(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
structure SMLofNJ: SML_OF_NJ =
   struct
      structure Cont =
	 struct
	    structure C = MLton.Cont

	    type 'a cont = 'a C.t
	    val callcc = C.callcc
	    fun throw k v = C.throw (k, v)
	 end
      	 
      structure SysInfo =
	 struct
	    exception UNKNOWN
	    datatype os_kind = BEOS | MACOS | OS2 | UNIX | WIN32

	    fun getHostArch () = "X86"
	    fun getOSKind () = UNIX
	    fun getOSName () =
	       let
		  open Primitive.MLton
	       in
		  case hostType of
		     Cygwin => "Cygwin"
		   | Linux => "Linux"
	       end
	 end
      
      structure Internals =
	 struct
	    structure GC =
	       struct
		  fun messages _ = ()
	       end
	 end

      val getCmdName = CommandLine.name
      val getArgs = CommandLine.arguments

      fun getAllArgs () = getCmdName () :: getArgs ()

      val exnHistory = MLton.Exn.history
	 
      structure World = MLton.World

      fun exportFn (file: string, f) =
	 let open MLton.World OS.Process
	 in case save (file ^ ".mlton") of
	    Original => exit success
	  | Clone => exit (f (getCmdName (), getArgs ()) handle _ => failure)
	 end

      fun exportML (f: string): bool =
	 let open MLton.World
	 in case save (f ^ ".mlton") of
	    Clone => true
	  | Original => false
	 end
   end
   
