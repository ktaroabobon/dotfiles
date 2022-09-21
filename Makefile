.PHONY: help
help:
	cat ./Makefile

.PHONY: all
all:
	$(MAKE) init

.PHONY: init
init:
	.bin/init.sh