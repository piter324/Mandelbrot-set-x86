CC=g++
CFLAGS=-Wall
all: mandelCpp.o mandel.o
	$(CC) $(CFLAGS) mandelCpp.o -lSDL2 mandel.o -o mandelbrot.o
mandelCpp.o: MandelbrotSet.cpp
	$(CC) MandelbrotSet.cpp -lSDL2 -c -o mandelCpp.o
mandel.o: mandel.s
	nasm -f elf64 -o mandel.o mandel.s
clean:
	rm -f *.o
