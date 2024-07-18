## shell-simple

personalized shell sciprt

## setup

`./util setup`

## upgrade

`u2 help --upgrade`

## quick setup with dep

add `-d -n -b -p` to the end to add docker & node & bun & pm2

```sh
ssurl="https://raw.gitmirror.com/Truth1984/shell-simple/main/util.sh"; if command -v curl > /dev/null 2>&1; then curl -sSL $ssurl -o util.sh; elif command -v wget > /dev/null 2>&1; then wget -O util.sh $ssurl; else echo "Neither curl nor wget found"; exit 1; fi; chmod 777 util.sh && ./util.sh setupEX
```

## quick setup

```sh
ssurl="https://raw.gitmirror.com/Truth1984/shell-simple/main/util.sh"; if command -v curl > /dev/null 2>&1; then curl -sSL $ssurl -o util.sh; elif command -v wget > /dev/null 2>&1; then wget -O util.sh $ssurl; else echo "Neither curl nor wget found"; exit 1; fi; chmod 777 util.sh && ./util.sh setup
```
