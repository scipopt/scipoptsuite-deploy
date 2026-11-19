# Enable exit on error - script will stop if any command fails
set -e

cd $GITHUB_WORKSPACE
yum install gcc gcc-c++ libgfortran git patch wget lapack-static unzip zip make glibc-static -y
rm -f /usr/lib64/liblapack.s*
rm -f /usr/lib64/libblas.*
rm -rf /usr/include/boost

mkdir scip_install
mkdir scip_install/share
echo "enable_shared=no
enable_java=no
enable_sipopt=no
with_pic=yes
with_metis_cflags=\"-I${GITHUB_WORKSPACE}/metis/include/\"
with_metis_lflags=\"-L${GITHUB_WORKSPACE}/metis/lib -lmetis -lGKlib -lm\"
with_lapack_lflags=\"-llapack_pic -lblas -lgfortran -lm\"
LT_LDFLAGS=-all-static
LDFLAGS=-static" > $GITHUB_WORKSPACE/scip_install/share/config.site

# dependencies: restored from the cache, or built and saved for the next run
if [ -f $GITHUB_WORKSPACE/deps.tar ]; then
    tar -xPf $GITHUB_WORKSPACE/deps.tar
else
    bash -x $GITHUB_WORKSPACE/.github/workflows/scripts/deps/linux.bash
    tar -cPf $GITHUB_WORKSPACE/deps.tar /usr/include/boost /usr/lib64/libblas.a $GITHUB_WORKSPACE/metis $GITHUB_WORKSPACE/scip_install
fi

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/v$SOPLEX_VERSION_FULL.zip
unzip v$SOPLEX_VERSION_FULL.zip
cd soplex-$SOPLEX_VERSION_FULL
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=Release -DGMP=false -DPAPILO=false -DBOOST=true
make -j$(nproc)
if [ "$TESTS" = "ON" ]; then
    # examples rebuild libscip, so they run one at a time
    ctest -j$(nproc) --output-on-failure -E "^examples-"
    ctest --output-on-failure -R "^examples-"
fi
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION_FULL.zip
unzip v$SCIP_VERSION_FULL.zip
cd scip-$SCIP_VERSION_FULL
mkdir build
cd build
cmake .. --preset interface -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DSHARED=$SHARED -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=$GITHUB_WORKSPACE/scip_install -DPAPILO=false -DZIMPL=false -DGMP=false -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=$GITHUB_WORKSPACE/scip_install -DTPI=tny -DCMAKE_VERBOSE_MAKEFILE=1 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(nproc)
if [ "$TESTS" = "ON" ]; then
    # examples rebuild libscip, so they run one at a time
    ctest -j$(nproc) --output-on-failure -E "^examples-"
    ctest --output-on-failure -R "^examples-"
fi
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/gcg/archive/refs/tags/v$GCG_VERSION_FULL.zip
unzip v$GCG_VERSION_FULL.zip
cd gcg-$GCG_VERSION_FULL
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DSHARED=$SHARED -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=false -DSYM=none -DCMAKE_VERBOSE_MAKEFILE=1 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(nproc)
if [ "$TESTS" = "ON" ]; then
    # examples rebuild libscip, so they run one at a time
    ctest -j$(nproc) --output-on-failure -E "^examples-"
    ctest --output-on-failure -R "^examples-"
fi
make install

cd $GITHUB_WORKSPACE
mkdir -p scip_install/lib
rm -rf scip_install/lib64/cmake
mv scip_install/lib64/* scip_install/lib/.

bash -x $GITHUB_WORKSPACE/.github/workflows/scripts/relocatable_bin.bash

# Detect architecture and set appropriate filename
if [[ "$ARM" == "ON" ]]; then
    FILENAME="libscip-linux-arm.zip"
else
    FILENAME="libscip-linux.zip"
fi

zip -r $GITHUB_WORKSPACE/$FILENAME scip_install/lib scip_install/include scip_install/bin
