(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

_overload ~ :   ('a -> 'a)
as  Int.~
and IntInf.~
and Real.~

_overload + :   ('a * 'a -> 'a)
as  Int.+
and IntInf.+
and Word.+
and Word8.+
and Real.+

_overload - :   ('a * 'a -> 'a)
as  Int.-
and IntInf.-
and Word.-
and Word8.-
and Real.-

_overload * :   ('a * 'a -> 'a)
as  Int.*
and IntInf.*
and Word.*
and Word8.*
and Real.*

_overload / : ('a * 'a -> 'a)
as Real./

_overload div: ('a * 'a -> 'a)
as  Int.div
and IntInf.div
and Word.div
and Word8.div

_overload mod: ('a * 'a -> 'a)
as  Int.mod
and IntInf.mod
and Word.mod
and Word8.mod

_overload < :   ('a * 'a -> bool)
as  Int.<
and IntInf.<
and Word.<
and Word8.<
and Real.<
and Char.<
and String.<

_overload <= :   ('a * 'a -> bool)
as  Int.<=
and IntInf.<=
and Word.<=
and Word8.<=
and Real.<=
and Char.<=
and String.<=

_overload > :   ('a * 'a -> bool)
as  Int.>
and IntInf.>
and Word.>
and Word8.>
and Real.>
and Char.>
and String.>

_overload >= :   ('a * 'a -> bool)
as  Int.>=
and IntInf.>=
and Word.>=
and Word8.>=
and Real.>=
and Char.>=
and String.>=

_overload abs: ('a -> 'a)
as  Int.abs
and IntInf.abs
and Real.abs

