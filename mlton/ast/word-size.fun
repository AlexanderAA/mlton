functor WordSize (S: WORD_SIZE_STRUCTS): WORD_SIZE =
struct

open S

datatype t = W8 | W16 | W32 | W64

val equals: t * t -> bool = op =

val all = [W8, W16, W32, W64]

val default = W32

fun pointer () = W32

val max: t -> LargeWord.t =
   fn W8 => Word.toLarge 0wxFF
    | W16 => Word.toLarge 0wxFFFF
    | W32 => Word.toLarge 0wxFFFFFFFF
    | W64 =>
	 (* Would like to write 0wxFFFFFFFFFFFFFFFF, but can't because SML/NJ
	  * doesn't have 64 bit words.
	  *)
	 let
	    open LargeWord
	 in
	    orb (<< (fromWord 0wxFFFFFFFF, 0w32),
		 fromWord 0wxFFFFFFFF)
	 end

val allOnes = max

val bits: t -> int =
   fn W8 => 8
    | W16 => 16
    | W32 => 32
    | W64 => 64

val bytes: t -> int = 
   fn W8 => 1
    | W16 => 2
    | W32 => 4
    | W64 => 8

val toString = Int.toString o bits

val memoize: (t -> 'a) -> t -> 'a =
   fn f =>
   let
      val a8 = f W8
      val a16 = f W16
      val a32 = f W32
      val a64 = f W64
   in
      fn W8 => a8
       | W16 => a16
       | W32 => a32
       | W64 => a64
   end
   
val cardinality = memoize (fn s => IntInf.pow (2, bits s))

end
