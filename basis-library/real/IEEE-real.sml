(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
structure IEEEReal: IEEE_REAL =
   struct
      exception Unordered
      datatype real_order = LESS | EQUAL | GREATER | UNORDERED

      datatype float_class =
	 NAN
       | INF
       | ZERO
       | NORMAL
       | SUBNORMAL
	 
      datatype rounding_mode =
	 TO_NEAREST
       | TO_NEGINF
       | TO_POSINF
       | TO_ZERO

      val intToRounding_mode: int -> rounding_mode =
	 fn 0 => TO_NEAREST
	  | 1 => TO_NEGINF
	  | 2 => TO_POSINF
	  | 3 => TO_ZERO
	  | _ => raise Fail "IEEEReal.intToRounding_mode"

      val rounding_modeToInt: rounding_mode -> int =
	 fn TO_NEAREST => 0
	  | TO_NEGINF => 1
	  | TO_POSINF => 2
	  | TO_ZERO => 3

      structure Prim = Primitive.IEEEReal

      val setRoundingMode = Prim.setRoundingMode o rounding_modeToInt
      val getRoundingMode = intToRounding_mode o Prim.getRoundingMode
	       
      type decimal_approx = {class: float_class,
			     sign: bool,
			     digits: int list,
			     exp: int}

      fun toString {class, sign, digits, exp}: string =
	 let
	    fun digitStr() = implode(map StringCvt.digitToChar digits)
	    fun norm() =
	       let val num = "0." ^ digitStr()
	       in if exp = 0
		     then num
		  else concat[num, "E", Int.toString exp]
	       end
	    val num =
	       case class of
		  ZERO => "0.0"
		| NORMAL => norm()
		| SUBNORMAL => norm()
		| INF => "inf"
		| NAN => "nan"
	 in if sign
	       then "~" ^ num
	    else num
	 end

      val scan = fn _ => raise (Fail "<IEEEReal.scan not implemented>")
      fun fromString s = StringCvt.scanString scan s
   end

