/* Copyright (C) 2004-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

#include "cenv.h"
#include "util.h"

static char* prefix[] = {
  "/* Copyright (C) 2004-2005 Henry Cejtin, Matthew Fluet, Suresh",
  " *    Jagannathan, and Stephen Weeks.",
  " *",
  " * MLton is released under a BSD-style license.",
  " * See the file MLton-LICENSE for details.",
  " */",
  "",
  "/* Can't use _TYPES_H_ because MSVCRT uses it.",
  " * So, we use _MLTON_TYPES_H_.",
  " */",
  "",
  "#ifndef _MLTON_TYPES_H_",
  "#define _MLTON_TYPES_H_",
  "",
  "/* We need these because in header files for exported SML functions, ",
  " * types.h is included without cenv.h.",
  " */",
  "#ifndef _ISOC99_SOURCE",
  "#define _ISOC99_SOURCE",
  "#endif",
  "#if (defined (__OpenBSD__))",
  "#include <inttypes.h>",
  "#elif (defined (__sun__))",
  "#include <sys/int_types.h>",
  "#else",
  "#include <stdint.h>",
  "#endif",
  "",
  NULL
};

static char* stdtypes[] = {
  "/* ML types */",
  "typedef unsigned char* /* uintptr_t */ Pointer;",
  "#define Array(t) Pointer",
  "#define Ref(t) Pointer",
  "#define Vector(t) const Pointer",
  "",
  "typedef int8_t Int8_t;",
  "typedef int8_t Int8;",
  "typedef int16_t Int16_t;",
  "typedef int16_t Int16;",
  "typedef int32_t Int32_t;",
  "typedef int32_t Int32;",
  "typedef int64_t Int64_t;",
  "typedef int64_t Int64;",
  "typedef float Real32_t;",
  "typedef float Real32;",
  "typedef double Real64_t;",
  "typedef double Real64;",
  // "typedef long double Real128_t;",
  // "typedef long double Real128;",
  "typedef uint8_t Word8_t;",
  "typedef uint8_t Word8;",
  "typedef uint16_t Word16_t;",
  "typedef uint16_t Word16;",
  "typedef uint32_t Word32_t;",
  "typedef uint32_t Word32;",
  "typedef uint64_t Word64_t;",
  "typedef uint64_t Word64;",
  "",
  "typedef Int8_t WordS8_t;",
  "typedef Int8_t WordS8;",
  "typedef Int16_t WordS16_t;",
  "typedef Int16_t WordS16;",
  "typedef Int32_t WordS32_t;",
  "typedef Int32_t WordS32;",
  "typedef Int64_t WordS64_t;",
  "typedef Int64_t WordS64;",
  "",
  "typedef Word8_t WordU8_t;",
  "typedef Word8_t WordU8;",
  "typedef Word16_t WordU16_t;",
  "typedef Word16_t WordU16;",
  "typedef Word32_t WordU32_t;",
  "typedef Word32_t WordU32;",
  "typedef Word64_t WordU64_t;",
  "typedef Word64_t WordU64;",
  "",
  "typedef WordS8_t Char8_t;",
  "typedef WordS8_t Char8;",
  "typedef WordS16_t Char16_t;",
  "typedef WordS16_t Char16;",
  "typedef WordS32_t Char32_t;",
  "typedef WordS32_t Char32;",
  "",
  "typedef Vector(Char8_t) String8_t;",
  "typedef Vector(Char8_t) String8;",
  "typedef Vector(Char16_t) String16_t;",
  "typedef Vector(Char16_t) String16;",
  "typedef Vector(Char32_t) String32_t;",
  "typedef Vector(Char32_t) String32;",
  "",
  "typedef Int32_t Bool_t;",
  "typedef Int32_t Bool;",
  // "typedef Char8_t Char_t;",
  // "typedef Char8_t Char;",
  "typedef Int32_t Int_t;",
  "typedef Int32_t Int;",
  // "typedef Real64_t Real_t;",
  // "typedef Real64_t Real;",
  // "typedef String8_t String_t;",
  // "typedef String8_t String;",
  "typedef Word32_t Word_t;",
  "typedef Word32_t Word;",
  ""
  "typedef String8_t NullString8_t;",
  "typedef String8_t NullString8;",
  "typedef Array(NullString8_t) NullString8Array_t;",
  "typedef Array(NullString8_t) NullString8Array;",
  NULL
};

#define systype(t, bt, name)               \
  do {                                     \
  writeString (fd, "typedef ");            \
  writeString (fd, "/* ");                 \
  writeString (fd, #t);                    \
  writeString (fd, " */ ");                \
  writeString (fd, bt);                    \
  writeUintmaxU (fd, CHAR_BIT * sizeof(t));\
  writeString (fd, "_t ");                 \
  writeString (fd, name);                  \
  writeString (fd, ";");                   \
  writeNewline (fd);                       \
  } while (0)
#define chkintsystype(t, name)             \
  do {                                     \
  if ((double)((t)(-1)) > 0)               \
  systype(t, "Word", name);                \
  else                                     \
  systype(t, "Int", name);                 \
  } while (0)
#define chknumsystype(t, name)             \
  do {                                     \
  if ((double)((t)(0.25)) > 0)             \
  systype(t, "Real", name);                \
  else                                     \
  chkintsystype(t, name);                  \
  } while (0)

static char* suffix[] = {
  "",
  "#define C_Errno_t(t) t",
  "",
  "#endif /* _MLTON_TYPES_H_ */",
  NULL
};

int main (int argc, char* argv[]) {
  int fd;

  unlink_safe ("types.h");
  fd = open_safe ("types.h", O_RDWR | O_CREAT, S_IRUSR | S_IWUSR);
  for (int i = 0; prefix[i] != NULL; i++) {
    writeString (fd, prefix[i]);
    writeNewline (fd);
  }
  for (int i = 0; stdtypes[i] != NULL; i++) {
    writeString (fd, stdtypes[i]);
    writeNewline (fd);
  }
  writeNewline (fd);
  writeString (fd, "/* C */");
  writeNewline (fd);
  chkintsystype(char, "C_Char_t");
  systype(signed char, "Int", "C_SChar_t");
  systype(unsigned char, "Word", "C_UChar_t");
  systype(short, "Int", "C_Short_t");
  systype(unsigned short, "Word", "C_UShort_t");
  systype(int, "Int", "C_Int_t");
  systype(unsigned int, "Word", "C_UInt_t");
  systype(long, "Int", "C_Long_t");
  systype(unsigned long, "Word", "C_ULong_t");
  systype(long long, "Int", "C_LongLong_t");
  systype(unsigned long long, "Word", "C_ULongLong_t");
  systype(float, "Real", "C_Float_t");
  systype(double, "Real", "C_Double_t");
  // systype(long double, "Real", "C_LongDouble");
  systype(size_t, "Word", "C_Size_t");
  writeNewline (fd);
  systype(void*, "Word", "C_Pointer_t");
  systype(char*, "Word", "C_String_t");
  systype(char**, "Word", "C_StringArray_t");
  writeNewline (fd);
  writeString (fd, "/* C99 */");
  writeNewline (fd);
  systype(_Bool, "Word", "C_Bool_t");
  systype(intmax_t, "Int", "C_Intmax_t");
  systype(uintmax_t, "Word", "C_UIntmax_t");
  systype(intptr_t, "Int", "C_Intptr_t");
  systype(uintptr_t, "Word", "C_UIntptr_t");
  writeNewline (fd);
  writeString (fd, "/* Generic integers */");
  writeNewline (fd);
  systype(int, "Int", "C_Fd_t");
  systype(int, "Int", "C_Signal_t");
  systype(int, "Int", "C_Status_t");
  systype(int, "Int", "C_Sock_t");
  writeNewline (fd);
  writeString (fd, "/* from <dirent.h> */");
  writeNewline (fd);
  systype(DIR*, "Word", "C_DirP_t");
  writeNewline (fd);
  writeString (fd, "/* from <poll.h> */");
  writeNewline (fd);
  systype(nfds_t, "Word", "C_NFds_t");
  writeNewline (fd);
  writeString (fd, "/* from <sys/resource.h> */");
  writeNewline (fd);
  systype(rlim_t, "Word", "C_RLim_t");
  writeNewline (fd);
  writeString (fd, "/* from <sys/types.h> */");
  writeNewline (fd);
  // systype(blkcnt_t, "Int", "C_BlkCnt_t");
  // systype(blksize_t, "Int", "C_BlkSize_t");
  chknumsystype(clock_t, "C_Clock_t");
  chknumsystype(dev_t, "C_Dev_t");
  chkintsystype(gid_t, "C_GId_t");
  chkintsystype(id_t, "C_Id_t");
  systype(ino_t, "Word", "C_INo_t");
  chkintsystype(mode_t, "C_Mode_t");
  chkintsystype(nlink_t, "C_NLink_t");
  systype(off_t, "Int", "C_Off_t");
  systype(pid_t, "Int", "C_PId_t");
  systype(ssize_t, "Int", "C_SSize_t");
  systype(suseconds_t, "Int", "C_SUSeconds_t");
  chknumsystype(time_t, "C_Time_t");
  chkintsystype(uid_t, "C_UId_t");
  systype(useconds_t, "Word", "C_USeconds_t");
  writeNewline (fd);
  writeString (fd, "/* from <sys/socket.h> */");
  writeNewline (fd);
  chkintsystype(socklen_t, "C_Socklen_t");
  writeNewline (fd);
  writeString (fd, "/* from <termios.h> */");
  writeNewline (fd);
  systype(cc_t, "Word", "C_CC_t");
  systype(speed_t, "Word", "C_Speed_t");
  systype(tcflag_t, "Word", "C_TCFlag_t");
  writeNewline (fd);
  for (int i = 0; suffix[i] != NULL; i++) {
    writeString (fd, suffix[i]);
    writeNewline (fd);
  }
  return 0;
}
