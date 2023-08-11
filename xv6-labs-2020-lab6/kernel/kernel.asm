
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	88013103          	ld	sp,-1920(sp) # 80008880 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	072000ef          	jal	ra,80000088 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	2781                	sext.w	a5,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000028:	0037969b          	slliw	a3,a5,0x3
    8000002c:	02004737          	lui	a4,0x2004
    80000030:	96ba                	add	a3,a3,a4
    80000032:	0200c737          	lui	a4,0x200c
    80000036:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003a:	000f4737          	lui	a4,0xf4
    8000003e:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000042:	963a                	add	a2,a2,a4
    80000044:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000046:	0057979b          	slliw	a5,a5,0x5
    8000004a:	078e                	slli	a5,a5,0x3
    8000004c:	00009617          	auipc	a2,0x9
    80000050:	fe460613          	addi	a2,a2,-28 # 80009030 <mscratch0>
    80000054:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000056:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000058:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005a:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005e:	00006797          	auipc	a5,0x6
    80000062:	f4278793          	addi	a5,a5,-190 # 80005fa0 <timervec>
    80000066:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006a:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006e:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000072:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000076:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007a:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007e:	30479073          	csrw	mie,a5
}
    80000082:	6422                	ld	s0,8(sp)
    80000084:	0141                	addi	sp,sp,16
    80000086:	8082                	ret

0000000080000088 <start>:
{
    80000088:	1141                	addi	sp,sp,-16
    8000008a:	e406                	sd	ra,8(sp)
    8000008c:	e022                	sd	s0,0(sp)
    8000008e:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000090:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000094:	7779                	lui	a4,0xffffe
    80000096:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ff987ff>
    8000009a:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009c:	6705                	lui	a4,0x1
    8000009e:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a4:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a8:	00001797          	auipc	a5,0x1
    800000ac:	fca78793          	addi	a5,a5,-54 # 80001072 <main>
    800000b0:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b4:	4781                	li	a5,0
    800000b6:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000ba:	67c1                	lui	a5,0x10
    800000bc:	17fd                	addi	a5,a5,-1
    800000be:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c2:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c6:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ca:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000ce:	10479073          	csrw	sie,a5
  timerinit();
    800000d2:	00000097          	auipc	ra,0x0
    800000d6:	f4a080e7          	jalr	-182(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000da:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000de:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e0:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e2:	30200073          	mret
}
    800000e6:	60a2                	ld	ra,8(sp)
    800000e8:	6402                	ld	s0,0(sp)
    800000ea:	0141                	addi	sp,sp,16
    800000ec:	8082                	ret

00000000800000ee <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ee:	715d                	addi	sp,sp,-80
    800000f0:	e486                	sd	ra,72(sp)
    800000f2:	e0a2                	sd	s0,64(sp)
    800000f4:	fc26                	sd	s1,56(sp)
    800000f6:	f84a                	sd	s2,48(sp)
    800000f8:	f44e                	sd	s3,40(sp)
    800000fa:	f052                	sd	s4,32(sp)
    800000fc:	ec56                	sd	s5,24(sp)
    800000fe:	0880                	addi	s0,sp,80
    80000100:	8a2a                	mv	s4,a0
    80000102:	892e                	mv	s2,a1
    80000104:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000106:	00011517          	auipc	a0,0x11
    8000010a:	72a50513          	addi	a0,a0,1834 # 80011830 <cons>
    8000010e:	00001097          	auipc	ra,0x1
    80000112:	c94080e7          	jalr	-876(ra) # 80000da2 <acquire>
  for(i = 0; i < n; i++){
    80000116:	05305b63          	blez	s3,8000016c <consolewrite+0x7e>
    8000011a:	4481                	li	s1,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011c:	5afd                	li	s5,-1
    8000011e:	4685                	li	a3,1
    80000120:	864a                	mv	a2,s2
    80000122:	85d2                	mv	a1,s4
    80000124:	fbf40513          	addi	a0,s0,-65
    80000128:	00002097          	auipc	ra,0x2
    8000012c:	676080e7          	jalr	1654(ra) # 8000279e <either_copyin>
    80000130:	01550c63          	beq	a0,s5,80000148 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000134:	fbf44503          	lbu	a0,-65(s0)
    80000138:	00000097          	auipc	ra,0x0
    8000013c:	7ee080e7          	jalr	2030(ra) # 80000926 <uartputc>
  for(i = 0; i < n; i++){
    80000140:	2485                	addiw	s1,s1,1
    80000142:	0905                	addi	s2,s2,1
    80000144:	fc999de3          	bne	s3,s1,8000011e <consolewrite+0x30>
  }
  release(&cons.lock);
    80000148:	00011517          	auipc	a0,0x11
    8000014c:	6e850513          	addi	a0,a0,1768 # 80011830 <cons>
    80000150:	00001097          	auipc	ra,0x1
    80000154:	d06080e7          	jalr	-762(ra) # 80000e56 <release>

  return i;
}
    80000158:	8526                	mv	a0,s1
    8000015a:	60a6                	ld	ra,72(sp)
    8000015c:	6406                	ld	s0,64(sp)
    8000015e:	74e2                	ld	s1,56(sp)
    80000160:	7942                	ld	s2,48(sp)
    80000162:	79a2                	ld	s3,40(sp)
    80000164:	7a02                	ld	s4,32(sp)
    80000166:	6ae2                	ld	s5,24(sp)
    80000168:	6161                	addi	sp,sp,80
    8000016a:	8082                	ret
  for(i = 0; i < n; i++){
    8000016c:	4481                	li	s1,0
    8000016e:	bfe9                	j	80000148 <consolewrite+0x5a>

0000000080000170 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000170:	7119                	addi	sp,sp,-128
    80000172:	fc86                	sd	ra,120(sp)
    80000174:	f8a2                	sd	s0,112(sp)
    80000176:	f4a6                	sd	s1,104(sp)
    80000178:	f0ca                	sd	s2,96(sp)
    8000017a:	ecce                	sd	s3,88(sp)
    8000017c:	e8d2                	sd	s4,80(sp)
    8000017e:	e4d6                	sd	s5,72(sp)
    80000180:	e0da                	sd	s6,64(sp)
    80000182:	fc5e                	sd	s7,56(sp)
    80000184:	f862                	sd	s8,48(sp)
    80000186:	f466                	sd	s9,40(sp)
    80000188:	f06a                	sd	s10,32(sp)
    8000018a:	ec6e                	sd	s11,24(sp)
    8000018c:	0100                	addi	s0,sp,128
    8000018e:	8caa                	mv	s9,a0
    80000190:	8aae                	mv	s5,a1
    80000192:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000194:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    80000198:	00011517          	auipc	a0,0x11
    8000019c:	69850513          	addi	a0,a0,1688 # 80011830 <cons>
    800001a0:	00001097          	auipc	ra,0x1
    800001a4:	c02080e7          	jalr	-1022(ra) # 80000da2 <acquire>
  while(n > 0){
    800001a8:	09405663          	blez	s4,80000234 <consoleread+0xc4>
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ac:	00011497          	auipc	s1,0x11
    800001b0:	68448493          	addi	s1,s1,1668 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b4:	89a6                	mv	s3,s1
    800001b6:	00011917          	auipc	s2,0x11
    800001ba:	71290913          	addi	s2,s2,1810 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001be:	4c11                	li	s8,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c2:	4da9                	li	s11,10
    while(cons.r == cons.w){
    800001c4:	0984a783          	lw	a5,152(s1)
    800001c8:	09c4a703          	lw	a4,156(s1)
    800001cc:	02f71463          	bne	a4,a5,800001f4 <consoleread+0x84>
      if(myproc()->killed){
    800001d0:	00002097          	auipc	ra,0x2
    800001d4:	afc080e7          	jalr	-1284(ra) # 80001ccc <myproc>
    800001d8:	591c                	lw	a5,48(a0)
    800001da:	eba5                	bnez	a5,8000024a <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001dc:	85ce                	mv	a1,s3
    800001de:	854a                	mv	a0,s2
    800001e0:	00002097          	auipc	ra,0x2
    800001e4:	306080e7          	jalr	774(ra) # 800024e6 <sleep>
    while(cons.r == cons.w){
    800001e8:	0984a783          	lw	a5,152(s1)
    800001ec:	09c4a703          	lw	a4,156(s1)
    800001f0:	fef700e3          	beq	a4,a5,800001d0 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f4:	0017871b          	addiw	a4,a5,1
    800001f8:	08e4ac23          	sw	a4,152(s1)
    800001fc:	07f7f713          	andi	a4,a5,127
    80000200:	9726                	add	a4,a4,s1
    80000202:	01874703          	lbu	a4,24(a4)
    80000206:	00070b9b          	sext.w	s7,a4
    if(c == C('D')){  // end-of-file
    8000020a:	078b8863          	beq	s7,s8,8000027a <consoleread+0x10a>
    cbuf = c;
    8000020e:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000212:	4685                	li	a3,1
    80000214:	f8f40613          	addi	a2,s0,-113
    80000218:	85d6                	mv	a1,s5
    8000021a:	8566                	mv	a0,s9
    8000021c:	00002097          	auipc	ra,0x2
    80000220:	52c080e7          	jalr	1324(ra) # 80002748 <either_copyout>
    80000224:	01a50863          	beq	a0,s10,80000234 <consoleread+0xc4>
    dst++;
    80000228:	0a85                	addi	s5,s5,1
    --n;
    8000022a:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022c:	01bb8463          	beq	s7,s11,80000234 <consoleread+0xc4>
  while(n > 0){
    80000230:	f80a1ae3          	bnez	s4,800001c4 <consoleread+0x54>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000234:	00011517          	auipc	a0,0x11
    80000238:	5fc50513          	addi	a0,a0,1532 # 80011830 <cons>
    8000023c:	00001097          	auipc	ra,0x1
    80000240:	c1a080e7          	jalr	-998(ra) # 80000e56 <release>

  return target - n;
    80000244:	414b053b          	subw	a0,s6,s4
    80000248:	a811                	j	8000025c <consoleread+0xec>
        release(&cons.lock);
    8000024a:	00011517          	auipc	a0,0x11
    8000024e:	5e650513          	addi	a0,a0,1510 # 80011830 <cons>
    80000252:	00001097          	auipc	ra,0x1
    80000256:	c04080e7          	jalr	-1020(ra) # 80000e56 <release>
        return -1;
    8000025a:	557d                	li	a0,-1
}
    8000025c:	70e6                	ld	ra,120(sp)
    8000025e:	7446                	ld	s0,112(sp)
    80000260:	74a6                	ld	s1,104(sp)
    80000262:	7906                	ld	s2,96(sp)
    80000264:	69e6                	ld	s3,88(sp)
    80000266:	6a46                	ld	s4,80(sp)
    80000268:	6aa6                	ld	s5,72(sp)
    8000026a:	6b06                	ld	s6,64(sp)
    8000026c:	7be2                	ld	s7,56(sp)
    8000026e:	7c42                	ld	s8,48(sp)
    80000270:	7ca2                	ld	s9,40(sp)
    80000272:	7d02                	ld	s10,32(sp)
    80000274:	6de2                	ld	s11,24(sp)
    80000276:	6109                	addi	sp,sp,128
    80000278:	8082                	ret
      if(n < target){
    8000027a:	000a071b          	sext.w	a4,s4
    8000027e:	fb677be3          	bleu	s6,a4,80000234 <consoleread+0xc4>
        cons.r--;
    80000282:	00011717          	auipc	a4,0x11
    80000286:	64f72323          	sw	a5,1606(a4) # 800118c8 <cons+0x98>
    8000028a:	b76d                	j	80000234 <consoleread+0xc4>

000000008000028c <consputc>:
{
    8000028c:	1141                	addi	sp,sp,-16
    8000028e:	e406                	sd	ra,8(sp)
    80000290:	e022                	sd	s0,0(sp)
    80000292:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000294:	10000793          	li	a5,256
    80000298:	00f50a63          	beq	a0,a5,800002ac <consputc+0x20>
    uartputc_sync(c);
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	58a080e7          	jalr	1418(ra) # 80000826 <uartputc_sync>
}
    800002a4:	60a2                	ld	ra,8(sp)
    800002a6:	6402                	ld	s0,0(sp)
    800002a8:	0141                	addi	sp,sp,16
    800002aa:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	578080e7          	jalr	1400(ra) # 80000826 <uartputc_sync>
    800002b6:	02000513          	li	a0,32
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	56c080e7          	jalr	1388(ra) # 80000826 <uartputc_sync>
    800002c2:	4521                	li	a0,8
    800002c4:	00000097          	auipc	ra,0x0
    800002c8:	562080e7          	jalr	1378(ra) # 80000826 <uartputc_sync>
    800002cc:	bfe1                	j	800002a4 <consputc+0x18>

00000000800002ce <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ce:	1101                	addi	sp,sp,-32
    800002d0:	ec06                	sd	ra,24(sp)
    800002d2:	e822                	sd	s0,16(sp)
    800002d4:	e426                	sd	s1,8(sp)
    800002d6:	e04a                	sd	s2,0(sp)
    800002d8:	1000                	addi	s0,sp,32
    800002da:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002dc:	00011517          	auipc	a0,0x11
    800002e0:	55450513          	addi	a0,a0,1364 # 80011830 <cons>
    800002e4:	00001097          	auipc	ra,0x1
    800002e8:	abe080e7          	jalr	-1346(ra) # 80000da2 <acquire>

  switch(c){
    800002ec:	47c1                	li	a5,16
    800002ee:	12f48463          	beq	s1,a5,80000416 <consoleintr+0x148>
    800002f2:	0297df63          	ble	s1,a5,80000330 <consoleintr+0x62>
    800002f6:	47d5                	li	a5,21
    800002f8:	0af48863          	beq	s1,a5,800003a8 <consoleintr+0xda>
    800002fc:	07f00793          	li	a5,127
    80000300:	02f49b63          	bne	s1,a5,80000336 <consoleintr+0x68>
      consputc(BACKSPACE);
    }
    break;
  case C('H'): // Backspace
  case '\x7f':
    if(cons.e != cons.w){
    80000304:	00011717          	auipc	a4,0x11
    80000308:	52c70713          	addi	a4,a4,1324 # 80011830 <cons>
    8000030c:	0a072783          	lw	a5,160(a4)
    80000310:	09c72703          	lw	a4,156(a4)
    80000314:	10f70563          	beq	a4,a5,8000041e <consoleintr+0x150>
      cons.e--;
    80000318:	37fd                	addiw	a5,a5,-1
    8000031a:	00011717          	auipc	a4,0x11
    8000031e:	5af72b23          	sw	a5,1462(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    80000322:	10000513          	li	a0,256
    80000326:	00000097          	auipc	ra,0x0
    8000032a:	f66080e7          	jalr	-154(ra) # 8000028c <consputc>
    8000032e:	a8c5                	j	8000041e <consoleintr+0x150>
  switch(c){
    80000330:	47a1                	li	a5,8
    80000332:	fcf489e3          	beq	s1,a5,80000304 <consoleintr+0x36>
    }
    break;
  default:
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000336:	c4e5                	beqz	s1,8000041e <consoleintr+0x150>
    80000338:	00011717          	auipc	a4,0x11
    8000033c:	4f870713          	addi	a4,a4,1272 # 80011830 <cons>
    80000340:	0a072783          	lw	a5,160(a4)
    80000344:	09872703          	lw	a4,152(a4)
    80000348:	9f99                	subw	a5,a5,a4
    8000034a:	07f00713          	li	a4,127
    8000034e:	0cf76863          	bltu	a4,a5,8000041e <consoleintr+0x150>
      c = (c == '\r') ? '\n' : c;
    80000352:	47b5                	li	a5,13
    80000354:	0ef48363          	beq	s1,a5,8000043a <consoleintr+0x16c>

      // echo back to the user.
      consputc(c);
    80000358:	8526                	mv	a0,s1
    8000035a:	00000097          	auipc	ra,0x0
    8000035e:	f32080e7          	jalr	-206(ra) # 8000028c <consputc>

      // store for consumption by consoleread().
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000362:	00011797          	auipc	a5,0x11
    80000366:	4ce78793          	addi	a5,a5,1230 # 80011830 <cons>
    8000036a:	0a07a703          	lw	a4,160(a5)
    8000036e:	0017069b          	addiw	a3,a4,1
    80000372:	0006861b          	sext.w	a2,a3
    80000376:	0ad7a023          	sw	a3,160(a5)
    8000037a:	07f77713          	andi	a4,a4,127
    8000037e:	97ba                	add	a5,a5,a4
    80000380:	00978c23          	sb	s1,24(a5)

      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000384:	47a9                	li	a5,10
    80000386:	0ef48163          	beq	s1,a5,80000468 <consoleintr+0x19a>
    8000038a:	4791                	li	a5,4
    8000038c:	0cf48e63          	beq	s1,a5,80000468 <consoleintr+0x19a>
    80000390:	00011797          	auipc	a5,0x11
    80000394:	4a078793          	addi	a5,a5,1184 # 80011830 <cons>
    80000398:	0987a783          	lw	a5,152(a5)
    8000039c:	0807879b          	addiw	a5,a5,128
    800003a0:	06f61f63          	bne	a2,a5,8000041e <consoleintr+0x150>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    800003a4:	863e                	mv	a2,a5
    800003a6:	a0c9                	j	80000468 <consoleintr+0x19a>
    while(cons.e != cons.w &&
    800003a8:	00011717          	auipc	a4,0x11
    800003ac:	48870713          	addi	a4,a4,1160 # 80011830 <cons>
    800003b0:	0a072783          	lw	a5,160(a4)
    800003b4:	09c72703          	lw	a4,156(a4)
    800003b8:	06f70363          	beq	a4,a5,8000041e <consoleintr+0x150>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003bc:	37fd                	addiw	a5,a5,-1
    800003be:	0007871b          	sext.w	a4,a5
    800003c2:	07f7f793          	andi	a5,a5,127
    800003c6:	00011697          	auipc	a3,0x11
    800003ca:	46a68693          	addi	a3,a3,1130 # 80011830 <cons>
    800003ce:	97b6                	add	a5,a5,a3
    while(cons.e != cons.w &&
    800003d0:	0187c683          	lbu	a3,24(a5)
    800003d4:	47a9                	li	a5,10
      cons.e--;
    800003d6:	00011497          	auipc	s1,0x11
    800003da:	45a48493          	addi	s1,s1,1114 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003de:	4929                	li	s2,10
    800003e0:	02f68f63          	beq	a3,a5,8000041e <consoleintr+0x150>
      cons.e--;
    800003e4:	0ae4a023          	sw	a4,160(s1)
      consputc(BACKSPACE);
    800003e8:	10000513          	li	a0,256
    800003ec:	00000097          	auipc	ra,0x0
    800003f0:	ea0080e7          	jalr	-352(ra) # 8000028c <consputc>
    while(cons.e != cons.w &&
    800003f4:	0a04a783          	lw	a5,160(s1)
    800003f8:	09c4a703          	lw	a4,156(s1)
    800003fc:	02f70163          	beq	a4,a5,8000041e <consoleintr+0x150>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    80000400:	37fd                	addiw	a5,a5,-1
    80000402:	0007871b          	sext.w	a4,a5
    80000406:	07f7f793          	andi	a5,a5,127
    8000040a:	97a6                	add	a5,a5,s1
    while(cons.e != cons.w &&
    8000040c:	0187c783          	lbu	a5,24(a5)
    80000410:	fd279ae3          	bne	a5,s2,800003e4 <consoleintr+0x116>
    80000414:	a029                	j	8000041e <consoleintr+0x150>
    procdump();
    80000416:	00002097          	auipc	ra,0x2
    8000041a:	3de080e7          	jalr	990(ra) # 800027f4 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000041e:	00011517          	auipc	a0,0x11
    80000422:	41250513          	addi	a0,a0,1042 # 80011830 <cons>
    80000426:	00001097          	auipc	ra,0x1
    8000042a:	a30080e7          	jalr	-1488(ra) # 80000e56 <release>
}
    8000042e:	60e2                	ld	ra,24(sp)
    80000430:	6442                	ld	s0,16(sp)
    80000432:	64a2                	ld	s1,8(sp)
    80000434:	6902                	ld	s2,0(sp)
    80000436:	6105                	addi	sp,sp,32
    80000438:	8082                	ret
      consputc(c);
    8000043a:	4529                	li	a0,10
    8000043c:	00000097          	auipc	ra,0x0
    80000440:	e50080e7          	jalr	-432(ra) # 8000028c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000444:	00011797          	auipc	a5,0x11
    80000448:	3ec78793          	addi	a5,a5,1004 # 80011830 <cons>
    8000044c:	0a07a703          	lw	a4,160(a5)
    80000450:	0017069b          	addiw	a3,a4,1
    80000454:	0006861b          	sext.w	a2,a3
    80000458:	0ad7a023          	sw	a3,160(a5)
    8000045c:	07f77713          	andi	a4,a4,127
    80000460:	97ba                	add	a5,a5,a4
    80000462:	4729                	li	a4,10
    80000464:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000468:	00011797          	auipc	a5,0x11
    8000046c:	46c7a223          	sw	a2,1124(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000470:	00011517          	auipc	a0,0x11
    80000474:	45850513          	addi	a0,a0,1112 # 800118c8 <cons+0x98>
    80000478:	00002097          	auipc	ra,0x2
    8000047c:	1f4080e7          	jalr	500(ra) # 8000266c <wakeup>
    80000480:	bf79                	j	8000041e <consoleintr+0x150>

0000000080000482 <consoleinit>:

void
consoleinit(void)
{
    80000482:	1141                	addi	sp,sp,-16
    80000484:	e406                	sd	ra,8(sp)
    80000486:	e022                	sd	s0,0(sp)
    80000488:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000048a:	00008597          	auipc	a1,0x8
    8000048e:	b8658593          	addi	a1,a1,-1146 # 80008010 <etext+0x10>
    80000492:	00011517          	auipc	a0,0x11
    80000496:	39e50513          	addi	a0,a0,926 # 80011830 <cons>
    8000049a:	00001097          	auipc	ra,0x1
    8000049e:	878080e7          	jalr	-1928(ra) # 80000d12 <initlock>

  uartinit();
    800004a2:	00000097          	auipc	ra,0x0
    800004a6:	334080e7          	jalr	820(ra) # 800007d6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    800004aa:	00061797          	auipc	a5,0x61
    800004ae:	50678793          	addi	a5,a5,1286 # 800619b0 <devsw>
    800004b2:	00000717          	auipc	a4,0x0
    800004b6:	cbe70713          	addi	a4,a4,-834 # 80000170 <consoleread>
    800004ba:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004bc:	00000717          	auipc	a4,0x0
    800004c0:	c3270713          	addi	a4,a4,-974 # 800000ee <consolewrite>
    800004c4:	ef98                	sd	a4,24(a5)
}
    800004c6:	60a2                	ld	ra,8(sp)
    800004c8:	6402                	ld	s0,0(sp)
    800004ca:	0141                	addi	sp,sp,16
    800004cc:	8082                	ret

00000000800004ce <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ce:	7179                	addi	sp,sp,-48
    800004d0:	f406                	sd	ra,40(sp)
    800004d2:	f022                	sd	s0,32(sp)
    800004d4:	ec26                	sd	s1,24(sp)
    800004d6:	e84a                	sd	s2,16(sp)
    800004d8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004da:	c219                	beqz	a2,800004e0 <printint+0x12>
    800004dc:	00054d63          	bltz	a0,800004f6 <printint+0x28>
    x = -xx;
  else
    x = xx;
    800004e0:	2501                	sext.w	a0,a0
    800004e2:	4881                	li	a7,0
    800004e4:	fd040713          	addi	a4,s0,-48

  i = 0;
    800004e8:	4601                	li	a2,0
  do {
    buf[i++] = digits[x % base];
    800004ea:	2581                	sext.w	a1,a1
    800004ec:	00008817          	auipc	a6,0x8
    800004f0:	b2c80813          	addi	a6,a6,-1236 # 80008018 <digits>
    800004f4:	a801                	j	80000504 <printint+0x36>
    x = -xx;
    800004f6:	40a0053b          	negw	a0,a0
    800004fa:	2501                	sext.w	a0,a0
  if(sign && (sign = xx < 0))
    800004fc:	4885                	li	a7,1
    x = -xx;
    800004fe:	b7dd                	j	800004e4 <printint+0x16>
  } while((x /= base) != 0);
    80000500:	853e                	mv	a0,a5
    buf[i++] = digits[x % base];
    80000502:	8636                	mv	a2,a3
    80000504:	0016069b          	addiw	a3,a2,1
    80000508:	02b577bb          	remuw	a5,a0,a1
    8000050c:	1782                	slli	a5,a5,0x20
    8000050e:	9381                	srli	a5,a5,0x20
    80000510:	97c2                	add	a5,a5,a6
    80000512:	0007c783          	lbu	a5,0(a5)
    80000516:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000051a:	0705                	addi	a4,a4,1
    8000051c:	02b557bb          	divuw	a5,a0,a1
    80000520:	feb570e3          	bleu	a1,a0,80000500 <printint+0x32>

  if(sign)
    80000524:	00088b63          	beqz	a7,8000053a <printint+0x6c>
    buf[i++] = '-';
    80000528:	fe040793          	addi	a5,s0,-32
    8000052c:	96be                	add	a3,a3,a5
    8000052e:	02d00793          	li	a5,45
    80000532:	fef68823          	sb	a5,-16(a3)
    80000536:	0026069b          	addiw	a3,a2,2

  while(--i >= 0)
    8000053a:	02d05763          	blez	a3,80000568 <printint+0x9a>
    8000053e:	fd040793          	addi	a5,s0,-48
    80000542:	00d784b3          	add	s1,a5,a3
    80000546:	fff78913          	addi	s2,a5,-1
    8000054a:	9936                	add	s2,s2,a3
    8000054c:	36fd                	addiw	a3,a3,-1
    8000054e:	1682                	slli	a3,a3,0x20
    80000550:	9281                	srli	a3,a3,0x20
    80000552:	40d90933          	sub	s2,s2,a3
    consputc(buf[i]);
    80000556:	fff4c503          	lbu	a0,-1(s1)
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	d32080e7          	jalr	-718(ra) # 8000028c <consputc>
  while(--i >= 0)
    80000562:	14fd                	addi	s1,s1,-1
    80000564:	ff2499e3          	bne	s1,s2,80000556 <printint+0x88>
}
    80000568:	70a2                	ld	ra,40(sp)
    8000056a:	7402                	ld	s0,32(sp)
    8000056c:	64e2                	ld	s1,24(sp)
    8000056e:	6942                	ld	s2,16(sp)
    80000570:	6145                	addi	sp,sp,48
    80000572:	8082                	ret

0000000080000574 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000574:	1101                	addi	sp,sp,-32
    80000576:	ec06                	sd	ra,24(sp)
    80000578:	e822                	sd	s0,16(sp)
    8000057a:	e426                	sd	s1,8(sp)
    8000057c:	1000                	addi	s0,sp,32
    8000057e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000580:	00011797          	auipc	a5,0x11
    80000584:	3607a823          	sw	zero,880(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    80000588:	00008517          	auipc	a0,0x8
    8000058c:	aa850513          	addi	a0,a0,-1368 # 80008030 <digits+0x18>
    80000590:	00000097          	auipc	ra,0x0
    80000594:	02e080e7          	jalr	46(ra) # 800005be <printf>
  printf(s);
    80000598:	8526                	mv	a0,s1
    8000059a:	00000097          	auipc	ra,0x0
    8000059e:	024080e7          	jalr	36(ra) # 800005be <printf>
  printf("\n");
    800005a2:	00008517          	auipc	a0,0x8
    800005a6:	b2650513          	addi	a0,a0,-1242 # 800080c8 <digits+0xb0>
    800005aa:	00000097          	auipc	ra,0x0
    800005ae:	014080e7          	jalr	20(ra) # 800005be <printf>
  panicked = 1; // freeze uart output from other CPUs
    800005b2:	4785                	li	a5,1
    800005b4:	00009717          	auipc	a4,0x9
    800005b8:	a4f72623          	sw	a5,-1460(a4) # 80009000 <panicked>
  for(;;)
    800005bc:	a001                	j	800005bc <panic+0x48>

00000000800005be <printf>:
{
    800005be:	7131                	addi	sp,sp,-192
    800005c0:	fc86                	sd	ra,120(sp)
    800005c2:	f8a2                	sd	s0,112(sp)
    800005c4:	f4a6                	sd	s1,104(sp)
    800005c6:	f0ca                	sd	s2,96(sp)
    800005c8:	ecce                	sd	s3,88(sp)
    800005ca:	e8d2                	sd	s4,80(sp)
    800005cc:	e4d6                	sd	s5,72(sp)
    800005ce:	e0da                	sd	s6,64(sp)
    800005d0:	fc5e                	sd	s7,56(sp)
    800005d2:	f862                	sd	s8,48(sp)
    800005d4:	f466                	sd	s9,40(sp)
    800005d6:	f06a                	sd	s10,32(sp)
    800005d8:	ec6e                	sd	s11,24(sp)
    800005da:	0100                	addi	s0,sp,128
    800005dc:	8aaa                	mv	s5,a0
    800005de:	e40c                	sd	a1,8(s0)
    800005e0:	e810                	sd	a2,16(s0)
    800005e2:	ec14                	sd	a3,24(s0)
    800005e4:	f018                	sd	a4,32(s0)
    800005e6:	f41c                	sd	a5,40(s0)
    800005e8:	03043823          	sd	a6,48(s0)
    800005ec:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005f0:	00011797          	auipc	a5,0x11
    800005f4:	2e878793          	addi	a5,a5,744 # 800118d8 <pr>
    800005f8:	0187ad83          	lw	s11,24(a5)
  if(locking)
    800005fc:	020d9b63          	bnez	s11,80000632 <printf+0x74>
  if (fmt == 0)
    80000600:	020a8f63          	beqz	s5,8000063e <printf+0x80>
  va_start(ap, fmt);
    80000604:	00840793          	addi	a5,s0,8
    80000608:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000060c:	000ac503          	lbu	a0,0(s5)
    80000610:	16050063          	beqz	a0,80000770 <printf+0x1b2>
    80000614:	4481                	li	s1,0
    if(c != '%'){
    80000616:	02500a13          	li	s4,37
    switch(c){
    8000061a:	07000b13          	li	s6,112
  consputc('x');
    8000061e:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000620:	00008b97          	auipc	s7,0x8
    80000624:	9f8b8b93          	addi	s7,s7,-1544 # 80008018 <digits>
    switch(c){
    80000628:	07300c93          	li	s9,115
    8000062c:	06400c13          	li	s8,100
    80000630:	a815                	j	80000664 <printf+0xa6>
    acquire(&pr.lock);
    80000632:	853e                	mv	a0,a5
    80000634:	00000097          	auipc	ra,0x0
    80000638:	76e080e7          	jalr	1902(ra) # 80000da2 <acquire>
    8000063c:	b7d1                	j	80000600 <printf+0x42>
    panic("null fmt");
    8000063e:	00008517          	auipc	a0,0x8
    80000642:	a0250513          	addi	a0,a0,-1534 # 80008040 <digits+0x28>
    80000646:	00000097          	auipc	ra,0x0
    8000064a:	f2e080e7          	jalr	-210(ra) # 80000574 <panic>
      consputc(c);
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	c3e080e7          	jalr	-962(ra) # 8000028c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000656:	2485                	addiw	s1,s1,1
    80000658:	009a87b3          	add	a5,s5,s1
    8000065c:	0007c503          	lbu	a0,0(a5)
    80000660:	10050863          	beqz	a0,80000770 <printf+0x1b2>
    if(c != '%'){
    80000664:	ff4515e3          	bne	a0,s4,8000064e <printf+0x90>
    c = fmt[++i] & 0xff;
    80000668:	2485                	addiw	s1,s1,1
    8000066a:	009a87b3          	add	a5,s5,s1
    8000066e:	0007c783          	lbu	a5,0(a5)
    80000672:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000676:	0e090d63          	beqz	s2,80000770 <printf+0x1b2>
    switch(c){
    8000067a:	05678a63          	beq	a5,s6,800006ce <printf+0x110>
    8000067e:	02fb7663          	bleu	a5,s6,800006aa <printf+0xec>
    80000682:	09978963          	beq	a5,s9,80000714 <printf+0x156>
    80000686:	07800713          	li	a4,120
    8000068a:	0ce79863          	bne	a5,a4,8000075a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	85ea                	mv	a1,s10
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e2e080e7          	jalr	-466(ra) # 800004ce <printint>
      break;
    800006a8:	b77d                	j	80000656 <printf+0x98>
    switch(c){
    800006aa:	0b478263          	beq	a5,s4,8000074e <printf+0x190>
    800006ae:	0b879663          	bne	a5,s8,8000075a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4605                	li	a2,1
    800006c0:	45a9                	li	a1,10
    800006c2:	4388                	lw	a0,0(a5)
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	e0a080e7          	jalr	-502(ra) # 800004ce <printint>
      break;
    800006cc:	b769                	j	80000656 <printf+0x98>
      printptr(va_arg(ap, uint64));
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006de:	03000513          	li	a0,48
    800006e2:	00000097          	auipc	ra,0x0
    800006e6:	baa080e7          	jalr	-1110(ra) # 8000028c <consputc>
  consputc('x');
    800006ea:	07800513          	li	a0,120
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	b9e080e7          	jalr	-1122(ra) # 8000028c <consputc>
    800006f6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006f8:	03c9d793          	srli	a5,s3,0x3c
    800006fc:	97de                	add	a5,a5,s7
    800006fe:	0007c503          	lbu	a0,0(a5)
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b8a080e7          	jalr	-1142(ra) # 8000028c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000070a:	0992                	slli	s3,s3,0x4
    8000070c:	397d                	addiw	s2,s2,-1
    8000070e:	fe0915e3          	bnez	s2,800006f8 <printf+0x13a>
    80000712:	b791                	j	80000656 <printf+0x98>
      if((s = va_arg(ap, char*)) == 0)
    80000714:	f8843783          	ld	a5,-120(s0)
    80000718:	00878713          	addi	a4,a5,8
    8000071c:	f8e43423          	sd	a4,-120(s0)
    80000720:	0007b903          	ld	s2,0(a5)
    80000724:	00090e63          	beqz	s2,80000740 <printf+0x182>
      for(; *s; s++)
    80000728:	00094503          	lbu	a0,0(s2)
    8000072c:	d50d                	beqz	a0,80000656 <printf+0x98>
        consputc(*s);
    8000072e:	00000097          	auipc	ra,0x0
    80000732:	b5e080e7          	jalr	-1186(ra) # 8000028c <consputc>
      for(; *s; s++)
    80000736:	0905                	addi	s2,s2,1
    80000738:	00094503          	lbu	a0,0(s2)
    8000073c:	f96d                	bnez	a0,8000072e <printf+0x170>
    8000073e:	bf21                	j	80000656 <printf+0x98>
        s = "(null)";
    80000740:	00008917          	auipc	s2,0x8
    80000744:	8f890913          	addi	s2,s2,-1800 # 80008038 <digits+0x20>
      for(; *s; s++)
    80000748:	02800513          	li	a0,40
    8000074c:	b7cd                	j	8000072e <printf+0x170>
      consputc('%');
    8000074e:	8552                	mv	a0,s4
    80000750:	00000097          	auipc	ra,0x0
    80000754:	b3c080e7          	jalr	-1220(ra) # 8000028c <consputc>
      break;
    80000758:	bdfd                	j	80000656 <printf+0x98>
      consputc('%');
    8000075a:	8552                	mv	a0,s4
    8000075c:	00000097          	auipc	ra,0x0
    80000760:	b30080e7          	jalr	-1232(ra) # 8000028c <consputc>
      consputc(c);
    80000764:	854a                	mv	a0,s2
    80000766:	00000097          	auipc	ra,0x0
    8000076a:	b26080e7          	jalr	-1242(ra) # 8000028c <consputc>
      break;
    8000076e:	b5e5                	j	80000656 <printf+0x98>
  if(locking)
    80000770:	020d9163          	bnez	s11,80000792 <printf+0x1d4>
}
    80000774:	70e6                	ld	ra,120(sp)
    80000776:	7446                	ld	s0,112(sp)
    80000778:	74a6                	ld	s1,104(sp)
    8000077a:	7906                	ld	s2,96(sp)
    8000077c:	69e6                	ld	s3,88(sp)
    8000077e:	6a46                	ld	s4,80(sp)
    80000780:	6aa6                	ld	s5,72(sp)
    80000782:	6b06                	ld	s6,64(sp)
    80000784:	7be2                	ld	s7,56(sp)
    80000786:	7c42                	ld	s8,48(sp)
    80000788:	7ca2                	ld	s9,40(sp)
    8000078a:	7d02                	ld	s10,32(sp)
    8000078c:	6de2                	ld	s11,24(sp)
    8000078e:	6129                	addi	sp,sp,192
    80000790:	8082                	ret
    release(&pr.lock);
    80000792:	00011517          	auipc	a0,0x11
    80000796:	14650513          	addi	a0,a0,326 # 800118d8 <pr>
    8000079a:	00000097          	auipc	ra,0x0
    8000079e:	6bc080e7          	jalr	1724(ra) # 80000e56 <release>
}
    800007a2:	bfc9                	j	80000774 <printf+0x1b6>

00000000800007a4 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007a4:	1101                	addi	sp,sp,-32
    800007a6:	ec06                	sd	ra,24(sp)
    800007a8:	e822                	sd	s0,16(sp)
    800007aa:	e426                	sd	s1,8(sp)
    800007ac:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007ae:	00011497          	auipc	s1,0x11
    800007b2:	12a48493          	addi	s1,s1,298 # 800118d8 <pr>
    800007b6:	00008597          	auipc	a1,0x8
    800007ba:	89a58593          	addi	a1,a1,-1894 # 80008050 <digits+0x38>
    800007be:	8526                	mv	a0,s1
    800007c0:	00000097          	auipc	ra,0x0
    800007c4:	552080e7          	jalr	1362(ra) # 80000d12 <initlock>
  pr.locking = 1;
    800007c8:	4785                	li	a5,1
    800007ca:	cc9c                	sw	a5,24(s1)
}
    800007cc:	60e2                	ld	ra,24(sp)
    800007ce:	6442                	ld	s0,16(sp)
    800007d0:	64a2                	ld	s1,8(sp)
    800007d2:	6105                	addi	sp,sp,32
    800007d4:	8082                	ret

00000000800007d6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007d6:	1141                	addi	sp,sp,-16
    800007d8:	e406                	sd	ra,8(sp)
    800007da:	e022                	sd	s0,0(sp)
    800007dc:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007de:	100007b7          	lui	a5,0x10000
    800007e2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007e6:	f8000713          	li	a4,-128
    800007ea:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ee:	470d                	li	a4,3
    800007f0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007f4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007f8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007fc:	469d                	li	a3,7
    800007fe:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000802:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000806:	00008597          	auipc	a1,0x8
    8000080a:	85258593          	addi	a1,a1,-1966 # 80008058 <digits+0x40>
    8000080e:	00011517          	auipc	a0,0x11
    80000812:	0ea50513          	addi	a0,a0,234 # 800118f8 <uart_tx_lock>
    80000816:	00000097          	auipc	ra,0x0
    8000081a:	4fc080e7          	jalr	1276(ra) # 80000d12 <initlock>
}
    8000081e:	60a2                	ld	ra,8(sp)
    80000820:	6402                	ld	s0,0(sp)
    80000822:	0141                	addi	sp,sp,16
    80000824:	8082                	ret

0000000080000826 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000826:	1101                	addi	sp,sp,-32
    80000828:	ec06                	sd	ra,24(sp)
    8000082a:	e822                	sd	s0,16(sp)
    8000082c:	e426                	sd	s1,8(sp)
    8000082e:	1000                	addi	s0,sp,32
    80000830:	84aa                	mv	s1,a0
  push_off();
    80000832:	00000097          	auipc	ra,0x0
    80000836:	524080e7          	jalr	1316(ra) # 80000d56 <push_off>

  if(panicked){
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7c678793          	addi	a5,a5,1990 # 80009000 <panicked>
    80000842:	439c                	lw	a5,0(a5)
    80000844:	2781                	sext.w	a5,a5
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000846:	10000737          	lui	a4,0x10000
  if(panicked){
    8000084a:	c391                	beqz	a5,8000084e <uartputc_sync+0x28>
    for(;;)
    8000084c:	a001                	j	8000084c <uartputc_sync+0x26>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000084e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000852:	0ff7f793          	andi	a5,a5,255
    80000856:	0207f793          	andi	a5,a5,32
    8000085a:	dbf5                	beqz	a5,8000084e <uartputc_sync+0x28>
    ;
  WriteReg(THR, c);
    8000085c:	0ff4f793          	andi	a5,s1,255
    80000860:	10000737          	lui	a4,0x10000
    80000864:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000868:	00000097          	auipc	ra,0x0
    8000086c:	58e080e7          	jalr	1422(ra) # 80000df6 <pop_off>
}
    80000870:	60e2                	ld	ra,24(sp)
    80000872:	6442                	ld	s0,16(sp)
    80000874:	64a2                	ld	s1,8(sp)
    80000876:	6105                	addi	sp,sp,32
    80000878:	8082                	ret

000000008000087a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008797          	auipc	a5,0x8
    8000087e:	78a78793          	addi	a5,a5,1930 # 80009004 <uart_tx_r>
    80000882:	439c                	lw	a5,0(a5)
    80000884:	00008717          	auipc	a4,0x8
    80000888:	78470713          	addi	a4,a4,1924 # 80009008 <uart_tx_w>
    8000088c:	4318                	lw	a4,0(a4)
    8000088e:	08f70b63          	beq	a4,a5,80000924 <uartstart+0xaa>
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000892:	10000737          	lui	a4,0x10000
    80000896:	00574703          	lbu	a4,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000089a:	0ff77713          	andi	a4,a4,255
    8000089e:	02077713          	andi	a4,a4,32
    800008a2:	c349                	beqz	a4,80000924 <uartstart+0xaa>
{
    800008a4:	7139                	addi	sp,sp,-64
    800008a6:	fc06                	sd	ra,56(sp)
    800008a8:	f822                	sd	s0,48(sp)
    800008aa:	f426                	sd	s1,40(sp)
    800008ac:	f04a                	sd	s2,32(sp)
    800008ae:	ec4e                	sd	s3,24(sp)
    800008b0:	e852                	sd	s4,16(sp)
    800008b2:	e456                	sd	s5,8(sp)
    800008b4:	0080                	addi	s0,sp,64
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008b6:	00011a17          	auipc	s4,0x11
    800008ba:	042a0a13          	addi	s4,s4,66 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008be:	00008497          	auipc	s1,0x8
    800008c2:	74648493          	addi	s1,s1,1862 # 80009004 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008c6:	10000937          	lui	s2,0x10000
    if(uart_tx_w == uart_tx_r){
    800008ca:	00008997          	auipc	s3,0x8
    800008ce:	73e98993          	addi	s3,s3,1854 # 80009008 <uart_tx_w>
    int c = uart_tx_buf[uart_tx_r];
    800008d2:	00fa0733          	add	a4,s4,a5
    800008d6:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008da:	2785                	addiw	a5,a5,1
    800008dc:	41f7d71b          	sraiw	a4,a5,0x1f
    800008e0:	01b7571b          	srliw	a4,a4,0x1b
    800008e4:	9fb9                	addw	a5,a5,a4
    800008e6:	8bfd                	andi	a5,a5,31
    800008e8:	9f99                	subw	a5,a5,a4
    800008ea:	c09c                	sw	a5,0(s1)
    wakeup(&uart_tx_r);
    800008ec:	8526                	mv	a0,s1
    800008ee:	00002097          	auipc	ra,0x2
    800008f2:	d7e080e7          	jalr	-642(ra) # 8000266c <wakeup>
    WriteReg(THR, c);
    800008f6:	01590023          	sb	s5,0(s2) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    800008fa:	409c                	lw	a5,0(s1)
    800008fc:	0009a703          	lw	a4,0(s3)
    80000900:	00f70963          	beq	a4,a5,80000912 <uartstart+0x98>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000904:	00594703          	lbu	a4,5(s2)
    80000908:	0ff77713          	andi	a4,a4,255
    8000090c:	02077713          	andi	a4,a4,32
    80000910:	f369                	bnez	a4,800008d2 <uartstart+0x58>
  }
}
    80000912:	70e2                	ld	ra,56(sp)
    80000914:	7442                	ld	s0,48(sp)
    80000916:	74a2                	ld	s1,40(sp)
    80000918:	7902                	ld	s2,32(sp)
    8000091a:	69e2                	ld	s3,24(sp)
    8000091c:	6a42                	ld	s4,16(sp)
    8000091e:	6aa2                	ld	s5,8(sp)
    80000920:	6121                	addi	sp,sp,64
    80000922:	8082                	ret
    80000924:	8082                	ret

0000000080000926 <uartputc>:
{
    80000926:	7179                	addi	sp,sp,-48
    80000928:	f406                	sd	ra,40(sp)
    8000092a:	f022                	sd	s0,32(sp)
    8000092c:	ec26                	sd	s1,24(sp)
    8000092e:	e84a                	sd	s2,16(sp)
    80000930:	e44e                	sd	s3,8(sp)
    80000932:	e052                	sd	s4,0(sp)
    80000934:	1800                	addi	s0,sp,48
    80000936:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000938:	00011517          	auipc	a0,0x11
    8000093c:	fc050513          	addi	a0,a0,-64 # 800118f8 <uart_tx_lock>
    80000940:	00000097          	auipc	ra,0x0
    80000944:	462080e7          	jalr	1122(ra) # 80000da2 <acquire>
  if(panicked){
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	6b878793          	addi	a5,a5,1720 # 80009000 <panicked>
    80000950:	439c                	lw	a5,0(a5)
    80000952:	2781                	sext.w	a5,a5
    80000954:	c391                	beqz	a5,80000958 <uartputc+0x32>
    for(;;)
    80000956:	a001                	j	80000956 <uartputc+0x30>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00008797          	auipc	a5,0x8
    8000095c:	6b078793          	addi	a5,a5,1712 # 80009008 <uart_tx_w>
    80000960:	4398                	lw	a4,0(a5)
    80000962:	0017079b          	addiw	a5,a4,1
    80000966:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096a:	01b6d69b          	srliw	a3,a3,0x1b
    8000096e:	9fb5                	addw	a5,a5,a3
    80000970:	8bfd                	andi	a5,a5,31
    80000972:	9f95                	subw	a5,a5,a3
    80000974:	00008697          	auipc	a3,0x8
    80000978:	69068693          	addi	a3,a3,1680 # 80009004 <uart_tx_r>
    8000097c:	4294                	lw	a3,0(a3)
    8000097e:	04f69263          	bne	a3,a5,800009c2 <uartputc+0x9c>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000982:	00011a17          	auipc	s4,0x11
    80000986:	f76a0a13          	addi	s4,s4,-138 # 800118f8 <uart_tx_lock>
    8000098a:	00008497          	auipc	s1,0x8
    8000098e:	67a48493          	addi	s1,s1,1658 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000992:	00008917          	auipc	s2,0x8
    80000996:	67690913          	addi	s2,s2,1654 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000099a:	85d2                	mv	a1,s4
    8000099c:	8526                	mv	a0,s1
    8000099e:	00002097          	auipc	ra,0x2
    800009a2:	b48080e7          	jalr	-1208(ra) # 800024e6 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009a6:	00092703          	lw	a4,0(s2)
    800009aa:	0017079b          	addiw	a5,a4,1
    800009ae:	41f7d69b          	sraiw	a3,a5,0x1f
    800009b2:	01b6d69b          	srliw	a3,a3,0x1b
    800009b6:	9fb5                	addw	a5,a5,a3
    800009b8:	8bfd                	andi	a5,a5,31
    800009ba:	9f95                	subw	a5,a5,a3
    800009bc:	4094                	lw	a3,0(s1)
    800009be:	fcf68ee3          	beq	a3,a5,8000099a <uartputc+0x74>
      uart_tx_buf[uart_tx_w] = c;
    800009c2:	00011497          	auipc	s1,0x11
    800009c6:	f3648493          	addi	s1,s1,-202 # 800118f8 <uart_tx_lock>
    800009ca:	9726                	add	a4,a4,s1
    800009cc:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009d0:	00008717          	auipc	a4,0x8
    800009d4:	62f72c23          	sw	a5,1592(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	ea2080e7          	jalr	-350(ra) # 8000087a <uartstart>
      release(&uart_tx_lock);
    800009e0:	8526                	mv	a0,s1
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	474080e7          	jalr	1140(ra) # 80000e56 <release>
}
    800009ea:	70a2                	ld	ra,40(sp)
    800009ec:	7402                	ld	s0,32(sp)
    800009ee:	64e2                	ld	s1,24(sp)
    800009f0:	6942                	ld	s2,16(sp)
    800009f2:	69a2                	ld	s3,8(sp)
    800009f4:	6a02                	ld	s4,0(sp)
    800009f6:	6145                	addi	sp,sp,48
    800009f8:	8082                	ret

00000000800009fa <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009fa:	1141                	addi	sp,sp,-16
    800009fc:	e422                	sd	s0,8(sp)
    800009fe:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a00:	100007b7          	lui	a5,0x10000
    80000a04:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a08:	8b85                	andi	a5,a5,1
    80000a0a:	cb91                	beqz	a5,80000a1e <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a0c:	100007b7          	lui	a5,0x10000
    80000a10:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a14:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a18:	6422                	ld	s0,8(sp)
    80000a1a:	0141                	addi	sp,sp,16
    80000a1c:	8082                	ret
    return -1;
    80000a1e:	557d                	li	a0,-1
    80000a20:	bfe5                	j	80000a18 <uartgetc+0x1e>

0000000080000a22 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a22:	1101                	addi	sp,sp,-32
    80000a24:	ec06                	sd	ra,24(sp)
    80000a26:	e822                	sd	s0,16(sp)
    80000a28:	e426                	sd	s1,8(sp)
    80000a2a:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a2c:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a2e:	00000097          	auipc	ra,0x0
    80000a32:	fcc080e7          	jalr	-52(ra) # 800009fa <uartgetc>
    if(c == -1)
    80000a36:	00950763          	beq	a0,s1,80000a44 <uartintr+0x22>
      break;
    consoleintr(c);
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	894080e7          	jalr	-1900(ra) # 800002ce <consoleintr>
  while(1){
    80000a42:	b7f5                	j	80000a2e <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a44:	00011497          	auipc	s1,0x11
    80000a48:	eb448493          	addi	s1,s1,-332 # 800118f8 <uart_tx_lock>
    80000a4c:	8526                	mv	a0,s1
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	354080e7          	jalr	852(ra) # 80000da2 <acquire>
  uartstart();
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	e24080e7          	jalr	-476(ra) # 8000087a <uartstart>
  release(&uart_tx_lock);
    80000a5e:	8526                	mv	a0,s1
    80000a60:	00000097          	auipc	ra,0x0
    80000a64:	3f6080e7          	jalr	1014(ra) # 80000e56 <release>
}
    80000a68:	60e2                	ld	ra,24(sp)
    80000a6a:	6442                	ld	s0,16(sp)
    80000a6c:	64a2                	ld	s1,8(sp)
    80000a6e:	6105                	addi	sp,sp,32
    80000a70:	8082                	ret

0000000080000a72 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a72:	1101                	addi	sp,sp,-32
    80000a74:	ec06                	sd	ra,24(sp)
    80000a76:	e822                	sd	s0,16(sp)
    80000a78:	e426                	sd	s1,8(sp)
    80000a7a:	e04a                	sd	s2,0(sp)
    80000a7c:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	17fd                	addi	a5,a5,-1
    80000a82:	8fe9                	and	a5,a5,a0
    80000a84:	ebc1                	bnez	a5,80000b14 <kfree+0xa2>
    80000a86:	84aa                	mv	s1,a0
    80000a88:	00065797          	auipc	a5,0x65
    80000a8c:	57878793          	addi	a5,a5,1400 # 80066000 <end>
    80000a90:	08f56263          	bltu	a0,a5,80000b14 <kfree+0xa2>
    80000a94:	47c5                	li	a5,17
    80000a96:	07ee                	slli	a5,a5,0x1b
    80000a98:	06f57e63          	bleu	a5,a0,80000b14 <kfree+0xa2>
    panic("kfree");

  acquire(&kmem.lock);
    80000a9c:	00011517          	auipc	a0,0x11
    80000aa0:	e9450513          	addi	a0,a0,-364 # 80011930 <kmem>
    80000aa4:	00000097          	auipc	ra,0x0
    80000aa8:	2fe080e7          	jalr	766(ra) # 80000da2 <acquire>
  pa_ref_cnt[ARR_INDEX((uint64)pa)]--;
    80000aac:	800007b7          	lui	a5,0x80000
    80000ab0:	97a6                	add	a5,a5,s1
    80000ab2:	83b1                	srli	a5,a5,0xc
    80000ab4:	078e                	slli	a5,a5,0x3
    80000ab6:	00011717          	auipc	a4,0x11
    80000aba:	e9a70713          	addi	a4,a4,-358 # 80011950 <pa_ref_cnt>
    80000abe:	97ba                	add	a5,a5,a4
    80000ac0:	6398                	ld	a4,0(a5)
    80000ac2:	177d                	addi	a4,a4,-1
    80000ac4:	e398                	sd	a4,0(a5)
  if (pa_ref_cnt[ARR_INDEX((uint64)pa)] > 0) {
    80000ac6:	04e04f63          	bgtz	a4,80000b24 <kfree+0xb2>
    release(&kmem.lock);
    return;
  }
  release(&kmem.lock);
    80000aca:	00011917          	auipc	s2,0x11
    80000ace:	e6690913          	addi	s2,s2,-410 # 80011930 <kmem>
    80000ad2:	854a                	mv	a0,s2
    80000ad4:	00000097          	auipc	ra,0x0
    80000ad8:	382080e7          	jalr	898(ra) # 80000e56 <release>
  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000adc:	6605                	lui	a2,0x1
    80000ade:	4585                	li	a1,1
    80000ae0:	8526                	mv	a0,s1
    80000ae2:	00000097          	auipc	ra,0x0
    80000ae6:	3bc080e7          	jalr	956(ra) # 80000e9e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000aea:	854a                	mv	a0,s2
    80000aec:	00000097          	auipc	ra,0x0
    80000af0:	2b6080e7          	jalr	694(ra) # 80000da2 <acquire>
  r->next = kmem.freelist;
    80000af4:	01893783          	ld	a5,24(s2)
    80000af8:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000afa:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000afe:	854a                	mv	a0,s2
    80000b00:	00000097          	auipc	ra,0x0
    80000b04:	356080e7          	jalr	854(ra) # 80000e56 <release>
}
    80000b08:	60e2                	ld	ra,24(sp)
    80000b0a:	6442                	ld	s0,16(sp)
    80000b0c:	64a2                	ld	s1,8(sp)
    80000b0e:	6902                	ld	s2,0(sp)
    80000b10:	6105                	addi	sp,sp,32
    80000b12:	8082                	ret
    panic("kfree");
    80000b14:	00007517          	auipc	a0,0x7
    80000b18:	54c50513          	addi	a0,a0,1356 # 80008060 <digits+0x48>
    80000b1c:	00000097          	auipc	ra,0x0
    80000b20:	a58080e7          	jalr	-1448(ra) # 80000574 <panic>
    release(&kmem.lock);
    80000b24:	00011517          	auipc	a0,0x11
    80000b28:	e0c50513          	addi	a0,a0,-500 # 80011930 <kmem>
    80000b2c:	00000097          	auipc	ra,0x0
    80000b30:	32a080e7          	jalr	810(ra) # 80000e56 <release>
    return;
    80000b34:	bfd1                	j	80000b08 <kfree+0x96>

0000000080000b36 <freerange>:
{
    80000b36:	7179                	addi	sp,sp,-48
    80000b38:	f406                	sd	ra,40(sp)
    80000b3a:	f022                	sd	s0,32(sp)
    80000b3c:	ec26                	sd	s1,24(sp)
    80000b3e:	e84a                	sd	s2,16(sp)
    80000b40:	e44e                	sd	s3,8(sp)
    80000b42:	e052                	sd	s4,0(sp)
    80000b44:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b46:	6705                	lui	a4,0x1
    80000b48:	fff70793          	addi	a5,a4,-1 # fff <_entry-0x7ffff001>
    80000b4c:	00f504b3          	add	s1,a0,a5
    80000b50:	77fd                	lui	a5,0xfffff
    80000b52:	8cfd                	and	s1,s1,a5
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b54:	94ba                	add	s1,s1,a4
    80000b56:	0095ee63          	bltu	a1,s1,80000b72 <freerange+0x3c>
    80000b5a:	892e                	mv	s2,a1
    kfree(p);
    80000b5c:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b5e:	6985                	lui	s3,0x1
    kfree(p);
    80000b60:	01448533          	add	a0,s1,s4
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	f0e080e7          	jalr	-242(ra) # 80000a72 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b6c:	94ce                	add	s1,s1,s3
    80000b6e:	fe9979e3          	bleu	s1,s2,80000b60 <freerange+0x2a>
}
    80000b72:	70a2                	ld	ra,40(sp)
    80000b74:	7402                	ld	s0,32(sp)
    80000b76:	64e2                	ld	s1,24(sp)
    80000b78:	6942                	ld	s2,16(sp)
    80000b7a:	69a2                	ld	s3,8(sp)
    80000b7c:	6a02                	ld	s4,0(sp)
    80000b7e:	6145                	addi	sp,sp,48
    80000b80:	8082                	ret

0000000080000b82 <kinit>:
{
    80000b82:	1141                	addi	sp,sp,-16
    80000b84:	e406                	sd	ra,8(sp)
    80000b86:	e022                	sd	s0,0(sp)
    80000b88:	0800                	addi	s0,sp,16
   initlock(&kmem.lock, "kmem");
    80000b8a:	00007597          	auipc	a1,0x7
    80000b8e:	4de58593          	addi	a1,a1,1246 # 80008068 <digits+0x50>
    80000b92:	00011517          	auipc	a0,0x11
    80000b96:	d9e50513          	addi	a0,a0,-610 # 80011930 <kmem>
    80000b9a:	00000097          	auipc	ra,0x0
    80000b9e:	178080e7          	jalr	376(ra) # 80000d12 <initlock>
  for (int i = 0; i < ARR_MAX; i++) {
    80000ba2:	00011797          	auipc	a5,0x11
    80000ba6:	dae78793          	addi	a5,a5,-594 # 80011950 <pa_ref_cnt>
    80000baa:	00051697          	auipc	a3,0x51
    80000bae:	da668693          	addi	a3,a3,-602 # 80051950 <pid_lock>
    pa_ref_cnt[i] = 1;
    80000bb2:	4705                	li	a4,1
    80000bb4:	e398                	sd	a4,0(a5)
  for (int i = 0; i < ARR_MAX; i++) {
    80000bb6:	07a1                	addi	a5,a5,8
    80000bb8:	fed79ee3          	bne	a5,a3,80000bb4 <kinit+0x32>
  freerange(end, (void*)PHYSTOP);
    80000bbc:	45c5                	li	a1,17
    80000bbe:	05ee                	slli	a1,a1,0x1b
    80000bc0:	00065517          	auipc	a0,0x65
    80000bc4:	44050513          	addi	a0,a0,1088 # 80066000 <end>
    80000bc8:	00000097          	auipc	ra,0x0
    80000bcc:	f6e080e7          	jalr	-146(ra) # 80000b36 <freerange>
}
    80000bd0:	60a2                	ld	ra,8(sp)
    80000bd2:	6402                	ld	s0,0(sp)
    80000bd4:	0141                	addi	sp,sp,16
    80000bd6:	8082                	ret

0000000080000bd8 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bd8:	1101                	addi	sp,sp,-32
    80000bda:	ec06                	sd	ra,24(sp)
    80000bdc:	e822                	sd	s0,16(sp)
    80000bde:	e426                	sd	s1,8(sp)
    80000be0:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000be2:	00011497          	auipc	s1,0x11
    80000be6:	d4e48493          	addi	s1,s1,-690 # 80011930 <kmem>
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	1b6080e7          	jalr	438(ra) # 80000da2 <acquire>
  r = kmem.freelist;
    80000bf4:	6c84                	ld	s1,24(s1)
  if(r) {
    80000bf6:	c4a1                	beqz	s1,80000c3e <kalloc+0x66>
    kmem.freelist = r->next;
    80000bf8:	609c                	ld	a5,0(s1)
    80000bfa:	00011517          	auipc	a0,0x11
    80000bfe:	d3650513          	addi	a0,a0,-714 # 80011930 <kmem>
    80000c02:	ed1c                	sd	a5,24(a0)
    pa_ref_cnt[ARR_INDEX((uint64)r)] = 1;
    80000c04:	800007b7          	lui	a5,0x80000
    80000c08:	97a6                	add	a5,a5,s1
    80000c0a:	83b1                	srli	a5,a5,0xc
    80000c0c:	078e                	slli	a5,a5,0x3
    80000c0e:	00011717          	auipc	a4,0x11
    80000c12:	d4270713          	addi	a4,a4,-702 # 80011950 <pa_ref_cnt>
    80000c16:	97ba                	add	a5,a5,a4
    80000c18:	4705                	li	a4,1
    80000c1a:	e398                	sd	a4,0(a5)
  }
  release(&kmem.lock);
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	23a080e7          	jalr	570(ra) # 80000e56 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c24:	6605                	lui	a2,0x1
    80000c26:	4595                	li	a1,5
    80000c28:	8526                	mv	a0,s1
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	274080e7          	jalr	628(ra) # 80000e9e <memset>
  return (void*)r;
}
    80000c32:	8526                	mv	a0,s1
    80000c34:	60e2                	ld	ra,24(sp)
    80000c36:	6442                	ld	s0,16(sp)
    80000c38:	64a2                	ld	s1,8(sp)
    80000c3a:	6105                	addi	sp,sp,32
    80000c3c:	8082                	ret
  release(&kmem.lock);
    80000c3e:	00011517          	auipc	a0,0x11
    80000c42:	cf250513          	addi	a0,a0,-782 # 80011930 <kmem>
    80000c46:	00000097          	auipc	ra,0x0
    80000c4a:	210080e7          	jalr	528(ra) # 80000e56 <release>
  if(r)
    80000c4e:	b7d5                	j	80000c32 <kalloc+0x5a>

0000000080000c50 <decrease_cnt>:

void
decrease_cnt(uint64 pa)
{
    80000c50:	1101                	addi	sp,sp,-32
    80000c52:	ec06                	sd	ra,24(sp)
    80000c54:	e822                	sd	s0,16(sp)
    80000c56:	e426                	sd	s1,8(sp)
    80000c58:	e04a                	sd	s2,0(sp)
    80000c5a:	1000                	addi	s0,sp,32
    80000c5c:	84aa                	mv	s1,a0
  acquire(&kmem.lock);
    80000c5e:	00011917          	auipc	s2,0x11
    80000c62:	cd290913          	addi	s2,s2,-814 # 80011930 <kmem>
    80000c66:	854a                	mv	a0,s2
    80000c68:	00000097          	auipc	ra,0x0
    80000c6c:	13a080e7          	jalr	314(ra) # 80000da2 <acquire>
  pa_ref_cnt[ARR_INDEX(pa)]--;
    80000c70:	800007b7          	lui	a5,0x80000
    80000c74:	94be                	add	s1,s1,a5
    80000c76:	80b1                	srli	s1,s1,0xc
    80000c78:	048e                	slli	s1,s1,0x3
    80000c7a:	00011797          	auipc	a5,0x11
    80000c7e:	cd678793          	addi	a5,a5,-810 # 80011950 <pa_ref_cnt>
    80000c82:	94be                	add	s1,s1,a5
    80000c84:	609c                	ld	a5,0(s1)
    80000c86:	17fd                	addi	a5,a5,-1
    80000c88:	e09c                	sd	a5,0(s1)
  release(&kmem.lock);
    80000c8a:	854a                	mv	a0,s2
    80000c8c:	00000097          	auipc	ra,0x0
    80000c90:	1ca080e7          	jalr	458(ra) # 80000e56 <release>
}
    80000c94:	60e2                	ld	ra,24(sp)
    80000c96:	6442                	ld	s0,16(sp)
    80000c98:	64a2                	ld	s1,8(sp)
    80000c9a:	6902                	ld	s2,0(sp)
    80000c9c:	6105                	addi	sp,sp,32
    80000c9e:	8082                	ret

0000000080000ca0 <increase_cnt>:

void
increase_cnt(uint64 pa)
{
    80000ca0:	1101                	addi	sp,sp,-32
    80000ca2:	ec06                	sd	ra,24(sp)
    80000ca4:	e822                	sd	s0,16(sp)
    80000ca6:	e426                	sd	s1,8(sp)
    80000ca8:	e04a                	sd	s2,0(sp)
    80000caa:	1000                	addi	s0,sp,32
    80000cac:	84aa                	mv	s1,a0
  acquire(&kmem.lock);
    80000cae:	00011917          	auipc	s2,0x11
    80000cb2:	c8290913          	addi	s2,s2,-894 # 80011930 <kmem>
    80000cb6:	854a                	mv	a0,s2
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	0ea080e7          	jalr	234(ra) # 80000da2 <acquire>
  pa_ref_cnt[ARR_INDEX(pa)]++;
    80000cc0:	800007b7          	lui	a5,0x80000
    80000cc4:	94be                	add	s1,s1,a5
    80000cc6:	80b1                	srli	s1,s1,0xc
    80000cc8:	048e                	slli	s1,s1,0x3
    80000cca:	00011797          	auipc	a5,0x11
    80000cce:	c8678793          	addi	a5,a5,-890 # 80011950 <pa_ref_cnt>
    80000cd2:	94be                	add	s1,s1,a5
    80000cd4:	609c                	ld	a5,0(s1)
    80000cd6:	0785                	addi	a5,a5,1
    80000cd8:	e09c                	sd	a5,0(s1)
  release(&kmem.lock);
    80000cda:	854a                	mv	a0,s2
    80000cdc:	00000097          	auipc	ra,0x0
    80000ce0:	17a080e7          	jalr	378(ra) # 80000e56 <release>
}
    80000ce4:	60e2                	ld	ra,24(sp)
    80000ce6:	6442                	ld	s0,16(sp)
    80000ce8:	64a2                	ld	s1,8(sp)
    80000cea:	6902                	ld	s2,0(sp)
    80000cec:	6105                	addi	sp,sp,32
    80000cee:	8082                	ret

0000000080000cf0 <get_ref_cnt>:

long
get_ref_cnt(uint64 pa)
{
    80000cf0:	1141                	addi	sp,sp,-16
    80000cf2:	e422                	sd	s0,8(sp)
    80000cf4:	0800                	addi	s0,sp,16
  return pa_ref_cnt[ARR_INDEX(pa)];
    80000cf6:	800007b7          	lui	a5,0x80000
    80000cfa:	953e                	add	a0,a0,a5
    80000cfc:	8131                	srli	a0,a0,0xc
    80000cfe:	050e                	slli	a0,a0,0x3
    80000d00:	00011797          	auipc	a5,0x11
    80000d04:	c5078793          	addi	a5,a5,-944 # 80011950 <pa_ref_cnt>
    80000d08:	953e                	add	a0,a0,a5
}
    80000d0a:	6108                	ld	a0,0(a0)
    80000d0c:	6422                	ld	s0,8(sp)
    80000d0e:	0141                	addi	sp,sp,16
    80000d10:	8082                	ret

0000000080000d12 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000d12:	1141                	addi	sp,sp,-16
    80000d14:	e422                	sd	s0,8(sp)
    80000d16:	0800                	addi	s0,sp,16
  lk->name = name;
    80000d18:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000d1a:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000d1e:	00053823          	sd	zero,16(a0)
}
    80000d22:	6422                	ld	s0,8(sp)
    80000d24:	0141                	addi	sp,sp,16
    80000d26:	8082                	ret

0000000080000d28 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d28:	411c                	lw	a5,0(a0)
    80000d2a:	e399                	bnez	a5,80000d30 <holding+0x8>
    80000d2c:	4501                	li	a0,0
  return r;
}
    80000d2e:	8082                	ret
{
    80000d30:	1101                	addi	sp,sp,-32
    80000d32:	ec06                	sd	ra,24(sp)
    80000d34:	e822                	sd	s0,16(sp)
    80000d36:	e426                	sd	s1,8(sp)
    80000d38:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d3a:	6904                	ld	s1,16(a0)
    80000d3c:	00001097          	auipc	ra,0x1
    80000d40:	f74080e7          	jalr	-140(ra) # 80001cb0 <mycpu>
    80000d44:	40a48533          	sub	a0,s1,a0
    80000d48:	00153513          	seqz	a0,a0
}
    80000d4c:	60e2                	ld	ra,24(sp)
    80000d4e:	6442                	ld	s0,16(sp)
    80000d50:	64a2                	ld	s1,8(sp)
    80000d52:	6105                	addi	sp,sp,32
    80000d54:	8082                	ret

0000000080000d56 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d56:	1101                	addi	sp,sp,-32
    80000d58:	ec06                	sd	ra,24(sp)
    80000d5a:	e822                	sd	s0,16(sp)
    80000d5c:	e426                	sd	s1,8(sp)
    80000d5e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d60:	100024f3          	csrr	s1,sstatus
    80000d64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d68:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d6a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d6e:	00001097          	auipc	ra,0x1
    80000d72:	f42080e7          	jalr	-190(ra) # 80001cb0 <mycpu>
    80000d76:	5d3c                	lw	a5,120(a0)
    80000d78:	cf89                	beqz	a5,80000d92 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d7a:	00001097          	auipc	ra,0x1
    80000d7e:	f36080e7          	jalr	-202(ra) # 80001cb0 <mycpu>
    80000d82:	5d3c                	lw	a5,120(a0)
    80000d84:	2785                	addiw	a5,a5,1
    80000d86:	dd3c                	sw	a5,120(a0)
}
    80000d88:	60e2                	ld	ra,24(sp)
    80000d8a:	6442                	ld	s0,16(sp)
    80000d8c:	64a2                	ld	s1,8(sp)
    80000d8e:	6105                	addi	sp,sp,32
    80000d90:	8082                	ret
    mycpu()->intena = old;
    80000d92:	00001097          	auipc	ra,0x1
    80000d96:	f1e080e7          	jalr	-226(ra) # 80001cb0 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d9a:	8085                	srli	s1,s1,0x1
    80000d9c:	8885                	andi	s1,s1,1
    80000d9e:	dd64                	sw	s1,124(a0)
    80000da0:	bfe9                	j	80000d7a <push_off+0x24>

0000000080000da2 <acquire>:
{
    80000da2:	1101                	addi	sp,sp,-32
    80000da4:	ec06                	sd	ra,24(sp)
    80000da6:	e822                	sd	s0,16(sp)
    80000da8:	e426                	sd	s1,8(sp)
    80000daa:	1000                	addi	s0,sp,32
    80000dac:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	fa8080e7          	jalr	-88(ra) # 80000d56 <push_off>
  if(holding(lk))
    80000db6:	8526                	mv	a0,s1
    80000db8:	00000097          	auipc	ra,0x0
    80000dbc:	f70080e7          	jalr	-144(ra) # 80000d28 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dc0:	4705                	li	a4,1
  if(holding(lk))
    80000dc2:	e115                	bnez	a0,80000de6 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dc4:	87ba                	mv	a5,a4
    80000dc6:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000dca:	2781                	sext.w	a5,a5
    80000dcc:	ffe5                	bnez	a5,80000dc4 <acquire+0x22>
  __sync_synchronize();
    80000dce:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000dd2:	00001097          	auipc	ra,0x1
    80000dd6:	ede080e7          	jalr	-290(ra) # 80001cb0 <mycpu>
    80000dda:	e888                	sd	a0,16(s1)
}
    80000ddc:	60e2                	ld	ra,24(sp)
    80000dde:	6442                	ld	s0,16(sp)
    80000de0:	64a2                	ld	s1,8(sp)
    80000de2:	6105                	addi	sp,sp,32
    80000de4:	8082                	ret
    panic("acquire");
    80000de6:	00007517          	auipc	a0,0x7
    80000dea:	28a50513          	addi	a0,a0,650 # 80008070 <digits+0x58>
    80000dee:	fffff097          	auipc	ra,0xfffff
    80000df2:	786080e7          	jalr	1926(ra) # 80000574 <panic>

0000000080000df6 <pop_off>:

void
pop_off(void)
{
    80000df6:	1141                	addi	sp,sp,-16
    80000df8:	e406                	sd	ra,8(sp)
    80000dfa:	e022                	sd	s0,0(sp)
    80000dfc:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000dfe:	00001097          	auipc	ra,0x1
    80000e02:	eb2080e7          	jalr	-334(ra) # 80001cb0 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e06:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000e0a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000e0c:	e78d                	bnez	a5,80000e36 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000e0e:	5d3c                	lw	a5,120(a0)
    80000e10:	02f05b63          	blez	a5,80000e46 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000e14:	37fd                	addiw	a5,a5,-1
    80000e16:	0007871b          	sext.w	a4,a5
    80000e1a:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e1c:	eb09                	bnez	a4,80000e2e <pop_off+0x38>
    80000e1e:	5d7c                	lw	a5,124(a0)
    80000e20:	c799                	beqz	a5,80000e2e <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e26:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e2a:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e2e:	60a2                	ld	ra,8(sp)
    80000e30:	6402                	ld	s0,0(sp)
    80000e32:	0141                	addi	sp,sp,16
    80000e34:	8082                	ret
    panic("pop_off - interruptible");
    80000e36:	00007517          	auipc	a0,0x7
    80000e3a:	24250513          	addi	a0,a0,578 # 80008078 <digits+0x60>
    80000e3e:	fffff097          	auipc	ra,0xfffff
    80000e42:	736080e7          	jalr	1846(ra) # 80000574 <panic>
    panic("pop_off");
    80000e46:	00007517          	auipc	a0,0x7
    80000e4a:	24a50513          	addi	a0,a0,586 # 80008090 <digits+0x78>
    80000e4e:	fffff097          	auipc	ra,0xfffff
    80000e52:	726080e7          	jalr	1830(ra) # 80000574 <panic>

0000000080000e56 <release>:
{
    80000e56:	1101                	addi	sp,sp,-32
    80000e58:	ec06                	sd	ra,24(sp)
    80000e5a:	e822                	sd	s0,16(sp)
    80000e5c:	e426                	sd	s1,8(sp)
    80000e5e:	1000                	addi	s0,sp,32
    80000e60:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e62:	00000097          	auipc	ra,0x0
    80000e66:	ec6080e7          	jalr	-314(ra) # 80000d28 <holding>
    80000e6a:	c115                	beqz	a0,80000e8e <release+0x38>
  lk->cpu = 0;
    80000e6c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e70:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e74:	0f50000f          	fence	iorw,ow
    80000e78:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e7c:	00000097          	auipc	ra,0x0
    80000e80:	f7a080e7          	jalr	-134(ra) # 80000df6 <pop_off>
}
    80000e84:	60e2                	ld	ra,24(sp)
    80000e86:	6442                	ld	s0,16(sp)
    80000e88:	64a2                	ld	s1,8(sp)
    80000e8a:	6105                	addi	sp,sp,32
    80000e8c:	8082                	ret
    panic("release");
    80000e8e:	00007517          	auipc	a0,0x7
    80000e92:	20a50513          	addi	a0,a0,522 # 80008098 <digits+0x80>
    80000e96:	fffff097          	auipc	ra,0xfffff
    80000e9a:	6de080e7          	jalr	1758(ra) # 80000574 <panic>

0000000080000e9e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e9e:	1141                	addi	sp,sp,-16
    80000ea0:	e422                	sd	s0,8(sp)
    80000ea2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ea4:	ce09                	beqz	a2,80000ebe <memset+0x20>
    80000ea6:	87aa                	mv	a5,a0
    80000ea8:	fff6071b          	addiw	a4,a2,-1
    80000eac:	1702                	slli	a4,a4,0x20
    80000eae:	9301                	srli	a4,a4,0x20
    80000eb0:	0705                	addi	a4,a4,1
    80000eb2:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000eb4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000eb8:	0785                	addi	a5,a5,1
    80000eba:	fee79de3          	bne	a5,a4,80000eb4 <memset+0x16>
  }
  return dst;
}
    80000ebe:	6422                	ld	s0,8(sp)
    80000ec0:	0141                	addi	sp,sp,16
    80000ec2:	8082                	ret

0000000080000ec4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ec4:	1141                	addi	sp,sp,-16
    80000ec6:	e422                	sd	s0,8(sp)
    80000ec8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000eca:	ce15                	beqz	a2,80000f06 <memcmp+0x42>
    80000ecc:	fff6069b          	addiw	a3,a2,-1
    if(*s1 != *s2)
    80000ed0:	00054783          	lbu	a5,0(a0)
    80000ed4:	0005c703          	lbu	a4,0(a1)
    80000ed8:	02e79063          	bne	a5,a4,80000ef8 <memcmp+0x34>
    80000edc:	1682                	slli	a3,a3,0x20
    80000ede:	9281                	srli	a3,a3,0x20
    80000ee0:	0685                	addi	a3,a3,1
    80000ee2:	96aa                	add	a3,a3,a0
      return *s1 - *s2;
    s1++, s2++;
    80000ee4:	0505                	addi	a0,a0,1
    80000ee6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ee8:	00d50d63          	beq	a0,a3,80000f02 <memcmp+0x3e>
    if(*s1 != *s2)
    80000eec:	00054783          	lbu	a5,0(a0)
    80000ef0:	0005c703          	lbu	a4,0(a1)
    80000ef4:	fee788e3          	beq	a5,a4,80000ee4 <memcmp+0x20>
      return *s1 - *s2;
    80000ef8:	40e7853b          	subw	a0,a5,a4
  }

  return 0;
}
    80000efc:	6422                	ld	s0,8(sp)
    80000efe:	0141                	addi	sp,sp,16
    80000f00:	8082                	ret
  return 0;
    80000f02:	4501                	li	a0,0
    80000f04:	bfe5                	j	80000efc <memcmp+0x38>
    80000f06:	4501                	li	a0,0
    80000f08:	bfd5                	j	80000efc <memcmp+0x38>

0000000080000f0a <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000f0a:	1141                	addi	sp,sp,-16
    80000f0c:	e422                	sd	s0,8(sp)
    80000f0e:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000f10:	00a5f963          	bleu	a0,a1,80000f22 <memmove+0x18>
    80000f14:	02061713          	slli	a4,a2,0x20
    80000f18:	9301                	srli	a4,a4,0x20
    80000f1a:	00e587b3          	add	a5,a1,a4
    80000f1e:	02f56563          	bltu	a0,a5,80000f48 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000f22:	fff6069b          	addiw	a3,a2,-1
    80000f26:	ce11                	beqz	a2,80000f42 <memmove+0x38>
    80000f28:	1682                	slli	a3,a3,0x20
    80000f2a:	9281                	srli	a3,a3,0x20
    80000f2c:	0685                	addi	a3,a3,1
    80000f2e:	96ae                	add	a3,a3,a1
    80000f30:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000f32:	0585                	addi	a1,a1,1
    80000f34:	0785                	addi	a5,a5,1
    80000f36:	fff5c703          	lbu	a4,-1(a1)
    80000f3a:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000f3e:	fed59ae3          	bne	a1,a3,80000f32 <memmove+0x28>

  return dst;
}
    80000f42:	6422                	ld	s0,8(sp)
    80000f44:	0141                	addi	sp,sp,16
    80000f46:	8082                	ret
    d += n;
    80000f48:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000f4a:	fff6069b          	addiw	a3,a2,-1
    80000f4e:	da75                	beqz	a2,80000f42 <memmove+0x38>
    80000f50:	02069613          	slli	a2,a3,0x20
    80000f54:	9201                	srli	a2,a2,0x20
    80000f56:	fff64613          	not	a2,a2
    80000f5a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000f5c:	17fd                	addi	a5,a5,-1
    80000f5e:	177d                	addi	a4,a4,-1
    80000f60:	0007c683          	lbu	a3,0(a5)
    80000f64:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000f68:	fef61ae3          	bne	a2,a5,80000f5c <memmove+0x52>
    80000f6c:	bfd9                	j	80000f42 <memmove+0x38>

0000000080000f6e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f6e:	1141                	addi	sp,sp,-16
    80000f70:	e406                	sd	ra,8(sp)
    80000f72:	e022                	sd	s0,0(sp)
    80000f74:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f76:	00000097          	auipc	ra,0x0
    80000f7a:	f94080e7          	jalr	-108(ra) # 80000f0a <memmove>
}
    80000f7e:	60a2                	ld	ra,8(sp)
    80000f80:	6402                	ld	s0,0(sp)
    80000f82:	0141                	addi	sp,sp,16
    80000f84:	8082                	ret

0000000080000f86 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f86:	1141                	addi	sp,sp,-16
    80000f88:	e422                	sd	s0,8(sp)
    80000f8a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f8c:	c229                	beqz	a2,80000fce <strncmp+0x48>
    80000f8e:	00054783          	lbu	a5,0(a0)
    80000f92:	c795                	beqz	a5,80000fbe <strncmp+0x38>
    80000f94:	0005c703          	lbu	a4,0(a1)
    80000f98:	02f71363          	bne	a4,a5,80000fbe <strncmp+0x38>
    80000f9c:	fff6071b          	addiw	a4,a2,-1
    80000fa0:	1702                	slli	a4,a4,0x20
    80000fa2:	9301                	srli	a4,a4,0x20
    80000fa4:	0705                	addi	a4,a4,1
    80000fa6:	972a                	add	a4,a4,a0
    n--, p++, q++;
    80000fa8:	0505                	addi	a0,a0,1
    80000faa:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000fac:	02e50363          	beq	a0,a4,80000fd2 <strncmp+0x4c>
    80000fb0:	00054783          	lbu	a5,0(a0)
    80000fb4:	c789                	beqz	a5,80000fbe <strncmp+0x38>
    80000fb6:	0005c683          	lbu	a3,0(a1)
    80000fba:	fef687e3          	beq	a3,a5,80000fa8 <strncmp+0x22>
  if(n == 0)
    return 0;
  return (uchar)*p - (uchar)*q;
    80000fbe:	00054503          	lbu	a0,0(a0)
    80000fc2:	0005c783          	lbu	a5,0(a1)
    80000fc6:	9d1d                	subw	a0,a0,a5
}
    80000fc8:	6422                	ld	s0,8(sp)
    80000fca:	0141                	addi	sp,sp,16
    80000fcc:	8082                	ret
    return 0;
    80000fce:	4501                	li	a0,0
    80000fd0:	bfe5                	j	80000fc8 <strncmp+0x42>
    80000fd2:	4501                	li	a0,0
    80000fd4:	bfd5                	j	80000fc8 <strncmp+0x42>

0000000080000fd6 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000fd6:	1141                	addi	sp,sp,-16
    80000fd8:	e422                	sd	s0,8(sp)
    80000fda:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000fdc:	872a                	mv	a4,a0
    80000fde:	a011                	j	80000fe2 <strncpy+0xc>
    80000fe0:	8636                	mv	a2,a3
    80000fe2:	fff6069b          	addiw	a3,a2,-1
    80000fe6:	00c05963          	blez	a2,80000ff8 <strncpy+0x22>
    80000fea:	0705                	addi	a4,a4,1
    80000fec:	0005c783          	lbu	a5,0(a1)
    80000ff0:	fef70fa3          	sb	a5,-1(a4)
    80000ff4:	0585                	addi	a1,a1,1
    80000ff6:	f7ed                	bnez	a5,80000fe0 <strncpy+0xa>
    ;
  while(n-- > 0)
    80000ff8:	00d05c63          	blez	a3,80001010 <strncpy+0x3a>
    80000ffc:	86ba                	mv	a3,a4
    *s++ = 0;
    80000ffe:	0685                	addi	a3,a3,1
    80001000:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80001004:	fff6c793          	not	a5,a3
    80001008:	9fb9                	addw	a5,a5,a4
    8000100a:	9fb1                	addw	a5,a5,a2
    8000100c:	fef049e3          	bgtz	a5,80000ffe <strncpy+0x28>
  return os;
}
    80001010:	6422                	ld	s0,8(sp)
    80001012:	0141                	addi	sp,sp,16
    80001014:	8082                	ret

0000000080001016 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80001016:	1141                	addi	sp,sp,-16
    80001018:	e422                	sd	s0,8(sp)
    8000101a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    8000101c:	02c05363          	blez	a2,80001042 <safestrcpy+0x2c>
    80001020:	fff6069b          	addiw	a3,a2,-1
    80001024:	1682                	slli	a3,a3,0x20
    80001026:	9281                	srli	a3,a3,0x20
    80001028:	96ae                	add	a3,a3,a1
    8000102a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    8000102c:	00d58963          	beq	a1,a3,8000103e <safestrcpy+0x28>
    80001030:	0585                	addi	a1,a1,1
    80001032:	0785                	addi	a5,a5,1
    80001034:	fff5c703          	lbu	a4,-1(a1)
    80001038:	fee78fa3          	sb	a4,-1(a5)
    8000103c:	fb65                	bnez	a4,8000102c <safestrcpy+0x16>
    ;
  *s = 0;
    8000103e:	00078023          	sb	zero,0(a5)
  return os;
}
    80001042:	6422                	ld	s0,8(sp)
    80001044:	0141                	addi	sp,sp,16
    80001046:	8082                	ret

0000000080001048 <strlen>:

int
strlen(const char *s)
{
    80001048:	1141                	addi	sp,sp,-16
    8000104a:	e422                	sd	s0,8(sp)
    8000104c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    8000104e:	00054783          	lbu	a5,0(a0)
    80001052:	cf91                	beqz	a5,8000106e <strlen+0x26>
    80001054:	0505                	addi	a0,a0,1
    80001056:	87aa                	mv	a5,a0
    80001058:	4685                	li	a3,1
    8000105a:	9e89                	subw	a3,a3,a0
    8000105c:	00f6853b          	addw	a0,a3,a5
    80001060:	0785                	addi	a5,a5,1
    80001062:	fff7c703          	lbu	a4,-1(a5)
    80001066:	fb7d                	bnez	a4,8000105c <strlen+0x14>
    ;
  return n;
}
    80001068:	6422                	ld	s0,8(sp)
    8000106a:	0141                	addi	sp,sp,16
    8000106c:	8082                	ret
  for(n = 0; s[n]; n++)
    8000106e:	4501                	li	a0,0
    80001070:	bfe5                	j	80001068 <strlen+0x20>

0000000080001072 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001072:	1141                	addi	sp,sp,-16
    80001074:	e406                	sd	ra,8(sp)
    80001076:	e022                	sd	s0,0(sp)
    80001078:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000107a:	00001097          	auipc	ra,0x1
    8000107e:	c26080e7          	jalr	-986(ra) # 80001ca0 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001082:	00008717          	auipc	a4,0x8
    80001086:	f8a70713          	addi	a4,a4,-118 # 8000900c <started>
  if(cpuid() == 0){
    8000108a:	c139                	beqz	a0,800010d0 <main+0x5e>
    while(started == 0)
    8000108c:	431c                	lw	a5,0(a4)
    8000108e:	2781                	sext.w	a5,a5
    80001090:	dff5                	beqz	a5,8000108c <main+0x1a>
      ;
    __sync_synchronize();
    80001092:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001096:	00001097          	auipc	ra,0x1
    8000109a:	c0a080e7          	jalr	-1014(ra) # 80001ca0 <cpuid>
    8000109e:	85aa                	mv	a1,a0
    800010a0:	00007517          	auipc	a0,0x7
    800010a4:	01850513          	addi	a0,a0,24 # 800080b8 <digits+0xa0>
    800010a8:	fffff097          	auipc	ra,0xfffff
    800010ac:	516080e7          	jalr	1302(ra) # 800005be <printf>
    kvminithart();    // turn on paging
    800010b0:	00000097          	auipc	ra,0x0
    800010b4:	0d8080e7          	jalr	216(ra) # 80001188 <kvminithart>
    trapinithart();   // install kernel trap vector
    800010b8:	00002097          	auipc	ra,0x2
    800010bc:	87e080e7          	jalr	-1922(ra) # 80002936 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800010c0:	00005097          	auipc	ra,0x5
    800010c4:	f20080e7          	jalr	-224(ra) # 80005fe0 <plicinithart>
  }

  scheduler();        
    800010c8:	00001097          	auipc	ra,0x1
    800010cc:	13a080e7          	jalr	314(ra) # 80002202 <scheduler>
    consoleinit();
    800010d0:	fffff097          	auipc	ra,0xfffff
    800010d4:	3b2080e7          	jalr	946(ra) # 80000482 <consoleinit>
    printfinit();
    800010d8:	fffff097          	auipc	ra,0xfffff
    800010dc:	6cc080e7          	jalr	1740(ra) # 800007a4 <printfinit>
    printf("\n");
    800010e0:	00007517          	auipc	a0,0x7
    800010e4:	fe850513          	addi	a0,a0,-24 # 800080c8 <digits+0xb0>
    800010e8:	fffff097          	auipc	ra,0xfffff
    800010ec:	4d6080e7          	jalr	1238(ra) # 800005be <printf>
    printf("xv6 kernel is booting\n");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fb050513          	addi	a0,a0,-80 # 800080a0 <digits+0x88>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	4c6080e7          	jalr	1222(ra) # 800005be <printf>
    printf("\n");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fc850513          	addi	a0,a0,-56 # 800080c8 <digits+0xb0>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	4b6080e7          	jalr	1206(ra) # 800005be <printf>
    kinit();         // physical page allocator
    80001110:	00000097          	auipc	ra,0x0
    80001114:	a72080e7          	jalr	-1422(ra) # 80000b82 <kinit>
    kvminit();       // create kernel page table
    80001118:	00000097          	auipc	ra,0x0
    8000111c:	2a6080e7          	jalr	678(ra) # 800013be <kvminit>
    kvminithart();   // turn on paging
    80001120:	00000097          	auipc	ra,0x0
    80001124:	068080e7          	jalr	104(ra) # 80001188 <kvminithart>
    procinit();      // process table
    80001128:	00001097          	auipc	ra,0x1
    8000112c:	aa8080e7          	jalr	-1368(ra) # 80001bd0 <procinit>
    trapinit();      // trap vectors
    80001130:	00001097          	auipc	ra,0x1
    80001134:	7de080e7          	jalr	2014(ra) # 8000290e <trapinit>
    trapinithart();  // install kernel trap vector
    80001138:	00001097          	auipc	ra,0x1
    8000113c:	7fe080e7          	jalr	2046(ra) # 80002936 <trapinithart>
    plicinit();      // set up interrupt controller
    80001140:	00005097          	auipc	ra,0x5
    80001144:	e8a080e7          	jalr	-374(ra) # 80005fca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001148:	00005097          	auipc	ra,0x5
    8000114c:	e98080e7          	jalr	-360(ra) # 80005fe0 <plicinithart>
    binit();         // buffer cache
    80001150:	00002097          	auipc	ra,0x2
    80001154:	f62080e7          	jalr	-158(ra) # 800030b2 <binit>
    iinit();         // inode cache
    80001158:	00002097          	auipc	ra,0x2
    8000115c:	634080e7          	jalr	1588(ra) # 8000378c <iinit>
    fileinit();      // file table
    80001160:	00003097          	auipc	ra,0x3
    80001164:	5fe080e7          	jalr	1534(ra) # 8000475e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001168:	00005097          	auipc	ra,0x5
    8000116c:	f82080e7          	jalr	-126(ra) # 800060ea <virtio_disk_init>
    userinit();      // first user process
    80001170:	00001097          	auipc	ra,0x1
    80001174:	e28080e7          	jalr	-472(ra) # 80001f98 <userinit>
    __sync_synchronize();
    80001178:	0ff0000f          	fence
    started = 1;
    8000117c:	4785                	li	a5,1
    8000117e:	00008717          	auipc	a4,0x8
    80001182:	e8f72723          	sw	a5,-370(a4) # 8000900c <started>
    80001186:	b789                	j	800010c8 <main+0x56>

0000000080001188 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001188:	1141                	addi	sp,sp,-16
    8000118a:	e422                	sd	s0,8(sp)
    8000118c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000118e:	00008797          	auipc	a5,0x8
    80001192:	e8278793          	addi	a5,a5,-382 # 80009010 <kernel_pagetable>
    80001196:	639c                	ld	a5,0(a5)
    80001198:	83b1                	srli	a5,a5,0xc
    8000119a:	577d                	li	a4,-1
    8000119c:	177e                	slli	a4,a4,0x3f
    8000119e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800011a0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800011a4:	12000073          	sfence.vma
  sfence_vma();
}
    800011a8:	6422                	ld	s0,8(sp)
    800011aa:	0141                	addi	sp,sp,16
    800011ac:	8082                	ret

00000000800011ae <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800011ae:	7139                	addi	sp,sp,-64
    800011b0:	fc06                	sd	ra,56(sp)
    800011b2:	f822                	sd	s0,48(sp)
    800011b4:	f426                	sd	s1,40(sp)
    800011b6:	f04a                	sd	s2,32(sp)
    800011b8:	ec4e                	sd	s3,24(sp)
    800011ba:	e852                	sd	s4,16(sp)
    800011bc:	e456                	sd	s5,8(sp)
    800011be:	e05a                	sd	s6,0(sp)
    800011c0:	0080                	addi	s0,sp,64
    800011c2:	84aa                	mv	s1,a0
    800011c4:	89ae                	mv	s3,a1
    800011c6:	8b32                	mv	s6,a2
  if(va >= MAXVA)
    800011c8:	57fd                	li	a5,-1
    800011ca:	83e9                	srli	a5,a5,0x1a
    800011cc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800011ce:	4ab1                	li	s5,12
  if(va >= MAXVA)
    800011d0:	04b7f263          	bleu	a1,a5,80001214 <walk+0x66>
    panic("walk");
    800011d4:	00007517          	auipc	a0,0x7
    800011d8:	efc50513          	addi	a0,a0,-260 # 800080d0 <digits+0xb8>
    800011dc:	fffff097          	auipc	ra,0xfffff
    800011e0:	398080e7          	jalr	920(ra) # 80000574 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800011e4:	060b0663          	beqz	s6,80001250 <walk+0xa2>
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	9f0080e7          	jalr	-1552(ra) # 80000bd8 <kalloc>
    800011f0:	84aa                	mv	s1,a0
    800011f2:	c529                	beqz	a0,8000123c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011f4:	6605                	lui	a2,0x1
    800011f6:	4581                	li	a1,0
    800011f8:	00000097          	auipc	ra,0x0
    800011fc:	ca6080e7          	jalr	-858(ra) # 80000e9e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001200:	00c4d793          	srli	a5,s1,0xc
    80001204:	07aa                	slli	a5,a5,0xa
    80001206:	0017e793          	ori	a5,a5,1
    8000120a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000120e:	3a5d                	addiw	s4,s4,-9
    80001210:	035a0063          	beq	s4,s5,80001230 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001214:	0149d933          	srl	s2,s3,s4
    80001218:	1ff97913          	andi	s2,s2,511
    8000121c:	090e                	slli	s2,s2,0x3
    8000121e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001220:	00093483          	ld	s1,0(s2)
    80001224:	0014f793          	andi	a5,s1,1
    80001228:	dfd5                	beqz	a5,800011e4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000122a:	80a9                	srli	s1,s1,0xa
    8000122c:	04b2                	slli	s1,s1,0xc
    8000122e:	b7c5                	j	8000120e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001230:	00c9d513          	srli	a0,s3,0xc
    80001234:	1ff57513          	andi	a0,a0,511
    80001238:	050e                	slli	a0,a0,0x3
    8000123a:	9526                	add	a0,a0,s1
}
    8000123c:	70e2                	ld	ra,56(sp)
    8000123e:	7442                	ld	s0,48(sp)
    80001240:	74a2                	ld	s1,40(sp)
    80001242:	7902                	ld	s2,32(sp)
    80001244:	69e2                	ld	s3,24(sp)
    80001246:	6a42                	ld	s4,16(sp)
    80001248:	6aa2                	ld	s5,8(sp)
    8000124a:	6b02                	ld	s6,0(sp)
    8000124c:	6121                	addi	sp,sp,64
    8000124e:	8082                	ret
        return 0;
    80001250:	4501                	li	a0,0
    80001252:	b7ed                	j	8000123c <walk+0x8e>

0000000080001254 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001254:	57fd                	li	a5,-1
    80001256:	83e9                	srli	a5,a5,0x1a
    80001258:	00b7f463          	bleu	a1,a5,80001260 <walkaddr+0xc>
    return 0;
    8000125c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000125e:	8082                	ret
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001268:	4601                	li	a2,0
    8000126a:	00000097          	auipc	ra,0x0
    8000126e:	f44080e7          	jalr	-188(ra) # 800011ae <walk>
  if(pte == 0)
    80001272:	c105                	beqz	a0,80001292 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001274:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001276:	0117f693          	andi	a3,a5,17
    8000127a:	4745                	li	a4,17
    return 0;
    8000127c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000127e:	00e68663          	beq	a3,a4,8000128a <walkaddr+0x36>
}
    80001282:	60a2                	ld	ra,8(sp)
    80001284:	6402                	ld	s0,0(sp)
    80001286:	0141                	addi	sp,sp,16
    80001288:	8082                	ret
  pa = PTE2PA(*pte);
    8000128a:	00a7d513          	srli	a0,a5,0xa
    8000128e:	0532                	slli	a0,a0,0xc
  return pa;
    80001290:	bfcd                	j	80001282 <walkaddr+0x2e>
    return 0;
    80001292:	4501                	li	a0,0
    80001294:	b7fd                	j	80001282 <walkaddr+0x2e>

0000000080001296 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001296:	1101                	addi	sp,sp,-32
    80001298:	ec06                	sd	ra,24(sp)
    8000129a:	e822                	sd	s0,16(sp)
    8000129c:	e426                	sd	s1,8(sp)
    8000129e:	1000                	addi	s0,sp,32
    800012a0:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800012a2:	6785                	lui	a5,0x1
    800012a4:	17fd                	addi	a5,a5,-1
    800012a6:	00f574b3          	and	s1,a0,a5
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800012aa:	4601                	li	a2,0
    800012ac:	00008797          	auipc	a5,0x8
    800012b0:	d6478793          	addi	a5,a5,-668 # 80009010 <kernel_pagetable>
    800012b4:	6388                	ld	a0,0(a5)
    800012b6:	00000097          	auipc	ra,0x0
    800012ba:	ef8080e7          	jalr	-264(ra) # 800011ae <walk>
  if(pte == 0)
    800012be:	cd09                	beqz	a0,800012d8 <kvmpa+0x42>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800012c0:	6108                	ld	a0,0(a0)
    800012c2:	00157793          	andi	a5,a0,1
    800012c6:	c38d                	beqz	a5,800012e8 <kvmpa+0x52>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800012c8:	8129                	srli	a0,a0,0xa
    800012ca:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800012cc:	9526                	add	a0,a0,s1
    800012ce:	60e2                	ld	ra,24(sp)
    800012d0:	6442                	ld	s0,16(sp)
    800012d2:	64a2                	ld	s1,8(sp)
    800012d4:	6105                	addi	sp,sp,32
    800012d6:	8082                	ret
    panic("kvmpa");
    800012d8:	00007517          	auipc	a0,0x7
    800012dc:	e0050513          	addi	a0,a0,-512 # 800080d8 <digits+0xc0>
    800012e0:	fffff097          	auipc	ra,0xfffff
    800012e4:	294080e7          	jalr	660(ra) # 80000574 <panic>
    panic("kvmpa");
    800012e8:	00007517          	auipc	a0,0x7
    800012ec:	df050513          	addi	a0,a0,-528 # 800080d8 <digits+0xc0>
    800012f0:	fffff097          	auipc	ra,0xfffff
    800012f4:	284080e7          	jalr	644(ra) # 80000574 <panic>

00000000800012f8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800012f8:	715d                	addi	sp,sp,-80
    800012fa:	e486                	sd	ra,72(sp)
    800012fc:	e0a2                	sd	s0,64(sp)
    800012fe:	fc26                	sd	s1,56(sp)
    80001300:	f84a                	sd	s2,48(sp)
    80001302:	f44e                	sd	s3,40(sp)
    80001304:	f052                	sd	s4,32(sp)
    80001306:	ec56                	sd	s5,24(sp)
    80001308:	e85a                	sd	s6,16(sp)
    8000130a:	e45e                	sd	s7,8(sp)
    8000130c:	0880                	addi	s0,sp,80
    8000130e:	8aaa                	mv	s5,a0
    80001310:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001312:	79fd                	lui	s3,0xfffff
    80001314:	0135fa33          	and	s4,a1,s3
  last = PGROUNDDOWN(va + size - 1);
    80001318:	167d                	addi	a2,a2,-1
    8000131a:	962e                	add	a2,a2,a1
    8000131c:	013679b3          	and	s3,a2,s3
  a = PGROUNDDOWN(va);
    80001320:	8952                	mv	s2,s4
    80001322:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001326:	6b85                	lui	s7,0x1
    80001328:	a811                	j	8000133c <mappages+0x44>
      panic("remap");
    8000132a:	00007517          	auipc	a0,0x7
    8000132e:	db650513          	addi	a0,a0,-586 # 800080e0 <digits+0xc8>
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	242080e7          	jalr	578(ra) # 80000574 <panic>
    a += PGSIZE;
    8000133a:	995e                	add	s2,s2,s7
  for(;;){
    8000133c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001340:	4605                	li	a2,1
    80001342:	85ca                	mv	a1,s2
    80001344:	8556                	mv	a0,s5
    80001346:	00000097          	auipc	ra,0x0
    8000134a:	e68080e7          	jalr	-408(ra) # 800011ae <walk>
    8000134e:	cd19                	beqz	a0,8000136c <mappages+0x74>
    if(*pte & PTE_V)
    80001350:	611c                	ld	a5,0(a0)
    80001352:	8b85                	andi	a5,a5,1
    80001354:	fbf9                	bnez	a5,8000132a <mappages+0x32>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001356:	80b1                	srli	s1,s1,0xc
    80001358:	04aa                	slli	s1,s1,0xa
    8000135a:	0164e4b3          	or	s1,s1,s6
    8000135e:	0014e493          	ori	s1,s1,1
    80001362:	e104                	sd	s1,0(a0)
    if(a == last)
    80001364:	fd391be3          	bne	s2,s3,8000133a <mappages+0x42>
    pa += PGSIZE;
  }
  return 0;
    80001368:	4501                	li	a0,0
    8000136a:	a011                	j	8000136e <mappages+0x76>
      return -1;
    8000136c:	557d                	li	a0,-1
}
    8000136e:	60a6                	ld	ra,72(sp)
    80001370:	6406                	ld	s0,64(sp)
    80001372:	74e2                	ld	s1,56(sp)
    80001374:	7942                	ld	s2,48(sp)
    80001376:	79a2                	ld	s3,40(sp)
    80001378:	7a02                	ld	s4,32(sp)
    8000137a:	6ae2                	ld	s5,24(sp)
    8000137c:	6b42                	ld	s6,16(sp)
    8000137e:	6ba2                	ld	s7,8(sp)
    80001380:	6161                	addi	sp,sp,80
    80001382:	8082                	ret

0000000080001384 <kvmmap>:
{
    80001384:	1141                	addi	sp,sp,-16
    80001386:	e406                	sd	ra,8(sp)
    80001388:	e022                	sd	s0,0(sp)
    8000138a:	0800                	addi	s0,sp,16
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000138c:	8736                	mv	a4,a3
    8000138e:	86ae                	mv	a3,a1
    80001390:	85aa                	mv	a1,a0
    80001392:	00008797          	auipc	a5,0x8
    80001396:	c7e78793          	addi	a5,a5,-898 # 80009010 <kernel_pagetable>
    8000139a:	6388                	ld	a0,0(a5)
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	f5c080e7          	jalr	-164(ra) # 800012f8 <mappages>
    800013a4:	e509                	bnez	a0,800013ae <kvmmap+0x2a>
}
    800013a6:	60a2                	ld	ra,8(sp)
    800013a8:	6402                	ld	s0,0(sp)
    800013aa:	0141                	addi	sp,sp,16
    800013ac:	8082                	ret
    panic("kvmmap");
    800013ae:	00007517          	auipc	a0,0x7
    800013b2:	d3a50513          	addi	a0,a0,-710 # 800080e8 <digits+0xd0>
    800013b6:	fffff097          	auipc	ra,0xfffff
    800013ba:	1be080e7          	jalr	446(ra) # 80000574 <panic>

00000000800013be <kvminit>:
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	810080e7          	jalr	-2032(ra) # 80000bd8 <kalloc>
    800013d0:	00008797          	auipc	a5,0x8
    800013d4:	c4a7b023          	sd	a0,-960(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800013d8:	6605                	lui	a2,0x1
    800013da:	4581                	li	a1,0
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	ac2080e7          	jalr	-1342(ra) # 80000e9e <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800013e4:	4699                	li	a3,6
    800013e6:	6605                	lui	a2,0x1
    800013e8:	100005b7          	lui	a1,0x10000
    800013ec:	10000537          	lui	a0,0x10000
    800013f0:	00000097          	auipc	ra,0x0
    800013f4:	f94080e7          	jalr	-108(ra) # 80001384 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800013f8:	4699                	li	a3,6
    800013fa:	6605                	lui	a2,0x1
    800013fc:	100015b7          	lui	a1,0x10001
    80001400:	10001537          	lui	a0,0x10001
    80001404:	00000097          	auipc	ra,0x0
    80001408:	f80080e7          	jalr	-128(ra) # 80001384 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000140c:	4699                	li	a3,6
    8000140e:	6641                	lui	a2,0x10
    80001410:	020005b7          	lui	a1,0x2000
    80001414:	02000537          	lui	a0,0x2000
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	f6c080e7          	jalr	-148(ra) # 80001384 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001420:	4699                	li	a3,6
    80001422:	00400637          	lui	a2,0x400
    80001426:	0c0005b7          	lui	a1,0xc000
    8000142a:	0c000537          	lui	a0,0xc000
    8000142e:	00000097          	auipc	ra,0x0
    80001432:	f56080e7          	jalr	-170(ra) # 80001384 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001436:	00007497          	auipc	s1,0x7
    8000143a:	bca48493          	addi	s1,s1,-1078 # 80008000 <etext>
    8000143e:	46a9                	li	a3,10
    80001440:	80007617          	auipc	a2,0x80007
    80001444:	bc060613          	addi	a2,a2,-1088 # 8000 <_entry-0x7fff8000>
    80001448:	4585                	li	a1,1
    8000144a:	05fe                	slli	a1,a1,0x1f
    8000144c:	852e                	mv	a0,a1
    8000144e:	00000097          	auipc	ra,0x0
    80001452:	f36080e7          	jalr	-202(ra) # 80001384 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001456:	4699                	li	a3,6
    80001458:	4645                	li	a2,17
    8000145a:	066e                	slli	a2,a2,0x1b
    8000145c:	8e05                	sub	a2,a2,s1
    8000145e:	85a6                	mv	a1,s1
    80001460:	8526                	mv	a0,s1
    80001462:	00000097          	auipc	ra,0x0
    80001466:	f22080e7          	jalr	-222(ra) # 80001384 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000146a:	46a9                	li	a3,10
    8000146c:	6605                	lui	a2,0x1
    8000146e:	00006597          	auipc	a1,0x6
    80001472:	b9258593          	addi	a1,a1,-1134 # 80007000 <_trampoline>
    80001476:	04000537          	lui	a0,0x4000
    8000147a:	157d                	addi	a0,a0,-1
    8000147c:	0532                	slli	a0,a0,0xc
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	f06080e7          	jalr	-250(ra) # 80001384 <kvmmap>
}
    80001486:	60e2                	ld	ra,24(sp)
    80001488:	6442                	ld	s0,16(sp)
    8000148a:	64a2                	ld	s1,8(sp)
    8000148c:	6105                	addi	sp,sp,32
    8000148e:	8082                	ret

0000000080001490 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001490:	715d                	addi	sp,sp,-80
    80001492:	e486                	sd	ra,72(sp)
    80001494:	e0a2                	sd	s0,64(sp)
    80001496:	fc26                	sd	s1,56(sp)
    80001498:	f84a                	sd	s2,48(sp)
    8000149a:	f44e                	sd	s3,40(sp)
    8000149c:	f052                	sd	s4,32(sp)
    8000149e:	ec56                	sd	s5,24(sp)
    800014a0:	e85a                	sd	s6,16(sp)
    800014a2:	e45e                	sd	s7,8(sp)
    800014a4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800014a6:	6785                	lui	a5,0x1
    800014a8:	17fd                	addi	a5,a5,-1
    800014aa:	8fed                	and	a5,a5,a1
    800014ac:	e795                	bnez	a5,800014d8 <uvmunmap+0x48>
    800014ae:	8a2a                	mv	s4,a0
    800014b0:	84ae                	mv	s1,a1
    800014b2:	8bb6                	mv	s7,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014b4:	0632                	slli	a2,a2,0xc
    800014b6:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800014ba:	4b05                	li	s6,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014bc:	6a85                	lui	s5,0x1
    800014be:	0735e863          	bltu	a1,s3,8000152e <uvmunmap+0x9e>
      decrease_cnt(PTE2PA(*pte));
    }
    //+++++end++++++
    *pte = 0;
  }
}
    800014c2:	60a6                	ld	ra,72(sp)
    800014c4:	6406                	ld	s0,64(sp)
    800014c6:	74e2                	ld	s1,56(sp)
    800014c8:	7942                	ld	s2,48(sp)
    800014ca:	79a2                	ld	s3,40(sp)
    800014cc:	7a02                	ld	s4,32(sp)
    800014ce:	6ae2                	ld	s5,24(sp)
    800014d0:	6b42                	ld	s6,16(sp)
    800014d2:	6ba2                	ld	s7,8(sp)
    800014d4:	6161                	addi	sp,sp,80
    800014d6:	8082                	ret
    panic("uvmunmap: not aligned");
    800014d8:	00007517          	auipc	a0,0x7
    800014dc:	c1850513          	addi	a0,a0,-1000 # 800080f0 <digits+0xd8>
    800014e0:	fffff097          	auipc	ra,0xfffff
    800014e4:	094080e7          	jalr	148(ra) # 80000574 <panic>
      panic("uvmunmap: walk");
    800014e8:	00007517          	auipc	a0,0x7
    800014ec:	c2050513          	addi	a0,a0,-992 # 80008108 <digits+0xf0>
    800014f0:	fffff097          	auipc	ra,0xfffff
    800014f4:	084080e7          	jalr	132(ra) # 80000574 <panic>
      panic("uvmunmap: not mapped");
    800014f8:	00007517          	auipc	a0,0x7
    800014fc:	c2050513          	addi	a0,a0,-992 # 80008118 <digits+0x100>
    80001500:	fffff097          	auipc	ra,0xfffff
    80001504:	074080e7          	jalr	116(ra) # 80000574 <panic>
      panic("uvmunmap: not a leaf");
    80001508:	00007517          	auipc	a0,0x7
    8000150c:	c2850513          	addi	a0,a0,-984 # 80008130 <digits+0x118>
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	064080e7          	jalr	100(ra) # 80000574 <panic>
      decrease_cnt(PTE2PA(*pte));
    80001518:	8129                	srli	a0,a0,0xa
    8000151a:	0532                	slli	a0,a0,0xc
    8000151c:	fffff097          	auipc	ra,0xfffff
    80001520:	734080e7          	jalr	1844(ra) # 80000c50 <decrease_cnt>
    *pte = 0;
    80001524:	00093023          	sd	zero,0(s2)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001528:	94d6                	add	s1,s1,s5
    8000152a:	f934fce3          	bleu	s3,s1,800014c2 <uvmunmap+0x32>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000152e:	4601                	li	a2,0
    80001530:	85a6                	mv	a1,s1
    80001532:	8552                	mv	a0,s4
    80001534:	00000097          	auipc	ra,0x0
    80001538:	c7a080e7          	jalr	-902(ra) # 800011ae <walk>
    8000153c:	892a                	mv	s2,a0
    8000153e:	d54d                	beqz	a0,800014e8 <uvmunmap+0x58>
    if((*pte & PTE_V) == 0)
    80001540:	6108                	ld	a0,0(a0)
    80001542:	00157793          	andi	a5,a0,1
    80001546:	dbcd                	beqz	a5,800014f8 <uvmunmap+0x68>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001548:	3ff57793          	andi	a5,a0,1023
    8000154c:	fb678ee3          	beq	a5,s6,80001508 <uvmunmap+0x78>
    if(do_free) {
    80001550:	fc0b84e3          	beqz	s7,80001518 <uvmunmap+0x88>
      uint64 pa = PTE2PA(*pte);
    80001554:	8129                	srli	a0,a0,0xa
      kfree((void *) pa);
    80001556:	0532                	slli	a0,a0,0xc
    80001558:	fffff097          	auipc	ra,0xfffff
    8000155c:	51a080e7          	jalr	1306(ra) # 80000a72 <kfree>
    80001560:	b7d1                	j	80001524 <uvmunmap+0x94>

0000000080001562 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001562:	1101                	addi	sp,sp,-32
    80001564:	ec06                	sd	ra,24(sp)
    80001566:	e822                	sd	s0,16(sp)
    80001568:	e426                	sd	s1,8(sp)
    8000156a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000156c:	fffff097          	auipc	ra,0xfffff
    80001570:	66c080e7          	jalr	1644(ra) # 80000bd8 <kalloc>
    80001574:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001576:	c519                	beqz	a0,80001584 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001578:	6605                	lui	a2,0x1
    8000157a:	4581                	li	a1,0
    8000157c:	00000097          	auipc	ra,0x0
    80001580:	922080e7          	jalr	-1758(ra) # 80000e9e <memset>
  return pagetable;
}
    80001584:	8526                	mv	a0,s1
    80001586:	60e2                	ld	ra,24(sp)
    80001588:	6442                	ld	s0,16(sp)
    8000158a:	64a2                	ld	s1,8(sp)
    8000158c:	6105                	addi	sp,sp,32
    8000158e:	8082                	ret

0000000080001590 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001590:	7179                	addi	sp,sp,-48
    80001592:	f406                	sd	ra,40(sp)
    80001594:	f022                	sd	s0,32(sp)
    80001596:	ec26                	sd	s1,24(sp)
    80001598:	e84a                	sd	s2,16(sp)
    8000159a:	e44e                	sd	s3,8(sp)
    8000159c:	e052                	sd	s4,0(sp)
    8000159e:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800015a0:	6785                	lui	a5,0x1
    800015a2:	04f67863          	bleu	a5,a2,800015f2 <uvminit+0x62>
    800015a6:	8a2a                	mv	s4,a0
    800015a8:	89ae                	mv	s3,a1
    800015aa:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	62c080e7          	jalr	1580(ra) # 80000bd8 <kalloc>
    800015b4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800015b6:	6605                	lui	a2,0x1
    800015b8:	4581                	li	a1,0
    800015ba:	00000097          	auipc	ra,0x0
    800015be:	8e4080e7          	jalr	-1820(ra) # 80000e9e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800015c2:	4779                	li	a4,30
    800015c4:	86ca                	mv	a3,s2
    800015c6:	6605                	lui	a2,0x1
    800015c8:	4581                	li	a1,0
    800015ca:	8552                	mv	a0,s4
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	d2c080e7          	jalr	-724(ra) # 800012f8 <mappages>
  memmove(mem, src, sz);
    800015d4:	8626                	mv	a2,s1
    800015d6:	85ce                	mv	a1,s3
    800015d8:	854a                	mv	a0,s2
    800015da:	00000097          	auipc	ra,0x0
    800015de:	930080e7          	jalr	-1744(ra) # 80000f0a <memmove>
}
    800015e2:	70a2                	ld	ra,40(sp)
    800015e4:	7402                	ld	s0,32(sp)
    800015e6:	64e2                	ld	s1,24(sp)
    800015e8:	6942                	ld	s2,16(sp)
    800015ea:	69a2                	ld	s3,8(sp)
    800015ec:	6a02                	ld	s4,0(sp)
    800015ee:	6145                	addi	sp,sp,48
    800015f0:	8082                	ret
    panic("inituvm: more than a page");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	b5650513          	addi	a0,a0,-1194 # 80008148 <digits+0x130>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f7a080e7          	jalr	-134(ra) # 80000574 <panic>

0000000080001602 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001602:	1101                	addi	sp,sp,-32
    80001604:	ec06                	sd	ra,24(sp)
    80001606:	e822                	sd	s0,16(sp)
    80001608:	e426                	sd	s1,8(sp)
    8000160a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000160c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000160e:	00b67d63          	bleu	a1,a2,80001628 <uvmdealloc+0x26>
    80001612:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001614:	6605                	lui	a2,0x1
    80001616:	167d                	addi	a2,a2,-1
    80001618:	00c487b3          	add	a5,s1,a2
    8000161c:	777d                	lui	a4,0xfffff
    8000161e:	8ff9                	and	a5,a5,a4
    80001620:	962e                	add	a2,a2,a1
    80001622:	8e79                	and	a2,a2,a4
    80001624:	00c7e863          	bltu	a5,a2,80001634 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001628:	8526                	mv	a0,s1
    8000162a:	60e2                	ld	ra,24(sp)
    8000162c:	6442                	ld	s0,16(sp)
    8000162e:	64a2                	ld	s1,8(sp)
    80001630:	6105                	addi	sp,sp,32
    80001632:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001634:	8e1d                	sub	a2,a2,a5
    80001636:	8231                	srli	a2,a2,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001638:	4685                	li	a3,1
    8000163a:	2601                	sext.w	a2,a2
    8000163c:	85be                	mv	a1,a5
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	e52080e7          	jalr	-430(ra) # 80001490 <uvmunmap>
    80001646:	b7cd                	j	80001628 <uvmdealloc+0x26>

0000000080001648 <uvmalloc>:
  if(newsz < oldsz)
    80001648:	0ab66163          	bltu	a2,a1,800016ea <uvmalloc+0xa2>
{
    8000164c:	7139                	addi	sp,sp,-64
    8000164e:	fc06                	sd	ra,56(sp)
    80001650:	f822                	sd	s0,48(sp)
    80001652:	f426                	sd	s1,40(sp)
    80001654:	f04a                	sd	s2,32(sp)
    80001656:	ec4e                	sd	s3,24(sp)
    80001658:	e852                	sd	s4,16(sp)
    8000165a:	e456                	sd	s5,8(sp)
    8000165c:	0080                	addi	s0,sp,64
  oldsz = PGROUNDUP(oldsz);
    8000165e:	6a05                	lui	s4,0x1
    80001660:	1a7d                	addi	s4,s4,-1
    80001662:	95d2                	add	a1,a1,s4
    80001664:	7a7d                	lui	s4,0xfffff
    80001666:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000166a:	08ca7263          	bleu	a2,s4,800016ee <uvmalloc+0xa6>
    8000166e:	89b2                	mv	s3,a2
    80001670:	8aaa                	mv	s5,a0
    80001672:	8952                	mv	s2,s4
    mem = kalloc();
    80001674:	fffff097          	auipc	ra,0xfffff
    80001678:	564080e7          	jalr	1380(ra) # 80000bd8 <kalloc>
    8000167c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000167e:	c51d                	beqz	a0,800016ac <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001680:	6605                	lui	a2,0x1
    80001682:	4581                	li	a1,0
    80001684:	00000097          	auipc	ra,0x0
    80001688:	81a080e7          	jalr	-2022(ra) # 80000e9e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000168c:	4779                	li	a4,30
    8000168e:	86a6                	mv	a3,s1
    80001690:	6605                	lui	a2,0x1
    80001692:	85ca                	mv	a1,s2
    80001694:	8556                	mv	a0,s5
    80001696:	00000097          	auipc	ra,0x0
    8000169a:	c62080e7          	jalr	-926(ra) # 800012f8 <mappages>
    8000169e:	e905                	bnez	a0,800016ce <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800016a0:	6785                	lui	a5,0x1
    800016a2:	993e                	add	s2,s2,a5
    800016a4:	fd3968e3          	bltu	s2,s3,80001674 <uvmalloc+0x2c>
  return newsz;
    800016a8:	854e                	mv	a0,s3
    800016aa:	a809                	j	800016bc <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800016ac:	8652                	mv	a2,s4
    800016ae:	85ca                	mv	a1,s2
    800016b0:	8556                	mv	a0,s5
    800016b2:	00000097          	auipc	ra,0x0
    800016b6:	f50080e7          	jalr	-176(ra) # 80001602 <uvmdealloc>
      return 0;
    800016ba:	4501                	li	a0,0
}
    800016bc:	70e2                	ld	ra,56(sp)
    800016be:	7442                	ld	s0,48(sp)
    800016c0:	74a2                	ld	s1,40(sp)
    800016c2:	7902                	ld	s2,32(sp)
    800016c4:	69e2                	ld	s3,24(sp)
    800016c6:	6a42                	ld	s4,16(sp)
    800016c8:	6aa2                	ld	s5,8(sp)
    800016ca:	6121                	addi	sp,sp,64
    800016cc:	8082                	ret
      kfree(mem);
    800016ce:	8526                	mv	a0,s1
    800016d0:	fffff097          	auipc	ra,0xfffff
    800016d4:	3a2080e7          	jalr	930(ra) # 80000a72 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800016d8:	8652                	mv	a2,s4
    800016da:	85ca                	mv	a1,s2
    800016dc:	8556                	mv	a0,s5
    800016de:	00000097          	auipc	ra,0x0
    800016e2:	f24080e7          	jalr	-220(ra) # 80001602 <uvmdealloc>
      return 0;
    800016e6:	4501                	li	a0,0
    800016e8:	bfd1                	j	800016bc <uvmalloc+0x74>
    return oldsz;
    800016ea:	852e                	mv	a0,a1
}
    800016ec:	8082                	ret
  return newsz;
    800016ee:	8532                	mv	a0,a2
    800016f0:	b7f1                	j	800016bc <uvmalloc+0x74>

00000000800016f2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800016f2:	7179                	addi	sp,sp,-48
    800016f4:	f406                	sd	ra,40(sp)
    800016f6:	f022                	sd	s0,32(sp)
    800016f8:	ec26                	sd	s1,24(sp)
    800016fa:	e84a                	sd	s2,16(sp)
    800016fc:	e44e                	sd	s3,8(sp)
    800016fe:	e052                	sd	s4,0(sp)
    80001700:	1800                	addi	s0,sp,48
    80001702:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001704:	84aa                	mv	s1,a0
    80001706:	6905                	lui	s2,0x1
    80001708:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000170a:	4985                	li	s3,1
    8000170c:	a821                	j	80001724 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000170e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001710:	0532                	slli	a0,a0,0xc
    80001712:	00000097          	auipc	ra,0x0
    80001716:	fe0080e7          	jalr	-32(ra) # 800016f2 <freewalk>
      pagetable[i] = 0;
    8000171a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000171e:	04a1                	addi	s1,s1,8
    80001720:	03248163          	beq	s1,s2,80001742 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001724:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001726:	00f57793          	andi	a5,a0,15
    8000172a:	ff3782e3          	beq	a5,s3,8000170e <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000172e:	8905                	andi	a0,a0,1
    80001730:	d57d                	beqz	a0,8000171e <freewalk+0x2c>
      panic("freewalk: leaf");
    80001732:	00007517          	auipc	a0,0x7
    80001736:	a3650513          	addi	a0,a0,-1482 # 80008168 <digits+0x150>
    8000173a:	fffff097          	auipc	ra,0xfffff
    8000173e:	e3a080e7          	jalr	-454(ra) # 80000574 <panic>
    }
  }
  kfree((void*)pagetable);
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	32e080e7          	jalr	814(ra) # 80000a72 <kfree>
}
    8000174c:	70a2                	ld	ra,40(sp)
    8000174e:	7402                	ld	s0,32(sp)
    80001750:	64e2                	ld	s1,24(sp)
    80001752:	6942                	ld	s2,16(sp)
    80001754:	69a2                	ld	s3,8(sp)
    80001756:	6a02                	ld	s4,0(sp)
    80001758:	6145                	addi	sp,sp,48
    8000175a:	8082                	ret

000000008000175c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000175c:	1101                	addi	sp,sp,-32
    8000175e:	ec06                	sd	ra,24(sp)
    80001760:	e822                	sd	s0,16(sp)
    80001762:	e426                	sd	s1,8(sp)
    80001764:	1000                	addi	s0,sp,32
    80001766:	84aa                	mv	s1,a0
  if(sz > 0)
    80001768:	e999                	bnez	a1,8000177e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000176a:	8526                	mv	a0,s1
    8000176c:	00000097          	auipc	ra,0x0
    80001770:	f86080e7          	jalr	-122(ra) # 800016f2 <freewalk>
}
    80001774:	60e2                	ld	ra,24(sp)
    80001776:	6442                	ld	s0,16(sp)
    80001778:	64a2                	ld	s1,8(sp)
    8000177a:	6105                	addi	sp,sp,32
    8000177c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000177e:	6605                	lui	a2,0x1
    80001780:	167d                	addi	a2,a2,-1
    80001782:	962e                	add	a2,a2,a1
    80001784:	4685                	li	a3,1
    80001786:	8231                	srli	a2,a2,0xc
    80001788:	4581                	li	a1,0
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	d06080e7          	jalr	-762(ra) # 80001490 <uvmunmap>
    80001792:	bfe1                	j	8000176a <uvmfree+0xe>

0000000080001794 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 sz)
{
    80001794:	7139                	addi	sp,sp,-64
    80001796:	fc06                	sd	ra,56(sp)
    80001798:	f822                	sd	s0,48(sp)
    8000179a:	f426                	sd	s1,40(sp)
    8000179c:	f04a                	sd	s2,32(sp)
    8000179e:	ec4e                	sd	s3,24(sp)
    800017a0:	e852                	sd	s4,16(sp)
    800017a2:	e456                	sd	s5,8(sp)
    800017a4:	e05a                	sd	s6,0(sp)
    800017a6:	0080                	addi	s0,sp,64
  pte_t *pte;
  uint64 pa, i;
  uint flags;
//  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800017a8:	c25d                	beqz	a2,8000184e <uvmcopy+0xba>
    800017aa:	8a32                	mv	s4,a2
    800017ac:	8aae                	mv	s5,a1
    800017ae:	8b2a                	mv	s6,a0
    800017b0:	4481                	li	s1,0
    if((pte = walk(old, i, 0)) == 0)
    800017b2:	4601                	li	a2,0
    800017b4:	85a6                	mv	a1,s1
    800017b6:	855a                	mv	a0,s6
    800017b8:	00000097          	auipc	ra,0x0
    800017bc:	9f6080e7          	jalr	-1546(ra) # 800011ae <walk>
    800017c0:	c131                	beqz	a0,80001804 <uvmcopy+0x70>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800017c2:	6118                	ld	a4,0(a0)
    800017c4:	00177793          	andi	a5,a4,1
    800017c8:	c7b1                	beqz	a5,80001814 <uvmcopy+0x80>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800017ca:	00a75913          	srli	s2,a4,0xa
    800017ce:	0932                	slli	s2,s2,0xc
    // 将写标志位设置为0
    *pte = (*pte) & (~PTE_W);
    800017d0:	9b6d                	andi	a4,a4,-5
    *pte = (*pte) | PTE_RSW;
    800017d2:	10076713          	ori	a4,a4,256
    800017d6:	e118                	sd	a4,0(a0)
    flags = PTE_FLAGS(*pte);
//    if((mem = kalloc()) == 0)
//      goto err;
//    memmove(mem, (char*)pa, PGSIZE);
    if(mappages(new, i, PGSIZE, (uint64)pa, flags) != 0){
    800017d8:	3fb77713          	andi	a4,a4,1019
    800017dc:	86ca                	mv	a3,s2
    800017de:	6605                	lui	a2,0x1
    800017e0:	85a6                	mv	a1,s1
    800017e2:	8556                	mv	a0,s5
    800017e4:	00000097          	auipc	ra,0x0
    800017e8:	b14080e7          	jalr	-1260(ra) # 800012f8 <mappages>
    800017ec:	89aa                	mv	s3,a0
    800017ee:	e91d                	bnez	a0,80001824 <uvmcopy+0x90>
//      kfree(mem);
      goto err;
    }
    increase_cnt(pa);
    800017f0:	854a                	mv	a0,s2
    800017f2:	fffff097          	auipc	ra,0xfffff
    800017f6:	4ae080e7          	jalr	1198(ra) # 80000ca0 <increase_cnt>
  for(i = 0; i < sz; i += PGSIZE){
    800017fa:	6785                	lui	a5,0x1
    800017fc:	94be                	add	s1,s1,a5
    800017fe:	fb44eae3          	bltu	s1,s4,800017b2 <uvmcopy+0x1e>
    80001802:	a81d                	j	80001838 <uvmcopy+0xa4>
      panic("uvmcopy: pte should exist");
    80001804:	00007517          	auipc	a0,0x7
    80001808:	97450513          	addi	a0,a0,-1676 # 80008178 <digits+0x160>
    8000180c:	fffff097          	auipc	ra,0xfffff
    80001810:	d68080e7          	jalr	-664(ra) # 80000574 <panic>
      panic("uvmcopy: page not present");
    80001814:	00007517          	auipc	a0,0x7
    80001818:	98450513          	addi	a0,a0,-1660 # 80008198 <digits+0x180>
    8000181c:	fffff097          	auipc	ra,0xfffff
    80001820:	d58080e7          	jalr	-680(ra) # 80000574 <panic>
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1); // TODO
    80001824:	4685                	li	a3,1
    80001826:	00c4d613          	srli	a2,s1,0xc
    8000182a:	4581                	li	a1,0
    8000182c:	8556                	mv	a0,s5
    8000182e:	00000097          	auipc	ra,0x0
    80001832:	c62080e7          	jalr	-926(ra) # 80001490 <uvmunmap>
  return -1;
    80001836:	59fd                	li	s3,-1
}
    80001838:	854e                	mv	a0,s3
    8000183a:	70e2                	ld	ra,56(sp)
    8000183c:	7442                	ld	s0,48(sp)
    8000183e:	74a2                	ld	s1,40(sp)
    80001840:	7902                	ld	s2,32(sp)
    80001842:	69e2                	ld	s3,24(sp)
    80001844:	6a42                	ld	s4,16(sp)
    80001846:	6aa2                	ld	s5,8(sp)
    80001848:	6b02                	ld	s6,0(sp)
    8000184a:	6121                	addi	sp,sp,64
    8000184c:	8082                	ret
  return 0;
    8000184e:	4981                	li	s3,0
    80001850:	b7e5                	j	80001838 <uvmcopy+0xa4>

0000000080001852 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001852:	1141                	addi	sp,sp,-16
    80001854:	e406                	sd	ra,8(sp)
    80001856:	e022                	sd	s0,0(sp)
    80001858:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000185a:	4601                	li	a2,0
    8000185c:	00000097          	auipc	ra,0x0
    80001860:	952080e7          	jalr	-1710(ra) # 800011ae <walk>
  if(pte == 0)
    80001864:	c901                	beqz	a0,80001874 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001866:	611c                	ld	a5,0(a0)
    80001868:	9bbd                	andi	a5,a5,-17
    8000186a:	e11c                	sd	a5,0(a0)
}
    8000186c:	60a2                	ld	ra,8(sp)
    8000186e:	6402                	ld	s0,0(sp)
    80001870:	0141                	addi	sp,sp,16
    80001872:	8082                	ret
    panic("uvmclear");
    80001874:	00007517          	auipc	a0,0x7
    80001878:	94450513          	addi	a0,a0,-1724 # 800081b8 <digits+0x1a0>
    8000187c:	fffff097          	auipc	ra,0xfffff
    80001880:	cf8080e7          	jalr	-776(ra) # 80000574 <panic>

0000000080001884 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001884:	caa5                	beqz	a3,800018f4 <copyin+0x70>
{
    80001886:	715d                	addi	sp,sp,-80
    80001888:	e486                	sd	ra,72(sp)
    8000188a:	e0a2                	sd	s0,64(sp)
    8000188c:	fc26                	sd	s1,56(sp)
    8000188e:	f84a                	sd	s2,48(sp)
    80001890:	f44e                	sd	s3,40(sp)
    80001892:	f052                	sd	s4,32(sp)
    80001894:	ec56                	sd	s5,24(sp)
    80001896:	e85a                	sd	s6,16(sp)
    80001898:	e45e                	sd	s7,8(sp)
    8000189a:	e062                	sd	s8,0(sp)
    8000189c:	0880                	addi	s0,sp,80
    8000189e:	8baa                	mv	s7,a0
    800018a0:	8aae                	mv	s5,a1
    800018a2:	8a32                	mv	s4,a2
    800018a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800018a6:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018a8:	6b05                	lui	s6,0x1
    800018aa:	a01d                	j	800018d0 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800018ac:	014505b3          	add	a1,a0,s4
    800018b0:	0004861b          	sext.w	a2,s1
    800018b4:	412585b3          	sub	a1,a1,s2
    800018b8:	8556                	mv	a0,s5
    800018ba:	fffff097          	auipc	ra,0xfffff
    800018be:	650080e7          	jalr	1616(ra) # 80000f0a <memmove>

    len -= n;
    800018c2:	409989b3          	sub	s3,s3,s1
    dst += n;
    800018c6:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    800018c8:	01690a33          	add	s4,s2,s6
  while(len > 0){
    800018cc:	02098263          	beqz	s3,800018f0 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800018d0:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    800018d4:	85ca                	mv	a1,s2
    800018d6:	855e                	mv	a0,s7
    800018d8:	00000097          	auipc	ra,0x0
    800018dc:	97c080e7          	jalr	-1668(ra) # 80001254 <walkaddr>
    if(pa0 == 0)
    800018e0:	cd01                	beqz	a0,800018f8 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800018e2:	414904b3          	sub	s1,s2,s4
    800018e6:	94da                	add	s1,s1,s6
    if(n > len)
    800018e8:	fc99f2e3          	bleu	s1,s3,800018ac <copyin+0x28>
    800018ec:	84ce                	mv	s1,s3
    800018ee:	bf7d                	j	800018ac <copyin+0x28>
  }
  return 0;
    800018f0:	4501                	li	a0,0
    800018f2:	a021                	j	800018fa <copyin+0x76>
    800018f4:	4501                	li	a0,0
}
    800018f6:	8082                	ret
      return -1;
    800018f8:	557d                	li	a0,-1
}
    800018fa:	60a6                	ld	ra,72(sp)
    800018fc:	6406                	ld	s0,64(sp)
    800018fe:	74e2                	ld	s1,56(sp)
    80001900:	7942                	ld	s2,48(sp)
    80001902:	79a2                	ld	s3,40(sp)
    80001904:	7a02                	ld	s4,32(sp)
    80001906:	6ae2                	ld	s5,24(sp)
    80001908:	6b42                	ld	s6,16(sp)
    8000190a:	6ba2                	ld	s7,8(sp)
    8000190c:	6c02                	ld	s8,0(sp)
    8000190e:	6161                	addi	sp,sp,80
    80001910:	8082                	ret

0000000080001912 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001912:	ced5                	beqz	a3,800019ce <copyinstr+0xbc>
{
    80001914:	715d                	addi	sp,sp,-80
    80001916:	e486                	sd	ra,72(sp)
    80001918:	e0a2                	sd	s0,64(sp)
    8000191a:	fc26                	sd	s1,56(sp)
    8000191c:	f84a                	sd	s2,48(sp)
    8000191e:	f44e                	sd	s3,40(sp)
    80001920:	f052                	sd	s4,32(sp)
    80001922:	ec56                	sd	s5,24(sp)
    80001924:	e85a                	sd	s6,16(sp)
    80001926:	e45e                	sd	s7,8(sp)
    80001928:	e062                	sd	s8,0(sp)
    8000192a:	0880                	addi	s0,sp,80
    8000192c:	8aaa                	mv	s5,a0
    8000192e:	84ae                	mv	s1,a1
    80001930:	8c32                	mv	s8,a2
    80001932:	8bb6                	mv	s7,a3
    va0 = PGROUNDDOWN(srcva);
    80001934:	7a7d                	lui	s4,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001936:	6985                	lui	s3,0x1
    80001938:	4b05                	li	s6,1
    8000193a:	a801                	j	8000194a <copyinstr+0x38>
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
    8000193c:	87a6                	mv	a5,s1
    8000193e:	a085                	j	8000199e <copyinstr+0x8c>
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    80001940:	84b2                	mv	s1,a2
    }

    srcva = va0 + PGSIZE;
    80001942:	01390c33          	add	s8,s2,s3
  while(got_null == 0 && max > 0){
    80001946:	080b8063          	beqz	s7,800019c6 <copyinstr+0xb4>
    va0 = PGROUNDDOWN(srcva);
    8000194a:	014c7933          	and	s2,s8,s4
    pa0 = walkaddr(pagetable, va0);
    8000194e:	85ca                	mv	a1,s2
    80001950:	8556                	mv	a0,s5
    80001952:	00000097          	auipc	ra,0x0
    80001956:	902080e7          	jalr	-1790(ra) # 80001254 <walkaddr>
    if(pa0 == 0)
    8000195a:	c925                	beqz	a0,800019ca <copyinstr+0xb8>
    n = PGSIZE - (srcva - va0);
    8000195c:	41890633          	sub	a2,s2,s8
    80001960:	964e                	add	a2,a2,s3
    if(n > max)
    80001962:	00cbf363          	bleu	a2,s7,80001968 <copyinstr+0x56>
    80001966:	865e                	mv	a2,s7
    char *p = (char *) (pa0 + (srcva - va0));
    80001968:	9562                	add	a0,a0,s8
    8000196a:	41250533          	sub	a0,a0,s2
    while(n > 0){
    8000196e:	da71                	beqz	a2,80001942 <copyinstr+0x30>
      if(*p == '\0'){
    80001970:	00054703          	lbu	a4,0(a0)
    80001974:	d761                	beqz	a4,8000193c <copyinstr+0x2a>
    80001976:	9626                	add	a2,a2,s1
    80001978:	87a6                	mv	a5,s1
    8000197a:	1bfd                	addi	s7,s7,-1
    8000197c:	009b86b3          	add	a3,s7,s1
    80001980:	409b04b3          	sub	s1,s6,s1
    80001984:	94aa                	add	s1,s1,a0
        *dst = *p;
    80001986:	00e78023          	sb	a4,0(a5) # 1000 <_entry-0x7ffff000>
      --max;
    8000198a:	40f68bb3          	sub	s7,a3,a5
      p++;
    8000198e:	00f48733          	add	a4,s1,a5
      dst++;
    80001992:	0785                	addi	a5,a5,1
    while(n > 0){
    80001994:	faf606e3          	beq	a2,a5,80001940 <copyinstr+0x2e>
      if(*p == '\0'){
    80001998:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ff99000>
    8000199c:	f76d                	bnez	a4,80001986 <copyinstr+0x74>
        *dst = '\0';
    8000199e:	00078023          	sb	zero,0(a5)
    800019a2:	4785                	li	a5,1
  }
  if(got_null){
    800019a4:	0017b513          	seqz	a0,a5
    800019a8:	40a0053b          	negw	a0,a0
    800019ac:	2501                	sext.w	a0,a0
    return 0;
  } else {
    return -1;
  }
}
    800019ae:	60a6                	ld	ra,72(sp)
    800019b0:	6406                	ld	s0,64(sp)
    800019b2:	74e2                	ld	s1,56(sp)
    800019b4:	7942                	ld	s2,48(sp)
    800019b6:	79a2                	ld	s3,40(sp)
    800019b8:	7a02                	ld	s4,32(sp)
    800019ba:	6ae2                	ld	s5,24(sp)
    800019bc:	6b42                	ld	s6,16(sp)
    800019be:	6ba2                	ld	s7,8(sp)
    800019c0:	6c02                	ld	s8,0(sp)
    800019c2:	6161                	addi	sp,sp,80
    800019c4:	8082                	ret
    800019c6:	4781                	li	a5,0
    800019c8:	bff1                	j	800019a4 <copyinstr+0x92>
      return -1;
    800019ca:	557d                	li	a0,-1
    800019cc:	b7cd                	j	800019ae <copyinstr+0x9c>
  int got_null = 0;
    800019ce:	4781                	li	a5,0
  if(got_null){
    800019d0:	0017b513          	seqz	a0,a5
    800019d4:	40a0053b          	negw	a0,a0
    800019d8:	2501                	sext.w	a0,a0
}
    800019da:	8082                	ret

00000000800019dc <walkpte>:
pte_t*
walkpte(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;

  if(va >= MAXVA)
    800019dc:	57fd                	li	a5,-1
    800019de:	83e9                	srli	a5,a5,0x1a
    800019e0:	02b7e763          	bltu	a5,a1,80001a0e <walkpte+0x32>
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
    return 0;

  pte = walk(pagetable, va, 0);
    800019ec:	4601                	li	a2,0
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	7c0080e7          	jalr	1984(ra) # 800011ae <walk>
  if(pte == 0)
    800019f6:	c511                	beqz	a0,80001a02 <walkpte+0x26>
    return 0;
  if((*pte & PTE_V) == 0)
    return 0;
  if((*pte & PTE_U) == 0)
    800019f8:	611c                	ld	a5,0(a0)
    800019fa:	8bc5                	andi	a5,a5,17
    800019fc:	4745                	li	a4,17
    800019fe:	00e79663          	bne	a5,a4,80001a0a <walkpte+0x2e>
    return 0;
  return pte;
}
    80001a02:	60a2                	ld	ra,8(sp)
    80001a04:	6402                	ld	s0,0(sp)
    80001a06:	0141                	addi	sp,sp,16
    80001a08:	8082                	ret
    return 0;
    80001a0a:	4501                	li	a0,0
    80001a0c:	bfdd                	j	80001a02 <walkpte+0x26>
    return 0;
    80001a0e:	4501                	li	a0,0
}
    80001a10:	8082                	ret

0000000080001a12 <cownewpage>:
// 该函数的主要作用是，在父进程或者子进程向cow页写东西时，
// 为进程新分配物理页，即物理页的申请是在此时才真正执行，而不是
// fork时申请的
int
cownewpage(pagetable_t pagetable, uint64 va)
{
    80001a12:	7179                	addi	sp,sp,-48
    80001a14:	f406                	sd	ra,40(sp)
    80001a16:	f022                	sd	s0,32(sp)
    80001a18:	ec26                	sd	s1,24(sp)
    80001a1a:	e84a                	sd	s2,16(sp)
    80001a1c:	e44e                	sd	s3,8(sp)
    80001a1e:	1800                	addi	s0,sp,48
//  printf("loop\n");
  va = PGROUNDDOWN(va);
  pte_t* pte = walk(pagetable, va, 0);
    80001a20:	4601                	li	a2,0
    80001a22:	77fd                	lui	a5,0xfffff
    80001a24:	8dfd                	and	a1,a1,a5
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	788080e7          	jalr	1928(ra) # 800011ae <walk>
  if (0 == pte) {
    80001a2e:	c159                	beqz	a0,80001ab4 <cownewpage+0xa2>
    80001a30:	89aa                	mv	s3,a0
//    printf("pte should exist\n");
    return -1;
  }

  if ((*pte & PTE_RSW) == 0) {
    80001a32:	6104                	ld	s1,0(a0)
    return -1;
  }

  if ((*pte & PTE_V) == 0) {
    80001a34:	1014f713          	andi	a4,s1,257
    80001a38:	10100793          	li	a5,257
    80001a3c:	06f71e63          	bne	a4,a5,80001ab8 <cownewpage+0xa6>
//    printf("pte should valid\n");
    return -1;
  }

  uint64 pa = PTE2PA(*pte);
    80001a40:	80a9                	srli	s1,s1,0xa
    80001a42:	04b2                	slli	s1,s1,0xc
  if (get_ref_cnt(pa) == 1) { // only children or only parent
    80001a44:	8526                	mv	a0,s1
    80001a46:	fffff097          	auipc	ra,0xfffff
    80001a4a:	2aa080e7          	jalr	682(ra) # 80000cf0 <get_ref_cnt>
    80001a4e:	4785                	li	a5,1
    80001a50:	04f50863          	beq	a0,a5,80001aa0 <cownewpage+0x8e>
    *pte = *pte | PTE_W;
    *pte = *pte & (~PTE_RSW);
    return 0;
  }

  char* mem = kalloc();
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	184080e7          	jalr	388(ra) # 80000bd8 <kalloc>
    80001a5c:	892a                	mv	s2,a0
  if (0 == mem) {
    80001a5e:	cd39                	beqz	a0,80001abc <cownewpage+0xaa>
//    printf("out of memory\n");
    return -1;
  }

//  decrease_cnt((uint64)pa);
  memmove(mem, (void*)pa, PGSIZE);
    80001a60:	6605                	lui	a2,0x1
    80001a62:	85a6                	mv	a1,s1
    80001a64:	fffff097          	auipc	ra,0xfffff
    80001a68:	4a6080e7          	jalr	1190(ra) # 80000f0a <memmove>
  kfree((void*)pa);
    80001a6c:	8526                	mv	a0,s1
    80001a6e:	fffff097          	auipc	ra,0xfffff
    80001a72:	004080e7          	jalr	4(ra) # 80000a72 <kfree>
  uint64 flag = (PTE_FLAGS(*pte) | (PTE_W)) & (~PTE_RSW);
    80001a76:	0009b783          	ld	a5,0(s3) # 1000 <_entry-0x7ffff000>
    80001a7a:	2fb7f793          	andi	a5,a5,763
  *pte = PA2PTE((uint64)mem) | flag;
    80001a7e:	00c95913          	srli	s2,s2,0xc
    80001a82:	092a                	slli	s2,s2,0xa
    80001a84:	0127e933          	or	s2,a5,s2
    80001a88:	00496913          	ori	s2,s2,4
    80001a8c:	0129b023          	sd	s2,0(s3)
  return 0;
    80001a90:	4501                	li	a0,0
}
    80001a92:	70a2                	ld	ra,40(sp)
    80001a94:	7402                	ld	s0,32(sp)
    80001a96:	64e2                	ld	s1,24(sp)
    80001a98:	6942                	ld	s2,16(sp)
    80001a9a:	69a2                	ld	s3,8(sp)
    80001a9c:	6145                	addi	sp,sp,48
    80001a9e:	8082                	ret
    *pte = *pte & (~PTE_RSW);
    80001aa0:	0009b783          	ld	a5,0(s3)
    80001aa4:	eff7f793          	andi	a5,a5,-257
    80001aa8:	0047e793          	ori	a5,a5,4
    80001aac:	00f9b023          	sd	a5,0(s3)
    return 0;
    80001ab0:	4501                	li	a0,0
    80001ab2:	b7c5                	j	80001a92 <cownewpage+0x80>
    return -1;
    80001ab4:	557d                	li	a0,-1
    80001ab6:	bff1                	j	80001a92 <cownewpage+0x80>
    return -1;
    80001ab8:	557d                	li	a0,-1
    80001aba:	bfe1                	j	80001a92 <cownewpage+0x80>
    return -1;
    80001abc:	557d                	li	a0,-1
    80001abe:	bfd1                	j	80001a92 <cownewpage+0x80>

0000000080001ac0 <copyout>:
  while(len > 0){
    80001ac0:	c6dd                	beqz	a3,80001b6e <copyout+0xae>
{
    80001ac2:	715d                	addi	sp,sp,-80
    80001ac4:	e486                	sd	ra,72(sp)
    80001ac6:	e0a2                	sd	s0,64(sp)
    80001ac8:	fc26                	sd	s1,56(sp)
    80001aca:	f84a                	sd	s2,48(sp)
    80001acc:	f44e                	sd	s3,40(sp)
    80001ace:	f052                	sd	s4,32(sp)
    80001ad0:	ec56                	sd	s5,24(sp)
    80001ad2:	e85a                	sd	s6,16(sp)
    80001ad4:	e45e                	sd	s7,8(sp)
    80001ad6:	e062                	sd	s8,0(sp)
    80001ad8:	0880                	addi	s0,sp,80
    80001ada:	8baa                	mv	s7,a0
    80001adc:	892e                	mv	s2,a1
    80001ade:	8ab2                	mv	s5,a2
    80001ae0:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001ae2:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (dstva - va0);
    80001ae4:	6b05                	lui	s6,0x1
    80001ae6:	a8b1                	j	80001b42 <copyout+0x82>
      if (cownewpage(pagetable, va0) < 0) {
    80001ae8:	85ce                	mv	a1,s3
    80001aea:	855e                	mv	a0,s7
    80001aec:	00000097          	auipc	ra,0x0
    80001af0:	f26080e7          	jalr	-218(ra) # 80001a12 <cownewpage>
    80001af4:	00054963          	bltz	a0,80001b06 <copyout+0x46>
        pte = walkpte(pagetable, va0);
    80001af8:	85ce                	mv	a1,s3
    80001afa:	855e                	mv	a0,s7
    80001afc:	00000097          	auipc	ra,0x0
    80001b00:	ee0080e7          	jalr	-288(ra) # 800019dc <walkpte>
    80001b04:	a8a1                	j	80001b5c <copyout+0x9c>
        printf("copyout: cow failed\n");
    80001b06:	00006517          	auipc	a0,0x6
    80001b0a:	6c250513          	addi	a0,a0,1730 # 800081c8 <digits+0x1b0>
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	ab0080e7          	jalr	-1360(ra) # 800005be <printf>
        return -1;
    80001b16:	557d                	li	a0,-1
    80001b18:	a8b1                	j	80001b74 <copyout+0xb4>
    pa0 = PTE2PA(*pte);
    80001b1a:	611c                	ld	a5,0(a0)
    80001b1c:	83a9                	srli	a5,a5,0xa
    80001b1e:	07b2                	slli	a5,a5,0xc
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001b20:	41390533          	sub	a0,s2,s3
    80001b24:	0004861b          	sext.w	a2,s1
    80001b28:	85d6                	mv	a1,s5
    80001b2a:	953e                	add	a0,a0,a5
    80001b2c:	fffff097          	auipc	ra,0xfffff
    80001b30:	3de080e7          	jalr	990(ra) # 80000f0a <memmove>
    len -= n;
    80001b34:	409a0a33          	sub	s4,s4,s1
    src += n;
    80001b38:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    80001b3a:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001b3e:	020a0663          	beqz	s4,80001b6a <copyout+0xaa>
    va0 = PGROUNDDOWN(dstva);
    80001b42:	018979b3          	and	s3,s2,s8
    pte = walkpte(pagetable, va0);
    80001b46:	85ce                	mv	a1,s3
    80001b48:	855e                	mv	a0,s7
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	e92080e7          	jalr	-366(ra) # 800019dc <walkpte>
    if (0 == pte) {
    80001b52:	c105                	beqz	a0,80001b72 <copyout+0xb2>
    if ((*pte & PTE_RSW)) {
    80001b54:	611c                	ld	a5,0(a0)
    80001b56:	1007f793          	andi	a5,a5,256
    80001b5a:	f7d9                	bnez	a5,80001ae8 <copyout+0x28>
    n = PGSIZE - (dstva - va0);
    80001b5c:	412984b3          	sub	s1,s3,s2
    80001b60:	94da                	add	s1,s1,s6
    if(n > len)
    80001b62:	fa9a7ce3          	bleu	s1,s4,80001b1a <copyout+0x5a>
    80001b66:	84d2                	mv	s1,s4
    80001b68:	bf4d                	j	80001b1a <copyout+0x5a>
  return 0;
    80001b6a:	4501                	li	a0,0
    80001b6c:	a021                	j	80001b74 <copyout+0xb4>
    80001b6e:	4501                	li	a0,0
}
    80001b70:	8082                	ret
      return -1;
    80001b72:	557d                	li	a0,-1
}
    80001b74:	60a6                	ld	ra,72(sp)
    80001b76:	6406                	ld	s0,64(sp)
    80001b78:	74e2                	ld	s1,56(sp)
    80001b7a:	7942                	ld	s2,48(sp)
    80001b7c:	79a2                	ld	s3,40(sp)
    80001b7e:	7a02                	ld	s4,32(sp)
    80001b80:	6ae2                	ld	s5,24(sp)
    80001b82:	6b42                	ld	s6,16(sp)
    80001b84:	6ba2                	ld	s7,8(sp)
    80001b86:	6c02                	ld	s8,0(sp)
    80001b88:	6161                	addi	sp,sp,80
    80001b8a:	8082                	ret

0000000080001b8c <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001b8c:	1101                	addi	sp,sp,-32
    80001b8e:	ec06                	sd	ra,24(sp)
    80001b90:	e822                	sd	s0,16(sp)
    80001b92:	e426                	sd	s1,8(sp)
    80001b94:	1000                	addi	s0,sp,32
    80001b96:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001b98:	fffff097          	auipc	ra,0xfffff
    80001b9c:	190080e7          	jalr	400(ra) # 80000d28 <holding>
    80001ba0:	c909                	beqz	a0,80001bb2 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001ba2:	749c                	ld	a5,40(s1)
    80001ba4:	00978f63          	beq	a5,s1,80001bc2 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6105                	addi	sp,sp,32
    80001bb0:	8082                	ret
    panic("wakeup1");
    80001bb2:	00006517          	auipc	a0,0x6
    80001bb6:	65650513          	addi	a0,a0,1622 # 80008208 <states.1738+0x28>
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	9ba080e7          	jalr	-1606(ra) # 80000574 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001bc2:	4c98                	lw	a4,24(s1)
    80001bc4:	4785                	li	a5,1
    80001bc6:	fef711e3          	bne	a4,a5,80001ba8 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001bca:	4789                	li	a5,2
    80001bcc:	cc9c                	sw	a5,24(s1)
}
    80001bce:	bfe9                	j	80001ba8 <wakeup1+0x1c>

0000000080001bd0 <procinit>:
{
    80001bd0:	715d                	addi	sp,sp,-80
    80001bd2:	e486                	sd	ra,72(sp)
    80001bd4:	e0a2                	sd	s0,64(sp)
    80001bd6:	fc26                	sd	s1,56(sp)
    80001bd8:	f84a                	sd	s2,48(sp)
    80001bda:	f44e                	sd	s3,40(sp)
    80001bdc:	f052                	sd	s4,32(sp)
    80001bde:	ec56                	sd	s5,24(sp)
    80001be0:	e85a                	sd	s6,16(sp)
    80001be2:	e45e                	sd	s7,8(sp)
    80001be4:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001be6:	00006597          	auipc	a1,0x6
    80001bea:	62a58593          	addi	a1,a1,1578 # 80008210 <states.1738+0x30>
    80001bee:	00050517          	auipc	a0,0x50
    80001bf2:	d6250513          	addi	a0,a0,-670 # 80051950 <pid_lock>
    80001bf6:	fffff097          	auipc	ra,0xfffff
    80001bfa:	11c080e7          	jalr	284(ra) # 80000d12 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bfe:	00050917          	auipc	s2,0x50
    80001c02:	16a90913          	addi	s2,s2,362 # 80051d68 <proc>
      initlock(&p->lock, "proc");
    80001c06:	00006b97          	auipc	s7,0x6
    80001c0a:	612b8b93          	addi	s7,s7,1554 # 80008218 <states.1738+0x38>
      uint64 va = KSTACK((int) (p - proc));
    80001c0e:	8b4a                	mv	s6,s2
    80001c10:	00006a97          	auipc	s5,0x6
    80001c14:	3f0a8a93          	addi	s5,s5,1008 # 80008000 <etext>
    80001c18:	040009b7          	lui	s3,0x4000
    80001c1c:	19fd                	addi	s3,s3,-1
    80001c1e:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c20:	00056a17          	auipc	s4,0x56
    80001c24:	b48a0a13          	addi	s4,s4,-1208 # 80057768 <tickslock>
      initlock(&p->lock, "proc");
    80001c28:	85de                	mv	a1,s7
    80001c2a:	854a                	mv	a0,s2
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0e6080e7          	jalr	230(ra) # 80000d12 <initlock>
      char *pa = kalloc();
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	fa4080e7          	jalr	-92(ra) # 80000bd8 <kalloc>
    80001c3c:	85aa                	mv	a1,a0
      if(pa == 0)
    80001c3e:	c929                	beqz	a0,80001c90 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001c40:	416904b3          	sub	s1,s2,s6
    80001c44:	848d                	srai	s1,s1,0x3
    80001c46:	000ab783          	ld	a5,0(s5)
    80001c4a:	02f484b3          	mul	s1,s1,a5
    80001c4e:	2485                	addiw	s1,s1,1
    80001c50:	00d4949b          	slliw	s1,s1,0xd
    80001c54:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c58:	4699                	li	a3,6
    80001c5a:	6605                	lui	a2,0x1
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	726080e7          	jalr	1830(ra) # 80001384 <kvmmap>
      p->kstack = va;
    80001c66:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c6a:	16890913          	addi	s2,s2,360
    80001c6e:	fb491de3          	bne	s2,s4,80001c28 <procinit+0x58>
  kvminithart();
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	516080e7          	jalr	1302(ra) # 80001188 <kvminithart>
}
    80001c7a:	60a6                	ld	ra,72(sp)
    80001c7c:	6406                	ld	s0,64(sp)
    80001c7e:	74e2                	ld	s1,56(sp)
    80001c80:	7942                	ld	s2,48(sp)
    80001c82:	79a2                	ld	s3,40(sp)
    80001c84:	7a02                	ld	s4,32(sp)
    80001c86:	6ae2                	ld	s5,24(sp)
    80001c88:	6b42                	ld	s6,16(sp)
    80001c8a:	6ba2                	ld	s7,8(sp)
    80001c8c:	6161                	addi	sp,sp,80
    80001c8e:	8082                	ret
        panic("kalloc");
    80001c90:	00006517          	auipc	a0,0x6
    80001c94:	59050513          	addi	a0,a0,1424 # 80008220 <states.1738+0x40>
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	8dc080e7          	jalr	-1828(ra) # 80000574 <panic>

0000000080001ca0 <cpuid>:
{
    80001ca0:	1141                	addi	sp,sp,-16
    80001ca2:	e422                	sd	s0,8(sp)
    80001ca4:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ca6:	8512                	mv	a0,tp
}
    80001ca8:	2501                	sext.w	a0,a0
    80001caa:	6422                	ld	s0,8(sp)
    80001cac:	0141                	addi	sp,sp,16
    80001cae:	8082                	ret

0000000080001cb0 <mycpu>:
mycpu(void) {
    80001cb0:	1141                	addi	sp,sp,-16
    80001cb2:	e422                	sd	s0,8(sp)
    80001cb4:	0800                	addi	s0,sp,16
    80001cb6:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001cb8:	2781                	sext.w	a5,a5
    80001cba:	079e                	slli	a5,a5,0x7
}
    80001cbc:	00050517          	auipc	a0,0x50
    80001cc0:	cac50513          	addi	a0,a0,-852 # 80051968 <cpus>
    80001cc4:	953e                	add	a0,a0,a5
    80001cc6:	6422                	ld	s0,8(sp)
    80001cc8:	0141                	addi	sp,sp,16
    80001cca:	8082                	ret

0000000080001ccc <myproc>:
myproc(void) {
    80001ccc:	1101                	addi	sp,sp,-32
    80001cce:	ec06                	sd	ra,24(sp)
    80001cd0:	e822                	sd	s0,16(sp)
    80001cd2:	e426                	sd	s1,8(sp)
    80001cd4:	1000                	addi	s0,sp,32
  push_off();
    80001cd6:	fffff097          	auipc	ra,0xfffff
    80001cda:	080080e7          	jalr	128(ra) # 80000d56 <push_off>
    80001cde:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001ce0:	2781                	sext.w	a5,a5
    80001ce2:	079e                	slli	a5,a5,0x7
    80001ce4:	00050717          	auipc	a4,0x50
    80001ce8:	c6c70713          	addi	a4,a4,-916 # 80051950 <pid_lock>
    80001cec:	97ba                	add	a5,a5,a4
    80001cee:	6f84                	ld	s1,24(a5)
  pop_off();
    80001cf0:	fffff097          	auipc	ra,0xfffff
    80001cf4:	106080e7          	jalr	262(ra) # 80000df6 <pop_off>
}
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	60e2                	ld	ra,24(sp)
    80001cfc:	6442                	ld	s0,16(sp)
    80001cfe:	64a2                	ld	s1,8(sp)
    80001d00:	6105                	addi	sp,sp,32
    80001d02:	8082                	ret

0000000080001d04 <forkret>:
{
    80001d04:	1141                	addi	sp,sp,-16
    80001d06:	e406                	sd	ra,8(sp)
    80001d08:	e022                	sd	s0,0(sp)
    80001d0a:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001d0c:	00000097          	auipc	ra,0x0
    80001d10:	fc0080e7          	jalr	-64(ra) # 80001ccc <myproc>
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	142080e7          	jalr	322(ra) # 80000e56 <release>
  if (first) {
    80001d1c:	00007797          	auipc	a5,0x7
    80001d20:	b1478793          	addi	a5,a5,-1260 # 80008830 <first.1698>
    80001d24:	439c                	lw	a5,0(a5)
    80001d26:	eb89                	bnez	a5,80001d38 <forkret+0x34>
  usertrapret();
    80001d28:	00001097          	auipc	ra,0x1
    80001d2c:	c26080e7          	jalr	-986(ra) # 8000294e <usertrapret>
}
    80001d30:	60a2                	ld	ra,8(sp)
    80001d32:	6402                	ld	s0,0(sp)
    80001d34:	0141                	addi	sp,sp,16
    80001d36:	8082                	ret
    first = 0;
    80001d38:	00007797          	auipc	a5,0x7
    80001d3c:	ae07ac23          	sw	zero,-1288(a5) # 80008830 <first.1698>
    fsinit(ROOTDEV);
    80001d40:	4505                	li	a0,1
    80001d42:	00002097          	auipc	ra,0x2
    80001d46:	9cc080e7          	jalr	-1588(ra) # 8000370e <fsinit>
    80001d4a:	bff9                	j	80001d28 <forkret+0x24>

0000000080001d4c <allocpid>:
allocpid() {
    80001d4c:	1101                	addi	sp,sp,-32
    80001d4e:	ec06                	sd	ra,24(sp)
    80001d50:	e822                	sd	s0,16(sp)
    80001d52:	e426                	sd	s1,8(sp)
    80001d54:	e04a                	sd	s2,0(sp)
    80001d56:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001d58:	00050917          	auipc	s2,0x50
    80001d5c:	bf890913          	addi	s2,s2,-1032 # 80051950 <pid_lock>
    80001d60:	854a                	mv	a0,s2
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	040080e7          	jalr	64(ra) # 80000da2 <acquire>
  pid = nextpid;
    80001d6a:	00007797          	auipc	a5,0x7
    80001d6e:	aca78793          	addi	a5,a5,-1334 # 80008834 <nextpid>
    80001d72:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001d74:	0014871b          	addiw	a4,s1,1
    80001d78:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001d7a:	854a                	mv	a0,s2
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	0da080e7          	jalr	218(ra) # 80000e56 <release>
}
    80001d84:	8526                	mv	a0,s1
    80001d86:	60e2                	ld	ra,24(sp)
    80001d88:	6442                	ld	s0,16(sp)
    80001d8a:	64a2                	ld	s1,8(sp)
    80001d8c:	6902                	ld	s2,0(sp)
    80001d8e:	6105                	addi	sp,sp,32
    80001d90:	8082                	ret

0000000080001d92 <proc_pagetable>:
{
    80001d92:	1101                	addi	sp,sp,-32
    80001d94:	ec06                	sd	ra,24(sp)
    80001d96:	e822                	sd	s0,16(sp)
    80001d98:	e426                	sd	s1,8(sp)
    80001d9a:	e04a                	sd	s2,0(sp)
    80001d9c:	1000                	addi	s0,sp,32
    80001d9e:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001da0:	fffff097          	auipc	ra,0xfffff
    80001da4:	7c2080e7          	jalr	1986(ra) # 80001562 <uvmcreate>
    80001da8:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001daa:	c121                	beqz	a0,80001dea <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001dac:	4729                	li	a4,10
    80001dae:	00005697          	auipc	a3,0x5
    80001db2:	25268693          	addi	a3,a3,594 # 80007000 <_trampoline>
    80001db6:	6605                	lui	a2,0x1
    80001db8:	040005b7          	lui	a1,0x4000
    80001dbc:	15fd                	addi	a1,a1,-1
    80001dbe:	05b2                	slli	a1,a1,0xc
    80001dc0:	fffff097          	auipc	ra,0xfffff
    80001dc4:	538080e7          	jalr	1336(ra) # 800012f8 <mappages>
    80001dc8:	02054863          	bltz	a0,80001df8 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dcc:	4719                	li	a4,6
    80001dce:	05893683          	ld	a3,88(s2)
    80001dd2:	6605                	lui	a2,0x1
    80001dd4:	020005b7          	lui	a1,0x2000
    80001dd8:	15fd                	addi	a1,a1,-1
    80001dda:	05b6                	slli	a1,a1,0xd
    80001ddc:	8526                	mv	a0,s1
    80001dde:	fffff097          	auipc	ra,0xfffff
    80001de2:	51a080e7          	jalr	1306(ra) # 800012f8 <mappages>
    80001de6:	02054163          	bltz	a0,80001e08 <proc_pagetable+0x76>
}
    80001dea:	8526                	mv	a0,s1
    80001dec:	60e2                	ld	ra,24(sp)
    80001dee:	6442                	ld	s0,16(sp)
    80001df0:	64a2                	ld	s1,8(sp)
    80001df2:	6902                	ld	s2,0(sp)
    80001df4:	6105                	addi	sp,sp,32
    80001df6:	8082                	ret
    uvmfree(pagetable, 0);
    80001df8:	4581                	li	a1,0
    80001dfa:	8526                	mv	a0,s1
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	960080e7          	jalr	-1696(ra) # 8000175c <uvmfree>
    return 0;
    80001e04:	4481                	li	s1,0
    80001e06:	b7d5                	j	80001dea <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e08:	4681                	li	a3,0
    80001e0a:	4605                	li	a2,1
    80001e0c:	040005b7          	lui	a1,0x4000
    80001e10:	15fd                	addi	a1,a1,-1
    80001e12:	05b2                	slli	a1,a1,0xc
    80001e14:	8526                	mv	a0,s1
    80001e16:	fffff097          	auipc	ra,0xfffff
    80001e1a:	67a080e7          	jalr	1658(ra) # 80001490 <uvmunmap>
    uvmfree(pagetable, 0);
    80001e1e:	4581                	li	a1,0
    80001e20:	8526                	mv	a0,s1
    80001e22:	00000097          	auipc	ra,0x0
    80001e26:	93a080e7          	jalr	-1734(ra) # 8000175c <uvmfree>
    return 0;
    80001e2a:	4481                	li	s1,0
    80001e2c:	bf7d                	j	80001dea <proc_pagetable+0x58>

0000000080001e2e <proc_freepagetable>:
{
    80001e2e:	1101                	addi	sp,sp,-32
    80001e30:	ec06                	sd	ra,24(sp)
    80001e32:	e822                	sd	s0,16(sp)
    80001e34:	e426                	sd	s1,8(sp)
    80001e36:	e04a                	sd	s2,0(sp)
    80001e38:	1000                	addi	s0,sp,32
    80001e3a:	84aa                	mv	s1,a0
    80001e3c:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e3e:	4681                	li	a3,0
    80001e40:	4605                	li	a2,1
    80001e42:	040005b7          	lui	a1,0x4000
    80001e46:	15fd                	addi	a1,a1,-1
    80001e48:	05b2                	slli	a1,a1,0xc
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	646080e7          	jalr	1606(ra) # 80001490 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e52:	4681                	li	a3,0
    80001e54:	4605                	li	a2,1
    80001e56:	020005b7          	lui	a1,0x2000
    80001e5a:	15fd                	addi	a1,a1,-1
    80001e5c:	05b6                	slli	a1,a1,0xd
    80001e5e:	8526                	mv	a0,s1
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	630080e7          	jalr	1584(ra) # 80001490 <uvmunmap>
  uvmfree(pagetable, sz);
    80001e68:	85ca                	mv	a1,s2
    80001e6a:	8526                	mv	a0,s1
    80001e6c:	00000097          	auipc	ra,0x0
    80001e70:	8f0080e7          	jalr	-1808(ra) # 8000175c <uvmfree>
}
    80001e74:	60e2                	ld	ra,24(sp)
    80001e76:	6442                	ld	s0,16(sp)
    80001e78:	64a2                	ld	s1,8(sp)
    80001e7a:	6902                	ld	s2,0(sp)
    80001e7c:	6105                	addi	sp,sp,32
    80001e7e:	8082                	ret

0000000080001e80 <freeproc>:
{
    80001e80:	1101                	addi	sp,sp,-32
    80001e82:	ec06                	sd	ra,24(sp)
    80001e84:	e822                	sd	s0,16(sp)
    80001e86:	e426                	sd	s1,8(sp)
    80001e88:	1000                	addi	s0,sp,32
    80001e8a:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001e8c:	6d28                	ld	a0,88(a0)
    80001e8e:	c509                	beqz	a0,80001e98 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	be2080e7          	jalr	-1054(ra) # 80000a72 <kfree>
  p->trapframe = 0;
    80001e98:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001e9c:	68a8                	ld	a0,80(s1)
    80001e9e:	c511                	beqz	a0,80001eaa <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ea0:	64ac                	ld	a1,72(s1)
    80001ea2:	00000097          	auipc	ra,0x0
    80001ea6:	f8c080e7          	jalr	-116(ra) # 80001e2e <proc_freepagetable>
  p->pagetable = 0;
    80001eaa:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001eae:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001eb2:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001eb6:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001eba:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ebe:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001ec2:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001ec6:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001eca:	0004ac23          	sw	zero,24(s1)
}
    80001ece:	60e2                	ld	ra,24(sp)
    80001ed0:	6442                	ld	s0,16(sp)
    80001ed2:	64a2                	ld	s1,8(sp)
    80001ed4:	6105                	addi	sp,sp,32
    80001ed6:	8082                	ret

0000000080001ed8 <allocproc>:
{
    80001ed8:	1101                	addi	sp,sp,-32
    80001eda:	ec06                	sd	ra,24(sp)
    80001edc:	e822                	sd	s0,16(sp)
    80001ede:	e426                	sd	s1,8(sp)
    80001ee0:	e04a                	sd	s2,0(sp)
    80001ee2:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ee4:	00050497          	auipc	s1,0x50
    80001ee8:	e8448493          	addi	s1,s1,-380 # 80051d68 <proc>
    80001eec:	00056917          	auipc	s2,0x56
    80001ef0:	87c90913          	addi	s2,s2,-1924 # 80057768 <tickslock>
    acquire(&p->lock);
    80001ef4:	8526                	mv	a0,s1
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	eac080e7          	jalr	-340(ra) # 80000da2 <acquire>
    if(p->state == UNUSED) {
    80001efe:	4c9c                	lw	a5,24(s1)
    80001f00:	cf81                	beqz	a5,80001f18 <allocproc+0x40>
      release(&p->lock);
    80001f02:	8526                	mv	a0,s1
    80001f04:	fffff097          	auipc	ra,0xfffff
    80001f08:	f52080e7          	jalr	-174(ra) # 80000e56 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f0c:	16848493          	addi	s1,s1,360
    80001f10:	ff2492e3          	bne	s1,s2,80001ef4 <allocproc+0x1c>
  return 0;
    80001f14:	4481                	li	s1,0
    80001f16:	a0b9                	j	80001f64 <allocproc+0x8c>
  p->pid = allocpid();
    80001f18:	00000097          	auipc	ra,0x0
    80001f1c:	e34080e7          	jalr	-460(ra) # 80001d4c <allocpid>
    80001f20:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	cb6080e7          	jalr	-842(ra) # 80000bd8 <kalloc>
    80001f2a:	892a                	mv	s2,a0
    80001f2c:	eca8                	sd	a0,88(s1)
    80001f2e:	c131                	beqz	a0,80001f72 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001f30:	8526                	mv	a0,s1
    80001f32:	00000097          	auipc	ra,0x0
    80001f36:	e60080e7          	jalr	-416(ra) # 80001d92 <proc_pagetable>
    80001f3a:	892a                	mv	s2,a0
    80001f3c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001f3e:	c129                	beqz	a0,80001f80 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001f40:	07000613          	li	a2,112
    80001f44:	4581                	li	a1,0
    80001f46:	06048513          	addi	a0,s1,96
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	f54080e7          	jalr	-172(ra) # 80000e9e <memset>
  p->context.ra = (uint64)forkret;
    80001f52:	00000797          	auipc	a5,0x0
    80001f56:	db278793          	addi	a5,a5,-590 # 80001d04 <forkret>
    80001f5a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f5c:	60bc                	ld	a5,64(s1)
    80001f5e:	6705                	lui	a4,0x1
    80001f60:	97ba                	add	a5,a5,a4
    80001f62:	f4bc                	sd	a5,104(s1)
}
    80001f64:	8526                	mv	a0,s1
    80001f66:	60e2                	ld	ra,24(sp)
    80001f68:	6442                	ld	s0,16(sp)
    80001f6a:	64a2                	ld	s1,8(sp)
    80001f6c:	6902                	ld	s2,0(sp)
    80001f6e:	6105                	addi	sp,sp,32
    80001f70:	8082                	ret
    release(&p->lock);
    80001f72:	8526                	mv	a0,s1
    80001f74:	fffff097          	auipc	ra,0xfffff
    80001f78:	ee2080e7          	jalr	-286(ra) # 80000e56 <release>
    return 0;
    80001f7c:	84ca                	mv	s1,s2
    80001f7e:	b7dd                	j	80001f64 <allocproc+0x8c>
    freeproc(p);
    80001f80:	8526                	mv	a0,s1
    80001f82:	00000097          	auipc	ra,0x0
    80001f86:	efe080e7          	jalr	-258(ra) # 80001e80 <freeproc>
    release(&p->lock);
    80001f8a:	8526                	mv	a0,s1
    80001f8c:	fffff097          	auipc	ra,0xfffff
    80001f90:	eca080e7          	jalr	-310(ra) # 80000e56 <release>
    return 0;
    80001f94:	84ca                	mv	s1,s2
    80001f96:	b7f9                	j	80001f64 <allocproc+0x8c>

0000000080001f98 <userinit>:
{
    80001f98:	1101                	addi	sp,sp,-32
    80001f9a:	ec06                	sd	ra,24(sp)
    80001f9c:	e822                	sd	s0,16(sp)
    80001f9e:	e426                	sd	s1,8(sp)
    80001fa0:	1000                	addi	s0,sp,32
  p = allocproc();
    80001fa2:	00000097          	auipc	ra,0x0
    80001fa6:	f36080e7          	jalr	-202(ra) # 80001ed8 <allocproc>
    80001faa:	84aa                	mv	s1,a0
  initproc = p;
    80001fac:	00007797          	auipc	a5,0x7
    80001fb0:	06a7b623          	sd	a0,108(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001fb4:	03400613          	li	a2,52
    80001fb8:	00007597          	auipc	a1,0x7
    80001fbc:	88858593          	addi	a1,a1,-1912 # 80008840 <initcode>
    80001fc0:	6928                	ld	a0,80(a0)
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	5ce080e7          	jalr	1486(ra) # 80001590 <uvminit>
  p->sz = PGSIZE;
    80001fca:	6785                	lui	a5,0x1
    80001fcc:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001fce:	6cb8                	ld	a4,88(s1)
    80001fd0:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001fd4:	6cb8                	ld	a4,88(s1)
    80001fd6:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fd8:	4641                	li	a2,16
    80001fda:	00006597          	auipc	a1,0x6
    80001fde:	24e58593          	addi	a1,a1,590 # 80008228 <states.1738+0x48>
    80001fe2:	15848513          	addi	a0,s1,344
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	030080e7          	jalr	48(ra) # 80001016 <safestrcpy>
  p->cwd = namei("/");
    80001fee:	00006517          	auipc	a0,0x6
    80001ff2:	24a50513          	addi	a0,a0,586 # 80008238 <states.1738+0x58>
    80001ff6:	00002097          	auipc	ra,0x2
    80001ffa:	150080e7          	jalr	336(ra) # 80004146 <namei>
    80001ffe:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80002002:	4789                	li	a5,2
    80002004:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002006:	8526                	mv	a0,s1
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	e4e080e7          	jalr	-434(ra) # 80000e56 <release>
}
    80002010:	60e2                	ld	ra,24(sp)
    80002012:	6442                	ld	s0,16(sp)
    80002014:	64a2                	ld	s1,8(sp)
    80002016:	6105                	addi	sp,sp,32
    80002018:	8082                	ret

000000008000201a <growproc>:
{
    8000201a:	1101                	addi	sp,sp,-32
    8000201c:	ec06                	sd	ra,24(sp)
    8000201e:	e822                	sd	s0,16(sp)
    80002020:	e426                	sd	s1,8(sp)
    80002022:	e04a                	sd	s2,0(sp)
    80002024:	1000                	addi	s0,sp,32
    80002026:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	ca4080e7          	jalr	-860(ra) # 80001ccc <myproc>
    80002030:	892a                	mv	s2,a0
  sz = p->sz;
    80002032:	652c                	ld	a1,72(a0)
    80002034:	0005851b          	sext.w	a0,a1
  if(n > 0){
    80002038:	00904f63          	bgtz	s1,80002056 <growproc+0x3c>
  } else if(n < 0){
    8000203c:	0204cd63          	bltz	s1,80002076 <growproc+0x5c>
  p->sz = sz;
    80002040:	1502                	slli	a0,a0,0x20
    80002042:	9101                	srli	a0,a0,0x20
    80002044:	04a93423          	sd	a0,72(s2)
  return 0;
    80002048:	4501                	li	a0,0
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6902                	ld	s2,0(sp)
    80002052:	6105                	addi	sp,sp,32
    80002054:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002056:	00a4863b          	addw	a2,s1,a0
    8000205a:	1602                	slli	a2,a2,0x20
    8000205c:	9201                	srli	a2,a2,0x20
    8000205e:	1582                	slli	a1,a1,0x20
    80002060:	9181                	srli	a1,a1,0x20
    80002062:	05093503          	ld	a0,80(s2)
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	5e2080e7          	jalr	1506(ra) # 80001648 <uvmalloc>
    8000206e:	2501                	sext.w	a0,a0
    80002070:	f961                	bnez	a0,80002040 <growproc+0x26>
      return -1;
    80002072:	557d                	li	a0,-1
    80002074:	bfd9                	j	8000204a <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002076:	00a4863b          	addw	a2,s1,a0
    8000207a:	1602                	slli	a2,a2,0x20
    8000207c:	9201                	srli	a2,a2,0x20
    8000207e:	1582                	slli	a1,a1,0x20
    80002080:	9181                	srli	a1,a1,0x20
    80002082:	05093503          	ld	a0,80(s2)
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	57c080e7          	jalr	1404(ra) # 80001602 <uvmdealloc>
    8000208e:	2501                	sext.w	a0,a0
    80002090:	bf45                	j	80002040 <growproc+0x26>

0000000080002092 <fork>:
{
    80002092:	7179                	addi	sp,sp,-48
    80002094:	f406                	sd	ra,40(sp)
    80002096:	f022                	sd	s0,32(sp)
    80002098:	ec26                	sd	s1,24(sp)
    8000209a:	e84a                	sd	s2,16(sp)
    8000209c:	e44e                	sd	s3,8(sp)
    8000209e:	e052                	sd	s4,0(sp)
    800020a0:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020a2:	00000097          	auipc	ra,0x0
    800020a6:	c2a080e7          	jalr	-982(ra) # 80001ccc <myproc>
    800020aa:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800020ac:	00000097          	auipc	ra,0x0
    800020b0:	e2c080e7          	jalr	-468(ra) # 80001ed8 <allocproc>
    800020b4:	c175                	beqz	a0,80002198 <fork+0x106>
    800020b6:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    800020b8:	04893603          	ld	a2,72(s2)
    800020bc:	692c                	ld	a1,80(a0)
    800020be:	05093503          	ld	a0,80(s2)
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	6d2080e7          	jalr	1746(ra) # 80001794 <uvmcopy>
    800020ca:	04054863          	bltz	a0,8000211a <fork+0x88>
  np->sz = p->sz;
    800020ce:	04893783          	ld	a5,72(s2)
    800020d2:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    800020d6:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    800020da:	05893683          	ld	a3,88(s2)
    800020de:	87b6                	mv	a5,a3
    800020e0:	0589b703          	ld	a4,88(s3)
    800020e4:	12068693          	addi	a3,a3,288
    800020e8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800020ec:	6788                	ld	a0,8(a5)
    800020ee:	6b8c                	ld	a1,16(a5)
    800020f0:	6f90                	ld	a2,24(a5)
    800020f2:	01073023          	sd	a6,0(a4)
    800020f6:	e708                	sd	a0,8(a4)
    800020f8:	eb0c                	sd	a1,16(a4)
    800020fa:	ef10                	sd	a2,24(a4)
    800020fc:	02078793          	addi	a5,a5,32
    80002100:	02070713          	addi	a4,a4,32
    80002104:	fed792e3          	bne	a5,a3,800020e8 <fork+0x56>
  np->trapframe->a0 = 0;
    80002108:	0589b783          	ld	a5,88(s3)
    8000210c:	0607b823          	sd	zero,112(a5)
    80002110:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80002114:	15000a13          	li	s4,336
    80002118:	a03d                	j	80002146 <fork+0xb4>
    freeproc(np);
    8000211a:	854e                	mv	a0,s3
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	d64080e7          	jalr	-668(ra) # 80001e80 <freeproc>
    release(&np->lock);
    80002124:	854e                	mv	a0,s3
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	d30080e7          	jalr	-720(ra) # 80000e56 <release>
    return -1;
    8000212e:	54fd                	li	s1,-1
    80002130:	a899                	j	80002186 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002132:	00002097          	auipc	ra,0x2
    80002136:	6d2080e7          	jalr	1746(ra) # 80004804 <filedup>
    8000213a:	009987b3          	add	a5,s3,s1
    8000213e:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002140:	04a1                	addi	s1,s1,8
    80002142:	01448763          	beq	s1,s4,80002150 <fork+0xbe>
    if(p->ofile[i])
    80002146:	009907b3          	add	a5,s2,s1
    8000214a:	6388                	ld	a0,0(a5)
    8000214c:	f17d                	bnez	a0,80002132 <fork+0xa0>
    8000214e:	bfcd                	j	80002140 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002150:	15093503          	ld	a0,336(s2)
    80002154:	00001097          	auipc	ra,0x1
    80002158:	7f6080e7          	jalr	2038(ra) # 8000394a <idup>
    8000215c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002160:	4641                	li	a2,16
    80002162:	15890593          	addi	a1,s2,344
    80002166:	15898513          	addi	a0,s3,344
    8000216a:	fffff097          	auipc	ra,0xfffff
    8000216e:	eac080e7          	jalr	-340(ra) # 80001016 <safestrcpy>
  pid = np->pid;
    80002172:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002176:	4789                	li	a5,2
    80002178:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    8000217c:	854e                	mv	a0,s3
    8000217e:	fffff097          	auipc	ra,0xfffff
    80002182:	cd8080e7          	jalr	-808(ra) # 80000e56 <release>
}
    80002186:	8526                	mv	a0,s1
    80002188:	70a2                	ld	ra,40(sp)
    8000218a:	7402                	ld	s0,32(sp)
    8000218c:	64e2                	ld	s1,24(sp)
    8000218e:	6942                	ld	s2,16(sp)
    80002190:	69a2                	ld	s3,8(sp)
    80002192:	6a02                	ld	s4,0(sp)
    80002194:	6145                	addi	sp,sp,48
    80002196:	8082                	ret
    return -1;
    80002198:	54fd                	li	s1,-1
    8000219a:	b7f5                	j	80002186 <fork+0xf4>

000000008000219c <reparent>:
{
    8000219c:	7179                	addi	sp,sp,-48
    8000219e:	f406                	sd	ra,40(sp)
    800021a0:	f022                	sd	s0,32(sp)
    800021a2:	ec26                	sd	s1,24(sp)
    800021a4:	e84a                	sd	s2,16(sp)
    800021a6:	e44e                	sd	s3,8(sp)
    800021a8:	e052                	sd	s4,0(sp)
    800021aa:	1800                	addi	s0,sp,48
    800021ac:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021ae:	00050497          	auipc	s1,0x50
    800021b2:	bba48493          	addi	s1,s1,-1094 # 80051d68 <proc>
      pp->parent = initproc;
    800021b6:	00007a17          	auipc	s4,0x7
    800021ba:	e62a0a13          	addi	s4,s4,-414 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021be:	00055917          	auipc	s2,0x55
    800021c2:	5aa90913          	addi	s2,s2,1450 # 80057768 <tickslock>
    800021c6:	a029                	j	800021d0 <reparent+0x34>
    800021c8:	16848493          	addi	s1,s1,360
    800021cc:	03248363          	beq	s1,s2,800021f2 <reparent+0x56>
    if(pp->parent == p){
    800021d0:	709c                	ld	a5,32(s1)
    800021d2:	ff379be3          	bne	a5,s3,800021c8 <reparent+0x2c>
      acquire(&pp->lock);
    800021d6:	8526                	mv	a0,s1
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	bca080e7          	jalr	-1078(ra) # 80000da2 <acquire>
      pp->parent = initproc;
    800021e0:	000a3783          	ld	a5,0(s4)
    800021e4:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	c6e080e7          	jalr	-914(ra) # 80000e56 <release>
    800021f0:	bfe1                	j	800021c8 <reparent+0x2c>
}
    800021f2:	70a2                	ld	ra,40(sp)
    800021f4:	7402                	ld	s0,32(sp)
    800021f6:	64e2                	ld	s1,24(sp)
    800021f8:	6942                	ld	s2,16(sp)
    800021fa:	69a2                	ld	s3,8(sp)
    800021fc:	6a02                	ld	s4,0(sp)
    800021fe:	6145                	addi	sp,sp,48
    80002200:	8082                	ret

0000000080002202 <scheduler>:
{
    80002202:	711d                	addi	sp,sp,-96
    80002204:	ec86                	sd	ra,88(sp)
    80002206:	e8a2                	sd	s0,80(sp)
    80002208:	e4a6                	sd	s1,72(sp)
    8000220a:	e0ca                	sd	s2,64(sp)
    8000220c:	fc4e                	sd	s3,56(sp)
    8000220e:	f852                	sd	s4,48(sp)
    80002210:	f456                	sd	s5,40(sp)
    80002212:	f05a                	sd	s6,32(sp)
    80002214:	ec5e                	sd	s7,24(sp)
    80002216:	e862                	sd	s8,16(sp)
    80002218:	e466                	sd	s9,8(sp)
    8000221a:	1080                	addi	s0,sp,96
    8000221c:	8792                	mv	a5,tp
  int id = r_tp();
    8000221e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002220:	00779c13          	slli	s8,a5,0x7
    80002224:	0004f717          	auipc	a4,0x4f
    80002228:	72c70713          	addi	a4,a4,1836 # 80051950 <pid_lock>
    8000222c:	9762                	add	a4,a4,s8
    8000222e:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002232:	0004f717          	auipc	a4,0x4f
    80002236:	73e70713          	addi	a4,a4,1854 # 80051970 <cpus+0x8>
    8000223a:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    8000223c:	4a89                	li	s5,2
        c->proc = p;
    8000223e:	079e                	slli	a5,a5,0x7
    80002240:	0004fb17          	auipc	s6,0x4f
    80002244:	710b0b13          	addi	s6,s6,1808 # 80051950 <pid_lock>
    80002248:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000224a:	00055a17          	auipc	s4,0x55
    8000224e:	51ea0a13          	addi	s4,s4,1310 # 80057768 <tickslock>
    int nproc = 0;
    80002252:	4c81                	li	s9,0
    80002254:	a8a1                	j	800022ac <scheduler+0xaa>
        p->state = RUNNING;
    80002256:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    8000225a:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    8000225e:	06048593          	addi	a1,s1,96
    80002262:	8562                	mv	a0,s8
    80002264:	00000097          	auipc	ra,0x0
    80002268:	640080e7          	jalr	1600(ra) # 800028a4 <swtch>
        c->proc = 0;
    8000226c:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80002270:	8526                	mv	a0,s1
    80002272:	fffff097          	auipc	ra,0xfffff
    80002276:	be4080e7          	jalr	-1052(ra) # 80000e56 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000227a:	16848493          	addi	s1,s1,360
    8000227e:	01448d63          	beq	s1,s4,80002298 <scheduler+0x96>
      acquire(&p->lock);
    80002282:	8526                	mv	a0,s1
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	b1e080e7          	jalr	-1250(ra) # 80000da2 <acquire>
      if(p->state != UNUSED) {
    8000228c:	4c9c                	lw	a5,24(s1)
    8000228e:	d3ed                	beqz	a5,80002270 <scheduler+0x6e>
        nproc++;
    80002290:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002292:	fd579fe3          	bne	a5,s5,80002270 <scheduler+0x6e>
    80002296:	b7c1                	j	80002256 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002298:	013aca63          	blt	s5,s3,800022ac <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000229c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022a0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022a4:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800022a8:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800022b0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800022b4:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800022b8:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800022ba:	00050497          	auipc	s1,0x50
    800022be:	aae48493          	addi	s1,s1,-1362 # 80051d68 <proc>
        p->state = RUNNING;
    800022c2:	4b8d                	li	s7,3
    800022c4:	bf7d                	j	80002282 <scheduler+0x80>

00000000800022c6 <sched>:
{
    800022c6:	7179                	addi	sp,sp,-48
    800022c8:	f406                	sd	ra,40(sp)
    800022ca:	f022                	sd	s0,32(sp)
    800022cc:	ec26                	sd	s1,24(sp)
    800022ce:	e84a                	sd	s2,16(sp)
    800022d0:	e44e                	sd	s3,8(sp)
    800022d2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	9f8080e7          	jalr	-1544(ra) # 80001ccc <myproc>
    800022dc:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	a4a080e7          	jalr	-1462(ra) # 80000d28 <holding>
    800022e6:	cd25                	beqz	a0,8000235e <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022e8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800022ea:	2781                	sext.w	a5,a5
    800022ec:	079e                	slli	a5,a5,0x7
    800022ee:	0004f717          	auipc	a4,0x4f
    800022f2:	66270713          	addi	a4,a4,1634 # 80051950 <pid_lock>
    800022f6:	97ba                	add	a5,a5,a4
    800022f8:	0907a703          	lw	a4,144(a5)
    800022fc:	4785                	li	a5,1
    800022fe:	06f71863          	bne	a4,a5,8000236e <sched+0xa8>
  if(p->state == RUNNING)
    80002302:	01892703          	lw	a4,24(s2)
    80002306:	478d                	li	a5,3
    80002308:	06f70b63          	beq	a4,a5,8000237e <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000230c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002310:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002312:	efb5                	bnez	a5,8000238e <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002314:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002316:	0004f497          	auipc	s1,0x4f
    8000231a:	63a48493          	addi	s1,s1,1594 # 80051950 <pid_lock>
    8000231e:	2781                	sext.w	a5,a5
    80002320:	079e                	slli	a5,a5,0x7
    80002322:	97a6                	add	a5,a5,s1
    80002324:	0947a983          	lw	s3,148(a5)
    80002328:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000232a:	2781                	sext.w	a5,a5
    8000232c:	079e                	slli	a5,a5,0x7
    8000232e:	0004f597          	auipc	a1,0x4f
    80002332:	64258593          	addi	a1,a1,1602 # 80051970 <cpus+0x8>
    80002336:	95be                	add	a1,a1,a5
    80002338:	06090513          	addi	a0,s2,96
    8000233c:	00000097          	auipc	ra,0x0
    80002340:	568080e7          	jalr	1384(ra) # 800028a4 <swtch>
    80002344:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002346:	2781                	sext.w	a5,a5
    80002348:	079e                	slli	a5,a5,0x7
    8000234a:	97a6                	add	a5,a5,s1
    8000234c:	0937aa23          	sw	s3,148(a5)
}
    80002350:	70a2                	ld	ra,40(sp)
    80002352:	7402                	ld	s0,32(sp)
    80002354:	64e2                	ld	s1,24(sp)
    80002356:	6942                	ld	s2,16(sp)
    80002358:	69a2                	ld	s3,8(sp)
    8000235a:	6145                	addi	sp,sp,48
    8000235c:	8082                	ret
    panic("sched p->lock");
    8000235e:	00006517          	auipc	a0,0x6
    80002362:	ee250513          	addi	a0,a0,-286 # 80008240 <states.1738+0x60>
    80002366:	ffffe097          	auipc	ra,0xffffe
    8000236a:	20e080e7          	jalr	526(ra) # 80000574 <panic>
    panic("sched locks");
    8000236e:	00006517          	auipc	a0,0x6
    80002372:	ee250513          	addi	a0,a0,-286 # 80008250 <states.1738+0x70>
    80002376:	ffffe097          	auipc	ra,0xffffe
    8000237a:	1fe080e7          	jalr	510(ra) # 80000574 <panic>
    panic("sched running");
    8000237e:	00006517          	auipc	a0,0x6
    80002382:	ee250513          	addi	a0,a0,-286 # 80008260 <states.1738+0x80>
    80002386:	ffffe097          	auipc	ra,0xffffe
    8000238a:	1ee080e7          	jalr	494(ra) # 80000574 <panic>
    panic("sched interruptible");
    8000238e:	00006517          	auipc	a0,0x6
    80002392:	ee250513          	addi	a0,a0,-286 # 80008270 <states.1738+0x90>
    80002396:	ffffe097          	auipc	ra,0xffffe
    8000239a:	1de080e7          	jalr	478(ra) # 80000574 <panic>

000000008000239e <exit>:
{
    8000239e:	7179                	addi	sp,sp,-48
    800023a0:	f406                	sd	ra,40(sp)
    800023a2:	f022                	sd	s0,32(sp)
    800023a4:	ec26                	sd	s1,24(sp)
    800023a6:	e84a                	sd	s2,16(sp)
    800023a8:	e44e                	sd	s3,8(sp)
    800023aa:	e052                	sd	s4,0(sp)
    800023ac:	1800                	addi	s0,sp,48
    800023ae:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023b0:	00000097          	auipc	ra,0x0
    800023b4:	91c080e7          	jalr	-1764(ra) # 80001ccc <myproc>
    800023b8:	89aa                	mv	s3,a0
  if(p == initproc)
    800023ba:	00007797          	auipc	a5,0x7
    800023be:	c5e78793          	addi	a5,a5,-930 # 80009018 <initproc>
    800023c2:	639c                	ld	a5,0(a5)
    800023c4:	0d050493          	addi	s1,a0,208
    800023c8:	15050913          	addi	s2,a0,336
    800023cc:	02a79363          	bne	a5,a0,800023f2 <exit+0x54>
    panic("init exiting");
    800023d0:	00006517          	auipc	a0,0x6
    800023d4:	eb850513          	addi	a0,a0,-328 # 80008288 <states.1738+0xa8>
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	19c080e7          	jalr	412(ra) # 80000574 <panic>
      fileclose(f);
    800023e0:	00002097          	auipc	ra,0x2
    800023e4:	476080e7          	jalr	1142(ra) # 80004856 <fileclose>
      p->ofile[fd] = 0;
    800023e8:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023ec:	04a1                	addi	s1,s1,8
    800023ee:	01248563          	beq	s1,s2,800023f8 <exit+0x5a>
    if(p->ofile[fd]){
    800023f2:	6088                	ld	a0,0(s1)
    800023f4:	f575                	bnez	a0,800023e0 <exit+0x42>
    800023f6:	bfdd                	j	800023ec <exit+0x4e>
  begin_op();
    800023f8:	00002097          	auipc	ra,0x2
    800023fc:	f5c080e7          	jalr	-164(ra) # 80004354 <begin_op>
  iput(p->cwd);
    80002400:	1509b503          	ld	a0,336(s3)
    80002404:	00001097          	auipc	ra,0x1
    80002408:	740080e7          	jalr	1856(ra) # 80003b44 <iput>
  end_op();
    8000240c:	00002097          	auipc	ra,0x2
    80002410:	fc8080e7          	jalr	-56(ra) # 800043d4 <end_op>
  p->cwd = 0;
    80002414:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002418:	00007497          	auipc	s1,0x7
    8000241c:	c0048493          	addi	s1,s1,-1024 # 80009018 <initproc>
    80002420:	6088                	ld	a0,0(s1)
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	980080e7          	jalr	-1664(ra) # 80000da2 <acquire>
  wakeup1(initproc);
    8000242a:	6088                	ld	a0,0(s1)
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	760080e7          	jalr	1888(ra) # 80001b8c <wakeup1>
  release(&initproc->lock);
    80002434:	6088                	ld	a0,0(s1)
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	a20080e7          	jalr	-1504(ra) # 80000e56 <release>
  acquire(&p->lock);
    8000243e:	854e                	mv	a0,s3
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	962080e7          	jalr	-1694(ra) # 80000da2 <acquire>
  struct proc *original_parent = p->parent;
    80002448:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000244c:	854e                	mv	a0,s3
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	a08080e7          	jalr	-1528(ra) # 80000e56 <release>
  acquire(&original_parent->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	94a080e7          	jalr	-1718(ra) # 80000da2 <acquire>
  acquire(&p->lock);
    80002460:	854e                	mv	a0,s3
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	940080e7          	jalr	-1728(ra) # 80000da2 <acquire>
  reparent(p);
    8000246a:	854e                	mv	a0,s3
    8000246c:	00000097          	auipc	ra,0x0
    80002470:	d30080e7          	jalr	-720(ra) # 8000219c <reparent>
  wakeup1(original_parent);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	716080e7          	jalr	1814(ra) # 80001b8c <wakeup1>
  p->xstate = status;
    8000247e:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002482:	4791                	li	a5,4
    80002484:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002488:	8526                	mv	a0,s1
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	9cc080e7          	jalr	-1588(ra) # 80000e56 <release>
  sched();
    80002492:	00000097          	auipc	ra,0x0
    80002496:	e34080e7          	jalr	-460(ra) # 800022c6 <sched>
  panic("zombie exit");
    8000249a:	00006517          	auipc	a0,0x6
    8000249e:	dfe50513          	addi	a0,a0,-514 # 80008298 <states.1738+0xb8>
    800024a2:	ffffe097          	auipc	ra,0xffffe
    800024a6:	0d2080e7          	jalr	210(ra) # 80000574 <panic>

00000000800024aa <yield>:
{
    800024aa:	1101                	addi	sp,sp,-32
    800024ac:	ec06                	sd	ra,24(sp)
    800024ae:	e822                	sd	s0,16(sp)
    800024b0:	e426                	sd	s1,8(sp)
    800024b2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	818080e7          	jalr	-2024(ra) # 80001ccc <myproc>
    800024bc:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024be:	fffff097          	auipc	ra,0xfffff
    800024c2:	8e4080e7          	jalr	-1820(ra) # 80000da2 <acquire>
  p->state = RUNNABLE;
    800024c6:	4789                	li	a5,2
    800024c8:	cc9c                	sw	a5,24(s1)
  sched();
    800024ca:	00000097          	auipc	ra,0x0
    800024ce:	dfc080e7          	jalr	-516(ra) # 800022c6 <sched>
  release(&p->lock);
    800024d2:	8526                	mv	a0,s1
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	982080e7          	jalr	-1662(ra) # 80000e56 <release>
}
    800024dc:	60e2                	ld	ra,24(sp)
    800024de:	6442                	ld	s0,16(sp)
    800024e0:	64a2                	ld	s1,8(sp)
    800024e2:	6105                	addi	sp,sp,32
    800024e4:	8082                	ret

00000000800024e6 <sleep>:
{
    800024e6:	7179                	addi	sp,sp,-48
    800024e8:	f406                	sd	ra,40(sp)
    800024ea:	f022                	sd	s0,32(sp)
    800024ec:	ec26                	sd	s1,24(sp)
    800024ee:	e84a                	sd	s2,16(sp)
    800024f0:	e44e                	sd	s3,8(sp)
    800024f2:	1800                	addi	s0,sp,48
    800024f4:	89aa                	mv	s3,a0
    800024f6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800024f8:	fffff097          	auipc	ra,0xfffff
    800024fc:	7d4080e7          	jalr	2004(ra) # 80001ccc <myproc>
    80002500:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002502:	05250663          	beq	a0,s2,8000254e <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	89c080e7          	jalr	-1892(ra) # 80000da2 <acquire>
    release(lk);
    8000250e:	854a                	mv	a0,s2
    80002510:	fffff097          	auipc	ra,0xfffff
    80002514:	946080e7          	jalr	-1722(ra) # 80000e56 <release>
  p->chan = chan;
    80002518:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000251c:	4785                	li	a5,1
    8000251e:	cc9c                	sw	a5,24(s1)
  sched();
    80002520:	00000097          	auipc	ra,0x0
    80002524:	da6080e7          	jalr	-602(ra) # 800022c6 <sched>
  p->chan = 0;
    80002528:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000252c:	8526                	mv	a0,s1
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	928080e7          	jalr	-1752(ra) # 80000e56 <release>
    acquire(lk);
    80002536:	854a                	mv	a0,s2
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	86a080e7          	jalr	-1942(ra) # 80000da2 <acquire>
}
    80002540:	70a2                	ld	ra,40(sp)
    80002542:	7402                	ld	s0,32(sp)
    80002544:	64e2                	ld	s1,24(sp)
    80002546:	6942                	ld	s2,16(sp)
    80002548:	69a2                	ld	s3,8(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
  p->chan = chan;
    8000254e:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002552:	4785                	li	a5,1
    80002554:	cd1c                	sw	a5,24(a0)
  sched();
    80002556:	00000097          	auipc	ra,0x0
    8000255a:	d70080e7          	jalr	-656(ra) # 800022c6 <sched>
  p->chan = 0;
    8000255e:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002562:	bff9                	j	80002540 <sleep+0x5a>

0000000080002564 <wait>:
{
    80002564:	715d                	addi	sp,sp,-80
    80002566:	e486                	sd	ra,72(sp)
    80002568:	e0a2                	sd	s0,64(sp)
    8000256a:	fc26                	sd	s1,56(sp)
    8000256c:	f84a                	sd	s2,48(sp)
    8000256e:	f44e                	sd	s3,40(sp)
    80002570:	f052                	sd	s4,32(sp)
    80002572:	ec56                	sd	s5,24(sp)
    80002574:	e85a                	sd	s6,16(sp)
    80002576:	e45e                	sd	s7,8(sp)
    80002578:	e062                	sd	s8,0(sp)
    8000257a:	0880                	addi	s0,sp,80
    8000257c:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    8000257e:	fffff097          	auipc	ra,0xfffff
    80002582:	74e080e7          	jalr	1870(ra) # 80001ccc <myproc>
    80002586:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002588:	8c2a                	mv	s8,a0
    8000258a:	fffff097          	auipc	ra,0xfffff
    8000258e:	818080e7          	jalr	-2024(ra) # 80000da2 <acquire>
    havekids = 0;
    80002592:	4b01                	li	s6,0
        if(np->state == ZOMBIE){
    80002594:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002596:	00055997          	auipc	s3,0x55
    8000259a:	1d298993          	addi	s3,s3,466 # 80057768 <tickslock>
        havekids = 1;
    8000259e:	4a85                	li	s5,1
    havekids = 0;
    800025a0:	875a                	mv	a4,s6
    for(np = proc; np < &proc[NPROC]; np++){
    800025a2:	0004f497          	auipc	s1,0x4f
    800025a6:	7c648493          	addi	s1,s1,1990 # 80051d68 <proc>
    800025aa:	a08d                	j	8000260c <wait+0xa8>
          pid = np->pid;
    800025ac:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800025b0:	000b8e63          	beqz	s7,800025cc <wait+0x68>
    800025b4:	4691                	li	a3,4
    800025b6:	03448613          	addi	a2,s1,52
    800025ba:	85de                	mv	a1,s7
    800025bc:	05093503          	ld	a0,80(s2)
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	500080e7          	jalr	1280(ra) # 80001ac0 <copyout>
    800025c8:	02054263          	bltz	a0,800025ec <wait+0x88>
          freeproc(np);
    800025cc:	8526                	mv	a0,s1
    800025ce:	00000097          	auipc	ra,0x0
    800025d2:	8b2080e7          	jalr	-1870(ra) # 80001e80 <freeproc>
          release(&np->lock);
    800025d6:	8526                	mv	a0,s1
    800025d8:	fffff097          	auipc	ra,0xfffff
    800025dc:	87e080e7          	jalr	-1922(ra) # 80000e56 <release>
          release(&p->lock);
    800025e0:	854a                	mv	a0,s2
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	874080e7          	jalr	-1932(ra) # 80000e56 <release>
          return pid;
    800025ea:	a8a9                	j	80002644 <wait+0xe0>
            release(&np->lock);
    800025ec:	8526                	mv	a0,s1
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	868080e7          	jalr	-1944(ra) # 80000e56 <release>
            release(&p->lock);
    800025f6:	854a                	mv	a0,s2
    800025f8:	fffff097          	auipc	ra,0xfffff
    800025fc:	85e080e7          	jalr	-1954(ra) # 80000e56 <release>
            return -1;
    80002600:	59fd                	li	s3,-1
    80002602:	a089                	j	80002644 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002604:	16848493          	addi	s1,s1,360
    80002608:	03348463          	beq	s1,s3,80002630 <wait+0xcc>
      if(np->parent == p){
    8000260c:	709c                	ld	a5,32(s1)
    8000260e:	ff279be3          	bne	a5,s2,80002604 <wait+0xa0>
        acquire(&np->lock);
    80002612:	8526                	mv	a0,s1
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	78e080e7          	jalr	1934(ra) # 80000da2 <acquire>
        if(np->state == ZOMBIE){
    8000261c:	4c9c                	lw	a5,24(s1)
    8000261e:	f94787e3          	beq	a5,s4,800025ac <wait+0x48>
        release(&np->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	fffff097          	auipc	ra,0xfffff
    80002628:	832080e7          	jalr	-1998(ra) # 80000e56 <release>
        havekids = 1;
    8000262c:	8756                	mv	a4,s5
    8000262e:	bfd9                	j	80002604 <wait+0xa0>
    if(!havekids || p->killed){
    80002630:	c701                	beqz	a4,80002638 <wait+0xd4>
    80002632:	03092783          	lw	a5,48(s2)
    80002636:	c785                	beqz	a5,8000265e <wait+0xfa>
      release(&p->lock);
    80002638:	854a                	mv	a0,s2
    8000263a:	fffff097          	auipc	ra,0xfffff
    8000263e:	81c080e7          	jalr	-2020(ra) # 80000e56 <release>
      return -1;
    80002642:	59fd                	li	s3,-1
}
    80002644:	854e                	mv	a0,s3
    80002646:	60a6                	ld	ra,72(sp)
    80002648:	6406                	ld	s0,64(sp)
    8000264a:	74e2                	ld	s1,56(sp)
    8000264c:	7942                	ld	s2,48(sp)
    8000264e:	79a2                	ld	s3,40(sp)
    80002650:	7a02                	ld	s4,32(sp)
    80002652:	6ae2                	ld	s5,24(sp)
    80002654:	6b42                	ld	s6,16(sp)
    80002656:	6ba2                	ld	s7,8(sp)
    80002658:	6c02                	ld	s8,0(sp)
    8000265a:	6161                	addi	sp,sp,80
    8000265c:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000265e:	85e2                	mv	a1,s8
    80002660:	854a                	mv	a0,s2
    80002662:	00000097          	auipc	ra,0x0
    80002666:	e84080e7          	jalr	-380(ra) # 800024e6 <sleep>
    havekids = 0;
    8000266a:	bf1d                	j	800025a0 <wait+0x3c>

000000008000266c <wakeup>:
{
    8000266c:	7139                	addi	sp,sp,-64
    8000266e:	fc06                	sd	ra,56(sp)
    80002670:	f822                	sd	s0,48(sp)
    80002672:	f426                	sd	s1,40(sp)
    80002674:	f04a                	sd	s2,32(sp)
    80002676:	ec4e                	sd	s3,24(sp)
    80002678:	e852                	sd	s4,16(sp)
    8000267a:	e456                	sd	s5,8(sp)
    8000267c:	0080                	addi	s0,sp,64
    8000267e:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002680:	0004f497          	auipc	s1,0x4f
    80002684:	6e848493          	addi	s1,s1,1768 # 80051d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002688:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000268a:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000268c:	00055917          	auipc	s2,0x55
    80002690:	0dc90913          	addi	s2,s2,220 # 80057768 <tickslock>
    80002694:	a821                	j	800026ac <wakeup+0x40>
      p->state = RUNNABLE;
    80002696:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000269a:	8526                	mv	a0,s1
    8000269c:	ffffe097          	auipc	ra,0xffffe
    800026a0:	7ba080e7          	jalr	1978(ra) # 80000e56 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800026a4:	16848493          	addi	s1,s1,360
    800026a8:	01248e63          	beq	s1,s2,800026c4 <wakeup+0x58>
    acquire(&p->lock);
    800026ac:	8526                	mv	a0,s1
    800026ae:	ffffe097          	auipc	ra,0xffffe
    800026b2:	6f4080e7          	jalr	1780(ra) # 80000da2 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800026b6:	4c9c                	lw	a5,24(s1)
    800026b8:	ff3791e3          	bne	a5,s3,8000269a <wakeup+0x2e>
    800026bc:	749c                	ld	a5,40(s1)
    800026be:	fd479ee3          	bne	a5,s4,8000269a <wakeup+0x2e>
    800026c2:	bfd1                	j	80002696 <wakeup+0x2a>
}
    800026c4:	70e2                	ld	ra,56(sp)
    800026c6:	7442                	ld	s0,48(sp)
    800026c8:	74a2                	ld	s1,40(sp)
    800026ca:	7902                	ld	s2,32(sp)
    800026cc:	69e2                	ld	s3,24(sp)
    800026ce:	6a42                	ld	s4,16(sp)
    800026d0:	6aa2                	ld	s5,8(sp)
    800026d2:	6121                	addi	sp,sp,64
    800026d4:	8082                	ret

00000000800026d6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800026d6:	7179                	addi	sp,sp,-48
    800026d8:	f406                	sd	ra,40(sp)
    800026da:	f022                	sd	s0,32(sp)
    800026dc:	ec26                	sd	s1,24(sp)
    800026de:	e84a                	sd	s2,16(sp)
    800026e0:	e44e                	sd	s3,8(sp)
    800026e2:	1800                	addi	s0,sp,48
    800026e4:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800026e6:	0004f497          	auipc	s1,0x4f
    800026ea:	68248493          	addi	s1,s1,1666 # 80051d68 <proc>
    800026ee:	00055997          	auipc	s3,0x55
    800026f2:	07a98993          	addi	s3,s3,122 # 80057768 <tickslock>
    acquire(&p->lock);
    800026f6:	8526                	mv	a0,s1
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	6aa080e7          	jalr	1706(ra) # 80000da2 <acquire>
    if(p->pid == pid){
    80002700:	5c9c                	lw	a5,56(s1)
    80002702:	01278d63          	beq	a5,s2,8000271c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002706:	8526                	mv	a0,s1
    80002708:	ffffe097          	auipc	ra,0xffffe
    8000270c:	74e080e7          	jalr	1870(ra) # 80000e56 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002710:	16848493          	addi	s1,s1,360
    80002714:	ff3491e3          	bne	s1,s3,800026f6 <kill+0x20>
  }
  return -1;
    80002718:	557d                	li	a0,-1
    8000271a:	a829                	j	80002734 <kill+0x5e>
      p->killed = 1;
    8000271c:	4785                	li	a5,1
    8000271e:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002720:	4c98                	lw	a4,24(s1)
    80002722:	4785                	li	a5,1
    80002724:	00f70f63          	beq	a4,a5,80002742 <kill+0x6c>
      release(&p->lock);
    80002728:	8526                	mv	a0,s1
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	72c080e7          	jalr	1836(ra) # 80000e56 <release>
      return 0;
    80002732:	4501                	li	a0,0
}
    80002734:	70a2                	ld	ra,40(sp)
    80002736:	7402                	ld	s0,32(sp)
    80002738:	64e2                	ld	s1,24(sp)
    8000273a:	6942                	ld	s2,16(sp)
    8000273c:	69a2                	ld	s3,8(sp)
    8000273e:	6145                	addi	sp,sp,48
    80002740:	8082                	ret
        p->state = RUNNABLE;
    80002742:	4789                	li	a5,2
    80002744:	cc9c                	sw	a5,24(s1)
    80002746:	b7cd                	j	80002728 <kill+0x52>

0000000080002748 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002748:	7179                	addi	sp,sp,-48
    8000274a:	f406                	sd	ra,40(sp)
    8000274c:	f022                	sd	s0,32(sp)
    8000274e:	ec26                	sd	s1,24(sp)
    80002750:	e84a                	sd	s2,16(sp)
    80002752:	e44e                	sd	s3,8(sp)
    80002754:	e052                	sd	s4,0(sp)
    80002756:	1800                	addi	s0,sp,48
    80002758:	84aa                	mv	s1,a0
    8000275a:	892e                	mv	s2,a1
    8000275c:	89b2                	mv	s3,a2
    8000275e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002760:	fffff097          	auipc	ra,0xfffff
    80002764:	56c080e7          	jalr	1388(ra) # 80001ccc <myproc>
  if(user_dst){
    80002768:	c08d                	beqz	s1,8000278a <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000276a:	86d2                	mv	a3,s4
    8000276c:	864e                	mv	a2,s3
    8000276e:	85ca                	mv	a1,s2
    80002770:	6928                	ld	a0,80(a0)
    80002772:	fffff097          	auipc	ra,0xfffff
    80002776:	34e080e7          	jalr	846(ra) # 80001ac0 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000277a:	70a2                	ld	ra,40(sp)
    8000277c:	7402                	ld	s0,32(sp)
    8000277e:	64e2                	ld	s1,24(sp)
    80002780:	6942                	ld	s2,16(sp)
    80002782:	69a2                	ld	s3,8(sp)
    80002784:	6a02                	ld	s4,0(sp)
    80002786:	6145                	addi	sp,sp,48
    80002788:	8082                	ret
    memmove((char *)dst, src, len);
    8000278a:	000a061b          	sext.w	a2,s4
    8000278e:	85ce                	mv	a1,s3
    80002790:	854a                	mv	a0,s2
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	778080e7          	jalr	1912(ra) # 80000f0a <memmove>
    return 0;
    8000279a:	8526                	mv	a0,s1
    8000279c:	bff9                	j	8000277a <either_copyout+0x32>

000000008000279e <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000279e:	7179                	addi	sp,sp,-48
    800027a0:	f406                	sd	ra,40(sp)
    800027a2:	f022                	sd	s0,32(sp)
    800027a4:	ec26                	sd	s1,24(sp)
    800027a6:	e84a                	sd	s2,16(sp)
    800027a8:	e44e                	sd	s3,8(sp)
    800027aa:	e052                	sd	s4,0(sp)
    800027ac:	1800                	addi	s0,sp,48
    800027ae:	892a                	mv	s2,a0
    800027b0:	84ae                	mv	s1,a1
    800027b2:	89b2                	mv	s3,a2
    800027b4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027b6:	fffff097          	auipc	ra,0xfffff
    800027ba:	516080e7          	jalr	1302(ra) # 80001ccc <myproc>
  if(user_src){
    800027be:	c08d                	beqz	s1,800027e0 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027c0:	86d2                	mv	a3,s4
    800027c2:	864e                	mv	a2,s3
    800027c4:	85ca                	mv	a1,s2
    800027c6:	6928                	ld	a0,80(a0)
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	0bc080e7          	jalr	188(ra) # 80001884 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027d0:	70a2                	ld	ra,40(sp)
    800027d2:	7402                	ld	s0,32(sp)
    800027d4:	64e2                	ld	s1,24(sp)
    800027d6:	6942                	ld	s2,16(sp)
    800027d8:	69a2                	ld	s3,8(sp)
    800027da:	6a02                	ld	s4,0(sp)
    800027dc:	6145                	addi	sp,sp,48
    800027de:	8082                	ret
    memmove(dst, (char*)src, len);
    800027e0:	000a061b          	sext.w	a2,s4
    800027e4:	85ce                	mv	a1,s3
    800027e6:	854a                	mv	a0,s2
    800027e8:	ffffe097          	auipc	ra,0xffffe
    800027ec:	722080e7          	jalr	1826(ra) # 80000f0a <memmove>
    return 0;
    800027f0:	8526                	mv	a0,s1
    800027f2:	bff9                	j	800027d0 <either_copyin+0x32>

00000000800027f4 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027f4:	715d                	addi	sp,sp,-80
    800027f6:	e486                	sd	ra,72(sp)
    800027f8:	e0a2                	sd	s0,64(sp)
    800027fa:	fc26                	sd	s1,56(sp)
    800027fc:	f84a                	sd	s2,48(sp)
    800027fe:	f44e                	sd	s3,40(sp)
    80002800:	f052                	sd	s4,32(sp)
    80002802:	ec56                	sd	s5,24(sp)
    80002804:	e85a                	sd	s6,16(sp)
    80002806:	e45e                	sd	s7,8(sp)
    80002808:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000280a:	00006517          	auipc	a0,0x6
    8000280e:	8be50513          	addi	a0,a0,-1858 # 800080c8 <digits+0xb0>
    80002812:	ffffe097          	auipc	ra,0xffffe
    80002816:	dac080e7          	jalr	-596(ra) # 800005be <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000281a:	0004f497          	auipc	s1,0x4f
    8000281e:	6a648493          	addi	s1,s1,1702 # 80051ec0 <proc+0x158>
    80002822:	00055917          	auipc	s2,0x55
    80002826:	09e90913          	addi	s2,s2,158 # 800578c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000282a:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000282c:	00006997          	auipc	s3,0x6
    80002830:	a7c98993          	addi	s3,s3,-1412 # 800082a8 <states.1738+0xc8>
    printf("%d %s %s", p->pid, state, p->name);
    80002834:	00006a97          	auipc	s5,0x6
    80002838:	a7ca8a93          	addi	s5,s5,-1412 # 800082b0 <states.1738+0xd0>
    printf("\n");
    8000283c:	00006a17          	auipc	s4,0x6
    80002840:	88ca0a13          	addi	s4,s4,-1908 # 800080c8 <digits+0xb0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002844:	00006b97          	auipc	s7,0x6
    80002848:	99cb8b93          	addi	s7,s7,-1636 # 800081e0 <states.1738>
    8000284c:	a015                	j	80002870 <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    8000284e:	86ba                	mv	a3,a4
    80002850:	ee072583          	lw	a1,-288(a4)
    80002854:	8556                	mv	a0,s5
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	d68080e7          	jalr	-664(ra) # 800005be <printf>
    printf("\n");
    8000285e:	8552                	mv	a0,s4
    80002860:	ffffe097          	auipc	ra,0xffffe
    80002864:	d5e080e7          	jalr	-674(ra) # 800005be <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002868:	16848493          	addi	s1,s1,360
    8000286c:	03248163          	beq	s1,s2,8000288e <procdump+0x9a>
    if(p->state == UNUSED)
    80002870:	8726                	mv	a4,s1
    80002872:	ec04a783          	lw	a5,-320(s1)
    80002876:	dbed                	beqz	a5,80002868 <procdump+0x74>
      state = "???";
    80002878:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000287a:	fcfb6ae3          	bltu	s6,a5,8000284e <procdump+0x5a>
    8000287e:	1782                	slli	a5,a5,0x20
    80002880:	9381                	srli	a5,a5,0x20
    80002882:	078e                	slli	a5,a5,0x3
    80002884:	97de                	add	a5,a5,s7
    80002886:	6390                	ld	a2,0(a5)
    80002888:	f279                	bnez	a2,8000284e <procdump+0x5a>
      state = "???";
    8000288a:	864e                	mv	a2,s3
    8000288c:	b7c9                	j	8000284e <procdump+0x5a>
  }
}
    8000288e:	60a6                	ld	ra,72(sp)
    80002890:	6406                	ld	s0,64(sp)
    80002892:	74e2                	ld	s1,56(sp)
    80002894:	7942                	ld	s2,48(sp)
    80002896:	79a2                	ld	s3,40(sp)
    80002898:	7a02                	ld	s4,32(sp)
    8000289a:	6ae2                	ld	s5,24(sp)
    8000289c:	6b42                	ld	s6,16(sp)
    8000289e:	6ba2                	ld	s7,8(sp)
    800028a0:	6161                	addi	sp,sp,80
    800028a2:	8082                	ret

00000000800028a4 <swtch>:
    800028a4:	00153023          	sd	ra,0(a0)
    800028a8:	00253423          	sd	sp,8(a0)
    800028ac:	e900                	sd	s0,16(a0)
    800028ae:	ed04                	sd	s1,24(a0)
    800028b0:	03253023          	sd	s2,32(a0)
    800028b4:	03353423          	sd	s3,40(a0)
    800028b8:	03453823          	sd	s4,48(a0)
    800028bc:	03553c23          	sd	s5,56(a0)
    800028c0:	05653023          	sd	s6,64(a0)
    800028c4:	05753423          	sd	s7,72(a0)
    800028c8:	05853823          	sd	s8,80(a0)
    800028cc:	05953c23          	sd	s9,88(a0)
    800028d0:	07a53023          	sd	s10,96(a0)
    800028d4:	07b53423          	sd	s11,104(a0)
    800028d8:	0005b083          	ld	ra,0(a1)
    800028dc:	0085b103          	ld	sp,8(a1)
    800028e0:	6980                	ld	s0,16(a1)
    800028e2:	6d84                	ld	s1,24(a1)
    800028e4:	0205b903          	ld	s2,32(a1)
    800028e8:	0285b983          	ld	s3,40(a1)
    800028ec:	0305ba03          	ld	s4,48(a1)
    800028f0:	0385ba83          	ld	s5,56(a1)
    800028f4:	0405bb03          	ld	s6,64(a1)
    800028f8:	0485bb83          	ld	s7,72(a1)
    800028fc:	0505bc03          	ld	s8,80(a1)
    80002900:	0585bc83          	ld	s9,88(a1)
    80002904:	0605bd03          	ld	s10,96(a1)
    80002908:	0685bd83          	ld	s11,104(a1)
    8000290c:	8082                	ret

000000008000290e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000290e:	1141                	addi	sp,sp,-16
    80002910:	e406                	sd	ra,8(sp)
    80002912:	e022                	sd	s0,0(sp)
    80002914:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002916:	00006597          	auipc	a1,0x6
    8000291a:	9d258593          	addi	a1,a1,-1582 # 800082e8 <states.1738+0x108>
    8000291e:	00055517          	auipc	a0,0x55
    80002922:	e4a50513          	addi	a0,a0,-438 # 80057768 <tickslock>
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	3ec080e7          	jalr	1004(ra) # 80000d12 <initlock>
}
    8000292e:	60a2                	ld	ra,8(sp)
    80002930:	6402                	ld	s0,0(sp)
    80002932:	0141                	addi	sp,sp,16
    80002934:	8082                	ret

0000000080002936 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002936:	1141                	addi	sp,sp,-16
    80002938:	e422                	sd	s0,8(sp)
    8000293a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000293c:	00003797          	auipc	a5,0x3
    80002940:	5d478793          	addi	a5,a5,1492 # 80005f10 <kernelvec>
    80002944:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002948:	6422                	ld	s0,8(sp)
    8000294a:	0141                	addi	sp,sp,16
    8000294c:	8082                	ret

000000008000294e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000294e:	1141                	addi	sp,sp,-16
    80002950:	e406                	sd	ra,8(sp)
    80002952:	e022                	sd	s0,0(sp)
    80002954:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002956:	fffff097          	auipc	ra,0xfffff
    8000295a:	376080e7          	jalr	886(ra) # 80001ccc <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002962:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002964:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002968:	00004617          	auipc	a2,0x4
    8000296c:	69860613          	addi	a2,a2,1688 # 80007000 <_trampoline>
    80002970:	00004697          	auipc	a3,0x4
    80002974:	69068693          	addi	a3,a3,1680 # 80007000 <_trampoline>
    80002978:	8e91                	sub	a3,a3,a2
    8000297a:	040007b7          	lui	a5,0x4000
    8000297e:	17fd                	addi	a5,a5,-1
    80002980:	07b2                	slli	a5,a5,0xc
    80002982:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002984:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002988:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000298a:	180026f3          	csrr	a3,satp
    8000298e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002990:	6d38                	ld	a4,88(a0)
    80002992:	6134                	ld	a3,64(a0)
    80002994:	6585                	lui	a1,0x1
    80002996:	96ae                	add	a3,a3,a1
    80002998:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000299a:	6d38                	ld	a4,88(a0)
    8000299c:	00000697          	auipc	a3,0x0
    800029a0:	13868693          	addi	a3,a3,312 # 80002ad4 <usertrap>
    800029a4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800029a6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800029a8:	8692                	mv	a3,tp
    800029aa:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ac:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800029b0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800029b4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029bc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029be:	6f18                	ld	a4,24(a4)
    800029c0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029c4:	692c                	ld	a1,80(a0)
    800029c6:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800029c8:	00004717          	auipc	a4,0x4
    800029cc:	6c870713          	addi	a4,a4,1736 # 80007090 <userret>
    800029d0:	8f11                	sub	a4,a4,a2
    800029d2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800029d4:	577d                	li	a4,-1
    800029d6:	177e                	slli	a4,a4,0x3f
    800029d8:	8dd9                	or	a1,a1,a4
    800029da:	02000537          	lui	a0,0x2000
    800029de:	157d                	addi	a0,a0,-1
    800029e0:	0536                	slli	a0,a0,0xd
    800029e2:	9782                	jalr	a5
}
    800029e4:	60a2                	ld	ra,8(sp)
    800029e6:	6402                	ld	s0,0(sp)
    800029e8:	0141                	addi	sp,sp,16
    800029ea:	8082                	ret

00000000800029ec <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029ec:	1101                	addi	sp,sp,-32
    800029ee:	ec06                	sd	ra,24(sp)
    800029f0:	e822                	sd	s0,16(sp)
    800029f2:	e426                	sd	s1,8(sp)
    800029f4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029f6:	00055497          	auipc	s1,0x55
    800029fa:	d7248493          	addi	s1,s1,-654 # 80057768 <tickslock>
    800029fe:	8526                	mv	a0,s1
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	3a2080e7          	jalr	930(ra) # 80000da2 <acquire>
  ticks++;
    80002a08:	00006517          	auipc	a0,0x6
    80002a0c:	61850513          	addi	a0,a0,1560 # 80009020 <ticks>
    80002a10:	411c                	lw	a5,0(a0)
    80002a12:	2785                	addiw	a5,a5,1
    80002a14:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a16:	00000097          	auipc	ra,0x0
    80002a1a:	c56080e7          	jalr	-938(ra) # 8000266c <wakeup>
  release(&tickslock);
    80002a1e:	8526                	mv	a0,s1
    80002a20:	ffffe097          	auipc	ra,0xffffe
    80002a24:	436080e7          	jalr	1078(ra) # 80000e56 <release>
}
    80002a28:	60e2                	ld	ra,24(sp)
    80002a2a:	6442                	ld	s0,16(sp)
    80002a2c:	64a2                	ld	s1,8(sp)
    80002a2e:	6105                	addi	sp,sp,32
    80002a30:	8082                	ret

0000000080002a32 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a32:	1101                	addi	sp,sp,-32
    80002a34:	ec06                	sd	ra,24(sp)
    80002a36:	e822                	sd	s0,16(sp)
    80002a38:	e426                	sd	s1,8(sp)
    80002a3a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a3c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a40:	00074d63          	bltz	a4,80002a5a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a44:	57fd                	li	a5,-1
    80002a46:	17fe                	slli	a5,a5,0x3f
    80002a48:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a4a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a4c:	06f70363          	beq	a4,a5,80002ab2 <devintr+0x80>
  }
}
    80002a50:	60e2                	ld	ra,24(sp)
    80002a52:	6442                	ld	s0,16(sp)
    80002a54:	64a2                	ld	s1,8(sp)
    80002a56:	6105                	addi	sp,sp,32
    80002a58:	8082                	ret
     (scause & 0xff) == 9){
    80002a5a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a5e:	46a5                	li	a3,9
    80002a60:	fed792e3          	bne	a5,a3,80002a44 <devintr+0x12>
    int irq = plic_claim();
    80002a64:	00003097          	auipc	ra,0x3
    80002a68:	5b4080e7          	jalr	1460(ra) # 80006018 <plic_claim>
    80002a6c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a6e:	47a9                	li	a5,10
    80002a70:	02f50763          	beq	a0,a5,80002a9e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a74:	4785                	li	a5,1
    80002a76:	02f50963          	beq	a0,a5,80002aa8 <devintr+0x76>
    return 1;
    80002a7a:	4505                	li	a0,1
    } else if(irq){
    80002a7c:	d8f1                	beqz	s1,80002a50 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a7e:	85a6                	mv	a1,s1
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	87050513          	addi	a0,a0,-1936 # 800082f0 <states.1738+0x110>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	b36080e7          	jalr	-1226(ra) # 800005be <printf>
      plic_complete(irq);
    80002a90:	8526                	mv	a0,s1
    80002a92:	00003097          	auipc	ra,0x3
    80002a96:	5aa080e7          	jalr	1450(ra) # 8000603c <plic_complete>
    return 1;
    80002a9a:	4505                	li	a0,1
    80002a9c:	bf55                	j	80002a50 <devintr+0x1e>
      uartintr();
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	f84080e7          	jalr	-124(ra) # 80000a22 <uartintr>
    80002aa6:	b7ed                	j	80002a90 <devintr+0x5e>
      virtio_disk_intr();
    80002aa8:	00004097          	auipc	ra,0x4
    80002aac:	a40080e7          	jalr	-1472(ra) # 800064e8 <virtio_disk_intr>
    80002ab0:	b7c5                	j	80002a90 <devintr+0x5e>
    if(cpuid() == 0){
    80002ab2:	fffff097          	auipc	ra,0xfffff
    80002ab6:	1ee080e7          	jalr	494(ra) # 80001ca0 <cpuid>
    80002aba:	c901                	beqz	a0,80002aca <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002abc:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002ac0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002ac2:	14479073          	csrw	sip,a5
    return 2;
    80002ac6:	4509                	li	a0,2
    80002ac8:	b761                	j	80002a50 <devintr+0x1e>
      clockintr();
    80002aca:	00000097          	auipc	ra,0x0
    80002ace:	f22080e7          	jalr	-222(ra) # 800029ec <clockintr>
    80002ad2:	b7ed                	j	80002abc <devintr+0x8a>

0000000080002ad4 <usertrap>:
{
    80002ad4:	1101                	addi	sp,sp,-32
    80002ad6:	ec06                	sd	ra,24(sp)
    80002ad8:	e822                	sd	s0,16(sp)
    80002ada:	e426                	sd	s1,8(sp)
    80002adc:	e04a                	sd	s2,0(sp)
    80002ade:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ae0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ae4:	1007f793          	andi	a5,a5,256
    80002ae8:	e3ad                	bnez	a5,80002b4a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aea:	00003797          	auipc	a5,0x3
    80002aee:	42678793          	addi	a5,a5,1062 # 80005f10 <kernelvec>
    80002af2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	1d6080e7          	jalr	470(ra) # 80001ccc <myproc>
    80002afe:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b00:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b02:	14102773          	csrr	a4,sepc
    80002b06:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b08:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b0c:	47a1                	li	a5,8
    80002b0e:	04f71c63          	bne	a4,a5,80002b66 <usertrap+0x92>
    if(p->killed)
    80002b12:	591c                	lw	a5,48(a0)
    80002b14:	e3b9                	bnez	a5,80002b5a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b16:	6cb8                	ld	a4,88(s1)
    80002b18:	6f1c                	ld	a5,24(a4)
    80002b1a:	0791                	addi	a5,a5,4
    80002b1c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b1e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b22:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b26:	10079073          	csrw	sstatus,a5
    syscall();
    80002b2a:	00000097          	auipc	ra,0x0
    80002b2e:	312080e7          	jalr	786(ra) # 80002e3c <syscall>
  if(p->killed)
    80002b32:	589c                	lw	a5,48(s1)
    80002b34:	e3d5                	bnez	a5,80002bd8 <usertrap+0x104>
  usertrapret();
    80002b36:	00000097          	auipc	ra,0x0
    80002b3a:	e18080e7          	jalr	-488(ra) # 8000294e <usertrapret>
}
    80002b3e:	60e2                	ld	ra,24(sp)
    80002b40:	6442                	ld	s0,16(sp)
    80002b42:	64a2                	ld	s1,8(sp)
    80002b44:	6902                	ld	s2,0(sp)
    80002b46:	6105                	addi	sp,sp,32
    80002b48:	8082                	ret
    panic("usertrap: not from user mode");
    80002b4a:	00005517          	auipc	a0,0x5
    80002b4e:	7c650513          	addi	a0,a0,1990 # 80008310 <states.1738+0x130>
    80002b52:	ffffe097          	auipc	ra,0xffffe
    80002b56:	a22080e7          	jalr	-1502(ra) # 80000574 <panic>
      exit(-1);
    80002b5a:	557d                	li	a0,-1
    80002b5c:	00000097          	auipc	ra,0x0
    80002b60:	842080e7          	jalr	-1982(ra) # 8000239e <exit>
    80002b64:	bf4d                	j	80002b16 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002b66:	00000097          	auipc	ra,0x0
    80002b6a:	ecc080e7          	jalr	-308(ra) # 80002a32 <devintr>
    80002b6e:	892a                	mv	s2,a0
    80002b70:	e12d                	bnez	a0,80002bd2 <usertrap+0xfe>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b72:	14202773          	csrr	a4,scause
 else if (r_scause() == 13 || r_scause() == 15) { // page fault
    80002b76:	47b5                	li	a5,13
    80002b78:	00f70763          	beq	a4,a5,80002b86 <usertrap+0xb2>
    80002b7c:	14202773          	csrr	a4,scause
    80002b80:	47bd                	li	a5,15
    80002b82:	00f71e63          	bne	a4,a5,80002b9e <usertrap+0xca>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b86:	143025f3          	csrr	a1,stval
    if (cownewpage(p->pagetable, va) < 0) {
    80002b8a:	68a8                	ld	a0,80(s1)
    80002b8c:	fffff097          	auipc	ra,0xfffff
    80002b90:	e86080e7          	jalr	-378(ra) # 80001a12 <cownewpage>
    80002b94:	f8055fe3          	bgez	a0,80002b32 <usertrap+0x5e>
      p->killed = 1;
    80002b98:	4785                	li	a5,1
    80002b9a:	d89c                	sw	a5,48(s1)
    80002b9c:	a83d                	j	80002bda <usertrap+0x106>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b9e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ba2:	5c90                	lw	a2,56(s1)
    80002ba4:	00005517          	auipc	a0,0x5
    80002ba8:	78c50513          	addi	a0,a0,1932 # 80008330 <states.1738+0x150>
    80002bac:	ffffe097          	auipc	ra,0xffffe
    80002bb0:	a12080e7          	jalr	-1518(ra) # 800005be <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bb8:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bbc:	00005517          	auipc	a0,0x5
    80002bc0:	7a450513          	addi	a0,a0,1956 # 80008360 <states.1738+0x180>
    80002bc4:	ffffe097          	auipc	ra,0xffffe
    80002bc8:	9fa080e7          	jalr	-1542(ra) # 800005be <printf>
    p->killed = 1;
    80002bcc:	4785                	li	a5,1
    80002bce:	d89c                	sw	a5,48(s1)
    80002bd0:	a029                	j	80002bda <usertrap+0x106>
  if(p->killed)
    80002bd2:	589c                	lw	a5,48(s1)
    80002bd4:	cb81                	beqz	a5,80002be4 <usertrap+0x110>
    80002bd6:	a011                	j	80002bda <usertrap+0x106>
    80002bd8:	4901                	li	s2,0
    exit(-1);
    80002bda:	557d                	li	a0,-1
    80002bdc:	fffff097          	auipc	ra,0xfffff
    80002be0:	7c2080e7          	jalr	1986(ra) # 8000239e <exit>
  if(which_dev == 2)
    80002be4:	4789                	li	a5,2
    80002be6:	f4f918e3          	bne	s2,a5,80002b36 <usertrap+0x62>
    yield();
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	8c0080e7          	jalr	-1856(ra) # 800024aa <yield>
    80002bf2:	b791                	j	80002b36 <usertrap+0x62>

0000000080002bf4 <kerneltrap>:
{
    80002bf4:	7179                	addi	sp,sp,-48
    80002bf6:	f406                	sd	ra,40(sp)
    80002bf8:	f022                	sd	s0,32(sp)
    80002bfa:	ec26                	sd	s1,24(sp)
    80002bfc:	e84a                	sd	s2,16(sp)
    80002bfe:	e44e                	sd	s3,8(sp)
    80002c00:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c02:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c06:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c0a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c0e:	1004f793          	andi	a5,s1,256
    80002c12:	cb85                	beqz	a5,80002c42 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c14:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c18:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c1a:	ef85                	bnez	a5,80002c52 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c1c:	00000097          	auipc	ra,0x0
    80002c20:	e16080e7          	jalr	-490(ra) # 80002a32 <devintr>
    80002c24:	cd1d                	beqz	a0,80002c62 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c26:	4789                	li	a5,2
    80002c28:	06f50a63          	beq	a0,a5,80002c9c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c2c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c30:	10049073          	csrw	sstatus,s1
}
    80002c34:	70a2                	ld	ra,40(sp)
    80002c36:	7402                	ld	s0,32(sp)
    80002c38:	64e2                	ld	s1,24(sp)
    80002c3a:	6942                	ld	s2,16(sp)
    80002c3c:	69a2                	ld	s3,8(sp)
    80002c3e:	6145                	addi	sp,sp,48
    80002c40:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c42:	00005517          	auipc	a0,0x5
    80002c46:	73e50513          	addi	a0,a0,1854 # 80008380 <states.1738+0x1a0>
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	92a080e7          	jalr	-1750(ra) # 80000574 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c52:	00005517          	auipc	a0,0x5
    80002c56:	75650513          	addi	a0,a0,1878 # 800083a8 <states.1738+0x1c8>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	91a080e7          	jalr	-1766(ra) # 80000574 <panic>
    printf("scause %p\n", scause);
    80002c62:	85ce                	mv	a1,s3
    80002c64:	00005517          	auipc	a0,0x5
    80002c68:	76450513          	addi	a0,a0,1892 # 800083c8 <states.1738+0x1e8>
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	952080e7          	jalr	-1710(ra) # 800005be <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c74:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c78:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c7c:	00005517          	auipc	a0,0x5
    80002c80:	75c50513          	addi	a0,a0,1884 # 800083d8 <states.1738+0x1f8>
    80002c84:	ffffe097          	auipc	ra,0xffffe
    80002c88:	93a080e7          	jalr	-1734(ra) # 800005be <printf>
    panic("kerneltrap");
    80002c8c:	00005517          	auipc	a0,0x5
    80002c90:	76450513          	addi	a0,a0,1892 # 800083f0 <states.1738+0x210>
    80002c94:	ffffe097          	auipc	ra,0xffffe
    80002c98:	8e0080e7          	jalr	-1824(ra) # 80000574 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	030080e7          	jalr	48(ra) # 80001ccc <myproc>
    80002ca4:	d541                	beqz	a0,80002c2c <kerneltrap+0x38>
    80002ca6:	fffff097          	auipc	ra,0xfffff
    80002caa:	026080e7          	jalr	38(ra) # 80001ccc <myproc>
    80002cae:	4d18                	lw	a4,24(a0)
    80002cb0:	478d                	li	a5,3
    80002cb2:	f6f71de3          	bne	a4,a5,80002c2c <kerneltrap+0x38>
    yield();
    80002cb6:	fffff097          	auipc	ra,0xfffff
    80002cba:	7f4080e7          	jalr	2036(ra) # 800024aa <yield>
    80002cbe:	b7bd                	j	80002c2c <kerneltrap+0x38>

0000000080002cc0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	e426                	sd	s1,8(sp)
    80002cc8:	1000                	addi	s0,sp,32
    80002cca:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	000080e7          	jalr	ra # 80001ccc <myproc>
  switch (n) {
    80002cd4:	4795                	li	a5,5
    80002cd6:	0497e363          	bltu	a5,s1,80002d1c <argraw+0x5c>
    80002cda:	1482                	slli	s1,s1,0x20
    80002cdc:	9081                	srli	s1,s1,0x20
    80002cde:	048a                	slli	s1,s1,0x2
    80002ce0:	00005717          	auipc	a4,0x5
    80002ce4:	72070713          	addi	a4,a4,1824 # 80008400 <states.1738+0x220>
    80002ce8:	94ba                	add	s1,s1,a4
    80002cea:	409c                	lw	a5,0(s1)
    80002cec:	97ba                	add	a5,a5,a4
    80002cee:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cf0:	6d3c                	ld	a5,88(a0)
    80002cf2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	64a2                	ld	s1,8(sp)
    80002cfa:	6105                	addi	sp,sp,32
    80002cfc:	8082                	ret
    return p->trapframe->a1;
    80002cfe:	6d3c                	ld	a5,88(a0)
    80002d00:	7fa8                	ld	a0,120(a5)
    80002d02:	bfcd                	j	80002cf4 <argraw+0x34>
    return p->trapframe->a2;
    80002d04:	6d3c                	ld	a5,88(a0)
    80002d06:	63c8                	ld	a0,128(a5)
    80002d08:	b7f5                	j	80002cf4 <argraw+0x34>
    return p->trapframe->a3;
    80002d0a:	6d3c                	ld	a5,88(a0)
    80002d0c:	67c8                	ld	a0,136(a5)
    80002d0e:	b7dd                	j	80002cf4 <argraw+0x34>
    return p->trapframe->a4;
    80002d10:	6d3c                	ld	a5,88(a0)
    80002d12:	6bc8                	ld	a0,144(a5)
    80002d14:	b7c5                	j	80002cf4 <argraw+0x34>
    return p->trapframe->a5;
    80002d16:	6d3c                	ld	a5,88(a0)
    80002d18:	6fc8                	ld	a0,152(a5)
    80002d1a:	bfe9                	j	80002cf4 <argraw+0x34>
  panic("argraw");
    80002d1c:	00005517          	auipc	a0,0x5
    80002d20:	7ac50513          	addi	a0,a0,1964 # 800084c8 <syscalls+0xb0>
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	850080e7          	jalr	-1968(ra) # 80000574 <panic>

0000000080002d2c <fetchaddr>:
{
    80002d2c:	1101                	addi	sp,sp,-32
    80002d2e:	ec06                	sd	ra,24(sp)
    80002d30:	e822                	sd	s0,16(sp)
    80002d32:	e426                	sd	s1,8(sp)
    80002d34:	e04a                	sd	s2,0(sp)
    80002d36:	1000                	addi	s0,sp,32
    80002d38:	84aa                	mv	s1,a0
    80002d3a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d3c:	fffff097          	auipc	ra,0xfffff
    80002d40:	f90080e7          	jalr	-112(ra) # 80001ccc <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d44:	653c                	ld	a5,72(a0)
    80002d46:	02f4f963          	bleu	a5,s1,80002d78 <fetchaddr+0x4c>
    80002d4a:	00848713          	addi	a4,s1,8
    80002d4e:	02e7e763          	bltu	a5,a4,80002d7c <fetchaddr+0x50>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d52:	46a1                	li	a3,8
    80002d54:	8626                	mv	a2,s1
    80002d56:	85ca                	mv	a1,s2
    80002d58:	6928                	ld	a0,80(a0)
    80002d5a:	fffff097          	auipc	ra,0xfffff
    80002d5e:	b2a080e7          	jalr	-1238(ra) # 80001884 <copyin>
    80002d62:	00a03533          	snez	a0,a0
    80002d66:	40a0053b          	negw	a0,a0
    80002d6a:	2501                	sext.w	a0,a0
}
    80002d6c:	60e2                	ld	ra,24(sp)
    80002d6e:	6442                	ld	s0,16(sp)
    80002d70:	64a2                	ld	s1,8(sp)
    80002d72:	6902                	ld	s2,0(sp)
    80002d74:	6105                	addi	sp,sp,32
    80002d76:	8082                	ret
    return -1;
    80002d78:	557d                	li	a0,-1
    80002d7a:	bfcd                	j	80002d6c <fetchaddr+0x40>
    80002d7c:	557d                	li	a0,-1
    80002d7e:	b7fd                	j	80002d6c <fetchaddr+0x40>

0000000080002d80 <fetchstr>:
{
    80002d80:	7179                	addi	sp,sp,-48
    80002d82:	f406                	sd	ra,40(sp)
    80002d84:	f022                	sd	s0,32(sp)
    80002d86:	ec26                	sd	s1,24(sp)
    80002d88:	e84a                	sd	s2,16(sp)
    80002d8a:	e44e                	sd	s3,8(sp)
    80002d8c:	1800                	addi	s0,sp,48
    80002d8e:	892a                	mv	s2,a0
    80002d90:	84ae                	mv	s1,a1
    80002d92:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	f38080e7          	jalr	-200(ra) # 80001ccc <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002d9c:	86ce                	mv	a3,s3
    80002d9e:	864a                	mv	a2,s2
    80002da0:	85a6                	mv	a1,s1
    80002da2:	6928                	ld	a0,80(a0)
    80002da4:	fffff097          	auipc	ra,0xfffff
    80002da8:	b6e080e7          	jalr	-1170(ra) # 80001912 <copyinstr>
  if(err < 0)
    80002dac:	00054763          	bltz	a0,80002dba <fetchstr+0x3a>
  return strlen(buf);
    80002db0:	8526                	mv	a0,s1
    80002db2:	ffffe097          	auipc	ra,0xffffe
    80002db6:	296080e7          	jalr	662(ra) # 80001048 <strlen>
}
    80002dba:	70a2                	ld	ra,40(sp)
    80002dbc:	7402                	ld	s0,32(sp)
    80002dbe:	64e2                	ld	s1,24(sp)
    80002dc0:	6942                	ld	s2,16(sp)
    80002dc2:	69a2                	ld	s3,8(sp)
    80002dc4:	6145                	addi	sp,sp,48
    80002dc6:	8082                	ret

0000000080002dc8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002dc8:	1101                	addi	sp,sp,-32
    80002dca:	ec06                	sd	ra,24(sp)
    80002dcc:	e822                	sd	s0,16(sp)
    80002dce:	e426                	sd	s1,8(sp)
    80002dd0:	1000                	addi	s0,sp,32
    80002dd2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	eec080e7          	jalr	-276(ra) # 80002cc0 <argraw>
    80002ddc:	c088                	sw	a0,0(s1)
  return 0;
}
    80002dde:	4501                	li	a0,0
    80002de0:	60e2                	ld	ra,24(sp)
    80002de2:	6442                	ld	s0,16(sp)
    80002de4:	64a2                	ld	s1,8(sp)
    80002de6:	6105                	addi	sp,sp,32
    80002de8:	8082                	ret

0000000080002dea <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002dea:	1101                	addi	sp,sp,-32
    80002dec:	ec06                	sd	ra,24(sp)
    80002dee:	e822                	sd	s0,16(sp)
    80002df0:	e426                	sd	s1,8(sp)
    80002df2:	1000                	addi	s0,sp,32
    80002df4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	eca080e7          	jalr	-310(ra) # 80002cc0 <argraw>
    80002dfe:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e00:	4501                	li	a0,0
    80002e02:	60e2                	ld	ra,24(sp)
    80002e04:	6442                	ld	s0,16(sp)
    80002e06:	64a2                	ld	s1,8(sp)
    80002e08:	6105                	addi	sp,sp,32
    80002e0a:	8082                	ret

0000000080002e0c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e0c:	1101                	addi	sp,sp,-32
    80002e0e:	ec06                	sd	ra,24(sp)
    80002e10:	e822                	sd	s0,16(sp)
    80002e12:	e426                	sd	s1,8(sp)
    80002e14:	e04a                	sd	s2,0(sp)
    80002e16:	1000                	addi	s0,sp,32
    80002e18:	84ae                	mv	s1,a1
    80002e1a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e1c:	00000097          	auipc	ra,0x0
    80002e20:	ea4080e7          	jalr	-348(ra) # 80002cc0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e24:	864a                	mv	a2,s2
    80002e26:	85a6                	mv	a1,s1
    80002e28:	00000097          	auipc	ra,0x0
    80002e2c:	f58080e7          	jalr	-168(ra) # 80002d80 <fetchstr>
}
    80002e30:	60e2                	ld	ra,24(sp)
    80002e32:	6442                	ld	s0,16(sp)
    80002e34:	64a2                	ld	s1,8(sp)
    80002e36:	6902                	ld	s2,0(sp)
    80002e38:	6105                	addi	sp,sp,32
    80002e3a:	8082                	ret

0000000080002e3c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e3c:	1101                	addi	sp,sp,-32
    80002e3e:	ec06                	sd	ra,24(sp)
    80002e40:	e822                	sd	s0,16(sp)
    80002e42:	e426                	sd	s1,8(sp)
    80002e44:	e04a                	sd	s2,0(sp)
    80002e46:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	e84080e7          	jalr	-380(ra) # 80001ccc <myproc>
    80002e50:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e52:	05853903          	ld	s2,88(a0)
    80002e56:	0a893783          	ld	a5,168(s2)
    80002e5a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e5e:	37fd                	addiw	a5,a5,-1
    80002e60:	4751                	li	a4,20
    80002e62:	00f76f63          	bltu	a4,a5,80002e80 <syscall+0x44>
    80002e66:	00369713          	slli	a4,a3,0x3
    80002e6a:	00005797          	auipc	a5,0x5
    80002e6e:	5ae78793          	addi	a5,a5,1454 # 80008418 <syscalls>
    80002e72:	97ba                	add	a5,a5,a4
    80002e74:	639c                	ld	a5,0(a5)
    80002e76:	c789                	beqz	a5,80002e80 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002e78:	9782                	jalr	a5
    80002e7a:	06a93823          	sd	a0,112(s2)
    80002e7e:	a839                	j	80002e9c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e80:	15848613          	addi	a2,s1,344
    80002e84:	5c8c                	lw	a1,56(s1)
    80002e86:	00005517          	auipc	a0,0x5
    80002e8a:	64a50513          	addi	a0,a0,1610 # 800084d0 <syscalls+0xb8>
    80002e8e:	ffffd097          	auipc	ra,0xffffd
    80002e92:	730080e7          	jalr	1840(ra) # 800005be <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e96:	6cbc                	ld	a5,88(s1)
    80002e98:	577d                	li	a4,-1
    80002e9a:	fbb8                	sd	a4,112(a5)
  }
}
    80002e9c:	60e2                	ld	ra,24(sp)
    80002e9e:	6442                	ld	s0,16(sp)
    80002ea0:	64a2                	ld	s1,8(sp)
    80002ea2:	6902                	ld	s2,0(sp)
    80002ea4:	6105                	addi	sp,sp,32
    80002ea6:	8082                	ret

0000000080002ea8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002ea8:	1101                	addi	sp,sp,-32
    80002eaa:	ec06                	sd	ra,24(sp)
    80002eac:	e822                	sd	s0,16(sp)
    80002eae:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002eb0:	fec40593          	addi	a1,s0,-20
    80002eb4:	4501                	li	a0,0
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	f12080e7          	jalr	-238(ra) # 80002dc8 <argint>
    return -1;
    80002ebe:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ec0:	00054963          	bltz	a0,80002ed2 <sys_exit+0x2a>
  exit(n);
    80002ec4:	fec42503          	lw	a0,-20(s0)
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	4d6080e7          	jalr	1238(ra) # 8000239e <exit>
  return 0;  // not reached
    80002ed0:	4781                	li	a5,0
}
    80002ed2:	853e                	mv	a0,a5
    80002ed4:	60e2                	ld	ra,24(sp)
    80002ed6:	6442                	ld	s0,16(sp)
    80002ed8:	6105                	addi	sp,sp,32
    80002eda:	8082                	ret

0000000080002edc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002edc:	1141                	addi	sp,sp,-16
    80002ede:	e406                	sd	ra,8(sp)
    80002ee0:	e022                	sd	s0,0(sp)
    80002ee2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	de8080e7          	jalr	-536(ra) # 80001ccc <myproc>
}
    80002eec:	5d08                	lw	a0,56(a0)
    80002eee:	60a2                	ld	ra,8(sp)
    80002ef0:	6402                	ld	s0,0(sp)
    80002ef2:	0141                	addi	sp,sp,16
    80002ef4:	8082                	ret

0000000080002ef6 <sys_fork>:

uint64
sys_fork(void)
{
    80002ef6:	1141                	addi	sp,sp,-16
    80002ef8:	e406                	sd	ra,8(sp)
    80002efa:	e022                	sd	s0,0(sp)
    80002efc:	0800                	addi	s0,sp,16
  return fork();
    80002efe:	fffff097          	auipc	ra,0xfffff
    80002f02:	194080e7          	jalr	404(ra) # 80002092 <fork>
}
    80002f06:	60a2                	ld	ra,8(sp)
    80002f08:	6402                	ld	s0,0(sp)
    80002f0a:	0141                	addi	sp,sp,16
    80002f0c:	8082                	ret

0000000080002f0e <sys_wait>:

uint64
sys_wait(void)
{
    80002f0e:	1101                	addi	sp,sp,-32
    80002f10:	ec06                	sd	ra,24(sp)
    80002f12:	e822                	sd	s0,16(sp)
    80002f14:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f16:	fe840593          	addi	a1,s0,-24
    80002f1a:	4501                	li	a0,0
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	ece080e7          	jalr	-306(ra) # 80002dea <argaddr>
    return -1;
    80002f24:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80002f26:	00054963          	bltz	a0,80002f38 <sys_wait+0x2a>
  return wait(p);
    80002f2a:	fe843503          	ld	a0,-24(s0)
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	636080e7          	jalr	1590(ra) # 80002564 <wait>
    80002f36:	87aa                	mv	a5,a0
}
    80002f38:	853e                	mv	a0,a5
    80002f3a:	60e2                	ld	ra,24(sp)
    80002f3c:	6442                	ld	s0,16(sp)
    80002f3e:	6105                	addi	sp,sp,32
    80002f40:	8082                	ret

0000000080002f42 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f42:	7179                	addi	sp,sp,-48
    80002f44:	f406                	sd	ra,40(sp)
    80002f46:	f022                	sd	s0,32(sp)
    80002f48:	ec26                	sd	s1,24(sp)
    80002f4a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002f4c:	fdc40593          	addi	a1,s0,-36
    80002f50:	4501                	li	a0,0
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	e76080e7          	jalr	-394(ra) # 80002dc8 <argint>
    return -1;
    80002f5a:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002f5c:	00054f63          	bltz	a0,80002f7a <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002f60:	fffff097          	auipc	ra,0xfffff
    80002f64:	d6c080e7          	jalr	-660(ra) # 80001ccc <myproc>
    80002f68:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002f6a:	fdc42503          	lw	a0,-36(s0)
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	0ac080e7          	jalr	172(ra) # 8000201a <growproc>
    80002f76:	00054863          	bltz	a0,80002f86 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002f7a:	8526                	mv	a0,s1
    80002f7c:	70a2                	ld	ra,40(sp)
    80002f7e:	7402                	ld	s0,32(sp)
    80002f80:	64e2                	ld	s1,24(sp)
    80002f82:	6145                	addi	sp,sp,48
    80002f84:	8082                	ret
    return -1;
    80002f86:	54fd                	li	s1,-1
    80002f88:	bfcd                	j	80002f7a <sys_sbrk+0x38>

0000000080002f8a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f8a:	7139                	addi	sp,sp,-64
    80002f8c:	fc06                	sd	ra,56(sp)
    80002f8e:	f822                	sd	s0,48(sp)
    80002f90:	f426                	sd	s1,40(sp)
    80002f92:	f04a                	sd	s2,32(sp)
    80002f94:	ec4e                	sd	s3,24(sp)
    80002f96:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002f98:	fcc40593          	addi	a1,s0,-52
    80002f9c:	4501                	li	a0,0
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	e2a080e7          	jalr	-470(ra) # 80002dc8 <argint>
    return -1;
    80002fa6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002fa8:	06054763          	bltz	a0,80003016 <sys_sleep+0x8c>
  acquire(&tickslock);
    80002fac:	00054517          	auipc	a0,0x54
    80002fb0:	7bc50513          	addi	a0,a0,1980 # 80057768 <tickslock>
    80002fb4:	ffffe097          	auipc	ra,0xffffe
    80002fb8:	dee080e7          	jalr	-530(ra) # 80000da2 <acquire>
  ticks0 = ticks;
    80002fbc:	00006797          	auipc	a5,0x6
    80002fc0:	06478793          	addi	a5,a5,100 # 80009020 <ticks>
    80002fc4:	0007a903          	lw	s2,0(a5)
  while(ticks - ticks0 < n){
    80002fc8:	fcc42783          	lw	a5,-52(s0)
    80002fcc:	cf85                	beqz	a5,80003004 <sys_sleep+0x7a>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fce:	00054997          	auipc	s3,0x54
    80002fd2:	79a98993          	addi	s3,s3,1946 # 80057768 <tickslock>
    80002fd6:	00006497          	auipc	s1,0x6
    80002fda:	04a48493          	addi	s1,s1,74 # 80009020 <ticks>
    if(myproc()->killed){
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	cee080e7          	jalr	-786(ra) # 80001ccc <myproc>
    80002fe6:	591c                	lw	a5,48(a0)
    80002fe8:	ef9d                	bnez	a5,80003026 <sys_sleep+0x9c>
    sleep(&ticks, &tickslock);
    80002fea:	85ce                	mv	a1,s3
    80002fec:	8526                	mv	a0,s1
    80002fee:	fffff097          	auipc	ra,0xfffff
    80002ff2:	4f8080e7          	jalr	1272(ra) # 800024e6 <sleep>
  while(ticks - ticks0 < n){
    80002ff6:	409c                	lw	a5,0(s1)
    80002ff8:	412787bb          	subw	a5,a5,s2
    80002ffc:	fcc42703          	lw	a4,-52(s0)
    80003000:	fce7efe3          	bltu	a5,a4,80002fde <sys_sleep+0x54>
  }
  release(&tickslock);
    80003004:	00054517          	auipc	a0,0x54
    80003008:	76450513          	addi	a0,a0,1892 # 80057768 <tickslock>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	e4a080e7          	jalr	-438(ra) # 80000e56 <release>
  return 0;
    80003014:	4781                	li	a5,0
}
    80003016:	853e                	mv	a0,a5
    80003018:	70e2                	ld	ra,56(sp)
    8000301a:	7442                	ld	s0,48(sp)
    8000301c:	74a2                	ld	s1,40(sp)
    8000301e:	7902                	ld	s2,32(sp)
    80003020:	69e2                	ld	s3,24(sp)
    80003022:	6121                	addi	sp,sp,64
    80003024:	8082                	ret
      release(&tickslock);
    80003026:	00054517          	auipc	a0,0x54
    8000302a:	74250513          	addi	a0,a0,1858 # 80057768 <tickslock>
    8000302e:	ffffe097          	auipc	ra,0xffffe
    80003032:	e28080e7          	jalr	-472(ra) # 80000e56 <release>
      return -1;
    80003036:	57fd                	li	a5,-1
    80003038:	bff9                	j	80003016 <sys_sleep+0x8c>

000000008000303a <sys_kill>:

uint64
sys_kill(void)
{
    8000303a:	1101                	addi	sp,sp,-32
    8000303c:	ec06                	sd	ra,24(sp)
    8000303e:	e822                	sd	s0,16(sp)
    80003040:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80003042:	fec40593          	addi	a1,s0,-20
    80003046:	4501                	li	a0,0
    80003048:	00000097          	auipc	ra,0x0
    8000304c:	d80080e7          	jalr	-640(ra) # 80002dc8 <argint>
    return -1;
    80003050:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80003052:	00054963          	bltz	a0,80003064 <sys_kill+0x2a>
  return kill(pid);
    80003056:	fec42503          	lw	a0,-20(s0)
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	67c080e7          	jalr	1660(ra) # 800026d6 <kill>
    80003062:	87aa                	mv	a5,a0
}
    80003064:	853e                	mv	a0,a5
    80003066:	60e2                	ld	ra,24(sp)
    80003068:	6442                	ld	s0,16(sp)
    8000306a:	6105                	addi	sp,sp,32
    8000306c:	8082                	ret

000000008000306e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000306e:	1101                	addi	sp,sp,-32
    80003070:	ec06                	sd	ra,24(sp)
    80003072:	e822                	sd	s0,16(sp)
    80003074:	e426                	sd	s1,8(sp)
    80003076:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003078:	00054517          	auipc	a0,0x54
    8000307c:	6f050513          	addi	a0,a0,1776 # 80057768 <tickslock>
    80003080:	ffffe097          	auipc	ra,0xffffe
    80003084:	d22080e7          	jalr	-734(ra) # 80000da2 <acquire>
  xticks = ticks;
    80003088:	00006797          	auipc	a5,0x6
    8000308c:	f9878793          	addi	a5,a5,-104 # 80009020 <ticks>
    80003090:	4384                	lw	s1,0(a5)
  release(&tickslock);
    80003092:	00054517          	auipc	a0,0x54
    80003096:	6d650513          	addi	a0,a0,1750 # 80057768 <tickslock>
    8000309a:	ffffe097          	auipc	ra,0xffffe
    8000309e:	dbc080e7          	jalr	-580(ra) # 80000e56 <release>
  return xticks;
}
    800030a2:	02049513          	slli	a0,s1,0x20
    800030a6:	9101                	srli	a0,a0,0x20
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	64a2                	ld	s1,8(sp)
    800030ae:	6105                	addi	sp,sp,32
    800030b0:	8082                	ret

00000000800030b2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030b2:	7179                	addi	sp,sp,-48
    800030b4:	f406                	sd	ra,40(sp)
    800030b6:	f022                	sd	s0,32(sp)
    800030b8:	ec26                	sd	s1,24(sp)
    800030ba:	e84a                	sd	s2,16(sp)
    800030bc:	e44e                	sd	s3,8(sp)
    800030be:	e052                	sd	s4,0(sp)
    800030c0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030c2:	00005597          	auipc	a1,0x5
    800030c6:	42e58593          	addi	a1,a1,1070 # 800084f0 <syscalls+0xd8>
    800030ca:	00054517          	auipc	a0,0x54
    800030ce:	6b650513          	addi	a0,a0,1718 # 80057780 <bcache>
    800030d2:	ffffe097          	auipc	ra,0xffffe
    800030d6:	c40080e7          	jalr	-960(ra) # 80000d12 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030da:	0005c797          	auipc	a5,0x5c
    800030de:	6a678793          	addi	a5,a5,1702 # 8005f780 <bcache+0x8000>
    800030e2:	0005d717          	auipc	a4,0x5d
    800030e6:	90670713          	addi	a4,a4,-1786 # 8005f9e8 <bcache+0x8268>
    800030ea:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030ee:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030f2:	00054497          	auipc	s1,0x54
    800030f6:	6a648493          	addi	s1,s1,1702 # 80057798 <bcache+0x18>
    b->next = bcache.head.next;
    800030fa:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030fc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030fe:	00005a17          	auipc	s4,0x5
    80003102:	3faa0a13          	addi	s4,s4,1018 # 800084f8 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003106:	2b893783          	ld	a5,696(s2)
    8000310a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000310c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003110:	85d2                	mv	a1,s4
    80003112:	01048513          	addi	a0,s1,16
    80003116:	00001097          	auipc	ra,0x1
    8000311a:	51e080e7          	jalr	1310(ra) # 80004634 <initsleeplock>
    bcache.head.next->prev = b;
    8000311e:	2b893783          	ld	a5,696(s2)
    80003122:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003124:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003128:	45848493          	addi	s1,s1,1112
    8000312c:	fd349de3          	bne	s1,s3,80003106 <binit+0x54>
  }
}
    80003130:	70a2                	ld	ra,40(sp)
    80003132:	7402                	ld	s0,32(sp)
    80003134:	64e2                	ld	s1,24(sp)
    80003136:	6942                	ld	s2,16(sp)
    80003138:	69a2                	ld	s3,8(sp)
    8000313a:	6a02                	ld	s4,0(sp)
    8000313c:	6145                	addi	sp,sp,48
    8000313e:	8082                	ret

0000000080003140 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003140:	7179                	addi	sp,sp,-48
    80003142:	f406                	sd	ra,40(sp)
    80003144:	f022                	sd	s0,32(sp)
    80003146:	ec26                	sd	s1,24(sp)
    80003148:	e84a                	sd	s2,16(sp)
    8000314a:	e44e                	sd	s3,8(sp)
    8000314c:	1800                	addi	s0,sp,48
    8000314e:	89aa                	mv	s3,a0
    80003150:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003152:	00054517          	auipc	a0,0x54
    80003156:	62e50513          	addi	a0,a0,1582 # 80057780 <bcache>
    8000315a:	ffffe097          	auipc	ra,0xffffe
    8000315e:	c48080e7          	jalr	-952(ra) # 80000da2 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003162:	0005c797          	auipc	a5,0x5c
    80003166:	61e78793          	addi	a5,a5,1566 # 8005f780 <bcache+0x8000>
    8000316a:	2b87b483          	ld	s1,696(a5)
    8000316e:	0005d797          	auipc	a5,0x5d
    80003172:	87a78793          	addi	a5,a5,-1926 # 8005f9e8 <bcache+0x8268>
    80003176:	02f48f63          	beq	s1,a5,800031b4 <bread+0x74>
    8000317a:	873e                	mv	a4,a5
    8000317c:	a021                	j	80003184 <bread+0x44>
    8000317e:	68a4                	ld	s1,80(s1)
    80003180:	02e48a63          	beq	s1,a4,800031b4 <bread+0x74>
    if(b->dev == dev && b->blockno == blockno){
    80003184:	449c                	lw	a5,8(s1)
    80003186:	ff379ce3          	bne	a5,s3,8000317e <bread+0x3e>
    8000318a:	44dc                	lw	a5,12(s1)
    8000318c:	ff2799e3          	bne	a5,s2,8000317e <bread+0x3e>
      b->refcnt++;
    80003190:	40bc                	lw	a5,64(s1)
    80003192:	2785                	addiw	a5,a5,1
    80003194:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003196:	00054517          	auipc	a0,0x54
    8000319a:	5ea50513          	addi	a0,a0,1514 # 80057780 <bcache>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	cb8080e7          	jalr	-840(ra) # 80000e56 <release>
      acquiresleep(&b->lock);
    800031a6:	01048513          	addi	a0,s1,16
    800031aa:	00001097          	auipc	ra,0x1
    800031ae:	4c4080e7          	jalr	1220(ra) # 8000466e <acquiresleep>
      return b;
    800031b2:	a8b1                	j	8000320e <bread+0xce>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031b4:	0005c797          	auipc	a5,0x5c
    800031b8:	5cc78793          	addi	a5,a5,1484 # 8005f780 <bcache+0x8000>
    800031bc:	2b07b483          	ld	s1,688(a5)
    800031c0:	0005d797          	auipc	a5,0x5d
    800031c4:	82878793          	addi	a5,a5,-2008 # 8005f9e8 <bcache+0x8268>
    800031c8:	04f48d63          	beq	s1,a5,80003222 <bread+0xe2>
    if(b->refcnt == 0) {
    800031cc:	40bc                	lw	a5,64(s1)
    800031ce:	cb91                	beqz	a5,800031e2 <bread+0xa2>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031d0:	0005d717          	auipc	a4,0x5d
    800031d4:	81870713          	addi	a4,a4,-2024 # 8005f9e8 <bcache+0x8268>
    800031d8:	64a4                	ld	s1,72(s1)
    800031da:	04e48463          	beq	s1,a4,80003222 <bread+0xe2>
    if(b->refcnt == 0) {
    800031de:	40bc                	lw	a5,64(s1)
    800031e0:	ffe5                	bnez	a5,800031d8 <bread+0x98>
      b->dev = dev;
    800031e2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031e6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031ea:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031ee:	4785                	li	a5,1
    800031f0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031f2:	00054517          	auipc	a0,0x54
    800031f6:	58e50513          	addi	a0,a0,1422 # 80057780 <bcache>
    800031fa:	ffffe097          	auipc	ra,0xffffe
    800031fe:	c5c080e7          	jalr	-932(ra) # 80000e56 <release>
      acquiresleep(&b->lock);
    80003202:	01048513          	addi	a0,s1,16
    80003206:	00001097          	auipc	ra,0x1
    8000320a:	468080e7          	jalr	1128(ra) # 8000466e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000320e:	409c                	lw	a5,0(s1)
    80003210:	c38d                	beqz	a5,80003232 <bread+0xf2>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003212:	8526                	mv	a0,s1
    80003214:	70a2                	ld	ra,40(sp)
    80003216:	7402                	ld	s0,32(sp)
    80003218:	64e2                	ld	s1,24(sp)
    8000321a:	6942                	ld	s2,16(sp)
    8000321c:	69a2                	ld	s3,8(sp)
    8000321e:	6145                	addi	sp,sp,48
    80003220:	8082                	ret
  panic("bget: no buffers");
    80003222:	00005517          	auipc	a0,0x5
    80003226:	2de50513          	addi	a0,a0,734 # 80008500 <syscalls+0xe8>
    8000322a:	ffffd097          	auipc	ra,0xffffd
    8000322e:	34a080e7          	jalr	842(ra) # 80000574 <panic>
    virtio_disk_rw(b, 0);
    80003232:	4581                	li	a1,0
    80003234:	8526                	mv	a0,s1
    80003236:	00003097          	auipc	ra,0x3
    8000323a:	ff8080e7          	jalr	-8(ra) # 8000622e <virtio_disk_rw>
    b->valid = 1;
    8000323e:	4785                	li	a5,1
    80003240:	c09c                	sw	a5,0(s1)
  return b;
    80003242:	bfc1                	j	80003212 <bread+0xd2>

0000000080003244 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003244:	1101                	addi	sp,sp,-32
    80003246:	ec06                	sd	ra,24(sp)
    80003248:	e822                	sd	s0,16(sp)
    8000324a:	e426                	sd	s1,8(sp)
    8000324c:	1000                	addi	s0,sp,32
    8000324e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003250:	0541                	addi	a0,a0,16
    80003252:	00001097          	auipc	ra,0x1
    80003256:	4b6080e7          	jalr	1206(ra) # 80004708 <holdingsleep>
    8000325a:	cd01                	beqz	a0,80003272 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000325c:	4585                	li	a1,1
    8000325e:	8526                	mv	a0,s1
    80003260:	00003097          	auipc	ra,0x3
    80003264:	fce080e7          	jalr	-50(ra) # 8000622e <virtio_disk_rw>
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	64a2                	ld	s1,8(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret
    panic("bwrite");
    80003272:	00005517          	auipc	a0,0x5
    80003276:	2a650513          	addi	a0,a0,678 # 80008518 <syscalls+0x100>
    8000327a:	ffffd097          	auipc	ra,0xffffd
    8000327e:	2fa080e7          	jalr	762(ra) # 80000574 <panic>

0000000080003282 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003282:	1101                	addi	sp,sp,-32
    80003284:	ec06                	sd	ra,24(sp)
    80003286:	e822                	sd	s0,16(sp)
    80003288:	e426                	sd	s1,8(sp)
    8000328a:	e04a                	sd	s2,0(sp)
    8000328c:	1000                	addi	s0,sp,32
    8000328e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003290:	01050913          	addi	s2,a0,16
    80003294:	854a                	mv	a0,s2
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	472080e7          	jalr	1138(ra) # 80004708 <holdingsleep>
    8000329e:	c92d                	beqz	a0,80003310 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032a0:	854a                	mv	a0,s2
    800032a2:	00001097          	auipc	ra,0x1
    800032a6:	422080e7          	jalr	1058(ra) # 800046c4 <releasesleep>

  acquire(&bcache.lock);
    800032aa:	00054517          	auipc	a0,0x54
    800032ae:	4d650513          	addi	a0,a0,1238 # 80057780 <bcache>
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	af0080e7          	jalr	-1296(ra) # 80000da2 <acquire>
  b->refcnt--;
    800032ba:	40bc                	lw	a5,64(s1)
    800032bc:	37fd                	addiw	a5,a5,-1
    800032be:	0007871b          	sext.w	a4,a5
    800032c2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032c4:	eb05                	bnez	a4,800032f4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032c6:	68bc                	ld	a5,80(s1)
    800032c8:	64b8                	ld	a4,72(s1)
    800032ca:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032cc:	64bc                	ld	a5,72(s1)
    800032ce:	68b8                	ld	a4,80(s1)
    800032d0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032d2:	0005c797          	auipc	a5,0x5c
    800032d6:	4ae78793          	addi	a5,a5,1198 # 8005f780 <bcache+0x8000>
    800032da:	2b87b703          	ld	a4,696(a5)
    800032de:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032e0:	0005c717          	auipc	a4,0x5c
    800032e4:	70870713          	addi	a4,a4,1800 # 8005f9e8 <bcache+0x8268>
    800032e8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032ea:	2b87b703          	ld	a4,696(a5)
    800032ee:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032f0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032f4:	00054517          	auipc	a0,0x54
    800032f8:	48c50513          	addi	a0,a0,1164 # 80057780 <bcache>
    800032fc:	ffffe097          	auipc	ra,0xffffe
    80003300:	b5a080e7          	jalr	-1190(ra) # 80000e56 <release>
}
    80003304:	60e2                	ld	ra,24(sp)
    80003306:	6442                	ld	s0,16(sp)
    80003308:	64a2                	ld	s1,8(sp)
    8000330a:	6902                	ld	s2,0(sp)
    8000330c:	6105                	addi	sp,sp,32
    8000330e:	8082                	ret
    panic("brelse");
    80003310:	00005517          	auipc	a0,0x5
    80003314:	21050513          	addi	a0,a0,528 # 80008520 <syscalls+0x108>
    80003318:	ffffd097          	auipc	ra,0xffffd
    8000331c:	25c080e7          	jalr	604(ra) # 80000574 <panic>

0000000080003320 <bpin>:

void
bpin(struct buf *b) {
    80003320:	1101                	addi	sp,sp,-32
    80003322:	ec06                	sd	ra,24(sp)
    80003324:	e822                	sd	s0,16(sp)
    80003326:	e426                	sd	s1,8(sp)
    80003328:	1000                	addi	s0,sp,32
    8000332a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000332c:	00054517          	auipc	a0,0x54
    80003330:	45450513          	addi	a0,a0,1108 # 80057780 <bcache>
    80003334:	ffffe097          	auipc	ra,0xffffe
    80003338:	a6e080e7          	jalr	-1426(ra) # 80000da2 <acquire>
  b->refcnt++;
    8000333c:	40bc                	lw	a5,64(s1)
    8000333e:	2785                	addiw	a5,a5,1
    80003340:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003342:	00054517          	auipc	a0,0x54
    80003346:	43e50513          	addi	a0,a0,1086 # 80057780 <bcache>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	b0c080e7          	jalr	-1268(ra) # 80000e56 <release>
}
    80003352:	60e2                	ld	ra,24(sp)
    80003354:	6442                	ld	s0,16(sp)
    80003356:	64a2                	ld	s1,8(sp)
    80003358:	6105                	addi	sp,sp,32
    8000335a:	8082                	ret

000000008000335c <bunpin>:

void
bunpin(struct buf *b) {
    8000335c:	1101                	addi	sp,sp,-32
    8000335e:	ec06                	sd	ra,24(sp)
    80003360:	e822                	sd	s0,16(sp)
    80003362:	e426                	sd	s1,8(sp)
    80003364:	1000                	addi	s0,sp,32
    80003366:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003368:	00054517          	auipc	a0,0x54
    8000336c:	41850513          	addi	a0,a0,1048 # 80057780 <bcache>
    80003370:	ffffe097          	auipc	ra,0xffffe
    80003374:	a32080e7          	jalr	-1486(ra) # 80000da2 <acquire>
  b->refcnt--;
    80003378:	40bc                	lw	a5,64(s1)
    8000337a:	37fd                	addiw	a5,a5,-1
    8000337c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000337e:	00054517          	auipc	a0,0x54
    80003382:	40250513          	addi	a0,a0,1026 # 80057780 <bcache>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	ad0080e7          	jalr	-1328(ra) # 80000e56 <release>
}
    8000338e:	60e2                	ld	ra,24(sp)
    80003390:	6442                	ld	s0,16(sp)
    80003392:	64a2                	ld	s1,8(sp)
    80003394:	6105                	addi	sp,sp,32
    80003396:	8082                	ret

0000000080003398 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003398:	1101                	addi	sp,sp,-32
    8000339a:	ec06                	sd	ra,24(sp)
    8000339c:	e822                	sd	s0,16(sp)
    8000339e:	e426                	sd	s1,8(sp)
    800033a0:	e04a                	sd	s2,0(sp)
    800033a2:	1000                	addi	s0,sp,32
    800033a4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033a6:	00d5d59b          	srliw	a1,a1,0xd
    800033aa:	0005d797          	auipc	a5,0x5d
    800033ae:	a9678793          	addi	a5,a5,-1386 # 8005fe40 <sb>
    800033b2:	4fdc                	lw	a5,28(a5)
    800033b4:	9dbd                	addw	a1,a1,a5
    800033b6:	00000097          	auipc	ra,0x0
    800033ba:	d8a080e7          	jalr	-630(ra) # 80003140 <bread>
  bi = b % BPB;
    800033be:	2481                	sext.w	s1,s1
  m = 1 << (bi % 8);
    800033c0:	0074f793          	andi	a5,s1,7
    800033c4:	4705                	li	a4,1
    800033c6:	00f7173b          	sllw	a4,a4,a5
  bi = b % BPB;
    800033ca:	6789                	lui	a5,0x2
    800033cc:	17fd                	addi	a5,a5,-1
    800033ce:	8cfd                	and	s1,s1,a5
  if((bp->data[bi/8] & m) == 0)
    800033d0:	41f4d79b          	sraiw	a5,s1,0x1f
    800033d4:	01d7d79b          	srliw	a5,a5,0x1d
    800033d8:	9fa5                	addw	a5,a5,s1
    800033da:	4037d79b          	sraiw	a5,a5,0x3
    800033de:	00f506b3          	add	a3,a0,a5
    800033e2:	0586c683          	lbu	a3,88(a3)
    800033e6:	00d77633          	and	a2,a4,a3
    800033ea:	c61d                	beqz	a2,80003418 <bfree+0x80>
    800033ec:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033ee:	97aa                	add	a5,a5,a0
    800033f0:	fff74713          	not	a4,a4
    800033f4:	8f75                	and	a4,a4,a3
    800033f6:	04e78c23          	sb	a4,88(a5) # 2058 <_entry-0x7fffdfa8>
  log_write(bp);
    800033fa:	00001097          	auipc	ra,0x1
    800033fe:	136080e7          	jalr	310(ra) # 80004530 <log_write>
  brelse(bp);
    80003402:	854a                	mv	a0,s2
    80003404:	00000097          	auipc	ra,0x0
    80003408:	e7e080e7          	jalr	-386(ra) # 80003282 <brelse>
}
    8000340c:	60e2                	ld	ra,24(sp)
    8000340e:	6442                	ld	s0,16(sp)
    80003410:	64a2                	ld	s1,8(sp)
    80003412:	6902                	ld	s2,0(sp)
    80003414:	6105                	addi	sp,sp,32
    80003416:	8082                	ret
    panic("freeing free block");
    80003418:	00005517          	auipc	a0,0x5
    8000341c:	11050513          	addi	a0,a0,272 # 80008528 <syscalls+0x110>
    80003420:	ffffd097          	auipc	ra,0xffffd
    80003424:	154080e7          	jalr	340(ra) # 80000574 <panic>

0000000080003428 <balloc>:
{
    80003428:	711d                	addi	sp,sp,-96
    8000342a:	ec86                	sd	ra,88(sp)
    8000342c:	e8a2                	sd	s0,80(sp)
    8000342e:	e4a6                	sd	s1,72(sp)
    80003430:	e0ca                	sd	s2,64(sp)
    80003432:	fc4e                	sd	s3,56(sp)
    80003434:	f852                	sd	s4,48(sp)
    80003436:	f456                	sd	s5,40(sp)
    80003438:	f05a                	sd	s6,32(sp)
    8000343a:	ec5e                	sd	s7,24(sp)
    8000343c:	e862                	sd	s8,16(sp)
    8000343e:	e466                	sd	s9,8(sp)
    80003440:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003442:	0005d797          	auipc	a5,0x5d
    80003446:	9fe78793          	addi	a5,a5,-1538 # 8005fe40 <sb>
    8000344a:	43dc                	lw	a5,4(a5)
    8000344c:	10078e63          	beqz	a5,80003568 <balloc+0x140>
    80003450:	8baa                	mv	s7,a0
    80003452:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003454:	0005db17          	auipc	s6,0x5d
    80003458:	9ecb0b13          	addi	s6,s6,-1556 # 8005fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345c:	4c05                	li	s8,1
      m = 1 << (bi % 8);
    8000345e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003460:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003462:	6c89                	lui	s9,0x2
    80003464:	a079                	j	800034f2 <balloc+0xca>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003466:	8942                	mv	s2,a6
      m = 1 << (bi % 8);
    80003468:	4705                	li	a4,1
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000346a:	4681                	li	a3,0
        bp->data[bi/8] |= m;  // Mark block in use.
    8000346c:	96a6                	add	a3,a3,s1
    8000346e:	8f51                	or	a4,a4,a2
    80003470:	04e68c23          	sb	a4,88(a3)
        log_write(bp);
    80003474:	8526                	mv	a0,s1
    80003476:	00001097          	auipc	ra,0x1
    8000347a:	0ba080e7          	jalr	186(ra) # 80004530 <log_write>
        brelse(bp);
    8000347e:	8526                	mv	a0,s1
    80003480:	00000097          	auipc	ra,0x0
    80003484:	e02080e7          	jalr	-510(ra) # 80003282 <brelse>
  bp = bread(dev, bno);
    80003488:	85ca                	mv	a1,s2
    8000348a:	855e                	mv	a0,s7
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	cb4080e7          	jalr	-844(ra) # 80003140 <bread>
    80003494:	84aa                	mv	s1,a0
  memset(bp->data, 0, BSIZE);
    80003496:	40000613          	li	a2,1024
    8000349a:	4581                	li	a1,0
    8000349c:	05850513          	addi	a0,a0,88
    800034a0:	ffffe097          	auipc	ra,0xffffe
    800034a4:	9fe080e7          	jalr	-1538(ra) # 80000e9e <memset>
  log_write(bp);
    800034a8:	8526                	mv	a0,s1
    800034aa:	00001097          	auipc	ra,0x1
    800034ae:	086080e7          	jalr	134(ra) # 80004530 <log_write>
  brelse(bp);
    800034b2:	8526                	mv	a0,s1
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	dce080e7          	jalr	-562(ra) # 80003282 <brelse>
}
    800034bc:	854a                	mv	a0,s2
    800034be:	60e6                	ld	ra,88(sp)
    800034c0:	6446                	ld	s0,80(sp)
    800034c2:	64a6                	ld	s1,72(sp)
    800034c4:	6906                	ld	s2,64(sp)
    800034c6:	79e2                	ld	s3,56(sp)
    800034c8:	7a42                	ld	s4,48(sp)
    800034ca:	7aa2                	ld	s5,40(sp)
    800034cc:	7b02                	ld	s6,32(sp)
    800034ce:	6be2                	ld	s7,24(sp)
    800034d0:	6c42                	ld	s8,16(sp)
    800034d2:	6ca2                	ld	s9,8(sp)
    800034d4:	6125                	addi	sp,sp,96
    800034d6:	8082                	ret
    brelse(bp);
    800034d8:	8526                	mv	a0,s1
    800034da:	00000097          	auipc	ra,0x0
    800034de:	da8080e7          	jalr	-600(ra) # 80003282 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034e2:	015c87bb          	addw	a5,s9,s5
    800034e6:	00078a9b          	sext.w	s5,a5
    800034ea:	004b2703          	lw	a4,4(s6)
    800034ee:	06eafd63          	bleu	a4,s5,80003568 <balloc+0x140>
    bp = bread(dev, BBLOCK(b, sb));
    800034f2:	41fad79b          	sraiw	a5,s5,0x1f
    800034f6:	0137d79b          	srliw	a5,a5,0x13
    800034fa:	015787bb          	addw	a5,a5,s5
    800034fe:	40d7d79b          	sraiw	a5,a5,0xd
    80003502:	01cb2583          	lw	a1,28(s6)
    80003506:	9dbd                	addw	a1,a1,a5
    80003508:	855e                	mv	a0,s7
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	c36080e7          	jalr	-970(ra) # 80003140 <bread>
    80003512:	84aa                	mv	s1,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003514:	000a881b          	sext.w	a6,s5
    80003518:	004b2503          	lw	a0,4(s6)
    8000351c:	faa87ee3          	bleu	a0,a6,800034d8 <balloc+0xb0>
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003520:	0584c603          	lbu	a2,88(s1)
    80003524:	00167793          	andi	a5,a2,1
    80003528:	df9d                	beqz	a5,80003466 <balloc+0x3e>
    8000352a:	4105053b          	subw	a0,a0,a6
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000352e:	87e2                	mv	a5,s8
    80003530:	0107893b          	addw	s2,a5,a6
    80003534:	faa782e3          	beq	a5,a0,800034d8 <balloc+0xb0>
      m = 1 << (bi % 8);
    80003538:	41f7d71b          	sraiw	a4,a5,0x1f
    8000353c:	01d7561b          	srliw	a2,a4,0x1d
    80003540:	00f606bb          	addw	a3,a2,a5
    80003544:	0076f713          	andi	a4,a3,7
    80003548:	9f11                	subw	a4,a4,a2
    8000354a:	00e9973b          	sllw	a4,s3,a4
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000354e:	4036d69b          	sraiw	a3,a3,0x3
    80003552:	00d48633          	add	a2,s1,a3
    80003556:	05864603          	lbu	a2,88(a2)
    8000355a:	00c775b3          	and	a1,a4,a2
    8000355e:	d599                	beqz	a1,8000346c <balloc+0x44>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003560:	2785                	addiw	a5,a5,1
    80003562:	fd4797e3          	bne	a5,s4,80003530 <balloc+0x108>
    80003566:	bf8d                	j	800034d8 <balloc+0xb0>
  panic("balloc: out of blocks");
    80003568:	00005517          	auipc	a0,0x5
    8000356c:	fd850513          	addi	a0,a0,-40 # 80008540 <syscalls+0x128>
    80003570:	ffffd097          	auipc	ra,0xffffd
    80003574:	004080e7          	jalr	4(ra) # 80000574 <panic>

0000000080003578 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003578:	7179                	addi	sp,sp,-48
    8000357a:	f406                	sd	ra,40(sp)
    8000357c:	f022                	sd	s0,32(sp)
    8000357e:	ec26                	sd	s1,24(sp)
    80003580:	e84a                	sd	s2,16(sp)
    80003582:	e44e                	sd	s3,8(sp)
    80003584:	e052                	sd	s4,0(sp)
    80003586:	1800                	addi	s0,sp,48
    80003588:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000358a:	47ad                	li	a5,11
    8000358c:	04b7fe63          	bleu	a1,a5,800035e8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003590:	ff45849b          	addiw	s1,a1,-12
    80003594:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003598:	0ff00793          	li	a5,255
    8000359c:	0ae7e363          	bltu	a5,a4,80003642 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035a0:	08052583          	lw	a1,128(a0)
    800035a4:	c5ad                	beqz	a1,8000360e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035a6:	0009a503          	lw	a0,0(s3)
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	b96080e7          	jalr	-1130(ra) # 80003140 <bread>
    800035b2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035b4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035b8:	02049593          	slli	a1,s1,0x20
    800035bc:	9181                	srli	a1,a1,0x20
    800035be:	058a                	slli	a1,a1,0x2
    800035c0:	00b784b3          	add	s1,a5,a1
    800035c4:	0004a903          	lw	s2,0(s1)
    800035c8:	04090d63          	beqz	s2,80003622 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035cc:	8552                	mv	a0,s4
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	cb4080e7          	jalr	-844(ra) # 80003282 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035d6:	854a                	mv	a0,s2
    800035d8:	70a2                	ld	ra,40(sp)
    800035da:	7402                	ld	s0,32(sp)
    800035dc:	64e2                	ld	s1,24(sp)
    800035de:	6942                	ld	s2,16(sp)
    800035e0:	69a2                	ld	s3,8(sp)
    800035e2:	6a02                	ld	s4,0(sp)
    800035e4:	6145                	addi	sp,sp,48
    800035e6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800035e8:	02059493          	slli	s1,a1,0x20
    800035ec:	9081                	srli	s1,s1,0x20
    800035ee:	048a                	slli	s1,s1,0x2
    800035f0:	94aa                	add	s1,s1,a0
    800035f2:	0504a903          	lw	s2,80(s1)
    800035f6:	fe0910e3          	bnez	s2,800035d6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800035fa:	4108                	lw	a0,0(a0)
    800035fc:	00000097          	auipc	ra,0x0
    80003600:	e2c080e7          	jalr	-468(ra) # 80003428 <balloc>
    80003604:	0005091b          	sext.w	s2,a0
    80003608:	0524a823          	sw	s2,80(s1)
    8000360c:	b7e9                	j	800035d6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000360e:	4108                	lw	a0,0(a0)
    80003610:	00000097          	auipc	ra,0x0
    80003614:	e18080e7          	jalr	-488(ra) # 80003428 <balloc>
    80003618:	0005059b          	sext.w	a1,a0
    8000361c:	08b9a023          	sw	a1,128(s3)
    80003620:	b759                	j	800035a6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003622:	0009a503          	lw	a0,0(s3)
    80003626:	00000097          	auipc	ra,0x0
    8000362a:	e02080e7          	jalr	-510(ra) # 80003428 <balloc>
    8000362e:	0005091b          	sext.w	s2,a0
    80003632:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    80003636:	8552                	mv	a0,s4
    80003638:	00001097          	auipc	ra,0x1
    8000363c:	ef8080e7          	jalr	-264(ra) # 80004530 <log_write>
    80003640:	b771                	j	800035cc <bmap+0x54>
  panic("bmap: out of range");
    80003642:	00005517          	auipc	a0,0x5
    80003646:	f1650513          	addi	a0,a0,-234 # 80008558 <syscalls+0x140>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	f2a080e7          	jalr	-214(ra) # 80000574 <panic>

0000000080003652 <iget>:
{
    80003652:	7179                	addi	sp,sp,-48
    80003654:	f406                	sd	ra,40(sp)
    80003656:	f022                	sd	s0,32(sp)
    80003658:	ec26                	sd	s1,24(sp)
    8000365a:	e84a                	sd	s2,16(sp)
    8000365c:	e44e                	sd	s3,8(sp)
    8000365e:	e052                	sd	s4,0(sp)
    80003660:	1800                	addi	s0,sp,48
    80003662:	89aa                	mv	s3,a0
    80003664:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003666:	0005c517          	auipc	a0,0x5c
    8000366a:	7fa50513          	addi	a0,a0,2042 # 8005fe60 <icache>
    8000366e:	ffffd097          	auipc	ra,0xffffd
    80003672:	734080e7          	jalr	1844(ra) # 80000da2 <acquire>
  empty = 0;
    80003676:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003678:	0005d497          	auipc	s1,0x5d
    8000367c:	80048493          	addi	s1,s1,-2048 # 8005fe78 <icache+0x18>
    80003680:	0005e697          	auipc	a3,0x5e
    80003684:	28868693          	addi	a3,a3,648 # 80061908 <log>
    80003688:	a039                	j	80003696 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000368a:	02090b63          	beqz	s2,800036c0 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000368e:	08848493          	addi	s1,s1,136
    80003692:	02d48a63          	beq	s1,a3,800036c6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003696:	449c                	lw	a5,8(s1)
    80003698:	fef059e3          	blez	a5,8000368a <iget+0x38>
    8000369c:	4098                	lw	a4,0(s1)
    8000369e:	ff3716e3          	bne	a4,s3,8000368a <iget+0x38>
    800036a2:	40d8                	lw	a4,4(s1)
    800036a4:	ff4713e3          	bne	a4,s4,8000368a <iget+0x38>
      ip->ref++;
    800036a8:	2785                	addiw	a5,a5,1
    800036aa:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036ac:	0005c517          	auipc	a0,0x5c
    800036b0:	7b450513          	addi	a0,a0,1972 # 8005fe60 <icache>
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	7a2080e7          	jalr	1954(ra) # 80000e56 <release>
      return ip;
    800036bc:	8926                	mv	s2,s1
    800036be:	a03d                	j	800036ec <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036c0:	f7f9                	bnez	a5,8000368e <iget+0x3c>
    800036c2:	8926                	mv	s2,s1
    800036c4:	b7e9                	j	8000368e <iget+0x3c>
  if(empty == 0)
    800036c6:	02090c63          	beqz	s2,800036fe <iget+0xac>
  ip->dev = dev;
    800036ca:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036ce:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036d2:	4785                	li	a5,1
    800036d4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036d8:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800036dc:	0005c517          	auipc	a0,0x5c
    800036e0:	78450513          	addi	a0,a0,1924 # 8005fe60 <icache>
    800036e4:	ffffd097          	auipc	ra,0xffffd
    800036e8:	772080e7          	jalr	1906(ra) # 80000e56 <release>
}
    800036ec:	854a                	mv	a0,s2
    800036ee:	70a2                	ld	ra,40(sp)
    800036f0:	7402                	ld	s0,32(sp)
    800036f2:	64e2                	ld	s1,24(sp)
    800036f4:	6942                	ld	s2,16(sp)
    800036f6:	69a2                	ld	s3,8(sp)
    800036f8:	6a02                	ld	s4,0(sp)
    800036fa:	6145                	addi	sp,sp,48
    800036fc:	8082                	ret
    panic("iget: no inodes");
    800036fe:	00005517          	auipc	a0,0x5
    80003702:	e7250513          	addi	a0,a0,-398 # 80008570 <syscalls+0x158>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	e6e080e7          	jalr	-402(ra) # 80000574 <panic>

000000008000370e <fsinit>:
fsinit(int dev) {
    8000370e:	7179                	addi	sp,sp,-48
    80003710:	f406                	sd	ra,40(sp)
    80003712:	f022                	sd	s0,32(sp)
    80003714:	ec26                	sd	s1,24(sp)
    80003716:	e84a                	sd	s2,16(sp)
    80003718:	e44e                	sd	s3,8(sp)
    8000371a:	1800                	addi	s0,sp,48
    8000371c:	89aa                	mv	s3,a0
  bp = bread(dev, 1);
    8000371e:	4585                	li	a1,1
    80003720:	00000097          	auipc	ra,0x0
    80003724:	a20080e7          	jalr	-1504(ra) # 80003140 <bread>
    80003728:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000372a:	0005c497          	auipc	s1,0x5c
    8000372e:	71648493          	addi	s1,s1,1814 # 8005fe40 <sb>
    80003732:	02000613          	li	a2,32
    80003736:	05850593          	addi	a1,a0,88
    8000373a:	8526                	mv	a0,s1
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	7ce080e7          	jalr	1998(ra) # 80000f0a <memmove>
  brelse(bp);
    80003744:	854a                	mv	a0,s2
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	b3c080e7          	jalr	-1220(ra) # 80003282 <brelse>
  if(sb.magic != FSMAGIC)
    8000374e:	4098                	lw	a4,0(s1)
    80003750:	102037b7          	lui	a5,0x10203
    80003754:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003758:	02f71263          	bne	a4,a5,8000377c <fsinit+0x6e>
  initlog(dev, &sb);
    8000375c:	0005c597          	auipc	a1,0x5c
    80003760:	6e458593          	addi	a1,a1,1764 # 8005fe40 <sb>
    80003764:	854e                	mv	a0,s3
    80003766:	00001097          	auipc	ra,0x1
    8000376a:	b4c080e7          	jalr	-1204(ra) # 800042b2 <initlog>
}
    8000376e:	70a2                	ld	ra,40(sp)
    80003770:	7402                	ld	s0,32(sp)
    80003772:	64e2                	ld	s1,24(sp)
    80003774:	6942                	ld	s2,16(sp)
    80003776:	69a2                	ld	s3,8(sp)
    80003778:	6145                	addi	sp,sp,48
    8000377a:	8082                	ret
    panic("invalid file system");
    8000377c:	00005517          	auipc	a0,0x5
    80003780:	e0450513          	addi	a0,a0,-508 # 80008580 <syscalls+0x168>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	df0080e7          	jalr	-528(ra) # 80000574 <panic>

000000008000378c <iinit>:
{
    8000378c:	7179                	addi	sp,sp,-48
    8000378e:	f406                	sd	ra,40(sp)
    80003790:	f022                	sd	s0,32(sp)
    80003792:	ec26                	sd	s1,24(sp)
    80003794:	e84a                	sd	s2,16(sp)
    80003796:	e44e                	sd	s3,8(sp)
    80003798:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000379a:	00005597          	auipc	a1,0x5
    8000379e:	dfe58593          	addi	a1,a1,-514 # 80008598 <syscalls+0x180>
    800037a2:	0005c517          	auipc	a0,0x5c
    800037a6:	6be50513          	addi	a0,a0,1726 # 8005fe60 <icache>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	568080e7          	jalr	1384(ra) # 80000d12 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037b2:	0005c497          	auipc	s1,0x5c
    800037b6:	6d648493          	addi	s1,s1,1750 # 8005fe88 <icache+0x28>
    800037ba:	0005e997          	auipc	s3,0x5e
    800037be:	15e98993          	addi	s3,s3,350 # 80061918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037c2:	00005917          	auipc	s2,0x5
    800037c6:	dde90913          	addi	s2,s2,-546 # 800085a0 <syscalls+0x188>
    800037ca:	85ca                	mv	a1,s2
    800037cc:	8526                	mv	a0,s1
    800037ce:	00001097          	auipc	ra,0x1
    800037d2:	e66080e7          	jalr	-410(ra) # 80004634 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037d6:	08848493          	addi	s1,s1,136
    800037da:	ff3498e3          	bne	s1,s3,800037ca <iinit+0x3e>
}
    800037de:	70a2                	ld	ra,40(sp)
    800037e0:	7402                	ld	s0,32(sp)
    800037e2:	64e2                	ld	s1,24(sp)
    800037e4:	6942                	ld	s2,16(sp)
    800037e6:	69a2                	ld	s3,8(sp)
    800037e8:	6145                	addi	sp,sp,48
    800037ea:	8082                	ret

00000000800037ec <ialloc>:
{
    800037ec:	715d                	addi	sp,sp,-80
    800037ee:	e486                	sd	ra,72(sp)
    800037f0:	e0a2                	sd	s0,64(sp)
    800037f2:	fc26                	sd	s1,56(sp)
    800037f4:	f84a                	sd	s2,48(sp)
    800037f6:	f44e                	sd	s3,40(sp)
    800037f8:	f052                	sd	s4,32(sp)
    800037fa:	ec56                	sd	s5,24(sp)
    800037fc:	e85a                	sd	s6,16(sp)
    800037fe:	e45e                	sd	s7,8(sp)
    80003800:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003802:	0005c797          	auipc	a5,0x5c
    80003806:	63e78793          	addi	a5,a5,1598 # 8005fe40 <sb>
    8000380a:	47d8                	lw	a4,12(a5)
    8000380c:	4785                	li	a5,1
    8000380e:	04e7fa63          	bleu	a4,a5,80003862 <ialloc+0x76>
    80003812:	8a2a                	mv	s4,a0
    80003814:	8b2e                	mv	s6,a1
    80003816:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003818:	0005c997          	auipc	s3,0x5c
    8000381c:	62898993          	addi	s3,s3,1576 # 8005fe40 <sb>
    80003820:	00048a9b          	sext.w	s5,s1
    80003824:	0044d593          	srli	a1,s1,0x4
    80003828:	0189a783          	lw	a5,24(s3)
    8000382c:	9dbd                	addw	a1,a1,a5
    8000382e:	8552                	mv	a0,s4
    80003830:	00000097          	auipc	ra,0x0
    80003834:	910080e7          	jalr	-1776(ra) # 80003140 <bread>
    80003838:	8baa                	mv	s7,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000383a:	05850913          	addi	s2,a0,88
    8000383e:	00f4f793          	andi	a5,s1,15
    80003842:	079a                	slli	a5,a5,0x6
    80003844:	993e                	add	s2,s2,a5
    if(dip->type == 0){  // a free inode
    80003846:	00091783          	lh	a5,0(s2)
    8000384a:	c785                	beqz	a5,80003872 <ialloc+0x86>
    brelse(bp);
    8000384c:	00000097          	auipc	ra,0x0
    80003850:	a36080e7          	jalr	-1482(ra) # 80003282 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003854:	0485                	addi	s1,s1,1
    80003856:	00c9a703          	lw	a4,12(s3)
    8000385a:	0004879b          	sext.w	a5,s1
    8000385e:	fce7e1e3          	bltu	a5,a4,80003820 <ialloc+0x34>
  panic("ialloc: no inodes");
    80003862:	00005517          	auipc	a0,0x5
    80003866:	d4650513          	addi	a0,a0,-698 # 800085a8 <syscalls+0x190>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	d0a080e7          	jalr	-758(ra) # 80000574 <panic>
      memset(dip, 0, sizeof(*dip));
    80003872:	04000613          	li	a2,64
    80003876:	4581                	li	a1,0
    80003878:	854a                	mv	a0,s2
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	624080e7          	jalr	1572(ra) # 80000e9e <memset>
      dip->type = type;
    80003882:	01691023          	sh	s6,0(s2)
      log_write(bp);   // mark it allocated on the disk
    80003886:	855e                	mv	a0,s7
    80003888:	00001097          	auipc	ra,0x1
    8000388c:	ca8080e7          	jalr	-856(ra) # 80004530 <log_write>
      brelse(bp);
    80003890:	855e                	mv	a0,s7
    80003892:	00000097          	auipc	ra,0x0
    80003896:	9f0080e7          	jalr	-1552(ra) # 80003282 <brelse>
      return iget(dev, inum);
    8000389a:	85d6                	mv	a1,s5
    8000389c:	8552                	mv	a0,s4
    8000389e:	00000097          	auipc	ra,0x0
    800038a2:	db4080e7          	jalr	-588(ra) # 80003652 <iget>
}
    800038a6:	60a6                	ld	ra,72(sp)
    800038a8:	6406                	ld	s0,64(sp)
    800038aa:	74e2                	ld	s1,56(sp)
    800038ac:	7942                	ld	s2,48(sp)
    800038ae:	79a2                	ld	s3,40(sp)
    800038b0:	7a02                	ld	s4,32(sp)
    800038b2:	6ae2                	ld	s5,24(sp)
    800038b4:	6b42                	ld	s6,16(sp)
    800038b6:	6ba2                	ld	s7,8(sp)
    800038b8:	6161                	addi	sp,sp,80
    800038ba:	8082                	ret

00000000800038bc <iupdate>:
{
    800038bc:	1101                	addi	sp,sp,-32
    800038be:	ec06                	sd	ra,24(sp)
    800038c0:	e822                	sd	s0,16(sp)
    800038c2:	e426                	sd	s1,8(sp)
    800038c4:	e04a                	sd	s2,0(sp)
    800038c6:	1000                	addi	s0,sp,32
    800038c8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ca:	415c                	lw	a5,4(a0)
    800038cc:	0047d79b          	srliw	a5,a5,0x4
    800038d0:	0005c717          	auipc	a4,0x5c
    800038d4:	57070713          	addi	a4,a4,1392 # 8005fe40 <sb>
    800038d8:	4f0c                	lw	a1,24(a4)
    800038da:	9dbd                	addw	a1,a1,a5
    800038dc:	4108                	lw	a0,0(a0)
    800038de:	00000097          	auipc	ra,0x0
    800038e2:	862080e7          	jalr	-1950(ra) # 80003140 <bread>
    800038e6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e8:	05850513          	addi	a0,a0,88
    800038ec:	40dc                	lw	a5,4(s1)
    800038ee:	8bbd                	andi	a5,a5,15
    800038f0:	079a                	slli	a5,a5,0x6
    800038f2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038f4:	04449783          	lh	a5,68(s1)
    800038f8:	00f51023          	sh	a5,0(a0)
  dip->major = ip->major;
    800038fc:	04649783          	lh	a5,70(s1)
    80003900:	00f51123          	sh	a5,2(a0)
  dip->minor = ip->minor;
    80003904:	04849783          	lh	a5,72(s1)
    80003908:	00f51223          	sh	a5,4(a0)
  dip->nlink = ip->nlink;
    8000390c:	04a49783          	lh	a5,74(s1)
    80003910:	00f51323          	sh	a5,6(a0)
  dip->size = ip->size;
    80003914:	44fc                	lw	a5,76(s1)
    80003916:	c51c                	sw	a5,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003918:	03400613          	li	a2,52
    8000391c:	05048593          	addi	a1,s1,80
    80003920:	0531                	addi	a0,a0,12
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	5e8080e7          	jalr	1512(ra) # 80000f0a <memmove>
  log_write(bp);
    8000392a:	854a                	mv	a0,s2
    8000392c:	00001097          	auipc	ra,0x1
    80003930:	c04080e7          	jalr	-1020(ra) # 80004530 <log_write>
  brelse(bp);
    80003934:	854a                	mv	a0,s2
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	94c080e7          	jalr	-1716(ra) # 80003282 <brelse>
}
    8000393e:	60e2                	ld	ra,24(sp)
    80003940:	6442                	ld	s0,16(sp)
    80003942:	64a2                	ld	s1,8(sp)
    80003944:	6902                	ld	s2,0(sp)
    80003946:	6105                	addi	sp,sp,32
    80003948:	8082                	ret

000000008000394a <idup>:
{
    8000394a:	1101                	addi	sp,sp,-32
    8000394c:	ec06                	sd	ra,24(sp)
    8000394e:	e822                	sd	s0,16(sp)
    80003950:	e426                	sd	s1,8(sp)
    80003952:	1000                	addi	s0,sp,32
    80003954:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003956:	0005c517          	auipc	a0,0x5c
    8000395a:	50a50513          	addi	a0,a0,1290 # 8005fe60 <icache>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	444080e7          	jalr	1092(ra) # 80000da2 <acquire>
  ip->ref++;
    80003966:	449c                	lw	a5,8(s1)
    80003968:	2785                	addiw	a5,a5,1
    8000396a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000396c:	0005c517          	auipc	a0,0x5c
    80003970:	4f450513          	addi	a0,a0,1268 # 8005fe60 <icache>
    80003974:	ffffd097          	auipc	ra,0xffffd
    80003978:	4e2080e7          	jalr	1250(ra) # 80000e56 <release>
}
    8000397c:	8526                	mv	a0,s1
    8000397e:	60e2                	ld	ra,24(sp)
    80003980:	6442                	ld	s0,16(sp)
    80003982:	64a2                	ld	s1,8(sp)
    80003984:	6105                	addi	sp,sp,32
    80003986:	8082                	ret

0000000080003988 <ilock>:
{
    80003988:	1101                	addi	sp,sp,-32
    8000398a:	ec06                	sd	ra,24(sp)
    8000398c:	e822                	sd	s0,16(sp)
    8000398e:	e426                	sd	s1,8(sp)
    80003990:	e04a                	sd	s2,0(sp)
    80003992:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003994:	c115                	beqz	a0,800039b8 <ilock+0x30>
    80003996:	84aa                	mv	s1,a0
    80003998:	451c                	lw	a5,8(a0)
    8000399a:	00f05f63          	blez	a5,800039b8 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000399e:	0541                	addi	a0,a0,16
    800039a0:	00001097          	auipc	ra,0x1
    800039a4:	cce080e7          	jalr	-818(ra) # 8000466e <acquiresleep>
  if(ip->valid == 0){
    800039a8:	40bc                	lw	a5,64(s1)
    800039aa:	cf99                	beqz	a5,800039c8 <ilock+0x40>
}
    800039ac:	60e2                	ld	ra,24(sp)
    800039ae:	6442                	ld	s0,16(sp)
    800039b0:	64a2                	ld	s1,8(sp)
    800039b2:	6902                	ld	s2,0(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret
    panic("ilock");
    800039b8:	00005517          	auipc	a0,0x5
    800039bc:	c0850513          	addi	a0,a0,-1016 # 800085c0 <syscalls+0x1a8>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	bb4080e7          	jalr	-1100(ra) # 80000574 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039c8:	40dc                	lw	a5,4(s1)
    800039ca:	0047d79b          	srliw	a5,a5,0x4
    800039ce:	0005c717          	auipc	a4,0x5c
    800039d2:	47270713          	addi	a4,a4,1138 # 8005fe40 <sb>
    800039d6:	4f0c                	lw	a1,24(a4)
    800039d8:	9dbd                	addw	a1,a1,a5
    800039da:	4088                	lw	a0,0(s1)
    800039dc:	fffff097          	auipc	ra,0xfffff
    800039e0:	764080e7          	jalr	1892(ra) # 80003140 <bread>
    800039e4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039e6:	05850593          	addi	a1,a0,88
    800039ea:	40dc                	lw	a5,4(s1)
    800039ec:	8bbd                	andi	a5,a5,15
    800039ee:	079a                	slli	a5,a5,0x6
    800039f0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039f2:	00059783          	lh	a5,0(a1)
    800039f6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039fa:	00259783          	lh	a5,2(a1)
    800039fe:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a02:	00459783          	lh	a5,4(a1)
    80003a06:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a0a:	00659783          	lh	a5,6(a1)
    80003a0e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a12:	459c                	lw	a5,8(a1)
    80003a14:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a16:	03400613          	li	a2,52
    80003a1a:	05b1                	addi	a1,a1,12
    80003a1c:	05048513          	addi	a0,s1,80
    80003a20:	ffffd097          	auipc	ra,0xffffd
    80003a24:	4ea080e7          	jalr	1258(ra) # 80000f0a <memmove>
    brelse(bp);
    80003a28:	854a                	mv	a0,s2
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	858080e7          	jalr	-1960(ra) # 80003282 <brelse>
    ip->valid = 1;
    80003a32:	4785                	li	a5,1
    80003a34:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a36:	04449783          	lh	a5,68(s1)
    80003a3a:	fbad                	bnez	a5,800039ac <ilock+0x24>
      panic("ilock: no type");
    80003a3c:	00005517          	auipc	a0,0x5
    80003a40:	b8c50513          	addi	a0,a0,-1140 # 800085c8 <syscalls+0x1b0>
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	b30080e7          	jalr	-1232(ra) # 80000574 <panic>

0000000080003a4c <iunlock>:
{
    80003a4c:	1101                	addi	sp,sp,-32
    80003a4e:	ec06                	sd	ra,24(sp)
    80003a50:	e822                	sd	s0,16(sp)
    80003a52:	e426                	sd	s1,8(sp)
    80003a54:	e04a                	sd	s2,0(sp)
    80003a56:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a58:	c905                	beqz	a0,80003a88 <iunlock+0x3c>
    80003a5a:	84aa                	mv	s1,a0
    80003a5c:	01050913          	addi	s2,a0,16
    80003a60:	854a                	mv	a0,s2
    80003a62:	00001097          	auipc	ra,0x1
    80003a66:	ca6080e7          	jalr	-858(ra) # 80004708 <holdingsleep>
    80003a6a:	cd19                	beqz	a0,80003a88 <iunlock+0x3c>
    80003a6c:	449c                	lw	a5,8(s1)
    80003a6e:	00f05d63          	blez	a5,80003a88 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a72:	854a                	mv	a0,s2
    80003a74:	00001097          	auipc	ra,0x1
    80003a78:	c50080e7          	jalr	-944(ra) # 800046c4 <releasesleep>
}
    80003a7c:	60e2                	ld	ra,24(sp)
    80003a7e:	6442                	ld	s0,16(sp)
    80003a80:	64a2                	ld	s1,8(sp)
    80003a82:	6902                	ld	s2,0(sp)
    80003a84:	6105                	addi	sp,sp,32
    80003a86:	8082                	ret
    panic("iunlock");
    80003a88:	00005517          	auipc	a0,0x5
    80003a8c:	b5050513          	addi	a0,a0,-1200 # 800085d8 <syscalls+0x1c0>
    80003a90:	ffffd097          	auipc	ra,0xffffd
    80003a94:	ae4080e7          	jalr	-1308(ra) # 80000574 <panic>

0000000080003a98 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a98:	7179                	addi	sp,sp,-48
    80003a9a:	f406                	sd	ra,40(sp)
    80003a9c:	f022                	sd	s0,32(sp)
    80003a9e:	ec26                	sd	s1,24(sp)
    80003aa0:	e84a                	sd	s2,16(sp)
    80003aa2:	e44e                	sd	s3,8(sp)
    80003aa4:	e052                	sd	s4,0(sp)
    80003aa6:	1800                	addi	s0,sp,48
    80003aa8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003aaa:	05050493          	addi	s1,a0,80
    80003aae:	08050913          	addi	s2,a0,128
    80003ab2:	a821                	j	80003aca <itrunc+0x32>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    80003ab4:	0009a503          	lw	a0,0(s3)
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	8e0080e7          	jalr	-1824(ra) # 80003398 <bfree>
      ip->addrs[i] = 0;
    80003ac0:	0004a023          	sw	zero,0(s1)
  for(i = 0; i < NDIRECT; i++){
    80003ac4:	0491                	addi	s1,s1,4
    80003ac6:	01248563          	beq	s1,s2,80003ad0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003aca:	408c                	lw	a1,0(s1)
    80003acc:	dde5                	beqz	a1,80003ac4 <itrunc+0x2c>
    80003ace:	b7dd                	j	80003ab4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ad0:	0809a583          	lw	a1,128(s3)
    80003ad4:	e185                	bnez	a1,80003af4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ad6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003ada:	854e                	mv	a0,s3
    80003adc:	00000097          	auipc	ra,0x0
    80003ae0:	de0080e7          	jalr	-544(ra) # 800038bc <iupdate>
}
    80003ae4:	70a2                	ld	ra,40(sp)
    80003ae6:	7402                	ld	s0,32(sp)
    80003ae8:	64e2                	ld	s1,24(sp)
    80003aea:	6942                	ld	s2,16(sp)
    80003aec:	69a2                	ld	s3,8(sp)
    80003aee:	6a02                	ld	s4,0(sp)
    80003af0:	6145                	addi	sp,sp,48
    80003af2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003af4:	0009a503          	lw	a0,0(s3)
    80003af8:	fffff097          	auipc	ra,0xfffff
    80003afc:	648080e7          	jalr	1608(ra) # 80003140 <bread>
    80003b00:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b02:	05850493          	addi	s1,a0,88
    80003b06:	45850913          	addi	s2,a0,1112
    80003b0a:	a811                	j	80003b1e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b0c:	0009a503          	lw	a0,0(s3)
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	888080e7          	jalr	-1912(ra) # 80003398 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b18:	0491                	addi	s1,s1,4
    80003b1a:	01248563          	beq	s1,s2,80003b24 <itrunc+0x8c>
      if(a[j])
    80003b1e:	408c                	lw	a1,0(s1)
    80003b20:	dde5                	beqz	a1,80003b18 <itrunc+0x80>
    80003b22:	b7ed                	j	80003b0c <itrunc+0x74>
    brelse(bp);
    80003b24:	8552                	mv	a0,s4
    80003b26:	fffff097          	auipc	ra,0xfffff
    80003b2a:	75c080e7          	jalr	1884(ra) # 80003282 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b2e:	0809a583          	lw	a1,128(s3)
    80003b32:	0009a503          	lw	a0,0(s3)
    80003b36:	00000097          	auipc	ra,0x0
    80003b3a:	862080e7          	jalr	-1950(ra) # 80003398 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b3e:	0809a023          	sw	zero,128(s3)
    80003b42:	bf51                	j	80003ad6 <itrunc+0x3e>

0000000080003b44 <iput>:
{
    80003b44:	1101                	addi	sp,sp,-32
    80003b46:	ec06                	sd	ra,24(sp)
    80003b48:	e822                	sd	s0,16(sp)
    80003b4a:	e426                	sd	s1,8(sp)
    80003b4c:	e04a                	sd	s2,0(sp)
    80003b4e:	1000                	addi	s0,sp,32
    80003b50:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b52:	0005c517          	auipc	a0,0x5c
    80003b56:	30e50513          	addi	a0,a0,782 # 8005fe60 <icache>
    80003b5a:	ffffd097          	auipc	ra,0xffffd
    80003b5e:	248080e7          	jalr	584(ra) # 80000da2 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b62:	4498                	lw	a4,8(s1)
    80003b64:	4785                	li	a5,1
    80003b66:	02f70363          	beq	a4,a5,80003b8c <iput+0x48>
  ip->ref--;
    80003b6a:	449c                	lw	a5,8(s1)
    80003b6c:	37fd                	addiw	a5,a5,-1
    80003b6e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b70:	0005c517          	auipc	a0,0x5c
    80003b74:	2f050513          	addi	a0,a0,752 # 8005fe60 <icache>
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	2de080e7          	jalr	734(ra) # 80000e56 <release>
}
    80003b80:	60e2                	ld	ra,24(sp)
    80003b82:	6442                	ld	s0,16(sp)
    80003b84:	64a2                	ld	s1,8(sp)
    80003b86:	6902                	ld	s2,0(sp)
    80003b88:	6105                	addi	sp,sp,32
    80003b8a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b8c:	40bc                	lw	a5,64(s1)
    80003b8e:	dff1                	beqz	a5,80003b6a <iput+0x26>
    80003b90:	04a49783          	lh	a5,74(s1)
    80003b94:	fbf9                	bnez	a5,80003b6a <iput+0x26>
    acquiresleep(&ip->lock);
    80003b96:	01048913          	addi	s2,s1,16
    80003b9a:	854a                	mv	a0,s2
    80003b9c:	00001097          	auipc	ra,0x1
    80003ba0:	ad2080e7          	jalr	-1326(ra) # 8000466e <acquiresleep>
    release(&icache.lock);
    80003ba4:	0005c517          	auipc	a0,0x5c
    80003ba8:	2bc50513          	addi	a0,a0,700 # 8005fe60 <icache>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	2aa080e7          	jalr	682(ra) # 80000e56 <release>
    itrunc(ip);
    80003bb4:	8526                	mv	a0,s1
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	ee2080e7          	jalr	-286(ra) # 80003a98 <itrunc>
    ip->type = 0;
    80003bbe:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bc2:	8526                	mv	a0,s1
    80003bc4:	00000097          	auipc	ra,0x0
    80003bc8:	cf8080e7          	jalr	-776(ra) # 800038bc <iupdate>
    ip->valid = 0;
    80003bcc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bd0:	854a                	mv	a0,s2
    80003bd2:	00001097          	auipc	ra,0x1
    80003bd6:	af2080e7          	jalr	-1294(ra) # 800046c4 <releasesleep>
    acquire(&icache.lock);
    80003bda:	0005c517          	auipc	a0,0x5c
    80003bde:	28650513          	addi	a0,a0,646 # 8005fe60 <icache>
    80003be2:	ffffd097          	auipc	ra,0xffffd
    80003be6:	1c0080e7          	jalr	448(ra) # 80000da2 <acquire>
    80003bea:	b741                	j	80003b6a <iput+0x26>

0000000080003bec <iunlockput>:
{
    80003bec:	1101                	addi	sp,sp,-32
    80003bee:	ec06                	sd	ra,24(sp)
    80003bf0:	e822                	sd	s0,16(sp)
    80003bf2:	e426                	sd	s1,8(sp)
    80003bf4:	1000                	addi	s0,sp,32
    80003bf6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bf8:	00000097          	auipc	ra,0x0
    80003bfc:	e54080e7          	jalr	-428(ra) # 80003a4c <iunlock>
  iput(ip);
    80003c00:	8526                	mv	a0,s1
    80003c02:	00000097          	auipc	ra,0x0
    80003c06:	f42080e7          	jalr	-190(ra) # 80003b44 <iput>
}
    80003c0a:	60e2                	ld	ra,24(sp)
    80003c0c:	6442                	ld	s0,16(sp)
    80003c0e:	64a2                	ld	s1,8(sp)
    80003c10:	6105                	addi	sp,sp,32
    80003c12:	8082                	ret

0000000080003c14 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c14:	1141                	addi	sp,sp,-16
    80003c16:	e422                	sd	s0,8(sp)
    80003c18:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c1a:	411c                	lw	a5,0(a0)
    80003c1c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c1e:	415c                	lw	a5,4(a0)
    80003c20:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c22:	04451783          	lh	a5,68(a0)
    80003c26:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c2a:	04a51783          	lh	a5,74(a0)
    80003c2e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c32:	04c56783          	lwu	a5,76(a0)
    80003c36:	e99c                	sd	a5,16(a1)
}
    80003c38:	6422                	ld	s0,8(sp)
    80003c3a:	0141                	addi	sp,sp,16
    80003c3c:	8082                	ret

0000000080003c3e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c3e:	457c                	lw	a5,76(a0)
    80003c40:	0ed7e963          	bltu	a5,a3,80003d32 <readi+0xf4>
{
    80003c44:	7159                	addi	sp,sp,-112
    80003c46:	f486                	sd	ra,104(sp)
    80003c48:	f0a2                	sd	s0,96(sp)
    80003c4a:	eca6                	sd	s1,88(sp)
    80003c4c:	e8ca                	sd	s2,80(sp)
    80003c4e:	e4ce                	sd	s3,72(sp)
    80003c50:	e0d2                	sd	s4,64(sp)
    80003c52:	fc56                	sd	s5,56(sp)
    80003c54:	f85a                	sd	s6,48(sp)
    80003c56:	f45e                	sd	s7,40(sp)
    80003c58:	f062                	sd	s8,32(sp)
    80003c5a:	ec66                	sd	s9,24(sp)
    80003c5c:	e86a                	sd	s10,16(sp)
    80003c5e:	e46e                	sd	s11,8(sp)
    80003c60:	1880                	addi	s0,sp,112
    80003c62:	8baa                	mv	s7,a0
    80003c64:	8c2e                	mv	s8,a1
    80003c66:	8a32                	mv	s4,a2
    80003c68:	84b6                	mv	s1,a3
    80003c6a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c6c:	9f35                	addw	a4,a4,a3
    return 0;
    80003c6e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c70:	0ad76063          	bltu	a4,a3,80003d10 <readi+0xd2>
  if(off + n > ip->size)
    80003c74:	00e7f463          	bleu	a4,a5,80003c7c <readi+0x3e>
    n = ip->size - off;
    80003c78:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c7c:	0a0b0963          	beqz	s6,80003d2e <readi+0xf0>
    80003c80:	4901                	li	s2,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c82:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c86:	5cfd                	li	s9,-1
    80003c88:	a82d                	j	80003cc2 <readi+0x84>
    80003c8a:	02099d93          	slli	s11,s3,0x20
    80003c8e:	020ddd93          	srli	s11,s11,0x20
    80003c92:	058a8613          	addi	a2,s5,88
    80003c96:	86ee                	mv	a3,s11
    80003c98:	963a                	add	a2,a2,a4
    80003c9a:	85d2                	mv	a1,s4
    80003c9c:	8562                	mv	a0,s8
    80003c9e:	fffff097          	auipc	ra,0xfffff
    80003ca2:	aaa080e7          	jalr	-1366(ra) # 80002748 <either_copyout>
    80003ca6:	05950d63          	beq	a0,s9,80003d00 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003caa:	8556                	mv	a0,s5
    80003cac:	fffff097          	auipc	ra,0xfffff
    80003cb0:	5d6080e7          	jalr	1494(ra) # 80003282 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cb4:	0129893b          	addw	s2,s3,s2
    80003cb8:	009984bb          	addw	s1,s3,s1
    80003cbc:	9a6e                	add	s4,s4,s11
    80003cbe:	05697763          	bleu	s6,s2,80003d0c <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cc2:	000ba983          	lw	s3,0(s7)
    80003cc6:	00a4d59b          	srliw	a1,s1,0xa
    80003cca:	855e                	mv	a0,s7
    80003ccc:	00000097          	auipc	ra,0x0
    80003cd0:	8ac080e7          	jalr	-1876(ra) # 80003578 <bmap>
    80003cd4:	0005059b          	sext.w	a1,a0
    80003cd8:	854e                	mv	a0,s3
    80003cda:	fffff097          	auipc	ra,0xfffff
    80003cde:	466080e7          	jalr	1126(ra) # 80003140 <bread>
    80003ce2:	8aaa                	mv	s5,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce4:	3ff4f713          	andi	a4,s1,1023
    80003ce8:	40ed07bb          	subw	a5,s10,a4
    80003cec:	412b06bb          	subw	a3,s6,s2
    80003cf0:	89be                	mv	s3,a5
    80003cf2:	2781                	sext.w	a5,a5
    80003cf4:	0006861b          	sext.w	a2,a3
    80003cf8:	f8f679e3          	bleu	a5,a2,80003c8a <readi+0x4c>
    80003cfc:	89b6                	mv	s3,a3
    80003cfe:	b771                	j	80003c8a <readi+0x4c>
      brelse(bp);
    80003d00:	8556                	mv	a0,s5
    80003d02:	fffff097          	auipc	ra,0xfffff
    80003d06:	580080e7          	jalr	1408(ra) # 80003282 <brelse>
      tot = -1;
    80003d0a:	597d                	li	s2,-1
  }
  return tot;
    80003d0c:	0009051b          	sext.w	a0,s2
}
    80003d10:	70a6                	ld	ra,104(sp)
    80003d12:	7406                	ld	s0,96(sp)
    80003d14:	64e6                	ld	s1,88(sp)
    80003d16:	6946                	ld	s2,80(sp)
    80003d18:	69a6                	ld	s3,72(sp)
    80003d1a:	6a06                	ld	s4,64(sp)
    80003d1c:	7ae2                	ld	s5,56(sp)
    80003d1e:	7b42                	ld	s6,48(sp)
    80003d20:	7ba2                	ld	s7,40(sp)
    80003d22:	7c02                	ld	s8,32(sp)
    80003d24:	6ce2                	ld	s9,24(sp)
    80003d26:	6d42                	ld	s10,16(sp)
    80003d28:	6da2                	ld	s11,8(sp)
    80003d2a:	6165                	addi	sp,sp,112
    80003d2c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d2e:	895a                	mv	s2,s6
    80003d30:	bff1                	j	80003d0c <readi+0xce>
    return 0;
    80003d32:	4501                	li	a0,0
}
    80003d34:	8082                	ret

0000000080003d36 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d36:	457c                	lw	a5,76(a0)
    80003d38:	10d7e763          	bltu	a5,a3,80003e46 <writei+0x110>
{
    80003d3c:	7159                	addi	sp,sp,-112
    80003d3e:	f486                	sd	ra,104(sp)
    80003d40:	f0a2                	sd	s0,96(sp)
    80003d42:	eca6                	sd	s1,88(sp)
    80003d44:	e8ca                	sd	s2,80(sp)
    80003d46:	e4ce                	sd	s3,72(sp)
    80003d48:	e0d2                	sd	s4,64(sp)
    80003d4a:	fc56                	sd	s5,56(sp)
    80003d4c:	f85a                	sd	s6,48(sp)
    80003d4e:	f45e                	sd	s7,40(sp)
    80003d50:	f062                	sd	s8,32(sp)
    80003d52:	ec66                	sd	s9,24(sp)
    80003d54:	e86a                	sd	s10,16(sp)
    80003d56:	e46e                	sd	s11,8(sp)
    80003d58:	1880                	addi	s0,sp,112
    80003d5a:	8baa                	mv	s7,a0
    80003d5c:	8c2e                	mv	s8,a1
    80003d5e:	8ab2                	mv	s5,a2
    80003d60:	84b6                	mv	s1,a3
    80003d62:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d64:	00e687bb          	addw	a5,a3,a4
    80003d68:	0ed7e163          	bltu	a5,a3,80003e4a <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d6c:	00043737          	lui	a4,0x43
    80003d70:	0cf76f63          	bltu	a4,a5,80003e4e <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d74:	0a0b0863          	beqz	s6,80003e24 <writei+0xee>
    80003d78:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d7a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d7e:	5cfd                	li	s9,-1
    80003d80:	a091                	j	80003dc4 <writei+0x8e>
    80003d82:	02091d93          	slli	s11,s2,0x20
    80003d86:	020ddd93          	srli	s11,s11,0x20
    80003d8a:	05898513          	addi	a0,s3,88
    80003d8e:	86ee                	mv	a3,s11
    80003d90:	8656                	mv	a2,s5
    80003d92:	85e2                	mv	a1,s8
    80003d94:	953a                	add	a0,a0,a4
    80003d96:	fffff097          	auipc	ra,0xfffff
    80003d9a:	a08080e7          	jalr	-1528(ra) # 8000279e <either_copyin>
    80003d9e:	07950263          	beq	a0,s9,80003e02 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003da2:	854e                	mv	a0,s3
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	78c080e7          	jalr	1932(ra) # 80004530 <log_write>
    brelse(bp);
    80003dac:	854e                	mv	a0,s3
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	4d4080e7          	jalr	1236(ra) # 80003282 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003db6:	01490a3b          	addw	s4,s2,s4
    80003dba:	009904bb          	addw	s1,s2,s1
    80003dbe:	9aee                	add	s5,s5,s11
    80003dc0:	056a7763          	bleu	s6,s4,80003e0e <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003dc4:	000ba903          	lw	s2,0(s7)
    80003dc8:	00a4d59b          	srliw	a1,s1,0xa
    80003dcc:	855e                	mv	a0,s7
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	7aa080e7          	jalr	1962(ra) # 80003578 <bmap>
    80003dd6:	0005059b          	sext.w	a1,a0
    80003dda:	854a                	mv	a0,s2
    80003ddc:	fffff097          	auipc	ra,0xfffff
    80003de0:	364080e7          	jalr	868(ra) # 80003140 <bread>
    80003de4:	89aa                	mv	s3,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003de6:	3ff4f713          	andi	a4,s1,1023
    80003dea:	40ed07bb          	subw	a5,s10,a4
    80003dee:	414b06bb          	subw	a3,s6,s4
    80003df2:	893e                	mv	s2,a5
    80003df4:	2781                	sext.w	a5,a5
    80003df6:	0006861b          	sext.w	a2,a3
    80003dfa:	f8f674e3          	bleu	a5,a2,80003d82 <writei+0x4c>
    80003dfe:	8936                	mv	s2,a3
    80003e00:	b749                	j	80003d82 <writei+0x4c>
      brelse(bp);
    80003e02:	854e                	mv	a0,s3
    80003e04:	fffff097          	auipc	ra,0xfffff
    80003e08:	47e080e7          	jalr	1150(ra) # 80003282 <brelse>
      n = -1;
    80003e0c:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003e0e:	04cba783          	lw	a5,76(s7)
    80003e12:	0097f463          	bleu	s1,a5,80003e1a <writei+0xe4>
      ip->size = off;
    80003e16:	049ba623          	sw	s1,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e1a:	855e                	mv	a0,s7
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	aa0080e7          	jalr	-1376(ra) # 800038bc <iupdate>
  }

  return n;
    80003e24:	000b051b          	sext.w	a0,s6
}
    80003e28:	70a6                	ld	ra,104(sp)
    80003e2a:	7406                	ld	s0,96(sp)
    80003e2c:	64e6                	ld	s1,88(sp)
    80003e2e:	6946                	ld	s2,80(sp)
    80003e30:	69a6                	ld	s3,72(sp)
    80003e32:	6a06                	ld	s4,64(sp)
    80003e34:	7ae2                	ld	s5,56(sp)
    80003e36:	7b42                	ld	s6,48(sp)
    80003e38:	7ba2                	ld	s7,40(sp)
    80003e3a:	7c02                	ld	s8,32(sp)
    80003e3c:	6ce2                	ld	s9,24(sp)
    80003e3e:	6d42                	ld	s10,16(sp)
    80003e40:	6da2                	ld	s11,8(sp)
    80003e42:	6165                	addi	sp,sp,112
    80003e44:	8082                	ret
    return -1;
    80003e46:	557d                	li	a0,-1
}
    80003e48:	8082                	ret
    return -1;
    80003e4a:	557d                	li	a0,-1
    80003e4c:	bff1                	j	80003e28 <writei+0xf2>
    return -1;
    80003e4e:	557d                	li	a0,-1
    80003e50:	bfe1                	j	80003e28 <writei+0xf2>

0000000080003e52 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e52:	1141                	addi	sp,sp,-16
    80003e54:	e406                	sd	ra,8(sp)
    80003e56:	e022                	sd	s0,0(sp)
    80003e58:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e5a:	4639                	li	a2,14
    80003e5c:	ffffd097          	auipc	ra,0xffffd
    80003e60:	12a080e7          	jalr	298(ra) # 80000f86 <strncmp>
}
    80003e64:	60a2                	ld	ra,8(sp)
    80003e66:	6402                	ld	s0,0(sp)
    80003e68:	0141                	addi	sp,sp,16
    80003e6a:	8082                	ret

0000000080003e6c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e6c:	7139                	addi	sp,sp,-64
    80003e6e:	fc06                	sd	ra,56(sp)
    80003e70:	f822                	sd	s0,48(sp)
    80003e72:	f426                	sd	s1,40(sp)
    80003e74:	f04a                	sd	s2,32(sp)
    80003e76:	ec4e                	sd	s3,24(sp)
    80003e78:	e852                	sd	s4,16(sp)
    80003e7a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e7c:	04451703          	lh	a4,68(a0)
    80003e80:	4785                	li	a5,1
    80003e82:	00f71a63          	bne	a4,a5,80003e96 <dirlookup+0x2a>
    80003e86:	892a                	mv	s2,a0
    80003e88:	89ae                	mv	s3,a1
    80003e8a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8c:	457c                	lw	a5,76(a0)
    80003e8e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e90:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e92:	e79d                	bnez	a5,80003ec0 <dirlookup+0x54>
    80003e94:	a8a5                	j	80003f0c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e96:	00004517          	auipc	a0,0x4
    80003e9a:	74a50513          	addi	a0,a0,1866 # 800085e0 <syscalls+0x1c8>
    80003e9e:	ffffc097          	auipc	ra,0xffffc
    80003ea2:	6d6080e7          	jalr	1750(ra) # 80000574 <panic>
      panic("dirlookup read");
    80003ea6:	00004517          	auipc	a0,0x4
    80003eaa:	75250513          	addi	a0,a0,1874 # 800085f8 <syscalls+0x1e0>
    80003eae:	ffffc097          	auipc	ra,0xffffc
    80003eb2:	6c6080e7          	jalr	1734(ra) # 80000574 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb6:	24c1                	addiw	s1,s1,16
    80003eb8:	04c92783          	lw	a5,76(s2)
    80003ebc:	04f4f763          	bleu	a5,s1,80003f0a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec0:	4741                	li	a4,16
    80003ec2:	86a6                	mv	a3,s1
    80003ec4:	fc040613          	addi	a2,s0,-64
    80003ec8:	4581                	li	a1,0
    80003eca:	854a                	mv	a0,s2
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	d72080e7          	jalr	-654(ra) # 80003c3e <readi>
    80003ed4:	47c1                	li	a5,16
    80003ed6:	fcf518e3          	bne	a0,a5,80003ea6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003eda:	fc045783          	lhu	a5,-64(s0)
    80003ede:	dfe1                	beqz	a5,80003eb6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ee0:	fc240593          	addi	a1,s0,-62
    80003ee4:	854e                	mv	a0,s3
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	f6c080e7          	jalr	-148(ra) # 80003e52 <namecmp>
    80003eee:	f561                	bnez	a0,80003eb6 <dirlookup+0x4a>
      if(poff)
    80003ef0:	000a0463          	beqz	s4,80003ef8 <dirlookup+0x8c>
        *poff = off;
    80003ef4:	009a2023          	sw	s1,0(s4) # 2000 <_entry-0x7fffe000>
      return iget(dp->dev, inum);
    80003ef8:	fc045583          	lhu	a1,-64(s0)
    80003efc:	00092503          	lw	a0,0(s2)
    80003f00:	fffff097          	auipc	ra,0xfffff
    80003f04:	752080e7          	jalr	1874(ra) # 80003652 <iget>
    80003f08:	a011                	j	80003f0c <dirlookup+0xa0>
  return 0;
    80003f0a:	4501                	li	a0,0
}
    80003f0c:	70e2                	ld	ra,56(sp)
    80003f0e:	7442                	ld	s0,48(sp)
    80003f10:	74a2                	ld	s1,40(sp)
    80003f12:	7902                	ld	s2,32(sp)
    80003f14:	69e2                	ld	s3,24(sp)
    80003f16:	6a42                	ld	s4,16(sp)
    80003f18:	6121                	addi	sp,sp,64
    80003f1a:	8082                	ret

0000000080003f1c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f1c:	711d                	addi	sp,sp,-96
    80003f1e:	ec86                	sd	ra,88(sp)
    80003f20:	e8a2                	sd	s0,80(sp)
    80003f22:	e4a6                	sd	s1,72(sp)
    80003f24:	e0ca                	sd	s2,64(sp)
    80003f26:	fc4e                	sd	s3,56(sp)
    80003f28:	f852                	sd	s4,48(sp)
    80003f2a:	f456                	sd	s5,40(sp)
    80003f2c:	f05a                	sd	s6,32(sp)
    80003f2e:	ec5e                	sd	s7,24(sp)
    80003f30:	e862                	sd	s8,16(sp)
    80003f32:	e466                	sd	s9,8(sp)
    80003f34:	1080                	addi	s0,sp,96
    80003f36:	84aa                	mv	s1,a0
    80003f38:	8bae                	mv	s7,a1
    80003f3a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f3c:	00054703          	lbu	a4,0(a0)
    80003f40:	02f00793          	li	a5,47
    80003f44:	02f70363          	beq	a4,a5,80003f6a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f48:	ffffe097          	auipc	ra,0xffffe
    80003f4c:	d84080e7          	jalr	-636(ra) # 80001ccc <myproc>
    80003f50:	15053503          	ld	a0,336(a0)
    80003f54:	00000097          	auipc	ra,0x0
    80003f58:	9f6080e7          	jalr	-1546(ra) # 8000394a <idup>
    80003f5c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f5e:	02f00913          	li	s2,47
  len = path - s;
    80003f62:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003f64:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f66:	4c05                	li	s8,1
    80003f68:	a865                	j	80004020 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f6a:	4585                	li	a1,1
    80003f6c:	4505                	li	a0,1
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	6e4080e7          	jalr	1764(ra) # 80003652 <iget>
    80003f76:	89aa                	mv	s3,a0
    80003f78:	b7dd                	j	80003f5e <namex+0x42>
      iunlockput(ip);
    80003f7a:	854e                	mv	a0,s3
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	c70080e7          	jalr	-912(ra) # 80003bec <iunlockput>
      return 0;
    80003f84:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f86:	854e                	mv	a0,s3
    80003f88:	60e6                	ld	ra,88(sp)
    80003f8a:	6446                	ld	s0,80(sp)
    80003f8c:	64a6                	ld	s1,72(sp)
    80003f8e:	6906                	ld	s2,64(sp)
    80003f90:	79e2                	ld	s3,56(sp)
    80003f92:	7a42                	ld	s4,48(sp)
    80003f94:	7aa2                	ld	s5,40(sp)
    80003f96:	7b02                	ld	s6,32(sp)
    80003f98:	6be2                	ld	s7,24(sp)
    80003f9a:	6c42                	ld	s8,16(sp)
    80003f9c:	6ca2                	ld	s9,8(sp)
    80003f9e:	6125                	addi	sp,sp,96
    80003fa0:	8082                	ret
      iunlock(ip);
    80003fa2:	854e                	mv	a0,s3
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	aa8080e7          	jalr	-1368(ra) # 80003a4c <iunlock>
      return ip;
    80003fac:	bfe9                	j	80003f86 <namex+0x6a>
      iunlockput(ip);
    80003fae:	854e                	mv	a0,s3
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	c3c080e7          	jalr	-964(ra) # 80003bec <iunlockput>
      return 0;
    80003fb8:	89d2                	mv	s3,s4
    80003fba:	b7f1                	j	80003f86 <namex+0x6a>
  len = path - s;
    80003fbc:	40b48633          	sub	a2,s1,a1
    80003fc0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fc4:	094cd663          	ble	s4,s9,80004050 <namex+0x134>
    memmove(name, s, DIRSIZ);
    80003fc8:	4639                	li	a2,14
    80003fca:	8556                	mv	a0,s5
    80003fcc:	ffffd097          	auipc	ra,0xffffd
    80003fd0:	f3e080e7          	jalr	-194(ra) # 80000f0a <memmove>
  while(*path == '/')
    80003fd4:	0004c783          	lbu	a5,0(s1)
    80003fd8:	01279763          	bne	a5,s2,80003fe6 <namex+0xca>
    path++;
    80003fdc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fde:	0004c783          	lbu	a5,0(s1)
    80003fe2:	ff278de3          	beq	a5,s2,80003fdc <namex+0xc0>
    ilock(ip);
    80003fe6:	854e                	mv	a0,s3
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	9a0080e7          	jalr	-1632(ra) # 80003988 <ilock>
    if(ip->type != T_DIR){
    80003ff0:	04499783          	lh	a5,68(s3)
    80003ff4:	f98793e3          	bne	a5,s8,80003f7a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ff8:	000b8563          	beqz	s7,80004002 <namex+0xe6>
    80003ffc:	0004c783          	lbu	a5,0(s1)
    80004000:	d3cd                	beqz	a5,80003fa2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004002:	865a                	mv	a2,s6
    80004004:	85d6                	mv	a1,s5
    80004006:	854e                	mv	a0,s3
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	e64080e7          	jalr	-412(ra) # 80003e6c <dirlookup>
    80004010:	8a2a                	mv	s4,a0
    80004012:	dd51                	beqz	a0,80003fae <namex+0x92>
    iunlockput(ip);
    80004014:	854e                	mv	a0,s3
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	bd6080e7          	jalr	-1066(ra) # 80003bec <iunlockput>
    ip = next;
    8000401e:	89d2                	mv	s3,s4
  while(*path == '/')
    80004020:	0004c783          	lbu	a5,0(s1)
    80004024:	05279d63          	bne	a5,s2,8000407e <namex+0x162>
    path++;
    80004028:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000402a:	0004c783          	lbu	a5,0(s1)
    8000402e:	ff278de3          	beq	a5,s2,80004028 <namex+0x10c>
  if(*path == 0)
    80004032:	cf8d                	beqz	a5,8000406c <namex+0x150>
  while(*path != '/' && *path != 0)
    80004034:	01278b63          	beq	a5,s2,8000404a <namex+0x12e>
    80004038:	c795                	beqz	a5,80004064 <namex+0x148>
    path++;
    8000403a:	85a6                	mv	a1,s1
    path++;
    8000403c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000403e:	0004c783          	lbu	a5,0(s1)
    80004042:	f7278de3          	beq	a5,s2,80003fbc <namex+0xa0>
    80004046:	fbfd                	bnez	a5,8000403c <namex+0x120>
    80004048:	bf95                	j	80003fbc <namex+0xa0>
    8000404a:	85a6                	mv	a1,s1
  len = path - s;
    8000404c:	8a5a                	mv	s4,s6
    8000404e:	865a                	mv	a2,s6
    memmove(name, s, len);
    80004050:	2601                	sext.w	a2,a2
    80004052:	8556                	mv	a0,s5
    80004054:	ffffd097          	auipc	ra,0xffffd
    80004058:	eb6080e7          	jalr	-330(ra) # 80000f0a <memmove>
    name[len] = 0;
    8000405c:	9a56                	add	s4,s4,s5
    8000405e:	000a0023          	sb	zero,0(s4)
    80004062:	bf8d                	j	80003fd4 <namex+0xb8>
  while(*path != '/' && *path != 0)
    80004064:	85a6                	mv	a1,s1
  len = path - s;
    80004066:	8a5a                	mv	s4,s6
    80004068:	865a                	mv	a2,s6
    8000406a:	b7dd                	j	80004050 <namex+0x134>
  if(nameiparent){
    8000406c:	f00b8de3          	beqz	s7,80003f86 <namex+0x6a>
    iput(ip);
    80004070:	854e                	mv	a0,s3
    80004072:	00000097          	auipc	ra,0x0
    80004076:	ad2080e7          	jalr	-1326(ra) # 80003b44 <iput>
    return 0;
    8000407a:	4981                	li	s3,0
    8000407c:	b729                	j	80003f86 <namex+0x6a>
  if(*path == 0)
    8000407e:	d7fd                	beqz	a5,8000406c <namex+0x150>
    80004080:	85a6                	mv	a1,s1
    80004082:	bf6d                	j	8000403c <namex+0x120>

0000000080004084 <dirlink>:
{
    80004084:	7139                	addi	sp,sp,-64
    80004086:	fc06                	sd	ra,56(sp)
    80004088:	f822                	sd	s0,48(sp)
    8000408a:	f426                	sd	s1,40(sp)
    8000408c:	f04a                	sd	s2,32(sp)
    8000408e:	ec4e                	sd	s3,24(sp)
    80004090:	e852                	sd	s4,16(sp)
    80004092:	0080                	addi	s0,sp,64
    80004094:	892a                	mv	s2,a0
    80004096:	8a2e                	mv	s4,a1
    80004098:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000409a:	4601                	li	a2,0
    8000409c:	00000097          	auipc	ra,0x0
    800040a0:	dd0080e7          	jalr	-560(ra) # 80003e6c <dirlookup>
    800040a4:	e93d                	bnez	a0,8000411a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040a6:	04c92483          	lw	s1,76(s2)
    800040aa:	c49d                	beqz	s1,800040d8 <dirlink+0x54>
    800040ac:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ae:	4741                	li	a4,16
    800040b0:	86a6                	mv	a3,s1
    800040b2:	fc040613          	addi	a2,s0,-64
    800040b6:	4581                	li	a1,0
    800040b8:	854a                	mv	a0,s2
    800040ba:	00000097          	auipc	ra,0x0
    800040be:	b84080e7          	jalr	-1148(ra) # 80003c3e <readi>
    800040c2:	47c1                	li	a5,16
    800040c4:	06f51163          	bne	a0,a5,80004126 <dirlink+0xa2>
    if(de.inum == 0)
    800040c8:	fc045783          	lhu	a5,-64(s0)
    800040cc:	c791                	beqz	a5,800040d8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040ce:	24c1                	addiw	s1,s1,16
    800040d0:	04c92783          	lw	a5,76(s2)
    800040d4:	fcf4ede3          	bltu	s1,a5,800040ae <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040d8:	4639                	li	a2,14
    800040da:	85d2                	mv	a1,s4
    800040dc:	fc240513          	addi	a0,s0,-62
    800040e0:	ffffd097          	auipc	ra,0xffffd
    800040e4:	ef6080e7          	jalr	-266(ra) # 80000fd6 <strncpy>
  de.inum = inum;
    800040e8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040ec:	4741                	li	a4,16
    800040ee:	86a6                	mv	a3,s1
    800040f0:	fc040613          	addi	a2,s0,-64
    800040f4:	4581                	li	a1,0
    800040f6:	854a                	mv	a0,s2
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	c3e080e7          	jalr	-962(ra) # 80003d36 <writei>
    80004100:	4741                	li	a4,16
  return 0;
    80004102:	4781                	li	a5,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004104:	02e51963          	bne	a0,a4,80004136 <dirlink+0xb2>
}
    80004108:	853e                	mv	a0,a5
    8000410a:	70e2                	ld	ra,56(sp)
    8000410c:	7442                	ld	s0,48(sp)
    8000410e:	74a2                	ld	s1,40(sp)
    80004110:	7902                	ld	s2,32(sp)
    80004112:	69e2                	ld	s3,24(sp)
    80004114:	6a42                	ld	s4,16(sp)
    80004116:	6121                	addi	sp,sp,64
    80004118:	8082                	ret
    iput(ip);
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	a2a080e7          	jalr	-1494(ra) # 80003b44 <iput>
    return -1;
    80004122:	57fd                	li	a5,-1
    80004124:	b7d5                	j	80004108 <dirlink+0x84>
      panic("dirlink read");
    80004126:	00004517          	auipc	a0,0x4
    8000412a:	4e250513          	addi	a0,a0,1250 # 80008608 <syscalls+0x1f0>
    8000412e:	ffffc097          	auipc	ra,0xffffc
    80004132:	446080e7          	jalr	1094(ra) # 80000574 <panic>
    panic("dirlink");
    80004136:	00004517          	auipc	a0,0x4
    8000413a:	5f250513          	addi	a0,a0,1522 # 80008728 <syscalls+0x310>
    8000413e:	ffffc097          	auipc	ra,0xffffc
    80004142:	436080e7          	jalr	1078(ra) # 80000574 <panic>

0000000080004146 <namei>:

struct inode*
namei(char *path)
{
    80004146:	1101                	addi	sp,sp,-32
    80004148:	ec06                	sd	ra,24(sp)
    8000414a:	e822                	sd	s0,16(sp)
    8000414c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000414e:	fe040613          	addi	a2,s0,-32
    80004152:	4581                	li	a1,0
    80004154:	00000097          	auipc	ra,0x0
    80004158:	dc8080e7          	jalr	-568(ra) # 80003f1c <namex>
}
    8000415c:	60e2                	ld	ra,24(sp)
    8000415e:	6442                	ld	s0,16(sp)
    80004160:	6105                	addi	sp,sp,32
    80004162:	8082                	ret

0000000080004164 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004164:	1141                	addi	sp,sp,-16
    80004166:	e406                	sd	ra,8(sp)
    80004168:	e022                	sd	s0,0(sp)
    8000416a:	0800                	addi	s0,sp,16
  return namex(path, 1, name);
    8000416c:	862e                	mv	a2,a1
    8000416e:	4585                	li	a1,1
    80004170:	00000097          	auipc	ra,0x0
    80004174:	dac080e7          	jalr	-596(ra) # 80003f1c <namex>
}
    80004178:	60a2                	ld	ra,8(sp)
    8000417a:	6402                	ld	s0,0(sp)
    8000417c:	0141                	addi	sp,sp,16
    8000417e:	8082                	ret

0000000080004180 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004180:	1101                	addi	sp,sp,-32
    80004182:	ec06                	sd	ra,24(sp)
    80004184:	e822                	sd	s0,16(sp)
    80004186:	e426                	sd	s1,8(sp)
    80004188:	e04a                	sd	s2,0(sp)
    8000418a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000418c:	0005d917          	auipc	s2,0x5d
    80004190:	77c90913          	addi	s2,s2,1916 # 80061908 <log>
    80004194:	01892583          	lw	a1,24(s2)
    80004198:	02892503          	lw	a0,40(s2)
    8000419c:	fffff097          	auipc	ra,0xfffff
    800041a0:	fa4080e7          	jalr	-92(ra) # 80003140 <bread>
    800041a4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041a6:	02c92683          	lw	a3,44(s2)
    800041aa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041ac:	02d05763          	blez	a3,800041da <write_head+0x5a>
    800041b0:	0005d797          	auipc	a5,0x5d
    800041b4:	78878793          	addi	a5,a5,1928 # 80061938 <log+0x30>
    800041b8:	05c50713          	addi	a4,a0,92
    800041bc:	36fd                	addiw	a3,a3,-1
    800041be:	1682                	slli	a3,a3,0x20
    800041c0:	9281                	srli	a3,a3,0x20
    800041c2:	068a                	slli	a3,a3,0x2
    800041c4:	0005d617          	auipc	a2,0x5d
    800041c8:	77860613          	addi	a2,a2,1912 # 8006193c <log+0x34>
    800041cc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041ce:	4390                	lw	a2,0(a5)
    800041d0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041d2:	0791                	addi	a5,a5,4
    800041d4:	0711                	addi	a4,a4,4
    800041d6:	fed79ce3          	bne	a5,a3,800041ce <write_head+0x4e>
  }
  bwrite(buf);
    800041da:	8526                	mv	a0,s1
    800041dc:	fffff097          	auipc	ra,0xfffff
    800041e0:	068080e7          	jalr	104(ra) # 80003244 <bwrite>
  brelse(buf);
    800041e4:	8526                	mv	a0,s1
    800041e6:	fffff097          	auipc	ra,0xfffff
    800041ea:	09c080e7          	jalr	156(ra) # 80003282 <brelse>
}
    800041ee:	60e2                	ld	ra,24(sp)
    800041f0:	6442                	ld	s0,16(sp)
    800041f2:	64a2                	ld	s1,8(sp)
    800041f4:	6902                	ld	s2,0(sp)
    800041f6:	6105                	addi	sp,sp,32
    800041f8:	8082                	ret

00000000800041fa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041fa:	0005d797          	auipc	a5,0x5d
    800041fe:	70e78793          	addi	a5,a5,1806 # 80061908 <log>
    80004202:	57dc                	lw	a5,44(a5)
    80004204:	0af05663          	blez	a5,800042b0 <install_trans+0xb6>
{
    80004208:	7139                	addi	sp,sp,-64
    8000420a:	fc06                	sd	ra,56(sp)
    8000420c:	f822                	sd	s0,48(sp)
    8000420e:	f426                	sd	s1,40(sp)
    80004210:	f04a                	sd	s2,32(sp)
    80004212:	ec4e                	sd	s3,24(sp)
    80004214:	e852                	sd	s4,16(sp)
    80004216:	e456                	sd	s5,8(sp)
    80004218:	0080                	addi	s0,sp,64
    8000421a:	0005da17          	auipc	s4,0x5d
    8000421e:	71ea0a13          	addi	s4,s4,1822 # 80061938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004222:	4981                	li	s3,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004224:	0005d917          	auipc	s2,0x5d
    80004228:	6e490913          	addi	s2,s2,1764 # 80061908 <log>
    8000422c:	01892583          	lw	a1,24(s2)
    80004230:	013585bb          	addw	a1,a1,s3
    80004234:	2585                	addiw	a1,a1,1
    80004236:	02892503          	lw	a0,40(s2)
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	f06080e7          	jalr	-250(ra) # 80003140 <bread>
    80004242:	8aaa                	mv	s5,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004244:	000a2583          	lw	a1,0(s4)
    80004248:	02892503          	lw	a0,40(s2)
    8000424c:	fffff097          	auipc	ra,0xfffff
    80004250:	ef4080e7          	jalr	-268(ra) # 80003140 <bread>
    80004254:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004256:	40000613          	li	a2,1024
    8000425a:	058a8593          	addi	a1,s5,88
    8000425e:	05850513          	addi	a0,a0,88
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	ca8080e7          	jalr	-856(ra) # 80000f0a <memmove>
    bwrite(dbuf);  // write dst to disk
    8000426a:	8526                	mv	a0,s1
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	fd8080e7          	jalr	-40(ra) # 80003244 <bwrite>
    bunpin(dbuf);
    80004274:	8526                	mv	a0,s1
    80004276:	fffff097          	auipc	ra,0xfffff
    8000427a:	0e6080e7          	jalr	230(ra) # 8000335c <bunpin>
    brelse(lbuf);
    8000427e:	8556                	mv	a0,s5
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	002080e7          	jalr	2(ra) # 80003282 <brelse>
    brelse(dbuf);
    80004288:	8526                	mv	a0,s1
    8000428a:	fffff097          	auipc	ra,0xfffff
    8000428e:	ff8080e7          	jalr	-8(ra) # 80003282 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004292:	2985                	addiw	s3,s3,1
    80004294:	0a11                	addi	s4,s4,4
    80004296:	02c92783          	lw	a5,44(s2)
    8000429a:	f8f9c9e3          	blt	s3,a5,8000422c <install_trans+0x32>
}
    8000429e:	70e2                	ld	ra,56(sp)
    800042a0:	7442                	ld	s0,48(sp)
    800042a2:	74a2                	ld	s1,40(sp)
    800042a4:	7902                	ld	s2,32(sp)
    800042a6:	69e2                	ld	s3,24(sp)
    800042a8:	6a42                	ld	s4,16(sp)
    800042aa:	6aa2                	ld	s5,8(sp)
    800042ac:	6121                	addi	sp,sp,64
    800042ae:	8082                	ret
    800042b0:	8082                	ret

00000000800042b2 <initlog>:
{
    800042b2:	7179                	addi	sp,sp,-48
    800042b4:	f406                	sd	ra,40(sp)
    800042b6:	f022                	sd	s0,32(sp)
    800042b8:	ec26                	sd	s1,24(sp)
    800042ba:	e84a                	sd	s2,16(sp)
    800042bc:	e44e                	sd	s3,8(sp)
    800042be:	1800                	addi	s0,sp,48
    800042c0:	892a                	mv	s2,a0
    800042c2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042c4:	0005d497          	auipc	s1,0x5d
    800042c8:	64448493          	addi	s1,s1,1604 # 80061908 <log>
    800042cc:	00004597          	auipc	a1,0x4
    800042d0:	34c58593          	addi	a1,a1,844 # 80008618 <syscalls+0x200>
    800042d4:	8526                	mv	a0,s1
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	a3c080e7          	jalr	-1476(ra) # 80000d12 <initlock>
  log.start = sb->logstart;
    800042de:	0149a583          	lw	a1,20(s3)
    800042e2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042e4:	0109a783          	lw	a5,16(s3)
    800042e8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042ea:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042ee:	854a                	mv	a0,s2
    800042f0:	fffff097          	auipc	ra,0xfffff
    800042f4:	e50080e7          	jalr	-432(ra) # 80003140 <bread>
  log.lh.n = lh->n;
    800042f8:	4d3c                	lw	a5,88(a0)
    800042fa:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042fc:	02f05563          	blez	a5,80004326 <initlog+0x74>
    80004300:	05c50713          	addi	a4,a0,92
    80004304:	0005d697          	auipc	a3,0x5d
    80004308:	63468693          	addi	a3,a3,1588 # 80061938 <log+0x30>
    8000430c:	37fd                	addiw	a5,a5,-1
    8000430e:	1782                	slli	a5,a5,0x20
    80004310:	9381                	srli	a5,a5,0x20
    80004312:	078a                	slli	a5,a5,0x2
    80004314:	06050613          	addi	a2,a0,96
    80004318:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000431a:	4310                	lw	a2,0(a4)
    8000431c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000431e:	0711                	addi	a4,a4,4
    80004320:	0691                	addi	a3,a3,4
    80004322:	fef71ce3          	bne	a4,a5,8000431a <initlog+0x68>
  brelse(buf);
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	f5c080e7          	jalr	-164(ra) # 80003282 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	ecc080e7          	jalr	-308(ra) # 800041fa <install_trans>
  log.lh.n = 0;
    80004336:	0005d797          	auipc	a5,0x5d
    8000433a:	5e07af23          	sw	zero,1534(a5) # 80061934 <log+0x2c>
  write_head(); // clear the log
    8000433e:	00000097          	auipc	ra,0x0
    80004342:	e42080e7          	jalr	-446(ra) # 80004180 <write_head>
}
    80004346:	70a2                	ld	ra,40(sp)
    80004348:	7402                	ld	s0,32(sp)
    8000434a:	64e2                	ld	s1,24(sp)
    8000434c:	6942                	ld	s2,16(sp)
    8000434e:	69a2                	ld	s3,8(sp)
    80004350:	6145                	addi	sp,sp,48
    80004352:	8082                	ret

0000000080004354 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004354:	1101                	addi	sp,sp,-32
    80004356:	ec06                	sd	ra,24(sp)
    80004358:	e822                	sd	s0,16(sp)
    8000435a:	e426                	sd	s1,8(sp)
    8000435c:	e04a                	sd	s2,0(sp)
    8000435e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004360:	0005d517          	auipc	a0,0x5d
    80004364:	5a850513          	addi	a0,a0,1448 # 80061908 <log>
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	a3a080e7          	jalr	-1478(ra) # 80000da2 <acquire>
  while(1){
    if(log.committing){
    80004370:	0005d497          	auipc	s1,0x5d
    80004374:	59848493          	addi	s1,s1,1432 # 80061908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004378:	4979                	li	s2,30
    8000437a:	a039                	j	80004388 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000437c:	85a6                	mv	a1,s1
    8000437e:	8526                	mv	a0,s1
    80004380:	ffffe097          	auipc	ra,0xffffe
    80004384:	166080e7          	jalr	358(ra) # 800024e6 <sleep>
    if(log.committing){
    80004388:	50dc                	lw	a5,36(s1)
    8000438a:	fbed                	bnez	a5,8000437c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000438c:	509c                	lw	a5,32(s1)
    8000438e:	0017871b          	addiw	a4,a5,1
    80004392:	0007069b          	sext.w	a3,a4
    80004396:	0027179b          	slliw	a5,a4,0x2
    8000439a:	9fb9                	addw	a5,a5,a4
    8000439c:	0017979b          	slliw	a5,a5,0x1
    800043a0:	54d8                	lw	a4,44(s1)
    800043a2:	9fb9                	addw	a5,a5,a4
    800043a4:	00f95963          	ble	a5,s2,800043b6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043a8:	85a6                	mv	a1,s1
    800043aa:	8526                	mv	a0,s1
    800043ac:	ffffe097          	auipc	ra,0xffffe
    800043b0:	13a080e7          	jalr	314(ra) # 800024e6 <sleep>
    800043b4:	bfd1                	j	80004388 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043b6:	0005d517          	auipc	a0,0x5d
    800043ba:	55250513          	addi	a0,a0,1362 # 80061908 <log>
    800043be:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043c0:	ffffd097          	auipc	ra,0xffffd
    800043c4:	a96080e7          	jalr	-1386(ra) # 80000e56 <release>
      break;
    }
  }
}
    800043c8:	60e2                	ld	ra,24(sp)
    800043ca:	6442                	ld	s0,16(sp)
    800043cc:	64a2                	ld	s1,8(sp)
    800043ce:	6902                	ld	s2,0(sp)
    800043d0:	6105                	addi	sp,sp,32
    800043d2:	8082                	ret

00000000800043d4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043d4:	7139                	addi	sp,sp,-64
    800043d6:	fc06                	sd	ra,56(sp)
    800043d8:	f822                	sd	s0,48(sp)
    800043da:	f426                	sd	s1,40(sp)
    800043dc:	f04a                	sd	s2,32(sp)
    800043de:	ec4e                	sd	s3,24(sp)
    800043e0:	e852                	sd	s4,16(sp)
    800043e2:	e456                	sd	s5,8(sp)
    800043e4:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043e6:	0005d917          	auipc	s2,0x5d
    800043ea:	52290913          	addi	s2,s2,1314 # 80061908 <log>
    800043ee:	854a                	mv	a0,s2
    800043f0:	ffffd097          	auipc	ra,0xffffd
    800043f4:	9b2080e7          	jalr	-1614(ra) # 80000da2 <acquire>
  log.outstanding -= 1;
    800043f8:	02092783          	lw	a5,32(s2)
    800043fc:	37fd                	addiw	a5,a5,-1
    800043fe:	0007849b          	sext.w	s1,a5
    80004402:	02f92023          	sw	a5,32(s2)
  if(log.committing)
    80004406:	02492783          	lw	a5,36(s2)
    8000440a:	eba1                	bnez	a5,8000445a <end_op+0x86>
    panic("log.committing");
  if(log.outstanding == 0){
    8000440c:	ecb9                	bnez	s1,8000446a <end_op+0x96>
    do_commit = 1;
    log.committing = 1;
    8000440e:	0005d917          	auipc	s2,0x5d
    80004412:	4fa90913          	addi	s2,s2,1274 # 80061908 <log>
    80004416:	4785                	li	a5,1
    80004418:	02f92223          	sw	a5,36(s2)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000441c:	854a                	mv	a0,s2
    8000441e:	ffffd097          	auipc	ra,0xffffd
    80004422:	a38080e7          	jalr	-1480(ra) # 80000e56 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004426:	02c92783          	lw	a5,44(s2)
    8000442a:	06f04763          	bgtz	a5,80004498 <end_op+0xc4>
    acquire(&log.lock);
    8000442e:	0005d497          	auipc	s1,0x5d
    80004432:	4da48493          	addi	s1,s1,1242 # 80061908 <log>
    80004436:	8526                	mv	a0,s1
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	96a080e7          	jalr	-1686(ra) # 80000da2 <acquire>
    log.committing = 0;
    80004440:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004444:	8526                	mv	a0,s1
    80004446:	ffffe097          	auipc	ra,0xffffe
    8000444a:	226080e7          	jalr	550(ra) # 8000266c <wakeup>
    release(&log.lock);
    8000444e:	8526                	mv	a0,s1
    80004450:	ffffd097          	auipc	ra,0xffffd
    80004454:	a06080e7          	jalr	-1530(ra) # 80000e56 <release>
}
    80004458:	a03d                	j	80004486 <end_op+0xb2>
    panic("log.committing");
    8000445a:	00004517          	auipc	a0,0x4
    8000445e:	1c650513          	addi	a0,a0,454 # 80008620 <syscalls+0x208>
    80004462:	ffffc097          	auipc	ra,0xffffc
    80004466:	112080e7          	jalr	274(ra) # 80000574 <panic>
    wakeup(&log);
    8000446a:	0005d497          	auipc	s1,0x5d
    8000446e:	49e48493          	addi	s1,s1,1182 # 80061908 <log>
    80004472:	8526                	mv	a0,s1
    80004474:	ffffe097          	auipc	ra,0xffffe
    80004478:	1f8080e7          	jalr	504(ra) # 8000266c <wakeup>
  release(&log.lock);
    8000447c:	8526                	mv	a0,s1
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	9d8080e7          	jalr	-1576(ra) # 80000e56 <release>
}
    80004486:	70e2                	ld	ra,56(sp)
    80004488:	7442                	ld	s0,48(sp)
    8000448a:	74a2                	ld	s1,40(sp)
    8000448c:	7902                	ld	s2,32(sp)
    8000448e:	69e2                	ld	s3,24(sp)
    80004490:	6a42                	ld	s4,16(sp)
    80004492:	6aa2                	ld	s5,8(sp)
    80004494:	6121                	addi	sp,sp,64
    80004496:	8082                	ret
    80004498:	0005da17          	auipc	s4,0x5d
    8000449c:	4a0a0a13          	addi	s4,s4,1184 # 80061938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044a0:	0005d917          	auipc	s2,0x5d
    800044a4:	46890913          	addi	s2,s2,1128 # 80061908 <log>
    800044a8:	01892583          	lw	a1,24(s2)
    800044ac:	9da5                	addw	a1,a1,s1
    800044ae:	2585                	addiw	a1,a1,1
    800044b0:	02892503          	lw	a0,40(s2)
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	c8c080e7          	jalr	-884(ra) # 80003140 <bread>
    800044bc:	89aa                	mv	s3,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044be:	000a2583          	lw	a1,0(s4)
    800044c2:	02892503          	lw	a0,40(s2)
    800044c6:	fffff097          	auipc	ra,0xfffff
    800044ca:	c7a080e7          	jalr	-902(ra) # 80003140 <bread>
    800044ce:	8aaa                	mv	s5,a0
    memmove(to->data, from->data, BSIZE);
    800044d0:	40000613          	li	a2,1024
    800044d4:	05850593          	addi	a1,a0,88
    800044d8:	05898513          	addi	a0,s3,88
    800044dc:	ffffd097          	auipc	ra,0xffffd
    800044e0:	a2e080e7          	jalr	-1490(ra) # 80000f0a <memmove>
    bwrite(to);  // write the log
    800044e4:	854e                	mv	a0,s3
    800044e6:	fffff097          	auipc	ra,0xfffff
    800044ea:	d5e080e7          	jalr	-674(ra) # 80003244 <bwrite>
    brelse(from);
    800044ee:	8556                	mv	a0,s5
    800044f0:	fffff097          	auipc	ra,0xfffff
    800044f4:	d92080e7          	jalr	-622(ra) # 80003282 <brelse>
    brelse(to);
    800044f8:	854e                	mv	a0,s3
    800044fa:	fffff097          	auipc	ra,0xfffff
    800044fe:	d88080e7          	jalr	-632(ra) # 80003282 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004502:	2485                	addiw	s1,s1,1
    80004504:	0a11                	addi	s4,s4,4
    80004506:	02c92783          	lw	a5,44(s2)
    8000450a:	f8f4cfe3          	blt	s1,a5,800044a8 <end_op+0xd4>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000450e:	00000097          	auipc	ra,0x0
    80004512:	c72080e7          	jalr	-910(ra) # 80004180 <write_head>
    install_trans(); // Now install writes to home locations
    80004516:	00000097          	auipc	ra,0x0
    8000451a:	ce4080e7          	jalr	-796(ra) # 800041fa <install_trans>
    log.lh.n = 0;
    8000451e:	0005d797          	auipc	a5,0x5d
    80004522:	4007ab23          	sw	zero,1046(a5) # 80061934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004526:	00000097          	auipc	ra,0x0
    8000452a:	c5a080e7          	jalr	-934(ra) # 80004180 <write_head>
    8000452e:	b701                	j	8000442e <end_op+0x5a>

0000000080004530 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004530:	1101                	addi	sp,sp,-32
    80004532:	ec06                	sd	ra,24(sp)
    80004534:	e822                	sd	s0,16(sp)
    80004536:	e426                	sd	s1,8(sp)
    80004538:	e04a                	sd	s2,0(sp)
    8000453a:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000453c:	0005d797          	auipc	a5,0x5d
    80004540:	3cc78793          	addi	a5,a5,972 # 80061908 <log>
    80004544:	57d8                	lw	a4,44(a5)
    80004546:	47f5                	li	a5,29
    80004548:	08e7c563          	blt	a5,a4,800045d2 <log_write+0xa2>
    8000454c:	892a                	mv	s2,a0
    8000454e:	0005d797          	auipc	a5,0x5d
    80004552:	3ba78793          	addi	a5,a5,954 # 80061908 <log>
    80004556:	4fdc                	lw	a5,28(a5)
    80004558:	37fd                	addiw	a5,a5,-1
    8000455a:	06f75c63          	ble	a5,a4,800045d2 <log_write+0xa2>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000455e:	0005d797          	auipc	a5,0x5d
    80004562:	3aa78793          	addi	a5,a5,938 # 80061908 <log>
    80004566:	539c                	lw	a5,32(a5)
    80004568:	06f05d63          	blez	a5,800045e2 <log_write+0xb2>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000456c:	0005d497          	auipc	s1,0x5d
    80004570:	39c48493          	addi	s1,s1,924 # 80061908 <log>
    80004574:	8526                	mv	a0,s1
    80004576:	ffffd097          	auipc	ra,0xffffd
    8000457a:	82c080e7          	jalr	-2004(ra) # 80000da2 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000457e:	54d0                	lw	a2,44(s1)
    80004580:	0ac05063          	blez	a2,80004620 <log_write+0xf0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004584:	00c92583          	lw	a1,12(s2)
    80004588:	589c                	lw	a5,48(s1)
    8000458a:	0ab78363          	beq	a5,a1,80004630 <log_write+0x100>
    8000458e:	0005d717          	auipc	a4,0x5d
    80004592:	3ae70713          	addi	a4,a4,942 # 8006193c <log+0x34>
  for (i = 0; i < log.lh.n; i++) {
    80004596:	4781                	li	a5,0
    80004598:	2785                	addiw	a5,a5,1
    8000459a:	04c78c63          	beq	a5,a2,800045f2 <log_write+0xc2>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000459e:	4314                	lw	a3,0(a4)
    800045a0:	0711                	addi	a4,a4,4
    800045a2:	feb69be3          	bne	a3,a1,80004598 <log_write+0x68>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045a6:	07a1                	addi	a5,a5,8
    800045a8:	078a                	slli	a5,a5,0x2
    800045aa:	0005d717          	auipc	a4,0x5d
    800045ae:	35e70713          	addi	a4,a4,862 # 80061908 <log>
    800045b2:	97ba                	add	a5,a5,a4
    800045b4:	cb8c                	sw	a1,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    log.lh.n++;
  }
  release(&log.lock);
    800045b6:	0005d517          	auipc	a0,0x5d
    800045ba:	35250513          	addi	a0,a0,850 # 80061908 <log>
    800045be:	ffffd097          	auipc	ra,0xffffd
    800045c2:	898080e7          	jalr	-1896(ra) # 80000e56 <release>
}
    800045c6:	60e2                	ld	ra,24(sp)
    800045c8:	6442                	ld	s0,16(sp)
    800045ca:	64a2                	ld	s1,8(sp)
    800045cc:	6902                	ld	s2,0(sp)
    800045ce:	6105                	addi	sp,sp,32
    800045d0:	8082                	ret
    panic("too big a transaction");
    800045d2:	00004517          	auipc	a0,0x4
    800045d6:	05e50513          	addi	a0,a0,94 # 80008630 <syscalls+0x218>
    800045da:	ffffc097          	auipc	ra,0xffffc
    800045de:	f9a080e7          	jalr	-102(ra) # 80000574 <panic>
    panic("log_write outside of trans");
    800045e2:	00004517          	auipc	a0,0x4
    800045e6:	06650513          	addi	a0,a0,102 # 80008648 <syscalls+0x230>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	f8a080e7          	jalr	-118(ra) # 80000574 <panic>
  log.lh.block[i] = b->blockno;
    800045f2:	0621                	addi	a2,a2,8
    800045f4:	060a                	slli	a2,a2,0x2
    800045f6:	0005d797          	auipc	a5,0x5d
    800045fa:	31278793          	addi	a5,a5,786 # 80061908 <log>
    800045fe:	963e                	add	a2,a2,a5
    80004600:	00c92783          	lw	a5,12(s2)
    80004604:	ca1c                	sw	a5,16(a2)
    bpin(b);
    80004606:	854a                	mv	a0,s2
    80004608:	fffff097          	auipc	ra,0xfffff
    8000460c:	d18080e7          	jalr	-744(ra) # 80003320 <bpin>
    log.lh.n++;
    80004610:	0005d717          	auipc	a4,0x5d
    80004614:	2f870713          	addi	a4,a4,760 # 80061908 <log>
    80004618:	575c                	lw	a5,44(a4)
    8000461a:	2785                	addiw	a5,a5,1
    8000461c:	d75c                	sw	a5,44(a4)
    8000461e:	bf61                	j	800045b6 <log_write+0x86>
  log.lh.block[i] = b->blockno;
    80004620:	00c92783          	lw	a5,12(s2)
    80004624:	0005d717          	auipc	a4,0x5d
    80004628:	30f72a23          	sw	a5,788(a4) # 80061938 <log+0x30>
  if (i == log.lh.n) {  // Add new block to log?
    8000462c:	f649                	bnez	a2,800045b6 <log_write+0x86>
    8000462e:	bfe1                	j	80004606 <log_write+0xd6>
  for (i = 0; i < log.lh.n; i++) {
    80004630:	4781                	li	a5,0
    80004632:	bf95                	j	800045a6 <log_write+0x76>

0000000080004634 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004634:	1101                	addi	sp,sp,-32
    80004636:	ec06                	sd	ra,24(sp)
    80004638:	e822                	sd	s0,16(sp)
    8000463a:	e426                	sd	s1,8(sp)
    8000463c:	e04a                	sd	s2,0(sp)
    8000463e:	1000                	addi	s0,sp,32
    80004640:	84aa                	mv	s1,a0
    80004642:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004644:	00004597          	auipc	a1,0x4
    80004648:	02458593          	addi	a1,a1,36 # 80008668 <syscalls+0x250>
    8000464c:	0521                	addi	a0,a0,8
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	6c4080e7          	jalr	1732(ra) # 80000d12 <initlock>
  lk->name = name;
    80004656:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000465a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000465e:	0204a423          	sw	zero,40(s1)
}
    80004662:	60e2                	ld	ra,24(sp)
    80004664:	6442                	ld	s0,16(sp)
    80004666:	64a2                	ld	s1,8(sp)
    80004668:	6902                	ld	s2,0(sp)
    8000466a:	6105                	addi	sp,sp,32
    8000466c:	8082                	ret

000000008000466e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000466e:	1101                	addi	sp,sp,-32
    80004670:	ec06                	sd	ra,24(sp)
    80004672:	e822                	sd	s0,16(sp)
    80004674:	e426                	sd	s1,8(sp)
    80004676:	e04a                	sd	s2,0(sp)
    80004678:	1000                	addi	s0,sp,32
    8000467a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000467c:	00850913          	addi	s2,a0,8
    80004680:	854a                	mv	a0,s2
    80004682:	ffffc097          	auipc	ra,0xffffc
    80004686:	720080e7          	jalr	1824(ra) # 80000da2 <acquire>
  while (lk->locked) {
    8000468a:	409c                	lw	a5,0(s1)
    8000468c:	cb89                	beqz	a5,8000469e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000468e:	85ca                	mv	a1,s2
    80004690:	8526                	mv	a0,s1
    80004692:	ffffe097          	auipc	ra,0xffffe
    80004696:	e54080e7          	jalr	-428(ra) # 800024e6 <sleep>
  while (lk->locked) {
    8000469a:	409c                	lw	a5,0(s1)
    8000469c:	fbed                	bnez	a5,8000468e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000469e:	4785                	li	a5,1
    800046a0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046a2:	ffffd097          	auipc	ra,0xffffd
    800046a6:	62a080e7          	jalr	1578(ra) # 80001ccc <myproc>
    800046aa:	5d1c                	lw	a5,56(a0)
    800046ac:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046ae:	854a                	mv	a0,s2
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	7a6080e7          	jalr	1958(ra) # 80000e56 <release>
}
    800046b8:	60e2                	ld	ra,24(sp)
    800046ba:	6442                	ld	s0,16(sp)
    800046bc:	64a2                	ld	s1,8(sp)
    800046be:	6902                	ld	s2,0(sp)
    800046c0:	6105                	addi	sp,sp,32
    800046c2:	8082                	ret

00000000800046c4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046c4:	1101                	addi	sp,sp,-32
    800046c6:	ec06                	sd	ra,24(sp)
    800046c8:	e822                	sd	s0,16(sp)
    800046ca:	e426                	sd	s1,8(sp)
    800046cc:	e04a                	sd	s2,0(sp)
    800046ce:	1000                	addi	s0,sp,32
    800046d0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046d2:	00850913          	addi	s2,a0,8
    800046d6:	854a                	mv	a0,s2
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	6ca080e7          	jalr	1738(ra) # 80000da2 <acquire>
  lk->locked = 0;
    800046e0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046e4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046e8:	8526                	mv	a0,s1
    800046ea:	ffffe097          	auipc	ra,0xffffe
    800046ee:	f82080e7          	jalr	-126(ra) # 8000266c <wakeup>
  release(&lk->lk);
    800046f2:	854a                	mv	a0,s2
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	762080e7          	jalr	1890(ra) # 80000e56 <release>
}
    800046fc:	60e2                	ld	ra,24(sp)
    800046fe:	6442                	ld	s0,16(sp)
    80004700:	64a2                	ld	s1,8(sp)
    80004702:	6902                	ld	s2,0(sp)
    80004704:	6105                	addi	sp,sp,32
    80004706:	8082                	ret

0000000080004708 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004708:	7179                	addi	sp,sp,-48
    8000470a:	f406                	sd	ra,40(sp)
    8000470c:	f022                	sd	s0,32(sp)
    8000470e:	ec26                	sd	s1,24(sp)
    80004710:	e84a                	sd	s2,16(sp)
    80004712:	e44e                	sd	s3,8(sp)
    80004714:	1800                	addi	s0,sp,48
    80004716:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004718:	00850913          	addi	s2,a0,8
    8000471c:	854a                	mv	a0,s2
    8000471e:	ffffc097          	auipc	ra,0xffffc
    80004722:	684080e7          	jalr	1668(ra) # 80000da2 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004726:	409c                	lw	a5,0(s1)
    80004728:	ef99                	bnez	a5,80004746 <holdingsleep+0x3e>
    8000472a:	4481                	li	s1,0
  release(&lk->lk);
    8000472c:	854a                	mv	a0,s2
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	728080e7          	jalr	1832(ra) # 80000e56 <release>
  return r;
}
    80004736:	8526                	mv	a0,s1
    80004738:	70a2                	ld	ra,40(sp)
    8000473a:	7402                	ld	s0,32(sp)
    8000473c:	64e2                	ld	s1,24(sp)
    8000473e:	6942                	ld	s2,16(sp)
    80004740:	69a2                	ld	s3,8(sp)
    80004742:	6145                	addi	sp,sp,48
    80004744:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004746:	0284a983          	lw	s3,40(s1)
    8000474a:	ffffd097          	auipc	ra,0xffffd
    8000474e:	582080e7          	jalr	1410(ra) # 80001ccc <myproc>
    80004752:	5d04                	lw	s1,56(a0)
    80004754:	413484b3          	sub	s1,s1,s3
    80004758:	0014b493          	seqz	s1,s1
    8000475c:	bfc1                	j	8000472c <holdingsleep+0x24>

000000008000475e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000475e:	1141                	addi	sp,sp,-16
    80004760:	e406                	sd	ra,8(sp)
    80004762:	e022                	sd	s0,0(sp)
    80004764:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004766:	00004597          	auipc	a1,0x4
    8000476a:	f1258593          	addi	a1,a1,-238 # 80008678 <syscalls+0x260>
    8000476e:	0005d517          	auipc	a0,0x5d
    80004772:	2e250513          	addi	a0,a0,738 # 80061a50 <ftable>
    80004776:	ffffc097          	auipc	ra,0xffffc
    8000477a:	59c080e7          	jalr	1436(ra) # 80000d12 <initlock>
}
    8000477e:	60a2                	ld	ra,8(sp)
    80004780:	6402                	ld	s0,0(sp)
    80004782:	0141                	addi	sp,sp,16
    80004784:	8082                	ret

0000000080004786 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004786:	1101                	addi	sp,sp,-32
    80004788:	ec06                	sd	ra,24(sp)
    8000478a:	e822                	sd	s0,16(sp)
    8000478c:	e426                	sd	s1,8(sp)
    8000478e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004790:	0005d517          	auipc	a0,0x5d
    80004794:	2c050513          	addi	a0,a0,704 # 80061a50 <ftable>
    80004798:	ffffc097          	auipc	ra,0xffffc
    8000479c:	60a080e7          	jalr	1546(ra) # 80000da2 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
    800047a0:	0005d797          	auipc	a5,0x5d
    800047a4:	2b078793          	addi	a5,a5,688 # 80061a50 <ftable>
    800047a8:	4fdc                	lw	a5,28(a5)
    800047aa:	cb8d                	beqz	a5,800047dc <filealloc+0x56>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047ac:	0005d497          	auipc	s1,0x5d
    800047b0:	2e448493          	addi	s1,s1,740 # 80061a90 <ftable+0x40>
    800047b4:	0005e717          	auipc	a4,0x5e
    800047b8:	25470713          	addi	a4,a4,596 # 80062a08 <ftable+0xfb8>
    if(f->ref == 0){
    800047bc:	40dc                	lw	a5,4(s1)
    800047be:	c39d                	beqz	a5,800047e4 <filealloc+0x5e>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047c0:	02848493          	addi	s1,s1,40
    800047c4:	fee49ce3          	bne	s1,a4,800047bc <filealloc+0x36>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047c8:	0005d517          	auipc	a0,0x5d
    800047cc:	28850513          	addi	a0,a0,648 # 80061a50 <ftable>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	686080e7          	jalr	1670(ra) # 80000e56 <release>
  return 0;
    800047d8:	4481                	li	s1,0
    800047da:	a839                	j	800047f8 <filealloc+0x72>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047dc:	0005d497          	auipc	s1,0x5d
    800047e0:	28c48493          	addi	s1,s1,652 # 80061a68 <ftable+0x18>
      f->ref = 1;
    800047e4:	4785                	li	a5,1
    800047e6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047e8:	0005d517          	auipc	a0,0x5d
    800047ec:	26850513          	addi	a0,a0,616 # 80061a50 <ftable>
    800047f0:	ffffc097          	auipc	ra,0xffffc
    800047f4:	666080e7          	jalr	1638(ra) # 80000e56 <release>
}
    800047f8:	8526                	mv	a0,s1
    800047fa:	60e2                	ld	ra,24(sp)
    800047fc:	6442                	ld	s0,16(sp)
    800047fe:	64a2                	ld	s1,8(sp)
    80004800:	6105                	addi	sp,sp,32
    80004802:	8082                	ret

0000000080004804 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004804:	1101                	addi	sp,sp,-32
    80004806:	ec06                	sd	ra,24(sp)
    80004808:	e822                	sd	s0,16(sp)
    8000480a:	e426                	sd	s1,8(sp)
    8000480c:	1000                	addi	s0,sp,32
    8000480e:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004810:	0005d517          	auipc	a0,0x5d
    80004814:	24050513          	addi	a0,a0,576 # 80061a50 <ftable>
    80004818:	ffffc097          	auipc	ra,0xffffc
    8000481c:	58a080e7          	jalr	1418(ra) # 80000da2 <acquire>
  if(f->ref < 1)
    80004820:	40dc                	lw	a5,4(s1)
    80004822:	02f05263          	blez	a5,80004846 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004826:	2785                	addiw	a5,a5,1
    80004828:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000482a:	0005d517          	auipc	a0,0x5d
    8000482e:	22650513          	addi	a0,a0,550 # 80061a50 <ftable>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	624080e7          	jalr	1572(ra) # 80000e56 <release>
  return f;
}
    8000483a:	8526                	mv	a0,s1
    8000483c:	60e2                	ld	ra,24(sp)
    8000483e:	6442                	ld	s0,16(sp)
    80004840:	64a2                	ld	s1,8(sp)
    80004842:	6105                	addi	sp,sp,32
    80004844:	8082                	ret
    panic("filedup");
    80004846:	00004517          	auipc	a0,0x4
    8000484a:	e3a50513          	addi	a0,a0,-454 # 80008680 <syscalls+0x268>
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	d26080e7          	jalr	-730(ra) # 80000574 <panic>

0000000080004856 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004856:	7139                	addi	sp,sp,-64
    80004858:	fc06                	sd	ra,56(sp)
    8000485a:	f822                	sd	s0,48(sp)
    8000485c:	f426                	sd	s1,40(sp)
    8000485e:	f04a                	sd	s2,32(sp)
    80004860:	ec4e                	sd	s3,24(sp)
    80004862:	e852                	sd	s4,16(sp)
    80004864:	e456                	sd	s5,8(sp)
    80004866:	0080                	addi	s0,sp,64
    80004868:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000486a:	0005d517          	auipc	a0,0x5d
    8000486e:	1e650513          	addi	a0,a0,486 # 80061a50 <ftable>
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	530080e7          	jalr	1328(ra) # 80000da2 <acquire>
  if(f->ref < 1)
    8000487a:	40dc                	lw	a5,4(s1)
    8000487c:	06f05163          	blez	a5,800048de <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004880:	37fd                	addiw	a5,a5,-1
    80004882:	0007871b          	sext.w	a4,a5
    80004886:	c0dc                	sw	a5,4(s1)
    80004888:	06e04363          	bgtz	a4,800048ee <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000488c:	0004a903          	lw	s2,0(s1)
    80004890:	0094ca83          	lbu	s5,9(s1)
    80004894:	0104ba03          	ld	s4,16(s1)
    80004898:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000489c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048a0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048a4:	0005d517          	auipc	a0,0x5d
    800048a8:	1ac50513          	addi	a0,a0,428 # 80061a50 <ftable>
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	5aa080e7          	jalr	1450(ra) # 80000e56 <release>

  if(ff.type == FD_PIPE){
    800048b4:	4785                	li	a5,1
    800048b6:	04f90d63          	beq	s2,a5,80004910 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048ba:	3979                	addiw	s2,s2,-2
    800048bc:	4785                	li	a5,1
    800048be:	0527e063          	bltu	a5,s2,800048fe <fileclose+0xa8>
    begin_op();
    800048c2:	00000097          	auipc	ra,0x0
    800048c6:	a92080e7          	jalr	-1390(ra) # 80004354 <begin_op>
    iput(ff.ip);
    800048ca:	854e                	mv	a0,s3
    800048cc:	fffff097          	auipc	ra,0xfffff
    800048d0:	278080e7          	jalr	632(ra) # 80003b44 <iput>
    end_op();
    800048d4:	00000097          	auipc	ra,0x0
    800048d8:	b00080e7          	jalr	-1280(ra) # 800043d4 <end_op>
    800048dc:	a00d                	j	800048fe <fileclose+0xa8>
    panic("fileclose");
    800048de:	00004517          	auipc	a0,0x4
    800048e2:	daa50513          	addi	a0,a0,-598 # 80008688 <syscalls+0x270>
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	c8e080e7          	jalr	-882(ra) # 80000574 <panic>
    release(&ftable.lock);
    800048ee:	0005d517          	auipc	a0,0x5d
    800048f2:	16250513          	addi	a0,a0,354 # 80061a50 <ftable>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	560080e7          	jalr	1376(ra) # 80000e56 <release>
  }
}
    800048fe:	70e2                	ld	ra,56(sp)
    80004900:	7442                	ld	s0,48(sp)
    80004902:	74a2                	ld	s1,40(sp)
    80004904:	7902                	ld	s2,32(sp)
    80004906:	69e2                	ld	s3,24(sp)
    80004908:	6a42                	ld	s4,16(sp)
    8000490a:	6aa2                	ld	s5,8(sp)
    8000490c:	6121                	addi	sp,sp,64
    8000490e:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004910:	85d6                	mv	a1,s5
    80004912:	8552                	mv	a0,s4
    80004914:	00000097          	auipc	ra,0x0
    80004918:	364080e7          	jalr	868(ra) # 80004c78 <pipeclose>
    8000491c:	b7cd                	j	800048fe <fileclose+0xa8>

000000008000491e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000491e:	715d                	addi	sp,sp,-80
    80004920:	e486                	sd	ra,72(sp)
    80004922:	e0a2                	sd	s0,64(sp)
    80004924:	fc26                	sd	s1,56(sp)
    80004926:	f84a                	sd	s2,48(sp)
    80004928:	f44e                	sd	s3,40(sp)
    8000492a:	0880                	addi	s0,sp,80
    8000492c:	84aa                	mv	s1,a0
    8000492e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004930:	ffffd097          	auipc	ra,0xffffd
    80004934:	39c080e7          	jalr	924(ra) # 80001ccc <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004938:	409c                	lw	a5,0(s1)
    8000493a:	37f9                	addiw	a5,a5,-2
    8000493c:	4705                	li	a4,1
    8000493e:	04f76763          	bltu	a4,a5,8000498c <filestat+0x6e>
    80004942:	892a                	mv	s2,a0
    ilock(f->ip);
    80004944:	6c88                	ld	a0,24(s1)
    80004946:	fffff097          	auipc	ra,0xfffff
    8000494a:	042080e7          	jalr	66(ra) # 80003988 <ilock>
    stati(f->ip, &st);
    8000494e:	fb840593          	addi	a1,s0,-72
    80004952:	6c88                	ld	a0,24(s1)
    80004954:	fffff097          	auipc	ra,0xfffff
    80004958:	2c0080e7          	jalr	704(ra) # 80003c14 <stati>
    iunlock(f->ip);
    8000495c:	6c88                	ld	a0,24(s1)
    8000495e:	fffff097          	auipc	ra,0xfffff
    80004962:	0ee080e7          	jalr	238(ra) # 80003a4c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004966:	46e1                	li	a3,24
    80004968:	fb840613          	addi	a2,s0,-72
    8000496c:	85ce                	mv	a1,s3
    8000496e:	05093503          	ld	a0,80(s2)
    80004972:	ffffd097          	auipc	ra,0xffffd
    80004976:	14e080e7          	jalr	334(ra) # 80001ac0 <copyout>
    8000497a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000497e:	60a6                	ld	ra,72(sp)
    80004980:	6406                	ld	s0,64(sp)
    80004982:	74e2                	ld	s1,56(sp)
    80004984:	7942                	ld	s2,48(sp)
    80004986:	79a2                	ld	s3,40(sp)
    80004988:	6161                	addi	sp,sp,80
    8000498a:	8082                	ret
  return -1;
    8000498c:	557d                	li	a0,-1
    8000498e:	bfc5                	j	8000497e <filestat+0x60>

0000000080004990 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004990:	7179                	addi	sp,sp,-48
    80004992:	f406                	sd	ra,40(sp)
    80004994:	f022                	sd	s0,32(sp)
    80004996:	ec26                	sd	s1,24(sp)
    80004998:	e84a                	sd	s2,16(sp)
    8000499a:	e44e                	sd	s3,8(sp)
    8000499c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000499e:	00854783          	lbu	a5,8(a0)
    800049a2:	c3d5                	beqz	a5,80004a46 <fileread+0xb6>
    800049a4:	89b2                	mv	s3,a2
    800049a6:	892e                	mv	s2,a1
    800049a8:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    800049aa:	411c                	lw	a5,0(a0)
    800049ac:	4705                	li	a4,1
    800049ae:	04e78963          	beq	a5,a4,80004a00 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049b2:	470d                	li	a4,3
    800049b4:	04e78d63          	beq	a5,a4,80004a0e <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049b8:	4709                	li	a4,2
    800049ba:	06e79e63          	bne	a5,a4,80004a36 <fileread+0xa6>
    ilock(f->ip);
    800049be:	6d08                	ld	a0,24(a0)
    800049c0:	fffff097          	auipc	ra,0xfffff
    800049c4:	fc8080e7          	jalr	-56(ra) # 80003988 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049c8:	874e                	mv	a4,s3
    800049ca:	5094                	lw	a3,32(s1)
    800049cc:	864a                	mv	a2,s2
    800049ce:	4585                	li	a1,1
    800049d0:	6c88                	ld	a0,24(s1)
    800049d2:	fffff097          	auipc	ra,0xfffff
    800049d6:	26c080e7          	jalr	620(ra) # 80003c3e <readi>
    800049da:	892a                	mv	s2,a0
    800049dc:	00a05563          	blez	a0,800049e6 <fileread+0x56>
      f->off += r;
    800049e0:	509c                	lw	a5,32(s1)
    800049e2:	9fa9                	addw	a5,a5,a0
    800049e4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049e6:	6c88                	ld	a0,24(s1)
    800049e8:	fffff097          	auipc	ra,0xfffff
    800049ec:	064080e7          	jalr	100(ra) # 80003a4c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049f0:	854a                	mv	a0,s2
    800049f2:	70a2                	ld	ra,40(sp)
    800049f4:	7402                	ld	s0,32(sp)
    800049f6:	64e2                	ld	s1,24(sp)
    800049f8:	6942                	ld	s2,16(sp)
    800049fa:	69a2                	ld	s3,8(sp)
    800049fc:	6145                	addi	sp,sp,48
    800049fe:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a00:	6908                	ld	a0,16(a0)
    80004a02:	00000097          	auipc	ra,0x0
    80004a06:	416080e7          	jalr	1046(ra) # 80004e18 <piperead>
    80004a0a:	892a                	mv	s2,a0
    80004a0c:	b7d5                	j	800049f0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a0e:	02451783          	lh	a5,36(a0)
    80004a12:	03079693          	slli	a3,a5,0x30
    80004a16:	92c1                	srli	a3,a3,0x30
    80004a18:	4725                	li	a4,9
    80004a1a:	02d76863          	bltu	a4,a3,80004a4a <fileread+0xba>
    80004a1e:	0792                	slli	a5,a5,0x4
    80004a20:	0005d717          	auipc	a4,0x5d
    80004a24:	f9070713          	addi	a4,a4,-112 # 800619b0 <devsw>
    80004a28:	97ba                	add	a5,a5,a4
    80004a2a:	639c                	ld	a5,0(a5)
    80004a2c:	c38d                	beqz	a5,80004a4e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a2e:	4505                	li	a0,1
    80004a30:	9782                	jalr	a5
    80004a32:	892a                	mv	s2,a0
    80004a34:	bf75                	j	800049f0 <fileread+0x60>
    panic("fileread");
    80004a36:	00004517          	auipc	a0,0x4
    80004a3a:	c6250513          	addi	a0,a0,-926 # 80008698 <syscalls+0x280>
    80004a3e:	ffffc097          	auipc	ra,0xffffc
    80004a42:	b36080e7          	jalr	-1226(ra) # 80000574 <panic>
    return -1;
    80004a46:	597d                	li	s2,-1
    80004a48:	b765                	j	800049f0 <fileread+0x60>
      return -1;
    80004a4a:	597d                	li	s2,-1
    80004a4c:	b755                	j	800049f0 <fileread+0x60>
    80004a4e:	597d                	li	s2,-1
    80004a50:	b745                	j	800049f0 <fileread+0x60>

0000000080004a52 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a52:	00954783          	lbu	a5,9(a0)
    80004a56:	12078e63          	beqz	a5,80004b92 <filewrite+0x140>
{
    80004a5a:	715d                	addi	sp,sp,-80
    80004a5c:	e486                	sd	ra,72(sp)
    80004a5e:	e0a2                	sd	s0,64(sp)
    80004a60:	fc26                	sd	s1,56(sp)
    80004a62:	f84a                	sd	s2,48(sp)
    80004a64:	f44e                	sd	s3,40(sp)
    80004a66:	f052                	sd	s4,32(sp)
    80004a68:	ec56                	sd	s5,24(sp)
    80004a6a:	e85a                	sd	s6,16(sp)
    80004a6c:	e45e                	sd	s7,8(sp)
    80004a6e:	e062                	sd	s8,0(sp)
    80004a70:	0880                	addi	s0,sp,80
    80004a72:	8ab2                	mv	s5,a2
    80004a74:	8b2e                	mv	s6,a1
    80004a76:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    80004a78:	411c                	lw	a5,0(a0)
    80004a7a:	4705                	li	a4,1
    80004a7c:	02e78263          	beq	a5,a4,80004aa0 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a80:	470d                	li	a4,3
    80004a82:	02e78563          	beq	a5,a4,80004aac <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a86:	4709                	li	a4,2
    80004a88:	0ee79d63          	bne	a5,a4,80004b82 <filewrite+0x130>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a8c:	0ec05763          	blez	a2,80004b7a <filewrite+0x128>
    int i = 0;
    80004a90:	4901                	li	s2,0
    80004a92:	6b85                	lui	s7,0x1
    80004a94:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004a98:	6c05                	lui	s8,0x1
    80004a9a:	c00c0c1b          	addiw	s8,s8,-1024
    80004a9e:	a061                	j	80004b26 <filewrite+0xd4>
    ret = pipewrite(f->pipe, addr, n);
    80004aa0:	6908                	ld	a0,16(a0)
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	246080e7          	jalr	582(ra) # 80004ce8 <pipewrite>
    80004aaa:	a065                	j	80004b52 <filewrite+0x100>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004aac:	02451783          	lh	a5,36(a0)
    80004ab0:	03079693          	slli	a3,a5,0x30
    80004ab4:	92c1                	srli	a3,a3,0x30
    80004ab6:	4725                	li	a4,9
    80004ab8:	0cd76f63          	bltu	a4,a3,80004b96 <filewrite+0x144>
    80004abc:	0792                	slli	a5,a5,0x4
    80004abe:	0005d717          	auipc	a4,0x5d
    80004ac2:	ef270713          	addi	a4,a4,-270 # 800619b0 <devsw>
    80004ac6:	97ba                	add	a5,a5,a4
    80004ac8:	679c                	ld	a5,8(a5)
    80004aca:	cbe1                	beqz	a5,80004b9a <filewrite+0x148>
    ret = devsw[f->major].write(1, addr, n);
    80004acc:	4505                	li	a0,1
    80004ace:	9782                	jalr	a5
    80004ad0:	a049                	j	80004b52 <filewrite+0x100>
    80004ad2:	00098a1b          	sext.w	s4,s3
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ad6:	00000097          	auipc	ra,0x0
    80004ada:	87e080e7          	jalr	-1922(ra) # 80004354 <begin_op>
      ilock(f->ip);
    80004ade:	6c88                	ld	a0,24(s1)
    80004ae0:	fffff097          	auipc	ra,0xfffff
    80004ae4:	ea8080e7          	jalr	-344(ra) # 80003988 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ae8:	8752                	mv	a4,s4
    80004aea:	5094                	lw	a3,32(s1)
    80004aec:	01690633          	add	a2,s2,s6
    80004af0:	4585                	li	a1,1
    80004af2:	6c88                	ld	a0,24(s1)
    80004af4:	fffff097          	auipc	ra,0xfffff
    80004af8:	242080e7          	jalr	578(ra) # 80003d36 <writei>
    80004afc:	89aa                	mv	s3,a0
    80004afe:	02a05c63          	blez	a0,80004b36 <filewrite+0xe4>
        f->off += r;
    80004b02:	509c                	lw	a5,32(s1)
    80004b04:	9fa9                	addw	a5,a5,a0
    80004b06:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    80004b08:	6c88                	ld	a0,24(s1)
    80004b0a:	fffff097          	auipc	ra,0xfffff
    80004b0e:	f42080e7          	jalr	-190(ra) # 80003a4c <iunlock>
      end_op();
    80004b12:	00000097          	auipc	ra,0x0
    80004b16:	8c2080e7          	jalr	-1854(ra) # 800043d4 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004b1a:	05499863          	bne	s3,s4,80004b6a <filewrite+0x118>
        panic("short filewrite");
      i += r;
    80004b1e:	012a093b          	addw	s2,s4,s2
    while(i < n){
    80004b22:	03595563          	ble	s5,s2,80004b4c <filewrite+0xfa>
      int n1 = n - i;
    80004b26:	412a87bb          	subw	a5,s5,s2
      if(n1 > max)
    80004b2a:	89be                	mv	s3,a5
    80004b2c:	2781                	sext.w	a5,a5
    80004b2e:	fafbd2e3          	ble	a5,s7,80004ad2 <filewrite+0x80>
    80004b32:	89e2                	mv	s3,s8
    80004b34:	bf79                	j	80004ad2 <filewrite+0x80>
      iunlock(f->ip);
    80004b36:	6c88                	ld	a0,24(s1)
    80004b38:	fffff097          	auipc	ra,0xfffff
    80004b3c:	f14080e7          	jalr	-236(ra) # 80003a4c <iunlock>
      end_op();
    80004b40:	00000097          	auipc	ra,0x0
    80004b44:	894080e7          	jalr	-1900(ra) # 800043d4 <end_op>
      if(r < 0)
    80004b48:	fc09d9e3          	bgez	s3,80004b1a <filewrite+0xc8>
    }
    ret = (i == n ? n : -1);
    80004b4c:	8556                	mv	a0,s5
    80004b4e:	032a9863          	bne	s5,s2,80004b7e <filewrite+0x12c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b52:	60a6                	ld	ra,72(sp)
    80004b54:	6406                	ld	s0,64(sp)
    80004b56:	74e2                	ld	s1,56(sp)
    80004b58:	7942                	ld	s2,48(sp)
    80004b5a:	79a2                	ld	s3,40(sp)
    80004b5c:	7a02                	ld	s4,32(sp)
    80004b5e:	6ae2                	ld	s5,24(sp)
    80004b60:	6b42                	ld	s6,16(sp)
    80004b62:	6ba2                	ld	s7,8(sp)
    80004b64:	6c02                	ld	s8,0(sp)
    80004b66:	6161                	addi	sp,sp,80
    80004b68:	8082                	ret
        panic("short filewrite");
    80004b6a:	00004517          	auipc	a0,0x4
    80004b6e:	b3e50513          	addi	a0,a0,-1218 # 800086a8 <syscalls+0x290>
    80004b72:	ffffc097          	auipc	ra,0xffffc
    80004b76:	a02080e7          	jalr	-1534(ra) # 80000574 <panic>
    int i = 0;
    80004b7a:	4901                	li	s2,0
    80004b7c:	bfc1                	j	80004b4c <filewrite+0xfa>
    ret = (i == n ? n : -1);
    80004b7e:	557d                	li	a0,-1
    80004b80:	bfc9                	j	80004b52 <filewrite+0x100>
    panic("filewrite");
    80004b82:	00004517          	auipc	a0,0x4
    80004b86:	b3650513          	addi	a0,a0,-1226 # 800086b8 <syscalls+0x2a0>
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	9ea080e7          	jalr	-1558(ra) # 80000574 <panic>
    return -1;
    80004b92:	557d                	li	a0,-1
}
    80004b94:	8082                	ret
      return -1;
    80004b96:	557d                	li	a0,-1
    80004b98:	bf6d                	j	80004b52 <filewrite+0x100>
    80004b9a:	557d                	li	a0,-1
    80004b9c:	bf5d                	j	80004b52 <filewrite+0x100>

0000000080004b9e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b9e:	7179                	addi	sp,sp,-48
    80004ba0:	f406                	sd	ra,40(sp)
    80004ba2:	f022                	sd	s0,32(sp)
    80004ba4:	ec26                	sd	s1,24(sp)
    80004ba6:	e84a                	sd	s2,16(sp)
    80004ba8:	e44e                	sd	s3,8(sp)
    80004baa:	e052                	sd	s4,0(sp)
    80004bac:	1800                	addi	s0,sp,48
    80004bae:	84aa                	mv	s1,a0
    80004bb0:	892e                	mv	s2,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bb2:	0005b023          	sd	zero,0(a1)
    80004bb6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bba:	00000097          	auipc	ra,0x0
    80004bbe:	bcc080e7          	jalr	-1076(ra) # 80004786 <filealloc>
    80004bc2:	e088                	sd	a0,0(s1)
    80004bc4:	c551                	beqz	a0,80004c50 <pipealloc+0xb2>
    80004bc6:	00000097          	auipc	ra,0x0
    80004bca:	bc0080e7          	jalr	-1088(ra) # 80004786 <filealloc>
    80004bce:	00a93023          	sd	a0,0(s2)
    80004bd2:	c92d                	beqz	a0,80004c44 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	004080e7          	jalr	4(ra) # 80000bd8 <kalloc>
    80004bdc:	89aa                	mv	s3,a0
    80004bde:	c125                	beqz	a0,80004c3e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004be0:	4a05                	li	s4,1
    80004be2:	23452023          	sw	s4,544(a0)
  pi->writeopen = 1;
    80004be6:	23452223          	sw	s4,548(a0)
  pi->nwrite = 0;
    80004bea:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bee:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bf2:	00004597          	auipc	a1,0x4
    80004bf6:	ad658593          	addi	a1,a1,-1322 # 800086c8 <syscalls+0x2b0>
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	118080e7          	jalr	280(ra) # 80000d12 <initlock>
  (*f0)->type = FD_PIPE;
    80004c02:	609c                	ld	a5,0(s1)
    80004c04:	0147a023          	sw	s4,0(a5)
  (*f0)->readable = 1;
    80004c08:	609c                	ld	a5,0(s1)
    80004c0a:	01478423          	sb	s4,8(a5)
  (*f0)->writable = 0;
    80004c0e:	609c                	ld	a5,0(s1)
    80004c10:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c14:	609c                	ld	a5,0(s1)
    80004c16:	0137b823          	sd	s3,16(a5)
  (*f1)->type = FD_PIPE;
    80004c1a:	00093783          	ld	a5,0(s2)
    80004c1e:	0147a023          	sw	s4,0(a5)
  (*f1)->readable = 0;
    80004c22:	00093783          	ld	a5,0(s2)
    80004c26:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c2a:	00093783          	ld	a5,0(s2)
    80004c2e:	014784a3          	sb	s4,9(a5)
  (*f1)->pipe = pi;
    80004c32:	00093783          	ld	a5,0(s2)
    80004c36:	0137b823          	sd	s3,16(a5)
  return 0;
    80004c3a:	4501                	li	a0,0
    80004c3c:	a025                	j	80004c64 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c3e:	6088                	ld	a0,0(s1)
    80004c40:	e501                	bnez	a0,80004c48 <pipealloc+0xaa>
    80004c42:	a039                	j	80004c50 <pipealloc+0xb2>
    80004c44:	6088                	ld	a0,0(s1)
    80004c46:	c51d                	beqz	a0,80004c74 <pipealloc+0xd6>
    fileclose(*f0);
    80004c48:	00000097          	auipc	ra,0x0
    80004c4c:	c0e080e7          	jalr	-1010(ra) # 80004856 <fileclose>
  if(*f1)
    80004c50:	00093783          	ld	a5,0(s2)
    fileclose(*f1);
  return -1;
    80004c54:	557d                	li	a0,-1
  if(*f1)
    80004c56:	c799                	beqz	a5,80004c64 <pipealloc+0xc6>
    fileclose(*f1);
    80004c58:	853e                	mv	a0,a5
    80004c5a:	00000097          	auipc	ra,0x0
    80004c5e:	bfc080e7          	jalr	-1028(ra) # 80004856 <fileclose>
  return -1;
    80004c62:	557d                	li	a0,-1
}
    80004c64:	70a2                	ld	ra,40(sp)
    80004c66:	7402                	ld	s0,32(sp)
    80004c68:	64e2                	ld	s1,24(sp)
    80004c6a:	6942                	ld	s2,16(sp)
    80004c6c:	69a2                	ld	s3,8(sp)
    80004c6e:	6a02                	ld	s4,0(sp)
    80004c70:	6145                	addi	sp,sp,48
    80004c72:	8082                	ret
  return -1;
    80004c74:	557d                	li	a0,-1
    80004c76:	b7fd                	j	80004c64 <pipealloc+0xc6>

0000000080004c78 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c78:	1101                	addi	sp,sp,-32
    80004c7a:	ec06                	sd	ra,24(sp)
    80004c7c:	e822                	sd	s0,16(sp)
    80004c7e:	e426                	sd	s1,8(sp)
    80004c80:	e04a                	sd	s2,0(sp)
    80004c82:	1000                	addi	s0,sp,32
    80004c84:	84aa                	mv	s1,a0
    80004c86:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	11a080e7          	jalr	282(ra) # 80000da2 <acquire>
  if(writable){
    80004c90:	02090d63          	beqz	s2,80004cca <pipeclose+0x52>
    pi->writeopen = 0;
    80004c94:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c98:	21848513          	addi	a0,s1,536
    80004c9c:	ffffe097          	auipc	ra,0xffffe
    80004ca0:	9d0080e7          	jalr	-1584(ra) # 8000266c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ca4:	2204b783          	ld	a5,544(s1)
    80004ca8:	eb95                	bnez	a5,80004cdc <pipeclose+0x64>
    release(&pi->lock);
    80004caa:	8526                	mv	a0,s1
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	1aa080e7          	jalr	426(ra) # 80000e56 <release>
    kfree((char*)pi);
    80004cb4:	8526                	mv	a0,s1
    80004cb6:	ffffc097          	auipc	ra,0xffffc
    80004cba:	dbc080e7          	jalr	-580(ra) # 80000a72 <kfree>
  } else
    release(&pi->lock);
}
    80004cbe:	60e2                	ld	ra,24(sp)
    80004cc0:	6442                	ld	s0,16(sp)
    80004cc2:	64a2                	ld	s1,8(sp)
    80004cc4:	6902                	ld	s2,0(sp)
    80004cc6:	6105                	addi	sp,sp,32
    80004cc8:	8082                	ret
    pi->readopen = 0;
    80004cca:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cce:	21c48513          	addi	a0,s1,540
    80004cd2:	ffffe097          	auipc	ra,0xffffe
    80004cd6:	99a080e7          	jalr	-1638(ra) # 8000266c <wakeup>
    80004cda:	b7e9                	j	80004ca4 <pipeclose+0x2c>
    release(&pi->lock);
    80004cdc:	8526                	mv	a0,s1
    80004cde:	ffffc097          	auipc	ra,0xffffc
    80004ce2:	178080e7          	jalr	376(ra) # 80000e56 <release>
}
    80004ce6:	bfe1                	j	80004cbe <pipeclose+0x46>

0000000080004ce8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ce8:	7119                	addi	sp,sp,-128
    80004cea:	fc86                	sd	ra,120(sp)
    80004cec:	f8a2                	sd	s0,112(sp)
    80004cee:	f4a6                	sd	s1,104(sp)
    80004cf0:	f0ca                	sd	s2,96(sp)
    80004cf2:	ecce                	sd	s3,88(sp)
    80004cf4:	e8d2                	sd	s4,80(sp)
    80004cf6:	e4d6                	sd	s5,72(sp)
    80004cf8:	e0da                	sd	s6,64(sp)
    80004cfa:	fc5e                	sd	s7,56(sp)
    80004cfc:	f862                	sd	s8,48(sp)
    80004cfe:	f466                	sd	s9,40(sp)
    80004d00:	f06a                	sd	s10,32(sp)
    80004d02:	ec6e                	sd	s11,24(sp)
    80004d04:	0100                	addi	s0,sp,128
    80004d06:	84aa                	mv	s1,a0
    80004d08:	8d2e                	mv	s10,a1
    80004d0a:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	fc0080e7          	jalr	-64(ra) # 80001ccc <myproc>
    80004d14:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004d16:	8526                	mv	a0,s1
    80004d18:	ffffc097          	auipc	ra,0xffffc
    80004d1c:	08a080e7          	jalr	138(ra) # 80000da2 <acquire>
  for(i = 0; i < n; i++){
    80004d20:	0d605f63          	blez	s6,80004dfe <pipewrite+0x116>
    80004d24:	89a6                	mv	s3,s1
    80004d26:	3b7d                	addiw	s6,s6,-1
    80004d28:	1b02                	slli	s6,s6,0x20
    80004d2a:	020b5b13          	srli	s6,s6,0x20
    80004d2e:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004d30:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d34:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d38:	5dfd                	li	s11,-1
    80004d3a:	000b8c9b          	sext.w	s9,s7
    80004d3e:	8c66                	mv	s8,s9
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d40:	2184a783          	lw	a5,536(s1)
    80004d44:	21c4a703          	lw	a4,540(s1)
    80004d48:	2007879b          	addiw	a5,a5,512
    80004d4c:	06f71763          	bne	a4,a5,80004dba <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80004d50:	2204a783          	lw	a5,544(s1)
    80004d54:	cf8d                	beqz	a5,80004d8e <pipewrite+0xa6>
    80004d56:	03092783          	lw	a5,48(s2)
    80004d5a:	eb95                	bnez	a5,80004d8e <pipewrite+0xa6>
      wakeup(&pi->nread);
    80004d5c:	8556                	mv	a0,s5
    80004d5e:	ffffe097          	auipc	ra,0xffffe
    80004d62:	90e080e7          	jalr	-1778(ra) # 8000266c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d66:	85ce                	mv	a1,s3
    80004d68:	8552                	mv	a0,s4
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	77c080e7          	jalr	1916(ra) # 800024e6 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d72:	2184a783          	lw	a5,536(s1)
    80004d76:	21c4a703          	lw	a4,540(s1)
    80004d7a:	2007879b          	addiw	a5,a5,512
    80004d7e:	02f71e63          	bne	a4,a5,80004dba <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80004d82:	2204a783          	lw	a5,544(s1)
    80004d86:	c781                	beqz	a5,80004d8e <pipewrite+0xa6>
    80004d88:	03092783          	lw	a5,48(s2)
    80004d8c:	dbe1                	beqz	a5,80004d5c <pipewrite+0x74>
        release(&pi->lock);
    80004d8e:	8526                	mv	a0,s1
    80004d90:	ffffc097          	auipc	ra,0xffffc
    80004d94:	0c6080e7          	jalr	198(ra) # 80000e56 <release>
        return -1;
    80004d98:	5c7d                	li	s8,-1
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004d9a:	8562                	mv	a0,s8
    80004d9c:	70e6                	ld	ra,120(sp)
    80004d9e:	7446                	ld	s0,112(sp)
    80004da0:	74a6                	ld	s1,104(sp)
    80004da2:	7906                	ld	s2,96(sp)
    80004da4:	69e6                	ld	s3,88(sp)
    80004da6:	6a46                	ld	s4,80(sp)
    80004da8:	6aa6                	ld	s5,72(sp)
    80004daa:	6b06                	ld	s6,64(sp)
    80004dac:	7be2                	ld	s7,56(sp)
    80004dae:	7c42                	ld	s8,48(sp)
    80004db0:	7ca2                	ld	s9,40(sp)
    80004db2:	7d02                	ld	s10,32(sp)
    80004db4:	6de2                	ld	s11,24(sp)
    80004db6:	6109                	addi	sp,sp,128
    80004db8:	8082                	ret
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dba:	4685                	li	a3,1
    80004dbc:	01ab8633          	add	a2,s7,s10
    80004dc0:	f8f40593          	addi	a1,s0,-113
    80004dc4:	05093503          	ld	a0,80(s2)
    80004dc8:	ffffd097          	auipc	ra,0xffffd
    80004dcc:	abc080e7          	jalr	-1348(ra) # 80001884 <copyin>
    80004dd0:	03b50863          	beq	a0,s11,80004e00 <pipewrite+0x118>
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004dd4:	21c4a783          	lw	a5,540(s1)
    80004dd8:	0017871b          	addiw	a4,a5,1
    80004ddc:	20e4ae23          	sw	a4,540(s1)
    80004de0:	1ff7f793          	andi	a5,a5,511
    80004de4:	97a6                	add	a5,a5,s1
    80004de6:	f8f44703          	lbu	a4,-113(s0)
    80004dea:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004dee:	001c8c1b          	addiw	s8,s9,1
    80004df2:	001b8793          	addi	a5,s7,1
    80004df6:	016b8563          	beq	s7,s6,80004e00 <pipewrite+0x118>
    80004dfa:	8bbe                	mv	s7,a5
    80004dfc:	bf3d                	j	80004d3a <pipewrite+0x52>
    80004dfe:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004e00:	21848513          	addi	a0,s1,536
    80004e04:	ffffe097          	auipc	ra,0xffffe
    80004e08:	868080e7          	jalr	-1944(ra) # 8000266c <wakeup>
  release(&pi->lock);
    80004e0c:	8526                	mv	a0,s1
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	048080e7          	jalr	72(ra) # 80000e56 <release>
  return i;
    80004e16:	b751                	j	80004d9a <pipewrite+0xb2>

0000000080004e18 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e18:	715d                	addi	sp,sp,-80
    80004e1a:	e486                	sd	ra,72(sp)
    80004e1c:	e0a2                	sd	s0,64(sp)
    80004e1e:	fc26                	sd	s1,56(sp)
    80004e20:	f84a                	sd	s2,48(sp)
    80004e22:	f44e                	sd	s3,40(sp)
    80004e24:	f052                	sd	s4,32(sp)
    80004e26:	ec56                	sd	s5,24(sp)
    80004e28:	e85a                	sd	s6,16(sp)
    80004e2a:	0880                	addi	s0,sp,80
    80004e2c:	84aa                	mv	s1,a0
    80004e2e:	89ae                	mv	s3,a1
    80004e30:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e32:	ffffd097          	auipc	ra,0xffffd
    80004e36:	e9a080e7          	jalr	-358(ra) # 80001ccc <myproc>
    80004e3a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e3c:	8526                	mv	a0,s1
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	f64080e7          	jalr	-156(ra) # 80000da2 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e46:	2184a703          	lw	a4,536(s1)
    80004e4a:	21c4a783          	lw	a5,540(s1)
    80004e4e:	06f71b63          	bne	a4,a5,80004ec4 <piperead+0xac>
    80004e52:	8926                	mv	s2,s1
    80004e54:	2244a783          	lw	a5,548(s1)
    80004e58:	cf9d                	beqz	a5,80004e96 <piperead+0x7e>
    if(pr->killed){
    80004e5a:	030a2783          	lw	a5,48(s4)
    80004e5e:	e78d                	bnez	a5,80004e88 <piperead+0x70>
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e60:	21848b13          	addi	s6,s1,536
    80004e64:	85ca                	mv	a1,s2
    80004e66:	855a                	mv	a0,s6
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	67e080e7          	jalr	1662(ra) # 800024e6 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e70:	2184a703          	lw	a4,536(s1)
    80004e74:	21c4a783          	lw	a5,540(s1)
    80004e78:	04f71663          	bne	a4,a5,80004ec4 <piperead+0xac>
    80004e7c:	2244a783          	lw	a5,548(s1)
    80004e80:	cb99                	beqz	a5,80004e96 <piperead+0x7e>
    if(pr->killed){
    80004e82:	030a2783          	lw	a5,48(s4)
    80004e86:	dff9                	beqz	a5,80004e64 <piperead+0x4c>
      release(&pi->lock);
    80004e88:	8526                	mv	a0,s1
    80004e8a:	ffffc097          	auipc	ra,0xffffc
    80004e8e:	fcc080e7          	jalr	-52(ra) # 80000e56 <release>
      return -1;
    80004e92:	597d                	li	s2,-1
    80004e94:	a829                	j	80004eae <piperead+0x96>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    if(pi->nread == pi->nwrite)
    80004e96:	4901                	li	s2,0
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e98:	21c48513          	addi	a0,s1,540
    80004e9c:	ffffd097          	auipc	ra,0xffffd
    80004ea0:	7d0080e7          	jalr	2000(ra) # 8000266c <wakeup>
  release(&pi->lock);
    80004ea4:	8526                	mv	a0,s1
    80004ea6:	ffffc097          	auipc	ra,0xffffc
    80004eaa:	fb0080e7          	jalr	-80(ra) # 80000e56 <release>
  return i;
}
    80004eae:	854a                	mv	a0,s2
    80004eb0:	60a6                	ld	ra,72(sp)
    80004eb2:	6406                	ld	s0,64(sp)
    80004eb4:	74e2                	ld	s1,56(sp)
    80004eb6:	7942                	ld	s2,48(sp)
    80004eb8:	79a2                	ld	s3,40(sp)
    80004eba:	7a02                	ld	s4,32(sp)
    80004ebc:	6ae2                	ld	s5,24(sp)
    80004ebe:	6b42                	ld	s6,16(sp)
    80004ec0:	6161                	addi	sp,sp,80
    80004ec2:	8082                	ret
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ec4:	4901                	li	s2,0
    80004ec6:	fd5059e3          	blez	s5,80004e98 <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004eca:	2184a783          	lw	a5,536(s1)
    80004ece:	4901                	li	s2,0
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ed0:	5b7d                	li	s6,-1
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ed2:	0017871b          	addiw	a4,a5,1
    80004ed6:	20e4ac23          	sw	a4,536(s1)
    80004eda:	1ff7f793          	andi	a5,a5,511
    80004ede:	97a6                	add	a5,a5,s1
    80004ee0:	0187c783          	lbu	a5,24(a5)
    80004ee4:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ee8:	4685                	li	a3,1
    80004eea:	fbf40613          	addi	a2,s0,-65
    80004eee:	85ce                	mv	a1,s3
    80004ef0:	050a3503          	ld	a0,80(s4)
    80004ef4:	ffffd097          	auipc	ra,0xffffd
    80004ef8:	bcc080e7          	jalr	-1076(ra) # 80001ac0 <copyout>
    80004efc:	f9650ee3          	beq	a0,s6,80004e98 <piperead+0x80>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f00:	2905                	addiw	s2,s2,1
    80004f02:	f92a8be3          	beq	s5,s2,80004e98 <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004f06:	2184a783          	lw	a5,536(s1)
    80004f0a:	0985                	addi	s3,s3,1
    80004f0c:	21c4a703          	lw	a4,540(s1)
    80004f10:	fcf711e3          	bne	a4,a5,80004ed2 <piperead+0xba>
    80004f14:	b751                	j	80004e98 <piperead+0x80>

0000000080004f16 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004f16:	de010113          	addi	sp,sp,-544
    80004f1a:	20113c23          	sd	ra,536(sp)
    80004f1e:	20813823          	sd	s0,528(sp)
    80004f22:	20913423          	sd	s1,520(sp)
    80004f26:	21213023          	sd	s2,512(sp)
    80004f2a:	ffce                	sd	s3,504(sp)
    80004f2c:	fbd2                	sd	s4,496(sp)
    80004f2e:	f7d6                	sd	s5,488(sp)
    80004f30:	f3da                	sd	s6,480(sp)
    80004f32:	efde                	sd	s7,472(sp)
    80004f34:	ebe2                	sd	s8,464(sp)
    80004f36:	e7e6                	sd	s9,456(sp)
    80004f38:	e3ea                	sd	s10,448(sp)
    80004f3a:	ff6e                	sd	s11,440(sp)
    80004f3c:	1400                	addi	s0,sp,544
    80004f3e:	892a                	mv	s2,a0
    80004f40:	dea43823          	sd	a0,-528(s0)
    80004f44:	deb43c23          	sd	a1,-520(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f48:	ffffd097          	auipc	ra,0xffffd
    80004f4c:	d84080e7          	jalr	-636(ra) # 80001ccc <myproc>
    80004f50:	84aa                	mv	s1,a0

  begin_op();
    80004f52:	fffff097          	auipc	ra,0xfffff
    80004f56:	402080e7          	jalr	1026(ra) # 80004354 <begin_op>

  if((ip = namei(path)) == 0){
    80004f5a:	854a                	mv	a0,s2
    80004f5c:	fffff097          	auipc	ra,0xfffff
    80004f60:	1ea080e7          	jalr	490(ra) # 80004146 <namei>
    80004f64:	c93d                	beqz	a0,80004fda <exec+0xc4>
    80004f66:	892a                	mv	s2,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f68:	fffff097          	auipc	ra,0xfffff
    80004f6c:	a20080e7          	jalr	-1504(ra) # 80003988 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f70:	04000713          	li	a4,64
    80004f74:	4681                	li	a3,0
    80004f76:	e4840613          	addi	a2,s0,-440
    80004f7a:	4581                	li	a1,0
    80004f7c:	854a                	mv	a0,s2
    80004f7e:	fffff097          	auipc	ra,0xfffff
    80004f82:	cc0080e7          	jalr	-832(ra) # 80003c3e <readi>
    80004f86:	04000793          	li	a5,64
    80004f8a:	00f51a63          	bne	a0,a5,80004f9e <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f8e:	e4842703          	lw	a4,-440(s0)
    80004f92:	464c47b7          	lui	a5,0x464c4
    80004f96:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f9a:	04f70663          	beq	a4,a5,80004fe6 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f9e:	854a                	mv	a0,s2
    80004fa0:	fffff097          	auipc	ra,0xfffff
    80004fa4:	c4c080e7          	jalr	-948(ra) # 80003bec <iunlockput>
    end_op();
    80004fa8:	fffff097          	auipc	ra,0xfffff
    80004fac:	42c080e7          	jalr	1068(ra) # 800043d4 <end_op>
  }
  return -1;
    80004fb0:	557d                	li	a0,-1
}
    80004fb2:	21813083          	ld	ra,536(sp)
    80004fb6:	21013403          	ld	s0,528(sp)
    80004fba:	20813483          	ld	s1,520(sp)
    80004fbe:	20013903          	ld	s2,512(sp)
    80004fc2:	79fe                	ld	s3,504(sp)
    80004fc4:	7a5e                	ld	s4,496(sp)
    80004fc6:	7abe                	ld	s5,488(sp)
    80004fc8:	7b1e                	ld	s6,480(sp)
    80004fca:	6bfe                	ld	s7,472(sp)
    80004fcc:	6c5e                	ld	s8,464(sp)
    80004fce:	6cbe                	ld	s9,456(sp)
    80004fd0:	6d1e                	ld	s10,448(sp)
    80004fd2:	7dfa                	ld	s11,440(sp)
    80004fd4:	22010113          	addi	sp,sp,544
    80004fd8:	8082                	ret
    end_op();
    80004fda:	fffff097          	auipc	ra,0xfffff
    80004fde:	3fa080e7          	jalr	1018(ra) # 800043d4 <end_op>
    return -1;
    80004fe2:	557d                	li	a0,-1
    80004fe4:	b7f9                	j	80004fb2 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fe6:	8526                	mv	a0,s1
    80004fe8:	ffffd097          	auipc	ra,0xffffd
    80004fec:	daa080e7          	jalr	-598(ra) # 80001d92 <proc_pagetable>
    80004ff0:	e0a43423          	sd	a0,-504(s0)
    80004ff4:	d54d                	beqz	a0,80004f9e <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ff6:	e6842983          	lw	s3,-408(s0)
    80004ffa:	e8045783          	lhu	a5,-384(s0)
    80004ffe:	c7ad                	beqz	a5,80005068 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005000:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005002:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005004:	6c05                	lui	s8,0x1
    80005006:	fffc0793          	addi	a5,s8,-1 # fff <_entry-0x7ffff001>
    8000500a:	def43423          	sd	a5,-536(s0)
    8000500e:	7cfd                	lui	s9,0xfffff
    80005010:	ac1d                	j	80005246 <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005012:	00003517          	auipc	a0,0x3
    80005016:	6be50513          	addi	a0,a0,1726 # 800086d0 <syscalls+0x2b8>
    8000501a:	ffffb097          	auipc	ra,0xffffb
    8000501e:	55a080e7          	jalr	1370(ra) # 80000574 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005022:	8756                	mv	a4,s5
    80005024:	009d86bb          	addw	a3,s11,s1
    80005028:	4581                	li	a1,0
    8000502a:	854a                	mv	a0,s2
    8000502c:	fffff097          	auipc	ra,0xfffff
    80005030:	c12080e7          	jalr	-1006(ra) # 80003c3e <readi>
    80005034:	2501                	sext.w	a0,a0
    80005036:	1aaa9e63          	bne	s5,a0,800051f2 <exec+0x2dc>
  for(i = 0; i < sz; i += PGSIZE){
    8000503a:	6785                	lui	a5,0x1
    8000503c:	9cbd                	addw	s1,s1,a5
    8000503e:	014c8a3b          	addw	s4,s9,s4
    80005042:	1f74f963          	bleu	s7,s1,80005234 <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    80005046:	02049593          	slli	a1,s1,0x20
    8000504a:	9181                	srli	a1,a1,0x20
    8000504c:	95ea                	add	a1,a1,s10
    8000504e:	e0843503          	ld	a0,-504(s0)
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	202080e7          	jalr	514(ra) # 80001254 <walkaddr>
    8000505a:	862a                	mv	a2,a0
    if(pa == 0)
    8000505c:	d95d                	beqz	a0,80005012 <exec+0xfc>
      n = PGSIZE;
    8000505e:	8ae2                	mv	s5,s8
    if(sz - i < PGSIZE)
    80005060:	fd8a71e3          	bleu	s8,s4,80005022 <exec+0x10c>
      n = sz - i;
    80005064:	8ad2                	mv	s5,s4
    80005066:	bf75                	j	80005022 <exec+0x10c>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005068:	4481                	li	s1,0
  iunlockput(ip);
    8000506a:	854a                	mv	a0,s2
    8000506c:	fffff097          	auipc	ra,0xfffff
    80005070:	b80080e7          	jalr	-1152(ra) # 80003bec <iunlockput>
  end_op();
    80005074:	fffff097          	auipc	ra,0xfffff
    80005078:	360080e7          	jalr	864(ra) # 800043d4 <end_op>
  p = myproc();
    8000507c:	ffffd097          	auipc	ra,0xffffd
    80005080:	c50080e7          	jalr	-944(ra) # 80001ccc <myproc>
    80005084:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005086:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000508a:	6785                	lui	a5,0x1
    8000508c:	17fd                	addi	a5,a5,-1
    8000508e:	94be                	add	s1,s1,a5
    80005090:	77fd                	lui	a5,0xfffff
    80005092:	8fe5                	and	a5,a5,s1
    80005094:	e0f43023          	sd	a5,-512(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005098:	6609                	lui	a2,0x2
    8000509a:	963e                	add	a2,a2,a5
    8000509c:	85be                	mv	a1,a5
    8000509e:	e0843483          	ld	s1,-504(s0)
    800050a2:	8526                	mv	a0,s1
    800050a4:	ffffc097          	auipc	ra,0xffffc
    800050a8:	5a4080e7          	jalr	1444(ra) # 80001648 <uvmalloc>
    800050ac:	8b2a                	mv	s6,a0
  ip = 0;
    800050ae:	4901                	li	s2,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050b0:	14050163          	beqz	a0,800051f2 <exec+0x2dc>
  uvmclear(pagetable, sz-2*PGSIZE);
    800050b4:	75f9                	lui	a1,0xffffe
    800050b6:	95aa                	add	a1,a1,a0
    800050b8:	8526                	mv	a0,s1
    800050ba:	ffffc097          	auipc	ra,0xffffc
    800050be:	798080e7          	jalr	1944(ra) # 80001852 <uvmclear>
  stackbase = sp - PGSIZE;
    800050c2:	7bfd                	lui	s7,0xfffff
    800050c4:	9bda                	add	s7,s7,s6
  for(argc = 0; argv[argc]; argc++) {
    800050c6:	df843783          	ld	a5,-520(s0)
    800050ca:	6388                	ld	a0,0(a5)
    800050cc:	c925                	beqz	a0,8000513c <exec+0x226>
    800050ce:	e8840993          	addi	s3,s0,-376
    800050d2:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    800050d6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800050d8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800050da:	ffffc097          	auipc	ra,0xffffc
    800050de:	f6e080e7          	jalr	-146(ra) # 80001048 <strlen>
    800050e2:	2505                	addiw	a0,a0,1
    800050e4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050e8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050ec:	13796863          	bltu	s2,s7,8000521c <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050f0:	df843c83          	ld	s9,-520(s0)
    800050f4:	000cba03          	ld	s4,0(s9) # fffffffffffff000 <end+0xffffffff7ff99000>
    800050f8:	8552                	mv	a0,s4
    800050fa:	ffffc097          	auipc	ra,0xffffc
    800050fe:	f4e080e7          	jalr	-178(ra) # 80001048 <strlen>
    80005102:	0015069b          	addiw	a3,a0,1
    80005106:	8652                	mv	a2,s4
    80005108:	85ca                	mv	a1,s2
    8000510a:	e0843503          	ld	a0,-504(s0)
    8000510e:	ffffd097          	auipc	ra,0xffffd
    80005112:	9b2080e7          	jalr	-1614(ra) # 80001ac0 <copyout>
    80005116:	10054763          	bltz	a0,80005224 <exec+0x30e>
    ustack[argc] = sp;
    8000511a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000511e:	0485                	addi	s1,s1,1
    80005120:	008c8793          	addi	a5,s9,8
    80005124:	def43c23          	sd	a5,-520(s0)
    80005128:	008cb503          	ld	a0,8(s9)
    8000512c:	c911                	beqz	a0,80005140 <exec+0x22a>
    if(argc >= MAXARG)
    8000512e:	09a1                	addi	s3,s3,8
    80005130:	fb8995e3          	bne	s3,s8,800050da <exec+0x1c4>
  sz = sz1;
    80005134:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005138:	4901                	li	s2,0
    8000513a:	a865                	j	800051f2 <exec+0x2dc>
  sp = sz;
    8000513c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000513e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005140:	00349793          	slli	a5,s1,0x3
    80005144:	f9040713          	addi	a4,s0,-112
    80005148:	97ba                	add	a5,a5,a4
    8000514a:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ff98ef8>
  sp -= (argc+1) * sizeof(uint64);
    8000514e:	00148693          	addi	a3,s1,1
    80005152:	068e                	slli	a3,a3,0x3
    80005154:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005158:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000515c:	01797663          	bleu	s7,s2,80005168 <exec+0x252>
  sz = sz1;
    80005160:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005164:	4901                	li	s2,0
    80005166:	a071                	j	800051f2 <exec+0x2dc>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005168:	e8840613          	addi	a2,s0,-376
    8000516c:	85ca                	mv	a1,s2
    8000516e:	e0843503          	ld	a0,-504(s0)
    80005172:	ffffd097          	auipc	ra,0xffffd
    80005176:	94e080e7          	jalr	-1714(ra) # 80001ac0 <copyout>
    8000517a:	0a054963          	bltz	a0,8000522c <exec+0x316>
  p->trapframe->a1 = sp;
    8000517e:	058ab783          	ld	a5,88(s5)
    80005182:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005186:	df043783          	ld	a5,-528(s0)
    8000518a:	0007c703          	lbu	a4,0(a5)
    8000518e:	cf11                	beqz	a4,800051aa <exec+0x294>
    80005190:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005192:	02f00693          	li	a3,47
    80005196:	a029                	j	800051a0 <exec+0x28a>
  for(last=s=path; *s; s++)
    80005198:	0785                	addi	a5,a5,1
    8000519a:	fff7c703          	lbu	a4,-1(a5)
    8000519e:	c711                	beqz	a4,800051aa <exec+0x294>
    if(*s == '/')
    800051a0:	fed71ce3          	bne	a4,a3,80005198 <exec+0x282>
      last = s+1;
    800051a4:	def43823          	sd	a5,-528(s0)
    800051a8:	bfc5                	j	80005198 <exec+0x282>
  safestrcpy(p->name, last, sizeof(p->name));
    800051aa:	4641                	li	a2,16
    800051ac:	df043583          	ld	a1,-528(s0)
    800051b0:	158a8513          	addi	a0,s5,344
    800051b4:	ffffc097          	auipc	ra,0xffffc
    800051b8:	e62080e7          	jalr	-414(ra) # 80001016 <safestrcpy>
  oldpagetable = p->pagetable;
    800051bc:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800051c0:	e0843783          	ld	a5,-504(s0)
    800051c4:	04fab823          	sd	a5,80(s5)
  p->sz = sz;
    800051c8:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051cc:	058ab783          	ld	a5,88(s5)
    800051d0:	e6043703          	ld	a4,-416(s0)
    800051d4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051d6:	058ab783          	ld	a5,88(s5)
    800051da:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051de:	85ea                	mv	a1,s10
    800051e0:	ffffd097          	auipc	ra,0xffffd
    800051e4:	c4e080e7          	jalr	-946(ra) # 80001e2e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051e8:	0004851b          	sext.w	a0,s1
    800051ec:	b3d9                	j	80004fb2 <exec+0x9c>
    800051ee:	e0943023          	sd	s1,-512(s0)
    proc_freepagetable(pagetable, sz);
    800051f2:	e0043583          	ld	a1,-512(s0)
    800051f6:	e0843503          	ld	a0,-504(s0)
    800051fa:	ffffd097          	auipc	ra,0xffffd
    800051fe:	c34080e7          	jalr	-972(ra) # 80001e2e <proc_freepagetable>
  if(ip){
    80005202:	d8091ee3          	bnez	s2,80004f9e <exec+0x88>
  return -1;
    80005206:	557d                	li	a0,-1
    80005208:	b36d                	j	80004fb2 <exec+0x9c>
    8000520a:	e0943023          	sd	s1,-512(s0)
    8000520e:	b7d5                	j	800051f2 <exec+0x2dc>
    80005210:	e0943023          	sd	s1,-512(s0)
    80005214:	bff9                	j	800051f2 <exec+0x2dc>
    80005216:	e0943023          	sd	s1,-512(s0)
    8000521a:	bfe1                	j	800051f2 <exec+0x2dc>
  sz = sz1;
    8000521c:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005220:	4901                	li	s2,0
    80005222:	bfc1                	j	800051f2 <exec+0x2dc>
  sz = sz1;
    80005224:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005228:	4901                	li	s2,0
    8000522a:	b7e1                	j	800051f2 <exec+0x2dc>
  sz = sz1;
    8000522c:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005230:	4901                	li	s2,0
    80005232:	b7c1                	j	800051f2 <exec+0x2dc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005234:	e0043483          	ld	s1,-512(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005238:	2b05                	addiw	s6,s6,1
    8000523a:	0389899b          	addiw	s3,s3,56
    8000523e:	e8045783          	lhu	a5,-384(s0)
    80005242:	e2fb54e3          	ble	a5,s6,8000506a <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005246:	2981                	sext.w	s3,s3
    80005248:	03800713          	li	a4,56
    8000524c:	86ce                	mv	a3,s3
    8000524e:	e1040613          	addi	a2,s0,-496
    80005252:	4581                	li	a1,0
    80005254:	854a                	mv	a0,s2
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	9e8080e7          	jalr	-1560(ra) # 80003c3e <readi>
    8000525e:	03800793          	li	a5,56
    80005262:	f8f516e3          	bne	a0,a5,800051ee <exec+0x2d8>
    if(ph.type != ELF_PROG_LOAD)
    80005266:	e1042783          	lw	a5,-496(s0)
    8000526a:	4705                	li	a4,1
    8000526c:	fce796e3          	bne	a5,a4,80005238 <exec+0x322>
    if(ph.memsz < ph.filesz)
    80005270:	e3843603          	ld	a2,-456(s0)
    80005274:	e3043783          	ld	a5,-464(s0)
    80005278:	f8f669e3          	bltu	a2,a5,8000520a <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000527c:	e2043783          	ld	a5,-480(s0)
    80005280:	963e                	add	a2,a2,a5
    80005282:	f8f667e3          	bltu	a2,a5,80005210 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005286:	85a6                	mv	a1,s1
    80005288:	e0843503          	ld	a0,-504(s0)
    8000528c:	ffffc097          	auipc	ra,0xffffc
    80005290:	3bc080e7          	jalr	956(ra) # 80001648 <uvmalloc>
    80005294:	e0a43023          	sd	a0,-512(s0)
    80005298:	dd3d                	beqz	a0,80005216 <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    8000529a:	e2043d03          	ld	s10,-480(s0)
    8000529e:	de843783          	ld	a5,-536(s0)
    800052a2:	00fd77b3          	and	a5,s10,a5
    800052a6:	f7b1                	bnez	a5,800051f2 <exec+0x2dc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052a8:	e1842d83          	lw	s11,-488(s0)
    800052ac:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052b0:	f80b82e3          	beqz	s7,80005234 <exec+0x31e>
    800052b4:	8a5e                	mv	s4,s7
    800052b6:	4481                	li	s1,0
    800052b8:	b379                	j	80005046 <exec+0x130>

00000000800052ba <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052ba:	7179                	addi	sp,sp,-48
    800052bc:	f406                	sd	ra,40(sp)
    800052be:	f022                	sd	s0,32(sp)
    800052c0:	ec26                	sd	s1,24(sp)
    800052c2:	e84a                	sd	s2,16(sp)
    800052c4:	1800                	addi	s0,sp,48
    800052c6:	892e                	mv	s2,a1
    800052c8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052ca:	fdc40593          	addi	a1,s0,-36
    800052ce:	ffffe097          	auipc	ra,0xffffe
    800052d2:	afa080e7          	jalr	-1286(ra) # 80002dc8 <argint>
    800052d6:	04054063          	bltz	a0,80005316 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052da:	fdc42703          	lw	a4,-36(s0)
    800052de:	47bd                	li	a5,15
    800052e0:	02e7ed63          	bltu	a5,a4,8000531a <argfd+0x60>
    800052e4:	ffffd097          	auipc	ra,0xffffd
    800052e8:	9e8080e7          	jalr	-1560(ra) # 80001ccc <myproc>
    800052ec:	fdc42703          	lw	a4,-36(s0)
    800052f0:	01a70793          	addi	a5,a4,26
    800052f4:	078e                	slli	a5,a5,0x3
    800052f6:	953e                	add	a0,a0,a5
    800052f8:	611c                	ld	a5,0(a0)
    800052fa:	c395                	beqz	a5,8000531e <argfd+0x64>
    return -1;
  if(pfd)
    800052fc:	00090463          	beqz	s2,80005304 <argfd+0x4a>
    *pfd = fd;
    80005300:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005304:	4501                	li	a0,0
  if(pf)
    80005306:	c091                	beqz	s1,8000530a <argfd+0x50>
    *pf = f;
    80005308:	e09c                	sd	a5,0(s1)
}
    8000530a:	70a2                	ld	ra,40(sp)
    8000530c:	7402                	ld	s0,32(sp)
    8000530e:	64e2                	ld	s1,24(sp)
    80005310:	6942                	ld	s2,16(sp)
    80005312:	6145                	addi	sp,sp,48
    80005314:	8082                	ret
    return -1;
    80005316:	557d                	li	a0,-1
    80005318:	bfcd                	j	8000530a <argfd+0x50>
    return -1;
    8000531a:	557d                	li	a0,-1
    8000531c:	b7fd                	j	8000530a <argfd+0x50>
    8000531e:	557d                	li	a0,-1
    80005320:	b7ed                	j	8000530a <argfd+0x50>

0000000080005322 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005322:	1101                	addi	sp,sp,-32
    80005324:	ec06                	sd	ra,24(sp)
    80005326:	e822                	sd	s0,16(sp)
    80005328:	e426                	sd	s1,8(sp)
    8000532a:	1000                	addi	s0,sp,32
    8000532c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000532e:	ffffd097          	auipc	ra,0xffffd
    80005332:	99e080e7          	jalr	-1634(ra) # 80001ccc <myproc>

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){
    80005336:	697c                	ld	a5,208(a0)
    80005338:	c395                	beqz	a5,8000535c <fdalloc+0x3a>
    8000533a:	0d850713          	addi	a4,a0,216
  for(fd = 0; fd < NOFILE; fd++){
    8000533e:	4785                	li	a5,1
    80005340:	4641                	li	a2,16
    if(p->ofile[fd] == 0){
    80005342:	6314                	ld	a3,0(a4)
    80005344:	ce89                	beqz	a3,8000535e <fdalloc+0x3c>
  for(fd = 0; fd < NOFILE; fd++){
    80005346:	2785                	addiw	a5,a5,1
    80005348:	0721                	addi	a4,a4,8
    8000534a:	fec79ce3          	bne	a5,a2,80005342 <fdalloc+0x20>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000534e:	57fd                	li	a5,-1
}
    80005350:	853e                	mv	a0,a5
    80005352:	60e2                	ld	ra,24(sp)
    80005354:	6442                	ld	s0,16(sp)
    80005356:	64a2                	ld	s1,8(sp)
    80005358:	6105                	addi	sp,sp,32
    8000535a:	8082                	ret
  for(fd = 0; fd < NOFILE; fd++){
    8000535c:	4781                	li	a5,0
      p->ofile[fd] = f;
    8000535e:	01a78713          	addi	a4,a5,26
    80005362:	070e                	slli	a4,a4,0x3
    80005364:	953a                	add	a0,a0,a4
    80005366:	e104                	sd	s1,0(a0)
      return fd;
    80005368:	b7e5                	j	80005350 <fdalloc+0x2e>

000000008000536a <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000536a:	715d                	addi	sp,sp,-80
    8000536c:	e486                	sd	ra,72(sp)
    8000536e:	e0a2                	sd	s0,64(sp)
    80005370:	fc26                	sd	s1,56(sp)
    80005372:	f84a                	sd	s2,48(sp)
    80005374:	f44e                	sd	s3,40(sp)
    80005376:	f052                	sd	s4,32(sp)
    80005378:	ec56                	sd	s5,24(sp)
    8000537a:	0880                	addi	s0,sp,80
    8000537c:	89ae                	mv	s3,a1
    8000537e:	8ab2                	mv	s5,a2
    80005380:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005382:	fb040593          	addi	a1,s0,-80
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	dde080e7          	jalr	-546(ra) # 80004164 <nameiparent>
    8000538e:	892a                	mv	s2,a0
    80005390:	12050f63          	beqz	a0,800054ce <create+0x164>
    return 0;

  ilock(dp);
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	5f4080e7          	jalr	1524(ra) # 80003988 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000539c:	4601                	li	a2,0
    8000539e:	fb040593          	addi	a1,s0,-80
    800053a2:	854a                	mv	a0,s2
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	ac8080e7          	jalr	-1336(ra) # 80003e6c <dirlookup>
    800053ac:	84aa                	mv	s1,a0
    800053ae:	c921                	beqz	a0,800053fe <create+0x94>
    iunlockput(dp);
    800053b0:	854a                	mv	a0,s2
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	83a080e7          	jalr	-1990(ra) # 80003bec <iunlockput>
    ilock(ip);
    800053ba:	8526                	mv	a0,s1
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	5cc080e7          	jalr	1484(ra) # 80003988 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053c4:	2981                	sext.w	s3,s3
    800053c6:	4789                	li	a5,2
    800053c8:	02f99463          	bne	s3,a5,800053f0 <create+0x86>
    800053cc:	0444d783          	lhu	a5,68(s1)
    800053d0:	37f9                	addiw	a5,a5,-2
    800053d2:	17c2                	slli	a5,a5,0x30
    800053d4:	93c1                	srli	a5,a5,0x30
    800053d6:	4705                	li	a4,1
    800053d8:	00f76c63          	bltu	a4,a5,800053f0 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053dc:	8526                	mv	a0,s1
    800053de:	60a6                	ld	ra,72(sp)
    800053e0:	6406                	ld	s0,64(sp)
    800053e2:	74e2                	ld	s1,56(sp)
    800053e4:	7942                	ld	s2,48(sp)
    800053e6:	79a2                	ld	s3,40(sp)
    800053e8:	7a02                	ld	s4,32(sp)
    800053ea:	6ae2                	ld	s5,24(sp)
    800053ec:	6161                	addi	sp,sp,80
    800053ee:	8082                	ret
    iunlockput(ip);
    800053f0:	8526                	mv	a0,s1
    800053f2:	ffffe097          	auipc	ra,0xffffe
    800053f6:	7fa080e7          	jalr	2042(ra) # 80003bec <iunlockput>
    return 0;
    800053fa:	4481                	li	s1,0
    800053fc:	b7c5                	j	800053dc <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800053fe:	85ce                	mv	a1,s3
    80005400:	00092503          	lw	a0,0(s2)
    80005404:	ffffe097          	auipc	ra,0xffffe
    80005408:	3e8080e7          	jalr	1000(ra) # 800037ec <ialloc>
    8000540c:	84aa                	mv	s1,a0
    8000540e:	c529                	beqz	a0,80005458 <create+0xee>
  ilock(ip);
    80005410:	ffffe097          	auipc	ra,0xffffe
    80005414:	578080e7          	jalr	1400(ra) # 80003988 <ilock>
  ip->major = major;
    80005418:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000541c:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005420:	4785                	li	a5,1
    80005422:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005426:	8526                	mv	a0,s1
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	494080e7          	jalr	1172(ra) # 800038bc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005430:	2981                	sext.w	s3,s3
    80005432:	4785                	li	a5,1
    80005434:	02f98a63          	beq	s3,a5,80005468 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005438:	40d0                	lw	a2,4(s1)
    8000543a:	fb040593          	addi	a1,s0,-80
    8000543e:	854a                	mv	a0,s2
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	c44080e7          	jalr	-956(ra) # 80004084 <dirlink>
    80005448:	06054b63          	bltz	a0,800054be <create+0x154>
  iunlockput(dp);
    8000544c:	854a                	mv	a0,s2
    8000544e:	ffffe097          	auipc	ra,0xffffe
    80005452:	79e080e7          	jalr	1950(ra) # 80003bec <iunlockput>
  return ip;
    80005456:	b759                	j	800053dc <create+0x72>
    panic("create: ialloc");
    80005458:	00003517          	auipc	a0,0x3
    8000545c:	29850513          	addi	a0,a0,664 # 800086f0 <syscalls+0x2d8>
    80005460:	ffffb097          	auipc	ra,0xffffb
    80005464:	114080e7          	jalr	276(ra) # 80000574 <panic>
    dp->nlink++;  // for ".."
    80005468:	04a95783          	lhu	a5,74(s2)
    8000546c:	2785                	addiw	a5,a5,1
    8000546e:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005472:	854a                	mv	a0,s2
    80005474:	ffffe097          	auipc	ra,0xffffe
    80005478:	448080e7          	jalr	1096(ra) # 800038bc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000547c:	40d0                	lw	a2,4(s1)
    8000547e:	00003597          	auipc	a1,0x3
    80005482:	28258593          	addi	a1,a1,642 # 80008700 <syscalls+0x2e8>
    80005486:	8526                	mv	a0,s1
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	bfc080e7          	jalr	-1028(ra) # 80004084 <dirlink>
    80005490:	00054f63          	bltz	a0,800054ae <create+0x144>
    80005494:	00492603          	lw	a2,4(s2)
    80005498:	00003597          	auipc	a1,0x3
    8000549c:	27058593          	addi	a1,a1,624 # 80008708 <syscalls+0x2f0>
    800054a0:	8526                	mv	a0,s1
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	be2080e7          	jalr	-1054(ra) # 80004084 <dirlink>
    800054aa:	f80557e3          	bgez	a0,80005438 <create+0xce>
      panic("create dots");
    800054ae:	00003517          	auipc	a0,0x3
    800054b2:	26250513          	addi	a0,a0,610 # 80008710 <syscalls+0x2f8>
    800054b6:	ffffb097          	auipc	ra,0xffffb
    800054ba:	0be080e7          	jalr	190(ra) # 80000574 <panic>
    panic("create: dirlink");
    800054be:	00003517          	auipc	a0,0x3
    800054c2:	26250513          	addi	a0,a0,610 # 80008720 <syscalls+0x308>
    800054c6:	ffffb097          	auipc	ra,0xffffb
    800054ca:	0ae080e7          	jalr	174(ra) # 80000574 <panic>
    return 0;
    800054ce:	84aa                	mv	s1,a0
    800054d0:	b731                	j	800053dc <create+0x72>

00000000800054d2 <sys_dup>:
{
    800054d2:	7179                	addi	sp,sp,-48
    800054d4:	f406                	sd	ra,40(sp)
    800054d6:	f022                	sd	s0,32(sp)
    800054d8:	ec26                	sd	s1,24(sp)
    800054da:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054dc:	fd840613          	addi	a2,s0,-40
    800054e0:	4581                	li	a1,0
    800054e2:	4501                	li	a0,0
    800054e4:	00000097          	auipc	ra,0x0
    800054e8:	dd6080e7          	jalr	-554(ra) # 800052ba <argfd>
    return -1;
    800054ec:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054ee:	02054363          	bltz	a0,80005514 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054f2:	fd843503          	ld	a0,-40(s0)
    800054f6:	00000097          	auipc	ra,0x0
    800054fa:	e2c080e7          	jalr	-468(ra) # 80005322 <fdalloc>
    800054fe:	84aa                	mv	s1,a0
    return -1;
    80005500:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005502:	00054963          	bltz	a0,80005514 <sys_dup+0x42>
  filedup(f);
    80005506:	fd843503          	ld	a0,-40(s0)
    8000550a:	fffff097          	auipc	ra,0xfffff
    8000550e:	2fa080e7          	jalr	762(ra) # 80004804 <filedup>
  return fd;
    80005512:	87a6                	mv	a5,s1
}
    80005514:	853e                	mv	a0,a5
    80005516:	70a2                	ld	ra,40(sp)
    80005518:	7402                	ld	s0,32(sp)
    8000551a:	64e2                	ld	s1,24(sp)
    8000551c:	6145                	addi	sp,sp,48
    8000551e:	8082                	ret

0000000080005520 <sys_read>:
{
    80005520:	7179                	addi	sp,sp,-48
    80005522:	f406                	sd	ra,40(sp)
    80005524:	f022                	sd	s0,32(sp)
    80005526:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005528:	fe840613          	addi	a2,s0,-24
    8000552c:	4581                	li	a1,0
    8000552e:	4501                	li	a0,0
    80005530:	00000097          	auipc	ra,0x0
    80005534:	d8a080e7          	jalr	-630(ra) # 800052ba <argfd>
    return -1;
    80005538:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000553a:	04054163          	bltz	a0,8000557c <sys_read+0x5c>
    8000553e:	fe440593          	addi	a1,s0,-28
    80005542:	4509                	li	a0,2
    80005544:	ffffe097          	auipc	ra,0xffffe
    80005548:	884080e7          	jalr	-1916(ra) # 80002dc8 <argint>
    return -1;
    8000554c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000554e:	02054763          	bltz	a0,8000557c <sys_read+0x5c>
    80005552:	fd840593          	addi	a1,s0,-40
    80005556:	4505                	li	a0,1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	892080e7          	jalr	-1902(ra) # 80002dea <argaddr>
    return -1;
    80005560:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005562:	00054d63          	bltz	a0,8000557c <sys_read+0x5c>
  return fileread(f, p, n);
    80005566:	fe442603          	lw	a2,-28(s0)
    8000556a:	fd843583          	ld	a1,-40(s0)
    8000556e:	fe843503          	ld	a0,-24(s0)
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	41e080e7          	jalr	1054(ra) # 80004990 <fileread>
    8000557a:	87aa                	mv	a5,a0
}
    8000557c:	853e                	mv	a0,a5
    8000557e:	70a2                	ld	ra,40(sp)
    80005580:	7402                	ld	s0,32(sp)
    80005582:	6145                	addi	sp,sp,48
    80005584:	8082                	ret

0000000080005586 <sys_write>:
{
    80005586:	7179                	addi	sp,sp,-48
    80005588:	f406                	sd	ra,40(sp)
    8000558a:	f022                	sd	s0,32(sp)
    8000558c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000558e:	fe840613          	addi	a2,s0,-24
    80005592:	4581                	li	a1,0
    80005594:	4501                	li	a0,0
    80005596:	00000097          	auipc	ra,0x0
    8000559a:	d24080e7          	jalr	-732(ra) # 800052ba <argfd>
    return -1;
    8000559e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055a0:	04054163          	bltz	a0,800055e2 <sys_write+0x5c>
    800055a4:	fe440593          	addi	a1,s0,-28
    800055a8:	4509                	li	a0,2
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	81e080e7          	jalr	-2018(ra) # 80002dc8 <argint>
    return -1;
    800055b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055b4:	02054763          	bltz	a0,800055e2 <sys_write+0x5c>
    800055b8:	fd840593          	addi	a1,s0,-40
    800055bc:	4505                	li	a0,1
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	82c080e7          	jalr	-2004(ra) # 80002dea <argaddr>
    return -1;
    800055c6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055c8:	00054d63          	bltz	a0,800055e2 <sys_write+0x5c>
  return filewrite(f, p, n);
    800055cc:	fe442603          	lw	a2,-28(s0)
    800055d0:	fd843583          	ld	a1,-40(s0)
    800055d4:	fe843503          	ld	a0,-24(s0)
    800055d8:	fffff097          	auipc	ra,0xfffff
    800055dc:	47a080e7          	jalr	1146(ra) # 80004a52 <filewrite>
    800055e0:	87aa                	mv	a5,a0
}
    800055e2:	853e                	mv	a0,a5
    800055e4:	70a2                	ld	ra,40(sp)
    800055e6:	7402                	ld	s0,32(sp)
    800055e8:	6145                	addi	sp,sp,48
    800055ea:	8082                	ret

00000000800055ec <sys_close>:
{
    800055ec:	1101                	addi	sp,sp,-32
    800055ee:	ec06                	sd	ra,24(sp)
    800055f0:	e822                	sd	s0,16(sp)
    800055f2:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055f4:	fe040613          	addi	a2,s0,-32
    800055f8:	fec40593          	addi	a1,s0,-20
    800055fc:	4501                	li	a0,0
    800055fe:	00000097          	auipc	ra,0x0
    80005602:	cbc080e7          	jalr	-836(ra) # 800052ba <argfd>
    return -1;
    80005606:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005608:	02054463          	bltz	a0,80005630 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000560c:	ffffc097          	auipc	ra,0xffffc
    80005610:	6c0080e7          	jalr	1728(ra) # 80001ccc <myproc>
    80005614:	fec42783          	lw	a5,-20(s0)
    80005618:	07e9                	addi	a5,a5,26
    8000561a:	078e                	slli	a5,a5,0x3
    8000561c:	953e                	add	a0,a0,a5
    8000561e:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005622:	fe043503          	ld	a0,-32(s0)
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	230080e7          	jalr	560(ra) # 80004856 <fileclose>
  return 0;
    8000562e:	4781                	li	a5,0
}
    80005630:	853e                	mv	a0,a5
    80005632:	60e2                	ld	ra,24(sp)
    80005634:	6442                	ld	s0,16(sp)
    80005636:	6105                	addi	sp,sp,32
    80005638:	8082                	ret

000000008000563a <sys_fstat>:
{
    8000563a:	1101                	addi	sp,sp,-32
    8000563c:	ec06                	sd	ra,24(sp)
    8000563e:	e822                	sd	s0,16(sp)
    80005640:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005642:	fe840613          	addi	a2,s0,-24
    80005646:	4581                	li	a1,0
    80005648:	4501                	li	a0,0
    8000564a:	00000097          	auipc	ra,0x0
    8000564e:	c70080e7          	jalr	-912(ra) # 800052ba <argfd>
    return -1;
    80005652:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005654:	02054563          	bltz	a0,8000567e <sys_fstat+0x44>
    80005658:	fe040593          	addi	a1,s0,-32
    8000565c:	4505                	li	a0,1
    8000565e:	ffffd097          	auipc	ra,0xffffd
    80005662:	78c080e7          	jalr	1932(ra) # 80002dea <argaddr>
    return -1;
    80005666:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005668:	00054b63          	bltz	a0,8000567e <sys_fstat+0x44>
  return filestat(f, st);
    8000566c:	fe043583          	ld	a1,-32(s0)
    80005670:	fe843503          	ld	a0,-24(s0)
    80005674:	fffff097          	auipc	ra,0xfffff
    80005678:	2aa080e7          	jalr	682(ra) # 8000491e <filestat>
    8000567c:	87aa                	mv	a5,a0
}
    8000567e:	853e                	mv	a0,a5
    80005680:	60e2                	ld	ra,24(sp)
    80005682:	6442                	ld	s0,16(sp)
    80005684:	6105                	addi	sp,sp,32
    80005686:	8082                	ret

0000000080005688 <sys_link>:
{
    80005688:	7169                	addi	sp,sp,-304
    8000568a:	f606                	sd	ra,296(sp)
    8000568c:	f222                	sd	s0,288(sp)
    8000568e:	ee26                	sd	s1,280(sp)
    80005690:	ea4a                	sd	s2,272(sp)
    80005692:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005694:	08000613          	li	a2,128
    80005698:	ed040593          	addi	a1,s0,-304
    8000569c:	4501                	li	a0,0
    8000569e:	ffffd097          	auipc	ra,0xffffd
    800056a2:	76e080e7          	jalr	1902(ra) # 80002e0c <argstr>
    return -1;
    800056a6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056a8:	10054e63          	bltz	a0,800057c4 <sys_link+0x13c>
    800056ac:	08000613          	li	a2,128
    800056b0:	f5040593          	addi	a1,s0,-176
    800056b4:	4505                	li	a0,1
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	756080e7          	jalr	1878(ra) # 80002e0c <argstr>
    return -1;
    800056be:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056c0:	10054263          	bltz	a0,800057c4 <sys_link+0x13c>
  begin_op();
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	c90080e7          	jalr	-880(ra) # 80004354 <begin_op>
  if((ip = namei(old)) == 0){
    800056cc:	ed040513          	addi	a0,s0,-304
    800056d0:	fffff097          	auipc	ra,0xfffff
    800056d4:	a76080e7          	jalr	-1418(ra) # 80004146 <namei>
    800056d8:	84aa                	mv	s1,a0
    800056da:	c551                	beqz	a0,80005766 <sys_link+0xde>
  ilock(ip);
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	2ac080e7          	jalr	684(ra) # 80003988 <ilock>
  if(ip->type == T_DIR){
    800056e4:	04449703          	lh	a4,68(s1)
    800056e8:	4785                	li	a5,1
    800056ea:	08f70463          	beq	a4,a5,80005772 <sys_link+0xea>
  ip->nlink++;
    800056ee:	04a4d783          	lhu	a5,74(s1)
    800056f2:	2785                	addiw	a5,a5,1
    800056f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056f8:	8526                	mv	a0,s1
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	1c2080e7          	jalr	450(ra) # 800038bc <iupdate>
  iunlock(ip);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	348080e7          	jalr	840(ra) # 80003a4c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000570c:	fd040593          	addi	a1,s0,-48
    80005710:	f5040513          	addi	a0,s0,-176
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	a50080e7          	jalr	-1456(ra) # 80004164 <nameiparent>
    8000571c:	892a                	mv	s2,a0
    8000571e:	c935                	beqz	a0,80005792 <sys_link+0x10a>
  ilock(dp);
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	268080e7          	jalr	616(ra) # 80003988 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005728:	00092703          	lw	a4,0(s2)
    8000572c:	409c                	lw	a5,0(s1)
    8000572e:	04f71d63          	bne	a4,a5,80005788 <sys_link+0x100>
    80005732:	40d0                	lw	a2,4(s1)
    80005734:	fd040593          	addi	a1,s0,-48
    80005738:	854a                	mv	a0,s2
    8000573a:	fffff097          	auipc	ra,0xfffff
    8000573e:	94a080e7          	jalr	-1718(ra) # 80004084 <dirlink>
    80005742:	04054363          	bltz	a0,80005788 <sys_link+0x100>
  iunlockput(dp);
    80005746:	854a                	mv	a0,s2
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	4a4080e7          	jalr	1188(ra) # 80003bec <iunlockput>
  iput(ip);
    80005750:	8526                	mv	a0,s1
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	3f2080e7          	jalr	1010(ra) # 80003b44 <iput>
  end_op();
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	c7a080e7          	jalr	-902(ra) # 800043d4 <end_op>
  return 0;
    80005762:	4781                	li	a5,0
    80005764:	a085                	j	800057c4 <sys_link+0x13c>
    end_op();
    80005766:	fffff097          	auipc	ra,0xfffff
    8000576a:	c6e080e7          	jalr	-914(ra) # 800043d4 <end_op>
    return -1;
    8000576e:	57fd                	li	a5,-1
    80005770:	a891                	j	800057c4 <sys_link+0x13c>
    iunlockput(ip);
    80005772:	8526                	mv	a0,s1
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	478080e7          	jalr	1144(ra) # 80003bec <iunlockput>
    end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	c58080e7          	jalr	-936(ra) # 800043d4 <end_op>
    return -1;
    80005784:	57fd                	li	a5,-1
    80005786:	a83d                	j	800057c4 <sys_link+0x13c>
    iunlockput(dp);
    80005788:	854a                	mv	a0,s2
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	462080e7          	jalr	1122(ra) # 80003bec <iunlockput>
  ilock(ip);
    80005792:	8526                	mv	a0,s1
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	1f4080e7          	jalr	500(ra) # 80003988 <ilock>
  ip->nlink--;
    8000579c:	04a4d783          	lhu	a5,74(s1)
    800057a0:	37fd                	addiw	a5,a5,-1
    800057a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057a6:	8526                	mv	a0,s1
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	114080e7          	jalr	276(ra) # 800038bc <iupdate>
  iunlockput(ip);
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	43a080e7          	jalr	1082(ra) # 80003bec <iunlockput>
  end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	c1a080e7          	jalr	-998(ra) # 800043d4 <end_op>
  return -1;
    800057c2:	57fd                	li	a5,-1
}
    800057c4:	853e                	mv	a0,a5
    800057c6:	70b2                	ld	ra,296(sp)
    800057c8:	7412                	ld	s0,288(sp)
    800057ca:	64f2                	ld	s1,280(sp)
    800057cc:	6952                	ld	s2,272(sp)
    800057ce:	6155                	addi	sp,sp,304
    800057d0:	8082                	ret

00000000800057d2 <sys_unlink>:
{
    800057d2:	7151                	addi	sp,sp,-240
    800057d4:	f586                	sd	ra,232(sp)
    800057d6:	f1a2                	sd	s0,224(sp)
    800057d8:	eda6                	sd	s1,216(sp)
    800057da:	e9ca                	sd	s2,208(sp)
    800057dc:	e5ce                	sd	s3,200(sp)
    800057de:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057e0:	08000613          	li	a2,128
    800057e4:	f3040593          	addi	a1,s0,-208
    800057e8:	4501                	li	a0,0
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	622080e7          	jalr	1570(ra) # 80002e0c <argstr>
    800057f2:	16054f63          	bltz	a0,80005970 <sys_unlink+0x19e>
  begin_op();
    800057f6:	fffff097          	auipc	ra,0xfffff
    800057fa:	b5e080e7          	jalr	-1186(ra) # 80004354 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057fe:	fb040593          	addi	a1,s0,-80
    80005802:	f3040513          	addi	a0,s0,-208
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	95e080e7          	jalr	-1698(ra) # 80004164 <nameiparent>
    8000580e:	89aa                	mv	s3,a0
    80005810:	c979                	beqz	a0,800058e6 <sys_unlink+0x114>
  ilock(dp);
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	176080e7          	jalr	374(ra) # 80003988 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000581a:	00003597          	auipc	a1,0x3
    8000581e:	ee658593          	addi	a1,a1,-282 # 80008700 <syscalls+0x2e8>
    80005822:	fb040513          	addi	a0,s0,-80
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	62c080e7          	jalr	1580(ra) # 80003e52 <namecmp>
    8000582e:	14050863          	beqz	a0,8000597e <sys_unlink+0x1ac>
    80005832:	00003597          	auipc	a1,0x3
    80005836:	ed658593          	addi	a1,a1,-298 # 80008708 <syscalls+0x2f0>
    8000583a:	fb040513          	addi	a0,s0,-80
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	614080e7          	jalr	1556(ra) # 80003e52 <namecmp>
    80005846:	12050c63          	beqz	a0,8000597e <sys_unlink+0x1ac>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000584a:	f2c40613          	addi	a2,s0,-212
    8000584e:	fb040593          	addi	a1,s0,-80
    80005852:	854e                	mv	a0,s3
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	618080e7          	jalr	1560(ra) # 80003e6c <dirlookup>
    8000585c:	84aa                	mv	s1,a0
    8000585e:	12050063          	beqz	a0,8000597e <sys_unlink+0x1ac>
  ilock(ip);
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	126080e7          	jalr	294(ra) # 80003988 <ilock>
  if(ip->nlink < 1)
    8000586a:	04a49783          	lh	a5,74(s1)
    8000586e:	08f05263          	blez	a5,800058f2 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005872:	04449703          	lh	a4,68(s1)
    80005876:	4785                	li	a5,1
    80005878:	08f70563          	beq	a4,a5,80005902 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000587c:	4641                	li	a2,16
    8000587e:	4581                	li	a1,0
    80005880:	fc040513          	addi	a0,s0,-64
    80005884:	ffffb097          	auipc	ra,0xffffb
    80005888:	61a080e7          	jalr	1562(ra) # 80000e9e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000588c:	4741                	li	a4,16
    8000588e:	f2c42683          	lw	a3,-212(s0)
    80005892:	fc040613          	addi	a2,s0,-64
    80005896:	4581                	li	a1,0
    80005898:	854e                	mv	a0,s3
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	49c080e7          	jalr	1180(ra) # 80003d36 <writei>
    800058a2:	47c1                	li	a5,16
    800058a4:	0af51363          	bne	a0,a5,8000594a <sys_unlink+0x178>
  if(ip->type == T_DIR){
    800058a8:	04449703          	lh	a4,68(s1)
    800058ac:	4785                	li	a5,1
    800058ae:	0af70663          	beq	a4,a5,8000595a <sys_unlink+0x188>
  iunlockput(dp);
    800058b2:	854e                	mv	a0,s3
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	338080e7          	jalr	824(ra) # 80003bec <iunlockput>
  ip->nlink--;
    800058bc:	04a4d783          	lhu	a5,74(s1)
    800058c0:	37fd                	addiw	a5,a5,-1
    800058c2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058c6:	8526                	mv	a0,s1
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	ff4080e7          	jalr	-12(ra) # 800038bc <iupdate>
  iunlockput(ip);
    800058d0:	8526                	mv	a0,s1
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	31a080e7          	jalr	794(ra) # 80003bec <iunlockput>
  end_op();
    800058da:	fffff097          	auipc	ra,0xfffff
    800058de:	afa080e7          	jalr	-1286(ra) # 800043d4 <end_op>
  return 0;
    800058e2:	4501                	li	a0,0
    800058e4:	a07d                	j	80005992 <sys_unlink+0x1c0>
    end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	aee080e7          	jalr	-1298(ra) # 800043d4 <end_op>
    return -1;
    800058ee:	557d                	li	a0,-1
    800058f0:	a04d                	j	80005992 <sys_unlink+0x1c0>
    panic("unlink: nlink < 1");
    800058f2:	00003517          	auipc	a0,0x3
    800058f6:	e3e50513          	addi	a0,a0,-450 # 80008730 <syscalls+0x318>
    800058fa:	ffffb097          	auipc	ra,0xffffb
    800058fe:	c7a080e7          	jalr	-902(ra) # 80000574 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005902:	44f8                	lw	a4,76(s1)
    80005904:	02000793          	li	a5,32
    80005908:	f6e7fae3          	bleu	a4,a5,8000587c <sys_unlink+0xaa>
    8000590c:	02000913          	li	s2,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005910:	4741                	li	a4,16
    80005912:	86ca                	mv	a3,s2
    80005914:	f1840613          	addi	a2,s0,-232
    80005918:	4581                	li	a1,0
    8000591a:	8526                	mv	a0,s1
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	322080e7          	jalr	802(ra) # 80003c3e <readi>
    80005924:	47c1                	li	a5,16
    80005926:	00f51a63          	bne	a0,a5,8000593a <sys_unlink+0x168>
    if(de.inum != 0)
    8000592a:	f1845783          	lhu	a5,-232(s0)
    8000592e:	e3b9                	bnez	a5,80005974 <sys_unlink+0x1a2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005930:	2941                	addiw	s2,s2,16
    80005932:	44fc                	lw	a5,76(s1)
    80005934:	fcf96ee3          	bltu	s2,a5,80005910 <sys_unlink+0x13e>
    80005938:	b791                	j	8000587c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000593a:	00003517          	auipc	a0,0x3
    8000593e:	e0e50513          	addi	a0,a0,-498 # 80008748 <syscalls+0x330>
    80005942:	ffffb097          	auipc	ra,0xffffb
    80005946:	c32080e7          	jalr	-974(ra) # 80000574 <panic>
    panic("unlink: writei");
    8000594a:	00003517          	auipc	a0,0x3
    8000594e:	e1650513          	addi	a0,a0,-490 # 80008760 <syscalls+0x348>
    80005952:	ffffb097          	auipc	ra,0xffffb
    80005956:	c22080e7          	jalr	-990(ra) # 80000574 <panic>
    dp->nlink--;
    8000595a:	04a9d783          	lhu	a5,74(s3)
    8000595e:	37fd                	addiw	a5,a5,-1
    80005960:	04f99523          	sh	a5,74(s3)
    iupdate(dp);
    80005964:	854e                	mv	a0,s3
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	f56080e7          	jalr	-170(ra) # 800038bc <iupdate>
    8000596e:	b791                	j	800058b2 <sys_unlink+0xe0>
    return -1;
    80005970:	557d                	li	a0,-1
    80005972:	a005                	j	80005992 <sys_unlink+0x1c0>
    iunlockput(ip);
    80005974:	8526                	mv	a0,s1
    80005976:	ffffe097          	auipc	ra,0xffffe
    8000597a:	276080e7          	jalr	630(ra) # 80003bec <iunlockput>
  iunlockput(dp);
    8000597e:	854e                	mv	a0,s3
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	26c080e7          	jalr	620(ra) # 80003bec <iunlockput>
  end_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	a4c080e7          	jalr	-1460(ra) # 800043d4 <end_op>
  return -1;
    80005990:	557d                	li	a0,-1
}
    80005992:	70ae                	ld	ra,232(sp)
    80005994:	740e                	ld	s0,224(sp)
    80005996:	64ee                	ld	s1,216(sp)
    80005998:	694e                	ld	s2,208(sp)
    8000599a:	69ae                	ld	s3,200(sp)
    8000599c:	616d                	addi	sp,sp,240
    8000599e:	8082                	ret

00000000800059a0 <sys_open>:

uint64
sys_open(void)
{
    800059a0:	7131                	addi	sp,sp,-192
    800059a2:	fd06                	sd	ra,184(sp)
    800059a4:	f922                	sd	s0,176(sp)
    800059a6:	f526                	sd	s1,168(sp)
    800059a8:	f14a                	sd	s2,160(sp)
    800059aa:	ed4e                	sd	s3,152(sp)
    800059ac:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059ae:	08000613          	li	a2,128
    800059b2:	f5040593          	addi	a1,s0,-176
    800059b6:	4501                	li	a0,0
    800059b8:	ffffd097          	auipc	ra,0xffffd
    800059bc:	454080e7          	jalr	1108(ra) # 80002e0c <argstr>
    return -1;
    800059c0:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059c2:	0c054163          	bltz	a0,80005a84 <sys_open+0xe4>
    800059c6:	f4c40593          	addi	a1,s0,-180
    800059ca:	4505                	li	a0,1
    800059cc:	ffffd097          	auipc	ra,0xffffd
    800059d0:	3fc080e7          	jalr	1020(ra) # 80002dc8 <argint>
    800059d4:	0a054863          	bltz	a0,80005a84 <sys_open+0xe4>

  begin_op();
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	97c080e7          	jalr	-1668(ra) # 80004354 <begin_op>

  if(omode & O_CREATE){
    800059e0:	f4c42783          	lw	a5,-180(s0)
    800059e4:	2007f793          	andi	a5,a5,512
    800059e8:	cbdd                	beqz	a5,80005a9e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059ea:	4681                	li	a3,0
    800059ec:	4601                	li	a2,0
    800059ee:	4589                	li	a1,2
    800059f0:	f5040513          	addi	a0,s0,-176
    800059f4:	00000097          	auipc	ra,0x0
    800059f8:	976080e7          	jalr	-1674(ra) # 8000536a <create>
    800059fc:	892a                	mv	s2,a0
    if(ip == 0){
    800059fe:	c959                	beqz	a0,80005a94 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a00:	04491703          	lh	a4,68(s2)
    80005a04:	478d                	li	a5,3
    80005a06:	00f71763          	bne	a4,a5,80005a14 <sys_open+0x74>
    80005a0a:	04695703          	lhu	a4,70(s2)
    80005a0e:	47a5                	li	a5,9
    80005a10:	0ce7ec63          	bltu	a5,a4,80005ae8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a14:	fffff097          	auipc	ra,0xfffff
    80005a18:	d72080e7          	jalr	-654(ra) # 80004786 <filealloc>
    80005a1c:	89aa                	mv	s3,a0
    80005a1e:	10050263          	beqz	a0,80005b22 <sys_open+0x182>
    80005a22:	00000097          	auipc	ra,0x0
    80005a26:	900080e7          	jalr	-1792(ra) # 80005322 <fdalloc>
    80005a2a:	84aa                	mv	s1,a0
    80005a2c:	0e054663          	bltz	a0,80005b18 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a30:	04491703          	lh	a4,68(s2)
    80005a34:	478d                	li	a5,3
    80005a36:	0cf70463          	beq	a4,a5,80005afe <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a3a:	4789                	li	a5,2
    80005a3c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a40:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a44:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a48:	f4c42783          	lw	a5,-180(s0)
    80005a4c:	0017c713          	xori	a4,a5,1
    80005a50:	8b05                	andi	a4,a4,1
    80005a52:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a56:	0037f713          	andi	a4,a5,3
    80005a5a:	00e03733          	snez	a4,a4
    80005a5e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a62:	4007f793          	andi	a5,a5,1024
    80005a66:	c791                	beqz	a5,80005a72 <sys_open+0xd2>
    80005a68:	04491703          	lh	a4,68(s2)
    80005a6c:	4789                	li	a5,2
    80005a6e:	08f70f63          	beq	a4,a5,80005b0c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a72:	854a                	mv	a0,s2
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	fd8080e7          	jalr	-40(ra) # 80003a4c <iunlock>
  end_op();
    80005a7c:	fffff097          	auipc	ra,0xfffff
    80005a80:	958080e7          	jalr	-1704(ra) # 800043d4 <end_op>

  return fd;
}
    80005a84:	8526                	mv	a0,s1
    80005a86:	70ea                	ld	ra,184(sp)
    80005a88:	744a                	ld	s0,176(sp)
    80005a8a:	74aa                	ld	s1,168(sp)
    80005a8c:	790a                	ld	s2,160(sp)
    80005a8e:	69ea                	ld	s3,152(sp)
    80005a90:	6129                	addi	sp,sp,192
    80005a92:	8082                	ret
      end_op();
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	940080e7          	jalr	-1728(ra) # 800043d4 <end_op>
      return -1;
    80005a9c:	b7e5                	j	80005a84 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a9e:	f5040513          	addi	a0,s0,-176
    80005aa2:	ffffe097          	auipc	ra,0xffffe
    80005aa6:	6a4080e7          	jalr	1700(ra) # 80004146 <namei>
    80005aaa:	892a                	mv	s2,a0
    80005aac:	c905                	beqz	a0,80005adc <sys_open+0x13c>
    ilock(ip);
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	eda080e7          	jalr	-294(ra) # 80003988 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ab6:	04491703          	lh	a4,68(s2)
    80005aba:	4785                	li	a5,1
    80005abc:	f4f712e3          	bne	a4,a5,80005a00 <sys_open+0x60>
    80005ac0:	f4c42783          	lw	a5,-180(s0)
    80005ac4:	dba1                	beqz	a5,80005a14 <sys_open+0x74>
      iunlockput(ip);
    80005ac6:	854a                	mv	a0,s2
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	124080e7          	jalr	292(ra) # 80003bec <iunlockput>
      end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	904080e7          	jalr	-1788(ra) # 800043d4 <end_op>
      return -1;
    80005ad8:	54fd                	li	s1,-1
    80005ada:	b76d                	j	80005a84 <sys_open+0xe4>
      end_op();
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	8f8080e7          	jalr	-1800(ra) # 800043d4 <end_op>
      return -1;
    80005ae4:	54fd                	li	s1,-1
    80005ae6:	bf79                	j	80005a84 <sys_open+0xe4>
    iunlockput(ip);
    80005ae8:	854a                	mv	a0,s2
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	102080e7          	jalr	258(ra) # 80003bec <iunlockput>
    end_op();
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	8e2080e7          	jalr	-1822(ra) # 800043d4 <end_op>
    return -1;
    80005afa:	54fd                	li	s1,-1
    80005afc:	b761                	j	80005a84 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005afe:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b02:	04691783          	lh	a5,70(s2)
    80005b06:	02f99223          	sh	a5,36(s3)
    80005b0a:	bf2d                	j	80005a44 <sys_open+0xa4>
    itrunc(ip);
    80005b0c:	854a                	mv	a0,s2
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	f8a080e7          	jalr	-118(ra) # 80003a98 <itrunc>
    80005b16:	bfb1                	j	80005a72 <sys_open+0xd2>
      fileclose(f);
    80005b18:	854e                	mv	a0,s3
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	d3c080e7          	jalr	-708(ra) # 80004856 <fileclose>
    iunlockput(ip);
    80005b22:	854a                	mv	a0,s2
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	0c8080e7          	jalr	200(ra) # 80003bec <iunlockput>
    end_op();
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	8a8080e7          	jalr	-1880(ra) # 800043d4 <end_op>
    return -1;
    80005b34:	54fd                	li	s1,-1
    80005b36:	b7b9                	j	80005a84 <sys_open+0xe4>

0000000080005b38 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b38:	7175                	addi	sp,sp,-144
    80005b3a:	e506                	sd	ra,136(sp)
    80005b3c:	e122                	sd	s0,128(sp)
    80005b3e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	814080e7          	jalr	-2028(ra) # 80004354 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b48:	08000613          	li	a2,128
    80005b4c:	f7040593          	addi	a1,s0,-144
    80005b50:	4501                	li	a0,0
    80005b52:	ffffd097          	auipc	ra,0xffffd
    80005b56:	2ba080e7          	jalr	698(ra) # 80002e0c <argstr>
    80005b5a:	02054963          	bltz	a0,80005b8c <sys_mkdir+0x54>
    80005b5e:	4681                	li	a3,0
    80005b60:	4601                	li	a2,0
    80005b62:	4585                	li	a1,1
    80005b64:	f7040513          	addi	a0,s0,-144
    80005b68:	00000097          	auipc	ra,0x0
    80005b6c:	802080e7          	jalr	-2046(ra) # 8000536a <create>
    80005b70:	cd11                	beqz	a0,80005b8c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	07a080e7          	jalr	122(ra) # 80003bec <iunlockput>
  end_op();
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	85a080e7          	jalr	-1958(ra) # 800043d4 <end_op>
  return 0;
    80005b82:	4501                	li	a0,0
}
    80005b84:	60aa                	ld	ra,136(sp)
    80005b86:	640a                	ld	s0,128(sp)
    80005b88:	6149                	addi	sp,sp,144
    80005b8a:	8082                	ret
    end_op();
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	848080e7          	jalr	-1976(ra) # 800043d4 <end_op>
    return -1;
    80005b94:	557d                	li	a0,-1
    80005b96:	b7fd                	j	80005b84 <sys_mkdir+0x4c>

0000000080005b98 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b98:	7135                	addi	sp,sp,-160
    80005b9a:	ed06                	sd	ra,152(sp)
    80005b9c:	e922                	sd	s0,144(sp)
    80005b9e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ba0:	ffffe097          	auipc	ra,0xffffe
    80005ba4:	7b4080e7          	jalr	1972(ra) # 80004354 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ba8:	08000613          	li	a2,128
    80005bac:	f7040593          	addi	a1,s0,-144
    80005bb0:	4501                	li	a0,0
    80005bb2:	ffffd097          	auipc	ra,0xffffd
    80005bb6:	25a080e7          	jalr	602(ra) # 80002e0c <argstr>
    80005bba:	04054a63          	bltz	a0,80005c0e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005bbe:	f6c40593          	addi	a1,s0,-148
    80005bc2:	4505                	li	a0,1
    80005bc4:	ffffd097          	auipc	ra,0xffffd
    80005bc8:	204080e7          	jalr	516(ra) # 80002dc8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bcc:	04054163          	bltz	a0,80005c0e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005bd0:	f6840593          	addi	a1,s0,-152
    80005bd4:	4509                	li	a0,2
    80005bd6:	ffffd097          	auipc	ra,0xffffd
    80005bda:	1f2080e7          	jalr	498(ra) # 80002dc8 <argint>
     argint(1, &major) < 0 ||
    80005bde:	02054863          	bltz	a0,80005c0e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005be2:	f6841683          	lh	a3,-152(s0)
    80005be6:	f6c41603          	lh	a2,-148(s0)
    80005bea:	458d                	li	a1,3
    80005bec:	f7040513          	addi	a0,s0,-144
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	77a080e7          	jalr	1914(ra) # 8000536a <create>
     argint(2, &minor) < 0 ||
    80005bf8:	c919                	beqz	a0,80005c0e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	ff2080e7          	jalr	-14(ra) # 80003bec <iunlockput>
  end_op();
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	7d2080e7          	jalr	2002(ra) # 800043d4 <end_op>
  return 0;
    80005c0a:	4501                	li	a0,0
    80005c0c:	a031                	j	80005c18 <sys_mknod+0x80>
    end_op();
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	7c6080e7          	jalr	1990(ra) # 800043d4 <end_op>
    return -1;
    80005c16:	557d                	li	a0,-1
}
    80005c18:	60ea                	ld	ra,152(sp)
    80005c1a:	644a                	ld	s0,144(sp)
    80005c1c:	610d                	addi	sp,sp,160
    80005c1e:	8082                	ret

0000000080005c20 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c20:	7135                	addi	sp,sp,-160
    80005c22:	ed06                	sd	ra,152(sp)
    80005c24:	e922                	sd	s0,144(sp)
    80005c26:	e526                	sd	s1,136(sp)
    80005c28:	e14a                	sd	s2,128(sp)
    80005c2a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c2c:	ffffc097          	auipc	ra,0xffffc
    80005c30:	0a0080e7          	jalr	160(ra) # 80001ccc <myproc>
    80005c34:	892a                	mv	s2,a0
  
  begin_op();
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	71e080e7          	jalr	1822(ra) # 80004354 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c3e:	08000613          	li	a2,128
    80005c42:	f6040593          	addi	a1,s0,-160
    80005c46:	4501                	li	a0,0
    80005c48:	ffffd097          	auipc	ra,0xffffd
    80005c4c:	1c4080e7          	jalr	452(ra) # 80002e0c <argstr>
    80005c50:	04054b63          	bltz	a0,80005ca6 <sys_chdir+0x86>
    80005c54:	f6040513          	addi	a0,s0,-160
    80005c58:	ffffe097          	auipc	ra,0xffffe
    80005c5c:	4ee080e7          	jalr	1262(ra) # 80004146 <namei>
    80005c60:	84aa                	mv	s1,a0
    80005c62:	c131                	beqz	a0,80005ca6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c64:	ffffe097          	auipc	ra,0xffffe
    80005c68:	d24080e7          	jalr	-732(ra) # 80003988 <ilock>
  if(ip->type != T_DIR){
    80005c6c:	04449703          	lh	a4,68(s1)
    80005c70:	4785                	li	a5,1
    80005c72:	04f71063          	bne	a4,a5,80005cb2 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c76:	8526                	mv	a0,s1
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	dd4080e7          	jalr	-556(ra) # 80003a4c <iunlock>
  iput(p->cwd);
    80005c80:	15093503          	ld	a0,336(s2)
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	ec0080e7          	jalr	-320(ra) # 80003b44 <iput>
  end_op();
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	748080e7          	jalr	1864(ra) # 800043d4 <end_op>
  p->cwd = ip;
    80005c94:	14993823          	sd	s1,336(s2)
  return 0;
    80005c98:	4501                	li	a0,0
}
    80005c9a:	60ea                	ld	ra,152(sp)
    80005c9c:	644a                	ld	s0,144(sp)
    80005c9e:	64aa                	ld	s1,136(sp)
    80005ca0:	690a                	ld	s2,128(sp)
    80005ca2:	610d                	addi	sp,sp,160
    80005ca4:	8082                	ret
    end_op();
    80005ca6:	ffffe097          	auipc	ra,0xffffe
    80005caa:	72e080e7          	jalr	1838(ra) # 800043d4 <end_op>
    return -1;
    80005cae:	557d                	li	a0,-1
    80005cb0:	b7ed                	j	80005c9a <sys_chdir+0x7a>
    iunlockput(ip);
    80005cb2:	8526                	mv	a0,s1
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	f38080e7          	jalr	-200(ra) # 80003bec <iunlockput>
    end_op();
    80005cbc:	ffffe097          	auipc	ra,0xffffe
    80005cc0:	718080e7          	jalr	1816(ra) # 800043d4 <end_op>
    return -1;
    80005cc4:	557d                	li	a0,-1
    80005cc6:	bfd1                	j	80005c9a <sys_chdir+0x7a>

0000000080005cc8 <sys_exec>:

uint64
sys_exec(void)
{
    80005cc8:	7145                	addi	sp,sp,-464
    80005cca:	e786                	sd	ra,456(sp)
    80005ccc:	e3a2                	sd	s0,448(sp)
    80005cce:	ff26                	sd	s1,440(sp)
    80005cd0:	fb4a                	sd	s2,432(sp)
    80005cd2:	f74e                	sd	s3,424(sp)
    80005cd4:	f352                	sd	s4,416(sp)
    80005cd6:	ef56                	sd	s5,408(sp)
    80005cd8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cda:	08000613          	li	a2,128
    80005cde:	f4040593          	addi	a1,s0,-192
    80005ce2:	4501                	li	a0,0
    80005ce4:	ffffd097          	auipc	ra,0xffffd
    80005ce8:	128080e7          	jalr	296(ra) # 80002e0c <argstr>
    return -1;
    80005cec:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cee:	0e054c63          	bltz	a0,80005de6 <sys_exec+0x11e>
    80005cf2:	e3840593          	addi	a1,s0,-456
    80005cf6:	4505                	li	a0,1
    80005cf8:	ffffd097          	auipc	ra,0xffffd
    80005cfc:	0f2080e7          	jalr	242(ra) # 80002dea <argaddr>
    80005d00:	0e054363          	bltz	a0,80005de6 <sys_exec+0x11e>
  }
  memset(argv, 0, sizeof(argv));
    80005d04:	e4040913          	addi	s2,s0,-448
    80005d08:	10000613          	li	a2,256
    80005d0c:	4581                	li	a1,0
    80005d0e:	854a                	mv	a0,s2
    80005d10:	ffffb097          	auipc	ra,0xffffb
    80005d14:	18e080e7          	jalr	398(ra) # 80000e9e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d18:	89ca                	mv	s3,s2
  memset(argv, 0, sizeof(argv));
    80005d1a:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    80005d1c:	02000a93          	li	s5,32
    80005d20:	00048a1b          	sext.w	s4,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d24:	00349513          	slli	a0,s1,0x3
    80005d28:	e3040593          	addi	a1,s0,-464
    80005d2c:	e3843783          	ld	a5,-456(s0)
    80005d30:	953e                	add	a0,a0,a5
    80005d32:	ffffd097          	auipc	ra,0xffffd
    80005d36:	ffa080e7          	jalr	-6(ra) # 80002d2c <fetchaddr>
    80005d3a:	02054a63          	bltz	a0,80005d6e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d3e:	e3043783          	ld	a5,-464(s0)
    80005d42:	cfa9                	beqz	a5,80005d9c <sys_exec+0xd4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d44:	ffffb097          	auipc	ra,0xffffb
    80005d48:	e94080e7          	jalr	-364(ra) # 80000bd8 <kalloc>
    80005d4c:	00a93023          	sd	a0,0(s2)
    if(argv[i] == 0)
    80005d50:	cd19                	beqz	a0,80005d6e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d52:	6605                	lui	a2,0x1
    80005d54:	85aa                	mv	a1,a0
    80005d56:	e3043503          	ld	a0,-464(s0)
    80005d5a:	ffffd097          	auipc	ra,0xffffd
    80005d5e:	026080e7          	jalr	38(ra) # 80002d80 <fetchstr>
    80005d62:	00054663          	bltz	a0,80005d6e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d66:	0485                	addi	s1,s1,1
    80005d68:	0921                	addi	s2,s2,8
    80005d6a:	fb549be3          	bne	s1,s5,80005d20 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d6e:	e4043503          	ld	a0,-448(s0)
    kfree(argv[i]);
  return -1;
    80005d72:	597d                	li	s2,-1
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d74:	c92d                	beqz	a0,80005de6 <sys_exec+0x11e>
    kfree(argv[i]);
    80005d76:	ffffb097          	auipc	ra,0xffffb
    80005d7a:	cfc080e7          	jalr	-772(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d7e:	e4840493          	addi	s1,s0,-440
    80005d82:	10098993          	addi	s3,s3,256
    80005d86:	6088                	ld	a0,0(s1)
    80005d88:	cd31                	beqz	a0,80005de4 <sys_exec+0x11c>
    kfree(argv[i]);
    80005d8a:	ffffb097          	auipc	ra,0xffffb
    80005d8e:	ce8080e7          	jalr	-792(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d92:	04a1                	addi	s1,s1,8
    80005d94:	ff3499e3          	bne	s1,s3,80005d86 <sys_exec+0xbe>
  return -1;
    80005d98:	597d                	li	s2,-1
    80005d9a:	a0b1                	j	80005de6 <sys_exec+0x11e>
      argv[i] = 0;
    80005d9c:	0a0e                	slli	s4,s4,0x3
    80005d9e:	fc040793          	addi	a5,s0,-64
    80005da2:	9a3e                	add	s4,s4,a5
    80005da4:	e80a3023          	sd	zero,-384(s4)
  int ret = exec(path, argv);
    80005da8:	e4040593          	addi	a1,s0,-448
    80005dac:	f4040513          	addi	a0,s0,-192
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	166080e7          	jalr	358(ra) # 80004f16 <exec>
    80005db8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dba:	e4043503          	ld	a0,-448(s0)
    80005dbe:	c505                	beqz	a0,80005de6 <sys_exec+0x11e>
    kfree(argv[i]);
    80005dc0:	ffffb097          	auipc	ra,0xffffb
    80005dc4:	cb2080e7          	jalr	-846(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dc8:	e4840493          	addi	s1,s0,-440
    80005dcc:	10098993          	addi	s3,s3,256
    80005dd0:	6088                	ld	a0,0(s1)
    80005dd2:	c911                	beqz	a0,80005de6 <sys_exec+0x11e>
    kfree(argv[i]);
    80005dd4:	ffffb097          	auipc	ra,0xffffb
    80005dd8:	c9e080e7          	jalr	-866(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ddc:	04a1                	addi	s1,s1,8
    80005dde:	ff3499e3          	bne	s1,s3,80005dd0 <sys_exec+0x108>
    80005de2:	a011                	j	80005de6 <sys_exec+0x11e>
  return -1;
    80005de4:	597d                	li	s2,-1
}
    80005de6:	854a                	mv	a0,s2
    80005de8:	60be                	ld	ra,456(sp)
    80005dea:	641e                	ld	s0,448(sp)
    80005dec:	74fa                	ld	s1,440(sp)
    80005dee:	795a                	ld	s2,432(sp)
    80005df0:	79ba                	ld	s3,424(sp)
    80005df2:	7a1a                	ld	s4,416(sp)
    80005df4:	6afa                	ld	s5,408(sp)
    80005df6:	6179                	addi	sp,sp,464
    80005df8:	8082                	ret

0000000080005dfa <sys_pipe>:

uint64
sys_pipe(void)
{
    80005dfa:	7139                	addi	sp,sp,-64
    80005dfc:	fc06                	sd	ra,56(sp)
    80005dfe:	f822                	sd	s0,48(sp)
    80005e00:	f426                	sd	s1,40(sp)
    80005e02:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e04:	ffffc097          	auipc	ra,0xffffc
    80005e08:	ec8080e7          	jalr	-312(ra) # 80001ccc <myproc>
    80005e0c:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e0e:	fd840593          	addi	a1,s0,-40
    80005e12:	4501                	li	a0,0
    80005e14:	ffffd097          	auipc	ra,0xffffd
    80005e18:	fd6080e7          	jalr	-42(ra) # 80002dea <argaddr>
    return -1;
    80005e1c:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e1e:	0c054f63          	bltz	a0,80005efc <sys_pipe+0x102>
  if(pipealloc(&rf, &wf) < 0)
    80005e22:	fc840593          	addi	a1,s0,-56
    80005e26:	fd040513          	addi	a0,s0,-48
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	d74080e7          	jalr	-652(ra) # 80004b9e <pipealloc>
    return -1;
    80005e32:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e34:	0c054463          	bltz	a0,80005efc <sys_pipe+0x102>
  fd0 = -1;
    80005e38:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e3c:	fd043503          	ld	a0,-48(s0)
    80005e40:	fffff097          	auipc	ra,0xfffff
    80005e44:	4e2080e7          	jalr	1250(ra) # 80005322 <fdalloc>
    80005e48:	fca42223          	sw	a0,-60(s0)
    80005e4c:	08054b63          	bltz	a0,80005ee2 <sys_pipe+0xe8>
    80005e50:	fc843503          	ld	a0,-56(s0)
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	4ce080e7          	jalr	1230(ra) # 80005322 <fdalloc>
    80005e5c:	fca42023          	sw	a0,-64(s0)
    80005e60:	06054863          	bltz	a0,80005ed0 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e64:	4691                	li	a3,4
    80005e66:	fc440613          	addi	a2,s0,-60
    80005e6a:	fd843583          	ld	a1,-40(s0)
    80005e6e:	68a8                	ld	a0,80(s1)
    80005e70:	ffffc097          	auipc	ra,0xffffc
    80005e74:	c50080e7          	jalr	-944(ra) # 80001ac0 <copyout>
    80005e78:	02054063          	bltz	a0,80005e98 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e7c:	4691                	li	a3,4
    80005e7e:	fc040613          	addi	a2,s0,-64
    80005e82:	fd843583          	ld	a1,-40(s0)
    80005e86:	0591                	addi	a1,a1,4
    80005e88:	68a8                	ld	a0,80(s1)
    80005e8a:	ffffc097          	auipc	ra,0xffffc
    80005e8e:	c36080e7          	jalr	-970(ra) # 80001ac0 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e92:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e94:	06055463          	bgez	a0,80005efc <sys_pipe+0x102>
    p->ofile[fd0] = 0;
    80005e98:	fc442783          	lw	a5,-60(s0)
    80005e9c:	07e9                	addi	a5,a5,26
    80005e9e:	078e                	slli	a5,a5,0x3
    80005ea0:	97a6                	add	a5,a5,s1
    80005ea2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005ea6:	fc042783          	lw	a5,-64(s0)
    80005eaa:	07e9                	addi	a5,a5,26
    80005eac:	078e                	slli	a5,a5,0x3
    80005eae:	94be                	add	s1,s1,a5
    80005eb0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005eb4:	fd043503          	ld	a0,-48(s0)
    80005eb8:	fffff097          	auipc	ra,0xfffff
    80005ebc:	99e080e7          	jalr	-1634(ra) # 80004856 <fileclose>
    fileclose(wf);
    80005ec0:	fc843503          	ld	a0,-56(s0)
    80005ec4:	fffff097          	auipc	ra,0xfffff
    80005ec8:	992080e7          	jalr	-1646(ra) # 80004856 <fileclose>
    return -1;
    80005ecc:	57fd                	li	a5,-1
    80005ece:	a03d                	j	80005efc <sys_pipe+0x102>
    if(fd0 >= 0)
    80005ed0:	fc442783          	lw	a5,-60(s0)
    80005ed4:	0007c763          	bltz	a5,80005ee2 <sys_pipe+0xe8>
      p->ofile[fd0] = 0;
    80005ed8:	07e9                	addi	a5,a5,26
    80005eda:	078e                	slli	a5,a5,0x3
    80005edc:	94be                	add	s1,s1,a5
    80005ede:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ee2:	fd043503          	ld	a0,-48(s0)
    80005ee6:	fffff097          	auipc	ra,0xfffff
    80005eea:	970080e7          	jalr	-1680(ra) # 80004856 <fileclose>
    fileclose(wf);
    80005eee:	fc843503          	ld	a0,-56(s0)
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	964080e7          	jalr	-1692(ra) # 80004856 <fileclose>
    return -1;
    80005efa:	57fd                	li	a5,-1
}
    80005efc:	853e                	mv	a0,a5
    80005efe:	70e2                	ld	ra,56(sp)
    80005f00:	7442                	ld	s0,48(sp)
    80005f02:	74a2                	ld	s1,40(sp)
    80005f04:	6121                	addi	sp,sp,64
    80005f06:	8082                	ret
	...

0000000080005f10 <kernelvec>:
    80005f10:	7111                	addi	sp,sp,-256
    80005f12:	e006                	sd	ra,0(sp)
    80005f14:	e40a                	sd	sp,8(sp)
    80005f16:	e80e                	sd	gp,16(sp)
    80005f18:	ec12                	sd	tp,24(sp)
    80005f1a:	f016                	sd	t0,32(sp)
    80005f1c:	f41a                	sd	t1,40(sp)
    80005f1e:	f81e                	sd	t2,48(sp)
    80005f20:	fc22                	sd	s0,56(sp)
    80005f22:	e0a6                	sd	s1,64(sp)
    80005f24:	e4aa                	sd	a0,72(sp)
    80005f26:	e8ae                	sd	a1,80(sp)
    80005f28:	ecb2                	sd	a2,88(sp)
    80005f2a:	f0b6                	sd	a3,96(sp)
    80005f2c:	f4ba                	sd	a4,104(sp)
    80005f2e:	f8be                	sd	a5,112(sp)
    80005f30:	fcc2                	sd	a6,120(sp)
    80005f32:	e146                	sd	a7,128(sp)
    80005f34:	e54a                	sd	s2,136(sp)
    80005f36:	e94e                	sd	s3,144(sp)
    80005f38:	ed52                	sd	s4,152(sp)
    80005f3a:	f156                	sd	s5,160(sp)
    80005f3c:	f55a                	sd	s6,168(sp)
    80005f3e:	f95e                	sd	s7,176(sp)
    80005f40:	fd62                	sd	s8,184(sp)
    80005f42:	e1e6                	sd	s9,192(sp)
    80005f44:	e5ea                	sd	s10,200(sp)
    80005f46:	e9ee                	sd	s11,208(sp)
    80005f48:	edf2                	sd	t3,216(sp)
    80005f4a:	f1f6                	sd	t4,224(sp)
    80005f4c:	f5fa                	sd	t5,232(sp)
    80005f4e:	f9fe                	sd	t6,240(sp)
    80005f50:	ca5fc0ef          	jal	ra,80002bf4 <kerneltrap>
    80005f54:	6082                	ld	ra,0(sp)
    80005f56:	6122                	ld	sp,8(sp)
    80005f58:	61c2                	ld	gp,16(sp)
    80005f5a:	7282                	ld	t0,32(sp)
    80005f5c:	7322                	ld	t1,40(sp)
    80005f5e:	73c2                	ld	t2,48(sp)
    80005f60:	7462                	ld	s0,56(sp)
    80005f62:	6486                	ld	s1,64(sp)
    80005f64:	6526                	ld	a0,72(sp)
    80005f66:	65c6                	ld	a1,80(sp)
    80005f68:	6666                	ld	a2,88(sp)
    80005f6a:	7686                	ld	a3,96(sp)
    80005f6c:	7726                	ld	a4,104(sp)
    80005f6e:	77c6                	ld	a5,112(sp)
    80005f70:	7866                	ld	a6,120(sp)
    80005f72:	688a                	ld	a7,128(sp)
    80005f74:	692a                	ld	s2,136(sp)
    80005f76:	69ca                	ld	s3,144(sp)
    80005f78:	6a6a                	ld	s4,152(sp)
    80005f7a:	7a8a                	ld	s5,160(sp)
    80005f7c:	7b2a                	ld	s6,168(sp)
    80005f7e:	7bca                	ld	s7,176(sp)
    80005f80:	7c6a                	ld	s8,184(sp)
    80005f82:	6c8e                	ld	s9,192(sp)
    80005f84:	6d2e                	ld	s10,200(sp)
    80005f86:	6dce                	ld	s11,208(sp)
    80005f88:	6e6e                	ld	t3,216(sp)
    80005f8a:	7e8e                	ld	t4,224(sp)
    80005f8c:	7f2e                	ld	t5,232(sp)
    80005f8e:	7fce                	ld	t6,240(sp)
    80005f90:	6111                	addi	sp,sp,256
    80005f92:	10200073          	sret
    80005f96:	00000013          	nop
    80005f9a:	00000013          	nop
    80005f9e:	0001                	nop

0000000080005fa0 <timervec>:
    80005fa0:	34051573          	csrrw	a0,mscratch,a0
    80005fa4:	e10c                	sd	a1,0(a0)
    80005fa6:	e510                	sd	a2,8(a0)
    80005fa8:	e914                	sd	a3,16(a0)
    80005faa:	710c                	ld	a1,32(a0)
    80005fac:	7510                	ld	a2,40(a0)
    80005fae:	6194                	ld	a3,0(a1)
    80005fb0:	96b2                	add	a3,a3,a2
    80005fb2:	e194                	sd	a3,0(a1)
    80005fb4:	4589                	li	a1,2
    80005fb6:	14459073          	csrw	sip,a1
    80005fba:	6914                	ld	a3,16(a0)
    80005fbc:	6510                	ld	a2,8(a0)
    80005fbe:	610c                	ld	a1,0(a0)
    80005fc0:	34051573          	csrrw	a0,mscratch,a0
    80005fc4:	30200073          	mret
	...

0000000080005fca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fca:	1141                	addi	sp,sp,-16
    80005fcc:	e422                	sd	s0,8(sp)
    80005fce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fd0:	0c0007b7          	lui	a5,0xc000
    80005fd4:	4705                	li	a4,1
    80005fd6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fd8:	c3d8                	sw	a4,4(a5)
}
    80005fda:	6422                	ld	s0,8(sp)
    80005fdc:	0141                	addi	sp,sp,16
    80005fde:	8082                	ret

0000000080005fe0 <plicinithart>:

void
plicinithart(void)
{
    80005fe0:	1141                	addi	sp,sp,-16
    80005fe2:	e406                	sd	ra,8(sp)
    80005fe4:	e022                	sd	s0,0(sp)
    80005fe6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fe8:	ffffc097          	auipc	ra,0xffffc
    80005fec:	cb8080e7          	jalr	-840(ra) # 80001ca0 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ff0:	0085171b          	slliw	a4,a0,0x8
    80005ff4:	0c0027b7          	lui	a5,0xc002
    80005ff8:	97ba                	add	a5,a5,a4
    80005ffa:	40200713          	li	a4,1026
    80005ffe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006002:	00d5151b          	slliw	a0,a0,0xd
    80006006:	0c2017b7          	lui	a5,0xc201
    8000600a:	953e                	add	a0,a0,a5
    8000600c:	00052023          	sw	zero,0(a0)
}
    80006010:	60a2                	ld	ra,8(sp)
    80006012:	6402                	ld	s0,0(sp)
    80006014:	0141                	addi	sp,sp,16
    80006016:	8082                	ret

0000000080006018 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006018:	1141                	addi	sp,sp,-16
    8000601a:	e406                	sd	ra,8(sp)
    8000601c:	e022                	sd	s0,0(sp)
    8000601e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006020:	ffffc097          	auipc	ra,0xffffc
    80006024:	c80080e7          	jalr	-896(ra) # 80001ca0 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006028:	00d5151b          	slliw	a0,a0,0xd
    8000602c:	0c2017b7          	lui	a5,0xc201
    80006030:	97aa                	add	a5,a5,a0
  return irq;
}
    80006032:	43c8                	lw	a0,4(a5)
    80006034:	60a2                	ld	ra,8(sp)
    80006036:	6402                	ld	s0,0(sp)
    80006038:	0141                	addi	sp,sp,16
    8000603a:	8082                	ret

000000008000603c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000603c:	1101                	addi	sp,sp,-32
    8000603e:	ec06                	sd	ra,24(sp)
    80006040:	e822                	sd	s0,16(sp)
    80006042:	e426                	sd	s1,8(sp)
    80006044:	1000                	addi	s0,sp,32
    80006046:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006048:	ffffc097          	auipc	ra,0xffffc
    8000604c:	c58080e7          	jalr	-936(ra) # 80001ca0 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006050:	00d5151b          	slliw	a0,a0,0xd
    80006054:	0c2017b7          	lui	a5,0xc201
    80006058:	97aa                	add	a5,a5,a0
    8000605a:	c3c4                	sw	s1,4(a5)
}
    8000605c:	60e2                	ld	ra,24(sp)
    8000605e:	6442                	ld	s0,16(sp)
    80006060:	64a2                	ld	s1,8(sp)
    80006062:	6105                	addi	sp,sp,32
    80006064:	8082                	ret

0000000080006066 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006066:	1141                	addi	sp,sp,-16
    80006068:	e406                	sd	ra,8(sp)
    8000606a:	e022                	sd	s0,0(sp)
    8000606c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000606e:	479d                	li	a5,7
    80006070:	04a7cd63          	blt	a5,a0,800060ca <free_desc+0x64>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80006074:	0005d797          	auipc	a5,0x5d
    80006078:	f8c78793          	addi	a5,a5,-116 # 80063000 <disk>
    8000607c:	00a78733          	add	a4,a5,a0
    80006080:	6789                	lui	a5,0x2
    80006082:	97ba                	add	a5,a5,a4
    80006084:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006088:	eba9                	bnez	a5,800060da <free_desc+0x74>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000608a:	0005f797          	auipc	a5,0x5f
    8000608e:	f7678793          	addi	a5,a5,-138 # 80065000 <disk+0x2000>
    80006092:	639c                	ld	a5,0(a5)
    80006094:	00451713          	slli	a4,a0,0x4
    80006098:	97ba                	add	a5,a5,a4
    8000609a:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000609e:	0005d797          	auipc	a5,0x5d
    800060a2:	f6278793          	addi	a5,a5,-158 # 80063000 <disk>
    800060a6:	97aa                	add	a5,a5,a0
    800060a8:	6509                	lui	a0,0x2
    800060aa:	953e                	add	a0,a0,a5
    800060ac:	4785                	li	a5,1
    800060ae:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800060b2:	0005f517          	auipc	a0,0x5f
    800060b6:	f6650513          	addi	a0,a0,-154 # 80065018 <disk+0x2018>
    800060ba:	ffffc097          	auipc	ra,0xffffc
    800060be:	5b2080e7          	jalr	1458(ra) # 8000266c <wakeup>
}
    800060c2:	60a2                	ld	ra,8(sp)
    800060c4:	6402                	ld	s0,0(sp)
    800060c6:	0141                	addi	sp,sp,16
    800060c8:	8082                	ret
    panic("virtio_disk_intr 1");
    800060ca:	00002517          	auipc	a0,0x2
    800060ce:	6a650513          	addi	a0,a0,1702 # 80008770 <syscalls+0x358>
    800060d2:	ffffa097          	auipc	ra,0xffffa
    800060d6:	4a2080e7          	jalr	1186(ra) # 80000574 <panic>
    panic("virtio_disk_intr 2");
    800060da:	00002517          	auipc	a0,0x2
    800060de:	6ae50513          	addi	a0,a0,1710 # 80008788 <syscalls+0x370>
    800060e2:	ffffa097          	auipc	ra,0xffffa
    800060e6:	492080e7          	jalr	1170(ra) # 80000574 <panic>

00000000800060ea <virtio_disk_init>:
{
    800060ea:	1101                	addi	sp,sp,-32
    800060ec:	ec06                	sd	ra,24(sp)
    800060ee:	e822                	sd	s0,16(sp)
    800060f0:	e426                	sd	s1,8(sp)
    800060f2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060f4:	00002597          	auipc	a1,0x2
    800060f8:	6ac58593          	addi	a1,a1,1708 # 800087a0 <syscalls+0x388>
    800060fc:	0005f517          	auipc	a0,0x5f
    80006100:	fac50513          	addi	a0,a0,-84 # 800650a8 <disk+0x20a8>
    80006104:	ffffb097          	auipc	ra,0xffffb
    80006108:	c0e080e7          	jalr	-1010(ra) # 80000d12 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000610c:	100017b7          	lui	a5,0x10001
    80006110:	4398                	lw	a4,0(a5)
    80006112:	2701                	sext.w	a4,a4
    80006114:	747277b7          	lui	a5,0x74727
    80006118:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000611c:	0ef71163          	bne	a4,a5,800061fe <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006120:	100017b7          	lui	a5,0x10001
    80006124:	43dc                	lw	a5,4(a5)
    80006126:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006128:	4705                	li	a4,1
    8000612a:	0ce79a63          	bne	a5,a4,800061fe <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000612e:	100017b7          	lui	a5,0x10001
    80006132:	479c                	lw	a5,8(a5)
    80006134:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006136:	4709                	li	a4,2
    80006138:	0ce79363          	bne	a5,a4,800061fe <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000613c:	100017b7          	lui	a5,0x10001
    80006140:	47d8                	lw	a4,12(a5)
    80006142:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006144:	554d47b7          	lui	a5,0x554d4
    80006148:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000614c:	0af71963          	bne	a4,a5,800061fe <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006150:	100017b7          	lui	a5,0x10001
    80006154:	4705                	li	a4,1
    80006156:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006158:	470d                	li	a4,3
    8000615a:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000615c:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000615e:	c7ffe737          	lui	a4,0xc7ffe
    80006162:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47f9875f>
    80006166:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006168:	2701                	sext.w	a4,a4
    8000616a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000616c:	472d                	li	a4,11
    8000616e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006170:	473d                	li	a4,15
    80006172:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006174:	6705                	lui	a4,0x1
    80006176:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006178:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000617c:	5bdc                	lw	a5,52(a5)
    8000617e:	2781                	sext.w	a5,a5
  if(max == 0)
    80006180:	c7d9                	beqz	a5,8000620e <virtio_disk_init+0x124>
  if(max < NUM)
    80006182:	471d                	li	a4,7
    80006184:	08f77d63          	bleu	a5,a4,8000621e <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006188:	100014b7          	lui	s1,0x10001
    8000618c:	47a1                	li	a5,8
    8000618e:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006190:	6609                	lui	a2,0x2
    80006192:	4581                	li	a1,0
    80006194:	0005d517          	auipc	a0,0x5d
    80006198:	e6c50513          	addi	a0,a0,-404 # 80063000 <disk>
    8000619c:	ffffb097          	auipc	ra,0xffffb
    800061a0:	d02080e7          	jalr	-766(ra) # 80000e9e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800061a4:	0005d717          	auipc	a4,0x5d
    800061a8:	e5c70713          	addi	a4,a4,-420 # 80063000 <disk>
    800061ac:	00c75793          	srli	a5,a4,0xc
    800061b0:	2781                	sext.w	a5,a5
    800061b2:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    800061b4:	0005f797          	auipc	a5,0x5f
    800061b8:	e4c78793          	addi	a5,a5,-436 # 80065000 <disk+0x2000>
    800061bc:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800061be:	0005d717          	auipc	a4,0x5d
    800061c2:	ec270713          	addi	a4,a4,-318 # 80063080 <disk+0x80>
    800061c6:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800061c8:	0005e717          	auipc	a4,0x5e
    800061cc:	e3870713          	addi	a4,a4,-456 # 80064000 <disk+0x1000>
    800061d0:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061d2:	4705                	li	a4,1
    800061d4:	00e78c23          	sb	a4,24(a5)
    800061d8:	00e78ca3          	sb	a4,25(a5)
    800061dc:	00e78d23          	sb	a4,26(a5)
    800061e0:	00e78da3          	sb	a4,27(a5)
    800061e4:	00e78e23          	sb	a4,28(a5)
    800061e8:	00e78ea3          	sb	a4,29(a5)
    800061ec:	00e78f23          	sb	a4,30(a5)
    800061f0:	00e78fa3          	sb	a4,31(a5)
}
    800061f4:	60e2                	ld	ra,24(sp)
    800061f6:	6442                	ld	s0,16(sp)
    800061f8:	64a2                	ld	s1,8(sp)
    800061fa:	6105                	addi	sp,sp,32
    800061fc:	8082                	ret
    panic("could not find virtio disk");
    800061fe:	00002517          	auipc	a0,0x2
    80006202:	5b250513          	addi	a0,a0,1458 # 800087b0 <syscalls+0x398>
    80006206:	ffffa097          	auipc	ra,0xffffa
    8000620a:	36e080e7          	jalr	878(ra) # 80000574 <panic>
    panic("virtio disk has no queue 0");
    8000620e:	00002517          	auipc	a0,0x2
    80006212:	5c250513          	addi	a0,a0,1474 # 800087d0 <syscalls+0x3b8>
    80006216:	ffffa097          	auipc	ra,0xffffa
    8000621a:	35e080e7          	jalr	862(ra) # 80000574 <panic>
    panic("virtio disk max queue too short");
    8000621e:	00002517          	auipc	a0,0x2
    80006222:	5d250513          	addi	a0,a0,1490 # 800087f0 <syscalls+0x3d8>
    80006226:	ffffa097          	auipc	ra,0xffffa
    8000622a:	34e080e7          	jalr	846(ra) # 80000574 <panic>

000000008000622e <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000622e:	7159                	addi	sp,sp,-112
    80006230:	f486                	sd	ra,104(sp)
    80006232:	f0a2                	sd	s0,96(sp)
    80006234:	eca6                	sd	s1,88(sp)
    80006236:	e8ca                	sd	s2,80(sp)
    80006238:	e4ce                	sd	s3,72(sp)
    8000623a:	e0d2                	sd	s4,64(sp)
    8000623c:	fc56                	sd	s5,56(sp)
    8000623e:	f85a                	sd	s6,48(sp)
    80006240:	f45e                	sd	s7,40(sp)
    80006242:	f062                	sd	s8,32(sp)
    80006244:	1880                	addi	s0,sp,112
    80006246:	892a                	mv	s2,a0
    80006248:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000624a:	00c52b83          	lw	s7,12(a0)
    8000624e:	001b9b9b          	slliw	s7,s7,0x1
    80006252:	1b82                	slli	s7,s7,0x20
    80006254:	020bdb93          	srli	s7,s7,0x20

  acquire(&disk.vdisk_lock);
    80006258:	0005f517          	auipc	a0,0x5f
    8000625c:	e5050513          	addi	a0,a0,-432 # 800650a8 <disk+0x20a8>
    80006260:	ffffb097          	auipc	ra,0xffffb
    80006264:	b42080e7          	jalr	-1214(ra) # 80000da2 <acquire>
    if(disk.free[i]){
    80006268:	0005f997          	auipc	s3,0x5f
    8000626c:	d9898993          	addi	s3,s3,-616 # 80065000 <disk+0x2000>
  for(int i = 0; i < NUM; i++){
    80006270:	4b21                	li	s6,8
      disk.free[i] = 0;
    80006272:	0005da97          	auipc	s5,0x5d
    80006276:	d8ea8a93          	addi	s5,s5,-626 # 80063000 <disk>
  for(int i = 0; i < 3; i++){
    8000627a:	4a0d                	li	s4,3
    8000627c:	a079                	j	8000630a <virtio_disk_rw+0xdc>
      disk.free[i] = 0;
    8000627e:	00fa86b3          	add	a3,s5,a5
    80006282:	96ae                	add	a3,a3,a1
    80006284:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006288:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000628a:	0207ca63          	bltz	a5,800062be <virtio_disk_rw+0x90>
  for(int i = 0; i < 3; i++){
    8000628e:	2485                	addiw	s1,s1,1
    80006290:	0711                	addi	a4,a4,4
    80006292:	25448163          	beq	s1,s4,800064d4 <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006296:	863a                	mv	a2,a4
    if(disk.free[i]){
    80006298:	0189c783          	lbu	a5,24(s3)
    8000629c:	24079163          	bnez	a5,800064de <virtio_disk_rw+0x2b0>
    800062a0:	0005f697          	auipc	a3,0x5f
    800062a4:	d7968693          	addi	a3,a3,-647 # 80065019 <disk+0x2019>
  for(int i = 0; i < NUM; i++){
    800062a8:	87aa                	mv	a5,a0
    if(disk.free[i]){
    800062aa:	0006c803          	lbu	a6,0(a3)
    800062ae:	fc0818e3          	bnez	a6,8000627e <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    800062b2:	2785                	addiw	a5,a5,1
    800062b4:	0685                	addi	a3,a3,1
    800062b6:	ff679ae3          	bne	a5,s6,800062aa <virtio_disk_rw+0x7c>
    idx[i] = alloc_desc();
    800062ba:	57fd                	li	a5,-1
    800062bc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800062be:	02905a63          	blez	s1,800062f2 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800062c2:	fa042503          	lw	a0,-96(s0)
    800062c6:	00000097          	auipc	ra,0x0
    800062ca:	da0080e7          	jalr	-608(ra) # 80006066 <free_desc>
      for(int j = 0; j < i; j++)
    800062ce:	4785                	li	a5,1
    800062d0:	0297d163          	ble	s1,a5,800062f2 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800062d4:	fa442503          	lw	a0,-92(s0)
    800062d8:	00000097          	auipc	ra,0x0
    800062dc:	d8e080e7          	jalr	-626(ra) # 80006066 <free_desc>
      for(int j = 0; j < i; j++)
    800062e0:	4789                	li	a5,2
    800062e2:	0097d863          	ble	s1,a5,800062f2 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800062e6:	fa842503          	lw	a0,-88(s0)
    800062ea:	00000097          	auipc	ra,0x0
    800062ee:	d7c080e7          	jalr	-644(ra) # 80006066 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062f2:	0005f597          	auipc	a1,0x5f
    800062f6:	db658593          	addi	a1,a1,-586 # 800650a8 <disk+0x20a8>
    800062fa:	0005f517          	auipc	a0,0x5f
    800062fe:	d1e50513          	addi	a0,a0,-738 # 80065018 <disk+0x2018>
    80006302:	ffffc097          	auipc	ra,0xffffc
    80006306:	1e4080e7          	jalr	484(ra) # 800024e6 <sleep>
  for(int i = 0; i < 3; i++){
    8000630a:	fa040713          	addi	a4,s0,-96
    8000630e:	4481                	li	s1,0
  for(int i = 0; i < NUM; i++){
    80006310:	4505                	li	a0,1
      disk.free[i] = 0;
    80006312:	6589                	lui	a1,0x2
    80006314:	b749                	j	80006296 <virtio_disk_rw+0x68>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006316:	4785                	li	a5,1
    80006318:	f8f42823          	sw	a5,-112(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000631c:	f8042a23          	sw	zero,-108(s0)
  buf0.sector = sector;
    80006320:	f9743c23          	sd	s7,-104(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006324:	fa042983          	lw	s3,-96(s0)
    80006328:	00499493          	slli	s1,s3,0x4
    8000632c:	0005fa17          	auipc	s4,0x5f
    80006330:	cd4a0a13          	addi	s4,s4,-812 # 80065000 <disk+0x2000>
    80006334:	000a3a83          	ld	s5,0(s4)
    80006338:	9aa6                	add	s5,s5,s1
    8000633a:	f9040513          	addi	a0,s0,-112
    8000633e:	ffffb097          	auipc	ra,0xffffb
    80006342:	f58080e7          	jalr	-168(ra) # 80001296 <kvmpa>
    80006346:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000634a:	000a3783          	ld	a5,0(s4)
    8000634e:	97a6                	add	a5,a5,s1
    80006350:	4741                	li	a4,16
    80006352:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006354:	000a3783          	ld	a5,0(s4)
    80006358:	97a6                	add	a5,a5,s1
    8000635a:	4705                	li	a4,1
    8000635c:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006360:	fa442703          	lw	a4,-92(s0)
    80006364:	000a3783          	ld	a5,0(s4)
    80006368:	97a6                	add	a5,a5,s1
    8000636a:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000636e:	0712                	slli	a4,a4,0x4
    80006370:	000a3783          	ld	a5,0(s4)
    80006374:	97ba                	add	a5,a5,a4
    80006376:	05890693          	addi	a3,s2,88
    8000637a:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000637c:	000a3783          	ld	a5,0(s4)
    80006380:	97ba                	add	a5,a5,a4
    80006382:	40000693          	li	a3,1024
    80006386:	c794                	sw	a3,8(a5)
  if(write)
    80006388:	100c0863          	beqz	s8,80006498 <virtio_disk_rw+0x26a>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000638c:	000a3783          	ld	a5,0(s4)
    80006390:	97ba                	add	a5,a5,a4
    80006392:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006396:	0005d517          	auipc	a0,0x5d
    8000639a:	c6a50513          	addi	a0,a0,-918 # 80063000 <disk>
    8000639e:	0005f797          	auipc	a5,0x5f
    800063a2:	c6278793          	addi	a5,a5,-926 # 80065000 <disk+0x2000>
    800063a6:	6394                	ld	a3,0(a5)
    800063a8:	96ba                	add	a3,a3,a4
    800063aa:	00c6d603          	lhu	a2,12(a3)
    800063ae:	00166613          	ori	a2,a2,1
    800063b2:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800063b6:	fa842683          	lw	a3,-88(s0)
    800063ba:	6390                	ld	a2,0(a5)
    800063bc:	9732                	add	a4,a4,a2
    800063be:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800063c2:	20098613          	addi	a2,s3,512
    800063c6:	0612                	slli	a2,a2,0x4
    800063c8:	962a                	add	a2,a2,a0
    800063ca:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063ce:	00469713          	slli	a4,a3,0x4
    800063d2:	6394                	ld	a3,0(a5)
    800063d4:	96ba                	add	a3,a3,a4
    800063d6:	6589                	lui	a1,0x2
    800063d8:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800063dc:	94ae                	add	s1,s1,a1
    800063de:	94aa                	add	s1,s1,a0
    800063e0:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800063e2:	6394                	ld	a3,0(a5)
    800063e4:	96ba                	add	a3,a3,a4
    800063e6:	4585                	li	a1,1
    800063e8:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063ea:	6394                	ld	a3,0(a5)
    800063ec:	96ba                	add	a3,a3,a4
    800063ee:	4509                	li	a0,2
    800063f0:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800063f4:	6394                	ld	a3,0(a5)
    800063f6:	9736                	add	a4,a4,a3
    800063f8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063fc:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006400:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006404:	6794                	ld	a3,8(a5)
    80006406:	0026d703          	lhu	a4,2(a3)
    8000640a:	8b1d                	andi	a4,a4,7
    8000640c:	2709                	addiw	a4,a4,2
    8000640e:	0706                	slli	a4,a4,0x1
    80006410:	9736                	add	a4,a4,a3
    80006412:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    80006416:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000641a:	6798                	ld	a4,8(a5)
    8000641c:	00275783          	lhu	a5,2(a4)
    80006420:	2785                	addiw	a5,a5,1
    80006422:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006426:	100017b7          	lui	a5,0x10001
    8000642a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000642e:	00492703          	lw	a4,4(s2)
    80006432:	4785                	li	a5,1
    80006434:	02f71163          	bne	a4,a5,80006456 <virtio_disk_rw+0x228>
    sleep(b, &disk.vdisk_lock);
    80006438:	0005f997          	auipc	s3,0x5f
    8000643c:	c7098993          	addi	s3,s3,-912 # 800650a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006440:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006442:	85ce                	mv	a1,s3
    80006444:	854a                	mv	a0,s2
    80006446:	ffffc097          	auipc	ra,0xffffc
    8000644a:	0a0080e7          	jalr	160(ra) # 800024e6 <sleep>
  while(b->disk == 1) {
    8000644e:	00492783          	lw	a5,4(s2)
    80006452:	fe9788e3          	beq	a5,s1,80006442 <virtio_disk_rw+0x214>
  }

  disk.info[idx[0]].b = 0;
    80006456:	fa042483          	lw	s1,-96(s0)
    8000645a:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    8000645e:	00479713          	slli	a4,a5,0x4
    80006462:	0005d797          	auipc	a5,0x5d
    80006466:	b9e78793          	addi	a5,a5,-1122 # 80063000 <disk>
    8000646a:	97ba                	add	a5,a5,a4
    8000646c:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006470:	0005f917          	auipc	s2,0x5f
    80006474:	b9090913          	addi	s2,s2,-1136 # 80065000 <disk+0x2000>
    free_desc(i);
    80006478:	8526                	mv	a0,s1
    8000647a:	00000097          	auipc	ra,0x0
    8000647e:	bec080e7          	jalr	-1044(ra) # 80006066 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006482:	0492                	slli	s1,s1,0x4
    80006484:	00093783          	ld	a5,0(s2)
    80006488:	94be                	add	s1,s1,a5
    8000648a:	00c4d783          	lhu	a5,12(s1)
    8000648e:	8b85                	andi	a5,a5,1
    80006490:	cf91                	beqz	a5,800064ac <virtio_disk_rw+0x27e>
      i = disk.desc[i].next;
    80006492:	00e4d483          	lhu	s1,14(s1)
  while(1){
    80006496:	b7cd                	j	80006478 <virtio_disk_rw+0x24a>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006498:	0005f797          	auipc	a5,0x5f
    8000649c:	b6878793          	addi	a5,a5,-1176 # 80065000 <disk+0x2000>
    800064a0:	639c                	ld	a5,0(a5)
    800064a2:	97ba                	add	a5,a5,a4
    800064a4:	4689                	li	a3,2
    800064a6:	00d79623          	sh	a3,12(a5)
    800064aa:	b5f5                	j	80006396 <virtio_disk_rw+0x168>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064ac:	0005f517          	auipc	a0,0x5f
    800064b0:	bfc50513          	addi	a0,a0,-1028 # 800650a8 <disk+0x20a8>
    800064b4:	ffffb097          	auipc	ra,0xffffb
    800064b8:	9a2080e7          	jalr	-1630(ra) # 80000e56 <release>
}
    800064bc:	70a6                	ld	ra,104(sp)
    800064be:	7406                	ld	s0,96(sp)
    800064c0:	64e6                	ld	s1,88(sp)
    800064c2:	6946                	ld	s2,80(sp)
    800064c4:	69a6                	ld	s3,72(sp)
    800064c6:	6a06                	ld	s4,64(sp)
    800064c8:	7ae2                	ld	s5,56(sp)
    800064ca:	7b42                	ld	s6,48(sp)
    800064cc:	7ba2                	ld	s7,40(sp)
    800064ce:	7c02                	ld	s8,32(sp)
    800064d0:	6165                	addi	sp,sp,112
    800064d2:	8082                	ret
  if(write)
    800064d4:	e40c11e3          	bnez	s8,80006316 <virtio_disk_rw+0xe8>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800064d8:	f8042823          	sw	zero,-112(s0)
    800064dc:	b581                	j	8000631c <virtio_disk_rw+0xee>
      disk.free[i] = 0;
    800064de:	00098c23          	sb	zero,24(s3)
    idx[i] = alloc_desc();
    800064e2:	00072023          	sw	zero,0(a4)
    if(idx[i] < 0){
    800064e6:	b365                	j	8000628e <virtio_disk_rw+0x60>

00000000800064e8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064e8:	1101                	addi	sp,sp,-32
    800064ea:	ec06                	sd	ra,24(sp)
    800064ec:	e822                	sd	s0,16(sp)
    800064ee:	e426                	sd	s1,8(sp)
    800064f0:	e04a                	sd	s2,0(sp)
    800064f2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064f4:	0005f517          	auipc	a0,0x5f
    800064f8:	bb450513          	addi	a0,a0,-1100 # 800650a8 <disk+0x20a8>
    800064fc:	ffffb097          	auipc	ra,0xffffb
    80006500:	8a6080e7          	jalr	-1882(ra) # 80000da2 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006504:	0005f797          	auipc	a5,0x5f
    80006508:	afc78793          	addi	a5,a5,-1284 # 80065000 <disk+0x2000>
    8000650c:	0207d683          	lhu	a3,32(a5)
    80006510:	6b98                	ld	a4,16(a5)
    80006512:	00275783          	lhu	a5,2(a4)
    80006516:	8fb5                	xor	a5,a5,a3
    80006518:	8b9d                	andi	a5,a5,7
    8000651a:	c7c9                	beqz	a5,800065a4 <virtio_disk_intr+0xbc>
    int id = disk.used->elems[disk.used_idx].id;
    8000651c:	068e                	slli	a3,a3,0x3
    8000651e:	9736                	add	a4,a4,a3
    80006520:	435c                	lw	a5,4(a4)

    if(disk.info[id].status != 0)
    80006522:	20078713          	addi	a4,a5,512
    80006526:	00471693          	slli	a3,a4,0x4
    8000652a:	0005d717          	auipc	a4,0x5d
    8000652e:	ad670713          	addi	a4,a4,-1322 # 80063000 <disk>
    80006532:	9736                	add	a4,a4,a3
    80006534:	03074703          	lbu	a4,48(a4)
    80006538:	ef31                	bnez	a4,80006594 <virtio_disk_intr+0xac>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000653a:	0005d917          	auipc	s2,0x5d
    8000653e:	ac690913          	addi	s2,s2,-1338 # 80063000 <disk>
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006542:	0005f497          	auipc	s1,0x5f
    80006546:	abe48493          	addi	s1,s1,-1346 # 80065000 <disk+0x2000>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000654a:	20078793          	addi	a5,a5,512
    8000654e:	0792                	slli	a5,a5,0x4
    80006550:	97ca                	add	a5,a5,s2
    80006552:	7798                	ld	a4,40(a5)
    80006554:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006558:	7788                	ld	a0,40(a5)
    8000655a:	ffffc097          	auipc	ra,0xffffc
    8000655e:	112080e7          	jalr	274(ra) # 8000266c <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006562:	0204d783          	lhu	a5,32(s1)
    80006566:	2785                	addiw	a5,a5,1
    80006568:	8b9d                	andi	a5,a5,7
    8000656a:	03079613          	slli	a2,a5,0x30
    8000656e:	9241                	srli	a2,a2,0x30
    80006570:	02c49023          	sh	a2,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006574:	6898                	ld	a4,16(s1)
    80006576:	00275683          	lhu	a3,2(a4)
    8000657a:	8a9d                	andi	a3,a3,7
    8000657c:	02c68463          	beq	a3,a2,800065a4 <virtio_disk_intr+0xbc>
    int id = disk.used->elems[disk.used_idx].id;
    80006580:	078e                	slli	a5,a5,0x3
    80006582:	97ba                	add	a5,a5,a4
    80006584:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006586:	20078713          	addi	a4,a5,512
    8000658a:	0712                	slli	a4,a4,0x4
    8000658c:	974a                	add	a4,a4,s2
    8000658e:	03074703          	lbu	a4,48(a4)
    80006592:	df45                	beqz	a4,8000654a <virtio_disk_intr+0x62>
      panic("virtio_disk_intr status");
    80006594:	00002517          	auipc	a0,0x2
    80006598:	27c50513          	addi	a0,a0,636 # 80008810 <syscalls+0x3f8>
    8000659c:	ffffa097          	auipc	ra,0xffffa
    800065a0:	fd8080e7          	jalr	-40(ra) # 80000574 <panic>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065a4:	10001737          	lui	a4,0x10001
    800065a8:	533c                	lw	a5,96(a4)
    800065aa:	8b8d                	andi	a5,a5,3
    800065ac:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800065ae:	0005f517          	auipc	a0,0x5f
    800065b2:	afa50513          	addi	a0,a0,-1286 # 800650a8 <disk+0x20a8>
    800065b6:	ffffb097          	auipc	ra,0xffffb
    800065ba:	8a0080e7          	jalr	-1888(ra) # 80000e56 <release>
}
    800065be:	60e2                	ld	ra,24(sp)
    800065c0:	6442                	ld	s0,16(sp)
    800065c2:	64a2                	ld	s1,8(sp)
    800065c4:	6902                	ld	s2,0(sp)
    800065c6:	6105                	addi	sp,sp,32
    800065c8:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
