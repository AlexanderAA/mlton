structure List =
   struct
      open List

      fun foreach (l, f) = app f l
   end
structure Process = Posix.Process
open Process MLton.Signal 

fun print s = let open TextIO
	      in output (stdErr, s)
		 ; output (stdErr, "\n")
	      end

val sleep = sleep o Time.fromSeconds
   
val _ =
   case fork () of
      NONE =>
	 let
	    val _ =
	       List.foreach
	       ([(hup, "Got a hup."),
		 (int, "You can't int me you loser."),
		 (term, "Don't even try to term me.")],
		fn (signal, msg) =>
		handleWith (signal, fn () => print msg))
	    fun loop' () = (sleep 1; loop' ())
	 in loop' ()
	 end
    | SOME pid => 
	 let
	    fun signal s = Process.kill (K_PROC pid, s)
	 in 
	    sleep 1
	    ; print "sending 1"
	    ; List.foreach ([hup, int, term, term, int, hup], signal)
	    ; sleep 3
	    ; print "sending 2"
	    ; List.foreach ([hup, int], signal)
	    ; sleep 3
	    ; print "sending 3"
	    ; signal kill
	    ; wait ()
	 end

