pacman -S --noconfirm p7zip unzip git mingw-w64-x86_64-cmake cmake mingw-w64-x86_64-zlib zip

export CC=C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.38.33130/bin/HostX64/x64/cl.exe
export CXX=C:/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.38.33130/bin/HostX64/x64/cl.exe
cd $GITHUB_WORKSPACE
wget https://github.com/pmmp/DependencyMirror/releases/download/mirror/gmp-6.3.0.tar.xz
tar xvf gmp-6.3.0.tar.xz
cd gmp-6.3.0
./configure --with-pic --disable-shared --enable-cxx --prefix=$GITHUB_WORKSPACE/scip_install
make install -j

cd $GITHUB_WORKSPACE
wget https://github.com/coin-or/Ipopt/releases/download/releases%2F$IPOPT_VERSION/Ipopt-$IPOPT_VERSION-win64-msvs2019-md.zip
unzip Ipopt-$IPOPT_VERSION-win64-msvs2019-md.zip
mv Ipopt-$IPOPT_VERSION-win64-msvs2019-md/ scip_install
mv scip_install/lib/ipopt.dll.lib scip_install/lib/ipopt.lib

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/release-$SOPLEX_VERSION.zip
unzip release-$SOPLEX_VERSION.zip
cd soplex-release-$SOPLEX_VERSION
mkdir soplex_build
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/bin/Hostx64/x64"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin"
cmake -G "Visual Studio 17 2022" -B soplex_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DPAPILO=false -DGMP=false -DZLIB=false -DCMAKE_GENERATOR_PLATFORM=x64
cmake --build soplex_build --config Release
cmake --install soplex_build


cd $GITHUB_WORKSPACE
mkdir $GITHUB_WORKSPACE/scip_build
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION.zip
unzip v$SCIP_VERSION.zip
cd scip-$SCIP_VERSION
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/bin/Hostx64/x64"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin"
cmake -G "Visual Studio 17 2022" -B $GITHUB_WORKSPACE/scip_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSOPLEX_DIR=../scip_install -DPAPILO=false -DZIMPL=false -DZLIB=false -DREADLINE=false -DGMP=false -DIPOPT=true -DIPOPT_DIR=../scip_install -DIPOPT_LIBRARIES=../scip_install/bin -DCMAKE_GENERATOR_PLATFORM=x64
cmake --build $GITHUB_WORKSPACE/scip_build --config Release
cmake --install $GITHUB_WORKSPACE/scip_build
cmake -G "Visual Studio 17 2022" -B $GITHUB_WORKSPACE/scip_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSOPLEX_DIR=../scip_install -DPAPILO=false -DZIMPL=false -DZLIB=false -DREADLINE=false -DGMP=false -DIPOPT=true -DIPOPT_DIR=../scip_install -DIPOPT_LIBRARIES=../scip_install/bin -DCMAKE_GENERATOR_PLATFORM=x64 -DSHARED=false
cmake --build $GITHUB_WORKSPACE/scip_build --config Release
cmake --install $GITHUB_WORKSPACE/scip_build


#cd $GITHUB_WORKSPACE
#wget https://github.com/ds4dm/Bliss/archive/refs/tags/v0.77.zip
#unzip v0.77.zip
#cd Bliss-0.77
#export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools"
#export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/bin/Hostx64/x64"
#export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin"
#mkdir bliss_build
#cmake -G "Visual Studio 17 2022" -B $GITHUB_WORKSPACE/bliss_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DCMAKE_GENERATOR_PLATFORM=x64
#cmake --build $GITHUB_WORKSPACE/bliss_build --config Release
#cmake --install $GITHUB_WORKSPACE/bliss_build

cd $GITHUB_WORKSPACE
wget -O gcg.zip https://github.com/scipopt/gcg/archive/v36-bugfix.zip
unzip gcg.zip
cd gcg-36-bugfix
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/bin/Hostx64/x64"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin"
mkdir gcg_build
cmake -G "Visual Studio 17 2022" -B $GITHUB_WORKSPACE/gcg_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DBLISS=false -DGMP=false -DCMAKE_GENERATOR_PLATFORM=x64
cmake --build $GITHUB_WORKSPACE/gcg_build --config Release
cmake --install $GITHUB_WORKSPACE/gcg_build
cmake -G "Visual Studio 17 2022" -B $GITHUB_WORKSPACE/gcg_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DBLISS=false -DGMP=false -DCMAKE_GENERATOR_PLATFORM=x64 -DSHARED=false
cmake --build $GITHUB_WORKSPACE/gcg_build --config Release
cmake --install $GITHUB_WORKSPACE/gcg_build


cd $GITHUB_WORKSPACE
zip -r $GITHUB_WORKSPACE/libscip-windows.zip scip_install/lib scip_install/include scip_install/bin
