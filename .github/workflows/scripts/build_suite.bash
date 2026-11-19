# Builds SoPlex, SCIP and GCG into scip_install and zips it, on Linux and macOS.
# Sourced at the end of the platform scripts, which set JOBS and the extra
# cmake flags for each one: SOPLEX_FLAGS, SCIP_FLAGS and GCG_FLAGS (arrays).

PREFIX=$GITHUB_WORKSPACE/scip_install

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

build soplex $SOPLEX_VERSION_FULL -DCMAKE_BUILD_TYPE=Release -DGMP=false -DPAPILO=false "${SOPLEX_FLAGS[@]}"
build scip $SCIP_VERSION_FULL --preset interface -DCMAKE_BUILD_TYPE=$BUILD_MODE -DSHARED=$SHARED \
    -DLPS=spx -DSYM=snauty -DSOPLEX_DIR=$PREFIX -DIPOPT=true -DIPOPT_DIR=$PREFIX -DTPI=tny \
    -DPAPILO=false -DZIMPL=false -DGMP=false -DREADLINE=false "${SCIP_FLAGS[@]}"
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
