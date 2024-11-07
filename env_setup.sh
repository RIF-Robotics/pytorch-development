#!/bin/bash

# Don't include the data directory in the build context
touch ../data/.dockerignore

# Get the host user's IDs for the entrypoint script
echo -e "USER_ID=$(id -u ${USER})\nGROUP_ID=$(id -g ${USER})" > .env

# Reference:
# https://stackoverflow.com/questions/16296753/can-you-run-gui-applications-in-a-linux-docker-container
#xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | xauth -f .docker.xauth nmerge -

#if [[ -z "${GOOGLE_APPLICATION_CREDENTIALS}" ]]; then
#    echo 'Warning: Environment variable not set: GOOGLE_APPLICATION_CREDENTIALS. Build might fail.'
#fi
