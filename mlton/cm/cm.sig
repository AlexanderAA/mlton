(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
signature CM =
   sig
      (* cmfile can be relative or absolute.
       * The resulting list of files will have the same path as cmfile.
       *)
      val cm: {cmfile: File.t} -> File.t list
   end
