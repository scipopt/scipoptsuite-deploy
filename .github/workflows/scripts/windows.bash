pacman -S --noconfirm unzip git mingw-w64-x86_64-cmake cmake mingw-w64-x86_64-zlib zip mingw-w64-x86_64-boost
            
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
cmake -G "Visual Studio 17 2022" -B soplex_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DBoost=true -DPAPILO=false -DGMP=false -DZLIB=false -DCMAKE_GENERATOR_PLATFORM=x64
cmake --build soplex_build --config Release
cmake --install soplex_build


cd $GITHUB_WORKSPACE
mkdir $GITHUB_WORKSPACE/scip_build
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION.zip
unzip v$SCIP_VERSION.zip
cd scip-$SCIP_VERSION
mkdir scip_build
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/bin/Hostx64/x64"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin"
cmake -G "Visual Studio 17 2022" -B scip_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=../scip_install -DPAPILO=false -DZIMPL=false -DZLIB=false -DREADLINE=false -DGMP=false -DBoost=true -DIPOPT=true -DIPOPT_DIR=../scip_install -DIPOPT_LIBRARIES=../scip_install/bin -DCMAKE_GENERATOR_PLATFORM=x64
cmake --build scip_build --config Release
cmake --install scip_build
ctest

cd $GITHUB_WORKSPACE
git clone https://github.com/jurgen-lentz/gcg.git
cd gcg
mkdir gcg_build
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/bin/Hostx64/x64"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin"
cmake -G "Visual Studio 17 2022" -B gcg_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DGMP=false -DSHARED=false -DSYM=none -DZLIB=true -DIPOPT=true -DIPOPT_DIR=../scip_install -DIPOPT_LIBRARIES=../scip_install/bin -DCMAKE_GENERATOR_PLATFORM=x64
cmake --build gcg_build --config Release
cmake --install gcg_build
ctest

cd $GITHUB_WORKSPACE
zip -r $GITHUB_WORKSPACE/libscip-windows.zip scip_install/lib scip_install/include scip_install/bin