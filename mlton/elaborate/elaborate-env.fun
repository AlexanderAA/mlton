(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
functor ElaborateEnv (S: ELABORATE_ENV_STRUCTS): ELABORATE_ENV =
struct

open S

local
   open Ast
in
   structure Fixity = Fixity
   structure Strid = Strid
   structure Longcon = Longcon
   structure Longvid = Longvid
   structure Longstrid = Longstrid
   structure Longtycon = Longtycon
end

local
   open CoreML
in
   structure Con = Con
   structure Var = Var
   structure Prim = Prim
   structure Record = Record
   structure Srecord = SortedRecord
   structure Tycon = Tycon
   structure Tyvar = Tyvar
   structure Var = Var
end

local
   open TypeEnv
in
   structure Scheme = Scheme
   structure Type = Type
end

structure Decs = Decs (structure CoreML = CoreML)

structure Scheme =
   struct
      open Scheme
	 
      fun bogus () = fromType (Type.new {canGeneralize = true,
					 equality = true})
   end

structure TypeScheme = Scheme

structure Scope = UniqueId ()
   
structure TypeStr =
   struct
      structure Kind = CoreML.Tycon.Kind

      datatype node =
	 Datatype of {cons: {con: Con.t,
			     name: Ast.Con.t,
			     scheme: Scheme.t} vector,
		      tycon: Tycon.t}
       | Scheme of Scheme.t
       | Tycon of Tycon.t

      datatype t = T of {kind: Kind.t,
			 node: node}

      local
	 fun make f (T r) = f r
      in
	 val kind = make #kind
	 val node = make #node
      end

      fun bogus () =
	 T {kind = Kind.Arity 0,
	    node = Scheme (Scheme.bogus ())}

      fun abs t =
	 case node t of
	    Datatype {tycon, ...} => T {kind = kind t,
					node = Tycon tycon}
	  | _ => t

      fun apply (t: t, tys: Type.t vector): Type.t =
	 case node t of
	    Datatype {tycon, ...} => Type.con (tycon, tys)
	  | Scheme s => Scheme.apply (s, tys)
	  | Tycon t => Type.con (t, tys)

      fun cons t =
	 case node t of
	    Datatype {cons, ...} => cons
	  | _ => Vector.new0 ()

      fun data (tycon, kind, cons) =
	 T {kind = kind,
	    node = Datatype {tycon = tycon, cons = cons}}

      fun def (s, kind) = T {kind = kind,
			     node = Scheme s}

      fun tycon (c, kind) = T {kind = kind,
			       node = Tycon c}

      fun layout t =
	 let
	    open Layout
	 in
	    case node t of
	       Datatype {tycon, cons} =>
		  seq [str "Datatype ",
		       record [("tycon", Tycon.layout tycon),
			       ("cons", (Vector.layout
					 (fn {con, name, scheme} =>
					  tuple [Ast.Con.layout name,
						 Con.layout con,
						 str ": ",
						 Scheme.layout scheme])
					 cons))]]
	     | Scheme s => Scheme.layout s
	     | Tycon t => seq [str "Tycon ", Tycon.layout t]
	 end
   end

structure Vid =
   struct
      datatype t =
	 Con of Con.t
       | ConAsVar of Con.t
       | Exn of Con.t
       | Overload of (Var.t * Type.t) vector
       | Var of Var.t

      val statusString =
	 fn Con _ => "con"
	  | ConAsVar _ => "var"
	  | Exn _ => "exn"
	  | Overload _ => "var"
	  | Var _ => "var"

      val bogus = Var Var.bogus

      fun layout vid =
	 let
	    open Layout
	    val (name, l) =
	       case vid of
		  Con c => ("Con", Con.layout c)
		| ConAsVar c => ("ConAsVar", Con.layout c)
		| Exn c => ("Exn", Con.layout c)
		| Overload xts =>
		     ("Overload",
		      Vector.layout (Layout.tuple2 (Var.layout, Type.layout))
		      xts)
		| Var v => ("Var", Var.layout v)
	 in
	    paren (seq [str name, str " ", l])
	 end

      val deVar =
	 fn Var v => SOME v
	  | _ => NONE
		
      val deCon =
	 fn Con c => SOME c
	  | Exn c => SOME c
	  | _ => NONE
	  
      fun output (r, out) = Layout.output (layout r, out)
   end

fun layoutSize z = Int.layout (MLton.size z)
   
structure Values =
   struct
      datatype ('a, 'b) t = T of {domain: 'a,
				  ranges: {isUsed: bool ref,
					   scope: Scope.t,
					   value: 'b} list ref}

      fun domain (T {domain, ...}) = domain
	    
      fun sizeMessage (vs as T {domain, ranges}, layoutA, layoutB) =
	 let
	    open Layout
	 in
	    seq [layoutA domain, str " ",
		 List.layout (layoutB o #value) (!ranges)]
	 end

      fun layout (layoutDomain, layoutRange) (T {domain, ranges, ...}) =
	 Layout.tuple [layoutDomain domain,
		       List.layout (layoutRange o #value) (!ranges)]

      fun new domain = T {domain = domain,
			  ranges = ref []}

      local
	 fun f g (T r) = g r
      in
	 fun domain z = f #domain z
	 fun ranges z = f #ranges z
      end

      fun isEmpty (T {ranges, ...}) = List.isEmpty (!ranges)

      val pop: ('a, 'b) t -> {isUsed: bool ref,
			      scope: Scope.t,
			      value: 'b} =
	 fn T {ranges, ...} => List.pop ranges
   end

structure ShapeId = UniqueId ()

structure Status:
   sig
      datatype t = Con | Exn | Var
	 
      val layout: t -> Layout.t
      val toString: t -> string
   end =
   struct
      datatype t = Con | Exn | Var

      val toString =
	 fn Con => "Con"
	  | Exn => "Exn"
	  | Var => "Var"

      val layout = Layout.str o toString
   end

(* ------------------------------------------------- *)
(*                     Interface                     *)
(* ------------------------------------------------- *)

structure Interface =
   struct
      structure Info =
	 struct
	    (* The array is sorted by domain element. *)
	    datatype ('a, 'b) t = T of {isUsed: bool ref,
					range: 'b,
					values: ('a, 'b) Values.t} array

	    fun bogus () = T (Array.tabulate (0, fn _ => Error.bug "impossible"))

	    fun layout (layoutDomain, layoutRange) (T a) =
	       Array.layout (fn {range, values, ...} =>
			     Layout.tuple [layoutDomain (Values.domain values),
					   layoutRange range])
	       a

	    fun foreach (T a, f) =
	       Array.foreach (a, fn {range, values, ...} =>
			      f (Values.domain values, range))

	    fun peek (T a, compare, domain) =
	       Option.map
	       (BinarySearch.search
		(a, fn {values, ...} => compare (domain, Values.domain values)),
		fn i =>
		let
		   val v as {isUsed, ...} =  Array.sub (a, i)
		   val _ = isUsed := !Control.showBasisUsed
		in
		   v
		end)
	 end
      
      structure TypeStr =
	 struct
	    datatype t =
	       Datatype of {cons: Ast.Con.t vector}
	     | Tycon

	    val cons =
	       fn Datatype {cons, ...} => cons
		| Tycon => Vector.new0 ()

	    fun layout t =
	       let
		  open Layout
	       in
		  case t of
		     Datatype {cons, ...} =>
			seq [str "Datatype ", Vector.layout Ast.Con.layout cons]
		   | Tycon => str "Tycon"
	       end
	 end
      
      datatype t = T of {id: ShapeId.t,
			 strs: (Ast.Strid.t, t) Info.t,
			 vals: (Ast.Vid.t, Status.t) Info.t,
			 types: (Ast.Tycon.t, TypeStr.t) Info.t}

      local
	 fun make (field, compare) (T fields, domain)  =
	    Option.map (Info.peek (field fields, compare, domain), #range)
      in
	 val peekStrid = make (#strs, Ast.Strid.compare)
	 val peekTycon = make (#types, Ast.Tycon.compare)
      end

      fun peekStrids (I: t, strids: Ast.Strid.t list): t option =
	 case strids of
	    [] => SOME I
	  | s :: strids =>
	       case peekStrid (I, s) of
		  NONE => NONE
		| SOME I => peekStrids (I, strids)
   
      val bogus = T {id = ShapeId.new (),
		     strs = Info.bogus (),
		     vals = Info.bogus (),
		     types = Info.bogus ()}

      fun layout (T {strs, vals, types, ...}) =
	 Layout.record
	 [("strs", Info.layout (Ast.Strid.layout, layout) strs),
	  ("vals", Info.layout (Ast.Vid.layout, Status.layout) vals),
	  ("types", Info.layout (Ast.Tycon.layout, TypeStr.layout) types)]

      fun shapeId (T {id, ...}) = id

      fun foreach (T {strs, vals, types, ...},
		   {handleStr, handleType, handleVal}) =
	 (Info.foreach (strs, handleStr)
	  ; Info.foreach (vals, handleVal)
	  ; Info.foreach (types, handleType))
   end

(* ------------------------------------------------- *)
(*                     Structure                     *)
(* ------------------------------------------------- *)

structure Structure =
   struct
      structure Info = Interface.Info

      datatype t = T of {shapeId: ShapeId.t option,
			 strs: (Ast.Strid.t, t) Info.t,
			 types: (Ast.Tycon.t, TypeStr.t) Info.t,
			 vals: (Ast.Vid.t, Vid.t * Scheme.t) Info.t}

      fun layoutUsed (T {strs, types, vals, ...}) =
	 let
	    open Layout
	    fun doit (Info.T a, lay): Layout.t =
	       align
	       (Array.foldr (a, [], fn ({isUsed, range, values}, ac) =>
			     if not (!isUsed)
				then ac
			     else lay (Values.domain values, range) :: ac))
	    fun doitn (i, name, lay) =
	       doit (i, fn (d, _) => seq [str name, lay d])
	 in
	    align [doitn (types, "type ", Ast.Tycon.layout),
		   doitn (vals, "val ", Ast.Vid.layout),
		   doit (strs, fn (d, r) =>
			 align [seq [str "structure ", Ast.Strid.layout d],
				indent (layoutUsed r, 3)])]
	 end

      fun layout (T {strs, vals, types, ...}) =
	 Layout.record
	 [("types", Info.layout (Ast.Tycon.layout, TypeStr.layout) types),
	  ("vals",
	   Info.layout (Ast.Vid.layout,
			Layout.tuple2 (Vid.layout, Scheme.layout))
	   vals),
	  ("strs", Info.layout (Ast.Strid.layout, layout) strs)]

      local
	 open Layout
      in
	 fun layoutTypeSpec (d, _) = seq [str "type ", Ast.Tycon.layout d]
	 fun layoutValSpec (d, (vid, scheme)) =
	    let
	       fun simple s =
		  seq [str s, str " ", Ast.Vid.layout d, str ": ",
		       Scheme.layoutPretty scheme]
	       datatype z = datatype Vid.t
	    in
	       case vid of
		  Con _ => simple "con"
		| ConAsVar _ => simple "val"
		| Exn c =>
		     seq [str "exception ", Con.layout c, 
			  case Type.deArrowOpt (Scheme.ty scheme) of
			     NONE => empty
			   | SOME (t, _) =>
				seq [str " of ", Type.layoutPretty t]]
		| Overload  _ => simple "val"
		| Var _ => simple "val"
	    end
	 fun layoutStrSpec (d, r) =
	    align [seq [str "structure ", Ast.Strid.layout d, str ":"],
		   indent (layoutPretty r, 3)]
	 and layoutPretty (T {strs, vals, types, ...}) =
	    let
	       fun doit (Info.T a, layout) =
		  align (Array.foldr (a, [], fn ({range, values, ...}, ac) =>
				      layout (Values.domain values,
					      range)
				      :: ac))
	    in
	       align
	       [str "sig",
		indent (align [doit (types, layoutTypeSpec),
			       doit (vals, layoutValSpec),
			       doit (strs, layoutStrSpec)],
			3),
		str "end"]
	    end
      end

      val bogus = T {shapeId = NONE,
		     strs = Info.bogus (),
		     vals = Info.bogus (),
		     types = Info.bogus ()}

      local
	 fun make (field, compare) (T fields, domain) =
	    Info.peek (field fields, compare, domain)
      in
	 val peekStrid' = make (#strs, Ast.Strid.compare)
	 val peekVid' = make (#vals, Ast.Vid.compare)
	 val peekTycon' = make (#types, Ast.Tycon.compare)
      end

      fun peekStrid z = Option.map (peekStrid' z, #range)
      fun peekTycon z = Option.map (peekTycon' z, #range)
      fun peekVid z = Option.map (peekVid' z, #range)

      local
	 fun make (from, de) (S, x) =
	    case peekVid (S, from x) of
	       NONE => NONE
	     | SOME (vid, s) => Option.map (de vid, fn z => (z, s))
      in
	 val peekCon = make (Ast.Vid.fromCon, Vid.deCon)
	 val peekVar = make (Ast.Vid.fromVar, Vid.deVar)
      end

      datatype peekResult =
	 Found of t
	| UndefinedStructure of Strid.t list
	  
      fun peekStrids (S, strids) =
	 let
	    fun loop (S, strids, ac) =
	       case strids of
		  [] => Found S
		| strid :: strids =>
		     case peekStrid (S, strid) of
			NONE => UndefinedStructure (rev (strid :: ac))
		      | SOME S => loop (S, strids, strid :: ac)
	 in
	    loop (S, strids, [])
	 end

(*       fun peekLongtycon (S, t) =
 * 	 let
 * 	    val (strids, t) = Ast.Longtycon.split t
 * 	 in
 * 	    case peekStrids (S, strids) of
 * 	       NONE => NONE
 * 	     | SOME S => peekTycon (S, t)
 * 	 end
 *)

(*       val lookupLongtycon = valOf o peekLongtycon
 * 	 
 *)
      (* section 5.3, 5.5, 5.6 and rules 52, 53 *)
      fun cut {str, interface, opaque, region}: t =
	 let
	    fun error (name, l) =
	       Control.error
	       (region, let open Layout
			in seq [str name, str " ", l,
				str " in signature but not in structure"]
			end, Layout.empty)
	    fun cut (S as T {shapeId, ...}, I, strids) =
	       let
		  val shapeId' = Interface.shapeId I
		  val cutoff =
		     if opaque then NONE
		     else case shapeId of
			NONE => NONE
		      | SOME shapeId =>
			   if ShapeId.equals (shapeId, shapeId')
			      then SOME S
			   else NONE
	       in
		  case cutoff of
		     SOME S => S
		   | NONE =>
			let
			   val strs = ref []
			   val vals = ref []
			   val types = ref []
			   fun handleStr (name, I) =
			      case peekStrid' (S, name) of
				 NONE =>
				    error
				    ("structure",
				     Longstrid.layout	
				     (Longstrid.long(rev strids, name)))
			       | SOME {range, values, ...} =>
				    List.push
				    (strs,
				     {isUsed = ref false,
				      range = cut (range, I, name :: strids),
				      values = values})
			   fun handleType (name: Ast.Tycon.t,
					   typeStr: Interface.TypeStr.t) =
			      case peekTycon' (S, name) of
				 NONE =>
				    error
				    ("type",
				     Longtycon.layout
				     (Longtycon.long (rev strids, name)))
			       | SOME {range = typeStr', values, ...} =>
				    let
				       datatype z = datatype TypeStr.node
				       val typeStr'' =
					  case typeStr of
					     Interface.TypeStr.Datatype {cons} =>
						(case TypeStr.node typeStr' of
						    Datatype _ => typeStr'
						  | _ =>
						       (Control.error
							(region,
							 let open Layout
							 in seq [str "type ",
								 str " is a datatype in signature but not in structure"]
							 end, Layout.empty)
							; TypeStr.bogus ()))
					   | Interface.TypeStr.Tycon =>
						let
						   datatype z = datatype TypeStr.t
						in case TypeStr.node typeStr' of
						   Datatype {tycon, ...} =>
						      TypeStr.T
						      {kind = TypeStr.kind typeStr',
						       node = Tycon tycon}
						 | _ => typeStr'
						end
				    in List.push (types,
						  {isUsed = ref false,
						   range = typeStr'',
						   values = values})
				    end
			   fun handleVal (name, status) =
			      case peekVid' (S, name) of
				 NONE =>
				    error ("variable",
					   Longvid.layout (Longvid.long
							   (rev strids, name)))
			       | SOME {range = (vid, s), values, ...} =>
				    let
				       val vid =
					  case (vid, status) of
					     (Vid.Con c, Status.Var) =>
						Vid.ConAsVar c
					   | (Vid.Exn c, Status.Var) =>
						Vid.ConAsVar c
					   | (_, Status.Var) => vid
					   | (Vid.Con _, Status.Con) => vid
					   | (Vid.Exn _, Status.Exn) => vid
					   | _ =>
						(Control.error
						 (region,
						  Layout.str
						  (concat
						   ["identifier ",
						    Longvid.toString
						    (Longvid.long (rev strids,
								   name)),
						    " has status ",
						    Vid.statusString vid,
						    " in structure but status ",
						    Status.toString status,
						    " in signature "]),
						  Layout.empty)
						 ; vid)
				    in
				       List.push (vals,
						  {isUsed = ref false,
						   range = (vid, s),
						   values = values})
				    end
			   val _ =
			      Interface.foreach
			      (I, {handleStr = handleStr,
				   handleType = handleType,
				   handleVal = handleVal})
			   fun doit (elts, less) =
			      Info.T
			      (QuickSort.sortArray
			       (Array.fromList (!elts),
				fn ({values = v, ...}, {values = v', ...}) =>
				less (Values.domain v, Values.domain v')))
			in
			   T {shapeId = SOME shapeId',
			      strs = doit (strs, Ast.Strid.<=),
			      vals = doit (vals, Ast.Vid.<=),
			      types = doit (types, Ast.Tycon.<=)}
			end
	       end
	 in
	    cut (str, interface, [])
	 end

      val cut =
	 Trace.trace ("cut",
		      fn {str, interface, ...} =>
		      Layout.tuple [layout str, Interface.layout interface],
		      layout)
	 cut

      val ffi: t option ref = ref NONE
   end

structure FunctorClosure =
   struct
      datatype t =
	 T of {apply: (Structure.t * string list * Region.t
		       -> Decs.t * Structure.t),
	       sizeMessage: unit -> Layout.t}

      val bogus = T {apply = fn _ => (Decs.empty, Structure.bogus),
 		     sizeMessage = fn _ => Layout.str "<bogus>"}

      fun apply (T {apply, ...}, s, nest, r) = apply (s, nest, r)

      fun sizeMessage (T {sizeMessage, ...}) = sizeMessage ()
	 
      fun layout _ = Layout.str "<functor closure>"
   end

(* ------------------------------------------------- *)
(*                     NameSpace                     *)
(* ------------------------------------------------- *)

structure NameSpace =
   struct
      datatype ('a, 'b) t =
	 T of {current: ('a, 'b) Values.t list ref,
	       equals: 'a * 'a -> bool,
	       hash: 'a -> word,
	       table: ('a, 'b) Values.t HashSet.t}

      fun fold (T {table, ...}, ac, f) =
	 HashSet.fold (table, [], fn (vs, ac) =>
		       if Values.isEmpty vs
			  then ac
		       else f (vs, ac))
	 
      fun domain s = fold (s, [], fn (vs, ac) => Values.domain vs :: ac)

      fun collect (T {current, ...}: ('a, 'b) t,
		   le: 'a * 'a -> bool): unit -> ('a, 'b) Structure.Info.t =
	 let
	    val old = !current
	    val _ = current := []
	 in
	    fn () =>
	    let
	       val elts =
		  List.revMap (!current, fn values =>
			       let
				  val {isUsed, value, ...} = Values.pop values
			       in
				  {isUsed = isUsed,
				   range = value,
				   values = values}
			       end)
	       val _ = current := old
	       val a =
		  QuickSort.sortArray
		  (Array.fromList elts,
		   fn ({values = v, ...}, {values = v', ...}) =>
		   le (Values.domain v, Values.domain v'))
	    in
	       Structure.Info.T a
	    end
	 end

      fun peek (T {equals, hash, table, ...}, a) =
	 case HashSet.peek (table, hash a, fn vs =>
			    equals (a, Values.domain vs)) of
	    SOME (Values.T {ranges = ref ({isUsed, value, ...} :: _), ...}) =>
	       (isUsed := !Control.showBasisUsed
		; SOME value)
	  | _ => NONE

      fun sizeMessage (i as T {table, ...}: ('a, 'b) t,
		       layoutA: 'a -> Layout.t,
		       layoutB: 'b -> Layout.t) =
	 let
	    open Layout
	 in
	    align (seq [str "total ", layoutSize i]
		   :: (HashSet.fold
		       (table, [], fn (v, ac) =>
			Values.sizeMessage (v, layoutA, layoutB) :: ac)))
	 end

      fun new (equals, hash) =
	 T {current = ref [],
	    equals = equals,
	    hash = hash,
	    table = HashSet.new {hash = hash o Values.domain}}

      fun layout (layoutDomain, layoutRange) (T {table, ...}) =
	 HashSet.layout (Values.layout (layoutDomain, layoutRange)) table

      fun values (T {hash, equals, table, ...}, a) =
	 HashSet.lookupOrInsert (table, hash a,
				 fn vs => equals (a, Values.domain vs),
				 fn () => Values.new a)

      val update: ('a, 'b) t * Scope.t * {isUsed: bool ref,
					  range: 'b,
					  values: ('a, 'b) Values.t} -> unit =
	 fn (T {current, ...}, scope, {isUsed,
				       range,
				       values as Values.T {ranges, ...}}) =>
	 let
	    val value = {isUsed = isUsed,
			 scope = scope,
			 value = range}
	    fun new () = (List.push (current, values)
			  ; List.push (ranges, value))
	 in
	    case !ranges of
	       [] => new ()
	     | {scope = scope', ...} :: l =>
		  if Scope.equals (scope, scope')
		     then ranges := value :: l
		  else new ()
	 end
   end

(*---------------------------------------------------*)
(*                 Main Env Datatype                 *)
(*---------------------------------------------------*)

datatype t = T of {currentScope: Scope.t ref,
		   fcts: (Ast.Fctid.t, FunctorClosure.t) NameSpace.t,
		   fixs: (Ast.Vid.t, Ast.Fixity.t) NameSpace.t,
		   sigs: (Ast.Sigid.t, Interface.t) NameSpace.t,
		   strs: (Ast.Strid.t, Structure.t) NameSpace.t,
		   types: (Ast.Tycon.t, TypeStr.t) NameSpace.t,
		   vals: (Ast.Vid.t, Vid.t * Scheme.t) NameSpace.t}

fun clean (T {fcts, fixs, sigs, strs, types, vals, ...}): unit =
   let
      fun doit (NameSpace.T {table, ...}) =
	 HashSet.removeAll (table, Values.isEmpty)
   in
      doit fcts; doit fixs; doit sigs
   (* Can't doit to the following because it removes Values.t components that
    * are referred to by structures.  Hence, later opens fail.
    *)
      (* doit strs; doit types; doit vals *)
   end

fun sizeMessage (E as T {fcts, fixs, sigs, strs, types, vals, ...}) =
   let
      val size = MLton.size
      open Layout
   in
      record
      [("total", Int.layout (size E)),
       ("fcts", NameSpace.sizeMessage (fcts, Ast.Fctid.layout,
				       FunctorClosure.sizeMessage)),
       ("sigs", NameSpace.sizeMessage (sigs, Ast.Sigid.layout, layoutSize)),
       ("strs", NameSpace.sizeMessage (strs, Ast.Strid.layout, layoutSize))]
   end

fun empty () =
   T {currentScope = ref (Scope.new ()),
      fcts = NameSpace.new let open Ast.Fctid in (equals, hash) end,
      fixs = NameSpace.new let open Ast.Vid in (equals, hash) end,
      sigs = NameSpace.new let open Ast.Sigid in (equals, hash) end,
      strs = NameSpace.new let open Ast.Strid in (equals, hash) end,
      types = NameSpace.new let open Ast.Tycon in (equals, hash) end,
      vals = NameSpace.new let open Ast.Vid in (equals, hash) end}

fun layout (T {strs, types, vals, ...}) =
   Layout.tuple
   [NameSpace.layout (Ast.Tycon.layout, TypeStr.layout) types,
    NameSpace.layout (Ast.Vid.layout,
		      Layout.tuple2 (Vid.layout, Scheme.layout)) vals,
    NameSpace.layout (Ast.Strid.layout, Structure.layout) strs]

fun layoutPretty (T {fcts, sigs, strs, types, vals, ...}) =
   let
      open Layout
      fun doit (NameSpace.T {table, ...}, le, layout) =
	 let
	    val l =
	       HashSet.fold
	       (table, [], fn (Values.T {domain, ranges}, ac) =>
		case !ranges of
		   [] => ac
		 | {value, ...} :: _ => (domain, value) :: ac)
	 in align (List.map (QuickSort.sortList
			     (l, fn ((d, _), (d', _)) => le (d, d')),
			     layout))
	 end
   in
      align [doit (types, Ast.Tycon.<=, Structure.layoutTypeSpec),
	     doit (vals, Ast.Vid.<=, Structure.layoutValSpec),
	     doit (sigs, Ast.Sigid.<=, fn (d, _) => seq [str "signature ",
							 Ast.Sigid.layout d]),
	     doit (fcts, Ast.Fctid.<=, fn (d, _) => seq [str "functor ",
							 Ast.Fctid.layout d]),
	     doit (strs, Ast.Strid.<=, Structure.layoutStrSpec)]
   end

fun layoutUsed (T {fcts, sigs, strs, types, vals, ...}) =
   let
      open Layout
      fun doit (NameSpace.T {table, ...}, le, layout) =
	 let
	    val all =
	       HashSet.fold
	       (table, [], fn (Values.T {domain, ranges}, ac) =>
		case !ranges of
		   [] => ac
		 | {isUsed, value, ...} :: _ =>
		      if !isUsed
			 then (domain, layout (domain, value)) :: ac
		      else ac)
	 in
	    align (List.map
		   (QuickSort.sortList
		    (all, fn ((d, _), (d', _)) => le (d, d')),
		    #2))
	 end
      fun doitn (ns, name, le, lay) =
	 doit (ns, le, fn (d, _) => seq [str name, str " ", lay d])

   in
      align [doitn (types, "type", Ast.Tycon.<=, Ast.Tycon.layout),
	     doitn (vals, "val", Ast.Vid.<=, Ast.Vid.layout),
	     doitn (sigs, "signature", Ast.Sigid.<=, Ast.Sigid.layout),
	     doitn (fcts, "functor", Ast.Fctid.<=, Ast.Fctid.layout),
	     doit (strs, Ast.Strid.<=,
		   fn (d, r) =>
		   align [seq [str "structure ", Ast.Strid.layout d],
			  indent (Structure.layoutUsed r, 3)])]
   end

(* ------------------------------------------------- *)
(*                  functorClosure                   *)
(* ------------------------------------------------- *)

fun snapshot (T {currentScope, fcts, fixs, sigs, strs, types, vals}):
   (unit -> 'a) -> 'a =
   let
      fun m l = Layout.outputl (l, Out.error)
      open Layout
      fun doit (NameSpace.T {current, table, ...}, lay) =
	 let
	    val all =
	       HashSet.fold
	       (table, [], fn (vs as Values.T {ranges, ...}, ac) =>
		case !ranges of
		   [] => ac
		 | z :: _ => (z, vs) :: ac)
	 in
	    fn s0 =>
	    let
	       val current0 = !current
	       val _ =
		  current :=
		  List.fold
		  (all, [], fn (({isUsed, value, ...},
				 vs as Values.T {ranges, ...}), ac) =>
		   (List.push (ranges, {isUsed = isUsed,
					scope = s0,
					value = value})
		    ; vs :: ac))
	       val removed =
		  HashSet.fold
		  (table, [], fn (Values.T {ranges, ...}, ac) =>
		   let
		      val r = !ranges
		   in
		      case r of
			 [] => ac
		       | {scope, ...} :: _ =>
			    if Scope.equals (s0, scope)
			       then ac
			    else (ranges := []
				  ; (ranges, r) :: ac)
		   end)
	    in fn () => (List.foreach (!current, fn v => (Values.pop v; ()))
			 ; current := current0
			 ; List.foreach (removed, op :=))
	    end
	 end
      val fcts = doit (fcts, Ast.Fctid.layout)
      val fixs = doit (fixs, Ast.Vid.layout)
      val sigs = doit (sigs, Ast.Sigid.layout)
      val strs = doit (strs, Ast.Strid.layout)
      val types = doit (types, Ast.Tycon.layout)
      val vals = doit (vals, Ast.Vid.layout)
   in
      fn th =>
      let
	 val s0 = Scope.new ()
	 val fcts = fcts s0
	 val fixs = fixs s0
	 val sigs = sigs s0
	 val strs = strs s0
	 val types = types s0
	 val vals = vals s0
	 val s1 = !currentScope
	 val _ = currentScope := s0
	 val res = th ()
	 val _ = currentScope := s1
	 val _ = (fcts (); fixs (); sigs (); strs (); types (); vals ())
      in
	 res
      end
   end
      
fun functorClosure
   (E: t,
    argInt: Interface.t,
    makeBody: Structure.t * string list -> Decs.t * Structure.t) =
   let
      val restore = snapshot E
      fun apply (arg, nest, region) =
	 let
	    val actual = Structure.cut {str = arg,
					interface = argInt,
					opaque = false,
					region = region}
	 in
	    restore (fn () => makeBody (actual, nest))
	 end
      val apply =
	 Trace.trace ("functorApply",
		      Structure.layout o #1,
		      Layout.tuple2 (Layout.ignore, Structure.layout))
	 apply
      fun sizeMessage () = layoutSize apply
   in
      FunctorClosure.T {apply = apply,
			sizeMessage = sizeMessage}
   end

(* ------------------------------------------------- *)
(*                       peek                        *)
(* ------------------------------------------------- *)

local
   fun 'a make field (T fields, a) = NameSpace.peek (field fields, a)
in
   val peekFctid = make #fcts
   val peekFix = make #fixs
   val peekFix =
      Trace.trace
      ("peekFix", Ast.Vid.layout o #2, Option.layout Ast.Fixity.layout)
      peekFix			      
   val peekSigid = make #sigs
   val peekStrid = make #strs
   val peekTycon = make #types
   val peekVid = make #vals
   fun peekVar (E, x) =
      case peekVid (E, Ast.Vid.fromVar x) of
	 NONE => NONE
       | SOME (vid, s) => Option.map (Vid.deVar vid, fn x => (x, s))
end

fun peekCon (E: t, c: Ast.Con.t): (Con.t * Scheme.t) option =
   case peekVid (E, Ast.Vid.fromCon c) of
      NONE => NONE
    | SOME (vid, s) => Option.map (Vid.deCon vid, fn c => (c, s))

fun layoutStrids (ss: Strid.t list): Layout.t =
   Layout.str (concat (List.separate (List.map (ss, Strid.toString), ".")))
   
structure PeekResult =
   struct
      datatype 'a t =
	 Found of 'a
       | UndefinedStructure of Strid.t list
       | Undefined

      fun layout lay =
	 fn Found z => lay z
	  | UndefinedStructure ss => layoutStrids ss
	  | Undefined => Layout.str "Undefined"

      val toOption: 'a t -> 'a option =
	 fn Found z => SOME z
	  | _ => NONE
   end
    
local
   datatype z = datatype PeekResult.t
   fun make (split: 'a -> Strid.t list * 'b,
	     peek: t * 'b -> 'c option,
	     strPeek: Structure.t * 'b -> 'c option) (E, x) =
      let
	 val (strids, x) = split x
      in
	 case strids of
	    [] => (case peek (E, x) of
		      NONE => Undefined
		    | SOME z => Found z)
	  | strid :: strids =>
	       case peekStrid (E, strid) of
		  NONE => UndefinedStructure [strid]
		| SOME S =>
		     case Structure.peekStrids (S, strids) of
			Structure.Found S =>
			   (case strPeek (S, x) of
			       NONE => Undefined
			     | SOME z => Found z)
		      | Structure.UndefinedStructure ss =>
			   UndefinedStructure (strid :: ss)
      end
in
   val peekLongstrid =
      make (Ast.Longstrid.split, peekStrid, Structure.peekStrid)
   val peekLongtycon =
      make (Ast.Longtycon.split, peekTycon, Structure.peekTycon)
   val peekLongvar = make (Ast.Longvar.split, peekVar, Structure.peekVar)
   val peekLongvid = make (Ast.Longvid.split, peekVid, Structure.peekVid)
   val peekLongcon = make (Ast.Longcon.split, peekCon, Structure.peekCon)
end

val peekLongcon =
   Trace.trace2 ("peekLongcon", Layout.ignore, Ast.Longcon.layout,
		 PeekResult.layout (Layout.tuple2
				    (CoreML.Con.layout, TypeScheme.layout)))
   peekLongcon
(* ------------------------------------------------- *)
(*                      lookup                       *)
(* ------------------------------------------------- *)

fun unbound (r: Region.t, className, x: Layout.t): unit =
   Control.error
   (r,
    let open Layout
    in seq [str "undefined ", str className, str " ", x]
    end,
    Layout.empty)

local
   fun make (peek: t * 'a -> 'b option,
	     bogus: unit -> 'b,
	     className: string,
	     region: 'a -> Region.t,
	     layout: 'a -> Layout.t)
      (E: t, x: 'a): 'b =
      case peek (E, x) of
	 SOME y => y
       | NONE => (unbound (region x, className, layout x); bogus ())
in
   val lookupFctid =
      make (peekFctid, fn () => FunctorClosure.bogus,
	    "functor", Ast.Fctid.region, Ast.Fctid.layout)
   val lookupSigid =
      make (peekSigid, fn () => Interface.bogus,
	    "signature", Ast.Sigid.region, Ast.Sigid.layout)
end

local
   fun make (peek: t * 'a -> 'b PeekResult.t,
	     bogus: unit -> 'b,
	     className: string,
	     region: 'a -> Region.t,
	     layout: 'a -> Layout.t)
      (E: t, x: 'a): 'b =
      let
	 datatype z = datatype PeekResult.t
      in
	 case peek (E, x) of
	    Found z => z
	  | UndefinedStructure ss =>
	       (unbound (region x, "structure", layoutStrids ss); bogus ())
	  | Undefined =>
	       (unbound (region x, className, layout x); bogus ())
      end
in
   val lookupLongcon =
      make (peekLongcon,
	    fn () => (Con.bogus, Scheme.bogus ()),
	    "constructor",
	    Ast.Longcon.region,
	    Ast.Longcon.layout)
   val lookupLongstrid =
      make (peekLongstrid,
	    fn () => Structure.bogus,
	    "structure",
	    Ast.Longstrid.region,
	    Ast.Longstrid.layout)
   val lookupLongtycon =
      make (peekLongtycon,
	    TypeStr.bogus,
	    "type",
	    Ast.Longtycon.region,
	    Ast.Longtycon.layout)
   val lookupLongvid =
      make (peekLongvid,
	    fn () => (Vid.bogus, Scheme.bogus ()),
	    "variable",
	    Ast.Longvid.region,
	    Ast.Longvid.layout)
   val lookupLongvar =
      make (peekLongvar,
	    fn () => (Var.bogus, Scheme.bogus ()),
	    "variable",
	    Ast.Longvar.region,
	    Ast.Longvar.layout)
end

val peekLongcon = PeekResult.toOption o peekLongcon
val peekLongtycon = PeekResult.toOption o peekLongtycon
   
(* ------------------------------------------------- *)
(*                      extend                       *)
(* ------------------------------------------------- *)

local
   fun make get (T (fields as {currentScope, ...}), domain, range) =
      let
	 val ns = get fields
      in
	 NameSpace.update (ns, !currentScope,
			   {isUsed = ref false,
			    range = range,
			    values = NameSpace.values (ns, domain)})
      end
in
   val extendFctid = make #fcts
   val extendFix = make #fixs
   val extendFix =
      Trace.trace ("extendFix",
		   fn (_, x, f) => Layout.tuple [Ast.Vid.layout x,
						 Ast.Fixity.layout f],
		   Unit.layout)
      extendFix
   val extendSigid = make #sigs
   val extendStrid = make #strs
   val extendTycon = make #types
   val extendVals = make #vals
end

val extendTycon =
   Trace.trace3 ("extendTycon", layout, Ast.Tycon.layout, TypeStr.layout,
		 Unit.layout)
   extendTycon

fun extendCon (E, c, c', s) =
   extendVals (E, Ast.Vid.fromCon c, (Vid.Con c', s))
	       
fun extendExn (E, c, c', s) =
   extendVals (E, Ast.Vid.fromCon c, (Vid.Exn c', s))
	       
fun extendVar (E, x, x', s) =
   extendVals (E, Ast.Vid.fromVar x, (Vid.Var x', s))

fun extendOverload (E, x, yts, s) =
   extendVals (E, Ast.Vid.fromVar x, (Vid.Overload yts, s))

val extendVar =
   Trace.trace4
   ("extendVar", Layout.ignore, Ast.Var.layout, Var.layout, Scheme.layoutPretty,
    Unit.layout)
   extendVar

(* ------------------------------------------------- *)   
(*                       local                       *)
(* ------------------------------------------------- *)

local
   fun doit (info as NameSpace.T {current, ...}, s0) =
      let
	 val old = !current
	 val _ = current := []
      in
	 fn () =>
	 let
	    val c1 = !current
	    val _ = current := []
	 in
	    fn () =>
	    let
	       val c2 = !current
	       val lift = List.map (c2, Values.pop)
	       val _ = List.foreach (c1, fn v => (Values.pop v; ()))
	       val _ = current := old
	       val _ =
		  List.foreach2 (lift, c2, fn ({isUsed, value, ...}, values) =>
				 NameSpace.update
				 (info, s0, {isUsed = isUsed,
					     range = value,
					     values = values}))
	    in
	       ()
	    end
	 end
      end
in
   fun localTop (T {currentScope, fcts, fixs, sigs, strs, types, vals, ...}, f) =
      let
	 val s0 = !currentScope
	 val fcts = doit (fcts, s0)
	 val fixs = doit (fixs, s0)
	 val sigs = doit (sigs, s0)
	 val strs = doit (strs, s0)
	 val types = doit (types, s0)
	 val vals = doit (vals, s0)
	 val _ = currentScope := Scope.new ()
	 val a = f ()
	 val fcts = fcts ()
	 val fixs = fixs ()
	 val sigs = sigs ()
	 val strs = strs ()
	 val types = types ()
	 val vals = vals ()
	 fun finish g =
	    let
	       val _ = currentScope := Scope.new ()
	       val b = g ()
	       val _ = (fcts (); fixs (); sigs (); strs (); types (); vals ())
	       val _ = currentScope := s0
	    in
	       b
	    end
      in (a, finish)
      end

   fun localModule (T {currentScope, fixs, strs, types, vals, ...},
		    f1, f2) =
      let
	 val s0 = !currentScope
	 val fixs = doit (fixs, s0)
	 val strs = doit (strs, s0)
	 val types = doit (types, s0)
	 val vals = doit (vals, s0)
	 val _ = currentScope := Scope.new ()
	 val a1 = f1 ()
	 val fixs = fixs ()
	 val strs = strs ()
	 val types = types ()
	 val vals = vals ()
	 val _ = currentScope := Scope.new ()
	 val a2 = f2 a1
	 val _ = (fixs (); strs (); types (); vals ())
	 val _ = currentScope := s0
      in
	 a2
      end

   (* Can't eliminate the use of strs in localCore, because openn still modifies
    * module level constructs.
    *)
   val localCore = localModule
end

fun makeStructure (T {currentScope, fixs, strs, types, vals, ...}, make) =
   let
      val f = NameSpace.collect (fixs, Ast.Vid.<=)
      val s = NameSpace.collect (strs, Ast.Strid.<=)
      val t = NameSpace.collect (types, Ast.Tycon.<=)
      val v = NameSpace.collect (vals, Ast.Vid.<=)
      val s0 = !currentScope
      val _ = currentScope := Scope.new ()
      val res = make ()
      val _ = f ()
      val S = Structure.T {shapeId = NONE,
			   strs = s (),
			   types = t (),
			   vals = v ()}
      val _ = currentScope := s0
   in (res, S)
   end
      
fun scope (T {currentScope, fixs, strs, types, vals, ...}, th) =
   let
      fun doit (NameSpace.T {current, ...}) =
	 let
	    val old = !current
	    val _ = current := []
	 in fn () => (List.foreach (!current, fn v => (Values.pop v; ()))
		      ; current := old)
	 end
      val s0 = !currentScope
      val _ = currentScope := Scope.new ()
      val f = doit fixs 
      val s = doit strs
      val t = doit types
      val v = doit vals
      val res = th ()
      val _ = (f (); s (); t (); v ())
      val _ = currentScope := s0
   in res
   end

fun scopeAll (T {currentScope, fcts, fixs, sigs, strs, types, vals, ...}, th) =
   let
      fun doit (NameSpace.T {current, ...}) =
	 let
	    val old = !current
	    val _ = current := []
	 in fn () => (List.foreach (!current, fn v => (Values.pop v; ()))
		      ; current := old)
	 end
      val s0 = !currentScope
      val _ = currentScope := Scope.new ()
      val fc = doit fcts
      val f = doit fixs
      val si = doit sigs
      val s = doit strs
      val t = doit types
      val v = doit vals
      val res = th ()
      val _ = (fc (); f (); si (); s (); t (); v ())
      val _ = currentScope := s0
   in
      res
   end

fun openStructure (T {currentScope, strs, vals, types, ...},
		   Structure.T {strs = strs',
				vals = vals',
				types = types', ...}): unit =
   let
      val scope = !currentScope
      fun doit (info, Structure.Info.T a) =
	 Array.foreach (a, fn z => NameSpace.update (info, scope, z))
   in doit (strs, strs')
      ; doit (vals, vals')
      ; doit (types, types')
   end

(* ------------------------------------------------- *)
(*                  InterfaceMaker                   *)
(* ------------------------------------------------- *)

structure Env =
   struct
      datatype t = datatype t

      val lookupLongtycon = lookupLongtycon
   end

structure InterfaceMaker =
   struct
      structure NameSpace =
	 struct
	    open NameSpace

	    fun update (T {current, ...}, scope, {isUsed, range, values}) =
	       let
		  val ranges = Values.ranges values
		  fun new () =
		     let
			val value = {isUsed = isUsed,
				     scope = scope,
				     value = range}
		     in
			List.push (current, values)
			; List.push (ranges, value)
		     end
	       in
		  case !ranges of
		     [] => new ()
		   | {scope = scope', ...} :: l =>
			if Scope.equals (scope, scope')
			   then Control.error (Region.bogus,
					       Layout.str "duplicate spec",
					       Layout.empty)
			else new ()
	       end
	 end

      datatype t = T of {currentScope: Scope.t ref,
			 env: Env.t,
			 strs: (Ast.Strid.t, Interface.t) NameSpace.t,
			 types: (Ast.Tycon.t, Interface.TypeStr.t) NameSpace.t,
			 vals: (Ast.Vid.t, Status.t) NameSpace.t}

      local
	 fun make sel (T (fields as {currentScope, ...}), d, r) =
	    let
	       val info as NameSpace.T {equals, hash, table, ...} = sel fields
	    in NameSpace.update
	       (info, !currentScope,
		{isUsed = ref false,
		 range = r,
		 values =
		 HashSet.lookupOrInsert (table, hash d,
					 fn vs => equals (d, Values.domain vs),
					 fn () => Values.new d)})
	    end
      in
	 val addStrid = make #strs
	 val addTycon' = make #types
	 val addVid = make #vals
      end

      fun addCon (m, c) = addVid (m, Ast.Vid.fromCon c, Status.Con)
      fun addExcon (m, c) = addVid (m, Ast.Vid.fromCon c, Status.Exn)
      fun addVar (m, x) = addVid (m, Ast.Vid.fromVar x, Status.Var)
      fun addTycon (m as T {env = Env.T {vals, ...}, ...}, tyc, cons) =
	 let
(* 	    val cons =
 * 	       List.revMap
 * 	       (cons, fn c =>
 * 		{con = c,
 * 		 values = NameSpace.values (vals, Ast.Vid.fromCon c)})
 *)
	 in addTycon' (m, tyc,
		       if Vector.isEmpty cons
			  then Interface.TypeStr.Tycon
		       else Interface.TypeStr.Datatype {cons = cons})
	    ; Vector.foreach (cons, fn c => addCon (m, c))
	 end

      fun includeInterface (T {currentScope, strs, types, vals, ...},
			    Interface.T {strs = strs',
					 types = types',
					 vals = vals', ...}): unit =
	 let
	    val scope = !currentScope
	    fun doit (info, Interface.Info.T a) =
	       Array.foreach (a, fn z => NameSpace.update (info, scope, z))
	 in doit (strs, strs')
	    ; doit (vals, vals')
	    ; doit (types, types')
	 end

      fun lookupLongtycon (T {env, strs, types, ...},
			   x): Ast.Con.t vector =
	 let
	    val unbound =
	       fn () =>
	       (unbound (Ast.Longtycon.region x,
			 "type",
			 Ast.Longtycon.layout x)
		; Vector.new0 ())
	    fun lookInEnv () =
	       let
		  val typeStr = Env.lookupLongtycon (env, x)
	       in
		  Vector.map (TypeStr.cons typeStr, #name)
	       end
	    val (strids, tycon) = Ast.Longtycon.split x
	 in
	    case strids of
	       [] => (case NameSpace.peek (types, tycon) of
			 NONE => lookInEnv ()
		       | SOME typeStr => Interface.TypeStr.cons typeStr)
	     | s :: strids =>
		  (case NameSpace.peek (strs, s) of
		      NONE => lookInEnv ()
		    | SOME I =>
			 (case Interface.peekStrids (I, strids) of
			     NONE => unbound ()
			   | SOME I =>
				case Interface.peekTycon (I, tycon) of
				   NONE => unbound ()
				 | SOME typeStr =>
				      Interface.TypeStr.cons typeStr))
	 end

      fun makeInterface (T {currentScope, strs, types, vals, ...}, make) =
	 let
	    val strs = NameSpace.collect (strs, Ast.Strid.<=)
	    val types = NameSpace.collect (types, Ast.Tycon.<=)
	    val vals = NameSpace.collect (vals, Ast.Vid.<=)
	    val s0 = !currentScope
	    val _ = currentScope := Scope.new ()
	    val res = make ()
	    val I = Interface.T {id = ShapeId.new (),
				 strs = strs (),
				 types = types (),
				 vals = vals ()}
	    val _ = currentScope := s0
	 in (res, I)
	 end
   end

fun makeInterfaceMaker E =
   InterfaceMaker.T
   {currentScope = ref (Scope.new ()),
    env = E,
    strs = NameSpace.new let open Ast.Strid in (equals, hash) end,
    types = NameSpace.new let open Ast.Tycon in (equals, hash) end,
    vals = NameSpace.new let open Ast.Vid in (equals, hash) end}
   
end
