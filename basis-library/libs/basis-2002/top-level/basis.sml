structure Basis2002:> BASIS_2002 = 
   struct
      (* Required structures *)
      structure Array = Array
      structure ArraySlice = ArraySlice
      structure BinIO = BinIO
      structure BinPrimIO = BinPrimIO
      structure Bool = Bool
      structure Byte = Byte
      structure Char = Char
      structure CharArray = CharArray
      structure CharArraySlice = CharArraySlice
      structure CharVector = CharVector
      structure CharVectorSlice = CharVectorSlice
      structure CommandLine = CommandLine
      structure Date = Date
      structure General = General
      structure IEEEReal = IEEEReal
      structure IO = IO
      structure Int = Int
      structure LargeInt = LargeInt
      structure LargeReal = LargeReal
      structure LargeWord = LargeWord
      structure List = List
      structure ListPair = ListPair
      structure Math = Math
      structure OS = OS
      structure Option = Option
      structure Position = Position
      structure Real = Real
      structure String = String
      structure StringCvt = StringCvt
      structure Substring = Substring
      structure Text = Text
      structure TextIO = TextIO
      structure TextPrimIO = TextPrimIO
      structure Time = Time
      structure Timer = Timer
      structure Vector = Vector
      structure VectorSlice = VectorSlice
      structure Word = Word
      structure Word8 = Word8
      structure Word8Array = Word8Array
      structure Word8Array2 = Word8Array2
      structure Word8ArraySlice = Word8ArraySlice
      structure Word8Vector = Word8Vector
      structure Word8VectorSlice = Word8VectorSlice

      (* Optional structures *)
      structure Array2 = Array2
      structure BoolArray = BoolArray
      structure BoolArray2 = BoolArray2
      structure BoolArraySlice = BoolArraySlice
      structure BoolVector = BoolVector
      structure BoolVectorSlice = BoolVectorSlice
      structure CharArray2 = CharArray2
      structure FixedInt = FixedInt
      structure GenericSock = GenericSock
      structure INetSock = INetSock
      structure Int16 = Int16
      structure Int16Array = Int16Array
      structure Int16Array2 = Int16Array2
      structure Int16ArraySlice = Int16ArraySlice
      structure Int16Vector = Int16Vector
      structure Int16VectorSlice = Int16VectorSlice
      structure Int32 = Int32
      structure Int32Array = Int32Array
      structure Int32Array2 = Int32Array2
      structure Int32ArraySlice = Int32ArraySlice
      structure Int32Vector = Int32Vector
      structure Int32VectorSlice = Int32VectorSlice
      structure Int64 = Int64
      structure Int64Array = Int64Array
      structure Int64Array2 = Int64Array2
      structure Int64ArraySlice = Int64ArraySlice
      structure Int64Vector = Int64Vector
      structure Int64VectorSlice = Int64VectorSlice
      structure Int8 = Int8
      structure Int8Array = Int8Array
      structure Int8Array2 = Int8Array2
      structure Int8ArraySlice = Int8ArraySlice
      structure Int8Vector = Int8Vector
      structure Int8VectorSlice = Int8VectorSlice
      structure IntArray = IntArray
      structure IntArray2 = IntArray2
      structure IntArraySlice = IntArraySlice
      structure IntInf = IntInf
      structure IntVector = IntVector
      structure IntVectorSlice = IntVectorSlice
      structure LargeIntArray = LargeIntArray
      structure LargeIntArray2 = LargeIntArray2
      structure LargeIntArraySlice = LargeIntArraySlice
      structure LargeIntVector = LargeIntVector
      structure LargeIntVectorSlice = LargeIntVectorSlice
      structure LargeRealArray = LargeRealArray
      structure LargeRealArray2 = LargeRealArray2
      structure LargeRealArraySlice = LargeRealArraySlice
      structure LargeRealVector = LargeRealVector
      structure LargeRealVectorSlice = LargeRealVectorSlice
      structure LargeWordArray = LargeWordArray
      structure LargeWordArray2 = LargeWordArray2
      structure LargeWordArraySlice = LargeWordArraySlice
      structure LargeWordVector = LargeWordVector
      structure LargeWordVectorSlice = LargeWordVectorSlice
      structure NetHostDB = NetHostDB
      structure NetProtDB = NetProtDB
      structure NetServDB = NetServDB
      structure Pack32Big = PackWord32Big
      structure Pack32Little = PackWord32Little
      structure PackWord32Big = PackWord32Big
      structure PackWord32Little = PackWord32Little
      structure PackReal32Big = PackReal32Big
      structure PackReal32Little = PackReal32Little
      structure PackReal64Big = PackReal64Big
      structure PackReal64Little = PackReal64Little
      structure PackRealBig = PackRealBig
      structure PackRealLittle = PackRealLittle
      structure Posix = Posix
      structure Real32 = Real32
      structure Real32Array = Real32Array
      structure Real32Array2 = Real32Array2
      structure Real32ArraySlice = Real32ArraySlice
      structure Real32Vector = Real32Vector
      structure Real32VectorSlice = Real32VectorSlice
      structure Real64 = Real64
      structure Real64Array = Real64Array
      structure Real64Array2 = Real64Array2
      structure Real64ArraySlice = Real64ArraySlice
      structure Real64Vector = Real64Vector
      structure Real64VectorSlice = Real64VectorSlice
      structure RealArray = RealArray
      structure RealArray2 = RealArray2
      structure RealArraySlice = RealArraySlice
      structure RealVector = RealVector
      structure RealVectorSlice = RealVectorSlice
      structure Socket = Socket
      structure SysWord = SysWord
      structure Unix = Unix
      structure UnixSock = UnixSock
(*
      structure WideChar = WideChar
      structure WideCharArray = WideCharArray
      structure WideCharArray2 = WideCharArray2
      structure WideCharArraySlice = WideCharArraySlice
      structure WideCharVector = WideCharVector
      structure WideCharVectorSlice = WideCharVectorSlice
      structure WideString = WideString
      structure WideSubstring = WideSubstring
      structure WideText = WideText
      structure WideTextPrimIO = WideTextPrimIO
*)
(*
      structure Windows = Windows
*)
      structure Word16 = Word16
      structure Word16Array = Word16Array
      structure Word16Array2 = Word16Array2
      structure Word16ArraySlice = Word16ArraySlice
      structure Word16Vector = Word16Vector
      structure Word16VectorSlice = Word16VectorSlice
      structure Word32 = Word32
      structure Word32Array = Word32Array
      structure Word32Array2 = Word32Array2
      structure Word32ArraySlice = Word32ArraySlice
      structure Word32Vector = Word32Vector
      structure Word32VectorSlice = Word32VectorSlice
      structure WordArray = WordArray
      structure WordArray2 = WordArray2
      structure WordArraySlice = WordArraySlice
      structure WordVector = WordVector
      structure WordVectorSlice = WordVectorSlice

      open ArrayGlobal
	   BoolGlobal
	   CharGlobal
	   IntGlobal
	   GeneralGlobal
	   ListGlobal
	   OptionGlobal
	   RealGlobal
	   StringGlobal
	   RealGlobal
	   SubstringGlobal
	   TextIOGlobal
	   VectorGlobal
	   WordGlobal
      val real = real
      val op <> = op <>
      val vector = vector
      datatype ref = datatype ref
   end
