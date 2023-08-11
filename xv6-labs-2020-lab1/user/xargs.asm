
user/_xargs：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

#define buf_size 512

int main(int argc, char *argv[]) {
   0:	a8010113          	addi	sp,sp,-1408
   4:	56113c23          	sd	ra,1400(sp)
   8:	56813823          	sd	s0,1392(sp)
   c:	56913423          	sd	s1,1384(sp)
  10:	57213023          	sd	s2,1376(sp)
  14:	55313c23          	sd	s3,1368(sp)
  18:	55413823          	sd	s4,1360(sp)
  1c:	55513423          	sd	s5,1352(sp)
  20:	55613023          	sd	s6,1344(sp)
  24:	53713c23          	sd	s7,1336(sp)
  28:	53813823          	sd	s8,1328(sp)
  2c:	53913423          	sd	s9,1320(sp)
  30:	53a13023          	sd	s10,1312(sp)
  34:	58010413          	addi	s0,sp,1408
  38:	8b2a                	mv	s6,a0
  3a:	8cae                	mv	s9,a1
  char buf[buf_size + 1] = {0};
  3c:	20100613          	li	a2,513
  40:	4581                	li	a1,0
  42:	d9840513          	addi	a0,s0,-616
  46:	00000097          	auipc	ra,0x0
  4a:	20c080e7          	jalr	524(ra) # 252 <memset>
  uint occupy = 0;
  char *xargv[MAXARG] = {0};
  4e:	10000613          	li	a2,256
  52:	4581                	li	a1,0
  54:	c9840513          	addi	a0,s0,-872
  58:	00000097          	auipc	ra,0x0
  5c:	1fa080e7          	jalr	506(ra) # 252 <memset>
  int stdin_end = 0;

  for (int i = 1; i < argc; i++) {
  60:	4785                	li	a5,1
  62:	0367d463          	ble	s6,a5,8a <main+0x8a>
  66:	008c8693          	addi	a3,s9,8
  6a:	c9840793          	addi	a5,s0,-872
  6e:	ffeb071b          	addiw	a4,s6,-2
  72:	1702                	slli	a4,a4,0x20
  74:	9301                	srli	a4,a4,0x20
  76:	070e                	slli	a4,a4,0x3
  78:	ca040613          	addi	a2,s0,-864
  7c:	9732                	add	a4,a4,a2
    xargv[i - 1] = argv[i];
  7e:	6290                	ld	a2,0(a3)
  80:	e390                	sd	a2,0(a5)
  for (int i = 1; i < argc; i++) {
  82:	06a1                	addi	a3,a3,8
  84:	07a1                	addi	a5,a5,8
  86:	fee79ce3          	bne	a5,a4,7e <main+0x7e>
  int stdin_end = 0;
  8a:	4c01                	li	s8,0
  uint occupy = 0;
  8c:	4b81                	li	s7,0
    // process lines read
    char *line_end = strchr(buf, '\n');
    while (line_end) {
      char xbuf[buf_size + 1] = {0};
      memcpy(xbuf, buf, line_end - buf);
      xargv[argc - 1] = xbuf;
  8e:	3b7d                	addiw	s6,s6,-1
  90:	0b0e                	slli	s6,s6,0x3
  92:	fa040793          	addi	a5,s0,-96
  96:	9b3e                	add	s6,s6,a5
  while (!(stdin_end && occupy == 0)) {
  98:	020c0263          	beqz	s8,bc <main+0xbc>
  9c:	120b8963          	beqz	s7,1ce <main+0x1ce>
    char *line_end = strchr(buf, '\n');
  a0:	45a9                	li	a1,10
  a2:	d9840513          	addi	a0,s0,-616
  a6:	00000097          	auipc	ra,0x0
  aa:	1d2080e7          	jalr	466(ra) # 278 <strchr>
  ae:	8a2a                	mv	s4,a0
    while (line_end) {
  b0:	d565                	beqz	a0,98 <main+0x98>
      char xbuf[buf_size + 1] = {0};
  b2:	a9040913          	addi	s2,s0,-1392
      memcpy(xbuf, buf, line_end - buf);
  b6:	d9840993          	addi	s3,s0,-616
  ba:	a885                	j	12a <main+0x12a>
      int read_bytes = read(0, buf + occupy, remain_size);
  bc:	020b9593          	slli	a1,s7,0x20
  c0:	9181                	srli	a1,a1,0x20
  c2:	20000613          	li	a2,512
  c6:	4176063b          	subw	a2,a2,s7
  ca:	d9840793          	addi	a5,s0,-616
  ce:	95be                	add	a1,a1,a5
  d0:	4501                	li	a0,0
  d2:	00000097          	auipc	ra,0x0
  d6:	3ae080e7          	jalr	942(ra) # 480 <read>
  da:	84aa                	mv	s1,a0
      if (read_bytes < 0) {
  dc:	00054663          	bltz	a0,e8 <main+0xe8>
      if (read_bytes == 0) {
  e0:	cd11                	beqz	a0,fc <main+0xfc>
      occupy += read_bytes;
  e2:	01748bbb          	addw	s7,s1,s7
  e6:	bf6d                	j	a0 <main+0xa0>
        fprintf(2, "xargs: read returns -1 error\n");
  e8:	00001597          	auipc	a1,0x1
  ec:	8a858593          	addi	a1,a1,-1880 # 990 <malloc+0xe8>
  f0:	4509                	li	a0,2
  f2:	00000097          	auipc	ra,0x0
  f6:	6c8080e7          	jalr	1736(ra) # 7ba <fprintf>
      if (read_bytes == 0) {
  fa:	b7e5                	j	e2 <main+0xe2>
        close(0);
  fc:	4501                	li	a0,0
  fe:	00000097          	auipc	ra,0x0
 102:	392080e7          	jalr	914(ra) # 490 <close>
        stdin_end = 1;
 106:	4c05                	li	s8,1
 108:	bfe9                	j	e2 <main+0xe2>
      int ret = fork();
      if (ret == 0) {
        // i am child
        if (!stdin_end) {
          close(0);
 10a:	00000097          	auipc	ra,0x0
 10e:	386080e7          	jalr	902(ra) # 490 <close>
        }
        if (exec(argv[1], xargv) < 0) {
 112:	c9840593          	addi	a1,s0,-872
 116:	008cb503          	ld	a0,8(s9)
 11a:	00000097          	auipc	ra,0x0
 11e:	386080e7          	jalr	902(ra) # 4a0 <exec>
 122:	02054f63          	bltz	a0,160 <main+0x160>
    while (line_end) {
 126:	f60a09e3          	beqz	s4,98 <main+0x98>
      char xbuf[buf_size + 1] = {0};
 12a:	20100613          	li	a2,513
 12e:	4581                	li	a1,0
 130:	854a                	mv	a0,s2
 132:	00000097          	auipc	ra,0x0
 136:	120080e7          	jalr	288(ra) # 252 <memset>
      memcpy(xbuf, buf, line_end - buf);
 13a:	413a04bb          	subw	s1,s4,s3
 13e:	8626                	mv	a2,s1
 140:	85ce                	mv	a1,s3
 142:	854a                	mv	a0,s2
 144:	00000097          	auipc	ra,0x0
 148:	304080e7          	jalr	772(ra) # 448 <memcpy>
      xargv[argc - 1] = xbuf;
 14c:	cf2b3c23          	sd	s2,-776(s6)
      int ret = fork();
 150:	00000097          	auipc	ra,0x0
 154:	310080e7          	jalr	784(ra) # 460 <fork>
      if (ret == 0) {
 158:	e115                	bnez	a0,17c <main+0x17c>
        if (!stdin_end) {
 15a:	fa0c1ce3          	bnez	s8,112 <main+0x112>
 15e:	b775                	j	10a <main+0x10a>
          fprintf(2, "xargs: exec fails with -1\n");
 160:	00001597          	auipc	a1,0x1
 164:	85058593          	addi	a1,a1,-1968 # 9b0 <malloc+0x108>
 168:	4509                	li	a0,2
 16a:	00000097          	auipc	ra,0x0
 16e:	650080e7          	jalr	1616(ra) # 7ba <fprintf>
          exit(1);
 172:	4505                	li	a0,1
 174:	00000097          	auipc	ra,0x0
 178:	2f4080e7          	jalr	756(ra) # 468 <exit>
        }
      } else {
        // trim out line already processed
        memmove(buf, line_end + 1, occupy - (line_end - buf) - 1);
 17c:	fffb8d1b          	addiw	s10,s7,-1
 180:	409d0abb          	subw	s5,s10,s1
 184:	000a8b9b          	sext.w	s7,s5
 188:	865e                	mv	a2,s7
 18a:	001a0593          	addi	a1,s4,1
 18e:	854e                	mv	a0,s3
 190:	00000097          	auipc	ra,0x0
 194:	216080e7          	jalr	534(ra) # 3a6 <memmove>
        occupy -= line_end - buf + 1;
        memset(buf + occupy, 0, buf_size - occupy);
 198:	41a4863b          	subw	a2,s1,s10
 19c:	020a9513          	slli	a0,s5,0x20
 1a0:	9101                	srli	a0,a0,0x20
 1a2:	2006061b          	addiw	a2,a2,512
 1a6:	4581                	li	a1,0
 1a8:	954e                	add	a0,a0,s3
 1aa:	00000097          	auipc	ra,0x0
 1ae:	0a8080e7          	jalr	168(ra) # 252 <memset>
        // harvest zombie
        int pid;
        wait(&pid);
 1b2:	a8c40513          	addi	a0,s0,-1396
 1b6:	00000097          	auipc	ra,0x0
 1ba:	2ba080e7          	jalr	698(ra) # 470 <wait>

        line_end = strchr(buf, '\n');
 1be:	45a9                	li	a1,10
 1c0:	854e                	mv	a0,s3
 1c2:	00000097          	auipc	ra,0x0
 1c6:	0b6080e7          	jalr	182(ra) # 278 <strchr>
 1ca:	8a2a                	mv	s4,a0
 1cc:	bfa9                	j	126 <main+0x126>
      }
    }
  }
  exit(0);
 1ce:	4501                	li	a0,0
 1d0:	00000097          	auipc	ra,0x0
 1d4:	298080e7          	jalr	664(ra) # 468 <exit>

00000000000001d8 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1d8:	1141                	addi	sp,sp,-16
 1da:	e422                	sd	s0,8(sp)
 1dc:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1de:	87aa                	mv	a5,a0
 1e0:	0585                	addi	a1,a1,1
 1e2:	0785                	addi	a5,a5,1
 1e4:	fff5c703          	lbu	a4,-1(a1)
 1e8:	fee78fa3          	sb	a4,-1(a5)
 1ec:	fb75                	bnez	a4,1e0 <strcpy+0x8>
    ;
  return os;
}
 1ee:	6422                	ld	s0,8(sp)
 1f0:	0141                	addi	sp,sp,16
 1f2:	8082                	ret

00000000000001f4 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1f4:	1141                	addi	sp,sp,-16
 1f6:	e422                	sd	s0,8(sp)
 1f8:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1fa:	00054783          	lbu	a5,0(a0)
 1fe:	cf91                	beqz	a5,21a <strcmp+0x26>
 200:	0005c703          	lbu	a4,0(a1)
 204:	00f71b63          	bne	a4,a5,21a <strcmp+0x26>
    p++, q++;
 208:	0505                	addi	a0,a0,1
 20a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 20c:	00054783          	lbu	a5,0(a0)
 210:	c789                	beqz	a5,21a <strcmp+0x26>
 212:	0005c703          	lbu	a4,0(a1)
 216:	fef709e3          	beq	a4,a5,208 <strcmp+0x14>
  return (uchar)*p - (uchar)*q;
 21a:	0005c503          	lbu	a0,0(a1)
}
 21e:	40a7853b          	subw	a0,a5,a0
 222:	6422                	ld	s0,8(sp)
 224:	0141                	addi	sp,sp,16
 226:	8082                	ret

0000000000000228 <strlen>:

uint
strlen(const char *s)
{
 228:	1141                	addi	sp,sp,-16
 22a:	e422                	sd	s0,8(sp)
 22c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 22e:	00054783          	lbu	a5,0(a0)
 232:	cf91                	beqz	a5,24e <strlen+0x26>
 234:	0505                	addi	a0,a0,1
 236:	87aa                	mv	a5,a0
 238:	4685                	li	a3,1
 23a:	9e89                	subw	a3,a3,a0
 23c:	00f6853b          	addw	a0,a3,a5
 240:	0785                	addi	a5,a5,1
 242:	fff7c703          	lbu	a4,-1(a5)
 246:	fb7d                	bnez	a4,23c <strlen+0x14>
    ;
  return n;
}
 248:	6422                	ld	s0,8(sp)
 24a:	0141                	addi	sp,sp,16
 24c:	8082                	ret
  for(n = 0; s[n]; n++)
 24e:	4501                	li	a0,0
 250:	bfe5                	j	248 <strlen+0x20>

0000000000000252 <memset>:

void*
memset(void *dst, int c, uint n)
{
 252:	1141                	addi	sp,sp,-16
 254:	e422                	sd	s0,8(sp)
 256:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 258:	ce09                	beqz	a2,272 <memset+0x20>
 25a:	87aa                	mv	a5,a0
 25c:	fff6071b          	addiw	a4,a2,-1
 260:	1702                	slli	a4,a4,0x20
 262:	9301                	srli	a4,a4,0x20
 264:	0705                	addi	a4,a4,1
 266:	972a                	add	a4,a4,a0
    cdst[i] = c;
 268:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 26c:	0785                	addi	a5,a5,1
 26e:	fee79de3          	bne	a5,a4,268 <memset+0x16>
  }
  return dst;
}
 272:	6422                	ld	s0,8(sp)
 274:	0141                	addi	sp,sp,16
 276:	8082                	ret

0000000000000278 <strchr>:

char*
strchr(const char *s, char c)
{
 278:	1141                	addi	sp,sp,-16
 27a:	e422                	sd	s0,8(sp)
 27c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 27e:	00054783          	lbu	a5,0(a0)
 282:	cf91                	beqz	a5,29e <strchr+0x26>
    if(*s == c)
 284:	00f58a63          	beq	a1,a5,298 <strchr+0x20>
  for(; *s; s++)
 288:	0505                	addi	a0,a0,1
 28a:	00054783          	lbu	a5,0(a0)
 28e:	c781                	beqz	a5,296 <strchr+0x1e>
    if(*s == c)
 290:	feb79ce3          	bne	a5,a1,288 <strchr+0x10>
 294:	a011                	j	298 <strchr+0x20>
      return (char*)s;
  return 0;
 296:	4501                	li	a0,0
}
 298:	6422                	ld	s0,8(sp)
 29a:	0141                	addi	sp,sp,16
 29c:	8082                	ret
  return 0;
 29e:	4501                	li	a0,0
 2a0:	bfe5                	j	298 <strchr+0x20>

00000000000002a2 <gets>:

char*
gets(char *buf, int max)
{
 2a2:	711d                	addi	sp,sp,-96
 2a4:	ec86                	sd	ra,88(sp)
 2a6:	e8a2                	sd	s0,80(sp)
 2a8:	e4a6                	sd	s1,72(sp)
 2aa:	e0ca                	sd	s2,64(sp)
 2ac:	fc4e                	sd	s3,56(sp)
 2ae:	f852                	sd	s4,48(sp)
 2b0:	f456                	sd	s5,40(sp)
 2b2:	f05a                	sd	s6,32(sp)
 2b4:	ec5e                	sd	s7,24(sp)
 2b6:	1080                	addi	s0,sp,96
 2b8:	8baa                	mv	s7,a0
 2ba:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 2bc:	892a                	mv	s2,a0
 2be:	4981                	li	s3,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 2c0:	4aa9                	li	s5,10
 2c2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 2c4:	0019849b          	addiw	s1,s3,1
 2c8:	0344d863          	ble	s4,s1,2f8 <gets+0x56>
    cc = read(0, &c, 1);
 2cc:	4605                	li	a2,1
 2ce:	faf40593          	addi	a1,s0,-81
 2d2:	4501                	li	a0,0
 2d4:	00000097          	auipc	ra,0x0
 2d8:	1ac080e7          	jalr	428(ra) # 480 <read>
    if(cc < 1)
 2dc:	00a05e63          	blez	a0,2f8 <gets+0x56>
    buf[i++] = c;
 2e0:	faf44783          	lbu	a5,-81(s0)
 2e4:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2e8:	01578763          	beq	a5,s5,2f6 <gets+0x54>
 2ec:	0905                	addi	s2,s2,1
  for(i=0; i+1 < max; ){
 2ee:	89a6                	mv	s3,s1
    if(c == '\n' || c == '\r')
 2f0:	fd679ae3          	bne	a5,s6,2c4 <gets+0x22>
 2f4:	a011                	j	2f8 <gets+0x56>
  for(i=0; i+1 < max; ){
 2f6:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2f8:	99de                	add	s3,s3,s7
 2fa:	00098023          	sb	zero,0(s3)
  return buf;
}
 2fe:	855e                	mv	a0,s7
 300:	60e6                	ld	ra,88(sp)
 302:	6446                	ld	s0,80(sp)
 304:	64a6                	ld	s1,72(sp)
 306:	6906                	ld	s2,64(sp)
 308:	79e2                	ld	s3,56(sp)
 30a:	7a42                	ld	s4,48(sp)
 30c:	7aa2                	ld	s5,40(sp)
 30e:	7b02                	ld	s6,32(sp)
 310:	6be2                	ld	s7,24(sp)
 312:	6125                	addi	sp,sp,96
 314:	8082                	ret

0000000000000316 <stat>:

int
stat(const char *n, struct stat *st)
{
 316:	1101                	addi	sp,sp,-32
 318:	ec06                	sd	ra,24(sp)
 31a:	e822                	sd	s0,16(sp)
 31c:	e426                	sd	s1,8(sp)
 31e:	e04a                	sd	s2,0(sp)
 320:	1000                	addi	s0,sp,32
 322:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 324:	4581                	li	a1,0
 326:	00000097          	auipc	ra,0x0
 32a:	182080e7          	jalr	386(ra) # 4a8 <open>
  if(fd < 0)
 32e:	02054563          	bltz	a0,358 <stat+0x42>
 332:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 334:	85ca                	mv	a1,s2
 336:	00000097          	auipc	ra,0x0
 33a:	18a080e7          	jalr	394(ra) # 4c0 <fstat>
 33e:	892a                	mv	s2,a0
  close(fd);
 340:	8526                	mv	a0,s1
 342:	00000097          	auipc	ra,0x0
 346:	14e080e7          	jalr	334(ra) # 490 <close>
  return r;
}
 34a:	854a                	mv	a0,s2
 34c:	60e2                	ld	ra,24(sp)
 34e:	6442                	ld	s0,16(sp)
 350:	64a2                	ld	s1,8(sp)
 352:	6902                	ld	s2,0(sp)
 354:	6105                	addi	sp,sp,32
 356:	8082                	ret
    return -1;
 358:	597d                	li	s2,-1
 35a:	bfc5                	j	34a <stat+0x34>

000000000000035c <atoi>:

int
atoi(const char *s)
{
 35c:	1141                	addi	sp,sp,-16
 35e:	e422                	sd	s0,8(sp)
 360:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 362:	00054683          	lbu	a3,0(a0)
 366:	fd06879b          	addiw	a5,a3,-48
 36a:	0ff7f793          	andi	a5,a5,255
 36e:	4725                	li	a4,9
 370:	02f76963          	bltu	a4,a5,3a2 <atoi+0x46>
 374:	862a                	mv	a2,a0
  n = 0;
 376:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 378:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 37a:	0605                	addi	a2,a2,1
 37c:	0025179b          	slliw	a5,a0,0x2
 380:	9fa9                	addw	a5,a5,a0
 382:	0017979b          	slliw	a5,a5,0x1
 386:	9fb5                	addw	a5,a5,a3
 388:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 38c:	00064683          	lbu	a3,0(a2)
 390:	fd06871b          	addiw	a4,a3,-48
 394:	0ff77713          	andi	a4,a4,255
 398:	fee5f1e3          	bleu	a4,a1,37a <atoi+0x1e>
  return n;
}
 39c:	6422                	ld	s0,8(sp)
 39e:	0141                	addi	sp,sp,16
 3a0:	8082                	ret
  n = 0;
 3a2:	4501                	li	a0,0
 3a4:	bfe5                	j	39c <atoi+0x40>

00000000000003a6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 3a6:	1141                	addi	sp,sp,-16
 3a8:	e422                	sd	s0,8(sp)
 3aa:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 3ac:	02b57663          	bleu	a1,a0,3d8 <memmove+0x32>
    while(n-- > 0)
 3b0:	02c05163          	blez	a2,3d2 <memmove+0x2c>
 3b4:	fff6079b          	addiw	a5,a2,-1
 3b8:	1782                	slli	a5,a5,0x20
 3ba:	9381                	srli	a5,a5,0x20
 3bc:	0785                	addi	a5,a5,1
 3be:	97aa                	add	a5,a5,a0
  dst = vdst;
 3c0:	872a                	mv	a4,a0
      *dst++ = *src++;
 3c2:	0585                	addi	a1,a1,1
 3c4:	0705                	addi	a4,a4,1
 3c6:	fff5c683          	lbu	a3,-1(a1)
 3ca:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 3ce:	fee79ae3          	bne	a5,a4,3c2 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 3d2:	6422                	ld	s0,8(sp)
 3d4:	0141                	addi	sp,sp,16
 3d6:	8082                	ret
    dst += n;
 3d8:	00c50733          	add	a4,a0,a2
    src += n;
 3dc:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3de:	fec05ae3          	blez	a2,3d2 <memmove+0x2c>
 3e2:	fff6079b          	addiw	a5,a2,-1
 3e6:	1782                	slli	a5,a5,0x20
 3e8:	9381                	srli	a5,a5,0x20
 3ea:	fff7c793          	not	a5,a5
 3ee:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3f0:	15fd                	addi	a1,a1,-1
 3f2:	177d                	addi	a4,a4,-1
 3f4:	0005c683          	lbu	a3,0(a1)
 3f8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3fc:	fef71ae3          	bne	a4,a5,3f0 <memmove+0x4a>
 400:	bfc9                	j	3d2 <memmove+0x2c>

0000000000000402 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 402:	1141                	addi	sp,sp,-16
 404:	e422                	sd	s0,8(sp)
 406:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 408:	ce15                	beqz	a2,444 <memcmp+0x42>
 40a:	fff6069b          	addiw	a3,a2,-1
    if (*p1 != *p2) {
 40e:	00054783          	lbu	a5,0(a0)
 412:	0005c703          	lbu	a4,0(a1)
 416:	02e79063          	bne	a5,a4,436 <memcmp+0x34>
 41a:	1682                	slli	a3,a3,0x20
 41c:	9281                	srli	a3,a3,0x20
 41e:	0685                	addi	a3,a3,1
 420:	96aa                	add	a3,a3,a0
      return *p1 - *p2;
    }
    p1++;
 422:	0505                	addi	a0,a0,1
    p2++;
 424:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 426:	00d50d63          	beq	a0,a3,440 <memcmp+0x3e>
    if (*p1 != *p2) {
 42a:	00054783          	lbu	a5,0(a0)
 42e:	0005c703          	lbu	a4,0(a1)
 432:	fee788e3          	beq	a5,a4,422 <memcmp+0x20>
      return *p1 - *p2;
 436:	40e7853b          	subw	a0,a5,a4
  }
  return 0;
}
 43a:	6422                	ld	s0,8(sp)
 43c:	0141                	addi	sp,sp,16
 43e:	8082                	ret
  return 0;
 440:	4501                	li	a0,0
 442:	bfe5                	j	43a <memcmp+0x38>
 444:	4501                	li	a0,0
 446:	bfd5                	j	43a <memcmp+0x38>

0000000000000448 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 448:	1141                	addi	sp,sp,-16
 44a:	e406                	sd	ra,8(sp)
 44c:	e022                	sd	s0,0(sp)
 44e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 450:	00000097          	auipc	ra,0x0
 454:	f56080e7          	jalr	-170(ra) # 3a6 <memmove>
}
 458:	60a2                	ld	ra,8(sp)
 45a:	6402                	ld	s0,0(sp)
 45c:	0141                	addi	sp,sp,16
 45e:	8082                	ret

0000000000000460 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 460:	4885                	li	a7,1
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <exit>:
.global exit
exit:
 li a7, SYS_exit
 468:	4889                	li	a7,2
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <wait>:
.global wait
wait:
 li a7, SYS_wait
 470:	488d                	li	a7,3
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 478:	4891                	li	a7,4
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <read>:
.global read
read:
 li a7, SYS_read
 480:	4895                	li	a7,5
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <write>:
.global write
write:
 li a7, SYS_write
 488:	48c1                	li	a7,16
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <close>:
.global close
close:
 li a7, SYS_close
 490:	48d5                	li	a7,21
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <kill>:
.global kill
kill:
 li a7, SYS_kill
 498:	4899                	li	a7,6
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 4a0:	489d                	li	a7,7
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <open>:
.global open
open:
 li a7, SYS_open
 4a8:	48bd                	li	a7,15
 ecall
 4aa:	00000073          	ecall
 ret
 4ae:	8082                	ret

00000000000004b0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 4b0:	48c5                	li	a7,17
 ecall
 4b2:	00000073          	ecall
 ret
 4b6:	8082                	ret

00000000000004b8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 4b8:	48c9                	li	a7,18
 ecall
 4ba:	00000073          	ecall
 ret
 4be:	8082                	ret

00000000000004c0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 4c0:	48a1                	li	a7,8
 ecall
 4c2:	00000073          	ecall
 ret
 4c6:	8082                	ret

00000000000004c8 <link>:
.global link
link:
 li a7, SYS_link
 4c8:	48cd                	li	a7,19
 ecall
 4ca:	00000073          	ecall
 ret
 4ce:	8082                	ret

00000000000004d0 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 4d0:	48d1                	li	a7,20
 ecall
 4d2:	00000073          	ecall
 ret
 4d6:	8082                	ret

00000000000004d8 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 4d8:	48a5                	li	a7,9
 ecall
 4da:	00000073          	ecall
 ret
 4de:	8082                	ret

00000000000004e0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 4e0:	48a9                	li	a7,10
 ecall
 4e2:	00000073          	ecall
 ret
 4e6:	8082                	ret

00000000000004e8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4e8:	48ad                	li	a7,11
 ecall
 4ea:	00000073          	ecall
 ret
 4ee:	8082                	ret

00000000000004f0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4f0:	48b1                	li	a7,12
 ecall
 4f2:	00000073          	ecall
 ret
 4f6:	8082                	ret

00000000000004f8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4f8:	48b5                	li	a7,13
 ecall
 4fa:	00000073          	ecall
 ret
 4fe:	8082                	ret

0000000000000500 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 500:	48b9                	li	a7,14
 ecall
 502:	00000073          	ecall
 ret
 506:	8082                	ret

0000000000000508 <trace>:
.global trace
trace:
 li a7, SYS_trace
 508:	48d9                	li	a7,22
 ecall
 50a:	00000073          	ecall
 ret
 50e:	8082                	ret

0000000000000510 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 510:	1101                	addi	sp,sp,-32
 512:	ec06                	sd	ra,24(sp)
 514:	e822                	sd	s0,16(sp)
 516:	1000                	addi	s0,sp,32
 518:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 51c:	4605                	li	a2,1
 51e:	fef40593          	addi	a1,s0,-17
 522:	00000097          	auipc	ra,0x0
 526:	f66080e7          	jalr	-154(ra) # 488 <write>
}
 52a:	60e2                	ld	ra,24(sp)
 52c:	6442                	ld	s0,16(sp)
 52e:	6105                	addi	sp,sp,32
 530:	8082                	ret

0000000000000532 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 532:	7139                	addi	sp,sp,-64
 534:	fc06                	sd	ra,56(sp)
 536:	f822                	sd	s0,48(sp)
 538:	f426                	sd	s1,40(sp)
 53a:	f04a                	sd	s2,32(sp)
 53c:	ec4e                	sd	s3,24(sp)
 53e:	0080                	addi	s0,sp,64
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 540:	c299                	beqz	a3,546 <printint+0x14>
 542:	0005cd63          	bltz	a1,55c <printint+0x2a>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 546:	2581                	sext.w	a1,a1
  neg = 0;
 548:	4301                	li	t1,0
 54a:	fc040713          	addi	a4,s0,-64
  }

  i = 0;
 54e:	4801                	li	a6,0
  do{
    buf[i++] = digits[x % base];
 550:	2601                	sext.w	a2,a2
 552:	00000897          	auipc	a7,0x0
 556:	47e88893          	addi	a7,a7,1150 # 9d0 <digits>
 55a:	a801                	j	56a <printint+0x38>
    x = -xx;
 55c:	40b005bb          	negw	a1,a1
 560:	2581                	sext.w	a1,a1
    neg = 1;
 562:	4305                	li	t1,1
    x = -xx;
 564:	b7dd                	j	54a <printint+0x18>
  }while((x /= base) != 0);
 566:	85be                	mv	a1,a5
    buf[i++] = digits[x % base];
 568:	8836                	mv	a6,a3
 56a:	0018069b          	addiw	a3,a6,1
 56e:	02c5f7bb          	remuw	a5,a1,a2
 572:	1782                	slli	a5,a5,0x20
 574:	9381                	srli	a5,a5,0x20
 576:	97c6                	add	a5,a5,a7
 578:	0007c783          	lbu	a5,0(a5)
 57c:	00f70023          	sb	a5,0(a4)
  }while((x /= base) != 0);
 580:	0705                	addi	a4,a4,1
 582:	02c5d7bb          	divuw	a5,a1,a2
 586:	fec5f0e3          	bleu	a2,a1,566 <printint+0x34>
  if(neg)
 58a:	00030b63          	beqz	t1,5a0 <printint+0x6e>
    buf[i++] = '-';
 58e:	fd040793          	addi	a5,s0,-48
 592:	96be                	add	a3,a3,a5
 594:	02d00793          	li	a5,45
 598:	fef68823          	sb	a5,-16(a3)
 59c:	0028069b          	addiw	a3,a6,2

  while(--i >= 0)
 5a0:	02d05963          	blez	a3,5d2 <printint+0xa0>
 5a4:	89aa                	mv	s3,a0
 5a6:	fc040793          	addi	a5,s0,-64
 5aa:	00d784b3          	add	s1,a5,a3
 5ae:	fff78913          	addi	s2,a5,-1
 5b2:	9936                	add	s2,s2,a3
 5b4:	36fd                	addiw	a3,a3,-1
 5b6:	1682                	slli	a3,a3,0x20
 5b8:	9281                	srli	a3,a3,0x20
 5ba:	40d90933          	sub	s2,s2,a3
    putc(fd, buf[i]);
 5be:	fff4c583          	lbu	a1,-1(s1)
 5c2:	854e                	mv	a0,s3
 5c4:	00000097          	auipc	ra,0x0
 5c8:	f4c080e7          	jalr	-180(ra) # 510 <putc>
  while(--i >= 0)
 5cc:	14fd                	addi	s1,s1,-1
 5ce:	ff2498e3          	bne	s1,s2,5be <printint+0x8c>
}
 5d2:	70e2                	ld	ra,56(sp)
 5d4:	7442                	ld	s0,48(sp)
 5d6:	74a2                	ld	s1,40(sp)
 5d8:	7902                	ld	s2,32(sp)
 5da:	69e2                	ld	s3,24(sp)
 5dc:	6121                	addi	sp,sp,64
 5de:	8082                	ret

00000000000005e0 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 5e0:	7119                	addi	sp,sp,-128
 5e2:	fc86                	sd	ra,120(sp)
 5e4:	f8a2                	sd	s0,112(sp)
 5e6:	f4a6                	sd	s1,104(sp)
 5e8:	f0ca                	sd	s2,96(sp)
 5ea:	ecce                	sd	s3,88(sp)
 5ec:	e8d2                	sd	s4,80(sp)
 5ee:	e4d6                	sd	s5,72(sp)
 5f0:	e0da                	sd	s6,64(sp)
 5f2:	fc5e                	sd	s7,56(sp)
 5f4:	f862                	sd	s8,48(sp)
 5f6:	f466                	sd	s9,40(sp)
 5f8:	f06a                	sd	s10,32(sp)
 5fa:	ec6e                	sd	s11,24(sp)
 5fc:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5fe:	0005c483          	lbu	s1,0(a1)
 602:	18048d63          	beqz	s1,79c <vprintf+0x1bc>
 606:	8aaa                	mv	s5,a0
 608:	8b32                	mv	s6,a2
 60a:	00158913          	addi	s2,a1,1
  state = 0;
 60e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 610:	02500a13          	li	s4,37
      if(c == 'd'){
 614:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 618:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 61c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 620:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 624:	00000b97          	auipc	s7,0x0
 628:	3acb8b93          	addi	s7,s7,940 # 9d0 <digits>
 62c:	a839                	j	64a <vprintf+0x6a>
        putc(fd, c);
 62e:	85a6                	mv	a1,s1
 630:	8556                	mv	a0,s5
 632:	00000097          	auipc	ra,0x0
 636:	ede080e7          	jalr	-290(ra) # 510 <putc>
 63a:	a019                	j	640 <vprintf+0x60>
    } else if(state == '%'){
 63c:	01498f63          	beq	s3,s4,65a <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 640:	0905                	addi	s2,s2,1
 642:	fff94483          	lbu	s1,-1(s2)
 646:	14048b63          	beqz	s1,79c <vprintf+0x1bc>
    c = fmt[i] & 0xff;
 64a:	0004879b          	sext.w	a5,s1
    if(state == 0){
 64e:	fe0997e3          	bnez	s3,63c <vprintf+0x5c>
      if(c == '%'){
 652:	fd479ee3          	bne	a5,s4,62e <vprintf+0x4e>
        state = '%';
 656:	89be                	mv	s3,a5
 658:	b7e5                	j	640 <vprintf+0x60>
      if(c == 'd'){
 65a:	05878063          	beq	a5,s8,69a <vprintf+0xba>
      } else if(c == 'l') {
 65e:	05978c63          	beq	a5,s9,6b6 <vprintf+0xd6>
      } else if(c == 'x') {
 662:	07a78863          	beq	a5,s10,6d2 <vprintf+0xf2>
      } else if(c == 'p') {
 666:	09b78463          	beq	a5,s11,6ee <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 66a:	07300713          	li	a4,115
 66e:	0ce78563          	beq	a5,a4,738 <vprintf+0x158>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 672:	06300713          	li	a4,99
 676:	0ee78c63          	beq	a5,a4,76e <vprintf+0x18e>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 67a:	11478663          	beq	a5,s4,786 <vprintf+0x1a6>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 67e:	85d2                	mv	a1,s4
 680:	8556                	mv	a0,s5
 682:	00000097          	auipc	ra,0x0
 686:	e8e080e7          	jalr	-370(ra) # 510 <putc>
        putc(fd, c);
 68a:	85a6                	mv	a1,s1
 68c:	8556                	mv	a0,s5
 68e:	00000097          	auipc	ra,0x0
 692:	e82080e7          	jalr	-382(ra) # 510 <putc>
      }
      state = 0;
 696:	4981                	li	s3,0
 698:	b765                	j	640 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 69a:	008b0493          	addi	s1,s6,8
 69e:	4685                	li	a3,1
 6a0:	4629                	li	a2,10
 6a2:	000b2583          	lw	a1,0(s6)
 6a6:	8556                	mv	a0,s5
 6a8:	00000097          	auipc	ra,0x0
 6ac:	e8a080e7          	jalr	-374(ra) # 532 <printint>
 6b0:	8b26                	mv	s6,s1
      state = 0;
 6b2:	4981                	li	s3,0
 6b4:	b771                	j	640 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 6b6:	008b0493          	addi	s1,s6,8
 6ba:	4681                	li	a3,0
 6bc:	4629                	li	a2,10
 6be:	000b2583          	lw	a1,0(s6)
 6c2:	8556                	mv	a0,s5
 6c4:	00000097          	auipc	ra,0x0
 6c8:	e6e080e7          	jalr	-402(ra) # 532 <printint>
 6cc:	8b26                	mv	s6,s1
      state = 0;
 6ce:	4981                	li	s3,0
 6d0:	bf85                	j	640 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 6d2:	008b0493          	addi	s1,s6,8
 6d6:	4681                	li	a3,0
 6d8:	4641                	li	a2,16
 6da:	000b2583          	lw	a1,0(s6)
 6de:	8556                	mv	a0,s5
 6e0:	00000097          	auipc	ra,0x0
 6e4:	e52080e7          	jalr	-430(ra) # 532 <printint>
 6e8:	8b26                	mv	s6,s1
      state = 0;
 6ea:	4981                	li	s3,0
 6ec:	bf91                	j	640 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6ee:	008b0793          	addi	a5,s6,8
 6f2:	f8f43423          	sd	a5,-120(s0)
 6f6:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6fa:	03000593          	li	a1,48
 6fe:	8556                	mv	a0,s5
 700:	00000097          	auipc	ra,0x0
 704:	e10080e7          	jalr	-496(ra) # 510 <putc>
  putc(fd, 'x');
 708:	85ea                	mv	a1,s10
 70a:	8556                	mv	a0,s5
 70c:	00000097          	auipc	ra,0x0
 710:	e04080e7          	jalr	-508(ra) # 510 <putc>
 714:	44c1                	li	s1,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 716:	03c9d793          	srli	a5,s3,0x3c
 71a:	97de                	add	a5,a5,s7
 71c:	0007c583          	lbu	a1,0(a5)
 720:	8556                	mv	a0,s5
 722:	00000097          	auipc	ra,0x0
 726:	dee080e7          	jalr	-530(ra) # 510 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 72a:	0992                	slli	s3,s3,0x4
 72c:	34fd                	addiw	s1,s1,-1
 72e:	f4e5                	bnez	s1,716 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 730:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 734:	4981                	li	s3,0
 736:	b729                	j	640 <vprintf+0x60>
        s = va_arg(ap, char*);
 738:	008b0993          	addi	s3,s6,8
 73c:	000b3483          	ld	s1,0(s6)
        if(s == 0)
 740:	c085                	beqz	s1,760 <vprintf+0x180>
        while(*s != 0){
 742:	0004c583          	lbu	a1,0(s1)
 746:	c9a1                	beqz	a1,796 <vprintf+0x1b6>
          putc(fd, *s);
 748:	8556                	mv	a0,s5
 74a:	00000097          	auipc	ra,0x0
 74e:	dc6080e7          	jalr	-570(ra) # 510 <putc>
          s++;
 752:	0485                	addi	s1,s1,1
        while(*s != 0){
 754:	0004c583          	lbu	a1,0(s1)
 758:	f9e5                	bnez	a1,748 <vprintf+0x168>
        s = va_arg(ap, char*);
 75a:	8b4e                	mv	s6,s3
      state = 0;
 75c:	4981                	li	s3,0
 75e:	b5cd                	j	640 <vprintf+0x60>
          s = "(null)";
 760:	00000497          	auipc	s1,0x0
 764:	28848493          	addi	s1,s1,648 # 9e8 <digits+0x18>
        while(*s != 0){
 768:	02800593          	li	a1,40
 76c:	bff1                	j	748 <vprintf+0x168>
        putc(fd, va_arg(ap, uint));
 76e:	008b0493          	addi	s1,s6,8
 772:	000b4583          	lbu	a1,0(s6)
 776:	8556                	mv	a0,s5
 778:	00000097          	auipc	ra,0x0
 77c:	d98080e7          	jalr	-616(ra) # 510 <putc>
 780:	8b26                	mv	s6,s1
      state = 0;
 782:	4981                	li	s3,0
 784:	bd75                	j	640 <vprintf+0x60>
        putc(fd, c);
 786:	85d2                	mv	a1,s4
 788:	8556                	mv	a0,s5
 78a:	00000097          	auipc	ra,0x0
 78e:	d86080e7          	jalr	-634(ra) # 510 <putc>
      state = 0;
 792:	4981                	li	s3,0
 794:	b575                	j	640 <vprintf+0x60>
        s = va_arg(ap, char*);
 796:	8b4e                	mv	s6,s3
      state = 0;
 798:	4981                	li	s3,0
 79a:	b55d                	j	640 <vprintf+0x60>
    }
  }
}
 79c:	70e6                	ld	ra,120(sp)
 79e:	7446                	ld	s0,112(sp)
 7a0:	74a6                	ld	s1,104(sp)
 7a2:	7906                	ld	s2,96(sp)
 7a4:	69e6                	ld	s3,88(sp)
 7a6:	6a46                	ld	s4,80(sp)
 7a8:	6aa6                	ld	s5,72(sp)
 7aa:	6b06                	ld	s6,64(sp)
 7ac:	7be2                	ld	s7,56(sp)
 7ae:	7c42                	ld	s8,48(sp)
 7b0:	7ca2                	ld	s9,40(sp)
 7b2:	7d02                	ld	s10,32(sp)
 7b4:	6de2                	ld	s11,24(sp)
 7b6:	6109                	addi	sp,sp,128
 7b8:	8082                	ret

00000000000007ba <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 7ba:	715d                	addi	sp,sp,-80
 7bc:	ec06                	sd	ra,24(sp)
 7be:	e822                	sd	s0,16(sp)
 7c0:	1000                	addi	s0,sp,32
 7c2:	e010                	sd	a2,0(s0)
 7c4:	e414                	sd	a3,8(s0)
 7c6:	e818                	sd	a4,16(s0)
 7c8:	ec1c                	sd	a5,24(s0)
 7ca:	03043023          	sd	a6,32(s0)
 7ce:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 7d2:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 7d6:	8622                	mv	a2,s0
 7d8:	00000097          	auipc	ra,0x0
 7dc:	e08080e7          	jalr	-504(ra) # 5e0 <vprintf>
}
 7e0:	60e2                	ld	ra,24(sp)
 7e2:	6442                	ld	s0,16(sp)
 7e4:	6161                	addi	sp,sp,80
 7e6:	8082                	ret

00000000000007e8 <printf>:

void
printf(const char *fmt, ...)
{
 7e8:	711d                	addi	sp,sp,-96
 7ea:	ec06                	sd	ra,24(sp)
 7ec:	e822                	sd	s0,16(sp)
 7ee:	1000                	addi	s0,sp,32
 7f0:	e40c                	sd	a1,8(s0)
 7f2:	e810                	sd	a2,16(s0)
 7f4:	ec14                	sd	a3,24(s0)
 7f6:	f018                	sd	a4,32(s0)
 7f8:	f41c                	sd	a5,40(s0)
 7fa:	03043823          	sd	a6,48(s0)
 7fe:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 802:	00840613          	addi	a2,s0,8
 806:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 80a:	85aa                	mv	a1,a0
 80c:	4505                	li	a0,1
 80e:	00000097          	auipc	ra,0x0
 812:	dd2080e7          	jalr	-558(ra) # 5e0 <vprintf>
}
 816:	60e2                	ld	ra,24(sp)
 818:	6442                	ld	s0,16(sp)
 81a:	6125                	addi	sp,sp,96
 81c:	8082                	ret

000000000000081e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 81e:	1141                	addi	sp,sp,-16
 820:	e422                	sd	s0,8(sp)
 822:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 824:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 828:	00000797          	auipc	a5,0x0
 82c:	1c878793          	addi	a5,a5,456 # 9f0 <__bss_start>
 830:	639c                	ld	a5,0(a5)
 832:	a805                	j	862 <free+0x44>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 834:	4618                	lw	a4,8(a2)
 836:	9db9                	addw	a1,a1,a4
 838:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 83c:	6398                	ld	a4,0(a5)
 83e:	6318                	ld	a4,0(a4)
 840:	fee53823          	sd	a4,-16(a0)
 844:	a091                	j	888 <free+0x6a>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 846:	ff852703          	lw	a4,-8(a0)
 84a:	9e39                	addw	a2,a2,a4
 84c:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 84e:	ff053703          	ld	a4,-16(a0)
 852:	e398                	sd	a4,0(a5)
 854:	a099                	j	89a <free+0x7c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 856:	6398                	ld	a4,0(a5)
 858:	00e7e463          	bltu	a5,a4,860 <free+0x42>
 85c:	00e6ea63          	bltu	a3,a4,870 <free+0x52>
{
 860:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 862:	fed7fae3          	bleu	a3,a5,856 <free+0x38>
 866:	6398                	ld	a4,0(a5)
 868:	00e6e463          	bltu	a3,a4,870 <free+0x52>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 86c:	fee7eae3          	bltu	a5,a4,860 <free+0x42>
  if(bp + bp->s.size == p->s.ptr){
 870:	ff852583          	lw	a1,-8(a0)
 874:	6390                	ld	a2,0(a5)
 876:	02059713          	slli	a4,a1,0x20
 87a:	9301                	srli	a4,a4,0x20
 87c:	0712                	slli	a4,a4,0x4
 87e:	9736                	add	a4,a4,a3
 880:	fae60ae3          	beq	a2,a4,834 <free+0x16>
    bp->s.ptr = p->s.ptr;
 884:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 888:	4790                	lw	a2,8(a5)
 88a:	02061713          	slli	a4,a2,0x20
 88e:	9301                	srli	a4,a4,0x20
 890:	0712                	slli	a4,a4,0x4
 892:	973e                	add	a4,a4,a5
 894:	fae689e3          	beq	a3,a4,846 <free+0x28>
  } else
    p->s.ptr = bp;
 898:	e394                	sd	a3,0(a5)
  freep = p;
 89a:	00000717          	auipc	a4,0x0
 89e:	14f73b23          	sd	a5,342(a4) # 9f0 <__bss_start>
}
 8a2:	6422                	ld	s0,8(sp)
 8a4:	0141                	addi	sp,sp,16
 8a6:	8082                	ret

00000000000008a8 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 8a8:	7139                	addi	sp,sp,-64
 8aa:	fc06                	sd	ra,56(sp)
 8ac:	f822                	sd	s0,48(sp)
 8ae:	f426                	sd	s1,40(sp)
 8b0:	f04a                	sd	s2,32(sp)
 8b2:	ec4e                	sd	s3,24(sp)
 8b4:	e852                	sd	s4,16(sp)
 8b6:	e456                	sd	s5,8(sp)
 8b8:	e05a                	sd	s6,0(sp)
 8ba:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 8bc:	02051993          	slli	s3,a0,0x20
 8c0:	0209d993          	srli	s3,s3,0x20
 8c4:	09bd                	addi	s3,s3,15
 8c6:	0049d993          	srli	s3,s3,0x4
 8ca:	2985                	addiw	s3,s3,1
 8cc:	0009891b          	sext.w	s2,s3
  if((prevp = freep) == 0){
 8d0:	00000797          	auipc	a5,0x0
 8d4:	12078793          	addi	a5,a5,288 # 9f0 <__bss_start>
 8d8:	6388                	ld	a0,0(a5)
 8da:	c515                	beqz	a0,906 <malloc+0x5e>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8dc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8de:	4798                	lw	a4,8(a5)
 8e0:	03277f63          	bleu	s2,a4,91e <malloc+0x76>
 8e4:	8a4e                	mv	s4,s3
 8e6:	0009871b          	sext.w	a4,s3
 8ea:	6685                	lui	a3,0x1
 8ec:	00d77363          	bleu	a3,a4,8f2 <malloc+0x4a>
 8f0:	6a05                	lui	s4,0x1
 8f2:	000a0a9b          	sext.w	s5,s4
  p = sbrk(nu * sizeof(Header));
 8f6:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8fa:	00000497          	auipc	s1,0x0
 8fe:	0f648493          	addi	s1,s1,246 # 9f0 <__bss_start>
  if(p == (char*)-1)
 902:	5b7d                	li	s6,-1
 904:	a885                	j	974 <malloc+0xcc>
    base.s.ptr = freep = prevp = &base;
 906:	00000797          	auipc	a5,0x0
 90a:	0f278793          	addi	a5,a5,242 # 9f8 <base>
 90e:	00000717          	auipc	a4,0x0
 912:	0ef73123          	sd	a5,226(a4) # 9f0 <__bss_start>
 916:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 918:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 91c:	b7e1                	j	8e4 <malloc+0x3c>
      if(p->s.size == nunits)
 91e:	02e90b63          	beq	s2,a4,954 <malloc+0xac>
        p->s.size -= nunits;
 922:	4137073b          	subw	a4,a4,s3
 926:	c798                	sw	a4,8(a5)
        p += p->s.size;
 928:	1702                	slli	a4,a4,0x20
 92a:	9301                	srli	a4,a4,0x20
 92c:	0712                	slli	a4,a4,0x4
 92e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 930:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 934:	00000717          	auipc	a4,0x0
 938:	0aa73e23          	sd	a0,188(a4) # 9f0 <__bss_start>
      return (void*)(p + 1);
 93c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 940:	70e2                	ld	ra,56(sp)
 942:	7442                	ld	s0,48(sp)
 944:	74a2                	ld	s1,40(sp)
 946:	7902                	ld	s2,32(sp)
 948:	69e2                	ld	s3,24(sp)
 94a:	6a42                	ld	s4,16(sp)
 94c:	6aa2                	ld	s5,8(sp)
 94e:	6b02                	ld	s6,0(sp)
 950:	6121                	addi	sp,sp,64
 952:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 954:	6398                	ld	a4,0(a5)
 956:	e118                	sd	a4,0(a0)
 958:	bff1                	j	934 <malloc+0x8c>
  hp->s.size = nu;
 95a:	01552423          	sw	s5,8(a0)
  free((void*)(hp + 1));
 95e:	0541                	addi	a0,a0,16
 960:	00000097          	auipc	ra,0x0
 964:	ebe080e7          	jalr	-322(ra) # 81e <free>
  return freep;
 968:	6088                	ld	a0,0(s1)
      if((p = morecore(nunits)) == 0)
 96a:	d979                	beqz	a0,940 <malloc+0x98>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 96c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 96e:	4798                	lw	a4,8(a5)
 970:	fb2777e3          	bleu	s2,a4,91e <malloc+0x76>
    if(p == freep)
 974:	6098                	ld	a4,0(s1)
 976:	853e                	mv	a0,a5
 978:	fef71ae3          	bne	a4,a5,96c <malloc+0xc4>
  p = sbrk(nu * sizeof(Header));
 97c:	8552                	mv	a0,s4
 97e:	00000097          	auipc	ra,0x0
 982:	b72080e7          	jalr	-1166(ra) # 4f0 <sbrk>
  if(p == (char*)-1)
 986:	fd651ae3          	bne	a0,s6,95a <malloc+0xb2>
        return 0;
 98a:	4501                	li	a0,0
 98c:	bf55                	j	940 <malloc+0x98>
