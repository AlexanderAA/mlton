type int = Int.t

signature DIRECTED_GRAPH = 
   sig
      structure Node: 
	 sig
	    type edge
	    type t

	    val equals: t * t -> bool
	    val hasEdge: {from: t, to: t} -> bool
	    val layout: t -> Layout.t
	    val plist: t -> PropertyList.t
	    val successors: t -> edge list
	 end
      structure Edge:
	 sig
	    type t

	    val equals: t * t -> bool
	    val plist: t -> PropertyList.t
	    val to: t -> Node.t
	 end
      sharing type Node.edge = Edge.t

      (* depth first search *)
      structure DfsParam:
	 sig
	    type t = {startNode: Node.t -> unit,
		      finishNode: Node.t -> unit,
		      handleTreeEdge: Edge.t -> unit,
		      handleNonTreeEdge: Edge.t -> unit,
		      startTree: Node.t -> unit,
		      finishTree: Node.t -> unit,
		      finishDfs: unit -> unit}
	    val finishNode: (Node.t -> unit) -> t
	    val ignore: 'a -> unit
	    val combine: t * t -> t
	 end

      (* the main graph type *)
      type t

      val addEdge: t * {from: Node.t, to: Node.t} -> Edge.t
      val dfs: t * DfsParam.t -> unit
      val dfsNodes: t * Node.t list * DfsParam.t -> unit
      val dfsTree: t * {root: Node.t, nodeValue: Node.t -> 'a} -> 'a Tree.t
      val discoverFinishTimes: t -> {discover: Node.t -> int,
				     finish: Node.t -> int,
				     destroy: unit -> unit,
				     param: DfsParam.t}
      val display:
	 {graph: t,
	  layoutNode: Node.t -> Layout.t,
	  display: Layout.t -> unit} -> unit
      (* dominators (graph, {root})
       * Returns the immediate dominator relation for the subgraph of graph
       * rooted at root.
       *  idom n = SOME root      if n = root
       *  idom n = SOME n'        where n' is the immediate dominator of n
       *  idom n = NONE           if n is not reachable from root.
       *)
      datatype idomRes =
	 Idom of Node.t
       | Root
       | Unreachable
      val dominators: t * {root: Node.t} -> {idom: Node.t -> idomRes}
      val dominatorTree: t * {root: Node.t, nodeValue: Node.t -> 'a} -> 'a Tree.t
      val foreachDescendent: t * Node.t * (Node.t -> unit) -> unit
      val foreachEdge: t * (Node.t * Edge.t -> unit) -> unit
      val foreachNode: t * (Node.t -> unit) -> unit
      val layoutDot:
	 t * ({nodeName: Node.t -> string} ->
	      {title: string,
	       options: Dot.GraphOption.t list,
	       edgeOptions: Edge.t -> Dot.EdgeOption.t list,
	       nodeOptions: Node.t -> Dot.NodeOption.t list}) -> Layout.t
      structure LoopForest: 
	 sig 
	   datatype t = T of {loops: {headers: Node.t vector,
				      child: t} vector,
			      notInLoop: Node.t vector}
	 end
      val loopForestSteensgaard: t * {root:Node.t} -> LoopForest.t
      val new: unit -> t
      val newNode: t -> Node.t
      val nodes: t -> Node.t list
      (* Strongly-connected components.
       * Each component is given as a list of nodes.
       * The components are returned topologically sorted.
       *)
      val stronglyConnectedComponents: t -> Node.t list list
      exception TopologicalSort
      val topologicalSort: t -> Node.t list
   end


functor TestDirectedGraph (S: DIRECTED_GRAPH): sig end =
struct

open S

(* Section 7.3 of Muchnick. *)
local
   val g = new ()
   val {get = name, set = setName, ...} =
      Property.getSetOnce (Node.plist,
			   Property.initRaise ("name", Node.layout))
   val node = String.memoize (fn s =>
			      let
				 val n = newNode g
				 val _ = setName (n, s)
			      in n
			      end)
   val _ =
      List.foreach ([("entry\nfoo", "B1"),
		     ("B1", "B2"),
		     ("B1", "B3"),
		     ("B2", "exit"),
		     ("B3", "B4"),
		     ("B4", "B5"),
		     ("B4", "B6"),
		     ("B5", "exit"),
		     ("B6", "B4")], fn (from, to) =>
		    (addEdge (g, {from = node from, to = node to})
		     ; ()))
   val _ =
      File.withOut
      ("/tmp/z.dot", fn out =>
       let
	  open Dot
       in
	  Layout.output (layoutDot
			 (g, fn _ =>
			  {title = "Muchnick",
			   options = [],
			   edgeOptions = fn _ => [],
			   nodeOptions = fn n => [NodeOption.label (name n)]}),
			 out)
	  ; Out.newline out
       end)
   val {idom} = dominators (g, {root = node "entry\nfoo"})
   val g2 = new ()
   val {get = oldNode, set = setOldNode, ...} =
      Property.getSetOnce (Node.plist,
			   Property.initRaise ("oldNode", Node.layout))
   val {get = newNode, ...} =
      Property.get (Node.plist,
		    Property.initFun (fn n =>
				      let
					 val n' = newNode g2
					 val _ = setOldNode (n', n)
				      in n'
				      end))
   val _ = foreachNode (g, fn n =>
			case idom n of
			   Idom n' =>
			      (addEdge (g2, {from = newNode n',
					     to = newNode n})
			       ; ())
			 | _ => ())
   val _ =
      File.withOut
      ("/tmp/z2.dot", fn out =>
       let
	  open Dot
       in
	  Layout.output
	  (layoutDot
	   (g2, fn _ =>
	    {title = "dom",
	     options = [],
	     edgeOptions = fn _ => [],
	     nodeOptions = fn n => [NodeOption.label (name (oldNode n))]}),
	   out)
	  ; Out.newline out
       end)
in
end

end
