wget https://github.com/coin-or/Ipopt/archive/refs/tags/releases/3.14.12.zip
unzip 3.14.12.zip
mkdir scip_install
mkdir scip_install/share
echo 'enable_shared=no
enable_java=no
enable_sipopt=no
with_pic=yes
with_metis_cflags="-I$GITHUB_WORKSPACE/pyscipopt-install/metis/include"
with_metis_lflags="-L$GITHUB_WORKSPACE/pyscipopt-install/metis/lib -lmetis"' > scip_install/share/config.site

wget https://github.com/pmmp/DependencyMirror/releases/download/mirror/gmp-6.3.0.tar.xz
tar xvf gmp-6.3.0.tar.xz
cd gmp-6.3.0
./configure --with-pic --disable-shared --enable-cxx --prefix=$GITHUB_WORKSPACE/pyscipopt-install/scip_install
make install -j
cd ..

wget https://github.com/KarypisLab/METIS/archive/refs/tags/v5.1.1-DistDGL-v0.5.tar.gz
tar -xvf v5.1.1-DistDGL-v0.5.tar.gz
wget https://github.com/KarypisLab/GKlib/archive/refs/tags/METIS-v5.1.1-DistDGL-0.5.tar.gz
tar -xvf METIS-v5.1.1-DistDGL-0.5.tar.gz
mkdir metis
cd GKlib-METIS-v5.1.1-DistDGL-0.5
make config prefix=$GITHUB_WORKSPACE/pyscipopt-install/GKlib-METIS-v5.1.1-DistDGL-0.5
make
make install
sed -i'' -e 's/set(GKlib_COPTIONS "${GKlib_COPTIONS} -Werror -Wall -pedantic -Wno-unused-function -Wno-unused-but-set-variable -Wno-unused-variable -Wno-unknown-pragmas -Wno-unused-label")/set(GKlib_COPTIONS "${GKlib_COPTIONS} -Wall -pedantic -Wno-unused-function -Wno-unused-but-set-variable -Wno-unused-variable -Wno-unknown-pragmas -Wno-unused-label")/g' GKlibSystem.cmake
cd ..
cd METIS-5.1.1-DistDGL-v0.5
make config prefix=$GITHUB_WORKSPACE/pyscipopt-install/metis/ gklib_path=$GITHUB_WORKSPACE/pyscipopt-install/GKlib-METIS-v5.1.1-DistDGL-0.5
make
make install
cd ..

git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git
cd ThirdParty-Mumps
./get.Mumps
./configure --enable-shared=no --enable-static=yes --prefix=$GITHUB_WORKSPACE/pyscipopt-install/scip_install
make
make install
cd ..

cd Ipopt-releases-3.14.12
mkdir build
cd build
../configure --prefix=$GITHUB_WORKSPACE/pyscipopt-install/scip_install/
make -j$(nproc)
make test
make install
cd ../..

wget https://github.com/scipopt/soplex/archive/refs/tags/release-700.zip
unzip release-700.zip
cd soplex-release-700
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=../../scip_install -DCMAKE_BUILD_TYPE=Release -DGMP=true -DPAPILO=false -DBOOST=false -DGMP_DIR=../../scip_install -DWITH_SHARED_LIBS=off
make -j$(nproc)
make test
make install
cd ../..

wget https://github.com/scipopt/scip/archive/refs/tags/v900.zip
unzip v900.zip
cd scip-900
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=../../scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSOPLEX_DIR=../../scip_install -DGMP_DIR=../../scip_install -DPAPILO=false -DZIMPL=false -DGMP=true -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=../../scip_install
make -j$(nproc)
make install
cmake .. -DCMAKE_INSTALL_PREFIX=../../scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSOPLEX_DIR=../../scip_install -DGMP_DIR=../../scip_install -DPAPILO=false -DZIMPL=false -DGMP=true -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=../../scip_install -DSHARED=false
make -j$(nproc)
make install
cd ../..
zip -r $GITHUB_WORKSPACE/libscip-macos-arm.zip scip_install/lib scip_install/include scip_install/bin