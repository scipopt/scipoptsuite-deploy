cd /
yum install gcc gcc-c++ libgfortran git patch wget lapack-static unzip zip make glibc-static -y
rm -f /usr/lib64/liblapack.s*
rm -f /usr/lib64/libblas.*
git clone https://github.com/Reference-LAPACK/lapack.git
cd lapack
mkdir build
cd build
cmake ..
make -j
mv lib/libblas.a /usr/lib64/.
cd ..
cd ..
mkdir scip_install
wget https://github.com/coin-or/Ipopt/archive/refs/tags/releases/3.14.12.zip
unzip 3.14.12.zip
mkdir scip_install
mkdir scip_install/share
echo 'enable_shared=no
enable_java=no
enable_sipopt=no
with_pic=yes
with_metis_cflags="-I/metis/include/"
with_metis_lflags="-L/metis/lib -lmetis -lm"
with_lapack_lflags="-llapack_pic -lblas -lgfortran -lquadmath -lm"
LT_LDFLAGS=-all-static
LDFLAGS=-static' > /scip_install/share/config.site
wget https://github.com/pmmp/DependencyMirror/releases/download/mirror/gmp-6.3.0.tar.xz
tar xvf gmp-6.3.0.tar.xz
cd gmp-6.3.0
./configure --with-pic --disable-shared --enable-cxx --prefix=/scip_install
make install -j
cd ..
rm scip_install/lib/*.so*
wget https://github.com/KarypisLab/METIS/archive/refs/tags/v5.1.1-DistDGL-v0.5.tar.gz
tar -xvf v5.1.1-DistDGL-v0.5.tar.gz
wget https://github.com/KarypisLab/GKlib/archive/refs/tags/METIS-v5.1.1-DistDGL-0.5.tar.gz
tar -xvf METIS-v5.1.1-DistDGL-0.5.tar.gz
mkdir /metis
cd GKlib-METIS-v5.1.1-DistDGL-0.5
make config prefix=/GKlib-METIS-v5.1.1-DistDGL-0.5
make
make install
cd ..
cd METIS-5.1.1-DistDGL-v0.5
make config prefix=/metis/ gklib_path=/GKlib-METIS-v5.1.1-DistDGL-0.5
make
make install
cd ..
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git
cd ThirdParty-Mumps
./get.Mumps
./configure --enable-shared=no --enable-static=yes --prefix=/scip_install
make -j
make install
cd ..
cd Ipopt-releases-3.14.12
mkdir build
cd build
../configure --prefix=/scip_install/
make -j$(nproc)
make test V=1 || :
make install
cd ..
cd ..
wget https://github.com/scipopt/soplex/archive/refs/tags/release-700.zip
unzip release-700.zip
cd soplex-release-700
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=../../scip_install -DCMAKE_BUILD_TYPE=Release -DGMP=true -DPAPILO=false -DGMP_DIR=../../scip_install -DWITH_SHARED_LIBS=off
make -j$(nproc)
make test
make install
cd ../..
wget https://github.com/scipopt/scip/archive/refs/tags/v900.zip
unzip v900.zip
cd scip-900
mkdir build
cd build
cmake .. -DCMAKE_INSTALL_PREFIX=../../scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSOPLEX_DIR=../../scip_install -DPAPILO=false -DZIMPL=false -DGMP=true -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=../../scip_install -DGMP_DIR=../../scip_install
make -j$(nproc) VERBOSE=true
make install
cmake .. -DCMAKE_INSTALL_PREFIX=../../scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSOPLEX_DIR=../../scip_install -DPAPILO=false -DZIMPL=false -DGMP=true -DREADLINE=false -DIPOPT=true -DIPOPT_DIR=../../scip_install -DGMP_DIR=../../scip_install -DSHARED=false
make -j$(nproc) VERBOSE=true
make install
cd ../..
mkdir scip_install/lib
mv scip_install/lib64/* scip_install/lib/.
zip -r $GITHUB_WORKSPACE/libscip-linux.zip scip_install/lib scip_install/include scip_install/bin