(* Copyright (C) 1999-2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type int = Int.t
type word = Word.t

signature RSSA_STRUCTS = 
   sig
      include ATOMS

      structure Handler: HANDLER
      structure Return: RETURN
      sharing Handler = Return.Handler
      sharing Label = Handler.Label
   end

signature RSSA = 
   sig
      include RSSA_STRUCTS

      structure Switch: SWITCH
      sharing Atoms = Switch

      structure Type: REP_TYPE
      sharing Type = RepType
     
      structure Operand:
	 sig
	    datatype t =
	       ArrayOffset of {base: t,
			       index: t,
			       ty: Type.t}
	     | Cast of t * Type.t
	     | Const of Const.t
	       (* EnsuresBytesFree is a pseudo-op used by C functions (like
		* GC_allocateArray) that take a number of bytes as an argument
		* and ensure that that number of bytes is free upon return.
		* EnsuresBytesFree is replaced by the limit check pass with
		* a real operand.
		*)
	     | EnsuresBytesFree
	     | File (* expand by codegen into string constant *)
	     | GCState
	     | Line (* expand by codegen into int constant *)
	     | Offset of {base: t,
			  offset: Bytes.t,
			  ty: Type.t}
	     | PointerTycon of PointerTycon.t
	     | Runtime of Runtime.GCField.t
	     | SmallIntInf of word
	     | Var of {ty: Type.t,
		       var: Var.t}

	    val bool: bool -> t
	    val caseBytes: t * {big: t -> 'a,
				small: Bytes.t -> 'a} -> 'a
	    val cast: t * Type.t -> t
	    val int: IntX.t -> t
	    val layout: t -> Layout.t
	    val foreachVar: t * (Var.t -> unit) -> unit
	    val ty: t -> Type.t
	    val word: WordX.t -> t
	 end
      sharing Operand = Switch.Use
    
      structure Statement:
	 sig
	    datatype t =
	       Bind of {isMutable: bool,
			oper: Operand.t,
			var: Var.t}
	     | Move of {dst: Operand.t,
			src: Operand.t}
	     | Object of {dst: Var.t * Type.t,
			  header: word,
			  size: Bytes.t, (* including header *)
			  (* The stores are in increasing order of offset. *)
			  stores: {offset: Bytes.t,
				   value: Operand.t} vector}
	     | PrimApp of {args: Operand.t vector,
			   dst: (Var.t * Type.t) option,
			   prim: Prim.t}
	     | Profile of ProfileExp.t
	     | ProfileLabel of ProfileLabel.t
	     | SetExnStackLocal
	     | SetExnStackSlot
	     | SetHandler of Label.t (* label must be of Handler kind. *)
	     | SetSlotExnStack

	    (* foldDef (s, a, f)
	     * If s defines a variable x, then return f (x, a), else return a.
	     *)
	    val foldDef: t * 'a * (Var.t * Type.t * 'a -> 'a) -> 'a
	    (* foreachDef (s, f) = foldDef (s, (), fn (x, ()) => f x) *)
	    val foreachDef: t * (Var.t * Type.t -> unit) -> unit
	    val foreachDefUse: t * {def: (Var.t * Type.t) -> unit,
				    use: Var.t -> unit} -> unit
	    val foldUse: t * 'a * (Var.t * 'a -> 'a) -> 'a
	    val foreachUse: t * (Var.t -> unit) -> unit
	    val layout: t -> Layout.t
	    val toString: t -> string
	 end

      structure Transfer:
	 sig
	    datatype t =
	       Arith of {args: Operand.t vector,
			 dst: Var.t,
			 overflow: Label.t, (* Must be nullary. *)
			 prim: Prim.t,
			 success: Label.t, (* Must be nullary. *)
			 ty: Type.t}
	     | CCall of {args: Operand.t vector,
			 func: CFunction.t,
			 (* return is NONE iff the CFunction doesn't return.
			  * Else, return must be SOME l, where l is of kind
			  * CReturn.  The return should be nullary if the C
			  * function returns void.  Else, it should be unary with
			  * a var of the appropriate type to accept the result.
			  *)
			 return: Label.t option}
	     | Call of {args: Operand.t vector,
			func: Func.t,
			return: Return.t}
	     | Goto of {args: Operand.t vector,
			dst: Label.t}
	     (* Raise implicitly raises to the caller.  
	      * I.E. the local handler stack must be empty.
	      *)
	     | Raise of Operand.t vector
	     | Return of Operand.t vector
	     | Switch of Switch.t

	    val bug: t
	    (* foldDef (t, a, f)
	     * If t defines a variable x, then return f (x, a), else return a.
	     *)
	    val foldDef: t * 'a * (Var.t * Type.t * 'a -> 'a) -> 'a
	    (* foreachDef (t, f) = foldDef (t, (), fn (x, ()) => f x) *)
	    val foreachDef: t * (Var.t * Type.t -> unit) -> unit
	    val foreachDefLabelUse: t * {def: Var.t * Type.t -> unit,
					 label: Label.t -> unit,
					 use: Var.t -> unit} -> unit
	    val foreachLabel: t * (Label.t -> unit) -> unit
	    val foreachUse: t * (Var.t -> unit) -> unit
	    val ifBool: Operand.t * {falsee: Label.t, truee: Label.t} -> t
	    (* in ifZero, the operand should be of type defaultWord *)
	    val ifZero: Operand.t * {falsee: Label.t, truee: Label.t} -> t
	    val layout: t -> Layout.t
	 end

      structure Kind:
	 sig
	    datatype t =
	       Cont of {handler: Handler.t}
	     | CReturn of {func: CFunction.t}
	     | Handler
	     | Jump

	    datatype frameStyle = None | OffsetsAndSize | SizeOnly
	    val frameStyle: t -> frameStyle
	 end

      structure Block:
	 sig
	    datatype t =
	       T of {args: (Var.t * Type.t) vector,
		     kind: Kind.t,
		     label: Label.t,
		     statements: Statement.t vector,
		     transfer: Transfer.t}

	    val args: t -> (Var.t * Type.t) vector
	    val clear: t -> unit
	    val kind: t -> Kind.t
	    val label: t -> Label.t
	    val statements: t -> Statement.t vector
	    val transfer: t -> Transfer.t
	 end

      structure Function:
	 sig
	    type t
	       
	    val blocks: t -> Block.t vector
	    val clear: t -> unit
	    val dest: t -> {args: (Var.t * Type.t) vector,
			    blocks: Block.t vector,
			    name: Func.t,
			    raises: Type.t vector option,
			    returns: Type.t vector option,
			    start: Label.t}
	    (* dfs (f, v) visits the blocks in depth-first order, applying v b
	     * for block b to yield v', then visiting b's descendents,
	     * then applying v' ().
	     *)
	    val dfs: t * (Block.t -> unit -> unit) -> unit
	    val name: t -> Func.t
	    val new: {args: (Var.t * Type.t) vector,
		      blocks: Block.t vector,
		      name: Func.t,
		      raises: Type.t vector option,
		      returns: Type.t vector option,
		      start: Label.t} -> t
	    val start: t -> Label.t
	 end
     
      structure Program:
	 sig
	    datatype t =
	       T of {functions: Function.t list,
		     handlesSignals: bool,
		     main: Function.t,
		     objectTypes: ObjectType.t vector}

	    val clear: t -> unit
	    val checkHandlers: t -> unit
	    val layouts: t * (Layout.t -> unit) -> unit
	    val typeCheck: t -> unit
	 end
   end
