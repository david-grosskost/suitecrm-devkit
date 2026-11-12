# front: the Angular module of a SuiteCRM extension (its app/ sources, built
# into public/), loaded by SuiteCRM 8 at start (module federation).

FRONT_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: front@build front@check

front@build:
	@$(FRONT_SCRIPTS)/front/build.sh

front@check:
	@$(FRONT_SCRIPTS)/front/check.sh
