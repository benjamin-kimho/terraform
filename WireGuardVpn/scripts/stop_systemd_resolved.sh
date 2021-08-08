#!/bin/bash

printf "\n\nDisabling system resolver...\n" &&
sudo systemctl stop systemd-resolved &&
sudo systemctl disable systemd-resolved
