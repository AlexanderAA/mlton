functor Ffi (S: FFI_STRUCTS): FFI = 
struct

open S

structure Convention = CFunction.Convention

val exports: {args: CType.t vector,
	      convention: Convention.t,
	      id: int,
	      name: string,
	      res: CType.t option} list ref = ref []

fun numExports () = List.length (!exports)

local
   val exportCounter = Counter.new 0
in
   fun addExport {args, convention, name, res} =
      let
	 val id = Counter.next exportCounter
	 val _ = List.push (exports, {args = args,
				      convention = convention,
				      id = id,
				      name = name,
				      res = res})
      in
	 id
      end
end

val headers: string list ref = ref []
      
fun declareExports {print} =
   let
      val maxMap = CType.memo (fn _ => ref ~1)
      fun bump (t, i) =
	 let
	    val r = maxMap t
	 in
	    r := Int.max (!r, i)
	 end
      val _ =
	 List.foreach
	 (!exports, fn {args, res, ...} =>
	  let
	     val map = CType.memo (fn _ => Counter.new 0)
	  in
	     Vector.foreach (args, fn t => bump (t, Counter.next (map t)))
	     ; Option.app (res, fn t => bump (t, 0))
	  end)
      (* Declare the arrays and functions used for parameter passing. *)
      val _ =
	 List.foreach
	 (CType.all, fn t =>
	  let
	     val n = !(maxMap t)
	  in
	     if n >= 0
		then
		   let
		      val size = Int.toString (1 + n)
		      val t = CType.toString t
		   in
		      print (concat [t, " MLton_FFI_", t, "[", size, "];\n"])
		      ; print (concat [t, " MLton_FFI_get", t, " (Int i) {\n",
				       "\treturn MLton_FFI_", t, "[i];\n",
				       "}\n"])
		      ; print (concat
			       [t, " MLton_FFI_set", t, " (", t, " x) {\n",
				"\tMLton_FFI_", t, "[0] = x;\n",
				"}\n"])
		   end
	     else ()
	  end)
      val _ = print "Int MLton_FFI_op;\n"
      val _ = print (concat ["Int MLton_FFI_getOp () {\n",
			     "\treturn MLton_FFI_op;\n",
			     "}\n"])
   in
      List.foreach
      (!exports, fn {args, convention, id, name, res} =>
       let
	  val varCounter = Counter.new 0
	  val map = CType.memo (fn _ => Counter.new 0)
	  val args =
	     Vector.map
	     (args, fn t =>
	      let
		 val index = Counter.next (map t)
		 val x = concat ["x", Int.toString (Counter.next varCounter)]
		 val t = CType.toString t
	      in
		 (x,
		  concat [t, " ", x],
		  concat ["\tMLton_FFI_", t, "[", Int.toString index, "] = ",
			  x, ";\n"])
	      end)
	  val header =
	     concat [case res of
			NONE => "void"
		      | SOME t => CType.toString t,
	             if convention <> Convention.Cdecl
			then concat [" __attribute__ ((",
				     Convention.toString convention,
				     ")) "]
		     else " ",
		     name, " (",
		     concat (List.separate (Vector.toListMap (args, #2), ", ")),
		     ")"]
	  val _ = List.push (headers, header)
       in
	  print (concat [header, " {\n"])
	  ; print (concat ["\tMLton_FFI_op = ", Int.toString id, ";\n"])
	  ; Vector.foreach (args, fn (_, _, set) => print set)
	  ; print ("\tMLton_callFromC ();\n")
	  ; (case res of
		NONE => ()
	      | SOME t =>
		   print (concat
			  ["\treturn MLton_FFI_", CType.toString t, "[0];\n"]))
	  ; print "}\n"
       end)
   end

fun declareHeaders {print} =
   (declareExports {print = fn _ => ()}
    ; List.foreach (!headers, fn s => (print s; print ";\n")))

end
