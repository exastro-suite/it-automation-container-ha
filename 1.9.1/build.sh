#!/bin/bash -x

BASE_DIR=$(cd $(dirname $0); pwd)

for CONTAINER_TYPE in webapp mariadb backyard nfs ansible terraform; do
    cd ${BASE_DIR}/it-automation-${CONTAINER_TYPE}/centos8
    make build
    cd ${BASE_DIR}
done