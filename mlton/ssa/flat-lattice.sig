(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
signature FLAT_LATTICE_STRUCTS =
   sig
      structure Point:
	 sig
	    type t

	    val equals: t * t -> bool
	    val layout: t -> Layout.t
	 end
   end

signature FLAT_LATTICE =
   sig
      include FLAT_LATTICE_STRUCTS
	 
      type t

      val <= : t * t -> bool
      val forcePoint: t * Point.t -> bool
      val layout: t -> Layout.t
      val lowerBound: t * Point.t -> bool
      val new: unit -> t
      val point: Point.t -> t
      val isBottom: t -> bool
      val isPoint: t -> bool
      val isPointEq: t * Point.t -> bool
      val isTop: t -> bool
      val upperBound: t * Point.t -> bool
   end
