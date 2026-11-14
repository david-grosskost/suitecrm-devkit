# package: the Module Loader package of a SuiteCRM extension (projects with an
# extension.json), to install it without the image of suitecrm-core:
# Administration → Module Loader, on any SuiteCRM 8.

PACKAGE_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

.PHONY: package@build package@scan

package@build:
	@$(PACKAGE_SCRIPTS)/package/build.sh

# The scanner of SuiteCRM's Module Loader on that package (make package@build first).
package@scan:
	@$(PACKAGE_SCRIPTS)/package/scan.sh
