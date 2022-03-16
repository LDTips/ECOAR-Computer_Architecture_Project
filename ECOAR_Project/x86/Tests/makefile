C_COMPILER=gcc
ASM_COMPILER=nasm
BIT=-m32

all: nasm gcc linker cleanup

nasm:
	$(ASM_COMPILER) -g -f elf decode128.asm

gcc:
	$(C_COMPILER) -g $(BIT) -std=c99 -c main.c

linker:
	$(C_COMPILER) -g $(BIT) -o out decode128.o main.o

cleanup:
	rm *.o
