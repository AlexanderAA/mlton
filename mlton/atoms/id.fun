(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
structure IdCounter:
   sig
      val getCounter: string -> Counter.t
   end =
   struct
      val getCounter = String.memoize (fn _ => Counter.new 0)
   end

functor HashId (S: ID_STRUCTS): HASH_ID =
struct

open S

structure Plist = PropertyList
   
datatype t = T of {originalName: string,
		   printName: string option ref,
		   hash: Word.t,
		   plist: Plist.t}

local
   fun make f (T r) = f r
in
   val hash = make #hash
   val plist = make #plist
   val originalName = make #originalName
end

fun setPrintName (T {printName, ...}, s) = printName := SOME s

fun toString (T {printName, originalName, ...}) =
   case !printName of
      NONE =>
	 let
	    val s =
	       concat [String.translate (originalName, fn c =>
					 case c of
					    #"'" => "P"
					  | #"." => "D"
					  | c => str c),
		       "_",
		       Int.toString (Counter.next
				     (IdCounter.getCounter originalName))]
	 in printName := SOME s
	    ; s
	 end
    | SOME s => s

val layout = String.layout o toString
   
fun sameName (id, id') = 
   String.equals (originalName id, originalName id')

fun equals (id, id') = Plist.equals (plist id, plist id')

fun fromString s =
   T {originalName = s,
      printName = ref (SOME s),
      hash = Random.word (),
      plist = Plist.new ()}
   
fun isOperator s =
   let val c = String.sub (s, 0)
   in not (Char.isAlpha c orelse Char.equals (c, #"'"))
   end

fun translateOperator s =
   let val map
         = fn #"!" => "Bang"
            | #"%" => "Percent"
            | #"&" => "Ampersand"
            | #"$" => "Dollar"
            | #"#" => "Hash"
            | #"+" => "Plus"
            | #"-" => "Minus"
            | #"/" => "Divide"
            | #":" => "Colon"
            | #"<" => "Lt"
            | #"=" => "Eq"
            | #">" => "Gt"
            | #"?" => "Ques"
            | #"@" => "At"
            | #"\\" => "Slash"
            | #"~" => "Tilde"
            | #"`" => "Quote"
            | #"^" => "Caret"
            | #"|" => "Pipe"
            | #"*" => "Star"
            | _ => ""
   in
     "operator" ^ (String.translate(s, map))
   end

fun newString s =
   let val s = if isOperator s then translateOperator s else s
   in fn () => T {originalName = s,
		  printName = ref NONE,
		  hash = Random.word (),
		  plist = Plist.new ()}
   end

val newNoname = newString noname

val newString = fn s => newString s ()
   
val bogus = newString "BOGUS"

fun new (T {originalName, ...}) =
   T {originalName = originalName,
      printName = ref NONE,
      hash = Random.word (),
      plist = Plist.new ()}

val clear = Plist.clear o plist
   
end


functor Id (S: ID_STRUCTS): ID = HashId (S)
