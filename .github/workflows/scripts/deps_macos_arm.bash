rm -rf /usr/local/include/boost/*

brew install boost
export MACOSX_DEPLOYMENT_TARGET=14.0
export DEVELOPER_DIR=/Applications/Xcode_15.0.1.app/Contents/Developer
brew reinstall gcc
export FC=/opt/homebrew/bin/gfortran
export DYLD_LIBRARY_PATH=$GITHUB_WORKSPACE/scip_install/lib
which gfortran || echo "gfortran not found"
gfortran --version || echo "gfortran command not working"

# wget https://archives.boost.io/release/1.82.0/source/boost_1_82_0.tar.bz2
# tar --bzip2 -xf $GITHUB_WORKSPACE/boost_1_82_0.tar.bz2
# mv $GITHUB_WORKSPACE/boost_1_82_0/boost /usr/local/include/boost

wget https://github.com/coin-or/Ipopt/archive/refs/tags/releases/$IPOPT_VERSION.zip
unzip $IPOPT_VERSION.zip
mkdir scip_install
mkdir scip_install/share
echo "enable_shared=no
enable_java=no
enable_sipopt=no
with_pic=yes
with_metis_cflags=\"-I${GITHUB_WORKSPACE}/scip_install/include\"
with_metis_lflags=\"-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis\"" > scip_install/share/config.site

rm -f /usr/local/lib/libgmp*
#wget https://github.com/pmmp/DependencyMirror/releases/download/mirror/gmp-6.3.0.tar.xz
#tar xvf gmp-6.3.0.tar.xz
#cd gmp-6.3.0
#./configure --with-pic --disable-shared --enable-cxx --prefix=$GITHUB_WORKSPACE/scip_install
#make install -j

cd $GITHUB_WORKSPACE
mkdir $GITHUB_WORKSPACE/metis
cd $GITHUB_WORKSPACE/metis-5.1.0
make config prefix=$GITHUB_WORKSPACE/scip_install/
make
make install

cd $GITHUB_WORKSPACE
git clone https://github.com/coin-or-tools/ThirdParty-Mumps.git
cd ThirdParty-Mumps
./get.Mumps
./configure --enable-shared=no --enable-static=yes --prefix=$GITHUB_WORKSPACE/scip_install --with-metis-cflags="-I${GITHUB_WORKSPACE}/scip_install/include" --with-metis-lflags="-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis"
make
make install


cd $GITHUB_WORKSPACE
cd Ipopt-releases-$IPOPT_VERSION
mkdir build
cd build
../configure --prefix=$GITHUB_WORKSPACE/scip_install/ --disable-java --enable-shared=no --disable-sipopt --enable-static=yes --with-metis-cflags="-I${GITHUB_WORKSPACE}/scip_install/include" --with-metis-lflags="-L${GITHUB_WORKSPACE}/scip_install/lib -lmetis"
make -j2
make test
make install
