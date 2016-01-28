#!/bin/bash

set -e

SCRIPTS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(dirname $SCRIPTS)

export REACT_PACKAGER_LOG="$ROOT/server.log"

cd $ROOT

function cleanup {
  EXIT_CODE=$?
  set +e

  if [ $EXIT_CODE -ne 0 ];
  then
    WATCHMAN_LOGS=/usr/local/Cellar/watchman/3.1/var/run/watchman/$USER.log
    [ -f $WATCHMAN_LOGS ] && cat $WATCHMAN_LOGS

    [ -f $REACT_PACKAGER_LOG ] && cat $REACT_PACKAGER_LOG
  fi
  [ $SERVER_PID ] && kill -9 $SERVER_PID
}
trap cleanup EXIT

./packager/packager.sh --nonPersistent &
SERVER_PID=$!
xctool \
  -project Examples/UIExplorer/UIExplorer.xcodeproj \
<<<<<<< HEAD
  -scheme UIExplorer \
  -sdk macosx10.11 \
  -destination 'platform=OS X,arch=x86_64' \
=======
  -scheme UIExplorer -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 5,OS=9.2' \
>>>>>>> ae45d8bd4cc7b0fc810c3f21dcf2c7188ae3097d
  test
