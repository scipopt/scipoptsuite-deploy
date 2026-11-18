# Enable exit on error - script will stop if any command fails
set -e

rm -rf /usr/local/include/boost/*

brew install boost
export MACOSX_DEPLOYMENT_TARGET=14.0
brew reinstall gcc
export FC=/opt/homebrew/bin/gfortran
export DYLD_LIBRARY_PATH=$GITHUB_WORKSPACE/scip_install/lib
which gfortran || echo "gfortran not found"
gfortran --version || echo "gfortran command not working"

# wget https://archives.boost.io/release/1.82.0/source/boost_1_82_0.tar.bz2
# tar --bzip2 -xf $GITHUB_WORKSPACE/boost_1_82_0.tar.bz2
# mv $GITHUB_WORKSPACE/boost_1_82_0/boost /usr/local/include/boost

mkdir scip_install
mkdir scip_install/share
echo "enable_shared=no
enable_java=no
enable_sipopt=no
with_pic=yes
with_metis_cflags=\"-I${GITHUB_WORKSPACE}/scip_install/include\"
with_metis_lflags=\"-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis -lGKlib\"" > scip_install/share/config.site

rm -f /usr/local/lib/libgmp*

# dependencies: restored from the cache, or built and saved for the next run
if [ -f $GITHUB_WORKSPACE/deps.tar ]; then
    tar -xPf $GITHUB_WORKSPACE/deps.tar
else
    bash -x $GITHUB_WORKSPACE/.github/workflows/scripts/deps/macos_arm.bash
    tar -cPf $GITHUB_WORKSPACE/deps.tar $GITHUB_WORKSPACE/scip_install
fi
if [ "$DEPS_ONLY" = "true" ]; then
    exit 0
fi

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/v$SOPLEX_VERSION_FULL.zip
unzip v$SOPLEX_VERSION_FULL.zip
cd soplex-$SOPLEX_VERSION_FULL
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=Release -DGMP=false -DPAPILO=false -DMPFR=false -DBOOST=false -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j2
if [ "$TESTS" = "ON" ]; then
    # examples rebuild libscip, so they run one at a time
    ctest -j$(sysctl -n hw.ncpu) --output-on-failure -E "^examples-"
    ctest --output-on-failure -R "^examples-"
fi
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION_FULL.zip
unzip v$SCIP_VERSION_FULL.zip
cd scip-$SCIP_VERSION_FULL
mkdir build
cd build
cmake .. --preset interface -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DSHARED=$SHARED -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=../../scip_install -DPAPILO=false -DZIMPL=false -DGMP=false -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=../../scip_install -DBOOST=false -DTPI=tny -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j2
if [ "$TESTS" = "ON" ]; then
    # examples rebuild libscip, so they run one at a time
    ctest -j$(sysctl -n hw.ncpu) --output-on-failure -E "^examples-"
    ctest --output-on-failure -R "^examples-"
fi
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/gcg/archive/refs/tags/v$GCG_VERSION_FULL.zip
unzip v$GCG_VERSION_FULL.zip
cd gcg-$GCG_VERSION_FULL
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=false -DSYM=none -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j2
if [ "$TESTS" = "ON" ]; then
    # examples rebuild libscip, so they run one at a time
    ctest -j$(sysctl -n hw.ncpu) --output-on-failure -E "^examples-"
    ctest --output-on-failure -R "^examples-"
fi
make install

bash -x $GITHUB_WORKSPACE/.github/workflows/scripts/relocatable_bin.bash
cd $GITHUB_WORKSPACE
zip -r $GITHUB_WORKSPACE/libscip-macos-arm.zip scip_install/lib scip_install/include scip_install/bin
