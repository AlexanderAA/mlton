signature MLTON_SIGNAL =
   sig
      include POSIX_SIGNAL

      type t
      sharing type t = signal

      val prof: t
      val vtalrm: t

      structure Mask:
	 sig
	    type t
	       
	    val all: t
	    val allBut: signal list -> t
	    val block: t -> unit
	    val none: t
	    val set: t -> unit
	    val some: signal list -> t
	    val unblock: t -> unit
	 end

      datatype handler =
	 Default
       | Ignore
       | Handler of unit Thread.t -> unit Thread.t

      val getHandler: t -> handler
      val handleDefault: t -> unit
      (*
       * It is an error for a handler to raise an exception.
       * It is an error to Thread.switch' to an interrupted thread
       * with a thunk that raises an exception (either directly, or via
       * Thread.prepend).  This is to avoid the possibility of
       * aynchronous exceptions.
       *)
      val handleWith': t * (unit Thread.t -> unit Thread.t) -> unit
      val handleWith: t * (unit -> unit) -> unit
      val ignore: t -> unit
      val setHandler: t * handler -> unit
      (* suspend m temporarily sets the signal mask to m and suspends until an
       * unmasked signal is received and handled, and then resets the mask.
       *)
      val suspend: Mask.t -> unit
   end
