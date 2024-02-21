#!/bin/bash

echo "run the stop app services"

sudo -i -u mbis_app ./stop_server_gracefully.sh || echo "Warning: Missing or Failed Stop Script" 