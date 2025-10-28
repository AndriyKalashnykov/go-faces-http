projectname?=go-faces-http

CURRENTTAG:=$(shell git describe --tags --abbrev=0)
NEWTAG ?= $(shell bash -c 'read -p "Please provide a new tag (currnet tag - ${CURRENTTAG}): " newtag; echo $$newtag')

default: help

.PHONY: help
help: ## list makefile targets
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

.PHONY: test
test: ## run tests
	go test --cover -parallel=1 -v -coverprofile=coverage.out -v ./...
	go tool cover -func=coverage.out | sort -rnk3

.PHONY: build
build: ## build golang binary
	VERSION=$$(git describe --tags 2>/dev/null || echo 'dev'); \
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
.PHONY: update
update: ## update dependency packages to latest versions
	@go get -u ./...; go mod tidy

.PHONY: release
release: ## create and push a new tag
	$(eval NT=$(NEWTAG))
	@echo -n "Are you sure to create and push ${NT} tag? [y/N] " && read ans && [ $${ans:-N} = y ]
	@echo ${NT} > ./version.txt
	@git add -A
	@git commit -a -s -m "Cut ${NT} release"
	@git tag ${NT}
	@git push origin ${NT}
	@git push
	@echo "Done."

bdi: ## build Docker image
	docker buildx build --load -f ./docker/Dockerfile -t andriykalashnykov/go-faces-http:latest .

run-bdi: ## run Docker image
	docker run --rm -p 8011:80 andriykalashnykov/go-faces-http:latest
# docker run --rm -p 8011:80 ghcr.io/andriykalashnykov/go-faces-http:v0.0.5