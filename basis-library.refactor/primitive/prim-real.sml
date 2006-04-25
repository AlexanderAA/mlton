(* Copyright (C) 1999-2006 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

(* Primitive names are special -- see atoms/prim.fun. *)

signature PRIM_REAL =
   sig
      type real
      type t = real

      val realSize: Primitive.Int32.int
      val precision: Primitive.Int32.int
      val radix: Primitive.Int32.int

      structure Math :
         sig
            type real

            val acos: real -> real
            val asin: real -> real
            val atan: real -> real
            val atan2: real * real -> real
            val cos: real -> real
            val cosh: real -> real
            val e: real
            val exp: real -> real
            val ln: real -> real
            val log10: real -> real
            val pi: real
            val pow: real * real -> real
            val sin: real -> real
            val sinh: real -> real
            val sqrt: real -> real
            val tan: real -> real
            val tanh: real -> real
         end

      val * : real * real -> real
      val *+ : real * real * real -> real
      val *- : real * real * real -> real
      val + : real * real -> real
      val - : real * real -> real
      val / : real * real -> real
      val ~ : real -> real
      val < : real * real -> bool
      val <= : real * real -> bool
      val == : real * real -> bool
      val ?= : real * real -> bool
      val abs: real -> real
      val class: real -> C_Int.t
      val frexp: real * C_Int.t ref -> real
      val gdtoa: real * C_Int.t * C_Int.t * C_Int.t ref -> C_String.t
      val ldexp: real * C_Int.t -> real
      val maxFinite: real
      val minNormalPos: real
      val minPos: real
      val modf: real * real ref -> real
      val nextAfter: real * real -> real
      val round: real -> real
      val signBit: real -> C_Int.t
      val strto: Primitive.NullString8.t -> real

      (* Integer to float; depends on rounding mode. *)
      val fromInt8Unsafe: Primitive.Int8.int -> real
      val fromInt16Unsafe: Primitive.Int16.int -> real
      val fromInt32Unsafe: Primitive.Int32.int -> real
      val fromInt64Unsafe: Primitive.Int64.int -> real

      (* Float to float; depends on rounding mode. *)
      val fromReal32Unsafe: Primitive.Real32.real -> real
      val fromReal64Unsafe: Primitive.Real64.real -> real

      (* Float to integer, taking lowbits. *)
      val toInt8Unsafe: real -> Primitive.Int8.int
      val toInt16Unsafe: real -> Primitive.Int16.int
      val toInt32Unsafe: real -> Primitive.Int32.int
      val toInt64Unsafe: real -> Primitive.Int64.int

      (* Float to float; depends on rounding mode. *)
      val toReal32Unsafe: real -> Primitive.Real32.real
      val toReal64Unsafe: real -> Primitive.Real64.real
   end

structure Primitive = struct

open Primitive

structure Real32 : PRIM_REAL  =
   struct
      open Real32
         
      val realSize : Int32.int = 32
      val precision : Int32.int = 24
      val radix : Int32.int = 2

      structure Math =
         struct
            type real = real
               
            val acos = _prim "Real32_Math_acos": real -> real;
            val asin = _prim "Real32_Math_asin": real -> real;
            val atan = _prim "Real32_Math_atan": real -> real;
            val atan2 = _prim "Real32_Math_atan2": real * real -> real;
            val cos = _prim "Real32_Math_cos": real -> real;
            val cosh = _import "Real32_Math_cosh": real -> real;
            val e = #1 _symbol "Real32_Math_e": real GetSet.t; ()
            val exp = _prim "Real32_Math_exp": real -> real;
            val ln = _prim "Real32_Math_ln": real -> real;
            val log10 = _prim "Real32_Math_log10": real -> real;
            val pi = #1 _symbol "Real32_Math_pi": real GetSet.t; ()
            val pow = _import "Real32_Math_pow": real * real -> real;
            val sin = _prim "Real32_Math_sin": real -> real;
            val sinh = _import "Real32_Math_sinh": real -> real;
            val sqrt = _prim "Real32_Math_sqrt": real -> real;
            val tan = _prim "Real32_Math_tan": real -> real;
            val tanh = _import "Real32_Math_tanh": real -> real;
         end
      
      val * = _prim "Real32_mul": real * real -> real;
      val *+ = _prim "Real32_muladd": real * real * real -> real;
      val *- = _prim "Real32_mulsub": real * real * real -> real;
      val + = _prim "Real32_add": real * real -> real;
      val - = _prim "Real32_sub": real * real -> real;
      val / = _prim "Real32_div": real * real -> real;
      val ~ = _prim "Real32_neg": real -> real;
      val op < = _prim "Real32_lt": real * real -> bool;
      val op <= = _prim "Real32_le": real * real -> bool;
      val == = _prim "Real32_equal": real * real -> bool;
      val ?= = _prim "Real32_qequal": real * real -> bool;
      val abs = _prim "Real32_abs": real -> real;
      val class = _import "Real32_class": real -> C_Int.t;
      val frexp = _import "Real32_frexp": real * C_Int.t ref -> real;
      val gdtoa = _import "Real32_gdtoa": real * C_Int.t * C_Int.t * C_Int.t ref -> C_String.t;
      val ldexp = _prim "Real32_ldexp": real * C_Int.t -> real;
      val maxFinite = #1 _symbol "Real32_maxFinite": real GetSet.t; ()
      val minNormalPos = #1 _symbol "Real32_minNormalPos": real GetSet.t; ()
      val minPos = #1 _symbol "Real32_minPos": real GetSet.t; ()
      val modf = _import "Real32_modf": real * real ref -> real;
      val nextAfter = _import "Real32_nextAfter": real * real -> real;
      val round = _prim "Real32_round": real -> real;
      val signBit = _import "Real32_signBit": real -> C_Int.t;
      val strto = _import "Real32_strto": NullString8.t -> real;

      val fromInt8Unsafe = _prim "WordS8_toReal32": Int8.int -> real;
      val fromInt16Unsafe = _prim "WordS16_toReal32": Int16.int -> real;
      val fromInt32Unsafe = _prim "WordS32_toReal32": Int32.int -> real;
      val fromInt64Unsafe = _prim "WordS64_toReal32": Int64.int -> real;

      val fromReal32Unsafe = _prim "Real32_toReal32": Real32.real -> real;
      val fromReal64Unsafe = _prim "Real64_toReal32": Real64.real -> real;

      val toInt8Unsafe = _prim "Real32_toWordS8": real -> Int8.int;
      val toInt16Unsafe = _prim "Real32_toWordS16": real -> Int16.int;
      val toInt32Unsafe = _prim "Real32_toWordS32": real -> Int32.int;
      val toInt64Unsafe = _prim "Real32_toWordS64": real -> Int64.int;

      val toReal32Unsafe = _prim "Real32_toReal32": real -> Real32.real;
      val toReal64Unsafe = _prim "Real32_toReal64": real -> Real64.real;
   end
structure Real32 =
   struct
      open Real32
      local
         structure S = RealComparisons (Real32)
      in
         open S
      end
   end

structure Real64 : PRIM_REAL =
   struct
      open Real64

      val realSize : Int32.int = 64
      val precision : Int32.int = 53
      val radix : Int32.int = 2
         
      structure Math =
         struct
            type real = real
               
            val acos = _prim "Real64_Math_acos": real -> real;
            val asin = _prim "Real64_Math_asin": real -> real;
            val atan = _prim "Real64_Math_atan": real -> real;
            val atan2 = _prim "Real64_Math_atan2": real * real -> real;
            val cos = _prim "Real64_Math_cos": real -> real;
            val cosh = _import "Real64_Math_cosh": real -> real;
            val e = #1 _symbol "Real64_Math_e": real GetSet.t; ()
            val exp = _prim "Real64_Math_exp": real -> real;
            val ln = _prim "Real64_Math_ln": real -> real;
            val log10 = _prim "Real64_Math_log10": real -> real;
            val pi = #1 _symbol "Real64_Math_pi": real GetSet.t; ()
            val pow = _import "Real64_Math_pow": real * real -> real;
            val sin = _prim "Real64_Math_sin": real -> real;
            val sinh = _import "Real64_Math_sinh": real -> real;
            val sqrt = _prim "Real64_Math_sqrt": real -> real;
            val tan = _prim "Real64_Math_tan": real -> real;
            val tanh = _import "Real64_Math_tanh": real -> real;
         end
      
      val * = _prim "Real64_mul": real * real -> real;
      val *+ = _prim "Real64_muladd": real * real * real -> real;
      val *- = _prim "Real64_mulsub": real * real * real -> real;
      val + = _prim "Real64_add": real * real -> real;
      val - = _prim "Real64_sub": real * real -> real;
      val / = _prim "Real64_div": real * real -> real;
      val ~ = _prim "Real64_neg": real -> real;
      val op < = _prim "Real64_lt": real * real -> bool;
      val op <= = _prim "Real64_le": real * real -> bool;
      val == = _prim "Real64_equal": real * real -> bool;
      val ?= = _prim "Real64_qequal": real * real -> bool;
      val abs = _prim "Real64_abs": real -> real;
      val class = _import "Real64_class": real -> C_Int.t;
      val frexp = _import "Real64_frexp": real * C_Int.t ref -> real;
      val gdtoa = _import "Real64_gdtoa": real * C_Int.t * C_Int.t * C_Int.t ref -> C_String.t;
      val ldexp = _prim "Real64_ldexp": real * C_Int.t -> real;
      val maxFinite = #1 _symbol "Real64_maxFinite": real GetSet.t; ()
      val minNormalPos = #1 _symbol "Real64_minNormalPos": real GetSet.t; ()
      val minPos = #1 _symbol "Real64_minPos": real GetSet.t; ()
      val modf = _import "Real64_modf": real * real ref -> real;
      val nextAfter = _import "Real64_nextAfter": real * real -> real;
      val round = _prim "Real64_round": real -> real;
      val signBit = _import "Real64_signBit": real -> C_Int.t;
      val strto = _import "Real64_strto": NullString8.t -> real;

      val fromInt8Unsafe = _prim "WordS8_toReal64": Int8.int -> real;
      val fromInt16Unsafe = _prim "WordS16_toReal64": Int16.int -> real;
      val fromInt32Unsafe = _prim "WordS32_toReal64": Int32.int -> real;
      val fromInt64Unsafe = _prim "WordS64_toReal64": Int64.int -> real;

      val fromReal32Unsafe = _prim "Real32_toReal64": Real32.real -> real;
      val fromReal64Unsafe = _prim "Real64_toReal64": Real64.real -> real;

      val toInt8Unsafe = _prim "Real64_toWordS8": real -> Int8.int;
      val toInt16Unsafe = _prim "Real64_toWordS16": real -> Int16.int;
      val toInt32Unsafe = _prim "Real64_toWordS32": real -> Int32.int;
      val toInt64Unsafe = _prim "Real64_toWordS64": real -> Int64.int;

      val toReal32Unsafe = _prim "Real64_toReal32": real -> Real32.real;
      val toReal64Unsafe = _prim "Real64_toReal64": real -> Real64.real;
   end
structure Real64 =
   struct
      open Real64
      local
         structure S = RealComparisons (Real64)
      in
         open S
      end
   end

end
