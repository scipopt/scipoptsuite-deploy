# Enable exit on error - script will stop if any command fails
set -e

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

# what deps/macos_arm.bash installs, for the dependency cache
DEPS_PATHS=($GITHUB_WORKSPACE/scip_install)
SOPLEX_FLAGS=(-DMPFR=false -DBOOST=false)
SCIP_FLAGS=(-DBOOST=false)
source $GITHUB_WORKSPACE/.github/workflows/scripts/build_suite.bash
