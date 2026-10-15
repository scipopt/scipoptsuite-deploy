# Enable exit on error - script will stop if any command fails
set -e


# Visual Studio ignores CMAKE_BUILD_TYPE; the configuration comes from --config.
# Debug builds must still use the normal runtime: the debug runtime DLLs are not redistributable.
# CMP0091 has to be forced NEW because all three projects declare cmake_minimum_required 3.11.
RUNTIME_FLAGS="-DCMAKE_POLICY_DEFAULT_CMP0091=NEW -DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL"

pacman -S --noconfirm unzip git mingw-w64-x86_64-zlib zip mingw-w64-x86_64-boost

export PATH="/c/Program Files/CMake/bin:$PATH"

# cmake can't auto-detect VS from the MSYS2 shell and the installed VS version
# drifts (2022 vs 2026). Query vswhere and pass the exact generator + instance.
VSWHERE="/c/Program Files (x86)/Microsoft Visual Studio/Installer/vswhere.exe"
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

EXACT_FLAGS=""
SCIP_EXACT_FLAGS=""
if [ "$BUILD_CONFIG" = "exact" ]; then
    # Same approach as ZIB's official Windows build: GMP and MPFR built with Visual Studio,
    # here via vcpkg, which is preinstalled on GitHub's Windows runners.
    VCPKG="$(cygpath -u "$VCPKG_INSTALLATION_ROOT")"
    "$VCPKG/vcpkg.exe" install gmp mpfr boost-multiprecision --triplet x64-windows
    DEPS="$(cygpath -m "$VCPKG/installed/x64-windows")"
    export GMP_DIR="$DEPS"
    export MPFR_DIR="$DEPS"
    EXACT_FLAGS="-DGMP=true -DMPFR=true -DBOOST=true -DBoost=true -DBOOST_ROOT=$DEPS"
    SCIP_EXACT_FLAGS="-DEXACTSOLVE=on -DLPSEXACT=spx"

    # ship the DLLs, import libraries and headers alongside SCIP, as on Linux/macOS
    mkdir -p scip_install/bin scip_install/lib scip_install/include
    cp "$VCPKG"/installed/x64-windows/bin/{gmp,mpfr}*.dll scip_install/bin/
    cp "$VCPKG"/installed/x64-windows/lib/{gmp,mpfr}*.lib scip_install/lib/
    cp "$VCPKG"/installed/x64-windows/include/{gmp,mpfr}*.h scip_install/include/
fi

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/soplex/archive/refs/tags/v$SOPLEX_VERSION_FULL.zip
unzip v$SOPLEX_VERSION_FULL.zip
cd soplex-$SOPLEX_VERSION_FULL
mkdir soplex_build
cmake -G "$VS_GEN" -DCMAKE_GENERATOR_INSTANCE="$VS_INSTANCE" -B soplex_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DBoost=true -DPAPILO=false -DGMP=false -DZLIB=false -DCMAKE_GENERATOR_PLATFORM=x64 -DCMAKE_POLICY_VERSION_MINIMUM=3.5 $RUNTIME_FLAGS $EXACT_FLAGS
cmake --build soplex_build --config $BUILD_MODE
cmake --install soplex_build --config $BUILD_MODE


cd $GITHUB_WORKSPACE
mkdir $GITHUB_WORKSPACE/scip_build
wget https://github.com/scipopt/scip/archive/refs/tags/v$SCIP_VERSION_FULL.zip
unzip v$SCIP_VERSION_FULL.zip
cd scip-$SCIP_VERSION_FULL
mkdir scip_build
cmake -G "$VS_GEN" -DCMAKE_GENERATOR_INSTANCE="$VS_INSTANCE" --preset interface -B scip_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DSHARED=$SHARED -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=../scip_install -DPAPILO=false -DZIMPL=false -DZLIB=false -DREADLINE=false -DGMP=false -DBoost=true -DIPOPT=true -DIPOPT_DIR=../scip_install -DIPOPT_LIBRARIES=../scip_install/bin -DCMAKE_GENERATOR_PLATFORM=x64 -DCMAKE_POLICY_VERSION_MINIMUM=3.5 $RUNTIME_FLAGS $EXACT_FLAGS $SCIP_EXACT_FLAGS
cmake --build scip_build --config $BUILD_MODE
cmake --install scip_build --config $BUILD_MODE

cd $GITHUB_WORKSPACE
wget https://github.com/scipopt/gcg/archive/refs/tags/v$GCG_VERSION_FULL.zip
unzip v$GCG_VERSION_FULL.zip
cd gcg-$GCG_VERSION_FULL
mkdir gcg_build
cmake -G "$VS_GEN" -DCMAKE_GENERATOR_INSTANCE="$VS_INSTANCE" -B gcg_build -DCMAKE_INSTALL_PREFIX=../scip_install -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=false -DSYM=none -DCMAKE_GENERATOR_PLATFORM=x64 -DCMAKE_POLICY_VERSION_MINIMUM=3.5 $RUNTIME_FLAGS
cmake --build gcg_build --config $BUILD_MODE
cmake --install gcg_build --config $BUILD_MODE

cd $GITHUB_WORKSPACE
zip -r $GITHUB_WORKSPACE/libscip-windows${SUFFIX}.zip scip_install/lib scip_install/include scip_install/bin
