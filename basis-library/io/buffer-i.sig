signature BUFFER_I =
   sig
      type elem
      type vector

      type inbuffer

      type instream
      type reader
      type pos

      val input: inbuffer -> vector
      val input1: inbuffer -> elem option
      val inputN: inbuffer * int -> vector
      val inputAll: inbuffer -> vector
      val canInput: inbuffer * int -> int option
      val lookahead: inbuffer -> elem option
      val closeIn: inbuffer -> unit
      val endOfStream: inbuffer -> bool
      val mkInbuffer: reader * vector -> inbuffer
      val getInstream: inbuffer -> instream
   end

signature BUFFER_I_EXTRA =
   sig
      include BUFFER_I

      val openVector: vector -> inbuffer
      val inputLine: inbuffer -> vector option
      val equalsIn: inbuffer * inbuffer -> bool
      val inbufferReader: inbuffer -> reader
      val getInstream': ({reader: reader, 
			  closed: bool,
			  buffer_contents: vector option} -> instream) ->
	                inbuffer -> instream
      val mkInbuffer': {reader: reader,
			closed: bool,
			buffer_contents: vector option} -> inbuffer
   end

signature BUFFER_I_EXTRA_FILE =
   sig
      include BUFFER_I_EXTRA

      val inFd: inbuffer -> Posix.IO.file_desc
      val getInstream'': ({reader: reader, 
			   closed: bool,
			   buffer_contents: vector option,
			   atExit: {close: bool}} -> instream) ->
	                 inbuffer -> instream
      val mkInbuffer'': {reader: reader,
			 closed: bool,
			 buffer_contents: vector option,
			 atExit: {close: bool}} -> inbuffer
   end
