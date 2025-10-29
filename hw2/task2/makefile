.PHONY: interactive

build-image:	
	docker build -t nasm-build .

interactive: build-image
	mkdir -p output
	docker run -it --rm -v $(PWD)/output:/workspace/output nasm-build \
			sh -c "nasm -f elf64 simple_calculator.asm -o simple_calculator.o -l output/simple_calculator.lst && ld -o simple_calculator simple_calculator.o && strace -o output/strace_output.txt ./simple_calculator"

results:
	@echo "=== Results ==="
	@ls -la output/
	@echo "=== strace output ==="
	@cat output/strace_output.txt
