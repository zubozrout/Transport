#!/bin/bash

# Switch to current directory
cd "${0%/*}"
# Build the project
clickable -k 16.04 --arch="armhf" build
# Package a .click
clickable click-build
# Review the package
click-review build/*.click
