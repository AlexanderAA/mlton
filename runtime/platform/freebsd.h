#include <grp.h>
#include <limits.h>
#include <netdb.h>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <netinet/udp.h>
#include <pwd.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/poll.h>
#include <sys/ptrace.h>
#include <sys/resource.h>
#include <sys/socket.h>
#include <sys/sysctl.h>
#include <sys/times.h>
#include <sys/un.h>
#include <sys/utsname.h>
#include <sys/wait.h>
#include <syslog.h>
#include <termios.h>
#include <ucontext.h>

/* On FreeBSD and OpenBSD the default gmp.h is installed in /usr/include, 
 * but that is version 2.  We want gmp version 4, which the is installed in 
 * /usr/local/include, and is ensured to exist because it is required by the
 * MLton package.
 */
#include "/usr/local/include/gmp.h"

#define HAS_MREMAP FALSE
#define HAS_PTRACE TRUE
#define HAS_SIGALTSTACK TRUE
#define HAS_SPAWN FALSE
#define HAS_TIME_PROFILING TRUE
#define HAS_WEAK 1
#define USE_MMAP TRUE
