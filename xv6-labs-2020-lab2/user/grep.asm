
user/_grep：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <matchstar>:
  return 0;
}

// matchstar: search for c*re at beginning of text
int matchstar(int c, char *re, char *text)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	e44e                	sd	s3,8(sp)
   c:	e052                	sd	s4,0(sp)
   e:	1800                	addi	s0,sp,48
  10:	892a                	mv	s2,a0
  12:	89ae                	mv	s3,a1
  14:	84b2                	mv	s1,a2
  do{  // a * matches zero or more instances
    if(matchhere(re, text))
      return 1;
  }while(*text!='\0' && (*text++==c || c=='.'));
  16:	02e00a13          	li	s4,46
    if(matchhere(re, text))
  1a:	85a6                	mv	a1,s1
  1c:	854e                	mv	a0,s3
  1e:	00000097          	auipc	ra,0x0
  22:	030080e7          	jalr	48(ra) # 4e <matchhere>
  26:	e919                	bnez	a0,3c <matchstar+0x3c>
  }while(*text!='\0' && (*text++==c || c=='.'));
  28:	0004c783          	lbu	a5,0(s1)
  2c:	cb89                	beqz	a5,3e <matchstar+0x3e>
  2e:	0485                	addi	s1,s1,1
  30:	2781                	sext.w	a5,a5
  32:	ff2784e3          	beq	a5,s2,1a <matchstar+0x1a>
  36:	ff4902e3          	beq	s2,s4,1a <matchstar+0x1a>
  3a:	a011                	j	3e <matchstar+0x3e>
      return 1;
  3c:	4505                	li	a0,1
  return 0;
}
  3e:	70a2                	ld	ra,40(sp)
  40:	7402                	ld	s0,32(sp)
  42:	64e2                	ld	s1,24(sp)
  44:	6942                	ld	s2,16(sp)
  46:	69a2                	ld	s3,8(sp)
  48:	6a02                	ld	s4,0(sp)
  4a:	6145                	addi	sp,sp,48
  4c:	8082                	ret

000000000000004e <matchhere>:
  if(re[0] == '\0')
  4e:	00054703          	lbu	a4,0(a0)
  52:	cb3d                	beqz	a4,c8 <matchhere+0x7a>
{
  54:	1141                	addi	sp,sp,-16
  56:	e406                	sd	ra,8(sp)
  58:	e022                	sd	s0,0(sp)
  5a:	0800                	addi	s0,sp,16
  5c:	87aa                	mv	a5,a0
  if(re[1] == '*')
  5e:	00154683          	lbu	a3,1(a0)
  62:	02a00613          	li	a2,42
  66:	02c68563          	beq	a3,a2,90 <matchhere+0x42>
  if(re[0] == '$' && re[1] == '\0')
  6a:	02400613          	li	a2,36
  6e:	02c70a63          	beq	a4,a2,a2 <matchhere+0x54>
  if(*text!='\0' && (re[0]=='.' || re[0]==*text))
  72:	0005c683          	lbu	a3,0(a1)
  return 0;
  76:	4501                	li	a0,0
  if(*text!='\0' && (re[0]=='.' || re[0]==*text))
  78:	ca81                	beqz	a3,88 <matchhere+0x3a>
  7a:	02e00613          	li	a2,46
  7e:	02c70d63          	beq	a4,a2,b8 <matchhere+0x6a>
  return 0;
  82:	4501                	li	a0,0
  if(*text!='\0' && (re[0]=='.' || re[0]==*text))
  84:	02d70a63          	beq	a4,a3,b8 <matchhere+0x6a>
}
  88:	60a2                	ld	ra,8(sp)
  8a:	6402                	ld	s0,0(sp)
  8c:	0141                	addi	sp,sp,16
  8e:	8082                	ret
    return matchstar(re[0], re+2, text);
  90:	862e                	mv	a2,a1
  92:	00250593          	addi	a1,a0,2
  96:	853a                	mv	a0,a4
  98:	00000097          	auipc	ra,0x0
  9c:	f68080e7          	jalr	-152(ra) # 0 <matchstar>
  a0:	b7e5                	j	88 <matchhere+0x3a>
  if(re[0] == '$' && re[1] == '\0')
  a2:	c691                	beqz	a3,ae <matchhere+0x60>
  if(*text!='\0' && (re[0]=='.' || re[0]==*text))
  a4:	0005c683          	lbu	a3,0(a1)
  a8:	fee9                	bnez	a3,82 <matchhere+0x34>
  return 0;
  aa:	4501                	li	a0,0
  ac:	bff1                	j	88 <matchhere+0x3a>
    return *text == '\0';
  ae:	0005c503          	lbu	a0,0(a1)
  b2:	00153513          	seqz	a0,a0
  b6:	bfc9                	j	88 <matchhere+0x3a>
    return matchhere(re+1, text+1);
  b8:	0585                	addi	a1,a1,1
  ba:	00178513          	addi	a0,a5,1
  be:	00000097          	auipc	ra,0x0
  c2:	f90080e7          	jalr	-112(ra) # 4e <matchhere>
  c6:	b7c9                	j	88 <matchhere+0x3a>
    return 1;
  c8:	4505                	li	a0,1
}
  ca:	8082                	ret

00000000000000cc <match>:
{
  cc:	1101                	addi	sp,sp,-32
  ce:	ec06                	sd	ra,24(sp)
  d0:	e822                	sd	s0,16(sp)
  d2:	e426                	sd	s1,8(sp)
  d4:	e04a                	sd	s2,0(sp)
  d6:	1000                	addi	s0,sp,32
  d8:	892a                	mv	s2,a0
  da:	84ae                	mv	s1,a1
  if(re[0] == '^')
  dc:	00054703          	lbu	a4,0(a0)
  e0:	05e00793          	li	a5,94
  e4:	00f70e63          	beq	a4,a5,100 <match+0x34>
    if(matchhere(re, text))
  e8:	85a6                	mv	a1,s1
  ea:	854a                	mv	a0,s2
  ec:	00000097          	auipc	ra,0x0
  f0:	f62080e7          	jalr	-158(ra) # 4e <matchhere>
  f4:	ed01                	bnez	a0,10c <match+0x40>
  }while(*text++ != '\0');
  f6:	0485                	addi	s1,s1,1
  f8:	fff4c783          	lbu	a5,-1(s1)
  fc:	f7f5                	bnez	a5,e8 <match+0x1c>
  fe:	a801                	j	10e <match+0x42>
    return matchhere(re+1, text);
 100:	0505                	addi	a0,a0,1
 102:	00000097          	auipc	ra,0x0
 106:	f4c080e7          	jalr	-180(ra) # 4e <matchhere>
 10a:	a011                	j	10e <match+0x42>
      return 1;
 10c:	4505                	li	a0,1
}
 10e:	60e2                	ld	ra,24(sp)
 110:	6442                	ld	s0,16(sp)
 112:	64a2                	ld	s1,8(sp)
 114:	6902                	ld	s2,0(sp)
 116:	6105                	addi	sp,sp,32
 118:	8082                	ret

000000000000011a <grep>:
{
 11a:	711d                	addi	sp,sp,-96
 11c:	ec86                	sd	ra,88(sp)
 11e:	e8a2                	sd	s0,80(sp)
 120:	e4a6                	sd	s1,72(sp)
 122:	e0ca                	sd	s2,64(sp)
 124:	fc4e                	sd	s3,56(sp)
 126:	f852                	sd	s4,48(sp)
 128:	f456                	sd	s5,40(sp)
 12a:	f05a                	sd	s6,32(sp)
 12c:	ec5e                	sd	s7,24(sp)
 12e:	e862                	sd	s8,16(sp)
 130:	e466                	sd	s9,8(sp)
 132:	e06a                	sd	s10,0(sp)
 134:	1080                	addi	s0,sp,96
 136:	89aa                	mv	s3,a0
 138:	8c2e                	mv	s8,a1
  m = 0;
 13a:	4a01                	li	s4,0
  while((n = read(fd, buf+m, sizeof(buf)-m-1)) > 0){
 13c:	3ff00b93          	li	s7,1023
 140:	00001b17          	auipc	s6,0x1
 144:	988b0b13          	addi	s6,s6,-1656 # ac8 <buf>
    p = buf;
 148:	8d5a                	mv	s10,s6
        *q = '\n';
 14a:	4aa9                	li	s5,10
    p = buf;
 14c:	8cda                	mv	s9,s6
  while((n = read(fd, buf+m, sizeof(buf)-m-1)) > 0){
 14e:	a099                	j	194 <grep+0x7a>
        *q = '\n';
 150:	01548023          	sb	s5,0(s1)
        write(1, p, q+1 - p);
 154:	00148613          	addi	a2,s1,1
 158:	4126063b          	subw	a2,a2,s2
 15c:	85ca                	mv	a1,s2
 15e:	4505                	li	a0,1
 160:	00000097          	auipc	ra,0x0
 164:	3fa080e7          	jalr	1018(ra) # 55a <write>
      p = q+1;
 168:	00148913          	addi	s2,s1,1
    while((q = strchr(p, '\n')) != 0){
 16c:	45a9                	li	a1,10
 16e:	854a                	mv	a0,s2
 170:	00000097          	auipc	ra,0x0
 174:	1da080e7          	jalr	474(ra) # 34a <strchr>
 178:	84aa                	mv	s1,a0
 17a:	c919                	beqz	a0,190 <grep+0x76>
      *q = 0;
 17c:	00048023          	sb	zero,0(s1)
      if(match(pattern, p)){
 180:	85ca                	mv	a1,s2
 182:	854e                	mv	a0,s3
 184:	00000097          	auipc	ra,0x0
 188:	f48080e7          	jalr	-184(ra) # cc <match>
 18c:	dd71                	beqz	a0,168 <grep+0x4e>
 18e:	b7c9                	j	150 <grep+0x36>
    if(m > 0){
 190:	03404563          	bgtz	s4,1ba <grep+0xa0>
  while((n = read(fd, buf+m, sizeof(buf)-m-1)) > 0){
 194:	414b863b          	subw	a2,s7,s4
 198:	014b05b3          	add	a1,s6,s4
 19c:	8562                	mv	a0,s8
 19e:	00000097          	auipc	ra,0x0
 1a2:	3b4080e7          	jalr	948(ra) # 552 <read>
 1a6:	02a05663          	blez	a0,1d2 <grep+0xb8>
    m += n;
 1aa:	00aa0a3b          	addw	s4,s4,a0
    buf[m] = '\0';
 1ae:	014b07b3          	add	a5,s6,s4
 1b2:	00078023          	sb	zero,0(a5)
    p = buf;
 1b6:	8966                	mv	s2,s9
    while((q = strchr(p, '\n')) != 0){
 1b8:	bf55                	j	16c <grep+0x52>
      m -= p - buf;
 1ba:	416907b3          	sub	a5,s2,s6
 1be:	40fa0a3b          	subw	s4,s4,a5
      memmove(buf, p, m);
 1c2:	8652                	mv	a2,s4
 1c4:	85ca                	mv	a1,s2
 1c6:	856a                	mv	a0,s10
 1c8:	00000097          	auipc	ra,0x0
 1cc:	2b0080e7          	jalr	688(ra) # 478 <memmove>
 1d0:	b7d1                	j	194 <grep+0x7a>
}
 1d2:	60e6                	ld	ra,88(sp)
 1d4:	6446                	ld	s0,80(sp)
 1d6:	64a6                	ld	s1,72(sp)
 1d8:	6906                	ld	s2,64(sp)
 1da:	79e2                	ld	s3,56(sp)
 1dc:	7a42                	ld	s4,48(sp)
 1de:	7aa2                	ld	s5,40(sp)
 1e0:	7b02                	ld	s6,32(sp)
 1e2:	6be2                	ld	s7,24(sp)
 1e4:	6c42                	ld	s8,16(sp)
 1e6:	6ca2                	ld	s9,8(sp)
 1e8:	6d02                	ld	s10,0(sp)
 1ea:	6125                	addi	sp,sp,96
 1ec:	8082                	ret

00000000000001ee <main>:
{
 1ee:	7139                	addi	sp,sp,-64
 1f0:	fc06                	sd	ra,56(sp)
 1f2:	f822                	sd	s0,48(sp)
 1f4:	f426                	sd	s1,40(sp)
 1f6:	f04a                	sd	s2,32(sp)
 1f8:	ec4e                	sd	s3,24(sp)
 1fa:	e852                	sd	s4,16(sp)
 1fc:	e456                	sd	s5,8(sp)
 1fe:	0080                	addi	s0,sp,64
  if(argc <= 1){
 200:	4785                	li	a5,1
 202:	04a7dd63          	ble	a0,a5,25c <main+0x6e>
  pattern = argv[1];
 206:	0085ba03          	ld	s4,8(a1)
  if(argc <= 2){
 20a:	4789                	li	a5,2
 20c:	06a7d663          	ble	a0,a5,278 <main+0x8a>
 210:	01058493          	addi	s1,a1,16
 214:	ffd5099b          	addiw	s3,a0,-3
 218:	1982                	slli	s3,s3,0x20
 21a:	0209d993          	srli	s3,s3,0x20
 21e:	098e                	slli	s3,s3,0x3
 220:	05e1                	addi	a1,a1,24
 222:	99ae                	add	s3,s3,a1
    if((fd = open(argv[i], 0)) < 0){
 224:	4581                	li	a1,0
 226:	6088                	ld	a0,0(s1)
 228:	00000097          	auipc	ra,0x0
 22c:	352080e7          	jalr	850(ra) # 57a <open>
 230:	892a                	mv	s2,a0
 232:	04054e63          	bltz	a0,28e <main+0xa0>
    grep(pattern, fd);
 236:	85aa                	mv	a1,a0
 238:	8552                	mv	a0,s4
 23a:	00000097          	auipc	ra,0x0
 23e:	ee0080e7          	jalr	-288(ra) # 11a <grep>
    close(fd);
 242:	854a                	mv	a0,s2
 244:	00000097          	auipc	ra,0x0
 248:	31e080e7          	jalr	798(ra) # 562 <close>
  for(i = 2; i < argc; i++){
 24c:	04a1                	addi	s1,s1,8
 24e:	fd349be3          	bne	s1,s3,224 <main+0x36>
  exit(0);
 252:	4501                	li	a0,0
 254:	00000097          	auipc	ra,0x0
 258:	2e6080e7          	jalr	742(ra) # 53a <exit>
    fprintf(2, "usage: grep pattern [file ...]\n");
 25c:	00001597          	auipc	a1,0x1
 260:	80c58593          	addi	a1,a1,-2036 # a68 <malloc+0xe6>
 264:	4509                	li	a0,2
 266:	00000097          	auipc	ra,0x0
 26a:	62e080e7          	jalr	1582(ra) # 894 <fprintf>
    exit(1);
 26e:	4505                	li	a0,1
 270:	00000097          	auipc	ra,0x0
 274:	2ca080e7          	jalr	714(ra) # 53a <exit>
    grep(pattern, 0);
 278:	4581                	li	a1,0
 27a:	8552                	mv	a0,s4
 27c:	00000097          	auipc	ra,0x0
 280:	e9e080e7          	jalr	-354(ra) # 11a <grep>
    exit(0);
 284:	4501                	li	a0,0
 286:	00000097          	auipc	ra,0x0
 28a:	2b4080e7          	jalr	692(ra) # 53a <exit>
      printf("grep: cannot open %s\n", argv[i]);
 28e:	608c                	ld	a1,0(s1)
 290:	00000517          	auipc	a0,0x0
 294:	7f850513          	addi	a0,a0,2040 # a88 <malloc+0x106>
 298:	00000097          	auipc	ra,0x0
 29c:	62a080e7          	jalr	1578(ra) # 8c2 <printf>
      exit(1);
 2a0:	4505                	li	a0,1
 2a2:	00000097          	auipc	ra,0x0
 2a6:	298080e7          	jalr	664(ra) # 53a <exit>

00000000000002aa <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 2aa:	1141                	addi	sp,sp,-16
 2ac:	e422                	sd	s0,8(sp)
 2ae:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 2b0:	87aa                	mv	a5,a0
 2b2:	0585                	addi	a1,a1,1
 2b4:	0785                	addi	a5,a5,1
 2b6:	fff5c703          	lbu	a4,-1(a1)
 2ba:	fee78fa3          	sb	a4,-1(a5)
 2be:	fb75                	bnez	a4,2b2 <strcpy+0x8>
    ;
  return os;
}
 2c0:	6422                	ld	s0,8(sp)
 2c2:	0141                	addi	sp,sp,16
 2c4:	8082                	ret

00000000000002c6 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 2c6:	1141                	addi	sp,sp,-16
 2c8:	e422                	sd	s0,8(sp)
 2ca:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 2cc:	00054783          	lbu	a5,0(a0)
 2d0:	cf91                	beqz	a5,2ec <strcmp+0x26>
 2d2:	0005c703          	lbu	a4,0(a1)
 2d6:	00f71b63          	bne	a4,a5,2ec <strcmp+0x26>
    p++, q++;
 2da:	0505                	addi	a0,a0,1
 2dc:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 2de:	00054783          	lbu	a5,0(a0)
 2e2:	c789                	beqz	a5,2ec <strcmp+0x26>
 2e4:	0005c703          	lbu	a4,0(a1)
 2e8:	fef709e3          	beq	a4,a5,2da <strcmp+0x14>
  return (uchar)*p - (uchar)*q;
 2ec:	0005c503          	lbu	a0,0(a1)
}
 2f0:	40a7853b          	subw	a0,a5,a0
 2f4:	6422                	ld	s0,8(sp)
 2f6:	0141                	addi	sp,sp,16
 2f8:	8082                	ret

00000000000002fa <strlen>:

uint
strlen(const char *s)
{
 2fa:	1141                	addi	sp,sp,-16
 2fc:	e422                	sd	s0,8(sp)
 2fe:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 300:	00054783          	lbu	a5,0(a0)
 304:	cf91                	beqz	a5,320 <strlen+0x26>
 306:	0505                	addi	a0,a0,1
 308:	87aa                	mv	a5,a0
 30a:	4685                	li	a3,1
 30c:	9e89                	subw	a3,a3,a0
 30e:	00f6853b          	addw	a0,a3,a5
 312:	0785                	addi	a5,a5,1
 314:	fff7c703          	lbu	a4,-1(a5)
 318:	fb7d                	bnez	a4,30e <strlen+0x14>
    ;
  return n;
}
 31a:	6422                	ld	s0,8(sp)
 31c:	0141                	addi	sp,sp,16
 31e:	8082                	ret
  for(n = 0; s[n]; n++)
 320:	4501                	li	a0,0
 322:	bfe5                	j	31a <strlen+0x20>

0000000000000324 <memset>:

void*
memset(void *dst, int c, uint n)
{
 324:	1141                	addi	sp,sp,-16
 326:	e422                	sd	s0,8(sp)
 328:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 32a:	ce09                	beqz	a2,344 <memset+0x20>
 32c:	87aa                	mv	a5,a0
 32e:	fff6071b          	addiw	a4,a2,-1
 332:	1702                	slli	a4,a4,0x20
 334:	9301                	srli	a4,a4,0x20
 336:	0705                	addi	a4,a4,1
 338:	972a                	add	a4,a4,a0
    cdst[i] = c;
 33a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 33e:	0785                	addi	a5,a5,1
 340:	fee79de3          	bne	a5,a4,33a <memset+0x16>
  }
  return dst;
}
 344:	6422                	ld	s0,8(sp)
 346:	0141                	addi	sp,sp,16
 348:	8082                	ret

000000000000034a <strchr>:

char*
strchr(const char *s, char c)
{
 34a:	1141                	addi	sp,sp,-16
 34c:	e422                	sd	s0,8(sp)
 34e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 350:	00054783          	lbu	a5,0(a0)
 354:	cf91                	beqz	a5,370 <strchr+0x26>
    if(*s == c)
 356:	00f58a63          	beq	a1,a5,36a <strchr+0x20>
  for(; *s; s++)
 35a:	0505                	addi	a0,a0,1
 35c:	00054783          	lbu	a5,0(a0)
 360:	c781                	beqz	a5,368 <strchr+0x1e>
    if(*s == c)
 362:	feb79ce3          	bne	a5,a1,35a <strchr+0x10>
 366:	a011                	j	36a <strchr+0x20>
      return (char*)s;
  return 0;
 368:	4501                	li	a0,0
}
 36a:	6422                	ld	s0,8(sp)
 36c:	0141                	addi	sp,sp,16
 36e:	8082                	ret
  return 0;
 370:	4501                	li	a0,0
 372:	bfe5                	j	36a <strchr+0x20>

0000000000000374 <gets>:

char*
gets(char *buf, int max)
{
 374:	711d                	addi	sp,sp,-96
 376:	ec86                	sd	ra,88(sp)
 378:	e8a2                	sd	s0,80(sp)
 37a:	e4a6                	sd	s1,72(sp)
 37c:	e0ca                	sd	s2,64(sp)
 37e:	fc4e                	sd	s3,56(sp)
 380:	f852                	sd	s4,48(sp)
 382:	f456                	sd	s5,40(sp)
 384:	f05a                	sd	s6,32(sp)
 386:	ec5e                	sd	s7,24(sp)
 388:	1080                	addi	s0,sp,96
 38a:	8baa                	mv	s7,a0
 38c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 38e:	892a                	mv	s2,a0
 390:	4981                	li	s3,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 392:	4aa9                	li	s5,10
 394:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 396:	0019849b          	addiw	s1,s3,1
 39a:	0344d863          	ble	s4,s1,3ca <gets+0x56>
    cc = read(0, &c, 1);
 39e:	4605                	li	a2,1
 3a0:	faf40593          	addi	a1,s0,-81
 3a4:	4501                	li	a0,0
 3a6:	00000097          	auipc	ra,0x0
 3aa:	1ac080e7          	jalr	428(ra) # 552 <read>
    if(cc < 1)
 3ae:	00a05e63          	blez	a0,3ca <gets+0x56>
    buf[i++] = c;
 3b2:	faf44783          	lbu	a5,-81(s0)
 3b6:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 3ba:	01578763          	beq	a5,s5,3c8 <gets+0x54>
 3be:	0905                	addi	s2,s2,1
  for(i=0; i+1 < max; ){
 3c0:	89a6                	mv	s3,s1
    if(c == '\n' || c == '\r')
 3c2:	fd679ae3          	bne	a5,s6,396 <gets+0x22>
 3c6:	a011                	j	3ca <gets+0x56>
  for(i=0; i+1 < max; ){
 3c8:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 3ca:	99de                	add	s3,s3,s7
 3cc:	00098023          	sb	zero,0(s3)
  return buf;
}
 3d0:	855e                	mv	a0,s7
 3d2:	60e6                	ld	ra,88(sp)
 3d4:	6446                	ld	s0,80(sp)
 3d6:	64a6                	ld	s1,72(sp)
 3d8:	6906                	ld	s2,64(sp)
 3da:	79e2                	ld	s3,56(sp)
 3dc:	7a42                	ld	s4,48(sp)
 3de:	7aa2                	ld	s5,40(sp)
 3e0:	7b02                	ld	s6,32(sp)
 3e2:	6be2                	ld	s7,24(sp)
 3e4:	6125                	addi	sp,sp,96
 3e6:	8082                	ret

00000000000003e8 <stat>:

int
stat(const char *n, struct stat *st)
{
 3e8:	1101                	addi	sp,sp,-32
 3ea:	ec06                	sd	ra,24(sp)
 3ec:	e822                	sd	s0,16(sp)
 3ee:	e426                	sd	s1,8(sp)
 3f0:	e04a                	sd	s2,0(sp)
 3f2:	1000                	addi	s0,sp,32
 3f4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 3f6:	4581                	li	a1,0
 3f8:	00000097          	auipc	ra,0x0
 3fc:	182080e7          	jalr	386(ra) # 57a <open>
  if(fd < 0)
 400:	02054563          	bltz	a0,42a <stat+0x42>
 404:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 406:	85ca                	mv	a1,s2
 408:	00000097          	auipc	ra,0x0
 40c:	18a080e7          	jalr	394(ra) # 592 <fstat>
 410:	892a                	mv	s2,a0
  close(fd);
 412:	8526                	mv	a0,s1
 414:	00000097          	auipc	ra,0x0
 418:	14e080e7          	jalr	334(ra) # 562 <close>
  return r;
}
 41c:	854a                	mv	a0,s2
 41e:	60e2                	ld	ra,24(sp)
 420:	6442                	ld	s0,16(sp)
 422:	64a2                	ld	s1,8(sp)
 424:	6902                	ld	s2,0(sp)
 426:	6105                	addi	sp,sp,32
 428:	8082                	ret
    return -1;
 42a:	597d                	li	s2,-1
 42c:	bfc5                	j	41c <stat+0x34>

000000000000042e <atoi>:

int
atoi(const char *s)
{
 42e:	1141                	addi	sp,sp,-16
 430:	e422                	sd	s0,8(sp)
 432:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 434:	00054683          	lbu	a3,0(a0)
 438:	fd06879b          	addiw	a5,a3,-48
 43c:	0ff7f793          	andi	a5,a5,255
 440:	4725                	li	a4,9
 442:	02f76963          	bltu	a4,a5,474 <atoi+0x46>
 446:	862a                	mv	a2,a0
  n = 0;
 448:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 44a:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 44c:	0605                	addi	a2,a2,1
 44e:	0025179b          	slliw	a5,a0,0x2
 452:	9fa9                	addw	a5,a5,a0
 454:	0017979b          	slliw	a5,a5,0x1
 458:	9fb5                	addw	a5,a5,a3
 45a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 45e:	00064683          	lbu	a3,0(a2)
 462:	fd06871b          	addiw	a4,a3,-48
 466:	0ff77713          	andi	a4,a4,255
 46a:	fee5f1e3          	bleu	a4,a1,44c <atoi+0x1e>
  return n;
}
 46e:	6422                	ld	s0,8(sp)
 470:	0141                	addi	sp,sp,16
 472:	8082                	ret
  n = 0;
 474:	4501                	li	a0,0
 476:	bfe5                	j	46e <atoi+0x40>

0000000000000478 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 478:	1141                	addi	sp,sp,-16
 47a:	e422                	sd	s0,8(sp)
 47c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 47e:	02b57663          	bleu	a1,a0,4aa <memmove+0x32>
    while(n-- > 0)
 482:	02c05163          	blez	a2,4a4 <memmove+0x2c>
 486:	fff6079b          	addiw	a5,a2,-1
 48a:	1782                	slli	a5,a5,0x20
 48c:	9381                	srli	a5,a5,0x20
 48e:	0785                	addi	a5,a5,1
 490:	97aa                	add	a5,a5,a0
  dst = vdst;
 492:	872a                	mv	a4,a0
      *dst++ = *src++;
 494:	0585                	addi	a1,a1,1
 496:	0705                	addi	a4,a4,1
 498:	fff5c683          	lbu	a3,-1(a1)
 49c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 4a0:	fee79ae3          	bne	a5,a4,494 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 4a4:	6422                	ld	s0,8(sp)
 4a6:	0141                	addi	sp,sp,16
 4a8:	8082                	ret
    dst += n;
 4aa:	00c50733          	add	a4,a0,a2
    src += n;
 4ae:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 4b0:	fec05ae3          	blez	a2,4a4 <memmove+0x2c>
 4b4:	fff6079b          	addiw	a5,a2,-1
 4b8:	1782                	slli	a5,a5,0x20
 4ba:	9381                	srli	a5,a5,0x20
 4bc:	fff7c793          	not	a5,a5
 4c0:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 4c2:	15fd                	addi	a1,a1,-1
 4c4:	177d                	addi	a4,a4,-1
 4c6:	0005c683          	lbu	a3,0(a1)
 4ca:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 4ce:	fef71ae3          	bne	a4,a5,4c2 <memmove+0x4a>
 4d2:	bfc9                	j	4a4 <memmove+0x2c>

00000000000004d4 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 4d4:	1141                	addi	sp,sp,-16
 4d6:	e422                	sd	s0,8(sp)
 4d8:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 4da:	ce15                	beqz	a2,516 <memcmp+0x42>
 4dc:	fff6069b          	addiw	a3,a2,-1
    if (*p1 != *p2) {
 4e0:	00054783          	lbu	a5,0(a0)
 4e4:	0005c703          	lbu	a4,0(a1)
 4e8:	02e79063          	bne	a5,a4,508 <memcmp+0x34>
 4ec:	1682                	slli	a3,a3,0x20
 4ee:	9281                	srli	a3,a3,0x20
 4f0:	0685                	addi	a3,a3,1
 4f2:	96aa                	add	a3,a3,a0
      return *p1 - *p2;
    }
    p1++;
 4f4:	0505                	addi	a0,a0,1
    p2++;
 4f6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 4f8:	00d50d63          	beq	a0,a3,512 <memcmp+0x3e>
    if (*p1 != *p2) {
 4fc:	00054783          	lbu	a5,0(a0)
 500:	0005c703          	lbu	a4,0(a1)
 504:	fee788e3          	beq	a5,a4,4f4 <memcmp+0x20>
      return *p1 - *p2;
 508:	40e7853b          	subw	a0,a5,a4
  }
  return 0;
}
 50c:	6422                	ld	s0,8(sp)
 50e:	0141                	addi	sp,sp,16
 510:	8082                	ret
  return 0;
 512:	4501                	li	a0,0
 514:	bfe5                	j	50c <memcmp+0x38>
 516:	4501                	li	a0,0
 518:	bfd5                	j	50c <memcmp+0x38>

000000000000051a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 51a:	1141                	addi	sp,sp,-16
 51c:	e406                	sd	ra,8(sp)
 51e:	e022                	sd	s0,0(sp)
 520:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 522:	00000097          	auipc	ra,0x0
 526:	f56080e7          	jalr	-170(ra) # 478 <memmove>
}
 52a:	60a2                	ld	ra,8(sp)
 52c:	6402                	ld	s0,0(sp)
 52e:	0141                	addi	sp,sp,16
 530:	8082                	ret

0000000000000532 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 532:	4885                	li	a7,1
 ecall
 534:	00000073          	ecall
 ret
 538:	8082                	ret

000000000000053a <exit>:
.global exit
exit:
 li a7, SYS_exit
 53a:	4889                	li	a7,2
 ecall
 53c:	00000073          	ecall
 ret
 540:	8082                	ret

0000000000000542 <wait>:
.global wait
wait:
 li a7, SYS_wait
 542:	488d                	li	a7,3
 ecall
 544:	00000073          	ecall
 ret
 548:	8082                	ret

000000000000054a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 54a:	4891                	li	a7,4
 ecall
 54c:	00000073          	ecall
 ret
 550:	8082                	ret

0000000000000552 <read>:
.global read
read:
 li a7, SYS_read
 552:	4895                	li	a7,5
 ecall
 554:	00000073          	ecall
 ret
 558:	8082                	ret

000000000000055a <write>:
.global write
write:
 li a7, SYS_write
 55a:	48c1                	li	a7,16
 ecall
 55c:	00000073          	ecall
 ret
 560:	8082                	ret

0000000000000562 <close>:
.global close
close:
 li a7, SYS_close
 562:	48d5                	li	a7,21
 ecall
 564:	00000073          	ecall
 ret
 568:	8082                	ret

000000000000056a <kill>:
.global kill
kill:
 li a7, SYS_kill
 56a:	4899                	li	a7,6
 ecall
 56c:	00000073          	ecall
 ret
 570:	8082                	ret

0000000000000572 <exec>:
.global exec
exec:
 li a7, SYS_exec
 572:	489d                	li	a7,7
 ecall
 574:	00000073          	ecall
 ret
 578:	8082                	ret

000000000000057a <open>:
.global open
open:
 li a7, SYS_open
 57a:	48bd                	li	a7,15
 ecall
 57c:	00000073          	ecall
 ret
 580:	8082                	ret

0000000000000582 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 582:	48c5                	li	a7,17
 ecall
 584:	00000073          	ecall
 ret
 588:	8082                	ret

000000000000058a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 58a:	48c9                	li	a7,18
 ecall
 58c:	00000073          	ecall
 ret
 590:	8082                	ret

0000000000000592 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 592:	48a1                	li	a7,8
 ecall
 594:	00000073          	ecall
 ret
 598:	8082                	ret

000000000000059a <link>:
.global link
link:
 li a7, SYS_link
 59a:	48cd                	li	a7,19
 ecall
 59c:	00000073          	ecall
 ret
 5a0:	8082                	ret

00000000000005a2 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 5a2:	48d1                	li	a7,20
 ecall
 5a4:	00000073          	ecall
 ret
 5a8:	8082                	ret

00000000000005aa <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 5aa:	48a5                	li	a7,9
 ecall
 5ac:	00000073          	ecall
 ret
 5b0:	8082                	ret

00000000000005b2 <dup>:
.global dup
dup:
 li a7, SYS_dup
 5b2:	48a9                	li	a7,10
 ecall
 5b4:	00000073          	ecall
 ret
 5b8:	8082                	ret

00000000000005ba <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 5ba:	48ad                	li	a7,11
 ecall
 5bc:	00000073          	ecall
 ret
 5c0:	8082                	ret

00000000000005c2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 5c2:	48b1                	li	a7,12
 ecall
 5c4:	00000073          	ecall
 ret
 5c8:	8082                	ret

00000000000005ca <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 5ca:	48b5                	li	a7,13
 ecall
 5cc:	00000073          	ecall
 ret
 5d0:	8082                	ret

00000000000005d2 <trace>:
.global trace
trace:
 li a7, SYS_trace
 5d2:	48d9                	li	a7,22
 ecall
 5d4:	00000073          	ecall
 ret
 5d8:	8082                	ret

00000000000005da <sysinfo>:
.global sysinfo
sysinfo:
 li a7, SYS_sysinfo
 5da:	48dd                	li	a7,23
 ecall
 5dc:	00000073          	ecall
 ret
 5e0:	8082                	ret

00000000000005e2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 5e2:	48b9                	li	a7,14
 ecall
 5e4:	00000073          	ecall
 ret
 5e8:	8082                	ret

00000000000005ea <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 5ea:	1101                	addi	sp,sp,-32
 5ec:	ec06                	sd	ra,24(sp)
 5ee:	e822                	sd	s0,16(sp)
 5f0:	1000                	addi	s0,sp,32
 5f2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 5f6:	4605                	li	a2,1
 5f8:	fef40593          	addi	a1,s0,-17
 5fc:	00000097          	auipc	ra,0x0
 600:	f5e080e7          	jalr	-162(ra) # 55a <write>
}
 604:	60e2                	ld	ra,24(sp)
 606:	6442                	ld	s0,16(sp)
 608:	6105                	addi	sp,sp,32
 60a:	8082                	ret

000000000000060c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 60c:	7139                	addi	sp,sp,-64
 60e:	fc06                	sd	ra,56(sp)
 610:	f822                	sd	s0,48(sp)
 612:	f426                	sd	s1,40(sp)
 614:	f04a                	sd	s2,32(sp)
 616:	ec4e                	sd	s3,24(sp)
 618:	0080                	addi	s0,sp,64
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 61a:	c299                	beqz	a3,620 <printint+0x14>
 61c:	0005cd63          	bltz	a1,636 <printint+0x2a>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 620:	2581                	sext.w	a1,a1
  neg = 0;
 622:	4301                	li	t1,0
 624:	fc040713          	addi	a4,s0,-64
  }

  i = 0;
 628:	4801                	li	a6,0
  do{
    buf[i++] = digits[x % base];
 62a:	2601                	sext.w	a2,a2
 62c:	00000897          	auipc	a7,0x0
 630:	47488893          	addi	a7,a7,1140 # aa0 <digits>
 634:	a801                	j	644 <printint+0x38>
    x = -xx;
 636:	40b005bb          	negw	a1,a1
 63a:	2581                	sext.w	a1,a1
    neg = 1;
 63c:	4305                	li	t1,1
    x = -xx;
 63e:	b7dd                	j	624 <printint+0x18>
  }while((x /= base) != 0);
 640:	85be                	mv	a1,a5
    buf[i++] = digits[x % base];
 642:	8836                	mv	a6,a3
 644:	0018069b          	addiw	a3,a6,1
 648:	02c5f7bb          	remuw	a5,a1,a2
 64c:	1782                	slli	a5,a5,0x20
 64e:	9381                	srli	a5,a5,0x20
 650:	97c6                	add	a5,a5,a7
 652:	0007c783          	lbu	a5,0(a5)
 656:	00f70023          	sb	a5,0(a4)
  }while((x /= base) != 0);
 65a:	0705                	addi	a4,a4,1
 65c:	02c5d7bb          	divuw	a5,a1,a2
 660:	fec5f0e3          	bleu	a2,a1,640 <printint+0x34>
  if(neg)
 664:	00030b63          	beqz	t1,67a <printint+0x6e>
    buf[i++] = '-';
 668:	fd040793          	addi	a5,s0,-48
 66c:	96be                	add	a3,a3,a5
 66e:	02d00793          	li	a5,45
 672:	fef68823          	sb	a5,-16(a3)
 676:	0028069b          	addiw	a3,a6,2

  while(--i >= 0)
 67a:	02d05963          	blez	a3,6ac <printint+0xa0>
 67e:	89aa                	mv	s3,a0
 680:	fc040793          	addi	a5,s0,-64
 684:	00d784b3          	add	s1,a5,a3
 688:	fff78913          	addi	s2,a5,-1
 68c:	9936                	add	s2,s2,a3
 68e:	36fd                	addiw	a3,a3,-1
 690:	1682                	slli	a3,a3,0x20
 692:	9281                	srli	a3,a3,0x20
 694:	40d90933          	sub	s2,s2,a3
    putc(fd, buf[i]);
 698:	fff4c583          	lbu	a1,-1(s1)
 69c:	854e                	mv	a0,s3
 69e:	00000097          	auipc	ra,0x0
 6a2:	f4c080e7          	jalr	-180(ra) # 5ea <putc>
  while(--i >= 0)
 6a6:	14fd                	addi	s1,s1,-1
 6a8:	ff2498e3          	bne	s1,s2,698 <printint+0x8c>
}
 6ac:	70e2                	ld	ra,56(sp)
 6ae:	7442                	ld	s0,48(sp)
 6b0:	74a2                	ld	s1,40(sp)
 6b2:	7902                	ld	s2,32(sp)
 6b4:	69e2                	ld	s3,24(sp)
 6b6:	6121                	addi	sp,sp,64
 6b8:	8082                	ret

00000000000006ba <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 6ba:	7119                	addi	sp,sp,-128
 6bc:	fc86                	sd	ra,120(sp)
 6be:	f8a2                	sd	s0,112(sp)
 6c0:	f4a6                	sd	s1,104(sp)
 6c2:	f0ca                	sd	s2,96(sp)
 6c4:	ecce                	sd	s3,88(sp)
 6c6:	e8d2                	sd	s4,80(sp)
 6c8:	e4d6                	sd	s5,72(sp)
 6ca:	e0da                	sd	s6,64(sp)
 6cc:	fc5e                	sd	s7,56(sp)
 6ce:	f862                	sd	s8,48(sp)
 6d0:	f466                	sd	s9,40(sp)
 6d2:	f06a                	sd	s10,32(sp)
 6d4:	ec6e                	sd	s11,24(sp)
 6d6:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 6d8:	0005c483          	lbu	s1,0(a1)
 6dc:	18048d63          	beqz	s1,876 <vprintf+0x1bc>
 6e0:	8aaa                	mv	s5,a0
 6e2:	8b32                	mv	s6,a2
 6e4:	00158913          	addi	s2,a1,1
  state = 0;
 6e8:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 6ea:	02500a13          	li	s4,37
      if(c == 'd'){
 6ee:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 6f2:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 6f6:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 6fa:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6fe:	00000b97          	auipc	s7,0x0
 702:	3a2b8b93          	addi	s7,s7,930 # aa0 <digits>
 706:	a839                	j	724 <vprintf+0x6a>
        putc(fd, c);
 708:	85a6                	mv	a1,s1
 70a:	8556                	mv	a0,s5
 70c:	00000097          	auipc	ra,0x0
 710:	ede080e7          	jalr	-290(ra) # 5ea <putc>
 714:	a019                	j	71a <vprintf+0x60>
    } else if(state == '%'){
 716:	01498f63          	beq	s3,s4,734 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 71a:	0905                	addi	s2,s2,1
 71c:	fff94483          	lbu	s1,-1(s2)
 720:	14048b63          	beqz	s1,876 <vprintf+0x1bc>
    c = fmt[i] & 0xff;
 724:	0004879b          	sext.w	a5,s1
    if(state == 0){
 728:	fe0997e3          	bnez	s3,716 <vprintf+0x5c>
      if(c == '%'){
 72c:	fd479ee3          	bne	a5,s4,708 <vprintf+0x4e>
        state = '%';
 730:	89be                	mv	s3,a5
 732:	b7e5                	j	71a <vprintf+0x60>
      if(c == 'd'){
 734:	05878063          	beq	a5,s8,774 <vprintf+0xba>
      } else if(c == 'l') {
 738:	05978c63          	beq	a5,s9,790 <vprintf+0xd6>
      } else if(c == 'x') {
 73c:	07a78863          	beq	a5,s10,7ac <vprintf+0xf2>
      } else if(c == 'p') {
 740:	09b78463          	beq	a5,s11,7c8 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 744:	07300713          	li	a4,115
 748:	0ce78563          	beq	a5,a4,812 <vprintf+0x158>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 74c:	06300713          	li	a4,99
 750:	0ee78c63          	beq	a5,a4,848 <vprintf+0x18e>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 754:	11478663          	beq	a5,s4,860 <vprintf+0x1a6>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 758:	85d2                	mv	a1,s4
 75a:	8556                	mv	a0,s5
 75c:	00000097          	auipc	ra,0x0
 760:	e8e080e7          	jalr	-370(ra) # 5ea <putc>
        putc(fd, c);
 764:	85a6                	mv	a1,s1
 766:	8556                	mv	a0,s5
 768:	00000097          	auipc	ra,0x0
 76c:	e82080e7          	jalr	-382(ra) # 5ea <putc>
      }
      state = 0;
 770:	4981                	li	s3,0
 772:	b765                	j	71a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 774:	008b0493          	addi	s1,s6,8
 778:	4685                	li	a3,1
 77a:	4629                	li	a2,10
 77c:	000b2583          	lw	a1,0(s6)
 780:	8556                	mv	a0,s5
 782:	00000097          	auipc	ra,0x0
 786:	e8a080e7          	jalr	-374(ra) # 60c <printint>
 78a:	8b26                	mv	s6,s1
      state = 0;
 78c:	4981                	li	s3,0
 78e:	b771                	j	71a <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 790:	008b0493          	addi	s1,s6,8
 794:	4681                	li	a3,0
 796:	4629                	li	a2,10
 798:	000b2583          	lw	a1,0(s6)
 79c:	8556                	mv	a0,s5
 79e:	00000097          	auipc	ra,0x0
 7a2:	e6e080e7          	jalr	-402(ra) # 60c <printint>
 7a6:	8b26                	mv	s6,s1
      state = 0;
 7a8:	4981                	li	s3,0
 7aa:	bf85                	j	71a <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 7ac:	008b0493          	addi	s1,s6,8
 7b0:	4681                	li	a3,0
 7b2:	4641                	li	a2,16
 7b4:	000b2583          	lw	a1,0(s6)
 7b8:	8556                	mv	a0,s5
 7ba:	00000097          	auipc	ra,0x0
 7be:	e52080e7          	jalr	-430(ra) # 60c <printint>
 7c2:	8b26                	mv	s6,s1
      state = 0;
 7c4:	4981                	li	s3,0
 7c6:	bf91                	j	71a <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 7c8:	008b0793          	addi	a5,s6,8
 7cc:	f8f43423          	sd	a5,-120(s0)
 7d0:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 7d4:	03000593          	li	a1,48
 7d8:	8556                	mv	a0,s5
 7da:	00000097          	auipc	ra,0x0
 7de:	e10080e7          	jalr	-496(ra) # 5ea <putc>
  putc(fd, 'x');
 7e2:	85ea                	mv	a1,s10
 7e4:	8556                	mv	a0,s5
 7e6:	00000097          	auipc	ra,0x0
 7ea:	e04080e7          	jalr	-508(ra) # 5ea <putc>
 7ee:	44c1                	li	s1,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 7f0:	03c9d793          	srli	a5,s3,0x3c
 7f4:	97de                	add	a5,a5,s7
 7f6:	0007c583          	lbu	a1,0(a5)
 7fa:	8556                	mv	a0,s5
 7fc:	00000097          	auipc	ra,0x0
 800:	dee080e7          	jalr	-530(ra) # 5ea <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 804:	0992                	slli	s3,s3,0x4
 806:	34fd                	addiw	s1,s1,-1
 808:	f4e5                	bnez	s1,7f0 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 80a:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 80e:	4981                	li	s3,0
 810:	b729                	j	71a <vprintf+0x60>
        s = va_arg(ap, char*);
 812:	008b0993          	addi	s3,s6,8
 816:	000b3483          	ld	s1,0(s6)
        if(s == 0)
 81a:	c085                	beqz	s1,83a <vprintf+0x180>
        while(*s != 0){
 81c:	0004c583          	lbu	a1,0(s1)
 820:	c9a1                	beqz	a1,870 <vprintf+0x1b6>
          putc(fd, *s);
 822:	8556                	mv	a0,s5
 824:	00000097          	auipc	ra,0x0
 828:	dc6080e7          	jalr	-570(ra) # 5ea <putc>
          s++;
 82c:	0485                	addi	s1,s1,1
        while(*s != 0){
 82e:	0004c583          	lbu	a1,0(s1)
 832:	f9e5                	bnez	a1,822 <vprintf+0x168>
        s = va_arg(ap, char*);
 834:	8b4e                	mv	s6,s3
      state = 0;
 836:	4981                	li	s3,0
 838:	b5cd                	j	71a <vprintf+0x60>
          s = "(null)";
 83a:	00000497          	auipc	s1,0x0
 83e:	27e48493          	addi	s1,s1,638 # ab8 <digits+0x18>
        while(*s != 0){
 842:	02800593          	li	a1,40
 846:	bff1                	j	822 <vprintf+0x168>
        putc(fd, va_arg(ap, uint));
 848:	008b0493          	addi	s1,s6,8
 84c:	000b4583          	lbu	a1,0(s6)
 850:	8556                	mv	a0,s5
 852:	00000097          	auipc	ra,0x0
 856:	d98080e7          	jalr	-616(ra) # 5ea <putc>
 85a:	8b26                	mv	s6,s1
      state = 0;
 85c:	4981                	li	s3,0
 85e:	bd75                	j	71a <vprintf+0x60>
        putc(fd, c);
 860:	85d2                	mv	a1,s4
 862:	8556                	mv	a0,s5
 864:	00000097          	auipc	ra,0x0
 868:	d86080e7          	jalr	-634(ra) # 5ea <putc>
      state = 0;
 86c:	4981                	li	s3,0
 86e:	b575                	j	71a <vprintf+0x60>
        s = va_arg(ap, char*);
 870:	8b4e                	mv	s6,s3
      state = 0;
 872:	4981                	li	s3,0
 874:	b55d                	j	71a <vprintf+0x60>
    }
  }
}
 876:	70e6                	ld	ra,120(sp)
 878:	7446                	ld	s0,112(sp)
 87a:	74a6                	ld	s1,104(sp)
 87c:	7906                	ld	s2,96(sp)
 87e:	69e6                	ld	s3,88(sp)
 880:	6a46                	ld	s4,80(sp)
 882:	6aa6                	ld	s5,72(sp)
 884:	6b06                	ld	s6,64(sp)
 886:	7be2                	ld	s7,56(sp)
 888:	7c42                	ld	s8,48(sp)
 88a:	7ca2                	ld	s9,40(sp)
 88c:	7d02                	ld	s10,32(sp)
 88e:	6de2                	ld	s11,24(sp)
 890:	6109                	addi	sp,sp,128
 892:	8082                	ret

0000000000000894 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 894:	715d                	addi	sp,sp,-80
 896:	ec06                	sd	ra,24(sp)
 898:	e822                	sd	s0,16(sp)
 89a:	1000                	addi	s0,sp,32
 89c:	e010                	sd	a2,0(s0)
 89e:	e414                	sd	a3,8(s0)
 8a0:	e818                	sd	a4,16(s0)
 8a2:	ec1c                	sd	a5,24(s0)
 8a4:	03043023          	sd	a6,32(s0)
 8a8:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 8ac:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 8b0:	8622                	mv	a2,s0
 8b2:	00000097          	auipc	ra,0x0
 8b6:	e08080e7          	jalr	-504(ra) # 6ba <vprintf>
}
 8ba:	60e2                	ld	ra,24(sp)
 8bc:	6442                	ld	s0,16(sp)
 8be:	6161                	addi	sp,sp,80
 8c0:	8082                	ret

00000000000008c2 <printf>:

void
printf(const char *fmt, ...)
{
 8c2:	711d                	addi	sp,sp,-96
 8c4:	ec06                	sd	ra,24(sp)
 8c6:	e822                	sd	s0,16(sp)
 8c8:	1000                	addi	s0,sp,32
 8ca:	e40c                	sd	a1,8(s0)
 8cc:	e810                	sd	a2,16(s0)
 8ce:	ec14                	sd	a3,24(s0)
 8d0:	f018                	sd	a4,32(s0)
 8d2:	f41c                	sd	a5,40(s0)
 8d4:	03043823          	sd	a6,48(s0)
 8d8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 8dc:	00840613          	addi	a2,s0,8
 8e0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 8e4:	85aa                	mv	a1,a0
 8e6:	4505                	li	a0,1
 8e8:	00000097          	auipc	ra,0x0
 8ec:	dd2080e7          	jalr	-558(ra) # 6ba <vprintf>
}
 8f0:	60e2                	ld	ra,24(sp)
 8f2:	6442                	ld	s0,16(sp)
 8f4:	6125                	addi	sp,sp,96
 8f6:	8082                	ret

00000000000008f8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 8f8:	1141                	addi	sp,sp,-16
 8fa:	e422                	sd	s0,8(sp)
 8fc:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 8fe:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 902:	00000797          	auipc	a5,0x0
 906:	1be78793          	addi	a5,a5,446 # ac0 <__bss_start>
 90a:	639c                	ld	a5,0(a5)
 90c:	a805                	j	93c <free+0x44>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 90e:	4618                	lw	a4,8(a2)
 910:	9db9                	addw	a1,a1,a4
 912:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 916:	6398                	ld	a4,0(a5)
 918:	6318                	ld	a4,0(a4)
 91a:	fee53823          	sd	a4,-16(a0)
 91e:	a091                	j	962 <free+0x6a>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 920:	ff852703          	lw	a4,-8(a0)
 924:	9e39                	addw	a2,a2,a4
 926:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 928:	ff053703          	ld	a4,-16(a0)
 92c:	e398                	sd	a4,0(a5)
 92e:	a099                	j	974 <free+0x7c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 930:	6398                	ld	a4,0(a5)
 932:	00e7e463          	bltu	a5,a4,93a <free+0x42>
 936:	00e6ea63          	bltu	a3,a4,94a <free+0x52>
{
 93a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 93c:	fed7fae3          	bleu	a3,a5,930 <free+0x38>
 940:	6398                	ld	a4,0(a5)
 942:	00e6e463          	bltu	a3,a4,94a <free+0x52>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 946:	fee7eae3          	bltu	a5,a4,93a <free+0x42>
  if(bp + bp->s.size == p->s.ptr){
 94a:	ff852583          	lw	a1,-8(a0)
 94e:	6390                	ld	a2,0(a5)
 950:	02059713          	slli	a4,a1,0x20
 954:	9301                	srli	a4,a4,0x20
 956:	0712                	slli	a4,a4,0x4
 958:	9736                	add	a4,a4,a3
 95a:	fae60ae3          	beq	a2,a4,90e <free+0x16>
    bp->s.ptr = p->s.ptr;
 95e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 962:	4790                	lw	a2,8(a5)
 964:	02061713          	slli	a4,a2,0x20
 968:	9301                	srli	a4,a4,0x20
 96a:	0712                	slli	a4,a4,0x4
 96c:	973e                	add	a4,a4,a5
 96e:	fae689e3          	beq	a3,a4,920 <free+0x28>
  } else
    p->s.ptr = bp;
 972:	e394                	sd	a3,0(a5)
  freep = p;
 974:	00000717          	auipc	a4,0x0
 978:	14f73623          	sd	a5,332(a4) # ac0 <__bss_start>
}
 97c:	6422                	ld	s0,8(sp)
 97e:	0141                	addi	sp,sp,16
 980:	8082                	ret

0000000000000982 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 982:	7139                	addi	sp,sp,-64
 984:	fc06                	sd	ra,56(sp)
 986:	f822                	sd	s0,48(sp)
 988:	f426                	sd	s1,40(sp)
 98a:	f04a                	sd	s2,32(sp)
 98c:	ec4e                	sd	s3,24(sp)
 98e:	e852                	sd	s4,16(sp)
 990:	e456                	sd	s5,8(sp)
 992:	e05a                	sd	s6,0(sp)
 994:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 996:	02051993          	slli	s3,a0,0x20
 99a:	0209d993          	srli	s3,s3,0x20
 99e:	09bd                	addi	s3,s3,15
 9a0:	0049d993          	srli	s3,s3,0x4
 9a4:	2985                	addiw	s3,s3,1
 9a6:	0009891b          	sext.w	s2,s3
  if((prevp = freep) == 0){
 9aa:	00000797          	auipc	a5,0x0
 9ae:	11678793          	addi	a5,a5,278 # ac0 <__bss_start>
 9b2:	6388                	ld	a0,0(a5)
 9b4:	c515                	beqz	a0,9e0 <malloc+0x5e>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9b6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9b8:	4798                	lw	a4,8(a5)
 9ba:	03277f63          	bleu	s2,a4,9f8 <malloc+0x76>
 9be:	8a4e                	mv	s4,s3
 9c0:	0009871b          	sext.w	a4,s3
 9c4:	6685                	lui	a3,0x1
 9c6:	00d77363          	bleu	a3,a4,9cc <malloc+0x4a>
 9ca:	6a05                	lui	s4,0x1
 9cc:	000a0a9b          	sext.w	s5,s4
  p = sbrk(nu * sizeof(Header));
 9d0:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 9d4:	00000497          	auipc	s1,0x0
 9d8:	0ec48493          	addi	s1,s1,236 # ac0 <__bss_start>
  if(p == (char*)-1)
 9dc:	5b7d                	li	s6,-1
 9de:	a885                	j	a4e <malloc+0xcc>
    base.s.ptr = freep = prevp = &base;
 9e0:	00000797          	auipc	a5,0x0
 9e4:	4e878793          	addi	a5,a5,1256 # ec8 <base>
 9e8:	00000717          	auipc	a4,0x0
 9ec:	0cf73c23          	sd	a5,216(a4) # ac0 <__bss_start>
 9f0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 9f2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 9f6:	b7e1                	j	9be <malloc+0x3c>
      if(p->s.size == nunits)
 9f8:	02e90b63          	beq	s2,a4,a2e <malloc+0xac>
        p->s.size -= nunits;
 9fc:	4137073b          	subw	a4,a4,s3
 a00:	c798                	sw	a4,8(a5)
        p += p->s.size;
 a02:	1702                	slli	a4,a4,0x20
 a04:	9301                	srli	a4,a4,0x20
 a06:	0712                	slli	a4,a4,0x4
 a08:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 a0a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 a0e:	00000717          	auipc	a4,0x0
 a12:	0aa73923          	sd	a0,178(a4) # ac0 <__bss_start>
      return (void*)(p + 1);
 a16:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 a1a:	70e2                	ld	ra,56(sp)
 a1c:	7442                	ld	s0,48(sp)
 a1e:	74a2                	ld	s1,40(sp)
 a20:	7902                	ld	s2,32(sp)
 a22:	69e2                	ld	s3,24(sp)
 a24:	6a42                	ld	s4,16(sp)
 a26:	6aa2                	ld	s5,8(sp)
 a28:	6b02                	ld	s6,0(sp)
 a2a:	6121                	addi	sp,sp,64
 a2c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 a2e:	6398                	ld	a4,0(a5)
 a30:	e118                	sd	a4,0(a0)
 a32:	bff1                	j	a0e <malloc+0x8c>
  hp->s.size = nu;
 a34:	01552423          	sw	s5,8(a0)
  free((void*)(hp + 1));
 a38:	0541                	addi	a0,a0,16
 a3a:	00000097          	auipc	ra,0x0
 a3e:	ebe080e7          	jalr	-322(ra) # 8f8 <free>
  return freep;
 a42:	6088                	ld	a0,0(s1)
      if((p = morecore(nunits)) == 0)
 a44:	d979                	beqz	a0,a1a <malloc+0x98>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 a46:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 a48:	4798                	lw	a4,8(a5)
 a4a:	fb2777e3          	bleu	s2,a4,9f8 <malloc+0x76>
    if(p == freep)
 a4e:	6098                	ld	a4,0(s1)
 a50:	853e                	mv	a0,a5
 a52:	fef71ae3          	bne	a4,a5,a46 <malloc+0xc4>
  p = sbrk(nu * sizeof(Header));
 a56:	8552                	mv	a0,s4
 a58:	00000097          	auipc	ra,0x0
 a5c:	b6a080e7          	jalr	-1174(ra) # 5c2 <sbrk>
  if(p == (char*)-1)
 a60:	fd651ae3          	bne	a0,s6,a34 <malloc+0xb2>
        return 0;
 a64:	4501                	li	a0,0
 a66:	bf55                	j	a1a <malloc+0x98>
