# URL for git clone
GIT_URL=https://chromium.googlesource.com/v8/v8.git

# Tag name or commit hash for checkout
GIT_VERSION=6.1.298

# Package name
NAME=libv8fs-6.1

# Package version
VERSION=$(GIT_VERSION)

# List of target distributions
DISTROS=jessie

# Number of threads
NPROCS:=$(shell grep -c ^processor /proc/cpuinfo)

# Build version number
BUILD_VERSION=1

# Build folder
BUILD_DIR=build

# Build date
DATE:=$(shell LC_ALL=en_US.utf8 date '+%a, %d %b %Y %H:%M:%S %z')

# Debian package maintainer
DEBEMAIL="packages@freeswitch.com"
DEBFULLNAME="FreeSWITCH Solutions"

DEBUILD=debuild -us -uc -b

all: _phony

_phony:

${BUILD_DIR}/${NAME}_${VERSION}:
	\
	mkdir ${BUILD_DIR} || true ; \
	cd ${BUILD_DIR} ; \
	mkdir "${NAME}_${VERSION}" ; \
	cd "${NAME}_${VERSION}"	; \
	cp ./../../stub-gclient-spec .gclient ; \
	cp ./../../Makefile.target Makefile ; \
	git clone --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools.git ; \
	export PATH=`pwd`/depot_tools:"${PATH}" ; \
	gclient sync -j ${NPROCS} -r ${VERSION} ; \
	cd .. ; \
	tar --exclude='./debian' --exclude .git --exclude '*.pyc' -cf - ${NAME}_${VERSION} | gzip -n9c > ${NAME}_${VERSION}.orig.tar.gz ; \

distro: ${BUILD_DIR}/${NAME}_${VERSION}

clean-tarball:
	cd ${BUILD_DIR} ; \
	rm -f ${NAME}_${VERSION}.orig.tar.gz

tarball:
	cd ${BUILD_DIR} ; \
	[ -f ${NAME}_${VERSION}.orig.tar.gz ] || tar --exclude='./debian' --exclude .git --exclude '*.pyc' -cf - ${NAME}_${VERSION} | gzip -n9c > ${NAME}_${VERSION}.orig.tar.gz

source-build:
	$(MAKE) _build DEBUILD="debuild -us -uc -S -sa"

source-clean:
	DEB_MAINTAINER_MODE=1 debuild clean

build:
	$(MAKE) _build DEBUILD="debuild -us -uc -b"

_build: distro
	cd "${BUILD_DIR}/${NAME}_${VERSION}" ; \
	for distro in ${DISTROS}; do \
	  NEW_VER="${VERSION}-${BUILD_VERSION}~$$distro"; \
	  rm -Rf debian ; cp -r ../../debian . ; \
	  sed -i -e "s/GIT_VERSION/${GIT_VERSION}/g" debian/v8fs.pc ; \
	  sed -i -e "s/GIT_VERSION/${GIT_VERSION}/g" debian/v8fs_static.pc ; \
	  sed -i -e "s/DISTRO/$$distro/g" debian/changelog ; \
	  sed -i -e "s/BUILD_VERSION/${BUILD_VERSION}/g" debian/changelog ; \
	  sed -i -e "s/GIT_VERSION/${GIT_VERSION}/g" debian/changelog ; \
	  sed -i -e "s/PKG_NAME/${NAME}/g" debian/changelog ; \
	  sed -i -e "s/DEB_EMAIL/${DEBEMAIL}/g" debian/changelog ; \
	  sed -i -e "s/DEB_FULL_NAME/${DEBFULLNAME}/g" debian/changelog ; \
	  sed -i -e "s/DATE/${DATE}/g" debian/changelog ; \
	  sed -i -e "s/DISTRO/$$distro/g" debian/control ; \
	  sed -i -e "s/BUILD_VERSION/${BUILD_VERSION}/g" debian/control ; \
	  sed -i -e "s/GIT_VERSION/${GIT_VERSION}/g" debian/control ; \
	  sed -i -e "s/PKG_NAME/${NAME}/g" debian/control ; \
	  sed -i -e "s/DEB_EMAIL/${DEBEMAIL}/g" debian/control ; \
	  sed -i -e "s/DEB_FULL_NAME/${DEBFULLNAME}/g" debian/control ; \
	  sed -i -e "s/DATE/${DATE}/g" debian/control ; \
	  for file in debian/*.$$distro; do \
	    if [ -f $$file ]; then \
	      rename -f "s/\.$$distro$$//" $$file ; \
	    fi ; \
	  done ; \
	  CUR_NAME=`dpkg-parsechangelog | grep '^Source: ' | awk '{print $$2}'`; \
	  CUR_VER=`dpkg-parsechangelog | grep '^Version: ' | awk '{print $$2}'`; \
	  if dpkg --compare-versions $$NEW_VER gt $$CUR_VER; then \
	    echo "New version. Will update changelog and build source package" ; \
	    dch -v $$NEW_VER --package="${NAME}" -D $$distro --force-distribution \
	        "New version based on ${GIT_VERSION} (${GIT_URL})" ; \
	    DEB_MAINTAINER_MODE=1 debuild clean ; \
	  else \
	    if dpkg --compare-versions $$NEW_VER ne $$CUR_VER; then \
	      echo "ERROR: Cannot rebuild source package, because new version is earlier \
	            than the one specified in changelog ($$NEW_VER < $$CUR_VER)" ; \
	      exit 1; \
	    fi ; \
	    echo "Same version, just rebuild source package" ; \
	  fi ; \
	  ${DEBUILD} ; \
	done

clean:
	@rm -Rf ${BUILD_DIR}
