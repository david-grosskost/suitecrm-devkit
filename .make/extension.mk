# extension: SuiteCRM extensions (projects with an extension.json), see the
# architecture decisions, "Format des extensions".

EXTENSION_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: extension@validate

extension@validate:
	@$(EXTENSION_SCRIPTS)/extension/validate.sh
