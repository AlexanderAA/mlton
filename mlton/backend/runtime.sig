type int = Int.t
type word = Word.t
   
signature RUNTIME =
   sig
      (* All sizes are in bytes. *)

      val arrayHeaderSize: int
      val isValidObjectHeader: {numPointers: int,
				numWordsNonPointers: int} -> bool
      (* objectSize does not include the header. *)
      val objectSize: {numPointers: int,
		       numWordsNonPointers: int} -> int
      val isValidArrayHeader: {numBytesNonPointers: int,
			       numPointers: int} -> bool
      val objectHeaderSize: int
      val pointerSize: int
      val wordSize: int
   end
