(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
functor ElaborateCore (S: ELABORATE_CORE_STRUCTS): ELABORATE_CORE = 
struct

open S

local
   open Ast
in 
   structure Aconst = Const
   structure Adec = Dec
   structure Aexp = Exp
   structure Amatch = Match
   structure Apat = Pat
   structure Atype = Type
   structure Avar = Var
   structure DatatypeRhs = DatatypeRhs
   structure DatBind = DatBind
   structure EbRhs = EbRhs
   structure Fixop = Fixop
   structure Longvid = Longvid
   structure Longtycon = Longtycon
   structure PrimKind = PrimKind
   structure Attribute = PrimKind.Attribute
   structure Record = Record
   structure SortedRecord = SortedRecord
   structure Strid = Strid
   structure TypBind = TypBind
end

local
   open Env
in
   structure TypeEnv = TypeEnv
   structure TypeStr = TypeStr
   structure Vid = Vid
end

local
   open TypeStr
in
   structure Cons = Cons
   structure Kind = Kind
end

local
   open TypeEnv
in
   structure Scheme = Scheme
   structure Type = Type
end

local
   open CoreML
in
   structure CFunction = CFunction
   structure Convention	 = CFunction.Convention	
   structure CType = CType
   structure Con = Con
   structure Const = Const
   structure Cdec = Dec
   structure Cexp = Exp
   structure Ffi = Ffi
   structure IntSize = IntSize
   structure IntX = IntX
   structure Lambda = Lambda
   structure Cpat = Pat
   structure Prim = Prim
   structure RealSize = RealSize
   structure RealX = RealX
   structure SourceInfo = SourceInfo
   structure Tycon = Tycon
   structure Tyvar = Tyvar
   structure Var = Var
   structure WordSize = WordSize
   structure WordX = WordX
end

structure AdmitsEquality = Tycon.AdmitsEquality

local
   open Record
in
   structure Field = Field
end

structure Parse = PrecedenceParse (structure Ast = Ast
				   structure Env = Env)

structure Scope = Scope (structure Ast = Ast)

structure Aconst =
   struct
      open Aconst

      fun ty (c: t): Type.t =
	 case node c of
	    Bool _ => Type.bool
	  | Char _ => Type.char
	  | Int _ => Type.unresolvedInt ()
	  | Real _ => Type.unresolvedReal ()
	  | String _ => Type.string
	  | Word _ => Type.unresolvedWord ()
   end

structure Apat =
   struct
      open Apat

      fun getName (p: t): string option =
	 case node p of
	    Var {name, ...} => SOME (Longvid.toString name)
	  | Constraint (p, _) => getName p
	  | FlatApp v =>
	       if 1 = Vector.length v
		  then getName (Vector.sub (v, 0))
	       else NONE
	  | Layered {var, ...} => SOME (Avar.toString var)
	  | _ => NONE

      val getName =
	 Trace.trace ("Apat.getName", layout, Option.layout String.layout)
	 getName
   end

structure Lookup =
   struct
      type t = Longtycon.t -> TypeStr.t

      fun fromFun f = f
      fun fromEnv (E: Env.t) longtycon = Env.lookupLongtycon (E, longtycon)
      fun lookup (l: t, c: Longtycon.t) = l c

      fun plusEnv (lookup: t, E: Env.t): t =
	 fn longtycon =>
	 case Env.peekLongtycon (E, longtycon) of
	    NONE => lookup longtycon
	  | SOME typeFcn => typeFcn

      fun plusTycons (f: t, v) =
	 if Vector.isEmpty v
	    then f
	 else
	    fn t => (case Longtycon.split t of
			([], t') =>
			   (case Vector.peek (v, fn (t'', _) =>
					      Ast.Tycon.equals (t', t'')) of
			       NONE => f t
			     | SOME (_, s) => s)
		      | _ => f t)
   end

fun elaborateType (ty: Atype.t, lookup: Lookup.t): Type.t =
   let 
      fun loop (ty: Atype.t): Type.t =
	 case Atype.node ty of
	    Atype.Var a => (* rule 44 *)
	       Type.var a
	  | Atype.Con (c, ts) => (* rules 46, 47 *)
	       let
		  val ts = Vector.map (ts, loop)
		  fun normal () =
		     let
			val s = lookup c
			val kind = TypeStr.kind s
			val numArgs = Vector.length ts
		     in
			if (case kind of
			       Kind.Arity n => n = numArgs
			     | Kind.Nary => true)
			   then TypeStr.apply (s, ts)
			else
			   let
			      open Layout
			      val _ = 
				 Control.error
				 (Atype.region ty,
				  seq [str "type constructor ",
				       Ast.Longtycon.layout c,
				       str " given ",
				       Int.layout numArgs,
				       str " arguments but wants ",
				       Kind.layout kind],
				  empty)
			   in
			      Type.new ()
			   end
		     end
	       in
		  case (Ast.Longtycon.split c, Vector.length ts) of
		     (([], c), 2) =>
			if Ast.Tycon.equals (c, Ast.Tycon.arrow)
			   then Type.arrow (Vector.sub (ts, 0),
					    Vector.sub (ts, 1))
			else normal ()
		   | _ => normal ()
	       end
	  | Atype.Record r => (* rules 45, 49 *)
	       Type.record (SortedRecord.map (r, loop))
   in
      loop ty
   end

fun elaborateTypeOpt (ty: Ast.Type.t option, lookup): Type.t option =
   Option.map (ty, fn ty => elaborateType (ty, lookup))

val overloads: (unit -> unit) list ref = ref []
val freeTyvarChecks: (unit -> unit) list ref = ref []

val {hom = typeTycon: Type.t -> Tycon.t option, ...} =
   Type.makeHom {con = fn (c, _) => SOME c,
		 var = fn _ => NONE}
   
fun resolveConst (c: Aconst.t, ty: Type.t): Const.t =
   let
      fun error m =
	 Control.error (Aconst.region c,
			Layout.str (concat [m, ": ", Aconst.toString c]),
			Layout.empty)
      val tycon =
	 case typeTycon ty of
	    NONE => Tycon.bogus
	  | SOME c => c
      fun choose (all, sizeTycon, name, make) =
	 case List.peek (all, fn s => Tycon.equals (tycon, sizeTycon s)) of
	    NONE => Const.string "<bogus>"
	  | SOME s => make s
   in
      case Aconst.node c of
	 Aconst.Bool _ => Error.bug "resolveConst can't handle bools"
       | Aconst.Char c =>
	    Const.Word (WordX.make (LargeWord.fromChar c, WordSize.W8))
       | Aconst.Int i =>
	    if Tycon.equals (tycon, Tycon.intInf)
	       then Const.IntInf i
	    else
	       choose (IntSize.all, Tycon.int, "int", fn s =>
		       Const.Int
		       (IntX.make (i, s)
			handle Overflow =>
			   (error (concat [Type.toString ty, " too big"])
			    ; IntX.zero s)))
       | Aconst.Real r =>
	    choose (RealSize.all, Tycon.real, "real", fn s =>
		    Const.Real (RealX.make (r, s)))
       | Aconst.String s => Const.string s
       | Aconst.Word w =>
	    choose (WordSize.all, Tycon.word, "word", fn s =>
		    Const.Word
		    (if w <= LargeWord.toIntInf (WordSize.max s)
			then WordX.fromLargeInt (w, s)
		     else (error (concat [Type.toString ty, " too big"])
			   ; WordX.zero s)))
   end

local
   open Layout
in
   val align = align
   val empty = empty
   val seq = seq
   val str = str
end

val unify = Type.unify
   
fun unifyList (trs: (Type.t * Region.t) vector,
	       lay: unit -> Layout.t): Type.t =
   if 0 = Vector.length trs
      then Type.list (Type.new ())
   else
      let
	 val (t, _) = Vector.sub (trs, 0)
	 val _ =
	    Vector.foreach
	    (trs, fn (t', r) =>
	     unify (t, t', fn (l, l') =>
		    (r,
		     str "list elements of different types",
		     align [seq [str "element:  ", l'],
			    seq [str "previous: ", l],
			    lay ()])))
      in
	 Type.list t
      end

val info = Trace.info "elaboratePat"

structure Var =
   struct
      open Var

      val fromAst = fromString o Avar.toString
   end

val allowRebindEquals = ref true
   
local
   val eq = Avar.fromString ("=", Region.bogus)
in
   fun extendVar (E, x, x', s, region) =
      if not (!allowRebindEquals) andalso Avar.equals (x, eq)
	 then
	    let
	       open Layout
	    in
	       Control.error (region, str "= can't be redefined", empty)
	    end
      else Env.extendVar (E, x, x', s)
end

fun elaboratePat (p: Apat.t, E: Env.t, amInRvb: bool)
   : Cpat.t * (Avar.t * Var.t * Type.t) vector =
   let
      val region = Apat.region p
      val xts: (Avar.t * Var.t * Type.t) list ref = ref []
      fun bindToType (x: Avar.t, t: Type.t): Var.t =
	 let
	    val x' = Var.fromAst x
	    val _ = List.push (xts, (x, x', t))
	    val _ = extendVar (E, x, x', Scheme.fromType t, region)
	 in
	    x'
	 end
      fun bind (x: Avar.t): Var.t * Type.t =
	 let
	    val t = Type.new ()
	 in
	    (bindToType (x, t), t)
	 end
      fun loop arg: Cpat.t =
	 Trace.traceInfo' (info, Apat.layout, Cpat.layout)
	 (fn p: Apat.t =>
	  let
	     val region = Apat.region p
	     fun unifyPatternConstraint (p, lay, c) =
		unify
		(p, c, fn (l1, l2) =>
		 (region,
		  str "pattern and constraint disagree",
		  align [seq [str "pattern:    ", lay ()],
			 seq [str "of type:    ", l1],
			 seq [str "constraint: ", l2]]))
	     fun lay () = Apat.layout p
	  in
	     case Apat.node p of
		Apat.App (c, p) =>
		   let
		      val (con, s) = Env.lookupLongcon (E, c)
		      val {args, instance} = Scheme.instantiate s
		      val args = args ()
		      val p = loop p
		      val argType = Type.new ()
		      val resultType = Type.new ()
		      val _ =
			 unify
			 (instance, Type.arrow (argType, resultType), fn _ =>
			  (region,
			   str "constant constructor applied to argument",
			   seq [str "pattern: ", lay ()]))
		      val _ =
			 unify
			 (Cpat.ty p, argType, fn (l, l') =>
			  (region,
			   str "constructor applied to incorrect argument",
			   align [seq [str "expects: ", l'],
				  seq [str "but got: ", l],
				  seq [str "pattern: ", lay ()]]))
		   in
		      Cpat.make (Cpat.Con {arg = SOME p,
					   con = con,
					   targs = args},
				 resultType)
		   end
	      | Apat.Const c =>
		   (case Aconst.node c of
		       Aconst.Bool b => if b then Cpat.truee else Cpat.falsee
		     | _ => 
			  let
			     val ty = Aconst.ty c
			     fun resolve () = resolveConst (c, ty)
			     val _ = List.push (overloads, fn () =>
						(resolve (); ()))
			  in
			     Cpat.make (Cpat.Const resolve, ty)
			  end)
	      | Apat.Constraint (p, t) =>
		   let
		      val p' = loop p
		      val _ =
			 unifyPatternConstraint
			 (Cpat.ty p', fn () => Apat.layout p,
			  elaborateType (t, Lookup.fromEnv E))
		   in
		      p'
		   end
	      | Apat.FlatApp items =>
		   loop (Parse.parsePat
			 (items, E, fn () => seq [str "pattern: ", lay ()]))
	      | Apat.Layered {var = x, constraint, pat, ...} =>
		   let
		      val t =
			 case constraint of
			    NONE => Type.new ()
			  | SOME t => elaborateType (t, Lookup.fromEnv E)
		      val x = bindToType (x, t)
		      val pat' = loop pat
		      val _ =
			 unifyPatternConstraint (Cpat.ty pat',
						 fn () => Apat.layout pat,
						 t)
		   in
		      Cpat.make (Cpat.Layered (x, pat'), t)
		   end
	      | Apat.List ps =>
		   let
		      val ps' = Vector.map (ps, loop)
		   in
		      Cpat.make (Cpat.List ps',
				 unifyList
				 (Vector.map2 (ps, ps', fn (p, p') =>
					       (Cpat.ty p', Apat.region p)),
				  fn () => seq [str "pattern:  ", lay ()]))
		   end
	      | Apat.Record {flexible, items} =>
		   (* rules 36, 38, 39 and Appendix A, p.57 *)
		   let
		      val (fs, ps) =
			 Vector.unzip
			 (Vector.map
			  (items,
			   fn Apat.Item.Field fp => fp
			    | Apat.Item.Vid (vid, tyo, po) =>
				 (Field.String (Ast.Vid.toString vid),
				  let
				     val p =
					case po of
					   NONE =>
					      Apat.longvid (Longvid.short vid)
					 | SOME p =>
					      Apat.layered
					      {fixop = Fixop.None,
					       var = Ast.Vid.toVar vid,
					       constraint = NONE,
					       pat = p}
				  in
				     case tyo of
					NONE => p
				      | SOME ty => Apat.constraint (p, ty)
				  end)))
		      val ps = Vector.map (ps, loop)
		      val r = SortedRecord.zip (fs, Vector.map (ps, Cpat.ty))
		      val ty =
			 if flexible
			    then
			       let
				  val (t, isResolved) = Type.flexRecord r
				  fun resolve () =
				     if isResolved ()
					then ()
				     else
					Control.error
					(region,
					 str "unresolved ... in record pattern",
					 seq [str "pattern: ", lay ()])
				  val _ = List.push (overloads, resolve)
			       in
				  t
			       end
			 else
			    Type.record r
		   in
		      Cpat.make
		      (Cpat.Record (Record.fromVector (Vector.zip (fs, ps))),
		       ty)
		   end
	      | Apat.Tuple ps =>
		   let
		      val ps = Vector.map (ps, loop)
		   in
		      Cpat.make (Cpat.Tuple ps,
				 Type.tuple (Vector.map (ps, Cpat.ty)))
		   end
	      | Apat.Var {name, ...} =>
		   let
		      val (strids, x) = Ast.Longvid.split name
		      fun var () =
			 let
			    val (x, t) = bind (Ast.Vid.toVar x)
			 in
			    Cpat.make (Cpat.Var x, t)
			 end

		   in
		      if amInRvb andalso List.isEmpty strids
			 then var ()
		      else
			 (case Env.peekLongcon (E, Ast.Longvid.toLongcon name) of
			     NONE =>
				if List.isEmpty strids
				   then var ()
				else
				   let
				      val _ = 
					 Control.error
					 (region,
					  seq [str "undefined constructor: ",
					       Ast.Longvid.layout name],
					  empty)
				   in
				      Cpat.make (Cpat.Wild, Type.new ())
				   end
			   | SOME (c, s) =>
				let
				   val {args, instance} = Scheme.instantiate s
				in
				   Cpat.make
				   (Cpat.Con {arg = NONE, con = c, targs = args ()},
				    instance)
				end)
		   end
	      | Apat.Wild =>
		   Cpat.make (Cpat.Wild, Type.new ())
	  end) arg
      val p = loop p
   in
      (p, Vector.fromList (!xts))
   end

(*---------------------------------------------------*)
(*                   Declarations                    *)
(*---------------------------------------------------*)

structure Nest =
   struct
      type t = string list

      val layout = List.layout String.layout
   end

val info = Trace.info "elaborateDec"
val elabExpInfo = Trace.info "elaborateExp"

structure CType =
   struct
      open CoreML.CType

      fun sized (all: 'a list,
		 toString: 'a -> string,
		 prefix: string,
		 make: 'a -> t,
		 makeType: 'a -> 'b) =
	 List.map (all, fn a =>
		   (make a, concat [prefix, toString a], makeType a))

      val nullary: (t * string * Tycon.t) list =
	 [(bool, "Bool", Tycon.bool),
	  (char, "Char", Tycon.char),
	  (pointer, "Pointer", Tycon.pointer),
	  (pointer, "Pointer", Tycon.preThread),
	  (pointer, "Pointer", Tycon.thread)]
	 @ sized (IntSize.all, IntSize.toString, "Int", Int, Tycon.int)
	 @ sized (RealSize.all, RealSize.toString, "Real", Real, Tycon.real)
	 @ sized (WordSize.all, WordSize.toString, "Word", Word, Tycon.word)

      val unary: Tycon.t list =
	 [Tycon.array, Tycon.reff, Tycon.vector]

      fun fromType (t: Type.t): (t * string) option =
	 case Type.deConOpt t of
	    NONE => NONE
	  | SOME (c, ts) =>
	       case List.peek (nullary, fn (_, _, c') => Tycon.equals (c, c')) of
		  NONE =>
		     if List.exists (unary, fn c' => Tycon.equals (c, c'))
			andalso 1 = Vector.length ts
			andalso isSome (fromType (Vector.sub (ts, 0)))
			then SOME (Pointer, "Pointer")
		     else NONE
		| SOME (t, s, _) => SOME (t, s)

      val fromType =
	 Trace.trace ("Ctype.fromType",
		      Type.layoutPretty,
		      Option.layout (Layout.tuple2 (layout, String.layout)))
	 fromType

      fun parse (ty: Type.t)
	 : ((t * string) vector * (t * string) option) option =
	 case Type.deArrowOpt ty of
	    NONE => NONE
	  | SOME (t1, t2) =>
	       let
		  fun finish (ts: (t * string) vector) =
		     case fromType t2 of
			NONE =>
			   if Type.isUnit t2
			      then SOME (ts, NONE)
			   else NONE
		      | SOME t => SOME (ts, SOME t)
	       in
		  case Type.deTupleOpt t1 of 
		     NONE =>
			(case fromType t1 of
			    NONE => NONE
			  | SOME u => finish (Vector.new1 u))
		   | SOME ts =>
			let
			   val us = Vector.map (ts, fromType)
			in
			   if Vector.forall (us, isSome)
			      then finish (Vector.map (us, valOf))
			   else NONE
			end
	       end
   end

fun parseAttributes (attributes: Attribute.t list): Convention.t option =
   case attributes of
      [] => SOME Convention.Cdecl
    | [a] =>
	 SOME (case a of
		  Attribute.Cdecl => Convention.Cdecl
		| Attribute.Stdcall =>
		     if !Control.targetOS = MLton.Platform.OS.Cygwin
			then Convention.Stdcall
		     else Convention.Cdecl)
    | _ => NONE

fun import {attributes: Attribute.t list,
	    name: string,
	    ty: Type.t,
	    region: Region.t}: Prim.t =
   let
      fun error l = Control.error (region, l, Layout.empty)
      fun invalidAttributes () =
	 error (seq [str "invalid attributes for import: ",
		     List.layout Attribute.layout attributes])
   in
      case CType.parse ty of
	 NONE =>
	    (case CType.fromType ty of
		NONE => 
		   let
		      val _ =
			 Control.error
			 (region,
			  str "invalid type for import:",
			  Type.layoutPretty ty)
		   in
		      Prim.bogus
		   end
	      | SOME (t, _) =>
		   case attributes of
		      [] => Prim.ffiSymbol {name = name, ty = t}
		    | _ => 
			 let
			    val _ = invalidAttributes ()
			 in
			    Prim.bogus
			 end)
       | SOME (args, result) =>
	    let
	       val convention =
		  case parseAttributes attributes of
		     NONE => (invalidAttributes ()
			      ; Convention.Cdecl)
		   | SOME c => c
	       val func =
		  CFunction.T {args = Vector.map (args, #1),
			       bytesNeeded = NONE,
			       convention = convention,
			       ensuresBytesFree = false,
			       modifiesFrontier = true,
			       modifiesStackTop = true,
			       mayGC = true,
			       maySwitchThreads = false,
			       name = name,
			       return = Option.map (result, #1)}
	    in
	       Prim.ffi func
	    end
   end

fun export {attributes, name: string, region: Region.t, ty: Type.t}: Aexp.t =
   let
      fun error l = Control.error (region, l, Layout.empty)
      fun invalidAttributes () =
	 error (seq [str "invalid attributes for export: ",
		     List.layout Attribute.layout attributes])
      val convention =
	 case parseAttributes attributes of
	    NONE => (invalidAttributes ()
		     ; Convention.Cdecl)
	  | SOME c => c
      val (exportId, args, res) =
	 case CType.parse ty of
	    NONE =>
	       (Control.error
		(region,
		 seq [str "invalid type for exported function: ",
		      Type.layout ty],
		 Layout.empty)
		; (0, Vector.new0 (), NONE))
	  | SOME (us, t) =>
	       let
		  val id = Ffi.addExport {args = Vector.map (us, #1),
					  convention = convention,
					  name = name,
					  res = Option.map (t, #1)}
	       in
		  (id, us, t)
	       end
      open Ast
      fun id name =
	 Aexp.longvid (Longvid.short (Vid.fromString (name, region)))
      fun int (i: int): Aexp.t =
	 Aexp.const (Aconst.makeRegion (Aconst.Int (IntInf.fromInt i), region))
      val f = Var.fromString ("f", region)
   in
      Exp.fnn
      (Vector.new1
       (Pat.var f,
	Exp.app
	(id "register",
	 Exp.tuple
	 (Vector.new2
	  (int exportId,
	   Exp.fnn
	   (Vector.new1
	    (Pat.tuple (Vector.new0 ()),
	     let
		val map = CType.memo (fn _ => Counter.new 0)
		val varCounter = Counter.new 0
		val (args, decs) =
		   Vector.unzip
		   (Vector.map
		    (args, fn (u, name) =>
		     let
			val x =
			   Var.fromString
			   (concat ["x",
				    Int.toString (Counter.next varCounter)],
			    region)
			val dec =
			   Dec.vall (Vector.new0 (),
				     x,
				     Exp.app (id (concat ["get", name]),
					      int (Counter.next (map u))))
		     in
			(x, dec)
		     end))
		val resVar = Var.fromString ("res", region)
		fun newVar () = Var.fromString ("none", region)
	     in
		Exp.lett
		(Vector.concat
		 [decs,
		  Vector.map 
		  (Vector.new4
		   ((newVar (), Exp.app (id "atomicEnd", Exp.unit)),
		    (resVar, Exp.app (Exp.var f,
				      Exp.tuple (Vector.map (args, Exp.var)))),
		    (newVar (), Exp.app (id "atomicBegin", Exp.unit)),
		    (newVar (),
		     (case res of
			 NONE => Exp.unit
		       | SOME (t, name) => 
			    Exp.app (id (concat ["set", name]),
				     Exp.var resVar)))),
		   fn (x, e) => Dec.vall (Vector.new0 (), x, e))],
		 Exp.tuple (Vector.new0 ()))
	     end)))))))
   end

structure Aexp =
   struct
      open Aexp

      fun selector (f: Field.t, r: Region.t): t =
	 let
	    val x = Avar.fromString ("x", r)
	 in
	    fnn (Vector.new1
		 (Apat.makeRegion
		  (Apat.Record {flexible = true,
				items = (Vector.new1
					 (Apat.Item.Field (f, Apat.var x)))},
		   r),
		  var x))
	 end
   end

structure Con =
   struct
      open Con

      val fromAst = fromString o Ast.Con.toString
   end

fun approximate (l: Layout.t): Layout.t =
   let
      val s = Layout.toString l
      val n = String.size s
   in
      Layout.str
      (if n <= 60
	  then s
       else concat [String.prefix (s, 35), "  ...  ", String.suffix (s, 25)])
   end
   
fun elaborateDec (d, {env = E,
		      lookupConstant: string * ConstType.t -> CoreML.Const.t,
		      nest}) =
   let
      val {get = recursiveTargs: Var.t -> (unit -> Type.t vector) option ref,
	   ...} =
	 Property.get (Var.plist, Property.initFun (fn _ => ref NONE))
      fun recursiveFun () =
	 let
	    val boundRef: (unit -> Tyvar.t vector) option ref = ref NONE
	    val targs =
	       Promise.lazy
	       (fn () =>
		case !boundRef of
		   NONE => Error.bug "boundRef not set"
		 | SOME f => Vector.map (f (), Type.var))
	    fun markFunc func = recursiveTargs func := SOME targs
	    fun unmarkFunc func = recursiveTargs func := NONE
	    fun setBound b = boundRef := SOME b
	 in
	    {markFunc = markFunc,
	     setBound = setBound,
	     unmarkFunc = unmarkFunc}
	 end  
      fun elabType (t: Atype.t): Type.t =
	 elaborateType (t, Lookup.fromEnv E)
      fun elabTypeOpt t = elaborateTypeOpt (t, Lookup.fromEnv E)
      fun elabTypBind (typBind: TypBind.t) =
	 let
	    val TypBind.T types = TypBind.node typBind
	    val strs =
	       List.map
	       (types, fn {def, tyvars, ...} =>
		TypeStr.def (Scheme.make {canGeneralize = true,
					  ty = elabType def,
					  tyvars = tyvars},
			     Kind.Arity (Vector.length tyvars)))
	 in
	    List.foreach2
	    (types, strs, fn ({tycon, ...}, str) =>
	     Env.extendTycon (E, tycon, str))
	 end
      fun elabDatBind (datBind: DatBind.t, nest: string list)
	 : Decs.t * {tycon: Ast.Tycon.t,
		     typeStr: TypeStr.t} vector =
	 (* rules 28, 29, 81, 82 *)
	 let
	    val region = DatBind.region datBind
	    val DatBind.T {datatypes, withtypes} = DatBind.node datBind
	    (* Build enough of an env so that that the withtypes and the
	     * constructor argument types can be elaborated.
	     *)
	    val tycons =
	       Vector.map
	       (datatypes, fn {cons, tycon = name, tyvars} =>
		let
		   val tycon =
		      Tycon.fromString
		      (concat (List.separate
			       (rev (Ast.Tycon.toString name :: nest),
				".")))
		   val _ =
		      Env.extendTycon
		      (E, name,
		       TypeStr.tycon (tycon, Kind.Arity (Vector.length tyvars)))
		in
		   tycon
		end)
	    val change = ref false
	    fun elabAll () =
	       (elabTypBind withtypes
		; (Vector.map2
		   (tycons, datatypes,
		    fn (tycon, {cons, tycon = astTycon, tyvars, ...}) =>
		    let
		       val resultType: Type.t =
			  Type.con (tycon, Vector.map (tyvars, Type.var))
		       val (cons, datatypeCons) =
			  Vector.unzip
			  (Vector.map
			   (cons, fn (name, arg) =>
			    let
			       val con = Con.fromAst name
			       val (arg, ty) =
				  case arg of
				     NONE => (NONE, resultType)
				   | SOME t =>
					let
					   val t = elabType t
					in
					   (SOME t, Type.arrow (t, resultType))
					end
			       val scheme =
				  Scheme.make {canGeneralize = true,
					       ty = ty,
					       tyvars = tyvars}
			       val _ = Env.extendCon (E, name, con, scheme)
			    in
			       ({con = con, name = name, scheme = scheme},
				{arg = arg, con = con})
			    end))
		       val _ =
			  let
			     val r = TypeEnv.tyconAdmitsEquality tycon
			     datatype z = datatype AdmitsEquality.t
			  in
			     case !r of
				Always => Error.bug "datatype Always"
			      | Never => ()
			      | Sometimes =>
				   if Vector.forall
				      (datatypeCons, fn {arg, ...} =>
				       case arg of
					  NONE => true
					| SOME ty =>
					     Scheme.admitsEquality
					     (Scheme.make {canGeneralize = true,
							   ty = ty,
							   tyvars = tyvars}))
				      then ()
				   else (r := Never; change := true)
			  end
		    val typeStr =
		       TypeStr.data (tycon,
				     Kind.Arity (Vector.length tyvars),
				     Cons.T cons)
		    val _ = Env.extendTycon (E, astTycon, typeStr)
		 in
		    ({cons = datatypeCons,
		      tycon = tycon,
		      tyvars = tyvars},
		     {tycon = astTycon,
		      typeStr = typeStr})
		 end)))
	    (* Maximize equality. *)
	    fun loop () =
	       let
		  val res = elabAll ()
	       in
		  if !change
		     then (change := false; loop ())
		  else res
	       end
	    val (dbs, strs) = Vector.unzip (loop ())
	 in
	    (Decs.single (Cdec.Datatype dbs), strs)
	 end
      fun elabDec arg : Decs.t =
	 Trace.traceInfo
	 (info,
	  Layout.tuple3 (Ast.Dec.layout, Nest.layout, Bool.layout),
	  Layout.ignore, Trace.assertTrue)
	 (fn (d, nest, isTop) =>
	  let
	     fun lay () = seq [str "in: ", approximate (Adec.layout d)]
	     val region = Adec.region d
	     fun checkSchemes (v: (Var.t * Scheme.t) vector): unit =
		if isTop
		   then
		      List.push
		      (freeTyvarChecks,
		       fn () =>
		       Vector.foreach2
		       (v, Scheme.haveFrees (Vector.map (v, #2)),
			fn ((x, s), b) =>
			if b
			   then
			      let
				 open Layout
			      in
				 Control.error
				 (region,
				  seq [str "unable to infer type for ",
				       Var.layout x],
				  align [seq [str "type: ", Scheme.layoutPretty s],
					 lay ()])
			      end
			else ()))
		else ()
	     val elabDec = fn (d, isTop) => elabDec (d, nest, isTop)
	  in
	     case Adec.node d of
		Adec.Abstype {datBind, body} => (* rule 19 and p.57 *)
		   let
		      val ((decs, strs), decs') =
			 Env.localCore
			 (E,
			  fn () => elabDatBind (datBind, nest),
			  fn z => (z, elabDec (body, isTop)))
		      val _ =
			 Vector.foreach
			 (strs, fn {tycon, typeStr} =>
			  Env.extendTycon (E, tycon, TypeStr.abs typeStr))
		   in
		      Decs.append (decs, decs')
		   end
	      | Adec.Datatype rhs =>
		   (case DatatypeRhs.node rhs of
		       DatatypeRhs.DatBind datBind => (* rule 17 *)
			  #1 (elabDatBind (datBind, nest))
		     | DatatypeRhs.Repl {lhs, rhs} => (* rule 18 *)
			  let
			     val tyStr = Env.lookupLongtycon (E, rhs)
			     val _ = Env.extendTycon (E, lhs, tyStr)
			     val TypeStr.Cons.T v = TypeStr.cons tyStr
			     val _ =
				Vector.foreach
				(v, fn {con, name, scheme} =>
				 Env.extendCon (E, name, con, scheme))
			  in
			     Decs.empty
			  end)
	      | Adec.Exception ebs =>
		   let
		      val decs =
			 Vector.fold
			 (ebs, Decs.empty, fn ((exn, rhs), decs) =>
			  let
			     val (decs, exn', scheme) =
				case EbRhs.node rhs of
				   EbRhs.Def c =>
				      let
					 val (c, s) = Env.lookupLongcon (E, c)
				      in
					 (decs, c, s)
				      end
				 | EbRhs.Gen arg =>
				      let
					 val exn' = Con.fromAst exn
					 val (arg, ty) =
					    case arg of
					       NONE => (NONE, Type.exn)
					     | SOME t =>
						  let
						     val t = elabType t
						  in
						     (SOME t,
						      Type.arrow (t, Type.exn))
						  end
					 val scheme = Scheme.fromType ty
				      in
					 (Decs.add (decs,
						    Cdec.Exception {arg = arg,
								    con = exn'}),
					  exn',
					  scheme)
				      end
			     val _ = Env.extendExn (E, exn, exn', scheme)
			  in
			     decs
			  end)
		   in
		      decs
		   end
	      | Adec.Fix {ops, fixity} =>
		   (Vector.foreach (ops, fn op' =>
				    Env.extendFix (E, op', fixity))
		    ; Decs.empty)
	      | Adec.Fun (tyvars, fbs) =>
		   let
		      val fbs =
			 Vector.map
			 (fbs, fn clauses =>
			  Vector.map
			  (clauses, fn {body, pats, resultType} =>
			   let
			      fun lay () =
				 approximate
				 (let
				     open Layout
				  in
				     seq [seq (List.separate
					       (Vector.toListMap
						(pats, Apat.layoutDelimit),
						str " ")),
					  str " = ",
					  Aexp.layout body]
				  end)
			      val {args, func} =
				 Parse.parseClause (pats, E, region, lay)
			   in
			      {args = args,
			       body = body,
			       func = func,
			       lay = lay,
			       resultType = resultType}
			   end))
		      val close = TypeEnv.close (tyvars, region)
		      val {markFunc, setBound, unmarkFunc} = recursiveFun ()
		      val fbs =
			 Vector.map
			 (fbs, fn clauses =>
			  if Vector.isEmpty clauses
			     then Error.bug "no clauses in fundec"
			  else
			     let
				val {args, func, ...} = Vector.sub (clauses, 0)
				val numArgs = Vector.length args
				val _ =
				   Vector.foreach
				   (clauses, fn {args, ...} =>
				    if numArgs = Vector.length args
				       then ()
				    else
				       Control.error
				       (region,
					seq [str "function defined with different numbers of arguments"],
					lay ()))
				val diff =
				   Vector.fold
				   (clauses, [], fn ({func = func', ...}, ac) =>
				    if Avar.equals (func, func')
				       then ac
				    else func' :: ac)
				val _ =
				   case diff of
				      [] => ()
				    | fs =>
					 let
					    val diff =
					       List.removeDuplicates
					       (func :: diff, Avar.equals)
					 in
					    Control.error
					    (region,
					     seq [str "function defined with multiple names: ",
						  seq (Layout.separateRight
						       (List.map (diff,
								  Avar.layout),
							", "))],
					     lay ())
					 end
				val var = Var.fromAst func
				val ty = Type.new ()
				val _ = Env.extendVar (E, func, var,
						       Scheme.fromType ty)
				val _ = markFunc var
			     in
				{clauses = clauses,
				 func = func,
				 ty = ty,
				 var = var}
			     end)
		      val decs =
			 Vector.map
			 (fbs, fn {clauses,
				   func: Avar.t,
				   ty: Type.t,
				   var: Var.t} =>
			  let
			     val nest = Avar.toString func :: nest
			     val sourceInfo =
				SourceInfo.function {name = nest,
						     region = Avar.region func}
			     val rs =
				Vector.map
				(clauses, fn {args: Apat.t vector,
					      body: Aexp.t,
					      lay: unit -> Layout.t,
					      resultType: Atype.t option, ...} =>
				 Env.scope
				 (E, fn () =>
				  let
				     val pats =
					Vector.map
					(args, fn p =>
					 {pat = #1 (elaboratePat (p, E, false)),
					  region = Apat.region p})
				     val bodyRegion = Aexp.region body
				     val body = elabExp (body, nest)
				     val _ =
					Option.app
					(resultType, fn t =>
					 unify
					 (elabType t, Cexp.ty body,
					  fn (l1, l2) =>
					  (Atype.region t,
					   str "function result type disagrees with expression",
					   align
					   [seq [str "result type: ", l1],
					    seq [str "expression:  ", l2],
					    lay ()])))
				  in
				     {body = body,
				      bodyRegion = bodyRegion,
				      lay = lay,
				      pats = pats}
				  end))
			     val numArgs =
				Vector.length (#pats (Vector.sub (rs, 0)))
			     val argTypes =
				Vector.tabulate
				(numArgs, fn i =>
				 let
				    val t =
				       Cpat.ty
				       (#pat (Vector.sub
					      (#pats (Vector.sub (rs, 0)),
					       i)))
				    val _ =
				       Vector.foreach
				       (rs, fn {pats, ...} =>
					let
					   val {pat, region} =
					      Vector.sub (pats, i)
					in
					   unify
					   (t, Cpat.ty pat, fn (l1, l2) =>
					    (region,
					     str "function with argument of different types",
					     align [seq [str "argument: ", l2],
						    seq [str "previous: ", l1],
						    lay ()]))
					end)
				 in
				    t
				 end)
			     val bodyType =
				let
				   val t = Cexp.ty (#body (Vector.sub (rs, 0)))
				   val _ =
				      Vector.foreach
				      (rs, fn {body, bodyRegion, ...} =>
				       unify
				       (t, Cexp.ty body, fn (l1, l2) =>
					(bodyRegion,
					 str "function with results of different types",
					 align [seq [str "result:   ", l2],
						seq [str "previous: ", l1],
						lay ()])))
				in
				   t
				end
			     val xs =
				Vector.tabulate (numArgs, fn _ =>
						 Var.newNoname ())
			     fun make (i: int): Cexp.t =
				if i = Vector.length xs
				   then
				      let
					 val e =
					    Cexp.casee
					    {kind = "function",
					     lay = lay,
					     noMatch = Cexp.RaiseMatch,
					     region = region,
					     rules =
					     Vector.map
					     (rs, fn {body, lay, pats, ...} =>
					      let
						 val pats =
						    Vector.map (pats, #pat)
					      in
						 {exp = body,
						  lay = SOME lay,
						  pat =
						  (Cpat.make
						   (Cpat.Tuple pats,
						    Type.tuple
						    (Vector.map (pats, Cpat.ty))))}
					      end),
					     test = 
					     Cexp.tuple
					     (Vector.map2
					      (xs, argTypes, Cexp.var))}
				      in
					 Cexp.enterLeave (e, sourceInfo)
				      end
				else
				   let
				      val body = make (i + 1)
				      val argType = Vector.sub (argTypes, i)
				   in
				      Cexp.make
				      (Cexp.Lambda
				       (Lambda.make
					{arg = Vector.sub (xs, i),
					 argType = argType,
					 body = body}),
				       Type.arrow (argType, Cexp.ty body))
				   end
			     val lambda = make 0
			     val _ =
				unify
				(Cexp.ty lambda, ty, fn (l1, l2) =>
				 (Avar.region func,
				  str "function type disagrees with recursive uses",
				  align [seq [str "function type:  ", l1],
					 seq [str "recursive uses: ", l2],
					 lay ()]))
			     val lambda =
				case Cexp.node lambda of
				   Cexp.Lambda l => l
				 | _ => Lambda.bogus
			  in
			     {lambda = lambda,
			      ty = ty,
			      var = var}
			  end)
		      val {bound, schemes} = close (Vector.map (decs, #ty))
		      val _ = checkSchemes (Vector.zip
					    (Vector.map (decs, #var),
					     schemes))
		      val _ = setBound bound
		      val _ =
			 Vector.foreach3
			 (fbs, decs, schemes,
			  fn ({func, ...}, {var, ...}, scheme) =>
			  (Env.extendVar (E, func, var, scheme)
			   ; unmarkFunc var))
		      val decs =
			 Vector.map (decs, fn {lambda, var, ...} =>
				     {lambda = lambda, var = var})
		   in
		      Decs.single (Cdec.Fun {decs = decs,
					     tyvars = bound})
		   end
	      | Adec.Local (d, d') =>
		   Env.localCore
		   (E,
		    fn () => elabDec (d, false),
		    fn decs => Decs.append (decs, elabDec (d', isTop)))
	      | Adec.Open paths =>
		   let
		      (* The following code is careful to first lookup all of the
		       * paths in the current environment, and then extend the
		       * environment with all of the results.
		       * See rule 22 of the Definition.
		       *)
		      val _ =
			 Vector.foreach
			 (Vector.map (paths, fn p => Env.lookupLongstrid (E, p)),
			  fn s => Env.openStructure (E, s))
		   in
		      Decs.empty
		   end
	      | Adec.Overload (x, tyvars, ty, xs) =>
		   let
		      (* Lookup the overloads before extending the var in case
		       * x appears in the xs.
		       *)
		      val ovlds =
			 Vector.map (xs, fn x => Env.lookupLongvar (E, x))
		      val _ =
			 Env.extendOverload
			 (E, x, 
			  Vector.map (ovlds, fn (x, s) => (x, Scheme.ty s)),
			  Scheme.make {canGeneralize = false,
				       tyvars = tyvars,
				       ty = elabType ty})
		   in
		      Decs.empty
		   end
	      | Adec.SeqDec ds =>
		   Vector.fold (ds, Decs.empty, fn (d, decs) =>
				Decs.append (decs, elabDec (d, isTop)))
	      | Adec.Type typBind =>
		   (elabTypBind typBind
		    ; Decs.empty)
	      | Adec.Val {tyvars, rvbs, vbs} =>
		   let
		      val close = TypeEnv.close (tyvars, region)
		      (* Must do all the es and rvbs before the ps because of
		       * scoping rules.
		       *)
		      val vbs =
			 Vector.map
			 (vbs, fn {exp, pat, ...} =>
			  let
			     fun lay () =
				let
				   open Layout
				in
				   approximate
				   (seq [str "in: ", Apat.layout pat,
					 str " = ", Aexp.layout exp])
				end
			  in
			     {exp = elabExp (exp,
					     case Apat.getName pat of
						NONE => "anon" :: nest
					      | SOME s => s :: nest),
			      expRegion = Aexp.region exp,
			      lay = lay,
			      pat = pat,
			      patRegion = Apat.region pat}
			  end)
		      val close =
			 case Vector.peek (vbs, Cexp.isExpansive o #exp) of
			    NONE => close
			  | SOME {expRegion, ...} => 
			       let
				  val _ =
				     if Vector.isEmpty tyvars
					then ()
				     else
					Control.error
					(expRegion,
					 seq [str "can't bind type variables: ",
					      seq (Layout.separateRight
						   (Vector.toListMap (tyvars, Tyvar.layout),
						    ", "))],
					 lay ())
			       in
				  fn tys => {bound = fn () => Vector.new0 (),
					     schemes =
					     Vector.map (tys, Scheme.fromType)}
			       end
		      val {markFunc, setBound, unmarkFunc} = recursiveFun ()
		      val rvbs =
			 Vector.map
			 (rvbs, fn {pat, match} =>
			  let
			     val region = Apat.region pat
			     val (pat, bound) = elaboratePat (pat, E, true)
			     val (nest, var, ty) =
				if 0 = Vector.length bound
				   then ("anon" :: nest,
					 Var.newNoname (),
					 Type.new ())
				else
				   let
				      val (x, x', t) = Vector.sub (bound, 0)
				   in
				      (Avar.toString x :: nest, x', t)
				   end
			     val _ = markFunc var
			     val scheme = Scheme.fromType ty
			     val bound =
				Vector.map
				(bound, fn (x, _, _) =>
				 (Env.extendVar (E, x, var, scheme)
				  ; (x, var, ty)))
			  in
			     {bound = bound,
			      match = match,
			      nest = nest,
			      pat = pat,
			      region = region,
			      var = var}
			  end)
		      val boundVars =
			 Vector.concatV (Vector.map (rvbs, #bound))
		      val rvbs =
			 Vector.map
			 (rvbs, fn {bound, match, nest, pat, region, var, ...} =>
			  let
			     val {argType, region, resultType, rules} =
				elabMatch (match, nest)
			     val _ =
				unify
				(Cpat.ty pat,
				 Type.arrow (argType, resultType),
				 fn (l1, l2) =>
				 (region,
				  str "function type disagrees with recursive uses",
				  align [seq [str "function type:  ", l1],
					 seq [str "recursive uses: ", l2],
					 lay ()]))
			     val arg = Var.newNoname ()
			     val body =
				Cexp.enterLeave
				(Cexp.casee {kind = "function",
					     lay = lay,
					     noMatch = Cexp.RaiseMatch,
					     region = region,
					     rules = rules,
					     test = Cexp.var (arg, argType)},
				 SourceInfo.function {name = nest,
						      region = region})
			     val lambda =
				Lambda.make {arg = arg,
					     argType = argType,
					     body = body}
			  in
			     {bound = bound,
			      lambda = lambda,
			      var = var}
			  end)
		      val rvbs =
			 Vector.map
			 (rvbs, fn {bound, lambda, var} =>
			  (Vector.foreach (bound, unmarkFunc o #2)
			   ; {lambda = lambda,
			      var = var}))
		      val vbs =
			 Vector.map
			 (vbs,
			  fn {exp = e, expRegion, lay, pat, patRegion, ...} =>
			  let
			     val (p, bound) = elaboratePat (pat, E, false)
			     val _ =
				unify
				(Cpat.ty p, Cexp.ty e, fn (p, e) =>
				 (Apat.region pat,
				  str "pattern and expression disagree",
				  align [seq [str "pattern:    ", p],
					 seq [str "expression: ", e],
					 lay ()]))
			  in
			     {bound = bound,
			      exp = e,
			      expRegion = expRegion,
			      lay = lay,
			      pat = p,
			      patRegion = patRegion}
			  end)
		      val boundVars =
			 Vector.concat
			 [boundVars, Vector.concatV (Vector.map (vbs, #bound))]
		      val {bound, schemes} =
			 close (Vector.map (boundVars, #3))
		      val _ = checkSchemes (Vector.zip
					    (Vector.map (boundVars, #2),
					     schemes))
		      val _ = setBound bound
		      val _ =
			 Vector.foreach2
			 (boundVars, schemes, fn ((x, x', _), scheme) =>
			  Env.extendVar (E, x, x', scheme))
		      val vbs =
			 Vector.map (vbs, fn {exp, lay, pat, patRegion, ...} =>
				     {exp = exp,
				      lay = lay,
				      pat = pat,
				      patRegion = patRegion})
		   in
		      (* According to page 28 of the Definition, we should
		       * issue warnings for nonexhaustive valdecs only when it's
		       * not a top level dec.   It seems harmless enough to go
		       * ahead and always issue them.
		       *)
		      Decs.single (Cdec.Val {rvbs = rvbs,
					     tyvars = bound,
					     vbs = vbs})
		   end
	  end) arg
      and elabExp (arg: Aexp.t * Nest.t): Cexp.t =
	 Trace.traceInfo (elabExpInfo,
			  Layout.tuple2 (Aexp.layout, Nest.layout),
			  Layout.ignore,
			  Trace.assertTrue)
	 (fn (e: Aexp.t, nest) =>
	  let
	     fun lay () = seq [str "in: ", approximate (Aexp.layout e)]
	     val unify =
		fn (a, b, f) => unify (a, b, fn z =>
				       let
					  val (r, l, l') = f z
				       in
					  (r, l, align [l', lay ()])
				       end)
	     val region = Aexp.region e
	     fun constant (c: Aconst.t) =
		case Aconst.node c of
		   Aconst.Bool b => if b then Cexp.truee else Cexp.falsee
		 | _ => 
		      let
			 val ty = Aconst.ty c
			 fun resolve () = resolveConst (c, ty)
			 val _ = List.push (overloads, fn () => (resolve (); ()))
		      in
			 Cexp.make (Cexp.Const resolve, ty)
		      end
	     fun elab e = elabExp (e, nest)
	  in
	     case Aexp.node e of
		Aexp.Andalso (e, e') =>
		   let
		      val ce = elab e
		      val ce' = elab e'
		      fun doit (ce, br) =
			 unify
			 (Cexp.ty ce, Type.bool,
			  fn (l, _) =>
			  (Aexp.region e,
			   str (concat
				[br, " branch of andalso not a bool"]),
			   seq [str " branch: ", l]))
		      val _ = doit (ce, "left")
		      val _ = doit (ce', "right")
		   in
		      Cexp.andAlso (ce, ce')
		   end
	      | Aexp.App (e1, e2) =>
		   let
		      val e1 = elab e1
		      val e2 = elab e2
		      val argType = Type.new ()
		      val resultType = Type.new ()
		      val _ =
			 unify (Cexp.ty e1, Type.arrow (argType, resultType),
				fn (l, _) =>
				(region,
				 str "function not of arrow type",
				 seq [str "function: ", l]))
		      val _ =
			 unify
			 (argType, Cexp.ty e2, fn (l1, l2) =>
			  (region,
			   str "function applied to incorrect argument",
			   align [seq [str "expects: ", l1],
				  seq [str "but got: ", l2]]))
		   in
		      Cexp.make (Cexp.App (e1, e2), resultType)
		   end
	      | Aexp.Case (e, m) =>
		   let
		      val e = elab e
		      val {argType, resultType, rules, ...} =
			 elabMatch (m, nest)
		      val _ =
			 unify
			 (Cexp.ty e, argType, fn (l1, l2) =>
			  (region,
			   str "case object and rules disagree",
			   align [seq [str "object type:  ", l1],
				  seq [str "rules expect: ", l2]]))
		   in
		      Cexp.casee {kind = "case",
				  lay = lay,
				  noMatch = Cexp.RaiseMatch,
				  region = region,
				  rules = rules,
				  test = e}
		   end
	      | Aexp.Const c => constant c
	      | Aexp.Constraint (e, t') =>
		   let
		      val e = elab e
		      val _ =
			 unify
			 (Cexp.ty e, elabType t', fn (l1, l2) =>
			  (region,
			   str "expression and constraint disagree",
			   seq [str "exp type:   ", l1]))
		   in
		      e
		   end
	      | Aexp.FlatApp items => elab (Parse.parseExp (items, E, lay))
	      | Aexp.Fn m =>
		   let
		      val {arg, argType, body} =
			 elabMatchFn (m, nest, "function", lay, Cexp.RaiseMatch)
		      val body =
			 Cexp.enterLeave
			 (body, SourceInfo.function {name = nest,
						     region = region})
		   in
		      Cexp.make (Cexp.Lambda (Lambda.make {arg = arg,
							   argType = argType,
							   body = body}),
				 Type.arrow (argType, Cexp.ty body))
		   end
	      | Aexp.Handle (try, match) =>
		   let
		      val try = elab try
		      val {arg, argType, body} =
			 elabMatchFn (match, nest, "handler", lay,
				      Cexp.RaiseAgain)
		      val _ =
			 unify
			 (Cexp.ty try, Cexp.ty body, fn (l1, l2) =>
			  (region,
			   str "expression and handler of different types",
			   align [seq [str "expression: ", l1],
				  seq [str "handler: ", l2]]))
		      val _ =
			 unify
			 (argType, Type.exn, fn (l1, _) =>
			  (Amatch.region match,
			   seq [str "handler handles wrong type: ", l1],
			   empty))
		   in
		      Cexp.make (Cexp.Handle {catch = (arg, Type.exn),
					      handler = body, 
					      try = try},
				 Cexp.ty try)
		   end
	      | Aexp.If (a, b, c) =>
		   let
		      val a' = elab a
		      val b' = elab b
		      val c' = elab c
		      val _ =
			 unify
			 (Cexp.ty a', Type.bool, fn (l1, _) =>
			  (Aexp.region a,
			   str "if test not a bool",
			   seq [str "test type: ", l1]))
		      val _ =
			 unify
			 (Cexp.ty b', Cexp.ty c', fn (l1, l2) =>
			  (region,
			   str "then and else branches of different types",
			   align [seq [str "then: ", l1],
				  seq [str "else: ", l2]]))
		   in
		      Cexp.iff (a', b', c')
		   end
	      | Aexp.Let (d, e) =>
		   Env.scope
		   (E, fn () =>
		    let
		       val d = Decs.toVector (elabDec (d, nest, false))
		       val e = elab e
		    in
		       Cexp.make (Cexp.Let (d, e), Cexp.ty e)
		    end)
	      | Aexp.List es =>
		   let
		      val es' = Vector.map (es, elab)
		   in
		      Cexp.make (Cexp.List es',
				 unifyList
				 (Vector.map2 (es, es', fn (e, e') =>
					       (Cexp.ty e', Aexp.region e)),
				  lay))
		   end
	      | Aexp.Orelse (e, e') =>
		   let
		      val ce = elab e
		      val ce' = elab e'
		      fun doit (ce, br) =
			 unify
			 (Cexp.ty ce, Type.bool,
			  fn (l, _) =>
			  (Aexp.region e,
			   str (concat
				[br, " branch of orelse not a bool"]),
			   seq [str " branch: ", l]))
		      val _ = doit (ce, "left")
		      val _ = doit (ce', "right")
		   in
		      Cexp.orElse (ce, ce')
		   end
	      | Aexp.Prim {kind, name, ty} =>
		   let
		      val ty = elabType ty
		      fun primApp {args, prim, result: Type.t} =
			 let
			    val targs =
			       Prim.extractTargs
			       {args = Vector.map (args, Cexp.ty),
				deArray = Type.deArray,
				deArrow = Type.deArrow,
				deRef = Type.deRef,
				deVector = Type.deVector,
				deWeak = Type.deWeak,
				prim = prim,
				result = result}
			 in
			    Cexp.make (Cexp.PrimApp {args = args,
						     prim = prim,
						     targs = targs},
				       result)
			 end
		      fun eta (p: Prim.t): Cexp.t =
			 case Type.deArrowOpt ty of
			    NONE => primApp {args = Vector.new0 (),
					     prim = p,
					     result = ty}
			  | SOME (argType, bodyType) =>
			       let
				  val arg = Var.newNoname ()
				  fun app args =
				     primApp {args = args,
					      prim = p,
					      result = bodyType}
				  val body =
				     case Type.deTupleOpt argType of
					NONE =>
					   app (Vector.new1
						(Cexp.var (arg, argType)))
				      | SOME ts =>
					   let
					      val vars =
						 Vector.map
						 (ts, fn t =>
						  (Var.newNoname (), t))
					   in
					      Cexp.casee
					      {kind = "",
					       lay = fn _ => Layout.empty,
					       noMatch = Cexp.Impossible,
					       region = Region.bogus,
					       rules =
					       Vector.new1
					       {exp = app (Vector.map
							   (vars, Cexp.var)),
						lay = NONE,
						pat =
						(Cpat.tuple
						 (Vector.map (vars, Cpat.var)))},
					       test = Cexp.var (arg, argType)}
					   end
			       in
				  Cexp.lambda (Lambda.make {arg = arg,
							    argType = argType,
							    body = body})
			       end
		      fun lookConst (name: string) =
			 case Type.deConOpt ty of
			    NONE => Error.bug "strange constant"
			  | SOME (c, ts) =>
			       let
				  val ct =
				     if Tycon.equals (c, Tycon.bool)
					then ConstType.Bool
				     else if Tycon.isIntX c
					then ConstType.Int
				     else if Tycon.isRealX c
					then ConstType.Real
				     else if Tycon.isWordX c
					then ConstType.Word
				     else if Tycon.equals (c, Tycon.vector)
					     andalso 1 = Vector.length ts
					     andalso
					     (case (Type.deConOpt
						    (Vector.sub (ts, 0))) of
						 NONE => false
					       | SOME (c, _) => 
						    Tycon.equals
						    (c, Tycon.char))
					then ConstType.String
				     else Error.bug "strange const type"
				  fun finish () = lookupConstant (name, ct)
			       in
				  Cexp.make (Cexp.Const finish, ty)
			       end
		      datatype z = datatype Ast.PrimKind.t
		   in
		      case kind of
			 BuildConst => lookConst name
		       | Const =>  lookConst name
		       | Export attributes =>
			    Env.scope
			    (E, fn () =>
			     (Env.openStructure (E,
						 valOf (!Env.Structure.ffi))
			      ; elabExp (export {attributes = attributes,
						 name = name,
						 region = region,
						 ty = ty},
					 nest)))
		       | Import attributes =>
			    eta (import {attributes = attributes,
					 name = name,
					 region = region,
					 ty = ty})
		       | Prim => eta (Prim.new name)
		   end
	      | Aexp.Raise exn =>
		   let
		      val region = Aexp.region exn
		      val exn = elab exn
		      val _ =
			 unify
			 (Cexp.ty exn, Type.exn, fn (l1, _) =>
			  (region,
			   str "raise of non-exception",
			   seq [str "exp type: ", l1]))
		      val resultType = Type.new ()
		   in
		      Cexp.make (Cexp.Raise {exn = exn, region = region},
				 resultType)
		   end
	      | Aexp.Record r =>
		   let
		      val r = Record.map (r, elab)
		      val ty =
			 Type.record
			 (SortedRecord.fromVector
			  (Record.toVector (Record.map (r, Cexp.ty))))
		   in
		      Cexp.make (Cexp.Record r, ty)
		   end
	      | Aexp.Selector f => elab (Aexp.selector (f, region))
	      | Aexp.Seq es =>
		   let
		      val es = Vector.map (es, elab)
		   (* Could put warning here for expressions before a ; that
		    * don't return unit.
		    *)
		   in
		      Cexp.make (Cexp.Seq es, Cexp.ty (Vector.last es))
		   end
	      | Aexp.Var {name = id, ...} =>
		   let
		      val (vid, scheme) = Env.lookupLongvid (E, id)
		      val {args, instance} = Scheme.instantiate scheme
		      fun con c = Cexp.Con (c, args ())
		      val e =
			 case vid of
			    Vid.ConAsVar c => con c
			  | Vid.Con c => con c
			  | Vid.Exn c => con c
			  | Vid.Overload yts =>
			       let
				  val resolve =
				     Promise.lazy
				     (fn () =>
				      case (Vector.peek
					    (yts, fn (_, t) =>
					     Type.canUnify (instance, t))) of
					 NONE =>
					    let
					       val _ =
						  Control.error
						  (region,
						   seq [str "impossible use of overloaded var: ",
							str (Longvid.toString id)],
						   Type.layoutPretty instance)
					    in
					       Var.newNoname ()
					    end
				       | SOME (y, t) =>  
					    (unify (instance, t, fn _ =>
						    Error.bug "overload unify")
					     ; y))
				  val _ = 
				     List.push (overloads, fn () =>
						(resolve (); ()))
			       in
				  Cexp.Var (resolve, fn () => Vector.new0 ())
			       end
			  | Vid.Var x =>
			       Cexp.Var (fn () => x,
					 case ! (recursiveTargs x) of
					    NONE => args
					  | SOME f => f)
		   in
		      Cexp.make (e, instance)
		   end
	      | Aexp.While {expr, test} =>
		   let
		      val test' = elab test
		      val _ =
			 unify
			 (Cexp.ty test', Type.bool, fn (l1, _) =>
			  (Aexp.region test,
			   str "while-test not a bool",
			   seq [str "test: ", l1]))
		      (* Could put warning here if the expr is not of type unit.
		       *)
		      val expr = elab expr
		   in
		      Cexp.whilee {expr = expr, test = test'}
		   end
	  end) arg
      and elabMatchFn (m: Amatch.t, nest, kind, lay, noMatch) =
	 let
	    val arg = Var.newNoname ()
	    val {argType, region, resultType, rules} = elabMatch (m, nest)
	    val body =
	       Cexp.casee {kind = kind,
			   lay = lay,
			   noMatch = noMatch,
			   region = region,
			   rules = rules,
			   test = Cexp.var (arg, argType)}
	 in
	   {arg = arg,
	    argType = argType,
	    body = body}
	 end
      and elabMatch (m: Amatch.t, nest: Nest.t) =
	 let
	    val region = Amatch.region m
	    val Amatch.T rules = Amatch.node m
	    val argType = Type.new ()
	    val resultType = Type.new ()
	    val rules =
	       Vector.map
	       (rules, fn (pat, exp) =>
		Env.scope
		(E, fn () =>
		 let
		    fun lay () =
		       let
			  open Layout
		       in
			  approximate
			  (seq [Apat.layout pat, str " => ", Aexp.layout exp])
		       end
		    val (p, xts) = elaboratePat (pat, E, false)
		    val _ =
		       unify
		       (Cpat.ty p, argType, fn (l1, l2) =>
			(Apat.region pat,
			 str "rule patterns of different types",
			 align [seq [str "pattern:  ", l1],
				seq [str "previous: ", l2],
				seq [str "in: ", lay ()]]))
		    val e = elabExp (exp, nest)
		    val _ =
		       unify
		       (Cexp.ty e, resultType, fn (l1, l2) =>
			(Aexp.region exp,
			 str "rule results of different types",
			 align [seq [str "result:   ", l1],
				seq [str "previous: ", l2],
				seq [str "in: ", lay ()]]))
		 in
		    {exp = e,
		     lay = SOME lay,
		     pat = p}
		 end))
	 in
	    {argType = argType,
	     region = region,
	     resultType = resultType,
	     rules = rules}
	 end
      val ds = elabDec (Scope.scope d, nest, true)
      val _ = List.foreach (rev (!overloads), fn p => (p (); ()))
      val _ = overloads := []
      val _ = List.foreach (rev (!freeTyvarChecks), fn p => p ())
      val _ = freeTyvarChecks := []
      val _ = TypeEnv.closeTop (Adec.region d)
   in
      ds
   end

end
