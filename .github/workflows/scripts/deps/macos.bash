# Enable exit on error - script will stop if any command fails
set -e

cd $GITHUB_WORKSPACE
wget https://archives.boost.io/release/1.82.0/source/boost_1_82_0.tar.bz2
tar --bzip2 -xf $GITHUB_WORKSPACE/boost_1_82_0.tar.bz2
rm -rf /usr/local/include/boost
mv $GITHUB_WORKSPACE/boost_1_82_0/boost /usr/local/include/boost

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
