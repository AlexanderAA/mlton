(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
functor MachineCases (S: MACHINE_CASES_STRUCTS): MACHINE_CASES = 
struct

open S

datatype t =
   Char of (char * Label.t) list
 | Int of (int * Label.t) list
 | Word of (word * Label.t) list

fun length c =
   case c of
      Char l => List.length l
    | Int l => List.length l
    | Word l => List.length l

fun fold (c, a, f) =
   let
      fun doit cs = List.fold (cs, a, fn ((_, l), a) => f (l, a))
   in
      case c of
	 Char cs => doit cs
       | Int cs => doit cs
       | Word cs => doit cs
   end

fun foreach (c, f) = fold (c, (), fn (l, ()) => f l)

fun forall (c, f) =
   let
      exception No
   in
      (foreach (c, fn x => if f x then () else raise No)
       ; true)
      handle No => false
   end

fun layout c =
   let
      fun doit (l, f) = List.layout (Layout.tuple2 (f, Label.layout)) l
   in
      case c of
	 Char l => doit (l, Char.layout)
       | Int l => doit (l, Int.layout)
       | Word l => doit (l, Word.layout)
   end

end
