# dockerfile to create a build environment with the codon static compiler for python

ARG CODON_INSTALL_DIR="/opt/codon"

FROM debian:stable AS codon-build

RUN apt update
RUN apt install -y git

ENV LLVM_BUILD_DIR="/tmp/llvm-project"
RUN git clone --depth 1 -b codon https://github.com/exaloop/llvm-project $LLVM_BUILD_DIR

ENV LLVM_INSTALL_DIR="/opt/llvm-codon"
RUN mkdir -p $LLVM_INSTALL_DIR

RUN apt install -y build-essential cmake ninja-build python3 zlib1g-dev

# build llvm
RUN cmake -S $LLVM_BUILD_DIR/llvm -B $LLVM_BUILD_DIR/build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$LLVM_INSTALL_DIR \
    -DLLVM_BUILD_TOOLS=OFF \
    -DLLVM_ENABLE_PROJECTS=clang \
    -DLLVM_ENABLE_RTTI=ON \
    -DLLVM_ENABLE_ZLIB=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_TARGETS_TO_BUILD="host;NVPTX"
RUN cmake --build $LLVM_BUILD_DIR/build
RUN cmake —-install $LLVM_BUILD_DIR/build

ENV CODON_BUILD_DIR="/tmp/codon"
RUN git clone -b master https://github.com/exaloop/codon.git $CODON_BUILD_DIR

ARG CODON_INSTALL_DIR
RUN mkdir -p $CODON_INSTALL_DIR

# build codon
RUN cmake -S $CODON_BUILD_DIR -B $CODON_BUILD_DIR/build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_C_COMPILER=$LLVM_INSTALL_DIR/bin/clang \
    -DCMAKE_CXX_COMPILER=$LLVM_INSTALL_DIR/bin/clang++ \
    -DCMAKE_INSTALL_PREFIX=$CODON_INSTALL_DIR \
    -DLLVM_DIR=$LLVM_INSTALL_DIR/lib/cmake/llvm
RUN cmake --build $CODON_BUILD_DIR/build
RUN cmake —-install $CODON_BUILD_DIR/build

# start from fresh image
FROM debian:stable-slim

ARG CODON_INSTALL_DIR
COPY --from=codon-build $CODON_INSTALL_DIR $CODON_INSTALL_DIR

COPY --from=codon-build /usr/ /usr/

ENV PATH="$CODON_INSTALL_DIR/bin:$PATH"
