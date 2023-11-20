#include <proc.h>
#include <kmalloc.h>
#include <string.h>
#include <sync.h>
#include <pmm.h>
#include <error.h>
#include <sched.h>
#include <elf.h>
#include <vmm.h>
#include <trap.h>
#include <stdio.h>
#include <stdlib.h>
#include <assert.h>

/* ------------- process/thread mechanism design&implementation -------------
(an simplified Linux process/thread mechanism )
introduction:
  ucore implements a simple process/thread mechanism. process contains the independent memory sapce, at least one threads
for execution, the kernel data(for management), processor state (for context switch), files(in lab6), etc. ucore needs to
manage all these details efficiently. In ucore, a thread is just a special kind of process(share process's memory).
------------------------------
process state       :     meaning               -- reason
    PROC_UNINIT     :   uninitialized           -- alloc_proc
    PROC_SLEEPING   :   sleeping                -- try_free_pages, do_wait, do_sleep
    PROC_RUNNABLE   :   runnable(maybe running) -- proc_init, wakeup_proc,
    PROC_ZOMBIE     :   almost dead             -- do_exit

-----------------------------
process state changing:

  alloc_proc                                 RUNNING
      +                                   +--<----<--+
      +                                   + proc_run +
      V                                   +-->---->--+
PROC_UNINIT -- proc_init/wakeup_proc --> PROC_RUNNABLE -- try_free_pages/do_wait/do_sleep --> PROC_SLEEPING --
                                           A      +                                                           +
                                           |      +--- do_exit --> PROC_ZOMBIE                                +
                                           +                                                                  +
                                           -----------------------wakeup_proc----------------------------------
-----------------------------
process relations
parent:           proc->parent  (proc is children)
children:         proc->cptr    (proc is parent)
older sibling:    proc->optr    (proc is younger sibling)
younger sibling:  proc->yptr    (proc is older sibling)
-----------------------------
related syscall for process:
SYS_exit        : process exit,                           -->do_exit
SYS_fork        : create child process, dup mm            -->do_fork-->wakeup_proc
SYS_wait        : wait process                            -->do_wait
SYS_exec        : after fork, process execute a program   -->load a program and refresh the mm
SYS_clone       : create child thread                     -->do_fork-->wakeup_proc
SYS_yield       : process flag itself need resecheduling, -- proc->need_sched=1, then scheduler will rescheule this process
SYS_sleep       : process sleep                           -->do_sleep
SYS_kill        : kill process                            -->do_kill-->proc->flags |= PF_EXITING
                                                                 -->wakeup_proc-->do_wait-->do_exit
SYS_getpid      : get the process's pid

*/

// the process set's list ���н��̿��ƿ��˫�������б�proc_struct�еĳ�Ա����list_link�����������������
list_entry_t proc_list;

#define HASH_SHIFT          10
#define HASH_LIST_SIZE      (1 << HASH_SHIFT)
#define pid_hashfn(x)       (hash32(x, HASH_SHIFT))

// has list for process set based on pid ���н��̿��ƿ�Ĺ�ϣ��proc_struct�еĳ�Ա����hash_link������pid�����������ϣ����
static list_entry_t hash_list[HASH_LIST_SIZE];

// idle proc
struct proc_struct* idleproc = NULL;
// init proc ָ��һ���ں��߳�
struct proc_struct* initproc = NULL;
// current proc ռ��CPU�Ҵ��ڡ����С�״̬���̿��ƿ�ָ��
struct proc_struct* current = NULL;

static int nr_process = 0;

void kernel_thread_entry(void);
void forkrets(struct trapframe* tf);
void switch_to(struct context* from, struct context* to);

// alloc_proc - alloc a proc_struct and init all fields of proc_struct
static struct proc_struct*
alloc_proc(void) {
    struct proc_struct* proc = kmalloc(sizeof(struct proc_struct));
    if (proc != NULL) {
        //LAB4:EXERCISE1 YOUR CODE
        /*
         * below fields in proc_struct need to be initialized
         *       enum proc_state state;                      // Process state
         *       int pid;                                    // Process ID
         *       int runs;                                   // the running times of Proces
         *       uintptr_t kstack;                           // Process kernel stack
         *       volatile bool need_resched;                 // bool value: need to be rescheduled to release CPU?
         *       struct proc_struct *parent;                 // the parent process
         *       struct mm_struct *mm;                       // Process's memory management field
         *       struct context context;                     // Switch here to run process
         *       struct trapframe *tf;                       // Trap frame for current interrupt
         *       uintptr_t cr3;                              // CR3 register: the base addr of Page Directroy Table(PDT)
         *       uint32_t flags;                             // Process flag
         *       char name[PROC_NAME_LEN + 1];               // Process name
         */
        proc->state = PROC_UNINIT;//���ý���Ϊ��ʼ̬
        proc->pid = -1;//���ý���pid��δ��ʼ��ֵ
        proc->runs = 0;
        proc->kstack = 0;
        proc->need_resched = 0;
        proc->parent = NULL;
        proc->mm = NULL;
        memset(&(proc->context), 0, sizeof(struct context));
        proc->tf = NULL;
        proc->cr3 = boot_cr3;//ʹ���ں�ҳĿ¼��Ļ�ַ
        proc->flags = 0;
        memset(&(proc->name), 0, PROC_NAME_LEN);
    }
    return proc;
}

// set_proc_name - set the name of proc
char*
set_proc_name(struct proc_struct* proc, const char* name) {
    memset(proc->name, 0, sizeof(proc->name));
    return memcpy(proc->name, name, PROC_NAME_LEN);
}

// get_proc_name - get the name of proc
char*
get_proc_name(struct proc_struct* proc) {
    static char name[PROC_NAME_LEN + 1];
    memset(name, 0, sizeof(name));
    return memcpy(name, proc->name, PROC_NAME_LEN);
}

// get_pid - alloc a unique pid for process
static int
get_pid(void) {
    // ʵ���ϣ�֮ǰ������MAX_PID=2*MAX_PROCESS����ζ��ID������Ŀ�Ǵ���PROCESS������Ŀ��
    // ��˲�����ֲ���PROCESS��ID�ɷֵ����
    static_assert(MAX_PID > MAX_PROCESS);
    struct proc_struct* proc;
    list_entry_t* list = &proc_list, * le;
    //next_safe��last_pid������������staticȫ�ֱ���
    static int next_safe = MAX_PID, last_pid = MAX_PID;
    //++last_pid>-MAX_PID,˵��pid�Լ��ֵ���ͷ����Ҫ��ͷ����
    if (++last_pid >= MAX_PID) {
        last_pid = 1;
        goto inside;
    }
    if (last_pid >= next_safe) {
    inside:
        next_safe = MAX_PID;
    repeat:
        le = list;
        //le�����̵߳�����ͷ
        //����һ������
        //ѭ��ɨ��ÿһ����ǰ���̣���һ�����еĽ��̺ź�last_pid���ʱ����last_pid+1��
        //�����еĽ��̺Ŵ���last_pidʱ������ζ�����Ѿ�ɨ��Ľ�����
        //[last_pid,min(next_safe, proc->pid)] ��ν��̺���δ��ռ�ã�����ɨ�衣
        while ((le = list_next(le)) != list) {
            proc = le2proc(le, list_link);
            if (proc->pid == last_pid) {
                //���proc��pid��last_pid��ȣ���last_pid��1
                //��Ȼ�����last_pid>=MAX_PID,then �����Ϊ1,ȷ����û��һ�����̵�pid��last_pid�غ�
                if (++last_pid >= next_safe) {
                    if (last_pid >= MAX_PID) {
                        last_pid = 1;
                    }
                    next_safe = MAX_PID;
                    goto repeat;
                }
            }
            //last_pid<pid<next_safe��ȷ������ܹ��ҵ���ôһ���������������䣬��úϷ���pid
            else if (proc->pid > last_pid && next_safe > proc->pid) {
                next_safe = proc->pid;
            }
        }
    }
    return last_pid;
}

// proc_run - make process "proc" running on cpu
// NOTE: before call switch_to, should load  base addr of "proc"'s new PDT
void
proc_run(struct proc_struct* proc) {
    if (proc != current) {
        // LAB4:EXERCISE3 YOUR CODE
        /*
        * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
        * MACROs or Functions:
        *   local_intr_save():        Disable interrupts
        *   local_intr_restore():     Enable Interrupts
        *   lcr3():                   Modify the value of CR3 register
        *   switch_to():              Context switching between two processes
        */
        struct proc_struct* prev = current;
        struct proc_struct* next = proc;
        bool intr_flag;
        local_intr_save(intr_flag);
        //change the current process to the new process����ǰ���еĽ�������ΪҪ�л��Ľ���
        current = proc;
        //change the page table to the new page table��ҳ�����½��̵�ҳ��
        //����ǰ��cr3�Ĵ�����Ϊ��Ҫ���н��̵�ҳĿ¼��
        lcr3(next->cr3);
        //use switch_to to new processʹ��switch_to�л����½���
        //�����������л�������ԭ�̵߳ļĴ������ָ��������̵߳ļĴ���
        switch_to(&(prev->context), &(next->context));
        local_intr_restore(intr_flag);
    }
}

// forkret -- the first kernel entry point of a new thread/process
// NOTE: the addr of forkret is setted in copy_thread function
//       after switch_to, the current proc will execute here.
static void
forkret(void) {
    forkrets(current->tf);
}

// hash_proc - add proc into proc hash_list
static void
hash_proc(struct proc_struct* proc) {
    list_add(hash_list + pid_hashfn(proc->pid), &(proc->hash_link));
}

// find_proc - find proc frome proc hash_list according to pid
struct proc_struct*
    find_proc(int pid) {
    if (0 < pid && pid < MAX_PID) {
        list_entry_t* list = hash_list + pid_hashfn(pid), * le = list;
        while ((le = list_next(le)) != list) {
            struct proc_struct* proc = le2proc(le, hash_link);
            if (proc->pid == pid) {
                return proc;
            }
        }
    }
    return NULL;
}

// kernel_thread - create a kernel thread using "fn" function
// NOTE: the contents of temp trapframe tf will be copied to 
//       proc->tf in do_fork-->copy_thread function
/**
 * kernel_thread���������˾ֲ�����tf�����ñ����ں��̵߳���ʱ�ж�֡�������ж�֡��ָ�봫�ݸ�do_fork����
 * ��do_fork���������copy_thread���������´����Ľ����ں�ջ��ר�Ÿ����̵��ж�֡����һ��ռ䡣
*/
int
kernel_thread(int (*fn)(void*), void* arg, uint32_t clone_flags) {
    //��trameframe���г�ʼ��
    struct trapframe tf;
    memset(&tf, 0, sizeof(struct trapframe));
    //�����ں��̵߳Ĳ����ͺ���ָ��
    tf.gpr.s0 = (uintptr_t)fn;// s0 �Ĵ������溯��ָ��
    tf.gpr.s1 = (uintptr_t)arg;// s1 �Ĵ������溯������
    //���� trapframe �е� status �Ĵ���
    // ���� trapframe �е� status �Ĵ�����SSTATUS��
    // SSTATUS_SPP��Supervisor Previous Privilege������Ϊ supervisor ģʽ����Ϊ����һ���ں��̣߳�
    // SSTATUS_SPIE��Supervisor Previous Interrupt Enable������Ϊ�����жϣ���Ϊ����һ���ں��̣߳�
    // SSTATUS_SIE��Supervisor Interrupt Enable������Ϊ�����жϣ���Ϊ���ǲ�ϣ�����̱߳��жϣ�
    // ����SPP��SPIEλ����ͬʱ���SIEλ���Ӷ�ʵ����Ȩ�����л��������ж�ʹ��״̬�������жϵĲ���
    tf.status = (read_csr(sstatus) | SSTATUS_SPP | SSTATUS_SPIE) & ~SSTATUS_SIE;

    //����ڵ㣨epc������Ϊ kernel_thread_entry ����
    tf.epc = (uintptr_t)kernel_thread_entry;

    //ʹ�� do_fork ����һ���½��̣��ں��߳�)
    return do_fork(clone_flags | CLONE_VM, 0, &tf);
}

// setup_kstack - alloc pages with size KSTACKPAGE as process kernel stack
static int
setup_kstack(struct proc_struct* proc) {
    struct Page* page = alloc_pages(KSTACKPAGE); //alloc pages with size KSTACKPAGE
    if (page != NULL) {
        proc->kstack = (uintptr_t)page2kva(page);
        return 0;
    }
    return -E_NO_MEM;
}

// put_kstack - free the memory space of process kernel stack
static void
put_kstack(struct proc_struct* proc) {
    free_pages(kva2page((void*)(proc->kstack)), KSTACKPAGE);
}

// copy_mm - process "proc" duplicate OR share process "current"'s mm according clone_flags
//         - if clone_flags & CLONE_VM, then "share" ; else "duplicate"
static int
copy_mm(uint32_t clone_flags, struct proc_struct* proc) {
    assert(current->mm == NULL);
    /* do nothing in this project */
    return 0;
}

// copy_thread - setup the trapframe on the  process's kernel stack top and
//             - setup the kernel entry point and stack of process
static void
copy_thread(struct proc_struct* proc, uintptr_t esp, struct trapframe* tf) {
    //�����������ں�ջ�Ϸ����һƬ�ռ�������trapframe
    proc->tf = (struct trapframe*)(proc->kstack + KSTACKSIZE - sizeof(struct trapframe));
    *(proc->tf) = *tf;

    // Set a0 to 0 so a child process knows it's just forked
    //���ǽ�trapframe�е�a0�Ĵ���������ֵ������Ϊ0��˵�����������һ���ӽ��̡�
    proc->tf->gpr.a0 = 0;
    proc->tf->gpr.sp = (esp == 0) ? (uintptr_t)proc->tf : esp;

    //���������е�ra����Ϊ��forkret��������ڣ����Ұ�trapframe���������ĵ�ջ����
    proc->context.ra = (uintptr_t)forkret;
    proc->context.sp = (uintptr_t)(proc->tf);
}

/* do_fork -     parent process for a new child process
 * @clone_flags: used to guide how to clone the child process
 * @stack:       the parent's user stack pointer. if stack==0, It means to fork a kernel thread.
 * @tf:          the trapframe info, which will be copied to child process's proc->tf
 */
int
do_fork(uint32_t clone_flags, uintptr_t stack, struct trapframe* tf) {
    int ret = -E_NO_FREE_PROC;
    struct proc_struct* proc;
    if (nr_process >= MAX_PROCESS) {
        goto fork_out;
    }
    ret = -E_NO_MEM;
    //LAB4:EXERCISE2 YOUR CODE
    /*
     * Some Useful MACROs, Functions and DEFINEs, you can use them in below implementation.
     * MACROs or Functions:
     *   alloc_proc:   create a proc struct and init fields (lab4:exercise1)
     *   setup_kstack: alloc pages with size KSTACKPAGE as process kernel stack
     *   copy_mm:      process "proc" duplicate OR share process "current"'s mm according clone_flags
     *                 if clone_flags & CLONE_VM, then "share" ; else "duplicate"
     *   copy_thread:  setup the trapframe on the  process's kernel stack top and
     *                 setup the kernel entry point and stack of process
     *   hash_proc:    add proc into proc hash_list
     *   get_pid:      alloc a unique pid for process
     *   wakeup_proc:  set proc->state = PROC_RUNNABLE
     * VARIABLES:
     *   proc_list:    the process set's list
     *   nr_process:   the number of process set
     */

     //    1. call alloc_proc to allocate a proc_struct���䲢��ʼ�����̿��ƿ飨alloc_proc������
    if ((proc = alloc_proc()) == NULL) {
        goto fork_out;
    }
    proc->parent = current;
    //    2. call setup_kstack to allocate a kernel stack for child process���䲢��ʼ���ں�ջ��setup_stack������
    if ((setup_kstack(proc)) == -E_NO_MEM) {
        goto bad_fork_cleanup_kstack;
    }
    //    3. call copy_mm to dup OR share mm according clone_flag����clone_flags�����Ǹ��ƻ��ǹ����ڴ����ϵͳ��copy_mm������
    if (copy_mm(clone_flags, proc) != 0) {
        goto bad_fork_cleanup_proc;
    }
    //    4. call copy_thread to setup tf & context in proc_struct���ý��̵��ж�֡�������ģ�copy_thread������
    copy_thread(proc, stack, tf);
    //    5. insert proc_struct into hash_list && proc_list�����úõĽ��̼�������
    bool intr_flag;
    local_intr_save(intr_flag);
    proc->pid = get_pid();
    hash_proc(proc);
    list_add(&proc_list, &(proc->list_link));
    nr_process++;
    local_intr_restore(intr_flag);
    //    6. call wakeup_proc to make the new child process RUNNABLE���½��Ľ�����Ϊ����̬
    wakeup_proc(proc);
    //    7. set ret vaule using child proc's pid������ֵ��Ϊ�߳�id
    ret = proc->pid;


fork_out:
    return ret;

bad_fork_cleanup_kstack:
    put_kstack(proc);
bad_fork_cleanup_proc:
    kfree(proc);
    goto fork_out;
}

// do_exit - called by sys_exit
//   1. call exit_mmap & put_pgdir & mm_destroy to free the almost all memory space of process
//   2. set process' state as PROC_ZOMBIE, then call wakeup_proc(parent) to ask parent reclaim itself.
//   3. call scheduler to switch to other process
int
do_exit(int error_code) {
    panic("process exit!!.\n");
}

// init_main - the second kernel thread used to create user_main kernel threads
static int
init_main(void* arg) {
    cprintf("this initproc, pid = %d, name = \"%s\"\n", current->pid, get_proc_name(current));
    cprintf("To U: \"%s\".\n", (const char*)arg);
    cprintf("To U: \"en.., Bye, Bye. :)\"\n");
    return 0;
}

// proc_init - set up the first kernel thread idleproc "idle" by itself and 
//           - create the second kernel thread init_main
//idleproc�����ں˵�ǰ����ִ�е��̣߳���idleproc�ǵ�0���ں��߳�
void
proc_init(void) {
    int i;
    //init proc_list
    list_init(&proc_list);
    //init hash_list
    for (i = 0; i < HASH_LIST_SIZE; i++) {
        list_init(hash_list + i);
    }

    //������������idleproc�ں��̺߳�initproc�ں��̵߳Ĵ������ƹ���
    //judge the idleproc whether alloc_proc or not
    if ((idleproc = alloc_proc()) == NULL) {
        panic("cannot alloc idleproc.\n");
    }

    // check the proc structure
    int* context_mem = (int*)kmalloc(sizeof(struct context));// �ں˷��亯��
    memset(context_mem, 0, sizeof(struct context));
    int context_init_flag = memcmp(&(idleproc->context), context_mem, sizeof(struct context));

    int* proc_name_mem = (int*)kmalloc(PROC_NAME_LEN);
    memset(proc_name_mem, 0, PROC_NAME_LEN);
    int proc_name_flag = memcmp(&(idleproc->name), proc_name_mem, PROC_NAME_LEN);

    if (idleproc->cr3 == boot_cr3 && idleproc->tf == NULL && !context_init_flag
        && idleproc->state == PROC_UNINIT && idleproc->pid == -1 && idleproc->runs == 0
        && idleproc->kstack == 0 && idleproc->need_resched == 0 && idleproc->parent == NULL
        && idleproc->mm == NULL && idleproc->flags == 0 && !proc_name_flag
        ) {
        cprintf("alloc_proc() correct!\n");

    }

    idleproc->pid = 0; //����idleproc�Ϸ������֤�ŨC0����������˳�ر�����idleproc�ǵ�0���ں��̡߳�ͨ������ͨ��pid�ĸ�ֵ����ʾ�̵߳Ĵ��������ȷ��
    idleproc->state = PROC_RUNNABLE; //�ı���idleproc��״̬��ʹ�����ӡ�������ת���ˡ�׼��������
    idleproc->kstack = (uintptr_t)bootstack; //idleproc��ʹ�õ��ں�ջ����ʼ��ַ����Ҫע���Ժ�������̵߳��ں�ջ����Ҫͨ��������
    idleproc->need_resched = 1; //����˱�־λΪ1�����ϵ���schedule�����л�����������
    set_proc_name(idleproc, "idle");
    nr_process++;

    // ���õ�ǰ���е��߳�Ϊidleproc
    current = idleproc;

    int pid = kernel_thread(init_main, "Hello world!!", 0);
    if (pid <= 0) {
        panic("create init_main failed.\n");
    }

    initproc = find_proc(pid);
    set_proc_name(initproc, "init");

    assert(idleproc != NULL && idleproc->pid == 0);
    assert(initproc != NULL && initproc->pid == 1);
}

// cpu_idle - at the end of kern_init, the first kernel thread idleproc will do below works
void
cpu_idle(void) {
    while (1) {
        //�жϵ�ǰ�ں��߳�idleproc��need_resched�Ƿ�Ϊ0
        if (current->need_resched) {
            //����schedule�������������ڡ�������̬�Ľ���ִ�С�
            schedule();
        }
    }
}

