#!/bin/bash

echo "RUN STOP Server" 
FILE=./stop_server_gracefully.sh
if [ -f "$FILE" ]; then
    echo "$FILE exists."
    sudo -i -u mbis_app ./stop_server_gracefully.sh
fi

