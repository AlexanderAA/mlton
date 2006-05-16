(* Copyright (C) 1999-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-2000 NEC Research Institute.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

structure CUtil: C_UTIL =
   struct
      open Int

      structure Pointer = Primitive.MLton.Pointer
         
      fun makeLength (sub, term) p =
         let
            fun loop i =
               if term (sub (p, i))
                  then i
                  else loop (i +? 1)
         in loop 0
         end

      fun toArrayOfLength (s: 'a,
                           sub: 'a * int -> 'b,
                           n: int) : 'b array =
         let
            val a = Array.arrayUninit n
            fun loop i =
               if i >= n
                  then ()
                  else (Array.update (a, i, sub (s, i))
                        ; loop (i + 1))
            val () = loop 0
         in 
            a
         end

      structure C_Pointer =
         struct
            type t = C_Pointer.t
            val null = Pointer.toWord Pointer.null
            fun isNull p = p = null
         end

      structure C_String =
         struct
            type t = C_String.t

            fun sub (cs, i) =
               Primitive.Char8.idFromWord8
               (Pointer.getWord8 
                (Pointer.fromWord cs, C_Ptrdiff.fromInt i))

            fun update (cs, i, c) =
               Pointer.setWord8 
               (Pointer.fromWord cs, C_Ptrdiff.fromInt i, 
                Primitive.Char8.idToWord8 c)

            fun toCharArrayOfLength (cs, n) = toArrayOfLength (cs, sub, n)

            fun toStringOfLength cs =
               String.fromArray (CharArray.fromPoly (toCharArrayOfLength cs))

            val length = makeLength (sub, fn #"\000" => true | _ => false)

            fun toString cs = toStringOfLength (cs, length cs)
         end
      
      structure C_StringArray =
         struct
            type t = C_StringArray.t

            fun sub (css: t, i) = 
               Pointer.getPointer 
               (Pointer.fromWord css, C_Ptrdiff.fromInt i)

            val length = makeLength (sub, Pointer.isNull)

            val toArrayOfLength =
               fn (css, n) => toArrayOfLength (css, C_String.toString o sub, n)

            fun toArray css = toArrayOfLength (css, length css)

            val toList = Array.toList o toArray

            (* The C side converts the last element of the array, "",
             * to the null terminator that C primitives expect.
             * As far as C can tell, the other elements of the array
             * are just char*'s.
             *)
            fun fromList l =
               let
                  val a = Array.array (1 +? List.length l, NullString.empty)
                  val _ =
                     List.foldl (fn (s, i) =>
                                 (Array.update (a, i, NullString.nullTerm s)
                                  ; i +? 1))
                     0 l
               in
                  a
               end
         end
   end
