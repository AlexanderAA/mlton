(* Copyright (C) 2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

functor SsaToSsa2 (S: SSA_TO_SSA2_STRUCTS): SSA_TO_SSA2 = 
struct

open S

structure S = Ssa
structure S2 = Ssa2

local
   open S
in
   structure Con = Con
   structure Label = Label
   structure Prim = Prim
   structure Var = Var
end

fun convert (S.Program.T {datatypes, functions, globals, main}) =
   let
      val {get = convertType: S.Type.t -> S2.Type.t, ...} =
	 Property.get
	 (S.Type.plist,
	  Property.initRec
	  (fn (t, convertType)  =>
	   case S.Type.dest t of
	      S.Type.Array t => S2.Type.array (convertType t)
	    | S.Type.Datatype tycon => S2.Type.datatypee tycon
	    | S.Type.IntInf => S2.Type.intInf
	    | S.Type.Real s => S2.Type.real s
	    | S.Type.Ref t => S2.Type.reff (convertType t)
	    | S.Type.Thread => S2.Type.thread
	    | S.Type.Tuple ts =>
		 S2.Type.tuple (Vector.map (ts, fn t =>
					    {elt = convertType t,
					     isMutable = false}))
	    | S.Type.Vector t => S2.Type.vector (convertType t)
	    | S.Type.Weak t => S2.Type.weak (convertType t)
	    | S.Type.Word s => S2.Type.word s))
      fun convertTypes ts = Vector.map (ts, convertType)
      val {get = conType: Con.t -> S2.Type.t, set = setConType, ...} =
	 Property.getSetOnce (Con.plist,
			      Property.initRaise ("type", Con.layout))
      val datatypes =
	 Vector.map
	 (datatypes, fn S.Datatype.T {cons, tycon} =>
	  S2.Datatype.T
	  {cons = Vector.map (cons, fn {args, con} =>
			      let
				 val args = Vector.map (args, fn t =>
							{elt = convertType t,
							 isMutable = false})
				 val () =
				    setConType (con, S2.Type.conApp (con, args))
			      in
				 {args = args,
				  con = con}
			      end),
	   tycon = tycon})
      fun convertPrim p = S.Prim.map (p, convertType)
      fun convertExp (e: S.Exp.t, t: S.Type.t): S2.Exp.t * S2.Type.t =
	 let
	    fun simple e = (e, convertType t)
	 in
	    case e of
	       S.Exp.ConApp {args, con} =>
		  (S2.Exp.Object {args = args, con = SOME con},
		   conType con)
	     | S.Exp.Const c => simple (S2.Exp.Const c)
	     | S.Exp.PrimApp {args, prim, targs} =>
		  simple
		  (let
		      fun arg i = Vector.sub (args, i)
		      datatype z = datatype Prim.Name.t
		   in
		      case Prim.name prim of
			 Ref_assign =>
			    S2.Exp.Update {object = arg 0,
					   offset = 0,
					   value = arg 1}
		       | Ref_deref =>
			    S2.Exp.Select {object = arg 0,
					   offset = 0}
		       | Ref_ref =>
			    S2.Exp.Object {args = Vector.new1 (arg 0),
					   con = NONE}
		       | _ => 
			    S2.Exp.PrimApp {args = args,
					    prim = convertPrim prim,
					    targs = convertTypes targs}
		   end)
	     | S.Exp.Profile e => simple (S2.Exp.Profile e)
	     | S.Exp.Select {offset, tuple} =>
		  simple (S2.Exp.Select {object = tuple, offset = offset})
	     | S.Exp.Tuple v => simple (S2.Exp.Object {args = v, con = NONE})
	     | S.Exp.Var x => simple (S2.Exp.Var x)
	 end
      fun convertStatement (S.Statement.T {exp, ty, var}) =
	 let
	    val (exp, ty) = convertExp (exp, ty)
	 in
	    S2.Statement.T {exp = exp,
			    ty = ty,
			    var = var}
	 end
      fun convertHandler (h: S.Handler.t): S2.Handler.t =
	 case h of
	    S.Handler.Caller => S2.Handler.Caller
	  | S.Handler.Dead => S2.Handler.Dead
	  | S.Handler.Handle l => S2.Handler.Handle l
      fun convertReturn (r: S.Return.t): S2.Return.t =
	 case r of
	    S.Return.Dead => S2.Return.Dead
	  | S.Return.NonTail {cont, handler} =>
	       S2.Return.NonTail {cont = cont,
				  handler = convertHandler handler}
	  | S.Return.Tail => S2.Return.Tail
      val extraBlocks: S2.Block.t list ref = ref []
      fun convertCases (cs: S.Cases.t): S2.Cases.t =
	 case cs of
	    S.Cases.Con v =>
	       S2.Cases.Con
	       (Vector.map
		(v, fn (c, l) =>
		 let
		    val objectTy = conType c
		 in
		    case S2.Type.dest objectTy of
		       S2.Type.Object {args, ...} =>
			  if 0 = Vector.length args
			     then (c, l)
			  else
			     let
				val l' = Label.newNoname ()
				val object = Var.newNoname ()
				val (xs, statements) =
				   Vector.unzip
				   (Vector.mapi
				    (args, fn (i, {elt = ty, ...}) =>
				     let
					val x = Var.newNoname ()
					val exp =
					   S2.Exp.Select {object = object,
							  offset = i}
				     in
					(x,
					 S2.Statement.T {exp = exp,
							 ty = ty,
							 var = SOME x})
				     end))
				val transfer =
				   S2.Transfer.Goto {args = xs, dst = l}
				val args = Vector.new1 (object, objectTy)
				val () =
				   List.push
				   (extraBlocks,
				    S2.Block.T {args = args,
						label = l',
						statements = statements,
						transfer = transfer})
			     in
				(c, l')
			     end
		     | _ => Error.bug "strange object type"
		 end))
	  | S.Cases.Word v => S2.Cases.Word v
      fun convertTransfer (t: S.Transfer.t): S2.Transfer.t =
	 case t of
	    S.Transfer.Arith {args, overflow, prim, success, ty} =>
	       S2.Transfer.Arith {args = args,
				  overflow = overflow,
				  prim = convertPrim prim,
				  success = success,
				  ty = convertType ty}
	  | S.Transfer.Bug => S2.Transfer.Bug
	  | S.Transfer.Call {args, func, return} =>
	       S2.Transfer.Call {args = args,
				 func = func,
				 return = convertReturn return}
	  | S.Transfer.Case {cases, default, test} =>
	       S2.Transfer.Case {cases = convertCases cases,
				 default = default,
				 test = test}
	  | S.Transfer.Goto r => S2.Transfer.Goto r
	  | S.Transfer.Raise v => S2.Transfer.Raise v
	  | S.Transfer.Return v => S2.Transfer.Return v
	  | S.Transfer.Runtime {args, prim, return} =>
	       S2.Transfer.Runtime {args = args,
				    prim = convertPrim prim,
				    return = return}
      fun convertFormals xts = Vector.map (xts, fn (x, t) => (x, convertType t))
      fun convertBlock (S.Block.T {args, label, statements, transfer}) =
	 S2.Block.T {args = convertFormals args,
		     label = label,
		     statements = Vector.map (statements, convertStatement),
		     transfer = convertTransfer transfer}
      val functions =
	 List.map
	 (functions, fn f =>
	  let
	     val {args, blocks, name, raises, returns, start} =
		S.Function.dest f
	     fun rr tvo = Option.map (tvo, convertTypes)
	     val blocks = Vector.map (blocks, convertBlock)
	     val blocks = Vector.concat [blocks, Vector.fromList (!extraBlocks)]
	     val () = extraBlocks := []
	  in
	     S2.Function.new {args = convertFormals args,
			      blocks = blocks,
			      name = name,
			      raises = rr raises,
			      returns = rr returns,
			      start = start}
	  end)
      val globals = Vector.map (globals, convertStatement)
   in
      S2.Program.T {datatypes = datatypes,
		    functions = functions,
		    globals = globals,
		    main = main}
   end

end
