#include "platform.h"

extern struct GC_state gcState;

static struct rusage self;
static struct rusage children;
static struct rusage gc;

C_Time_t MLton_Rusage_self_utime_sec (void) {
  return self.ru_utime.tv_sec;
}

C_SUSeconds_t MLton_Rusage_self_utime_usec (void) {
  return self.ru_utime.tv_usec;
}

C_Time_t MLton_Rusage_self_stime_sec (void) {
  return self.ru_stime.tv_sec;
}

C_SUSeconds_t MLton_Rusage_self_stime_usec (void) {
  return self.ru_stime.tv_usec;
}

C_Time_t MLton_Rusage_children_utime_sec (void) {
  return children.ru_utime.tv_sec;
}

C_SUSeconds_t MLton_Rusage_children_utime_usec (void) {
  return children.ru_utime.tv_usec;
}

C_Time_t MLton_Rusage_children_stime_sec (void) {
  return children.ru_stime.tv_sec;
}

C_SUSeconds_t MLton_Rusage_children_stime_usec (void) {
  return children.ru_stime.tv_usec;
}

C_Time_t MLton_Rusage_gc_utime_sec (void) {
  return gc.ru_utime.tv_sec;
}

C_SUSeconds_t MLton_Rusage_gc_utime_usec (void) {
  return gc.ru_utime.tv_usec;
}

C_Time_t MLton_Rusage_gc_stime_sec (void) {
  return gc.ru_stime.tv_sec;
}

C_SUSeconds_t MLton_Rusage_gc_stime_usec (void) {
  return gc.ru_stime.tv_usec;
}

void MLton_Rusage_getrusage (void) {
  gc = *(GC_getRusageGCAddr (&gcState));
  getrusage (RUSAGE_SELF, &self);
  getrusage (RUSAGE_CHILDREN, &children);
}
