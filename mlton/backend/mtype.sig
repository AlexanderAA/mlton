(* Copyright (C) 1997-1999 NEC Research Institute.
 * Please see the file LICENSE for license information.
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
       | Void

      val align: t * int -> int       (* align an address *)	 
      val all: t list
      val char: t
      val dest: t -> dest
      val double: t
      val equals: t * t -> bool
      val int: t
      val isPointer: t -> bool
      val isVoid: t -> bool
      val label: t (* same as uint *)
      val layout: t -> Layout.t
      val memo: (t -> 'a) -> (t -> 'a)
      val name: t -> string (* one letter abbreviation: CDIPUV *)
      val pointer: t
      val size: t -> int (* bytes *)
      val toString: t -> string
      val uint: t
      val void: t
      val wordAlign: int -> int
   end
