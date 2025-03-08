FROM ubuntu:20.04

# 配置阿里云镜像源和时区
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list
ENV TZ=UTC
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 安装依赖（已修复软件包冲突）
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt install -y \
    ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
    bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib \
    g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev \
    libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses-dev libpython3-dev \
    libreadline-dev libssl-dev libtool lld llvm lrzsz mkisofs msmtp nano ninja-build \
    p7zip p7zip-full patch pkgconf python3 python3-pip python3-ply python3-docutils \
    python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig \
    texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev && \
    apt-get clean

# 创建用户并配置
RUN useradd -m user && \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

# 设置用户级 Git 配置
USER user
WORKDIR /home/user
RUN git config --global user.name "user" && git config --global user.email "user@example.com"
