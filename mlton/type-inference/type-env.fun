(* Copyright (C) 1997-1999 NEC Research Institute.
 * Please see the file LICENSE for license information.
 *)
functor TypeEnv (S: TYPE_ENV_STRUCTS): TYPE_ENV =
struct

open S

local open Ast
in structure Aconst = Const
end

structure Field = Record.Field
structure Srecord = SortedRecord
structure Set = DisjointSet

structure Unknown =
   struct
      datatype t = T of {canGeneralize: bool,
			 equality: bool,
			 id: int}

      fun layout (T {id, ...}) =
	 let
	    open Layout
	 in
	    seq [str "Unknown ", Int.layout id]
	 end
      (* 		 namedRecord ("Unknown",
       * 			      [("equality", Bool.layout equality),
       * 			       ("canGeneralize", Bool.layout canGeneralize)]),
       *)
      local
	 val r: int ref = ref 0
      in
	 fun newId () = (Int.inc r; !r)
      end

      fun new {canGeneralize, equality} =
	 T {canGeneralize = canGeneralize,
	    equality = equality,
	    id = newId ()}

      fun join (T r, T r'): t =
	 T {equality = #equality r orelse #equality r',
	    canGeneralize = #canGeneralize r andalso #canGeneralize r',
	    id = newId ()}
   end

(* Flexible record spine, i.e. a possibly extensible list of fields. *)
structure Spine:
   sig
      type t

      val canAddFields: t -> bool
      val empty: unit -> t
      val fields: t -> Field.t list
      (* ensureField checks if field is there.  If it is not, then ensureField
       * will add it unless no more fields are allowed in the spine.
       *)
      val ensureField: t * Field.t -> unit
      val foldOverNew: t * (Field.t * 'a) list * 'b * (Field.t * 'b -> 'b) -> 'b
      val layout: t -> Layout.t
      val new: Field.t list -> t
      val noMoreFields: t -> unit
      val unify: t * t -> unit
   end =
   struct
      datatype t = T of {fields: Field.t list ref,
			 more: bool ref} Set.t

      fun new fields = T (Set.singleton {fields = ref fields,
					 more = ref true})

      fun empty () = new []

      fun layout (T s) =
	 let
	    val {fields, more} = Set.value s
	 in
	    Layout.record [("fields", List.layout Field.layout (!fields)),
			   ("more", Bool.layout (!more))]
	 end

      fun canAddFields (T s) = ! (#more (Set.value s))
      fun fields (T s) = ! (#fields (Set.value s))

      fun ensureFieldValue ({fields, more}, f) =
	 if List.contains (!fields, f, Field.equals)
	    then ()
	 else
	    if !more
	       then List.push (fields, f)
	    else Error.bug (concat ["record spine missing field ",
				    Field.toString f])

      fun ensureField (T s, f) = ensureFieldValue (Set.value s, f)

      fun noMoreFields (T s) = #more (Set.value s) := false

      fun unify (T s, T s') =
	 let
	    val v as {fields = fs, more = m} = Set.value s
	    val v' as {fields = fs', more = m'} = Set.value s'
	    fun subset (s, v) =
	       List.foreach (!fs, fn f => ensureFieldValue (v, f))
	    val _ = subset (fs, v')
	    val _ = subset (fs', v)
	    val _ = Set.union (s, s')
	 in
	    ()
	 end

      fun foldOverNew (spine: t, fs, ac, g) =
	 List.fold
	 (fields spine, ac, fn (f, ac) =>
	  if List.exists (fs, fn (f', _) => Field.equals (f, f'))
	     then ac
	  else g (f, ac))
   end

structure FinalRecordType =
   struct
      type t = (Field.t * XmlType.t) vector option ref

      fun new () = ref NONE

      fun layout (r: t) =
	 Option.layout (Vector.layout (Layout.tuple2 (Field.layout,
						      XmlType.layout)))
	 (!r)
   end

structure Type =
   struct
      (* Tuples of length <> 1 are always represented as records.
       * There will never be tuples of length one.
       *)
      datatype t = T of {ty: ty,
			 plist: PropertyList.t} Set.t
      and ty =
	 Con of Tycon.t * t vector
	| Int (* an unresolved int type *)
	| FlexRecord of {fields: fields,
			 final: FinalRecordType.t,
			 spine: Spine.t}
	(* GenFlexRecord only appears in type schemes.
	 * It will never be unified.
	 * The fields that are filled in after generalization are stored in
	 * extra.
	 *)
	| GenFlexRecord of {
			    extra: unit -> {field: Field.t,
					    tyvar: Tyvar.t} list,
			    fields: fields,
			    final: FinalRecordType.t,
			    spine: Spine.t
			    }
	| Record of t Srecord.t
	| Unknown of Unknown.t
	| Var of Tyvar.t
	| Word (* an unresolved word type *)
      withtype fields = (Field.t * t) list

      local
	 fun make f (T s) = f (Set.value s)
      in
	 val toType: t -> ty = make #ty
	 val plist: t -> PropertyList.t = make #plist
      end

      local
	 open Layout
      in
	 fun layoutFields fs =
	    List.layout (Layout.tuple2 (Field.layout, layout)) fs
	 and layout ty =
	    case toType ty of
	       Con (c, ts) =>
		  paren (align [seq [str "Con ", Tycon.layout c],
				Vector.layout layout ts])
	     | Int => str "Int"
	     | FlexRecord {fields, final, spine} =>
		  seq [str "Flex ",
		       record [("fields", layoutFields fields),
			       ("final", FinalRecordType.layout final),
			       ("spine", Spine.layout spine)]]
	     | GenFlexRecord {fields, final, spine, ...} =>
		  seq [str "GenFlex ",
		       record [("fields", layoutFields fields),
			       ("final", FinalRecordType.layout final),
			       ("spine", Spine.layout spine)]]
	     | Record r => Srecord.layout {record = r,
					   separator = ":",
					   extra = "",
					   layoutTuple = Vector.layout layout,
					   layoutElt = layout}
	     | Unknown u => Unknown.layout u
	     | Var a => paren (seq [str "Var ", Tyvar.layout a])
	     | Word => str "Word"
      end

      fun union (T s, T s') = Set.union (s, s')

      fun set (T s, v) = Set.setValue (s, v)
	 
      fun makeHom {con, int, flexRecord, genFlexRecord,
		   record, unknown, var, word} =
	 let
	    val {get, destroy} =
	       Property.destGet
	       (plist,
		Property.initRec
		(fn (t, get) =>
		 let
		    fun loopFields fields =
		       List.revMap (fields, fn (f, t) => (f, get t))
		 in
		    case toType t of
		       Con (c, ts) => con (t, c, Vector.map (ts, get))
		     | Int => int t
		     | FlexRecord {fields, final, spine} =>
			  flexRecord (t, {fields = loopFields fields,
					  final = final,
					  spine = spine})
		     | GenFlexRecord {extra, fields, final, spine} =>
			  genFlexRecord (t, {extra = extra,
					     fields = loopFields fields,
					     final = final,
					     spine = spine})
		     | Record r => record (t, Srecord.map (r, get))
		     | Unknown u => unknown (t, u)
		     | Var a => var (t, a)
		     | Word => word t
		 end))
	 in {hom = get, destroy = destroy}
	 end

      fun hom (ty, z) =
	 let val {hom, destroy} = makeHom z
	 in hom ty before destroy ()
	 end

      fun deconOpt t =
	 case toType t of
	    Con x => SOME x
	  | _ => NONE

      fun newTy (ty: ty): t =
	 T (Set.singleton {ty = ty,
			   plist = PropertyList.new ()})

      val new = newTy o Unknown o Unknown.new

      fun record {flexible, record} =
	 newTy (if flexible
		   then
		      let
			 val v = Srecord.toVector record
		      in
			 FlexRecord {fields = Vector.toList v,
				     final = FinalRecordType.new (),
				     spine = Spine.new (Vector.toListMap
							(v, #1))}
		      end
		else Record record)

      fun tuple ts =
	 if 1 = Vector.length ts
	    then Vector.sub (ts, 0)
	 else newTy (Record (Srecord.tuple ts))

      fun con (tycon, ts) =
	 if Tycon.equals (tycon, Tycon.tuple) then tuple ts
	 else newTy (Con (tycon, ts))
   end

structure Ops = TypeOps (structure Tycon = Tycon
			 open Type)

structure Type =
   struct
      (* Order is important, since want specialized definitions
       * in Type to override general definitions in Ops.
       *)
      open Ops Type

      val unit = tuple (Vector.new0 ())
	 
      val equals: t * t -> bool = fn (T s, T s') => Set.equals (s, s')
	 
      val var = newTy o Var

      (*val con = Trace.trace2 ("con", Tycon.layout,
       List.layout (", ", layout),
       layout) con*)
      fun ofConst c =
	 case c of
	    Aconst.Char _ => char
	  | Aconst.Int _ => newTy Type.Int
	  | Aconst.Real _ => real
	  | Aconst.String _ => string
	  | Aconst.Word _ => newTy Type.Word


      val traceCanUnify =
	 Trace.trace2 ("canUnify", layout, layout, Bool.layout)

      fun canUnify arg = 
	 traceCanUnify
	 (fn (t, t') =>
	  case (toType t,   toType t') of
	     (Unknown _,  _) => true
	   | (_, Unknown _) => true
	   | (Con (c, ts), Con (c', ts')) => (Tycon.equals (c, c')
					      andalso
					      Vector.forall2 (ts, ts', canUnify))
	   | (Con (c, ts), Word) =>
		0 = Vector.length ts andalso Tycon.isWordX c
	   | (Word, Con (c, ts)) =>
		0 = Vector.length ts andalso Tycon.isWordX c
	   | (Con (c, ts), Int) =>
		0 = Vector.length ts andalso Tycon.isIntX c
	   | (Int, Con (c, ts)) =>
		0 = Vector.length ts andalso Tycon.isIntX c
	   | (Var a, Var a') => Tyvar.equals (a, a')
	   | (Word, Word) => true
	   | (Int, Int) => true
	   | (Record r, Record r') =>
		let
		   val fs = Srecord.toVector r
		   val fs' = Srecord.toVector r'
		in Vector.length fs = Vector.length fs'
		   andalso Vector.forall2 (fs, fs', fn ((f, t), (f', t')) =>
					   Field.equals (f, f')
					   andalso canUnify (t, t'))
		end
	    | _ => false) arg

      val traceUnify = Trace.trace2 ("unify", layout, layout, Unit.layout)

      fun unify arg =
	 traceUnify
	 (fn (T s, T s') =>
	  if Set.equals (s, s')
	     then ()
	  else
	     let
		fun oneFlex ({fields, final, spine}, r) =
		   let
		      val _ =
			 List.foreach
			 (fields, fn (f, t) =>
			  case Srecord.peek (r, f) of
			     NONE =>
				Error.bug "oneFlex: in flex but not in record"
			   | SOME t' => unify (t, t'))
		      val _ =
			 List.foreach
			 (Spine.fields spine, fn f =>
			  case Srecord.peek (r, f) of
			     NONE =>
				Error.bug "oneFlex: in spine but not in record"
			   | SOME _ => ())
		      val _ =
			 Srecord.foldi
			 (r, (), fn (f, t, ()) =>
			  let
			     val _ = Spine.ensureField (spine, f)
			     val _ =
				case List.peek (fields, fn (f', _) =>
						Field.equals (f, f')) of
				   NONE => ()
				 | SOME (_, t') => unify (t, t')
			  in
			     ()
			  end)
		      val _ = Spine.noMoreFields spine
		   in
		      ()
		   end
		fun genFlexError () = Error.bug "GenFlexRecord seen in unify"
		val {ty = t, plist} = Set.value s
		val {ty = t', ...} = Set.value s'
		val t =
		   case (t, t')           of
		      (Unknown r, Unknown r') => Unknown (Unknown.join (r, r'))
		    | (t, Unknown _) => t
		    | (Unknown _, t) => t
		    | (Var a, Var a') => if Tyvar.equals (a, a')
					    then t
					 else Error.bug "unify Var"
		    | (Con (c, ts), Con (c', ts')) =>
			 if Tycon.equals (c, c')
			    then (unifys (ts, ts'); t)
			 else Error.bug "unify Con"
		    | (Con (c, ts), Word) =>
			 if Tycon.isWordX c andalso Vector.isEmpty ts
			    then t
			 else Error.bug "unify Word"
		    | (Word, Con (c, ts)) =>
			 if Tycon.isWordX c andalso Vector.isEmpty ts
			    then t'
			 else Error.bug "unify Word"
		    | (Con (c, ts), Int) =>
			 if Tycon.isIntX c andalso Vector.isEmpty ts
			    then t
			 else Error.bug "unify Int"
		    | (Int, Con (c, ts)) =>
			 if Tycon.isIntX c andalso Vector.isEmpty ts
			    then t'
			 else Error.bug "unify Int"
		    | (Word, Word) => t
		    | (Int, Int) => t
		    | (Record r, Record r') =>
			 let
			    val fs = Srecord.toVector r
			    val fs' = Srecord.toVector r'
			    val n = Vector.length fs
			    val n' = Vector.length fs'
			 in
			    
			    if n = n'
			       then (Vector.foreach2
				     (fs, fs', fn ((f, t), (f', t')) =>
				      if Field.equals (f, f')
					 then unify (t, t')
				      else Error.bug "unify field")
				     ; t)
			    else Error.bug "unify mismatch: different length records"
			 end
		    | (GenFlexRecord _, _) => genFlexError ()
		    | (_, GenFlexRecord _) => genFlexError ()
		    | (FlexRecord f, res as Record r) => (oneFlex (f, r); res)
		    | (res as Record r, FlexRecord f) => (oneFlex (f, r); res)
		    | (FlexRecord {fields = fields, spine = s, final, ...},
		       FlexRecord {fields = fields', spine = s', ...}) =>
			 let
			    val _ = Spine.unify (s, s')
			    fun subset (fields, fields') =
			       let
				  val res = ref fields'
				  val _ =
				     List.foreach
				     (fields, fn (f, t) =>
				      case List.peek (fields', fn (f', _) =>
						      Field.equals (f, f')) of
					 NONE => List.push (res, (f, t))
				       | SOME (_, t') => unify (t, t'))
			       in
				  !res
			       end
			    val _ = subset (fields, fields')
			    val fields = subset (fields', fields)
			 in
			    FlexRecord {fields = fields,
					final = final,
					spine = s}
			 end
		    | _ => Error.bug "unify mismatch"
		val _ = Set.union (s, s')
		val _ = Set.setValue (s, {ty = t, plist = plist})
	     in
		()
	     end) arg

      and unifys (ts: t vector, ts': t vector): unit =
	 if Vector.length ts = Vector.length ts'
	    then Vector.foreach2 (ts, ts', unify)
	 else Error.bug "unify Con: different number of args"

      fun unifys ts =
	 case ts of
	    t :: ts => (List.foreach (ts, fn t' => unify (t, t'))
			; t)
	  | [] => new {equality = false, canGeneralize = true}

      local
	 structure X = XmlType
	 val con = X.con
	 val unknown = con (Tycon.tuple, Vector.new0 ())
	 fun tuple ts =
	    if 1 = Vector.length ts
	       then Vector.sub (ts, 0)
	    else con (Tycon.tuple, ts)
	 fun sortFields (fields: (Field.t * 'a) list) =
	    let
	       val a = Array.fromList fields
	       val _ = QuickSort.sort (a, fn ((f, _), (f', _)) =>
				       Field.<= (f, f'))
	    in
	       Array.toVector a
	    end
	 fun unsorted (fields: (Field.t * X.t) list, final: FinalRecordType.t) =
	    let
	       val v = sortFields fields
	       val _ = final := SOME v
	    in
	       tuple (Vector.map (v, #2))
	    end
	 fun genFlexRecord (_, {extra, fields, final, spine}) =
	    unsorted (List.fold
		      (extra (), fields, fn ({field, tyvar}, ac) =>
		       (field, X.var tyvar) :: ac),
		      final)
	 fun flexRecord (_, {fields, final, spine}) =
	    if Spine.canAddFields spine
	       then Error.bug "unresolved ... in flexible pattern"
	    else unsorted (Spine.foldOverNew
			   (spine, fields, fields, fn (f, ac) =>
			    (f, X.unit) :: ac),
			   final)
	 fun record (_, r) = tuple (Srecord.range r)
	 val int = con (Tycon.defaultInt, Vector.new0 ())
	 val word = con (Tycon.defaultWord, Vector.new0 ())
	 val {hom: Type.t -> X.t, ...} =
	    makeHom {con = fn (_, c, ts) => con (c, ts),
		     int = fn _ => int,
		     flexRecord = flexRecord,
		     genFlexRecord = genFlexRecord,
		     record = record,
		     unknown = fn _ => unknown,
		     var = X.var o #2,
		     word = fn _ => word}
      in
	 val toXml = hom

	 val toXml = Trace.trace ("toXml", layout, XmlType.layout) toXml
      end
	 
      fun derecord t =
	 case toType t of
	    FlexRecord {final, ...} => (toXml t
					; valOf (!final))
	  | GenFlexRecord {final, ...} => (toXml t
					   ; valOf (!final))
	  | Record r => Vector.map (Srecord.toVector r, fn (f, t) =>
				    (f, toXml t))
	  | _ => Error.bug "Type.deRecord"
   end

structure InferScheme =
   struct
      datatype t =
	 Type of Type.t
       | General of {bound: unit -> Tyvar.t vector,
		     canGeneralize: bool,
		     flexes: Type.t list,
		     tyvars: Tyvar.t vector,
		     ty: Type.t}

      fun layout s =
	 case s of
	    Type t => Type.layout t
	  | General {canGeneralize, flexes, tyvars, ty, ...} =>
	       Layout.record [("canGeneralize", Bool.layout canGeneralize),
			      ("flexes", List.layout Type.layout flexes),
			      ("tyvars", Vector.layout Tyvar.layout tyvars),
			      ("ty", Type.layout ty)]

      val tyvars =
	 fn General {tyvars, ...} => tyvars
	  | Type _ => Vector.new0 ()
	 
      val bound =
	 fn General {bound, ...} => bound ()
	  | Type _ => Vector.new0 ()

      val bound =
	 Trace.trace ("Scheme.bound", layout, Vector.layout Tyvar.layout)
	 bound

      val ty =
	 fn General {ty, ...} => ty
	  | Type ty => ty

      fun make {canGeneralize, tyvars, ty} =
	 if 0 = Vector.length tyvars
	    then Type ty
	 else General {bound = fn () => tyvars,
		       canGeneralize = canGeneralize,
		       flexes = [],
		       tyvars = tyvars,
		       ty = ty}

      val fromType = Type

      val instantiate =
	 fn Type ty => {args = fn () => Vector.new0 (),
			instance = ty}
	  | General {canGeneralize, flexes, tyvars, ty, ...} =>
	       let
		  open Type
		  val {destroy = destroyTyvarInst,
		       get = tyvarInst: Tyvar.t -> Type.t option,
		       set = setTyvarInst} =
		     Property.destGetSetOnce (Tyvar.plist,
					      Property.initConst NONE)
		  val types =
		     Vector.toListMap
		     (tyvars, fn v =>
		      let
			 val t = Type.new {equality = Tyvar.isEquality v,
					   canGeneralize = canGeneralize}
			 val _ = setTyvarInst (v, SOME t)
		      in
			 t
		      end)
		  type z = {isNew: bool, ty: Type.t}
		  fun isNew {isNew = b, ty} = b
		  fun keep ty = {isNew = false, ty = ty}
		  fun con (ty, c, zs) =
		     if Vector.exists (zs, isNew)
			then {isNew = true,
			      ty = newTy (Con (c, Vector.map (zs, #ty)))}
		     else keep ty
		  val flexInsts = ref []
		  fun genFlexRecord (t, {extra, fields, final, spine}) =
		     let
			val fields = List.revMap (fields, fn (f, t: z) =>
						  (f, #ty t))
			val flex = 
			   newTy (FlexRecord {fields = fields,
					      final = FinalRecordType.new (),
					      spine = spine})
			val _ = List.push (flexInsts, {genFlex = t, flex = flex})
		     in
			{isNew = true,
			 ty = flex}
		     end
		  fun record (t, r) =
		     if Srecord.exists (r, isNew)
			then {isNew = true,
			      ty = newTy (Record (Srecord.map (r, #ty)))}
		     else keep t
		  fun var (ty, a) =
		     case tyvarInst a of
			NONE => {isNew = false, ty = ty}
		      | SOME ty => {isNew = true, ty = ty}
		  val {ty: Type.t, ...} =
		     Type.hom (ty, {con = con,
				    int = keep,
				    flexRecord = fn (t, _) => keep t,
				    genFlexRecord = genFlexRecord,
				    record = record,
				    unknown = fn (t, _) => keep t,
				    var = var,
				    word = keep})
		  val _ = destroyTyvarInst ()
		  val flexInsts = !flexInsts
		  fun args (): XmlType.t vector =
		     Vector.fromListMap
		     (List.fold
		      (flexes, types, fn (t, ac) =>
		       case Type.toType t of
			  Type.GenFlexRecord {fields, spine, ...} =>
			     let
				val flex =
				   case List.peek (flexInsts,
						   fn {genFlex, ...} =>
						   Type.equals (t, genFlex)) of
				      NONE => Error.bug "missing flexInst"
				    | SOME {flex, ...} => flex
				fun peekFields (fields, f) =
				   Option.map
				   (List.peek (fields, fn (f', _) =>
					       Field.equals (f, f')),
				    #2)
				val peek =
				   case Type.toType flex of
				      FlexRecord {fields, ...} =>
					 (fn f => peekFields (fields, f))
				    | GenFlexRecord {extra, fields, ...} =>
					 (fn f =>
					  case peekFields (fields, f) of
					     NONE =>
						Option.map
						(List.peek
						 (extra (), fn {field, ...} =>
						  Field.equals (f, field)),
						 Type.var o #tyvar)
					   | SOME t => SOME t)
				    | Record r => (fn f => Srecord.peek (r, f))
				    | _ => Error.bug "strange flexInst"
			     in
				Spine.foldOverNew
				(spine, fields, ac, fn (f, ac) =>
				 (case peek f of
				    NONE => Type.unit
				  | SOME t => t) :: ac)
			     end
			| _ => Error.bug "args expected GenFlexRecord"),
		      Type.toXml)
	       in {args = args,
		   instance = ty}
	       end
      val instantiate =
	 Trace.trace ("Scheme.instantiate", layout, Type.layout o #instance)
	 instantiate
   end

structure VarRange =
   struct
      datatype kind =
	 Normal
       | Delayed
       | Recursive of unit -> XmlType.t vector
       | Overload of (Var.t * Type.t) vector

      datatype t = T of {scheme: InferScheme.t,
			 kind: kind}

      fun scheme (T {scheme, ...}) = scheme

      fun layout (T {scheme, ...}) = InferScheme.layout scheme
   end

datatype t = T of z ref
and z =
   Empty
 | Cons of InferScheme.t * t

fun toList (T opens) =
   case !opens of
      Empty => []
    | Cons (s, opens) => s :: (toList opens)

local
   open Layout
in
   fun layout e = list (List.map (toList e, InferScheme.layout))
end

val empty: t = T (ref Empty)

(* This property is destroyed after type inference is done by the call to
 * Xml.Program.clear in infer.fun.
 * The property can not be getSetOnce, because it is set twice for fun
 * declarations.
 *)
val {get = getVarRange: Var.t -> VarRange.t, set = setVarRange, ...} =
   Property.getSet (Var.plist, Property.initRaise ("range", Var.layout))

val setVarRange =
   Trace.trace2 ("setVarRange", Var.layout, VarRange.layout, Unit.layout)
   setVarRange
   
fun extendVarRange (e, x, r) =
   let
      val _ = setVarRange (x, r)
   in
      T (ref (Cons (VarRange.scheme r, e)))
   end

fun lookupVarRange (_, x) = getVarRange x

val lookupVarRange =
   Trace.trace2 ("Env.lookupVarRange", layout, Var.layout, VarRange.layout)
   lookupVarRange

fun lookupVar (e, x) = VarRange.scheme (lookupVarRange (e, x))
   
fun extendVar (e, x, s) =
   extendVarRange (e, x, VarRange.T {scheme = s,
				     kind = VarRange.Normal})
val extendVar =
   Trace.trace3 ("Env.extendVar", layout, Var.layout, InferScheme.layout,
		 layout)
   extendVar
   
fun closes (e: t, tys: Type.t vector, ensure: Tyvar.t vector)
   : {bound: unit -> Tyvar.t vector,
      mayHaveTyvars: bool,
      schemes: InferScheme.t vector} =
   let
      fun add (r, x, equals) =
	 if List.contains (!r, x, equals)
	    then ()
	 else List.push (r, x)
      fun remove (r, x, equals) =
	 if List.contains (!r, x, equals)
	    then r := List.remove (!r, fn x' => equals (x, x'))
	 else ()
      val freeTyvars: Tyvar.t list ref = ref []
      val freeUnknowns: Type.t list ref = ref []
      val flexes: Type.t list ref = ref []
      (* Add all of the unknown types and all of the type variables. *)
      val _ =
	 Vector.foreach
	 (tys, fn ty =>
	  Type.hom
	  (ty,
	   {con = fn _ => (),
	    int = fn _ => (),
	    flexRecord = fn (t, _) => add (flexes, t, Type.equals),
	    genFlexRecord = fn _ => Error.bug "GenFlexRecord seen in Env.close",
	    record = fn _ => (),
	    unknown = (fn (t, Unknown.T {canGeneralize, ...}) =>
		       if canGeneralize
			  then add (freeUnknowns, t, Type.equals)
		       else ()),
	    var = fn (_, a) => add (freeTyvars, a, Tyvar.equals),
	    word = fn _ => ()}))
      fun finish () =
	 let
	    val flexes = !flexes
	    val tyvars =
	       List.fold
	       (!freeUnknowns, !freeTyvars, fn (t, ac) =>
		case Type.toType t of
		   Type.Unknown (Unknown.T {equality, ...}) =>
		      let
			 val a = Tyvar.newNoname {equality = equality}
			 val _ = Type.set (t, {ty = Type.Var a,
					       plist = PropertyList.new ()})
		      in
			 a :: ac
		      end
		 | _ => Error.bug "strange freeUnknown")
	    (* Change all remaining FlexRecord to GenFlexRecord. *)
	    val _ =
	       List.foreach
	       (flexes, fn Type.T s =>
		let
		   val {ty, plist} = Set.value s
		in
		   case ty of
		      Type.FlexRecord {fields, spine, ...} =>
			 let
			    val extra =
			       Promise.lazy
			       (fn () =>
				let
				   val _ =
				      if Spine.canAddFields spine
					 then Error.bug "unresolved ... in flexible pattern"
				      else ()
				in
				   Spine.foldOverNew
				   (spine, fields, [], fn (f, ac) =>
				    {field = f,
				     tyvar = Tyvar.newNoname {equality = false}}
				    :: ac)
				end)
			 in
			    Set.setValue
			    (s, {plist = plist,
				 ty =
				 Type.GenFlexRecord {extra = extra,
						     fields = fields,
						     final = FinalRecordType.new (),
						     spine = spine}})
			 end
		    | _ => Error.bug "flexes contained non FlexRecord"
		end)
	    fun bound () =
	       Vector.fromList
	       (List.fold
		(flexes, tyvars, fn (t, ac) =>
		 case Type.toType t of
		    Type.GenFlexRecord {extra, fields, spine, ...} =>
		       let
			  val extra = extra ()
		       in
			  Spine.foldOverNew
			  (spine, fields, ac, fn (f, ac) =>
			   case List.peek (extra, fn {field, ...} =>
					   Field.equals (f, field)) of
			      NONE => Error.bug "GenFlex missing field"
			    | SOME {tyvar, ...} => tyvar :: ac)
		       end
		  | _ => Error.bug "bound expected GenFlex"))
	    val schemes =
	       Vector.map
	       (tys, fn ty =>
		InferScheme.General {bound = bound,
				     canGeneralize = true,
				     flexes = flexes,
				     tyvars = Vector.fromList tyvars,
				     ty = ty})
	 in
	    {bound = bound,
	     mayHaveTyvars = true,
	     schemes = schemes}
	 end
      (* Loop through all of the type schemes in the environment and remove
       * any frees or flexes.
       *)
      fun loop (T r, T r') =
	 if List.isEmpty (!freeTyvars)
	    andalso List.isEmpty (!freeUnknowns)
	    andalso List.isEmpty (!flexes)
	    then {bound = fn () => Vector.new0 (),
		  mayHaveTyvars = false,
		  schemes = Vector.map (tys, InferScheme.Type)}
	 else
	    case !r' of
	       Empty => (r := Empty; finish ())
	     | pair as Cons (s, r') =>
		  let
		     val bound = InferScheme.tyvars s
		     val keep = ref false
		     fun ignore _ = ()
		     fun flexRecord (t, _) =
			 (keep := true
			  ; remove (flexes, t, Type.equals))
		     fun unknown (t, Unknown.T {canGeneralize, ...}) =
			if canGeneralize
			   then (keep := true
				 ; remove (freeUnknowns, t, Type.equals))
			else ()
		     fun var (_, a) =
			if Vector.contains (ensure, a, Tyvar.equals)
			   then Error.bug "unable to generalize tyvar"
			else 
			   if Vector.exists (bound, fn a' =>
					     Tyvar.equals (a, a'))
			      then ()
			   else (keep := true
				 ; remove (freeTyvars, a, Tyvar.equals))
		     val _ = Type.hom (InferScheme.ty s,
				       {con = ignore,
					int = ignore,
					flexRecord = flexRecord,
					genFlexRecord = ignore,
					record = ignore,
					unknown = unknown,
					var = var,
					word = ignore})
		  in
		     if !keep
			then (r := pair
			      ; loop (r', r'))
		     else loop (T r, r')
		  end
   in
      loop (e, e)
   end

val closes =
   Trace.trace3
   ("Env.closes",
    layout, Vector.layout Type.layout, Vector.layout Tyvar.layout,
    fn {bound, mayHaveTyvars, schemes} =>
    Layout.record [("mayHaveTyvars", Bool.layout mayHaveTyvars),
		   ("schemes", Vector.layout InferScheme.layout schemes)])
   closes

fun close (e, t, ts) =
   let
      val {bound, mayHaveTyvars, schemes} = closes (e, Vector.new1 t, ts)
   in
      {bound = bound,
       mayHaveTyvars = mayHaveTyvars,
       scheme = Vector.sub (schemes, 0)}
   end

val closes =
   fn z =>
   let
      val {bound, schemes, ...} = closes z
   in
      {bound = bound,
       schemes = schemes}
   end
       
end
