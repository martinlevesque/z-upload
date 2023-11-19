
build:
	zig build

lint:
	zig fmt --check src/*.zig

lint-fix:
	zig fmt src/*.zig

unit-test:
	zig test src/tests.zig

end-to-end-test:
	bash tests/end_to_end.sh

test-all: lint unit-test end-to-end-test

client-sample: build
	./zig-out/bin/z-upload ./tmp/testfile.txt /tmp/testfile-out.txt@127.0.0.1:8000

server-sample: build
	./zig-out/bin/z-upload -server 0.0.0.0:8000
