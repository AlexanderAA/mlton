(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
functor Const (S: CONST_STRUCTS): CONST = 
struct

open S

local
   open Ast
in
   structure Aconst = Const
end
local
   open IntX
in
   structure IntSize = IntSize
end
local
   open WordX
in
   structure WordSize = WordSize
end

datatype z = datatype IntSize.t
datatype z = datatype WordSize.t

structure SmallIntInf =
   struct
      structure Word = Pervasive.Word
      (*
       * The IntInf.fromInt calls are just because SML/NJ doesn't
       * overload integer constants for IntInf.int's.
       * This code relies on the language that MLton is implemented in using at
       * least 31 bits for integers.
       *)
      val minSmall: IntInf.t = IntInf.fromInt ~0x40000000
      val maxSmall: IntInf.t = IntInf.fromInt 0x3FFFFFFF

      fun isSmall (i: IntInf.t): bool =
	 let open IntInf
	 in minSmall <= i andalso i <= maxSmall
	 end

      fun toWord (i: IntInf.t): word option =
	 if isSmall i
	    then SOME (Word.orb (0w1,
				 Word.<< (Word.fromInt (IntInf.toInt i),
					  0w1)))
	 else NONE

      fun fromWord (w: word): IntInf.t =
	 IntInf.fromInt (Word.toIntX (Word.~>> (w, 0w1)))
   end

datatype t =
   Int of IntX.t
 | IntInf of IntInf.t
 | Real of RealX.t
 | Word of WordX.t
 | Word8Vector of Word8.t vector

val int = Int
val real = Real
val intInf = IntInf
val word = Word
val word8Vector = Word8Vector

val word8 = word o WordX.fromWord8 
val string = word8Vector o Word8.stringToVector
   
local
   open Layout
   fun wrap (pre, post, s) = seq [str pre, String.layout s, str post]
in
   val layout =
      fn Int i => IntX.layout i
       | IntInf i => IntInf.layout i
       | Real r => RealX.layout r
       | Word w => WordX.layout w
       | Word8Vector v => wrap ("\"", "\"", Word8.vectorToString v)
end	 

val toString = Layout.toString o layout

local
   val truee = Random.word ()
   val falsee = Random.word ()
in
   fun hash (c: t): word =
      case c of
	 Int i => String.hash (IntX.toString i)
       | IntInf i => String.hash (IntInf.toString i)
       | Real r => RealX.hash r
       | Word w => WordX.toWord w
       | Word8Vector v => String.hash (Word8.vectorToString v)
end
   
fun 'a toAst (make: Ast.Const.t -> 'a, constrain: 'a * Ast.Type.t -> 'a) c =
   let
      val aconst =
	 case c of
	    Int i => Aconst.Int (IntX.toIntInf i)
	  | IntInf i => Aconst.Int i
	  | Real r => Aconst.Real (RealX.toString r)
	  | Word w => Aconst.Word (WordX.toIntInf w)
	  | Word8Vector v => Aconst.String (Word8.vectorToString v)
   in
      make (Ast.Const.makeRegion (aconst, Region.bogus))
   end

val toAstExp = toAst (Ast.Exp.const, Ast.Exp.constraint)
val toAstPat = toAst (Ast.Pat.const, Ast.Pat.constraint)

fun equals (c, c') =
   case (c, c') of
      (Int i, Int i') => IntX.equals (i, i')
    | (IntInf i, IntInf i') => IntInf.equals (i, i')
    | (Real r, Real r') => RealX.equals (r, r')
    | (Word w, Word w') => WordX.equals (w, w')
    | (Word8Vector v, Word8Vector v') => v = v'
    | _ => false

val equals = Trace.trace2 ("Const.equals", layout, layout, Bool.layout) equals
  
end
