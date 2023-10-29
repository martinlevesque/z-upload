
build:
	zig build

run: build
	./zig-out/bin/z-upload $(filter-out run,$(MAKECMDGOALS))
