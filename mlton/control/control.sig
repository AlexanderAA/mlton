(* Copyright (C) 1997-1999 NEC Research Institute.
 * Please see the file LICENSE for license information.
 *)
type int = Int.t
   
signature CONTROL =
   sig
      val instrumentSxml: bool ref
	 
      (* set all flags to their default values *)
      val defaults: unit -> unit

      (*------------------------------------*)
      (*            Begin Flags             *)
      (*------------------------------------*)

      datatype chunk =
	 OneChunk
       | ChunkPerFunc
       | Coalesce of {limit: int}

      val chunk: chunk ref

      (* Generate an executable with debugging info. *)
      val debug: bool ref

      val defines: string list ref

      val detectOverflow: bool ref

      (* List of optimization passes to skip. *)
      val dropPasses: string list ref

      val exnHistory: bool ref
	 
      (* SOME n means that the executable should use a fixed heap of size n *)
      val fixedHeap: int option ref

      (* *)
      datatype gcCheck =
	 Limit
       | First
       | Every
      val gcCheck: gcCheck ref

      (* Indentation used in laying out ILs. *)
      val indentation: int ref
	 
      (* The .h files that should be #include'd in the .c file. *)
      val includes: string list ref
	 
      datatype inline =
	 NonRecursive of {product: int,
			  small: int}
       | Leaf of {size: int option}
       | LeafNoLoop of {size: int option}
      val inline: inline ref
      val layoutInline: inline -> Layout.t
      val setInlineSize: int -> unit

      (* The input file on the command line *)
      val inputFile: File.t ref

      (* call count instrumentation *)
      val instrument: bool ref

      (* Save the SSA to a file. *)
      val keepSSA: bool ref
	 
      (* List of pass names to keep diagnostic info on. *)
      val keepDiagnostics: string list ref

      (* Keep dot files for whatever SSA files are produced. *)
      val keepDot: bool ref

      (* List of pass names to save the result of. *)
      val keepPasses: string list ref

      datatype limitCheck =
	 (* per block *)
	 PerBlock
         (* decycle using extended basic blocks 
	  *)
       | ExtBasicBlocks
	 (* decycle using loop headers
	  *  - use full CFG
	  *  - use loop exits of non-allocatin loops
	  *)
       | LoopHeaders of {fullCFG: bool,
			 loopExits: bool}

      val limitCheck: limitCheck ref

      (* Whether or not dynamic counts of limit checks are computed. *)
      val limitCheckCounts: bool ref

      (* Number of times to loop through optimization passes. *)
      val loopPasses: int ref

      structure Native:
	 sig
	    (* whether or not to use native codegen *)
	    val native: bool ref

	    (* whether or not to use comments in native codegen *)
	    val commented: int ref

	    (* whether or not to track liveness of stack slots *)
	    val liveStack: bool ref 

	    (* level of optimization to use in native codegen *)
	    val optimize: int ref

	    (* whether or not to use move hoisting in native codegen *)
	    val moveHoist: bool ref
	       
	    (* whether or not to use copy propagation in native codegen *)
	    val copyProp: bool ref
	       
	    (* live transfer cutoff distance *)
	    val cutoff: int ref 

	    (* whether or not to use live transfer in native codegen *)
	    val liveTransfer: int ref 

	    (* size of future list for register allocation *)
	    val future: int ref
	       
	    (* whether or not to use strict IEEE floating-point in native codegen *)
	    val IEEEFP: bool ref

	    (* whether or not to split assembly file in native codegen *)
	    val split: int option ref
	 end

      (* Whether or not to use the new non-tail call return convention.
       *)
      val newReturn: bool ref

      (* Only duplicate big functions when
       * (size - small) * (number of occurrences - 1) <= product
       *)
      val polyvariance:
	 {
	  rounds: int,
	  small: int,
	  product: int
	 } option ref

      (* Elaborator inserts code to print a message on entry to each function.
       * In order to use this, the "Primitive" structure must be exported at
       * the top-level in basis-library/top-level/top-level.sml.
       *)
      val printAtFunEntry: bool ref

      (* Insert profiling information. *)
      val profile: bool ref

      (* Array bounds checking. *)
      val safe: bool ref

      (* Show the basis library used and exit. *)
      val showBasisUsed: bool ref
	 
      (* Should types be printed in ILs. *)
      val showTypes: bool ref

      (* Force continuation formals to stack. *)
      val stackCont: bool ref 

      (* Generate a statically linked executable. *)
      val static: bool ref

      (* Type check ILs. *)
      val typeCheck: bool ref
	 
      (* Should the basis library be prefixed onto the program. *)
      val useBasisLibrary: bool ref

      datatype verbosity =
	 Silent
       | Top
       | Pass
       | Detail
      val verbosity: verbosity ref

      (*------------------------------------*)
      (*             End Flags              *)
      (*------------------------------------*)

      (* Tracing and other informative messages.
       * Some take a verbosity argument that specifies the verbosity level at
       * which messages should be printed. 
       *)
      val message: verbosity * (unit -> Layout.t) -> unit
      val messageStr: verbosity * string -> unit
      val sizeMessage: string * 'a -> Layout.t
      val trace: verbosity * string -> ('a -> 'b) -> 'a -> 'b
      type traceAccum
      val traceAccum: verbosity * string -> (traceAccum * (unit -> unit))
      val traceAdd: traceAccum * string -> ('a -> 'b) -> 'a -> 'b
      val traceBatch: verbosity * string -> ('a -> 'b) -> 
                      (('a -> 'b) * (unit -> unit))
      val indent: unit -> unit
      val unindent: unit -> unit
      val getDepth: unit -> int

      (*------------------------------------*)
      (*          Error Reporting           *)
      (*------------------------------------*)
      (* abort compilation once this many errors reached *)
      val errorThreshhold: int ref
      val error: Region.t * Layout.t -> unit
      val errorStr: Region.t * string -> unit
      val checkForErrors: string -> unit
	 
      (*------------------------------------*)
      (*          Compiler Passes           *)
      (*------------------------------------*)
      datatype style = No | Assembly | C | Dot | ML

      datatype 'a display =
	 NoDisplay
       | Layout of 'a -> Layout.t
       | Layouts of 'a * (Layout.t -> unit) -> unit

      val diagnostic: (unit -> Layout.t) -> unit
      val diagnostics: ((Layout.t -> unit) -> unit) -> unit
      val maybeSaveToFile:
	 {name: string, suffix: string} * style * 'a * 'a display -> unit
      val saveToFile:
	 {suffix: string} * style * 'a * 'a display -> unit
      val outputHeader: style * (Layout.t -> unit) -> unit
      val outputHeader': style * Out.t -> unit

      val pass: {name: string,
		 suffix: string,
		 style: style,
		 thunk: unit -> 'a,
		 display: 'a display} ->'a
	 
      val passTypeCheck: {name: string,
			  suffix: string,
			  style: style,
			  thunk: unit -> 'a,
			  display: 'a display,
			  typeCheck: 'a -> unit} -> 'a
	 
      val passSimplify: {name: string,
			 suffix: string,
			 style: style,
			 thunk: unit -> 'a,
			 display: 'a display,
			 simplify: 'a -> 'a,
			 typeCheck: 'a -> unit} -> 'a
   end
