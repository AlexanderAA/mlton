(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type int = Int.t
   
signature TYPE_ENV_STRUCTS = 
   sig
      include ATOMS
   end

signature TYPE_ENV = 
   sig
      include TYPE_ENV_STRUCTS
      structure Type:
	 sig
	    include TYPE_OPS

            (* can two types be unified?  not side-effecting. *)
            val canUnify: t * t -> bool
	    val char: t
	    val deRecord: t -> (Record.Field.t * t) vector
	    val flexRecord: t SortedRecord.t -> t * (unit -> bool)
	    val hom: {con: Tycon.t * 'a vector -> 'a,
		      var: Tyvar.t -> 'a} -> t -> 'a
	    val isUnit: t -> bool
	    val layout: t -> Layout.t
	    val layoutPretty: t -> Layout.t
	    val new: {canGeneralize: bool, equality: bool} -> t
	    val record: t SortedRecord.t -> t
	    val string: t
	    val toString: t -> string
	    (* make two types identical (recursively).  side-effecting. *)
	    datatype unifyResult =
	       NotUnifiable of Layout.t * Layout.t
	     | Unified
	    val unify: t * t -> unifyResult
	    val unresolvedInt: unit -> t
	    val unresolvedReal: unit -> t
	    val unresolvedWord: unit -> t
	    val var: Tyvar.t -> t
	 end
      sharing type Type.intSize = IntSize.t
      sharing type Type.realSize = RealSize.t
      sharing type Type.wordSize = WordSize.t
      sharing type Type.tycon = Tycon.t
      structure InferScheme:
	 sig
	    type t

	    val apply: t * Type.t vector -> Type.t
	    val fromType: Type.t -> t
	    val haveFrees: t vector -> bool vector
	    val instantiate: t -> {args: unit -> Type.t vector,
				   instance: Type.t}
	    val layout: t -> Layout.t
	    val layoutPretty: t -> Layout.t
	    val make: {canGeneralize: bool,
		       ty: Type.t,
		       tyvars: Tyvar.t vector} -> t
	    val ty: t -> Type.t
	 end

      (* close (e, t, ts, r) = {bound, scheme} close type
       * t with respect to environment e, including all the tyvars in ts
       * and ensuring than no tyvar in ts occurs free in e.  bound returns
       * the vector of type variables in t that do not occur in e, which
       * isn't known until all flexible record fields are determined,
       * after unification is complete.
       *)
      val close:
	 Tyvar.t vector * Region.t
	 -> Type.t vector
	 -> {bound: unit -> Tyvar.t vector,
	     schemes: InferScheme.t vector}
      val closeTop: Region.t -> unit
   end

signature INFER_TYPE_ENV = TYPE_ENV
