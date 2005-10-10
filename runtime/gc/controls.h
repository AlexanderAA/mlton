/* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

struct GC_controls {
  size_t fixedHeap; /* If 0, then no fixed heap. */
  size_t maxHeap; /* if zero, then unlimited, else limit total heap */
  bool messages;
  bool summary;
};
