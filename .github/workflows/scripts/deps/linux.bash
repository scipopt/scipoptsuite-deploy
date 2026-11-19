# Enable exit on error - script will stop if any command fails
set -e

cd $GITHUB_WORKSPACE
mkdir /usr/include/boost

# older Boost doesn't compile with GCC 14 in exact builds
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
wget https://github.com/coin-or/Ipopt/archive/refs/tags/releases/$IPOPT_VERSION.zip
unzip $IPOPT_VERSION.zip

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
