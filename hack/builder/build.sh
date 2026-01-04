#!/usr/bin/env bash
set -ex

MODE=${1:-all}
LOCAL_ARCH=${2:-all}

source $(dirname "$0")/../common.sh

fail_if_cri_bin_missing

SCRIPT_DIR="$(
    cd "$(dirname "${BASH_SOURCE[0]}")"
    pwd
)"

# If qemu-static has already been registered as a runner for foreign
# binaries, for example by installing qemu-user and qemu-user-binfmt
# packages on Fedora or by having already run this script earlier,
# then we shouldn't alter the existing configuration to avoid the
# risk of possibly breaking it
if ! grep -q -E '^enabled$' /proc/sys/fs/binfmt_misc/qemu-aarch64 2>/dev/null; then
    ${KUBEVIRT_CRI} >&2 run --rm --privileged docker.io/multiarch/qemu-user-static --reset -p yes
fi

# shellcheck source=hack/builder/common.sh
. "${SCRIPT_DIR}/common.sh"
# shellcheck source=hack/builder/version.sh
. "${SCRIPT_DIR}/version.sh"

# for ARCH in ${ARCHITECTURES}; do
#     case ${ARCH} in
#     amd64)
#         sonobuoy_arch="amd64"
#         bazel_arch="x86_64"
#         ;;
#     *)
#         sonobuoy_arch=${ARCH}
#         bazel_arch=${ARCH}
#         ;;
#     esac
#     ${KUBEVIRT_CRI} >&2 pull --platform="linux/${ARCH}" quay.io/centos/centos:stream9
#     ${KUBEVIRT_CRI} >&2 build --platform="linux/${ARCH}" -t "${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}-${ARCH}" --build-arg ARCH=${ARCH} --build-arg SONOBUOY_ARCH=${sonobuoy_arch} --build-arg BAZEL_ARCH=${bazel_arch} -f "${SCRIPT_DIR}/Dockerfile" "${SCRIPT_DIR}"
# done

# ${KUBEVIRT_CRI} >&2 build --platform="linux/amd64" -t "${DOCKER_PREFIX}/${DOCKER_CROSS_IMAGE}:${VERSION}" --build-arg BUILDER_IMAGE="${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}-amd64" -f "${SCRIPT_DIR}/Dockerfile.cross-compile" "${SCRIPT_DIR}"
#
if [ "${MODE}" == "cross" ]; then
    if [ "${LOCAL_ARCH}" == "amd64" ] || [ "${LOCAL_ARCH}" == "arm64" ]; then
        ARCHITECTURES="${LOCAL_ARCH}"
    else
        echo "Unsupported architecture for cross mode: ${LOCAL_ARCH}" >&2
        exit 1
    fi
fi

if [[ "${MODE}" == "single" && "${ARCH}" == "riscv64" ]]; then
    sonobuoy_arch=${ARCH}
    bazel_arch=${ARCH}
    ${KUBEVIRT_CRI} >&2 pull --platform="linux/${ARCH}" registry.risc-vers.cn/wg-cloudcomputing/openeuler:24.03-lts
    ${KUBEVIRT_CRI} >&2 build --network host --platform="linux/${ARCH}" -t "${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}-${ARCH}" --build-arg ARCH=${ARCH} --build-arg SONOBUOY_ARCH=${sonobuoy_arch} --build-arg BAZEL_ARCH=${bazel_arch} -f "${SCRIPT_DIR}/Dockerfile.riscv64" "${SCRIPT_DIR}"
else
    for ARCH in ${ARCHITECTURES}; do
        case ${ARCH} in
        amd64)
            sonobuoy_arch="amd64"
            bazel_arch="x86_64"
            ;;
        *)
            sonobuoy_arch=${ARCH}
            bazel_arch=${ARCH}
            ;;
        esac
        if [ "${ARCH}" == "riscv64" ]; then
            ${KUBEVIRT_CRI} >&2 pull --platform="linux/${ARCH}" registry.risc-vers.cn/wg-cloudcomputing/openeuler:24.03-lts
            ${KUBEVIRT_CRI} >&2 build --network host --platform="linux/${ARCH}" -t "${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}-${ARCH}" --build-arg ARCH=${ARCH} --build-arg SONOBUOY_ARCH=${sonobuoy_arch} --build-arg BAZEL_ARCH=${bazel_arch} -f "${SCRIPT_DIR}/Dockerfile.riscv64" "${SCRIPT_DIR}"
        elif [ "${ARCH}" == "arm64" ]; then
            ${KUBEVIRT_CRI} >&2 pull --platform="linux/${ARCH}" registry.risc-vers.cn/wg-cloudcomputing/ubuntu:24.04
            ${KUBEVIRT_CRI} >&2 build --platform="linux/${ARCH}" -t "${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}-${ARCH}" --build-arg ARCH=${ARCH} --build-arg SONOBUOY_ARCH=${sonobuoy_arch} --build-arg BAZEL_ARCH=${bazel_arch} -f "${SCRIPT_DIR}/Dockerfile.arm64" "${SCRIPT_DIR}"
            # Used for cross-compilation on arm64
            ${KUBEVIRT_CRI} >&2 build --platform="linux/arm64" -t "${DOCKER_PREFIX}/${DOCKER_CROSS_IMAGE}:${VERSION}" --build-arg BUILDER_IMAGE="${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}-arm64" -f "${SCRIPT_DIR}/Dockerfile.cross-compile-arm64" "${SCRIPT_DIR}"
        elif [ "${ARCH}" == "amd64" ]; then
            ${KUBEVIRT_CRI} >&2 pull --platform="linux/${ARCH}" ubuntu:24.04
            ${KUBEVIRT_CRI} >&2 build --platform="linux/${ARCH}" -t "${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}-${ARCH}" --build-arg ARCH=${ARCH} --build-arg SONOBUOY_ARCH=${sonobuoy_arch} --build-arg BAZEL_ARCH=${bazel_arch} -f "${SCRIPT_DIR}/Dockerfile.amd64" "${SCRIPT_DIR}"
            # Used for cross-compilation on x86_64/amd64
            ${KUBEVIRT_CRI} >&2 build --platform="linux/amd64" -t "${DOCKER_PREFIX}/${DOCKER_CROSS_IMAGE}:${VERSION}" --build-arg BUILDER_IMAGE="${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}-amd64" -f "${SCRIPT_DIR}/Dockerfile.cross-compile-amd64" "${SCRIPT_DIR}"
        else
            ${KUBEVIRT_CRI} >&2 pull --platform="linux/${ARCH}" quay.io/centos/centos:stream9
            ${KUBEVIRT_CRI} >&2 build --platform="linux/${ARCH}" -t "${DOCKER_PREFIX}/${DOCKER_IMAGE}:${VERSION}-${ARCH}" --build-arg ARCH=${ARCH} --build-arg SONOBUOY_ARCH=${sonobuoy_arch} --build-arg BAZEL_ARCH=${bazel_arch} -f "${SCRIPT_DIR}/Dockerfile" "${SCRIPT_DIR}"
        fi
    done
fi

# Print the version for use by other callers such as publish.sh
echo ${VERSION}
