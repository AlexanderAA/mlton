/* Copyright (C) 1999-2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 */
#ifndef _LIBMLTON_H
#define _LIBMLTON_H

#undef i386
#undef i486

#include "basis-constants.h"
#include "gc.h"
#include "IntInf.h"
#include "mlton-basis.h"
#include "mlton-posix.h"
#include "my-lib.h"
#include "net-constants.h"
#include "posix-constants.h"

/* initialize the machine */
void MLton_init (int argc, char **argv, GC_state s);

/* Print a string, escaping every character with decimal escapes. */
void MLton_printStringEscaped (FILE *f, unsigned char *s);

#endif /* #ifndef _LIBMLTON_H */

