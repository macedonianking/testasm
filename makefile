.PHONY: all
all: main

main: *.s
	gcc -g -o $@ $^
