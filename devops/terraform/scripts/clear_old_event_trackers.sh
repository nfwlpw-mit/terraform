#!/bin/bash

serverips=`terraform output api_private_ips`;


query="DELETE from simplisafe_LIVE.ss_event_tracking where server_ip NOT IN ("
for serverip in $serverips ; do
  query="$query \"${serverip}\","
done
query=`echo $query | sed 's/,$//g'`
query="$query );"

echo $query
  
