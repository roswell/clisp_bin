SIGSEGV_VERSION ?= 2.12
FFCALL_VERSION ?= 2.4
CLISP_VERSION ?= bin
ARCH ?= $(shell ros roswell-internal-use uname)

show:
	@echo $(CLISP_VERSION)

sigsegv:
	curl -O  https://ftp.gnu.org/gnu/libsigsegv/libsigsegv-$(SIGSEGV_VERSION).tar.gz
	tar xfz libsigsegv-$(SIGSEGV_VERSION).tar.gz
	cd libsigsegv-$(SIGSEGV_VERSION); ./configure --prefix=`pwd`/../sigsegv;make;make check;make install
	rm -rf libsigsegv-$(SIGSEGV_VERSION)

ffcall:
	curl -O https://ftp.gnu.org/gnu/libffcall/libffcall-$(FFCALL_VERSION).tar.gz
	tar xfz libffcall-$(FFCALL_VERSION).tar.gz
	cd libffcall-$(FFCALL_VERSION);./configure --prefix=`pwd`/../ffcall --disable-shared;make;make check;make install
	rm -rf libffcall-$(FFCALL_VERSION)

clisp: sigsegv ffcall
	git clone https://github.com/roswell/clisp

archive: clisp
	cd clisp; \
	./configure \
		--with-libsigsegv-prefix=`pwd`/../sigsegv \
		--with-libffcall-prefix=`pwd`/../ffcall \
		--prefix=`pwd`/../clisp-$(CLISP_VERSION);
	cd clisp/src; \
	make; \
	make install
	tar cjvf clisp-$(CLISP_VERSION)-binary.tar.bz2 clisp-$(CLISP_VERSION)
	rm -rf clisp-$(CLISP_VERSION)

clean:
	rm -rf sigsegv ffcall clisp
	rm -f lib*.gz
	#rm -f clisp*.tar.bz2
