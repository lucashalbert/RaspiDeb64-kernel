FROM ubuntu:18.04

ENV WORKDIR=/workdir \
    BUILDS=/workdir/builds \
    KERNEL_BRANCH=rpi-4.19.y  \
    KERNEL_REPO=https://www.github.com/raspberrypi/linux.git \
    TIMESTAMP_OUTPUT=true

WORKDIR ${WORKDIR}

# Install build dependencies
RUN apt-get update -y && \
  apt-get install --no-install-recommends -y bc build-essential gcc-aarch64-linux-gnu curl git-core zip unzip flex bison libssl-dev ca-certificates kmod && \
  apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY build.sh ${WORKDIR}
ENTRYPOINT ["./build.sh"]
