#include <stdio.h>
#include <gc.h>
#include "gdtoa.h"
#include "mlton-basis.h"
#include "my-lib.h"

enum {
	DEBUG = FALSE,
};

#if (defined (__i386__))
#define _0 1
#define _1 0

#elif (defined (__sparc__))
#define _0 0
#define _1 1

#else
#error unknown endianness
#endif

/* This code is patterned on g_dfmt from the gdtoa sources. */
char * Real_gdtoa (double d, int mode, int ndig, int *decpt) {
	ULong bits[2];
	int ex;
	static FPI fpi = { 53, 1-1023-53+1, 2046-1023-53+1, 1, 0 };
	int i;
	ULong *L;
	char *result;
	ULong sign;

	L = (ULong*)&d;
	sign = L[_0] & 0x80000000L;
	bits[0] = L[_1];
	bits[1] = L[_0] & 0xfffff;
	if ( (ex = (L[_0] >> 20) & 0x7ff) !=0)
		bits[1] |= 0x100000;
	else
		ex = 1;
	ex -= 0x3ff + 52;
	i = STRTOG_Normal;
	result = gdtoa (&fpi, ex, bits, &i, mode, ndig, decpt, NULL);
	if (DEBUG)
		fprintf (stderr, "%s = gdtoa (%g, %d, %d)   decpt = %d\n", 
				result, d, mode, ndig, *decpt);
	return result;
}
