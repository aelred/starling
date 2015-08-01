CC=gcc

CFLAGS= -lm -g -std=c11 -pedantic -Wall -Werror -Wextra -Wshadow \
	-Wformat-nonliteral -Wcast-align -Wbad-function-cast \
	-Wmissing-prototypes -Wstrict-prototypes -Wmissing-declarations \
	-Winline -Wundef -Wnested-externs -Wcast-qual -Wwrite-strings \
	-Wfloat-equal -Winit-self -Wlogical-op -Wmissing-include-dirs

SUFFIXES += .d

SOURCES = $(shell find src/ -name "*.c") src/parser.c src/lexer.c
DEPFILES = $(pathsubst %.c, %.d, $(SOURCES))

OBJS = obj/starling.o obj/util.o obj/parser.o obj/lexer.o obj/vector.o obj/node.o obj/string.o
TEST = obj/test.o obj/test_util.o obj/test_starling.o obj/test_node.o

-include $(DEPFILES)

all: obj bin starling test

clean:
	rm -rf obj/*.o bin/*
	rm -rf src/parser.c src/parser.h src/parser.output src/lexer.c src/lexer.h

starling: obj/main.o $(OBJS)
	$(CC) $(CFLAGS) -o bin/$@ $^

test: $(OBJS) $(TEST)
	$(CC) $(CFLAGS) -o bin/$@ $^

obj/%.o: src/%.c src/%.d
	$(CC) $(CFLAGS) -o $@ -c $<

src/%.d: src/%.c src/parser.c src/lexer.c
	$(CC) $(CFLAGS) -MM -MT '$(pathsubst src/%.c, obj/%.o, $<)' $< -MF $@

obj/lexer.o: src/parser.c
src/lexer.c: src/lexer.l
	flex --header-file=src/lexer.h -o $@ $<

obj/parser.o: src/lexer.c
src/parser.c: src/parser.y
	bison -v -d -o $@ $<

obj:
	mkdir obj

bin:
	mkdir bin
