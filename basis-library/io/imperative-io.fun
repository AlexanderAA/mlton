signature IMPERATIVE_IO_EXTRA_ARG = 
   sig
      structure StreamIO: STREAM_IO_EXTRA
      structure Vector: MONO_VECTOR
      structure Array: MONO_ARRAY
      sharing type StreamIO.elem = Vector.elem = Array.elem
      sharing type StreamIO.vector = Vector.vector = Array.vector
   end

functor ImperativeIOExtra
        (S: IMPERATIVE_IO_EXTRA_ARG): IMPERATIVE_IO_EXTRA =
   struct
      open S

      structure SIO = StreamIO
      structure V = Vector
      structure A = Array

      type vector = StreamIO.vector
      type elem = StreamIO.elem

      (*---------------*)
      (*   outstream   *)
      (*---------------*)

      datatype outstream = Out of SIO.outstream ref

      fun equalsOut (Out os1, Out os2) = os1 = os2

      fun output (Out os, v) = SIO.output (!os, v)
      fun output1 (Out os, v) = SIO.output1 (!os, v)
      fun outputSlice (Out os, (v, i, sz)) = SIO.outputSlice (!os, (v, i, sz))
      fun flushOut (Out os) = SIO.flushOut (!os)
      fun closeOut (Out os) = SIO.closeOut (!os)
      fun mkOutstream os = Out (ref os)
      fun getOutstream (Out os) = !os
      fun setOutstream (Out os, os') = os := os'
      fun getPosOut (Out os) = SIO.getPosOut (!os)
      fun setPosOut (Out os, out_pos) = os := SIO.setPosOut out_pos

      (*---------------*)
      (*   instream    *)
      (*---------------*)

      datatype instream = In of SIO.instream ref

      fun equalsIn (In is1, In is2) = is1 = is2

      fun input (In is) = let val (v, is') = SIO.input (!is)
			  in is := is'; v
			  end 
      (* input1 will never move past a temporary end of stream *)
      fun input1 (In is) = 
	case SIO.input1 (!is) of
	  SOME (c,is') => (is := is'; c)
	| NONE => NONE
      (* input1 will move past a temporary end of stream *)
      fun input1 (In is) = 
	case SIO.input1' (!is) of
	  (c,is') => (is := is'; c)
      fun inputN (In is, n) = let val (v, is') = SIO.inputN (!is, n)
			      in is := is'; v
			      end
      fun inputAll (In is) = let val (v, is') = SIO.inputAll (!is)
			     in is := is'; v
			     end
      fun inputLine (In is) = let val (v, is') = SIO.inputLine (!is)
			      in is := is'; v
			      end
      fun canInput (In is, n) = SIO.canInput (!is, n)
      fun lookahead (In is) = Option.map (fn (c, is') => c) (SIO.input1 (!is))
      fun closeIn (In is) = SIO.closeIn (!is)
      fun endOfStream (In is) = SIO.endOfStream (!is)
      fun mkInstream is = In (ref is)
      fun getInstream (In is) = !is
      fun setInstream (In is, is') = is := is'

      fun openVector v = mkInstream (SIO.openVector v)

      fun scanStream f is =
	case f SIO.input1 (getInstream is) of
	  NONE => NONE
	| SOME (v, is') => (setInstream (is, is'); SOME v)
   end

signature IMPERATIVE_IO_ARG = 
   sig
      structure StreamIO: STREAM_IO
      structure Vector: MONO_VECTOR
      structure Array: MONO_ARRAY
      sharing type StreamIO.elem = Vector.elem = Array.elem
      sharing type StreamIO.vector = Vector.vector = Array.vector
   end

functor ImperativeIO
        (S: IMPERATIVE_IO_ARG): IMPERATIVE_IO = 
  ImperativeIOExtra(open S
		    structure StreamIO =
		      struct
			open StreamIO
			fun input1' _ = raise (Fail "<input1'>")
			fun equalsIn _ = raise (Fail "<equalsIn>")
			fun instreamReader _ = raise (Fail "<instreamReader>")
			fun mkInstream' _ = raise (Fail "<mkInstream>")
			fun equalsOut _ = raise (Fail "<equalsOut>")
			fun outstreamWriter _ = raise (Fail "<outstreamWriter>")
			fun mkOutstream' _ = raise (Fail "<mkOutstream>")
			fun openVector _ = raise (Fail "<openVector>")
			fun inputLine _ = raise (Fail "<inputLine>")
			fun outputSlice _ = raise (Fail "<outputSlice>")
		      end)


signature IMPERATIVE_IO_EXTRA_FILE_ARG =
   sig
      structure StreamIO: STREAM_IO_EXTRA_FILE
      structure Vector: MONO_VECTOR
      structure Array: MONO_ARRAY
      sharing type StreamIO.elem = Vector.elem = Array.elem
      sharing type StreamIO.vector = Vector.vector = Array.vector

      val chunkSize: int
      val fileTypeFlags: Posix.FileSys.O.flags list
      val mkReader: {fd: Posix.FileSys.file_desc,
		     name: string,
		     initBlkMode: bool} -> StreamIO.reader
      val mkWriter: {fd: Posix.FileSys.file_desc,
		     name: string,
		     appendMode: bool,
		     initBlkMode: bool,
		     chunkSize: int} -> StreamIO.writer
   end

functor ImperativeIOExtraFile
        (S: IMPERATIVE_IO_EXTRA_FILE_ARG): IMPERATIVE_IO_EXTRA_FILE = 
   struct
      structure ImperativeIO = ImperativeIOExtra(open S)
      open ImperativeIO
      open S
      structure SIO = StreamIO
      structure V = Vector

      structure PIO = Posix.IO
      structure PFS = Posix.FileSys

      fun liftExn name function cause = raise IO.Io {name = name,
						     function = function,
						     cause = cause}

      (*---------------*)
      (*   outstream   *)
      (*---------------*)

      fun newOut {fd, name, appendMode, 
		  buffer_mode, atExit} =
	let
	  val writer = mkWriter {fd = fd, name = name,
				 appendMode = appendMode, 
				 initBlkMode = true,
				 chunkSize = chunkSize}
	  val outstream = SIO.mkOutstream'' {writer = writer, 
					     closed = false,
					     buffer_mode = buffer_mode,
					     atExit = atExit}
	in
	  mkOutstream outstream
	end
      val stdErr = newOut {fd = PFS.stderr,
			   name = "<stderr>", 
			   appendMode = true, 
			   buffer_mode = IO.NO_BUF,
			   atExit = {close = false}}
      val newOut = fn {fd, name, appendMode, atExit} =>
	newOut {fd = fd, name = name, appendMode = appendMode,
		buffer_mode = if Posix.ProcEnv.isatty fd
				then IO.LINE_BUF
				else IO.BLOCK_BUF,
		atExit = atExit}
      val stdOut = newOut {fd = PFS.stdout, 
			   name = "<stdout>", 
			   appendMode = true,
			   atExit = {close = false}}
      val newOut = fn {fd, name, appendMode} =>
	newOut {fd = fd, name = name, appendMode = appendMode,
		atExit = {close = true}}
      local
	val readWrite =
	  let open PFS.S
	  in flags [irusr, iwusr, irgrp, iwgrp, iroth, iwoth]
	  end
      in
	fun openOut file =
	  let
	    val fd = PFS.createf (file, PIO.O_WRONLY, 
				  PFS.O.flags (PFS.O.trunc::fileTypeFlags), 
				  readWrite)
	  in 
	    newOut {fd = fd, 
		    name = file, 
		    appendMode = false}
	  end
          handle exn => liftExn file "openOut" exn
	fun openAppend file =
	  let
	    val fd = PFS.createf (file, PIO.O_WRONLY,
				  PFS.O.flags (PFS.O.append::fileTypeFlags),
				  readWrite)
	  in
	    newOut {fd = fd, 
		    name = file, 
		    appendMode = true}
	  end
          handle exn => liftExn file "openAppend" exn
      end
      val newOut = fn fd => newOut {fd = fd, 
				    name = "<unknown>", 
				    appendMode = false}
      val outFd = SIO.outFd o getOutstream

      (*---------------*)
      (*   instream   *)
      (*---------------*)

      fun newIn {fd, name, buffer_contents, atExit} =
	let 
	  val reader = mkReader {fd = fd, name = name, initBlkMode = true}
	  val instream = SIO.mkInstream'' {reader = reader,
					   closed = false,
					   buffer_contents = buffer_contents,
					   atExit = atExit}
	in
	  mkInstream instream
	end
      val newIn = fn {fd, name, atExit} =>
	newIn {fd = fd, name = name, buffer_contents = NONE, atExit = atExit}
      val newIn = fn {fd, name} =>
	newIn {fd = fd, name = name, atExit = {close = true}}
      val stdIn = newIn {fd = PFS.stdin, 
			 name = "<stdin>"}
      fun openIn file =
	let 
	  val fd = PFS.openf (file, PIO.O_RDONLY, 
			      PFS.O.flags fileTypeFlags)
	in 
	  newIn {fd = fd, 
		 name = file}
	end
        handle exn => liftExn file "newIn" exn
      val newIn = fn fd => newIn {fd = fd, name = "<unknown>"}
      val inFd = SIO.inFd o getInstream
   end
