##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

.PHONE: new-install
new-install: ## Installs the latest workspace.new locally
	mix archive.uninstall --force workspace_new
	cd workspace_new && MIX_ENV=prod mix do archive.build, archive.install --force

##@ Utilities

.PHONY: todos
todos: ## Find TODOs in the codebase
	@rg TODO

.PHONY: cloc
cloc: ## Code stats
	cloc --exclude-dir artifacts,fixtures -v=2 .

##@ Linting

.PHONE: spell
spell: ## Run cspell on project
	@echo "=> spell-checking lib folders"
	@-cspell lint **/lib/**/*.ex **/lib/*.ex
	@echo "=> spell-checking test folders"
	@-cspell lint "**/test/**/*.exs" "**/test/**/*.ex"
	@echo "=> spell-checking docs"
	@-cspell lint **/*.md *.md

.PHONE: format
format: ## Format the workspace
	mix workspace.run -t format

.PHONY: lint
lint: ## Run linters suite on project
	mix workspace.check
	mix workspace.run -t format -- --check-formatted
	mix credo
	mix workspace.run -t doctor --allow-failure workspace_new -- --failed

##@ Documentation

.PHONY: docs
docs: ## Generates docs for the complete workspace
	mix workspace.run -t docs

##@ Testing

.PHONY: test
test: ## Test the complete codebase
	mix workspace.run -t test

.PHONY: coverage
coverage: ## Generates coverage report
	-mix workspace.run -t test -- --cover --trace
	mix workspace.test.coverage || true
	genhtml artifacts/coverage/coverage.lcov -o artifacts/coverage --flat --prefix ${PWD}
	open artifacts/coverage/index.html
