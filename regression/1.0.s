/* MLton g9a43e11 (built Sun Apr  5 22:29:53 NZST 2015 on xeon) */
/*   created this file on Sun Apr 05 23:04:04 2015. */
/* Do not edit this file. */
/* Flag settings:  */
/*    align: 8 */
/*    atMLtons: (1, @MLton, --) */
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
/*    input file: 1 */
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
.text
.p2align 0x4
.globl MLton_jumpToSML
.hidden MLton_jumpToSML
MLton_jumpToSML:
	subq $0x48,%rsp
	movq %rbp,0x40(%rsp)
	movq %rbx,0x38(%rsp)
	movq %r12,0x30(%rsp)
	movq %r13,0x28(%rsp)
	movq %r14,0x20(%rsp)
	movq %r15,0x18(%rsp)
	movq c_stackP(%rip),%rbx
	movq %rbx,0x10(%rsp)
	movq %rsp,c_stackP(%rip)
	movq (gcState+0x10)(%rip),%rbp
	movq (gcState+0x0)(%rip),%r12
	jmp *%rdi
.p2align 0x4
.globl Thread_returnToC
.hidden Thread_returnToC
Thread_returnToC:
	movq c_stackP(%rip),%rsp
	movq 0x10(%rsp),%rbx
	movq %rbx,c_stackP(%rip)
	movq 0x18(%rsp),%r15
	movq 0x20(%rsp),%r14
	movq 0x28(%rsp),%r13
	movq 0x30(%rsp),%r12
	movq 0x38(%rsp),%rbx
	movq 0x40(%rsp),%rbp
	addq $0x48,%rsp
	ret
.text
.p2align 0x4
.globl F_0
.hidden F_0
F_0:
L_0:
	movq (gcState+0x18)(%rip),%r15
	cmpq %rbp,%r15
	setb %al
	movzbl %al,%eax
	testl %eax,%eax
	movl %eax,(globalWord32+0x0)(%rip)
	jnz L_6
L_1:
	movq (gcState+0x8)(%rip),%r14
	cmpq %r12,%r14
	setb %bl
	movzbl %bl,%ebx
	testl %ebx,%ebx
	movl %ebx,(globalWord32+0x4)(%rip)
	jnz L_147
L_2:
	movq $0x1F,%r15
	movq %r12,%r14
	addq $0x8,%r14
	movq %r14,%r13
	movq %r15,0x0(%r12)
	movq %r12,%r12
	addq $0x10,%r12
	movq $0x1,%r15
	movq (c_stackP+0x0)(%rip),%r14
	movq %r14,%rsp
	movq $0x11,%r14
	movq %r14,%rcx
	xorq %r14,%r14
	movq %r14,%rdx
	movq $0x48,%r14
	movq %r14,%rsi
	leaq gcState(%rip),%r14
	movq %r14,%r11
	movq %r11,%rdi
	xorq %r14,%r14
	movq %r14,%rax
	addq $0x8,%rbp
	leaq (L_3+0x0)(%rip),%r14
	movq %r14,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %r15,0x0(%r13)
	movq %r13,(globalObjptr+0x0)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	movq %rbp,(gcState+0x10)(%rip)
	call GC_arrayAllocate
	movq (gcState+0x0)(%rip),%r15
	movq %r15,%r12
	movq (gcState+0x10)(%rip),%r15
	movq %r15,%rbp
	jmp L_3
.p2align 0x4
.long 0x0
L_3:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
	movq %rax,%r15
	movq (c_stackP+0x0)(%rip),%r14
	movq %r14,%rsp
	movq $0x11,%r14
	movq %r14,%rcx
	xorq %r14,%r14
	movq %r14,%rdx
	movq $0x48,%r14
	movq %r14,%rsi
	leaq gcState(%rip),%r14
	movq %r14,%r13
	movq %r13,%rdi
	xorq %r14,%r14
	xchgq %r14,%rax
	addq $0x8,%rbp
	leaq (L_4+0x0)(%rip),%r13
	movq %r13,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %r15,(globalObjptr+0x8)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	movq %rbp,(gcState+0x10)(%rip)
	call GC_arrayAllocate
	movq (gcState+0x0)(%rip),%r15
	movq %r15,%r12
	movq (gcState+0x10)(%rip),%r15
	movq %r15,%rbp
	jmp L_4
.p2align 0x4
.long 0x0
L_4:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
	movq %rax,%r15
	movq $0x19,%r14
	movq %r12,%r13
	addq $0x8,%r13
	movq %r13,%r11
	movq %r14,0x0(%r12)
	movq %r12,%r12
	addq $0x18,%r12
	movw $0x4641,%r14w
	movzwl %r14w,%r13d
	movl %r13d,%r14d
	xorl %r10d,%r10d
	movq $0x1,%r9
	movq %r9,0x8(%r11)
	movl %r14d,0x0(%r11)
	movl %r10d,0x4(%r11)
	movq $0x19,%r8
	movq %r12,%rsp
	addq $0x8,%rsp
	movq %rsp,%rsi
	movq %r8,0x0(%r12)
	movq %r12,%r12
	addq $0x18,%r12
	movw $0x6661,%r8w
	movzwl %r8w,%esp
	movl %esp,%r8d
	xorl %edi,%edi
	movq %r11,%rdx
	movq %rdx,0x8(%rsi)
	movl %edi,0x4(%rsi)
	movl %r8d,0x0(%rsi)
	movq $0x1B,%rcx
	movq %r12,%rbx
	addq $0x8,%rbx
	movq %rbx,%r14
	movq %rcx,0x0(%r12)
	movq %r12,%r12
	addq $0x18,%r12
	movq (globalObjptr+0x30)(%rip),%rcx
	movq %rcx,%rbx
	movq $0x1,%r10
	addq $0x8,%rbp
	leaq (L_5+0x0)(%rip),%r9
	movq %r9,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %r10,0x8(%r14)
	movq %rbx,0x0(%r14)
	movq %r14,(globalObjptr+0x28)(%rip)
	movl %esp,(globalWord32+0xC)(%rip)
	movq %rsi,(globalObjptr+0x20)(%rip)
	movl %r13d,(globalWord32+0x8)(%rip)
	movq %r11,(globalObjptr+0x18)(%rip)
	movq %r15,(globalObjptr+0x10)(%rip)
	jmp main_0
.p2align 0x4
L_147:
L_6:
	movq (c_stackP+0x0)(%rip),%r15
	movq %r15,%rsp
	movl $0x0,%r15d
	movl %r15d,%r14d
	movq %r14,%rdx
	xorq %r15,%r15
	movq %r15,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%r14
	movq %r14,%rdi
	xorq %r15,%r15
	movq %r15,%rax
	addq $0x8,%rbp
	leaq (L_7+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r15
	movq %r15,%r12
	movq (gcState+0x10)(%rip),%r15
	movq %r15,%rbp
	jmp L_7
.p2align 0x4
.long 0x0
L_7:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
	jmp L_2
.p2align 0x4
.long 0x1
L_5:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
	movq (c_stackP+0x0)(%rip),%r15
	movq %r15,%rsp
	movq (globalObjptr+0x38)(%rip),%r15
	movq %r15,%r14
	movq %r14,%rdi
	xorq %r14,%r14
	movq %r14,%rax
	call MLton_bug
.text
.p2align 0x4
.globl main_0
.hidden main_0
main_0:
L_8:
	cmpq %rbp,(gcState+0x18)(%rip)
	jnb L_9
L_145:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x8,%rbp
	leaq (L_146+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_146
.p2align 0x4
.long 0x0
L_146:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
L_9:
	movq (globalObjptr+0x0)(%rip),%r15
	movq %r15,0x0(%rbp)
	movq $0x1,0x8(%rbp)
	movq $0x4000000000000000,%r15
	movq %r15,0x10(%rbp)
.p2align 0x4,,0x7
loop_0:
	cmpq %r12,(gcState+0x8)(%rip)
	jb L_201
.p2align 0x4,,0x7
L_10:
	movq 0x10(%rbp),%r15
	testq %r15,%r15
	jz L_150
L_11:
	movq 0x8(%rbp),%r15
	incq %r15
	jo L_149
L_17:
	movq %r15,0x8(%rbp)
	movq $0x1F,0x0(%r12)
	movq %r12,%r15
	addq $0x8,%r15
	addq $0x10,%r12
	movq 0x0(%rbp),%r14
	movq %r14,0x0(%r15)
	movq %r15,0x0(%rbp)
	movq $0x0,0x10(%rbp)
	jmp loop_0
.p2align 0x4
L_149:
L_12:
	movq (c_stackP+0x0)(%rip),%rsp
	movq (globalObjptr+0x40)(%rip),%rdi
	xorq %rax,%rax
	addq $0x8,%rbp
	leaq (L_13+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call Stdio_print
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_13
.p2align 0x4
.long 0x0
L_13:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
	movq (c_stackP+0x0)(%rip),%rsp
	movq (globalObjptr+0x48)(%rip),%rdi
	xorq %rax,%rax
	addq $0x8,%rbp
	leaq (L_14+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call Stdio_print
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_14
.p2align 0x4
.long 0x0
L_14:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
	movq (c_stackP+0x0)(%rip),%rsp
	movq (globalObjptr+0x30)(%rip),%rdi
	xorq %rax,%rax
	addq $0x8,%rbp
	leaq (L_15+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call Stdio_print
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_15
.p2align 0x4
.long 0x0
L_15:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
	movq (c_stackP+0x0)(%rip),%rsp
	movq (globalObjptr+0x50)(%rip),%rdi
	xorq %rax,%rax
	addq $0x8,%rbp
	leaq (L_16+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call MLton_bug
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_16
.p2align 0x4
.long 0x0
L_16:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
	jmp *0xFFFFFFFFFFFFFFF8(%rbp)
.p2align 0x4
L_150:
L_18:
	movq 0x0(%rbp),%r14
	cmpq $0x1,%r14
	je L_23
L_19:
	movq 0x0(%r14),%r15
.p2align 0x4,,0x7
loop_1:
	cmpq $0x1,%r15
	je L_151
L_20:
	movq 0x0(%r15),%r15
	jmp loop_1
.p2align 0x4
L_151:
L_21:
	cmpq %r12,(gcState+0x8)(%rip)
	jnb L_23
L_140:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x8,%rbp
	leaq (L_141+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_141
.p2align 0x4
.long 0x0
L_141:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
L_23:
	movq $0x13,0x0(%r12)
	movq %r12,%r15
	addq $0x8,%r15
	movq %r15,0x0(%rbp)
	addq $0x10,%r12
	movq $0x1,0x0(%r15)
	movq (globalObjptr+0x0)(%rip),%r15
	movq %r15,0x8(%rbp)
	movq $0x1,0x10(%rbp)
	movq $0x7FFFFFFFFFFFFFFF,%r15
	movq %r15,0x18(%rbp)
.p2align 0x4,,0x7
loop_2:
	cmpq %r12,(gcState+0x8)(%rip)
	jb L_198
.p2align 0x4,,0x7
L_24:
	movq 0x18(%rbp),%r15
	testq %r15,%r15
	jz L_153
L_25:
	movq 0x10(%rbp),%r15
	incq %r15
	jo L_12
L_26:
	movq %r15,0x10(%rbp)
	movq $0x1F,0x0(%r12)
	movq %r12,%r15
	addq $0x8,%r15
	addq $0x10,%r12
	movq 0x8(%rbp),%r14
	movq %r14,0x0(%r15)
	movq %r15,0x8(%rbp)
	movq $0x0,0x18(%rbp)
	jmp loop_2
.p2align 0x4
L_153:
L_27:
	movq 0x8(%rbp),%r14
	cmpq $0x1,%r14
	je L_31
L_28:
	movq 0x0(%r14),%r15
.p2align 0x4,,0x7
loop_3:
	cmpq $0x1,%r15
	je L_154
L_29:
	movq 0x0(%r15),%r15
	jmp loop_3
.p2align 0x4
L_154:
L_31:
	movq (globalObjptr+0x0)(%rip),%r15
	movq %r15,0x8(%rbp)
	movq $0x1,0x10(%rbp)
	movq $0x7FFFFFFFFFFFFFFF,%r15
	movq %r15,0x18(%rbp)
.p2align 0x4,,0x7
loop_4:
	cmpq %r12,(gcState+0x8)(%rip)
	jb L_196
.p2align 0x4,,0x7
L_32:
	movq 0x18(%rbp),%r15
	testq %r15,%r15
	jz L_156
L_33:
	movq 0x10(%rbp),%r15
	incq %r15
	jo L_12
L_34:
	movq %r15,0x10(%rbp)
	movq $0x1F,0x0(%r12)
	movq %r12,%r15
	addq $0x8,%r15
	addq $0x10,%r12
	movq 0x8(%rbp),%r14
	movq %r14,0x0(%r15)
	movq %r15,0x8(%rbp)
	movq $0x0,0x18(%rbp)
	jmp loop_4
.p2align 0x4
L_156:
L_35:
	movq 0x8(%rbp),%r14
	cmpq $0x1,%r14
	je L_39
L_36:
	movq 0x0(%r14),%r15
.p2align 0x4,,0x7
loop_5:
	cmpq $0x1,%r15
	je L_157
L_37:
	movq 0x0(%r15),%r15
	jmp loop_5
.p2align 0x4
L_157:
L_39:
	xorq %r15,%r15
.p2align 0x4,,0x7
loop_6:
	cmpq $0x100,%r15
	jnl L_158
L_133:
	incq %r15
	jmp loop_6
.p2align 0x4
L_158:
L_40:
	xorq %r15,%r15
.p2align 0x4,,0x7
loop_7:
	cmpq $0x100,%r15
	jnl L_159
L_132:
	incq %r15
	jmp loop_7
.p2align 0x4
L_159:
L_41:
	xorq %r15,%r15
.p2align 0x4,,0x7
loop_8:
	cmpq $0x100,%r15
	jnl L_160
L_131:
	incq %r15
	jmp loop_8
.p2align 0x4
L_160:
L_42:
	xorq %r15,%r15
.p2align 0x4,,0x7
loop_9:
	cmpq $0x100,%r15
	jnl L_164
L_121:
	movb %r15b,%dl
	movq (globalObjptr+0x20)(%rip),%r14
	movw $0x3930,%r11w
	movq %r15,%r13
	movw %r11w,%r15w
.p2align 0x4,,0x7
L_122:
	movw %r15w,%r11w
	shrw $0x8,%r11w
	movb %r11b,%r10b
	movb %r15b,%r11b
	cmpb %r11b,%dl
	jb L_163
L_123:
	cmpb %dl,%r10b
	jnb L_162
	movq %r13,(localWord64+0x0)(%rip)
L_127:
	cmpq $0x1,%r14
	je L_161
L_128:
	movw 0x0(%r14),%r15w
	movq 0x8(%r14),%r14
	movq (localWord64+0x0)(%rip),%r13
	jmp L_122
.p2align 0x4
L_161:
L_125:
	movq (localWord64+0x0)(%rip),%r15
	incq %r15
	jmp loop_9
.p2align 0x4
L_162:
	movq %r13,(localWord64+0x0)(%rip)
	jmp L_125
.p2align 0x4
L_163:
	movq %r13,(localWord64+0x0)(%rip)
	jmp L_127
.p2align 0x4
L_164:
L_43:
	xorq %r15,%r15
.p2align 0x4,,0x7
loop_10:
	cmpq $0x100,%r15
	jnl L_165
L_120:
	incq %r15
	jmp loop_10
.p2align 0x4
L_165:
L_44:
	xorq %r15,%r15
.p2align 0x4,,0x7
loop_11:
	cmpq $0x21,%r15
	jnl L_166
L_119:
	incq %r15
	jmp loop_11
.p2align 0x4
L_166:
L_45:
	xorq %r15,%r15
.p2align 0x4,,0x7
loop_12:
	cmpq $0x41,%r15
	jnl L_167
L_118:
	incq %r15
	jmp loop_12
.p2align 0x4
L_167:
L_46:
	xorq %r15,%r15
.p2align 0x4,,0x7
loop_13:
	cmpq $0x1,%r15
	jnl L_168
L_117:
	incq %r15
	jmp loop_13
.p2align 0x4
L_168:
L_47:
	cmpq %r12,(gcState+0x8)(%rip)
	jnb L_48
L_115:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x10,%rbp
	leaq (L_116+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_116
.p2align 0x4
.long 0x6
L_116:
	addq $0xFFFFFFFFFFFFFFF0,%rbp
L_48:
	movq 0x0(%rbp),%r14
	movq 0x0(%r14),%r15
	movq $0x17,0x0(%r12)
	movq %r12,%r13
	addq $0x8,%r13
	movq %r15,0x8(%r13)
	addq $0x18,%r12
	movb $0x1,%r11b
	movzbl %r11b,%r10d
	movl %r10d,0x0(%r13)
	movl $0x0,0x4(%r13)
	movq %r14,%r15
	shrq $0x8,%r15
	movq (gcState+0x3C8)(%rip),%r11
	movb $0x1,0x0(%r11,%r15,1)
	movq %r13,%r15
	movq %r13,0x0(%r14)
	movq $0x17,0x0(%r12)
	movq %r12,%r13
	addq $0x8,%r13
	movq %r15,0x8(%r13)
	addq $0x18,%r12
	movb $0x2,%r10b
	movzbl %r10b,%r9d
	movl %r9d,0x0(%r13)
	movl $0x0,0x4(%r13)
	movq %r14,%r15
	shrq $0x8,%r15
	movb $0x1,0x0(%r11,%r15,1)
	movq %r13,%r15
	movq %r13,0x0(%r14)
	movq $0x17,0x0(%r12)
	movq %r12,%r13
	addq $0x8,%r13
	movq %r15,0x8(%r13)
	addq $0x18,%r12
	movb $0x0,%r10b
	movzbl %r10b,%r9d
	movl %r9d,0x0(%r13)
	movl $0x0,0x4(%r13)
	movq %r14,%r15
	shrq $0x8,%r15
	movb $0x1,0x0(%r11,%r15,1)
	movq %r13,0x0(%r14)
	movq $0x15,0x0(%r12)
	movq %r12,%r13
	addq $0x8,%r13
	movq %r13,0x8(%rbp)
	addq $0x10,%r12
	movl $0x0,0x0(%r13)
	movl $0x0,0x4(%r13)
	movq 0x0(%r14),%r15
	cmpq $0x1,%r15
	je L_55
L_49:
	movq 0x8(%r15),%r14
	movb 0x0(%r15),%dl
	movq %r14,%r15
.p2align 0x4,,0x7
L_50:
	cmpb $0x1,%dl
	je L_190
	cmpb $0x2,%dl
	je L_187
L_51:
	cmpq $0x1,%r15
	je L_169
L_52:
	movb 0x0(%r15),%dl
	movq 0x8(%r15),%r15
	jmp L_50
.p2align 0x4
L_169:
L_53:
	cmpq %r12,(gcState+0x8)(%rip)
	jnb L_55
L_100:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x18,%rbp
	leaq (L_101+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_101
.p2align 0x4
.long 0x3
L_101:
	addq $0xFFFFFFFFFFFFFFE8,%rbp
L_55:
	movq $0x1B,0x0(%r12)
	movq %r12,%r15
	addq $0x8,%r15
	addq $0x18,%r12
	movq (globalObjptr+0x48)(%rip),%r14
	movq %r14,0x0(%r15)
	movq (globalObjptr+0x28)(%rip),%r14
	movq %r14,0x8(%r15)
	movq %r15,0x10(%rbp)
	movq (globalObjptr+0x40)(%rip),%r15
	movq %r15,0x18(%rbp)
	movq $0x1,0x20(%rbp)
.p2align 0x4,,0x7
L_56:
	cmpq %r12,(gcState+0x8)(%rip)
	jb L_185
.p2align 0x4,,0x7
L_57:
	movq 0x18(%rbp),%r15
	movq 0xFFFFFFFFFFFFFFF0(%r15),%r14
	movq $0xF,0x0(%r12)
	movq %r12,%r13
	addq $0x8,%r13
	movq %r14,0x0(%r13)
	addq $0x18,%r12
	movq %r15,0x8(%r13)
	movq $0x1D,0x0(%r12)
	movq %r12,%r15
	addq $0x8,%r15
	addq $0x18,%r12
	movq %r13,0x0(%r15)
	movq 0x20(%rbp),%r14
	movq %r14,0x8(%r15)
	movq 0x10(%rbp),%r14
	cmpq $0x1,%r14
	je L_170
L_58:
	movq %r15,0x20(%rbp)
	movq 0x0(%r14),%r15
	movq 0x8(%r14),%r14
	movq %r14,0x10(%rbp)
	movq %r15,0x18(%rbp)
	jmp L_56
.p2align 0x4
L_170:
L_59:
	movq %r13,0x18(%rbp)
	movq 0x20(%rbp),%r15
	movq %r15,0x10(%rbp)
	movq $0x1,0x20(%rbp)
.p2align 0x4,,0x7
L_60:
	cmpq %r12,(gcState+0x8)(%rip)
	jb L_184
.p2align 0x4,,0x7
L_61:
	movq $0x1D,0x0(%r12)
	movq %r12,%r15
	addq $0x8,%r15
	addq $0x18,%r12
	movq 0x18(%rbp),%r14
	movq %r14,0x0(%r15)
	movq 0x20(%rbp),%r14
	movq %r14,0x8(%r15)
	movq 0x10(%rbp),%r14
	cmpq $0x1,%r14
	je L_171
L_62:
	movq %r15,0x20(%rbp)
	movq 0x0(%r14),%r15
	movq 0x8(%r14),%r14
	movq %r14,0x10(%rbp)
	movq %r15,0x18(%rbp)
	jmp L_60
.p2align 0x4
L_171:
L_63:
	movq 0x20(%rbp),%r13
	cmpq $0x1,%r13
	je L_179
L_64:
	movq 0x18(%rbp),%r11
	xorq %r15,%r15
	xchgq %r11,%r14
.p2align 0x4,,0x7
L_65:
	addq 0x0(%r14),%r15
	movq %r15,0x10(%rbp)
	cmpq $0x1,%r13
	je L_172
L_66:
	movq 0x0(%r13),%r14
	movq 0x8(%r13),%r13
	jmp L_65
.p2align 0x4
L_172:
L_67:
	testq %r15,%r15
	jz L_178
L_68:
	cmpq $0x7FFFFFFF,%r15
	ja L_76
L_69:
	movq (c_stackP+0x0)(%rip),%rsp
	movq $0x11,%rcx
	movq %r15,%rdx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x30,%rbp
	leaq (L_70+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_arrayAllocate
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_70
.p2align 0x4
.long 0x2
L_70:
	addq $0xFFFFFFFFFFFFFFD0,%rbp
	movq %rax,%r15
L_71:
	movq 0x20(%rbp),%r10
	movq 0x18(%rbp),%r11
	xorq %r13,%r13
	xorq %r14,%r14
.p2align 0x4,,0x7
loop_14:
	cmpq 0x10(%rbp),%r14
	jnl L_175
.p2align 0x4,,0x7
loop_15:
	cmpq 0x0(%r11),%r13
	jl L_174
L_79:
	cmpq $0x1,%r10
	je L_173
L_80:
	movq 0x0(%r10),%r9
	movq 0x8(%r10),%r10
	xorq %r13,%r13
	movq %r9,%r11
	jmp loop_15
.p2align 0x4
L_173:
L_76:
	movq (c_stackP+0x0)(%rip),%rsp
	movq (globalObjptr+0x58)(%rip),%rdi
	xorq %rax,%rax
	addq $0x8,%rbp
	leaq (L_77+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call Stdio_print
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_77
.p2align 0x4
.long 0x0
L_77:
	addq $0xFFFFFFFFFFFFFFF8,%rbp
	movq %rbp,(gcState+0x10)(%rip)
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x1,%r15d
	movl %r15d,%esi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	movq %r12,(gcState+0x0)(%rip)
	call MLton_halt
.p2align 0x4
L_174:
L_82:
	movq %r13,%r9
	movq 0x8(%r11),%rsp
	movb 0x0(%rsp,%r13,1),%r8b
	movb %r8b,0x0(%r15,%r14,1)
	incq %r9
	incq %r14
	movq %r9,%r13
	jmp loop_14
.p2align 0x4
L_175:
L_72:
	movq $0x7,0xFFFFFFFFFFFFFFF8(%r15)
print_0:
	movq (c_stackP+0x0)(%rip),%rsp
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x18,%rbp
	leaq (L_73+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call Stdio_print
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_73
.p2align 0x4
.long 0x3
L_73:
	addq $0xFFFFFFFFFFFFFFE8,%rbp
	movq 0x8(%rbp),%r15
	movl 0x0(%r15),%r14d
	testl %r14d,%r14d
	jnz L_76
L_74:
	movl $0x1,0x0(%r15)
	movq %rbp,(gcState+0x10)(%rip)
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x1,%r15d
	movl %r15d,%esi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	movq %r12,(gcState+0x0)(%rip)
	call MLton_halt
.p2align 0x4
L_178:
L_84:
	movq (globalObjptr+0x8)(%rip),%r14
	xchgq %r14,%r15
	jmp L_71
.p2align 0x4
L_179:
L_85:
	movq 0x18(%rbp),%r15
	movq 0x8(%r15),%r14
	movq 0x0(%r15),%r13
	movq %r13,0x20(%rbp)
	cmpq %r13,0xFFFFFFFFFFFFFFF0(%r14)
	movq %r14,0x10(%rbp)
	je L_183
L_86:
	testq %r13,%r13
	jz L_182
L_87:
	cmpq $0x7FFFFFFF,%r13
	ja L_76
L_88:
	movq (c_stackP+0x0)(%rip),%rsp
	movq $0x11,%rcx
	movq %r13,%rdx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x30,%rbp
	leaq (L_89+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_arrayAllocate
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_89
.p2align 0x4
.long 0x4
L_89:
	addq $0xFFFFFFFFFFFFFFD0,%rbp
	movq %rax,%r15
L_90:
	xorq %r14,%r14
.p2align 0x4,,0x7
loop_16:
	cmpq 0x20(%rbp),%r14
	jnl L_180
L_92:
	movq 0x10(%rbp),%r11
	movb 0x0(%r11,%r14,1),%r13b
	movb %r13b,0x0(%r15,%r14,1)
	incq %r14
	jmp loop_16
.p2align 0x4
L_180:
L_91:
	movq $0x7,0xFFFFFFFFFFFFFFF8(%r15)
	jmp print_0
.p2align 0x4
L_182:
L_94:
	movq (globalObjptr+0x10)(%rip),%r15
	jmp L_90
.p2align 0x4
L_183:
L_95:
	movq 0x10(%rbp),%r15
	jmp print_0
.p2align 0x4
L_184:
L_96:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x30,%rbp
	leaq (L_97+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_97
.p2align 0x4
.long 0x5
L_97:
	addq $0xFFFFFFFFFFFFFFD0,%rbp
	jmp L_61
.p2align 0x4
L_185:
L_98:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x30,%rbp
	leaq (L_99+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_99
.p2align 0x4
.long 0x5
L_99:
	addq $0xFFFFFFFFFFFFFFD0,%rbp
	jmp L_57
.p2align 0x4
L_187:
L_108:
	cmpq $0x1,%r15
	je L_188
L_109:
	movb 0x0(%r15),%dl
	movq 0x8(%r15),%r15
	jmp L_50
.p2align 0x4
L_188:
L_110:
	cmpq %r12,(gcState+0x8)(%rip)
	jnb L_55
L_112:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x18,%rbp
	leaq (L_113+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_113
.p2align 0x4
.long 0x3
L_113:
	addq $0xFFFFFFFFFFFFFFE8,%rbp
	jmp L_55
.p2align 0x4
L_190:
L_102:
	cmpq $0x1,%r15
	je L_191
L_103:
	movb 0x0(%r15),%dl
	movq 0x8(%r15),%r15
	jmp L_50
.p2align 0x4
L_191:
L_104:
	cmpq %r12,(gcState+0x8)(%rip)
	jnb L_55
L_106:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x18,%rbp
	leaq (L_107+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_107
.p2align 0x4
.long 0x3
L_107:
	addq $0xFFFFFFFFFFFFFFE8,%rbp
	jmp L_55
.p2align 0x4
L_196:
L_135:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x28,%rbp
	leaq (L_136+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_136
.p2align 0x4
.long 0x7
L_136:
	addq $0xFFFFFFFFFFFFFFD8,%rbp
	jmp L_32
.p2align 0x4
L_198:
L_138:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x28,%rbp
	leaq (L_139+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_139
.p2align 0x4
.long 0x7
L_139:
	addq $0xFFFFFFFFFFFFFFD8,%rbp
	jmp L_24
.p2align 0x4
L_201:
L_143:
	movq (c_stackP+0x0)(%rip),%rsp
	movl $0x0,%r15d
	movl %r15d,%edx
	xorq %rsi,%rsi
	leaq gcState(%rip),%r15
	movq %r15,%rdi
	xorq %rax,%rax
	addq $0x20,%rbp
	leaq (L_144+0x0)(%rip),%r15
	movq %r15,0xFFFFFFFFFFFFFFF8(%rbp)
	movq %rbp,(gcState+0x10)(%rip)
	movq %r12,(gcState+0x0)(%rip)
	call GC_collect
	movq (gcState+0x0)(%rip),%r12
	movq (gcState+0x10)(%rip),%rbp
	jmp L_144
.p2align 0x4
.long 0x8
L_144:
	addq $0xFFFFFFFFFFFFFFE0,%rbp
	jmp L_10
