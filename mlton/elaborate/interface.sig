(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type int = Int.t
   
signature INTERFACE_STRUCTS = 
   sig
      structure Ast: AST
      structure EnvTypeStr:
	 sig
	    structure AdmitsEquality: ADMITS_EQUALITY
	    structure Kind: TYCON_KIND
	    structure Tycon:
	       sig
		  type t

		  val admitsEquality: t -> AdmitsEquality.t ref
		  val arrow: t
		  val equals: t * t -> bool
		  val exn: t
		  val layout: t -> Layout.t
		  val layoutApp:
		     t * (Layout.t * {isChar: bool, needsParen: bool}) vector
		     -> Layout.t * {isChar: bool, needsParen: bool}
		  val tuple: t
	       end

	    type t
	 end
   end

signature INTERFACE = 
   sig
      include INTERFACE_STRUCTS

      structure AdmitsEquality: ADMITS_EQUALITY
      sharing AdmitsEquality = EnvTypeStr.AdmitsEquality
      structure Kind: TYCON_KIND
      sharing Kind = EnvTypeStr.Kind
	 
      structure FlexibleTycon:
	 sig
	    type typeStr
	    type t

	    datatype dest =
	       ETypeStr of EnvTypeStr.t
	     | TypeStr of typeStr
	    val dest: t -> dest
	 end
      structure Tycon:
	 sig
	    datatype t =
	       Flexible of FlexibleTycon.t
	     | Rigid of EnvTypeStr.Tycon.t * Kind.t

	    val admitsEquality: t -> AdmitsEquality.t ref
	    val make: {hasCons: bool} -> t
	 end
      structure Tyvar:
	 sig
	    type t
	 end
      sharing Tyvar = Ast.Tyvar
      structure Record: RECORD
      sharing Record = Ast.SortedRecord
      structure Type:
	 sig
	    type t

	    val arrow: t * t -> t
	    val bogus: t
	    val con: Tycon.t * t vector -> t
	    val deArrow: t -> t * t
	    val deEta: t * Tyvar.t vector -> Tycon.t option
	    val exn: t
	    val hom: t * {con: Tycon.t * 'a vector -> 'a,
			  record: 'a Record.t -> 'a,
			  var: Tyvar.t -> 'a} -> 'a
	    val layout: t -> Layout.t
	    val record: t Record.t -> t
	    val var: Tyvar.t -> t
	 end
      structure Status:
	 sig
	    datatype t = Con | Exn | Var
	       
	    val layout: t -> Layout.t
	    val toString: t -> string
	 end
      structure Time:
	 sig
	    type t

	    val tick: unit -> t
	 end
      structure Scheme:
	 sig
	    datatype t = T of {ty: Type.t,
			       tyvars: Tyvar.t vector}

	    val admitsEquality: t -> bool
	    val make: Tyvar.t vector * Type.t -> t
	    val ty: t -> Type.t
	 end
      structure Cons:
	 sig
	    datatype t = T of {name: Ast.Con.t,
			       scheme: Scheme.t} vector
	       
	    val empty: t
	    val layout: t -> Layout.t
	 end
      structure TypeStr:
	 sig
	    type t

	    datatype node =
	       Datatype of {cons: Cons.t,
			    tycon: Tycon.t}
	     | Scheme of Scheme.t
	     | Tycon of Tycon.t

	    val abs: t -> t
	    val admitsEquality: t -> AdmitsEquality.t
	    val apply: t * Type.t vector -> Type.t
	    val bogus: Kind.t -> t
	    val cons: t -> Cons.t
	    val data: Tycon.t * Kind.t * Cons.t -> t
	    val def: Scheme.t * Kind.t -> t
	    val kind: t -> Kind.t
	    val layout: t -> Layout.t
	    val node: t -> node
	    val toTyconOpt: t -> Tycon.t option (* NONE on Scheme *)
	    val tycon: Tycon.t * Kind.t -> t
	    val share:
	       (t * Region.t * (unit -> Layout.t))
	       * (t * Region.t * (unit -> Layout.t))
	       * Time.t
	       -> unit
	    val wheree: t * Region.t * (unit -> Layout.t) * Time.t * t -> unit
	 end
      sharing type FlexibleTycon.typeStr = TypeStr.t
      structure Shape:
	 sig
	    type t

	    val equals: t * t -> bool
	    val plist: t -> PropertyList.t
	 end

      type t
      
      val copy: t -> t (* copy renames all flexible tycons. *)
      val equals: t * t -> bool
      val dest: t -> {strs: (Ast.Strid.t * t) array,
		      types: (Ast.Tycon.t * TypeStr.t) array,
		      vals: (Ast.Vid.t * (Status.t * Scheme.t)) array}
      val empty: t
      val layout: t -> Layout.t
      val lookupLongtycon:
	 t * Ast.Longtycon.t * Region.t * {prefix: Ast.Strid.t list}
	 -> TypeStr.t option
      val new: {strs: (Ast.Strid.t * t) array,
		types: (Ast.Tycon.t * TypeStr.t) array,
		vals: (Ast.Vid.t * (Status.t * Scheme.t)) array} -> t
      val peekStrid: t * Ast.Strid.t -> t option
      datatype 'a peekResult =
	 Found of 'a
       | UndefinedStructure of Ast.Strid.t list
      val peekStrids: t * Ast.Strid.t list -> t peekResult
      val peekTycon: t * Ast.Tycon.t -> TypeStr.t option
      val plist: t -> PropertyList.t
      (* realize makes a copy, and instantiate longtycons *)
      val realize:
	 t * {followStrid: 'a * Ast.Strid.t -> 'a,
	      init: 'a,
	      realizeTycon: ('a * Ast.Tycon.t
			     * AdmitsEquality.t
			     * Kind.t
			     * {hasCons: bool} -> EnvTypeStr.t)}
	 -> t
      val renameTycons: (unit -> unit) ref
      val shape: t -> Shape.t
      val share: t * Ast.Longstrid.t * t * Ast.Longstrid.t * Time.t -> unit
   end
