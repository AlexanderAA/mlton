(* Copyright (C) 2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

functor RepType (S: REP_TYPE_STRUCTS): REP_TYPE =
struct

open S

type int = Int.t

structure Type =
   struct
      datatype t = T of dest
      and dest =
	 Address of t
	| Constant of WordX.t
	| ExnStack
	| GCState
	| Int of IntSize.t
	| Junk of Bits.t
	| Label of Label.t
	| Pointer of PointerTycon.t
	| Real of RealSize.t
	| Seq of t vector
	| Sum of t vector
	| Word of Bits.t

      fun dest (T d): dest = d
 
      fun layout (t: t): Layout.t =
	 let
	    open Layout
	 in
	    case dest t of
	       Address t => seq [str "Address ", layout t]
	     | Constant w => seq [str "0x", WordX.layout w, str ":",
				  WordSize.layout (WordX.size w)]
	     | ExnStack => str "ExnStack"
	     | GCState => str "GCState"
	     | Int s => str (concat ["Int", IntSize.toString s])
	     | Junk b => str (concat ["Junk", Bits.toString b])
	     | Label l => seq [str "Label ", Label.layout l]
	     | Pointer p => PointerTycon.layout p
	     | Real s => str (concat ["Real", RealSize.toString s])
	     | Seq ts => List.layout layout (Vector.toList ts)
	     | Sum ts => paren (seq (separate (Vector.toListMap (ts, layout),
					       " + ")))
	     | Word s => str (concat ["Word", Bits.toString s])
	 end

      val toString = Layout.toString o layout

      fun compare (t, t') =
	 case (dest t, dest t') of
	    (Address t, Address t') => compare (t, t')
	  | (Address _, _) => LESS
	  | (Constant w, Constant w') =>
	       Relation.lexico
	       (WordSize.compare (WordX.size w, WordX.size w'), fn () =>
		IntInf.compare (WordX.toIntInf w, WordX.toIntInf w'))
	  | (Constant _, _) => LESS
	  | (ExnStack, ExnStack) => EQUAL
	  | (ExnStack, _) => LESS
	  | (GCState, GCState) => EQUAL
	  | (GCState, _) => LESS
	  | (Int s, Int s') => IntSize.compare (s, s')
	  | (Int _, _) => LESS
	  | (Junk b, Junk b') => Bits.compare (b, b')
	  | (Junk _, _) => LESS
	  | (Label l, Label l') =>
	       String.compare (Label.originalName l, Label.originalName l')
	  | (Label _, _) => LESS
	  | (Pointer p, Pointer p') => PointerTycon.compare (p, p')
	  | (Pointer _, _) => LESS
	  | (Real s, Real s') => RealSize.compare (s, s')
	  | (Real _, _) => LESS
	  | (Seq ts, Seq ts') => compares (ts, ts')
	  | (Seq _, _) => LESS
	  | (Sum ts, Sum ts') => compares (ts, ts')
	  | (Sum _, _) => LESS
	  | (Word s, Word s') => Bits.compare (s, s')
	  | _ => GREATER
      and compares (ts: t vector, ts': t vector): Relation.t =
	 Vector.compare (ts, ts', compare)

      val {<= = lessEq, equals, ...} = Relation.compare compare

      val equals =
	 Trace.trace2 ("Machine.Type.equals", layout, layout, Bool.layout)
	 equals

      local
	 val word = Bits.inWord
      in
	 fun width (t: t): Bits.t =
	    case dest t of
	       Address _ => word
	     | Constant w => WordSize.bits (WordX.size w)
	     | ExnStack => word
	     | GCState => Bits.inPointer
	     | Int s => IntSize.bits s
	     | Junk b => b
	     | Label _ => word
	     | Pointer _ => word
	     | Real s => RealSize.bits s
	     | Seq ts => Vector.fold (ts, Bits.zero, fn (t, b) =>
				      Bits.+ (b, width t))
	     | Sum ts => width (Vector.sub (ts, 0))
	     | Word b => b
      end

      val bytes = Bits.toBytes o width

      val address = T o Address
      val constant = T o Constant
      val exnStack = T ExnStack
      val gcState = T GCState
      val int = T o Int
      val junk = T o Junk
      val label = T o Label
      val pointer = T o Pointer
      val real = T o Real
      val word = T o Word

      val char = word Bits.inByte

      fun isUnit t = Bits.zero = width t
	 
      local
	 fun seqOnto (ts: t vector, ts': t list): t list =
	    Vector.foldr (ts, ts', fn (t, ts) =>
			  if isUnit t
			     then ts
			  else
			     case (dest t, ts) of
				(Constant w, t' :: ts') =>
				   (case dest t' of
				       Constant w' =>
					  constant (WordX.splice {hi = w',
								  lo = w})
					  :: ts'
				     | _ => t :: ts)
			      | (Seq ts', _) => seqOnto (ts', ts)
			      | (Word s, t' :: ts') =>
				   (case dest t' of
				       Word s' =>
					  word (Bits.+ (s, s')) :: ts'
				     | _ => t :: ts)
			      | _ => t :: ts)
      in
	 fun seq ts =
	    case seqOnto (ts, []) of
	       [t] => t
	     | ts => T (Seq (Vector.fromList ts))
      end
   
      val unit = seq (Vector.new0 ())

      fun sum (ts: t vector): t =
	 if 1 <= Vector.length ts
	    andalso
	    let
	       val w = width (Vector.sub (ts, 0))
	    in
	       Vector.forall (ts, fn t => Bits.equals (w, width t))
	    end
	    then
	       let
		  val ts =
		     Vector.removeDuplicates
		     (QuickSort.sortVector (ts, lessEq), equals)
	       in
		  if 1 = Vector.length ts
		     then Vector.sub (ts, 0)
		  else T (Sum ts)
	       end
	 else Error.bug "invalid sum"
	       
      val sum = Trace.trace ("Type.sum", Vector.layout layout, layout) sum
	       
      val bool = sum (Vector.new2
		      (constant (WordX.fromIntInf (0, WordSize.default)),
		       constant (WordX.fromIntInf (1, WordSize.default))))
	 
      fun cPointer () = word Bits.inPointer

      fun isCPointer t =
	 case dest t of
	    Word b => Bits.equals (b, Bits.inPointer)
	  | _ => false
	 
      val defaultInt = int IntSize.default
      val defaultWord = word Bits.inWord
      val word8 = word Bits.inByte

      val stack = pointer PointerTycon.stack
      val thread = pointer PointerTycon.thread
      val wordVector = pointer PointerTycon.wordVector
      val word8Vector = pointer PointerTycon.word8Vector
      val string = word8Vector

      val intInf: t =
	 sum (Vector.new2
	      (wordVector,
	       seq (Vector.new2
		    (constant (WordX.fromIntInf
			       (1, WordSize.fromBits (Bits.fromInt 1))),
		     int (IntSize.I (Bits.fromInt 31))))))

      local
	 fun make is t =
	    case dest t of
	       Constant w => is w
	     | _ => false
      in
	 val isOne = make WordX.isOne
	 val isZero = make WordX.isZero
      end

      fun isBool t =
	 case dest t of
	    Sum ts =>
	       2 = Vector.length ts
	       andalso isZero (Vector.sub (ts, 0))
	       andalso isOne (Vector.sub (ts, 1))
	  | _ => false
	       
      fun isReal t =
	 case dest t of
	    Real _ => true
	  | _ => false

      fun isPointer t =
	 case dest t of
	    Pointer _ => true
	  | Sum ts => Vector.exists (ts, isPointer)
	  | _ => false

      val traceSplit =
	 Trace.trace2 ("Type.split", layout,
		       fn {lo} => Layout.record [("lo", Bits.layout lo)],
		       fn {hi, lo} =>
		       Layout.record [("hi", layout hi),
				      ("lo", layout lo)])

      fun split arg: {hi: t, lo: t} =
	 traceSplit
	 (fn (t: t, {lo: Bits.t}) =>
	  let
	     val w = width t
	  in
	     if Bits.> (lo, w)
		then Error.bug "Type.split"
	     else if Bits.isZero lo
		     then {lo = unit, hi = t}
		  else if Bits.equals (lo, w)
			  then {lo = t, hi = unit}
		       else
			  let
			     val hi = Bits.- (w, lo)
			  in
			     case dest t of
				Constant c =>
				   let
				      val {hi = hiW, lo = loW} =
					 WordX.split (c, {lo = lo})
				   in
				      {hi = constant hiW,
				       lo = constant loW}
				   end
			      | Junk _ =>
				   {hi = junk hi,
				    lo = junk lo}
			      | Seq ts =>
				   let
				      fun loop (i: int, lo: Bits.t, ac: t list)
					 : {hi: t, lo: t} =
					 let
					    val t = Vector.sub (ts, i)
					    val w = width t
					 in
					    if Bits.> (lo, w)
					       then loop (i + 1, Bits.- (lo, w),
							  t :: ac)
					    else
					       let
						  val {hi, lo} =
						     split (t, {lo = lo})
						  val hi =
						     seq
						     (Vector.fromList
						      (hi ::
						       (Vector.toList
							(Vector.dropPrefix
							 (ts, i + 1)))))
						  val lo =
						     seq (Vector.fromListRev
							  (lo :: ac))
					       in
						  {hi = hi, lo = lo}
					       end
					 end
				   in
				      loop (0, lo, [])
				   end
			      | Sum ts =>
				   let
				      val all = Vector.map (ts, fn t =>
							    split (t, {lo = lo}))
				      fun make f = sum (Vector.map (all, f))
				   in
				      {hi = make #hi,
				       lo = make #lo}
				   end
			      | _ => {hi = word hi,
				      lo = word lo}
			  end
	  end) arg

      fun prefix (t, b) = #lo (split (t, {lo = b}))

      fun dropSuffix (t, b) = prefix (t, Bits.- (width t, b))

      fun dropPrefix (t, b) = #hi (split (t, {lo = b}))

      fun suffix (t, b) = dropPrefix (t, Bits.- (width t, b))

      fun fragment (t: t, {start, width}): t =
	 prefix (dropPrefix (t, start), width)

      val fragment =
	 Trace.trace2 ("Type.fragment",
		       layout,
		       fn {start, width} =>
		       Layout.record [("start", Bits.layout start),
				      ("width", Bits.layout width)],
		       layout)
	 fragment

      fun isSubtype (t: t, t': t): bool =
	 Bits.equals (width t, width t')
	 andalso
	 (equals (t, t')
	  orelse
	  (case (dest t, dest t') of
	      (Address t, Address t') => isSubtype (t, t')
	    | (Seq ts, Sum ts') =>
		 (* Multiply out any sums in the sequence, and check that each
		  * resulting sequence is in one of the ts'.  This is sound,
		  * but not complete.  For example, it won't show that
		  * Word4 is a subtype of (Word3 * 1) + (Word3 * 0).
		  *)
		 let
		    val flat =
		       Vector.foldr
		       (ts, [[]], fn (t, tss) =>
			let
			   fun cons (t, ac) =
			      List.fold (tss, ac, fn (ts, ac) =>
					 (t :: ts) :: ac)
			in
			   case dest t of
			      Sum ts => Vector.fold (ts, [], cons)
			    | _ => cons (t, [])
			end)
		 in
		    List.forall (flat, fn ts =>
				 let
				    val t = seq (Vector.fromList ts)
				 in
				    Vector.exists (ts', fn t' =>
						   isSubtype (t, t'))
				 end)
		 end
	    | (Seq ts, Word _) =>
		 Vector.forall (ts, fn t => isSubtype (t, word (width t)))
	    (*	      | (Word _, Sum _) => *)
	    | (_, Junk _) => true
	    | (Junk _, _) => false
	    | (_, Seq ts') =>
		 let
		    val n' = Vector.length ts'
		    fun loop (i, t) =
		       let
			  val t' = Vector.sub (ts', i)
			  val i = i + 1
		       in
			  if i = n'
			     then isSubtype (t, t')
			  else
			     let
				val {hi, lo} = split (t, {lo = width t'})
			     in
				isSubtype (lo, t') andalso loop (i, hi)
			     end
		       end
		 in
		    loop (0, t)
		 end
	    | (Sum ts, _) => Vector.forall (ts, fn t => isSubtype (t, t'))
	    | (_, Sum ts') => Vector.exists (ts', fn t' => isSubtype (t, t'))
	    | (_, Word _) => true
	    | _ => false))

      val isSubtype =
	 Trace.trace2 ("Type.isSubtype", layout, layout, Bool.layout) isSubtype

      fun isValidInit (t, v) =
	 let
	    val (_, ts) =
	       Vector.fold
	       (v, (Bytes.zero, []), fn ({offset, ty}, (last, ts)) =>
		let
		   val ts =
		      if Bytes.equals (last, offset)
			 then ts
		      else junk (Bytes.toBits (Bytes.- (offset, last))) :: ts
		in
		   (Bytes.+ (offset, bytes ty), ty :: ts)
		end)
	    val init = seq (Vector.fromListRev ts)
	    val init =
	       if Bits.equals (width t, width init)
		  then init
	       else seq (Vector.new2 (init, junk (Bits.- (width t, width init))))
	 in
	    isSubtype (init, t)
	 end

      val isValidInit =
	 Trace.trace2 ("Type.isValidInit",
		       layout,
		       Vector.layout (fn {offset, ty} =>
				      Layout.record
				      [("offset", Bytes.layout offset),
				       ("ty", layout ty)]),
		       Bool.layout)
	 isValidInit

      fun binaryWord (t1: t, t2: t): t =
	 let
	    val w = width t1
	    val t = word w
	 in
	    if isSubtype (t1, t) andalso isSubtype (t2, t)
	       then t
	    else junk w
	 end

      fun add (t1: t, t2: t): t =
	 if width t1 <> width t2
	    then Error.bug "Type.add"
	 else
	    case dest t1 of
	       Address t =>
		  let
		     val w = width t
		     val m =
			Bits.fromWord (Word.maxPow2ThatDivides
				       (Bytes.toWord (Bits.toBytes w)))
		  in
		     if isSubtype
			(t2, seq (Vector.new2
				  (constant (WordX.zero (WordSize.fromBits m)),
				   word (Bits.- (w, m)))))
			then t1
		     else junk (width t1)
		  end
	     | _ => binaryWord (t1, t2)

      val add = Trace.trace2 ("Type.add", layout, layout, layout) add

      fun mulConstant (t: t, w: WordX.t): t =
	 case dest t of
	    Constant w' => constant (WordX.* (w, w'))
	  | _ =>
	       let
		  val n = width t
		  val t' = word n
	       in
		  if isSubtype (t, t')
		     then
			let
			   val lo =
			      Bits.fromWord
			      (IntInf.maxPow2ThatDivides (WordX.toIntInf w))
			in
			   seq (Vector.new2
				(constant (WordX.zero (WordSize.fromBits lo)),
				 word (Bits.- (n, lo))))
			end
		  else junk n
	       end
	 
      fun mul (t: t, t': t): t =
	 if width t <> width t'
	    then Error.bug "Type.mul"
	 else
	    case (dest t, dest t') of
	       (Constant w, _) => mulConstant (t', w)
	     | (_, Constant w') => mulConstant (t, w')
	     | _ => binaryWord (t, t')

      val mul = Trace.trace2 ("Type.mul", layout, layout, layout) mul

      fun shift (t1, t2) =
	 let
	    val w = width t1
	    val t1' = word w
	    val t2' = word (width t2)
	 in
	    if isSubtype (t1, t1') andalso isSubtype (t2, t2')
	       then t1'
	    else junk w
	 end

      fun lshift (t, t'): t =
	 case dest t' of
	    Constant w =>
	       let
		  val shift = Bits.fromIntInf (WordX.toIntInf w)
	       in
		  seq (Vector.new2 (constant (WordX.zero (WordSize.fromBits shift)),
				    dropSuffix (t, shift)))
	       end
	  | _ => shift (t, t')

      val lshift = Trace.trace2 ("Type.lshift", layout, layout, layout) lshift

      fun rshift (t, t'): t =
	 case dest t' of
	    Constant w =>
	       let
		  val shift = Bits.fromIntInf (WordX.toIntInf w)
	       in
		  seq (Vector.new2 (dropPrefix (t, shift),
				    constant (WordX.zero
					      (WordSize.fromBits shift))))
	       end
	  | _ => shift (t, t')
	 
      val rshift = Trace.trace2 ("Type.rshift", layout, layout, layout) rshift

      local
	 fun make (name: string,
		   const: WordX.t * WordX.t -> WordX.t,
		   bit: bool -> t)
	    : t * t -> t option =
	    let
	       val rec doit: t * t -> t option =
		  fn (t, t') =>
		  if not (Bits.equals (width t, width t'))
		     then NONE
		  else
		     case (dest t, dest t') of
			(Constant w, _) => SOME (doConstant (t', w))
		      | (_, Constant w') => SOME (doConstant (t, w'))
		      | (Word _, Word _) => SOME t
		      | _ => NONE
	       and doConstant: t * WordX.t -> t =
		  fn (t, w) =>
		  if not (Bits.equals (width t, WordSize.bits (WordX.size w)))
		     then Error.bug (concat ["Type.", name, "Constant"])
		  else
		     case dest t of
			Constant w' => constant (const (w, w'))
		      | Seq ts =>
			   seq
			   (Vector.fromListRev
			    (#2
			     (Vector.fold
			      (ts, (w, []), fn (t, (w, ac)) =>
			       let
				  val {hi, lo} = WordX.split (w, {lo = width t})
			       in
				  (hi, doConstant (t, lo) :: ac)
			       end))))
		      | Sum ts =>
			   sum (Vector.map (ts, fn t => doConstant (t, w)))
		      | Word _ =>
			   seq (Vector.tabulate
				(Bits.toInt (width t), fn i =>
				 bit (WordX.bitIsSet (w, i))))
		      | _ =>
			   junk (width t)
	    in
	       doit
	    end
      in
	 val andb = make ("andb", WordX.andb, fn b =>
			  if b
			     then word (Bits.fromInt 1)
			  else constant (WordX.zero WordSize.one))
	 val orb = make ("orb", WordX.orb,
			 fn b =>
			 if b
			    then constant (WordX.one WordSize.one)
			 else word (Bits.fromInt 1))
      end
	 
      local
	 structure C =
	    struct
	       open CType

	       val defaultWord = Word32
	       val pointer = Word32

	       fun fromBits (b: Bits.t): t =
		  case Bits.toInt b of
		     8 => Word8
		   | 16 => Word16
		   | 32 => Word32
		   | 64 => Word64
		   | _ => Error.bug (concat ["CType.fromBits: ",
					     Bits.toString b])

	       val fromIntSize = fromBits o IntSize.bits
	       val fromWordSize = fromBits o WordSize.bits
	    end
	 fun w i = word (Bits.fromInt i)
      in
	 val fromCType: CType.t -> t =
	    fn C.Pointer => w 32
	     | C.Real32 => real RealSize.R32
	     | C.Real64 => real RealSize.R64
	     | C.Word8 => w 8
	     | C.Word16 => w 16
	     | C.Word32 => w 32
	     | C.Word64 => w 64

	 val rec toCType: t -> CType.t =
	    fn t =>
	    if isPointer t
	       then C.Pointer
	    else 
	       case dest t of
		  Real s =>
		     (case s of
			 RealSize.R32 => C.Real32
		       | RealSize.R64 => C.Real64)
		| _ => C.fromBits (width t)

	 val name = C.name o toCType

	 fun align (t: t, n: Bytes.t): Bytes.t = C.align (toCType t, n)
      end

      fun bytesAndPointers (t: t): Bytes.t * int =
	 case dest t of
	    Pointer _ => (Bytes.zero, 1)
	  | Seq ts =>
	       (case Vector.peeki (ts, isPointer o #2) of
		   NONE => (bytes t, 0)
		 | SOME (i, _) =>
		      let
			 val b = bytes (seq (Vector.prefix (ts, i)))
		      in
			 (b, (Bytes.toInt (Bytes.- (bytes t, b))
			      div Bytes.toInt Bytes.inPointer))
		      end)
	  | Sum ts =>
	       Vector.fold
	       (ts, (bytes t, 0), fn (t, (b, p)) =>
		let
		   val (b', p') = bytesAndPointers t
		in
		   if Bytes.< (b', b)
		      then (b', p')
		   else (b, p)
		end)
	  | _ => (bytes t, 0)
   end

structure ObjectType =
   struct
      structure PointerTycon = PointerTycon
      structure Runtime = Runtime

      type ty = Type.t
	 
      datatype t =
	 Array of Type.t
       | Normal of Type.t
       | Stack
       | Weak of Type.t
       | WeakGone

      fun layout (t: t) =
	 let
	    open Layout
	 in
	    case t of
	       Array t => seq [str "Array ", Type.layout t]
	     | Normal t => seq [str "Normal ", Type.layout t]
	     | Stack => str "Stack"
	     | Weak t => seq [str "Weak ", Type.layout t]
	     | WeakGone => str "WeakGone"
	 end

      fun isOk (t: t): bool =
	 case t of
	    Array t => Bits.isByteAligned (Type.width t)
	  | Normal t =>
	       not (Type.isUnit t) andalso Bits.isWordAligned (Type.width t)
	  | Stack => true
	  | Weak t => Type.isPointer t
	  | WeakGone => true

      val stack = Stack

      val thread =
	 Normal (Type.seq
		 (Vector.new3 (Type.defaultWord,
			       Type.defaultWord,
			       Type.stack)))

      val word8Vector = Array Type.word8

      val wordVector = Array Type.defaultWord

      val basic =
	 Vector.fromList
	 [(PointerTycon.stack, stack),
	  (PointerTycon.thread, thread),
	  (PointerTycon.weakGone, WeakGone),
	  (PointerTycon.wordVector, wordVector),
	  (PointerTycon.word8Vector, word8Vector)]

      local
	 structure R = Runtime.RObjectType
      in
	 fun toRuntime (t: t): R.t =
	    case t of
	       Array t => let
			     val (b, p) = Type.bytesAndPointers t
			  in
			     R.Array {nonPointer = b,
				      pointers = p}
			  end
	     | Normal t => let
			      val (b, p) = Type.bytesAndPointers t
			   in
			      R.Normal {nonPointer = Bytes.toWords b,
					pointers = p}
			   end
	     | Stack => R.Stack
	     | Weak _ => R.Weak
	     | WeakGone => R.WeakGone
      end
   end

open Type
   
fun pointerHeader p =
   constant (WordX.fromIntInf
	     (1 + 2 * Int.toIntInf (PointerTycon.index p),
	      WordSize.default))

fun offset (t: t, {offset, pointerTy, width}): t option =
   let
      fun frag t =
	 fragment (t, {start = Bytes.toBits offset,
		       width = width})
      fun doit t =
	 case dest t of
	    Address t => SOME (frag t)
	  | Pointer p =>
	       if Bytes.equals (offset, Runtime.headerOffset)
		  then SOME (pointerHeader p)
	       else
		  (case pointerTy p of
		      ObjectType.Array _ =>
			 if Bytes.equals (offset, Runtime.arrayLengthOffset)
			    then SOME Type.defaultInt
			 else NONE
		    | ObjectType.Normal t => SOME (frag t)
		    | _ => NONE)
	  | Sum ts =>
	       let
		  val ts' = Vector.keepAllMap (ts, doit)
	       in
		  if Vector.length ts = Vector.length ts'
		     then SOME (sum ts')
		  else NONE
	       end
	  | _ => NONE
   in
      doit t
   end

val offset =
   Trace.trace2
   ("Type.offset",
    layout,
    fn {offset, width, ...} =>
    Layout.record [("offset", Bytes.layout offset),
		   ("width", Bits.layout width)],
    Option.layout layout)
   offset

structure GCField = Runtime.GCField
   
fun ofGCField (f: GCField.t): t =
   let
      datatype z = datatype GCField.t
   in
      case f of
	 CanHandle => defaultWord
       | CardMap => cPointer ()
       | CurrentThread => cPointer ()
       | ExnStack => defaultWord
       | Frontier => cPointer ()
       | Limit => cPointer ()
       | LimitPlusSlop => cPointer ()
       | MaxFrameSize => defaultWord
       | SignalIsPending => bool
       | StackBottom => cPointer ()
       | StackLimit => cPointer ()
       | StackTop => cPointer ()
   end

fun castIsOk _ = true

end
