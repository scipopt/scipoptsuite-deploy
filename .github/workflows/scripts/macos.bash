# Enable exit on error - script will stop if any command fails
set -e

brew install bash
brew upgrade cmake
brew install unzip

export CC=/usr/local/bin/gcc-13
export CXX=/usr/local/bin/g++-13
export FC=/usr/local/bin/gfortran-13
export MACOSX_DEPLOYMENT_TARGET=13.0
export DYLD_LIBRARY_PATH=$GITHUB_WORKSPACE/scip_install/lib

rm -rf /usr/local/include/boost/*

cd $GITHUB_WORKSPACE
mkdir scip_install
mkdir scip_install/share

echo "enable_shared=no
enable_java=no
enable_sipopt=no
with_pic=yes
with_metis_cflags=\"-I${GITHUB_WORKSPACE}/scip_install/include\"
with_metis_lflags=\"-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis -lGKlib\"" > $GITHUB_WORKSPACE/scip_install/share/config.site

rm -f /usr/local/lib/libgmp*

# deps.tar is restored and saved by the workflow; without it, build the dependencies
if [ -f $GITHUB_WORKSPACE/deps.tar ]; then
    tar -xPf $GITHUB_WORKSPACE/deps.tar
else
    bash -x $GITHUB_WORKSPACE/.github/workflows/scripts/deps/macos.bash
    tar -cPf $GITHUB_WORKSPACE/deps.tar /usr/local/include/boost $GITHUB_WORKSPACE/scip_install
fi

JOBS=$(sysctl -n hw.ncpu)
SOPLEX_FLAGS=(-DMPFR=false -DBOOST=false)
SCIP_FLAGS=(-DCMAKE_CXX_FLAGS=-DFlt_Rounds=0 -DBOOST=false)
# GCG uses Apple's clang, the rest GCC 13 (CC/CXX above)
GCG_FLAGS=(-DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++)
source $GITHUB_WORKSPACE/.github/workflows/scripts/build_suite.bash
