/* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

#ifndef _UTIL_H_
#define _UTIL_H_

#define _ISOC99_SOURCE
#define _BSD_SOURCE

/* Only enable _POSIX_C_SOURCE on platforms that don't have broken system
 * headers.
 */
#if (defined (__linux__))
#define _POSIX_C_SOURCE 200112L
#endif

/* C99-specific headers */
#include <stddef.h>
#include <stdbool.h>
#include <iso646.h>
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

#include "../assert.h"

#define TWOPOWER(n) (1 << (n))

#ifndef TRUE
#define TRUE    (0 == 0)
#endif
#ifndef FALSE
#define FALSE   (not TRUE)
#endif
#define unless(p)       if (not (p))

/* issue error message and exit */
extern void die (char *fmt, ...)
                        __attribute__ ((format(printf, 1, 2)))
                        __attribute__ ((noreturn));
/* issue error message and exit.  Also print strerror(errno). */
extern void diee (char *fmt, ...)
                        __attribute__ ((format(printf, 1, 2)))
                        __attribute__ ((noreturn));

typedef void* pointer;
#define FMTPTR "0x%08"PRIxPTR

#endif /* _UTIL_H_ */
