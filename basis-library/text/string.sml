(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
structure String: STRING_EXTRA =
   struct
      open String0

      local
	 fun make f = f (op = : char * char -> bool)
      in
	val isPrefix = make isPrefix
	val isSubstring = make isSubvector
	val isSuffix = make isSuffix
      end
      val compare = collate Char.compare
      val {<, <=, >, >=} = Util.makeOrder compare

      val toString = translate Char.toString
      val toCString = translate Char.toCString

      fun scanString scanChar (reader: (char, 'a) StringCvt.reader)
	: (string, 'a) StringCvt.reader =
	 fn state =>
	 case reader state of
	    NONE => SOME ("", state)
	  | _ =>
	       case Reader.list (scanChar reader) state of
		  NONE => NONE
		| SOME ([], _) => NONE
		| SOME (cs, state) => SOME (implode cs, state)

      val fromString = StringCvt.scanString (scanString Char.scan)
      val fromCString = StringCvt.scanString (scanString Char.scanC)

      fun nullTerm s = s ^ "\000"
   end

structure StringGlobal: STRING_GLOBAL = String
open StringGlobal
