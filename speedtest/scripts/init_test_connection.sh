#!/bin/sh
FILE="/app/speedtest/test_connection.log"

HOSTNAME_COMMAND=${HOSTNAME_COMMAND:=hostname}
if ! HOSTVALUE=$($HOSTNAME_COMMAND 2>&1); then
        HOSTVALUE=local
fi

DATABASE_PATH=${DATABASE_PATH:=db}

while true 
do 
    TIMESTAMP=$(date '+%s')

	COMMAND=/app/speedtest/speedtest-cli
	if [ -n "${TEST_SERVER}" ]; then
		COMMAND="${COMMAND} --server ${TEST_SERVER}"
	fi

	eval "${COMMAND} > ${FILE}"

    DOWNLOAD=$(cat $FILE | grep "Download:" | awk -F " " '{print $2}')
    UPLOAD=$(cat $FILE | grep "Upload:" | awk -F " " '{print $2}')
    PING=$(ping -qc1 google.com 2>&1 | awk -F'/' 'END {print (/^round-trip/? $4:"-100")}')
    echo "Download: $DOWNLOAD Upload: $UPLOAD Ping: $PING   $TIMESTAMP"
    curl -i -XPOST "http://${DATABASE_PATH}:8086/write?db=speedtest" --data-binary "download,host=$HOSTVALUE value=$DOWNLOAD"
    curl -i -XPOST "http://${DATABASE_PATH}:8086/write?db=speedtest" --data-binary "upload,host=$HOSTVALUE value=$UPLOAD"
    curl -i -XPOST "http://${DATABASE_PATH}:8086/write?db=speedtest" --data-binary "ping,host=$HOSTVALUE value=$PING"
    sleep $TEST_INTERVAL

done
