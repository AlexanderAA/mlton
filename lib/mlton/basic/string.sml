(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type word = Word.t
   
structure String: STRING =
   struct
      open String1

      fun keepAll (s: t, f: char -> bool): t =
	 implode (List.rev
		  (fold (s, [], fn (c, ac) => if f c then c :: ac else ac)))
	 
      fun memoizeList (init: string -> 'a, l: (t * 'a) list): t -> 'a =
	 let
	    val set: (word * t * 'a) HashSet.t = HashSet.new {hash = #1}
	    fun lookupOrInsert (s, f) =
	       let
		  val hash = hash s
	       in HashSet.lookupOrInsert
		  (set, hash,
		   fn (hash', s', _) => hash = hash' andalso s = s',
		   fn () => (hash, s, f ()))
	       end
	    val _ =
	       List.foreach (l, fn (s, a) =>
			     ignore (lookupOrInsert (s, fn () => a)))
	 in
	    fn s => #3 (lookupOrInsert (s, fn () => init s))
	 end

      fun memoize init = memoizeList (init, [])

      fun posToLineCol (s: string): int -> {line: int, col: int} =
	 let
	    open Int
	    val lineStarts =
	       Array.fromList
	       (List.rev (foldi (s, [0], fn (i, c, is) =>
				 if c = #"\n"
				    then (i + 1) :: is
				 else is)))
	    fun find (pos: int) =
	       let
		  val line =
		     valOf (BinarySearch.largest (lineStarts, fn x => x <= pos))
	       (* The 1+'s are to make stuff one based *)
	       in {line = 1 + line,
		   col = 1 + pos - Array.sub (lineStarts, line)}
	       end
	 in find
	 end

   end

structure ZString = String (* CM bug ?? -- see instream.sml *)
