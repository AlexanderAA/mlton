(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
functor RemoveUnused (S: REMOVE_UNUSED_STRUCTS): REMOVE_UNUSED = 
struct

open S
open Exp Transfer

structure Used =
  struct
    structure L = TwoPointLattice (val bottom = "unused"
				   val top = "used")
    open L
    val use = makeTop
    val isUsed = isTop
    val whenUsed = addHandler
  end

structure Coned =
  struct
    structure L = TwoPointLattice (val bottom = "not coned"
				   val top = "coned")
    open L
    val con = makeTop
    val isConed = isTop
    val whenConed = addHandler
  end

structure Deconed =
  struct
    structure L = TwoPointLattice (val bottom = "not deconed"
				   val top = "deconed")
    open L
    val decon = makeTop
    val isDeconed = isTop
    val whenDeconed = addHandler
  end

structure Catches =
  struct
    structure L = TwoPointLattice (val bottom = "does not catch"
				   val top = "catches")
    open L
    val catch = makeTop
    val doesCatch = isTop
    val whenCatches = addHandler
  end

structure SideEffects =
  struct
    structure L = TwoPointLattice (val bottom = "does not side effect"
				   val top = "side effects")
    open L
    val sideEffect = makeTop
    val doesSideEffect = isTop
    val whenSideEffects = addHandler
  end

structure MayReturn =
  struct
    structure L = TwoPointLattice (val bottom = "does not return"
				   val top = "may return")
    open L
    val return = makeTop
    val mayReturn = isTop
    val whenReturns = addHandler
  end

structure MayRaise =
  struct
    structure L = TwoPointLattice (val bottom = "does not raise"
				   val top = "may raise")
    open L
    val raisee = makeTop
    val mayRaise = isTop
    val whenRaises = addHandler
  end


structure VarInfo =
   struct
     datatype t = T of {used: Used.t}

     fun layout (T {used, ...}) = Used.layout used
       
     local
       fun make f (T r) = f r
       fun make' f = (make f, ! o (make f))
     in
       val used = make #used
     end
   
     fun new (): t = T {used = Used.new ()}
       
     val use = Used.use o used
     val isUsed = Used.isUsed o used
     fun whenUsed (vi, th) = Used.whenUsed (used vi, th)
   end
 
structure TypeInfo = 
  struct
    datatype t = T of {deconed: bool ref}

    val layout = Layout.ignore

    local
      fun make f (T r) = f r
      fun make' f = (make f, ! o (make f))
    in
      val (deconed', deconed) = make' #deconed
    end

    fun new (): t = T {deconed = ref false}
  end

structure TyconInfo =
  struct
    datatype t = T of {cons: {con: Con.t, args: Type.t vector} vector,
		       numCons: int ref}

    val layout = Layout.ignore
      
    local
      fun make f (T r) = f r
      fun make' f = (make f, ! o (make f))
    in
      val cons = make #cons
      val (numCons', numCons) = make' #numCons
    end

    fun new {cons: {con: Con.t, args: Type.t vector} vector}: t
      = T {cons = cons,
	   numCons = ref ~1}
  end

structure ConInfo =
  struct
    datatype t = T of {args: (VarInfo.t * Type.t) vector,
		       coned: Coned.t,
		       deconed: Deconed.t,
		       dummy: Exp.t option ref,
		       tycon: Tycon.t}

    fun layout (T {args, coned, deconed, ...}) 
      = Layout.record [("args", Vector.layout (VarInfo.layout o #1) args),
		       ("coned", Coned.layout coned),
		       ("deconed", Deconed.layout deconed)]
      
    local
      fun make f (T r) = f r
      fun make' f = (make f, ! o (make f))
    in
      val args = make #args
      val coned = make #coned
      val deconed = make #deconed
      val dummy = make #dummy
      val tycon = make #tycon
    end
  
    val con = Coned.con o coned
    val isConed = Coned.isConed o coned
    fun whenConed (ci, th) = Coned.whenConed (coned ci, th)

    val decon = Deconed.decon o deconed
    val isDeconed = Deconed.isDeconed o deconed
    fun whenDeconed (ci, th) = Deconed.whenDeconed (deconed ci, th)
      
    fun new {args: Type.t vector, tycon: Tycon.t}: t
      = T {args = Vector.map (args, fn t => (VarInfo.new (), t)),
	   coned = Coned.new (),
	   deconed = Deconed.new (),
	   dummy = ref NONE,
	   tycon = tycon}
  end

structure FuncInfo =
  struct
    datatype t = T of {args: (VarInfo.t * Type.t) vector,
		       bugLabel: Label.t option ref,
		       mayRaise: MayRaise.t,
		       mayReturn: MayReturn.t,
		       raiseLabel: Label.t option ref,
		       raises: (VarInfo.t * Type.t) vector option,
		       returnLabel: Label.t option ref,
		       returns: (VarInfo.t * Type.t) vector option,
		       sideEffects: SideEffects.t,
		       used: Used.t,
		       wrappers: Block.t list ref}
      
    fun layout (T {args, 
		   mayRaise, mayReturn, 
		   raises, returns, 
		   sideEffects, used,
		   ...}) 
      = Layout.record [("args", Vector.layout 
			        (Layout.tuple2 (VarInfo.layout, Type.layout)) 
				args),
		       ("mayRaise", MayRaise.layout mayRaise),
		       ("mayReturn", MayReturn.layout mayReturn),
		       ("raises", Option.layout
				  (Vector.layout 
				   (Layout.tuple2 (VarInfo.layout, Type.layout)))
				  raises),
		       ("returns", Option.layout
			           (Vector.layout 
				    (Layout.tuple2 (VarInfo.layout, Type.layout)))
				   returns),
		       ("sideEffects", SideEffects.layout sideEffects),
		       ("used", Used.layout used)]

    local
      fun make f (T r) = f r
      fun make' f = (make f, ! o (make f))
    in
      val args = make #args
      val bugLabel = make #bugLabel
      val mayRaise' = make #mayRaise
      val mayReturn' = make #mayReturn
      val raiseLabel = make #raiseLabel
      val raises = make #raises
      val returnLabel = make #returnLabel
      val returns = make #returns
      val sideEffects = make #sideEffects
      val used = make #used
      val (wrappers', wrappers) = make' #wrappers
    end
  
    val raisee = MayRaise.raisee o mayRaise'
    val mayRaise = MayRaise.mayRaise o mayRaise'
    fun whenRaises (fi, th) = MayRaise.whenRaises (mayRaise' fi, th)
    fun flowRaises (fi, fi') = MayRaise.<= (mayRaise' fi, mayRaise' fi')
      
    val return = MayReturn.return o mayReturn'
    fun whenReturns (fi, th) = MayReturn.whenReturns (mayReturn' fi, th)
    val mayReturn = MayReturn.mayReturn o mayReturn'
    fun flowReturns (fi, fi') = MayReturn.<= (mayReturn' fi, mayReturn' fi')

    val use = Used.use o used
    val isUsed = Used.isUsed o used
    fun whenUsed (fi, th) = Used.whenUsed (used fi, th)

    val sideEffect = SideEffects.sideEffect o sideEffects
    val doesSideEffect = SideEffects.doesSideEffect o sideEffects
    fun whenSideEffects (fi, th) = SideEffects.whenSideEffects (sideEffects fi, th)
    fun flowSideEffects (fi, fi') = SideEffects.<= (sideEffects fi, sideEffects fi')

    fun new {args: (VarInfo.t * Type.t) vector, 
	     raises: (VarInfo.t * Type.t) vector option, 
	     returns: (VarInfo.t * Type.t) vector option}: t
      = T {args = args,
	   bugLabel = ref NONE,
	   mayRaise = MayRaise.new (),
	   mayReturn = MayReturn.new (),
	   raiseLabel = ref NONE,
	   raises = raises,
	   returnLabel = ref NONE,
	   returns = returns,
	   sideEffects = SideEffects.new (),
	   used = Used.new (),
	   wrappers = ref []}
  end

structure LabelInfo =
  struct
    datatype t = T of {args: (VarInfo.t * Type.t) vector,
		       catches: Catches.t,
		       func: FuncInfo.t,
		       used: Used.t,
		       wrappers: (Type.t vector * Label.t) list ref}

    fun layout (T {args, catches, used, ...}) 
      = Layout.record [("args", Vector.layout (VarInfo.layout o #1) args),
		       ("catches", Catches.layout catches),
		       ("used", Used.layout used)]
				  
    fun new {args: (VarInfo.t * Type.t) vector, func: FuncInfo.t}: t 
      = T {args = args,
	   catches = Catches.new (),
	   func = func,
	   used = Used.new (),
	   wrappers = ref []}

    local
      fun make f (T r) = f r
      fun make' f = (make f, ! o (make f))
    in
      val args = make #args
      val catches = make #catches
      val func = make #func
      val used = make #used
      val (wrappers', wrappers) = make' #wrappers
    end

    val catch = Catches.catch o catches
    val doesCatch = Catches.doesCatch o catches
    fun whenCatches (li, th) = Catches.whenCatches (catches li, th)
      
    val use = Used.use o used
    val isUsed = Used.isUsed o used
    fun whenUsed (li, th) = Used.whenUsed (used li, th)
  end


fun remove (program as Program.T {datatypes, globals, functions, main})
  = let
      val {get = varInfo: Var.t -> VarInfo.t, ...}
	= Property.get 
	  (Var.plist, 
	   Property.initFun (fn _ => VarInfo.new ()))

      val {get = typeInfo: Type.t -> TypeInfo.t, 
	   destroy, ...} 
	= Property.destGet 
	  (Type.plist, 
	   Property.initFun (fn _ => TypeInfo.new ()))

      val {get = tyconInfo: Tycon.t -> TyconInfo.t,
	   set = setTyconInfo, ...}
	= Property.getSetOnce
	  (Tycon.plist, 
	   Property.initRaise ("RemovedUnused.tyconInfo", Tycon.layout))

      val {get = conInfo: Con.t -> ConInfo.t, 
	   set = setConInfo, ...}
	= Property.getSetOnce
	  (Con.plist, 
	   Property.initRaise ("RemoveUnused.conInfo", Con.layout))
      fun newConInfo (con, args, tycon)
	= setConInfo (con, ConInfo.new {args = args, tycon = tycon})

      val {get = labelInfo: Label.t -> LabelInfo.t, 
	   set = setLabelInfo, ...}
	= Property.getSetOnce
	  (Label.plist,
	   Property.initRaise ("RemoveUnused.labelInfo", Label.layout))

      val {get = funcInfo: Func.t -> FuncInfo.t, 
	   set = setFuncInfo, ...}
	 = Property.getSetOnce
	  (Func.plist,
	   Property.initRaise ("RemoveUnused.funcInfo", Func.layout))

      val usedVar = VarInfo.used o varInfo
      val useVar = Used.use o usedVar
      fun flowVarInfoTyVarInfoTy ((vi, _), (vi', _))
	= Used.<= (VarInfo.used vi, VarInfo.used vi')
      fun flowVarInfoTysVarInfoTys (xs, ys)
	= Vector.foreach2 (xs, ys, flowVarInfoTyVarInfoTy)
      fun unifyVarInfoTysVarInfoTys (xs, ys)
	= (flowVarInfoTysVarInfoTys (xs, ys);
	   flowVarInfoTysVarInfoTys (ys, xs))
      fun flowVarInfoTyVar ((vi, _), x) 
	= Used.<= (VarInfo.used vi, usedVar x)
      fun flowVarInfoTysVars (xs, ys)
	= Vector.foreach2 (xs, ys, flowVarInfoTyVar)
      val isUsedVar = Used.isUsed o usedVar

      val visitLabelInfo = LabelInfo.use
      val visitLabelInfoTh = fn li => fn () => visitLabelInfo li
      val visitLabel = visitLabelInfo o labelInfo
      val visitLabelTh = fn l => fn () => visitLabel l
      val visitFuncInfo = FuncInfo.use
      val visitFuncInfoTh = fn fi => fn () => visitFuncInfo fi
      val visitFunc = visitFuncInfo o funcInfo
      val visitFuncTh = fn f => fn () => visitFunc f

      fun visitVar (x: Var.t) = useVar x
      fun visitVars (xs: Var.t Vector.t) = Vector.foreach (xs, visitVar)
      fun visitExp (e: Exp.t)
	= case e 
	    of ConApp {con, args}
	     => let
		  val ci = conInfo con
		  val _ = ConInfo.con ci
		  val _ = flowVarInfoTysVars (ConInfo.args ci, args)
		in
		  ()
		end
	     | PrimApp {prim, targs, args} 
	     => let
		  val _ = visitVars args
		  datatype z = datatype Type.dest
		  fun decon t
		    = let
		        val ti = typeInfo t
			val deconed = TypeInfo.deconed' ti
		      in
			if !deconed
			  then ()
			  else (deconed := true;
				case Type.dest t
				  of Datatype t
				   => Vector.foreach
				      (TyconInfo.cons (tyconInfo t), 
				       fn {con, ...} => 
				       let
					 val ci = conInfo con
					 val _ = ConInfo.decon ci
					 val _
					   = Vector.foreach
					     (ConInfo.args ci, fn (x, t) => 
					      (VarInfo.use x; decon t))
				       in
					 ()
				       end)
				   | Tuple ts => Vector.foreach (ts, decon)
				   | Vector t => decon t
				   | _ => ())
		      end
		in
		  case (Prim.name prim, Vector.length targs)
		    of (Prim.Name.MLton_eq, 1)
		     (* MLton_eq may be used on datatypes used as enums. *)
		     => decon (Vector.sub (targs, 0))
		     | (Prim.Name.MLton_equal, 1)
		     (* MLton_equal will be expanded by poly-equal into uses
		      * of constructors as patterns.
		      *)
		     => decon (Vector.sub (targs, 0))
(*		     | (Prim.Name.MLton_size, 1) => decon (Vector.sub (targs, 0)) *)
		     | _ => ()
		end
	     | Select {tuple, ...} => visitVar tuple
	     | Tuple xs => visitVars xs
	     | Var x => visitVar x
	     | _ => ()
      val visitExpTh = fn e => fn () => visitExp e
      fun maybeVisitVarExp (var, exp)
	= Option.app (var, fn var => VarInfo.whenUsed (varInfo var, visitExpTh exp))
      fun visitStatement (s: Statement.t as Statement.T {var, ty, exp},
			  fi: FuncInfo.t)
	= if Exp.maySideEffect exp
	    then (FuncInfo.sideEffect fi
		  ; visitExp exp)
	    else maybeVisitVarExp (var, exp)
      fun visitTransfer (t: Transfer.t, fi: FuncInfo.t)
	= case t
	    of Arith {args, overflow, success, ...} 
	     => (FuncInfo.sideEffect fi;
		 visitVars args;
		 visitLabel overflow;
		 visitLabel success)
	     | Bug => ()
	     | Call {func, args, return}
	     => let
		  datatype u = None
		             | Caller
		             | Some of Label.t
		  val (cont, handler)
		    = case return
			of Return.Dead => (None, None)
			 | Return.HandleOnly => (None, Caller)
			 | Return.NonTail {cont, handler}
			 => (Some cont,
			     case handler
			       of Handler.None => None
				| Handler.CallerHandler => Caller
				| Handler.Handle h => Some h)
			 | Tail => (Caller, Caller)
		  val fi' = funcInfo func
		in
		  flowVarInfoTysVars (FuncInfo.args fi', args);
		  FuncInfo.flowSideEffects (fi', fi);
		  case cont
		    of None => ()
		     | Caller 
		     => (case (FuncInfo.returns fi, FuncInfo.returns fi')
			   of (SOME xts, SOME xts')
			    => flowVarInfoTysVarInfoTys (xts, xts')
			    | _ => ();
			 FuncInfo.flowReturns (fi', fi))
		     | Some l
		     => let
			  val li = labelInfo l
			in
			  Option.app
			  (FuncInfo.returns fi', fn xts =>
			   flowVarInfoTysVarInfoTys
			   (LabelInfo.args li, xts));
			  FuncInfo.whenReturns (fi', visitLabelInfoTh li)
			end;
		  case handler
		    of None => ()
		     | Caller 
		     => (case (FuncInfo.raises fi, FuncInfo.raises fi')
			   of (SOME xts, SOME xts')
			    => (* force equality on raises *)
			       unifyVarInfoTysVarInfoTys (xts, xts')
			    | _ => ();
			 FuncInfo.flowRaises (fi', fi))
		     | Some l
		     => let
			  val li = labelInfo l
			in
			  Option.app
			  (FuncInfo.raises fi', fn xts =>
			   (* force equality on raises *)
			   unifyVarInfoTysVarInfoTys
			   (LabelInfo.args li, xts));
			  FuncInfo.whenRaises (fi', fn () => LabelInfo.catch li);
			  FuncInfo.whenRaises (fi', visitLabelInfoTh li)
			end;
		  visitFuncInfo fi'
		end
	     | Case {test, cases, default}
	     => let
		  val _ = visitVar test
		  fun doit l = (Vector.foreach (l, fn (_, l) => visitLabel l);
				Option.app (default, visitLabel))
		in
		  case cases 
		    of Cases.Char l => doit l
		     | Cases.Int l => doit l
		     | Cases.Word l => doit l
		     | Cases.Word8 l => doit l
		     | Cases.Con cases
		     => if Vector.length cases = 0
			  then Option.app (default, visitLabel)
			  else let
				 val _
				   = Vector.foreach
				     (cases, fn (con, l) =>
				      let
					val ci = conInfo con
					val _ = ConInfo.decon ci
					val li = labelInfo l
					val _
					  = flowVarInfoTysVarInfoTys
					    (LabelInfo.args li, ConInfo.args ci)
					val _ 
					  = ConInfo.whenConed
					    (ci, fn () => visitLabelInfo li)
				      in
					()
				      end)
				 val cons 
				   = TyconInfo.cons
				     (tyconInfo
				      (ConInfo.tycon 
				       (conInfo (#1 (Vector.sub (cases, 0))))))
			       in
				 case default
				   of NONE => ()
				    | SOME l
				    => let
					 val li = labelInfo l
				       in
					 Vector.foreach
					 (cons, fn {con, ...} =>
					  if Vector.exists
					      (cases, fn (c, _) => 
					       Con.equals(c, con))
					    then ()
					    else ConInfo.whenConed
					         (conInfo con, fn () => 
						  visitLabelInfo li))
				       end
			       end
		end
	     | Goto {dst, args} =>
		  let
		     val li = labelInfo dst
		     val _ = flowVarInfoTysVars (LabelInfo.args li, args)
		     val _ = visitLabelInfo li
		  in
		     ()
		  end
	     | Raise xs 
	     => (FuncInfo.raisee fi;
		 flowVarInfoTysVars (valOf (FuncInfo.raises fi), xs))
	     | Return xs 
	     => (FuncInfo.return fi;
		 flowVarInfoTysVars (valOf (FuncInfo.returns fi), xs))
	     | Runtime {args, return, ...} 
	     => (FuncInfo.sideEffect fi;
		 visitVars args;
		 visitLabel return)

      val visitTransfer
	= Trace.trace ("RemoveUnused.visitTransfer",
		       Layout.tuple2 (Transfer.layout, FuncInfo.layout),
		       Unit.layout)
	              visitTransfer
      fun visitBlock (b: Block.t as Block.T {label, statements, transfer, ...},
		      fi: FuncInfo.t) =
	 (Vector.foreach (statements, fn s => visitStatement (s, fi))
	  ; visitTransfer (transfer, fi))
      (* Visit all reachable expressions. *)
      val _ = Vector.foreach
	      (datatypes, fn Datatype.T {tycon, cons} =>
	       (setTyconInfo (tycon, TyconInfo.new {cons = cons});
		Vector.foreach (cons, fn {con, args} => 
				newConInfo (con, args, tycon))))
      val _ = let
		fun doit c
		  = let
		      val ci = conInfo c
		      val _ = ConInfo.con ci
		      val _ = ConInfo.decon ci
		    in
		      ()
		    end
	      in
		doit Con.truee ; doit Con.falsee 
	      end
      val _ = Vector.foreach 
	      (globals, fn Statement.T {var, exp, ...} => 
	       maybeVisitVarExp (var, exp))
      val _ = List.foreach
	      (functions, fn function =>
	       let
		 val {name, args, raises, returns, start, blocks, ...}
		   = Function.dest function
		 local
		   fun doitVarTys vts
		     = Vector.map (vts, fn (x, t) => (varInfo x, t))
		   fun doitTys ts
		     = Vector.map (ts, fn t => (VarInfo.new (), t))
		   fun doitTys' ts
		     = Option.map (ts, doitTys)
		 in
		   val fi = FuncInfo.new
		            {args = doitVarTys args,
			     raises = doitTys' raises,
			     returns = doitTys' returns}
		 end
		 val _ = setFuncInfo (name, fi)
		 val _ = FuncInfo.whenUsed 
		         (fi, visitLabelTh start)
		 val _
		   = Vector.foreach
		     (blocks, fn block as Block.T {label, args, ...} => 
		      let
			local
			  fun doitVarTys vts
			    = Vector.map (vts, fn (x, t) => (varInfo x, t))
			in
			  val li
			    = LabelInfo.new 
			      {args = doitVarTys args,
			       func = fi}
			end
			val _ = setLabelInfo (label, li)
			val _ = LabelInfo.whenUsed 
			        (li, fn () => visitBlock (block, fi))
		      in
			()
		      end)
	       in
		 ()
	       end)
      val _ = visitFunc main

      (* Diagnostics *)
      val _ = Control.diagnostics
	      (fn display =>
	       let open Layout
	       in 
		 Vector.foreach
		 (datatypes, fn Datatype.T {tycon, cons} =>
		  display (seq [Tycon.layout tycon,
				str ": ",
				Vector.layout
				(fn {con, ...} =>
				 seq [Con.layout con,
				      str " ",
				      ConInfo.layout (conInfo con)])
				cons]));
		 display (str "\n");
		 List.foreach
		 (functions, fn f =>
		  let
		    val {name, blocks, ...} = Function.dest f
		  in
		    display (seq [Func.layout name,
				  str ": ",
				  FuncInfo.layout (funcInfo name)]);
		    Vector.foreach
		    (blocks, fn Block.T {label, ...} =>
		     display (seq [Label.layout label,
				   str ": ",
				   LabelInfo.layout (labelInfo label)]));
		    display (str "\n")
		  end)
	       end)

      (* Analysis is done,  Now build the resulting program. *)
      val datatypes
	= Vector.keepAllMap
	  (datatypes, fn Datatype.T {tycon, cons} =>
	   let
	     val r: Exp.t option ref = ref NONE
	     val cons 
	       = Vector.keepAllMap
	         (cons, fn c as {con, args} =>
		  let
		    val c = conInfo con
		  in
		    case (ConInfo.isConed c, ConInfo.isDeconed c)
		      of (false, _) => NONE
		       | (true, true)
		       => SOME {con = con,
				args = Vector.keepAllMap
				       (ConInfo.args c, fn (x, t) =>
					if VarInfo.isUsed x
					  then SOME t
					  else NONE)}
		       | (true, false)
		       => let
			    val (e, res)
			      = case !r
				  of NONE 
				   => let
					val c = Con.newString "dummy"
					val targs = Vector.new0 ()
					val args = Vector.new0 ()
					val e = ConApp {con = c,
							args = args}
				      in
					r := SOME e ;
					newConInfo (c, targs, tycon) ;
					(e, SOME {con = c, 
						  args = targs})
				      end
				   | SOME e => (e, NONE)
			    val _ = ConInfo.dummy c := SOME e
			  in
			    res
			  end
		  end)
	     val num = Vector.length cons
	     val _ = TyconInfo.numCons' (tyconInfo tycon) := num
	   in
	     if num = 0
	       then NONE
	       else SOME (Datatype.T {tycon = tycon, cons = cons})
	   end)

      fun getWrapperLabel (l: Label.t,
			   args: (VarInfo.t * Type.t) vector)
	= let
	    val li = labelInfo l
	  in
	    if Vector.forall2 (args, LabelInfo.args li, fn ((x, _), (y, _)) =>
			       VarInfo.isUsed x = VarInfo.isUsed y)
	      then l
	      else let
		     val tys
		       = Vector.keepAllMap (args, fn (x, ty) =>
					    if VarInfo.isUsed x
					      then SOME ty
					      else NONE)
		   in 
		     case List.peek 
		          (LabelInfo.wrappers li, fn (args', l') =>
			   Vector.length args' = Vector.length tys
			   andalso
			   Vector.forall2 (args', tys, fn (ty', ty) =>
					   Type.equals (ty', ty)))
		       of SOME (_, l') => l'
			| NONE
			=> let
			     val l' = Label.newNoname ()
			     val (args', args'')
			       = Vector.unzip
			         (Vector.map2
				  (args, LabelInfo.args li, fn ((x, ty), (y, _)) =>
				   let
				     val z = Var.newNoname ()
				   in
				     (if VarInfo.isUsed x then SOME (z, ty) else NONE,
				      if VarInfo.isUsed y then SOME z else NONE)
				   end))
			     val args' = Vector.keepAllMap (args', fn x => x)
			     val (_, tys') = Vector.unzip args'
			     val args'' = Vector.keepAllMap (args'', fn x => x)
			     val block = Block.T {label = l',
						  args =  args',
						  statements = Vector.new0 (),
						  transfer = Goto {dst = l,
								   args = args''}}
			     val _ = List.push (LabelInfo.wrappers' li, (tys', l'))
			     val _ = List.push (FuncInfo.wrappers' (LabelInfo.func li),
						block)
			   in
			     l'
			   end
		   end
	  end
      val getConWrapperLabel = getWrapperLabel
      val getContWrapperLabel = getWrapperLabel
      val getHandlerWrapperLabel = getWrapperLabel
      fun getHandlerWrapperLabel' l
	= getWrapperLabel (l, LabelInfo.args (labelInfo l))
      fun getOriginalWrapperLabel l 
	= getWrapperLabel 
	  (l, Vector.map (LabelInfo.args (labelInfo l), fn (_, t) =>
			  let 
			    val x = VarInfo.new ()
			    val _ = VarInfo.use x
			  in
			    (x, t)
			  end))
      val getArithOverflowWrapperLabel = getOriginalWrapperLabel
      val getArithSuccessWrapperLabel = getOriginalWrapperLabel
      val getRuntimeWrapperLabel = getOriginalWrapperLabel
      fun getBugFunc (fi: FuncInfo.t): Label.t
	= let
	    val r = FuncInfo.bugLabel fi
	  in
	    case !r 
	      of SOME l => l
	       | NONE
	       => let
		    val l = Label.newNoname ()
		    val block = Block.T {label = l,
					 args = Vector.new0 (),
					 statements = Vector.new0 (),
					 transfer = Bug}
		    val _ = r := SOME l
		    val _ = List.push (FuncInfo.wrappers' fi, block)
		  in
		    l
		  end
	  end
      fun getReturnFunc (fi: FuncInfo.t): Label.t 
	= let
	    val r = FuncInfo.returnLabel fi
	  in
	    case !r
	      of SOME l => l
	       | NONE 
	       => let
		    val l = Label.newNoname ()
		    val returns = valOf (FuncInfo.returns fi)
		    val args
		      = Vector.keepAllMap
		        (returns, fn (vi, ty) =>
			 if VarInfo.isUsed vi
			   then SOME (Var.newNoname (), ty)
			   else NONE)
		    val xs = Vector.map (args, #1)
		    val block = Block.T {label = l,
					 args = args,
					 statements = Vector.new0 (),
					 transfer = Return xs}
		    val _ = r := SOME l
		    val _ = List.push (FuncInfo.wrappers' fi, block)
		    val _ = setLabelInfo (l, LabelInfo.new {func = fi,
							    args = returns})
		  in
		    l
		  end
	  end
      fun getReturnContFunc (fi, args) = getWrapperLabel (getReturnFunc fi, args)
      fun getRaiseFunc (fi: FuncInfo.t): Label.t
	= let
	    val r = FuncInfo.raiseLabel fi
	  in
	    case !r 
	      of SOME l => l
	       | NONE 
	       => let
		    val l = Label.newNoname ()
		    val raises = valOf (FuncInfo.raises fi)
		    val args
		      = Vector.keepAllMap
		        (raises, fn (vi, ty) =>
			 if VarInfo.isUsed vi
			   then SOME (Var.newNoname (), ty)
			   else NONE)
		    val xs = Vector.map (args, #1)
		    val block = Block.T {label = l,
					 args = args,
					 statements = Vector.new0 (),
					 transfer = Raise xs}
		    val _ = r := SOME l
		    val _ = List.push (FuncInfo.wrappers' fi, block)
		    val _ = setLabelInfo (l, LabelInfo.new {func = fi,
							    args = raises})
		  in
		    l
		  end
	  end
      fun getRaiseHandlerFunc (fi, args) = getWrapperLabel (getRaiseFunc fi, args)

      fun simplifyExp (e: Exp.t): Exp.t
	= case e 
	    of ConApp {con, args}
	     => let
		  val c = conInfo con
		in
		  if ConInfo.isDeconed c
		    then ConApp {con = con,
				 args = (Vector.keepAllMap2
					 (args, ConInfo.args c,
					  fn (x, (y, t)) =>
					  if VarInfo.isUsed y
					    then SOME x
					    else NONE))}
		    else valOf (! (ConInfo.dummy c))
		end
	     | _ => e
      val simplifyExp 
	= Trace.trace ("RemoveUnused.simplifyExp", 
		       Exp.layout, 
		       Exp.layout)
	              simplifyExp
      fun simplifyStatement (s as Statement.T {var, ty, exp},
			     f: FuncInfo.t): Statement.t option 
	= let
	    fun maybe (l, th) 
	      = if LabelInfo.doesCatch (labelInfo l)
		  then SOME (Statement.T {var = var, ty = ty, exp = th ()})
		  else NONE
	  in     
	    case exp 
	      of HandlerPop l 
	       => maybe (l, fn () => HandlerPop (getHandlerWrapperLabel' l))
	       | HandlerPush l 
	       => maybe (l, fn () => HandlerPush (getHandlerWrapperLabel' l))
	       | _ => let
			fun doit' var
			  = SOME (Statement.T {var = var,
					       ty = ty,
					       exp = simplifyExp exp})
			fun doit var'
			  = if Exp.maySideEffect exp
			      then doit' var
			      else if isSome var'
				     then doit' var'
				     else NONE
		      in
			case var
			  of SOME var => if isUsedVar var
					   then doit (SOME var)
					   else doit NONE
			   | NONE => doit NONE
		      end
	  end
      fun simplifyStatements (ss: Statement.t Vector.t,
			      fi: FuncInfo.t) : Statement.t Vector.t
	= Vector.keepAllMap (ss, fn s => simplifyStatement (s, fi))
      fun simplifyTransfer (t: Transfer.t, fi: FuncInfo.t): Transfer.t
	= case t
	    of Arith {prim, args, overflow, success, ty} 
	     => Arith {prim = prim,
		       args = args,
		       overflow = getArithOverflowWrapperLabel overflow,
		       success = getArithSuccessWrapperLabel success,
		       ty = ty}
	     | Bug => Bug
	     | Call {func, args, return}
	     => let
		  val fi' = funcInfo func
		  datatype u = None
		             | Caller
		             | Some of Label.t
		  val (cont, handler)
		    = case return
			of Return.Dead => (None, None)
			 | Return.HandleOnly => (None, Caller)
			 | Return.NonTail {cont, handler}
			 => (Some cont,
			     case handler
			       of Handler.None => None
				| Handler.CallerHandler => Caller
				| Handler.Handle h => Some h)
			 | Tail => (Caller, Caller)
		  val cont 
		    = if FuncInfo.mayReturn fi'
			then case cont 
			       of None => Error.bug "cont:None"
				| Caller
				=> if (case (FuncInfo.returns fi,
					     FuncInfo.returns fi')
					 of (SOME xts, SOME yts)
					  => Vector.forall2
					     (xts, yts, fn ((x, _), (y, _)) =>
					      VarInfo.isUsed x = VarInfo.isUsed y)
					  | _ => Error.bug "cont:Caller")
				     then Caller
				     else Some (getReturnContFunc
						(fi, valOf (FuncInfo.returns fi')))
				| Some l
			        => Some (getContWrapperLabel
					 (l, valOf (FuncInfo.returns fi')))
			else None

		  val handler
		    = if FuncInfo.mayRaise fi'
			then case handler
			       of None => Error.bug "handler:None"
				| Caller
				=> if (case (FuncInfo.raises fi,
					     FuncInfo.raises fi')
					 of (SOME xts, SOME yts)
					  => Vector.forall2
					     (xts, yts, fn ((x, _), (y, _)) =>
					      VarInfo.isUsed x = VarInfo.isUsed y)
					  | _ => Error.bug "handler:Caller")
				     then Caller
				     else Some (getRaiseHandlerFunc
						(fi, valOf (FuncInfo.raises fi')))
				| Some l
			        => Some (getHandlerWrapperLabel
					 (l, valOf (FuncInfo.raises fi')))
			else None

		  val return
		    = case (cont, handler)
			of (None, None) => Return.Dead
			 | (None, Caller) => Return.HandleOnly
			 | (None, Some h)
			 => Return.NonTail
			    {cont = getBugFunc fi,
			     handler = Handler.Handle h}
			 | (Caller, None) => Return.Tail
			 | (Caller, Caller) => Return.Tail
			 | (Caller, Some h)
			 => Return.NonTail
			    {cont = getReturnContFunc
			            (fi, valOf (FuncInfo.returns fi')),
			     handler = Handler.Handle h}
			 | (Some c, None)
			 => Return.NonTail
			    {cont = c,
			     handler = Handler.None}
			 | (Some c, Caller)
			 => Return.NonTail
			    {cont = c,
			     handler = Handler.CallerHandler}
			 | (Some c, Some h)
			 => Return.NonTail 
			    {cont = c,
			     handler = Handler.Handle h}

		  val args
		    = Vector.keepAllMap2
		      (args, FuncInfo.args fi', fn (x, (y, t)) =>
		       if VarInfo.isUsed y
			 then SOME x
			 else NONE)
		in 
		  Call {func = func,
			args = args,
			return = return}
		end 
	     | Case {test, cases = Cases.Con cases, default}
	     => let
		  val cases
		    = Vector.keepAllMap
		      (cases, fn (con, l) =>
		       let
			 val ci = conInfo con
		       in
			 if ConInfo.isConed ci
			   then SOME (con, getConWrapperLabel (l, ConInfo.args ci))
			   else NONE
		       end)
		  fun keep default = Case {test = test,
					   cases = Cases.Con cases,
					   default = default}
		  fun none () = keep NONE
		in
		  case default
		    of NONE => none ()
		     | SOME l => if Vector.length cases = 0
				   then if LabelInfo.isUsed (labelInfo l)
					  then Goto {dst = l, args = Vector.new0 ()}
					  else Bug
				   else let
					  val numCons
					    = TyconInfo.numCons
					      (tyconInfo
					       (ConInfo.tycon
						(conInfo
						 (#1 (Vector.sub (cases, 0))))))
					in 
					  if Vector.length cases = numCons
					    then none ()
					    else keep (SOME l)
					end
		end
	     | Case {test, cases, default}
	     => Case {test = test,
		      cases = cases,
		      default = default}
	     | Goto {dst, args}
	     => Goto {dst = dst, 
		      args = (Vector.keepAllMap2
			      (args, LabelInfo.args (labelInfo dst),
			       fn (x, (y, t)) => if VarInfo.isUsed y
						   then SOME x
						   else NONE))}
	     | Raise xs
	     => Raise (Vector.keepAllMap2
		       (xs, valOf (FuncInfo.raises fi),
			fn (x, (y, t)) => if VarInfo.isUsed y
					    then SOME x
					    else NONE))
	     | Return xs 
	     => Return (Vector.keepAllMap2
			(xs, valOf (FuncInfo.returns fi),
			 fn (x, (y, t)) => if VarInfo.isUsed y
					     then SOME x
					     else NONE))
	     | Runtime {prim, args, return}
	     => Runtime {prim = prim,
			 args = args,
			 return = getRuntimeWrapperLabel return}
      val simplifyTransfer
	= Trace.trace ("RemoveUnused.simplifyTransfer",
		       Layout.tuple2 (Transfer.layout, FuncInfo.layout),
		       Transfer.layout)
	              simplifyTransfer
      fun simplifyBlock (b: Block.t
			 as Block.T {label, args, 
				     statements, transfer}): Block.t option
	= let
	    val li = labelInfo label
	  in 
	    if LabelInfo.isUsed li
	      then let
		     val args
		       = Vector.keepAllMap2
		         (LabelInfo.args li, args, fn ((vi, _), (x, ty)) =>
			  if VarInfo.isUsed vi
			    then SOME (x, ty)
			    else NONE)
		     val statements
		       = simplifyStatements (statements, LabelInfo.func li)
		     val transfer
		       = simplifyTransfer (transfer, LabelInfo.func li)
		   in
		     SOME (Block.T {label = label,
				    args = args,
				    statements = statements,
				    transfer = transfer})
		   end
	      else NONE
	  end
      fun simplifyBlocks (bs: Block.t Vector.t): Block.t Vector.t
	= Vector.keepAllMap (bs, simplifyBlock)
      val globals = simplifyStatements (globals, funcInfo main)
      val shrink = shrinkFunction globals
      fun simplifyFunction (f: Function.t): Function.t option
	= let
	    val {args, blocks, name, sourceInfo, start, ...} = Function.dest f
	    val fi = funcInfo name
	  in
	    if FuncInfo.isUsed fi
	      then let
		     val args
		       = Vector.keepAllMap2
		         (FuncInfo.args fi, args, fn ((vi, _), (x, t)) =>
			  if VarInfo.isUsed vi
			    then SOME (x, t)
			    else NONE)
		     val blocks = simplifyBlocks blocks
		     val wrappers = Vector.fromList (FuncInfo.wrappers fi)
		     val blocks = Vector.concat [wrappers, blocks]
		     val returns 
		       = case FuncInfo.returns fi
			   of NONE => NONE
			    | SOME xts 
			    => if FuncInfo.mayReturn fi
				 then SOME (Vector.keepAllMap
					    (xts, fn (x, t) => 
					     if VarInfo.isUsed x
					       then SOME t
					       else NONE))
				 else NONE
		     val raises 
		       = case FuncInfo.raises fi
			   of NONE => NONE
			    | SOME xts 
			    => if FuncInfo.mayRaise fi
				 then SOME (Vector.keepAllMap
					    (xts, fn (x, t) => 
					     if VarInfo.isUsed x
					       then SOME t
					       else NONE))
				 else NONE
		   in
		      SOME (shrink (Function.new {args = args,
						  blocks = blocks,
						  name = name,
						  raises = raises,
						  returns = returns,
						  sourceInfo = sourceInfo,
						  start = start}))
		   end
	      else NONE
	  end
      fun simplifyFunctions (fs: Function.t List.t): Function.t List.t
	= List.keepAllMap (fs, simplifyFunction)
      val functions = simplifyFunctions functions
      val program = Program.T {datatypes = datatypes,
			       globals = globals,
			       functions = functions,
			       main = main}
      val _ = destroy ()
      val _ = Program.clearTop program
    in
      program
    end
 
end
