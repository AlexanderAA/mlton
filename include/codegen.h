#ifndef _CODEGEN_H_
#define _CODEGEN_H_

/* The label must be declared as weak because gcc's optimizer may prove that
 * the code that declares the label is dead and hence eliminate declaration.
 */
#define DeclareProfileLabel(l)			\
	void l() __attribute__ ((weak))

#define BeginIntInfs static struct GC_intInfInit intInfInits[] = {
#define IntInf(g, n) { g, n },
#define EndIntInfs };

#define BeginStrings static struct GC_stringInit stringInits[] = {
#define String(g, s, l) { g, s, l },
#define EndStrings };

#define BeginReals static void real_Init() {
#define Real(c, f) globaldouble[c] = f;
#define EndReals }

#define Globals(c, d, i, p, u, nr)					\
	/* gcState can't be static because stuff in mlton-lib.c refers to it */	\
	struct GC_state gcState;						\
	char globaluchar[c];						\
	double globaldouble[d];						\
	int globalint[i];						\
	pointer globalpointer[p];					\
        uint globaluint[u];						\
	pointer globalpointerNonRoot[nr];				\
	void saveGlobals (int fd) {					\
		swrite (fd, globaluchar, sizeof(char) * c);		\
		swrite (fd, globaldouble, sizeof(double) * d);		\
		swrite (fd, globalint, sizeof(int) * i);		\
		swrite (fd, globalpointer, sizeof(pointer) * p); 	\
		swrite (fd, globaluint, sizeof(uint) * u);		\
	}								\
	static void loadGlobals (FILE *file) {				\
		sfread (globaluchar, sizeof(char), c, file);		\
		sfread (globaldouble, sizeof(double), d, file);		\
		sfread (globalint, sizeof(int), i, file);		\
		sfread (globalpointer, sizeof(pointer), p, file);	\
		sfread (globaluint, sizeof(uint), u, file);		\
	}

#define Initialize(cs, mg, mfs, mlw, mmc, ps)				\
	gcState.cardSizeLog2 = cs;					\
	gcState.frameLayouts = frameLayouts;				\
	gcState.frameLayoutsSize = cardof(frameLayouts); 		\
	gcState.frameSources = frameSources;				\
	gcState.frameSourcesSize = cardof(frameSources);		\
	gcState.globals = globalpointer;				\
	gcState.globalsSize = cardof(globalpointer);			\
	gcState.intInfInits = intInfInits;				\
	gcState.intInfInitsSize = cardof(intInfInits);			\
	gcState.loadGlobals = loadGlobals;				\
	gcState.magic = mg;						\
	gcState.maxFrameSize = mfs;					\
	gcState.mayLoadWorld = mlw;					\
	gcState.mutatorMarksCards = mmc;				\
	gcState.objectTypes = objectTypes;				\
	gcState.objectTypesSize = cardof(objectTypes);			\
	gcState.profileStack = ps;					\
	gcState.sourceLabels = sourceLabels;				\
	gcState.sourceLabelsSize = cardof(sourceLabels);		\
	gcState.saveGlobals = saveGlobals;				\
	gcState.sources = sources;					\
	gcState.sourcesSize = cardof(sources);				\
	gcState.sourceSeqs = sourceSeqs;				\
	gcState.sourceSeqsSize = cardof(sourceSeqs);			\
	gcState.sourceSuccessors = sourceSuccessors;			\
	gcState.stringInits = stringInits;				\
	gcState.stringInitsSize = cardof(stringInits);			\
	MLton_init (argc, argv, &gcState);				\

#endif /* #ifndef _CODEGEN_H_ */
