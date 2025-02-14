# Enable exit on error - script will stop if any command fails
set -e

if [ "$USE_CACHED_DEPENDENCIES" = "true" ]; then
    mkdir -p $GITHUB_WORKSPACE/scip_install
    wget https://github.com/scipopt/scipoptsuite-deploy/releases/download/v0.7.0/libscip-macos-arm.zip
    unzip libscip-macos-arm.zip
    cp -r scip_install/* $GITHUB_WORKSPACE/scip_install/
else
    bash deps_macos_arm.bash
fi

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/release-$SOPLEX_VERSION.zip
unzip release-$SOPLEX_VERSION.zip
cd soplex-release-$SOPLEX_VERSION
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=Release -DGMP=false -DPAPILO=false -DMPFR=false -DBOOST=false
make -j2
make test
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION.zip
unzip v$SCIP_VERSION.zip
cd scip-$SCIP_VERSION
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=../../scip_install -DPAPILO=false -DZIMPL=false -DGMP=false -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=../../scip_install -DBOOST=false -DTPI=tny
make -j2
make test
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/gcg/archive/refs/tags/v$GCG_VERSION.zip
unzip v$GCG_VERSION.zip
cd gcg-$GCG_VERSION
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=false -DSYM=none
make -j2
make test
make install

cd $GITHUB_WORKSPACE
zip -r $GITHUB_WORKSPACE/libscip-macos-arm.zip scip_install/lib scip_install/include scip_install/bin
