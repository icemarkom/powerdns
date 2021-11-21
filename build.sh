#!/bin/bash

# For "weird" multiplatform failures:
#
# docker run --pull always --rm --privileged multiarch/qemu-user-static --reset -p yes

docker_user="icemarkom"
image_prefix="pdns"
build_targets=("dnsdist" "server" "recursor")
platform_list="linux/amd64,linux/arm64,linux/arm"

# Default target versions
dnsdist="1.6.1"
server="4.5.2"
recursor="4.5.7"

if [[ ! -z "${PLATFORM_LIST}" ]]; then
  platform_list="${PLATFORM_LIST}"
fi

# TODO(markom@gmail.com): These could potentially be moved into the build loop...
# dnsdist version override
if [[ ! -z "${DNSDIST_VERSION}" ]]; then
  dnsdist="${DNSDIST_VERSION}"
fi

# server version override
if [[ ! -z "${PDNS_SERVER_VERSION}" ]]; then
  server="${PDNS_SERVER_VERSION}"
fi

# recursor version override
if [[ ! -z "${PDNS_RECURSOR_VERSION}" ]]; then
  recursor="${PDNS_RECURSOR_VERSION}"
fi

if [[ ! -z $1 ]]; then
  build_targets=($*)
fi

for build_target in ${build_targets[@]}; do
  target_version="${!build_target}"
  docker buildx build \
    --target="${build_target}" \
    --build-arg "${build_target}_version"="${target_version}" \
    -t "${docker_user}/${image_prefix}-${build_target}" \
    --platform="${platform_list}" \
    --push \
    ${PWD}
done
