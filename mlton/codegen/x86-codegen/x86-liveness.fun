
functor x86Liveness(S: X86_LIVENESS_STRUCTS) : X86_LIVENESS =
struct
  open S
  open x86
    
  val tracer = x86.tracer
  val tracerTop = x86.tracerTop

  structure LiveSet = MemLocSet
  fun track memloc = ClassSet.contains(!x86MLtonBasic.Classes.livenessClasses, 
				       MemLoc.class memloc)

  fun livenessOperands live
    = List.fold
      (live,
       LiveSet.empty,
       fn (operand, live)
        => (case Operand.deMemloc operand
	      of NONE => live
	       | SOME memloc
	       => if track memloc
		    then LiveSet.add(live, memloc)
		    else live))

  fun livenessMemlocs live
    = List.fold
      (live,
       LiveSet.empty,
       fn (memloc, live) 
        => if track memloc
	     then LiveSet.add(live, memloc)
	     else live)

  structure LiveInfo =
    struct
      datatype t = T of {get: Label.t -> LiveSet.t,
			 set: Label.t * LiveSet.t -> unit}
      
      fun newLiveInfo ()
	= let
	    val liveInfo as {get : Label.t -> LiveSet.t,
			     set : Label.t * LiveSet.t -> unit}
	      = Property.getSet
	        (Label.plist, Property.initRaise ("liveInfo", Label.layout))
	  in
	    T liveInfo
	  end

      fun setLiveOperands (liveInfo as T {get, set}, label, live)
	= set(label, livenessOperands live)
      fun setLiveMemlocs (liveInfo as T {get, set}, label, live)
	= set(label, livenessMemlocs live)
      fun setLive (liveInfo as T {get, set}, label, live)
	= set(label, live)
      fun getLive (liveInfo as T {get, set}, label)
	= get label
    end

  fun liveness_uses_defs {uses : Operand.t list,
			  defs : Operand.t list} :
                         {uses : LiveSet.t,
			  defs : LiveSet.t}
    = let
	val baseUses = livenessOperands uses
	val livenessUses 
	  = let
	      fun doit (operands, livenessUses)
		= List.fold
		  (operands,
		   livenessUses,
		   fn (operand, livenessUses)
		    => case Operand.deMemloc operand
			 of SOME memloc
			  => List.fold
		             (MemLoc.utilized memloc,
			      livenessUses,
			      fn (memloc, livenessUses)
			       => if track memloc
				    then LiveSet.add(livenessUses, memloc)
				    else livenessUses)
			  | NONE => livenessUses)
	    in
	      doit(defs,
	      doit(uses,
		   baseUses))
	    end

	val baseDefs = livenessOperands defs
	val livenessDefs = baseDefs
      in
	{uses = livenessUses,
	 defs = livenessDefs}
      end

  structure Liveness = 
    struct
      type t = {liveIn: LiveSet.t,
		liveOut: LiveSet.t,
		dead: LiveSet.t}

      fun toString {liveIn, liveOut, dead}
	= let
	    fun doit (name, l, toString, s)
	      = LiveSet.fold(l, s,
			     fn (x, s)
			      => concat [name, toString x, "\n", s])
	  in
	    doit("liveIn: ", liveIn, MemLoc.toString,
	    doit("liveOut: ", liveOut, MemLoc.toString,
	    doit("dead: ", dead, MemLoc.toString,
		 "")))
	  end
	

      fun eq ({liveIn = liveIn1,
	       liveOut = liveOut1,
	       dead = dead1},
	      {liveIn = liveIn2,
	       liveOut = liveOut2,
	       dead = dead2})
	= LiveSet.equals(liveIn1, liveIn2) andalso
	  LiveSet.equals(liveOut1, liveOut2) andalso
	  LiveSet.equals(dead1, dead2)	      

      fun invariant {liveIn : LiveSet.t,
		     liveOut : LiveSet.t,
		     dead : LiveSet.t}
	= let
	    val rec check 
	      = fn [] => true
	         | m::l => List.forall
	                   (l, 
			    fn m' 
			     => if not(MemLoc.mayAlias(m,m'))
				  then true
				  else (print 
					(concat 
					 ["\nmayAlias:\n",
					  MemLoc.toString m,
					  "\n",
					  MemLoc.toString m',
					  "\n"]);
					false))
                           andalso
			   check l

	    fun doit s
	      = let
		  val _
		    = Assert.assert
		      ("invariant - mayAlias",
		       fn () => check (LiveSet.toList s))
		in
		  s
		end
	  in
	    {liveIn = doit liveIn,
	     liveOut = doit liveOut,
	     dead = doit dead}
	  end

      fun liveness {uses : LiveSet.t,
		    defs : LiveSet.t,
		    live : LiveSet.t} : t
	= let
	    val liveOut = live

	    (* liveIn = uses \/ (liveOut - defs) *)
	    val liveIn = LiveSet.+(uses, LiveSet.-(live, defs))

	    (* dead = (liveIn \/ defs) - liveOut *)
	    val dead = LiveSet.-(LiveSet.+(liveIn, defs), liveOut)
	  in
	    (* invariant *) {liveIn = liveIn,
			     liveOut = liveOut,
			     dead = dead}
	  end

      fun livenessEntry {entry : Entry.t,
			 live : LiveSet.t} : t
	= let
	    val {uses, defs, ...} = Entry.uses_defs_kills entry
	    val {uses, defs} = liveness_uses_defs {uses = uses, defs = defs}
	    val defs = List.fold
	               (Entry.live entry,
			defs,
			fn (memloc, defs)
			 => if track memloc
			      then LiveSet.add(defs, memloc)
			      else defs)
	  in
	    liveness {uses = uses,
		      defs = defs,
		      live = live}
	  end

      fun livenessAssembly {assembly : Assembly.t,
			    live : LiveSet.t} : t
	= let
	    val {uses, defs, ...} = Assembly.uses_defs_kills assembly
	    val {uses, defs} = liveness_uses_defs {uses = uses, defs = defs}
	  in
	    liveness {uses = uses,
		      defs = defs,
		      live = live}
	  end

      fun livenessTransfer' {transfer: Transfer.t,
			     live : LiveSet.t} : t
	= let
	    val {uses,defs,...} = Transfer.uses_defs_kills transfer
	    val {uses,defs} = liveness_uses_defs {uses = uses, defs = defs}
	    (* Transfer.live transfer could be considered uses,
	     *  but the Liveness.t of a transfer should have
	     *  Transfer.live transfer as liveOut.
	     *)
	    val live = List.fold
	               (Transfer.live transfer,
			live,
			fn (memloc, live)
			 => if track memloc
			      then LiveSet.add(live, memloc)
			      else live)
	  in 
	    liveness {uses = uses,
		      defs = defs,
		      live = live}
	  end

      fun livenessTransfer {transfer: Transfer.t,
			    liveInfo: LiveInfo.t} : t
	= let
	    val targets = Transfer.nearTargets transfer
	    val live
	      = List.fold
	        (targets,
		 LiveSet.empty,
		 fn (target, live) 
	          => LiveSet.union(LiveInfo.getLive(liveInfo, target), 
				   live))
	  in
	    livenessTransfer' {transfer = transfer,
			       live = live}
	  end

      fun livenessBlock {block as Block.T {entry, statements, transfer, ...},
			 liveInfo : LiveInfo.t}
	= let
	    val {liveIn = live, ...}
	      = livenessTransfer {transfer = transfer,
				  liveInfo = liveInfo}

	    val live
	      = List.foldr
	        (statements,
		 live,
		 fn (asm,live)
		  => let
		       val {liveIn = live, ...}
			 = livenessAssembly {assembly = asm,
					     live = live}
		     in
		       live
		     end)

	    val {liveIn = live, ...} 
	      = livenessEntry {entry = entry,
			       live = live}
	  in
	    live
	  end
    end

  structure LiveInfo =
    struct
      open LiveInfo

      fun completeLiveInfo {chunk as Chunk.T {blocks, ...}, 
			    liveInfo : LiveInfo.t,
			    pass: string}
	= let
	    val blockInfo
	      as {get = getBlockInfo : 
		        Label.t -> {pred: Label.t list ref,
				    block: Block.t option ref,
				    topo: int ref}}
	      = Property.get
	        (Label.plist,
		 Property.initFun (fn label => {pred = ref [],
						block = ref NONE,
						topo = ref ~1}))
	    val get_pred = (#pred o getBlockInfo)
	    val get_block = (#block o getBlockInfo)
	    val get_topo = (#topo o getBlockInfo)
	    val get_pred' = (! o #pred o getBlockInfo)
	    val get_block' = (! o #block o getBlockInfo)
	    val get_topo' = (! o #topo o getBlockInfo)
	      
	    val labels
	      = List.map
	        (blocks,
		 fn block' as Block.T {entry, transfer,...}
		  => let
		       val label = Entry.label entry
		       val {block,topo,...} = getBlockInfo label
		       val targets = Transfer.nearTargets transfer
		     in 
		       block := SOME block';
		       topo := 0;
		       List.foreach
		       (targets,
			fn target => List.push(get_pred target, label));
		       label
		     end)
		
	    local
	      val todo = ref []
	      fun topo_order(x,y) = Int.compare(get_topo' x, get_topo' y)

	      fun insert (l, x, compare)
		= let
		    val rec insert'
		      = fn ([],acc) => List.appendRev(acc, [x])
		         | (l as h::t,acc) 
		         => (case compare(h,x)
			       of LESS
				=> insert' (t, h::acc)
			        | EQUAL
				=> List.appendRev(acc, l)
			        | GREATER
			        => List.appendRev(acc, x::l))
		  in
		    insert' (l,[])
		  end
	    in
	      fun add_todo x = todo := insert(!todo, x, topo_order)
	      fun push_todo x = todo := x::(!todo)
	      fun rev_todo () = todo := List.rev (!todo)
	      fun get_todo () 
		= (case !todo
		     of [] => NONE
		      | (x::todo') => (todo := todo';
				       SOME x))
	    end
	  
	    local
	      val num = Counter.new 1
	    in
	      fun topo_sort label
		= let
		    val {topo, pred, ...} = getBlockInfo label
		  in
		    if !topo = 0
		      then (topo := Counter.next num;
			    push_todo label;
			    List.foreach(!pred, topo_sort))
		      else ()
		  end
	      fun topo_root label
		= (get_topo label := Counter.next num;
		   push_todo label)
	    end
	  
	    fun loop (labels, n)
	      = if List.isEmpty labels
		  then ()
		  else let
			 val {yes = exits, no = labels}
			   = List.partition
			     (labels,
			      fn label
			       => let
				    val Block.T {transfer, ...} 
				      = valOf (get_block' label)
				    val targets = Transfer.nearTargets transfer
				      
				    val targets'
				      = List.fold(targets,
						  0,
						  fn (target,targets')
						   => if get_topo' target = ~1
							then targets'
							else targets' + 1)
				  in
				    targets' = n
				  end)
			 val exits
			   = List.removeAll
			     (exits,
			      fn label => get_topo' label <> 0)
			 val _ 
			   = (List.foreach
			      (exits, 
			       fn label => topo_root label);
			      List.foreach
			      (exits,
			       fn label 
			       => List.foreach(get_pred' label, topo_sort)))
		       in
			 loop(labels, n + 1)
		       end
	    val _ = loop(labels, 0)
	    val _ = rev_todo ()
	      
	    val changed = ref false
	    fun doit ()
	      = (case get_todo ()
		   of NONE => ()
 		    | SOME label
		    => let
			 val {pred, block, ...} = getBlockInfo label
			 val block = valOf (!block)
			 val live = Liveness.livenessBlock {block = block,
							    liveInfo = liveInfo}
			     
			 val live' = LiveInfo.getLive(liveInfo, label)
		       in
			 if LiveSet.equals(live, live')
			   then ()
			   else (LiveInfo.setLive(liveInfo, label, live);
				 List.foreach(!pred, add_todo);
				 print "completeLiveInfo:";
				 print pass;
				 print ": ";
				 print (Label.toString label);
				 print ": ";
				 if LiveSet.<(live, live')
				   then print "new < old"
				 else if LiveSet.<(live', live)
				   then print "old < new"
				 else print "?";
				 print "\n";
				 if true
				   then (print "old: ";
					 LiveSet.foreach
					 (live',
					  fn m 
					   => (print (MemLoc.toString m);
					       print " "));
					 print "\n";
					 print "new: ";
					 LiveSet.foreach
					 (live,
					  fn m 
					   => (print (MemLoc.toString m);
					       print " "));
					 print "\n")
				   else ();
				 changed := true);
			 doit ()
		       end)
	  in
	    doit ()
	  end
	
      val (completeLiveInfo : {chunk: Chunk.t, 
			       liveInfo: LiveInfo.t,
			       pass: string} -> unit,
	   completeLiveInfo_msg)
	= tracerTop
	  "completeLiveInfo"
	  completeLiveInfo

      fun verifyLiveInfo {chunk as Chunk.T {blocks, ...},
			  liveInfo : t}
	= List.forall
	  (blocks,
	   fn block as Block.T {entry, ...} 
	    => let
		 val label = Entry.label entry
		 val live = LiveInfo.getLive(liveInfo, label)
		 val live' = Liveness.livenessBlock {block = block,
						     liveInfo = liveInfo}
	       in
		 LiveSet.equals(live, live')
	       end)

      val (verifyLiveInfo : {chunk: Chunk.t, liveInfo: LiveInfo.t} -> bool,
	   verifyLiveInfo_msg)
	= tracer
	  "verifyLiveInfo"
	  verifyLiveInfo

    end

  structure LivenessBlock =
    struct
      datatype t = T of {entry: (Entry.t * Liveness.t),
			 profileInfo: ProfileInfo.t,
			 statements: (Assembly.t * Liveness.t) list,
			 transfer: Transfer.t * Liveness.t}

      fun toString (T {entry, profileInfo, statements, transfer})
	= concat [let
		    val (entry,info) = entry
		  in
		    concat[Entry.toString entry,
			   "\n",
			   Liveness.toString info,
			   "\n"]
		  end,
		  List.fold
		  (statements,
		   "",
		   fn ((asm,info),s)
		    => concat [s,
			       Assembly.toString asm,
			       "\n",
			       Liveness.toString info]),
		  let
		    val (trans,info) = transfer
		  in
		    concat[Transfer.toString trans,
			   "\n",
			   Liveness.toString info,
			   "\n"]
		  end]

      fun printBlock (T {entry, profileInfo, statements, transfer})
	= (let
	     val (entry,info) = entry
	   in 
	     print (Entry.toString entry);
	     print "\n";
	     print (Liveness.toString info)
	   end;
	   List.foreach
	   (statements,
	    fn (asm,info)
	     => (print (Assembly.toString asm);
		 print "\n";
		 print (Liveness.toString info)));
	   let
	     val (trans,info) = transfer
	   in
	     print (Transfer.toString trans);
	     print "\n";
	     print (Liveness.toString info);
	     print "\n"
	   end)

      fun toLivenessEntry {entry,
			   live}
	= let
	    val info as {liveIn = live, ...}
	      = Liveness.livenessEntry {entry = entry,
					live = live}
	  in
	    {entry = (entry,info),
	     live = live}
	  end

      fun reLivenessEntry {entry,
			   live}
	= let
	    val (entry,_) = entry
	    val info as {liveIn = live, ...}
	      = Liveness.livenessEntry {entry = entry,
					live = live}
	  in
	    {entry = (entry,info),
	     live = live}
	  end

      fun toLivenessStatements {statements,
				live}
	= let
	    val {statements,live}
	      = List.foldr(statements,
			   {statements = [], live = live},
			   fn (asm,{statements,live})
			    => let
				 val info as {liveIn = live, ...}
				   = Liveness.livenessAssembly 
				     {assembly = asm,
				      live = live}
			       in
				 {statements = (asm, info)::statements, 
				  live = live}
			       end)
	  in
	    {statements = statements,
	     live = live}
	  end

      fun reLivenessStatements {statements: (Assembly.t * Liveness.t) list,
				live}
	= let
	    val {statements,live,...}
	      = List.foldr(statements,
			   {statements = [], 
			    live = live, 
			    continue = false},
			   fn ((asm,info),{statements,live,continue})
			    => if continue
				 then {statements = (asm,info)::statements,
				       live = #liveIn info,
				       continue = continue}
				 else let
				       val info' as {liveIn = live',...}
					 = Liveness.livenessAssembly 
					   {assembly = asm,
					    live = live}
				     in
				       {statements = (asm, info')::statements, 
					live = live',
					continue = Liveness.eq(info,info')}
				     end)
	  in
	    {statements = statements,
	     live = live}
	  end

      fun toLivenessTransfer {transfer,
			      liveInfo}
	= let
	    val info as {liveIn = live, ...}
	      = Liveness.livenessTransfer {transfer = transfer,
					   liveInfo = liveInfo}
	  in
	    {transfer = (transfer,info),
	     live = live}
	  end

      fun reLivenessTransfer {transfer: Transfer.t * Liveness.t}
	= let
	    val (transfer,{liveOut,...}) = transfer
	    val info as {liveIn = live, ...} 
	      = Liveness.livenessTransfer' {transfer = transfer,
					    live = liveOut}
	  in
	    {transfer = (transfer, info),
	     live = live}
	  end

      fun toLivenessBlock {block as Block.T {entry, profileInfo,
					     statements, transfer},
			   liveInfo : LiveInfo.t}
	= let
	    val {transfer, live}
	      = toLivenessTransfer {transfer = transfer,
				    liveInfo = liveInfo}

	    val {statements, live}
	      = toLivenessStatements {statements =statements,
				      live = live}

	    val {entry, live}
	      = toLivenessEntry {entry = entry,
				 live = live}

	    val liveness_block
	      = T {entry = entry,
		   profileInfo = profileInfo,
		   statements = statements,
		   transfer = transfer}
	  in 
	    liveness_block
	  end

      val (toLivenessBlock: {block: Block.t, liveInfo: LiveInfo.t} -> t,
	   toLivenessBlock_msg)
	= tracer
	  "toLivenessBlock"
          toLivenessBlock

      fun verifyLivenessEntry {entry = (entry,info),
			       live}
	= let
	    val info' as {liveIn = live', ...}
	      = Liveness.livenessEntry {entry = entry,
					live = live}
	  in
	    {verified = Liveness.eq(info, info'),
	     live = live'}
	  end

      fun verifyLivenessStatements {statements,
				    live}
	= List.foldr(statements,
		     {verified = true, live = live},
		     fn ((asm,info),{verified, live})
		      => let
			   val info' as {liveIn = live', ...}
			     = Liveness.livenessAssembly 
			       {assembly = asm,
				live = live}
			 in
			   {verified = verified andalso 
			               Liveness.eq(info, info'), 
			    live = live'}
			 end)

      fun verifyLivenessTransfer {transfer = (transfer,info),
				  liveInfo}
	= let
	    val info' as {liveIn = live', ...}
	      = Liveness.livenessTransfer {transfer = transfer,
					   liveInfo = liveInfo}
	  in
	    {verified = Liveness.eq(info, info'),
	     live = live'}
	  end

      fun verifyLivenessBlock {block as T {entry, profileInfo,
					   statements, transfer},
			       liveInfo: LiveInfo.t}
	= let
	    val {verified = verified_transfer,
		 live}
	      = verifyLivenessTransfer {transfer = transfer,
					liveInfo = liveInfo}

	    val {verified = verified_statements,
		 live}
	      = verifyLivenessStatements {statements =statements,
					  live = live}

	    val {verified = verified_entry,
		 live}
	      = verifyLivenessEntry {entry = entry,
				     live = live}

(* FIXME -- the live-in set changed because of dead code elimination.
	    val live' = get label

	    val verified_live = List.equalsAsSet(live, live', MemLoc.eq)
*)
	    val verified_live = true
	  in 
	    verified_transfer andalso 
	    verified_statements andalso
	    verified_entry andalso
	    verified_live
	  end

      val (verifyLivenessBlock: {block: t, liveInfo: LiveInfo.t} -> bool,
	   verifyLivenessBlock_msg)
	= tracer
	  "verifyLivenessBlock"
          verifyLivenessBlock

      fun toBlock {block as T {entry, profileInfo, statements, transfer}}
	= let
	    val (entry,info) = entry
	    val statements = List.map(statements, fn (asm,info) => asm)
	    val (transfer,info) = transfer
	  in 
	    Block.T {entry = entry,
		     profileInfo = profileInfo,
		     statements = statements,
		     transfer = transfer}
	  end

      val (toBlock: {block: t} -> Block.t, 
	   toBlock_msg)
	= tracer
	  "toBlock"
          toBlock
    end

end
