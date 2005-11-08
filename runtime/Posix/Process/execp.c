#include "platform.h"

Int Posix_Process_execp (Pointer f, Pointer a) {
        char            *file;
        char            *saved;
        char            **args;
        int             n;
        int             result;

        file = (char *) f;
        args = (char **) a;
        n = GC_getArrayLength (a) - 1;
        saved = args[n];
        args[n] = (char *) NULL;
        result = EXECVP (file, args);
        /* execp failed */
        args[n] = saved;
        return result;
}
