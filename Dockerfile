FROM alpine:latest

WORKDIR /app

COPY . /app

# add make
RUN apk add --no-cache make

RUN wget https://ziglang.org/download/0.11.0/zig-linux-x86_64-0.11.0.tar.xz -O /tmp/zig.tar.xz
RUN mkdir -p /tmp/zig
RUN tar -xf /tmp/zig.tar.xz -C /tmp/zig
RUN mv /tmp/zig/zig* /opt

ENV ZIG_PATH /opt/zig-linux-x86_64-0.11.0

# Add Zig to the PATH
ENV PATH $ZIG_PATH:$PATH

RUN zig build

# Specify a command to run on container start
CMD ["make", "server"]