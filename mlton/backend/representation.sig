(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type int = Int.t
   
signature REPRESENTATION_STRUCTS = 
   sig
      structure Ssa: SSA
      structure Mtype: MTYPE
   end

signature REPRESENTATION = 
   sig
      include REPRESENTATION_STRUCTS

      structure TyconRep:
	 sig
	    datatype t =
	     (* Datatype has no representation (Void) or contains a single
	      * variant, and hence constructor requires no additional
	      * representation.
	      *) 
	       Prim of Mtype.t
	     (* All cons are non-value-carrying and are represented as ints. *)
	     | Enum of {numEnum: int}
	     (* All cons except for one are non-value-carrying and are
	      * represented as ints that are nonzero mod 4.  The value carrying
	      * con is represented transparently, i.e. the value is known to be a
	      * pointer and is left as such.
	      *)
	     | EnumDirect of {numEnum: int}
	     (* All cons except for one are non-value-carrying and are
	      * represented as ints that are nonzero mod 4.  The value carrying
	      * con is represented by boxing its arg.
	      *)
	     | EnumIndirect of {numEnum: int}
	     (* Non-value-carrying and are represented as ints that are nonzero
	      * mod 4.  Value carrying cons are represented by boxing the args
	      * and adding an integer tag.
	      *)
	     | EnumIndirectTag of {numEnum: int,
				   numTag: int}
	     (* All cons are value carrying and are represented by boxing the
	      * args and adding an integer tag.
	      *)
	     | IndirectTag of {numTag: int}
	     | Void

	    val equals: t * t -> bool
	    val layout: t -> Layout.t
	    val toMtype: t -> Mtype.t option
	 end

      (* How a constructor variant of a datatype is represented. *)
      structure ConRep:
	 sig
	    datatype t =
	       (* need no representation *)
	       Void
	     (* an integer *)
	     | Int of int
	     (* an integer, but of Pointer type *)
	     | IntCast of int
	     (* just keep the value itself *)
	     | Transparent of Mtype.t
	     (* box the arg(s) *)
	     | Tuple
	     (* box the arg(s) and add the integer tag as the first word *)
	     | TagTuple of int

	    val layout: t -> Layout.t
	 end
      
      val compute:
	 Ssa.Program.t
	 -> {
	     tyconRep: Ssa.Tycon.t -> TyconRep.t,
	     conRep: Ssa.Con.t -> ConRep.t,
	     toMtype: Ssa.Type.t -> Mtype.t option
	    }
   end
