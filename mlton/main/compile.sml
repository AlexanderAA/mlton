(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
structure Compile: COMPILE =
struct

(*---------------------------------------------------*)
(*              Intermediate Languages               *)
(*---------------------------------------------------*)
   
structure Ast = Ast ()
structure Atoms = Atoms (structure Ast = Ast)
structure CoreML = CoreML (open Atoms
			   structure Type = Prim.Type)
structure Xml = Xml (open Atoms)
structure Sxml = Xml
structure Ssa = Ssa (open Atoms)
structure Runtime = Runtime ()
structure Machine = Machine (structure Label = Ssa.Label
			     structure Prim = Atoms.Prim
			     structure Runtime = Runtime)

(*---------------------------------------------------*)
(*                  Compiler Passes                  *)
(*---------------------------------------------------*)

structure FrontEnd = FrontEnd (structure Ast = Ast)
structure DeadCode = DeadCode (structure CoreML = CoreML)
structure Elaborate = Elaborate (structure Ast = Ast
				 structure CoreML = CoreML)
structure LookupConstant = LookupConstant (structure CoreML = CoreML)
structure Infer = Infer (structure CoreML = CoreML
			 structure LookupConstant = LookupConstant
			 structure Xml = Xml)
structure Monomorphise = Monomorphise (structure Xml = Xml
				       structure Sxml = Sxml)
structure ImplementExceptions = ImplementExceptions (open Sxml)
structure Polyvariance = Polyvariance (open Sxml)
structure ClosureConvert = ClosureConvert (structure Ssa = Ssa
					   structure Sxml = Sxml)
structure Backend = Backend (structure Ssa = Ssa
			     structure Machine = Machine
			     fun funcToLabel f = f)
structure CCodegen = CCodegen (structure Machine = Machine)
structure x86Codegen = x86Codegen (structure CCodegen = CCodegen
				   structure Machine = Machine)

local open Elaborate
in 
   structure Decs = Decs
   structure Env = Env
end
   
(* ------------------------------------------------- *)
(*                 parseAndElaborate                 *)
(* ------------------------------------------------- *)

val (lexAndParse, lexAndParseMsg) =
   Control.traceBatch (Control.Pass, "lex and parse") FrontEnd.lexAndParse

val (elaborate, elaborateMsg) =
   Control.traceBatch (Control.Pass, "elaborate") Elaborate.elaborateProgram

fun parseAndElaborateFile (f: File.t, E): Decs.t =
   let
      val ast = lexAndParse f
      val _ = Control.checkForErrors "parse"
      val res = elaborate (ast, E)
      val _ = Control.checkForErrors "elaborate"
   in res
   end

val displayDecs =
   Control.Layout
   (fn ds => CoreML.Program.layout (CoreML.Program.T
				    {decs = Decs.toVector ds}))
   
fun parseAndElaborateFiles (fs: File.t list, E: Env.t): Decs.t =
   Control.pass
   {name = "parseAndElaborate",
    suffix = "core-ml",
    style = Control.ML,
    thunk = fn () => List.fold (fs, Decs.empty, fn (f, ds) =>
				Decs.append (ds, parseAndElaborateFile (f, E))),
    display = displayDecs}

(* ------------------------------------------------- *)   
(*                   Primitive Env                   *)
(* ------------------------------------------------- *)

local
   open CoreML
   open Scheme Type
in
   val primitiveDatatypes =
      Vector.new3
      ({tycon = Tycon.bool,
	tyvars = Vector.new0 (),
	cons = Vector.new2 ({con = Con.falsee, arg = NONE},
			    {con = Con.truee, arg = NONE})},
       let val a = Tyvar.newNoname {equality = false}
       in {tycon = Tycon.list,
	   tyvars = Vector.new1 a,
	   cons = Vector.new2 ({con = Con.nill, arg = NONE},
			       {con = Con.cons,
				arg = SOME (tuple
					    (Vector.new2
					     (var a, list (var a))))})}
       end,
       let val a = Tyvar.newNoname {equality = false}
       in {tycon = Tycon.reff,
	   tyvars = Vector.new1 a,
	   cons = Vector.new1 {con = Con.reff, arg = SOME (var a)}}
       end)
end

val primitiveExcons =
   let open CoreML.Con
   in [bind, match, overflow]
   end

structure Env =
   struct
      open Env 

      fun addPrim (E: t): unit =
	 let
	    open CoreML
	    val _ =
	       List.foreach
	       (Tycon.prims, fn tycon =>
		extendTycon
		(E, Ast.Tycon.fromString (Tycon.originalName tycon,
					  Region.bogus),
		 TypeStr.tycon tycon))
	    val _ =
	       Vector.foreach
	       (primitiveDatatypes, fn {tyvars, tycon, cons} =>
		let
		   val cs =
		      Vector.map
		      (cons, fn {con, arg} =>
		       let
			  val resultType =
			     Type.con (tycon, Vector.map (tyvars, Type.var))
		       (* 		    val scheme =
			* 		       Scheme.T
			* 		       {tyvars = tyvars,
			* 			ty = (case arg of
			* 				 NONE => resultType
			* 			       | SOME t => Type.arrow (t, resultType))}
			*)
		       in {name = Con.toAst con,
			   con = con}
		       end)
		   val _ =
		      Vector.foreach (cs, fn {name, con} =>
				      extendCon (E, name, con))
		in extendTycon (E, Tycon.toAst tycon,
				TypeStr.data (tycon, cs))
		end)
	    val _ = extendTycon (E, Ast.Tycon.fromString ("unit", Region.bogus),
				 TypeStr.def (Scheme.make0 Type.unit))
	    val _ = addEquals E
	    val _ = List.foreach (primitiveExcons, fn c =>
				  extendCon (E, Con.toAst c, c))
	 in ()
	 end
   end

(* ------------------------------------------------- *)
(*                   Basis Library                   *)
(* ------------------------------------------------- *)

val basisEnv = Env.empty ()

local
   val dir = ref NONE
in
   fun setBasisLibraryDir (d: Dir.t): unit =
      dir := SOME d
   val basisLibrary =
      Promise.lazy
      (fn () =>
       let
	  val d =
	     case !dir of
		NONE => Error.bug "basis library dir not set"
	      | SOME d => d
	  fun basisFile f = String./ (d, f)
	  fun files (f, E) =
	     parseAndElaborateFiles
	     (rev (File.foldLines (basisFile f, [], fn (s, ac) =>
				   if s <> "\n" andalso #"#" <> String.sub (s, 0)
				      then basisFile (String.dropLast s) :: ac
				   else ac)),
	      basisEnv)
	  val (d1, (d2, d3)) =
	     Env.localTop
	     (basisEnv,
	      fn () => (Env.addPrim basisEnv
			; files ("build-basis", basisEnv)),
	      fn () =>
	      (files ("bind-basis", basisEnv),
	       (* Suffix is concatenated onto the end of the program for cleanup. *)
	       parseAndElaborateFiles ([basisFile "misc/suffix.sml"], basisEnv)))
	  val _ = Env.addEquals basisEnv
	  val _ = Env.clean basisEnv
       in
	  {prefix = Decs.append (d1, d2),
	   suffix = d3}
       end)
end

fun forceBasisLibrary d =
   (setBasisLibraryDir d
    ; basisLibrary ()
    ; ())
   
fun basisDecs () =
   let
      val {prefix, ...} = basisLibrary ()
   in
      Decs.toVector prefix
   end
   
fun outputBasisConstants (out: Out.t): unit =
   LookupConstant.build (basisDecs (), out)

fun layoutBasisLibrary () = Env.layoutPretty basisEnv

(* ------------------------------------------------- *)
(*                      compile                      *)
(* ------------------------------------------------- *)

fun preCodegen {input, docc}: Machine.Program.t =
   let
      fun parseElabMsg () = (lexAndParseMsg (); elaborateMsg ())
      val primitiveDecs: CoreML.Dec.t vector =
	 let
	    open CoreML.Dec
	    fun make n = makeRegion (n, Region.bogus)
	 in
	    Vector.concat [Vector.new1 (make (Datatype primitiveDatatypes)),
			   Vector.fromListMap
			   (primitiveExcons, fn c =>
			    make (Exception {con = c, arg = NONE}))]
	 end
      val decs =
	 if !Control.useBasisLibrary
	    then
	       let
		  val {prefix, suffix} = basisLibrary ()
		  val basis = Decs.toList prefix
		  val decs =
		     if !Control.showBasisUsed
			then
			   let
			      val decs = 
				 Elaborate.Env.scopeAll
				 (basisEnv, fn () =>
				  parseAndElaborateFiles (input, basisEnv))
			      val _ =
				 Layout.outputl
				 (Elaborate.Env.layoutUsed basisEnv,
				  Out.standard)
			   in
			      Process.succeed ()
			   end
		     else
			parseAndElaborateFiles (input, basisEnv)
		  val user = Decs.toList (Decs.append (decs, suffix))
		  val _ = parseElabMsg ()
		  val basis =
		     Control.pass
		     {name = "dead",
		      suffix = "basis",
		      style = Control.ML,
		      thunk = fn () => DeadCode.deadCode {basis = basis,
							  user = user},
		      display = Control.Layout (List.layout CoreML.Dec.layout)}
	       in Vector.concat [primitiveDecs,
				 Vector.fromList basis,
				 Vector.fromList user]
	       end
	 else
	    let
	       val E = Env.empty ()
	       val _ = Env.addPrim E
	       val decs = parseAndElaborateFiles (input, E)
	       val _ = parseElabMsg ()
	    in Vector.concat [primitiveDecs, Decs.toVector decs]
	    end
      val coreML = CoreML.Program.T {decs = decs}
      val _ = Control.message (Control.Detail, fn () =>
			       CoreML.Program.layoutStats coreML)
      val buildConstants =
	 let
	    datatype z = datatype LookupConstant.Const.t
	    open Control
	 in
	    [("Exn_keepHistory", Bool (!exnHistory)),
	     ("MLton_debug", Bool (!debug)),
	     ("MLton_detectOverflow", Bool (!detectOverflow)),
	     ("MLton_native", Bool (!Native.native)),
	     ("MLton_profile", Bool (!profile)),
	     ("MLton_safe", Bool (!safe)),
	     ("TextIO_bufSize", Int (!textIOBufSize))]
	 end
      fun lookupBuildConstant (c: string) =
	 case List.peek (buildConstants, fn (c', _) => c = c') of
	    NONE => Error.bug (concat ["strange build constant: ", c])
	  | SOME (_, v) => v
      val lookupConstant =
	 File.withIn
	 (concat [!Control.libDir, "/constants"], fn ins =>
	  LookupConstant.load (basisDecs (), ins))
      (* Set GC_state offsets. *)
      val _ =
	 let
	    fun get s =
	       case lookupConstant s of
		  LookupConstant.Const.Int n => n
		| _ => Error.bug "GC_state offset must be an int"
	 in
	    Runtime.GCField.setOffsets
	    {
	     base = get "base",
	     canHandle = get "canHandle",
	     currentThread = get "currentThread",
	     fromSize = get "fromSize",
	     frontier = get "frontier",
	     limit = get "limit",
	     limitPlusSlop = get "limitPlusSlop",
	     maxFrameSize = get "maxFrameSize",
	     signalIsPending = get "signalIsPending",
	     stackBottom = get "stackBottom",
	     stackLimit = get "stackLimit",
	     stackTop = get "stackTop"
	     }
	 end
      val xml =
	 Control.passSimplify
	 {name = "infer",
	  suffix = "xml",
	  style = Control.ML,
	  thunk = fn () => (Infer.infer
			    {program = coreML,
			     lookupBuildConstant = lookupBuildConstant,
			     lookupConstant = lookupConstant}),
	  display = Control.Layout Xml.Program.layout,
	  typeCheck = Xml.typeCheck,
	  simplify = Xml.simplify}
      val _ = Control.message (Control.Detail, fn () =>
			       Xml.Program.layoutStats xml)
      val sxml =
	 Control.passSimplify
	 {name = "mono",
	  suffix = "sxml",
	  style = Control.ML,
	  thunk = fn () => Monomorphise.monomorphise xml,
	  display = Control.Layout Sxml.Program.layout,
	  typeCheck = Sxml.typeCheck,
	  simplify = Sxml.simplify}
      val _ = Control.message (Control.Detail, fn () =>
			       Sxml.Program.layoutStats sxml)
      val sxml =
	 Control.passSimplify
	 {name = "implementExceptions",
	  suffix = "sxml",
	  style = Control.ML,
	  thunk = fn () => ImplementExceptions.doit sxml,
	  typeCheck = Sxml.typeCheck,
	  display = Control.Layout Sxml.Program.layout,
	  simplify = Sxml.simplify}
      val sxml =
	 Control.pass (* polyvariance has simplify built in *)
	 {name = "polyvariance",
	  suffix = "sxml.poly",
	  style = Control.ML,
	  thunk = fn () => Polyvariance.duplicate sxml,
	  display = Control.Layout Sxml.Program.layout}
      val _ = Control.message (Control.Detail, fn () =>
			       Sxml.Program.layoutStats sxml)
      val ssa =
	 Control.passSimplify
	 {name = "closureConvert",
	  suffix = "ssa",
	  style = Control.No,
	  thunk = fn () => ClosureConvert.closureConvert sxml,
	  typeCheck = Ssa.typeCheck,
	  display = Control.Layouts Ssa.Program.layouts,
	  simplify = Ssa.simplify}
      val _ =
	 let open Control
	 in if !keepSSA
	       then
		  File.withOut
		  (concat [!inputFile, ".ssa"], fn out =>
		   let
		      fun disp l = Layout.outputl (l, out)
		   in
		      outputHeader (No, disp)
		      ; Ssa.Program.layouts (ssa, disp)
		   end)
	    else ()
	 end
      val machine =
	 Control.passTypeCheck
	 {name = "backend",
	  suffix = "machine",
	  style = Control.No,
	  thunk = fn () => Backend.toMachine ssa,
	  typeCheck = Machine.Program.typeCheck,
	  display = Control.Layouts Machine.Program.layouts}
   in
      machine
   end

fun compile {input: File.t list, outputC, outputS, docc}: unit =
   let
      val machine =
	 Control.trace (Control.Top, "pre codegen")
	 preCodegen {input = input, docc = docc}
      val _ =
	 if !Control.Native.native
	    then
	       Control.trace (Control.Top, "x86 code gen")
	       x86Codegen.output {program = machine,
                                  includes = !Control.includes,
				  outputC = outputC,
				  outputS = outputS}
	 else
	    Control.trace (Control.Top, "C code gen")
	    CCodegen.output {program = machine,
                             includes = !Control.includes,
			     outputC = outputC}
      val _ = Control.message (Control.Detail, PropertyList.stats)
      val _ = Control.message (Control.Detail, HashSet.stats)
   in ()
   end
   
end
