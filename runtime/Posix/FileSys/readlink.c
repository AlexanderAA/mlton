#define _ISOC99_SOURCE
#define _BSD_SOURCE
#define _POSIX_C_SOURCE 200112L

#include "platform.h"

Int Posix_FileSys_readlink (NullString p, Pointer b, Int n) {
	return readlink ((char *) p, b, n);
}
