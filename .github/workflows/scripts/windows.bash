pacman -S --noconfirm unzip git mingw-w64-x86_64-cmake cmake mingw-w64-x86_64-zlib zip
            
cd $GITHUB_WORKSPACE
wget https://github.com/coin-or/Ipopt/releases/download/releases%2F3.14.12/Ipopt-3.14.12-win64-msvs2019-md.zip
unzip Ipopt-3.14.12-win64-msvs2019-md.zip
mv Ipopt-3.14.12-win64-msvs2019-md/ scip_install
mv scip_install/lib/ipopt.dll.lib scip_install/lib/ipopt.lib

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/release-700.zip
unzip release-700.zip
cd soplex-release-700
mkdir soplex_build
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/bin/Hostx64/x64"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin"
cmake -G "Visual Studio 17 2022" -B soplex_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DPAPILO=false -DGMP=false -DZLIB=false -DCMAKE_GENERATOR_PLATFORM=x64
cmake --build soplex_build --config Release
cmake --install soplex_build


cd $GITHUB_WORKSPACE
mkdir $GITHUB_WORKSPACE/scip_build
wget https://github.com/scipopt/scip/archive/refs/tags/v900.zip
unzip v900.zip
cd scip-900
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/Common7/Tools"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/VC/Tools/MSVC/14.37.32822/bin/Hostx64/x64"
export PATH="$PATH:/c/Program Files/Microsoft Visual Studio/2022/Enterprise/MSBuild/Current/Bin"
cmake -G "Visual Studio 17 2022" -B $GITHUB_WORKSPACE/scip_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSOPLEX_DIR=../scip_install -DPAPILO=false -DZIMPL=false -DZLIB=false -DREADLINE=false -DGMP=false -DIPOPT=true -DIPOPT_DIR=../scip_install -DIPOPT_LIBRARIES=../scip_install/bin -DCMAKE_GENERATOR_PLATFORM=x64
cmake --build $GITHUB_WORKSPACE/scip_build --config Release
cmake --install $GITHUB_WORKSPACE/scip_build
cmake -G "Visual Studio 17 2022" -B $GITHUB_WORKSPACE/scip_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DLPS=spx -DSOPLEX_DIR=../scip_install -DPAPILO=false -DZIMPL=false -DZLIB=false -DREADLINE=false -DGMP=false -DIPOPT=true -DIPOPT_DIR=../scip_install -DIPOPT_LIBRARIES=../scip_install/bin -DCMAKE_GENERATOR_PLATFORM=x64 -DSHARED=false
cmake --build $GITHUB_WORKSPACE/scip_build --config Release
cmake --install $GITHUB_WORKSPACE/scip_build

cd $GITHUB_WORKSPACE
zip -r $GITHUB_WORKSPACE/libscip-windows.zip scip_install/lib scip_install/include scip_install/bin