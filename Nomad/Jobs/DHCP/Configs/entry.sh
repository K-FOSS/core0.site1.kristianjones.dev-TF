#!/bin/sh
echo "HelloWorld"

/usr/sbin/keactrl start -c /local/keactrl.conf

echo "Starking Stork Agent"

exec watch -n 5 /usr/sbin/keactrl -c /local/keactrl.conf status