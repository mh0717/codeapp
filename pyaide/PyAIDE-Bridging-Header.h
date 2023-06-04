//
//  PyAIDE-Bridging-Header.h
//  pyaide
//
//  Created by Huima on 2023/5/10.
//



#import "../CodeApp/Utilities/KBWebViewBase.h"
#import "pyaide/LineNumberTextView/LineNumberTextView.h"

extern int Py_BytesMain(int argc, char **argv);

void initIntepreters();
NSString* pycompleteCode(NSString* code, NSString* path, int index, BOOL getdef, int vid, NSString* uid);
int python3_run(int argc, char** argv);

//typedef  (*clang_complete_t)(const char *, const char *, int, int, NSArray*);


