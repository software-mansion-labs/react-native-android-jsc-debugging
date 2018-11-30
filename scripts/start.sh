#!/usr/bin/env bash

set -e
set -x

export ROOTDIR="$PWD"

adb forward tcp:9123 tcp:9123
./plist-websocket-proxy.rb &

cd $ROOTDIR/remotedebug-ios-webkit-adapter && yarn start



