#if (defined (__CYGWIN__))
#include <process.h>
#include "gc.h"
#include "mlton-basis.h"

Int MLton_Process_spawnp (NullString p, Pointer a) {
	char		*path;
	char		*asaved;
	char 		**args;
	int             an;
	int 		result;

	path = (char *) p;
	args = (char **) a;
	an = GC_arrayNumElements(a) - 1;
	asaved = args[an];
	args[an] = (char *) NULL;
	result = spawnvp(0, path, (const char * const *)args);
	args[an] = asaved;
	return result;
}
#endif
