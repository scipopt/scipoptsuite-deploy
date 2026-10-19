# Builds GMP and MPFR into scip_install for exact builds on Linux and macOS (Windows uses vcpkg).
# Shared, not static: the LGPLv3 relinking requirement is met by shipping them as separate libraries.
# CONFIG_SITE=/dev/null: scip_install/share/config.site forces static builds for every configure under that prefix.

# Enable exit on error - script will stop if any command fails
set -e

PREFIX=$GITHUB_WORKSPACE/scip_install
JOBS=$(nproc 2>/dev/null || sysctl -n hw.ncpu)

cd $GITHUB_WORKSPACE
wget https://ftp.gnu.org/gnu/gmp/gmp-6.3.0.tar.bz2
tar -xf gmp-6.3.0.tar.bz2
cd gmp-6.3.0
CONFIG_SITE=/dev/null ./configure --prefix=$PREFIX --enable-shared --disable-static --enable-cxx
make -j$JOBS
make install

cd $GITHUB_WORKSPACE
wget https://ftp.gnu.org/gnu/mpfr/mpfr-4.2.1.tar.bz2
tar -xf mpfr-4.2.1.tar.bz2
cd mpfr-4.2.1
CONFIG_SITE=/dev/null ./configure --prefix=$PREFIX --enable-shared --disable-static --with-gmp=$PREFIX
make -j$JOBS
make install

if [ "$(uname)" = "Darwin" ]; then
    # libtool records absolute install names, which break once consumers move the folder
    # (PySCIPOpt moves it to src/scip). Rewrite to @rpath before SoPlex/SCIP link against them.
    cd $PREFIX/lib
    for f in $(find . -maxdepth 1 -type f \( -name 'libgmp*.dylib' -o -name 'libmpfr*.dylib' \)); do
        install_name_tool -id "@rpath/$(basename "$(otool -D "$f" | tail -1)")" "$f"
        for dep in $(otool -L "$f" | awk 'NR>1 {print $1}' | grep "^$PREFIX/lib/" || true); do
            install_name_tool -change "$dep" "@rpath/$(basename "$dep")" "$f"
        done
        codesign --force --sign - "$f"
    done
fi
