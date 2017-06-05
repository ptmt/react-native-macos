#!/bin/bash
set -e

# Fix name conflicts with macOS
cat << EOF >> folly/prepend.h
#ifdef __APPLE__
#undef check
#endif
EOF

echo "$(cat folly/prepend.h)\n$(cat folly/dynamic.h)" > folly/dynamic.h
