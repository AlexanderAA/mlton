#define _ISOC99_SOURCE
#define _BSD_SOURCE
#define _POSIX_SOURCE

#include "platform.h"

Int Posix_IO_fsync (Fd f) {
	return fsync (f);
}
