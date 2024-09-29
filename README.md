docker构建编译所需的系统镜像
下载源代码
首次编译
选择自己需要的软件再次编译
集成第三方软件包编译/编译单独ipk
官网教程： https://openwrt.org/docs/guide-developer/toolchain/start
为什么要使用Docker编译？
因为容器可以随时创建、删除，但是如果你直接在系统上构建，系统被破坏了就不好恢复了！因此推荐使用Docker
如果你对Docker一无所知，可以看看入门教程，推荐这个 【【编程不良人】Docker&Docker-Compose 实战!】 https://www.bilibili.com/video/BV1wQ4y1Y7SE/?p=3&share_source=copy_web&vd_source=801146758c4483987cb1bd1d6f31883a
docker编译官方openwrt
构建编译所需的系统镜像
为了不让编译环境污染宿主机，采用docker的方式编译，由docker为我们创建一个专门用于编译openwrt的系统，执行docker build的时候会自动下载编译工具所需要的依赖。你可以使用别人写好的Dockerfile文件： https://github.com/mwarning/docker-openwrt-build-env

git clone https://github.com/mwarning/docker-openwrt-builder.git
cd docker-openwrt-builder
查看Dockerfile，可以看到是基于debian的系统，安装了一些依赖，并创建了一个user用户（原因是不能使用root用户编译，也不能使用sudo执行编译）

不同系统所需依赖： https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem
FROM debian:buster

RUN apt-get update &&\
    apt-get install -y \
        sudo time git-core subversion build-essential g++ bash make \
        libssl-dev patch libncurses5 libncurses5-dev zlib1g-dev gawk \
        flex gettext wget unzip xz-utils python python-distutils-extra \
        python3 python3-distutils-extra python3-setuptools swig rsync curl \
        libsnmp-dev liblzma-dev libpam0g-dev cpio rsync gcc-multilib && \
    apt-get clean && \
    useradd -m user && \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

# set system wide dummy git config
RUN git config --system user.name "user" && git config --system user.email "user@example.com"

USER user
WORKDIR /home/user
为了加快构建速度，使用国内的源，在FROM debian:buster后面添加一行

RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
此时Dockerfile如下

FROM debian:buster
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

RUN apt-get update &&\
    apt-get install -y \
        sudo time git-core subversion build-essential g++ bash make \
        libssl-dev patch libncurses5 libncurses5-dev zlib1g-dev gawk \
        flex gettext wget unzip xz-utils python python-distutils-extra \
        python3 python3-distutils-extra python3-setuptools swig rsync curl \
        libsnmp-dev liblzma-dev libpam0g-dev cpio rsync gcc-multilib && \
    apt-get clean && \
    useradd -m user && \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

# set system wide dummy git config
RUN git config --system user.name "user" && git config --system user.email "user@example.com"

USER user
WORKDIR /home/user
构建镜像

docker build -t openwrt_builder .


执行此命令后，我们本地就多出了一个安装好编译依赖的debian镜像

root@tignioj:~/docker-openwrt-builder# docker images | grep openwrt
openwrt_builder            latest     0175798f5da9   4 weeks ago     716MB
创建编译系统的容器（镜像类似于系统的安装光盘，是固定的，容器类似于安装后的系统，可以开机关机、安装软件）

mkdir ~/mybuild
docker run -v ~/mybuild:/home/user --name openwrt_builder -itd openwrt_builder
进入容器

docker exec -it openwrt_builder /bin/bash
修改当前目录所属用户给user（这个user用户是在Dockerfile中创建的）

sudo chown -R user:user .
首次编译
经过上面的步骤，我们进入了一个已经准备好编译环境的系统，此时可以开始跟着官方的步骤开始编译了

官方编译步骤： https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem
下载openwrt源代码：

git clone https://git.openwrt.org/openwrt/openwrt.git
进入代码目录

cd openwrt
选择稳定版本分支
最好使用稳定版 git checkout 指定版本，而不是默认使用HEAD分支，如果你不使用稳定版，会带来某些问题，比如opkg安装程序会报错内核版本不匹配

# Select a specific code revision
git branch -a
git tag  # 查看有哪些分支
切换到指定版本

git checkout v23.05.2 # 指定稳定版
更新feeds
# Update the feeds
./scripts/feeds update -a
./scripts/feeds install -a
配置选项
# Configure the firmware image
make menuconfig
先认识一下界面 

在这个例子里面，我们暂时使用x86平台，到后面我们再使用指定的路由器平台，所以这些默认不动即可！ 

openwrt编译默认不带luci的web界面，你需要手动勾选安装，找到， LuCI-> Collections-> luci，双击使得前面的变成*符号 

设置web界面为中文， 双击空格使得前面的< >变成<*>符号

LuCI->Modules->Translations -> <*> Chinese Simplified (zh_Hans)
我们选择x86平台就是为了能在宿主机上运行，为了能docker中运行openwrt，找到target image勾选tar.gz (默认是勾选上的，没有自己勾上) 

接着保存配置菜单，移动到Save，回车  选择OK  然后光标移动到EXIT退出菜单。

下载编译所需的库
# Build the firmware image
make download -j$(nproc)
-j$(nproc), 其中nproc会返回你系统的最大线程数量，例如-j8表示7线程编译(会保留一个线程防止系统卡死)
V=s: 打印详细信息
开始编译
编译前，请确保有良好的科学环境，终端输入curl -I www.google.com ，检查状态码是否为200，如果卡住了说明网络环境不适合编译。

HTTP/1.1 200 OK
Content-Type: text/html; charset=ISO-8859-1
第一次编译推荐使用多线程编译，一个小时以内可以完成。单线程编译可能要5小时。

make -j$(nproc)
如果编译出错了，那么就单线程编译一遍，前面多线程编译过的内容会跳过。通常出问题都是网络问题。

make -j1 V=s
加上V=s后可以看到详细的错误信息，例如可能出现的网络问题 

编译成功后，到这里你可以看到在bin/target/x86/64目录下看到编译的固件



怎么在docker运行我们编译好的固件？请查看-> index.zh-cn

选择插件编译进固件
经过第一次编译后，后面再次编译速度就会快很多，这时候我们就可以选择自己需要的插件编译进固件里面，例如 samba4

make menuconfig
找到LuCI->Applications->luci-app-samba4, 双击空格使得前面的<>变成<*>，其中*表示集成进固件里面, M表示作为ipk包。

网络共享samba4
 光标移动到save，保存.config，然后再次编译，发现速度会快很多。

docker
<*> luci-app-dockerman.................. LuCI Support for docker
提醒：仅针对x86平台，如果编译luci-app-dockerman，则需要自己手动勾选依赖dockerd，否则docker无法正常启动

在Utilities下找到，把前面的设置成<*>

<*> dockerd............ Docker Community Edition Daemon  --->
usb打印服务器
 <*> luci-app-p910nd........... p910nd - Printer server module
找到内核Kernal Modules -> USB Support

 <*> kmod-usb-printer...... ........ Support for printers
usb挂载
Base System 中选中 block-mount

usb存储支持
-*- kmod-usb-storage............................. USB Storage support
<*> kmod-usb-storage-extras............ Extra drivers for usb-storage
<*> kmod-usb-storage-uas............... USB Attached SCSI (UASP) support
提醒：dnsmasq和dnsmasq-full不能同时勾选。例如选中passwall第三方插件时，可能会出现这种情况，请到Base System中取消调dnsmasq的勾选

二次编译
make -j$(nproc) download
make -j$(nproc)
集成第三方插件
经过上面的的步骤，你已经学会了基本的编译，此时可以尝试添加第三方的软件包 https://github.com/kenzok8/openwrt-packages

添加软件源
执行

sed -i '$a src-git kenzo https://github.com/kenzok8/openwrt-packages' feeds.conf.default
sed -i '$a src-git small https://github.com/kenzok8/small' feeds.conf.default
git pull
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig
找到LuCI->Applications，勾选需要的软件，依赖会自动勾选

插件集成到固件里面
按下空格选中M表示作为ipk包编译

<M> luci-app-alist............ LuCI support for alist 
再次按下空格，出现*表示集成到固件里面

<*> luci-app-alist............ LuCI support for alist 
然后开始编译

make -j$(nproc) download
make -j$(nproc)
插件不集成到固件里面，而是单独作为ipk包
参考： https://3mile.github.io/archives/2019/0813123100/ 按下空格选中M表示作为ipk包编译
<M> luci-app-alist............ LuCI support for alist 
开始编译

make package/luci-app-alist/compile V=s
ipk生成路径，可以使用find命令查找

find bin/  -name "*alist*"   
user@c6ba0d0ab225:~/openwrt$ find bin/  -name "*alist*"                                                                                       
bin/packages/aarch64_cortex-a53/kenzo/luci-i18n-alist-zh-cn_1.0.11-1_all.ipk
bin/packages/aarch64_cortex-a53/kenzo/alist_3.30.0-2_aarch64_cortex-a53.ipk
bin/packages/aarch64_cortex-a53/kenzo/luci-app-alist_1.0.11-1_all.ipk
user@c6ba0d0ab225:~/lede$ 
然后把这些ipk上传到路由器上执行即可

opkg install luci-i18n-alist-zh-cn_1.0.11-1_all.ipk
opkg install alist_3.30.0-2_aarch64_cortex-a53.ipk
opkg install luci-app-alist_1.0.11-1_all.ipk
或者在web界面上传安装

第三方插件源可能出现的问题
ERROR: package/feeds/kenzo/alist failed to build
解决方案参考： kenzok8/openwrt-packages#363 (comment) 添加依赖即可
sudo apt install libfuse-dev
ERROR: package/feeds/small/v2ray-plugin failed to build.
参考 fw876/helloworld#836 原因是勾选passwall2的时候，自动勾选了v2ray-plugin，要么取消调v2raya-plugin，要么升级go版本 
调整ROOT大小
参考 https://github.com/danshui-git/shuoming/blob/master/overlay.md
注意：对于官方openwrt的固件，修改root分区大小后，如果刷到路由器里面，需要重新刷GPT和uboot，否则可能不生效。

找到 Target Images -> (102) Root filesystem partition size (in MiB) ， 把102改为自己想要的大小。

自定义配置文件
参考1： https://openwrt.org/docs/guide-developer/toolchain/use-buildsystem#custom_files
参考2： https://openwrt.org/docs/guide-developer/uci-defaults 我们可以在编译根目录下创建files目录，相当于路由器的根目录。然后往里面新建etc/uci-defaults文件夹，这里面可以写自己定义的uci命令
mkdir -p files/etc/uci-defaults
往files/etc/uci-defaults/添加脚本，等同于往路由器的/etc/uci-defaults/中添加脚本。

vim files/etc/uci-defaults/99-custom
在99-custom添加自定义ip地址、dns和网关命令

uci -q batch << EOI
set network.lan.ipaddr='192.168.30.99'
set network.lan.dns='192.168.30.1'
set network.lan.gateway='192.168.30.1'
EOI
然后编译出来的固件，就会使用你的自定义配置.

该目录中的所有脚本都会由boot服务自动执行，且仅在全新安装后的首次启动时执行！

如果它们以代码 0 退出，则它们随后将被删除。
以非零退出代码退出的脚本不会被删除，并将在下次启动时重新执行，直到它们也成功退出。
注意事项
如果你选择了自定义路由器平台，官方openwrt编译出来的是.itb格式的固件，需要用到tftp刷机方式，不兼容常见的第三方uboot刷入方式。可参考教程：

官网： https://openwrt.org/docs/guide-user/installation/generic.flashing.tftp
恩山： https://www.right.com.cn/forum/thread-8338290-1-1.html
差异配置
暂时不清楚有什么优点

参考： https://openwrt.org/docs/guide-developer/uci-defaults
uci命令： https://openwrt.org/docs/techref/uci
docker编译lede
简介：lede是openwrt的一个分支，默认使用中文，集成了一些基本的插件。

编译方法：类似openwrt，其实就是仿造 https://github.com/mwarning/docker-openwrt-build-env 这个编写了一个linux环境，然后在这个环境里面执行编译

这次我们不下载他们Dockerfile，而是自己仿造一个

FROM debian:buster
RUN sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list

RUN apt-get update &&\
    apt-get install -y \
        sudo time git-core subversion build-essential g++ bash make \
        libssl-dev patch libncurses5 libncurses5-dev zlib1g-dev gawk \
        flex gettext wget unzip xz-utils python python-distutils-extra \
        python3 python3-distutils-extra python3-setuptools swig rsync curl \
        libsnmp-dev liblzma-dev libpam0g-dev cpio rsync gcc-multilib && \
    apt-get clean && \
    useradd -m user && \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

# set system wide dummy git config
RUN git config --system user.name "user" && git config --system user.email "user@example.com"

USER user
WORKDIR /home/user
构建镜像

docker build -t lede_builder .
运行镜像

docker run  -v ~/lede_mybild:/home/user lede_builder /bin/bash
首次编译
git clone https://github.com/coolsnowwolf/lede
cd lede
./scripts/feeds update -a
./scripts/feeds install -a
make menuconfig
第一次编译建议不要勾选任何插件，因为第一次编译包含了很多基础包的编译，过程比较持久，如果加上了插件造成报错可能会感到困惑：到底是插件的问题，还是我系统没配置好？因此第一次仅仅勾选你的路由器平台即可。这里拿RAX3000M举例，首先选择平台，接着是芯片，第三项是具体型号



自定义配置
默认情况下，openwrt和lede后台地址都是192.168.1.1，有没有办法在编译的时候自定义呢？当然可以，只需要在编译的根目录下创建文件夹files，然后往里面添加初始化脚本即可。files相当于路由器的根目录

mkdir -p files/etc/uci-defaults
假设我们要自定义ip地址

vim files/etc/uci-defaults/99-custom
往里面添加内容

uci -q batch << EOI
set network.lan.ipaddr='192.168.30.101'
set network.lan.dns='192.168.30.1'
set network.lan.gateway='192.168.30.1'
delete uhttpd.main.listen_https
EOI
注意到我这里删掉了uhttpd的https监听地址，原因是lede默认没有安装luci-app-openssl，如果不关闭https监听会无法启动web界面（仅x86）
开始编译固件 （-j 后面是线程数）

make download -j8
make -j$(nproc)
如果发现编译出错，那么可以使用单线程编译，并输出详细信息。大部分情况下的首次编译出现错误都是网络问题。

make -j1 V=s
编译完成后，可以在bin/target/平台目录下看到自己编译后的包，其中 xxx-squashfs-sysupgrade.bin就是我们要的固件 

集成插件编译
经过前面的首次编译后，一些基础的包都已经编译完成，再次编译时候会跳过他们。此时选择自己需要的插件编译速度，就取决于插件本身。

make menuconfig
选择自己的插件后

make download -j$(nproc)
make -j$(nproc)
注意，勾选luci应用后，依赖会自动勾选上，此时再次取消勾选luci，依赖不会取消，如果需要重新配置，请删掉.config

rm -rf .config
make menuconfig
make -j$(nproc)
或者再选择插件前，先备份一下.config

cp .config .config.backup
拓展包
一些发行版会添加自己的拓展包，例如lede和immortalWRT的代码中都有automount和autosamba，但是这些官方openwrt是没有的。

ipv6支持
默认情况下lede的代码没有勾选ipv6-helper，请到 Extra pckages勾选ipv6-helper

自动挂载
Extra packages -> automount

自动网络共享
Extra packages -> autosamb

注意：这个脚本有BUG，在RAX3000M-emmc勾选了此拓展包会导致无线网络消失。删除后才能恢复，因此不建议使用此拓展包。详细信息： immortalwrt/immortalwrt#1201

参考： https://github.com/coolsnowwolf/lede
添加第三方插件源
与openwrt的相同，请参考上面

docker编译immortalwrt
地址： https://github.com/immortalwrt/immortalwrt
简介： immortalwrt甚至集成了很多第三方的软件包，无需额外添加软件源，感觉更方便，编译步骤和lede一样，过程不再赘述。
构建镜像
准备Dockerfile文件
Dockerfile文件，根据官网描述，建议基于ubuntu20.04-LTS，那么第一行的FROM就要改了

FROM ubuntu:20.04
RUN sed -i s@/archive.ubuntu.com/@/mirrors.aliyun.com/@g /etc/apt/sources.list

RUN apt-get update &&\
  DEBIAN_FRONTEND=noninteractive  apt install -y \
  sudo ack antlr3 asciidoc autoconf automake autopoint binutils bison build-essential \
  bzip2 ccache clang cmake cpio curl device-tree-compiler ecj fastjar flex gawk gettext gcc-multilib \
  g++-multilib git gnutls-dev gperf haveged help2man intltool lib32gcc-s1 libc6-dev-i386 libelf-dev \
  libglib2.0-dev libgmp3-dev libltdl-dev libmpc-dev libmpfr-dev libncurses5-dev libncursesw5 \
  libncursesw5-dev libpython3-dev libreadline-dev libssl-dev libtool lld llvm lrzsz mkisofs msmtp \
  nano ninja-build p7zip p7zip-full patch pkgconf python2.7 python3 python3-pip python3-ply \
  python3-docutils python3-pyelftools qemu-utils re2c rsync scons squashfs-tools subversion swig \
  texinfo uglifyjs upx-ucl unzip vim wget xmlto xxd zlib1g-dev 

RUN apt-get clean && \
    useradd -m user && \
    echo 'user ALL=NOPASSWD: ALL' > /etc/sudoers.d/user

# set system wide dummy git config
RUN git config --system user.name "user" && git config --system user.email "user@example.com"

USER user
WORKDIR /home/user
注意到这里还加了一行 DEBIAN_FRONTEND=noninteractive，防止创建镜像的过程出现交互行为。

docker build -t immortalwrt_builder .
创建容器
docker run -itd --name iwt_builder -v ~/iwt_builder:/home/user immortalwrt_builder 
进入容器
docker exec -it iwt_builder bash
注意，docker里面的ubuntu系统需要修改用户目录权限给user才能下载源代码

sudo chown -R user:user .
首次编译
下载源代码

git clone -b openwrt-23.05 --single-branch --filter=blob:none https://github.com/immortalwrt/immortalwrt
cd immortalwrt
选择哪个分区可以在这里找 https://github.com/immortalwrt/immortalwrt/branches/active
安装feeds

./scripts/feeds update -a
./scripts/feeds install -a
编译菜单，同样，先别选择插件，仅选择你的平台即可！

make menuconfig
首次编译

make -j$(nproc)
选择插件后再次编译

make menuconfig
make -j$(nproc)
编译的一些技巧
make选项
当多线程编译失败时，可以使用以下命令单线程编译，仅关注错误信息
make V=s 2>&1 | tee build.log | grep -i -E "^make.*(error|[12345]...Entering dir)"
另一种方法是检查相应的logs文件夹，如make[3] -C package/kernel/mac80211 compile，那么可以转到<buildroot>/logs/package/kernel/mac80211查看compile.txt

报错时发出声音
make ...; echo -e '\a'
忽视某个包的错误，继续编译其他包
加入某个包编译错误了，

# Ignore compilation errors
IGNORE_ERRORS=1 make ...
 
# Ignore all errors including firmware assembly stage
make -i ...
tmux多窗口
tmux小技巧往期文章-> index.zh-cn

如果是远程ssh连接服务器编译，最好使用tmux，可以多窗口，且ssh断掉后进程不会中断，再次ssh进入服务器可以回到tmux会话。 创建一个名称为openwrt的session
tmux new -s openwrt
面板垂直分割，键盘按下快捷键。以下<prefix> 表示同时按下Ctrl + B。

例如下面这个命令，表示同时按下Ctrl + B 后，松开键盘，再按下%
<prefix> + %
面板水平分割

<prefix> + "
退出tmux，但不退出tmux的进程

<prefix>  + Q
回到tmux

tmux attach
云编译：github action
