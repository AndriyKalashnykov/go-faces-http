projectname ?= go-faces-http

# Tool versions
GOLANGCI_LINT_VERSION := v1.64.8

# Git metadata
CURRENTTAG := $(shell git describe --tags --abbrev=0 2>/dev/null || echo "none")
NEWTAG ?= $(shell bash -c 'read -p "Please provide a new tag (current tag - $(CURRENTTAG)): " newtag; echo $$newtag')

# Docker
DOCKER_IMAGE := andriykalashnykov/$(projectname)
DOCKER_TAG := latest

# Semver regex for validation
SEMVER_REGEX := ^v[0-9]+\.[0-9]+\.[0-9]+$$

.DEFAULT_GOAL := help

.PHONY: help deps test build update release image-build image-run clean lint run ci renovate-bootstrap renovate-validate

help: ## list makefile targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

deps: ## check required dependencies
	@command -v go >/dev/null 2>&1 || { echo "ERROR: go is not installed"; exit 1; }
	@command -v docker >/dev/null 2>&1 || { echo "ERROR: docker is not installed"; exit 1; }
	@command -v git >/dev/null 2>&1 || { echo "ERROR: git is not installed"; exit 1; }
	@echo "All dependencies are available."

test: deps ## run tests
	@go test --cover -parallel=1 -v -coverprofile=coverage.out -v ./...
	@go tool cover -func=coverage.out | sort -rnk3

build: deps ## build golang binary
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

run: build ## run the application locally
	@./faces -listen localhost:8011

update: ## update dependency packages to latest versions
	@go get -u ./...; go mod tidy

lint: deps ## run linter
	@command -v golangci-lint >/dev/null 2>&1 || { echo "ERROR: golangci-lint is not installed ($(GOLANGCI_LINT_VERSION))"; exit 1; }
	@golangci-lint run ./...

release: ## create and push a new tag
	$(eval NT=$(NEWTAG))
	@if ! echo "$(NT)" | grep -qE '$(SEMVER_REGEX)'; then \
		echo "ERROR: tag '$(NT)' does not match semver format (vX.Y.Z)"; \
		exit 1; \
	fi
	@echo -n "Are you sure to create and push $(NT) tag? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo $(NT) > ./version.txt
	@git add -A
	@git commit -a -s -m "Cut $(NT) release"
	@git tag $(NT)
	@git push origin $(NT)
	@git push
	@echo "Done."

image-build: deps ## build Docker image
	@docker buildx build --load -f ./docker/Dockerfile -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

image-run: image-build ## run Docker image
	@docker run --rm -p 8011:80 $(DOCKER_IMAGE):$(DOCKER_TAG)

clean: ## remove build artifacts
	@rm -f faces
	@rm -f coverage.out
	@echo "Clean complete."

ci: lint test image-build ## run full CI pipeline (lint, test, image-build)
	@echo "CI pipeline complete."

# Renovate
NVM_VERSION := 0.40.4

renovate-bootstrap: ## install nvm and npm for Renovate
	@command -v node >/dev/null 2>&1 || { \
		echo "Installing nvm $(NVM_VERSION)..."; \
		curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v$(NVM_VERSION)/install.sh | bash; \
		export NVM_DIR="$$HOME/.nvm"; \
		[ -s "$$NVM_DIR/nvm.sh" ] && . "$$NVM_DIR/nvm.sh"; \
		nvm install --lts; \
	}

renovate-validate: renovate-bootstrap ## validate Renovate configuration
	@npx --yes renovate --platform=local
