#!/bin/bash


for node in $(docker node ls | sed 1d | grep -v '*' | awk '{print $2}'); do
    printf "Stopping     : "
    docker stop ${node}
    printf "Removing     : "
    docker rm ${node}
    printf "Removing Log : "
    echo "${node}.json"
    rm ${node}.json
done
docker swarm leave --force
