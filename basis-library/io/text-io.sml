structure TextIO: TEXT_IO_EXTRA =
   struct
      structure S = struct
		      structure PrimIO = TextPrimIO
		      structure Array = CharArray
		      structure ArraySlice = CharArraySlice
		      structure Vector = CharVector
		      structure VectorSlice = CharVectorSlice
		      val someElem = (#"\000": Char.char)
		      val lineElem = (#"\n": Char.char)
		      fun isLine c = c = lineElem
		      val line = SOME {isLine = isLine, 
				       lineElem = lineElem}
		      val xlatePos = SOME {fromInt = fn i => i,
					   toInt = fn i => i}
		      structure Cleaner = Cleaner
		    end
      structure StreamIO = StreamIOExtraFile (open S)
      structure SIO = StreamIO
      structure S = struct 
		      open S 
		      structure StreamIO = StreamIO
		    end
      structure BufferI = BufferIExtraFile (open S)
      structure BI = BufferI
      structure S = struct
		      open S
		      structure BufferI = BufferI
		      val chunkSize = Primitive.TextIO.bufSize
		      val fileTypeFlags = [PosixPrimitive.FileSys.O.text]
		      val mkReader = Posix.IO.mkTextReader
		      val mkWriter = Posix.IO.mkTextWriter
		    end
      structure FastImperativeIO = FastImperativeIOExtraFile (open S)
      open FastImperativeIO

      structure StreamIO =
	 struct
	    open SIO
	    fun outputSubstr (s, ss) = outputSlice (s, ss)
	 end

      fun outputSubstr (s, ss) = outputSlice (s, ss)
      val openString = openVector
      fun print (s: string) = (output (stdOut, s); flushOut stdOut)
   end

structure TextIO = TextIO

structure TextIOGlobal: TEXT_IO_GLOBAL = TextIO
open TextIOGlobal
