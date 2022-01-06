#!/bin/bash

set -e

export PROJ_DB_CACHE_DIR="$HOME/.ccache"

echo "CCACHE_DIR=${CCACHE_DIR}"
ccache -M 200M

CC="clang" CXX="clang++" CMAKE_BUILD_TYPE=RelWithDebInfo ./travis/install.sh

echo "CCACHE_DIR=${CCACHE_DIR}"

