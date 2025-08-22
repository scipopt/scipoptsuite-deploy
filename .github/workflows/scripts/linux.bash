# Enable exit on error - script will stop if any command fails
set -e

cd $GITHUB_WORKSPACE
yum install gcc gcc-c++ libgfortran git patch wget lapack-static unzip zip make glibc-static -y
rm -f /usr/lib64/liblapack.s*
rm -f /usr/lib64/libblas.*
rm -rf /usr/include/boost
mkdir /usr/include/boost

wget https://archives.boost.io/release/1.82.0/source/boost_1_82_0.tar.gz
tar -xvf $GITHUB_WORKSPACE/boost_1_82_0.tar.gz
cd boost_1_82_0
./bootstrap.sh --prefix=/usr/include/boost --with-libraries=program_options,serialization,iostreams,regex
./b2 --prefix=/usr/include/boost -j8 install
cd ..

git clone https://github.com/Reference-LAPACK/lapack.git
cd lapack
mkdir build
cd build
cmake ..
make -j
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
with_metis_lflags=\"-L${GITHUB_WORKSPACE}/metis/lib -lmetis -lm\"
with_lapack_lflags=\"-llapack_pic -lblas -lgfortran -lm\"
LT_LDFLAGS=-all-static
LDFLAGS=-static" > $GITHUB_WORKSPACE/scip_install/share/config.site

#wget https://github.com/pmmp/DependencyMirror/releases/download/mirror/gmp-6.3.0.tar.xz
#tar xvf gmp-6.3.0.tar.xz
#cd gmp-6.3.0
#./configure --with-pic --disable-shared --enable-cxx --prefix=$GITHUB_WORKSPACE/scip_install
#make install -j

cd $GITHUB_WORKSPACE
wget https://github.com/KarypisLab/METIS/archive/refs/tags/v5.1.1-DistDGL-v0.5.tar.gz
tar -xvf v5.1.1-DistDGL-v0.5.tar.gz
wget https://github.com/KarypisLab/GKlib/archive/refs/tags/METIS-v5.1.1-DistDGL-0.5.tar.gz
tar -xvf METIS-v5.1.1-DistDGL-0.5.tar.gz
mkdir $GITHUB_WORKSPACE/metis
cd GKlib-METIS-v5.1.1-DistDGL-0.5
sed -i 's/^CONFIG_FLAGS =/CONFIG_FLAGS = -DCMAKE_POLICY_VERSION_MINIMUM=3.5/' Makefile
make config prefix=$GITHUB_WORKSPACE/GKlib-METIS-v5.1.1-DistDGL-0.5
make
make install

cd $GITHUB_WORKSPACE
cd METIS-5.1.1-DistDGL-v0.5
sed -i 's/^CONFIG_FLAGS =/CONFIG_FLAGS = -DCMAKE_POLICY_VERSION_MINIMUM=3.5/' Makefile
make config prefix=$GITHUB_WORKSPACE/metis gklib_path=$GITHUB_WORKSPACE/GKlib-METIS-v5.1.1-DistDGL-0.5
make
make install

cd $GITHUB_WORKSPACE
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git
cd ThirdParty-Mumps
./get.Mumps
./configure --enable-shared=no --enable-static=yes --prefix=$GITHUB_WORKSPACE/scip_install
make -j
make install

cd $GITHUB_WORKSPACE
cd Ipopt-releases-$IPOPT_VERSION
mkdir build
cd build
../configure --prefix=$GITHUB_WORKSPACE/scip_install/
make -j$(nproc)
make test V=1 || :
make install
cd ..
cd ..
wget https://github.com/scipopt/soplex/archive/refs/tags/release-$SOPLEX_VERSION.zip
unzip release-$SOPLEX_VERSION.zip
cd soplex-release-$SOPLEX_VERSION
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=Release -DGMP=false -DPAPILO=false -DBOOST=true
make -j$(nproc)
make test
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION.zip
unzip v$SCIP_VERSION.zip
cd scip-$SCIP_VERSION
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DSHARED=$SHARED -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=$GITHUB_WORKSPACE/scip_install -DPAPILO=false -DZIMPL=false -DGMP=false -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=$GITHUB_WORKSPACE/scip_install -DTPI=tny -DCMAKE_VERBOSE_MAKEFILE=1 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(nproc)
make test
make install

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/gcg/archive/refs/tags/v$GCG_VERSION.zip
unzip v$GCG_VERSION.zip
cd gcg-$GCG_VERSION
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=$GITHUB_WORKSPACE/scip_install -DSHARED=$SHARED -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=false -DSYM=none -DCMAKE_VERBOSE_MAKEFILE=1 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j$(nproc)
make test
make install

cd $GITHUB_WORKSPACE
mkdir -p scip_install/lib
rm -rf scip_install/lib64/cmake
mv scip_install/lib64/* scip_install/lib/.
zip -r $GITHUB_WORKSPACE/libscip-linux.zip scip_install/lib scip_install/include scip_install/bin
