## shell-simple

personalized shell sciprt

## setup

`./util setup`

## upgrade

`u2 help --upgrade`

## quick setup with dep

add `-d -n -b -p` to the end to add docker & node & bun & pm2

```sh
for url in "https://fastgit.cc/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "http://gh.ddlc.top/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "http://ghfast.top/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "https://ghproxy.monkeyray.net/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "https://cdn.akaere.online/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "http://down.npee.cn/?https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh"; do if command -v curl >/dev/null 2>&1 && curl -sSL "$url" -o util.sh 2>/dev/null; then echo "Downloaded from $url" && break; elif command -v wget >/dev/null 2>&1 && wget -O util.sh "$url" 2>/dev/null; then echo "Downloaded from $url" && break; fi; done; [ -f util.sh ] && chmod +x util.sh && ./util.sh setupEX
```

## quick setup

```sh
for url in "https://fastgit.cc/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "http://gh.ddlc.top/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "http://ghfast.top/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "https://ghproxy.monkeyray.net/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "https://cdn.akaere.online/https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh" "http://down.npee.cn/?https://raw.githubusercontent.com/Truth1984/shell-simple/refs/heads/main/util.sh"; do if command -v curl >/dev/null 2>&1 && curl -sSL "$url" -o util.sh 2>/dev/null; then echo "Downloaded from $url" && break; elif command -v wget >/dev/null 2>&1 && wget -O util.sh "$url" 2>/dev/null; then echo "Downloaded from $url" && break; fi; done; [ -f util.sh ] && chmod +x util.sh && ./util.sh setup || (echo "Download failed" && exit 1)
```
