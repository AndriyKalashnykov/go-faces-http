.DEFAULT_GOAL := help

APP_NAME       := go-faces-http
CURRENTTAG     := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "dev")

# === Tool Versions (pinned) ===
GOLANGCI_VERSION := 1.64.8
HADOLINT_VERSION := 2.12.0
ACT_VERSION      := 0.2.86
NVM_VERSION      := 0.40.4

# Docker
DOCKER_IMAGE    := andriykalashnykov/$(APP_NAME)
DOCKER_TAG      := latest

# Go build flags
GOFLAGS ?= -mod=mod

# Semver regex for validation
SEMVER_REGEX := ^v[0-9]+\.[0-9]+\.[0-9]+$$

#help: @ List available tasks
help:
	@echo "Usage: make COMMAND"
	@echo "Commands :"
	@grep -E '[a-zA-Z\.\-]+:.*?@ .*$$' $(MAKEFILE_LIST)| tr -d '#' | awk 'BEGIN {FS = ":.*?@ "}; {printf "\033[32m%-20s\033[0m - %s\n", $$1, $$2}'

#deps: @ Check and install required dependencies
deps:
	@command -v go >/dev/null 2>&1 || { echo "ERROR: go is not installed"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is not installed"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "ERROR: git is not installed"; exit 1; }
	@command -v golangci-lint >/dev/null 2>&1 || { echo "Installing golangci-lint v$(GOLANGCI_VERSION)..."; \
		curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | sh -s -- -b $$(go env GOPATH)/bin v$(GOLANGCI_VERSION); \
	}

#deps-hadolint: @ Install hadolint for Dockerfile linting
deps-hadolint:
	@command -v hadolint >/dev/null 2>&1 || { echo "Installing hadolint $(HADOLINT_VERSION)..."; \
		curl -sSfL -o /tmp/hadolint https://github.com/hadolint/hadolint/releases/download/v$(HADOLINT_VERSION)/hadolint-Linux-x86_64 && \
		install -m 755 /tmp/hadolint /usr/local/bin/hadolint && \
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

#lint: @ Run all linters (Go + Dockerfile)
lint: deps deps-hadolint
	@golangci-lint run ./...
	@hadolint docker/Dockerfile

#lint-dockerfile: @ Lint the Dockerfile with hadolint
lint-dockerfile: deps-hadolint
	@hadolint docker/Dockerfile

#test: @ Run tests with coverage
test: deps
	@go test --cover -parallel=1 -v -coverprofile=coverage.out -v ./...
	@go tool cover -func=coverage.out | sort -rnk3

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
update:
	@go get -u ./...; go mod tidy

#image-build: @ Build Docker image (self-contained, installs deps in container)
image-build: deps
	@docker buildx build --load -f ./docker/Dockerfile -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

#image-run: @ Run Docker container
image-run: image-build
	@docker run --rm -p 8011:80 $(DOCKER_IMAGE):$(DOCKER_TAG)

#release: @ Create and push a new tag
release:
	@bash -c 'read -p "New tag (current: $(CURRENTTAG)): " newtag && \
		echo "$$newtag" | grep -qE "$(SEMVER_REGEX)" || { echo "Error: Tag must match vN.N.N"; exit 1; } && \
		echo -n "Create and push $$newtag? [y/N] " && read ans && [ "$${ans:-N}" = y ] && \
		echo $$newtag > ./version.txt && \
		git add -A && \
		git commit -a -s -m "Cut $$newtag release" && \
		git tag $$newtag && \
		git push origin $$newtag && \
		git push && \
		echo "Done."'

#ci: @ Run full local CI pipeline (requires CGO and dlib)
ci: deps lint test build
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

.PHONY: help deps deps-hadolint deps-act clean lint lint-dockerfile test build run update \
	image-build image-run release ci ci-run \
	renovate-bootstrap renovate-validate
