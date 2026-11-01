# test: automated tests, run in Docker.

TEST_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: test@smoke

test@smoke:
	@$(TEST_SCRIPTS)/test/smoke.sh
