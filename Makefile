.DEFAULT_GOAL := help

APP_NAME       := go-faces-http
CURRENTTAG     := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "dev")

# === Tool Versions (pinned) ===
GOLANGCI_VERSION := 2.11.4
HADOLINT_VERSION := 2.12.0
ACT_VERSION      := 0.2.87
NVM_VERSION      := 0.40.4
GVM_SHA          := dd652539fa4b771840846f8319fad303c7d0a8d2 # v1.0.22

# Docker
DOCKER_IMAGE    := andriykalashnykov/$(APP_NAME)
DOCKER_TAG      := latest

# Go build flags
GOFLAGS ?= -mod=mod

# Parse all unique Go versions from every go.mod in the project
GO_VERSIONS := $(shell find . -name 'go.mod' -exec grep -oP '^go \K[0-9.]+' {} \; | sort -uV)
# Primary Go version from root go.mod
GO_VERSION  := $(shell grep -oP '^go \K[0-9.]+' go.mod)

# Helper: run a command under the correct Go version
# In CI, actions/setup-go provides Go directly — gvm is not needed.
# Locally, gvm sets GOROOT/GOPATH/PATH in a subshell.
HAS_GVM := $(shell [ -s "$$HOME/.gvm/scripts/gvm" ] && echo true || echo false)
define go-exec
$(if $(filter true,$(HAS_GVM)),bash -c '. $$GVM_ROOT/scripts/gvm && gvm use go$(GO_VERSION) >/dev/null && $(1)',bash -c '$(1)')
endef

# Semver regex for validation
SEMVER_REGEX := ^v[0-9]+\.[0-9]+\.[0-9]+$$

#help: @ List available tasks
help:
	@echo "Usage: make COMMAND"
	@echo "Commands :"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-20s\033[0m - %s\n", $$1, $$2}'

#deps: @ Check and install required dependencies
deps:
	@# Install gvm if not present (local development only, CI uses actions/setup-go)
	@if [ -z "$$CI" ] && [ ! -s "$$HOME/.gvm/scripts/gvm" ]; then \
		echo "Installing gvm (Go Version Manager)..."; \
		curl -s -S -L https://raw.githubusercontent.com/moovweb/gvm/$(GVM_SHA)/binscripts/gvm-installer | bash -s $(GVM_SHA); \
		echo ""; \
		echo "gvm installed. Please restart your shell or run:"; \
		echo "  source $$HOME/.gvm/scripts/gvm"; \
		echo "Then re-run 'make deps' to install Go $(GO_VERSION) via gvm."; \
		exit 0; \
	fi
	@if [ "$(HAS_GVM)" = "true" ]; then \
		for v in $(GO_VERSIONS); do \
			bash -c '. $$GVM_ROOT/scripts/gvm && gvm list' 2>/dev/null | grep -q "go$$v" || { \
				echo "Installing Go $$v via gvm..."; \
				bash -c '. $$GVM_ROOT/scripts/gvm && gvm install go'"$$v"' -B'; \
			}; \
		done; \
	else \
		command -v go >/dev/null 2>&1 || { echo "Error: Go required. Install gvm from https://github.com/moovweb/gvm or Go from https://go.dev/dl/"; exit 1; }; \
	fi
	@command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is not installed"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "ERROR: git is not installed"; exit 1; }
	@$(call go-exec,command -v golangci-lint) >/dev/null 2>&1 || { echo "Installing golangci-lint v$(GOLANGCI_VERSION)..."; \
		$(call go-exec,go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@v$(GOLANGCI_VERSION)); \
	}

#deps-check: @ Show required tool versions and installation status
deps-check:
	@echo "Go versions required: $(GO_VERSIONS)"
	@echo "Primary Go version:   $(GO_VERSION)"
	@command -v gvm >/dev/null 2>&1 && { \
		bash -c '. $$GVM_ROOT/scripts/gvm && gvm list'; \
	} || echo "gvm not installed — install from https://github.com/moovweb/gvm"
	@printf "  %-16s " "go:"; command -v go >/dev/null 2>&1 && go version || echo "NOT installed"
	@printf "  %-16s " "docker:"; command -v docker >/dev/null 2>&1 && docker --version || echo "NOT installed"
	@printf "  %-16s " "git:"; command -v git >/dev/null 2>&1 && git --version || echo "NOT installed"
	@printf "  %-16s " "golangci-lint:"; command -v golangci-lint >/dev/null 2>&1 && golangci-lint version 2>&1 | head -1 || echo "NOT installed"
	@printf "  %-16s " "hadolint:"; command -v hadolint >/dev/null 2>&1 && hadolint --version || echo "NOT installed"
	@printf "  %-16s " "act:"; command -v act >/dev/null 2>&1 && act --version || echo "NOT installed"

#deps-hadolint: @ Install hadolint for Dockerfile linting
deps-hadolint:
	@command -v hadolint >/dev/null 2>&1 || { echo "Installing hadolint $(HADOLINT_VERSION)..."; \
		curl -sSfL -o /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v$(HADOLINT_VERSION)/hadolint-Linux-x86_64 && \
		sudo install -m 755 /tmp/hadolint /usr/local/bin/hadolint && \
		rm -f /tmp/hadolint; \
	}

#deps-act: @ Install act for local CI
deps-act: deps
	@command -v act >/dev/null 2>&1 || { echo "Installing act $(ACT_VERSION)..."; \
		curl -sSfL https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash -s -- -b /usr/local/bin v$(ACT_VERSION); \
	}

#clean: @ Remove build artifacts
clean:
	@rm -f faces
	@rm -f coverage.out
	@echo "Clean complete."

#format: @ Auto-format Go source files and tidy modules
format: deps
	@$(call go-exec,gofmt -w .)
	@$(call go-exec,go mod tidy)

#lint: @ Run golangci-lint (includes gocritic via .golangci.yml)
lint: deps
	@$(call go-exec,golangci-lint run ./...)

#lint-dockerfile: @ Lint the Dockerfile with hadolint
lint-dockerfile: deps-hadolint
	@hadolint docker/Dockerfile

#test: @ Run tests with coverage and race detection
test: deps
	@$(call go-exec,export GOFLAGS=$(GOFLAGS) && go test -cover -race -parallel=1 -v -coverprofile=coverage.out ./...)
	@$(call go-exec,go tool cover -func=coverage.out | sort -rnk3)

#build: @ Build Go binary (requires CGO and dlib)
build: deps
	@VERSION=$$(git describe --tags 2>/dev/null || echo 'dev'); \
	COMMIT=$$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown'); \
	BUILDTIME=$$(date -u '+%Y-%m-%dT%H:%M:%SZ'); \
	CGO_ENABLED=1 CGO_LDFLAGS="-static -lgfortran -lblas -llapack" go build \
		-tags netgo,osusergo,static \
		-buildvcs=true \
		-ldflags " \
			-X 'main.version=$$VERSION' \
			-X 'github.com/AndriyKalashnykov/go-faces-http/internal/build.Version=$$VERSION' \
			-X 'github.com/AndriyKalashnykov/go-faces-http/internal/build.Commit=$$COMMIT' \
			-X 'github.com/AndriyKalashnykov/go-faces-http/internal/build.BuildTime=$$BUILDTIME' \
			-extldflags '-static'" \
		-o faces faces.go

#run: @ Build and run the application locally
run: build
	@./faces -listen localhost:8011

#update: @ Update dependency packages to latest versions
update: deps
	@$(call go-exec,export GOFLAGS=$(GOFLAGS) && go get -u ./... && go mod tidy)

#image-build: @ Build Docker image (self-contained, installs deps in container)
image-build:
	@docker buildx build --load -f ./docker/Dockerfile -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

#image-run: @ Run Docker container
image-run: image-build
	@docker run --rm -p 8011:80 $(DOCKER_IMAGE):$(DOCKER_TAG)

#image-stop: @ Stop Docker container
image-stop:
	@docker stop $(APP_NAME) || true

#image-push: @ Push Docker image to registry
image-push: image-build
	@docker push $(DOCKER_IMAGE):$(DOCKER_TAG)

#release: @ Create and push a new tag
release:
	@bash -c 'read -p "New tag (current: $(CURRENTTAG)): " newtag && \
		echo "$$newtag" | grep -qE "$(SEMVER_REGEX)" || { echo "Error: Tag must match vN.N.N"; exit 1; } && \
		echo -n "Create and push $$newtag? [y/N] " && read ans && [ "$${ans:-N}" = y ] && \
		echo $$newtag > ./version.txt && \
		git add version.txt && \
		git commit -s -m "Cut $$newtag release" && \
		git tag $$newtag && \
		git push origin $$newtag && \
		git push && \
		echo "Done."'

#ci: @ Run full local CI pipeline (requires CGO and dlib for test and build)
ci: format lint lint-dockerfile test build
	@echo "Local CI pipeline passed."

#ci-run: @ Run GitHub Actions workflow locally using act
ci-run: deps-act
	@act push --container-architecture linux/amd64 \
		--artifact-server-path /tmp/act-artifacts

# Renovate

#renovate-bootstrap: @ Install nvm and npm for Renovate
renovate-bootstrap:
	@command -v node >/dev/null 2>&1 || { \
		echo "Installing nvm $(NVM_VERSION)..."; \
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$(NVM_VERSION)/install.sh | bash; \
		export NVM_DIR="$$HOME/.nvm"; \
		[ -s "$$NVM_DIR/nvm.sh" ] && . "$$NVM_DIR/nvm.sh"; \
		nvm install --lts; \
	}

#renovate-validate: @ Validate Renovate configuration
renovate-validate: renovate-bootstrap
	@npx --yes renovate --platform=local

.PHONY: help deps deps-check deps-hadolint deps-act clean format lint lint-dockerfile test build run update \
	image-build image-run image-stop image-push release ci ci-run \
	renovate-bootstrap renovate-validate
