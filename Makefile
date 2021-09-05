-include .env
export $(shell sed 's/=.*//' .env)

VERSION ?= $(shell date +%y.%-m.%-d)
ORIGIN_URI=https://github.com/roswell/clisp
ORIGIN_REF=master
GITHUB=https://github.com/roswell/clisp_head
TSV_FILE=clisp-bin_uri.tsv

SIGSEGV_VERSION ?= 2.12
FFCALL_VERSION ?= 2.4
RELEASE_DATE ?= $(shell date +%F)

OS ?= $(shell ros roswell-internal-use uname)
CPU ?= $(shell ros roswell-internal-use uname -m)
VARIANT ?=
CLISP_LDFLAGS ?=
DOCKER_REPO ?= docker.pkg.github.com/roswell/sbcl_bin
PACK=clisp-$(VERSION)-$(CPU)-$(OS)$(VARIANT)
LAST_VERSION=`ros web.ros version`

hash:
	git ls-remote --heads $(ORIGIN_URI) $(ORIGIN_REF) |sed -r "s/^([0-9a-fA-F]*).*/\1/" > hash

lasthash:
	curl -sSL -o lasthash $(GITHUB)/releases/download/$(LAST_VERSION)/hash

latest-version: lasthash version
	$(eval VERSION := $(shell cat version))
	$(eval HASH := $(shell cat lasthash))
	@echo "set version $(VERSION):$(HASH)"

upload-hash: hash lasthash
	diff -u hash lasthash || VERSION=$(VERSION) ros web.ros upload-hash

tsv:
	TSV_FILE=$(TSV_FILE) ros web.ros tsv

upload-tsv:
	TSV_FILE=$(TSV_FILE) ros web.ros upload-tsv

version:
	@echo $(LAST_VERSION) > version

show:
	@echo PACK=$(PACK) CC=$(CC)

sigsegv:
	curl -O  https://ftp.gnu.org/gnu/libsigsegv/libsigsegv-$(SIGSEGV_VERSION).tar.gz
	tar xfz libsigsegv-$(SIGSEGV_VERSION).tar.gz
	cd libsigsegv-$(SIGSEGV_VERSION);CC='$(CC)' ./configure --prefix=`pwd`/../sigsegv;make;make check;make install
	rm -rf libsigsegv-$(SIGSEGV_VERSION)

ffcall:
	curl -O https://ftp.gnu.org/gnu/libffcall/libffcall-$(FFCALL_VERSION).tar.gz
	tar xfz libffcall-$(FFCALL_VERSION).tar.gz
	cd libffcall-$(FFCALL_VERSION);CC='$(CC)' ./configure --prefix=`pwd`/../ffcall --disable-shared;make;make check;make install
	rm -rf libffcall-$(FFCALL_VERSION)

clisp: sigsegv ffcall
	git clone --depth 100 $(ORIGIN_URI)

checkout-clisp: clisp
	cd clisp;git checkout `cat ../lasthash`

clisp/version.sh: clisp
	echo VERSION_NUMBER=$(VERSION) > clisp/version.sh
	echo RELEASE_DATE=$(RELEASE_DATE) >> clisp/version.sh
	cd clisp/src; \
		autoconf; \
		autoheader

compile: show
	cd clisp; \
	CC='$(CC)' \
	LDFLAGS="$(CLISP_LDFLAGS)" \
	FORCE_UNSAFE_CONFIGURE=1 \
	./configure \
		--with-libsigsegv-prefix=`pwd`/../sigsegv \
		--with-libffcall-prefix=`pwd`/../ffcall \
		--prefix=`pwd`/../$(PACK)
	cd clisp/src; \
	make; \
	make install

archive: $(PACK)
	tar cjvf $(PACK)-binary.tar.bz2 $(PACK)

upload-archive: show
	VERSION=$(VERSION) TARGET=$(ARCH) SUFFIX=$(SUFFIX) ros web.ros upload-archive

pull-docker:
	docker pull $(DOCKER_REPO)/$(IMAGE);

docker:
	docker run \
		-v `pwd`:/tmp \
		-e VERSION=$(VERSION) \
		-e CPU=$(CPU) \
		-e OS=$(OS) \
		-e SUFFIX=$(SUFFIX) \
		-e CFLAGS=$(CFLAGS) \
		-e LINKFLAGS=$(LINKFLAGS) \
		$(DOCKER_REPO)/$(IMAGE) \
		bash \
		-c "cd /tmp;make $(ACTION)"

clean:
	rm -rf sigsegv ffcall clisp
	rm -f lib*.gz
	rm -rf $(PACK)
	rm -f hash lasthash
	#rm -f clisp*.tar.bz2
