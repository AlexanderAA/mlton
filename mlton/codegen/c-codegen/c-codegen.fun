(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
functor CCodegen (S: C_CODEGEN_STRUCTS): C_CODEGEN =
struct

open S

local
   open Machine
in
   structure Block = Block
   structure Chunk = Chunk
   structure ChunkLabel = ChunkLabel
   structure FrameInfo = FrameInfo
   structure Global = Global
   structure Kind = Kind
   structure Label = Label
   structure ObjectType = ObjectType
   structure Operand = Operand
   structure Prim = Prim
   structure ProfileInfo = ProfileInfo
   structure ProfileLabel = ProfileLabel
   structure Program = Program
   structure Register = Register
   structure Runtime = Runtime
   structure SourceInfo = SourceInfo
   structure Statement = Statement
   structure Switch = Switch
   structure Transfer = Transfer
   structure Type = Type
end

local
   open Runtime
in
   structure CFunction = CFunction
   structure GCField = GCField
end

structure Kind =
   struct
      open Kind

      fun isEntry (k: t): bool =
	 case k of
	    Cont _ => true
	  | CReturn {func, ...} => CFunction.mayGC func
	  | Func => true
	  | Handler _ => true
	  | _ => false
   end

val traceGotoLabel = Trace.trace ("gotoLabel", Label.layout, Unit.layout) 

val overhead = "**C overhead**"
   
structure C =
   struct
      val truee = "TRUE"
      val falsee = "FALSE"

      fun bool b = if b then truee else falsee
	 
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

      (* The only difference between SML reals and C floats/doubles is that
       * SML uses "~" while C uses "-".
       *)
      fun real s = String.translate (s, fn #"~" => "-" | c => String.fromChar c)

      fun string s =
	 let val quote = "\""
	 in concat [quote, String.escapeC s, quote]
	 end

      fun bug (s: string, print) =
	 call ("MLton_bug", [concat ["\"", String.escapeC s, "\""]], print)

      fun push (i, print) =
	 call ("\tPush", [int i], print)

      fun move ({dst, src}, print) =
	 print (concat [dst, " = ", src, ";\n"])
   end

structure Operand =
   struct
      open Operand

      fun isMem (z: t): bool =
	 case z of
	    ArrayOffset _ => true
	  | Cast (z, _) => isMem z
	  | Contents _ => true
	  | Offset _ => true
	  | StackOffset _ => true
	  | _ => false
   end

fun creturn (t: Runtime.Type.t): string =
   concat ["CReturn", Runtime.Type.name t]

fun outputIncludes (includes, print) =
   (List.foreach (includes, fn i => (print "#include <";
				     print i;
				     print ">\n"))
    ; print "\n")

fun declareProfileLabel (l, print) =
   C.call ("DeclareProfileLabel", [ProfileLabel.toString l], print)

fun outputDeclarations
   {additionalMainArgs: string list,
    includes: string list,
    print: string -> unit,
    program = (Program.T
	       {chunks, frameLayouts, frameOffsets, intInfs, maxFrameSize,
		objectTypes, profileInfo, reals, strings, ...}),
    rest: unit -> unit
    }: unit =
   let
      fun declareGlobals () =
	 C.call ("Globals",
		 List.map (List.map (let open Runtime.Type
				     in [char, double, int, pointer, uint]
				     end, 
				     Global.numberOfType)
			   @ [Global.numberOfNonRoot ()],
			   C.int),
		 print)
      fun declareIntInfs () =
	 (print "BeginIntInfs\n"
	  ; List.foreach (intInfs, fn (g, s) =>
			  (C.callNoSemi ("IntInf",
					 [C.int (Global.index g),
					  C.string s],
					 print)
			   ; print "\n"))
	  ; print "EndIntInfs\n")
      fun declareStrings () =
	 (print "BeginStrings\n"
	  ; List.foreach (strings, fn (g, s) =>
			  (C.callNoSemi ("String",
					 [C.int (Global.index g),
					  C.string s,
					  C.int (String.size s)],
					 print)
			   ; print "\n"))
	  ; print "EndStrings\n")
      fun declareReals () =
	 (print "BeginReals\n"
	  ; List.foreach (reals, fn (g, f) =>
			  (C.callNoSemi ("Real",
					 [C.int (Global.index g),
					  C.real f],
					 print)
			   ; print "\n"))
	  ; print "EndReals\n")
      fun declareFrameOffsets () =
	 Vector.foreachi
	 (frameOffsets, fn (i, v) =>
	  (print (concat ["static ushort frameOffsets", C.int i, "[] = {"])
	   ; print (C.int (Vector.length v))
	   ; Vector.foreach (v, fn i => (print ","; print (C.int i)))
	   ; print "};\n"))
      fun declareArray (ty: string,
			name: string,
			v: 'a vector,
			toString: int * 'a -> string) =
	 (print (concat ["static ", ty, " ", name, "[] = {\n"])
	  ; Vector.foreachi (v, fn (i, x) =>
			     print (concat ["\t", toString (i, x), ",\n"]))
	  ; print "};\n")
      fun declareFrameLayouts () =
	 declareArray ("GC_frameLayout", "frameLayouts", frameLayouts,
		       fn (_, {frameOffsetsIndex, isC, size}) =>
		       concat ["{",
			       C.bool isC,
			       ", ", C.int size,
			       ", frameOffsets", C.int frameOffsetsIndex,
			       "}"])
      fun declareObjectTypes () =
	 declareArray
	 ("GC_ObjectType", "objectTypes", objectTypes,
	  fn (_, ty) =>
	  let
	     datatype z = datatype Runtime.ObjectType.t
	     val (tag, nonPointers, pointers) =
		case ObjectType.toRuntime ty of
		   Array {numBytesNonPointers, numPointers} =>
		      (0, numBytesNonPointers, numPointers)
		 | Normal {numPointers, numWordsNonPointers} =>
		      (1, numWordsNonPointers, numPointers)
		 | Stack =>
		      (2, 0, 0)
		 | Weak =>
		      (3, 2, 1)
		 | WeakGone =>
		      (3, 3, 0)
	  in
	     concat ["{ ", C.int tag, ", ",
		     C.int nonPointers, ", ",
		     C.int pointers, " }"]
	  end)
      fun declareMain () =
	 let
	    val align =
	       case !Control.align of
		  Control.Align4 => 4
		| Control.Align8 => 8
	    val magic = C.word (case Random.useed () of
				   NONE => String.hash (!Control.inputFile)
				 | SOME w => w)
	 in 
	    C.callNoSemi ("Main",
			  [C.int align,
			   C.int (!Control.cardSizeLog2),
			   magic,
			   C.int maxFrameSize,
			   C.bool (!Control.mayLoadWorld),
			   C.bool (!Control.markCards),
			   C.bool (!Control.profileStack)]
			  @ additionalMainArgs,
			  print)
	    ; print "\n"
	 end
      fun declareProfileInfo () =
	 let
	    val ProfileInfo.T {frameSources, labels, sourceSeqs,
			       sourceSuccessors, sources, ...} =
	       profileInfo
	 in
	    Vector.foreach (labels, fn {label, ...} =>
			    declareProfileLabel (label, print))
	    ; declareArray ("struct GC_sourceLabel", "sourceLabels", labels,
			    fn (_, {label, sourceSeqsIndex}) =>
			    concat ["{(pointer)", ProfileLabel.toString label,
				    ", ", C.int sourceSeqsIndex, "}"])
	    ; declareArray ("string", "sources", sources,
			    fn (_, si) =>
			    C.string (SourceInfo.toString' (si, "\t")))
	    ; Vector.foreachi (sourceSeqs, fn (i, v) =>
			       (print (concat ["static int sourceSeq",
					       Int.toString i,
					       "[] = {"])
				; print (C.int (Vector.length v))
				; Vector.foreach (v, fn i =>
						  (print (concat [",", C.int i])))
				; print "};\n"))
				      
	    ; declareArray ("uint", "*sourceSeqs", sourceSeqs, fn (i, _) =>
			    concat ["sourceSeq", Int.toString i])
	    ; declareArray ("uint", "frameSources", frameSources, C.int o #2)
	    ; declareArray ("uint", "sourceSuccessors", sourceSuccessors,
			    C.int o #2)
	 end
   in
      outputIncludes (includes, print)
      ; declareGlobals ()
      ; declareIntInfs ()
      ; declareStrings ()
      ; declareReals ()
      ; declareFrameOffsets ()
      ; declareFrameLayouts ()
      ; declareObjectTypes ()
      ; declareProfileInfo ()
      ; rest ()
      ; declareMain ()
   end

structure Type =
   struct
      open Type

      fun toC (t: t): string =
	 case t of
	    Char => "Char"
	  | CPointer => "Pointer"
	  | EnumPointers {pointers, ...} =>
	       if 0 = Vector.length pointers
		  then "Int"
	       else "Pointer"
	  | ExnStack => "Word"
	  | Int => "Int"
	  | IntInf => "Pointer"
	  | Label _ => "Word"
	  | Real => "Double"
	  | Word => "Word"
	  | _ => Error.bug (concat ["Type.toC strange type: ", toString t])
   end

structure Prim =
   struct
      open Prim
      structure Type =
	 struct
	    open Type

	    local
	       val {get: Tycon.t -> string option, set, ...} =
		  Property.getSetOnce (Tycon.plist, Property.initConst NONE)
	       val tycons =
		  [(Tycon.char, "Char"),
		   (Tycon.int, "Int"),
		   (Tycon.intInf, "Pointer"),
		   (Tycon.pointer, "Pointer"),
		   (Tycon.preThread, "Pointer"),
		   (Tycon.real, "Double"),
		   (Tycon.reff, "Pointer"),
		   (Tycon.thread, "Pointer"),
		   (Tycon.tuple, "Pointer"),
		   (Tycon.vector, "Pointer"),
		   (Tycon.weak, "Pointer"),
		   (Tycon.word, "Word32"),
		   (Tycon.word8, "Word8")]
	       val _ =
		  List.foreach (tycons, fn (tycon, s) => set (tycon, SOME s))
	    in
	       fun toC (ty: t): string =
		  case ty of
		     Con (c, _) =>
			(case get c of
			    NONE => Error.bug (concat ["strange tycon: ",
						       Tycon.toString c])
			  | SOME s => s)
		   | _ => Error.bug "strange type"
	    end
	 end
   end
   
fun output {program as Machine.Program.T {chunks,
					  frameLayouts,
					  main = {chunkLabel, label}, ...},
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
      val entryLabels: (Label.t * int) list ref = ref []
      val indexCounter = Counter.new (Vector.length frameLayouts)
      val _ =
	 List.foreach
	 (chunks, fn Chunk.T {blocks, chunkLabel, ...} =>
	  Vector.foreach
	  (blocks, fn b as Block.T {kind, label, ...} =>
	   let
	      fun entry (index: int) =
		 List.push (entryLabels, (label, index))
	      val frameIndex = 
		 case Kind.frameInfoOpt kind of
		    NONE => (if Kind.isEntry kind
				then entry (Counter.next indexCounter)
			     else ()
		             ; NONE)
		  | SOME (FrameInfo.T {frameLayoutsIndex, ...}) =>
		       (entry frameLayoutsIndex
			; SOME frameLayoutsIndex)
	   in
	      setLabelInfo (label, {block = b,
				    chunkLabel = chunkLabel,
				    frameIndex = frameIndex,
				    layedOut = ref false,
				    status = ref None})
	   end))
      val entryLabels =
	 Vector.map
	 (Vector.fromArray
	  (QuickSort.sortArray
	   (Array.fromList (!entryLabels), fn ((_, i), (_, i')) => i <= i')),
	  #1)
      val labelChunk = #chunkLabel o labelInfo
      fun labelFrameInfo (l: Label.t): FrameInfo.t option =
	 let
	    val {block = Block.T {kind, ...}, ...} = labelInfo l
	 in
	    Kind.frameInfoOpt kind
	 end
      val {get = chunkLabelIndex: ChunkLabel.t -> int, ...} =
	 Property.getSet (ChunkLabel.plist,
			  Property.initFun (let
					       val c = Counter.new 0
					    in
					       fn _ => Counter.next c
					    end))
      val chunkLabelToString = C.int o chunkLabelIndex
      fun declareChunk (Chunk.T {chunkLabel, ...}, print) =
	 C.call ("DeclareChunk",
		 [chunkLabelToString chunkLabel],
		 print)
      val {get = labelIndex, set = setLabelIndex, ...} =
	 Property.getSetOnce (Label.plist,
			      Property.initRaise ("index", Label.layout))
      val _ =
	 Vector.foreachi (entryLabels, fn (i, l) => setLabelIndex (l, i))
      fun labelToStringIndex (l: Label.t): string =
	 let
	    val s = C.int (labelIndex l)
	 in
	    if 0 = !Control.Native.commented
	       then s
	    else concat [s, " /* ", Label.toString l, " */"]
	 end
      val handleMisalignedReals =
	 !Control.align = Control.Align4
	 andalso !Control.hostArch = Control.Sparc
      fun addr z = concat ["&(", z, ")"]
      fun realFetch z = concat ["Real_fetch(", addr z, ")"]
      fun realMove {dst, src} =
	 concat ["Real_move(", addr dst, ", ", addr src, ");\n"]
      fun realStore {dst, src} =
	 concat ["Real_store(", addr dst, ", ", src, ");\n"]
      fun move {dst: string, dstIsMem: bool,
		src: string, srcIsMem: bool,
		ty: Type.t}: string =
	 if handleMisalignedReals
	    andalso Type.equals (ty, Type.real)
	    then
	       case (dstIsMem, srcIsMem) of
		  (false, false) => concat [dst, " = ", src, ";\n"]
		| (false, true) => concat [dst, " = ", realFetch src, ";\n"]
		| (true, false) => realStore {dst = dst, src = src}
		| (true, true) => realMove {dst = dst, src = src}
	 else concat [dst, " = ", src, ";\n"]
      local
	 datatype z = datatype Operand.t
      	 fun toString (z: Operand.t): string =
	    case z of
	       ArrayOffset {base, index, ty} =>
		  concat ["X", Type.name ty,
			  C.args [toString base, toString index]]
	     | Cast (z, ty) =>
		  concat ["(", Runtime.Type.toString (Type.toRuntime ty), ")",
			  toString z]
	     | Char c => C.char c
	     | Contents {oper, ty} =>
		  concat ["C", Type.name ty, "(", toString oper, ")"]
	     | File => "__FILE__"
	     | GCState => "GCState"
	     | Global g =>
		  concat ["G", Type.name (Global.ty g),
			  if Global.isRoot g
			     then ""
			  else "NR",
			     "(", Int.toString (Global.index g), ")"]
	     | Int n => C.int n
	     | Label l => labelToStringIndex l
	     | Line => "__LINE__"
	     | Offset {base, offset, ty} =>
		  concat ["O", Type.name ty,
			  C.args [toString base, C.int offset]]
	     | Real s => C.real s
	     | Register r =>
		  concat ["R", Type.name (Register.ty r),
			  "(", Int.toString (Register.index r), ")"]
	     | Runtime _ => Error.bug "C codegen saw Runtime operand"
	     | SmallIntInf w =>
		  concat ["SmallIntInf", C.args [concat ["0x", Word.toString w]]]
	     | StackOffset {offset, ty} =>
		  concat ["S", Type.name ty, "(", C.int offset, ")"]
	     | Word w => C.word w
      in
	 val operandToString = toString
      end
      fun fetchOperand (z: Operand.t): string =
	 if handleMisalignedReals
	    andalso Type.equals (Operand.ty z, Type.real)
	    andalso Operand.isMem z
	    then realFetch (operandToString z)
	 else operandToString z
      fun outputStatement (s, print) =
	 let
	    datatype z = datatype Statement.t
	 in
	    case s of
	       Noop => ()
	     | _ =>
		  (print "\t"
		   ; (case s of
			 Move {dst, src} =>
			    print
			    (move {dst = operandToString dst,
				   dstIsMem = Operand.isMem dst,
				   src = operandToString src,
				   srcIsMem = Operand.isMem src,
				   ty = Operand.ty dst})
		       | Noop => ()
		       | Object {dst, header, size, stores} =>
			    (C.call ("Object", [operandToString dst,
						C.word header],
				     print)
			     ; (Vector.foreach
				(stores, fn {offset, value} =>
				 let
				    val ty = Operand.ty value
				    val dst =
				       concat
				       ["C", Type.name (Operand.ty value),
					"(Frontier + ",
					C.int (offset
					       + Runtime.normalHeaderSize),
					")"]
				 in
				    print "\t"
				    ; (print
				       (move {dst = dst,
					      dstIsMem = true,
					      src = operandToString value,
					      srcIsMem = Operand.isMem value,
					      ty = ty}))
				 end))
			     ; print "\t"
			     ; C.call ("EndObject", [C.int size], print))
		       | PrimApp {args, dst, prim} =>
			    let
			       fun call (): string =
				  concat
				  [Prim.toString prim,
				   "(",
				   concat
				   (List.separate
				    (Vector.toListMap (args, fetchOperand),
				     ", ")),
				   ")"]
			       fun app (): string =
				  case Prim.name prim of
				     Prim.Name.FFI s =>
					(case Prim.numArgs prim of
					    NONE => s
					  | SOME _ => call ())
				   | _ => call ()
			    in
			       case dst of
				  NONE => (print (app ())
					   ; print ";\n")
				| SOME dst =>
				     print (move {dst = operandToString dst,
						  dstIsMem = Operand.isMem dst,
						  src = app (),
						  srcIsMem = false,
						  ty = Operand.ty dst})
			    end
		       | ProfileLabel l =>
			    C.call ("ProfileLabel", [ProfileLabel.toString l],
				    print)
			    ))
	 end
      val profiling = !Control.profile <> Control.ProfileNone
      fun outputChunk (chunk as Chunk.T {chunkLabel, blocks, regMax, ...}) =
	 let
	    val {done, print, ...} = outputC ()
	    fun declareFFI () =
	       let
		  val seen = String.memoize (fn _ => ref false)
		  fun doit (name: string, declare: unit -> string): unit =
		     let
			val r = seen name
		     in
			if !r
			   then ()
			else (r := true; print (declare ()))
		     end
	       in
		  Vector.foreach
		  (blocks, fn Block.T {statements, transfer, ...} =>
		   let
		      val _ =
			 Vector.foreach
			 (statements, fn s =>
			  case s of
			     Statement.PrimApp {prim, ...} =>
				(case Prim.name prim of
				    Prim.Name.FFI name =>
				       doit
				       (name, fn () =>
					let
					   val ty =
					      Prim.Type.toC
					      (Prim.Scheme.ty
					       (Prim.scheme prim))
					in
					   concat
					   ["extern ", ty, " ", name, ";\n"]
					end)
				  | _ => ())
			   | _ => ())
		      val _ =
			 case transfer of
			    Transfer.CCall {args, func, ...} =>
			       let
				  val {name, returnTy, ...} = CFunction.dest func
			       in
				  if name = "Thread_returnToC"
				     then ()
				  else
				  doit
				  (name, fn () =>
				   let
				      val res =
					 case returnTy of
					    NONE => "void"
					  | SOME t => CFunction.Type.toString t
				      val c = Counter.new 0
				      fun arg z =
					 concat [Type.toC (Operand.ty z),
						 " x",
						 Int.toString (Counter.next c)]
				   in
				      (concat
				       [res, " ",
					CFunction.name func,
					" (",
					concat (List.separate
						(Vector.toListMap (args, arg),
						 ", ")),
					");\n"])
				   end)
			       end
			  | _ => ()
		   in
		      ()
		   end)
	       end
	    fun declareChunks () =
	       let
		  val {get, ...} =
		     Property.get (ChunkLabel.plist,
				   Property.initFun (fn _ => ref false))
		  val _ =
		     Vector.foreach
		     (blocks, fn Block.T {transfer, ...} =>
		      case transfer of
			 Transfer.Call {label, ...} =>
			    get (labelChunk label) := true
		       | _ => ())
		  val _ =
		     List.foreach
		     (chunks, fn c as Chunk.T {chunkLabel, ...} =>
		      if ! (get chunkLabel)
			 then declareChunk (c, print)
		      else ())
	       in
		  ()
	       end
	    fun declareProfileLabels () =
	       Vector.foreach
	       (blocks, fn Block.T {statements, ...} =>
		Vector.foreach
		(statements, fn s =>
		 case s of
		    Statement.ProfileLabel l => declareProfileLabel (l, print)
		  | _ => ()))
	    fun labelFrameSize (l: Label.t): int =
	       Program.frameSize (program, valOf (labelFrameInfo l))
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
		     | CCall {func, return, ...} =>
			  if CFunction.maySwitchThreads func
			     then ()
			  else Option.app (return, jump)
		     | Call {label, ...} => jump label
		     | Goto dst => jump dst
		     | Raise => ()
		     | Return => ()
		     | Switch s => Switch.foreachLabel (s, jump)
		 end)
	    fun push (return: Label.t, size: int) =
	       (print "\t"
		; print (move {dst = (operandToString
				      (Operand.StackOffset
				       {offset = size - Runtime.labelSize,
					ty = Type.label return})),
			       dstIsMem = true,
			       src = operandToString (Operand.Label return),
			       srcIsMem = false,
			       ty = Type.Label return})
		; C.push (size, print))
	    fun copyArgs (args: Operand.t vector): string list * (unit -> unit) =
	       if Vector.exists (args,
				 fn Operand.StackOffset _ => true
				  | _ => false)
		  then
		     let
			val _ = print "\t{\n"
			val c = Counter.new 0
			val args =
			   Vector.toListMap
			   (args, fn z =>
			    case z of
			       Operand.StackOffset {ty, ...} =>
				  let
				     val tmp =
					concat ["tmp",
						Int.toString (Counter.next c)]
				     val _ =
					print
					(concat
					 ["\t",
					  Runtime.Type.toString
					  (Type.toRuntime ty),
					  " ", tmp, " = ",
					  fetchOperand z,
					  ";\n"])
				  in
				     tmp
				  end
			     | _ => fetchOperand z)
		     in
			(args, fn () => print "\t}\n")
		     end
	       else (Vector.toListMap (args, fetchOperand),
		     fn () => ())
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
	       (fn {block = Block.T {kind, label = l, live, statements,
				     transfer, ...},
		    layedOut, status, ...} =>
		let
		  val _ = layedOut := true
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
		  fun pop (fi: FrameInfo.t) =
		     C.push (~ (Program.frameSize (program, fi)), print)
		  val _ =
		     case kind of
			Kind.Cont {frameInfo, ...} => pop frameInfo
		      | Kind.CReturn {dst, frameInfo, ...} =>
			   (case frameInfo of
			       NONE => ()
			     | SOME fi => pop (valOf frameInfo)
			    ; (Option.app
			       (dst, fn x =>
				let
				   val ty = Operand.ty x
				in
				   print
				   (concat
				    ["\t",
				     move {dst = operandToString x,
					   dstIsMem = Operand.isMem x,
					   src = creturn (Type.toRuntime ty),
					   srcIsMem = false,
					   ty = ty}])
				end)))
		      | Kind.Func => ()
		      | Kind.Handler {frameInfo, ...} => pop frameInfo
		      | Kind.Jump => ()
		  val _ =
		     if 0 = !Control.Native.commented
			then ()
		     else
			if true
			   then
			      Vector.foreach
			      (live, fn z =>
			       if Type.isPointer (Operand.ty z)
				  then
				     print
				     (concat ["\tCheckPointer(",
					      operandToString z,
					      ");\n"])
			       else ())
			else
			   print (let open Layout
				  in toString
				     (seq [str "\t/* live: ",
					   Vector.layout Operand.layout live,
					   str " */\n"])
				  end)
		  val _ = Vector.foreach (statements, fn s =>
					  outputStatement (s, print))
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
				 fun const i =
				    case Vector.sub (args, i) of
				       Operand.Int _ => true
				     | _ => false
				 fun const0 () = const 0
				 fun const1 () = const 1
			      in
				 case Prim.name prim of
				    Int_addCheck =>
				       if const0 ()
					  then "\tInt_addCheckCX"
				       else if const1 ()
					       then "\tInt_addCheckXC"
					    else "\tInt_addCheck"
				  | Int_mulCheck => "\tInt_mulCheck"
				  | Int_negCheck => "\tInt_negCheck"
				  | Int_subCheck =>
				       if const0 ()
					  then "\tInt_subCheckCX"
				       else if const1 ()
					       then "\tInt_subCheckXC"
					    else "\tInt_subCheck"
				  | Word32_addCheck =>
				       if const0 ()
					  then "\tWord32_addCheckCX"
				       else if const1 ()
					       then "\tWord32_addCheckXC"
					    else "\tWord32_addCheck"
				  | Word32_mulCheck => "\tWord32_mulCheck"  
				  | _ => Error.bug "strange overflow prim"
			      end
			   val _ = force overflow
			in
			   C.call (prim,
				   operandToString dst
				   :: (Vector.toListMap (args, operandToString)
				       @ [Label.toString overflow]),
				   print)
			   ; gotoLabel success 
			   ; maybePrintLabel overflow
			end
		   | CCall {args, frameInfo, func, return} =>
			let
			   val {maySwitchThreads, name, returnTy, ...} =
			      CFunction.dest func
			   val (args, afterCall) =
			      case frameInfo of
				 NONE =>
				    (Vector.toListMap (args, fetchOperand),
				     fn () => ())
			       | SOME frameInfo =>
				    let
				       val size =
					  Program.frameSize (program, frameInfo)
				       val res = copyArgs args
				       val _ = push (valOf return, size)
				    in
				       res
				    end
			   val _ = print "\t"
			   val _ =
			      case returnTy of
				 NONE => ()
			       | SOME t => print (concat [creturn t, " = "])
			   val _ = C.call (name, args, print)
			   val _ = afterCall ()
			   val _ =
			      if maySwitchThreads
				 then print "\tReturn();\n"
			      else Option.app (return, gotoLabel)
			in
			   ()
			end
		   | Call {label, return, ...} =>
			let
			   val dstChunk = labelChunk label
			   val _ =
			      case return of
				 NONE => ()
			       | SOME {return, size, ...} =>
				    push (return, size)
			in
			   if ChunkLabel.equals (labelChunk source, dstChunk)
			      then gotoLabel label
			   else
			      C.call ("\tFarJump", 
				      [chunkLabelToString dstChunk, 
				       labelToStringIndex label],
				      print)
			end
		   | Goto dst => gotoLabel dst
		   | Raise => C.call ("\tRaise", [], print)
		   | Return => C.call ("\tReturn", [], print)
		   | Switch switch =>
			let 
			   fun bool (test: Operand.t, t, f) =
			      iff (operandToString test, t, f)
			   fun doit {cases: (string * Label.t) vector,
				     default: Label.t option,
				     test: Operand.t}: unit =
			      let
				 val test = operandToString test
				 fun switch (cases: (string * Label.t) vector,
					     default: Label.t): unit =
				    (print "switch ("
				     ; print test
				     ; print ") {\n"
				     ; (Vector.foreach
					(cases, fn (n, l) => (print "case "
							      ; print n
							      ; print ":\n"
							      ; gotoLabel l)))
				     ; print "default:\n"
				     ; gotoLabel default
				     ; print "}\n")
			      in
				 case (Vector.length cases, default) of
				    (0, NONE) =>
				       Error.bug "switch: empty cases"
				  | (0, SOME l) => gotoLabel l
				  | (1, NONE) =>
				       gotoLabel (#2 (Vector.sub (cases, 0)))
				  | (_, NONE) =>
				       switch (Vector.dropPrefix (cases, 1),
					       #2 (Vector.sub (cases, 0)))
				  | (_, SOME l) => switch (cases, l)
			      end
			   fun simple ({cases, default, test}, f) =
			      doit {cases = Vector.map (cases, fn (c, l) =>
							(f c, l)),
				    default = default,
				    test = test}
			   datatype z = datatype Switch.t
			in
			   case switch of
			      Char z => simple (z, C.char)
			    | EnumPointers {enum, pointers, test} =>
			      iff (concat
				   ["IsInt (", operandToString test, ")"],
				   enum, pointers)
			    | Int (z as {cases, default, test}) =>
				 let
				    fun normal () = simple (z, C.int)
				 in
				    if 2 = Vector.length cases
				       then
					  let
					     val c0 = Vector.sub (cases, 0)
					     val c1 = Vector.sub (cases, 1)
					  in
					     case (c0, c1, default) of
						((0, f), (1, t), NONE) =>
						   bool (test, t, f)
					      | ((1, t), (0, f), NONE) =>
						   bool (test, t, f)
					      | _ => normal ()
					  end
				    else normal ()
				 end
			    | Pointer {cases, default, tag, ...} =>
				 doit {cases = (Vector.map
						(cases, fn {dst, tag, ...} =>
						 (Int.toString tag, dst))),
				       default = default,
				       test = tag}
			    | Word z => simple (z, C.word)
			end
	       end
	    fun declareRegisters () =
	       List.foreach
	       (Runtime.Type.all, fn t =>
		let
		   val d = concat ["D", Runtime.Type.name t]
		in
		   Int.for (0, 1 + regMax t, fn i =>
			    C.call (d, [C.int i], print))
		end)
	    fun outputOffsets () =
	       List.foreach
	       ([("ExnStackOffset", GCField.ExnStack),
		 ("FrontierOffset", GCField.Frontier),
		 ("StackBottomOffset", GCField.StackBottom),
		 ("StackTopOffset", GCField.StackTop)],
		fn (name, f) =>
		print (concat ["#define ", name, " ",
			       Int.toString (GCField.offset f), "\n"]))
	 in
	    outputOffsets ()
	    ; outputIncludes (["c-chunk.h"], print)
	    ; declareFFI ()
	    ; declareChunks ()
	    ; declareProfileLabels ()
	    ; C.callNoSemi ("Chunk", [chunkLabelToString chunkLabel], print)
	    ; print "\n"
	    ; declareRegisters ()
	    ; C.callNoSemi ("ChunkSwitch", [chunkLabelToString chunkLabel],
			    print)
	    ; print "\n"
	    ; Vector.foreach (blocks, fn Block.T {kind, label, ...} =>
			      if Kind.isEntry kind
				 then (print "case "
				       ; print (labelToStringIndex label)
				       ; print ":\n"
				       ; gotoLabel label)
			      else ())
	    ; print "EndChunk\n"
	    ; done ()
	 end
      val additionalMainArgs =
	 [chunkLabelToString chunkLabel,
	  labelToStringIndex label]
      val {print, done, ...} = outputC ()
      fun rest () =
	 (List.foreach (chunks, fn c => declareChunk (c, print))
	  ; print "struct cont ( *nextChunks []) () = {"
	  ; Vector.foreach (entryLabels, fn l =>
			    let
			       val {chunkLabel, ...} = labelInfo l
			    in
			       print "\t"
			       ; C.callNoSemi ("Chunkp",
					       [chunkLabelToString chunkLabel],
					       print)
			       ; print ",\n"
			    end)
	  ; print "};\n")
      val _ = 
	 outputDeclarations {additionalMainArgs = additionalMainArgs,
			     includes = ["c-main.h"],
			     program = program,
			     print = print,
			     rest = rest}
      val _ = done ()
      val _ = List.foreach (chunks, outputChunk)
   in
      ()
   end

end
