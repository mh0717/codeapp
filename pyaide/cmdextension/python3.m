
//
//  pyintepreter.c
//  pyintepreter
//
//  Created by tjuser on 2020/1/21.
//  Copyright © 2020 tjuser. All rights reserved.
//

#import <Foundation/Foundation.h>
//#include <stdio.h>
#include <wchar.h>
#include <Python.h>
#include <pthread.h>
#include <dlfcn.h>

#undef swprintf
//#undef printf
#undef write

pthread_key_t pid_key = 0;




#define MAX_INTEPRETER_COUNT 16
#define INTERPRETER_INIT_COUNT 8

/// 所有python运行时子解释器池子size
static int intepreterSize = 0;
/// 所有python运行时子解释器池子
static PyThreadState* subIntepreters[MAX_INTEPRETER_COUNT];
static int irunning[MAX_INTEPRETER_COUNT];

/// 主解释器
static PyThreadState* main_state = NULL;


//static PyStatus
//pymain_init(const _PyArgv *args)
//{
//    PyStatus status;
//
//    status = _PyRuntime_Initialize();
//    if (_PyStatus_EXCEPTION(status)) {
//        return status;
//    }
//
//    PyPreConfig preconfig;
//    PyPreConfig_InitPythonConfig(&preconfig);
//
//    status = _Py_PreInitializeFromPyArgv(&preconfig, args);
//    if (_PyStatus_EXCEPTION(status)) {
//        return status;
//    }
//
//    PyConfig config;
//    PyConfig_InitPythonConfig(&config);
//
//    /* pass NULL as the config: config is read from command line arguments,
//       environment variables, configuration files */
//    if (args->use_bytes_argv) {
//        status = PyConfig_SetBytesArgv(&config, args->argc, args->bytes_argv);
//    }
//    else {
//        status = PyConfig_SetArgv(&config, args->argc, args->wchar_argv);
//    }
//    if (_PyStatus_EXCEPTION(status)) {
//        goto done;
//    }
//
//    status = Py_InitializeFromConfig(&config);
//    if (_PyStatus_EXCEPTION(status)) {
//        goto done;
//    }
//    status = _PyStatus_OK();
//
//done:
//    PyConfig_Clear(&config);
//    return status;
//}

void initIntepreters(void) {
    if (!Py_IsInitialized()) {
        thread_stdin = stdin;
        thread_stdout = stdout;
        thread_stderr = stderr;
//        char* argv[] = {"python3", "-c", ""};
//        Py_BytesMain(3, argv);
        Py_SetProgramName(L"python3");
//        wchar_t* name[] = {Py_DecodeLocale("python3", NULL), NULL};
////        PySys_SetArgv(1, name);
        Py_InitializeWithName("python3");
        PyEval_InitThreads();
        PyThread_init_thread();
        
//
        
        main_state = PyThreadState_Get();
//        PyEval_ReleaseLock();

        subIntepreters[0] = main_state;
        irunning[0] = 0;
//        PyThreadState* state = PyEval_SaveThread();
        
        
//        PyGILState_STATE gilstate;
//        PyThreadState *mainstate = PyThreadState_Get();
//
//        PyEval_ReleaseThread(mainstate);
//
//        gilstate = PyGILState_Ensure();
//        PyThreadState_Swap(NULL);
//
//        subIntepreters[0] = main_state;
//                irunning[0] = 0;
        
        
        for(int i = 0; i < INTERPRETER_INIT_COUNT; i++) {
            subIntepreters[i] = Py_NewInterpreter();
            irunning[i] = 0;
        }
        intepreterSize = INTERPRETER_INIT_COUNT;
        
        PyThreadState_Swap(main_state);
        PyEval_SaveThread();
//        PyEval_RestoreThread(main_state);
        
        
        
////        PyThreadState_Swap(mainstate);
//        PyGILState_Release(gilstate);
//        PyEval_SaveThread();
//        PyEval_RestoreThread(mainstate);
////        PyEval_SaveThread();
        
        pthread_key_create(&pid_key, NULL);
        
        sleep(1);
    }
}

PyThreadState* genPyIntepreter(void) {
    PyThreadState* idle = NULL;
    for(int i = 0; i < intepreterSize; i++) {
        if (irunning[i] == 0) {
            idle = subIntepreters[i];
            irunning[i] = 1;
            fprintf(thread_stdout, "inteperter: %d\n", i);
            return idle;
        }
    }
    
    return idle;
}

void idleIntepreter(PyThreadState* state) {
    assert(state != NULL);
    for (int i = 0; i < intepreterSize; i++) {
        if (state == subIntepreters[i]) {
            assert(irunning[i] != 0);
            irunning[i] = 0;
        }
    }
}

/// 接收到SIGINT信号后，抛出异常
void onSig(int sig) {
    PyGILState_STATE state = PyGILState_Ensure();
    PyErr_SetInterrupt();
    PyGILState_Release(state);
}

static int
pymain_run_module(const wchar_t *modname, int set_argv0)
{
    PyObject *module, *runpy, *runmodule, *runargs, *result;
    runpy = PyImport_ImportModule("runpy");
    if (runpy == NULL) {
        fprintf(stderr, "Could not import runpy module\n");
        PyErr_Print();
        return -1;
    }
    runmodule = PyObject_GetAttrString(runpy, "_run_module_as_main");
    if (runmodule == NULL) {
        fprintf(stderr, "Could not access runpy._run_module_as_main\n");
        PyErr_Print();
        Py_DECREF(runpy);
        return -1;
    }
    module = PyUnicode_FromWideChar(modname, wcslen(modname));
    if (module == NULL) {
        fprintf(stderr, "Could not convert module name to unicode\n");
        PyErr_Print();
        Py_DECREF(runpy);
        Py_DECREF(runmodule);
        return -1;
    }
    runargs = Py_BuildValue("(Oi)", module, set_argv0);
    if (runargs == NULL) {
        fprintf(stderr,
            "Could not create arguments for runpy._run_module_as_main\n");
        PyErr_Print();
        Py_DECREF(runpy);
        Py_DECREF(runmodule);
        Py_DECREF(module);
        return -1;
    }
    result = PyObject_Call(runmodule, runargs, NULL);
    if (result == NULL) {
        PyErr_Print();
    }
    Py_DECREF(runpy);
    Py_DECREF(runmodule);
    Py_DECREF(module);
    Py_DECREF(runargs);
    if (result == NULL) {
        return -1;
    }
    Py_DECREF(result);
    return 0;
}

int python3_run(int argc, char** argv) {
//    initIntepreters();
    
//    setvbuf(thread_stdout, NULL, _IONBF, 1024);
    
    PyThreadState* context = genPyIntepreter();
    
    if (context == NULL) {
//        printf("没有可运行的Python解释器了，请关闭其它正在运行的Python程序!\n");
        fflush(thread_stdout);
        fprintf(thread_stdout, "没有可运行的Python解释器了，请关闭其它正在运行的Python程序!\n");
        fprintf(thread_stdout, "There is no running Python interpreter, please close other running Python programs!\n");
        fflush(thread_stdout);
        return -1;
    }
    
    signal(SIGINT, &onSig);
    
    pthread_setspecific(pid_key, context);
    
    wchar_t** wargv = NULL;
    if (argc > 1) {
        wargv = (wchar_t**)malloc(sizeof(wchar_t*) * (argc));
        for(int i = 1; i < argc; i++) {
            wargv[i-1] = Py_DecodeLocale(argv[i], 0);
        }
        wargv[argc-1] = NULL;
    }
    
    PyThreadState* cstate = NULL;

    if (_PyThreadState_UncheckedGet() != NULL) {
        cstate = PyEval_SaveThread();
    }
    PyEval_RestoreThread(context);
    
    
//    PyGILState_Ensure();
//    PyThreadState_Swap(context);
    /*if (_PyThreadState_UncheckedGet() != NULL) {
        PyEval_SaveThread();
    }
    PyEval_RestoreThread(context);*/
//    PyThreadState_Swap(context);
//    PyGILState_STATE gstate = PyGILState_Ensure();
//    PyGILState_Release(PyGILState_UNLOCKED);
    
//    PyEval_ReleaseThread(context);
//    PyEval_RestoreThread(context);
    
    
    pthread_cleanup_push(idleIntepreter, context);
    
    
    if (argc > 1 && strcmp(argv[1], "-m") == 0) {
        PySys_SetArgv(argc-2, &wargv[1]);
        pymain_run_module(wargv[1], 1);
        PyErr_Print();
    }
    else if (argc > 1) {
        
        PySys_SetArgv(argc-1, wargv);
        if (strcmp("-u", argv[1]) == 0) {
            char* filePath = argv[2];
            FILE* file = fopen(filePath, "r");
            if (file != NULL) {
                fflush(thread_stdout);
//                fprintf(thread_stdout, "Python3IDE(Python 3.7) running!\n");
                PyRun_SimpleFile(file, filePath);
                PyErr_Print();
//                fprintf(thread_stdout, "Pytho3IDE run end!\n");
                fflush(thread_stdout);
            }
        }
        else if (strcmp("-c", argv[1]) == 0) {
            fflush(thread_stdout);
//            fprintf(thread_stdout, "Python3IDE(Python 3.7) running!\n");
            PyRun_SimpleString(argv[2]);
            PyErr_Print();
//            fprintf(thread_stdout, "Pytho3IDE run end!\n");
            fflush(thread_stdout);
        } else {
            char* filePath = argv[1];
            FILE* file = fopen(filePath, "r");
            if (file != NULL) {
                fflush(thread_stdout);
//                fprintf(thread_stdout, "Python3IDE(Python 3.7) running!\n");
                PyRun_SimpleFile(file, filePath);
                PyErr_Print();
//                fprintf(thread_stdout, "Pytho3IDE run end!\n");
                fflush(thread_stdout);
            }
        }
        
    }
    else {
        const char* header = "Python 3.7.1 \nType \"help\", \"copyright\", \"credits\" or \"license\" for more information.\n";
        fprintf(thread_stdout, header, strlen(header));
        PyRun_InteractiveLoop(thread_stdin, "<stdin>");
    }
    /*
    /// 清理运行时产生的变量
    PyObject * poMainModule = PyImport_AddModule("__main__");
    PyObject * poAttrList = PyObject_Dir(poMainModule);
    PyObject * poAttrIter = PyObject_GetIter(poAttrList);
    PyObject * poAttrName;
    while ((poAttrName = PyIter_Next(poAttrIter)) != NULL)
    {
        const char* cattname = PyUnicode_AsUTF8(poAttrName);
        NSString* attname = [NSString stringWithUTF8String:cattname];

        // Make sure we don't delete any private objects.
        if (![attname hasPrefix:@"__"] || ![attname hasSuffix:@"__"]) {
//                    PyObject * poAttr = PyObject_GetAttr(poMainModule, poAttrName);
            PyObject_SetAttr(poMainModule, poAttrName, NULL);
//                    // Make sure we don't delete any module objects.
//                    if (poAttr && poAttr->ob_type != poMainModule->ob_type)
//                        PyObject_SetAttr(poMainModule, poAttrName, NULL);

//                    Py_DecRef(poAttr);
        }

        Py_DecRef(poAttrName);
    }
    Py_DecRef(poAttrIter);
    Py_DecRef(poAttrList);
    
    
    /// 清理导入的模块(处于文档目录的，由用户编写的)
    /// 用户编写的模块下次运行可能会更改，不能缓存
//    PyObject *modules = PyImport_GetModuleDict();
    PyObject *modules = PySys_GetObject("modules");
    PyObject *key, *value;
    PyObject *iterator = PyObject_GetIter(modules);
    PyObject* delList = PyList_New(0);
    if (iterator == NULL) {
        PyErr_Clear();
    }
    else {
        while ((key = PyIter_Next(iterator))) {
            value = PyObject_GetItem(modules, key);
            if (value == NULL) {
                PyErr_Clear();
                continue;
            }
            
            const char* nname  = PyModule_GetName(value);
//            NSLog(@"name: %s", nname);
            
            
            const char* path = PyModule_GetFilename(value);
            if (path == NULL) {
                Py_DECREF(value);
                Py_DECREF(key);
                continue;
            };
            NSString* opath = [NSString stringWithFormat:@"%s", path];
//            if ([opath containsString:documentsDirectory]) {
//                PyList_Append(delList, key);
//            }
            
            if (PyObject_HasAttrString(value, "__clean_module__")) {
                PyList_Append(delList, key);
            }
            
            Py_DECREF(value);
            Py_DECREF(key);
        }
        if (PyErr_Occurred()) {
            PyErr_Clear();
        }
        Py_DECREF(iterator);
    }
    
    if (delList != NULL) {
        Py_ssize_t i, n;
        n = PyList_GET_SIZE(delList);
        for (i = 0; i < n; i++) {
            PyObject *key = PyList_GET_ITEM(delList, i);
            PyObject_DelItem(modules, key);
        }
        Py_DECREF(delList);
        delList = NULL;
    }*/


    PyEval_SaveThread();

    if (cstate != NULL) {
        PyEval_RestoreThread(cstate);
    }

//    PyEval_SaveThread();
//    PyGILState_Release(gstate);
    
    
    
//    PyEval_SaveThread();
//    PyThreadState_Swap(NULL);
    pthread_cleanup_pop(1);
    
    return 0;
}












int python_sub_main(int argc, char** argv) {
    PyThreadState* _mainState = NULL;
    if (!Py_IsInitialized()) {
        Py_SetProgramName(L"python_sub");
        
//        PyImport_AppendInittab("__ios_io", PyInit_ios_io);
        
        Py_Initialize();
        PyEval_InitThreads();
        
        _mainState = PyThreadState_Get();
    }
    
    if (_PyThreadState_UncheckedGet() == NULL) {
        PyEval_RestoreThread(_mainState);
    }
    
    wchar_t** wargv = NULL;
    if (argc > 1) {
        wargv = (wchar_t**)malloc(sizeof(wchar_t*) * (argc));
        for(int i = 1; i < argc; i++) {
            wargv[i-1] = Py_DecodeLocale(argv[i], 0);
        }
        wargv[argc-1] = NULL;
    }
    
    
//    static NSString* iostr = nil;
//    if (iostr == nil) {
//        const char* redirect_io_py = getenv("redirect_io_py");
//        iostr = [NSString stringWithContentsOfFile:[NSString stringWithUTF8String:redirect_io_py] encoding:NSUTF8StringEncoding error:nil];
//    }
//    PyRun_SimpleString(iostr.UTF8String);
    
//    NSString* odir = nil;
//    if (argc > 1) {
//        NSString* opath = [NSString stringWithUTF8String:argv[1]];
//        odir = [opath stringByDeletingLastPathComponent];
//        chdir(odir.UTF8String);
//
//        NSString* addPathSource = [NSString stringWithFormat:@"sys.path.append(\'%@\')", odir];
//        PyRun_SimpleString(addPathSource.UTF8String);
//    }
    
    
    
    if (strcmp(argv[1], "-m") == 0) {
        PySys_SetArgv(argc-2, &wargv[1]);
        pymain_run_module(wargv[1], 1);
    }
    else if (argc > 1) {
        PySys_SetArgv(argc-1, wargv);
        char* filePath = argv[1];
        FILE* file = fopen(filePath, "r");
        if (file != NULL) {
            PyRun_SimpleFile(file, filePath);
        }
    }
    
//    if (odir != nil && context->intepreter->interp != NULL) {
//        NSString* removePathSource = [NSString stringWithFormat:@"sys.path.remove(\'%@\')", odir];
//        PyRun_SimpleString(removePathSource.UTF8String);
//    }
    if (_PyThreadState_UncheckedGet() == NULL) {
        PyEval_RestoreThread(_mainState);
    }
    
    return 0;
}


PyThreadState* _completionState = NULL;

NSString* pycompleteCode(NSString* code, NSString* path, int index, BOOL getdef, int vid, NSString* uid) {
    initIntepreters();
    
    if (_completionState == NULL) {
        _completionState = genPyIntepreter();
    }

    if (_completionState == NULL) {return @"";}

//    PyThreadState* cstate = NULL;
//
//    if (_PyThreadState_UncheckedGet() != NULL) {
//        cstate = PyEval_SaveThread();
//    }
//    PyEval_RestoreThread(_completionState);
    
    
    
    if (_PyThreadState_UncheckedGet() != NULL) {
        PyEval_SaveThread();
    }
    PyThreadState_Swap(_completionState);
    PyGILState_STATE gstate = PyGILState_Ensure();
    
    
    NSString* result = @"";
    NSString* errResult = @"";
    
    PyObject* cmpModule = PyImport_ImportModule("_ccmp");
    if (cmpModule == NULL) return errResult;
    PyObject* cmpFunc = PyObject_GetAttrString(cmpModule, "completeCode");
//    PyObject* cmpFunc = PyObject_GetAttrString(cmpModule, "test");
    if (cmpFunc == NULL) return errResult;
    PyObject* pResult = PyObject_CallFunction(cmpFunc, "ssiiis", [code UTF8String], [path UTF8String],index, 1, vid, [uid UTF8String]);
//    printf("%s", [code UTF8String]);
//    PyObject* pResult = PyObject_CallFunction(cmpFunc, NULL);
    if (pResult == NULL) return errResult;
    
    const char* strResult = PyUnicode_AsUTF8(pResult);
    result = [[NSString alloc] initWithCString:strResult encoding:NSUTF8StringEncoding];
    
    
//    PyEval_SaveThread();
//
//    if (cstate != NULL) {
//        PyEval_RestoreThread(cstate);
//    }
    
    PyGILState_Release(gstate);
    
    return result;
}

//#undef write
//#undef fwrite
//#undef read
//#undef fread
//static ssize_t (*origin_write)(int fildes, const void *buf, size_t nbyte) = NULL;
//static size_t (*origin_fwrite)(const void *restrict ptr, size_t size, size_t nitems, FILE *restrict stream) = NULL;
//
//static ssize_t (*origin_read)(int, void *, size_t) = NULL;
//static size_t  (*origin_fread)(void * __restrict __ptr, size_t __size, size_t __nitems, FILE * __restrict __stream) = NULL;
//
//__attribute__((visibility("default"))) __attribute__((used))
//ssize_t write(int fildes, const void *buf, size_t nbyte) {
//    if (origin_write == NULL) {
//        void* libsystem_b_handle = dlopen("/usr/lib/libSystem.B.dylib", RTLD_LAZY);
//        origin_write = dlsym(libsystem_b_handle, "write");
//    }
//
//    if (thread_stdout == NULL) thread_stdout = stdout;
//    if (thread_stderr == NULL) thread_stderr = stderr;
//    if (fildes == STDOUT_FILENO) return origin_write(fileno(thread_stdout), buf, nbyte);
//    if (fildes == STDERR_FILENO) return origin_write(fileno(thread_stderr), buf, nbyte);
//    return origin_write(fildes, buf, nbyte);
//}
//
//__attribute__((visibility("default"))) __attribute__((used))
//size_t fwrite(const void *restrict ptr, size_t size, size_t nitems, FILE *restrict stream) {
//    if (origin_fwrite == NULL) {
//        void* libsystem_b_handle = dlopen("/usr/lib/libSystem.B.dylib", RTLD_LAZY);
//        origin_fwrite = dlsym(libsystem_b_handle, "fwrite");
//    }
//    if (thread_stdout == NULL) thread_stdout = stdout;
//    if (thread_stderr == NULL) thread_stderr = stderr;
//    if (fileno(stream) == STDOUT_FILENO) return origin_fwrite(ptr, size, nitems, thread_stdout);
//    // iOS, debug:
//    if (fileno(stream) == STDERR_FILENO) return origin_fwrite(ptr, size, nitems, thread_stderr);
//    return origin_fwrite(ptr, size, nitems, stream);
//}
//
//__attribute__((visibility("default"))) __attribute__((used))
//ssize_t read(int fildes, void *buf, size_t nbyte) {
//    if (origin_read == NULL) {
//        void* libsystem_b_handle = dlopen("/usr/lib/libSystem.B.dylib", RTLD_LAZY);
//        origin_read = dlsym(libsystem_b_handle, "read");
//    }
//
//    if (thread_stdin == NULL) thread_stdin = stdin;
//    if (fildes == STDIN_FILENO) return origin_read(fileno(thread_stdout), buf, nbyte);
//    return origin_read(fildes, buf, nbyte);
//}
//
//__attribute__((visibility("default"))) __attribute__((used))
//size_t fread(void * __restrict ptr, size_t size, size_t nitems, FILE * __restrict stream) {
//    if (origin_fread == NULL) {
//        void* libsystem_b_handle = dlopen("/usr/lib/libSystem.B.dylib", RTLD_LAZY);
//        origin_fread = dlsym(libsystem_b_handle, "fread");
//    }
//
//    if (thread_stdin == NULL) thread_stdin = stdin;
//    if (fileno(stream) == STDIN_FILENO) return origin_fread(ptr, size, nitems, thread_stdin);
//    return origin_fread(ptr, size, nitems, stream);
//}
