<h1><center>lab0.5实验报告</center></h1>

# 一、实验内容

## 1.使用交叉编译器完成ucore内核的映像文件生成

进入lab0源代码的根目录下执行`make qemu`指令，make工具将解析Makefile文件，并执行交叉编译。

```
.PHONY: qemu 
qemu: $(UCOREIMG) $(SWAPIMG) $(SFSIMG)
    $(V)$(QEMU) \
        -machine virt \
        -nographic \
        -bios default \
        -device loader,file=$(UCOREIMG),addr=0x80200000
```

`.PHONY`用于指定make工具的伪目标，之后带有`$`的变量名在Makefile文件中都被定义，随后在`$(QEMU)`命令下启动QEMU虚拟机设置机器类型为 `virt`，使用了 `-nographic` 选项，意味着不使用图形界面，而是在终端中运行。使用 `-bios default` 指定默认的 BIOS，并使用 `-device` 选项加载 `$(UCOREIMG)` 到指定的地址 `0x80200000`。



## 2.使用qemu和gdb调试源代码

在lab0源代码的根目录下打开多个bash，在一个bash中输入`make debug`，然后在另一个bash中输入`make gdb`开始调试。

```
Reading symbols from bin/kernel...done.
The target architecture is assumed to be riscv:rv64
Remote debugging using localhost:1234
0x0000000000001000 in ?? ()
(gdb)
```

输入指令`x/10i $pc`显示即将执行的10条汇编指令

```
(gdb) x/10i $pc
=> 0x1000:    auipc    t0,0x0
   0x1004:    addi    a1,t0,32
   0x1008:    csrr    a0,mhartid
   0x100c:    ld    t0,24(t0)
   0x1010:    jr    t0
   0x1014:    unimp
   0x1016:    unimp
   0x1018:    unimp
   0x101a:    0x8000
   0x101c:    unimp
```

使用ni或si指令可以实现单步执行

```
(gdb) ni
0x0000000000001004 in ?? ()
(gdb) si
0x0000000000001008 in ?? ()
(gdb) 
```

使用info r t0可以显示寄存器t0的值，因此通过这个可以得到前几条指令完成的任务。

```
(gdb) ni
0x0000000000001004 in ?? ()
(gdb) si
0x0000000000001008 in ?? ()
(gdb) info r t0
t0             0x0000000000001000    4096
(gdb) ni
0x000000000000100c in ?? ()
(gdb) info r t0
t0             0x0000000000001000    4096
(gdb) ni
0x0000000000001010 in ?? ()
(gdb) ni
0x0000000080000000 in ?? ()
(gdb) info r t0
t0             0x0000000080000000    2147483648
```

发现当执行到jr t0时跳转到0x80000000地址处继续执行。根据实验指导手册，这个地址加载着qemu自带的bootloader：OpenSBI.bin，启动OpenSBI固件。

> 在QEMU模拟的riscv计算机里，我们使用QEMU自带的bootloader: OpenSBI固件，那么在 Qemu 开始执行任何指令之前，首先两个文件将被加载到 Qemu 的物理内存中：即作为 bootloader 的 OpenSBI.bin 被加载到物理内存以物理地址 0x80000000 开头的区域上，同时内核镜像 os.bin 被加载到以物理地址 0x80200000 开头的区域上

此时查看将要执行的10条汇编指令为

```
(gdb) x/10i $pc
=> 0x80000000:    csrr    a6,mhartid
   0x80000004:    bgtz    a6,0x80000108
   0x80000008:    auipc    t0,0x0
   0x8000000c:    addi    t0,t0,1032
   0x80000010:    auipc    t1,0x0
   0x80000014:    addi    t1,t1,-16
   0x80000018:    sd    t1,0(t0)
   0x8000001c:    auipc    t0,0x0
   0x80000020:    addi    t0,t0,1020
   0x80000024:    ld    t0,0(t0)
```

在0x80200000处（`0x80200000`是`kernel.ld`中定义的`BASE_ADDRESS`（加载地址）所决定的）打断点，后执行到断点处，并查看将要执行的十条命令

```
(gdb) b *0x80200000
Breakpoint 1 at 0x80200000: file kern/init/entry.S, line 7.
(gdb) c
Continuing.

Breakpoint 1, kern_entry () at kern/init/entry.S:7
7        la sp, bootstacktop
```

```
(gdb) x/10i $pc
=> 0x80200000 <kern_entry>:    auipc    sp,0x3
   0x80200004 <kern_entry+4>:    mv    sp,sp
   0x80200008 <kern_entry+8>:    
    j    0x8020000c <kern_init>
   0x8020000c <kern_init>:    auipc    a0,0x3
   0x80200010 <kern_init+4>:    addi    a0,a0,-4
   0x80200014 <kern_init+8>:    auipc    a2,0x3
   0x80200018 <kern_init+12>:    addi    a2,a2,-12
   0x8020001c <kern_init+16>:    addi    sp,sp,-16
   0x8020001e <kern_init+18>:    li    a1,0
   0x80200020 <kern_init+20>:    sub    a2,a2,a0
```

正如上述`0x80200000`是`kernel.ld`中定义的`BASE_ADDRESS`（加载地址）所决定的，同时在kernel.ld中也定义了入口点为kern_entry,查看entry.S相应代码为


        .section .text,"ax",%progbits
        .globl kern_entry
    kern_entry:
        la sp, bootstacktop
        tail kern_init

发现对应代码和汇编语言都是kern_entry后紧跟kern_init，相互对应，没有问题~

同时当我们c跳转到地址0x80200000处时，`make debug`界面出现如下显示

```
OpenSBI v0.4 (Jul  2 2019 11:53:53)
   ____                    _____ ____ _____
  / __ \                  / ____|  _ \_   _|
 | |  | |_ __   ___ _ __ | (___ | |_) || |
 | |  | | '_ \ / _ \ '_ \ \___ \|  _ < | |
 | |__| | |_) |  __/ | | |____) | |_) || |_
  \____/| .__/ \___|_| |_|_____/|____/_____|
        | |
        |_|

Platform Name          : QEMU Virt Machine
Platform HART Features : RV64ACDFIMSU
Platform Max HARTs     : 8
Current Hart           : 0
Firmware Base          : 0x80000000
Firmware Size          : 112 KB
Runtime SBI Version    : 0.1

PMP0: 0x0000000080000000-0x000000008001ffff (A)
PMP1: 0x0000000000000000-0xffffffffffffffff (A,R,W,X)

```

证明OpenSBI已经启动。再次输入指令，在kern_init处打断点，并运行到该处。

输入`disassemble kern_init`查看`kern_init`对应的RISC-V代码

```
(gdb) disassemble kern_init
Dump of assembler code for function kern_init:
=> 0x000000008020000c <+0>:    auipc    a0,0x3
   0x0000000080200010 <+4>:    addi    a0,a0,-4 # 0x80203008
   0x0000000080200014 <+8>:    auipc    a2,0x3
   0x0000000080200018 <+12>:    addi    a2,a2,-12 # 0x80203008
   0x000000008020001c <+16>:    addi    sp,sp,-16
   0x000000008020001e <+18>:    li    a1,0
   0x0000000080200020 <+20>:    sub    a2,a2,a0
   0x0000000080200022 <+22>:    sd    ra,8(sp)
   0x0000000080200024 <+24>:    jal    ra,0x802000ba <memset>
   0x0000000080200028 <+28>:    auipc    a1,0x0
   0x000000008020002c <+32>:    addi    a1,a1,1208 # 0x802004e0
   0x0000000080200030 <+36>:    auipc    a0,0x0
   0x0000000080200034 <+40>:    addi    a0,a0,1232 # 0x80200500
   0x0000000080200038 <+44>:    jal    ra,0x80200058 <cprintf>
   0x000000008020003c <+48>:    j    0x8020003c <kern_init+48>
---Type <return> to continue, or q <return> to quit---
End of assembler dump.
```

观察发现这个函数的最后一条指令`0x000000008020003c <+48>: j 0x8020003c <kern_init+48>`是跳转到自己开始的地址，所以代码将会一直循环下去。

继续`continue`(c)，观察debug的窗口，发现有新输出：

```
(THU.CST) os is loading ...
```

实验结束。



# 二、练习1

## 1.RISC-V硬件加电后的几条指令

以5条为例，在0x1000到0x1010之间。

```
0x1000:    auipc    t0,0x0
   0x1004:    addi    a1,t0,32
   0x1008:    csrr    a0,mhartid
   0x100c:    ld    t0,24(t0)
   0x1010:    jr    t0
```

## 2.完成的功能

`auipc t0,0x0`：`auipc`将立即数0x0加到pc（当前程序计数器）上，即将当前 PC 的值（高 20 位）与指定的立即数进行拼接，然后将结果存储到目标寄存器中。

`addi a1，t0，32`：将立即数32加到t0上，并将结果存储在a1，此时a1的地址为0x20。

`csrr a0，mhartid`：读取寄存器mhartid的值，存储在a0中，mhartid为当前线程的id。

`ld t0，24（t0）`：从t0+24地址处读取一个双字（8字节），存到t0；

`jr t0`：寄存器跳转，跳转到t0处，这里指向0x80000000，然后加载bootloader，硬件加电。



# 三、知识点
