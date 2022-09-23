.PHONY: help
help:
	cat ./Makefile

.PHONY: all
all:
	$(MAKE) init
	$(MAKE) brew
	$(MAKE) link

.PHONY: init
init:
	.bin/init.sh

.PHONY: brew
brew:
	.bin/brew.sh

.PHONY: link
link:
	.bin/link.sh

.PHONY: defaults
defaults:
	.bin/defaults.sh