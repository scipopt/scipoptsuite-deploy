# Enable exit on error - script will stop if any command fails
set -e

pacman -S --noconfirm unzip git mingw-w64-x86_64-zlib zip mingw-w64-x86_64-boost

export PATH="/c/Program Files/CMake/bin:$PATH"

# cmake can't auto-detect VS from the MSYS2 shell and the installed VS version
# drifts (2022 vs 2026). Query vswhere and pass the exact generator + instance.
VSWHERE="/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
"$VSWHERE" -all -property installationPath || true
cmake --help | grep -i "Visual Studio" || true
VS_INSTANCE=$("$VSWHERE" -latest -property installationPath | tr -d '\r' | tr '\\' '/')
VS_MAJOR=$("$VSWHERE" -latest -property installationVersion | tr -d '\r' | cut -d. -f1)
case "$VS_MAJOR" in
  18) VS_GEN="Visual Studio 18 2026";;
  17) VS_GEN="Visual Studio 17 2022";;
  16) VS_GEN="Visual Studio 16 2019";;
  *)  VS_GEN="Visual Studio $VS_MAJOR";;
esac
echo "Using generator: $VS_GEN  instance: $VS_INSTANCE"

cd $GITHUB_WORKSPACE
wget https://github.com/coin-or/Ipopt/releases/download/releases%2F$IPOPT_VERSION/Ipopt-$IPOPT_VERSION-win64-msvs2022-md.zip
unzip Ipopt-$IPOPT_VERSION-win64-msvs2022-md.zip
mv Ipopt-$IPOPT_VERSION-win64-msvs2022-md/ scip_install
mv scip_install/lib/ipopt.dll.lib scip_install/lib/ipopt.lib

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/v$SOPLEX_VERSION_FULL.zip
unzip v$SOPLEX_VERSION_FULL.zip
cd soplex-$SOPLEX_VERSION_FULL
mkdir soplex_build
cmake -G "$VS_GEN" -DCMAKE_GENERATOR_INSTANCE="$VS_INSTANCE" -B soplex_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=Release -DBoost=true -DPAPILO=false -DGMP=false -DZLIB=false -DCMAKE_GENERATOR_PLATFORM=x64 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build soplex_build --config Release
cmake --install soplex_build


cd $GITHUB_WORKSPACE
mkdir $GITHUB_WORKSPACE/scip_build
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION_FULL.zip
unzip v$SCIP_VERSION_FULL.zip
cd scip-$SCIP_VERSION_FULL
mkdir scip_build
cmake -G "$VS_GEN" -DCMAKE_GENERATOR_INSTANCE="$VS_INSTANCE" --preset interface -B scip_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DSHARED=$SHARED -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=../scip_install -DPAPILO=false -DZIMPL=false -DZLIB=false -DREADLINE=false -DGMP=false -DBoost=true -DIPOPT=true -DIPOPT_DIR=../scip_install -DIPOPT_LIBRARIES=../scip_install/bin -DCMAKE_GENERATOR_PLATFORM=x64 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build scip_build --config Release
cmake --install scip_build
if [ "$TESTS" = "ON" ]; then
  ctest
fi

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/gcg/archive/refs/tags/v$GCG_VERSION_FULL.zip
unzip v$GCG_VERSION_FULL.zip
cd gcg-$GCG_VERSION_FULL
mkdir gcg_build
cmake -G "$VS_GEN" -DCMAKE_GENERATOR_INSTANCE="$VS_INSTANCE" -B gcg_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=false -DSYM=none -DCMAKE_GENERATOR_PLATFORM=x64 -DCMAKE_POLICY_VERSION_MINIMUM=3.5
cmake --build gcg_build --config Release
cmake --install gcg_build
if [ "$TESTS" = "ON" ]; then
  ctest
fi

cd $GITHUB_WORKSPACE
zip -r $GITHUB_WORKSPACE/libscip-windows.zip scip_install/lib scip_install/include scip_install/bin
