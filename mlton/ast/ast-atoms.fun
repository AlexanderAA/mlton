(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
functor AstAtoms (S: AST_ATOMS_STRUCTS) :> AST_ATOMS = 
struct

open S
structure Wrap = Region.Wrap

structure Tycon =
   struct
      structure Id = AstId (val className = "tycon")
      open Id

      structure P =
	 PrimTycons (open Id
		     val fromString = fn s => fromString (s, Region.bogus))
      open P
   end

structure Var = AstId (val className = "variable")
   
structure Con =
   struct
      structure Id = AstId (val className = "constructor")
      open Id

      structure P =
	 PrimCons (open Id
		   val fromString = fn s => fromString (s, Region.bogus))

      open P
   end

structure Sigid = AstId (val className = "signature")
structure Strid = AstId (val className = "structure")
structure Fctid = AstId (val className = "functor")

structure Vid =
   struct
      structure I = AstId (val className = "variable")
      open I
	 
      fun fromCon c = fromString (Con.toString c, Con.region c)
      fun fromVar x = fromString (Var.toString x, Var.region x)
      local
	 fun make f v = f (toString v, region v)
      in
	 val toCon = make Con.fromString
	 val toVar = make Var.fromString
	 val toFctid = make Fctid.fromString
	 val toStrid = make Strid.fromString
      end
      val bind = fromCon Con.bind
      val cons = fromCon Con.cons
      val falsee = fromCon Con.falsee
      val match = fromCon Con.match
      val nill = fromCon Con.nill
      val reff = fromCon Con.reff
      val truee = fromCon Con.truee
   end

structure Longtycon =
   struct
      structure T = Longid (structure Strid = Strid
			    structure Id = Tycon)
      open T

      val arrow = short Tycon.arrow

      val exn = short Tycon.exn

      fun isArrow t =
	 case split t of
	    ([], tycon) => Tycon.equals (tycon, Tycon.arrow)
	  | _ => false
   end
structure Longvar = Longid (structure Strid = Strid
			   structure Id = Var)
structure Longcon =
   struct
      structure L = Longid (structure Strid = Strid
			   structure Id = Con)
      open L
      val nill = short Con.nill
      val cons = short Con.cons
   end

structure Longstrid = Longid (structure Strid = Strid
			     structure Id = Strid)
structure Longfctid = Longid (structure Strid = Strid
			     structure Id = Fctid)

structure Longvid =
   struct
      structure L = Longid (structure Strid = Strid
			   structure Id = Vid)
      open L
      fun fromLongcon (c: Longcon.t): t =
	 let
	    val (strids, id) = Longcon.split c
	 in
	    makeRegion (T {strids = strids, id = Vid.fromCon id},
			Longcon.region c)
	 end
      local
	 fun to (make,node, conv) x =
	    let val (T {strids, id}, region) = dest x
	    in make (node {strids = strids, id =  conv id}, region)
	    end
      in val toLongvar = to (Longvar.makeRegion, Longvar.T, Vid.toVar)
	 val toLongcon = to (Longcon.makeRegion, Longcon.T, Vid.toCon)
	 val toLongstrid = to (Longstrid.makeRegion, Longstrid.T, Vid.toStrid)
	 val toLongfctid = to (Longfctid.makeRegion, Longfctid.T, Vid.toFctid)
      end

      val bind = short Vid.bind
      val cons = short Vid.cons
      val falsee = short Vid.falsee
      val match = short Vid.match
      val nill = short Vid.nill
      val reff = short Vid.reff
      val truee = short Vid.truee
   end

open Layout

structure Type =
   struct
      structure Record = SortedRecord
      open Wrap
      datatype node =
	 Var of Tyvar.t
       | Con of Longtycon.t * t vector
       | Record of node Wrap.t Record.t (* kit barfs on t Record.t *)
      withtype t = node Wrap.t
      type node' = node
      type obj = t

      fun make n = makeRegion (n, Region.bogus)
      val var = make o Var
      val record = make o Record
      val tuple = record o Record.tuple
      val unit = tuple (Vector.new0 ())

      fun con (c: Tycon.t, ts: t vector): t =
	 if Tycon.equals (c, Tycon.tuple)
	    then tuple ts
	 else make (Con (Longtycon.short c, ts))

      fun arrow (t1, t2) = con (Tycon.arrow, Vector.new2 (t1, t2))

      val exn = con (Tycon.exn, Vector.new0 ())

      fun layoutApp (tycon, args: 'a vector, layoutArg) =
	 case Vector.length args of
	    0 => tycon
	  | 1 => seq [layoutArg (Vector.sub (args, 0)), str " ", tycon]
	  | _ => seq [Vector.layout layoutArg args, str " ", tycon]
	       
      fun layout ty =
	 case node ty of
	    Var v => Tyvar.layout v
	  | Con (c, tys) =>
	       if Longtycon.equals (c, Longtycon.arrow)
		  then if 2 = Vector.length tys
			  then
			     paren (mayAlign
				    [layout (Vector.sub (tys, 0)),
				     seq [str "-> ",
					  layout (Vector.sub (tys, 1))]])
		       else Error.bug "non-binary -> tyc"
	       else layoutApp (Longtycon.layout c, tys, layout)
	  | Record r => Record.layout {record = r,
				       separator = ":", extra = "",
				       layoutElt = layout,
				       layoutTuple = layoutTupleTy}
      and layoutTupleTy tys =
	 case Vector.length tys of
	    0 => str "unit"
	  | 1 => layout (Vector.sub (tys, 0))
	  | _ => paren (mayAlign (separateLeft (Vector.toListMap (tys, layout),
						"* ")))
	       
      fun layoutOption ty =
	 case ty of
	    NONE => empty
	  | SOME ty => seq [str " of ", layout ty]
   end

fun bind (x, y) = mayAlign [seq [x, str " ="], y]

val layouts = List.map
   
fun 'a layoutAnds (prefix: string,
		   xs: 'a list, 
		   layoutX: Layout.t * 'a -> Layout.t): Layout.t =
   case xs of
      x :: xs => align (layoutX (str (prefix ^ " "), x)
		       :: List.map (xs, fn x => layoutX (str "and ", x)))
    | [] => empty

datatype bindStyle = OneLine | Split of int

fun 'a layoutBind (bind: string,
		   layout: 'a -> bindStyle * Layout.t * Layout.t)
   (prefix: Layout.t, x: 'a): Layout.t =
   let val (style, lhs, rhs) = layout x
      val lhs = seq [prefix, lhs, str " " , str bind]
   in case style of
      OneLine => seq [lhs, str " ", rhs]
    | Split indentation => align [lhs, indent (rhs, indentation)]
   end

fun layoutAndsBind (prefix, bind, xs, layout) =
   layoutAnds (prefix, xs, layoutBind (bind, layout))
   
(*---------------------------------------------------*)
(*                      TypBind                      *)
(*---------------------------------------------------*)

structure TypBind =
   struct
      datatype node =
	 T of {tycon: Tycon.t,
	       def: Type.t,
	       tyvars: Tyvar.t vector} list
      open Wrap
      type t = node Wrap.t
      type node' = node
      type obj = t

      fun layout t =
	 let val T l = node t
	 in layoutAndsBind
	    ("type", "=", l, fn {tycon, def, tyvars} =>
	     (OneLine,
	      Type.layoutApp (Tycon.layout tycon,
			      tyvars,
			      Tyvar.layout),
	      Type.layout def))
	 end
      val empty = makeRegion (T [], Region.bogus)
   end

(*---------------------------------------------------*)
(*                      DatBind                      *)
(*---------------------------------------------------*)

structure DatBind =
   struct
      datatype node =
	 T of {datatypes: {tyvars: Tyvar.t vector,
			   tycon: Tycon.t,
			   cons: (Con.t * Type.t option) vector} vector,
	       withtypes: TypBind.t}

      open Wrap
      type t = node Wrap.t
      type node' = node
      type obj = t
	 
      fun layout (prefix, d) =
	 let val T {datatypes, withtypes} = node d
	 in align
	    [layoutAndsBind
	     (prefix, "=", Vector.toList datatypes, fn {tyvars, tycon, cons} =>
	      (OneLine,
	       Type.layoutApp (Tycon.layout tycon, tyvars, Tyvar.layout),
	       alignPrefix (Vector.toListMap (cons, fn (c, to) =>
					      seq [Con.layout c,
						   Type.layoutOption to]),
			   "| "))),
	     case TypBind.node withtypes of
		TypBind.T [] => empty
	      | _ => seq [str "with", TypBind.layout withtypes]]
	 end
   end

structure DatatypeRhs =
   struct
      datatype node =
	 DatBind of DatBind.t
       | Repl of {lhs: Tycon.t, rhs: Longtycon.t}

      open Wrap
      type t = node Wrap.t
      type node' = node
      type obj = t
	 
      fun layout d =
	 case node d of
	    DatBind d => DatBind.layout ("datatype", d)
	  | Repl {lhs, rhs} =>
	       seq [str "datatype ", Tycon.layout lhs,
		   str " = datatype ", Longtycon.layout rhs]
   end

end
