functor Profile (S: PROFILE_STRUCTS): PROFILE = 
struct

open S
open Rssa

type sourceSeq = int list

structure InfoNode =
   struct
      datatype t = T of {info: SourceInfo.t,
			 nameIndex: int,
			 sourcesIndex: int,
			 successors: t list ref}

      local
	 fun make f (T r) = f r
      in
	 val info = make #info
	 val sourcesIndex = make #sourcesIndex
      end

      fun layout (T {info, ...}) =
	 Layout.record [("info", SourceInfo.layout info)]

      fun equals (n: t, n': t): bool = SourceInfo.equals (info n, info n')

      fun call {from = T {successors, ...},
		to as T {info = i', ...}} =
	 if let
	       open SourceInfo
	    in
	       equals (i', gc)
	       orelse equals (i', main)
	       orelse equals (i', unknown)
	    end orelse List.exists (!successors, fn n => equals (n, to))
	    then ()
	 else List.push (successors, to)

      val call =
	 Trace.trace ("InfoNode.call",
		      fn {from, to} =>
		      Layout.record [("from", layout from),
				     ("to", layout to)],
		      Unit.layout)
	 call
   end

structure FuncInfo =
   struct
      datatype t = T of {callers: InfoNode.t list ref,
			 enters: InfoNode.t list ref,
			 seen: bool ref,
			 tailCalls: t list ref}

      fun new () = T {callers = ref [],
		      enters = ref [],
		      seen = ref false,
		      tailCalls = ref []}
   end

structure Push =
   struct
      datatype t =
	 Enter of InfoNode.t
       | Skip of SourceInfo.t

      fun layout z =
	 let
	    open Layout
	 in
	    case z of
	       Enter n => seq [str "Enter ", InfoNode.layout n]
	     | Skip i => seq [str "Skip ", SourceInfo.layout i]
	 end

      fun toSources (ps: t list): int list =
	 List.fold (rev ps, [], fn (p, ac) =>
		    case p of
		       Enter (InfoNode.T {sourcesIndex, ...}) =>
			  sourcesIndex :: ac
		     | Skip _ => ac)
   end

fun profile program =
   if !Control.profile = Control.ProfileNone
      then (program, fn _ => NONE)
   else
   let
      val Program.T {functions, handlesSignals, main, objectTypes} = program
      val debug = false
      val profile = !Control.profile
      val profileAlloc: bool = profile = Control.ProfileAlloc
      val profileStack: bool = !Control.profileStack
      val profileTime: bool = profile = Control.ProfileTime
      val frameProfileIndices: (Label.t * int) list ref = ref []
      val infoNodes: InfoNode.t list ref = ref []
      val nameCounter = Counter.new 0
      val names: string list ref = ref []
      local
	 val sourceCounter = Counter.new 0
	 val {get = nameIndex, ...} =
	    Property.get (SourceInfo.plist,
			  Property.initFun
			  (fn si =>
			   (List.push (names, SourceInfo.toString' (si, "\t"))
			    ; Counter.next nameCounter)))
      in	 
	 fun sourceInfoNode (si: SourceInfo.t) =
	    let
	       val infoNode =
		  InfoNode.T {info = si,
			      nameIndex = nameIndex si,
			      sourcesIndex = Counter.next sourceCounter,
			      successors = ref []}
	       val _ = List.push (infoNodes, infoNode)
	    in
	       infoNode
	    end
      end
      fun firstEnter (ps: Push.t list): InfoNode.t option =
	 List.peekMap (ps, fn p =>
		       case p of
			  Push.Enter n => SOME n
			| _ => NONE)
      (* unknown must be 0, which == SOURCES_INDEX_UNKNOWN from gc.h *)
      val unknownInfoNode = sourceInfoNode SourceInfo.unknown
      (* gc must be 1 which == SOURCES_INDEX_GC from gc.h *)
      val gcInfoNode = sourceInfoNode SourceInfo.gc
      val mainInfoNode = sourceInfoNode SourceInfo.main
      val sourceInfoNode =
	 fn si =>
	 let
	    open SourceInfo
	 in
	    if equals (si, unknown)
	       then unknownInfoNode
	    else if equals (si, gc)
		    then gcInfoNode
		 else if equals (si, main)
			 then mainInfoNode
		      else sourceInfoNode si
	 end
      local
	 val table: {hash: word,
		     index: int,
		     sourceSeq: int vector} HashSet.t =
	    HashSet.new {hash = #hash}
	 val c = Counter.new 0
	 val sourceSeqs: int vector list ref = ref []
      in
	 fun sourceSeqIndex (s: sourceSeq): int =
	    let
	       val s = Vector.fromListRev s
	       val hash =
		  Vector.fold (s, 0w0, fn (i, w) =>
			       w * 0w31 + Word.fromInt i)
	    in
	       #index
	       (HashSet.lookupOrInsert
		(table, hash,
		 fn {sourceSeq = s', ...} => s = s',
		 fn () => let
			     val _ = List.push (sourceSeqs, s)
			  in
			     {hash = hash,
			      index = Counter.next c,
			      sourceSeq = s}
			  end))
	    end
	 fun makeSourceSeqs () = Vector.fromListRev (!sourceSeqs)
      end
      (* Ensure that [SourceInfo.unknown] is index 0. *)
      val _ = sourceSeqIndex [InfoNode.sourcesIndex unknownInfoNode]
      (* Ensure that [SourceInfo.gc] is index 1. *)
      val _ = sourceSeqIndex [InfoNode.sourcesIndex gcInfoNode]
      fun addFrameProfileIndex (label: Label.t,
				index: int): unit =
	 List.push (frameProfileIndices, (label, index))
      fun addFrameProfilePushes (label: Label.t,
				 pushes: Push.t list): unit =
	 addFrameProfileIndex (label,
			       sourceSeqIndex (Push.toSources pushes))
      val {get = labelInfo: Label.t -> {block: Block.t,
					visited: bool ref},
	   set = setLabelInfo, ...} =
	 Property.getSetOnce
	 (Label.plist, Property.initRaise ("info", Label.layout))
      val labels = ref []
      fun profileLabelIndex (sourceSeqsIndex: int): Statement.t =
	 let
	    val l = ProfileLabel.new ()
	    val _ = List.push (labels, {label = l,
					sourceSeqsIndex = sourceSeqsIndex})
	 in
	    Statement.ProfileLabel l
	 end
      fun profileLabel (sourceSeq: int list): Statement.t =
	 profileLabelIndex (sourceSeqIndex sourceSeq)
      local
	 val {get: Func.t -> FuncInfo.t, ...} =
	    Property.get (Func.plist, Property.initFun (fn _ => FuncInfo.new ()))
      in
	 val funcInfo = get
	 fun addFuncEdges () =
	    (* Don't need to add edges for main because no one calls it. *)
	    List.foreach
	    (functions, fn f =>
	     let
		val allSeen: bool ref list ref = ref []
		val func = Function.name f
		val fi as FuncInfo.T {callers, ...} = get func
		(* Add edges from all the callers to the enters in f and all
		 * functions that f tail calls.
		 *)
		fun call (FuncInfo.T {enters, seen, tailCalls, ...}): unit =
		   if !seen
		      then ()
		   else
		      let
			 val _ = seen := true
			 val _ = List.push (allSeen, seen)
			 val _ = 
			    List.foreach
			    (!callers, fn from =>
			     List.foreach
			     (!enters, fn to =>
			      InfoNode.call {from = from, to = to}))
		      in
			 List.foreach (!tailCalls, call)
		      end
		val _ = call fi
		val _ = List.foreach (!allSeen, fn r => r := false)
	     in
		()
	     end)
      end
      fun doFunction (f: Function.t): Function.t =
	 let
	    val {args, blocks, name, raises, returns, start} = Function.dest f
	    val FuncInfo.T {enters, tailCalls, ...} = funcInfo name
	    fun enter (ps: Push.t list, si: SourceInfo.t): Push.t list * bool =
	       let
		  val node = Promise.lazy (fn () => sourceInfoNode si)
		  fun yes () = (Push.Enter (node ()) :: ps, true)
		  fun no () = (Push.Skip si :: ps, false)
	       in
		  if SourceInfo.equals (si, SourceInfo.unknown)
		     then no ()
		  else
		     case firstEnter ps of
			NONE =>
			   (List.push (enters, node ())
			    ; yes ())
		      | SOME (node' as InfoNode.T {info = si', ...}) =>
			   if let
				 open SourceInfo
			      in
				 not (!Control.profileBasis)
				 andalso not (equals (si', unknown))
				 andalso
				 (equals (si, gcArrayAllocate)
				  orelse isBasis si
				  orelse (isC si
					  andalso (isBasis si'
						   orelse equals (si', main))))
			      end
			      then no ()
			   else (InfoNode.call {from = node', to = node ()}
				 ; yes ())
	       end
	    val enter =
	       Trace.trace2 ("Profile.enter",
			     List.layout Push.layout,
			     SourceInfo.layout,
			     Layout.tuple2 (List.layout Push.layout,
					    Bool.layout))
	       enter
	    val _ =
	       Vector.foreach
	       (blocks, fn block as Block.T {label, ...} =>
		setLabelInfo (label, {block = block,
				      visited = ref false}))
	    (* Find the first Enter statement and (conceptually) move it to the
	     * front of the function.
	     *)
	    local
	       exception Yes of Label.t * SourceInfo.t
	       fun goto l =
		  let
		     val {block, ...} = labelInfo l
		     val Block.T {statements, transfer, ...} = block
		     val _ =
			Vector.foreach
			(statements, fn s =>
			 case s of
			    Statement.Profile (ProfileExp.Enter si) =>
			       raise Yes (l, si)
			  | _ => ())
		     val _ = Transfer.foreachLabel (transfer, goto)
		  in
		     ()
		  end
	    in
	       val (firstLabel, firstSource) =
		  (goto start
		   ; (Label.bogus, SourceInfo.unknown))
		  handle Yes z => z
	    end
	    val blocks = ref []
	    datatype z = datatype Statement.t
	    datatype z = datatype ProfileExp.t
	    fun backward {args,
			  kind,
			  label,
			  leaves,
			  sourceSeq: int list,
			  statements: Statement.t list,
			  transfer: Transfer.t}: unit =
	       let
		  val (_, npl, sourceSeq, statements) =
		     List.fold
		     (statements,
		      (leaves, true, sourceSeq, []),
		      fn (s, (leaves, npl, sourceSeq, ss)) =>
		      case s of
			 Object _ => (leaves, true, sourceSeq, s :: ss)
		       | Profile ps =>
			    let
			       val (npl, ss) =
				  if profileAlloc
				     then (false, ss)
				  else (* profileTime *)
				     if npl andalso not (List.isEmpty sourceSeq)
					then (false,
					      profileLabel sourceSeq :: ss)
				     else (true, ss)
			       val (leaves, sourceSeq) = 
				  case ps of
				     Enter _ =>
					(case sourceSeq of
					    [] => Error.bug "unmatched Enter"
					  | _ :: sis => (leaves, sis))
				   | Leave _ =>
					(case leaves of
					    [] => Error.bug "missing Leave"
					  | infoNode :: leaves =>
					       (leaves,
						InfoNode.sourcesIndex infoNode
						:: sourceSeq))
			    in
			       (leaves, npl, sourceSeq, ss)
			    end
		       | _ => (leaves, true, sourceSeq, s :: ss))
		  val statements =
		     if profileTime andalso npl
			then profileLabel sourceSeq :: statements
		     else statements
		  val {args, kind, label} =
		     if profileStack andalso (case kind of
						 Kind.Cont _ => true
					       | Kind.Handler => true
					       | _ => false)
			then
			   let
			      val func = CFunction.profileLeave
			      val newLabel = Label.newNoname ()
			      val _ =
				 addFrameProfileIndex
				 (newLabel, sourceSeqIndex sourceSeq)
			      val statements =
				 if profileTime
				    then (Vector.new1
					  (profileLabelIndex
					   (sourceSeqIndex sourceSeq)))
				 else Vector.new0 ()
			      val _ =
				 List.push
				 (blocks,
				  Block.T
				  {args = args,
				   kind = kind,
				   label = label,
				   statements = statements,
				   transfer = 
				   Transfer.CCall
				   {args = Vector.new1 Operand.GCState,
				    func = func,
				    return = SOME newLabel}})
			   in
			      {args = Vector.new0 (),
			       kind = Kind.CReturn {func = func},
			       label = newLabel}
			   end
		     else {args = args,
			   kind = kind,
			   label = label}
	       in		       
		  List.push (blocks,
			     Block.T {args = args,
				      kind = kind,
				      label = label,
				      statements = Vector.fromList statements,
				      transfer = transfer})
	       end
	    val backward =
	       Trace.trace
	       ("Profile.backward",
		fn {statements, sourceSeq, ...} =>
		Layout.tuple [List.layout Int.layout sourceSeq,
			      List.layout Statement.layout statements],
		Unit.layout)
	       backward
	    fun profileEnter (pushes: Push.t list,
			      transfer: Transfer.t): Transfer.t =
	       let
		  val func = CFunction.profileEnter
		  val newLabel = Label.newNoname ()
		  val index = sourceSeqIndex (Push.toSources pushes)
		  val _ = addFrameProfileIndex (newLabel, index)
		  val statements =
		     if profileTime
			then Vector.new1 (profileLabelIndex index)
		     else Vector.new0 ()
		  val _ =
		     List.push
		     (blocks,
		      Block.T {args = Vector.new0 (),
			       kind = Kind.CReturn {func = func},
			       label = newLabel,
			       statements = statements,
			       transfer = transfer})
	       in
		  Transfer.CCall {args = Vector.new1 Operand.GCState,
				  func = func,
				  return = SOME newLabel}
	       end
	    fun goto (l: Label.t, pushes: Push.t list): unit =
	       let
		  val _ =
		     if not debug
			then ()
		     else
		     let
			open Layout
		     in
			outputl (seq [str "goto (",
				      Label.layout l,
				      str ", ",
				      List.layout Push.layout pushes,
				      str ")"],
				 Out.error)
		     end
		  val {block, visited, ...} = labelInfo l
	       in
		  if !visited
		     then ()
		  else
		     let
			val _ = visited := true
			val Block.T {args, kind, label, statements, transfer,
				     ...} = block
			val statements =
			   if Label.equals (label, firstLabel)
			      then
				 Vector.removeFirst
				 (statements, fn s =>
				  case s of
				     Profile (Enter _) => true
				   | _ => false)
			   else statements
			val _ =
			   let
			      fun add pushes =
				 addFrameProfilePushes (label, pushes)
			      datatype z = datatype Kind.t
			   in
			      case kind of
				 Cont _ => add pushes
			       | CReturn {func, ...} =>
				    let
				       val name = CFunction.name func
				       fun doit si =
					  add (#1 (enter (pushes, si)))
				    in
				       case name of
					  "GC_gc" => doit SourceInfo.gc
					| "GC_arrayAllocate" =>
					     doit SourceInfo.gcArrayAllocate
					| "MLton_bug" => add pushes
					| _ => doit (SourceInfo.fromC name)
				    end
			       | Handler => add pushes
			       | Jump => ()
			   end
			fun maybeSplit {args,
					bytesAllocated: Bytes.t,
					kind,
					label,
					leaves,
					pushes: Push.t list,
					statements} =
			   if profileAlloc
			      andalso Bytes.> (bytesAllocated, Bytes.zero)
			      then
				 let
				    val newLabel = Label.newNoname ()
				    val _ =
				       addFrameProfilePushes (newLabel, pushes)
				    val func = CFunction.profileInc
				    val transfer =
				       Transfer.CCall
				       {args = (Vector.new2
						(Operand.GCState,
						 Operand.word
						 (WordX.fromIntInf
						  (IntInf.fromInt
						   (Bytes.toInt bytesAllocated),
						   WordSize.default)))),
					func = func,
					return = SOME newLabel}
				    val sourceSeq = Push.toSources pushes
				    val _ =
				       backward {args = args,
						 kind = kind,
						 label = label,
						 leaves = leaves,
						 sourceSeq = sourceSeq,
						 statements = statements,
						 transfer = transfer}
				 in
				    {args = Vector.new0 (),
				     bytesAllocated = Bytes.zero,
				     kind = Kind.CReturn {func = func},
				     label = newLabel,
				     leaves = [],
				     statements = []}
				 end
			   else {args = args,
				 bytesAllocated = Bytes.zero,
				 kind = kind,
				 label = label,
				 leaves = leaves,
				 statements = statements}
			val {args, bytesAllocated, kind, label, leaves, pushes,
			     statements} =
			   Vector.fold
			   (statements,
			    {args = args,
			     bytesAllocated = Bytes.zero,
			     kind = kind,
			     label = label,
			     leaves = [],
			     pushes = pushes,
			     statements = []},
			    fn (s, {args, bytesAllocated, kind, label,
				    leaves,
				    pushes: Push.t list,
				    statements}) =>
			    (if not debug
				then ()
			     else
				let
				   open Layout
				in
				   outputl
				   (seq [List.layout Push.layout pushes,
					 str " ",
					 Statement.layout s],
				    Out.error)
				end
			     ;
			    case s of
			       Object {size, ...} =>
				  {args = args,
				   bytesAllocated = Bytes.+ (bytesAllocated,
							     size),
				   kind = kind,
				   label = label,
				   leaves = leaves,
				   pushes = pushes,
				   statements = s :: statements}
			     | Profile ps =>
				  let
				     val {args, bytesAllocated, kind, label,
					  leaves, statements} =
					maybeSplit
					{args = args,
					 bytesAllocated = bytesAllocated,
					 kind = kind,
					 label = label,
					 leaves = leaves,
					 pushes = pushes,
					 statements = statements}
				     datatype z = datatype ProfileExp.t
				     val (pushes, keep, leaves) =
					case ps of
					   Enter si =>
					      let
						 val (pushes, keep) =
						    enter (pushes, si)
					      in
						 (pushes, keep, leaves)
					      end
					 | Leave si =>
					      (case pushes of
						  [] =>
						     Error.bug "unmatched Leave"
						| p :: pushes' =>
						     let
							val (keep, si', leaves) =
							   case p of
							      Push.Enter
							      (infoNode as
							       InfoNode.T
							       {info, ...}) =>
								 (true, info,
								  infoNode :: leaves)
							    | Push.Skip si' =>
								 (false, si',
								  leaves)
						     in
							if SourceInfo.equals (si, si')
							   then (pushes',
								 keep,
								 leaves)
							else Error.bug "mismatched Leave"
						     end)
				     val statements =
					if keep
					   then s :: statements
					else statements
				  in
				     {args = args,
				      bytesAllocated = bytesAllocated,
				      kind = kind,
				      label = label,
				      leaves = leaves,
				      pushes = pushes,
				      statements = statements}
				  end
			     | _ =>
				  {args = args,
				   bytesAllocated = bytesAllocated,
				   kind = kind,
				   label = label,
				   leaves = leaves,
				   pushes = pushes,
				   statements = s :: statements})
			    )
			val {args, kind, label, leaves, statements, ...} =
			   maybeSplit {args = args,
				       bytesAllocated = bytesAllocated,
				       kind = kind,
				       label = label,
				       leaves = leaves,
				       pushes = pushes,
				       statements = statements}
			val _ =
			   Transfer.foreachLabel
			   (transfer, fn l => goto (l, pushes))
			val transfer =
			   case transfer of
			      Transfer.Call {func, return, ...} =>
				 let
				    val fi as FuncInfo.T {callers, ...} =
				       funcInfo func
				 in
				    case return of
				       Return.NonTail _ =>
					  let
					     val _ =
						case firstEnter pushes of
						   NONE =>
						      List.push (tailCalls, fi)
						 | SOME n => 
						      List.push (callers, n)
					  in
					     if profileStack
						then profileEnter (pushes,
								   transfer)
					     else transfer
					  end
				     | _ =>
					  (List.push (tailCalls, fi)
					   ; transfer)
				 end
			    | _ => transfer
		     in
			backward {args = args,
				  kind = kind,
				  label = label,
				  leaves = leaves,
				  sourceSeq = Push.toSources pushes,
				  statements = statements,
				  transfer = transfer}
		     end
	       end
	    val _ = goto (start, #1 (enter ([], firstSource)))
	    val blocks = Vector.fromList (!blocks)
	 in
	    Function.new {args = args,
			  blocks = blocks,
			  name = name,
			  raises = raises,
			  returns = returns,
			  start = start}
	 end
      val program = Program.T {functions = List.revMap (functions, doFunction),
			       handlesSignals = handlesSignals,
			       main = doFunction main,
			       objectTypes = objectTypes}
      val _ = addFuncEdges ()
      val names = Vector.fromListRev (!names)
      val sources =
	 Vector.map
	 (Vector.fromListRev (!infoNodes),
	  fn InfoNode.T {nameIndex, successors, ...} =>
	  {nameIndex = nameIndex, 
	   successorsIndex = (sourceSeqIndex
			      (List.revMap (!successors,
					    InfoNode.sourcesIndex)))})
      (* makeSourceSeqs () must happen after making sources, since that creates
       * new sourceSeqs.
       *)
      val sourceSeqs = makeSourceSeqs ()
      fun makeProfileInfo {frames} =
	 let
	    val {get, set, ...} =
	       Property.getSetOnce
	       (Label.plist,
		Property.initRaise ("frameProfileIndex", Label.layout))
	    val _ =
	       List.foreach (!frameProfileIndices, fn (l, i) =>
			     set (l, i))
	    val frameSources = Vector.map (frames, get)
	 in
	    SOME (Machine.ProfileInfo.T
		  {frameSources = frameSources,
		   labels = Vector.fromList (!labels),
		   names = names,
		   sourceSeqs = sourceSeqs,
		   sources = sources})
	 end
   in
      (program, makeProfileInfo)
   end

end
