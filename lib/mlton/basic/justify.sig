(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type int = Int.t
   
signature JUSTIFY =
   sig
      datatype t =
	 Left
       | Center
       | Right

      val justify: string * int * t -> string
      val outputTable: string list list * Out.t -> unit
      val table: {justs: t list,
		  rows: string list list} -> string list list
   end
