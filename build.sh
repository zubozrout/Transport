#!/bin/bash

# Switch to current directory
cd "${0%/*}"
# Delete build data
clickable clean
# Build the project
clickable -k 16.04 --arch="armhf" build
# Package a .click
clickable -k 16.04 click-build
# Review the package
click-review build/*.click
