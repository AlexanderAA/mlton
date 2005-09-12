/* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

struct GC_cumulativeStatistics {
  uintmax_t bytesAllocated;
  uintmax_t bytesCopied;
  uintmax_t bytesCopiedMinor;
  uintmax_t bytesHashConsed;
  uintmax_t bytesMarkCompacted;

  uintmax_t markedCards; /* Number of marked cards seen during minor GCs. */

  size_t maxBytesLive;
  size_t maxHeapSizeSeen;
  size_t maxStackSizeSeen;

  uintmax_t minorBytesScanned;
  uintmax_t minorBytesSkipped;

  uintmax_t numLimitChecks;

  unsigned int numCopyingGCs;
  unsigned int numHashConsGCs;
  unsigned int numMarkCompactGCs;
  unsigned int numMinorGCs;

/*   struct rusage ru_gc; /\* total resource usage spent in gc *\/ */
/*   struct rusage ru_gcCopy; /\* resource usage in major copying gcs. *\/ */
/*   struct rusage ru_gcMarkCompact; /\* resource usage in mark-compact gcs. *\/ */
/*   struct rusage ru_gcMinor; /\* resource usage in minor gcs. *\/ */
};

struct GC_lastMajorStatistics {
  size_t bytesLive; /* Number of bytes live at most recent major GC. */
  GC_MajorKind kind;
  unsigned int numMinorsGCs;
};
