#!/bin/bash

serverips=`terraform output api_ips`;

for serverip in $serverips ; do
  ssh -i ~/.ssh/PrdCommon.pem centos@${serverip} "sudo systemctl restart pm2";
done
