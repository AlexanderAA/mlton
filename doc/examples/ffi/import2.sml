(* main.sml *)

(* Declare ffi to be implemented by calling the C function ffi. *)
val ffi_addr = _import # "ffi" : MLton.Pointer.t;
val ffi_schema = _import * : MLton.Pointer.t -> real array * int ref * int -> char;
open Array

(* val size = _const "FFI_SIZE": int; *)
val size = 10
val a = tabulate (size, fn i => real i)
val r = ref 0
val n = 17

(* Call the C function *)
val c = ffi_schema ffi_addr (a, r, n)

val _ =
   print (if c = #"c" andalso !r = 45
	     then "success\n"
	  else "fail\n")

val n = _import "FFI_INT": int;
val _ = print (concat [Int.toString n, "\n"])
val w = _import "FFI_WORD": word;
val _ = print (concat [Word.toString w, "\n"])
val b = _import "FFI_BOOL": bool;
val _ = print (concat [Bool.toString b, "\n"])
val r = _import "FFI_REAL": real;
val _ = print (concat [Real.toString r, "\n"])

signature OPAQUE =
   sig
      type t
      val toString : t -> string
   end

structure OpaqueInt :> OPAQUE =
   struct
      type t = Int.int
      val toString = Int.toString
   end
structure OpaqueWord :> OPAQUE =
   struct
      type t = Word.word
      val toString = Word.toString
   end
structure OpaqueBool :> OPAQUE =
   struct
      type t = Bool.bool
      val toString = Bool.toString
   end
structure OpaqueReal :> OPAQUE =
   struct
      type t = Real.real
      val toString = Real.toString
   end

val n = _import "FFI_INT": OpaqueInt.t;
val _ = print (concat [OpaqueInt.toString n, "\n"])
val w = _import "FFI_WORD": OpaqueWord.t;
val _ = print (concat [OpaqueWord.toString w, "\n"])
val b = _import "FFI_BOOL": OpaqueBool.t;
val _ = print (concat [OpaqueBool.toString b, "\n"])
val r = _import "FFI_REAL": OpaqueReal.t;
val _ = print (concat [OpaqueReal.toString r, "\n"])

val n_addr = _import # "FFI_INT": MLton.Pointer.t;
val n = MLton.Pointer.getInt32 (n_addr, 0);
val _ = print (concat [Int.toString n, "\n"])
val w_addr = _import # "FFI_WORD": MLton.Pointer.t;
val w = MLton.Pointer.getWord32 (w_addr, 0);
val _ = print (concat [Word.toString w, "\n"])
val b_addr = _import # "FFI_BOOL": MLton.Pointer.t;
val b = (MLton.Pointer.getInt32 (n_addr, 0)) <> 0
val _ = print (concat [Bool.toString b, "\n"])
val r_addr = _import # "FFI_REAL": MLton.Pointer.t;
val r = MLton.Pointer.getReal64 (r_addr, 0)
val _ = print (concat [Real.toString r, "\n"])
