# quality: code checks, run in Docker (same tool versions in local and in the CI).

QUALITY_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: quality@lint quality@fix quality@stan quality@baseline

quality@lint:
	@$(QUALITY_SCRIPTS)/quality/lint.sh

quality@fix:
	@$(QUALITY_SCRIPTS)/quality/fix.sh

quality@stan:
	@$(QUALITY_SCRIPTS)/quality/stan.sh

quality@baseline:
	@$(QUALITY_SCRIPTS)/quality/baseline.sh
