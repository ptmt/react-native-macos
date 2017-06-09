#!/bin/bash
set -ex

# Script used to run iOS tests.
# If not arguments are passed to the script, it will only compile
# the UIExplorer.
# If the script is called with a single argument "test", we'll
# also run the UIExplorer integration test (needs JS and packager):
# ./objc-test-ios.sh test

SCRIPTS=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT=$(dirname "$SCRIPTS")

cd "$ROOT"

SCHEME="UIExplorer"
SDK="macosx10.12"
DESTINATION="platform=OS X,arch=x86_64"

# If there is a "test" argument, pass it to the test script.
. ./scripts/objc-test.sh $1
