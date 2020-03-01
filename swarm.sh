#!/bin/bash

docker swarm init
docker node ls
service ssh restart
