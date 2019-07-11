#!/bin/bash
set -e

docker-compose -p raspbian64 build
docker-compose -p raspbian64 run builder
docker-compose -p raspbian64 down
