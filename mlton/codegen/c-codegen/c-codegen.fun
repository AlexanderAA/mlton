(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
functor CCodeGen (S: C_CODEGEN_STRUCTS): C_CODEGEN =
struct

open S

local
   open Machine
in
   structure Block = Block
   structure Cases = Cases
   structure Chunk = Chunk
   structure ChunkLabel = ChunkLabel
   structure FrameInfo = FrameInfo
   structure Global = Global
   structure Kind = Kind
   structure Label = Label
   structure Operand = Operand
   structure Prim = Prim
   structure Register = Register
   structure RuntimeOperand = RuntimeOperand
   structure Statement = Statement
   structure Transfer = Transfer
   structure Type = Type
end

structure Kind =
   struct
      open Kind

      fun isEntry (k: t): bool =
	 case k of
	    Cont _ => true
	  | Func _ => true
	  | Handler _ => true
	  | Runtime _ => true
	  | _ => false
   end

val traceGotoLabel = Trace.trace ("gotoLabel", Label.layout, Unit.layout) 

val wordSize: int = 4
val pointerSize = wordSize
val objectHeaderSize = wordSize
val arrayHeaderSize = 2 * wordSize
val intInfOverhead = arrayHeaderSize + wordSize (* for the sign *)

val overhead = "**C overhead**"
   
structure C =
   struct
      val truee = "TRUE"
      val falsee = "FALSE"

      fun args (ss: string list): string
	 = concat ("(" :: List.separate (ss, ", ") @ [")"])
         
      fun callNoSemi (f: string, xs: string list, print: string -> unit): unit 
	 = (print f
	    ; print "("
	    ; (case xs 
		  of [] => ()
		| x :: xs => (print x
			      ; List.foreach (xs, 
					     fn x => (print ", "; print x))))
	    ; print ")")

      fun call (f, xs, print) =
	 (callNoSemi (f, xs, print)
	  ; print ";\n")

      fun int (n: int): string =
	 if n >= 0
	    then Int.toString n
	 else if n = Int.minInt
		 then "(int)0x80000000" (* because of goofy gcc warning *)
	      else concat ["-", String.dropPrefix (Int.toString n, 1)]

      fun char (c: char) =
	 concat [if Char.ord c >= 0x80 then "(uchar)" else "",
		 "'", Char.escapeC c, "'"]

      fun word (w: Word.t) = "0x" ^ Word.toString w

      (* The only difference between SML floats and C floats is that
       * SML uses "~" while C uses "-".
       *)
      fun float s = String.translate (s, fn #"~" => "-" | c => String.fromChar c)

      fun string s =
	 let val quote = "\""
	 in concat [quote, String.escapeC s, quote]
	 end

      fun bug (s: string, print) =
	 call ("MLton_bug", [concat ["\"", String.escapeC s, "\""]], print)

      local
	 val current = ref ""
      in
	 fun profile (detailed: string, nonDetailed: string,
		      print: string -> unit): unit =
	    if !Control.profile
	       then
		  if detailed <> !current
		     then (print "/* PROFILE: "
			   ; print detailed
			   ; print " & "
			   ; print nonDetailed
			   ; print " */\n"
			   ; current := detailed)
		  else ()
	    else ()
      end 

      fun push (i, print) = call ("\tPush", [int i], print)
   end
structure Label =
   struct
      open Label

      fun toStringIndex l = (toString l) ^ "_index"
   end

structure Operand =
   struct
      open Operand
	 
      val rec toString =
	 fn ArrayOffset {base, index, ty} =>
	       concat ["X", Type.name ty,
		       C.args [toString base, toString index]]
          | CastInt oper => concat ["PointerToInt", C.args [toString oper]]
          | Char c => C.char c
          | Contents {oper, ty} =>
	       concat ["C", Type.name ty, "(", toString oper, ")"]
          | Float s => C.float s
          | Global g => Global.toString g
          | GlobalPointerNonRoot n =>
	       concat ["globalpointerNonRoot [", C.int n, "]"]
          | Int n => C.int n
          | IntInf w =>
	       concat ["SmallIntInf", C.args [concat ["0x", Word.toString w]]]
          | Label l => Label.toStringIndex l
          | Offset {base, offset, ty} =>
	       concat ["O", Type.name ty, C.args [toString base, C.int offset]]
          | Pointer n => concat ["IntAsPointer", C.args [C.int n]]
          | Register r => Register.toString r
	  | Runtime r =>
	       let
		  datatype z = datatype RuntimeOperand.t
		  val ty = (case RuntimeOperand.ty r of
			       RuntimeOperand.Int => "Int"
			     | RuntimeOperand.Word => "Word")
		  val z = 
		     case r of
			Base => "gcState.base"
		      | CanHandle => "gcState.canHandle"
		      | CurrentThread => "gcState.currentThread"
		      | FromSize => "gcState.fromSize"
		      | Frontier => "frontier"
		      | Limit => "gcState.limit"
		      | LimitPlusSlop => "gcState.limitPlusSlop"
		      | MaxFrameSize => "gcState.maxFrameSize"
		      | SignalIsPending => "gcState.signalIsPending"
		      | StackBottom => "gcState.stackBottom"
		      | StackLimit => "gcState.stackLimit"
		      | StackTop => "stackTop"
	       in
		  concat ["((", ty, ")", z, ")"]
	       end
          | StackOffset {offset, ty} =>
	       concat ["S", Type.name ty, "(", C.int offset, ")"]
          | Uint w => C.word w

      val layout = Layout.str o toString
   end

structure Statement =
   struct
      open Statement
 
      fun output (s, print) =
	 case s of
	    Noop => ()
	  | _ =>
	       (print "\t"
		; (case s of
		      Move {dst, src} =>
			 print (concat [Operand.toString dst, " = ",
					Operand.toString src, ";\n"])
		    | Noop => ()
		    | Object {dst, numPointers, numWordsNonPointers, stores} =>
		         (C.call ("Object", [Operand.toString dst,
					     C.int numWordsNonPointers,
					     C.int numPointers],
				  print)
			  ; print "\t"
			  ; (Vector.foreach
			     (stores, fn {offset, value} =>
			      (C.call
			       (concat ["A", Type.name (Operand.ty value)],
				[C.int offset, Operand.toString value], 
				print)
			       ; print "\t")))
			  ; C.call ("EndObject",
				    [C.int
				     (Runtime.objectHeaderSize
				      +
				      Runtime.objectSize
				      {numPointers = numPointers,
				       numWordsNonPointers = numWordsNonPointers})],
				    print))
		    | PrimApp {args, dst, prim} =>
			 let
			    val _ =
			       case dst of
				  NONE => ()
				| SOME dst =>
				     print (concat [Operand.toString dst, " = "])
			   fun doit () =
			      C.call (Prim.toString prim,
				      Vector.toListMap (args, Operand.toString),
				      print)
			   val _ =
			      case Prim.name prim of
				 Prim.Name.FFI s =>
				    (case Prim.numArgs prim of
					NONE => print (concat [s, ";\n"])
				      | SOME _ => doit ())
			       | _ => doit ()
			 in 
			    ()
			 end
		    | SetExnStackLocal {offset} =>
			 C.call ("SetExnStackLocal", [C.int offset], print)
		    | SetExnStackSlot {offset} =>
			 C.call ("SetExnStackSlot", [C.int offset], print)
		    | SetSlotExnStack {offset} =>
			 C.call ("SetSlotExnStack", [C.int offset], print)
			 ))

      fun toString s =
	 let
	    val ss = ref []
	    fun print s = List.push (ss, s)
	    val _ = output (s, print)
	 in concat (rev (!ss))
	 end

      val layout = Layout.str o toString
   end

fun creturn (t: Type.t): string = concat ["CReturn", Type.name t]

fun output {program = Machine.Program.T {chunks,
					 floats,
					 frameOffsets,
					 globals,
					 globalsNonRoot,
					 intInfs,
					 main = {chunkLabel, label},
					 maxFrameSize,
					 strings, ...},
            includes,
	    outputC: unit -> {file: File.t,
			      print: string -> unit,
			      done: unit -> unit}} =
   let
      datatype status = None | One | Many
      val {get = labelInfo: Label.t -> {block: Block.t,
					chunkLabel: ChunkLabel.t,
					frameIndex: int option,
					status: status ref,
					layedOut: bool ref},
	   set = setLabelInfo, ...} =
	 Property.getSetOnce
	 (Label.plist, Property.initRaise ("CCodeGen.info", Label.layout))
      val entryLabels = ref []
      (* Assign the entries of each chunk consecutive integers so that
       * gcc will use a jump table.
       *)
      val indexCounter = Counter.new 0
      val _ =
	 List.foreach
	 (chunks, fn Chunk.T {blocks, chunkLabel, ...} =>
	  Vector.foreach
	  (blocks, fn b as Block.T {kind, label, ...} =>
	   (setLabelInfo
	    (label,
	     {block = b,
	      chunkLabel = chunkLabel,
	      frameIndex = if Kind.isEntry kind
			      then (List.push (entryLabels, label)
				    ; SOME (Counter.next indexCounter))
			   else NONE,
              layedOut = ref false,
	      status = ref None}))))
      val entryLabels = Vector.fromListRev (!entryLabels)
      val maxFrameIndex = Counter.value indexCounter
      val labelChunk = #chunkLabel o labelInfo
      fun labelFrameInfo (l: Label.t): FrameInfo.t option =
	 let
	    val {block = Block.T {kind, ...}, ...} = labelInfo l
	 in
	    Kind.frameInfoOpt kind
	 end
      val {print, done, ...} = outputC ()
      fun outputIncludes () =
	 List.foreach (includes, fn i => (print "#include <";
					  print i;
					  print ">\n\n"))
      fun declareGlobals () =
	 C.call ("Globals",
		 List.map (List.map (let open Type
				     in [char, double, int, pointer, uint]
				     end,
					globals) @ [globalsNonRoot],
			   C.int),
		 print);
      fun declareIntInfs () =
	 (print "BeginIntInfs\n"; 
	  List.foreach (intInfs, 
			fn (g, s) 
			=> (C.callNoSemi ("IntInf",
					  [C.int (Global.index g),
					   C.string s],
					  print)
			    ; print "\n"));
	  print "EndIntInfs\n")
      fun declareStrings () =
	 (print "BeginStrings\n";
	  List.foreach (strings, 
			fn (g, s) 
			=> (C.callNoSemi ("String",
					  [C.int (Global.index g),
					   C.string s,
					   C.int (String.size s)],
					  print);
			    print "\n"));
	  print "EndStrings\n");
      fun declareFloats () =
	 (print "BeginFloats\n";
	  List.foreach (floats, fn (g, f) =>
			(C.callNoSemi ("Float",
				       [C.int (Global.index g),
					C.float f],
				       print);
			 print "\n"));
	  print "EndFloats\n");
      fun declareChunks () =
	 List.foreach (chunks, fn Chunk.T {chunkLabel, ...} =>
		       C.call ("DeclareChunk",
			       [ChunkLabel.toString chunkLabel],
			       print));
      fun make (name, pr) =
	 (print (concat ["static ", name, " = {"])
	  ; Vector.foreachi (entryLabels, fn (i, x) =>
			     (if i > 0 then print ",\n\t" else ()
				 ; pr x))
	  ; print "};\n")
      fun declareNextChunks () =
	 make ("void ( *nextChunks []) ()", fn l =>
	       let
		  val {chunkLabel, frameIndex, ...} = labelInfo l
	       in
		  case frameIndex of
		     NONE => print "NULL"
		   | SOME _ =>
			C.callNoSemi ("Chunkp",
				      [ChunkLabel.toString chunkLabel],
				      print)
	       end)
      fun declareFrameOffsets () =
	 Vector.foreachi
	 (frameOffsets, fn (i, v) =>
	  (print (concat ["static ushort frameOffsets", C.int i, "[] = {"])
	   ; print (C.int (Vector.length v))
	   ; Vector.foreach (v, fn i => (print ","; print (C.int i)))
	   ; print "};\n"))
      fun declareFrameLayouts () =
	 make ("GC_frameLayout frameLayouts []", fn l =>
	       let
		  val (size, offsetIndex) =
		     case labelFrameInfo l of
			NONE => ("0", "NULL")
		      | SOME (FrameInfo.T {size, frameOffsetsIndex}) =>
			   (C.int size, "frameOffsets" ^ C.int frameOffsetsIndex)
	       in 
		  print (concat ["{", size, ",", offsetIndex, "}"])
	       end)
      fun declareIndices () =
	 Vector.foreach
	 (entryLabels, fn l =>
	  Option.app
	  (#frameIndex (labelInfo l), fn i =>
	   (print "#define "
	    ; print (Label.toStringIndex l)
	    ; print " "
	    ; print (C.int i)
	    ; print "\n")))
      fun outputChunk (Chunk.T {chunkLabel, blocks, regMax, ...}) =
	 let
	    fun labelFrameSize (l: Label.t): int =
	       FrameInfo.size (valOf (labelFrameInfo l))
	    (* Count how many times each label is jumped to. *)
	    fun jump l =
	       let
		  val {status, ...} = labelInfo l
	       in
		  case !status of
		     None => status := One
		   | One => status := Many
		   | Many => ()
	       end
	    fun force l = #status (labelInfo l) := Many
	    val _ =
		Vector.foreach
		(blocks, fn Block.T {kind, label, statements, transfer, ...} =>
		 let
		    val _ = if Kind.isEntry kind then jump label else ()
		    datatype z = datatype Transfer.t
		 in
		    case transfer of
		       Arith {overflow, success, ...} =>
			  (jump overflow; jump success)
		     | Bug => ()
		     | CCall _ => ()
		     | Call {label, ...} => jump label
		     | Goto dst => jump dst
		     | Raise => ()
		     | Return _ => ()
		     | Runtime _ => ()
		     | Switch {cases, default, ...} =>
			  (Cases.foreach (cases, jump)
			   ; Option.app (default, jump))
		     | SwitchIP {int, pointer, ...} =>
			  (jump int; jump pointer)
		 end)
	    val tracePrintLabelCode =
	       Trace.trace
	       ("printLabelCode",
		fn {block, layedOut, status: status ref, ...} =>
		Layout.record [("block", Label.layout (Block.label block)),
			       ("layedOut", Bool.layout (!layedOut))],
		Unit.layout)
	    fun maybePrintLabel l =
	       if ! (#layedOut (labelInfo l))
		  then ()
	       else gotoLabel l
	    and gotoLabel arg =
	       traceGotoLabel
	       (fn l =>
		let
		   val info as {layedOut, ...} = labelInfo l
		in
		   if !layedOut 
		      then print (concat ["\tgoto ", Label.toString l, ";\n"])
		   else printLabelCode info
		end) arg
	    and printLabelCode arg =
	       tracePrintLabelCode
	       (fn {block = Block.T {kind, label = l, live,
				     profileInfo as 
				     {ssa as {func = profileInfoFunc, 
					      label = profileInfoLabel}, ...},
				     statements, transfer, ...},
		    layedOut, status, ...} =>
		let
		  val _ = layedOut := true
		  val _ = C.profile (profileInfoFunc, profileInfoFunc, print)
		  val _ =
		     case !status of
			Many =>
			   let
			      val s = Label.toString l
			   in
			      print s
			      ; print ":\n"
			   end 
		      | _ => ()
		  val _ =
		     if 0 = !Control.Native.commented
			then ()
		     else
			print (let open Layout
			       in toString
				  (seq [str "\t/* live: ",
					Vector.layout Operand.layout live,
					str " */\n"])
			       end)
		  val _ =
		     case kind of
			Kind.Cont {frameInfo, ...} =>
			   C.push (~ (FrameInfo.size frameInfo), print)
		      | Kind.CReturn {dst, ...} =>
			   Option.app
			   (dst, fn x =>
			    print (concat ["\t", Operand.toString x, " = ",
					   creturn (Operand.ty x), ";\n"]))
		      | Kind.Func {args} => ()
		      | Kind.Handler {offset} => C.push (~ offset, print)
		      | Kind.Jump => ()
		      | Kind.Runtime {frameInfo, ...} =>
			   C.push (~ (FrameInfo.size frameInfo), print)
		  val _ =
		     Vector.foreach (statements, fn s =>
				     Statement.output (s, print))
		  val _ = outputTransfer (transfer, l)
	       in ()
	       end) arg
	    and outputTransfer (t, source: Label.t) =
	       let
		  fun iff (test, a, b) =
		     (force a
		      ; C.call ("\tBNZ", [test, Label.toString a], print)
		      ; gotoLabel b
		      ; maybePrintLabel a)
		  datatype z = datatype Transfer.t
	       in
		  case t of
		     Arith {prim, args, dst, overflow, success, ...} =>
			let
			   val prim =
			      let
				 datatype z = datatype Prim.Name.t
			      in
				 case Prim.name prim of
				    Int_addCheck => "\tInt_addCheck"
				  | Int_mulCheck => "\tInt_mulCheck"
				  | Int_negCheck => "\tInt_negCheck"
				  | Int_subCheck => "\tInt_subCheck"
				  | Word32_addCheck => "\tWord32_addCheck"
				  | Word32_mulCheck => "\tWord32_mulCheck"  
				  | _ => Error.bug "strange overflow prim"
			      end
			   val _ = force overflow
			in
			   C.call (prim,
				   Operand.toString dst
				   :: (Vector.toListMap (args, Operand.toString)
				       @ [Label.toString overflow]),
				   print)
			   ; gotoLabel success 
			   ; maybePrintLabel overflow
			end
		   | Bug => (print "\t"; C.bug ("machine", print))
		   | CCall {args, prim, return, returnTy} =>
			let
			   val _ = print "\t"
			   val _ =
			      case returnTy of
				 NONE => ()
			       | SOME t => print (concat [creturn t, " = "])
			   fun doit () =
			      C.call (Prim.toString prim,
				      Vector.toListMap (args, Operand.toString),
				      print)
			   val _ =
			      case Prim.name prim of
				 Prim.Name.FFI s =>
				    (case Prim.numArgs prim of
					NONE => print (concat [s, ";\n"])
				      | SOME _ => doit ())
			       | _ => doit ()
			   val _ = gotoLabel return
			in
			   ()
			end
		   | Call {label, return, ...} =>
			let
			   val _ =
			      case return of
				 NONE => ()
			       | SOME {return, handler, size} =>
				    (C.push (size, print)
				     ; (Statement.output
					(Statement.Move
					 {dst = (Operand.StackOffset
						 {offset = ~Runtime.labelSize, 
						  ty = Type.label}),
					  src = Operand.Label return},
					 print)))
			   val dstChunk = labelChunk label
			in
			   if ChunkLabel.equals (labelChunk source, dstChunk)
			      then gotoLabel label
			   else
			      C.call ("\tFarJump", 
				      [ChunkLabel.toString dstChunk, 
				       Label.toStringIndex label],
				      print)
			end
		   | Goto dst => gotoLabel dst
		   | Raise => C.call ("\tRaise", [], print)
		   | Return _ => C.call ("\tReturn", [], print)
		   | Runtime {args, prim, return, ...} =>
			(print "\t"
			 ; C.call (Prim.toString prim,
				   [C.int (labelFrameSize return),
				    Label.toStringIndex return]
				   @ Vector.toListMap (args, Operand.toString),
				   print))
		   | Switch {test, cases, default} =>
			let 
			   val test = Operand.toString test
			   fun bool (t, f) = iff (test, t, f)
			   fun doit (cases, f) =
			      let
				 fun switch (cases, l) =
				    (print "switch ("
				     ; print test
				     ; print ") {\n"
				     ; (List.foreach
					(cases, fn (n, l) => (print "case "
							      ; print (f n)
							      ; print ":\n"
							      ; gotoLabel l)))
				     ; print "default:\n"
				     ; gotoLabel l
				     ; print "}\n")
			      in
				 case (cases,            default) of
				    ([],               NONE) =>
				       Error.bug "switch: empty cases"
				  | ([(_, l)],         NONE)   => gotoLabel l
				  | ([],               SOME l) => gotoLabel l
				  | ((_, l) :: cases', NONE)   => switch (cases', l)
				  | (_,                SOME l) => switch (cases, l)
			      end
			in
			   case cases of
			      Cases.Char l => doit (l, C.char)
			    | Cases.Int l =>
				 (case (l, default) of
				     ([(0, f), (1, t)], NONE) => bool (t, f)
				   | ([(1, t), (0, f)], NONE) => bool (t, f)
				   | _ => doit (l, C.int))
			    | Cases.Word l => doit (l, C.word)
			end
		   | SwitchIP {test, int, pointer} =>
			iff (concat ["IsInt (", Operand.toString test, ")"],
			     int, pointer)
	       end
	    fun profChunkSwitch () =
	       C.profile ("ChunkSwitch (magic)", overhead, print)
	 in
	    C.profile ("Chunk (magic)", overhead, print)
	    ; C.callNoSemi ("Chunk", [ChunkLabel.toString chunkLabel], print)
	    ; print "\n"
	    (* Declare registers. *)
	    ; List.foreach (Type.all, fn ty =>
			    Int.for (0, regMax ty,
				     fn i => C.call (concat ["D", Type.name ty],
						     [C.int i],
						     print)))
	    ; profChunkSwitch ()
	    ; print "ChunkSwitch\n"
	    ; Vector.foreach (blocks, fn Block.T {kind, label, ...} =>
			      if Kind.isEntry kind
				 then (profChunkSwitch ()
				       ; print "case "
				       ; print (Label.toStringIndex label)
				       ; print ":\n"
				       ; gotoLabel label)
			      else ())
	    ; C.profile ("EndChunk (magic)", overhead, print)
	    ; print "EndChunk\n"
	 end
      fun declareMain () =
	 let
	    val stringSizes =
	       List.fold (strings, 0, fn ((_, s), n)  =>
			  n + arrayHeaderSize
			  + Type.align (Type.pointer, String.size s))
	    val intInfSizes =
	       List.fold (intInfs, 
			  0, 
			  fn ((_, s), n) =>
			  n + intInfOverhead
			  + Type.align (Type.pointer, String.size s))
	    val liveSize = intInfSizes + stringSizes
	    val (useFixedHeap, fromSize) =
	       case !Control.fixedHeap of
		  NONE => (C.falsee, 0)
		| SOME n => (* div 2 for semispace *)
		     (if n > 0 andalso liveSize >= n div 2 
			 then Out.output (Out.error,
					  "Warning: heap size used with -h is too small to hold static data.\n")
		      else ();
			 (C.truee, n))
	    val magic = C.word (Random.useed ())
	 in C.profile ("Main (magic)", overhead, print)
	    ; C.callNoSemi ("Main",
			    [useFixedHeap,
			     C.int fromSize,
			     C.int liveSize,
			     C.int maxFrameSize,
			     C.int maxFrameIndex,
			     magic,
			     ChunkLabel.toString chunkLabel,
			     Label.toStringIndex label],
			    print)
	    ; print "\n"
	 end
   in
      print "#define CCODEGEN\n\n"
      ; outputIncludes ()
      ; declareGlobals ()
      ; declareIntInfs ()
      ; declareStrings ()
      ; declareFloats ()
      ; declareChunks ()
      ; declareNextChunks ()
      ; declareFrameOffsets ()
      ; declareFrameLayouts ()
      ; declareIndices ()
      ; List.foreach (chunks, outputChunk)
      ; declareMain ()
      ; done ()
   end

end
