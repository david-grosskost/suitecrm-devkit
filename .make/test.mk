# test: automated tests, run in Docker.

TEST_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

# test@unit: PHPUnit (phpunit.xml.dist). test@smoke, test@regression: a running instance.
.PHONY: test@regression test@smoke test@unit

test@regression:
	@$(TEST_SCRIPTS)/test/regression.sh

test@smoke:
	@$(TEST_SCRIPTS)/test/smoke.sh

test@unit:
	@$(TEST_SCRIPTS)/test/unit.sh
