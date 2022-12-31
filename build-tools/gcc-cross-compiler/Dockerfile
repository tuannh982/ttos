FROM ubuntu:jammy

ARG BUILD_TARGET

# build dependencies
RUN apt update

RUN apt install -yq \
    curl \
    build-essential \
    bison \
    flex \
    libgmp3-dev \
    libmpc-dev \
    libmpfr-dev \
    texinfo \
    file \
    grub-common \
    grub-pc-bin \
    xorriso

# install gcc cross compiler
WORKDIR /src
# download src
RUN curl https://ftp.gnu.org/gnu/binutils/binutils-2.39.tar.gz -o binutils-2.39.tar.gz
RUN curl https://ftp.gnu.org/gnu/gcc/gcc-12.2.0/gcc-12.2.0.tar.gz -o gcc-12.2.0.tar.gz
# extract
RUN tar -xf binutils-2.39.tar.gz && mv binutils-2.39 src-binutils
RUN tar -xf gcc-12.2.0.tar.gz && mv gcc-12.2.0 src-gcc
# env
ENV PREFIX="/usr/local/cross"
ENV TARGET=$BUILD_TARGET
ENV PATH="$PREFIX/bin:$PATH"
# buid
COPY ./build.sh /src
RUN chmod 777 ./build.sh
RUN ./build.sh
# purge
WORKDIR /
# RUN rm -r /src

ENTRYPOINT ["tail", "-f", "/dev/null"]