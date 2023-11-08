
build:
	zig build

lint:
	zig fmt --check src/*.zig

test:
	zig test src/tests.zig

test-all: lint test

client-sample: build
	./zig-out/bin/z-upload -client ./tmp/testfile.txt /tmp/testfile.txt@127.0.0.1:8000

server-sample: build
	./zig-out/bin/z-upload -server 127.0.0.1:8000
