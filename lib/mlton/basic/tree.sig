(* Copyright (C) 1999-2004 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
signature TREE =
   sig
      datatype 'a t = T of 'a * 'a t vector

      val children: 'a t -> 'a t vector
      val foldPre: 'a t * 'b * ('a * 'b -> 'b) -> 'b
      val foldPost: 'a t * 'b * ('a * 'b -> 'b) -> 'b
      val foreachPre: 'a t * ('a -> unit) -> unit (* preorder traversal *)
      val foreachPost: 'a t * ('a -> unit) -> unit (* postorder traversal *)
      val layout: ('a -> Layout.t) -> 'a t -> Layout.t
      val layoutDot:
	 'a t * {nodeOptions: 'a -> Dot.NodeOption.t list,
		 options: Dot.GraphOption.t list,
		 title: string}
	 -> Layout.t
      val map: 'a t * ('a -> 'b) -> 'b t
      val traverse: 'a t * ('a -> unit -> unit) -> unit
   end
