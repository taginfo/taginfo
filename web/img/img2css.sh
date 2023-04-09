#!/bin/sh

DATA=`base64 -w0 "$1" | tr -d '='`

echo "url(data:image/svg+xml;base64,$DATA);"

