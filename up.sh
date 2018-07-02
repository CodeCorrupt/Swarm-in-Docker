#!/bin/bash


#Create swarm node if not already
if ! docker node ls > /dev/null 2>&1 ; then
    docker swarm init
fi

SWARM_NUM_WORKERS="${1:-3}"
SWARM_NUM_MANAGERS="${2:-0}"
SWARM_WORKER_TOKEN=$(docker swarm join-token -q worker)
SWARM_MANAGER_TOKEN=$(docker swarm join-token -q manager)
SWARM_MASTER_IP=$(docker info | grep -w 'Node Address' | awk '{print $3}')
DOCKER_VERSION=$(docker version | grep -A2 "Server:" | grep "Version:" | awk '{print $2}')
echo "SWARM_WORKER_TOKEN :   $SWARM_WORKER_TOKEN"
echo "SWARM_MANAGER_TOKEN:   $SWARM_MANAGER_TOKEN"
echo "SWARM_MASTER_IP    :   $SWARM_MASTER_IP"
echo "DOCKER_VERSION     :   $DOCKER_VERSION"
echo "SWARM_NUM_WORKERS  :   $SWARM_NUM_WORKERS"

# Run NUM_WORKERS workers with SWARM_TOKEN
for i in $(seq "${SWARM_NUM_MANAGERS}"); do
    docker run \
        -d \
        --privileged \
        --name manager-${i} \
        --hostname=manager-${i} \
        -p $((2377 + $i)):2375 \
        docker:${DOCKER_VERSION}-dind
    docker --host=localhost:$((2377 + $i)) swarm join --token ${SWARM_MANAGER_TOKEN} ${SWARM_MASTER_IP}:2377
    ln -s $(docker inspect --format='{{.LogPath}}' manager-$i) manager-${i}.json
    echo "Log File           :   manager-${i}.json"
done
for i in $(seq "${SWARM_NUM_WORKERS}"); do
    docker run \
        -d \
        --privileged \
        --name worker-${i} \
        --hostname=worker-${i} \
        -p $((2377 + $i + $SWARM_NUM_MANAGERS)):2375 \
        docker:${DOCKER_VERSION}-dind
    docker --host=localhost:$((2377 + $i + $SWARM_NUM_MANAGERS)) swarm join --token ${SWARM_WORKER_TOKEN} ${SWARM_MASTER_IP}:2377
    ln -s $(docker inspect --format='{{.LogPath}}' worker-$i) worker-${i}.json
    echo "Log File           :   worker-${i}.json"
done

docker service create \
    --detach=true \
    --name=viz \
    --publish=8000:8080/tcp \
    --constraint=node.role==manager \
    --mount=type=bind,src=/var/run/docker.sock,dst=/var/run/docker.sock \
    dockersamples/visualizer
