#!/usr/bin/env bash
set -e

ID=$1
DIR=${OUTDIR:-"/var/hls"}
MINUTES=${2:-10}
OPTIONS=${3:-'-d'}
PLAYLIST=${4:-"https://openwebinars.net/academia/hls/$ID.m3u8"}
TIMEOUT=$(echo  $MINUTES*60 | bc)
[ -d "$DIR/${ID::2}/$ID" ] && find "$DIR/${ID::2}/$ID" -type f -size 21c -exec rm {} \;
# The proxy will stop automatically when all segments are downloaded (VoD).
# timeout is kept as a safety net in case something goes wrong.
timeout --signal=TERM "${TIMEOUT}s" pipenv run -- ./hlsproxy.py $OPTIONS -o "$DIR/${ID::2}/$ID" $PLAYLIST || EXIT_CODE=$?
if [ "${EXIT_CODE:-0}" -eq 124 ]; then
    echo "Warning: Process was killed by timeout after $MINUTES minutes"
else
    echo "Download finished"
fi
