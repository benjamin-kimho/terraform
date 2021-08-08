#!/bin/bash

cd ~/ &&
docker-compose pull &&
./stop_systemd_resolved.sh &&
docker-compose up -d &&
sudo reboot
