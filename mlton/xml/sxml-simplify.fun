(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
functor SxmlSimplify (S: SXML_SIMPLIFY_STRUCTS): SXML_SIMPLIFY = 
struct

open S

structure ImplementExceptions = ImplementExceptions (open S)
structure Polyvariance = Polyvariance (open S)
structure Uncurry = Uncurry (open S)

fun traces s p = (Trace.Immediate.on s; p)

val passes =
   [
    ("sxmlShrink1", S.shrink),
    ("implementExceptions", ImplementExceptions.doit),
    ("sxmlShrink2", S.shrink),
(*
    ("uncurry", Uncurry.uncurry),
    ("sxmlShrink3", S.shrink),
*)
    ("polyvariance", Polyvariance.duplicate)
   ]
   
fun stats p =
   Control.message (Control.Detail, fn () => Program.layoutStats p)

fun simplify p =
   (stats p
    ; (List.fold
       (passes, p, fn ((name, pass), p) =>
      if List.exists (!Control.dropPasses, fn re =>
		      Regexp.Compiled.matchesAll (re, name))
         then p
      else
         let
            val _ =
	       let
		  open Control
	       in maybeSaveToFile
		  ({name = name, suffix = "pre.sxml"},
		   Control.No, p, Control.Layout Program.layout)
	       end
            val p =
               Control.passTypeCheck
               {name = name,
                suffix = "post.sxml",
                style = Control.No,
                thunk = fn () => pass p,
                display = Control.Layout Program.layout,
                typeCheck = typeCheck}
            val _ = stats p
         in
            p
         end)))

val typeCheck = S.typeCheck

val simplify = fn p => let
			 (* Always want to type check the initial and final XML
			  * programs, even if type checking is turned off, just
			  * to catch bugs.
			  *)
			 val _ = typeCheck p
			 val p' = simplify p
			 val _ = typeCheck p'
		       in
			 p'
		       end

end
