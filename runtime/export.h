/* Copyright (C) 1999-2007 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

#ifndef _MLTON_EXPORT_H_
#define _MLTON_EXPORT_H_

/* ------------------------------------------------- */
/*                      Symbols                      */
/* ------------------------------------------------- */

#if defined(_WIN32) || defined(_WIN64)
#define IMPORTED __declspec(dllimport)
#define EXPORTED __declspec(dllexport)
#define INTERNAL
#else
#if __GNUC__ >= 4
#define IMPORTED __attribute__((visibility("default")))
#define EXPORTED __attribute__((visibility("default")))
#define INTERNAL __attribute__((visibility("hidden")))
#else
#define IMPORTED
#define EXPORTED
#define INTERNAL
#endif
#endif

#endif /* _MLTON_EXPORT_H_ */
