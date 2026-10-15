# Enable exit on error - script will stop if any command fails
set -e

cd $GITHUB_WORKSPACE
yum install gcc gcc-c++ libgfortran git patch wget lapack-static unzip zip make glibc-static -y
rm -f /usr/lib64/liblapack.s*
rm -f /usr/lib64/libblas.*
rm -rf /usr/include/boost
mkdir /usr/include/boost

# 1.86+: older Boost redefines numeric_limits<__float128>, which GCC 14's libstdc++ already defines
wget https://archives.boost.io/release/1.86.0/source/boost_1_86_0.tar.gz
tar -xvf $GITHUB_WORKSPACE/boost_1_86_0.tar.gz
cd boost_1_86_0
./bootstrap.sh --prefix=/usr/include/boost --with-libraries=program_options,serialization,iostreams,regex
./b2 --prefix=/usr/include/boost -j8 install
cd ..

git clone https://github.com/Reference-LAPACK/lapack.git
cd lapack
mkdir build
cd build
cmake ..
make -j$(nproc)
mv lib/libblas.a /usr/lib64/.

cd $GITHUB_WORKSPACE
mkdir scip_install
mkdir scip_install/share
wget https://github.com/coin-or/Ipopt/archive/refs/tags/releases/$IPOPT_VERSION.zip
unzip $IPOPT_VERSION.zip
echo "enable_shared=no
enable_java=no
enable_sipopt=no
with_pic=yes
with_metis_cflags=\"-I${GITHUB_WORKSPACE}/metis/include/\"
with_metis_lflags=\"-L${GITHUB_WORKSPACE}/metis/lib -lmetis -lGKlib -lm\"
with_lapack_lflags=\"-llapack_pic -lblas -lgfortran -lm\"
LT_LDFLAGS=-all-static
LDFLAGS=-static" > $GITHUB_WORKSPACE/scip_install/share/config.site

cd $GITHUB_WORKSPACE
GKLIB_COMMIT=8bd6bad750b2b0d90800c632cf18e8ee93ad72d7  # GKlib has no 5.2.1 tag
wget https://github.com/KarypisLab/METIS/archive/refs/tags/v5.2.1.tar.gz
tar -xvf v5.2.1.tar.gz
wget https://github.com/KarypisLab/GKlib/archive/$GKLIB_COMMIT.tar.gz
tar -xvf $GKLIB_COMMIT.tar.gz
mkdir $GITHUB_WORKSPACE/metis
cd GKlib-$GKLIB_COMMIT
sed -i 's/^CONFIG_FLAGS =/CONFIG_FLAGS = -DCMAKE_POLICY_VERSION_MINIMUM=3.5/' Makefile
sed -i 's/-march=native//' GKlibSystem.cmake  # portable binaries
make config prefix=$GITHUB_WORKSPACE/metis
make
make install

cd $GITHUB_WORKSPACE
cd METIS-5.2.1
sed -i 's/^CONFIG_FLAGS =/CONFIG_FLAGS = -DCMAKE_POLICY_VERSION_MINIMUM=3.5/' Makefile
sed -i 's/-march=native//' conf/gkbuild.cmake
make config prefix=$GITHUB_WORKSPACE/metis gklib_path=$GITHUB_WORKSPACE/metis
make
make install

cd $GITHUB_WORKSPACE
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git
cd ThirdParty-Mumps
./get.Mumps
./configure --enable-shared=no --enable-static=yes --prefix=$GITHUB_WORKSPACE/scip_install
# serial: MUMPS Fortran module deps race under parallel make
make -j1
make install

cd $GITHUB_WORKSPACE
cd Ipopt-releases-$IPOPT_VERSION
mkdir build
cd build
../configure --prefix=$GITHUB_WORKSPACE/scip_install/
make -j$(nproc)
if [ "$TESTS" = "ON" ]; then
    make test V=1 || :
fi
make install
cd ..
cd ..

EXACT_FLAGS=""
SCIP_EXACT_FLAGS=""
if [ "$BUILD_CONFIG" = "exact" ]; then
    # Shared, not static: the LGPLv3 relinking requirement is met by shipping them as separate libraries.
    # CONFIG_SITE=/dev/null: scip_install/share/config.site forces static builds for every configure under that prefix.
    cd $GITHUB_WORKSPACE
    wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.bz2
    tar -xf gmp-6.3.0.tar.bz2
    cd gmp-6.3.0
    CONFIG_SITE=/dev/null ./configure --prefix=$GITHUB_WORKSPACE/scip_install --enable-shared --disable-static --enable-cxx
    make -j$(nproc)
    make install

    cd $GITHUB_WORKSPACE
    wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.bz2
    tar -xf mpfr-4.2.1.tar.bz2
    cd mpfr-4.2.1
    CONFIG_SITE=/dev/null ./configure --prefix=$GITHUB_WORKSPACE/scip_install --enable-shared --disable-static --with-gmp=$GITHUB_WORKSPACE/scip_install
    make -j$(nproc)
    make install

    export GMP_DIR=$GITHUB_WORKSPACE/scip_install
    export MPFR_DIR=$GITHUB_WORKSPACE/scip_install
    # CMake only accepts Boost's package file here; b2 installed it next to the Boost build above
    BOOST_CMAKE_DIR=$(dirname "$(find /usr/include/boost -name BoostConfig.cmake | head -1)")
    EXACT_FLAGS="-DGMP=true -DMPFR=true -DBOOST=true -DBoost_DIR=$BOOST_CMAKE_DIR"
    SCIP_EXACT_FLAGS="-DEXACTSOLVE=on -DLPSEXACT=spx"
fi

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/v$SOPLEX_VERSION_FULL.zip
unzip v$SOPLEX_VERSION_FULL.zip
cd soplex-$SOPLEX_VERSION_FULL
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=false -DPAPILO=false -DBOOST=true $EXACT_FLAGS
make -j$(nproc)
if [ "$TESTS" = "ON" ]; then
    make test
fi
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION_FULL.zip
unzip v$SCIP_VERSION_FULL.zip
cd scip-$SCIP_VERSION_FULL
mkdir build
cd build
cmake .. --preset interface -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DSHARED=$SHARED -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=$GITHUB_WORKSPACE/scip_install -DPAPILO=false -DZIMPL=false -DGMP=false -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=$GITHUB_WORKSPACE/scip_install -DTPI=tny -DCMAKE_VERBOSE_MAKEFILE=1 -DCMAKE_POLICY_VERSION_MINIMUM=3.5 $EXACT_FLAGS $SCIP_EXACT_FLAGS
make -j$(nproc)
if [ "$TESTS" = "ON" ]; then
    make test
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
    make test
fi
make install

cd $GITHUB_WORKSPACE
mkdir -p scip_install/lib
rm -rf scip_install/lib64/cmake
mv scip_install/lib64/* scip_install/lib/.

# Detect architecture and set appropriate filename
if [[ "$ARM" == "ON" ]]; then
    FILENAME="libscip-linux-arm${SUFFIX}.zip"
else
    FILENAME="libscip-linux${SUFFIX}.zip"
fi

zip -r $GITHUB_WORKSPACE/$FILENAME scip_install/lib scip_install/include scip_install/bin
