# test: automated tests, run in Docker.

TEST_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

# test@unit: PHPUnit (phpunit.xml.dist). test@smoke: a running instance.
.PHONY: test@smoke test@unit

test@smoke:
	@$(TEST_SCRIPTS)/test/smoke.sh

test@unit:
	@$(TEST_SCRIPTS)/test/unit.sh
