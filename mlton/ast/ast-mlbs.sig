(* Copyright (C) 1999-2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
signature AST_MLBS_STRUCTS =
   sig
      include AST_ATOMS_STRUCTS
   end

signature AST_MLBS =
   sig
      include AST_PROGRAMS

      structure Basexp:
	 sig
	    type basdec

	    type t
	    datatype node =
	       Bas of basdec
	     | Let of basdec * t
	     | Var of Basid.t
	       
	    include WRAPPED sharing type node' = node
	                    sharing type obj = t

	    val bas: basdec -> t
	    val lett: basdec * t -> t
	    val var: Basid.t -> t

	    val checkSyntax: t -> unit
	    val layout: t -> Layout.t
	 end

      structure Basdec:
	 sig
	    type t
	    datatype node =
	       Ann of (string list * Region.t) list * t
	     | Basis of {name: Basid.t, def: Basexp.t} vector
	     | Defs of ModIdBind.t
	     | Local of t * t
	     | MLB of {fileAbs: File.t, fileUse: File.t} * t Promise.t
	     | Open of Basid.t vector
	     | Prim
	     | Prog of {fileAbs: File.t, fileUse: File.t} * Program.t Promise.t
	     | Seq of t list

	    include WRAPPED sharing type node' = node
	                    sharing type obj = t

	    val ann: (string list * Region.t) list * t -> t
	    val basis: {name: Basid.t, def: Basexp.t} vector -> t
	    val defs: ModIdBind.t -> t
	    val empty: t
	    val locall: t * t -> t
	    val mlb: {fileAbs: File.t, fileUse: File.t} * t Promise.t -> t
	    val openn: Basid.t vector -> t
	    val prim: t
	    val prog: {fileAbs: File.t, fileUse: File.t} * Program.t Promise.t -> t
	    val seq: t list -> t

	    val checkSyntax: t -> unit
	    val layout: t -> Layout.t
	    val sourceFiles: t -> File.t vector
	 end
      sharing type Basdec.t = Basexp.basdec
   end
