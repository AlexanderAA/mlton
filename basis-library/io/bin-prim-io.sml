structure BinPrimIO: PRIM_IO
                     where type array = Word8Array.array
		     where type vector = Word8Vector.vector
		     where type elem = Word8.word
		     where type pos = Position.int =
  PrimIO (structure Array = Word8Array
	  structure ArraySlice = Word8ArraySlice
	  structure Vector = Word8Vector
	  structure VectorSlice = Word8VectorSlice
	  type pos = Position.int
	  val compare = Position.compare
	  val someElem = 0wx0: Word8.word)
