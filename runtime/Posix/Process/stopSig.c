#include <wait.h>
#include "mlton-posix.h"

Signal Posix_Process_stopSig(Status s) {
	return WSTOPSIG(s);
}
