(* Copyright (C) 1999-2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type word = Word.t
   
signature CONST_STRUCTS = 
   sig
      structure RealX: REAL_X
      structure WordX: WORD_X
   end

signature CONST = 
   sig
      include CONST_STRUCTS

      structure SmallIntInf:
	 sig
	    val fromWord: word -> IntInf.t
	    val isSmall: IntInf.t -> bool
	    val toWord: IntInf.t -> word option
	 end

      datatype t =
	 IntInf of IntInf.t
       | Real of RealX.t
       | Word of WordX.t
       | Word8Vector of Word8.t vector

      val equals: t * t -> bool
      val intInf: IntInf.t -> t
      val hash: t -> word
      val layout: t -> Layout.t
      val real: RealX.t -> t
      val string: string -> t
      val toString: t -> string
      val word: WordX.t -> t
      val word8: Word8.t -> t
      val word8Vector: Word8.t vector -> t
   end
