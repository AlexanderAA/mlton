(* Copyright (C) 2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

functor Bytecode (S: BYTECODE_STRUCTS): BYTECODE = 
struct

open S

type int = Int.t

local
   open Machine
in
   structure Block = Block
   structure CFunction = CFunction
   structure Chunk = Chunk
   structure CType = CType
   structure FrameInfo = FrameInfo
   structure Global = Global
   structure Kind = Kind
   structure Label = Label
   structure Live = Live
   structure Operand = Operand
   structure Prim = Prim
   structure Program = Program
   structure Register = Register
   structure Runtime = Runtime
   structure Scale = Scale
   structure StackOffset = StackOffset
   structure Statement = Statement
   structure Switch = Switch
   structure Transfer = Transfer
   structure Type = Type
   structure WordSize = WordSize
   structure WordX = WordX
end

structure Target = CFunction.Target

fun implementsPrim p =
   let
      datatype z = datatype Prim.Name.t
   in
      case Prim.name p of
	 Real_Math_acos _ => false
       | Real_Math_asin _ => false
       | Real_Math_atan _ => false
       | Real_Math_atan2 _ => false
       | Real_Math_cos _ => false
       | Real_Math_exp _ => false
       | Real_Math_ln _ => false
       | Real_Math_log10 _ => false
       | Real_Math_sin _ => false
       | Real_Math_sqrt _ => false
       | Real_Math_tan _ => false
       | Real_ldexp _ => false
       | Real_muladd _ => false
       | Real_mulsub _ => false
       | _ => CCodegen.implementsPrim p
   end

structure Opcode = IntInf

structure CType =
   struct
      open CType

      val memo: (t -> 'a) -> t -> 'a =
	 fn f =>
	 let
	    val m =
	       CType.memo (fn t =>
			   case t of
			      CType.Pointer => NONE
			    | _ => SOME (f t))
	 in
	    CType.memo (fn t =>
			valOf (case t of
				  CType.Pointer => m CType.Word32
				| _ => m t))
	 end

      val toStringOrig = toString
      val toString = memo toString

      val toStringNoInt =
	 memo (fn t =>
	       case t of
		  Int8 => toString Word8
		| Int16 => toString Word16
		| Int32 => toString Word32
		| Int64 => toString Word64
		| _ => toString t)
   end

structure LoadStore =
   struct
      datatype t = Load | Store

      val toString =
	 fn Load => "load"
	  | Store => "store"

      val layout = Layout.str o toString
   end

fun output {program as Program.T {chunks, main, ...}, outputC} =
   let
      datatype z = datatype LoadStore.t
      datatype z = datatype Statement.t
      datatype z = datatype Transfer.t
      (* Build a table of the opcodes. *)
      val table = HashSet.new {hash = #hash}
      val _ =
	 File.withIn
	 (concat [!Control.libDir, "/opcodes"], fn ins =>
	  In.foldLines
	  (ins, 0, fn (l, i) =>
	   case String.tokens (l, Char.isSpace) of
	     [name] =>
		let
		   val hash = String.hash name
		   val _ =
		      HashSet.insertIfNew
		      (table, hash,
		       fn {name = name', ...} => name = name',
		       fn () => {hash = hash,
				 opcode = Int.toIntInf i,
				 name = name},
		       fn _ => Error.bug (concat ["duplicate opcode: ", name]))
		in
		   i + 1
		end
	   | _ => Error.bug "strange opcode file"))
      val opcode: string -> Opcode.t =
	 fn name =>
	 #opcode (HashSet.lookupOrInsert
		  (table, String.hash name,
		   fn {name = name', ...} => name = name',
		   fn () => Error.bug (concat ["missing opcode: ", name, "\n"])))
      val decls = ref []
      val callCounter = Counter.new 0
      val callCs = ref []
      fun callC {function: string,
		 prototype}: string =
	 let
	    val (args, result) = prototype
	    val c = Counter.new 0
	    val args =
	       Vector.map
	       (args, fn cty =>
		let
		   val temp = concat ["t", Int.toString (Counter.next c)]
		   val cty = CType.toStringNoInt cty
		in
		   {declare = concat ["\t", cty, " ",
				      temp, " = PopReg (", cty, ");\n"],
		    temp = temp}
		end)
	    val result =
	       case result of
		  NONE => ""
		| SOME cty =>
		     concat ["PushReg (", CType.toStringNoInt cty, ") = "]
	 in
	    concat
	    ["{\n",
	     concat (Vector.toListMap (args, #declare)),
	     "\tassertRegsEmpty ();\n",
	     "\t", result, function,
	     " (",
	     concat (List.separate (Vector.toListMap (args, #temp), ", ")),
	     ");\n",
	     "\t}\n"]
	 end
      local
	 val calls = HashSet.new {hash = #hash}
      in
	 val () =
	    (* Visit each direct C Call in the program. *)
	    List.foreach
	    (chunks, fn Chunk.T {blocks, ...} =>
	     Vector.foreach
	     (blocks, fn Block.T {statements, transfer, ...} =>
	      (Vector.foreach
	       (statements, fn s =>
		case s of
		   PrimApp {dst, prim, ...} =>
		      (case Prim.name prim of
			  Prim.Name.FFI_Symbol {name, ...} =>
			     Option.app
			     (dst, fn dst =>
			      let
				 val hash = String.hash name
			      in
				 ignore
				 (HashSet.lookupOrInsert
				  (calls, hash,
				   fn {name = n, ...} => n = name,
				   fn () =>
				   let
				      val index = Counter.next callCounter
				      val display =
					 concat
					 ["PushReg (",
					  CType.toString
					  (Type.toCType (Operand.ty dst)),
					  ") = ", name, ";"]
				      val () =
					 List.push
					 (callCs, {display = display,
						   index = index})
				   in
				      {hash = hash,
				       index = index,
				       name = name}
				   end))
			      end)
			| _ => ())
		 | _ => ())
	       ; (case transfer of
		     CCall {func, ...} =>
			let
			   val CFunction.T {prototype, target, ...} = func
			   datatype z = datatype Target.t
			in
			   case target of
			      Direct name =>
				 let
				    val hash = String.hash name
				 in
				    ignore
				    (HashSet.lookupOrInsert
				     (calls, hash,
				      fn {name = n, ...} => n = name,
				      fn () =>
				      let
					 val index = Counter.next callCounter
					 val display =
					    callC {function = name,
						   prototype = prototype}
					 val () =
					    List.push
					    (callCs, {display = display,
						      index = index})
				      in
					 {hash = hash,
					  index = index,
					  name = name}
				      end))
				 end
			    | Indirect => ()
			end
		   | _ => ()))))
	 fun directIndex (name: string) =
	    #index (HashSet.lookupOrInsert
		    (calls, String.hash name,
		     fn {name = n, ...} => n = name,
		     fn () => Error.bug "directIndex"))
	 val ffiSymbolIndex = directIndex
      end
      fun indirectIndex (f: 'a CFunction.t): int =
	 let
	    val index = Counter.next callCounter
	    val function = concat ["( *(", CFunction.cPointerType f, " fptr)) "]
	    val display =
	       concat ["fptr = PopReg (Word32);\n",
		       callC {function = function,
			      prototype = CFunction.prototype f}]
	    val () =
	       List.push (callCs, {display = display,
				   index = index})
	 in
	    index
	 end
      val callC = opcode "CallC"
      val jumpOnOverflow = opcode "JumpOnOverflow"
      val profileLabel = opcode "ProfileLabel"
      val raisee = opcode "Raise"
      val returnOp = opcode "Return"
      datatype z = datatype WordSize.prim
      val switch: WordSize.t -> Opcode.t =
	 let
	    val s8 = opcode "Switch8"
	    val s16 = opcode "Switch16"
	    val s32 = opcode "Switch32"
	    val s64 = opcode "Switch64"
	 in
	    fn w =>
	    case WordSize.prim w of
	       W8 => s8
	     | W16 => s16
	     | W32 => s32
	     | W64 => s64
	 end
      val thread_returnToC = opcode "Thread_returnToC"
      local
	 fun make (name, distinguishPointers: bool)
	    (ls: LoadStore.t, cty: CType.t): Opcode.t =
	    opcode
	    (concat [if distinguishPointers
			then CType.toStringOrig cty
		     else CType.toString cty,
		     "_", LoadStore.toString ls, name])
      in
	 val arrayOffset = make ("ArrayOffset", false)
	 val contents = make ("Contents", false)
   	 val global = make ("Global", true)
	 val offsetOp = make ("Offset", false)
	 val register = make ("Register", true)
	 val stackOffset = make ("StackOffset", false)
	 val wordOpcode = make ("Word", false)
      end
      local
	 fun make name (ls: LoadStore.t): Opcode.t =
	    opcode (concat [LoadStore.toString ls, name])
      in
   	 val frontier = make "Frontier"
	 val gcState = make "GCState"
	 val stackTop = make "StackTop"
      end
      val backpatches: {label: Label.t, offset: int} list ref = ref []
      val code: Word8.t list ref = ref []
      val offset = ref 0
      val emitByte: Word8.t -> unit =
	 fn w =>
	 (List.push (code, w)
	  ; Int.inc offset)
      local
	 fun make (bits: int, {signed}): IntInf.t -> unit =
	    let
	       val bits = Bits.fromInt bits
	    in
	       fn i =>
	       if not (WordSize.isInRange (WordSize.fromBits bits, i,
					   {signed = signed}))
		  then Error.bug (concat ["emitWord", Bits.toString bits,
					  " failed on ", IntInf.toString i])
	       else
		  let
		     fun loop (j, i) =
			if 0 = j
			   then ()
			else
			   let
			      val (q, r) = IntInf.quotRem (i, 0x100)
			      val () = emitByte (Word8.fromIntInf r)
			   in
			      loop (j - 1, q)
			   end
		  in
		     loop (Bytes.toInt (Bits.toBytes bits),
			   IntInf.mod (i, IntInf.<< (1, Bits.toWord bits)))
		  end
	    end
      in
	 val emitWord8 = make (8, {signed = false})
	 val emitWord16 = make (16, {signed = false})
	 val emitWordS16 = make (16, {signed = true})
	 val emitWord32 = make (32, {signed = false})
	 val emitWord64 = make (64, {signed = false})
      end
      val emitWordX: WordX.t -> unit =
	 fn w =>
	 (case WordSize.prim (WordX.size w) of
	     W8 => emitWord8
	   | W16 => emitWord16
	   | W32 => emitWord32
	   | W64 => emitWord64) (WordX.toIntInf w)
      val emitOpcode = emitWord8
      val emitPrim: 'a Prim.t -> unit =
	 fn p => emitOpcode (opcode (Prim.toString p))
      fun emitCallC (index: int): unit =
	 (emitOpcode callC
	  ; emitWord16 (Int.toIntInf index))
      val emitLabel: Label.t -> unit =
	 fn l =>
	 (List.push (backpatches, {label = l, offset = !offset})
	  ; emitWord32 0)
      val emitLabel =
	 Trace.trace ("emitLabel", Label.layout, Unit.layout) emitLabel
      fun emitLoadWord32Zero () =
	 (emitOpcode (wordOpcode (Load, CType.Word32))
	  ; emitWord32 0)
      fun loadStoreStackOffset (offset, cty, ls) =
	 (emitOpcode (stackOffset (ls, cty))
	  ; emitWord16 (Bytes.toIntInf offset))
      val rec emitLoadOperand = fn z => emitOperand (z, Load)
      and emitOperand: Operand.t * LoadStore.t -> unit =
	 fn (z, ls) =>
	 let
	    val cty = Type.toCType (Operand.ty z)
	    datatype z = datatype Operand.t
	 in
	    case z of
	       ArrayOffset {base, index, offset, scale, ...} =>
		  (emitLoadOperand base
		   ; emitLoadOperand index
		   ; emitOpcode (arrayOffset (ls, cty))
		   ; emitWord16 (Bytes.toIntInf offset)
		   ; emitWord8 (Int.toIntInf (Scale.toInt scale)))
	     | Cast (z, _) => emitOperand (z, ls)
	     | Contents {oper, ...} =>
		   (emitLoadOperand oper
		    ; emitOpcode (contents (ls, cty)))
	     | File => emitLoadWord32Zero ()
	     | Frontier => emitOpcode (frontier ls)
	     | GCState => emitOpcode (gcState ls)
	     | Global g =>
		  (emitOpcode (global (ls, cty))
		   ; emitWord16 (Int.toIntInf (Global.index g)))
	     | Label l =>
		  (emitOpcode (wordOpcode (ls, cty))
		   ; emitLabel l)
	     | Line => emitLoadWord32Zero ()
	     | Offset {base, offset = off, ...} =>
		  (emitLoadOperand base
		   ; emitOpcode (offsetOp (ls, cty))
		   ; emitWordS16 (Bytes.toIntInf off))
	     | Real _ => Error.bug "shouldn't see Real operands in bytecode"
	     | Register r =>
		  (emitOpcode (register (ls, cty))
		   ; emitWord16 (Int.toIntInf (Register.index r)))
	     | StackOffset (StackOffset.T {offset, ...}) =>
		  loadStoreStackOffset (offset, cty, ls)
	     | StackTop => emitOpcode (stackTop ls)
	     | Word w =>
		  case ls of
		     Load => (emitOpcode (wordOpcode (ls, cty)); emitWordX w)
		   | Store => Error.bug "can't store to word constant"
	 end
      val emitOperand =
	 Trace.trace2
	 ("emitOperand", Operand.layout, LoadStore.layout, Unit.layout)
	 emitOperand
      fun emitStoreOperand z = emitOperand (z, Store)
      fun move {dst, src} =
	 (emitLoadOperand src
	  ; emitStoreOperand dst)
      fun emitArgs args = Vector.foreach (Vector.rev args, emitLoadOperand)
      fun primApp {args, dst, prim} =
	 case Prim.name prim of
	    Prim.Name.FFI_Symbol {name, ...} =>
	       Option.app
	       (dst, fn dst =>
		(emitCallC (ffiSymbolIndex name)
		 ; emitStoreOperand dst))
	  | _ => 
	       (emitArgs args
		; emitPrim prim
		; Option.app (dst, emitStoreOperand))
      val emitStatement: Statement.t -> unit =
	 fn s =>
	 case s of
	    Move z => move z
	  | Noop => ()
	  | PrimApp z => primApp z
	  | ProfileLabel _ => emitOpcode profileLabel
      val emitStatement =
	 Trace.trace ("emitStatement", Statement.layout, Unit.layout)
	 emitStatement
      local
	 val gotoOp = opcode "Goto"
      in
	 fun goto (l: Label.t): unit =
	    (emitOpcode gotoOp; emitLabel l)
      end
      val pointerSize = WordSize.pointer ()
      fun shiftStackTop (size: Bytes.t) =
	 primApp {args = (Vector.new2
			  (Operand.StackTop,
			   Operand.Word (WordX.fromIntInf
					 (Bytes.toIntInf size,
					  pointerSize)))),
		  dst = SOME Operand.StackTop,
		  prim = Prim.wordAdd pointerSize}
      fun push (label: Label.t, size: Bytes.t): unit =
	 (move {dst = (Operand.StackOffset
		       (StackOffset.T
			{offset = Bytes.- (size, Runtime.labelSize),
			 ty = Type.label label})),
		src = Operand.Label label}
	  ; shiftStackTop size)
      fun pop (size: Bytes.t) = shiftStackTop (Bytes.~ size)
      fun emitTransfer (t: Transfer.t): unit =
	 let
	    datatype z = datatype Transfer.t
	 in
	    case t of
	       Arith {args, dst, overflow, prim, success} =>
		  (emitArgs args
		   ; emitPrim prim
		   ; emitStoreOperand dst
		   ; emitOpcode jumpOnOverflow
		   ; emitLabel overflow
		   ; goto success)
	     | CCall {args, frameInfo, func, return} =>
		  let
		     val () = emitArgs args
		     val CFunction.T {maySwitchThreads, prototype, target, ...} =
			func
		     val () =
			Option.app
			(frameInfo, fn frameInfo =>
			 push (valOf return,
			       Program.frameSize (program, frameInfo)))
		     datatype z = datatype Target.t
		     val () =
			case target of
			   Direct name => emitCallC (directIndex name)
			 | Indirect => emitCallC (indirectIndex func)
		     val () =
			if maySwitchThreads
			   then emitOpcode returnOp
			else Option.app (return, goto)
		  in
		     ()
		  end
	     | Call {label, return, ...} =>
		  (Option.app (return, fn {return, size, ...} =>
			       push (return, size))
		   ; goto label)
	     | Goto l => goto l
	     | Raise => emitOpcode raisee
	     | Return => emitOpcode returnOp
	     | Switch (Switch.T {cases, default, size, test}) =>
		  let
		     val numCases =
			Vector.length cases
			+ (if isSome default then 1 else 0)
			- 1
		     val () =
			(emitLoadOperand test
			 ; emitOpcode (switch size)
			 ; emitWord16 (Int.toIntInf numCases))
		     fun emitCases cases =
			Vector.foreach (cases, fn (w, l) =>
					(emitWordX w; emitLabel l))
		  in
		     case default of
			NONE =>
			   (emitCases (Vector.dropSuffix (cases, 1))
			    ; emitLabel (#2 (Vector.last cases)))
		      | SOME l =>
			   (emitCases cases; emitLabel l)
		  end
	 end
      val emitTransfer =
	 Trace.trace ("emitTransfer", Transfer.layout, Unit.layout)
	 emitTransfer
      val {get = labelOffset: Label.t -> int,
	   set = setLabelOffset, ...} =
	 Property.getSetOnce (Label.plist,
			      Property.initRaise ("offset", Label.layout))
      val () =
	 List.foreach
	 (chunks, fn Chunk.T {blocks, ...} =>
	  Vector.foreach
	  (blocks, fn Block.T {kind, label, statements, transfer, ...} =>
	   let
	      val () =
		 Option.app
		 (Kind.frameInfoOpt kind,
		  fn FrameInfo.T {frameLayoutsIndex} =>
		  ((* This load will never be used.  We just have it there
		    * so the disassembler doesn't get confused when it
		    * sees the frameLayoutsIndex.
		    *)
		   emitOpcode (wordOpcode (Load, CType.Word32))
		   ; emitWord32 (Int.toIntInf frameLayoutsIndex)))
	      val () = setLabelOffset (label, !offset)
	      fun popFrame () =
		 Option.app (Kind.frameInfoOpt kind, fn fi =>
			     pop (Program.frameSize (program, fi)))
	      val () =
		 case kind of
		    Kind.CReturn {dst, func, ...} =>
		       (case #2 (CFunction.prototype func) of
			  NONE => popFrame ()
			| SOME cty => 
			     case dst of
				NONE =>
				   (* Even if there is no dst, we still need to
				    * pop the value returned by the C function.
				    * We write it to a bogus location in the
				    * callee's frame before popping back to the
				    * caller.
				    *)
				   (loadStoreStackOffset (Bytes.zero, cty, Store)
				    ; popFrame ())
			      | SOME z =>
				   (popFrame ()
				    ; emitStoreOperand (Live.toOperand z)))
		  | _ => popFrame ()
	      val () =
		 (Vector.foreach (statements, emitStatement)
		  ; emitTransfer transfer)
	   in
	      ()
	   end))
      val word8ArrayToString: Word8.t array -> string =
	 fn a => String.tabulate (Array.length a, fn i =>
				  Char.fromWord8 (Array.sub (a, i)))
      val code = Array.fromListRev (!code)
      (* Backpatch all label references. *)
      val () =
	 List.foreach
	 (!backpatches, fn {label, offset} =>
	  let
	     fun loop (i, address) =
		if 0 = address
		   then ()
		else (Array.update (code, i,
				    Word8.fromInt (Int.rem (address, 0x100)))
		      ; loop (i + 1, Int.quot (address, 0x100)))
	  in
	     loop (offset, labelOffset label)
	  end)
      val {done, file = _, print} = outputC ()
      val () =
	 CCodegen.outputDeclarations
	 {additionalMainArgs = [Int.toString (labelOffset (#label main))],
          includes = ["bytecode-main.h"],
	  print = print,
	  program = program,
	  rest = fn () => ()}
      val () = done ()
      val {done, print, ...} = outputC ()
      fun declareCallC () =
	  (print "void MLton_callC (int i) {\n"
	   ; print "switch (i) {\n"
	   ; List.foreach (!callCs, fn {display, index} =>
			   (print (concat ["case ", Int.toString index, ":\n\t"])
			    ; print display
			    ; print "break;\n"))
	   ; print "}}\n")
      val () =
	  (print "#include \"bytecode.h\"\n\n"
	   ; List.foreach (chunks, fn c =>
			   CCodegen.declareFFI (c, {print = print}))
	   ; print "\n"
	   ; declareCallC ()
	   ; print "\n")
      val addressNamesSize = ref 0
      val () =
	 (print "static struct AddressName addressNames [] = {\n"
	  ; (List.foreach
	     (chunks, fn Chunk.T {blocks, ...} =>
	      Vector.foreach
	      (blocks, fn Block.T {label, ...} =>
	       (Int.inc addressNamesSize
		; print (concat ["\t{ \"", String.escapeC (Label.toString label),
				 "\", ", Int.toString (labelOffset label),
				 " },\n"])))))
	  ; print "};\n"
	  ; print (concat
		   ["struct Bytecode MLton_bytecode = {\n",
		    "\taddressNames,\n",
		    "\t", Int.toString (!addressNamesSize), ",\n"])
	  ; print "\t\""
	  ; print (String.escapeC (word8ArrayToString code))
	  ; print "\",\n"
	  ; print (concat ["\t", Int.toString (Array.length code), "\n};\n"]))
      val () = done ()
   in
      ()
   end

end
