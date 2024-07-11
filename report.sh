#!/bin/bash

source ~/.bash_profile
id=$GAIANET_ID
chain=?
network=testnet
type="node"
group=node

version=$(gaianet --version | awk '{print $NF}')

#health=$(curl -sS -I "http://localhost:7000/health" | head -1 | awk '{print $2}')
#if [ -z $health ]; then health=null; fi
#case $health in
# 200) status=ok ;;
# *)   status=warning;message="health - $health" ;;
#esac

pid=$(pidof qdrant)

if [ -z $pid ]
then status="error"; message="qdrant not running";
else status="ok";
fi

cat << EOF
{
  "id":"$id",
  "machine":"$MACHINE",
  "version":"$version",
  "chain":"$chain",
  "network":"$network",
  "type":"node",
  "status":"$status",
  "message":"$message",
  "pid":$pid,
  "updated":"$(date --utc +%FT%TZ)"
}
EOF

# send data to influxdb
if [ ! -z $INFLUX_HOST ]
then
 curl --request POST \
 "$INFLUX_HOST/api/v2/write?org=$INFLUX_ORG&bucket=$INFLUX_BUCKET&precision=ns" \
  --header "Authorization: Token $INFLUX_TOKEN" \
  --header "Content-Type: text/plain; charset=utf-8" \
  --header "Accept: application/json" \
  --data-binary "
    report,id=$id,machine=$MACHINE,grp=$group status=\"$status\",message=\"$message\",version=\"$version\",url=\"$url\",chain=\"$chain\",network=\"$network\" $(date +%s%N) 
    "
fi
