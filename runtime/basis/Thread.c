#include "gc.h"
#include "mlton-basis.h"
#include "my-lib.h"

extern struct GC_state gcState;

enum {
	DEBUG_THREAD = FALSE,
};

Thread Thread_current () {
	Thread t;

	t = (Thread)gcState.currentThread;
	if (DEBUG_THREAD)
		fprintf (stderr, "0x%08x = Thread_current ()\n", (uint)t);
	return t;
}

void Thread_finishHandler () {
	GC_finishHandler (&gcState);
}

Thread Thread_saved () {
	Thread t;

	t = (Thread)gcState.savedThread;
	gcState.savedThread = (GC_thread)0x1;
	if (DEBUG_THREAD)
		fprintf (stderr, "0x%08x = Thread_saved ()\n", (uint)t);
	return t;
}

void Thread_setCallFromCHandler (Thread t) {
	gcState.callFromCHandler = (GC_thread)t;
}

void Thread_setSaved (Thread t) {
	if (DEBUG_THREAD)
		fprintf (stderr, "Thread_setSaved (0x%08x)\n", (uint)t);
	gcState.savedThread = (GC_thread)t;
}

void Thread_setHandler (Thread t) {
	gcState.signalHandler = (GC_thread)t;
}

void Thread_startHandler () {
	GC_startHandler (&gcState);
}

void Thread_switchTo (Thread thread, Word ensureBytesFree) {
	GC_state s;

	if (DEBUG_THREAD)
		fprintf (stderr, "Thread_switchTo (0x%08x, %u)\n",
				(uint)thread, (uint)ensureBytesFree);
	s = &gcState;
	s->currentThread->stack->used = s->stackTop - s->stackBottom;
	s->currentThread->bytesNeeded = ensureBytesFree;
	GC_switchToThread (s, (GC_thread)thread);
}
