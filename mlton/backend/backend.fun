(* Copyright (C) 1997-1999 NEC Research Institute.
 * Please see the file LICENSE for license information.
 *)
functor Backend (S: BACKEND_STRUCTS): BACKEND = 
struct

open S

local open Ssa
in
   structure Block = Block
   structure Cases = Cases
   structure Con = Con
   structure Const = Const
   structure Datatype = Datatype
   structure Exp = Exp
   structure Func = Func
   structure Function = Function
   structure Label = Label
   structure Sprogram = Program
   structure Prim = Prim
   structure Statement = Statement
   structure Stransfer = Transfer
   structure Tycon = Tycon
   structure Stype = Type
   structure Var = Var
end 

local open Machine
in
   structure Mcases = Cases
   structure Chunk = Chunk
   structure GCInfo = GCInfo
   structure Kind = Block.Kind
   structure Mlabel = Label
   structure MlimitCheck = LimitCheck
   structure Mtype = Type
   structure Mprogram = Program
   structure Operand = Operand
   structure MPrimInfo = PrimInfo
   structure Register = Register
   structure Mstatement = Statement
   structure Mtransfer = Transfer
   structure MOtransfer = MachineOutput.Transfer
end

val traceGenBlock =
   Trace.trace ("Backend.genBlock", Label.layout o Block.label, Unit.layout)

val traceGenConstBind =
   Trace.trace ("Backend.genConstBind", Statement.layout, Bool.layout)
   
val traceGenFunc =
   Trace.trace ("Backend.genFunc", Func.layout o Function.name, Unit.layout)

nonfix ^
fun ^ r = valOf (!r)

fun id x = x
   
structure Chunkify = Chunkify (open Ssa)

structure ParallelMove = ParallelMove ()

structure Representation = Representation (structure Ssa = Ssa
					   structure Mtype = Mtype)

structure AllocateRegisters = AllocateRegisters (structure Ssa = Ssa
						 structure Machine = Machine)
local open AllocateRegisters
in structure Info = Info
end

local open Representation
in structure TyconRep = TyconRep
   structure ConRep = ConRep
end

structure VarOperand =
   struct
      datatype t =
	 Allocate of {isUsed: bool ref,
		      operand: Operand.t option ref}
       | Const of Operand.t
       | Global of Operand.t
       | Void

      val operandOpt =
	 fn Allocate {operand, ...} => SOME (^operand)
	  | Const oper => SOME oper
	  | Global oper => SOME oper
	  | Void => NONE

      val operand = valOf o operandOpt

      fun layout i =
	 let open Layout
	 in case i of
	    Allocate {isUsed, operand, ...} =>
	       seq [str "Allocate ",
		    record [("isUsed", Bool.layout (!isUsed)),
			    ("operand", Option.layout Operand.layout (!operand))
			    ]]
	  | Const oper => seq [str "Const ", Operand.layout oper]
	  | Global oper => seq [str "Global ", Operand.layout oper]
	  | Void => str "Void "
	 end

      val use =
	 fn Allocate {isUsed, ...} => isUsed := true
	  | _ => ()
   end

fun generate (program as Sprogram.T {datatypes, globals, functions, main})
   : Mprogram.t =
   let
      val {tyconRep, conRep, toMtype} = Representation.compute program
      val _ =
	 Control.diagnostics
	 (fn display =>
	  (display (Layout.str "Representations:")
	   ; (Vector.foreach
	      (datatypes, fn Datatype.T {tycon, cons} =>
	       let open Layout
	       in display (seq [Tycon.layout tycon,
				str " ",
				TyconRep.layout (tyconRep tycon)])
		  ; display (indent
			     (Vector.layout (fn {con, ...} =>
					     seq [Con.layout con,
						  str " ",
						  ConRep.layout (conRep con)])
			      cons,
			      2))
	       end))))
      fun toMtypes ts = Vector.map (ts, toMtype)
      val wordSize = 4
      val labelSize = Mtype.size Mtype.label
      val tagOffset = 0
      val tagType = Mtype.int
      (* Chunk information *)
      val chunks = Chunkify.chunkify program
      val {get = labelChunk, set = setLabelChunk, ...} =
	 Property.getSetOnce (Label.plist,
			      Property.initRaise ("labelChunk", Label.layout))
      val {get = funcChunk: Func.t -> Chunk.t,
	   set = setFuncChunk, ...} =
	 Property.getSetOnce (Func.plist,
			      Property.initRaise ("funcChunk", Func.layout))
      val funcChunkLabel = Chunk.label o funcChunk
      val mprogram = Mprogram.new ()
      (* Create the mprogram chunks. *)
      val machineChunks = ref []
      val _ =
	 Vector.foreach
	 (chunks, fn {funcs, labels} =>
	  let 
	     val c = Mprogram.newChunk mprogram
	     val _ = Vector.foreach (funcs, fn f =>
				     Chunk.addEntry (c, funcToLabel f))
	  in
	     List.push (machineChunks, c)
	     ; Vector.foreach (funcs, fn f => setFuncChunk (f, c))
	     ; Vector.foreach (labels, fn l => setLabelChunk (l, c))
	  end)
      (* The global raise operand. *)
      val raiseGlobal: Operand.t option ref = ref NONE
      fun maybeSetRaiseGlobal (a: (Var.t * Stype.t) vector) =
	 case !raiseGlobal of
	    SOME _ => ()
	  | NONE =>
	       if 1 = Vector.length a
		  then
		     let
			val (_, t) = Vector.sub (a, 0)
			val t = toMtype t
			val oper =
			   if Mtype.isPointer t
			      then
				 Mprogram.newGlobalPointerNonRoot
				 mprogram
			   else
			      Mprogram.newGlobal (mprogram, t)
		     in raiseGlobal := SOME oper
		     end
	       else Error.bug "handler with <> 1 arg"
      fun raiseOperand (): Operand.t =
	 case !raiseGlobal of
	    NONE => Error.bug "raiseGlobal not defined"
	  | SOME z => z
      (* labelInfo, which is only set while processing each function. *)
      val {get = labelInfo: Label.t -> {args: (Var.t * Stype.t) vector,
					cont: Mlabel.t option ref,
					handler: Mlabel.t option ref},
	   set = setLabelInfo, ...} =
	 Property.getSetOnce (Label.plist,
			      Property.initRaise ("label info", Label.layout))
      val labelArgs = #args o labelInfo
      val labelCont = ^  o #cont o labelInfo
      val labelHandler = ^ o #handler o labelInfo
      local
	 fun make f l = isSome (! (f (labelInfo l)))
      in
	 val isCont = make #cont
	 val isHandler = make #handler
      end
      val labelHandler =
	 Trace.trace ("labelHandler", Label.layout, Mlabel.layout) labelHandler
      (* primInfo is defined for primitives that enter the runtime system. *)
      val {get = varInfo: Var.t -> {operand: VarOperand.t,
				    primInfo: MPrimInfo.t ref,
				    ty: Stype.t},
	   set = setVarInfo, ...} =
	 Property.getSetOnce (Var.plist,
			      Property.initRaise ("Backend.info", Var.layout))
      val varInfo =
	 Trace.trace ("Backend.varInfo",
		      Var.layout,
		      fn {operand, primInfo, ...} =>
		      Layout.record [("operand", VarOperand.layout operand),
				     ("primInfo", MPrimInfo.layout (!primInfo))])
	 varInfo
      fun varOptInfo x =
	 case x of
	    NONE => {operand = VarOperand.Void,
		     primInfo = ref MPrimInfo.none,
		     ty = Stype.unit}
	  | SOME x => varInfo x
      fun newVarInfo (x, oper, ty) =
	 setVarInfo (x, {operand = oper,
			 primInfo = ref MPrimInfo.none,
			 ty = ty})
      val newVarInfo =
	 Trace.trace3 ("Backend.newVarInfo",
		       Var.layout, VarOperand.layout, Layout.ignore,
		       Unit.layout)
	 newVarInfo
      val varOperand = #operand o varInfo
      fun varOperands xs = List.map (xs, varOperand)
      val varOperandOpt = VarOperand.operandOpt o varOperand
      val vo = valOf o varOperandOpt
      fun sortTypes (initialOffset: int,
		     tys: Mtype.t vector): {size: int,
					    offsets: int vector,
					    numWordsNonPointers: int,
					    numPointers: int} =
	 let
	    val voids = ref []
	    val bytes = ref []
	    val doubleWords = ref []
	    val words = ref []
	    val pointers = ref []
	    val numPointers = ref 0
	    val _ = Vector.foreachi (tys, fn (i, t) =>
				     List.push
				     (if Mtype.isPointer t
					 then (Int.inc numPointers; pointers)
				      else (case Mtype.size t of
					       0 => voids
					     | 1 => bytes
					     | 4 => words
					     | 8 => doubleWords
					     | _ => Error.bug "strange size"),
					 (i, t)))
	    fun build (r, size, accum) =
	       List.fold (!r, accum, fn ((index, ty), (res, offset)) =>
			  ({index = index, offset = offset, ty = ty} :: res,
			   offset + size))
	    val (accum, offset) =
	       build
	       (voids, 0,
		build (bytes, 1,
		       build (words, 4,
			      build (doubleWords, 8, ([], initialOffset)))))
	    val offset = Mtype.align (Mtype.pointer, offset)
	    val numWordsNonPointers = (offset - initialOffset) div wordSize
	    val (components, size) = build (pointers, 4, (accum, offset))
	    val offsets =
	       Vector.tabulate
	       (Vector.length tys,
		fn i => #offset (List.lookup (components, fn {index, ...} =>
					      i = index)))
	 in {size = size,
	     offsets = offsets,
	     numWordsNonPointers = numWordsNonPointers,
	     numPointers = !numPointers}
	 end
      (* Compute layout for each con and associate it with the con. *)
      local
	 val {get, set, ...} =
	    Property.getSetOnce (Con.plist,
				 Property.initRaise ("con info", Con.layout))
      in
	 val _ =
	    Vector.foreach
	    (datatypes, fn Datatype.T {cons, ...} =>
	     Vector.foreach (cons, fn {con, args} =>
			     let
				fun doit n =
				   let
				      val mtypes = toMtypes args
				      val info = sortTypes (n, mtypes)
				   in set (con, {info = info,
						 mtypes = mtypes})
				   end
			     in case conRep con of
				ConRep.Tuple => doit 0
			      | ConRep.TagTuple _ => doit 4
			      | _ => ()
			     end))
	 val conInfo = get
      end
      (* Compute layout for each tuple type. *)
      local
	 val {get, ...} =
	    Property.get (Stype.plist,
			  Property.initFun
			  (fn t => sortTypes (0, toMtypes (Stype.detuple t))))
      in
	 val tupleInfo = get
	 fun tupleOffset (t: Stype.t, n: int): int =
	    Vector.sub (#offsets (get t), n)
      end
      (* genConstBind returns true iff var is set to a constant operand.
       *)
      fun genConstBind (Statement.T {var, ty, exp}): bool =
	 let
	    fun set' (oper: VarOperand.t): bool =
	       (Option.app (var, fn var => newVarInfo (var, oper, ty))
		; true)
	    fun set oper = set' (VarOperand.Const oper)
	    fun global (new, s) = set (new (mprogram, s))
	    fun bogus () = set' VarOperand.Void
	 in
	    case exp of
	       Exp.ConApp {con, args} =>
		  (case conRep con of
		      ConRep.Void => bogus ()
		    | ConRep.Int n => set (Operand.int n)
		    | ConRep.IntCast n => set (Operand.pointer n)
		    | _ => false)
	     | Exp.Const c =>
		  let
		     datatype z = datatype Const.Node.t
		  in case Const.node c of
		     Char c => set (Operand.char c)
		   | Int n =>
			(Assert.assert
			 ("genConstBind Const", fn () =>
			  Tycon.equals (Const.tycon c, Tycon.int))
			 ; set (Operand.int n))
		   | IntInf i =>
			if Const.SmallIntInf.isSmall i
			   then
			      set (Operand.intInf
				   (Const.SmallIntInf.toWord i))
			else global (Mprogram.newIntInf,
				     IntInf.format (i, StringCvt.DEC))
		   | Real f => if !Control.Native.native
				  then global (Mprogram.newFloat, f)
			       else set (Operand.float f)
		   | String s => global (Mprogram.newString, s)
		   | Word w =>
			set
			(let val t = Const.tycon c
			 in if Tycon.equals (t, Tycon.word)
			       then Operand.uint w
			    else if Tycon.equals (t, Tycon.word8)
				    then (Operand.char
					  (Char.chr (Word.toInt w)))
				 else Error.bug "strange word"
			 end)
		  end
	     | Exp.PrimApp {prim, ...} =>
		  (case Prim.name prim of
		      Prim.Name.MLton_bogus =>
			 set (case Mtype.dest (toMtype ty) of
				 Mtype.Char => Operand.char #"\000"
			       (*				  | Mtype.Double => Operand.float "0.0" *)
			       | Mtype.Int => Operand.int 0

			       | Mtype.Uint => Operand.uint 0w0
			       | Mtype.Pointer => Operand.pointer 1
			       | _ => Error.bug "bogus not implemented for type")
		    | _ => false)
	     | Exp.Select _ => Mtype.isVoid (toMtype ty) andalso bogus ()
	     | Exp.Tuple xs =>
		  if 0 = Vector.length xs
		     then bogus ()
		  else false
	     | Exp.Var x =>
		  (case #operand (varInfo x) of
		      VarOperand.Const oper => set oper
		    | _ => false)
	     | _ => false
	 end
      val genConstBind = traceGenConstBind genConstBind
      val use = VarOperand.use o #operand o varInfo
      val use = Trace.trace ("Backend.use", Var.layout, Unit.layout) use
      val _ =
	 Vector.foreach
	 (globals, fn s as Statement.T {var, ty, exp} =>
	  (Exp.foreachVar (exp, use)
	   ; if genConstBind s
		then ()
	     else
		Option.app
		(var, fn var =>
		 case exp of
		    Exp.Var x => setVarInfo (var, varInfo x)
		  | _ =>
		       newVarInfo
		       (var,
			let val m = toMtype ty
			in if Mtype.isVoid m
			      then VarOperand.Void
			   else VarOperand.Global (Mprogram.newGlobal
						   (mprogram, m))
			end,
			ty))))
      local
	 val varInfo =
	    fn x =>
	    let val {operand, primInfo, ty, ...} = varInfo x
	    in {operand = (case operand of
			      VarOperand.Allocate {isUsed, operand, ...} =>
				 if !isUsed
				    then SOME operand
				 else NONE
			    | _ => NONE),
		primInfo = primInfo,
		ty = toMtype ty}
	    end
      in
	 val allocateFunc =
	    AllocateRegisters.allocate {funcChunk = funcChunk,
					isCont = isCont,
					isHandler = isHandler,
					labelChunk = labelChunk,
					labelToLabel = labelToLabel,
					program = program,
					varInfo = varInfo}
	 val allocateFunc = 
	    Trace.trace
	    ("Backend.allocateFunc", Func.layout o Function.name, Layout.ignore)
	    allocateFunc
      end
      fun parallelMove {srcs, dsts, chunk} =
	 let
	    val moves =
	       List.fold2 (srcs, dsts, [],
			   fn (src, dst, ac) => {src = src, dst = dst} :: ac)
	    fun temp r =
	       Operand.register (Chunk.tempRegister (chunk, Operand.ty r))
	 (* 	     val temp =
	  * 		Trace.trace ("temp", Operand.layout, Operand.layout) temp
	  *)
	 in
	    (* 	     Trace.trace
	     * 	     ("parallelMove",
	     * 	      fn {moves, ...} =>
	     * 	      List.layout (fn {src, dst} =>
	     * 			   Layout.tuple
	     * 			   [Operand.layout src, Operand.layout dst])
	     * 	      moves,
	     * 	      Layout.ignore)
	     *)
	    ParallelMove.move {
			       equals = Operand.equals,
			       move = Mstatement.move,
			       moves = moves,
			       interfere = Operand.interfere,
			       temp = temp
			       }
	 end
      fun conSelects (variant: Operand.t, con: Con.t): Operand.t vector =
	 let
	    val _ = Assert.assert ("conSelects", fn () =>
				   case conRep con of
				      ConRep.TagTuple _ => true
				    | ConRep.Tuple => true
				    | _ => false)
	    val {info = {offsets, ...}, mtypes} = conInfo con
	 in Vector.map2 (offsets, mtypes, fn (i, t) =>
			 Operand.offset {base = variant, offset = i, ty = t})
	 end
      val conSelects =
	 Trace.trace2 ("Backend.conSelects",
		       Operand.layout, Con.layout,
		       Vector.layout Operand.layout)
	 conSelects
      fun genStatement (Statement.T {var, ty, exp},
			chunk: Chunk.t,
			handlerOffset): Mstatement.t list =
	 let
	    val {operand, primInfo, ty, ...} = varOptInfo var
	    fun sideEffectFree () = not (Exp.maySideEffect exp)
	 in if (case operand of
		   VarOperand.Allocate {isUsed, ...} =>
		      not (!isUsed) andalso sideEffectFree ()
		 | VarOperand.Const _ => true
		 | VarOperand.Global _ => false
		 | VarOperand.Void => sideEffectFree ())
	       then []
	    else
	       let
		  fun xop () =
		     case operand of
			VarOperand.Allocate {operand, ...} => ^operand
		      | VarOperand.Global z => z
		      | _ => Error.bug "xop"
		  fun move src = [Mstatement.move {dst = xop (), src = src}]
		  fun makeStores (ys: Var.t vector, offsets) =
		     Vector.fold2 (ys, offsets, [], fn (y, offset, stores) =>
				   case varOperandOpt y of
				      NONE => stores
				    | SOME value => 
					 {offset = offset, value = value}
					 :: stores)
		  fun allocate (ys: Var.t vector,
				{size, offsets,
				 numPointers, numWordsNonPointers}) =
		     [Mstatement.allocate
		      {dst = xop (),
		       size = size,
		       numPointers = numPointers,
		       numWordsNonPointers = numWordsNonPointers,
		       stores = makeStores (ys, offsets)}]
		  fun allocateTagged (n: int,
				      ys: Var.t vector,
				      {size, offsets,
				       numPointers, numWordsNonPointers}) =
		     [Mstatement.allocate
		      {dst = xop (),
		       size = size,
		       numPointers = numPointers,
		       numWordsNonPointers =
		       (* for the tag *) 1 + numWordsNonPointers,
		       stores = ({offset = tagOffset, value = Operand.int n}
				 :: makeStores (ys, offsets))}]
		  datatype z = datatype Exp.t
	       in case exp of
		  ConApp {con, args} =>
		     let 
			fun tuple () = allocate (args, #info (conInfo con))
		     in case conRep con of
			ConRep.Transparent _ =>
			   move (vo (Vector.sub (args, 0)))
		      | ConRep.Tuple => tuple ()
		      | ConRep.TagTuple n =>
			   allocateTagged (n, args, #info (conInfo con))
		      | _ => Error.bug "strange ConApp"
		     end
		| PrimApp {prim, targs, args, ...} =>
		     let
			fun a i = Vector.sub (args, i)
			fun offset (a, i, ty) =
			   Operand.arrayOffset {base = a,
						offset = i,
						ty = ty}
			fun unsafeSub (ty: Mtype.t) =
			   move (offset (vo (a 0), vo (a 1), ty))
			fun array (n: Operand.t, t: Mtype.t): Mstatement.t list =
			   let
			      val (nbnp, np) =
				 if Mtype.isPointer t
				    then (0, 1)
				 else (Mtype.size t, 0)
			      val gcInfo = MPrimInfo.deRuntime (!primInfo)
			   in [Mstatement.allocateArray
			       {dst = xop (),
				numElts = n,
				numBytesNonPointers = nbnp,
				numPointers = np,
				gcInfo = gcInfo}]
			   end
			fun normal () =
			   let
			      val pinfo = !primInfo
			      val dst =
				 let datatype z = datatype VarOperand.t
				 in case operand of
				    Allocate {isUsed, operand, ...} =>
				       if !isUsed
					  then SOME (^operand)
				       else NONE
				  | Const oper => SOME oper
				  | Global oper => SOME oper
				  | Void => NONE
				 end
			   in
			      [Mstatement.assign
			       {dst = dst,
				oper = prim,
				args = Vector.map (args, vo),
				pinfo = pinfo}]
			   end
			fun targ () = toMtype (Vector.sub (targs, 0))
			datatype z = datatype Prim.Name.t
		     in case Prim.name prim of
			Array_array => array (vo (a 0), targ ())
		      | Array_sub => unsafeSub (targ ())
		      | Array_update =>
			   let
			      val t = targ ()
			   in case Mtype.dest t of
			      Mtype.Void => []
			    | _ => [Mstatement.move
				    {dst = offset (vo (a 0), vo (a 1), t),
				     src = vo (a 2)}]
			   end
		      | MLton_eq =>
			   if Mtype.isVoid (targ ())
			      then [Mstatement.move {dst = xop (),
						     src = Operand.int 1}]
			   else normal ()
		      | Ref_assign =>
			   let
			      val t = targ ()
			   in case Mtype.dest t of
			      Mtype.Void => []
			    | _ => [Mstatement.move
				    {dst = Operand.contents (vo (a 0), t),
				     src = vo (a 1)}]
			   end
		      | Ref_deref =>
			   let
			      val t = targ ()
			   in case Mtype.dest t of
			      Mtype.Void => []
			    | _ => move (Operand.contents (vo (a 0), t))
			   end
		      | Ref_ref =>
			   let
			      val t = targ ()
			      val (ys, ts) = if Mtype.isVoid t
						then (Vector.new0 (),
						      Vector.new0 ())
					     else (Vector.new1 (a 0),
						   Vector.new1 t)
			   in allocate (ys, sortTypes (0, ts))
			   end
		      | String_sub => unsafeSub Mtype.char
		      | Vector_fromArray => move (vo (a 0))
		      | Vector_sub => unsafeSub (targ ())
		      | _ => normal ()
		     end
		| Select {tuple, offset} =>
		     let val {operand, ty = ty', ...} = varInfo tuple
		     in move (Operand.offset
			      {base = VarOperand.operand operand,
			       offset = tupleOffset (ty', offset),
			       ty = toMtype ty})
		     end
		| SetExnStackLocal =>
		     [Mstatement.setExnStackLocal {offset = valOf handlerOffset}]
		| SetExnStackSlot =>
		     [Mstatement.setExnStackSlot {offset = valOf handlerOffset}]
		| SetHandler h =>
		     [Mstatement.move
		      {dst = Operand.stackOffset {offset = valOf handlerOffset,
						  ty = Mtype.label},
		       src = Operand.label (labelHandler h)}]
		| SetSlotExnStack =>
		     [Mstatement.setSlotExnStack {offset = valOf handlerOffset}]
		| Tuple ys => allocate (ys, tupleInfo ty)
		| Var y => move (vo y)
		| _ => Error.bug "genStatement saw strange primExp"
	       end
	 end
      val genStatement =
	 Trace.trace ("Backend.genStatement",
		      Statement.layout o #1,
		      List.layout Mstatement.layout)
	 genStatement
      fun genStatements (ss: Statement.t vector,
			 chunk: Chunk.t,
			 handlerOffset): Mstatement.t list =
	 List.concat
	 (Vector.toListMap (ss, fn s =>
			    genStatement (s, chunk, handlerOffset)))
      (* Build the initGlobals chunk. *)
      val initGlobals = Mlabel.newString "initGlobals"
      val chunk = Mprogram.newChunk mprogram
      val _ = Chunk.addEntry (chunk, initGlobals)
      val initGlobalsStatements =
	 Mstatement.limitCheck
	 (MlimitCheck.Maybe
	  (GCInfo.make {live = [],
			frameSize = Mtype.size Mtype.label}))
	 ::
	 List.fold
	 (Vector.fold (globals, [], fn (s, statements) =>
		      (genStatement (s, chunk, NONE) :: statements)),
	  [], op @)
      val _ =
	 Mprogram.setMain (mprogram, {chunkLabel = Chunk.label chunk, 
				      label = initGlobals})
      val _ =
	 Chunk.newBlock
	 (chunk, {label = initGlobals,
		  kind = Kind.func {args = []},
		  live = [],
		  profileName = "initGlobals",
		  statements = initGlobalsStatements,
		  transfer = Mtransfer.farJump {chunkLabel = funcChunkLabel main,
					        label = funcToLabel main,
						live = [],
						return = NONE}})
      fun setVarInfo (x, ty) =
	 newVarInfo (x,
		     if Mtype.isVoid (toMtype ty)
			then VarOperand.Void
		     else VarOperand.Allocate {isUsed = ref false,
					       operand = ref NONE},
		     ty)
      fun setVarInfos xts = Vector.foreach (xts, setVarInfo)
      fun genFunc (f: Function.t): unit =
	 let
	    val {args, blocks, name, start, ...} = Function.dest f
	    val _ =
	       Control.diagnostic
	       (fn () =>
		let
		   open Layout
		in
		   seq [str "Generating code for function", Func.layout name]
		end)
	    val _ = setVarInfos args
	    val profileName = Func.toString name
	    val chunk = funcChunk name
	    (* Set the var infos. *)
	    val _ =
	       Tree.foreachPre
	       (Function.dominatorTree f,
		fn Block.T {args, statements, transfer, ...} =>
		let
		   val _ = setVarInfos args
		   val _ =
		      Vector.foreach
		      (statements, fn s as Statement.T {var, ty, exp, ...} =>
		       (Exp.foreachVar (exp, use)
			; if genConstBind s
			     then ()
			  else Option.app (var, fn var =>
					   setVarInfo (var, ty))))
		   val _ = Stransfer.foreachVar (transfer, use)
		in
		   ()
		end)
	    (* Create info for labels used as conts. *)
	    fun new (r, l) =
	       case !r of
		  SOME _ => ()
		| NONE =>
		     let
			val c = labelChunk l
			val l = Mlabel.new (labelToLabel l)
			val _ = r := SOME l
			val _ = Chunk.addEntry (c, l)
		     in
			()
		     end
	    val _ =
	       Vector.foreach
	       (blocks, fn Block.T {label, args, ...} =>
		(setLabelInfo (label, {args = args,
				       cont = ref NONE,
				       handler = ref NONE})))
	    val _ =
	       Vector.foreach
	       (blocks, fn Block.T {statements, transfer, ...} =>
		(Vector.foreach
		 (statements, fn Statement.T {exp, ...} =>
		  case exp of
		     Exp.SetHandler h =>
			let
			   val {args, handler, ...} = labelInfo h
			   val _ = maybeSetRaiseGlobal args
			in
			   new (handler, h)
			end
		   | _ => ())
		 ; (case transfer of
		       Stransfer.Call {return, ...} =>
			  Option.app (return, fn {cont, ...} =>
				      new (#cont (labelInfo cont), cont))
		     | _ => ())))
	    val {handlerOffset, labelInfo = labelRegInfo, limitCheck, ...} =
	       allocateFunc f
	    local
	       fun make sel (l: Label.t) =
		  let val Info.T r = labelRegInfo l
		  in sel r
		  end
	    in
	       val labelLive = make #live
	       val labelLiveNoFormals = make #liveNoFormals
	    end
	    fun tail' (to: Label.t, srcs: 'a vector, srcOp: 'a -> Operand.t)
	       : Mstatement.t list * Mtransfer.t * bool =
	       let
		  val t = Mtransfer.nearJump {label = labelToLabel to,
					      return = NONE}
	       in
		  if Vector.isEmpty srcs
		     then ([], t, false)
		  else
		     let
			val {args, ...} = labelInfo to
			val (srcs, dsts) =
			   Vector.fold2
			   (srcs, args, ([], []),
			    fn (src, (x, _), ac as (srcs, dsts)) =>
			    let
			       val {operand, ...} = varInfo x
			    in
			       case operand of
				  VarOperand.Allocate
				  {isUsed = ref true, operand, ...} =>
				     (srcOp src :: srcs, ^operand :: dsts)
				| _ => ac
			    end)
		     in
			(parallelMove {srcs = srcs,
				       dsts = dsts,
				       chunk = labelChunk to},
			 t,
			 length srcs > 0)
		     end
	       end
	    val tail =
	       Trace.trace ("Backend.tail",
			    Label.layout o #1,
			    fn (s, t, _) =>
			    Layout.tuple [List.layout Mstatement.layout s,
					  Mtransfer.layout t])
	       tail'
	    fun tail (to: Label.t, srcs: 'a vector, srcOp: 'a -> Operand.t) =
	       let val (s, t, _) = tail' (to, srcs, srcOp)
	       in (s, t)
	       end
	    (* ------------------------------------------------- *)
	    (*                      genCase                      *)
	    (* ------------------------------------------------- *)
	    fun genCase {chunk: Chunk.t,
			 profileName: string,
			 test: Var.t,
			 testRep: TyconRep.t,
			 cases: (Con.t * Label.t) vector,
			 default: Label.t option} =
	       let
		  fun addTest (os: Operand.t list): Operand.t list =
		     case varOperand test of
			VarOperand.Allocate {operand, ...} => (^operand) :: os
		      | _ => os
		  (* Creating this new block without limit checks is OK because
		   * all it does is a few moves and then a transfer.  I.E. it
		   * does no allocations and can not trigger a GC.
		   *)
		  fun newBlock (live, statements, transfer): Mlabel.t =
		     let
			val l = Mlabel.newNoname ()
			val _ =
			   Chunk.newBlock (chunk,
					   {label = l,
					    kind = Kind.jump,
					    profileName = profileName,
					    live = live,
					    statements = statements,
					    transfer = transfer})
		     in
			l
		     end
		  fun switch {test = test', cases, default, live, numLeft}
		     : {live: Operand.t list, transfer: Mtransfer.t} =
		     let
			datatype z = None | One of Mlabel.t | Many
			val (live, default) =
			   if numLeft = 0
			      then (live, NONE)
			   else
			      case default of
				 NONE => (live, NONE)
			       | SOME j => (labelLive j @ live,
					    SOME (labelToLabel j))
			val targets =
			   Mcases.fold
			   (cases,
			    case default of
			       SOME l => One l
			     | NONE => None,
				  fn (l, Many) => Many
				   | (l, One l') => if Mlabel.equals (l, l')
						       then One l'
						    else Many
				   | (l, None) => One l)
			val (live, transfer) =
			   case targets of
			      None => Error.bug "no targets"
			    | One l =>
				 (live,
				  Mtransfer.nearJump {label = l,
						      return = NONE})
			    | Many =>
				 (addTest live,
				  Mtransfer.switch {test = test',
						    cases = cases,
						    default = default})
		     in {live = live, 
			 transfer = transfer}
		     end
		  fun enum (test: Operand.t, numEnum: int) =
		     let
			val (live, cases, numLeft) =
			   Vector.fold
			   (cases, ([], [], numEnum),
			    fn ((c, j), (os, cases, numLeft)) =>
			    let
			       fun keep n =
				  (labelLiveNoFormals j @ os,
				   (n, labelToLabel j) :: cases,
				   numLeft - 1)
			    in
			       case conRep c of
				  ConRep.Int n => keep n
				| ConRep.IntCast n => keep n
				| _ => (os, cases, numLeft)
			    end)
		     in switch {test = test,
				cases = Mcases.Int cases, default = default,
				live = live, numLeft = numLeft}
		     end
		  fun transferToLabel {live, transfer}: Mlabel.t =
		     case Mtransfer.toMOut transfer of
			MOtransfer.NearJump {label, ...} => label
		      | _ => newBlock (live, [], transfer)
		  fun switchIP (numEnum, pointer: Mlabel.t): Mtransfer.t =
		     let
			val test = vo test
			val int =
			   transferToLabel
			   (enum (Operand.castInt test, numEnum))
		     in Mtransfer.switchIP {test = test,
					    int = int,
					    pointer = pointer}
		     end
		  fun doTail (j: Label.t, args: Operand.t vector)
		     : Operand.t list * Mlabel.t =
		     let
			val (s, t, testIsUsed) = tail' (j, args, fn a => a)
		     in
			case (s, Mtransfer.toMOut t) of
			   ([], MOtransfer.NearJump {label, ...}) =>
			      (labelLive j, label)
			 | _ => let
				   val live = labelLiveNoFormals j
				   val live = if testIsUsed
						 then addTest live
					      else live
				in (live, newBlock (live, s, t))
				end
		     end
		  fun enumAndOne (numEnum: int): Mtransfer.t =
		     let
			val test = vo test
			val z =
			   Vector.loop
			   (cases,
			    fn (c, j) =>
			    case conRep c of
			       ConRep.Transparent _ => SOME (j, Vector.new1 test)
			     | ConRep.Tuple => SOME (j, conSelects (test, c))
			     | _ => NONE,
				  fn () =>
				  case default of
				     NONE => Error.bug "enumAndOne: no default"
				   | SOME j => (j, Vector.new0 ()))
		     in switchIP (numEnum, #2 (doTail z))
		     end
		  fun indirectTag (numTag: int) =
		     let
			val test = vo test
			val (live, cases, numLeft) =
			   Vector.fold
			   (cases, ([], [], numTag),
			    fn ((c, j), (live, cases, numLeft)) =>
			    case conRep c of
			       ConRep.TagTuple n =>
				  let
				     val (live', l) =
					doTail (j, conSelects (test, c))
				  in (live' @ live, (n, l) :: cases, numLeft - 1)
				  end
			     | _ => (live, cases, numLeft))
		     in switch {test = Operand.offset {base = test,
						       offset = tagOffset,
						       ty = tagType},
				cases = Mcases.Int cases, default = default,
				live = live, numLeft = numLeft}
		     end
	       in case testRep of
		  TyconRep.Prim mtype =>
		     (case (Vector.length cases, default) of
			 (1, _) =>
			    (* We use _ instead of NONE for the default becuase
			     * there may be an unreachable default case.
			     *)
			    let
			       val (c, l) = Vector.sub (cases, 0)
			    in case conRep c of
			       ConRep.Void => tail (l, Vector.new0 (), id)
			     | ConRep.Transparent _ =>
				  tail (l, Vector.new1 test, vo)
			     | ConRep.Tuple =>
				  tail (l, conSelects (vo test, c), id)
			     | _ => Error.bug "strange conRep for Prim"
			    end
		       | (0, SOME j) => tail (j, Vector.new0 (), id)
		       | _ => Error.bug "prim datatype with more than one case")
		| TyconRep.Enum {numEnum} =>
		     ([], #transfer (enum (vo test, numEnum)))
		| TyconRep.EnumDirect {numEnum} => ([], enumAndOne numEnum)
		| TyconRep.EnumIndirect {numEnum} => ([], enumAndOne numEnum)
		| TyconRep.EnumIndirectTag {numEnum, numTag} =>
		     ([], switchIP (numEnum,
				    transferToLabel (indirectTag numTag)))
		| TyconRep.IndirectTag {numTag} =>
		     ([], #transfer (indirectTag numTag))
	       end
	    fun varsRegs (xs: Var.t list): Register.t list =
	       List.fold (xs, [], fn (x, rs) =>
			  case varOperandOpt x of
			     NONE => rs
			   | SOME oper => 
				case Operand.deRegister oper of
				   NONE => rs
				 | SOME r => r :: rs)
	    (* ------------------------------------------------- *)
	    (*                      genCont                      *)
	    (* ------------------------------------------------- *)
	    fun genCont (c: Chunk.t,
			 l: Mlabel.t,
			 j: Label.t,
			 args: (Var.t * Stype.t) vector,
			 profileName: string): unit =
	       let
		  val Info.T {liveFrame, liveNoFormals, cont, ...} =
		     labelRegInfo j
		  val size =
		     case cont of
			SOME {size, ...} => size
		      | NONE => Error.bug "no cont"
		  (* Need liveFrame
		   * because some vars might be live down a handler
		   * that handles raises from the function returning here.
		   *)
		  val _ = Mprogram.newFrame (mprogram,
					     {return = l,
					      chunkLabel = Chunk.label c,
					      size = size,
					      live = liveFrame})

		  val (args, (argsl, offset)) =
		     Vector.mapAndFold
		     (args, ([], 4),
		      fn ((var, ty), (argsl, offset)) =>
		      let
			 val ty = toMtype ty
			 val offset = Mtype.align (ty, offset)
			 val calleeOffset = offset + size
			 val arg = Operand.stackOffset {offset = calleeOffset,
							ty = ty}
			 val isUsed
			    = case varInfo var
			    of {operand = VarOperand.Allocate {isUsed, ...}, ...} 
			       => !isUsed
			     | _ => false
		      in (arg,
			  (if isUsed
			      then arg::argsl
			   else argsl,
			      offset + Mtype.size ty))
		      end)
		  val (statements, transfer) = tail (j, args, id)
		  val limitCheck =
		     MlimitCheck.Maybe (GCInfo.make 
					{frameSize = size + offset,
					 live = argsl @ liveNoFormals})
		  val statements =
		     Mstatement.limitCheck limitCheck
		     :: statements
		  val chunk = labelChunk j
		  val _ =
		     Chunk.newBlock
		     (chunk, {label = l,
			      kind = Kind.cont {args = argsl,
						size = size},
			      live = liveNoFormals,
			      profileName = profileName,
			      statements = statements,
			      transfer = transfer})
	       in ()
	       end
	    (* ------------------------------------------------- *)
	    (*                    genHandler                     *)
	    (* ------------------------------------------------- *)
	    fun genHandler (c: Chunk.t,
			    l: Mlabel.t,
			    j: Label.t,
			    profileName: string): unit =
	       let
		  val _ = Mprogram.newHandler (mprogram, 
					       {chunkLabel = Chunk.label c,
						label = l})
		  val Info.T {liveNoFormals, handler, ...} = labelRegInfo j
		  val size
		     = case handler
		     of SOME {size, ...} => size
		   | NONE => Error.bug "no handler"
		  val args = Vector.new1 (raiseOperand ())
		  val (statements, transfer) = tail (j, args, id)
	       in Chunk.newBlock (labelChunk j,
				  {label = l,
				   kind = Kind.handler {size = size},
				   live = liveNoFormals,
				   profileName = profileName,
				   statements = statements,
				   transfer = transfer})
	       end
	    (* ------------------------------------------------- *)
	    (*                    genTransfer                    *)
	    (* ------------------------------------------------- *)
	    fun genTransfer (t: Stransfer.t,
			     chunk: Chunk.t,
			     profileName: string,
			     handlerOffset: int option)
	       : Mstatement.t list * Mtransfer.t =
	       case t of
		  Stransfer.Bug => ([], Mtransfer.bug)
		| Stransfer.Call {func, args, return} =>
		     let
			val args = Vector.toList args
			val offsets =
			   rev (#2 (List.fold
				    (args, (4, []), (* 4 is for return address *)
				     fn (arg, (offset, offsets)) =>
				     case varOperandOpt arg of
					NONE => (offset, offset :: offsets)
				      | SOME oper =>
					   let val ty = Operand.ty oper
					      val offset = Mtype.align (ty, offset)
					   in (offset + Mtype.size ty,
					       offset :: offsets)
					   end)))
			val (frameSize, return, handlerLive) =
			   case return of
			      NONE => (0, NONE, [])
			    | SOME {cont, handler} =>
				 let
				    val return = labelCont cont
				    val Info.T {cont, ...} = labelRegInfo cont
				    val size =
				       case cont of
					  SOME {size, ...} => size
					| NONE => Error.bug "no cont"
				    val (handler, handlerLive) =
				       case handler of
					  NONE => (NONE, [])
					| SOME h =>
					     let
						val handlerOffset =
						   valOf handlerOffset
					     in
						(SOME (labelHandler h),
						 (Operand.stackOffset 
						  {offset = handlerOffset,
						   ty = Mtype.uint})::
						 (Operand.stackOffset 
						  {offset = handlerOffset + 
						   labelSize,
						   ty = Mtype.uint})::
						 nil)
					     end
				 in
				    (size, 
				     SOME {return = return,
					   handler = handler,
					   size = size},
				     handlerLive)
				 end
			val (live, setupArgs) =
			   let
			      val (live,moves) =
				 List.fold2
				 (args, offsets, (handlerLive,[]), 
				  fn (arg, offset, (live, ac)) =>
				  case varOperandOpt arg of
				     NONE => (live, ac)
				   | SOME oper =>
					let
					   val so = Operand.stackOffset
					      {offset = frameSize + offset,
					       ty = Operand.ty oper}
					in
					   (so::live,
					    {src = oper,
					     dst = so}::ac)
					end)
			      fun temp r =
				 Operand.register
				 (Chunk.tempRegister (chunk, Operand.ty r))
			   in
			      (live,
			       ParallelMove.move {equals = Operand.equals,
						  move = Mstatement.move,
						  moves = moves,
						  interfere = Operand.interfere,
						  temp = temp})
			   end
			val chunk' = funcChunk func
			val transfer =
			   if !Control.Native.native
			      orelse (not (Chunk.equals (chunk, chunk')))
			      then
				 Mtransfer.farJump
				 {chunkLabel = Chunk.label chunk',
				  label = funcToLabel func,
				  live = live,
				  return = return}
			   else 
			      Mtransfer.nearJump 
			      {label = funcToLabel func,
			       return = return}
		     in (setupArgs, transfer)
		     end
		| Stransfer.Case {test, cases, default, ...} =>
		     let
			fun id x = x
			fun doit (l, f, branch) =
			   ([],
			    Mtransfer.switch
			    {test = vo test,
			     cases = f (Vector.toListMap
					(l, fn (i, j) =>
					 (branch i, labelToLabel j))),
			     default = Option.map (default, labelToLabel)})
		     in case cases of
			Cases.Char l => doit (l, Mcases.Char, id)
		      | Cases.Int l => doit (l, Mcases.Int, id)
		      | Cases.Word l => doit (l, Mcases.Word, id)
		      | Cases.Word8 l => doit (l, Mcases.Char, Word8.toChar)
		      | Cases.Con cases =>
			   (case (Vector.length cases, default) of
			       (0, NONE) => ([], Mtransfer.bug)
			     | _ => 
				  let
				     val (tycon, tys) =
					Stype.tyconArgs (#ty (varInfo test))
				  in
				     if Vector.isEmpty tys
					then genCase {cases = cases,
						      chunk = chunk,
						      default = default,
						      profileName = profileName,
						      test = test,
						      testRep = tyconRep tycon}
				     else Error.bug "strange type in case"
				  end)
		     end
		| Stransfer.Goto {dst, args} => tail (dst, args, vo)
		| Stransfer.Prim {prim, args, failure, success} =>
		     let
			val temp =
			   Operand.register
			   (Chunk.tempRegister (chunk, Mtype.int))
			val noOverflowLabel = Mlabel.newNoname ()
			val live = labelLiveNoFormals success
			val (live, statements) =
			   let
			      val {operand, ...} =
				 varInfo (#1 (Vector.sub
					      (#args (labelInfo success), 0)))
			   in
			      case operand of
				 VarOperand.Allocate {isUsed, operand, ...} =>
				    if !isUsed
				       then
					  (temp :: live,
					   [Mstatement.move {dst = ^operand,
							     src = temp}])
				    else (live, [])
			       | _ => (live, [])
			   end
			val _ =
			   Chunk.newBlock
			   (chunk,
			    {label = noOverflowLabel,
			     kind = Kind.jump,
			     live = live,
			     profileName = profileName,
			     statements = statements,
			     transfer = (Mtransfer.nearJump
					 {label = labelToLabel success,
					  return = NONE})})
		     in
			([],
			 Mtransfer.overflow
			 {args = Vector.map (args, vo),
			  dst = temp,
			  failure = labelToLabel failure,
			  prim = prim,
			  success = noOverflowLabel})
		     end
		| Stransfer.Raise xs =>
		     (Mstatement.moves {dsts = [raiseOperand ()],
					srcs = Vector.toListMap (xs, vo)},
		      Mtransfer.raisee)
		| Stransfer.Return xs =>
		     let
			val (_, live, moves) =
			   Vector.fold
			   (xs, (4, [], []), fn (x, (offset, live, moves)) =>
			    case varOperandOpt x of
			       NONE => (offset, live, moves)
			     | SOME x =>
				  let 
				     val ty = Operand.ty x
				     val offset = Mtype.align (ty, offset)
				     val so =
					Operand.stackOffset {offset = offset, 
							     ty = ty}
				  in 
				     (offset + Mtype.size ty,
				      so::live,
				      {src = x,
				       dst = so}
				      :: moves)
				  end)
			fun temp r =
			   Operand.register
			   (Chunk.tempRegister (chunk, Operand.ty r))
		     in
			(ParallelMove.move {equals = Operand.equals,
					    move = Mstatement.move,
					    moves = moves,
					    interfere = Operand.interfere,
					    temp = temp},
			 Mtransfer.return {live = live})
		     end
	    val genTransfer =
	       Trace.trace ("Backend.genTransfer",
			    Stransfer.layout o #1,
			    Layout.tuple2 (List.layout Mstatement.layout,
					   Mtransfer.layout))
	       genTransfer
	    val live = Info.live (labelRegInfo start)
	    val _ =
	       Chunk.newBlock
	       (chunk,
		{label = funcToLabel name,
		 kind = Kind.func {args = live},
		 live = live,
		 profileName = profileName,
		 statements = [Mstatement.limitCheck limitCheck],
		 transfer = (Mtransfer.nearJump
			     {label = labelToLabel start,
			      return = NONE})})
	    fun genBlock (Block.T {label, args, statements, transfer, ...}) =
	       let
		  val _ =
		     Control.diagnostic
		     (fn () =>
		      let
			 open Layout
		      in
			 seq [str "Generating code for block ",
			      Label.layout label]
		      end)
		  val Info.T {limitCheck, live, ...} = labelRegInfo label
		  val {cont, handler, ...} = labelInfo label
		  val chunk = labelChunk label
		  val _ =
		     Option.app (!cont, fn l =>
				 genCont (chunk, l, label, args, profileName))
		  val _ =
		     Option.app (!handler, fn l =>
				 genHandler (chunk, l, label, profileName))
		  val statements = 
		     genStatements (statements, chunk, handlerOffset)
		  val (preTransfer, transfer) =
		     genTransfer (transfer, chunk, profileName, handlerOffset)
		  val statements =
		     Mstatement.limitCheck limitCheck
		     :: (statements @ preTransfer)
	       in
		  Chunk.newBlock (chunk, {label = labelToLabel label,
					  kind = Kind.jump,
					  live = live,
					  profileName = profileName,
					  statements = statements,
					  transfer = transfer})
	       end
	    val genBlock = traceGenBlock genBlock
	    val _ = Vector.foreach (blocks, genBlock)
	    val _ = Vector.foreach (blocks, Block.clear)
	 in
	    ()
	 end
      val genFunc = traceGenFunc genFunc
      val _ = List.foreach (functions, genFunc)
      (* The Mprogram.clear is necessary because Funcs and Labels are turned into
       * Labels in the resulting mprogram, and properties have been attached to
       * them by the backend.
       *)
      val _ = Mprogram.clear mprogram
   in
      mprogram
   end

end
