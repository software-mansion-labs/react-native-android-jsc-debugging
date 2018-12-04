#!/usr/bin/env bash

set -e
set -x

export ROOTDIR="$PWD"

ensureSubmodules() {
    git submodule update --init
}

buildJsc() {
    cd $ROOTDIR/jsc-android-buildscripts
    if [[ ! -d $ROOTDIR/jsc-android-buildscripts/build/download ]]; then
        yarn run download
    fi
    yarn start
}

prepareReactNative() {
    cd $ROOTDIR/react-native/react-native-cli && yarn
}

prepareRemoteDebugAdapter() {
    cd $ROOTDIR/remotedebug-ios-webkit-adapter && yarn
    cd $ROOTDIR/remotedebug-ios-webkit-adapter && git reset --hard && cd .. && patch -d ./remotedebug-ios-webkit-adapter -p1 < remotedebug-ios-webkit-adapter.patch
}

preparePlistProxy() {
    cd $ROOTDIR
    if ! command -v bundle >/dev/null 2>&1; then
        sudo gem install bundler
    fi
    bundle
}


ensureSubmodules
buildJsc
prepareReactNative
prepareRemoteDebugAdapter
preparePlistProxy
