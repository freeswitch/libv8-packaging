# V8 Library Packaging

This repository contains tools and scripts for building and packaging the V8 JavaScript engine as a static library for different platforms on AMD64 architecture.

## Linux

### Build Script

The `build.sh` script automates the process of building V8 from the source and creating Debian packages.

#### Requirements

- Debian-based system (tested on Debian Bookworm)
- Internet connection for downloading source code
- Root privileges for dependency installation (can use sudo)

#### Script Usage

```bash
./build.sh [--build-number <num>] [--source-dir <dir>] [--pyenv-root <dir>]
           [--output-dir <dir>] [--install-deps] [--setup-pyenv] [--debug]
```

##### Command-Line Options

- `--build-number` : Build number for package versioning (required for V8 build)
- `--source-dir`   : Source directory containing libv8-packaging (defaults to script directory)
- `--pyenv-root`   : Path for pyenv installation (defaults to /opt/pyenv)
- `--output-dir`   : Output directory for deb packages (defaults to $HOME/DEB)
- `--install-deps` : Install dependencies
- `--setup-pyenv`  : Setup pyenv and install the required Python version
- `--debug`        : Enable verbose debugging output
- `--help`         : Show help message

> Note: When --build-number is not specified, the script will only perform the
>       environment setup steps (install dependencies and/or setup pyenv) if requested.

#### Usage Examples

##### Preparing the Build Environment

To set up the required dependencies and Python environment:

```bash
sudo ./build.sh --install-deps --setup-pyenv
```

##### Building V8 with a Specific Version Number

```bash
./build.sh --build-number 42
```

##### Setting Custom Output Directory

```bash
./build.sh --build-number 123 --output-dir /path/to/output
```

##### Complete Build Process

```bash
sudo ./build.sh --install-deps --setup-pyenv --build-number 456 --output-dir /custom/output/dir
```

##### Running in Docker

The script can be executed in a Docker container:

```bash
docker run -it -v $(pwd):/usr/src/libv8-packaging/ debian:bookworm bash -c \
  "cd /usr/src/libv8-packaging/ && bash"
```

Then inside the container:

```bash
./build.sh --install-deps --setup-pyenv
./build.sh --build-number 42 --output-dir /root/DEB/
```

#### Build Output

The script produces Debian packages (.deb files) placed in the specified output
directory or in `$HOME/DEB` by default.

#### Notes

- The script uses Python 2.7.18 for compatibility with V8 build tools
- V8 version 6.1.298 is built by default

## Windows

### Building on Windows

#### Prerequisites

```
You must install the "Debugging Tools for Windows" feature from the Windows 10 SDK.
https://developer.microsoft.com/windows/downloads/windows-10-sdk
```

#### Script Usage

For building V8 on Windows, use the `build.cmd` script:

```
build.cmd
```
