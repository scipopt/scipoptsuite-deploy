rm -rf /usr/local/include/boost
mkdir /usr/local/include/boost
brew install boost
export MACOSX_DEPLOYMENT_TARGET=11.0
export FC=/usr/local/bin/gfortran-13

wget https://boostorg.jfrog.io/artifactory/main/release/1.82.0/source/boost_1_82_0.tar.bz2
tar --bzip2 -xf $GITHUB_WORKSPACE/boost_1_82_0.tar.bz2
mv $GITHUB_WORKSPACE/boost_1_82_0/boost/* /usr/local/include/boost/.

wget https://github.com/coin-or/Ipopt/archive/refs/tags/releases/$IPOPT_VERSION.zip
unzip $IPOPT_VERSION.zip
mkdir scip_install
mkdir scip_install/share
echo "enable_shared=no
enable_java=no
enable_sipopt=no
with_pic=yes
with_metis_cflags=\"-I${GITHUB_WORKSPACE}/metis/include\"
with_metis_lflags=\"-L${GITHUB_WORKSPACE}/metis/lib -lmetis\"" > scip_install/share/config.site

#rm -f /usr/local/lib/libgmp*
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
mkdir metis
cd GKlib-METIS-v5.1.1-DistDGL-0.5
make config prefix=$GITHUB_WORKSPACE/GKlib-METIS-v5.1.1-DistDGL-0.5
make
make install
sed -i'' -e 's/set(GKlib_COPTIONS "${GKlib_COPTIONS} -Werror -Wall -pedantic -Wno-unused-function -Wno-unused-but-set-variable -Wno-unused-variable -Wno-unknown-pragmas -Wno-unused-label")/set(GKlib_COPTIONS "${GKlib_COPTIONS} -Wall -pedantic -Wno-unused-function -Wno-unused-but-set-variable -Wno-unused-variable -Wno-unknown-pragmas -Wno-unused-label")/g' GKlibSystem.cmake
cd $GITHUB_WORKSPACE
cd METIS-5.1.1-DistDGL-v0.5
make config prefix=$GITHUB_WORKSPACE/metis/ gklib_path=$GITHUB_WORKSPACE/GKlib-METIS-v5.1.1-DistDGL-0.5
make
make install
#cd $GITHUB_WORKSPACE
#mkdir $GITHUB_WORKSPACE/metis
#cd $GITHUB_WORKSPACE/metis-5.1.0
#make config shared=0 prefix=$GITHUB_WORKSPACE/metis/
#make
#make install

cd $GITHUB_WORKSPACE
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git
cd ThirdParty-Mumps
./get.Mumps
./configure --enable-shared=no --enable-static=yes --prefix=$GITHUB_WORKSPACE/scip_install
make
make install


cd $GITHUB_WORKSPACE
cd Ipopt-releases-$IPOPT_VERSION
mkdir build
cd build
../configure --prefix=$GITHUB_WORKSPACE/scip_install/
make -j$(nproc)
make test
make install

#cd $GITHUB_WORKSPACE
#wget https://github.com/scipopt/soplex/archive/refs/tags/release-$SOPLEX_VERSION.zip
#unzip release-$SOPLEX_VERSION.zip
#cd soplex-release-$SOPLEX_VERSION
#mkdir build
#cd build
#cmake .. -DCMAKE_INSTALL_PREFIX=../../scip_install -DCMAKE_BUILD_TYPE=Release -DGMP=true -DPAPILO=false -DGMP_DIR=../../scip_install -DMPFR=false -DBOOST=true -DBOOST_INCLUDE_DIR=/usr/local/include/boost/
#make -j$(nproc)
#make test
#make install
#
#cd $GITHUB_WORKSPACE
#wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION.zip
#unzip v$SCIP_VERSION.zip
#cd scip-$SCIP_VERSION
#mkdir build
#cd build
#cmake .. -DCMAKE_INSTALL_PREFIX=../../scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=../../scip_install -DGMP_DIR=../../scip_install -DPAPILO=false -DZIMPL=false -DGMP=true -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=../../scip_install -DBOOST=true -DGMP=true -DGMP_DIR=$GITHUB_WORKSPACE/scip_install
#make -j
#make test
#make install
#
#cd $GITHUB_WORKSPACE
#zip -r $GITHUB_WORKSPACE/libscip-macos-arm.zip scip_install/lib scip_install/include scip_install/bin