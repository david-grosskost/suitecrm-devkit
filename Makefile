# Convention: make <domain>@<action> runs .make/scripts/<domain>/<action>.sh
# Each .make/<domain>.mk only declares targets; the logic lives in the scripts.
#
# Shared by every SuiteCRM project through Composer: a project's own Makefile
# includes vendor/david-grosskost/suitecrm-devkit/Makefile. The project can add
# its own commands in its .make/*.mk, listed with the devkit ones.

# Must be set before any include, otherwise make defaults to the first target.
.DEFAULT_GOAL := .list

# Directory of this Makefile: "." in the devkit itself, the vendor path in a project.
DEVKIT_DIR := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

DEVKIT_MK := $(wildcard $(DEVKIT_DIR)/.make/*.mk)
PROJECT_MK := $(if $(filter .,$(DEVKIT_DIR)),,$(wildcard .make/*.mk))

include $(DEVKIT_MK) $(PROJECT_MK)

# Lists every <domain>@<action> target declared in a .PHONY line.
.PHONY: .list

.list:
	@printf '\n  \033[1;35m%s\033[0m - commandes disponibles\n' "$(notdir $(CURDIR))"
	@grep -h '^\.PHONY:' $(MAKEFILE_LIST) \
		| sed 's/^\.PHONY: *//' | tr ' ' '\n' | grep '@' | sort -u \
		| awk -F'@' '{ \
			if ($$1 != last) { printf "\n  \033[1;33m%s\033[0m\n", $$1; last = $$1 } \
			printf "    \033[36m%s\033[0m\n", $$0 \
		}'
	@printf '\n'
