(* Copyright (C) 1999-2002 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 * Copyright (C) 1997-1999 NEC Research Institute.
 *
 * MLton is released under the GNU General Public License (GPL).
 * Please see the file MLton-LICENSE for license information.
 *)
structure Main =
struct

type int = Int.t
type word = Word.t

val busy = ref false : bool ref
val color = ref false
val static = ref false (* include static C functions *)
val thresh = ref 0 : int ref
val extra = ref false

val die = Process.fail
val warn = fn s => Out.output (Out.error, concat ["Warning: ", s, "\n"])

fun die s =
   (Out.output (Out.error, s)
    ; Out.newline Out.error
    ; Process.fail "die")
   
structure Regexp =
struct
  open Regexp
      
  val eol = seq [star (oneOf "\t "), string "\n"]
  val hexDigit = isChar Char.isHexDigit
  val hexDigits = oneOrMore hexDigit
  val identifier = seq [isChar Char.isAlpha,
			star (isChar (fn #"_" => true
				       | #"'" => true
				       | c => Char.isAlphaNum c))]
end

structure StringMap:
sig
  type 'a t

  val foldi: 'a t * 'b * (string * 'a * 'b -> 'b) -> 'b
  val insertIfNew: 'a t * string * 'a * (unit -> unit) -> 'a
  val layout: ('a -> Layout.t) -> 'a t -> Layout.t
  val lookup: 'a t * string -> 'a
  val lookupOrInsert: 'a t * string * (unit -> 'a) -> 'a
  val new: unit -> 'a t
end =
struct
  datatype 'a t = T of (word * String.t * 'a) HashSet.t

  fun layout lay (T h)
    = HashSet.layout (fn (_, s, a) => Layout.tuple [String.layout s, lay a]) h

  fun new () = T (HashSet.new {hash = #1})
    
  fun foldi (T t, b, f)
    = HashSet.fold (t, b, fn ((_, s, a), ac) => f (s, a, ac))
	 
  fun lookupOrInsert (T t, s, f)
    = let
	val w = String.hash s
      in
	#3 (HashSet.lookupOrInsert
	    (t, w,
	     fn (w', s', _) => w = w' andalso s = s',
	     fn () => (w, s, f ())))
      end
	 
  fun insertIfNew (T t, s, a, old) 
    = let
	val w = String.hash s
	val (_, _, a)
	  = HashSet.lookupOrInsert
	    (t, w,
	     fn (w', s', _) => w = w' andalso s = s' andalso (old (); true),
	     fn () => (w, s, a))
      in 
	a
      end
	 
  fun peek (T t, s)
    = let
	val w = String.hash s
      in
	Option.map
	(HashSet.peek (t, w, fn (w', s', _) => w = w' andalso s = s'),
	 #3)
      end

  fun contains z = isSome (peek z)
  fun lookup z = valOf (peek z)
end

structure ProfileInfo =
struct
   datatype 'a t = T of {data: 'a,
			 minor: 'a t} list

   local
      open Layout
   in
      fun layout lay (T l)
	 = List.layout 
	   (fn {data, minor} => seq [str "{",
				     lay data,
				     layout lay minor,
				     str "}"])
	   l
   end
end

structure AFile =
   struct
      datatype t = T of {etext: word,
			 start: word,
			 data: {addr: word,
				profileInfo: {name: string} ProfileInfo.t} list}

      fun layout (T {data, ...}) =
	 let 
	    open Layout
	 in 
	    List.layout
	    (fn {addr, profileInfo} 
	     => seq [Word.layout addr,
		     str " ",
		     ProfileInfo.layout (fn {name} => str name) profileInfo])
	    data
	 end

      structure Match = Regexp.Match
      fun new {afile: File.t}: t =
	 let
	    local
	       open Regexp
	    in
	       val level = Save.new ()
	       val name = Save.new ()
	       val profileInfoC =
		  compileDFA (seq [save (digits, level),
				   char #".",
				   save (identifier, name),
				   string "$$"])
	       val profileInfo = Save.new ()
	       val profileLabelRegexp =
		  seq [string "MLtonProfile",
		       digits,
		       string "$$",
		       save (star (seq [digits,
					char #".",
					identifier,
					string "$$"]),
			     profileInfo),
		       string "Begin"]
	       val addr = Save.new ()
	       val kind = Save.new ()
	       val label = Save.new ()
	       val start = Save.new ()
	       val etext = Save.new ()
	       val symbolC =
		  compileDFA
		  (or [seq [save (hexDigits, start),
			    string " T _start",
			    eol],
		       seq [save (hexDigits, etext),
			    string " A etext",
			    eol],
		       seq [save (hexDigits, addr),
			    char #" ",
			    save (char #"t", kind),
			    char #" ",
			    profileLabelRegexp,
			    eol],
		       seq [save (hexDigits, addr),
			    char #" ",
			    save (oneOf (if !static then "tT" else "T"), kind),
			    char #" ",
			    save (identifier, label),
			    eol]])
	       val _ =
		  if true
		     then ()
		  else (Layout.outputl (Compiled.layout symbolC, Out.standard)
			; Compiled.layoutDotToFile (symbolC, "symbol.dot"))
	    end
	    val startRef = ref NONE
	    val etextRef = ref NONE
	    val l
	       = Process.callWithIn
	       ("nm", ["-n", afile], fn ins =>
		In.foldLines
		(ins, [], fn (line, ac) =>
		 case Regexp.Compiled.matchAll (symbolC, line) of
		    NONE => ac
		  | SOME m =>
		       let
			  val {lookup, peek, ...} = Regexp.Match.stringFuns m
			  fun normal () =
			     let
				val addr = valOf (Word.fromString (lookup addr))
				val profileInfo =
				   case peek label of
				      SOME label =>
					 let
					    val kind = lookup kind
					    val level =
					       if kind = "T" then ~1 else ~2
					 in [{profileLevel = level,
					      profileName = label}]
					 end
				    | NONE =>
					 let
					    val profileInfo = lookup profileInfo
					    val length = String.size profileInfo
					    fun loop pos =
					       case (Regexp.Compiled.matchShort
						     (profileInfoC,
						      profileInfo, pos)) of
						  NONE => []
						| SOME m =>
						     let
							val {lookup, ...} =
							   Match.stringFuns m
							val level =
							   valOf (Int.fromString
								  (lookup level))
							val name = lookup name
						     in
							{profileLevel = level,
							 profileName = name}
							:: loop (pos + Match.length m)
						     end	
					 in loop 0
					 end
			     in
				{addr = addr, profileInfo = profileInfo} :: ac
			     end
		       in
			  case peek start of
			     SOME s =>
				(startRef := SOME (valOf (Word.fromString s))
				 ; ac)
			   | NONE =>
				case peek etext of
				   SOME s =>
				      (etextRef :=
				       SOME (valOf (Word.fromString s))
				       ; ac)
				 | NONE => normal ()
		       end))

	    fun shrink {addr, profileInfo : {profileLevel: int,
					 profileName: string} list}
	  = let
	      val profileInfo 
		= List.fold
		  (profileInfo,
		   [],
		   fn (v, profileInfo)
		    =>
		       if List.contains (profileInfo, v, op =)
			  then profileInfo
		       else
			  List.insert
			  (profileInfo, 
			   v, 
			   fn ({profileLevel = pL1, profileName = pN1},
			       {profileLevel = pL2, profileName = pN2}) 
			   => if pL1 = pL2
				 then String.<= (pN1, pN2)
			      else Int.<= (pL1, pL2)))

	      val profileInfo
		= List.foldr
		  (profileInfo,
		   [],
		   fn (v as {profileLevel, profileName}, profileInfo)
		    => if profileLevel < 0
			 then if List.exists
			         (profileInfo,
				  fn {profileName = profileName', ...}
				   => profileName = profileName')
				then profileInfo
				else let
				       val profileName
					 = if profileLevel = ~1
					     then profileName ^ " (C)"
					     else concat [profileName,
							  " (C @ 0x",
							  Word.toString addr,
							  ")"]
				     in
				       {profileLevel = 0,
					profileName = profileName}::
				       profileInfo
				     end
			 else v::profileInfo)

	      fun loop (profileInfo, n)
		= let
		    val {yes, no}
		      = List.partition
		        (List.rev profileInfo,
			 fn {profileLevel, profileName} => profileLevel = n)
		  in
		    if List.isEmpty yes
		       then ProfileInfo.T []
		    else let
			    val name 
			       = concat (List.separate
					 (List.map (yes, #profileName),
					  ","))
			    val minor = loop (no, n + 1)
			 in
			    ProfileInfo.T [{data = {name = name},
					    minor = minor}]
			 end
		  end

	      val profileInfo = loop (profileInfo, 0)
	    in
	      {addr = addr, profileInfo = profileInfo}
	    end

	val rec compress
	  = fn [] => []
	     | [v] => [shrink v]
	     | (v1 as {addr = addr1,
		       profileInfo = profileInfo1})::
	       (v2 as {addr = addr2,
		       profileInfo = profileInfo2})::
	       l
	     => if addr1 = addr2
		  then compress ({addr = addr1,
				  profileInfo = profileInfo1 @ profileInfo2}::
				 l)
		  else (shrink v1):: (compress (v2::l))

	val l = List.rev (compress l)
	val start =
	   case !startRef of
	      NONE => die "couldn't find _start label"
	    | SOME w => w
	val etext =
	   case !etextRef of
	      NONE => die "couldn't find _etext label"
	    | SOME w => w
      in
	T {data = l,
	   etext = etext,
	   start = start}
      end

  val new = Trace.trace ("AFile.new", File.layout o #afile, layout) new
end

structure ProfFile =
struct
   (* Profile information is a list of buckets, sorted in increasing order of
    * address, with count always greater than 0.
    *)
  datatype t = T of {buckets: {addr: word,
			       count: IntInf.t} list,
		     etext: word,
		     magic: word,
		     start: word}

  fun layout (T {buckets, ...}) 
    = let 
	open Layout
      in 
	List.layout
	(fn {addr, count} => seq [Word.layout addr, str " ", IntInf.layout count])
	buckets
      end

  fun new {mlmonfile: File.t}: t 
    = File.withIn
      (mlmonfile, 
       fn ins
        => let
	     fun read (size: int): string 
	       = let 
		   val res = In.inputN (ins, size)
		 in 
		   if size <> String.size res
		     then die "Unexpected EOF"
		     else res
		 end
	     fun getString size = read size
	     fun getChar ():char 
	       = let val s = read 1
		 in String.sub (s, 0)
		 end 
	     fun getWord (): word
	       = let val s = read 4
		     fun c i = Word.fromInt (Char.toInt (String.sub (s, i)))
		 in Word.orb (Word.orb (Word.<< (c 3, 0w24),
					Word.<< (c 2, 0w16)),
			      Word.orb (Word.<< (c 1, 0w8), 
					Word.<< (c 0, 0w0)))
		 end
	     fun getHWord (): word
	       = let val s = read 2
		     fun c i = Word.fromInt (Char.toInt (String.sub (s, i)))
		 in Word.orb (Word.<< (c 1, 0w8), 
			     Word.<< (c 0, 0w0))
		 end
	     fun getQWord (): word
	       = let val s = read 1
		     fun c i = Word.fromInt (Char.toInt (String.sub (s, i)))
		 in Word.<< (c 0, 0w0)
		 end
	     val _ =
		if "MLton prof\n\000" <> getString 12
		   then
		      die (concat [mlmonfile,
				   " does not appear to be a mlmon.out file"])
		else ()
	     val getAddr = getWord
	     val magic = getWord ()
	     val start = getAddr ()
	     val etext = getAddr ()
	     fun loop ac =
		if In.endOf ins
		   then rev ac
		else let
			val addr = getAddr ()
			val _ =
			   if addr < start orelse addr >= etext
			      then die "bad addr"
			   else ()
			val count = IntInf.fromInt (Word.toInt (getWord ()))
			val _ =
			   if count = IntInf.fromInt 0
			      then die "zero count"
			   else ()
		     in
			loop ({addr = addr, count = count} :: ac)
		     end
	     val buckets = loop []
	   in 
	     T {buckets = buckets,
		etext = etext,
		magic = magic,
		start = start}
	   end)

  val new = Trace.trace ("ProfFile.new", File.layout o #mlmonfile, layout) new

  fun merge (T {buckets = b, etext = e, magic = m, start = s},
	     T {buckets = b', etext = e', magic = m', start = s'}) =
     if m <> m' orelse e <> e' orelse s <> s'
	then die "incompatible mlmon files"
     else
	let
	   fun loop (buckets, buckets', ac) =
	      case (buckets, buckets') of
		 ([], buckets') => List.appendRev (ac, buckets')
	       | (buckets, []) => List.appendRev (ac, buckets)
	       | (buckets as {addr, count}::bs,
		  buckets' as {addr = addr', count = count'}::bs') =>
		 (case Word.compare (addr, addr')
		     of LESS => loop (bs, buckets', 
				      {addr = addr, count = count}::ac)
		   | EQUAL => loop (bs, bs', 
				    {addr = addr,
				     count = IntInf.+ (count, count')}
				    :: ac)
		   | GREATER => loop (buckets, bs', 
				      {addr = addr', count = count'}::ac))
	in
	   T {buckets = loop (b, b', []),
	      etext = e,
	      magic = m,
	      start = s}
	end
	     
  fun addNew (pi, mlmonfile: File.t): t =
     merge (pi, new {mlmonfile = mlmonfile})

  val addNew = Trace.trace ("ProfFile.addNew", File.layout o #2, layout) addNew
end

fun attribute (AFile.T {data, etext = e, start = s}, 
	       ProfFile.T {buckets, etext = e', start = s', ...}) : 
    {profileInfo: {name: string} ProfileInfo.t,
     ticks: IntInf.t} list
  = let
       val _ =
	  if e <> e' orelse s <> s'
	     then die "incompatible a.out and mlmon.out"
	  else ()
      fun loop (profileInfoCurrent, ticks, l, buckets)
	= let
	    fun done (ticks, rest)
	      = if IntInf.equals (IntInf.fromInt 0, ticks)
		   then rest
		else {profileInfo = profileInfoCurrent,
		      ticks = ticks} :: rest
	  in
	    case (l, buckets)
	      of (_, []) => done (ticks, [])
	       | ([], _) => done (List.fold (buckets, ticks, 
					     fn ({count, ...}, ticks) =>
					     IntInf.+ (count, ticks)),
				  [])
	       | ({addr = profileAddr, profileInfo}::l', 
		  {addr = bucketAddr, count}::buckets')
	       => if profileAddr <= bucketAddr
		    then done (ticks,
			       loop (profileInfo, IntInf.fromInt 0, l', buckets))
		    else loop (profileInfoCurrent,
			       IntInf.+ (ticks, count), l, buckets')
	  end
    in
      loop (ProfileInfo.T ([{data = {name = "<unknown>"},
			     minor = ProfileInfo.T []}]),
	    IntInf.fromInt 0, data, buckets)
    end

fun coalesce (counts: {profileInfo: {name: string} ProfileInfo.t,
		       ticks: IntInf.t} list)
   : {name: string, ticks: IntInf.t} ProfileInfo.t =
   let
      datatype t = T of {ticks': IntInf.t ref, map': t StringMap.t ref}
      val map = StringMap.new ()
      val _ 
	= List.foreach
	  (counts,
	   fn {profileInfo, ticks}
	    => let
		 fun doit (ProfileInfo.T profileInfo, map)
		   = List.foreach
		     (profileInfo,
		      fn {data = {name}, minor}
		       => let
			    val T {ticks', map'} 
			      = StringMap.lookupOrInsert
			        (map, 
				 name, 
				 fn () => T {ticks' = ref (IntInf.fromInt 0),
					     map' = ref (StringMap.new ())})
			  in
			    ticks' := IntInf.+ (!ticks', ticks);
			    doit (minor, !map')
			  end)
	       in
		 doit (profileInfo, map)
	       end)

      fun doit map
	= ProfileInfo.T
	  (StringMap.foldi
	   (map,
	    [],
	    (fn (name, T {map', ticks'}, profileInfo)
	      => {data = {name = name, ticks = !ticks'},
		  minor = doit (!map')}::profileInfo)))
    in
      doit map
    end

val replaceLine =
   Promise.lazy
   (fn () =>
    let
       open Regexp
       val beforeColor = Save.new ()
       val label = Save.new ()
       val afterColor = Save.new ()
       val nodeLine =
	  seq [save (seq [anys, string "fontcolor = ", dquote], beforeColor),
	       star (notOneOf String.dquote),
	       save (seq [dquote,
			  anys,
			  string "label = ", dquote,
			  save (star (notOneOf " \\"), label),
			  oneOf " \\",
			  anys,
			  string "\n"],
		     afterColor)]
       val c = compileNFA nodeLine
       val _ = if true
	          then ()
	       else Compiled.layoutDotToFile (c, "/tmp/z.dot")
    in
       fn (l, color) =>
       case Compiled.matchAll (c, l) of
	  NONE => l
	| SOME m =>
	     let
		val {lookup, ...} = Match.stringFuns m
	     in
		concat [lookup beforeColor,
			color (lookup label),
			lookup afterColor]
	     end
    end)

fun display (counts: {name: string, ticks: IntInf.t} ProfileInfo.t,
	     baseName: string,
	     depth: int) =
   let
      val ticksPerSecond = 100.0
      val thresh = Real.fromInt (!thresh)
      datatype t = T of {name: string,
			 ticks: IntInf.t,
			 row: string list,
			 minor: t} array
      fun doit (info as ProfileInfo.T profileInfo,
		n: int,
		dotFile: File.t,
		stuffing: string list,
		totals: real list) =
	 let
	    val total =
	       List.fold
	       (profileInfo, IntInf.fromInt 0,
		fn ({data = {ticks, ...}, ...}, total) =>
		IntInf.+ (total, ticks))
	    val total = Real.fromIntInf total
	    val _ =
	       if n = 0
		  then print (concat ([Real.format (total / ticksPerSecond, 
						    Real.Format.fix (SOME 2)),
				       " seconds of CPU time\n"]))
	       else ()
	    val space = String.make (5 * n, #" ")
	    val profileInfo =
	       List.fold
	       (profileInfo, [], fn ({data = {name, ticks}, minor}, ac) =>
		let
		   val rticks = Real.fromIntInf ticks
		   fun per total = 100.0 * rticks / total
		in
		   if per total < thresh
		      then ac
		   else
		      let
			 val per =
			    fn total =>
			    concat [Real.format (per total,
						 Real.Format.fix (SOME 2)),
				    "%",
				    if !extra
				      then concat [" (",
						   Real.format
						   (rticks / ticksPerSecond,
						    Real.Format.fix (SOME 2)),
						   "s)"]
				      else ""]
		      in			    
			 {name = name,
			  ticks = ticks,
			  row = (List.concat
				 [[concat [space, name]],
				  stuffing,
				  [per total],
				  if !busy
				     then List.map (totals, per)
				  else (List.duplicate
					(List.length totals, fn () => ""))]),
			  minor = if n < depth
				     then doit (minor, n + 1,
						concat [baseName, ".",
							name, ".cfg.dot"],
						tl stuffing, total :: totals)
				  else T (Array.new0 ())}
			 :: ac
		      end
		end)
	    val a = Array.fromList profileInfo
	    val _ =
	       QuickSort.sort
	       (a, fn ({ticks = t1, ...}, {ticks = t2, ...}) =>
		IntInf.>= (t1, t2))
	    (* Colorize. *)
	    val _ =
	       if n > 1 orelse not(!color) orelse 0 = Array.length a
		  then ()
	       else
		  let
		     val ticks: real =
			Real.fromIntInf (#ticks (Array.sub (a, 0)))
		     fun thresh r = Real.toIntInf (Real.* (ticks, r))
		     val thresh1 = thresh (2.0 / 3.0)
		     val thresh2 = thresh (1.0 / 3.0)
		     datatype z = datatype DotColor.t
		     fun color l =
			DotColor.toString
			(case Array.peek (a, fn {name, ...} =>
					  String.equals (l, name)) of
			    NONE => Black
			  | SOME {ticks, ...} =>
			       if IntInf.>= (ticks, thresh1)
				  then Red1
			       else if IntInf.>= (ticks, thresh2)
				       then Orange2
				    else Yellow3)
		  in
		     if not (File.doesExist dotFile)
			then ()
		     else
			let
			   val replaceLine = replaceLine ()
			   val lines = File.lines dotFile
			in
			   File.withOut
			   (dotFile, fn out =>
			    List.foreach
			    (lines, fn l =>
			     Out.output (out, replaceLine (l, color))))
			end
		  end
	 in T a
	 end
      fun toList (T a, ac) =
	 Array.foldr (a, ac, fn ({row, minor, ...}, ac) =>
		      row :: toList (minor, ac))
      val rows = toList (doit (counts, 0,
			       concat [baseName, ".call-graph.dot"],
			       List.duplicate (depth, fn () => ""),
			       []),
			 [])
      val _ =
	 let
	    open Justify
	 in outputTable
	    (table {justs = Left :: (List.duplicate (depth + 1, fn () => Right)),
		    rows = rows},
	     Out.standard)
	 end
   in
      ()
   end

fun usage s
  = Process.usage 
    {usage = "[-color] [-d {0|1|2}] [-s] [-t n] [-x] a.out mlmon.out [mlmon.out ...]",
     msg = s}

fun main args =
   let
      val depth = ref 0
      val rest
	= let
	    open Popt
	  in
	    parse
	    {switches = args,
	     opts = [("b", trueRef busy),
		     ("color", trueRef color),
		     ("d", Int (fn i => if i < 0 orelse i > 2
					  then die "invalid depth"
					  else depth := i)),
		     ("s", trueRef static),
		     ("t", Int (fn i => if i < 0 orelse i > 100
					  then die "invalid threshold"
					  else thresh := i)),
		     ("x", trueRef extra)]}
	  end
    in
      case rest 
	of Result.No s => usage (concat ["invalid switch: ", s])
	 | Result.Yes (afile::mlmonfile::mlmonfiles)
	 => let
	      val aInfo = AFile.new {afile = afile}
	      val _ =
		 if true
		    then ()
		 else (print "AFile:\n"
		       ; Layout.outputl (AFile.layout aInfo, Out.standard))
	      val profInfo = ProfFile.new {mlmonfile = mlmonfile}	
	      val profInfo =
		 List.fold
		 (mlmonfiles, profInfo, fn (mlmonfile, profInfo) =>
		  ProfFile.addNew (profInfo, mlmonfile))
	      val _ =
		 if true
		    then ()
		 else (print "ProfFile:\n"
		       ; Layout.outputl (ProfFile.layout profInfo, Out.standard))
	      val info = coalesce (attribute (aInfo, profInfo))
	      val _ = display (info, afile, !depth)
	    in
	       ()
	    end
	 | Result.Yes _ => usage "wrong number of args"
    end

val main = Process.makeMain main

end
