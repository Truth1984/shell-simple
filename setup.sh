#!/usr/bin/env bash

echo SCRIPT_VERSION=1.6.0

if [[ -z "$(command -v u)" ]]; then
    URLS=("https://fastgit.cc/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "http://gh.ddlc.top/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "http://ghfast.top/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "https://ghproxy.monkeyray.net/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "https://cdn.akaere.online/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "http://down.npee.cn/?https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh"); for url in "${URLS[@]}"; do if command -v curl >/dev/null 2>&1 && curl -sSL "$url" -o util.sh 2>/dev/null; then echo "Downloaded from $url" && break; elif command -v wget >/dev/null 2>&1 && wget -O util.sh "$url" 2>/dev/null; then echo "Downloaded from $url" && break; fi; done; [ -f util.sh ] && chmod +x util.sh && ./util.sh setupEX || (echo "Download failed" && exit 1)
    source ~/.bash_mine
fi;

if [[ -z "$(command -v u)" ]]; then echo u not setup correctly && exit 1; fi;

source $HOME/.bash_env

if ! $(u hasValue $_u_INIT_DEP); then

    if ! $(u string -c "$@" "container"); then u upgrade; fi;

    if $(u string -c "$@" "container"); then
        u installC nano make psmisc net-tools coreutils screen

        if $(u os -c apk); then u installC the_silver_searcher; fi;
        if $(u os -c apt); then u installC software-properties-common silversearcher-ag; fi;
        if $(u os -c yum); then u installC redhat-lsb-core epel-release the_silver_searcher; fi;

        NO_SWAP=true; 

    elif ! $(u os -c win); then

        u install wget curl nano git make psmisc net-tools nethogs coreutils sudo screen tcpdump iftop gnupg tmux shfmt

        if $(u os -c yum); then
            u install redhat-lsb-core epel-release the_silver_searcher udisks2 openssh-server openssh-clients p7zip
        fi;

        if $(u os -c apk); then
            u install the_silver_searcher openrc openssh p7zip util-linux
        fi;
        
        if $(u os -c apt); then
            u install software-properties-common silversearcher-ag udisks2 openssh-server openssh-client p7zip-full
        fi;

        if $(u os -c brew); then 
            if [ ! -d /usr/local/sbin ]; then 
                sudo mkdir /usr/local/sbin && sudo chmod 777 /usr/local/sbin
                echo 'export PATH=/usr/local/sbin:$PATH' >> $HOME/.bashrc
            fi;
            u install the_silver_searcher pstree openssh p7zip
        fi;

    fi;

    if $(u hasFile /etc/resolv.conf) && ! $(u hasContent /etc/resolv.conf 1.0.0.1); then
        sudo sh -c "printf 'nameserver\t1.0.0.1\n' >> /etc/resolv.conf"
        sudo sh -c "printf 'nameserver\t8.8.8.8\n' >> /etc/resolv.conf"
        sudo sh -c "printf 'nameserver\t8.8.4.4\n' >> /etc/resolv.conf"
    fi;

    if $(u hasFile /etc/systemd/resolved.conf) && ! $(u hasContent /etc/systemd/resolved.conf 'DNS=1.0.0.1'); then
        sudo sh -c "printf 'DNS=1.0.0.1 8.8.8.8 8.8.4.4\n' >> /etc/systemd/resolved.conf" 
    fi;

    echo "_u_INIT_DEP=1" >> $HOME/.bash_env
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
if $(u string -c "$@" "ALL"); then ALL=true; fi;

if $(u string -c "$@" "docker") || $ALL; then 
    if ! $(u hasCmd docker); then 
        u get -r https://raw.gitmirror.com/docker/docker-install/master/install.sh --mirror Aliyun
        sudo usermod -aG docker $(whoami)
       
        if $(u hasCmd systemctl); then
            sudo systemctl start docker.service
            sudo systemctl enable docker.service
        fi; 
    fi; 
fi;

if $(u string -c "$@" "node") || $ALL; then 
    if ! $(u hasCmd node); then 
        u install nodejs npm
    fi;
    npm config set registry http://registry.npmmirror.com
    # original:
    # npm config set registry https://registry.npmjs.org
fi;

if $(u string -c "$@" "bun") || $ALL; then 
    if ! $(u hasCmd bun); then 
        u install unzip
        u np npm i -g bun --loglevel verbose
        if ! $(u hasContent $HOME/.bash_env BUN_INSTALL); then
            echo 'export BUN_INSTALL="$HOME/.bun"' >> $HOME/.bash_env 
            echo 'export PATH="$BUN_INSTALL/bin:$PATH"' >> $HOME/.bash_env 
        fi; 
    fi; 
fi;

if $(u string -c "$@" "pm2") || $ALL; then 
    if ! $(u hasCmd pm2); then 
        bun i -g pm2
        u np pm2 install pm2-logrotate
        pm2 set pm2-logrotate:rotateInterval "0 0 1 * *"
        pm2 startup
    fi; 
fi;