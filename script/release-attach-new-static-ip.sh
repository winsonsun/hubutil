#!/bin/bash

while getopts h:u:k:y:p:r:d: flag
do
    case "${flag}" in
        s) static_ip_name=${OPTARG};;
        n) instance_name=${OPTARG};;
    esac
done

static_ip_name=${static_ip_name:="StaticIp-new"}
instance_name=${instance_name:="skshell"}

aws lightsail detach-static-ip --static-ip-name "$static_ip_name" --region us-east-2 > /dev/null
aws lightsail release-static-ip --static-ip-name "$static_ip_name" --region us-east-2 > /dev/null
aws lightsail allocate-static-ip --static-ip-name "$static_ip_name" --region us-east-2 > /dev/null
aws lightsail attach-static-ip  --static-ip-name "$static_ip_name" --instance-name "$instance_name" > /dev/null

aws lightsail get-static-ip --no-paginate --static-ip-name "$static_ip_name" | jq -r '.staticIp.ipAddress'
