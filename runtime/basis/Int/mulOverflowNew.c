#include "mlton-basis.h"

#include "my-lib.h"

Int Int_mulOverflowNew(Int lhs, Int rhs, Bool *overflow) {
	long long	tmp;

	tmp = (long long)lhs * rhs;
	*overflow = (tmp != (int)tmp);
	return tmp;
}
