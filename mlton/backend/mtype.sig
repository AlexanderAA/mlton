(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
type int = Int.t
   
signature MTYPE_STRUCTS = 
   sig
   end

signature MTYPE = 
   sig
      include MTYPE_STRUCTS

      type t
	 
      datatype dest =
	 Char
       | Double
       | Int
       | Pointer
       | Uint

      val align4: int -> int
      val align8: int -> int
      val align: t * int -> int       (* align an address *)	 
      val all: t list
      val bool: t (* same as int *)
      val char: t
      val dest: t -> dest
      val double: t
      val equals: t * t -> bool
      val int: t
      val isPointer: t -> bool
      val label: t (* same as uint *)
      val layout: t -> Layout.t
      val memo: (t -> 'a) -> (t -> 'a)
      val name: t -> string (* one letter abbreviation: CDIPUV *)
      val pointer: t
      val size: t -> int (* bytes *)
      val toString: t -> string
      val uint: t
      val word: t (* synonym for uint *)
   end
