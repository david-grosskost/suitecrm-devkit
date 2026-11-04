# security: known vulnerabilities in the dependencies and in the image, run in Docker.

SECURITY_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: security@deps security@image

security@deps:
	@$(SECURITY_SCRIPTS)/security/deps.sh

security@image:
	@$(SECURITY_SCRIPTS)/security/image.sh
