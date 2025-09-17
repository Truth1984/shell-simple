#!/usr/bin/env bash

echo SCRIPT_VERSION=1.5.3

if [[ -z "$(command -v u2)" ]]; then
    ssurl="https://raw.gitmirror.com/Truth1984/shell-simple/main/util.sh"; if $(command -v curl &> /dev/null); then curl $ssurl -o util.sh; elif $(command -v wget &> /dev/null); then wget -O util.sh $ssurl; fi; chmod 777 util.sh && ./util.sh setup && source ~/.bash_mine
fi;

if [[ -z "$(command -v u2)" ]]; then echo u2 not setup correctly && exit 1; fi;

source $HOME/.bash_env

if ! $(u2 hasValue $_U2_INIT_DEP); then

    if ! $(u2 string -c "$@" "container"); then u2 upgrade; fi;

    if $(u2 string -c "$@" "container"); then
        u2 installC nano make psmisc net-tools coreutils screen

        if $(u2 os -c apk); then u2 installC the_silver_searcher; fi;
        if $(u2 os -c apt); then u2 installC software-properties-common silversearcher-ag; fi;
        if $(u2 os -c yum); then u2 installC redhat-lsb-core epel-release the_silver_searcher; fi;

        NO_SWAP=true; 

    elif ! $(u2 os -c win); then

        u2 install wget curl nano git make psmisc net-tools nethogs coreutils sudo screen tcpdump iftop gnupg tmux

        if $(u2 os -c yum); then
            u2 install redhat-lsb-core epel-release the_silver_searcher udisks2 openssh-server openssh-clients p7zip
        fi;

        if $(u2 os -c apk); then
            u2 install the_silver_searcher openrc openssh p7zip util-linux
        fi;
        
        if $(u2 os -c apt); then
            u2 install software-properties-common silversearcher-ag udisks2 openssh-server openssh-client p7zip-full
        fi;

        if $(u2 os -c brew); then 
            if [ ! -d /usr/local/sbin ]; then 
                sudo mkdir /usr/local/sbin && sudo chmod 777 /usr/local/sbin
                echo 'export PATH=/usr/local/sbin:$PATH' >> $HOME/.bashrc
            fi;
            u2 install the_silver_searcher pstree openssh p7zip
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

if ! $(u hasValueq $NO_SWAP) && $(u os linux); then
    u _ED swap check
    if swapon --show | grep -q '^'; then
        u _ED "Swap is already enabled."
    else
        u _ED "No swap found. Creating a 4 GB swap file on /swap"
        if ! $(u has -p /swap); then sudo dd if=/dev/zero of=/swap bs=1M count=4096; fi;
        sudo chmod 600 /swap
        sudo mkswap /swap
        sudo swapon /swap
        u _ED "Swap created, writing to fstab"
        echo '/swap none swap sw 0 0' | sudo tee -a /etc/fstab
    fi; 
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
        u2 install nodejs npm
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
        pm2 install pm2-logrotate
        pm2 set pm2-logrotate:rotateInterval "0 0 1 * *"
        pm2 startup
    fi; 
fi;