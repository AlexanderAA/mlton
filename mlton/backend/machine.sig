(* Copyright (C) 1997-1999 NEC Research Institute.
 * Please see the file LICENSE for license information.
 *)
type int = Int.t
type word = Word.t
   
signature MACHINE_STRUCTS = 
   sig
      structure Label: HASH_ID
      structure Prim: PRIM
   end

signature MACHINE = 
   sig
      include MACHINE_STRUCTS
	 
      structure ChunkLabel: UNIQUE_ID
      structure Type: MTYPE

      structure Register:
	 sig
	    datatype t = T of {index: int,
			       ty: Type.t}

	    val equals: t * t -> bool
	    val index: t -> int
	    val layout: t -> Layout.t
	    val toString: t -> string
	    val ty: t -> Type.t
	 end

      structure Global:
	 sig
	    datatype t = T of {index: int,
			       ty: Type.t}

	    val equals: t * t -> bool
	    val index: t -> int
	    val layout: t -> Layout.t
	    val toString: t -> string
	    val ty: t -> Type.t
	 end

      structure Operand:
	 sig
	    datatype t =
	       ArrayOffset of {base: t,
			       offset: t,
			       ty: Type.t}
	     | CastInt of t (* takes an IntOrPointer and makes it an int *)
	     | Char of char
	     | Contents of {oper: t,
			    ty: Type.t}
	     | Float of string 
	     | Global of Global.t
	     | GlobalPointerNonRoot of int
	     | Int of int
	     | IntInf of word
	     | Label of Label.t
	     | Offset of {base: t,
			  offset: int,
			  ty: Type.t}
	     | Pointer of int (* In (Pointer n), n must be nonzero mod 4. *)
	     | Register of Register.t
	     | StackOffset of {offset: int,
			       ty: Type.t}
	     | Uint of Word.t


	    val deRegister: t -> Register.t option
	    val deStackOffset: t -> {offset: int, ty: Type.t} option
	    val equals: t * t -> bool
	    val intInf: Word.t -> t
	    val interfere: {write: t, read: t} -> bool
	    val isPointer: t -> bool
	    val label: Label.t -> t
	    val layout: t -> Layout.t
	    val toString: t -> string
	    val ty: t -> Type.t
	    val uint: word -> t
	 end

      structure Statement:
	 sig
	    datatype t =
	       (* Fixed-size allocation. *)
	       Allocate of {dst: Operand.t,
			    numPointers: int,
			    numWordsNonPointers: int,
			    size: int,
			    stores: {offset: int,
				     value: Operand.t} vector}
	     (* Variable-sized allocation. *)
	     | Array of {dst: Operand.t,
			 numElts: Operand.t,
			 numPointers: int,
			 numBytesNonPointers: int}
	     | Assign of {dst: Operand.t option,
			  prim: Prim.t, 
			  args: Operand.t vector}
	     (* When registers or offsets appear in operands, there is an
	      * implicit contents of.
	      * When they appear as locations, there is not.
	      *)
	     | Move of {dst: Operand.t,
			src: Operand.t}
	     | Noop
	     | SetExnStackLocal of {offset: int}
	     | SetExnStackSlot of {offset: int}
	     | SetSlotExnStack of {offset: int}

	    val layout: t -> Layout.t
	    val move: {dst: Operand.t, src: Operand.t} -> t
	    (* Error if dsts and srcs aren't of same length. *)
	    val moves: {dsts: Operand.t vector,
			srcs: Operand.t vector} -> t vector
	 end

      structure Cases: MACHINE_CASES sharing Label = Cases.Label

      structure LimitCheck:
	 sig
	    datatype t =
	       Array of {bytesPerElt: int, (* > 0 *)
			 extraBytes: int, (* for subsequent allocation *)
			 numElts: Operand.t, (* not an int *)
			 stackToo: bool}
	     | Heap of {bytes: int,
			stackToo: bool}
	     | Signal
	     | Stack
	 end
   
      structure Transfer:
	 sig
	    datatype t =
	       (* In an arith transfer, dst is modified whether or not the
		* prim succeeds.
		*)
	       Arith of {prim: Prim.t,
			 args: Operand.t vector,
			 dst: Operand.t,
			 overflow: Label.t,
			 success: Label.t}
	     | Bug
	     | CCall of {args: Operand.t vector,
			 prim: Prim.t,
			 return: Label.t, (* return should be nullary if the
					   * C function returns void.  Else,
					   * return should be either nullary or
					   * unary with a var of the appropriate
					   * type to accept the result.
					   *)
			 returnTy: Type.t option}
	     | FarJump of {chunkLabel: ChunkLabel.t,
			   label: Label.t,
			   live: Operand.t list,
			   return: {return: Label.t,
				    handler: Label.t option,
				    size: int} option}
	     | LimitCheck of {failure: Label.t, (* Must be of Runtime kind. *)
			      kind: LimitCheck.t,
			      success: Label.t} (* Must be of Jump kind. *)
	     | NearJump of {label: Label.t,
			    return: {return: Label.t,
				     handler: Label.t option,
				     size: int} option}
	     | Raise
	     | Return of {live: Operand.t list}
	     | Runtime of {args: Operand.t vector,
			   prim: Prim.t,
			   return: Label.t} (* Must be of Runtime kind. *)
	     | Switch of {test: Operand.t,
			  cases: Cases.t,
			  default: Label.t option}
	     (* Switch to one of two labels, based on whether the operand is an
	      * Integer or a Pointer.  Pointers are word aligned and integers
	      * are not.
	      *)
	     | SwitchIP of {test: Operand.t,
			    int: Label.t,
			    pointer: Label.t}

	    val layout: t -> Layout.t
	 end

      structure FrameInfo:
	 sig
	    datatype t =
	       T of {(* Index into frameOffsets *)
		     offsetIndex: int,
		     (* Size of frame in bytes, including return address. *)
		     size: int}

	    val bogus: t
	    val size: t -> int
	 end
      
      structure Kind:
	 sig
	    datatype t =
	       Cont of {args: Operand.t list,
			frameInfo: FrameInfo.t}
	     | CReturn of {arg: Operand.t,
			   ty: Type.t} option
	     | Func of {args: Operand.t list}
	     | Handler of {offset: int}
	     | Jump
	     | Runtime of {frameInfo: FrameInfo.t}
	 end
      
      structure Block:
	 sig
	    datatype t =
	       T of {kind: Kind.t,
		     label: Label.t,
		     (* Live registers and stack offsets at beginning of block. *)
		     live: Operand.t list,
		     profileInfo: {func: string, label: string},
		     statements: Statement.t vector,
		     transfer: Transfer.t}

	    val label: t -> Label.t
	 end

      structure Chunk:
	 sig
	    datatype t = T of {chunkLabel: ChunkLabel.t,
			       blocks: Block.t vector,
			       (* for each type, gives the max # regs used *)
			       regMax: Type.t -> int}
	 end

      structure Program:
	 sig
	    datatype t =
	       T of {chunks: Chunk.t list,
		     floats: (Global.t * string) list,
		     frameOffsets: int vector vector,
		     globals: Type.t -> int,
		     globalsNonRoot: int,
		     intInfs: (Global.t * string) list,
		     main: {chunkLabel: ChunkLabel.t,
			    label: Label.t},
		     maxFrameSize: int,
		     strings: (Global.t * string) list}

	    val layouts: t * (Layout.t -> unit) -> unit
	    val typeCheck: t -> unit
	 end
   end
