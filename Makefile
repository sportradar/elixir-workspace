##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN { \
    FS = ":.*##"; \
    printf "\nUsage:\n  make \033[36m<target>\033[0m\n" \
  } \
  /^[a-zA-Z_0-9-]+:.*?##/ { \
    printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2 \
  } \
  /^##@/ { \
    printf "\n\033[1m%s\033[0m\n", substr($$0, 5) \
  } ' $(MAKEFILE_LIST)

##@ Bootstrapping

.PHONY: setup
setup: ## Gets and compiles all dependencies
	@echo "==> Compiling workspace"
	@mix deps.get
	@mix compile
	@echo "==> Getting projects dependencies"
	@mix workspace.run -t deps.get
	@mix workspace.run -t deps.compile -- --skip-local-deps

##@ Utilities

.PHONY: todos
todos: ## Find TODOs in the codebase
	@rg \
		-g !Makefile \
		-g !assets/credo.exs \
		-g !cascade/templates/template/template.ex \
		-g !workspace_new/template/README.md \
		TODO

.PHONY: new-install
new-install: ## Installs the latest workspace.new locally
	mix archive.uninstall --force workspace_new
	cd workspace_new && MIX_ENV=prod mix do archive.build, archive.install --force

.PHONY: clean
clean: ## Cleans build artifacts
	@echo "==> Removing artifacts"
	rm -rf artifacts/

##@ Testing

.PHONY: test
test: ## Test the complete codebase
	mix workspace.run -t test -- --warnings-as-errors

.PHONY: test-cover
test-cover: ## Test the complete codebase with cover enabled
	mix workspace.run -t test -- --cover --warnings-as-errors

.PHONY: coverage
coverage: ## Generates coverage report
	-mix workspace.run -t test -- --cover --trace
	mix workspace.test.coverage || true
	genhtml artifacts/coverage/coverage.lcov -o artifacts/coverage --flat --prefix "${PWD}"
	open artifacts/coverage/index.html

##@ Documentation

.PHONY: docs
docs: ## Generates docs for the complete workspace
	mix workspace.run -t docs

##@ Linting steps

.PHONY: compile-warnings
compile-warnings: ## Checks that there are no compilation warnings
	mix workspace.run -t compile -- --force --wanrings-as-errors

.PHONY: check
check: export WORKSPACE_DEV := true
check: ## Runs workspace checks
	mix workspace.check

.PHONY: format
format: ## Format the workspace
	mix workspace.run -t format

.PHONY: format-check
format-check: ## Checks elixir workspace projects format
	mix workspace.run -t format -- --check-formatted

.PHONY: doctor
doctor: export WORKSPACE_DEV := true
doctor: ## Runs doctor on all projects
	mix workspace.run -t doctor --allow-failure cascade -- --failed --config-file "$(PWD)/assets/doctor.exs"

.PHONY: credo
credo: export WORKSPACE_DEV := true
credo: ## Runs credo on all projects
	mix workspace.run -t credo -- --config-file "$(PWD)/assets/credo.exs" --strict

.PHONY: xref
xref: ## Ensures that no cycles are present
	mix workspace.run -t xref -- graph --format cycles --fail-above 0

.PHONY: dialyzer
dialyzer: export WORKSPACE_DEV := true
dialyzer: ## Runs dialyzer on all workspace projects
	mix workspace.run -t dialyzer -- --format dialyxir --underspecs --error_handling

.PHONY: spell
spell: ## Run cspell on project
	@echo "=> spell-checking lib folders"
	@cspell lint -c assets/cspell/cspell.json --gitignore **/lib/**/*.ex **/lib/*.ex
	@echo "=> spell-checking test folders"
	@cspell lint -c assets/cspell/cspell.json --gitignore "**/test/**/*.exs" "**/test/**/*.ex"
	@echo "=> spell-checking docs"
	@cspell lint -c assets/cspell/cspell.json --gitignore **/*.md *.md

.PHONY: markdown-lint
markdown-lint: ## Lints `markdown` files
	markdownlint \
		-c assets/markdownlint.yaml \
		-i artifacts/ \
		-i deps/ \
		-i _build/ \
		**/*.md

##@ Linting suites

LINT_CI_DEPS := check compile-warnings format-check xref test-cover

.PHONY: ci
ci: $(LINT_CI_DEPS) ## Run CI linters suite on project
	@mix workspace.test.coverage

LINT_FULL_DEPS := $(LINT_CI_DEPS) dialyzer doctor credo spell markdown-lint

.PHONY: lint
lint: $(LINT_FULL_DEPS) ## Run the full linters suite
