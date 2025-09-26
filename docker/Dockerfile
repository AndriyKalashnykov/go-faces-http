# https://hub.docker.com/_/ubuntu/tags
FROM ubuntu:24.04@sha256:353675e2a41babd526e2b837d7ec780c2a05bca0164f7ea5dbbd433d21d166fc AS builder

RUN apt-get update
RUN apt-get install -y build-essential cmake curl

# Cross compiling dlib for ARM on Ubuntu - https://www.jofre.de/?p=1494

# Install DLib
#RUN mkdir /dlib && cd /dlib && curl -sLO http://dlib.net/files/dlib-19.24.tar.bz2 && tar xf dlib-19.24.tar.bz2
#RUN cd /dlib/dlib-19.24 && mkdir build && cd build && cmake .. && cmake --build . --config Release && make install && rm -rf /dlib

# https://packages.debian.org/source/sid/dlib
# https://packages.debian.org/sid/liblapack3
# http://mirrors.edge.kernel.org/ubuntu/pool/main/libj/libjpeg-turbo/
# apt-cache search libjpeg
# apt-cache search openblas
RUN apt-get install -y \
    libdlib-dev \
    libopenblas-dev \
    libblas-dev \
    libblaspp-dev \
    libatlas-base-dev \
    libgslcblas0 \
    libjpeg-dev \
    libpng-dev \
    liblapack-dev \
    libjpeg-turbo8-dev \
    gfortran \
    libx11-dev libgtk-3-dev


WORKDIR /app

ADD . .

# Install Go (version from go.mod)
RUN set -eux; \
    GOVERSION="$(sed -n 's/^go[[:space:]]\+\([0-9][0-9.]*\)/\1/p' go.mod)"; \
    curl -sLO "https://go.dev/dl/go${GOVERSION}.linux-amd64.tar.gz"; \
    tar -C /usr/local -xzf "go${GOVERSION}.linux-amd64.tar.gz"; \
    rm -f "go${GOVERSION}.linux-amd64.tar.gz"

RUN CGO_ENABLED=1 CGO_LDFLAGS="-static -lgfortran" /usr/local/go/bin/go build -tags static -o faces faces.go

# Exporting minimal docker image with pre-built binary.
FROM alpine@sha256:4bcff63911fcb4448bd4fdacec207030997caf25e9bea4045fa6c8c44de311d1
WORKDIR /app
COPY --from=builder /app/faces .
CMD ["faces", "-listen", "0.0.0.0:80"]

