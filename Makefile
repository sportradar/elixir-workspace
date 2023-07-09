##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Linting

.PHONE: format
format: ## Format the workspace
	mix workspace.run -t format

.PHONY: lint
lint: ## Run linters suite on project
	mix workspace.check
	mix workspace.run -t format -- --check-formatted
	mix workspace.run -t credo -- --strict
	mix workspace.run -t doctor -- --failed

##@ Testing

.PHONY: coverage
coverage: ## Generates coverage report
	mix workspace.run -t test -- --cover
	mix workspace.test.coverage || true
	genhtml artifacts/coverage/coverage.lcov -o artifacts/coverage --flat --prefix ${PWD}
	open artifacts/coverage/index.html
