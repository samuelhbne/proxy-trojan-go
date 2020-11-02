#!/bin/bash

usage() {
	echo "proxy-trojan-go -d|--domain <trojan-go-domain> -w|--password <password> [-p|--port <port-number>] [-c|--china] [--wp <websocket-path>] [--sp <shadowsocks-pass>] [--sm <shadowsocks-method>]"
	echo "    -d|--domain <trojan-go-domain>  Trojan-go server domain name"
	echo "    -w|--password <password>        Password for Trojan-go server access"
	echo "    -p|--port <port-num>            [Optional] Port number for Trojan-go server connection, default 443"
	echo "    -m|--mux                        [Optional] Enable Trojan-go mux (incompatible with original Trojan server), default disable"
	echo "    -c|--china                      [Optional] Enable China-site access without proxy, default disable"
	echo "    --wp <websocket-path>           [Optional] Enable websocket with websocket-path setting, e.g. '/ws'. default disable"
	echo "    --sp <shadowsocks-pass>         [Optional] Enable Shadowsocks AEAD with given password, default disable"
	echo "    --sm <shadowsocks-method>       [Optional] Encryption method applied in Shadowsocks AEAD layer, default AES-128-GCM"
}

TEMP=`getopt -o d:w:p:mc --long domain:,password:,port:,mux,china,wp:,sp:,sm: -n "$0" -- $@`
if [ $? != 0 ] ; then usage; exit 1 ; fi

eval set -- "$TEMP"
while true ; do
	case "$1" in
		-d|--domain)
			TJDOMAIN="$2"
			shift 2
			;;
		-w|--password)
			PASSWORD="$2"
			shift 2
			;;
		-p|--port)
			TJPORT="$2"
			shift 2
			;;
		-m|--mux)
			TJGMUX="true"
			shift 1
			;;
		-c|--china)
			RTCHINA="true"
			shift 1
			;;
		--wp)
			WSPATH="$2"
			shift 2
			;;
		--sp)
			SSPASSWORD="$2"
			shift 2
			;;
		--sm)
			SSMETHOD="$2"
			shift 2
			;;
		--)
			shift
			break
			;;
		*)
			usage;
			exit 1
			;;
	esac
done

if [ -z "${TJDOMAIN}" ] || [ -z "${PASSWORD}" ]; then
	usage
	exit 1
fi

if [ -z "${TJPORT}" ]; then
	TJPORT=443
fi

if [ -z "${TJGMUX}" ]; then
	TJGMUX="false"
fi

if [ -z "${RTCHINA}" ]; then
	RTCHINA="false"
fi

if [ -z "${SSMETHOD}" ]; then
	SSMETHOD="AES-128-GCM"
fi

cat /etc/trojan-go/client.yaml  \
	| yq -y " .\"local-addr\" |= \"0.0.0.0\" " \
	| yq -y " .\"local-port\" |= 1080 " \
	| yq -y " .\"remote-addr\" |= \"${TJDOMAIN}\" " \
	| yq -y " .\"remote-port\" |= ${TJPORT} " \
	| yq -y " .\"password\"[0] |= \"${PASSWORD}\" " \
	| yq -y " .\"ssl\".\"sni\" |= \"${TJDOMAIN}\" " \
	| yq -y " .\"mux\".\"enabled\" |= ${TJGMUX} " \
	| yq -y " .\"router\".\"enabled\" |= ${RTCHINA} " \
	>/etc/trojan-go/client.yml

if [ -n "${WSPATH}" ]; then
	cat /etc/trojan-go/client.yml \
		|yq -y ". + {websocket:{enabled:true,path:\"${WSPATH}\",host:\"${DOMAIN}\"}}" > /tmp/client.yml.1
	mv /tmp/client.yml.1 /etc/trojan-go/client.yml
fi

if [ -n "${SSPASSWORD}" ]; then
	cat /etc/trojan-go/client.yml \
		|yq -y ". + {shadowsocks:{enabled:true,method:\"${SSMETHOD}\",password:\"${SSPASSWORD}\"}}" > /tmp/client.yml.1
	mv /tmp/client.yml.1 /etc/trojan-go/client.yml
fi

/usr/bin/nohup /usr/local/bin/trojan-go -config /etc/trojan-go/client.yml &
/root/polipo/polipo -c /root/polipo/config
exec /usr/bin/dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml
