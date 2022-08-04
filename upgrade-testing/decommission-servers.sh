#!/bin/sh

for container in $(terraform -chdir=original-servers output -json containers | jq -r '.[]')
do
   docker stop $container
done