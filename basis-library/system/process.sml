(* Modified from SML/NJ sources by sweeks@research.nj.nec.com on 1998-6-25.
 * Further modified by sweeks@acm.org 1999-12-10, 2000-1-18
 *)

(* os-process.sml
 *
 * COPYRIGHT (c) 1995 AT&T Bell Laboratories.
 *
 * The Posix-based implementation of the generic process control
 * interface (OS.Process).
 *
 *)

structure OS_Process: OS_PROCESS_EXTRA =
   struct
      open Posix.Process

      structure Signal = MLton.Signal
      type status = int

      val success: status = 0
      val failure: status = 1

      fun wait pid =
	 case #2 (waitpid (W_CHILD pid, [])) of
	    W_EXITED => success
	  | W_EXITSTATUS w => Word8.toInt w
	  | W_SIGNALED s => failure (* ?? *)
	  | W_STOPPED s => failure (* this shouldn't happen *)
	       
      fun system cmd =
	 wait (MLton.Process.spawn {path = "/bin/sh",
				    args = ["sh", "-c", cmd]})

      fun atExit f = Cleaner.addNew (Cleaner.atExit, f)

      fun terminate x = exit (Word8.fromInt x)

      val exit = MLton.Process.exit

      val getEnv = Posix.ProcEnv.getenv
   end
