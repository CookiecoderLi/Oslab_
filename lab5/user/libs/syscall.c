#include <defs.h>
#include <unistd.h>
#include <stdarg.h>
#include <syscall.h>

#define MAX_ARGS            5

static inline int
syscall(int64_t num, ...) {
    va_list ap;
    //初始化参数列表为va_list类型
    va_start(ap, num);
    uint64_t a[MAX_ARGS];
    int i, ret;
    //依次取出参数列表中的参数
    for (i = 0; i < MAX_ARGS; i ++) {
        a[i] = va_arg(ap, uint64_t);
    }
    va_end(ap);

/*
1. `ld a0, %1` 到 `ld a5, %6`：这些是 load 指令，用于将参数从内存加载到 RISC-V 的通用寄存器 `a0` 到 `a5` 中。`%1` 到 `%6` 是占位符，表示在后面的冒号之后，用输入参数替换这些占位符。
2. `ecall`：这是一个特殊的 RISC-V 指令，用于触发系统调用。
3. `sd a0, %0`：store 指令，将通用寄存器 `a0` 中的值存储回 `ret` 变量。`%0` 是占位符，表示在后面的冒号之后，将 `ret` 替换这个占位符。
4. `: "=m" (ret)`：这是输出操作数约束，指示 `ret` 是一个输出操作数，并且是一个存储在内存中的数值。`"=m"` 表示这是一个输出操作数，并且是通过内存引用的方式。
5. `: "m"(num), "m"(a[0]), "m"(a[1]), "m"(a[2]), "m"(a[3]), "m"(a[4])`：这是输入操作数约束，指示了输入操作数的类型和位置。`"m"` 表示这是一个内存引用。
6. `: "memory"`：这是 clobber 操作数约束，告诉编译器内联汇编代码可能会修改内存。这是为了确保编译器不会进行任何有害的优化。
*/
    asm volatile (
        "ld a0, %1\n"
        "ld a1, %2\n"
        "ld a2, %3\n"
        "ld a3, %4\n"
        "ld a4, %5\n"
    	"ld a5, %6\n"
        "ecall\n"
        "sd a0, %0"
        : "=m" (ret)
        : "m"(num), "m"(a[0]), "m"(a[1]), "m"(a[2]), "m"(a[3]), "m"(a[4])
        :"memory");
    return ret;
}

int
sys_exit(int64_t error_code) {
    return syscall(SYS_exit, error_code);
}

int
sys_fork(void) {
    return syscall(SYS_fork);
}

int
sys_wait(int64_t pid, int *store) {
    return syscall(SYS_wait, pid, store);
}

int
sys_yield(void) {
    return syscall(SYS_yield);
}

int
sys_kill(int64_t pid) {
    return syscall(SYS_kill, pid);
}

int
sys_getpid(void) {
    return syscall(SYS_getpid);
}

int
sys_putc(int64_t c) {
    return syscall(SYS_putc, c);
}

int
sys_pgdir(void) {
    return syscall(SYS_pgdir);
}

