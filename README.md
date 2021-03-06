# proxy-trojan-go

Trojan-go client container with SOCKS5/HTTP/DNS proxy and QR code support. Running on x86 and arm/arm64 (Raspberry Pi).

![docker-build](https://github.com/samuelhbne/proxy-trojan-go/workflows/docker-buildx-latest/badge.svg)

## [Optional] How to build proxy-trojan-go docker image

```shell
$ git clone https://github.com/samuelhbne/proxy-trojan-go.git
$ cd proxy-trojan-go
$ docker build -t samuelhbne/proxy-trojan-go:amd64 -f Dockerfile.amd64 .
...
```

### NOTE1

- Please replace "amd64" with the arch match the current box accordingly. For example: "arm64" for AWS ARM64 platform like A1, t4g instance or 64bit Ubuntu on Raspberry Pi. "arm" for 32bit Raspbian.

## How to start proxy-trojan-go container

```shell
$ docker run --rm -it samuelhbne/proxy-trojan-go:amd64
proxy-trojan-go -d|--domain <trojan-go-domain> -w|--password <password> [-p|--port <port-number>] [-c|--china] [--wp <websocket-path>] [--sp <shadowsocks-pass>] [--sm <shadowsocks-method>]
    -d|--domain <trojan-go-domain>  Trojan-go server domain name
    -w|--password <password>        Password for Trojan-go server access
    -p|--port <port-num>            [Optional] Port number for Trojan-go server connection, default 443
    -m|--mux                        [Optional] Enable Trojan-go mux (incompatible with original Trojan server), default disable
    -c|--china                      [Optional] Enable China-site access without proxy, default disable
    --wp <websocket-path>           [Optional] Enable websocket with websocket-path setting, e.g. '/ws'. default disable
    --sp <shadowsocks-pass>         [Optional] Enable Shadowsocks AEAD with given password, default disable
    --sm <shadowsocks-method>       [Optional] Encryption method applied in Shadowsocks AEAD layer, default AES-128-GCM
$ docker run --name proxy-trojan-go -p 21080:1080 -p 65353:53/udp -p 28123:8123 -d samuelhbne/proxy-trojan-go:amd64 -d my-domain.com -w my-secret -c
...
```

### NOTE2

- Please replace "amd64" with the arch match the current box accordingly. For example: "arm64" for AWS ARM64 platform like A1, t4g instance or 64bit Ubuntu on Raspberry Pi. "arm" for 32bit Raspbian.
- Please replace "my-domain.com" and "my-secret" above with your FULL domain-name and Trojan-go service access password accordingly.
- Please replace 21080 with the port you want for SOCKS5 proxy TCP listerning.
- Please replace 28123 with the port you want for HTTP proxy TCP listerning.
- Please replace 65353 with the port you want for DNS UDP listerning.

## How to verify if proxy tunnel is working properly

```shell
$ curl -sSx socks5h://127.0.0.1:21080 http://ifconfig.co
12.34.56.78

$ curl -sSx http://127.0.0.1:28123 http://ifconfig.co
12.34.56.78

$ dig +short @127.0.0.1 -p 65353 twitter.com
104.244.42.193
104.244.42.129

$ docker exec -it proxy-trojan-go proxychains whois 104.244.42.193|grep OrgId
[proxychains] config file found: /etc/proxychains/proxychains.conf
[proxychains] preloading /usr/lib/libproxychains4.so
[proxychains] DLL init: proxychains-ng 4.14
[proxychains] Strict chain  ...  127.0.0.1:1080  ...  whois.arin.net:43  ...  OK
OrgId:          TWITT
```

### NOTE3

- curl should return the VPN server address given above if SOCKS5/HTTP proxy works properly.
- dig should return resolved IP recorders of twitter.com if DNS server works properly.
- Whois should return "OrgId: TWITT". That means the IP address returned from dig query belongs to twitter.com indeed, hence untaminated.
- Whois was actually running inside the proxy container through the proxy tunnel to avoid potential access blocking.
- Please have a look over the sibling project [server-trojan-go](https://github.com/samuelhbne/server-trojan-go) if you'd like to set a Trojan-go server.

## How to get the Trojan-go QR code for mobile connection

```shell
$ docker exec -it proxy-trojan-go /status.sh
VPS-Server: 12.34.56.78
Trojan-go-URL: trojan://my-secret@my-domain.com:443
```

![QR code example](https://github.com/samuelhbne/proxy-trojan-go/blob/master/images/qr-trojan-go.png)

## How to stop and remove the running container

```shell
$ docker stop proxy-trojan-go
...
$ docker rm proxy-trojan-go
```
