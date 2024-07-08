## shell-simple

personalized shell sciprt

## setup

`./util setup`

## upgrade

`u2 help --upgrade`

## quick setup with dep

add `-d -n -b -p` to the end to add docker & node & bun & pm2

```sh
ssurl="https://raw.gitmirror.com/Truth1984/shell-simple/main/util.sh"; if $(command -v curl &> /dev/null); then curl $ssurl -o util.sh; elif $(command -v wget &> /dev/null); then wget -O util.sh $ssurl; fi; chmod 777 util.sh && ./util.sh setupEX
```

## quick setup

```sh
ssurl="https://raw.gitmirror.com/Truth1984/shell-simple/main/util.sh"; if $(command -v curl &> /dev/null); then curl $ssurl -o util.sh; elif $(command -v wget &> /dev/null); then wget -O util.sh $ssurl; fi; chmod 777 util.sh && ./util.sh setup
```
