#!/bin/bash


for node in $(docker node ls | sed 1d | grep -v '*' | awk '{print $2}'); do
    printf "Stopping   : "
    docker stop ${node}
    printf "Removing   : "
    docker rm ${node}
done
docker swarm leave --force
