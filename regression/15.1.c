/* MLton g9a43e11 (built Sun Apr  5 22:29:53 NZST 2015 on xeon) */
/*   created this file on Sun Apr 05 23:03:31 2015. */
/* Do not edit this file. */
/* Flag settings:  */
/*    align: 8 */
/*    atMLtons: (15, @MLton, --) */
/*    chunk: chunk per function */
/*    closureConvertGlobalize: true */
/*    closureConvertShrink: true */
/*    codegen: amd64 */
/*    contifyIntoMain: false */
/*    debug: false */
/*    defaultChar: char8 */
/*    defaultWideChar: widechar32 */
/*    defaultInt: int32 */
/*    defaultReal: real64 */
/*    defaultWord: word32 */
/*    diag passes: [] */
/*    drop passes: [] */
/*    elaborate allowConstant (default): false */
/*    elaborate allowConstant (enabled): true */
/*    elaborate allowFFI (default): false */
/*    elaborate allowFFI (enabled): true */
/*    elaborate allowPrim (default): false */
/*    elaborate allowPrim (enabled): true */
/*    elaborate allowOverload (default): false */
/*    elaborate allowOverload (enabled): true */
/*    elaborate allowRebindEquals (default): false */
/*    elaborate allowRebindEquals (enabled): true */
/*    elaborate deadCode (default): false */
/*    elaborate deadCode (enabled): true */
/*    elaborate forceUsed (default): false */
/*    elaborate forceUsed (enabled): true */
/*    elaborate ffiStr (default):  */
/*    elaborate ffiStr (enabled): true */
/*    elaborate nonexhaustiveExnMatch (default): default */
/*    elaborate nonexhaustiveExnMatch (enabled): true */
/*    elaborate nonexhaustiveMatch (default): warn */
/*    elaborate nonexhaustiveMatch (enabled): true */
/*    elaborate redundantMatch (default): warn */
/*    elaborate redundantMatch (enabled): true */
/*    elaborate resolveScope (default): strdec */
/*    elaborate resolveScope (enabled): true */
/*    elaborate sequenceNonUnit (default): ignore */
/*    elaborate sequenceNonUnit (enabled): true */
/*    elaborate warnUnused (default): false */
/*    elaborate warnUnused (enabled): true */
/*    elaborate only: false */
/*    emit main: true */
/*    export header: None */
/*    exn history: false */
/*    generated output format: executable */
/*    gc check: Limit */
/*    indentation: 3 */
/*    inlineIntoMain: true */
/*    inlineLeafA: {loops = true, repeat = true, size = Some 20} */
/*    inlineLeafB: {loops = true, repeat = true, size = Some 40} */
/*    inlineNonRec: {small = 60, product = 320} */
/*    input file: 15 */
/*    keep CoreML: false */
/*    keep def use: true */
/*    keep dot: false */
/*    keep Machine: false */
/*    keep passes: [] */
/*    keep RSSA: false */
/*    keep SSA: false */
/*    keep SSA2: false */
/*    keep SXML: false */
/*    keep XML: false */
/*    extra_: false */
/*    lib dir: /home/a/Projects/mlton/build/lib */
/*    lib target dir: /home/a/Projects/mlton/build/lib/targets/unknown */
/*    loop passes: 1 */
/*    mark cards: true */
/*    max function size: 10000 */
/*    mlb path vars: [{var = MLTON_ROOT, path = $(LIB_MLTON_DIR)/sml}, {var = SML_LIB, path = $(LIB_MLTON_DIR)/sml}] */
/*    native commented: 0 */
/*    native live stack: false */
/*    native optimize: 1 */
/*    native move hoist: true */
/*    native copy prop: true */
/*    native copy prop cutoff: 1000 */
/*    native cutoff: 100 */
/*    native live transfer: 8 */
/*    native shuffle: true */
/*    native ieee fp: false */
/*    native split: Some 20000 */
/*    optimizationPasses: [<ssa2::default>, <ssa::default>, <sxml::default>, <xml::default>] */
/*    polyvariance: Some {hofo = true, rounds = 2, small = 30, product = 300} */
/*    prefer abs paths: false */
/*    prof passes: [] */
/*    profile: None */
/*    profile branch: false */
/*    profile C: [] */
/*    profile IL: ProfileSource */
/*    profile include/exclude: [(Seq [Star [.], Or [Seq [Seq [[$], [(], [S], [M], [L], [_], [L], [I], [B], [)]]]], Star [.]], false)] */
/*    profile raise: false */
/*    profile stack: false */
/*    profile val: false */
/*    show basis: None */
/*    show def-use: None */
/*    show types: true */
/*    target: unknown */
/*    target arch: AMD64 */
/*    target OS: OpenBSD */
/*    type check: true */
/*    verbosity: Silent */
/*    warn unrecognized annotation: true */
/*    warn deprecated features: true */
/*    zone cut depth: 100 */
#define _ISOC99_SOURCE
#include <amd64-main.h>

PRIVATE struct GC_state gcState;
PRIVATE CPointer globalCPointer [0];
PRIVATE CPointer CReturnQ;
PRIVATE Int8 globalInt8 [0];
PRIVATE Int8 CReturnI8;
PRIVATE Int16 globalInt16 [0];
PRIVATE Int16 CReturnI16;
PRIVATE Int32 globalInt32 [0];
PRIVATE Int32 CReturnI32;
PRIVATE Int64 globalInt64 [0];
PRIVATE Int64 CReturnI64;
PRIVATE Objptr globalObjptr [13];
PRIVATE Objptr CReturnP;
PRIVATE Real32 globalReal32 [0];
PRIVATE Real32 CReturnR32;
PRIVATE Real64 globalReal64 [0];
PRIVATE Real64 CReturnR64;
PRIVATE Word8 globalWord8 [0];
PRIVATE Word8 CReturnW8;
PRIVATE Word16 globalWord16 [0];
PRIVATE Word16 CReturnW16;
PRIVATE Word32 globalWord32 [4];
PRIVATE Word32 CReturnW32;
PRIVATE Word64 globalWord64 [0];
PRIVATE Word64 CReturnW64;
PRIVATE Pointer globalObjptrNonRoot [0];
PRIVATE Pointer MLton_FFI_opArgsResPtr;
static int saveGlobals (FILE *f) {
	SaveArray (globalCPointer, f);
	SaveArray (globalInt8, f);
	SaveArray (globalInt16, f);
	SaveArray (globalInt32, f);
	SaveArray (globalInt64, f);
	SaveArray (globalObjptr, f);
	SaveArray (globalReal32, f);
	SaveArray (globalReal64, f);
	SaveArray (globalWord8, f);
	SaveArray (globalWord16, f);
	SaveArray (globalWord32, f);
	SaveArray (globalWord64, f);
	return 0;
}
static int loadGlobals (FILE *f) {
	LoadArray (globalCPointer, f);
	LoadArray (globalInt8, f);
	LoadArray (globalInt16, f);
	LoadArray (globalInt32, f);
	LoadArray (globalInt64, f);
	LoadArray (globalObjptr, f);
	LoadArray (globalReal32, f);
	LoadArray (globalReal64, f);
	LoadArray (globalWord8, f);
	LoadArray (globalWord16, f);
	LoadArray (globalWord32, f);
	LoadArray (globalWord64, f);
	return 0;
}
BeginIntInfInits
EndIntInfInits
BeginVectorInits
VectorInitElem ("Top-level suffix raised exception.\n", 1, 12, 35)
VectorInitElem ("control shouldn\'t reach here", 1, 8, 28)
VectorInitElem ("Overflow", 1, 10, 8)
VectorInitElem ("unhandled exception: ", 1, 9, 21)
VectorInitElem ("unhandled exception in Basis Library", 1, 11, 36)
VectorInitElem ("\n", 1, 7, 1)
EndVectorInits
static void real_Init() {
}
static uint16_t frameOffsets0[] = {0};
static uint16_t frameOffsets1[] = {1,0};
static uint16_t frameOffsets2[] = {2,0,8};
static struct GC_frameLayout frameLayouts[] = {
	{C_FRAME, frameOffsets0, 8},
	{ML_FRAME, frameOffsets0, 8},
	{C_FRAME, frameOffsets1, 16},
	{C_FRAME, frameOffsets2, 40},
	{C_FRAME, frameOffsets1, 32},
};
static struct GC_objectType objectTypes[] = {
	{ STACK_TAG, FALSE, 0, 0 },
	{ NORMAL_TAG, TRUE, 16, 1 },
	{ WEAK_TAG, FALSE, 16, 0 },
	{ ARRAY_TAG, FALSE, 1, 0 },
	{ ARRAY_TAG, FALSE, 4, 0 },
	{ ARRAY_TAG, FALSE, 2, 0 },
	{ ARRAY_TAG, FALSE, 8, 0 },
	{ NORMAL_TAG, FALSE, 8, 1 },
	{ ARRAY_TAG, TRUE, 1, 0 },
	{ NORMAL_TAG, TRUE, 0, 1 },
	{ NORMAL_TAG, TRUE, 8, 0 },
	{ NORMAL_TAG, FALSE, 8, 1 },
	{ NORMAL_TAG, FALSE, 8, 1 },
	{ NORMAL_TAG, FALSE, 0, 2 },
	{ NORMAL_TAG, FALSE, 0, 2 },
	{ NORMAL_TAG, FALSE, 0, 1 },
};
static uint32_t* sourceSeqs[] = {
};
static GC_sourceSeqIndex frameSources[] = {
};
static struct GC_sourceLabel sourceLabels[] = {
};
static char* sourceNames[] = {
};
static struct GC_source sources[] = {
};
static char* atMLtons[] = {
	"15",
	"@MLton",
	"--",
};
PRIVATE CPointer localCPointer[8];
PRIVATE Int8 localInt8[0];
PRIVATE Int16 localInt16[0];
PRIVATE Int32 localInt32[0];
PRIVATE Int64 localInt64[0];
PRIVATE Objptr localObjptr[7];
PRIVATE Real32 localReal32[0];
PRIVATE Real64 localReal64[0];
PRIVATE Word8 localWord8[3];
PRIVATE Word16 localWord16[2];
PRIVATE Word32 localWord32[4];
PRIVATE Word64 localWord64[3];
MLtonMain (8, 0xB23A96CB, 40, TRUE, PROFILE_NONE, FALSE, F_0)
int main (int argc, char* argv[]) {
return (MLton_main (argc, argv));
}
