.PHONY: help
help:
	cat ./Makefile

.PHONY: all
all:
	$(MAKE) all

.PHONY: init
init:
	.bin/init.sh