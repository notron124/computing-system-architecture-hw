.PHONY: all normal broken clean

build-image:	
	docker build -t nasm-build .

normal: build-image
	mkdir -p output
	docker run --rm -v $(PWD)/output:/workspace/output nasm-build \
			sh -c "cmake -DCMAKE_ASM_NASM_OBJECT_FORMAT=elf64 -DBUILD_BROKEN_EXAMPLE=OFF -B build_normal && cmake --build build_normal --verbose --target run_strace"

broken: build-image
	mkdir -p output
	docker run --rm -v $(PWD)/output:/workspace/output nasm-build \
			sh -c "cmake -DCMAKE_ASM_NASM_OBJECT_FORMAT=elf64 -DBUILD_BROKEN_EXAMPLE=ON -B build_broken && cmake --build build_broken --verbose --target run_strace"

all: normal broken

clean:
	rm -rf output build_normal build_broken

results:
	@echo "=== Results ==="
	@ls -la output/
