/* On FreeBSD and OpenBSD the default gmp.h is installed in /usr/include, 
 * but that is version 2.  We want gmp version 4, which the is installed in 
 * /usr/local/include, and is ensured to exist because it is required by the
 * MLton package.
 */
#include "/usr/local/include/gmp.h"
#include <sys/param.h>
#include <sys/sysctl.h>
#include <sys/mman.h>
#include <sys/resource.h>
#include <sys/times.h>

#include "ptrace.h"
#include "spawn.h"

#define HAS_MREMAP FALSE
#define HAS_SIGALTSTACK TRUE
#define HAS_TIME_PROFILING TRUE
#define HAS_WEAK 1
#define USE_MMAP TRUE
