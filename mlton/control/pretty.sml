structure Pretty: PRETTY =
struct

open Layout
	 
fun casee {default, rules, test} =
   align [seq [str "case ", test, str " of"],
	  indent (alignPrefix (Vector.toListMap
			       (rules, fn (lhs, rhs) =>
				mayAlign [seq [lhs, str " =>"], rhs]),
			       "| "),
		  2)]

fun conApp {arg, con, targs} =
   seq [con,
	if !Control.showTypes
	   then tuple (Vector.toList targs)
	else empty,
	case arg of
	   NONE => empty
	 | SOME x => seq [str " ", x]]

fun handlee {catch, handler, try} =
   align [try,
	  seq [str "handle ", catch, str " => ", handler]]

fun longid (ls, l) = seq (separate (ls @ [l], "."))
   
fun nest (prefix, x, y) =
   align [seq [str prefix, x],
	  str "in",
	  indent (y, 3),
	  str "end"]

fun lett (d, e) = nest ("let ", d, e)
	 
fun locall (d, d') = nest ("local ", d, d')

fun primApp {args, prim, targs} =
   seq [prim,
	if !Control.showTypes
	   andalso 0 < Vector.length targs
	   then list (Vector.toList targs)
	else empty,
	str " ",
	tuple (Vector.toList args)]

fun raisee exn = seq [str "raise ", exn]

fun var {targs, var} =
   if !Control.showTypes
      then seq [var, tuple (Vector.toList targs)]
   else var
      
fun seq es = mayAlign (separateLeft (Vector.toList es, ";"))

end
