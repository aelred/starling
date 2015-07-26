struct Object {
    int value;
};

struct Object eval(const char *);

void object_str(const struct Object, char **);

void repl();
