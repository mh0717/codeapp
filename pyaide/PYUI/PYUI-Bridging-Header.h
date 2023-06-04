//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Foundation/Foundation.h>

extern int Py_BytesMain(int argc, char **argv);
int python3_run(int argc, char** argv);
void initIntepreters(void);

typedef void (*exit_t)(int value);



int rectangles_main();
extern void update_sdl_winsize(CGRect size);
int pymain(const char* filepath);


int SDL_SendQuit(void);
void SDL_Quit(void);
