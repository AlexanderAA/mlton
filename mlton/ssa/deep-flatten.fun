(* Copyright (C) 2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

functor DeepFlatten (S: DEEP_FLATTEN_STRUCTS): DEEP_FLATTEN = 
struct

open S

type int = Int.t

datatype z = datatype Exp.t
datatype z = datatype Transfer.t

structure Set = DisjointSet

structure Flat =
   struct
      datatype t = Flat | NotFlat

      val toString: t -> string =
	 fn Flat => "Flat"
	  | NotFlat => "NotFlat"

      val layout = Layout.str o toString
   end

datatype z = datatype Flat.t

structure TypeTree =
   struct
      datatype info =
	 Flat
       | NotFlat of {ty: Type.t}
	 
      type t = info Tree.t

      val layout: t -> Layout.t =
	 Tree.layout
	 (let
	     open Layout
	  in
	     fn Flat => str "Flat"
	      | NotFlat {ty} => seq [str "NotFlat ",
				     record [("ty", Type.layout ty)]]
	  end)

      val isFlat: t -> bool =
	 fn Tree.T (i, _) =>
	 case i of
	    Flat => true
	  | NotFlat _ => false
   end

structure VarTree =
   struct
      datatype info =
	 Flat
       | NotFlat of {ty: Type.t,
		     var: Var.t option}

      type t = info Tree.t

      val layout: t -> Layout.t =
	 Tree.layout
	 (let
	     open Layout
	  in
	     fn Flat => str "Flat"
	      | NotFlat {ty, var} =>
		   seq [str "NotFlat ",
			record [("ty", Type.layout ty),
				("var", Option.layout Var.layout var)]]
	  end)

      val labelRoot: t * Var.t -> t =
	 fn (t as Tree.T (info, ts), x) =>
	 case info of
	    Flat => t
	  | NotFlat {ty, ...} => Tree.T (NotFlat {ty = ty, var = SOME x}, ts)

      val fromTypeTree: TypeTree.t -> t =
	 fn t =>
	 Tree.map (t, fn i =>
		   case i of
		      TypeTree.Flat => Flat
		    | TypeTree.NotFlat {ty} => NotFlat {ty = ty, var = NONE})

      val foldRoots: t * 'a * (Var.t * 'a -> 'a) -> 'a =
	 fn (t, a, f) =>
	 let
	    fun loop (Tree.T (info, children), a: 'a): 'a =
	       case info of
		  Flat => Vector.fold (children, a, loop)
		| NotFlat {var, ...} =>
		     case var of
			NONE => Error.bug "foldRoots"
		      | SOME x => f (x, a)
	 in
	    loop (t, a)
	 end

      fun foreachRoot (t, f) = foldRoots (t, (), f o #1)

      val rootsOnto: t * Var.t list -> Var.t list =
	 fn (t, ac) =>
	 List.appendRev (foldRoots (t, [], op ::), ac)
	 
      fun fillInRoots (t: t, {object: Var.t, offset: int})
	 : t * Statement.t list =
	 let
	    fun loop (t as Tree.T (info, ts), offset, ac) =
	       case info of
		  Flat =>
		     let
			val (ts, offset, ac) =
			   Vector.fold
			   (ts, ([], offset, ac), fn (t, (ts, offset, ac)) =>
			    let
			       val (t, offset, ac) = loop (t, offset, ac)
			    in
			       (t :: ts, offset, ac)
			    end)
		     in
			(Tree.T (Flat, Vector.fromListRev ts), offset, ac)
		     end
		| NotFlat {ty, var} =>
		     let
			val (t, ac) =
			   case var of
			      NONE =>
				 let
				    val var = Var.newNoname ()
				 in
				    (Tree.T (NotFlat {ty = ty, var = SOME var},
					     ts),
				     Statement.T
				     {exp = Select {object = object,
						    offset = offset},
				      ty = ty,
				      var = SOME var} :: ac)
				 end
			    | SOME _ => (t, ac)
		     in
			(t, offset + 1, ac)
		     end
	    val (t, _, ac) = loop (t, offset, [])
	 in
	    (t, ac)
	 end
   end

fun flatten {from: VarTree.t,
	     object: Var.t option,
	     offset: int,
	     to: TypeTree.t}: {offset: int} * VarTree.t * Statement.t list =
   let
      val Tree.T (from, fs) = from
   in
      case from of
	 VarTree.Flat =>
	    if TypeTree.isFlat to
	       then flattensAt {froms = fs,
				object = object,
				offset = offset,
				tos = Tree.children to}
	    else Error.bug "cannot flatten from Flat to NotFlat"
       | VarTree.NotFlat {ty, var} =>
	    let
	       val (var, ss) =
		  case var of
		     NONE =>
			let
			   val object =
			      case object of
				 NONE => Error.bug "flatten missing object"
			       | SOME object => object
			   val result = Var.newNoname ()
			in
			   (result,
			    [Statement.T {exp = Select {object = object,
							offset = offset},
					  ty = ty,
					  var = SOME result}])
			end
		   | SOME var => (var, [])
	       val (r, ss) =
		  if TypeTree.isFlat to
		     then
			let
			   val (_, r, ss') =
			      flattensAt {froms = fs,
					  object = SOME var,
					  offset = 0,
					  tos = Tree.children to}
			in
			   (r, ss @ ss')
			end
		  else (Tree.T (VarTree.NotFlat {ty = ty, var = SOME var},
				fs),
			ss)
	    in
	       ({offset = 1 + offset}, r, ss)
	    end
   end
and flattensAt {froms: VarTree.t vector,
		object: Var.t option,
		offset: int,
		tos: TypeTree.t vector} =
   let
      val (off, ts, ss) =
	 Vector.fold2
	 (froms, tos, ({offset = offset}, [], []),
	  fn (f, t, ({offset}, ts, ss)) =>
	  let
	     val ({offset}, t, ss') =
		flatten {from = f,
			 object = object,
			 offset = offset,
			 to = t}
	  in
	     ({offset = offset}, t :: ts, ss' @ ss)
	  end)
   in
      (off, Tree.T (VarTree.Flat, Vector.fromListRev ts), ss)
   end

fun coerceTree {from: VarTree.t, to: TypeTree.t}: VarTree.t * Statement.t list =
   let
      val (_, r, ss) =
	 flatten {from = from,
		  object = NONE,
		  offset = 0,
		  to = to}
   in
      (r, ss)
   end

val coerceTree =
   let
      open Layout
   in
      Trace.trace ("DeepFlatten.coerceTree",
		   fn {from, to} =>
		   record [("from", VarTree.layout from),
			   ("to", TypeTree.layout to)],
		   fn (vt, ss) =>
		   tuple [VarTree.layout vt,
			  List.layout Statement.layout ss])
      coerceTree
   end

structure Value =
   struct
      datatype t = T of {finalOffsets: int vector option ref,
			 finalTree: TypeTree.t option ref,
			 finalType: Type.t option ref,
			 finalTypes: Type.t Prod.t option ref,
			 value: value} Set.t
      and value =
	 Ground of Type.t
       | Object of {args: t Prod.t,
		    coercedFrom: t list ref,
		    con: Con.t option,
		    flat: Flat.t ref}
       | Vector of {elt: t Prod.t}
       | Weak of {arg: t}

      fun new' v = {finalOffsets = ref NONE,
		    finalTree = ref NONE,
		    finalType = ref NONE,
		    finalTypes = ref NONE,
		    value = v}

      fun new v = T (Set.singleton (new' v))

      fun value (T s) = #value (Set.! s)

      fun layout v: Layout.t =
	 let
	    open Layout
	 in
	    case value v of
	       Ground t => Type.layout t
	     | Object {args, con, flat, ...} => 
		  seq [str "Object ",
		       record [("args", Prod.layout (args, layout)),
			       ("con", Option.layout Con.layout con),
			       ("flat", Flat.layout (! flat))]]
	     | Vector {elt, ...} =>
		  seq [str "Vector ", Prod.layout (elt, layout)]
	     | Weak {arg, ...} => seq [str "Weak ", layout arg]
	 end

      val ground = new o Ground

      fun weak (a: t): t = new (Weak {arg = a})

      fun vector (p: t Prod.t): t = new (Vector {elt = p})

      val unit = ground Type.unit

      fun isUnit v =
	 case value v of
	    Ground t => Type.isUnit t
	  | _ => false
	       
      fun object {args, con} =
	 new (Object {args = args,
		      coercedFrom = ref [],
		      con = con,
		      flat = ref Flat.Flat})
	    
      val tuple: t Prod.t -> t =
	 fn vs => object {args = vs, con = NONE}

      val tuple =
	 Trace.trace ("Value.tuple", fn p => Prod.layout (p, layout), layout)
	 tuple

      val deObject =
	 fn v =>
	 case value v of
	    Object z => z
	  | _ => Error.bug "Value.deObject"

      fun select {object: t, offset: int}: t =
	 case value object of
	    Object {args, ...} => Prod.elt (args, offset)
	  | _ => Error.bug "Value.select"

      val deVector: t -> t Prod.t =
	 fn v =>
	 case value v of
	    Vector {elt, ...} => elt
	  | _ => Error.bug "Value.deVector"
	       
      val deWeak: t -> t =
	 fn v =>
	 case value v of
	    Weak {arg, ...} => arg
	  | _ => Error.bug "Value.deWeak"

      val rec unify: t * t -> unit =
	 fn (T s, T s') =>
	 if Set.equals (s, s')
	    then ()
	 else
	    let
	       val {value = v, ...} = Set.! s
	       val {value = v', ...} = Set.! s'
	       val () = Set.union (s, s')
	    in
	       case (v, v') of
		  (Ground _, Ground _) => ()
		| (Object (obj as {args = a, coercedFrom = c, flat = f, ...}),
		   Object (obj' as {args = a', coercedFrom = c', flat = f',
				    ...})) =>
		     let
			val () = unifyProd (a, a')
			fun set v = Set.:= (s, new' v)
		     in
			case (!f, !f') of
			   (Flat, Flat) =>
			      (set v; c := List.fold (!c', !c, op ::))
			 | (Flat, NotFlat) =>
			      (set v; dontFlatten (T s))
			 | (NotFlat, Flat) =>
			      (set v'; dontFlatten (T s))
			 | (NotFlat, NotFlat) => ()
		     end
		| (Vector {elt = p, ...}, Vector {elt = p', ...}) =>
		     unifyProd (p, p')
		| (Weak {arg = a, ...}, Weak {arg = a', ...}) => unify (a, a')
		| _ => Error.bug "strange unify"
	    end
      and unifyProd =
	 fn (p, p') =>
	 Vector.foreach2
	 (Prod.dest p, Prod.dest p',
	  fn ({elt = e, ...}, {elt = e', ...}) => unify (e, e'))
      and coerce =
	 fn {from as T s, to = T s'} =>
	 if Set.equals (s, s')
	    then ()
	 else
	    let
	       val {value = v, ...} = Set.! s
	       val {value = v', ...} = Set.! s'
	    in
	       case (v, v') of
		  (Ground _, Ground _) => ()
		| (Object {args = a, ...},
		   Object {args = a', coercedFrom = c', flat = f', ...}) =>
		     let
			val () =
			   case !f' of
			      Flat => List.push (c', from)
			    | NotFlat => dontFlatten from
		     in
			coerceProd {from = a, to = a'}
		     end
		| (Vector {elt = p, ...}, Vector {elt = p', ...}) =>
		     coerceProd {from = p, to = p'}
		| (Weak {arg = a, ...}, Weak {arg = a', ...}) => unify (a, a')
		| _ => Error.bug "strange unify"
	    end
      and coerceProd =
	 fn {from = p, to = p'} =>
	 Vector.foreach2
	 (Prod.dest p, Prod.dest p', fn ({elt = e, ...}, {elt = e', ...}) =>
	  coerce {from = e, to = e'})
      and dontFlatten: t -> unit =
	 fn v =>
	 case value v of
	    Object (z as {coercedFrom, flat, ...}) =>
	       (case ! flat of
		   Flat =>
		      let
			 val () = flat := NotFlat
			 val from = !coercedFrom
			 val () = coercedFrom := []
		      in
			 List.foreach (!coercedFrom, fn v' => unify (v, v'))
		      end
		 | NotFlat => ())
	  | _ => ()

      val coerce =
	 Trace.trace ("Value.coerce",
		      fn {from, to} =>
		      Layout.record [("from", layout from),
				     ("to", layout to)],
		      Unit.layout)
	 coerce

      val traceFinalType = Trace.trace ("Value.finalType", layout, Type.layout)

      fun finalTree (v as T s): TypeTree.t =
	 let
	    val {finalTree = r, value, ...} = Set.! s
	 in
	    Ref.memoize
	    (r, fn () =>
	     let
		fun notFlat () = TypeTree.NotFlat {ty = finalType v}
	     in
		case value of
		   Object {args, flat, ...} =>
		      let
			 val info =
			    case !flat of
			       Flat => TypeTree.Flat
			     | NotFlat => notFlat ()
		      in
			 Tree.T (info,
				 Vector.map (Prod.dest args, finalTree o # elt))
		      end
		 | _ => Tree.T (notFlat (), Vector.new0 ())
	     end)
	 end
      and finalType arg: Type.t =
	 traceFinalType
	 (fn v as T s =>
	  let
	     val {finalType = r, value, ...} = Set.! s
	  in
	     Ref.memoize
	     (r, fn () =>
	      case value of
		 Ground t => t
	       | Object {con, flat, ...} =>
		    (case !flat of
			Flat => Error.bug "finalType Flat"
		      | NotFlat => 
			   Type.object {args = finalTypes v, con = con})
	       | Vector {elt, ...} => Type.vector (prodFinalTypes elt)
	       | Weak {arg, ...} => Type.weak (finalType arg))
	  end) arg
      and finalTypes (v as T s): Type.t Prod.t =
	 let
	     val {finalTypes, value, ...} = Set.! s
	  in
	     Ref.memoize
	     (finalTypes, fn () =>
	      case value of
		 Object {args, ...} => prodFinalTypes args
	       | _ => Prod.make (Vector.new1 {elt = finalType v,
					      isMutable = false}))
	 end
      and prodFinalTypes (p: t Prod.t): Type.t Prod.t =
	 Prod.make
	 (Vector.fromList
	  (Vector.foldr
	   (Prod.dest p, [], fn ({elt, isMutable = i}, ac) =>
	    Vector.fold
	    (Prod.dest (finalTypes elt), ac, fn ({elt, isMutable = i'}, ac) =>
	     {elt = elt, isMutable = i orelse i'} :: ac))))

      fun finalOffsets (v as T s): int vector =
	 let
	    val {finalOffsets = r, value, ...} = Set.! s
	 in
	    Ref.memoize
	    (r, fn () =>
	     case value of
		Object {args, ...} =>
		   Vector.fromListRev
		   (#2 (Vector.fold (Prod.dest args, (0, []),
				     fn ({elt, ...}, (offset, offsets)) =>
				     (offset + Prod.length (finalTypes elt),
				      offset :: offsets))))
	      | _ => Error.bug "finalOffsets of non object")
	 end

      fun finalOffset (object, offset) =
	 Vector.sub (finalOffsets object, offset)
   end

fun flatten (program as Program.T {datatypes, functions, globals, main}) =
   let
      val {get = conValue: Con.t -> Value.t option ref, ...} =
	 Property.get (Con.plist, Property.initFun (fn _ => ref NONE))
      val conValue =
	 Trace.trace ("conValue",
		      Con.layout, Ref.layout (Option.layout Value.layout))
	 conValue
      val {get = typeValue: Type.t -> Value.t, ...} =
	 Property.get
	 (Type.plist,
	  Property.initRec
	  (fn (t, typeValue) =>
	   let
	      datatype z = datatype Type.dest
	   in
	      case Type.dest t of
		 Object {args, con} =>
		    let
		       fun doit () =
			  Value.object {args = Prod.map (args, typeValue),
					con = con}
		    in
		       case con of
			  NONE => doit ()
			| SOME c =>
			     Ref.memoize
			     (conValue c, fn () =>
			      let
				 val v = doit ()
				 val () = Value.dontFlatten v
			      in
				 v
			      end)
		    end
	       | Vector p => Value.vector (Prod.map (p, typeValue))
	       | Weak t => Value.weak (typeValue t)
	       | _ => Value.ground t
	   end))
      val typeValue =
	 Trace.trace ("typeValue", Type.layout, Value.layout) typeValue
      val coerce = Value.coerce
      fun inject {sum, variant} = typeValue (Type.datatypee sum)
      fun object {args, con, resultType} =
	 case con of
	    NONE => Value.tuple args
	  | SOME c =>
	       let
		  val res = typeValue resultType
		  val () =
		     Value.coerceProd {from = args,
				       to = #args (Value.deObject res)}
	       in
		  res
	       end
      val object =
	 Trace.trace
	 ("object",
	  fn {args, con, ...} =>
	  Layout.record [("args", Prod.layout (args, Value.layout)),
			 ("con", Option.layout Con.layout con)],
	  Value.layout)
	 object
      fun primApp {args, prim, resultVar, resultType, targs} =
	 let
	    fun arg i = Vector.sub (args, i)
	    fun result () = typeValue resultType
	    datatype z = datatype Prim.Name.t
	    fun dontFlatten () =
	       (Vector.foreach (args, Value.dontFlatten)
		; result ())
	    fun equal () =
	       (Value.unify (arg 0, arg 1)
		; result ())
	 in
	    case Prim.name prim of
	       Array_toVector =>
		  let
		     val res = result ()
		     datatype z = datatype Value.value
		     val () =
			case (Value.value (arg 0), Value.value res) of
			   (Ground _, Ground _) => ()
			 | (Vector {elt = p, ...}, Vector {elt = p', ...}) =>
			      Vector.foreach2
			      (Prod.dest p, Prod.dest p',
			       fn ({elt = v, ...}, {elt = v', ...}) =>
			       Value.unify (v, v'))
			 | _ => Error.bug "Array_toVector"
		  in
		     res
		  end
	     | FFI _ =>
		  (* Some imports, like Real64.modf, take ref cells that can not
		   * be flattened.
		   *)
		  dontFlatten ()
	     | MLton_eq => equal ()
	     | MLton_equal => equal ()
	     | MLton_size => dontFlatten ()
	     | Weak_get => Value.deWeak (arg 0)
	     | Weak_new => Value.weak (arg 0)
	     | _ => result ()
	 end
      fun update {object, offset, value} =
	 coerce {from = value,
		 to = Value.select {object = object, offset = offset}}
      fun vectorSub {index = _, offset, vector: Value.t}: Value.t =
	 Prod.elt (Value.deVector vector, offset)
      fun vectorUpdate {index, offset, value: Value.t, vector: Value.t} =
	 coerce {from = value,
		 to = vectorSub {index = index,
				 offset = offset,
				 vector = vector}}
      fun const c = typeValue (Type.ofConst c)
      val {func, label, value = varValue, ...} =
	 analyze {coerce = coerce,
		  const = const,
		  filter = fn _ => (),
		  filterWord = fn _ => (),
		  fromType = typeValue,
		  inject = inject,
		  layout = Value.layout,
		  object = object,
		  primApp = primApp,
		  program = program,
		  select = fn {object, offset, ...} => (Value.select
							{object = object,
							 offset = offset}),
		  update = update,
		  useFromTypeOnBinds = false,
		  vectorSub = vectorSub,
		  vectorUpdate = vectorUpdate}
      (* Don't flatten outermost part of formal parameters. *)
      fun dontFlattenFormals (xts: (Var.t * Type.t) vector): unit =
	 Vector.foreach (xts, fn (x, _) => Value.dontFlatten (varValue x))
      val () =
	 List.foreach
	 (functions, fn f =>
	  let
	     val {args, blocks, ...} = Function.dest f
	     val () = dontFlattenFormals args
	     val () = Vector.foreach (blocks, fn Block.T {args, ...} =>
				      dontFlattenFormals args)
	  in
	     ()
	  end)
      val () =
	 Control.diagnostics
	 (fn display =>
	  let
	     open Layout
	     val () =
		Vector.foreach
		(datatypes, fn Datatype.T {cons, ...} =>
		 Vector.foreach
		 (cons, fn {con, ...} =>
		  display (Option.layout Value.layout (! (conValue con)))))
	     val () =
		Program.foreachVar
		(program, fn (x, _) =>
		 display
		 (seq [Var.layout x, str " ", Value.layout (varValue x)]))
	  in
	     ()
	  end)
      (* Transform the program. *)
      val datatypes =
	 Vector.map
	 (datatypes, fn Datatype.T {cons, tycon} =>
	  let
	     val cons =
		Vector.map
		(cons, fn {con, args} =>
		 let
		    val args =
		       case ! (conValue con) of
			  NONE => args
			| SOME v => 
			     case Type.dest (Value.finalType v) of
				Type.Object {args, ...} => args
			      | _ => Error.bug "strange con"
		 in
		    {args = args, con = con}
		 end)
	  in
	     Datatype.T {cons = cons, tycon = tycon}
	  end)
      fun valuesTypes vs = Vector.map (vs, Value.finalType)
      val {get = varTree: Var.t -> VarTree.t, set = setVarTree, ...} =
	 Property.getSetOnce (Var.plist,
			      Property.initRaise ("tree", Var.layout))
      fun simpleVarTree (x: Var.t): unit =
	 setVarTree
	 (x, VarTree.labelRoot (VarTree.fromTypeTree
				(Value.finalTree (varValue x)),
				x))
      fun transformFormals xts =
	 Vector.map (xts, fn (x, _) =>
		     let
			val () = simpleVarTree x
		     in
			(x, Value.finalType (varValue x))
		     end)
      fun replaceVar (x: Var.t): Var.t =
	 let
	    fun bug () = Error.bug (concat ["replaceVar ", Var.toString x])
	    val Tree.T (info, _) = varTree x
	 in
	    case info of
	       VarTree.Flat => bug ()
	     | VarTree.NotFlat {var, ...} =>
		  case var of
		     NONE => bug ()
		   | SOME y => y
	 end
      fun transformStatement (Statement.T {exp, ty, var}): Statement.t list =
	 let
	    fun doit e = [Statement.T {exp = e, ty = ty, var = var}]
	    fun simple () =
	       (Option.app (var, simpleVarTree)
		; doit (Exp.replaceVar (exp, replaceVar)))
	    fun none () = []
	 in
	    case exp of
	       Const _ => simple ()
	     | Inject _ => simple ()
	     | Object {args, con} =>
		  (case var of
		      NONE => none ()
		    | SOME var =>
			 let
			    val v = varValue var
			 in
			    case Value.value v of
			       Value.Object {args = expects, flat, ...} =>
				  let
				     val z =
					Vector.map2
					(args, Prod.dest expects,
					 fn (arg, {elt, ...}) =>
					 coerceTree {from = varTree arg,
						     to = Value.finalTree elt})
				     val vts = Vector.map (z, #1)
				     fun set info =
					setVarTree (var, Tree.T (info, vts))
				  in
				     case !flat of
					Flat => (set VarTree.Flat; none ())
				      | NotFlat =>
					   let
					      val () =
						 set (VarTree.NotFlat
						      {ty = Value.finalType v,
						       var = SOME var})
					      val args =
						 Vector.fromList
						 (Vector.foldr
						  (vts, [], fn (vt, ac) =>
						   VarTree.rootsOnto (vt, ac)))
					   in
					      Vector.foldr
					      (z, doit (Object {args = args, con = con}),
					       fn ((_, ss), ac) => ss @ ac)
					   end
				  end
			  | _ => Error.bug "transformStatement Object"
			 end)
	     | PrimApp {args, prim, targs} => simple ()
	     | Profile _ => simple ()
	     | Select {object, offset} =>
		  (case var of
		      NONE => none ()
		    | SOME var =>
			 let
			    val Tree.T (info, children) = varTree object
			    val child = Vector.sub (children, offset)
			    val (child, ss) =
			       case info of
				  VarTree.Flat => (child, [])
				| VarTree.NotFlat {var, ...} =>
				     (case var of
					 NONE => Error.bug "select missing var"
				       | SOME var => 
					    VarTree.fillInRoots
					    (child,
					     {object = object,
					      offset = (Value.finalOffset
							(varValue object,
							 offset))}))
			    val () = setVarTree (var, child)
			 in
			    ss
			 end)
	     | Update {object, offset, value} =>
		  let
		     val objectValue = varValue object
		     val child =
			Value.finalTree
			(Value.select {object = objectValue,
				       offset = offset})
		     val offset = Value.finalOffset (objectValue, offset)
		  in
		     if not (TypeTree.isFlat child)
			then
			   [Statement.T
			    {exp = Update {object = object,
					   offset = offset,
					   value = replaceVar value},
			     ty = Type.unit,
			     var = NONE}]
		     else
			let
			   val (vt, ss) =
			      coerceTree {from = varTree value,
					  to = child}
			   val r = ref 0
			   val ss' = ref []
			   val () =
			      VarTree.foreachRoot
			      (vt, fn var =>
			       let
				  val offset = !r
				  val () = r := 1 + !r
			       in
				  List.push (ss',
					     Statement.T
					     {exp = Update {object = object,
							    offset = offset,
							    value = var},
					      ty = Type.unit,
					      var = NONE})
			       end)
			in
			   ss @ (!ss')
			end
		  end
	     | Var x =>
		  (Option.app (var, fn y => setVarTree (y, varTree x))
		   ; none ())
	     | VectorSub {index, offset, vector} =>
		  (* FIXME: this should be changed once vectors can be
		   * flattened.
		   *)
		  simple ()
	     | VectorUpdates (vector, us) =>
		  (* FIXME: this should be changed once vectors can be
		   * flattened.
		   *)
		  simple ()
	 end
      val transformStatement =
	 Trace.trace ("DeepFlatten.transformStatement",
		      Statement.layout,
		      List.layout Statement.layout)
	 transformStatement
      fun transformStatements ss =
	 Vector.fromList
	 (Vector.fold (ss, [], fn (s, ac) => transformStatement s @ ac))
      fun transformTransfer t = Transfer.replaceVar (t, replaceVar)
      val transformTransfer =
	 Trace.trace ("DeepFlatten.transformTransfer",
		      Transfer.layout, Transfer.layout)
	 transformTransfer
      fun transformBlock (Block.T {args, label, statements, transfer}) =
	 Block.T {args = transformFormals args,
		  label = label,
		  statements = transformStatements statements,
		  transfer = transformTransfer transfer}
      fun transformFunction (f: Function.t): Function.t =
	  let
	     val {args, blocks, mayInline, name, start, ...} = Function.dest f
	     val {raises, returns, ...} = func name
	     val args = transformFormals args
	     val raises = Option.map (raises, valuesTypes)
	     val returns = Option.map (returns, valuesTypes)
	     val blocks = ref []
	     val () =
		Function.dfs (f, fn b =>
			      (List.push (blocks, transformBlock b)
			       ; fn () => ()))
	  in
	     Function.new {args = args,
			   blocks = Vector.fromList (!blocks),
			   mayInline = mayInline,
			   name = name,
			   raises = raises,
			   returns = returns,
			   start = start}
	  end
      val globals = transformStatements globals
      val functions = List.revMap (functions, transformFunction)
      val program =
	 Program.T {datatypes = datatypes,
		    functions = functions,
		    globals = globals,
		    main = main}
      val () = Program.clear program
   in
      program
   end

end

