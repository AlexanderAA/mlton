(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type int = Int.t
type word = Word.t
   
signature BACKEND_STRUCTS = 
   sig
      structure Machine: MACHINE
      structure Ssa: SSA
      sharing Machine.IntX = Ssa.IntX
      sharing Machine.Label = Ssa.Label
      sharing Machine.Prim = Ssa.Prim
      sharing Machine.RealX = Ssa.RealX
      sharing Machine.SourceInfo = Ssa.SourceInfo
      sharing Machine.WordX = Ssa.WordX

      val funcToLabel: Ssa.Func.t -> Machine.Label.t
   end

signature BACKEND = 
   sig
      include BACKEND_STRUCTS
      
      val toMachine: Ssa.Program.t -> Machine.Program.t
   end
