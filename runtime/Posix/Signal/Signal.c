#include <signal.h>
#include <string.h>
#include "gc.h"
#include "mlton-posix.h"

extern struct GC_state gcState;

static void handler(Int signum) {
	GC_handler(&gcState, signum);
}

enum {
	SA_FLAGS = SA_ONSTACK,
};

Int Posix_Signal_default(Int signum) {
	struct sigaction sa;

	sigdelset(&gcState.signalsHandled, signum);
	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = SIG_DFL;
 	sa.sa_flags = SA_FLAGS;
	return sigaction(signum, &sa, NULL);
}

Int Posix_Signal_handle(int signum) {
	static struct sigaction sa;

	sigaddset(&gcState.signalsHandled, signum);
	memset(&sa, 0, sizeof(sa));
	/* The mask must be full because GC_handler reads and writes 
	 * s->signalsPending (else there is a race condition).
	 */
	sigfillset(&sa.sa_mask);
	sa.sa_handler = handler;
 	sa.sa_flags = SA_FLAGS;
	return sigaction(signum, &sa, NULL);
}

Int Posix_Signal_ignore(Int signum) {
	struct sigaction sa;

	sigdelset(&gcState.signalsHandled, signum);
	memset(&sa, 0, sizeof(sa));
	sa.sa_handler = SIG_IGN;
 	sa.sa_flags = SA_FLAGS;
	return sigaction(signum, &sa, NULL);
}

bool Posix_Signal_isDefault(Int signum) {
	struct sigaction sa;

 	sa.sa_flags = SA_FLAGS;
	sigaction(signum, NULL, &sa);
	return (sa.sa_handler == SIG_DFL);
}

static sigset_t set;

Int Posix_Signal_sigaddset(int signum) {
	return sigaddset(&set, signum);
}

Int Posix_Signal_sigemptyset() {
	return sigemptyset(&set);
}

Int Posix_Signal_sigfillset() {
	return sigfillset(&set);
}

Int Posix_Signal_sigprocmask(Int how) {
	return sigprocmask(how, &set, (sigset_t*)NULL);
}
