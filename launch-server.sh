#!/bin/bash
# A simple script to launch the easymap server, takes one argument: a port number between 8100 and 8200

nohup ./src/Python3/.localpython/bin/python3 -m http.server $1 &
