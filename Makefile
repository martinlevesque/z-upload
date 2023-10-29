
build:
	zig build

test:
	zig test src/tests.zig

run: build
	./zig-out/bin/z-upload $(filter-out run,$(MAKECMDGOALS))
