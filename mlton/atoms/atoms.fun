(* Copyright (C) 1999-2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)

functor Atoms (S: ATOMS_STRUCTS): ATOMS =
struct

structure Atoms =
   struct
      open S

      structure PointerTycon = PointerTycon ()
      structure ProfileLabel = ProfileLabel ()
      structure SourceInfo = SourceInfo ()
      structure ProfileExp = ProfileExp (structure SourceInfo = SourceInfo)
      structure Var = Var ()
      structure Tycon = Tycon (structure IntSize = IntSize
			       structure RealSize = RealSize
			       structure WordSize = WordSize)
      structure Con = Con ()
      structure CType = CType (structure IntSize = IntSize
			       structure RealSize = RealSize
			       structure WordSize = WordSize)
      structure IntX = IntX (structure IntSize = IntSize)
      structure RealX = RealX (structure RealSize = RealSize)
      structure WordX = WordX (structure WordSize = WordSize)
      structure Runtime = Runtime (structure CType = CType)
      structure Func =
	 struct
	    open Var
	    fun newNoname () = newString "F"
	 end
      structure Label =
	 struct
	    open Func
	    fun newNoname () = newString "L"
	 end
      structure Const = Const (structure IntX = IntX
			       structure RealX = RealX
			       structure WordX = WordX)
      structure CFunction = CFunction ()
      structure Prim = Prim (structure CFunction = CFunction
			     structure CType = CType
			     structure Con = Con
			     structure Const = Const
			     structure IntSize = IntSize
			     structure RealSize = RealSize
			     structure WordSize = WordSize)
      structure RepType = RepType (structure CFunction = CFunction
				   structure CType = CType
				   structure IntSize = IntSize
				   structure IntX = IntX
				   structure Label = Label
				   structure PointerTycon = PointerTycon
				   structure Prim = Prim
				   structure RealSize = RealSize
				   structure Runtime = Runtime
				   structure WordSize = WordSize
				   structure WordX = WordX)
      structure Ffi = Ffi (structure CFunction = CFunction
			   structure CType = CType)
      structure ObjectType = RepType.ObjectType
      structure Tyvars = UnorderedSet (Tyvar)
      structure Vars = UnorderedSet (Var)
      structure Cons = UnorderedSet (Con)
      structure Tycons = UnorderedSet (Tycon)
   end

open Atoms

end
