# DOCKER_PREFIX=${DOCKER_PREFIX:-"quay.io/kubevirt"}
# DOCKER_IMAGE=${DOCKER_IMAGE:-"builder"}

if [ "$(uname -m)" == "riscv64" ]; then
    DOCKER_PREFIX=${DOCKER_PREFIX:-"registry.risc-vers.cn/wg-cloudcomputing"}
    DOCKER_IMAGE=${DOCKER_IMAGE:-"kubevirt-builder"}
else
    DOCKER_PREFIX=${DOCKER_PREFIX:-"quay.io/kubevirt"}
    DOCKER_IMAGE=${DOCKER_IMAGE:-"builder"}
fi

DOCKER_CROSS_IMAGE=${DOCKER_CROSS_IMAGE:-"builder-cross"}

ARCHITECTURES=${ARCHITECTURES:-"amd64 arm64 s390x riscv64"}
