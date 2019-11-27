#!/usr/bin/env bash
set -e

ID=$1
DIR=${OUTDIR:-"/var/hls"}
MINUTES=${2:-10}
TIMEOUT=$(echo  $MINUTES*30 | bc)
pipenv run -- ./hlsproxy.py -d -o "$DIR/${ID::2}/$ID" "https://openwebinars.net/academia/hls/$ID.m3u8" &
echo "Process $! will be killed after $TIMEOUT seconds"
sleep $TIMEOUT && kill $!
echo "Sended KILL to $!"