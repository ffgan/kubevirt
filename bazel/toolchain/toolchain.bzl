def register_all_toolchains():
    native.register_toolchains(
        "//bazel/toolchain/s390x-none-linux-gnu:s390x_linux_toolchain",
        "//bazel/toolchain/aarch64-none-linux-gnu:aarch64_linux_toolchain",
        "//bazel/toolchain/x86_64-none-linux-gnu:x86_64_linux_toolchain",
        "//bazel/toolchain/riscv64-aarch64-linux-gnu:riscv64_linux_toolchain_in_aarch64",
        "//bazel/toolchain/riscv64-x86_64-linux-gnu:riscv64_linux_toolchain_in_x86_64",
        "//bazel/toolchain/riscv64-local-linux-gnu:riscv64_linux_toolchain",
    )
