(* Copyright (C) 1997-1999 NEC Research Institute.
 * Please see the file LICENSE for license information.
 *)
(* sweeks commented out update and create because vectors are immutable
 * and mlton optimizations may break if you update them.
 *)

(* unsafe-mono-vector.sig
 *
 * COPYRIGHT (c) 1997 Bell Labs, Lucent Technologies.
 *)

signature UNSAFE_MONO_VECTOR =
  sig

    type vector
    type elem

    val sub : (vector * int) -> elem
(*    val update : (vector * int * elem) -> unit *)
(*    val create : int -> vector *)

  end


(*
 * $Log$
 *)
