.PHONY: all normal broken clean

build-image:	
	docker build -t nasm-build .

normal: build-image
	mkdir -p output
	docker run --rm -v $(PWD)/output:/workspace/output nasm-build \
			sh -c "nasm -f elf64 helloworld.asm -o helloworld.o -l output/helloworld.lst && ld -o helloworld helloworld.o && strace -o output/strace_output.txt ./helloworld"

broken: build-image
	mkdir -p output
	docker run --rm -v $(PWD)/output:/workspace/output nasm-build \
			sh -c "nasm -f elf64 helloworld_broken.asm -o helloworld_broken.o -l output/helloworld_broken.lst && ld -o helloworld_broken helloworld_broken.o && strace -o output/strace_output_broken.txt ./helloworld_broken"

all: normal broken

clean:
	rm -rf output build_normal build_broken

results:
	@echo "=== Results ==="
	@ls -la output/
	@echo "=== strace output ==="
	@cat output/strace_output.txt
	@echo "=== strace output broken ==="
	@cat output/strace_output_broken.txt
