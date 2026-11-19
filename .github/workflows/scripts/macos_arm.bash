# Enable exit on error - script will stop if any command fails
set -e

brew install boost
export MACOSX_DEPLOYMENT_TARGET=14.0
brew reinstall gcc
export FC=/opt/homebrew/bin/gfortran
export DYLD_LIBRARY_PATH=$GITHUB_WORKSPACE/scip_install/lib

mkdir scip_install
mkdir scip_install/share
echo "enable_shared=no
enable_java=no
enable_sipopt=no
with_pic=yes
with_metis_cflags=\"-I${GITHUB_WORKSPACE}/scip_install/include\"
with_metis_lflags=\"-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis -lGKlib\"" > scip_install/share/config.site

rm -f /usr/local/lib/libgmp*

# deps.tar is restored and saved by the workflow; without it, build the dependencies
if [ -f $GITHUB_WORKSPACE/deps.tar ]; then
    tar -xPf $GITHUB_WORKSPACE/deps.tar
else
    bash -x $GITHUB_WORKSPACE/.github/workflows/scripts/deps/macos_arm.bash
    tar -cPf $GITHUB_WORKSPACE/deps.tar $GITHUB_WORKSPACE/scip_install
fi

JOBS=$(sysctl -n hw.ncpu)
SOPLEX_FLAGS=(-DMPFR=false -DBOOST=false)
SCIP_FLAGS=(-DBOOST=false)
GCG_FLAGS=()
source $GITHUB_WORKSPACE/.github/workflows/scripts/build_suite.bash
