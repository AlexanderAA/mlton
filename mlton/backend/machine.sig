(* Copyright (C) 1997-1999 NEC Research Institute.
 * Please see the file LICENSE for license information.
 *)
type int = Int.t
type word = Word.t
   
signature MACHINE_STRUCTS = 
   sig
      structure MachineOutput: MACHINE_OUTPUT
   end

signature MACHINE = 
   sig
      structure MachineOutput: MACHINE_OUTPUT
     
      structure Label: ID sharing Label = MachineOutput.Label
      structure ChunkLabel: UNIQUE_ID
      structure Prim: PRIM
      structure Type: MTYPE

      structure Register:
	 sig
	    type t

	    val equals: t * t -> bool
	    val layout: t -> Layout.t
	    val ty: t -> Type.t
	 end

      structure Global:
	 sig
	    type t

	    val equals: t * t -> bool
	    val ty: t -> Type.t
	 end

      structure Operand:
	 sig
	    type t

	    val arrayOffset: {base: t, offset: t, ty: Type.t} -> t
	    val castInt: t -> t (* takes an IntOrPointer and makes it an int *)
	    val char: char -> t
	    val contents: t * Type.t -> t
	    val deRegister: t -> Register.t option
	    val deStackOffset: t -> {offset: int, ty: Type.t} option
	    val equals: t * t -> bool
	    val float: string -> t
	    val int: int -> t
	    val intInf: Word.t -> t
	    val interfere: {write: t, read: t} -> bool
	    val label: Label.t -> t
	    val layout: t -> Layout.t
	    val offset: {base: t, offset: int, ty: Type.t} -> t
	    val pointer: int -> t (* In (pointer n), n must be nonzero mod 4. *)
	    val register: Register.t -> t
	    val stackOffset: {offset: int, ty: Type.t} -> t
	    val ty: t -> Type.t
	    val uint: word -> t
	 end

      (* GCInfo.t is the information that the garbage collector needs to know
       * at a program point in order to do a collection.
       *)
      structure GCInfo:
	 sig
	    type t

	    val layout: t -> Layout.t
	    val make:
	       {(* Size of stack frame in bytes, including return address. *)
		frameSize: int,
		(* Live pointer valued stack offsets.  It should not contain
		 * duplicates.
		 *) 
		offsets: int list
		} -> t
	 end

      structure LimitCheck:
	 sig
	    datatype t =
	       No
	     | Maybe of GCInfo.t
	     | Yes of GCInfo.t
	     | Stack of GCInfo.t

	    val layout: t -> Layout.t
	 end

      structure PrimInfo:
	 sig
	    datatype t =
	       None
	     | Overflow of Label.t
	 end

      structure Statement:
	 sig
	    type t

	    (* Fixed-size allocation. *)
	    val allocate:
	       {dst: Operand.t,
		size: int,
		numPointers: int,
		numWordsNonPointers: int,
		stores: {offset: int,
			 value: Operand.t} list
		} -> t
	    (* Variable-sized allocation. *)
	    val allocateArray: {dst: Operand.t,
				numElts: Operand.t,
				numPointers: int,
				numBytesNonPointers: int,
				gcInfo: GCInfo.t
				} -> t
	    val assign: {dst: Operand.t option,
			 oper: Prim.t,
			 pinfo: PrimInfo.t,
			 args: Operand.t vector,
			 info: GCInfo.t option} -> t
	    val layout: t -> Layout.t
	    val limitCheck: LimitCheck.t -> t
	    (* When registers or offsets appear in operands, there is an
	     * implicit contents of.
	     * When they appear as locations, there is not.
	     *)
	    val move: {dst: Operand.t, src: Operand.t} -> t
	    (* Error if dsts and srcs aren't of same length. *)
	    val moves: {
			dsts: Operand.t list,
			srcs: Operand.t list
		       } -> t list
	    (* pop number of bytes from stack *)
	    val pop: int -> t
	    (* push number of bytes from stack *)
	    val push: int -> t
	    val restoreExnStack: {offset: int} -> t
	    val saveExnStack: {offset: int} -> t
	 end

      structure Cases: MACHINE_CASES sharing Label = Cases.Label

      structure Transfer:
	 sig
	    type t

	    val bug: t
	    val farJump: {chunkLabel: ChunkLabel.t,
			  label: Label.t} -> t
	    val isSwitch: t -> bool
	    val layout: t -> Layout.t
	    val nearJump: {label: Label.t} -> t
	    val return: t
	    val raisee: t
	    val switch: {
			 test: Operand.t,
			 cases: Cases.t,
			 default: Label.t option
			} -> t
	    (* Switch to one of two labels, based on whether the operand is an
	     * Integer or a Pointer.  Pointers are word aligned and integers
	     * are not.
	     *)
	    val switchIP: {
			   test: Operand.t,
			   int: Label.t,
			   pointer: Label.t
			  } -> t
	    val toMOut: t -> MachineOutput.Transfer.t
	 end

      structure Chunk:
	 sig
	    type t

	    val label: t -> ChunkLabel.t
	    val equals: t * t -> bool
	    val newBlock: 
	       t * {
		    label: Label.t,
		    live: Register.t list,
		    profileName: string,
		    statements: Statement.t list,
		    transfer: Transfer.t
		   } -> unit
	    val register: t * int * Type.t -> Register.t
	    val tempRegister: t * Type.t -> Register.t
	 end

      structure Program:
	 sig
	    type t

	    val clear: t -> unit
	    val new: unit -> t
	    val newChunk: {program: t,
			   entries: Label.t list} -> Chunk.t
	    val newFrame:
	       t * {return: Label.t, (* where to return to *)
		    chunkLabel: ChunkLabel.t,
		    (* Number of bytes in frame, including return address. *)
		    size: int,
		    (* The locations of live pointers in the current stack frame
		     * relative to the stack pointer of the frame below.
		     *)
		    liveOffsets: int list
		    } -> unit
	    val newGlobal: t * Type.t -> Operand.t
	    (* A global pointer that the GC doesn't use as a root *)
	    val newGlobalPointerNonRoot: t -> Operand.t
	    val newHandler: t * {chunkLabel: ChunkLabel.t, 
				 label: Label.t} -> unit
	    val newString: t * string -> Operand.t
	    val newIntInf: t * string -> Operand.t
	    val newFloat: t * string -> Operand.t
	    val setMain: t * {chunkLabel: ChunkLabel.t, label: Label.t} -> unit
	    val toMachineOutput: t -> MachineOutput.Program.t
	 end
   end
