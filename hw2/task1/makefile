.PHONY: interactive

build-image:	
	docker build -t nasm-build .

interactive: build-image
	mkdir -p output
	docker run -it --rm -v $(PWD)/output:/workspace/output nasm-build \
			sh -c "nasm -f elf64 reverse_str.asm -o reverse_str.o -l output/reverse_str.lst && ld -o reverse_str reverse_str.o && strace -o output/strace_output.txt ./reverse_str"

results:
	@echo "=== Results ==="
	@ls -la output/
	@echo "=== strace output ==="
	@cat output/strace_output.txt
