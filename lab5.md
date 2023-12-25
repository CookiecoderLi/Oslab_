#### 练习1: 加载应用程序并执行
##### 1.do_exceve函数
首先在do_exceve函数中会调用load_icode函数，来加载一个处于内存中的ELF二进制格式的文件到内存中去并执行。
```c
int do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
    struct mm_struct *mm = current->mm;
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) {
        return -E_INVAL;
    }

    if (len > PROC_NAME_LEN) { //进程名字的长度有上限 PROC_NAME_LEN
        len = PROC_NAME_LEN;
    }

    char local_name[PROC_NAME_LEN + 1];
    memset(local_name, 0, sizeof(local_name));
    memcpy(local_name, name, len);

    if (mm != NULL) {
        cputs("mm != NULL");
        lcr3(boot_cr3);
        if (mm_count_dec(mm) == 0) {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);//把进程当前占用的内存释放
        }
        current->mm = NULL;
    }
    //把新的程序加载到当前进程里的工作都在load_icode()函数里完成
    int ret;
    if ((ret = load_icode(binary, size)) != 0) { // 加载应用程序执行码到当前进程的新创建的用户态虚拟空间中
        goto execve_exit;//返回不为0，则加载失败
    }
    set_proc_name(current, local_name);
    return 0;

execve_exit:
    do_exit(ret);
    panic("already exit: %e.\n", ret);
}
```
##### 2.mm_create函数
这个函数申请了一块内存空间，如果申请成功，那么把该内存空间返回给当前进程，如果申请失败，内存空间等于NULL。
```c
struct mm_struct *mm_create(void) {
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

    if (mm != NULL) {
        list_init(&(mm->mmap_list));
        mm->mmap_cache = NULL;
        mm->pgdir = NULL;
        mm->map_count = 0;

        if (swap_init_ok) swap_init_mm(mm);
        else mm->sm_priv = NULL;
        
        set_mm_count(mm, 0);
        lock_init(&(mm->mm_lock));
    }    
    return mm;
}
```
##### 3.setup_pgdir函数
这个函数分配了一个新的页目录表，并且设置为分配内存空间的页目录表。
```c
static int setup_pgdir(struct mm_struct *mm) {
    struct Page *page;
    if ((page = alloc_page()) == NULL) {
        return -E_NO_MEM;
    }
    pde_t *pgdir = page2kva(page);
    memcpy(pgdir, boot_pgdir, PGSIZE);

    mm->pgdir = pgdir;
    return 0;
}
```
##### 4.mm_map函数
这个函数建立了虚拟内存空间的vma结构，使这片内存空间合法。
```c
int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
    struct vma_struct **vma_store) {
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
    if (!USER_ACCESS(start, end)) {
        return -E_INVAL;
    }

    assert(mm != NULL);
    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start) {
        goto out;
    }
    ret = -E_NO_MEM;

    if ((vma = vma_create(start, end, vm_flags)) == NULL) {
        goto out;
    }
    insert_vma_struct(mm, vma);
    if (vma_store != NULL) {
        *vma_store = vma;
    }
    ret = 0;

out:
    return ret;
}
```
##### 5.load_icode函数
load_icode函数主要用来加载和解析处于内存中的ELF文件格式的应用程序。
+ 调用mm_create函数申请进程所需的内存空间
+ 调用setup_pgdir函数来申请一个页目录表，并将ucore内核虚空间映射的内核页表(boot_pgdir)的内容映射到新目录表中，最后将mm_pgdir指向该页目录表
+ 解析该ELF格式的执行程序，并调用mm_map函数来根据程序各个段的起始位置和大小建立对应的vma结构
+ 根据执行程序各个段的大小分配物理内存空间，并根据执行程序各个段的起始位置确定虚拟地址，并在页表中建立好物理地址和虚拟地址的映射关系，然后把执行程序各个段的内容拷贝到相应的内核虚拟地址中
+ 调用mm_map函数给用户进程设置用户栈
+ 给当前进程设置mm、sr3、CR3，并且给用户态设置trapframe。
##### 6.具体实现
实现代码如下：
```c
tf->gpr.sp = USTACKTOP;
tf->epc = elf->e_entry;
tf->status = sstatus & ~(SSTATUS_SPP | SSTATUS_SPIE);
```
+ 首先把tf结构体的通用寄存器(gpr)中的栈指针设置为USTACKTOP，表示将用户栈栈顶地址赋值给用户进程的栈指针
+ 然后将tf结构的用户程序入口点(epc)设置为elf文件的入口地址
+ 最后将tf结构的状态寄存器(status)设置为sstatus，并将SPP和SPIE标志清除。
#### 练习二
##### copy_range 函数
它负责将内存从一个地址空间复制到另一个地址空间。
```c
int copy_range(pde_t *to, pde_t *from, uintptr_t start, uintptr_t end,
               bool share) {
    assert(start % PGSIZE == 0 && end % PGSIZE == 0);
    assert(USER_ACCESS(start, end));
    // copy content by page unit.
    do {
        // call get_pte to find process A's pte according to the addr start
        pte_t *ptep = get_pte(from, start, 0), *nptep;
        if (ptep == NULL) {
            start = ROUNDDOWN(start + PTSIZE, PTSIZE);
            continue;
        }
        // call get_pte to find process B's pte according to the addr start. If
        // pte is NULL, just alloc a PT.
        if (*ptep & PTE_V) {
            if ((nptep = get_pte(to, start, 1)) == NULL) {
                return -E_NO_MEM;
            }
            uint32_t perm = (*ptep & PTE_USER);
            // get page from ptep
            struct Page *page = pte2page(*ptep);
            // alloc a page for process B
            struct Page *npage = alloc_page();
            assert(page != NULL);
            assert(npage != NULL);
            int ret = 0;\
            memcpy(page2kva(npage), page2kva(page), PGSIZE);
            if ((ret = page_insert(to, npage, start, perm)) != 0) {
                return ret;
            }
            
            assert(ret == 0);
        }
        start += PGSIZE;
    } while (start != 0 && start < end);
    return 0;
}
```
+ 首先，函数使用了两个断言（assert）来确保起始地址（start）和结束地址（end）都是页面大小（PGSIZE）的整数倍，并且地址范围在用户空间内（USER_ACCESS）。这是为了确保函数在合法的内存范围内进行操作。
+ 接下来，函数使用一个循环来逐页复制内存内容。在循环内部：

1、调用 get_pte 函数来获取源地址空间中地址 start 对应的页表项（pte）指针 ptep。

2、 如果 ptep 为空指针，则将 start 向下舍入到前一个页的起始地址，并继续下一次循环。

3、 如果 ptep 不为空且包含有效的页表项（PTE_V 标志位），则继续下一步操作。
+ 对于有效的页表项，函数调用 get_pte 函数来获取目标地址空间中地址 start 对应的页表项指针 nptep。如果 nptep 为空指针，则分配一个新的页表。
+ 接下来，函数获取源地址空间中地址 start 对应的页表项指向的物理页面，并为目标地址空间分配一个新的物理页面。然后，使用 memcpy 函数将源页面的内容复制到目标页面。
+ 最后，函数调用 page_insert 函数来建立目标地址空间中新页面的映射关系，并更新相关标志位。
通过以上步骤，函数实现了将源地址空间中指定范围的内存内容复制到目标地址空间的过程。这个函数的实现涉及了页表操作、物理页面分配和内存内容复制等多个方面的操作。
##### 如何设计实现 Copy on Write 机制？给出概要设计，鼓励给出详细设计。
如果源地址空间中的页表项 ptep 是有效的（PTE_V 为 true），则表示该页是存在的，需要执行Copy-on-Write操作。在这种情况下，函数会为目标地址空间分配一个新的物理页面，并将源地址空间中的页面内容复制到新分配的物理页面中，然后建立目标地址空间中新页面的映射关系。

通过这段代码，实现了将源地址空间中指定范围的内存内容复制到目标地址空间的过程，并在需要时执行Copy-on-Write操作，确保多个进程可以共享内存页面，并在需要时进行延迟复制，提高了内存利用率和性能。
#### 练习三
##### 请分析 fork/exec/wait/exit 的执行流程。重点关注哪些操作是在用户态完成，哪些是在内核态完成？内核态与用户态程序是如何交错执行的？内核态执行结果是如何返回给用户程序的？
fork/exec/wait/exit 是与进程管理相关的四个关键操作。它们的执行流程以及内核态和用户态之间的交互分别如下：

1. fork：
   - 在用户态，父进程调用 fork() 系统调用，将触发从用户态进入内核态，将当前进程的上下文信息保存到内核栈中。
   - 在内核态，内核会创建一个新的进程控制块（PCB），并将父进程的内存空间、寄存器状态等信息复制给子进程。
   - 然后内核会更新进程表，将子进程的 PCB 加入到进程表中，并将子进程的状态设置为就绪态。
   - 最后，内核会将子进程的 PCB 加入到调度队列中，等待调度执行。

2. exec：
   - 在用户态，进程调用 exec() 系统调用，触发从用户态进入内核态，将当前进程的上下文信息保存到内核栈中。
   - 在内核态，内核会根据参数中指定的可执行文件，读取文件内容，并解析可执行文件的格式，将程序代码加载到内存中。
   - 然后，内核会更新进程的内存映射关系，将新的程序代码映射到进程的地址空间中。
   - 最后，内核会更新进程的上下文信息，包括程序计数器（PC）、堆栈指针（SP）等，然后将控制权交还给新的程序。

3. wait：
   - 在用户态，父进程调用 wait() 系统调用，触发从用户态进入内核态，将当前进程的上下文信息保存到内核栈中。
   - 在内核态，内核会检查子进程的状态，如果子进程还在运行，则将父进程置为等待状态，并加入到等待队列中。
   - 当子进程终止时，内核会更新子进程的状态，并通知父进程，父进程从等待队列中移除，然后将父进程置为就绪态，等待调度执行。

4. exit：
   - 在用户态，进程调用 exit() 系统调用，触发从用户态进入内核态，将当前进程的上下文信息保存到内核栈中。
   - 在内核态，内核会更新当前进程的状态为终止态，并释放进程占用的资源，包括内存、文件描述符等。
   - 然后，内核会检查是否有其他进程在等待当前进程，如果有，则通知等待的进程，更新其状态，并将其加入到就绪队列中，等待调度执行。
   - 最后，内核会从进程表中移除当前进程的 PCB，释放其占用的资源，然后选择一个新的进程执行。

在这些操作中，用户态程序通过系统调用触发进入内核态执行相关操作，内核态完成了进程管理的各项操作，包括创建进程、加载新的程序、等待子进程、终止进程等。在内核态执行的结果会通过寄存器或者内存中的特定位置返回给用户程序，例如，fork() 系统调用会返回子进程的进程ID给父进程，exec() 系统调用会将新程序的代码加载到进程的地址空间中，并更新进程的上下文信息，wait() 和 exit() 系统调用会更新进程的状态，并通过调用返回将控制权交还给用户程序。
##### 请给出 ucore 中一个用户态进程的执行状态生命周期图（包执行状态，执行状态之间的变换关系，以及产生变换的事件或函数调用）。（字符方式画即可）
用户态进程的执行状态生命周期图：

```
创建状态----->就绪状态----->运行状态----->终止状态
```

- 创建状态：进程被创建后，处于创建状态。这个状态是由操作系统内核创建进程控制块（PCB）并分配资源完成的。
- 就绪状态：当进程被创建后，它会进入就绪状态，等待被调度执行。这个状态是由操作系统内核在进程创建后将进程加入到调度队列中完成的。
- 运行状态：当进程被调度执行时，它会进入运行状态，开始执行程序代码。这个状态是由操作系统内核在调度队列中选择进程执行完成的。
- 终止状态：当进程执行完成或者被终止时，它会进入终止状态，等待被操作系统回收资源。这个状态是由操作系统内核在进程执行完成或者终止后更新进程状态完成的。

在不同状态之间的变换关系和事件/函数调用如下：
- 创建状态到就绪状态：进程创建完成后，被加入到调度队列中，等待被调度执行。
- 就绪状态到运行状态：当调度器选择该进程执行时，进程从就绪状态变为运行状态。
- 运行状态到终止状态：进程执行完成或者被终止后，进程从运行状态变为终止状态。

