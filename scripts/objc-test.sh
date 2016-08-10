#!/bin/bash

set -ex

SCRIPTS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(dirname $SCRIPTS)

cd $ROOT

function cleanup {
  EXIT_CODE=$?
  set +e
  echo "EXIT_CODE=$EXIT_CODE"
  echo "SERVER_PID=$SERVER_PID"
  if [ $EXIT_CODE -ne 0 ];
  then
    WATCHMAN_LOGS=/usr/local/Cellar/watchman/3.1/var/run/watchman/$USER.log
    [ -f $WATCHMAN_LOGS ] && cat $WATCHMAN_LOGS
  fi
<<<<<<< HEAD
  SERVER_PID=$(lsof -n -i4TCP:8081 | grep 'LISTEN' | awk -F" " '{print $2}')
  [ $SERVER_PID ] && kill -9 $SERVER_PID
=======
  # kill whatever is occupying port 8081 
  lsof -i tcp:8081 | awk 'NR!=1 {print $2}' | xargs kill
>>>>>>> 0561336ae4f2e9bd9d418c18b30bc32951f2c2ac
}
trap cleanup EXIT

XCODE_PROJECT="Examples/UIExplorer/UIExplorer.xcodeproj"
XCODE_SCHEME="UIExplorer"
XCODE_SDK="iphonesimulator"
if [ -z "$XCODE_DESTINATION" ]; then
  XCODE_DESTINATION="platform=iOS Simulator,name=iPhone 5s,OS=9.3"
fi

# Support for environments without xcpretty installed
set +e
OUTPUT_TOOL=$(which xcpretty)
set -e

# TODO: We use xcodebuild because xctool would stall when collecting info about
# the tests before running them. Switch back when this issue with xctool has
# been resolved.
<<<<<<< HEAD
xcodebuild \
  -project Examples/UIExplorer/UIExplorer.xcodeproj \
  -scheme UIExplorer \
  -sdk macosx10.11 \
  -destination 'platform=OS X,arch=x86_64' \
  test
| xcpretty && exit ${PIPESTATUS[0]}
=======
if [ -z "$OUTPUT_TOOL" ]; then
  xcodebuild \
    -project $XCODE_PROJECT \
    -scheme $XCODE_SCHEME \
    -sdk $XCODE_SDK \
    -destination "$XCODE_DESTINATION" \
    test
else
  xcodebuild \
    -project $XCODE_PROJECT \
    -scheme $XCODE_SCHEME \
    -sdk $XCODE_SDK \
    -destination "$XCODE_DESTINATION" \
    test | $OUTPUT_TOOL && exit ${PIPESTATUS[0]}
fi
>>>>>>> 0561336ae4f2e9bd9d418c18b30bc32951f2c2ac
