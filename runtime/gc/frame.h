/* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

/*
 * The "... reserved bytes ..." of a stack object constitute a linear
 * sequence of frames.  For the purposes of garbage collection, we
 * must be able to recover the size and offsets of live heap-pointers
 * for each frame.  This data is declared as follows:
 *
 *  GC_frameLayout *frameLayouts;
 * 
 * The frameLayouts pointer is initialized to point to a static array
 * of frame layouts that is emitted for each compiled program.  The
 * kind field identifies whether or not the frame is for a C call.
 * (Note: The ML stack is distinct from the system stack.  A C call
 * executes on the system stack.  The frame left on the ML stack is
 * just a marker.)  The size field indicates the size of the frame,
 * including space for the return address.  The offsets field points
 * to an array (the zeroeth element recording the size of the array)
 * whose elements record byte offsets from the bottom of the frame at
 * which live heap pointers are located.
 */
typedef uint16_t *GC_frameOffsets;

typedef enum {
  C_FRAME,
  ML_FRAME
} GC_frameKind;

typedef struct GC_frameLayout {
  GC_frameKind kind;
  uint16_t size;
  GC_frameOffsets offsets;
} GC_frameLayout;

typedef uintptr_t GC_returnAddress;
#define GC_RETURNADDRESS_SIZE sizeof(GC_returnAddress)
#define FMTRA "0x%016"PRIxPTR
