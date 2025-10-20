cmake_minimum_required(VERSION 3.14)
project(Hello_World LANGUAGES ASM_NASM)

set(CMAKE_ASM_NASM_OBJECT_FORMAT elf64) # почему-то не везде работает

option(BUILD_BROKEN_EXAMPLE "Build broken example, that returns error" OFF)

if (BUILD_BROKEN_EXAMPLE) 
    set(NASM_SOURCE_FILE helloworld_broken.asm)
    set(STRACE_FILE_PATH "../output/strace_output_broken.txt")
    set(CMAKE_ASM_NASM_FLAGS "-l ../output/helloworld_broken.lst")
else()
    set(NASM_SOURCE_FILE helloworld.asm)
    set(STRACE_FILE_PATH "../output/strace_output.txt")
    set(CMAKE_ASM_NASM_FLAGS "-l ../output/helloworld.lst")
endif()

add_executable(helloworld ${NASM_SOURCE_FILE})

add_custom_target(run_strace
    COMMAND strace -o ${STRACE_FILE_PATH} ./helloworld
    COMMENT "Writing strace result into ${STRACE_FILE_PATH} file"
    DEPENDS helloworld
    VERBATIM
)
