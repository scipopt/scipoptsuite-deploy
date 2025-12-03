# scipoptsuite-deploy

Contains Github pipelines for:
- Building SCIP Optimization Suite docker images and publishing them to dockerhub.
- Building SCIP Optimization Suite for multiple platforms.

## Supported Platforms

The build workflow produces pre-built SCIP libraries for the following platforms:

| Platform | Architecture | Artifact Name |
|----------|-------------|---------------|
| Linux | x86-64 | `libscip-linux.zip` |
| Linux | ARM64 (aarch64) | `libscip-linux-arm.zip` |
| macOS | x86-64 (Intel) | `libscip-macos-intel.zip` |
| macOS | ARM64 (Apple Silicon) | `libscip-macos-arm.zip` |
| Windows | x86-64 | `libscip-windows.zip` |

## Usage

The release artifacts are used by downstream projects like [PySCIPOpt](https://github.com/scipopt/PySCIPOpt) to build platform-specific wheels. Each release contains pre-built SCIP libraries that can be downloaded and used directly.

### Release Artifacts

Each release includes:
- Pre-compiled SCIP libraries (`lib/`)
- Header files (`include/`)
- Binary executables (`bin/`)

These are packaged as zip files that can be downloaded from the [Releases](https://github.com/scipopt/scipoptsuite-deploy/releases) page.
