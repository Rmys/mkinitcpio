# Makefile for mkinitcpio

VERSION = $(shell if test -f VERSION; then cat VERSION; else git describe | sed 's/-/./g'; fi)

DIRS = \
	/usr/bin \
	/usr/share/bash-completion/completions \
	/etc/mkinitcpio.d \
	/usr/lib/initcpio/hooks \
	/usr/lib/initcpio/install \
	/usr/lib/initcpio/udev \
	/usr/share/man/man8 \
	/usr/share/man/man5 \
	/usr/share/man/man1

all: doc

MANPAGES = \
	mkinitcpio.8 \
	mkinitcpio.conf.5 \
	lsinitcpio.1

install: all
	mkdir -p $(DESTDIR)
	$(foreach dir,$(DIRS),install -dm755 $(DESTDIR)$(dir);)

	sed -e 's|^_f_config=.*|_f_config=/etc/mkinitcpio.conf|' \
	    -e 's|^_f_functions=.*|_f_functions=/usr/lib/initcpio/functions|' \
	    -e 's|^_d_hooks=.*|_d_hooks=({/usr,}/lib/initcpio/hooks)|' \
	    -e 's|^_d_install=.*|_d_install=({/usr,}/lib/initcpio/install)|' \
	    -e 's|^_d_presets=.*|_d_presets=/etc/mkinitcpio.d|' \
	    -e 's|%VERSION%|$(VERSION)|g' \
	    < mkinitcpio > $(DESTDIR)/usr/bin/mkinitcpio

	sed -e 's|\(^_f_functions\)=.*|\1=/usr/lib/initcpio/functions|' \
	    -e 's|%VERSION%|$(VERSION)|g' \
	    < lsinitcpio > $(DESTDIR)/usr/bin/lsinitcpio

	chmod 755 $(DESTDIR)/usr/bin/lsinitcpio $(DESTDIR)/usr/bin/mkinitcpio

	install -m644 mkinitcpio.conf $(DESTDIR)/etc/mkinitcpio.conf
	install -m755 -t $(DESTDIR)/usr/lib/initcpio init shutdown
	install -m644 -t $(DESTDIR)/usr/lib/initcpio init_functions functions
	install -m644 01-memdisk.rules $(DESTDIR)/usr/lib/initcpio/udev/01-memdisk.rules

	cp -at $(DESTDIR)/usr/lib/initcpio/hooks hooks/*
	cp -at $(DESTDIR)/usr/lib/initcpio/install install/*
	cp -at $(DESTDIR)/etc/mkinitcpio.d mkinitcpio.d/*

	install -m644 mkinitcpio.8 $(DESTDIR)/usr/share/man/man8/mkinitcpio.8
	install -m644 mkinitcpio.conf.5 $(DESTDIR)/usr/share/man/man5/mkinitcpio.conf.5
	install -m644 lsinitcpio.1 $(DESTDIR)/usr/share/man/man1/lsinitcpio.1
	install -m644 bash-completion $(DESTDIR)/usr/share/bash-completion/completions/mkinitcpio
	ln -s mkinitcpio $(DESTDIR)/usr/share/bash-completion/completions/lsinitcpio

doc: $(MANPAGES)
%: %.txt Makefile
	a2x -d manpage \
		-f manpage \
		-a manversion=$(VERSION) \
		-a manmanual="mkinitcpio manual" $<

clean:
	$(RM) -r build mkinitcpio-$(VERSION)
	$(RM) mkinitcpio-${VERSION}.tar.gz $(MANPAGES)

dist: doc
	echo $(VERSION) > VERSION
	git ls-files -z | xargs -0 \
		bsdtar -czf mkinitcpio-$(VERSION).tar.gz -s ,^,mkinitcpio-$(VERSION)/, VERSION $(MANPAGES)
	$(RM) VERSION

version:
	@echo $(VERSION)

.PHONY: clean dist install tarball version
