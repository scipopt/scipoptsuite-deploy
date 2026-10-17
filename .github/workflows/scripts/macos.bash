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

wget https://archives.boost.io/release/1.82.0/source/boost_1_82_0.tar.bz2
tar --bzip2 -xf $GITHUB_WORKSPACE/boost_1_82_0.tar.bz2
rm -rf /usr/local/include/boost
mv $GITHUB_WORKSPACE/boost_1_82_0/boost /usr/local/include/boost

rm -f /usr/local/lib/libgmp*

cd $GITHUB_WORKSPACE
GKLIB_COMMIT=8bd6bad750b2b0d90800c632cf18e8ee93ad72d7  # GKlib has no 5.2.1 tag
wget https://github.com/KarypisLab/METIS/archive/refs/tags/v5.2.1.tar.gz
tar -xvf v5.2.1.tar.gz
wget https://github.com/KarypisLab/GKlib/archive/$GKLIB_COMMIT.tar.gz
tar -xvf $GKLIB_COMMIT.tar.gz
cd GKlib-$GKLIB_COMMIT
sed -i '' 's/^CONFIG_FLAGS =/CONFIG_FLAGS = -DCMAKE_POLICY_VERSION_MINIMUM=3.5/' Makefile
sed -i '' 's/-march=native//' GKlibSystem.cmake  # portable binaries
make config cc=/usr/local/bin/gcc-13 prefix=$GITHUB_WORKSPACE/scip_install/  # default is Apple clang
make
make install

cd $GITHUB_WORKSPACE/METIS-5.2.1
sed -i '' 's/^CONFIG_FLAGS =/CONFIG_FLAGS = -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_C_COMPILER=\/usr\/local\/bin\/gcc-13 -DCMAKE_CXX_COMPILER=\/usr\/local\/bin\/g++-13/' Makefile
sed -i '' 's/-march=native//' conf/gkbuild.cmake
make config prefix=$GITHUB_WORKSPACE/scip_install/ gklib_path=$GITHUB_WORKSPACE/scip_install/
make
make install


cd $GITHUB_WORKSPACE
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git
cd ThirdParty-Mumps
./get.Mumps
./configure --enable-shared=no --enable-static=yes --prefix=$GITHUB_WORKSPACE/scip_install --with-metis-cflags="-I${GITHUB_WORKSPACE}/scip_install/include" --with-metis-lflags="-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis -lGKlib"
make
make install


cd $GITHUB_WORKSPACE
wget https://github.com/coin-or/Ipopt/archive/refs/tags/releases/$IPOPT_VERSION.zip
unzip $IPOPT_VERSION.zip
cd Ipopt-releases-$IPOPT_VERSION
mkdir build
cd build
../configure --prefix=$GITHUB_WORKSPACE/scip_install/ --disable-java --enable-shared=no --disable-sipopt --enable-static=yes --with-metis-cflags="-I${GITHUB_WORKSPACE}/scip_install/include" --with-metis-lflags="-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis -lGKlib"
make -j$(sysctl -n hw.ncpu)
if [ "$TESTS" = "ON" ]; then
    make test
fi
make install


EXACT_FLAGS=""
SCIP_EXACT_FLAGS=""
if [ "$EXACT" = "ON" ]; then
    # Shared, not static: the LGPLv3 relinking requirement is met by shipping them as separate libraries.
    # CONFIG_SITE=/dev/null: scip_install/share/config.site forces static builds for every configure under that prefix.
    cd $GITHUB_WORKSPACE
    wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.bz2
    tar -xf gmp-6.3.0.tar.bz2
    cd gmp-6.3.0
    CONFIG_SITE=/dev/null ./configure --prefix=$GITHUB_WORKSPACE/scip_install --enable-shared --disable-static --enable-cxx
    make -j$(sysctl -n hw.ncpu)
    make install

    cd $GITHUB_WORKSPACE
    wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.bz2
    tar -xf mpfr-4.2.1.tar.bz2
    cd mpfr-4.2.1
    CONFIG_SITE=/dev/null ./configure --prefix=$GITHUB_WORKSPACE/scip_install --enable-shared --disable-static --with-gmp=$GITHUB_WORKSPACE/scip_install
    make -j$(sysctl -n hw.ncpu)
    make install

    # libtool records absolute install names, which break once consumers move the folder
    # (PySCIPOpt moves it to src/scip). Rewrite to @rpath before SoPlex/SCIP link against them.
    cd $GITHUB_WORKSPACE/scip_install/lib
    for f in $(find . -maxdepth 1 -type f \( -name 'libgmp*.dylib' -o -name 'libmpfr*.dylib' \)); do
        install_name_tool -id "@rpath/$(basename "$(otool -D "$f" | tail -1)")" "$f"
        for dep in $(otool -L "$f" | awk 'NR>1 {print $1}' | grep "^$GITHUB_WORKSPACE/scip_install/lib/" || true); do
            install_name_tool -change "$dep" "@rpath/$(basename "$dep")" "$f"
        done
        codesign --force --sign - "$f"
    done

    export GMP_DIR=$GITHUB_WORKSPACE/scip_install
    export MPFR_DIR=$GITHUB_WORKSPACE/scip_install
    # CMake only accepts Boost's package file, and the Boost headers downloaded above have none.
    # Homebrew's Boost does; its link step may clash with those headers, but the package itself installs.
    brew install boost || true
    BOOST_CMAKE_DIR=$(ls -d "$(brew --prefix boost)"/lib/cmake/Boost-* | head -1)
    EXACT_FLAGS="-DGMP=true -DMPFR=true -DBOOST=true -DBoost_DIR=$BOOST_CMAKE_DIR"
    # libscip finds libgmp/libmpfr next to itself
    SCIP_EXACT_FLAGS="-DEXACTSOLVE=on -DLPSEXACT=spx -DCMAKE_INSTALL_RPATH=@loader_path"
fi

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/v$SOPLEX_VERSION_FULL.zip
unzip v$SOPLEX_VERSION_FULL.zip
cd soplex-$SOPLEX_VERSION_FULL
# SoPlex 8.1.0 calls isnan/isinf unqualified in debug-only checks, which GCC on macOS rejects
SOPLEX_PATCH=$GITHUB_WORKSPACE/.github/workflows/patches/soplex-$SOPLEX_VERSION_FULL-isnan.patch
if [ -f "$SOPLEX_PATCH" ]; then
    patch -p1 < "$SOPLEX_PATCH"
fi
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DCMAKE_C_COMPILER=/usr/local/bin/gcc-13 -DCMAKE_CXX_COMPILER=/usr/local/bin/g++-13 -DGMP=false -DPAPILO=false -DMPFR=false -DBOOST=false -DCMAKE_POLICY_VERSION_MINIMUM=3.5 $EXACT_FLAGS
make -j$(sysctl -n hw.ncpu)
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
cmake .. --preset interface -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DCMAKE_C_COMPILER=/usr/local/bin/gcc-13 -DCMAKE_CXX_COMPILER=/usr/local/bin/g++-13 -DCMAKE_CXX_FLAGS=-DFlt_Rounds=0 -DSHARED=$SHARED -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=../../scip_install -DPAPILO=false -DZIMPL=false -DGMP=false -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=../../scip_install -DBOOST=false -DTPI=tny -DCMAKE_POLICY_VERSION_MINIMUM=3.5 $EXACT_FLAGS $SCIP_EXACT_FLAGS
make -j$(sysctl -n hw.ncpu)
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
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=false -DSYM=none -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(sysctl -n hw.ncpu)
if [ "$TESTS" = "ON" ]; then
    make test
fi
make install

cd ../..
zip -r $GITHUB_WORKSPACE/libscip-macos-intel${SUFFIX}.zip scip_install/lib scip_install/include scip_install/bin
