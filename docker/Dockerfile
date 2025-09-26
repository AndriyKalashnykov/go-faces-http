
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
    libx11-dev libgtk-3-dev \
    git

WORKDIR /app

ADD . .

# Install Go (version from go.mod)
RUN set -eux; \
    GOVERSION="$(sed -n 's/^go[[:space:]]\+\([0-9][0-9.]*\)/\1/p' go.mod)"; \
    curl -sLO "https://go.dev/dl/go${GOVERSION}.linux-amd64.tar.gz"; \
    tar -C /usr/local -xzf "go${GOVERSION}.linux-amd64.tar.gz"; \
    rm -f "go${GOVERSION}.linux-amd64.tar.gz"

ENV PATH=$PATH:/usr/local/go/bin
# Get version from Git tag or default to 'dev'
RUN VERSION=$(git describe --tags 2>/dev/null || echo 'dev') && \
    COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo 'unknown') && \
    BUILDTIME=$(date -u '+%Y-%m-%dT%H:%M:%SZ') && \
    CGO_ENABLED=1 CGO_LDFLAGS="-static -lgfortran -lblas -llapack" go build \
        -tags netgo,osusergo,static \
        -buildvcs=true \
        -ldflags " \
            -X 'main.version=$VERSION' \
            -X 'github.com/AndriyKalashnykov/go-faces-http/internal/build.Version=$VERSION' \
            -X 'github.com/AndriyKalashnykov/go-faces-http/internal/build.Commit=$COMMIT' \
            -X 'github.com/AndriyKalashnykov/go-faces-http/internal/build.BuildTime=$BUILDTIME' \
            -extldflags '-static'" \
        -o faces faces.go

# Exporting minimal docker image with pre-built binary.
FROM alpine@sha256:4bcff63911fcb4448bd4fdacec207030997caf25e9bea4045fa6c8c44de311d1

# Install runtime dependencies for the binary
RUN apk add --no-cache ca-certificates

WORKDIR /app

# Copy binary and models from builder
COPY --from=builder /app/faces /app/faces
COPY --from=builder /app/models /app/models/

# Make the binary executable
RUN chmod +x /app/faces

# Create a symlink in a directory that's in PATH
RUN mkdir -p /usr/local/bin && \
    ln -s /app/faces /usr/local/bin/faces

# Expose the port
EXPOSE 80

# Run the app
# The executable in ENTRYPOINT
ENTRYPOINT ["/app/faces"]
# Only the parameters in CMD
CMD ["-listen", "0.0.0.0:80"]