# Enable exit on error - script will stop if any command fails
set -e

pacman -S --noconfirm \
  git \
  unzip \
  zip \
  patch \
  m4 \
  cmake \
  ninja \
  make \
  gcc \
  mingw-w64-ucrt-x86_64-git \
  mingw-w64-ucrt-x86_64-cmake \
  mingw-w64-ucrt-x86_64-zlib \
  mingw-w64-ucrt-x86_64-boost \
  mingw-w64-ucrt-x86_64-make \
  mingw-w64-ucrt-x86_64-gcc \
  mingw-w64-ucrt-x86_64-metis \
  mingw-w64-ucrt-x86_64-gcc-fortran
        
cd $GITHUB_WORKSPACE
export GITHUB_WORKSPACE=$(pwd)

mkdir scip_install

cd $GITHUB_WORKSPACE
git clone https://github.com/Reference-LAPACK/lapack.git
cd lapack
mkdir build
cmake -B build -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE
cmake --build build --config Release -j$(nproc)
cmake --install build

cd $GITHUB_WORKSPACE
git clone https://github.com/coin-or/Ipopt.git
cd Ipopt
git checkout releases/3.14.19
./configure --disable-shared --enable-static --prefix=$GITHUB_WORKSPACE/scip_install
make -j$(nproc)
make install

cd $GITHUB_WORKSPACE
if [ "$GMP" = "true" ]; then
    wget https://github.com/pmmp/DependencyMirror/releases/download/mirror/gmp-6.3.0.tar.xz
    tar xvf gmp-6.3.0.tar.xz
    cd gmp-6.3.0
    patch -u configure -i ../.github/workflows/configure.patch
    ./configure --with-pic --disable-shared --enable-static --enable-cxx --prefix=$GITHUB_WORKSPACE/scip_install
    make -j$(nproc)
    if [ "$TESTS" = "ON" ]; then
        make check
    fi
    make install
fi

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/v$SOPLEX_VERSION_FULL.zip
unzip v$SOPLEX_VERSION_FULL.zip
cd soplex-$SOPLEX_VERSION_FULL
mkdir soplex_build
cmake -B soplex_build -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DBoost=true -DPAPILO=false -DGMP=$GMP -DZLIB=false
cmake --build soplex_build --config Release -j$(nproc)
cmake --install soplex_build


cd $GITHUB_WORKSPACE
mkdir $GITHUB_WORKSPACE/scip_build
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION_FULL.zip
unzip v$SCIP_VERSION_FULL.zip
cd scip-$SCIP_VERSION_FULL
mkdir scip_build
#cmake --preset interface -B scip_build -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DSHARED=false -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=$GITHUB_WORKSPACE/scip_install -DPAPILO=false -DZIMPL=false -DZLIB=false -DREADLINE=false -DGMP=false -DGMP_DIR=$GITHUB_WORKSPACE/scip_install -DBoost=true -DIPOPT=true -DIPOPT_DIR=$GITHUB_WORKSPACE/scip_install -DIPOPT_LIBRARIES=$GITHUB_WORKSPACE/scip_install/bin -DLAPACK=true -DCMAKE_C_FLAGS=" -L/ucrt64/lib -llapack -lblas" -DCMAKE_CXX_FLAGS=" -L/ucrt64/lib -llapack -lblas"
cmake --preset interface -B scip_build -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DSHARED=$SHARED -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=$GITHUB_WORKSPACE/scip_install -DPAPILO=false -DZIMPL=false -DZLIB=false -DREADLINE=false -DGMP=$GMP -DGMP_DIR=$GITHUB_WORKSPACE/scip_install -DBoost=true -DIPOPT=true -DIPOPT_DIR=$GITHUB_WORKSPACE/scip_install -DIPOPT_LIBRARIES=$GITHUB_WORKSPACE/scip_install/bin
cmake --build scip_build --config Release -j$(nproc)
cmake --install scip_build
if [ "$TESTS" = "ON" ]; then
  ctest
fi

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/gcg/archive/refs/tags/v$GCG_VERSION_FULL.zip
unzip v$GCG_VERSION_FULL.zip
cd gcg-$GCG_VERSION_FULL
mkdir gcg_build
cmake -B gcg_build -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=$GMP -DGMP_DIR=$GITHUB_WORKSPACE/scip_install -DSYM=none
cmake --build gcg_build --config Release -j$(nproc)
cmake --install gcg_build
if [ "$TESTS" = "ON" ]; then
  ctest
fi

cd $GITHUB_WORKSPACE

zip -r $GITHUB_WORKSPACE/$FILENAME scip_install/lib scip_install/include scip_install/bin
