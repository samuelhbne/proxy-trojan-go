#!/bin/bash

usage() {
	echo "proxy-trojan-go -d|--domain <trojan-go-domain> -w|--password <password> [-p|--port <port-number>] [-c|--china]"
	echo "    -d|--domain <trojan-go-domain>  Trojan-go server domain name"
	echo "    -w|--password <password>        Password for Trojan-go server access"
	echo "    -p|--port <port-num>            [Optional] Port number for Trojan-go server connection, default 443"
	echo "    -m|--mux                        [Optional] Enable Trojan-go mux (incompatible with original Trojan server), default disable"
	echo "    -c|--china                      [Optional] Enable China-site access without proxy, default disable"
}

TEMP=`getopt -o d:w:p:mc --long domain:,password:,port:,mux,china -n "$0" -- $@`
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

/usr/bin/nohup /usr/local/bin/trojan-go -config /etc/trojan-go/client.yml &
/root/polipo/polipo -c /root/polipo/config
exec /usr/bin/dnscrypt-proxy -config /etc/dnscrypt-proxy/dnscrypt-proxy.toml
