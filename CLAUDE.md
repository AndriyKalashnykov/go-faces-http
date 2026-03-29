# CLAUDE.md

## Project Overview

Go-based face detection HTTP microservice using dlib. Provides a REST API to detect faces in uploaded images. Packaged as a statically-linked binary and Docker image.

## Language & Runtime

- Go (version from `go.mod`)
- CGO enabled (requires dlib, blas, lapack, gfortran)
- Docker multi-stage build (Ubuntu builder -> Alpine runtime)

## Build & Development

```bash
make help              # list all targets
make deps              # check and install required dependencies
make build             # build Go binary
make test              # run tests with coverage
make lint              # run linters (Go + Dockerfile)
make image-build       # build Docker image
make image-run         # run Docker container
make ci                # full CI pipeline (lint, test, build)
make ci-run            # run GitHub Actions locally via act
make clean             # remove build artifacts
make run               # build and run locally on :8011
make update            # update Go dependencies
make release           # create and push a new semver tag
make renovate-validate # validate Renovate configuration
```

## Key Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `GOLANGCI_VERSION` | `2.1.6` | golangci-lint version |
| `HADOLINT_VERSION` | `2.12.0` | hadolint version |
| `ACT_VERSION` | `0.2.86` | act version for local CI |
| `NVM_VERSION` | `0.40.4` | nvm version for Renovate validation |

## Project Structure

- `faces.go` -- main application (HTTP server, face detection endpoint)
- `models/` -- embedded dlib model files
- `docker/Dockerfile` -- multi-stage Docker build
- `.golangci.yml` -- linter configuration
- `.hadolint.yaml` -- Dockerfile linter configuration
- `version.txt` -- current release version

## CI/CD

### CI Workflow (`ci.yml`)

- **Triggers**: push to `main`, tag pushes (`v*`), pull requests
- **Jobs**:
  - `ci` -- lint (`make lint`), test (`make test`), build (`make image-build`)
  - `release` (tag-gated) -- builds image, pushes to GHCR, creates GitHub release with binary

### Cleanup Workflow (`cleanup-runs.yml`)

- **Triggers**: weekly schedule (Sunday midnight) + manual dispatch
- **Job**: deletes workflow runs older than 7 days, keeps minimum 5

## Conventions

- Makefile is the single source of truth for build commands
- Actions pinned to commit SHAs
- Conventional commits: `feat:`, `fix:`, `chore:`, `ci:`
- Docker image: `andriykalashnykov/go-faces-http`
- GHCR image: `ghcr.io/<owner>/go-faces-http`

## Skills

Use the following skills when working on related files:

| File(s) | Skill |
|---------|-------|
| `Makefile` | `/makefile` |
| `renovate.json` | `/renovate` |
| `README.md` | `/readme` |
| `.github/workflows/*.yml` | `/ci-workflow` |

When spawning subagents, always pass conventions from the respective skill into the agent's prompt.
