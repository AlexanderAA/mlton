(* Copyright (C) 1997-1999 NEC Research Institute.
 * Please see the file LICENSE for license information.
 *)
signature TYPE_CHECK_STRUCTS = 
   sig
      include INFER_HANDLERS
   end

signature TYPE_CHECK = 
   sig
      include TYPE_CHECK_STRUCTS
      
      val typeCheck: Program.t -> unit
   end
