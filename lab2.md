# Lab2

## First-fit分配算法

### 1.基本思想

First-fit算法是连续物理内存分配算法的一种，通过使用双向链表的方式将空闲的内存块按照地址从小到大的方式连接起来。当需要分配内存时，从低地址向高地址查找，**一旦找到可以满足要求的内存块，就将该内存块分配出去**。如果选择的块明显的大小大于请求的内存大小，通常将其拆分，将剩下的块作为另一个空闲块添加到空闲块列表中。

### 2.准备工作

##### （1）物理页结构Page

首先我们在文件kern/mm/memlayout.h中定义了一个Page的结构体，用来描述每个物理页的属性信息。

```
struct Page {
    int ref;                        // page frame's reference counter
    uint64_t flags;                 // array of flags that describe the status of the page frame
    unsigned int property;          // the num of free block, used in first fit pm manager
    list_entry_t page_link;         // free list link
};
```

+ ref表示该物理页的引用次数。

+ flags表示该物理页的状态。在kern/mm/memlayout.h中可以看到：flags用到了两个bit表示也当前的两种属性。对于PG_reserved，当bit为1时，它表示该页被保留为内核占用，不能被分配和释放；当bit为0，则该页不是保留页。对于PG_property，如果为1表示该页可以被分配，如果设置为0，表示该页已经被分配出去或不是head page。
  
  ```
  #define PG_reserved                 0       // if this bit=1: the Page is reserved for kernel, cannot be used in alloc/free_pages; otherwise, this bit=0 
  #define PG_property                 1       // if this bit=1: the Page is the head page of a free memory block(contains some continuous_addrress pages), and can be used in alloc_pages; if this bit=0: if the Page is the the head page of a free memory block, then this Page and the memory block is alloced. Or this Page isn't the head page.
  ```
  
  同时，还定义了一些函数来设置和清除PG_reserved、PG_property的值。
  
  ```
  #define SetPageReserved(page)       set_bit(PG_reserved, &((page)->flags))
  #define ClearPageReserved(page)     clear_bit(PG_reserved, &((page)->flags))
  #define PageReserved(page)          test_bit(PG_reserved, &((page)->flags))
  #define SetPageProperty(page)       set_bit(PG_property, &((page)->flags))
  #define ClearPageProperty(page)     clear_bit(PG_property, &((page)->flags))
  #define PageProperty(page)          test_bit(PG_property, &((page)->flags))
  ```

+ property用来地址连续的空闲页的个数。

+ page_link表示把多个连续内存空闲块连接在一起的双向链表指针。
  
  ##### （2）双向链表结构list_entry
  
  随着物理页的分配和释放，会分裂出许多地址不连续的内存空闲块，为了便于管理多个不连续的内存空闲块，我们引入了双向链表。在文件kern/libs/list.h中定义了一个双向链表的结构体和一系列对链表进行操作的函数。
  
  ```
  struct list_entry {
    struct list_entry *prev, *next;
  };
  ```
  
  ##### （3）空闲块列表free_area_t
  
  我们还在文件kern/mm/memlayout.h文件中定义了一个free_area_t的数据结构，它包含了一个list_entry结构的双向链表指针和记录在当前链表中的空闲页个数的变量nr_free。
  
  ```
  typedef struct {
    list_entry_t free_list;         // the list header
    unsigned int nr_free;           // number of free pages in this free list
  } free_area_t;
  ```
  
  ##### （4）物理内存页管理框架pmm_manager
  
  对于C语言来说，它不像C++具有虚函数，我们能够重写虚函数，但这里我们用到了**机制和策略**。先定义一个pmm_manager的结构体，在结构体中定义了它一个变量name来记录pmm_manager的成员变量和能够指向任何符合各自参数类型的函数的函数指针。
  
  ```
  truct pmm_manager {
    const char *name;  
    void (*init)( void);  
    void (*init_memmap)(struct Page *base,size_t n); 
    struct Page *(*alloc_pages)(size_t n); 
    void (*free_pages)(struct Page *base, size_t n);  
    size_t (*nr_free_pages)(void);  
    void (*check)(void);            
  };
  ```
  
  然后在init_pmm_manager中让pmm_manager指向了best_fit_pmm_manager了这个pmm_manager类型的结构体，在这个结构体里面给每个成员变量赋值了入口地址，从而调用我们想使用的函数。
  
  ```
  pmm_manager = &best_fit_pmm_manager;
  ```
  
  ##### （5）le2page函数
  
  在Page结构体里面，我们定义了一个双向链表page_link用来连接各个Page，但双向链表中的前向指针和后向指针都指向的是每个页中的pre位置处，所以我们还需要减去数据元素这块区域的值。  
  首先在kern/mm/memlayout.h文件里使用宏定义定义to_struct函数等同于le2page函数。
  
  ```
  #define le2page(le, member)                 \
    to_struct((le), struct Page, member)
  ```
  
  然后在再kern/libs/defs.h文件里宏定义to_struct函数的具体算法，用指针指向的位置减去一个偏移值。
  
  ```
  #define to_struct(ptr, type, member)                               \
    ((type *)((char *)(ptr) - offsetof(type, member)))
  ```
  
  并且我们定义了这个偏移值的算法,把Page放在以0地址开始的位置，pre所在的位置就是偏移值，也就是结构体里数据元素所占区域大小。
  
  ```
  #define offsetof(type, member)                                      \
    ((size_t)(&((type *)0)->member))
  ```
  
  ### 3.具体实现
  
  ##### （1）default_init函数
  
  default_init函数用来初始化free_area这个free_area_t结构体类型的变量。先调用链表的初始化函数list_init俩初始化链表，然后设置nr_free的值为0，表示可用内存块的数目为0。
  
  ```
  list_init(&free_list);
  nr_free = 0;
  ```
  
  ##### （2）default_init_memmap函数
  
  default_init_memmap函数根据page_init函数中传来的参数(第一个参数是某个连续空闲块的起始页，第二个参数是页的个数)来建立一个连续内存块的双向链表。

+ 循环遍历这个空闲块的每个页面，检查每个页面的PG_reserved，设置每个页的flags和property为0，表示该页空闲，设置每个页没有被引用过。
  
  ```
  struct Page *p = base;
  for (; p != base + n; p ++) {
        assert(PageReserved(p));
        p->flags = p->property = 0;
        set_page_ref(p, 0);
  }
  ```

+ 设置空闲块的第一页中property(块中总页数)为n，并设置PG_property为1，表示作为起始页，可以被用作分配内存，并将空闲页的数目加n。
  
  ```
  base->property = n;
  SetPageProperty(base);
  nr_free += n;
  ```

+ 如果链表是空的，则直接将base->page link链接到free list中，否则遍历该链表，将base->page link插入到第一个大于base的页的前面，并退出循环，如果已经到达链表结尾，将base插入到链表尾部。
  
  ```
  if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
  ```
  
  ##### （3）default_alloc_pages函数
  
  当申请内存空间时，default_alloc_pages函数用来分配内存。first-fit算法需要从链表头开始查找，通过调用list_next找到下一个空闲块，通过le2page函数来找到对应链表的Page，从而获取Page中的属性property，直到找到满足property>=n的空闲块，把找到的Page返回。

+ 遍历整个空闲链表，通过le2page函数获取链表元素对应的Page，判断当前页面的property是否大于等于n，如果满足说明空闲块的连续空页数大于等于n，可以分配，令page等于p，直接退出。
  
  ```
  struct Page *page = NULL;
  list_entry_t *le = &free_list;
  while ((le = list_next(le)) != &free_list) {
        struct Page *p = le2page(le, page_link);
        if (p->property >= n) {
            page = p;
            break;
        }
  }
  ```

+ 当找到空闲块时，会进行重新组织，删掉刚刚分配到空闲块，如果分配的空闲块的连续空闲页数大于n，创建以恶搞地址为page+n的新物理页，设置页面的property为page多出来的空闲连续页数，设置p为新的空闲块的起始页，并将新的空闲块的页插入到空闲页链表的后面。剩余空闲页的数目减n，清除page的page_property，表示该页已经被分配。
  
  ```
  if (page != NULL) {
        list_entry_t* prev = list_prev(&(page->page_link));
        list_del(&(page->page_link));
        if (page->property > n) {
            struct Page *p = page + n;
            p->property = page->property - n;
            SetPageProperty(p);
            list_add(prev, &(p->page_link));
        }
        nr_free -= n;
        ClearPageProperty(page);
    }
  ```
  
  ##### （4）default_free_pages函数
  
  default_free_pages函数用来释放分配的内存，将页面重新链接到空闲链表中，还需要考虑空闲块的合并问题。

+ 令p为释放块的起始页，遍历释放块的每个页进行初始化，检查每一页的Page_reserved位和Page_property是否都未被设置，设置每一页的flags都为0，表示可以分配，设置每一页的ref都为0，表示这页空闲。
  
  ```
  struct Page *p = base;
  for (; p != base + n; p ++) {
        assert(!PageReserved(p) && !PageProperty(p));
        p->flags = 0;
        set_page_ref(p, 0);
    }
  ```

+ 判断链表是否为空，如果为空直接将base->page link插到链表后面，否则遍历空闲链表，通过le2page函数来找到对应链表的Page，，将base->page link插入到第一个大于base的页的前面，并退出循环，如果已经到达链表结尾，将base插入到链表尾部。
  
  ```
  if (list_empty(&free_list)) {
        list_add(&free_list, &(base->page_link));
    } else {
        list_entry_t* le = &free_list;
        while ((le = list_next(le)) != &free_list) {
            struct Page* page = le2page(le, page_link);
            if (base < page) {
                list_add_before(le, &(base->page_link));
                break;
            } else if (list_next(le) == &free_list) {
                list_add(le, &(base->page_link));
            }
        }
    }
  ```

+ 判断前面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到前面的空闲页块中。首先更新前一个空闲页块的大小，加上当前页块的大小，并清除当前页块的属性标记，表示不再是空闲页块，从链表中删除当前页块，将指针指向前一个空闲页块，以便继续检查合并后的连续空闲页块。
  
  ```
  list_entry_t* le = list_prev(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (p + p->property == base) {
            p->property += base->property;
            ClearPageProperty(base);
            list_del(&(base->page_link));
            base = p;
        }
    }
  ```

+ 判断后面的空闲页块是否与当前页块是连续的，如果是连续的，则将当前页块合并到后面的空闲页块中。其合并步骤和上面类似，但需要清除后面页块的属性标记，从链表中删除后面的页块。
  
  ```
  le = list_next(&(base->page_link));
    if (le != &free_list) {
        p = le2page(le, page_link);
        if (base + base->property == p) {
            base->property += p->property;
            ClearPageProperty(p);
            list_del(&(p->page_link));
        }
    }
  ```
  
  ### 4.算法改进
  
  在进行分配以及释放内存的时候，在双向链表上进行操作的时间复杂度为O(n)，但是如果使用二叉搜索树对地址进行排序，从而对进程进行管理，就可以在查找页块时将时间复杂度降到O(logn)，从而提高算法的效率。



## best_fit算法（编程）

```
rookie@rookie-virtual-machine:~/桌面/labcode/lab2$ make grade
>>>>>>>>>> here_make>>>>>>>>>>>
make[1]: 进入目录“/home/rookie/桌面/labcode/lab2” + cc kern/init/entry.S + cc kern/init/init.c + cc kern/libs/stdio.c + cc kern/debug/panic.c + cc kern/debug/kdebug.c + cc kern/debug/kmonitor.c + cc kern/driver/clock.c + cc kern/driver/console.c + cc kern/driver/intr.c + cc kern/trap/trap.c + cc kern/trap/trapentry.S + cc kern/mm/pmm.c + cc kern/mm/default_pmm.c + cc kern/mm/best_fit_pmm.c + cc libs/string.c + cc libs/printfmt.c + cc libs/readline.c + cc libs/sbi.c + ld bin/kernel riscv64-unknown-elf-objcopy bin/kernel --strip-all -O binary bin/ucore.img make[1]: 离开目录“/home/rookie/桌面/labcode/lab2”
>>>>>>>>>> here_make>>>>>>>>>>>
<<<<<<<<<<<<<<< here_run_qemu <<<<<<<<<<<<<<<<<<
try to run qemu
qemu pid=30273
<<<<<<<<<<<<<<< here_run_check <<<<<<<<<<<<<<<<<<
  -check physical_memory_map_information:    OK
  -check_best_fit:                           OK
  -check ticks:                              OK
Total Score: 30/30
```

### 设计实现过程



### 如何对物理内存进行分配和释放



## 知识点

### 虚拟地址空间布局

```c
/* *
 * 详细描述了虚拟地址空间的布局。它包括内核空间、用户空间和一些保留区域。例如：
    KERNBASE 到 KERNTOP 是内核的物理内存映射区域。
    USERBASE 到 USERTOP 是用户空间的虚拟地址范围。
 * Virtual memory map:虚拟内存映射                                Permissions
 *                                                              kernel/user
 *
 *     4G ------------------> +---------------------------------+
 *                            |                                 |
 *                            |         Empty Memory (*)        |
 *                            |                                 |
 *                            +---------------------------------+ 0xFB000000
 *                            |   Cur. Page Table (Kern, RW)    | RW/-- PTSIZE
 *     VPT -----------------> +---------------------------------+ 0xFAC00000
 *                            |        Invalid Memory (*)       | --/--
 *     KERNTOP -------------> +---------------------------------+ 0xF8000000
 *                            |                                 |
 *                            |    Remapped Physical Memory     | RW/-- KMEMSIZE
 *                            |                                 |
 *     KERNBASE ------------> +---------------------------------+ 0xC0000000
 *                            |        Invalid Memory (*)       | --/--
 *     USERTOP -------------> +---------------------------------+ 0xB0000000
 *                            |           User stack            |
 *                            +---------------------------------+
 *                            |                                 |
 *                            :                                 :
 *                            |         ~~~~~~~~~~~~~~~~        |
 *                            :                                 :
 *                            |                                 |
 *                            ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *                            |       User Program & Heap       |
 *     UTEXT ---------------> +---------------------------------+ 0x00800000
 *                            |        Invalid Memory (*)       | --/--
 *                            |  - - - - - - - - - - - - - - -  |
 *                            |    User STAB Data (optional)    |
 *     USERBASE, USTAB------> +---------------------------------+ 0x00200000
 *                            |        Invalid Memory (*)       | --/--
 *     0 -------------------> +---------------------------------+ 0x00000000
 * (*) Note: The kernel ensures that "Invalid Memory" is *never* mapped.
 *     "Empty Memory" is normally unmapped, but user programs may map pages
 *     there if desired.
 *  
 * */
```

1. 用户栈的顶部地址 `USTACKTOP`，并将其设置为与用户空间的顶部地址 `USERTOP` 相同
   
   * 保护内核空间：将用户栈放在用户空间的顶部有助于防止栈溢出错误影响内核空间。因为用户空间和内核空间通常是分开的，用户栈在顶部意味着它远离内核空间
   * 利用虚拟内存：用户栈的大小可以动态变化。将用户栈放在地址空间的顶部可以使栈有更多的空间来动态增长（向下增长），而不会与其他如堆（heap）等区域发生冲突。
   * 简化内存管理：通过将用户栈放在固定的位置（用户空间的顶部），操作系统可以更容易地管理和分配栈空间，因为它总是知道栈的起始地址

2. 内核如何处理“无效内存”（Invalid Memory）和“空内存”（Empty Memory）区域
   
   * “无效内存”区域是不会被映射到物理内存的。
     这意味着，如果试图访问这些区域的地址，将会触发一个异常或错误，因为这些地址没有对应的物理内存。保持这些区域为无效内存有助于捕获和防止某些类型的程序错误，如空指针解引用。
   
   * “空内存”区域通常也是未映射的
     意味着在默认情况下，这些地址没有映射到物理内存。但与“无效内存”不同，用户程序可以根据需要将页面映射到“空内存”区域。这提供了一些灵活性，允许用户程序使用更多的虚拟地址空间

在RISC-V架构下使用`sv39`模式，其中39指的是虚拟地址空间的大小，即 39 位。这个转换通过一个三级页表进行。其中`sv39`的标准页大小是4KB，这意味着**每个页包含 4096 个字节**。由于虚拟地址有 39 位，所以 sv39 能够支持的**虚拟地址空间大小是 512GB**。但物理地址可以更长，例如 56 位。这允许系统访问更大的物理内存空间。

这种转换过程使用虚拟地址的不同部分来索引页表中的不同级别，并最终解析出物理地址。下面是这一过程的基本步骤：

### 虚拟地址划分

```c
// Sv39 linear address structure
// +-------9--------+-------9--------+--------9---------+----------12----------+
// |      VPN2      |      VPN1      |       VPN0       |  Offset within Page  |
// +----------------+----------------+------------------+----------------------+

// Sv39 in RISC-V64 uses 39-bit virtual address to access 56-bit physical address!
// Sv39 page table entry:
// +-------10--------+--------26-------+--------9----------+--------9--------+---2----+-------8-------+
// |    Reserved     |      PPN[2]     |      PPN[1]       |      PPN[0]     |Reserved|D|A|G|U|X|W|R|V|
// +-----------------+-----------------+-------------------+-----------------+--------+---------------+
```

在`sv39`模式下，一个39位的虚拟地址通常被划分为多个部分：27位的页号和12位的页内偏移，用于在三级页表中进行查找：

* **VPN[2]:** 虚拟地址的[38:30]位，用于在一级页表中进行查找。
* **VPN[1]:** 虚拟地址的[29:21]位，用于在二级页表中进行查找。
* **VPN[0]:** 虚拟地址的[20:12]位，用于在三级页表中进行查找。
* **Offset:** 虚拟地址的[11:0]位，用于在找到的物理页中找到确切的字节。

整个Sv39的虚拟内存空间里，有512（2的9次方）个大大页，每个大大页里有512个大页，每个大页里有512个页，每个页里有4096个字节，整个虚拟内存空间里就有512∗512∗512∗4096个字节，是512GiB的地址空间。

### 分级页表

如果页表项非法（没有对应的物理页）则只需要用一个非法的页表项来覆盖这个大页而不需要分别建立一大堆页表项

### 页表查找过程

1. **一级页表查找：**
   * 使用`satp`寄存器（存储一级页表基地址）和VPN[2]来找到一级页表项（PTE）。
   * 检查PTE的有效位和其他权限位是否满足要求。
   * 如果PTE无效或不允许所需的访问类型，则触发一个异常。
   * 否则，PTE中的物理页号（PPN）字段指向二级页表的基地址。
2. **二级页表查找：**
   * 使用一级页表查找到的PPN和VPN[1]找到二级页表项。
   * 再次检查PTE的有效位和权限位。
   * 如果PTE无效或不允许所需的访问类型，则触发一个异常。
   * 否则，PTE中的PPN字段指向三级页表的基地址。
3. **三级页表查找：**
   * 使用二级页表查找到的PPN和VPN[0]找到三级页表项。
   * 再次检查PTE的有效位和权限位。
   * 如果PTE无效或不允许所需的访问类型，则触发一个异常。
   * 否则，PTE中的PPN字段指向目标物理页的基地址。
4. **物理地址计算：**
   * 使用三级页表查找到的PPN和原始虚拟地址的Offset部分拼接形成最终的物理地址。

这个过程中，虚拟地址的各个部分用于在页表的不同级别中进行查找，并最终找到物理地址。这个过程通常在硬件层面自动进行，对上层的软件来说是透明的。在实际实现中，硬件和操作系统可能还会使用TLB（Translation Lookaside Buffer）等缓存机制来加速虚拟地址到物理地址的转换过程。

在页表转换中，**虚拟页面号（VPN，Virtual Page Number）用于索引页表（页表是个数组，虚拟页面号索引页表数组的项，每个页表项64位8字节）**，并从中得到相应的页表条目（Page Table Entry，PTE）。每一个PTE包含一个物理页面号（PPN，Physical Page Number）以及一些控制位，如有效位、可读位、可写位等。在 `sv39` 模式下，每个PTE是64位，其中包含一个物理页号和一些标志位。

在多级页表中，最高层的页表基址通常存储在一个特定的寄存器中。在 RISC-V 架构中，这个寄存器通常被称为 `satp`（在某些文档中也可能被称为 `ptbr`，页表基址寄存器）。
