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

# deps.tar is restored and saved by the workflow; without it, build the dependencies
if [ -f $GITHUB_WORKSPACE/deps.tar ]; then
    tar -xPf $GITHUB_WORKSPACE/deps.tar
else
    bash -x $GITHUB_WORKSPACE/.github/workflows/scripts/deps/linux.bash
    tar -cPf $GITHUB_WORKSPACE/deps.tar /usr/include/boost /usr/lib64/libblas.a $GITHUB_WORKSPACE/metis $GITHUB_WORKSPACE/scip_install
fi

JOBS=$(nproc)
SOPLEX_FLAGS=(-DBOOST=true)
SCIP_FLAGS=(-DCMAKE_VERBOSE_MAKEFILE=1)
GCG_FLAGS=(-DSHARED=$SHARED -DCMAKE_VERBOSE_MAKEFILE=1)
source $GITHUB_WORKSPACE/.github/workflows/scripts/build_suite.bash
