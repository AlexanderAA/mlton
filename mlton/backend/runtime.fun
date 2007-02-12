(* Copyright (C) 2002-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 *)

functor Runtime (S: RUNTIME_STRUCTS): RUNTIME =
struct

open S

structure GCField =
   struct
      datatype t =
         CanHandle
       | CardMap
       | CurrentThread
       | CurSourceSeqsIndex
       | ExnStack
       | Frontier
       | Limit
       | LimitPlusSlop
       | MaxFrameSize
       | SignalIsPending
       | StackBottom
       | StackLimit
       | StackTop

(*       val ty =
 *       fn CanHandle => CType.defaultInt
 *        | CardMap => CType.pointer
 *        | CurrentThread => CType.pointer
 *        | ExnStack => CType.defaultWord
 *        | Frontier => CType.pointer
 *        | Limit => CType.pointer
 *        | LimitPlusSlop => CType.pointer
 *        | MaxFrameSize => CType.defaultWord
 *        | SignalIsPending => CType.defaultInt
 *        | StackBottom => CType.pointer
 *        | StackLimit => CType.pointer
 *        | StackTop => CType.pointer
 *)

      val canHandleOffset: Bytes.t ref = ref Bytes.zero
      val cardMapOffset: Bytes.t ref = ref Bytes.zero
      val currentThreadOffset: Bytes.t ref = ref Bytes.zero
      val curSourceSeqsIndexOffset: Bytes.t ref = ref Bytes.zero
      val exnStackOffset: Bytes.t ref = ref Bytes.zero
      val frontierOffset: Bytes.t ref = ref Bytes.zero
      val limitOffset: Bytes.t ref = ref Bytes.zero
      val limitPlusSlopOffset: Bytes.t ref = ref Bytes.zero
      val maxFrameSizeOffset: Bytes.t ref = ref Bytes.zero
      val signalIsPendingOffset: Bytes.t ref = ref Bytes.zero
      val stackBottomOffset: Bytes.t ref = ref Bytes.zero
      val stackLimitOffset: Bytes.t ref = ref Bytes.zero
      val stackTopOffset: Bytes.t ref = ref Bytes.zero

      fun setOffsets {canHandle, cardMap, currentThread, curSourceSeqsIndex, 
                      exnStack, frontier, limit, limitPlusSlop, maxFrameSize, 
                      signalIsPending, stackBottom, stackLimit, stackTop} =
         (canHandleOffset := canHandle
          ; cardMapOffset := cardMap
          ; currentThreadOffset := currentThread
          ; curSourceSeqsIndexOffset := curSourceSeqsIndex
          ; exnStackOffset := exnStack
          ; frontierOffset := frontier
          ; limitOffset := limit
          ; limitPlusSlopOffset := limitPlusSlop
          ; maxFrameSizeOffset := maxFrameSize
          ; signalIsPendingOffset := signalIsPending
          ; stackBottomOffset := stackBottom
          ; stackLimitOffset := stackLimit
          ; stackTopOffset := stackTop)

      val offset =
         fn CanHandle => !canHandleOffset
          | CardMap => !cardMapOffset
          | CurrentThread => !currentThreadOffset
          | CurSourceSeqsIndex => !curSourceSeqsIndexOffset
          | ExnStack => !exnStackOffset
          | Frontier => !frontierOffset
          | Limit => !limitOffset
          | LimitPlusSlop => !limitPlusSlopOffset
          | MaxFrameSize => !maxFrameSizeOffset
          | SignalIsPending => !signalIsPendingOffset
          | StackBottom => !stackBottomOffset
          | StackLimit => !stackLimitOffset
          | StackTop => !stackTopOffset

      val canHandleSize: Bytes.t ref = ref Bytes.zero
      val cardMapSize: Bytes.t ref = ref Bytes.zero
      val currentThreadSize: Bytes.t ref = ref Bytes.zero
      val curSourceSeqsIndexSize: Bytes.t ref = ref Bytes.zero
      val exnStackSize: Bytes.t ref = ref Bytes.zero
      val frontierSize: Bytes.t ref = ref Bytes.zero
      val limitSize: Bytes.t ref = ref Bytes.zero
      val limitPlusSlopSize: Bytes.t ref = ref Bytes.zero
      val maxFrameSizeSize: Bytes.t ref = ref Bytes.zero
      val signalIsPendingSize: Bytes.t ref = ref Bytes.zero
      val stackBottomSize: Bytes.t ref = ref Bytes.zero
      val stackLimitSize: Bytes.t ref = ref Bytes.zero
      val stackTopSize: Bytes.t ref = ref Bytes.zero

      fun setSizes {canHandle, cardMap, currentThread, curSourceSeqsIndex, 
                    exnStack, frontier, limit, limitPlusSlop, maxFrameSize, 
                    signalIsPending, stackBottom, stackLimit, stackTop} =
         (canHandleSize := canHandle
          ; cardMapSize := cardMap
          ; currentThreadSize := currentThread
          ; curSourceSeqsIndexSize := curSourceSeqsIndex
          ; exnStackSize := exnStack
          ; frontierSize := frontier
          ; limitSize := limit
          ; limitPlusSlopSize := limitPlusSlop
          ; maxFrameSizeSize := maxFrameSize
          ; signalIsPendingSize := signalIsPending
          ; stackBottomSize := stackBottom
          ; stackLimitSize := stackLimit
          ; stackTopSize := stackTop)

      val size =
         fn CanHandle => !canHandleSize
          | CardMap => !cardMapSize
          | CurrentThread => !currentThreadSize
          | CurSourceSeqsIndex => !curSourceSeqsIndexSize
          | ExnStack => !exnStackSize
          | Frontier => !frontierSize
          | Limit => !limitSize
          | LimitPlusSlop => !limitPlusSlopSize
          | MaxFrameSize => !maxFrameSizeSize
          | SignalIsPending => !signalIsPendingSize
          | StackBottom => !stackBottomSize
          | StackLimit => !stackLimitSize
          | StackTop => !stackTopSize

      val toString =
         fn CanHandle => "CanHandle"
          | CardMap => "CardMap"
          | CurrentThread => "CurrentThread"
          | CurSourceSeqsIndex => "CurSourceSeqsIndex"
          | ExnStack => "ExnStack"
          | Frontier => "Frontier"
          | Limit => "Limit"
          | LimitPlusSlop => "LimitPlusSlop"
          | MaxFrameSize => "MaxFrameSize"
          | SignalIsPending => "SignalIsPending"
          | StackBottom => "StackBottom"
          | StackLimit => "StackLimit"
          | StackTop => "StackTop"

      val layout = Layout.str o toString
   end

structure RObjectType =
   struct
      datatype t =
         Array of {hasIdentity: bool,
                   bytesNonPointers: Bytes.t,
                   numPointers: int}
       | Normal of {hasIdentity: bool,
                    bytesNonPointers: Bytes.t,
                    numPointers: int}
       | Stack
       | Weak
       | WeakGone

      fun layout (t: t): Layout.t =
         let
            open Layout
         in
            case t of
               Array {hasIdentity, bytesNonPointers = np, numPointers = p} =>
                  seq [str "Array ",
                       record [("hasIdentity", Bool.layout hasIdentity),
                               ("bytesNonPointers", Bytes.layout np),
                               ("numPointers", Int.layout p)]]
             | Normal {hasIdentity, bytesNonPointers = np, numPointers = p} =>
                  seq [str "Normal ",
                       record [("hasIdentity", Bool.layout hasIdentity),
                               ("bytesNonPointers", Bytes.layout np),
                               ("numPointers", Int.layout p)]]
             | Stack => str "Stack"
             | Weak => str "Weak"
             | WeakGone => str "WeakGone"
         end
      val _ = layout (* quell unused warning *)
   end

val maxTypeIndex = Int.pow (2, 19)

fun typeIndexToHeader typeIndex =
   (Assert.assert ("Runtime.header", fn () =>
                   0 <= typeIndex
                   andalso typeIndex < maxTypeIndex)
    ; Word.orb (0w1, Word.<< (Word.fromInt typeIndex, 0w1)))

fun headerToTypeIndex w = Word.toInt (Word.>> (w, 0w1))

val labelSize = Bytes.inWord

val limitSlop = Bytes.fromInt 512

val normalHeaderSize = Bytes.inWord

val pointerSize = Bytes.inWord

val arrayLengthOffset = Bytes.~ (Bytes.scale (Bytes.inWord, 2))

val allocTooLarge = Bytes.fromWord 0wxFFFFFFFC

val headerOffset = Bytes.~ Bytes.inWord

val maxFrameSize = Bytes.fromInt (Int.pow (2, 16))

end
