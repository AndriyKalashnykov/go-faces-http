# https://hub.docker.com/_/ubuntu/tags
FROM ubuntu:oracular-20241009 AS builder

RUN apt-get update
RUN apt-get install -y build-essential cmake curl

# Cross compiling dlib for ARM on Ubuntu - https://www.jofre.de/?p=1494

# Install DLib
#RUN mkdir /dlib && cd /dlib && curl -sLO http://dlib.net/files/dlib-19.24.tar.bz2 && tar xf dlib-19.24.tar.bz2
#RUN cd /dlib/dlib-19.24 && mkdir build && cd build && cmake .. && cmake --build . --config Release && make install && rm -rf /dlib

# https://packages.debian.org/source/sid/dlib
# https://packages.debian.org/sid/liblapack3
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

# Install Go
RUN curl -sLO https://go.dev/dl/go1.23.2.linux-amd64.tar.gz && tar -C /usr/local -xzf go1.23.2.linux-amd64.tar.gz && rm -rf go1.23.2.linux-amd64.tar.gz

WORKDIR /app
ADD . .
RUN CGO_ENABLED=1 CGO_LDFLAGS="-static -lgfortran" /usr/local/go/bin/go build -tags static -o faces faces.go

# Exporting minimal docker image with pre-built binary.
FROM alpine
WORKDIR /app
COPY --from=builder /app/faces .
CMD ["faces", "-listen", "0.0.0.0:80"]

