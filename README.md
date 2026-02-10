[![Hits](https://hits.sh/github.com/AndriyKalashnykov/go-faces-http.svg?view=today-total&style=plastic)](https://hits.sh/github.com/AndriyKalashnykov/go-faces-http/)
[![License: CC0](https://img.shields.io/badge/License-CC0-brightgreen.svg)](https://creativecommons.org/publicdomain/zero/1.0/)
[![Renovate enabled](https://img.shields.io/badge/renovate-enabled-brightgreen.svg)](https://app.renovatebot.com/dashboard#github/AndriyKalashnykov/go-faces-http)
# go-faces-http

Face detection HTTP microservice based on [`dlib`](https://github.com/davisking/dlib-models).

## Installation

Portable statically-linked binary for Linux AMD64 is available
on [releases](https://github.com/AndriyKalashnykov/go-faces-http/releases).

```
wget https://github.com/AndriyKalashnykov/go-faces-http/releases/download/latest/linux_amd64.tar.gz && tar xf linux_amd64.tar.gz && rm linux_amd64.tar.gz
./faces -h
```

It is also available as a docker image.

```
docker run --rm -p 8011:80 ghcr.io/andriykalashnykov/go-faces-http:v0.0.5
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
mkdir ~/projects && cd ~/projects
git clone https://github.com/AndriyKalashnykov/go-faces-http
cd ~/projects/go-faces-http

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
        "Min": {
          "X": 584,
          "Y": 1228
        },
        "Max": {
          "X": 1029,
          "Y": 1673
        }
      },
      "Descriptor": [
        -0.122200325,
        0.10511437,
        0.05358115,
        0.011272355,
        -0.09460048,
        "............. cut here ..........."
      ]
    }
  ]
}
```

This repo contains models, that were created by [Davis King DLib Models](https://github.com/davisking/dlib-models) and are
licensed in the public domain or under CC0 1.0 Universal. See [LICENSE](./LICENSE).

### References

* [Building a platform-specific executable with Docker Image and uploading to GiHub releases](https://dev.to/vearutop/building-a-portable-face-recognition-application-with-go-and-dlib-12p1)