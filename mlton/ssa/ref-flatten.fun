(* Copyright (C) 2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

functor RefFlatten (S: REF_FLATTEN_STRUCTS): REF_FLATTEN = 
struct

open S

type int = Int.t

datatype z = datatype Exp.t
datatype z = datatype Transfer.t

structure Set = DisjointSet

structure Finish =
   struct
      datatype t = T of {flat: Type.t Prod.t option, 
			 ty: Type.t}

      fun notFlat ty = T {flat = NONE, ty = ty}

      val layout: t -> Layout.t =
	 fn T {flat, ty} =>
	 let
	    open Layout
	 in
	    record [("flat",
		     Option.layout (fn p => Prod.layout (p, Type.layout)) flat),
		    ("ty", Type.layout ty)]
	 end
   end

structure Value =
   struct
      datatype t =
	 Ground of Type.t
       | Object of object
       | Vector of {elt: t Prod.t,
		    finalType: Type.t option ref}
       | Weak of {arg: t,
		  finalType: Type.t option ref}
      and flat =
	 NotFlat
	| Offset of {object: object,
		     offset: int}
	| Unknown
      and object =
	 Obj of {args: t Prod.t,
		 con: Con.t option,
		 finalComponents: Type.t Prod.t option ref,
		 finalOffsets: int vector option ref,
		 finalType: Type.t option ref,
		 flat: flat Set.t}

      local
	 open Layout
      in
	 fun layout v: Layout.t =
	    case v of
	       Ground t => Type.layout t
	     | Object ob => layoutObject ob
	     | Vector {elt, ...} =>
		  seq [str "Vector ", Prod.layout (elt, layout)]
	     | Weak {arg, ...} => seq [str "Weak ", layout arg]
	 and layoutFlat (f: flat): Layout.t =
	    case f of
	       NotFlat => str "NotFlat"
	     | Offset {offset, ...} =>
		  seq [str "Offset ",
		       record [("offset", Int.layout offset)]]
	     | Unknown => str "Unknown"
	 and layoutObject (Obj {args, con, flat, ...}) =
	    seq [str "Object ",
		 record [("args", Prod.layout (args, layout)),
			 ("con", Option.layout Con.layout con),
			 ("flat", layoutFlat (Set.value flat))]]
      end
   end

structure Flat =
   struct
      datatype t = datatype Value.flat

      val layout = Value.layoutFlat
   end

structure Object =
   struct
      datatype t = datatype Value.object

      val layout = Value.layoutObject

      fun equals (Obj {flat = f, ...}, Obj {flat = f', ...}) = Set.equals (f, f')

      val select: t * int -> Value.t =
	 fn (Obj {args, ...}, offset) =>
	 Prod.elt (args, offset)
   end

datatype z = datatype Object.t

structure Value =
   struct
      open Value

      fun weak a = Weak {arg = a, finalType = ref NONE}

      fun vector p = Vector {elt = p, finalType = ref NONE}

      val deObject: t -> Object.t option =
	 fn Object ob => SOME ob
	  | _ => NONE

      fun deFlat {inner: t, outer: Object.t}: Object.t option =
	 case inner of
	    Object (z as Obj {flat, ...}) =>
	       (case Set.value flat of
		   Flat.Offset {object, ...} =>
		      if Object.equals (object, outer) then SOME z else NONE
		 | _ => NONE)
	  | _ => NONE
	       
      fun dontFlatten (v: t): unit =
	 case v of
	    Object (Obj {flat, ...}) => Set.setValue (flat, NotFlat)
	  | _ => ()

      val unit = Ground Type.unit

      fun isUnit v =
	 case v of
	    Ground t => Type.isUnit t
	  | _ => false
	       
      fun object {args, con} =
	 let
	    (* Only may flatten objects with mutable fields. *)
	    val flat =
	       Set.singleton
	       (if Vector.exists (Prod.dest args, fn {elt, isMutable} =>
				  isMutable andalso not (isUnit elt))
		   then Unknown
		else NotFlat)
	 in
	    Object (Obj {args = args,
			 con = con,
			 finalComponents = ref NONE,
			 finalOffsets = ref NONE,
			 finalType = ref NONE,
			 flat = flat})
	 end
	    
      val tuple: t Prod.t -> t =
	 fn vs => object {args = vs, con = NONE}

      val tuple =
	 Trace.trace ("Value.tuple", fn p => Prod.layout (p, layout), layout)
	 tuple

      val rec unify: t * t -> unit =
	 fn (v, v') =>
	 case (v, v') of
	    (Ground t, Ground t') => ()
	  | (Object (Obj {args = a, flat = f, ...}),
	     Object (Obj {args = a', flat = f', ...})) =>
	       (Set.union (f, f')
		; unifyProd (a, a'))
	  | (Vector {elt = p, ...}, Vector {elt = p', ...}) => unifyProd (p, p')
	  | (Weak {arg = a, ...}, Weak {arg = a', ...}) => unify (a, a')
	  | _ => Error.bug "strange unify"
      and unifyProd =
	 fn (p, p') =>
	 Vector.foreach2
	 (Prod.dest p, Prod.dest p',
	  fn ({elt = e, ...}, {elt = e', ...}) => unify (e, e'))

      fun coerce {from, to} = unify (from, to)

      val coerce =
	 Trace.trace ("Value.coerce",
		      fn {from, to} =>
		      Layout.record [("from", layout from),
				     ("to", layout to)],
		      Unit.layout)
	 coerce
   end

fun memoize (r: 'a option ref, f: unit -> 'a): 'a =
   case !r of
      NONE =>
	 let
	    val a = f ()
	    val () = r := SOME a
	 in
	    a
	 end
    | SOME a => a

fun flatten (program as Program.T {datatypes, functions, globals, main}) =
   let
      val {get = conValue: Con.t -> Value.t option ref, ...} =
	 Property.get (Con.plist, Property.initFun (fn _ => ref NONE))
      val conValue =
	 Trace.trace ("conValue",
		      Con.layout, Ref.layout (Option.layout Value.layout))
	 conValue
      datatype 'a make =
	 Const of 'a
       | Make of unit -> 'a
      fun needToMakeProd p =
	 Vector.exists (Prod.dest p, fn {elt, ...} =>
			case elt of
			   Const _ => false
			 | Make _ => true)
      fun makeProd p =
	 Prod.map (p, fn m =>
		   case m of
		      Const v => v
		    | Make f => f ())
      val {get = makeTypeValue: Type.t -> Value.t make, ...} =
	 Property.get
	 (Type.plist,
	  Property.initRec
	  (fn (t, makeTypeValue) =>
	   let
	      fun const () = Const (Value.Ground t)
	      datatype z = datatype Type.dest
	   in
	      case Type.dest t of
		 Object {args, con} =>
		    let
		       fun doit () =
			  let
			     val args = Prod.map (args, makeTypeValue)
			     val mayFlatten =
				Vector.exists (Prod.dest args, #isMutable)
			  in
			     if mayFlatten orelse needToMakeProd args
				then Make (fn () =>
					   Value.object {args = makeProd args,
							 con = con})
			     else const ()
			  end
		    in
		       case con of
			  NONE => doit ()
			| SOME c =>
			     let
				val r = conValue c
			     in
				Const
				(memoize
				 (r, fn () =>
				  case doit () of
				     Const v => v
				   | Make f =>
					let
					   val v = f ()
					   (* Constructors can never be
					    * flattened into other objects.
					    *)
					   val () = Value.dontFlatten v
					in
					   v
					end))
			     end
		    end
	       | Vector p =>
		    let
		       val p = Prod.map (p, makeTypeValue)
		    in
		       if needToMakeProd p
			  then Make (fn () => Value.vector (makeProd p))
		       else const ()
		    end
	       | Weak t =>
		    (case makeTypeValue t of
			Const _ => const ()
		      | Make f => Make (fn () => Value.weak (f ())))
	       | _ => const ()
	   end))
      fun typeValue (t: Type.t): Value.t =
	  case makeTypeValue t of
	     Const v => v
	   | Make f => f ()
      val typeValue =
	 Trace.trace ("typeValue", Type.layout, Value.layout) typeValue
      val coerce = Value.coerce
      fun inject {sum, variant} = typeValue (Type.datatypee sum)
      fun object {args, con, resultType} =
	 let
	    val m = makeTypeValue resultType
	 in
	    case con of
	       NONE =>
		  (case m of
		      Const v => v
		    | Make _ => Value.tuple args)
	  | SOME c =>
	       (case m of
		   Const v =>
		      let
			 val () =
			    case Value.deObject v of
			       NONE => ()
			     | SOME (Obj {args = args', ...}) =>
				  Vector.foreach2
				  (Prod.dest args, Prod.dest args',
				   fn ({elt = a, ...}, {elt = a', ...}) =>
				   coerce {from = a, to = a'})
		      in
			 v
		      end
		 | _ => Error.bug "strange con value")
	 end
      val object =
	 Trace.trace
	 ("object",
	  fn {args, con, ...} =>
	  Layout.record [("args", Prod.layout (args, Value.layout)),
			 ("con", Option.layout Con.layout con)],
	  Value.layout)
	 object
      val deWeak: Value.t -> Value.t =
	 fn v =>
	 case v of
	    Value.Ground t =>
	       typeValue (case Type.dest t of
			     Type.Weak t => t
			   | _ => Error.bug "deWeak")
	  | Value.Weak {arg, ...} => arg
	  | _ => Error.bug "deWeak"
      val deVector: Value.t -> Value.t =
	 fn v =>
	 case v of
	    Value.Ground t =>
	       typeValue (case Type.dest t of
			     Type.Vector p =>
				if 1 = Prod.length p
				   then Prod.elt (p, 0)
				else Error.bug "refFlatten can't handle flat vectors"
			   | _ => Error.bug "deUnary")
	  | Value.Vector {elt = p, ...} =>
	       if 1 = Prod.length p
		  then Prod.elt (p, 0)
	       else Error.bug "refFlatten can't handle flat vectors"
	  | _ => Error.bug "deUnary"
      val deArray = deVector
      fun primApp {args, prim, resultVar, resultType, targs} =
	 let
	    fun vector1 v =
	       case makeTypeValue resultType of
		  Const v => v
		| Make _ =>
		     Value.vector (Prod.make (Vector.new1 {elt = v,
							   isMutable = false}))
	    fun weak v =
	       case makeTypeValue resultType of
		  Const v => v
		| Make _ => Value.weak v
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
	       Array_sub => deArray (arg 0)
	     | Array_toVector => vector1 (deArray (arg 0))
	     | Array_update =>
		  (coerce {from = arg 2,
			   to = deArray (arg 0)}
		   ; result ())
	     | FFI _ =>
		  (* Some imports, like Real64.modf, take ref cells that can not
		   * be flattened.
		   *)
		  dontFlatten ()
	     | MLton_eq => equal ()
	     | MLton_equal => equal ()
	     | MLton_size => dontFlatten ()
	     | Vector_sub => deVector (arg 0)
	     | Weak_get => deWeak (arg 0)
	     | Weak_new => weak (arg 0)
	     | _ => result ()
	 end
      fun select {object, offset} =
	 let
	    datatype z = datatype Value.t
	 in
	    case object of
		  Ground t =>
		     (case Type.dest t of
			 Type.Object {args, ...} =>
			    typeValue (Prod.elt (args, offset))
		       | _ => Error.bug "select Ground")
		| Object ob => Object.select (ob, offset)
		| _ => Error.bug "select"
	 end
      fun update {object, offset, value} =
	 coerce {from = value,
		 to = select {object = object, offset = offset}}
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
		  select = fn {object, offset, ...} => select {object = object,
							       offset = offset},
		  update = update,
		  useFromTypeOnBinds = false}
      val varObject = Value.deObject o varValue
      (* Mark a variable as flat if it is used only once and that use is in an
       * object allocation.
       *)
      datatype varInfo =
	 NonObject
	| Object of {components: Var.t vector,
		     flat: Flat.t ref}
      val {get = varInfo: Var.t -> varInfo ref, ...} =
	 Property.get (Var.plist, Property.initFun (fn _ => ref NonObject))
      fun use x =
	 case ! (varInfo x) of
	    Object {flat, ...} => flat := Flat.NotFlat
	  | _ => ()
      fun uses xs = Vector.foreach (xs, use)
      fun loopStatement (Statement.T {exp, ty, var}) =
	 case exp of
	    Exp.Object {args, ...} =>
	       (case var of
		   NONE => uses args
		 | SOME var =>
		      case Value.deObject (varValue var) of
			 NONE => uses args
		       | SOME object =>
			    let
			       val () =
				  varInfo var
				  := Object {components = args,
					     flat = ref Flat.Unknown}
			    in
			       Vector.foreachi
			       (args, fn (offset, x) =>
				case ! (varInfo x) of
				   NonObject => ()
				 | Object {components, flat} => 
				      let
					 datatype z = datatype Flat.t
				      in
					 case !flat of
					    Unknown =>
					       flat :=
					       Offset {object = object,
						       offset = offset}
					  | _ => flat := NotFlat
				      end)
			    end)
	  | _ => Exp.foreachVar (exp, use)
      fun loopStatements ss = Vector.foreach (ss, loopStatement)
      fun loopTransfer t = Transfer.foreachVar (t, use)
      val {get = labelInfo: Label.t -> {args: (Var.t * Type.t) vector},
	   set = setLabelInfo, ...} =
	 Property.getSetOnce (Label.plist,
			      Property.initRaise ("info", Label.layout))
      val labelArgs = #args o labelInfo
      val () = loopStatements globals
      val () =
	 List.foreach
	 (functions, fn f =>
	  let
	     val {args, blocks, ...} = Function.dest f
	  in
	     Vector.foreach
	     (blocks, fn Block.T {args, label, statements, transfer, ...} =>
	      (setLabelInfo (label, {args = args})
	       ; loopStatements statements
	       ; loopTransfer transfer))
	  end)
      fun foreachObject (f): unit =
	 let
	    fun loopStatement (Statement.T {exp, var, ...}) =
	       case exp of
		  Exp.Object {args, ...} =>
		     Option.app
		     (var, fn var =>
		      case varValue var of
			 Value.Ground _ => ()
		       | Value.Object obj => f (var, args, obj)
		       | _ => Error.bug "Object with strange value")
		| _ => ()
	    val () = Vector.foreach (globals, loopStatement)
	    val () =
	       List.foreach
	       (functions, fn f =>
		let
		   val {blocks, ...} = Function.dest f
		in
		   Vector.foreach
		   (blocks, fn Block.T {statements, ...} =>
		    Vector.foreach (statements, loopStatement))
		end)
	 in
	    ()
	 end
      (* Try to flatten each ref. *)
      val () =
	 foreachObject
	 (fn (var, _, obj as Obj {flat, ...}) =>
	  let
	     datatype z = datatype Flat.t
	     val flat'Ref as ref flat' =
		case ! (varInfo var) of
		   NonObject => Error.bug "Object with NonObject"
		 | Object {flat, ...} => flat
	     fun notFlat () =
		(Set.setValue (flat, NotFlat)
		 ; flat'Ref := NotFlat)
	  in
	     case flat' of
		Offset {object = obj, offset = i} =>
		   (case Set.value flat of
		       NotFlat => notFlat ()
		     | Offset {object = obj', offset = i'} =>
			  if i = i' andalso Object.equals (obj, obj')
			     then ()
			  else notFlat ()
		     | Unknown => Set.setValue (flat, flat'))
	      | _ => notFlat ()
	  end)
      (* Disallow flattening into object components that aren't explicitly
       * constructed.
       *)
      val () =
	 foreachObject
	 (fn (_, args, obj) =>
	  Vector.foreach
	  (args, fn arg =>
	   case ! (varInfo arg) of
	      NonObject =>
		 let
		    val v = varValue arg
		 in
		    if isSome (Value.deFlat {inner = v, outer = obj})
		       then Value.dontFlatten v
		    else ()
		 end
	    | Object _ => ()))
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
		 let
		    val vi =
		       case ! (varInfo x) of
			  NonObject => str "NonObject"
			| Object {flat, ...} =>
			     seq [str "Object ", Flat.layout (!flat)]
		 in
		    display
		    (seq [Var.layout x, str " ",
			  record [("value", Value.layout (varValue x)),
				  ("varInfo", vi)]])
		 end)
	  in
	     ()
	  end)
      (* Conversion from values to types. *)
      datatype z = datatype Finish.t
      val traceValueType = Trace.trace ("valueType", Value.layout, Type.layout)
      fun valueType arg: Type.t =
	 traceValueType
	 (fn (v: Value.t) =>
	 let
	    datatype z = datatype Value.t
	 in
	    case v of
	       Ground t => t
	     | Object z => objectType z
	     | Vector {elt, finalType} =>
		  memoize (finalType, fn () =>
			   Type.vector (Prod.map (elt, valueType)))
	     | Weak {arg, finalType} =>
		  memoize (finalType, fn () => Type.weak (valueType arg))
	 end) arg
      and objectFinalComponents (obj as Obj {args, finalComponents, ...}) =
	 memoize
	 (finalComponents, fn () =>
	  Prod.make
	  (Vector.fromList
	   (Vector.foldr
	    (Prod.dest args, [], fn ({elt, isMutable = i}, ac) =>
	     case Value.deFlat {inner = elt, outer = obj} of
		NONE => {elt = valueType elt, isMutable = i} :: ac
	      | SOME z => 
		   Vector.foldr
		   (Prod.dest (objectFinalComponents z), ac,
		    fn ({elt, isMutable = i'}, ac) =>
		    {elt = elt, isMutable = i orelse i'} :: ac)))))
      and objectFinalOffsets (z as Obj {args, finalOffsets, flat, ...}) =
	 memoize
	 (finalOffsets, fn () =>
	  let
	     val initial =
		case Set.value flat of
		   Flat.Offset {object, offset} => objectOffset (object, offset)
		 | _ => 0
	     val (_, offsets) =
		Vector.fold
		(Prod.dest args, (initial, []), fn ({elt, ...}, (offset, ac)) =>
		 let
		    val width =
		       case Value.deFlat {inner = elt, outer = z} of
			  NONE => 1
			| SOME z => Prod.length (objectFinalComponents z)
		 in
		    (offset + width, offset :: ac)
		 end)
	  in
	     Vector.fromListRev offsets
	  end)
      and objectOffset (z: Object.t, offset: int): int =
	 Vector.sub (objectFinalOffsets z, offset)
      and objectType (z as Obj {con, finalType, flat, ...}): Type.t =
	 memoize
	 (finalType, fn () =>
	  case Set.value flat of
	     Flat.Offset {object, ...} => objectType object
	   | _ => Type.object {args = objectFinalComponents z,
			       con = con})
      (* Transform the program. *)
      fun transformFormals (xts: (Var.t * Type.t) vector)
	 : (Var.t * Type.t) vector =
	 Vector.map (xts, fn (x, _) => (x, valueType (varValue x)))
      val extraSelects: Statement.t list ref = ref []
      fun flattenValues (object: Var.t,
			 obj as Obj {args, ...},
			 ac: Var.t list): Var.t list =
	 Vector.foldri
	 (Prod.dest args, ac, fn (i, {elt, ...}, ac) =>
	  case Value.deFlat {inner = elt, outer = obj} of
	     NONE => 
		let
		   val var = Var.newNoname ()
		   val () =
		      List.push
		      (extraSelects,
		       Statement.T
		       {exp = Select {object = object,
				      offset = objectOffset (obj, i)},
			ty = valueType elt,
			var = SOME var})
		in
		   var :: ac
		end
	   | SOME obj => flattenValues (object, obj, ac))
      fun flattenArgs (xs: Var.t vector, outer: Object.t, ac): Var.t list =
	 Vector.foldr
	 (xs, ac, fn (x, ac) =>
	  let
	     val v = varValue x
	  in
	     case Value.deFlat {inner = v, outer = outer} of
		NONE => x :: ac
	      | SOME obj =>
		   (case ! (varInfo x) of
		       NonObject => flattenValues (x, obj, ac)
		     | Object {components, ...} =>
			  flattenArgs (components, obj, ac))
	  end)
      val flattenArgs =
	 Trace.trace3 ("flattenArgs",
		       Vector.layout Var.layout,
		       Object.layout,
		       List.layout Var.layout,
		       List.layout Var.layout)
	 flattenArgs
      fun transformStatement (s as Statement.T {exp, ty, var})
	 : Statement.t vector =
	 let
	    fun make e =
	       Vector.new1
	       (Statement.T {exp = e,
			     ty = (case var of
				      NONE => ty
				    | SOME var => valueType (varValue var)),
			     var = var})
	    fun none () = Vector.new0 ()
	 in
	    case exp of
	       Exp.Object {args, con} =>
		  (case var of
		      NONE => none ()
		    | SOME var =>
			 (case varObject var of
			     NONE => make exp
			   | SOME (z as Obj {flat, ...}) =>
				case Set.value flat of
				   Flat.Offset _ => none ()
				 | _ =>
				      let
					 val args =
					    Vector.fromList
					    (flattenArgs (args, z, []))
					 val extra = !extraSelects
					 val () = extraSelects := []
				      in
					 Vector.concat
					 [Vector.fromList extra,
					  make (Exp.Object
						{args = args, con = con})]
				      end))
	      | PrimApp {args, prim, targs} =>
		   let
		      val vargs = Vector.map (args, varValue)
		      val targs =
			 Vector.map
			 (Prim.extractTargs
			  (prim,
			   {args = vargs,
			    deArray = deArray,
			    deArrow = fn _ => Error.bug "deArrow",
			    deRef = fn _ => Error.bug "deRef",
			    deVector = deVector,
			    deWeak = deWeak,
			    result = (case var of
					 NONE => Value.unit
				       | SOME x => varValue x)}),
			  valueType)
		   in
		      make (PrimApp {args = args,
				     prim = prim,
				     targs = targs})
		   end
	     | Select {object, offset} =>
		  (case var of
		      NONE => none ()
		    | SOME var =>
			 (case varObject object of
			     NONE => make exp
			   | SOME obj => 
				make
				(if isSome (Value.deFlat {inner = varValue var,
							  outer = obj})
				    then Var object
				 else (Select
				       {object = object,
					offset = objectOffset (obj, offset)}))))
	     | Update {object, offset, value} =>
		  (case varObject object of
		      NONE => make exp
		    | SOME obj => 
			 make (Update {object = object,
				       offset = objectOffset (obj, offset),
				       value = value}))
	     | _ => make exp
	 end
      val transformStatement =
	 Trace.trace ("transformStatement",
		      Statement.layout,
		      Vector.layout Statement.layout)
	 transformStatement
      fun transformStatements ss =
	 Vector.concatV (Vector.map (ss, transformStatement))
      fun transformBlock (Block.T {args, label, statements, transfer}) =
	    Block.T {args = transformFormals args,
		     label = label,
		     statements = transformStatements statements,
		     transfer = transfer}
      fun valuesTypes vs = Vector.map (vs, valueType)
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
			     case Type.dest (valueType v) of
				Type.Object {args, ...} => args
			      | _ => Error.bug "strange con"
		 in
		    {args = args, con = con}
		 end)
	  in
	     Datatype.T {cons = cons, tycon = tycon}
	  end)
      fun transformFunction (f: Function.t): Function.t =
	  let
	     val {args, blocks, mayInline, name, start, ...} = Function.dest f
	     val {raises, returns, ...} = func name
	     val raises = Option.map (raises, valuesTypes)
	     val returns = Option.map (returns, valuesTypes)
	  in
	     Function.new {args = transformFormals args,
			   blocks = Vector.map (blocks, transformBlock),
			   mayInline = mayInline,
			   name = name,
			   raises = raises,
			   returns = returns,
			   start = start}
	  end
      val program =
	 Program.T {datatypes = datatypes,
		    functions = List.revMap (functions, transformFunction),
		    globals = transformStatements globals,
		    main = main}
      val () = Program.clear program
   in
      program
   end

end

