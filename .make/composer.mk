# composer: PHP dependencies, Composer run in Docker (no PHP needed on the machine).

COMPOSER_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

# Packages given to composer@update: make composer@update PACKAGES=david-grosskost/suitecrm-devkit
PACKAGES ?=
export PACKAGES

.PHONY: composer@install composer@update

composer@install:
	@$(COMPOSER_SCRIPTS)/composer/install.sh

composer@update:
	@$(COMPOSER_SCRIPTS)/composer/update.sh
