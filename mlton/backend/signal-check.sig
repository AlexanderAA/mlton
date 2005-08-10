(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

type int = Int.t
   
signature SIGNAL_CHECK_STRUCTS = 
   sig
      structure Rssa: RSSA
   end

signature SIGNAL_CHECK = 
   sig
      include SIGNAL_CHECK_STRUCTS

      val insert: Rssa.Program.t -> Rssa.Program.t
   end
