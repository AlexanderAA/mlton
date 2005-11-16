/* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

#ifndef _MLTON_PLATFORM_H_
#define _MLTON_PLATFORM_H_

#include "cenv.h"
#include "util.h"
#include "gc.h"

#if (defined (__APPLE_CC__))
#define __Darwin__
#endif

#if (defined (__CYGWIN__))
#include "platform/cygwin.h"
#elif (defined (__Darwin__))
#include "platform/darwin.h"
#elif (defined (__FreeBSD__))
#include "platform/freebsd.h"
#elif (defined (__linux__))
#include "platform/linux.h"
#elif (defined (__MINGW32__))
#include "platform/mingw.h"
#elif (defined (__NetBSD__))
#include "platform/netbsd.h"
#elif (defined (__OpenBSD__))
#include "platform/openbsd.h"
#elif (defined (__sun__))
#include "platform/solaris.h"
#else
#error unknown platform
#endif

#ifndef MLton_Platform_OS_host
#error MLton_Platform_OS_host not defined
#endif

#ifndef HAS_FPCLASSIFY
#error HAS_FPCLASSIFY not defined
#endif

#ifndef HAS_FEROUND
#error HAS_FEROUND not defined
#endif

#ifndef HAS_PTRACE
#error HAS_PTRACE not defined
#endif

#ifndef HAS_REMAP
#error HAS_REMAP not defined
#endif

#ifndef HAS_SIGALTSTACK
#error HAS_SIGALTSTACK not defined
#endif

#ifndef HAS_SIGNBIT
#error HAS_SIGNBIT not defined
#endif

#ifndef HAS_SPAWN
#error HAS_SPAWN not defined
#endif

#ifndef HAS_TIME_PROFILING
#error HAS_TIME_PROFILING not defined
#endif

#ifndef EXECVP
#define EXECVP execvp
#endif

#ifndef EXECVE
#define EXECVE execve
#endif

#if not HAS_FEROUND
#ifndef FE_TONEAREST
#define FE_TONEAREST 0
#endif
#ifndef FE_DOWNWARD
#define FE_DOWNWARD 1
#endif
#ifndef FE_UPWARD
#define FE_UPWARD 2
#endif
#ifndef FE_TOWARDZERO
#define FE_TOWARDZERO 3
#endif
#endif

#if not HAS_FPCLASSIFY
#ifndef FP_INFINITE
#define FP_INFINITE 1
#endif
#ifndef FP_NAN
#define FP_NAN 0
#endif
#ifndef FP_NORMAL
#define FP_NORMAL 4
#endif
#ifndef FP_SUBNORMAL
#define FP_SUBNORMAL 3
#endif
#ifndef FP_ZERO
#define FP_ZERO 2
#endif
#endif

#ifndef SPAWN_MODE
#define SPAWN_MODE 0
#endif

#include "types.h"

/* ---------------------------------------------------------------- */
/*                        Runtime Init/Exit                         */
/* ---------------------------------------------------------------- */

void MLton_init (int argc, char **argv, GC_state s);
void MLton_exit (GC_state s, Int status) __attribute__ ((noreturn));

/* ---------------------------------------------------------------- */
/*                        Utility libraries                         */
/* ---------------------------------------------------------------- */

int mkdir2 (const char *pathname, mode_t mode);

/* ---------------------------------------------------------------- */
/*                        Garbage Collector                         */
/* ---------------------------------------------------------------- */

/* ------------------------------------------------- */
/*                Virtual Memory                     */
/* ------------------------------------------------- */

/* GC_displayMem displays the virtual memory mapping to stdout.  
 * It is used to diagnose memory problems. 
 */
void GC_displayMem (void);

void *GC_mmapAnon (void *start, size_t length);
void *GC_mmapAnon_safe (void *start, size_t length);
void *GC_mmapAnon_safe_protect (void *start, size_t length, 
                                size_t dead_low, size_t dead_high);
void *GC_mremap (void *start, size_t oldLength, size_t newLength);
void GC_release (void *base, size_t length);
void GC_decommit (void *base, size_t length);

size_t GC_pageSize (void);
size_t GC_totalRam (void);
size_t GC_availRam (void);

void GC_setCygwinUseMmap (bool b);

/* ------------------------------------------------- */
/*                Text Segment                       */
/* ------------------------------------------------- */

void *GC_getTextEnd (void);
void *GC_getTextStart (void);

/* ------------------------------------------------- */
/*                SigProf Handler                    */
/* ------------------------------------------------- */

void GC_setSigProfHandler (struct sigaction *sa);

/* ---------------------------------------------------------------- */
/*                         MLton libraries                          */
/* ---------------------------------------------------------------- */

/* ------------------------------------------------- */
/*                    CommandLine                    */
/* ------------------------------------------------- */

/* These are initialized by MLton_init. */
extern Int CommandLine_argc;
extern CstringArray CommandLine_argv;
extern Cstring CommandLine_commandName;

/* ------------------------------------------------- */
/*                       Date                        */
/* ------------------------------------------------- */

Int Date_Tm_sec (void);
Int Date_Tm_min (void);
Int Date_Tm_hour (void);
Int Date_Tm_mday (void);
Int Date_Tm_mon (void);
Int Date_Tm_year (void);
Int Date_Tm_wday (void);
Int Date_Tm_yday (void);
Int Date_Tm_isdst (void);
void Date_Tm_setSec (Int x);
void Date_Tm_setMin (Int x);
void Date_Tm_setHour (Int x);
void Date_Tm_setMday (Int x);
void Date_Tm_setMon (Int x);
void Date_Tm_setYear (Int x);
void Date_Tm_setWday (Int x);
void Date_Tm_setYday (Int x);
void Date_Tm_setIsdst (Int x);

Cstring Date_ascTime (void);
void Date_gmTime (Pointer p);
Int Date_localOffset (void);
void Date_localTime (Pointer p);
Int Date_mkTime (void);
Int Date_strfTime (Pointer buf, Int n, Pointer fmt);

/* ------------------------------------------------- */
/*                       Debug                       */
/* ------------------------------------------------- */

void Debug_enter (Pointer name);
void Debug_leave (Pointer name);

/* ------------------------------------------------- */
/*                     IEEEReal                      */
/* ------------------------------------------------- */

#define FE_NOSUPPORT -1
/* Can't handle undefined rounding modes with code like the following.
 *  #ifndef FE_TONEAREST
 *  #define FE_TONEAREST FE_NOSUPPORT
 *  #endif
 * On some platforms, FE_* are defined via an enum, not the preprocessor,
 * and hence don't show up as #defined.  In that case, the above code 
 * overwrites them.
 */
void IEEEReal_setRoundingMode (Int mode);
Int IEEEReal_getRoundingMode (void);

/* ------------------------------------------------- */
/*                      IntInf                       */
/* ------------------------------------------------- */

/* All of these routines modify the frontier in gcState.  They assume that 
 * there are bytes bytes free, and allocate an array to store the result
 * at the current frontier position.
 * Immediately after the bytesArg, they take a labelIndex arg.  This is an index
 * into the array used for allocation profiling, and the appropriate element
 * is incremented by the amount that the function moves the frontier.
 */
Pointer IntInf_add (Pointer lhs, Pointer rhs, size_t bytes);
Pointer IntInf_andb (Pointer lhs, Pointer rhs, size_t bytes);
Pointer IntInf_arshift (Pointer arg, uint shift, size_t bytes);
Pointer IntInf_gcd (Pointer lhs, Pointer rhs, size_t bytes);
Pointer IntInf_lshift (Pointer arg, uint shift, size_t bytes);
Pointer IntInf_mul (Pointer lhs, Pointer rhs, size_t bytes);
Pointer IntInf_neg (Pointer arg, size_t bytes);
Pointer IntInf_notb (Pointer arg, size_t bytes);
Pointer IntInf_orb (Pointer lhs, Pointer rhs, size_t bytes);
Pointer IntInf_quot (Pointer num, Pointer den, size_t bytes);
Pointer IntInf_rem (Pointer num, Pointer den, size_t bytes);
Pointer IntInf_sub (Pointer lhs, Pointer rhs, size_t bytes);
Pointer IntInf_toString (Pointer arg, int base, size_t bytes);
Pointer IntInf_xorb (Pointer lhs, Pointer rhs, size_t bytes);

Word IntInf_smallMul (Word lhs, Word rhs, Pointer carry);
Int IntInf_compare (Pointer lhs, Pointer rhs);
Bool IntInf_equal (Pointer lhs, Pointer rhs);

/* ------------------------------------------------- */
/*                      Itimer                       */
/* ------------------------------------------------- */

#define Itimer_prof ITIMER_PROF
#define Itimer_real ITIMER_REAL
#define Itimer_virtual ITIMER_VIRTUAL

void Itimer_set (Int which,
                        Int interval_tv_sec, Int interval_tv_usec,
                        Int value_tv_sec, Int value_tv_usec);

/* ------------------------------------------------- */
/*                       MLton                       */
/* ------------------------------------------------- */

void MLton_allocTooLarge (void) __attribute__ ((noreturn));
/* print a bug message and exit (2) */
void MLton_bug (Pointer msg) __attribute__ ((noreturn));

/* ---------------------------------- */
/*           MLton.Platform           */
/* ---------------------------------- */

#define MLton_Platform_Arch_bigendian isBigEndian()

#if (defined (__alpha__))
#define MLton_Platform_Arch_host "alpha"
#elif (defined (__x86_64__))
#define MLton_Platform_Arch_host "amd64"
#elif (defined (__arm__))
#define MLton_Platform_Arch_host "arm"
#elif (defined (__hppa__))
#define MLton_Platform_Arch_host "hppa"
#elif (defined (__ia64__))
#define MLton_Platform_Arch_host "ia64"
#elif (defined (__m68k__))
#define MLton_Platform_Arch_host "m68k"
#elif (defined (__mips__))
#define MLton_Platform_Arch_host "mips"
#elif (defined (__ppc__)) || (defined (__powerpc__))
#define MLton_Platform_Arch_host "powerpc"
#elif (defined (__s390__))
#define MLton_Platform_Arch_host "s390"
#elif (defined (__sparc__))
#define MLton_Platform_Arch_host "sparc"
#elif (defined (__i386__))
#define MLton_Platform_Arch_host "x86"
#else
#error MLton_Platform_Arch_host not defined
#endif

extern Bool MLton_Platform_CygwinUseMmap;

/* ---------------------------------- */
/*           MLton.Process            */
/* ---------------------------------- */

Pid MLton_Process_cwait (Pid p, Pointer s);
Int MLton_Process_spawne (Pointer p, Pointer a, Pointer e);
Int MLton_Process_spawnp (Pointer p, Pointer a);

/* ---------------------------------- */
/*            MLton.Rlimit            */
/* ---------------------------------- */

#define RLIMIT_BOGUS 0xFFFFFFFF

#ifndef RLIMIT_RSS
#define RLIMIT_RSS RLIMIT_BOGUS
#endif
#ifndef RLIMIT_NPROC
#define RLIMIT_NPROC RLIMIT_BOGUS
#endif
#ifndef RLIMIT_MEMLOCK
#define RLIMIT_MEMLOCK RLIMIT_BOGUS
#endif

#define MLton_Rlimit_cpuTime RLIMIT_CPU
#define MLton_Rlimit_coreFileSize RLIMIT_CORE
#define MLton_Rlimit_dataSize RLIMIT_DATA
#define MLton_Rlimit_fileSize RLIMIT_FSIZE
#define MLton_Rlimit_lockedInMemorySize RLIMIT_MEMLOCK
#define MLton_Rlimit_numFiles RLIMIT_NOFILE
#define MLton_Rlimit_numProcesses RLIMIT_NPROC
#define MLton_Rlimit_residentSetSize RLIMIT_RSS
#define MLton_Rlimit_stackSize RLIMIT_STACK
#if (defined (RLIMIT_DATA))
#define MLton_Rlimit_virtualMemorySize RLIMIT_DATA
#elif (defined (RLIMIT_AS))
#define MLton_Rlimit_virtualMemorySize RLIMIT_AS
#else
#error MLton_Rlimit_virtualMemorySize not defined
#endif

#define MLton_Rlimit_infinity RLIM_INFINITY

Int MLton_Rlimit_get (Resource r);
Rlimit MLton_Rlimit_getHard (void);
Rlimit MLton_Rlimit_getSoft (void);
Int MLton_Rlimit_set (Resource r, Rlimit hard, Rlimit soft);

/* ---------------------------------- */
/*           MLton.Rusage             */
/* ---------------------------------- */

Int MLton_Rusage_self_utime_sec (void);
Int MLton_Rusage_self_utime_usec (void);
Int MLton_Rusage_self_stime_sec (void);
Int MLton_Rusage_self_stime_usec (void);
Int MLton_Rusage_children_utime_sec (void);
Int MLton_Rusage_children_utime_usec (void);
Int MLton_Rusage_children_stime_sec (void);
Int MLton_Rusage_children_stime_usec (void);
Int MLton_Rusage_gc_utime_sec (void);
Int MLton_Rusage_gc_utime_usec (void);
Int MLton_Rusage_gc_stime_sec (void);
Int MLton_Rusage_gc_stime_usec (void);
void MLton_Rusage_ru (GC_state s);

/* ------------------------------------------------- */
/*                        Net                        */
/* ------------------------------------------------- */

Int Net_htonl (Int i);
Int Net_ntohl (Int i);
Int Net_htons (Int i);
Int Net_ntohs (Int i);
#define NetHostDB_inAddrLen sizeof (struct in_addr)
#define NetHostDB_INADDR_ANY INADDR_ANY
Cstring NetHostDB_Entry_name(void);
Int NetHostDB_Entry_numAliases(void);
Cstring NetHostDB_Entry_aliasesN(Int n);
Int NetHostDB_Entry_addrType(void);
Int NetHostDB_Entry_length(void);
Int NetHostDB_Entry_numAddrs(void);
void NetHostDB_Entry_addrsN(Int n, Pointer addr);
Bool NetHostDB_getByAddress(Pointer addr, Int len);
Bool NetHostDB_getByName(Cstring name);
Int NetHostDB_getHostName(Pointer buf, Int len);
Cstring NetProtDB_Entry_name(void);
Int NetProtDB_Entry_numAliases(void);
Cstring NetProtDB_Entry_aliasesN(Int n);
Int NetProtDB_Entry_protocol(void);
Int NetProtDB_getByName(Cstring name);
Int NetProtDB_getByNumber(Int proto);
Cstring NetServDB_Entry_name(void);
Int NetServDB_Entry_numAliases(void);
Cstring NetServDB_Entry_aliasesN(Int n);
Int NetServDB_Entry_port(void);
Cstring NetServDB_Entry_protocol(void);
Int NetServDB_getByName(Cstring name, Cstring proto);
Int NetServDB_getByNameNull(Cstring name);
Int NetServDB_getByPort(Int port, Cstring proto);
Int NetServDB_getByPortNull(Int port);

/* ------------------------------------------------- */
/*                      OS                           */
/* ------------------------------------------------- */

#define OS_IO_POLLIN POLLIN
#define OS_IO_POLLPRI POLLPRI
#define OS_IO_POLLOUT POLLOUT

Cstring OS_FileSys_tmpnam (void);
Int OS_IO_poll (Int *fds, Word *eventss, Int n, Int timeout, Word *reventss);

/* ------------------------------------------------- */
/*                     PackReal                      */
/* ------------------------------------------------- */

Real32 PackReal32_subVec (Pointer v, Int offset);
Real32 PackReal32_subVecRev (Pointer v, Int offset);
Real64 PackReal64_subVec (Pointer v, Int offset);
Real64 PackReal64_subVecRev (Pointer v, Int offset);
void PackReal32_update (Pointer a, Int offset, Real32 r);
void PackReal32_updateRev (Pointer a, Int offset, Real32 r);
void PackReal64_update (Pointer a, Int offset, Real64 r);
void PackReal64_updateRev (Pointer a, Int offset, Real64 r);

/* ------------------------------------------------- */
/*                       Posix                       */
/* ------------------------------------------------- */

/* ---------------------------------- */
/*            Posix.Error             */
/* ---------------------------------- */

void Posix_Error_clearErrno (void);
int Posix_Error_getErrno (void);
Cstring Posix_Error_strerror (Int n);

#define Posix_Error_acces EACCES
#define Posix_Error_again EAGAIN
#define Posix_Error_badf EBADF
#ifndef EBADMSG
#define EBADMSG 0
#endif
#define Posix_Error_badmsg EBADMSG
#define Posix_Error_busy EBUSY
#ifndef ECANCELED
#define ECANCELED 0
#endif
#define Posix_Error_canceled ECANCELED
#define Posix_Error_child ECHILD
#define Posix_Error_deadlk EDEADLK
#define Posix_Error_dom EDOM
#define Posix_Error_exist EEXIST
#define Posix_Error_fault EFAULT
#define Posix_Error_fbig EFBIG
#define Posix_Error_inprogress EINPROGRESS
#define Posix_Error_intr EINTR
#define Posix_Error_inval EINVAL
#define Posix_Error_io EIO
#define Posix_Error_isdir EISDIR
#define Posix_Error_loop ELOOP
#define Posix_Error_mfile EMFILE
#define Posix_Error_mlink EMLINK
#define Posix_Error_msgsize EMSGSIZE
#define Posix_Error_nametoolong ENAMETOOLONG
#define Posix_Error_nfile ENFILE
#define Posix_Error_nodev ENODEV
#define Posix_Error_noent ENOENT
#define Posix_Error_noexec ENOEXEC
#define Posix_Error_nolck ENOLCK
#define Posix_Error_nomem ENOMEM
#define Posix_Error_nospc ENOSPC
#define Posix_Error_nosys ENOSYS
#define Posix_Error_notdir ENOTDIR
#define Posix_Error_notempty ENOTEMPTY
#ifndef ENOTSUP
#define ENOTSUP 0
#endif
#define Posix_Error_notsup ENOTSUP
#define Posix_Error_notty ENOTTY
#define Posix_Error_nxio ENXIO
#define Posix_Error_perm EPERM
#define Posix_Error_pipe EPIPE
#define Posix_Error_range ERANGE
#define Posix_Error_rofs EROFS
#define Posix_Error_spipe ESPIPE
#define Posix_Error_srch ESRCH
#define Posix_Error_toobig E2BIG
#define Posix_Error_xdev EXDEV

/* ---------------------------------- */
/*           Posix.FileSys            */
/* ---------------------------------- */

#define Posix_FileSys_S_ifsock S_IFSOCK
#define Posix_FileSys_S_iflnk S_IFLNK
#define Posix_FileSys_S_ifreg S_IFREG
#define Posix_FileSys_S_ifblk S_IFBLK
#define Posix_FileSys_S_ifdir S_IFDIR
#define Posix_FileSys_S_ifchr S_IFCHR
#define Posix_FileSys_S_ififo S_IFIFO

#ifndef O_BINARY
#define O_BINARY 0
#endif

#ifndef O_TEXT
#define O_TEXT 0
#endif

#define Posix_FileSys_O_append O_APPEND
#define Posix_FileSys_O_binary O_BINARY
#define Posix_FileSys_O_creat O_CREAT
#define Posix_FileSys_O_excl O_EXCL
#define Posix_FileSys_O_noctty O_NOCTTY
#define Posix_FileSys_O_nonblock O_NONBLOCK
#if (defined (O_SYNC))
#define Posix_FileSys_O_sync O_SYNC
#else
#define Posix_FileSys_O_sync 0
#endif
#define Posix_FileSys_O_text O_TEXT
#define Posix_FileSys_O_trunc O_TRUNC
#define Posix_FileSys_o_rdonly O_RDONLY
#define Posix_FileSys_o_wronly O_WRONLY
#define Posix_FileSys_o_rdwr O_RDWR
#define Posix_FileSys_S_irwxu S_IRWXU
#define Posix_FileSys_S_irusr S_IRUSR
#define Posix_FileSys_S_iwusr S_IWUSR
#define Posix_FileSys_S_ixusr S_IXUSR
#define Posix_FileSys_S_irwxg S_IRWXG
#define Posix_FileSys_S_irgrp S_IRGRP
#define Posix_FileSys_S_iwgrp S_IWGRP
#define Posix_FileSys_S_ixgrp S_IXGRP
#define Posix_FileSys_S_irwxo S_IRWXO
#define Posix_FileSys_S_iroth S_IROTH
#define Posix_FileSys_S_iwoth S_IWOTH
#define Posix_FileSys_S_ixoth S_IXOTH
#define Posix_FileSys_S_isuid S_ISUID
#define Posix_FileSys_S_isgid S_ISGID

#define Posix_FileSys_R_OK R_OK
#define Posix_FileSys_W_OK W_OK
#define Posix_FileSys_X_OK X_OK
#define Posix_FileSys_F_OK F_OK

/* used by pathconf and fpathconf */
#define Posix_FileSys_CHOWN_RESTRICTED _PC_CHOWN_RESTRICTED
#define Posix_FileSys_LINK_MAX _PC_LINK_MAX
#define Posix_FileSys_MAX_CANON _PC_MAX_CANON
#define Posix_FileSys_MAX_INPUT _PC_MAX_INPUT
#define Posix_FileSys_NAME_MAX _PC_NAME_MAX
#define Posix_FileSys_NO_TRUNC _PC_NO_TRUNC
#define Posix_FileSys_PATH_MAX _PC_PATH_MAX
#define Posix_FileSys_PIPE_BUF _PC_PIPE_BUF
#define Posix_FileSys_VDISABLE _PC_VDISABLE

#if (defined (_PC_SYNC_IO))
#define Posix_FileSys_SYNC_IO _PC_SYNC_IO
#else
#define Posix_FileSys_SYNC_IO 0
#endif

#if (defined (_PC_ASYNC_IO))
#define Posix_FileSys_ASYNC_IO _PC_ASYNC_IO
#else
#define Posix_FileSys_ASYNC_IO 0
#define Posix_FileSys_PRIO_IO 0
#endif

#if (defined (_PC_PRIO_IO))
#define Posix_FileSys_PRIO_IO _PC_PRIO_IO
#else
#define Posix_FileSys_PRIO_IO 0
#endif

Int Posix_FileSys_Dirstream_closedir (Cpointer d);
Cpointer Posix_FileSys_Dirstream_opendir (Pointer p);
Cstring Posix_FileSys_Dirstream_readdir (Cpointer d);
void Posix_FileSys_Dirstream_rewinddir (Cpointer p);

Int Posix_FileSys_Stat_fstat (Fd f);
Int Posix_FileSys_Stat_lstat (Pointer f);
Int Posix_FileSys_Stat_stat (Pointer f);
Word Posix_FileSys_Stat_dev (void);
Int Posix_FileSys_Stat_ino (void);
Word Posix_FileSys_Stat_mode (void);
Int Posix_FileSys_Stat_nlink (void);
Word Posix_FileSys_Stat_uid (void);
Word Posix_FileSys_Stat_gid (void);
Word Posix_FileSys_Stat_rdev (void);
Position Posix_FileSys_Stat_size (void);
Int Posix_FileSys_Stat_atime (void);
Int Posix_FileSys_Stat_mtime (void);
Int Posix_FileSys_Stat_ctime (void);

void Posix_FileSys_Utimbuf_setActime (Int x);
void Posix_FileSys_Utimbuf_setModTime (Int x);
Int Posix_FileSys_Utimbuf_utime (Pointer s);

Int Posix_FileSys_access (Pointer f, Word w);
Int Posix_FileSys_chdir(Pointer p);
Int Posix_FileSys_chmod (Pointer p, Mode m);
Int Posix_FileSys_chown (Pointer p, Uid u, Gid g);
Int Posix_FileSys_fchmod (Fd f, Mode m);
Int Posix_FileSys_fchown (Fd f, Uid u, Gid g);
Int Posix_FileSys_fpathconf (Fd f, Int n);
Int Posix_FileSys_ftruncate (Fd f, Position n);
Cstring Posix_FileSys_getcwd (Pointer buf, Size n);
Int Posix_FileSys_link (Pointer p1, Pointer p2);
Int Posix_FileSys_mkdir (Pointer p, Word w);
Int Posix_FileSys_mkfifo (Pointer p, Word w);
Int Posix_FileSys_open (Pointer p, Word w, Mode m);
Int Posix_FileSys_pathconf (Pointer p, Int n);
Int Posix_FileSys_readlink (Pointer p, Pointer b, Int);
Int Posix_FileSys_rename (Pointer p1, Pointer p2);
Int Posix_FileSys_rmdir (Pointer p);
Int Posix_FileSys_symlink (Pointer p1, Pointer p2);
Word Posix_FileSys_umask (Word w);
Word Posix_FileSys_unlink (Pointer p);

Bool Posix_FileSys_ST_isDir (Word w);
Bool Posix_FileSys_ST_isChr (Word w);
Bool Posix_FileSys_ST_isBlk (Word w);
Bool Posix_FileSys_ST_isReg (Word w);
Bool Posix_FileSys_ST_isFIFO (Word w);
Bool Posix_FileSys_ST_isLink (Word w);
Bool Posix_FileSys_ST_isSock (Word w);

/* ---------------------------------- */
/*              Posix.IO              */
/* ---------------------------------- */

#define Posix_IO_F_DUPFD F_DUPFD
#define Posix_IO_F_GETFD F_GETFD
#define Posix_IO_F_SETFD F_SETFD
#define Posix_IO_F_GETFL F_GETFL
#define Posix_IO_F_SETFL F_SETFL
#define Posix_IO_F_GETLK F_GETLK
#define Posix_IO_F_SETLK F_SETLK
#define Posix_IO_F_RDLCK F_RDLCK
#define Posix_IO_F_WRLCK F_WRLCK
#define Posix_IO_F_UNLCK F_UNLCK
#define Posix_IO_F_SETLKW F_SETLKW
#define Posix_IO_F_GETOWN F_GETOWN
#define Posix_IO_F_SETOWN F_SETOWN
#define Posix_IO_O_ACCMODE O_ACCMODE
#define Posix_IO_SEEK_SET SEEK_SET
#define Posix_IO_SEEK_CUR SEEK_CUR
#define Posix_IO_SEEK_END SEEK_END
#define Posix_IO_FD_cloexec FD_CLOEXEC

Int Posix_IO_FLock_fcntl (Fd f, Int cmd);
Int Posix_IO_FLock_type (void);
Int Posix_IO_FLock_whence (void);
Position Posix_IO_FLock_start (void);
Position Posix_IO_FLock_len (void);
Int Posix_IO_FLock_pid (void);
void Posix_IO_FLock_setType (Int x);
void Posix_IO_FLock_setWhence (Int x);
void Posix_IO_FLock_setStart (Position x);
void Posix_IO_FLock_setLen (Position x);
void Posix_IO_FLock_setPid (Int x);

Int Posix_IO_close (Fd f);
Fd Posix_IO_dup (Fd f);
Fd Posix_IO_dup2 (Fd f1, Fd f2);
Int Posix_IO_fcntl2 (Fd f, Int i);
Int Posix_IO_fcntl3 (Fd f, Int i, Int j);
Int Posix_IO_fsync (Fd f);
Position Posix_IO_lseek (Fd f, Position i, Int j);
Int Posix_IO_pipe (Pointer fds);
Ssize Posix_IO_read (Fd fd, Pointer b, Int i, Size s);
void Posix_IO_setbin (Fd fd);
void Posix_IO_settext (Fd fd);
Ssize Posix_IO_write (Fd fd, Pointer b, Int i, Size s);

/* ---------------------------------- */
/*           Posix.ProcEnv            */
/* ---------------------------------- */

extern CstringArray Posix_ProcEnv_environ;

/* used by sysconf. */
#define Posix_ProcEnv_2_FORT_DEV _SC_2_FORT_DEV
#define Posix_ProcEnv_2_FORT_RUN _SC_2_FORT_RUN
#define Posix_ProcEnv_2_SW_DEV _SC_2_SW_DEV
#define Posix_ProcEnv_2_VERSION _SC_2_VERSION
#define Posix_ProcEnv_ARG_MAX _SC_ARG_MAX
#define Posix_ProcEnv_BC_BASE_MAX _SC_BC_BASE_MAX
#define Posix_ProcEnv_BC_DIM_MAX _SC_BC_DIM_MAX
#define Posix_ProcEnv_BC_SCALE_MAX _SC_BC_SCALE_MAX
#define Posix_ProcEnv_BC_STRING_MAX _SC_BC_STRING_MAX
#define Posix_ProcEnv_CHILD_MAX _SC_CHILD_MAX
#define Posix_ProcEnv_CLK_TCK _SC_CLK_TCK
#define Posix_ProcEnv_COLL_WEIGHTS_MAX _SC_COLL_WEIGHTS_MAX
#define Posix_ProcEnv_EXPR_NEST_MAX _SC_EXPR_NEST_MAX
#define Posix_ProcEnv_JOB_CONTROL _SC_JOB_CONTROL
#define Posix_ProcEnv_LINE_MAX _SC_LINE_MAX
#define Posix_ProcEnv_NGROUPS_MAX _SC_NGROUPS_MAX
#define Posix_ProcEnv_OPEN_MAX _SC_OPEN_MAX
#define Posix_ProcEnv_RE_DUP_MAX _SC_RE_DUP_MAX
#define Posix_ProcEnv_SAVED_IDS _SC_SAVED_IDS
#define Posix_ProcEnv_STREAM_MAX _SC_STREAM_MAX
#define Posix_ProcEnv_TZNAME_MAX _SC_TZNAME_MAX
#define Posix_ProcEnv_VERSION _SC_VERSION

enum {
  Posix_ProcEnv_numgroups = 100,
};

Pid Posix_ProcEnv_getpid (void);
Pid Posix_ProcEnv_getppid (void);
Uid Posix_ProcEnv_getuid (void);
Uid Posix_ProcEnv_geteuid (void);
Gid Posix_ProcEnv_getgid (void);
Gid Posix_ProcEnv_getegid (void);
Int Posix_ProcEnv_setenv (Pointer s, Pointer v);
Int Posix_ProcEnv_setuid (Uid u);
Int Posix_ProcEnv_setgid (Gid g);
Int Posix_ProcEnv_getgroups (Pointer groups);
Int Posix_ProcEnv_setgroups (Pointer groups);
Cstring Posix_ProcEnv_getlogin (void);
Pid Posix_ProcEnv_getpgrp (void);
Pid Posix_ProcEnv_setsid (void);
Int Posix_ProcEnv_setpgid (Pid p, Gid g);

Int Posix_ProcEnv_Uname_uname (void);
Cstring Posix_ProcEnv_Uname_sysname (void);
Cstring Posix_ProcEnv_Uname_nodename (void);
Cstring Posix_ProcEnv_Uname_release (void);
Cstring Posix_ProcEnv_Uname_version (void);
Cstring Posix_ProcEnv_Uname_machine (void);

Int Posix_ProcEnv_Tms_utime (void);
Int Posix_ProcEnv_Tms_stime (void);
Int Posix_ProcEnv_Tms_cutime (void);
Int Posix_ProcEnv_Tms_cstime (void);

Cstring Posix_ProcEnv_ctermid (void);
Cstring Posix_ProcEnv_getenv (Pointer s);
Bool Posix_ProcEnv_isatty (Fd f);
Int Posix_ProcEnv_sysconf (Int i);
Int Posix_ProcEnv_times (void);
Cstring Posix_ProcEnv_ttyname (Fd f);

/* ---------------------------------- */
/*           Posix.Process            */
/* ---------------------------------- */

#define Posix_Process_wnohang WNOHANG
#define Posix_Process_W_untraced WUNTRACED

#define Posix_Signal_abrt SIGABRT
#define Posix_Signal_alrm SIGALRM
#define Posix_Signal_bus SIGBUS
#define Posix_Signal_chld SIGCHLD
#define Posix_Signal_cont SIGCONT
#define Posix_Signal_fpe SIGFPE
#define Posix_Signal_hup SIGHUP
#define Posix_Signal_ill SIGILL
#define Posix_Signal_int SIGINT
#define Posix_Signal_kill SIGKILL
#define Posix_Signal_pipe SIGPIPE
#define Posix_Signal_prof SIGPROF
#define Posix_Signal_quit SIGQUIT
#define Posix_Signal_segv SIGSEGV
#define Posix_Signal_stop SIGSTOP
#define Posix_Signal_term SIGTERM
#define Posix_Signal_tstp SIGTSTP
#define Posix_Signal_ttin SIGTTIN
#define Posix_Signal_ttou SIGTTOU
#define Posix_Signal_usr1 SIGUSR1
#define Posix_Signal_usr2 SIGUSR2
#define Posix_Signal_vtalrm SIGVTALRM

Int Posix_Process_alarm (Int i);
Int Posix_Process_exece (Pointer path, Pointer args, Pointer env);
Int Posix_Process_execp (Pointer file, Pointer args);
void Posix_Process_exit (Int i) __attribute__ ((noreturn));
Pid Posix_Process_fork (void);
Int Posix_Process_kill (Pid p, Signal s);
Int Posix_Process_nanosleep (Pointer sec, Pointer nsec);
Int Posix_Process_pause (void);
Int Posix_Process_sleep (Int i);
int Posix_Process_system (const char* cmd);
Pid Posix_Process_waitpid (Pid p, Pointer s, Int i);
Bool Posix_Process_ifExited (Status s);
Int Posix_Process_exitStatus (Status s);
Bool Posix_Process_ifSignaled (Status s);
Signal Posix_Process_termSig (Status s);
Bool Posix_Process_ifStopped (Status s);
Signal Posix_Process_stopSig (Status s);

/* ---------------------------------- */
/*            Posix.Signal            */
/* ---------------------------------- */

#define Posix_Signal_block SIG_BLOCK
#if (defined (NSIG))
#define Posix_Signal_numSignals NSIG
#elif (defined (_NSIG))
#define Posix_Signal_numSignals _NSIG
#else
#error Posix_Signal_numSignals not defined
#endif
#define Posix_Signal_setmask SIG_SETMASK
#define Posix_Signal_unblock SIG_UNBLOCK
Int Posix_Signal_default (Int signum);
bool Posix_Signal_isGCPending (void);
Bool Posix_Signal_isPending (Int signum);
Int Posix_Signal_handle (Int signum);
void Posix_Signal_handleGC (void);
Int Posix_Signal_ignore (Int signum);
Int Posix_Signal_isDefault (Int signum, Bool *isDef);
void Posix_Signal_resetPending (void);

Int Posix_Signal_sigaddset (Int signum);
Int Posix_Signal_sigdelset (Int signum);
Int Posix_Signal_sigemptyset (void);
Int Posix_Signal_sigfillset (void);
Int Posix_Signal_sigismember (Int signum);
Int Posix_Signal_sigprocmask (Int how);
void Posix_Signal_suspend (void);

/* ---------------------------------- */
/*            Posix.SysDB             */
/* ---------------------------------- */

Cstring Posix_SysDB_Passwd_name (void);
Uid Posix_SysDB_Passwd_uid (void);
Gid Posix_SysDB_Passwd_gid (void);
Cstring Posix_SysDB_Passwd_dir (void);
Cstring Posix_SysDB_Passwd_shell (void);
Bool Posix_SysDB_getpwnam (Pointer p);
Bool Posix_SysDB_getpwuid (Uid u);
Bool Posix_SysDB_getgrgid (Gid g);
Bool Posix_SysDB_getgrnam (Pointer s);
Cstring Posix_SysDB_Group_name (void);
Gid Posix_SysDB_Group_gid (void);
CstringArray Posix_SysDB_Group_mem (void);

/* ---------------------------------- */
/*             Posix.TTY              */
/* ---------------------------------- */

#define Posix_TTY_b0 B0
#define Posix_TTY_b110 B110
#define Posix_TTY_b1200 B1200
#define Posix_TTY_b134 B134
#define Posix_TTY_b150 B150
#define Posix_TTY_b1800 B1800
#define Posix_TTY_b19200 B19200
#define Posix_TTY_b200 B200
#define Posix_TTY_b2400 B2400
#define Posix_TTY_b300 B300
#define Posix_TTY_b38400 B38400
#define Posix_TTY_b4800 B4800
#define Posix_TTY_b50 B50
#define Posix_TTY_b600 B600
#define Posix_TTY_b75 B75
#define Posix_TTY_b9600 B9600
#define Posix_TTY_V_eof VEOF
#define Posix_TTY_V_eol VEOL
#define Posix_TTY_V_erase VERASE
#define Posix_TTY_V_intr VINTR
#define Posix_TTY_V_kill VKILL
#define Posix_TTY_V_min VMIN
#define Posix_TTY_V_nccs NCCS
#define Posix_TTY_V_quit VQUIT
#define Posix_TTY_V_start VSTART
#define Posix_TTY_V_stop VSTOP
#define Posix_TTY_V_susp VSUSP
#define Posix_TTY_V_time VTIME
#define Posix_TTY_I_brkint BRKINT
#define Posix_TTY_I_icrnl ICRNL
#define Posix_TTY_I_ignbrk IGNBRK
#define Posix_TTY_I_igncr IGNCR
#define Posix_TTY_I_ignpar IGNPAR
#define Posix_TTY_I_inlcr INLCR
#define Posix_TTY_I_inpck INPCK
#define Posix_TTY_I_istrip ISTRIP
#define Posix_TTY_I_ixoff IXOFF
#define Posix_TTY_I_ixon IXON
#define Posix_TTY_I_parmrk PARMRK
#define Posix_TTY_O_opost OPOST
#define Posix_TTY_C_clocal CLOCAL
#define Posix_TTY_C_cread CREAD
#define Posix_TTY_C_cs5 CS5
#define Posix_TTY_C_cs6 CS6
#define Posix_TTY_C_cs7 CS7
#define Posix_TTY_C_cs8 CS8
#define Posix_TTY_C_csize CSIZE
#define Posix_TTY_C_cstopb CSTOPB
#define Posix_TTY_C_hupcl HUPCL
#define Posix_TTY_C_parenb PARENB
#define Posix_TTY_C_parodd PARODD
#define Posix_TTY_L_echo ECHO
#define Posix_TTY_L_echoe ECHOE
#define Posix_TTY_L_echok ECHOK
#define Posix_TTY_L_echonl ECHONL
#define Posix_TTY_L_icanon ICANON
#define Posix_TTY_L_iexten IEXTEN
#define Posix_TTY_L_isig ISIG
#define Posix_TTY_L_noflsh NOFLSH
#define Posix_TTY_L_tostop TOSTOP
#define Posix_TTY_TC_sadrain TCSADRAIN
#define Posix_TTY_TC_saflush TCSAFLUSH
#define Posix_TTY_TC_sanow TCSANOW
#define Posix_TTY_TC_ion TCION
#define Posix_TTY_TC_ioff TCIOFF
#define Posix_TTY_TC_ooff TCOOFF
#define Posix_TTY_TC_oon TCOON
#define Posix_TTY_TC_iflush TCIFLUSH
#define Posix_TTY_TC_ioflush TCIOFLUSH
#define Posix_TTY_TC_oflush TCOFLUSH

Flag Posix_TTY_Termios_iflag (void);
Flag Posix_TTY_Termios_oflag (void);
Flag Posix_TTY_Termios_cflag (void);
Flag Posix_TTY_Termios_lflag (void);
Cstring Posix_TTY_Termios_cc (void);
Speed Posix_TTY_Termios_cfgetospeed (void);
Speed Posix_TTY_Termios_cfgetispeed (void);
void Posix_TTY_Termios_setiflag (Flag f);
void Posix_TTY_Termios_setoflag (Flag f);
void Posix_TTY_Termios_setcflag (Flag f);
void Posix_TTY_Termios_setlflag (Flag f);
Int Posix_TTY_Termios_setospeed (Speed s);
Int Posix_TTY_Termios_setispeed (Speed s);
Int Posix_TTY_getattr (Fd f);
Int Posix_TTY_setattr (Fd f, Int i);
Int Posix_TTY_sendbreak (Fd f, Int i);
Int Posix_TTY_drain (Fd f);
Int Posix_TTY_flush (Fd f, Int i);
Int Posix_TTY_flow (Fd f, Int i);
Int Posix_TTY_getpgrp (Fd f);
Int Posix_TTY_setpgrp (Fd f, Pid p);

/* ------------------------------------------------- */
/*                      Ptrace                       */
/* ------------------------------------------------- */

Int Ptrace_ptrace2 (Int request, Int pid);
/* data is a word ref */
Int Ptrace_ptrace4 (Int request, Int pid, Word addr, Pointer data);

/* ------------------------------------------------- */
/*                       Real                        */
/* ------------------------------------------------- */

Real64 Real64_modf (Real64 x, Real64 *exp);
Real32 Real32_modf (Real32 x, Real32 *exp);
Real64 Real64_frexp (Real64 x, Int *exp);
Cstring Real64_gdtoa (double d, int mode, int ndig, int *decpt);
Cstring Real32_gdtoa (float f, int mode, int ndig, int *decpt);
Int Real32_class (Real32 f);
Int Real64_class (Real64 d);
Real32 Real32_strto (Pointer s);
Real64 Real64_strto (Pointer s);
Real64 Real64_nextAfter (Real64 x1, Real64 x2);
Int Real32_signBit (Real32 f);
Int Real64_signBit (Real64 d);
#define ternary(size, name)                                     \
        Real##size Real##size##_mul##name                       \
                (Real##size r1, Real##size r2, Real##size r3);
ternary(32, add)
ternary(64, add)
ternary(32, sub)
ternary(64, sub)
#undef ternary

/* ------------------------------------------------- */
/*                      Socket                       */
/* ------------------------------------------------- */

#if (defined (__MSVCRT__))
void MLton_initSockets (void);
#else
static inline void MLton_initSockets (void) {}
#endif

#define Socket_sockAddrLenMax max(sizeof (struct sockaddr), \
                              max(sizeof (struct sockaddr_un), \
                              max(sizeof (struct sockaddr_in), \
                                  sizeof (struct sockaddr_in6))))
#define Socket_AF_UNIX PF_UNIX
#define Socket_AF_INET PF_INET
#define Socket_AF_INET6 PF_INET6
#define Socket_AF_UNSPEC PF_UNSPEC
#define Socket_SOCK_STREAM SOCK_STREAM
#define Socket_SOCK_DGRAM SOCK_DGRAM
#define Socket_Ctl_SOL_SOCKET SOL_SOCKET
#define Socket_Ctl_SO_DEBUG SO_DEBUG
#define Socket_Ctl_SO_REUSEADDR SO_REUSEADDR
#define Socket_Ctl_SO_KEEPALIVE SO_KEEPALIVE
#define Socket_Ctl_SO_DONTROUTE SO_DONTROUTE
#define Socket_Ctl_SO_LINGER SO_LINGER
#define Socket_Ctl_SO_BROADCAST SO_BROADCAST
#define Socket_Ctl_SO_OOBINLINE SO_OOBINLINE
#define Socket_Ctl_SO_SNDBUF SO_SNDBUF
#define Socket_Ctl_SO_RCVBUF SO_RCVBUF
#define Socket_Ctl_SO_TYPE SO_TYPE
#define Socket_Ctl_SO_ERROR SO_ERROR
#define Socket_Ctl_FIONBIO FIONBIO
#define Socket_Ctl_FIONREAD FIONREAD
#define Socket_Ctl_SIOCATMARK SIOCATMARK
#define Socket_SHUT_RD SHUT_RD
#define Socket_SHUT_WR SHUT_WR
#define Socket_SHUT_RDWR SHUT_RDWR
#define Socket_MSG_DONTROUTE MSG_DONTROUTE
#define Socket_MSG_DONTWAIT MSG_DONTWAIT
#define Socket_MSG_OOB MSG_OOB
#define Socket_MSG_PEEK MSG_PEEK
#define Socket_INetSock_TCP_SOL_TCP IPPROTO_TCP
#define Socket_INetSock_TCP_SO_NODELAY TCP_NODELAY
Int Socket_accept (Int s, Char *addr, Int *addrlen);
Int Socket_bind (Int s, Char *addr, Int addrlen);
Int Socket_close(Int s);
Int Socket_connect (Int s, Char *addr, Int addrlen);
Int Socket_familyOfAddr(Char *addr);
Int Socket_listen (Int s, Int backlog);
Int Socket_recv (Int s, Char *msg, Int start, Int len, Word flags);
Int Socket_recvFrom (Int s, Char *msg, Int start, Int len, Word flags, Char* addr, Int *addrlen);
Int Socket_send (Int s, Char *msg, Int start, Int len, Word flags);
Int Socket_sendTo (Int s, Char *msg, Int start, Int len, Word flags, Char* addr, Int addrlen);
Int Socket_shutdown (Int s, Int how);
Int Socket_Ctl_getSockOpt (Int s, Int level, Int optname, Char *optval, Int *optlen);
Int Socket_Ctl_setSockOpt (Int s, Int level, Int optname, Char *optval, Int optlen);
Int Socket_Ctl_getsetIOCtl (Int s, Int request, Char* argp);
Int Socket_Ctl_getPeerName (Int s, Char *name, Int *namelen);
Int Socket_Ctl_getSockName (Int s, Char *name, Int *namelen);
Int GenericSock_socket (Int domain, Int type, Int protocol);
Int GenericSocket_socketPair (Int domain, Int type, Int protocol, Int sv[2]);
void UnixSock_toAddr (Char* path, Int pathlen, Char* addr, Int *addrlen);
Int UnixSock_pathLen (Char* addr);
void UnixSock_fromAddr (Char* addr, Char* path, Int pathlen);
void INetSock_toAddr (Pointer in_addr, Int port, Char* addr, Int *addrlen);
void INetSock_fromAddr (Char* addr);
Int INetSock_getPort (void);
void INetSock_getInAddr (Pointer addr);

/* ------------------------------------------------- */
/*                       Stdio                       */
/* ------------------------------------------------- */

void Stdio_print (Pointer s);

/* ------------------------------------------------- */
/*                      String                       */
/* ------------------------------------------------- */

int String_equal (char * s1, char * s2);

/* ------------------------------------------------- */
/*                       Time                        */
/* ------------------------------------------------- */

Int Time_gettimeofday (void);
Int Time_sec (void);
Int Time_usec (void);

/* ------------------------------------------------- */
/*                      Windows                      */
/* ------------------------------------------------- */

Int Windows_terminate (Pid p, Int s);

/* ------------------------------------------------- */
/*                  Word{8,16,32,64}                 */
/* ------------------------------------------------- */

#define SaddCheckOverflows(size)                                        \
        Bool WordS##size##_addCheckOverflows (WordS##size x, WordS##size y);
#define UaddCheckOverflows(size)                                        \
        Bool WordU##size##_addCheckOverflows (WordU##size x, WordU##size y);
#define SmulCheckOverflows(size)                                        \
        Bool WordS##size##_mulCheckOverflows (WordS##size x, WordS##size y);
#define negCheckOverflows(size)                                         \
        Bool Word##size##_negCheckOverflows (WordS##size x);
#define SsubCheckOverflows(size)                                        \
        Bool WordS##size##_subCheckOverflows (WordS##size x, WordS##size y);

#define all(size)                                               \
        SaddCheckOverflows (size)                               \
        UaddCheckOverflows (size)                               \
        negCheckOverflows (size)                                \
        SmulCheckOverflows (size)                               \
        SsubCheckOverflows (size)                               \

all (8)
all (16)
all (32)
all (64)

#undef SaddCheckOverflows
#undef UaddCheckOverflows
#undef SmulCheckOverflows
#undef negCheckOverflows
#undef SsubCheckOverflows
#undef all

/* ------------------------------------------------- */
/*                    Word8 Array                    */
/* ------------------------------------------------- */

Word32 Word8Array_subWord32Rev (Pointer v, Int offset);
void Word8Array_updateWord32Rev (Pointer a, Int offset, Word32 w);

/* ------------------------------------------------- */
/*                    Word8 Vector                   */
/* ------------------------------------------------- */

Word32 Word8Vector_subWord32Rev (Pointer v, Int offset);

#endif /* _MLTON_PLATFORM_H_ */
