(* Copyright (C) 1999-2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

functor Integer (I: PRE_INTEGER_EXTRA) =
struct

open I
structure PI = Primitive.Int

val detectOverflow = Primitive.detectOverflow

val (toInt, fromInt) =
   if detectOverflow andalso
      precision' <> PI.precision'
      then if PI.<(precision', PI.precision')
	     then (I.toInt, 
		   fn i =>
		   if (PI.<= (I.toInt minInt', i)
		       andalso PI.<= (i, I.toInt maxInt'))
		      then I.fromInt i
		   else raise Overflow)
	     else (fn i => 
		   if (I.<= (I.fromInt PI.minInt', i)
		       andalso I.<= (i, I.fromInt PI.maxInt'))
		      then I.toInt i
		   else raise Overflow,
		   I.fromInt)
   else (I.toInt, I.fromInt)

val precision: Int.int option = SOME precision'

val maxInt: int option = SOME maxInt'
val minInt: int option = SOME minInt'

val one: int = fromInt 1
val zero: int = fromInt 0

fun quot (x, y) =
  if y = zero
    then raise Div
    else if detectOverflow andalso x = minInt' andalso y = ~one
	   then raise Overflow
	   else I.quot (x, y)
	     
fun rem (x, y) =
  if y = zero
    then raise Div
    else if x = minInt' andalso y = ~one
	   then zero
	   else I.rem (x, y)
   
fun x div y =
  if x >= zero
    then if y > zero
	   then I.quot (x, y)
	   else if y < zero
		  then if x = zero
			 then zero
			 else I.quot (x - one, y) -? one
		  else raise Div
    else if y < zero
	   then if detectOverflow andalso x = minInt' andalso y = ~one
		  then raise Overflow
		  else I.quot (x, y)
	   else if y > zero
		  then I.quot (x + one, y) -? one
		  else raise Div

fun x mod y =
  if x >= zero
    then if y > zero
	   then I.rem (x, y)
	   else if y < zero
		  then if x = zero
			 then zero
			 else I.rem (x - one, y) +? (y + one)
		  else raise Div
    else if y < zero
	   then if x = minInt' andalso y = ~one
		  then zero
		  else I.rem (x, y)
	   else if y > zero
		  then I.rem (x + one, y) +? (y - one)
		  else raise Div

val sign: int -> Int.int =
  fn i => if i = zero
	    then (0: Int.int)
	  else if i < zero
	    then (~1: Int.int)
	  else (1: Int.int)
	       
fun sameSign (x, y) = sign x = sign y
  
fun abs (x: int) = if x < zero then ~ x else x

val {compare, min, max} = Util.makeCompare (op <)

(* fmt constructs a string to represent the integer by building it into a
 * statically allocated buffer.  For the most part, this is a textbook
 * algorithm: loop starting at the end of the buffer; we use rem to
 * extract the next digit to put into the buffer; and we use quot to
 * figure out the part of the integer that we haven't yet formatted.
 * However, this function uses the negative absolute value of the input
 * number, which allows it to take into account minInt without any
 * special-casing.  This requires the rem function to behave in a very
 * specific way, or else things will go terribly wrong.  This may be a
 * concern when porting to platforms where the division hardware has a
 * different interpretation than SML about what happens when doing
 * division of negative numbers.
 *)
local
   (* Allocate a buffer large enough to hold any formatted integer in any radix.
    * The most that will be required is for minInt in binary.
    *)
   val maxNumDigits = PI.+ (precision', 1)
   val buf = CharArray.array (maxNumDigits, #"\000")
in
   fun fmt radix (n: int): string =
      let
	 val radix = fromInt (StringCvt.radixToInt radix)
	 fun loop (q, i: Int.int) =
	    let
	       val _ =
		  CharArray.update
		  (buf, i, StringCvt.digitToChar (toInt (~? (rem (q, radix)))))
	       val q = quot (q, radix)
	    in
	       if q = zero
		  then
		     let
			val start =
			   if n < zero
			      then
				 let
				    val i = PI.- (i, 1)
				    val () = CharArray.update (buf, i, #"~")
				 in
				    i
				 end
			   else i
		     in
			CharArraySlice.vector
			(CharArraySlice.slice (buf, start, NONE))
		     end
	       else loop (q, PI.- (i, 1))
	    end
      in
	 loop (if n < zero then n else ~? n, PI.- (maxNumDigits, 1))
      end
end      

val toString = fmt StringCvt.DEC
	 
fun scan radix reader state =
  let
    (* Works with the negative of the number so that minInt can
     * be scanned.
     *)
    val state = StringCvt.skipWS reader state
    fun charToDigit c =
      case StringCvt.charToDigit radix c of
	NONE => NONE
      | SOME n => SOME (fromInt n)
    val radixInt = fromInt (StringCvt.radixToInt radix)
    fun finishNum (state, n) =
      case reader state of
	NONE => SOME (n, state)
      | SOME (c, state') =>
	  case charToDigit c of
	    NONE => SOME (n, state)
	  | SOME n' => finishNum (state', n * radixInt - n')
    fun num state =
      case (reader state, radix) of
	(NONE, _) => NONE
      | (SOME (#"0", state), StringCvt.HEX) =>
	  (case reader state of
	     NONE => SOME (zero, state)
	   | SOME (c, state') =>
	       let
		 fun rest () =
		   case reader state' of
		     NONE => SOME (zero, state)
		   | SOME (c, state') =>
		       case charToDigit c of
			 NONE => SOME (zero, state)
		       | SOME n => finishNum (state', ~? n)
	       in case c of
		 #"x" => rest ()
	       | #"X" => rest ()
	       | _ => (case charToDigit c of
			 NONE => SOME (zero, state)
		       | SOME n => finishNum (state', ~? n))
	       end)
      | (SOME (c, state), _) =>
	     (case charToDigit c of
		NONE => NONE
	      | SOME n => finishNum (state, ~? n))
    fun negate state =
      case num state of
	NONE => NONE
      | SOME (n, s) => SOME (~ n, s)
  in case reader state of
    NONE => NONE
  | SOME (c, state') =>
      case c of
	#"~" => num state'
      | #"-" => num state'
      | #"+" => negate state'
      | _ => negate state
  end
      
val fromString = StringCvt.scanString (scan StringCvt.DEC)

fun power {base, exp} =
  if Primitive.safe andalso exp < zero
    then raise Fail "Int.power"
    else let
	   fun loop (exp, accum) =
	     if exp <= zero
	       then accum
	       else loop (exp - one, base * accum)
	 in loop (exp, one)
	 end
end

structure Int8 = Integer (Primitive.Int8)

structure Int16 = Integer (Primitive.Int16)

structure Int32 = Integer (Primitive.Int32)
structure Int = Int32
structure IntGlobal: INTEGER_GLOBAL = Int
open IntGlobal

structure Int64 = 
   struct
      local
	 structure P = Primitive.Int64
	 structure I = Integer (P)
      in
	 open I
	 val toWord = P.toWord
      end
   end
