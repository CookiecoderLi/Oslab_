#### 练习1：分配并初始化一个进程控制块

##### 1.实现过程

###### 1.1进程控制块

首先，我们设计了一个管理线程的数据结构，即进程控制块，它包含了进程的一些基本信息，通过双向链表连接在一起，便于随时进行插入、删除和查找等操作。
    struct proc_struct {
        enum proc_state state;                      // Process state
        int pid;                                    // Process ID
        int runs;                                   // the running times of Proces
        uintptr_t kstack;                           // Process kernel stack 
        volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
        struct proc_struct *parent;                 // the parent process 
        struct mm_struct *mm;                       // Process's memory management field 
        struct context context;                     // Switch here to run process
        struct trapframe *tf;                       // Trap frame for current interrupt 保存了进程的中断帧
        uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT) 
        uint32_t flags;                             // Process flag
        char name[PROC_NAME_LEN + 1];               // Process name
        list_entry_t list_link;                     // Process link list 
        list_entry_t hash_link;                     // Process hash list
    };

* state:进程所处的状态。uCore中进程状态有四种：分别是PROC_UNINIT、PROC_SLEEPING、PROC_RUNNABLE、PROC_ZOMBIE。

* pid:进程的ID。

* runs:进程运行时间。

* kstack：内核栈，每个线程都有一个并且位于内核地址空间的不同位置。

* need_resched:表示是否需要重新调度

* parent:里面保存了进程的父进程的指针。在内核中，只有内核创建的idle进程没有父进程，其他进程都有父进程。

* mm:保存了内存管理的信息，包括内存映射，虚存管理等内容。

* context:保存了进程执行的上下文，也就是几个关键的寄存器的值。

* tf:保存了进程的中断帧。

* cr3:保存页表所在的基址。

* flags:进程标志。

* name:进程名。
  
  ###### 1.2.实验思路
  
  alloc_proc函数主要用来初始化进程控制块，即初始化proc_struct结构体里面的各成员变量。
  
      proc->state = PROC_UNINIT;
      proc->pid = -1;
      proc->runs = 0;
      proc->kstack = 0;
      proc->need_resched = 0; 
      proc->parent = NULL;
      proc->mm = NULL;
      memset(&(proc->context), 0, sizeof(struct context));
      proc->tf = NULL;
      proc->cr3 = boot_cr3;
      proc->flags = 0;
      memset(&(proc->name), 0, PROC_NAME_LEN);

* state:由于分配进程控制块时，进程还处于创建阶段，因此设置其状态为PROC_UNINIT，表示还没有进行初始化。

* pid:先设置pid为无效值-1，等调用完alloc_proc函数后再根据实际情况设置pid。

* cr3:设置为前面已经创建好的页目录表的基址。

* kstack:先初始化为0，后续再根据情况进行设置。

* tf:先初始化为NULL，同样后续根据情况进行设置。
  
  ##### 2.请说明proc_struct中struct context context和struct trapframe *tf成员变量含义和在本实验中的作用是啥？
  
  ###### 2.1.context的含义和作用

* 首先在context成员变量的结构体里面，它包含了ra，sp，s0~s11共14个寄存器。
  
      struct context {
        uintptr_t ra;
        uintptr_t sp;
        uintptr_t s0;
        uintptr_t s1;
        uintptr_t s2;
        uintptr_t s3;
        uintptr_t s4;
        uintptr_t s5;
        uintptr_t s6;
        uintptr_t s7;
        uintptr_t s8;
        uintptr_t s9;
        uintptr_t s10;
        uintptr_t s11;
      };

* 然后在switch_to函数里面，我们第一个参数代表当前线程的上下文，第二个参数表示新线程的上下文，通过switch_to函数将现在运行的线程的还是那个下午保存到from上下文中，并将to上下文的内容加载到CPU的各个寄存器中去，从而实现了两个上下文的切换。
  
      void switch_to(struct context *from, struct context *to);
      switch_to:
        # save from's registers
        STORE ra, 0*REGBYTES(a0)
        STORE sp, 1*REGBYTES(a0)
        STORE s0, 2*REGBYTES(a0)
        STORE s1, 3*REGBYTES(a0)
        STORE s2, 4*REGBYTES(a0)
        STORE s3, 5*REGBYTES(a0)
        STORE s4, 6*REGBYTES(a0)
        STORE s5, 7*REGBYTES(a0)
        STORE s6, 8*REGBYTES(a0)
        STORE s7, 9*REGBYTES(a0)
        STORE s8, 10*REGBYTES(a0)
        STORE s9, 11*REGBYTES(a0)
        STORE s10, 12*REGBYTES(a0)
        STORE s11, 13*REGBYTES(a0)
      
        # restore to's registers
        LOAD ra, 0*REGBYTES(a1)
        LOAD sp, 1*REGBYTES(a1)
        LOAD s0, 2*REGBYTES(a1)
        LOAD s1, 3*REGBYTES(a1)
        LOAD s2, 4*REGBYTES(a1)
        LOAD s3, 5*REGBYTES(a1)
        LOAD s4, 6*REGBYTES(a1)
        LOAD s5, 7*REGBYTES(a1)
        LOAD s6, 8*REGBYTES(a1)
        LOAD s7, 9*REGBYTES(a1)
        LOAD s8, 10*REGBYTES(a1)
        LOAD s9, 11*REGBYTES(a1)
        LOAD s10, 12*REGBYTES(a1)
        LOAD s11, 13*REGBYTES(a1)
  
  **所以可以看出，context就是进程的上下文，储存了进程执行时各个寄存器的值，其主要用来在进程切换时保存进程的上下文。在本实验中，idleproc进程被切换出去时，可以将其上下文保存在进程控制块的context中，从而当再次要运行idleproc进程时，能够恢复现场，继续执行，**
  
  ###### 2.2.tf的含义和作用

* 在copy_thread函数中，我们设置了当switch_to返回后将会跳转到forkret这一所有线程完成初始化后统一跳转的入口，同时我们还设置了当前的栈顶指针sp指向proc->tf。
  
      static void
      copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf) {
        proc->tf = (struct trapframe *)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
        *(proc->tf) = *tf;
        // Set a0 to 0 so a child process knows it's just forked
        proc->tf->gpr.a0 = 0;
        proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;
        proc->context.ra = (uintptr_t)forkret;
        proc->context.sp = (uintptr_t)(proc->tf);
      }

* forkrets函数让栈顶指针指向了前面设置好的trapframe的首地址后，便跳转到了__trapret，进行中断返回操作
  
      forkrets:
        # set stack to this new process's trapframe
        move sp, a0
        j __trapret

* 在__trapret中依次将前面设置好的临时trapframe中断帧中各个数据依次还原，然后完成中断返回。
  
      __trapret:
        RESTORE_ALL
        # go back from supervisor call
        sret
  
  **所以可以看出，当进程从用户空间跳进内核空间的时候，进程的执行状态被保存在了中断帧中。当要构造新的线程的时候，如果要将控制权转交给这个线程，需要使用中断返回的方式进行，因此需要构造一个伪造的中断返回现场traframe，使得可以正确的将控制权转交给新的线程。**
  
  #### 练习2：为新创建的内核线程分配资源（需要编码）
  
  创建一个内核线程需要分配和设置好很多资源。kernel_thread函数通过调用**do_fork**函数完成具体内核线程的创建工作。do_fork函数会调用alloc_proc函数来分配并初始化一个进程控制块，但alloc_proc只是找到了一小块内存用以记录进程的必要信息，并没有实际分配这些资源。ucore一般通过do_fork实际创建新的内核线程。do_fork的作用是，创建当前内核线程的一个副本，它们的执行上下文、代码、数据都一样，但是存储位置不同。因此，我们**实际需要”fork”的东西就是stack和trapframe**。在这个过程中，需要给新内核线程分配资源，并且复制原进程的状态。你需要完成在kern/process/proc.c中的do_fork函数中的处理过程。它的大致执行步骤包括：
  
  * 调用alloc_proc，首先获得一块用户信息块。
  * 为进程分配一个内核栈。
  * 复制原进程的内存管理信息到新进程（但内核线程不必做此事）
  * 复制原进程上下文到新进程
  * 将新进程添加到进程列表
  * 唤醒新进程
  * 返回新进程号
  
  请在实验报告中简要说明你的设计实现过程。请回答如下问题：
  
  * 请说明ucore是否做到给每个新fork的线程一个唯一的id？请说明你的分析和理由。
  
  1.设计实现
  
          //    1. call alloc_proc to allocate a proc_struct
          if(proc = alloc_proc == NULL){
              goto fork_out;
          }
          //    2. call setup_kstack to allocate a kernel stack for child process
          ret = setup_kstack(proc);
          if(ret != 0) {
              goto bad_fork_cleanup_proc;
          }
          //    3. call copy_mm to dup OR share mm according clone_flag
          ret = copy_mm(clone_flags,proc);
          if(ret != 0) {
              goto bad_fork_cleanup_kstack;
          }
          //    4. call copy_thread to setup tf & context in proc_struct
          copy_thread(proc,stack,tf);
          //    5. insert proc_struct into hash_list && proc_list
          bool intr_flag;
          local_intr_save(intr_flag);
          {
              proc->pid = get_pid();
              hash_proc(proc);
              list_add(&proc_list,&(proc->list_link));
              nr_process++;
          }
          local_intr_restore(intr_flag);
          //    6. call wakeup_proc to make the new child process RUNNABLE
          wakeup_proc(proc);
          //    7. set ret vaule using child proc's pid
          ret = proc->pid;
  
  2.ucore是否做到给每个新fork的线程一个唯一的id
  根据函数get_id()，可知每个调用fock的线程返回不同的id。
  
      // get_pid - alloc a unique pid for process
      static int
      get_pid(void) {
          //实际上，之前定义了MAX_PID=2*MAX_PROCESS，意味着ID的总数目是大于PROCESS的总数目的
          //因此不会出现部分PROCESS无ID可分的情况
          static_assert(MAX_PID > MAX_PROCESS);
          struct proc_struct *proc;
          list_entry_t *list = &proc_list, *le;
          //next_safe和last_pid两个变量，这里需要注意！ 它们是static全局变量！！！
          static int next_safe = MAX_PID, last_pid = MAX_PID;
          //++last_pid>-MAX_PID,说明pid以及分到尽头，需要从头再来
          if (++ last_pid >= MAX_PID) {
              last_pid = 1;
              goto inside;
          }
          if (last_pid >= next_safe) {
          inside:
              next_safe = MAX_PID;
          repeat:
              le = list; //le等于线程的链表头
              //遍历一遍链表
              //循环扫描每一个当前进程：当一个现有的进程号和last_pid相等时，则将last_pid+1；
              //当现有的进程号大于last_pid时，这意味着在已经扫描的进程中
              //[last_pid,min(next_safe, proc->pid)] 这段进程号尚未被占用，继续扫描。
              while ((le = list_next(le)) != list) {
                  proc = le2proc(le, list_link);
                  if (proc->pid == last_pid) {
                      //如果proc的pid与last_pid相等，则将last_pid加1
                      //当然，如果last_pid>=MAX_PID,then 将其变为1,确保了没有一个进程的pid与last_pid重合
                      if (++ last_pid >= next_safe) {
                          if (last_pid >= MAX_PID) {
                              last_pid = 1;
                          }
                          next_safe = MAX_PID;
                          goto repeat;
                      }
                  }
                  //last_pid<pid<next_safe，确保最后能够找到这么一个满足条件的区间，获得合法的pid
                  else if (proc->pid > last_pid && next_safe > proc->pid) {
                      next_safe = proc->pid;
                  }
              }
          }
          return last_pid;
      }
  
  之所以按照这样的过程来找寻id，因为暴力搜索复杂度较高，而操作系统内部的算法应强调复杂度小而快。其次，维护一个合法的pid的区间，不仅优化了时间效率，而且不同的调用get_pid函数的时候可以利用到先前调用这个函数的中间结果去求解；
  
  ### 练习3：编写proc_run 函数（需要编码）
  
  proc_run用于将指定的进程切换到CPU上运行。它的大致执行步骤包括：
  
  * 检查要切换的进程是否与当前正在运行的进程相同，如果相同则不需要切换。
  * 禁用中断。你可以使用`/kern/sync/sync.h`中定义好的宏`local_intr_save(x)`和`local_intr_restore(x)`来实现关、开中断。
  * 切换当前进程为要运行的进程。
  * 切换页表，以便使用新进程的地址空间。`/libs/riscv.h`中提供了`lcr3(unsigned int cr3)`函数，可实现修改CR3寄存器值的功能。
  * 实现上下文切换。`/kern/process`中已经预先编写好了`switch.S`，其中定义了`switch_to()`函数。可实现两个进程的context切换。
  * 允许中断。
  
  请回答如下问题：
  
  * 在本实验的执行过程中，创建且运行了几个内核线程？
  
  通过kernel_thread函数、proc_init函数以及具体的实现结果可知，本次实验共建立了两个内核线程。首先是`idleproc`内核线程，idleproc内核线程的工作就是不停地查询，看是否有其他内核线程可以执行了，如果有，马上让调度器选择那个内核线程执行（请参考cpu_idle函数的实现）。所以idleproc内核线程是在ucore操作系统没有其他内核线程可执行的情况下才会被调用。接着就是调用kernel_thread函数来创建initproc内核线程。initproc内核线程的工作就是显示“Hello World”，表明自己存在且能正常工作了。
  
  #### 扩展练习 Challenge
  
  ##### 1.说明语句local_intr_save(intr_flag);....local_intr_restore(intr_flag);是如何实现开关中断的？

* 首先我们定义了一个bool类型的变量intr_flag，用来记录调用local_intr_save函数的返回值，如果成功设置为禁止中断，其值为true
  
      #define local_intr_save(x) \
        do {                   \
            x = __intr_save(); \
        } while (0)

* 然后在__intr_save函数中，我们读取了trapframe 中的 status 寄存器（SSTATUS），如果线程为能够中断模式SSTATUS_SIE（Supervisor Interrupt Enable），我们就调用intr_disable()函数，将其设置为禁止中断。
  
      static inline bool __intr_save(void) {
        if (read_csr(sstatus) & SSTATUS_SIE) {
            intr_disable(); //
            return 1;
        }
        return 0;
      }
      void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }

* 然后最后调用local_intr_restore()函数，即__intr_restore()函数，因为之前定义的返回值intr_flag变为了true，所以就会调用intr_enable()函数，将其设置为允许中断。
  
      #define local_intr_restore(x) __intr_restore(x);
      static inline void __intr_restore(bool flag) {
        if (flag) {
            intr_enable();
        }
      }
