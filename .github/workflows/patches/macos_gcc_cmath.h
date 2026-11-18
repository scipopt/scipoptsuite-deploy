// Force-included into the C++ files of SoPlex and SCIP debug builds on macOS Intel (macos.bash).
// SoPlex and SCIP call isnan/isinf/isfinite unqualified in debug-only checks. <cmath> only
// guarantees them in std::, and GCC's libstdc++ on macOS doesn't put them in the global
// namespace too, so those checks don't compile there. Making the std:: versions visible
// works for every SoPlex/SCIP version and keeps ADL for non-std number types.
#include <cmath>
using std::isnan;
using std::isinf;
using std::isfinite;
