# CLAUDE.md

## Project Overview

Go-based face detection HTTP microservice using dlib. Provides a REST API to detect faces in uploaded images. Packaged as a statically-linked binary and Docker image.

## Language & Runtime

- Go (version from `go.mod`)
- CGO enabled (requires dlib, blas, lapack, gfortran)
- Docker multi-stage build (Ubuntu builder -> Alpine runtime)

## Build & Development

```bash
make help          # list all targets
make build         # build Go binary
make test          # run tests with coverage
make lint          # run golangci-lint
make image-build   # build Docker image
make image-run     # build and run Docker image
make ci            # full CI pipeline (lint, test, image-build)
make clean         # remove build artifacts
make run           # build and run locally on :8011
make release       # create and push a new semver tag
```

## Project Structure

- `faces.go` -- main application (HTTP server, face detection endpoint)
- `models/` -- embedded dlib model files
- `docker/Dockerfile` -- multi-stage Docker build
- `.golangci.yml` -- linter configuration
- `version.txt` -- current release version

## CI/CD

### CI Workflow (`ci.yml`)

- **Triggers**: push to `main`, tag pushes (`v*`), pull requests
- **Jobs**:
  - `tests` -- builds Docker image via `make image-build`
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
