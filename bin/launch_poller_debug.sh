#!/bin/bash

DIR=$(cd $(dirname "$0"); pwd)
BIN=$DIR"/../bin"
ETC=$DIR"/../etc"
DEBUG_PATH="/tmp/poller.debug"

echo "Launching Poller (that launches the checks) in debug mode to the file $DEBUG_PATH"
$BIN/shinken-poller -d -c $ETC/pollerd.ini --debug $DEBUG_PATH
