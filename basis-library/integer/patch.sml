(* Copyright (C) 1997-1999 NEC Research Institute.
 * Please see the file LICENSE for license information.
 *)
(* Patch in fromLarge and toLarge now that IntInf is defined.
 *)

structure Int32: INTEGER_EXTRA =
   struct
      open Int32

      val fromLarge = IntInf.toInt
      val toLarge = IntInf.fromInt
   end

structure Int = Int32

structure Word8: WORD_EXTRA =
   struct
      open Word8

      val toLargeIntX = IntInf.fromInt o toIntX
      val toLargeInt = IntInf.fromInt o toInt

     fun fromLargeInt (i: IntInf.int): word =
	fromInt (IntInf.toInt (IntInf.mod (i, 256)))
   end

structure Word32: WORD32_EXTRA =
   struct
      open Word32

      val toLargeIntX = IntInf.fromInt o toIntX

      fun highBitSet w = w >= 0wx80000000

      fun toLargeInt (w: word): LargeInt.int =
	 if highBitSet w
	    then IntInf.+ (IntInf.bigIntConstant 0x80000000,
			   toLargeIntX (andb (w, 0wx7FFFFFFF)))
	 else toLargeIntX w

      fun toReal (w: word): real =
	 if highBitSet w
	    then
	       Real.+ (2147483648.0, (* 2 ^ 31 *)
		       Real.fromInt (toIntX (andb (w, 0wx7FFFFFFF))))
	 else Real.fromInt (toIntX w)

      local
	 val t32 = IntInf.pow (2, 32)
	 val t31 = IntInf.pow (2, 31)
      in
	 fun fromLargeInt (i: IntInf.int): word =
	    fromInt
	    (let open IntInf
		 val low32 = i mod t32
	     in toInt (if low32 >= t31
			 then low32 - t32
		      else low32)
	     end)
      end
   end

structure Word = Word32
structure LargeWord = Word32
structure SysWord = Word32
