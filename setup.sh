#!/usr/bin/env bash

echo SCRIPT_VERSION=1.0.0

if [[ -z "$(command -v u2)" ]]; then
    ssurl="https://raw.gitmirror.com/Truth1984/shell-simple/main/util.sh"; if $(command -v curl &> /dev/null); then curl $ssurl -o util.sh; elif $(command -v wget &> /dev/null); then wget -O util.sh $ssurl; fi; chmod 777 util.sh && ./util.sh setup && source ~/.bash_mine
fi;

if [[ -z "$(command -v u2)" ]]; then echo u2 not setup correctly && exit 1; fi;

source $HOME/.bash_env

if ! $(hasValue $_U2_INIT_DEP); then

    if $(u2 os -c alpine); then
        sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories
    fi;

    if $(u2 hasFile /etc/apt/sources.list); then
        sed -i 's/http.*[^security].com/https:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
        sed -i 's/http.*[^security].org/https:\/\/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list
    fi;

    u2 upgrade

    if ! $(u2 os -c win); then

        u2 install wget curl nano git make psmisc net-tools nethogs coreutils sudo screen

        if $(u2 os -c yum); then
            u2 install redhat-lsb-core epel-release the_silver_searcher udisks2
        fi;

        if $(u2 os -c apt); then
            u2 install software-properties-common silversearcher-ag udisks2
        fi;

        if $(u2 os -c brew); then 
            if [ ! -d /usr/local/sbin ]; then 
                sudo mkdir /usr/local/sbin && sudo chmod 777 /usr/local/sbin
                echo 'export PATH=/usr/local/sbin:$PATH' >> $HOME/.bashrc
            fi;
            u2 install the_silver_searcher
        fi;

    fi;

    if $(u2 hasFile /etc/resolv.conf) && ! $(u2 hasContent /etc/resolv.conf 1.1.1.1); then
        sudo sh -c "printf 'nameserver\t1.1.1.1\n' >> /etc/resolv.conf"
        sudo sh -c "printf 'nameserver\t8.8.8.8\n' >> /etc/resolv.conf"
        sudo sh -c "printf 'nameserver\t8.8.4.4\n' >> /etc/resolv.conf"
    fi;

    if $(u2 hasFile /etc/systemd/resolved.conf) && ! $(u2 hasContent /etc/systemd/resolved.conf 'DNS=1.1.1.1'); then
        sudo sh -c "printf 'DNS=1.1.1.1 8.8.8.8 8.8.4.4\n' >> /etc/systemd/resolved.conf" 
    fi;

    echo "_U2_INIT_DEP=1" >> $HOME/.bash_env
fi;

# ./setup docker

if $(u2 string -c "$@" "docker"); then 
    if ! $(u2 hasCmd docker); then 
        u2 install docker
        sudo usermod -aG docker $(whoami)
       
        if $(u2 hasCmd systemctl); then
            sudo systemctl start docker.service
            sudo systemctl enable docker.service
        fi; 
    fi; 
fi;

if $(u2 string -c "$@" "node"); then 
    if ! $(u2 hasCmd node); then 
        curl -L https://bit.ly/n-install | bash -s -- -y 
    fi; 
    if ! $(u2 hasCmd bun); then 
        curl -fsSL https://bun.sh/install | bash
    fi; 
fi;

