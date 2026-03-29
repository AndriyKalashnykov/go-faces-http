[![CI](https://github.com/AndriyKalashnykov/go-faces-http/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/AndriyKalashnykov/go-faces-http/actions/workflows/ci.yml)
[![Hits](https://hits.sh/github.com/AndriyKalashnykov/go-faces-http.svg?view=today-total&style=plastic)](https://hits.sh/github.com/AndriyKalashnykov/go-faces-http/)
[![License: CC0](https://img.shields.io/badge/License-CC0-brightgreen.svg)](https://creativecommons.org/publicdomain/zero/1.0/)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://app.renovatebot.com/dashboard#github/AndriyKalashnykov/go-faces-http)

# go-faces-http

Face detection HTTP microservice based on [`dlib`](https://github.com/davisking/dlib-models). Built with Go and packaged as a statically-linked binary and Docker image.

## Quick Start

```bash
make deps          # check and install prerequisites
make lint          # run Go and Dockerfile linters
make test          # run tests with coverage
make image-build   # build Docker image
make run           # build and run locally on :8011
```

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| [Go](https://go.dev/dl/) | 1.25+ | Language runtime and compiler |
| [Docker](https://www.docker.com/) | latest | Container image builds |
| [Git](https://git-scm.com/) | latest | Version control |
| [GNU Make](https://www.gnu.org/software/make/) | 3.81+ | Build orchestration |
| [golangci-lint](https://golangci-lint.run/) | 2.1.6 | Go linter (auto-installed by `make deps`) |
| [hadolint](https://github.com/hadolint/hadolint) | 2.12.0 | Dockerfile linter (auto-installed by `make lint`) |
| [act](https://github.com/nektos/act) | 0.2.86 | Run GitHub Actions locally (optional, auto-installed by `make ci-run`) |

Install all required dependencies:

```bash
make deps
```

## Installation

Portable statically-linked binary for Linux AMD64 is available
on [releases](https://github.com/AndriyKalashnykov/go-faces-http/releases).

```
wget https://github.com/AndriyKalashnykov/go-faces-http/releases/download/latest/linux_amd64.tar.gz && tar xf linux_amd64.tar.gz && rm linux_amd64.tar.gz
./faces -h
```

It is also available as a docker image.

```
docker run --rm -p 8011:80 ghcr.io/andriykalashnykov/go-faces-http:v0.0.9
```

If you want to build the app from source, please follow the instructions on
[dependency setup](https://github.com/Kagami/go-face?tab=readme-ov-file#requirements).

## Usage

```
./faces -h
Usage of ./faces:
  -listen string
        listen address (default "localhost:8011")
```

Start server.

```
./faces
2024/01/15 23:44:22 recognizer init 424.357089ms
2024/01/15 23:44:22 http://localhost:80/docs
```

Send request.

```
curl -X 'POST' \
  'http://localhost:8011/image' \
  -H 'accept: application/json' \
  -H 'Content-Type: multipart/form-data' \
  -F 'image=@person.jpg;type=image/jpeg'
```

```json
{
  "elapsedSec": 2.373028184,
  "found": 4,
  "faces": [
    {
      "Rectangle": {
        "Min": { "X": 584, "Y": 1228 },
        "Max": { "X": 1029, "Y": 1673 }
      },
      "Descriptor": [
        -0.122200325,
        0.10511437,
        0.05358115,
        "............. cut here ..........."
      ]
    }
  ]
}
```

## Available Make Targets

Run `make help` to see all available targets.

### Build & Run

| Target | Description |
|--------|-------------|
| `make build` | Build Go binary |
| `make run` | Build and run the application locally |
| `make clean` | Remove build artifacts |
| `make update` | Update dependency packages to latest versions |

### Code Quality

| Target | Description |
|--------|-------------|
| `make lint` | Run linters (Go + Dockerfile) |
| `make test` | Run tests with coverage |

### Docker

| Target | Description |
|--------|-------------|
| `make image-build` | Build Docker image |
| `make image-run` | Run Docker container |

### CI

| Target | Description |
|--------|-------------|
| `make ci` | Run full local CI pipeline (lint, test, build) |
| `make ci-run` | Run GitHub Actions workflow locally via [act](https://github.com/nektos/act) |

### Utilities

| Target | Description |
|--------|-------------|
| `make deps` | Check and install required dependencies |
| `make release` | Create and push a new semver tag |
| `make renovate-validate` | Validate Renovate configuration |

## CI/CD

GitHub Actions runs on every push to `main`, tags `v*`, and pull requests.

| Job | Triggers | Steps |
|-----|----------|-------|
| **ci** | push, PR, tags | Lint, Test, Build |
| **release** | tag push (`v*`) | Build image, push to GHCR, create GitHub release with binary |

[Renovate](https://docs.renovatebot.com/) keeps dependencies up to date with platform automerge enabled.

## License

This repo contains models created by [Davis King dlib-models](https://github.com/davisking/dlib-models),
licensed in the public domain or under CC0 1.0 Universal. See [LICENSE](./LICENSE).

### References

* [Building a platform-specific executable with Docker Image and uploading to GitHub releases](https://dev.to/vearutop/building-a-portable-face-recognition-application-with-go-and-dlib-12p1)
