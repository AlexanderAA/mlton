/* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

void loadWorldFromFD (GC_state s, FILE *f) {
  uint32_t magic;
  pointer start;
        
  if (DEBUG_WORLD)
    fprintf (stderr, "loadWorldFromFD\n");
  until (readChar (f) == '\000') ;
  magic = readUint32 (f);
  unless (s->magic == magic)
    die ("Invalid world: wrong magic number.");
  start = readPointer (f);
  s->heap.oldGenSize = readSize (f);
  s->atomicState = readUint32 (f);
  s->callFromCHandlerThread = readObjptr (f); 
  s->currentThread = readObjptr (f); 
  s->signalHandlerThread = readObjptr (f); 
  createHeap (s, &s->heap, 
              sizeofHeapDesired (s, s->heap.oldGenSize, 0), 
              s->heap.oldGenSize);
  createCardMapAndCrossMap (s); 
  fread_safe (s->heap.start, 1, s->heap.oldGenSize, f);
  if ((*(s->loadGlobals)) (f) != 0) diee("couldn't load globals");
  // unless (EOF == fgetc (file))
  //  die ("Invalid world: junk at end of file.");
  /* translateHeap must occur after loading the heap and globals,
   * since it changes pointers in all of them.
   */
  translateHeap (s, start, s->heap.start, s->heap.oldGenSize);
  setGCStateCurrentHeap (s, 0, 0); 
  setGCStateCurrentThreadAndStack (s); 
}

void loadWorldFromFileName (GC_state s, const char *fileName) {
  FILE *f;
        
  if (DEBUG_WORLD)
    fprintf (stderr, "loadWorldFromFileName (%s)\n", fileName);
  f = fopen_safe (fileName, "rb");
  loadWorldFromFD (s, f);
  fclose_safe (f); 
}

/* Don't use 'safe' functions, because we don't want the ML program to die.
 * Instead, check return values, and propogate them up to SML for an exception.
 */
int saveWorldToFD (GC_state s, FILE *f) {
  char buf[80];
  size_t len;

  if (DEBUG_WORLD)
    fprintf (stderr, "saveWorld.\n");
  /* Compact the heap. */
  performGC (s, 0, 0, TRUE, TRUE);
  sprintf (buf,
           "Heap file created by MLton.\nheap.start = "FMTPTR"\nbytesLive = %zu\n",
           (uintptr_t)s->heap.start, 
           s->lastMajorStatistics.bytesLive);
  len = strlen(buf) + 1; /* +1 to get the '\000' */
  
  if (fwrite (buf, 1, len, f) != len) return -1;
  if (fwrite (&s->magic, sizeof(uint32_t), 1, f) != 1) return -1;
  if (fwrite (&s->heap.start, sizeof(uintptr_t), 1, f) != 1) return -1;
  if (fwrite (&s->heap.oldGenSize, sizeof(size_t), 1, f) != 1) return -1;
  
  /* atomicState must be saved in the heap, because the saveWorld may
   * be run in the context of a critical section, which will expect to
   * be in the same context when it is restored.
   */
  if (fwrite (&s->atomicState, sizeof(uint32_t), 1, f) != 1) return -1;
  if (fwrite (&s->callFromCHandlerThread, sizeof(objptr), 1, f) != 1) return -1;
  if (fwrite (&s->currentThread, sizeof(objptr), 1, f) != 1) return -1;
  if (fwrite (&s->signalHandlerThread, sizeof(objptr), 1, f) != 1) return -1;
  
  if (fwrite (s->heap.start, 1, s->heap.oldGenSize, f) != s->heap.oldGenSize)
    return -1;
  if ((*(s->saveGlobals)) (f) != 0)
    return -1;
  return 0;
}

uint32_t GC_saveWorld (GC_state s, NullString8_t fileName) {
  FILE *f;
  
  enter (s);
  f = fopen((const char*)fileName, "wb");
  if (0 == f) {
    leave (s);
    return 1;
  }
  if (saveWorldToFD (s, f) != 0) return 1;
  if (fclose (f) != 0) return 1;
  leave (s);
  
  return 0;
}
