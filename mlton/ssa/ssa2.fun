(* Copyright (C) 1999-2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

functor Ssa2 (S: SSA2_STRUCTS): SSA2 = 
   Simplify2 (Shrink2 (PrePasses2 (
   TypeCheck2 (Analyze2 (SsaTree2 (S))))))
