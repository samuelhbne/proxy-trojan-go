#!/bin/bash

TJHOST=`cat /etc/trojan-go/client.yml| yq -r ' ."remote-addr" '`
TJPORT=`cat /etc/trojan-go/client.yml| yq -r ' ."remote-port" '`
TJPASS=`cat /etc/trojan-go/client.yml| yq -r ' ."password"[0] '`

TJIP=`dig +short $TJHOST|head -n1`
if [ -z "$TJIP" ]; then
    TJIP=$TJHOST
fi

echo "VPS-Server: $TJIP"
echo "Trojan-go-URL: trojan://${TJPASS}@${TJHOST}:${TJPORT}"
qrcode-terminal "trojan://${TJPASS}@${TJHOST}:${TJPORT}"
