// Included in debug builds on macOS Intel (see macos.bash).
// SoPlex and SCIP call isnan etc. without std::, which GCC on macOS rejects.
#include <cmath>
using std::isnan;
using std::isinf;
using std::isfinite;
