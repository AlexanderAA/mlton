(* Copyright (C) 1997-1999 NEC Research Institute.
 * Please see the file LICENSE for license information.
 *)
signature AST_ATOMS_STRUCTS = 
   sig
      structure Const: AST_CONST
      structure Record: RECORD
      structure SortedRecord: RECORD
      sharing Record.Field = SortedRecord.Field
      structure Tyvar: TYVAR
   end

signature AST_ATOMS =
   sig
      include AST_ATOMS_STRUCTS
      
      structure Tycon:
	 sig
	    include AST_ID
	    include PRIM_TYCONS sharing type tycon = t
	 end

      structure Var: AST_ID

      structure Con:
	 sig
	    include AST_ID
	    include PRIM_CONS sharing type con = t
	 end

      structure Sigid: AST_ID
      structure Strid: AST_ID
      structure Fctid: AST_ID

      structure Vid:
	 sig
	    include AST_ID

	    (* conversions to and from variables and constructors *)
            val fromVar: Var.t -> t
	    val fromCon: Con.t -> t
	    val toVar: t -> Var.t
	    val toCon: t -> Con.t
	    val toFctid: t -> Fctid.t
	 end

      structure Longtycon:
	 sig
	    include LONGID
            val arrow: t
	    val exn: t
	 end sharing Longtycon.Id = Tycon

      structure Longvar: LONGID sharing Longvar.Id = Var
      structure Longcon: LONGID sharing Longcon.Id = Con
      structure Longstrid: LONGID sharing Longstrid.Id = Strid
      structure Longvid:
	 sig
	    include LONGID

	    val bind: t
	    val cons: t
	    val falsee: t
	    val match: t
	    val nill: t
	    val reff: t
	    val truee: t

	    val fromLongcon: Longcon.t -> t
	    val toLongvar: t -> Longvar.t
	    val toLongcon: t -> Longcon.t
	    val toLongstrid: t -> Longstrid.t
	 end sharing Longvid.Id = Vid

      sharing Strid = Longtycon.Strid = Longvar.Strid = Longcon.Strid
	 = Longvid.Strid = Longstrid.Strid

      structure Type:
	 sig
	    type t
	    datatype node =
	       Var of Tyvar.t
	     | Con of Longtycon.t * t vector
	     | Record of t SortedRecord.t

	    include WRAPPED sharing type node' = node
			    sharing type obj = t

	    val var: Tyvar.t -> t
	    val con: Tycon.t * t vector -> t
	    val record: t SortedRecord.t -> t
	    val arrow: t * t -> t
	    val exn:  t
	    val tuple: t vector -> t
	    val unit: t
	    val layout: t -> Layout.t
	    val layoutOption: t option -> Layout.t
	    val layoutApp: Layout.t * 'a vector * ('a -> Layout.t) -> Layout.t
	 end
      structure TypBind:
	 sig
	    type t
	    datatype node = T of {tyvars: Tyvar.t vector,
				  tycon: Tycon.t,
				  def: Type.t} list
	    include WRAPPED sharing type node' = node
			    sharing type obj = t

            val empty: t
	    val layout: t -> Layout.t
	 end
      structure DatBind:
	 sig
	    type t
	    datatype node =
	       T of {datatypes: {tyvars: Tyvar.t vector,
				 tycon: Tycon.t,
				 cons: (Con.t * Type.t option) vector} vector,
		     withtypes: TypBind.t}
	    include WRAPPED sharing type node' = node
			    sharing type obj = t
	    val layout: string * t -> Layout.t
	 end
      structure DatatypeRhs:
	 sig
	    type t
	    datatype node =
	       DatBind of DatBind.t
	     | Repl of {lhs: Tycon.t, rhs: Longtycon.t}
	    include WRAPPED sharing type node' = node
			    sharing type obj = t
	    val layout: t -> Layout.t
	 end

      val bind: Layout.t * Layout.t -> Layout.t
      val layoutAnds: string * 'a list * (Layout.t * 'a -> Layout.t) -> Layout.t
      datatype bindStyle =
	 OneLine
       | Split of int
      val layoutAndsBind:
	 string * string * 'a list * ('a -> bindStyle * Layout.t * Layout.t)
	 -> Layout.t
   end
