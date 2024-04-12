##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN { \
    FS = ":.*##"; \
    printf "\nUsage:\n  make \033[36m<target>\033[0m\n" \
  } \
  /^[a-zA-Z_0-9-]+:.*?##/ { \
    printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2 \
  } \
  /^##@/ { \
    printf "\n\033[1m%s\033[0m\n", substr($$0, 5) \
  } ' $(MAKEFILE_LIST)

##@ Utilities

.PHONY: todos
todos: ## Find TODOs in the codebase
	@rg TODO

.PHONY: new-install
new-install: ## Installs the latest workspace.new locally
	mix archive.uninstall --force workspace_new
	cd workspace_new && MIX_ENV=prod mix do archive.build, archive.install --force

##@ Linting

.PHONY: spell
spell: ## Run cspell on project
	@echo "=> spell-checking lib folders"
	@cspell lint -c assets/cspell/cspell.json --gitignore **/lib/**/*.ex **/lib/*.ex
	@echo "=> spell-checking test folders"
	@cspell lint -c assets/cspell/cspell.json --gitignore "**/test/**/*.exs" "**/test/**/*.ex"
	@echo "=> spell-checking docs"
	@cspell lint -c assets/cspell/cspell.json --gitignore **/*.md *.md

.PHONY: format
format: ## Format the workspace
	mix workspace.run -t format

.PHONY: doctor
doctor: ## Runs doctor on all projects
	mix workspace.run -t doctor --exclude workspace_new -- --failed --config-file $(PWD)/assets/doctor.exs

.PHONY: credo
creod: ## Runs credo on all projects
	mix workspace.run -t credo --exclude workspace_new --exclude cascade -- --config-file $(PWD)/assets/credo.exs --strict

.PHONY: lint
lint: ## Run full linters suite on project
	mix workspace.check
	mix workspace.run -t format -- --check-formatted
	mix workspace.run -t xref -- graph --format cycles --fail-above 0
	mix workspace.run -t credo --exclude workspace_new --exclude cascade -- --config-file $(PWD)/assets/credo.exs --strict

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
