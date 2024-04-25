FROM --platform=linux/amd64 debian:bookworm AS builder

ARG BUILD_NUMBER=42

SHELL ["/bin/bash", "-c"]

ENV PYENV_VERSION_TAG=v2.4.0
ENV PYTHON_VERSION=2.7.18
ENV V8_GIT_VERSION=6.1.298
ENV BUILD_DIR=/data/BUILD
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update -y \
    && apt-get install -y \
        build-essential \
        ca-certificates \
        curl \
        devscripts \
        git \
        libbz2-dev \
        libffi-dev \
        libglib2.0-dev \
        liblzma-dev \
        libncurses5 \
        libncurses5-dev \
        libncursesw5-dev \
        libreadline-dev \
        libsqlite3-dev \
        libssl-dev \
        llvm \
        lsb-release \
        make \
        ninja-build \
        tk-dev \
        wget \
        xz-utils \
        zlib1g-dev \
    && apt-get clean \
    && update-ca-certificates --fresh \
    && rm -rf /var/lib/apt/lists/*

ENV PYENV_ROOT "/opt/pyenv"
ENV PATH "$PYENV_ROOT/shims:$PYENV_ROOT/bin:$BUILD_DIR/depot_tools:$PATH"

RUN git clone --depth 1 --branch $PYENV_VERSION_TAG https://github.com/pyenv/pyenv.git $PYENV_ROOT \
    && sed -i 's|PATH="/|PATH="$PYENV_ROOT/bin/:/|g' /etc/profile \
    && $PYENV_ROOT/bin/pyenv init - | tee -a /etc/profile \
    && echo "export PATH=\"$BUILD_DIR/depot_tools:${PATH}\"" | tee -a /etc/profile

RUN pyenv install $PYTHON_VERSION \
    && pyenv global $PYTHON_VERSION

ENTRYPOINT ["/bin/bash", "-l"]

WORKDIR $BUILD_DIR

COPY ./stub-gclient-spec $BUILD_DIR/.gclient

RUN git clone --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools.git \
    && gclient sync --verbose -r $V8_GIT_VERSION \
    && cd v8 \
    && gn gen out.gn --args="is_debug=true symbol_level=2 blink_symbol_level=1 v8_symbol_level=1 v8_static_library=true is_component_build=false v8_enable_i18n_support=false v8_use_external_startup_data=false" \
    && gn args out.gn --list | tee out.gn/gn_args.txt \
    && ninja -v d8 -C out.gn

COPY ./debian $BUILD_DIR/debian

RUN sed -i -e "s/GIT_VERSION/$V8_GIT_VERSION/g" debian/v8-6.1_static.pc \
    && sed -i -e "s/GIT_VERSION/$V8_GIT_VERSION/g" debian/changelog \
    && sed -i -e "s/DATE/$(env LC_ALL=en_US.utf8 date '+%a, %d %b %Y %H:%M:%S %z')/g" debian/changelog \
    && sed -i -e "s/DISTRO/$(lsb_release -sc | tr -d '\n')/g" debian/changelog \
    && sed -i -e "s/BUILD_NUMBER/$BUILD_NUMBER/g" debian/changelog \
    && debuild -b -us -uc \
    && mkdir ../OUT \
    && mv -v ../*.deb ../OUT/.

# Artifacts image (mandatory part, the resulting image must have a single filesystem layer)
FROM scratch
COPY --from=builder /data/OUT/ /
