# Builds SoPlex, SCIP and GCG into scip_install and zips it, on Linux and macOS.
# Sourced at the end of the platform scripts, which set DEPS_PATHS and the extra
# cmake flags for each one: SOPLEX_FLAGS, SCIP_FLAGS and GCG_FLAGS (arrays).

PREFIX=$GITHUB_WORKSPACE/scip_install
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu)

# deps.tar is restored and saved by the workflow; without it, build the
# dependencies with deps/<platform script> and pack them into it
if [ -f $GITHUB_WORKSPACE/deps.tar ]; then
    tar -xPf $GITHUB_WORKSPACE/deps.tar
else
    bash -x $GITHUB_WORKSPACE/.github/workflows/scripts/deps/$(basename $0)
    tar -cPf $GITHUB_WORKSPACE/deps.tar "${DEPS_PATHS[@]}"
fi

# exact builds: GMP/MPFR, and Boost's CMake config
EXACT_FLAGS=()
if [ "$EXACT" = "ON" ]; then
    bash -x $GITHUB_WORKSPACE/.github/workflows/scripts/build_gmp_mpfr.bash
    export GMP_DIR=$PREFIX
    export MPFR_DIR=$PREFIX
    if [ "$(uname)" = "Darwin" ]; then
        # on Intel, brew's link step clashes with the Boost headers from deps, hence || true
        brew install boost || true
        BOOST_CMAKE_DIR=$(ls -d "$(brew --prefix boost)"/lib/cmake/Boost-* | head -1)
        ORIGIN=@loader_path
    else
        BOOST_CMAKE_DIR=$(dirname "$(find /usr/include/boost -name BoostConfig.cmake | head -1)")
        ORIGIN='$ORIGIN'
    fi
    # the rpath lets lib/ and bin/ find libgmp/libmpfr
    EXACT_FLAGS=(-DGMP=true -DMPFR=true -DBOOST=true -DBoost_DIR=$BOOST_CMAKE_DIR
        "-DCMAKE_INSTALL_RPATH=$ORIGIN;$ORIGIN/../lib" -DEXACTSOLVE=on -DLPSEXACT=spx)
fi

# build NAME VERSION CMAKE_FLAGS...: download, build, test and install
build() {
    local name=$1 version=$2
    shift 2
    cd $GITHUB_WORKSPACE
    wget https://github.com/scipopt/$name/archive/refs/tags/v$version.zip
    unzip v$version.zip
    mkdir $name-$version/build
    cd $name-$version/build
    cmake .. -DCMAKE_INSTALL_PREFIX=$PREFIX -DCMAKE_POLICY_VERSION_MINIMUM=3.5 "$@"
    make -j$JOBS
    if [ "$TESTS" = "ON" ]; then
        # SCIP's examples-* tests relink libscip, so they run after the others, one at a time
        ctest -j$JOBS --output-on-failure -E "^examples-"
        ctest --output-on-failure -R "^examples-"
    fi
    make install
}

build soplex $SOPLEX_VERSION_FULL -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=false -DPAPILO=false "${SOPLEX_FLAGS[@]}" "${EXACT_FLAGS[@]}"
build scip $SCIP_VERSION_FULL --preset interface -DCMAKE_BUILD_TYPE=$BUILD_MODE -DSHARED=$SHARED \
    -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=$PREFIX -DIPOPT=true -DIPOPT_DIR=$PREFIX -DTPI=tny \
    -DPAPILO=false -DZIMPL=false -DGMP=false -DREADLINE=false "${SCIP_FLAGS[@]}" "${EXACT_FLAGS[@]}"
build gcg $GCG_VERSION_FULL -DCMAKE_BUILD_TYPE=$BUILD_MODE -DGMP=false -DSYM=none "${GCG_FLAGS[@]}"

# some libraries go to lib64 on Linux
if [ -d $PREFIX/lib64 ]; then
    rm -rf $PREFIX/lib64/cmake
    mv $PREFIX/lib64/* $PREFIX/lib/
fi

# CMake gives the executables an absolute rpath to the build machine;
# point them at ../lib so they work wherever the zip is unpacked
for b in $PREFIX/bin/*; do
    if [ "$(uname)" = "Darwin" ]; then
        otool -l "$b" | grep -q "path @loader_path/../lib " || install_name_tool -add_rpath @loader_path/../lib "$b"
        codesign --force --sign - "$b"
    else
        patchelf --set-rpath '$ORIGIN/../lib' "$b"
    fi
done

cd $GITHUB_WORKSPACE
zip -r $GITHUB_WORKSPACE/$ZIP scip_install/lib scip_install/include scip_install/bin
