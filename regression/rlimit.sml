open MLton.Rlimit
val _ =
   List.app
   (fn r => set (r, get r))
   [cpuTime, coreFileSize, dataSize, fileSize, lockedInMemorySize, numFiles,
    numProcesses, residentSetSize, stackSize, virtualMemorySize]
val _ = print (concat [Word.toString infinity, "\n"])
