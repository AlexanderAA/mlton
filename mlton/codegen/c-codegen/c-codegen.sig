(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type int = Int.t
type word = Word.t

signature C_CODEGEN_STRUCTS =
   sig
      structure Ffi: FFI
      structure Machine: MACHINE
   end

signature C_CODEGEN =
   sig
      include C_CODEGEN_STRUCTS

      val output: {program: Machine.Program.t,
		   outputC: unit -> {file: File.t,
				     print: string -> unit,
				     done: unit -> unit},
		   outputH: unit -> {done: unit -> unit,
				     print: string -> unit}
		   } -> unit
      val outputDeclarations: {additionalMainArgs: string list,
			       includes: string list,
			       outputH: unit -> {done: unit -> unit,
						 print: string -> unit},
			       print: string -> unit,
			       program: Machine.Program.t,
			       rest: unit -> unit
			       } -> unit
   end
