# SCIP, SoPlex and GCG set their executables' install rpath to the absolute install prefix,
# overriding CMAKE_INSTALL_RPATH, so bin/ only finds lib/ on the build machine.
# Point them at ../lib so the zip works wherever it is unpacked.

# Enable exit on error - script will stop if any command fails
set -e

for b in $GITHUB_WORKSPACE/scip_install/bin/*; do
    if [ "$(uname)" = "Darwin" ]; then
        otool -l "$b" | grep -q "path @loader_path/../lib " || install_name_tool -add_rpath @loader_path/../lib "$b"
        codesign --force --sign - "$b"
    else
        patchelf --set-rpath '$ORIGIN/../lib' "$b"
    fi
done
