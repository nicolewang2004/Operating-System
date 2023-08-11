
user/_uthread：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <thread_init>:
struct thread *current_thread;
extern void thread_switch(uint64, uint64);
              
void 
thread_init(void)
{
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
  // again, because its state is set to RUNNING, and thread_schedule() selects
  // a RUNNABLE thread.

  // 增加初始化context的内容  
  for (int i = 0; i < MAX_THREAD; i++) {
    all_thread[i].context = &all_context[i];
   6:	00003797          	auipc	a5,0x3
   a:	fba78793          	addi	a5,a5,-70 # 2fc0 <__global_pointer$+0x19e8>
   e:	00001717          	auipc	a4,0x1
  12:	df270713          	addi	a4,a4,-526 # e00 <all_context>
  16:	e798                	sd	a4,8(a5)
  18:	00001717          	auipc	a4,0x1
  1c:	e5870713          	addi	a4,a4,-424 # e70 <all_context+0x70>
  20:	00005697          	auipc	a3,0x5
  24:	fae6bc23          	sd	a4,-72(a3) # 4fd8 <__global_pointer$+0x3a00>
  28:	00001717          	auipc	a4,0x1
  2c:	eb870713          	addi	a4,a4,-328 # ee0 <all_context+0xe0>
  30:	00007697          	auipc	a3,0x7
  34:	fae6bc23          	sd	a4,-72(a3) # 6fe8 <__global_pointer$+0x5a10>
  38:	00001717          	auipc	a4,0x1
  3c:	f1870713          	addi	a4,a4,-232 # f50 <all_context+0x150>
  40:	00009697          	auipc	a3,0x9
  44:	fae6bc23          	sd	a4,-72(a3) # 8ff8 <__global_pointer$+0x7a20>
  }

  current_thread = &all_thread[0];
  48:	00001717          	auipc	a4,0x1
  4c:	f7870713          	addi	a4,a4,-136 # fc0 <all_thread>
  50:	00001697          	auipc	a3,0x1
  54:	dae6b023          	sd	a4,-608(a3) # df0 <current_thread>
  current_thread->state = RUNNING;
  58:	4705                	li	a4,1
  5a:	c398                	sw	a4,0(a5)
}
  5c:	6422                	ld	s0,8(sp)
  5e:	0141                	addi	sp,sp,16
  60:	8082                	ret

0000000000000062 <thread_schedule>:

void 
thread_schedule(void)
{
  62:	1141                	addi	sp,sp,-16
  64:	e406                	sd	ra,8(sp)
  66:	e022                	sd	s0,0(sp)
  68:	0800                	addi	s0,sp,16
  struct thread *t, *next_thread;

  /* Find another runnable thread. */
  next_thread = 0;
  t = current_thread + 1;
  6a:	00001797          	auipc	a5,0x1
  6e:	d8678793          	addi	a5,a5,-634 # df0 <current_thread>
  72:	638c                	ld	a1,0(a5)
  74:	6789                	lui	a5,0x2
  76:	07c1                	addi	a5,a5,16
  78:	97ae                	add	a5,a5,a1
  7a:	4711                	li	a4,4
  for(int i = 0; i < MAX_THREAD; i++){
    if(t >= all_thread + MAX_THREAD)
  7c:	00009817          	auipc	a6,0x9
  80:	f8480813          	addi	a6,a6,-124 # 9000 <base>
      t = all_thread;
    if(t->state == RUNNABLE) {
  84:	6609                	lui	a2,0x2
  86:	4509                	li	a0,2
      next_thread = t;
      break;
    }
    t = t + 1;
  88:	01060893          	addi	a7,a2,16 # 2010 <__global_pointer$+0xa38>
  8c:	a809                	j	9e <thread_schedule+0x3c>
    if(t->state == RUNNABLE) {
  8e:	00c786b3          	add	a3,a5,a2
  92:	4294                	lw	a3,0(a3)
  94:	02a68963          	beq	a3,a0,c6 <thread_schedule+0x64>
    t = t + 1;
  98:	97c6                	add	a5,a5,a7
  for(int i = 0; i < MAX_THREAD; i++){
  9a:	377d                	addiw	a4,a4,-1
  9c:	cb01                	beqz	a4,ac <thread_schedule+0x4a>
    if(t >= all_thread + MAX_THREAD)
  9e:	ff07e8e3          	bltu	a5,a6,8e <thread_schedule+0x2c>
      t = all_thread;
  a2:	00001797          	auipc	a5,0x1
  a6:	f1e78793          	addi	a5,a5,-226 # fc0 <all_thread>
  aa:	b7d5                	j	8e <thread_schedule+0x2c>
  }

  if (next_thread == 0) {
    printf("thread_schedule: no runnable threads\n");
  ac:	00001517          	auipc	a0,0x1
  b0:	c0c50513          	addi	a0,a0,-1012 # cb8 <malloc+0xe8>
  b4:	00001097          	auipc	ra,0x1
  b8:	a5c080e7          	jalr	-1444(ra) # b10 <printf>
    exit(-1);
  bc:	557d                	li	a0,-1
  be:	00000097          	auipc	ra,0x0
  c2:	6da080e7          	jalr	1754(ra) # 798 <exit>
  }

  if (current_thread != next_thread) {         /* switch threads?  */
  c6:	02f58363          	beq	a1,a5,ec <thread_schedule+0x8a>
    next_thread->state = RUNNING;
  ca:	6689                	lui	a3,0x2
  cc:	00d78733          	add	a4,a5,a3
  d0:	4605                	li	a2,1
  d2:	c310                	sw	a2,0(a4)
    t = current_thread;
    current_thread = next_thread;
  d4:	00001617          	auipc	a2,0x1
  d8:	d0f63e23          	sd	a5,-740(a2) # df0 <current_thread>
     * Invoke thread_switch to switch from t to next_thread:
     * thread_switch(??, ??);
     */

// +++++ begin +++++++
    thread_switch((uint64)(t->context), (uint64)(next_thread->context));
  dc:	00d587b3          	add	a5,a1,a3
  e0:	670c                	ld	a1,8(a4)
  e2:	6788                	ld	a0,8(a5)
  e4:	00000097          	auipc	ra,0x0
  e8:	3ba080e7          	jalr	954(ra) # 49e <thread_switch>
      // ------ end ----------

  } else
    next_thread = 0;
}
  ec:	60a2                	ld	ra,8(sp)
  ee:	6402                	ld	s0,0(sp)
  f0:	0141                	addi	sp,sp,16
  f2:	8082                	ret

00000000000000f4 <thread_create>:

void 
thread_create(void (*func)())
{
  f4:	7179                	addi	sp,sp,-48
  f6:	f406                	sd	ra,40(sp)
  f8:	f022                	sd	s0,32(sp)
  fa:	ec26                	sd	s1,24(sp)
  fc:	e84a                	sd	s2,16(sp)
  fe:	e44e                	sd	s3,8(sp)
 100:	e052                	sd	s4,0(sp)
 102:	1800                	addi	s0,sp,48
 104:	8a2a                	mv	s4,a0
  struct thread *t;

  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
    if (t->state == FREE) break;
 106:	00003797          	auipc	a5,0x3
 10a:	eba78793          	addi	a5,a5,-326 # 2fc0 <__global_pointer$+0x19e8>
 10e:	439c                	lw	a5,0(a5)
 110:	c3ad                	beqz	a5,172 <thread_create+0x7e>
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
 112:	00003497          	auipc	s1,0x3
 116:	ebe48493          	addi	s1,s1,-322 # 2fd0 <__global_pointer$+0x19f8>
    if (t->state == FREE) break;
 11a:	6709                	lui	a4,0x2
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
 11c:	01070613          	addi	a2,a4,16 # 2010 <__global_pointer$+0xa38>
 120:	00009697          	auipc	a3,0x9
 124:	ee068693          	addi	a3,a3,-288 # 9000 <base>
    if (t->state == FREE) break;
 128:	00e487b3          	add	a5,s1,a4
 12c:	439c                	lw	a5,0(a5)
 12e:	c781                	beqz	a5,136 <thread_create+0x42>
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
 130:	94b2                	add	s1,s1,a2
 132:	fed49be3          	bne	s1,a3,128 <thread_create+0x34>
  }
  t->state = RUNNABLE;
 136:	6909                	lui	s2,0x2
 138:	012489b3          	add	s3,s1,s2
 13c:	4789                	li	a5,2
 13e:	00f9a023          	sw	a5,0(s3)
  // YOUR CODE HERE

  memset(t->stack, 0, sizeof(char) * MAX_THREAD);
 142:	4611                	li	a2,4
 144:	4581                	li	a1,0
 146:	8526                	mv	a0,s1
 148:	00000097          	auipc	ra,0x0
 14c:	43a080e7          	jalr	1082(ra) # 582 <memset>
  t->context->ra = (uint64)(*func);
 150:	0089b783          	ld	a5,8(s3)
 154:	0147b023          	sd	s4,0(a5)
  // 注意栈的方向，否则会导致数据错乱  
  t->context->sp = (uint64)(&(t->stack[STACK_SIZE - 1]));
 158:	0089b783          	ld	a5,8(s3)
 15c:	197d                	addi	s2,s2,-1
 15e:	94ca                	add	s1,s1,s2
 160:	e784                	sd	s1,8(a5)
}
 162:	70a2                	ld	ra,40(sp)
 164:	7402                	ld	s0,32(sp)
 166:	64e2                	ld	s1,24(sp)
 168:	6942                	ld	s2,16(sp)
 16a:	69a2                	ld	s3,8(sp)
 16c:	6a02                	ld	s4,0(sp)
 16e:	6145                	addi	sp,sp,48
 170:	8082                	ret
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
 172:	00001497          	auipc	s1,0x1
 176:	e4e48493          	addi	s1,s1,-434 # fc0 <all_thread>
 17a:	bf75                	j	136 <thread_create+0x42>

000000000000017c <thread_yield>:

void 
thread_yield(void)
{
 17c:	1141                	addi	sp,sp,-16
 17e:	e406                	sd	ra,8(sp)
 180:	e022                	sd	s0,0(sp)
 182:	0800                	addi	s0,sp,16
  current_thread->state = RUNNABLE;
 184:	00001797          	auipc	a5,0x1
 188:	c6c78793          	addi	a5,a5,-916 # df0 <current_thread>
 18c:	639c                	ld	a5,0(a5)
 18e:	6709                	lui	a4,0x2
 190:	97ba                	add	a5,a5,a4
 192:	4709                	li	a4,2
 194:	c398                	sw	a4,0(a5)
  thread_schedule();
 196:	00000097          	auipc	ra,0x0
 19a:	ecc080e7          	jalr	-308(ra) # 62 <thread_schedule>
}
 19e:	60a2                	ld	ra,8(sp)
 1a0:	6402                	ld	s0,0(sp)
 1a2:	0141                	addi	sp,sp,16
 1a4:	8082                	ret

00000000000001a6 <thread_a>:
volatile int a_started, b_started, c_started;
volatile int a_n, b_n, c_n;

void 
thread_a(void)
{
 1a6:	7179                	addi	sp,sp,-48
 1a8:	f406                	sd	ra,40(sp)
 1aa:	f022                	sd	s0,32(sp)
 1ac:	ec26                	sd	s1,24(sp)
 1ae:	e84a                	sd	s2,16(sp)
 1b0:	e44e                	sd	s3,8(sp)
 1b2:	e052                	sd	s4,0(sp)
 1b4:	1800                	addi	s0,sp,48
  int i;
  printf("thread_a started\n");
 1b6:	00001517          	auipc	a0,0x1
 1ba:	b2a50513          	addi	a0,a0,-1238 # ce0 <malloc+0x110>
 1be:	00001097          	auipc	ra,0x1
 1c2:	952080e7          	jalr	-1710(ra) # b10 <printf>
  a_started = 1;
 1c6:	4785                	li	a5,1
 1c8:	00001717          	auipc	a4,0x1
 1cc:	c2f72223          	sw	a5,-988(a4) # dec <a_started>
  while(b_started == 0 || c_started == 0)
 1d0:	00001497          	auipc	s1,0x1
 1d4:	c1848493          	addi	s1,s1,-1000 # de8 <b_started>
 1d8:	00001917          	auipc	s2,0x1
 1dc:	c0c90913          	addi	s2,s2,-1012 # de4 <c_started>
 1e0:	a029                	j	1ea <thread_a+0x44>
    thread_yield();
 1e2:	00000097          	auipc	ra,0x0
 1e6:	f9a080e7          	jalr	-102(ra) # 17c <thread_yield>
  while(b_started == 0 || c_started == 0)
 1ea:	409c                	lw	a5,0(s1)
 1ec:	2781                	sext.w	a5,a5
 1ee:	dbf5                	beqz	a5,1e2 <thread_a+0x3c>
 1f0:	00092783          	lw	a5,0(s2)
 1f4:	2781                	sext.w	a5,a5
 1f6:	d7f5                	beqz	a5,1e2 <thread_a+0x3c>
  
  for (i = 0; i < 100; i++) {
 1f8:	4481                	li	s1,0
    printf("thread_a %d\n", i);
 1fa:	00001a17          	auipc	s4,0x1
 1fe:	afea0a13          	addi	s4,s4,-1282 # cf8 <malloc+0x128>
    a_n += 1;
 202:	00001917          	auipc	s2,0x1
 206:	bde90913          	addi	s2,s2,-1058 # de0 <a_n>
  for (i = 0; i < 100; i++) {
 20a:	06400993          	li	s3,100
    printf("thread_a %d\n", i);
 20e:	85a6                	mv	a1,s1
 210:	8552                	mv	a0,s4
 212:	00001097          	auipc	ra,0x1
 216:	8fe080e7          	jalr	-1794(ra) # b10 <printf>
    a_n += 1;
 21a:	00092783          	lw	a5,0(s2)
 21e:	2785                	addiw	a5,a5,1
 220:	00f92023          	sw	a5,0(s2)
    thread_yield();
 224:	00000097          	auipc	ra,0x0
 228:	f58080e7          	jalr	-168(ra) # 17c <thread_yield>
  for (i = 0; i < 100; i++) {
 22c:	2485                	addiw	s1,s1,1
 22e:	ff3490e3          	bne	s1,s3,20e <thread_a+0x68>
  }
  printf("thread_a: exit after %d\n", a_n);
 232:	00001797          	auipc	a5,0x1
 236:	bae78793          	addi	a5,a5,-1106 # de0 <a_n>
 23a:	438c                	lw	a1,0(a5)
 23c:	2581                	sext.w	a1,a1
 23e:	00001517          	auipc	a0,0x1
 242:	aca50513          	addi	a0,a0,-1334 # d08 <malloc+0x138>
 246:	00001097          	auipc	ra,0x1
 24a:	8ca080e7          	jalr	-1846(ra) # b10 <printf>

  current_thread->state = FREE;
 24e:	00001797          	auipc	a5,0x1
 252:	ba278793          	addi	a5,a5,-1118 # df0 <current_thread>
 256:	639c                	ld	a5,0(a5)
 258:	6709                	lui	a4,0x2
 25a:	97ba                	add	a5,a5,a4
 25c:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 260:	00000097          	auipc	ra,0x0
 264:	e02080e7          	jalr	-510(ra) # 62 <thread_schedule>
}
 268:	70a2                	ld	ra,40(sp)
 26a:	7402                	ld	s0,32(sp)
 26c:	64e2                	ld	s1,24(sp)
 26e:	6942                	ld	s2,16(sp)
 270:	69a2                	ld	s3,8(sp)
 272:	6a02                	ld	s4,0(sp)
 274:	6145                	addi	sp,sp,48
 276:	8082                	ret

0000000000000278 <thread_b>:

void 
thread_b(void)
{
 278:	7179                	addi	sp,sp,-48
 27a:	f406                	sd	ra,40(sp)
 27c:	f022                	sd	s0,32(sp)
 27e:	ec26                	sd	s1,24(sp)
 280:	e84a                	sd	s2,16(sp)
 282:	e44e                	sd	s3,8(sp)
 284:	e052                	sd	s4,0(sp)
 286:	1800                	addi	s0,sp,48
  int i;
  printf("thread_b started\n");
 288:	00001517          	auipc	a0,0x1
 28c:	aa050513          	addi	a0,a0,-1376 # d28 <malloc+0x158>
 290:	00001097          	auipc	ra,0x1
 294:	880080e7          	jalr	-1920(ra) # b10 <printf>
  b_started = 1;
 298:	4785                	li	a5,1
 29a:	00001717          	auipc	a4,0x1
 29e:	b4f72723          	sw	a5,-1202(a4) # de8 <b_started>
  while(a_started == 0 || c_started == 0)
 2a2:	00001497          	auipc	s1,0x1
 2a6:	b4a48493          	addi	s1,s1,-1206 # dec <a_started>
 2aa:	00001917          	auipc	s2,0x1
 2ae:	b3a90913          	addi	s2,s2,-1222 # de4 <c_started>
 2b2:	a029                	j	2bc <thread_b+0x44>
    thread_yield();
 2b4:	00000097          	auipc	ra,0x0
 2b8:	ec8080e7          	jalr	-312(ra) # 17c <thread_yield>
  while(a_started == 0 || c_started == 0)
 2bc:	409c                	lw	a5,0(s1)
 2be:	2781                	sext.w	a5,a5
 2c0:	dbf5                	beqz	a5,2b4 <thread_b+0x3c>
 2c2:	00092783          	lw	a5,0(s2)
 2c6:	2781                	sext.w	a5,a5
 2c8:	d7f5                	beqz	a5,2b4 <thread_b+0x3c>
  
  for (i = 0; i < 100; i++) {
 2ca:	4481                	li	s1,0
    printf("thread_b %d\n", i);
 2cc:	00001a17          	auipc	s4,0x1
 2d0:	a74a0a13          	addi	s4,s4,-1420 # d40 <malloc+0x170>
    b_n += 1;
 2d4:	00001917          	auipc	s2,0x1
 2d8:	b0890913          	addi	s2,s2,-1272 # ddc <b_n>
  for (i = 0; i < 100; i++) {
 2dc:	06400993          	li	s3,100
    printf("thread_b %d\n", i);
 2e0:	85a6                	mv	a1,s1
 2e2:	8552                	mv	a0,s4
 2e4:	00001097          	auipc	ra,0x1
 2e8:	82c080e7          	jalr	-2004(ra) # b10 <printf>
    b_n += 1;
 2ec:	00092783          	lw	a5,0(s2)
 2f0:	2785                	addiw	a5,a5,1
 2f2:	00f92023          	sw	a5,0(s2)
    thread_yield();
 2f6:	00000097          	auipc	ra,0x0
 2fa:	e86080e7          	jalr	-378(ra) # 17c <thread_yield>
  for (i = 0; i < 100; i++) {
 2fe:	2485                	addiw	s1,s1,1
 300:	ff3490e3          	bne	s1,s3,2e0 <thread_b+0x68>
  }
  printf("thread_b: exit after %d\n", b_n);
 304:	00001797          	auipc	a5,0x1
 308:	ad878793          	addi	a5,a5,-1320 # ddc <b_n>
 30c:	438c                	lw	a1,0(a5)
 30e:	2581                	sext.w	a1,a1
 310:	00001517          	auipc	a0,0x1
 314:	a4050513          	addi	a0,a0,-1472 # d50 <malloc+0x180>
 318:	00000097          	auipc	ra,0x0
 31c:	7f8080e7          	jalr	2040(ra) # b10 <printf>

  current_thread->state = FREE;
 320:	00001797          	auipc	a5,0x1
 324:	ad078793          	addi	a5,a5,-1328 # df0 <current_thread>
 328:	639c                	ld	a5,0(a5)
 32a:	6709                	lui	a4,0x2
 32c:	97ba                	add	a5,a5,a4
 32e:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 332:	00000097          	auipc	ra,0x0
 336:	d30080e7          	jalr	-720(ra) # 62 <thread_schedule>
}
 33a:	70a2                	ld	ra,40(sp)
 33c:	7402                	ld	s0,32(sp)
 33e:	64e2                	ld	s1,24(sp)
 340:	6942                	ld	s2,16(sp)
 342:	69a2                	ld	s3,8(sp)
 344:	6a02                	ld	s4,0(sp)
 346:	6145                	addi	sp,sp,48
 348:	8082                	ret

000000000000034a <thread_c>:

void 
thread_c(void)
{
 34a:	7179                	addi	sp,sp,-48
 34c:	f406                	sd	ra,40(sp)
 34e:	f022                	sd	s0,32(sp)
 350:	ec26                	sd	s1,24(sp)
 352:	e84a                	sd	s2,16(sp)
 354:	e44e                	sd	s3,8(sp)
 356:	e052                	sd	s4,0(sp)
 358:	1800                	addi	s0,sp,48
  int i;
  printf("thread_c started\n");
 35a:	00001517          	auipc	a0,0x1
 35e:	a1650513          	addi	a0,a0,-1514 # d70 <malloc+0x1a0>
 362:	00000097          	auipc	ra,0x0
 366:	7ae080e7          	jalr	1966(ra) # b10 <printf>
  c_started = 1;
 36a:	4785                	li	a5,1
 36c:	00001717          	auipc	a4,0x1
 370:	a6f72c23          	sw	a5,-1416(a4) # de4 <c_started>
  while(a_started == 0 || b_started == 0)
 374:	00001497          	auipc	s1,0x1
 378:	a7848493          	addi	s1,s1,-1416 # dec <a_started>
 37c:	00001917          	auipc	s2,0x1
 380:	a6c90913          	addi	s2,s2,-1428 # de8 <b_started>
 384:	a029                	j	38e <thread_c+0x44>
    thread_yield();
 386:	00000097          	auipc	ra,0x0
 38a:	df6080e7          	jalr	-522(ra) # 17c <thread_yield>
  while(a_started == 0 || b_started == 0)
 38e:	409c                	lw	a5,0(s1)
 390:	2781                	sext.w	a5,a5
 392:	dbf5                	beqz	a5,386 <thread_c+0x3c>
 394:	00092783          	lw	a5,0(s2)
 398:	2781                	sext.w	a5,a5
 39a:	d7f5                	beqz	a5,386 <thread_c+0x3c>
  
  for (i = 0; i < 100; i++) {
 39c:	4481                	li	s1,0
    printf("thread_c %d\n", i);
 39e:	00001a17          	auipc	s4,0x1
 3a2:	9eaa0a13          	addi	s4,s4,-1558 # d88 <malloc+0x1b8>
    c_n += 1;
 3a6:	00001917          	auipc	s2,0x1
 3aa:	a3290913          	addi	s2,s2,-1486 # dd8 <c_n>
  for (i = 0; i < 100; i++) {
 3ae:	06400993          	li	s3,100
    printf("thread_c %d\n", i);
 3b2:	85a6                	mv	a1,s1
 3b4:	8552                	mv	a0,s4
 3b6:	00000097          	auipc	ra,0x0
 3ba:	75a080e7          	jalr	1882(ra) # b10 <printf>
    c_n += 1;
 3be:	00092783          	lw	a5,0(s2)
 3c2:	2785                	addiw	a5,a5,1
 3c4:	00f92023          	sw	a5,0(s2)
    thread_yield();
 3c8:	00000097          	auipc	ra,0x0
 3cc:	db4080e7          	jalr	-588(ra) # 17c <thread_yield>
  for (i = 0; i < 100; i++) {
 3d0:	2485                	addiw	s1,s1,1
 3d2:	ff3490e3          	bne	s1,s3,3b2 <thread_c+0x68>
  }
  printf("thread_c: exit after %d\n", c_n);
 3d6:	00001797          	auipc	a5,0x1
 3da:	a0278793          	addi	a5,a5,-1534 # dd8 <c_n>
 3de:	438c                	lw	a1,0(a5)
 3e0:	2581                	sext.w	a1,a1
 3e2:	00001517          	auipc	a0,0x1
 3e6:	9b650513          	addi	a0,a0,-1610 # d98 <malloc+0x1c8>
 3ea:	00000097          	auipc	ra,0x0
 3ee:	726080e7          	jalr	1830(ra) # b10 <printf>

  current_thread->state = FREE;
 3f2:	00001797          	auipc	a5,0x1
 3f6:	9fe78793          	addi	a5,a5,-1538 # df0 <current_thread>
 3fa:	639c                	ld	a5,0(a5)
 3fc:	6709                	lui	a4,0x2
 3fe:	97ba                	add	a5,a5,a4
 400:	0007a023          	sw	zero,0(a5)
  thread_schedule();
 404:	00000097          	auipc	ra,0x0
 408:	c5e080e7          	jalr	-930(ra) # 62 <thread_schedule>
}
 40c:	70a2                	ld	ra,40(sp)
 40e:	7402                	ld	s0,32(sp)
 410:	64e2                	ld	s1,24(sp)
 412:	6942                	ld	s2,16(sp)
 414:	69a2                	ld	s3,8(sp)
 416:	6a02                	ld	s4,0(sp)
 418:	6145                	addi	sp,sp,48
 41a:	8082                	ret

000000000000041c <main>:

int 
main(int argc, char *argv[]) 
{
 41c:	1141                	addi	sp,sp,-16
 41e:	e406                	sd	ra,8(sp)
 420:	e022                	sd	s0,0(sp)
 422:	0800                	addi	s0,sp,16
  a_started = b_started = c_started = 0;
 424:	00001797          	auipc	a5,0x1
 428:	9c07a023          	sw	zero,-1600(a5) # de4 <c_started>
 42c:	00001797          	auipc	a5,0x1
 430:	9a07ae23          	sw	zero,-1604(a5) # de8 <b_started>
 434:	00001797          	auipc	a5,0x1
 438:	9a07ac23          	sw	zero,-1608(a5) # dec <a_started>
  a_n = b_n = c_n = 0;
 43c:	00001797          	auipc	a5,0x1
 440:	9807ae23          	sw	zero,-1636(a5) # dd8 <c_n>
 444:	00001797          	auipc	a5,0x1
 448:	9807ac23          	sw	zero,-1640(a5) # ddc <b_n>
 44c:	00001797          	auipc	a5,0x1
 450:	9807aa23          	sw	zero,-1644(a5) # de0 <a_n>
  thread_init();
 454:	00000097          	auipc	ra,0x0
 458:	bac080e7          	jalr	-1108(ra) # 0 <thread_init>
  thread_create(thread_a);
 45c:	00000517          	auipc	a0,0x0
 460:	d4a50513          	addi	a0,a0,-694 # 1a6 <thread_a>
 464:	00000097          	auipc	ra,0x0
 468:	c90080e7          	jalr	-880(ra) # f4 <thread_create>
  thread_create(thread_b);
 46c:	00000517          	auipc	a0,0x0
 470:	e0c50513          	addi	a0,a0,-500 # 278 <thread_b>
 474:	00000097          	auipc	ra,0x0
 478:	c80080e7          	jalr	-896(ra) # f4 <thread_create>
  thread_create(thread_c);
 47c:	00000517          	auipc	a0,0x0
 480:	ece50513          	addi	a0,a0,-306 # 34a <thread_c>
 484:	00000097          	auipc	ra,0x0
 488:	c70080e7          	jalr	-912(ra) # f4 <thread_create>
  thread_schedule();
 48c:	00000097          	auipc	ra,0x0
 490:	bd6080e7          	jalr	-1066(ra) # 62 <thread_schedule>
  exit(0);
 494:	4501                	li	a0,0
 496:	00000097          	auipc	ra,0x0
 49a:	302080e7          	jalr	770(ra) # 798 <exit>

000000000000049e <thread_switch>:
         */

	.globl thread_switch
thread_switch:
	/* YOUR CODE HERE */
sd ra, 0(a0)
 49e:	00153023          	sd	ra,0(a0)
    sd sp, 8(a0)
 4a2:	00253423          	sd	sp,8(a0)
    sd s0, 16(a0)
 4a6:	e900                	sd	s0,16(a0)
    sd s1, 24(a0)
 4a8:	ed04                	sd	s1,24(a0)
    sd s2, 32(a0)
 4aa:	03253023          	sd	s2,32(a0)
    sd s3, 40(a0)
 4ae:	03353423          	sd	s3,40(a0)
    sd s4, 48(a0)
 4b2:	03453823          	sd	s4,48(a0)
    sd s5, 56(a0)
 4b6:	03553c23          	sd	s5,56(a0)
    sd s6, 64(a0)
 4ba:	05653023          	sd	s6,64(a0)
    sd s7, 72(a0)
 4be:	05753423          	sd	s7,72(a0)
    sd s8, 80(a0)
 4c2:	05853823          	sd	s8,80(a0)
    sd s9, 88(a0)
 4c6:	05953c23          	sd	s9,88(a0)
    sd s10, 96(a0)
 4ca:	07a53023          	sd	s10,96(a0)
    sd s11, 104(a0)
 4ce:	07b53423          	sd	s11,104(a0)

    ld ra, 0(a1)
 4d2:	0005b083          	ld	ra,0(a1)
    ld sp, 8(a1)
 4d6:	0085b103          	ld	sp,8(a1)
    ld s0, 16(a1)
 4da:	6980                	ld	s0,16(a1)
    ld s1, 24(a1)
 4dc:	6d84                	ld	s1,24(a1)
    ld s2, 32(a1)
 4de:	0205b903          	ld	s2,32(a1)
    ld s3, 40(a1)
 4e2:	0285b983          	ld	s3,40(a1)
    ld s4, 48(a1)
 4e6:	0305ba03          	ld	s4,48(a1)
    ld s5, 56(a1)
 4ea:	0385ba83          	ld	s5,56(a1)
    ld s6, 64(a1)
 4ee:	0405bb03          	ld	s6,64(a1)
    ld s7, 72(a1)
 4f2:	0485bb83          	ld	s7,72(a1)
    ld s8, 80(a1)
 4f6:	0505bc03          	ld	s8,80(a1)
    ld s9, 88(a1)
 4fa:	0585bc83          	ld	s9,88(a1)
    ld s10, 96(a1)
 4fe:	0605bd03          	ld	s10,96(a1)
    ld s11, 104(a1)
 502:	0685bd83          	ld	s11,104(a1)
	ret    /* return to ra */
 506:	8082                	ret

0000000000000508 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 508:	1141                	addi	sp,sp,-16
 50a:	e422                	sd	s0,8(sp)
 50c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 50e:	87aa                	mv	a5,a0
 510:	0585                	addi	a1,a1,1
 512:	0785                	addi	a5,a5,1
 514:	fff5c703          	lbu	a4,-1(a1)
 518:	fee78fa3          	sb	a4,-1(a5)
 51c:	fb75                	bnez	a4,510 <strcpy+0x8>
    ;
  return os;
}
 51e:	6422                	ld	s0,8(sp)
 520:	0141                	addi	sp,sp,16
 522:	8082                	ret

0000000000000524 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 524:	1141                	addi	sp,sp,-16
 526:	e422                	sd	s0,8(sp)
 528:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 52a:	00054783          	lbu	a5,0(a0)
 52e:	cf91                	beqz	a5,54a <strcmp+0x26>
 530:	0005c703          	lbu	a4,0(a1)
 534:	00f71b63          	bne	a4,a5,54a <strcmp+0x26>
    p++, q++;
 538:	0505                	addi	a0,a0,1
 53a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 53c:	00054783          	lbu	a5,0(a0)
 540:	c789                	beqz	a5,54a <strcmp+0x26>
 542:	0005c703          	lbu	a4,0(a1)
 546:	fef709e3          	beq	a4,a5,538 <strcmp+0x14>
  return (uchar)*p - (uchar)*q;
 54a:	0005c503          	lbu	a0,0(a1)
}
 54e:	40a7853b          	subw	a0,a5,a0
 552:	6422                	ld	s0,8(sp)
 554:	0141                	addi	sp,sp,16
 556:	8082                	ret

0000000000000558 <strlen>:

uint
strlen(const char *s)
{
 558:	1141                	addi	sp,sp,-16
 55a:	e422                	sd	s0,8(sp)
 55c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 55e:	00054783          	lbu	a5,0(a0)
 562:	cf91                	beqz	a5,57e <strlen+0x26>
 564:	0505                	addi	a0,a0,1
 566:	87aa                	mv	a5,a0
 568:	4685                	li	a3,1
 56a:	9e89                	subw	a3,a3,a0
 56c:	00f6853b          	addw	a0,a3,a5
 570:	0785                	addi	a5,a5,1
 572:	fff7c703          	lbu	a4,-1(a5)
 576:	fb7d                	bnez	a4,56c <strlen+0x14>
    ;
  return n;
}
 578:	6422                	ld	s0,8(sp)
 57a:	0141                	addi	sp,sp,16
 57c:	8082                	ret
  for(n = 0; s[n]; n++)
 57e:	4501                	li	a0,0
 580:	bfe5                	j	578 <strlen+0x20>

0000000000000582 <memset>:

void*
memset(void *dst, int c, uint n)
{
 582:	1141                	addi	sp,sp,-16
 584:	e422                	sd	s0,8(sp)
 586:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 588:	ce09                	beqz	a2,5a2 <memset+0x20>
 58a:	87aa                	mv	a5,a0
 58c:	fff6071b          	addiw	a4,a2,-1
 590:	1702                	slli	a4,a4,0x20
 592:	9301                	srli	a4,a4,0x20
 594:	0705                	addi	a4,a4,1
 596:	972a                	add	a4,a4,a0
    cdst[i] = c;
 598:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 59c:	0785                	addi	a5,a5,1
 59e:	fee79de3          	bne	a5,a4,598 <memset+0x16>
  }
  return dst;
}
 5a2:	6422                	ld	s0,8(sp)
 5a4:	0141                	addi	sp,sp,16
 5a6:	8082                	ret

00000000000005a8 <strchr>:

char*
strchr(const char *s, char c)
{
 5a8:	1141                	addi	sp,sp,-16
 5aa:	e422                	sd	s0,8(sp)
 5ac:	0800                	addi	s0,sp,16
  for(; *s; s++)
 5ae:	00054783          	lbu	a5,0(a0)
 5b2:	cf91                	beqz	a5,5ce <strchr+0x26>
    if(*s == c)
 5b4:	00f58a63          	beq	a1,a5,5c8 <strchr+0x20>
  for(; *s; s++)
 5b8:	0505                	addi	a0,a0,1
 5ba:	00054783          	lbu	a5,0(a0)
 5be:	c781                	beqz	a5,5c6 <strchr+0x1e>
    if(*s == c)
 5c0:	feb79ce3          	bne	a5,a1,5b8 <strchr+0x10>
 5c4:	a011                	j	5c8 <strchr+0x20>
      return (char*)s;
  return 0;
 5c6:	4501                	li	a0,0
}
 5c8:	6422                	ld	s0,8(sp)
 5ca:	0141                	addi	sp,sp,16
 5cc:	8082                	ret
  return 0;
 5ce:	4501                	li	a0,0
 5d0:	bfe5                	j	5c8 <strchr+0x20>

00000000000005d2 <gets>:

char*
gets(char *buf, int max)
{
 5d2:	711d                	addi	sp,sp,-96
 5d4:	ec86                	sd	ra,88(sp)
 5d6:	e8a2                	sd	s0,80(sp)
 5d8:	e4a6                	sd	s1,72(sp)
 5da:	e0ca                	sd	s2,64(sp)
 5dc:	fc4e                	sd	s3,56(sp)
 5de:	f852                	sd	s4,48(sp)
 5e0:	f456                	sd	s5,40(sp)
 5e2:	f05a                	sd	s6,32(sp)
 5e4:	ec5e                	sd	s7,24(sp)
 5e6:	1080                	addi	s0,sp,96
 5e8:	8baa                	mv	s7,a0
 5ea:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 5ec:	892a                	mv	s2,a0
 5ee:	4981                	li	s3,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 5f0:	4aa9                	li	s5,10
 5f2:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 5f4:	0019849b          	addiw	s1,s3,1
 5f8:	0344d863          	ble	s4,s1,628 <gets+0x56>
    cc = read(0, &c, 1);
 5fc:	4605                	li	a2,1
 5fe:	faf40593          	addi	a1,s0,-81
 602:	4501                	li	a0,0
 604:	00000097          	auipc	ra,0x0
 608:	1ac080e7          	jalr	428(ra) # 7b0 <read>
    if(cc < 1)
 60c:	00a05e63          	blez	a0,628 <gets+0x56>
    buf[i++] = c;
 610:	faf44783          	lbu	a5,-81(s0)
 614:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 618:	01578763          	beq	a5,s5,626 <gets+0x54>
 61c:	0905                	addi	s2,s2,1
  for(i=0; i+1 < max; ){
 61e:	89a6                	mv	s3,s1
    if(c == '\n' || c == '\r')
 620:	fd679ae3          	bne	a5,s6,5f4 <gets+0x22>
 624:	a011                	j	628 <gets+0x56>
  for(i=0; i+1 < max; ){
 626:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 628:	99de                	add	s3,s3,s7
 62a:	00098023          	sb	zero,0(s3)
  return buf;
}
 62e:	855e                	mv	a0,s7
 630:	60e6                	ld	ra,88(sp)
 632:	6446                	ld	s0,80(sp)
 634:	64a6                	ld	s1,72(sp)
 636:	6906                	ld	s2,64(sp)
 638:	79e2                	ld	s3,56(sp)
 63a:	7a42                	ld	s4,48(sp)
 63c:	7aa2                	ld	s5,40(sp)
 63e:	7b02                	ld	s6,32(sp)
 640:	6be2                	ld	s7,24(sp)
 642:	6125                	addi	sp,sp,96
 644:	8082                	ret

0000000000000646 <stat>:

int
stat(const char *n, struct stat *st)
{
 646:	1101                	addi	sp,sp,-32
 648:	ec06                	sd	ra,24(sp)
 64a:	e822                	sd	s0,16(sp)
 64c:	e426                	sd	s1,8(sp)
 64e:	e04a                	sd	s2,0(sp)
 650:	1000                	addi	s0,sp,32
 652:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 654:	4581                	li	a1,0
 656:	00000097          	auipc	ra,0x0
 65a:	182080e7          	jalr	386(ra) # 7d8 <open>
  if(fd < 0)
 65e:	02054563          	bltz	a0,688 <stat+0x42>
 662:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 664:	85ca                	mv	a1,s2
 666:	00000097          	auipc	ra,0x0
 66a:	18a080e7          	jalr	394(ra) # 7f0 <fstat>
 66e:	892a                	mv	s2,a0
  close(fd);
 670:	8526                	mv	a0,s1
 672:	00000097          	auipc	ra,0x0
 676:	14e080e7          	jalr	334(ra) # 7c0 <close>
  return r;
}
 67a:	854a                	mv	a0,s2
 67c:	60e2                	ld	ra,24(sp)
 67e:	6442                	ld	s0,16(sp)
 680:	64a2                	ld	s1,8(sp)
 682:	6902                	ld	s2,0(sp)
 684:	6105                	addi	sp,sp,32
 686:	8082                	ret
    return -1;
 688:	597d                	li	s2,-1
 68a:	bfc5                	j	67a <stat+0x34>

000000000000068c <atoi>:

int
atoi(const char *s)
{
 68c:	1141                	addi	sp,sp,-16
 68e:	e422                	sd	s0,8(sp)
 690:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 692:	00054683          	lbu	a3,0(a0)
 696:	fd06879b          	addiw	a5,a3,-48
 69a:	0ff7f793          	andi	a5,a5,255
 69e:	4725                	li	a4,9
 6a0:	02f76963          	bltu	a4,a5,6d2 <atoi+0x46>
 6a4:	862a                	mv	a2,a0
  n = 0;
 6a6:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 6a8:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 6aa:	0605                	addi	a2,a2,1
 6ac:	0025179b          	slliw	a5,a0,0x2
 6b0:	9fa9                	addw	a5,a5,a0
 6b2:	0017979b          	slliw	a5,a5,0x1
 6b6:	9fb5                	addw	a5,a5,a3
 6b8:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 6bc:	00064683          	lbu	a3,0(a2)
 6c0:	fd06871b          	addiw	a4,a3,-48
 6c4:	0ff77713          	andi	a4,a4,255
 6c8:	fee5f1e3          	bleu	a4,a1,6aa <atoi+0x1e>
  return n;
}
 6cc:	6422                	ld	s0,8(sp)
 6ce:	0141                	addi	sp,sp,16
 6d0:	8082                	ret
  n = 0;
 6d2:	4501                	li	a0,0
 6d4:	bfe5                	j	6cc <atoi+0x40>

00000000000006d6 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 6d6:	1141                	addi	sp,sp,-16
 6d8:	e422                	sd	s0,8(sp)
 6da:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 6dc:	02b57663          	bleu	a1,a0,708 <memmove+0x32>
    while(n-- > 0)
 6e0:	02c05163          	blez	a2,702 <memmove+0x2c>
 6e4:	fff6079b          	addiw	a5,a2,-1
 6e8:	1782                	slli	a5,a5,0x20
 6ea:	9381                	srli	a5,a5,0x20
 6ec:	0785                	addi	a5,a5,1
 6ee:	97aa                	add	a5,a5,a0
  dst = vdst;
 6f0:	872a                	mv	a4,a0
      *dst++ = *src++;
 6f2:	0585                	addi	a1,a1,1
 6f4:	0705                	addi	a4,a4,1
 6f6:	fff5c683          	lbu	a3,-1(a1)
 6fa:	fed70fa3          	sb	a3,-1(a4) # 1fff <__global_pointer$+0xa27>
    while(n-- > 0)
 6fe:	fee79ae3          	bne	a5,a4,6f2 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 702:	6422                	ld	s0,8(sp)
 704:	0141                	addi	sp,sp,16
 706:	8082                	ret
    dst += n;
 708:	00c50733          	add	a4,a0,a2
    src += n;
 70c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 70e:	fec05ae3          	blez	a2,702 <memmove+0x2c>
 712:	fff6079b          	addiw	a5,a2,-1
 716:	1782                	slli	a5,a5,0x20
 718:	9381                	srli	a5,a5,0x20
 71a:	fff7c793          	not	a5,a5
 71e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 720:	15fd                	addi	a1,a1,-1
 722:	177d                	addi	a4,a4,-1
 724:	0005c683          	lbu	a3,0(a1)
 728:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 72c:	fef71ae3          	bne	a4,a5,720 <memmove+0x4a>
 730:	bfc9                	j	702 <memmove+0x2c>

0000000000000732 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 732:	1141                	addi	sp,sp,-16
 734:	e422                	sd	s0,8(sp)
 736:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 738:	ce15                	beqz	a2,774 <memcmp+0x42>
 73a:	fff6069b          	addiw	a3,a2,-1
    if (*p1 != *p2) {
 73e:	00054783          	lbu	a5,0(a0)
 742:	0005c703          	lbu	a4,0(a1)
 746:	02e79063          	bne	a5,a4,766 <memcmp+0x34>
 74a:	1682                	slli	a3,a3,0x20
 74c:	9281                	srli	a3,a3,0x20
 74e:	0685                	addi	a3,a3,1
 750:	96aa                	add	a3,a3,a0
      return *p1 - *p2;
    }
    p1++;
 752:	0505                	addi	a0,a0,1
    p2++;
 754:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 756:	00d50d63          	beq	a0,a3,770 <memcmp+0x3e>
    if (*p1 != *p2) {
 75a:	00054783          	lbu	a5,0(a0)
 75e:	0005c703          	lbu	a4,0(a1)
 762:	fee788e3          	beq	a5,a4,752 <memcmp+0x20>
      return *p1 - *p2;
 766:	40e7853b          	subw	a0,a5,a4
  }
  return 0;
}
 76a:	6422                	ld	s0,8(sp)
 76c:	0141                	addi	sp,sp,16
 76e:	8082                	ret
  return 0;
 770:	4501                	li	a0,0
 772:	bfe5                	j	76a <memcmp+0x38>
 774:	4501                	li	a0,0
 776:	bfd5                	j	76a <memcmp+0x38>

0000000000000778 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 778:	1141                	addi	sp,sp,-16
 77a:	e406                	sd	ra,8(sp)
 77c:	e022                	sd	s0,0(sp)
 77e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 780:	00000097          	auipc	ra,0x0
 784:	f56080e7          	jalr	-170(ra) # 6d6 <memmove>
}
 788:	60a2                	ld	ra,8(sp)
 78a:	6402                	ld	s0,0(sp)
 78c:	0141                	addi	sp,sp,16
 78e:	8082                	ret

0000000000000790 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 790:	4885                	li	a7,1
 ecall
 792:	00000073          	ecall
 ret
 796:	8082                	ret

0000000000000798 <exit>:
.global exit
exit:
 li a7, SYS_exit
 798:	4889                	li	a7,2
 ecall
 79a:	00000073          	ecall
 ret
 79e:	8082                	ret

00000000000007a0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 7a0:	488d                	li	a7,3
 ecall
 7a2:	00000073          	ecall
 ret
 7a6:	8082                	ret

00000000000007a8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 7a8:	4891                	li	a7,4
 ecall
 7aa:	00000073          	ecall
 ret
 7ae:	8082                	ret

00000000000007b0 <read>:
.global read
read:
 li a7, SYS_read
 7b0:	4895                	li	a7,5
 ecall
 7b2:	00000073          	ecall
 ret
 7b6:	8082                	ret

00000000000007b8 <write>:
.global write
write:
 li a7, SYS_write
 7b8:	48c1                	li	a7,16
 ecall
 7ba:	00000073          	ecall
 ret
 7be:	8082                	ret

00000000000007c0 <close>:
.global close
close:
 li a7, SYS_close
 7c0:	48d5                	li	a7,21
 ecall
 7c2:	00000073          	ecall
 ret
 7c6:	8082                	ret

00000000000007c8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 7c8:	4899                	li	a7,6
 ecall
 7ca:	00000073          	ecall
 ret
 7ce:	8082                	ret

00000000000007d0 <exec>:
.global exec
exec:
 li a7, SYS_exec
 7d0:	489d                	li	a7,7
 ecall
 7d2:	00000073          	ecall
 ret
 7d6:	8082                	ret

00000000000007d8 <open>:
.global open
open:
 li a7, SYS_open
 7d8:	48bd                	li	a7,15
 ecall
 7da:	00000073          	ecall
 ret
 7de:	8082                	ret

00000000000007e0 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 7e0:	48c5                	li	a7,17
 ecall
 7e2:	00000073          	ecall
 ret
 7e6:	8082                	ret

00000000000007e8 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 7e8:	48c9                	li	a7,18
 ecall
 7ea:	00000073          	ecall
 ret
 7ee:	8082                	ret

00000000000007f0 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 7f0:	48a1                	li	a7,8
 ecall
 7f2:	00000073          	ecall
 ret
 7f6:	8082                	ret

00000000000007f8 <link>:
.global link
link:
 li a7, SYS_link
 7f8:	48cd                	li	a7,19
 ecall
 7fa:	00000073          	ecall
 ret
 7fe:	8082                	ret

0000000000000800 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 800:	48d1                	li	a7,20
 ecall
 802:	00000073          	ecall
 ret
 806:	8082                	ret

0000000000000808 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 808:	48a5                	li	a7,9
 ecall
 80a:	00000073          	ecall
 ret
 80e:	8082                	ret

0000000000000810 <dup>:
.global dup
dup:
 li a7, SYS_dup
 810:	48a9                	li	a7,10
 ecall
 812:	00000073          	ecall
 ret
 816:	8082                	ret

0000000000000818 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 818:	48ad                	li	a7,11
 ecall
 81a:	00000073          	ecall
 ret
 81e:	8082                	ret

0000000000000820 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 820:	48b1                	li	a7,12
 ecall
 822:	00000073          	ecall
 ret
 826:	8082                	ret

0000000000000828 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 828:	48b5                	li	a7,13
 ecall
 82a:	00000073          	ecall
 ret
 82e:	8082                	ret

0000000000000830 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 830:	48b9                	li	a7,14
 ecall
 832:	00000073          	ecall
 ret
 836:	8082                	ret

0000000000000838 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 838:	1101                	addi	sp,sp,-32
 83a:	ec06                	sd	ra,24(sp)
 83c:	e822                	sd	s0,16(sp)
 83e:	1000                	addi	s0,sp,32
 840:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 844:	4605                	li	a2,1
 846:	fef40593          	addi	a1,s0,-17
 84a:	00000097          	auipc	ra,0x0
 84e:	f6e080e7          	jalr	-146(ra) # 7b8 <write>
}
 852:	60e2                	ld	ra,24(sp)
 854:	6442                	ld	s0,16(sp)
 856:	6105                	addi	sp,sp,32
 858:	8082                	ret

000000000000085a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 85a:	7139                	addi	sp,sp,-64
 85c:	fc06                	sd	ra,56(sp)
 85e:	f822                	sd	s0,48(sp)
 860:	f426                	sd	s1,40(sp)
 862:	f04a                	sd	s2,32(sp)
 864:	ec4e                	sd	s3,24(sp)
 866:	0080                	addi	s0,sp,64
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 868:	c299                	beqz	a3,86e <printint+0x14>
 86a:	0005cd63          	bltz	a1,884 <printint+0x2a>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 86e:	2581                	sext.w	a1,a1
  neg = 0;
 870:	4301                	li	t1,0
 872:	fc040713          	addi	a4,s0,-64
  }

  i = 0;
 876:	4801                	li	a6,0
  do{
    buf[i++] = digits[x % base];
 878:	2601                	sext.w	a2,a2
 87a:	00000897          	auipc	a7,0x0
 87e:	53e88893          	addi	a7,a7,1342 # db8 <digits>
 882:	a801                	j	892 <printint+0x38>
    x = -xx;
 884:	40b005bb          	negw	a1,a1
 888:	2581                	sext.w	a1,a1
    neg = 1;
 88a:	4305                	li	t1,1
    x = -xx;
 88c:	b7dd                	j	872 <printint+0x18>
  }while((x /= base) != 0);
 88e:	85be                	mv	a1,a5
    buf[i++] = digits[x % base];
 890:	8836                	mv	a6,a3
 892:	0018069b          	addiw	a3,a6,1
 896:	02c5f7bb          	remuw	a5,a1,a2
 89a:	1782                	slli	a5,a5,0x20
 89c:	9381                	srli	a5,a5,0x20
 89e:	97c6                	add	a5,a5,a7
 8a0:	0007c783          	lbu	a5,0(a5)
 8a4:	00f70023          	sb	a5,0(a4)
  }while((x /= base) != 0);
 8a8:	0705                	addi	a4,a4,1
 8aa:	02c5d7bb          	divuw	a5,a1,a2
 8ae:	fec5f0e3          	bleu	a2,a1,88e <printint+0x34>
  if(neg)
 8b2:	00030b63          	beqz	t1,8c8 <printint+0x6e>
    buf[i++] = '-';
 8b6:	fd040793          	addi	a5,s0,-48
 8ba:	96be                	add	a3,a3,a5
 8bc:	02d00793          	li	a5,45
 8c0:	fef68823          	sb	a5,-16(a3)
 8c4:	0028069b          	addiw	a3,a6,2

  while(--i >= 0)
 8c8:	02d05963          	blez	a3,8fa <printint+0xa0>
 8cc:	89aa                	mv	s3,a0
 8ce:	fc040793          	addi	a5,s0,-64
 8d2:	00d784b3          	add	s1,a5,a3
 8d6:	fff78913          	addi	s2,a5,-1
 8da:	9936                	add	s2,s2,a3
 8dc:	36fd                	addiw	a3,a3,-1
 8de:	1682                	slli	a3,a3,0x20
 8e0:	9281                	srli	a3,a3,0x20
 8e2:	40d90933          	sub	s2,s2,a3
    putc(fd, buf[i]);
 8e6:	fff4c583          	lbu	a1,-1(s1)
 8ea:	854e                	mv	a0,s3
 8ec:	00000097          	auipc	ra,0x0
 8f0:	f4c080e7          	jalr	-180(ra) # 838 <putc>
  while(--i >= 0)
 8f4:	14fd                	addi	s1,s1,-1
 8f6:	ff2498e3          	bne	s1,s2,8e6 <printint+0x8c>
}
 8fa:	70e2                	ld	ra,56(sp)
 8fc:	7442                	ld	s0,48(sp)
 8fe:	74a2                	ld	s1,40(sp)
 900:	7902                	ld	s2,32(sp)
 902:	69e2                	ld	s3,24(sp)
 904:	6121                	addi	sp,sp,64
 906:	8082                	ret

0000000000000908 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 908:	7119                	addi	sp,sp,-128
 90a:	fc86                	sd	ra,120(sp)
 90c:	f8a2                	sd	s0,112(sp)
 90e:	f4a6                	sd	s1,104(sp)
 910:	f0ca                	sd	s2,96(sp)
 912:	ecce                	sd	s3,88(sp)
 914:	e8d2                	sd	s4,80(sp)
 916:	e4d6                	sd	s5,72(sp)
 918:	e0da                	sd	s6,64(sp)
 91a:	fc5e                	sd	s7,56(sp)
 91c:	f862                	sd	s8,48(sp)
 91e:	f466                	sd	s9,40(sp)
 920:	f06a                	sd	s10,32(sp)
 922:	ec6e                	sd	s11,24(sp)
 924:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 926:	0005c483          	lbu	s1,0(a1)
 92a:	18048d63          	beqz	s1,ac4 <vprintf+0x1bc>
 92e:	8aaa                	mv	s5,a0
 930:	8b32                	mv	s6,a2
 932:	00158913          	addi	s2,a1,1
  state = 0;
 936:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 938:	02500a13          	li	s4,37
      if(c == 'd'){
 93c:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 940:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 944:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 948:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 94c:	00000b97          	auipc	s7,0x0
 950:	46cb8b93          	addi	s7,s7,1132 # db8 <digits>
 954:	a839                	j	972 <vprintf+0x6a>
        putc(fd, c);
 956:	85a6                	mv	a1,s1
 958:	8556                	mv	a0,s5
 95a:	00000097          	auipc	ra,0x0
 95e:	ede080e7          	jalr	-290(ra) # 838 <putc>
 962:	a019                	j	968 <vprintf+0x60>
    } else if(state == '%'){
 964:	01498f63          	beq	s3,s4,982 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 968:	0905                	addi	s2,s2,1
 96a:	fff94483          	lbu	s1,-1(s2)
 96e:	14048b63          	beqz	s1,ac4 <vprintf+0x1bc>
    c = fmt[i] & 0xff;
 972:	0004879b          	sext.w	a5,s1
    if(state == 0){
 976:	fe0997e3          	bnez	s3,964 <vprintf+0x5c>
      if(c == '%'){
 97a:	fd479ee3          	bne	a5,s4,956 <vprintf+0x4e>
        state = '%';
 97e:	89be                	mv	s3,a5
 980:	b7e5                	j	968 <vprintf+0x60>
      if(c == 'd'){
 982:	05878063          	beq	a5,s8,9c2 <vprintf+0xba>
      } else if(c == 'l') {
 986:	05978c63          	beq	a5,s9,9de <vprintf+0xd6>
      } else if(c == 'x') {
 98a:	07a78863          	beq	a5,s10,9fa <vprintf+0xf2>
      } else if(c == 'p') {
 98e:	09b78463          	beq	a5,s11,a16 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 992:	07300713          	li	a4,115
 996:	0ce78563          	beq	a5,a4,a60 <vprintf+0x158>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 99a:	06300713          	li	a4,99
 99e:	0ee78c63          	beq	a5,a4,a96 <vprintf+0x18e>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 9a2:	11478663          	beq	a5,s4,aae <vprintf+0x1a6>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 9a6:	85d2                	mv	a1,s4
 9a8:	8556                	mv	a0,s5
 9aa:	00000097          	auipc	ra,0x0
 9ae:	e8e080e7          	jalr	-370(ra) # 838 <putc>
        putc(fd, c);
 9b2:	85a6                	mv	a1,s1
 9b4:	8556                	mv	a0,s5
 9b6:	00000097          	auipc	ra,0x0
 9ba:	e82080e7          	jalr	-382(ra) # 838 <putc>
      }
      state = 0;
 9be:	4981                	li	s3,0
 9c0:	b765                	j	968 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 9c2:	008b0493          	addi	s1,s6,8
 9c6:	4685                	li	a3,1
 9c8:	4629                	li	a2,10
 9ca:	000b2583          	lw	a1,0(s6)
 9ce:	8556                	mv	a0,s5
 9d0:	00000097          	auipc	ra,0x0
 9d4:	e8a080e7          	jalr	-374(ra) # 85a <printint>
 9d8:	8b26                	mv	s6,s1
      state = 0;
 9da:	4981                	li	s3,0
 9dc:	b771                	j	968 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 9de:	008b0493          	addi	s1,s6,8
 9e2:	4681                	li	a3,0
 9e4:	4629                	li	a2,10
 9e6:	000b2583          	lw	a1,0(s6)
 9ea:	8556                	mv	a0,s5
 9ec:	00000097          	auipc	ra,0x0
 9f0:	e6e080e7          	jalr	-402(ra) # 85a <printint>
 9f4:	8b26                	mv	s6,s1
      state = 0;
 9f6:	4981                	li	s3,0
 9f8:	bf85                	j	968 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 9fa:	008b0493          	addi	s1,s6,8
 9fe:	4681                	li	a3,0
 a00:	4641                	li	a2,16
 a02:	000b2583          	lw	a1,0(s6)
 a06:	8556                	mv	a0,s5
 a08:	00000097          	auipc	ra,0x0
 a0c:	e52080e7          	jalr	-430(ra) # 85a <printint>
 a10:	8b26                	mv	s6,s1
      state = 0;
 a12:	4981                	li	s3,0
 a14:	bf91                	j	968 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 a16:	008b0793          	addi	a5,s6,8
 a1a:	f8f43423          	sd	a5,-120(s0)
 a1e:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 a22:	03000593          	li	a1,48
 a26:	8556                	mv	a0,s5
 a28:	00000097          	auipc	ra,0x0
 a2c:	e10080e7          	jalr	-496(ra) # 838 <putc>
  putc(fd, 'x');
 a30:	85ea                	mv	a1,s10
 a32:	8556                	mv	a0,s5
 a34:	00000097          	auipc	ra,0x0
 a38:	e04080e7          	jalr	-508(ra) # 838 <putc>
 a3c:	44c1                	li	s1,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 a3e:	03c9d793          	srli	a5,s3,0x3c
 a42:	97de                	add	a5,a5,s7
 a44:	0007c583          	lbu	a1,0(a5)
 a48:	8556                	mv	a0,s5
 a4a:	00000097          	auipc	ra,0x0
 a4e:	dee080e7          	jalr	-530(ra) # 838 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 a52:	0992                	slli	s3,s3,0x4
 a54:	34fd                	addiw	s1,s1,-1
 a56:	f4e5                	bnez	s1,a3e <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 a58:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 a5c:	4981                	li	s3,0
 a5e:	b729                	j	968 <vprintf+0x60>
        s = va_arg(ap, char*);
 a60:	008b0993          	addi	s3,s6,8
 a64:	000b3483          	ld	s1,0(s6)
        if(s == 0)
 a68:	c085                	beqz	s1,a88 <vprintf+0x180>
        while(*s != 0){
 a6a:	0004c583          	lbu	a1,0(s1)
 a6e:	c9a1                	beqz	a1,abe <vprintf+0x1b6>
          putc(fd, *s);
 a70:	8556                	mv	a0,s5
 a72:	00000097          	auipc	ra,0x0
 a76:	dc6080e7          	jalr	-570(ra) # 838 <putc>
          s++;
 a7a:	0485                	addi	s1,s1,1
        while(*s != 0){
 a7c:	0004c583          	lbu	a1,0(s1)
 a80:	f9e5                	bnez	a1,a70 <vprintf+0x168>
        s = va_arg(ap, char*);
 a82:	8b4e                	mv	s6,s3
      state = 0;
 a84:	4981                	li	s3,0
 a86:	b5cd                	j	968 <vprintf+0x60>
          s = "(null)";
 a88:	00000497          	auipc	s1,0x0
 a8c:	34848493          	addi	s1,s1,840 # dd0 <digits+0x18>
        while(*s != 0){
 a90:	02800593          	li	a1,40
 a94:	bff1                	j	a70 <vprintf+0x168>
        putc(fd, va_arg(ap, uint));
 a96:	008b0493          	addi	s1,s6,8
 a9a:	000b4583          	lbu	a1,0(s6)
 a9e:	8556                	mv	a0,s5
 aa0:	00000097          	auipc	ra,0x0
 aa4:	d98080e7          	jalr	-616(ra) # 838 <putc>
 aa8:	8b26                	mv	s6,s1
      state = 0;
 aaa:	4981                	li	s3,0
 aac:	bd75                	j	968 <vprintf+0x60>
        putc(fd, c);
 aae:	85d2                	mv	a1,s4
 ab0:	8556                	mv	a0,s5
 ab2:	00000097          	auipc	ra,0x0
 ab6:	d86080e7          	jalr	-634(ra) # 838 <putc>
      state = 0;
 aba:	4981                	li	s3,0
 abc:	b575                	j	968 <vprintf+0x60>
        s = va_arg(ap, char*);
 abe:	8b4e                	mv	s6,s3
      state = 0;
 ac0:	4981                	li	s3,0
 ac2:	b55d                	j	968 <vprintf+0x60>
    }
  }
}
 ac4:	70e6                	ld	ra,120(sp)
 ac6:	7446                	ld	s0,112(sp)
 ac8:	74a6                	ld	s1,104(sp)
 aca:	7906                	ld	s2,96(sp)
 acc:	69e6                	ld	s3,88(sp)
 ace:	6a46                	ld	s4,80(sp)
 ad0:	6aa6                	ld	s5,72(sp)
 ad2:	6b06                	ld	s6,64(sp)
 ad4:	7be2                	ld	s7,56(sp)
 ad6:	7c42                	ld	s8,48(sp)
 ad8:	7ca2                	ld	s9,40(sp)
 ada:	7d02                	ld	s10,32(sp)
 adc:	6de2                	ld	s11,24(sp)
 ade:	6109                	addi	sp,sp,128
 ae0:	8082                	ret

0000000000000ae2 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 ae2:	715d                	addi	sp,sp,-80
 ae4:	ec06                	sd	ra,24(sp)
 ae6:	e822                	sd	s0,16(sp)
 ae8:	1000                	addi	s0,sp,32
 aea:	e010                	sd	a2,0(s0)
 aec:	e414                	sd	a3,8(s0)
 aee:	e818                	sd	a4,16(s0)
 af0:	ec1c                	sd	a5,24(s0)
 af2:	03043023          	sd	a6,32(s0)
 af6:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 afa:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 afe:	8622                	mv	a2,s0
 b00:	00000097          	auipc	ra,0x0
 b04:	e08080e7          	jalr	-504(ra) # 908 <vprintf>
}
 b08:	60e2                	ld	ra,24(sp)
 b0a:	6442                	ld	s0,16(sp)
 b0c:	6161                	addi	sp,sp,80
 b0e:	8082                	ret

0000000000000b10 <printf>:

void
printf(const char *fmt, ...)
{
 b10:	711d                	addi	sp,sp,-96
 b12:	ec06                	sd	ra,24(sp)
 b14:	e822                	sd	s0,16(sp)
 b16:	1000                	addi	s0,sp,32
 b18:	e40c                	sd	a1,8(s0)
 b1a:	e810                	sd	a2,16(s0)
 b1c:	ec14                	sd	a3,24(s0)
 b1e:	f018                	sd	a4,32(s0)
 b20:	f41c                	sd	a5,40(s0)
 b22:	03043823          	sd	a6,48(s0)
 b26:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 b2a:	00840613          	addi	a2,s0,8
 b2e:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 b32:	85aa                	mv	a1,a0
 b34:	4505                	li	a0,1
 b36:	00000097          	auipc	ra,0x0
 b3a:	dd2080e7          	jalr	-558(ra) # 908 <vprintf>
}
 b3e:	60e2                	ld	ra,24(sp)
 b40:	6442                	ld	s0,16(sp)
 b42:	6125                	addi	sp,sp,96
 b44:	8082                	ret

0000000000000b46 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 b46:	1141                	addi	sp,sp,-16
 b48:	e422                	sd	s0,8(sp)
 b4a:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 b4c:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b50:	00000797          	auipc	a5,0x0
 b54:	2a878793          	addi	a5,a5,680 # df8 <freep>
 b58:	639c                	ld	a5,0(a5)
 b5a:	a805                	j	b8a <free+0x44>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 b5c:	4618                	lw	a4,8(a2)
 b5e:	9db9                	addw	a1,a1,a4
 b60:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 b64:	6398                	ld	a4,0(a5)
 b66:	6318                	ld	a4,0(a4)
 b68:	fee53823          	sd	a4,-16(a0)
 b6c:	a091                	j	bb0 <free+0x6a>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 b6e:	ff852703          	lw	a4,-8(a0)
 b72:	9e39                	addw	a2,a2,a4
 b74:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 b76:	ff053703          	ld	a4,-16(a0)
 b7a:	e398                	sd	a4,0(a5)
 b7c:	a099                	j	bc2 <free+0x7c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b7e:	6398                	ld	a4,0(a5)
 b80:	00e7e463          	bltu	a5,a4,b88 <free+0x42>
 b84:	00e6ea63          	bltu	a3,a4,b98 <free+0x52>
{
 b88:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 b8a:	fed7fae3          	bleu	a3,a5,b7e <free+0x38>
 b8e:	6398                	ld	a4,0(a5)
 b90:	00e6e463          	bltu	a3,a4,b98 <free+0x52>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 b94:	fee7eae3          	bltu	a5,a4,b88 <free+0x42>
  if(bp + bp->s.size == p->s.ptr){
 b98:	ff852583          	lw	a1,-8(a0)
 b9c:	6390                	ld	a2,0(a5)
 b9e:	02059713          	slli	a4,a1,0x20
 ba2:	9301                	srli	a4,a4,0x20
 ba4:	0712                	slli	a4,a4,0x4
 ba6:	9736                	add	a4,a4,a3
 ba8:	fae60ae3          	beq	a2,a4,b5c <free+0x16>
    bp->s.ptr = p->s.ptr;
 bac:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 bb0:	4790                	lw	a2,8(a5)
 bb2:	02061713          	slli	a4,a2,0x20
 bb6:	9301                	srli	a4,a4,0x20
 bb8:	0712                	slli	a4,a4,0x4
 bba:	973e                	add	a4,a4,a5
 bbc:	fae689e3          	beq	a3,a4,b6e <free+0x28>
  } else
    p->s.ptr = bp;
 bc0:	e394                	sd	a3,0(a5)
  freep = p;
 bc2:	00000717          	auipc	a4,0x0
 bc6:	22f73b23          	sd	a5,566(a4) # df8 <freep>
}
 bca:	6422                	ld	s0,8(sp)
 bcc:	0141                	addi	sp,sp,16
 bce:	8082                	ret

0000000000000bd0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 bd0:	7139                	addi	sp,sp,-64
 bd2:	fc06                	sd	ra,56(sp)
 bd4:	f822                	sd	s0,48(sp)
 bd6:	f426                	sd	s1,40(sp)
 bd8:	f04a                	sd	s2,32(sp)
 bda:	ec4e                	sd	s3,24(sp)
 bdc:	e852                	sd	s4,16(sp)
 bde:	e456                	sd	s5,8(sp)
 be0:	e05a                	sd	s6,0(sp)
 be2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 be4:	02051993          	slli	s3,a0,0x20
 be8:	0209d993          	srli	s3,s3,0x20
 bec:	09bd                	addi	s3,s3,15
 bee:	0049d993          	srli	s3,s3,0x4
 bf2:	2985                	addiw	s3,s3,1
 bf4:	0009891b          	sext.w	s2,s3
  if((prevp = freep) == 0){
 bf8:	00000797          	auipc	a5,0x0
 bfc:	20078793          	addi	a5,a5,512 # df8 <freep>
 c00:	6388                	ld	a0,0(a5)
 c02:	c515                	beqz	a0,c2e <malloc+0x5e>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c04:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c06:	4798                	lw	a4,8(a5)
 c08:	03277f63          	bleu	s2,a4,c46 <malloc+0x76>
 c0c:	8a4e                	mv	s4,s3
 c0e:	0009871b          	sext.w	a4,s3
 c12:	6685                	lui	a3,0x1
 c14:	00d77363          	bleu	a3,a4,c1a <malloc+0x4a>
 c18:	6a05                	lui	s4,0x1
 c1a:	000a0a9b          	sext.w	s5,s4
  p = sbrk(nu * sizeof(Header));
 c1e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 c22:	00000497          	auipc	s1,0x0
 c26:	1d648493          	addi	s1,s1,470 # df8 <freep>
  if(p == (char*)-1)
 c2a:	5b7d                	li	s6,-1
 c2c:	a885                	j	c9c <malloc+0xcc>
    base.s.ptr = freep = prevp = &base;
 c2e:	00008797          	auipc	a5,0x8
 c32:	3d278793          	addi	a5,a5,978 # 9000 <base>
 c36:	00000717          	auipc	a4,0x0
 c3a:	1cf73123          	sd	a5,450(a4) # df8 <freep>
 c3e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 c40:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 c44:	b7e1                	j	c0c <malloc+0x3c>
      if(p->s.size == nunits)
 c46:	02e90b63          	beq	s2,a4,c7c <malloc+0xac>
        p->s.size -= nunits;
 c4a:	4137073b          	subw	a4,a4,s3
 c4e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 c50:	1702                	slli	a4,a4,0x20
 c52:	9301                	srli	a4,a4,0x20
 c54:	0712                	slli	a4,a4,0x4
 c56:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 c58:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 c5c:	00000717          	auipc	a4,0x0
 c60:	18a73e23          	sd	a0,412(a4) # df8 <freep>
      return (void*)(p + 1);
 c64:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 c68:	70e2                	ld	ra,56(sp)
 c6a:	7442                	ld	s0,48(sp)
 c6c:	74a2                	ld	s1,40(sp)
 c6e:	7902                	ld	s2,32(sp)
 c70:	69e2                	ld	s3,24(sp)
 c72:	6a42                	ld	s4,16(sp)
 c74:	6aa2                	ld	s5,8(sp)
 c76:	6b02                	ld	s6,0(sp)
 c78:	6121                	addi	sp,sp,64
 c7a:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 c7c:	6398                	ld	a4,0(a5)
 c7e:	e118                	sd	a4,0(a0)
 c80:	bff1                	j	c5c <malloc+0x8c>
  hp->s.size = nu;
 c82:	01552423          	sw	s5,8(a0)
  free((void*)(hp + 1));
 c86:	0541                	addi	a0,a0,16
 c88:	00000097          	auipc	ra,0x0
 c8c:	ebe080e7          	jalr	-322(ra) # b46 <free>
  return freep;
 c90:	6088                	ld	a0,0(s1)
      if((p = morecore(nunits)) == 0)
 c92:	d979                	beqz	a0,c68 <malloc+0x98>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 c94:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 c96:	4798                	lw	a4,8(a5)
 c98:	fb2777e3          	bleu	s2,a4,c46 <malloc+0x76>
    if(p == freep)
 c9c:	6098                	ld	a4,0(s1)
 c9e:	853e                	mv	a0,a5
 ca0:	fef71ae3          	bne	a4,a5,c94 <malloc+0xc4>
  p = sbrk(nu * sizeof(Header));
 ca4:	8552                	mv	a0,s4
 ca6:	00000097          	auipc	ra,0x0
 caa:	b7a080e7          	jalr	-1158(ra) # 820 <sbrk>
  if(p == (char*)-1)
 cae:	fd651ae3          	bne	a0,s6,c82 <malloc+0xb2>
        return 0;
 cb2:	4501                	li	a0,0
 cb4:	bf55                	j	c68 <malloc+0x98>
