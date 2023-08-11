
user/_primes：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <runprocess>:

/*
 * Run as a prime-number processor
 * the listenfd is from your left neighbor
 */
void runprocess(int listenfd) {
   0:	711d                	addi	sp,sp,-96
   2:	ec86                	sd	ra,88(sp)
   4:	e8a2                	sd	s0,80(sp)
   6:	e4a6                	sd	s1,72(sp)
   8:	e0ca                	sd	s2,64(sp)
   a:	fc4e                	sd	s3,56(sp)
   c:	f852                	sd	s4,48(sp)
   e:	f456                	sd	s5,40(sp)
  10:	1080                	addi	s0,sp,96
  12:	892a                	mv	s2,a0
  int my_num = 0;
  int forked = 0;
  int passed_num = 0;
  14:	fa042e23          	sw	zero,-68(s0)
  int forked = 0;
  18:	4981                	li	s3,0
  int my_num = 0;
  1a:	4481                	li	s1,0
    }

    // if my initial read
    if (my_num == 0) {
      my_num = passed_num;
      printf("prime %d\n", my_num);
  1c:	00001a97          	auipc	s5,0x1
  20:	8dca8a93          	addi	s5,s5,-1828 # 8f8 <malloc+0xe6>
          close(pipes[0]);
        }
      }

      // pass the number to right neighbor
      write(pipes[1], &passed_num, 4);
  24:	4a05                	li	s4,1
  26:	a09d                	j	8c <runprocess+0x8c>
      close(listenfd);
  28:	854a                	mv	a0,s2
  2a:	00000097          	auipc	ra,0x0
  2e:	3d0080e7          	jalr	976(ra) # 3fa <close>
      if (forked) {
  32:	00099763          	bnez	s3,40 <runprocess+0x40>
      exit(0);
  36:	4501                	li	a0,0
  38:	00000097          	auipc	ra,0x0
  3c:	39a080e7          	jalr	922(ra) # 3d2 <exit>
        close(pipes[1]);
  40:	fb442503          	lw	a0,-76(s0)
  44:	00000097          	auipc	ra,0x0
  48:	3b6080e7          	jalr	950(ra) # 3fa <close>
        wait(&child_pid);
  4c:	fac40513          	addi	a0,s0,-84
  50:	00000097          	auipc	ra,0x0
  54:	38a080e7          	jalr	906(ra) # 3da <wait>
  58:	bff9                	j	36 <runprocess+0x36>
      my_num = passed_num;
  5a:	fbc42483          	lw	s1,-68(s0)
      printf("prime %d\n", my_num);
  5e:	85a6                	mv	a1,s1
  60:	8556                	mv	a0,s5
  62:	00000097          	auipc	ra,0x0
  66:	6f0080e7          	jalr	1776(ra) # 752 <printf>
  6a:	a81d                	j	a0 <runprocess+0xa0>
          close(pipes[0]);
  6c:	fb042503          	lw	a0,-80(s0)
  70:	00000097          	auipc	ra,0x0
  74:	38a080e7          	jalr	906(ra) # 3fa <close>
      write(pipes[1], &passed_num, 4);
  78:	4611                	li	a2,4
  7a:	fbc40593          	addi	a1,s0,-68
  7e:	fb442503          	lw	a0,-76(s0)
  82:	00000097          	auipc	ra,0x0
  86:	370080e7          	jalr	880(ra) # 3f2 <write>
  8a:	89d2                	mv	s3,s4
    int read_bytes = read(listenfd, &passed_num, 4);
  8c:	4611                	li	a2,4
  8e:	fbc40593          	addi	a1,s0,-68
  92:	854a                	mv	a0,s2
  94:	00000097          	auipc	ra,0x0
  98:	356080e7          	jalr	854(ra) # 3ea <read>
    if (read_bytes == 0) {
  9c:	d551                	beqz	a0,28 <runprocess+0x28>
    if (my_num == 0) {
  9e:	dcd5                	beqz	s1,5a <runprocess+0x5a>
    if (passed_num % my_num != 0) {
  a0:	fbc42783          	lw	a5,-68(s0)
  a4:	0297e7bb          	remw	a5,a5,s1
  a8:	d3f5                	beqz	a5,8c <runprocess+0x8c>
      if (!forked) {
  aa:	fc0997e3          	bnez	s3,78 <runprocess+0x78>
        pipe(pipes);
  ae:	fb040513          	addi	a0,s0,-80
  b2:	00000097          	auipc	ra,0x0
  b6:	330080e7          	jalr	816(ra) # 3e2 <pipe>
        int ret = fork();
  ba:	00000097          	auipc	ra,0x0
  be:	310080e7          	jalr	784(ra) # 3ca <fork>
        if (ret == 0) {
  c2:	f54d                	bnez	a0,6c <runprocess+0x6c>
          close(pipes[1]);
  c4:	fb442503          	lw	a0,-76(s0)
  c8:	00000097          	auipc	ra,0x0
  cc:	332080e7          	jalr	818(ra) # 3fa <close>
          close(listenfd);
  d0:	854a                	mv	a0,s2
  d2:	00000097          	auipc	ra,0x0
  d6:	328080e7          	jalr	808(ra) # 3fa <close>
          runprocess(pipes[0]);
  da:	fb042503          	lw	a0,-80(s0)
  de:	00000097          	auipc	ra,0x0
  e2:	f22080e7          	jalr	-222(ra) # 0 <runprocess>

00000000000000e6 <main>:
    }
  }
}

int main(int argc, char *argv[]) {
  e6:	7179                	addi	sp,sp,-48
  e8:	f406                	sd	ra,40(sp)
  ea:	f022                	sd	s0,32(sp)
  ec:	ec26                	sd	s1,24(sp)
  ee:	1800                	addi	s0,sp,48
  int pipes[2];
  pipe(pipes);
  f0:	fd840513          	addi	a0,s0,-40
  f4:	00000097          	auipc	ra,0x0
  f8:	2ee080e7          	jalr	750(ra) # 3e2 <pipe>
  for (int i = 2; i <= 35; i++) {
  fc:	4789                	li	a5,2
  fe:	fcf42a23          	sw	a5,-44(s0)
 102:	02300493          	li	s1,35
    write(pipes[1], &i, 4);
 106:	4611                	li	a2,4
 108:	fd440593          	addi	a1,s0,-44
 10c:	fdc42503          	lw	a0,-36(s0)
 110:	00000097          	auipc	ra,0x0
 114:	2e2080e7          	jalr	738(ra) # 3f2 <write>
  for (int i = 2; i <= 35; i++) {
 118:	fd442783          	lw	a5,-44(s0)
 11c:	2785                	addiw	a5,a5,1
 11e:	0007871b          	sext.w	a4,a5
 122:	fcf42a23          	sw	a5,-44(s0)
 126:	fee4d0e3          	ble	a4,s1,106 <main+0x20>
  }
  close(pipes[1]);
 12a:	fdc42503          	lw	a0,-36(s0)
 12e:	00000097          	auipc	ra,0x0
 132:	2cc080e7          	jalr	716(ra) # 3fa <close>
  runprocess(pipes[0]);
 136:	fd842503          	lw	a0,-40(s0)
 13a:	00000097          	auipc	ra,0x0
 13e:	ec6080e7          	jalr	-314(ra) # 0 <runprocess>

0000000000000142 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 142:	1141                	addi	sp,sp,-16
 144:	e422                	sd	s0,8(sp)
 146:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 148:	87aa                	mv	a5,a0
 14a:	0585                	addi	a1,a1,1
 14c:	0785                	addi	a5,a5,1
 14e:	fff5c703          	lbu	a4,-1(a1)
 152:	fee78fa3          	sb	a4,-1(a5)
 156:	fb75                	bnez	a4,14a <strcpy+0x8>
    ;
  return os;
}
 158:	6422                	ld	s0,8(sp)
 15a:	0141                	addi	sp,sp,16
 15c:	8082                	ret

000000000000015e <strcmp>:

int
strcmp(const char *p, const char *q)
{
 15e:	1141                	addi	sp,sp,-16
 160:	e422                	sd	s0,8(sp)
 162:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 164:	00054783          	lbu	a5,0(a0)
 168:	cf91                	beqz	a5,184 <strcmp+0x26>
 16a:	0005c703          	lbu	a4,0(a1)
 16e:	00f71b63          	bne	a4,a5,184 <strcmp+0x26>
    p++, q++;
 172:	0505                	addi	a0,a0,1
 174:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 176:	00054783          	lbu	a5,0(a0)
 17a:	c789                	beqz	a5,184 <strcmp+0x26>
 17c:	0005c703          	lbu	a4,0(a1)
 180:	fef709e3          	beq	a4,a5,172 <strcmp+0x14>
  return (uchar)*p - (uchar)*q;
 184:	0005c503          	lbu	a0,0(a1)
}
 188:	40a7853b          	subw	a0,a5,a0
 18c:	6422                	ld	s0,8(sp)
 18e:	0141                	addi	sp,sp,16
 190:	8082                	ret

0000000000000192 <strlen>:

uint
strlen(const char *s)
{
 192:	1141                	addi	sp,sp,-16
 194:	e422                	sd	s0,8(sp)
 196:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 198:	00054783          	lbu	a5,0(a0)
 19c:	cf91                	beqz	a5,1b8 <strlen+0x26>
 19e:	0505                	addi	a0,a0,1
 1a0:	87aa                	mv	a5,a0
 1a2:	4685                	li	a3,1
 1a4:	9e89                	subw	a3,a3,a0
 1a6:	00f6853b          	addw	a0,a3,a5
 1aa:	0785                	addi	a5,a5,1
 1ac:	fff7c703          	lbu	a4,-1(a5)
 1b0:	fb7d                	bnez	a4,1a6 <strlen+0x14>
    ;
  return n;
}
 1b2:	6422                	ld	s0,8(sp)
 1b4:	0141                	addi	sp,sp,16
 1b6:	8082                	ret
  for(n = 0; s[n]; n++)
 1b8:	4501                	li	a0,0
 1ba:	bfe5                	j	1b2 <strlen+0x20>

00000000000001bc <memset>:

void*
memset(void *dst, int c, uint n)
{
 1bc:	1141                	addi	sp,sp,-16
 1be:	e422                	sd	s0,8(sp)
 1c0:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1c2:	ce09                	beqz	a2,1dc <memset+0x20>
 1c4:	87aa                	mv	a5,a0
 1c6:	fff6071b          	addiw	a4,a2,-1
 1ca:	1702                	slli	a4,a4,0x20
 1cc:	9301                	srli	a4,a4,0x20
 1ce:	0705                	addi	a4,a4,1
 1d0:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1d2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1d6:	0785                	addi	a5,a5,1
 1d8:	fee79de3          	bne	a5,a4,1d2 <memset+0x16>
  }
  return dst;
}
 1dc:	6422                	ld	s0,8(sp)
 1de:	0141                	addi	sp,sp,16
 1e0:	8082                	ret

00000000000001e2 <strchr>:

char*
strchr(const char *s, char c)
{
 1e2:	1141                	addi	sp,sp,-16
 1e4:	e422                	sd	s0,8(sp)
 1e6:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1e8:	00054783          	lbu	a5,0(a0)
 1ec:	cf91                	beqz	a5,208 <strchr+0x26>
    if(*s == c)
 1ee:	00f58a63          	beq	a1,a5,202 <strchr+0x20>
  for(; *s; s++)
 1f2:	0505                	addi	a0,a0,1
 1f4:	00054783          	lbu	a5,0(a0)
 1f8:	c781                	beqz	a5,200 <strchr+0x1e>
    if(*s == c)
 1fa:	feb79ce3          	bne	a5,a1,1f2 <strchr+0x10>
 1fe:	a011                	j	202 <strchr+0x20>
      return (char*)s;
  return 0;
 200:	4501                	li	a0,0
}
 202:	6422                	ld	s0,8(sp)
 204:	0141                	addi	sp,sp,16
 206:	8082                	ret
  return 0;
 208:	4501                	li	a0,0
 20a:	bfe5                	j	202 <strchr+0x20>

000000000000020c <gets>:

char*
gets(char *buf, int max)
{
 20c:	711d                	addi	sp,sp,-96
 20e:	ec86                	sd	ra,88(sp)
 210:	e8a2                	sd	s0,80(sp)
 212:	e4a6                	sd	s1,72(sp)
 214:	e0ca                	sd	s2,64(sp)
 216:	fc4e                	sd	s3,56(sp)
 218:	f852                	sd	s4,48(sp)
 21a:	f456                	sd	s5,40(sp)
 21c:	f05a                	sd	s6,32(sp)
 21e:	ec5e                	sd	s7,24(sp)
 220:	1080                	addi	s0,sp,96
 222:	8baa                	mv	s7,a0
 224:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 226:	892a                	mv	s2,a0
 228:	4981                	li	s3,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 22a:	4aa9                	li	s5,10
 22c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 22e:	0019849b          	addiw	s1,s3,1
 232:	0344d863          	ble	s4,s1,262 <gets+0x56>
    cc = read(0, &c, 1);
 236:	4605                	li	a2,1
 238:	faf40593          	addi	a1,s0,-81
 23c:	4501                	li	a0,0
 23e:	00000097          	auipc	ra,0x0
 242:	1ac080e7          	jalr	428(ra) # 3ea <read>
    if(cc < 1)
 246:	00a05e63          	blez	a0,262 <gets+0x56>
    buf[i++] = c;
 24a:	faf44783          	lbu	a5,-81(s0)
 24e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 252:	01578763          	beq	a5,s5,260 <gets+0x54>
 256:	0905                	addi	s2,s2,1
  for(i=0; i+1 < max; ){
 258:	89a6                	mv	s3,s1
    if(c == '\n' || c == '\r')
 25a:	fd679ae3          	bne	a5,s6,22e <gets+0x22>
 25e:	a011                	j	262 <gets+0x56>
  for(i=0; i+1 < max; ){
 260:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 262:	99de                	add	s3,s3,s7
 264:	00098023          	sb	zero,0(s3)
  return buf;
}
 268:	855e                	mv	a0,s7
 26a:	60e6                	ld	ra,88(sp)
 26c:	6446                	ld	s0,80(sp)
 26e:	64a6                	ld	s1,72(sp)
 270:	6906                	ld	s2,64(sp)
 272:	79e2                	ld	s3,56(sp)
 274:	7a42                	ld	s4,48(sp)
 276:	7aa2                	ld	s5,40(sp)
 278:	7b02                	ld	s6,32(sp)
 27a:	6be2                	ld	s7,24(sp)
 27c:	6125                	addi	sp,sp,96
 27e:	8082                	ret

0000000000000280 <stat>:

int
stat(const char *n, struct stat *st)
{
 280:	1101                	addi	sp,sp,-32
 282:	ec06                	sd	ra,24(sp)
 284:	e822                	sd	s0,16(sp)
 286:	e426                	sd	s1,8(sp)
 288:	e04a                	sd	s2,0(sp)
 28a:	1000                	addi	s0,sp,32
 28c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 28e:	4581                	li	a1,0
 290:	00000097          	auipc	ra,0x0
 294:	182080e7          	jalr	386(ra) # 412 <open>
  if(fd < 0)
 298:	02054563          	bltz	a0,2c2 <stat+0x42>
 29c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 29e:	85ca                	mv	a1,s2
 2a0:	00000097          	auipc	ra,0x0
 2a4:	18a080e7          	jalr	394(ra) # 42a <fstat>
 2a8:	892a                	mv	s2,a0
  close(fd);
 2aa:	8526                	mv	a0,s1
 2ac:	00000097          	auipc	ra,0x0
 2b0:	14e080e7          	jalr	334(ra) # 3fa <close>
  return r;
}
 2b4:	854a                	mv	a0,s2
 2b6:	60e2                	ld	ra,24(sp)
 2b8:	6442                	ld	s0,16(sp)
 2ba:	64a2                	ld	s1,8(sp)
 2bc:	6902                	ld	s2,0(sp)
 2be:	6105                	addi	sp,sp,32
 2c0:	8082                	ret
    return -1;
 2c2:	597d                	li	s2,-1
 2c4:	bfc5                	j	2b4 <stat+0x34>

00000000000002c6 <atoi>:

int
atoi(const char *s)
{
 2c6:	1141                	addi	sp,sp,-16
 2c8:	e422                	sd	s0,8(sp)
 2ca:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2cc:	00054683          	lbu	a3,0(a0)
 2d0:	fd06879b          	addiw	a5,a3,-48
 2d4:	0ff7f793          	andi	a5,a5,255
 2d8:	4725                	li	a4,9
 2da:	02f76963          	bltu	a4,a5,30c <atoi+0x46>
 2de:	862a                	mv	a2,a0
  n = 0;
 2e0:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2e2:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2e4:	0605                	addi	a2,a2,1
 2e6:	0025179b          	slliw	a5,a0,0x2
 2ea:	9fa9                	addw	a5,a5,a0
 2ec:	0017979b          	slliw	a5,a5,0x1
 2f0:	9fb5                	addw	a5,a5,a3
 2f2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2f6:	00064683          	lbu	a3,0(a2)
 2fa:	fd06871b          	addiw	a4,a3,-48
 2fe:	0ff77713          	andi	a4,a4,255
 302:	fee5f1e3          	bleu	a4,a1,2e4 <atoi+0x1e>
  return n;
}
 306:	6422                	ld	s0,8(sp)
 308:	0141                	addi	sp,sp,16
 30a:	8082                	ret
  n = 0;
 30c:	4501                	li	a0,0
 30e:	bfe5                	j	306 <atoi+0x40>

0000000000000310 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 310:	1141                	addi	sp,sp,-16
 312:	e422                	sd	s0,8(sp)
 314:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 316:	02b57663          	bleu	a1,a0,342 <memmove+0x32>
    while(n-- > 0)
 31a:	02c05163          	blez	a2,33c <memmove+0x2c>
 31e:	fff6079b          	addiw	a5,a2,-1
 322:	1782                	slli	a5,a5,0x20
 324:	9381                	srli	a5,a5,0x20
 326:	0785                	addi	a5,a5,1
 328:	97aa                	add	a5,a5,a0
  dst = vdst;
 32a:	872a                	mv	a4,a0
      *dst++ = *src++;
 32c:	0585                	addi	a1,a1,1
 32e:	0705                	addi	a4,a4,1
 330:	fff5c683          	lbu	a3,-1(a1)
 334:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 338:	fee79ae3          	bne	a5,a4,32c <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 33c:	6422                	ld	s0,8(sp)
 33e:	0141                	addi	sp,sp,16
 340:	8082                	ret
    dst += n;
 342:	00c50733          	add	a4,a0,a2
    src += n;
 346:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 348:	fec05ae3          	blez	a2,33c <memmove+0x2c>
 34c:	fff6079b          	addiw	a5,a2,-1
 350:	1782                	slli	a5,a5,0x20
 352:	9381                	srli	a5,a5,0x20
 354:	fff7c793          	not	a5,a5
 358:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 35a:	15fd                	addi	a1,a1,-1
 35c:	177d                	addi	a4,a4,-1
 35e:	0005c683          	lbu	a3,0(a1)
 362:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 366:	fef71ae3          	bne	a4,a5,35a <memmove+0x4a>
 36a:	bfc9                	j	33c <memmove+0x2c>

000000000000036c <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 36c:	1141                	addi	sp,sp,-16
 36e:	e422                	sd	s0,8(sp)
 370:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 372:	ce15                	beqz	a2,3ae <memcmp+0x42>
 374:	fff6069b          	addiw	a3,a2,-1
    if (*p1 != *p2) {
 378:	00054783          	lbu	a5,0(a0)
 37c:	0005c703          	lbu	a4,0(a1)
 380:	02e79063          	bne	a5,a4,3a0 <memcmp+0x34>
 384:	1682                	slli	a3,a3,0x20
 386:	9281                	srli	a3,a3,0x20
 388:	0685                	addi	a3,a3,1
 38a:	96aa                	add	a3,a3,a0
      return *p1 - *p2;
    }
    p1++;
 38c:	0505                	addi	a0,a0,1
    p2++;
 38e:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 390:	00d50d63          	beq	a0,a3,3aa <memcmp+0x3e>
    if (*p1 != *p2) {
 394:	00054783          	lbu	a5,0(a0)
 398:	0005c703          	lbu	a4,0(a1)
 39c:	fee788e3          	beq	a5,a4,38c <memcmp+0x20>
      return *p1 - *p2;
 3a0:	40e7853b          	subw	a0,a5,a4
  }
  return 0;
}
 3a4:	6422                	ld	s0,8(sp)
 3a6:	0141                	addi	sp,sp,16
 3a8:	8082                	ret
  return 0;
 3aa:	4501                	li	a0,0
 3ac:	bfe5                	j	3a4 <memcmp+0x38>
 3ae:	4501                	li	a0,0
 3b0:	bfd5                	j	3a4 <memcmp+0x38>

00000000000003b2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3b2:	1141                	addi	sp,sp,-16
 3b4:	e406                	sd	ra,8(sp)
 3b6:	e022                	sd	s0,0(sp)
 3b8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3ba:	00000097          	auipc	ra,0x0
 3be:	f56080e7          	jalr	-170(ra) # 310 <memmove>
}
 3c2:	60a2                	ld	ra,8(sp)
 3c4:	6402                	ld	s0,0(sp)
 3c6:	0141                	addi	sp,sp,16
 3c8:	8082                	ret

00000000000003ca <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3ca:	4885                	li	a7,1
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 3d2:	4889                	li	a7,2
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <wait>:
.global wait
wait:
 li a7, SYS_wait
 3da:	488d                	li	a7,3
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3e2:	4891                	li	a7,4
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <read>:
.global read
read:
 li a7, SYS_read
 3ea:	4895                	li	a7,5
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <write>:
.global write
write:
 li a7, SYS_write
 3f2:	48c1                	li	a7,16
 ecall
 3f4:	00000073          	ecall
 ret
 3f8:	8082                	ret

00000000000003fa <close>:
.global close
close:
 li a7, SYS_close
 3fa:	48d5                	li	a7,21
 ecall
 3fc:	00000073          	ecall
 ret
 400:	8082                	ret

0000000000000402 <kill>:
.global kill
kill:
 li a7, SYS_kill
 402:	4899                	li	a7,6
 ecall
 404:	00000073          	ecall
 ret
 408:	8082                	ret

000000000000040a <exec>:
.global exec
exec:
 li a7, SYS_exec
 40a:	489d                	li	a7,7
 ecall
 40c:	00000073          	ecall
 ret
 410:	8082                	ret

0000000000000412 <open>:
.global open
open:
 li a7, SYS_open
 412:	48bd                	li	a7,15
 ecall
 414:	00000073          	ecall
 ret
 418:	8082                	ret

000000000000041a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 41a:	48c5                	li	a7,17
 ecall
 41c:	00000073          	ecall
 ret
 420:	8082                	ret

0000000000000422 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 422:	48c9                	li	a7,18
 ecall
 424:	00000073          	ecall
 ret
 428:	8082                	ret

000000000000042a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 42a:	48a1                	li	a7,8
 ecall
 42c:	00000073          	ecall
 ret
 430:	8082                	ret

0000000000000432 <link>:
.global link
link:
 li a7, SYS_link
 432:	48cd                	li	a7,19
 ecall
 434:	00000073          	ecall
 ret
 438:	8082                	ret

000000000000043a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 43a:	48d1                	li	a7,20
 ecall
 43c:	00000073          	ecall
 ret
 440:	8082                	ret

0000000000000442 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 442:	48a5                	li	a7,9
 ecall
 444:	00000073          	ecall
 ret
 448:	8082                	ret

000000000000044a <dup>:
.global dup
dup:
 li a7, SYS_dup
 44a:	48a9                	li	a7,10
 ecall
 44c:	00000073          	ecall
 ret
 450:	8082                	ret

0000000000000452 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 452:	48ad                	li	a7,11
 ecall
 454:	00000073          	ecall
 ret
 458:	8082                	ret

000000000000045a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 45a:	48b1                	li	a7,12
 ecall
 45c:	00000073          	ecall
 ret
 460:	8082                	ret

0000000000000462 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 462:	48b5                	li	a7,13
 ecall
 464:	00000073          	ecall
 ret
 468:	8082                	ret

000000000000046a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 46a:	48b9                	li	a7,14
 ecall
 46c:	00000073          	ecall
 ret
 470:	8082                	ret

0000000000000472 <trace>:
.global trace
trace:
 li a7, SYS_trace
 472:	48d9                	li	a7,22
 ecall
 474:	00000073          	ecall
 ret
 478:	8082                	ret

000000000000047a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 47a:	1101                	addi	sp,sp,-32
 47c:	ec06                	sd	ra,24(sp)
 47e:	e822                	sd	s0,16(sp)
 480:	1000                	addi	s0,sp,32
 482:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 486:	4605                	li	a2,1
 488:	fef40593          	addi	a1,s0,-17
 48c:	00000097          	auipc	ra,0x0
 490:	f66080e7          	jalr	-154(ra) # 3f2 <write>
}
 494:	60e2                	ld	ra,24(sp)
 496:	6442                	ld	s0,16(sp)
 498:	6105                	addi	sp,sp,32
 49a:	8082                	ret

000000000000049c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 49c:	7139                	addi	sp,sp,-64
 49e:	fc06                	sd	ra,56(sp)
 4a0:	f822                	sd	s0,48(sp)
 4a2:	f426                	sd	s1,40(sp)
 4a4:	f04a                	sd	s2,32(sp)
 4a6:	ec4e                	sd	s3,24(sp)
 4a8:	0080                	addi	s0,sp,64
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4aa:	c299                	beqz	a3,4b0 <printint+0x14>
 4ac:	0005cd63          	bltz	a1,4c6 <printint+0x2a>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4b0:	2581                	sext.w	a1,a1
  neg = 0;
 4b2:	4301                	li	t1,0
 4b4:	fc040713          	addi	a4,s0,-64
  }

  i = 0;
 4b8:	4801                	li	a6,0
  do{
    buf[i++] = digits[x % base];
 4ba:	2601                	sext.w	a2,a2
 4bc:	00000897          	auipc	a7,0x0
 4c0:	44c88893          	addi	a7,a7,1100 # 908 <digits>
 4c4:	a801                	j	4d4 <printint+0x38>
    x = -xx;
 4c6:	40b005bb          	negw	a1,a1
 4ca:	2581                	sext.w	a1,a1
    neg = 1;
 4cc:	4305                	li	t1,1
    x = -xx;
 4ce:	b7dd                	j	4b4 <printint+0x18>
  }while((x /= base) != 0);
 4d0:	85be                	mv	a1,a5
    buf[i++] = digits[x % base];
 4d2:	8836                	mv	a6,a3
 4d4:	0018069b          	addiw	a3,a6,1
 4d8:	02c5f7bb          	remuw	a5,a1,a2
 4dc:	1782                	slli	a5,a5,0x20
 4de:	9381                	srli	a5,a5,0x20
 4e0:	97c6                	add	a5,a5,a7
 4e2:	0007c783          	lbu	a5,0(a5)
 4e6:	00f70023          	sb	a5,0(a4)
  }while((x /= base) != 0);
 4ea:	0705                	addi	a4,a4,1
 4ec:	02c5d7bb          	divuw	a5,a1,a2
 4f0:	fec5f0e3          	bleu	a2,a1,4d0 <printint+0x34>
  if(neg)
 4f4:	00030b63          	beqz	t1,50a <printint+0x6e>
    buf[i++] = '-';
 4f8:	fd040793          	addi	a5,s0,-48
 4fc:	96be                	add	a3,a3,a5
 4fe:	02d00793          	li	a5,45
 502:	fef68823          	sb	a5,-16(a3)
 506:	0028069b          	addiw	a3,a6,2

  while(--i >= 0)
 50a:	02d05963          	blez	a3,53c <printint+0xa0>
 50e:	89aa                	mv	s3,a0
 510:	fc040793          	addi	a5,s0,-64
 514:	00d784b3          	add	s1,a5,a3
 518:	fff78913          	addi	s2,a5,-1
 51c:	9936                	add	s2,s2,a3
 51e:	36fd                	addiw	a3,a3,-1
 520:	1682                	slli	a3,a3,0x20
 522:	9281                	srli	a3,a3,0x20
 524:	40d90933          	sub	s2,s2,a3
    putc(fd, buf[i]);
 528:	fff4c583          	lbu	a1,-1(s1)
 52c:	854e                	mv	a0,s3
 52e:	00000097          	auipc	ra,0x0
 532:	f4c080e7          	jalr	-180(ra) # 47a <putc>
  while(--i >= 0)
 536:	14fd                	addi	s1,s1,-1
 538:	ff2498e3          	bne	s1,s2,528 <printint+0x8c>
}
 53c:	70e2                	ld	ra,56(sp)
 53e:	7442                	ld	s0,48(sp)
 540:	74a2                	ld	s1,40(sp)
 542:	7902                	ld	s2,32(sp)
 544:	69e2                	ld	s3,24(sp)
 546:	6121                	addi	sp,sp,64
 548:	8082                	ret

000000000000054a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 54a:	7119                	addi	sp,sp,-128
 54c:	fc86                	sd	ra,120(sp)
 54e:	f8a2                	sd	s0,112(sp)
 550:	f4a6                	sd	s1,104(sp)
 552:	f0ca                	sd	s2,96(sp)
 554:	ecce                	sd	s3,88(sp)
 556:	e8d2                	sd	s4,80(sp)
 558:	e4d6                	sd	s5,72(sp)
 55a:	e0da                	sd	s6,64(sp)
 55c:	fc5e                	sd	s7,56(sp)
 55e:	f862                	sd	s8,48(sp)
 560:	f466                	sd	s9,40(sp)
 562:	f06a                	sd	s10,32(sp)
 564:	ec6e                	sd	s11,24(sp)
 566:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 568:	0005c483          	lbu	s1,0(a1)
 56c:	18048d63          	beqz	s1,706 <vprintf+0x1bc>
 570:	8aaa                	mv	s5,a0
 572:	8b32                	mv	s6,a2
 574:	00158913          	addi	s2,a1,1
  state = 0;
 578:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 57a:	02500a13          	li	s4,37
      if(c == 'd'){
 57e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 582:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 586:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 58a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 58e:	00000b97          	auipc	s7,0x0
 592:	37ab8b93          	addi	s7,s7,890 # 908 <digits>
 596:	a839                	j	5b4 <vprintf+0x6a>
        putc(fd, c);
 598:	85a6                	mv	a1,s1
 59a:	8556                	mv	a0,s5
 59c:	00000097          	auipc	ra,0x0
 5a0:	ede080e7          	jalr	-290(ra) # 47a <putc>
 5a4:	a019                	j	5aa <vprintf+0x60>
    } else if(state == '%'){
 5a6:	01498f63          	beq	s3,s4,5c4 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5aa:	0905                	addi	s2,s2,1
 5ac:	fff94483          	lbu	s1,-1(s2)
 5b0:	14048b63          	beqz	s1,706 <vprintf+0x1bc>
    c = fmt[i] & 0xff;
 5b4:	0004879b          	sext.w	a5,s1
    if(state == 0){
 5b8:	fe0997e3          	bnez	s3,5a6 <vprintf+0x5c>
      if(c == '%'){
 5bc:	fd479ee3          	bne	a5,s4,598 <vprintf+0x4e>
        state = '%';
 5c0:	89be                	mv	s3,a5
 5c2:	b7e5                	j	5aa <vprintf+0x60>
      if(c == 'd'){
 5c4:	05878063          	beq	a5,s8,604 <vprintf+0xba>
      } else if(c == 'l') {
 5c8:	05978c63          	beq	a5,s9,620 <vprintf+0xd6>
      } else if(c == 'x') {
 5cc:	07a78863          	beq	a5,s10,63c <vprintf+0xf2>
      } else if(c == 'p') {
 5d0:	09b78463          	beq	a5,s11,658 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5d4:	07300713          	li	a4,115
 5d8:	0ce78563          	beq	a5,a4,6a2 <vprintf+0x158>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5dc:	06300713          	li	a4,99
 5e0:	0ee78c63          	beq	a5,a4,6d8 <vprintf+0x18e>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5e4:	11478663          	beq	a5,s4,6f0 <vprintf+0x1a6>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5e8:	85d2                	mv	a1,s4
 5ea:	8556                	mv	a0,s5
 5ec:	00000097          	auipc	ra,0x0
 5f0:	e8e080e7          	jalr	-370(ra) # 47a <putc>
        putc(fd, c);
 5f4:	85a6                	mv	a1,s1
 5f6:	8556                	mv	a0,s5
 5f8:	00000097          	auipc	ra,0x0
 5fc:	e82080e7          	jalr	-382(ra) # 47a <putc>
      }
      state = 0;
 600:	4981                	li	s3,0
 602:	b765                	j	5aa <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 604:	008b0493          	addi	s1,s6,8
 608:	4685                	li	a3,1
 60a:	4629                	li	a2,10
 60c:	000b2583          	lw	a1,0(s6)
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	e8a080e7          	jalr	-374(ra) # 49c <printint>
 61a:	8b26                	mv	s6,s1
      state = 0;
 61c:	4981                	li	s3,0
 61e:	b771                	j	5aa <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 620:	008b0493          	addi	s1,s6,8
 624:	4681                	li	a3,0
 626:	4629                	li	a2,10
 628:	000b2583          	lw	a1,0(s6)
 62c:	8556                	mv	a0,s5
 62e:	00000097          	auipc	ra,0x0
 632:	e6e080e7          	jalr	-402(ra) # 49c <printint>
 636:	8b26                	mv	s6,s1
      state = 0;
 638:	4981                	li	s3,0
 63a:	bf85                	j	5aa <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 63c:	008b0493          	addi	s1,s6,8
 640:	4681                	li	a3,0
 642:	4641                	li	a2,16
 644:	000b2583          	lw	a1,0(s6)
 648:	8556                	mv	a0,s5
 64a:	00000097          	auipc	ra,0x0
 64e:	e52080e7          	jalr	-430(ra) # 49c <printint>
 652:	8b26                	mv	s6,s1
      state = 0;
 654:	4981                	li	s3,0
 656:	bf91                	j	5aa <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 658:	008b0793          	addi	a5,s6,8
 65c:	f8f43423          	sd	a5,-120(s0)
 660:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 664:	03000593          	li	a1,48
 668:	8556                	mv	a0,s5
 66a:	00000097          	auipc	ra,0x0
 66e:	e10080e7          	jalr	-496(ra) # 47a <putc>
  putc(fd, 'x');
 672:	85ea                	mv	a1,s10
 674:	8556                	mv	a0,s5
 676:	00000097          	auipc	ra,0x0
 67a:	e04080e7          	jalr	-508(ra) # 47a <putc>
 67e:	44c1                	li	s1,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 680:	03c9d793          	srli	a5,s3,0x3c
 684:	97de                	add	a5,a5,s7
 686:	0007c583          	lbu	a1,0(a5)
 68a:	8556                	mv	a0,s5
 68c:	00000097          	auipc	ra,0x0
 690:	dee080e7          	jalr	-530(ra) # 47a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 694:	0992                	slli	s3,s3,0x4
 696:	34fd                	addiw	s1,s1,-1
 698:	f4e5                	bnez	s1,680 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 69a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 69e:	4981                	li	s3,0
 6a0:	b729                	j	5aa <vprintf+0x60>
        s = va_arg(ap, char*);
 6a2:	008b0993          	addi	s3,s6,8
 6a6:	000b3483          	ld	s1,0(s6)
        if(s == 0)
 6aa:	c085                	beqz	s1,6ca <vprintf+0x180>
        while(*s != 0){
 6ac:	0004c583          	lbu	a1,0(s1)
 6b0:	c9a1                	beqz	a1,700 <vprintf+0x1b6>
          putc(fd, *s);
 6b2:	8556                	mv	a0,s5
 6b4:	00000097          	auipc	ra,0x0
 6b8:	dc6080e7          	jalr	-570(ra) # 47a <putc>
          s++;
 6bc:	0485                	addi	s1,s1,1
        while(*s != 0){
 6be:	0004c583          	lbu	a1,0(s1)
 6c2:	f9e5                	bnez	a1,6b2 <vprintf+0x168>
        s = va_arg(ap, char*);
 6c4:	8b4e                	mv	s6,s3
      state = 0;
 6c6:	4981                	li	s3,0
 6c8:	b5cd                	j	5aa <vprintf+0x60>
          s = "(null)";
 6ca:	00000497          	auipc	s1,0x0
 6ce:	25648493          	addi	s1,s1,598 # 920 <digits+0x18>
        while(*s != 0){
 6d2:	02800593          	li	a1,40
 6d6:	bff1                	j	6b2 <vprintf+0x168>
        putc(fd, va_arg(ap, uint));
 6d8:	008b0493          	addi	s1,s6,8
 6dc:	000b4583          	lbu	a1,0(s6)
 6e0:	8556                	mv	a0,s5
 6e2:	00000097          	auipc	ra,0x0
 6e6:	d98080e7          	jalr	-616(ra) # 47a <putc>
 6ea:	8b26                	mv	s6,s1
      state = 0;
 6ec:	4981                	li	s3,0
 6ee:	bd75                	j	5aa <vprintf+0x60>
        putc(fd, c);
 6f0:	85d2                	mv	a1,s4
 6f2:	8556                	mv	a0,s5
 6f4:	00000097          	auipc	ra,0x0
 6f8:	d86080e7          	jalr	-634(ra) # 47a <putc>
      state = 0;
 6fc:	4981                	li	s3,0
 6fe:	b575                	j	5aa <vprintf+0x60>
        s = va_arg(ap, char*);
 700:	8b4e                	mv	s6,s3
      state = 0;
 702:	4981                	li	s3,0
 704:	b55d                	j	5aa <vprintf+0x60>
    }
  }
}
 706:	70e6                	ld	ra,120(sp)
 708:	7446                	ld	s0,112(sp)
 70a:	74a6                	ld	s1,104(sp)
 70c:	7906                	ld	s2,96(sp)
 70e:	69e6                	ld	s3,88(sp)
 710:	6a46                	ld	s4,80(sp)
 712:	6aa6                	ld	s5,72(sp)
 714:	6b06                	ld	s6,64(sp)
 716:	7be2                	ld	s7,56(sp)
 718:	7c42                	ld	s8,48(sp)
 71a:	7ca2                	ld	s9,40(sp)
 71c:	7d02                	ld	s10,32(sp)
 71e:	6de2                	ld	s11,24(sp)
 720:	6109                	addi	sp,sp,128
 722:	8082                	ret

0000000000000724 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 724:	715d                	addi	sp,sp,-80
 726:	ec06                	sd	ra,24(sp)
 728:	e822                	sd	s0,16(sp)
 72a:	1000                	addi	s0,sp,32
 72c:	e010                	sd	a2,0(s0)
 72e:	e414                	sd	a3,8(s0)
 730:	e818                	sd	a4,16(s0)
 732:	ec1c                	sd	a5,24(s0)
 734:	03043023          	sd	a6,32(s0)
 738:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 73c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 740:	8622                	mv	a2,s0
 742:	00000097          	auipc	ra,0x0
 746:	e08080e7          	jalr	-504(ra) # 54a <vprintf>
}
 74a:	60e2                	ld	ra,24(sp)
 74c:	6442                	ld	s0,16(sp)
 74e:	6161                	addi	sp,sp,80
 750:	8082                	ret

0000000000000752 <printf>:

void
printf(const char *fmt, ...)
{
 752:	711d                	addi	sp,sp,-96
 754:	ec06                	sd	ra,24(sp)
 756:	e822                	sd	s0,16(sp)
 758:	1000                	addi	s0,sp,32
 75a:	e40c                	sd	a1,8(s0)
 75c:	e810                	sd	a2,16(s0)
 75e:	ec14                	sd	a3,24(s0)
 760:	f018                	sd	a4,32(s0)
 762:	f41c                	sd	a5,40(s0)
 764:	03043823          	sd	a6,48(s0)
 768:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 76c:	00840613          	addi	a2,s0,8
 770:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 774:	85aa                	mv	a1,a0
 776:	4505                	li	a0,1
 778:	00000097          	auipc	ra,0x0
 77c:	dd2080e7          	jalr	-558(ra) # 54a <vprintf>
}
 780:	60e2                	ld	ra,24(sp)
 782:	6442                	ld	s0,16(sp)
 784:	6125                	addi	sp,sp,96
 786:	8082                	ret

0000000000000788 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 788:	1141                	addi	sp,sp,-16
 78a:	e422                	sd	s0,8(sp)
 78c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 78e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 792:	00000797          	auipc	a5,0x0
 796:	19678793          	addi	a5,a5,406 # 928 <__bss_start>
 79a:	639c                	ld	a5,0(a5)
 79c:	a805                	j	7cc <free+0x44>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 79e:	4618                	lw	a4,8(a2)
 7a0:	9db9                	addw	a1,a1,a4
 7a2:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7a6:	6398                	ld	a4,0(a5)
 7a8:	6318                	ld	a4,0(a4)
 7aa:	fee53823          	sd	a4,-16(a0)
 7ae:	a091                	j	7f2 <free+0x6a>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7b0:	ff852703          	lw	a4,-8(a0)
 7b4:	9e39                	addw	a2,a2,a4
 7b6:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7b8:	ff053703          	ld	a4,-16(a0)
 7bc:	e398                	sd	a4,0(a5)
 7be:	a099                	j	804 <free+0x7c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7c0:	6398                	ld	a4,0(a5)
 7c2:	00e7e463          	bltu	a5,a4,7ca <free+0x42>
 7c6:	00e6ea63          	bltu	a3,a4,7da <free+0x52>
{
 7ca:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7cc:	fed7fae3          	bleu	a3,a5,7c0 <free+0x38>
 7d0:	6398                	ld	a4,0(a5)
 7d2:	00e6e463          	bltu	a3,a4,7da <free+0x52>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7d6:	fee7eae3          	bltu	a5,a4,7ca <free+0x42>
  if(bp + bp->s.size == p->s.ptr){
 7da:	ff852583          	lw	a1,-8(a0)
 7de:	6390                	ld	a2,0(a5)
 7e0:	02059713          	slli	a4,a1,0x20
 7e4:	9301                	srli	a4,a4,0x20
 7e6:	0712                	slli	a4,a4,0x4
 7e8:	9736                	add	a4,a4,a3
 7ea:	fae60ae3          	beq	a2,a4,79e <free+0x16>
    bp->s.ptr = p->s.ptr;
 7ee:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7f2:	4790                	lw	a2,8(a5)
 7f4:	02061713          	slli	a4,a2,0x20
 7f8:	9301                	srli	a4,a4,0x20
 7fa:	0712                	slli	a4,a4,0x4
 7fc:	973e                	add	a4,a4,a5
 7fe:	fae689e3          	beq	a3,a4,7b0 <free+0x28>
  } else
    p->s.ptr = bp;
 802:	e394                	sd	a3,0(a5)
  freep = p;
 804:	00000717          	auipc	a4,0x0
 808:	12f73223          	sd	a5,292(a4) # 928 <__bss_start>
}
 80c:	6422                	ld	s0,8(sp)
 80e:	0141                	addi	sp,sp,16
 810:	8082                	ret

0000000000000812 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 812:	7139                	addi	sp,sp,-64
 814:	fc06                	sd	ra,56(sp)
 816:	f822                	sd	s0,48(sp)
 818:	f426                	sd	s1,40(sp)
 81a:	f04a                	sd	s2,32(sp)
 81c:	ec4e                	sd	s3,24(sp)
 81e:	e852                	sd	s4,16(sp)
 820:	e456                	sd	s5,8(sp)
 822:	e05a                	sd	s6,0(sp)
 824:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 826:	02051993          	slli	s3,a0,0x20
 82a:	0209d993          	srli	s3,s3,0x20
 82e:	09bd                	addi	s3,s3,15
 830:	0049d993          	srli	s3,s3,0x4
 834:	2985                	addiw	s3,s3,1
 836:	0009891b          	sext.w	s2,s3
  if((prevp = freep) == 0){
 83a:	00000797          	auipc	a5,0x0
 83e:	0ee78793          	addi	a5,a5,238 # 928 <__bss_start>
 842:	6388                	ld	a0,0(a5)
 844:	c515                	beqz	a0,870 <malloc+0x5e>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 846:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 848:	4798                	lw	a4,8(a5)
 84a:	03277f63          	bleu	s2,a4,888 <malloc+0x76>
 84e:	8a4e                	mv	s4,s3
 850:	0009871b          	sext.w	a4,s3
 854:	6685                	lui	a3,0x1
 856:	00d77363          	bleu	a3,a4,85c <malloc+0x4a>
 85a:	6a05                	lui	s4,0x1
 85c:	000a0a9b          	sext.w	s5,s4
  p = sbrk(nu * sizeof(Header));
 860:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 864:	00000497          	auipc	s1,0x0
 868:	0c448493          	addi	s1,s1,196 # 928 <__bss_start>
  if(p == (char*)-1)
 86c:	5b7d                	li	s6,-1
 86e:	a885                	j	8de <malloc+0xcc>
    base.s.ptr = freep = prevp = &base;
 870:	00000797          	auipc	a5,0x0
 874:	0c078793          	addi	a5,a5,192 # 930 <base>
 878:	00000717          	auipc	a4,0x0
 87c:	0af73823          	sd	a5,176(a4) # 928 <__bss_start>
 880:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 882:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 886:	b7e1                	j	84e <malloc+0x3c>
      if(p->s.size == nunits)
 888:	02e90b63          	beq	s2,a4,8be <malloc+0xac>
        p->s.size -= nunits;
 88c:	4137073b          	subw	a4,a4,s3
 890:	c798                	sw	a4,8(a5)
        p += p->s.size;
 892:	1702                	slli	a4,a4,0x20
 894:	9301                	srli	a4,a4,0x20
 896:	0712                	slli	a4,a4,0x4
 898:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 89a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 89e:	00000717          	auipc	a4,0x0
 8a2:	08a73523          	sd	a0,138(a4) # 928 <__bss_start>
      return (void*)(p + 1);
 8a6:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8aa:	70e2                	ld	ra,56(sp)
 8ac:	7442                	ld	s0,48(sp)
 8ae:	74a2                	ld	s1,40(sp)
 8b0:	7902                	ld	s2,32(sp)
 8b2:	69e2                	ld	s3,24(sp)
 8b4:	6a42                	ld	s4,16(sp)
 8b6:	6aa2                	ld	s5,8(sp)
 8b8:	6b02                	ld	s6,0(sp)
 8ba:	6121                	addi	sp,sp,64
 8bc:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8be:	6398                	ld	a4,0(a5)
 8c0:	e118                	sd	a4,0(a0)
 8c2:	bff1                	j	89e <malloc+0x8c>
  hp->s.size = nu;
 8c4:	01552423          	sw	s5,8(a0)
  free((void*)(hp + 1));
 8c8:	0541                	addi	a0,a0,16
 8ca:	00000097          	auipc	ra,0x0
 8ce:	ebe080e7          	jalr	-322(ra) # 788 <free>
  return freep;
 8d2:	6088                	ld	a0,0(s1)
      if((p = morecore(nunits)) == 0)
 8d4:	d979                	beqz	a0,8aa <malloc+0x98>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8d6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8d8:	4798                	lw	a4,8(a5)
 8da:	fb2777e3          	bleu	s2,a4,888 <malloc+0x76>
    if(p == freep)
 8de:	6098                	ld	a4,0(s1)
 8e0:	853e                	mv	a0,a5
 8e2:	fef71ae3          	bne	a4,a5,8d6 <malloc+0xc4>
  p = sbrk(nu * sizeof(Header));
 8e6:	8552                	mv	a0,s4
 8e8:	00000097          	auipc	ra,0x0
 8ec:	b72080e7          	jalr	-1166(ra) # 45a <sbrk>
  if(p == (char*)-1)
 8f0:	fd651ae3          	bne	a0,s6,8c4 <malloc+0xb2>
        return 0;
 8f4:	4501                	li	a0,0
 8f6:	bf55                	j	8aa <malloc+0x98>
