# app: SuiteCRM stack lifecycle.

APP_SCRIPTS := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))/scripts

# Defaults to .env.local, then local. Override: make app@start APP_ENV=demo
APP_ENV ?=

# Service followed by app@logs: make app@logs SERVICE=db
SERVICE ?= app
export APP_ENV SERVICE

.PHONY: app@check app@install app@start app@stop app@restart app@status app@logs app@update app@config

app@check:
	@$(APP_SCRIPTS)/app/check.sh

app@install:
	@$(APP_SCRIPTS)/app/install.sh

app@start:
	@$(APP_SCRIPTS)/app/start.sh

app@stop:
	@$(APP_SCRIPTS)/app/stop.sh

app@restart:
	@$(APP_SCRIPTS)/app/restart.sh

app@status:
	@$(APP_SCRIPTS)/app/status.sh

app@logs:
	@$(APP_SCRIPTS)/app/logs.sh

app@update:
	@$(APP_SCRIPTS)/app/update.sh

app@config:
	@$(APP_SCRIPTS)/app/config.sh