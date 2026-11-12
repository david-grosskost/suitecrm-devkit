# git: repository tooling.

GIT_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: git@hooks git@gitleaks git@shellcheck git@chmod git@gh git@pr

git@hooks:
	@$(GIT_SCRIPTS)/git/hooks.sh

git@gitleaks:
	@$(GIT_SCRIPTS)/git/gitleaks.sh

git@shellcheck:
	@$(GIT_SCRIPTS)/git/shellcheck.sh

git@chmod:
	@$(GIT_SCRIPTS)/git/chmod.sh

git@gh:
	@$(GIT_SCRIPTS)/git/gh.sh

git@pr:
	@$(GIT_SCRIPTS)/git/pr.sh
