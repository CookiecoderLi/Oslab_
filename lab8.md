#### 练习1: 完成读文件操作的实现（需要编码）

##### 1.文件处理流程

+ 进入通用文件访问接口层，这里提供了从用户空间到文件系统的标准访问接口。首先调用用户态的read函数，在该函数里面又调用了sys_read函数，而sys_read函数里面又调用了syscall，从而发生了系统调用进入到内核态。
  
  ```
    int read(int fd, void *base, size_t len) {
    return sys_read(fd, base, len);
    }
  ```
  
  ```
    int sys_read(int64_t fd, void *base, size_t len) {
    return syscall(SYS_read, fd, base, len);
    }
  ```

+ 在内核态里面，通过中断向量表的处理，终止会调用sys_read函数将用户态的参数传入到内核态，并且进一步调用sysfile_read函数。
  
  ```
    static int sys_read(uint64_t arg[]) {
    int fd = (int)arg[0];
    void *base = (void *)arg[1];
    size_t len = (size_t)arg[2];
    return sysfile_read(fd, base, len);
    }
  ```

+ 然后进入到了文件系统抽象层，在该函数里面首先会检查读取长度是否为0和测试文件是否可以读写，然后调用kmalloc函数分配4096字节的空间，最后循环读取文件，调用file_read函数将文件内容读取到buffer中，调用copy_to_user函数将读到的内容拷贝到用户的内存空间中，当读取完成后，返回到用户程序。
  
  ```
    int sysfile_read(int fd, void *base, size_t len) {
    struct mm_struct *mm = current->mm;
    if (len == 0) {
        return 0;
    }
    if (!file_testfd(fd, 1, 0)) {
        return -E_INVAL;
    }
    void *buffer;
    if ((buffer = kmalloc(IOBUF_SIZE)) == NULL) {
        return -E_NO_MEM;
    }
    int ret = 0;
    size_t copied = 0, alen;
    while (len != 0) {
        if ((alen = IOBUF_SIZE) > len) {
            alen = len;
        }
        ret = file_read(fd, buffer, alen, &alen);
        if (alen != 0) {
            lock_mm(mm);
            {
                if (copy_to_user(mm, base, buffer, alen)) {
                    assert(len >= alen);
                    base += alen, len -= alen, copied += alen;
                }
                else if (ret == 0) {
                    ret = -E_INVAL;
                }
            }
            unlock_mm(mm);
        }
        if (ret != 0 || alen == 0) {
            goto out;
        }
    }
    out:
    kfree(buffer);
    if (copied != 0) {
        return copied;
    }
    return ret;
    }
  ```

+ file_read函数用于读取文件，首先调用fd2file函数找到对应的file结构并且检查是否可读，然后调用filemap_acquire函数使打开该文件的计数加一，之后调用vop_read函数将文件内容读到iob中并调整文件指针偏移量的值，最后调用filemap_release函数使打开这个文件的计数减1。
  
  ```
  int file_read(int fd, void *base, size_t len, size_t *copied_store) {
    int ret;
    struct file *file;
    *copied_store = 0;
    if ((ret = fd2file(fd, &file)) != 0) { 
        return ret;
    }
    if (!file->readable) {
        return -E_INVAL;
    }
    fd_array_acquire(file); 
    struct iobuf __iob, *iob = iobuf_init(&__iob, base, len, file->pos);
    ret = vop_read(file->node, iob); 
    size_t copied = iobuf_used(iob);
    if (file->status == FD_OPENED) {
        file->pos += copied; 
    }
    *copied_store = copied;
    fd_array_release(file); 
    return ret;
  }
  ```

+ 然后进入到了SFS文件系统层，vop_read函数实际上是对sfs_read函数的封装
  
  ```
  static const struct inode_ops sfs_node_fileops = {
    .vop_magic                      = VOP_MAGIC,
    .vop_open                       = sfs_openfile,
    .vop_close                      = sfs_close,
    .vop_read                       = sfs_read, 
    .vop_write                      = sfs_write,
    .vop_fstat                      = sfs_fstat,
    .vop_fsync                      = sfs_fsync,
    .vop_reclaim                    = sfs_reclaim,
    .vop_gettype                    = sfs_gettype,
    .vop_tryseek                    = sfs_tryseek,
    .vop_truncate                   = sfs_truncfile,
  };
  ```

+ 在vop_read函数中调用了sys_io函数
  
  ```
  static int sfs_read(struct inode *node, struct iobuf *iob) {
    return sfs_io(node, iob, 0);
  }
  ```

+ 在sfs_io函数中，首先寻找到inode对应的sfs和sin，然后调用sfs_io_nolock函数进行读取文件操作，最后调用iobuf_skip函数调整iobuf的指针。
  
  ```
  static inline int sfs_io(struct inode *node, struct iobuf *iob, bool write) {
    struct sfs_fs *sfs = fsop_info(vop_fs(node), sfs);
    struct sfs_inode *sin = vop_info(node, sfs_inode);
    int ret;
    lock_sin(sin);
    {
        size_t alen = iob->io_resid;
        ret = sfs_io_nolock(sfs, sin, iob->io_base, iob->io_offset, &alen, write);
        if (alen != 0) {
            iobuf_skip(iob, alen);
        }
    }
    unlock_sin(sin);
    return ret;
  }
  ```
  
  ##### 2.具体实现
  
  在sfs_io_nolock函数中，首先计算了一些辅助变量，然后分为了三部分进行读取文件，第一部分判断偏移量（offset）与第一个块是否不对齐，如果不对齐，从偏移量位置开始读写一些内容到第一个块的末尾，第二部分主要针对对齐部分，第三部分主要判断结束位置与最后一个块是否对齐，如果不对齐从开头 Rd/Wr 一些内容到最后一个块的endpos % SFS_BLKSIZE，而对于每一部分，通过sfs_bmap_load_nolock函数获取文件索引编号，然后调用sfs_buf_op完成实际的文件读写操作。
  
  ```
  static int
  sfs_io_nolock(struct sfs_fs *sfs, struct sfs_inode *sin, void *buf, off_t offset, size_t *alenp, bool write) {
    struct sfs_disk_inode *din = sin->din;
    assert(din->type != SFS_TYPE_DIR);
    off_t endpos = offset + *alenp, blkoff;
    *alenp = 0;
    // calculate the Rd/Wr end position
    if (offset < 0 || offset >= SFS_MAX_FILE_SIZE || offset > endpos) {
        return -E_INVAL;
    }
    if (offset == endpos) {
        return 0;
    }
    if (endpos > SFS_MAX_FILE_SIZE) {
        endpos = SFS_MAX_FILE_SIZE;
    }
    if (!write) {
        if (offset >= din->size) {
            return 0;
        }
        if (endpos > din->size) {
            endpos = din->size;
        }
    }
    int (*sfs_buf_op)(struct sfs_fs *sfs, void *buf, size_t len, uint32_t blkno, off_t offset);
    int (*sfs_block_op)(struct sfs_fs *sfs, void *buf, uint32_t blkno, uint32_t nblks);
    if (write) {
        sfs_buf_op = sfs_wbuf, sfs_block_op = sfs_wblock;
    }
    else {
        sfs_buf_op = sfs_rbuf, sfs_block_op = sfs_rblock;
    }
    int ret = 0;
    size_t size, alen = 0;
    uint32_t ino;
    uint32_t blkno = offset / SFS_BLKSIZE;          // The NO. of Rd/Wr begin block
    uint32_t nblks = endpos / SFS_BLKSIZE - blkno;  // The size of Rd/Wr blocks
    if ((blkoff = offset % SFS_BLKSIZE) != 0) {
        size = (nblks != 0) ? (SFS_BLKSIZE - blkoff) : (endpos - offset);
        if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
            goto out;
        }
        if ((ret = sfs_buf_op(sfs, buf, size, ino, blkoff)) != 0) {
            goto out;
        }
  
        alen += size;
        buf += size;
  
        if (nblks == 0) {
            goto out;
        }
  
        blkno++;
        nblks--;
    }
    if (nblks > 0) {
        if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
            goto out;
        }
        if ((ret = sfs_block_op(sfs, buf, ino, nblks)) != 0) {
            goto out;
        }
  
        alen += nblks * SFS_BLKSIZE;
        buf += nblks * SFS_BLKSIZE;
        blkno += nblks;
        nblks -= nblks;
    }
  
    if ((size = endpos % SFS_BLKSIZE) != 0) {
        if ((ret = sfs_bmap_load_nolock(sfs, sin, blkno, &ino)) != 0) {
            goto out;
        }
        if ((ret = sfs_buf_op(sfs, buf, size, ino, 0)) != 0) {
            goto out;
        }
        alen += size;
    }
  out:
    *alenp = alen;
    if (offset + alen > sin->din->size) {
        sin->din->size = offset + alen;
        sin->dirty = 1;
    }
    return ret;
  }
  ```

## 练习2: 完成基于文件系统的执行程序机制的实现（需要编码）

在 Lab 5 的基础上进行修改，读 elf 文件变成从磁盘上读，而不是直接在内存中读。

1. `alloc_proc`函数

在 proc.c 中，首先我们需要先初始化 fs 中的进程控制结构，即在 alloc_proc 函数中我们需要做—下修改，加上—句 proc->ﬁlesp = NULL; 从而完成初始化。一个文件需要在 VFS 中变为一个进程才能被执行。

```

    // kern/process/proc.c中
    // 初始化filesp
    proc->filesp = NULL;
```

2. `load_icode`函数

首先，已经实现了文件系统，所以将原来lab5中的从内存中读取用户elf文件头以及程序文件头的方式改为通过文件系统来完成：

```

    // ... some codes here ...
    //(3) copy TEXT/DATA/BSS parts in binary to memory space of process
    struct elfhdr __elf, *elf = &__elf;
    if ((ret = load_icode_read(fd, elf, sizeof(struct elfhdr), 0)) != 0) {
        goto bad_elf_cleanup_pgdir;
    }
    if (elf->e_magic != ELF_MAGIC) {
        ret = -E_INVAL_ELF;
        goto bad_elf_cleanup_pgdir;
    }

    struct proghdr __ph, *ph = &__ph;
    uint32_t vm_flags, perm, phnum;
    for (phnum = 0; phnum < elf->e_phnum; phnum ++) {
        off_t phoff = elf->e_phoff + sizeof(struct proghdr) * phnum;
        if ((ret = load_icode_read(fd, ph, sizeof(struct proghdr), phoff)) != 0) {
    // ... some codes here ...
```

上面的代码使用`load_icode_read`来完成对elfhdr和proghdr的读取工作，而`load_icode_read`本质上是调用了文件系统的接口。后续的代码中还有对于这个函数的调用，这里不再赘述。

另外，由于还需要对用户栈中的参数argc和argv进行初始化，所以还需要计算传入参数的长度，将这两个参数压入用户栈。

```

    //(6) setup uargc and uargv in user stacks
    uint32_t argv_size=0, i;
    //计算参数总长度
    for (i = 0; i < argc; i ++) {
        argv_size += strnlen(kargv[i],EXEC_MAX_ARG_LEN + 1)+1;
    }
    // 为agrv指向的字符串分配空间，对齐
    uintptr_t stacktop = USTACKTOP - (argv_size/sizeof(long)+1)*sizeof(long);
    char** uargv=(char **)(stacktop  - argc * sizeof(char *));
    argv_size = 0;
    //存储参数
    for (i = 0; i < argc; i ++) {
        //uargv[i]保存了kargv[i]在栈中的起始位置
        uargv[i] = strcpy((char *)(stacktop + argv_size), kargv[i]);
        argv_size +=  strnlen(kargv[i],EXEC_MAX_ARG_LEN + 1)+1;
    }
    //由于栈地址从高向低增长，所以第一个参数的地址即为栈顶地址，同时压入一个int用于保存argc
    stacktop = (uintptr_t)uargv - sizeof(int);
    //在栈顶存储参数数量
    *(int *)stacktop = argc;
```

这个过程通过四步完成：

* 首先通过遍历计算出argv指向的字符串的总长度，然后通过将栈顶指针减去这个长度并对齐，**为这些字符串分配空间。**

* 其次将栈顶减去argc * sizeof(char*)**为agrv指针数组本身分配空间**

* 然后利用循环把uargv中的字符串参数拷贝到对应的位置

* 最后**为argc参数分配空间**，给argc赋值即可

通过这两步即可完成基于文件系统的执行，make qemu后可以执行相应的用户程序。


