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
make deps-check        # show required tool versions and installation status
make build             # build Go binary (requires CGO and dlib)
make test              # run tests with coverage and race detection
make format            # auto-format Go source files and tidy modules
make lint              # run golangci-lint (includes gocritic via .golangci.yml)
make lint-dockerfile   # lint the Dockerfile with hadolint
make image-build       # build Docker image
make image-run         # run Docker container
make image-stop        # stop Docker container
make image-push        # push Docker image to registry
make image-push-ghcr   # tag and push Docker image to GHCR
make release-artifacts # extract binary and create release archives
make ci                # full CI pipeline (format, lint, test, build)
make ci-run            # run GitHub Actions locally via act
make clean             # remove build artifacts
make run               # build and run locally on :8011
make update            # update Go dependencies
make release           # create and push a new tag
make deps-node         # install nvm and Node.js for Renovate
make renovate-bootstrap # install nvm and npm for Renovate
make renovate-validate # validate Renovate configuration
```

## Key Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `GOLANGCI_VERSION` | `2.11.4` | golangci-lint version |
| `HADOLINT_VERSION` | `2.14.0` | hadolint version |
| `ACT_VERSION` | `0.2.87` | act version for local CI |
| `NVM_VERSION` | `0.40.4` | nvm version for Renovate validation |
| `GVM_SHA` | `dd6525...` | gvm commit SHA for reproducible installs |

## Project Structure

- `faces.go` -- main application (HTTP server, face detection endpoint)
- `models/` -- embedded dlib model files
- `docker/Dockerfile` -- multi-stage Docker build
- `.dockerignore` -- Docker build exclusions
- `.golangci.yml` -- linter configuration (golangci-lint v2 with gocritic)
- `.hadolint.yaml` -- Dockerfile linter configuration
- `renovate.json` -- Renovate dependency update configuration
- `version.txt` -- current release version

**Note**: No `*_test.go` files exist yet. `make test` runs but reports zero coverage. Helper targets `deps-hadolint`, `deps-act`, and `deps-node` auto-install tools on first use.

## CI/CD

### CI Workflow (`ci.yml`)

- **Triggers**: push to `main`, tag pushes (`v*`), pull requests, workflow_call
- **Jobs**:
  - `static-check` -- Dockerfile lint (fast, no native deps needed)
  - `build` (needs: static-check) -- Docker image build (Go compilation runs inside Docker, requires dlib)
  - `release` (tag-gated, needs: build) -- builds image, pushes to GHCR, creates GitHub release with binary

### Cleanup Workflow (`cleanup-runs.yml`)

- **Triggers**: weekly schedule (Sunday midnight) + manual dispatch
- **Job**: deletes workflow runs older than 7 days, keeps minimum 5

## Conventions

- Makefile is the single source of truth for build commands
- Actions pinned to commit SHAs
- Conventional commits: `feat:`, `fix:`, `chore:`, `ci:`
- Docker image: `andriykalashnykov/go-faces-http`
- GHCR image: `ghcr.io/<owner>/go-faces-http`
- Go version managed via gvm locally, `actions/setup-go` in CI
- golangci-lint v2 with gocritic enabled via `.golangci.yml`

## Skills

Use the following skills when working on related files:

| File(s) | Skill |
|---------|-------|
| `Makefile` | `/makefile` |
| `renovate.json` | `/renovate` |
| `README.md` | `/readme` |
| `.github/workflows/*.yml` | `/ci-workflow` |

When spawning subagents, always pass conventions from the respective skill into the agent's prompt.
