
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c020b2b7          	lui	t0,0xc020b
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	01e31313          	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000c:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200010:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200014:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200018:	03f31313          	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc020001c:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200020:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200024:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200028:	c020b137          	lui	sp,0xc020b

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc020002c:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc0200030:	03628293          	addi	t0,t0,54 # ffffffffc0200036 <kern_init>
    jr t0
ffffffffc0200034:	8282                	jr	t0

ffffffffc0200036 <kern_init>:
void grade_backtrace(void);

int
kern_init(void) {
    extern char edata[], end[];
    memset(edata, 0, end - edata);
ffffffffc0200036:	000a1517          	auipc	a0,0xa1
ffffffffc020003a:	05250513          	addi	a0,a0,82 # ffffffffc02a1088 <edata>
ffffffffc020003e:	000ac617          	auipc	a2,0xac
ffffffffc0200042:	5d260613          	addi	a2,a2,1490 # ffffffffc02ac610 <end>
kern_init(void) {
ffffffffc0200046:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
ffffffffc0200048:	8e09                	sub	a2,a2,a0
ffffffffc020004a:	4581                	li	a1,0
kern_init(void) {
ffffffffc020004c:	e406                	sd	ra,8(sp)
    memset(edata, 0, end - edata);
ffffffffc020004e:	5a0060ef          	jal	ra,ffffffffc02065ee <memset>
    cons_init();                // init the console
ffffffffc0200052:	536000ef          	jal	ra,ffffffffc0200588 <cons_init>

    const char *message = "(THU.CST) os is loading ...";
    cprintf("%s\n\n", message);
ffffffffc0200056:	00006597          	auipc	a1,0x6
ffffffffc020005a:	5c258593          	addi	a1,a1,1474 # ffffffffc0206618 <etext>
ffffffffc020005e:	00006517          	auipc	a0,0x6
ffffffffc0200062:	5da50513          	addi	a0,a0,1498 # ffffffffc0206638 <etext+0x20>
ffffffffc0200066:	128000ef          	jal	ra,ffffffffc020018e <cprintf>

    print_kerninfo();
ffffffffc020006a:	1ac000ef          	jal	ra,ffffffffc0200216 <print_kerninfo>

    // grade_backtrace();

    pmm_init();                 // init physical memory management
ffffffffc020006e:	5c6020ef          	jal	ra,ffffffffc0202634 <pmm_init>

    pic_init();                 // init interrupt controller
ffffffffc0200072:	5ee000ef          	jal	ra,ffffffffc0200660 <pic_init>
    idt_init();                 // init interrupt descriptor table
ffffffffc0200076:	5ec000ef          	jal	ra,ffffffffc0200662 <idt_init>

    vmm_init();                 // init virtual memory management
ffffffffc020007a:	3dc040ef          	jal	ra,ffffffffc0204456 <vmm_init>
    proc_init();                // init process table
ffffffffc020007e:	501050ef          	jal	ra,ffffffffc0205d7e <proc_init>
    
    ide_init();                 // init ide devices
ffffffffc0200082:	57a000ef          	jal	ra,ffffffffc02005fc <ide_init>
    swap_init();                // init swap
ffffffffc0200086:	2fa030ef          	jal	ra,ffffffffc0203380 <swap_init>

    clock_init();               // init clock interrupt
ffffffffc020008a:	4a8000ef          	jal	ra,ffffffffc0200532 <clock_init>
    intr_enable();              // enable irq interrupt
ffffffffc020008e:	5c6000ef          	jal	ra,ffffffffc0200654 <intr_enable>
    
    cpu_idle();                 // run idle process
ffffffffc0200092:	639050ef          	jal	ra,ffffffffc0205eca <cpu_idle>

ffffffffc0200096 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc0200096:	715d                	addi	sp,sp,-80
ffffffffc0200098:	e486                	sd	ra,72(sp)
ffffffffc020009a:	e0a2                	sd	s0,64(sp)
ffffffffc020009c:	fc26                	sd	s1,56(sp)
ffffffffc020009e:	f84a                	sd	s2,48(sp)
ffffffffc02000a0:	f44e                	sd	s3,40(sp)
ffffffffc02000a2:	f052                	sd	s4,32(sp)
ffffffffc02000a4:	ec56                	sd	s5,24(sp)
ffffffffc02000a6:	e85a                	sd	s6,16(sp)
ffffffffc02000a8:	e45e                	sd	s7,8(sp)
    if (prompt != NULL) {
ffffffffc02000aa:	c901                	beqz	a0,ffffffffc02000ba <readline+0x24>
        cprintf("%s", prompt);
ffffffffc02000ac:	85aa                	mv	a1,a0
ffffffffc02000ae:	00006517          	auipc	a0,0x6
ffffffffc02000b2:	59250513          	addi	a0,a0,1426 # ffffffffc0206640 <etext+0x28>
ffffffffc02000b6:	0d8000ef          	jal	ra,ffffffffc020018e <cprintf>
readline(const char *prompt) {
ffffffffc02000ba:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000bc:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02000be:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02000c0:	4aa9                	li	s5,10
ffffffffc02000c2:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02000c4:	000a1b97          	auipc	s7,0xa1
ffffffffc02000c8:	fc4b8b93          	addi	s7,s7,-60 # ffffffffc02a1088 <edata>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000cc:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02000d0:	136000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000d4:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000d6:	00054b63          	bltz	a0,ffffffffc02000ec <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02000da:	00a95b63          	ble	a0,s2,ffffffffc02000f0 <readline+0x5a>
ffffffffc02000de:	029a5463          	ble	s1,s4,ffffffffc0200106 <readline+0x70>
        c = getchar();
ffffffffc02000e2:	124000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000e6:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000e8:	fe0559e3          	bgez	a0,ffffffffc02000da <readline+0x44>
            return NULL;
ffffffffc02000ec:	4501                	li	a0,0
ffffffffc02000ee:	a099                	j	ffffffffc0200134 <readline+0x9e>
        else if (c == '\b' && i > 0) {
ffffffffc02000f0:	03341463          	bne	s0,s3,ffffffffc0200118 <readline+0x82>
ffffffffc02000f4:	e8b9                	bnez	s1,ffffffffc020014a <readline+0xb4>
        c = getchar();
ffffffffc02000f6:	110000ef          	jal	ra,ffffffffc0200206 <getchar>
ffffffffc02000fa:	842a                	mv	s0,a0
        if (c < 0) {
ffffffffc02000fc:	fe0548e3          	bltz	a0,ffffffffc02000ec <readline+0x56>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0200100:	fea958e3          	ble	a0,s2,ffffffffc02000f0 <readline+0x5a>
ffffffffc0200104:	4481                	li	s1,0
            cputchar(c);
ffffffffc0200106:	8522                	mv	a0,s0
ffffffffc0200108:	0ba000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            buf[i ++] = c;
ffffffffc020010c:	009b87b3          	add	a5,s7,s1
ffffffffc0200110:	00878023          	sb	s0,0(a5)
ffffffffc0200114:	2485                	addiw	s1,s1,1
ffffffffc0200116:	bf6d                	j	ffffffffc02000d0 <readline+0x3a>
        else if (c == '\n' || c == '\r') {
ffffffffc0200118:	01540463          	beq	s0,s5,ffffffffc0200120 <readline+0x8a>
ffffffffc020011c:	fb641ae3          	bne	s0,s6,ffffffffc02000d0 <readline+0x3a>
            cputchar(c);
ffffffffc0200120:	8522                	mv	a0,s0
ffffffffc0200122:	0a0000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            buf[i] = '\0';
ffffffffc0200126:	000a1517          	auipc	a0,0xa1
ffffffffc020012a:	f6250513          	addi	a0,a0,-158 # ffffffffc02a1088 <edata>
ffffffffc020012e:	94aa                	add	s1,s1,a0
ffffffffc0200130:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0200134:	60a6                	ld	ra,72(sp)
ffffffffc0200136:	6406                	ld	s0,64(sp)
ffffffffc0200138:	74e2                	ld	s1,56(sp)
ffffffffc020013a:	7942                	ld	s2,48(sp)
ffffffffc020013c:	79a2                	ld	s3,40(sp)
ffffffffc020013e:	7a02                	ld	s4,32(sp)
ffffffffc0200140:	6ae2                	ld	s5,24(sp)
ffffffffc0200142:	6b42                	ld	s6,16(sp)
ffffffffc0200144:	6ba2                	ld	s7,8(sp)
ffffffffc0200146:	6161                	addi	sp,sp,80
ffffffffc0200148:	8082                	ret
            cputchar(c);
ffffffffc020014a:	4521                	li	a0,8
ffffffffc020014c:	076000ef          	jal	ra,ffffffffc02001c2 <cputchar>
            i --;
ffffffffc0200150:	34fd                	addiw	s1,s1,-1
ffffffffc0200152:	bfbd                	j	ffffffffc02000d0 <readline+0x3a>

ffffffffc0200154 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc0200154:	1141                	addi	sp,sp,-16
ffffffffc0200156:	e022                	sd	s0,0(sp)
ffffffffc0200158:	e406                	sd	ra,8(sp)
ffffffffc020015a:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc020015c:	42e000ef          	jal	ra,ffffffffc020058a <cons_putc>
    (*cnt) ++;
ffffffffc0200160:	401c                	lw	a5,0(s0)
}
ffffffffc0200162:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200164:	2785                	addiw	a5,a5,1
ffffffffc0200166:	c01c                	sw	a5,0(s0)
}
ffffffffc0200168:	6402                	ld	s0,0(sp)
ffffffffc020016a:	0141                	addi	sp,sp,16
ffffffffc020016c:	8082                	ret

ffffffffc020016e <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc020016e:	1101                	addi	sp,sp,-32
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200170:	86ae                	mv	a3,a1
ffffffffc0200172:	862a                	mv	a2,a0
ffffffffc0200174:	006c                	addi	a1,sp,12
ffffffffc0200176:	00000517          	auipc	a0,0x0
ffffffffc020017a:	fde50513          	addi	a0,a0,-34 # ffffffffc0200154 <cputch>
vcprintf(const char *fmt, va_list ap) {
ffffffffc020017e:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200180:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200182:	042060ef          	jal	ra,ffffffffc02061c4 <vprintfmt>
    return cnt;
}
ffffffffc0200186:	60e2                	ld	ra,24(sp)
ffffffffc0200188:	4532                	lw	a0,12(sp)
ffffffffc020018a:	6105                	addi	sp,sp,32
ffffffffc020018c:	8082                	ret

ffffffffc020018e <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc020018e:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200190:	02810313          	addi	t1,sp,40 # ffffffffc020b028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200194:	f42e                	sd	a1,40(sp)
ffffffffc0200196:	f832                	sd	a2,48(sp)
ffffffffc0200198:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020019a:	862a                	mv	a2,a0
ffffffffc020019c:	004c                	addi	a1,sp,4
ffffffffc020019e:	00000517          	auipc	a0,0x0
ffffffffc02001a2:	fb650513          	addi	a0,a0,-74 # ffffffffc0200154 <cputch>
ffffffffc02001a6:	869a                	mv	a3,t1
cprintf(const char *fmt, ...) {
ffffffffc02001a8:	ec06                	sd	ra,24(sp)
ffffffffc02001aa:	e0ba                	sd	a4,64(sp)
ffffffffc02001ac:	e4be                	sd	a5,72(sp)
ffffffffc02001ae:	e8c2                	sd	a6,80(sp)
ffffffffc02001b0:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02001b2:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc02001b4:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02001b6:	00e060ef          	jal	ra,ffffffffc02061c4 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc02001ba:	60e2                	ld	ra,24(sp)
ffffffffc02001bc:	4512                	lw	a0,4(sp)
ffffffffc02001be:	6125                	addi	sp,sp,96
ffffffffc02001c0:	8082                	ret

ffffffffc02001c2 <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc02001c2:	3c80006f          	j	ffffffffc020058a <cons_putc>

ffffffffc02001c6 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc02001c6:	1101                	addi	sp,sp,-32
ffffffffc02001c8:	e822                	sd	s0,16(sp)
ffffffffc02001ca:	ec06                	sd	ra,24(sp)
ffffffffc02001cc:	e426                	sd	s1,8(sp)
ffffffffc02001ce:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc02001d0:	00054503          	lbu	a0,0(a0)
ffffffffc02001d4:	c51d                	beqz	a0,ffffffffc0200202 <cputs+0x3c>
ffffffffc02001d6:	0405                	addi	s0,s0,1
ffffffffc02001d8:	4485                	li	s1,1
ffffffffc02001da:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc02001dc:	3ae000ef          	jal	ra,ffffffffc020058a <cons_putc>
    (*cnt) ++;
ffffffffc02001e0:	008487bb          	addw	a5,s1,s0
    while ((c = *str ++) != '\0') {
ffffffffc02001e4:	0405                	addi	s0,s0,1
ffffffffc02001e6:	fff44503          	lbu	a0,-1(s0)
ffffffffc02001ea:	f96d                	bnez	a0,ffffffffc02001dc <cputs+0x16>
ffffffffc02001ec:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc02001f0:	4529                	li	a0,10
ffffffffc02001f2:	398000ef          	jal	ra,ffffffffc020058a <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc02001f6:	8522                	mv	a0,s0
ffffffffc02001f8:	60e2                	ld	ra,24(sp)
ffffffffc02001fa:	6442                	ld	s0,16(sp)
ffffffffc02001fc:	64a2                	ld	s1,8(sp)
ffffffffc02001fe:	6105                	addi	sp,sp,32
ffffffffc0200200:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc0200202:	4405                	li	s0,1
ffffffffc0200204:	b7f5                	j	ffffffffc02001f0 <cputs+0x2a>

ffffffffc0200206 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200206:	1141                	addi	sp,sp,-16
ffffffffc0200208:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc020020a:	3b6000ef          	jal	ra,ffffffffc02005c0 <cons_getc>
ffffffffc020020e:	dd75                	beqz	a0,ffffffffc020020a <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc0200210:	60a2                	ld	ra,8(sp)
ffffffffc0200212:	0141                	addi	sp,sp,16
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200216:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200218:	00006517          	auipc	a0,0x6
ffffffffc020021c:	46050513          	addi	a0,a0,1120 # ffffffffc0206678 <etext+0x60>
void print_kerninfo(void) {
ffffffffc0200220:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc0200222:	f6dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  entry  0x%08x (virtual)\n", kern_init);
ffffffffc0200226:	00000597          	auipc	a1,0x0
ffffffffc020022a:	e1058593          	addi	a1,a1,-496 # ffffffffc0200036 <kern_init>
ffffffffc020022e:	00006517          	auipc	a0,0x6
ffffffffc0200232:	46a50513          	addi	a0,a0,1130 # ffffffffc0206698 <etext+0x80>
ffffffffc0200236:	f59ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  etext  0x%08x (virtual)\n", etext);
ffffffffc020023a:	00006597          	auipc	a1,0x6
ffffffffc020023e:	3de58593          	addi	a1,a1,990 # ffffffffc0206618 <etext>
ffffffffc0200242:	00006517          	auipc	a0,0x6
ffffffffc0200246:	47650513          	addi	a0,a0,1142 # ffffffffc02066b8 <etext+0xa0>
ffffffffc020024a:	f45ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  edata  0x%08x (virtual)\n", edata);
ffffffffc020024e:	000a1597          	auipc	a1,0xa1
ffffffffc0200252:	e3a58593          	addi	a1,a1,-454 # ffffffffc02a1088 <edata>
ffffffffc0200256:	00006517          	auipc	a0,0x6
ffffffffc020025a:	48250513          	addi	a0,a0,1154 # ffffffffc02066d8 <etext+0xc0>
ffffffffc020025e:	f31ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  end    0x%08x (virtual)\n", end);
ffffffffc0200262:	000ac597          	auipc	a1,0xac
ffffffffc0200266:	3ae58593          	addi	a1,a1,942 # ffffffffc02ac610 <end>
ffffffffc020026a:	00006517          	auipc	a0,0x6
ffffffffc020026e:	48e50513          	addi	a0,a0,1166 # ffffffffc02066f8 <etext+0xe0>
ffffffffc0200272:	f1dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc0200276:	000ac597          	auipc	a1,0xac
ffffffffc020027a:	79958593          	addi	a1,a1,1945 # ffffffffc02aca0f <end+0x3ff>
ffffffffc020027e:	00000797          	auipc	a5,0x0
ffffffffc0200282:	db878793          	addi	a5,a5,-584 # ffffffffc0200036 <kern_init>
ffffffffc0200286:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc020028a:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc020028e:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc0200290:	3ff5f593          	andi	a1,a1,1023
ffffffffc0200294:	95be                	add	a1,a1,a5
ffffffffc0200296:	85a9                	srai	a1,a1,0xa
ffffffffc0200298:	00006517          	auipc	a0,0x6
ffffffffc020029c:	48050513          	addi	a0,a0,1152 # ffffffffc0206718 <etext+0x100>
}
ffffffffc02002a0:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02002a2:	eedff06f          	j	ffffffffc020018e <cprintf>

ffffffffc02002a6 <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02002a6:	1141                	addi	sp,sp,-16
    panic("Not Implemented!");
ffffffffc02002a8:	00006617          	auipc	a2,0x6
ffffffffc02002ac:	3a060613          	addi	a2,a2,928 # ffffffffc0206648 <etext+0x30>
ffffffffc02002b0:	04d00593          	li	a1,77
ffffffffc02002b4:	00006517          	auipc	a0,0x6
ffffffffc02002b8:	3ac50513          	addi	a0,a0,940 # ffffffffc0206660 <etext+0x48>
void print_stackframe(void) {
ffffffffc02002bc:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc02002be:	1c6000ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02002c2 <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002c2:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002c4:	00006617          	auipc	a2,0x6
ffffffffc02002c8:	56460613          	addi	a2,a2,1380 # ffffffffc0206828 <commands+0xe0>
ffffffffc02002cc:	00006597          	auipc	a1,0x6
ffffffffc02002d0:	57c58593          	addi	a1,a1,1404 # ffffffffc0206848 <commands+0x100>
ffffffffc02002d4:	00006517          	auipc	a0,0x6
ffffffffc02002d8:	57c50513          	addi	a0,a0,1404 # ffffffffc0206850 <commands+0x108>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc02002dc:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc02002de:	eb1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02002e2:	00006617          	auipc	a2,0x6
ffffffffc02002e6:	57e60613          	addi	a2,a2,1406 # ffffffffc0206860 <commands+0x118>
ffffffffc02002ea:	00006597          	auipc	a1,0x6
ffffffffc02002ee:	59e58593          	addi	a1,a1,1438 # ffffffffc0206888 <commands+0x140>
ffffffffc02002f2:	00006517          	auipc	a0,0x6
ffffffffc02002f6:	55e50513          	addi	a0,a0,1374 # ffffffffc0206850 <commands+0x108>
ffffffffc02002fa:	e95ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc02002fe:	00006617          	auipc	a2,0x6
ffffffffc0200302:	59a60613          	addi	a2,a2,1434 # ffffffffc0206898 <commands+0x150>
ffffffffc0200306:	00006597          	auipc	a1,0x6
ffffffffc020030a:	5b258593          	addi	a1,a1,1458 # ffffffffc02068b8 <commands+0x170>
ffffffffc020030e:	00006517          	auipc	a0,0x6
ffffffffc0200312:	54250513          	addi	a0,a0,1346 # ffffffffc0206850 <commands+0x108>
ffffffffc0200316:	e79ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    }
    return 0;
}
ffffffffc020031a:	60a2                	ld	ra,8(sp)
ffffffffc020031c:	4501                	li	a0,0
ffffffffc020031e:	0141                	addi	sp,sp,16
ffffffffc0200320:	8082                	ret

ffffffffc0200322 <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200322:	1141                	addi	sp,sp,-16
ffffffffc0200324:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc0200326:	ef1ff0ef          	jal	ra,ffffffffc0200216 <print_kerninfo>
    return 0;
}
ffffffffc020032a:	60a2                	ld	ra,8(sp)
ffffffffc020032c:	4501                	li	a0,0
ffffffffc020032e:	0141                	addi	sp,sp,16
ffffffffc0200330:	8082                	ret

ffffffffc0200332 <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200332:	1141                	addi	sp,sp,-16
ffffffffc0200334:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc0200336:	f71ff0ef          	jal	ra,ffffffffc02002a6 <print_stackframe>
    return 0;
}
ffffffffc020033a:	60a2                	ld	ra,8(sp)
ffffffffc020033c:	4501                	li	a0,0
ffffffffc020033e:	0141                	addi	sp,sp,16
ffffffffc0200340:	8082                	ret

ffffffffc0200342 <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc0200342:	7115                	addi	sp,sp,-224
ffffffffc0200344:	e962                	sd	s8,144(sp)
ffffffffc0200346:	8c2a                	mv	s8,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200348:	00006517          	auipc	a0,0x6
ffffffffc020034c:	44850513          	addi	a0,a0,1096 # ffffffffc0206790 <commands+0x48>
kmonitor(struct trapframe *tf) {
ffffffffc0200350:	ed86                	sd	ra,216(sp)
ffffffffc0200352:	e9a2                	sd	s0,208(sp)
ffffffffc0200354:	e5a6                	sd	s1,200(sp)
ffffffffc0200356:	e1ca                	sd	s2,192(sp)
ffffffffc0200358:	fd4e                	sd	s3,184(sp)
ffffffffc020035a:	f952                	sd	s4,176(sp)
ffffffffc020035c:	f556                	sd	s5,168(sp)
ffffffffc020035e:	f15a                	sd	s6,160(sp)
ffffffffc0200360:	ed5e                	sd	s7,152(sp)
ffffffffc0200362:	e566                	sd	s9,136(sp)
ffffffffc0200364:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200366:	e29ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc020036a:	00006517          	auipc	a0,0x6
ffffffffc020036e:	44e50513          	addi	a0,a0,1102 # ffffffffc02067b8 <commands+0x70>
ffffffffc0200372:	e1dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    if (tf != NULL) {
ffffffffc0200376:	000c0563          	beqz	s8,ffffffffc0200380 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc020037a:	8562                	mv	a0,s8
ffffffffc020037c:	4ce000ef          	jal	ra,ffffffffc020084a <print_trapframe>
ffffffffc0200380:	00006c97          	auipc	s9,0x6
ffffffffc0200384:	3c8c8c93          	addi	s9,s9,968 # ffffffffc0206748 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc0200388:	00006997          	auipc	s3,0x6
ffffffffc020038c:	45898993          	addi	s3,s3,1112 # ffffffffc02067e0 <commands+0x98>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200390:	00006917          	auipc	s2,0x6
ffffffffc0200394:	45890913          	addi	s2,s2,1112 # ffffffffc02067e8 <commands+0xa0>
        if (argc == MAXARGS - 1) {
ffffffffc0200398:	4a3d                	li	s4,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020039a:	00006b17          	auipc	s6,0x6
ffffffffc020039e:	456b0b13          	addi	s6,s6,1110 # ffffffffc02067f0 <commands+0xa8>
    if (argc == 0) {
ffffffffc02003a2:	00006a97          	auipc	s5,0x6
ffffffffc02003a6:	4a6a8a93          	addi	s5,s5,1190 # ffffffffc0206848 <commands+0x100>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003aa:	4b8d                	li	s7,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02003ac:	854e                	mv	a0,s3
ffffffffc02003ae:	ce9ff0ef          	jal	ra,ffffffffc0200096 <readline>
ffffffffc02003b2:	842a                	mv	s0,a0
ffffffffc02003b4:	dd65                	beqz	a0,ffffffffc02003ac <kmonitor+0x6a>
ffffffffc02003b6:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc02003ba:	4481                	li	s1,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003bc:	c999                	beqz	a1,ffffffffc02003d2 <kmonitor+0x90>
ffffffffc02003be:	854a                	mv	a0,s2
ffffffffc02003c0:	210060ef          	jal	ra,ffffffffc02065d0 <strchr>
ffffffffc02003c4:	c925                	beqz	a0,ffffffffc0200434 <kmonitor+0xf2>
            *buf ++ = '\0';
ffffffffc02003c6:	00144583          	lbu	a1,1(s0)
ffffffffc02003ca:	00040023          	sb	zero,0(s0)
ffffffffc02003ce:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003d0:	f5fd                	bnez	a1,ffffffffc02003be <kmonitor+0x7c>
    if (argc == 0) {
ffffffffc02003d2:	dce9                	beqz	s1,ffffffffc02003ac <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003d4:	6582                	ld	a1,0(sp)
ffffffffc02003d6:	00006d17          	auipc	s10,0x6
ffffffffc02003da:	372d0d13          	addi	s10,s10,882 # ffffffffc0206748 <commands>
    if (argc == 0) {
ffffffffc02003de:	8556                	mv	a0,s5
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003e0:	4401                	li	s0,0
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003e2:	0d61                	addi	s10,s10,24
ffffffffc02003e4:	1c2060ef          	jal	ra,ffffffffc02065a6 <strcmp>
ffffffffc02003e8:	c919                	beqz	a0,ffffffffc02003fe <kmonitor+0xbc>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02003ea:	2405                	addiw	s0,s0,1
ffffffffc02003ec:	09740463          	beq	s0,s7,ffffffffc0200474 <kmonitor+0x132>
ffffffffc02003f0:	000d3503          	ld	a0,0(s10)
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc02003f4:	6582                	ld	a1,0(sp)
ffffffffc02003f6:	0d61                	addi	s10,s10,24
ffffffffc02003f8:	1ae060ef          	jal	ra,ffffffffc02065a6 <strcmp>
ffffffffc02003fc:	f57d                	bnez	a0,ffffffffc02003ea <kmonitor+0xa8>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc02003fe:	00141793          	slli	a5,s0,0x1
ffffffffc0200402:	97a2                	add	a5,a5,s0
ffffffffc0200404:	078e                	slli	a5,a5,0x3
ffffffffc0200406:	97e6                	add	a5,a5,s9
ffffffffc0200408:	6b9c                	ld	a5,16(a5)
ffffffffc020040a:	8662                	mv	a2,s8
ffffffffc020040c:	002c                	addi	a1,sp,8
ffffffffc020040e:	fff4851b          	addiw	a0,s1,-1
ffffffffc0200412:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc0200414:	f8055ce3          	bgez	a0,ffffffffc02003ac <kmonitor+0x6a>
}
ffffffffc0200418:	60ee                	ld	ra,216(sp)
ffffffffc020041a:	644e                	ld	s0,208(sp)
ffffffffc020041c:	64ae                	ld	s1,200(sp)
ffffffffc020041e:	690e                	ld	s2,192(sp)
ffffffffc0200420:	79ea                	ld	s3,184(sp)
ffffffffc0200422:	7a4a                	ld	s4,176(sp)
ffffffffc0200424:	7aaa                	ld	s5,168(sp)
ffffffffc0200426:	7b0a                	ld	s6,160(sp)
ffffffffc0200428:	6bea                	ld	s7,152(sp)
ffffffffc020042a:	6c4a                	ld	s8,144(sp)
ffffffffc020042c:	6caa                	ld	s9,136(sp)
ffffffffc020042e:	6d0a                	ld	s10,128(sp)
ffffffffc0200430:	612d                	addi	sp,sp,224
ffffffffc0200432:	8082                	ret
        if (*buf == '\0') {
ffffffffc0200434:	00044783          	lbu	a5,0(s0)
ffffffffc0200438:	dfc9                	beqz	a5,ffffffffc02003d2 <kmonitor+0x90>
        if (argc == MAXARGS - 1) {
ffffffffc020043a:	03448863          	beq	s1,s4,ffffffffc020046a <kmonitor+0x128>
        argv[argc ++] = buf;
ffffffffc020043e:	00349793          	slli	a5,s1,0x3
ffffffffc0200442:	0118                	addi	a4,sp,128
ffffffffc0200444:	97ba                	add	a5,a5,a4
ffffffffc0200446:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020044a:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020044e:	2485                	addiw	s1,s1,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200450:	e591                	bnez	a1,ffffffffc020045c <kmonitor+0x11a>
ffffffffc0200452:	b749                	j	ffffffffc02003d4 <kmonitor+0x92>
            buf ++;
ffffffffc0200454:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200456:	00044583          	lbu	a1,0(s0)
ffffffffc020045a:	ddad                	beqz	a1,ffffffffc02003d4 <kmonitor+0x92>
ffffffffc020045c:	854a                	mv	a0,s2
ffffffffc020045e:	172060ef          	jal	ra,ffffffffc02065d0 <strchr>
ffffffffc0200462:	d96d                	beqz	a0,ffffffffc0200454 <kmonitor+0x112>
ffffffffc0200464:	00044583          	lbu	a1,0(s0)
ffffffffc0200468:	bf91                	j	ffffffffc02003bc <kmonitor+0x7a>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc020046a:	45c1                	li	a1,16
ffffffffc020046c:	855a                	mv	a0,s6
ffffffffc020046e:	d21ff0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0200472:	b7f1                	j	ffffffffc020043e <kmonitor+0xfc>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc0200474:	6582                	ld	a1,0(sp)
ffffffffc0200476:	00006517          	auipc	a0,0x6
ffffffffc020047a:	39a50513          	addi	a0,a0,922 # ffffffffc0206810 <commands+0xc8>
ffffffffc020047e:	d11ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    return 0;
ffffffffc0200482:	b72d                	j	ffffffffc02003ac <kmonitor+0x6a>

ffffffffc0200484 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc0200484:	000ac317          	auipc	t1,0xac
ffffffffc0200488:	00430313          	addi	t1,t1,4 # ffffffffc02ac488 <is_panic>
ffffffffc020048c:	00033303          	ld	t1,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc0200490:	715d                	addi	sp,sp,-80
ffffffffc0200492:	ec06                	sd	ra,24(sp)
ffffffffc0200494:	e822                	sd	s0,16(sp)
ffffffffc0200496:	f436                	sd	a3,40(sp)
ffffffffc0200498:	f83a                	sd	a4,48(sp)
ffffffffc020049a:	fc3e                	sd	a5,56(sp)
ffffffffc020049c:	e0c2                	sd	a6,64(sp)
ffffffffc020049e:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02004a0:	02031c63          	bnez	t1,ffffffffc02004d8 <__panic+0x54>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02004a4:	4785                	li	a5,1
ffffffffc02004a6:	8432                	mv	s0,a2
ffffffffc02004a8:	000ac717          	auipc	a4,0xac
ffffffffc02004ac:	fef73023          	sd	a5,-32(a4) # ffffffffc02ac488 <is_panic>

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b0:	862e                	mv	a2,a1
    va_start(ap, fmt);
ffffffffc02004b2:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004b4:	85aa                	mv	a1,a0
ffffffffc02004b6:	00006517          	auipc	a0,0x6
ffffffffc02004ba:	41250513          	addi	a0,a0,1042 # ffffffffc02068c8 <commands+0x180>
    va_start(ap, fmt);
ffffffffc02004be:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02004c0:	ccfff0ef          	jal	ra,ffffffffc020018e <cprintf>
    vcprintf(fmt, ap);
ffffffffc02004c4:	65a2                	ld	a1,8(sp)
ffffffffc02004c6:	8522                	mv	a0,s0
ffffffffc02004c8:	ca7ff0ef          	jal	ra,ffffffffc020016e <vcprintf>
    cprintf("\n");
ffffffffc02004cc:	00007517          	auipc	a0,0x7
ffffffffc02004d0:	3a450513          	addi	a0,a0,932 # ffffffffc0207870 <default_pmm_manager+0x520>
ffffffffc02004d4:	cbbff0ef          	jal	ra,ffffffffc020018e <cprintf>
#endif
}

static inline void sbi_shutdown(void)
{
	SBI_CALL_0(SBI_SHUTDOWN);
ffffffffc02004d8:	4501                	li	a0,0
ffffffffc02004da:	4581                	li	a1,0
ffffffffc02004dc:	4601                	li	a2,0
ffffffffc02004de:	48a1                	li	a7,8
ffffffffc02004e0:	00000073          	ecall
    va_end(ap);

panic_dead:
    // No debug monitor here
    sbi_shutdown();
    intr_disable();
ffffffffc02004e4:	176000ef          	jal	ra,ffffffffc020065a <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc02004e8:	4501                	li	a0,0
ffffffffc02004ea:	e59ff0ef          	jal	ra,ffffffffc0200342 <kmonitor>
ffffffffc02004ee:	bfed                	j	ffffffffc02004e8 <__panic+0x64>

ffffffffc02004f0 <__warn>:
    }
}

/* __warn - like panic, but don't */
void
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc02004f0:	715d                	addi	sp,sp,-80
ffffffffc02004f2:	e822                	sd	s0,16(sp)
ffffffffc02004f4:	fc3e                	sd	a5,56(sp)
ffffffffc02004f6:	8432                	mv	s0,a2
    va_list ap;
    va_start(ap, fmt);
ffffffffc02004f8:	103c                	addi	a5,sp,40
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc02004fa:	862e                	mv	a2,a1
ffffffffc02004fc:	85aa                	mv	a1,a0
ffffffffc02004fe:	00006517          	auipc	a0,0x6
ffffffffc0200502:	3ea50513          	addi	a0,a0,1002 # ffffffffc02068e8 <commands+0x1a0>
__warn(const char *file, int line, const char *fmt, ...) {
ffffffffc0200506:	ec06                	sd	ra,24(sp)
ffffffffc0200508:	f436                	sd	a3,40(sp)
ffffffffc020050a:	f83a                	sd	a4,48(sp)
ffffffffc020050c:	e0c2                	sd	a6,64(sp)
ffffffffc020050e:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0200510:	e43e                	sd	a5,8(sp)
    cprintf("kernel warning at %s:%d:\n    ", file, line);
ffffffffc0200512:	c7dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    vcprintf(fmt, ap);
ffffffffc0200516:	65a2                	ld	a1,8(sp)
ffffffffc0200518:	8522                	mv	a0,s0
ffffffffc020051a:	c55ff0ef          	jal	ra,ffffffffc020016e <vcprintf>
    cprintf("\n");
ffffffffc020051e:	00007517          	auipc	a0,0x7
ffffffffc0200522:	35250513          	addi	a0,a0,850 # ffffffffc0207870 <default_pmm_manager+0x520>
ffffffffc0200526:	c69ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    va_end(ap);
}
ffffffffc020052a:	60e2                	ld	ra,24(sp)
ffffffffc020052c:	6442                	ld	s0,16(sp)
ffffffffc020052e:	6161                	addi	sp,sp,80
ffffffffc0200530:	8082                	ret

ffffffffc0200532 <clock_init>:
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
    // divided by 500 when using Spike(2MHz)
    // divided by 100 when using QEMU(10MHz)
    timebase = 1e7 / 100;
ffffffffc0200532:	67e1                	lui	a5,0x18
ffffffffc0200534:	6a078793          	addi	a5,a5,1696 # 186a0 <_binary_obj___user_exit_out_size+0xdc20>
ffffffffc0200538:	000ac717          	auipc	a4,0xac
ffffffffc020053c:	f4f73c23          	sd	a5,-168(a4) # ffffffffc02ac490 <timebase>
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200540:	c0102573          	rdtime	a0
	SBI_CALL_1(SBI_SET_TIMER, stime_value);
ffffffffc0200544:	4581                	li	a1,0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200546:	953e                	add	a0,a0,a5
ffffffffc0200548:	4601                	li	a2,0
ffffffffc020054a:	4881                	li	a7,0
ffffffffc020054c:	00000073          	ecall
    set_csr(sie, MIP_STIP);
ffffffffc0200550:	02000793          	li	a5,32
ffffffffc0200554:	1047a7f3          	csrrs	a5,sie,a5
    cprintf("++ setup timer interrupts\n");
ffffffffc0200558:	00006517          	auipc	a0,0x6
ffffffffc020055c:	3b050513          	addi	a0,a0,944 # ffffffffc0206908 <commands+0x1c0>
    ticks = 0;
ffffffffc0200560:	000ac797          	auipc	a5,0xac
ffffffffc0200564:	f807b023          	sd	zero,-128(a5) # ffffffffc02ac4e0 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200568:	c27ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020056c <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020056c:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200570:	000ac797          	auipc	a5,0xac
ffffffffc0200574:	f2078793          	addi	a5,a5,-224 # ffffffffc02ac490 <timebase>
ffffffffc0200578:	639c                	ld	a5,0(a5)
ffffffffc020057a:	4581                	li	a1,0
ffffffffc020057c:	4601                	li	a2,0
ffffffffc020057e:	953e                	add	a0,a0,a5
ffffffffc0200580:	4881                	li	a7,0
ffffffffc0200582:	00000073          	ecall
ffffffffc0200586:	8082                	ret

ffffffffc0200588 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200588:	8082                	ret

ffffffffc020058a <cons_putc>:
#include <sched.h>
#include <riscv.h>
#include <assert.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020058a:	100027f3          	csrr	a5,sstatus
ffffffffc020058e:	8b89                	andi	a5,a5,2
ffffffffc0200590:	0ff57513          	andi	a0,a0,255
ffffffffc0200594:	e799                	bnez	a5,ffffffffc02005a2 <cons_putc+0x18>
	SBI_CALL_1(SBI_CONSOLE_PUTCHAR, ch);
ffffffffc0200596:	4581                	li	a1,0
ffffffffc0200598:	4601                	li	a2,0
ffffffffc020059a:	4885                	li	a7,1
ffffffffc020059c:	00000073          	ecall
    }
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
ffffffffc02005a0:	8082                	ret

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) {
ffffffffc02005a2:	1101                	addi	sp,sp,-32
ffffffffc02005a4:	ec06                	sd	ra,24(sp)
ffffffffc02005a6:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc02005a8:	0b2000ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc02005ac:	6522                	ld	a0,8(sp)
ffffffffc02005ae:	4581                	li	a1,0
ffffffffc02005b0:	4601                	li	a2,0
ffffffffc02005b2:	4885                	li	a7,1
ffffffffc02005b4:	00000073          	ecall
    local_intr_save(intr_flag);
    {
        sbi_console_putchar((unsigned char)c);
    }
    local_intr_restore(intr_flag);
}
ffffffffc02005b8:	60e2                	ld	ra,24(sp)
ffffffffc02005ba:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02005bc:	0980006f          	j	ffffffffc0200654 <intr_enable>

ffffffffc02005c0 <cons_getc>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02005c0:	100027f3          	csrr	a5,sstatus
ffffffffc02005c4:	8b89                	andi	a5,a5,2
ffffffffc02005c6:	eb89                	bnez	a5,ffffffffc02005d8 <cons_getc+0x18>
	return SBI_CALL_0(SBI_CONSOLE_GETCHAR);
ffffffffc02005c8:	4501                	li	a0,0
ffffffffc02005ca:	4581                	li	a1,0
ffffffffc02005cc:	4601                	li	a2,0
ffffffffc02005ce:	4889                	li	a7,2
ffffffffc02005d0:	00000073          	ecall
ffffffffc02005d4:	2501                	sext.w	a0,a0
    {
        c = sbi_console_getchar();
    }
    local_intr_restore(intr_flag);
    return c;
}
ffffffffc02005d6:	8082                	ret
int cons_getc(void) {
ffffffffc02005d8:	1101                	addi	sp,sp,-32
ffffffffc02005da:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc02005dc:	07e000ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc02005e0:	4501                	li	a0,0
ffffffffc02005e2:	4581                	li	a1,0
ffffffffc02005e4:	4601                	li	a2,0
ffffffffc02005e6:	4889                	li	a7,2
ffffffffc02005e8:	00000073          	ecall
ffffffffc02005ec:	2501                	sext.w	a0,a0
ffffffffc02005ee:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc02005f0:	064000ef          	jal	ra,ffffffffc0200654 <intr_enable>
}
ffffffffc02005f4:	60e2                	ld	ra,24(sp)
ffffffffc02005f6:	6522                	ld	a0,8(sp)
ffffffffc02005f8:	6105                	addi	sp,sp,32
ffffffffc02005fa:	8082                	ret

ffffffffc02005fc <ide_init>:
#include <stdio.h>
#include <string.h>
#include <trap.h>
#include <riscv.h>

void ide_init(void) {}
ffffffffc02005fc:	8082                	ret

ffffffffc02005fe <ide_device_valid>:

#define MAX_IDE 2
#define MAX_DISK_NSECS 56
static char ide[MAX_DISK_NSECS * SECTSIZE];

bool ide_device_valid(unsigned short ideno) { return ideno < MAX_IDE; }
ffffffffc02005fe:	00253513          	sltiu	a0,a0,2
ffffffffc0200602:	8082                	ret

ffffffffc0200604 <ide_device_size>:

size_t ide_device_size(unsigned short ideno) { return MAX_DISK_NSECS; }
ffffffffc0200604:	03800513          	li	a0,56
ffffffffc0200608:	8082                	ret

ffffffffc020060a <ide_read_secs>:

int ide_read_secs(unsigned short ideno, uint32_t secno, void *dst,
                  size_t nsecs) {
    int iobase = secno * SECTSIZE;
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020060a:	000a1797          	auipc	a5,0xa1
ffffffffc020060e:	e7e78793          	addi	a5,a5,-386 # ffffffffc02a1488 <ide>
ffffffffc0200612:	0095959b          	slliw	a1,a1,0x9
                  size_t nsecs) {
ffffffffc0200616:	1141                	addi	sp,sp,-16
ffffffffc0200618:	8532                	mv	a0,a2
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc020061a:	95be                	add	a1,a1,a5
ffffffffc020061c:	00969613          	slli	a2,a3,0x9
                  size_t nsecs) {
ffffffffc0200620:	e406                	sd	ra,8(sp)
    memcpy(dst, &ide[iobase], nsecs * SECTSIZE);
ffffffffc0200622:	7df050ef          	jal	ra,ffffffffc0206600 <memcpy>
    return 0;
}
ffffffffc0200626:	60a2                	ld	ra,8(sp)
ffffffffc0200628:	4501                	li	a0,0
ffffffffc020062a:	0141                	addi	sp,sp,16
ffffffffc020062c:	8082                	ret

ffffffffc020062e <ide_write_secs>:

int ide_write_secs(unsigned short ideno, uint32_t secno, const void *src,
                   size_t nsecs) {
ffffffffc020062e:	8732                	mv	a4,a2
    int iobase = secno * SECTSIZE;
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200630:	0095979b          	slliw	a5,a1,0x9
ffffffffc0200634:	000a1517          	auipc	a0,0xa1
ffffffffc0200638:	e5450513          	addi	a0,a0,-428 # ffffffffc02a1488 <ide>
                   size_t nsecs) {
ffffffffc020063c:	1141                	addi	sp,sp,-16
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc020063e:	00969613          	slli	a2,a3,0x9
ffffffffc0200642:	85ba                	mv	a1,a4
ffffffffc0200644:	953e                	add	a0,a0,a5
                   size_t nsecs) {
ffffffffc0200646:	e406                	sd	ra,8(sp)
    memcpy(&ide[iobase], src, nsecs * SECTSIZE);
ffffffffc0200648:	7b9050ef          	jal	ra,ffffffffc0206600 <memcpy>
    return 0;
}
ffffffffc020064c:	60a2                	ld	ra,8(sp)
ffffffffc020064e:	4501                	li	a0,0
ffffffffc0200650:	0141                	addi	sp,sp,16
ffffffffc0200652:	8082                	ret

ffffffffc0200654 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc0200654:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc0200658:	8082                	ret

ffffffffc020065a <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc020065a:	100177f3          	csrrci	a5,sstatus,2
ffffffffc020065e:	8082                	ret

ffffffffc0200660 <pic_init>:
#include <picirq.h>

void pic_enable(unsigned int irq) {}

/* pic_init - initialize the 8259A interrupt controllers */
void pic_init(void) {}
ffffffffc0200660:	8082                	ret

ffffffffc0200662 <idt_init>:
void
idt_init(void) {
    extern void __alltraps(void);
    /* Set sscratch register to 0, indicating to exception vector that we are
     * presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc0200662:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc0200666:	00000797          	auipc	a5,0x0
ffffffffc020066a:	67a78793          	addi	a5,a5,1658 # ffffffffc0200ce0 <__alltraps>
ffffffffc020066e:	10579073          	csrw	stvec,a5
    /* Allow kernel to access user memory */
    set_csr(sstatus, SSTATUS_SUM);
ffffffffc0200672:	000407b7          	lui	a5,0x40
ffffffffc0200676:	1007a7f3          	csrrs	a5,sstatus,a5
}
ffffffffc020067a:	8082                	ret

ffffffffc020067c <print_regs>:
    cprintf("  tval 0x%08x\n", tf->tval);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs* gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020067c:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs* gpr) {
ffffffffc020067e:	1141                	addi	sp,sp,-16
ffffffffc0200680:	e022                	sd	s0,0(sp)
ffffffffc0200682:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc0200684:	00006517          	auipc	a0,0x6
ffffffffc0200688:	5cc50513          	addi	a0,a0,1484 # ffffffffc0206c50 <commands+0x508>
void print_regs(struct pushregs* gpr) {
ffffffffc020068c:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc020068e:	b01ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc0200692:	640c                	ld	a1,8(s0)
ffffffffc0200694:	00006517          	auipc	a0,0x6
ffffffffc0200698:	5d450513          	addi	a0,a0,1492 # ffffffffc0206c68 <commands+0x520>
ffffffffc020069c:	af3ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02006a0:	680c                	ld	a1,16(s0)
ffffffffc02006a2:	00006517          	auipc	a0,0x6
ffffffffc02006a6:	5de50513          	addi	a0,a0,1502 # ffffffffc0206c80 <commands+0x538>
ffffffffc02006aa:	ae5ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc02006ae:	6c0c                	ld	a1,24(s0)
ffffffffc02006b0:	00006517          	auipc	a0,0x6
ffffffffc02006b4:	5e850513          	addi	a0,a0,1512 # ffffffffc0206c98 <commands+0x550>
ffffffffc02006b8:	ad7ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc02006bc:	700c                	ld	a1,32(s0)
ffffffffc02006be:	00006517          	auipc	a0,0x6
ffffffffc02006c2:	5f250513          	addi	a0,a0,1522 # ffffffffc0206cb0 <commands+0x568>
ffffffffc02006c6:	ac9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc02006ca:	740c                	ld	a1,40(s0)
ffffffffc02006cc:	00006517          	auipc	a0,0x6
ffffffffc02006d0:	5fc50513          	addi	a0,a0,1532 # ffffffffc0206cc8 <commands+0x580>
ffffffffc02006d4:	abbff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc02006d8:	780c                	ld	a1,48(s0)
ffffffffc02006da:	00006517          	auipc	a0,0x6
ffffffffc02006de:	60650513          	addi	a0,a0,1542 # ffffffffc0206ce0 <commands+0x598>
ffffffffc02006e2:	aadff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc02006e6:	7c0c                	ld	a1,56(s0)
ffffffffc02006e8:	00006517          	auipc	a0,0x6
ffffffffc02006ec:	61050513          	addi	a0,a0,1552 # ffffffffc0206cf8 <commands+0x5b0>
ffffffffc02006f0:	a9fff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc02006f4:	602c                	ld	a1,64(s0)
ffffffffc02006f6:	00006517          	auipc	a0,0x6
ffffffffc02006fa:	61a50513          	addi	a0,a0,1562 # ffffffffc0206d10 <commands+0x5c8>
ffffffffc02006fe:	a91ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc0200702:	642c                	ld	a1,72(s0)
ffffffffc0200704:	00006517          	auipc	a0,0x6
ffffffffc0200708:	62450513          	addi	a0,a0,1572 # ffffffffc0206d28 <commands+0x5e0>
ffffffffc020070c:	a83ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc0200710:	682c                	ld	a1,80(s0)
ffffffffc0200712:	00006517          	auipc	a0,0x6
ffffffffc0200716:	62e50513          	addi	a0,a0,1582 # ffffffffc0206d40 <commands+0x5f8>
ffffffffc020071a:	a75ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc020071e:	6c2c                	ld	a1,88(s0)
ffffffffc0200720:	00006517          	auipc	a0,0x6
ffffffffc0200724:	63850513          	addi	a0,a0,1592 # ffffffffc0206d58 <commands+0x610>
ffffffffc0200728:	a67ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc020072c:	702c                	ld	a1,96(s0)
ffffffffc020072e:	00006517          	auipc	a0,0x6
ffffffffc0200732:	64250513          	addi	a0,a0,1602 # ffffffffc0206d70 <commands+0x628>
ffffffffc0200736:	a59ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc020073a:	742c                	ld	a1,104(s0)
ffffffffc020073c:	00006517          	auipc	a0,0x6
ffffffffc0200740:	64c50513          	addi	a0,a0,1612 # ffffffffc0206d88 <commands+0x640>
ffffffffc0200744:	a4bff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc0200748:	782c                	ld	a1,112(s0)
ffffffffc020074a:	00006517          	auipc	a0,0x6
ffffffffc020074e:	65650513          	addi	a0,a0,1622 # ffffffffc0206da0 <commands+0x658>
ffffffffc0200752:	a3dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc0200756:	7c2c                	ld	a1,120(s0)
ffffffffc0200758:	00006517          	auipc	a0,0x6
ffffffffc020075c:	66050513          	addi	a0,a0,1632 # ffffffffc0206db8 <commands+0x670>
ffffffffc0200760:	a2fff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc0200764:	604c                	ld	a1,128(s0)
ffffffffc0200766:	00006517          	auipc	a0,0x6
ffffffffc020076a:	66a50513          	addi	a0,a0,1642 # ffffffffc0206dd0 <commands+0x688>
ffffffffc020076e:	a21ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc0200772:	644c                	ld	a1,136(s0)
ffffffffc0200774:	00006517          	auipc	a0,0x6
ffffffffc0200778:	67450513          	addi	a0,a0,1652 # ffffffffc0206de8 <commands+0x6a0>
ffffffffc020077c:	a13ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc0200780:	684c                	ld	a1,144(s0)
ffffffffc0200782:	00006517          	auipc	a0,0x6
ffffffffc0200786:	67e50513          	addi	a0,a0,1662 # ffffffffc0206e00 <commands+0x6b8>
ffffffffc020078a:	a05ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc020078e:	6c4c                	ld	a1,152(s0)
ffffffffc0200790:	00006517          	auipc	a0,0x6
ffffffffc0200794:	68850513          	addi	a0,a0,1672 # ffffffffc0206e18 <commands+0x6d0>
ffffffffc0200798:	9f7ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc020079c:	704c                	ld	a1,160(s0)
ffffffffc020079e:	00006517          	auipc	a0,0x6
ffffffffc02007a2:	69250513          	addi	a0,a0,1682 # ffffffffc0206e30 <commands+0x6e8>
ffffffffc02007a6:	9e9ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc02007aa:	744c                	ld	a1,168(s0)
ffffffffc02007ac:	00006517          	auipc	a0,0x6
ffffffffc02007b0:	69c50513          	addi	a0,a0,1692 # ffffffffc0206e48 <commands+0x700>
ffffffffc02007b4:	9dbff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc02007b8:	784c                	ld	a1,176(s0)
ffffffffc02007ba:	00006517          	auipc	a0,0x6
ffffffffc02007be:	6a650513          	addi	a0,a0,1702 # ffffffffc0206e60 <commands+0x718>
ffffffffc02007c2:	9cdff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc02007c6:	7c4c                	ld	a1,184(s0)
ffffffffc02007c8:	00006517          	auipc	a0,0x6
ffffffffc02007cc:	6b050513          	addi	a0,a0,1712 # ffffffffc0206e78 <commands+0x730>
ffffffffc02007d0:	9bfff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc02007d4:	606c                	ld	a1,192(s0)
ffffffffc02007d6:	00006517          	auipc	a0,0x6
ffffffffc02007da:	6ba50513          	addi	a0,a0,1722 # ffffffffc0206e90 <commands+0x748>
ffffffffc02007de:	9b1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc02007e2:	646c                	ld	a1,200(s0)
ffffffffc02007e4:	00006517          	auipc	a0,0x6
ffffffffc02007e8:	6c450513          	addi	a0,a0,1732 # ffffffffc0206ea8 <commands+0x760>
ffffffffc02007ec:	9a3ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc02007f0:	686c                	ld	a1,208(s0)
ffffffffc02007f2:	00006517          	auipc	a0,0x6
ffffffffc02007f6:	6ce50513          	addi	a0,a0,1742 # ffffffffc0206ec0 <commands+0x778>
ffffffffc02007fa:	995ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc02007fe:	6c6c                	ld	a1,216(s0)
ffffffffc0200800:	00006517          	auipc	a0,0x6
ffffffffc0200804:	6d850513          	addi	a0,a0,1752 # ffffffffc0206ed8 <commands+0x790>
ffffffffc0200808:	987ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc020080c:	706c                	ld	a1,224(s0)
ffffffffc020080e:	00006517          	auipc	a0,0x6
ffffffffc0200812:	6e250513          	addi	a0,a0,1762 # ffffffffc0206ef0 <commands+0x7a8>
ffffffffc0200816:	979ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc020081a:	746c                	ld	a1,232(s0)
ffffffffc020081c:	00006517          	auipc	a0,0x6
ffffffffc0200820:	6ec50513          	addi	a0,a0,1772 # ffffffffc0206f08 <commands+0x7c0>
ffffffffc0200824:	96bff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200828:	786c                	ld	a1,240(s0)
ffffffffc020082a:	00006517          	auipc	a0,0x6
ffffffffc020082e:	6f650513          	addi	a0,a0,1782 # ffffffffc0206f20 <commands+0x7d8>
ffffffffc0200832:	95dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200836:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200838:	6402                	ld	s0,0(sp)
ffffffffc020083a:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc020083c:	00006517          	auipc	a0,0x6
ffffffffc0200840:	6fc50513          	addi	a0,a0,1788 # ffffffffc0206f38 <commands+0x7f0>
}
ffffffffc0200844:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200846:	949ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc020084a <print_trapframe>:
print_trapframe(struct trapframe *tf) {
ffffffffc020084a:	1141                	addi	sp,sp,-16
ffffffffc020084c:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020084e:	85aa                	mv	a1,a0
print_trapframe(struct trapframe *tf) {
ffffffffc0200850:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc0200852:	00006517          	auipc	a0,0x6
ffffffffc0200856:	6fe50513          	addi	a0,a0,1790 # ffffffffc0206f50 <commands+0x808>
print_trapframe(struct trapframe *tf) {
ffffffffc020085a:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc020085c:	933ff0ef          	jal	ra,ffffffffc020018e <cprintf>
    print_regs(&tf->gpr);
ffffffffc0200860:	8522                	mv	a0,s0
ffffffffc0200862:	e1bff0ef          	jal	ra,ffffffffc020067c <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc0200866:	10043583          	ld	a1,256(s0)
ffffffffc020086a:	00006517          	auipc	a0,0x6
ffffffffc020086e:	6fe50513          	addi	a0,a0,1790 # ffffffffc0206f68 <commands+0x820>
ffffffffc0200872:	91dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc0200876:	10843583          	ld	a1,264(s0)
ffffffffc020087a:	00006517          	auipc	a0,0x6
ffffffffc020087e:	70650513          	addi	a0,a0,1798 # ffffffffc0206f80 <commands+0x838>
ffffffffc0200882:	90dff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  tval 0x%08x\n", tf->tval);
ffffffffc0200886:	11043583          	ld	a1,272(s0)
ffffffffc020088a:	00006517          	auipc	a0,0x6
ffffffffc020088e:	70e50513          	addi	a0,a0,1806 # ffffffffc0206f98 <commands+0x850>
ffffffffc0200892:	8fdff0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200896:	11843583          	ld	a1,280(s0)
}
ffffffffc020089a:	6402                	ld	s0,0(sp)
ffffffffc020089c:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc020089e:	00006517          	auipc	a0,0x6
ffffffffc02008a2:	70a50513          	addi	a0,a0,1802 # ffffffffc0206fa8 <commands+0x860>
}
ffffffffc02008a6:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02008a8:	8e7ff06f          	j	ffffffffc020018e <cprintf>

ffffffffc02008ac <pgfault_handler>:
            trap_in_kernel(tf) ? 'K' : 'U',
            tf->cause == CAUSE_STORE_PAGE_FAULT ? 'W' : 'R');
}

static int
pgfault_handler(struct trapframe *tf) {
ffffffffc02008ac:	1101                	addi	sp,sp,-32
ffffffffc02008ae:	e426                	sd	s1,8(sp)
    extern struct mm_struct *check_mm_struct;
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008b0:	000ac497          	auipc	s1,0xac
ffffffffc02008b4:	d4848493          	addi	s1,s1,-696 # ffffffffc02ac5f8 <check_mm_struct>
ffffffffc02008b8:	609c                	ld	a5,0(s1)
pgfault_handler(struct trapframe *tf) {
ffffffffc02008ba:	e822                	sd	s0,16(sp)
ffffffffc02008bc:	ec06                	sd	ra,24(sp)
ffffffffc02008be:	842a                	mv	s0,a0
    if(check_mm_struct !=NULL) { //used for test check_swap
ffffffffc02008c0:	cbbd                	beqz	a5,ffffffffc0200936 <pgfault_handler+0x8a>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008c2:	10053783          	ld	a5,256(a0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008c6:	11053583          	ld	a1,272(a0)
ffffffffc02008ca:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc02008ce:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02008d2:	cba1                	beqz	a5,ffffffffc0200922 <pgfault_handler+0x76>
ffffffffc02008d4:	11843703          	ld	a4,280(s0)
ffffffffc02008d8:	47bd                	li	a5,15
ffffffffc02008da:	05700693          	li	a3,87
ffffffffc02008de:	00f70463          	beq	a4,a5,ffffffffc02008e6 <pgfault_handler+0x3a>
ffffffffc02008e2:	05200693          	li	a3,82
ffffffffc02008e6:	00006517          	auipc	a0,0x6
ffffffffc02008ea:	2ea50513          	addi	a0,a0,746 # ffffffffc0206bd0 <commands+0x488>
ffffffffc02008ee:	8a1ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            print_pgfault(tf);
        }
    struct mm_struct *mm;
    if (check_mm_struct != NULL) {
ffffffffc02008f2:	6088                	ld	a0,0(s1)
ffffffffc02008f4:	c129                	beqz	a0,ffffffffc0200936 <pgfault_handler+0x8a>
        assert(current == idleproc);
ffffffffc02008f6:	000ac797          	auipc	a5,0xac
ffffffffc02008fa:	bca78793          	addi	a5,a5,-1078 # ffffffffc02ac4c0 <current>
ffffffffc02008fe:	6398                	ld	a4,0(a5)
ffffffffc0200900:	000ac797          	auipc	a5,0xac
ffffffffc0200904:	bc878793          	addi	a5,a5,-1080 # ffffffffc02ac4c8 <idleproc>
ffffffffc0200908:	639c                	ld	a5,0(a5)
ffffffffc020090a:	04f71763          	bne	a4,a5,ffffffffc0200958 <pgfault_handler+0xac>
            print_pgfault(tf);
            panic("unhandled page fault.\n");
        }
        mm = current->mm;
    }
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020090e:	11043603          	ld	a2,272(s0)
ffffffffc0200912:	11843583          	ld	a1,280(s0)
}
ffffffffc0200916:	6442                	ld	s0,16(sp)
ffffffffc0200918:	60e2                	ld	ra,24(sp)
ffffffffc020091a:	64a2                	ld	s1,8(sp)
ffffffffc020091c:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc020091e:	07e0406f          	j	ffffffffc020499c <do_pgfault>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200922:	11843703          	ld	a4,280(s0)
ffffffffc0200926:	47bd                	li	a5,15
ffffffffc0200928:	05500613          	li	a2,85
ffffffffc020092c:	05700693          	li	a3,87
ffffffffc0200930:	faf719e3          	bne	a4,a5,ffffffffc02008e2 <pgfault_handler+0x36>
ffffffffc0200934:	bf4d                	j	ffffffffc02008e6 <pgfault_handler+0x3a>
        if (current == NULL) {
ffffffffc0200936:	000ac797          	auipc	a5,0xac
ffffffffc020093a:	b8a78793          	addi	a5,a5,-1142 # ffffffffc02ac4c0 <current>
ffffffffc020093e:	639c                	ld	a5,0(a5)
ffffffffc0200940:	cf85                	beqz	a5,ffffffffc0200978 <pgfault_handler+0xcc>
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200942:	11043603          	ld	a2,272(s0)
ffffffffc0200946:	11843583          	ld	a1,280(s0)
}
ffffffffc020094a:	6442                	ld	s0,16(sp)
ffffffffc020094c:	60e2                	ld	ra,24(sp)
ffffffffc020094e:	64a2                	ld	s1,8(sp)
        mm = current->mm;
ffffffffc0200950:	7788                	ld	a0,40(a5)
}
ffffffffc0200952:	6105                	addi	sp,sp,32
    return do_pgfault(mm, tf->cause, tf->tval);
ffffffffc0200954:	0480406f          	j	ffffffffc020499c <do_pgfault>
        assert(current == idleproc);
ffffffffc0200958:	00006697          	auipc	a3,0x6
ffffffffc020095c:	29868693          	addi	a3,a3,664 # ffffffffc0206bf0 <commands+0x4a8>
ffffffffc0200960:	00006617          	auipc	a2,0x6
ffffffffc0200964:	2a860613          	addi	a2,a2,680 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0200968:	06b00593          	li	a1,107
ffffffffc020096c:	00006517          	auipc	a0,0x6
ffffffffc0200970:	2b450513          	addi	a0,a0,692 # ffffffffc0206c20 <commands+0x4d8>
ffffffffc0200974:	b11ff0ef          	jal	ra,ffffffffc0200484 <__panic>
            print_trapframe(tf);
ffffffffc0200978:	8522                	mv	a0,s0
ffffffffc020097a:	ed1ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020097e:	10043783          	ld	a5,256(s0)
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc0200982:	11043583          	ld	a1,272(s0)
ffffffffc0200986:	04b00613          	li	a2,75
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc020098a:	1007f793          	andi	a5,a5,256
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc020098e:	e399                	bnez	a5,ffffffffc0200994 <pgfault_handler+0xe8>
ffffffffc0200990:	05500613          	li	a2,85
ffffffffc0200994:	11843703          	ld	a4,280(s0)
ffffffffc0200998:	47bd                	li	a5,15
ffffffffc020099a:	02f70663          	beq	a4,a5,ffffffffc02009c6 <pgfault_handler+0x11a>
ffffffffc020099e:	05200693          	li	a3,82
ffffffffc02009a2:	00006517          	auipc	a0,0x6
ffffffffc02009a6:	22e50513          	addi	a0,a0,558 # ffffffffc0206bd0 <commands+0x488>
ffffffffc02009aa:	fe4ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            panic("unhandled page fault.\n");
ffffffffc02009ae:	00006617          	auipc	a2,0x6
ffffffffc02009b2:	28a60613          	addi	a2,a2,650 # ffffffffc0206c38 <commands+0x4f0>
ffffffffc02009b6:	07200593          	li	a1,114
ffffffffc02009ba:	00006517          	auipc	a0,0x6
ffffffffc02009be:	26650513          	addi	a0,a0,614 # ffffffffc0206c20 <commands+0x4d8>
ffffffffc02009c2:	ac3ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    cprintf("page fault at 0x%08x: %c/%c\n", tf->tval,
ffffffffc02009c6:	05700693          	li	a3,87
ffffffffc02009ca:	bfe1                	j	ffffffffc02009a2 <pgfault_handler+0xf6>

ffffffffc02009cc <interrupt_handler>:

static volatile int in_swap_tick_event = 0;
extern struct mm_struct *check_mm_struct;

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc02009cc:	11853783          	ld	a5,280(a0)
ffffffffc02009d0:	577d                	li	a4,-1
ffffffffc02009d2:	8305                	srli	a4,a4,0x1
ffffffffc02009d4:	8ff9                	and	a5,a5,a4
    switch (cause) {
ffffffffc02009d6:	472d                	li	a4,11
ffffffffc02009d8:	08f76763          	bltu	a4,a5,ffffffffc0200a66 <interrupt_handler+0x9a>
ffffffffc02009dc:	00006717          	auipc	a4,0x6
ffffffffc02009e0:	f4870713          	addi	a4,a4,-184 # ffffffffc0206924 <commands+0x1dc>
ffffffffc02009e4:	078a                	slli	a5,a5,0x2
ffffffffc02009e6:	97ba                	add	a5,a5,a4
ffffffffc02009e8:	439c                	lw	a5,0(a5)
ffffffffc02009ea:	97ba                	add	a5,a5,a4
ffffffffc02009ec:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc02009ee:	00006517          	auipc	a0,0x6
ffffffffc02009f2:	1a250513          	addi	a0,a0,418 # ffffffffc0206b90 <commands+0x448>
ffffffffc02009f6:	f98ff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc02009fa:	00006517          	auipc	a0,0x6
ffffffffc02009fe:	17650513          	addi	a0,a0,374 # ffffffffc0206b70 <commands+0x428>
ffffffffc0200a02:	f8cff06f          	j	ffffffffc020018e <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200a06:	00006517          	auipc	a0,0x6
ffffffffc0200a0a:	12a50513          	addi	a0,a0,298 # ffffffffc0206b30 <commands+0x3e8>
ffffffffc0200a0e:	f80ff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc0200a12:	00006517          	auipc	a0,0x6
ffffffffc0200a16:	13e50513          	addi	a0,a0,318 # ffffffffc0206b50 <commands+0x408>
ffffffffc0200a1a:	f74ff06f          	j	ffffffffc020018e <cprintf>
            break;
        case IRQ_U_EXT:
            cprintf("User software interrupt\n");
            break;
        case IRQ_S_EXT:
            cprintf("Supervisor external interrupt\n");
ffffffffc0200a1e:	00006517          	auipc	a0,0x6
ffffffffc0200a22:	19250513          	addi	a0,a0,402 # ffffffffc0206bb0 <commands+0x468>
ffffffffc0200a26:	f68ff06f          	j	ffffffffc020018e <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc0200a2a:	1141                	addi	sp,sp,-16
ffffffffc0200a2c:	e406                	sd	ra,8(sp)
            clock_set_next_event();
ffffffffc0200a2e:	b3fff0ef          	jal	ra,ffffffffc020056c <clock_set_next_event>
            if (++ticks % TICK_NUM == 0 && current) {
ffffffffc0200a32:	000ac797          	auipc	a5,0xac
ffffffffc0200a36:	aae78793          	addi	a5,a5,-1362 # ffffffffc02ac4e0 <ticks>
ffffffffc0200a3a:	639c                	ld	a5,0(a5)
ffffffffc0200a3c:	06400713          	li	a4,100
ffffffffc0200a40:	0785                	addi	a5,a5,1
ffffffffc0200a42:	02e7f733          	remu	a4,a5,a4
ffffffffc0200a46:	000ac697          	auipc	a3,0xac
ffffffffc0200a4a:	a8f6bd23          	sd	a5,-1382(a3) # ffffffffc02ac4e0 <ticks>
ffffffffc0200a4e:	eb09                	bnez	a4,ffffffffc0200a60 <interrupt_handler+0x94>
ffffffffc0200a50:	000ac797          	auipc	a5,0xac
ffffffffc0200a54:	a7078793          	addi	a5,a5,-1424 # ffffffffc02ac4c0 <current>
ffffffffc0200a58:	639c                	ld	a5,0(a5)
ffffffffc0200a5a:	c399                	beqz	a5,ffffffffc0200a60 <interrupt_handler+0x94>
                current->need_resched = 1;
ffffffffc0200a5c:	4705                	li	a4,1
ffffffffc0200a5e:	ef98                	sd	a4,24(a5)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200a60:	60a2                	ld	ra,8(sp)
ffffffffc0200a62:	0141                	addi	sp,sp,16
ffffffffc0200a64:	8082                	ret
            print_trapframe(tf);
ffffffffc0200a66:	de5ff06f          	j	ffffffffc020084a <print_trapframe>

ffffffffc0200a6a <exception_handler>:
void kernel_execve_ret(struct trapframe *tf,uintptr_t kstacktop);
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
ffffffffc0200a6a:	11853783          	ld	a5,280(a0)
ffffffffc0200a6e:	473d                	li	a4,15
ffffffffc0200a70:	1af76e63          	bltu	a4,a5,ffffffffc0200c2c <exception_handler+0x1c2>
ffffffffc0200a74:	00006717          	auipc	a4,0x6
ffffffffc0200a78:	ee070713          	addi	a4,a4,-288 # ffffffffc0206954 <commands+0x20c>
ffffffffc0200a7c:	078a                	slli	a5,a5,0x2
ffffffffc0200a7e:	97ba                	add	a5,a5,a4
ffffffffc0200a80:	439c                	lw	a5,0(a5)
void exception_handler(struct trapframe *tf) {
ffffffffc0200a82:	1101                	addi	sp,sp,-32
ffffffffc0200a84:	e822                	sd	s0,16(sp)
ffffffffc0200a86:	ec06                	sd	ra,24(sp)
ffffffffc0200a88:	e426                	sd	s1,8(sp)
    switch (tf->cause) {
ffffffffc0200a8a:	97ba                	add	a5,a5,a4
ffffffffc0200a8c:	842a                	mv	s0,a0
ffffffffc0200a8e:	8782                	jr	a5
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4;
            syscall();
            break;
        case CAUSE_SUPERVISOR_ECALL:
            cprintf("Environment call from S-mode\n");
ffffffffc0200a90:	00006517          	auipc	a0,0x6
ffffffffc0200a94:	ff850513          	addi	a0,a0,-8 # ffffffffc0206a88 <commands+0x340>
ffffffffc0200a98:	ef6ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            tf->epc += 4;
ffffffffc0200a9c:	10843783          	ld	a5,264(s0)
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc0200aa0:	60e2                	ld	ra,24(sp)
ffffffffc0200aa2:	64a2                	ld	s1,8(sp)
            tf->epc += 4;
ffffffffc0200aa4:	0791                	addi	a5,a5,4
ffffffffc0200aa6:	10f43423          	sd	a5,264(s0)
}
ffffffffc0200aaa:	6442                	ld	s0,16(sp)
ffffffffc0200aac:	6105                	addi	sp,sp,32
            syscall();
ffffffffc0200aae:	6120506f          	j	ffffffffc02060c0 <syscall>
            cprintf("Environment call from H-mode\n");
ffffffffc0200ab2:	00006517          	auipc	a0,0x6
ffffffffc0200ab6:	ff650513          	addi	a0,a0,-10 # ffffffffc0206aa8 <commands+0x360>
}
ffffffffc0200aba:	6442                	ld	s0,16(sp)
ffffffffc0200abc:	60e2                	ld	ra,24(sp)
ffffffffc0200abe:	64a2                	ld	s1,8(sp)
ffffffffc0200ac0:	6105                	addi	sp,sp,32
            cprintf("Instruction access fault\n");
ffffffffc0200ac2:	eccff06f          	j	ffffffffc020018e <cprintf>
            cprintf("Environment call from M-mode\n");
ffffffffc0200ac6:	00006517          	auipc	a0,0x6
ffffffffc0200aca:	00250513          	addi	a0,a0,2 # ffffffffc0206ac8 <commands+0x380>
ffffffffc0200ace:	b7f5                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Instruction page fault\n");
ffffffffc0200ad0:	00006517          	auipc	a0,0x6
ffffffffc0200ad4:	01850513          	addi	a0,a0,24 # ffffffffc0206ae8 <commands+0x3a0>
ffffffffc0200ad8:	b7cd                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Load page fault\n");
ffffffffc0200ada:	00006517          	auipc	a0,0x6
ffffffffc0200ade:	02650513          	addi	a0,a0,38 # ffffffffc0206b00 <commands+0x3b8>
ffffffffc0200ae2:	eacff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ae6:	8522                	mv	a0,s0
ffffffffc0200ae8:	dc5ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200aec:	84aa                	mv	s1,a0
ffffffffc0200aee:	14051163          	bnez	a0,ffffffffc0200c30 <exception_handler+0x1c6>
}
ffffffffc0200af2:	60e2                	ld	ra,24(sp)
ffffffffc0200af4:	6442                	ld	s0,16(sp)
ffffffffc0200af6:	64a2                	ld	s1,8(sp)
ffffffffc0200af8:	6105                	addi	sp,sp,32
ffffffffc0200afa:	8082                	ret
            cprintf("Store/AMO page fault\n");
ffffffffc0200afc:	00006517          	auipc	a0,0x6
ffffffffc0200b00:	01c50513          	addi	a0,a0,28 # ffffffffc0206b18 <commands+0x3d0>
ffffffffc0200b04:	e8aff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200b08:	8522                	mv	a0,s0
ffffffffc0200b0a:	da3ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200b0e:	84aa                	mv	s1,a0
ffffffffc0200b10:	d16d                	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200b12:	8522                	mv	a0,s0
ffffffffc0200b14:	d37ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200b18:	86a6                	mv	a3,s1
ffffffffc0200b1a:	00006617          	auipc	a2,0x6
ffffffffc0200b1e:	f1e60613          	addi	a2,a2,-226 # ffffffffc0206a38 <commands+0x2f0>
ffffffffc0200b22:	0f900593          	li	a1,249
ffffffffc0200b26:	00006517          	auipc	a0,0x6
ffffffffc0200b2a:	0fa50513          	addi	a0,a0,250 # ffffffffc0206c20 <commands+0x4d8>
ffffffffc0200b2e:	957ff0ef          	jal	ra,ffffffffc0200484 <__panic>
            cprintf("Instruction address misaligned\n");
ffffffffc0200b32:	00006517          	auipc	a0,0x6
ffffffffc0200b36:	e6650513          	addi	a0,a0,-410 # ffffffffc0206998 <commands+0x250>
ffffffffc0200b3a:	b741                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Instruction access fault\n");
ffffffffc0200b3c:	00006517          	auipc	a0,0x6
ffffffffc0200b40:	e7c50513          	addi	a0,a0,-388 # ffffffffc02069b8 <commands+0x270>
ffffffffc0200b44:	bf9d                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Illegal instruction\n");
ffffffffc0200b46:	00006517          	auipc	a0,0x6
ffffffffc0200b4a:	e9250513          	addi	a0,a0,-366 # ffffffffc02069d8 <commands+0x290>
ffffffffc0200b4e:	b7b5                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Breakpoint\n");
ffffffffc0200b50:	00006517          	auipc	a0,0x6
ffffffffc0200b54:	ea050513          	addi	a0,a0,-352 # ffffffffc02069f0 <commands+0x2a8>
ffffffffc0200b58:	e36ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if(tf->gpr.a7 == 10){
ffffffffc0200b5c:	6458                	ld	a4,136(s0)
ffffffffc0200b5e:	47a9                	li	a5,10
ffffffffc0200b60:	f8f719e3          	bne	a4,a5,ffffffffc0200af2 <exception_handler+0x88>
                tf->epc += 4;
ffffffffc0200b64:	10843783          	ld	a5,264(s0)
ffffffffc0200b68:	0791                	addi	a5,a5,4
ffffffffc0200b6a:	10f43423          	sd	a5,264(s0)
                syscall();
ffffffffc0200b6e:	552050ef          	jal	ra,ffffffffc02060c0 <syscall>
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b72:	000ac797          	auipc	a5,0xac
ffffffffc0200b76:	94e78793          	addi	a5,a5,-1714 # ffffffffc02ac4c0 <current>
ffffffffc0200b7a:	639c                	ld	a5,0(a5)
ffffffffc0200b7c:	8522                	mv	a0,s0
}
ffffffffc0200b7e:	6442                	ld	s0,16(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b80:	6b9c                	ld	a5,16(a5)
}
ffffffffc0200b82:	60e2                	ld	ra,24(sp)
ffffffffc0200b84:	64a2                	ld	s1,8(sp)
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b86:	6589                	lui	a1,0x2
ffffffffc0200b88:	95be                	add	a1,a1,a5
}
ffffffffc0200b8a:	6105                	addi	sp,sp,32
                kernel_execve_ret(tf,current->kstack+KSTACKSIZE);
ffffffffc0200b8c:	2220006f          	j	ffffffffc0200dae <kernel_execve_ret>
            cprintf("Load address misaligned\n");
ffffffffc0200b90:	00006517          	auipc	a0,0x6
ffffffffc0200b94:	e7050513          	addi	a0,a0,-400 # ffffffffc0206a00 <commands+0x2b8>
ffffffffc0200b98:	b70d                	j	ffffffffc0200aba <exception_handler+0x50>
            cprintf("Load access fault\n");
ffffffffc0200b9a:	00006517          	auipc	a0,0x6
ffffffffc0200b9e:	e8650513          	addi	a0,a0,-378 # ffffffffc0206a20 <commands+0x2d8>
ffffffffc0200ba2:	decff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200ba6:	8522                	mv	a0,s0
ffffffffc0200ba8:	d05ff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200bac:	84aa                	mv	s1,a0
ffffffffc0200bae:	d131                	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200bb0:	8522                	mv	a0,s0
ffffffffc0200bb2:	c99ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bb6:	86a6                	mv	a3,s1
ffffffffc0200bb8:	00006617          	auipc	a2,0x6
ffffffffc0200bbc:	e8060613          	addi	a2,a2,-384 # ffffffffc0206a38 <commands+0x2f0>
ffffffffc0200bc0:	0ce00593          	li	a1,206
ffffffffc0200bc4:	00006517          	auipc	a0,0x6
ffffffffc0200bc8:	05c50513          	addi	a0,a0,92 # ffffffffc0206c20 <commands+0x4d8>
ffffffffc0200bcc:	8b9ff0ef          	jal	ra,ffffffffc0200484 <__panic>
            cprintf("Store/AMO access fault\n");
ffffffffc0200bd0:	00006517          	auipc	a0,0x6
ffffffffc0200bd4:	ea050513          	addi	a0,a0,-352 # ffffffffc0206a70 <commands+0x328>
ffffffffc0200bd8:	db6ff0ef          	jal	ra,ffffffffc020018e <cprintf>
            if ((ret = pgfault_handler(tf)) != 0) {
ffffffffc0200bdc:	8522                	mv	a0,s0
ffffffffc0200bde:	ccfff0ef          	jal	ra,ffffffffc02008ac <pgfault_handler>
ffffffffc0200be2:	84aa                	mv	s1,a0
ffffffffc0200be4:	f00507e3          	beqz	a0,ffffffffc0200af2 <exception_handler+0x88>
                print_trapframe(tf);
ffffffffc0200be8:	8522                	mv	a0,s0
ffffffffc0200bea:	c61ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200bee:	86a6                	mv	a3,s1
ffffffffc0200bf0:	00006617          	auipc	a2,0x6
ffffffffc0200bf4:	e4860613          	addi	a2,a2,-440 # ffffffffc0206a38 <commands+0x2f0>
ffffffffc0200bf8:	0d800593          	li	a1,216
ffffffffc0200bfc:	00006517          	auipc	a0,0x6
ffffffffc0200c00:	02450513          	addi	a0,a0,36 # ffffffffc0206c20 <commands+0x4d8>
ffffffffc0200c04:	881ff0ef          	jal	ra,ffffffffc0200484 <__panic>
}
ffffffffc0200c08:	6442                	ld	s0,16(sp)
ffffffffc0200c0a:	60e2                	ld	ra,24(sp)
ffffffffc0200c0c:	64a2                	ld	s1,8(sp)
ffffffffc0200c0e:	6105                	addi	sp,sp,32
            print_trapframe(tf);
ffffffffc0200c10:	c3bff06f          	j	ffffffffc020084a <print_trapframe>
            panic("AMO address misaligned\n");
ffffffffc0200c14:	00006617          	auipc	a2,0x6
ffffffffc0200c18:	e4460613          	addi	a2,a2,-444 # ffffffffc0206a58 <commands+0x310>
ffffffffc0200c1c:	0d200593          	li	a1,210
ffffffffc0200c20:	00006517          	auipc	a0,0x6
ffffffffc0200c24:	00050513          	mv	a0,a0
ffffffffc0200c28:	85dff0ef          	jal	ra,ffffffffc0200484 <__panic>
            print_trapframe(tf);
ffffffffc0200c2c:	c1fff06f          	j	ffffffffc020084a <print_trapframe>
                print_trapframe(tf);
ffffffffc0200c30:	8522                	mv	a0,s0
ffffffffc0200c32:	c19ff0ef          	jal	ra,ffffffffc020084a <print_trapframe>
                panic("handle pgfault failed. %e\n", ret);
ffffffffc0200c36:	86a6                	mv	a3,s1
ffffffffc0200c38:	00006617          	auipc	a2,0x6
ffffffffc0200c3c:	e0060613          	addi	a2,a2,-512 # ffffffffc0206a38 <commands+0x2f0>
ffffffffc0200c40:	0f200593          	li	a1,242
ffffffffc0200c44:	00006517          	auipc	a0,0x6
ffffffffc0200c48:	fdc50513          	addi	a0,a0,-36 # ffffffffc0206c20 <commands+0x4d8>
ffffffffc0200c4c:	839ff0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0200c50 <trap>:
 * trap - handles or dispatches an exception/interrupt. if and when trap() returns,
 * the code in kern/trap/trapentry.S restores the old CPU state saved in the
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void
trap(struct trapframe *tf) {
ffffffffc0200c50:	1101                	addi	sp,sp,-32
ffffffffc0200c52:	e822                	sd	s0,16(sp)
    // dispatch based on what type of trap occurred
//    cputs("some trap");
    if (current == NULL) {
ffffffffc0200c54:	000ac417          	auipc	s0,0xac
ffffffffc0200c58:	86c40413          	addi	s0,s0,-1940 # ffffffffc02ac4c0 <current>
ffffffffc0200c5c:	6018                	ld	a4,0(s0)
trap(struct trapframe *tf) {
ffffffffc0200c5e:	ec06                	sd	ra,24(sp)
ffffffffc0200c60:	e426                	sd	s1,8(sp)
ffffffffc0200c62:	e04a                	sd	s2,0(sp)
ffffffffc0200c64:	11853683          	ld	a3,280(a0)
    if (current == NULL) {
ffffffffc0200c68:	cf1d                	beqz	a4,ffffffffc0200ca6 <trap+0x56>
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c6a:	10053483          	ld	s1,256(a0)
        trap_dispatch(tf);
    } else {
        struct trapframe *otf = current->tf;
ffffffffc0200c6e:	0a073903          	ld	s2,160(a4)
        current->tf = tf;
ffffffffc0200c72:	f348                	sd	a0,160(a4)
    return (tf->status & SSTATUS_SPP) != 0;
ffffffffc0200c74:	1004f493          	andi	s1,s1,256
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200c78:	0206c463          	bltz	a3,ffffffffc0200ca0 <trap+0x50>
        exception_handler(tf);
ffffffffc0200c7c:	defff0ef          	jal	ra,ffffffffc0200a6a <exception_handler>

        bool in_kernel = trap_in_kernel(tf);

        trap_dispatch(tf);

        current->tf = otf;
ffffffffc0200c80:	601c                	ld	a5,0(s0)
ffffffffc0200c82:	0b27b023          	sd	s2,160(a5)
        if (!in_kernel) {
ffffffffc0200c86:	e499                	bnez	s1,ffffffffc0200c94 <trap+0x44>
            if (current->flags & PF_EXITING) {
ffffffffc0200c88:	0b07a703          	lw	a4,176(a5)
ffffffffc0200c8c:	8b05                	andi	a4,a4,1
ffffffffc0200c8e:	e339                	bnez	a4,ffffffffc0200cd4 <trap+0x84>
                do_exit(-E_KILLED);
            }
            if (current->need_resched) {
ffffffffc0200c90:	6f9c                	ld	a5,24(a5)
ffffffffc0200c92:	eb95                	bnez	a5,ffffffffc0200cc6 <trap+0x76>
                schedule();
            }
        }
    }
}
ffffffffc0200c94:	60e2                	ld	ra,24(sp)
ffffffffc0200c96:	6442                	ld	s0,16(sp)
ffffffffc0200c98:	64a2                	ld	s1,8(sp)
ffffffffc0200c9a:	6902                	ld	s2,0(sp)
ffffffffc0200c9c:	6105                	addi	sp,sp,32
ffffffffc0200c9e:	8082                	ret
        interrupt_handler(tf);
ffffffffc0200ca0:	d2dff0ef          	jal	ra,ffffffffc02009cc <interrupt_handler>
ffffffffc0200ca4:	bff1                	j	ffffffffc0200c80 <trap+0x30>
    if ((intptr_t)tf->cause < 0) {
ffffffffc0200ca6:	0006c963          	bltz	a3,ffffffffc0200cb8 <trap+0x68>
}
ffffffffc0200caa:	6442                	ld	s0,16(sp)
ffffffffc0200cac:	60e2                	ld	ra,24(sp)
ffffffffc0200cae:	64a2                	ld	s1,8(sp)
ffffffffc0200cb0:	6902                	ld	s2,0(sp)
ffffffffc0200cb2:	6105                	addi	sp,sp,32
        exception_handler(tf);
ffffffffc0200cb4:	db7ff06f          	j	ffffffffc0200a6a <exception_handler>
}
ffffffffc0200cb8:	6442                	ld	s0,16(sp)
ffffffffc0200cba:	60e2                	ld	ra,24(sp)
ffffffffc0200cbc:	64a2                	ld	s1,8(sp)
ffffffffc0200cbe:	6902                	ld	s2,0(sp)
ffffffffc0200cc0:	6105                	addi	sp,sp,32
        interrupt_handler(tf);
ffffffffc0200cc2:	d0bff06f          	j	ffffffffc02009cc <interrupt_handler>
}
ffffffffc0200cc6:	6442                	ld	s0,16(sp)
ffffffffc0200cc8:	60e2                	ld	ra,24(sp)
ffffffffc0200cca:	64a2                	ld	s1,8(sp)
ffffffffc0200ccc:	6902                	ld	s2,0(sp)
ffffffffc0200cce:	6105                	addi	sp,sp,32
                schedule();
ffffffffc0200cd0:	2fa0506f          	j	ffffffffc0205fca <schedule>
                do_exit(-E_KILLED);
ffffffffc0200cd4:	555d                	li	a0,-9
ffffffffc0200cd6:	6ee040ef          	jal	ra,ffffffffc02053c4 <do_exit>
ffffffffc0200cda:	601c                	ld	a5,0(s0)
ffffffffc0200cdc:	bf55                	j	ffffffffc0200c90 <trap+0x40>
	...

ffffffffc0200ce0 <__alltraps>:
    LOAD x2, 2*REGBYTES(sp)
    .endm

    .globl __alltraps
__alltraps:
    SAVE_ALL
ffffffffc0200ce0:	14011173          	csrrw	sp,sscratch,sp
ffffffffc0200ce4:	00011463          	bnez	sp,ffffffffc0200cec <__alltraps+0xc>
ffffffffc0200ce8:	14002173          	csrr	sp,sscratch
ffffffffc0200cec:	712d                	addi	sp,sp,-288
ffffffffc0200cee:	e002                	sd	zero,0(sp)
ffffffffc0200cf0:	e406                	sd	ra,8(sp)
ffffffffc0200cf2:	ec0e                	sd	gp,24(sp)
ffffffffc0200cf4:	f012                	sd	tp,32(sp)
ffffffffc0200cf6:	f416                	sd	t0,40(sp)
ffffffffc0200cf8:	f81a                	sd	t1,48(sp)
ffffffffc0200cfa:	fc1e                	sd	t2,56(sp)
ffffffffc0200cfc:	e0a2                	sd	s0,64(sp)
ffffffffc0200cfe:	e4a6                	sd	s1,72(sp)
ffffffffc0200d00:	e8aa                	sd	a0,80(sp)
ffffffffc0200d02:	ecae                	sd	a1,88(sp)
ffffffffc0200d04:	f0b2                	sd	a2,96(sp)
ffffffffc0200d06:	f4b6                	sd	a3,104(sp)
ffffffffc0200d08:	f8ba                	sd	a4,112(sp)
ffffffffc0200d0a:	fcbe                	sd	a5,120(sp)
ffffffffc0200d0c:	e142                	sd	a6,128(sp)
ffffffffc0200d0e:	e546                	sd	a7,136(sp)
ffffffffc0200d10:	e94a                	sd	s2,144(sp)
ffffffffc0200d12:	ed4e                	sd	s3,152(sp)
ffffffffc0200d14:	f152                	sd	s4,160(sp)
ffffffffc0200d16:	f556                	sd	s5,168(sp)
ffffffffc0200d18:	f95a                	sd	s6,176(sp)
ffffffffc0200d1a:	fd5e                	sd	s7,184(sp)
ffffffffc0200d1c:	e1e2                	sd	s8,192(sp)
ffffffffc0200d1e:	e5e6                	sd	s9,200(sp)
ffffffffc0200d20:	e9ea                	sd	s10,208(sp)
ffffffffc0200d22:	edee                	sd	s11,216(sp)
ffffffffc0200d24:	f1f2                	sd	t3,224(sp)
ffffffffc0200d26:	f5f6                	sd	t4,232(sp)
ffffffffc0200d28:	f9fa                	sd	t5,240(sp)
ffffffffc0200d2a:	fdfe                	sd	t6,248(sp)
ffffffffc0200d2c:	14001473          	csrrw	s0,sscratch,zero
ffffffffc0200d30:	100024f3          	csrr	s1,sstatus
ffffffffc0200d34:	14102973          	csrr	s2,sepc
ffffffffc0200d38:	143029f3          	csrr	s3,stval
ffffffffc0200d3c:	14202a73          	csrr	s4,scause
ffffffffc0200d40:	e822                	sd	s0,16(sp)
ffffffffc0200d42:	e226                	sd	s1,256(sp)
ffffffffc0200d44:	e64a                	sd	s2,264(sp)
ffffffffc0200d46:	ea4e                	sd	s3,272(sp)
ffffffffc0200d48:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200d4a:	850a                	mv	a0,sp
    jal trap
ffffffffc0200d4c:	f05ff0ef          	jal	ra,ffffffffc0200c50 <trap>

ffffffffc0200d50 <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc0200d50:	6492                	ld	s1,256(sp)
ffffffffc0200d52:	6932                	ld	s2,264(sp)
ffffffffc0200d54:	1004f413          	andi	s0,s1,256
ffffffffc0200d58:	e401                	bnez	s0,ffffffffc0200d60 <__trapret+0x10>
ffffffffc0200d5a:	1200                	addi	s0,sp,288
ffffffffc0200d5c:	14041073          	csrw	sscratch,s0
ffffffffc0200d60:	10049073          	csrw	sstatus,s1
ffffffffc0200d64:	14191073          	csrw	sepc,s2
ffffffffc0200d68:	60a2                	ld	ra,8(sp)
ffffffffc0200d6a:	61e2                	ld	gp,24(sp)
ffffffffc0200d6c:	7202                	ld	tp,32(sp)
ffffffffc0200d6e:	72a2                	ld	t0,40(sp)
ffffffffc0200d70:	7342                	ld	t1,48(sp)
ffffffffc0200d72:	73e2                	ld	t2,56(sp)
ffffffffc0200d74:	6406                	ld	s0,64(sp)
ffffffffc0200d76:	64a6                	ld	s1,72(sp)
ffffffffc0200d78:	6546                	ld	a0,80(sp)
ffffffffc0200d7a:	65e6                	ld	a1,88(sp)
ffffffffc0200d7c:	7606                	ld	a2,96(sp)
ffffffffc0200d7e:	76a6                	ld	a3,104(sp)
ffffffffc0200d80:	7746                	ld	a4,112(sp)
ffffffffc0200d82:	77e6                	ld	a5,120(sp)
ffffffffc0200d84:	680a                	ld	a6,128(sp)
ffffffffc0200d86:	68aa                	ld	a7,136(sp)
ffffffffc0200d88:	694a                	ld	s2,144(sp)
ffffffffc0200d8a:	69ea                	ld	s3,152(sp)
ffffffffc0200d8c:	7a0a                	ld	s4,160(sp)
ffffffffc0200d8e:	7aaa                	ld	s5,168(sp)
ffffffffc0200d90:	7b4a                	ld	s6,176(sp)
ffffffffc0200d92:	7bea                	ld	s7,184(sp)
ffffffffc0200d94:	6c0e                	ld	s8,192(sp)
ffffffffc0200d96:	6cae                	ld	s9,200(sp)
ffffffffc0200d98:	6d4e                	ld	s10,208(sp)
ffffffffc0200d9a:	6dee                	ld	s11,216(sp)
ffffffffc0200d9c:	7e0e                	ld	t3,224(sp)
ffffffffc0200d9e:	7eae                	ld	t4,232(sp)
ffffffffc0200da0:	7f4e                	ld	t5,240(sp)
ffffffffc0200da2:	7fee                	ld	t6,248(sp)
ffffffffc0200da4:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200da6:	10200073          	sret

ffffffffc0200daa <forkrets>:
 
    .globl forkrets
forkrets:
    # set stack to this new process's trapframe
    move sp, a0
ffffffffc0200daa:	812a                	mv	sp,a0
    j __trapret
ffffffffc0200dac:	b755                	j	ffffffffc0200d50 <__trapret>

ffffffffc0200dae <kernel_execve_ret>:

    .global kernel_execve_ret
kernel_execve_ret:
    // adjust sp to beneath kstacktop of current process
    addi a1, a1, -36*REGBYTES
ffffffffc0200dae:	ee058593          	addi	a1,a1,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x76a0>

    // copy from previous trapframe to new trapframe
    LOAD s1, 35*REGBYTES(a0)
ffffffffc0200db2:	11853483          	ld	s1,280(a0)
    STORE s1, 35*REGBYTES(a1)
ffffffffc0200db6:	1095bc23          	sd	s1,280(a1)
    LOAD s1, 34*REGBYTES(a0)
ffffffffc0200dba:	11053483          	ld	s1,272(a0)
    STORE s1, 34*REGBYTES(a1)
ffffffffc0200dbe:	1095b823          	sd	s1,272(a1)
    LOAD s1, 33*REGBYTES(a0)
ffffffffc0200dc2:	10853483          	ld	s1,264(a0)
    STORE s1, 33*REGBYTES(a1)
ffffffffc0200dc6:	1095b423          	sd	s1,264(a1)
    LOAD s1, 32*REGBYTES(a0)
ffffffffc0200dca:	10053483          	ld	s1,256(a0)
    STORE s1, 32*REGBYTES(a1)
ffffffffc0200dce:	1095b023          	sd	s1,256(a1)
    LOAD s1, 31*REGBYTES(a0)
ffffffffc0200dd2:	7d64                	ld	s1,248(a0)
    STORE s1, 31*REGBYTES(a1)
ffffffffc0200dd4:	fde4                	sd	s1,248(a1)
    LOAD s1, 30*REGBYTES(a0)
ffffffffc0200dd6:	7964                	ld	s1,240(a0)
    STORE s1, 30*REGBYTES(a1)
ffffffffc0200dd8:	f9e4                	sd	s1,240(a1)
    LOAD s1, 29*REGBYTES(a0)
ffffffffc0200dda:	7564                	ld	s1,232(a0)
    STORE s1, 29*REGBYTES(a1)
ffffffffc0200ddc:	f5e4                	sd	s1,232(a1)
    LOAD s1, 28*REGBYTES(a0)
ffffffffc0200dde:	7164                	ld	s1,224(a0)
    STORE s1, 28*REGBYTES(a1)
ffffffffc0200de0:	f1e4                	sd	s1,224(a1)
    LOAD s1, 27*REGBYTES(a0)
ffffffffc0200de2:	6d64                	ld	s1,216(a0)
    STORE s1, 27*REGBYTES(a1)
ffffffffc0200de4:	ede4                	sd	s1,216(a1)
    LOAD s1, 26*REGBYTES(a0)
ffffffffc0200de6:	6964                	ld	s1,208(a0)
    STORE s1, 26*REGBYTES(a1)
ffffffffc0200de8:	e9e4                	sd	s1,208(a1)
    LOAD s1, 25*REGBYTES(a0)
ffffffffc0200dea:	6564                	ld	s1,200(a0)
    STORE s1, 25*REGBYTES(a1)
ffffffffc0200dec:	e5e4                	sd	s1,200(a1)
    LOAD s1, 24*REGBYTES(a0)
ffffffffc0200dee:	6164                	ld	s1,192(a0)
    STORE s1, 24*REGBYTES(a1)
ffffffffc0200df0:	e1e4                	sd	s1,192(a1)
    LOAD s1, 23*REGBYTES(a0)
ffffffffc0200df2:	7d44                	ld	s1,184(a0)
    STORE s1, 23*REGBYTES(a1)
ffffffffc0200df4:	fdc4                	sd	s1,184(a1)
    LOAD s1, 22*REGBYTES(a0)
ffffffffc0200df6:	7944                	ld	s1,176(a0)
    STORE s1, 22*REGBYTES(a1)
ffffffffc0200df8:	f9c4                	sd	s1,176(a1)
    LOAD s1, 21*REGBYTES(a0)
ffffffffc0200dfa:	7544                	ld	s1,168(a0)
    STORE s1, 21*REGBYTES(a1)
ffffffffc0200dfc:	f5c4                	sd	s1,168(a1)
    LOAD s1, 20*REGBYTES(a0)
ffffffffc0200dfe:	7144                	ld	s1,160(a0)
    STORE s1, 20*REGBYTES(a1)
ffffffffc0200e00:	f1c4                	sd	s1,160(a1)
    LOAD s1, 19*REGBYTES(a0)
ffffffffc0200e02:	6d44                	ld	s1,152(a0)
    STORE s1, 19*REGBYTES(a1)
ffffffffc0200e04:	edc4                	sd	s1,152(a1)
    LOAD s1, 18*REGBYTES(a0)
ffffffffc0200e06:	6944                	ld	s1,144(a0)
    STORE s1, 18*REGBYTES(a1)
ffffffffc0200e08:	e9c4                	sd	s1,144(a1)
    LOAD s1, 17*REGBYTES(a0)
ffffffffc0200e0a:	6544                	ld	s1,136(a0)
    STORE s1, 17*REGBYTES(a1)
ffffffffc0200e0c:	e5c4                	sd	s1,136(a1)
    LOAD s1, 16*REGBYTES(a0)
ffffffffc0200e0e:	6144                	ld	s1,128(a0)
    STORE s1, 16*REGBYTES(a1)
ffffffffc0200e10:	e1c4                	sd	s1,128(a1)
    LOAD s1, 15*REGBYTES(a0)
ffffffffc0200e12:	7d24                	ld	s1,120(a0)
    STORE s1, 15*REGBYTES(a1)
ffffffffc0200e14:	fda4                	sd	s1,120(a1)
    LOAD s1, 14*REGBYTES(a0)
ffffffffc0200e16:	7924                	ld	s1,112(a0)
    STORE s1, 14*REGBYTES(a1)
ffffffffc0200e18:	f9a4                	sd	s1,112(a1)
    LOAD s1, 13*REGBYTES(a0)
ffffffffc0200e1a:	7524                	ld	s1,104(a0)
    STORE s1, 13*REGBYTES(a1)
ffffffffc0200e1c:	f5a4                	sd	s1,104(a1)
    LOAD s1, 12*REGBYTES(a0)
ffffffffc0200e1e:	7124                	ld	s1,96(a0)
    STORE s1, 12*REGBYTES(a1)
ffffffffc0200e20:	f1a4                	sd	s1,96(a1)
    LOAD s1, 11*REGBYTES(a0)
ffffffffc0200e22:	6d24                	ld	s1,88(a0)
    STORE s1, 11*REGBYTES(a1)
ffffffffc0200e24:	eda4                	sd	s1,88(a1)
    LOAD s1, 10*REGBYTES(a0)
ffffffffc0200e26:	6924                	ld	s1,80(a0)
    STORE s1, 10*REGBYTES(a1)
ffffffffc0200e28:	e9a4                	sd	s1,80(a1)
    LOAD s1, 9*REGBYTES(a0)
ffffffffc0200e2a:	6524                	ld	s1,72(a0)
    STORE s1, 9*REGBYTES(a1)
ffffffffc0200e2c:	e5a4                	sd	s1,72(a1)
    LOAD s1, 8*REGBYTES(a0)
ffffffffc0200e2e:	6124                	ld	s1,64(a0)
    STORE s1, 8*REGBYTES(a1)
ffffffffc0200e30:	e1a4                	sd	s1,64(a1)
    LOAD s1, 7*REGBYTES(a0)
ffffffffc0200e32:	7d04                	ld	s1,56(a0)
    STORE s1, 7*REGBYTES(a1)
ffffffffc0200e34:	fd84                	sd	s1,56(a1)
    LOAD s1, 6*REGBYTES(a0)
ffffffffc0200e36:	7904                	ld	s1,48(a0)
    STORE s1, 6*REGBYTES(a1)
ffffffffc0200e38:	f984                	sd	s1,48(a1)
    LOAD s1, 5*REGBYTES(a0)
ffffffffc0200e3a:	7504                	ld	s1,40(a0)
    STORE s1, 5*REGBYTES(a1)
ffffffffc0200e3c:	f584                	sd	s1,40(a1)
    LOAD s1, 4*REGBYTES(a0)
ffffffffc0200e3e:	7104                	ld	s1,32(a0)
    STORE s1, 4*REGBYTES(a1)
ffffffffc0200e40:	f184                	sd	s1,32(a1)
    LOAD s1, 3*REGBYTES(a0)
ffffffffc0200e42:	6d04                	ld	s1,24(a0)
    STORE s1, 3*REGBYTES(a1)
ffffffffc0200e44:	ed84                	sd	s1,24(a1)
    LOAD s1, 2*REGBYTES(a0)
ffffffffc0200e46:	6904                	ld	s1,16(a0)
    STORE s1, 2*REGBYTES(a1)
ffffffffc0200e48:	e984                	sd	s1,16(a1)
    LOAD s1, 1*REGBYTES(a0)
ffffffffc0200e4a:	6504                	ld	s1,8(a0)
    STORE s1, 1*REGBYTES(a1)
ffffffffc0200e4c:	e584                	sd	s1,8(a1)
    LOAD s1, 0*REGBYTES(a0)
ffffffffc0200e4e:	6104                	ld	s1,0(a0)
    STORE s1, 0*REGBYTES(a1)
ffffffffc0200e50:	e184                	sd	s1,0(a1)

    // acutually adjust sp
    move sp, a1
ffffffffc0200e52:	812e                	mv	sp,a1
ffffffffc0200e54:	bdf5                	j	ffffffffc0200d50 <__trapret>

ffffffffc0200e56 <default_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200e56:	000ab797          	auipc	a5,0xab
ffffffffc0200e5a:	69278793          	addi	a5,a5,1682 # ffffffffc02ac4e8 <free_area>
ffffffffc0200e5e:	e79c                	sd	a5,8(a5)
ffffffffc0200e60:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
default_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200e62:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200e66:	8082                	ret

ffffffffc0200e68 <default_nr_free_pages>:
}

static size_t
default_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200e68:	000ab517          	auipc	a0,0xab
ffffffffc0200e6c:	69056503          	lwu	a0,1680(a0) # ffffffffc02ac4f8 <free_area+0x10>
ffffffffc0200e70:	8082                	ret

ffffffffc0200e72 <default_check>:
}

// LAB2: below code is used to check the first fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
default_check(void) {
ffffffffc0200e72:	715d                	addi	sp,sp,-80
ffffffffc0200e74:	f84a                	sd	s2,48(sp)
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc0200e76:	000ab917          	auipc	s2,0xab
ffffffffc0200e7a:	67290913          	addi	s2,s2,1650 # ffffffffc02ac4e8 <free_area>
ffffffffc0200e7e:	00893783          	ld	a5,8(s2)
ffffffffc0200e82:	e486                	sd	ra,72(sp)
ffffffffc0200e84:	e0a2                	sd	s0,64(sp)
ffffffffc0200e86:	fc26                	sd	s1,56(sp)
ffffffffc0200e88:	f44e                	sd	s3,40(sp)
ffffffffc0200e8a:	f052                	sd	s4,32(sp)
ffffffffc0200e8c:	ec56                	sd	s5,24(sp)
ffffffffc0200e8e:	e85a                	sd	s6,16(sp)
ffffffffc0200e90:	e45e                	sd	s7,8(sp)
ffffffffc0200e92:	e062                	sd	s8,0(sp)
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200e94:	31278463          	beq	a5,s2,ffffffffc020119c <default_check+0x32a>
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200e98:	ff07b703          	ld	a4,-16(a5)
ffffffffc0200e9c:	8305                	srli	a4,a4,0x1
ffffffffc0200e9e:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200ea0:	30070263          	beqz	a4,ffffffffc02011a4 <default_check+0x332>
    int count = 0, total = 0;
ffffffffc0200ea4:	4401                	li	s0,0
ffffffffc0200ea6:	4481                	li	s1,0
ffffffffc0200ea8:	a031                	j	ffffffffc0200eb4 <default_check+0x42>
ffffffffc0200eaa:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0200eae:	8b09                	andi	a4,a4,2
ffffffffc0200eb0:	2e070a63          	beqz	a4,ffffffffc02011a4 <default_check+0x332>
        count ++, total += p->property;
ffffffffc0200eb4:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200eb8:	679c                	ld	a5,8(a5)
ffffffffc0200eba:	2485                	addiw	s1,s1,1
ffffffffc0200ebc:	9c39                	addw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200ebe:	ff2796e3          	bne	a5,s2,ffffffffc0200eaa <default_check+0x38>
ffffffffc0200ec2:	89a2                	mv	s3,s0
    }
    assert(total == nr_free_pages());
ffffffffc0200ec4:	05c010ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc0200ec8:	73351e63          	bne	a0,s3,ffffffffc0201604 <default_check+0x792>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200ecc:	4505                	li	a0,1
ffffffffc0200ece:	785000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ed2:	8a2a                	mv	s4,a0
ffffffffc0200ed4:	46050863          	beqz	a0,ffffffffc0201344 <default_check+0x4d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200ed8:	4505                	li	a0,1
ffffffffc0200eda:	779000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ede:	89aa                	mv	s3,a0
ffffffffc0200ee0:	74050263          	beqz	a0,ffffffffc0201624 <default_check+0x7b2>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200ee4:	4505                	li	a0,1
ffffffffc0200ee6:	76d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200eea:	8aaa                	mv	s5,a0
ffffffffc0200eec:	4c050c63          	beqz	a0,ffffffffc02013c4 <default_check+0x552>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200ef0:	2d3a0a63          	beq	s4,s3,ffffffffc02011c4 <default_check+0x352>
ffffffffc0200ef4:	2caa0863          	beq	s4,a0,ffffffffc02011c4 <default_check+0x352>
ffffffffc0200ef8:	2ca98663          	beq	s3,a0,ffffffffc02011c4 <default_check+0x352>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200efc:	000a2783          	lw	a5,0(s4)
ffffffffc0200f00:	2e079263          	bnez	a5,ffffffffc02011e4 <default_check+0x372>
ffffffffc0200f04:	0009a783          	lw	a5,0(s3)
ffffffffc0200f08:	2c079e63          	bnez	a5,ffffffffc02011e4 <default_check+0x372>
ffffffffc0200f0c:	411c                	lw	a5,0(a0)
ffffffffc0200f0e:	2c079b63          	bnez	a5,ffffffffc02011e4 <default_check+0x372>
extern size_t npage;
extern uint_t va_pa_offset;

static inline ppn_t
page2ppn(struct Page *page) {
    return page - pages + nbase;
ffffffffc0200f12:	000ab797          	auipc	a5,0xab
ffffffffc0200f16:	60678793          	addi	a5,a5,1542 # ffffffffc02ac518 <pages>
ffffffffc0200f1a:	639c                	ld	a5,0(a5)
ffffffffc0200f1c:	00008717          	auipc	a4,0x8
ffffffffc0200f20:	dbc70713          	addi	a4,a4,-580 # ffffffffc0208cd8 <nbase>
ffffffffc0200f24:	6310                	ld	a2,0(a4)
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200f26:	000ab717          	auipc	a4,0xab
ffffffffc0200f2a:	58270713          	addi	a4,a4,1410 # ffffffffc02ac4a8 <npage>
ffffffffc0200f2e:	6314                	ld	a3,0(a4)
ffffffffc0200f30:	40fa0733          	sub	a4,s4,a5
ffffffffc0200f34:	8719                	srai	a4,a4,0x6
ffffffffc0200f36:	9732                	add	a4,a4,a2
ffffffffc0200f38:	06b2                	slli	a3,a3,0xc
}

static inline uintptr_t
page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f3a:	0732                	slli	a4,a4,0xc
ffffffffc0200f3c:	2cd77463          	bleu	a3,a4,ffffffffc0201204 <default_check+0x392>
    return page - pages + nbase;
ffffffffc0200f40:	40f98733          	sub	a4,s3,a5
ffffffffc0200f44:	8719                	srai	a4,a4,0x6
ffffffffc0200f46:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f48:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200f4a:	4ed77d63          	bleu	a3,a4,ffffffffc0201444 <default_check+0x5d2>
    return page - pages + nbase;
ffffffffc0200f4e:	40f507b3          	sub	a5,a0,a5
ffffffffc0200f52:	8799                	srai	a5,a5,0x6
ffffffffc0200f54:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200f56:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200f58:	34d7f663          	bleu	a3,a5,ffffffffc02012a4 <default_check+0x432>
    assert(alloc_page() == NULL);
ffffffffc0200f5c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200f5e:	00093c03          	ld	s8,0(s2)
ffffffffc0200f62:	00893b83          	ld	s7,8(s2)
    unsigned int nr_free_store = nr_free;
ffffffffc0200f66:	01092b03          	lw	s6,16(s2)
    elm->prev = elm->next = elm;
ffffffffc0200f6a:	000ab797          	auipc	a5,0xab
ffffffffc0200f6e:	5927b323          	sd	s2,1414(a5) # ffffffffc02ac4f0 <free_area+0x8>
ffffffffc0200f72:	000ab797          	auipc	a5,0xab
ffffffffc0200f76:	5727bb23          	sd	s2,1398(a5) # ffffffffc02ac4e8 <free_area>
    nr_free = 0;
ffffffffc0200f7a:	000ab797          	auipc	a5,0xab
ffffffffc0200f7e:	5607af23          	sw	zero,1406(a5) # ffffffffc02ac4f8 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200f82:	6d1000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200f86:	2e051f63          	bnez	a0,ffffffffc0201284 <default_check+0x412>
    free_page(p0);
ffffffffc0200f8a:	4585                	li	a1,1
ffffffffc0200f8c:	8552                	mv	a0,s4
ffffffffc0200f8e:	74d000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p1);
ffffffffc0200f92:	4585                	li	a1,1
ffffffffc0200f94:	854e                	mv	a0,s3
ffffffffc0200f96:	745000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p2);
ffffffffc0200f9a:	4585                	li	a1,1
ffffffffc0200f9c:	8556                	mv	a0,s5
ffffffffc0200f9e:	73d000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert(nr_free == 3);
ffffffffc0200fa2:	01092703          	lw	a4,16(s2)
ffffffffc0200fa6:	478d                	li	a5,3
ffffffffc0200fa8:	2af71e63          	bne	a4,a5,ffffffffc0201264 <default_check+0x3f2>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200fac:	4505                	li	a0,1
ffffffffc0200fae:	6a5000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fb2:	89aa                	mv	s3,a0
ffffffffc0200fb4:	28050863          	beqz	a0,ffffffffc0201244 <default_check+0x3d2>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200fb8:	4505                	li	a0,1
ffffffffc0200fba:	699000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fbe:	8aaa                	mv	s5,a0
ffffffffc0200fc0:	3e050263          	beqz	a0,ffffffffc02013a4 <default_check+0x532>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200fc4:	4505                	li	a0,1
ffffffffc0200fc6:	68d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fca:	8a2a                	mv	s4,a0
ffffffffc0200fcc:	3a050c63          	beqz	a0,ffffffffc0201384 <default_check+0x512>
    assert(alloc_page() == NULL);
ffffffffc0200fd0:	4505                	li	a0,1
ffffffffc0200fd2:	681000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200fd6:	38051763          	bnez	a0,ffffffffc0201364 <default_check+0x4f2>
    free_page(p0);
ffffffffc0200fda:	4585                	li	a1,1
ffffffffc0200fdc:	854e                	mv	a0,s3
ffffffffc0200fde:	6fd000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200fe2:	00893783          	ld	a5,8(s2)
ffffffffc0200fe6:	23278f63          	beq	a5,s2,ffffffffc0201224 <default_check+0x3b2>
    assert((p = alloc_page()) == p0);
ffffffffc0200fea:	4505                	li	a0,1
ffffffffc0200fec:	667000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ff0:	32a99a63          	bne	s3,a0,ffffffffc0201324 <default_check+0x4b2>
    assert(alloc_page() == NULL);
ffffffffc0200ff4:	4505                	li	a0,1
ffffffffc0200ff6:	65d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0200ffa:	30051563          	bnez	a0,ffffffffc0201304 <default_check+0x492>
    assert(nr_free == 0);
ffffffffc0200ffe:	01092783          	lw	a5,16(s2)
ffffffffc0201002:	2e079163          	bnez	a5,ffffffffc02012e4 <default_check+0x472>
    free_page(p);
ffffffffc0201006:	854e                	mv	a0,s3
ffffffffc0201008:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc020100a:	000ab797          	auipc	a5,0xab
ffffffffc020100e:	4d87bf23          	sd	s8,1246(a5) # ffffffffc02ac4e8 <free_area>
ffffffffc0201012:	000ab797          	auipc	a5,0xab
ffffffffc0201016:	4d77bf23          	sd	s7,1246(a5) # ffffffffc02ac4f0 <free_area+0x8>
    nr_free = nr_free_store;
ffffffffc020101a:	000ab797          	auipc	a5,0xab
ffffffffc020101e:	4d67af23          	sw	s6,1246(a5) # ffffffffc02ac4f8 <free_area+0x10>
    free_page(p);
ffffffffc0201022:	6b9000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p1);
ffffffffc0201026:	4585                	li	a1,1
ffffffffc0201028:	8556                	mv	a0,s5
ffffffffc020102a:	6b1000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p2);
ffffffffc020102e:	4585                	li	a1,1
ffffffffc0201030:	8552                	mv	a0,s4
ffffffffc0201032:	6a9000ef          	jal	ra,ffffffffc0201eda <free_pages>

    basic_check();

    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0201036:	4515                	li	a0,5
ffffffffc0201038:	61b000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020103c:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020103e:	28050363          	beqz	a0,ffffffffc02012c4 <default_check+0x452>
ffffffffc0201042:	651c                	ld	a5,8(a0)
ffffffffc0201044:	8385                	srli	a5,a5,0x1
ffffffffc0201046:	8b85                	andi	a5,a5,1
    assert(!PageProperty(p0));
ffffffffc0201048:	54079e63          	bnez	a5,ffffffffc02015a4 <default_check+0x732>

    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc020104c:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc020104e:	00093b03          	ld	s6,0(s2)
ffffffffc0201052:	00893a83          	ld	s5,8(s2)
ffffffffc0201056:	000ab797          	auipc	a5,0xab
ffffffffc020105a:	4927b923          	sd	s2,1170(a5) # ffffffffc02ac4e8 <free_area>
ffffffffc020105e:	000ab797          	auipc	a5,0xab
ffffffffc0201062:	4927b923          	sd	s2,1170(a5) # ffffffffc02ac4f0 <free_area+0x8>
    assert(alloc_page() == NULL);
ffffffffc0201066:	5ed000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020106a:	50051d63          	bnez	a0,ffffffffc0201584 <default_check+0x712>

    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    free_pages(p0 + 2, 3);
ffffffffc020106e:	08098a13          	addi	s4,s3,128
ffffffffc0201072:	8552                	mv	a0,s4
ffffffffc0201074:	458d                	li	a1,3
    unsigned int nr_free_store = nr_free;
ffffffffc0201076:	01092b83          	lw	s7,16(s2)
    nr_free = 0;
ffffffffc020107a:	000ab797          	auipc	a5,0xab
ffffffffc020107e:	4607af23          	sw	zero,1150(a5) # ffffffffc02ac4f8 <free_area+0x10>
    free_pages(p0 + 2, 3);
ffffffffc0201082:	659000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0201086:	4511                	li	a0,4
ffffffffc0201088:	5cb000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020108c:	4c051c63          	bnez	a0,ffffffffc0201564 <default_check+0x6f2>
ffffffffc0201090:	0889b783          	ld	a5,136(s3)
ffffffffc0201094:	8385                	srli	a5,a5,0x1
ffffffffc0201096:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201098:	4a078663          	beqz	a5,ffffffffc0201544 <default_check+0x6d2>
ffffffffc020109c:	0909a703          	lw	a4,144(s3)
ffffffffc02010a0:	478d                	li	a5,3
ffffffffc02010a2:	4af71163          	bne	a4,a5,ffffffffc0201544 <default_check+0x6d2>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc02010a6:	450d                	li	a0,3
ffffffffc02010a8:	5ab000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02010ac:	8c2a                	mv	s8,a0
ffffffffc02010ae:	46050b63          	beqz	a0,ffffffffc0201524 <default_check+0x6b2>
    assert(alloc_page() == NULL);
ffffffffc02010b2:	4505                	li	a0,1
ffffffffc02010b4:	59f000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02010b8:	44051663          	bnez	a0,ffffffffc0201504 <default_check+0x692>
    assert(p0 + 2 == p1);
ffffffffc02010bc:	438a1463          	bne	s4,s8,ffffffffc02014e4 <default_check+0x672>

    p2 = p0 + 1;
    free_page(p0);
ffffffffc02010c0:	4585                	li	a1,1
ffffffffc02010c2:	854e                	mv	a0,s3
ffffffffc02010c4:	617000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_pages(p1, 3);
ffffffffc02010c8:	458d                	li	a1,3
ffffffffc02010ca:	8552                	mv	a0,s4
ffffffffc02010cc:	60f000ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc02010d0:	0089b783          	ld	a5,8(s3)
    p2 = p0 + 1;
ffffffffc02010d4:	04098c13          	addi	s8,s3,64
ffffffffc02010d8:	8385                	srli	a5,a5,0x1
ffffffffc02010da:	8b85                	andi	a5,a5,1
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02010dc:	3e078463          	beqz	a5,ffffffffc02014c4 <default_check+0x652>
ffffffffc02010e0:	0109a703          	lw	a4,16(s3)
ffffffffc02010e4:	4785                	li	a5,1
ffffffffc02010e6:	3cf71f63          	bne	a4,a5,ffffffffc02014c4 <default_check+0x652>
ffffffffc02010ea:	008a3783          	ld	a5,8(s4)
ffffffffc02010ee:	8385                	srli	a5,a5,0x1
ffffffffc02010f0:	8b85                	andi	a5,a5,1
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02010f2:	3a078963          	beqz	a5,ffffffffc02014a4 <default_check+0x632>
ffffffffc02010f6:	010a2703          	lw	a4,16(s4)
ffffffffc02010fa:	478d                	li	a5,3
ffffffffc02010fc:	3af71463          	bne	a4,a5,ffffffffc02014a4 <default_check+0x632>

    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201100:	4505                	li	a0,1
ffffffffc0201102:	551000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0201106:	36a99f63          	bne	s3,a0,ffffffffc0201484 <default_check+0x612>
    free_page(p0);
ffffffffc020110a:	4585                	li	a1,1
ffffffffc020110c:	5cf000ef          	jal	ra,ffffffffc0201eda <free_pages>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201110:	4509                	li	a0,2
ffffffffc0201112:	541000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0201116:	34aa1763          	bne	s4,a0,ffffffffc0201464 <default_check+0x5f2>

    free_pages(p0, 2);
ffffffffc020111a:	4589                	li	a1,2
ffffffffc020111c:	5bf000ef          	jal	ra,ffffffffc0201eda <free_pages>
    free_page(p2);
ffffffffc0201120:	4585                	li	a1,1
ffffffffc0201122:	8562                	mv	a0,s8
ffffffffc0201124:	5b7000ef          	jal	ra,ffffffffc0201eda <free_pages>

    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0201128:	4515                	li	a0,5
ffffffffc020112a:	529000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020112e:	89aa                	mv	s3,a0
ffffffffc0201130:	48050a63          	beqz	a0,ffffffffc02015c4 <default_check+0x752>
    assert(alloc_page() == NULL);
ffffffffc0201134:	4505                	li	a0,1
ffffffffc0201136:	51d000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020113a:	2e051563          	bnez	a0,ffffffffc0201424 <default_check+0x5b2>

    assert(nr_free == 0);
ffffffffc020113e:	01092783          	lw	a5,16(s2)
ffffffffc0201142:	2c079163          	bnez	a5,ffffffffc0201404 <default_check+0x592>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0201146:	4595                	li	a1,5
ffffffffc0201148:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020114a:	000ab797          	auipc	a5,0xab
ffffffffc020114e:	3b77a723          	sw	s7,942(a5) # ffffffffc02ac4f8 <free_area+0x10>
    free_list = free_list_store;
ffffffffc0201152:	000ab797          	auipc	a5,0xab
ffffffffc0201156:	3967bb23          	sd	s6,918(a5) # ffffffffc02ac4e8 <free_area>
ffffffffc020115a:	000ab797          	auipc	a5,0xab
ffffffffc020115e:	3957bb23          	sd	s5,918(a5) # ffffffffc02ac4f0 <free_area+0x8>
    free_pages(p0, 5);
ffffffffc0201162:	579000ef          	jal	ra,ffffffffc0201eda <free_pages>
    return listelm->next;
ffffffffc0201166:	00893783          	ld	a5,8(s2)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020116a:	01278963          	beq	a5,s2,ffffffffc020117c <default_check+0x30a>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc020116e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201172:	679c                	ld	a5,8(a5)
ffffffffc0201174:	34fd                	addiw	s1,s1,-1
ffffffffc0201176:	9c19                	subw	s0,s0,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201178:	ff279be3          	bne	a5,s2,ffffffffc020116e <default_check+0x2fc>
    }
    assert(count == 0);
ffffffffc020117c:	26049463          	bnez	s1,ffffffffc02013e4 <default_check+0x572>
    assert(total == 0);
ffffffffc0201180:	46041263          	bnez	s0,ffffffffc02015e4 <default_check+0x772>
}
ffffffffc0201184:	60a6                	ld	ra,72(sp)
ffffffffc0201186:	6406                	ld	s0,64(sp)
ffffffffc0201188:	74e2                	ld	s1,56(sp)
ffffffffc020118a:	7942                	ld	s2,48(sp)
ffffffffc020118c:	79a2                	ld	s3,40(sp)
ffffffffc020118e:	7a02                	ld	s4,32(sp)
ffffffffc0201190:	6ae2                	ld	s5,24(sp)
ffffffffc0201192:	6b42                	ld	s6,16(sp)
ffffffffc0201194:	6ba2                	ld	s7,8(sp)
ffffffffc0201196:	6c02                	ld	s8,0(sp)
ffffffffc0201198:	6161                	addi	sp,sp,80
ffffffffc020119a:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc020119c:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc020119e:	4401                	li	s0,0
ffffffffc02011a0:	4481                	li	s1,0
ffffffffc02011a2:	b30d                	j	ffffffffc0200ec4 <default_check+0x52>
        assert(PageProperty(p));
ffffffffc02011a4:	00006697          	auipc	a3,0x6
ffffffffc02011a8:	e1c68693          	addi	a3,a3,-484 # ffffffffc0206fc0 <commands+0x878>
ffffffffc02011ac:	00006617          	auipc	a2,0x6
ffffffffc02011b0:	a5c60613          	addi	a2,a2,-1444 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02011b4:	0f000593          	li	a1,240
ffffffffc02011b8:	00006517          	auipc	a0,0x6
ffffffffc02011bc:	e1850513          	addi	a0,a0,-488 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02011c0:	ac4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02011c4:	00006697          	auipc	a3,0x6
ffffffffc02011c8:	ea468693          	addi	a3,a3,-348 # ffffffffc0207068 <commands+0x920>
ffffffffc02011cc:	00006617          	auipc	a2,0x6
ffffffffc02011d0:	a3c60613          	addi	a2,a2,-1476 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02011d4:	0bd00593          	li	a1,189
ffffffffc02011d8:	00006517          	auipc	a0,0x6
ffffffffc02011dc:	df850513          	addi	a0,a0,-520 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02011e0:	aa4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02011e4:	00006697          	auipc	a3,0x6
ffffffffc02011e8:	eac68693          	addi	a3,a3,-340 # ffffffffc0207090 <commands+0x948>
ffffffffc02011ec:	00006617          	auipc	a2,0x6
ffffffffc02011f0:	a1c60613          	addi	a2,a2,-1508 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02011f4:	0be00593          	li	a1,190
ffffffffc02011f8:	00006517          	auipc	a0,0x6
ffffffffc02011fc:	dd850513          	addi	a0,a0,-552 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201200:	a84ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0201204:	00006697          	auipc	a3,0x6
ffffffffc0201208:	ecc68693          	addi	a3,a3,-308 # ffffffffc02070d0 <commands+0x988>
ffffffffc020120c:	00006617          	auipc	a2,0x6
ffffffffc0201210:	9fc60613          	addi	a2,a2,-1540 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201214:	0c000593          	li	a1,192
ffffffffc0201218:	00006517          	auipc	a0,0x6
ffffffffc020121c:	db850513          	addi	a0,a0,-584 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201220:	a64ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0201224:	00006697          	auipc	a3,0x6
ffffffffc0201228:	f3468693          	addi	a3,a3,-204 # ffffffffc0207158 <commands+0xa10>
ffffffffc020122c:	00006617          	auipc	a2,0x6
ffffffffc0201230:	9dc60613          	addi	a2,a2,-1572 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201234:	0d900593          	li	a1,217
ffffffffc0201238:	00006517          	auipc	a0,0x6
ffffffffc020123c:	d9850513          	addi	a0,a0,-616 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201240:	a44ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201244:	00006697          	auipc	a3,0x6
ffffffffc0201248:	dc468693          	addi	a3,a3,-572 # ffffffffc0207008 <commands+0x8c0>
ffffffffc020124c:	00006617          	auipc	a2,0x6
ffffffffc0201250:	9bc60613          	addi	a2,a2,-1604 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201254:	0d200593          	li	a1,210
ffffffffc0201258:	00006517          	auipc	a0,0x6
ffffffffc020125c:	d7850513          	addi	a0,a0,-648 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201260:	a24ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 3);
ffffffffc0201264:	00006697          	auipc	a3,0x6
ffffffffc0201268:	ee468693          	addi	a3,a3,-284 # ffffffffc0207148 <commands+0xa00>
ffffffffc020126c:	00006617          	auipc	a2,0x6
ffffffffc0201270:	99c60613          	addi	a2,a2,-1636 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201274:	0d000593          	li	a1,208
ffffffffc0201278:	00006517          	auipc	a0,0x6
ffffffffc020127c:	d5850513          	addi	a0,a0,-680 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201280:	a04ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201284:	00006697          	auipc	a3,0x6
ffffffffc0201288:	eac68693          	addi	a3,a3,-340 # ffffffffc0207130 <commands+0x9e8>
ffffffffc020128c:	00006617          	auipc	a2,0x6
ffffffffc0201290:	97c60613          	addi	a2,a2,-1668 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201294:	0cb00593          	li	a1,203
ffffffffc0201298:	00006517          	auipc	a0,0x6
ffffffffc020129c:	d3850513          	addi	a0,a0,-712 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02012a0:	9e4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02012a4:	00006697          	auipc	a3,0x6
ffffffffc02012a8:	e6c68693          	addi	a3,a3,-404 # ffffffffc0207110 <commands+0x9c8>
ffffffffc02012ac:	00006617          	auipc	a2,0x6
ffffffffc02012b0:	95c60613          	addi	a2,a2,-1700 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02012b4:	0c200593          	li	a1,194
ffffffffc02012b8:	00006517          	auipc	a0,0x6
ffffffffc02012bc:	d1850513          	addi	a0,a0,-744 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02012c0:	9c4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 != NULL);
ffffffffc02012c4:	00006697          	auipc	a3,0x6
ffffffffc02012c8:	edc68693          	addi	a3,a3,-292 # ffffffffc02071a0 <commands+0xa58>
ffffffffc02012cc:	00006617          	auipc	a2,0x6
ffffffffc02012d0:	93c60613          	addi	a2,a2,-1732 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02012d4:	0f800593          	li	a1,248
ffffffffc02012d8:	00006517          	auipc	a0,0x6
ffffffffc02012dc:	cf850513          	addi	a0,a0,-776 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02012e0:	9a4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 0);
ffffffffc02012e4:	00006697          	auipc	a3,0x6
ffffffffc02012e8:	eac68693          	addi	a3,a3,-340 # ffffffffc0207190 <commands+0xa48>
ffffffffc02012ec:	00006617          	auipc	a2,0x6
ffffffffc02012f0:	91c60613          	addi	a2,a2,-1764 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02012f4:	0df00593          	li	a1,223
ffffffffc02012f8:	00006517          	auipc	a0,0x6
ffffffffc02012fc:	cd850513          	addi	a0,a0,-808 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201300:	984ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201304:	00006697          	auipc	a3,0x6
ffffffffc0201308:	e2c68693          	addi	a3,a3,-468 # ffffffffc0207130 <commands+0x9e8>
ffffffffc020130c:	00006617          	auipc	a2,0x6
ffffffffc0201310:	8fc60613          	addi	a2,a2,-1796 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201314:	0dd00593          	li	a1,221
ffffffffc0201318:	00006517          	auipc	a0,0x6
ffffffffc020131c:	cb850513          	addi	a0,a0,-840 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201320:	964ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0201324:	00006697          	auipc	a3,0x6
ffffffffc0201328:	e4c68693          	addi	a3,a3,-436 # ffffffffc0207170 <commands+0xa28>
ffffffffc020132c:	00006617          	auipc	a2,0x6
ffffffffc0201330:	8dc60613          	addi	a2,a2,-1828 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201334:	0dc00593          	li	a1,220
ffffffffc0201338:	00006517          	auipc	a0,0x6
ffffffffc020133c:	c9850513          	addi	a0,a0,-872 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201340:	944ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0201344:	00006697          	auipc	a3,0x6
ffffffffc0201348:	cc468693          	addi	a3,a3,-828 # ffffffffc0207008 <commands+0x8c0>
ffffffffc020134c:	00006617          	auipc	a2,0x6
ffffffffc0201350:	8bc60613          	addi	a2,a2,-1860 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201354:	0b900593          	li	a1,185
ffffffffc0201358:	00006517          	auipc	a0,0x6
ffffffffc020135c:	c7850513          	addi	a0,a0,-904 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201360:	924ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201364:	00006697          	auipc	a3,0x6
ffffffffc0201368:	dcc68693          	addi	a3,a3,-564 # ffffffffc0207130 <commands+0x9e8>
ffffffffc020136c:	00006617          	auipc	a2,0x6
ffffffffc0201370:	89c60613          	addi	a2,a2,-1892 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201374:	0d600593          	li	a1,214
ffffffffc0201378:	00006517          	auipc	a0,0x6
ffffffffc020137c:	c5850513          	addi	a0,a0,-936 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201380:	904ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0201384:	00006697          	auipc	a3,0x6
ffffffffc0201388:	cc468693          	addi	a3,a3,-828 # ffffffffc0207048 <commands+0x900>
ffffffffc020138c:	00006617          	auipc	a2,0x6
ffffffffc0201390:	87c60613          	addi	a2,a2,-1924 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201394:	0d400593          	li	a1,212
ffffffffc0201398:	00006517          	auipc	a0,0x6
ffffffffc020139c:	c3850513          	addi	a0,a0,-968 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02013a0:	8e4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02013a4:	00006697          	auipc	a3,0x6
ffffffffc02013a8:	c8468693          	addi	a3,a3,-892 # ffffffffc0207028 <commands+0x8e0>
ffffffffc02013ac:	00006617          	auipc	a2,0x6
ffffffffc02013b0:	85c60613          	addi	a2,a2,-1956 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02013b4:	0d300593          	li	a1,211
ffffffffc02013b8:	00006517          	auipc	a0,0x6
ffffffffc02013bc:	c1850513          	addi	a0,a0,-1000 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02013c0:	8c4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02013c4:	00006697          	auipc	a3,0x6
ffffffffc02013c8:	c8468693          	addi	a3,a3,-892 # ffffffffc0207048 <commands+0x900>
ffffffffc02013cc:	00006617          	auipc	a2,0x6
ffffffffc02013d0:	83c60613          	addi	a2,a2,-1988 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02013d4:	0bb00593          	li	a1,187
ffffffffc02013d8:	00006517          	auipc	a0,0x6
ffffffffc02013dc:	bf850513          	addi	a0,a0,-1032 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02013e0:	8a4ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(count == 0);
ffffffffc02013e4:	00006697          	auipc	a3,0x6
ffffffffc02013e8:	f0c68693          	addi	a3,a3,-244 # ffffffffc02072f0 <commands+0xba8>
ffffffffc02013ec:	00006617          	auipc	a2,0x6
ffffffffc02013f0:	81c60613          	addi	a2,a2,-2020 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02013f4:	12500593          	li	a1,293
ffffffffc02013f8:	00006517          	auipc	a0,0x6
ffffffffc02013fc:	bd850513          	addi	a0,a0,-1064 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201400:	884ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free == 0);
ffffffffc0201404:	00006697          	auipc	a3,0x6
ffffffffc0201408:	d8c68693          	addi	a3,a3,-628 # ffffffffc0207190 <commands+0xa48>
ffffffffc020140c:	00005617          	auipc	a2,0x5
ffffffffc0201410:	7fc60613          	addi	a2,a2,2044 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201414:	11a00593          	li	a1,282
ffffffffc0201418:	00006517          	auipc	a0,0x6
ffffffffc020141c:	bb850513          	addi	a0,a0,-1096 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201420:	864ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201424:	00006697          	auipc	a3,0x6
ffffffffc0201428:	d0c68693          	addi	a3,a3,-756 # ffffffffc0207130 <commands+0x9e8>
ffffffffc020142c:	00005617          	auipc	a2,0x5
ffffffffc0201430:	7dc60613          	addi	a2,a2,2012 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201434:	11800593          	li	a1,280
ffffffffc0201438:	00006517          	auipc	a0,0x6
ffffffffc020143c:	b9850513          	addi	a0,a0,-1128 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201440:	844ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0201444:	00006697          	auipc	a3,0x6
ffffffffc0201448:	cac68693          	addi	a3,a3,-852 # ffffffffc02070f0 <commands+0x9a8>
ffffffffc020144c:	00005617          	auipc	a2,0x5
ffffffffc0201450:	7bc60613          	addi	a2,a2,1980 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201454:	0c100593          	li	a1,193
ffffffffc0201458:	00006517          	auipc	a0,0x6
ffffffffc020145c:	b7850513          	addi	a0,a0,-1160 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201460:	824ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_pages(2)) == p2 + 1);
ffffffffc0201464:	00006697          	auipc	a3,0x6
ffffffffc0201468:	e4c68693          	addi	a3,a3,-436 # ffffffffc02072b0 <commands+0xb68>
ffffffffc020146c:	00005617          	auipc	a2,0x5
ffffffffc0201470:	79c60613          	addi	a2,a2,1948 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201474:	11200593          	li	a1,274
ffffffffc0201478:	00006517          	auipc	a0,0x6
ffffffffc020147c:	b5850513          	addi	a0,a0,-1192 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201480:	804ff0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_page()) == p2 - 1);
ffffffffc0201484:	00006697          	auipc	a3,0x6
ffffffffc0201488:	e0c68693          	addi	a3,a3,-500 # ffffffffc0207290 <commands+0xb48>
ffffffffc020148c:	00005617          	auipc	a2,0x5
ffffffffc0201490:	77c60613          	addi	a2,a2,1916 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201494:	11000593          	li	a1,272
ffffffffc0201498:	00006517          	auipc	a0,0x6
ffffffffc020149c:	b3850513          	addi	a0,a0,-1224 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02014a0:	fe5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p1) && p1->property == 3);
ffffffffc02014a4:	00006697          	auipc	a3,0x6
ffffffffc02014a8:	dc468693          	addi	a3,a3,-572 # ffffffffc0207268 <commands+0xb20>
ffffffffc02014ac:	00005617          	auipc	a2,0x5
ffffffffc02014b0:	75c60613          	addi	a2,a2,1884 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02014b4:	10e00593          	li	a1,270
ffffffffc02014b8:	00006517          	auipc	a0,0x6
ffffffffc02014bc:	b1850513          	addi	a0,a0,-1256 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02014c0:	fc5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p0) && p0->property == 1);
ffffffffc02014c4:	00006697          	auipc	a3,0x6
ffffffffc02014c8:	d7c68693          	addi	a3,a3,-644 # ffffffffc0207240 <commands+0xaf8>
ffffffffc02014cc:	00005617          	auipc	a2,0x5
ffffffffc02014d0:	73c60613          	addi	a2,a2,1852 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02014d4:	10d00593          	li	a1,269
ffffffffc02014d8:	00006517          	auipc	a0,0x6
ffffffffc02014dc:	af850513          	addi	a0,a0,-1288 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02014e0:	fa5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(p0 + 2 == p1);
ffffffffc02014e4:	00006697          	auipc	a3,0x6
ffffffffc02014e8:	d4c68693          	addi	a3,a3,-692 # ffffffffc0207230 <commands+0xae8>
ffffffffc02014ec:	00005617          	auipc	a2,0x5
ffffffffc02014f0:	71c60613          	addi	a2,a2,1820 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02014f4:	10800593          	li	a1,264
ffffffffc02014f8:	00006517          	auipc	a0,0x6
ffffffffc02014fc:	ad850513          	addi	a0,a0,-1320 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201500:	f85fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201504:	00006697          	auipc	a3,0x6
ffffffffc0201508:	c2c68693          	addi	a3,a3,-980 # ffffffffc0207130 <commands+0x9e8>
ffffffffc020150c:	00005617          	auipc	a2,0x5
ffffffffc0201510:	6fc60613          	addi	a2,a2,1788 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201514:	10700593          	li	a1,263
ffffffffc0201518:	00006517          	auipc	a0,0x6
ffffffffc020151c:	ab850513          	addi	a0,a0,-1352 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201520:	f65fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_pages(3)) != NULL);
ffffffffc0201524:	00006697          	auipc	a3,0x6
ffffffffc0201528:	cec68693          	addi	a3,a3,-788 # ffffffffc0207210 <commands+0xac8>
ffffffffc020152c:	00005617          	auipc	a2,0x5
ffffffffc0201530:	6dc60613          	addi	a2,a2,1756 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201534:	10600593          	li	a1,262
ffffffffc0201538:	00006517          	auipc	a0,0x6
ffffffffc020153c:	a9850513          	addi	a0,a0,-1384 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201540:	f45fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(PageProperty(p0 + 2) && p0[2].property == 3);
ffffffffc0201544:	00006697          	auipc	a3,0x6
ffffffffc0201548:	c9c68693          	addi	a3,a3,-868 # ffffffffc02071e0 <commands+0xa98>
ffffffffc020154c:	00005617          	auipc	a2,0x5
ffffffffc0201550:	6bc60613          	addi	a2,a2,1724 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201554:	10500593          	li	a1,261
ffffffffc0201558:	00006517          	auipc	a0,0x6
ffffffffc020155c:	a7850513          	addi	a0,a0,-1416 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201560:	f25fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0201564:	00006697          	auipc	a3,0x6
ffffffffc0201568:	c6468693          	addi	a3,a3,-924 # ffffffffc02071c8 <commands+0xa80>
ffffffffc020156c:	00005617          	auipc	a2,0x5
ffffffffc0201570:	69c60613          	addi	a2,a2,1692 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201574:	10400593          	li	a1,260
ffffffffc0201578:	00006517          	auipc	a0,0x6
ffffffffc020157c:	a5850513          	addi	a0,a0,-1448 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201580:	f05fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0201584:	00006697          	auipc	a3,0x6
ffffffffc0201588:	bac68693          	addi	a3,a3,-1108 # ffffffffc0207130 <commands+0x9e8>
ffffffffc020158c:	00005617          	auipc	a2,0x5
ffffffffc0201590:	67c60613          	addi	a2,a2,1660 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201594:	0fe00593          	li	a1,254
ffffffffc0201598:	00006517          	auipc	a0,0x6
ffffffffc020159c:	a3850513          	addi	a0,a0,-1480 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02015a0:	ee5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(!PageProperty(p0));
ffffffffc02015a4:	00006697          	auipc	a3,0x6
ffffffffc02015a8:	c0c68693          	addi	a3,a3,-1012 # ffffffffc02071b0 <commands+0xa68>
ffffffffc02015ac:	00005617          	auipc	a2,0x5
ffffffffc02015b0:	65c60613          	addi	a2,a2,1628 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02015b4:	0f900593          	li	a1,249
ffffffffc02015b8:	00006517          	auipc	a0,0x6
ffffffffc02015bc:	a1850513          	addi	a0,a0,-1512 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02015c0:	ec5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc02015c4:	00006697          	auipc	a3,0x6
ffffffffc02015c8:	d0c68693          	addi	a3,a3,-756 # ffffffffc02072d0 <commands+0xb88>
ffffffffc02015cc:	00005617          	auipc	a2,0x5
ffffffffc02015d0:	63c60613          	addi	a2,a2,1596 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02015d4:	11700593          	li	a1,279
ffffffffc02015d8:	00006517          	auipc	a0,0x6
ffffffffc02015dc:	9f850513          	addi	a0,a0,-1544 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02015e0:	ea5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(total == 0);
ffffffffc02015e4:	00006697          	auipc	a3,0x6
ffffffffc02015e8:	d1c68693          	addi	a3,a3,-740 # ffffffffc0207300 <commands+0xbb8>
ffffffffc02015ec:	00005617          	auipc	a2,0x5
ffffffffc02015f0:	61c60613          	addi	a2,a2,1564 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02015f4:	12600593          	li	a1,294
ffffffffc02015f8:	00006517          	auipc	a0,0x6
ffffffffc02015fc:	9d850513          	addi	a0,a0,-1576 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201600:	e85fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(total == nr_free_pages());
ffffffffc0201604:	00006697          	auipc	a3,0x6
ffffffffc0201608:	9e468693          	addi	a3,a3,-1564 # ffffffffc0206fe8 <commands+0x8a0>
ffffffffc020160c:	00005617          	auipc	a2,0x5
ffffffffc0201610:	5fc60613          	addi	a2,a2,1532 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201614:	0f300593          	li	a1,243
ffffffffc0201618:	00006517          	auipc	a0,0x6
ffffffffc020161c:	9b850513          	addi	a0,a0,-1608 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201620:	e65fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0201624:	00006697          	auipc	a3,0x6
ffffffffc0201628:	a0468693          	addi	a3,a3,-1532 # ffffffffc0207028 <commands+0x8e0>
ffffffffc020162c:	00005617          	auipc	a2,0x5
ffffffffc0201630:	5dc60613          	addi	a2,a2,1500 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201634:	0ba00593          	li	a1,186
ffffffffc0201638:	00006517          	auipc	a0,0x6
ffffffffc020163c:	99850513          	addi	a0,a0,-1640 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201640:	e45fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201644 <default_free_pages>:
default_free_pages(struct Page *base, size_t n) {
ffffffffc0201644:	1141                	addi	sp,sp,-16
ffffffffc0201646:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201648:	16058e63          	beqz	a1,ffffffffc02017c4 <default_free_pages+0x180>
    for (; p != base + n; p ++) {
ffffffffc020164c:	00659693          	slli	a3,a1,0x6
ffffffffc0201650:	96aa                	add	a3,a3,a0
ffffffffc0201652:	02d50d63          	beq	a0,a3,ffffffffc020168c <default_free_pages+0x48>
ffffffffc0201656:	651c                	ld	a5,8(a0)
ffffffffc0201658:	8b85                	andi	a5,a5,1
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc020165a:	14079563          	bnez	a5,ffffffffc02017a4 <default_free_pages+0x160>
ffffffffc020165e:	651c                	ld	a5,8(a0)
ffffffffc0201660:	8385                	srli	a5,a5,0x1
ffffffffc0201662:	8b85                	andi	a5,a5,1
ffffffffc0201664:	14079063          	bnez	a5,ffffffffc02017a4 <default_free_pages+0x160>
ffffffffc0201668:	87aa                	mv	a5,a0
ffffffffc020166a:	a809                	j	ffffffffc020167c <default_free_pages+0x38>
ffffffffc020166c:	6798                	ld	a4,8(a5)
ffffffffc020166e:	8b05                	andi	a4,a4,1
ffffffffc0201670:	12071a63          	bnez	a4,ffffffffc02017a4 <default_free_pages+0x160>
ffffffffc0201674:	6798                	ld	a4,8(a5)
ffffffffc0201676:	8b09                	andi	a4,a4,2
ffffffffc0201678:	12071663          	bnez	a4,ffffffffc02017a4 <default_free_pages+0x160>
        p->flags = 0;
ffffffffc020167c:	0007b423          	sd	zero,8(a5)
    return page->ref;
}

static inline void
set_page_ref(struct Page *page, int val) {
    page->ref = val;
ffffffffc0201680:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0201684:	04078793          	addi	a5,a5,64
ffffffffc0201688:	fed792e3          	bne	a5,a3,ffffffffc020166c <default_free_pages+0x28>
    base->property = n;
ffffffffc020168c:	2581                	sext.w	a1,a1
ffffffffc020168e:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201690:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201694:	4789                	li	a5,2
ffffffffc0201696:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc020169a:	000ab697          	auipc	a3,0xab
ffffffffc020169e:	e4e68693          	addi	a3,a3,-434 # ffffffffc02ac4e8 <free_area>
ffffffffc02016a2:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02016a4:	669c                	ld	a5,8(a3)
ffffffffc02016a6:	9db9                	addw	a1,a1,a4
ffffffffc02016a8:	000ab717          	auipc	a4,0xab
ffffffffc02016ac:	e4b72823          	sw	a1,-432(a4) # ffffffffc02ac4f8 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02016b0:	0cd78163          	beq	a5,a3,ffffffffc0201772 <default_free_pages+0x12e>
            struct Page* page = le2page(le, page_link);
ffffffffc02016b4:	fe878713          	addi	a4,a5,-24
ffffffffc02016b8:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02016ba:	4801                	li	a6,0
ffffffffc02016bc:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc02016c0:	00e56a63          	bltu	a0,a4,ffffffffc02016d4 <default_free_pages+0x90>
    return listelm->next;
ffffffffc02016c4:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02016c6:	04d70f63          	beq	a4,a3,ffffffffc0201724 <default_free_pages+0xe0>
        while ((le = list_next(le)) != &free_list) {
ffffffffc02016ca:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02016cc:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02016d0:	fee57ae3          	bleu	a4,a0,ffffffffc02016c4 <default_free_pages+0x80>
ffffffffc02016d4:	00080663          	beqz	a6,ffffffffc02016e0 <default_free_pages+0x9c>
ffffffffc02016d8:	000ab817          	auipc	a6,0xab
ffffffffc02016dc:	e0b83823          	sd	a1,-496(a6) # ffffffffc02ac4e8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc02016e0:	638c                	ld	a1,0(a5)
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_add(list_entry_t *elm, list_entry_t *prev, list_entry_t *next) {
    prev->next = next->prev = elm;
ffffffffc02016e2:	e390                	sd	a2,0(a5)
ffffffffc02016e4:	e590                	sd	a2,8(a1)
    elm->next = next;
ffffffffc02016e6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc02016e8:	ed0c                	sd	a1,24(a0)
    if (le != &free_list) {
ffffffffc02016ea:	06d58a63          	beq	a1,a3,ffffffffc020175e <default_free_pages+0x11a>
        if (p + p->property == base) {
ffffffffc02016ee:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc02016f2:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base) {
ffffffffc02016f6:	02061793          	slli	a5,a2,0x20
ffffffffc02016fa:	83e9                	srli	a5,a5,0x1a
ffffffffc02016fc:	97ba                	add	a5,a5,a4
ffffffffc02016fe:	04f51b63          	bne	a0,a5,ffffffffc0201754 <default_free_pages+0x110>
            p->property += base->property;
ffffffffc0201702:	491c                	lw	a5,16(a0)
ffffffffc0201704:	9e3d                	addw	a2,a2,a5
ffffffffc0201706:	fec5ac23          	sw	a2,-8(a1)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc020170a:	57f5                	li	a5,-3
ffffffffc020170c:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201710:	01853803          	ld	a6,24(a0)
ffffffffc0201714:	7110                	ld	a2,32(a0)
            base = p;
ffffffffc0201716:	853a                	mv	a0,a4
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0201718:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc020171c:	659c                	ld	a5,8(a1)
ffffffffc020171e:	01063023          	sd	a6,0(a2)
ffffffffc0201722:	a815                	j	ffffffffc0201756 <default_free_pages+0x112>
    prev->next = next->prev = elm;
ffffffffc0201724:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201726:	f114                	sd	a3,32(a0)
ffffffffc0201728:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020172a:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020172c:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc020172e:	00d70563          	beq	a4,a3,ffffffffc0201738 <default_free_pages+0xf4>
ffffffffc0201732:	4805                	li	a6,1
ffffffffc0201734:	87ba                	mv	a5,a4
ffffffffc0201736:	bf59                	j	ffffffffc02016cc <default_free_pages+0x88>
ffffffffc0201738:	e290                	sd	a2,0(a3)
    return listelm->prev;
ffffffffc020173a:	85be                	mv	a1,a5
    if (le != &free_list) {
ffffffffc020173c:	00d78d63          	beq	a5,a3,ffffffffc0201756 <default_free_pages+0x112>
        if (p + p->property == base) {
ffffffffc0201740:	ff85a603          	lw	a2,-8(a1)
        p = le2page(le, page_link);
ffffffffc0201744:	fe858713          	addi	a4,a1,-24
        if (p + p->property == base) {
ffffffffc0201748:	02061793          	slli	a5,a2,0x20
ffffffffc020174c:	83e9                	srli	a5,a5,0x1a
ffffffffc020174e:	97ba                	add	a5,a5,a4
ffffffffc0201750:	faf509e3          	beq	a0,a5,ffffffffc0201702 <default_free_pages+0xbe>
ffffffffc0201754:	711c                	ld	a5,32(a0)
    if (le != &free_list) {
ffffffffc0201756:	fe878713          	addi	a4,a5,-24
ffffffffc020175a:	00d78963          	beq	a5,a3,ffffffffc020176c <default_free_pages+0x128>
        if (base + base->property == p) {
ffffffffc020175e:	4910                	lw	a2,16(a0)
ffffffffc0201760:	02061693          	slli	a3,a2,0x20
ffffffffc0201764:	82e9                	srli	a3,a3,0x1a
ffffffffc0201766:	96aa                	add	a3,a3,a0
ffffffffc0201768:	00d70e63          	beq	a4,a3,ffffffffc0201784 <default_free_pages+0x140>
}
ffffffffc020176c:	60a2                	ld	ra,8(sp)
ffffffffc020176e:	0141                	addi	sp,sp,16
ffffffffc0201770:	8082                	ret
ffffffffc0201772:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc0201774:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201778:	e398                	sd	a4,0(a5)
ffffffffc020177a:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc020177c:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020177e:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201780:	0141                	addi	sp,sp,16
ffffffffc0201782:	8082                	ret
            base->property += p->property;
ffffffffc0201784:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201788:	ff078693          	addi	a3,a5,-16
ffffffffc020178c:	9e39                	addw	a2,a2,a4
ffffffffc020178e:	c910                	sw	a2,16(a0)
ffffffffc0201790:	5775                	li	a4,-3
ffffffffc0201792:	60e6b02f          	amoand.d	zero,a4,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201796:	6398                	ld	a4,0(a5)
ffffffffc0201798:	679c                	ld	a5,8(a5)
}
ffffffffc020179a:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020179c:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020179e:	e398                	sd	a4,0(a5)
ffffffffc02017a0:	0141                	addi	sp,sp,16
ffffffffc02017a2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02017a4:	00006697          	auipc	a3,0x6
ffffffffc02017a8:	b6c68693          	addi	a3,a3,-1172 # ffffffffc0207310 <commands+0xbc8>
ffffffffc02017ac:	00005617          	auipc	a2,0x5
ffffffffc02017b0:	45c60613          	addi	a2,a2,1116 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02017b4:	08300593          	li	a1,131
ffffffffc02017b8:	00006517          	auipc	a0,0x6
ffffffffc02017bc:	81850513          	addi	a0,a0,-2024 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02017c0:	cc5fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(n > 0);
ffffffffc02017c4:	00006697          	auipc	a3,0x6
ffffffffc02017c8:	b7468693          	addi	a3,a3,-1164 # ffffffffc0207338 <commands+0xbf0>
ffffffffc02017cc:	00005617          	auipc	a2,0x5
ffffffffc02017d0:	43c60613          	addi	a2,a2,1084 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02017d4:	08000593          	li	a1,128
ffffffffc02017d8:	00005517          	auipc	a0,0x5
ffffffffc02017dc:	7f850513          	addi	a0,a0,2040 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02017e0:	ca5fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02017e4 <default_alloc_pages>:
    assert(n > 0);
ffffffffc02017e4:	c959                	beqz	a0,ffffffffc020187a <default_alloc_pages+0x96>
    if (n > nr_free) {
ffffffffc02017e6:	000ab597          	auipc	a1,0xab
ffffffffc02017ea:	d0258593          	addi	a1,a1,-766 # ffffffffc02ac4e8 <free_area>
ffffffffc02017ee:	0105a803          	lw	a6,16(a1)
ffffffffc02017f2:	862a                	mv	a2,a0
ffffffffc02017f4:	02081793          	slli	a5,a6,0x20
ffffffffc02017f8:	9381                	srli	a5,a5,0x20
ffffffffc02017fa:	00a7ee63          	bltu	a5,a0,ffffffffc0201816 <default_alloc_pages+0x32>
    list_entry_t *le = &free_list;
ffffffffc02017fe:	87ae                	mv	a5,a1
ffffffffc0201800:	a801                	j	ffffffffc0201810 <default_alloc_pages+0x2c>
        if (p->property >= n) {
ffffffffc0201802:	ff87a703          	lw	a4,-8(a5)
ffffffffc0201806:	02071693          	slli	a3,a4,0x20
ffffffffc020180a:	9281                	srli	a3,a3,0x20
ffffffffc020180c:	00c6f763          	bleu	a2,a3,ffffffffc020181a <default_alloc_pages+0x36>
    return listelm->next;
ffffffffc0201810:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc0201812:	feb798e3          	bne	a5,a1,ffffffffc0201802 <default_alloc_pages+0x1e>
        return NULL;
ffffffffc0201816:	4501                	li	a0,0
}
ffffffffc0201818:	8082                	ret
        struct Page *p = le2page(le, page_link);
ffffffffc020181a:	fe878513          	addi	a0,a5,-24
    if (page != NULL) {
ffffffffc020181e:	dd6d                	beqz	a0,ffffffffc0201818 <default_alloc_pages+0x34>
    return listelm->prev;
ffffffffc0201820:	0007b883          	ld	a7,0(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201824:	0087b303          	ld	t1,8(a5)
    prev->next = next;
ffffffffc0201828:	00060e1b          	sext.w	t3,a2
ffffffffc020182c:	0068b423          	sd	t1,8(a7)
    next->prev = prev;
ffffffffc0201830:	01133023          	sd	a7,0(t1)
        if (page->property > n) {
ffffffffc0201834:	02d67863          	bleu	a3,a2,ffffffffc0201864 <default_alloc_pages+0x80>
            struct Page *p = page + n;
ffffffffc0201838:	061a                	slli	a2,a2,0x6
ffffffffc020183a:	962a                	add	a2,a2,a0
            p->property = page->property - n;
ffffffffc020183c:	41c7073b          	subw	a4,a4,t3
ffffffffc0201840:	ca18                	sw	a4,16(a2)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0201842:	00860693          	addi	a3,a2,8
ffffffffc0201846:	4709                	li	a4,2
ffffffffc0201848:	40e6b02f          	amoor.d	zero,a4,(a3)
    __list_add(elm, listelm, listelm->next);
ffffffffc020184c:	0088b703          	ld	a4,8(a7)
            list_add(prev, &(p->page_link));
ffffffffc0201850:	01860693          	addi	a3,a2,24
    prev->next = next->prev = elm;
ffffffffc0201854:	0105a803          	lw	a6,16(a1)
ffffffffc0201858:	e314                	sd	a3,0(a4)
ffffffffc020185a:	00d8b423          	sd	a3,8(a7)
    elm->next = next;
ffffffffc020185e:	f218                	sd	a4,32(a2)
    elm->prev = prev;
ffffffffc0201860:	01163c23          	sd	a7,24(a2)
        nr_free -= n;
ffffffffc0201864:	41c8083b          	subw	a6,a6,t3
ffffffffc0201868:	000ab717          	auipc	a4,0xab
ffffffffc020186c:	c9072823          	sw	a6,-880(a4) # ffffffffc02ac4f8 <free_area+0x10>
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0201870:	5775                	li	a4,-3
ffffffffc0201872:	17c1                	addi	a5,a5,-16
ffffffffc0201874:	60e7b02f          	amoand.d	zero,a4,(a5)
ffffffffc0201878:	8082                	ret
default_alloc_pages(size_t n) {
ffffffffc020187a:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020187c:	00006697          	auipc	a3,0x6
ffffffffc0201880:	abc68693          	addi	a3,a3,-1348 # ffffffffc0207338 <commands+0xbf0>
ffffffffc0201884:	00005617          	auipc	a2,0x5
ffffffffc0201888:	38460613          	addi	a2,a2,900 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020188c:	06200593          	li	a1,98
ffffffffc0201890:	00005517          	auipc	a0,0x5
ffffffffc0201894:	74050513          	addi	a0,a0,1856 # ffffffffc0206fd0 <commands+0x888>
default_alloc_pages(size_t n) {
ffffffffc0201898:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020189a:	bebfe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020189e <default_init_memmap>:
default_init_memmap(struct Page *base, size_t n) {
ffffffffc020189e:	1141                	addi	sp,sp,-16
ffffffffc02018a0:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02018a2:	c1ed                	beqz	a1,ffffffffc0201984 <default_init_memmap+0xe6>
    for (; p != base + n; p ++) {
ffffffffc02018a4:	00659693          	slli	a3,a1,0x6
ffffffffc02018a8:	96aa                	add	a3,a3,a0
ffffffffc02018aa:	02d50463          	beq	a0,a3,ffffffffc02018d2 <default_init_memmap+0x34>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc02018ae:	6518                	ld	a4,8(a0)
        assert(PageReserved(p));
ffffffffc02018b0:	87aa                	mv	a5,a0
ffffffffc02018b2:	8b05                	andi	a4,a4,1
ffffffffc02018b4:	e709                	bnez	a4,ffffffffc02018be <default_init_memmap+0x20>
ffffffffc02018b6:	a07d                	j	ffffffffc0201964 <default_init_memmap+0xc6>
ffffffffc02018b8:	6798                	ld	a4,8(a5)
ffffffffc02018ba:	8b05                	andi	a4,a4,1
ffffffffc02018bc:	c745                	beqz	a4,ffffffffc0201964 <default_init_memmap+0xc6>
        p->flags = p->property = 0;
ffffffffc02018be:	0007a823          	sw	zero,16(a5)
ffffffffc02018c2:	0007b423          	sd	zero,8(a5)
ffffffffc02018c6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02018ca:	04078793          	addi	a5,a5,64
ffffffffc02018ce:	fed795e3          	bne	a5,a3,ffffffffc02018b8 <default_init_memmap+0x1a>
    base->property = n;
ffffffffc02018d2:	2581                	sext.w	a1,a1
ffffffffc02018d4:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02018d6:	4789                	li	a5,2
ffffffffc02018d8:	00850713          	addi	a4,a0,8
ffffffffc02018dc:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02018e0:	000ab697          	auipc	a3,0xab
ffffffffc02018e4:	c0868693          	addi	a3,a3,-1016 # ffffffffc02ac4e8 <free_area>
ffffffffc02018e8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02018ea:	669c                	ld	a5,8(a3)
ffffffffc02018ec:	9db9                	addw	a1,a1,a4
ffffffffc02018ee:	000ab717          	auipc	a4,0xab
ffffffffc02018f2:	c0b72523          	sw	a1,-1014(a4) # ffffffffc02ac4f8 <free_area+0x10>
    if (list_empty(&free_list)) {
ffffffffc02018f6:	04d78a63          	beq	a5,a3,ffffffffc020194a <default_init_memmap+0xac>
            struct Page* page = le2page(le, page_link);
ffffffffc02018fa:	fe878713          	addi	a4,a5,-24
ffffffffc02018fe:	628c                	ld	a1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201900:	4801                	li	a6,0
ffffffffc0201902:	01850613          	addi	a2,a0,24
            if (base < page) {
ffffffffc0201906:	00e56a63          	bltu	a0,a4,ffffffffc020191a <default_init_memmap+0x7c>
    return listelm->next;
ffffffffc020190a:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc020190c:	02d70563          	beq	a4,a3,ffffffffc0201936 <default_init_memmap+0x98>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201910:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0201912:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201916:	fee57ae3          	bleu	a4,a0,ffffffffc020190a <default_init_memmap+0x6c>
ffffffffc020191a:	00080663          	beqz	a6,ffffffffc0201926 <default_init_memmap+0x88>
ffffffffc020191e:	000ab717          	auipc	a4,0xab
ffffffffc0201922:	bcb73523          	sd	a1,-1078(a4) # ffffffffc02ac4e8 <free_area>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0201926:	6398                	ld	a4,0(a5)
}
ffffffffc0201928:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc020192a:	e390                	sd	a2,0(a5)
ffffffffc020192c:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc020192e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201930:	ed18                	sd	a4,24(a0)
ffffffffc0201932:	0141                	addi	sp,sp,16
ffffffffc0201934:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0201936:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0201938:	f114                	sd	a3,32(a0)
ffffffffc020193a:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc020193c:	ed1c                	sd	a5,24(a0)
                list_add(le, &(base->page_link));
ffffffffc020193e:	85b2                	mv	a1,a2
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201940:	00d70e63          	beq	a4,a3,ffffffffc020195c <default_init_memmap+0xbe>
ffffffffc0201944:	4805                	li	a6,1
ffffffffc0201946:	87ba                	mv	a5,a4
ffffffffc0201948:	b7e9                	j	ffffffffc0201912 <default_init_memmap+0x74>
}
ffffffffc020194a:	60a2                	ld	ra,8(sp)
        list_add(&free_list, &(base->page_link));
ffffffffc020194c:	01850713          	addi	a4,a0,24
    prev->next = next->prev = elm;
ffffffffc0201950:	e398                	sd	a4,0(a5)
ffffffffc0201952:	e798                	sd	a4,8(a5)
    elm->next = next;
ffffffffc0201954:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201956:	ed1c                	sd	a5,24(a0)
}
ffffffffc0201958:	0141                	addi	sp,sp,16
ffffffffc020195a:	8082                	ret
ffffffffc020195c:	60a2                	ld	ra,8(sp)
ffffffffc020195e:	e290                	sd	a2,0(a3)
ffffffffc0201960:	0141                	addi	sp,sp,16
ffffffffc0201962:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201964:	00006697          	auipc	a3,0x6
ffffffffc0201968:	9dc68693          	addi	a3,a3,-1572 # ffffffffc0207340 <commands+0xbf8>
ffffffffc020196c:	00005617          	auipc	a2,0x5
ffffffffc0201970:	29c60613          	addi	a2,a2,668 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201974:	04900593          	li	a1,73
ffffffffc0201978:	00005517          	auipc	a0,0x5
ffffffffc020197c:	65850513          	addi	a0,a0,1624 # ffffffffc0206fd0 <commands+0x888>
ffffffffc0201980:	b05fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(n > 0);
ffffffffc0201984:	00006697          	auipc	a3,0x6
ffffffffc0201988:	9b468693          	addi	a3,a3,-1612 # ffffffffc0207338 <commands+0xbf0>
ffffffffc020198c:	00005617          	auipc	a2,0x5
ffffffffc0201990:	27c60613          	addi	a2,a2,636 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201994:	04600593          	li	a1,70
ffffffffc0201998:	00005517          	auipc	a0,0x5
ffffffffc020199c:	63850513          	addi	a0,a0,1592 # ffffffffc0206fd0 <commands+0x888>
ffffffffc02019a0:	ae5fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02019a4 <slob_free>:
static void slob_free(void *block, int size)
{
	slob_t *cur, *b = (slob_t *)block;
	unsigned long flags;

	if (!block)
ffffffffc02019a4:	c125                	beqz	a0,ffffffffc0201a04 <slob_free+0x60>
		return;

	if (size)
ffffffffc02019a6:	e1a5                	bnez	a1,ffffffffc0201a06 <slob_free+0x62>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019a8:	100027f3          	csrr	a5,sstatus
ffffffffc02019ac:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02019ae:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02019b0:	e3bd                	bnez	a5,ffffffffc0201a16 <slob_free+0x72>
		b->units = SLOB_UNITS(size);

	/* Find reinsertion point */
	spin_lock_irqsave(&slob_lock, flags);
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019b2:	0009f797          	auipc	a5,0x9f
ffffffffc02019b6:	6c678793          	addi	a5,a5,1734 # ffffffffc02a1078 <slobfree>
ffffffffc02019ba:	639c                	ld	a5,0(a5)
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019bc:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019be:	00a7fa63          	bleu	a0,a5,ffffffffc02019d2 <slob_free+0x2e>
ffffffffc02019c2:	00e56c63          	bltu	a0,a4,ffffffffc02019da <slob_free+0x36>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019c6:	00e7fa63          	bleu	a4,a5,ffffffffc02019da <slob_free+0x36>
    return 0;
ffffffffc02019ca:	87ba                	mv	a5,a4
ffffffffc02019cc:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc02019ce:	fea7eae3          	bltu	a5,a0,ffffffffc02019c2 <slob_free+0x1e>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc02019d2:	fee7ece3          	bltu	a5,a4,ffffffffc02019ca <slob_free+0x26>
ffffffffc02019d6:	fee57ae3          	bleu	a4,a0,ffffffffc02019ca <slob_free+0x26>
			break;

	if (b + b->units == cur->next) {
ffffffffc02019da:	4110                	lw	a2,0(a0)
ffffffffc02019dc:	00461693          	slli	a3,a2,0x4
ffffffffc02019e0:	96aa                	add	a3,a3,a0
ffffffffc02019e2:	08d70b63          	beq	a4,a3,ffffffffc0201a78 <slob_free+0xd4>
		b->units += cur->next->units;
		b->next = cur->next->next;
	} else
		b->next = cur->next;

	if (cur + cur->units == b) {
ffffffffc02019e6:	4394                	lw	a3,0(a5)
		b->next = cur->next;
ffffffffc02019e8:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc02019ea:	00469713          	slli	a4,a3,0x4
ffffffffc02019ee:	973e                	add	a4,a4,a5
ffffffffc02019f0:	08e50f63          	beq	a0,a4,ffffffffc0201a8e <slob_free+0xea>
		cur->units += b->units;
		cur->next = b->next;
	} else
		cur->next = b;
ffffffffc02019f4:	e788                	sd	a0,8(a5)

	slobfree = cur;
ffffffffc02019f6:	0009f717          	auipc	a4,0x9f
ffffffffc02019fa:	68f73123          	sd	a5,1666(a4) # ffffffffc02a1078 <slobfree>
    if (flag) {
ffffffffc02019fe:	c199                	beqz	a1,ffffffffc0201a04 <slob_free+0x60>
        intr_enable();
ffffffffc0201a00:	c55fe06f          	j	ffffffffc0200654 <intr_enable>
ffffffffc0201a04:	8082                	ret
		b->units = SLOB_UNITS(size);
ffffffffc0201a06:	05bd                	addi	a1,a1,15
ffffffffc0201a08:	8191                	srli	a1,a1,0x4
ffffffffc0201a0a:	c10c                	sw	a1,0(a0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a0c:	100027f3          	csrr	a5,sstatus
ffffffffc0201a10:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0201a12:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201a14:	dfd9                	beqz	a5,ffffffffc02019b2 <slob_free+0xe>
{
ffffffffc0201a16:	1101                	addi	sp,sp,-32
ffffffffc0201a18:	e42a                	sd	a0,8(sp)
ffffffffc0201a1a:	ec06                	sd	ra,24(sp)
        intr_disable();
ffffffffc0201a1c:	c3ffe0ef          	jal	ra,ffffffffc020065a <intr_disable>
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a20:	0009f797          	auipc	a5,0x9f
ffffffffc0201a24:	65878793          	addi	a5,a5,1624 # ffffffffc02a1078 <slobfree>
ffffffffc0201a28:	639c                	ld	a5,0(a5)
        return 1;
ffffffffc0201a2a:	6522                	ld	a0,8(sp)
ffffffffc0201a2c:	4585                	li	a1,1
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a2e:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a30:	00a7fa63          	bleu	a0,a5,ffffffffc0201a44 <slob_free+0xa0>
ffffffffc0201a34:	00e56c63          	bltu	a0,a4,ffffffffc0201a4c <slob_free+0xa8>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a38:	00e7fa63          	bleu	a4,a5,ffffffffc0201a4c <slob_free+0xa8>
    return 0;
ffffffffc0201a3c:	87ba                	mv	a5,a4
ffffffffc0201a3e:	6798                	ld	a4,8(a5)
	for (cur = slobfree; !(b > cur && b < cur->next); cur = cur->next)
ffffffffc0201a40:	fea7eae3          	bltu	a5,a0,ffffffffc0201a34 <slob_free+0x90>
		if (cur >= cur->next && (b > cur || b < cur->next))
ffffffffc0201a44:	fee7ece3          	bltu	a5,a4,ffffffffc0201a3c <slob_free+0x98>
ffffffffc0201a48:	fee57ae3          	bleu	a4,a0,ffffffffc0201a3c <slob_free+0x98>
	if (b + b->units == cur->next) {
ffffffffc0201a4c:	4110                	lw	a2,0(a0)
ffffffffc0201a4e:	00461693          	slli	a3,a2,0x4
ffffffffc0201a52:	96aa                	add	a3,a3,a0
ffffffffc0201a54:	04d70763          	beq	a4,a3,ffffffffc0201aa2 <slob_free+0xfe>
		b->next = cur->next;
ffffffffc0201a58:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0201a5a:	4394                	lw	a3,0(a5)
ffffffffc0201a5c:	00469713          	slli	a4,a3,0x4
ffffffffc0201a60:	973e                	add	a4,a4,a5
ffffffffc0201a62:	04e50663          	beq	a0,a4,ffffffffc0201aae <slob_free+0x10a>
		cur->next = b;
ffffffffc0201a66:	e788                	sd	a0,8(a5)
	slobfree = cur;
ffffffffc0201a68:	0009f717          	auipc	a4,0x9f
ffffffffc0201a6c:	60f73823          	sd	a5,1552(a4) # ffffffffc02a1078 <slobfree>
    if (flag) {
ffffffffc0201a70:	e58d                	bnez	a1,ffffffffc0201a9a <slob_free+0xf6>

	spin_unlock_irqrestore(&slob_lock, flags);
}
ffffffffc0201a72:	60e2                	ld	ra,24(sp)
ffffffffc0201a74:	6105                	addi	sp,sp,32
ffffffffc0201a76:	8082                	ret
		b->units += cur->next->units;
ffffffffc0201a78:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201a7a:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0201a7c:	9e35                	addw	a2,a2,a3
ffffffffc0201a7e:	c110                	sw	a2,0(a0)
	if (cur + cur->units == b) {
ffffffffc0201a80:	4394                	lw	a3,0(a5)
		b->next = cur->next->next;
ffffffffc0201a82:	e518                	sd	a4,8(a0)
	if (cur + cur->units == b) {
ffffffffc0201a84:	00469713          	slli	a4,a3,0x4
ffffffffc0201a88:	973e                	add	a4,a4,a5
ffffffffc0201a8a:	f6e515e3          	bne	a0,a4,ffffffffc02019f4 <slob_free+0x50>
		cur->units += b->units;
ffffffffc0201a8e:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0201a90:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0201a92:	9eb9                	addw	a3,a3,a4
ffffffffc0201a94:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0201a96:	e790                	sd	a2,8(a5)
ffffffffc0201a98:	bfb9                	j	ffffffffc02019f6 <slob_free+0x52>
}
ffffffffc0201a9a:	60e2                	ld	ra,24(sp)
ffffffffc0201a9c:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201a9e:	bb7fe06f          	j	ffffffffc0200654 <intr_enable>
		b->units += cur->next->units;
ffffffffc0201aa2:	4314                	lw	a3,0(a4)
		b->next = cur->next->next;
ffffffffc0201aa4:	6718                	ld	a4,8(a4)
		b->units += cur->next->units;
ffffffffc0201aa6:	9e35                	addw	a2,a2,a3
ffffffffc0201aa8:	c110                	sw	a2,0(a0)
		b->next = cur->next->next;
ffffffffc0201aaa:	e518                	sd	a4,8(a0)
ffffffffc0201aac:	b77d                	j	ffffffffc0201a5a <slob_free+0xb6>
		cur->units += b->units;
ffffffffc0201aae:	4118                	lw	a4,0(a0)
		cur->next = b->next;
ffffffffc0201ab0:	6510                	ld	a2,8(a0)
		cur->units += b->units;
ffffffffc0201ab2:	9eb9                	addw	a3,a3,a4
ffffffffc0201ab4:	c394                	sw	a3,0(a5)
		cur->next = b->next;
ffffffffc0201ab6:	e790                	sd	a2,8(a5)
ffffffffc0201ab8:	bf45                	j	ffffffffc0201a68 <slob_free+0xc4>

ffffffffc0201aba <__slob_get_free_pages.isra.0>:
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201aba:	4785                	li	a5,1
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201abc:	1141                	addi	sp,sp,-16
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201abe:	00a7953b          	sllw	a0,a5,a0
static void* __slob_get_free_pages(gfp_t gfp, int order)
ffffffffc0201ac2:	e406                	sd	ra,8(sp)
  struct Page * page = alloc_pages(1 << order);
ffffffffc0201ac4:	38e000ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
  if(!page)
ffffffffc0201ac8:	c139                	beqz	a0,ffffffffc0201b0e <__slob_get_free_pages.isra.0+0x54>
    return page - pages + nbase;
ffffffffc0201aca:	000ab797          	auipc	a5,0xab
ffffffffc0201ace:	a4e78793          	addi	a5,a5,-1458 # ffffffffc02ac518 <pages>
ffffffffc0201ad2:	6394                	ld	a3,0(a5)
ffffffffc0201ad4:	00007797          	auipc	a5,0x7
ffffffffc0201ad8:	20478793          	addi	a5,a5,516 # ffffffffc0208cd8 <nbase>
    return KADDR(page2pa(page));
ffffffffc0201adc:	000ab717          	auipc	a4,0xab
ffffffffc0201ae0:	9cc70713          	addi	a4,a4,-1588 # ffffffffc02ac4a8 <npage>
    return page - pages + nbase;
ffffffffc0201ae4:	40d506b3          	sub	a3,a0,a3
ffffffffc0201ae8:	6388                	ld	a0,0(a5)
ffffffffc0201aea:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0201aec:	57fd                	li	a5,-1
ffffffffc0201aee:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0201af0:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0201af2:	83b1                	srli	a5,a5,0xc
ffffffffc0201af4:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0201af6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0201af8:	00e7ff63          	bleu	a4,a5,ffffffffc0201b16 <__slob_get_free_pages.isra.0+0x5c>
ffffffffc0201afc:	000ab797          	auipc	a5,0xab
ffffffffc0201b00:	a0c78793          	addi	a5,a5,-1524 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0201b04:	6388                	ld	a0,0(a5)
}
ffffffffc0201b06:	60a2                	ld	ra,8(sp)
ffffffffc0201b08:	9536                	add	a0,a0,a3
ffffffffc0201b0a:	0141                	addi	sp,sp,16
ffffffffc0201b0c:	8082                	ret
ffffffffc0201b0e:	60a2                	ld	ra,8(sp)
    return NULL;
ffffffffc0201b10:	4501                	li	a0,0
}
ffffffffc0201b12:	0141                	addi	sp,sp,16
ffffffffc0201b14:	8082                	ret
ffffffffc0201b16:	00006617          	auipc	a2,0x6
ffffffffc0201b1a:	88a60613          	addi	a2,a2,-1910 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0201b1e:	06900593          	li	a1,105
ffffffffc0201b22:	00006517          	auipc	a0,0x6
ffffffffc0201b26:	8a650513          	addi	a0,a0,-1882 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0201b2a:	95bfe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201b2e <slob_alloc.isra.1.constprop.3>:
static void *slob_alloc(size_t size, gfp_t gfp, int align)
ffffffffc0201b2e:	7179                	addi	sp,sp,-48
ffffffffc0201b30:	f406                	sd	ra,40(sp)
ffffffffc0201b32:	f022                	sd	s0,32(sp)
ffffffffc0201b34:	ec26                	sd	s1,24(sp)
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201b36:	01050713          	addi	a4,a0,16
ffffffffc0201b3a:	6785                	lui	a5,0x1
ffffffffc0201b3c:	0cf77b63          	bleu	a5,a4,ffffffffc0201c12 <slob_alloc.isra.1.constprop.3+0xe4>
	int delta = 0, units = SLOB_UNITS(size);
ffffffffc0201b40:	00f50413          	addi	s0,a0,15
ffffffffc0201b44:	8011                	srli	s0,s0,0x4
ffffffffc0201b46:	2401                	sext.w	s0,s0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b48:	10002673          	csrr	a2,sstatus
ffffffffc0201b4c:	8a09                	andi	a2,a2,2
ffffffffc0201b4e:	ea5d                	bnez	a2,ffffffffc0201c04 <slob_alloc.isra.1.constprop.3+0xd6>
	prev = slobfree;
ffffffffc0201b50:	0009f497          	auipc	s1,0x9f
ffffffffc0201b54:	52848493          	addi	s1,s1,1320 # ffffffffc02a1078 <slobfree>
ffffffffc0201b58:	6094                	ld	a3,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b5a:	669c                	ld	a5,8(a3)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b5c:	4398                	lw	a4,0(a5)
ffffffffc0201b5e:	0a875763          	ble	s0,a4,ffffffffc0201c0c <slob_alloc.isra.1.constprop.3+0xde>
		if (cur == slobfree) {
ffffffffc0201b62:	00f68a63          	beq	a3,a5,ffffffffc0201b76 <slob_alloc.isra.1.constprop.3+0x48>
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b66:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b68:	4118                	lw	a4,0(a0)
ffffffffc0201b6a:	02875763          	ble	s0,a4,ffffffffc0201b98 <slob_alloc.isra.1.constprop.3+0x6a>
ffffffffc0201b6e:	6094                	ld	a3,0(s1)
ffffffffc0201b70:	87aa                	mv	a5,a0
		if (cur == slobfree) {
ffffffffc0201b72:	fef69ae3          	bne	a3,a5,ffffffffc0201b66 <slob_alloc.isra.1.constprop.3+0x38>
    if (flag) {
ffffffffc0201b76:	ea39                	bnez	a2,ffffffffc0201bcc <slob_alloc.isra.1.constprop.3+0x9e>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201b78:	4501                	li	a0,0
ffffffffc0201b7a:	f41ff0ef          	jal	ra,ffffffffc0201aba <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc0201b7e:	cd29                	beqz	a0,ffffffffc0201bd8 <slob_alloc.isra.1.constprop.3+0xaa>
			slob_free(cur, PAGE_SIZE);
ffffffffc0201b80:	6585                	lui	a1,0x1
ffffffffc0201b82:	e23ff0ef          	jal	ra,ffffffffc02019a4 <slob_free>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201b86:	10002673          	csrr	a2,sstatus
ffffffffc0201b8a:	8a09                	andi	a2,a2,2
ffffffffc0201b8c:	ea1d                	bnez	a2,ffffffffc0201bc2 <slob_alloc.isra.1.constprop.3+0x94>
			cur = slobfree;
ffffffffc0201b8e:	609c                	ld	a5,0(s1)
	for (cur = prev->next; ; prev = cur, cur = cur->next) {
ffffffffc0201b90:	6788                	ld	a0,8(a5)
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201b92:	4118                	lw	a4,0(a0)
ffffffffc0201b94:	fc874de3          	blt	a4,s0,ffffffffc0201b6e <slob_alloc.isra.1.constprop.3+0x40>
			if (cur->units == units) /* exact fit? */
ffffffffc0201b98:	04e40663          	beq	s0,a4,ffffffffc0201be4 <slob_alloc.isra.1.constprop.3+0xb6>
				prev->next = cur + units;
ffffffffc0201b9c:	00441693          	slli	a3,s0,0x4
ffffffffc0201ba0:	96aa                	add	a3,a3,a0
ffffffffc0201ba2:	e794                	sd	a3,8(a5)
				prev->next->next = cur->next;
ffffffffc0201ba4:	650c                	ld	a1,8(a0)
				prev->next->units = cur->units - units;
ffffffffc0201ba6:	9f01                	subw	a4,a4,s0
ffffffffc0201ba8:	c298                	sw	a4,0(a3)
				prev->next->next = cur->next;
ffffffffc0201baa:	e68c                	sd	a1,8(a3)
				cur->units = units;
ffffffffc0201bac:	c100                	sw	s0,0(a0)
			slobfree = prev;
ffffffffc0201bae:	0009f717          	auipc	a4,0x9f
ffffffffc0201bb2:	4cf73523          	sd	a5,1226(a4) # ffffffffc02a1078 <slobfree>
    if (flag) {
ffffffffc0201bb6:	ee15                	bnez	a2,ffffffffc0201bf2 <slob_alloc.isra.1.constprop.3+0xc4>
}
ffffffffc0201bb8:	70a2                	ld	ra,40(sp)
ffffffffc0201bba:	7402                	ld	s0,32(sp)
ffffffffc0201bbc:	64e2                	ld	s1,24(sp)
ffffffffc0201bbe:	6145                	addi	sp,sp,48
ffffffffc0201bc0:	8082                	ret
        intr_disable();
ffffffffc0201bc2:	a99fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201bc6:	4605                	li	a2,1
			cur = slobfree;
ffffffffc0201bc8:	609c                	ld	a5,0(s1)
ffffffffc0201bca:	b7d9                	j	ffffffffc0201b90 <slob_alloc.isra.1.constprop.3+0x62>
        intr_enable();
ffffffffc0201bcc:	a89fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
			cur = (slob_t *)__slob_get_free_page(gfp);
ffffffffc0201bd0:	4501                	li	a0,0
ffffffffc0201bd2:	ee9ff0ef          	jal	ra,ffffffffc0201aba <__slob_get_free_pages.isra.0>
			if (!cur)
ffffffffc0201bd6:	f54d                	bnez	a0,ffffffffc0201b80 <slob_alloc.isra.1.constprop.3+0x52>
}
ffffffffc0201bd8:	70a2                	ld	ra,40(sp)
ffffffffc0201bda:	7402                	ld	s0,32(sp)
ffffffffc0201bdc:	64e2                	ld	s1,24(sp)
				return 0;
ffffffffc0201bde:	4501                	li	a0,0
}
ffffffffc0201be0:	6145                	addi	sp,sp,48
ffffffffc0201be2:	8082                	ret
				prev->next = cur->next; /* unlink */
ffffffffc0201be4:	6518                	ld	a4,8(a0)
ffffffffc0201be6:	e798                	sd	a4,8(a5)
			slobfree = prev;
ffffffffc0201be8:	0009f717          	auipc	a4,0x9f
ffffffffc0201bec:	48f73823          	sd	a5,1168(a4) # ffffffffc02a1078 <slobfree>
    if (flag) {
ffffffffc0201bf0:	d661                	beqz	a2,ffffffffc0201bb8 <slob_alloc.isra.1.constprop.3+0x8a>
ffffffffc0201bf2:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201bf4:	a61fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
}
ffffffffc0201bf8:	70a2                	ld	ra,40(sp)
ffffffffc0201bfa:	7402                	ld	s0,32(sp)
ffffffffc0201bfc:	6522                	ld	a0,8(sp)
ffffffffc0201bfe:	64e2                	ld	s1,24(sp)
ffffffffc0201c00:	6145                	addi	sp,sp,48
ffffffffc0201c02:	8082                	ret
        intr_disable();
ffffffffc0201c04:	a57fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201c08:	4605                	li	a2,1
ffffffffc0201c0a:	b799                	j	ffffffffc0201b50 <slob_alloc.isra.1.constprop.3+0x22>
		if (cur->units >= units + delta) { /* room enough? */
ffffffffc0201c0c:	853e                	mv	a0,a5
ffffffffc0201c0e:	87b6                	mv	a5,a3
ffffffffc0201c10:	b761                	j	ffffffffc0201b98 <slob_alloc.isra.1.constprop.3+0x6a>
  assert( (size + SLOB_UNIT) < PAGE_SIZE );
ffffffffc0201c12:	00006697          	auipc	a3,0x6
ffffffffc0201c16:	82e68693          	addi	a3,a3,-2002 # ffffffffc0207440 <default_pmm_manager+0xf0>
ffffffffc0201c1a:	00005617          	auipc	a2,0x5
ffffffffc0201c1e:	fee60613          	addi	a2,a2,-18 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0201c22:	06400593          	li	a1,100
ffffffffc0201c26:	00006517          	auipc	a0,0x6
ffffffffc0201c2a:	83a50513          	addi	a0,a0,-1990 # ffffffffc0207460 <default_pmm_manager+0x110>
ffffffffc0201c2e:	857fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201c32 <kmalloc_init>:
slob_init(void) {
  cprintf("use SLOB allocator\n");
}

inline void 
kmalloc_init(void) {
ffffffffc0201c32:	1141                	addi	sp,sp,-16
  cprintf("use SLOB allocator\n");
ffffffffc0201c34:	00006517          	auipc	a0,0x6
ffffffffc0201c38:	84450513          	addi	a0,a0,-1980 # ffffffffc0207478 <default_pmm_manager+0x128>
kmalloc_init(void) {
ffffffffc0201c3c:	e406                	sd	ra,8(sp)
  cprintf("use SLOB allocator\n");
ffffffffc0201c3e:	d50fe0ef          	jal	ra,ffffffffc020018e <cprintf>
    slob_init();
    cprintf("kmalloc_init() succeeded!\n");
}
ffffffffc0201c42:	60a2                	ld	ra,8(sp)
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c44:	00005517          	auipc	a0,0x5
ffffffffc0201c48:	7dc50513          	addi	a0,a0,2012 # ffffffffc0207420 <default_pmm_manager+0xd0>
}
ffffffffc0201c4c:	0141                	addi	sp,sp,16
    cprintf("kmalloc_init() succeeded!\n");
ffffffffc0201c4e:	d40fe06f          	j	ffffffffc020018e <cprintf>

ffffffffc0201c52 <kallocated>:
}

size_t
kallocated(void) {
   return slob_allocated();
}
ffffffffc0201c52:	4501                	li	a0,0
ffffffffc0201c54:	8082                	ret

ffffffffc0201c56 <kmalloc>:
	return 0;
}

void *
kmalloc(size_t size)
{
ffffffffc0201c56:	1101                	addi	sp,sp,-32
ffffffffc0201c58:	e04a                	sd	s2,0(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c5a:	6905                	lui	s2,0x1
{
ffffffffc0201c5c:	e822                	sd	s0,16(sp)
ffffffffc0201c5e:	ec06                	sd	ra,24(sp)
ffffffffc0201c60:	e426                	sd	s1,8(sp)
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c62:	fef90793          	addi	a5,s2,-17 # fef <_binary_obj___user_faultread_out_size-0x8591>
{
ffffffffc0201c66:	842a                	mv	s0,a0
	if (size < PAGE_SIZE - SLOB_UNIT) {
ffffffffc0201c68:	04a7fc63          	bleu	a0,a5,ffffffffc0201cc0 <kmalloc+0x6a>
	bb = slob_alloc(sizeof(bigblock_t), gfp, 0);
ffffffffc0201c6c:	4561                	li	a0,24
ffffffffc0201c6e:	ec1ff0ef          	jal	ra,ffffffffc0201b2e <slob_alloc.isra.1.constprop.3>
ffffffffc0201c72:	84aa                	mv	s1,a0
	if (!bb)
ffffffffc0201c74:	cd21                	beqz	a0,ffffffffc0201ccc <kmalloc+0x76>
	bb->order = find_order(size);
ffffffffc0201c76:	0004079b          	sext.w	a5,s0
	int order = 0;
ffffffffc0201c7a:	4501                	li	a0,0
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201c7c:	00f95763          	ble	a5,s2,ffffffffc0201c8a <kmalloc+0x34>
ffffffffc0201c80:	6705                	lui	a4,0x1
ffffffffc0201c82:	8785                	srai	a5,a5,0x1
		order++;
ffffffffc0201c84:	2505                	addiw	a0,a0,1
	for ( ; size > 4096 ; size >>=1)
ffffffffc0201c86:	fef74ee3          	blt	a4,a5,ffffffffc0201c82 <kmalloc+0x2c>
	bb->order = find_order(size);
ffffffffc0201c8a:	c088                	sw	a0,0(s1)
	bb->pages = (void *)__slob_get_free_pages(gfp, bb->order);
ffffffffc0201c8c:	e2fff0ef          	jal	ra,ffffffffc0201aba <__slob_get_free_pages.isra.0>
ffffffffc0201c90:	e488                	sd	a0,8(s1)
ffffffffc0201c92:	842a                	mv	s0,a0
	if (bb->pages) {
ffffffffc0201c94:	c935                	beqz	a0,ffffffffc0201d08 <kmalloc+0xb2>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201c96:	100027f3          	csrr	a5,sstatus
ffffffffc0201c9a:	8b89                	andi	a5,a5,2
ffffffffc0201c9c:	e3a1                	bnez	a5,ffffffffc0201cdc <kmalloc+0x86>
		bb->next = bigblocks;
ffffffffc0201c9e:	000aa797          	auipc	a5,0xaa
ffffffffc0201ca2:	7fa78793          	addi	a5,a5,2042 # ffffffffc02ac498 <bigblocks>
ffffffffc0201ca6:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0201ca8:	000aa717          	auipc	a4,0xaa
ffffffffc0201cac:	7e973823          	sd	s1,2032(a4) # ffffffffc02ac498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201cb0:	e89c                	sd	a5,16(s1)
  return __kmalloc(size, 0);
}
ffffffffc0201cb2:	8522                	mv	a0,s0
ffffffffc0201cb4:	60e2                	ld	ra,24(sp)
ffffffffc0201cb6:	6442                	ld	s0,16(sp)
ffffffffc0201cb8:	64a2                	ld	s1,8(sp)
ffffffffc0201cba:	6902                	ld	s2,0(sp)
ffffffffc0201cbc:	6105                	addi	sp,sp,32
ffffffffc0201cbe:	8082                	ret
		m = slob_alloc(size + SLOB_UNIT, gfp, 0);
ffffffffc0201cc0:	0541                	addi	a0,a0,16
ffffffffc0201cc2:	e6dff0ef          	jal	ra,ffffffffc0201b2e <slob_alloc.isra.1.constprop.3>
		return m ? (void *)(m + 1) : 0;
ffffffffc0201cc6:	01050413          	addi	s0,a0,16
ffffffffc0201cca:	f565                	bnez	a0,ffffffffc0201cb2 <kmalloc+0x5c>
ffffffffc0201ccc:	4401                	li	s0,0
}
ffffffffc0201cce:	8522                	mv	a0,s0
ffffffffc0201cd0:	60e2                	ld	ra,24(sp)
ffffffffc0201cd2:	6442                	ld	s0,16(sp)
ffffffffc0201cd4:	64a2                	ld	s1,8(sp)
ffffffffc0201cd6:	6902                	ld	s2,0(sp)
ffffffffc0201cd8:	6105                	addi	sp,sp,32
ffffffffc0201cda:	8082                	ret
        intr_disable();
ffffffffc0201cdc:	97ffe0ef          	jal	ra,ffffffffc020065a <intr_disable>
		bb->next = bigblocks;
ffffffffc0201ce0:	000aa797          	auipc	a5,0xaa
ffffffffc0201ce4:	7b878793          	addi	a5,a5,1976 # ffffffffc02ac498 <bigblocks>
ffffffffc0201ce8:	639c                	ld	a5,0(a5)
		bigblocks = bb;
ffffffffc0201cea:	000aa717          	auipc	a4,0xaa
ffffffffc0201cee:	7a973723          	sd	s1,1966(a4) # ffffffffc02ac498 <bigblocks>
		bb->next = bigblocks;
ffffffffc0201cf2:	e89c                	sd	a5,16(s1)
        intr_enable();
ffffffffc0201cf4:	961fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201cf8:	6480                	ld	s0,8(s1)
}
ffffffffc0201cfa:	60e2                	ld	ra,24(sp)
ffffffffc0201cfc:	64a2                	ld	s1,8(sp)
ffffffffc0201cfe:	8522                	mv	a0,s0
ffffffffc0201d00:	6442                	ld	s0,16(sp)
ffffffffc0201d02:	6902                	ld	s2,0(sp)
ffffffffc0201d04:	6105                	addi	sp,sp,32
ffffffffc0201d06:	8082                	ret
	slob_free(bb, sizeof(bigblock_t));
ffffffffc0201d08:	45e1                	li	a1,24
ffffffffc0201d0a:	8526                	mv	a0,s1
ffffffffc0201d0c:	c99ff0ef          	jal	ra,ffffffffc02019a4 <slob_free>
  return __kmalloc(size, 0);
ffffffffc0201d10:	b74d                	j	ffffffffc0201cb2 <kmalloc+0x5c>

ffffffffc0201d12 <kfree>:
void kfree(void *block)
{
	bigblock_t *bb, **last = &bigblocks;
	unsigned long flags;

	if (!block)
ffffffffc0201d12:	c175                	beqz	a0,ffffffffc0201df6 <kfree+0xe4>
{
ffffffffc0201d14:	1101                	addi	sp,sp,-32
ffffffffc0201d16:	e426                	sd	s1,8(sp)
ffffffffc0201d18:	ec06                	sd	ra,24(sp)
ffffffffc0201d1a:	e822                	sd	s0,16(sp)
		return;

	if (!((unsigned long)block & (PAGE_SIZE-1))) {
ffffffffc0201d1c:	03451793          	slli	a5,a0,0x34
ffffffffc0201d20:	84aa                	mv	s1,a0
ffffffffc0201d22:	eb8d                	bnez	a5,ffffffffc0201d54 <kfree+0x42>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201d24:	100027f3          	csrr	a5,sstatus
ffffffffc0201d28:	8b89                	andi	a5,a5,2
ffffffffc0201d2a:	efc9                	bnez	a5,ffffffffc0201dc4 <kfree+0xb2>
		/* might be on the big block list */
		spin_lock_irqsave(&block_lock, flags);
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d2c:	000aa797          	auipc	a5,0xaa
ffffffffc0201d30:	76c78793          	addi	a5,a5,1900 # ffffffffc02ac498 <bigblocks>
ffffffffc0201d34:	6394                	ld	a3,0(a5)
ffffffffc0201d36:	ce99                	beqz	a3,ffffffffc0201d54 <kfree+0x42>
			if (bb->pages == block) {
ffffffffc0201d38:	669c                	ld	a5,8(a3)
ffffffffc0201d3a:	6a80                	ld	s0,16(a3)
ffffffffc0201d3c:	0af50e63          	beq	a0,a5,ffffffffc0201df8 <kfree+0xe6>
    return 0;
ffffffffc0201d40:	4601                	li	a2,0
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d42:	c801                	beqz	s0,ffffffffc0201d52 <kfree+0x40>
			if (bb->pages == block) {
ffffffffc0201d44:	6418                	ld	a4,8(s0)
ffffffffc0201d46:	681c                	ld	a5,16(s0)
ffffffffc0201d48:	00970f63          	beq	a4,s1,ffffffffc0201d66 <kfree+0x54>
ffffffffc0201d4c:	86a2                	mv	a3,s0
ffffffffc0201d4e:	843e                	mv	s0,a5
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201d50:	f875                	bnez	s0,ffffffffc0201d44 <kfree+0x32>
    if (flag) {
ffffffffc0201d52:	e659                	bnez	a2,ffffffffc0201de0 <kfree+0xce>
		spin_unlock_irqrestore(&block_lock, flags);
	}

	slob_free((slob_t *)block - 1, 0);
	return;
}
ffffffffc0201d54:	6442                	ld	s0,16(sp)
ffffffffc0201d56:	60e2                	ld	ra,24(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d58:	ff048513          	addi	a0,s1,-16
}
ffffffffc0201d5c:	64a2                	ld	s1,8(sp)
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d5e:	4581                	li	a1,0
}
ffffffffc0201d60:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201d62:	c43ff06f          	j	ffffffffc02019a4 <slob_free>
				*last = bb->next;
ffffffffc0201d66:	ea9c                	sd	a5,16(a3)
ffffffffc0201d68:	e641                	bnez	a2,ffffffffc0201df0 <kfree+0xde>
    return pa2page(PADDR(kva));
ffffffffc0201d6a:	c02007b7          	lui	a5,0xc0200
				__slob_free_pages((unsigned long)block, bb->order);
ffffffffc0201d6e:	4018                	lw	a4,0(s0)
ffffffffc0201d70:	08f4ea63          	bltu	s1,a5,ffffffffc0201e04 <kfree+0xf2>
ffffffffc0201d74:	000aa797          	auipc	a5,0xaa
ffffffffc0201d78:	79478793          	addi	a5,a5,1940 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0201d7c:	6394                	ld	a3,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0201d7e:	000aa797          	auipc	a5,0xaa
ffffffffc0201d82:	72a78793          	addi	a5,a5,1834 # ffffffffc02ac4a8 <npage>
ffffffffc0201d86:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0201d88:	8c95                	sub	s1,s1,a3
    if (PPN(pa) >= npage) {
ffffffffc0201d8a:	80b1                	srli	s1,s1,0xc
ffffffffc0201d8c:	08f4f963          	bleu	a5,s1,ffffffffc0201e1e <kfree+0x10c>
    return &pages[PPN(pa) - nbase];
ffffffffc0201d90:	00007797          	auipc	a5,0x7
ffffffffc0201d94:	f4878793          	addi	a5,a5,-184 # ffffffffc0208cd8 <nbase>
ffffffffc0201d98:	639c                	ld	a5,0(a5)
ffffffffc0201d9a:	000aa697          	auipc	a3,0xaa
ffffffffc0201d9e:	77e68693          	addi	a3,a3,1918 # ffffffffc02ac518 <pages>
ffffffffc0201da2:	6288                	ld	a0,0(a3)
ffffffffc0201da4:	8c9d                	sub	s1,s1,a5
ffffffffc0201da6:	049a                	slli	s1,s1,0x6
  free_pages(kva2page(kva), 1 << order);
ffffffffc0201da8:	4585                	li	a1,1
ffffffffc0201daa:	9526                	add	a0,a0,s1
ffffffffc0201dac:	00e595bb          	sllw	a1,a1,a4
ffffffffc0201db0:	12a000ef          	jal	ra,ffffffffc0201eda <free_pages>
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201db4:	8522                	mv	a0,s0
}
ffffffffc0201db6:	6442                	ld	s0,16(sp)
ffffffffc0201db8:	60e2                	ld	ra,24(sp)
ffffffffc0201dba:	64a2                	ld	s1,8(sp)
				slob_free(bb, sizeof(bigblock_t));
ffffffffc0201dbc:	45e1                	li	a1,24
}
ffffffffc0201dbe:	6105                	addi	sp,sp,32
	slob_free((slob_t *)block - 1, 0);
ffffffffc0201dc0:	be5ff06f          	j	ffffffffc02019a4 <slob_free>
        intr_disable();
ffffffffc0201dc4:	897fe0ef          	jal	ra,ffffffffc020065a <intr_disable>
		for (bb = bigblocks; bb; last = &bb->next, bb = bb->next) {
ffffffffc0201dc8:	000aa797          	auipc	a5,0xaa
ffffffffc0201dcc:	6d078793          	addi	a5,a5,1744 # ffffffffc02ac498 <bigblocks>
ffffffffc0201dd0:	6394                	ld	a3,0(a5)
ffffffffc0201dd2:	c699                	beqz	a3,ffffffffc0201de0 <kfree+0xce>
			if (bb->pages == block) {
ffffffffc0201dd4:	669c                	ld	a5,8(a3)
ffffffffc0201dd6:	6a80                	ld	s0,16(a3)
ffffffffc0201dd8:	00f48763          	beq	s1,a5,ffffffffc0201de6 <kfree+0xd4>
        return 1;
ffffffffc0201ddc:	4605                	li	a2,1
ffffffffc0201dde:	b795                	j	ffffffffc0201d42 <kfree+0x30>
        intr_enable();
ffffffffc0201de0:	875fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201de4:	bf85                	j	ffffffffc0201d54 <kfree+0x42>
				*last = bb->next;
ffffffffc0201de6:	000aa797          	auipc	a5,0xaa
ffffffffc0201dea:	6a87b923          	sd	s0,1714(a5) # ffffffffc02ac498 <bigblocks>
ffffffffc0201dee:	8436                	mv	s0,a3
ffffffffc0201df0:	865fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201df4:	bf9d                	j	ffffffffc0201d6a <kfree+0x58>
ffffffffc0201df6:	8082                	ret
ffffffffc0201df8:	000aa797          	auipc	a5,0xaa
ffffffffc0201dfc:	6a87b023          	sd	s0,1696(a5) # ffffffffc02ac498 <bigblocks>
ffffffffc0201e00:	8436                	mv	s0,a3
ffffffffc0201e02:	b7a5                	j	ffffffffc0201d6a <kfree+0x58>
    return pa2page(PADDR(kva));
ffffffffc0201e04:	86a6                	mv	a3,s1
ffffffffc0201e06:	00005617          	auipc	a2,0x5
ffffffffc0201e0a:	5d260613          	addi	a2,a2,1490 # ffffffffc02073d8 <default_pmm_manager+0x88>
ffffffffc0201e0e:	06e00593          	li	a1,110
ffffffffc0201e12:	00005517          	auipc	a0,0x5
ffffffffc0201e16:	5b650513          	addi	a0,a0,1462 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0201e1a:	e6afe0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0201e1e:	00005617          	auipc	a2,0x5
ffffffffc0201e22:	5e260613          	addi	a2,a2,1506 # ffffffffc0207400 <default_pmm_manager+0xb0>
ffffffffc0201e26:	06200593          	li	a1,98
ffffffffc0201e2a:	00005517          	auipc	a0,0x5
ffffffffc0201e2e:	59e50513          	addi	a0,a0,1438 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0201e32:	e52fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201e36 <pa2page.part.4>:
pa2page(uintptr_t pa) {
ffffffffc0201e36:	1141                	addi	sp,sp,-16
        panic("pa2page called with invalid pa");
ffffffffc0201e38:	00005617          	auipc	a2,0x5
ffffffffc0201e3c:	5c860613          	addi	a2,a2,1480 # ffffffffc0207400 <default_pmm_manager+0xb0>
ffffffffc0201e40:	06200593          	li	a1,98
ffffffffc0201e44:	00005517          	auipc	a0,0x5
ffffffffc0201e48:	58450513          	addi	a0,a0,1412 # ffffffffc02073c8 <default_pmm_manager+0x78>
pa2page(uintptr_t pa) {
ffffffffc0201e4c:	e406                	sd	ra,8(sp)
        panic("pa2page called with invalid pa");
ffffffffc0201e4e:	e36fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0201e52 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0201e52:	715d                	addi	sp,sp,-80
ffffffffc0201e54:	e0a2                	sd	s0,64(sp)
ffffffffc0201e56:	fc26                	sd	s1,56(sp)
ffffffffc0201e58:	f84a                	sd	s2,48(sp)
ffffffffc0201e5a:	f44e                	sd	s3,40(sp)
ffffffffc0201e5c:	f052                	sd	s4,32(sp)
ffffffffc0201e5e:	ec56                	sd	s5,24(sp)
ffffffffc0201e60:	e486                	sd	ra,72(sp)
ffffffffc0201e62:	842a                	mv	s0,a0
ffffffffc0201e64:	000aa497          	auipc	s1,0xaa
ffffffffc0201e68:	69c48493          	addi	s1,s1,1692 # ffffffffc02ac500 <pmm_manager>
        {
            page = pmm_manager->alloc_pages(n);
        }
        local_intr_restore(intr_flag);

        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201e6c:	4985                	li	s3,1
ffffffffc0201e6e:	000aaa17          	auipc	s4,0xaa
ffffffffc0201e72:	64aa0a13          	addi	s4,s4,1610 # ffffffffc02ac4b8 <swap_init_ok>

        extern struct mm_struct *check_mm_struct;
        // cprintf("page %x, call swap_out in alloc_pages %d\n",page, n);
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e76:	0005091b          	sext.w	s2,a0
ffffffffc0201e7a:	000aaa97          	auipc	s5,0xaa
ffffffffc0201e7e:	77ea8a93          	addi	s5,s5,1918 # ffffffffc02ac5f8 <check_mm_struct>
ffffffffc0201e82:	a00d                	j	ffffffffc0201ea4 <alloc_pages+0x52>
            page = pmm_manager->alloc_pages(n);
ffffffffc0201e84:	609c                	ld	a5,0(s1)
ffffffffc0201e86:	6f9c                	ld	a5,24(a5)
ffffffffc0201e88:	9782                	jalr	a5
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e8a:	4601                	li	a2,0
ffffffffc0201e8c:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201e8e:	ed0d                	bnez	a0,ffffffffc0201ec8 <alloc_pages+0x76>
ffffffffc0201e90:	0289ec63          	bltu	s3,s0,ffffffffc0201ec8 <alloc_pages+0x76>
ffffffffc0201e94:	000a2783          	lw	a5,0(s4)
ffffffffc0201e98:	2781                	sext.w	a5,a5
ffffffffc0201e9a:	c79d                	beqz	a5,ffffffffc0201ec8 <alloc_pages+0x76>
        swap_out(check_mm_struct, n, 0);
ffffffffc0201e9c:	000ab503          	ld	a0,0(s5)
ffffffffc0201ea0:	481010ef          	jal	ra,ffffffffc0203b20 <swap_out>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201ea4:	100027f3          	csrr	a5,sstatus
ffffffffc0201ea8:	8b89                	andi	a5,a5,2
            page = pmm_manager->alloc_pages(n);
ffffffffc0201eaa:	8522                	mv	a0,s0
ffffffffc0201eac:	dfe1                	beqz	a5,ffffffffc0201e84 <alloc_pages+0x32>
        intr_disable();
ffffffffc0201eae:	facfe0ef          	jal	ra,ffffffffc020065a <intr_disable>
ffffffffc0201eb2:	609c                	ld	a5,0(s1)
ffffffffc0201eb4:	8522                	mv	a0,s0
ffffffffc0201eb6:	6f9c                	ld	a5,24(a5)
ffffffffc0201eb8:	9782                	jalr	a5
ffffffffc0201eba:	e42a                	sd	a0,8(sp)
        intr_enable();
ffffffffc0201ebc:	f98fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0201ec0:	6522                	ld	a0,8(sp)
        swap_out(check_mm_struct, n, 0);
ffffffffc0201ec2:	4601                	li	a2,0
ffffffffc0201ec4:	85ca                	mv	a1,s2
        if (page != NULL || n > 1 || swap_init_ok == 0) break;
ffffffffc0201ec6:	d569                	beqz	a0,ffffffffc0201e90 <alloc_pages+0x3e>
    }
    // cprintf("n %d,get page %x, No %d in alloc_pages\n",n,page,(page-pages));
    return page;
}
ffffffffc0201ec8:	60a6                	ld	ra,72(sp)
ffffffffc0201eca:	6406                	ld	s0,64(sp)
ffffffffc0201ecc:	74e2                	ld	s1,56(sp)
ffffffffc0201ece:	7942                	ld	s2,48(sp)
ffffffffc0201ed0:	79a2                	ld	s3,40(sp)
ffffffffc0201ed2:	7a02                	ld	s4,32(sp)
ffffffffc0201ed4:	6ae2                	ld	s5,24(sp)
ffffffffc0201ed6:	6161                	addi	sp,sp,80
ffffffffc0201ed8:	8082                	ret

ffffffffc0201eda <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201eda:	100027f3          	csrr	a5,sstatus
ffffffffc0201ede:	8b89                	andi	a5,a5,2
ffffffffc0201ee0:	eb89                	bnez	a5,ffffffffc0201ef2 <free_pages+0x18>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc0201ee2:	000aa797          	auipc	a5,0xaa
ffffffffc0201ee6:	61e78793          	addi	a5,a5,1566 # ffffffffc02ac500 <pmm_manager>
ffffffffc0201eea:	639c                	ld	a5,0(a5)
ffffffffc0201eec:	0207b303          	ld	t1,32(a5)
ffffffffc0201ef0:	8302                	jr	t1
void free_pages(struct Page *base, size_t n) {
ffffffffc0201ef2:	1101                	addi	sp,sp,-32
ffffffffc0201ef4:	ec06                	sd	ra,24(sp)
ffffffffc0201ef6:	e822                	sd	s0,16(sp)
ffffffffc0201ef8:	e426                	sd	s1,8(sp)
ffffffffc0201efa:	842a                	mv	s0,a0
ffffffffc0201efc:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc0201efe:	f5cfe0ef          	jal	ra,ffffffffc020065a <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc0201f02:	000aa797          	auipc	a5,0xaa
ffffffffc0201f06:	5fe78793          	addi	a5,a5,1534 # ffffffffc02ac500 <pmm_manager>
ffffffffc0201f0a:	639c                	ld	a5,0(a5)
ffffffffc0201f0c:	85a6                	mv	a1,s1
ffffffffc0201f0e:	8522                	mv	a0,s0
ffffffffc0201f10:	739c                	ld	a5,32(a5)
ffffffffc0201f12:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc0201f14:	6442                	ld	s0,16(sp)
ffffffffc0201f16:	60e2                	ld	ra,24(sp)
ffffffffc0201f18:	64a2                	ld	s1,8(sp)
ffffffffc0201f1a:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0201f1c:	f38fe06f          	j	ffffffffc0200654 <intr_enable>

ffffffffc0201f20 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201f20:	100027f3          	csrr	a5,sstatus
ffffffffc0201f24:	8b89                	andi	a5,a5,2
ffffffffc0201f26:	eb89                	bnez	a5,ffffffffc0201f38 <nr_free_pages+0x18>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f28:	000aa797          	auipc	a5,0xaa
ffffffffc0201f2c:	5d878793          	addi	a5,a5,1496 # ffffffffc02ac500 <pmm_manager>
ffffffffc0201f30:	639c                	ld	a5,0(a5)
ffffffffc0201f32:	0287b303          	ld	t1,40(a5)
ffffffffc0201f36:	8302                	jr	t1
size_t nr_free_pages(void) {
ffffffffc0201f38:	1141                	addi	sp,sp,-16
ffffffffc0201f3a:	e406                	sd	ra,8(sp)
ffffffffc0201f3c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc0201f3e:	f1cfe0ef          	jal	ra,ffffffffc020065a <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201f42:	000aa797          	auipc	a5,0xaa
ffffffffc0201f46:	5be78793          	addi	a5,a5,1470 # ffffffffc02ac500 <pmm_manager>
ffffffffc0201f4a:	639c                	ld	a5,0(a5)
ffffffffc0201f4c:	779c                	ld	a5,40(a5)
ffffffffc0201f4e:	9782                	jalr	a5
ffffffffc0201f50:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201f52:	f02fe0ef          	jal	ra,ffffffffc0200654 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201f56:	8522                	mv	a0,s0
ffffffffc0201f58:	60a2                	ld	ra,8(sp)
ffffffffc0201f5a:	6402                	ld	s0,0(sp)
ffffffffc0201f5c:	0141                	addi	sp,sp,16
ffffffffc0201f5e:	8082                	ret

ffffffffc0201f60 <get_pte>:
// parameter:
//  pgdir:  the kernel virtual base address of PDT
//  la:     the linear address need to map
//  create: a logical value to decide if alloc a page for PT
// return vaule: the kernel virtual address of this pte
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201f60:	7139                	addi	sp,sp,-64
ffffffffc0201f62:	f426                	sd	s1,40(sp)
    pde_t *pdep1 = &pgdir[PDX1(la)];
ffffffffc0201f64:	01e5d493          	srli	s1,a1,0x1e
ffffffffc0201f68:	1ff4f493          	andi	s1,s1,511
ffffffffc0201f6c:	048e                	slli	s1,s1,0x3
ffffffffc0201f6e:	94aa                	add	s1,s1,a0
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201f70:	6094                	ld	a3,0(s1)
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201f72:	f04a                	sd	s2,32(sp)
ffffffffc0201f74:	ec4e                	sd	s3,24(sp)
ffffffffc0201f76:	e852                	sd	s4,16(sp)
ffffffffc0201f78:	fc06                	sd	ra,56(sp)
ffffffffc0201f7a:	f822                	sd	s0,48(sp)
ffffffffc0201f7c:	e456                	sd	s5,8(sp)
ffffffffc0201f7e:	e05a                	sd	s6,0(sp)
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201f80:	0016f793          	andi	a5,a3,1
pte_t *get_pte(pde_t *pgdir, uintptr_t la, bool create) {
ffffffffc0201f84:	892e                	mv	s2,a1
ffffffffc0201f86:	8a32                	mv	s4,a2
ffffffffc0201f88:	000aa997          	auipc	s3,0xaa
ffffffffc0201f8c:	52098993          	addi	s3,s3,1312 # ffffffffc02ac4a8 <npage>
    if (!(*pdep1 & PTE_V)) {
ffffffffc0201f90:	e7bd                	bnez	a5,ffffffffc0201ffe <get_pte+0x9e>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0201f92:	12060c63          	beqz	a2,ffffffffc02020ca <get_pte+0x16a>
ffffffffc0201f96:	4505                	li	a0,1
ffffffffc0201f98:	ebbff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0201f9c:	842a                	mv	s0,a0
ffffffffc0201f9e:	12050663          	beqz	a0,ffffffffc02020ca <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0201fa2:	000aab17          	auipc	s6,0xaa
ffffffffc0201fa6:	576b0b13          	addi	s6,s6,1398 # ffffffffc02ac518 <pages>
ffffffffc0201faa:	000b3503          	ld	a0,0(s6)
    page->ref = val;
ffffffffc0201fae:	4785                	li	a5,1
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0201fb0:	000aa997          	auipc	s3,0xaa
ffffffffc0201fb4:	4f898993          	addi	s3,s3,1272 # ffffffffc02ac4a8 <npage>
    return page - pages + nbase;
ffffffffc0201fb8:	40a40533          	sub	a0,s0,a0
ffffffffc0201fbc:	00080ab7          	lui	s5,0x80
ffffffffc0201fc0:	8519                	srai	a0,a0,0x6
ffffffffc0201fc2:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc0201fc6:	c01c                	sw	a5,0(s0)
ffffffffc0201fc8:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0201fca:	9556                	add	a0,a0,s5
ffffffffc0201fcc:	83b1                	srli	a5,a5,0xc
ffffffffc0201fce:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0201fd0:	0532                	slli	a0,a0,0xc
ffffffffc0201fd2:	14e7f363          	bleu	a4,a5,ffffffffc0202118 <get_pte+0x1b8>
ffffffffc0201fd6:	000aa797          	auipc	a5,0xaa
ffffffffc0201fda:	53278793          	addi	a5,a5,1330 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0201fde:	639c                	ld	a5,0(a5)
ffffffffc0201fe0:	6605                	lui	a2,0x1
ffffffffc0201fe2:	4581                	li	a1,0
ffffffffc0201fe4:	953e                	add	a0,a0,a5
ffffffffc0201fe6:	608040ef          	jal	ra,ffffffffc02065ee <memset>
    return page - pages + nbase;
ffffffffc0201fea:	000b3683          	ld	a3,0(s6)
ffffffffc0201fee:	40d406b3          	sub	a3,s0,a3
ffffffffc0201ff2:	8699                	srai	a3,a3,0x6
ffffffffc0201ff4:	96d6                	add	a3,a3,s5
  asm volatile("sfence.vma");
}

// construct PTE from a page and permission bits
static inline pte_t pte_create(uintptr_t ppn, int type) {
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0201ff6:	06aa                	slli	a3,a3,0xa
ffffffffc0201ff8:	0116e693          	ori	a3,a3,17
        *pdep1 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc0201ffc:	e094                	sd	a3,0(s1)
    }

    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc0201ffe:	77fd                	lui	a5,0xfffff
ffffffffc0202000:	068a                	slli	a3,a3,0x2
ffffffffc0202002:	0009b703          	ld	a4,0(s3)
ffffffffc0202006:	8efd                	and	a3,a3,a5
ffffffffc0202008:	00c6d793          	srli	a5,a3,0xc
ffffffffc020200c:	0ce7f163          	bleu	a4,a5,ffffffffc02020ce <get_pte+0x16e>
ffffffffc0202010:	000aaa97          	auipc	s5,0xaa
ffffffffc0202014:	4f8a8a93          	addi	s5,s5,1272 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0202018:	000ab403          	ld	s0,0(s5)
ffffffffc020201c:	01595793          	srli	a5,s2,0x15
ffffffffc0202020:	1ff7f793          	andi	a5,a5,511
ffffffffc0202024:	96a2                	add	a3,a3,s0
ffffffffc0202026:	00379413          	slli	s0,a5,0x3
ffffffffc020202a:	9436                	add	s0,s0,a3
    if (!(*pdep0 & PTE_V)) {
ffffffffc020202c:	6014                	ld	a3,0(s0)
ffffffffc020202e:	0016f793          	andi	a5,a3,1
ffffffffc0202032:	e3ad                	bnez	a5,ffffffffc0202094 <get_pte+0x134>
        struct Page *page;
        if (!create || (page = alloc_page()) == NULL) {
ffffffffc0202034:	080a0b63          	beqz	s4,ffffffffc02020ca <get_pte+0x16a>
ffffffffc0202038:	4505                	li	a0,1
ffffffffc020203a:	e19ff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020203e:	84aa                	mv	s1,a0
ffffffffc0202040:	c549                	beqz	a0,ffffffffc02020ca <get_pte+0x16a>
    return page - pages + nbase;
ffffffffc0202042:	000aab17          	auipc	s6,0xaa
ffffffffc0202046:	4d6b0b13          	addi	s6,s6,1238 # ffffffffc02ac518 <pages>
ffffffffc020204a:	000b3503          	ld	a0,0(s6)
    page->ref = val;
ffffffffc020204e:	4785                	li	a5,1
    return page - pages + nbase;
ffffffffc0202050:	00080a37          	lui	s4,0x80
ffffffffc0202054:	40a48533          	sub	a0,s1,a0
ffffffffc0202058:	8519                	srai	a0,a0,0x6
            return NULL;
        }
        set_page_ref(page, 1);
        uintptr_t pa = page2pa(page);
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc020205a:	0009b703          	ld	a4,0(s3)
    page->ref = val;
ffffffffc020205e:	c09c                	sw	a5,0(s1)
ffffffffc0202060:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc0202062:	9552                	add	a0,a0,s4
ffffffffc0202064:	83b1                	srli	a5,a5,0xc
ffffffffc0202066:	8fe9                	and	a5,a5,a0
    return page2ppn(page) << PGSHIFT;
ffffffffc0202068:	0532                	slli	a0,a0,0xc
ffffffffc020206a:	08e7fa63          	bleu	a4,a5,ffffffffc02020fe <get_pte+0x19e>
ffffffffc020206e:	000ab783          	ld	a5,0(s5)
ffffffffc0202072:	6605                	lui	a2,0x1
ffffffffc0202074:	4581                	li	a1,0
ffffffffc0202076:	953e                	add	a0,a0,a5
ffffffffc0202078:	576040ef          	jal	ra,ffffffffc02065ee <memset>
    return page - pages + nbase;
ffffffffc020207c:	000b3683          	ld	a3,0(s6)
ffffffffc0202080:	40d486b3          	sub	a3,s1,a3
ffffffffc0202084:	8699                	srai	a3,a3,0x6
ffffffffc0202086:	96d2                	add	a3,a3,s4
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc0202088:	06aa                	slli	a3,a3,0xa
ffffffffc020208a:	0116e693          	ori	a3,a3,17
        *pdep0 = pte_create(page2ppn(page), PTE_U | PTE_V);
ffffffffc020208e:	e014                	sd	a3,0(s0)
ffffffffc0202090:	0009b703          	ld	a4,0(s3)
        }
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc0202094:	068a                	slli	a3,a3,0x2
ffffffffc0202096:	757d                	lui	a0,0xfffff
ffffffffc0202098:	8ee9                	and	a3,a3,a0
ffffffffc020209a:	00c6d793          	srli	a5,a3,0xc
ffffffffc020209e:	04e7f463          	bleu	a4,a5,ffffffffc02020e6 <get_pte+0x186>
ffffffffc02020a2:	000ab503          	ld	a0,0(s5)
ffffffffc02020a6:	00c95793          	srli	a5,s2,0xc
ffffffffc02020aa:	1ff7f793          	andi	a5,a5,511
ffffffffc02020ae:	96aa                	add	a3,a3,a0
ffffffffc02020b0:	00379513          	slli	a0,a5,0x3
ffffffffc02020b4:	9536                	add	a0,a0,a3
}
ffffffffc02020b6:	70e2                	ld	ra,56(sp)
ffffffffc02020b8:	7442                	ld	s0,48(sp)
ffffffffc02020ba:	74a2                	ld	s1,40(sp)
ffffffffc02020bc:	7902                	ld	s2,32(sp)
ffffffffc02020be:	69e2                	ld	s3,24(sp)
ffffffffc02020c0:	6a42                	ld	s4,16(sp)
ffffffffc02020c2:	6aa2                	ld	s5,8(sp)
ffffffffc02020c4:	6b02                	ld	s6,0(sp)
ffffffffc02020c6:	6121                	addi	sp,sp,64
ffffffffc02020c8:	8082                	ret
            return NULL;
ffffffffc02020ca:	4501                	li	a0,0
ffffffffc02020cc:	b7ed                	j	ffffffffc02020b6 <get_pte+0x156>
    pde_t *pdep0 = &((pde_t *)KADDR(PDE_ADDR(*pdep1)))[PDX0(la)];
ffffffffc02020ce:	00005617          	auipc	a2,0x5
ffffffffc02020d2:	2d260613          	addi	a2,a2,722 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc02020d6:	0e300593          	li	a1,227
ffffffffc02020da:	00005517          	auipc	a0,0x5
ffffffffc02020de:	3d650513          	addi	a0,a0,982 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc02020e2:	ba2fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    return &((pte_t *)KADDR(PDE_ADDR(*pdep0)))[PTX(la)];
ffffffffc02020e6:	00005617          	auipc	a2,0x5
ffffffffc02020ea:	2ba60613          	addi	a2,a2,698 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc02020ee:	0ee00593          	li	a1,238
ffffffffc02020f2:	00005517          	auipc	a0,0x5
ffffffffc02020f6:	3be50513          	addi	a0,a0,958 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc02020fa:	b8afe0ef          	jal	ra,ffffffffc0200484 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc02020fe:	86aa                	mv	a3,a0
ffffffffc0202100:	00005617          	auipc	a2,0x5
ffffffffc0202104:	2a060613          	addi	a2,a2,672 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0202108:	0eb00593          	li	a1,235
ffffffffc020210c:	00005517          	auipc	a0,0x5
ffffffffc0202110:	3a450513          	addi	a0,a0,932 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202114:	b70fe0ef          	jal	ra,ffffffffc0200484 <__panic>
        memset(KADDR(pa), 0, PGSIZE);
ffffffffc0202118:	86aa                	mv	a3,a0
ffffffffc020211a:	00005617          	auipc	a2,0x5
ffffffffc020211e:	28660613          	addi	a2,a2,646 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0202122:	0df00593          	li	a1,223
ffffffffc0202126:	00005517          	auipc	a0,0x5
ffffffffc020212a:	38a50513          	addi	a0,a0,906 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc020212e:	b56fe0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0202132 <get_page>:

// get_page - get related Page struct for linear address la using PDT pgdir
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc0202132:	1141                	addi	sp,sp,-16
ffffffffc0202134:	e022                	sd	s0,0(sp)
ffffffffc0202136:	8432                	mv	s0,a2
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202138:	4601                	li	a2,0
struct Page *get_page(pde_t *pgdir, uintptr_t la, pte_t **ptep_store) {
ffffffffc020213a:	e406                	sd	ra,8(sp)
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020213c:	e25ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    if (ptep_store != NULL) {
ffffffffc0202140:	c011                	beqz	s0,ffffffffc0202144 <get_page+0x12>
        *ptep_store = ptep;
ffffffffc0202142:	e008                	sd	a0,0(s0)
    }
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc0202144:	c129                	beqz	a0,ffffffffc0202186 <get_page+0x54>
ffffffffc0202146:	611c                	ld	a5,0(a0)
        return pte2page(*ptep);
    }
    return NULL;
ffffffffc0202148:	4501                	li	a0,0
    if (ptep != NULL && *ptep & PTE_V) {
ffffffffc020214a:	0017f713          	andi	a4,a5,1
ffffffffc020214e:	e709                	bnez	a4,ffffffffc0202158 <get_page+0x26>
}
ffffffffc0202150:	60a2                	ld	ra,8(sp)
ffffffffc0202152:	6402                	ld	s0,0(sp)
ffffffffc0202154:	0141                	addi	sp,sp,16
ffffffffc0202156:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202158:	000aa717          	auipc	a4,0xaa
ffffffffc020215c:	35070713          	addi	a4,a4,848 # ffffffffc02ac4a8 <npage>
ffffffffc0202160:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202162:	078a                	slli	a5,a5,0x2
ffffffffc0202164:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202166:	02e7f563          	bleu	a4,a5,ffffffffc0202190 <get_page+0x5e>
    return &pages[PPN(pa) - nbase];
ffffffffc020216a:	000aa717          	auipc	a4,0xaa
ffffffffc020216e:	3ae70713          	addi	a4,a4,942 # ffffffffc02ac518 <pages>
ffffffffc0202172:	6308                	ld	a0,0(a4)
ffffffffc0202174:	60a2                	ld	ra,8(sp)
ffffffffc0202176:	6402                	ld	s0,0(sp)
ffffffffc0202178:	fff80737          	lui	a4,0xfff80
ffffffffc020217c:	97ba                	add	a5,a5,a4
ffffffffc020217e:	079a                	slli	a5,a5,0x6
ffffffffc0202180:	953e                	add	a0,a0,a5
ffffffffc0202182:	0141                	addi	sp,sp,16
ffffffffc0202184:	8082                	ret
ffffffffc0202186:	60a2                	ld	ra,8(sp)
ffffffffc0202188:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc020218a:	4501                	li	a0,0
}
ffffffffc020218c:	0141                	addi	sp,sp,16
ffffffffc020218e:	8082                	ret
ffffffffc0202190:	ca7ff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc0202194 <unmap_range>:
        *ptep = 0;                  //(5) clear second page table entry
        tlb_invalidate(pgdir, la);  //(6) flush tlb
    }
}

void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc0202194:	711d                	addi	sp,sp,-96
    //检查start和end是否是PGSIZE的整数倍(按页分配内存)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202196:	00c5e7b3          	or	a5,a1,a2
void unmap_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc020219a:	ec86                	sd	ra,88(sp)
ffffffffc020219c:	e8a2                	sd	s0,80(sp)
ffffffffc020219e:	e4a6                	sd	s1,72(sp)
ffffffffc02021a0:	e0ca                	sd	s2,64(sp)
ffffffffc02021a2:	fc4e                	sd	s3,56(sp)
ffffffffc02021a4:	f852                	sd	s4,48(sp)
ffffffffc02021a6:	f456                	sd	s5,40(sp)
ffffffffc02021a8:	f05a                	sd	s6,32(sp)
ffffffffc02021aa:	ec5e                	sd	s7,24(sp)
ffffffffc02021ac:	e862                	sd	s8,16(sp)
ffffffffc02021ae:	e466                	sd	s9,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02021b0:	03479713          	slli	a4,a5,0x34
ffffffffc02021b4:	eb71                	bnez	a4,ffffffffc0202288 <unmap_range+0xf4>
    assert(USER_ACCESS(start, end));
ffffffffc02021b6:	002007b7          	lui	a5,0x200
ffffffffc02021ba:	842e                	mv	s0,a1
ffffffffc02021bc:	0af5e663          	bltu	a1,a5,ffffffffc0202268 <unmap_range+0xd4>
ffffffffc02021c0:	8932                	mv	s2,a2
ffffffffc02021c2:	0ac5f363          	bleu	a2,a1,ffffffffc0202268 <unmap_range+0xd4>
ffffffffc02021c6:	4785                	li	a5,1
ffffffffc02021c8:	07fe                	slli	a5,a5,0x1f
ffffffffc02021ca:	08c7ef63          	bltu	a5,a2,ffffffffc0202268 <unmap_range+0xd4>
ffffffffc02021ce:	89aa                	mv	s3,a0
            continue;
        }
        if (*ptep != 0) {
            page_remove_pte(pgdir, start, ptep);
        }
        start += PGSIZE;
ffffffffc02021d0:	6a05                	lui	s4,0x1
    if (PPN(pa) >= npage) {
ffffffffc02021d2:	000aac97          	auipc	s9,0xaa
ffffffffc02021d6:	2d6c8c93          	addi	s9,s9,726 # ffffffffc02ac4a8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc02021da:	000aac17          	auipc	s8,0xaa
ffffffffc02021de:	33ec0c13          	addi	s8,s8,830 # ffffffffc02ac518 <pages>
ffffffffc02021e2:	fff80bb7          	lui	s7,0xfff80
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02021e6:	00200b37          	lui	s6,0x200
ffffffffc02021ea:	ffe00ab7          	lui	s5,0xffe00
        pte_t *ptep = get_pte(pgdir, start, 0);
ffffffffc02021ee:	4601                	li	a2,0
ffffffffc02021f0:	85a2                	mv	a1,s0
ffffffffc02021f2:	854e                	mv	a0,s3
ffffffffc02021f4:	d6dff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02021f8:	84aa                	mv	s1,a0
        if (ptep == NULL) {
ffffffffc02021fa:	cd21                	beqz	a0,ffffffffc0202252 <unmap_range+0xbe>
        if (*ptep != 0) {
ffffffffc02021fc:	611c                	ld	a5,0(a0)
ffffffffc02021fe:	e38d                	bnez	a5,ffffffffc0202220 <unmap_range+0x8c>
        start += PGSIZE;
ffffffffc0202200:	9452                	add	s0,s0,s4
    } while (start != 0 && start < end);
ffffffffc0202202:	ff2466e3          	bltu	s0,s2,ffffffffc02021ee <unmap_range+0x5a>
}
ffffffffc0202206:	60e6                	ld	ra,88(sp)
ffffffffc0202208:	6446                	ld	s0,80(sp)
ffffffffc020220a:	64a6                	ld	s1,72(sp)
ffffffffc020220c:	6906                	ld	s2,64(sp)
ffffffffc020220e:	79e2                	ld	s3,56(sp)
ffffffffc0202210:	7a42                	ld	s4,48(sp)
ffffffffc0202212:	7aa2                	ld	s5,40(sp)
ffffffffc0202214:	7b02                	ld	s6,32(sp)
ffffffffc0202216:	6be2                	ld	s7,24(sp)
ffffffffc0202218:	6c42                	ld	s8,16(sp)
ffffffffc020221a:	6ca2                	ld	s9,8(sp)
ffffffffc020221c:	6125                	addi	sp,sp,96
ffffffffc020221e:	8082                	ret
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0202220:	0017f713          	andi	a4,a5,1
ffffffffc0202224:	df71                	beqz	a4,ffffffffc0202200 <unmap_range+0x6c>
    if (PPN(pa) >= npage) {
ffffffffc0202226:	000cb703          	ld	a4,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc020222a:	078a                	slli	a5,a5,0x2
ffffffffc020222c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020222e:	06e7fd63          	bleu	a4,a5,ffffffffc02022a8 <unmap_range+0x114>
    return &pages[PPN(pa) - nbase];
ffffffffc0202232:	000c3503          	ld	a0,0(s8)
ffffffffc0202236:	97de                	add	a5,a5,s7
ffffffffc0202238:	079a                	slli	a5,a5,0x6
ffffffffc020223a:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020223c:	411c                	lw	a5,0(a0)
ffffffffc020223e:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202242:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202244:	cf11                	beqz	a4,ffffffffc0202260 <unmap_range+0xcc>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0202246:	0004b023          	sd	zero,0(s1)
}

// invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
void tlb_invalidate(pde_t *pgdir, uintptr_t la) {
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020224a:	12040073          	sfence.vma	s0
        start += PGSIZE;
ffffffffc020224e:	9452                	add	s0,s0,s4
ffffffffc0202250:	bf4d                	j	ffffffffc0202202 <unmap_range+0x6e>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc0202252:	945a                	add	s0,s0,s6
ffffffffc0202254:	01547433          	and	s0,s0,s5
    } while (start != 0 && start < end);
ffffffffc0202258:	d45d                	beqz	s0,ffffffffc0202206 <unmap_range+0x72>
ffffffffc020225a:	f9246ae3          	bltu	s0,s2,ffffffffc02021ee <unmap_range+0x5a>
ffffffffc020225e:	b765                	j	ffffffffc0202206 <unmap_range+0x72>
            free_page(page);
ffffffffc0202260:	4585                	li	a1,1
ffffffffc0202262:	c79ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc0202266:	b7c5                	j	ffffffffc0202246 <unmap_range+0xb2>
    assert(USER_ACCESS(start, end));
ffffffffc0202268:	00005697          	auipc	a3,0x5
ffffffffc020226c:	7f068693          	addi	a3,a3,2032 # ffffffffc0207a58 <default_pmm_manager+0x708>
ffffffffc0202270:	00005617          	auipc	a2,0x5
ffffffffc0202274:	99860613          	addi	a2,a2,-1640 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202278:	11100593          	li	a1,273
ffffffffc020227c:	00005517          	auipc	a0,0x5
ffffffffc0202280:	23450513          	addi	a0,a0,564 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202284:	a00fe0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202288:	00005697          	auipc	a3,0x5
ffffffffc020228c:	7a068693          	addi	a3,a3,1952 # ffffffffc0207a28 <default_pmm_manager+0x6d8>
ffffffffc0202290:	00005617          	auipc	a2,0x5
ffffffffc0202294:	97860613          	addi	a2,a2,-1672 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202298:	11000593          	li	a1,272
ffffffffc020229c:	00005517          	auipc	a0,0x5
ffffffffc02022a0:	21450513          	addi	a0,a0,532 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc02022a4:	9e0fe0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc02022a8:	b8fff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc02022ac <exit_range>:
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02022ac:	7119                	addi	sp,sp,-128
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022ae:	00c5e7b3          	or	a5,a1,a2
void exit_range(pde_t *pgdir, uintptr_t start, uintptr_t end) {
ffffffffc02022b2:	fc86                	sd	ra,120(sp)
ffffffffc02022b4:	f8a2                	sd	s0,112(sp)
ffffffffc02022b6:	f4a6                	sd	s1,104(sp)
ffffffffc02022b8:	f0ca                	sd	s2,96(sp)
ffffffffc02022ba:	ecce                	sd	s3,88(sp)
ffffffffc02022bc:	e8d2                	sd	s4,80(sp)
ffffffffc02022be:	e4d6                	sd	s5,72(sp)
ffffffffc02022c0:	e0da                	sd	s6,64(sp)
ffffffffc02022c2:	fc5e                	sd	s7,56(sp)
ffffffffc02022c4:	f862                	sd	s8,48(sp)
ffffffffc02022c6:	f466                	sd	s9,40(sp)
ffffffffc02022c8:	f06a                	sd	s10,32(sp)
ffffffffc02022ca:	ec6e                	sd	s11,24(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02022cc:	03479713          	slli	a4,a5,0x34
ffffffffc02022d0:	1c071163          	bnez	a4,ffffffffc0202492 <exit_range+0x1e6>
    assert(USER_ACCESS(start, end));
ffffffffc02022d4:	002007b7          	lui	a5,0x200
ffffffffc02022d8:	20f5e563          	bltu	a1,a5,ffffffffc02024e2 <exit_range+0x236>
ffffffffc02022dc:	8b32                	mv	s6,a2
ffffffffc02022de:	20c5f263          	bleu	a2,a1,ffffffffc02024e2 <exit_range+0x236>
ffffffffc02022e2:	4785                	li	a5,1
ffffffffc02022e4:	07fe                	slli	a5,a5,0x1f
ffffffffc02022e6:	1ec7ee63          	bltu	a5,a2,ffffffffc02024e2 <exit_range+0x236>
    d1start = ROUNDDOWN(start, PDSIZE);
ffffffffc02022ea:	c00009b7          	lui	s3,0xc0000
ffffffffc02022ee:	400007b7          	lui	a5,0x40000
ffffffffc02022f2:	0135f9b3          	and	s3,a1,s3
ffffffffc02022f6:	99be                	add	s3,s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc02022f8:	c0000337          	lui	t1,0xc0000
ffffffffc02022fc:	00698933          	add	s2,s3,t1
ffffffffc0202300:	01e95913          	srli	s2,s2,0x1e
ffffffffc0202304:	1ff97913          	andi	s2,s2,511
ffffffffc0202308:	8e2a                	mv	t3,a0
ffffffffc020230a:	090e                	slli	s2,s2,0x3
ffffffffc020230c:	9972                	add	s2,s2,t3
ffffffffc020230e:	00093b83          	ld	s7,0(s2)
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc0202312:	ffe004b7          	lui	s1,0xffe00
    return KADDR(page2pa(page));
ffffffffc0202316:	5dfd                	li	s11,-1
        if (pde1&PTE_V){
ffffffffc0202318:	001bf793          	andi	a5,s7,1
    d0start = ROUNDDOWN(start, PTSIZE);
ffffffffc020231c:	8ced                	and	s1,s1,a1
    if (PPN(pa) >= npage) {
ffffffffc020231e:	000aad17          	auipc	s10,0xaa
ffffffffc0202322:	18ad0d13          	addi	s10,s10,394 # ffffffffc02ac4a8 <npage>
    return KADDR(page2pa(page));
ffffffffc0202326:	00cddd93          	srli	s11,s11,0xc
ffffffffc020232a:	000aa717          	auipc	a4,0xaa
ffffffffc020232e:	1de70713          	addi	a4,a4,478 # ffffffffc02ac508 <va_pa_offset>
    return &pages[PPN(pa) - nbase];
ffffffffc0202332:	000aae97          	auipc	t4,0xaa
ffffffffc0202336:	1e6e8e93          	addi	t4,t4,486 # ffffffffc02ac518 <pages>
        if (pde1&PTE_V){
ffffffffc020233a:	e79d                	bnez	a5,ffffffffc0202368 <exit_range+0xbc>
    } while (d1start != 0 && d1start < end);
ffffffffc020233c:	12098963          	beqz	s3,ffffffffc020246e <exit_range+0x1c2>
ffffffffc0202340:	400007b7          	lui	a5,0x40000
ffffffffc0202344:	84ce                	mv	s1,s3
ffffffffc0202346:	97ce                	add	a5,a5,s3
ffffffffc0202348:	1369f363          	bleu	s6,s3,ffffffffc020246e <exit_range+0x1c2>
ffffffffc020234c:	89be                	mv	s3,a5
        pde1 = pgdir[PDX1(d1start)];
ffffffffc020234e:	00698933          	add	s2,s3,t1
ffffffffc0202352:	01e95913          	srli	s2,s2,0x1e
ffffffffc0202356:	1ff97913          	andi	s2,s2,511
ffffffffc020235a:	090e                	slli	s2,s2,0x3
ffffffffc020235c:	9972                	add	s2,s2,t3
ffffffffc020235e:	00093b83          	ld	s7,0(s2)
        if (pde1&PTE_V){
ffffffffc0202362:	001bf793          	andi	a5,s7,1
ffffffffc0202366:	dbf9                	beqz	a5,ffffffffc020233c <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0202368:	000d3783          	ld	a5,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc020236c:	0b8a                	slli	s7,s7,0x2
ffffffffc020236e:	00cbdb93          	srli	s7,s7,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202372:	14fbfc63          	bleu	a5,s7,ffffffffc02024ca <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202376:	fff80ab7          	lui	s5,0xfff80
ffffffffc020237a:	9ade                	add	s5,s5,s7
    return page - pages + nbase;
ffffffffc020237c:	000806b7          	lui	a3,0x80
ffffffffc0202380:	96d6                	add	a3,a3,s5
ffffffffc0202382:	006a9593          	slli	a1,s5,0x6
    return KADDR(page2pa(page));
ffffffffc0202386:	01b6f633          	and	a2,a3,s11
    return page - pages + nbase;
ffffffffc020238a:	e42e                	sd	a1,8(sp)
    return page2ppn(page) << PGSHIFT;
ffffffffc020238c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020238e:	12f67263          	bleu	a5,a2,ffffffffc02024b2 <exit_range+0x206>
ffffffffc0202392:	00073a03          	ld	s4,0(a4)
            free_pd0 = 1;
ffffffffc0202396:	4c85                	li	s9,1
    return &pages[PPN(pa) - nbase];
ffffffffc0202398:	fff808b7          	lui	a7,0xfff80
    return KADDR(page2pa(page));
ffffffffc020239c:	9a36                	add	s4,s4,a3
    return page - pages + nbase;
ffffffffc020239e:	00080837          	lui	a6,0x80
ffffffffc02023a2:	6a85                	lui	s5,0x1
                d0start += PTSIZE;
ffffffffc02023a4:	00200c37          	lui	s8,0x200
ffffffffc02023a8:	a801                	j	ffffffffc02023b8 <exit_range+0x10c>
                    free_pd0 = 0;
ffffffffc02023aa:	4c81                	li	s9,0
                d0start += PTSIZE;
ffffffffc02023ac:	94e2                	add	s1,s1,s8
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc02023ae:	c0d9                	beqz	s1,ffffffffc0202434 <exit_range+0x188>
ffffffffc02023b0:	0934f263          	bleu	s3,s1,ffffffffc0202434 <exit_range+0x188>
ffffffffc02023b4:	0d64fc63          	bleu	s6,s1,ffffffffc020248c <exit_range+0x1e0>
                pde0 = pd0[PDX0(d0start)];
ffffffffc02023b8:	0154d413          	srli	s0,s1,0x15
ffffffffc02023bc:	1ff47413          	andi	s0,s0,511
ffffffffc02023c0:	040e                	slli	s0,s0,0x3
ffffffffc02023c2:	9452                	add	s0,s0,s4
ffffffffc02023c4:	601c                	ld	a5,0(s0)
                if (pde0&PTE_V) {
ffffffffc02023c6:	0017f693          	andi	a3,a5,1
ffffffffc02023ca:	d2e5                	beqz	a3,ffffffffc02023aa <exit_range+0xfe>
    if (PPN(pa) >= npage) {
ffffffffc02023cc:	000d3583          	ld	a1,0(s10)
    return pa2page(PDE_ADDR(pde));
ffffffffc02023d0:	00279513          	slli	a0,a5,0x2
ffffffffc02023d4:	8131                	srli	a0,a0,0xc
    if (PPN(pa) >= npage) {
ffffffffc02023d6:	0eb57a63          	bleu	a1,a0,ffffffffc02024ca <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc02023da:	9546                	add	a0,a0,a7
    return page - pages + nbase;
ffffffffc02023dc:	010506b3          	add	a3,a0,a6
    return KADDR(page2pa(page));
ffffffffc02023e0:	01b6f7b3          	and	a5,a3,s11
    return page - pages + nbase;
ffffffffc02023e4:	051a                	slli	a0,a0,0x6
    return page2ppn(page) << PGSHIFT;
ffffffffc02023e6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02023e8:	0cb7f563          	bleu	a1,a5,ffffffffc02024b2 <exit_range+0x206>
ffffffffc02023ec:	631c                	ld	a5,0(a4)
ffffffffc02023ee:	96be                	add	a3,a3,a5
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc02023f0:	015685b3          	add	a1,a3,s5
                        if (pt[i]&PTE_V){
ffffffffc02023f4:	629c                	ld	a5,0(a3)
ffffffffc02023f6:	8b85                	andi	a5,a5,1
ffffffffc02023f8:	fbd5                	bnez	a5,ffffffffc02023ac <exit_range+0x100>
ffffffffc02023fa:	06a1                	addi	a3,a3,8
                    for (int i = 0;i <NPTEENTRY;i++)
ffffffffc02023fc:	fed59ce3          	bne	a1,a3,ffffffffc02023f4 <exit_range+0x148>
    return &pages[PPN(pa) - nbase];
ffffffffc0202400:	000eb783          	ld	a5,0(t4)
                        free_page(pde2page(pde0));
ffffffffc0202404:	4585                	li	a1,1
ffffffffc0202406:	e072                	sd	t3,0(sp)
ffffffffc0202408:	953e                	add	a0,a0,a5
ffffffffc020240a:	ad1ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
                d0start += PTSIZE;
ffffffffc020240e:	94e2                	add	s1,s1,s8
                        pd0[PDX0(d0start)] = 0;
ffffffffc0202410:	00043023          	sd	zero,0(s0)
ffffffffc0202414:	000aae97          	auipc	t4,0xaa
ffffffffc0202418:	104e8e93          	addi	t4,t4,260 # ffffffffc02ac518 <pages>
ffffffffc020241c:	6e02                	ld	t3,0(sp)
ffffffffc020241e:	c0000337          	lui	t1,0xc0000
ffffffffc0202422:	fff808b7          	lui	a7,0xfff80
ffffffffc0202426:	00080837          	lui	a6,0x80
ffffffffc020242a:	000aa717          	auipc	a4,0xaa
ffffffffc020242e:	0de70713          	addi	a4,a4,222 # ffffffffc02ac508 <va_pa_offset>
            } while (d0start != 0 && d0start < d1start+PDSIZE && d0start < end);
ffffffffc0202432:	fcbd                	bnez	s1,ffffffffc02023b0 <exit_range+0x104>
            if (free_pd0) {
ffffffffc0202434:	f00c84e3          	beqz	s9,ffffffffc020233c <exit_range+0x90>
    if (PPN(pa) >= npage) {
ffffffffc0202438:	000d3783          	ld	a5,0(s10)
ffffffffc020243c:	e072                	sd	t3,0(sp)
ffffffffc020243e:	08fbf663          	bleu	a5,s7,ffffffffc02024ca <exit_range+0x21e>
    return &pages[PPN(pa) - nbase];
ffffffffc0202442:	000eb503          	ld	a0,0(t4)
                free_page(pde2page(pde1));
ffffffffc0202446:	67a2                	ld	a5,8(sp)
ffffffffc0202448:	4585                	li	a1,1
ffffffffc020244a:	953e                	add	a0,a0,a5
ffffffffc020244c:	a8fff0ef          	jal	ra,ffffffffc0201eda <free_pages>
                pgdir[PDX1(d1start)] = 0;
ffffffffc0202450:	00093023          	sd	zero,0(s2)
ffffffffc0202454:	000aa717          	auipc	a4,0xaa
ffffffffc0202458:	0b470713          	addi	a4,a4,180 # ffffffffc02ac508 <va_pa_offset>
ffffffffc020245c:	c0000337          	lui	t1,0xc0000
ffffffffc0202460:	6e02                	ld	t3,0(sp)
ffffffffc0202462:	000aae97          	auipc	t4,0xaa
ffffffffc0202466:	0b6e8e93          	addi	t4,t4,182 # ffffffffc02ac518 <pages>
    } while (d1start != 0 && d1start < end);
ffffffffc020246a:	ec099be3          	bnez	s3,ffffffffc0202340 <exit_range+0x94>
}
ffffffffc020246e:	70e6                	ld	ra,120(sp)
ffffffffc0202470:	7446                	ld	s0,112(sp)
ffffffffc0202472:	74a6                	ld	s1,104(sp)
ffffffffc0202474:	7906                	ld	s2,96(sp)
ffffffffc0202476:	69e6                	ld	s3,88(sp)
ffffffffc0202478:	6a46                	ld	s4,80(sp)
ffffffffc020247a:	6aa6                	ld	s5,72(sp)
ffffffffc020247c:	6b06                	ld	s6,64(sp)
ffffffffc020247e:	7be2                	ld	s7,56(sp)
ffffffffc0202480:	7c42                	ld	s8,48(sp)
ffffffffc0202482:	7ca2                	ld	s9,40(sp)
ffffffffc0202484:	7d02                	ld	s10,32(sp)
ffffffffc0202486:	6de2                	ld	s11,24(sp)
ffffffffc0202488:	6109                	addi	sp,sp,128
ffffffffc020248a:	8082                	ret
            if (free_pd0) {
ffffffffc020248c:	ea0c8ae3          	beqz	s9,ffffffffc0202340 <exit_range+0x94>
ffffffffc0202490:	b765                	j	ffffffffc0202438 <exit_range+0x18c>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc0202492:	00005697          	auipc	a3,0x5
ffffffffc0202496:	59668693          	addi	a3,a3,1430 # ffffffffc0207a28 <default_pmm_manager+0x6d8>
ffffffffc020249a:	00004617          	auipc	a2,0x4
ffffffffc020249e:	76e60613          	addi	a2,a2,1902 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02024a2:	12200593          	li	a1,290
ffffffffc02024a6:	00005517          	auipc	a0,0x5
ffffffffc02024aa:	00a50513          	addi	a0,a0,10 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc02024ae:	fd7fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc02024b2:	00005617          	auipc	a2,0x5
ffffffffc02024b6:	eee60613          	addi	a2,a2,-274 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc02024ba:	06900593          	li	a1,105
ffffffffc02024be:	00005517          	auipc	a0,0x5
ffffffffc02024c2:	f0a50513          	addi	a0,a0,-246 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc02024c6:	fbffd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02024ca:	00005617          	auipc	a2,0x5
ffffffffc02024ce:	f3660613          	addi	a2,a2,-202 # ffffffffc0207400 <default_pmm_manager+0xb0>
ffffffffc02024d2:	06200593          	li	a1,98
ffffffffc02024d6:	00005517          	auipc	a0,0x5
ffffffffc02024da:	ef250513          	addi	a0,a0,-270 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc02024de:	fa7fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc02024e2:	00005697          	auipc	a3,0x5
ffffffffc02024e6:	57668693          	addi	a3,a3,1398 # ffffffffc0207a58 <default_pmm_manager+0x708>
ffffffffc02024ea:	00004617          	auipc	a2,0x4
ffffffffc02024ee:	71e60613          	addi	a2,a2,1822 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02024f2:	12300593          	li	a1,291
ffffffffc02024f6:	00005517          	auipc	a0,0x5
ffffffffc02024fa:	fba50513          	addi	a0,a0,-70 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc02024fe:	f87fd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0202502 <page_remove>:
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202502:	1101                	addi	sp,sp,-32
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc0202504:	4601                	li	a2,0
void page_remove(pde_t *pgdir, uintptr_t la) {
ffffffffc0202506:	e426                	sd	s1,8(sp)
ffffffffc0202508:	ec06                	sd	ra,24(sp)
ffffffffc020250a:	e822                	sd	s0,16(sp)
ffffffffc020250c:	84ae                	mv	s1,a1
    pte_t *ptep = get_pte(pgdir, la, 0);
ffffffffc020250e:	a53ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    if (ptep != NULL) {
ffffffffc0202512:	c511                	beqz	a0,ffffffffc020251e <page_remove+0x1c>
    if (*ptep & PTE_V) {  //(1) check if this page table entry is
ffffffffc0202514:	611c                	ld	a5,0(a0)
ffffffffc0202516:	842a                	mv	s0,a0
ffffffffc0202518:	0017f713          	andi	a4,a5,1
ffffffffc020251c:	e711                	bnez	a4,ffffffffc0202528 <page_remove+0x26>
}
ffffffffc020251e:	60e2                	ld	ra,24(sp)
ffffffffc0202520:	6442                	ld	s0,16(sp)
ffffffffc0202522:	64a2                	ld	s1,8(sp)
ffffffffc0202524:	6105                	addi	sp,sp,32
ffffffffc0202526:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc0202528:	000aa717          	auipc	a4,0xaa
ffffffffc020252c:	f8070713          	addi	a4,a4,-128 # ffffffffc02ac4a8 <npage>
ffffffffc0202530:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202532:	078a                	slli	a5,a5,0x2
ffffffffc0202534:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202536:	02e7fe63          	bleu	a4,a5,ffffffffc0202572 <page_remove+0x70>
    return &pages[PPN(pa) - nbase];
ffffffffc020253a:	000aa717          	auipc	a4,0xaa
ffffffffc020253e:	fde70713          	addi	a4,a4,-34 # ffffffffc02ac518 <pages>
ffffffffc0202542:	6308                	ld	a0,0(a4)
ffffffffc0202544:	fff80737          	lui	a4,0xfff80
ffffffffc0202548:	97ba                	add	a5,a5,a4
ffffffffc020254a:	079a                	slli	a5,a5,0x6
ffffffffc020254c:	953e                	add	a0,a0,a5
    page->ref -= 1;
ffffffffc020254e:	411c                	lw	a5,0(a0)
ffffffffc0202550:	fff7871b          	addiw	a4,a5,-1
ffffffffc0202554:	c118                	sw	a4,0(a0)
        if (page_ref(page) ==
ffffffffc0202556:	cb11                	beqz	a4,ffffffffc020256a <page_remove+0x68>
        *ptep = 0;                  //(5) clear second page table entry
ffffffffc0202558:	00043023          	sd	zero,0(s0)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc020255c:	12048073          	sfence.vma	s1
}
ffffffffc0202560:	60e2                	ld	ra,24(sp)
ffffffffc0202562:	6442                	ld	s0,16(sp)
ffffffffc0202564:	64a2                	ld	s1,8(sp)
ffffffffc0202566:	6105                	addi	sp,sp,32
ffffffffc0202568:	8082                	ret
            free_page(page);
ffffffffc020256a:	4585                	li	a1,1
ffffffffc020256c:	96fff0ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc0202570:	b7e5                	j	ffffffffc0202558 <page_remove+0x56>
ffffffffc0202572:	8c5ff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc0202576 <page_insert>:
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202576:	7179                	addi	sp,sp,-48
ffffffffc0202578:	e44e                	sd	s3,8(sp)
ffffffffc020257a:	89b2                	mv	s3,a2
ffffffffc020257c:	f022                	sd	s0,32(sp)
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020257e:	4605                	li	a2,1
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202580:	842e                	mv	s0,a1
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc0202582:	85ce                	mv	a1,s3
int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm) {
ffffffffc0202584:	ec26                	sd	s1,24(sp)
ffffffffc0202586:	f406                	sd	ra,40(sp)
ffffffffc0202588:	e84a                	sd	s2,16(sp)
ffffffffc020258a:	e052                	sd	s4,0(sp)
ffffffffc020258c:	84b6                	mv	s1,a3
    pte_t *ptep = get_pte(pgdir, la, 1);
ffffffffc020258e:	9d3ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    if (ptep == NULL) {
ffffffffc0202592:	cd49                	beqz	a0,ffffffffc020262c <page_insert+0xb6>
    page->ref += 1;
ffffffffc0202594:	4014                	lw	a3,0(s0)
    if (*ptep & PTE_V) {
ffffffffc0202596:	611c                	ld	a5,0(a0)
ffffffffc0202598:	892a                	mv	s2,a0
ffffffffc020259a:	0016871b          	addiw	a4,a3,1
ffffffffc020259e:	c018                	sw	a4,0(s0)
ffffffffc02025a0:	0017f713          	andi	a4,a5,1
ffffffffc02025a4:	ef05                	bnez	a4,ffffffffc02025dc <page_insert+0x66>
ffffffffc02025a6:	000aa797          	auipc	a5,0xaa
ffffffffc02025aa:	f7278793          	addi	a5,a5,-142 # ffffffffc02ac518 <pages>
ffffffffc02025ae:	6398                	ld	a4,0(a5)
    return page - pages + nbase;
ffffffffc02025b0:	8c19                	sub	s0,s0,a4
ffffffffc02025b2:	000806b7          	lui	a3,0x80
ffffffffc02025b6:	8419                	srai	s0,s0,0x6
ffffffffc02025b8:	9436                	add	s0,s0,a3
  return (ppn << PTE_PPN_SHIFT) | PTE_V | type;
ffffffffc02025ba:	042a                	slli	s0,s0,0xa
ffffffffc02025bc:	8c45                	or	s0,s0,s1
ffffffffc02025be:	00146413          	ori	s0,s0,1
    *ptep = pte_create(page2ppn(page), PTE_V | perm);
ffffffffc02025c2:	00893023          	sd	s0,0(s2)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02025c6:	12098073          	sfence.vma	s3
    return 0;
ffffffffc02025ca:	4501                	li	a0,0
}
ffffffffc02025cc:	70a2                	ld	ra,40(sp)
ffffffffc02025ce:	7402                	ld	s0,32(sp)
ffffffffc02025d0:	64e2                	ld	s1,24(sp)
ffffffffc02025d2:	6942                	ld	s2,16(sp)
ffffffffc02025d4:	69a2                	ld	s3,8(sp)
ffffffffc02025d6:	6a02                	ld	s4,0(sp)
ffffffffc02025d8:	6145                	addi	sp,sp,48
ffffffffc02025da:	8082                	ret
    if (PPN(pa) >= npage) {
ffffffffc02025dc:	000aa717          	auipc	a4,0xaa
ffffffffc02025e0:	ecc70713          	addi	a4,a4,-308 # ffffffffc02ac4a8 <npage>
ffffffffc02025e4:	6318                	ld	a4,0(a4)
    return pa2page(PTE_ADDR(pte));
ffffffffc02025e6:	078a                	slli	a5,a5,0x2
ffffffffc02025e8:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02025ea:	04e7f363          	bleu	a4,a5,ffffffffc0202630 <page_insert+0xba>
    return &pages[PPN(pa) - nbase];
ffffffffc02025ee:	000aaa17          	auipc	s4,0xaa
ffffffffc02025f2:	f2aa0a13          	addi	s4,s4,-214 # ffffffffc02ac518 <pages>
ffffffffc02025f6:	000a3703          	ld	a4,0(s4)
ffffffffc02025fa:	fff80537          	lui	a0,0xfff80
ffffffffc02025fe:	953e                	add	a0,a0,a5
ffffffffc0202600:	051a                	slli	a0,a0,0x6
ffffffffc0202602:	953a                	add	a0,a0,a4
        if (p == page) {
ffffffffc0202604:	00a40a63          	beq	s0,a0,ffffffffc0202618 <page_insert+0xa2>
    page->ref -= 1;
ffffffffc0202608:	411c                	lw	a5,0(a0)
ffffffffc020260a:	fff7869b          	addiw	a3,a5,-1
ffffffffc020260e:	c114                	sw	a3,0(a0)
        if (page_ref(page) ==
ffffffffc0202610:	c691                	beqz	a3,ffffffffc020261c <page_insert+0xa6>
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202612:	12098073          	sfence.vma	s3
ffffffffc0202616:	bf69                	j	ffffffffc02025b0 <page_insert+0x3a>
ffffffffc0202618:	c014                	sw	a3,0(s0)
    return page->ref;
ffffffffc020261a:	bf59                	j	ffffffffc02025b0 <page_insert+0x3a>
            free_page(page);
ffffffffc020261c:	4585                	li	a1,1
ffffffffc020261e:	8bdff0ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc0202622:	000a3703          	ld	a4,0(s4)
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc0202626:	12098073          	sfence.vma	s3
ffffffffc020262a:	b759                	j	ffffffffc02025b0 <page_insert+0x3a>
        return -E_NO_MEM;
ffffffffc020262c:	5571                	li	a0,-4
ffffffffc020262e:	bf79                	j	ffffffffc02025cc <page_insert+0x56>
ffffffffc0202630:	807ff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>

ffffffffc0202634 <pmm_init>:
    pmm_manager = &default_pmm_manager;
ffffffffc0202634:	00005797          	auipc	a5,0x5
ffffffffc0202638:	d1c78793          	addi	a5,a5,-740 # ffffffffc0207350 <default_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020263c:	638c                	ld	a1,0(a5)
void pmm_init(void) {
ffffffffc020263e:	715d                	addi	sp,sp,-80
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0202640:	00005517          	auipc	a0,0x5
ffffffffc0202644:	e9850513          	addi	a0,a0,-360 # ffffffffc02074d8 <default_pmm_manager+0x188>
void pmm_init(void) {
ffffffffc0202648:	e486                	sd	ra,72(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc020264a:	000aa717          	auipc	a4,0xaa
ffffffffc020264e:	eaf73b23          	sd	a5,-330(a4) # ffffffffc02ac500 <pmm_manager>
void pmm_init(void) {
ffffffffc0202652:	e0a2                	sd	s0,64(sp)
ffffffffc0202654:	fc26                	sd	s1,56(sp)
ffffffffc0202656:	f84a                	sd	s2,48(sp)
ffffffffc0202658:	f44e                	sd	s3,40(sp)
ffffffffc020265a:	f052                	sd	s4,32(sp)
ffffffffc020265c:	ec56                	sd	s5,24(sp)
ffffffffc020265e:	e85a                	sd	s6,16(sp)
ffffffffc0202660:	e45e                	sd	s7,8(sp)
ffffffffc0202662:	e062                	sd	s8,0(sp)
    pmm_manager = &default_pmm_manager;
ffffffffc0202664:	000aa417          	auipc	s0,0xaa
ffffffffc0202668:	e9c40413          	addi	s0,s0,-356 # ffffffffc02ac500 <pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020266c:	b23fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    pmm_manager->init();
ffffffffc0202670:	601c                	ld	a5,0(s0)
ffffffffc0202672:	000aa497          	auipc	s1,0xaa
ffffffffc0202676:	e3648493          	addi	s1,s1,-458 # ffffffffc02ac4a8 <npage>
ffffffffc020267a:	000aa917          	auipc	s2,0xaa
ffffffffc020267e:	e9e90913          	addi	s2,s2,-354 # ffffffffc02ac518 <pages>
ffffffffc0202682:	679c                	ld	a5,8(a5)
ffffffffc0202684:	9782                	jalr	a5
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0202686:	57f5                	li	a5,-3
ffffffffc0202688:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc020268a:	00005517          	auipc	a0,0x5
ffffffffc020268e:	e6650513          	addi	a0,a0,-410 # ffffffffc02074f0 <default_pmm_manager+0x1a0>
    va_pa_offset = KERNBASE - 0x80200000;
ffffffffc0202692:	000aa717          	auipc	a4,0xaa
ffffffffc0202696:	e6f73b23          	sd	a5,-394(a4) # ffffffffc02ac508 <va_pa_offset>
    cprintf("physcial memory map:\n");
ffffffffc020269a:	af5fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    cprintf("  memory: 0x%08lx, [0x%08lx, 0x%08lx].\n", mem_size, mem_begin,
ffffffffc020269e:	46c5                	li	a3,17
ffffffffc02026a0:	06ee                	slli	a3,a3,0x1b
ffffffffc02026a2:	40100613          	li	a2,1025
ffffffffc02026a6:	16fd                	addi	a3,a3,-1
ffffffffc02026a8:	0656                	slli	a2,a2,0x15
ffffffffc02026aa:	07e005b7          	lui	a1,0x7e00
ffffffffc02026ae:	00005517          	auipc	a0,0x5
ffffffffc02026b2:	e5a50513          	addi	a0,a0,-422 # ffffffffc0207508 <default_pmm_manager+0x1b8>
ffffffffc02026b6:	ad9fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026ba:	777d                	lui	a4,0xfffff
ffffffffc02026bc:	000ab797          	auipc	a5,0xab
ffffffffc02026c0:	f5378793          	addi	a5,a5,-173 # ffffffffc02ad60f <end+0xfff>
ffffffffc02026c4:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc02026c6:	00088737          	lui	a4,0x88
ffffffffc02026ca:	000aa697          	auipc	a3,0xaa
ffffffffc02026ce:	dce6bf23          	sd	a4,-546(a3) # ffffffffc02ac4a8 <npage>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02026d2:	000aa717          	auipc	a4,0xaa
ffffffffc02026d6:	e4f73323          	sd	a5,-442(a4) # ffffffffc02ac518 <pages>
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02026da:	4701                	li	a4,0
ffffffffc02026dc:	4685                	li	a3,1
ffffffffc02026de:	fff80837          	lui	a6,0xfff80
ffffffffc02026e2:	a019                	j	ffffffffc02026e8 <pmm_init+0xb4>
ffffffffc02026e4:	00093783          	ld	a5,0(s2)
        SetPageReserved(pages + i);
ffffffffc02026e8:	00671613          	slli	a2,a4,0x6
ffffffffc02026ec:	97b2                	add	a5,a5,a2
ffffffffc02026ee:	07a1                	addi	a5,a5,8
ffffffffc02026f0:	40d7b02f          	amoor.d	zero,a3,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02026f4:	6090                	ld	a2,0(s1)
ffffffffc02026f6:	0705                	addi	a4,a4,1
ffffffffc02026f8:	010607b3          	add	a5,a2,a6
ffffffffc02026fc:	fef764e3          	bltu	a4,a5,ffffffffc02026e4 <pmm_init+0xb0>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202700:	00093503          	ld	a0,0(s2)
ffffffffc0202704:	fe0007b7          	lui	a5,0xfe000
ffffffffc0202708:	00661693          	slli	a3,a2,0x6
ffffffffc020270c:	97aa                	add	a5,a5,a0
ffffffffc020270e:	96be                	add	a3,a3,a5
ffffffffc0202710:	c02007b7          	lui	a5,0xc0200
ffffffffc0202714:	7af6ed63          	bltu	a3,a5,ffffffffc0202ece <pmm_init+0x89a>
ffffffffc0202718:	000aa997          	auipc	s3,0xaa
ffffffffc020271c:	df098993          	addi	s3,s3,-528 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0202720:	0009b583          	ld	a1,0(s3)
    if (freemem < mem_end) {
ffffffffc0202724:	47c5                	li	a5,17
ffffffffc0202726:	07ee                	slli	a5,a5,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202728:	8e8d                	sub	a3,a3,a1
    if (freemem < mem_end) {
ffffffffc020272a:	02f6f763          	bleu	a5,a3,ffffffffc0202758 <pmm_init+0x124>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020272e:	6585                	lui	a1,0x1
ffffffffc0202730:	15fd                	addi	a1,a1,-1
ffffffffc0202732:	96ae                	add	a3,a3,a1
    if (PPN(pa) >= npage) {
ffffffffc0202734:	00c6d713          	srli	a4,a3,0xc
ffffffffc0202738:	48c77a63          	bleu	a2,a4,ffffffffc0202bcc <pmm_init+0x598>
    pmm_manager->init_memmap(base, n);
ffffffffc020273c:	6010                	ld	a2,0(s0)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020273e:	75fd                	lui	a1,0xfffff
ffffffffc0202740:	8eed                	and	a3,a3,a1
    return &pages[PPN(pa) - nbase];
ffffffffc0202742:	9742                	add	a4,a4,a6
    pmm_manager->init_memmap(base, n);
ffffffffc0202744:	6a10                	ld	a2,16(a2)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc0202746:	40d786b3          	sub	a3,a5,a3
ffffffffc020274a:	071a                	slli	a4,a4,0x6
    pmm_manager->init_memmap(base, n);
ffffffffc020274c:	00c6d593          	srli	a1,a3,0xc
ffffffffc0202750:	953a                	add	a0,a0,a4
ffffffffc0202752:	9602                	jalr	a2
ffffffffc0202754:	0009b583          	ld	a1,0(s3)
    cprintf("vapaofset is %llu\n",va_pa_offset);
ffffffffc0202758:	00005517          	auipc	a0,0x5
ffffffffc020275c:	dd850513          	addi	a0,a0,-552 # ffffffffc0207530 <default_pmm_manager+0x1e0>
ffffffffc0202760:	a2ffd0ef          	jal	ra,ffffffffc020018e <cprintf>

    return page;
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0202764:	601c                	ld	a5,0(s0)
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc0202766:	000aa417          	auipc	s0,0xaa
ffffffffc020276a:	d3a40413          	addi	s0,s0,-710 # ffffffffc02ac4a0 <boot_pgdir>
    pmm_manager->check();
ffffffffc020276e:	7b9c                	ld	a5,48(a5)
ffffffffc0202770:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0202772:	00005517          	auipc	a0,0x5
ffffffffc0202776:	dd650513          	addi	a0,a0,-554 # ffffffffc0207548 <default_pmm_manager+0x1f8>
ffffffffc020277a:	a15fd0ef          	jal	ra,ffffffffc020018e <cprintf>
    boot_pgdir = (pte_t*)boot_page_table_sv39;
ffffffffc020277e:	00009697          	auipc	a3,0x9
ffffffffc0202782:	88268693          	addi	a3,a3,-1918 # ffffffffc020b000 <boot_page_table_sv39>
ffffffffc0202786:	000aa797          	auipc	a5,0xaa
ffffffffc020278a:	d0d7bd23          	sd	a3,-742(a5) # ffffffffc02ac4a0 <boot_pgdir>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc020278e:	c02007b7          	lui	a5,0xc0200
ffffffffc0202792:	10f6eae3          	bltu	a3,a5,ffffffffc02030a6 <pmm_init+0xa72>
ffffffffc0202796:	0009b783          	ld	a5,0(s3)
ffffffffc020279a:	8e9d                	sub	a3,a3,a5
ffffffffc020279c:	000aa797          	auipc	a5,0xaa
ffffffffc02027a0:	d6d7ba23          	sd	a3,-652(a5) # ffffffffc02ac510 <boot_cr3>
    // assert(npage <= KMEMSIZE / PGSIZE);
    // The memory starts at 2GB in RISC-V
    // so npage is always larger than KMEMSIZE / PGSIZE
    size_t nr_free_store;

    nr_free_store=nr_free_pages();
ffffffffc02027a4:	f7cff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>

    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027a8:	6098                	ld	a4,0(s1)
ffffffffc02027aa:	c80007b7          	lui	a5,0xc8000
ffffffffc02027ae:	83b1                	srli	a5,a5,0xc
    nr_free_store=nr_free_pages();
ffffffffc02027b0:	8a2a                	mv	s4,a0
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc02027b2:	0ce7eae3          	bltu	a5,a4,ffffffffc0203086 <pmm_init+0xa52>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc02027b6:	6008                	ld	a0,0(s0)
ffffffffc02027b8:	44050463          	beqz	a0,ffffffffc0202c00 <pmm_init+0x5cc>
ffffffffc02027bc:	6785                	lui	a5,0x1
ffffffffc02027be:	17fd                	addi	a5,a5,-1
ffffffffc02027c0:	8fe9                	and	a5,a5,a0
ffffffffc02027c2:	2781                	sext.w	a5,a5
ffffffffc02027c4:	42079e63          	bnez	a5,ffffffffc0202c00 <pmm_init+0x5cc>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc02027c8:	4601                	li	a2,0
ffffffffc02027ca:	4581                	li	a1,0
ffffffffc02027cc:	967ff0ef          	jal	ra,ffffffffc0202132 <get_page>
ffffffffc02027d0:	78051b63          	bnez	a0,ffffffffc0202f66 <pmm_init+0x932>

    struct Page *p1, *p2;
    p1 = alloc_page();
ffffffffc02027d4:	4505                	li	a0,1
ffffffffc02027d6:	e7cff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02027da:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc02027dc:	6008                	ld	a0,0(s0)
ffffffffc02027de:	4681                	li	a3,0
ffffffffc02027e0:	4601                	li	a2,0
ffffffffc02027e2:	85d6                	mv	a1,s5
ffffffffc02027e4:	d93ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc02027e8:	7a051f63          	bnez	a0,ffffffffc0202fa6 <pmm_init+0x972>

    pte_t *ptep;
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc02027ec:	6008                	ld	a0,0(s0)
ffffffffc02027ee:	4601                	li	a2,0
ffffffffc02027f0:	4581                	li	a1,0
ffffffffc02027f2:	f6eff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02027f6:	78050863          	beqz	a0,ffffffffc0202f86 <pmm_init+0x952>
    assert(pte2page(*ptep) == p1);
ffffffffc02027fa:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02027fc:	0017f713          	andi	a4,a5,1
ffffffffc0202800:	3e070463          	beqz	a4,ffffffffc0202be8 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc0202804:	6098                	ld	a4,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc0202806:	078a                	slli	a5,a5,0x2
ffffffffc0202808:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020280a:	3ce7f163          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc020280e:	00093683          	ld	a3,0(s2)
ffffffffc0202812:	fff80637          	lui	a2,0xfff80
ffffffffc0202816:	97b2                	add	a5,a5,a2
ffffffffc0202818:	079a                	slli	a5,a5,0x6
ffffffffc020281a:	97b6                	add	a5,a5,a3
ffffffffc020281c:	72fa9563          	bne	s5,a5,ffffffffc0202f46 <pmm_init+0x912>
    assert(page_ref(p1) == 1);
ffffffffc0202820:	000aab83          	lw	s7,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
ffffffffc0202824:	4785                	li	a5,1
ffffffffc0202826:	70fb9063          	bne	s7,a5,ffffffffc0202f26 <pmm_init+0x8f2>

    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc020282a:	6008                	ld	a0,0(s0)
ffffffffc020282c:	76fd                	lui	a3,0xfffff
ffffffffc020282e:	611c                	ld	a5,0(a0)
ffffffffc0202830:	078a                	slli	a5,a5,0x2
ffffffffc0202832:	8ff5                	and	a5,a5,a3
ffffffffc0202834:	00c7d613          	srli	a2,a5,0xc
ffffffffc0202838:	66e67e63          	bleu	a4,a2,ffffffffc0202eb4 <pmm_init+0x880>
ffffffffc020283c:	0009bc03          	ld	s8,0(s3)
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202840:	97e2                	add	a5,a5,s8
ffffffffc0202842:	0007bb03          	ld	s6,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
ffffffffc0202846:	0b0a                	slli	s6,s6,0x2
ffffffffc0202848:	00db7b33          	and	s6,s6,a3
ffffffffc020284c:	00cb5793          	srli	a5,s6,0xc
ffffffffc0202850:	56e7f863          	bleu	a4,a5,ffffffffc0202dc0 <pmm_init+0x78c>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202854:	4601                	li	a2,0
ffffffffc0202856:	6585                	lui	a1,0x1
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202858:	9b62                	add	s6,s6,s8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc020285a:	f06ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc020285e:	0b21                	addi	s6,s6,8
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202860:	55651063          	bne	a0,s6,ffffffffc0202da0 <pmm_init+0x76c>

    p2 = alloc_page();
ffffffffc0202864:	4505                	li	a0,1
ffffffffc0202866:	decff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc020286a:	8b2a                	mv	s6,a0
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc020286c:	6008                	ld	a0,0(s0)
ffffffffc020286e:	46d1                	li	a3,20
ffffffffc0202870:	6605                	lui	a2,0x1
ffffffffc0202872:	85da                	mv	a1,s6
ffffffffc0202874:	d03ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0202878:	50051463          	bnez	a0,ffffffffc0202d80 <pmm_init+0x74c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc020287c:	6008                	ld	a0,0(s0)
ffffffffc020287e:	4601                	li	a2,0
ffffffffc0202880:	6585                	lui	a1,0x1
ffffffffc0202882:	edeff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0202886:	4c050d63          	beqz	a0,ffffffffc0202d60 <pmm_init+0x72c>
    assert(*ptep & PTE_U);
ffffffffc020288a:	611c                	ld	a5,0(a0)
ffffffffc020288c:	0107f713          	andi	a4,a5,16
ffffffffc0202890:	4a070863          	beqz	a4,ffffffffc0202d40 <pmm_init+0x70c>
    assert(*ptep & PTE_W);
ffffffffc0202894:	8b91                	andi	a5,a5,4
ffffffffc0202896:	48078563          	beqz	a5,ffffffffc0202d20 <pmm_init+0x6ec>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc020289a:	6008                	ld	a0,0(s0)
ffffffffc020289c:	611c                	ld	a5,0(a0)
ffffffffc020289e:	8bc1                	andi	a5,a5,16
ffffffffc02028a0:	46078063          	beqz	a5,ffffffffc0202d00 <pmm_init+0x6cc>
    assert(page_ref(p2) == 1);
ffffffffc02028a4:	000b2783          	lw	a5,0(s6) # 200000 <_binary_obj___user_exit_out_size+0x1f5580>
ffffffffc02028a8:	43779c63          	bne	a5,s7,ffffffffc0202ce0 <pmm_init+0x6ac>

    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc02028ac:	4681                	li	a3,0
ffffffffc02028ae:	6605                	lui	a2,0x1
ffffffffc02028b0:	85d6                	mv	a1,s5
ffffffffc02028b2:	cc5ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc02028b6:	40051563          	bnez	a0,ffffffffc0202cc0 <pmm_init+0x68c>
    assert(page_ref(p1) == 2);
ffffffffc02028ba:	000aa703          	lw	a4,0(s5)
ffffffffc02028be:	4789                	li	a5,2
ffffffffc02028c0:	3ef71063          	bne	a4,a5,ffffffffc0202ca0 <pmm_init+0x66c>
    assert(page_ref(p2) == 0);
ffffffffc02028c4:	000b2783          	lw	a5,0(s6)
ffffffffc02028c8:	3a079c63          	bnez	a5,ffffffffc0202c80 <pmm_init+0x64c>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc02028cc:	6008                	ld	a0,0(s0)
ffffffffc02028ce:	4601                	li	a2,0
ffffffffc02028d0:	6585                	lui	a1,0x1
ffffffffc02028d2:	e8eff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02028d6:	38050563          	beqz	a0,ffffffffc0202c60 <pmm_init+0x62c>
    assert(pte2page(*ptep) == p1);
ffffffffc02028da:	6118                	ld	a4,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc02028dc:	00177793          	andi	a5,a4,1
ffffffffc02028e0:	30078463          	beqz	a5,ffffffffc0202be8 <pmm_init+0x5b4>
    if (PPN(pa) >= npage) {
ffffffffc02028e4:	6094                	ld	a3,0(s1)
    return pa2page(PTE_ADDR(pte));
ffffffffc02028e6:	00271793          	slli	a5,a4,0x2
ffffffffc02028ea:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02028ec:	2ed7f063          	bleu	a3,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02028f0:	00093683          	ld	a3,0(s2)
ffffffffc02028f4:	fff80637          	lui	a2,0xfff80
ffffffffc02028f8:	97b2                	add	a5,a5,a2
ffffffffc02028fa:	079a                	slli	a5,a5,0x6
ffffffffc02028fc:	97b6                	add	a5,a5,a3
ffffffffc02028fe:	32fa9163          	bne	s5,a5,ffffffffc0202c20 <pmm_init+0x5ec>
    assert((*ptep & PTE_U) == 0);
ffffffffc0202902:	8b41                	andi	a4,a4,16
ffffffffc0202904:	70071163          	bnez	a4,ffffffffc0203006 <pmm_init+0x9d2>

    page_remove(boot_pgdir, 0x0);
ffffffffc0202908:	6008                	ld	a0,0(s0)
ffffffffc020290a:	4581                	li	a1,0
ffffffffc020290c:	bf7ff0ef          	jal	ra,ffffffffc0202502 <page_remove>
    assert(page_ref(p1) == 1);
ffffffffc0202910:	000aa703          	lw	a4,0(s5)
ffffffffc0202914:	4785                	li	a5,1
ffffffffc0202916:	6cf71863          	bne	a4,a5,ffffffffc0202fe6 <pmm_init+0x9b2>
    assert(page_ref(p2) == 0);
ffffffffc020291a:	000b2783          	lw	a5,0(s6)
ffffffffc020291e:	6a079463          	bnez	a5,ffffffffc0202fc6 <pmm_init+0x992>

    page_remove(boot_pgdir, PGSIZE);
ffffffffc0202922:	6008                	ld	a0,0(s0)
ffffffffc0202924:	6585                	lui	a1,0x1
ffffffffc0202926:	bddff0ef          	jal	ra,ffffffffc0202502 <page_remove>
    assert(page_ref(p1) == 0);
ffffffffc020292a:	000aa783          	lw	a5,0(s5)
ffffffffc020292e:	50079363          	bnez	a5,ffffffffc0202e34 <pmm_init+0x800>
    assert(page_ref(p2) == 0);
ffffffffc0202932:	000b2783          	lw	a5,0(s6)
ffffffffc0202936:	4c079f63          	bnez	a5,ffffffffc0202e14 <pmm_init+0x7e0>

    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc020293a:	00043a83          	ld	s5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc020293e:	6090                	ld	a2,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202940:	000ab783          	ld	a5,0(s5)
ffffffffc0202944:	078a                	slli	a5,a5,0x2
ffffffffc0202946:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202948:	28c7f263          	bleu	a2,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc020294c:	fff80737          	lui	a4,0xfff80
ffffffffc0202950:	00093503          	ld	a0,0(s2)
ffffffffc0202954:	97ba                	add	a5,a5,a4
ffffffffc0202956:	079a                	slli	a5,a5,0x6
ffffffffc0202958:	00f50733          	add	a4,a0,a5
ffffffffc020295c:	4314                	lw	a3,0(a4)
ffffffffc020295e:	4705                	li	a4,1
ffffffffc0202960:	48e69a63          	bne	a3,a4,ffffffffc0202df4 <pmm_init+0x7c0>
    return page - pages + nbase;
ffffffffc0202964:	8799                	srai	a5,a5,0x6
ffffffffc0202966:	00080b37          	lui	s6,0x80
    return KADDR(page2pa(page));
ffffffffc020296a:	577d                	li	a4,-1
    return page - pages + nbase;
ffffffffc020296c:	97da                	add	a5,a5,s6
    return KADDR(page2pa(page));
ffffffffc020296e:	8331                	srli	a4,a4,0xc
ffffffffc0202970:	8f7d                	and	a4,a4,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0202972:	07b2                	slli	a5,a5,0xc
    return KADDR(page2pa(page));
ffffffffc0202974:	46c77363          	bleu	a2,a4,ffffffffc0202dda <pmm_init+0x7a6>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
    free_page(pde2page(pd0[0]));
ffffffffc0202978:	0009b683          	ld	a3,0(s3)
ffffffffc020297c:	97b6                	add	a5,a5,a3
    return pa2page(PDE_ADDR(pde));
ffffffffc020297e:	639c                	ld	a5,0(a5)
ffffffffc0202980:	078a                	slli	a5,a5,0x2
ffffffffc0202982:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202984:	24c7f463          	bleu	a2,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202988:	416787b3          	sub	a5,a5,s6
ffffffffc020298c:	079a                	slli	a5,a5,0x6
ffffffffc020298e:	953e                	add	a0,a0,a5
ffffffffc0202990:	4585                	li	a1,1
ffffffffc0202992:	d48ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202996:	000ab783          	ld	a5,0(s5)
    if (PPN(pa) >= npage) {
ffffffffc020299a:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc020299c:	078a                	slli	a5,a5,0x2
ffffffffc020299e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02029a0:	22e7f663          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc02029a4:	00093503          	ld	a0,0(s2)
ffffffffc02029a8:	416787b3          	sub	a5,a5,s6
ffffffffc02029ac:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc02029ae:	953e                	add	a0,a0,a5
ffffffffc02029b0:	4585                	li	a1,1
ffffffffc02029b2:	d28ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    boot_pgdir[0] = 0;
ffffffffc02029b6:	601c                	ld	a5,0(s0)
ffffffffc02029b8:	0007b023          	sd	zero,0(a5)
  asm volatile("sfence.vma");
ffffffffc02029bc:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc02029c0:	d60ff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc02029c4:	68aa1163          	bne	s4,a0,ffffffffc0203046 <pmm_init+0xa12>

    cprintf("check_pgdir() succeeded!\n");
ffffffffc02029c8:	00005517          	auipc	a0,0x5
ffffffffc02029cc:	e9050513          	addi	a0,a0,-368 # ffffffffc0207858 <default_pmm_manager+0x508>
ffffffffc02029d0:	fbefd0ef          	jal	ra,ffffffffc020018e <cprintf>
static void check_boot_pgdir(void) {
    size_t nr_free_store;
    pte_t *ptep;
    int i;

    nr_free_store=nr_free_pages();
ffffffffc02029d4:	d4cff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>

    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02029d8:	6098                	ld	a4,0(s1)
ffffffffc02029da:	c02007b7          	lui	a5,0xc0200
    nr_free_store=nr_free_pages();
ffffffffc02029de:	8a2a                	mv	s4,a0
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02029e0:	00c71693          	slli	a3,a4,0xc
ffffffffc02029e4:	18d7f563          	bleu	a3,a5,ffffffffc0202b6e <pmm_init+0x53a>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029e8:	83b1                	srli	a5,a5,0xc
ffffffffc02029ea:	6008                	ld	a0,0(s0)
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc02029ec:	c0200ab7          	lui	s5,0xc0200
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029f0:	1ae7f163          	bleu	a4,a5,ffffffffc0202b92 <pmm_init+0x55e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc02029f4:	7bfd                	lui	s7,0xfffff
ffffffffc02029f6:	6b05                	lui	s6,0x1
ffffffffc02029f8:	a029                	j	ffffffffc0202a02 <pmm_init+0x3ce>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc02029fa:	00cad713          	srli	a4,s5,0xc
ffffffffc02029fe:	18f77a63          	bleu	a5,a4,ffffffffc0202b92 <pmm_init+0x55e>
ffffffffc0202a02:	0009b583          	ld	a1,0(s3)
ffffffffc0202a06:	4601                	li	a2,0
ffffffffc0202a08:	95d6                	add	a1,a1,s5
ffffffffc0202a0a:	d56ff0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0202a0e:	16050263          	beqz	a0,ffffffffc0202b72 <pmm_init+0x53e>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202a12:	611c                	ld	a5,0(a0)
ffffffffc0202a14:	078a                	slli	a5,a5,0x2
ffffffffc0202a16:	0177f7b3          	and	a5,a5,s7
ffffffffc0202a1a:	19579963          	bne	a5,s5,ffffffffc0202bac <pmm_init+0x578>
    for (i = ROUNDDOWN(KERNBASE, PGSIZE); i < npage * PGSIZE; i += PGSIZE) {
ffffffffc0202a1e:	609c                	ld	a5,0(s1)
ffffffffc0202a20:	9ada                	add	s5,s5,s6
ffffffffc0202a22:	6008                	ld	a0,0(s0)
ffffffffc0202a24:	00c79713          	slli	a4,a5,0xc
ffffffffc0202a28:	fceae9e3          	bltu	s5,a4,ffffffffc02029fa <pmm_init+0x3c6>
    }


    assert(boot_pgdir[0] == 0);
ffffffffc0202a2c:	611c                	ld	a5,0(a0)
ffffffffc0202a2e:	62079c63          	bnez	a5,ffffffffc0203066 <pmm_init+0xa32>

    struct Page *p;
    p = alloc_page();
ffffffffc0202a32:	4505                	li	a0,1
ffffffffc0202a34:	c1eff0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0202a38:	8aaa                	mv	s5,a0
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202a3a:	6008                	ld	a0,0(s0)
ffffffffc0202a3c:	4699                	li	a3,6
ffffffffc0202a3e:	10000613          	li	a2,256
ffffffffc0202a42:	85d6                	mv	a1,s5
ffffffffc0202a44:	b33ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0202a48:	1e051c63          	bnez	a0,ffffffffc0202c40 <pmm_init+0x60c>
    assert(page_ref(p) == 1);
ffffffffc0202a4c:	000aa703          	lw	a4,0(s5) # ffffffffc0200000 <kern_entry>
ffffffffc0202a50:	4785                	li	a5,1
ffffffffc0202a52:	44f71163          	bne	a4,a5,ffffffffc0202e94 <pmm_init+0x860>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202a56:	6008                	ld	a0,0(s0)
ffffffffc0202a58:	6b05                	lui	s6,0x1
ffffffffc0202a5a:	4699                	li	a3,6
ffffffffc0202a5c:	100b0613          	addi	a2,s6,256 # 1100 <_binary_obj___user_faultread_out_size-0x8480>
ffffffffc0202a60:	85d6                	mv	a1,s5
ffffffffc0202a62:	b15ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0202a66:	40051763          	bnez	a0,ffffffffc0202e74 <pmm_init+0x840>
    assert(page_ref(p) == 2);
ffffffffc0202a6a:	000aa703          	lw	a4,0(s5)
ffffffffc0202a6e:	4789                	li	a5,2
ffffffffc0202a70:	3ef71263          	bne	a4,a5,ffffffffc0202e54 <pmm_init+0x820>

    const char *str = "ucore: Hello world!!";
    strcpy((void *)0x100, str);
ffffffffc0202a74:	00005597          	auipc	a1,0x5
ffffffffc0202a78:	f1c58593          	addi	a1,a1,-228 # ffffffffc0207990 <default_pmm_manager+0x640>
ffffffffc0202a7c:	10000513          	li	a0,256
ffffffffc0202a80:	315030ef          	jal	ra,ffffffffc0206594 <strcpy>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202a84:	100b0593          	addi	a1,s6,256
ffffffffc0202a88:	10000513          	li	a0,256
ffffffffc0202a8c:	31b030ef          	jal	ra,ffffffffc02065a6 <strcmp>
ffffffffc0202a90:	44051b63          	bnez	a0,ffffffffc0202ee6 <pmm_init+0x8b2>
    return page - pages + nbase;
ffffffffc0202a94:	00093683          	ld	a3,0(s2)
ffffffffc0202a98:	00080737          	lui	a4,0x80
    return KADDR(page2pa(page));
ffffffffc0202a9c:	5b7d                	li	s6,-1
    return page - pages + nbase;
ffffffffc0202a9e:	40da86b3          	sub	a3,s5,a3
ffffffffc0202aa2:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0202aa4:	609c                	ld	a5,0(s1)
    return page - pages + nbase;
ffffffffc0202aa6:	96ba                	add	a3,a3,a4
    return KADDR(page2pa(page));
ffffffffc0202aa8:	00cb5b13          	srli	s6,s6,0xc
ffffffffc0202aac:	0166f733          	and	a4,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ab0:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ab2:	10f77f63          	bleu	a5,a4,ffffffffc0202bd0 <pmm_init+0x59c>

    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202ab6:	0009b783          	ld	a5,0(s3)
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202aba:	10000513          	li	a0,256
    *(char *)(page2kva(p) + 0x100) = '\0';
ffffffffc0202abe:	96be                	add	a3,a3,a5
ffffffffc0202ac0:	10068023          	sb	zero,256(a3) # fffffffffffff100 <end+0x3fd52af0>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0202ac4:	28d030ef          	jal	ra,ffffffffc0206550 <strlen>
ffffffffc0202ac8:	54051f63          	bnez	a0,ffffffffc0203026 <pmm_init+0x9f2>

    pde_t *pd1=boot_pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc0202acc:	00043b83          	ld	s7,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc0202ad0:	609c                	ld	a5,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202ad2:	000bb683          	ld	a3,0(s7) # fffffffffffff000 <end+0x3fd529f0>
ffffffffc0202ad6:	068a                	slli	a3,a3,0x2
ffffffffc0202ad8:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202ada:	0ef6f963          	bleu	a5,a3,ffffffffc0202bcc <pmm_init+0x598>
    return KADDR(page2pa(page));
ffffffffc0202ade:	0166fb33          	and	s6,a3,s6
    return page2ppn(page) << PGSHIFT;
ffffffffc0202ae2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0202ae4:	0efb7663          	bleu	a5,s6,ffffffffc0202bd0 <pmm_init+0x59c>
ffffffffc0202ae8:	0009b983          	ld	s3,0(s3)
    free_page(p);
ffffffffc0202aec:	4585                	li	a1,1
ffffffffc0202aee:	8556                	mv	a0,s5
ffffffffc0202af0:	99b6                	add	s3,s3,a3
ffffffffc0202af2:	be8ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202af6:	0009b783          	ld	a5,0(s3)
    if (PPN(pa) >= npage) {
ffffffffc0202afa:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202afc:	078a                	slli	a5,a5,0x2
ffffffffc0202afe:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202b00:	0ce7f663          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b04:	00093503          	ld	a0,0(s2)
ffffffffc0202b08:	fff809b7          	lui	s3,0xfff80
ffffffffc0202b0c:	97ce                	add	a5,a5,s3
ffffffffc0202b0e:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc0202b10:	953e                	add	a0,a0,a5
ffffffffc0202b12:	4585                	li	a1,1
ffffffffc0202b14:	bc6ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b18:	000bb783          	ld	a5,0(s7)
    if (PPN(pa) >= npage) {
ffffffffc0202b1c:	6098                	ld	a4,0(s1)
    return pa2page(PDE_ADDR(pde));
ffffffffc0202b1e:	078a                	slli	a5,a5,0x2
ffffffffc0202b20:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0202b22:	0ae7f563          	bleu	a4,a5,ffffffffc0202bcc <pmm_init+0x598>
    return &pages[PPN(pa) - nbase];
ffffffffc0202b26:	00093503          	ld	a0,0(s2)
ffffffffc0202b2a:	97ce                	add	a5,a5,s3
ffffffffc0202b2c:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc0202b2e:	953e                	add	a0,a0,a5
ffffffffc0202b30:	4585                	li	a1,1
ffffffffc0202b32:	ba8ff0ef          	jal	ra,ffffffffc0201eda <free_pages>
    boot_pgdir[0] = 0;
ffffffffc0202b36:	601c                	ld	a5,0(s0)
ffffffffc0202b38:	0007b023          	sd	zero,0(a5) # ffffffffc0200000 <kern_entry>
  asm volatile("sfence.vma");
ffffffffc0202b3c:	12000073          	sfence.vma
    flush_tlb();

    assert(nr_free_store==nr_free_pages());
ffffffffc0202b40:	be0ff0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc0202b44:	3caa1163          	bne	s4,a0,ffffffffc0202f06 <pmm_init+0x8d2>

    cprintf("check_boot_pgdir() succeeded!\n");
ffffffffc0202b48:	00005517          	auipc	a0,0x5
ffffffffc0202b4c:	ec050513          	addi	a0,a0,-320 # ffffffffc0207a08 <default_pmm_manager+0x6b8>
ffffffffc0202b50:	e3efd0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0202b54:	6406                	ld	s0,64(sp)
ffffffffc0202b56:	60a6                	ld	ra,72(sp)
ffffffffc0202b58:	74e2                	ld	s1,56(sp)
ffffffffc0202b5a:	7942                	ld	s2,48(sp)
ffffffffc0202b5c:	79a2                	ld	s3,40(sp)
ffffffffc0202b5e:	7a02                	ld	s4,32(sp)
ffffffffc0202b60:	6ae2                	ld	s5,24(sp)
ffffffffc0202b62:	6b42                	ld	s6,16(sp)
ffffffffc0202b64:	6ba2                	ld	s7,8(sp)
ffffffffc0202b66:	6c02                	ld	s8,0(sp)
ffffffffc0202b68:	6161                	addi	sp,sp,80
    kmalloc_init();
ffffffffc0202b6a:	8c8ff06f          	j	ffffffffc0201c32 <kmalloc_init>
ffffffffc0202b6e:	6008                	ld	a0,0(s0)
ffffffffc0202b70:	bd75                	j	ffffffffc0202a2c <pmm_init+0x3f8>
        assert((ptep = get_pte(boot_pgdir, (uintptr_t)KADDR(i), 0)) != NULL);
ffffffffc0202b72:	00005697          	auipc	a3,0x5
ffffffffc0202b76:	d0668693          	addi	a3,a3,-762 # ffffffffc0207878 <default_pmm_manager+0x528>
ffffffffc0202b7a:	00004617          	auipc	a2,0x4
ffffffffc0202b7e:	08e60613          	addi	a2,a2,142 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202b82:	22f00593          	li	a1,559
ffffffffc0202b86:	00005517          	auipc	a0,0x5
ffffffffc0202b8a:	92a50513          	addi	a0,a0,-1750 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202b8e:	8f7fd0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0202b92:	86d6                	mv	a3,s5
ffffffffc0202b94:	00005617          	auipc	a2,0x5
ffffffffc0202b98:	80c60613          	addi	a2,a2,-2036 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0202b9c:	22f00593          	li	a1,559
ffffffffc0202ba0:	00005517          	auipc	a0,0x5
ffffffffc0202ba4:	91050513          	addi	a0,a0,-1776 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202ba8:	8ddfd0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(PTE_ADDR(*ptep) == i);
ffffffffc0202bac:	00005697          	auipc	a3,0x5
ffffffffc0202bb0:	d0c68693          	addi	a3,a3,-756 # ffffffffc02078b8 <default_pmm_manager+0x568>
ffffffffc0202bb4:	00004617          	auipc	a2,0x4
ffffffffc0202bb8:	05460613          	addi	a2,a2,84 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202bbc:	23000593          	li	a1,560
ffffffffc0202bc0:	00005517          	auipc	a0,0x5
ffffffffc0202bc4:	8f050513          	addi	a0,a0,-1808 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202bc8:	8bdfd0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0202bcc:	a6aff0ef          	jal	ra,ffffffffc0201e36 <pa2page.part.4>
    return KADDR(page2pa(page));
ffffffffc0202bd0:	00004617          	auipc	a2,0x4
ffffffffc0202bd4:	7d060613          	addi	a2,a2,2000 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0202bd8:	06900593          	li	a1,105
ffffffffc0202bdc:	00004517          	auipc	a0,0x4
ffffffffc0202be0:	7ec50513          	addi	a0,a0,2028 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0202be4:	8a1fd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc0202be8:	00005617          	auipc	a2,0x5
ffffffffc0202bec:	a6060613          	addi	a2,a2,-1440 # ffffffffc0207648 <default_pmm_manager+0x2f8>
ffffffffc0202bf0:	07400593          	li	a1,116
ffffffffc0202bf4:	00004517          	auipc	a0,0x4
ffffffffc0202bf8:	7d450513          	addi	a0,a0,2004 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0202bfc:	889fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir != NULL && (uint32_t)PGOFF(boot_pgdir) == 0);
ffffffffc0202c00:	00005697          	auipc	a3,0x5
ffffffffc0202c04:	98868693          	addi	a3,a3,-1656 # ffffffffc0207588 <default_pmm_manager+0x238>
ffffffffc0202c08:	00004617          	auipc	a2,0x4
ffffffffc0202c0c:	00060613          	mv	a2,a2
ffffffffc0202c10:	1f300593          	li	a1,499
ffffffffc0202c14:	00005517          	auipc	a0,0x5
ffffffffc0202c18:	89c50513          	addi	a0,a0,-1892 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202c1c:	869fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202c20:	00005697          	auipc	a3,0x5
ffffffffc0202c24:	a5068693          	addi	a3,a3,-1456 # ffffffffc0207670 <default_pmm_manager+0x320>
ffffffffc0202c28:	00004617          	auipc	a2,0x4
ffffffffc0202c2c:	fe060613          	addi	a2,a2,-32 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202c30:	20f00593          	li	a1,527
ffffffffc0202c34:	00005517          	auipc	a0,0x5
ffffffffc0202c38:	87c50513          	addi	a0,a0,-1924 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202c3c:	849fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100, PTE_W | PTE_R) == 0);
ffffffffc0202c40:	00005697          	auipc	a3,0x5
ffffffffc0202c44:	ca868693          	addi	a3,a3,-856 # ffffffffc02078e8 <default_pmm_manager+0x598>
ffffffffc0202c48:	00004617          	auipc	a2,0x4
ffffffffc0202c4c:	fc060613          	addi	a2,a2,-64 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202c50:	23800593          	li	a1,568
ffffffffc0202c54:	00005517          	auipc	a0,0x5
ffffffffc0202c58:	85c50513          	addi	a0,a0,-1956 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202c5c:	829fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202c60:	00005697          	auipc	a3,0x5
ffffffffc0202c64:	aa068693          	addi	a3,a3,-1376 # ffffffffc0207700 <default_pmm_manager+0x3b0>
ffffffffc0202c68:	00004617          	auipc	a2,0x4
ffffffffc0202c6c:	fa060613          	addi	a2,a2,-96 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202c70:	20e00593          	li	a1,526
ffffffffc0202c74:	00005517          	auipc	a0,0x5
ffffffffc0202c78:	83c50513          	addi	a0,a0,-1988 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202c7c:	809fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202c80:	00005697          	auipc	a3,0x5
ffffffffc0202c84:	b4868693          	addi	a3,a3,-1208 # ffffffffc02077c8 <default_pmm_manager+0x478>
ffffffffc0202c88:	00004617          	auipc	a2,0x4
ffffffffc0202c8c:	f8060613          	addi	a2,a2,-128 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202c90:	20d00593          	li	a1,525
ffffffffc0202c94:	00005517          	auipc	a0,0x5
ffffffffc0202c98:	81c50513          	addi	a0,a0,-2020 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202c9c:	fe8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 2);
ffffffffc0202ca0:	00005697          	auipc	a3,0x5
ffffffffc0202ca4:	b1068693          	addi	a3,a3,-1264 # ffffffffc02077b0 <default_pmm_manager+0x460>
ffffffffc0202ca8:	00004617          	auipc	a2,0x4
ffffffffc0202cac:	f6060613          	addi	a2,a2,-160 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202cb0:	20c00593          	li	a1,524
ffffffffc0202cb4:	00004517          	auipc	a0,0x4
ffffffffc0202cb8:	7fc50513          	addi	a0,a0,2044 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202cbc:	fc8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p1, PGSIZE, 0) == 0);
ffffffffc0202cc0:	00005697          	auipc	a3,0x5
ffffffffc0202cc4:	ac068693          	addi	a3,a3,-1344 # ffffffffc0207780 <default_pmm_manager+0x430>
ffffffffc0202cc8:	00004617          	auipc	a2,0x4
ffffffffc0202ccc:	f4060613          	addi	a2,a2,-192 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202cd0:	20b00593          	li	a1,523
ffffffffc0202cd4:	00004517          	auipc	a0,0x4
ffffffffc0202cd8:	7dc50513          	addi	a0,a0,2012 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202cdc:	fa8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 1);
ffffffffc0202ce0:	00005697          	auipc	a3,0x5
ffffffffc0202ce4:	a8868693          	addi	a3,a3,-1400 # ffffffffc0207768 <default_pmm_manager+0x418>
ffffffffc0202ce8:	00004617          	auipc	a2,0x4
ffffffffc0202cec:	f2060613          	addi	a2,a2,-224 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202cf0:	20900593          	li	a1,521
ffffffffc0202cf4:	00004517          	auipc	a0,0x4
ffffffffc0202cf8:	7bc50513          	addi	a0,a0,1980 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202cfc:	f88fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir[0] & PTE_U);
ffffffffc0202d00:	00005697          	auipc	a3,0x5
ffffffffc0202d04:	a5068693          	addi	a3,a3,-1456 # ffffffffc0207750 <default_pmm_manager+0x400>
ffffffffc0202d08:	00004617          	auipc	a2,0x4
ffffffffc0202d0c:	f0060613          	addi	a2,a2,-256 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202d10:	20800593          	li	a1,520
ffffffffc0202d14:	00004517          	auipc	a0,0x4
ffffffffc0202d18:	79c50513          	addi	a0,a0,1948 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202d1c:	f68fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*ptep & PTE_W);
ffffffffc0202d20:	00005697          	auipc	a3,0x5
ffffffffc0202d24:	a2068693          	addi	a3,a3,-1504 # ffffffffc0207740 <default_pmm_manager+0x3f0>
ffffffffc0202d28:	00004617          	auipc	a2,0x4
ffffffffc0202d2c:	ee060613          	addi	a2,a2,-288 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202d30:	20700593          	li	a1,519
ffffffffc0202d34:	00004517          	auipc	a0,0x4
ffffffffc0202d38:	77c50513          	addi	a0,a0,1916 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202d3c:	f48fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*ptep & PTE_U);
ffffffffc0202d40:	00005697          	auipc	a3,0x5
ffffffffc0202d44:	9f068693          	addi	a3,a3,-1552 # ffffffffc0207730 <default_pmm_manager+0x3e0>
ffffffffc0202d48:	00004617          	auipc	a2,0x4
ffffffffc0202d4c:	ec060613          	addi	a2,a2,-320 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202d50:	20600593          	li	a1,518
ffffffffc0202d54:	00004517          	auipc	a0,0x4
ffffffffc0202d58:	75c50513          	addi	a0,a0,1884 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202d5c:	f28fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, PGSIZE, 0)) != NULL);
ffffffffc0202d60:	00005697          	auipc	a3,0x5
ffffffffc0202d64:	9a068693          	addi	a3,a3,-1632 # ffffffffc0207700 <default_pmm_manager+0x3b0>
ffffffffc0202d68:	00004617          	auipc	a2,0x4
ffffffffc0202d6c:	ea060613          	addi	a2,a2,-352 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202d70:	20500593          	li	a1,517
ffffffffc0202d74:	00004517          	auipc	a0,0x4
ffffffffc0202d78:	73c50513          	addi	a0,a0,1852 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202d7c:	f08fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p2, PGSIZE, PTE_U | PTE_W) == 0);
ffffffffc0202d80:	00005697          	auipc	a3,0x5
ffffffffc0202d84:	94868693          	addi	a3,a3,-1720 # ffffffffc02076c8 <default_pmm_manager+0x378>
ffffffffc0202d88:	00004617          	auipc	a2,0x4
ffffffffc0202d8c:	e8060613          	addi	a2,a2,-384 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202d90:	20400593          	li	a1,516
ffffffffc0202d94:	00004517          	auipc	a0,0x4
ffffffffc0202d98:	71c50513          	addi	a0,a0,1820 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202d9c:	ee8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(get_pte(boot_pgdir, PGSIZE, 0) == ptep);
ffffffffc0202da0:	00005697          	auipc	a3,0x5
ffffffffc0202da4:	90068693          	addi	a3,a3,-1792 # ffffffffc02076a0 <default_pmm_manager+0x350>
ffffffffc0202da8:	00004617          	auipc	a2,0x4
ffffffffc0202dac:	e6060613          	addi	a2,a2,-416 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202db0:	20100593          	li	a1,513
ffffffffc0202db4:	00004517          	auipc	a0,0x4
ffffffffc0202db8:	6fc50513          	addi	a0,a0,1788 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202dbc:	ec8fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(ptep[0])) + 1;
ffffffffc0202dc0:	86da                	mv	a3,s6
ffffffffc0202dc2:	00004617          	auipc	a2,0x4
ffffffffc0202dc6:	5de60613          	addi	a2,a2,1502 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0202dca:	20000593          	li	a1,512
ffffffffc0202dce:	00004517          	auipc	a0,0x4
ffffffffc0202dd2:	6e250513          	addi	a0,a0,1762 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202dd6:	eaefd0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0202dda:	86be                	mv	a3,a5
ffffffffc0202ddc:	00004617          	auipc	a2,0x4
ffffffffc0202de0:	5c460613          	addi	a2,a2,1476 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0202de4:	06900593          	li	a1,105
ffffffffc0202de8:	00004517          	auipc	a0,0x4
ffffffffc0202dec:	5e050513          	addi	a0,a0,1504 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0202df0:	e94fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(pde2page(boot_pgdir[0])) == 1);
ffffffffc0202df4:	00005697          	auipc	a3,0x5
ffffffffc0202df8:	a1c68693          	addi	a3,a3,-1508 # ffffffffc0207810 <default_pmm_manager+0x4c0>
ffffffffc0202dfc:	00004617          	auipc	a2,0x4
ffffffffc0202e00:	e0c60613          	addi	a2,a2,-500 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202e04:	21a00593          	li	a1,538
ffffffffc0202e08:	00004517          	auipc	a0,0x4
ffffffffc0202e0c:	6a850513          	addi	a0,a0,1704 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202e10:	e74fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202e14:	00005697          	auipc	a3,0x5
ffffffffc0202e18:	9b468693          	addi	a3,a3,-1612 # ffffffffc02077c8 <default_pmm_manager+0x478>
ffffffffc0202e1c:	00004617          	auipc	a2,0x4
ffffffffc0202e20:	dec60613          	addi	a2,a2,-532 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202e24:	21800593          	li	a1,536
ffffffffc0202e28:	00004517          	auipc	a0,0x4
ffffffffc0202e2c:	68850513          	addi	a0,a0,1672 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202e30:	e54fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 0);
ffffffffc0202e34:	00005697          	auipc	a3,0x5
ffffffffc0202e38:	9c468693          	addi	a3,a3,-1596 # ffffffffc02077f8 <default_pmm_manager+0x4a8>
ffffffffc0202e3c:	00004617          	auipc	a2,0x4
ffffffffc0202e40:	dcc60613          	addi	a2,a2,-564 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202e44:	21700593          	li	a1,535
ffffffffc0202e48:	00004517          	auipc	a0,0x4
ffffffffc0202e4c:	66850513          	addi	a0,a0,1640 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202e50:	e34fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p) == 2);
ffffffffc0202e54:	00005697          	auipc	a3,0x5
ffffffffc0202e58:	b2468693          	addi	a3,a3,-1244 # ffffffffc0207978 <default_pmm_manager+0x628>
ffffffffc0202e5c:	00004617          	auipc	a2,0x4
ffffffffc0202e60:	dac60613          	addi	a2,a2,-596 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202e64:	23b00593          	li	a1,571
ffffffffc0202e68:	00004517          	auipc	a0,0x4
ffffffffc0202e6c:	64850513          	addi	a0,a0,1608 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202e70:	e14fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p, 0x100 + PGSIZE, PTE_W | PTE_R) == 0);
ffffffffc0202e74:	00005697          	auipc	a3,0x5
ffffffffc0202e78:	ac468693          	addi	a3,a3,-1340 # ffffffffc0207938 <default_pmm_manager+0x5e8>
ffffffffc0202e7c:	00004617          	auipc	a2,0x4
ffffffffc0202e80:	d8c60613          	addi	a2,a2,-628 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202e84:	23a00593          	li	a1,570
ffffffffc0202e88:	00004517          	auipc	a0,0x4
ffffffffc0202e8c:	62850513          	addi	a0,a0,1576 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202e90:	df4fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p) == 1);
ffffffffc0202e94:	00005697          	auipc	a3,0x5
ffffffffc0202e98:	a8c68693          	addi	a3,a3,-1396 # ffffffffc0207920 <default_pmm_manager+0x5d0>
ffffffffc0202e9c:	00004617          	auipc	a2,0x4
ffffffffc0202ea0:	d6c60613          	addi	a2,a2,-660 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202ea4:	23900593          	li	a1,569
ffffffffc0202ea8:	00004517          	auipc	a0,0x4
ffffffffc0202eac:	60850513          	addi	a0,a0,1544 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202eb0:	dd4fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    ptep = (pte_t *)KADDR(PDE_ADDR(boot_pgdir[0]));
ffffffffc0202eb4:	86be                	mv	a3,a5
ffffffffc0202eb6:	00004617          	auipc	a2,0x4
ffffffffc0202eba:	4ea60613          	addi	a2,a2,1258 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0202ebe:	1ff00593          	li	a1,511
ffffffffc0202ec2:	00004517          	auipc	a0,0x4
ffffffffc0202ec6:	5ee50513          	addi	a0,a0,1518 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202eca:	dbafd0ef          	jal	ra,ffffffffc0200484 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0202ece:	00004617          	auipc	a2,0x4
ffffffffc0202ed2:	50a60613          	addi	a2,a2,1290 # ffffffffc02073d8 <default_pmm_manager+0x88>
ffffffffc0202ed6:	07f00593          	li	a1,127
ffffffffc0202eda:	00004517          	auipc	a0,0x4
ffffffffc0202ede:	5d650513          	addi	a0,a0,1494 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202ee2:	da2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(strcmp((void *)0x100, (void *)(0x100 + PGSIZE)) == 0);
ffffffffc0202ee6:	00005697          	auipc	a3,0x5
ffffffffc0202eea:	ac268693          	addi	a3,a3,-1342 # ffffffffc02079a8 <default_pmm_manager+0x658>
ffffffffc0202eee:	00004617          	auipc	a2,0x4
ffffffffc0202ef2:	d1a60613          	addi	a2,a2,-742 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202ef6:	23f00593          	li	a1,575
ffffffffc0202efa:	00004517          	auipc	a0,0x4
ffffffffc0202efe:	5b650513          	addi	a0,a0,1462 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202f02:	d82fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0202f06:	00005697          	auipc	a3,0x5
ffffffffc0202f0a:	93268693          	addi	a3,a3,-1742 # ffffffffc0207838 <default_pmm_manager+0x4e8>
ffffffffc0202f0e:	00004617          	auipc	a2,0x4
ffffffffc0202f12:	cfa60613          	addi	a2,a2,-774 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202f16:	24b00593          	li	a1,587
ffffffffc0202f1a:	00004517          	auipc	a0,0x4
ffffffffc0202f1e:	59650513          	addi	a0,a0,1430 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202f22:	d62fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202f26:	00004697          	auipc	a3,0x4
ffffffffc0202f2a:	76268693          	addi	a3,a3,1890 # ffffffffc0207688 <default_pmm_manager+0x338>
ffffffffc0202f2e:	00004617          	auipc	a2,0x4
ffffffffc0202f32:	cda60613          	addi	a2,a2,-806 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202f36:	1fd00593          	li	a1,509
ffffffffc0202f3a:	00004517          	auipc	a0,0x4
ffffffffc0202f3e:	57650513          	addi	a0,a0,1398 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202f42:	d42fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pte2page(*ptep) == p1);
ffffffffc0202f46:	00004697          	auipc	a3,0x4
ffffffffc0202f4a:	72a68693          	addi	a3,a3,1834 # ffffffffc0207670 <default_pmm_manager+0x320>
ffffffffc0202f4e:	00004617          	auipc	a2,0x4
ffffffffc0202f52:	cba60613          	addi	a2,a2,-838 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202f56:	1fc00593          	li	a1,508
ffffffffc0202f5a:	00004517          	auipc	a0,0x4
ffffffffc0202f5e:	55650513          	addi	a0,a0,1366 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202f62:	d22fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(get_page(boot_pgdir, 0x0, NULL) == NULL);
ffffffffc0202f66:	00004697          	auipc	a3,0x4
ffffffffc0202f6a:	65a68693          	addi	a3,a3,1626 # ffffffffc02075c0 <default_pmm_manager+0x270>
ffffffffc0202f6e:	00004617          	auipc	a2,0x4
ffffffffc0202f72:	c9a60613          	addi	a2,a2,-870 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202f76:	1f400593          	li	a1,500
ffffffffc0202f7a:	00004517          	auipc	a0,0x4
ffffffffc0202f7e:	53650513          	addi	a0,a0,1334 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202f82:	d02fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((ptep = get_pte(boot_pgdir, 0x0, 0)) != NULL);
ffffffffc0202f86:	00004697          	auipc	a3,0x4
ffffffffc0202f8a:	69268693          	addi	a3,a3,1682 # ffffffffc0207618 <default_pmm_manager+0x2c8>
ffffffffc0202f8e:	00004617          	auipc	a2,0x4
ffffffffc0202f92:	c7a60613          	addi	a2,a2,-902 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202f96:	1fb00593          	li	a1,507
ffffffffc0202f9a:	00004517          	auipc	a0,0x4
ffffffffc0202f9e:	51650513          	addi	a0,a0,1302 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202fa2:	ce2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_insert(boot_pgdir, p1, 0x0, 0) == 0);
ffffffffc0202fa6:	00004697          	auipc	a3,0x4
ffffffffc0202faa:	64268693          	addi	a3,a3,1602 # ffffffffc02075e8 <default_pmm_manager+0x298>
ffffffffc0202fae:	00004617          	auipc	a2,0x4
ffffffffc0202fb2:	c5a60613          	addi	a2,a2,-934 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202fb6:	1f800593          	li	a1,504
ffffffffc0202fba:	00004517          	auipc	a0,0x4
ffffffffc0202fbe:	4f650513          	addi	a0,a0,1270 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202fc2:	cc2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p2) == 0);
ffffffffc0202fc6:	00005697          	auipc	a3,0x5
ffffffffc0202fca:	80268693          	addi	a3,a3,-2046 # ffffffffc02077c8 <default_pmm_manager+0x478>
ffffffffc0202fce:	00004617          	auipc	a2,0x4
ffffffffc0202fd2:	c3a60613          	addi	a2,a2,-966 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202fd6:	21400593          	li	a1,532
ffffffffc0202fda:	00004517          	auipc	a0,0x4
ffffffffc0202fde:	4d650513          	addi	a0,a0,1238 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0202fe2:	ca2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(page_ref(p1) == 1);
ffffffffc0202fe6:	00004697          	auipc	a3,0x4
ffffffffc0202fea:	6a268693          	addi	a3,a3,1698 # ffffffffc0207688 <default_pmm_manager+0x338>
ffffffffc0202fee:	00004617          	auipc	a2,0x4
ffffffffc0202ff2:	c1a60613          	addi	a2,a2,-998 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0202ff6:	21300593          	li	a1,531
ffffffffc0202ffa:	00004517          	auipc	a0,0x4
ffffffffc0202ffe:	4b650513          	addi	a0,a0,1206 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0203002:	c82fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert((*ptep & PTE_U) == 0);
ffffffffc0203006:	00004697          	auipc	a3,0x4
ffffffffc020300a:	7da68693          	addi	a3,a3,2010 # ffffffffc02077e0 <default_pmm_manager+0x490>
ffffffffc020300e:	00004617          	auipc	a2,0x4
ffffffffc0203012:	bfa60613          	addi	a2,a2,-1030 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203016:	21000593          	li	a1,528
ffffffffc020301a:	00004517          	auipc	a0,0x4
ffffffffc020301e:	49650513          	addi	a0,a0,1174 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0203022:	c62fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(strlen((const char *)0x100) == 0);
ffffffffc0203026:	00005697          	auipc	a3,0x5
ffffffffc020302a:	9ba68693          	addi	a3,a3,-1606 # ffffffffc02079e0 <default_pmm_manager+0x690>
ffffffffc020302e:	00004617          	auipc	a2,0x4
ffffffffc0203032:	bda60613          	addi	a2,a2,-1062 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203036:	24200593          	li	a1,578
ffffffffc020303a:	00004517          	auipc	a0,0x4
ffffffffc020303e:	47650513          	addi	a0,a0,1142 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0203042:	c42fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_store==nr_free_pages());
ffffffffc0203046:	00004697          	auipc	a3,0x4
ffffffffc020304a:	7f268693          	addi	a3,a3,2034 # ffffffffc0207838 <default_pmm_manager+0x4e8>
ffffffffc020304e:	00004617          	auipc	a2,0x4
ffffffffc0203052:	bba60613          	addi	a2,a2,-1094 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203056:	22200593          	li	a1,546
ffffffffc020305a:	00004517          	auipc	a0,0x4
ffffffffc020305e:	45650513          	addi	a0,a0,1110 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0203062:	c22fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(boot_pgdir[0] == 0);
ffffffffc0203066:	00005697          	auipc	a3,0x5
ffffffffc020306a:	86a68693          	addi	a3,a3,-1942 # ffffffffc02078d0 <default_pmm_manager+0x580>
ffffffffc020306e:	00004617          	auipc	a2,0x4
ffffffffc0203072:	b9a60613          	addi	a2,a2,-1126 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203076:	23400593          	li	a1,564
ffffffffc020307a:	00004517          	auipc	a0,0x4
ffffffffc020307e:	43650513          	addi	a0,a0,1078 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0203082:	c02fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(npage <= KERNTOP / PGSIZE);
ffffffffc0203086:	00004697          	auipc	a3,0x4
ffffffffc020308a:	4e268693          	addi	a3,a3,1250 # ffffffffc0207568 <default_pmm_manager+0x218>
ffffffffc020308e:	00004617          	auipc	a2,0x4
ffffffffc0203092:	b7a60613          	addi	a2,a2,-1158 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203096:	1f200593          	li	a1,498
ffffffffc020309a:	00004517          	auipc	a0,0x4
ffffffffc020309e:	41650513          	addi	a0,a0,1046 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc02030a2:	be2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    boot_cr3 = PADDR(boot_pgdir);
ffffffffc02030a6:	00004617          	auipc	a2,0x4
ffffffffc02030aa:	33260613          	addi	a2,a2,818 # ffffffffc02073d8 <default_pmm_manager+0x88>
ffffffffc02030ae:	0c100593          	li	a1,193
ffffffffc02030b2:	00004517          	auipc	a0,0x4
ffffffffc02030b6:	3fe50513          	addi	a0,a0,1022 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc02030ba:	bcafd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02030be <copy_range>:
               bool share) {
ffffffffc02030be:	7159                	addi	sp,sp,-112
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02030c0:	00d667b3          	or	a5,a2,a3
               bool share) {
ffffffffc02030c4:	f486                	sd	ra,104(sp)
ffffffffc02030c6:	f0a2                	sd	s0,96(sp)
ffffffffc02030c8:	eca6                	sd	s1,88(sp)
ffffffffc02030ca:	e8ca                	sd	s2,80(sp)
ffffffffc02030cc:	e4ce                	sd	s3,72(sp)
ffffffffc02030ce:	e0d2                	sd	s4,64(sp)
ffffffffc02030d0:	fc56                	sd	s5,56(sp)
ffffffffc02030d2:	f85a                	sd	s6,48(sp)
ffffffffc02030d4:	f45e                	sd	s7,40(sp)
ffffffffc02030d6:	f062                	sd	s8,32(sp)
ffffffffc02030d8:	ec66                	sd	s9,24(sp)
ffffffffc02030da:	e86a                	sd	s10,16(sp)
ffffffffc02030dc:	e46e                	sd	s11,8(sp)
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02030de:	03479713          	slli	a4,a5,0x34
ffffffffc02030e2:	1e071263          	bnez	a4,ffffffffc02032c6 <copy_range+0x208>
    assert(USER_ACCESS(start, end));
ffffffffc02030e6:	002007b7          	lui	a5,0x200
ffffffffc02030ea:	8432                	mv	s0,a2
ffffffffc02030ec:	12f66863          	bltu	a2,a5,ffffffffc020321c <copy_range+0x15e>
ffffffffc02030f0:	84b6                	mv	s1,a3
ffffffffc02030f2:	12d67563          	bleu	a3,a2,ffffffffc020321c <copy_range+0x15e>
ffffffffc02030f6:	4785                	li	a5,1
ffffffffc02030f8:	07fe                	slli	a5,a5,0x1f
ffffffffc02030fa:	12d7e163          	bltu	a5,a3,ffffffffc020321c <copy_range+0x15e>
ffffffffc02030fe:	59fd                	li	s3,-1
ffffffffc0203100:	8a2a                	mv	s4,a0
ffffffffc0203102:	892e                	mv	s2,a1
    if (PPN(pa) >= npage) {
ffffffffc0203104:	000a9b97          	auipc	s7,0xa9
ffffffffc0203108:	3a4b8b93          	addi	s7,s7,932 # ffffffffc02ac4a8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc020310c:	000a9b17          	auipc	s6,0xa9
ffffffffc0203110:	40cb0b13          	addi	s6,s6,1036 # ffffffffc02ac518 <pages>
ffffffffc0203114:	fff80d37          	lui	s10,0xfff80
    return page - pages + nbase;
ffffffffc0203118:	00080ab7          	lui	s5,0x80
    return KADDR(page2pa(page));
ffffffffc020311c:	00c9d993          	srli	s3,s3,0xc
        pte_t *ptep = get_pte(from, start, 0), *nptep;
ffffffffc0203120:	4601                	li	a2,0
ffffffffc0203122:	85a2                	mv	a1,s0
ffffffffc0203124:	854a                	mv	a0,s2
ffffffffc0203126:	e3bfe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc020312a:	8c2a                	mv	s8,a0
        if (ptep == NULL) {
ffffffffc020312c:	c161                	beqz	a0,ffffffffc02031ec <copy_range+0x12e>
        if (*ptep & PTE_V) {
ffffffffc020312e:	611c                	ld	a5,0(a0)
ffffffffc0203130:	8b85                	andi	a5,a5,1
ffffffffc0203132:	e78d                	bnez	a5,ffffffffc020315c <copy_range+0x9e>
        start += PGSIZE;
ffffffffc0203134:	6785                	lui	a5,0x1
ffffffffc0203136:	943e                	add	s0,s0,a5
    } while (start != 0 && start < end);
ffffffffc0203138:	fe9464e3          	bltu	s0,s1,ffffffffc0203120 <copy_range+0x62>
    return 0;
ffffffffc020313c:	4501                	li	a0,0
}
ffffffffc020313e:	70a6                	ld	ra,104(sp)
ffffffffc0203140:	7406                	ld	s0,96(sp)
ffffffffc0203142:	64e6                	ld	s1,88(sp)
ffffffffc0203144:	6946                	ld	s2,80(sp)
ffffffffc0203146:	69a6                	ld	s3,72(sp)
ffffffffc0203148:	6a06                	ld	s4,64(sp)
ffffffffc020314a:	7ae2                	ld	s5,56(sp)
ffffffffc020314c:	7b42                	ld	s6,48(sp)
ffffffffc020314e:	7ba2                	ld	s7,40(sp)
ffffffffc0203150:	7c02                	ld	s8,32(sp)
ffffffffc0203152:	6ce2                	ld	s9,24(sp)
ffffffffc0203154:	6d42                	ld	s10,16(sp)
ffffffffc0203156:	6da2                	ld	s11,8(sp)
ffffffffc0203158:	6165                	addi	sp,sp,112
ffffffffc020315a:	8082                	ret
            if ((nptep = get_pte(to, start, 1)) == NULL) {
ffffffffc020315c:	4605                	li	a2,1
ffffffffc020315e:	85a2                	mv	a1,s0
ffffffffc0203160:	8552                	mv	a0,s4
ffffffffc0203162:	dfffe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0203166:	cd49                	beqz	a0,ffffffffc0203200 <copy_range+0x142>
            uint32_t perm = (*ptep & PTE_USER);
ffffffffc0203168:	000c3783          	ld	a5,0(s8) # 200000 <_binary_obj___user_exit_out_size+0x1f5580>
    if (!(pte & PTE_V)) {
ffffffffc020316c:	0017f713          	andi	a4,a5,1
ffffffffc0203170:	01f7fc13          	andi	s8,a5,31
ffffffffc0203174:	cb41                	beqz	a4,ffffffffc0203204 <copy_range+0x146>
    if (PPN(pa) >= npage) {
ffffffffc0203176:	000bb683          	ld	a3,0(s7)
    return pa2page(PTE_ADDR(pte));
ffffffffc020317a:	078a                	slli	a5,a5,0x2
ffffffffc020317c:	00c7d713          	srli	a4,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203180:	12d77763          	bleu	a3,a4,ffffffffc02032ae <copy_range+0x1f0>
    return &pages[PPN(pa) - nbase];
ffffffffc0203184:	000b3783          	ld	a5,0(s6)
ffffffffc0203188:	976a                	add	a4,a4,s10
ffffffffc020318a:	071a                	slli	a4,a4,0x6
            struct Page *npage = alloc_page();
ffffffffc020318c:	4505                	li	a0,1
ffffffffc020318e:	00e78cb3          	add	s9,a5,a4
ffffffffc0203192:	cc1fe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0203196:	8daa                	mv	s11,a0
            assert(page != NULL);
ffffffffc0203198:	0e0c8b63          	beqz	s9,ffffffffc020328e <copy_range+0x1d0>
            assert(npage != NULL);
ffffffffc020319c:	c969                	beqz	a0,ffffffffc020326e <copy_range+0x1b0>
    return page - pages + nbase;
ffffffffc020319e:	000b3683          	ld	a3,0(s6)
    return KADDR(page2pa(page));
ffffffffc02031a2:	000bb603          	ld	a2,0(s7)
    return page - pages + nbase;
ffffffffc02031a6:	8d15                	sub	a0,a0,a3
ffffffffc02031a8:	8519                	srai	a0,a0,0x6
ffffffffc02031aa:	9556                	add	a0,a0,s5
    return KADDR(page2pa(page));
ffffffffc02031ac:	013575b3          	and	a1,a0,s3
    return page2ppn(page) << PGSHIFT;
ffffffffc02031b0:	0532                	slli	a0,a0,0xc
    return KADDR(page2pa(page));
ffffffffc02031b2:	0ac5f163          	bleu	a2,a1,ffffffffc0203254 <copy_range+0x196>
ffffffffc02031b6:	000a9797          	auipc	a5,0xa9
ffffffffc02031ba:	35278793          	addi	a5,a5,850 # ffffffffc02ac508 <va_pa_offset>
    return page - pages + nbase;
ffffffffc02031be:	40dc86b3          	sub	a3,s9,a3
    return KADDR(page2pa(page));
ffffffffc02031c2:	638c                	ld	a1,0(a5)
    return page - pages + nbase;
ffffffffc02031c4:	8699                	srai	a3,a3,0x6
ffffffffc02031c6:	96d6                	add	a3,a3,s5
    return KADDR(page2pa(page));
ffffffffc02031c8:	0136f7b3          	and	a5,a3,s3
ffffffffc02031cc:	952e                	add	a0,a0,a1
    return page2ppn(page) << PGSHIFT;
ffffffffc02031ce:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02031d0:	06c7f663          	bleu	a2,a5,ffffffffc020323c <copy_range+0x17e>
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
ffffffffc02031d4:	95b6                	add	a1,a1,a3
ffffffffc02031d6:	6605                	lui	a2,0x1
ffffffffc02031d8:	428030ef          	jal	ra,ffffffffc0206600 <memcpy>
            if ((ret = page_insert(to, npage, start, perm)) != 0) {
ffffffffc02031dc:	86e2                	mv	a3,s8
ffffffffc02031de:	8622                	mv	a2,s0
ffffffffc02031e0:	85ee                	mv	a1,s11
ffffffffc02031e2:	8552                	mv	a0,s4
ffffffffc02031e4:	b92ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc02031e8:	d531                	beqz	a0,ffffffffc0203134 <copy_range+0x76>
ffffffffc02031ea:	bf91                	j	ffffffffc020313e <copy_range+0x80>
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
ffffffffc02031ec:	002007b7          	lui	a5,0x200
ffffffffc02031f0:	943e                	add	s0,s0,a5
ffffffffc02031f2:	ffe007b7          	lui	a5,0xffe00
ffffffffc02031f6:	8c7d                	and	s0,s0,a5
    } while (start != 0 && start < end);
ffffffffc02031f8:	d031                	beqz	s0,ffffffffc020313c <copy_range+0x7e>
ffffffffc02031fa:	f29463e3          	bltu	s0,s1,ffffffffc0203120 <copy_range+0x62>
ffffffffc02031fe:	bf3d                	j	ffffffffc020313c <copy_range+0x7e>
                return -E_NO_MEM;
ffffffffc0203200:	5571                	li	a0,-4
ffffffffc0203202:	bf35                	j	ffffffffc020313e <copy_range+0x80>
        panic("pte2page called with invalid pte");
ffffffffc0203204:	00004617          	auipc	a2,0x4
ffffffffc0203208:	44460613          	addi	a2,a2,1092 # ffffffffc0207648 <default_pmm_manager+0x2f8>
ffffffffc020320c:	07400593          	li	a1,116
ffffffffc0203210:	00004517          	auipc	a0,0x4
ffffffffc0203214:	1b850513          	addi	a0,a0,440 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0203218:	a6cfd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(USER_ACCESS(start, end));
ffffffffc020321c:	00005697          	auipc	a3,0x5
ffffffffc0203220:	83c68693          	addi	a3,a3,-1988 # ffffffffc0207a58 <default_pmm_manager+0x708>
ffffffffc0203224:	00004617          	auipc	a2,0x4
ffffffffc0203228:	9e460613          	addi	a2,a2,-1564 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020322c:	16600593          	li	a1,358
ffffffffc0203230:	00004517          	auipc	a0,0x4
ffffffffc0203234:	28050513          	addi	a0,a0,640 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc0203238:	a4cfd0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc020323c:	00004617          	auipc	a2,0x4
ffffffffc0203240:	16460613          	addi	a2,a2,356 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0203244:	06900593          	li	a1,105
ffffffffc0203248:	00004517          	auipc	a0,0x4
ffffffffc020324c:	18050513          	addi	a0,a0,384 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0203250:	a34fd0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0203254:	86aa                	mv	a3,a0
ffffffffc0203256:	00004617          	auipc	a2,0x4
ffffffffc020325a:	14a60613          	addi	a2,a2,330 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc020325e:	06900593          	li	a1,105
ffffffffc0203262:	00004517          	auipc	a0,0x4
ffffffffc0203266:	16650513          	addi	a0,a0,358 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc020326a:	a1afd0ef          	jal	ra,ffffffffc0200484 <__panic>
            assert(npage != NULL);
ffffffffc020326e:	00004697          	auipc	a3,0x4
ffffffffc0203272:	23268693          	addi	a3,a3,562 # ffffffffc02074a0 <default_pmm_manager+0x150>
ffffffffc0203276:	00004617          	auipc	a2,0x4
ffffffffc020327a:	99260613          	addi	a2,a2,-1646 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020327e:	17b00593          	li	a1,379
ffffffffc0203282:	00004517          	auipc	a0,0x4
ffffffffc0203286:	22e50513          	addi	a0,a0,558 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc020328a:	9fafd0ef          	jal	ra,ffffffffc0200484 <__panic>
            assert(page != NULL);
ffffffffc020328e:	00004697          	auipc	a3,0x4
ffffffffc0203292:	20268693          	addi	a3,a3,514 # ffffffffc0207490 <default_pmm_manager+0x140>
ffffffffc0203296:	00004617          	auipc	a2,0x4
ffffffffc020329a:	97260613          	addi	a2,a2,-1678 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020329e:	17a00593          	li	a1,378
ffffffffc02032a2:	00004517          	auipc	a0,0x4
ffffffffc02032a6:	20e50513          	addi	a0,a0,526 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc02032aa:	9dafd0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02032ae:	00004617          	auipc	a2,0x4
ffffffffc02032b2:	15260613          	addi	a2,a2,338 # ffffffffc0207400 <default_pmm_manager+0xb0>
ffffffffc02032b6:	06200593          	li	a1,98
ffffffffc02032ba:	00004517          	auipc	a0,0x4
ffffffffc02032be:	10e50513          	addi	a0,a0,270 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc02032c2:	9c2fd0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
ffffffffc02032c6:	00004697          	auipc	a3,0x4
ffffffffc02032ca:	76268693          	addi	a3,a3,1890 # ffffffffc0207a28 <default_pmm_manager+0x6d8>
ffffffffc02032ce:	00004617          	auipc	a2,0x4
ffffffffc02032d2:	93a60613          	addi	a2,a2,-1734 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02032d6:	16500593          	li	a1,357
ffffffffc02032da:	00004517          	auipc	a0,0x4
ffffffffc02032de:	1d650513          	addi	a0,a0,470 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc02032e2:	9a2fd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02032e6 <tlb_invalidate>:
    asm volatile("sfence.vma %0" : : "r"(la));
ffffffffc02032e6:	12058073          	sfence.vma	a1
}
ffffffffc02032ea:	8082                	ret

ffffffffc02032ec <pgdir_alloc_page>:
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc02032ec:	7179                	addi	sp,sp,-48
ffffffffc02032ee:	e84a                	sd	s2,16(sp)
ffffffffc02032f0:	892a                	mv	s2,a0
    struct Page *page = alloc_page();
ffffffffc02032f2:	4505                	li	a0,1
struct Page *pgdir_alloc_page(pde_t *pgdir, uintptr_t la, uint32_t perm) {
ffffffffc02032f4:	f022                	sd	s0,32(sp)
ffffffffc02032f6:	ec26                	sd	s1,24(sp)
ffffffffc02032f8:	e44e                	sd	s3,8(sp)
ffffffffc02032fa:	f406                	sd	ra,40(sp)
ffffffffc02032fc:	84ae                	mv	s1,a1
ffffffffc02032fe:	89b2                	mv	s3,a2
    struct Page *page = alloc_page();
ffffffffc0203300:	b53fe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0203304:	842a                	mv	s0,a0
    if (page != NULL) {
ffffffffc0203306:	cd1d                	beqz	a0,ffffffffc0203344 <pgdir_alloc_page+0x58>
        if (page_insert(pgdir, page, la, perm) != 0) {
ffffffffc0203308:	85aa                	mv	a1,a0
ffffffffc020330a:	86ce                	mv	a3,s3
ffffffffc020330c:	8626                	mv	a2,s1
ffffffffc020330e:	854a                	mv	a0,s2
ffffffffc0203310:	a66ff0ef          	jal	ra,ffffffffc0202576 <page_insert>
ffffffffc0203314:	e121                	bnez	a0,ffffffffc0203354 <pgdir_alloc_page+0x68>
        if (swap_init_ok) {
ffffffffc0203316:	000a9797          	auipc	a5,0xa9
ffffffffc020331a:	1a278793          	addi	a5,a5,418 # ffffffffc02ac4b8 <swap_init_ok>
ffffffffc020331e:	439c                	lw	a5,0(a5)
ffffffffc0203320:	2781                	sext.w	a5,a5
ffffffffc0203322:	c38d                	beqz	a5,ffffffffc0203344 <pgdir_alloc_page+0x58>
            if (check_mm_struct != NULL) {
ffffffffc0203324:	000a9797          	auipc	a5,0xa9
ffffffffc0203328:	2d478793          	addi	a5,a5,724 # ffffffffc02ac5f8 <check_mm_struct>
ffffffffc020332c:	6388                	ld	a0,0(a5)
ffffffffc020332e:	c919                	beqz	a0,ffffffffc0203344 <pgdir_alloc_page+0x58>
                swap_map_swappable(check_mm_struct, la, page, 0);
ffffffffc0203330:	4681                	li	a3,0
ffffffffc0203332:	8622                	mv	a2,s0
ffffffffc0203334:	85a6                	mv	a1,s1
ffffffffc0203336:	7da000ef          	jal	ra,ffffffffc0203b10 <swap_map_swappable>
                assert(page_ref(page) == 1);
ffffffffc020333a:	4018                	lw	a4,0(s0)
                page->pra_vaddr = la;
ffffffffc020333c:	fc04                	sd	s1,56(s0)
                assert(page_ref(page) == 1);
ffffffffc020333e:	4785                	li	a5,1
ffffffffc0203340:	02f71063          	bne	a4,a5,ffffffffc0203360 <pgdir_alloc_page+0x74>
}
ffffffffc0203344:	8522                	mv	a0,s0
ffffffffc0203346:	70a2                	ld	ra,40(sp)
ffffffffc0203348:	7402                	ld	s0,32(sp)
ffffffffc020334a:	64e2                	ld	s1,24(sp)
ffffffffc020334c:	6942                	ld	s2,16(sp)
ffffffffc020334e:	69a2                	ld	s3,8(sp)
ffffffffc0203350:	6145                	addi	sp,sp,48
ffffffffc0203352:	8082                	ret
            free_page(page);
ffffffffc0203354:	8522                	mv	a0,s0
ffffffffc0203356:	4585                	li	a1,1
ffffffffc0203358:	b83fe0ef          	jal	ra,ffffffffc0201eda <free_pages>
            return NULL;
ffffffffc020335c:	4401                	li	s0,0
ffffffffc020335e:	b7dd                	j	ffffffffc0203344 <pgdir_alloc_page+0x58>
                assert(page_ref(page) == 1);
ffffffffc0203360:	00004697          	auipc	a3,0x4
ffffffffc0203364:	16068693          	addi	a3,a3,352 # ffffffffc02074c0 <default_pmm_manager+0x170>
ffffffffc0203368:	00004617          	auipc	a2,0x4
ffffffffc020336c:	8a060613          	addi	a2,a2,-1888 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203370:	1d300593          	li	a1,467
ffffffffc0203374:	00004517          	auipc	a0,0x4
ffffffffc0203378:	13c50513          	addi	a0,a0,316 # ffffffffc02074b0 <default_pmm_manager+0x160>
ffffffffc020337c:	908fd0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203380 <swap_init>:

static void check_swap(void);

int
swap_init(void)
{
ffffffffc0203380:	7135                	addi	sp,sp,-160
ffffffffc0203382:	ed06                	sd	ra,152(sp)
ffffffffc0203384:	e922                	sd	s0,144(sp)
ffffffffc0203386:	e526                	sd	s1,136(sp)
ffffffffc0203388:	e14a                	sd	s2,128(sp)
ffffffffc020338a:	fcce                	sd	s3,120(sp)
ffffffffc020338c:	f8d2                	sd	s4,112(sp)
ffffffffc020338e:	f4d6                	sd	s5,104(sp)
ffffffffc0203390:	f0da                	sd	s6,96(sp)
ffffffffc0203392:	ecde                	sd	s7,88(sp)
ffffffffc0203394:	e8e2                	sd	s8,80(sp)
ffffffffc0203396:	e4e6                	sd	s9,72(sp)
ffffffffc0203398:	e0ea                	sd	s10,64(sp)
ffffffffc020339a:	fc6e                	sd	s11,56(sp)
     swapfs_init();
ffffffffc020339c:	77a010ef          	jal	ra,ffffffffc0204b16 <swapfs_init>

     // Since the IDE is faked, it can only store 7 pages at most to pass the test
     if (!(7 <= max_swap_offset &&
ffffffffc02033a0:	000a9797          	auipc	a5,0xa9
ffffffffc02033a4:	20878793          	addi	a5,a5,520 # ffffffffc02ac5a8 <max_swap_offset>
ffffffffc02033a8:	6394                	ld	a3,0(a5)
ffffffffc02033aa:	010007b7          	lui	a5,0x1000
ffffffffc02033ae:	17e1                	addi	a5,a5,-8
ffffffffc02033b0:	ff968713          	addi	a4,a3,-7
ffffffffc02033b4:	4ae7ee63          	bltu	a5,a4,ffffffffc0203870 <swap_init+0x4f0>
        max_swap_offset < MAX_SWAP_OFFSET_LIMIT)) {
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
     }
     

     sm = &swap_manager_fifo;
ffffffffc02033b8:	0009e797          	auipc	a5,0x9e
ffffffffc02033bc:	c8078793          	addi	a5,a5,-896 # ffffffffc02a1038 <swap_manager_fifo>
     int r = sm->init();
ffffffffc02033c0:	6798                	ld	a4,8(a5)
     sm = &swap_manager_fifo;
ffffffffc02033c2:	000a9697          	auipc	a3,0xa9
ffffffffc02033c6:	0ef6b723          	sd	a5,238(a3) # ffffffffc02ac4b0 <sm>
     int r = sm->init();
ffffffffc02033ca:	9702                	jalr	a4
ffffffffc02033cc:	8aaa                	mv	s5,a0
     
     if (r == 0)
ffffffffc02033ce:	c10d                	beqz	a0,ffffffffc02033f0 <swap_init+0x70>
          cprintf("SWAP: manager = %s\n", sm->name);
          check_swap();
     }

     return r;
}
ffffffffc02033d0:	60ea                	ld	ra,152(sp)
ffffffffc02033d2:	644a                	ld	s0,144(sp)
ffffffffc02033d4:	8556                	mv	a0,s5
ffffffffc02033d6:	64aa                	ld	s1,136(sp)
ffffffffc02033d8:	690a                	ld	s2,128(sp)
ffffffffc02033da:	79e6                	ld	s3,120(sp)
ffffffffc02033dc:	7a46                	ld	s4,112(sp)
ffffffffc02033de:	7aa6                	ld	s5,104(sp)
ffffffffc02033e0:	7b06                	ld	s6,96(sp)
ffffffffc02033e2:	6be6                	ld	s7,88(sp)
ffffffffc02033e4:	6c46                	ld	s8,80(sp)
ffffffffc02033e6:	6ca6                	ld	s9,72(sp)
ffffffffc02033e8:	6d06                	ld	s10,64(sp)
ffffffffc02033ea:	7de2                	ld	s11,56(sp)
ffffffffc02033ec:	610d                	addi	sp,sp,160
ffffffffc02033ee:	8082                	ret
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc02033f0:	000a9797          	auipc	a5,0xa9
ffffffffc02033f4:	0c078793          	addi	a5,a5,192 # ffffffffc02ac4b0 <sm>
ffffffffc02033f8:	639c                	ld	a5,0(a5)
ffffffffc02033fa:	00004517          	auipc	a0,0x4
ffffffffc02033fe:	6f650513          	addi	a0,a0,1782 # ffffffffc0207af0 <default_pmm_manager+0x7a0>
    return listelm->next;
ffffffffc0203402:	000a9417          	auipc	s0,0xa9
ffffffffc0203406:	0e640413          	addi	s0,s0,230 # ffffffffc02ac4e8 <free_area>
ffffffffc020340a:	638c                	ld	a1,0(a5)
          swap_init_ok = 1;
ffffffffc020340c:	4785                	li	a5,1
ffffffffc020340e:	000a9717          	auipc	a4,0xa9
ffffffffc0203412:	0af72523          	sw	a5,170(a4) # ffffffffc02ac4b8 <swap_init_ok>
          cprintf("SWAP: manager = %s\n", sm->name);
ffffffffc0203416:	d79fc0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc020341a:	641c                	ld	a5,8(s0)
check_swap(void)
{
    //backup mem env
     int ret, count = 0, total = 0, i;
     list_entry_t *le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc020341c:	36878e63          	beq	a5,s0,ffffffffc0203798 <swap_init+0x418>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0203420:	ff07b703          	ld	a4,-16(a5)
ffffffffc0203424:	8305                	srli	a4,a4,0x1
ffffffffc0203426:	8b05                	andi	a4,a4,1
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0203428:	36070c63          	beqz	a4,ffffffffc02037a0 <swap_init+0x420>
     int ret, count = 0, total = 0, i;
ffffffffc020342c:	4481                	li	s1,0
ffffffffc020342e:	4901                	li	s2,0
ffffffffc0203430:	a031                	j	ffffffffc020343c <swap_init+0xbc>
ffffffffc0203432:	ff07b703          	ld	a4,-16(a5)
        assert(PageProperty(p));
ffffffffc0203436:	8b09                	andi	a4,a4,2
ffffffffc0203438:	36070463          	beqz	a4,ffffffffc02037a0 <swap_init+0x420>
        count ++, total += p->property;
ffffffffc020343c:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203440:	679c                	ld	a5,8(a5)
ffffffffc0203442:	2905                	addiw	s2,s2,1
ffffffffc0203444:	9cb9                	addw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203446:	fe8796e3          	bne	a5,s0,ffffffffc0203432 <swap_init+0xb2>
ffffffffc020344a:	89a6                	mv	s3,s1
     }
     assert(total == nr_free_pages());
ffffffffc020344c:	ad5fe0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc0203450:	69351863          	bne	a0,s3,ffffffffc0203ae0 <swap_init+0x760>
     cprintf("BEGIN check_swap: count %d, total %d\n",count,total);
ffffffffc0203454:	8626                	mv	a2,s1
ffffffffc0203456:	85ca                	mv	a1,s2
ffffffffc0203458:	00004517          	auipc	a0,0x4
ffffffffc020345c:	6b050513          	addi	a0,a0,1712 # ffffffffc0207b08 <default_pmm_manager+0x7b8>
ffffffffc0203460:	d2ffc0ef          	jal	ra,ffffffffc020018e <cprintf>
     
     //now we set the phy pages env     
     struct mm_struct *mm = mm_create();
ffffffffc0203464:	457000ef          	jal	ra,ffffffffc02040ba <mm_create>
ffffffffc0203468:	8baa                	mv	s7,a0
     assert(mm != NULL);
ffffffffc020346a:	60050b63          	beqz	a0,ffffffffc0203a80 <swap_init+0x700>

     extern struct mm_struct *check_mm_struct;
     assert(check_mm_struct == NULL);
ffffffffc020346e:	000a9797          	auipc	a5,0xa9
ffffffffc0203472:	18a78793          	addi	a5,a5,394 # ffffffffc02ac5f8 <check_mm_struct>
ffffffffc0203476:	639c                	ld	a5,0(a5)
ffffffffc0203478:	62079463          	bnez	a5,ffffffffc0203aa0 <swap_init+0x720>

     check_mm_struct = mm;

     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc020347c:	000a9797          	auipc	a5,0xa9
ffffffffc0203480:	02478793          	addi	a5,a5,36 # ffffffffc02ac4a0 <boot_pgdir>
ffffffffc0203484:	0007bb03          	ld	s6,0(a5)
     check_mm_struct = mm;
ffffffffc0203488:	000a9797          	auipc	a5,0xa9
ffffffffc020348c:	16a7b823          	sd	a0,368(a5) # ffffffffc02ac5f8 <check_mm_struct>
     assert(pgdir[0] == 0);
ffffffffc0203490:	000b3783          	ld	a5,0(s6)
     pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0203494:	01653c23          	sd	s6,24(a0)
     assert(pgdir[0] == 0);
ffffffffc0203498:	4e079863          	bnez	a5,ffffffffc0203988 <swap_init+0x608>

     struct vma_struct *vma = vma_create(BEING_CHECK_VALID_VADDR, CHECK_VALID_VADDR, VM_WRITE | VM_READ);
ffffffffc020349c:	6599                	lui	a1,0x6
ffffffffc020349e:	460d                	li	a2,3
ffffffffc02034a0:	6505                	lui	a0,0x1
ffffffffc02034a2:	465000ef          	jal	ra,ffffffffc0204106 <vma_create>
ffffffffc02034a6:	85aa                	mv	a1,a0
     assert(vma != NULL);
ffffffffc02034a8:	50050063          	beqz	a0,ffffffffc02039a8 <swap_init+0x628>

     insert_vma_struct(mm, vma);
ffffffffc02034ac:	855e                	mv	a0,s7
ffffffffc02034ae:	4c5000ef          	jal	ra,ffffffffc0204172 <insert_vma_struct>

     //setup the temp Page Table vaddr 0~4MB
     cprintf("setup Page Table for vaddr 0X1000, so alloc a page\n");
ffffffffc02034b2:	00004517          	auipc	a0,0x4
ffffffffc02034b6:	6c650513          	addi	a0,a0,1734 # ffffffffc0207b78 <default_pmm_manager+0x828>
ffffffffc02034ba:	cd5fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     pte_t *temp_ptep=NULL;
     temp_ptep = get_pte(mm->pgdir, BEING_CHECK_VALID_VADDR, 1);
ffffffffc02034be:	018bb503          	ld	a0,24(s7)
ffffffffc02034c2:	4605                	li	a2,1
ffffffffc02034c4:	6585                	lui	a1,0x1
ffffffffc02034c6:	a9bfe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
     assert(temp_ptep!= NULL);
ffffffffc02034ca:	4e050f63          	beqz	a0,ffffffffc02039c8 <swap_init+0x648>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02034ce:	00004517          	auipc	a0,0x4
ffffffffc02034d2:	6fa50513          	addi	a0,a0,1786 # ffffffffc0207bc8 <default_pmm_manager+0x878>
ffffffffc02034d6:	000a9997          	auipc	s3,0xa9
ffffffffc02034da:	04a98993          	addi	s3,s3,74 # ffffffffc02ac520 <check_rp>
ffffffffc02034de:	cb1fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02034e2:	000a9a17          	auipc	s4,0xa9
ffffffffc02034e6:	05ea0a13          	addi	s4,s4,94 # ffffffffc02ac540 <swap_in_seq_no>
     cprintf("setup Page Table vaddr 0~4MB OVER!\n");
ffffffffc02034ea:	8c4e                	mv	s8,s3
          check_rp[i] = alloc_page();
ffffffffc02034ec:	4505                	li	a0,1
ffffffffc02034ee:	965fe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc02034f2:	00ac3023          	sd	a0,0(s8)
          assert(check_rp[i] != NULL );
ffffffffc02034f6:	32050d63          	beqz	a0,ffffffffc0203830 <swap_init+0x4b0>
ffffffffc02034fa:	651c                	ld	a5,8(a0)
          assert(!PageProperty(check_rp[i]));
ffffffffc02034fc:	8b89                	andi	a5,a5,2
ffffffffc02034fe:	30079963          	bnez	a5,ffffffffc0203810 <swap_init+0x490>
ffffffffc0203502:	0c21                	addi	s8,s8,8
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203504:	ff4c14e3          	bne	s8,s4,ffffffffc02034ec <swap_init+0x16c>
     }
     list_entry_t free_list_store = free_list;
ffffffffc0203508:	601c                	ld	a5,0(s0)
     assert(list_empty(&free_list));
     
     //assert(alloc_page() == NULL);
     
     unsigned int nr_free_store = nr_free;
     nr_free = 0;
ffffffffc020350a:	000a9c17          	auipc	s8,0xa9
ffffffffc020350e:	016c0c13          	addi	s8,s8,22 # ffffffffc02ac520 <check_rp>
     list_entry_t free_list_store = free_list;
ffffffffc0203512:	ec3e                	sd	a5,24(sp)
ffffffffc0203514:	641c                	ld	a5,8(s0)
ffffffffc0203516:	f03e                	sd	a5,32(sp)
     unsigned int nr_free_store = nr_free;
ffffffffc0203518:	481c                	lw	a5,16(s0)
ffffffffc020351a:	f43e                	sd	a5,40(sp)
    elm->prev = elm->next = elm;
ffffffffc020351c:	000a9797          	auipc	a5,0xa9
ffffffffc0203520:	fc87ba23          	sd	s0,-44(a5) # ffffffffc02ac4f0 <free_area+0x8>
ffffffffc0203524:	000a9797          	auipc	a5,0xa9
ffffffffc0203528:	fc87b223          	sd	s0,-60(a5) # ffffffffc02ac4e8 <free_area>
     nr_free = 0;
ffffffffc020352c:	000a9797          	auipc	a5,0xa9
ffffffffc0203530:	fc07a623          	sw	zero,-52(a5) # ffffffffc02ac4f8 <free_area+0x10>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
        free_pages(check_rp[i],1);
ffffffffc0203534:	000c3503          	ld	a0,0(s8)
ffffffffc0203538:	4585                	li	a1,1
ffffffffc020353a:	0c21                	addi	s8,s8,8
ffffffffc020353c:	99ffe0ef          	jal	ra,ffffffffc0201eda <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203540:	ff4c1ae3          	bne	s8,s4,ffffffffc0203534 <swap_init+0x1b4>
     }
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203544:	01042c03          	lw	s8,16(s0)
ffffffffc0203548:	4791                	li	a5,4
ffffffffc020354a:	50fc1b63          	bne	s8,a5,ffffffffc0203a60 <swap_init+0x6e0>
     
     cprintf("set up init env for check_swap begin!\n");
ffffffffc020354e:	00004517          	auipc	a0,0x4
ffffffffc0203552:	70250513          	addi	a0,a0,1794 # ffffffffc0207c50 <default_pmm_manager+0x900>
ffffffffc0203556:	c39fc0ef          	jal	ra,ffffffffc020018e <cprintf>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc020355a:	6685                	lui	a3,0x1
     //setup initial vir_page<->phy_page environment for page relpacement algorithm 

     
     pgfault_num=0;
ffffffffc020355c:	000a9797          	auipc	a5,0xa9
ffffffffc0203560:	f607a023          	sw	zero,-160(a5) # ffffffffc02ac4bc <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203564:	4629                	li	a2,10
     pgfault_num=0;
ffffffffc0203566:	000a9797          	auipc	a5,0xa9
ffffffffc020356a:	f5678793          	addi	a5,a5,-170 # ffffffffc02ac4bc <pgfault_num>
     *(unsigned char *)0x1000 = 0x0a;
ffffffffc020356e:	00c68023          	sb	a2,0(a3) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
     assert(pgfault_num==1);
ffffffffc0203572:	4398                	lw	a4,0(a5)
ffffffffc0203574:	4585                	li	a1,1
ffffffffc0203576:	2701                	sext.w	a4,a4
ffffffffc0203578:	38b71863          	bne	a4,a1,ffffffffc0203908 <swap_init+0x588>
     *(unsigned char *)0x1010 = 0x0a;
ffffffffc020357c:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==1);
ffffffffc0203580:	4394                	lw	a3,0(a5)
ffffffffc0203582:	2681                	sext.w	a3,a3
ffffffffc0203584:	3ae69263          	bne	a3,a4,ffffffffc0203928 <swap_init+0x5a8>
     *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203588:	6689                	lui	a3,0x2
ffffffffc020358a:	462d                	li	a2,11
ffffffffc020358c:	00c68023          	sb	a2,0(a3) # 2000 <_binary_obj___user_faultread_out_size-0x7580>
     assert(pgfault_num==2);
ffffffffc0203590:	4398                	lw	a4,0(a5)
ffffffffc0203592:	4589                	li	a1,2
ffffffffc0203594:	2701                	sext.w	a4,a4
ffffffffc0203596:	2eb71963          	bne	a4,a1,ffffffffc0203888 <swap_init+0x508>
     *(unsigned char *)0x2010 = 0x0b;
ffffffffc020359a:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==2);
ffffffffc020359e:	4394                	lw	a3,0(a5)
ffffffffc02035a0:	2681                	sext.w	a3,a3
ffffffffc02035a2:	30e69363          	bne	a3,a4,ffffffffc02038a8 <swap_init+0x528>
     *(unsigned char *)0x3000 = 0x0c;
ffffffffc02035a6:	668d                	lui	a3,0x3
ffffffffc02035a8:	4631                	li	a2,12
ffffffffc02035aa:	00c68023          	sb	a2,0(a3) # 3000 <_binary_obj___user_faultread_out_size-0x6580>
     assert(pgfault_num==3);
ffffffffc02035ae:	4398                	lw	a4,0(a5)
ffffffffc02035b0:	458d                	li	a1,3
ffffffffc02035b2:	2701                	sext.w	a4,a4
ffffffffc02035b4:	30b71a63          	bne	a4,a1,ffffffffc02038c8 <swap_init+0x548>
     *(unsigned char *)0x3010 = 0x0c;
ffffffffc02035b8:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==3);
ffffffffc02035bc:	4394                	lw	a3,0(a5)
ffffffffc02035be:	2681                	sext.w	a3,a3
ffffffffc02035c0:	32e69463          	bne	a3,a4,ffffffffc02038e8 <swap_init+0x568>
     *(unsigned char *)0x4000 = 0x0d;
ffffffffc02035c4:	6691                	lui	a3,0x4
ffffffffc02035c6:	4635                	li	a2,13
ffffffffc02035c8:	00c68023          	sb	a2,0(a3) # 4000 <_binary_obj___user_faultread_out_size-0x5580>
     assert(pgfault_num==4);
ffffffffc02035cc:	4398                	lw	a4,0(a5)
ffffffffc02035ce:	2701                	sext.w	a4,a4
ffffffffc02035d0:	37871c63          	bne	a4,s8,ffffffffc0203948 <swap_init+0x5c8>
     *(unsigned char *)0x4010 = 0x0d;
ffffffffc02035d4:	00c68823          	sb	a2,16(a3)
     assert(pgfault_num==4);
ffffffffc02035d8:	439c                	lw	a5,0(a5)
ffffffffc02035da:	2781                	sext.w	a5,a5
ffffffffc02035dc:	38e79663          	bne	a5,a4,ffffffffc0203968 <swap_init+0x5e8>
     
     check_content_set();
     assert( nr_free == 0);         
ffffffffc02035e0:	481c                	lw	a5,16(s0)
ffffffffc02035e2:	40079363          	bnez	a5,ffffffffc02039e8 <swap_init+0x668>
ffffffffc02035e6:	000a9797          	auipc	a5,0xa9
ffffffffc02035ea:	f5a78793          	addi	a5,a5,-166 # ffffffffc02ac540 <swap_in_seq_no>
ffffffffc02035ee:	000a9717          	auipc	a4,0xa9
ffffffffc02035f2:	f7a70713          	addi	a4,a4,-134 # ffffffffc02ac568 <swap_out_seq_no>
ffffffffc02035f6:	000a9617          	auipc	a2,0xa9
ffffffffc02035fa:	f7260613          	addi	a2,a2,-142 # ffffffffc02ac568 <swap_out_seq_no>
     for(i = 0; i<MAX_SEQ_NO ; i++) 
         swap_out_seq_no[i]=swap_in_seq_no[i]=-1;
ffffffffc02035fe:	56fd                	li	a3,-1
ffffffffc0203600:	c394                	sw	a3,0(a5)
ffffffffc0203602:	c314                	sw	a3,0(a4)
ffffffffc0203604:	0791                	addi	a5,a5,4
ffffffffc0203606:	0711                	addi	a4,a4,4
     for(i = 0; i<MAX_SEQ_NO ; i++) 
ffffffffc0203608:	fef61ce3          	bne	a2,a5,ffffffffc0203600 <swap_init+0x280>
ffffffffc020360c:	000a9697          	auipc	a3,0xa9
ffffffffc0203610:	fbc68693          	addi	a3,a3,-68 # ffffffffc02ac5c8 <check_ptep>
ffffffffc0203614:	000a9817          	auipc	a6,0xa9
ffffffffc0203618:	f0c80813          	addi	a6,a6,-244 # ffffffffc02ac520 <check_rp>
ffffffffc020361c:	6d05                	lui	s10,0x1
    if (PPN(pa) >= npage) {
ffffffffc020361e:	000a9c97          	auipc	s9,0xa9
ffffffffc0203622:	e8ac8c93          	addi	s9,s9,-374 # ffffffffc02ac4a8 <npage>
    return &pages[PPN(pa) - nbase];
ffffffffc0203626:	00005d97          	auipc	s11,0x5
ffffffffc020362a:	6b2d8d93          	addi	s11,s11,1714 # ffffffffc0208cd8 <nbase>
ffffffffc020362e:	000a9c17          	auipc	s8,0xa9
ffffffffc0203632:	eeac0c13          	addi	s8,s8,-278 # ffffffffc02ac518 <pages>
     
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         check_ptep[i]=0;
ffffffffc0203636:	0006b023          	sd	zero,0(a3)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020363a:	4601                	li	a2,0
ffffffffc020363c:	85ea                	mv	a1,s10
ffffffffc020363e:	855a                	mv	a0,s6
ffffffffc0203640:	e842                	sd	a6,16(sp)
         check_ptep[i]=0;
ffffffffc0203642:	e436                	sd	a3,8(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc0203644:	91dfe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0203648:	66a2                	ld	a3,8(sp)
         //cprintf("i %d, check_ptep addr %x, value %x\n", i, check_ptep[i], *check_ptep[i]);
         assert(check_ptep[i] != NULL);
ffffffffc020364a:	6842                	ld	a6,16(sp)
         check_ptep[i] = get_pte(pgdir, (i+1)*0x1000, 0);
ffffffffc020364c:	e288                	sd	a0,0(a3)
         assert(check_ptep[i] != NULL);
ffffffffc020364e:	20050163          	beqz	a0,ffffffffc0203850 <swap_init+0x4d0>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc0203652:	611c                	ld	a5,0(a0)
    if (!(pte & PTE_V)) {
ffffffffc0203654:	0017f613          	andi	a2,a5,1
ffffffffc0203658:	1a060063          	beqz	a2,ffffffffc02037f8 <swap_init+0x478>
    if (PPN(pa) >= npage) {
ffffffffc020365c:	000cb603          	ld	a2,0(s9)
    return pa2page(PTE_ADDR(pte));
ffffffffc0203660:	078a                	slli	a5,a5,0x2
ffffffffc0203662:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203664:	14c7fe63          	bleu	a2,a5,ffffffffc02037c0 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203668:	000db703          	ld	a4,0(s11)
ffffffffc020366c:	000c3603          	ld	a2,0(s8)
ffffffffc0203670:	00083583          	ld	a1,0(a6)
ffffffffc0203674:	8f99                	sub	a5,a5,a4
ffffffffc0203676:	079a                	slli	a5,a5,0x6
ffffffffc0203678:	e43a                	sd	a4,8(sp)
ffffffffc020367a:	97b2                	add	a5,a5,a2
ffffffffc020367c:	14f59e63          	bne	a1,a5,ffffffffc02037d8 <swap_init+0x458>
ffffffffc0203680:	6785                	lui	a5,0x1
ffffffffc0203682:	9d3e                	add	s10,s10,a5
     for (i= 0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc0203684:	6795                	lui	a5,0x5
ffffffffc0203686:	06a1                	addi	a3,a3,8
ffffffffc0203688:	0821                	addi	a6,a6,8
ffffffffc020368a:	fafd16e3          	bne	s10,a5,ffffffffc0203636 <swap_init+0x2b6>
         assert((*check_ptep[i] & PTE_V));          
     }
     cprintf("set up init env for check_swap over!\n");
ffffffffc020368e:	00004517          	auipc	a0,0x4
ffffffffc0203692:	66a50513          	addi	a0,a0,1642 # ffffffffc0207cf8 <default_pmm_manager+0x9a8>
ffffffffc0203696:	af9fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    int ret = sm->check_swap();
ffffffffc020369a:	000a9797          	auipc	a5,0xa9
ffffffffc020369e:	e1678793          	addi	a5,a5,-490 # ffffffffc02ac4b0 <sm>
ffffffffc02036a2:	639c                	ld	a5,0(a5)
ffffffffc02036a4:	7f9c                	ld	a5,56(a5)
ffffffffc02036a6:	9782                	jalr	a5
     // now access the virt pages to test  page relpacement algorithm 
     ret=check_content_access();
     assert(ret==0);
ffffffffc02036a8:	40051c63          	bnez	a0,ffffffffc0203ac0 <swap_init+0x740>

     nr_free = nr_free_store;
ffffffffc02036ac:	77a2                	ld	a5,40(sp)
ffffffffc02036ae:	000a9717          	auipc	a4,0xa9
ffffffffc02036b2:	e4f72523          	sw	a5,-438(a4) # ffffffffc02ac4f8 <free_area+0x10>
     free_list = free_list_store;
ffffffffc02036b6:	67e2                	ld	a5,24(sp)
ffffffffc02036b8:	000a9717          	auipc	a4,0xa9
ffffffffc02036bc:	e2f73823          	sd	a5,-464(a4) # ffffffffc02ac4e8 <free_area>
ffffffffc02036c0:	7782                	ld	a5,32(sp)
ffffffffc02036c2:	000a9717          	auipc	a4,0xa9
ffffffffc02036c6:	e2f73723          	sd	a5,-466(a4) # ffffffffc02ac4f0 <free_area+0x8>

     //restore kernel mem env
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
         free_pages(check_rp[i],1);
ffffffffc02036ca:	0009b503          	ld	a0,0(s3)
ffffffffc02036ce:	4585                	li	a1,1
ffffffffc02036d0:	09a1                	addi	s3,s3,8
ffffffffc02036d2:	809fe0ef          	jal	ra,ffffffffc0201eda <free_pages>
     for (i=0;i<CHECK_VALID_PHY_PAGE_NUM;i++) {
ffffffffc02036d6:	ff499ae3          	bne	s3,s4,ffffffffc02036ca <swap_init+0x34a>
     } 

     //free_page(pte2page(*temp_ptep));

     mm->pgdir = NULL;
ffffffffc02036da:	000bbc23          	sd	zero,24(s7)
     mm_destroy(mm);
ffffffffc02036de:	855e                	mv	a0,s7
ffffffffc02036e0:	361000ef          	jal	ra,ffffffffc0204240 <mm_destroy>
     check_mm_struct = NULL;

     pde_t *pd1=pgdir,*pd0=page2kva(pde2page(boot_pgdir[0]));
ffffffffc02036e4:	000a9797          	auipc	a5,0xa9
ffffffffc02036e8:	dbc78793          	addi	a5,a5,-580 # ffffffffc02ac4a0 <boot_pgdir>
ffffffffc02036ec:	639c                	ld	a5,0(a5)
     check_mm_struct = NULL;
ffffffffc02036ee:	000a9697          	auipc	a3,0xa9
ffffffffc02036f2:	f006b523          	sd	zero,-246(a3) # ffffffffc02ac5f8 <check_mm_struct>
    if (PPN(pa) >= npage) {
ffffffffc02036f6:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc02036fa:	6394                	ld	a3,0(a5)
ffffffffc02036fc:	068a                	slli	a3,a3,0x2
ffffffffc02036fe:	82b1                	srli	a3,a3,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203700:	0ce6f063          	bleu	a4,a3,ffffffffc02037c0 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203704:	67a2                	ld	a5,8(sp)
ffffffffc0203706:	000c3503          	ld	a0,0(s8)
ffffffffc020370a:	8e9d                	sub	a3,a3,a5
ffffffffc020370c:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc020370e:	8699                	srai	a3,a3,0x6
ffffffffc0203710:	96be                	add	a3,a3,a5
    return KADDR(page2pa(page));
ffffffffc0203712:	57fd                	li	a5,-1
ffffffffc0203714:	83b1                	srli	a5,a5,0xc
ffffffffc0203716:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0203718:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020371a:	2ee7f763          	bleu	a4,a5,ffffffffc0203a08 <swap_init+0x688>
     free_page(pde2page(pd0[0]));
ffffffffc020371e:	000a9797          	auipc	a5,0xa9
ffffffffc0203722:	dea78793          	addi	a5,a5,-534 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0203726:	639c                	ld	a5,0(a5)
ffffffffc0203728:	96be                	add	a3,a3,a5
    return pa2page(PDE_ADDR(pde));
ffffffffc020372a:	629c                	ld	a5,0(a3)
ffffffffc020372c:	078a                	slli	a5,a5,0x2
ffffffffc020372e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203730:	08e7f863          	bleu	a4,a5,ffffffffc02037c0 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203734:	69a2                	ld	s3,8(sp)
ffffffffc0203736:	4585                	li	a1,1
ffffffffc0203738:	413787b3          	sub	a5,a5,s3
ffffffffc020373c:	079a                	slli	a5,a5,0x6
ffffffffc020373e:	953e                	add	a0,a0,a5
ffffffffc0203740:	f9afe0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0203744:	000b3783          	ld	a5,0(s6)
    if (PPN(pa) >= npage) {
ffffffffc0203748:	000cb703          	ld	a4,0(s9)
    return pa2page(PDE_ADDR(pde));
ffffffffc020374c:	078a                	slli	a5,a5,0x2
ffffffffc020374e:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc0203750:	06e7f863          	bleu	a4,a5,ffffffffc02037c0 <swap_init+0x440>
    return &pages[PPN(pa) - nbase];
ffffffffc0203754:	000c3503          	ld	a0,0(s8)
ffffffffc0203758:	413787b3          	sub	a5,a5,s3
ffffffffc020375c:	079a                	slli	a5,a5,0x6
     free_page(pde2page(pd1[0]));
ffffffffc020375e:	4585                	li	a1,1
ffffffffc0203760:	953e                	add	a0,a0,a5
ffffffffc0203762:	f78fe0ef          	jal	ra,ffffffffc0201eda <free_pages>
     pgdir[0] = 0;
ffffffffc0203766:	000b3023          	sd	zero,0(s6)
  asm volatile("sfence.vma");
ffffffffc020376a:	12000073          	sfence.vma
    return listelm->next;
ffffffffc020376e:	641c                	ld	a5,8(s0)
     flush_tlb();

     le = &free_list;
     while ((le = list_next(le)) != &free_list) {
ffffffffc0203770:	00878963          	beq	a5,s0,ffffffffc0203782 <swap_init+0x402>
         struct Page *p = le2page(le, page_link);
         count --, total -= p->property;
ffffffffc0203774:	ff87a703          	lw	a4,-8(a5)
ffffffffc0203778:	679c                	ld	a5,8(a5)
ffffffffc020377a:	397d                	addiw	s2,s2,-1
ffffffffc020377c:	9c99                	subw	s1,s1,a4
     while ((le = list_next(le)) != &free_list) {
ffffffffc020377e:	fe879be3          	bne	a5,s0,ffffffffc0203774 <swap_init+0x3f4>
     }
     assert(count==0);
ffffffffc0203782:	28091f63          	bnez	s2,ffffffffc0203a20 <swap_init+0x6a0>
     assert(total==0);
ffffffffc0203786:	2a049d63          	bnez	s1,ffffffffc0203a40 <swap_init+0x6c0>

     cprintf("check_swap() succeeded!\n");
ffffffffc020378a:	00004517          	auipc	a0,0x4
ffffffffc020378e:	5be50513          	addi	a0,a0,1470 # ffffffffc0207d48 <default_pmm_manager+0x9f8>
ffffffffc0203792:	9fdfc0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0203796:	b92d                	j	ffffffffc02033d0 <swap_init+0x50>
     int ret, count = 0, total = 0, i;
ffffffffc0203798:	4481                	li	s1,0
ffffffffc020379a:	4901                	li	s2,0
     while ((le = list_next(le)) != &free_list) {
ffffffffc020379c:	4981                	li	s3,0
ffffffffc020379e:	b17d                	j	ffffffffc020344c <swap_init+0xcc>
        assert(PageProperty(p));
ffffffffc02037a0:	00004697          	auipc	a3,0x4
ffffffffc02037a4:	82068693          	addi	a3,a3,-2016 # ffffffffc0206fc0 <commands+0x878>
ffffffffc02037a8:	00003617          	auipc	a2,0x3
ffffffffc02037ac:	46060613          	addi	a2,a2,1120 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02037b0:	0bc00593          	li	a1,188
ffffffffc02037b4:	00004517          	auipc	a0,0x4
ffffffffc02037b8:	32c50513          	addi	a0,a0,812 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc02037bc:	cc9fc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02037c0:	00004617          	auipc	a2,0x4
ffffffffc02037c4:	c4060613          	addi	a2,a2,-960 # ffffffffc0207400 <default_pmm_manager+0xb0>
ffffffffc02037c8:	06200593          	li	a1,98
ffffffffc02037cc:	00004517          	auipc	a0,0x4
ffffffffc02037d0:	bfc50513          	addi	a0,a0,-1028 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc02037d4:	cb1fc0ef          	jal	ra,ffffffffc0200484 <__panic>
         assert(pte2page(*check_ptep[i]) == check_rp[i]);
ffffffffc02037d8:	00004697          	auipc	a3,0x4
ffffffffc02037dc:	4f868693          	addi	a3,a3,1272 # ffffffffc0207cd0 <default_pmm_manager+0x980>
ffffffffc02037e0:	00003617          	auipc	a2,0x3
ffffffffc02037e4:	42860613          	addi	a2,a2,1064 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02037e8:	0fc00593          	li	a1,252
ffffffffc02037ec:	00004517          	auipc	a0,0x4
ffffffffc02037f0:	2f450513          	addi	a0,a0,756 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc02037f4:	c91fc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pte2page called with invalid pte");
ffffffffc02037f8:	00004617          	auipc	a2,0x4
ffffffffc02037fc:	e5060613          	addi	a2,a2,-432 # ffffffffc0207648 <default_pmm_manager+0x2f8>
ffffffffc0203800:	07400593          	li	a1,116
ffffffffc0203804:	00004517          	auipc	a0,0x4
ffffffffc0203808:	bc450513          	addi	a0,a0,-1084 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc020380c:	c79fc0ef          	jal	ra,ffffffffc0200484 <__panic>
          assert(!PageProperty(check_rp[i]));
ffffffffc0203810:	00004697          	auipc	a3,0x4
ffffffffc0203814:	3f868693          	addi	a3,a3,1016 # ffffffffc0207c08 <default_pmm_manager+0x8b8>
ffffffffc0203818:	00003617          	auipc	a2,0x3
ffffffffc020381c:	3f060613          	addi	a2,a2,1008 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203820:	0dd00593          	li	a1,221
ffffffffc0203824:	00004517          	auipc	a0,0x4
ffffffffc0203828:	2bc50513          	addi	a0,a0,700 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc020382c:	c59fc0ef          	jal	ra,ffffffffc0200484 <__panic>
          assert(check_rp[i] != NULL );
ffffffffc0203830:	00004697          	auipc	a3,0x4
ffffffffc0203834:	3c068693          	addi	a3,a3,960 # ffffffffc0207bf0 <default_pmm_manager+0x8a0>
ffffffffc0203838:	00003617          	auipc	a2,0x3
ffffffffc020383c:	3d060613          	addi	a2,a2,976 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203840:	0dc00593          	li	a1,220
ffffffffc0203844:	00004517          	auipc	a0,0x4
ffffffffc0203848:	29c50513          	addi	a0,a0,668 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc020384c:	c39fc0ef          	jal	ra,ffffffffc0200484 <__panic>
         assert(check_ptep[i] != NULL);
ffffffffc0203850:	00004697          	auipc	a3,0x4
ffffffffc0203854:	46868693          	addi	a3,a3,1128 # ffffffffc0207cb8 <default_pmm_manager+0x968>
ffffffffc0203858:	00003617          	auipc	a2,0x3
ffffffffc020385c:	3b060613          	addi	a2,a2,944 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203860:	0fb00593          	li	a1,251
ffffffffc0203864:	00004517          	auipc	a0,0x4
ffffffffc0203868:	27c50513          	addi	a0,a0,636 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc020386c:	c19fc0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("bad max_swap_offset %08x.\n", max_swap_offset);
ffffffffc0203870:	00004617          	auipc	a2,0x4
ffffffffc0203874:	25060613          	addi	a2,a2,592 # ffffffffc0207ac0 <default_pmm_manager+0x770>
ffffffffc0203878:	02800593          	li	a1,40
ffffffffc020387c:	00004517          	auipc	a0,0x4
ffffffffc0203880:	26450513          	addi	a0,a0,612 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203884:	c01fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==2);
ffffffffc0203888:	00004697          	auipc	a3,0x4
ffffffffc020388c:	40068693          	addi	a3,a3,1024 # ffffffffc0207c88 <default_pmm_manager+0x938>
ffffffffc0203890:	00003617          	auipc	a2,0x3
ffffffffc0203894:	37860613          	addi	a2,a2,888 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203898:	09700593          	li	a1,151
ffffffffc020389c:	00004517          	auipc	a0,0x4
ffffffffc02038a0:	24450513          	addi	a0,a0,580 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc02038a4:	be1fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==2);
ffffffffc02038a8:	00004697          	auipc	a3,0x4
ffffffffc02038ac:	3e068693          	addi	a3,a3,992 # ffffffffc0207c88 <default_pmm_manager+0x938>
ffffffffc02038b0:	00003617          	auipc	a2,0x3
ffffffffc02038b4:	35860613          	addi	a2,a2,856 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02038b8:	09900593          	li	a1,153
ffffffffc02038bc:	00004517          	auipc	a0,0x4
ffffffffc02038c0:	22450513          	addi	a0,a0,548 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc02038c4:	bc1fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==3);
ffffffffc02038c8:	00004697          	auipc	a3,0x4
ffffffffc02038cc:	3d068693          	addi	a3,a3,976 # ffffffffc0207c98 <default_pmm_manager+0x948>
ffffffffc02038d0:	00003617          	auipc	a2,0x3
ffffffffc02038d4:	33860613          	addi	a2,a2,824 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02038d8:	09b00593          	li	a1,155
ffffffffc02038dc:	00004517          	auipc	a0,0x4
ffffffffc02038e0:	20450513          	addi	a0,a0,516 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc02038e4:	ba1fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==3);
ffffffffc02038e8:	00004697          	auipc	a3,0x4
ffffffffc02038ec:	3b068693          	addi	a3,a3,944 # ffffffffc0207c98 <default_pmm_manager+0x948>
ffffffffc02038f0:	00003617          	auipc	a2,0x3
ffffffffc02038f4:	31860613          	addi	a2,a2,792 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02038f8:	09d00593          	li	a1,157
ffffffffc02038fc:	00004517          	auipc	a0,0x4
ffffffffc0203900:	1e450513          	addi	a0,a0,484 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203904:	b81fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==1);
ffffffffc0203908:	00004697          	auipc	a3,0x4
ffffffffc020390c:	37068693          	addi	a3,a3,880 # ffffffffc0207c78 <default_pmm_manager+0x928>
ffffffffc0203910:	00003617          	auipc	a2,0x3
ffffffffc0203914:	2f860613          	addi	a2,a2,760 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203918:	09300593          	li	a1,147
ffffffffc020391c:	00004517          	auipc	a0,0x4
ffffffffc0203920:	1c450513          	addi	a0,a0,452 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203924:	b61fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==1);
ffffffffc0203928:	00004697          	auipc	a3,0x4
ffffffffc020392c:	35068693          	addi	a3,a3,848 # ffffffffc0207c78 <default_pmm_manager+0x928>
ffffffffc0203930:	00003617          	auipc	a2,0x3
ffffffffc0203934:	2d860613          	addi	a2,a2,728 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203938:	09500593          	li	a1,149
ffffffffc020393c:	00004517          	auipc	a0,0x4
ffffffffc0203940:	1a450513          	addi	a0,a0,420 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203944:	b41fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==4);
ffffffffc0203948:	00004697          	auipc	a3,0x4
ffffffffc020394c:	36068693          	addi	a3,a3,864 # ffffffffc0207ca8 <default_pmm_manager+0x958>
ffffffffc0203950:	00003617          	auipc	a2,0x3
ffffffffc0203954:	2b860613          	addi	a2,a2,696 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203958:	09f00593          	li	a1,159
ffffffffc020395c:	00004517          	auipc	a0,0x4
ffffffffc0203960:	18450513          	addi	a0,a0,388 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203964:	b21fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgfault_num==4);
ffffffffc0203968:	00004697          	auipc	a3,0x4
ffffffffc020396c:	34068693          	addi	a3,a3,832 # ffffffffc0207ca8 <default_pmm_manager+0x958>
ffffffffc0203970:	00003617          	auipc	a2,0x3
ffffffffc0203974:	29860613          	addi	a2,a2,664 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203978:	0a100593          	li	a1,161
ffffffffc020397c:	00004517          	auipc	a0,0x4
ffffffffc0203980:	16450513          	addi	a0,a0,356 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203984:	b01fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(pgdir[0] == 0);
ffffffffc0203988:	00004697          	auipc	a3,0x4
ffffffffc020398c:	1d068693          	addi	a3,a3,464 # ffffffffc0207b58 <default_pmm_manager+0x808>
ffffffffc0203990:	00003617          	auipc	a2,0x3
ffffffffc0203994:	27860613          	addi	a2,a2,632 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203998:	0cc00593          	li	a1,204
ffffffffc020399c:	00004517          	auipc	a0,0x4
ffffffffc02039a0:	14450513          	addi	a0,a0,324 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc02039a4:	ae1fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(vma != NULL);
ffffffffc02039a8:	00004697          	auipc	a3,0x4
ffffffffc02039ac:	1c068693          	addi	a3,a3,448 # ffffffffc0207b68 <default_pmm_manager+0x818>
ffffffffc02039b0:	00003617          	auipc	a2,0x3
ffffffffc02039b4:	25860613          	addi	a2,a2,600 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02039b8:	0cf00593          	li	a1,207
ffffffffc02039bc:	00004517          	auipc	a0,0x4
ffffffffc02039c0:	12450513          	addi	a0,a0,292 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc02039c4:	ac1fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(temp_ptep!= NULL);
ffffffffc02039c8:	00004697          	auipc	a3,0x4
ffffffffc02039cc:	1e868693          	addi	a3,a3,488 # ffffffffc0207bb0 <default_pmm_manager+0x860>
ffffffffc02039d0:	00003617          	auipc	a2,0x3
ffffffffc02039d4:	23860613          	addi	a2,a2,568 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02039d8:	0d700593          	li	a1,215
ffffffffc02039dc:	00004517          	auipc	a0,0x4
ffffffffc02039e0:	10450513          	addi	a0,a0,260 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc02039e4:	aa1fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert( nr_free == 0);         
ffffffffc02039e8:	00003697          	auipc	a3,0x3
ffffffffc02039ec:	7a868693          	addi	a3,a3,1960 # ffffffffc0207190 <commands+0xa48>
ffffffffc02039f0:	00003617          	auipc	a2,0x3
ffffffffc02039f4:	21860613          	addi	a2,a2,536 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02039f8:	0f300593          	li	a1,243
ffffffffc02039fc:	00004517          	auipc	a0,0x4
ffffffffc0203a00:	0e450513          	addi	a0,a0,228 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203a04:	a81fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0203a08:	00004617          	auipc	a2,0x4
ffffffffc0203a0c:	99860613          	addi	a2,a2,-1640 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0203a10:	06900593          	li	a1,105
ffffffffc0203a14:	00004517          	auipc	a0,0x4
ffffffffc0203a18:	9b450513          	addi	a0,a0,-1612 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0203a1c:	a69fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(count==0);
ffffffffc0203a20:	00004697          	auipc	a3,0x4
ffffffffc0203a24:	30868693          	addi	a3,a3,776 # ffffffffc0207d28 <default_pmm_manager+0x9d8>
ffffffffc0203a28:	00003617          	auipc	a2,0x3
ffffffffc0203a2c:	1e060613          	addi	a2,a2,480 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203a30:	11d00593          	li	a1,285
ffffffffc0203a34:	00004517          	auipc	a0,0x4
ffffffffc0203a38:	0ac50513          	addi	a0,a0,172 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203a3c:	a49fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(total==0);
ffffffffc0203a40:	00004697          	auipc	a3,0x4
ffffffffc0203a44:	2f868693          	addi	a3,a3,760 # ffffffffc0207d38 <default_pmm_manager+0x9e8>
ffffffffc0203a48:	00003617          	auipc	a2,0x3
ffffffffc0203a4c:	1c060613          	addi	a2,a2,448 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203a50:	11e00593          	li	a1,286
ffffffffc0203a54:	00004517          	auipc	a0,0x4
ffffffffc0203a58:	08c50513          	addi	a0,a0,140 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203a5c:	a29fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(nr_free==CHECK_VALID_PHY_PAGE_NUM);
ffffffffc0203a60:	00004697          	auipc	a3,0x4
ffffffffc0203a64:	1c868693          	addi	a3,a3,456 # ffffffffc0207c28 <default_pmm_manager+0x8d8>
ffffffffc0203a68:	00003617          	auipc	a2,0x3
ffffffffc0203a6c:	1a060613          	addi	a2,a2,416 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203a70:	0ea00593          	li	a1,234
ffffffffc0203a74:	00004517          	auipc	a0,0x4
ffffffffc0203a78:	06c50513          	addi	a0,a0,108 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203a7c:	a09fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(mm != NULL);
ffffffffc0203a80:	00004697          	auipc	a3,0x4
ffffffffc0203a84:	0b068693          	addi	a3,a3,176 # ffffffffc0207b30 <default_pmm_manager+0x7e0>
ffffffffc0203a88:	00003617          	auipc	a2,0x3
ffffffffc0203a8c:	18060613          	addi	a2,a2,384 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203a90:	0c400593          	li	a1,196
ffffffffc0203a94:	00004517          	auipc	a0,0x4
ffffffffc0203a98:	04c50513          	addi	a0,a0,76 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203a9c:	9e9fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(check_mm_struct == NULL);
ffffffffc0203aa0:	00004697          	auipc	a3,0x4
ffffffffc0203aa4:	0a068693          	addi	a3,a3,160 # ffffffffc0207b40 <default_pmm_manager+0x7f0>
ffffffffc0203aa8:	00003617          	auipc	a2,0x3
ffffffffc0203aac:	16060613          	addi	a2,a2,352 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203ab0:	0c700593          	li	a1,199
ffffffffc0203ab4:	00004517          	auipc	a0,0x4
ffffffffc0203ab8:	02c50513          	addi	a0,a0,44 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203abc:	9c9fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(ret==0);
ffffffffc0203ac0:	00004697          	auipc	a3,0x4
ffffffffc0203ac4:	26068693          	addi	a3,a3,608 # ffffffffc0207d20 <default_pmm_manager+0x9d0>
ffffffffc0203ac8:	00003617          	auipc	a2,0x3
ffffffffc0203acc:	14060613          	addi	a2,a2,320 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203ad0:	10200593          	li	a1,258
ffffffffc0203ad4:	00004517          	auipc	a0,0x4
ffffffffc0203ad8:	00c50513          	addi	a0,a0,12 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203adc:	9a9fc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(total == nr_free_pages());
ffffffffc0203ae0:	00003697          	auipc	a3,0x3
ffffffffc0203ae4:	50868693          	addi	a3,a3,1288 # ffffffffc0206fe8 <commands+0x8a0>
ffffffffc0203ae8:	00003617          	auipc	a2,0x3
ffffffffc0203aec:	12060613          	addi	a2,a2,288 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203af0:	0bf00593          	li	a1,191
ffffffffc0203af4:	00004517          	auipc	a0,0x4
ffffffffc0203af8:	fec50513          	addi	a0,a0,-20 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203afc:	989fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203b00 <swap_init_mm>:
     return sm->init_mm(mm);
ffffffffc0203b00:	000a9797          	auipc	a5,0xa9
ffffffffc0203b04:	9b078793          	addi	a5,a5,-1616 # ffffffffc02ac4b0 <sm>
ffffffffc0203b08:	639c                	ld	a5,0(a5)
ffffffffc0203b0a:	0107b303          	ld	t1,16(a5)
ffffffffc0203b0e:	8302                	jr	t1

ffffffffc0203b10 <swap_map_swappable>:
     return sm->map_swappable(mm, addr, page, swap_in);
ffffffffc0203b10:	000a9797          	auipc	a5,0xa9
ffffffffc0203b14:	9a078793          	addi	a5,a5,-1632 # ffffffffc02ac4b0 <sm>
ffffffffc0203b18:	639c                	ld	a5,0(a5)
ffffffffc0203b1a:	0207b303          	ld	t1,32(a5)
ffffffffc0203b1e:	8302                	jr	t1

ffffffffc0203b20 <swap_out>:
{
ffffffffc0203b20:	711d                	addi	sp,sp,-96
ffffffffc0203b22:	ec86                	sd	ra,88(sp)
ffffffffc0203b24:	e8a2                	sd	s0,80(sp)
ffffffffc0203b26:	e4a6                	sd	s1,72(sp)
ffffffffc0203b28:	e0ca                	sd	s2,64(sp)
ffffffffc0203b2a:	fc4e                	sd	s3,56(sp)
ffffffffc0203b2c:	f852                	sd	s4,48(sp)
ffffffffc0203b2e:	f456                	sd	s5,40(sp)
ffffffffc0203b30:	f05a                	sd	s6,32(sp)
ffffffffc0203b32:	ec5e                	sd	s7,24(sp)
ffffffffc0203b34:	e862                	sd	s8,16(sp)
     for (i = 0; i != n; ++ i)
ffffffffc0203b36:	cde9                	beqz	a1,ffffffffc0203c10 <swap_out+0xf0>
ffffffffc0203b38:	8ab2                	mv	s5,a2
ffffffffc0203b3a:	892a                	mv	s2,a0
ffffffffc0203b3c:	8a2e                	mv	s4,a1
ffffffffc0203b3e:	4401                	li	s0,0
ffffffffc0203b40:	000a9997          	auipc	s3,0xa9
ffffffffc0203b44:	97098993          	addi	s3,s3,-1680 # ffffffffc02ac4b0 <sm>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b48:	00004b17          	auipc	s6,0x4
ffffffffc0203b4c:	280b0b13          	addi	s6,s6,640 # ffffffffc0207dc8 <default_pmm_manager+0xa78>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203b50:	00004b97          	auipc	s7,0x4
ffffffffc0203b54:	260b8b93          	addi	s7,s7,608 # ffffffffc0207db0 <default_pmm_manager+0xa60>
ffffffffc0203b58:	a825                	j	ffffffffc0203b90 <swap_out+0x70>
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b5a:	67a2                	ld	a5,8(sp)
ffffffffc0203b5c:	8626                	mv	a2,s1
ffffffffc0203b5e:	85a2                	mv	a1,s0
ffffffffc0203b60:	7f94                	ld	a3,56(a5)
ffffffffc0203b62:	855a                	mv	a0,s6
     for (i = 0; i != n; ++ i)
ffffffffc0203b64:	2405                	addiw	s0,s0,1
                    cprintf("swap_out: i %d, store page in vaddr 0x%x to disk swap entry %d\n", i, v, page->pra_vaddr/PGSIZE+1);
ffffffffc0203b66:	82b1                	srli	a3,a3,0xc
ffffffffc0203b68:	0685                	addi	a3,a3,1
ffffffffc0203b6a:	e24fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203b6e:	6522                	ld	a0,8(sp)
                    free_page(page);
ffffffffc0203b70:	4585                	li	a1,1
                    *ptep = (page->pra_vaddr/PGSIZE+1)<<8;
ffffffffc0203b72:	7d1c                	ld	a5,56(a0)
ffffffffc0203b74:	83b1                	srli	a5,a5,0xc
ffffffffc0203b76:	0785                	addi	a5,a5,1
ffffffffc0203b78:	07a2                	slli	a5,a5,0x8
ffffffffc0203b7a:	00fc3023          	sd	a5,0(s8)
                    free_page(page);
ffffffffc0203b7e:	b5cfe0ef          	jal	ra,ffffffffc0201eda <free_pages>
          tlb_invalidate(mm->pgdir, v);
ffffffffc0203b82:	01893503          	ld	a0,24(s2)
ffffffffc0203b86:	85a6                	mv	a1,s1
ffffffffc0203b88:	f5eff0ef          	jal	ra,ffffffffc02032e6 <tlb_invalidate>
     for (i = 0; i != n; ++ i)
ffffffffc0203b8c:	048a0d63          	beq	s4,s0,ffffffffc0203be6 <swap_out+0xc6>
          int r = sm->swap_out_victim(mm, &page, in_tick);
ffffffffc0203b90:	0009b783          	ld	a5,0(s3)
ffffffffc0203b94:	8656                	mv	a2,s5
ffffffffc0203b96:	002c                	addi	a1,sp,8
ffffffffc0203b98:	7b9c                	ld	a5,48(a5)
ffffffffc0203b9a:	854a                	mv	a0,s2
ffffffffc0203b9c:	9782                	jalr	a5
          if (r != 0) {
ffffffffc0203b9e:	e12d                	bnez	a0,ffffffffc0203c00 <swap_out+0xe0>
          v=page->pra_vaddr; 
ffffffffc0203ba0:	67a2                	ld	a5,8(sp)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203ba2:	01893503          	ld	a0,24(s2)
ffffffffc0203ba6:	4601                	li	a2,0
          v=page->pra_vaddr; 
ffffffffc0203ba8:	7f84                	ld	s1,56(a5)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203baa:	85a6                	mv	a1,s1
ffffffffc0203bac:	bb4fe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203bb0:	611c                	ld	a5,0(a0)
          pte_t *ptep = get_pte(mm->pgdir, v, 0);
ffffffffc0203bb2:	8c2a                	mv	s8,a0
          assert((*ptep & PTE_V) != 0);
ffffffffc0203bb4:	8b85                	andi	a5,a5,1
ffffffffc0203bb6:	cfb9                	beqz	a5,ffffffffc0203c14 <swap_out+0xf4>
          if (swapfs_write( (page->pra_vaddr/PGSIZE+1)<<8, page) != 0) {
ffffffffc0203bb8:	65a2                	ld	a1,8(sp)
ffffffffc0203bba:	7d9c                	ld	a5,56(a1)
ffffffffc0203bbc:	83b1                	srli	a5,a5,0xc
ffffffffc0203bbe:	00178513          	addi	a0,a5,1
ffffffffc0203bc2:	0522                	slli	a0,a0,0x8
ffffffffc0203bc4:	022010ef          	jal	ra,ffffffffc0204be6 <swapfs_write>
ffffffffc0203bc8:	d949                	beqz	a0,ffffffffc0203b5a <swap_out+0x3a>
                    cprintf("SWAP: failed to save\n");
ffffffffc0203bca:	855e                	mv	a0,s7
ffffffffc0203bcc:	dc2fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203bd0:	0009b783          	ld	a5,0(s3)
ffffffffc0203bd4:	6622                	ld	a2,8(sp)
ffffffffc0203bd6:	4681                	li	a3,0
ffffffffc0203bd8:	739c                	ld	a5,32(a5)
ffffffffc0203bda:	85a6                	mv	a1,s1
ffffffffc0203bdc:	854a                	mv	a0,s2
     for (i = 0; i != n; ++ i)
ffffffffc0203bde:	2405                	addiw	s0,s0,1
                    sm->map_swappable(mm, v, page, 0);
ffffffffc0203be0:	9782                	jalr	a5
     for (i = 0; i != n; ++ i)
ffffffffc0203be2:	fa8a17e3          	bne	s4,s0,ffffffffc0203b90 <swap_out+0x70>
}
ffffffffc0203be6:	8522                	mv	a0,s0
ffffffffc0203be8:	60e6                	ld	ra,88(sp)
ffffffffc0203bea:	6446                	ld	s0,80(sp)
ffffffffc0203bec:	64a6                	ld	s1,72(sp)
ffffffffc0203bee:	6906                	ld	s2,64(sp)
ffffffffc0203bf0:	79e2                	ld	s3,56(sp)
ffffffffc0203bf2:	7a42                	ld	s4,48(sp)
ffffffffc0203bf4:	7aa2                	ld	s5,40(sp)
ffffffffc0203bf6:	7b02                	ld	s6,32(sp)
ffffffffc0203bf8:	6be2                	ld	s7,24(sp)
ffffffffc0203bfa:	6c42                	ld	s8,16(sp)
ffffffffc0203bfc:	6125                	addi	sp,sp,96
ffffffffc0203bfe:	8082                	ret
                    cprintf("i %d, swap_out: call swap_out_victim failed\n",i);
ffffffffc0203c00:	85a2                	mv	a1,s0
ffffffffc0203c02:	00004517          	auipc	a0,0x4
ffffffffc0203c06:	16650513          	addi	a0,a0,358 # ffffffffc0207d68 <default_pmm_manager+0xa18>
ffffffffc0203c0a:	d84fc0ef          	jal	ra,ffffffffc020018e <cprintf>
                  break;
ffffffffc0203c0e:	bfe1                	j	ffffffffc0203be6 <swap_out+0xc6>
     for (i = 0; i != n; ++ i)
ffffffffc0203c10:	4401                	li	s0,0
ffffffffc0203c12:	bfd1                	j	ffffffffc0203be6 <swap_out+0xc6>
          assert((*ptep & PTE_V) != 0);
ffffffffc0203c14:	00004697          	auipc	a3,0x4
ffffffffc0203c18:	18468693          	addi	a3,a3,388 # ffffffffc0207d98 <default_pmm_manager+0xa48>
ffffffffc0203c1c:	00003617          	auipc	a2,0x3
ffffffffc0203c20:	fec60613          	addi	a2,a2,-20 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203c24:	06800593          	li	a1,104
ffffffffc0203c28:	00004517          	auipc	a0,0x4
ffffffffc0203c2c:	eb850513          	addi	a0,a0,-328 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203c30:	855fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203c34 <swap_in>:
{
ffffffffc0203c34:	7179                	addi	sp,sp,-48
ffffffffc0203c36:	e84a                	sd	s2,16(sp)
ffffffffc0203c38:	892a                	mv	s2,a0
     struct Page *result = alloc_page();
ffffffffc0203c3a:	4505                	li	a0,1
{
ffffffffc0203c3c:	ec26                	sd	s1,24(sp)
ffffffffc0203c3e:	e44e                	sd	s3,8(sp)
ffffffffc0203c40:	f406                	sd	ra,40(sp)
ffffffffc0203c42:	f022                	sd	s0,32(sp)
ffffffffc0203c44:	84ae                	mv	s1,a1
ffffffffc0203c46:	89b2                	mv	s3,a2
     struct Page *result = alloc_page();
ffffffffc0203c48:	a0afe0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
     assert(result!=NULL);
ffffffffc0203c4c:	c129                	beqz	a0,ffffffffc0203c8e <swap_in+0x5a>
     pte_t *ptep = get_pte(mm->pgdir, addr, 0);
ffffffffc0203c4e:	842a                	mv	s0,a0
ffffffffc0203c50:	01893503          	ld	a0,24(s2)
ffffffffc0203c54:	4601                	li	a2,0
ffffffffc0203c56:	85a6                	mv	a1,s1
ffffffffc0203c58:	b08fe0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc0203c5c:	892a                	mv	s2,a0
     if ((r = swapfs_read((*ptep), result)) != 0)
ffffffffc0203c5e:	6108                	ld	a0,0(a0)
ffffffffc0203c60:	85a2                	mv	a1,s0
ffffffffc0203c62:	6ed000ef          	jal	ra,ffffffffc0204b4e <swapfs_read>
     cprintf("swap_in: load disk swap entry %d with swap_page in vadr 0x%x\n", (*ptep)>>8, addr);
ffffffffc0203c66:	00093583          	ld	a1,0(s2)
ffffffffc0203c6a:	8626                	mv	a2,s1
ffffffffc0203c6c:	00004517          	auipc	a0,0x4
ffffffffc0203c70:	e1450513          	addi	a0,a0,-492 # ffffffffc0207a80 <default_pmm_manager+0x730>
ffffffffc0203c74:	81a1                	srli	a1,a1,0x8
ffffffffc0203c76:	d18fc0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0203c7a:	70a2                	ld	ra,40(sp)
     *ptr_result=result;
ffffffffc0203c7c:	0089b023          	sd	s0,0(s3)
}
ffffffffc0203c80:	7402                	ld	s0,32(sp)
ffffffffc0203c82:	64e2                	ld	s1,24(sp)
ffffffffc0203c84:	6942                	ld	s2,16(sp)
ffffffffc0203c86:	69a2                	ld	s3,8(sp)
ffffffffc0203c88:	4501                	li	a0,0
ffffffffc0203c8a:	6145                	addi	sp,sp,48
ffffffffc0203c8c:	8082                	ret
     assert(result!=NULL);
ffffffffc0203c8e:	00004697          	auipc	a3,0x4
ffffffffc0203c92:	de268693          	addi	a3,a3,-542 # ffffffffc0207a70 <default_pmm_manager+0x720>
ffffffffc0203c96:	00003617          	auipc	a2,0x3
ffffffffc0203c9a:	f7260613          	addi	a2,a2,-142 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203c9e:	07e00593          	li	a1,126
ffffffffc0203ca2:	00004517          	auipc	a0,0x4
ffffffffc0203ca6:	e3e50513          	addi	a0,a0,-450 # ffffffffc0207ae0 <default_pmm_manager+0x790>
ffffffffc0203caa:	fdafc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203cae <_fifo_init_mm>:
    elm->prev = elm->next = elm;
ffffffffc0203cae:	000a9797          	auipc	a5,0xa9
ffffffffc0203cb2:	93a78793          	addi	a5,a5,-1734 # ffffffffc02ac5e8 <pra_list_head>
 */
static int
_fifo_init_mm(struct mm_struct *mm)
{     
     list_init(&pra_list_head);
     mm->sm_priv = &pra_list_head;
ffffffffc0203cb6:	f51c                	sd	a5,40(a0)
ffffffffc0203cb8:	e79c                	sd	a5,8(a5)
ffffffffc0203cba:	e39c                	sd	a5,0(a5)
     //cprintf(" mm->sm_priv %x in fifo_init_mm\n",mm->sm_priv);
     return 0;
}
ffffffffc0203cbc:	4501                	li	a0,0
ffffffffc0203cbe:	8082                	ret

ffffffffc0203cc0 <_fifo_init>:

static int
_fifo_init(void)
{
    return 0;
}
ffffffffc0203cc0:	4501                	li	a0,0
ffffffffc0203cc2:	8082                	ret

ffffffffc0203cc4 <_fifo_set_unswappable>:

static int
_fifo_set_unswappable(struct mm_struct *mm, uintptr_t addr)
{
    return 0;
}
ffffffffc0203cc4:	4501                	li	a0,0
ffffffffc0203cc6:	8082                	ret

ffffffffc0203cc8 <_fifo_tick_event>:

static int
_fifo_tick_event(struct mm_struct *mm)
{ return 0; }
ffffffffc0203cc8:	4501                	li	a0,0
ffffffffc0203cca:	8082                	ret

ffffffffc0203ccc <_fifo_check_swap>:
_fifo_check_swap(void) {
ffffffffc0203ccc:	711d                	addi	sp,sp,-96
ffffffffc0203cce:	fc4e                	sd	s3,56(sp)
ffffffffc0203cd0:	f852                	sd	s4,48(sp)
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203cd2:	00004517          	auipc	a0,0x4
ffffffffc0203cd6:	13650513          	addi	a0,a0,310 # ffffffffc0207e08 <default_pmm_manager+0xab8>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203cda:	698d                	lui	s3,0x3
ffffffffc0203cdc:	4a31                	li	s4,12
_fifo_check_swap(void) {
ffffffffc0203cde:	e8a2                	sd	s0,80(sp)
ffffffffc0203ce0:	e4a6                	sd	s1,72(sp)
ffffffffc0203ce2:	ec86                	sd	ra,88(sp)
ffffffffc0203ce4:	e0ca                	sd	s2,64(sp)
ffffffffc0203ce6:	f456                	sd	s5,40(sp)
ffffffffc0203ce8:	f05a                	sd	s6,32(sp)
ffffffffc0203cea:	ec5e                	sd	s7,24(sp)
ffffffffc0203cec:	e862                	sd	s8,16(sp)
ffffffffc0203cee:	e466                	sd	s9,8(sp)
    assert(pgfault_num==4);
ffffffffc0203cf0:	000a8417          	auipc	s0,0xa8
ffffffffc0203cf4:	7cc40413          	addi	s0,s0,1996 # ffffffffc02ac4bc <pgfault_num>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203cf8:	c96fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203cfc:	01498023          	sb	s4,0(s3) # 3000 <_binary_obj___user_faultread_out_size-0x6580>
    assert(pgfault_num==4);
ffffffffc0203d00:	4004                	lw	s1,0(s0)
ffffffffc0203d02:	4791                	li	a5,4
ffffffffc0203d04:	2481                	sext.w	s1,s1
ffffffffc0203d06:	14f49963          	bne	s1,a5,ffffffffc0203e58 <_fifo_check_swap+0x18c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d0a:	00004517          	auipc	a0,0x4
ffffffffc0203d0e:	13e50513          	addi	a0,a0,318 # ffffffffc0207e48 <default_pmm_manager+0xaf8>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d12:	6a85                	lui	s5,0x1
ffffffffc0203d14:	4b29                	li	s6,10
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d16:	c78fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203d1a:	016a8023          	sb	s6,0(s5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
    assert(pgfault_num==4);
ffffffffc0203d1e:	00042903          	lw	s2,0(s0)
ffffffffc0203d22:	2901                	sext.w	s2,s2
ffffffffc0203d24:	2a991a63          	bne	s2,s1,ffffffffc0203fd8 <_fifo_check_swap+0x30c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d28:	00004517          	auipc	a0,0x4
ffffffffc0203d2c:	14850513          	addi	a0,a0,328 # ffffffffc0207e70 <default_pmm_manager+0xb20>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203d30:	6b91                	lui	s7,0x4
ffffffffc0203d32:	4c35                	li	s8,13
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203d34:	c5afc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203d38:	018b8023          	sb	s8,0(s7) # 4000 <_binary_obj___user_faultread_out_size-0x5580>
    assert(pgfault_num==4);
ffffffffc0203d3c:	4004                	lw	s1,0(s0)
ffffffffc0203d3e:	2481                	sext.w	s1,s1
ffffffffc0203d40:	27249c63          	bne	s1,s2,ffffffffc0203fb8 <_fifo_check_swap+0x2ec>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d44:	00004517          	auipc	a0,0x4
ffffffffc0203d48:	15450513          	addi	a0,a0,340 # ffffffffc0207e98 <default_pmm_manager+0xb48>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d4c:	6909                	lui	s2,0x2
ffffffffc0203d4e:	4cad                	li	s9,11
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d50:	c3efc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d54:	01990023          	sb	s9,0(s2) # 2000 <_binary_obj___user_faultread_out_size-0x7580>
    assert(pgfault_num==4);
ffffffffc0203d58:	401c                	lw	a5,0(s0)
ffffffffc0203d5a:	2781                	sext.w	a5,a5
ffffffffc0203d5c:	22979e63          	bne	a5,s1,ffffffffc0203f98 <_fifo_check_swap+0x2cc>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203d60:	00004517          	auipc	a0,0x4
ffffffffc0203d64:	16050513          	addi	a0,a0,352 # ffffffffc0207ec0 <default_pmm_manager+0xb70>
ffffffffc0203d68:	c26fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203d6c:	6795                	lui	a5,0x5
ffffffffc0203d6e:	4739                	li	a4,14
ffffffffc0203d70:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4580>
    assert(pgfault_num==5);
ffffffffc0203d74:	4004                	lw	s1,0(s0)
ffffffffc0203d76:	4795                	li	a5,5
ffffffffc0203d78:	2481                	sext.w	s1,s1
ffffffffc0203d7a:	1ef49f63          	bne	s1,a5,ffffffffc0203f78 <_fifo_check_swap+0x2ac>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203d7e:	00004517          	auipc	a0,0x4
ffffffffc0203d82:	11a50513          	addi	a0,a0,282 # ffffffffc0207e98 <default_pmm_manager+0xb48>
ffffffffc0203d86:	c08fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203d8a:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==5);
ffffffffc0203d8e:	401c                	lw	a5,0(s0)
ffffffffc0203d90:	2781                	sext.w	a5,a5
ffffffffc0203d92:	1c979363          	bne	a5,s1,ffffffffc0203f58 <_fifo_check_swap+0x28c>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203d96:	00004517          	auipc	a0,0x4
ffffffffc0203d9a:	0b250513          	addi	a0,a0,178 # ffffffffc0207e48 <default_pmm_manager+0xaf8>
ffffffffc0203d9e:	bf0fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x1000 = 0x0a;
ffffffffc0203da2:	016a8023          	sb	s6,0(s5)
    assert(pgfault_num==6);
ffffffffc0203da6:	401c                	lw	a5,0(s0)
ffffffffc0203da8:	4719                	li	a4,6
ffffffffc0203daa:	2781                	sext.w	a5,a5
ffffffffc0203dac:	18e79663          	bne	a5,a4,ffffffffc0203f38 <_fifo_check_swap+0x26c>
    cprintf("write Virt Page b in fifo_check_swap\n");
ffffffffc0203db0:	00004517          	auipc	a0,0x4
ffffffffc0203db4:	0e850513          	addi	a0,a0,232 # ffffffffc0207e98 <default_pmm_manager+0xb48>
ffffffffc0203db8:	bd6fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x2000 = 0x0b;
ffffffffc0203dbc:	01990023          	sb	s9,0(s2)
    assert(pgfault_num==7);
ffffffffc0203dc0:	401c                	lw	a5,0(s0)
ffffffffc0203dc2:	471d                	li	a4,7
ffffffffc0203dc4:	2781                	sext.w	a5,a5
ffffffffc0203dc6:	14e79963          	bne	a5,a4,ffffffffc0203f18 <_fifo_check_swap+0x24c>
    cprintf("write Virt Page c in fifo_check_swap\n");
ffffffffc0203dca:	00004517          	auipc	a0,0x4
ffffffffc0203dce:	03e50513          	addi	a0,a0,62 # ffffffffc0207e08 <default_pmm_manager+0xab8>
ffffffffc0203dd2:	bbcfc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x3000 = 0x0c;
ffffffffc0203dd6:	01498023          	sb	s4,0(s3)
    assert(pgfault_num==8);
ffffffffc0203dda:	401c                	lw	a5,0(s0)
ffffffffc0203ddc:	4721                	li	a4,8
ffffffffc0203dde:	2781                	sext.w	a5,a5
ffffffffc0203de0:	10e79c63          	bne	a5,a4,ffffffffc0203ef8 <_fifo_check_swap+0x22c>
    cprintf("write Virt Page d in fifo_check_swap\n");
ffffffffc0203de4:	00004517          	auipc	a0,0x4
ffffffffc0203de8:	08c50513          	addi	a0,a0,140 # ffffffffc0207e70 <default_pmm_manager+0xb20>
ffffffffc0203dec:	ba2fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x4000 = 0x0d;
ffffffffc0203df0:	018b8023          	sb	s8,0(s7)
    assert(pgfault_num==9);
ffffffffc0203df4:	401c                	lw	a5,0(s0)
ffffffffc0203df6:	4725                	li	a4,9
ffffffffc0203df8:	2781                	sext.w	a5,a5
ffffffffc0203dfa:	0ce79f63          	bne	a5,a4,ffffffffc0203ed8 <_fifo_check_swap+0x20c>
    cprintf("write Virt Page e in fifo_check_swap\n");
ffffffffc0203dfe:	00004517          	auipc	a0,0x4
ffffffffc0203e02:	0c250513          	addi	a0,a0,194 # ffffffffc0207ec0 <default_pmm_manager+0xb70>
ffffffffc0203e06:	b88fc0ef          	jal	ra,ffffffffc020018e <cprintf>
    *(unsigned char *)0x5000 = 0x0e;
ffffffffc0203e0a:	6795                	lui	a5,0x5
ffffffffc0203e0c:	4739                	li	a4,14
ffffffffc0203e0e:	00e78023          	sb	a4,0(a5) # 5000 <_binary_obj___user_faultread_out_size-0x4580>
    assert(pgfault_num==10);
ffffffffc0203e12:	4004                	lw	s1,0(s0)
ffffffffc0203e14:	47a9                	li	a5,10
ffffffffc0203e16:	2481                	sext.w	s1,s1
ffffffffc0203e18:	0af49063          	bne	s1,a5,ffffffffc0203eb8 <_fifo_check_swap+0x1ec>
    cprintf("write Virt Page a in fifo_check_swap\n");
ffffffffc0203e1c:	00004517          	auipc	a0,0x4
ffffffffc0203e20:	02c50513          	addi	a0,a0,44 # ffffffffc0207e48 <default_pmm_manager+0xaf8>
ffffffffc0203e24:	b6afc0ef          	jal	ra,ffffffffc020018e <cprintf>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203e28:	6785                	lui	a5,0x1
ffffffffc0203e2a:	0007c783          	lbu	a5,0(a5) # 1000 <_binary_obj___user_faultread_out_size-0x8580>
ffffffffc0203e2e:	06979563          	bne	a5,s1,ffffffffc0203e98 <_fifo_check_swap+0x1cc>
    assert(pgfault_num==11);
ffffffffc0203e32:	401c                	lw	a5,0(s0)
ffffffffc0203e34:	472d                	li	a4,11
ffffffffc0203e36:	2781                	sext.w	a5,a5
ffffffffc0203e38:	04e79063          	bne	a5,a4,ffffffffc0203e78 <_fifo_check_swap+0x1ac>
}
ffffffffc0203e3c:	60e6                	ld	ra,88(sp)
ffffffffc0203e3e:	6446                	ld	s0,80(sp)
ffffffffc0203e40:	64a6                	ld	s1,72(sp)
ffffffffc0203e42:	6906                	ld	s2,64(sp)
ffffffffc0203e44:	79e2                	ld	s3,56(sp)
ffffffffc0203e46:	7a42                	ld	s4,48(sp)
ffffffffc0203e48:	7aa2                	ld	s5,40(sp)
ffffffffc0203e4a:	7b02                	ld	s6,32(sp)
ffffffffc0203e4c:	6be2                	ld	s7,24(sp)
ffffffffc0203e4e:	6c42                	ld	s8,16(sp)
ffffffffc0203e50:	6ca2                	ld	s9,8(sp)
ffffffffc0203e52:	4501                	li	a0,0
ffffffffc0203e54:	6125                	addi	sp,sp,96
ffffffffc0203e56:	8082                	ret
    assert(pgfault_num==4);
ffffffffc0203e58:	00004697          	auipc	a3,0x4
ffffffffc0203e5c:	e5068693          	addi	a3,a3,-432 # ffffffffc0207ca8 <default_pmm_manager+0x958>
ffffffffc0203e60:	00003617          	auipc	a2,0x3
ffffffffc0203e64:	da860613          	addi	a2,a2,-600 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203e68:	05100593          	li	a1,81
ffffffffc0203e6c:	00004517          	auipc	a0,0x4
ffffffffc0203e70:	fc450513          	addi	a0,a0,-60 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203e74:	e10fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==11);
ffffffffc0203e78:	00004697          	auipc	a3,0x4
ffffffffc0203e7c:	0f868693          	addi	a3,a3,248 # ffffffffc0207f70 <default_pmm_manager+0xc20>
ffffffffc0203e80:	00003617          	auipc	a2,0x3
ffffffffc0203e84:	d8860613          	addi	a2,a2,-632 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203e88:	07300593          	li	a1,115
ffffffffc0203e8c:	00004517          	auipc	a0,0x4
ffffffffc0203e90:	fa450513          	addi	a0,a0,-92 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203e94:	df0fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(*(unsigned char *)0x1000 == 0x0a);
ffffffffc0203e98:	00004697          	auipc	a3,0x4
ffffffffc0203e9c:	0b068693          	addi	a3,a3,176 # ffffffffc0207f48 <default_pmm_manager+0xbf8>
ffffffffc0203ea0:	00003617          	auipc	a2,0x3
ffffffffc0203ea4:	d6860613          	addi	a2,a2,-664 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203ea8:	07100593          	li	a1,113
ffffffffc0203eac:	00004517          	auipc	a0,0x4
ffffffffc0203eb0:	f8450513          	addi	a0,a0,-124 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203eb4:	dd0fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==10);
ffffffffc0203eb8:	00004697          	auipc	a3,0x4
ffffffffc0203ebc:	08068693          	addi	a3,a3,128 # ffffffffc0207f38 <default_pmm_manager+0xbe8>
ffffffffc0203ec0:	00003617          	auipc	a2,0x3
ffffffffc0203ec4:	d4860613          	addi	a2,a2,-696 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203ec8:	06f00593          	li	a1,111
ffffffffc0203ecc:	00004517          	auipc	a0,0x4
ffffffffc0203ed0:	f6450513          	addi	a0,a0,-156 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203ed4:	db0fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==9);
ffffffffc0203ed8:	00004697          	auipc	a3,0x4
ffffffffc0203edc:	05068693          	addi	a3,a3,80 # ffffffffc0207f28 <default_pmm_manager+0xbd8>
ffffffffc0203ee0:	00003617          	auipc	a2,0x3
ffffffffc0203ee4:	d2860613          	addi	a2,a2,-728 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203ee8:	06c00593          	li	a1,108
ffffffffc0203eec:	00004517          	auipc	a0,0x4
ffffffffc0203ef0:	f4450513          	addi	a0,a0,-188 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203ef4:	d90fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==8);
ffffffffc0203ef8:	00004697          	auipc	a3,0x4
ffffffffc0203efc:	02068693          	addi	a3,a3,32 # ffffffffc0207f18 <default_pmm_manager+0xbc8>
ffffffffc0203f00:	00003617          	auipc	a2,0x3
ffffffffc0203f04:	d0860613          	addi	a2,a2,-760 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203f08:	06900593          	li	a1,105
ffffffffc0203f0c:	00004517          	auipc	a0,0x4
ffffffffc0203f10:	f2450513          	addi	a0,a0,-220 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203f14:	d70fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==7);
ffffffffc0203f18:	00004697          	auipc	a3,0x4
ffffffffc0203f1c:	ff068693          	addi	a3,a3,-16 # ffffffffc0207f08 <default_pmm_manager+0xbb8>
ffffffffc0203f20:	00003617          	auipc	a2,0x3
ffffffffc0203f24:	ce860613          	addi	a2,a2,-792 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203f28:	06600593          	li	a1,102
ffffffffc0203f2c:	00004517          	auipc	a0,0x4
ffffffffc0203f30:	f0450513          	addi	a0,a0,-252 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203f34:	d50fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==6);
ffffffffc0203f38:	00004697          	auipc	a3,0x4
ffffffffc0203f3c:	fc068693          	addi	a3,a3,-64 # ffffffffc0207ef8 <default_pmm_manager+0xba8>
ffffffffc0203f40:	00003617          	auipc	a2,0x3
ffffffffc0203f44:	cc860613          	addi	a2,a2,-824 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203f48:	06300593          	li	a1,99
ffffffffc0203f4c:	00004517          	auipc	a0,0x4
ffffffffc0203f50:	ee450513          	addi	a0,a0,-284 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203f54:	d30fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==5);
ffffffffc0203f58:	00004697          	auipc	a3,0x4
ffffffffc0203f5c:	f9068693          	addi	a3,a3,-112 # ffffffffc0207ee8 <default_pmm_manager+0xb98>
ffffffffc0203f60:	00003617          	auipc	a2,0x3
ffffffffc0203f64:	ca860613          	addi	a2,a2,-856 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203f68:	06000593          	li	a1,96
ffffffffc0203f6c:	00004517          	auipc	a0,0x4
ffffffffc0203f70:	ec450513          	addi	a0,a0,-316 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203f74:	d10fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==5);
ffffffffc0203f78:	00004697          	auipc	a3,0x4
ffffffffc0203f7c:	f7068693          	addi	a3,a3,-144 # ffffffffc0207ee8 <default_pmm_manager+0xb98>
ffffffffc0203f80:	00003617          	auipc	a2,0x3
ffffffffc0203f84:	c8860613          	addi	a2,a2,-888 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203f88:	05d00593          	li	a1,93
ffffffffc0203f8c:	00004517          	auipc	a0,0x4
ffffffffc0203f90:	ea450513          	addi	a0,a0,-348 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203f94:	cf0fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==4);
ffffffffc0203f98:	00004697          	auipc	a3,0x4
ffffffffc0203f9c:	d1068693          	addi	a3,a3,-752 # ffffffffc0207ca8 <default_pmm_manager+0x958>
ffffffffc0203fa0:	00003617          	auipc	a2,0x3
ffffffffc0203fa4:	c6860613          	addi	a2,a2,-920 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203fa8:	05a00593          	li	a1,90
ffffffffc0203fac:	00004517          	auipc	a0,0x4
ffffffffc0203fb0:	e8450513          	addi	a0,a0,-380 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203fb4:	cd0fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==4);
ffffffffc0203fb8:	00004697          	auipc	a3,0x4
ffffffffc0203fbc:	cf068693          	addi	a3,a3,-784 # ffffffffc0207ca8 <default_pmm_manager+0x958>
ffffffffc0203fc0:	00003617          	auipc	a2,0x3
ffffffffc0203fc4:	c4860613          	addi	a2,a2,-952 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203fc8:	05700593          	li	a1,87
ffffffffc0203fcc:	00004517          	auipc	a0,0x4
ffffffffc0203fd0:	e6450513          	addi	a0,a0,-412 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203fd4:	cb0fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgfault_num==4);
ffffffffc0203fd8:	00004697          	auipc	a3,0x4
ffffffffc0203fdc:	cd068693          	addi	a3,a3,-816 # ffffffffc0207ca8 <default_pmm_manager+0x958>
ffffffffc0203fe0:	00003617          	auipc	a2,0x3
ffffffffc0203fe4:	c2860613          	addi	a2,a2,-984 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0203fe8:	05400593          	li	a1,84
ffffffffc0203fec:	00004517          	auipc	a0,0x4
ffffffffc0203ff0:	e4450513          	addi	a0,a0,-444 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0203ff4:	c90fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0203ff8 <_fifo_swap_out_victim>:
     list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc0203ff8:	751c                	ld	a5,40(a0)
{
ffffffffc0203ffa:	1141                	addi	sp,sp,-16
ffffffffc0203ffc:	e406                	sd	ra,8(sp)
         assert(head != NULL);
ffffffffc0203ffe:	cf91                	beqz	a5,ffffffffc020401a <_fifo_swap_out_victim+0x22>
     assert(in_tick==0);
ffffffffc0204000:	ee0d                	bnez	a2,ffffffffc020403a <_fifo_swap_out_victim+0x42>
    return listelm->next;
ffffffffc0204002:	679c                	ld	a5,8(a5)
}
ffffffffc0204004:	60a2                	ld	ra,8(sp)
ffffffffc0204006:	4501                	li	a0,0
    __list_del(listelm->prev, listelm->next);
ffffffffc0204008:	6394                	ld	a3,0(a5)
ffffffffc020400a:	6798                	ld	a4,8(a5)
    *ptr_page = le2page(entry, pra_page_link);
ffffffffc020400c:	fd878793          	addi	a5,a5,-40
    prev->next = next;
ffffffffc0204010:	e698                	sd	a4,8(a3)
    next->prev = prev;
ffffffffc0204012:	e314                	sd	a3,0(a4)
ffffffffc0204014:	e19c                	sd	a5,0(a1)
}
ffffffffc0204016:	0141                	addi	sp,sp,16
ffffffffc0204018:	8082                	ret
         assert(head != NULL);
ffffffffc020401a:	00004697          	auipc	a3,0x4
ffffffffc020401e:	f8668693          	addi	a3,a3,-122 # ffffffffc0207fa0 <default_pmm_manager+0xc50>
ffffffffc0204022:	00003617          	auipc	a2,0x3
ffffffffc0204026:	be660613          	addi	a2,a2,-1050 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020402a:	04100593          	li	a1,65
ffffffffc020402e:	00004517          	auipc	a0,0x4
ffffffffc0204032:	e0250513          	addi	a0,a0,-510 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0204036:	c4efc0ef          	jal	ra,ffffffffc0200484 <__panic>
     assert(in_tick==0);
ffffffffc020403a:	00004697          	auipc	a3,0x4
ffffffffc020403e:	f7668693          	addi	a3,a3,-138 # ffffffffc0207fb0 <default_pmm_manager+0xc60>
ffffffffc0204042:	00003617          	auipc	a2,0x3
ffffffffc0204046:	bc660613          	addi	a2,a2,-1082 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020404a:	04200593          	li	a1,66
ffffffffc020404e:	00004517          	auipc	a0,0x4
ffffffffc0204052:	de250513          	addi	a0,a0,-542 # ffffffffc0207e30 <default_pmm_manager+0xae0>
ffffffffc0204056:	c2efc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020405a <_fifo_map_swappable>:
    list_entry_t *entry=&(page->pra_page_link);
ffffffffc020405a:	02860713          	addi	a4,a2,40
    list_entry_t *head=(list_entry_t*) mm->sm_priv;
ffffffffc020405e:	751c                	ld	a5,40(a0)
    assert(entry != NULL && head != NULL);
ffffffffc0204060:	cb09                	beqz	a4,ffffffffc0204072 <_fifo_map_swappable+0x18>
ffffffffc0204062:	cb81                	beqz	a5,ffffffffc0204072 <_fifo_map_swappable+0x18>
    __list_add(elm, listelm->prev, listelm);
ffffffffc0204064:	6394                	ld	a3,0(a5)
    prev->next = next->prev = elm;
ffffffffc0204066:	e398                	sd	a4,0(a5)
}
ffffffffc0204068:	4501                	li	a0,0
ffffffffc020406a:	e698                	sd	a4,8(a3)
    elm->next = next;
ffffffffc020406c:	fa1c                	sd	a5,48(a2)
    elm->prev = prev;
ffffffffc020406e:	f614                	sd	a3,40(a2)
ffffffffc0204070:	8082                	ret
{
ffffffffc0204072:	1141                	addi	sp,sp,-16
    assert(entry != NULL && head != NULL);
ffffffffc0204074:	00004697          	auipc	a3,0x4
ffffffffc0204078:	f0c68693          	addi	a3,a3,-244 # ffffffffc0207f80 <default_pmm_manager+0xc30>
ffffffffc020407c:	00003617          	auipc	a2,0x3
ffffffffc0204080:	b8c60613          	addi	a2,a2,-1140 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0204084:	03200593          	li	a1,50
ffffffffc0204088:	00004517          	auipc	a0,0x4
ffffffffc020408c:	da850513          	addi	a0,a0,-600 # ffffffffc0207e30 <default_pmm_manager+0xae0>
{
ffffffffc0204090:	e406                	sd	ra,8(sp)
    assert(entry != NULL && head != NULL);
ffffffffc0204092:	bf2fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204096 <check_vma_overlap.isra.0.part.1>:
}


// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc0204096:	1141                	addi	sp,sp,-16
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
ffffffffc0204098:	00004697          	auipc	a3,0x4
ffffffffc020409c:	f4068693          	addi	a3,a3,-192 # ffffffffc0207fd8 <default_pmm_manager+0xc88>
ffffffffc02040a0:	00003617          	auipc	a2,0x3
ffffffffc02040a4:	b6860613          	addi	a2,a2,-1176 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02040a8:	06d00593          	li	a1,109
ffffffffc02040ac:	00004517          	auipc	a0,0x4
ffffffffc02040b0:	f4c50513          	addi	a0,a0,-180 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next) {
ffffffffc02040b4:	e406                	sd	ra,8(sp)
    assert(next->vm_start < next->vm_end);
ffffffffc02040b6:	bcefc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02040ba <mm_create>:
mm_create(void) {
ffffffffc02040ba:	1141                	addi	sp,sp,-16
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02040bc:	04000513          	li	a0,64
mm_create(void) {
ffffffffc02040c0:	e022                	sd	s0,0(sp)
ffffffffc02040c2:	e406                	sd	ra,8(sp)
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));
ffffffffc02040c4:	b93fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc02040c8:	842a                	mv	s0,a0
    if (mm != NULL) {
ffffffffc02040ca:	c515                	beqz	a0,ffffffffc02040f6 <mm_create+0x3c>
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02040cc:	000a8797          	auipc	a5,0xa8
ffffffffc02040d0:	3ec78793          	addi	a5,a5,1004 # ffffffffc02ac4b8 <swap_init_ok>
ffffffffc02040d4:	439c                	lw	a5,0(a5)
    elm->prev = elm->next = elm;
ffffffffc02040d6:	e408                	sd	a0,8(s0)
ffffffffc02040d8:	e008                	sd	a0,0(s0)
        mm->mmap_cache = NULL;
ffffffffc02040da:	00053823          	sd	zero,16(a0)
        mm->pgdir = NULL;
ffffffffc02040de:	00053c23          	sd	zero,24(a0)
        mm->map_count = 0;
ffffffffc02040e2:	02052023          	sw	zero,32(a0)
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc02040e6:	2781                	sext.w	a5,a5
ffffffffc02040e8:	ef81                	bnez	a5,ffffffffc0204100 <mm_create+0x46>
        else mm->sm_priv = NULL;
ffffffffc02040ea:	02053423          	sd	zero,40(a0)
    return mm->mm_count;
}

static inline void
set_mm_count(struct mm_struct *mm, int val) {
    mm->mm_count = val;
ffffffffc02040ee:	02042823          	sw	zero,48(s0)

typedef volatile bool lock_t;

static inline void
lock_init(lock_t *lock) {
    *lock = 0;
ffffffffc02040f2:	02043c23          	sd	zero,56(s0)
}
ffffffffc02040f6:	8522                	mv	a0,s0
ffffffffc02040f8:	60a2                	ld	ra,8(sp)
ffffffffc02040fa:	6402                	ld	s0,0(sp)
ffffffffc02040fc:	0141                	addi	sp,sp,16
ffffffffc02040fe:	8082                	ret
        if (swap_init_ok) swap_init_mm(mm);
ffffffffc0204100:	a01ff0ef          	jal	ra,ffffffffc0203b00 <swap_init_mm>
ffffffffc0204104:	b7ed                	j	ffffffffc02040ee <mm_create+0x34>

ffffffffc0204106 <vma_create>:
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0204106:	1101                	addi	sp,sp,-32
ffffffffc0204108:	e04a                	sd	s2,0(sp)
ffffffffc020410a:	892a                	mv	s2,a0
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020410c:	03000513          	li	a0,48
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags) {
ffffffffc0204110:	e822                	sd	s0,16(sp)
ffffffffc0204112:	e426                	sd	s1,8(sp)
ffffffffc0204114:	ec06                	sd	ra,24(sp)
ffffffffc0204116:	84ae                	mv	s1,a1
ffffffffc0204118:	8432                	mv	s0,a2
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020411a:	b3dfd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
    if (vma != NULL) {
ffffffffc020411e:	c509                	beqz	a0,ffffffffc0204128 <vma_create+0x22>
        vma->vm_start = vm_start;
ffffffffc0204120:	01253423          	sd	s2,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204124:	e904                	sd	s1,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204126:	cd00                	sw	s0,24(a0)
}
ffffffffc0204128:	60e2                	ld	ra,24(sp)
ffffffffc020412a:	6442                	ld	s0,16(sp)
ffffffffc020412c:	64a2                	ld	s1,8(sp)
ffffffffc020412e:	6902                	ld	s2,0(sp)
ffffffffc0204130:	6105                	addi	sp,sp,32
ffffffffc0204132:	8082                	ret

ffffffffc0204134 <find_vma>:
    if (mm != NULL) {
ffffffffc0204134:	c51d                	beqz	a0,ffffffffc0204162 <find_vma+0x2e>
        vma = mm->mmap_cache;
ffffffffc0204136:	691c                	ld	a5,16(a0)
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0204138:	c781                	beqz	a5,ffffffffc0204140 <find_vma+0xc>
ffffffffc020413a:	6798                	ld	a4,8(a5)
ffffffffc020413c:	02e5f663          	bleu	a4,a1,ffffffffc0204168 <find_vma+0x34>
                list_entry_t *list = &(mm->mmap_list), *le = list;
ffffffffc0204140:	87aa                	mv	a5,a0
    return listelm->next;
ffffffffc0204142:	679c                	ld	a5,8(a5)
                while ((le = list_next(le)) != list) {
ffffffffc0204144:	00f50f63          	beq	a0,a5,ffffffffc0204162 <find_vma+0x2e>
                    if (vma->vm_start<=addr && addr < vma->vm_end) {
ffffffffc0204148:	fe87b703          	ld	a4,-24(a5)
ffffffffc020414c:	fee5ebe3          	bltu	a1,a4,ffffffffc0204142 <find_vma+0xe>
ffffffffc0204150:	ff07b703          	ld	a4,-16(a5)
ffffffffc0204154:	fee5f7e3          	bleu	a4,a1,ffffffffc0204142 <find_vma+0xe>
                    vma = le2vma(le, list_link);
ffffffffc0204158:	1781                	addi	a5,a5,-32
        if (vma != NULL) {
ffffffffc020415a:	c781                	beqz	a5,ffffffffc0204162 <find_vma+0x2e>
            mm->mmap_cache = vma;
ffffffffc020415c:	e91c                	sd	a5,16(a0)
}
ffffffffc020415e:	853e                	mv	a0,a5
ffffffffc0204160:	8082                	ret
    struct vma_struct *vma = NULL;
ffffffffc0204162:	4781                	li	a5,0
}
ffffffffc0204164:	853e                	mv	a0,a5
ffffffffc0204166:	8082                	ret
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr)) {
ffffffffc0204168:	6b98                	ld	a4,16(a5)
ffffffffc020416a:	fce5fbe3          	bleu	a4,a1,ffffffffc0204140 <find_vma+0xc>
            mm->mmap_cache = vma;
ffffffffc020416e:	e91c                	sd	a5,16(a0)
    return vma;
ffffffffc0204170:	b7fd                	j	ffffffffc020415e <find_vma+0x2a>

ffffffffc0204172 <insert_vma_struct>:


// insert_vma_struct -insert vma in mm's list link
void
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
    assert(vma->vm_start < vma->vm_end);
ffffffffc0204172:	6590                	ld	a2,8(a1)
ffffffffc0204174:	0105b803          	ld	a6,16(a1) # 1010 <_binary_obj___user_faultread_out_size-0x8570>
insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma) {
ffffffffc0204178:	1141                	addi	sp,sp,-16
ffffffffc020417a:	e406                	sd	ra,8(sp)
ffffffffc020417c:	872a                	mv	a4,a0
    assert(vma->vm_start < vma->vm_end);
ffffffffc020417e:	01066863          	bltu	a2,a6,ffffffffc020418e <insert_vma_struct+0x1c>
ffffffffc0204182:	a8b9                	j	ffffffffc02041e0 <insert_vma_struct+0x6e>
    list_entry_t *le_prev = list, *le_next;

        list_entry_t *le = list;
        while ((le = list_next(le)) != list) {
            struct vma_struct *mmap_prev = le2vma(le, list_link);
            if (mmap_prev->vm_start > vma->vm_start) {
ffffffffc0204184:	fe87b683          	ld	a3,-24(a5)
ffffffffc0204188:	04d66763          	bltu	a2,a3,ffffffffc02041d6 <insert_vma_struct+0x64>
ffffffffc020418c:	873e                	mv	a4,a5
ffffffffc020418e:	671c                	ld	a5,8(a4)
        while ((le = list_next(le)) != list) {
ffffffffc0204190:	fef51ae3          	bne	a0,a5,ffffffffc0204184 <insert_vma_struct+0x12>
        }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list) {
ffffffffc0204194:	02a70463          	beq	a4,a0,ffffffffc02041bc <insert_vma_struct+0x4a>
        check_vma_overlap(le2vma(le_prev, list_link), vma);
ffffffffc0204198:	ff073683          	ld	a3,-16(a4)
    assert(prev->vm_start < prev->vm_end);
ffffffffc020419c:	fe873883          	ld	a7,-24(a4)
ffffffffc02041a0:	08d8f063          	bleu	a3,a7,ffffffffc0204220 <insert_vma_struct+0xae>
    assert(prev->vm_end <= next->vm_start);
ffffffffc02041a4:	04d66e63          	bltu	a2,a3,ffffffffc0204200 <insert_vma_struct+0x8e>
    }
    if (le_next != list) {
ffffffffc02041a8:	00f50a63          	beq	a0,a5,ffffffffc02041bc <insert_vma_struct+0x4a>
ffffffffc02041ac:	fe87b683          	ld	a3,-24(a5)
    assert(prev->vm_end <= next->vm_start);
ffffffffc02041b0:	0506e863          	bltu	a3,a6,ffffffffc0204200 <insert_vma_struct+0x8e>
    assert(next->vm_start < next->vm_end);
ffffffffc02041b4:	ff07b603          	ld	a2,-16(a5)
ffffffffc02041b8:	02c6f263          	bleu	a2,a3,ffffffffc02041dc <insert_vma_struct+0x6a>
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count ++;
ffffffffc02041bc:	5114                	lw	a3,32(a0)
    vma->vm_mm = mm;
ffffffffc02041be:	e188                	sd	a0,0(a1)
    list_add_after(le_prev, &(vma->list_link));
ffffffffc02041c0:	02058613          	addi	a2,a1,32
    prev->next = next->prev = elm;
ffffffffc02041c4:	e390                	sd	a2,0(a5)
ffffffffc02041c6:	e710                	sd	a2,8(a4)
}
ffffffffc02041c8:	60a2                	ld	ra,8(sp)
    elm->next = next;
ffffffffc02041ca:	f59c                	sd	a5,40(a1)
    elm->prev = prev;
ffffffffc02041cc:	f198                	sd	a4,32(a1)
    mm->map_count ++;
ffffffffc02041ce:	2685                	addiw	a3,a3,1
ffffffffc02041d0:	d114                	sw	a3,32(a0)
}
ffffffffc02041d2:	0141                	addi	sp,sp,16
ffffffffc02041d4:	8082                	ret
    if (le_prev != list) {
ffffffffc02041d6:	fca711e3          	bne	a4,a0,ffffffffc0204198 <insert_vma_struct+0x26>
ffffffffc02041da:	bfd9                	j	ffffffffc02041b0 <insert_vma_struct+0x3e>
ffffffffc02041dc:	ebbff0ef          	jal	ra,ffffffffc0204096 <check_vma_overlap.isra.0.part.1>
    assert(vma->vm_start < vma->vm_end);
ffffffffc02041e0:	00004697          	auipc	a3,0x4
ffffffffc02041e4:	f0868693          	addi	a3,a3,-248 # ffffffffc02080e8 <default_pmm_manager+0xd98>
ffffffffc02041e8:	00003617          	auipc	a2,0x3
ffffffffc02041ec:	a2060613          	addi	a2,a2,-1504 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02041f0:	07400593          	li	a1,116
ffffffffc02041f4:	00004517          	auipc	a0,0x4
ffffffffc02041f8:	e0450513          	addi	a0,a0,-508 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc02041fc:	a88fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(prev->vm_end <= next->vm_start);
ffffffffc0204200:	00004697          	auipc	a3,0x4
ffffffffc0204204:	f2868693          	addi	a3,a3,-216 # ffffffffc0208128 <default_pmm_manager+0xdd8>
ffffffffc0204208:	00003617          	auipc	a2,0x3
ffffffffc020420c:	a0060613          	addi	a2,a2,-1536 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0204210:	06c00593          	li	a1,108
ffffffffc0204214:	00004517          	auipc	a0,0x4
ffffffffc0204218:	de450513          	addi	a0,a0,-540 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc020421c:	a68fc0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(prev->vm_start < prev->vm_end);
ffffffffc0204220:	00004697          	auipc	a3,0x4
ffffffffc0204224:	ee868693          	addi	a3,a3,-280 # ffffffffc0208108 <default_pmm_manager+0xdb8>
ffffffffc0204228:	00003617          	auipc	a2,0x3
ffffffffc020422c:	9e060613          	addi	a2,a2,-1568 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0204230:	06b00593          	li	a1,107
ffffffffc0204234:	00004517          	auipc	a0,0x4
ffffffffc0204238:	dc450513          	addi	a0,a0,-572 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc020423c:	a48fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204240 <mm_destroy>:

// mm_destroy - free mm and mm internal fields
void
mm_destroy(struct mm_struct *mm) {
    assert(mm_count(mm) == 0);
ffffffffc0204240:	591c                	lw	a5,48(a0)
mm_destroy(struct mm_struct *mm) {
ffffffffc0204242:	1141                	addi	sp,sp,-16
ffffffffc0204244:	e406                	sd	ra,8(sp)
ffffffffc0204246:	e022                	sd	s0,0(sp)
    assert(mm_count(mm) == 0);
ffffffffc0204248:	e78d                	bnez	a5,ffffffffc0204272 <mm_destroy+0x32>
ffffffffc020424a:	842a                	mv	s0,a0
    return listelm->next;
ffffffffc020424c:	6508                	ld	a0,8(a0)

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list) {
ffffffffc020424e:	00a40c63          	beq	s0,a0,ffffffffc0204266 <mm_destroy+0x26>
    __list_del(listelm->prev, listelm->next);
ffffffffc0204252:	6118                	ld	a4,0(a0)
ffffffffc0204254:	651c                	ld	a5,8(a0)
        list_del(le);
        kfree(le2vma(le, list_link));  //kfree vma        
ffffffffc0204256:	1501                	addi	a0,a0,-32
    prev->next = next;
ffffffffc0204258:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc020425a:	e398                	sd	a4,0(a5)
ffffffffc020425c:	ab7fd0ef          	jal	ra,ffffffffc0201d12 <kfree>
    return listelm->next;
ffffffffc0204260:	6408                	ld	a0,8(s0)
    while ((le = list_next(list)) != list) {
ffffffffc0204262:	fea418e3          	bne	s0,a0,ffffffffc0204252 <mm_destroy+0x12>
    }
    kfree(mm); //kfree mm
ffffffffc0204266:	8522                	mv	a0,s0
    mm=NULL;
}
ffffffffc0204268:	6402                	ld	s0,0(sp)
ffffffffc020426a:	60a2                	ld	ra,8(sp)
ffffffffc020426c:	0141                	addi	sp,sp,16
    kfree(mm); //kfree mm
ffffffffc020426e:	aa5fd06f          	j	ffffffffc0201d12 <kfree>
    assert(mm_count(mm) == 0);
ffffffffc0204272:	00004697          	auipc	a3,0x4
ffffffffc0204276:	ed668693          	addi	a3,a3,-298 # ffffffffc0208148 <default_pmm_manager+0xdf8>
ffffffffc020427a:	00003617          	auipc	a2,0x3
ffffffffc020427e:	98e60613          	addi	a2,a2,-1650 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0204282:	09400593          	li	a1,148
ffffffffc0204286:	00004517          	auipc	a0,0x4
ffffffffc020428a:	d7250513          	addi	a0,a0,-654 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc020428e:	9f6fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204292 <mm_map>:

//创建vma并插入到mm的链表中
int
mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
       struct vma_struct **vma_store) {
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0204292:	6785                	lui	a5,0x1
       struct vma_struct **vma_store) {
ffffffffc0204294:	7139                	addi	sp,sp,-64
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc0204296:	17fd                	addi	a5,a5,-1
ffffffffc0204298:	787d                	lui	a6,0xfffff
       struct vma_struct **vma_store) {
ffffffffc020429a:	f822                	sd	s0,48(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc020429c:	00f60433          	add	s0,a2,a5
       struct vma_struct **vma_store) {
ffffffffc02042a0:	f426                	sd	s1,40(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042a2:	942e                	add	s0,s0,a1
       struct vma_struct **vma_store) {
ffffffffc02042a4:	fc06                	sd	ra,56(sp)
ffffffffc02042a6:	f04a                	sd	s2,32(sp)
ffffffffc02042a8:	ec4e                	sd	s3,24(sp)
ffffffffc02042aa:	e852                	sd	s4,16(sp)
ffffffffc02042ac:	e456                	sd	s5,8(sp)
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
ffffffffc02042ae:	0105f4b3          	and	s1,a1,a6
    if (!USER_ACCESS(start, end)) {
ffffffffc02042b2:	002007b7          	lui	a5,0x200
ffffffffc02042b6:	01047433          	and	s0,s0,a6
ffffffffc02042ba:	06f4e363          	bltu	s1,a5,ffffffffc0204320 <mm_map+0x8e>
ffffffffc02042be:	0684f163          	bleu	s0,s1,ffffffffc0204320 <mm_map+0x8e>
ffffffffc02042c2:	4785                	li	a5,1
ffffffffc02042c4:	07fe                	slli	a5,a5,0x1f
ffffffffc02042c6:	0487ed63          	bltu	a5,s0,ffffffffc0204320 <mm_map+0x8e>
ffffffffc02042ca:	89aa                	mv	s3,a0
ffffffffc02042cc:	8a3a                	mv	s4,a4
ffffffffc02042ce:	8ab6                	mv	s5,a3
        return -E_INVAL;
    }

    assert(mm != NULL);
ffffffffc02042d0:	c931                	beqz	a0,ffffffffc0204324 <mm_map+0x92>

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
ffffffffc02042d2:	85a6                	mv	a1,s1
ffffffffc02042d4:	e61ff0ef          	jal	ra,ffffffffc0204134 <find_vma>
ffffffffc02042d8:	c501                	beqz	a0,ffffffffc02042e0 <mm_map+0x4e>
ffffffffc02042da:	651c                	ld	a5,8(a0)
ffffffffc02042dc:	0487e263          	bltu	a5,s0,ffffffffc0204320 <mm_map+0x8e>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02042e0:	03000513          	li	a0,48
ffffffffc02042e4:	973fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc02042e8:	892a                	mv	s2,a0
        goto out;
    }
    ret = -E_NO_MEM;
ffffffffc02042ea:	5571                	li	a0,-4
    if (vma != NULL) {
ffffffffc02042ec:	02090163          	beqz	s2,ffffffffc020430e <mm_map+0x7c>

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
ffffffffc02042f0:	854e                	mv	a0,s3
        vma->vm_start = vm_start;
ffffffffc02042f2:	00993423          	sd	s1,8(s2)
        vma->vm_end = vm_end;
ffffffffc02042f6:	00893823          	sd	s0,16(s2)
        vma->vm_flags = vm_flags;
ffffffffc02042fa:	01592c23          	sw	s5,24(s2)
    insert_vma_struct(mm, vma);
ffffffffc02042fe:	85ca                	mv	a1,s2
ffffffffc0204300:	e73ff0ef          	jal	ra,ffffffffc0204172 <insert_vma_struct>
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;
ffffffffc0204304:	4501                	li	a0,0
    if (vma_store != NULL) {
ffffffffc0204306:	000a0463          	beqz	s4,ffffffffc020430e <mm_map+0x7c>
        *vma_store = vma;
ffffffffc020430a:	012a3023          	sd	s2,0(s4)

out:
    return ret;
}
ffffffffc020430e:	70e2                	ld	ra,56(sp)
ffffffffc0204310:	7442                	ld	s0,48(sp)
ffffffffc0204312:	74a2                	ld	s1,40(sp)
ffffffffc0204314:	7902                	ld	s2,32(sp)
ffffffffc0204316:	69e2                	ld	s3,24(sp)
ffffffffc0204318:	6a42                	ld	s4,16(sp)
ffffffffc020431a:	6aa2                	ld	s5,8(sp)
ffffffffc020431c:	6121                	addi	sp,sp,64
ffffffffc020431e:	8082                	ret
        return -E_INVAL;
ffffffffc0204320:	5575                	li	a0,-3
ffffffffc0204322:	b7f5                	j	ffffffffc020430e <mm_map+0x7c>
    assert(mm != NULL);
ffffffffc0204324:	00004697          	auipc	a3,0x4
ffffffffc0204328:	80c68693          	addi	a3,a3,-2036 # ffffffffc0207b30 <default_pmm_manager+0x7e0>
ffffffffc020432c:	00003617          	auipc	a2,0x3
ffffffffc0204330:	8dc60613          	addi	a2,a2,-1828 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0204334:	0a800593          	li	a1,168
ffffffffc0204338:	00004517          	auipc	a0,0x4
ffffffffc020433c:	cc050513          	addi	a0,a0,-832 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204340:	944fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204344 <dup_mmap>:

//对所有oldmm中的vma遍历，复制新的vma到newmm中，同时对每个vma中的地址(以页为单位)进行内容复制
int
dup_mmap(struct mm_struct *to, struct mm_struct *from) {
ffffffffc0204344:	7139                	addi	sp,sp,-64
ffffffffc0204346:	fc06                	sd	ra,56(sp)
ffffffffc0204348:	f822                	sd	s0,48(sp)
ffffffffc020434a:	f426                	sd	s1,40(sp)
ffffffffc020434c:	f04a                	sd	s2,32(sp)
ffffffffc020434e:	ec4e                	sd	s3,24(sp)
ffffffffc0204350:	e852                	sd	s4,16(sp)
ffffffffc0204352:	e456                	sd	s5,8(sp)
    assert(to != NULL && from != NULL);
ffffffffc0204354:	c535                	beqz	a0,ffffffffc02043c0 <dup_mmap+0x7c>
ffffffffc0204356:	892a                	mv	s2,a0
ffffffffc0204358:	84ae                	mv	s1,a1
    list_entry_t *list = &(from->mmap_list), *le = list;
ffffffffc020435a:	842e                	mv	s0,a1
    assert(to != NULL && from != NULL);
ffffffffc020435c:	e59d                	bnez	a1,ffffffffc020438a <dup_mmap+0x46>
ffffffffc020435e:	a08d                	j	ffffffffc02043c0 <dup_mmap+0x7c>
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL) {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);
ffffffffc0204360:	85aa                	mv	a1,a0
        vma->vm_start = vm_start;
ffffffffc0204362:	0157b423          	sd	s5,8(a5) # 200008 <_binary_obj___user_exit_out_size+0x1f5588>
        insert_vma_struct(to, nvma);
ffffffffc0204366:	854a                	mv	a0,s2
        vma->vm_end = vm_end;
ffffffffc0204368:	0147b823          	sd	s4,16(a5)
        vma->vm_flags = vm_flags;
ffffffffc020436c:	0137ac23          	sw	s3,24(a5)
        insert_vma_struct(to, nvma);
ffffffffc0204370:	e03ff0ef          	jal	ra,ffffffffc0204172 <insert_vma_struct>

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0) {
ffffffffc0204374:	ff043683          	ld	a3,-16(s0)
ffffffffc0204378:	fe843603          	ld	a2,-24(s0)
ffffffffc020437c:	6c8c                	ld	a1,24(s1)
ffffffffc020437e:	01893503          	ld	a0,24(s2)
ffffffffc0204382:	4701                	li	a4,0
ffffffffc0204384:	d3bfe0ef          	jal	ra,ffffffffc02030be <copy_range>
ffffffffc0204388:	e105                	bnez	a0,ffffffffc02043a8 <dup_mmap+0x64>
    return listelm->prev;
ffffffffc020438a:	6000                	ld	s0,0(s0)
    while ((le = list_prev(le)) != list) {
ffffffffc020438c:	02848863          	beq	s1,s0,ffffffffc02043bc <dup_mmap+0x78>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204390:	03000513          	li	a0,48
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
ffffffffc0204394:	fe843a83          	ld	s5,-24(s0)
ffffffffc0204398:	ff043a03          	ld	s4,-16(s0)
ffffffffc020439c:	ff842983          	lw	s3,-8(s0)
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02043a0:	8b7fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc02043a4:	87aa                	mv	a5,a0
    if (vma != NULL) {
ffffffffc02043a6:	fd4d                	bnez	a0,ffffffffc0204360 <dup_mmap+0x1c>
            return -E_NO_MEM;
ffffffffc02043a8:	5571                	li	a0,-4
            return -E_NO_MEM;
        }
    }
    return 0;
}
ffffffffc02043aa:	70e2                	ld	ra,56(sp)
ffffffffc02043ac:	7442                	ld	s0,48(sp)
ffffffffc02043ae:	74a2                	ld	s1,40(sp)
ffffffffc02043b0:	7902                	ld	s2,32(sp)
ffffffffc02043b2:	69e2                	ld	s3,24(sp)
ffffffffc02043b4:	6a42                	ld	s4,16(sp)
ffffffffc02043b6:	6aa2                	ld	s5,8(sp)
ffffffffc02043b8:	6121                	addi	sp,sp,64
ffffffffc02043ba:	8082                	ret
    return 0;
ffffffffc02043bc:	4501                	li	a0,0
ffffffffc02043be:	b7f5                	j	ffffffffc02043aa <dup_mmap+0x66>
    assert(to != NULL && from != NULL);
ffffffffc02043c0:	00004697          	auipc	a3,0x4
ffffffffc02043c4:	ce868693          	addi	a3,a3,-792 # ffffffffc02080a8 <default_pmm_manager+0xd58>
ffffffffc02043c8:	00003617          	auipc	a2,0x3
ffffffffc02043cc:	84060613          	addi	a2,a2,-1984 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02043d0:	0c200593          	li	a1,194
ffffffffc02043d4:	00004517          	auipc	a0,0x4
ffffffffc02043d8:	c2450513          	addi	a0,a0,-988 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc02043dc:	8a8fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02043e0 <exit_mmap>:

void
exit_mmap(struct mm_struct *mm) {
ffffffffc02043e0:	1101                	addi	sp,sp,-32
ffffffffc02043e2:	ec06                	sd	ra,24(sp)
ffffffffc02043e4:	e822                	sd	s0,16(sp)
ffffffffc02043e6:	e426                	sd	s1,8(sp)
ffffffffc02043e8:	e04a                	sd	s2,0(sp)
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc02043ea:	c531                	beqz	a0,ffffffffc0204436 <exit_mmap+0x56>
ffffffffc02043ec:	591c                	lw	a5,48(a0)
ffffffffc02043ee:	84aa                	mv	s1,a0
ffffffffc02043f0:	e3b9                	bnez	a5,ffffffffc0204436 <exit_mmap+0x56>
    return listelm->next;
ffffffffc02043f2:	6500                	ld	s0,8(a0)
    pde_t *pgdir = mm->pgdir;
ffffffffc02043f4:	01853903          	ld	s2,24(a0)
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list) {
ffffffffc02043f8:	02850663          	beq	a0,s0,ffffffffc0204424 <exit_mmap+0x44>
        struct vma_struct *vma = le2vma(le, list_link);
        //删除vma的范围内分配的页表项，并释放这些页表项对应的物理页，只包括最低级的页表项
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc02043fc:	ff043603          	ld	a2,-16(s0)
ffffffffc0204400:	fe843583          	ld	a1,-24(s0)
ffffffffc0204404:	854a                	mv	a0,s2
ffffffffc0204406:	d8ffd0ef          	jal	ra,ffffffffc0202194 <unmap_range>
ffffffffc020440a:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc020440c:	fe8498e3          	bne	s1,s0,ffffffffc02043fc <exit_mmap+0x1c>
ffffffffc0204410:	6400                	ld	s0,8(s0)
    }
    while ((le = list_next(le)) != list) {
ffffffffc0204412:	00848c63          	beq	s1,s0,ffffffffc020442a <exit_mmap+0x4a>
        struct vma_struct *vma = le2vma(le, list_link);
        //释放对应的pde0和pde1
        exit_range(pgdir, vma->vm_start, vma->vm_end);
ffffffffc0204416:	ff043603          	ld	a2,-16(s0)
ffffffffc020441a:	fe843583          	ld	a1,-24(s0)
ffffffffc020441e:	854a                	mv	a0,s2
ffffffffc0204420:	e8dfd0ef          	jal	ra,ffffffffc02022ac <exit_range>
ffffffffc0204424:	6400                	ld	s0,8(s0)
    while ((le = list_next(le)) != list) {
ffffffffc0204426:	fe8498e3          	bne	s1,s0,ffffffffc0204416 <exit_mmap+0x36>
    }
}
ffffffffc020442a:	60e2                	ld	ra,24(sp)
ffffffffc020442c:	6442                	ld	s0,16(sp)
ffffffffc020442e:	64a2                	ld	s1,8(sp)
ffffffffc0204430:	6902                	ld	s2,0(sp)
ffffffffc0204432:	6105                	addi	sp,sp,32
ffffffffc0204434:	8082                	ret
    assert(mm != NULL && mm_count(mm) == 0);
ffffffffc0204436:	00004697          	auipc	a3,0x4
ffffffffc020443a:	c9268693          	addi	a3,a3,-878 # ffffffffc02080c8 <default_pmm_manager+0xd78>
ffffffffc020443e:	00002617          	auipc	a2,0x2
ffffffffc0204442:	7ca60613          	addi	a2,a2,1994 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0204446:	0d800593          	li	a1,216
ffffffffc020444a:	00004517          	auipc	a0,0x4
ffffffffc020444e:	bae50513          	addi	a0,a0,-1106 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204452:	832fc0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204456 <vmm_init>:
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void
vmm_init(void) {
ffffffffc0204456:	7139                	addi	sp,sp,-64
ffffffffc0204458:	f822                	sd	s0,48(sp)
ffffffffc020445a:	f426                	sd	s1,40(sp)
ffffffffc020445c:	fc06                	sd	ra,56(sp)
ffffffffc020445e:	f04a                	sd	s2,32(sp)
ffffffffc0204460:	ec4e                	sd	s3,24(sp)
ffffffffc0204462:	e852                	sd	s4,16(sp)
ffffffffc0204464:	e456                	sd	s5,8(sp)

static void
check_vma_struct(void) {
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
ffffffffc0204466:	c55ff0ef          	jal	ra,ffffffffc02040ba <mm_create>
    assert(mm != NULL);
ffffffffc020446a:	842a                	mv	s0,a0
ffffffffc020446c:	03200493          	li	s1,50
ffffffffc0204470:	e919                	bnez	a0,ffffffffc0204486 <vmm_init+0x30>
ffffffffc0204472:	a989                	j	ffffffffc02048c4 <vmm_init+0x46e>
        vma->vm_start = vm_start;
ffffffffc0204474:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc0204476:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc0204478:	00052c23          	sw	zero,24(a0)

    int i;
    for (i = step1; i >= 1; i --) {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc020447c:	14ed                	addi	s1,s1,-5
ffffffffc020447e:	8522                	mv	a0,s0
ffffffffc0204480:	cf3ff0ef          	jal	ra,ffffffffc0204172 <insert_vma_struct>
    for (i = step1; i >= 1; i --) {
ffffffffc0204484:	c88d                	beqz	s1,ffffffffc02044b6 <vmm_init+0x60>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc0204486:	03000513          	li	a0,48
ffffffffc020448a:	fccfd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc020448e:	85aa                	mv	a1,a0
ffffffffc0204490:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc0204494:	f165                	bnez	a0,ffffffffc0204474 <vmm_init+0x1e>
        assert(vma != NULL);
ffffffffc0204496:	00003697          	auipc	a3,0x3
ffffffffc020449a:	6d268693          	addi	a3,a3,1746 # ffffffffc0207b68 <default_pmm_manager+0x818>
ffffffffc020449e:	00002617          	auipc	a2,0x2
ffffffffc02044a2:	76a60613          	addi	a2,a2,1898 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02044a6:	11700593          	li	a1,279
ffffffffc02044aa:	00004517          	auipc	a0,0x4
ffffffffc02044ae:	b4e50513          	addi	a0,a0,-1202 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc02044b2:	fd3fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    for (i = step1; i >= 1; i --) {
ffffffffc02044b6:	03700493          	li	s1,55
    }

    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02044ba:	1f900913          	li	s2,505
ffffffffc02044be:	a819                	j	ffffffffc02044d4 <vmm_init+0x7e>
        vma->vm_start = vm_start;
ffffffffc02044c0:	e504                	sd	s1,8(a0)
        vma->vm_end = vm_end;
ffffffffc02044c2:	e91c                	sd	a5,16(a0)
        vma->vm_flags = vm_flags;
ffffffffc02044c4:	00052c23          	sw	zero,24(a0)
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
ffffffffc02044c8:	0495                	addi	s1,s1,5
ffffffffc02044ca:	8522                	mv	a0,s0
ffffffffc02044cc:	ca7ff0ef          	jal	ra,ffffffffc0204172 <insert_vma_struct>
    for (i = step1 + 1; i <= step2; i ++) {
ffffffffc02044d0:	03248a63          	beq	s1,s2,ffffffffc0204504 <vmm_init+0xae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc02044d4:	03000513          	li	a0,48
ffffffffc02044d8:	f7efd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc02044dc:	85aa                	mv	a1,a0
ffffffffc02044de:	00248793          	addi	a5,s1,2
    if (vma != NULL) {
ffffffffc02044e2:	fd79                	bnez	a0,ffffffffc02044c0 <vmm_init+0x6a>
        assert(vma != NULL);
ffffffffc02044e4:	00003697          	auipc	a3,0x3
ffffffffc02044e8:	68468693          	addi	a3,a3,1668 # ffffffffc0207b68 <default_pmm_manager+0x818>
ffffffffc02044ec:	00002617          	auipc	a2,0x2
ffffffffc02044f0:	71c60613          	addi	a2,a2,1820 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02044f4:	11d00593          	li	a1,285
ffffffffc02044f8:	00004517          	auipc	a0,0x4
ffffffffc02044fc:	b0050513          	addi	a0,a0,-1280 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204500:	f85fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204504:	6418                	ld	a4,8(s0)
ffffffffc0204506:	479d                	li	a5,7
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i ++) {
ffffffffc0204508:	1fb00593          	li	a1,507
        assert(le != &(mm->mmap_list));
ffffffffc020450c:	2ee40063          	beq	s0,a4,ffffffffc02047ec <vmm_init+0x396>
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc0204510:	fe873603          	ld	a2,-24(a4)
ffffffffc0204514:	ffe78693          	addi	a3,a5,-2
ffffffffc0204518:	24d61a63          	bne	a2,a3,ffffffffc020476c <vmm_init+0x316>
ffffffffc020451c:	ff073683          	ld	a3,-16(a4)
ffffffffc0204520:	24f69663          	bne	a3,a5,ffffffffc020476c <vmm_init+0x316>
ffffffffc0204524:	0795                	addi	a5,a5,5
ffffffffc0204526:	6718                	ld	a4,8(a4)
    for (i = 1; i <= step2; i ++) {
ffffffffc0204528:	feb792e3          	bne	a5,a1,ffffffffc020450c <vmm_init+0xb6>
ffffffffc020452c:	491d                	li	s2,7
ffffffffc020452e:	4495                	li	s1,5
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc0204530:	1f900a93          	li	s5,505
        struct vma_struct *vma1 = find_vma(mm, i);
ffffffffc0204534:	85a6                	mv	a1,s1
ffffffffc0204536:	8522                	mv	a0,s0
ffffffffc0204538:	bfdff0ef          	jal	ra,ffffffffc0204134 <find_vma>
ffffffffc020453c:	8a2a                	mv	s4,a0
        assert(vma1 != NULL);
ffffffffc020453e:	30050763          	beqz	a0,ffffffffc020484c <vmm_init+0x3f6>
        struct vma_struct *vma2 = find_vma(mm, i+1);
ffffffffc0204542:	00148593          	addi	a1,s1,1
ffffffffc0204546:	8522                	mv	a0,s0
ffffffffc0204548:	bedff0ef          	jal	ra,ffffffffc0204134 <find_vma>
ffffffffc020454c:	89aa                	mv	s3,a0
        assert(vma2 != NULL);
ffffffffc020454e:	2c050f63          	beqz	a0,ffffffffc020482c <vmm_init+0x3d6>
        struct vma_struct *vma3 = find_vma(mm, i+2);
ffffffffc0204552:	85ca                	mv	a1,s2
ffffffffc0204554:	8522                	mv	a0,s0
ffffffffc0204556:	bdfff0ef          	jal	ra,ffffffffc0204134 <find_vma>
        assert(vma3 == NULL);
ffffffffc020455a:	2a051963          	bnez	a0,ffffffffc020480c <vmm_init+0x3b6>
        struct vma_struct *vma4 = find_vma(mm, i+3);
ffffffffc020455e:	00348593          	addi	a1,s1,3
ffffffffc0204562:	8522                	mv	a0,s0
ffffffffc0204564:	bd1ff0ef          	jal	ra,ffffffffc0204134 <find_vma>
        assert(vma4 == NULL);
ffffffffc0204568:	32051263          	bnez	a0,ffffffffc020488c <vmm_init+0x436>
        struct vma_struct *vma5 = find_vma(mm, i+4);
ffffffffc020456c:	00448593          	addi	a1,s1,4
ffffffffc0204570:	8522                	mv	a0,s0
ffffffffc0204572:	bc3ff0ef          	jal	ra,ffffffffc0204134 <find_vma>
        assert(vma5 == NULL);
ffffffffc0204576:	2e051b63          	bnez	a0,ffffffffc020486c <vmm_init+0x416>

        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc020457a:	008a3783          	ld	a5,8(s4)
ffffffffc020457e:	20979763          	bne	a5,s1,ffffffffc020478c <vmm_init+0x336>
ffffffffc0204582:	010a3783          	ld	a5,16(s4)
ffffffffc0204586:	21279363          	bne	a5,s2,ffffffffc020478c <vmm_init+0x336>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc020458a:	0089b783          	ld	a5,8(s3)
ffffffffc020458e:	20979f63          	bne	a5,s1,ffffffffc02047ac <vmm_init+0x356>
ffffffffc0204592:	0109b783          	ld	a5,16(s3)
ffffffffc0204596:	21279b63          	bne	a5,s2,ffffffffc02047ac <vmm_init+0x356>
ffffffffc020459a:	0495                	addi	s1,s1,5
ffffffffc020459c:	0915                	addi	s2,s2,5
    for (i = 5; i <= 5 * step2; i +=5) {
ffffffffc020459e:	f9549be3          	bne	s1,s5,ffffffffc0204534 <vmm_init+0xde>
ffffffffc02045a2:	4491                	li	s1,4
    }

    for (i =4; i>=0; i--) {
ffffffffc02045a4:	597d                	li	s2,-1
        struct vma_struct *vma_below_5= find_vma(mm,i);
ffffffffc02045a6:	85a6                	mv	a1,s1
ffffffffc02045a8:	8522                	mv	a0,s0
ffffffffc02045aa:	b8bff0ef          	jal	ra,ffffffffc0204134 <find_vma>
ffffffffc02045ae:	0004859b          	sext.w	a1,s1
        if (vma_below_5 != NULL ) {
ffffffffc02045b2:	c90d                	beqz	a0,ffffffffc02045e4 <vmm_init+0x18e>
           cprintf("vma_below_5: i %x, start %x, end %x\n",i, vma_below_5->vm_start, vma_below_5->vm_end); 
ffffffffc02045b4:	6914                	ld	a3,16(a0)
ffffffffc02045b6:	6510                	ld	a2,8(a0)
ffffffffc02045b8:	00004517          	auipc	a0,0x4
ffffffffc02045bc:	ca850513          	addi	a0,a0,-856 # ffffffffc0208260 <default_pmm_manager+0xf10>
ffffffffc02045c0:	bcffb0ef          	jal	ra,ffffffffc020018e <cprintf>
        }
        assert(vma_below_5 == NULL);
ffffffffc02045c4:	00004697          	auipc	a3,0x4
ffffffffc02045c8:	cc468693          	addi	a3,a3,-828 # ffffffffc0208288 <default_pmm_manager+0xf38>
ffffffffc02045cc:	00002617          	auipc	a2,0x2
ffffffffc02045d0:	63c60613          	addi	a2,a2,1596 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02045d4:	13f00593          	li	a1,319
ffffffffc02045d8:	00004517          	auipc	a0,0x4
ffffffffc02045dc:	a2050513          	addi	a0,a0,-1504 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc02045e0:	ea5fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc02045e4:	14fd                	addi	s1,s1,-1
    for (i =4; i>=0; i--) {
ffffffffc02045e6:	fd2490e3          	bne	s1,s2,ffffffffc02045a6 <vmm_init+0x150>
    }

    mm_destroy(mm);
ffffffffc02045ea:	8522                	mv	a0,s0
ffffffffc02045ec:	c55ff0ef          	jal	ra,ffffffffc0204240 <mm_destroy>

    cprintf("check_vma_struct() succeeded!\n");
ffffffffc02045f0:	00004517          	auipc	a0,0x4
ffffffffc02045f4:	cb050513          	addi	a0,a0,-848 # ffffffffc02082a0 <default_pmm_manager+0xf50>
ffffffffc02045f8:	b97fb0ef          	jal	ra,ffffffffc020018e <cprintf>
struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void) {
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02045fc:	925fd0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc0204600:	89aa                	mv	s3,a0

    check_mm_struct = mm_create();
ffffffffc0204602:	ab9ff0ef          	jal	ra,ffffffffc02040ba <mm_create>
ffffffffc0204606:	000a8797          	auipc	a5,0xa8
ffffffffc020460a:	fea7b923          	sd	a0,-14(a5) # ffffffffc02ac5f8 <check_mm_struct>
ffffffffc020460e:	84aa                	mv	s1,a0
    assert(check_mm_struct != NULL);
ffffffffc0204610:	36050663          	beqz	a0,ffffffffc020497c <vmm_init+0x526>

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0204614:	000a8797          	auipc	a5,0xa8
ffffffffc0204618:	e8c78793          	addi	a5,a5,-372 # ffffffffc02ac4a0 <boot_pgdir>
ffffffffc020461c:	0007b903          	ld	s2,0(a5)
    assert(pgdir[0] == 0);
ffffffffc0204620:	00093783          	ld	a5,0(s2)
    pde_t *pgdir = mm->pgdir = boot_pgdir;
ffffffffc0204624:	01253c23          	sd	s2,24(a0)
    assert(pgdir[0] == 0);
ffffffffc0204628:	2c079e63          	bnez	a5,ffffffffc0204904 <vmm_init+0x4ae>
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));
ffffffffc020462c:	03000513          	li	a0,48
ffffffffc0204630:	e26fd0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc0204634:	842a                	mv	s0,a0
    if (vma != NULL) {
ffffffffc0204636:	18050b63          	beqz	a0,ffffffffc02047cc <vmm_init+0x376>
        vma->vm_end = vm_end;
ffffffffc020463a:	002007b7          	lui	a5,0x200
ffffffffc020463e:	e81c                	sd	a5,16(s0)
        vma->vm_flags = vm_flags;
ffffffffc0204640:	4789                	li	a5,2

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);
ffffffffc0204642:	85aa                	mv	a1,a0
        vma->vm_flags = vm_flags;
ffffffffc0204644:	cc1c                	sw	a5,24(s0)
    insert_vma_struct(mm, vma);
ffffffffc0204646:	8526                	mv	a0,s1
        vma->vm_start = vm_start;
ffffffffc0204648:	00043423          	sd	zero,8(s0)
    insert_vma_struct(mm, vma);
ffffffffc020464c:	b27ff0ef          	jal	ra,ffffffffc0204172 <insert_vma_struct>

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);
ffffffffc0204650:	10000593          	li	a1,256
ffffffffc0204654:	8526                	mv	a0,s1
ffffffffc0204656:	adfff0ef          	jal	ra,ffffffffc0204134 <find_vma>
ffffffffc020465a:	10000793          	li	a5,256

    int i, sum = 0;

    for (i = 0; i < 100; i ++) {
ffffffffc020465e:	16400713          	li	a4,356
    assert(find_vma(mm, addr) == vma);
ffffffffc0204662:	2ca41163          	bne	s0,a0,ffffffffc0204924 <vmm_init+0x4ce>
        *(char *)(addr + i) = i;
ffffffffc0204666:	00f78023          	sb	a5,0(a5) # 200000 <_binary_obj___user_exit_out_size+0x1f5580>
        sum += i;
ffffffffc020466a:	0785                	addi	a5,a5,1
    for (i = 0; i < 100; i ++) {
ffffffffc020466c:	fee79de3          	bne	a5,a4,ffffffffc0204666 <vmm_init+0x210>
        sum += i;
ffffffffc0204670:	6705                	lui	a4,0x1
    for (i = 0; i < 100; i ++) {
ffffffffc0204672:	10000793          	li	a5,256
        sum += i;
ffffffffc0204676:	35670713          	addi	a4,a4,854 # 1356 <_binary_obj___user_faultread_out_size-0x822a>
    }
    for (i = 0; i < 100; i ++) {
ffffffffc020467a:	16400613          	li	a2,356
        sum -= *(char *)(addr + i);
ffffffffc020467e:	0007c683          	lbu	a3,0(a5)
ffffffffc0204682:	0785                	addi	a5,a5,1
ffffffffc0204684:	9f15                	subw	a4,a4,a3
    for (i = 0; i < 100; i ++) {
ffffffffc0204686:	fec79ce3          	bne	a5,a2,ffffffffc020467e <vmm_init+0x228>
    }

    assert(sum == 0);
ffffffffc020468a:	2c071963          	bnez	a4,ffffffffc020495c <vmm_init+0x506>
    return pa2page(PDE_ADDR(pde));
ffffffffc020468e:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0204692:	000a8a97          	auipc	s5,0xa8
ffffffffc0204696:	e16a8a93          	addi	s5,s5,-490 # ffffffffc02ac4a8 <npage>
ffffffffc020469a:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020469e:	078a                	slli	a5,a5,0x2
ffffffffc02046a0:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02046a2:	20e7f563          	bleu	a4,a5,ffffffffc02048ac <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc02046a6:	00004697          	auipc	a3,0x4
ffffffffc02046aa:	63268693          	addi	a3,a3,1586 # ffffffffc0208cd8 <nbase>
ffffffffc02046ae:	0006ba03          	ld	s4,0(a3)
ffffffffc02046b2:	414786b3          	sub	a3,a5,s4
ffffffffc02046b6:	069a                	slli	a3,a3,0x6
    return page - pages + nbase;
ffffffffc02046b8:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc02046ba:	57fd                	li	a5,-1
    return page - pages + nbase;
ffffffffc02046bc:	96d2                	add	a3,a3,s4
    return KADDR(page2pa(page));
ffffffffc02046be:	83b1                	srli	a5,a5,0xc
ffffffffc02046c0:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc02046c2:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc02046c4:	28e7f063          	bleu	a4,a5,ffffffffc0204944 <vmm_init+0x4ee>
ffffffffc02046c8:	000a8797          	auipc	a5,0xa8
ffffffffc02046cc:	e4078793          	addi	a5,a5,-448 # ffffffffc02ac508 <va_pa_offset>
ffffffffc02046d0:	6380                	ld	s0,0(a5)

    pde_t *pd1=pgdir,*pd0=page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
ffffffffc02046d2:	4581                	li	a1,0
ffffffffc02046d4:	854a                	mv	a0,s2
ffffffffc02046d6:	9436                	add	s0,s0,a3
ffffffffc02046d8:	e2bfd0ef          	jal	ra,ffffffffc0202502 <page_remove>
    return pa2page(PDE_ADDR(pde));
ffffffffc02046dc:	601c                	ld	a5,0(s0)
    if (PPN(pa) >= npage) {
ffffffffc02046de:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc02046e2:	078a                	slli	a5,a5,0x2
ffffffffc02046e4:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc02046e6:	1ce7f363          	bleu	a4,a5,ffffffffc02048ac <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc02046ea:	000a8417          	auipc	s0,0xa8
ffffffffc02046ee:	e2e40413          	addi	s0,s0,-466 # ffffffffc02ac518 <pages>
ffffffffc02046f2:	6008                	ld	a0,0(s0)
ffffffffc02046f4:	414787b3          	sub	a5,a5,s4
ffffffffc02046f8:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd0[0]));
ffffffffc02046fa:	953e                	add	a0,a0,a5
ffffffffc02046fc:	4585                	li	a1,1
ffffffffc02046fe:	fdcfd0ef          	jal	ra,ffffffffc0201eda <free_pages>
    return pa2page(PDE_ADDR(pde));
ffffffffc0204702:	00093783          	ld	a5,0(s2)
    if (PPN(pa) >= npage) {
ffffffffc0204706:	000ab703          	ld	a4,0(s5)
    return pa2page(PDE_ADDR(pde));
ffffffffc020470a:	078a                	slli	a5,a5,0x2
ffffffffc020470c:	83b1                	srli	a5,a5,0xc
    if (PPN(pa) >= npage) {
ffffffffc020470e:	18e7ff63          	bleu	a4,a5,ffffffffc02048ac <vmm_init+0x456>
    return &pages[PPN(pa) - nbase];
ffffffffc0204712:	6008                	ld	a0,0(s0)
ffffffffc0204714:	414787b3          	sub	a5,a5,s4
ffffffffc0204718:	079a                	slli	a5,a5,0x6
    free_page(pde2page(pd1[0]));
ffffffffc020471a:	4585                	li	a1,1
ffffffffc020471c:	953e                	add	a0,a0,a5
ffffffffc020471e:	fbcfd0ef          	jal	ra,ffffffffc0201eda <free_pages>
    pgdir[0] = 0;
ffffffffc0204722:	00093023          	sd	zero,0(s2)
  asm volatile("sfence.vma");
ffffffffc0204726:	12000073          	sfence.vma
    flush_tlb();

    mm->pgdir = NULL;
ffffffffc020472a:	0004bc23          	sd	zero,24(s1)
    mm_destroy(mm);
ffffffffc020472e:	8526                	mv	a0,s1
ffffffffc0204730:	b11ff0ef          	jal	ra,ffffffffc0204240 <mm_destroy>
    check_mm_struct = NULL;
ffffffffc0204734:	000a8797          	auipc	a5,0xa8
ffffffffc0204738:	ec07b223          	sd	zero,-316(a5) # ffffffffc02ac5f8 <check_mm_struct>

    assert(nr_free_pages_store == nr_free_pages());
ffffffffc020473c:	fe4fd0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
ffffffffc0204740:	1aa99263          	bne	s3,a0,ffffffffc02048e4 <vmm_init+0x48e>

    cprintf("check_pgfault() succeeded!\n");
ffffffffc0204744:	00004517          	auipc	a0,0x4
ffffffffc0204748:	bec50513          	addi	a0,a0,-1044 # ffffffffc0208330 <default_pmm_manager+0xfe0>
ffffffffc020474c:	a43fb0ef          	jal	ra,ffffffffc020018e <cprintf>
}
ffffffffc0204750:	7442                	ld	s0,48(sp)
ffffffffc0204752:	70e2                	ld	ra,56(sp)
ffffffffc0204754:	74a2                	ld	s1,40(sp)
ffffffffc0204756:	7902                	ld	s2,32(sp)
ffffffffc0204758:	69e2                	ld	s3,24(sp)
ffffffffc020475a:	6a42                	ld	s4,16(sp)
ffffffffc020475c:	6aa2                	ld	s5,8(sp)
    cprintf("check_vmm() succeeded.\n");
ffffffffc020475e:	00004517          	auipc	a0,0x4
ffffffffc0204762:	bf250513          	addi	a0,a0,-1038 # ffffffffc0208350 <default_pmm_manager+0x1000>
}
ffffffffc0204766:	6121                	addi	sp,sp,64
    cprintf("check_vmm() succeeded.\n");
ffffffffc0204768:	a27fb06f          	j	ffffffffc020018e <cprintf>
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
ffffffffc020476c:	00004697          	auipc	a3,0x4
ffffffffc0204770:	a0c68693          	addi	a3,a3,-1524 # ffffffffc0208178 <default_pmm_manager+0xe28>
ffffffffc0204774:	00002617          	auipc	a2,0x2
ffffffffc0204778:	49460613          	addi	a2,a2,1172 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020477c:	12600593          	li	a1,294
ffffffffc0204780:	00004517          	auipc	a0,0x4
ffffffffc0204784:	87850513          	addi	a0,a0,-1928 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204788:	cfdfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma1->vm_start == i  && vma1->vm_end == i  + 2);
ffffffffc020478c:	00004697          	auipc	a3,0x4
ffffffffc0204790:	a7468693          	addi	a3,a3,-1420 # ffffffffc0208200 <default_pmm_manager+0xeb0>
ffffffffc0204794:	00002617          	auipc	a2,0x2
ffffffffc0204798:	47460613          	addi	a2,a2,1140 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020479c:	13600593          	li	a1,310
ffffffffc02047a0:	00004517          	auipc	a0,0x4
ffffffffc02047a4:	85850513          	addi	a0,a0,-1960 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc02047a8:	cddfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma2->vm_start == i  && vma2->vm_end == i  + 2);
ffffffffc02047ac:	00004697          	auipc	a3,0x4
ffffffffc02047b0:	a8468693          	addi	a3,a3,-1404 # ffffffffc0208230 <default_pmm_manager+0xee0>
ffffffffc02047b4:	00002617          	auipc	a2,0x2
ffffffffc02047b8:	45460613          	addi	a2,a2,1108 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02047bc:	13700593          	li	a1,311
ffffffffc02047c0:	00004517          	auipc	a0,0x4
ffffffffc02047c4:	83850513          	addi	a0,a0,-1992 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc02047c8:	cbdfb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(vma != NULL);
ffffffffc02047cc:	00003697          	auipc	a3,0x3
ffffffffc02047d0:	39c68693          	addi	a3,a3,924 # ffffffffc0207b68 <default_pmm_manager+0x818>
ffffffffc02047d4:	00002617          	auipc	a2,0x2
ffffffffc02047d8:	43460613          	addi	a2,a2,1076 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02047dc:	15600593          	li	a1,342
ffffffffc02047e0:	00004517          	auipc	a0,0x4
ffffffffc02047e4:	81850513          	addi	a0,a0,-2024 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc02047e8:	c9dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(le != &(mm->mmap_list));
ffffffffc02047ec:	00004697          	auipc	a3,0x4
ffffffffc02047f0:	97468693          	addi	a3,a3,-1676 # ffffffffc0208160 <default_pmm_manager+0xe10>
ffffffffc02047f4:	00002617          	auipc	a2,0x2
ffffffffc02047f8:	41460613          	addi	a2,a2,1044 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02047fc:	12400593          	li	a1,292
ffffffffc0204800:	00003517          	auipc	a0,0x3
ffffffffc0204804:	7f850513          	addi	a0,a0,2040 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204808:	c7dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma3 == NULL);
ffffffffc020480c:	00004697          	auipc	a3,0x4
ffffffffc0204810:	9c468693          	addi	a3,a3,-1596 # ffffffffc02081d0 <default_pmm_manager+0xe80>
ffffffffc0204814:	00002617          	auipc	a2,0x2
ffffffffc0204818:	3f460613          	addi	a2,a2,1012 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020481c:	13000593          	li	a1,304
ffffffffc0204820:	00003517          	auipc	a0,0x3
ffffffffc0204824:	7d850513          	addi	a0,a0,2008 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204828:	c5dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma2 != NULL);
ffffffffc020482c:	00004697          	auipc	a3,0x4
ffffffffc0204830:	99468693          	addi	a3,a3,-1644 # ffffffffc02081c0 <default_pmm_manager+0xe70>
ffffffffc0204834:	00002617          	auipc	a2,0x2
ffffffffc0204838:	3d460613          	addi	a2,a2,980 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020483c:	12e00593          	li	a1,302
ffffffffc0204840:	00003517          	auipc	a0,0x3
ffffffffc0204844:	7b850513          	addi	a0,a0,1976 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204848:	c3dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma1 != NULL);
ffffffffc020484c:	00004697          	auipc	a3,0x4
ffffffffc0204850:	96468693          	addi	a3,a3,-1692 # ffffffffc02081b0 <default_pmm_manager+0xe60>
ffffffffc0204854:	00002617          	auipc	a2,0x2
ffffffffc0204858:	3b460613          	addi	a2,a2,948 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020485c:	12c00593          	li	a1,300
ffffffffc0204860:	00003517          	auipc	a0,0x3
ffffffffc0204864:	79850513          	addi	a0,a0,1944 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204868:	c1dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma5 == NULL);
ffffffffc020486c:	00004697          	auipc	a3,0x4
ffffffffc0204870:	98468693          	addi	a3,a3,-1660 # ffffffffc02081f0 <default_pmm_manager+0xea0>
ffffffffc0204874:	00002617          	auipc	a2,0x2
ffffffffc0204878:	39460613          	addi	a2,a2,916 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020487c:	13400593          	li	a1,308
ffffffffc0204880:	00003517          	auipc	a0,0x3
ffffffffc0204884:	77850513          	addi	a0,a0,1912 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204888:	bfdfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        assert(vma4 == NULL);
ffffffffc020488c:	00004697          	auipc	a3,0x4
ffffffffc0204890:	95468693          	addi	a3,a3,-1708 # ffffffffc02081e0 <default_pmm_manager+0xe90>
ffffffffc0204894:	00002617          	auipc	a2,0x2
ffffffffc0204898:	37460613          	addi	a2,a2,884 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020489c:	13200593          	li	a1,306
ffffffffc02048a0:	00003517          	auipc	a0,0x3
ffffffffc02048a4:	75850513          	addi	a0,a0,1880 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc02048a8:	bddfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc02048ac:	00003617          	auipc	a2,0x3
ffffffffc02048b0:	b5460613          	addi	a2,a2,-1196 # ffffffffc0207400 <default_pmm_manager+0xb0>
ffffffffc02048b4:	06200593          	li	a1,98
ffffffffc02048b8:	00003517          	auipc	a0,0x3
ffffffffc02048bc:	b1050513          	addi	a0,a0,-1264 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc02048c0:	bc5fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(mm != NULL);
ffffffffc02048c4:	00003697          	auipc	a3,0x3
ffffffffc02048c8:	26c68693          	addi	a3,a3,620 # ffffffffc0207b30 <default_pmm_manager+0x7e0>
ffffffffc02048cc:	00002617          	auipc	a2,0x2
ffffffffc02048d0:	33c60613          	addi	a2,a2,828 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02048d4:	11000593          	li	a1,272
ffffffffc02048d8:	00003517          	auipc	a0,0x3
ffffffffc02048dc:	72050513          	addi	a0,a0,1824 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc02048e0:	ba5fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_free_pages_store == nr_free_pages());
ffffffffc02048e4:	00004697          	auipc	a3,0x4
ffffffffc02048e8:	a2468693          	addi	a3,a3,-1500 # ffffffffc0208308 <default_pmm_manager+0xfb8>
ffffffffc02048ec:	00002617          	auipc	a2,0x2
ffffffffc02048f0:	31c60613          	addi	a2,a2,796 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02048f4:	17400593          	li	a1,372
ffffffffc02048f8:	00003517          	auipc	a0,0x3
ffffffffc02048fc:	70050513          	addi	a0,a0,1792 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204900:	b85fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir[0] == 0);
ffffffffc0204904:	00003697          	auipc	a3,0x3
ffffffffc0204908:	25468693          	addi	a3,a3,596 # ffffffffc0207b58 <default_pmm_manager+0x808>
ffffffffc020490c:	00002617          	auipc	a2,0x2
ffffffffc0204910:	2fc60613          	addi	a2,a2,764 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0204914:	15300593          	li	a1,339
ffffffffc0204918:	00003517          	auipc	a0,0x3
ffffffffc020491c:	6e050513          	addi	a0,a0,1760 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204920:	b65fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(find_vma(mm, addr) == vma);
ffffffffc0204924:	00004697          	auipc	a3,0x4
ffffffffc0204928:	9b468693          	addi	a3,a3,-1612 # ffffffffc02082d8 <default_pmm_manager+0xf88>
ffffffffc020492c:	00002617          	auipc	a2,0x2
ffffffffc0204930:	2dc60613          	addi	a2,a2,732 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0204934:	15b00593          	li	a1,347
ffffffffc0204938:	00003517          	auipc	a0,0x3
ffffffffc020493c:	6c050513          	addi	a0,a0,1728 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204940:	b45fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc0204944:	00003617          	auipc	a2,0x3
ffffffffc0204948:	a5c60613          	addi	a2,a2,-1444 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc020494c:	06900593          	li	a1,105
ffffffffc0204950:	00003517          	auipc	a0,0x3
ffffffffc0204954:	a7850513          	addi	a0,a0,-1416 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0204958:	b2dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(sum == 0);
ffffffffc020495c:	00004697          	auipc	a3,0x4
ffffffffc0204960:	99c68693          	addi	a3,a3,-1636 # ffffffffc02082f8 <default_pmm_manager+0xfa8>
ffffffffc0204964:	00002617          	auipc	a2,0x2
ffffffffc0204968:	2a460613          	addi	a2,a2,676 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020496c:	16700593          	li	a1,359
ffffffffc0204970:	00003517          	auipc	a0,0x3
ffffffffc0204974:	68850513          	addi	a0,a0,1672 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204978:	b0dfb0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(check_mm_struct != NULL);
ffffffffc020497c:	00004697          	auipc	a3,0x4
ffffffffc0204980:	94468693          	addi	a3,a3,-1724 # ffffffffc02082c0 <default_pmm_manager+0xf70>
ffffffffc0204984:	00002617          	auipc	a2,0x2
ffffffffc0204988:	28460613          	addi	a2,a2,644 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020498c:	14f00593          	li	a1,335
ffffffffc0204990:	00003517          	auipc	a0,0x3
ffffffffc0204994:	66850513          	addi	a0,a0,1640 # ffffffffc0207ff8 <default_pmm_manager+0xca8>
ffffffffc0204998:	aedfb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc020499c <do_pgfault>:
 *            was a read (0) or write (1).
 *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
 *            or supervisor mode (0) at the time of the exception.
 */
int
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc020499c:	7179                	addi	sp,sp,-48
    int ret = -E_INVAL;
    //try to find a vma which include addr
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc020499e:	85b2                	mv	a1,a2
do_pgfault(struct mm_struct *mm, uint_t error_code, uintptr_t addr) {
ffffffffc02049a0:	f022                	sd	s0,32(sp)
ffffffffc02049a2:	ec26                	sd	s1,24(sp)
ffffffffc02049a4:	f406                	sd	ra,40(sp)
ffffffffc02049a6:	e84a                	sd	s2,16(sp)
ffffffffc02049a8:	8432                	mv	s0,a2
ffffffffc02049aa:	84aa                	mv	s1,a0
    struct vma_struct *vma = find_vma(mm, addr);
ffffffffc02049ac:	f88ff0ef          	jal	ra,ffffffffc0204134 <find_vma>

    pgfault_num++;
ffffffffc02049b0:	000a8797          	auipc	a5,0xa8
ffffffffc02049b4:	b0c78793          	addi	a5,a5,-1268 # ffffffffc02ac4bc <pgfault_num>
ffffffffc02049b8:	439c                	lw	a5,0(a5)
ffffffffc02049ba:	2785                	addiw	a5,a5,1
ffffffffc02049bc:	000a8717          	auipc	a4,0xa8
ffffffffc02049c0:	b0f72023          	sw	a5,-1280(a4) # ffffffffc02ac4bc <pgfault_num>
    //If the addr is in the range of a mm's vma?
    if (vma == NULL || vma->vm_start > addr) {
ffffffffc02049c4:	c551                	beqz	a0,ffffffffc0204a50 <do_pgfault+0xb4>
ffffffffc02049c6:	651c                	ld	a5,8(a0)
ffffffffc02049c8:	08f46463          	bltu	s0,a5,ffffffffc0204a50 <do_pgfault+0xb4>
     *    (read  an non_existed addr && addr is readable)
     * THEN
     *    continue process
     */
    uint32_t perm = PTE_U;
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02049cc:	4d1c                	lw	a5,24(a0)
    uint32_t perm = PTE_U;
ffffffffc02049ce:	4941                	li	s2,16
    if (vma->vm_flags & VM_WRITE) {
ffffffffc02049d0:	8b89                	andi	a5,a5,2
ffffffffc02049d2:	efb1                	bnez	a5,ffffffffc0204a2e <do_pgfault+0x92>
        perm |= READ_WRITE;
    }
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02049d4:	767d                	lui	a2,0xfffff

    pte_t *ptep=NULL;
  
    // try to find a pte, if pte's PT(Page Table) isn't existed, then create a PT.
    // (notice the 3th parameter '1')
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc02049d6:	6c88                	ld	a0,24(s1)
    addr = ROUNDDOWN(addr, PGSIZE);
ffffffffc02049d8:	8c71                	and	s0,s0,a2
    if ((ptep = get_pte(mm->pgdir, addr, 1)) == NULL) {
ffffffffc02049da:	85a2                	mv	a1,s0
ffffffffc02049dc:	4605                	li	a2,1
ffffffffc02049de:	d82fd0ef          	jal	ra,ffffffffc0201f60 <get_pte>
ffffffffc02049e2:	c941                	beqz	a0,ffffffffc0204a72 <do_pgfault+0xd6>
        cprintf("get_pte in do_pgfault failed\n");
        goto failed;
    }
    
    if (*ptep == 0) { // if the phy addr isn't exist, then alloc a page & map the phy addr with logical addr
ffffffffc02049e4:	610c                	ld	a1,0(a0)
ffffffffc02049e6:	c5b1                	beqz	a1,ffffffffc0204a32 <do_pgfault+0x96>
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok) {
ffffffffc02049e8:	000a8797          	auipc	a5,0xa8
ffffffffc02049ec:	ad078793          	addi	a5,a5,-1328 # ffffffffc02ac4b8 <swap_init_ok>
ffffffffc02049f0:	439c                	lw	a5,0(a5)
ffffffffc02049f2:	2781                	sext.w	a5,a5
ffffffffc02049f4:	c7bd                	beqz	a5,ffffffffc0204a62 <do_pgfault+0xc6>
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            swap_in(mm,addr,&page);
ffffffffc02049f6:	85a2                	mv	a1,s0
ffffffffc02049f8:	0030                	addi	a2,sp,8
ffffffffc02049fa:	8526                	mv	a0,s1
            struct Page *page = NULL;
ffffffffc02049fc:	e402                	sd	zero,8(sp)
            swap_in(mm,addr,&page);
ffffffffc02049fe:	a36ff0ef          	jal	ra,ffffffffc0203c34 <swap_in>
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            page_insert(mm->pgdir,page,addr,perm);
ffffffffc0204a02:	65a2                	ld	a1,8(sp)
ffffffffc0204a04:	6c88                	ld	a0,24(s1)
ffffffffc0204a06:	86ca                	mv	a3,s2
ffffffffc0204a08:	8622                	mv	a2,s0
ffffffffc0204a0a:	b6dfd0ef          	jal	ra,ffffffffc0202576 <page_insert>
            //(3) make the page swappable.
            swap_map_swappable(mm,addr,page,1);
ffffffffc0204a0e:	6622                	ld	a2,8(sp)
ffffffffc0204a10:	4685                	li	a3,1
ffffffffc0204a12:	85a2                	mv	a1,s0
ffffffffc0204a14:	8526                	mv	a0,s1
ffffffffc0204a16:	8faff0ef          	jal	ra,ffffffffc0203b10 <swap_map_swappable>
            page->pra_vaddr = addr;
ffffffffc0204a1a:	6722                	ld	a4,8(sp)
        } else {
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
            goto failed;
        }
   }
   ret = 0;
ffffffffc0204a1c:	4781                	li	a5,0
            page->pra_vaddr = addr;
ffffffffc0204a1e:	ff00                	sd	s0,56(a4)
failed:
    return ret;
}
ffffffffc0204a20:	70a2                	ld	ra,40(sp)
ffffffffc0204a22:	7402                	ld	s0,32(sp)
ffffffffc0204a24:	64e2                	ld	s1,24(sp)
ffffffffc0204a26:	6942                	ld	s2,16(sp)
ffffffffc0204a28:	853e                	mv	a0,a5
ffffffffc0204a2a:	6145                	addi	sp,sp,48
ffffffffc0204a2c:	8082                	ret
        perm |= READ_WRITE;
ffffffffc0204a2e:	495d                	li	s2,23
ffffffffc0204a30:	b755                	j	ffffffffc02049d4 <do_pgfault+0x38>
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204a32:	6c88                	ld	a0,24(s1)
ffffffffc0204a34:	864a                	mv	a2,s2
ffffffffc0204a36:	85a2                	mv	a1,s0
ffffffffc0204a38:	8b5fe0ef          	jal	ra,ffffffffc02032ec <pgdir_alloc_page>
   ret = 0;
ffffffffc0204a3c:	4781                	li	a5,0
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL) {
ffffffffc0204a3e:	f16d                	bnez	a0,ffffffffc0204a20 <do_pgfault+0x84>
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
ffffffffc0204a40:	00003517          	auipc	a0,0x3
ffffffffc0204a44:	61850513          	addi	a0,a0,1560 # ffffffffc0208058 <default_pmm_manager+0xd08>
ffffffffc0204a48:	f46fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204a4c:	57f1                	li	a5,-4
            goto failed;
ffffffffc0204a4e:	bfc9                	j	ffffffffc0204a20 <do_pgfault+0x84>
        cprintf("not valid addr %x, and  can not find it in vma\n", addr);
ffffffffc0204a50:	85a2                	mv	a1,s0
ffffffffc0204a52:	00003517          	auipc	a0,0x3
ffffffffc0204a56:	5b650513          	addi	a0,a0,1462 # ffffffffc0208008 <default_pmm_manager+0xcb8>
ffffffffc0204a5a:	f34fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    int ret = -E_INVAL;
ffffffffc0204a5e:	57f5                	li	a5,-3
        goto failed;
ffffffffc0204a60:	b7c1                	j	ffffffffc0204a20 <do_pgfault+0x84>
            cprintf("no swap_init_ok but ptep is %x, failed\n", *ptep);
ffffffffc0204a62:	00003517          	auipc	a0,0x3
ffffffffc0204a66:	61e50513          	addi	a0,a0,1566 # ffffffffc0208080 <default_pmm_manager+0xd30>
ffffffffc0204a6a:	f24fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204a6e:	57f1                	li	a5,-4
            goto failed;
ffffffffc0204a70:	bf45                	j	ffffffffc0204a20 <do_pgfault+0x84>
        cprintf("get_pte in do_pgfault failed\n");
ffffffffc0204a72:	00003517          	auipc	a0,0x3
ffffffffc0204a76:	5c650513          	addi	a0,a0,1478 # ffffffffc0208038 <default_pmm_manager+0xce8>
ffffffffc0204a7a:	f14fb0ef          	jal	ra,ffffffffc020018e <cprintf>
    ret = -E_NO_MEM;
ffffffffc0204a7e:	57f1                	li	a5,-4
        goto failed;
ffffffffc0204a80:	b745                	j	ffffffffc0204a20 <do_pgfault+0x84>

ffffffffc0204a82 <user_mem_check>:

//搜索 vma 链表，检查是否是一个合法的用户空间范围
bool
user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write) {
ffffffffc0204a82:	7179                	addi	sp,sp,-48
ffffffffc0204a84:	f022                	sd	s0,32(sp)
ffffffffc0204a86:	f406                	sd	ra,40(sp)
ffffffffc0204a88:	ec26                	sd	s1,24(sp)
ffffffffc0204a8a:	e84a                	sd	s2,16(sp)
ffffffffc0204a8c:	e44e                	sd	s3,8(sp)
ffffffffc0204a8e:	e052                	sd	s4,0(sp)
ffffffffc0204a90:	842e                	mv	s0,a1
//在内核空间内，将mm初始化了NULL，检查是对于用户空间
    if (mm != NULL) {
ffffffffc0204a92:	c135                	beqz	a0,ffffffffc0204af6 <user_mem_check+0x74>
        if (!USER_ACCESS(addr, addr + len)) {
ffffffffc0204a94:	002007b7          	lui	a5,0x200
ffffffffc0204a98:	04f5e663          	bltu	a1,a5,ffffffffc0204ae4 <user_mem_check+0x62>
ffffffffc0204a9c:	00c584b3          	add	s1,a1,a2
ffffffffc0204aa0:	0495f263          	bleu	s1,a1,ffffffffc0204ae4 <user_mem_check+0x62>
ffffffffc0204aa4:	4785                	li	a5,1
ffffffffc0204aa6:	07fe                	slli	a5,a5,0x1f
ffffffffc0204aa8:	0297ee63          	bltu	a5,s1,ffffffffc0204ae4 <user_mem_check+0x62>
ffffffffc0204aac:	892a                	mv	s2,a0
ffffffffc0204aae:	89b6                	mv	s3,a3
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK)) {
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204ab0:	6a05                	lui	s4,0x1
ffffffffc0204ab2:	a821                	j	ffffffffc0204aca <user_mem_check+0x48>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204ab4:	0027f693          	andi	a3,a5,2
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204ab8:	9752                	add	a4,a4,s4
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204aba:	8ba1                	andi	a5,a5,8
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204abc:	c685                	beqz	a3,ffffffffc0204ae4 <user_mem_check+0x62>
            if (write && (vma->vm_flags & VM_STACK)) {
ffffffffc0204abe:	c399                	beqz	a5,ffffffffc0204ac4 <user_mem_check+0x42>
                if (start < vma->vm_start + PGSIZE) { //check stack start & size
ffffffffc0204ac0:	02e46263          	bltu	s0,a4,ffffffffc0204ae4 <user_mem_check+0x62>
                    return 0;
                }
            }
            start = vma->vm_end;
ffffffffc0204ac4:	6900                	ld	s0,16(a0)
        while (start < end) {
ffffffffc0204ac6:	04947663          	bleu	s1,s0,ffffffffc0204b12 <user_mem_check+0x90>
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start) {
ffffffffc0204aca:	85a2                	mv	a1,s0
ffffffffc0204acc:	854a                	mv	a0,s2
ffffffffc0204ace:	e66ff0ef          	jal	ra,ffffffffc0204134 <find_vma>
ffffffffc0204ad2:	c909                	beqz	a0,ffffffffc0204ae4 <user_mem_check+0x62>
ffffffffc0204ad4:	6518                	ld	a4,8(a0)
ffffffffc0204ad6:	00e46763          	bltu	s0,a4,ffffffffc0204ae4 <user_mem_check+0x62>
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ))) {
ffffffffc0204ada:	4d1c                	lw	a5,24(a0)
ffffffffc0204adc:	fc099ce3          	bnez	s3,ffffffffc0204ab4 <user_mem_check+0x32>
ffffffffc0204ae0:	8b85                	andi	a5,a5,1
ffffffffc0204ae2:	f3ed                	bnez	a5,ffffffffc0204ac4 <user_mem_check+0x42>
            return 0;
ffffffffc0204ae4:	4501                	li	a0,0
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
ffffffffc0204ae6:	70a2                	ld	ra,40(sp)
ffffffffc0204ae8:	7402                	ld	s0,32(sp)
ffffffffc0204aea:	64e2                	ld	s1,24(sp)
ffffffffc0204aec:	6942                	ld	s2,16(sp)
ffffffffc0204aee:	69a2                	ld	s3,8(sp)
ffffffffc0204af0:	6a02                	ld	s4,0(sp)
ffffffffc0204af2:	6145                	addi	sp,sp,48
ffffffffc0204af4:	8082                	ret
    return KERN_ACCESS(addr, addr + len);
ffffffffc0204af6:	c02007b7          	lui	a5,0xc0200
ffffffffc0204afa:	4501                	li	a0,0
ffffffffc0204afc:	fef5e5e3          	bltu	a1,a5,ffffffffc0204ae6 <user_mem_check+0x64>
ffffffffc0204b00:	962e                	add	a2,a2,a1
ffffffffc0204b02:	fec5f2e3          	bleu	a2,a1,ffffffffc0204ae6 <user_mem_check+0x64>
ffffffffc0204b06:	c8000537          	lui	a0,0xc8000
ffffffffc0204b0a:	0505                	addi	a0,a0,1
ffffffffc0204b0c:	00a63533          	sltu	a0,a2,a0
ffffffffc0204b10:	bfd9                	j	ffffffffc0204ae6 <user_mem_check+0x64>
        return 1;
ffffffffc0204b12:	4505                	li	a0,1
ffffffffc0204b14:	bfc9                	j	ffffffffc0204ae6 <user_mem_check+0x64>

ffffffffc0204b16 <swapfs_init>:
#include <ide.h>
#include <pmm.h>
#include <assert.h>

void
swapfs_init(void) {
ffffffffc0204b16:	1141                	addi	sp,sp,-16
    static_assert((PGSIZE % SECTSIZE) == 0);
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b18:	4505                	li	a0,1
swapfs_init(void) {
ffffffffc0204b1a:	e406                	sd	ra,8(sp)
    if (!ide_device_valid(SWAP_DEV_NO)) {
ffffffffc0204b1c:	ae3fb0ef          	jal	ra,ffffffffc02005fe <ide_device_valid>
ffffffffc0204b20:	cd01                	beqz	a0,ffffffffc0204b38 <swapfs_init+0x22>
        panic("swap fs isn't available.\n");
    }
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b22:	4505                	li	a0,1
ffffffffc0204b24:	ae1fb0ef          	jal	ra,ffffffffc0200604 <ide_device_size>
}
ffffffffc0204b28:	60a2                	ld	ra,8(sp)
    max_swap_offset = ide_device_size(SWAP_DEV_NO) / (PGSIZE / SECTSIZE);
ffffffffc0204b2a:	810d                	srli	a0,a0,0x3
ffffffffc0204b2c:	000a8797          	auipc	a5,0xa8
ffffffffc0204b30:	a6a7be23          	sd	a0,-1412(a5) # ffffffffc02ac5a8 <max_swap_offset>
}
ffffffffc0204b34:	0141                	addi	sp,sp,16
ffffffffc0204b36:	8082                	ret
        panic("swap fs isn't available.\n");
ffffffffc0204b38:	00004617          	auipc	a2,0x4
ffffffffc0204b3c:	83060613          	addi	a2,a2,-2000 # ffffffffc0208368 <default_pmm_manager+0x1018>
ffffffffc0204b40:	45b5                	li	a1,13
ffffffffc0204b42:	00004517          	auipc	a0,0x4
ffffffffc0204b46:	84650513          	addi	a0,a0,-1978 # ffffffffc0208388 <default_pmm_manager+0x1038>
ffffffffc0204b4a:	93bfb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204b4e <swapfs_read>:

int
swapfs_read(swap_entry_t entry, struct Page *page) {
ffffffffc0204b4e:	1141                	addi	sp,sp,-16
ffffffffc0204b50:	e406                	sd	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204b52:	00855793          	srli	a5,a0,0x8
ffffffffc0204b56:	cfb9                	beqz	a5,ffffffffc0204bb4 <swapfs_read+0x66>
ffffffffc0204b58:	000a8717          	auipc	a4,0xa8
ffffffffc0204b5c:	a5070713          	addi	a4,a4,-1456 # ffffffffc02ac5a8 <max_swap_offset>
ffffffffc0204b60:	6318                	ld	a4,0(a4)
ffffffffc0204b62:	04e7f963          	bleu	a4,a5,ffffffffc0204bb4 <swapfs_read+0x66>
    return page - pages + nbase;
ffffffffc0204b66:	000a8717          	auipc	a4,0xa8
ffffffffc0204b6a:	9b270713          	addi	a4,a4,-1614 # ffffffffc02ac518 <pages>
ffffffffc0204b6e:	6310                	ld	a2,0(a4)
ffffffffc0204b70:	00004717          	auipc	a4,0x4
ffffffffc0204b74:	16870713          	addi	a4,a4,360 # ffffffffc0208cd8 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204b78:	000a8697          	auipc	a3,0xa8
ffffffffc0204b7c:	93068693          	addi	a3,a3,-1744 # ffffffffc02ac4a8 <npage>
    return page - pages + nbase;
ffffffffc0204b80:	40c58633          	sub	a2,a1,a2
ffffffffc0204b84:	630c                	ld	a1,0(a4)
ffffffffc0204b86:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204b88:	577d                	li	a4,-1
ffffffffc0204b8a:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204b8c:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204b8e:	8331                	srli	a4,a4,0xc
ffffffffc0204b90:	8f71                	and	a4,a4,a2
ffffffffc0204b92:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204b96:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204b98:	02d77a63          	bleu	a3,a4,ffffffffc0204bcc <swapfs_read+0x7e>
ffffffffc0204b9c:	000a8797          	auipc	a5,0xa8
ffffffffc0204ba0:	96c78793          	addi	a5,a5,-1684 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0204ba4:	639c                	ld	a5,0(a5)
}
ffffffffc0204ba6:	60a2                	ld	ra,8(sp)
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204ba8:	46a1                	li	a3,8
ffffffffc0204baa:	963e                	add	a2,a2,a5
ffffffffc0204bac:	4505                	li	a0,1
}
ffffffffc0204bae:	0141                	addi	sp,sp,16
    return ide_read_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bb0:	a5bfb06f          	j	ffffffffc020060a <ide_read_secs>
ffffffffc0204bb4:	86aa                	mv	a3,a0
ffffffffc0204bb6:	00003617          	auipc	a2,0x3
ffffffffc0204bba:	7ea60613          	addi	a2,a2,2026 # ffffffffc02083a0 <default_pmm_manager+0x1050>
ffffffffc0204bbe:	45d1                	li	a1,20
ffffffffc0204bc0:	00003517          	auipc	a0,0x3
ffffffffc0204bc4:	7c850513          	addi	a0,a0,1992 # ffffffffc0208388 <default_pmm_manager+0x1038>
ffffffffc0204bc8:	8bdfb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204bcc:	86b2                	mv	a3,a2
ffffffffc0204bce:	06900593          	li	a1,105
ffffffffc0204bd2:	00002617          	auipc	a2,0x2
ffffffffc0204bd6:	7ce60613          	addi	a2,a2,1998 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0204bda:	00002517          	auipc	a0,0x2
ffffffffc0204bde:	7ee50513          	addi	a0,a0,2030 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0204be2:	8a3fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204be6 <swapfs_write>:

int
swapfs_write(swap_entry_t entry, struct Page *page) {
ffffffffc0204be6:	1141                	addi	sp,sp,-16
ffffffffc0204be8:	e406                	sd	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204bea:	00855793          	srli	a5,a0,0x8
ffffffffc0204bee:	cfb9                	beqz	a5,ffffffffc0204c4c <swapfs_write+0x66>
ffffffffc0204bf0:	000a8717          	auipc	a4,0xa8
ffffffffc0204bf4:	9b870713          	addi	a4,a4,-1608 # ffffffffc02ac5a8 <max_swap_offset>
ffffffffc0204bf8:	6318                	ld	a4,0(a4)
ffffffffc0204bfa:	04e7f963          	bleu	a4,a5,ffffffffc0204c4c <swapfs_write+0x66>
    return page - pages + nbase;
ffffffffc0204bfe:	000a8717          	auipc	a4,0xa8
ffffffffc0204c02:	91a70713          	addi	a4,a4,-1766 # ffffffffc02ac518 <pages>
ffffffffc0204c06:	6310                	ld	a2,0(a4)
ffffffffc0204c08:	00004717          	auipc	a4,0x4
ffffffffc0204c0c:	0d070713          	addi	a4,a4,208 # ffffffffc0208cd8 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204c10:	000a8697          	auipc	a3,0xa8
ffffffffc0204c14:	89868693          	addi	a3,a3,-1896 # ffffffffc02ac4a8 <npage>
    return page - pages + nbase;
ffffffffc0204c18:	40c58633          	sub	a2,a1,a2
ffffffffc0204c1c:	630c                	ld	a1,0(a4)
ffffffffc0204c1e:	8619                	srai	a2,a2,0x6
    return KADDR(page2pa(page));
ffffffffc0204c20:	577d                	li	a4,-1
ffffffffc0204c22:	6294                	ld	a3,0(a3)
    return page - pages + nbase;
ffffffffc0204c24:	962e                	add	a2,a2,a1
    return KADDR(page2pa(page));
ffffffffc0204c26:	8331                	srli	a4,a4,0xc
ffffffffc0204c28:	8f71                	and	a4,a4,a2
ffffffffc0204c2a:	0037959b          	slliw	a1,a5,0x3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204c2e:	0632                	slli	a2,a2,0xc
    return KADDR(page2pa(page));
ffffffffc0204c30:	02d77a63          	bleu	a3,a4,ffffffffc0204c64 <swapfs_write+0x7e>
ffffffffc0204c34:	000a8797          	auipc	a5,0xa8
ffffffffc0204c38:	8d478793          	addi	a5,a5,-1836 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0204c3c:	639c                	ld	a5,0(a5)
}
ffffffffc0204c3e:	60a2                	ld	ra,8(sp)
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c40:	46a1                	li	a3,8
ffffffffc0204c42:	963e                	add	a2,a2,a5
ffffffffc0204c44:	4505                	li	a0,1
}
ffffffffc0204c46:	0141                	addi	sp,sp,16
    return ide_write_secs(SWAP_DEV_NO, swap_offset(entry) * PAGE_NSECT, page2kva(page), PAGE_NSECT);
ffffffffc0204c48:	9e7fb06f          	j	ffffffffc020062e <ide_write_secs>
ffffffffc0204c4c:	86aa                	mv	a3,a0
ffffffffc0204c4e:	00003617          	auipc	a2,0x3
ffffffffc0204c52:	75260613          	addi	a2,a2,1874 # ffffffffc02083a0 <default_pmm_manager+0x1050>
ffffffffc0204c56:	45e5                	li	a1,25
ffffffffc0204c58:	00003517          	auipc	a0,0x3
ffffffffc0204c5c:	73050513          	addi	a0,a0,1840 # ffffffffc0208388 <default_pmm_manager+0x1038>
ffffffffc0204c60:	825fb0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0204c64:	86b2                	mv	a3,a2
ffffffffc0204c66:	06900593          	li	a1,105
ffffffffc0204c6a:	00002617          	auipc	a2,0x2
ffffffffc0204c6e:	73660613          	addi	a2,a2,1846 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0204c72:	00002517          	auipc	a0,0x2
ffffffffc0204c76:	75650513          	addi	a0,a0,1878 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0204c7a:	80bfb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204c7e <kernel_thread_entry>:
.text
.globl kernel_thread_entry
kernel_thread_entry:        # void kernel_thread(void)
	move a0, s1
ffffffffc0204c7e:	8526                	mv	a0,s1
	jalr s0
ffffffffc0204c80:	9402                	jalr	s0

	jal do_exit
ffffffffc0204c82:	742000ef          	jal	ra,ffffffffc02053c4 <do_exit>

ffffffffc0204c86 <alloc_proc>:
void forkrets(struct trapframe *tf);
void switch_to(struct context *from, struct context *to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct *
alloc_proc(void) {
ffffffffc0204c86:	1141                	addi	sp,sp,-16
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204c88:	10800513          	li	a0,264
alloc_proc(void) {
ffffffffc0204c8c:	e022                	sd	s0,0(sp)
ffffffffc0204c8e:	e406                	sd	ra,8(sp)
    struct proc_struct *proc = kmalloc(sizeof(struct proc_struct));
ffffffffc0204c90:	fc7fc0ef          	jal	ra,ffffffffc0201c56 <kmalloc>
ffffffffc0204c94:	842a                	mv	s0,a0
    if (proc != NULL) {
ffffffffc0204c96:	cd29                	beqz	a0,ffffffffc0204cf0 <alloc_proc+0x6a>
     /*
     * below fields(add in LAB5) in proc_struct need to be initialized  
     *       uint32_t wait_state;                        // waiting state
     *       struct proc_struct *cptr, *yptr, *optr;     // relations between processes
     */
    proc->state=PROC_UNINIT;    //未初始化状态
ffffffffc0204c98:	57fd                	li	a5,-1
ffffffffc0204c9a:	1782                	slli	a5,a5,0x20
ffffffffc0204c9c:	e11c                	sd	a5,0(a0)
    proc->kstack=0;
    proc->need_resched=0;
    proc->parent=NULL;
    proc->mm=NULL;
    //context结构体全部置为0
    memset(&(proc->context),0,sizeof(struct context));
ffffffffc0204c9e:	07000613          	li	a2,112
ffffffffc0204ca2:	4581                	li	a1,0
    proc->runs=0;
ffffffffc0204ca4:	00052423          	sw	zero,8(a0)
    proc->kstack=0;
ffffffffc0204ca8:	00053823          	sd	zero,16(a0)
    proc->need_resched=0;
ffffffffc0204cac:	00053c23          	sd	zero,24(a0)
    proc->parent=NULL;
ffffffffc0204cb0:	02053023          	sd	zero,32(a0)
    proc->mm=NULL;
ffffffffc0204cb4:	02053423          	sd	zero,40(a0)
    memset(&(proc->context),0,sizeof(struct context));
ffffffffc0204cb8:	03050513          	addi	a0,a0,48
ffffffffc0204cbc:	133010ef          	jal	ra,ffffffffc02065ee <memset>
    proc->tf=NULL;
    //设置为ucore内核表的起始地址
    proc->cr3=boot_cr3;
ffffffffc0204cc0:	000a8797          	auipc	a5,0xa8
ffffffffc0204cc4:	85078793          	addi	a5,a5,-1968 # ffffffffc02ac510 <boot_cr3>
ffffffffc0204cc8:	639c                	ld	a5,0(a5)
    proc->tf=NULL;
ffffffffc0204cca:	0a043023          	sd	zero,160(s0)
    proc->flags=0;
ffffffffc0204cce:	0a042823          	sw	zero,176(s0)
    proc->cr3=boot_cr3;
ffffffffc0204cd2:	f45c                	sd	a5,168(s0)
    //保留一个char存放'\0'
    memset(proc->name,0,PROC_NAME_LEN);
ffffffffc0204cd4:	463d                	li	a2,15
ffffffffc0204cd6:	4581                	li	a1,0
ffffffffc0204cd8:	0b440513          	addi	a0,s0,180
ffffffffc0204cdc:	113010ef          	jal	ra,ffffffffc02065ee <memset>
    proc->wait_state=0;
ffffffffc0204ce0:	0e042623          	sw	zero,236(s0)
    proc->cptr=NULL;
ffffffffc0204ce4:	0e043823          	sd	zero,240(s0)
    proc->yptr=NULL;
ffffffffc0204ce8:	0e043c23          	sd	zero,248(s0)
    proc->optr=NULL;
ffffffffc0204cec:	10043023          	sd	zero,256(s0)
    }
    return proc;
}
ffffffffc0204cf0:	8522                	mv	a0,s0
ffffffffc0204cf2:	60a2                	ld	ra,8(sp)
ffffffffc0204cf4:	6402                	ld	s0,0(sp)
ffffffffc0204cf6:	0141                	addi	sp,sp,16
ffffffffc0204cf8:	8082                	ret

ffffffffc0204cfa <forkret>:
// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
ffffffffc0204cfa:	000a7797          	auipc	a5,0xa7
ffffffffc0204cfe:	7c678793          	addi	a5,a5,1990 # ffffffffc02ac4c0 <current>
ffffffffc0204d02:	639c                	ld	a5,0(a5)
ffffffffc0204d04:	73c8                	ld	a0,160(a5)
ffffffffc0204d06:	8a4fc06f          	j	ffffffffc0200daa <forkrets>

ffffffffc0204d0a <user_main>:

// user_main - kernel thread used to exec a user program
static int
user_main(void *arg) {
#ifdef TEST
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d0a:	000a7797          	auipc	a5,0xa7
ffffffffc0204d0e:	7b678793          	addi	a5,a5,1974 # ffffffffc02ac4c0 <current>
ffffffffc0204d12:	639c                	ld	a5,0(a5)
user_main(void *arg) {
ffffffffc0204d14:	7139                	addi	sp,sp,-64
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d16:	00004617          	auipc	a2,0x4
ffffffffc0204d1a:	a9260613          	addi	a2,a2,-1390 # ffffffffc02087a8 <default_pmm_manager+0x1458>
ffffffffc0204d1e:	43cc                	lw	a1,4(a5)
ffffffffc0204d20:	00004517          	auipc	a0,0x4
ffffffffc0204d24:	a9850513          	addi	a0,a0,-1384 # ffffffffc02087b8 <default_pmm_manager+0x1468>
user_main(void *arg) {
ffffffffc0204d28:	fc06                	sd	ra,56(sp)
    KERNEL_EXECVE2(TEST, TESTSTART, TESTSIZE);
ffffffffc0204d2a:	c64fb0ef          	jal	ra,ffffffffc020018e <cprintf>
ffffffffc0204d2e:	00004797          	auipc	a5,0x4
ffffffffc0204d32:	a7a78793          	addi	a5,a5,-1414 # ffffffffc02087a8 <default_pmm_manager+0x1458>
ffffffffc0204d36:	3fe05717          	auipc	a4,0x3fe05
ffffffffc0204d3a:	5aa70713          	addi	a4,a4,1450 # a2e0 <_binary_obj___user_forktest_out_size>
ffffffffc0204d3e:	e43a                	sd	a4,8(sp)
    int64_t ret=0, len = strlen(name);
ffffffffc0204d40:	853e                	mv	a0,a5
ffffffffc0204d42:	00043717          	auipc	a4,0x43
ffffffffc0204d46:	30e70713          	addi	a4,a4,782 # ffffffffc0248050 <_binary_obj___user_forktest_out_start>
ffffffffc0204d4a:	f03a                	sd	a4,32(sp)
ffffffffc0204d4c:	f43e                	sd	a5,40(sp)
ffffffffc0204d4e:	e802                	sd	zero,16(sp)
ffffffffc0204d50:	001010ef          	jal	ra,ffffffffc0206550 <strlen>
ffffffffc0204d54:	ec2a                	sd	a0,24(sp)
    asm volatile(
ffffffffc0204d56:	4511                	li	a0,4
ffffffffc0204d58:	55a2                	lw	a1,40(sp)
ffffffffc0204d5a:	4662                	lw	a2,24(sp)
ffffffffc0204d5c:	5682                	lw	a3,32(sp)
ffffffffc0204d5e:	4722                	lw	a4,8(sp)
ffffffffc0204d60:	48a9                	li	a7,10
ffffffffc0204d62:	9002                	ebreak
ffffffffc0204d64:	c82a                	sw	a0,16(sp)
    cprintf("ret = %d\n", ret);
ffffffffc0204d66:	65c2                	ld	a1,16(sp)
ffffffffc0204d68:	00004517          	auipc	a0,0x4
ffffffffc0204d6c:	a7850513          	addi	a0,a0,-1416 # ffffffffc02087e0 <default_pmm_manager+0x1490>
ffffffffc0204d70:	c1efb0ef          	jal	ra,ffffffffc020018e <cprintf>
#else
    KERNEL_EXECVE(exit);
#endif
    panic("user_main execve failed.\n");
ffffffffc0204d74:	00004617          	auipc	a2,0x4
ffffffffc0204d78:	a7c60613          	addi	a2,a2,-1412 # ffffffffc02087f0 <default_pmm_manager+0x14a0>
ffffffffc0204d7c:	38500593          	li	a1,901
ffffffffc0204d80:	00004517          	auipc	a0,0x4
ffffffffc0204d84:	a9050513          	addi	a0,a0,-1392 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0204d88:	efcfb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204d8c <put_pgdir>:
    return pa2page(PADDR(kva));
ffffffffc0204d8c:	6d14                	ld	a3,24(a0)
put_pgdir(struct mm_struct *mm) {
ffffffffc0204d8e:	1141                	addi	sp,sp,-16
ffffffffc0204d90:	e406                	sd	ra,8(sp)
ffffffffc0204d92:	c02007b7          	lui	a5,0xc0200
ffffffffc0204d96:	04f6e263          	bltu	a3,a5,ffffffffc0204dda <put_pgdir+0x4e>
ffffffffc0204d9a:	000a7797          	auipc	a5,0xa7
ffffffffc0204d9e:	76e78793          	addi	a5,a5,1902 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0204da2:	6388                	ld	a0,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc0204da4:	000a7797          	auipc	a5,0xa7
ffffffffc0204da8:	70478793          	addi	a5,a5,1796 # ffffffffc02ac4a8 <npage>
ffffffffc0204dac:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0204dae:	8e89                	sub	a3,a3,a0
    if (PPN(pa) >= npage) {
ffffffffc0204db0:	82b1                	srli	a3,a3,0xc
ffffffffc0204db2:	04f6f063          	bleu	a5,a3,ffffffffc0204df2 <put_pgdir+0x66>
    return &pages[PPN(pa) - nbase];
ffffffffc0204db6:	00004797          	auipc	a5,0x4
ffffffffc0204dba:	f2278793          	addi	a5,a5,-222 # ffffffffc0208cd8 <nbase>
ffffffffc0204dbe:	639c                	ld	a5,0(a5)
ffffffffc0204dc0:	000a7717          	auipc	a4,0xa7
ffffffffc0204dc4:	75870713          	addi	a4,a4,1880 # ffffffffc02ac518 <pages>
ffffffffc0204dc8:	6308                	ld	a0,0(a4)
}
ffffffffc0204dca:	60a2                	ld	ra,8(sp)
ffffffffc0204dcc:	8e9d                	sub	a3,a3,a5
ffffffffc0204dce:	069a                	slli	a3,a3,0x6
    free_page(kva2page(mm->pgdir));
ffffffffc0204dd0:	4585                	li	a1,1
ffffffffc0204dd2:	9536                	add	a0,a0,a3
}
ffffffffc0204dd4:	0141                	addi	sp,sp,16
    free_page(kva2page(mm->pgdir));
ffffffffc0204dd6:	904fd06f          	j	ffffffffc0201eda <free_pages>
    return pa2page(PADDR(kva));
ffffffffc0204dda:	00002617          	auipc	a2,0x2
ffffffffc0204dde:	5fe60613          	addi	a2,a2,1534 # ffffffffc02073d8 <default_pmm_manager+0x88>
ffffffffc0204de2:	06e00593          	li	a1,110
ffffffffc0204de6:	00002517          	auipc	a0,0x2
ffffffffc0204dea:	5e250513          	addi	a0,a0,1506 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0204dee:	e96fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0204df2:	00002617          	auipc	a2,0x2
ffffffffc0204df6:	60e60613          	addi	a2,a2,1550 # ffffffffc0207400 <default_pmm_manager+0xb0>
ffffffffc0204dfa:	06200593          	li	a1,98
ffffffffc0204dfe:	00002517          	auipc	a0,0x2
ffffffffc0204e02:	5ca50513          	addi	a0,a0,1482 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0204e06:	e7efb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204e0a <setup_pgdir>:
setup_pgdir(struct mm_struct *mm) {
ffffffffc0204e0a:	1101                	addi	sp,sp,-32
ffffffffc0204e0c:	e426                	sd	s1,8(sp)
ffffffffc0204e0e:	84aa                	mv	s1,a0
    if ((page = alloc_page()) == NULL) {
ffffffffc0204e10:	4505                	li	a0,1
setup_pgdir(struct mm_struct *mm) {
ffffffffc0204e12:	ec06                	sd	ra,24(sp)
ffffffffc0204e14:	e822                	sd	s0,16(sp)
    if ((page = alloc_page()) == NULL) {
ffffffffc0204e16:	83cfd0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
ffffffffc0204e1a:	c125                	beqz	a0,ffffffffc0204e7a <setup_pgdir+0x70>
    return page - pages + nbase;
ffffffffc0204e1c:	000a7797          	auipc	a5,0xa7
ffffffffc0204e20:	6fc78793          	addi	a5,a5,1788 # ffffffffc02ac518 <pages>
ffffffffc0204e24:	6394                	ld	a3,0(a5)
ffffffffc0204e26:	00004797          	auipc	a5,0x4
ffffffffc0204e2a:	eb278793          	addi	a5,a5,-334 # ffffffffc0208cd8 <nbase>
ffffffffc0204e2e:	6380                	ld	s0,0(a5)
ffffffffc0204e30:	40d506b3          	sub	a3,a0,a3
    return KADDR(page2pa(page));
ffffffffc0204e34:	000a7717          	auipc	a4,0xa7
ffffffffc0204e38:	67470713          	addi	a4,a4,1652 # ffffffffc02ac4a8 <npage>
    return page - pages + nbase;
ffffffffc0204e3c:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0204e3e:	57fd                	li	a5,-1
ffffffffc0204e40:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0204e42:	96a2                	add	a3,a3,s0
    return KADDR(page2pa(page));
ffffffffc0204e44:	83b1                	srli	a5,a5,0xc
ffffffffc0204e46:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc0204e48:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0204e4a:	02e7fa63          	bleu	a4,a5,ffffffffc0204e7e <setup_pgdir+0x74>
ffffffffc0204e4e:	000a7797          	auipc	a5,0xa7
ffffffffc0204e52:	6ba78793          	addi	a5,a5,1722 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0204e56:	6380                	ld	s0,0(a5)
    memcpy(pgdir, boot_pgdir, PGSIZE);
ffffffffc0204e58:	000a7797          	auipc	a5,0xa7
ffffffffc0204e5c:	64878793          	addi	a5,a5,1608 # ffffffffc02ac4a0 <boot_pgdir>
ffffffffc0204e60:	638c                	ld	a1,0(a5)
ffffffffc0204e62:	9436                	add	s0,s0,a3
ffffffffc0204e64:	6605                	lui	a2,0x1
ffffffffc0204e66:	8522                	mv	a0,s0
ffffffffc0204e68:	798010ef          	jal	ra,ffffffffc0206600 <memcpy>
    return 0;
ffffffffc0204e6c:	4501                	li	a0,0
    mm->pgdir = pgdir;
ffffffffc0204e6e:	ec80                	sd	s0,24(s1)
}
ffffffffc0204e70:	60e2                	ld	ra,24(sp)
ffffffffc0204e72:	6442                	ld	s0,16(sp)
ffffffffc0204e74:	64a2                	ld	s1,8(sp)
ffffffffc0204e76:	6105                	addi	sp,sp,32
ffffffffc0204e78:	8082                	ret
        return -E_NO_MEM;
ffffffffc0204e7a:	5571                	li	a0,-4
ffffffffc0204e7c:	bfd5                	j	ffffffffc0204e70 <setup_pgdir+0x66>
ffffffffc0204e7e:	00002617          	auipc	a2,0x2
ffffffffc0204e82:	52260613          	addi	a2,a2,1314 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0204e86:	06900593          	li	a1,105
ffffffffc0204e8a:	00002517          	auipc	a0,0x2
ffffffffc0204e8e:	53e50513          	addi	a0,a0,1342 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0204e92:	df2fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0204e96 <set_proc_name>:
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204e96:	1101                	addi	sp,sp,-32
ffffffffc0204e98:	e822                	sd	s0,16(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204e9a:	0b450413          	addi	s0,a0,180
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204e9e:	e426                	sd	s1,8(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ea0:	4641                	li	a2,16
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204ea2:	84ae                	mv	s1,a1
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204ea4:	8522                	mv	a0,s0
ffffffffc0204ea6:	4581                	li	a1,0
set_proc_name(struct proc_struct *proc, const char *name) {
ffffffffc0204ea8:	ec06                	sd	ra,24(sp)
    memset(proc->name, 0, sizeof(proc->name));
ffffffffc0204eaa:	744010ef          	jal	ra,ffffffffc02065ee <memset>
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204eae:	8522                	mv	a0,s0
}
ffffffffc0204eb0:	6442                	ld	s0,16(sp)
ffffffffc0204eb2:	60e2                	ld	ra,24(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204eb4:	85a6                	mv	a1,s1
}
ffffffffc0204eb6:	64a2                	ld	s1,8(sp)
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204eb8:	463d                	li	a2,15
}
ffffffffc0204eba:	6105                	addi	sp,sp,32
    return memcpy(proc->name, name, PROC_NAME_LEN);
ffffffffc0204ebc:	7440106f          	j	ffffffffc0206600 <memcpy>

ffffffffc0204ec0 <proc_run>:
proc_run(struct proc_struct *proc) {
ffffffffc0204ec0:	1101                	addi	sp,sp,-32
    if (proc != current) {
ffffffffc0204ec2:	000a7797          	auipc	a5,0xa7
ffffffffc0204ec6:	5fe78793          	addi	a5,a5,1534 # ffffffffc02ac4c0 <current>
proc_run(struct proc_struct *proc) {
ffffffffc0204eca:	e426                	sd	s1,8(sp)
    if (proc != current) {
ffffffffc0204ecc:	6384                	ld	s1,0(a5)
proc_run(struct proc_struct *proc) {
ffffffffc0204ece:	ec06                	sd	ra,24(sp)
ffffffffc0204ed0:	e822                	sd	s0,16(sp)
ffffffffc0204ed2:	e04a                	sd	s2,0(sp)
    if (proc != current) {
ffffffffc0204ed4:	02a48b63          	beq	s1,a0,ffffffffc0204f0a <proc_run+0x4a>
ffffffffc0204ed8:	842a                	mv	s0,a0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204eda:	100027f3          	csrr	a5,sstatus
ffffffffc0204ede:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0204ee0:	4901                	li	s2,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0204ee2:	e3a9                	bnez	a5,ffffffffc0204f24 <proc_run+0x64>

#define barrier() __asm__ __volatile__ ("fence" ::: "memory")

static inline void
lcr3(unsigned long cr3) {
    write_csr(satp, 0x8000000000000000 | (cr3 >> RISCV_PGSHIFT));
ffffffffc0204ee4:	745c                	ld	a5,168(s0)
            current=proc;
ffffffffc0204ee6:	000a7717          	auipc	a4,0xa7
ffffffffc0204eea:	5c873d23          	sd	s0,1498(a4) # ffffffffc02ac4c0 <current>
ffffffffc0204eee:	577d                	li	a4,-1
ffffffffc0204ef0:	177e                	slli	a4,a4,0x3f
ffffffffc0204ef2:	83b1                	srli	a5,a5,0xc
ffffffffc0204ef4:	8fd9                	or	a5,a5,a4
ffffffffc0204ef6:	18079073          	csrw	satp,a5
            switch_to(&(pre->context),&(proc->context));
ffffffffc0204efa:	03040593          	addi	a1,s0,48
ffffffffc0204efe:	03048513          	addi	a0,s1,48
ffffffffc0204f02:	7e3000ef          	jal	ra,ffffffffc0205ee4 <switch_to>
    if (flag) {
ffffffffc0204f06:	00091863          	bnez	s2,ffffffffc0204f16 <proc_run+0x56>
}
ffffffffc0204f0a:	60e2                	ld	ra,24(sp)
ffffffffc0204f0c:	6442                	ld	s0,16(sp)
ffffffffc0204f0e:	64a2                	ld	s1,8(sp)
ffffffffc0204f10:	6902                	ld	s2,0(sp)
ffffffffc0204f12:	6105                	addi	sp,sp,32
ffffffffc0204f14:	8082                	ret
ffffffffc0204f16:	6442                	ld	s0,16(sp)
ffffffffc0204f18:	60e2                	ld	ra,24(sp)
ffffffffc0204f1a:	64a2                	ld	s1,8(sp)
ffffffffc0204f1c:	6902                	ld	s2,0(sp)
ffffffffc0204f1e:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0204f20:	f34fb06f          	j	ffffffffc0200654 <intr_enable>
        intr_disable();
ffffffffc0204f24:	f36fb0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc0204f28:	4905                	li	s2,1
ffffffffc0204f2a:	bf6d                	j	ffffffffc0204ee4 <proc_run+0x24>

ffffffffc0204f2c <find_proc>:
    if (0 < pid && pid < MAX_PID) {
ffffffffc0204f2c:	0005071b          	sext.w	a4,a0
ffffffffc0204f30:	6789                	lui	a5,0x2
ffffffffc0204f32:	fff7069b          	addiw	a3,a4,-1
ffffffffc0204f36:	17f9                	addi	a5,a5,-2
ffffffffc0204f38:	04d7e063          	bltu	a5,a3,ffffffffc0204f78 <find_proc+0x4c>
find_proc(int pid) {
ffffffffc0204f3c:	1141                	addi	sp,sp,-16
ffffffffc0204f3e:	e022                	sd	s0,0(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f40:	45a9                	li	a1,10
ffffffffc0204f42:	842a                	mv	s0,a0
ffffffffc0204f44:	853a                	mv	a0,a4
find_proc(int pid) {
ffffffffc0204f46:	e406                	sd	ra,8(sp)
        list_entry_t *list = hash_list + pid_hashfn(pid), *le = list;
ffffffffc0204f48:	1f8010ef          	jal	ra,ffffffffc0206140 <hash32>
ffffffffc0204f4c:	02051693          	slli	a3,a0,0x20
ffffffffc0204f50:	82f1                	srli	a3,a3,0x1c
ffffffffc0204f52:	000a3517          	auipc	a0,0xa3
ffffffffc0204f56:	53650513          	addi	a0,a0,1334 # ffffffffc02a8488 <hash_list>
ffffffffc0204f5a:	96aa                	add	a3,a3,a0
ffffffffc0204f5c:	87b6                	mv	a5,a3
        while ((le = list_next(le)) != list) {
ffffffffc0204f5e:	a029                	j	ffffffffc0204f68 <find_proc+0x3c>
            if (proc->pid == pid) {
ffffffffc0204f60:	f2c7a703          	lw	a4,-212(a5) # 1f2c <_binary_obj___user_faultread_out_size-0x7654>
ffffffffc0204f64:	00870c63          	beq	a4,s0,ffffffffc0204f7c <find_proc+0x50>
ffffffffc0204f68:	679c                	ld	a5,8(a5)
        while ((le = list_next(le)) != list) {
ffffffffc0204f6a:	fef69be3          	bne	a3,a5,ffffffffc0204f60 <find_proc+0x34>
}
ffffffffc0204f6e:	60a2                	ld	ra,8(sp)
ffffffffc0204f70:	6402                	ld	s0,0(sp)
    return NULL;
ffffffffc0204f72:	4501                	li	a0,0
}
ffffffffc0204f74:	0141                	addi	sp,sp,16
ffffffffc0204f76:	8082                	ret
    return NULL;
ffffffffc0204f78:	4501                	li	a0,0
}
ffffffffc0204f7a:	8082                	ret
ffffffffc0204f7c:	60a2                	ld	ra,8(sp)
ffffffffc0204f7e:	6402                	ld	s0,0(sp)
            struct proc_struct *proc = le2proc(le, hash_link);
ffffffffc0204f80:	f2878513          	addi	a0,a5,-216
}
ffffffffc0204f84:	0141                	addi	sp,sp,16
ffffffffc0204f86:	8082                	ret

ffffffffc0204f88 <do_fork>:
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204f88:	715d                	addi	sp,sp,-80
ffffffffc0204f8a:	f84a                	sd	s2,48(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204f8c:	000a7917          	auipc	s2,0xa7
ffffffffc0204f90:	54c90913          	addi	s2,s2,1356 # ffffffffc02ac4d8 <nr_process>
ffffffffc0204f94:	00092703          	lw	a4,0(s2)
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe *tf) {
ffffffffc0204f98:	e486                	sd	ra,72(sp)
ffffffffc0204f9a:	e0a2                	sd	s0,64(sp)
ffffffffc0204f9c:	fc26                	sd	s1,56(sp)
ffffffffc0204f9e:	f44e                	sd	s3,40(sp)
ffffffffc0204fa0:	f052                	sd	s4,32(sp)
ffffffffc0204fa2:	ec56                	sd	s5,24(sp)
ffffffffc0204fa4:	e85a                	sd	s6,16(sp)
ffffffffc0204fa6:	e45e                	sd	s7,8(sp)
ffffffffc0204fa8:	e062                	sd	s8,0(sp)
    if (nr_process >= MAX_PROCESS) {
ffffffffc0204faa:	6785                	lui	a5,0x1
ffffffffc0204fac:	32f75563          	ble	a5,a4,ffffffffc02052d6 <do_fork+0x34e>
ffffffffc0204fb0:	8aaa                	mv	s5,a0
ffffffffc0204fb2:	89ae                	mv	s3,a1
ffffffffc0204fb4:	84b2                	mv	s1,a2
   if((proc=alloc_proc())==NULL)
ffffffffc0204fb6:	cd1ff0ef          	jal	ra,ffffffffc0204c86 <alloc_proc>
ffffffffc0204fba:	842a                	mv	s0,a0
ffffffffc0204fbc:	2a050a63          	beqz	a0,ffffffffc0205270 <do_fork+0x2e8>
    proc->parent=current;
ffffffffc0204fc0:	000a7a17          	auipc	s4,0xa7
ffffffffc0204fc4:	500a0a13          	addi	s4,s4,1280 # ffffffffc02ac4c0 <current>
ffffffffc0204fc8:	000a3783          	ld	a5,0(s4)
    assert(current->wait_state==0);
ffffffffc0204fcc:	0ec7a703          	lw	a4,236(a5) # 10ec <_binary_obj___user_faultread_out_size-0x8494>
    proc->parent=current;
ffffffffc0204fd0:	f11c                	sd	a5,32(a0)
    assert(current->wait_state==0);
ffffffffc0204fd2:	30071463          	bnez	a4,ffffffffc02052da <do_fork+0x352>
    struct Page *page = alloc_pages(KSTACKPAGE);
ffffffffc0204fd6:	4509                	li	a0,2
ffffffffc0204fd8:	e7bfc0ef          	jal	ra,ffffffffc0201e52 <alloc_pages>
    if (page != NULL) {
ffffffffc0204fdc:	2a050863          	beqz	a0,ffffffffc020528c <do_fork+0x304>
    return page - pages + nbase;
ffffffffc0204fe0:	000a7797          	auipc	a5,0xa7
ffffffffc0204fe4:	53878793          	addi	a5,a5,1336 # ffffffffc02ac518 <pages>
ffffffffc0204fe8:	6394                	ld	a3,0(a5)
ffffffffc0204fea:	00004797          	auipc	a5,0x4
ffffffffc0204fee:	cee78793          	addi	a5,a5,-786 # ffffffffc0208cd8 <nbase>
    return KADDR(page2pa(page));
ffffffffc0204ff2:	000a7717          	auipc	a4,0xa7
ffffffffc0204ff6:	4b670713          	addi	a4,a4,1206 # ffffffffc02ac4a8 <npage>
    return page - pages + nbase;
ffffffffc0204ffa:	40d506b3          	sub	a3,a0,a3
ffffffffc0204ffe:	6388                	ld	a0,0(a5)
ffffffffc0205000:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205002:	57fd                	li	a5,-1
ffffffffc0205004:	6318                	ld	a4,0(a4)
    return page - pages + nbase;
ffffffffc0205006:	96aa                	add	a3,a3,a0
    return KADDR(page2pa(page));
ffffffffc0205008:	83b1                	srli	a5,a5,0xc
ffffffffc020500a:	8ff5                	and	a5,a5,a3
    return page2ppn(page) << PGSHIFT;
ffffffffc020500c:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc020500e:	2ee7f663          	bleu	a4,a5,ffffffffc02052fa <do_fork+0x372>
ffffffffc0205012:	000a7b17          	auipc	s6,0xa7
ffffffffc0205016:	4f6b0b13          	addi	s6,s6,1270 # ffffffffc02ac508 <va_pa_offset>
    struct mm_struct *mm, *oldmm = current->mm;
ffffffffc020501a:	000a3703          	ld	a4,0(s4)
ffffffffc020501e:	000b3783          	ld	a5,0(s6)
ffffffffc0205022:	02873a03          	ld	s4,40(a4)
ffffffffc0205026:	96be                	add	a3,a3,a5
        proc->kstack = (uintptr_t)page2kva(page);
ffffffffc0205028:	e814                	sd	a3,16(s0)
    if (oldmm == NULL) {
ffffffffc020502a:	020a0863          	beqz	s4,ffffffffc020505a <do_fork+0xd2>
    if (clone_flags & CLONE_VM) {
ffffffffc020502e:	100afa93          	andi	s5,s5,256
ffffffffc0205032:	1e0a8163          	beqz	s5,ffffffffc0205214 <do_fork+0x28c>
}

static inline int
mm_count_inc(struct mm_struct *mm) {
    mm->mm_count += 1;
ffffffffc0205036:	030a2703          	lw	a4,48(s4)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020503a:	018a3783          	ld	a5,24(s4)
ffffffffc020503e:	c02006b7          	lui	a3,0xc0200
ffffffffc0205042:	2705                	addiw	a4,a4,1
ffffffffc0205044:	02ea2823          	sw	a4,48(s4)
    proc->mm = mm;
ffffffffc0205048:	03443423          	sd	s4,40(s0)
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc020504c:	2cd7e363          	bltu	a5,a3,ffffffffc0205312 <do_fork+0x38a>
ffffffffc0205050:	000b3703          	ld	a4,0(s6)
ffffffffc0205054:	6814                	ld	a3,16(s0)
ffffffffc0205056:	8f99                	sub	a5,a5,a4
ffffffffc0205058:	f45c                	sd	a5,168(s0)
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc020505a:	6789                	lui	a5,0x2
ffffffffc020505c:	ee078793          	addi	a5,a5,-288 # 1ee0 <_binary_obj___user_faultread_out_size-0x76a0>
ffffffffc0205060:	96be                	add	a3,a3,a5
    *(proc->tf) = *tf;
ffffffffc0205062:	8626                	mv	a2,s1
    proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE) - 1;
ffffffffc0205064:	f054                	sd	a3,160(s0)
    *(proc->tf) = *tf;
ffffffffc0205066:	87b6                	mv	a5,a3
ffffffffc0205068:	12048893          	addi	a7,s1,288
ffffffffc020506c:	00063803          	ld	a6,0(a2)
ffffffffc0205070:	6608                	ld	a0,8(a2)
ffffffffc0205072:	6a0c                	ld	a1,16(a2)
ffffffffc0205074:	6e18                	ld	a4,24(a2)
ffffffffc0205076:	0107b023          	sd	a6,0(a5)
ffffffffc020507a:	e788                	sd	a0,8(a5)
ffffffffc020507c:	eb8c                	sd	a1,16(a5)
ffffffffc020507e:	ef98                	sd	a4,24(a5)
ffffffffc0205080:	02060613          	addi	a2,a2,32
ffffffffc0205084:	02078793          	addi	a5,a5,32
ffffffffc0205088:	ff1612e3          	bne	a2,a7,ffffffffc020506c <do_fork+0xe4>
    proc->tf->gpr.a0 = 0;
ffffffffc020508c:	0406b823          	sd	zero,80(a3) # ffffffffc0200050 <kern_init+0x1a>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc0205090:	12098b63          	beqz	s3,ffffffffc02051c6 <do_fork+0x23e>
ffffffffc0205094:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc0205098:	00000797          	auipc	a5,0x0
ffffffffc020509c:	c6278793          	addi	a5,a5,-926 # ffffffffc0204cfa <forkret>
ffffffffc02050a0:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02050a2:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02050a4:	100027f3          	csrr	a5,sstatus
ffffffffc02050a8:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02050aa:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02050ac:	12079c63          	bnez	a5,ffffffffc02051e4 <do_fork+0x25c>
    if (++ last_pid >= MAX_PID) {
ffffffffc02050b0:	0009c797          	auipc	a5,0x9c
ffffffffc02050b4:	fd078793          	addi	a5,a5,-48 # ffffffffc02a1080 <last_pid.1691>
ffffffffc02050b8:	439c                	lw	a5,0(a5)
ffffffffc02050ba:	6709                	lui	a4,0x2
ffffffffc02050bc:	0017851b          	addiw	a0,a5,1
ffffffffc02050c0:	0009c697          	auipc	a3,0x9c
ffffffffc02050c4:	fca6a023          	sw	a0,-64(a3) # ffffffffc02a1080 <last_pid.1691>
ffffffffc02050c8:	12e55f63          	ble	a4,a0,ffffffffc0205206 <do_fork+0x27e>
    if (last_pid >= next_safe) {
ffffffffc02050cc:	0009c797          	auipc	a5,0x9c
ffffffffc02050d0:	fb878793          	addi	a5,a5,-72 # ffffffffc02a1084 <next_safe.1690>
ffffffffc02050d4:	439c                	lw	a5,0(a5)
ffffffffc02050d6:	000a7497          	auipc	s1,0xa7
ffffffffc02050da:	52a48493          	addi	s1,s1,1322 # ffffffffc02ac600 <proc_list>
ffffffffc02050de:	06f54063          	blt	a0,a5,ffffffffc020513e <do_fork+0x1b6>
        next_safe = MAX_PID;
ffffffffc02050e2:	6789                	lui	a5,0x2
ffffffffc02050e4:	0009c717          	auipc	a4,0x9c
ffffffffc02050e8:	faf72023          	sw	a5,-96(a4) # ffffffffc02a1084 <next_safe.1690>
ffffffffc02050ec:	4581                	li	a1,0
ffffffffc02050ee:	87aa                	mv	a5,a0
ffffffffc02050f0:	000a7497          	auipc	s1,0xa7
ffffffffc02050f4:	51048493          	addi	s1,s1,1296 # ffffffffc02ac600 <proc_list>
    repeat:
ffffffffc02050f8:	6889                	lui	a7,0x2
ffffffffc02050fa:	882e                	mv	a6,a1
ffffffffc02050fc:	6609                	lui	a2,0x2
        le = list;
ffffffffc02050fe:	000a7697          	auipc	a3,0xa7
ffffffffc0205102:	50268693          	addi	a3,a3,1282 # ffffffffc02ac600 <proc_list>
ffffffffc0205106:	6694                	ld	a3,8(a3)
        while ((le = list_next(le)) != list) {
ffffffffc0205108:	00968f63          	beq	a3,s1,ffffffffc0205126 <do_fork+0x19e>
            if (proc->pid == last_pid) {
ffffffffc020510c:	f3c6a703          	lw	a4,-196(a3)
ffffffffc0205110:	0ae78663          	beq	a5,a4,ffffffffc02051bc <do_fork+0x234>
            else if (proc->pid > last_pid && next_safe > proc->pid) {
ffffffffc0205114:	fee7d9e3          	ble	a4,a5,ffffffffc0205106 <do_fork+0x17e>
ffffffffc0205118:	fec757e3          	ble	a2,a4,ffffffffc0205106 <do_fork+0x17e>
ffffffffc020511c:	6694                	ld	a3,8(a3)
ffffffffc020511e:	863a                	mv	a2,a4
ffffffffc0205120:	4805                	li	a6,1
        while ((le = list_next(le)) != list) {
ffffffffc0205122:	fe9695e3          	bne	a3,s1,ffffffffc020510c <do_fork+0x184>
ffffffffc0205126:	c591                	beqz	a1,ffffffffc0205132 <do_fork+0x1aa>
ffffffffc0205128:	0009c717          	auipc	a4,0x9c
ffffffffc020512c:	f4f72c23          	sw	a5,-168(a4) # ffffffffc02a1080 <last_pid.1691>
ffffffffc0205130:	853e                	mv	a0,a5
ffffffffc0205132:	00080663          	beqz	a6,ffffffffc020513e <do_fork+0x1b6>
ffffffffc0205136:	0009c797          	auipc	a5,0x9c
ffffffffc020513a:	f4c7a723          	sw	a2,-178(a5) # ffffffffc02a1084 <next_safe.1690>
        proc->pid=get_pid();
ffffffffc020513e:	c048                	sw	a0,4(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc0205140:	45a9                	li	a1,10
ffffffffc0205142:	2501                	sext.w	a0,a0
ffffffffc0205144:	7fd000ef          	jal	ra,ffffffffc0206140 <hash32>
ffffffffc0205148:	1502                	slli	a0,a0,0x20
ffffffffc020514a:	000a3797          	auipc	a5,0xa3
ffffffffc020514e:	33e78793          	addi	a5,a5,830 # ffffffffc02a8488 <hash_list>
ffffffffc0205152:	8171                	srli	a0,a0,0x1c
ffffffffc0205154:	953e                	add	a0,a0,a5
    __list_add(elm, listelm, listelm->next);
ffffffffc0205156:	650c                	ld	a1,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205158:	7014                	ld	a3,32(s0)
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
ffffffffc020515a:	0d840793          	addi	a5,s0,216
    prev->next = next->prev = elm;
ffffffffc020515e:	e19c                	sd	a5,0(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc0205160:	6490                	ld	a2,8(s1)
    prev->next = next->prev = elm;
ffffffffc0205162:	e51c                	sd	a5,8(a0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205164:	7af8                	ld	a4,240(a3)
    list_add(&proc_list, &(proc->list_link));
ffffffffc0205166:	0c840793          	addi	a5,s0,200
    elm->next = next;
ffffffffc020516a:	f06c                	sd	a1,224(s0)
    elm->prev = prev;
ffffffffc020516c:	ec68                	sd	a0,216(s0)
    prev->next = next->prev = elm;
ffffffffc020516e:	e21c                	sd	a5,0(a2)
ffffffffc0205170:	000a7597          	auipc	a1,0xa7
ffffffffc0205174:	48f5bc23          	sd	a5,1176(a1) # ffffffffc02ac608 <proc_list+0x8>
    elm->next = next;
ffffffffc0205178:	e870                	sd	a2,208(s0)
    elm->prev = prev;
ffffffffc020517a:	e464                	sd	s1,200(s0)
    proc->yptr = NULL;
ffffffffc020517c:	0e043c23          	sd	zero,248(s0)
    if ((proc->optr = proc->parent->cptr) != NULL) {
ffffffffc0205180:	10e43023          	sd	a4,256(s0)
ffffffffc0205184:	c311                	beqz	a4,ffffffffc0205188 <do_fork+0x200>
        proc->optr->yptr = proc;
ffffffffc0205186:	ff60                	sd	s0,248(a4)
    nr_process ++;
ffffffffc0205188:	00092783          	lw	a5,0(s2)
    proc->parent->cptr = proc;
ffffffffc020518c:	fae0                	sd	s0,240(a3)
    nr_process ++;
ffffffffc020518e:	2785                	addiw	a5,a5,1
ffffffffc0205190:	000a7717          	auipc	a4,0xa7
ffffffffc0205194:	34f72423          	sw	a5,840(a4) # ffffffffc02ac4d8 <nr_process>
    if (flag) {
ffffffffc0205198:	0c099e63          	bnez	s3,ffffffffc0205274 <do_fork+0x2ec>
    wakeup_proc(proc);
ffffffffc020519c:	8522                	mv	a0,s0
ffffffffc020519e:	5b1000ef          	jal	ra,ffffffffc0205f4e <wakeup_proc>
    ret=proc->pid;
ffffffffc02051a2:	4048                	lw	a0,4(s0)
}
ffffffffc02051a4:	60a6                	ld	ra,72(sp)
ffffffffc02051a6:	6406                	ld	s0,64(sp)
ffffffffc02051a8:	74e2                	ld	s1,56(sp)
ffffffffc02051aa:	7942                	ld	s2,48(sp)
ffffffffc02051ac:	79a2                	ld	s3,40(sp)
ffffffffc02051ae:	7a02                	ld	s4,32(sp)
ffffffffc02051b0:	6ae2                	ld	s5,24(sp)
ffffffffc02051b2:	6b42                	ld	s6,16(sp)
ffffffffc02051b4:	6ba2                	ld	s7,8(sp)
ffffffffc02051b6:	6c02                	ld	s8,0(sp)
ffffffffc02051b8:	6161                	addi	sp,sp,80
ffffffffc02051ba:	8082                	ret
                if (++ last_pid >= next_safe) {
ffffffffc02051bc:	2785                	addiw	a5,a5,1
ffffffffc02051be:	0ac7de63          	ble	a2,a5,ffffffffc020527a <do_fork+0x2f2>
ffffffffc02051c2:	4585                	li	a1,1
ffffffffc02051c4:	b789                	j	ffffffffc0205106 <do_fork+0x17e>
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
ffffffffc02051c6:	89b6                	mv	s3,a3
ffffffffc02051c8:	0136b823          	sd	s3,16(a3)
    proc->context.ra = (uintptr_t)forkret;
ffffffffc02051cc:	00000797          	auipc	a5,0x0
ffffffffc02051d0:	b2e78793          	addi	a5,a5,-1234 # ffffffffc0204cfa <forkret>
ffffffffc02051d4:	f81c                	sd	a5,48(s0)
    proc->context.sp = (uintptr_t)(proc->tf);
ffffffffc02051d6:	fc14                	sd	a3,56(s0)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02051d8:	100027f3          	csrr	a5,sstatus
ffffffffc02051dc:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02051de:	4981                	li	s3,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02051e0:	ec0788e3          	beqz	a5,ffffffffc02050b0 <do_fork+0x128>
        intr_disable();
ffffffffc02051e4:	c76fb0ef          	jal	ra,ffffffffc020065a <intr_disable>
    if (++ last_pid >= MAX_PID) {
ffffffffc02051e8:	0009c797          	auipc	a5,0x9c
ffffffffc02051ec:	e9878793          	addi	a5,a5,-360 # ffffffffc02a1080 <last_pid.1691>
ffffffffc02051f0:	439c                	lw	a5,0(a5)
ffffffffc02051f2:	6709                	lui	a4,0x2
        return 1;
ffffffffc02051f4:	4985                	li	s3,1
ffffffffc02051f6:	0017851b          	addiw	a0,a5,1
ffffffffc02051fa:	0009c697          	auipc	a3,0x9c
ffffffffc02051fe:	e8a6a323          	sw	a0,-378(a3) # ffffffffc02a1080 <last_pid.1691>
ffffffffc0205202:	ece545e3          	blt	a0,a4,ffffffffc02050cc <do_fork+0x144>
        last_pid = 1;
ffffffffc0205206:	4785                	li	a5,1
ffffffffc0205208:	0009c717          	auipc	a4,0x9c
ffffffffc020520c:	e6f72c23          	sw	a5,-392(a4) # ffffffffc02a1080 <last_pid.1691>
ffffffffc0205210:	4505                	li	a0,1
ffffffffc0205212:	bdc1                	j	ffffffffc02050e2 <do_fork+0x15a>
    if ((mm = mm_create()) == NULL) {
ffffffffc0205214:	ea7fe0ef          	jal	ra,ffffffffc02040ba <mm_create>
ffffffffc0205218:	8c2a                	mv	s8,a0
ffffffffc020521a:	c921                	beqz	a0,ffffffffc020526a <do_fork+0x2e2>
    if (setup_pgdir(mm) != 0) {
ffffffffc020521c:	befff0ef          	jal	ra,ffffffffc0204e0a <setup_pgdir>
ffffffffc0205220:	e135                	bnez	a0,ffffffffc0205284 <do_fork+0x2fc>
}
//mm里有一个mm_lock,若该位为0，则表示没有被锁住，加锁后返回，若该位为1，则表示该mm被锁住，调度其它线程执行，等待该位为0
static inline void
lock_mm(struct mm_struct *mm) {
    if (mm != NULL) {
        lock(&(mm->mm_lock));
ffffffffc0205222:	038a0a93          	addi	s5,s4,56
 * test_and_set_bit - Atomically set a bit and return its old value
 * @nr:     the bit to set
 * @addr:   the address to count from
 * */
static inline bool test_and_set_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc0205226:	4785                	li	a5,1
ffffffffc0205228:	40fab7af          	amoor.d	a5,a5,(s5)
ffffffffc020522c:	8b85                	andi	a5,a5,1
ffffffffc020522e:	4b85                	li	s7,1
    return !test_and_set_bit(0, lock);
}

static inline void
lock(lock_t *lock) {
    while (!try_lock(lock)) {
ffffffffc0205230:	c799                	beqz	a5,ffffffffc020523e <do_fork+0x2b6>
        schedule();
ffffffffc0205232:	599000ef          	jal	ra,ffffffffc0205fca <schedule>
ffffffffc0205236:	417ab7af          	amoor.d	a5,s7,(s5)
ffffffffc020523a:	8b85                	andi	a5,a5,1
    while (!try_lock(lock)) {
ffffffffc020523c:	fbfd                	bnez	a5,ffffffffc0205232 <do_fork+0x2aa>
        ret = dup_mmap(mm, oldmm);
ffffffffc020523e:	85d2                	mv	a1,s4
ffffffffc0205240:	8562                	mv	a0,s8
ffffffffc0205242:	902ff0ef          	jal	ra,ffffffffc0204344 <dup_mmap>
 * test_and_clear_bit - Atomically clear a bit and return its old value
 * @nr:     the bit to clear
 * @addr:   the address to count from
 * */
static inline bool test_and_clear_bit(int nr, volatile void *addr) {
    return __test_and_op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0205246:	57f9                	li	a5,-2
ffffffffc0205248:	60fab7af          	amoand.d	a5,a5,(s5)
ffffffffc020524c:	8b85                	andi	a5,a5,1
    }
}

static inline void
unlock(lock_t *lock) {
    if (!test_and_clear_bit(0, lock)) {
ffffffffc020524e:	0c078f63          	beqz	a5,ffffffffc020532c <do_fork+0x3a4>
    if (ret != 0) {
ffffffffc0205252:	8a62                	mv	s4,s8
ffffffffc0205254:	de0501e3          	beqz	a0,ffffffffc0205036 <do_fork+0xae>
    exit_mmap(mm);
ffffffffc0205258:	8562                	mv	a0,s8
ffffffffc020525a:	986ff0ef          	jal	ra,ffffffffc02043e0 <exit_mmap>
    put_pgdir(mm);
ffffffffc020525e:	8562                	mv	a0,s8
ffffffffc0205260:	b2dff0ef          	jal	ra,ffffffffc0204d8c <put_pgdir>
    mm_destroy(mm);
ffffffffc0205264:	8562                	mv	a0,s8
ffffffffc0205266:	fdbfe0ef          	jal	ra,ffffffffc0204240 <mm_destroy>
    kfree(proc);
ffffffffc020526a:	8522                	mv	a0,s0
ffffffffc020526c:	aa7fc0ef          	jal	ra,ffffffffc0201d12 <kfree>
    ret = -E_NO_MEM;
ffffffffc0205270:	5571                	li	a0,-4
    return ret;
ffffffffc0205272:	bf0d                	j	ffffffffc02051a4 <do_fork+0x21c>
        intr_enable();
ffffffffc0205274:	be0fb0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc0205278:	b715                	j	ffffffffc020519c <do_fork+0x214>
                    if (last_pid >= MAX_PID) {
ffffffffc020527a:	0117c363          	blt	a5,a7,ffffffffc0205280 <do_fork+0x2f8>
                        last_pid = 1;
ffffffffc020527e:	4785                	li	a5,1
                    goto repeat;
ffffffffc0205280:	4585                	li	a1,1
ffffffffc0205282:	bda5                	j	ffffffffc02050fa <do_fork+0x172>
    mm_destroy(mm);
ffffffffc0205284:	8562                	mv	a0,s8
ffffffffc0205286:	fbbfe0ef          	jal	ra,ffffffffc0204240 <mm_destroy>
ffffffffc020528a:	b7c5                	j	ffffffffc020526a <do_fork+0x2e2>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc020528c:	6814                	ld	a3,16(s0)
    return pa2page(PADDR(kva));
ffffffffc020528e:	c02007b7          	lui	a5,0xc0200
ffffffffc0205292:	0cf6e563          	bltu	a3,a5,ffffffffc020535c <do_fork+0x3d4>
ffffffffc0205296:	000a7797          	auipc	a5,0xa7
ffffffffc020529a:	27278793          	addi	a5,a5,626 # ffffffffc02ac508 <va_pa_offset>
ffffffffc020529e:	639c                	ld	a5,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc02052a0:	000a7717          	auipc	a4,0xa7
ffffffffc02052a4:	20870713          	addi	a4,a4,520 # ffffffffc02ac4a8 <npage>
ffffffffc02052a8:	6318                	ld	a4,0(a4)
    return pa2page(PADDR(kva));
ffffffffc02052aa:	40f687b3          	sub	a5,a3,a5
    if (PPN(pa) >= npage) {
ffffffffc02052ae:	83b1                	srli	a5,a5,0xc
ffffffffc02052b0:	08e7fa63          	bleu	a4,a5,ffffffffc0205344 <do_fork+0x3bc>
    return &pages[PPN(pa) - nbase];
ffffffffc02052b4:	00004717          	auipc	a4,0x4
ffffffffc02052b8:	a2470713          	addi	a4,a4,-1500 # ffffffffc0208cd8 <nbase>
ffffffffc02052bc:	6318                	ld	a4,0(a4)
ffffffffc02052be:	000a7697          	auipc	a3,0xa7
ffffffffc02052c2:	25a68693          	addi	a3,a3,602 # ffffffffc02ac518 <pages>
ffffffffc02052c6:	6288                	ld	a0,0(a3)
ffffffffc02052c8:	8f99                	sub	a5,a5,a4
ffffffffc02052ca:	079a                	slli	a5,a5,0x6
ffffffffc02052cc:	4589                	li	a1,2
ffffffffc02052ce:	953e                	add	a0,a0,a5
ffffffffc02052d0:	c0bfc0ef          	jal	ra,ffffffffc0201eda <free_pages>
ffffffffc02052d4:	bf59                	j	ffffffffc020526a <do_fork+0x2e2>
    int ret = -E_NO_FREE_PROC;
ffffffffc02052d6:	556d                	li	a0,-5
ffffffffc02052d8:	b5f1                	j	ffffffffc02051a4 <do_fork+0x21c>
    assert(current->wait_state==0);
ffffffffc02052da:	00003697          	auipc	a3,0x3
ffffffffc02052de:	2ae68693          	addi	a3,a3,686 # ffffffffc0208588 <default_pmm_manager+0x1238>
ffffffffc02052e2:	00002617          	auipc	a2,0x2
ffffffffc02052e6:	92660613          	addi	a2,a2,-1754 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02052ea:	1c200593          	li	a1,450
ffffffffc02052ee:	00003517          	auipc	a0,0x3
ffffffffc02052f2:	52250513          	addi	a0,a0,1314 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc02052f6:	98efb0ef          	jal	ra,ffffffffc0200484 <__panic>
    return KADDR(page2pa(page));
ffffffffc02052fa:	00002617          	auipc	a2,0x2
ffffffffc02052fe:	0a660613          	addi	a2,a2,166 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0205302:	06900593          	li	a1,105
ffffffffc0205306:	00002517          	auipc	a0,0x2
ffffffffc020530a:	0c250513          	addi	a0,a0,194 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc020530e:	976fb0ef          	jal	ra,ffffffffc0200484 <__panic>
    proc->cr3 = PADDR(mm->pgdir);
ffffffffc0205312:	86be                	mv	a3,a5
ffffffffc0205314:	00002617          	auipc	a2,0x2
ffffffffc0205318:	0c460613          	addi	a2,a2,196 # ffffffffc02073d8 <default_pmm_manager+0x88>
ffffffffc020531c:	17100593          	li	a1,369
ffffffffc0205320:	00003517          	auipc	a0,0x3
ffffffffc0205324:	4f050513          	addi	a0,a0,1264 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205328:	95cfb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("Unlock failed.\n");
ffffffffc020532c:	00003617          	auipc	a2,0x3
ffffffffc0205330:	27460613          	addi	a2,a2,628 # ffffffffc02085a0 <default_pmm_manager+0x1250>
ffffffffc0205334:	03100593          	li	a1,49
ffffffffc0205338:	00003517          	auipc	a0,0x3
ffffffffc020533c:	27850513          	addi	a0,a0,632 # ffffffffc02085b0 <default_pmm_manager+0x1260>
ffffffffc0205340:	944fb0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc0205344:	00002617          	auipc	a2,0x2
ffffffffc0205348:	0bc60613          	addi	a2,a2,188 # ffffffffc0207400 <default_pmm_manager+0xb0>
ffffffffc020534c:	06200593          	li	a1,98
ffffffffc0205350:	00002517          	auipc	a0,0x2
ffffffffc0205354:	07850513          	addi	a0,a0,120 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0205358:	92cfb0ef          	jal	ra,ffffffffc0200484 <__panic>
    return pa2page(PADDR(kva));
ffffffffc020535c:	00002617          	auipc	a2,0x2
ffffffffc0205360:	07c60613          	addi	a2,a2,124 # ffffffffc02073d8 <default_pmm_manager+0x88>
ffffffffc0205364:	06e00593          	li	a1,110
ffffffffc0205368:	00002517          	auipc	a0,0x2
ffffffffc020536c:	06050513          	addi	a0,a0,96 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0205370:	914fb0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205374 <kernel_thread>:
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc0205374:	7129                	addi	sp,sp,-320
ffffffffc0205376:	fa22                	sd	s0,304(sp)
ffffffffc0205378:	f626                	sd	s1,296(sp)
ffffffffc020537a:	f24a                	sd	s2,288(sp)
ffffffffc020537c:	84ae                	mv	s1,a1
ffffffffc020537e:	892a                	mv	s2,a0
ffffffffc0205380:	8432                	mv	s0,a2
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc0205382:	4581                	li	a1,0
ffffffffc0205384:	12000613          	li	a2,288
ffffffffc0205388:	850a                	mv	a0,sp
kernel_thread(int (*fn)(void *), void *arg, uint32_t clone_flags) {
ffffffffc020538a:	fe06                	sd	ra,312(sp)
    memset(&tf, 0, sizeof(struct trapframe));
ffffffffc020538c:	262010ef          	jal	ra,ffffffffc02065ee <memset>
    tf.gpr.s0 = (uintptr_t)fn;
ffffffffc0205390:	e0ca                	sd	s2,64(sp)
    tf.gpr.s1 = (uintptr_t)arg;
ffffffffc0205392:	e4a6                	sd	s1,72(sp)
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;
ffffffffc0205394:	100027f3          	csrr	a5,sstatus
ffffffffc0205398:	edd7f793          	andi	a5,a5,-291
ffffffffc020539c:	1207e793          	ori	a5,a5,288
ffffffffc02053a0:	e23e                	sd	a5,256(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02053a2:	860a                	mv	a2,sp
ffffffffc02053a4:	10046513          	ori	a0,s0,256
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02053a8:	00000797          	auipc	a5,0x0
ffffffffc02053ac:	8d678793          	addi	a5,a5,-1834 # ffffffffc0204c7e <kernel_thread_entry>
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02053b0:	4581                	li	a1,0
    tf.epc = (uintptr_t)kernel_thread_entry;
ffffffffc02053b2:	e63e                	sd	a5,264(sp)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
ffffffffc02053b4:	bd5ff0ef          	jal	ra,ffffffffc0204f88 <do_fork>
}
ffffffffc02053b8:	70f2                	ld	ra,312(sp)
ffffffffc02053ba:	7452                	ld	s0,304(sp)
ffffffffc02053bc:	74b2                	ld	s1,296(sp)
ffffffffc02053be:	7912                	ld	s2,288(sp)
ffffffffc02053c0:	6131                	addi	sp,sp,320
ffffffffc02053c2:	8082                	ret

ffffffffc02053c4 <do_exit>:
do_exit(int error_code) {
ffffffffc02053c4:	7179                	addi	sp,sp,-48
ffffffffc02053c6:	e84a                	sd	s2,16(sp)
    if (current == idleproc) {
ffffffffc02053c8:	000a7717          	auipc	a4,0xa7
ffffffffc02053cc:	10070713          	addi	a4,a4,256 # ffffffffc02ac4c8 <idleproc>
ffffffffc02053d0:	000a7917          	auipc	s2,0xa7
ffffffffc02053d4:	0f090913          	addi	s2,s2,240 # ffffffffc02ac4c0 <current>
ffffffffc02053d8:	00093783          	ld	a5,0(s2)
ffffffffc02053dc:	6318                	ld	a4,0(a4)
do_exit(int error_code) {
ffffffffc02053de:	f406                	sd	ra,40(sp)
ffffffffc02053e0:	f022                	sd	s0,32(sp)
ffffffffc02053e2:	ec26                	sd	s1,24(sp)
ffffffffc02053e4:	e44e                	sd	s3,8(sp)
ffffffffc02053e6:	e052                	sd	s4,0(sp)
    if (current == idleproc) {
ffffffffc02053e8:	0ce78c63          	beq	a5,a4,ffffffffc02054c0 <do_exit+0xfc>
    if (current == initproc) {
ffffffffc02053ec:	000a7417          	auipc	s0,0xa7
ffffffffc02053f0:	0e440413          	addi	s0,s0,228 # ffffffffc02ac4d0 <initproc>
ffffffffc02053f4:	6018                	ld	a4,0(s0)
ffffffffc02053f6:	0ee78b63          	beq	a5,a4,ffffffffc02054ec <do_exit+0x128>
    struct mm_struct *mm = current->mm;
ffffffffc02053fa:	7784                	ld	s1,40(a5)
ffffffffc02053fc:	89aa                	mv	s3,a0
    if (mm != NULL) {
ffffffffc02053fe:	c48d                	beqz	s1,ffffffffc0205428 <do_exit+0x64>
        lcr3(boot_cr3);
ffffffffc0205400:	000a7797          	auipc	a5,0xa7
ffffffffc0205404:	11078793          	addi	a5,a5,272 # ffffffffc02ac510 <boot_cr3>
ffffffffc0205408:	639c                	ld	a5,0(a5)
ffffffffc020540a:	577d                	li	a4,-1
ffffffffc020540c:	177e                	slli	a4,a4,0x3f
ffffffffc020540e:	83b1                	srli	a5,a5,0xc
ffffffffc0205410:	8fd9                	or	a5,a5,a4
ffffffffc0205412:	18079073          	csrw	satp,a5
    mm->mm_count -= 1;
ffffffffc0205416:	589c                	lw	a5,48(s1)
ffffffffc0205418:	fff7871b          	addiw	a4,a5,-1
ffffffffc020541c:	d898                	sw	a4,48(s1)
        if (mm_count_dec(mm) == 0) {
ffffffffc020541e:	cf4d                	beqz	a4,ffffffffc02054d8 <do_exit+0x114>
        current->mm = NULL;
ffffffffc0205420:	00093783          	ld	a5,0(s2)
ffffffffc0205424:	0207b423          	sd	zero,40(a5)
    current->state = PROC_ZOMBIE;
ffffffffc0205428:	00093783          	ld	a5,0(s2)
ffffffffc020542c:	470d                	li	a4,3
ffffffffc020542e:	c398                	sw	a4,0(a5)
    current->exit_code = error_code;
ffffffffc0205430:	0f37a423          	sw	s3,232(a5)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205434:	100027f3          	csrr	a5,sstatus
ffffffffc0205438:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc020543a:	4a01                	li	s4,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc020543c:	e7e1                	bnez	a5,ffffffffc0205504 <do_exit+0x140>
        proc = current->parent;
ffffffffc020543e:	00093703          	ld	a4,0(s2)
        if (proc->wait_state == WT_CHILD) {
ffffffffc0205442:	800007b7          	lui	a5,0x80000
ffffffffc0205446:	0785                	addi	a5,a5,1
        proc = current->parent;
ffffffffc0205448:	7308                	ld	a0,32(a4)
        if (proc->wait_state == WT_CHILD) {
ffffffffc020544a:	0ec52703          	lw	a4,236(a0)
ffffffffc020544e:	0af70f63          	beq	a4,a5,ffffffffc020550c <do_exit+0x148>
ffffffffc0205452:	00093683          	ld	a3,0(s2)
                if (initproc->wait_state == WT_CHILD) {
ffffffffc0205456:	800009b7          	lui	s3,0x80000
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020545a:	448d                	li	s1,3
                if (initproc->wait_state == WT_CHILD) {
ffffffffc020545c:	0985                	addi	s3,s3,1
        while (current->cptr != NULL) {
ffffffffc020545e:	7afc                	ld	a5,240(a3)
ffffffffc0205460:	cb95                	beqz	a5,ffffffffc0205494 <do_exit+0xd0>
            current->cptr = proc->optr;
ffffffffc0205462:	1007b703          	ld	a4,256(a5) # ffffffff80000100 <_binary_obj___user_exit_out_size+0xffffffff7fff5680>
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc0205466:	6008                	ld	a0,0(s0)
            current->cptr = proc->optr;
ffffffffc0205468:	faf8                	sd	a4,240(a3)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc020546a:	7978                	ld	a4,240(a0)
            proc->yptr = NULL;
ffffffffc020546c:	0e07bc23          	sd	zero,248(a5)
            if ((proc->optr = initproc->cptr) != NULL) {
ffffffffc0205470:	10e7b023          	sd	a4,256(a5)
ffffffffc0205474:	c311                	beqz	a4,ffffffffc0205478 <do_exit+0xb4>
                initproc->cptr->yptr = proc;
ffffffffc0205476:	ff7c                	sd	a5,248(a4)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205478:	4398                	lw	a4,0(a5)
            proc->parent = initproc;
ffffffffc020547a:	f388                	sd	a0,32(a5)
            initproc->cptr = proc;
ffffffffc020547c:	f97c                	sd	a5,240(a0)
            if (proc->state == PROC_ZOMBIE) {
ffffffffc020547e:	fe9710e3          	bne	a4,s1,ffffffffc020545e <do_exit+0x9a>
                if (initproc->wait_state == WT_CHILD) {
ffffffffc0205482:	0ec52783          	lw	a5,236(a0)
ffffffffc0205486:	fd379ce3          	bne	a5,s3,ffffffffc020545e <do_exit+0x9a>
                    wakeup_proc(initproc);
ffffffffc020548a:	2c5000ef          	jal	ra,ffffffffc0205f4e <wakeup_proc>
ffffffffc020548e:	00093683          	ld	a3,0(s2)
ffffffffc0205492:	b7f1                	j	ffffffffc020545e <do_exit+0x9a>
    if (flag) {
ffffffffc0205494:	020a1363          	bnez	s4,ffffffffc02054ba <do_exit+0xf6>
    schedule();
ffffffffc0205498:	333000ef          	jal	ra,ffffffffc0205fca <schedule>
    panic("do_exit will not return!! %d.\n", current->pid);
ffffffffc020549c:	00093783          	ld	a5,0(s2)
ffffffffc02054a0:	00003617          	auipc	a2,0x3
ffffffffc02054a4:	0c860613          	addi	a2,a2,200 # ffffffffc0208568 <default_pmm_manager+0x1218>
ffffffffc02054a8:	21c00593          	li	a1,540
ffffffffc02054ac:	43d4                	lw	a3,4(a5)
ffffffffc02054ae:	00003517          	auipc	a0,0x3
ffffffffc02054b2:	36250513          	addi	a0,a0,866 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc02054b6:	fcffa0ef          	jal	ra,ffffffffc0200484 <__panic>
        intr_enable();
ffffffffc02054ba:	99afb0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc02054be:	bfe9                	j	ffffffffc0205498 <do_exit+0xd4>
        panic("idleproc exit.\n");
ffffffffc02054c0:	00003617          	auipc	a2,0x3
ffffffffc02054c4:	08860613          	addi	a2,a2,136 # ffffffffc0208548 <default_pmm_manager+0x11f8>
ffffffffc02054c8:	1eb00593          	li	a1,491
ffffffffc02054cc:	00003517          	auipc	a0,0x3
ffffffffc02054d0:	34450513          	addi	a0,a0,836 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc02054d4:	fb1fa0ef          	jal	ra,ffffffffc0200484 <__panic>
            exit_mmap(mm);
ffffffffc02054d8:	8526                	mv	a0,s1
ffffffffc02054da:	f07fe0ef          	jal	ra,ffffffffc02043e0 <exit_mmap>
            put_pgdir(mm);
ffffffffc02054de:	8526                	mv	a0,s1
ffffffffc02054e0:	8adff0ef          	jal	ra,ffffffffc0204d8c <put_pgdir>
            mm_destroy(mm);
ffffffffc02054e4:	8526                	mv	a0,s1
ffffffffc02054e6:	d5bfe0ef          	jal	ra,ffffffffc0204240 <mm_destroy>
ffffffffc02054ea:	bf1d                	j	ffffffffc0205420 <do_exit+0x5c>
        panic("initproc exit.\n");
ffffffffc02054ec:	00003617          	auipc	a2,0x3
ffffffffc02054f0:	06c60613          	addi	a2,a2,108 # ffffffffc0208558 <default_pmm_manager+0x1208>
ffffffffc02054f4:	1ee00593          	li	a1,494
ffffffffc02054f8:	00003517          	auipc	a0,0x3
ffffffffc02054fc:	31850513          	addi	a0,a0,792 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205500:	f85fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        intr_disable();
ffffffffc0205504:	956fb0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc0205508:	4a05                	li	s4,1
ffffffffc020550a:	bf15                	j	ffffffffc020543e <do_exit+0x7a>
            wakeup_proc(proc);
ffffffffc020550c:	243000ef          	jal	ra,ffffffffc0205f4e <wakeup_proc>
ffffffffc0205510:	b789                	j	ffffffffc0205452 <do_exit+0x8e>

ffffffffc0205512 <do_wait.part.1>:
do_wait(int pid, int *code_store) {
ffffffffc0205512:	7139                	addi	sp,sp,-64
ffffffffc0205514:	e852                	sd	s4,16(sp)
        current->wait_state = WT_CHILD;
ffffffffc0205516:	80000a37          	lui	s4,0x80000
do_wait(int pid, int *code_store) {
ffffffffc020551a:	f426                	sd	s1,40(sp)
ffffffffc020551c:	f04a                	sd	s2,32(sp)
ffffffffc020551e:	ec4e                	sd	s3,24(sp)
ffffffffc0205520:	e456                	sd	s5,8(sp)
ffffffffc0205522:	e05a                	sd	s6,0(sp)
ffffffffc0205524:	fc06                	sd	ra,56(sp)
ffffffffc0205526:	f822                	sd	s0,48(sp)
ffffffffc0205528:	89aa                	mv	s3,a0
ffffffffc020552a:	8b2e                	mv	s6,a1
        proc = current->cptr;
ffffffffc020552c:	000a7917          	auipc	s2,0xa7
ffffffffc0205530:	f9490913          	addi	s2,s2,-108 # ffffffffc02ac4c0 <current>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205534:	448d                	li	s1,3
        current->state = PROC_SLEEPING;
ffffffffc0205536:	4a85                	li	s5,1
        current->wait_state = WT_CHILD;
ffffffffc0205538:	2a05                	addiw	s4,s4,1
    if (pid != 0) {
ffffffffc020553a:	02098f63          	beqz	s3,ffffffffc0205578 <do_wait.part.1+0x66>
        proc = find_proc(pid);
ffffffffc020553e:	854e                	mv	a0,s3
ffffffffc0205540:	9edff0ef          	jal	ra,ffffffffc0204f2c <find_proc>
ffffffffc0205544:	842a                	mv	s0,a0
        if (proc != NULL && proc->parent == current) {
ffffffffc0205546:	12050063          	beqz	a0,ffffffffc0205666 <do_wait.part.1+0x154>
ffffffffc020554a:	00093703          	ld	a4,0(s2)
ffffffffc020554e:	711c                	ld	a5,32(a0)
ffffffffc0205550:	10e79b63          	bne	a5,a4,ffffffffc0205666 <do_wait.part.1+0x154>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205554:	411c                	lw	a5,0(a0)
ffffffffc0205556:	02978c63          	beq	a5,s1,ffffffffc020558e <do_wait.part.1+0x7c>
        current->state = PROC_SLEEPING;
ffffffffc020555a:	01572023          	sw	s5,0(a4)
        current->wait_state = WT_CHILD;
ffffffffc020555e:	0f472623          	sw	s4,236(a4)
        schedule();
ffffffffc0205562:	269000ef          	jal	ra,ffffffffc0205fca <schedule>
        if (current->flags & PF_EXITING) {
ffffffffc0205566:	00093783          	ld	a5,0(s2)
ffffffffc020556a:	0b07a783          	lw	a5,176(a5)
ffffffffc020556e:	8b85                	andi	a5,a5,1
ffffffffc0205570:	d7e9                	beqz	a5,ffffffffc020553a <do_wait.part.1+0x28>
            do_exit(-E_KILLED);
ffffffffc0205572:	555d                	li	a0,-9
ffffffffc0205574:	e51ff0ef          	jal	ra,ffffffffc02053c4 <do_exit>
        proc = current->cptr;
ffffffffc0205578:	00093703          	ld	a4,0(s2)
ffffffffc020557c:	7b60                	ld	s0,240(a4)
        for (; proc != NULL; proc = proc->optr) {
ffffffffc020557e:	e409                	bnez	s0,ffffffffc0205588 <do_wait.part.1+0x76>
ffffffffc0205580:	a0dd                	j	ffffffffc0205666 <do_wait.part.1+0x154>
ffffffffc0205582:	10043403          	ld	s0,256(s0)
ffffffffc0205586:	d871                	beqz	s0,ffffffffc020555a <do_wait.part.1+0x48>
            if (proc->state == PROC_ZOMBIE) {
ffffffffc0205588:	401c                	lw	a5,0(s0)
ffffffffc020558a:	fe979ce3          	bne	a5,s1,ffffffffc0205582 <do_wait.part.1+0x70>
    if (proc == idleproc || proc == initproc) {
ffffffffc020558e:	000a7797          	auipc	a5,0xa7
ffffffffc0205592:	f3a78793          	addi	a5,a5,-198 # ffffffffc02ac4c8 <idleproc>
ffffffffc0205596:	639c                	ld	a5,0(a5)
ffffffffc0205598:	0c878d63          	beq	a5,s0,ffffffffc0205672 <do_wait.part.1+0x160>
ffffffffc020559c:	000a7797          	auipc	a5,0xa7
ffffffffc02055a0:	f3478793          	addi	a5,a5,-204 # ffffffffc02ac4d0 <initproc>
ffffffffc02055a4:	639c                	ld	a5,0(a5)
ffffffffc02055a6:	0cf40663          	beq	s0,a5,ffffffffc0205672 <do_wait.part.1+0x160>
    if (code_store != NULL) {
ffffffffc02055aa:	000b0663          	beqz	s6,ffffffffc02055b6 <do_wait.part.1+0xa4>
        *code_store = proc->exit_code;
ffffffffc02055ae:	0e842783          	lw	a5,232(s0)
ffffffffc02055b2:	00fb2023          	sw	a5,0(s6)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02055b6:	100027f3          	csrr	a5,sstatus
ffffffffc02055ba:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc02055bc:	4581                	li	a1,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02055be:	e7d5                	bnez	a5,ffffffffc020566a <do_wait.part.1+0x158>
    __list_del(listelm->prev, listelm->next);
ffffffffc02055c0:	6c70                	ld	a2,216(s0)
ffffffffc02055c2:	7074                	ld	a3,224(s0)
    if (proc->optr != NULL) {
ffffffffc02055c4:	10043703          	ld	a4,256(s0)
ffffffffc02055c8:	7c7c                	ld	a5,248(s0)
    prev->next = next;
ffffffffc02055ca:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02055cc:	e290                	sd	a2,0(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc02055ce:	6470                	ld	a2,200(s0)
ffffffffc02055d0:	6874                	ld	a3,208(s0)
    prev->next = next;
ffffffffc02055d2:	e614                	sd	a3,8(a2)
    next->prev = prev;
ffffffffc02055d4:	e290                	sd	a2,0(a3)
ffffffffc02055d6:	c319                	beqz	a4,ffffffffc02055dc <do_wait.part.1+0xca>
        proc->optr->yptr = proc->yptr;
ffffffffc02055d8:	ff7c                	sd	a5,248(a4)
ffffffffc02055da:	7c7c                	ld	a5,248(s0)
    if (proc->yptr != NULL) {
ffffffffc02055dc:	c3d1                	beqz	a5,ffffffffc0205660 <do_wait.part.1+0x14e>
        proc->yptr->optr = proc->optr;
ffffffffc02055de:	10e7b023          	sd	a4,256(a5)
    nr_process --;
ffffffffc02055e2:	000a7797          	auipc	a5,0xa7
ffffffffc02055e6:	ef678793          	addi	a5,a5,-266 # ffffffffc02ac4d8 <nr_process>
ffffffffc02055ea:	439c                	lw	a5,0(a5)
ffffffffc02055ec:	37fd                	addiw	a5,a5,-1
ffffffffc02055ee:	000a7717          	auipc	a4,0xa7
ffffffffc02055f2:	eef72523          	sw	a5,-278(a4) # ffffffffc02ac4d8 <nr_process>
    if (flag) {
ffffffffc02055f6:	e1b5                	bnez	a1,ffffffffc020565a <do_wait.part.1+0x148>
    free_pages(kva2page((void *)(proc->kstack)), KSTACKPAGE);
ffffffffc02055f8:	6814                	ld	a3,16(s0)
ffffffffc02055fa:	c02007b7          	lui	a5,0xc0200
ffffffffc02055fe:	0af6e263          	bltu	a3,a5,ffffffffc02056a2 <do_wait.part.1+0x190>
ffffffffc0205602:	000a7797          	auipc	a5,0xa7
ffffffffc0205606:	f0678793          	addi	a5,a5,-250 # ffffffffc02ac508 <va_pa_offset>
ffffffffc020560a:	6398                	ld	a4,0(a5)
    if (PPN(pa) >= npage) {
ffffffffc020560c:	000a7797          	auipc	a5,0xa7
ffffffffc0205610:	e9c78793          	addi	a5,a5,-356 # ffffffffc02ac4a8 <npage>
ffffffffc0205614:	639c                	ld	a5,0(a5)
    return pa2page(PADDR(kva));
ffffffffc0205616:	8e99                	sub	a3,a3,a4
    if (PPN(pa) >= npage) {
ffffffffc0205618:	82b1                	srli	a3,a3,0xc
ffffffffc020561a:	06f6f863          	bleu	a5,a3,ffffffffc020568a <do_wait.part.1+0x178>
    return &pages[PPN(pa) - nbase];
ffffffffc020561e:	00003797          	auipc	a5,0x3
ffffffffc0205622:	6ba78793          	addi	a5,a5,1722 # ffffffffc0208cd8 <nbase>
ffffffffc0205626:	639c                	ld	a5,0(a5)
ffffffffc0205628:	000a7717          	auipc	a4,0xa7
ffffffffc020562c:	ef070713          	addi	a4,a4,-272 # ffffffffc02ac518 <pages>
ffffffffc0205630:	6308                	ld	a0,0(a4)
ffffffffc0205632:	8e9d                	sub	a3,a3,a5
ffffffffc0205634:	069a                	slli	a3,a3,0x6
ffffffffc0205636:	9536                	add	a0,a0,a3
ffffffffc0205638:	4589                	li	a1,2
ffffffffc020563a:	8a1fc0ef          	jal	ra,ffffffffc0201eda <free_pages>
    kfree(proc);
ffffffffc020563e:	8522                	mv	a0,s0
ffffffffc0205640:	ed2fc0ef          	jal	ra,ffffffffc0201d12 <kfree>
    return 0;
ffffffffc0205644:	4501                	li	a0,0
}
ffffffffc0205646:	70e2                	ld	ra,56(sp)
ffffffffc0205648:	7442                	ld	s0,48(sp)
ffffffffc020564a:	74a2                	ld	s1,40(sp)
ffffffffc020564c:	7902                	ld	s2,32(sp)
ffffffffc020564e:	69e2                	ld	s3,24(sp)
ffffffffc0205650:	6a42                	ld	s4,16(sp)
ffffffffc0205652:	6aa2                	ld	s5,8(sp)
ffffffffc0205654:	6b02                	ld	s6,0(sp)
ffffffffc0205656:	6121                	addi	sp,sp,64
ffffffffc0205658:	8082                	ret
        intr_enable();
ffffffffc020565a:	ffbfa0ef          	jal	ra,ffffffffc0200654 <intr_enable>
ffffffffc020565e:	bf69                	j	ffffffffc02055f8 <do_wait.part.1+0xe6>
       proc->parent->cptr = proc->optr;
ffffffffc0205660:	701c                	ld	a5,32(s0)
ffffffffc0205662:	fbf8                	sd	a4,240(a5)
ffffffffc0205664:	bfbd                	j	ffffffffc02055e2 <do_wait.part.1+0xd0>
    return -E_BAD_PROC;
ffffffffc0205666:	5579                	li	a0,-2
ffffffffc0205668:	bff9                	j	ffffffffc0205646 <do_wait.part.1+0x134>
        intr_disable();
ffffffffc020566a:	ff1fa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc020566e:	4585                	li	a1,1
ffffffffc0205670:	bf81                	j	ffffffffc02055c0 <do_wait.part.1+0xae>
        panic("wait idleproc or initproc.\n");
ffffffffc0205672:	00003617          	auipc	a2,0x3
ffffffffc0205676:	f5660613          	addi	a2,a2,-170 # ffffffffc02085c8 <default_pmm_manager+0x1278>
ffffffffc020567a:	33200593          	li	a1,818
ffffffffc020567e:	00003517          	auipc	a0,0x3
ffffffffc0205682:	19250513          	addi	a0,a0,402 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205686:	dfffa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("pa2page called with invalid pa");
ffffffffc020568a:	00002617          	auipc	a2,0x2
ffffffffc020568e:	d7660613          	addi	a2,a2,-650 # ffffffffc0207400 <default_pmm_manager+0xb0>
ffffffffc0205692:	06200593          	li	a1,98
ffffffffc0205696:	00002517          	auipc	a0,0x2
ffffffffc020569a:	d3250513          	addi	a0,a0,-718 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc020569e:	de7fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    return pa2page(PADDR(kva));
ffffffffc02056a2:	00002617          	auipc	a2,0x2
ffffffffc02056a6:	d3660613          	addi	a2,a2,-714 # ffffffffc02073d8 <default_pmm_manager+0x88>
ffffffffc02056aa:	06e00593          	li	a1,110
ffffffffc02056ae:	00002517          	auipc	a0,0x2
ffffffffc02056b2:	d1a50513          	addi	a0,a0,-742 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc02056b6:	dcffa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02056ba <init_main>:
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void *arg) {
ffffffffc02056ba:	1141                	addi	sp,sp,-16
ffffffffc02056bc:	e406                	sd	ra,8(sp)
    size_t nr_free_pages_store = nr_free_pages();
ffffffffc02056be:	863fc0ef          	jal	ra,ffffffffc0201f20 <nr_free_pages>
    size_t kernel_allocated_store = kallocated();
ffffffffc02056c2:	d90fc0ef          	jal	ra,ffffffffc0201c52 <kallocated>

    int pid = kernel_thread(user_main, NULL, 0);
ffffffffc02056c6:	4601                	li	a2,0
ffffffffc02056c8:	4581                	li	a1,0
ffffffffc02056ca:	fffff517          	auipc	a0,0xfffff
ffffffffc02056ce:	64050513          	addi	a0,a0,1600 # ffffffffc0204d0a <user_main>
ffffffffc02056d2:	ca3ff0ef          	jal	ra,ffffffffc0205374 <kernel_thread>
    if (pid <= 0) {
ffffffffc02056d6:	00a04563          	bgtz	a0,ffffffffc02056e0 <init_main+0x26>
ffffffffc02056da:	a841                	j	ffffffffc020576a <init_main+0xb0>
        panic("create user_main failed.\n");
    }

    while (do_wait(0, NULL) == 0) {
        schedule();
ffffffffc02056dc:	0ef000ef          	jal	ra,ffffffffc0205fca <schedule>
    if (code_store != NULL) {
ffffffffc02056e0:	4581                	li	a1,0
ffffffffc02056e2:	4501                	li	a0,0
ffffffffc02056e4:	e2fff0ef          	jal	ra,ffffffffc0205512 <do_wait.part.1>
    while (do_wait(0, NULL) == 0) {
ffffffffc02056e8:	d975                	beqz	a0,ffffffffc02056dc <init_main+0x22>
    }

    cprintf("all user-mode processes have quit.\n");
ffffffffc02056ea:	00003517          	auipc	a0,0x3
ffffffffc02056ee:	f1e50513          	addi	a0,a0,-226 # ffffffffc0208608 <default_pmm_manager+0x12b8>
ffffffffc02056f2:	a9dfa0ef          	jal	ra,ffffffffc020018e <cprintf>
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc02056f6:	000a7797          	auipc	a5,0xa7
ffffffffc02056fa:	dda78793          	addi	a5,a5,-550 # ffffffffc02ac4d0 <initproc>
ffffffffc02056fe:	639c                	ld	a5,0(a5)
ffffffffc0205700:	7bf8                	ld	a4,240(a5)
ffffffffc0205702:	e721                	bnez	a4,ffffffffc020574a <init_main+0x90>
ffffffffc0205704:	7ff8                	ld	a4,248(a5)
ffffffffc0205706:	e331                	bnez	a4,ffffffffc020574a <init_main+0x90>
ffffffffc0205708:	1007b703          	ld	a4,256(a5)
ffffffffc020570c:	ef1d                	bnez	a4,ffffffffc020574a <init_main+0x90>
    assert(nr_process == 2);
ffffffffc020570e:	000a7717          	auipc	a4,0xa7
ffffffffc0205712:	dca70713          	addi	a4,a4,-566 # ffffffffc02ac4d8 <nr_process>
ffffffffc0205716:	4314                	lw	a3,0(a4)
ffffffffc0205718:	4709                	li	a4,2
ffffffffc020571a:	0ae69463          	bne	a3,a4,ffffffffc02057c2 <init_main+0x108>
    return listelm->next;
ffffffffc020571e:	000a7697          	auipc	a3,0xa7
ffffffffc0205722:	ee268693          	addi	a3,a3,-286 # ffffffffc02ac600 <proc_list>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc0205726:	6698                	ld	a4,8(a3)
ffffffffc0205728:	0c878793          	addi	a5,a5,200
ffffffffc020572c:	06f71b63          	bne	a4,a5,ffffffffc02057a2 <init_main+0xe8>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205730:	629c                	ld	a5,0(a3)
ffffffffc0205732:	04f71863          	bne	a4,a5,ffffffffc0205782 <init_main+0xc8>

    cprintf("init check memory pass.\n");
ffffffffc0205736:	00003517          	auipc	a0,0x3
ffffffffc020573a:	fba50513          	addi	a0,a0,-70 # ffffffffc02086f0 <default_pmm_manager+0x13a0>
ffffffffc020573e:	a51fa0ef          	jal	ra,ffffffffc020018e <cprintf>
    return 0;
}
ffffffffc0205742:	60a2                	ld	ra,8(sp)
ffffffffc0205744:	4501                	li	a0,0
ffffffffc0205746:	0141                	addi	sp,sp,16
ffffffffc0205748:	8082                	ret
    assert(initproc->cptr == NULL && initproc->yptr == NULL && initproc->optr == NULL);
ffffffffc020574a:	00003697          	auipc	a3,0x3
ffffffffc020574e:	ee668693          	addi	a3,a3,-282 # ffffffffc0208630 <default_pmm_manager+0x12e0>
ffffffffc0205752:	00001617          	auipc	a2,0x1
ffffffffc0205756:	4b660613          	addi	a2,a2,1206 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc020575a:	39800593          	li	a1,920
ffffffffc020575e:	00003517          	auipc	a0,0x3
ffffffffc0205762:	0b250513          	addi	a0,a0,178 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205766:	d1ffa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("create user_main failed.\n");
ffffffffc020576a:	00003617          	auipc	a2,0x3
ffffffffc020576e:	e7e60613          	addi	a2,a2,-386 # ffffffffc02085e8 <default_pmm_manager+0x1298>
ffffffffc0205772:	39000593          	li	a1,912
ffffffffc0205776:	00003517          	auipc	a0,0x3
ffffffffc020577a:	09a50513          	addi	a0,a0,154 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc020577e:	d07fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(list_prev(&proc_list) == &(initproc->list_link));
ffffffffc0205782:	00003697          	auipc	a3,0x3
ffffffffc0205786:	f3e68693          	addi	a3,a3,-194 # ffffffffc02086c0 <default_pmm_manager+0x1370>
ffffffffc020578a:	00001617          	auipc	a2,0x1
ffffffffc020578e:	47e60613          	addi	a2,a2,1150 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0205792:	39b00593          	li	a1,923
ffffffffc0205796:	00003517          	auipc	a0,0x3
ffffffffc020579a:	07a50513          	addi	a0,a0,122 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc020579e:	ce7fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(list_next(&proc_list) == &(initproc->list_link));
ffffffffc02057a2:	00003697          	auipc	a3,0x3
ffffffffc02057a6:	eee68693          	addi	a3,a3,-274 # ffffffffc0208690 <default_pmm_manager+0x1340>
ffffffffc02057aa:	00001617          	auipc	a2,0x1
ffffffffc02057ae:	45e60613          	addi	a2,a2,1118 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02057b2:	39a00593          	li	a1,922
ffffffffc02057b6:	00003517          	auipc	a0,0x3
ffffffffc02057ba:	05a50513          	addi	a0,a0,90 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc02057be:	cc7fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(nr_process == 2);
ffffffffc02057c2:	00003697          	auipc	a3,0x3
ffffffffc02057c6:	ebe68693          	addi	a3,a3,-322 # ffffffffc0208680 <default_pmm_manager+0x1330>
ffffffffc02057ca:	00001617          	auipc	a2,0x1
ffffffffc02057ce:	43e60613          	addi	a2,a2,1086 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc02057d2:	39900593          	li	a1,921
ffffffffc02057d6:	00003517          	auipc	a0,0x3
ffffffffc02057da:	03a50513          	addi	a0,a0,58 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc02057de:	ca7fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc02057e2 <do_execve>:
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02057e2:	7135                	addi	sp,sp,-160
ffffffffc02057e4:	f8d2                	sd	s4,112(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02057e6:	000a7a17          	auipc	s4,0xa7
ffffffffc02057ea:	cdaa0a13          	addi	s4,s4,-806 # ffffffffc02ac4c0 <current>
ffffffffc02057ee:	000a3783          	ld	a5,0(s4)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02057f2:	e14a                	sd	s2,128(sp)
ffffffffc02057f4:	e922                	sd	s0,144(sp)
    struct mm_struct *mm = current->mm;
ffffffffc02057f6:	0287b903          	ld	s2,40(a5)
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc02057fa:	fcce                	sd	s3,120(sp)
ffffffffc02057fc:	f0da                	sd	s6,96(sp)
ffffffffc02057fe:	89aa                	mv	s3,a0
ffffffffc0205800:	842e                	mv	s0,a1
ffffffffc0205802:	8b32                	mv	s6,a2
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc0205804:	4681                	li	a3,0
ffffffffc0205806:	862e                	mv	a2,a1
ffffffffc0205808:	85aa                	mv	a1,a0
ffffffffc020580a:	854a                	mv	a0,s2
do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
ffffffffc020580c:	ed06                	sd	ra,152(sp)
ffffffffc020580e:	e526                	sd	s1,136(sp)
ffffffffc0205810:	f4d6                	sd	s5,104(sp)
ffffffffc0205812:	ecde                	sd	s7,88(sp)
ffffffffc0205814:	e8e2                	sd	s8,80(sp)
ffffffffc0205816:	e4e6                	sd	s9,72(sp)
ffffffffc0205818:	e0ea                	sd	s10,64(sp)
ffffffffc020581a:	fc6e                	sd	s11,56(sp)
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
ffffffffc020581c:	a66ff0ef          	jal	ra,ffffffffc0204a82 <user_mem_check>
ffffffffc0205820:	40050663          	beqz	a0,ffffffffc0205c2c <do_execve+0x44a>
    memset(local_name, 0, sizeof(local_name));
ffffffffc0205824:	4641                	li	a2,16
ffffffffc0205826:	4581                	li	a1,0
ffffffffc0205828:	1008                	addi	a0,sp,32
ffffffffc020582a:	5c5000ef          	jal	ra,ffffffffc02065ee <memset>
    memcpy(local_name, name, len);
ffffffffc020582e:	47bd                	li	a5,15
ffffffffc0205830:	8622                	mv	a2,s0
ffffffffc0205832:	0687ee63          	bltu	a5,s0,ffffffffc02058ae <do_execve+0xcc>
ffffffffc0205836:	85ce                	mv	a1,s3
ffffffffc0205838:	1008                	addi	a0,sp,32
ffffffffc020583a:	5c7000ef          	jal	ra,ffffffffc0206600 <memcpy>
    if (mm != NULL) {
ffffffffc020583e:	06090f63          	beqz	s2,ffffffffc02058bc <do_execve+0xda>
        cputs("mm != NULL");
ffffffffc0205842:	00002517          	auipc	a0,0x2
ffffffffc0205846:	2ee50513          	addi	a0,a0,750 # ffffffffc0207b30 <default_pmm_manager+0x7e0>
ffffffffc020584a:	97dfa0ef          	jal	ra,ffffffffc02001c6 <cputs>
        lcr3(boot_cr3);
ffffffffc020584e:	000a7797          	auipc	a5,0xa7
ffffffffc0205852:	cc278793          	addi	a5,a5,-830 # ffffffffc02ac510 <boot_cr3>
ffffffffc0205856:	639c                	ld	a5,0(a5)
ffffffffc0205858:	577d                	li	a4,-1
ffffffffc020585a:	177e                	slli	a4,a4,0x3f
ffffffffc020585c:	83b1                	srli	a5,a5,0xc
ffffffffc020585e:	8fd9                	or	a5,a5,a4
ffffffffc0205860:	18079073          	csrw	satp,a5
ffffffffc0205864:	03092783          	lw	a5,48(s2)
ffffffffc0205868:	fff7871b          	addiw	a4,a5,-1
ffffffffc020586c:	02e92823          	sw	a4,48(s2)
        if (mm_count_dec(mm) == 0) {
ffffffffc0205870:	28070d63          	beqz	a4,ffffffffc0205b0a <do_execve+0x328>
        current->mm = NULL;
ffffffffc0205874:	000a3783          	ld	a5,0(s4)
ffffffffc0205878:	0207b423          	sd	zero,40(a5)
    if ((mm = mm_create()) == NULL) {
ffffffffc020587c:	83ffe0ef          	jal	ra,ffffffffc02040ba <mm_create>
ffffffffc0205880:	892a                	mv	s2,a0
ffffffffc0205882:	c135                	beqz	a0,ffffffffc02058e6 <do_execve+0x104>
    if (setup_pgdir(mm) != 0) {
ffffffffc0205884:	d86ff0ef          	jal	ra,ffffffffc0204e0a <setup_pgdir>
ffffffffc0205888:	e931                	bnez	a0,ffffffffc02058dc <do_execve+0xfa>
    if (elf->e_magic != ELF_MAGIC) {
ffffffffc020588a:	000b2703          	lw	a4,0(s6)
ffffffffc020588e:	464c47b7          	lui	a5,0x464c4
ffffffffc0205892:	57f78793          	addi	a5,a5,1407 # 464c457f <_binary_obj___user_exit_out_size+0x464b9aff>
ffffffffc0205896:	04f70a63          	beq	a4,a5,ffffffffc02058ea <do_execve+0x108>
    put_pgdir(mm);
ffffffffc020589a:	854a                	mv	a0,s2
ffffffffc020589c:	cf0ff0ef          	jal	ra,ffffffffc0204d8c <put_pgdir>
    mm_destroy(mm);
ffffffffc02058a0:	854a                	mv	a0,s2
ffffffffc02058a2:	99ffe0ef          	jal	ra,ffffffffc0204240 <mm_destroy>
        ret = -E_INVAL_ELF;
ffffffffc02058a6:	59e1                	li	s3,-8
    do_exit(ret);
ffffffffc02058a8:	854e                	mv	a0,s3
ffffffffc02058aa:	b1bff0ef          	jal	ra,ffffffffc02053c4 <do_exit>
    memcpy(local_name, name, len);
ffffffffc02058ae:	463d                	li	a2,15
ffffffffc02058b0:	85ce                	mv	a1,s3
ffffffffc02058b2:	1008                	addi	a0,sp,32
ffffffffc02058b4:	54d000ef          	jal	ra,ffffffffc0206600 <memcpy>
    if (mm != NULL) {
ffffffffc02058b8:	f80915e3          	bnez	s2,ffffffffc0205842 <do_execve+0x60>
    if (current->mm != NULL) {
ffffffffc02058bc:	000a3783          	ld	a5,0(s4)
ffffffffc02058c0:	779c                	ld	a5,40(a5)
ffffffffc02058c2:	dfcd                	beqz	a5,ffffffffc020587c <do_execve+0x9a>
        panic("load_icode: current->mm must be empty.\n");
ffffffffc02058c4:	00003617          	auipc	a2,0x3
ffffffffc02058c8:	afc60613          	addi	a2,a2,-1284 # ffffffffc02083c0 <default_pmm_manager+0x1070>
ffffffffc02058cc:	22600593          	li	a1,550
ffffffffc02058d0:	00003517          	auipc	a0,0x3
ffffffffc02058d4:	f4050513          	addi	a0,a0,-192 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc02058d8:	badfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    mm_destroy(mm);
ffffffffc02058dc:	854a                	mv	a0,s2
ffffffffc02058de:	963fe0ef          	jal	ra,ffffffffc0204240 <mm_destroy>
    int ret = -E_NO_MEM;
ffffffffc02058e2:	59f1                	li	s3,-4
ffffffffc02058e4:	b7d1                	j	ffffffffc02058a8 <do_execve+0xc6>
ffffffffc02058e6:	59f1                	li	s3,-4
ffffffffc02058e8:	b7c1                	j	ffffffffc02058a8 <do_execve+0xc6>
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058ea:	038b5703          	lhu	a4,56(s6)
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02058ee:	020b3403          	ld	s0,32(s6)
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058f2:	00371793          	slli	a5,a4,0x3
ffffffffc02058f6:	8f99                	sub	a5,a5,a4
    struct proghdr *ph = (struct proghdr *)(binary + elf->e_phoff);
ffffffffc02058f8:	945a                	add	s0,s0,s6
    struct proghdr *ph_end = ph + elf->e_phnum;
ffffffffc02058fa:	078e                	slli	a5,a5,0x3
ffffffffc02058fc:	97a2                	add	a5,a5,s0
ffffffffc02058fe:	ec3e                	sd	a5,24(sp)
    for (; ph < ph_end; ph ++) {
ffffffffc0205900:	02f47b63          	bleu	a5,s0,ffffffffc0205936 <do_execve+0x154>
    return KADDR(page2pa(page));
ffffffffc0205904:	5bfd                	li	s7,-1
ffffffffc0205906:	00cbd793          	srli	a5,s7,0xc
    return page - pages + nbase;
ffffffffc020590a:	000a7d97          	auipc	s11,0xa7
ffffffffc020590e:	c0ed8d93          	addi	s11,s11,-1010 # ffffffffc02ac518 <pages>
ffffffffc0205912:	00003d17          	auipc	s10,0x3
ffffffffc0205916:	3c6d0d13          	addi	s10,s10,966 # ffffffffc0208cd8 <nbase>
    return KADDR(page2pa(page));
ffffffffc020591a:	e43e                	sd	a5,8(sp)
ffffffffc020591c:	000a7c97          	auipc	s9,0xa7
ffffffffc0205920:	b8cc8c93          	addi	s9,s9,-1140 # ffffffffc02ac4a8 <npage>
        if (ph->p_type != ELF_PT_LOAD) {
ffffffffc0205924:	4018                	lw	a4,0(s0)
ffffffffc0205926:	4785                	li	a5,1
ffffffffc0205928:	0ef70f63          	beq	a4,a5,ffffffffc0205a26 <do_execve+0x244>
    for (; ph < ph_end; ph ++) {
ffffffffc020592c:	67e2                	ld	a5,24(sp)
ffffffffc020592e:	03840413          	addi	s0,s0,56
ffffffffc0205932:	fef469e3          	bltu	s0,a5,ffffffffc0205924 <do_execve+0x142>
    if ((ret = mm_map(mm, USTACKTOP - USTACKSIZE, USTACKSIZE, vm_flags, NULL)) != 0) {
ffffffffc0205936:	4701                	li	a4,0
ffffffffc0205938:	46ad                	li	a3,11
ffffffffc020593a:	00100637          	lui	a2,0x100
ffffffffc020593e:	7ff005b7          	lui	a1,0x7ff00
ffffffffc0205942:	854a                	mv	a0,s2
ffffffffc0205944:	94ffe0ef          	jal	ra,ffffffffc0204292 <mm_map>
ffffffffc0205948:	89aa                	mv	s3,a0
ffffffffc020594a:	1a051663          	bnez	a0,ffffffffc0205af6 <do_execve+0x314>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc020594e:	01893503          	ld	a0,24(s2)
ffffffffc0205952:	467d                	li	a2,31
ffffffffc0205954:	7ffff5b7          	lui	a1,0x7ffff
ffffffffc0205958:	995fd0ef          	jal	ra,ffffffffc02032ec <pgdir_alloc_page>
ffffffffc020595c:	36050463          	beqz	a0,ffffffffc0205cc4 <do_execve+0x4e2>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205960:	01893503          	ld	a0,24(s2)
ffffffffc0205964:	467d                	li	a2,31
ffffffffc0205966:	7fffe5b7          	lui	a1,0x7fffe
ffffffffc020596a:	983fd0ef          	jal	ra,ffffffffc02032ec <pgdir_alloc_page>
ffffffffc020596e:	32050b63          	beqz	a0,ffffffffc0205ca4 <do_execve+0x4c2>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205972:	01893503          	ld	a0,24(s2)
ffffffffc0205976:	467d                	li	a2,31
ffffffffc0205978:	7fffd5b7          	lui	a1,0x7fffd
ffffffffc020597c:	971fd0ef          	jal	ra,ffffffffc02032ec <pgdir_alloc_page>
ffffffffc0205980:	30050263          	beqz	a0,ffffffffc0205c84 <do_execve+0x4a2>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205984:	01893503          	ld	a0,24(s2)
ffffffffc0205988:	467d                	li	a2,31
ffffffffc020598a:	7fffc5b7          	lui	a1,0x7fffc
ffffffffc020598e:	95ffd0ef          	jal	ra,ffffffffc02032ec <pgdir_alloc_page>
ffffffffc0205992:	2c050963          	beqz	a0,ffffffffc0205c64 <do_execve+0x482>
    mm->mm_count += 1;
ffffffffc0205996:	03092783          	lw	a5,48(s2)
    current->mm = mm;
ffffffffc020599a:	000a3603          	ld	a2,0(s4)
    current->cr3 = PADDR(mm->pgdir);
ffffffffc020599e:	01893683          	ld	a3,24(s2)
ffffffffc02059a2:	2785                	addiw	a5,a5,1
ffffffffc02059a4:	02f92823          	sw	a5,48(s2)
    current->mm = mm;
ffffffffc02059a8:	03263423          	sd	s2,40(a2) # 100028 <_binary_obj___user_exit_out_size+0xf55a8>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc02059ac:	c02007b7          	lui	a5,0xc0200
ffffffffc02059b0:	28f6ee63          	bltu	a3,a5,ffffffffc0205c4c <do_execve+0x46a>
ffffffffc02059b4:	000a7797          	auipc	a5,0xa7
ffffffffc02059b8:	b5478793          	addi	a5,a5,-1196 # ffffffffc02ac508 <va_pa_offset>
ffffffffc02059bc:	639c                	ld	a5,0(a5)
ffffffffc02059be:	577d                	li	a4,-1
ffffffffc02059c0:	177e                	slli	a4,a4,0x3f
ffffffffc02059c2:	8e9d                	sub	a3,a3,a5
ffffffffc02059c4:	00c6d793          	srli	a5,a3,0xc
ffffffffc02059c8:	f654                	sd	a3,168(a2)
ffffffffc02059ca:	8fd9                	or	a5,a5,a4
ffffffffc02059cc:	18079073          	csrw	satp,a5
    struct trapframe *tf = current->tf;
ffffffffc02059d0:	7240                	ld	s0,160(a2)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02059d2:	4581                	li	a1,0
ffffffffc02059d4:	12000613          	li	a2,288
    uintptr_t sstatus = tf->status;
ffffffffc02059d8:	10043483          	ld	s1,256(s0)
    memset(tf, 0, sizeof(struct trapframe));
ffffffffc02059dc:	8522                	mv	a0,s0
ffffffffc02059de:	411000ef          	jal	ra,ffffffffc02065ee <memset>
    tf->epc=elf->e_entry;
ffffffffc02059e2:	018b3703          	ld	a4,24(s6)
    tf->status=(sstatus|SSTATUS_SPIE)&(~SSTATUS_SPP);
ffffffffc02059e6:	edf4f493          	andi	s1,s1,-289
    tf->gpr.sp=USTACKTOP;
ffffffffc02059ea:	4785                	li	a5,1
    set_proc_name(current, local_name);
ffffffffc02059ec:	000a3503          	ld	a0,0(s4)
    tf->status=(sstatus|SSTATUS_SPIE)&(~SSTATUS_SPP);
ffffffffc02059f0:	0204e493          	ori	s1,s1,32
    tf->gpr.sp=USTACKTOP;
ffffffffc02059f4:	07fe                	slli	a5,a5,0x1f
ffffffffc02059f6:	e81c                	sd	a5,16(s0)
    tf->epc=elf->e_entry;
ffffffffc02059f8:	10e43423          	sd	a4,264(s0)
    tf->status=(sstatus|SSTATUS_SPIE)&(~SSTATUS_SPP);
ffffffffc02059fc:	10943023          	sd	s1,256(s0)
    set_proc_name(current, local_name);
ffffffffc0205a00:	100c                	addi	a1,sp,32
ffffffffc0205a02:	c94ff0ef          	jal	ra,ffffffffc0204e96 <set_proc_name>
}
ffffffffc0205a06:	60ea                	ld	ra,152(sp)
ffffffffc0205a08:	644a                	ld	s0,144(sp)
ffffffffc0205a0a:	854e                	mv	a0,s3
ffffffffc0205a0c:	64aa                	ld	s1,136(sp)
ffffffffc0205a0e:	690a                	ld	s2,128(sp)
ffffffffc0205a10:	79e6                	ld	s3,120(sp)
ffffffffc0205a12:	7a46                	ld	s4,112(sp)
ffffffffc0205a14:	7aa6                	ld	s5,104(sp)
ffffffffc0205a16:	7b06                	ld	s6,96(sp)
ffffffffc0205a18:	6be6                	ld	s7,88(sp)
ffffffffc0205a1a:	6c46                	ld	s8,80(sp)
ffffffffc0205a1c:	6ca6                	ld	s9,72(sp)
ffffffffc0205a1e:	6d06                	ld	s10,64(sp)
ffffffffc0205a20:	7de2                	ld	s11,56(sp)
ffffffffc0205a22:	610d                	addi	sp,sp,160
ffffffffc0205a24:	8082                	ret
        if (ph->p_filesz > ph->p_memsz) {
ffffffffc0205a26:	7410                	ld	a2,40(s0)
ffffffffc0205a28:	701c                	ld	a5,32(s0)
ffffffffc0205a2a:	20f66363          	bltu	a2,a5,ffffffffc0205c30 <do_execve+0x44e>
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205a2e:	405c                	lw	a5,4(s0)
ffffffffc0205a30:	0017f693          	andi	a3,a5,1
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205a34:	0027f713          	andi	a4,a5,2
        if (ph->p_flags & ELF_PF_X) vm_flags |= VM_EXEC;
ffffffffc0205a38:	068a                	slli	a3,a3,0x2
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205a3a:	0e071263          	bnez	a4,ffffffffc0205b1e <do_execve+0x33c>
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205a3e:	4745                	li	a4,17
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205a40:	8b91                	andi	a5,a5,4
        vm_flags = 0, perm = PTE_U | PTE_V;
ffffffffc0205a42:	e03a                	sd	a4,0(sp)
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205a44:	c789                	beqz	a5,ffffffffc0205a4e <do_execve+0x26c>
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205a46:	47cd                	li	a5,19
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205a48:	0016e693          	ori	a3,a3,1
        if (vm_flags & VM_READ) perm |= PTE_R;
ffffffffc0205a4c:	e03e                	sd	a5,0(sp)
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205a4e:	0026f793          	andi	a5,a3,2
ffffffffc0205a52:	efe1                	bnez	a5,ffffffffc0205b2a <do_execve+0x348>
        if (vm_flags & VM_EXEC) perm |= PTE_X;
ffffffffc0205a54:	0046f793          	andi	a5,a3,4
ffffffffc0205a58:	c789                	beqz	a5,ffffffffc0205a62 <do_execve+0x280>
ffffffffc0205a5a:	6782                	ld	a5,0(sp)
ffffffffc0205a5c:	0087e793          	ori	a5,a5,8
ffffffffc0205a60:	e03e                	sd	a5,0(sp)
        if ((ret = mm_map(mm, ph->p_va, ph->p_memsz, vm_flags, NULL)) != 0) {
ffffffffc0205a62:	680c                	ld	a1,16(s0)
ffffffffc0205a64:	4701                	li	a4,0
ffffffffc0205a66:	854a                	mv	a0,s2
ffffffffc0205a68:	82bfe0ef          	jal	ra,ffffffffc0204292 <mm_map>
ffffffffc0205a6c:	89aa                	mv	s3,a0
ffffffffc0205a6e:	e541                	bnez	a0,ffffffffc0205af6 <do_execve+0x314>
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a70:	01043b83          	ld	s7,16(s0)
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a74:	02043983          	ld	s3,32(s0)
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a78:	00843a83          	ld	s5,8(s0)
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a7c:	77fd                	lui	a5,0xfffff
        end = ph->p_va + ph->p_filesz;
ffffffffc0205a7e:	99de                	add	s3,s3,s7
        unsigned char *from = binary + ph->p_offset;
ffffffffc0205a80:	9ada                	add	s5,s5,s6
        uintptr_t start = ph->p_va, end, la = ROUNDDOWN(start, PGSIZE);
ffffffffc0205a82:	00fbfc33          	and	s8,s7,a5
        while (start < end) {
ffffffffc0205a86:	053bef63          	bltu	s7,s3,ffffffffc0205ae4 <do_execve+0x302>
ffffffffc0205a8a:	aa79                	j	ffffffffc0205c28 <do_execve+0x446>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205a8c:	6785                	lui	a5,0x1
ffffffffc0205a8e:	418b8533          	sub	a0,s7,s8
ffffffffc0205a92:	9c3e                	add	s8,s8,a5
ffffffffc0205a94:	417c0833          	sub	a6,s8,s7
            if (end < la) {
ffffffffc0205a98:	0189f463          	bleu	s8,s3,ffffffffc0205aa0 <do_execve+0x2be>
                size -= la - end;
ffffffffc0205a9c:	41798833          	sub	a6,s3,s7
    return page - pages + nbase;
ffffffffc0205aa0:	000db683          	ld	a3,0(s11)
ffffffffc0205aa4:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205aa8:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205aaa:	40d486b3          	sub	a3,s1,a3
ffffffffc0205aae:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205ab0:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205ab4:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205ab6:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205aba:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205abc:	16c5fc63          	bleu	a2,a1,ffffffffc0205c34 <do_execve+0x452>
ffffffffc0205ac0:	000a7797          	auipc	a5,0xa7
ffffffffc0205ac4:	a4878793          	addi	a5,a5,-1464 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0205ac8:	0007b883          	ld	a7,0(a5)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205acc:	85d6                	mv	a1,s5
ffffffffc0205ace:	8642                	mv	a2,a6
ffffffffc0205ad0:	96c6                	add	a3,a3,a7
ffffffffc0205ad2:	9536                	add	a0,a0,a3
            start += size, from += size;
ffffffffc0205ad4:	9bc2                	add	s7,s7,a6
ffffffffc0205ad6:	e842                	sd	a6,16(sp)
            memcpy(page2kva(page) + off, from, size);
ffffffffc0205ad8:	329000ef          	jal	ra,ffffffffc0206600 <memcpy>
            start += size, from += size;
ffffffffc0205adc:	6842                	ld	a6,16(sp)
ffffffffc0205ade:	9ac2                	add	s5,s5,a6
        while (start < end) {
ffffffffc0205ae0:	053bf863          	bleu	s3,s7,ffffffffc0205b30 <do_execve+0x34e>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205ae4:	01893503          	ld	a0,24(s2)
ffffffffc0205ae8:	6602                	ld	a2,0(sp)
ffffffffc0205aea:	85e2                	mv	a1,s8
ffffffffc0205aec:	801fd0ef          	jal	ra,ffffffffc02032ec <pgdir_alloc_page>
ffffffffc0205af0:	84aa                	mv	s1,a0
ffffffffc0205af2:	fd49                	bnez	a0,ffffffffc0205a8c <do_execve+0x2aa>
        ret = -E_NO_MEM;
ffffffffc0205af4:	59f1                	li	s3,-4
    exit_mmap(mm);
ffffffffc0205af6:	854a                	mv	a0,s2
ffffffffc0205af8:	8e9fe0ef          	jal	ra,ffffffffc02043e0 <exit_mmap>
    put_pgdir(mm);
ffffffffc0205afc:	854a                	mv	a0,s2
ffffffffc0205afe:	a8eff0ef          	jal	ra,ffffffffc0204d8c <put_pgdir>
    mm_destroy(mm);
ffffffffc0205b02:	854a                	mv	a0,s2
ffffffffc0205b04:	f3cfe0ef          	jal	ra,ffffffffc0204240 <mm_destroy>
    return ret;
ffffffffc0205b08:	b345                	j	ffffffffc02058a8 <do_execve+0xc6>
            exit_mmap(mm);
ffffffffc0205b0a:	854a                	mv	a0,s2
ffffffffc0205b0c:	8d5fe0ef          	jal	ra,ffffffffc02043e0 <exit_mmap>
            put_pgdir(mm);
ffffffffc0205b10:	854a                	mv	a0,s2
ffffffffc0205b12:	a7aff0ef          	jal	ra,ffffffffc0204d8c <put_pgdir>
            mm_destroy(mm);
ffffffffc0205b16:	854a                	mv	a0,s2
ffffffffc0205b18:	f28fe0ef          	jal	ra,ffffffffc0204240 <mm_destroy>
ffffffffc0205b1c:	bba1                	j	ffffffffc0205874 <do_execve+0x92>
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205b1e:	0026e693          	ori	a3,a3,2
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205b22:	8b91                	andi	a5,a5,4
        if (ph->p_flags & ELF_PF_W) vm_flags |= VM_WRITE;
ffffffffc0205b24:	2681                	sext.w	a3,a3
        if (ph->p_flags & ELF_PF_R) vm_flags |= VM_READ;
ffffffffc0205b26:	f20790e3          	bnez	a5,ffffffffc0205a46 <do_execve+0x264>
        if (vm_flags & VM_WRITE) perm |= (PTE_W | PTE_R);
ffffffffc0205b2a:	47dd                	li	a5,23
ffffffffc0205b2c:	e03e                	sd	a5,0(sp)
ffffffffc0205b2e:	b71d                	j	ffffffffc0205a54 <do_execve+0x272>
ffffffffc0205b30:	01043983          	ld	s3,16(s0)
        end = ph->p_va + ph->p_memsz;
ffffffffc0205b34:	7414                	ld	a3,40(s0)
ffffffffc0205b36:	99b6                	add	s3,s3,a3
        if (start < la) {
ffffffffc0205b38:	098bf163          	bleu	s8,s7,ffffffffc0205bba <do_execve+0x3d8>
            if (start == end) {
ffffffffc0205b3c:	df7988e3          	beq	s3,s7,ffffffffc020592c <do_execve+0x14a>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205b40:	6505                	lui	a0,0x1
ffffffffc0205b42:	955e                	add	a0,a0,s7
ffffffffc0205b44:	41850533          	sub	a0,a0,s8
                size -= la - end;
ffffffffc0205b48:	41798ab3          	sub	s5,s3,s7
            if (end < la) {
ffffffffc0205b4c:	0d89fb63          	bleu	s8,s3,ffffffffc0205c22 <do_execve+0x440>
    return page - pages + nbase;
ffffffffc0205b50:	000db683          	ld	a3,0(s11)
ffffffffc0205b54:	000d3583          	ld	a1,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205b58:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205b5a:	40d486b3          	sub	a3,s1,a3
ffffffffc0205b5e:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205b60:	000cb603          	ld	a2,0(s9)
    return page - pages + nbase;
ffffffffc0205b64:	96ae                	add	a3,a3,a1
    return KADDR(page2pa(page));
ffffffffc0205b66:	00f6f5b3          	and	a1,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205b6a:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205b6c:	0cc5f463          	bleu	a2,a1,ffffffffc0205c34 <do_execve+0x452>
ffffffffc0205b70:	000a7617          	auipc	a2,0xa7
ffffffffc0205b74:	99860613          	addi	a2,a2,-1640 # ffffffffc02ac508 <va_pa_offset>
ffffffffc0205b78:	00063803          	ld	a6,0(a2)
            memset(page2kva(page) + off, 0, size);
ffffffffc0205b7c:	4581                	li	a1,0
ffffffffc0205b7e:	8656                	mv	a2,s5
ffffffffc0205b80:	96c2                	add	a3,a3,a6
ffffffffc0205b82:	9536                	add	a0,a0,a3
ffffffffc0205b84:	26b000ef          	jal	ra,ffffffffc02065ee <memset>
            start += size;
ffffffffc0205b88:	017a8733          	add	a4,s5,s7
            assert((end < la && start == end) || (end >= la && start == la));
ffffffffc0205b8c:	0389f463          	bleu	s8,s3,ffffffffc0205bb4 <do_execve+0x3d2>
ffffffffc0205b90:	d8e98ee3          	beq	s3,a4,ffffffffc020592c <do_execve+0x14a>
ffffffffc0205b94:	00003697          	auipc	a3,0x3
ffffffffc0205b98:	85468693          	addi	a3,a3,-1964 # ffffffffc02083e8 <default_pmm_manager+0x1098>
ffffffffc0205b9c:	00001617          	auipc	a2,0x1
ffffffffc0205ba0:	06c60613          	addi	a2,a2,108 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0205ba4:	28b00593          	li	a1,651
ffffffffc0205ba8:	00003517          	auipc	a0,0x3
ffffffffc0205bac:	c6850513          	addi	a0,a0,-920 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205bb0:	8d5fa0ef          	jal	ra,ffffffffc0200484 <__panic>
ffffffffc0205bb4:	ff8710e3          	bne	a4,s8,ffffffffc0205b94 <do_execve+0x3b2>
ffffffffc0205bb8:	8be2                	mv	s7,s8
ffffffffc0205bba:	000a7a97          	auipc	s5,0xa7
ffffffffc0205bbe:	94ea8a93          	addi	s5,s5,-1714 # ffffffffc02ac508 <va_pa_offset>
        while (start < end) {
ffffffffc0205bc2:	053be763          	bltu	s7,s3,ffffffffc0205c10 <do_execve+0x42e>
ffffffffc0205bc6:	b39d                	j	ffffffffc020592c <do_execve+0x14a>
            off = start - la, size = PGSIZE - off, la += PGSIZE;
ffffffffc0205bc8:	6785                	lui	a5,0x1
ffffffffc0205bca:	418b8533          	sub	a0,s7,s8
ffffffffc0205bce:	9c3e                	add	s8,s8,a5
ffffffffc0205bd0:	417c0633          	sub	a2,s8,s7
            if (end < la) {
ffffffffc0205bd4:	0189f463          	bleu	s8,s3,ffffffffc0205bdc <do_execve+0x3fa>
                size -= la - end;
ffffffffc0205bd8:	41798633          	sub	a2,s3,s7
    return page - pages + nbase;
ffffffffc0205bdc:	000db683          	ld	a3,0(s11)
ffffffffc0205be0:	000d3803          	ld	a6,0(s10)
    return KADDR(page2pa(page));
ffffffffc0205be4:	67a2                	ld	a5,8(sp)
    return page - pages + nbase;
ffffffffc0205be6:	40d486b3          	sub	a3,s1,a3
ffffffffc0205bea:	8699                	srai	a3,a3,0x6
    return KADDR(page2pa(page));
ffffffffc0205bec:	000cb583          	ld	a1,0(s9)
    return page - pages + nbase;
ffffffffc0205bf0:	96c2                	add	a3,a3,a6
    return KADDR(page2pa(page));
ffffffffc0205bf2:	00f6f833          	and	a6,a3,a5
    return page2ppn(page) << PGSHIFT;
ffffffffc0205bf6:	06b2                	slli	a3,a3,0xc
    return KADDR(page2pa(page));
ffffffffc0205bf8:	02b87e63          	bleu	a1,a6,ffffffffc0205c34 <do_execve+0x452>
ffffffffc0205bfc:	000ab803          	ld	a6,0(s5)
            start += size;
ffffffffc0205c00:	9bb2                	add	s7,s7,a2
            memset(page2kva(page) + off, 0, size);
ffffffffc0205c02:	4581                	li	a1,0
ffffffffc0205c04:	96c2                	add	a3,a3,a6
ffffffffc0205c06:	9536                	add	a0,a0,a3
ffffffffc0205c08:	1e7000ef          	jal	ra,ffffffffc02065ee <memset>
        while (start < end) {
ffffffffc0205c0c:	d33bf0e3          	bleu	s3,s7,ffffffffc020592c <do_execve+0x14a>
            if ((page = pgdir_alloc_page(mm->pgdir, la, perm)) == NULL) {
ffffffffc0205c10:	01893503          	ld	a0,24(s2)
ffffffffc0205c14:	6602                	ld	a2,0(sp)
ffffffffc0205c16:	85e2                	mv	a1,s8
ffffffffc0205c18:	ed4fd0ef          	jal	ra,ffffffffc02032ec <pgdir_alloc_page>
ffffffffc0205c1c:	84aa                	mv	s1,a0
ffffffffc0205c1e:	f54d                	bnez	a0,ffffffffc0205bc8 <do_execve+0x3e6>
ffffffffc0205c20:	bdd1                	j	ffffffffc0205af4 <do_execve+0x312>
            off = start + PGSIZE - la, size = PGSIZE - off;
ffffffffc0205c22:	417c0ab3          	sub	s5,s8,s7
ffffffffc0205c26:	b72d                	j	ffffffffc0205b50 <do_execve+0x36e>
        while (start < end) {
ffffffffc0205c28:	89de                	mv	s3,s7
ffffffffc0205c2a:	b729                	j	ffffffffc0205b34 <do_execve+0x352>
        return -E_INVAL;
ffffffffc0205c2c:	59f5                	li	s3,-3
ffffffffc0205c2e:	bbe1                	j	ffffffffc0205a06 <do_execve+0x224>
            ret = -E_INVAL_ELF;
ffffffffc0205c30:	59e1                	li	s3,-8
ffffffffc0205c32:	b5d1                	j	ffffffffc0205af6 <do_execve+0x314>
ffffffffc0205c34:	00001617          	auipc	a2,0x1
ffffffffc0205c38:	76c60613          	addi	a2,a2,1900 # ffffffffc02073a0 <default_pmm_manager+0x50>
ffffffffc0205c3c:	06900593          	li	a1,105
ffffffffc0205c40:	00001517          	auipc	a0,0x1
ffffffffc0205c44:	78850513          	addi	a0,a0,1928 # ffffffffc02073c8 <default_pmm_manager+0x78>
ffffffffc0205c48:	83dfa0ef          	jal	ra,ffffffffc0200484 <__panic>
    current->cr3 = PADDR(mm->pgdir);
ffffffffc0205c4c:	00001617          	auipc	a2,0x1
ffffffffc0205c50:	78c60613          	addi	a2,a2,1932 # ffffffffc02073d8 <default_pmm_manager+0x88>
ffffffffc0205c54:	2a900593          	li	a1,681
ffffffffc0205c58:	00003517          	auipc	a0,0x3
ffffffffc0205c5c:	bb850513          	addi	a0,a0,-1096 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205c60:	825fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-4*PGSIZE , PTE_USER) != NULL);
ffffffffc0205c64:	00003697          	auipc	a3,0x3
ffffffffc0205c68:	89c68693          	addi	a3,a3,-1892 # ffffffffc0208500 <default_pmm_manager+0x11b0>
ffffffffc0205c6c:	00001617          	auipc	a2,0x1
ffffffffc0205c70:	f9c60613          	addi	a2,a2,-100 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0205c74:	2a400593          	li	a1,676
ffffffffc0205c78:	00003517          	auipc	a0,0x3
ffffffffc0205c7c:	b9850513          	addi	a0,a0,-1128 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205c80:	805fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-3*PGSIZE , PTE_USER) != NULL);
ffffffffc0205c84:	00003697          	auipc	a3,0x3
ffffffffc0205c88:	83468693          	addi	a3,a3,-1996 # ffffffffc02084b8 <default_pmm_manager+0x1168>
ffffffffc0205c8c:	00001617          	auipc	a2,0x1
ffffffffc0205c90:	f7c60613          	addi	a2,a2,-132 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0205c94:	2a300593          	li	a1,675
ffffffffc0205c98:	00003517          	auipc	a0,0x3
ffffffffc0205c9c:	b7850513          	addi	a0,a0,-1160 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205ca0:	fe4fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-2*PGSIZE , PTE_USER) != NULL);
ffffffffc0205ca4:	00002697          	auipc	a3,0x2
ffffffffc0205ca8:	7cc68693          	addi	a3,a3,1996 # ffffffffc0208470 <default_pmm_manager+0x1120>
ffffffffc0205cac:	00001617          	auipc	a2,0x1
ffffffffc0205cb0:	f5c60613          	addi	a2,a2,-164 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0205cb4:	2a200593          	li	a1,674
ffffffffc0205cb8:	00003517          	auipc	a0,0x3
ffffffffc0205cbc:	b5850513          	addi	a0,a0,-1192 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205cc0:	fc4fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(pgdir_alloc_page(mm->pgdir, USTACKTOP-PGSIZE , PTE_USER) != NULL);
ffffffffc0205cc4:	00002697          	auipc	a3,0x2
ffffffffc0205cc8:	76468693          	addi	a3,a3,1892 # ffffffffc0208428 <default_pmm_manager+0x10d8>
ffffffffc0205ccc:	00001617          	auipc	a2,0x1
ffffffffc0205cd0:	f3c60613          	addi	a2,a2,-196 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0205cd4:	2a100593          	li	a1,673
ffffffffc0205cd8:	00003517          	auipc	a0,0x3
ffffffffc0205cdc:	b3850513          	addi	a0,a0,-1224 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205ce0:	fa4fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205ce4 <do_yield>:
    current->need_resched = 1;
ffffffffc0205ce4:	000a6797          	auipc	a5,0xa6
ffffffffc0205ce8:	7dc78793          	addi	a5,a5,2012 # ffffffffc02ac4c0 <current>
ffffffffc0205cec:	639c                	ld	a5,0(a5)
ffffffffc0205cee:	4705                	li	a4,1
}
ffffffffc0205cf0:	4501                	li	a0,0
    current->need_resched = 1;
ffffffffc0205cf2:	ef98                	sd	a4,24(a5)
}
ffffffffc0205cf4:	8082                	ret

ffffffffc0205cf6 <do_wait>:
do_wait(int pid, int *code_store) {
ffffffffc0205cf6:	1101                	addi	sp,sp,-32
ffffffffc0205cf8:	e822                	sd	s0,16(sp)
ffffffffc0205cfa:	e426                	sd	s1,8(sp)
ffffffffc0205cfc:	ec06                	sd	ra,24(sp)
ffffffffc0205cfe:	842e                	mv	s0,a1
ffffffffc0205d00:	84aa                	mv	s1,a0
    if (code_store != NULL) {
ffffffffc0205d02:	cd81                	beqz	a1,ffffffffc0205d1a <do_wait+0x24>
    struct mm_struct *mm = current->mm;
ffffffffc0205d04:	000a6797          	auipc	a5,0xa6
ffffffffc0205d08:	7bc78793          	addi	a5,a5,1980 # ffffffffc02ac4c0 <current>
ffffffffc0205d0c:	639c                	ld	a5,0(a5)
        if (!user_mem_check(mm, (uintptr_t)code_store, sizeof(int), 1)) {
ffffffffc0205d0e:	4685                	li	a3,1
ffffffffc0205d10:	4611                	li	a2,4
ffffffffc0205d12:	7788                	ld	a0,40(a5)
ffffffffc0205d14:	d6ffe0ef          	jal	ra,ffffffffc0204a82 <user_mem_check>
ffffffffc0205d18:	c909                	beqz	a0,ffffffffc0205d2a <do_wait+0x34>
ffffffffc0205d1a:	85a2                	mv	a1,s0
}
ffffffffc0205d1c:	6442                	ld	s0,16(sp)
ffffffffc0205d1e:	60e2                	ld	ra,24(sp)
ffffffffc0205d20:	8526                	mv	a0,s1
ffffffffc0205d22:	64a2                	ld	s1,8(sp)
ffffffffc0205d24:	6105                	addi	sp,sp,32
ffffffffc0205d26:	fecff06f          	j	ffffffffc0205512 <do_wait.part.1>
ffffffffc0205d2a:	60e2                	ld	ra,24(sp)
ffffffffc0205d2c:	6442                	ld	s0,16(sp)
ffffffffc0205d2e:	64a2                	ld	s1,8(sp)
ffffffffc0205d30:	5575                	li	a0,-3
ffffffffc0205d32:	6105                	addi	sp,sp,32
ffffffffc0205d34:	8082                	ret

ffffffffc0205d36 <do_kill>:
do_kill(int pid) {
ffffffffc0205d36:	1141                	addi	sp,sp,-16
ffffffffc0205d38:	e406                	sd	ra,8(sp)
ffffffffc0205d3a:	e022                	sd	s0,0(sp)
    if ((proc = find_proc(pid)) != NULL) {
ffffffffc0205d3c:	9f0ff0ef          	jal	ra,ffffffffc0204f2c <find_proc>
ffffffffc0205d40:	cd0d                	beqz	a0,ffffffffc0205d7a <do_kill+0x44>
        if (!(proc->flags & PF_EXITING)) {
ffffffffc0205d42:	0b052703          	lw	a4,176(a0)
ffffffffc0205d46:	00177693          	andi	a3,a4,1
ffffffffc0205d4a:	e695                	bnez	a3,ffffffffc0205d76 <do_kill+0x40>
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205d4c:	0ec52683          	lw	a3,236(a0)
            proc->flags |= PF_EXITING;
ffffffffc0205d50:	00176713          	ori	a4,a4,1
ffffffffc0205d54:	0ae52823          	sw	a4,176(a0)
            return 0;
ffffffffc0205d58:	4401                	li	s0,0
            if (proc->wait_state & WT_INTERRUPTED) {
ffffffffc0205d5a:	0006c763          	bltz	a3,ffffffffc0205d68 <do_kill+0x32>
}
ffffffffc0205d5e:	8522                	mv	a0,s0
ffffffffc0205d60:	60a2                	ld	ra,8(sp)
ffffffffc0205d62:	6402                	ld	s0,0(sp)
ffffffffc0205d64:	0141                	addi	sp,sp,16
ffffffffc0205d66:	8082                	ret
                wakeup_proc(proc);
ffffffffc0205d68:	1e6000ef          	jal	ra,ffffffffc0205f4e <wakeup_proc>
}
ffffffffc0205d6c:	8522                	mv	a0,s0
ffffffffc0205d6e:	60a2                	ld	ra,8(sp)
ffffffffc0205d70:	6402                	ld	s0,0(sp)
ffffffffc0205d72:	0141                	addi	sp,sp,16
ffffffffc0205d74:	8082                	ret
        return -E_KILLED;
ffffffffc0205d76:	545d                	li	s0,-9
ffffffffc0205d78:	b7dd                	j	ffffffffc0205d5e <do_kill+0x28>
    return -E_INVAL;
ffffffffc0205d7a:	5475                	li	s0,-3
ffffffffc0205d7c:	b7cd                	j	ffffffffc0205d5e <do_kill+0x28>

ffffffffc0205d7e <proc_init>:
    elm->prev = elm->next = elm;
ffffffffc0205d7e:	000a7797          	auipc	a5,0xa7
ffffffffc0205d82:	88278793          	addi	a5,a5,-1918 # ffffffffc02ac600 <proc_list>

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
void
proc_init(void) {
ffffffffc0205d86:	1101                	addi	sp,sp,-32
ffffffffc0205d88:	000a7717          	auipc	a4,0xa7
ffffffffc0205d8c:	88f73023          	sd	a5,-1920(a4) # ffffffffc02ac608 <proc_list+0x8>
ffffffffc0205d90:	000a7717          	auipc	a4,0xa7
ffffffffc0205d94:	86f73823          	sd	a5,-1936(a4) # ffffffffc02ac600 <proc_list>
ffffffffc0205d98:	ec06                	sd	ra,24(sp)
ffffffffc0205d9a:	e822                	sd	s0,16(sp)
ffffffffc0205d9c:	e426                	sd	s1,8(sp)
ffffffffc0205d9e:	000a2797          	auipc	a5,0xa2
ffffffffc0205da2:	6ea78793          	addi	a5,a5,1770 # ffffffffc02a8488 <hash_list>
ffffffffc0205da6:	000a6717          	auipc	a4,0xa6
ffffffffc0205daa:	6e270713          	addi	a4,a4,1762 # ffffffffc02ac488 <is_panic>
ffffffffc0205dae:	e79c                	sd	a5,8(a5)
ffffffffc0205db0:	e39c                	sd	a5,0(a5)
ffffffffc0205db2:	07c1                	addi	a5,a5,16
    int i;

    list_init(&proc_list);
    for (i = 0; i < HASH_LIST_SIZE; i ++) {
ffffffffc0205db4:	fee79de3          	bne	a5,a4,ffffffffc0205dae <proc_init+0x30>
        list_init(hash_list + i);
    }

    if ((idleproc = alloc_proc()) == NULL) {
ffffffffc0205db8:	ecffe0ef          	jal	ra,ffffffffc0204c86 <alloc_proc>
ffffffffc0205dbc:	000a6717          	auipc	a4,0xa6
ffffffffc0205dc0:	70a73623          	sd	a0,1804(a4) # ffffffffc02ac4c8 <idleproc>
ffffffffc0205dc4:	000a6497          	auipc	s1,0xa6
ffffffffc0205dc8:	70448493          	addi	s1,s1,1796 # ffffffffc02ac4c8 <idleproc>
ffffffffc0205dcc:	c559                	beqz	a0,ffffffffc0205e5a <proc_init+0xdc>
        panic("cannot alloc idleproc.\n");
    }

    idleproc->pid = 0;
    idleproc->state = PROC_RUNNABLE;
ffffffffc0205dce:	4709                	li	a4,2
ffffffffc0205dd0:	e118                	sd	a4,0(a0)
    idleproc->kstack = (uintptr_t)bootstack;
    idleproc->need_resched = 1;
ffffffffc0205dd2:	4405                	li	s0,1
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205dd4:	00003717          	auipc	a4,0x3
ffffffffc0205dd8:	22c70713          	addi	a4,a4,556 # ffffffffc0209000 <bootstack>
    set_proc_name(idleproc, "idle");
ffffffffc0205ddc:	00003597          	auipc	a1,0x3
ffffffffc0205de0:	94c58593          	addi	a1,a1,-1716 # ffffffffc0208728 <default_pmm_manager+0x13d8>
    idleproc->kstack = (uintptr_t)bootstack;
ffffffffc0205de4:	e918                	sd	a4,16(a0)
    idleproc->need_resched = 1;
ffffffffc0205de6:	ed00                	sd	s0,24(a0)
    set_proc_name(idleproc, "idle");
ffffffffc0205de8:	8aeff0ef          	jal	ra,ffffffffc0204e96 <set_proc_name>
    nr_process ++;
ffffffffc0205dec:	000a6797          	auipc	a5,0xa6
ffffffffc0205df0:	6ec78793          	addi	a5,a5,1772 # ffffffffc02ac4d8 <nr_process>
ffffffffc0205df4:	439c                	lw	a5,0(a5)

    current = idleproc;
ffffffffc0205df6:	6098                	ld	a4,0(s1)

    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205df8:	4601                	li	a2,0
    nr_process ++;
ffffffffc0205dfa:	2785                	addiw	a5,a5,1
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205dfc:	4581                	li	a1,0
ffffffffc0205dfe:	00000517          	auipc	a0,0x0
ffffffffc0205e02:	8bc50513          	addi	a0,a0,-1860 # ffffffffc02056ba <init_main>
    nr_process ++;
ffffffffc0205e06:	000a6697          	auipc	a3,0xa6
ffffffffc0205e0a:	6cf6a923          	sw	a5,1746(a3) # ffffffffc02ac4d8 <nr_process>
    current = idleproc;
ffffffffc0205e0e:	000a6797          	auipc	a5,0xa6
ffffffffc0205e12:	6ae7b923          	sd	a4,1714(a5) # ffffffffc02ac4c0 <current>
    int pid = kernel_thread(init_main, NULL, 0);
ffffffffc0205e16:	d5eff0ef          	jal	ra,ffffffffc0205374 <kernel_thread>
    if (pid <= 0) {
ffffffffc0205e1a:	08a05c63          	blez	a0,ffffffffc0205eb2 <proc_init+0x134>
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
ffffffffc0205e1e:	90eff0ef          	jal	ra,ffffffffc0204f2c <find_proc>
    set_proc_name(initproc, "init");
ffffffffc0205e22:	00003597          	auipc	a1,0x3
ffffffffc0205e26:	92e58593          	addi	a1,a1,-1746 # ffffffffc0208750 <default_pmm_manager+0x1400>
    initproc = find_proc(pid);
ffffffffc0205e2a:	000a6797          	auipc	a5,0xa6
ffffffffc0205e2e:	6aa7b323          	sd	a0,1702(a5) # ffffffffc02ac4d0 <initproc>
    set_proc_name(initproc, "init");
ffffffffc0205e32:	864ff0ef          	jal	ra,ffffffffc0204e96 <set_proc_name>

    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205e36:	609c                	ld	a5,0(s1)
ffffffffc0205e38:	cfa9                	beqz	a5,ffffffffc0205e92 <proc_init+0x114>
ffffffffc0205e3a:	43dc                	lw	a5,4(a5)
ffffffffc0205e3c:	ebb9                	bnez	a5,ffffffffc0205e92 <proc_init+0x114>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205e3e:	000a6797          	auipc	a5,0xa6
ffffffffc0205e42:	69278793          	addi	a5,a5,1682 # ffffffffc02ac4d0 <initproc>
ffffffffc0205e46:	639c                	ld	a5,0(a5)
ffffffffc0205e48:	c78d                	beqz	a5,ffffffffc0205e72 <proc_init+0xf4>
ffffffffc0205e4a:	43dc                	lw	a5,4(a5)
ffffffffc0205e4c:	02879363          	bne	a5,s0,ffffffffc0205e72 <proc_init+0xf4>
}
ffffffffc0205e50:	60e2                	ld	ra,24(sp)
ffffffffc0205e52:	6442                	ld	s0,16(sp)
ffffffffc0205e54:	64a2                	ld	s1,8(sp)
ffffffffc0205e56:	6105                	addi	sp,sp,32
ffffffffc0205e58:	8082                	ret
        panic("cannot alloc idleproc.\n");
ffffffffc0205e5a:	00003617          	auipc	a2,0x3
ffffffffc0205e5e:	8b660613          	addi	a2,a2,-1866 # ffffffffc0208710 <default_pmm_manager+0x13c0>
ffffffffc0205e62:	3ad00593          	li	a1,941
ffffffffc0205e66:	00003517          	auipc	a0,0x3
ffffffffc0205e6a:	9aa50513          	addi	a0,a0,-1622 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205e6e:	e16fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(initproc != NULL && initproc->pid == 1);
ffffffffc0205e72:	00003697          	auipc	a3,0x3
ffffffffc0205e76:	90e68693          	addi	a3,a3,-1778 # ffffffffc0208780 <default_pmm_manager+0x1430>
ffffffffc0205e7a:	00001617          	auipc	a2,0x1
ffffffffc0205e7e:	d8e60613          	addi	a2,a2,-626 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0205e82:	3c200593          	li	a1,962
ffffffffc0205e86:	00003517          	auipc	a0,0x3
ffffffffc0205e8a:	98a50513          	addi	a0,a0,-1654 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205e8e:	df6fa0ef          	jal	ra,ffffffffc0200484 <__panic>
    assert(idleproc != NULL && idleproc->pid == 0);
ffffffffc0205e92:	00003697          	auipc	a3,0x3
ffffffffc0205e96:	8c668693          	addi	a3,a3,-1850 # ffffffffc0208758 <default_pmm_manager+0x1408>
ffffffffc0205e9a:	00001617          	auipc	a2,0x1
ffffffffc0205e9e:	d6e60613          	addi	a2,a2,-658 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0205ea2:	3c100593          	li	a1,961
ffffffffc0205ea6:	00003517          	auipc	a0,0x3
ffffffffc0205eaa:	96a50513          	addi	a0,a0,-1686 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205eae:	dd6fa0ef          	jal	ra,ffffffffc0200484 <__panic>
        panic("create init_main failed.\n");
ffffffffc0205eb2:	00003617          	auipc	a2,0x3
ffffffffc0205eb6:	87e60613          	addi	a2,a2,-1922 # ffffffffc0208730 <default_pmm_manager+0x13e0>
ffffffffc0205eba:	3bb00593          	li	a1,955
ffffffffc0205ebe:	00003517          	auipc	a0,0x3
ffffffffc0205ec2:	95250513          	addi	a0,a0,-1710 # ffffffffc0208810 <default_pmm_manager+0x14c0>
ffffffffc0205ec6:	dbefa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205eca <cpu_idle>:

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
ffffffffc0205eca:	1141                	addi	sp,sp,-16
ffffffffc0205ecc:	e022                	sd	s0,0(sp)
ffffffffc0205ece:	e406                	sd	ra,8(sp)
ffffffffc0205ed0:	000a6417          	auipc	s0,0xa6
ffffffffc0205ed4:	5f040413          	addi	s0,s0,1520 # ffffffffc02ac4c0 <current>
    while (1) {
        if (current->need_resched) {
ffffffffc0205ed8:	6018                	ld	a4,0(s0)
ffffffffc0205eda:	6f1c                	ld	a5,24(a4)
ffffffffc0205edc:	dffd                	beqz	a5,ffffffffc0205eda <cpu_idle+0x10>
            schedule();
ffffffffc0205ede:	0ec000ef          	jal	ra,ffffffffc0205fca <schedule>
ffffffffc0205ee2:	bfdd                	j	ffffffffc0205ed8 <cpu_idle+0xe>

ffffffffc0205ee4 <switch_to>:
.text
# void switch_to(struct proc_struct* from, struct proc_struct* to)
.globl switch_to
switch_to:
    # save from's registers
    STORE ra, 0*REGBYTES(a0)
ffffffffc0205ee4:	00153023          	sd	ra,0(a0)
    STORE sp, 1*REGBYTES(a0)
ffffffffc0205ee8:	00253423          	sd	sp,8(a0)
    STORE s0, 2*REGBYTES(a0)
ffffffffc0205eec:	e900                	sd	s0,16(a0)
    STORE s1, 3*REGBYTES(a0)
ffffffffc0205eee:	ed04                	sd	s1,24(a0)
    STORE s2, 4*REGBYTES(a0)
ffffffffc0205ef0:	03253023          	sd	s2,32(a0)
    STORE s3, 5*REGBYTES(a0)
ffffffffc0205ef4:	03353423          	sd	s3,40(a0)
    STORE s4, 6*REGBYTES(a0)
ffffffffc0205ef8:	03453823          	sd	s4,48(a0)
    STORE s5, 7*REGBYTES(a0)
ffffffffc0205efc:	03553c23          	sd	s5,56(a0)
    STORE s6, 8*REGBYTES(a0)
ffffffffc0205f00:	05653023          	sd	s6,64(a0)
    STORE s7, 9*REGBYTES(a0)
ffffffffc0205f04:	05753423          	sd	s7,72(a0)
    STORE s8, 10*REGBYTES(a0)
ffffffffc0205f08:	05853823          	sd	s8,80(a0)
    STORE s9, 11*REGBYTES(a0)
ffffffffc0205f0c:	05953c23          	sd	s9,88(a0)
    STORE s10, 12*REGBYTES(a0)
ffffffffc0205f10:	07a53023          	sd	s10,96(a0)
    STORE s11, 13*REGBYTES(a0)
ffffffffc0205f14:	07b53423          	sd	s11,104(a0)

    # restore to's registers
    LOAD ra, 0*REGBYTES(a1)
ffffffffc0205f18:	0005b083          	ld	ra,0(a1)
    LOAD sp, 1*REGBYTES(a1)
ffffffffc0205f1c:	0085b103          	ld	sp,8(a1)
    LOAD s0, 2*REGBYTES(a1)
ffffffffc0205f20:	6980                	ld	s0,16(a1)
    LOAD s1, 3*REGBYTES(a1)
ffffffffc0205f22:	6d84                	ld	s1,24(a1)
    LOAD s2, 4*REGBYTES(a1)
ffffffffc0205f24:	0205b903          	ld	s2,32(a1)
    LOAD s3, 5*REGBYTES(a1)
ffffffffc0205f28:	0285b983          	ld	s3,40(a1)
    LOAD s4, 6*REGBYTES(a1)
ffffffffc0205f2c:	0305ba03          	ld	s4,48(a1)
    LOAD s5, 7*REGBYTES(a1)
ffffffffc0205f30:	0385ba83          	ld	s5,56(a1)
    LOAD s6, 8*REGBYTES(a1)
ffffffffc0205f34:	0405bb03          	ld	s6,64(a1)
    LOAD s7, 9*REGBYTES(a1)
ffffffffc0205f38:	0485bb83          	ld	s7,72(a1)
    LOAD s8, 10*REGBYTES(a1)
ffffffffc0205f3c:	0505bc03          	ld	s8,80(a1)
    LOAD s9, 11*REGBYTES(a1)
ffffffffc0205f40:	0585bc83          	ld	s9,88(a1)
    LOAD s10, 12*REGBYTES(a1)
ffffffffc0205f44:	0605bd03          	ld	s10,96(a1)
    LOAD s11, 13*REGBYTES(a1)
ffffffffc0205f48:	0685bd83          	ld	s11,104(a1)

    ret
ffffffffc0205f4c:	8082                	ret

ffffffffc0205f4e <wakeup_proc>:
#include <sched.h>
#include <assert.h>

void
wakeup_proc(struct proc_struct *proc) {
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f4e:	4118                	lw	a4,0(a0)
wakeup_proc(struct proc_struct *proc) {
ffffffffc0205f50:	1101                	addi	sp,sp,-32
ffffffffc0205f52:	ec06                	sd	ra,24(sp)
ffffffffc0205f54:	e822                	sd	s0,16(sp)
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205f56:	478d                	li	a5,3
ffffffffc0205f58:	04f70a63          	beq	a4,a5,ffffffffc0205fac <wakeup_proc+0x5e>
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f5c:	100027f3          	csrr	a5,sstatus
ffffffffc0205f60:	8b89                	andi	a5,a5,2
    return 0;
ffffffffc0205f62:	4401                	li	s0,0
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205f64:	ef8d                	bnez	a5,ffffffffc0205f9e <wakeup_proc+0x50>
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        if (proc->state != PROC_RUNNABLE) {
ffffffffc0205f66:	4789                	li	a5,2
ffffffffc0205f68:	00f70f63          	beq	a4,a5,ffffffffc0205f86 <wakeup_proc+0x38>
            proc->state = PROC_RUNNABLE;
ffffffffc0205f6c:	c11c                	sw	a5,0(a0)
            proc->wait_state = 0;
ffffffffc0205f6e:	0e052623          	sw	zero,236(a0)
    if (flag) {
ffffffffc0205f72:	e409                	bnez	s0,ffffffffc0205f7c <wakeup_proc+0x2e>
        else {
            warn("wakeup runnable process.\n");
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc0205f74:	60e2                	ld	ra,24(sp)
ffffffffc0205f76:	6442                	ld	s0,16(sp)
ffffffffc0205f78:	6105                	addi	sp,sp,32
ffffffffc0205f7a:	8082                	ret
ffffffffc0205f7c:	6442                	ld	s0,16(sp)
ffffffffc0205f7e:	60e2                	ld	ra,24(sp)
ffffffffc0205f80:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc0205f82:	ed2fa06f          	j	ffffffffc0200654 <intr_enable>
            warn("wakeup runnable process.\n");
ffffffffc0205f86:	00003617          	auipc	a2,0x3
ffffffffc0205f8a:	8da60613          	addi	a2,a2,-1830 # ffffffffc0208860 <default_pmm_manager+0x1510>
ffffffffc0205f8e:	45c9                	li	a1,18
ffffffffc0205f90:	00003517          	auipc	a0,0x3
ffffffffc0205f94:	8b850513          	addi	a0,a0,-1864 # ffffffffc0208848 <default_pmm_manager+0x14f8>
ffffffffc0205f98:	d58fa0ef          	jal	ra,ffffffffc02004f0 <__warn>
ffffffffc0205f9c:	bfd9                	j	ffffffffc0205f72 <wakeup_proc+0x24>
ffffffffc0205f9e:	e42a                	sd	a0,8(sp)
        intr_disable();
ffffffffc0205fa0:	ebafa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc0205fa4:	6522                	ld	a0,8(sp)
ffffffffc0205fa6:	4405                	li	s0,1
ffffffffc0205fa8:	4118                	lw	a4,0(a0)
ffffffffc0205faa:	bf75                	j	ffffffffc0205f66 <wakeup_proc+0x18>
    assert(proc->state != PROC_ZOMBIE);
ffffffffc0205fac:	00003697          	auipc	a3,0x3
ffffffffc0205fb0:	87c68693          	addi	a3,a3,-1924 # ffffffffc0208828 <default_pmm_manager+0x14d8>
ffffffffc0205fb4:	00001617          	auipc	a2,0x1
ffffffffc0205fb8:	c5460613          	addi	a2,a2,-940 # ffffffffc0206c08 <commands+0x4c0>
ffffffffc0205fbc:	45a5                	li	a1,9
ffffffffc0205fbe:	00003517          	auipc	a0,0x3
ffffffffc0205fc2:	88a50513          	addi	a0,a0,-1910 # ffffffffc0208848 <default_pmm_manager+0x14f8>
ffffffffc0205fc6:	cbefa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0205fca <schedule>:

void
schedule(void) {
ffffffffc0205fca:	1141                	addi	sp,sp,-16
ffffffffc0205fcc:	e406                	sd	ra,8(sp)
ffffffffc0205fce:	e022                	sd	s0,0(sp)
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0205fd0:	100027f3          	csrr	a5,sstatus
ffffffffc0205fd4:	8b89                	andi	a5,a5,2
ffffffffc0205fd6:	4401                	li	s0,0
ffffffffc0205fd8:	e3d1                	bnez	a5,ffffffffc020605c <schedule+0x92>
    bool intr_flag;
    list_entry_t *le, *last;
    struct proc_struct *next = NULL;
    local_intr_save(intr_flag);
    {
        current->need_resched = 0;
ffffffffc0205fda:	000a6797          	auipc	a5,0xa6
ffffffffc0205fde:	4e678793          	addi	a5,a5,1254 # ffffffffc02ac4c0 <current>
ffffffffc0205fe2:	0007b883          	ld	a7,0(a5)
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205fe6:	000a6797          	auipc	a5,0xa6
ffffffffc0205fea:	4e278793          	addi	a5,a5,1250 # ffffffffc02ac4c8 <idleproc>
ffffffffc0205fee:	6388                	ld	a0,0(a5)
        current->need_resched = 0;
ffffffffc0205ff0:	0008bc23          	sd	zero,24(a7) # 2018 <_binary_obj___user_faultread_out_size-0x7568>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0205ff4:	04a88e63          	beq	a7,a0,ffffffffc0206050 <schedule+0x86>
ffffffffc0205ff8:	0c888693          	addi	a3,a7,200
ffffffffc0205ffc:	000a6617          	auipc	a2,0xa6
ffffffffc0206000:	60460613          	addi	a2,a2,1540 # ffffffffc02ac600 <proc_list>
        le = last;
ffffffffc0206004:	87b6                	mv	a5,a3
    struct proc_struct *next = NULL;
ffffffffc0206006:	4581                	li	a1,0
        do {
            if ((le = list_next(le)) != &proc_list) {
                next = le2proc(le, list_link);
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206008:	4809                	li	a6,2
    return listelm->next;
ffffffffc020600a:	679c                	ld	a5,8(a5)
            if ((le = list_next(le)) != &proc_list) {
ffffffffc020600c:	00c78863          	beq	a5,a2,ffffffffc020601c <schedule+0x52>
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206010:	f387a703          	lw	a4,-200(a5)
                next = le2proc(le, list_link);
ffffffffc0206014:	f3878593          	addi	a1,a5,-200
                if (next->state == PROC_RUNNABLE) {
ffffffffc0206018:	01070463          	beq	a4,a6,ffffffffc0206020 <schedule+0x56>
                    break;
                }
            }
        } while (le != last);
ffffffffc020601c:	fef697e3          	bne	a3,a5,ffffffffc020600a <schedule+0x40>
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206020:	c589                	beqz	a1,ffffffffc020602a <schedule+0x60>
ffffffffc0206022:	4198                	lw	a4,0(a1)
ffffffffc0206024:	4789                	li	a5,2
ffffffffc0206026:	00f70e63          	beq	a4,a5,ffffffffc0206042 <schedule+0x78>
            next = idleproc;
        }
        next->runs ++;
ffffffffc020602a:	451c                	lw	a5,8(a0)
ffffffffc020602c:	2785                	addiw	a5,a5,1
ffffffffc020602e:	c51c                	sw	a5,8(a0)
        //调度的进程不能为当前进程
        if (next != current) {
ffffffffc0206030:	00a88463          	beq	a7,a0,ffffffffc0206038 <schedule+0x6e>
            proc_run(next);
ffffffffc0206034:	e8dfe0ef          	jal	ra,ffffffffc0204ec0 <proc_run>
    if (flag) {
ffffffffc0206038:	e419                	bnez	s0,ffffffffc0206046 <schedule+0x7c>
        }
    }
    local_intr_restore(intr_flag);
}
ffffffffc020603a:	60a2                	ld	ra,8(sp)
ffffffffc020603c:	6402                	ld	s0,0(sp)
ffffffffc020603e:	0141                	addi	sp,sp,16
ffffffffc0206040:	8082                	ret
        if (next == NULL || next->state != PROC_RUNNABLE) {
ffffffffc0206042:	852e                	mv	a0,a1
ffffffffc0206044:	b7dd                	j	ffffffffc020602a <schedule+0x60>
}
ffffffffc0206046:	6402                	ld	s0,0(sp)
ffffffffc0206048:	60a2                	ld	ra,8(sp)
ffffffffc020604a:	0141                	addi	sp,sp,16
        intr_enable();
ffffffffc020604c:	e08fa06f          	j	ffffffffc0200654 <intr_enable>
        last = (current == idleproc) ? &proc_list : &(current->list_link);
ffffffffc0206050:	000a6617          	auipc	a2,0xa6
ffffffffc0206054:	5b060613          	addi	a2,a2,1456 # ffffffffc02ac600 <proc_list>
ffffffffc0206058:	86b2                	mv	a3,a2
ffffffffc020605a:	b76d                	j	ffffffffc0206004 <schedule+0x3a>
        intr_disable();
ffffffffc020605c:	dfefa0ef          	jal	ra,ffffffffc020065a <intr_disable>
        return 1;
ffffffffc0206060:	4405                	li	s0,1
ffffffffc0206062:	bfa5                	j	ffffffffc0205fda <schedule+0x10>

ffffffffc0206064 <sys_getpid>:
    return do_kill(pid);
}

static int
sys_getpid(uint64_t arg[]) {
    return current->pid;
ffffffffc0206064:	000a6797          	auipc	a5,0xa6
ffffffffc0206068:	45c78793          	addi	a5,a5,1116 # ffffffffc02ac4c0 <current>
ffffffffc020606c:	639c                	ld	a5,0(a5)
}
ffffffffc020606e:	43c8                	lw	a0,4(a5)
ffffffffc0206070:	8082                	ret

ffffffffc0206072 <sys_pgdir>:

static int
sys_pgdir(uint64_t arg[]) {
    //print_pgdir();
    return 0;
}
ffffffffc0206072:	4501                	li	a0,0
ffffffffc0206074:	8082                	ret

ffffffffc0206076 <sys_putc>:
    cputchar(c);
ffffffffc0206076:	4108                	lw	a0,0(a0)
sys_putc(uint64_t arg[]) {
ffffffffc0206078:	1141                	addi	sp,sp,-16
ffffffffc020607a:	e406                	sd	ra,8(sp)
    cputchar(c);
ffffffffc020607c:	946fa0ef          	jal	ra,ffffffffc02001c2 <cputchar>
}
ffffffffc0206080:	60a2                	ld	ra,8(sp)
ffffffffc0206082:	4501                	li	a0,0
ffffffffc0206084:	0141                	addi	sp,sp,16
ffffffffc0206086:	8082                	ret

ffffffffc0206088 <sys_kill>:
    return do_kill(pid);
ffffffffc0206088:	4108                	lw	a0,0(a0)
ffffffffc020608a:	cadff06f          	j	ffffffffc0205d36 <do_kill>

ffffffffc020608e <sys_yield>:
    return do_yield();
ffffffffc020608e:	c57ff06f          	j	ffffffffc0205ce4 <do_yield>

ffffffffc0206092 <sys_exec>:
    return do_execve(name, len, binary, size);
ffffffffc0206092:	6d14                	ld	a3,24(a0)
ffffffffc0206094:	6910                	ld	a2,16(a0)
ffffffffc0206096:	650c                	ld	a1,8(a0)
ffffffffc0206098:	6108                	ld	a0,0(a0)
ffffffffc020609a:	f48ff06f          	j	ffffffffc02057e2 <do_execve>

ffffffffc020609e <sys_wait>:
    return do_wait(pid, store);
ffffffffc020609e:	650c                	ld	a1,8(a0)
ffffffffc02060a0:	4108                	lw	a0,0(a0)
ffffffffc02060a2:	c55ff06f          	j	ffffffffc0205cf6 <do_wait>

ffffffffc02060a6 <sys_fork>:
    struct trapframe *tf = current->tf;
ffffffffc02060a6:	000a6797          	auipc	a5,0xa6
ffffffffc02060aa:	41a78793          	addi	a5,a5,1050 # ffffffffc02ac4c0 <current>
ffffffffc02060ae:	639c                	ld	a5,0(a5)
    return do_fork(0, stack, tf);
ffffffffc02060b0:	4501                	li	a0,0
    struct trapframe *tf = current->tf;
ffffffffc02060b2:	73d0                	ld	a2,160(a5)
    return do_fork(0, stack, tf);
ffffffffc02060b4:	6a0c                	ld	a1,16(a2)
ffffffffc02060b6:	ed3fe06f          	j	ffffffffc0204f88 <do_fork>

ffffffffc02060ba <sys_exit>:
    return do_exit(error_code);
ffffffffc02060ba:	4108                	lw	a0,0(a0)
ffffffffc02060bc:	b08ff06f          	j	ffffffffc02053c4 <do_exit>

ffffffffc02060c0 <syscall>:
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void
syscall(void) {
ffffffffc02060c0:	715d                	addi	sp,sp,-80
ffffffffc02060c2:	fc26                	sd	s1,56(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060c4:	000a6497          	auipc	s1,0xa6
ffffffffc02060c8:	3fc48493          	addi	s1,s1,1020 # ffffffffc02ac4c0 <current>
ffffffffc02060cc:	6098                	ld	a4,0(s1)
syscall(void) {
ffffffffc02060ce:	e0a2                	sd	s0,64(sp)
ffffffffc02060d0:	f84a                	sd	s2,48(sp)
    struct trapframe *tf = current->tf;
ffffffffc02060d2:	7340                	ld	s0,160(a4)
syscall(void) {
ffffffffc02060d4:	e486                	sd	ra,72(sp)
    uint64_t arg[5];
    int num = tf->gpr.a0;
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060d6:	47fd                	li	a5,31
    int num = tf->gpr.a0;
ffffffffc02060d8:	05042903          	lw	s2,80(s0)
    if (num >= 0 && num < NUM_SYSCALLS) {
ffffffffc02060dc:	0327ee63          	bltu	a5,s2,ffffffffc0206118 <syscall+0x58>
        if (syscalls[num] != NULL) {
ffffffffc02060e0:	00391713          	slli	a4,s2,0x3
ffffffffc02060e4:	00002797          	auipc	a5,0x2
ffffffffc02060e8:	7e478793          	addi	a5,a5,2020 # ffffffffc02088c8 <syscalls>
ffffffffc02060ec:	97ba                	add	a5,a5,a4
ffffffffc02060ee:	639c                	ld	a5,0(a5)
ffffffffc02060f0:	c785                	beqz	a5,ffffffffc0206118 <syscall+0x58>
            arg[0] = tf->gpr.a1;
ffffffffc02060f2:	6c28                	ld	a0,88(s0)
            arg[1] = tf->gpr.a2;
ffffffffc02060f4:	702c                	ld	a1,96(s0)
            arg[2] = tf->gpr.a3;
ffffffffc02060f6:	7430                	ld	a2,104(s0)
            arg[3] = tf->gpr.a4;
ffffffffc02060f8:	7834                	ld	a3,112(s0)
            arg[4] = tf->gpr.a5;
ffffffffc02060fa:	7c38                	ld	a4,120(s0)
            arg[0] = tf->gpr.a1;
ffffffffc02060fc:	e42a                	sd	a0,8(sp)
            arg[1] = tf->gpr.a2;
ffffffffc02060fe:	e82e                	sd	a1,16(sp)
            arg[2] = tf->gpr.a3;
ffffffffc0206100:	ec32                	sd	a2,24(sp)
            arg[3] = tf->gpr.a4;
ffffffffc0206102:	f036                	sd	a3,32(sp)
            arg[4] = tf->gpr.a5;
ffffffffc0206104:	f43a                	sd	a4,40(sp)
            //调用对应的系统调用函数，传入参数
            tf->gpr.a0 = syscalls[num](arg);
ffffffffc0206106:	0028                	addi	a0,sp,8
ffffffffc0206108:	9782                	jalr	a5
ffffffffc020610a:	e828                	sd	a0,80(s0)
        }
    }
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
ffffffffc020610c:	60a6                	ld	ra,72(sp)
ffffffffc020610e:	6406                	ld	s0,64(sp)
ffffffffc0206110:	74e2                	ld	s1,56(sp)
ffffffffc0206112:	7942                	ld	s2,48(sp)
ffffffffc0206114:	6161                	addi	sp,sp,80
ffffffffc0206116:	8082                	ret
    print_trapframe(tf);
ffffffffc0206118:	8522                	mv	a0,s0
ffffffffc020611a:	f30fa0ef          	jal	ra,ffffffffc020084a <print_trapframe>
    panic("undefined syscall %d, pid = %d, name = %s.\n",
ffffffffc020611e:	609c                	ld	a5,0(s1)
ffffffffc0206120:	86ca                	mv	a3,s2
ffffffffc0206122:	00002617          	auipc	a2,0x2
ffffffffc0206126:	75e60613          	addi	a2,a2,1886 # ffffffffc0208880 <default_pmm_manager+0x1530>
ffffffffc020612a:	43d8                	lw	a4,4(a5)
ffffffffc020612c:	06400593          	li	a1,100
ffffffffc0206130:	0b478793          	addi	a5,a5,180
ffffffffc0206134:	00002517          	auipc	a0,0x2
ffffffffc0206138:	77c50513          	addi	a0,a0,1916 # ffffffffc02088b0 <default_pmm_manager+0x1560>
ffffffffc020613c:	b48fa0ef          	jal	ra,ffffffffc0200484 <__panic>

ffffffffc0206140 <hash32>:
 *
 * High bits are more random, so we use them.
 * */
uint32_t
hash32(uint32_t val, unsigned int bits) {
    uint32_t hash = val * GOLDEN_RATIO_PRIME_32;
ffffffffc0206140:	9e3707b7          	lui	a5,0x9e370
ffffffffc0206144:	2785                	addiw	a5,a5,1
ffffffffc0206146:	02f5053b          	mulw	a0,a0,a5
    return (hash >> (32 - bits));
ffffffffc020614a:	02000793          	li	a5,32
ffffffffc020614e:	40b785bb          	subw	a1,a5,a1
}
ffffffffc0206152:	00b5553b          	srlw	a0,a0,a1
ffffffffc0206156:	8082                	ret

ffffffffc0206158 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0206158:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc020615c:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc020615e:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206162:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0206164:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0206168:	f022                	sd	s0,32(sp)
ffffffffc020616a:	ec26                	sd	s1,24(sp)
ffffffffc020616c:	e84a                	sd	s2,16(sp)
ffffffffc020616e:	f406                	sd	ra,40(sp)
ffffffffc0206170:	e44e                	sd	s3,8(sp)
ffffffffc0206172:	84aa                	mv	s1,a0
ffffffffc0206174:	892e                	mv	s2,a1
ffffffffc0206176:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc020617a:	2a01                	sext.w	s4,s4

    // first recursively print all preceding (more significant) digits
    if (num >= base) {
ffffffffc020617c:	03067e63          	bleu	a6,a2,ffffffffc02061b8 <printnum+0x60>
ffffffffc0206180:	89be                	mv	s3,a5
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0206182:	00805763          	blez	s0,ffffffffc0206190 <printnum+0x38>
ffffffffc0206186:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0206188:	85ca                	mv	a1,s2
ffffffffc020618a:	854e                	mv	a0,s3
ffffffffc020618c:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc020618e:	fc65                	bnez	s0,ffffffffc0206186 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0206190:	1a02                	slli	s4,s4,0x20
ffffffffc0206192:	020a5a13          	srli	s4,s4,0x20
ffffffffc0206196:	00003797          	auipc	a5,0x3
ffffffffc020619a:	a5278793          	addi	a5,a5,-1454 # ffffffffc0208be8 <error_string+0xc8>
ffffffffc020619e:	9a3e                	add	s4,s4,a5
    // Crashes if num >= base. No idea what going on here
    // Here is a quick fix
    // update: Stack grows downward and destory the SBI
    // sbi_console_putchar("0123456789abcdef"[mod]);
    // (*(int *)putdat)++;
}
ffffffffc02061a0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02061a2:	000a4503          	lbu	a0,0(s4)
}
ffffffffc02061a6:	70a2                	ld	ra,40(sp)
ffffffffc02061a8:	69a2                	ld	s3,8(sp)
ffffffffc02061aa:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02061ac:	85ca                	mv	a1,s2
ffffffffc02061ae:	8326                	mv	t1,s1
}
ffffffffc02061b0:	6942                	ld	s2,16(sp)
ffffffffc02061b2:	64e2                	ld	s1,24(sp)
ffffffffc02061b4:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02061b6:	8302                	jr	t1
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc02061b8:	03065633          	divu	a2,a2,a6
ffffffffc02061bc:	8722                	mv	a4,s0
ffffffffc02061be:	f9bff0ef          	jal	ra,ffffffffc0206158 <printnum>
ffffffffc02061c2:	b7f9                	j	ffffffffc0206190 <printnum+0x38>

ffffffffc02061c4 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc02061c4:	7119                	addi	sp,sp,-128
ffffffffc02061c6:	f4a6                	sd	s1,104(sp)
ffffffffc02061c8:	f0ca                	sd	s2,96(sp)
ffffffffc02061ca:	e8d2                	sd	s4,80(sp)
ffffffffc02061cc:	e4d6                	sd	s5,72(sp)
ffffffffc02061ce:	e0da                	sd	s6,64(sp)
ffffffffc02061d0:	fc5e                	sd	s7,56(sp)
ffffffffc02061d2:	f862                	sd	s8,48(sp)
ffffffffc02061d4:	f06a                	sd	s10,32(sp)
ffffffffc02061d6:	fc86                	sd	ra,120(sp)
ffffffffc02061d8:	f8a2                	sd	s0,112(sp)
ffffffffc02061da:	ecce                	sd	s3,88(sp)
ffffffffc02061dc:	f466                	sd	s9,40(sp)
ffffffffc02061de:	ec6e                	sd	s11,24(sp)
ffffffffc02061e0:	892a                	mv	s2,a0
ffffffffc02061e2:	84ae                	mv	s1,a1
ffffffffc02061e4:	8d32                	mv	s10,a2
ffffffffc02061e6:	8ab6                	mv	s5,a3
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc02061e8:	5b7d                	li	s6,-1
        lflag = altflag = 0;

    reswitch:
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02061ea:	00002a17          	auipc	s4,0x2
ffffffffc02061ee:	7dea0a13          	addi	s4,s4,2014 # ffffffffc02089c8 <syscalls+0x100>
                for (width -= strnlen(p, precision); width > 0; width --) {
                    putch(padc, putdat);
                }
            }
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02061f2:	05e00b93          	li	s7,94
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02061f6:	00003c17          	auipc	s8,0x3
ffffffffc02061fa:	92ac0c13          	addi	s8,s8,-1750 # ffffffffc0208b20 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc02061fe:	000d4503          	lbu	a0,0(s10)
ffffffffc0206202:	02500793          	li	a5,37
ffffffffc0206206:	001d0413          	addi	s0,s10,1
ffffffffc020620a:	00f50e63          	beq	a0,a5,ffffffffc0206226 <vprintfmt+0x62>
            if (ch == '\0') {
ffffffffc020620e:	c521                	beqz	a0,ffffffffc0206256 <vprintfmt+0x92>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0206210:	02500993          	li	s3,37
ffffffffc0206214:	a011                	j	ffffffffc0206218 <vprintfmt+0x54>
            if (ch == '\0') {
ffffffffc0206216:	c121                	beqz	a0,ffffffffc0206256 <vprintfmt+0x92>
            putch(ch, putdat);
ffffffffc0206218:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020621a:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020621c:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020621e:	fff44503          	lbu	a0,-1(s0)
ffffffffc0206222:	ff351ae3          	bne	a0,s3,ffffffffc0206216 <vprintfmt+0x52>
ffffffffc0206226:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc020622a:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020622e:	4981                	li	s3,0
ffffffffc0206230:	4801                	li	a6,0
        width = precision = -1;
ffffffffc0206232:	5cfd                	li	s9,-1
ffffffffc0206234:	5dfd                	li	s11,-1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206236:	05500593          	li	a1,85
                if (ch < '0' || ch > '9') {
ffffffffc020623a:	4525                	li	a0,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020623c:	fdd6069b          	addiw	a3,a2,-35
ffffffffc0206240:	0ff6f693          	andi	a3,a3,255
ffffffffc0206244:	00140d13          	addi	s10,s0,1
ffffffffc0206248:	20d5e563          	bltu	a1,a3,ffffffffc0206452 <vprintfmt+0x28e>
ffffffffc020624c:	068a                	slli	a3,a3,0x2
ffffffffc020624e:	96d2                	add	a3,a3,s4
ffffffffc0206250:	4294                	lw	a3,0(a3)
ffffffffc0206252:	96d2                	add	a3,a3,s4
ffffffffc0206254:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0206256:	70e6                	ld	ra,120(sp)
ffffffffc0206258:	7446                	ld	s0,112(sp)
ffffffffc020625a:	74a6                	ld	s1,104(sp)
ffffffffc020625c:	7906                	ld	s2,96(sp)
ffffffffc020625e:	69e6                	ld	s3,88(sp)
ffffffffc0206260:	6a46                	ld	s4,80(sp)
ffffffffc0206262:	6aa6                	ld	s5,72(sp)
ffffffffc0206264:	6b06                	ld	s6,64(sp)
ffffffffc0206266:	7be2                	ld	s7,56(sp)
ffffffffc0206268:	7c42                	ld	s8,48(sp)
ffffffffc020626a:	7ca2                	ld	s9,40(sp)
ffffffffc020626c:	7d02                	ld	s10,32(sp)
ffffffffc020626e:	6de2                	ld	s11,24(sp)
ffffffffc0206270:	6109                	addi	sp,sp,128
ffffffffc0206272:	8082                	ret
    if (lflag >= 2) {
ffffffffc0206274:	4705                	li	a4,1
ffffffffc0206276:	008a8593          	addi	a1,s5,8
ffffffffc020627a:	01074463          	blt	a4,a6,ffffffffc0206282 <vprintfmt+0xbe>
    else if (lflag) {
ffffffffc020627e:	26080363          	beqz	a6,ffffffffc02064e4 <vprintfmt+0x320>
        return va_arg(*ap, unsigned long);
ffffffffc0206282:	000ab603          	ld	a2,0(s5)
ffffffffc0206286:	46c1                	li	a3,16
ffffffffc0206288:	8aae                	mv	s5,a1
ffffffffc020628a:	a06d                	j	ffffffffc0206334 <vprintfmt+0x170>
            goto reswitch;
ffffffffc020628c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0206290:	4985                	li	s3,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206292:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0206294:	b765                	j	ffffffffc020623c <vprintfmt+0x78>
            putch(va_arg(ap, int), putdat);
ffffffffc0206296:	000aa503          	lw	a0,0(s5)
ffffffffc020629a:	85a6                	mv	a1,s1
ffffffffc020629c:	0aa1                	addi	s5,s5,8
ffffffffc020629e:	9902                	jalr	s2
            break;
ffffffffc02062a0:	bfb9                	j	ffffffffc02061fe <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02062a2:	4705                	li	a4,1
ffffffffc02062a4:	008a8993          	addi	s3,s5,8
ffffffffc02062a8:	01074463          	blt	a4,a6,ffffffffc02062b0 <vprintfmt+0xec>
    else if (lflag) {
ffffffffc02062ac:	22080463          	beqz	a6,ffffffffc02064d4 <vprintfmt+0x310>
        return va_arg(*ap, long);
ffffffffc02062b0:	000ab403          	ld	s0,0(s5)
            if ((long long)num < 0) {
ffffffffc02062b4:	24044463          	bltz	s0,ffffffffc02064fc <vprintfmt+0x338>
            num = getint(&ap, lflag);
ffffffffc02062b8:	8622                	mv	a2,s0
ffffffffc02062ba:	8ace                	mv	s5,s3
ffffffffc02062bc:	46a9                	li	a3,10
ffffffffc02062be:	a89d                	j	ffffffffc0206334 <vprintfmt+0x170>
            err = va_arg(ap, int);
ffffffffc02062c0:	000aa783          	lw	a5,0(s5)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02062c4:	4761                	li	a4,24
            err = va_arg(ap, int);
ffffffffc02062c6:	0aa1                	addi	s5,s5,8
            if (err < 0) {
ffffffffc02062c8:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02062cc:	8fb5                	xor	a5,a5,a3
ffffffffc02062ce:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02062d2:	1ad74363          	blt	a4,a3,ffffffffc0206478 <vprintfmt+0x2b4>
ffffffffc02062d6:	00369793          	slli	a5,a3,0x3
ffffffffc02062da:	97e2                	add	a5,a5,s8
ffffffffc02062dc:	639c                	ld	a5,0(a5)
ffffffffc02062de:	18078d63          	beqz	a5,ffffffffc0206478 <vprintfmt+0x2b4>
                printfmt(putch, putdat, "%s", p);
ffffffffc02062e2:	86be                	mv	a3,a5
ffffffffc02062e4:	00000617          	auipc	a2,0x0
ffffffffc02062e8:	35c60613          	addi	a2,a2,860 # ffffffffc0206640 <etext+0x28>
ffffffffc02062ec:	85a6                	mv	a1,s1
ffffffffc02062ee:	854a                	mv	a0,s2
ffffffffc02062f0:	240000ef          	jal	ra,ffffffffc0206530 <printfmt>
ffffffffc02062f4:	b729                	j	ffffffffc02061fe <vprintfmt+0x3a>
            lflag ++;
ffffffffc02062f6:	00144603          	lbu	a2,1(s0)
ffffffffc02062fa:	2805                	addiw	a6,a6,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02062fc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02062fe:	bf3d                	j	ffffffffc020623c <vprintfmt+0x78>
    if (lflag >= 2) {
ffffffffc0206300:	4705                	li	a4,1
ffffffffc0206302:	008a8593          	addi	a1,s5,8
ffffffffc0206306:	01074463          	blt	a4,a6,ffffffffc020630e <vprintfmt+0x14a>
    else if (lflag) {
ffffffffc020630a:	1e080263          	beqz	a6,ffffffffc02064ee <vprintfmt+0x32a>
        return va_arg(*ap, unsigned long);
ffffffffc020630e:	000ab603          	ld	a2,0(s5)
ffffffffc0206312:	46a1                	li	a3,8
ffffffffc0206314:	8aae                	mv	s5,a1
ffffffffc0206316:	a839                	j	ffffffffc0206334 <vprintfmt+0x170>
            putch('0', putdat);
ffffffffc0206318:	03000513          	li	a0,48
ffffffffc020631c:	85a6                	mv	a1,s1
ffffffffc020631e:	e03e                	sd	a5,0(sp)
ffffffffc0206320:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0206322:	85a6                	mv	a1,s1
ffffffffc0206324:	07800513          	li	a0,120
ffffffffc0206328:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc020632a:	0aa1                	addi	s5,s5,8
ffffffffc020632c:	ff8ab603          	ld	a2,-8(s5)
            goto number;
ffffffffc0206330:	6782                	ld	a5,0(sp)
ffffffffc0206332:	46c1                	li	a3,16
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0206334:	876e                	mv	a4,s11
ffffffffc0206336:	85a6                	mv	a1,s1
ffffffffc0206338:	854a                	mv	a0,s2
ffffffffc020633a:	e1fff0ef          	jal	ra,ffffffffc0206158 <printnum>
            break;
ffffffffc020633e:	b5c1                	j	ffffffffc02061fe <vprintfmt+0x3a>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0206340:	000ab603          	ld	a2,0(s5)
ffffffffc0206344:	0aa1                	addi	s5,s5,8
ffffffffc0206346:	1c060663          	beqz	a2,ffffffffc0206512 <vprintfmt+0x34e>
            if (width > 0 && padc != '-') {
ffffffffc020634a:	00160413          	addi	s0,a2,1
ffffffffc020634e:	17b05c63          	blez	s11,ffffffffc02064c6 <vprintfmt+0x302>
ffffffffc0206352:	02d00593          	li	a1,45
ffffffffc0206356:	14b79263          	bne	a5,a1,ffffffffc020649a <vprintfmt+0x2d6>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020635a:	00064783          	lbu	a5,0(a2)
ffffffffc020635e:	0007851b          	sext.w	a0,a5
ffffffffc0206362:	c905                	beqz	a0,ffffffffc0206392 <vprintfmt+0x1ce>
ffffffffc0206364:	000cc563          	bltz	s9,ffffffffc020636e <vprintfmt+0x1aa>
ffffffffc0206368:	3cfd                	addiw	s9,s9,-1
ffffffffc020636a:	036c8263          	beq	s9,s6,ffffffffc020638e <vprintfmt+0x1ca>
                    putch('?', putdat);
ffffffffc020636e:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0206370:	18098463          	beqz	s3,ffffffffc02064f8 <vprintfmt+0x334>
ffffffffc0206374:	3781                	addiw	a5,a5,-32
ffffffffc0206376:	18fbf163          	bleu	a5,s7,ffffffffc02064f8 <vprintfmt+0x334>
                    putch('?', putdat);
ffffffffc020637a:	03f00513          	li	a0,63
ffffffffc020637e:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206380:	0405                	addi	s0,s0,1
ffffffffc0206382:	fff44783          	lbu	a5,-1(s0)
ffffffffc0206386:	3dfd                	addiw	s11,s11,-1
ffffffffc0206388:	0007851b          	sext.w	a0,a5
ffffffffc020638c:	fd61                	bnez	a0,ffffffffc0206364 <vprintfmt+0x1a0>
            for (; width > 0; width --) {
ffffffffc020638e:	e7b058e3          	blez	s11,ffffffffc02061fe <vprintfmt+0x3a>
ffffffffc0206392:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0206394:	85a6                	mv	a1,s1
ffffffffc0206396:	02000513          	li	a0,32
ffffffffc020639a:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020639c:	e60d81e3          	beqz	s11,ffffffffc02061fe <vprintfmt+0x3a>
ffffffffc02063a0:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc02063a2:	85a6                	mv	a1,s1
ffffffffc02063a4:	02000513          	li	a0,32
ffffffffc02063a8:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc02063aa:	fe0d94e3          	bnez	s11,ffffffffc0206392 <vprintfmt+0x1ce>
ffffffffc02063ae:	bd81                	j	ffffffffc02061fe <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc02063b0:	4705                	li	a4,1
ffffffffc02063b2:	008a8593          	addi	a1,s5,8
ffffffffc02063b6:	01074463          	blt	a4,a6,ffffffffc02063be <vprintfmt+0x1fa>
    else if (lflag) {
ffffffffc02063ba:	12080063          	beqz	a6,ffffffffc02064da <vprintfmt+0x316>
        return va_arg(*ap, unsigned long);
ffffffffc02063be:	000ab603          	ld	a2,0(s5)
ffffffffc02063c2:	46a9                	li	a3,10
ffffffffc02063c4:	8aae                	mv	s5,a1
ffffffffc02063c6:	b7bd                	j	ffffffffc0206334 <vprintfmt+0x170>
ffffffffc02063c8:	00144603          	lbu	a2,1(s0)
            padc = '-';
ffffffffc02063cc:	02d00793          	li	a5,45
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063d0:	846a                	mv	s0,s10
ffffffffc02063d2:	b5ad                	j	ffffffffc020623c <vprintfmt+0x78>
            putch(ch, putdat);
ffffffffc02063d4:	85a6                	mv	a1,s1
ffffffffc02063d6:	02500513          	li	a0,37
ffffffffc02063da:	9902                	jalr	s2
            break;
ffffffffc02063dc:	b50d                	j	ffffffffc02061fe <vprintfmt+0x3a>
            precision = va_arg(ap, int);
ffffffffc02063de:	000aac83          	lw	s9,0(s5)
            goto process_precision;
ffffffffc02063e2:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc02063e6:	0aa1                	addi	s5,s5,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063e8:	846a                	mv	s0,s10
            if (width < 0)
ffffffffc02063ea:	e40dd9e3          	bgez	s11,ffffffffc020623c <vprintfmt+0x78>
                width = precision, precision = -1;
ffffffffc02063ee:	8de6                	mv	s11,s9
ffffffffc02063f0:	5cfd                	li	s9,-1
ffffffffc02063f2:	b5a9                	j	ffffffffc020623c <vprintfmt+0x78>
            goto reswitch;
ffffffffc02063f4:	00144603          	lbu	a2,1(s0)
            padc = '0';
ffffffffc02063f8:	03000793          	li	a5,48
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02063fc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02063fe:	bd3d                	j	ffffffffc020623c <vprintfmt+0x78>
                precision = precision * 10 + ch - '0';
ffffffffc0206400:	fd060c9b          	addiw	s9,a2,-48
                ch = *fmt;
ffffffffc0206404:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0206408:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc020640a:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc020640e:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206412:	fcd56ce3          	bltu	a0,a3,ffffffffc02063ea <vprintfmt+0x226>
            for (precision = 0; ; ++ fmt) {
ffffffffc0206416:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0206418:	002c969b          	slliw	a3,s9,0x2
                ch = *fmt;
ffffffffc020641c:	00044603          	lbu	a2,0(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0206420:	0196873b          	addw	a4,a3,s9
ffffffffc0206424:	0017171b          	slliw	a4,a4,0x1
ffffffffc0206428:	0117073b          	addw	a4,a4,a7
                if (ch < '0' || ch > '9') {
ffffffffc020642c:	fd06069b          	addiw	a3,a2,-48
                precision = precision * 10 + ch - '0';
ffffffffc0206430:	fd070c9b          	addiw	s9,a4,-48
                ch = *fmt;
ffffffffc0206434:	0006089b          	sext.w	a7,a2
                if (ch < '0' || ch > '9') {
ffffffffc0206438:	fcd57fe3          	bleu	a3,a0,ffffffffc0206416 <vprintfmt+0x252>
ffffffffc020643c:	b77d                	j	ffffffffc02063ea <vprintfmt+0x226>
            if (width < 0)
ffffffffc020643e:	fffdc693          	not	a3,s11
ffffffffc0206442:	96fd                	srai	a3,a3,0x3f
ffffffffc0206444:	00ddfdb3          	and	s11,s11,a3
ffffffffc0206448:	00144603          	lbu	a2,1(s0)
ffffffffc020644c:	2d81                	sext.w	s11,s11
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020644e:	846a                	mv	s0,s10
ffffffffc0206450:	b3f5                	j	ffffffffc020623c <vprintfmt+0x78>
            putch('%', putdat);
ffffffffc0206452:	85a6                	mv	a1,s1
ffffffffc0206454:	02500513          	li	a0,37
ffffffffc0206458:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc020645a:	fff44703          	lbu	a4,-1(s0)
ffffffffc020645e:	02500793          	li	a5,37
ffffffffc0206462:	8d22                	mv	s10,s0
ffffffffc0206464:	d8f70de3          	beq	a4,a5,ffffffffc02061fe <vprintfmt+0x3a>
ffffffffc0206468:	02500713          	li	a4,37
ffffffffc020646c:	1d7d                	addi	s10,s10,-1
ffffffffc020646e:	fffd4783          	lbu	a5,-1(s10)
ffffffffc0206472:	fee79de3          	bne	a5,a4,ffffffffc020646c <vprintfmt+0x2a8>
ffffffffc0206476:	b361                	j	ffffffffc02061fe <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc0206478:	00003617          	auipc	a2,0x3
ffffffffc020647c:	85060613          	addi	a2,a2,-1968 # ffffffffc0208cc8 <error_string+0x1a8>
ffffffffc0206480:	85a6                	mv	a1,s1
ffffffffc0206482:	854a                	mv	a0,s2
ffffffffc0206484:	0ac000ef          	jal	ra,ffffffffc0206530 <printfmt>
ffffffffc0206488:	bb9d                	j	ffffffffc02061fe <vprintfmt+0x3a>
                p = "(null)";
ffffffffc020648a:	00003617          	auipc	a2,0x3
ffffffffc020648e:	83660613          	addi	a2,a2,-1994 # ffffffffc0208cc0 <error_string+0x1a0>
            if (width > 0 && padc != '-') {
ffffffffc0206492:	00003417          	auipc	s0,0x3
ffffffffc0206496:	82f40413          	addi	s0,s0,-2001 # ffffffffc0208cc1 <error_string+0x1a1>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc020649a:	8532                	mv	a0,a2
ffffffffc020649c:	85e6                	mv	a1,s9
ffffffffc020649e:	e032                	sd	a2,0(sp)
ffffffffc02064a0:	e43e                	sd	a5,8(sp)
ffffffffc02064a2:	0cc000ef          	jal	ra,ffffffffc020656e <strnlen>
ffffffffc02064a6:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02064aa:	6602                	ld	a2,0(sp)
ffffffffc02064ac:	01b05d63          	blez	s11,ffffffffc02064c6 <vprintfmt+0x302>
ffffffffc02064b0:	67a2                	ld	a5,8(sp)
ffffffffc02064b2:	2781                	sext.w	a5,a5
ffffffffc02064b4:	e43e                	sd	a5,8(sp)
                    putch(padc, putdat);
ffffffffc02064b6:	6522                	ld	a0,8(sp)
ffffffffc02064b8:	85a6                	mv	a1,s1
ffffffffc02064ba:	e032                	sd	a2,0(sp)
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02064bc:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02064be:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02064c0:	6602                	ld	a2,0(sp)
ffffffffc02064c2:	fe0d9ae3          	bnez	s11,ffffffffc02064b6 <vprintfmt+0x2f2>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02064c6:	00064783          	lbu	a5,0(a2)
ffffffffc02064ca:	0007851b          	sext.w	a0,a5
ffffffffc02064ce:	e8051be3          	bnez	a0,ffffffffc0206364 <vprintfmt+0x1a0>
ffffffffc02064d2:	b335                	j	ffffffffc02061fe <vprintfmt+0x3a>
        return va_arg(*ap, int);
ffffffffc02064d4:	000aa403          	lw	s0,0(s5)
ffffffffc02064d8:	bbf1                	j	ffffffffc02062b4 <vprintfmt+0xf0>
        return va_arg(*ap, unsigned int);
ffffffffc02064da:	000ae603          	lwu	a2,0(s5)
ffffffffc02064de:	46a9                	li	a3,10
ffffffffc02064e0:	8aae                	mv	s5,a1
ffffffffc02064e2:	bd89                	j	ffffffffc0206334 <vprintfmt+0x170>
ffffffffc02064e4:	000ae603          	lwu	a2,0(s5)
ffffffffc02064e8:	46c1                	li	a3,16
ffffffffc02064ea:	8aae                	mv	s5,a1
ffffffffc02064ec:	b5a1                	j	ffffffffc0206334 <vprintfmt+0x170>
ffffffffc02064ee:	000ae603          	lwu	a2,0(s5)
ffffffffc02064f2:	46a1                	li	a3,8
ffffffffc02064f4:	8aae                	mv	s5,a1
ffffffffc02064f6:	bd3d                	j	ffffffffc0206334 <vprintfmt+0x170>
                    putch(ch, putdat);
ffffffffc02064f8:	9902                	jalr	s2
ffffffffc02064fa:	b559                	j	ffffffffc0206380 <vprintfmt+0x1bc>
                putch('-', putdat);
ffffffffc02064fc:	85a6                	mv	a1,s1
ffffffffc02064fe:	02d00513          	li	a0,45
ffffffffc0206502:	e03e                	sd	a5,0(sp)
ffffffffc0206504:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0206506:	8ace                	mv	s5,s3
ffffffffc0206508:	40800633          	neg	a2,s0
ffffffffc020650c:	46a9                	li	a3,10
ffffffffc020650e:	6782                	ld	a5,0(sp)
ffffffffc0206510:	b515                	j	ffffffffc0206334 <vprintfmt+0x170>
            if (width > 0 && padc != '-') {
ffffffffc0206512:	01b05663          	blez	s11,ffffffffc020651e <vprintfmt+0x35a>
ffffffffc0206516:	02d00693          	li	a3,45
ffffffffc020651a:	f6d798e3          	bne	a5,a3,ffffffffc020648a <vprintfmt+0x2c6>
ffffffffc020651e:	00002417          	auipc	s0,0x2
ffffffffc0206522:	7a340413          	addi	s0,s0,1955 # ffffffffc0208cc1 <error_string+0x1a1>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0206526:	02800513          	li	a0,40
ffffffffc020652a:	02800793          	li	a5,40
ffffffffc020652e:	bd1d                	j	ffffffffc0206364 <vprintfmt+0x1a0>

ffffffffc0206530 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206530:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0206532:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0206536:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206538:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020653a:	ec06                	sd	ra,24(sp)
ffffffffc020653c:	f83a                	sd	a4,48(sp)
ffffffffc020653e:	fc3e                	sd	a5,56(sp)
ffffffffc0206540:	e0c2                	sd	a6,64(sp)
ffffffffc0206542:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc0206544:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0206546:	c7fff0ef          	jal	ra,ffffffffc02061c4 <vprintfmt>
}
ffffffffc020654a:	60e2                	ld	ra,24(sp)
ffffffffc020654c:	6161                	addi	sp,sp,80
ffffffffc020654e:	8082                	ret

ffffffffc0206550 <strlen>:
 * The strlen() function returns the length of string @s.
 * */
size_t
strlen(const char *s) {
    size_t cnt = 0;
    while (*s ++ != '\0') {
ffffffffc0206550:	00054783          	lbu	a5,0(a0)
ffffffffc0206554:	cb91                	beqz	a5,ffffffffc0206568 <strlen+0x18>
    size_t cnt = 0;
ffffffffc0206556:	4781                	li	a5,0
        cnt ++;
ffffffffc0206558:	0785                	addi	a5,a5,1
    while (*s ++ != '\0') {
ffffffffc020655a:	00f50733          	add	a4,a0,a5
ffffffffc020655e:	00074703          	lbu	a4,0(a4)
ffffffffc0206562:	fb7d                	bnez	a4,ffffffffc0206558 <strlen+0x8>
    }
    return cnt;
}
ffffffffc0206564:	853e                	mv	a0,a5
ffffffffc0206566:	8082                	ret
    size_t cnt = 0;
ffffffffc0206568:	4781                	li	a5,0
}
ffffffffc020656a:	853e                	mv	a0,a5
ffffffffc020656c:	8082                	ret

ffffffffc020656e <strnlen>:
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
    while (cnt < len && *s ++ != '\0') {
ffffffffc020656e:	c185                	beqz	a1,ffffffffc020658e <strnlen+0x20>
ffffffffc0206570:	00054783          	lbu	a5,0(a0)
ffffffffc0206574:	cf89                	beqz	a5,ffffffffc020658e <strnlen+0x20>
    size_t cnt = 0;
ffffffffc0206576:	4781                	li	a5,0
ffffffffc0206578:	a021                	j	ffffffffc0206580 <strnlen+0x12>
    while (cnt < len && *s ++ != '\0') {
ffffffffc020657a:	00074703          	lbu	a4,0(a4)
ffffffffc020657e:	c711                	beqz	a4,ffffffffc020658a <strnlen+0x1c>
        cnt ++;
ffffffffc0206580:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc0206582:	00f50733          	add	a4,a0,a5
ffffffffc0206586:	fef59ae3          	bne	a1,a5,ffffffffc020657a <strnlen+0xc>
    }
    return cnt;
}
ffffffffc020658a:	853e                	mv	a0,a5
ffffffffc020658c:	8082                	ret
    size_t cnt = 0;
ffffffffc020658e:	4781                	li	a5,0
}
ffffffffc0206590:	853e                	mv	a0,a5
ffffffffc0206592:	8082                	ret

ffffffffc0206594 <strcpy>:
char *
strcpy(char *dst, const char *src) {
#ifdef __HAVE_ARCH_STRCPY
    return __strcpy(dst, src);
#else
    char *p = dst;
ffffffffc0206594:	87aa                	mv	a5,a0
    while ((*p ++ = *src ++) != '\0')
ffffffffc0206596:	0585                	addi	a1,a1,1
ffffffffc0206598:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020659c:	0785                	addi	a5,a5,1
ffffffffc020659e:	fee78fa3          	sb	a4,-1(a5)
ffffffffc02065a2:	fb75                	bnez	a4,ffffffffc0206596 <strcpy+0x2>
        /* nothing */;
    return dst;
#endif /* __HAVE_ARCH_STRCPY */
}
ffffffffc02065a4:	8082                	ret

ffffffffc02065a6 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02065a6:	00054783          	lbu	a5,0(a0)
ffffffffc02065aa:	0005c703          	lbu	a4,0(a1)
ffffffffc02065ae:	cb91                	beqz	a5,ffffffffc02065c2 <strcmp+0x1c>
ffffffffc02065b0:	00e79c63          	bne	a5,a4,ffffffffc02065c8 <strcmp+0x22>
        s1 ++, s2 ++;
ffffffffc02065b4:	0505                	addi	a0,a0,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02065b6:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
ffffffffc02065ba:	0585                	addi	a1,a1,1
ffffffffc02065bc:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02065c0:	fbe5                	bnez	a5,ffffffffc02065b0 <strcmp+0xa>
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02065c2:	4501                	li	a0,0
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02065c4:	9d19                	subw	a0,a0,a4
ffffffffc02065c6:	8082                	ret
ffffffffc02065c8:	0007851b          	sext.w	a0,a5
ffffffffc02065cc:	9d19                	subw	a0,a0,a4
ffffffffc02065ce:	8082                	ret

ffffffffc02065d0 <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02065d0:	00054783          	lbu	a5,0(a0)
ffffffffc02065d4:	cb91                	beqz	a5,ffffffffc02065e8 <strchr+0x18>
        if (*s == c) {
ffffffffc02065d6:	00b79563          	bne	a5,a1,ffffffffc02065e0 <strchr+0x10>
ffffffffc02065da:	a809                	j	ffffffffc02065ec <strchr+0x1c>
ffffffffc02065dc:	00b78763          	beq	a5,a1,ffffffffc02065ea <strchr+0x1a>
            return (char *)s;
        }
        s ++;
ffffffffc02065e0:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02065e2:	00054783          	lbu	a5,0(a0)
ffffffffc02065e6:	fbfd                	bnez	a5,ffffffffc02065dc <strchr+0xc>
    }
    return NULL;
ffffffffc02065e8:	4501                	li	a0,0
}
ffffffffc02065ea:	8082                	ret
ffffffffc02065ec:	8082                	ret

ffffffffc02065ee <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02065ee:	ca01                	beqz	a2,ffffffffc02065fe <memset+0x10>
ffffffffc02065f0:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02065f2:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02065f4:	0785                	addi	a5,a5,1
ffffffffc02065f6:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02065fa:	fec79de3          	bne	a5,a2,ffffffffc02065f4 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02065fe:	8082                	ret

ffffffffc0206600 <memcpy>:
#ifdef __HAVE_ARCH_MEMCPY
    return __memcpy(dst, src, n);
#else
    const char *s = src;
    char *d = dst;
    while (n -- > 0) {
ffffffffc0206600:	ca19                	beqz	a2,ffffffffc0206616 <memcpy+0x16>
ffffffffc0206602:	962e                	add	a2,a2,a1
    char *d = dst;
ffffffffc0206604:	87aa                	mv	a5,a0
        *d ++ = *s ++;
ffffffffc0206606:	0585                	addi	a1,a1,1
ffffffffc0206608:	fff5c703          	lbu	a4,-1(a1)
ffffffffc020660c:	0785                	addi	a5,a5,1
ffffffffc020660e:	fee78fa3          	sb	a4,-1(a5)
    while (n -- > 0) {
ffffffffc0206612:	fec59ae3          	bne	a1,a2,ffffffffc0206606 <memcpy+0x6>
    }
    return dst;
#endif /* __HAVE_ARCH_MEMCPY */
}
ffffffffc0206616:	8082                	ret
