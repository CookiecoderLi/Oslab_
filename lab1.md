<h1><center>lab1实验报告</center></h1>

# 一、练习

### 练习1：理解内核启动中的程序入口操作

```
la sp, bootstacktop
```

1. 完成的操作
   将`bootstacktop`的地址加载到堆栈指针`sp`中，`sp`通常是指向栈顶的指针，即将`bootstacktop`的地址作为起始地址。

2. 目的
   在操作系统内核启动的时候，将栈顶指针设置到特定地址，可以建立一个可控的堆栈。
   在后续操作系统内核启动过程中可能发生函数调用、中断处理、堆栈操作等等，这时便需要这个可以有效控制、设计的堆栈，来保存函数的变量、返回地址或设计该栈的空间大小等，来保证系统的稳定性和可操作性。同时这样设置也可以确保内核有一个定义好的、不会与其他数据冲突的堆栈空间。

```
tail kern_init
```

1. 完成的操作
   通过尾调用`kern_init`，直接跳转到`kern_init`函数的入口地址。

2. 目的
   `kern_init`是内核初始化的主函数，尾调用后开始内核的初始化。同时使用尾调用直接跳转到目标函数，意味着当前函数的栈帧将**被新调用的函数重用**，可以避免在函数返回时需要额外的栈空间，防止栈溢出

## 练习2：完善中断处理

### 1.实现目标

对时钟中断进行处理的部分填写kern/trap/trap.c函数中处理时钟中断的部分，使操作系统每遇到100次时钟中断后，调用print_ticks子程序，向屏幕上打印一行文字”100 ticks”，在打印完10行后调用sbi.h中的shut_down()函数关机。

### 2.实现过程

#### 实现准备

+ trap.c文件中定义好了一个print_ticks函数，用来向屏幕上面打印一行文字"100 ticks"。
  
  ```
  static void print_ticks() {
    cprintf("%d ticks\n", TICK_NUM);
  #ifdef DEBUG_GRADE
    cprintf("End of Test.\n");
    panic("EOT: kernel seems ok.");
  #endif
  }
  ```

+ trap.c文件中定义了一个可改变值的变量num，并初始化其值为0，用来记录打印"100 ticks"的次数。
  
  ```
  volatile size_t num=0;
  ```

+ clock.c文件中定义好了一个可更改值的变量ticks作为计数器，并初始化赋予其值为0。
  
  ```
  volatile size_t ticks;
  // initialize time counter 'ticks' to zero
    ticks = 0;
  ```

+ clock.c文件中定义了一个clock_set_next_event函数，里面用到了OpenSBI提供的sbi_set_timer()接口，给这个接口传入一个时刻，它可以在那个时刻触发一次时钟终端，这个接口传入的参数是get_cycles() + timebase。
  
  ```
  void clock_set_next_event(void) { 
    sbi_set_timer(get_cycles() + timebase); 
    }
  ```
  
  + get_cycles()是在clock.c中定义的一个函数，里面利用rdtime的伪指令读取了CPU启动之后经过的真实时间，因为无论在RISCV32还是RISCV64架构中，time寄存器都是64为，所以对于64位架构，只需要调用一次rdtime，但对于32位架构，就要把64的time寄存器读到两个32位的整数里，然后拼凑出来形成64位。
  + timebase是定义好的静态变量，其值为100000。

+ sbi.c文件中定义了sbi_shutdown函数，用来进行关机。
  
  #### 实现逻辑

+ clock.c文件的初始化函数中已经调用了一次clock_set_next_event函数，它就会跳转到时钟中断处理的代码处，但之后每次如果要发生时钟中断，还需要再次调用。所以我们首先再次调用clock_set_next_event函数。
  
  ```
  clock_set_next_event();
  ```

+ 每调用一次时钟中断函数，我们让计数器的值增加1，当ticks的值为100的倍数时，也就是操作系统遇到了100次时钟中断，调用print_ticks函数，在屏幕上打印"100 ticks"，并使num的值加1。
  
  ```
  if (++ticks % TICK_NUM == 0) 
  {
    num++;
    print_ticks();
  }
  ```

+ 当num的值变为10后，也即向屏幕上打印了10次"100 ticks"后，调用sbi_shutdown()函数来关机。
  
  ```
  if(num==10){
    sbi_shutdown();
  }
  ```

### 3.实现结果

执行<strong>make qemu</strong>后，发现屏幕上打印了10条"100 ticks"，然后退出了qemu。
![实例图片](https://github.com/CookiecoderLi/Oslab_/blob/master/%E6%95%88%E6%9E%9C%E5%9B%BE.png)  
执行<strong>make grade</strong>后，可以看到得分为100，满足实验要求！
![实例图片](https://github.com/CookiecoderLi/Oslab_/blob/master/grade.png)

## 扩展练习1：描述与理解中断流程

异常产生后，进入中断入口点的入口函数__alltraps，首先保存上下文，然后跳转到trap函数，trap函数中是对各种中断类型的处理流程，从而对中断进行处理。trap函数指向完后，会回到__alltraps函数里继续向下进行，进入__trapret函数，在这里恢复上下文并继续运行。涉及代码如下：

```
   .globl __alltraps
.align(2) #中断入口点 __alltraps必须四字节对齐
__alltraps:
    SAVE_ALL #保存上下文
    move  a0, sp #传递参数。
    jal trap 
    .globl __trapret
__trapret:
    RESTORE_ALL
    sret
```

1. mov a0,sp的目的
   用寄存器a0存储当前函数的地址，方便中断处理完成后的返回。

2. SAVE_ALL中寄存器保存在栈中的位置是什么确定的
   由当前栈顶的位置来确定。

3. 对任何中断，__alltraps中都需要保存所有寄存器吗？为什么
   需要。因为任何处理机制都有可能对寄存器的值进行修改，从而导致安全性隐患。

## 扩展练习2：理解上下文切换机制

1. 在trapentry.S中汇编代码 csrw sscratch, sp；csrrw s0, sscratch, x0实现了什么操作，目的是什么？
   指定汇编代码操作与目的
   
   1. **`csrw sscratch, sp`**:
      `csrw` 指令将一个寄存器的值写入一个 CSR。
      这条指令将堆栈指针 `sp` 的值写入 `sscratch` CSR。`sscratch` 是一个特殊的寄存器，通常在异常或中断处理中用作临时存储，或作为中间值的存储。
   
   2. **`csrrw s0, sscratch, x0`**:
      `csrrw` 是 "Control and Status Register Read-Write" 的缩写，它读取一个 CSR 的值并将其写入一个寄存器，同时将另一个寄存器的值写入该 CSR。
      这条指令做了以下操作：
      将 `sscratch` CSR 的值读取到 `s0` 寄存器。
      将 `x0` 寄存器的值（这是一个固定的零寄存器，总是为 0）写入 `sscratch` CSR。
   
   这两条指令的组合实现了以下操作：
      将当前的堆栈指针 `sp` 保存到 `sscratch` CSR。
      将 `sscratch` CSR 的值（即先前的 `sp` 值）读取到 `s0` 寄存器。
      将 `sscratch` 设置为 0。
      这样做的目的是为了在异常或中断处理中保存 `sp` 的原始值，并将其放入 `s0` 寄存器以供后续使用。同时，通过将 `sscratch` 设置为 0，可以为后续的异常或中断处理提供一个标志，表明当前的中断或异常是从内核模式触发的，而不是从用户模式。这是因为如果在处理一个异常或中断时发生另一个异常或中断，`sscratch` 的值为 0 可以作为一个标志，提示处理程序这是一个嵌套的中断，并且来自内核。

2. save all里面保存了stval scause这些csr，而在restore all里面却不还原它们？那么store的意义何在？
   `scause` 和 `stval`，在异常或中断发生时由硬件自动设置。这些寄存器的值提供了关于异常或中断原因的信息。处理程序需要这些信息来确定如何处理异常或中断。在处理完异常或中断并返回原始代码之后，这些寄存器的值不再重要，不需要恢复它们。
   `stval` 寄存器在某些异常中包含有关异常原因的有用信息，但一旦处理程序读取了这些信息，就不需要再恢复原始值了。

## 扩展练习3：完善异常中断

代码如下：

```
void exception_handler(struct trapframe *tf) {
    switch (tf->cause) {
        case CAUSE_MISALIGNED_FETCH:
            break;
        case CAUSE_FAULT_FETCH:
            break;
        case CAUSE_ILLEGAL_INSTRUCTION:
             // 非法指令异常处理
             /* LAB1 CHALLENGE3   YOUR CODE : 2110508 */
            //(1)输出指令异常类型（ Illegal instruction）
              cprintf("Exception type:lllegal instruction\n");
            //(2)输出异常指令地址
              cprintf("llegal instruction caught at 0x%08x\n",tf->badvaddr);
            //(3)更新 tf->epc寄存器
              tf->epc=tf->epc+4;
            break;
        case CAUSE_BREAKPOINT:
            //断点异常处理
            /* LAB1 CHALLLENGE3   YOUR CODE : 2110508 */
            //(1)输出指令异常类型（ breakpoint）
            	  cprintf("Exception type:breakpoint\n");
            //(2)输出异常指令地址
             	  cprintf("ebreak caught at 0x%08x\n",tf->badvaddr);
            //(3)更新 tf->epc寄存器
            	  tf->epc=tf->epc+4;
            break;
```


