#include <sys/types.h>
#include <sys/socket.h>
#include "mlton-basis.h"
#include "my-lib.h"

Int Socket_send(Int s, Char *msg, Int start, Int len, Word flags) {
	return send(s, (void*)((char *)msg + start), (size_t)len, flags);
}
