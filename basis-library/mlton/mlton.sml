(* Copyright (C) 1999-2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
structure MLton: MLTON =
struct

val isMLton = true
   
(* The ref stuff is so that the (de)serializer always deals with pointers
 * to heap objects.
 *)
(*       val serialize = fn x => serialize (ref x)
 *       val deserialize = fn x => !(deserialize x)
 *)

val share = Primitive.MLton.share
val shareAll = Primitive.MLton.shareAll
   
fun size x =
   let val refOverhead = 8 (* header + indirect *)
   in Primitive.MLton.size (ref x) - refOverhead
   end

(* fun cleanAtExit () = let open Cleaner in clean atExit end *)

val eq = Primitive.eq
(* val errno = Primitive.errno *)
val safe = Primitive.safe

structure Array = Array
structure BinIO = MLtonIO (BinIO)
structure Cont = MLtonCont
structure Exn = MLtonExn
structure Finalizable = MLtonFinalizable
structure GC = MLtonGC
structure IntInf =
   struct
      open IntInf
      type t = int
   end
structure Itimer = MLtonItimer
structure Platform = MLtonPlatform
structure Pointer = MLtonPointer
structure ProcEnv = MLtonProcEnv
structure Process = MLtonProcess
(* structure Ptrace = MLtonPtrace *)
structure Profile = MLtonProfile
structure Random = MLtonRandom
structure Rlimit = MLtonRlimit
structure Rusage = MLtonRusage
structure Signal = MLtonSignal
structure Socket = MLtonSocket
structure Syslog = MLtonSyslog
structure TextIO = MLtonIO (TextIO)
structure Thread = MLtonThread
structure Vector = Vector
structure Weak = MLtonWeak
structure World = MLtonWorld
structure Word =
   struct
      open Primitive.Word32
      type t = word
   end
structure Word8 =
   struct
      open Primitive.Word8
      type t = word
   end

val _ = 
   (Primitive.TopLevel.setHandler MLtonExn.topLevelHandler
    ; Primitive.TopLevel.setSuffix 
      (fn () => MLtonProcess.exit MLtonProcess.Status.success))
end

(* Patch OS.FileSys.tmpName to use mkstemp. *)
structure OS =
   struct
      open OS

      structure FileSys =
	 struct
	    open FileSys

	    fun tmpName () =
	       let
		  val (f, out) = MLton.TextIO.mkstemp "/tmp/file"
		  val _ = TextIO.closeOut out
	       in
		  f
	       end
	 end
   end
