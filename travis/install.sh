#!/bin/bash

# set -e

UNAME="$(uname)" || UNAME=""
if test "x${NPROC}" = "x"; then
    if test "${UNAME}" = "Linux" ; then
        NPROC=$(nproc);
    elif test "${UNAME}" = "Darwin" ; then
        NPROC=$(sysctl -n hw.ncpu);
    fi
    if test "x${NPROC}" = "x"; then
        NPROC=2;
    fi
fi
echo "NPROC=${NPROC}"
export MAKEFLAGS="-j ${NPROC}"

# Use ccache if it's available
if command -v ccache &> /dev/null
then
    USE_CCACHE=ON
    ccache -s
else
    USE_CCACHE=OFF
fi

if test "x${CMAKE_BUILD_TYPE}" = "x"; then
    CMAKE_BUILD_TYPE=Release
fi

echo "Make dist tarball, and check consistency"
mkdir build_dist
cd build_dist
cmake -D BUILD_TESTING=OFF ..
make dist

TAR_FILENAME=$(ls *.tar.gz)
TAR_DIRECTORY=$(basename $TAR_FILENAME .tar.gz)
mkdir ../build_from_dist
cd ../build_from_dist
tar xvzf ../build_dist/$TAR_FILENAME

# There's a nasty #define CS in a Solaris system header. Avoid being caught about that again
CXXFLAGS="-DCS=do_not_use_CS_for_solaris_compat $CXXFLAGS"

echo "Build shared configuration from generated tarball"
cd $TAR_DIRECTORY
mkdir shared_build
cd shared_build
cmake \
  -D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
  -D USE_CCACHE=${USE_CCACHE} \
  -D RUN_NETWORK_DEPENDENT_TESTS=OFF \
  -D BUILD_SHARED_LIBS=ON \
  -D CMAKE_INSTALL_PREFIX=/tmp/proj_shared_install_from_dist \
  ..
make

ctest
make install

echo "otool -L"
otool -L /tmp/proj_shared_install_from_dist/lib/libproj.dylib
echo "otool -l"
otool -l /tmp/proj_shared_install_from_dist/lib/libproj.dylib

echo "otool -L"
otool -L /tmp/proj_shared_install_from_dist/bin/projinfo
echo "otool -l"
otool -l /tmp/proj_shared_install_from_dist/bin/projinfo

$TRAVIS_BUILD_DIR/test/postinstall/test_cmake.sh /tmp/proj_shared_install_from_dist shared
$TRAVIS_BUILD_DIR/test/postinstall/test_autotools.sh /tmp/proj_shared_install_from_dist shared

echo "Build static configuration from generated tarball"
cd ..
mkdir static_build
cd static_build
cmake \
  -D CMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE} \
  -D USE_CCACHE=${USE_CCACHE} \
  -D RUN_NETWORK_DEPENDENT_TESTS=OFF \
  -D BUILD_SHARED_LIBS=OFF \
  -D CMAKE_INSTALL_PREFIX=/tmp/proj_static_install_from_dist \
  ..
make

ctest
make install

echo "otool -L"
otool -L /tmp/proj_static_install_from_dist/bin/projinfo
echo "otool -l"
otool -l /tmp/proj_static_install_from_dist/bin/projinfo

$TRAVIS_BUILD_DIR/test/postinstall/test_cmake.sh /tmp/proj_static_install_from_dist static
$TRAVIS_BUILD_DIR/test/postinstall/test_autotools.sh /tmp/proj_static_install_from_dist static
