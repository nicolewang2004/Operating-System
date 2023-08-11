
user/_sleep：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
  if (argc != 2) {
   8:	4789                	li	a5,2
   a:	02f50063          	beq	a0,a5,2a <main+0x2a>
    fprintf(2, "usage: sleep [ticks num]\n");
   e:	00000597          	auipc	a1,0x0
  12:	7f258593          	addi	a1,a1,2034 # 800 <malloc+0xec>
  16:	4509                	li	a0,2
  18:	00000097          	auipc	ra,0x0
  1c:	60e080e7          	jalr	1550(ra) # 626 <fprintf>
    exit(1);
  20:	4505                	li	a0,1
  22:	00000097          	auipc	ra,0x0
  26:	2b2080e7          	jalr	690(ra) # 2d4 <exit>
  }
  // atoi sys call guarantees return an integer
  int ticks = atoi(argv[1]);
  2a:	6588                	ld	a0,8(a1)
  2c:	00000097          	auipc	ra,0x0
  30:	19c080e7          	jalr	412(ra) # 1c8 <atoi>
  int ret = sleep(ticks);
  34:	00000097          	auipc	ra,0x0
  38:	330080e7          	jalr	816(ra) # 364 <sleep>
  exit(ret);
  3c:	00000097          	auipc	ra,0x0
  40:	298080e7          	jalr	664(ra) # 2d4 <exit>

0000000000000044 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
  44:	1141                	addi	sp,sp,-16
  46:	e422                	sd	s0,8(sp)
  48:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  4a:	87aa                	mv	a5,a0
  4c:	0585                	addi	a1,a1,1
  4e:	0785                	addi	a5,a5,1
  50:	fff5c703          	lbu	a4,-1(a1)
  54:	fee78fa3          	sb	a4,-1(a5)
  58:	fb75                	bnez	a4,4c <strcpy+0x8>
    ;
  return os;
}
  5a:	6422                	ld	s0,8(sp)
  5c:	0141                	addi	sp,sp,16
  5e:	8082                	ret

0000000000000060 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  60:	1141                	addi	sp,sp,-16
  62:	e422                	sd	s0,8(sp)
  64:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  66:	00054783          	lbu	a5,0(a0)
  6a:	cf91                	beqz	a5,86 <strcmp+0x26>
  6c:	0005c703          	lbu	a4,0(a1)
  70:	00f71b63          	bne	a4,a5,86 <strcmp+0x26>
    p++, q++;
  74:	0505                	addi	a0,a0,1
  76:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  78:	00054783          	lbu	a5,0(a0)
  7c:	c789                	beqz	a5,86 <strcmp+0x26>
  7e:	0005c703          	lbu	a4,0(a1)
  82:	fef709e3          	beq	a4,a5,74 <strcmp+0x14>
  return (uchar)*p - (uchar)*q;
  86:	0005c503          	lbu	a0,0(a1)
}
  8a:	40a7853b          	subw	a0,a5,a0
  8e:	6422                	ld	s0,8(sp)
  90:	0141                	addi	sp,sp,16
  92:	8082                	ret

0000000000000094 <strlen>:

uint
strlen(const char *s)
{
  94:	1141                	addi	sp,sp,-16
  96:	e422                	sd	s0,8(sp)
  98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  9a:	00054783          	lbu	a5,0(a0)
  9e:	cf91                	beqz	a5,ba <strlen+0x26>
  a0:	0505                	addi	a0,a0,1
  a2:	87aa                	mv	a5,a0
  a4:	4685                	li	a3,1
  a6:	9e89                	subw	a3,a3,a0
  a8:	00f6853b          	addw	a0,a3,a5
  ac:	0785                	addi	a5,a5,1
  ae:	fff7c703          	lbu	a4,-1(a5)
  b2:	fb7d                	bnez	a4,a8 <strlen+0x14>
    ;
  return n;
}
  b4:	6422                	ld	s0,8(sp)
  b6:	0141                	addi	sp,sp,16
  b8:	8082                	ret
  for(n = 0; s[n]; n++)
  ba:	4501                	li	a0,0
  bc:	bfe5                	j	b4 <strlen+0x20>

00000000000000be <memset>:

void*
memset(void *dst, int c, uint n)
{
  be:	1141                	addi	sp,sp,-16
  c0:	e422                	sd	s0,8(sp)
  c2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  c4:	ce09                	beqz	a2,de <memset+0x20>
  c6:	87aa                	mv	a5,a0
  c8:	fff6071b          	addiw	a4,a2,-1
  cc:	1702                	slli	a4,a4,0x20
  ce:	9301                	srli	a4,a4,0x20
  d0:	0705                	addi	a4,a4,1
  d2:	972a                	add	a4,a4,a0
    cdst[i] = c;
  d4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  d8:	0785                	addi	a5,a5,1
  da:	fee79de3          	bne	a5,a4,d4 <memset+0x16>
  }
  return dst;
}
  de:	6422                	ld	s0,8(sp)
  e0:	0141                	addi	sp,sp,16
  e2:	8082                	ret

00000000000000e4 <strchr>:

char*
strchr(const char *s, char c)
{
  e4:	1141                	addi	sp,sp,-16
  e6:	e422                	sd	s0,8(sp)
  e8:	0800                	addi	s0,sp,16
  for(; *s; s++)
  ea:	00054783          	lbu	a5,0(a0)
  ee:	cf91                	beqz	a5,10a <strchr+0x26>
    if(*s == c)
  f0:	00f58a63          	beq	a1,a5,104 <strchr+0x20>
  for(; *s; s++)
  f4:	0505                	addi	a0,a0,1
  f6:	00054783          	lbu	a5,0(a0)
  fa:	c781                	beqz	a5,102 <strchr+0x1e>
    if(*s == c)
  fc:	feb79ce3          	bne	a5,a1,f4 <strchr+0x10>
 100:	a011                	j	104 <strchr+0x20>
      return (char*)s;
  return 0;
 102:	4501                	li	a0,0
}
 104:	6422                	ld	s0,8(sp)
 106:	0141                	addi	sp,sp,16
 108:	8082                	ret
  return 0;
 10a:	4501                	li	a0,0
 10c:	bfe5                	j	104 <strchr+0x20>

000000000000010e <gets>:

char*
gets(char *buf, int max)
{
 10e:	711d                	addi	sp,sp,-96
 110:	ec86                	sd	ra,88(sp)
 112:	e8a2                	sd	s0,80(sp)
 114:	e4a6                	sd	s1,72(sp)
 116:	e0ca                	sd	s2,64(sp)
 118:	fc4e                	sd	s3,56(sp)
 11a:	f852                	sd	s4,48(sp)
 11c:	f456                	sd	s5,40(sp)
 11e:	f05a                	sd	s6,32(sp)
 120:	ec5e                	sd	s7,24(sp)
 122:	1080                	addi	s0,sp,96
 124:	8baa                	mv	s7,a0
 126:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 128:	892a                	mv	s2,a0
 12a:	4981                	li	s3,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 12c:	4aa9                	li	s5,10
 12e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 130:	0019849b          	addiw	s1,s3,1
 134:	0344d863          	ble	s4,s1,164 <gets+0x56>
    cc = read(0, &c, 1);
 138:	4605                	li	a2,1
 13a:	faf40593          	addi	a1,s0,-81
 13e:	4501                	li	a0,0
 140:	00000097          	auipc	ra,0x0
 144:	1ac080e7          	jalr	428(ra) # 2ec <read>
    if(cc < 1)
 148:	00a05e63          	blez	a0,164 <gets+0x56>
    buf[i++] = c;
 14c:	faf44783          	lbu	a5,-81(s0)
 150:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 154:	01578763          	beq	a5,s5,162 <gets+0x54>
 158:	0905                	addi	s2,s2,1
  for(i=0; i+1 < max; ){
 15a:	89a6                	mv	s3,s1
    if(c == '\n' || c == '\r')
 15c:	fd679ae3          	bne	a5,s6,130 <gets+0x22>
 160:	a011                	j	164 <gets+0x56>
  for(i=0; i+1 < max; ){
 162:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 164:	99de                	add	s3,s3,s7
 166:	00098023          	sb	zero,0(s3)
  return buf;
}
 16a:	855e                	mv	a0,s7
 16c:	60e6                	ld	ra,88(sp)
 16e:	6446                	ld	s0,80(sp)
 170:	64a6                	ld	s1,72(sp)
 172:	6906                	ld	s2,64(sp)
 174:	79e2                	ld	s3,56(sp)
 176:	7a42                	ld	s4,48(sp)
 178:	7aa2                	ld	s5,40(sp)
 17a:	7b02                	ld	s6,32(sp)
 17c:	6be2                	ld	s7,24(sp)
 17e:	6125                	addi	sp,sp,96
 180:	8082                	ret

0000000000000182 <stat>:

int
stat(const char *n, struct stat *st)
{
 182:	1101                	addi	sp,sp,-32
 184:	ec06                	sd	ra,24(sp)
 186:	e822                	sd	s0,16(sp)
 188:	e426                	sd	s1,8(sp)
 18a:	e04a                	sd	s2,0(sp)
 18c:	1000                	addi	s0,sp,32
 18e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 190:	4581                	li	a1,0
 192:	00000097          	auipc	ra,0x0
 196:	182080e7          	jalr	386(ra) # 314 <open>
  if(fd < 0)
 19a:	02054563          	bltz	a0,1c4 <stat+0x42>
 19e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1a0:	85ca                	mv	a1,s2
 1a2:	00000097          	auipc	ra,0x0
 1a6:	18a080e7          	jalr	394(ra) # 32c <fstat>
 1aa:	892a                	mv	s2,a0
  close(fd);
 1ac:	8526                	mv	a0,s1
 1ae:	00000097          	auipc	ra,0x0
 1b2:	14e080e7          	jalr	334(ra) # 2fc <close>
  return r;
}
 1b6:	854a                	mv	a0,s2
 1b8:	60e2                	ld	ra,24(sp)
 1ba:	6442                	ld	s0,16(sp)
 1bc:	64a2                	ld	s1,8(sp)
 1be:	6902                	ld	s2,0(sp)
 1c0:	6105                	addi	sp,sp,32
 1c2:	8082                	ret
    return -1;
 1c4:	597d                	li	s2,-1
 1c6:	bfc5                	j	1b6 <stat+0x34>

00000000000001c8 <atoi>:

int
atoi(const char *s)
{
 1c8:	1141                	addi	sp,sp,-16
 1ca:	e422                	sd	s0,8(sp)
 1cc:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1ce:	00054683          	lbu	a3,0(a0)
 1d2:	fd06879b          	addiw	a5,a3,-48
 1d6:	0ff7f793          	andi	a5,a5,255
 1da:	4725                	li	a4,9
 1dc:	02f76963          	bltu	a4,a5,20e <atoi+0x46>
 1e0:	862a                	mv	a2,a0
  n = 0;
 1e2:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1e4:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1e6:	0605                	addi	a2,a2,1
 1e8:	0025179b          	slliw	a5,a0,0x2
 1ec:	9fa9                	addw	a5,a5,a0
 1ee:	0017979b          	slliw	a5,a5,0x1
 1f2:	9fb5                	addw	a5,a5,a3
 1f4:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1f8:	00064683          	lbu	a3,0(a2)
 1fc:	fd06871b          	addiw	a4,a3,-48
 200:	0ff77713          	andi	a4,a4,255
 204:	fee5f1e3          	bleu	a4,a1,1e6 <atoi+0x1e>
  return n;
}
 208:	6422                	ld	s0,8(sp)
 20a:	0141                	addi	sp,sp,16
 20c:	8082                	ret
  n = 0;
 20e:	4501                	li	a0,0
 210:	bfe5                	j	208 <atoi+0x40>

0000000000000212 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 212:	1141                	addi	sp,sp,-16
 214:	e422                	sd	s0,8(sp)
 216:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 218:	02b57663          	bleu	a1,a0,244 <memmove+0x32>
    while(n-- > 0)
 21c:	02c05163          	blez	a2,23e <memmove+0x2c>
 220:	fff6079b          	addiw	a5,a2,-1
 224:	1782                	slli	a5,a5,0x20
 226:	9381                	srli	a5,a5,0x20
 228:	0785                	addi	a5,a5,1
 22a:	97aa                	add	a5,a5,a0
  dst = vdst;
 22c:	872a                	mv	a4,a0
      *dst++ = *src++;
 22e:	0585                	addi	a1,a1,1
 230:	0705                	addi	a4,a4,1
 232:	fff5c683          	lbu	a3,-1(a1)
 236:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 23a:	fee79ae3          	bne	a5,a4,22e <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 23e:	6422                	ld	s0,8(sp)
 240:	0141                	addi	sp,sp,16
 242:	8082                	ret
    dst += n;
 244:	00c50733          	add	a4,a0,a2
    src += n;
 248:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 24a:	fec05ae3          	blez	a2,23e <memmove+0x2c>
 24e:	fff6079b          	addiw	a5,a2,-1
 252:	1782                	slli	a5,a5,0x20
 254:	9381                	srli	a5,a5,0x20
 256:	fff7c793          	not	a5,a5
 25a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 25c:	15fd                	addi	a1,a1,-1
 25e:	177d                	addi	a4,a4,-1
 260:	0005c683          	lbu	a3,0(a1)
 264:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 268:	fef71ae3          	bne	a4,a5,25c <memmove+0x4a>
 26c:	bfc9                	j	23e <memmove+0x2c>

000000000000026e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 26e:	1141                	addi	sp,sp,-16
 270:	e422                	sd	s0,8(sp)
 272:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 274:	ce15                	beqz	a2,2b0 <memcmp+0x42>
 276:	fff6069b          	addiw	a3,a2,-1
    if (*p1 != *p2) {
 27a:	00054783          	lbu	a5,0(a0)
 27e:	0005c703          	lbu	a4,0(a1)
 282:	02e79063          	bne	a5,a4,2a2 <memcmp+0x34>
 286:	1682                	slli	a3,a3,0x20
 288:	9281                	srli	a3,a3,0x20
 28a:	0685                	addi	a3,a3,1
 28c:	96aa                	add	a3,a3,a0
      return *p1 - *p2;
    }
    p1++;
 28e:	0505                	addi	a0,a0,1
    p2++;
 290:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 292:	00d50d63          	beq	a0,a3,2ac <memcmp+0x3e>
    if (*p1 != *p2) {
 296:	00054783          	lbu	a5,0(a0)
 29a:	0005c703          	lbu	a4,0(a1)
 29e:	fee788e3          	beq	a5,a4,28e <memcmp+0x20>
      return *p1 - *p2;
 2a2:	40e7853b          	subw	a0,a5,a4
  }
  return 0;
}
 2a6:	6422                	ld	s0,8(sp)
 2a8:	0141                	addi	sp,sp,16
 2aa:	8082                	ret
  return 0;
 2ac:	4501                	li	a0,0
 2ae:	bfe5                	j	2a6 <memcmp+0x38>
 2b0:	4501                	li	a0,0
 2b2:	bfd5                	j	2a6 <memcmp+0x38>

00000000000002b4 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2b4:	1141                	addi	sp,sp,-16
 2b6:	e406                	sd	ra,8(sp)
 2b8:	e022                	sd	s0,0(sp)
 2ba:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2bc:	00000097          	auipc	ra,0x0
 2c0:	f56080e7          	jalr	-170(ra) # 212 <memmove>
}
 2c4:	60a2                	ld	ra,8(sp)
 2c6:	6402                	ld	s0,0(sp)
 2c8:	0141                	addi	sp,sp,16
 2ca:	8082                	ret

00000000000002cc <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2cc:	4885                	li	a7,1
 ecall
 2ce:	00000073          	ecall
 ret
 2d2:	8082                	ret

00000000000002d4 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2d4:	4889                	li	a7,2
 ecall
 2d6:	00000073          	ecall
 ret
 2da:	8082                	ret

00000000000002dc <wait>:
.global wait
wait:
 li a7, SYS_wait
 2dc:	488d                	li	a7,3
 ecall
 2de:	00000073          	ecall
 ret
 2e2:	8082                	ret

00000000000002e4 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2e4:	4891                	li	a7,4
 ecall
 2e6:	00000073          	ecall
 ret
 2ea:	8082                	ret

00000000000002ec <read>:
.global read
read:
 li a7, SYS_read
 2ec:	4895                	li	a7,5
 ecall
 2ee:	00000073          	ecall
 ret
 2f2:	8082                	ret

00000000000002f4 <write>:
.global write
write:
 li a7, SYS_write
 2f4:	48c1                	li	a7,16
 ecall
 2f6:	00000073          	ecall
 ret
 2fa:	8082                	ret

00000000000002fc <close>:
.global close
close:
 li a7, SYS_close
 2fc:	48d5                	li	a7,21
 ecall
 2fe:	00000073          	ecall
 ret
 302:	8082                	ret

0000000000000304 <kill>:
.global kill
kill:
 li a7, SYS_kill
 304:	4899                	li	a7,6
 ecall
 306:	00000073          	ecall
 ret
 30a:	8082                	ret

000000000000030c <exec>:
.global exec
exec:
 li a7, SYS_exec
 30c:	489d                	li	a7,7
 ecall
 30e:	00000073          	ecall
 ret
 312:	8082                	ret

0000000000000314 <open>:
.global open
open:
 li a7, SYS_open
 314:	48bd                	li	a7,15
 ecall
 316:	00000073          	ecall
 ret
 31a:	8082                	ret

000000000000031c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 31c:	48c5                	li	a7,17
 ecall
 31e:	00000073          	ecall
 ret
 322:	8082                	ret

0000000000000324 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 324:	48c9                	li	a7,18
 ecall
 326:	00000073          	ecall
 ret
 32a:	8082                	ret

000000000000032c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 32c:	48a1                	li	a7,8
 ecall
 32e:	00000073          	ecall
 ret
 332:	8082                	ret

0000000000000334 <link>:
.global link
link:
 li a7, SYS_link
 334:	48cd                	li	a7,19
 ecall
 336:	00000073          	ecall
 ret
 33a:	8082                	ret

000000000000033c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 33c:	48d1                	li	a7,20
 ecall
 33e:	00000073          	ecall
 ret
 342:	8082                	ret

0000000000000344 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 344:	48a5                	li	a7,9
 ecall
 346:	00000073          	ecall
 ret
 34a:	8082                	ret

000000000000034c <dup>:
.global dup
dup:
 li a7, SYS_dup
 34c:	48a9                	li	a7,10
 ecall
 34e:	00000073          	ecall
 ret
 352:	8082                	ret

0000000000000354 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 354:	48ad                	li	a7,11
 ecall
 356:	00000073          	ecall
 ret
 35a:	8082                	ret

000000000000035c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 35c:	48b1                	li	a7,12
 ecall
 35e:	00000073          	ecall
 ret
 362:	8082                	ret

0000000000000364 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 364:	48b5                	li	a7,13
 ecall
 366:	00000073          	ecall
 ret
 36a:	8082                	ret

000000000000036c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 36c:	48b9                	li	a7,14
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <trace>:
.global trace
trace:
 li a7, SYS_trace
 374:	48d9                	li	a7,22
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 37c:	1101                	addi	sp,sp,-32
 37e:	ec06                	sd	ra,24(sp)
 380:	e822                	sd	s0,16(sp)
 382:	1000                	addi	s0,sp,32
 384:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 388:	4605                	li	a2,1
 38a:	fef40593          	addi	a1,s0,-17
 38e:	00000097          	auipc	ra,0x0
 392:	f66080e7          	jalr	-154(ra) # 2f4 <write>
}
 396:	60e2                	ld	ra,24(sp)
 398:	6442                	ld	s0,16(sp)
 39a:	6105                	addi	sp,sp,32
 39c:	8082                	ret

000000000000039e <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 39e:	7139                	addi	sp,sp,-64
 3a0:	fc06                	sd	ra,56(sp)
 3a2:	f822                	sd	s0,48(sp)
 3a4:	f426                	sd	s1,40(sp)
 3a6:	f04a                	sd	s2,32(sp)
 3a8:	ec4e                	sd	s3,24(sp)
 3aa:	0080                	addi	s0,sp,64
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3ac:	c299                	beqz	a3,3b2 <printint+0x14>
 3ae:	0005cd63          	bltz	a1,3c8 <printint+0x2a>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3b2:	2581                	sext.w	a1,a1
  neg = 0;
 3b4:	4301                	li	t1,0
 3b6:	fc040713          	addi	a4,s0,-64
  }

  i = 0;
 3ba:	4801                	li	a6,0
  do{
    buf[i++] = digits[x % base];
 3bc:	2601                	sext.w	a2,a2
 3be:	00000897          	auipc	a7,0x0
 3c2:	46288893          	addi	a7,a7,1122 # 820 <digits>
 3c6:	a801                	j	3d6 <printint+0x38>
    x = -xx;
 3c8:	40b005bb          	negw	a1,a1
 3cc:	2581                	sext.w	a1,a1
    neg = 1;
 3ce:	4305                	li	t1,1
    x = -xx;
 3d0:	b7dd                	j	3b6 <printint+0x18>
  }while((x /= base) != 0);
 3d2:	85be                	mv	a1,a5
    buf[i++] = digits[x % base];
 3d4:	8836                	mv	a6,a3
 3d6:	0018069b          	addiw	a3,a6,1
 3da:	02c5f7bb          	remuw	a5,a1,a2
 3de:	1782                	slli	a5,a5,0x20
 3e0:	9381                	srli	a5,a5,0x20
 3e2:	97c6                	add	a5,a5,a7
 3e4:	0007c783          	lbu	a5,0(a5)
 3e8:	00f70023          	sb	a5,0(a4)
  }while((x /= base) != 0);
 3ec:	0705                	addi	a4,a4,1
 3ee:	02c5d7bb          	divuw	a5,a1,a2
 3f2:	fec5f0e3          	bleu	a2,a1,3d2 <printint+0x34>
  if(neg)
 3f6:	00030b63          	beqz	t1,40c <printint+0x6e>
    buf[i++] = '-';
 3fa:	fd040793          	addi	a5,s0,-48
 3fe:	96be                	add	a3,a3,a5
 400:	02d00793          	li	a5,45
 404:	fef68823          	sb	a5,-16(a3)
 408:	0028069b          	addiw	a3,a6,2

  while(--i >= 0)
 40c:	02d05963          	blez	a3,43e <printint+0xa0>
 410:	89aa                	mv	s3,a0
 412:	fc040793          	addi	a5,s0,-64
 416:	00d784b3          	add	s1,a5,a3
 41a:	fff78913          	addi	s2,a5,-1
 41e:	9936                	add	s2,s2,a3
 420:	36fd                	addiw	a3,a3,-1
 422:	1682                	slli	a3,a3,0x20
 424:	9281                	srli	a3,a3,0x20
 426:	40d90933          	sub	s2,s2,a3
    putc(fd, buf[i]);
 42a:	fff4c583          	lbu	a1,-1(s1)
 42e:	854e                	mv	a0,s3
 430:	00000097          	auipc	ra,0x0
 434:	f4c080e7          	jalr	-180(ra) # 37c <putc>
  while(--i >= 0)
 438:	14fd                	addi	s1,s1,-1
 43a:	ff2498e3          	bne	s1,s2,42a <printint+0x8c>
}
 43e:	70e2                	ld	ra,56(sp)
 440:	7442                	ld	s0,48(sp)
 442:	74a2                	ld	s1,40(sp)
 444:	7902                	ld	s2,32(sp)
 446:	69e2                	ld	s3,24(sp)
 448:	6121                	addi	sp,sp,64
 44a:	8082                	ret

000000000000044c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 44c:	7119                	addi	sp,sp,-128
 44e:	fc86                	sd	ra,120(sp)
 450:	f8a2                	sd	s0,112(sp)
 452:	f4a6                	sd	s1,104(sp)
 454:	f0ca                	sd	s2,96(sp)
 456:	ecce                	sd	s3,88(sp)
 458:	e8d2                	sd	s4,80(sp)
 45a:	e4d6                	sd	s5,72(sp)
 45c:	e0da                	sd	s6,64(sp)
 45e:	fc5e                	sd	s7,56(sp)
 460:	f862                	sd	s8,48(sp)
 462:	f466                	sd	s9,40(sp)
 464:	f06a                	sd	s10,32(sp)
 466:	ec6e                	sd	s11,24(sp)
 468:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 46a:	0005c483          	lbu	s1,0(a1)
 46e:	18048d63          	beqz	s1,608 <vprintf+0x1bc>
 472:	8aaa                	mv	s5,a0
 474:	8b32                	mv	s6,a2
 476:	00158913          	addi	s2,a1,1
  state = 0;
 47a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 47c:	02500a13          	li	s4,37
      if(c == 'd'){
 480:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 484:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 488:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 48c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 490:	00000b97          	auipc	s7,0x0
 494:	390b8b93          	addi	s7,s7,912 # 820 <digits>
 498:	a839                	j	4b6 <vprintf+0x6a>
        putc(fd, c);
 49a:	85a6                	mv	a1,s1
 49c:	8556                	mv	a0,s5
 49e:	00000097          	auipc	ra,0x0
 4a2:	ede080e7          	jalr	-290(ra) # 37c <putc>
 4a6:	a019                	j	4ac <vprintf+0x60>
    } else if(state == '%'){
 4a8:	01498f63          	beq	s3,s4,4c6 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4ac:	0905                	addi	s2,s2,1
 4ae:	fff94483          	lbu	s1,-1(s2)
 4b2:	14048b63          	beqz	s1,608 <vprintf+0x1bc>
    c = fmt[i] & 0xff;
 4b6:	0004879b          	sext.w	a5,s1
    if(state == 0){
 4ba:	fe0997e3          	bnez	s3,4a8 <vprintf+0x5c>
      if(c == '%'){
 4be:	fd479ee3          	bne	a5,s4,49a <vprintf+0x4e>
        state = '%';
 4c2:	89be                	mv	s3,a5
 4c4:	b7e5                	j	4ac <vprintf+0x60>
      if(c == 'd'){
 4c6:	05878063          	beq	a5,s8,506 <vprintf+0xba>
      } else if(c == 'l') {
 4ca:	05978c63          	beq	a5,s9,522 <vprintf+0xd6>
      } else if(c == 'x') {
 4ce:	07a78863          	beq	a5,s10,53e <vprintf+0xf2>
      } else if(c == 'p') {
 4d2:	09b78463          	beq	a5,s11,55a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4d6:	07300713          	li	a4,115
 4da:	0ce78563          	beq	a5,a4,5a4 <vprintf+0x158>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4de:	06300713          	li	a4,99
 4e2:	0ee78c63          	beq	a5,a4,5da <vprintf+0x18e>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 4e6:	11478663          	beq	a5,s4,5f2 <vprintf+0x1a6>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4ea:	85d2                	mv	a1,s4
 4ec:	8556                	mv	a0,s5
 4ee:	00000097          	auipc	ra,0x0
 4f2:	e8e080e7          	jalr	-370(ra) # 37c <putc>
        putc(fd, c);
 4f6:	85a6                	mv	a1,s1
 4f8:	8556                	mv	a0,s5
 4fa:	00000097          	auipc	ra,0x0
 4fe:	e82080e7          	jalr	-382(ra) # 37c <putc>
      }
      state = 0;
 502:	4981                	li	s3,0
 504:	b765                	j	4ac <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 506:	008b0493          	addi	s1,s6,8
 50a:	4685                	li	a3,1
 50c:	4629                	li	a2,10
 50e:	000b2583          	lw	a1,0(s6)
 512:	8556                	mv	a0,s5
 514:	00000097          	auipc	ra,0x0
 518:	e8a080e7          	jalr	-374(ra) # 39e <printint>
 51c:	8b26                	mv	s6,s1
      state = 0;
 51e:	4981                	li	s3,0
 520:	b771                	j	4ac <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 522:	008b0493          	addi	s1,s6,8
 526:	4681                	li	a3,0
 528:	4629                	li	a2,10
 52a:	000b2583          	lw	a1,0(s6)
 52e:	8556                	mv	a0,s5
 530:	00000097          	auipc	ra,0x0
 534:	e6e080e7          	jalr	-402(ra) # 39e <printint>
 538:	8b26                	mv	s6,s1
      state = 0;
 53a:	4981                	li	s3,0
 53c:	bf85                	j	4ac <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 53e:	008b0493          	addi	s1,s6,8
 542:	4681                	li	a3,0
 544:	4641                	li	a2,16
 546:	000b2583          	lw	a1,0(s6)
 54a:	8556                	mv	a0,s5
 54c:	00000097          	auipc	ra,0x0
 550:	e52080e7          	jalr	-430(ra) # 39e <printint>
 554:	8b26                	mv	s6,s1
      state = 0;
 556:	4981                	li	s3,0
 558:	bf91                	j	4ac <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 55a:	008b0793          	addi	a5,s6,8
 55e:	f8f43423          	sd	a5,-120(s0)
 562:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 566:	03000593          	li	a1,48
 56a:	8556                	mv	a0,s5
 56c:	00000097          	auipc	ra,0x0
 570:	e10080e7          	jalr	-496(ra) # 37c <putc>
  putc(fd, 'x');
 574:	85ea                	mv	a1,s10
 576:	8556                	mv	a0,s5
 578:	00000097          	auipc	ra,0x0
 57c:	e04080e7          	jalr	-508(ra) # 37c <putc>
 580:	44c1                	li	s1,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 582:	03c9d793          	srli	a5,s3,0x3c
 586:	97de                	add	a5,a5,s7
 588:	0007c583          	lbu	a1,0(a5)
 58c:	8556                	mv	a0,s5
 58e:	00000097          	auipc	ra,0x0
 592:	dee080e7          	jalr	-530(ra) # 37c <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 596:	0992                	slli	s3,s3,0x4
 598:	34fd                	addiw	s1,s1,-1
 59a:	f4e5                	bnez	s1,582 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 59c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5a0:	4981                	li	s3,0
 5a2:	b729                	j	4ac <vprintf+0x60>
        s = va_arg(ap, char*);
 5a4:	008b0993          	addi	s3,s6,8
 5a8:	000b3483          	ld	s1,0(s6)
        if(s == 0)
 5ac:	c085                	beqz	s1,5cc <vprintf+0x180>
        while(*s != 0){
 5ae:	0004c583          	lbu	a1,0(s1)
 5b2:	c9a1                	beqz	a1,602 <vprintf+0x1b6>
          putc(fd, *s);
 5b4:	8556                	mv	a0,s5
 5b6:	00000097          	auipc	ra,0x0
 5ba:	dc6080e7          	jalr	-570(ra) # 37c <putc>
          s++;
 5be:	0485                	addi	s1,s1,1
        while(*s != 0){
 5c0:	0004c583          	lbu	a1,0(s1)
 5c4:	f9e5                	bnez	a1,5b4 <vprintf+0x168>
        s = va_arg(ap, char*);
 5c6:	8b4e                	mv	s6,s3
      state = 0;
 5c8:	4981                	li	s3,0
 5ca:	b5cd                	j	4ac <vprintf+0x60>
          s = "(null)";
 5cc:	00000497          	auipc	s1,0x0
 5d0:	26c48493          	addi	s1,s1,620 # 838 <digits+0x18>
        while(*s != 0){
 5d4:	02800593          	li	a1,40
 5d8:	bff1                	j	5b4 <vprintf+0x168>
        putc(fd, va_arg(ap, uint));
 5da:	008b0493          	addi	s1,s6,8
 5de:	000b4583          	lbu	a1,0(s6)
 5e2:	8556                	mv	a0,s5
 5e4:	00000097          	auipc	ra,0x0
 5e8:	d98080e7          	jalr	-616(ra) # 37c <putc>
 5ec:	8b26                	mv	s6,s1
      state = 0;
 5ee:	4981                	li	s3,0
 5f0:	bd75                	j	4ac <vprintf+0x60>
        putc(fd, c);
 5f2:	85d2                	mv	a1,s4
 5f4:	8556                	mv	a0,s5
 5f6:	00000097          	auipc	ra,0x0
 5fa:	d86080e7          	jalr	-634(ra) # 37c <putc>
      state = 0;
 5fe:	4981                	li	s3,0
 600:	b575                	j	4ac <vprintf+0x60>
        s = va_arg(ap, char*);
 602:	8b4e                	mv	s6,s3
      state = 0;
 604:	4981                	li	s3,0
 606:	b55d                	j	4ac <vprintf+0x60>
    }
  }
}
 608:	70e6                	ld	ra,120(sp)
 60a:	7446                	ld	s0,112(sp)
 60c:	74a6                	ld	s1,104(sp)
 60e:	7906                	ld	s2,96(sp)
 610:	69e6                	ld	s3,88(sp)
 612:	6a46                	ld	s4,80(sp)
 614:	6aa6                	ld	s5,72(sp)
 616:	6b06                	ld	s6,64(sp)
 618:	7be2                	ld	s7,56(sp)
 61a:	7c42                	ld	s8,48(sp)
 61c:	7ca2                	ld	s9,40(sp)
 61e:	7d02                	ld	s10,32(sp)
 620:	6de2                	ld	s11,24(sp)
 622:	6109                	addi	sp,sp,128
 624:	8082                	ret

0000000000000626 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 626:	715d                	addi	sp,sp,-80
 628:	ec06                	sd	ra,24(sp)
 62a:	e822                	sd	s0,16(sp)
 62c:	1000                	addi	s0,sp,32
 62e:	e010                	sd	a2,0(s0)
 630:	e414                	sd	a3,8(s0)
 632:	e818                	sd	a4,16(s0)
 634:	ec1c                	sd	a5,24(s0)
 636:	03043023          	sd	a6,32(s0)
 63a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 63e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 642:	8622                	mv	a2,s0
 644:	00000097          	auipc	ra,0x0
 648:	e08080e7          	jalr	-504(ra) # 44c <vprintf>
}
 64c:	60e2                	ld	ra,24(sp)
 64e:	6442                	ld	s0,16(sp)
 650:	6161                	addi	sp,sp,80
 652:	8082                	ret

0000000000000654 <printf>:

void
printf(const char *fmt, ...)
{
 654:	711d                	addi	sp,sp,-96
 656:	ec06                	sd	ra,24(sp)
 658:	e822                	sd	s0,16(sp)
 65a:	1000                	addi	s0,sp,32
 65c:	e40c                	sd	a1,8(s0)
 65e:	e810                	sd	a2,16(s0)
 660:	ec14                	sd	a3,24(s0)
 662:	f018                	sd	a4,32(s0)
 664:	f41c                	sd	a5,40(s0)
 666:	03043823          	sd	a6,48(s0)
 66a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 66e:	00840613          	addi	a2,s0,8
 672:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 676:	85aa                	mv	a1,a0
 678:	4505                	li	a0,1
 67a:	00000097          	auipc	ra,0x0
 67e:	dd2080e7          	jalr	-558(ra) # 44c <vprintf>
}
 682:	60e2                	ld	ra,24(sp)
 684:	6442                	ld	s0,16(sp)
 686:	6125                	addi	sp,sp,96
 688:	8082                	ret

000000000000068a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 68a:	1141                	addi	sp,sp,-16
 68c:	e422                	sd	s0,8(sp)
 68e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 690:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 694:	00000797          	auipc	a5,0x0
 698:	1ac78793          	addi	a5,a5,428 # 840 <__bss_start>
 69c:	639c                	ld	a5,0(a5)
 69e:	a805                	j	6ce <free+0x44>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6a0:	4618                	lw	a4,8(a2)
 6a2:	9db9                	addw	a1,a1,a4
 6a4:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6a8:	6398                	ld	a4,0(a5)
 6aa:	6318                	ld	a4,0(a4)
 6ac:	fee53823          	sd	a4,-16(a0)
 6b0:	a091                	j	6f4 <free+0x6a>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6b2:	ff852703          	lw	a4,-8(a0)
 6b6:	9e39                	addw	a2,a2,a4
 6b8:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6ba:	ff053703          	ld	a4,-16(a0)
 6be:	e398                	sd	a4,0(a5)
 6c0:	a099                	j	706 <free+0x7c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6c2:	6398                	ld	a4,0(a5)
 6c4:	00e7e463          	bltu	a5,a4,6cc <free+0x42>
 6c8:	00e6ea63          	bltu	a3,a4,6dc <free+0x52>
{
 6cc:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6ce:	fed7fae3          	bleu	a3,a5,6c2 <free+0x38>
 6d2:	6398                	ld	a4,0(a5)
 6d4:	00e6e463          	bltu	a3,a4,6dc <free+0x52>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6d8:	fee7eae3          	bltu	a5,a4,6cc <free+0x42>
  if(bp + bp->s.size == p->s.ptr){
 6dc:	ff852583          	lw	a1,-8(a0)
 6e0:	6390                	ld	a2,0(a5)
 6e2:	02059713          	slli	a4,a1,0x20
 6e6:	9301                	srli	a4,a4,0x20
 6e8:	0712                	slli	a4,a4,0x4
 6ea:	9736                	add	a4,a4,a3
 6ec:	fae60ae3          	beq	a2,a4,6a0 <free+0x16>
    bp->s.ptr = p->s.ptr;
 6f0:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6f4:	4790                	lw	a2,8(a5)
 6f6:	02061713          	slli	a4,a2,0x20
 6fa:	9301                	srli	a4,a4,0x20
 6fc:	0712                	slli	a4,a4,0x4
 6fe:	973e                	add	a4,a4,a5
 700:	fae689e3          	beq	a3,a4,6b2 <free+0x28>
  } else
    p->s.ptr = bp;
 704:	e394                	sd	a3,0(a5)
  freep = p;
 706:	00000717          	auipc	a4,0x0
 70a:	12f73d23          	sd	a5,314(a4) # 840 <__bss_start>
}
 70e:	6422                	ld	s0,8(sp)
 710:	0141                	addi	sp,sp,16
 712:	8082                	ret

0000000000000714 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 714:	7139                	addi	sp,sp,-64
 716:	fc06                	sd	ra,56(sp)
 718:	f822                	sd	s0,48(sp)
 71a:	f426                	sd	s1,40(sp)
 71c:	f04a                	sd	s2,32(sp)
 71e:	ec4e                	sd	s3,24(sp)
 720:	e852                	sd	s4,16(sp)
 722:	e456                	sd	s5,8(sp)
 724:	e05a                	sd	s6,0(sp)
 726:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 728:	02051993          	slli	s3,a0,0x20
 72c:	0209d993          	srli	s3,s3,0x20
 730:	09bd                	addi	s3,s3,15
 732:	0049d993          	srli	s3,s3,0x4
 736:	2985                	addiw	s3,s3,1
 738:	0009891b          	sext.w	s2,s3
  if((prevp = freep) == 0){
 73c:	00000797          	auipc	a5,0x0
 740:	10478793          	addi	a5,a5,260 # 840 <__bss_start>
 744:	6388                	ld	a0,0(a5)
 746:	c515                	beqz	a0,772 <malloc+0x5e>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 748:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 74a:	4798                	lw	a4,8(a5)
 74c:	03277f63          	bleu	s2,a4,78a <malloc+0x76>
 750:	8a4e                	mv	s4,s3
 752:	0009871b          	sext.w	a4,s3
 756:	6685                	lui	a3,0x1
 758:	00d77363          	bleu	a3,a4,75e <malloc+0x4a>
 75c:	6a05                	lui	s4,0x1
 75e:	000a0a9b          	sext.w	s5,s4
  p = sbrk(nu * sizeof(Header));
 762:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 766:	00000497          	auipc	s1,0x0
 76a:	0da48493          	addi	s1,s1,218 # 840 <__bss_start>
  if(p == (char*)-1)
 76e:	5b7d                	li	s6,-1
 770:	a885                	j	7e0 <malloc+0xcc>
    base.s.ptr = freep = prevp = &base;
 772:	00000797          	auipc	a5,0x0
 776:	0d678793          	addi	a5,a5,214 # 848 <base>
 77a:	00000717          	auipc	a4,0x0
 77e:	0cf73323          	sd	a5,198(a4) # 840 <__bss_start>
 782:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 784:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 788:	b7e1                	j	750 <malloc+0x3c>
      if(p->s.size == nunits)
 78a:	02e90b63          	beq	s2,a4,7c0 <malloc+0xac>
        p->s.size -= nunits;
 78e:	4137073b          	subw	a4,a4,s3
 792:	c798                	sw	a4,8(a5)
        p += p->s.size;
 794:	1702                	slli	a4,a4,0x20
 796:	9301                	srli	a4,a4,0x20
 798:	0712                	slli	a4,a4,0x4
 79a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 79c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7a0:	00000717          	auipc	a4,0x0
 7a4:	0aa73023          	sd	a0,160(a4) # 840 <__bss_start>
      return (void*)(p + 1);
 7a8:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7ac:	70e2                	ld	ra,56(sp)
 7ae:	7442                	ld	s0,48(sp)
 7b0:	74a2                	ld	s1,40(sp)
 7b2:	7902                	ld	s2,32(sp)
 7b4:	69e2                	ld	s3,24(sp)
 7b6:	6a42                	ld	s4,16(sp)
 7b8:	6aa2                	ld	s5,8(sp)
 7ba:	6b02                	ld	s6,0(sp)
 7bc:	6121                	addi	sp,sp,64
 7be:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7c0:	6398                	ld	a4,0(a5)
 7c2:	e118                	sd	a4,0(a0)
 7c4:	bff1                	j	7a0 <malloc+0x8c>
  hp->s.size = nu;
 7c6:	01552423          	sw	s5,8(a0)
  free((void*)(hp + 1));
 7ca:	0541                	addi	a0,a0,16
 7cc:	00000097          	auipc	ra,0x0
 7d0:	ebe080e7          	jalr	-322(ra) # 68a <free>
  return freep;
 7d4:	6088                	ld	a0,0(s1)
      if((p = morecore(nunits)) == 0)
 7d6:	d979                	beqz	a0,7ac <malloc+0x98>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7d8:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7da:	4798                	lw	a4,8(a5)
 7dc:	fb2777e3          	bleu	s2,a4,78a <malloc+0x76>
    if(p == freep)
 7e0:	6098                	ld	a4,0(s1)
 7e2:	853e                	mv	a0,a5
 7e4:	fef71ae3          	bne	a4,a5,7d8 <malloc+0xc4>
  p = sbrk(nu * sizeof(Header));
 7e8:	8552                	mv	a0,s4
 7ea:	00000097          	auipc	ra,0x0
 7ee:	b72080e7          	jalr	-1166(ra) # 35c <sbrk>
  if(p == (char*)-1)
 7f2:	fd651ae3          	bne	a0,s6,7c6 <malloc+0xb2>
        return 0;
 7f6:	4501                	li	a0,0
 7f8:	bf55                	j	7ac <malloc+0x98>
