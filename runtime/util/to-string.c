/* Copyright (C) 2004-2005 Henry Cejtin, Matthew Fluet, Suresh
 *    Jagannathan, and Stephen Weeks.
 *
 * MLton is released under a BSD-style license.
 * See the file MLton-LICENSE for details.
 */

#include "util.h"

const char* boolToString (bool b) {
  return b ? "TRUE" : "FALSE";
}

#define BUF_SIZE 81
char* intmaxToCommaString (intmax_t n) {
  static char buf1[BUF_SIZE];
  static char buf2[BUF_SIZE];
  static char buf3[BUF_SIZE];
  static char buf4[BUF_SIZE];
  static char buf5[BUF_SIZE];
  static char *bufs[] = {buf1, buf2, buf3, buf4, buf5};
  static int bufIndex = 0;
  static char *buf;
  int i;
  
  buf = bufs[bufIndex++];
  bufIndex %= 5;
        
  i = BUF_SIZE - 1;
  buf[i--] = '\000';
        
  if (0 == n)
    buf[i--] = '0';
  else if (INTMAX_MIN == n) {
    /* must treat INTMAX_MIN specially, because I negate stuff later */
    switch (sizeof(intmax_t)) {
    case 1:
      strcpy (buf + 1, "-128");
      break;
    case 2:
      strcpy (buf + 1, "-32,768");
      break;
    case 4:
      strcpy (buf + 1, "-2,147,483,648");
      break;
    case 8:
      strcpy (buf + 1, "-9,223,372,036,854,775,808");
      break;
    case 16:
      strcpy (buf + 1, "-170,141,183,460,469,231,731,687,303,715,884,105,728");
      break;
    default:
      die ("intmaxToCommaString: sizeof(intmax_t) = %zu", sizeof(intmax_t));
      break;
    }
    i = 0;
  } else {
    intmax_t m;
        
    if (n > 0) 
      m = n; 
    else 
      m = -n;
        
    while (m > 0) {
      buf[i--] = m % 10 + '0';
      m = m / 10;
      if (i % 4 == 0 and m > 0) buf[i--] = ',';
    }
    if (n < 0) buf[i--] = '-';
  }
  return buf + i + 1;
}

char* uintmaxToCommaString (uintmax_t n) {
  static char buf1[BUF_SIZE];
  static char buf2[BUF_SIZE];
  static char buf3[BUF_SIZE];
  static char buf4[BUF_SIZE];
  static char buf5[BUF_SIZE];
  static char *bufs[] = {buf1, buf2, buf3, buf4, buf5};
  static int bufIndex = 0;
  static char *buf;
  int i;
  
  buf = bufs[bufIndex++];
  bufIndex %= 5;
  
  i = BUF_SIZE - 1;
  buf[i--] = '\000';
  if (0 == n)
    buf[i--] = '0';
  else {
    while (n > 0) {
      buf[i--] = n % 10 + '0';
      n = n / 10;
      if (i % 4 == 0 and n > 0) buf[i--] = ',';
    }
  }
  return buf + i + 1;
}

char* sizeToBytesApproxString (size_t amount) {
  static char* suffixs[] = {"", "K", "M", "G"};
  static char buf1[BUF_SIZE];
  static char buf2[BUF_SIZE];
  static char buf3[BUF_SIZE];
  static char buf4[BUF_SIZE];
  static char buf5[BUF_SIZE];
  static char *bufs[] = {buf1, buf2, buf3, buf4, buf5};
  static int bufIndex = 0;
  static char *buf;
  size_t factor = 1;
  int suffixIndex = 0;
  
  buf = bufs[bufIndex++];
  bufIndex %= 5;

  while (amount > 1024 * factor
         and suffixIndex < 4) {
    factor *= 1024;
    amount /= factor;
    suffixIndex++;
  }
  sprintf (buf, "%zu%s", amount, suffixs[suffixIndex]);
  return buf;
}
#undef BUF_SIZE
