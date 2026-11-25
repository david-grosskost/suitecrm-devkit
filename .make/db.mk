# db: dumps of the instance's database, on this machine.
# A project adds its own db@ commands in its .make/db.mk (e.g. db@seed).

DB_DUMP_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

# Label added to the dump name: make db@dump NAME=before-import
# Dump to restore (default: the latest): make db@restore FILE=.tools/dumps/...
NAME ?=
FILE ?=
export NAME FILE

.PHONY: db@dump db@restore

db@dump:
	@$(DB_DUMP_SCRIPTS)/db/dump.sh

db@restore:
	@$(DB_DUMP_SCRIPTS)/db/restore.sh
