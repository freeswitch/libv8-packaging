#!/usr/bin/env bash

# V8 Library Build Script

### docker run -it -v $(pwd):/usr/src/libv8-packaging/ debian:bookworm bash -c "cd /usr/src/libv8-packaging/ && bash"
### ./build.sh --install-deps --setup-pyenv
### ./build.sh --build-number 42 --output-dir /root/DEB/

### shfmt -w -s -ci -sr -kp -fn build.sh

echo "Preparing environment..."

handle_error()
{
	echo "Error occurred at line $1"

	if [ -n "$BUILD_DIR" ] && [[ $BUILD_DIR == /tmp/* ]]; then
		echo "Cleaning up temporary build directory: $BUILD_DIR"
		rm -rf "$BUILD_DIR"
	fi

	exit 1
}

set -e
set -o pipefail

trap 'handle_error $LINENO' ERR

if [ "$(id -u)" -ne 0 ]; then
	echo "WARNING: This script may require root privileges to install packages and modify system files."
	echo "Consider running with sudo if you encounter permission errors."
	echo ""
fi

usage()
{
	echo "Usage: $0 [--build-number <num>] [--source-dir <dir>] [--pyenv-root <dir>] [--output-dir <dir>] [--install-deps] [--setup-pyenv] [--debug]"
	echo "  --build-number : Build number for package versioning (required for V8 build)"
	echo "  --source-dir   : Source directory containing libv8-packaging (defaults to script directory)"
	echo "  --pyenv-root   : Path for pyenv installation (defaults to /opt/pyenv)"
	echo "  --output-dir   : Output directory for deb packages (defaults to $HOME/DEB)"
	echo "  --install-deps : Install dependencies"
	echo "  --setup-pyenv  : Setup pyenv and install the required Python version"
	echo "  --debug        : Enable verbose debugging output"
	echo "  --help         : Show this help message"
	echo ""
	echo "Note: When --build-number is not specified, the script will only perform the"
	echo "      environment setup steps (install dependencies and/or setup pyenv) if requested."
	exit 1
}

create_temp_build_dir()
{
	BUILD_DIR=$(mktemp -d /tmp/v8-build.XXXXXX)
	if [ $? -ne 0 ]; then
		echo "Failed to create temporary build directory"
		exit 1
	fi

	echo "Created temporary build directory: $BUILD_DIR"
	trap 'rm -rf "$BUILD_DIR"' EXIT
}

install_dependencies()
{
	echo "Installing dependencies..."
	apt-get update
	apt-get -y install \
		build-essential \
		cmake \
		devscripts \
		docbook-xsl \
		libbz2-dev \
		libffi-dev \
		libglib2.0-dev \
		liblzma-dev \
		libncurses5-dev \
		libncursesw5-dev \
		libreadline-dev \
		libsqlite3-dev \
		libssl-dev \
		libtinfo5 \
		llvm \
		lsb-release \
		ninja-build \
		pkg-config \
		tk-dev \
		zlib1g-dev

	echo "Dependencies installed successfully."
}

setup_pyenv()
{
	echo "Setting up pyenv..."
	if [ ! -d "$PYENV_ROOT" ]; then
		git clone --depth 1 --branch "$PYENV_VERSION_TAG" https://github.com/pyenv/pyenv.git "$PYENV_ROOT"
		sed -i 's|PATH="/|PATH="$PYENV_ROOT/bin/:/|g' /etc/profile
		"$PYENV_ROOT/bin/pyenv" init - | tee -a /etc/profile
		if [ -n "$BUILD_DIR" ]; then
			echo "export PATH=\"$BUILD_DIR/depot_tools:\${PATH}\"" | tee -a /etc/profile
		fi
	fi

	echo "Installing Python $PYTHON_VERSION..."
	pyenv install -s $PYTHON_VERSION
	pyenv global $PYTHON_VERSION

	echo "Pyenv setup completed successfully."
}

build_v8()
{
	echo "Starting V8 build process..."

	create_temp_build_dir

	cd "$SOURCE_DIR"

	cp "$SOURCE_DIR/stub-gclient-spec" "$BUILD_DIR/.gclient"
	cp -av "$SOURCE_DIR/debian/" "$BUILD_DIR/"
	cd "$BUILD_DIR"

	echo "Setting up depot_tools and syncing v8..."
	if [ ! -d "$BUILD_DIR/depot_tools" ]; then
		git clone --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools.git "$BUILD_DIR/depot_tools"
	fi

	export PATH="$BUILD_DIR/depot_tools:$PATH"

	echo "Sync to specific v8 version..."
	gclient sync --verbose -r $V8_GIT_VERSION

	echo "Building v8..."
	cd v8
	gn gen out.gn --args="is_debug=true symbol_level=2 blink_symbol_level=1 v8_symbol_level=1 v8_static_library=true is_component_build=false v8_enable_i18n_support=false v8_use_external_startup_data=false"
	gn args out.gn --list | tee out.gn/gn_args.txt
	ninja -v d8 -C out.gn

	echo "Updating debian packaging..."
	cd "$BUILD_DIR"
	sed -i -e "s/GIT_VERSION/$V8_GIT_VERSION/g" "$BUILD_DIR/debian/v8-6.1_static.pc"
	sed -i -e "s/GIT_VERSION/$V8_GIT_VERSION/g" "$BUILD_DIR/debian/changelog"
	sed -i -e "s/DATE/$(env LC_ALL=en_US.utf8 date '+%a, %d %b %Y %H:%M:%S %z')/g" "$BUILD_DIR/debian/changelog"
	sed -i -e "s/DISTRO/$(lsb_release -sc | tr -d '\n')/g" "$BUILD_DIR/debian/changelog"
	sed -i -e "s/BUILD_NUMBER/$BUILD_NUMBER/g" "$BUILD_DIR/debian/changelog"

	echo "Building debian package..."
	debuild -b -us -uc

	echo "Moving output files..."
	mkdir -p "$OUTPUT_DIR"
	mv -v "$BUILD_DIR"/../*.deb "$OUTPUT_DIR"/

	echo "Build completed successfully!"
	echo "Output packages are available in $OUTPUT_DIR"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR"
BUILD_NUMBER=""
PYENV_ROOT="/opt/pyenv"
OUTPUT_DIR="$HOME/DEB"
INSTALL_DEPS=false
SETUP_PYENV=false
DEBUG=false

while [[ $# -gt 0 ]]; do
	case "$1" in
		--source-dir)
			SOURCE_DIR="$2"
			shift 2
			;;
		--build-number)
			BUILD_NUMBER="$2"
			shift 2
			;;
		--pyenv-root)
			PYENV_ROOT="$2"
			shift 2
			;;
		--output-dir)
			OUTPUT_DIR="$2"
			shift 2
			;;
		--install-deps)
			INSTALL_DEPS=true
			shift
			;;
		--setup-pyenv)
			SETUP_PYENV=true
			shift
			;;
		--debug)
			DEBUG=true
			shift
			;;
		--help)
			usage
			;;
		*)
			echo "Unknown option: $1"
			usage
			;;
	esac
done

SOURCE_DIR=$(realpath "$SOURCE_DIR")
echo "Using source directory: $SOURCE_DIR"

if [ "$DEBUG" = true ]; then
	echo "Debug mode enabled - verbose output will be shown"
	set -x
fi

export DEBIAN_FRONTEND=noninteractive

if [ "$INSTALL_DEPS" = true ]; then
	install_dependencies
fi

if ! git config --global --get-all safe.directory | grep -q '\*'; then
	git config --global --add safe.directory '*'
fi

export BUILD_NUMBER="$BUILD_NUMBER"
export CODENAME=$(lsb_release -sc)
export PYENV_VERSION_TAG=v2.4.0
export PYTHON_VERSION=2.7.18
export V8_GIT_VERSION=6.1.298
export PYENV_ROOT="$PYENV_ROOT"
export BUILD_DIR="$BUILD_DIR"
export PATH="$PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH"

if [ "$SETUP_PYENV" = true ]; then
	setup_pyenv
fi

if [ -n "$BUILD_NUMBER" ]; then
	build_v8
else
	if [ "$INSTALL_DEPS" = false ] && [ "$SETUP_PYENV" = false ]; then
		echo "No operations requested. Please specify at least one action."
		echo "Use --install-deps to install dependencies or --setup-pyenv to set up Python environment."
		echo "Add --build-number <num> to build V8 library."
		usage
	else
		echo "Environment setup completed. Skipping V8 build as no build number was specified."
		echo "To build V8, run again with --build-number <num>"
	fi
fi

echo "Script execution completed."
