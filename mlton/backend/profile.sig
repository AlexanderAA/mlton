type int = Int.t
type word = Word.t
   
signature PROFILE_STRUCTS = 
   sig
      structure Rssa: RSSA
   end

signature PROFILE = 
   sig
      include PROFILE_STRUCTS
      
      val profile:
	 Rssa.Program.t -> {frameProfileIndices: (Rssa.Label.t * int) vector,
			    labels: {label: Rssa.ProfileLabel.t,
				     sourceSeqsIndex: int} vector,
			    program: Rssa.Program.t,
			    sourceSeqs: int vector vector,
			    sourceSuccessors: int vector,
			    sources: Rssa.SourceInfo.t vector}
   end
