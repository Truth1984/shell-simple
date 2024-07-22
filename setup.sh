#!/usr/bin/env bash

echo SCRIPT_VERSION=1.3.0

if [[ -z "$(command -v u2)" ]]; then
    ssurl="https://raw.gitmirror.com/Truth1984/shell-simple/main/util.sh"; if $(command -v curl &> /dev/null); then curl $ssurl -o util.sh; elif $(command -v wget &> /dev/null); then wget -O util.sh $ssurl; fi; chmod 777 util.sh && ./util.sh setup && source ~/.bash_mine
fi;

if [[ -z "$(command -v u2)" ]]; then echo u2 not setup correctly && exit 1; fi;

source $HOME/.bash_env

if ! $(u2 hasValue $_U2_INIT_DEP); then

    if grep -q "ID=ubuntu" /etc/os-release ; then 
        codename=$(sh -c '. /etc/os-release; echo $VERSION_CODENAME')
        u2 _ED updating ubuntu $codename mirror
        printf "deb https://mirrors.163.com/ubuntu/ $codename main restricted universe multiverse
\ndeb-src https://mirrors.163.com/ubuntu/ $codename main restricted universe multiverse
\ndeb https://mirrors.163.com/ubuntu/ $codename-updates main restricted universe multiverse
\ndeb-src https://mirrors.163.com/ubuntu/ $codename-updates main restricted universe multiverse
\ndeb https://mirrors.163.com/ubuntu/ $codename-backports main restricted universe multiverse
\ndeb-src https://mirrors.163.com/ubuntu/ $codename-backports main restricted universe multiverse
\ndeb https://mirrors.163.com/ubuntu/ $codename-security main restricted universe multiverse
\ndeb-src https://mirrors.163.com/ubuntu/ $codename-security main restricted universe multiverse
        " > /etc/apt/sources.list
    fi;

    if grep -q "ID=debian" /etc/os-release ; then
        codename=$(dpkg --status tzdata|grep Provides|cut -f2 -d'-')
        u2 _ED updating debian $codename mirror
        printf "deb https://mirrors.163.com/debian/ $codename main contrib non-free
\ndeb-src https://mirrors.163.com/debian/ $codename main contrib non-free
\ndeb https://mirrors.163.com/debian/ $codename-updates main contrib non-free
\ndeb-src https://mirrors.163.com/debian/ $codename-updates main contrib non-free
\ndeb https://mirrors.163.com/debian/ $codename-backports main contrib non-free
\ndeb-src https://mirrors.163.com/debian/ $codename-backports main contrib non-free
\ndeb https://mirrors.163.com/debian-security $codename/updates main contrib non-free
\ndeb-src https://mirrors.163.com/debian-security $codename/updates main contrib non-free
        " > /etc/apt/sources.list
    fi;

    if grep -q "ID=alpine" /etc/os-release ; then
        u2 _ED updating alpine mirror
        printf "https://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/main
\nhttps://mirrors.tuna.tsinghua.edu.cn/alpine/latest-stable/community
        " > /etc/apk/repositories
    fi;

    u2 upgrade

    if $(u2 string -c "$@" "container"); then
        u2 install wget curl nano make psmisc net-tools coreutils screen

        if $(u2 os -c apk); then u2 install the_silver_searcher; fi;
        if $(u2 os -c apt); then u2 install software-properties-common silversearcher-ag; fi;
        if $(u2 os -c yum); then u2 install redhat-lsb-core epel-release the_silver_searcher; fi;

    elif ! $(u2 os -c win); then

        u2 install wget curl nano git make psmisc net-tools nethogs coreutils sudo screen tcpdump iftop

        if $(u2 os -c yum); then
            u2 install redhat-lsb-core epel-release the_silver_searcher udisks2 openssh-server openssh-clients
        fi;

        if $(u2 os -c apk); then
            u2 install the_silver_searcher openrc openssh
        fi;
        
        if $(u2 os -c apt); then
            u2 install software-properties-common silversearcher-ag udisks2 openssh-server openssh-client
        fi;

        if $(u2 os -c brew); then 
            if [ ! -d /usr/local/sbin ]; then 
                sudo mkdir /usr/local/sbin && sudo chmod 777 /usr/local/sbin
                echo 'export PATH=/usr/local/sbin:$PATH' >> $HOME/.bashrc
            fi;
            u2 install the_silver_searcher pstree openssh
        fi;

    fi;

    if $(u2 hasFile /etc/resolv.conf) && ! $(u2 hasContent /etc/resolv.conf 1.0.0.1); then
        sudo sh -c "printf 'nameserver\t1.0.0.1\n' >> /etc/resolv.conf"
        sudo sh -c "printf 'nameserver\t8.8.8.8\n' >> /etc/resolv.conf"
        sudo sh -c "printf 'nameserver\t8.8.4.4\n' >> /etc/resolv.conf"
    fi;

    if $(u2 hasFile /etc/systemd/resolved.conf) && ! $(u2 hasContent /etc/systemd/resolved.conf 'DNS=1.0.0.1'); then
        sudo sh -c "printf 'DNS=1.0.0.1 8.8.8.8 8.8.4.4\n' >> /etc/systemd/resolved.conf" 
    fi;

    echo "_U2_INIT_DEP=1" >> $HOME/.bash_env
fi;

# ./setup docker

ALL=false;
if $(u2 string -c "$@" "ALL"); then ALL=true; fi;

if $(u2 string -c "$@" "docker") || $ALL; then 
    if ! $(u2 hasCmd docker); then 
        u get -r https://raw.gitmirror.com/docker/docker-install/master/install.sh --mirror Aliyun
        sudo usermod -aG docker $(whoami)
       
        if $(u2 hasCmd systemctl); then
            sudo systemctl start docker.service
            sudo systemctl enable docker.service
        fi; 
    fi; 
fi;

if $(u2 string -c "$@" "node") || $ALL; then 
    if ! $(u2 hasCmd node); then 
        curl -L https://raw.gitmirror.com/mklement0/n-install/stable/bin/n-install | bash -s -- -y 
    fi;
    npm config set registry http://registry.npmmirror.com
    # original:
    # npm config set registry https://registry.npmjs.org
fi;

if $(u2 string -c "$@" "bun") || $ALL; then 
    if ! $(u2 hasCmd bun); then 
        u2 install unzip
        u np npm i -g bun --loglevel verbose
        if ! $(u2 hasContent $HOME/.bash_env BUN_INSTALL); then
            echo 'export BUN_INSTALL="$HOME/.bun"' >> $HOME/.bash_env 
            echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> $HOME/.bash_env 
        fi; 
    fi; 
fi;

if $(u2 string -c "$@" "pm2") || $ALL; then 
    if ! $(u2 hasCmd pm2); then 
        bun i -g pm2
        pm2 startup
    fi; 
fi;