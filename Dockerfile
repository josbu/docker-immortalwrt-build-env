# 使用官方基础镜像
FROM ubuntu:20.04 AS base

# 切换到国内阿里云源，并设置非交互式安装
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \
    export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
        bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib \
        g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev \
        libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev \
        libreadline-dev libssl-dev libtool lld llvm lrzsz mkisofs msmtp nano ninja-build \
        p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils \
        python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig \
        texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 切换到实际运行阶段（多阶段构建，用于优化镜像大小）
FROM ubuntu:20.04

# 切换到国内阿里云源
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list && \
    apt-get update && apt-get install -y --no-install-recommends \
        sudo vim curl wget git nano python3 python3-pip && \
    rm -rf /var/lib/apt/lists/*

# 创建普通用户（非 root），提高安全性
RUN useradd -m -d /home/user -s /bin/bash user && \
    echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/user
USER user
WORKDIR /home/user

# 配置 Git 系统全局信息
RUN git config --global user.name "user" && git config --global user.email "user@example.com"

# 如果需要额外操作添加到这里
