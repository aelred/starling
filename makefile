CC=gcc

all: obj bin starling test

clean:
	rm obj -rf
	rm bin -rf

starling: obj/main.o obj/starling.o obj/util.o
	$(CC) -o bin/$@ $^

test: obj/test.o obj/test_util.o obj/util.o obj/test_starling.o obj/starling.o
	$(CC) -o bin/$@ $^

obj/%.o: src/%.c
	$(CC) -c -o $@ $<

obj:
	mkdir obj

bin:
	mkdir bin
