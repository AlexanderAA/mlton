/* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 */
#ifndef _MLTON_GC_H
#define _MLTON_GC_H

/*
 * A two-space stop-and-copy GC.
 *
 * Has three kinds of objects: normal (fixed size), arrays, and stacks.
 */

#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/resource.h>

#include "my-lib.h"

typedef uint word;
typedef char* pointer;
typedef unsigned long long W64;
typedef unsigned long W32;
typedef W32 Header;

/*
 * Header word bits look as follows:
 * 31		mark bit
 * 30 - 20	counter bits
 * 19 - 1	type index bits
 * 0		1
 *
 * The mark bit is used by the mark compact GC and GC_size to mark an object
 * as reachable.  The counter bits are used during the mark phase in conjunction
 * with pointer reversal to implement the mark stack.  They record the current
 * pointer
 *
 * The type index is an index into an array of struct GC_ObjectType's, where 
 * each element describes the layout of an object.  There are three kinds of
 * objects: array, normal, and stack.
 *
 * Arrays are layed out as follows
 *   counter word
 *   length word
 *   header word
 *   data words ...
 * The counter word is used during marking to help implement the mark stack.
 * The length word is the number of elements in the array.
 * The header word contains a type index that describes the layout of elements.
 * For now, arrays are either all pointers or all nonpointers.
 * 
 * Normal objects are a header word followed by the data words, which consist
 * of all nonpointer data followed by all pointer data.  
 *
 * 19 bits means that there are only 2^19 different different object layouts,
 * which appears to be plenty, since there were < 128 different types required
 * for a self-compile.
 */

/* Sizes are (almost) always measured in bytes. */
enum {
	DEBUG_PROFILE_ALLOC = 	FALSE,
	DEBUG_PROFILE_TIME = 	FALSE,
	WORD_SIZE = 		4,
	COUNTER_MASK =		0x7FF00000,
	COUNTER_SHIFT =		20,
	GC_ARRAY_HEADER_SIZE = 	3 * WORD_SIZE,
	GC_NORMAL_HEADER_SIZE =	WORD_SIZE,
	TYPE_INDEX_BITS =	19,
	TYPE_INDEX_MASK =	0x000FFFFE,
	LIMIT_SLOP = 		512,
	MARK_MASK =		0x80000000,
	POINTER_SIZE =		WORD_SIZE,
	SOURCES_INDEX_UNKNOWN = 0,
	SOURCES_INDEX_GC =	1,
	SOURCE_SEQ_UNKNOWN = 	0,
	STACK_TYPE_INDEX =	0,
	STRING_TYPE_INDEX = 	1,
	THREAD_TYPE_INDEX =	2,
	WORD8_VECTOR_TYPE_INDEX = STRING_TYPE_INDEX,
	WORD_VECTOR_TYPE_INDEX = 3,
};

#define TWOPOWER(n) (1 << (n))

typedef enum {
	PROFILE_CURRENT,
	PROFILE_CUMULATIVE,
} ProfileStyle;

/* ------------------------------------------------- */
/*                    object type                    */
/* ------------------------------------------------- */

typedef enum { 
	ARRAY_TAG,
	NORMAL_TAG,
	STACK_TAG,
} GC_ObjectTypeTag;

typedef struct {
	GC_ObjectTypeTag tag;
	ushort numNonPointers;
	ushort numPointers;
} GC_ObjectType;

/* ------------------------------------------------- */
/*                  initialization                   */
/* ------------------------------------------------- */

/*
 * GC_init uses the array of struct intInfInits in s at program start to 
 * allocate intInfs.
 * The array is terminated by an intInfInit with mlstr field NULL.
 * For each other entry, the globalIndex'th entry of the globals array in
 * s is set to the IntInf.int whose value corresponds to the mlstr string.
 *
 * The strings pointed to by the mlstr fields consist of
 *	an optional ~
 *	either one or more of [0-9] or
 *		0x followed by one or more of [0-9a-fA-F]
 *	a trailing EOS
 */
struct GC_intInfInit {
	uint	globalIndex;
	char	*mlstr;
};

/* GC_init allocates a collection of strings in the heap. */
struct GC_stringInit {
  uint globalIndex;
  char *str;
  uint size;
};

/* ------------------------------------------------- */
/*                  GC_frameLayout                   */
/* ------------------------------------------------- */

typedef ushort *GC_offsets;

typedef struct GC_frameLayout {
	/* Number of bytes in frame, including space for return address. */
	ushort numBytes;
	/* Offsets from stackTop pointing at bottom of frame at which pointers
	 * are located. 
	 */
	GC_offsets offsets;
} GC_frameLayout;

/* ------------------------------------------------- */
/*                     GC_stack                      */
/* ------------------------------------------------- */

typedef struct GC_stack {	
	/* markTop and markIndex are only used during marking.  They record the
	 * current pointer in the stack that is being followed.  markTop points
	 * to the top of the stack frame containing the pointer and markI is the
	 * index in that frames frameOffsets of the pointer slot.  So, when the
	 * GC pointer reversal gets back to the stack, it can continue with the
	 * next pointer (either in the current frame or the next frame).
	 */
	pointer markTop;
	W32 markIndex;
	/* reserved is the number of bytes reserved for stack, i.e. its maximum
	 * size.
	 */
	uint reserved;
	/* used is the number of bytes in use by the stack.  
         * Stacks with used == reserved are continuations.
	 */
	uint used;	
	/* The next address is the bottom of the stack, and the following
         * reserved bytes hold space for the stack.
         */
} *GC_stack;

/* ------------------------------------------------- */
/*                     GC_thread                     */
/* ------------------------------------------------- */

typedef struct GC_thread {
	/* The order of these fields is important.  The nonpointer fields
	 * must be first, because this object must appear to be a normal heap
	 * object.
	 * Furthermore, the exnStack field must be first, because the native
	 * codegen depends on this (which is bad and should be fixed).
	 */
	uint exnStack;    	/* An offset added to stackBottom that specifies 
				 * where the top of the exnStack is.
				 */
	uint bytesNeeded;       /* The number of bytes needed when returning
				 * to this thread.
				 */
	GC_stack stack;		/* The stack for this thread. */
} *GC_thread;

/* ------------------------------------------------- */
/*                     Profiling                     */
/* ------------------------------------------------- */

typedef struct GC_sourceLabel {
	pointer label;
	uint sourceSeqsIndex;
} *GC_profileLabel;

typedef struct GC_profileAlloc {
	/* bytesAllocated is an array of length sourcesSize that counts for
	 * each function the number of bytes that have been allocated.
	 * If profileStyle == PROFILE_CURRENT, then it is the number while
	 * that function was current.  If profileStyle == PROFILE_CUMULATIVE,
	 * then it is the number while the function was on the stack.
	 */
	ullong *bytesAllocated;
	/* lastTotal is an array of length sourcesSize that for each function, 
	 * f, stores the value of totalBytesAllocated when the oldest occurrence
	 * of f on the stack was pushed, i.e., the most recent time that 
	 * stackCount[f] was changed from 0 to 1.  lastTotal is used to compute
	 * the number of bytes to attribute to f when the oldest occurrence is
	 * finally popped.  lastTotal is only used if 
	 * profileStyle == PROFILE_CUMULATIVE.
	 */
	ullong *lastTotal;
	/* stackCount is an array of length sourcesSize that counts the number 
	 * of times each function is on the stack.  It is only used if 
	 * profileStyle == PROFILE_CUMULATIVE.
	 */
 	uint *stackCount;
	ullong totalBytesAllocated;
} *GC_profileAlloc;

typedef struct GC_profileTime {
	/* ticks is an array of length sourcesSize that counts for each function
	 * the number of clock ticks that have happened while the function was
	 * on top of the stack (if profileStyle == PROFILE_CURRENT) or anywhere
	 * on the stack (if profileStyle == PROFILE_CUMULATIVE).
 	 * With a 32 bits, a counter cannot overflow for 2^32 / 100 seconds,
	 * or a bit over 1 CPU year. 
	 */
	uint *ticks;
	uint totalTicks;
} *GC_profileTime;

/* ------------------------------------------------- */
/*                      GC_heap                      */
/* ------------------------------------------------- */

/* Heap layout is as follows
 *
 *  ---------------------------------------------------
 * |    old generation    |   to space   |   nursery   |
 *  ---------------------------------------------------
 *
 * If not canMinor then the to space is empty, and the nursery starts
 * immediately after the old generation.
 */

typedef struct GC_heap {
	uint size;
	pointer start;		/* start of memory area */
} *GC_heap;

/* ------------------------------------------------- */
/*                     GC_state                      */
/* ------------------------------------------------- */

/* General note:
 *   stackBottom, stackLimit, and stackTop are computed from 
 *   s->currentThread->stack.  It is expected that the mutator side effects these
 *   directly rather than mucking with s->currentThread->stack.  Upon entering
 *   the runtime system, the GC will update s->currentThread->stack based on
 *   these values so that everything is consistent.
 */

typedef struct GC_state {
	/* These fields are at the front because they are the most commonly
	 * referenced, and having them at smaller offsets may decrease code size.
         */
	pointer frontier; 	/* base <= frontier < limit */
	pointer limit; 		/* end of from space */
	pointer stackTop;
	pointer stackLimit;	/* stackBottom + stackSize - maxFrameSize */

	bool amInGC;
	pointer back;     	/* Points at next available word in toSpace. */
	ullong bytesAllocated;
 	ullong bytesCopied;
	ullong bytesCopiedMinor;
	int bytesLive; /* Number of bytes live at most recent major GC. */
	ullong bytesMarkCompacted;
	bool canMinor; /* TRUE iff there is space for a minor gc. */
	pointer cardMap;
	pointer cardMapForMutator;
	uint cardMapSize;
	uint cardSize;
	uint cardSizeLog2;
	/* Only use generational GC with copying collection if the ratio of 
 	 * semispace size to live data size is below copyGenerationalRatio.
	 */
	float copyGenerationalRatio;
	float copyRatio;	/* Minimum live ratio to use copying GC. */
	GC_heap crossMapHeap;	/* only used during GC. */
	pointer crossMap;
	uint crossMapSize;
	/* currentSource is the index in sources of the currently executing
	 * function.   This is only used when allocation profiling with
	 * profileStyle = PROFILE_CURRENT;
	 */
	uint currentSource;
	GC_thread currentThread; /* This points to a thread in the heap. */
	uint fixedHeapSize; 	/* Only meaningful if useFixedHeap. */
	GC_frameLayout *frameLayouts;
	uint frameLayoutsSize;
	/* frameSources is an array of length frameLayoutsSize that for each
	 * stack frame, gives an index into sourceSeqs of the sequence of 
	 * source functions corresponding to the frame.
	 */
	uint *frameSources;
	uint frameSourcesSize;
	pointer *globals;
	uint globalsSize;
	float growRatio;
	struct GC_heap heap;
	struct GC_heap heap2;	/* Used for major copying collection. */
	bool inSignalHandler; 	/* TRUE iff a signal handler is running. */
	/* canHandle == 0 iff GC may switch to the signal handler
 	 * thread.  This is used to implement critical sections.
	 */
	struct GC_intInfInit *intInfInits;
	volatile int canHandle;
	bool isOriginal;
	pointer limitPlusSlop; /* limit + LIMIT_SLOP */
	float liveRatio;	/* Desired ratio of heap size to live data. */
	/* loadGlobals loads the globals from the stream. */
	void (*loadGlobals)(FILE *file);
	uint magic; /* The magic number for this executable. */
	/* Minimum live ratio to us mark-compact GC. */
	float markCompactRatio; 
	ullong markedCards; /* Number of marked cards seen during minor GCs. */
	/* Only use generational GC with mark-compact collection if the ratio of 
 	 * heap size to live data size is below markCompactGenerationalRatio.
	 */
	float markCompactGenerationalRatio;
	uint maxBytesLive;
	uint maxFrameSize;
	uint maxHeap; /* if zero, then unlimited, else limit total heap */
	uint maxHeapSizeSeen;
	uint maxPause;		/* max time spent in any gc in milliseconds. */
	uint maxStackSizeSeen;
	bool messages; /* Print out a message at the start and end of each gc. */
	ullong minorBytesScanned;
	ullong minorBytesSkipped;
	bool mutatorMarksCards;
	/* native is true iff the native codegen was used.
	 * The GC needs to know this because it affects how it finds the
	 * layout of stack frames.
 	 */
	bool native;
	uint numCopyingGCs;
 	ullong numLCs;
 	uint numMarkCompactGCs;
	uint numMinorGCs;
	uint numMinorsSinceLastMajor;
	/* As long as the ratio of bytes live to nursery size is greater than
	 * nurseryRatio, use minor GCs.
	 */
	float nurseryRatio;
	pointer nursery;
	uint nurserySize;
	GC_ObjectType *objectTypes; /* Array of object types. */
	uint objectTypesSize;
	/* Arrays larger than oldGenArraySize are allocated in the old generation
	 * instead of the nursery, if possible.
	 */
	W32 oldGenArraySize; 
	uint oldGenSize;
	uint pageSize; /* bytes */
	GC_profileAlloc profileAlloc;
	bool profileAllocIsOn;
	ProfileStyle profileStyle;
	GC_profileTime profileTime;
	bool profileTimeIsOn;
	W32 ram;		/* ramSlop * totalRam */
	float ramSlop;
 	struct rusage ru_gc; /* total resource usage spent in gc */
	struct rusage ru_gcCopy; /* resource usage in major copying gcs. */
	struct rusage ru_gcMarkCompact; /* resource usage in mark-compact gcs. */
	struct rusage ru_gcMinor; /* resource usage in minor gcs. */
	/* savedThread is only set
         *    when executing a signal handler.  It is set to the thread that
	 *    was running when the signal arrived.
         * GC_copyCurrentThread also uses it to store its result.
	 */
	GC_thread savedThread;
	/* saveGlobals writes out the values of all of the globals to fd. */
	void (*saveGlobals)(int fd);
	/* serializeStart holds the frontier at the start of the serialized
         * object during object serialization.
         */
	pointer serializeStart;
	GC_thread signalHandler; /* The mutator signal handler thread. */
	sigset_t signalsHandled; /* The signals handler expects to be handled. */
	/* signalIsPending is TRUE iff a signal has been received but not
	 * processed by the mutator signal handler.
	 */
	volatile bool signalIsPending;
	/* The signals that have been recieved but not processed by the mutator
	 * signal handler.
	 */
	sigset_t signalsPending;
	/* sourceIsOnStack is an array of bools of length sourcesSize.  It is
	 * used during stack walking (when time profiling with
	 * profileStyle == PROFILE_CUMULATIVE) to count each source function
	 * only once no matter how many times it appears on the stack.
 	 */
	char *sourceIsOnStack;
	struct GC_sourceLabel *sourceLabels;
	uint sourceLabelsSize;
	/* sources is an array of strings identifying source positions. */
	string *sources;
	uint sourcesSize;
	/* Each entry in sourceSeqs is a vector, whose first element is
         * a length, and subsequent elements index into sources.
	 */
	int **sourceSeqs;
	uint sourceSeqsSize;
	pointer stackBottom; /* The bottom of the stack in the current thread. */
 	uint startTime; /* The time when GC_init or GC_loadWorld was called. */
        /* The inits array should be NULL terminated, 
         *    i.e.the final element should be {0, NULL, 0}.
         */
	struct GC_stringInit *stringInits;
	/* If summary is TRUE, then print a summary of gc info when the program 
	 * is done .
	 */
	bool summary; 
	pointer textEnd;
	/* An array of indices, one entry for each address in the text segment,
	 * giving and index into profileSourceSeqs.
	 */
	uint *textSources;
	pointer textStart;
	pointer toSpace;	/* used during copying */
	pointer toLimit;	/* used during copying */
	uint totalRam;		/* bytes */
	uint totalSwap; 	/* bytes */
	uint translateDiff;	/* used by translateHeap */
 	bool translateUp;	/* used by translateHeap */
	bool useFixedHeap; 	/* if true, then don't resize the heap */
} *GC_state;

static inline uint wordAlign(uint p) {
 	return ((p + 3) & ~ 3);
}

static inline bool isWordAligned(uint x) {
	return 0 == (x & 0x3);
}

/*
 * fixedGetrusage() works just like getrusage() except that it actually works.
 * I.e., it does not suffer from the Linux kernel bugs associated with the user
 * and system times.
 */
int fixedGetrusage(int who, struct rusage *rup);

/* ---------------------------------------------------------------- */
/*                           GC functions                           */
/* ---------------------------------------------------------------- */

/* Allocate an array with the specified header and number of elements.
 * Also ensure that frontier + bytesNeeded < limit after the array is allocated.
 */
pointer GC_arrayAllocate (GC_state s, W32 bytesNeeded, W32 numElts, W32 header);

/* The array size is stored before the header */
static inline uint* GC_arrayNumElementsp (pointer a) {
	return ((uint*)a - 2);
}

static inline int GC_arrayNumElements (pointer a) {
	return *(GC_arrayNumElementsp (a));
}

/* GC_copyThread (s, t) returns a copy of the thread pointed to by t.
 */
pointer GC_copyThread (GC_state s, pointer t);

/* GC_copyThread (s) stores a copy of the current thread, s->currentThread
 * in s->savedThread.  See the comment in basis-library/misc/primitive.sml for
 * why it's a bad idea to have copyCurrentThread return the copy directly.
 */
void GC_copyCurrentThread (GC_state s);

/* GC_deseralize returns the deserialization of the word8vector. */
/* pointer GC_deserialize (GC_state s, pointer word8vector); */

/* GC_display (s, str) prints out the state s to stream str. */
void GC_display (GC_state s, FILE *stream);

/* GC_done should be called after the program is done.
 * munmaps heap and stack.
 * Prints out gc statistics if s->summary is set.
 */
void GC_done (GC_state s);

/* GC_finishHandler should be called by the mutator signal handler thread when
 * it is done handling the signal.
 */
void GC_finishHandler (GC_state s);

/* GC_foreachStackFrame (s, f) applies f to the frameLayout index of each frame
 * in the stack.
 */
void GC_foreachStackFrame (GC_state s, void (*f) (GC_state s, uint i));

/* GC_gc does a gc.
 * This will also resize the stack if necessary.
 * It will also switch to the signal handler thread if there is a pending signal.
 */
void GC_gc (GC_state s, uint bytesRequested, bool force,
		string file, int line);

/* GC_getHeaderp returns a pointer to the header for the object pointed to by 
 * p. 
 */
static inline Header* GC_getHeaderp (pointer p) {
	return (Header*)(p - WORD_SIZE);
}

/* GC_gerHeader returns the header for the object pointed to by p. */
static inline Header GC_getHeader (pointer p) {
	return *(GC_getHeaderp(p));
}

/* GC_handler is the baked-in C signal handler. 
 * It causes the next limit check to fail by setting s->limit to zero.
 * This, in turn, will cause the GC to run the SML signal handler.
 */
void GC_handler (GC_state s, int signum);

void GC_incProfileAlloc (GC_state s, W32 amount);

/* GC_init must be called before doing any allocation.
 * It processes command line arguments, creates the heap, initializes the global
 * strings and intInfs.
 *
 * Before calling GC_init, you must initialize:
 *   fixedHeapSize
 *   frameLayouts
 *   globals 
 *   intInfInits
 *   loadGlobals
 *   magic
 *   maxFrameSize
 *   maxObjectTypeIndex
 *   native
 *   numFrameLayouts
 *   numGlobals
 *   objectTypes
 *   saveGlobals
 *   stringInits
 *   useFixedHeap
 *
 * GC_init returns the index of the first non-runtime command-line arg.
 */
int GC_init (GC_state s, int argc, char **argv);

/* GC_isPointer returns true if p looks like a pointer, i.e. if p = 0 mod 4. */
static inline bool GC_isPointer (pointer p) {
	return (0 == ((word)p & 0x3));
}

static inline bool GC_isValidFrontier (GC_state s, pointer frontier) {
	return s->nursery <= frontier and frontier <= s->limit;
}

static inline bool GC_isValidSlot (GC_state s, pointer slot) {
	return s->stackBottom <= slot 
		and slot < s->stackBottom + s->currentThread->stack->reserved;
}

/* Write a profile data array out to a file descriptor.
 *
 * The `unknown ticks' is a count of the number of times that the monitored
 * program counter was not in the range of a bin.  This almost certainly
 * corresponds to times when it was pointing at shared library code.
 */
void GC_profileAllocFree (GC_state s, GC_profileAlloc pa);
GC_profileAlloc GC_profileAllocNew (GC_state s);
void GC_profileAllocWrite (GC_state s, GC_profileAlloc pa, int fd);
void GC_profileTimeFree (GC_state s, GC_profileTime pt);
GC_profileTime GC_profileTimeNew (GC_state s);
void GC_profileTimeWrite (GC_state s, GC_profileTime pt, int fd);

/*
 * Build the header for an object, given the index to its type info.
 */
static inline word GC_objectHeader (W32 t) {
	assert (t < TWOPOWER (TYPE_INDEX_BITS));
	return 1 | (t << 1);
}

/* Pack the heap into a small amount of RAM. */
void GC_pack (GC_state s);

void GC_profile (GC_state s, uint sourceSeqsIndex);

/* Write out the current world to the file descriptor. */
void GC_saveWorld (GC_state s, int fd);

/* Return a serialized version of the object rooted at root. */
/* pointer GC_serialize(GC_state s, pointer root); */

/* Return the amount of heap space taken by the object pointed to by root. */
uint GC_size (GC_state s, pointer root);

/* Returns an array of indices corresponding to the current frames on the stack.
 * The array is terminated by 0xFFFFFFFF.
 */
word *GC_stackFrameIndices (GC_state s);

/* GC_startHandler should be called by the mutator just before switching to
 * the signal handler thread.
 */
void GC_startHandler (GC_state s);

void GC_switchToThread (GC_state s, GC_thread t);

#endif /* #ifndef _MLTON_GC_H */
