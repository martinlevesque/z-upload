
build:
	zig build

lint:
	zig fmt --check src/*.zig

test:
	zig test src/tests.zig

test-all: lint test

client-sample: build
	./zig-out/bin/z-upload -client 

server-sample: build
	./zig-out/bin/z-upload -server
