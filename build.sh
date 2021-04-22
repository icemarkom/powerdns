#!/bin/bash

docker_user="icemarkom"
image_prefix="pdns"

if [[ -z $1 ]]; then
  echo "Build name must be specified." > /dev/stderr
  exit 42
fi

case $1 in
  server)
    build_type="server"
  ;;
  recursor)
    build_type="recursor"
  ;;
  dnsdist)
    build_type="dnsdist"
  ;;
  *)
    echo "Unknown build type: $1" > /dev/stderr
    exit 42
  ;;
esac

if [[ ! -z $2 ]]; then
  build_arg="--build-arg=${build_type}_ver=$2"
fi

if [[ ! -d ${build_type} ]]; then
  echo "Cannot find ${build_type}" > /dev/stderr
  exit 42
fi


if [[ ! -f ${build_type}/Dockerfile ]]; then
  echo "Cannot find ${build_type}/Dockerfile" > /dev/stderr
  exit 42
fi

docker build \
  -t ${docker_user}/${image_prefix}-${build_type} \
  ${build_arg} \
  -f ${build_type}/Dockerfile \
  .