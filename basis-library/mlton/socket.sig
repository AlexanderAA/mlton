type int = Int.int
type word = Word.word

signature MLTON_SOCKET =
   sig
      structure Address:
	 sig
	    type t = word
	 end

      structure Host:
	 sig
	    type t = {name: string}

	    val getByAddress: Address.t -> t option
	    val getByName: string -> t option
	 end

      structure Port:
	 sig
	    type t = int
	 end

      type t

      val accept: t -> Address.t * Port.t * TextIO.instream * TextIO.outstream
      val connect: string * Port.t -> TextIO.instream * TextIO.outstream
      val listen: unit -> Port.t * t
      val listenAt: Port.t -> t
      val shutdownRead: TextIO.instream -> unit
      val shutdownWrite: TextIO.outstream -> unit

      val fdToSock: Posix.FileSys.file_desc -> ('af, 'sock_type) Socket.sock
   end
