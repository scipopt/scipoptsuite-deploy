FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive
ARG TARGETPLATFORM
ARG TAG

RUN apt-get update && apt-get -y install \
    build-essential \
    gfortran \
    curl

# Upstream names the packages scipoptsuite_<version>-1+<distro>_<arch>.deb,
# using aarch64 where Docker says arm64.
WORKDIR /tmp
RUN case "$TARGETPLATFORM" in \
        linux/amd64) ARCH=amd64 ;; \
        linux/arm64) ARCH=aarch64 ;; \
        *) echo "Unsupported platform: $TARGETPLATFORM" && exit 1 ;; \
    esac && \
    curl -fLo SCIPOptSuite.deb https://github.com/scipopt/scip/releases/download/v${TAG}/scipoptsuite_${TAG}-1+bookworm_${ARCH}.deb && \
    apt-get -y install ./SCIPOptSuite.deb && \
    rm SCIPOptSuite.deb && \
    rm -rf /var/lib/apt/lists/*
