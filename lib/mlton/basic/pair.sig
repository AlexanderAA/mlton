(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

signature PAIR =
   sig
      structure X: T
      structure Y: T

      type t = X.t * Y.t
      val equals: t * t -> bool
      val layout: t -> Layout.t
   end
