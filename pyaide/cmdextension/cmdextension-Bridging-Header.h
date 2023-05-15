//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

extern int Py_BytesMain(int argc, char **argv);
int python3_run(int argc, char** argv);
void initIntepreters(void);

typedef void (*exit_t)(int value);
