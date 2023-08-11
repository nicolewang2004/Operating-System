
user/_find：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <basename>:
#include "kernel/stat.h"
#include "user/user.h"

/* retrieve the filename from whole path */
char *basename(char *pathname)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
    char *prev = 0;
    char *curr = strchr(pathname, '/');
   a:	02f00593          	li	a1,47
   e:	00000097          	auipc	ra,0x0
  12:	2ca080e7          	jalr	714(ra) # 2d8 <strchr>
  16:	84aa                	mv	s1,a0
    while (curr != 0)
  18:	e119                	bnez	a0,1e <basename+0x1e>
  1a:	a819                	j	30 <basename+0x30>
    {
        prev = curr;
        curr = strchr(curr + 1, '/');
  1c:	84aa                	mv	s1,a0
  1e:	02f00593          	li	a1,47
  22:	00148513          	addi	a0,s1,1
  26:	00000097          	auipc	ra,0x0
  2a:	2b2080e7          	jalr	690(ra) # 2d8 <strchr>
    while (curr != 0)
  2e:	f57d                	bnez	a0,1c <basename+0x1c>
    }
    return prev;
}
  30:	8526                	mv	a0,s1
  32:	60e2                	ld	ra,24(sp)
  34:	6442                	ld	s0,16(sp)
  36:	64a2                	ld	s1,8(sp)
  38:	6105                	addi	sp,sp,32
  3a:	8082                	ret

000000000000003c <find>:

/* recursive */
void find(char *curr_path, char *target)
{
  3c:	d9010113          	addi	sp,sp,-624
  40:	26113423          	sd	ra,616(sp)
  44:	26813023          	sd	s0,608(sp)
  48:	24913c23          	sd	s1,600(sp)
  4c:	25213823          	sd	s2,592(sp)
  50:	25313423          	sd	s3,584(sp)
  54:	25413023          	sd	s4,576(sp)
  58:	23513c23          	sd	s5,568(sp)
  5c:	23613823          	sd	s6,560(sp)
  60:	1c80                	addi	s0,sp,624
  62:	892a                	mv	s2,a0
  64:	8a2e                	mv	s4,a1
    char buf[512], *p;
    int fd;
    struct dirent de;
    struct stat st;
    if ((fd = open(curr_path, O_RDONLY)) < 0)
  66:	4581                	li	a1,0
  68:	00000097          	auipc	ra,0x0
  6c:	4a0080e7          	jalr	1184(ra) # 508 <open>
  70:	04054863          	bltz	a0,c0 <find+0x84>
  74:	84aa                	mv	s1,a0
    {
        fprintf(2, "find: cannot open %s\n", curr_path);
        return;
    }

    if (fstat(fd, &st) < 0)
  76:	d9840593          	addi	a1,s0,-616
  7a:	00000097          	auipc	ra,0x0
  7e:	4a6080e7          	jalr	1190(ra) # 520 <fstat>
  82:	06054c63          	bltz	a0,fa <find+0xbe>
        fprintf(2, "find: cannot stat %s\n", curr_path);
        close(fd);
        return;
    }

    switch (st.type)
  86:	da041783          	lh	a5,-608(s0)
  8a:	0007869b          	sext.w	a3,a5
  8e:	4705                	li	a4,1
  90:	08e68f63          	beq	a3,a4,12e <find+0xf2>
  94:	4709                	li	a4,2
  96:	02e69f63          	bne	a3,a4,d4 <find+0x98>
    {

    case T_FILE:
    {
        char *f_name = basename(curr_path);
  9a:	854a                	mv	a0,s2
  9c:	00000097          	auipc	ra,0x0
  a0:	f64080e7          	jalr	-156(ra) # 0 <basename>
        int match = 1;
        if (f_name == 0 || strcmp(f_name + 1, target) != 0)
  a4:	c901                	beqz	a0,b4 <find+0x78>
  a6:	85d2                	mv	a1,s4
  a8:	0505                	addi	a0,a0,1
  aa:	00000097          	auipc	ra,0x0
  ae:	1aa080e7          	jalr	426(ra) # 254 <strcmp>
  b2:	c525                	beqz	a0,11a <find+0xde>
        {
            match = 0;
        }
        if (match)
            printf("%s\n", curr_path);
        close(fd);
  b4:	8526                	mv	a0,s1
  b6:	00000097          	auipc	ra,0x0
  ba:	43a080e7          	jalr	1082(ra) # 4f0 <close>
        break;
  be:	a819                	j	d4 <find+0x98>
        fprintf(2, "find: cannot open %s\n", curr_path);
  c0:	864a                	mv	a2,s2
  c2:	00001597          	auipc	a1,0x1
  c6:	92e58593          	addi	a1,a1,-1746 # 9f0 <malloc+0xe8>
  ca:	4509                	li	a0,2
  cc:	00000097          	auipc	ra,0x0
  d0:	74e080e7          	jalr	1870(ra) # 81a <fprintf>
        }
        close(fd);
        break;
    }
    }
}
  d4:	26813083          	ld	ra,616(sp)
  d8:	26013403          	ld	s0,608(sp)
  dc:	25813483          	ld	s1,600(sp)
  e0:	25013903          	ld	s2,592(sp)
  e4:	24813983          	ld	s3,584(sp)
  e8:	24013a03          	ld	s4,576(sp)
  ec:	23813a83          	ld	s5,568(sp)
  f0:	23013b03          	ld	s6,560(sp)
  f4:	27010113          	addi	sp,sp,624
  f8:	8082                	ret
        fprintf(2, "find: cannot stat %s\n", curr_path);
  fa:	864a                	mv	a2,s2
  fc:	00001597          	auipc	a1,0x1
 100:	90c58593          	addi	a1,a1,-1780 # a08 <malloc+0x100>
 104:	4509                	li	a0,2
 106:	00000097          	auipc	ra,0x0
 10a:	714080e7          	jalr	1812(ra) # 81a <fprintf>
        close(fd);
 10e:	8526                	mv	a0,s1
 110:	00000097          	auipc	ra,0x0
 114:	3e0080e7          	jalr	992(ra) # 4f0 <close>
        return;
 118:	bf75                	j	d4 <find+0x98>
            printf("%s\n", curr_path);
 11a:	85ca                	mv	a1,s2
 11c:	00001517          	auipc	a0,0x1
 120:	90450513          	addi	a0,a0,-1788 # a20 <malloc+0x118>
 124:	00000097          	auipc	ra,0x0
 128:	724080e7          	jalr	1828(ra) # 848 <printf>
 12c:	b761                	j	b4 <find+0x78>
        memset(buf, 0, sizeof(buf));
 12e:	20000613          	li	a2,512
 132:	4581                	li	a1,0
 134:	dc040513          	addi	a0,s0,-576
 138:	00000097          	auipc	ra,0x0
 13c:	17a080e7          	jalr	378(ra) # 2b2 <memset>
        uint curr_path_len = strlen(curr_path);
 140:	854a                	mv	a0,s2
 142:	00000097          	auipc	ra,0x0
 146:	146080e7          	jalr	326(ra) # 288 <strlen>
 14a:	0005099b          	sext.w	s3,a0
        memcpy(buf, curr_path, curr_path_len);
 14e:	864e                	mv	a2,s3
 150:	85ca                	mv	a1,s2
 152:	dc040513          	addi	a0,s0,-576
 156:	00000097          	auipc	ra,0x0
 15a:	352080e7          	jalr	850(ra) # 4a8 <memcpy>
        buf[curr_path_len] = '/';
 15e:	1982                	slli	s3,s3,0x20
 160:	0209d993          	srli	s3,s3,0x20
 164:	fc040793          	addi	a5,s0,-64
 168:	97ce                	add	a5,a5,s3
 16a:	02f00713          	li	a4,47
 16e:	e0e78023          	sb	a4,-512(a5)
        p = buf + curr_path_len + 1;
 172:	0985                	addi	s3,s3,1
 174:	dc040793          	addi	a5,s0,-576
 178:	99be                	add	s3,s3,a5
            if (de.inum == 0 || strcmp(de.name, ".") == 0 ||
 17a:	00001a97          	auipc	s5,0x1
 17e:	8aea8a93          	addi	s5,s5,-1874 # a28 <malloc+0x120>
                strcmp(de.name, "..") == 0)
 182:	00001b17          	auipc	s6,0x1
 186:	8aeb0b13          	addi	s6,s6,-1874 # a30 <malloc+0x128>
            if (de.inum == 0 || strcmp(de.name, ".") == 0 ||
 18a:	db240913          	addi	s2,s0,-590
        while (read(fd, &de, sizeof(de)) == sizeof(de))
 18e:	4641                	li	a2,16
 190:	db040593          	addi	a1,s0,-592
 194:	8526                	mv	a0,s1
 196:	00000097          	auipc	ra,0x0
 19a:	34a080e7          	jalr	842(ra) # 4e0 <read>
 19e:	47c1                	li	a5,16
 1a0:	04f51563          	bne	a0,a5,1ea <find+0x1ae>
            if (de.inum == 0 || strcmp(de.name, ".") == 0 ||
 1a4:	db045783          	lhu	a5,-592(s0)
 1a8:	d3fd                	beqz	a5,18e <find+0x152>
 1aa:	85d6                	mv	a1,s5
 1ac:	854a                	mv	a0,s2
 1ae:	00000097          	auipc	ra,0x0
 1b2:	0a6080e7          	jalr	166(ra) # 254 <strcmp>
 1b6:	dd61                	beqz	a0,18e <find+0x152>
                strcmp(de.name, "..") == 0)
 1b8:	85da                	mv	a1,s6
 1ba:	854a                	mv	a0,s2
 1bc:	00000097          	auipc	ra,0x0
 1c0:	098080e7          	jalr	152(ra) # 254 <strcmp>
            if (de.inum == 0 || strcmp(de.name, ".") == 0 ||
 1c4:	d569                	beqz	a0,18e <find+0x152>
            memcpy(p, de.name, DIRSIZ);
 1c6:	4639                	li	a2,14
 1c8:	db240593          	addi	a1,s0,-590
 1cc:	854e                	mv	a0,s3
 1ce:	00000097          	auipc	ra,0x0
 1d2:	2da080e7          	jalr	730(ra) # 4a8 <memcpy>
            p[DIRSIZ] = 0;
 1d6:	00098723          	sb	zero,14(s3)
            find(buf, target); // recurse
 1da:	85d2                	mv	a1,s4
 1dc:	dc040513          	addi	a0,s0,-576
 1e0:	00000097          	auipc	ra,0x0
 1e4:	e5c080e7          	jalr	-420(ra) # 3c <find>
 1e8:	b75d                	j	18e <find+0x152>
        close(fd);
 1ea:	8526                	mv	a0,s1
 1ec:	00000097          	auipc	ra,0x0
 1f0:	304080e7          	jalr	772(ra) # 4f0 <close>
        break;
 1f4:	b5c5                	j	d4 <find+0x98>

00000000000001f6 <main>:

int main(int argc, char *argv[])
{
 1f6:	1141                	addi	sp,sp,-16
 1f8:	e406                	sd	ra,8(sp)
 1fa:	e022                	sd	s0,0(sp)
 1fc:	0800                	addi	s0,sp,16
    if (argc != 3)
 1fe:	478d                	li	a5,3
 200:	02f50063          	beq	a0,a5,220 <main+0x2a>
    {
        fprintf(2, "usage: find [directory] [target filename]\n");
 204:	00001597          	auipc	a1,0x1
 208:	83458593          	addi	a1,a1,-1996 # a38 <malloc+0x130>
 20c:	4509                	li	a0,2
 20e:	00000097          	auipc	ra,0x0
 212:	60c080e7          	jalr	1548(ra) # 81a <fprintf>
        exit(1);
 216:	4505                	li	a0,1
 218:	00000097          	auipc	ra,0x0
 21c:	2b0080e7          	jalr	688(ra) # 4c8 <exit>
 220:	872e                	mv	a4,a1
    }
    find(argv[1], argv[2]);
 222:	698c                	ld	a1,16(a1)
 224:	6708                	ld	a0,8(a4)
 226:	00000097          	auipc	ra,0x0
 22a:	e16080e7          	jalr	-490(ra) # 3c <find>
    exit(0);
 22e:	4501                	li	a0,0
 230:	00000097          	auipc	ra,0x0
 234:	298080e7          	jalr	664(ra) # 4c8 <exit>

0000000000000238 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 238:	1141                	addi	sp,sp,-16
 23a:	e422                	sd	s0,8(sp)
 23c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 23e:	87aa                	mv	a5,a0
 240:	0585                	addi	a1,a1,1
 242:	0785                	addi	a5,a5,1
 244:	fff5c703          	lbu	a4,-1(a1)
 248:	fee78fa3          	sb	a4,-1(a5)
 24c:	fb75                	bnez	a4,240 <strcpy+0x8>
    ;
  return os;
}
 24e:	6422                	ld	s0,8(sp)
 250:	0141                	addi	sp,sp,16
 252:	8082                	ret

0000000000000254 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 254:	1141                	addi	sp,sp,-16
 256:	e422                	sd	s0,8(sp)
 258:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 25a:	00054783          	lbu	a5,0(a0)
 25e:	cf91                	beqz	a5,27a <strcmp+0x26>
 260:	0005c703          	lbu	a4,0(a1)
 264:	00f71b63          	bne	a4,a5,27a <strcmp+0x26>
    p++, q++;
 268:	0505                	addi	a0,a0,1
 26a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 26c:	00054783          	lbu	a5,0(a0)
 270:	c789                	beqz	a5,27a <strcmp+0x26>
 272:	0005c703          	lbu	a4,0(a1)
 276:	fef709e3          	beq	a4,a5,268 <strcmp+0x14>
  return (uchar)*p - (uchar)*q;
 27a:	0005c503          	lbu	a0,0(a1)
}
 27e:	40a7853b          	subw	a0,a5,a0
 282:	6422                	ld	s0,8(sp)
 284:	0141                	addi	sp,sp,16
 286:	8082                	ret

0000000000000288 <strlen>:

uint
strlen(const char *s)
{
 288:	1141                	addi	sp,sp,-16
 28a:	e422                	sd	s0,8(sp)
 28c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 28e:	00054783          	lbu	a5,0(a0)
 292:	cf91                	beqz	a5,2ae <strlen+0x26>
 294:	0505                	addi	a0,a0,1
 296:	87aa                	mv	a5,a0
 298:	4685                	li	a3,1
 29a:	9e89                	subw	a3,a3,a0
 29c:	00f6853b          	addw	a0,a3,a5
 2a0:	0785                	addi	a5,a5,1
 2a2:	fff7c703          	lbu	a4,-1(a5)
 2a6:	fb7d                	bnez	a4,29c <strlen+0x14>
    ;
  return n;
}
 2a8:	6422                	ld	s0,8(sp)
 2aa:	0141                	addi	sp,sp,16
 2ac:	8082                	ret
  for(n = 0; s[n]; n++)
 2ae:	4501                	li	a0,0
 2b0:	bfe5                	j	2a8 <strlen+0x20>

00000000000002b2 <memset>:

void*
memset(void *dst, int c, uint n)
{
 2b2:	1141                	addi	sp,sp,-16
 2b4:	e422                	sd	s0,8(sp)
 2b6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 2b8:	ce09                	beqz	a2,2d2 <memset+0x20>
 2ba:	87aa                	mv	a5,a0
 2bc:	fff6071b          	addiw	a4,a2,-1
 2c0:	1702                	slli	a4,a4,0x20
 2c2:	9301                	srli	a4,a4,0x20
 2c4:	0705                	addi	a4,a4,1
 2c6:	972a                	add	a4,a4,a0
    cdst[i] = c;
 2c8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 2cc:	0785                	addi	a5,a5,1
 2ce:	fee79de3          	bne	a5,a4,2c8 <memset+0x16>
  }
  return dst;
}
 2d2:	6422                	ld	s0,8(sp)
 2d4:	0141                	addi	sp,sp,16
 2d6:	8082                	ret

00000000000002d8 <strchr>:

char*
strchr(const char *s, char c)
{
 2d8:	1141                	addi	sp,sp,-16
 2da:	e422                	sd	s0,8(sp)
 2dc:	0800                	addi	s0,sp,16
  for(; *s; s++)
 2de:	00054783          	lbu	a5,0(a0)
 2e2:	cf91                	beqz	a5,2fe <strchr+0x26>
    if(*s == c)
 2e4:	00f58a63          	beq	a1,a5,2f8 <strchr+0x20>
  for(; *s; s++)
 2e8:	0505                	addi	a0,a0,1
 2ea:	00054783          	lbu	a5,0(a0)
 2ee:	c781                	beqz	a5,2f6 <strchr+0x1e>
    if(*s == c)
 2f0:	feb79ce3          	bne	a5,a1,2e8 <strchr+0x10>
 2f4:	a011                	j	2f8 <strchr+0x20>
      return (char*)s;
  return 0;
 2f6:	4501                	li	a0,0
}
 2f8:	6422                	ld	s0,8(sp)
 2fa:	0141                	addi	sp,sp,16
 2fc:	8082                	ret
  return 0;
 2fe:	4501                	li	a0,0
 300:	bfe5                	j	2f8 <strchr+0x20>

0000000000000302 <gets>:

char*
gets(char *buf, int max)
{
 302:	711d                	addi	sp,sp,-96
 304:	ec86                	sd	ra,88(sp)
 306:	e8a2                	sd	s0,80(sp)
 308:	e4a6                	sd	s1,72(sp)
 30a:	e0ca                	sd	s2,64(sp)
 30c:	fc4e                	sd	s3,56(sp)
 30e:	f852                	sd	s4,48(sp)
 310:	f456                	sd	s5,40(sp)
 312:	f05a                	sd	s6,32(sp)
 314:	ec5e                	sd	s7,24(sp)
 316:	1080                	addi	s0,sp,96
 318:	8baa                	mv	s7,a0
 31a:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 31c:	892a                	mv	s2,a0
 31e:	4981                	li	s3,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 320:	4aa9                	li	s5,10
 322:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 324:	0019849b          	addiw	s1,s3,1
 328:	0344d863          	ble	s4,s1,358 <gets+0x56>
    cc = read(0, &c, 1);
 32c:	4605                	li	a2,1
 32e:	faf40593          	addi	a1,s0,-81
 332:	4501                	li	a0,0
 334:	00000097          	auipc	ra,0x0
 338:	1ac080e7          	jalr	428(ra) # 4e0 <read>
    if(cc < 1)
 33c:	00a05e63          	blez	a0,358 <gets+0x56>
    buf[i++] = c;
 340:	faf44783          	lbu	a5,-81(s0)
 344:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 348:	01578763          	beq	a5,s5,356 <gets+0x54>
 34c:	0905                	addi	s2,s2,1
  for(i=0; i+1 < max; ){
 34e:	89a6                	mv	s3,s1
    if(c == '\n' || c == '\r')
 350:	fd679ae3          	bne	a5,s6,324 <gets+0x22>
 354:	a011                	j	358 <gets+0x56>
  for(i=0; i+1 < max; ){
 356:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 358:	99de                	add	s3,s3,s7
 35a:	00098023          	sb	zero,0(s3)
  return buf;
}
 35e:	855e                	mv	a0,s7
 360:	60e6                	ld	ra,88(sp)
 362:	6446                	ld	s0,80(sp)
 364:	64a6                	ld	s1,72(sp)
 366:	6906                	ld	s2,64(sp)
 368:	79e2                	ld	s3,56(sp)
 36a:	7a42                	ld	s4,48(sp)
 36c:	7aa2                	ld	s5,40(sp)
 36e:	7b02                	ld	s6,32(sp)
 370:	6be2                	ld	s7,24(sp)
 372:	6125                	addi	sp,sp,96
 374:	8082                	ret

0000000000000376 <stat>:

int
stat(const char *n, struct stat *st)
{
 376:	1101                	addi	sp,sp,-32
 378:	ec06                	sd	ra,24(sp)
 37a:	e822                	sd	s0,16(sp)
 37c:	e426                	sd	s1,8(sp)
 37e:	e04a                	sd	s2,0(sp)
 380:	1000                	addi	s0,sp,32
 382:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 384:	4581                	li	a1,0
 386:	00000097          	auipc	ra,0x0
 38a:	182080e7          	jalr	386(ra) # 508 <open>
  if(fd < 0)
 38e:	02054563          	bltz	a0,3b8 <stat+0x42>
 392:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 394:	85ca                	mv	a1,s2
 396:	00000097          	auipc	ra,0x0
 39a:	18a080e7          	jalr	394(ra) # 520 <fstat>
 39e:	892a                	mv	s2,a0
  close(fd);
 3a0:	8526                	mv	a0,s1
 3a2:	00000097          	auipc	ra,0x0
 3a6:	14e080e7          	jalr	334(ra) # 4f0 <close>
  return r;
}
 3aa:	854a                	mv	a0,s2
 3ac:	60e2                	ld	ra,24(sp)
 3ae:	6442                	ld	s0,16(sp)
 3b0:	64a2                	ld	s1,8(sp)
 3b2:	6902                	ld	s2,0(sp)
 3b4:	6105                	addi	sp,sp,32
 3b6:	8082                	ret
    return -1;
 3b8:	597d                	li	s2,-1
 3ba:	bfc5                	j	3aa <stat+0x34>

00000000000003bc <atoi>:

int
atoi(const char *s)
{
 3bc:	1141                	addi	sp,sp,-16
 3be:	e422                	sd	s0,8(sp)
 3c0:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 3c2:	00054683          	lbu	a3,0(a0)
 3c6:	fd06879b          	addiw	a5,a3,-48
 3ca:	0ff7f793          	andi	a5,a5,255
 3ce:	4725                	li	a4,9
 3d0:	02f76963          	bltu	a4,a5,402 <atoi+0x46>
 3d4:	862a                	mv	a2,a0
  n = 0;
 3d6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 3d8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 3da:	0605                	addi	a2,a2,1
 3dc:	0025179b          	slliw	a5,a0,0x2
 3e0:	9fa9                	addw	a5,a5,a0
 3e2:	0017979b          	slliw	a5,a5,0x1
 3e6:	9fb5                	addw	a5,a5,a3
 3e8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 3ec:	00064683          	lbu	a3,0(a2)
 3f0:	fd06871b          	addiw	a4,a3,-48
 3f4:	0ff77713          	andi	a4,a4,255
 3f8:	fee5f1e3          	bleu	a4,a1,3da <atoi+0x1e>
  return n;
}
 3fc:	6422                	ld	s0,8(sp)
 3fe:	0141                	addi	sp,sp,16
 400:	8082                	ret
  n = 0;
 402:	4501                	li	a0,0
 404:	bfe5                	j	3fc <atoi+0x40>

0000000000000406 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 406:	1141                	addi	sp,sp,-16
 408:	e422                	sd	s0,8(sp)
 40a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 40c:	02b57663          	bleu	a1,a0,438 <memmove+0x32>
    while(n-- > 0)
 410:	02c05163          	blez	a2,432 <memmove+0x2c>
 414:	fff6079b          	addiw	a5,a2,-1
 418:	1782                	slli	a5,a5,0x20
 41a:	9381                	srli	a5,a5,0x20
 41c:	0785                	addi	a5,a5,1
 41e:	97aa                	add	a5,a5,a0
  dst = vdst;
 420:	872a                	mv	a4,a0
      *dst++ = *src++;
 422:	0585                	addi	a1,a1,1
 424:	0705                	addi	a4,a4,1
 426:	fff5c683          	lbu	a3,-1(a1)
 42a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 42e:	fee79ae3          	bne	a5,a4,422 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 432:	6422                	ld	s0,8(sp)
 434:	0141                	addi	sp,sp,16
 436:	8082                	ret
    dst += n;
 438:	00c50733          	add	a4,a0,a2
    src += n;
 43c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 43e:	fec05ae3          	blez	a2,432 <memmove+0x2c>
 442:	fff6079b          	addiw	a5,a2,-1
 446:	1782                	slli	a5,a5,0x20
 448:	9381                	srli	a5,a5,0x20
 44a:	fff7c793          	not	a5,a5
 44e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 450:	15fd                	addi	a1,a1,-1
 452:	177d                	addi	a4,a4,-1
 454:	0005c683          	lbu	a3,0(a1)
 458:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 45c:	fef71ae3          	bne	a4,a5,450 <memmove+0x4a>
 460:	bfc9                	j	432 <memmove+0x2c>

0000000000000462 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 462:	1141                	addi	sp,sp,-16
 464:	e422                	sd	s0,8(sp)
 466:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 468:	ce15                	beqz	a2,4a4 <memcmp+0x42>
 46a:	fff6069b          	addiw	a3,a2,-1
    if (*p1 != *p2) {
 46e:	00054783          	lbu	a5,0(a0)
 472:	0005c703          	lbu	a4,0(a1)
 476:	02e79063          	bne	a5,a4,496 <memcmp+0x34>
 47a:	1682                	slli	a3,a3,0x20
 47c:	9281                	srli	a3,a3,0x20
 47e:	0685                	addi	a3,a3,1
 480:	96aa                	add	a3,a3,a0
      return *p1 - *p2;
    }
    p1++;
 482:	0505                	addi	a0,a0,1
    p2++;
 484:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 486:	00d50d63          	beq	a0,a3,4a0 <memcmp+0x3e>
    if (*p1 != *p2) {
 48a:	00054783          	lbu	a5,0(a0)
 48e:	0005c703          	lbu	a4,0(a1)
 492:	fee788e3          	beq	a5,a4,482 <memcmp+0x20>
      return *p1 - *p2;
 496:	40e7853b          	subw	a0,a5,a4
  }
  return 0;
}
 49a:	6422                	ld	s0,8(sp)
 49c:	0141                	addi	sp,sp,16
 49e:	8082                	ret
  return 0;
 4a0:	4501                	li	a0,0
 4a2:	bfe5                	j	49a <memcmp+0x38>
 4a4:	4501                	li	a0,0
 4a6:	bfd5                	j	49a <memcmp+0x38>

00000000000004a8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 4a8:	1141                	addi	sp,sp,-16
 4aa:	e406                	sd	ra,8(sp)
 4ac:	e022                	sd	s0,0(sp)
 4ae:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 4b0:	00000097          	auipc	ra,0x0
 4b4:	f56080e7          	jalr	-170(ra) # 406 <memmove>
}
 4b8:	60a2                	ld	ra,8(sp)
 4ba:	6402                	ld	s0,0(sp)
 4bc:	0141                	addi	sp,sp,16
 4be:	8082                	ret

00000000000004c0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 4c0:	4885                	li	a7,1
 ecall
 4c2:	00000073          	ecall
 ret
 4c6:	8082                	ret

00000000000004c8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 4c8:	4889                	li	a7,2
 ecall
 4ca:	00000073          	ecall
 ret
 4ce:	8082                	ret

00000000000004d0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 4d0:	488d                	li	a7,3
 ecall
 4d2:	00000073          	ecall
 ret
 4d6:	8082                	ret

00000000000004d8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 4d8:	4891                	li	a7,4
 ecall
 4da:	00000073          	ecall
 ret
 4de:	8082                	ret

00000000000004e0 <read>:
.global read
read:
 li a7, SYS_read
 4e0:	4895                	li	a7,5
 ecall
 4e2:	00000073          	ecall
 ret
 4e6:	8082                	ret

00000000000004e8 <write>:
.global write
write:
 li a7, SYS_write
 4e8:	48c1                	li	a7,16
 ecall
 4ea:	00000073          	ecall
 ret
 4ee:	8082                	ret

00000000000004f0 <close>:
.global close
close:
 li a7, SYS_close
 4f0:	48d5                	li	a7,21
 ecall
 4f2:	00000073          	ecall
 ret
 4f6:	8082                	ret

00000000000004f8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 4f8:	4899                	li	a7,6
 ecall
 4fa:	00000073          	ecall
 ret
 4fe:	8082                	ret

0000000000000500 <exec>:
.global exec
exec:
 li a7, SYS_exec
 500:	489d                	li	a7,7
 ecall
 502:	00000073          	ecall
 ret
 506:	8082                	ret

0000000000000508 <open>:
.global open
open:
 li a7, SYS_open
 508:	48bd                	li	a7,15
 ecall
 50a:	00000073          	ecall
 ret
 50e:	8082                	ret

0000000000000510 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 510:	48c5                	li	a7,17
 ecall
 512:	00000073          	ecall
 ret
 516:	8082                	ret

0000000000000518 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 518:	48c9                	li	a7,18
 ecall
 51a:	00000073          	ecall
 ret
 51e:	8082                	ret

0000000000000520 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 520:	48a1                	li	a7,8
 ecall
 522:	00000073          	ecall
 ret
 526:	8082                	ret

0000000000000528 <link>:
.global link
link:
 li a7, SYS_link
 528:	48cd                	li	a7,19
 ecall
 52a:	00000073          	ecall
 ret
 52e:	8082                	ret

0000000000000530 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 530:	48d1                	li	a7,20
 ecall
 532:	00000073          	ecall
 ret
 536:	8082                	ret

0000000000000538 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 538:	48a5                	li	a7,9
 ecall
 53a:	00000073          	ecall
 ret
 53e:	8082                	ret

0000000000000540 <dup>:
.global dup
dup:
 li a7, SYS_dup
 540:	48a9                	li	a7,10
 ecall
 542:	00000073          	ecall
 ret
 546:	8082                	ret

0000000000000548 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 548:	48ad                	li	a7,11
 ecall
 54a:	00000073          	ecall
 ret
 54e:	8082                	ret

0000000000000550 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 550:	48b1                	li	a7,12
 ecall
 552:	00000073          	ecall
 ret
 556:	8082                	ret

0000000000000558 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 558:	48b5                	li	a7,13
 ecall
 55a:	00000073          	ecall
 ret
 55e:	8082                	ret

0000000000000560 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 560:	48b9                	li	a7,14
 ecall
 562:	00000073          	ecall
 ret
 566:	8082                	ret

0000000000000568 <trace>:
.global trace
trace:
 li a7, SYS_trace
 568:	48d9                	li	a7,22
 ecall
 56a:	00000073          	ecall
 ret
 56e:	8082                	ret

0000000000000570 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 570:	1101                	addi	sp,sp,-32
 572:	ec06                	sd	ra,24(sp)
 574:	e822                	sd	s0,16(sp)
 576:	1000                	addi	s0,sp,32
 578:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 57c:	4605                	li	a2,1
 57e:	fef40593          	addi	a1,s0,-17
 582:	00000097          	auipc	ra,0x0
 586:	f66080e7          	jalr	-154(ra) # 4e8 <write>
}
 58a:	60e2                	ld	ra,24(sp)
 58c:	6442                	ld	s0,16(sp)
 58e:	6105                	addi	sp,sp,32
 590:	8082                	ret

0000000000000592 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 592:	7139                	addi	sp,sp,-64
 594:	fc06                	sd	ra,56(sp)
 596:	f822                	sd	s0,48(sp)
 598:	f426                	sd	s1,40(sp)
 59a:	f04a                	sd	s2,32(sp)
 59c:	ec4e                	sd	s3,24(sp)
 59e:	0080                	addi	s0,sp,64
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 5a0:	c299                	beqz	a3,5a6 <printint+0x14>
 5a2:	0005cd63          	bltz	a1,5bc <printint+0x2a>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 5a6:	2581                	sext.w	a1,a1
  neg = 0;
 5a8:	4301                	li	t1,0
 5aa:	fc040713          	addi	a4,s0,-64
  }

  i = 0;
 5ae:	4801                	li	a6,0
  do{
    buf[i++] = digits[x % base];
 5b0:	2601                	sext.w	a2,a2
 5b2:	00000897          	auipc	a7,0x0
 5b6:	4b688893          	addi	a7,a7,1206 # a68 <digits>
 5ba:	a801                	j	5ca <printint+0x38>
    x = -xx;
 5bc:	40b005bb          	negw	a1,a1
 5c0:	2581                	sext.w	a1,a1
    neg = 1;
 5c2:	4305                	li	t1,1
    x = -xx;
 5c4:	b7dd                	j	5aa <printint+0x18>
  }while((x /= base) != 0);
 5c6:	85be                	mv	a1,a5
    buf[i++] = digits[x % base];
 5c8:	8836                	mv	a6,a3
 5ca:	0018069b          	addiw	a3,a6,1
 5ce:	02c5f7bb          	remuw	a5,a1,a2
 5d2:	1782                	slli	a5,a5,0x20
 5d4:	9381                	srli	a5,a5,0x20
 5d6:	97c6                	add	a5,a5,a7
 5d8:	0007c783          	lbu	a5,0(a5)
 5dc:	00f70023          	sb	a5,0(a4)
  }while((x /= base) != 0);
 5e0:	0705                	addi	a4,a4,1
 5e2:	02c5d7bb          	divuw	a5,a1,a2
 5e6:	fec5f0e3          	bleu	a2,a1,5c6 <printint+0x34>
  if(neg)
 5ea:	00030b63          	beqz	t1,600 <printint+0x6e>
    buf[i++] = '-';
 5ee:	fd040793          	addi	a5,s0,-48
 5f2:	96be                	add	a3,a3,a5
 5f4:	02d00793          	li	a5,45
 5f8:	fef68823          	sb	a5,-16(a3)
 5fc:	0028069b          	addiw	a3,a6,2

  while(--i >= 0)
 600:	02d05963          	blez	a3,632 <printint+0xa0>
 604:	89aa                	mv	s3,a0
 606:	fc040793          	addi	a5,s0,-64
 60a:	00d784b3          	add	s1,a5,a3
 60e:	fff78913          	addi	s2,a5,-1
 612:	9936                	add	s2,s2,a3
 614:	36fd                	addiw	a3,a3,-1
 616:	1682                	slli	a3,a3,0x20
 618:	9281                	srli	a3,a3,0x20
 61a:	40d90933          	sub	s2,s2,a3
    putc(fd, buf[i]);
 61e:	fff4c583          	lbu	a1,-1(s1)
 622:	854e                	mv	a0,s3
 624:	00000097          	auipc	ra,0x0
 628:	f4c080e7          	jalr	-180(ra) # 570 <putc>
  while(--i >= 0)
 62c:	14fd                	addi	s1,s1,-1
 62e:	ff2498e3          	bne	s1,s2,61e <printint+0x8c>
}
 632:	70e2                	ld	ra,56(sp)
 634:	7442                	ld	s0,48(sp)
 636:	74a2                	ld	s1,40(sp)
 638:	7902                	ld	s2,32(sp)
 63a:	69e2                	ld	s3,24(sp)
 63c:	6121                	addi	sp,sp,64
 63e:	8082                	ret

0000000000000640 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 640:	7119                	addi	sp,sp,-128
 642:	fc86                	sd	ra,120(sp)
 644:	f8a2                	sd	s0,112(sp)
 646:	f4a6                	sd	s1,104(sp)
 648:	f0ca                	sd	s2,96(sp)
 64a:	ecce                	sd	s3,88(sp)
 64c:	e8d2                	sd	s4,80(sp)
 64e:	e4d6                	sd	s5,72(sp)
 650:	e0da                	sd	s6,64(sp)
 652:	fc5e                	sd	s7,56(sp)
 654:	f862                	sd	s8,48(sp)
 656:	f466                	sd	s9,40(sp)
 658:	f06a                	sd	s10,32(sp)
 65a:	ec6e                	sd	s11,24(sp)
 65c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 65e:	0005c483          	lbu	s1,0(a1)
 662:	18048d63          	beqz	s1,7fc <vprintf+0x1bc>
 666:	8aaa                	mv	s5,a0
 668:	8b32                	mv	s6,a2
 66a:	00158913          	addi	s2,a1,1
  state = 0;
 66e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 670:	02500a13          	li	s4,37
      if(c == 'd'){
 674:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 678:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 67c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 680:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 684:	00000b97          	auipc	s7,0x0
 688:	3e4b8b93          	addi	s7,s7,996 # a68 <digits>
 68c:	a839                	j	6aa <vprintf+0x6a>
        putc(fd, c);
 68e:	85a6                	mv	a1,s1
 690:	8556                	mv	a0,s5
 692:	00000097          	auipc	ra,0x0
 696:	ede080e7          	jalr	-290(ra) # 570 <putc>
 69a:	a019                	j	6a0 <vprintf+0x60>
    } else if(state == '%'){
 69c:	01498f63          	beq	s3,s4,6ba <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 6a0:	0905                	addi	s2,s2,1
 6a2:	fff94483          	lbu	s1,-1(s2)
 6a6:	14048b63          	beqz	s1,7fc <vprintf+0x1bc>
    c = fmt[i] & 0xff;
 6aa:	0004879b          	sext.w	a5,s1
    if(state == 0){
 6ae:	fe0997e3          	bnez	s3,69c <vprintf+0x5c>
      if(c == '%'){
 6b2:	fd479ee3          	bne	a5,s4,68e <vprintf+0x4e>
        state = '%';
 6b6:	89be                	mv	s3,a5
 6b8:	b7e5                	j	6a0 <vprintf+0x60>
      if(c == 'd'){
 6ba:	05878063          	beq	a5,s8,6fa <vprintf+0xba>
      } else if(c == 'l') {
 6be:	05978c63          	beq	a5,s9,716 <vprintf+0xd6>
      } else if(c == 'x') {
 6c2:	07a78863          	beq	a5,s10,732 <vprintf+0xf2>
      } else if(c == 'p') {
 6c6:	09b78463          	beq	a5,s11,74e <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 6ca:	07300713          	li	a4,115
 6ce:	0ce78563          	beq	a5,a4,798 <vprintf+0x158>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 6d2:	06300713          	li	a4,99
 6d6:	0ee78c63          	beq	a5,a4,7ce <vprintf+0x18e>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 6da:	11478663          	beq	a5,s4,7e6 <vprintf+0x1a6>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 6de:	85d2                	mv	a1,s4
 6e0:	8556                	mv	a0,s5
 6e2:	00000097          	auipc	ra,0x0
 6e6:	e8e080e7          	jalr	-370(ra) # 570 <putc>
        putc(fd, c);
 6ea:	85a6                	mv	a1,s1
 6ec:	8556                	mv	a0,s5
 6ee:	00000097          	auipc	ra,0x0
 6f2:	e82080e7          	jalr	-382(ra) # 570 <putc>
      }
      state = 0;
 6f6:	4981                	li	s3,0
 6f8:	b765                	j	6a0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 6fa:	008b0493          	addi	s1,s6,8
 6fe:	4685                	li	a3,1
 700:	4629                	li	a2,10
 702:	000b2583          	lw	a1,0(s6)
 706:	8556                	mv	a0,s5
 708:	00000097          	auipc	ra,0x0
 70c:	e8a080e7          	jalr	-374(ra) # 592 <printint>
 710:	8b26                	mv	s6,s1
      state = 0;
 712:	4981                	li	s3,0
 714:	b771                	j	6a0 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 716:	008b0493          	addi	s1,s6,8
 71a:	4681                	li	a3,0
 71c:	4629                	li	a2,10
 71e:	000b2583          	lw	a1,0(s6)
 722:	8556                	mv	a0,s5
 724:	00000097          	auipc	ra,0x0
 728:	e6e080e7          	jalr	-402(ra) # 592 <printint>
 72c:	8b26                	mv	s6,s1
      state = 0;
 72e:	4981                	li	s3,0
 730:	bf85                	j	6a0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 732:	008b0493          	addi	s1,s6,8
 736:	4681                	li	a3,0
 738:	4641                	li	a2,16
 73a:	000b2583          	lw	a1,0(s6)
 73e:	8556                	mv	a0,s5
 740:	00000097          	auipc	ra,0x0
 744:	e52080e7          	jalr	-430(ra) # 592 <printint>
 748:	8b26                	mv	s6,s1
      state = 0;
 74a:	4981                	li	s3,0
 74c:	bf91                	j	6a0 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 74e:	008b0793          	addi	a5,s6,8
 752:	f8f43423          	sd	a5,-120(s0)
 756:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 75a:	03000593          	li	a1,48
 75e:	8556                	mv	a0,s5
 760:	00000097          	auipc	ra,0x0
 764:	e10080e7          	jalr	-496(ra) # 570 <putc>
  putc(fd, 'x');
 768:	85ea                	mv	a1,s10
 76a:	8556                	mv	a0,s5
 76c:	00000097          	auipc	ra,0x0
 770:	e04080e7          	jalr	-508(ra) # 570 <putc>
 774:	44c1                	li	s1,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 776:	03c9d793          	srli	a5,s3,0x3c
 77a:	97de                	add	a5,a5,s7
 77c:	0007c583          	lbu	a1,0(a5)
 780:	8556                	mv	a0,s5
 782:	00000097          	auipc	ra,0x0
 786:	dee080e7          	jalr	-530(ra) # 570 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 78a:	0992                	slli	s3,s3,0x4
 78c:	34fd                	addiw	s1,s1,-1
 78e:	f4e5                	bnez	s1,776 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 790:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 794:	4981                	li	s3,0
 796:	b729                	j	6a0 <vprintf+0x60>
        s = va_arg(ap, char*);
 798:	008b0993          	addi	s3,s6,8
 79c:	000b3483          	ld	s1,0(s6)
        if(s == 0)
 7a0:	c085                	beqz	s1,7c0 <vprintf+0x180>
        while(*s != 0){
 7a2:	0004c583          	lbu	a1,0(s1)
 7a6:	c9a1                	beqz	a1,7f6 <vprintf+0x1b6>
          putc(fd, *s);
 7a8:	8556                	mv	a0,s5
 7aa:	00000097          	auipc	ra,0x0
 7ae:	dc6080e7          	jalr	-570(ra) # 570 <putc>
          s++;
 7b2:	0485                	addi	s1,s1,1
        while(*s != 0){
 7b4:	0004c583          	lbu	a1,0(s1)
 7b8:	f9e5                	bnez	a1,7a8 <vprintf+0x168>
        s = va_arg(ap, char*);
 7ba:	8b4e                	mv	s6,s3
      state = 0;
 7bc:	4981                	li	s3,0
 7be:	b5cd                	j	6a0 <vprintf+0x60>
          s = "(null)";
 7c0:	00000497          	auipc	s1,0x0
 7c4:	2c048493          	addi	s1,s1,704 # a80 <digits+0x18>
        while(*s != 0){
 7c8:	02800593          	li	a1,40
 7cc:	bff1                	j	7a8 <vprintf+0x168>
        putc(fd, va_arg(ap, uint));
 7ce:	008b0493          	addi	s1,s6,8
 7d2:	000b4583          	lbu	a1,0(s6)
 7d6:	8556                	mv	a0,s5
 7d8:	00000097          	auipc	ra,0x0
 7dc:	d98080e7          	jalr	-616(ra) # 570 <putc>
 7e0:	8b26                	mv	s6,s1
      state = 0;
 7e2:	4981                	li	s3,0
 7e4:	bd75                	j	6a0 <vprintf+0x60>
        putc(fd, c);
 7e6:	85d2                	mv	a1,s4
 7e8:	8556                	mv	a0,s5
 7ea:	00000097          	auipc	ra,0x0
 7ee:	d86080e7          	jalr	-634(ra) # 570 <putc>
      state = 0;
 7f2:	4981                	li	s3,0
 7f4:	b575                	j	6a0 <vprintf+0x60>
        s = va_arg(ap, char*);
 7f6:	8b4e                	mv	s6,s3
      state = 0;
 7f8:	4981                	li	s3,0
 7fa:	b55d                	j	6a0 <vprintf+0x60>
    }
  }
}
 7fc:	70e6                	ld	ra,120(sp)
 7fe:	7446                	ld	s0,112(sp)
 800:	74a6                	ld	s1,104(sp)
 802:	7906                	ld	s2,96(sp)
 804:	69e6                	ld	s3,88(sp)
 806:	6a46                	ld	s4,80(sp)
 808:	6aa6                	ld	s5,72(sp)
 80a:	6b06                	ld	s6,64(sp)
 80c:	7be2                	ld	s7,56(sp)
 80e:	7c42                	ld	s8,48(sp)
 810:	7ca2                	ld	s9,40(sp)
 812:	7d02                	ld	s10,32(sp)
 814:	6de2                	ld	s11,24(sp)
 816:	6109                	addi	sp,sp,128
 818:	8082                	ret

000000000000081a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 81a:	715d                	addi	sp,sp,-80
 81c:	ec06                	sd	ra,24(sp)
 81e:	e822                	sd	s0,16(sp)
 820:	1000                	addi	s0,sp,32
 822:	e010                	sd	a2,0(s0)
 824:	e414                	sd	a3,8(s0)
 826:	e818                	sd	a4,16(s0)
 828:	ec1c                	sd	a5,24(s0)
 82a:	03043023          	sd	a6,32(s0)
 82e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 832:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 836:	8622                	mv	a2,s0
 838:	00000097          	auipc	ra,0x0
 83c:	e08080e7          	jalr	-504(ra) # 640 <vprintf>
}
 840:	60e2                	ld	ra,24(sp)
 842:	6442                	ld	s0,16(sp)
 844:	6161                	addi	sp,sp,80
 846:	8082                	ret

0000000000000848 <printf>:

void
printf(const char *fmt, ...)
{
 848:	711d                	addi	sp,sp,-96
 84a:	ec06                	sd	ra,24(sp)
 84c:	e822                	sd	s0,16(sp)
 84e:	1000                	addi	s0,sp,32
 850:	e40c                	sd	a1,8(s0)
 852:	e810                	sd	a2,16(s0)
 854:	ec14                	sd	a3,24(s0)
 856:	f018                	sd	a4,32(s0)
 858:	f41c                	sd	a5,40(s0)
 85a:	03043823          	sd	a6,48(s0)
 85e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 862:	00840613          	addi	a2,s0,8
 866:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 86a:	85aa                	mv	a1,a0
 86c:	4505                	li	a0,1
 86e:	00000097          	auipc	ra,0x0
 872:	dd2080e7          	jalr	-558(ra) # 640 <vprintf>
}
 876:	60e2                	ld	ra,24(sp)
 878:	6442                	ld	s0,16(sp)
 87a:	6125                	addi	sp,sp,96
 87c:	8082                	ret

000000000000087e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 87e:	1141                	addi	sp,sp,-16
 880:	e422                	sd	s0,8(sp)
 882:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 884:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 888:	00000797          	auipc	a5,0x0
 88c:	20078793          	addi	a5,a5,512 # a88 <__bss_start>
 890:	639c                	ld	a5,0(a5)
 892:	a805                	j	8c2 <free+0x44>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 894:	4618                	lw	a4,8(a2)
 896:	9db9                	addw	a1,a1,a4
 898:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 89c:	6398                	ld	a4,0(a5)
 89e:	6318                	ld	a4,0(a4)
 8a0:	fee53823          	sd	a4,-16(a0)
 8a4:	a091                	j	8e8 <free+0x6a>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 8a6:	ff852703          	lw	a4,-8(a0)
 8aa:	9e39                	addw	a2,a2,a4
 8ac:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 8ae:	ff053703          	ld	a4,-16(a0)
 8b2:	e398                	sd	a4,0(a5)
 8b4:	a099                	j	8fa <free+0x7c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8b6:	6398                	ld	a4,0(a5)
 8b8:	00e7e463          	bltu	a5,a4,8c0 <free+0x42>
 8bc:	00e6ea63          	bltu	a3,a4,8d0 <free+0x52>
{
 8c0:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8c2:	fed7fae3          	bleu	a3,a5,8b6 <free+0x38>
 8c6:	6398                	ld	a4,0(a5)
 8c8:	00e6e463          	bltu	a3,a4,8d0 <free+0x52>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8cc:	fee7eae3          	bltu	a5,a4,8c0 <free+0x42>
  if(bp + bp->s.size == p->s.ptr){
 8d0:	ff852583          	lw	a1,-8(a0)
 8d4:	6390                	ld	a2,0(a5)
 8d6:	02059713          	slli	a4,a1,0x20
 8da:	9301                	srli	a4,a4,0x20
 8dc:	0712                	slli	a4,a4,0x4
 8de:	9736                	add	a4,a4,a3
 8e0:	fae60ae3          	beq	a2,a4,894 <free+0x16>
    bp->s.ptr = p->s.ptr;
 8e4:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 8e8:	4790                	lw	a2,8(a5)
 8ea:	02061713          	slli	a4,a2,0x20
 8ee:	9301                	srli	a4,a4,0x20
 8f0:	0712                	slli	a4,a4,0x4
 8f2:	973e                	add	a4,a4,a5
 8f4:	fae689e3          	beq	a3,a4,8a6 <free+0x28>
  } else
    p->s.ptr = bp;
 8f8:	e394                	sd	a3,0(a5)
  freep = p;
 8fa:	00000717          	auipc	a4,0x0
 8fe:	18f73723          	sd	a5,398(a4) # a88 <__bss_start>
}
 902:	6422                	ld	s0,8(sp)
 904:	0141                	addi	sp,sp,16
 906:	8082                	ret

0000000000000908 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 908:	7139                	addi	sp,sp,-64
 90a:	fc06                	sd	ra,56(sp)
 90c:	f822                	sd	s0,48(sp)
 90e:	f426                	sd	s1,40(sp)
 910:	f04a                	sd	s2,32(sp)
 912:	ec4e                	sd	s3,24(sp)
 914:	e852                	sd	s4,16(sp)
 916:	e456                	sd	s5,8(sp)
 918:	e05a                	sd	s6,0(sp)
 91a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 91c:	02051993          	slli	s3,a0,0x20
 920:	0209d993          	srli	s3,s3,0x20
 924:	09bd                	addi	s3,s3,15
 926:	0049d993          	srli	s3,s3,0x4
 92a:	2985                	addiw	s3,s3,1
 92c:	0009891b          	sext.w	s2,s3
  if((prevp = freep) == 0){
 930:	00000797          	auipc	a5,0x0
 934:	15878793          	addi	a5,a5,344 # a88 <__bss_start>
 938:	6388                	ld	a0,0(a5)
 93a:	c515                	beqz	a0,966 <malloc+0x5e>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 93c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 93e:	4798                	lw	a4,8(a5)
 940:	03277f63          	bleu	s2,a4,97e <malloc+0x76>
 944:	8a4e                	mv	s4,s3
 946:	0009871b          	sext.w	a4,s3
 94a:	6685                	lui	a3,0x1
 94c:	00d77363          	bleu	a3,a4,952 <malloc+0x4a>
 950:	6a05                	lui	s4,0x1
 952:	000a0a9b          	sext.w	s5,s4
  p = sbrk(nu * sizeof(Header));
 956:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 95a:	00000497          	auipc	s1,0x0
 95e:	12e48493          	addi	s1,s1,302 # a88 <__bss_start>
  if(p == (char*)-1)
 962:	5b7d                	li	s6,-1
 964:	a885                	j	9d4 <malloc+0xcc>
    base.s.ptr = freep = prevp = &base;
 966:	00000797          	auipc	a5,0x0
 96a:	12a78793          	addi	a5,a5,298 # a90 <base>
 96e:	00000717          	auipc	a4,0x0
 972:	10f73d23          	sd	a5,282(a4) # a88 <__bss_start>
 976:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 978:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 97c:	b7e1                	j	944 <malloc+0x3c>
      if(p->s.size == nunits)
 97e:	02e90b63          	beq	s2,a4,9b4 <malloc+0xac>
        p->s.size -= nunits;
 982:	4137073b          	subw	a4,a4,s3
 986:	c798                	sw	a4,8(a5)
        p += p->s.size;
 988:	1702                	slli	a4,a4,0x20
 98a:	9301                	srli	a4,a4,0x20
 98c:	0712                	slli	a4,a4,0x4
 98e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 990:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 994:	00000717          	auipc	a4,0x0
 998:	0ea73a23          	sd	a0,244(a4) # a88 <__bss_start>
      return (void*)(p + 1);
 99c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 9a0:	70e2                	ld	ra,56(sp)
 9a2:	7442                	ld	s0,48(sp)
 9a4:	74a2                	ld	s1,40(sp)
 9a6:	7902                	ld	s2,32(sp)
 9a8:	69e2                	ld	s3,24(sp)
 9aa:	6a42                	ld	s4,16(sp)
 9ac:	6aa2                	ld	s5,8(sp)
 9ae:	6b02                	ld	s6,0(sp)
 9b0:	6121                	addi	sp,sp,64
 9b2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 9b4:	6398                	ld	a4,0(a5)
 9b6:	e118                	sd	a4,0(a0)
 9b8:	bff1                	j	994 <malloc+0x8c>
  hp->s.size = nu;
 9ba:	01552423          	sw	s5,8(a0)
  free((void*)(hp + 1));
 9be:	0541                	addi	a0,a0,16
 9c0:	00000097          	auipc	ra,0x0
 9c4:	ebe080e7          	jalr	-322(ra) # 87e <free>
  return freep;
 9c8:	6088                	ld	a0,0(s1)
      if((p = morecore(nunits)) == 0)
 9ca:	d979                	beqz	a0,9a0 <malloc+0x98>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 9cc:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 9ce:	4798                	lw	a4,8(a5)
 9d0:	fb2777e3          	bleu	s2,a4,97e <malloc+0x76>
    if(p == freep)
 9d4:	6098                	ld	a4,0(s1)
 9d6:	853e                	mv	a0,a5
 9d8:	fef71ae3          	bne	a4,a5,9cc <malloc+0xc4>
  p = sbrk(nu * sizeof(Header));
 9dc:	8552                	mv	a0,s4
 9de:	00000097          	auipc	ra,0x0
 9e2:	b72080e7          	jalr	-1166(ra) # 550 <sbrk>
  if(p == (char*)-1)
 9e6:	fd651ae3          	bne	a0,s6,9ba <malloc+0xb2>
        return 0;
 9ea:	4501                	li	a0,0
 9ec:	bf55                	j	9a0 <malloc+0x98>
