# security: known vulnerabilities in the dependencies and in the image, and a
# passive scan of a running instance, run in Docker.

SECURITY_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: security@deps security@image security@zap

security@deps:
	@$(SECURITY_SCRIPTS)/security/deps.sh

security@image:
	@$(SECURITY_SCRIPTS)/security/image.sh

security@zap:
	@$(SECURITY_SCRIPTS)/security/zap.sh
