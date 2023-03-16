#!/bin/bash

APT="debian:stable-slim"
YUM="oraclelinux:9"
APK="alpine:edge"
APK2="alpine-bash"
verbose=0

echo "====== HOST ======"
verbose=$verbose ./util.sh $@
echo "====== END ======"

echo "====== $APT ======"
docker run -it --rm -e verbose=$verbose -v "$(pwd)"/util.sh:/util.sh $APT /util.sh $@
echo "====== END ======"

echo "====== $YUM ======"
docker run -it --rm -e verbose=$verbose -v "$(pwd)"/util.sh:/util.sh $YUM /util.sh $@
echo "====== END ======"

echo "====== $APK2 ======"
if ! $(docker image ls | grep -q $APK2); then 
        echo "building $APK2"
        printf "FROM $APK\nRUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && apk add --no-cache bash\nCMD /bin/bash" > Dockerfile
        docker build -t $APK2 . && rm Dockerfile
fi;
docker run -it --rm -e verbose=$verbose -v "$(pwd)"/util.sh:/util.sh $APK2 /util.sh $@
echo "====== END ======"


