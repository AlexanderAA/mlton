(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
functor MonoVector(type elem): MONO_VECTOR_EXTRA =
   struct
      open Vector
      type elem = elem
      type vector = elem vector
      structure MonoVectorSlice = 
	 struct
	    open VectorSlice
	    type elem = elem
	    type vector = elem vector
	    type slice = elem slice
	 end
   end
