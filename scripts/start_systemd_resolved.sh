#!/bin/bash

printf "\n\nStarting system resolver...\n" &&
sudo systemctl start systemd-resolved &&
sudo systemctl enable systemd-resolved
