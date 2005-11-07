#include "platform.h"

#ifndef DEBUG_PROFILE
#define DEBUG_PROFILE FALSE
#endif

extern struct GC_state gcState;

void MLton_Profile_Data_free (Pointer p) {
        GC_profileFree (&gcState, (GC_profileData)p);
}

Pointer MLton_Profile_Data_malloc (void) {
        return (Pointer)GC_profileNew (&gcState);
}

void MLton_Profile_Data_write (Pointer p, Word fd) {
        if (DEBUG_PROFILE)
                fprintf (stderr, "MLton_Profile_Data_write (0x%08x)\n", (uint)p);
        GC_profileWrite (&gcState, (GC_profileData)p, (int)fd);
}

Pointer MLton_Profile_current (void) {
        Pointer res;

        res = (Pointer)(GC_getProfileCurrent (&gcState));
        if (DEBUG_PROFILE)
                fprintf (stderr, "0x%08x = MLton_Profile_current ()\n", 
                                (uint)res);
        return res;
}

void MLton_Profile_setCurrent (Pointer d) {
        if (DEBUG_PROFILE)
                fprintf (stderr, "MLton_Profile_setCurrent (0x%08x)\n", (uint)d);
        GC_setProfileCurrent (&gcState, (GC_profileData)d);
}

void MLton_Profile_done () {
        GC_profileDone (&gcState);
}
