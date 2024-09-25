pacman -S --noconfirm unzip git mingw-w64-x86_64-cmake cmake mingw-w64-x86_64-zlib zip mingw-w64-x86_64-boost

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/release-$SOPLEX_VERSION.zip
unzip release-$SOPLEX_VERSION.zip
cd soplex-release-$SOPLEX_VERSION
mkdir soplex_build
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/bin/Hostx64/x64"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin"
cmake -G "Visual Studio 17 2022" -B soplex_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Debug -DBoost=true -DPAPILO=false -DGMP=false -DZLIB=false -DCMAKE_GENERATOR_PLATFORM=x64
cmake --build soplex_build --config Debug
cmake --install soplex_build --config Debug


cd $GITHUB_WORKSPACE
mkdir $GITHUB_WORKSPACE/scip_build
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION.zip
unzip v$SCIP_VERSION.zip
cd scip-$SCIP_VERSION
mkdir scip_build
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/bin/Hostx64/x64"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin"
cmake -G "Visual Studio 17 2022" -B scip_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Debug -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=../scip_install -DPAPILO=false -DZIMPL=false -DZLIB=false -DREADLINE=false -DGMP=false -DBoost=true -DIPOPT=false -DTPI=tny -DCMAKE_GENERATOR_PLATFORM=x64
cmake --build scip_build --config Debug
cmake --install scip_build --config Debug
ctest

cd $GITHUB_WORKSPACE
zip -r $GITHUB_WORKSPACE/libscip-windows.zip scip_install/lib scip_install/include scip_install/bin
