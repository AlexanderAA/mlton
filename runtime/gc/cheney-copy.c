/* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

/* ---------------------------------------------------------------- */
/*                    Cheney Copying Collection                     */
/* ---------------------------------------------------------------- */

#define GC_FORWARDED ~((GC_header)0)

/* forward (s, opp) 
 * Forwards the object pointed to by *opp and updates *opp to point to
 * the new object.  
 * It also updates the crossMap.
 */
struct forwardState {
  pointer back;
  pointer toStart;
  pointer toLimit;
};
static struct forwardState forwardState;

static inline bool pointerIsInFromSpace (GC_state s, pointer p) {
  return (pointerIsInOldGen (s, p) or pointerIsInNursery (s, p));
}

static inline bool objptrIsInFromSpace (GC_state s, objptr op) {
  return (objptrIsInOldGen (s, op) or objptrIsInNursery (s, op));
}

static inline bool pointerIsInToSpace (pointer p) {
  return (not (isPointer (p))
          or (forwardState.toStart <= p and p < forwardState.toLimit));
}

static inline bool objptrIsInToSpace (objptr op) {
  pointer p;

  if (not (isObjptr (op)))
    return TRUE;
  p = objptrToPointer (op, forwardState.toStart);
  return pointerIsInToSpace (p);
}

static inline void forward (GC_state s, objptr *opp) {
  objptr op;
  pointer p;
  GC_header header;
  GC_objectTypeTag tag;

  op = *opp;
  p = objptrToPointer (op, s->heap.start);
  if (DEBUG_DETAILED)
    fprintf (stderr,
             "forward  opp = "FMTPTR"  op = "FMTOBJPTR"  p = "FMTPTR"\n",
             (uintptr_t)opp, op, (uintptr_t)p);
  assert (objptrIsInFromSpace (s, *opp));
  header = getHeader (p);
  if (DEBUG_DETAILED and header == GC_FORWARDED)
    fprintf (stderr, "  already FORWARDED\n");
  if (header != GC_FORWARDED) { /* forward the object */
    bool hasIdentity;
    uint16_t numNonObjptrs, numObjptrs;
    size_t headerBytes, objectBytes, size, skip;

    /* Compute the space taken by the header and object body. */
    SPLIT_HEADER();
    if ((NORMAL_TAG == tag) or (WEAK_TAG == tag)) { /* Fixed size object. */
      headerBytes = GC_NORMAL_HEADER_SIZE;
      objectBytes = 
        numNonObjptrsToBytes(numNonObjptrs, NORMAL_TAG)
        + (numObjptrs * OBJPTR_SIZE);
      skip = 0;
    } else if (ARRAY_TAG == tag) {
      headerBytes = GC_ARRAY_HEADER_SIZE;
      objectBytes = arrayNumBytes (s, p, numObjptrs, numNonObjptrs);
      skip = 0;
    } else { /* Stack. */
      GC_stack stack;

      assert (STACK_TAG == tag);
      headerBytes = GC_STACK_HEADER_SIZE;
      stack = (GC_stack)p;

      if (currentThreadStack(s) == op) {
        /* Shrink stacks that don't use a lot of their reserved space;
         * but don't violate the stack invariant.
         */
        if (stack->used <= stack->reserved / 4) {
          size_t new = 
            stackReserved (s, maxZ (stack->reserved / 2,
                                    stackNeedsReserved (s, stack)));
          /* It's possible that new > stack->reserved if the stack
           * invariant is violated. In that case, we want to leave the
           * stack alone, because some other part of the gc will grow
           * the stack.  We cannot do any growing here because we may
           * run out of to space.
           */
          if (new <= stack->reserved) {
            stack->reserved = new;
            if (DEBUG_STACKS)
              fprintf (stderr, "Shrinking stack to size %zd.\n",
                       /*uintToCommaString*/(stack->reserved));
          }
        }
      } else {
        /* Shrink heap stacks. */
        stack->reserved = 
          stackReserved (s, maxZ((size_t)(s->threadShrinkRatio * stack->reserved),
                                 stack->used));
        if (DEBUG_STACKS)
          fprintf (stderr, "Shrinking stack to size %zd.\n",
                   /*uintToCommaString*/(stack->reserved));
      }
      objectBytes = sizeof (struct GC_stack) + stack->used;
      skip = stack->reserved - stack->used;
    }
    size = headerBytes + objectBytes;
    assert (forwardState.back + size + skip <= forwardState.toLimit);
    /* Copy the object. */
    copy (p - headerBytes, forwardState.back, size);
    /* If the object has a valid weak pointer, link it into the weaks
     * for update after the copying GC is done.
     */
    if ((WEAK_TAG == tag) and (numObjptrs == 1)) {
      GC_weak w;
      
      w = (GC_weak)(forwardState.back + GC_NORMAL_HEADER_SIZE);
      if (DEBUG_WEAK)
        fprintf (stderr, "forwarding weak "FMTPTR" ",
                 (uintptr_t)w);
      if (isObjptr (w->objptr)
          and (not s->amInMinorGC
               or objptrIsInNursery (s, w->objptr))) {
        if (DEBUG_WEAK)
          fprintf (stderr, "linking\n");
        w->link = s->weaks;
        s->weaks = w;
      } else {
        if (DEBUG_WEAK)
          fprintf (stderr, "not linking\n");
      }
    }
    /* Store the forwarding pointer in the old object. */
    *(GC_header*)(p - GC_HEADER_SIZE) = GC_FORWARDED;
    *(objptr*)p = pointerToObjptr(forwardState.back + headerBytes, forwardState.toStart);
    /* Update the back of the queue. */
    forwardState.back += size + skip;
    assert (isAligned ((uintptr_t)forwardState.back + GC_NORMAL_HEADER_SIZE, 
                       s->alignment));
  }
  *opp = *(objptr*)p;
  assert (objptrIsInToSpace (*opp));
}

static inline void updateWeaks (GC_state s) {
  pointer p;
  GC_weak w;

  for (w = s->weaks; w != NULL; w = w->link) {
    assert (BOGUS_OBJPTR != w->objptr);

    if (DEBUG_WEAK)
      fprintf (stderr, "updateWeaks  w = "FMTPTR"  ", (uintptr_t)w);
    p = objptrToPointer (w->objptr, s->heap.start);
    if (GC_FORWARDED == getHeader (p)) {
      if (DEBUG_WEAK)
        fprintf (stderr, "forwarded from "FMTOBJPTR" to "FMTOBJPTR"\n",
                 w->objptr,
                 *(objptr*)p);
      w->objptr = *(objptr*)p;
    } else {
      if (DEBUG_WEAK)
        fprintf (stderr, "cleared\n");
      *(getHeaderp(p)) = WEAK_GONE_HEADER;
      w->objptr = BOGUS_OBJPTR;
    }
  }
  s->weaks = NULL;
}

static inline void swapHeaps (GC_state s) {
  struct GC_heap tempHeap;
  
  tempHeap = s->secondaryHeap;
  s->secondaryHeap = s->heap;
  s->heap = tempHeap;
  // setCardMapForMutator (s);
}

/* static inline bool detailedGCTime (GC_state s) { */
/*         return s->summary; */
/* } */

static void majorCheneyCopyGC (GC_state s) {
  // struct rusage ru_start;
  pointer toStart;

  assert (s->secondaryHeap.totalBytes >= s->heap.oldGenBytes);
/*   if (detailedGCTime (s)) */
/*     startTiming (&ru_start); */
  s->cumulative.numCopyingGCs++;
  forwardState.toStart = s->secondaryHeap.start;
  forwardState.toLimit = s->secondaryHeap.start + s->secondaryHeap.totalBytes;
  if (DEBUG or s->messages) {
    fprintf (stderr, "Major copying GC.\n");
    fprintf (stderr, "fromSpace = "FMTPTR" of size %zd\n",
             (uintptr_t) s->heap.start, 
             /*uintToCommaString*/(s->heap.totalBytes));
    fprintf (stderr, "toSpace = "FMTPTR" of size %zd\n",
             (uintptr_t) s->secondaryHeap.start, 
             /*uintToCommaString*/(s->secondaryHeap.totalBytes));
  }
  assert (s->secondaryHeap.start != (pointer)NULL);
  /* The next assert ensures there is enough space for the copy to
   * succeed.  It does not assert 
   *   (s->secondaryHeap.totalBytes >= s->heap.totalByes) 
   * because that is too strong.
   */
  assert (s->secondaryHeap.totalBytes >= s->heap.oldGenBytes);
  toStart = alignFrontier (s, s->secondaryHeap.start);
  forwardState.back = toStart;
  foreachGlobalObjptr (s, forward);
  foreachObjptrInRange (s, toStart, &forwardState.back, TRUE, forward);
  updateWeaks (s);
  s->secondaryHeap.oldGenBytes = forwardState.back - s->secondaryHeap.start;
  s->cumulative.bytesCopied += s->secondaryHeap.oldGenBytes;
  if (DEBUG)
    fprintf (stderr, "%zd bytes live.\n",
             /*uintToCommaString*/(s->secondaryHeap.oldGenBytes));
  swapHeaps (s);
  // clearCrossMap (s);
  s->lastMajor.kind = GC_COPYING;
/*   if (detailedGCTime (s)) */
/*     stopTiming (&ru_start, &s->ru_gcCopy); */
  if (DEBUG or s->messages)
    fprintf (stderr, "Major copying GC done.\n");
}
