
local
   open MLton.Profile
   open Data
in
   val topData = MLton.Profile.current ()
   val fibData = MLton.Profile.Data.malloc ()
   val takData = MLton.Profile.Data.malloc ()

   fun wrap (f, d) x =
      let
	 val d' = MLton.Profile.current ()
         val _ = MLton.Profile.setCurrent d
	 val res = f x
	 val _ = MLton.Profile.setCurrent d'
      in
	 res
      end
end

val rec fib =
   fn 0 => 0
    | 1 => 1
    | n => fib (n - 1) + fib (n - 2)
val fib = wrap (fib, fibData)

fun tak (x,y,z) =
   if not (y < x)
      then z
   else tak (tak (x - 1, y, z),
             tak (y - 1, z, x),
             tak (z - 1, x, y))
val tak = wrap (tak, takData)

val rec f =
   fn 0 => ()
    | n => (fib 38; f (n-1))
val _ = f 2

val rec g =
   fn 0 => ()
    | n => (tak (18,12,6); g (n-1))
val _ = g 500

val _ = MLton.Profile.Data.write (fibData, "mlmon.fib.out")
val _ = MLton.Profile.Data.free fibData
val _ = MLton.Profile.Data.write (takData, "mlmon.tak.out")
val _ = MLton.Profile.Data.free takData
(* topData written to mlmon.out at program exit. *)
