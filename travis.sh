#!/bin/bash
# Exit on any failure
set -e

# Enable verbose logging
set -x

SECONDS=0

# Get start time
START_TIME=$(date +"%Y%m%dT%H%M%S")
echo "Start Time: ${START_TIME}"

# Check if running in Travis-CI
if [ -z "$TRAVIS_BRANCH" ]; then 
  echo "Error: this script is meant to run in Travis-CI only"
  exit 1
fi

# Check if GitHub token set
if [ -z "$GITHUB_TOKEN" ]; then
  echo "Error: GITHUB_TOKEN environment variable not set"
  exit 2
fi

# run build
docker-compose build
docker-compose run builder


# Post to GitHub releases
export GIT_TAG=v${START_TIME}
export GIT_RELEASE_TEXT="Auto-released by [Travis-CI build #$TRAVIS_BUILD_NUMBER](https://travis-ci.org/$TRAVIS_REPO_SLUG/builds/$TRAVIS_BUILD_ID)"
curl -sSL https://github.com/tcnksm/ghr/releases/download/v0.12.2/ghr_v0.12.2_linux_amd64.tar.gz | tar -xzvf -
ghr_v0.12.2_linux_amd64/ghr --version
ghr_v0.12.2_linux_amd64/ghr --debug -u lucashalbert -b "$GIT_RELEASE_TEXT" $GIT_TAG builds/
