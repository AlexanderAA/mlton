(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
signature ID_STRUCTS =
   sig
      val noname: string
   end

signature ID =
   sig
      include ID_STRUCTS

      type t

      val bogus: t
      val clear: t -> unit
      val equals: t * t -> bool
      val fromString: string -> t (* doesn't add uniquefying suffix *)
      val layout: t -> Layout.t
      val new: t -> t (* with the same prefix *)
      val newNoname: unit -> t (* prefix is noname *)
      val newString: string -> t (* given prefix *)
      val originalName: t -> string (* raw destructor *)
      val plist: t -> PropertyList.t
      val sameName: t * t -> bool
      val setPrintName: t * string -> unit
      val toString: t -> string
   end

signature HASH_ID =
   sig
      include ID

      val hash: t -> Word.t
   end
