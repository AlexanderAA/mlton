(* Copyright (C) 1999-2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type int = Int.t

signature ELABORATE_CORE_STRUCTS = 
   sig
      structure Ast: AST
      structure ConstType: CONST_TYPE
      structure CoreML: CORE_ML
      structure Ctrls: ELABORATE_CONTROLS
      structure Decs: DECS
      structure Env: ELABORATE_ENV
      sharing Ast = Ctrls.Ast = Env.Ast
      sharing Ast.Tyvar = CoreML.Tyvar
      sharing ConstType = Ctrls.ConstType
      sharing CoreML = Ctrls.CoreML = Decs.CoreML = Env.CoreML
      sharing Decs = Env.Decs
   end

signature ELABORATE_CORE = 
   sig
      include ELABORATE_CORE_STRUCTS

      (* Elaborate dec in env, returning Core ML decs. *)
      val elaborateDec:
	 Ast.Dec.t * {env: Env.t, nest: string list}
	 -> Decs.t
      val reportUndeterminedTypes: unit -> unit
   end
