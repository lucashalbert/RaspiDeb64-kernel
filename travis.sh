#!/bin/bash
SECONDS=0
set -e

# Get start time
START_TIME=$(date +"%Y%m%dT%H%M%S")
echo "Start Time: ${START_TIME}"

# Enable verbose logging
set -x

# Check if running in Travis-CI
if [ -z "$TRAVIS_BRANCH" ]; then 
  echo "Error: this script is meant to run in Travis-CI only"
  exit 1
fi

# Check if GitHub token set
#if [ -z "$GITHUB_TOKEN" ]; then
#  echo "Error: GITHUB_TOKEN environment variable not set"
#  exit 2
#fi

# run build
docker-compose build
docker-compose run builder
