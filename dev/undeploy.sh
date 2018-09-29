#!/bin/sh
set -e

############################ Configuration #################################
WORK_DIR=$(cd "$(dirname "$0")"; pwd)

PROJECT_NAME=starchart

echo "Start docker-compose ... "
cd ${WORK_DIR}
docker-compose -p ${PROJECT_NAME} down
