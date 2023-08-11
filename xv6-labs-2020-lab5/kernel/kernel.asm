
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	80013103          	ld	sp,-2048(sp) # 80008800 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000062:	d5278793          	addi	a5,a5,-686 # 80005db0 <timervec>
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
    80000096:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    8000009a:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009c:	6705                	lui	a4,0x1
    8000009e:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a4:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a8:	00001797          	auipc	a5,0x1
    800000ac:	e8a78793          	addi	a5,a5,-374 # 80000f32 <main>
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
    80000112:	b54080e7          	jalr	-1196(ra) # 80000c62 <acquire>
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
    8000012c:	43a080e7          	jalr	1082(ra) # 80002562 <either_copyin>
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
    80000154:	bc6080e7          	jalr	-1082(ra) # 80000d16 <release>

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
    800001a4:	ac2080e7          	jalr	-1342(ra) # 80000c62 <acquire>
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
    800001d4:	8c0080e7          	jalr	-1856(ra) # 80001a90 <myproc>
    800001d8:	591c                	lw	a5,48(a0)
    800001da:	eba5                	bnez	a5,8000024a <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001dc:	85ce                	mv	a1,s3
    800001de:	854a                	mv	a0,s2
    800001e0:	00002097          	auipc	ra,0x2
    800001e4:	0ca080e7          	jalr	202(ra) # 800022aa <sleep>
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
    80000220:	2f0080e7          	jalr	752(ra) # 8000250c <either_copyout>
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
    80000240:	ada080e7          	jalr	-1318(ra) # 80000d16 <release>

  return target - n;
    80000244:	414b053b          	subw	a0,s6,s4
    80000248:	a811                	j	8000025c <consoleread+0xec>
        release(&cons.lock);
    8000024a:	00011517          	auipc	a0,0x11
    8000024e:	5e650513          	addi	a0,a0,1510 # 80011830 <cons>
    80000252:	00001097          	auipc	ra,0x1
    80000256:	ac4080e7          	jalr	-1340(ra) # 80000d16 <release>
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
    800002e8:	97e080e7          	jalr	-1666(ra) # 80000c62 <acquire>

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
    8000041a:	1a2080e7          	jalr	418(ra) # 800025b8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000041e:	00011517          	auipc	a0,0x11
    80000422:	41250513          	addi	a0,a0,1042 # 80011830 <cons>
    80000426:	00001097          	auipc	ra,0x1
    8000042a:	8f0080e7          	jalr	-1808(ra) # 80000d16 <release>
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
    8000047c:	fb8080e7          	jalr	-72(ra) # 80002430 <wakeup>
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
    8000049a:	00000097          	auipc	ra,0x0
    8000049e:	738080e7          	jalr	1848(ra) # 80000bd2 <initlock>

  uartinit();
    800004a2:	00000097          	auipc	ra,0x0
    800004a6:	334080e7          	jalr	820(ra) # 800007d6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    800004aa:	00021797          	auipc	a5,0x21
    800004ae:	50678793          	addi	a5,a5,1286 # 800219b0 <devsw>
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
    80000638:	62e080e7          	jalr	1582(ra) # 80000c62 <acquire>
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
    8000079e:	57c080e7          	jalr	1404(ra) # 80000d16 <release>
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
    800007c4:	412080e7          	jalr	1042(ra) # 80000bd2 <initlock>
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
    8000081a:	3bc080e7          	jalr	956(ra) # 80000bd2 <initlock>
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
    80000836:	3e4080e7          	jalr	996(ra) # 80000c16 <push_off>

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
    8000086c:	44e080e7          	jalr	1102(ra) # 80000cb6 <pop_off>
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
    800008f2:	b42080e7          	jalr	-1214(ra) # 80002430 <wakeup>
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
    80000944:	322080e7          	jalr	802(ra) # 80000c62 <acquire>
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
    800009a2:	90c080e7          	jalr	-1780(ra) # 800022aa <sleep>
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
    800009e6:	334080e7          	jalr	820(ra) # 80000d16 <release>
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
    80000a52:	214080e7          	jalr	532(ra) # 80000c62 <acquire>
  uartstart();
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	e24080e7          	jalr	-476(ra) # 8000087a <uartstart>
  release(&uart_tx_lock);
    80000a5e:	8526                	mv	a0,s1
    80000a60:	00000097          	auipc	ra,0x0
    80000a64:	2b6080e7          	jalr	694(ra) # 80000d16 <release>
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
    80000a84:	ebb9                	bnez	a5,80000ada <kfree+0x68>
    80000a86:	84aa                	mv	s1,a0
    80000a88:	00025797          	auipc	a5,0x25
    80000a8c:	57878793          	addi	a5,a5,1400 # 80026000 <end>
    80000a90:	04f56563          	bltu	a0,a5,80000ada <kfree+0x68>
    80000a94:	47c5                	li	a5,17
    80000a96:	07ee                	slli	a5,a5,0x1b
    80000a98:	04f57163          	bleu	a5,a0,80000ada <kfree+0x68>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a9c:	6605                	lui	a2,0x1
    80000a9e:	4585                	li	a1,1
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	2be080e7          	jalr	702(ra) # 80000d5e <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000aa8:	00011917          	auipc	s2,0x11
    80000aac:	e8890913          	addi	s2,s2,-376 # 80011930 <kmem>
    80000ab0:	854a                	mv	a0,s2
    80000ab2:	00000097          	auipc	ra,0x0
    80000ab6:	1b0080e7          	jalr	432(ra) # 80000c62 <acquire>
  r->next = kmem.freelist;
    80000aba:	01893783          	ld	a5,24(s2)
    80000abe:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ac0:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ac4:	854a                	mv	a0,s2
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	250080e7          	jalr	592(ra) # 80000d16 <release>
}
    80000ace:	60e2                	ld	ra,24(sp)
    80000ad0:	6442                	ld	s0,16(sp)
    80000ad2:	64a2                	ld	s1,8(sp)
    80000ad4:	6902                	ld	s2,0(sp)
    80000ad6:	6105                	addi	sp,sp,32
    80000ad8:	8082                	ret
    panic("kfree");
    80000ada:	00007517          	auipc	a0,0x7
    80000ade:	58650513          	addi	a0,a0,1414 # 80008060 <digits+0x48>
    80000ae2:	00000097          	auipc	ra,0x0
    80000ae6:	a92080e7          	jalr	-1390(ra) # 80000574 <panic>

0000000080000aea <freerange>:
{
    80000aea:	7179                	addi	sp,sp,-48
    80000aec:	f406                	sd	ra,40(sp)
    80000aee:	f022                	sd	s0,32(sp)
    80000af0:	ec26                	sd	s1,24(sp)
    80000af2:	e84a                	sd	s2,16(sp)
    80000af4:	e44e                	sd	s3,8(sp)
    80000af6:	e052                	sd	s4,0(sp)
    80000af8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000afa:	6705                	lui	a4,0x1
    80000afc:	fff70793          	addi	a5,a4,-1 # fff <_entry-0x7ffff001>
    80000b00:	00f504b3          	add	s1,a0,a5
    80000b04:	77fd                	lui	a5,0xfffff
    80000b06:	8cfd                	and	s1,s1,a5
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b08:	94ba                	add	s1,s1,a4
    80000b0a:	0095ee63          	bltu	a1,s1,80000b26 <freerange+0x3c>
    80000b0e:	892e                	mv	s2,a1
    kfree(p);
    80000b10:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b12:	6985                	lui	s3,0x1
    kfree(p);
    80000b14:	01448533          	add	a0,s1,s4
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	f5a080e7          	jalr	-166(ra) # 80000a72 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b20:	94ce                	add	s1,s1,s3
    80000b22:	fe9979e3          	bleu	s1,s2,80000b14 <freerange+0x2a>
}
    80000b26:	70a2                	ld	ra,40(sp)
    80000b28:	7402                	ld	s0,32(sp)
    80000b2a:	64e2                	ld	s1,24(sp)
    80000b2c:	6942                	ld	s2,16(sp)
    80000b2e:	69a2                	ld	s3,8(sp)
    80000b30:	6a02                	ld	s4,0(sp)
    80000b32:	6145                	addi	sp,sp,48
    80000b34:	8082                	ret

0000000080000b36 <kinit>:
{
    80000b36:	1141                	addi	sp,sp,-16
    80000b38:	e406                	sd	ra,8(sp)
    80000b3a:	e022                	sd	s0,0(sp)
    80000b3c:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b3e:	00007597          	auipc	a1,0x7
    80000b42:	52a58593          	addi	a1,a1,1322 # 80008068 <digits+0x50>
    80000b46:	00011517          	auipc	a0,0x11
    80000b4a:	dea50513          	addi	a0,a0,-534 # 80011930 <kmem>
    80000b4e:	00000097          	auipc	ra,0x0
    80000b52:	084080e7          	jalr	132(ra) # 80000bd2 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b56:	45c5                	li	a1,17
    80000b58:	05ee                	slli	a1,a1,0x1b
    80000b5a:	00025517          	auipc	a0,0x25
    80000b5e:	4a650513          	addi	a0,a0,1190 # 80026000 <end>
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	f88080e7          	jalr	-120(ra) # 80000aea <freerange>
}
    80000b6a:	60a2                	ld	ra,8(sp)
    80000b6c:	6402                	ld	s0,0(sp)
    80000b6e:	0141                	addi	sp,sp,16
    80000b70:	8082                	ret

0000000080000b72 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b7c:	00011497          	auipc	s1,0x11
    80000b80:	db448493          	addi	s1,s1,-588 # 80011930 <kmem>
    80000b84:	8526                	mv	a0,s1
    80000b86:	00000097          	auipc	ra,0x0
    80000b8a:	0dc080e7          	jalr	220(ra) # 80000c62 <acquire>
  r = kmem.freelist;
    80000b8e:	6c84                	ld	s1,24(s1)
  if(r)
    80000b90:	c885                	beqz	s1,80000bc0 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b92:	609c                	ld	a5,0(s1)
    80000b94:	00011517          	auipc	a0,0x11
    80000b98:	d9c50513          	addi	a0,a0,-612 # 80011930 <kmem>
    80000b9c:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	178080e7          	jalr	376(ra) # 80000d16 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000ba6:	6605                	lui	a2,0x1
    80000ba8:	4595                	li	a1,5
    80000baa:	8526                	mv	a0,s1
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	1b2080e7          	jalr	434(ra) # 80000d5e <memset>
  return (void*)r;
}
    80000bb4:	8526                	mv	a0,s1
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
  release(&kmem.lock);
    80000bc0:	00011517          	auipc	a0,0x11
    80000bc4:	d7050513          	addi	a0,a0,-656 # 80011930 <kmem>
    80000bc8:	00000097          	auipc	ra,0x0
    80000bcc:	14e080e7          	jalr	334(ra) # 80000d16 <release>
  if(r)
    80000bd0:	b7d5                	j	80000bb4 <kalloc+0x42>

0000000080000bd2 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bd2:	1141                	addi	sp,sp,-16
    80000bd4:	e422                	sd	s0,8(sp)
    80000bd6:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bd8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bda:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bde:	00053823          	sd	zero,16(a0)
}
    80000be2:	6422                	ld	s0,8(sp)
    80000be4:	0141                	addi	sp,sp,16
    80000be6:	8082                	ret

0000000080000be8 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000be8:	411c                	lw	a5,0(a0)
    80000bea:	e399                	bnez	a5,80000bf0 <holding+0x8>
    80000bec:	4501                	li	a0,0
  return r;
}
    80000bee:	8082                	ret
{
    80000bf0:	1101                	addi	sp,sp,-32
    80000bf2:	ec06                	sd	ra,24(sp)
    80000bf4:	e822                	sd	s0,16(sp)
    80000bf6:	e426                	sd	s1,8(sp)
    80000bf8:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bfa:	6904                	ld	s1,16(a0)
    80000bfc:	00001097          	auipc	ra,0x1
    80000c00:	e78080e7          	jalr	-392(ra) # 80001a74 <mycpu>
    80000c04:	40a48533          	sub	a0,s1,a0
    80000c08:	00153513          	seqz	a0,a0
}
    80000c0c:	60e2                	ld	ra,24(sp)
    80000c0e:	6442                	ld	s0,16(sp)
    80000c10:	64a2                	ld	s1,8(sp)
    80000c12:	6105                	addi	sp,sp,32
    80000c14:	8082                	ret

0000000080000c16 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c16:	1101                	addi	sp,sp,-32
    80000c18:	ec06                	sd	ra,24(sp)
    80000c1a:	e822                	sd	s0,16(sp)
    80000c1c:	e426                	sd	s1,8(sp)
    80000c1e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c20:	100024f3          	csrr	s1,sstatus
    80000c24:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c28:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c2a:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c2e:	00001097          	auipc	ra,0x1
    80000c32:	e46080e7          	jalr	-442(ra) # 80001a74 <mycpu>
    80000c36:	5d3c                	lw	a5,120(a0)
    80000c38:	cf89                	beqz	a5,80000c52 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c3a:	00001097          	auipc	ra,0x1
    80000c3e:	e3a080e7          	jalr	-454(ra) # 80001a74 <mycpu>
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	2785                	addiw	a5,a5,1
    80000c46:	dd3c                	sw	a5,120(a0)
}
    80000c48:	60e2                	ld	ra,24(sp)
    80000c4a:	6442                	ld	s0,16(sp)
    80000c4c:	64a2                	ld	s1,8(sp)
    80000c4e:	6105                	addi	sp,sp,32
    80000c50:	8082                	ret
    mycpu()->intena = old;
    80000c52:	00001097          	auipc	ra,0x1
    80000c56:	e22080e7          	jalr	-478(ra) # 80001a74 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c5a:	8085                	srli	s1,s1,0x1
    80000c5c:	8885                	andi	s1,s1,1
    80000c5e:	dd64                	sw	s1,124(a0)
    80000c60:	bfe9                	j	80000c3a <push_off+0x24>

0000000080000c62 <acquire>:
{
    80000c62:	1101                	addi	sp,sp,-32
    80000c64:	ec06                	sd	ra,24(sp)
    80000c66:	e822                	sd	s0,16(sp)
    80000c68:	e426                	sd	s1,8(sp)
    80000c6a:	1000                	addi	s0,sp,32
    80000c6c:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c6e:	00000097          	auipc	ra,0x0
    80000c72:	fa8080e7          	jalr	-88(ra) # 80000c16 <push_off>
  if(holding(lk))
    80000c76:	8526                	mv	a0,s1
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	f70080e7          	jalr	-144(ra) # 80000be8 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c80:	4705                	li	a4,1
  if(holding(lk))
    80000c82:	e115                	bnez	a0,80000ca6 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c84:	87ba                	mv	a5,a4
    80000c86:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c8a:	2781                	sext.w	a5,a5
    80000c8c:	ffe5                	bnez	a5,80000c84 <acquire+0x22>
  __sync_synchronize();
    80000c8e:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c92:	00001097          	auipc	ra,0x1
    80000c96:	de2080e7          	jalr	-542(ra) # 80001a74 <mycpu>
    80000c9a:	e888                	sd	a0,16(s1)
}
    80000c9c:	60e2                	ld	ra,24(sp)
    80000c9e:	6442                	ld	s0,16(sp)
    80000ca0:	64a2                	ld	s1,8(sp)
    80000ca2:	6105                	addi	sp,sp,32
    80000ca4:	8082                	ret
    panic("acquire");
    80000ca6:	00007517          	auipc	a0,0x7
    80000caa:	3ca50513          	addi	a0,a0,970 # 80008070 <digits+0x58>
    80000cae:	00000097          	auipc	ra,0x0
    80000cb2:	8c6080e7          	jalr	-1850(ra) # 80000574 <panic>

0000000080000cb6 <pop_off>:

void
pop_off(void)
{
    80000cb6:	1141                	addi	sp,sp,-16
    80000cb8:	e406                	sd	ra,8(sp)
    80000cba:	e022                	sd	s0,0(sp)
    80000cbc:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000cbe:	00001097          	auipc	ra,0x1
    80000cc2:	db6080e7          	jalr	-586(ra) # 80001a74 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cc6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cca:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000ccc:	e78d                	bnez	a5,80000cf6 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cce:	5d3c                	lw	a5,120(a0)
    80000cd0:	02f05b63          	blez	a5,80000d06 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cd4:	37fd                	addiw	a5,a5,-1
    80000cd6:	0007871b          	sext.w	a4,a5
    80000cda:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cdc:	eb09                	bnez	a4,80000cee <pop_off+0x38>
    80000cde:	5d7c                	lw	a5,124(a0)
    80000ce0:	c799                	beqz	a5,80000cee <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ce6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cea:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cee:	60a2                	ld	ra,8(sp)
    80000cf0:	6402                	ld	s0,0(sp)
    80000cf2:	0141                	addi	sp,sp,16
    80000cf4:	8082                	ret
    panic("pop_off - interruptible");
    80000cf6:	00007517          	auipc	a0,0x7
    80000cfa:	38250513          	addi	a0,a0,898 # 80008078 <digits+0x60>
    80000cfe:	00000097          	auipc	ra,0x0
    80000d02:	876080e7          	jalr	-1930(ra) # 80000574 <panic>
    panic("pop_off");
    80000d06:	00007517          	auipc	a0,0x7
    80000d0a:	38a50513          	addi	a0,a0,906 # 80008090 <digits+0x78>
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	866080e7          	jalr	-1946(ra) # 80000574 <panic>

0000000080000d16 <release>:
{
    80000d16:	1101                	addi	sp,sp,-32
    80000d18:	ec06                	sd	ra,24(sp)
    80000d1a:	e822                	sd	s0,16(sp)
    80000d1c:	e426                	sd	s1,8(sp)
    80000d1e:	1000                	addi	s0,sp,32
    80000d20:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	ec6080e7          	jalr	-314(ra) # 80000be8 <holding>
    80000d2a:	c115                	beqz	a0,80000d4e <release+0x38>
  lk->cpu = 0;
    80000d2c:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d30:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d34:	0f50000f          	fence	iorw,ow
    80000d38:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d3c:	00000097          	auipc	ra,0x0
    80000d40:	f7a080e7          	jalr	-134(ra) # 80000cb6 <pop_off>
}
    80000d44:	60e2                	ld	ra,24(sp)
    80000d46:	6442                	ld	s0,16(sp)
    80000d48:	64a2                	ld	s1,8(sp)
    80000d4a:	6105                	addi	sp,sp,32
    80000d4c:	8082                	ret
    panic("release");
    80000d4e:	00007517          	auipc	a0,0x7
    80000d52:	34a50513          	addi	a0,a0,842 # 80008098 <digits+0x80>
    80000d56:	00000097          	auipc	ra,0x0
    80000d5a:	81e080e7          	jalr	-2018(ra) # 80000574 <panic>

0000000080000d5e <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d5e:	1141                	addi	sp,sp,-16
    80000d60:	e422                	sd	s0,8(sp)
    80000d62:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d64:	ce09                	beqz	a2,80000d7e <memset+0x20>
    80000d66:	87aa                	mv	a5,a0
    80000d68:	fff6071b          	addiw	a4,a2,-1
    80000d6c:	1702                	slli	a4,a4,0x20
    80000d6e:	9301                	srli	a4,a4,0x20
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d74:	00b78023          	sb	a1,0(a5) # fffffffffffff000 <end+0xffffffff7ffd9000>
  for(i = 0; i < n; i++){
    80000d78:	0785                	addi	a5,a5,1
    80000d7a:	fee79de3          	bne	a5,a4,80000d74 <memset+0x16>
  }
  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret

0000000080000d84 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d84:	1141                	addi	sp,sp,-16
    80000d86:	e422                	sd	s0,8(sp)
    80000d88:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d8a:	ce15                	beqz	a2,80000dc6 <memcmp+0x42>
    80000d8c:	fff6069b          	addiw	a3,a2,-1
    if(*s1 != *s2)
    80000d90:	00054783          	lbu	a5,0(a0)
    80000d94:	0005c703          	lbu	a4,0(a1)
    80000d98:	02e79063          	bne	a5,a4,80000db8 <memcmp+0x34>
    80000d9c:	1682                	slli	a3,a3,0x20
    80000d9e:	9281                	srli	a3,a3,0x20
    80000da0:	0685                	addi	a3,a3,1
    80000da2:	96aa                	add	a3,a3,a0
      return *s1 - *s2;
    s1++, s2++;
    80000da4:	0505                	addi	a0,a0,1
    80000da6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000da8:	00d50d63          	beq	a0,a3,80000dc2 <memcmp+0x3e>
    if(*s1 != *s2)
    80000dac:	00054783          	lbu	a5,0(a0)
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	fee788e3          	beq	a5,a4,80000da4 <memcmp+0x20>
      return *s1 - *s2;
    80000db8:	40e7853b          	subw	a0,a5,a4
  }

  return 0;
}
    80000dbc:	6422                	ld	s0,8(sp)
    80000dbe:	0141                	addi	sp,sp,16
    80000dc0:	8082                	ret
  return 0;
    80000dc2:	4501                	li	a0,0
    80000dc4:	bfe5                	j	80000dbc <memcmp+0x38>
    80000dc6:	4501                	li	a0,0
    80000dc8:	bfd5                	j	80000dbc <memcmp+0x38>

0000000080000dca <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000dca:	1141                	addi	sp,sp,-16
    80000dcc:	e422                	sd	s0,8(sp)
    80000dce:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000dd0:	00a5f963          	bleu	a0,a1,80000de2 <memmove+0x18>
    80000dd4:	02061713          	slli	a4,a2,0x20
    80000dd8:	9301                	srli	a4,a4,0x20
    80000dda:	00e587b3          	add	a5,a1,a4
    80000dde:	02f56563          	bltu	a0,a5,80000e08 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000de2:	fff6069b          	addiw	a3,a2,-1
    80000de6:	ce11                	beqz	a2,80000e02 <memmove+0x38>
    80000de8:	1682                	slli	a3,a3,0x20
    80000dea:	9281                	srli	a3,a3,0x20
    80000dec:	0685                	addi	a3,a3,1
    80000dee:	96ae                	add	a3,a3,a1
    80000df0:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000df2:	0585                	addi	a1,a1,1
    80000df4:	0785                	addi	a5,a5,1
    80000df6:	fff5c703          	lbu	a4,-1(a1)
    80000dfa:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dfe:	fed59ae3          	bne	a1,a3,80000df2 <memmove+0x28>

  return dst;
}
    80000e02:	6422                	ld	s0,8(sp)
    80000e04:	0141                	addi	sp,sp,16
    80000e06:	8082                	ret
    d += n;
    80000e08:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e0a:	fff6069b          	addiw	a3,a2,-1
    80000e0e:	da75                	beqz	a2,80000e02 <memmove+0x38>
    80000e10:	02069613          	slli	a2,a3,0x20
    80000e14:	9201                	srli	a2,a2,0x20
    80000e16:	fff64613          	not	a2,a2
    80000e1a:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e1c:	17fd                	addi	a5,a5,-1
    80000e1e:	177d                	addi	a4,a4,-1
    80000e20:	0007c683          	lbu	a3,0(a5)
    80000e24:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e28:	fef61ae3          	bne	a2,a5,80000e1c <memmove+0x52>
    80000e2c:	bfd9                	j	80000e02 <memmove+0x38>

0000000080000e2e <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e2e:	1141                	addi	sp,sp,-16
    80000e30:	e406                	sd	ra,8(sp)
    80000e32:	e022                	sd	s0,0(sp)
    80000e34:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e36:	00000097          	auipc	ra,0x0
    80000e3a:	f94080e7          	jalr	-108(ra) # 80000dca <memmove>
}
    80000e3e:	60a2                	ld	ra,8(sp)
    80000e40:	6402                	ld	s0,0(sp)
    80000e42:	0141                	addi	sp,sp,16
    80000e44:	8082                	ret

0000000080000e46 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e46:	1141                	addi	sp,sp,-16
    80000e48:	e422                	sd	s0,8(sp)
    80000e4a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e4c:	c229                	beqz	a2,80000e8e <strncmp+0x48>
    80000e4e:	00054783          	lbu	a5,0(a0)
    80000e52:	c795                	beqz	a5,80000e7e <strncmp+0x38>
    80000e54:	0005c703          	lbu	a4,0(a1)
    80000e58:	02f71363          	bne	a4,a5,80000e7e <strncmp+0x38>
    80000e5c:	fff6071b          	addiw	a4,a2,-1
    80000e60:	1702                	slli	a4,a4,0x20
    80000e62:	9301                	srli	a4,a4,0x20
    80000e64:	0705                	addi	a4,a4,1
    80000e66:	972a                	add	a4,a4,a0
    n--, p++, q++;
    80000e68:	0505                	addi	a0,a0,1
    80000e6a:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e6c:	02e50363          	beq	a0,a4,80000e92 <strncmp+0x4c>
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	c789                	beqz	a5,80000e7e <strncmp+0x38>
    80000e76:	0005c683          	lbu	a3,0(a1)
    80000e7a:	fef687e3          	beq	a3,a5,80000e68 <strncmp+0x22>
  if(n == 0)
    return 0;
  return (uchar)*p - (uchar)*q;
    80000e7e:	00054503          	lbu	a0,0(a0)
    80000e82:	0005c783          	lbu	a5,0(a1)
    80000e86:	9d1d                	subw	a0,a0,a5
}
    80000e88:	6422                	ld	s0,8(sp)
    80000e8a:	0141                	addi	sp,sp,16
    80000e8c:	8082                	ret
    return 0;
    80000e8e:	4501                	li	a0,0
    80000e90:	bfe5                	j	80000e88 <strncmp+0x42>
    80000e92:	4501                	li	a0,0
    80000e94:	bfd5                	j	80000e88 <strncmp+0x42>

0000000080000e96 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e96:	1141                	addi	sp,sp,-16
    80000e98:	e422                	sd	s0,8(sp)
    80000e9a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e9c:	872a                	mv	a4,a0
    80000e9e:	a011                	j	80000ea2 <strncpy+0xc>
    80000ea0:	8636                	mv	a2,a3
    80000ea2:	fff6069b          	addiw	a3,a2,-1
    80000ea6:	00c05963          	blez	a2,80000eb8 <strncpy+0x22>
    80000eaa:	0705                	addi	a4,a4,1
    80000eac:	0005c783          	lbu	a5,0(a1)
    80000eb0:	fef70fa3          	sb	a5,-1(a4)
    80000eb4:	0585                	addi	a1,a1,1
    80000eb6:	f7ed                	bnez	a5,80000ea0 <strncpy+0xa>
    ;
  while(n-- > 0)
    80000eb8:	00d05c63          	blez	a3,80000ed0 <strncpy+0x3a>
    80000ebc:	86ba                	mv	a3,a4
    *s++ = 0;
    80000ebe:	0685                	addi	a3,a3,1
    80000ec0:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ec4:	fff6c793          	not	a5,a3
    80000ec8:	9fb9                	addw	a5,a5,a4
    80000eca:	9fb1                	addw	a5,a5,a2
    80000ecc:	fef049e3          	bgtz	a5,80000ebe <strncpy+0x28>
  return os;
}
    80000ed0:	6422                	ld	s0,8(sp)
    80000ed2:	0141                	addi	sp,sp,16
    80000ed4:	8082                	ret

0000000080000ed6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ed6:	1141                	addi	sp,sp,-16
    80000ed8:	e422                	sd	s0,8(sp)
    80000eda:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000edc:	02c05363          	blez	a2,80000f02 <safestrcpy+0x2c>
    80000ee0:	fff6069b          	addiw	a3,a2,-1
    80000ee4:	1682                	slli	a3,a3,0x20
    80000ee6:	9281                	srli	a3,a3,0x20
    80000ee8:	96ae                	add	a3,a3,a1
    80000eea:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000eec:	00d58963          	beq	a1,a3,80000efe <safestrcpy+0x28>
    80000ef0:	0585                	addi	a1,a1,1
    80000ef2:	0785                	addi	a5,a5,1
    80000ef4:	fff5c703          	lbu	a4,-1(a1)
    80000ef8:	fee78fa3          	sb	a4,-1(a5)
    80000efc:	fb65                	bnez	a4,80000eec <safestrcpy+0x16>
    ;
  *s = 0;
    80000efe:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f02:	6422                	ld	s0,8(sp)
    80000f04:	0141                	addi	sp,sp,16
    80000f06:	8082                	ret

0000000080000f08 <strlen>:

int
strlen(const char *s)
{
    80000f08:	1141                	addi	sp,sp,-16
    80000f0a:	e422                	sd	s0,8(sp)
    80000f0c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f0e:	00054783          	lbu	a5,0(a0)
    80000f12:	cf91                	beqz	a5,80000f2e <strlen+0x26>
    80000f14:	0505                	addi	a0,a0,1
    80000f16:	87aa                	mv	a5,a0
    80000f18:	4685                	li	a3,1
    80000f1a:	9e89                	subw	a3,a3,a0
    80000f1c:	00f6853b          	addw	a0,a3,a5
    80000f20:	0785                	addi	a5,a5,1
    80000f22:	fff7c703          	lbu	a4,-1(a5)
    80000f26:	fb7d                	bnez	a4,80000f1c <strlen+0x14>
    ;
  return n;
}
    80000f28:	6422                	ld	s0,8(sp)
    80000f2a:	0141                	addi	sp,sp,16
    80000f2c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f2e:	4501                	li	a0,0
    80000f30:	bfe5                	j	80000f28 <strlen+0x20>

0000000080000f32 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f32:	1141                	addi	sp,sp,-16
    80000f34:	e406                	sd	ra,8(sp)
    80000f36:	e022                	sd	s0,0(sp)
    80000f38:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	b2a080e7          	jalr	-1238(ra) # 80001a64 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f42:	00008717          	auipc	a4,0x8
    80000f46:	0ca70713          	addi	a4,a4,202 # 8000900c <started>
  if(cpuid() == 0){
    80000f4a:	c139                	beqz	a0,80000f90 <main+0x5e>
    while(started == 0)
    80000f4c:	431c                	lw	a5,0(a4)
    80000f4e:	2781                	sext.w	a5,a5
    80000f50:	dff5                	beqz	a5,80000f4c <main+0x1a>
      ;
    __sync_synchronize();
    80000f52:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f56:	00001097          	auipc	ra,0x1
    80000f5a:	b0e080e7          	jalr	-1266(ra) # 80001a64 <cpuid>
    80000f5e:	85aa                	mv	a1,a0
    80000f60:	00007517          	auipc	a0,0x7
    80000f64:	15850513          	addi	a0,a0,344 # 800080b8 <digits+0xa0>
    80000f68:	fffff097          	auipc	ra,0xfffff
    80000f6c:	656080e7          	jalr	1622(ra) # 800005be <printf>
    kvminithart();    // turn on paging
    80000f70:	00000097          	auipc	ra,0x0
    80000f74:	0d8080e7          	jalr	216(ra) # 80001048 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f78:	00001097          	auipc	ra,0x1
    80000f7c:	782080e7          	jalr	1922(ra) # 800026fa <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	e70080e7          	jalr	-400(ra) # 80005df0 <plicinithart>
  }

  scheduler();        
    80000f88:	00001097          	auipc	ra,0x1
    80000f8c:	03e080e7          	jalr	62(ra) # 80001fc6 <scheduler>
    consoleinit();
    80000f90:	fffff097          	auipc	ra,0xfffff
    80000f94:	4f2080e7          	jalr	1266(ra) # 80000482 <consoleinit>
    printfinit();
    80000f98:	00000097          	auipc	ra,0x0
    80000f9c:	80c080e7          	jalr	-2036(ra) # 800007a4 <printfinit>
    printf("\n");
    80000fa0:	00007517          	auipc	a0,0x7
    80000fa4:	12850513          	addi	a0,a0,296 # 800080c8 <digits+0xb0>
    80000fa8:	fffff097          	auipc	ra,0xfffff
    80000fac:	616080e7          	jalr	1558(ra) # 800005be <printf>
    printf("xv6 kernel is booting\n");
    80000fb0:	00007517          	auipc	a0,0x7
    80000fb4:	0f050513          	addi	a0,a0,240 # 800080a0 <digits+0x88>
    80000fb8:	fffff097          	auipc	ra,0xfffff
    80000fbc:	606080e7          	jalr	1542(ra) # 800005be <printf>
    printf("\n");
    80000fc0:	00007517          	auipc	a0,0x7
    80000fc4:	10850513          	addi	a0,a0,264 # 800080c8 <digits+0xb0>
    80000fc8:	fffff097          	auipc	ra,0xfffff
    80000fcc:	5f6080e7          	jalr	1526(ra) # 800005be <printf>
    kinit();         // physical page allocator
    80000fd0:	00000097          	auipc	ra,0x0
    80000fd4:	b66080e7          	jalr	-1178(ra) # 80000b36 <kinit>
    kvminit();       // create kernel page table
    80000fd8:	00000097          	auipc	ra,0x0
    80000fdc:	264080e7          	jalr	612(ra) # 8000123c <kvminit>
    kvminithart();   // turn on paging
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	068080e7          	jalr	104(ra) # 80001048 <kvminithart>
    procinit();      // process table
    80000fe8:	00001097          	auipc	ra,0x1
    80000fec:	9ac080e7          	jalr	-1620(ra) # 80001994 <procinit>
    trapinit();      // trap vectors
    80000ff0:	00001097          	auipc	ra,0x1
    80000ff4:	6e2080e7          	jalr	1762(ra) # 800026d2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ff8:	00001097          	auipc	ra,0x1
    80000ffc:	702080e7          	jalr	1794(ra) # 800026fa <trapinithart>
    plicinit();      // set up interrupt controller
    80001000:	00005097          	auipc	ra,0x5
    80001004:	dda080e7          	jalr	-550(ra) # 80005dda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001008:	00005097          	auipc	ra,0x5
    8000100c:	de8080e7          	jalr	-536(ra) # 80005df0 <plicinithart>
    binit();         // buffer cache
    80001010:	00002097          	auipc	ra,0x2
    80001014:	eb4080e7          	jalr	-332(ra) # 80002ec4 <binit>
    iinit();         // inode cache
    80001018:	00002097          	auipc	ra,0x2
    8000101c:	586080e7          	jalr	1414(ra) # 8000359e <iinit>
    fileinit();      // file table
    80001020:	00003097          	auipc	ra,0x3
    80001024:	550080e7          	jalr	1360(ra) # 80004570 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001028:	00005097          	auipc	ra,0x5
    8000102c:	ed2080e7          	jalr	-302(ra) # 80005efa <virtio_disk_init>
    userinit();      // first user process
    80001030:	00001097          	auipc	ra,0x1
    80001034:	d2c080e7          	jalr	-724(ra) # 80001d5c <userinit>
    __sync_synchronize();
    80001038:	0ff0000f          	fence
    started = 1;
    8000103c:	4785                	li	a5,1
    8000103e:	00008717          	auipc	a4,0x8
    80001042:	fcf72723          	sw	a5,-50(a4) # 8000900c <started>
    80001046:	b789                	j	80000f88 <main+0x56>

0000000080001048 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001048:	1141                	addi	sp,sp,-16
    8000104a:	e422                	sd	s0,8(sp)
    8000104c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000104e:	00008797          	auipc	a5,0x8
    80001052:	fc278793          	addi	a5,a5,-62 # 80009010 <kernel_pagetable>
    80001056:	639c                	ld	a5,0(a5)
    80001058:	83b1                	srli	a5,a5,0xc
    8000105a:	577d                	li	a4,-1
    8000105c:	177e                	slli	a4,a4,0x3f
    8000105e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001060:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001064:	12000073          	sfence.vma
  sfence_vma();
}
    80001068:	6422                	ld	s0,8(sp)
    8000106a:	0141                	addi	sp,sp,16
    8000106c:	8082                	ret

000000008000106e <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000106e:	7139                	addi	sp,sp,-64
    80001070:	fc06                	sd	ra,56(sp)
    80001072:	f822                	sd	s0,48(sp)
    80001074:	f426                	sd	s1,40(sp)
    80001076:	f04a                	sd	s2,32(sp)
    80001078:	ec4e                	sd	s3,24(sp)
    8000107a:	e852                	sd	s4,16(sp)
    8000107c:	e456                	sd	s5,8(sp)
    8000107e:	e05a                	sd	s6,0(sp)
    80001080:	0080                	addi	s0,sp,64
    80001082:	84aa                	mv	s1,a0
    80001084:	89ae                	mv	s3,a1
    80001086:	8b32                	mv	s6,a2
  if(va >= MAXVA)
    80001088:	57fd                	li	a5,-1
    8000108a:	83e9                	srli	a5,a5,0x1a
    8000108c:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000108e:	4ab1                	li	s5,12
  if(va >= MAXVA)
    80001090:	04b7f263          	bleu	a1,a5,800010d4 <walk+0x66>
    panic("walk");
    80001094:	00007517          	auipc	a0,0x7
    80001098:	03c50513          	addi	a0,a0,60 # 800080d0 <digits+0xb8>
    8000109c:	fffff097          	auipc	ra,0xfffff
    800010a0:	4d8080e7          	jalr	1240(ra) # 80000574 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010a4:	060b0663          	beqz	s6,80001110 <walk+0xa2>
    800010a8:	00000097          	auipc	ra,0x0
    800010ac:	aca080e7          	jalr	-1334(ra) # 80000b72 <kalloc>
    800010b0:	84aa                	mv	s1,a0
    800010b2:	c529                	beqz	a0,800010fc <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010b4:	6605                	lui	a2,0x1
    800010b6:	4581                	li	a1,0
    800010b8:	00000097          	auipc	ra,0x0
    800010bc:	ca6080e7          	jalr	-858(ra) # 80000d5e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010c0:	00c4d793          	srli	a5,s1,0xc
    800010c4:	07aa                	slli	a5,a5,0xa
    800010c6:	0017e793          	ori	a5,a5,1
    800010ca:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010ce:	3a5d                	addiw	s4,s4,-9
    800010d0:	035a0063          	beq	s4,s5,800010f0 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010d4:	0149d933          	srl	s2,s3,s4
    800010d8:	1ff97913          	andi	s2,s2,511
    800010dc:	090e                	slli	s2,s2,0x3
    800010de:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010e0:	00093483          	ld	s1,0(s2)
    800010e4:	0014f793          	andi	a5,s1,1
    800010e8:	dfd5                	beqz	a5,800010a4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010ea:	80a9                	srli	s1,s1,0xa
    800010ec:	04b2                	slli	s1,s1,0xc
    800010ee:	b7c5                	j	800010ce <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010f0:	00c9d513          	srli	a0,s3,0xc
    800010f4:	1ff57513          	andi	a0,a0,511
    800010f8:	050e                	slli	a0,a0,0x3
    800010fa:	9526                	add	a0,a0,s1
}
    800010fc:	70e2                	ld	ra,56(sp)
    800010fe:	7442                	ld	s0,48(sp)
    80001100:	74a2                	ld	s1,40(sp)
    80001102:	7902                	ld	s2,32(sp)
    80001104:	69e2                	ld	s3,24(sp)
    80001106:	6a42                	ld	s4,16(sp)
    80001108:	6aa2                	ld	s5,8(sp)
    8000110a:	6b02                	ld	s6,0(sp)
    8000110c:	6121                	addi	sp,sp,64
    8000110e:	8082                	ret
        return 0;
    80001110:	4501                	li	a0,0
    80001112:	b7ed                	j	800010fc <walk+0x8e>

0000000080001114 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001114:	1101                	addi	sp,sp,-32
    80001116:	ec06                	sd	ra,24(sp)
    80001118:	e822                	sd	s0,16(sp)
    8000111a:	e426                	sd	s1,8(sp)
    8000111c:	1000                	addi	s0,sp,32
    8000111e:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001120:	6785                	lui	a5,0x1
    80001122:	17fd                	addi	a5,a5,-1
    80001124:	00f574b3          	and	s1,a0,a5
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001128:	4601                	li	a2,0
    8000112a:	00008797          	auipc	a5,0x8
    8000112e:	ee678793          	addi	a5,a5,-282 # 80009010 <kernel_pagetable>
    80001132:	6388                	ld	a0,0(a5)
    80001134:	00000097          	auipc	ra,0x0
    80001138:	f3a080e7          	jalr	-198(ra) # 8000106e <walk>
  if(pte == 0)
    8000113c:	cd09                	beqz	a0,80001156 <kvmpa+0x42>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000113e:	6108                	ld	a0,0(a0)
    80001140:	00157793          	andi	a5,a0,1
    80001144:	c38d                	beqz	a5,80001166 <kvmpa+0x52>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001146:	8129                	srli	a0,a0,0xa
    80001148:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000114a:	9526                	add	a0,a0,s1
    8000114c:	60e2                	ld	ra,24(sp)
    8000114e:	6442                	ld	s0,16(sp)
    80001150:	64a2                	ld	s1,8(sp)
    80001152:	6105                	addi	sp,sp,32
    80001154:	8082                	ret
    panic("kvmpa");
    80001156:	00007517          	auipc	a0,0x7
    8000115a:	f8250513          	addi	a0,a0,-126 # 800080d8 <digits+0xc0>
    8000115e:	fffff097          	auipc	ra,0xfffff
    80001162:	416080e7          	jalr	1046(ra) # 80000574 <panic>
    panic("kvmpa");
    80001166:	00007517          	auipc	a0,0x7
    8000116a:	f7250513          	addi	a0,a0,-142 # 800080d8 <digits+0xc0>
    8000116e:	fffff097          	auipc	ra,0xfffff
    80001172:	406080e7          	jalr	1030(ra) # 80000574 <panic>

0000000080001176 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001176:	715d                	addi	sp,sp,-80
    80001178:	e486                	sd	ra,72(sp)
    8000117a:	e0a2                	sd	s0,64(sp)
    8000117c:	fc26                	sd	s1,56(sp)
    8000117e:	f84a                	sd	s2,48(sp)
    80001180:	f44e                	sd	s3,40(sp)
    80001182:	f052                	sd	s4,32(sp)
    80001184:	ec56                	sd	s5,24(sp)
    80001186:	e85a                	sd	s6,16(sp)
    80001188:	e45e                	sd	s7,8(sp)
    8000118a:	0880                	addi	s0,sp,80
    8000118c:	8aaa                	mv	s5,a0
    8000118e:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001190:	79fd                	lui	s3,0xfffff
    80001192:	0135fa33          	and	s4,a1,s3
  last = PGROUNDDOWN(va + size - 1);
    80001196:	167d                	addi	a2,a2,-1
    80001198:	962e                	add	a2,a2,a1
    8000119a:	013679b3          	and	s3,a2,s3
  a = PGROUNDDOWN(va);
    8000119e:	8952                	mv	s2,s4
    800011a0:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011a4:	6b85                	lui	s7,0x1
    800011a6:	a811                	j	800011ba <mappages+0x44>
      panic("remap");
    800011a8:	00007517          	auipc	a0,0x7
    800011ac:	f3850513          	addi	a0,a0,-200 # 800080e0 <digits+0xc8>
    800011b0:	fffff097          	auipc	ra,0xfffff
    800011b4:	3c4080e7          	jalr	964(ra) # 80000574 <panic>
    a += PGSIZE;
    800011b8:	995e                	add	s2,s2,s7
  for(;;){
    800011ba:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011be:	4605                	li	a2,1
    800011c0:	85ca                	mv	a1,s2
    800011c2:	8556                	mv	a0,s5
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	eaa080e7          	jalr	-342(ra) # 8000106e <walk>
    800011cc:	cd19                	beqz	a0,800011ea <mappages+0x74>
    if(*pte & PTE_V)
    800011ce:	611c                	ld	a5,0(a0)
    800011d0:	8b85                	andi	a5,a5,1
    800011d2:	fbf9                	bnez	a5,800011a8 <mappages+0x32>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011d4:	80b1                	srli	s1,s1,0xc
    800011d6:	04aa                	slli	s1,s1,0xa
    800011d8:	0164e4b3          	or	s1,s1,s6
    800011dc:	0014e493          	ori	s1,s1,1
    800011e0:	e104                	sd	s1,0(a0)
    if(a == last)
    800011e2:	fd391be3          	bne	s2,s3,800011b8 <mappages+0x42>
    pa += PGSIZE;
  }
  return 0;
    800011e6:	4501                	li	a0,0
    800011e8:	a011                	j	800011ec <mappages+0x76>
      return -1;
    800011ea:	557d                	li	a0,-1
}
    800011ec:	60a6                	ld	ra,72(sp)
    800011ee:	6406                	ld	s0,64(sp)
    800011f0:	74e2                	ld	s1,56(sp)
    800011f2:	7942                	ld	s2,48(sp)
    800011f4:	79a2                	ld	s3,40(sp)
    800011f6:	7a02                	ld	s4,32(sp)
    800011f8:	6ae2                	ld	s5,24(sp)
    800011fa:	6b42                	ld	s6,16(sp)
    800011fc:	6ba2                	ld	s7,8(sp)
    800011fe:	6161                	addi	sp,sp,80
    80001200:	8082                	ret

0000000080001202 <kvmmap>:
{
    80001202:	1141                	addi	sp,sp,-16
    80001204:	e406                	sd	ra,8(sp)
    80001206:	e022                	sd	s0,0(sp)
    80001208:	0800                	addi	s0,sp,16
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000120a:	8736                	mv	a4,a3
    8000120c:	86ae                	mv	a3,a1
    8000120e:	85aa                	mv	a1,a0
    80001210:	00008797          	auipc	a5,0x8
    80001214:	e0078793          	addi	a5,a5,-512 # 80009010 <kernel_pagetable>
    80001218:	6388                	ld	a0,0(a5)
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f5c080e7          	jalr	-164(ra) # 80001176 <mappages>
    80001222:	e509                	bnez	a0,8000122c <kvmmap+0x2a>
}
    80001224:	60a2                	ld	ra,8(sp)
    80001226:	6402                	ld	s0,0(sp)
    80001228:	0141                	addi	sp,sp,16
    8000122a:	8082                	ret
    panic("kvmmap");
    8000122c:	00007517          	auipc	a0,0x7
    80001230:	ebc50513          	addi	a0,a0,-324 # 800080e8 <digits+0xd0>
    80001234:	fffff097          	auipc	ra,0xfffff
    80001238:	340080e7          	jalr	832(ra) # 80000574 <panic>

000000008000123c <kvminit>:
{
    8000123c:	1101                	addi	sp,sp,-32
    8000123e:	ec06                	sd	ra,24(sp)
    80001240:	e822                	sd	s0,16(sp)
    80001242:	e426                	sd	s1,8(sp)
    80001244:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	92c080e7          	jalr	-1748(ra) # 80000b72 <kalloc>
    8000124e:	00008797          	auipc	a5,0x8
    80001252:	dca7b123          	sd	a0,-574(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001256:	6605                	lui	a2,0x1
    80001258:	4581                	li	a1,0
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	b04080e7          	jalr	-1276(ra) # 80000d5e <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001262:	4699                	li	a3,6
    80001264:	6605                	lui	a2,0x1
    80001266:	100005b7          	lui	a1,0x10000
    8000126a:	10000537          	lui	a0,0x10000
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f94080e7          	jalr	-108(ra) # 80001202 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001276:	4699                	li	a3,6
    80001278:	6605                	lui	a2,0x1
    8000127a:	100015b7          	lui	a1,0x10001
    8000127e:	10001537          	lui	a0,0x10001
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f80080e7          	jalr	-128(ra) # 80001202 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    8000128a:	4699                	li	a3,6
    8000128c:	6641                	lui	a2,0x10
    8000128e:	020005b7          	lui	a1,0x2000
    80001292:	02000537          	lui	a0,0x2000
    80001296:	00000097          	auipc	ra,0x0
    8000129a:	f6c080e7          	jalr	-148(ra) # 80001202 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000129e:	4699                	li	a3,6
    800012a0:	00400637          	lui	a2,0x400
    800012a4:	0c0005b7          	lui	a1,0xc000
    800012a8:	0c000537          	lui	a0,0xc000
    800012ac:	00000097          	auipc	ra,0x0
    800012b0:	f56080e7          	jalr	-170(ra) # 80001202 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012b4:	00007497          	auipc	s1,0x7
    800012b8:	d4c48493          	addi	s1,s1,-692 # 80008000 <etext>
    800012bc:	46a9                	li	a3,10
    800012be:	80007617          	auipc	a2,0x80007
    800012c2:	d4260613          	addi	a2,a2,-702 # 8000 <_entry-0x7fff8000>
    800012c6:	4585                	li	a1,1
    800012c8:	05fe                	slli	a1,a1,0x1f
    800012ca:	852e                	mv	a0,a1
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	f36080e7          	jalr	-202(ra) # 80001202 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012d4:	4699                	li	a3,6
    800012d6:	4645                	li	a2,17
    800012d8:	066e                	slli	a2,a2,0x1b
    800012da:	8e05                	sub	a2,a2,s1
    800012dc:	85a6                	mv	a1,s1
    800012de:	8526                	mv	a0,s1
    800012e0:	00000097          	auipc	ra,0x0
    800012e4:	f22080e7          	jalr	-222(ra) # 80001202 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012e8:	46a9                	li	a3,10
    800012ea:	6605                	lui	a2,0x1
    800012ec:	00006597          	auipc	a1,0x6
    800012f0:	d1458593          	addi	a1,a1,-748 # 80007000 <_trampoline>
    800012f4:	04000537          	lui	a0,0x4000
    800012f8:	157d                	addi	a0,a0,-1
    800012fa:	0532                	slli	a0,a0,0xc
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	f06080e7          	jalr	-250(ra) # 80001202 <kvmmap>
}
    80001304:	60e2                	ld	ra,24(sp)
    80001306:	6442                	ld	s0,16(sp)
    80001308:	64a2                	ld	s1,8(sp)
    8000130a:	6105                	addi	sp,sp,32
    8000130c:	8082                	ret

000000008000130e <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000130e:	715d                	addi	sp,sp,-80
    80001310:	e486                	sd	ra,72(sp)
    80001312:	e0a2                	sd	s0,64(sp)
    80001314:	fc26                	sd	s1,56(sp)
    80001316:	f84a                	sd	s2,48(sp)
    80001318:	f44e                	sd	s3,40(sp)
    8000131a:	f052                	sd	s4,32(sp)
    8000131c:	ec56                	sd	s5,24(sp)
    8000131e:	e85a                	sd	s6,16(sp)
    80001320:	e45e                	sd	s7,8(sp)
    80001322:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001324:	6785                	lui	a5,0x1
    80001326:	17fd                	addi	a5,a5,-1
    80001328:	8fed                	and	a5,a5,a1
    8000132a:	e795                	bnez	a5,80001356 <uvmunmap+0x48>
    8000132c:	8a2a                	mv	s4,a0
    8000132e:	84ae                	mv	s1,a1
    80001330:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001332:	0632                	slli	a2,a2,0xc
    80001334:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      continue; //panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue; //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001338:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000133a:	6b05                	lui	s6,0x1
    8000133c:	0535e863          	bltu	a1,s3,8000138c <uvmunmap+0x7e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001340:	60a6                	ld	ra,72(sp)
    80001342:	6406                	ld	s0,64(sp)
    80001344:	74e2                	ld	s1,56(sp)
    80001346:	7942                	ld	s2,48(sp)
    80001348:	79a2                	ld	s3,40(sp)
    8000134a:	7a02                	ld	s4,32(sp)
    8000134c:	6ae2                	ld	s5,24(sp)
    8000134e:	6b42                	ld	s6,16(sp)
    80001350:	6ba2                	ld	s7,8(sp)
    80001352:	6161                	addi	sp,sp,80
    80001354:	8082                	ret
    panic("uvmunmap: not aligned");
    80001356:	00007517          	auipc	a0,0x7
    8000135a:	d9a50513          	addi	a0,a0,-614 # 800080f0 <digits+0xd8>
    8000135e:	fffff097          	auipc	ra,0xfffff
    80001362:	216080e7          	jalr	534(ra) # 80000574 <panic>
      panic("uvmunmap: not a leaf");
    80001366:	00007517          	auipc	a0,0x7
    8000136a:	da250513          	addi	a0,a0,-606 # 80008108 <digits+0xf0>
    8000136e:	fffff097          	auipc	ra,0xfffff
    80001372:	206080e7          	jalr	518(ra) # 80000574 <panic>
      uint64 pa = PTE2PA(*pte);
    80001376:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001378:	0532                	slli	a0,a0,0xc
    8000137a:	fffff097          	auipc	ra,0xfffff
    8000137e:	6f8080e7          	jalr	1784(ra) # 80000a72 <kfree>
    *pte = 0;
    80001382:	00093023          	sd	zero,0(s2)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001386:	94da                	add	s1,s1,s6
    80001388:	fb34fce3          	bleu	s3,s1,80001340 <uvmunmap+0x32>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000138c:	4601                	li	a2,0
    8000138e:	85a6                	mv	a1,s1
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	cdc080e7          	jalr	-804(ra) # 8000106e <walk>
    8000139a:	892a                	mv	s2,a0
    8000139c:	d56d                	beqz	a0,80001386 <uvmunmap+0x78>
    if((*pte & PTE_V) == 0)
    8000139e:	6108                	ld	a0,0(a0)
    800013a0:	00157793          	andi	a5,a0,1
    800013a4:	d3ed                	beqz	a5,80001386 <uvmunmap+0x78>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013a6:	3ff57793          	andi	a5,a0,1023
    800013aa:	fb778ee3          	beq	a5,s7,80001366 <uvmunmap+0x58>
    if(do_free){
    800013ae:	fc0a8ae3          	beqz	s5,80001382 <uvmunmap+0x74>
    800013b2:	b7d1                	j	80001376 <uvmunmap+0x68>

00000000800013b4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013b4:	1101                	addi	sp,sp,-32
    800013b6:	ec06                	sd	ra,24(sp)
    800013b8:	e822                	sd	s0,16(sp)
    800013ba:	e426                	sd	s1,8(sp)
    800013bc:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013be:	fffff097          	auipc	ra,0xfffff
    800013c2:	7b4080e7          	jalr	1972(ra) # 80000b72 <kalloc>
    800013c6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013c8:	c519                	beqz	a0,800013d6 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013ca:	6605                	lui	a2,0x1
    800013cc:	4581                	li	a1,0
    800013ce:	00000097          	auipc	ra,0x0
    800013d2:	990080e7          	jalr	-1648(ra) # 80000d5e <memset>
  return pagetable;
}
    800013d6:	8526                	mv	a0,s1
    800013d8:	60e2                	ld	ra,24(sp)
    800013da:	6442                	ld	s0,16(sp)
    800013dc:	64a2                	ld	s1,8(sp)
    800013de:	6105                	addi	sp,sp,32
    800013e0:	8082                	ret

00000000800013e2 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013e2:	7179                	addi	sp,sp,-48
    800013e4:	f406                	sd	ra,40(sp)
    800013e6:	f022                	sd	s0,32(sp)
    800013e8:	ec26                	sd	s1,24(sp)
    800013ea:	e84a                	sd	s2,16(sp)
    800013ec:	e44e                	sd	s3,8(sp)
    800013ee:	e052                	sd	s4,0(sp)
    800013f0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013f2:	6785                	lui	a5,0x1
    800013f4:	04f67863          	bleu	a5,a2,80001444 <uvminit+0x62>
    800013f8:	8a2a                	mv	s4,a0
    800013fa:	89ae                	mv	s3,a1
    800013fc:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013fe:	fffff097          	auipc	ra,0xfffff
    80001402:	774080e7          	jalr	1908(ra) # 80000b72 <kalloc>
    80001406:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001408:	6605                	lui	a2,0x1
    8000140a:	4581                	li	a1,0
    8000140c:	00000097          	auipc	ra,0x0
    80001410:	952080e7          	jalr	-1710(ra) # 80000d5e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001414:	4779                	li	a4,30
    80001416:	86ca                	mv	a3,s2
    80001418:	6605                	lui	a2,0x1
    8000141a:	4581                	li	a1,0
    8000141c:	8552                	mv	a0,s4
    8000141e:	00000097          	auipc	ra,0x0
    80001422:	d58080e7          	jalr	-680(ra) # 80001176 <mappages>
  memmove(mem, src, sz);
    80001426:	8626                	mv	a2,s1
    80001428:	85ce                	mv	a1,s3
    8000142a:	854a                	mv	a0,s2
    8000142c:	00000097          	auipc	ra,0x0
    80001430:	99e080e7          	jalr	-1634(ra) # 80000dca <memmove>
}
    80001434:	70a2                	ld	ra,40(sp)
    80001436:	7402                	ld	s0,32(sp)
    80001438:	64e2                	ld	s1,24(sp)
    8000143a:	6942                	ld	s2,16(sp)
    8000143c:	69a2                	ld	s3,8(sp)
    8000143e:	6a02                	ld	s4,0(sp)
    80001440:	6145                	addi	sp,sp,48
    80001442:	8082                	ret
    panic("inituvm: more than a page");
    80001444:	00007517          	auipc	a0,0x7
    80001448:	cdc50513          	addi	a0,a0,-804 # 80008120 <digits+0x108>
    8000144c:	fffff097          	auipc	ra,0xfffff
    80001450:	128080e7          	jalr	296(ra) # 80000574 <panic>

0000000080001454 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001454:	1101                	addi	sp,sp,-32
    80001456:	ec06                	sd	ra,24(sp)
    80001458:	e822                	sd	s0,16(sp)
    8000145a:	e426                	sd	s1,8(sp)
    8000145c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000145e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001460:	00b67d63          	bleu	a1,a2,8000147a <uvmdealloc+0x26>
    80001464:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001466:	6605                	lui	a2,0x1
    80001468:	167d                	addi	a2,a2,-1
    8000146a:	00c487b3          	add	a5,s1,a2
    8000146e:	777d                	lui	a4,0xfffff
    80001470:	8ff9                	and	a5,a5,a4
    80001472:	962e                	add	a2,a2,a1
    80001474:	8e79                	and	a2,a2,a4
    80001476:	00c7e863          	bltu	a5,a2,80001486 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000147a:	8526                	mv	a0,s1
    8000147c:	60e2                	ld	ra,24(sp)
    8000147e:	6442                	ld	s0,16(sp)
    80001480:	64a2                	ld	s1,8(sp)
    80001482:	6105                	addi	sp,sp,32
    80001484:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001486:	8e1d                	sub	a2,a2,a5
    80001488:	8231                	srli	a2,a2,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000148a:	4685                	li	a3,1
    8000148c:	2601                	sext.w	a2,a2
    8000148e:	85be                	mv	a1,a5
    80001490:	00000097          	auipc	ra,0x0
    80001494:	e7e080e7          	jalr	-386(ra) # 8000130e <uvmunmap>
    80001498:	b7cd                	j	8000147a <uvmdealloc+0x26>

000000008000149a <uvmalloc>:
  if(newsz < oldsz)
    8000149a:	0ab66163          	bltu	a2,a1,8000153c <uvmalloc+0xa2>
{
    8000149e:	7139                	addi	sp,sp,-64
    800014a0:	fc06                	sd	ra,56(sp)
    800014a2:	f822                	sd	s0,48(sp)
    800014a4:	f426                	sd	s1,40(sp)
    800014a6:	f04a                	sd	s2,32(sp)
    800014a8:	ec4e                	sd	s3,24(sp)
    800014aa:	e852                	sd	s4,16(sp)
    800014ac:	e456                	sd	s5,8(sp)
    800014ae:	0080                	addi	s0,sp,64
  oldsz = PGROUNDUP(oldsz);
    800014b0:	6a05                	lui	s4,0x1
    800014b2:	1a7d                	addi	s4,s4,-1
    800014b4:	95d2                	add	a1,a1,s4
    800014b6:	7a7d                	lui	s4,0xfffff
    800014b8:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014bc:	08ca7263          	bleu	a2,s4,80001540 <uvmalloc+0xa6>
    800014c0:	89b2                	mv	s3,a2
    800014c2:	8aaa                	mv	s5,a0
    800014c4:	8952                	mv	s2,s4
    mem = kalloc();
    800014c6:	fffff097          	auipc	ra,0xfffff
    800014ca:	6ac080e7          	jalr	1708(ra) # 80000b72 <kalloc>
    800014ce:	84aa                	mv	s1,a0
    if(mem == 0){
    800014d0:	c51d                	beqz	a0,800014fe <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014d2:	6605                	lui	a2,0x1
    800014d4:	4581                	li	a1,0
    800014d6:	00000097          	auipc	ra,0x0
    800014da:	888080e7          	jalr	-1912(ra) # 80000d5e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014de:	4779                	li	a4,30
    800014e0:	86a6                	mv	a3,s1
    800014e2:	6605                	lui	a2,0x1
    800014e4:	85ca                	mv	a1,s2
    800014e6:	8556                	mv	a0,s5
    800014e8:	00000097          	auipc	ra,0x0
    800014ec:	c8e080e7          	jalr	-882(ra) # 80001176 <mappages>
    800014f0:	e905                	bnez	a0,80001520 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014f2:	6785                	lui	a5,0x1
    800014f4:	993e                	add	s2,s2,a5
    800014f6:	fd3968e3          	bltu	s2,s3,800014c6 <uvmalloc+0x2c>
  return newsz;
    800014fa:	854e                	mv	a0,s3
    800014fc:	a809                	j	8000150e <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014fe:	8652                	mv	a2,s4
    80001500:	85ca                	mv	a1,s2
    80001502:	8556                	mv	a0,s5
    80001504:	00000097          	auipc	ra,0x0
    80001508:	f50080e7          	jalr	-176(ra) # 80001454 <uvmdealloc>
      return 0;
    8000150c:	4501                	li	a0,0
}
    8000150e:	70e2                	ld	ra,56(sp)
    80001510:	7442                	ld	s0,48(sp)
    80001512:	74a2                	ld	s1,40(sp)
    80001514:	7902                	ld	s2,32(sp)
    80001516:	69e2                	ld	s3,24(sp)
    80001518:	6a42                	ld	s4,16(sp)
    8000151a:	6aa2                	ld	s5,8(sp)
    8000151c:	6121                	addi	sp,sp,64
    8000151e:	8082                	ret
      kfree(mem);
    80001520:	8526                	mv	a0,s1
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	550080e7          	jalr	1360(ra) # 80000a72 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000152a:	8652                	mv	a2,s4
    8000152c:	85ca                	mv	a1,s2
    8000152e:	8556                	mv	a0,s5
    80001530:	00000097          	auipc	ra,0x0
    80001534:	f24080e7          	jalr	-220(ra) # 80001454 <uvmdealloc>
      return 0;
    80001538:	4501                	li	a0,0
    8000153a:	bfd1                	j	8000150e <uvmalloc+0x74>
    return oldsz;
    8000153c:	852e                	mv	a0,a1
}
    8000153e:	8082                	ret
  return newsz;
    80001540:	8532                	mv	a0,a2
    80001542:	b7f1                	j	8000150e <uvmalloc+0x74>

0000000080001544 <walkaddr>:
{
    80001544:	7179                	addi	sp,sp,-48
    80001546:	f406                	sd	ra,40(sp)
    80001548:	f022                	sd	s0,32(sp)
    8000154a:	ec26                	sd	s1,24(sp)
    8000154c:	e84a                	sd	s2,16(sp)
    8000154e:	e44e                	sd	s3,8(sp)
    80001550:	1800                	addi	s0,sp,48
    80001552:	89aa                	mv	s3,a0
    80001554:	84ae                	mv	s1,a1
struct proc* p = myproc(); //new
    80001556:	00000097          	auipc	ra,0x0
    8000155a:	53a080e7          	jalr	1338(ra) # 80001a90 <myproc>
  if(va >= MAXVA)
    8000155e:	57fd                	li	a5,-1
    80001560:	83e9                	srli	a5,a5,0x1a
    80001562:	0097fa63          	bleu	s1,a5,80001576 <walkaddr+0x32>
    return 0;
    80001566:	4501                	li	a0,0
}
    80001568:	70a2                	ld	ra,40(sp)
    8000156a:	7402                	ld	s0,32(sp)
    8000156c:	64e2                	ld	s1,24(sp)
    8000156e:	6942                	ld	s2,16(sp)
    80001570:	69a2                	ld	s3,8(sp)
    80001572:	6145                	addi	sp,sp,48
    80001574:	8082                	ret
    80001576:	892a                	mv	s2,a0
  pte = walk(pagetable, va, 0);
    80001578:	4601                	li	a2,0
    8000157a:	85a6                	mv	a1,s1
    8000157c:	854e                	mv	a0,s3
    8000157e:	00000097          	auipc	ra,0x0
    80001582:	af0080e7          	jalr	-1296(ra) # 8000106e <walk>
  if(pte == 0 || (*pte & PTE_V) == 0) {
    80001586:	c509                	beqz	a0,80001590 <walkaddr+0x4c>
    80001588:	611c                	ld	a5,0(a0)
    8000158a:	0017f713          	andi	a4,a5,1
    8000158e:	e339                	bnez	a4,800015d4 <walkaddr+0x90>
    if (va >= p->sz || va < PGROUNDUP(p->trapframe->sp) || va >= MAXVA) { // pagefault的地址大于sbrk的最大值
    80001590:	04893783          	ld	a5,72(s2)
      return 0;
    80001594:	4501                	li	a0,0
    if (va >= p->sz || va < PGROUNDUP(p->trapframe->sp) || va >= MAXVA) { // pagefault的地址大于sbrk的最大值
    80001596:	fcf4f9e3          	bleu	a5,s1,80001568 <walkaddr+0x24>
    8000159a:	05893783          	ld	a5,88(s2)
    8000159e:	7b9c                	ld	a5,48(a5)
    800015a0:	6705                	lui	a4,0x1
    800015a2:	177d                	addi	a4,a4,-1
    800015a4:	97ba                	add	a5,a5,a4
    800015a6:	777d                	lui	a4,0xfffff
    800015a8:	8ff9                	and	a5,a5,a4
    800015aa:	faf4efe3          	bltu	s1,a5,80001568 <walkaddr+0x24>
      if (uvmalloc(p->pagetable, PGROUNDDOWN(va), PGSIZE + PGROUNDDOWN(va)) == 0) {
    800015ae:	75fd                	lui	a1,0xfffff
    800015b0:	8de5                	and	a1,a1,s1
    800015b2:	6605                	lui	a2,0x1
    800015b4:	962e                	add	a2,a2,a1
    800015b6:	05093503          	ld	a0,80(s2)
    800015ba:	00000097          	auipc	ra,0x0
    800015be:	ee0080e7          	jalr	-288(ra) # 8000149a <uvmalloc>
    800015c2:	d15d                	beqz	a0,80001568 <walkaddr+0x24>
      return walkaddr(p->pagetable, va);
    800015c4:	85a6                	mv	a1,s1
    800015c6:	05093503          	ld	a0,80(s2)
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	f7a080e7          	jalr	-134(ra) # 80001544 <walkaddr>
    800015d2:	bf59                	j	80001568 <walkaddr+0x24>
  if((*pte & PTE_U) == 0)
    800015d4:	0107f513          	andi	a0,a5,16
    800015d8:	d941                	beqz	a0,80001568 <walkaddr+0x24>
  pa = PTE2PA(*pte);
    800015da:	00a7d513          	srli	a0,a5,0xa
    800015de:	0532                	slli	a0,a0,0xc
  return pa;
    800015e0:	b761                	j	80001568 <walkaddr+0x24>

00000000800015e2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015e2:	7179                	addi	sp,sp,-48
    800015e4:	f406                	sd	ra,40(sp)
    800015e6:	f022                	sd	s0,32(sp)
    800015e8:	ec26                	sd	s1,24(sp)
    800015ea:	e84a                	sd	s2,16(sp)
    800015ec:	e44e                	sd	s3,8(sp)
    800015ee:	e052                	sd	s4,0(sp)
    800015f0:	1800                	addi	s0,sp,48
    800015f2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015f4:	84aa                	mv	s1,a0
    800015f6:	6905                	lui	s2,0x1
    800015f8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015fa:	4985                	li	s3,1
    800015fc:	a821                	j	80001614 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015fe:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001600:	0532                	slli	a0,a0,0xc
    80001602:	00000097          	auipc	ra,0x0
    80001606:	fe0080e7          	jalr	-32(ra) # 800015e2 <freewalk>
      pagetable[i] = 0;
    8000160a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000160e:	04a1                	addi	s1,s1,8
    80001610:	03248163          	beq	s1,s2,80001632 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001614:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001616:	00f57793          	andi	a5,a0,15
    8000161a:	ff3782e3          	beq	a5,s3,800015fe <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000161e:	8905                	andi	a0,a0,1
    80001620:	d57d                	beqz	a0,8000160e <freewalk+0x2c>
      panic("freewalk: leaf");
    80001622:	00007517          	auipc	a0,0x7
    80001626:	b1e50513          	addi	a0,a0,-1250 # 80008140 <digits+0x128>
    8000162a:	fffff097          	auipc	ra,0xfffff
    8000162e:	f4a080e7          	jalr	-182(ra) # 80000574 <panic>
    }
  }
  kfree((void*)pagetable);
    80001632:	8552                	mv	a0,s4
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	43e080e7          	jalr	1086(ra) # 80000a72 <kfree>
}
    8000163c:	70a2                	ld	ra,40(sp)
    8000163e:	7402                	ld	s0,32(sp)
    80001640:	64e2                	ld	s1,24(sp)
    80001642:	6942                	ld	s2,16(sp)
    80001644:	69a2                	ld	s3,8(sp)
    80001646:	6a02                	ld	s4,0(sp)
    80001648:	6145                	addi	sp,sp,48
    8000164a:	8082                	ret

000000008000164c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000164c:	1101                	addi	sp,sp,-32
    8000164e:	ec06                	sd	ra,24(sp)
    80001650:	e822                	sd	s0,16(sp)
    80001652:	e426                	sd	s1,8(sp)
    80001654:	1000                	addi	s0,sp,32
    80001656:	84aa                	mv	s1,a0
  if(sz > 0)
    80001658:	e999                	bnez	a1,8000166e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000165a:	8526                	mv	a0,s1
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	f86080e7          	jalr	-122(ra) # 800015e2 <freewalk>
}
    80001664:	60e2                	ld	ra,24(sp)
    80001666:	6442                	ld	s0,16(sp)
    80001668:	64a2                	ld	s1,8(sp)
    8000166a:	6105                	addi	sp,sp,32
    8000166c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000166e:	6605                	lui	a2,0x1
    80001670:	167d                	addi	a2,a2,-1
    80001672:	962e                	add	a2,a2,a1
    80001674:	4685                	li	a3,1
    80001676:	8231                	srli	a2,a2,0xc
    80001678:	4581                	li	a1,0
    8000167a:	00000097          	auipc	ra,0x0
    8000167e:	c94080e7          	jalr	-876(ra) # 8000130e <uvmunmap>
    80001682:	bfe1                	j	8000165a <uvmfree+0xe>

0000000080001684 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001684:	ca4d                	beqz	a2,80001736 <uvmcopy+0xb2>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	0880                	addi	s0,sp,80
    8000169c:	8a32                	mv	s4,a2
    8000169e:	8b2e                	mv	s6,a1
    800016a0:	8aaa                	mv	s5,a0
  for(i = 0; i < sz; i += PGSIZE){
    800016a2:	4481                	li	s1,0
    800016a4:	a029                	j	800016ae <uvmcopy+0x2a>
    800016a6:	6785                	lui	a5,0x1
    800016a8:	94be                	add	s1,s1,a5
    800016aa:	0744fa63          	bleu	s4,s1,8000171e <uvmcopy+0x9a>
    if((pte = walk(old, i, 0)) == 0)
    800016ae:	4601                	li	a2,0
    800016b0:	85a6                	mv	a1,s1
    800016b2:	8556                	mv	a0,s5
    800016b4:	00000097          	auipc	ra,0x0
    800016b8:	9ba080e7          	jalr	-1606(ra) # 8000106e <walk>
    800016bc:	d56d                	beqz	a0,800016a6 <uvmcopy+0x22>
      continue; //panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016be:	6118                	ld	a4,0(a0)
    800016c0:	00177793          	andi	a5,a4,1
    800016c4:	d3ed                	beqz	a5,800016a6 <uvmcopy+0x22>
      continue; //panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016c6:	00a75793          	srli	a5,a4,0xa
    800016ca:	00c79b93          	slli	s7,a5,0xc
    flags = PTE_FLAGS(*pte);
    800016ce:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    800016d2:	fffff097          	auipc	ra,0xfffff
    800016d6:	4a0080e7          	jalr	1184(ra) # 80000b72 <kalloc>
    800016da:	89aa                	mv	s3,a0
    800016dc:	c515                	beqz	a0,80001708 <uvmcopy+0x84>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016de:	6605                	lui	a2,0x1
    800016e0:	85de                	mv	a1,s7
    800016e2:	fffff097          	auipc	ra,0xfffff
    800016e6:	6e8080e7          	jalr	1768(ra) # 80000dca <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016ea:	874a                	mv	a4,s2
    800016ec:	86ce                	mv	a3,s3
    800016ee:	6605                	lui	a2,0x1
    800016f0:	85a6                	mv	a1,s1
    800016f2:	855a                	mv	a0,s6
    800016f4:	00000097          	auipc	ra,0x0
    800016f8:	a82080e7          	jalr	-1406(ra) # 80001176 <mappages>
    800016fc:	d54d                	beqz	a0,800016a6 <uvmcopy+0x22>
      kfree(mem);
    800016fe:	854e                	mv	a0,s3
    80001700:	fffff097          	auipc	ra,0xfffff
    80001704:	372080e7          	jalr	882(ra) # 80000a72 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001708:	4685                	li	a3,1
    8000170a:	00c4d613          	srli	a2,s1,0xc
    8000170e:	4581                	li	a1,0
    80001710:	855a                	mv	a0,s6
    80001712:	00000097          	auipc	ra,0x0
    80001716:	bfc080e7          	jalr	-1028(ra) # 8000130e <uvmunmap>
  return -1;
    8000171a:	557d                	li	a0,-1
    8000171c:	a011                	j	80001720 <uvmcopy+0x9c>
  return 0;
    8000171e:	4501                	li	a0,0
}
    80001720:	60a6                	ld	ra,72(sp)
    80001722:	6406                	ld	s0,64(sp)
    80001724:	74e2                	ld	s1,56(sp)
    80001726:	7942                	ld	s2,48(sp)
    80001728:	79a2                	ld	s3,40(sp)
    8000172a:	7a02                	ld	s4,32(sp)
    8000172c:	6ae2                	ld	s5,24(sp)
    8000172e:	6b42                	ld	s6,16(sp)
    80001730:	6ba2                	ld	s7,8(sp)
    80001732:	6161                	addi	sp,sp,80
    80001734:	8082                	ret
  return 0;
    80001736:	4501                	li	a0,0
}
    80001738:	8082                	ret

000000008000173a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000173a:	1141                	addi	sp,sp,-16
    8000173c:	e406                	sd	ra,8(sp)
    8000173e:	e022                	sd	s0,0(sp)
    80001740:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001742:	4601                	li	a2,0
    80001744:	00000097          	auipc	ra,0x0
    80001748:	92a080e7          	jalr	-1750(ra) # 8000106e <walk>
  if(pte == 0)
    8000174c:	c901                	beqz	a0,8000175c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000174e:	611c                	ld	a5,0(a0)
    80001750:	9bbd                	andi	a5,a5,-17
    80001752:	e11c                	sd	a5,0(a0)
}
    80001754:	60a2                	ld	ra,8(sp)
    80001756:	6402                	ld	s0,0(sp)
    80001758:	0141                	addi	sp,sp,16
    8000175a:	8082                	ret
    panic("uvmclear");
    8000175c:	00007517          	auipc	a0,0x7
    80001760:	9f450513          	addi	a0,a0,-1548 # 80008150 <digits+0x138>
    80001764:	fffff097          	auipc	ra,0xfffff
    80001768:	e10080e7          	jalr	-496(ra) # 80000574 <panic>

000000008000176c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000176c:	c6bd                	beqz	a3,800017da <copyout+0x6e>
{
    8000176e:	715d                	addi	sp,sp,-80
    80001770:	e486                	sd	ra,72(sp)
    80001772:	e0a2                	sd	s0,64(sp)
    80001774:	fc26                	sd	s1,56(sp)
    80001776:	f84a                	sd	s2,48(sp)
    80001778:	f44e                	sd	s3,40(sp)
    8000177a:	f052                	sd	s4,32(sp)
    8000177c:	ec56                	sd	s5,24(sp)
    8000177e:	e85a                	sd	s6,16(sp)
    80001780:	e45e                	sd	s7,8(sp)
    80001782:	e062                	sd	s8,0(sp)
    80001784:	0880                	addi	s0,sp,80
    80001786:	8baa                	mv	s7,a0
    80001788:	8a2e                	mv	s4,a1
    8000178a:	8ab2                	mv	s5,a2
    8000178c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000178e:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001790:	6b05                	lui	s6,0x1
    80001792:	a015                	j	800017b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001794:	9552                	add	a0,a0,s4
    80001796:	0004861b          	sext.w	a2,s1
    8000179a:	85d6                	mv	a1,s5
    8000179c:	41250533          	sub	a0,a0,s2
    800017a0:	fffff097          	auipc	ra,0xfffff
    800017a4:	62a080e7          	jalr	1578(ra) # 80000dca <memmove>

    len -= n;
    800017a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800017ac:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    800017ae:	01690a33          	add	s4,s2,s6
  while(len > 0){
    800017b2:	02098263          	beqz	s3,800017d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017b6:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    800017ba:	85ca                	mv	a1,s2
    800017bc:	855e                	mv	a0,s7
    800017be:	00000097          	auipc	ra,0x0
    800017c2:	d86080e7          	jalr	-634(ra) # 80001544 <walkaddr>
    if(pa0 == 0)
    800017c6:	cd01                	beqz	a0,800017de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017c8:	414904b3          	sub	s1,s2,s4
    800017cc:	94da                	add	s1,s1,s6
    if(n > len)
    800017ce:	fc99f3e3          	bleu	s1,s3,80001794 <copyout+0x28>
    800017d2:	84ce                	mv	s1,s3
    800017d4:	b7c1                	j	80001794 <copyout+0x28>
  }
  return 0;
    800017d6:	4501                	li	a0,0
    800017d8:	a021                	j	800017e0 <copyout+0x74>
    800017da:	4501                	li	a0,0
}
    800017dc:	8082                	ret
      return -1;
    800017de:	557d                	li	a0,-1
}
    800017e0:	60a6                	ld	ra,72(sp)
    800017e2:	6406                	ld	s0,64(sp)
    800017e4:	74e2                	ld	s1,56(sp)
    800017e6:	7942                	ld	s2,48(sp)
    800017e8:	79a2                	ld	s3,40(sp)
    800017ea:	7a02                	ld	s4,32(sp)
    800017ec:	6ae2                	ld	s5,24(sp)
    800017ee:	6b42                	ld	s6,16(sp)
    800017f0:	6ba2                	ld	s7,8(sp)
    800017f2:	6c02                	ld	s8,0(sp)
    800017f4:	6161                	addi	sp,sp,80
    800017f6:	8082                	ret

00000000800017f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017f8:	caa5                	beqz	a3,80001868 <copyin+0x70>
{
    800017fa:	715d                	addi	sp,sp,-80
    800017fc:	e486                	sd	ra,72(sp)
    800017fe:	e0a2                	sd	s0,64(sp)
    80001800:	fc26                	sd	s1,56(sp)
    80001802:	f84a                	sd	s2,48(sp)
    80001804:	f44e                	sd	s3,40(sp)
    80001806:	f052                	sd	s4,32(sp)
    80001808:	ec56                	sd	s5,24(sp)
    8000180a:	e85a                	sd	s6,16(sp)
    8000180c:	e45e                	sd	s7,8(sp)
    8000180e:	e062                	sd	s8,0(sp)
    80001810:	0880                	addi	s0,sp,80
    80001812:	8baa                	mv	s7,a0
    80001814:	8aae                	mv	s5,a1
    80001816:	8a32                	mv	s4,a2
    80001818:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000181a:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000181c:	6b05                	lui	s6,0x1
    8000181e:	a01d                	j	80001844 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001820:	014505b3          	add	a1,a0,s4
    80001824:	0004861b          	sext.w	a2,s1
    80001828:	412585b3          	sub	a1,a1,s2
    8000182c:	8556                	mv	a0,s5
    8000182e:	fffff097          	auipc	ra,0xfffff
    80001832:	59c080e7          	jalr	1436(ra) # 80000dca <memmove>

    len -= n;
    80001836:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000183a:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    8000183c:	01690a33          	add	s4,s2,s6
  while(len > 0){
    80001840:	02098263          	beqz	s3,80001864 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001844:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    80001848:	85ca                	mv	a1,s2
    8000184a:	855e                	mv	a0,s7
    8000184c:	00000097          	auipc	ra,0x0
    80001850:	cf8080e7          	jalr	-776(ra) # 80001544 <walkaddr>
    if(pa0 == 0)
    80001854:	cd01                	beqz	a0,8000186c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001856:	414904b3          	sub	s1,s2,s4
    8000185a:	94da                	add	s1,s1,s6
    if(n > len)
    8000185c:	fc99f2e3          	bleu	s1,s3,80001820 <copyin+0x28>
    80001860:	84ce                	mv	s1,s3
    80001862:	bf7d                	j	80001820 <copyin+0x28>
  }
  return 0;
    80001864:	4501                	li	a0,0
    80001866:	a021                	j	8000186e <copyin+0x76>
    80001868:	4501                	li	a0,0
}
    8000186a:	8082                	ret
      return -1;
    8000186c:	557d                	li	a0,-1
}
    8000186e:	60a6                	ld	ra,72(sp)
    80001870:	6406                	ld	s0,64(sp)
    80001872:	74e2                	ld	s1,56(sp)
    80001874:	7942                	ld	s2,48(sp)
    80001876:	79a2                	ld	s3,40(sp)
    80001878:	7a02                	ld	s4,32(sp)
    8000187a:	6ae2                	ld	s5,24(sp)
    8000187c:	6b42                	ld	s6,16(sp)
    8000187e:	6ba2                	ld	s7,8(sp)
    80001880:	6c02                	ld	s8,0(sp)
    80001882:	6161                	addi	sp,sp,80
    80001884:	8082                	ret

0000000080001886 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001886:	ced5                	beqz	a3,80001942 <copyinstr+0xbc>
{
    80001888:	715d                	addi	sp,sp,-80
    8000188a:	e486                	sd	ra,72(sp)
    8000188c:	e0a2                	sd	s0,64(sp)
    8000188e:	fc26                	sd	s1,56(sp)
    80001890:	f84a                	sd	s2,48(sp)
    80001892:	f44e                	sd	s3,40(sp)
    80001894:	f052                	sd	s4,32(sp)
    80001896:	ec56                	sd	s5,24(sp)
    80001898:	e85a                	sd	s6,16(sp)
    8000189a:	e45e                	sd	s7,8(sp)
    8000189c:	e062                	sd	s8,0(sp)
    8000189e:	0880                	addi	s0,sp,80
    800018a0:	8aaa                	mv	s5,a0
    800018a2:	84ae                	mv	s1,a1
    800018a4:	8c32                	mv	s8,a2
    800018a6:	8bb6                	mv	s7,a3
    va0 = PGROUNDDOWN(srcva);
    800018a8:	7a7d                	lui	s4,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018aa:	6985                	lui	s3,0x1
    800018ac:	4b05                	li	s6,1
    800018ae:	a801                	j	800018be <copyinstr+0x38>
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
    800018b0:	87a6                	mv	a5,s1
    800018b2:	a085                	j	80001912 <copyinstr+0x8c>
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    800018b4:	84b2                	mv	s1,a2
    }

    srcva = va0 + PGSIZE;
    800018b6:	01390c33          	add	s8,s2,s3
  while(got_null == 0 && max > 0){
    800018ba:	080b8063          	beqz	s7,8000193a <copyinstr+0xb4>
    va0 = PGROUNDDOWN(srcva);
    800018be:	014c7933          	and	s2,s8,s4
    pa0 = walkaddr(pagetable, va0);
    800018c2:	85ca                	mv	a1,s2
    800018c4:	8556                	mv	a0,s5
    800018c6:	00000097          	auipc	ra,0x0
    800018ca:	c7e080e7          	jalr	-898(ra) # 80001544 <walkaddr>
    if(pa0 == 0)
    800018ce:	c925                	beqz	a0,8000193e <copyinstr+0xb8>
    n = PGSIZE - (srcva - va0);
    800018d0:	41890633          	sub	a2,s2,s8
    800018d4:	964e                	add	a2,a2,s3
    if(n > max)
    800018d6:	00cbf363          	bleu	a2,s7,800018dc <copyinstr+0x56>
    800018da:	865e                	mv	a2,s7
    char *p = (char *) (pa0 + (srcva - va0));
    800018dc:	9562                	add	a0,a0,s8
    800018de:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018e2:	da71                	beqz	a2,800018b6 <copyinstr+0x30>
      if(*p == '\0'){
    800018e4:	00054703          	lbu	a4,0(a0)
    800018e8:	d761                	beqz	a4,800018b0 <copyinstr+0x2a>
    800018ea:	9626                	add	a2,a2,s1
    800018ec:	87a6                	mv	a5,s1
    800018ee:	1bfd                	addi	s7,s7,-1
    800018f0:	009b86b3          	add	a3,s7,s1
    800018f4:	409b04b3          	sub	s1,s6,s1
    800018f8:	94aa                	add	s1,s1,a0
        *dst = *p;
    800018fa:	00e78023          	sb	a4,0(a5) # 1000 <_entry-0x7ffff000>
      --max;
    800018fe:	40f68bb3          	sub	s7,a3,a5
      p++;
    80001902:	00f48733          	add	a4,s1,a5
      dst++;
    80001906:	0785                	addi	a5,a5,1
    while(n > 0){
    80001908:	faf606e3          	beq	a2,a5,800018b4 <copyinstr+0x2e>
      if(*p == '\0'){
    8000190c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001910:	f76d                	bnez	a4,800018fa <copyinstr+0x74>
        *dst = '\0';
    80001912:	00078023          	sb	zero,0(a5)
    80001916:	4785                	li	a5,1
  }
  if(got_null){
    80001918:	0017b513          	seqz	a0,a5
    8000191c:	40a0053b          	negw	a0,a0
    80001920:	2501                	sext.w	a0,a0
    return 0;
  } else {
    return -1;
  }
}
    80001922:	60a6                	ld	ra,72(sp)
    80001924:	6406                	ld	s0,64(sp)
    80001926:	74e2                	ld	s1,56(sp)
    80001928:	7942                	ld	s2,48(sp)
    8000192a:	79a2                	ld	s3,40(sp)
    8000192c:	7a02                	ld	s4,32(sp)
    8000192e:	6ae2                	ld	s5,24(sp)
    80001930:	6b42                	ld	s6,16(sp)
    80001932:	6ba2                	ld	s7,8(sp)
    80001934:	6c02                	ld	s8,0(sp)
    80001936:	6161                	addi	sp,sp,80
    80001938:	8082                	ret
    8000193a:	4781                	li	a5,0
    8000193c:	bff1                	j	80001918 <copyinstr+0x92>
      return -1;
    8000193e:	557d                	li	a0,-1
    80001940:	b7cd                	j	80001922 <copyinstr+0x9c>
  int got_null = 0;
    80001942:	4781                	li	a5,0
  if(got_null){
    80001944:	0017b513          	seqz	a0,a5
    80001948:	40a0053b          	negw	a0,a0
    8000194c:	2501                	sext.w	a0,a0
}
    8000194e:	8082                	ret

0000000080001950 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001950:	1101                	addi	sp,sp,-32
    80001952:	ec06                	sd	ra,24(sp)
    80001954:	e822                	sd	s0,16(sp)
    80001956:	e426                	sd	s1,8(sp)
    80001958:	1000                	addi	s0,sp,32
    8000195a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000195c:	fffff097          	auipc	ra,0xfffff
    80001960:	28c080e7          	jalr	652(ra) # 80000be8 <holding>
    80001964:	c909                	beqz	a0,80001976 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001966:	749c                	ld	a5,40(s1)
    80001968:	00978f63          	beq	a5,s1,80001986 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000196c:	60e2                	ld	ra,24(sp)
    8000196e:	6442                	ld	s0,16(sp)
    80001970:	64a2                	ld	s1,8(sp)
    80001972:	6105                	addi	sp,sp,32
    80001974:	8082                	ret
    panic("wakeup1");
    80001976:	00007517          	auipc	a0,0x7
    8000197a:	81250513          	addi	a0,a0,-2030 # 80008188 <states.1722+0x28>
    8000197e:	fffff097          	auipc	ra,0xfffff
    80001982:	bf6080e7          	jalr	-1034(ra) # 80000574 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001986:	4c98                	lw	a4,24(s1)
    80001988:	4785                	li	a5,1
    8000198a:	fef711e3          	bne	a4,a5,8000196c <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000198e:	4789                	li	a5,2
    80001990:	cc9c                	sw	a5,24(s1)
}
    80001992:	bfe9                	j	8000196c <wakeup1+0x1c>

0000000080001994 <procinit>:
{
    80001994:	715d                	addi	sp,sp,-80
    80001996:	e486                	sd	ra,72(sp)
    80001998:	e0a2                	sd	s0,64(sp)
    8000199a:	fc26                	sd	s1,56(sp)
    8000199c:	f84a                	sd	s2,48(sp)
    8000199e:	f44e                	sd	s3,40(sp)
    800019a0:	f052                	sd	s4,32(sp)
    800019a2:	ec56                	sd	s5,24(sp)
    800019a4:	e85a                	sd	s6,16(sp)
    800019a6:	e45e                	sd	s7,8(sp)
    800019a8:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800019aa:	00006597          	auipc	a1,0x6
    800019ae:	7e658593          	addi	a1,a1,2022 # 80008190 <states.1722+0x30>
    800019b2:	00010517          	auipc	a0,0x10
    800019b6:	f9e50513          	addi	a0,a0,-98 # 80011950 <pid_lock>
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	218080e7          	jalr	536(ra) # 80000bd2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c2:	00010917          	auipc	s2,0x10
    800019c6:	3a690913          	addi	s2,s2,934 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    800019ca:	00006b97          	auipc	s7,0x6
    800019ce:	7ceb8b93          	addi	s7,s7,1998 # 80008198 <states.1722+0x38>
      uint64 va = KSTACK((int) (p - proc));
    800019d2:	8b4a                	mv	s6,s2
    800019d4:	00006a97          	auipc	s5,0x6
    800019d8:	62ca8a93          	addi	s5,s5,1580 # 80008000 <etext>
    800019dc:	040009b7          	lui	s3,0x4000
    800019e0:	19fd                	addi	s3,s3,-1
    800019e2:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019e4:	00016a17          	auipc	s4,0x16
    800019e8:	d84a0a13          	addi	s4,s4,-636 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    800019ec:	85de                	mv	a1,s7
    800019ee:	854a                	mv	a0,s2
    800019f0:	fffff097          	auipc	ra,0xfffff
    800019f4:	1e2080e7          	jalr	482(ra) # 80000bd2 <initlock>
      char *pa = kalloc();
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	17a080e7          	jalr	378(ra) # 80000b72 <kalloc>
    80001a00:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a02:	c929                	beqz	a0,80001a54 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a04:	416904b3          	sub	s1,s2,s6
    80001a08:	848d                	srai	s1,s1,0x3
    80001a0a:	000ab783          	ld	a5,0(s5)
    80001a0e:	02f484b3          	mul	s1,s1,a5
    80001a12:	2485                	addiw	s1,s1,1
    80001a14:	00d4949b          	slliw	s1,s1,0xd
    80001a18:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a1c:	4699                	li	a3,6
    80001a1e:	6605                	lui	a2,0x1
    80001a20:	8526                	mv	a0,s1
    80001a22:	fffff097          	auipc	ra,0xfffff
    80001a26:	7e0080e7          	jalr	2016(ra) # 80001202 <kvmmap>
      p->kstack = va;
    80001a2a:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a2e:	16890913          	addi	s2,s2,360
    80001a32:	fb491de3          	bne	s2,s4,800019ec <procinit+0x58>
  kvminithart();
    80001a36:	fffff097          	auipc	ra,0xfffff
    80001a3a:	612080e7          	jalr	1554(ra) # 80001048 <kvminithart>
}
    80001a3e:	60a6                	ld	ra,72(sp)
    80001a40:	6406                	ld	s0,64(sp)
    80001a42:	74e2                	ld	s1,56(sp)
    80001a44:	7942                	ld	s2,48(sp)
    80001a46:	79a2                	ld	s3,40(sp)
    80001a48:	7a02                	ld	s4,32(sp)
    80001a4a:	6ae2                	ld	s5,24(sp)
    80001a4c:	6b42                	ld	s6,16(sp)
    80001a4e:	6ba2                	ld	s7,8(sp)
    80001a50:	6161                	addi	sp,sp,80
    80001a52:	8082                	ret
        panic("kalloc");
    80001a54:	00006517          	auipc	a0,0x6
    80001a58:	74c50513          	addi	a0,a0,1868 # 800081a0 <states.1722+0x40>
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	b18080e7          	jalr	-1256(ra) # 80000574 <panic>

0000000080001a64 <cpuid>:
{
    80001a64:	1141                	addi	sp,sp,-16
    80001a66:	e422                	sd	s0,8(sp)
    80001a68:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a6a:	8512                	mv	a0,tp
}
    80001a6c:	2501                	sext.w	a0,a0
    80001a6e:	6422                	ld	s0,8(sp)
    80001a70:	0141                	addi	sp,sp,16
    80001a72:	8082                	ret

0000000080001a74 <mycpu>:
mycpu(void) {
    80001a74:	1141                	addi	sp,sp,-16
    80001a76:	e422                	sd	s0,8(sp)
    80001a78:	0800                	addi	s0,sp,16
    80001a7a:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a7c:	2781                	sext.w	a5,a5
    80001a7e:	079e                	slli	a5,a5,0x7
}
    80001a80:	00010517          	auipc	a0,0x10
    80001a84:	ee850513          	addi	a0,a0,-280 # 80011968 <cpus>
    80001a88:	953e                	add	a0,a0,a5
    80001a8a:	6422                	ld	s0,8(sp)
    80001a8c:	0141                	addi	sp,sp,16
    80001a8e:	8082                	ret

0000000080001a90 <myproc>:
myproc(void) {
    80001a90:	1101                	addi	sp,sp,-32
    80001a92:	ec06                	sd	ra,24(sp)
    80001a94:	e822                	sd	s0,16(sp)
    80001a96:	e426                	sd	s1,8(sp)
    80001a98:	1000                	addi	s0,sp,32
  push_off();
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	17c080e7          	jalr	380(ra) # 80000c16 <push_off>
    80001aa2:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001aa4:	2781                	sext.w	a5,a5
    80001aa6:	079e                	slli	a5,a5,0x7
    80001aa8:	00010717          	auipc	a4,0x10
    80001aac:	ea870713          	addi	a4,a4,-344 # 80011950 <pid_lock>
    80001ab0:	97ba                	add	a5,a5,a4
    80001ab2:	6f84                	ld	s1,24(a5)
  pop_off();
    80001ab4:	fffff097          	auipc	ra,0xfffff
    80001ab8:	202080e7          	jalr	514(ra) # 80000cb6 <pop_off>
}
    80001abc:	8526                	mv	a0,s1
    80001abe:	60e2                	ld	ra,24(sp)
    80001ac0:	6442                	ld	s0,16(sp)
    80001ac2:	64a2                	ld	s1,8(sp)
    80001ac4:	6105                	addi	sp,sp,32
    80001ac6:	8082                	ret

0000000080001ac8 <forkret>:
{
    80001ac8:	1141                	addi	sp,sp,-16
    80001aca:	e406                	sd	ra,8(sp)
    80001acc:	e022                	sd	s0,0(sp)
    80001ace:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001ad0:	00000097          	auipc	ra,0x0
    80001ad4:	fc0080e7          	jalr	-64(ra) # 80001a90 <myproc>
    80001ad8:	fffff097          	auipc	ra,0xfffff
    80001adc:	23e080e7          	jalr	574(ra) # 80000d16 <release>
  if (first) {
    80001ae0:	00007797          	auipc	a5,0x7
    80001ae4:	cd078793          	addi	a5,a5,-816 # 800087b0 <first.1682>
    80001ae8:	439c                	lw	a5,0(a5)
    80001aea:	eb89                	bnez	a5,80001afc <forkret+0x34>
  usertrapret();
    80001aec:	00001097          	auipc	ra,0x1
    80001af0:	c26080e7          	jalr	-986(ra) # 80002712 <usertrapret>
}
    80001af4:	60a2                	ld	ra,8(sp)
    80001af6:	6402                	ld	s0,0(sp)
    80001af8:	0141                	addi	sp,sp,16
    80001afa:	8082                	ret
    first = 0;
    80001afc:	00007797          	auipc	a5,0x7
    80001b00:	ca07aa23          	sw	zero,-844(a5) # 800087b0 <first.1682>
    fsinit(ROOTDEV);
    80001b04:	4505                	li	a0,1
    80001b06:	00002097          	auipc	ra,0x2
    80001b0a:	a1a080e7          	jalr	-1510(ra) # 80003520 <fsinit>
    80001b0e:	bff9                	j	80001aec <forkret+0x24>

0000000080001b10 <allocpid>:
allocpid() {
    80001b10:	1101                	addi	sp,sp,-32
    80001b12:	ec06                	sd	ra,24(sp)
    80001b14:	e822                	sd	s0,16(sp)
    80001b16:	e426                	sd	s1,8(sp)
    80001b18:	e04a                	sd	s2,0(sp)
    80001b1a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b1c:	00010917          	auipc	s2,0x10
    80001b20:	e3490913          	addi	s2,s2,-460 # 80011950 <pid_lock>
    80001b24:	854a                	mv	a0,s2
    80001b26:	fffff097          	auipc	ra,0xfffff
    80001b2a:	13c080e7          	jalr	316(ra) # 80000c62 <acquire>
  pid = nextpid;
    80001b2e:	00007797          	auipc	a5,0x7
    80001b32:	c8678793          	addi	a5,a5,-890 # 800087b4 <nextpid>
    80001b36:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b38:	0014871b          	addiw	a4,s1,1
    80001b3c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b3e:	854a                	mv	a0,s2
    80001b40:	fffff097          	auipc	ra,0xfffff
    80001b44:	1d6080e7          	jalr	470(ra) # 80000d16 <release>
}
    80001b48:	8526                	mv	a0,s1
    80001b4a:	60e2                	ld	ra,24(sp)
    80001b4c:	6442                	ld	s0,16(sp)
    80001b4e:	64a2                	ld	s1,8(sp)
    80001b50:	6902                	ld	s2,0(sp)
    80001b52:	6105                	addi	sp,sp,32
    80001b54:	8082                	ret

0000000080001b56 <proc_pagetable>:
{
    80001b56:	1101                	addi	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	e04a                	sd	s2,0(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	850080e7          	jalr	-1968(ra) # 800013b4 <uvmcreate>
    80001b6c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b6e:	c121                	beqz	a0,80001bae <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b70:	4729                	li	a4,10
    80001b72:	00005697          	auipc	a3,0x5
    80001b76:	48e68693          	addi	a3,a3,1166 # 80007000 <_trampoline>
    80001b7a:	6605                	lui	a2,0x1
    80001b7c:	040005b7          	lui	a1,0x4000
    80001b80:	15fd                	addi	a1,a1,-1
    80001b82:	05b2                	slli	a1,a1,0xc
    80001b84:	fffff097          	auipc	ra,0xfffff
    80001b88:	5f2080e7          	jalr	1522(ra) # 80001176 <mappages>
    80001b8c:	02054863          	bltz	a0,80001bbc <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b90:	4719                	li	a4,6
    80001b92:	05893683          	ld	a3,88(s2)
    80001b96:	6605                	lui	a2,0x1
    80001b98:	020005b7          	lui	a1,0x2000
    80001b9c:	15fd                	addi	a1,a1,-1
    80001b9e:	05b6                	slli	a1,a1,0xd
    80001ba0:	8526                	mv	a0,s1
    80001ba2:	fffff097          	auipc	ra,0xfffff
    80001ba6:	5d4080e7          	jalr	1492(ra) # 80001176 <mappages>
    80001baa:	02054163          	bltz	a0,80001bcc <proc_pagetable+0x76>
}
    80001bae:	8526                	mv	a0,s1
    80001bb0:	60e2                	ld	ra,24(sp)
    80001bb2:	6442                	ld	s0,16(sp)
    80001bb4:	64a2                	ld	s1,8(sp)
    80001bb6:	6902                	ld	s2,0(sp)
    80001bb8:	6105                	addi	sp,sp,32
    80001bba:	8082                	ret
    uvmfree(pagetable, 0);
    80001bbc:	4581                	li	a1,0
    80001bbe:	8526                	mv	a0,s1
    80001bc0:	00000097          	auipc	ra,0x0
    80001bc4:	a8c080e7          	jalr	-1396(ra) # 8000164c <uvmfree>
    return 0;
    80001bc8:	4481                	li	s1,0
    80001bca:	b7d5                	j	80001bae <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bcc:	4681                	li	a3,0
    80001bce:	4605                	li	a2,1
    80001bd0:	040005b7          	lui	a1,0x4000
    80001bd4:	15fd                	addi	a1,a1,-1
    80001bd6:	05b2                	slli	a1,a1,0xc
    80001bd8:	8526                	mv	a0,s1
    80001bda:	fffff097          	auipc	ra,0xfffff
    80001bde:	734080e7          	jalr	1844(ra) # 8000130e <uvmunmap>
    uvmfree(pagetable, 0);
    80001be2:	4581                	li	a1,0
    80001be4:	8526                	mv	a0,s1
    80001be6:	00000097          	auipc	ra,0x0
    80001bea:	a66080e7          	jalr	-1434(ra) # 8000164c <uvmfree>
    return 0;
    80001bee:	4481                	li	s1,0
    80001bf0:	bf7d                	j	80001bae <proc_pagetable+0x58>

0000000080001bf2 <proc_freepagetable>:
{
    80001bf2:	1101                	addi	sp,sp,-32
    80001bf4:	ec06                	sd	ra,24(sp)
    80001bf6:	e822                	sd	s0,16(sp)
    80001bf8:	e426                	sd	s1,8(sp)
    80001bfa:	e04a                	sd	s2,0(sp)
    80001bfc:	1000                	addi	s0,sp,32
    80001bfe:	84aa                	mv	s1,a0
    80001c00:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c02:	4681                	li	a3,0
    80001c04:	4605                	li	a2,1
    80001c06:	040005b7          	lui	a1,0x4000
    80001c0a:	15fd                	addi	a1,a1,-1
    80001c0c:	05b2                	slli	a1,a1,0xc
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	700080e7          	jalr	1792(ra) # 8000130e <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c16:	4681                	li	a3,0
    80001c18:	4605                	li	a2,1
    80001c1a:	020005b7          	lui	a1,0x2000
    80001c1e:	15fd                	addi	a1,a1,-1
    80001c20:	05b6                	slli	a1,a1,0xd
    80001c22:	8526                	mv	a0,s1
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	6ea080e7          	jalr	1770(ra) # 8000130e <uvmunmap>
  uvmfree(pagetable, sz);
    80001c2c:	85ca                	mv	a1,s2
    80001c2e:	8526                	mv	a0,s1
    80001c30:	00000097          	auipc	ra,0x0
    80001c34:	a1c080e7          	jalr	-1508(ra) # 8000164c <uvmfree>
}
    80001c38:	60e2                	ld	ra,24(sp)
    80001c3a:	6442                	ld	s0,16(sp)
    80001c3c:	64a2                	ld	s1,8(sp)
    80001c3e:	6902                	ld	s2,0(sp)
    80001c40:	6105                	addi	sp,sp,32
    80001c42:	8082                	ret

0000000080001c44 <freeproc>:
{
    80001c44:	1101                	addi	sp,sp,-32
    80001c46:	ec06                	sd	ra,24(sp)
    80001c48:	e822                	sd	s0,16(sp)
    80001c4a:	e426                	sd	s1,8(sp)
    80001c4c:	1000                	addi	s0,sp,32
    80001c4e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c50:	6d28                	ld	a0,88(a0)
    80001c52:	c509                	beqz	a0,80001c5c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c54:	fffff097          	auipc	ra,0xfffff
    80001c58:	e1e080e7          	jalr	-482(ra) # 80000a72 <kfree>
  p->trapframe = 0;
    80001c5c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c60:	68a8                	ld	a0,80(s1)
    80001c62:	c511                	beqz	a0,80001c6e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c64:	64ac                	ld	a1,72(s1)
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	f8c080e7          	jalr	-116(ra) # 80001bf2 <proc_freepagetable>
  p->pagetable = 0;
    80001c6e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c72:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c76:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c7a:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c7e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c82:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c86:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c8a:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c8e:	0004ac23          	sw	zero,24(s1)
}
    80001c92:	60e2                	ld	ra,24(sp)
    80001c94:	6442                	ld	s0,16(sp)
    80001c96:	64a2                	ld	s1,8(sp)
    80001c98:	6105                	addi	sp,sp,32
    80001c9a:	8082                	ret

0000000080001c9c <allocproc>:
{
    80001c9c:	1101                	addi	sp,sp,-32
    80001c9e:	ec06                	sd	ra,24(sp)
    80001ca0:	e822                	sd	s0,16(sp)
    80001ca2:	e426                	sd	s1,8(sp)
    80001ca4:	e04a                	sd	s2,0(sp)
    80001ca6:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ca8:	00010497          	auipc	s1,0x10
    80001cac:	0c048493          	addi	s1,s1,192 # 80011d68 <proc>
    80001cb0:	00016917          	auipc	s2,0x16
    80001cb4:	ab890913          	addi	s2,s2,-1352 # 80017768 <tickslock>
    acquire(&p->lock);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	fa8080e7          	jalr	-88(ra) # 80000c62 <acquire>
    if(p->state == UNUSED) {
    80001cc2:	4c9c                	lw	a5,24(s1)
    80001cc4:	cf81                	beqz	a5,80001cdc <allocproc+0x40>
      release(&p->lock);
    80001cc6:	8526                	mv	a0,s1
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	04e080e7          	jalr	78(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd0:	16848493          	addi	s1,s1,360
    80001cd4:	ff2492e3          	bne	s1,s2,80001cb8 <allocproc+0x1c>
  return 0;
    80001cd8:	4481                	li	s1,0
    80001cda:	a0b9                	j	80001d28 <allocproc+0x8c>
  p->pid = allocpid();
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	e34080e7          	jalr	-460(ra) # 80001b10 <allocpid>
    80001ce4:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	e8c080e7          	jalr	-372(ra) # 80000b72 <kalloc>
    80001cee:	892a                	mv	s2,a0
    80001cf0:	eca8                	sd	a0,88(s1)
    80001cf2:	c131                	beqz	a0,80001d36 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	e60080e7          	jalr	-416(ra) # 80001b56 <proc_pagetable>
    80001cfe:	892a                	mv	s2,a0
    80001d00:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d02:	c129                	beqz	a0,80001d44 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d04:	07000613          	li	a2,112
    80001d08:	4581                	li	a1,0
    80001d0a:	06048513          	addi	a0,s1,96
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	050080e7          	jalr	80(ra) # 80000d5e <memset>
  p->context.ra = (uint64)forkret;
    80001d16:	00000797          	auipc	a5,0x0
    80001d1a:	db278793          	addi	a5,a5,-590 # 80001ac8 <forkret>
    80001d1e:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d20:	60bc                	ld	a5,64(s1)
    80001d22:	6705                	lui	a4,0x1
    80001d24:	97ba                	add	a5,a5,a4
    80001d26:	f4bc                	sd	a5,104(s1)
}
    80001d28:	8526                	mv	a0,s1
    80001d2a:	60e2                	ld	ra,24(sp)
    80001d2c:	6442                	ld	s0,16(sp)
    80001d2e:	64a2                	ld	s1,8(sp)
    80001d30:	6902                	ld	s2,0(sp)
    80001d32:	6105                	addi	sp,sp,32
    80001d34:	8082                	ret
    release(&p->lock);
    80001d36:	8526                	mv	a0,s1
    80001d38:	fffff097          	auipc	ra,0xfffff
    80001d3c:	fde080e7          	jalr	-34(ra) # 80000d16 <release>
    return 0;
    80001d40:	84ca                	mv	s1,s2
    80001d42:	b7dd                	j	80001d28 <allocproc+0x8c>
    freeproc(p);
    80001d44:	8526                	mv	a0,s1
    80001d46:	00000097          	auipc	ra,0x0
    80001d4a:	efe080e7          	jalr	-258(ra) # 80001c44 <freeproc>
    release(&p->lock);
    80001d4e:	8526                	mv	a0,s1
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	fc6080e7          	jalr	-58(ra) # 80000d16 <release>
    return 0;
    80001d58:	84ca                	mv	s1,s2
    80001d5a:	b7f9                	j	80001d28 <allocproc+0x8c>

0000000080001d5c <userinit>:
{
    80001d5c:	1101                	addi	sp,sp,-32
    80001d5e:	ec06                	sd	ra,24(sp)
    80001d60:	e822                	sd	s0,16(sp)
    80001d62:	e426                	sd	s1,8(sp)
    80001d64:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d66:	00000097          	auipc	ra,0x0
    80001d6a:	f36080e7          	jalr	-202(ra) # 80001c9c <allocproc>
    80001d6e:	84aa                	mv	s1,a0
  initproc = p;
    80001d70:	00007797          	auipc	a5,0x7
    80001d74:	2aa7b423          	sd	a0,680(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d78:	03400613          	li	a2,52
    80001d7c:	00007597          	auipc	a1,0x7
    80001d80:	a4458593          	addi	a1,a1,-1468 # 800087c0 <initcode>
    80001d84:	6928                	ld	a0,80(a0)
    80001d86:	fffff097          	auipc	ra,0xfffff
    80001d8a:	65c080e7          	jalr	1628(ra) # 800013e2 <uvminit>
  p->sz = PGSIZE;
    80001d8e:	6785                	lui	a5,0x1
    80001d90:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d92:	6cb8                	ld	a4,88(s1)
    80001d94:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d98:	6cb8                	ld	a4,88(s1)
    80001d9a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d9c:	4641                	li	a2,16
    80001d9e:	00006597          	auipc	a1,0x6
    80001da2:	40a58593          	addi	a1,a1,1034 # 800081a8 <states.1722+0x48>
    80001da6:	15848513          	addi	a0,s1,344
    80001daa:	fffff097          	auipc	ra,0xfffff
    80001dae:	12c080e7          	jalr	300(ra) # 80000ed6 <safestrcpy>
  p->cwd = namei("/");
    80001db2:	00006517          	auipc	a0,0x6
    80001db6:	40650513          	addi	a0,a0,1030 # 800081b8 <states.1722+0x58>
    80001dba:	00002097          	auipc	ra,0x2
    80001dbe:	19e080e7          	jalr	414(ra) # 80003f58 <namei>
    80001dc2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001dc6:	4789                	li	a5,2
    80001dc8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001dca:	8526                	mv	a0,s1
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	f4a080e7          	jalr	-182(ra) # 80000d16 <release>
}
    80001dd4:	60e2                	ld	ra,24(sp)
    80001dd6:	6442                	ld	s0,16(sp)
    80001dd8:	64a2                	ld	s1,8(sp)
    80001dda:	6105                	addi	sp,sp,32
    80001ddc:	8082                	ret

0000000080001dde <growproc>:
{
    80001dde:	1101                	addi	sp,sp,-32
    80001de0:	ec06                	sd	ra,24(sp)
    80001de2:	e822                	sd	s0,16(sp)
    80001de4:	e426                	sd	s1,8(sp)
    80001de6:	e04a                	sd	s2,0(sp)
    80001de8:	1000                	addi	s0,sp,32
    80001dea:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	ca4080e7          	jalr	-860(ra) # 80001a90 <myproc>
    80001df4:	892a                	mv	s2,a0
  sz = p->sz;
    80001df6:	652c                	ld	a1,72(a0)
    80001df8:	0005851b          	sext.w	a0,a1
  if(n > 0){
    80001dfc:	00904f63          	bgtz	s1,80001e1a <growproc+0x3c>
  } else if(n < 0){
    80001e00:	0204cd63          	bltz	s1,80001e3a <growproc+0x5c>
  p->sz = sz;
    80001e04:	1502                	slli	a0,a0,0x20
    80001e06:	9101                	srli	a0,a0,0x20
    80001e08:	04a93423          	sd	a0,72(s2)
  return 0;
    80001e0c:	4501                	li	a0,0
}
    80001e0e:	60e2                	ld	ra,24(sp)
    80001e10:	6442                	ld	s0,16(sp)
    80001e12:	64a2                	ld	s1,8(sp)
    80001e14:	6902                	ld	s2,0(sp)
    80001e16:	6105                	addi	sp,sp,32
    80001e18:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e1a:	00a4863b          	addw	a2,s1,a0
    80001e1e:	1602                	slli	a2,a2,0x20
    80001e20:	9201                	srli	a2,a2,0x20
    80001e22:	1582                	slli	a1,a1,0x20
    80001e24:	9181                	srli	a1,a1,0x20
    80001e26:	05093503          	ld	a0,80(s2)
    80001e2a:	fffff097          	auipc	ra,0xfffff
    80001e2e:	670080e7          	jalr	1648(ra) # 8000149a <uvmalloc>
    80001e32:	2501                	sext.w	a0,a0
    80001e34:	f961                	bnez	a0,80001e04 <growproc+0x26>
      return -1;
    80001e36:	557d                	li	a0,-1
    80001e38:	bfd9                	j	80001e0e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e3a:	00a4863b          	addw	a2,s1,a0
    80001e3e:	1602                	slli	a2,a2,0x20
    80001e40:	9201                	srli	a2,a2,0x20
    80001e42:	1582                	slli	a1,a1,0x20
    80001e44:	9181                	srli	a1,a1,0x20
    80001e46:	05093503          	ld	a0,80(s2)
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	60a080e7          	jalr	1546(ra) # 80001454 <uvmdealloc>
    80001e52:	2501                	sext.w	a0,a0
    80001e54:	bf45                	j	80001e04 <growproc+0x26>

0000000080001e56 <fork>:
{
    80001e56:	7179                	addi	sp,sp,-48
    80001e58:	f406                	sd	ra,40(sp)
    80001e5a:	f022                	sd	s0,32(sp)
    80001e5c:	ec26                	sd	s1,24(sp)
    80001e5e:	e84a                	sd	s2,16(sp)
    80001e60:	e44e                	sd	s3,8(sp)
    80001e62:	e052                	sd	s4,0(sp)
    80001e64:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e66:	00000097          	auipc	ra,0x0
    80001e6a:	c2a080e7          	jalr	-982(ra) # 80001a90 <myproc>
    80001e6e:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e70:	00000097          	auipc	ra,0x0
    80001e74:	e2c080e7          	jalr	-468(ra) # 80001c9c <allocproc>
    80001e78:	c175                	beqz	a0,80001f5c <fork+0x106>
    80001e7a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e7c:	04893603          	ld	a2,72(s2)
    80001e80:	692c                	ld	a1,80(a0)
    80001e82:	05093503          	ld	a0,80(s2)
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	7fe080e7          	jalr	2046(ra) # 80001684 <uvmcopy>
    80001e8e:	04054863          	bltz	a0,80001ede <fork+0x88>
  np->sz = p->sz;
    80001e92:	04893783          	ld	a5,72(s2)
    80001e96:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e9a:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e9e:	05893683          	ld	a3,88(s2)
    80001ea2:	87b6                	mv	a5,a3
    80001ea4:	0589b703          	ld	a4,88(s3)
    80001ea8:	12068693          	addi	a3,a3,288
    80001eac:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001eb0:	6788                	ld	a0,8(a5)
    80001eb2:	6b8c                	ld	a1,16(a5)
    80001eb4:	6f90                	ld	a2,24(a5)
    80001eb6:	01073023          	sd	a6,0(a4)
    80001eba:	e708                	sd	a0,8(a4)
    80001ebc:	eb0c                	sd	a1,16(a4)
    80001ebe:	ef10                	sd	a2,24(a4)
    80001ec0:	02078793          	addi	a5,a5,32
    80001ec4:	02070713          	addi	a4,a4,32
    80001ec8:	fed792e3          	bne	a5,a3,80001eac <fork+0x56>
  np->trapframe->a0 = 0;
    80001ecc:	0589b783          	ld	a5,88(s3)
    80001ed0:	0607b823          	sd	zero,112(a5)
    80001ed4:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ed8:	15000a13          	li	s4,336
    80001edc:	a03d                	j	80001f0a <fork+0xb4>
    freeproc(np);
    80001ede:	854e                	mv	a0,s3
    80001ee0:	00000097          	auipc	ra,0x0
    80001ee4:	d64080e7          	jalr	-668(ra) # 80001c44 <freeproc>
    release(&np->lock);
    80001ee8:	854e                	mv	a0,s3
    80001eea:	fffff097          	auipc	ra,0xfffff
    80001eee:	e2c080e7          	jalr	-468(ra) # 80000d16 <release>
    return -1;
    80001ef2:	54fd                	li	s1,-1
    80001ef4:	a899                	j	80001f4a <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ef6:	00002097          	auipc	ra,0x2
    80001efa:	720080e7          	jalr	1824(ra) # 80004616 <filedup>
    80001efe:	009987b3          	add	a5,s3,s1
    80001f02:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f04:	04a1                	addi	s1,s1,8
    80001f06:	01448763          	beq	s1,s4,80001f14 <fork+0xbe>
    if(p->ofile[i])
    80001f0a:	009907b3          	add	a5,s2,s1
    80001f0e:	6388                	ld	a0,0(a5)
    80001f10:	f17d                	bnez	a0,80001ef6 <fork+0xa0>
    80001f12:	bfcd                	j	80001f04 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001f14:	15093503          	ld	a0,336(s2)
    80001f18:	00002097          	auipc	ra,0x2
    80001f1c:	844080e7          	jalr	-1980(ra) # 8000375c <idup>
    80001f20:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f24:	4641                	li	a2,16
    80001f26:	15890593          	addi	a1,s2,344
    80001f2a:	15898513          	addi	a0,s3,344
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	fa8080e7          	jalr	-88(ra) # 80000ed6 <safestrcpy>
  pid = np->pid;
    80001f36:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f3a:	4789                	li	a5,2
    80001f3c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f40:	854e                	mv	a0,s3
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	dd4080e7          	jalr	-556(ra) # 80000d16 <release>
}
    80001f4a:	8526                	mv	a0,s1
    80001f4c:	70a2                	ld	ra,40(sp)
    80001f4e:	7402                	ld	s0,32(sp)
    80001f50:	64e2                	ld	s1,24(sp)
    80001f52:	6942                	ld	s2,16(sp)
    80001f54:	69a2                	ld	s3,8(sp)
    80001f56:	6a02                	ld	s4,0(sp)
    80001f58:	6145                	addi	sp,sp,48
    80001f5a:	8082                	ret
    return -1;
    80001f5c:	54fd                	li	s1,-1
    80001f5e:	b7f5                	j	80001f4a <fork+0xf4>

0000000080001f60 <reparent>:
{
    80001f60:	7179                	addi	sp,sp,-48
    80001f62:	f406                	sd	ra,40(sp)
    80001f64:	f022                	sd	s0,32(sp)
    80001f66:	ec26                	sd	s1,24(sp)
    80001f68:	e84a                	sd	s2,16(sp)
    80001f6a:	e44e                	sd	s3,8(sp)
    80001f6c:	e052                	sd	s4,0(sp)
    80001f6e:	1800                	addi	s0,sp,48
    80001f70:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f72:	00010497          	auipc	s1,0x10
    80001f76:	df648493          	addi	s1,s1,-522 # 80011d68 <proc>
      pp->parent = initproc;
    80001f7a:	00007a17          	auipc	s4,0x7
    80001f7e:	09ea0a13          	addi	s4,s4,158 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f82:	00015917          	auipc	s2,0x15
    80001f86:	7e690913          	addi	s2,s2,2022 # 80017768 <tickslock>
    80001f8a:	a029                	j	80001f94 <reparent+0x34>
    80001f8c:	16848493          	addi	s1,s1,360
    80001f90:	03248363          	beq	s1,s2,80001fb6 <reparent+0x56>
    if(pp->parent == p){
    80001f94:	709c                	ld	a5,32(s1)
    80001f96:	ff379be3          	bne	a5,s3,80001f8c <reparent+0x2c>
      acquire(&pp->lock);
    80001f9a:	8526                	mv	a0,s1
    80001f9c:	fffff097          	auipc	ra,0xfffff
    80001fa0:	cc6080e7          	jalr	-826(ra) # 80000c62 <acquire>
      pp->parent = initproc;
    80001fa4:	000a3783          	ld	a5,0(s4)
    80001fa8:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	d6a080e7          	jalr	-662(ra) # 80000d16 <release>
    80001fb4:	bfe1                	j	80001f8c <reparent+0x2c>
}
    80001fb6:	70a2                	ld	ra,40(sp)
    80001fb8:	7402                	ld	s0,32(sp)
    80001fba:	64e2                	ld	s1,24(sp)
    80001fbc:	6942                	ld	s2,16(sp)
    80001fbe:	69a2                	ld	s3,8(sp)
    80001fc0:	6a02                	ld	s4,0(sp)
    80001fc2:	6145                	addi	sp,sp,48
    80001fc4:	8082                	ret

0000000080001fc6 <scheduler>:
{
    80001fc6:	711d                	addi	sp,sp,-96
    80001fc8:	ec86                	sd	ra,88(sp)
    80001fca:	e8a2                	sd	s0,80(sp)
    80001fcc:	e4a6                	sd	s1,72(sp)
    80001fce:	e0ca                	sd	s2,64(sp)
    80001fd0:	fc4e                	sd	s3,56(sp)
    80001fd2:	f852                	sd	s4,48(sp)
    80001fd4:	f456                	sd	s5,40(sp)
    80001fd6:	f05a                	sd	s6,32(sp)
    80001fd8:	ec5e                	sd	s7,24(sp)
    80001fda:	e862                	sd	s8,16(sp)
    80001fdc:	e466                	sd	s9,8(sp)
    80001fde:	1080                	addi	s0,sp,96
    80001fe0:	8792                	mv	a5,tp
  int id = r_tp();
    80001fe2:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fe4:	00779c13          	slli	s8,a5,0x7
    80001fe8:	00010717          	auipc	a4,0x10
    80001fec:	96870713          	addi	a4,a4,-1688 # 80011950 <pid_lock>
    80001ff0:	9762                	add	a4,a4,s8
    80001ff2:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001ff6:	00010717          	auipc	a4,0x10
    80001ffa:	97a70713          	addi	a4,a4,-1670 # 80011970 <cpus+0x8>
    80001ffe:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002000:	4a89                	li	s5,2
        c->proc = p;
    80002002:	079e                	slli	a5,a5,0x7
    80002004:	00010b17          	auipc	s6,0x10
    80002008:	94cb0b13          	addi	s6,s6,-1716 # 80011950 <pid_lock>
    8000200c:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    8000200e:	00015a17          	auipc	s4,0x15
    80002012:	75aa0a13          	addi	s4,s4,1882 # 80017768 <tickslock>
    int nproc = 0;
    80002016:	4c81                	li	s9,0
    80002018:	a8a1                	j	80002070 <scheduler+0xaa>
        p->state = RUNNING;
    8000201a:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    8000201e:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80002022:	06048593          	addi	a1,s1,96
    80002026:	8562                	mv	a0,s8
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	640080e7          	jalr	1600(ra) # 80002668 <swtch>
        c->proc = 0;
    80002030:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    80002034:	8526                	mv	a0,s1
    80002036:	fffff097          	auipc	ra,0xfffff
    8000203a:	ce0080e7          	jalr	-800(ra) # 80000d16 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000203e:	16848493          	addi	s1,s1,360
    80002042:	01448d63          	beq	s1,s4,8000205c <scheduler+0x96>
      acquire(&p->lock);
    80002046:	8526                	mv	a0,s1
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	c1a080e7          	jalr	-998(ra) # 80000c62 <acquire>
      if(p->state != UNUSED) {
    80002050:	4c9c                	lw	a5,24(s1)
    80002052:	d3ed                	beqz	a5,80002034 <scheduler+0x6e>
        nproc++;
    80002054:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002056:	fd579fe3          	bne	a5,s5,80002034 <scheduler+0x6e>
    8000205a:	b7c1                	j	8000201a <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    8000205c:	013aca63          	blt	s5,s3,80002070 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002060:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002064:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002068:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000206c:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002070:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002074:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002078:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    8000207c:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    8000207e:	00010497          	auipc	s1,0x10
    80002082:	cea48493          	addi	s1,s1,-790 # 80011d68 <proc>
        p->state = RUNNING;
    80002086:	4b8d                	li	s7,3
    80002088:	bf7d                	j	80002046 <scheduler+0x80>

000000008000208a <sched>:
{
    8000208a:	7179                	addi	sp,sp,-48
    8000208c:	f406                	sd	ra,40(sp)
    8000208e:	f022                	sd	s0,32(sp)
    80002090:	ec26                	sd	s1,24(sp)
    80002092:	e84a                	sd	s2,16(sp)
    80002094:	e44e                	sd	s3,8(sp)
    80002096:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002098:	00000097          	auipc	ra,0x0
    8000209c:	9f8080e7          	jalr	-1544(ra) # 80001a90 <myproc>
    800020a0:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b46080e7          	jalr	-1210(ra) # 80000be8 <holding>
    800020aa:	cd25                	beqz	a0,80002122 <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ac:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020ae:	2781                	sext.w	a5,a5
    800020b0:	079e                	slli	a5,a5,0x7
    800020b2:	00010717          	auipc	a4,0x10
    800020b6:	89e70713          	addi	a4,a4,-1890 # 80011950 <pid_lock>
    800020ba:	97ba                	add	a5,a5,a4
    800020bc:	0907a703          	lw	a4,144(a5)
    800020c0:	4785                	li	a5,1
    800020c2:	06f71863          	bne	a4,a5,80002132 <sched+0xa8>
  if(p->state == RUNNING)
    800020c6:	01892703          	lw	a4,24(s2)
    800020ca:	478d                	li	a5,3
    800020cc:	06f70b63          	beq	a4,a5,80002142 <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020d0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020d4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020d6:	efb5                	bnez	a5,80002152 <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020da:	00010497          	auipc	s1,0x10
    800020de:	87648493          	addi	s1,s1,-1930 # 80011950 <pid_lock>
    800020e2:	2781                	sext.w	a5,a5
    800020e4:	079e                	slli	a5,a5,0x7
    800020e6:	97a6                	add	a5,a5,s1
    800020e8:	0947a983          	lw	s3,148(a5)
    800020ec:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020ee:	2781                	sext.w	a5,a5
    800020f0:	079e                	slli	a5,a5,0x7
    800020f2:	00010597          	auipc	a1,0x10
    800020f6:	87e58593          	addi	a1,a1,-1922 # 80011970 <cpus+0x8>
    800020fa:	95be                	add	a1,a1,a5
    800020fc:	06090513          	addi	a0,s2,96
    80002100:	00000097          	auipc	ra,0x0
    80002104:	568080e7          	jalr	1384(ra) # 80002668 <swtch>
    80002108:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000210a:	2781                	sext.w	a5,a5
    8000210c:	079e                	slli	a5,a5,0x7
    8000210e:	97a6                	add	a5,a5,s1
    80002110:	0937aa23          	sw	s3,148(a5)
}
    80002114:	70a2                	ld	ra,40(sp)
    80002116:	7402                	ld	s0,32(sp)
    80002118:	64e2                	ld	s1,24(sp)
    8000211a:	6942                	ld	s2,16(sp)
    8000211c:	69a2                	ld	s3,8(sp)
    8000211e:	6145                	addi	sp,sp,48
    80002120:	8082                	ret
    panic("sched p->lock");
    80002122:	00006517          	auipc	a0,0x6
    80002126:	09e50513          	addi	a0,a0,158 # 800081c0 <states.1722+0x60>
    8000212a:	ffffe097          	auipc	ra,0xffffe
    8000212e:	44a080e7          	jalr	1098(ra) # 80000574 <panic>
    panic("sched locks");
    80002132:	00006517          	auipc	a0,0x6
    80002136:	09e50513          	addi	a0,a0,158 # 800081d0 <states.1722+0x70>
    8000213a:	ffffe097          	auipc	ra,0xffffe
    8000213e:	43a080e7          	jalr	1082(ra) # 80000574 <panic>
    panic("sched running");
    80002142:	00006517          	auipc	a0,0x6
    80002146:	09e50513          	addi	a0,a0,158 # 800081e0 <states.1722+0x80>
    8000214a:	ffffe097          	auipc	ra,0xffffe
    8000214e:	42a080e7          	jalr	1066(ra) # 80000574 <panic>
    panic("sched interruptible");
    80002152:	00006517          	auipc	a0,0x6
    80002156:	09e50513          	addi	a0,a0,158 # 800081f0 <states.1722+0x90>
    8000215a:	ffffe097          	auipc	ra,0xffffe
    8000215e:	41a080e7          	jalr	1050(ra) # 80000574 <panic>

0000000080002162 <exit>:
{
    80002162:	7179                	addi	sp,sp,-48
    80002164:	f406                	sd	ra,40(sp)
    80002166:	f022                	sd	s0,32(sp)
    80002168:	ec26                	sd	s1,24(sp)
    8000216a:	e84a                	sd	s2,16(sp)
    8000216c:	e44e                	sd	s3,8(sp)
    8000216e:	e052                	sd	s4,0(sp)
    80002170:	1800                	addi	s0,sp,48
    80002172:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002174:	00000097          	auipc	ra,0x0
    80002178:	91c080e7          	jalr	-1764(ra) # 80001a90 <myproc>
    8000217c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000217e:	00007797          	auipc	a5,0x7
    80002182:	e9a78793          	addi	a5,a5,-358 # 80009018 <initproc>
    80002186:	639c                	ld	a5,0(a5)
    80002188:	0d050493          	addi	s1,a0,208
    8000218c:	15050913          	addi	s2,a0,336
    80002190:	02a79363          	bne	a5,a0,800021b6 <exit+0x54>
    panic("init exiting");
    80002194:	00006517          	auipc	a0,0x6
    80002198:	07450513          	addi	a0,a0,116 # 80008208 <states.1722+0xa8>
    8000219c:	ffffe097          	auipc	ra,0xffffe
    800021a0:	3d8080e7          	jalr	984(ra) # 80000574 <panic>
      fileclose(f);
    800021a4:	00002097          	auipc	ra,0x2
    800021a8:	4c4080e7          	jalr	1220(ra) # 80004668 <fileclose>
      p->ofile[fd] = 0;
    800021ac:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021b0:	04a1                	addi	s1,s1,8
    800021b2:	01248563          	beq	s1,s2,800021bc <exit+0x5a>
    if(p->ofile[fd]){
    800021b6:	6088                	ld	a0,0(s1)
    800021b8:	f575                	bnez	a0,800021a4 <exit+0x42>
    800021ba:	bfdd                	j	800021b0 <exit+0x4e>
  begin_op();
    800021bc:	00002097          	auipc	ra,0x2
    800021c0:	faa080e7          	jalr	-86(ra) # 80004166 <begin_op>
  iput(p->cwd);
    800021c4:	1509b503          	ld	a0,336(s3)
    800021c8:	00001097          	auipc	ra,0x1
    800021cc:	78e080e7          	jalr	1934(ra) # 80003956 <iput>
  end_op();
    800021d0:	00002097          	auipc	ra,0x2
    800021d4:	016080e7          	jalr	22(ra) # 800041e6 <end_op>
  p->cwd = 0;
    800021d8:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800021dc:	00007497          	auipc	s1,0x7
    800021e0:	e3c48493          	addi	s1,s1,-452 # 80009018 <initproc>
    800021e4:	6088                	ld	a0,0(s1)
    800021e6:	fffff097          	auipc	ra,0xfffff
    800021ea:	a7c080e7          	jalr	-1412(ra) # 80000c62 <acquire>
  wakeup1(initproc);
    800021ee:	6088                	ld	a0,0(s1)
    800021f0:	fffff097          	auipc	ra,0xfffff
    800021f4:	760080e7          	jalr	1888(ra) # 80001950 <wakeup1>
  release(&initproc->lock);
    800021f8:	6088                	ld	a0,0(s1)
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	b1c080e7          	jalr	-1252(ra) # 80000d16 <release>
  acquire(&p->lock);
    80002202:	854e                	mv	a0,s3
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	a5e080e7          	jalr	-1442(ra) # 80000c62 <acquire>
  struct proc *original_parent = p->parent;
    8000220c:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002210:	854e                	mv	a0,s3
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	b04080e7          	jalr	-1276(ra) # 80000d16 <release>
  acquire(&original_parent->lock);
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	a46080e7          	jalr	-1466(ra) # 80000c62 <acquire>
  acquire(&p->lock);
    80002224:	854e                	mv	a0,s3
    80002226:	fffff097          	auipc	ra,0xfffff
    8000222a:	a3c080e7          	jalr	-1476(ra) # 80000c62 <acquire>
  reparent(p);
    8000222e:	854e                	mv	a0,s3
    80002230:	00000097          	auipc	ra,0x0
    80002234:	d30080e7          	jalr	-720(ra) # 80001f60 <reparent>
  wakeup1(original_parent);
    80002238:	8526                	mv	a0,s1
    8000223a:	fffff097          	auipc	ra,0xfffff
    8000223e:	716080e7          	jalr	1814(ra) # 80001950 <wakeup1>
  p->xstate = status;
    80002242:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002246:	4791                	li	a5,4
    80002248:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	ac8080e7          	jalr	-1336(ra) # 80000d16 <release>
  sched();
    80002256:	00000097          	auipc	ra,0x0
    8000225a:	e34080e7          	jalr	-460(ra) # 8000208a <sched>
  panic("zombie exit");
    8000225e:	00006517          	auipc	a0,0x6
    80002262:	fba50513          	addi	a0,a0,-70 # 80008218 <states.1722+0xb8>
    80002266:	ffffe097          	auipc	ra,0xffffe
    8000226a:	30e080e7          	jalr	782(ra) # 80000574 <panic>

000000008000226e <yield>:
{
    8000226e:	1101                	addi	sp,sp,-32
    80002270:	ec06                	sd	ra,24(sp)
    80002272:	e822                	sd	s0,16(sp)
    80002274:	e426                	sd	s1,8(sp)
    80002276:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002278:	00000097          	auipc	ra,0x0
    8000227c:	818080e7          	jalr	-2024(ra) # 80001a90 <myproc>
    80002280:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002282:	fffff097          	auipc	ra,0xfffff
    80002286:	9e0080e7          	jalr	-1568(ra) # 80000c62 <acquire>
  p->state = RUNNABLE;
    8000228a:	4789                	li	a5,2
    8000228c:	cc9c                	sw	a5,24(s1)
  sched();
    8000228e:	00000097          	auipc	ra,0x0
    80002292:	dfc080e7          	jalr	-516(ra) # 8000208a <sched>
  release(&p->lock);
    80002296:	8526                	mv	a0,s1
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	a7e080e7          	jalr	-1410(ra) # 80000d16 <release>
}
    800022a0:	60e2                	ld	ra,24(sp)
    800022a2:	6442                	ld	s0,16(sp)
    800022a4:	64a2                	ld	s1,8(sp)
    800022a6:	6105                	addi	sp,sp,32
    800022a8:	8082                	ret

00000000800022aa <sleep>:
{
    800022aa:	7179                	addi	sp,sp,-48
    800022ac:	f406                	sd	ra,40(sp)
    800022ae:	f022                	sd	s0,32(sp)
    800022b0:	ec26                	sd	s1,24(sp)
    800022b2:	e84a                	sd	s2,16(sp)
    800022b4:	e44e                	sd	s3,8(sp)
    800022b6:	1800                	addi	s0,sp,48
    800022b8:	89aa                	mv	s3,a0
    800022ba:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	7d4080e7          	jalr	2004(ra) # 80001a90 <myproc>
    800022c4:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022c6:	05250663          	beq	a0,s2,80002312 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	998080e7          	jalr	-1640(ra) # 80000c62 <acquire>
    release(lk);
    800022d2:	854a                	mv	a0,s2
    800022d4:	fffff097          	auipc	ra,0xfffff
    800022d8:	a42080e7          	jalr	-1470(ra) # 80000d16 <release>
  p->chan = chan;
    800022dc:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022e0:	4785                	li	a5,1
    800022e2:	cc9c                	sw	a5,24(s1)
  sched();
    800022e4:	00000097          	auipc	ra,0x0
    800022e8:	da6080e7          	jalr	-602(ra) # 8000208a <sched>
  p->chan = 0;
    800022ec:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022f0:	8526                	mv	a0,s1
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	a24080e7          	jalr	-1500(ra) # 80000d16 <release>
    acquire(lk);
    800022fa:	854a                	mv	a0,s2
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	966080e7          	jalr	-1690(ra) # 80000c62 <acquire>
}
    80002304:	70a2                	ld	ra,40(sp)
    80002306:	7402                	ld	s0,32(sp)
    80002308:	64e2                	ld	s1,24(sp)
    8000230a:	6942                	ld	s2,16(sp)
    8000230c:	69a2                	ld	s3,8(sp)
    8000230e:	6145                	addi	sp,sp,48
    80002310:	8082                	ret
  p->chan = chan;
    80002312:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002316:	4785                	li	a5,1
    80002318:	cd1c                	sw	a5,24(a0)
  sched();
    8000231a:	00000097          	auipc	ra,0x0
    8000231e:	d70080e7          	jalr	-656(ra) # 8000208a <sched>
  p->chan = 0;
    80002322:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002326:	bff9                	j	80002304 <sleep+0x5a>

0000000080002328 <wait>:
{
    80002328:	715d                	addi	sp,sp,-80
    8000232a:	e486                	sd	ra,72(sp)
    8000232c:	e0a2                	sd	s0,64(sp)
    8000232e:	fc26                	sd	s1,56(sp)
    80002330:	f84a                	sd	s2,48(sp)
    80002332:	f44e                	sd	s3,40(sp)
    80002334:	f052                	sd	s4,32(sp)
    80002336:	ec56                	sd	s5,24(sp)
    80002338:	e85a                	sd	s6,16(sp)
    8000233a:	e45e                	sd	s7,8(sp)
    8000233c:	e062                	sd	s8,0(sp)
    8000233e:	0880                	addi	s0,sp,80
    80002340:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	74e080e7          	jalr	1870(ra) # 80001a90 <myproc>
    8000234a:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000234c:	8c2a                	mv	s8,a0
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	914080e7          	jalr	-1772(ra) # 80000c62 <acquire>
    havekids = 0;
    80002356:	4b01                	li	s6,0
        if(np->state == ZOMBIE){
    80002358:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000235a:	00015997          	auipc	s3,0x15
    8000235e:	40e98993          	addi	s3,s3,1038 # 80017768 <tickslock>
        havekids = 1;
    80002362:	4a85                	li	s5,1
    havekids = 0;
    80002364:	875a                	mv	a4,s6
    for(np = proc; np < &proc[NPROC]; np++){
    80002366:	00010497          	auipc	s1,0x10
    8000236a:	a0248493          	addi	s1,s1,-1534 # 80011d68 <proc>
    8000236e:	a08d                	j	800023d0 <wait+0xa8>
          pid = np->pid;
    80002370:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002374:	000b8e63          	beqz	s7,80002390 <wait+0x68>
    80002378:	4691                	li	a3,4
    8000237a:	03448613          	addi	a2,s1,52
    8000237e:	85de                	mv	a1,s7
    80002380:	05093503          	ld	a0,80(s2)
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	3e8080e7          	jalr	1000(ra) # 8000176c <copyout>
    8000238c:	02054263          	bltz	a0,800023b0 <wait+0x88>
          freeproc(np);
    80002390:	8526                	mv	a0,s1
    80002392:	00000097          	auipc	ra,0x0
    80002396:	8b2080e7          	jalr	-1870(ra) # 80001c44 <freeproc>
          release(&np->lock);
    8000239a:	8526                	mv	a0,s1
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	97a080e7          	jalr	-1670(ra) # 80000d16 <release>
          release(&p->lock);
    800023a4:	854a                	mv	a0,s2
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	970080e7          	jalr	-1680(ra) # 80000d16 <release>
          return pid;
    800023ae:	a8a9                	j	80002408 <wait+0xe0>
            release(&np->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	964080e7          	jalr	-1692(ra) # 80000d16 <release>
            release(&p->lock);
    800023ba:	854a                	mv	a0,s2
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	95a080e7          	jalr	-1702(ra) # 80000d16 <release>
            return -1;
    800023c4:	59fd                	li	s3,-1
    800023c6:	a089                	j	80002408 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023c8:	16848493          	addi	s1,s1,360
    800023cc:	03348463          	beq	s1,s3,800023f4 <wait+0xcc>
      if(np->parent == p){
    800023d0:	709c                	ld	a5,32(s1)
    800023d2:	ff279be3          	bne	a5,s2,800023c8 <wait+0xa0>
        acquire(&np->lock);
    800023d6:	8526                	mv	a0,s1
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	88a080e7          	jalr	-1910(ra) # 80000c62 <acquire>
        if(np->state == ZOMBIE){
    800023e0:	4c9c                	lw	a5,24(s1)
    800023e2:	f94787e3          	beq	a5,s4,80002370 <wait+0x48>
        release(&np->lock);
    800023e6:	8526                	mv	a0,s1
    800023e8:	fffff097          	auipc	ra,0xfffff
    800023ec:	92e080e7          	jalr	-1746(ra) # 80000d16 <release>
        havekids = 1;
    800023f0:	8756                	mv	a4,s5
    800023f2:	bfd9                	j	800023c8 <wait+0xa0>
    if(!havekids || p->killed){
    800023f4:	c701                	beqz	a4,800023fc <wait+0xd4>
    800023f6:	03092783          	lw	a5,48(s2)
    800023fa:	c785                	beqz	a5,80002422 <wait+0xfa>
      release(&p->lock);
    800023fc:	854a                	mv	a0,s2
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	918080e7          	jalr	-1768(ra) # 80000d16 <release>
      return -1;
    80002406:	59fd                	li	s3,-1
}
    80002408:	854e                	mv	a0,s3
    8000240a:	60a6                	ld	ra,72(sp)
    8000240c:	6406                	ld	s0,64(sp)
    8000240e:	74e2                	ld	s1,56(sp)
    80002410:	7942                	ld	s2,48(sp)
    80002412:	79a2                	ld	s3,40(sp)
    80002414:	7a02                	ld	s4,32(sp)
    80002416:	6ae2                	ld	s5,24(sp)
    80002418:	6b42                	ld	s6,16(sp)
    8000241a:	6ba2                	ld	s7,8(sp)
    8000241c:	6c02                	ld	s8,0(sp)
    8000241e:	6161                	addi	sp,sp,80
    80002420:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002422:	85e2                	mv	a1,s8
    80002424:	854a                	mv	a0,s2
    80002426:	00000097          	auipc	ra,0x0
    8000242a:	e84080e7          	jalr	-380(ra) # 800022aa <sleep>
    havekids = 0;
    8000242e:	bf1d                	j	80002364 <wait+0x3c>

0000000080002430 <wakeup>:
{
    80002430:	7139                	addi	sp,sp,-64
    80002432:	fc06                	sd	ra,56(sp)
    80002434:	f822                	sd	s0,48(sp)
    80002436:	f426                	sd	s1,40(sp)
    80002438:	f04a                	sd	s2,32(sp)
    8000243a:	ec4e                	sd	s3,24(sp)
    8000243c:	e852                	sd	s4,16(sp)
    8000243e:	e456                	sd	s5,8(sp)
    80002440:	0080                	addi	s0,sp,64
    80002442:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002444:	00010497          	auipc	s1,0x10
    80002448:	92448493          	addi	s1,s1,-1756 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000244c:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000244e:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002450:	00015917          	auipc	s2,0x15
    80002454:	31890913          	addi	s2,s2,792 # 80017768 <tickslock>
    80002458:	a821                	j	80002470 <wakeup+0x40>
      p->state = RUNNABLE;
    8000245a:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	8b6080e7          	jalr	-1866(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002468:	16848493          	addi	s1,s1,360
    8000246c:	01248e63          	beq	s1,s2,80002488 <wakeup+0x58>
    acquire(&p->lock);
    80002470:	8526                	mv	a0,s1
    80002472:	ffffe097          	auipc	ra,0xffffe
    80002476:	7f0080e7          	jalr	2032(ra) # 80000c62 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000247a:	4c9c                	lw	a5,24(s1)
    8000247c:	ff3791e3          	bne	a5,s3,8000245e <wakeup+0x2e>
    80002480:	749c                	ld	a5,40(s1)
    80002482:	fd479ee3          	bne	a5,s4,8000245e <wakeup+0x2e>
    80002486:	bfd1                	j	8000245a <wakeup+0x2a>
}
    80002488:	70e2                	ld	ra,56(sp)
    8000248a:	7442                	ld	s0,48(sp)
    8000248c:	74a2                	ld	s1,40(sp)
    8000248e:	7902                	ld	s2,32(sp)
    80002490:	69e2                	ld	s3,24(sp)
    80002492:	6a42                	ld	s4,16(sp)
    80002494:	6aa2                	ld	s5,8(sp)
    80002496:	6121                	addi	sp,sp,64
    80002498:	8082                	ret

000000008000249a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000249a:	7179                	addi	sp,sp,-48
    8000249c:	f406                	sd	ra,40(sp)
    8000249e:	f022                	sd	s0,32(sp)
    800024a0:	ec26                	sd	s1,24(sp)
    800024a2:	e84a                	sd	s2,16(sp)
    800024a4:	e44e                	sd	s3,8(sp)
    800024a6:	1800                	addi	s0,sp,48
    800024a8:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024aa:	00010497          	auipc	s1,0x10
    800024ae:	8be48493          	addi	s1,s1,-1858 # 80011d68 <proc>
    800024b2:	00015997          	auipc	s3,0x15
    800024b6:	2b698993          	addi	s3,s3,694 # 80017768 <tickslock>
    acquire(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7a6080e7          	jalr	1958(ra) # 80000c62 <acquire>
    if(p->pid == pid){
    800024c4:	5c9c                	lw	a5,56(s1)
    800024c6:	01278d63          	beq	a5,s2,800024e0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024ca:	8526                	mv	a0,s1
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	84a080e7          	jalr	-1974(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024d4:	16848493          	addi	s1,s1,360
    800024d8:	ff3491e3          	bne	s1,s3,800024ba <kill+0x20>
  }
  return -1;
    800024dc:	557d                	li	a0,-1
    800024de:	a829                	j	800024f8 <kill+0x5e>
      p->killed = 1;
    800024e0:	4785                	li	a5,1
    800024e2:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024e4:	4c98                	lw	a4,24(s1)
    800024e6:	4785                	li	a5,1
    800024e8:	00f70f63          	beq	a4,a5,80002506 <kill+0x6c>
      release(&p->lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	828080e7          	jalr	-2008(ra) # 80000d16 <release>
      return 0;
    800024f6:	4501                	li	a0,0
}
    800024f8:	70a2                	ld	ra,40(sp)
    800024fa:	7402                	ld	s0,32(sp)
    800024fc:	64e2                	ld	s1,24(sp)
    800024fe:	6942                	ld	s2,16(sp)
    80002500:	69a2                	ld	s3,8(sp)
    80002502:	6145                	addi	sp,sp,48
    80002504:	8082                	ret
        p->state = RUNNABLE;
    80002506:	4789                	li	a5,2
    80002508:	cc9c                	sw	a5,24(s1)
    8000250a:	b7cd                	j	800024ec <kill+0x52>

000000008000250c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000250c:	7179                	addi	sp,sp,-48
    8000250e:	f406                	sd	ra,40(sp)
    80002510:	f022                	sd	s0,32(sp)
    80002512:	ec26                	sd	s1,24(sp)
    80002514:	e84a                	sd	s2,16(sp)
    80002516:	e44e                	sd	s3,8(sp)
    80002518:	e052                	sd	s4,0(sp)
    8000251a:	1800                	addi	s0,sp,48
    8000251c:	84aa                	mv	s1,a0
    8000251e:	892e                	mv	s2,a1
    80002520:	89b2                	mv	s3,a2
    80002522:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002524:	fffff097          	auipc	ra,0xfffff
    80002528:	56c080e7          	jalr	1388(ra) # 80001a90 <myproc>
  if(user_dst){
    8000252c:	c08d                	beqz	s1,8000254e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000252e:	86d2                	mv	a3,s4
    80002530:	864e                	mv	a2,s3
    80002532:	85ca                	mv	a1,s2
    80002534:	6928                	ld	a0,80(a0)
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	236080e7          	jalr	566(ra) # 8000176c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000253e:	70a2                	ld	ra,40(sp)
    80002540:	7402                	ld	s0,32(sp)
    80002542:	64e2                	ld	s1,24(sp)
    80002544:	6942                	ld	s2,16(sp)
    80002546:	69a2                	ld	s3,8(sp)
    80002548:	6a02                	ld	s4,0(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
    memmove((char *)dst, src, len);
    8000254e:	000a061b          	sext.w	a2,s4
    80002552:	85ce                	mv	a1,s3
    80002554:	854a                	mv	a0,s2
    80002556:	fffff097          	auipc	ra,0xfffff
    8000255a:	874080e7          	jalr	-1932(ra) # 80000dca <memmove>
    return 0;
    8000255e:	8526                	mv	a0,s1
    80002560:	bff9                	j	8000253e <either_copyout+0x32>

0000000080002562 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002562:	7179                	addi	sp,sp,-48
    80002564:	f406                	sd	ra,40(sp)
    80002566:	f022                	sd	s0,32(sp)
    80002568:	ec26                	sd	s1,24(sp)
    8000256a:	e84a                	sd	s2,16(sp)
    8000256c:	e44e                	sd	s3,8(sp)
    8000256e:	e052                	sd	s4,0(sp)
    80002570:	1800                	addi	s0,sp,48
    80002572:	892a                	mv	s2,a0
    80002574:	84ae                	mv	s1,a1
    80002576:	89b2                	mv	s3,a2
    80002578:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	516080e7          	jalr	1302(ra) # 80001a90 <myproc>
  if(user_src){
    80002582:	c08d                	beqz	s1,800025a4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002584:	86d2                	mv	a3,s4
    80002586:	864e                	mv	a2,s3
    80002588:	85ca                	mv	a1,s2
    8000258a:	6928                	ld	a0,80(a0)
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	26c080e7          	jalr	620(ra) # 800017f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002594:	70a2                	ld	ra,40(sp)
    80002596:	7402                	ld	s0,32(sp)
    80002598:	64e2                	ld	s1,24(sp)
    8000259a:	6942                	ld	s2,16(sp)
    8000259c:	69a2                	ld	s3,8(sp)
    8000259e:	6a02                	ld	s4,0(sp)
    800025a0:	6145                	addi	sp,sp,48
    800025a2:	8082                	ret
    memmove(dst, (char*)src, len);
    800025a4:	000a061b          	sext.w	a2,s4
    800025a8:	85ce                	mv	a1,s3
    800025aa:	854a                	mv	a0,s2
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	81e080e7          	jalr	-2018(ra) # 80000dca <memmove>
    return 0;
    800025b4:	8526                	mv	a0,s1
    800025b6:	bff9                	j	80002594 <either_copyin+0x32>

00000000800025b8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025b8:	715d                	addi	sp,sp,-80
    800025ba:	e486                	sd	ra,72(sp)
    800025bc:	e0a2                	sd	s0,64(sp)
    800025be:	fc26                	sd	s1,56(sp)
    800025c0:	f84a                	sd	s2,48(sp)
    800025c2:	f44e                	sd	s3,40(sp)
    800025c4:	f052                	sd	s4,32(sp)
    800025c6:	ec56                	sd	s5,24(sp)
    800025c8:	e85a                	sd	s6,16(sp)
    800025ca:	e45e                	sd	s7,8(sp)
    800025cc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ce:	00006517          	auipc	a0,0x6
    800025d2:	afa50513          	addi	a0,a0,-1286 # 800080c8 <digits+0xb0>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	fe8080e7          	jalr	-24(ra) # 800005be <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025de:	00010497          	auipc	s1,0x10
    800025e2:	8e248493          	addi	s1,s1,-1822 # 80011ec0 <proc+0x158>
    800025e6:	00015917          	auipc	s2,0x15
    800025ea:	2da90913          	addi	s2,s2,730 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025f0:	00006997          	auipc	s3,0x6
    800025f4:	c3898993          	addi	s3,s3,-968 # 80008228 <states.1722+0xc8>
    printf("%d %s %s", p->pid, state, p->name);
    800025f8:	00006a97          	auipc	s5,0x6
    800025fc:	c38a8a93          	addi	s5,s5,-968 # 80008230 <states.1722+0xd0>
    printf("\n");
    80002600:	00006a17          	auipc	s4,0x6
    80002604:	ac8a0a13          	addi	s4,s4,-1336 # 800080c8 <digits+0xb0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002608:	00006b97          	auipc	s7,0x6
    8000260c:	b58b8b93          	addi	s7,s7,-1192 # 80008160 <states.1722>
    80002610:	a015                	j	80002634 <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    80002612:	86ba                	mv	a3,a4
    80002614:	ee072583          	lw	a1,-288(a4)
    80002618:	8556                	mv	a0,s5
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	fa4080e7          	jalr	-92(ra) # 800005be <printf>
    printf("\n");
    80002622:	8552                	mv	a0,s4
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	f9a080e7          	jalr	-102(ra) # 800005be <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000262c:	16848493          	addi	s1,s1,360
    80002630:	03248163          	beq	s1,s2,80002652 <procdump+0x9a>
    if(p->state == UNUSED)
    80002634:	8726                	mv	a4,s1
    80002636:	ec04a783          	lw	a5,-320(s1)
    8000263a:	dbed                	beqz	a5,8000262c <procdump+0x74>
      state = "???";
    8000263c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000263e:	fcfb6ae3          	bltu	s6,a5,80002612 <procdump+0x5a>
    80002642:	1782                	slli	a5,a5,0x20
    80002644:	9381                	srli	a5,a5,0x20
    80002646:	078e                	slli	a5,a5,0x3
    80002648:	97de                	add	a5,a5,s7
    8000264a:	6390                	ld	a2,0(a5)
    8000264c:	f279                	bnez	a2,80002612 <procdump+0x5a>
      state = "???";
    8000264e:	864e                	mv	a2,s3
    80002650:	b7c9                	j	80002612 <procdump+0x5a>
  }
}
    80002652:	60a6                	ld	ra,72(sp)
    80002654:	6406                	ld	s0,64(sp)
    80002656:	74e2                	ld	s1,56(sp)
    80002658:	7942                	ld	s2,48(sp)
    8000265a:	79a2                	ld	s3,40(sp)
    8000265c:	7a02                	ld	s4,32(sp)
    8000265e:	6ae2                	ld	s5,24(sp)
    80002660:	6b42                	ld	s6,16(sp)
    80002662:	6ba2                	ld	s7,8(sp)
    80002664:	6161                	addi	sp,sp,80
    80002666:	8082                	ret

0000000080002668 <swtch>:
    80002668:	00153023          	sd	ra,0(a0)
    8000266c:	00253423          	sd	sp,8(a0)
    80002670:	e900                	sd	s0,16(a0)
    80002672:	ed04                	sd	s1,24(a0)
    80002674:	03253023          	sd	s2,32(a0)
    80002678:	03353423          	sd	s3,40(a0)
    8000267c:	03453823          	sd	s4,48(a0)
    80002680:	03553c23          	sd	s5,56(a0)
    80002684:	05653023          	sd	s6,64(a0)
    80002688:	05753423          	sd	s7,72(a0)
    8000268c:	05853823          	sd	s8,80(a0)
    80002690:	05953c23          	sd	s9,88(a0)
    80002694:	07a53023          	sd	s10,96(a0)
    80002698:	07b53423          	sd	s11,104(a0)
    8000269c:	0005b083          	ld	ra,0(a1)
    800026a0:	0085b103          	ld	sp,8(a1)
    800026a4:	6980                	ld	s0,16(a1)
    800026a6:	6d84                	ld	s1,24(a1)
    800026a8:	0205b903          	ld	s2,32(a1)
    800026ac:	0285b983          	ld	s3,40(a1)
    800026b0:	0305ba03          	ld	s4,48(a1)
    800026b4:	0385ba83          	ld	s5,56(a1)
    800026b8:	0405bb03          	ld	s6,64(a1)
    800026bc:	0485bb83          	ld	s7,72(a1)
    800026c0:	0505bc03          	ld	s8,80(a1)
    800026c4:	0585bc83          	ld	s9,88(a1)
    800026c8:	0605bd03          	ld	s10,96(a1)
    800026cc:	0685bd83          	ld	s11,104(a1)
    800026d0:	8082                	ret

00000000800026d2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026d2:	1141                	addi	sp,sp,-16
    800026d4:	e406                	sd	ra,8(sp)
    800026d6:	e022                	sd	s0,0(sp)
    800026d8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026da:	00006597          	auipc	a1,0x6
    800026de:	b8e58593          	addi	a1,a1,-1138 # 80008268 <states.1722+0x108>
    800026e2:	00015517          	auipc	a0,0x15
    800026e6:	08650513          	addi	a0,a0,134 # 80017768 <tickslock>
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	4e8080e7          	jalr	1256(ra) # 80000bd2 <initlock>
}
    800026f2:	60a2                	ld	ra,8(sp)
    800026f4:	6402                	ld	s0,0(sp)
    800026f6:	0141                	addi	sp,sp,16
    800026f8:	8082                	ret

00000000800026fa <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026fa:	1141                	addi	sp,sp,-16
    800026fc:	e422                	sd	s0,8(sp)
    800026fe:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002700:	00003797          	auipc	a5,0x3
    80002704:	62078793          	addi	a5,a5,1568 # 80005d20 <kernelvec>
    80002708:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000270c:	6422                	ld	s0,8(sp)
    8000270e:	0141                	addi	sp,sp,16
    80002710:	8082                	ret

0000000080002712 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002712:	1141                	addi	sp,sp,-16
    80002714:	e406                	sd	ra,8(sp)
    80002716:	e022                	sd	s0,0(sp)
    80002718:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000271a:	fffff097          	auipc	ra,0xfffff
    8000271e:	376080e7          	jalr	886(ra) # 80001a90 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002722:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002726:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002728:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000272c:	00005617          	auipc	a2,0x5
    80002730:	8d460613          	addi	a2,a2,-1836 # 80007000 <_trampoline>
    80002734:	00005697          	auipc	a3,0x5
    80002738:	8cc68693          	addi	a3,a3,-1844 # 80007000 <_trampoline>
    8000273c:	8e91                	sub	a3,a3,a2
    8000273e:	040007b7          	lui	a5,0x4000
    80002742:	17fd                	addi	a5,a5,-1
    80002744:	07b2                	slli	a5,a5,0xc
    80002746:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002748:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000274c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000274e:	180026f3          	csrr	a3,satp
    80002752:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002754:	6d38                	ld	a4,88(a0)
    80002756:	6134                	ld	a3,64(a0)
    80002758:	6585                	lui	a1,0x1
    8000275a:	96ae                	add	a3,a3,a1
    8000275c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000275e:	6d38                	ld	a4,88(a0)
    80002760:	00000697          	auipc	a3,0x0
    80002764:	13868693          	addi	a3,a3,312 # 80002898 <usertrap>
    80002768:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000276a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000276c:	8692                	mv	a3,tp
    8000276e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002770:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002774:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002778:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002780:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002782:	6f18                	ld	a4,24(a4)
    80002784:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002788:	692c                	ld	a1,80(a0)
    8000278a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000278c:	00005717          	auipc	a4,0x5
    80002790:	90470713          	addi	a4,a4,-1788 # 80007090 <userret>
    80002794:	8f11                	sub	a4,a4,a2
    80002796:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002798:	577d                	li	a4,-1
    8000279a:	177e                	slli	a4,a4,0x3f
    8000279c:	8dd9                	or	a1,a1,a4
    8000279e:	02000537          	lui	a0,0x2000
    800027a2:	157d                	addi	a0,a0,-1
    800027a4:	0536                	slli	a0,a0,0xd
    800027a6:	9782                	jalr	a5
}
    800027a8:	60a2                	ld	ra,8(sp)
    800027aa:	6402                	ld	s0,0(sp)
    800027ac:	0141                	addi	sp,sp,16
    800027ae:	8082                	ret

00000000800027b0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027b0:	1101                	addi	sp,sp,-32
    800027b2:	ec06                	sd	ra,24(sp)
    800027b4:	e822                	sd	s0,16(sp)
    800027b6:	e426                	sd	s1,8(sp)
    800027b8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027ba:	00015497          	auipc	s1,0x15
    800027be:	fae48493          	addi	s1,s1,-82 # 80017768 <tickslock>
    800027c2:	8526                	mv	a0,s1
    800027c4:	ffffe097          	auipc	ra,0xffffe
    800027c8:	49e080e7          	jalr	1182(ra) # 80000c62 <acquire>
  ticks++;
    800027cc:	00007517          	auipc	a0,0x7
    800027d0:	85450513          	addi	a0,a0,-1964 # 80009020 <ticks>
    800027d4:	411c                	lw	a5,0(a0)
    800027d6:	2785                	addiw	a5,a5,1
    800027d8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027da:	00000097          	auipc	ra,0x0
    800027de:	c56080e7          	jalr	-938(ra) # 80002430 <wakeup>
  release(&tickslock);
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	532080e7          	jalr	1330(ra) # 80000d16 <release>
}
    800027ec:	60e2                	ld	ra,24(sp)
    800027ee:	6442                	ld	s0,16(sp)
    800027f0:	64a2                	ld	s1,8(sp)
    800027f2:	6105                	addi	sp,sp,32
    800027f4:	8082                	ret

00000000800027f6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027f6:	1101                	addi	sp,sp,-32
    800027f8:	ec06                	sd	ra,24(sp)
    800027fa:	e822                	sd	s0,16(sp)
    800027fc:	e426                	sd	s1,8(sp)
    800027fe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002800:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002804:	00074d63          	bltz	a4,8000281e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002808:	57fd                	li	a5,-1
    8000280a:	17fe                	slli	a5,a5,0x3f
    8000280c:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000280e:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002810:	06f70363          	beq	a4,a5,80002876 <devintr+0x80>
  }
}
    80002814:	60e2                	ld	ra,24(sp)
    80002816:	6442                	ld	s0,16(sp)
    80002818:	64a2                	ld	s1,8(sp)
    8000281a:	6105                	addi	sp,sp,32
    8000281c:	8082                	ret
     (scause & 0xff) == 9){
    8000281e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002822:	46a5                	li	a3,9
    80002824:	fed792e3          	bne	a5,a3,80002808 <devintr+0x12>
    int irq = plic_claim();
    80002828:	00003097          	auipc	ra,0x3
    8000282c:	600080e7          	jalr	1536(ra) # 80005e28 <plic_claim>
    80002830:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002832:	47a9                	li	a5,10
    80002834:	02f50763          	beq	a0,a5,80002862 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002838:	4785                	li	a5,1
    8000283a:	02f50963          	beq	a0,a5,8000286c <devintr+0x76>
    return 1;
    8000283e:	4505                	li	a0,1
    } else if(irq){
    80002840:	d8f1                	beqz	s1,80002814 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002842:	85a6                	mv	a1,s1
    80002844:	00006517          	auipc	a0,0x6
    80002848:	a2c50513          	addi	a0,a0,-1492 # 80008270 <states.1722+0x110>
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	d72080e7          	jalr	-654(ra) # 800005be <printf>
      plic_complete(irq);
    80002854:	8526                	mv	a0,s1
    80002856:	00003097          	auipc	ra,0x3
    8000285a:	5f6080e7          	jalr	1526(ra) # 80005e4c <plic_complete>
    return 1;
    8000285e:	4505                	li	a0,1
    80002860:	bf55                	j	80002814 <devintr+0x1e>
      uartintr();
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	1c0080e7          	jalr	448(ra) # 80000a22 <uartintr>
    8000286a:	b7ed                	j	80002854 <devintr+0x5e>
      virtio_disk_intr();
    8000286c:	00004097          	auipc	ra,0x4
    80002870:	a8c080e7          	jalr	-1396(ra) # 800062f8 <virtio_disk_intr>
    80002874:	b7c5                	j	80002854 <devintr+0x5e>
    if(cpuid() == 0){
    80002876:	fffff097          	auipc	ra,0xfffff
    8000287a:	1ee080e7          	jalr	494(ra) # 80001a64 <cpuid>
    8000287e:	c901                	beqz	a0,8000288e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002880:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002884:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002886:	14479073          	csrw	sip,a5
    return 2;
    8000288a:	4509                	li	a0,2
    8000288c:	b761                	j	80002814 <devintr+0x1e>
      clockintr();
    8000288e:	00000097          	auipc	ra,0x0
    80002892:	f22080e7          	jalr	-222(ra) # 800027b0 <clockintr>
    80002896:	b7ed                	j	80002880 <devintr+0x8a>

0000000080002898 <usertrap>:
{
    80002898:	1101                	addi	sp,sp,-32
    8000289a:	ec06                	sd	ra,24(sp)
    8000289c:	e822                	sd	s0,16(sp)
    8000289e:	e426                	sd	s1,8(sp)
    800028a0:	e04a                	sd	s2,0(sp)
    800028a2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a4:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028a8:	1007f793          	andi	a5,a5,256
    800028ac:	e3ad                	bnez	a5,8000290e <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028ae:	00003797          	auipc	a5,0x3
    800028b2:	47278793          	addi	a5,a5,1138 # 80005d20 <kernelvec>
    800028b6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028ba:	fffff097          	auipc	ra,0xfffff
    800028be:	1d6080e7          	jalr	470(ra) # 80001a90 <myproc>
    800028c2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028c4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c6:	14102773          	csrr	a4,sepc
    800028ca:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028cc:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028d0:	47a1                	li	a5,8
    800028d2:	04f71c63          	bne	a4,a5,8000292a <usertrap+0x92>
    if(p->killed)
    800028d6:	591c                	lw	a5,48(a0)
    800028d8:	e3b9                	bnez	a5,8000291e <usertrap+0x86>
    p->trapframe->epc += 4;
    800028da:	6cb8                	ld	a4,88(s1)
    800028dc:	6f1c                	ld	a5,24(a4)
    800028de:	0791                	addi	a5,a5,4
    800028e0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028e6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ea:	10079073          	csrw	sstatus,a5
    syscall();
    800028ee:	00000097          	auipc	ra,0x0
    800028f2:	33e080e7          	jalr	830(ra) # 80002c2c <syscall>
  if(p->killed)
    800028f6:	589c                	lw	a5,48(s1)
    800028f8:	e7e5                	bnez	a5,800029e0 <usertrap+0x148>
  usertrapret();
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	e18080e7          	jalr	-488(ra) # 80002712 <usertrapret>
}
    80002902:	60e2                	ld	ra,24(sp)
    80002904:	6442                	ld	s0,16(sp)
    80002906:	64a2                	ld	s1,8(sp)
    80002908:	6902                	ld	s2,0(sp)
    8000290a:	6105                	addi	sp,sp,32
    8000290c:	8082                	ret
    panic("usertrap: not from user mode");
    8000290e:	00006517          	auipc	a0,0x6
    80002912:	98250513          	addi	a0,a0,-1662 # 80008290 <states.1722+0x130>
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	c5e080e7          	jalr	-930(ra) # 80000574 <panic>
      exit(-1);
    8000291e:	557d                	li	a0,-1
    80002920:	00000097          	auipc	ra,0x0
    80002924:	842080e7          	jalr	-1982(ra) # 80002162 <exit>
    80002928:	bf4d                	j	800028da <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    8000292a:	00000097          	auipc	ra,0x0
    8000292e:	ecc080e7          	jalr	-308(ra) # 800027f6 <devintr>
    80002932:	892a                	mv	s2,a0
    80002934:	e15d                	bnez	a0,800029da <usertrap+0x142>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002936:	14202773          	csrr	a4,scause
  } else if (r_scause() == 15 || r_scause() == 13) {
    8000293a:	47bd                	li	a5,15
    8000293c:	00f70763          	beq	a4,a5,8000294a <usertrap+0xb2>
    80002940:	14202773          	csrr	a4,scause
    80002944:	47b5                	li	a5,13
    80002946:	06f71063          	bne	a4,a5,800029a6 <usertrap+0x10e>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000294a:	143027f3          	csrr	a5,stval
    if (va > p->sz || va < PGROUNDUP(p->trapframe->sp) || va >= MAXVA) { // pagefault的地址大于sbrk的最大值
    8000294e:	64b8                	ld	a4,72(s1)
    80002950:	00f76f63          	bltu	a4,a5,8000296e <usertrap+0xd6>
    80002954:	6cb8                	ld	a4,88(s1)
    80002956:	7b18                	ld	a4,48(a4)
    80002958:	6685                	lui	a3,0x1
    8000295a:	16fd                	addi	a3,a3,-1
    8000295c:	9736                	add	a4,a4,a3
    8000295e:	76fd                	lui	a3,0xfffff
    80002960:	8f75                	and	a4,a4,a3
    80002962:	00e7e663          	bltu	a5,a4,8000296e <usertrap+0xd6>
    80002966:	577d                	li	a4,-1
    80002968:	8369                	srli	a4,a4,0x1a
    8000296a:	02f77163          	bleu	a5,a4,8000298c <usertrap+0xf4>
      p->killed = 1;
    8000296e:	4785                	li	a5,1
    80002970:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002972:	557d                	li	a0,-1
    80002974:	fffff097          	auipc	ra,0xfffff
    80002978:	7ee080e7          	jalr	2030(ra) # 80002162 <exit>
  if(which_dev == 2)
    8000297c:	4789                	li	a5,2
    8000297e:	f6f91ee3          	bne	s2,a5,800028fa <usertrap+0x62>
    yield();
    80002982:	00000097          	auipc	ra,0x0
    80002986:	8ec080e7          	jalr	-1812(ra) # 8000226e <yield>
    8000298a:	bf85                	j	800028fa <usertrap+0x62>
      if (uvmalloc(p->pagetable, PGROUNDDOWN(va), PGSIZE + PGROUNDDOWN(va)) == 0) {
    8000298c:	75fd                	lui	a1,0xfffff
    8000298e:	8dfd                	and	a1,a1,a5
    80002990:	6605                	lui	a2,0x1
    80002992:	962e                	add	a2,a2,a1
    80002994:	68a8                	ld	a0,80(s1)
    80002996:	fffff097          	auipc	ra,0xfffff
    8000299a:	b04080e7          	jalr	-1276(ra) # 8000149a <uvmalloc>
    8000299e:	fd21                	bnez	a0,800028f6 <usertrap+0x5e>
        p->killed = 1;
    800029a0:	4785                	li	a5,1
    800029a2:	d89c                	sw	a5,48(s1)
    800029a4:	b7f9                	j	80002972 <usertrap+0xda>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029aa:	5c90                	lw	a2,56(s1)
    800029ac:	00006517          	auipc	a0,0x6
    800029b0:	90450513          	addi	a0,a0,-1788 # 800082b0 <states.1722+0x150>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	c0a080e7          	jalr	-1014(ra) # 800005be <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029bc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029c0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029c4:	00006517          	auipc	a0,0x6
    800029c8:	91c50513          	addi	a0,a0,-1764 # 800082e0 <states.1722+0x180>
    800029cc:	ffffe097          	auipc	ra,0xffffe
    800029d0:	bf2080e7          	jalr	-1038(ra) # 800005be <printf>
    p->killed = 1;
    800029d4:	4785                	li	a5,1
    800029d6:	d89c                	sw	a5,48(s1)
    800029d8:	bf69                	j	80002972 <usertrap+0xda>
  if(p->killed)
    800029da:	589c                	lw	a5,48(s1)
    800029dc:	d3c5                	beqz	a5,8000297c <usertrap+0xe4>
    800029de:	bf51                	j	80002972 <usertrap+0xda>
    800029e0:	4901                	li	s2,0
    800029e2:	bf41                	j	80002972 <usertrap+0xda>

00000000800029e4 <kerneltrap>:
{
    800029e4:	7179                	addi	sp,sp,-48
    800029e6:	f406                	sd	ra,40(sp)
    800029e8:	f022                	sd	s0,32(sp)
    800029ea:	ec26                	sd	s1,24(sp)
    800029ec:	e84a                	sd	s2,16(sp)
    800029ee:	e44e                	sd	s3,8(sp)
    800029f0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029fa:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029fe:	1004f793          	andi	a5,s1,256
    80002a02:	cb85                	beqz	a5,80002a32 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a04:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a08:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a0a:	ef85                	bnez	a5,80002a42 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a0c:	00000097          	auipc	ra,0x0
    80002a10:	dea080e7          	jalr	-534(ra) # 800027f6 <devintr>
    80002a14:	cd1d                	beqz	a0,80002a52 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a16:	4789                	li	a5,2
    80002a18:	06f50a63          	beq	a0,a5,80002a8c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a1c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a20:	10049073          	csrw	sstatus,s1
}
    80002a24:	70a2                	ld	ra,40(sp)
    80002a26:	7402                	ld	s0,32(sp)
    80002a28:	64e2                	ld	s1,24(sp)
    80002a2a:	6942                	ld	s2,16(sp)
    80002a2c:	69a2                	ld	s3,8(sp)
    80002a2e:	6145                	addi	sp,sp,48
    80002a30:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a32:	00006517          	auipc	a0,0x6
    80002a36:	8ce50513          	addi	a0,a0,-1842 # 80008300 <states.1722+0x1a0>
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	b3a080e7          	jalr	-1222(ra) # 80000574 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a42:	00006517          	auipc	a0,0x6
    80002a46:	8e650513          	addi	a0,a0,-1818 # 80008328 <states.1722+0x1c8>
    80002a4a:	ffffe097          	auipc	ra,0xffffe
    80002a4e:	b2a080e7          	jalr	-1238(ra) # 80000574 <panic>
    printf("scause %p\n", scause);
    80002a52:	85ce                	mv	a1,s3
    80002a54:	00006517          	auipc	a0,0x6
    80002a58:	8f450513          	addi	a0,a0,-1804 # 80008348 <states.1722+0x1e8>
    80002a5c:	ffffe097          	auipc	ra,0xffffe
    80002a60:	b62080e7          	jalr	-1182(ra) # 800005be <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a64:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a68:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a6c:	00006517          	auipc	a0,0x6
    80002a70:	8ec50513          	addi	a0,a0,-1812 # 80008358 <states.1722+0x1f8>
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	b4a080e7          	jalr	-1206(ra) # 800005be <printf>
    panic("kerneltrap");
    80002a7c:	00006517          	auipc	a0,0x6
    80002a80:	8f450513          	addi	a0,a0,-1804 # 80008370 <states.1722+0x210>
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	af0080e7          	jalr	-1296(ra) # 80000574 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	004080e7          	jalr	4(ra) # 80001a90 <myproc>
    80002a94:	d541                	beqz	a0,80002a1c <kerneltrap+0x38>
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	ffa080e7          	jalr	-6(ra) # 80001a90 <myproc>
    80002a9e:	4d18                	lw	a4,24(a0)
    80002aa0:	478d                	li	a5,3
    80002aa2:	f6f71de3          	bne	a4,a5,80002a1c <kerneltrap+0x38>
    yield();
    80002aa6:	fffff097          	auipc	ra,0xfffff
    80002aaa:	7c8080e7          	jalr	1992(ra) # 8000226e <yield>
    80002aae:	b7bd                	j	80002a1c <kerneltrap+0x38>

0000000080002ab0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ab0:	1101                	addi	sp,sp,-32
    80002ab2:	ec06                	sd	ra,24(sp)
    80002ab4:	e822                	sd	s0,16(sp)
    80002ab6:	e426                	sd	s1,8(sp)
    80002ab8:	1000                	addi	s0,sp,32
    80002aba:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	fd4080e7          	jalr	-44(ra) # 80001a90 <myproc>
  switch (n) {
    80002ac4:	4795                	li	a5,5
    80002ac6:	0497e363          	bltu	a5,s1,80002b0c <argraw+0x5c>
    80002aca:	1482                	slli	s1,s1,0x20
    80002acc:	9081                	srli	s1,s1,0x20
    80002ace:	048a                	slli	s1,s1,0x2
    80002ad0:	00006717          	auipc	a4,0x6
    80002ad4:	8b070713          	addi	a4,a4,-1872 # 80008380 <states.1722+0x220>
    80002ad8:	94ba                	add	s1,s1,a4
    80002ada:	409c                	lw	a5,0(s1)
    80002adc:	97ba                	add	a5,a5,a4
    80002ade:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ae0:	6d3c                	ld	a5,88(a0)
    80002ae2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6105                	addi	sp,sp,32
    80002aec:	8082                	ret
    return p->trapframe->a1;
    80002aee:	6d3c                	ld	a5,88(a0)
    80002af0:	7fa8                	ld	a0,120(a5)
    80002af2:	bfcd                	j	80002ae4 <argraw+0x34>
    return p->trapframe->a2;
    80002af4:	6d3c                	ld	a5,88(a0)
    80002af6:	63c8                	ld	a0,128(a5)
    80002af8:	b7f5                	j	80002ae4 <argraw+0x34>
    return p->trapframe->a3;
    80002afa:	6d3c                	ld	a5,88(a0)
    80002afc:	67c8                	ld	a0,136(a5)
    80002afe:	b7dd                	j	80002ae4 <argraw+0x34>
    return p->trapframe->a4;
    80002b00:	6d3c                	ld	a5,88(a0)
    80002b02:	6bc8                	ld	a0,144(a5)
    80002b04:	b7c5                	j	80002ae4 <argraw+0x34>
    return p->trapframe->a5;
    80002b06:	6d3c                	ld	a5,88(a0)
    80002b08:	6fc8                	ld	a0,152(a5)
    80002b0a:	bfe9                	j	80002ae4 <argraw+0x34>
  panic("argraw");
    80002b0c:	00006517          	auipc	a0,0x6
    80002b10:	93c50513          	addi	a0,a0,-1732 # 80008448 <syscalls+0xb0>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	a60080e7          	jalr	-1440(ra) # 80000574 <panic>

0000000080002b1c <fetchaddr>:
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	e04a                	sd	s2,0(sp)
    80002b26:	1000                	addi	s0,sp,32
    80002b28:	84aa                	mv	s1,a0
    80002b2a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	f64080e7          	jalr	-156(ra) # 80001a90 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b34:	653c                	ld	a5,72(a0)
    80002b36:	02f4f963          	bleu	a5,s1,80002b68 <fetchaddr+0x4c>
    80002b3a:	00848713          	addi	a4,s1,8
    80002b3e:	02e7e763          	bltu	a5,a4,80002b6c <fetchaddr+0x50>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b42:	46a1                	li	a3,8
    80002b44:	8626                	mv	a2,s1
    80002b46:	85ca                	mv	a1,s2
    80002b48:	6928                	ld	a0,80(a0)
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	cae080e7          	jalr	-850(ra) # 800017f8 <copyin>
    80002b52:	00a03533          	snez	a0,a0
    80002b56:	40a0053b          	negw	a0,a0
    80002b5a:	2501                	sext.w	a0,a0
}
    80002b5c:	60e2                	ld	ra,24(sp)
    80002b5e:	6442                	ld	s0,16(sp)
    80002b60:	64a2                	ld	s1,8(sp)
    80002b62:	6902                	ld	s2,0(sp)
    80002b64:	6105                	addi	sp,sp,32
    80002b66:	8082                	ret
    return -1;
    80002b68:	557d                	li	a0,-1
    80002b6a:	bfcd                	j	80002b5c <fetchaddr+0x40>
    80002b6c:	557d                	li	a0,-1
    80002b6e:	b7fd                	j	80002b5c <fetchaddr+0x40>

0000000080002b70 <fetchstr>:
{
    80002b70:	7179                	addi	sp,sp,-48
    80002b72:	f406                	sd	ra,40(sp)
    80002b74:	f022                	sd	s0,32(sp)
    80002b76:	ec26                	sd	s1,24(sp)
    80002b78:	e84a                	sd	s2,16(sp)
    80002b7a:	e44e                	sd	s3,8(sp)
    80002b7c:	1800                	addi	s0,sp,48
    80002b7e:	892a                	mv	s2,a0
    80002b80:	84ae                	mv	s1,a1
    80002b82:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b84:	fffff097          	auipc	ra,0xfffff
    80002b88:	f0c080e7          	jalr	-244(ra) # 80001a90 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b8c:	86ce                	mv	a3,s3
    80002b8e:	864a                	mv	a2,s2
    80002b90:	85a6                	mv	a1,s1
    80002b92:	6928                	ld	a0,80(a0)
    80002b94:	fffff097          	auipc	ra,0xfffff
    80002b98:	cf2080e7          	jalr	-782(ra) # 80001886 <copyinstr>
  if(err < 0)
    80002b9c:	00054763          	bltz	a0,80002baa <fetchstr+0x3a>
  return strlen(buf);
    80002ba0:	8526                	mv	a0,s1
    80002ba2:	ffffe097          	auipc	ra,0xffffe
    80002ba6:	366080e7          	jalr	870(ra) # 80000f08 <strlen>
}
    80002baa:	70a2                	ld	ra,40(sp)
    80002bac:	7402                	ld	s0,32(sp)
    80002bae:	64e2                	ld	s1,24(sp)
    80002bb0:	6942                	ld	s2,16(sp)
    80002bb2:	69a2                	ld	s3,8(sp)
    80002bb4:	6145                	addi	sp,sp,48
    80002bb6:	8082                	ret

0000000080002bb8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002bb8:	1101                	addi	sp,sp,-32
    80002bba:	ec06                	sd	ra,24(sp)
    80002bbc:	e822                	sd	s0,16(sp)
    80002bbe:	e426                	sd	s1,8(sp)
    80002bc0:	1000                	addi	s0,sp,32
    80002bc2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bc4:	00000097          	auipc	ra,0x0
    80002bc8:	eec080e7          	jalr	-276(ra) # 80002ab0 <argraw>
    80002bcc:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bce:	4501                	li	a0,0
    80002bd0:	60e2                	ld	ra,24(sp)
    80002bd2:	6442                	ld	s0,16(sp)
    80002bd4:	64a2                	ld	s1,8(sp)
    80002bd6:	6105                	addi	sp,sp,32
    80002bd8:	8082                	ret

0000000080002bda <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bda:	1101                	addi	sp,sp,-32
    80002bdc:	ec06                	sd	ra,24(sp)
    80002bde:	e822                	sd	s0,16(sp)
    80002be0:	e426                	sd	s1,8(sp)
    80002be2:	1000                	addi	s0,sp,32
    80002be4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	eca080e7          	jalr	-310(ra) # 80002ab0 <argraw>
    80002bee:	e088                	sd	a0,0(s1)
  return 0;
}
    80002bf0:	4501                	li	a0,0
    80002bf2:	60e2                	ld	ra,24(sp)
    80002bf4:	6442                	ld	s0,16(sp)
    80002bf6:	64a2                	ld	s1,8(sp)
    80002bf8:	6105                	addi	sp,sp,32
    80002bfa:	8082                	ret

0000000080002bfc <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bfc:	1101                	addi	sp,sp,-32
    80002bfe:	ec06                	sd	ra,24(sp)
    80002c00:	e822                	sd	s0,16(sp)
    80002c02:	e426                	sd	s1,8(sp)
    80002c04:	e04a                	sd	s2,0(sp)
    80002c06:	1000                	addi	s0,sp,32
    80002c08:	84ae                	mv	s1,a1
    80002c0a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002c0c:	00000097          	auipc	ra,0x0
    80002c10:	ea4080e7          	jalr	-348(ra) # 80002ab0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c14:	864a                	mv	a2,s2
    80002c16:	85a6                	mv	a1,s1
    80002c18:	00000097          	auipc	ra,0x0
    80002c1c:	f58080e7          	jalr	-168(ra) # 80002b70 <fetchstr>
}
    80002c20:	60e2                	ld	ra,24(sp)
    80002c22:	6442                	ld	s0,16(sp)
    80002c24:	64a2                	ld	s1,8(sp)
    80002c26:	6902                	ld	s2,0(sp)
    80002c28:	6105                	addi	sp,sp,32
    80002c2a:	8082                	ret

0000000080002c2c <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002c2c:	1101                	addi	sp,sp,-32
    80002c2e:	ec06                	sd	ra,24(sp)
    80002c30:	e822                	sd	s0,16(sp)
    80002c32:	e426                	sd	s1,8(sp)
    80002c34:	e04a                	sd	s2,0(sp)
    80002c36:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c38:	fffff097          	auipc	ra,0xfffff
    80002c3c:	e58080e7          	jalr	-424(ra) # 80001a90 <myproc>
    80002c40:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c42:	05853903          	ld	s2,88(a0)
    80002c46:	0a893783          	ld	a5,168(s2)
    80002c4a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c4e:	37fd                	addiw	a5,a5,-1
    80002c50:	4751                	li	a4,20
    80002c52:	00f76f63          	bltu	a4,a5,80002c70 <syscall+0x44>
    80002c56:	00369713          	slli	a4,a3,0x3
    80002c5a:	00005797          	auipc	a5,0x5
    80002c5e:	73e78793          	addi	a5,a5,1854 # 80008398 <syscalls>
    80002c62:	97ba                	add	a5,a5,a4
    80002c64:	639c                	ld	a5,0(a5)
    80002c66:	c789                	beqz	a5,80002c70 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c68:	9782                	jalr	a5
    80002c6a:	06a93823          	sd	a0,112(s2)
    80002c6e:	a839                	j	80002c8c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c70:	15848613          	addi	a2,s1,344
    80002c74:	5c8c                	lw	a1,56(s1)
    80002c76:	00005517          	auipc	a0,0x5
    80002c7a:	7da50513          	addi	a0,a0,2010 # 80008450 <syscalls+0xb8>
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	940080e7          	jalr	-1728(ra) # 800005be <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c86:	6cbc                	ld	a5,88(s1)
    80002c88:	577d                	li	a4,-1
    80002c8a:	fbb8                	sd	a4,112(a5)
  }
}
    80002c8c:	60e2                	ld	ra,24(sp)
    80002c8e:	6442                	ld	s0,16(sp)
    80002c90:	64a2                	ld	s1,8(sp)
    80002c92:	6902                	ld	s2,0(sp)
    80002c94:	6105                	addi	sp,sp,32
    80002c96:	8082                	ret

0000000080002c98 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c98:	1101                	addi	sp,sp,-32
    80002c9a:	ec06                	sd	ra,24(sp)
    80002c9c:	e822                	sd	s0,16(sp)
    80002c9e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002ca0:	fec40593          	addi	a1,s0,-20
    80002ca4:	4501                	li	a0,0
    80002ca6:	00000097          	auipc	ra,0x0
    80002caa:	f12080e7          	jalr	-238(ra) # 80002bb8 <argint>
    return -1;
    80002cae:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002cb0:	00054963          	bltz	a0,80002cc2 <sys_exit+0x2a>
  exit(n);
    80002cb4:	fec42503          	lw	a0,-20(s0)
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	4aa080e7          	jalr	1194(ra) # 80002162 <exit>
  return 0;  // not reached
    80002cc0:	4781                	li	a5,0
}
    80002cc2:	853e                	mv	a0,a5
    80002cc4:	60e2                	ld	ra,24(sp)
    80002cc6:	6442                	ld	s0,16(sp)
    80002cc8:	6105                	addi	sp,sp,32
    80002cca:	8082                	ret

0000000080002ccc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ccc:	1141                	addi	sp,sp,-16
    80002cce:	e406                	sd	ra,8(sp)
    80002cd0:	e022                	sd	s0,0(sp)
    80002cd2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cd4:	fffff097          	auipc	ra,0xfffff
    80002cd8:	dbc080e7          	jalr	-580(ra) # 80001a90 <myproc>
}
    80002cdc:	5d08                	lw	a0,56(a0)
    80002cde:	60a2                	ld	ra,8(sp)
    80002ce0:	6402                	ld	s0,0(sp)
    80002ce2:	0141                	addi	sp,sp,16
    80002ce4:	8082                	ret

0000000080002ce6 <sys_fork>:

uint64
sys_fork(void)
{
    80002ce6:	1141                	addi	sp,sp,-16
    80002ce8:	e406                	sd	ra,8(sp)
    80002cea:	e022                	sd	s0,0(sp)
    80002cec:	0800                	addi	s0,sp,16
  return fork();
    80002cee:	fffff097          	auipc	ra,0xfffff
    80002cf2:	168080e7          	jalr	360(ra) # 80001e56 <fork>
}
    80002cf6:	60a2                	ld	ra,8(sp)
    80002cf8:	6402                	ld	s0,0(sp)
    80002cfa:	0141                	addi	sp,sp,16
    80002cfc:	8082                	ret

0000000080002cfe <sys_wait>:

uint64
sys_wait(void)
{
    80002cfe:	1101                	addi	sp,sp,-32
    80002d00:	ec06                	sd	ra,24(sp)
    80002d02:	e822                	sd	s0,16(sp)
    80002d04:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d06:	fe840593          	addi	a1,s0,-24
    80002d0a:	4501                	li	a0,0
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	ece080e7          	jalr	-306(ra) # 80002bda <argaddr>
    return -1;
    80002d14:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80002d16:	00054963          	bltz	a0,80002d28 <sys_wait+0x2a>
  return wait(p);
    80002d1a:	fe843503          	ld	a0,-24(s0)
    80002d1e:	fffff097          	auipc	ra,0xfffff
    80002d22:	60a080e7          	jalr	1546(ra) # 80002328 <wait>
    80002d26:	87aa                	mv	a5,a0
}
    80002d28:	853e                	mv	a0,a5
    80002d2a:	60e2                	ld	ra,24(sp)
    80002d2c:	6442                	ld	s0,16(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d32:	7179                	addi	sp,sp,-48
    80002d34:	f406                	sd	ra,40(sp)
    80002d36:	f022                	sd	s0,32(sp)
    80002d38:	ec26                	sd	s1,24(sp)
    80002d3a:	e84a                	sd	s2,16(sp)
    80002d3c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  if(argint(0, &n) < 0)
    80002d3e:	fdc40593          	addi	a1,s0,-36
    80002d42:	4501                	li	a0,0
    80002d44:	00000097          	auipc	ra,0x0
    80002d48:	e74080e7          	jalr	-396(ra) # 80002bb8 <argint>
    return -1;
    80002d4c:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002d4e:	02054963          	bltz	a0,80002d80 <sys_sbrk+0x4e>
  struct proc* p = myproc();
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	d3e080e7          	jalr	-706(ra) # 80001a90 <myproc>
    80002d5a:	892a                	mv	s2,a0
  addr = p->sz;
    80002d5c:	6524                	ld	s1,72(a0)
  if (p->sz + n >= MAXVA || p->sz + n < 0) {
    80002d5e:	fdc42703          	lw	a4,-36(s0)
    80002d62:	00970633          	add	a2,a4,s1
    80002d66:	57fd                	li	a5,-1
    80002d68:	83e9                	srli	a5,a5,0x1a
    80002d6a:	00c7eb63          	bltu	a5,a2,80002d80 <sys_sbrk+0x4e>
    return addr;
  }

  if (n < 0) {
    80002d6e:	02074063          	bltz	a4,80002d8e <sys_sbrk+0x5c>
    uvmdealloc(p->pagetable, addr, addr + n);
  }
  p->sz = p->sz + n;
    80002d72:	fdc42703          	lw	a4,-36(s0)
    80002d76:	04893783          	ld	a5,72(s2)
    80002d7a:	97ba                	add	a5,a5,a4
    80002d7c:	04f93423          	sd	a5,72(s2)
  return addr;
}
    80002d80:	8526                	mv	a0,s1
    80002d82:	70a2                	ld	ra,40(sp)
    80002d84:	7402                	ld	s0,32(sp)
    80002d86:	64e2                	ld	s1,24(sp)
    80002d88:	6942                	ld	s2,16(sp)
    80002d8a:	6145                	addi	sp,sp,48
    80002d8c:	8082                	ret
    uvmdealloc(p->pagetable, addr, addr + n);
    80002d8e:	85a6                	mv	a1,s1
    80002d90:	6928                	ld	a0,80(a0)
    80002d92:	ffffe097          	auipc	ra,0xffffe
    80002d96:	6c2080e7          	jalr	1730(ra) # 80001454 <uvmdealloc>
    80002d9a:	bfe1                	j	80002d72 <sys_sbrk+0x40>

0000000080002d9c <sys_sleep>:



uint64
sys_sleep(void)
{
    80002d9c:	7139                	addi	sp,sp,-64
    80002d9e:	fc06                	sd	ra,56(sp)
    80002da0:	f822                	sd	s0,48(sp)
    80002da2:	f426                	sd	s1,40(sp)
    80002da4:	f04a                	sd	s2,32(sp)
    80002da6:	ec4e                	sd	s3,24(sp)
    80002da8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002daa:	fcc40593          	addi	a1,s0,-52
    80002dae:	4501                	li	a0,0
    80002db0:	00000097          	auipc	ra,0x0
    80002db4:	e08080e7          	jalr	-504(ra) # 80002bb8 <argint>
    return -1;
    80002db8:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002dba:	06054763          	bltz	a0,80002e28 <sys_sleep+0x8c>
  acquire(&tickslock);
    80002dbe:	00015517          	auipc	a0,0x15
    80002dc2:	9aa50513          	addi	a0,a0,-1622 # 80017768 <tickslock>
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	e9c080e7          	jalr	-356(ra) # 80000c62 <acquire>
  ticks0 = ticks;
    80002dce:	00006797          	auipc	a5,0x6
    80002dd2:	25278793          	addi	a5,a5,594 # 80009020 <ticks>
    80002dd6:	0007a903          	lw	s2,0(a5)
  while(ticks - ticks0 < n){
    80002dda:	fcc42783          	lw	a5,-52(s0)
    80002dde:	cf85                	beqz	a5,80002e16 <sys_sleep+0x7a>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002de0:	00015997          	auipc	s3,0x15
    80002de4:	98898993          	addi	s3,s3,-1656 # 80017768 <tickslock>
    80002de8:	00006497          	auipc	s1,0x6
    80002dec:	23848493          	addi	s1,s1,568 # 80009020 <ticks>
    if(myproc()->killed){
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	ca0080e7          	jalr	-864(ra) # 80001a90 <myproc>
    80002df8:	591c                	lw	a5,48(a0)
    80002dfa:	ef9d                	bnez	a5,80002e38 <sys_sleep+0x9c>
    sleep(&ticks, &tickslock);
    80002dfc:	85ce                	mv	a1,s3
    80002dfe:	8526                	mv	a0,s1
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	4aa080e7          	jalr	1194(ra) # 800022aa <sleep>
  while(ticks - ticks0 < n){
    80002e08:	409c                	lw	a5,0(s1)
    80002e0a:	412787bb          	subw	a5,a5,s2
    80002e0e:	fcc42703          	lw	a4,-52(s0)
    80002e12:	fce7efe3          	bltu	a5,a4,80002df0 <sys_sleep+0x54>
  }
  release(&tickslock);
    80002e16:	00015517          	auipc	a0,0x15
    80002e1a:	95250513          	addi	a0,a0,-1710 # 80017768 <tickslock>
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	ef8080e7          	jalr	-264(ra) # 80000d16 <release>
  return 0;
    80002e26:	4781                	li	a5,0
}
    80002e28:	853e                	mv	a0,a5
    80002e2a:	70e2                	ld	ra,56(sp)
    80002e2c:	7442                	ld	s0,48(sp)
    80002e2e:	74a2                	ld	s1,40(sp)
    80002e30:	7902                	ld	s2,32(sp)
    80002e32:	69e2                	ld	s3,24(sp)
    80002e34:	6121                	addi	sp,sp,64
    80002e36:	8082                	ret
      release(&tickslock);
    80002e38:	00015517          	auipc	a0,0x15
    80002e3c:	93050513          	addi	a0,a0,-1744 # 80017768 <tickslock>
    80002e40:	ffffe097          	auipc	ra,0xffffe
    80002e44:	ed6080e7          	jalr	-298(ra) # 80000d16 <release>
      return -1;
    80002e48:	57fd                	li	a5,-1
    80002e4a:	bff9                	j	80002e28 <sys_sleep+0x8c>

0000000080002e4c <sys_kill>:

uint64
sys_kill(void)
{
    80002e4c:	1101                	addi	sp,sp,-32
    80002e4e:	ec06                	sd	ra,24(sp)
    80002e50:	e822                	sd	s0,16(sp)
    80002e52:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e54:	fec40593          	addi	a1,s0,-20
    80002e58:	4501                	li	a0,0
    80002e5a:	00000097          	auipc	ra,0x0
    80002e5e:	d5e080e7          	jalr	-674(ra) # 80002bb8 <argint>
    return -1;
    80002e62:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80002e64:	00054963          	bltz	a0,80002e76 <sys_kill+0x2a>
  return kill(pid);
    80002e68:	fec42503          	lw	a0,-20(s0)
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	62e080e7          	jalr	1582(ra) # 8000249a <kill>
    80002e74:	87aa                	mv	a5,a0
}
    80002e76:	853e                	mv	a0,a5
    80002e78:	60e2                	ld	ra,24(sp)
    80002e7a:	6442                	ld	s0,16(sp)
    80002e7c:	6105                	addi	sp,sp,32
    80002e7e:	8082                	ret

0000000080002e80 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e80:	1101                	addi	sp,sp,-32
    80002e82:	ec06                	sd	ra,24(sp)
    80002e84:	e822                	sd	s0,16(sp)
    80002e86:	e426                	sd	s1,8(sp)
    80002e88:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e8a:	00015517          	auipc	a0,0x15
    80002e8e:	8de50513          	addi	a0,a0,-1826 # 80017768 <tickslock>
    80002e92:	ffffe097          	auipc	ra,0xffffe
    80002e96:	dd0080e7          	jalr	-560(ra) # 80000c62 <acquire>
  xticks = ticks;
    80002e9a:	00006797          	auipc	a5,0x6
    80002e9e:	18678793          	addi	a5,a5,390 # 80009020 <ticks>
    80002ea2:	4384                	lw	s1,0(a5)
  release(&tickslock);
    80002ea4:	00015517          	auipc	a0,0x15
    80002ea8:	8c450513          	addi	a0,a0,-1852 # 80017768 <tickslock>
    80002eac:	ffffe097          	auipc	ra,0xffffe
    80002eb0:	e6a080e7          	jalr	-406(ra) # 80000d16 <release>
  return xticks;
}
    80002eb4:	02049513          	slli	a0,s1,0x20
    80002eb8:	9101                	srli	a0,a0,0x20
    80002eba:	60e2                	ld	ra,24(sp)
    80002ebc:	6442                	ld	s0,16(sp)
    80002ebe:	64a2                	ld	s1,8(sp)
    80002ec0:	6105                	addi	sp,sp,32
    80002ec2:	8082                	ret

0000000080002ec4 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ec4:	7179                	addi	sp,sp,-48
    80002ec6:	f406                	sd	ra,40(sp)
    80002ec8:	f022                	sd	s0,32(sp)
    80002eca:	ec26                	sd	s1,24(sp)
    80002ecc:	e84a                	sd	s2,16(sp)
    80002ece:	e44e                	sd	s3,8(sp)
    80002ed0:	e052                	sd	s4,0(sp)
    80002ed2:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ed4:	00005597          	auipc	a1,0x5
    80002ed8:	59c58593          	addi	a1,a1,1436 # 80008470 <syscalls+0xd8>
    80002edc:	00015517          	auipc	a0,0x15
    80002ee0:	8a450513          	addi	a0,a0,-1884 # 80017780 <bcache>
    80002ee4:	ffffe097          	auipc	ra,0xffffe
    80002ee8:	cee080e7          	jalr	-786(ra) # 80000bd2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eec:	0001d797          	auipc	a5,0x1d
    80002ef0:	89478793          	addi	a5,a5,-1900 # 8001f780 <bcache+0x8000>
    80002ef4:	0001d717          	auipc	a4,0x1d
    80002ef8:	af470713          	addi	a4,a4,-1292 # 8001f9e8 <bcache+0x8268>
    80002efc:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f00:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f04:	00015497          	auipc	s1,0x15
    80002f08:	89448493          	addi	s1,s1,-1900 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002f0c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f0e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f10:	00005a17          	auipc	s4,0x5
    80002f14:	568a0a13          	addi	s4,s4,1384 # 80008478 <syscalls+0xe0>
    b->next = bcache.head.next;
    80002f18:	2b893783          	ld	a5,696(s2)
    80002f1c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f1e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f22:	85d2                	mv	a1,s4
    80002f24:	01048513          	addi	a0,s1,16
    80002f28:	00001097          	auipc	ra,0x1
    80002f2c:	51e080e7          	jalr	1310(ra) # 80004446 <initsleeplock>
    bcache.head.next->prev = b;
    80002f30:	2b893783          	ld	a5,696(s2)
    80002f34:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f36:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f3a:	45848493          	addi	s1,s1,1112
    80002f3e:	fd349de3          	bne	s1,s3,80002f18 <binit+0x54>
  }
}
    80002f42:	70a2                	ld	ra,40(sp)
    80002f44:	7402                	ld	s0,32(sp)
    80002f46:	64e2                	ld	s1,24(sp)
    80002f48:	6942                	ld	s2,16(sp)
    80002f4a:	69a2                	ld	s3,8(sp)
    80002f4c:	6a02                	ld	s4,0(sp)
    80002f4e:	6145                	addi	sp,sp,48
    80002f50:	8082                	ret

0000000080002f52 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f52:	7179                	addi	sp,sp,-48
    80002f54:	f406                	sd	ra,40(sp)
    80002f56:	f022                	sd	s0,32(sp)
    80002f58:	ec26                	sd	s1,24(sp)
    80002f5a:	e84a                	sd	s2,16(sp)
    80002f5c:	e44e                	sd	s3,8(sp)
    80002f5e:	1800                	addi	s0,sp,48
    80002f60:	89aa                	mv	s3,a0
    80002f62:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f64:	00015517          	auipc	a0,0x15
    80002f68:	81c50513          	addi	a0,a0,-2020 # 80017780 <bcache>
    80002f6c:	ffffe097          	auipc	ra,0xffffe
    80002f70:	cf6080e7          	jalr	-778(ra) # 80000c62 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f74:	0001d797          	auipc	a5,0x1d
    80002f78:	80c78793          	addi	a5,a5,-2036 # 8001f780 <bcache+0x8000>
    80002f7c:	2b87b483          	ld	s1,696(a5)
    80002f80:	0001d797          	auipc	a5,0x1d
    80002f84:	a6878793          	addi	a5,a5,-1432 # 8001f9e8 <bcache+0x8268>
    80002f88:	02f48f63          	beq	s1,a5,80002fc6 <bread+0x74>
    80002f8c:	873e                	mv	a4,a5
    80002f8e:	a021                	j	80002f96 <bread+0x44>
    80002f90:	68a4                	ld	s1,80(s1)
    80002f92:	02e48a63          	beq	s1,a4,80002fc6 <bread+0x74>
    if(b->dev == dev && b->blockno == blockno){
    80002f96:	449c                	lw	a5,8(s1)
    80002f98:	ff379ce3          	bne	a5,s3,80002f90 <bread+0x3e>
    80002f9c:	44dc                	lw	a5,12(s1)
    80002f9e:	ff2799e3          	bne	a5,s2,80002f90 <bread+0x3e>
      b->refcnt++;
    80002fa2:	40bc                	lw	a5,64(s1)
    80002fa4:	2785                	addiw	a5,a5,1
    80002fa6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fa8:	00014517          	auipc	a0,0x14
    80002fac:	7d850513          	addi	a0,a0,2008 # 80017780 <bcache>
    80002fb0:	ffffe097          	auipc	ra,0xffffe
    80002fb4:	d66080e7          	jalr	-666(ra) # 80000d16 <release>
      acquiresleep(&b->lock);
    80002fb8:	01048513          	addi	a0,s1,16
    80002fbc:	00001097          	auipc	ra,0x1
    80002fc0:	4c4080e7          	jalr	1220(ra) # 80004480 <acquiresleep>
      return b;
    80002fc4:	a8b1                	j	80003020 <bread+0xce>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc6:	0001c797          	auipc	a5,0x1c
    80002fca:	7ba78793          	addi	a5,a5,1978 # 8001f780 <bcache+0x8000>
    80002fce:	2b07b483          	ld	s1,688(a5)
    80002fd2:	0001d797          	auipc	a5,0x1d
    80002fd6:	a1678793          	addi	a5,a5,-1514 # 8001f9e8 <bcache+0x8268>
    80002fda:	04f48d63          	beq	s1,a5,80003034 <bread+0xe2>
    if(b->refcnt == 0) {
    80002fde:	40bc                	lw	a5,64(s1)
    80002fe0:	cb91                	beqz	a5,80002ff4 <bread+0xa2>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fe2:	0001d717          	auipc	a4,0x1d
    80002fe6:	a0670713          	addi	a4,a4,-1530 # 8001f9e8 <bcache+0x8268>
    80002fea:	64a4                	ld	s1,72(s1)
    80002fec:	04e48463          	beq	s1,a4,80003034 <bread+0xe2>
    if(b->refcnt == 0) {
    80002ff0:	40bc                	lw	a5,64(s1)
    80002ff2:	ffe5                	bnez	a5,80002fea <bread+0x98>
      b->dev = dev;
    80002ff4:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002ff8:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002ffc:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003000:	4785                	li	a5,1
    80003002:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003004:	00014517          	auipc	a0,0x14
    80003008:	77c50513          	addi	a0,a0,1916 # 80017780 <bcache>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	d0a080e7          	jalr	-758(ra) # 80000d16 <release>
      acquiresleep(&b->lock);
    80003014:	01048513          	addi	a0,s1,16
    80003018:	00001097          	auipc	ra,0x1
    8000301c:	468080e7          	jalr	1128(ra) # 80004480 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003020:	409c                	lw	a5,0(s1)
    80003022:	c38d                	beqz	a5,80003044 <bread+0xf2>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003024:	8526                	mv	a0,s1
    80003026:	70a2                	ld	ra,40(sp)
    80003028:	7402                	ld	s0,32(sp)
    8000302a:	64e2                	ld	s1,24(sp)
    8000302c:	6942                	ld	s2,16(sp)
    8000302e:	69a2                	ld	s3,8(sp)
    80003030:	6145                	addi	sp,sp,48
    80003032:	8082                	ret
  panic("bget: no buffers");
    80003034:	00005517          	auipc	a0,0x5
    80003038:	44c50513          	addi	a0,a0,1100 # 80008480 <syscalls+0xe8>
    8000303c:	ffffd097          	auipc	ra,0xffffd
    80003040:	538080e7          	jalr	1336(ra) # 80000574 <panic>
    virtio_disk_rw(b, 0);
    80003044:	4581                	li	a1,0
    80003046:	8526                	mv	a0,s1
    80003048:	00003097          	auipc	ra,0x3
    8000304c:	ff6080e7          	jalr	-10(ra) # 8000603e <virtio_disk_rw>
    b->valid = 1;
    80003050:	4785                	li	a5,1
    80003052:	c09c                	sw	a5,0(s1)
  return b;
    80003054:	bfc1                	j	80003024 <bread+0xd2>

0000000080003056 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	e426                	sd	s1,8(sp)
    8000305e:	1000                	addi	s0,sp,32
    80003060:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003062:	0541                	addi	a0,a0,16
    80003064:	00001097          	auipc	ra,0x1
    80003068:	4b6080e7          	jalr	1206(ra) # 8000451a <holdingsleep>
    8000306c:	cd01                	beqz	a0,80003084 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000306e:	4585                	li	a1,1
    80003070:	8526                	mv	a0,s1
    80003072:	00003097          	auipc	ra,0x3
    80003076:	fcc080e7          	jalr	-52(ra) # 8000603e <virtio_disk_rw>
}
    8000307a:	60e2                	ld	ra,24(sp)
    8000307c:	6442                	ld	s0,16(sp)
    8000307e:	64a2                	ld	s1,8(sp)
    80003080:	6105                	addi	sp,sp,32
    80003082:	8082                	ret
    panic("bwrite");
    80003084:	00005517          	auipc	a0,0x5
    80003088:	41450513          	addi	a0,a0,1044 # 80008498 <syscalls+0x100>
    8000308c:	ffffd097          	auipc	ra,0xffffd
    80003090:	4e8080e7          	jalr	1256(ra) # 80000574 <panic>

0000000080003094 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003094:	1101                	addi	sp,sp,-32
    80003096:	ec06                	sd	ra,24(sp)
    80003098:	e822                	sd	s0,16(sp)
    8000309a:	e426                	sd	s1,8(sp)
    8000309c:	e04a                	sd	s2,0(sp)
    8000309e:	1000                	addi	s0,sp,32
    800030a0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030a2:	01050913          	addi	s2,a0,16
    800030a6:	854a                	mv	a0,s2
    800030a8:	00001097          	auipc	ra,0x1
    800030ac:	472080e7          	jalr	1138(ra) # 8000451a <holdingsleep>
    800030b0:	c92d                	beqz	a0,80003122 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030b2:	854a                	mv	a0,s2
    800030b4:	00001097          	auipc	ra,0x1
    800030b8:	422080e7          	jalr	1058(ra) # 800044d6 <releasesleep>

  acquire(&bcache.lock);
    800030bc:	00014517          	auipc	a0,0x14
    800030c0:	6c450513          	addi	a0,a0,1732 # 80017780 <bcache>
    800030c4:	ffffe097          	auipc	ra,0xffffe
    800030c8:	b9e080e7          	jalr	-1122(ra) # 80000c62 <acquire>
  b->refcnt--;
    800030cc:	40bc                	lw	a5,64(s1)
    800030ce:	37fd                	addiw	a5,a5,-1
    800030d0:	0007871b          	sext.w	a4,a5
    800030d4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030d6:	eb05                	bnez	a4,80003106 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030d8:	68bc                	ld	a5,80(s1)
    800030da:	64b8                	ld	a4,72(s1)
    800030dc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030de:	64bc                	ld	a5,72(s1)
    800030e0:	68b8                	ld	a4,80(s1)
    800030e2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030e4:	0001c797          	auipc	a5,0x1c
    800030e8:	69c78793          	addi	a5,a5,1692 # 8001f780 <bcache+0x8000>
    800030ec:	2b87b703          	ld	a4,696(a5)
    800030f0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030f2:	0001d717          	auipc	a4,0x1d
    800030f6:	8f670713          	addi	a4,a4,-1802 # 8001f9e8 <bcache+0x8268>
    800030fa:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030fc:	2b87b703          	ld	a4,696(a5)
    80003100:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003102:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003106:	00014517          	auipc	a0,0x14
    8000310a:	67a50513          	addi	a0,a0,1658 # 80017780 <bcache>
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	c08080e7          	jalr	-1016(ra) # 80000d16 <release>
}
    80003116:	60e2                	ld	ra,24(sp)
    80003118:	6442                	ld	s0,16(sp)
    8000311a:	64a2                	ld	s1,8(sp)
    8000311c:	6902                	ld	s2,0(sp)
    8000311e:	6105                	addi	sp,sp,32
    80003120:	8082                	ret
    panic("brelse");
    80003122:	00005517          	auipc	a0,0x5
    80003126:	37e50513          	addi	a0,a0,894 # 800084a0 <syscalls+0x108>
    8000312a:	ffffd097          	auipc	ra,0xffffd
    8000312e:	44a080e7          	jalr	1098(ra) # 80000574 <panic>

0000000080003132 <bpin>:

void
bpin(struct buf *b) {
    80003132:	1101                	addi	sp,sp,-32
    80003134:	ec06                	sd	ra,24(sp)
    80003136:	e822                	sd	s0,16(sp)
    80003138:	e426                	sd	s1,8(sp)
    8000313a:	1000                	addi	s0,sp,32
    8000313c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000313e:	00014517          	auipc	a0,0x14
    80003142:	64250513          	addi	a0,a0,1602 # 80017780 <bcache>
    80003146:	ffffe097          	auipc	ra,0xffffe
    8000314a:	b1c080e7          	jalr	-1252(ra) # 80000c62 <acquire>
  b->refcnt++;
    8000314e:	40bc                	lw	a5,64(s1)
    80003150:	2785                	addiw	a5,a5,1
    80003152:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003154:	00014517          	auipc	a0,0x14
    80003158:	62c50513          	addi	a0,a0,1580 # 80017780 <bcache>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	bba080e7          	jalr	-1094(ra) # 80000d16 <release>
}
    80003164:	60e2                	ld	ra,24(sp)
    80003166:	6442                	ld	s0,16(sp)
    80003168:	64a2                	ld	s1,8(sp)
    8000316a:	6105                	addi	sp,sp,32
    8000316c:	8082                	ret

000000008000316e <bunpin>:

void
bunpin(struct buf *b) {
    8000316e:	1101                	addi	sp,sp,-32
    80003170:	ec06                	sd	ra,24(sp)
    80003172:	e822                	sd	s0,16(sp)
    80003174:	e426                	sd	s1,8(sp)
    80003176:	1000                	addi	s0,sp,32
    80003178:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000317a:	00014517          	auipc	a0,0x14
    8000317e:	60650513          	addi	a0,a0,1542 # 80017780 <bcache>
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	ae0080e7          	jalr	-1312(ra) # 80000c62 <acquire>
  b->refcnt--;
    8000318a:	40bc                	lw	a5,64(s1)
    8000318c:	37fd                	addiw	a5,a5,-1
    8000318e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003190:	00014517          	auipc	a0,0x14
    80003194:	5f050513          	addi	a0,a0,1520 # 80017780 <bcache>
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	b7e080e7          	jalr	-1154(ra) # 80000d16 <release>
}
    800031a0:	60e2                	ld	ra,24(sp)
    800031a2:	6442                	ld	s0,16(sp)
    800031a4:	64a2                	ld	s1,8(sp)
    800031a6:	6105                	addi	sp,sp,32
    800031a8:	8082                	ret

00000000800031aa <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031aa:	1101                	addi	sp,sp,-32
    800031ac:	ec06                	sd	ra,24(sp)
    800031ae:	e822                	sd	s0,16(sp)
    800031b0:	e426                	sd	s1,8(sp)
    800031b2:	e04a                	sd	s2,0(sp)
    800031b4:	1000                	addi	s0,sp,32
    800031b6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031b8:	00d5d59b          	srliw	a1,a1,0xd
    800031bc:	0001d797          	auipc	a5,0x1d
    800031c0:	c8478793          	addi	a5,a5,-892 # 8001fe40 <sb>
    800031c4:	4fdc                	lw	a5,28(a5)
    800031c6:	9dbd                	addw	a1,a1,a5
    800031c8:	00000097          	auipc	ra,0x0
    800031cc:	d8a080e7          	jalr	-630(ra) # 80002f52 <bread>
  bi = b % BPB;
    800031d0:	2481                	sext.w	s1,s1
  m = 1 << (bi % 8);
    800031d2:	0074f793          	andi	a5,s1,7
    800031d6:	4705                	li	a4,1
    800031d8:	00f7173b          	sllw	a4,a4,a5
  bi = b % BPB;
    800031dc:	6789                	lui	a5,0x2
    800031de:	17fd                	addi	a5,a5,-1
    800031e0:	8cfd                	and	s1,s1,a5
  if((bp->data[bi/8] & m) == 0)
    800031e2:	41f4d79b          	sraiw	a5,s1,0x1f
    800031e6:	01d7d79b          	srliw	a5,a5,0x1d
    800031ea:	9fa5                	addw	a5,a5,s1
    800031ec:	4037d79b          	sraiw	a5,a5,0x3
    800031f0:	00f506b3          	add	a3,a0,a5
    800031f4:	0586c683          	lbu	a3,88(a3) # fffffffffffff058 <end+0xffffffff7ffd9058>
    800031f8:	00d77633          	and	a2,a4,a3
    800031fc:	c61d                	beqz	a2,8000322a <bfree+0x80>
    800031fe:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003200:	97aa                	add	a5,a5,a0
    80003202:	fff74713          	not	a4,a4
    80003206:	8f75                	and	a4,a4,a3
    80003208:	04e78c23          	sb	a4,88(a5) # 2058 <_entry-0x7fffdfa8>
  log_write(bp);
    8000320c:	00001097          	auipc	ra,0x1
    80003210:	136080e7          	jalr	310(ra) # 80004342 <log_write>
  brelse(bp);
    80003214:	854a                	mv	a0,s2
    80003216:	00000097          	auipc	ra,0x0
    8000321a:	e7e080e7          	jalr	-386(ra) # 80003094 <brelse>
}
    8000321e:	60e2                	ld	ra,24(sp)
    80003220:	6442                	ld	s0,16(sp)
    80003222:	64a2                	ld	s1,8(sp)
    80003224:	6902                	ld	s2,0(sp)
    80003226:	6105                	addi	sp,sp,32
    80003228:	8082                	ret
    panic("freeing free block");
    8000322a:	00005517          	auipc	a0,0x5
    8000322e:	27e50513          	addi	a0,a0,638 # 800084a8 <syscalls+0x110>
    80003232:	ffffd097          	auipc	ra,0xffffd
    80003236:	342080e7          	jalr	834(ra) # 80000574 <panic>

000000008000323a <balloc>:
{
    8000323a:	711d                	addi	sp,sp,-96
    8000323c:	ec86                	sd	ra,88(sp)
    8000323e:	e8a2                	sd	s0,80(sp)
    80003240:	e4a6                	sd	s1,72(sp)
    80003242:	e0ca                	sd	s2,64(sp)
    80003244:	fc4e                	sd	s3,56(sp)
    80003246:	f852                	sd	s4,48(sp)
    80003248:	f456                	sd	s5,40(sp)
    8000324a:	f05a                	sd	s6,32(sp)
    8000324c:	ec5e                	sd	s7,24(sp)
    8000324e:	e862                	sd	s8,16(sp)
    80003250:	e466                	sd	s9,8(sp)
    80003252:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003254:	0001d797          	auipc	a5,0x1d
    80003258:	bec78793          	addi	a5,a5,-1044 # 8001fe40 <sb>
    8000325c:	43dc                	lw	a5,4(a5)
    8000325e:	10078e63          	beqz	a5,8000337a <balloc+0x140>
    80003262:	8baa                	mv	s7,a0
    80003264:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003266:	0001db17          	auipc	s6,0x1d
    8000326a:	bdab0b13          	addi	s6,s6,-1062 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326e:	4c05                	li	s8,1
      m = 1 << (bi % 8);
    80003270:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003272:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003274:	6c89                	lui	s9,0x2
    80003276:	a079                	j	80003304 <balloc+0xca>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003278:	8942                	mv	s2,a6
      m = 1 << (bi % 8);
    8000327a:	4705                	li	a4,1
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000327c:	4681                	li	a3,0
        bp->data[bi/8] |= m;  // Mark block in use.
    8000327e:	96a6                	add	a3,a3,s1
    80003280:	8f51                	or	a4,a4,a2
    80003282:	04e68c23          	sb	a4,88(a3)
        log_write(bp);
    80003286:	8526                	mv	a0,s1
    80003288:	00001097          	auipc	ra,0x1
    8000328c:	0ba080e7          	jalr	186(ra) # 80004342 <log_write>
        brelse(bp);
    80003290:	8526                	mv	a0,s1
    80003292:	00000097          	auipc	ra,0x0
    80003296:	e02080e7          	jalr	-510(ra) # 80003094 <brelse>
  bp = bread(dev, bno);
    8000329a:	85ca                	mv	a1,s2
    8000329c:	855e                	mv	a0,s7
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	cb4080e7          	jalr	-844(ra) # 80002f52 <bread>
    800032a6:	84aa                	mv	s1,a0
  memset(bp->data, 0, BSIZE);
    800032a8:	40000613          	li	a2,1024
    800032ac:	4581                	li	a1,0
    800032ae:	05850513          	addi	a0,a0,88
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	aac080e7          	jalr	-1364(ra) # 80000d5e <memset>
  log_write(bp);
    800032ba:	8526                	mv	a0,s1
    800032bc:	00001097          	auipc	ra,0x1
    800032c0:	086080e7          	jalr	134(ra) # 80004342 <log_write>
  brelse(bp);
    800032c4:	8526                	mv	a0,s1
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	dce080e7          	jalr	-562(ra) # 80003094 <brelse>
}
    800032ce:	854a                	mv	a0,s2
    800032d0:	60e6                	ld	ra,88(sp)
    800032d2:	6446                	ld	s0,80(sp)
    800032d4:	64a6                	ld	s1,72(sp)
    800032d6:	6906                	ld	s2,64(sp)
    800032d8:	79e2                	ld	s3,56(sp)
    800032da:	7a42                	ld	s4,48(sp)
    800032dc:	7aa2                	ld	s5,40(sp)
    800032de:	7b02                	ld	s6,32(sp)
    800032e0:	6be2                	ld	s7,24(sp)
    800032e2:	6c42                	ld	s8,16(sp)
    800032e4:	6ca2                	ld	s9,8(sp)
    800032e6:	6125                	addi	sp,sp,96
    800032e8:	8082                	ret
    brelse(bp);
    800032ea:	8526                	mv	a0,s1
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	da8080e7          	jalr	-600(ra) # 80003094 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032f4:	015c87bb          	addw	a5,s9,s5
    800032f8:	00078a9b          	sext.w	s5,a5
    800032fc:	004b2703          	lw	a4,4(s6)
    80003300:	06eafd63          	bleu	a4,s5,8000337a <balloc+0x140>
    bp = bread(dev, BBLOCK(b, sb));
    80003304:	41fad79b          	sraiw	a5,s5,0x1f
    80003308:	0137d79b          	srliw	a5,a5,0x13
    8000330c:	015787bb          	addw	a5,a5,s5
    80003310:	40d7d79b          	sraiw	a5,a5,0xd
    80003314:	01cb2583          	lw	a1,28(s6)
    80003318:	9dbd                	addw	a1,a1,a5
    8000331a:	855e                	mv	a0,s7
    8000331c:	00000097          	auipc	ra,0x0
    80003320:	c36080e7          	jalr	-970(ra) # 80002f52 <bread>
    80003324:	84aa                	mv	s1,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003326:	000a881b          	sext.w	a6,s5
    8000332a:	004b2503          	lw	a0,4(s6)
    8000332e:	faa87ee3          	bleu	a0,a6,800032ea <balloc+0xb0>
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003332:	0584c603          	lbu	a2,88(s1)
    80003336:	00167793          	andi	a5,a2,1
    8000333a:	df9d                	beqz	a5,80003278 <balloc+0x3e>
    8000333c:	4105053b          	subw	a0,a0,a6
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003340:	87e2                	mv	a5,s8
    80003342:	0107893b          	addw	s2,a5,a6
    80003346:	faa782e3          	beq	a5,a0,800032ea <balloc+0xb0>
      m = 1 << (bi % 8);
    8000334a:	41f7d71b          	sraiw	a4,a5,0x1f
    8000334e:	01d7561b          	srliw	a2,a4,0x1d
    80003352:	00f606bb          	addw	a3,a2,a5
    80003356:	0076f713          	andi	a4,a3,7
    8000335a:	9f11                	subw	a4,a4,a2
    8000335c:	00e9973b          	sllw	a4,s3,a4
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003360:	4036d69b          	sraiw	a3,a3,0x3
    80003364:	00d48633          	add	a2,s1,a3
    80003368:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000336c:	00c775b3          	and	a1,a4,a2
    80003370:	d599                	beqz	a1,8000327e <balloc+0x44>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003372:	2785                	addiw	a5,a5,1
    80003374:	fd4797e3          	bne	a5,s4,80003342 <balloc+0x108>
    80003378:	bf8d                	j	800032ea <balloc+0xb0>
  panic("balloc: out of blocks");
    8000337a:	00005517          	auipc	a0,0x5
    8000337e:	14650513          	addi	a0,a0,326 # 800084c0 <syscalls+0x128>
    80003382:	ffffd097          	auipc	ra,0xffffd
    80003386:	1f2080e7          	jalr	498(ra) # 80000574 <panic>

000000008000338a <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000338a:	7179                	addi	sp,sp,-48
    8000338c:	f406                	sd	ra,40(sp)
    8000338e:	f022                	sd	s0,32(sp)
    80003390:	ec26                	sd	s1,24(sp)
    80003392:	e84a                	sd	s2,16(sp)
    80003394:	e44e                	sd	s3,8(sp)
    80003396:	e052                	sd	s4,0(sp)
    80003398:	1800                	addi	s0,sp,48
    8000339a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000339c:	47ad                	li	a5,11
    8000339e:	04b7fe63          	bleu	a1,a5,800033fa <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033a2:	ff45849b          	addiw	s1,a1,-12
    800033a6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033aa:	0ff00793          	li	a5,255
    800033ae:	0ae7e363          	bltu	a5,a4,80003454 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033b2:	08052583          	lw	a1,128(a0)
    800033b6:	c5ad                	beqz	a1,80003420 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033b8:	0009a503          	lw	a0,0(s3)
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	b96080e7          	jalr	-1130(ra) # 80002f52 <bread>
    800033c4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033c6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ca:	02049593          	slli	a1,s1,0x20
    800033ce:	9181                	srli	a1,a1,0x20
    800033d0:	058a                	slli	a1,a1,0x2
    800033d2:	00b784b3          	add	s1,a5,a1
    800033d6:	0004a903          	lw	s2,0(s1)
    800033da:	04090d63          	beqz	s2,80003434 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033de:	8552                	mv	a0,s4
    800033e0:	00000097          	auipc	ra,0x0
    800033e4:	cb4080e7          	jalr	-844(ra) # 80003094 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033e8:	854a                	mv	a0,s2
    800033ea:	70a2                	ld	ra,40(sp)
    800033ec:	7402                	ld	s0,32(sp)
    800033ee:	64e2                	ld	s1,24(sp)
    800033f0:	6942                	ld	s2,16(sp)
    800033f2:	69a2                	ld	s3,8(sp)
    800033f4:	6a02                	ld	s4,0(sp)
    800033f6:	6145                	addi	sp,sp,48
    800033f8:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033fa:	02059493          	slli	s1,a1,0x20
    800033fe:	9081                	srli	s1,s1,0x20
    80003400:	048a                	slli	s1,s1,0x2
    80003402:	94aa                	add	s1,s1,a0
    80003404:	0504a903          	lw	s2,80(s1)
    80003408:	fe0910e3          	bnez	s2,800033e8 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000340c:	4108                	lw	a0,0(a0)
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	e2c080e7          	jalr	-468(ra) # 8000323a <balloc>
    80003416:	0005091b          	sext.w	s2,a0
    8000341a:	0524a823          	sw	s2,80(s1)
    8000341e:	b7e9                	j	800033e8 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003420:	4108                	lw	a0,0(a0)
    80003422:	00000097          	auipc	ra,0x0
    80003426:	e18080e7          	jalr	-488(ra) # 8000323a <balloc>
    8000342a:	0005059b          	sext.w	a1,a0
    8000342e:	08b9a023          	sw	a1,128(s3)
    80003432:	b759                	j	800033b8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003434:	0009a503          	lw	a0,0(s3)
    80003438:	00000097          	auipc	ra,0x0
    8000343c:	e02080e7          	jalr	-510(ra) # 8000323a <balloc>
    80003440:	0005091b          	sext.w	s2,a0
    80003444:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    80003448:	8552                	mv	a0,s4
    8000344a:	00001097          	auipc	ra,0x1
    8000344e:	ef8080e7          	jalr	-264(ra) # 80004342 <log_write>
    80003452:	b771                	j	800033de <bmap+0x54>
  panic("bmap: out of range");
    80003454:	00005517          	auipc	a0,0x5
    80003458:	08450513          	addi	a0,a0,132 # 800084d8 <syscalls+0x140>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	118080e7          	jalr	280(ra) # 80000574 <panic>

0000000080003464 <iget>:
{
    80003464:	7179                	addi	sp,sp,-48
    80003466:	f406                	sd	ra,40(sp)
    80003468:	f022                	sd	s0,32(sp)
    8000346a:	ec26                	sd	s1,24(sp)
    8000346c:	e84a                	sd	s2,16(sp)
    8000346e:	e44e                	sd	s3,8(sp)
    80003470:	e052                	sd	s4,0(sp)
    80003472:	1800                	addi	s0,sp,48
    80003474:	89aa                	mv	s3,a0
    80003476:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003478:	0001d517          	auipc	a0,0x1d
    8000347c:	9e850513          	addi	a0,a0,-1560 # 8001fe60 <icache>
    80003480:	ffffd097          	auipc	ra,0xffffd
    80003484:	7e2080e7          	jalr	2018(ra) # 80000c62 <acquire>
  empty = 0;
    80003488:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000348a:	0001d497          	auipc	s1,0x1d
    8000348e:	9ee48493          	addi	s1,s1,-1554 # 8001fe78 <icache+0x18>
    80003492:	0001e697          	auipc	a3,0x1e
    80003496:	47668693          	addi	a3,a3,1142 # 80021908 <log>
    8000349a:	a039                	j	800034a8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000349c:	02090b63          	beqz	s2,800034d2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034a0:	08848493          	addi	s1,s1,136
    800034a4:	02d48a63          	beq	s1,a3,800034d8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034a8:	449c                	lw	a5,8(s1)
    800034aa:	fef059e3          	blez	a5,8000349c <iget+0x38>
    800034ae:	4098                	lw	a4,0(s1)
    800034b0:	ff3716e3          	bne	a4,s3,8000349c <iget+0x38>
    800034b4:	40d8                	lw	a4,4(s1)
    800034b6:	ff4713e3          	bne	a4,s4,8000349c <iget+0x38>
      ip->ref++;
    800034ba:	2785                	addiw	a5,a5,1
    800034bc:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034be:	0001d517          	auipc	a0,0x1d
    800034c2:	9a250513          	addi	a0,a0,-1630 # 8001fe60 <icache>
    800034c6:	ffffe097          	auipc	ra,0xffffe
    800034ca:	850080e7          	jalr	-1968(ra) # 80000d16 <release>
      return ip;
    800034ce:	8926                	mv	s2,s1
    800034d0:	a03d                	j	800034fe <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034d2:	f7f9                	bnez	a5,800034a0 <iget+0x3c>
    800034d4:	8926                	mv	s2,s1
    800034d6:	b7e9                	j	800034a0 <iget+0x3c>
  if(empty == 0)
    800034d8:	02090c63          	beqz	s2,80003510 <iget+0xac>
  ip->dev = dev;
    800034dc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034e0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034e4:	4785                	li	a5,1
    800034e6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034ea:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034ee:	0001d517          	auipc	a0,0x1d
    800034f2:	97250513          	addi	a0,a0,-1678 # 8001fe60 <icache>
    800034f6:	ffffe097          	auipc	ra,0xffffe
    800034fa:	820080e7          	jalr	-2016(ra) # 80000d16 <release>
}
    800034fe:	854a                	mv	a0,s2
    80003500:	70a2                	ld	ra,40(sp)
    80003502:	7402                	ld	s0,32(sp)
    80003504:	64e2                	ld	s1,24(sp)
    80003506:	6942                	ld	s2,16(sp)
    80003508:	69a2                	ld	s3,8(sp)
    8000350a:	6a02                	ld	s4,0(sp)
    8000350c:	6145                	addi	sp,sp,48
    8000350e:	8082                	ret
    panic("iget: no inodes");
    80003510:	00005517          	auipc	a0,0x5
    80003514:	fe050513          	addi	a0,a0,-32 # 800084f0 <syscalls+0x158>
    80003518:	ffffd097          	auipc	ra,0xffffd
    8000351c:	05c080e7          	jalr	92(ra) # 80000574 <panic>

0000000080003520 <fsinit>:
fsinit(int dev) {
    80003520:	7179                	addi	sp,sp,-48
    80003522:	f406                	sd	ra,40(sp)
    80003524:	f022                	sd	s0,32(sp)
    80003526:	ec26                	sd	s1,24(sp)
    80003528:	e84a                	sd	s2,16(sp)
    8000352a:	e44e                	sd	s3,8(sp)
    8000352c:	1800                	addi	s0,sp,48
    8000352e:	89aa                	mv	s3,a0
  bp = bread(dev, 1);
    80003530:	4585                	li	a1,1
    80003532:	00000097          	auipc	ra,0x0
    80003536:	a20080e7          	jalr	-1504(ra) # 80002f52 <bread>
    8000353a:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000353c:	0001d497          	auipc	s1,0x1d
    80003540:	90448493          	addi	s1,s1,-1788 # 8001fe40 <sb>
    80003544:	02000613          	li	a2,32
    80003548:	05850593          	addi	a1,a0,88
    8000354c:	8526                	mv	a0,s1
    8000354e:	ffffe097          	auipc	ra,0xffffe
    80003552:	87c080e7          	jalr	-1924(ra) # 80000dca <memmove>
  brelse(bp);
    80003556:	854a                	mv	a0,s2
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	b3c080e7          	jalr	-1220(ra) # 80003094 <brelse>
  if(sb.magic != FSMAGIC)
    80003560:	4098                	lw	a4,0(s1)
    80003562:	102037b7          	lui	a5,0x10203
    80003566:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000356a:	02f71263          	bne	a4,a5,8000358e <fsinit+0x6e>
  initlog(dev, &sb);
    8000356e:	0001d597          	auipc	a1,0x1d
    80003572:	8d258593          	addi	a1,a1,-1838 # 8001fe40 <sb>
    80003576:	854e                	mv	a0,s3
    80003578:	00001097          	auipc	ra,0x1
    8000357c:	b4c080e7          	jalr	-1204(ra) # 800040c4 <initlog>
}
    80003580:	70a2                	ld	ra,40(sp)
    80003582:	7402                	ld	s0,32(sp)
    80003584:	64e2                	ld	s1,24(sp)
    80003586:	6942                	ld	s2,16(sp)
    80003588:	69a2                	ld	s3,8(sp)
    8000358a:	6145                	addi	sp,sp,48
    8000358c:	8082                	ret
    panic("invalid file system");
    8000358e:	00005517          	auipc	a0,0x5
    80003592:	f7250513          	addi	a0,a0,-142 # 80008500 <syscalls+0x168>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	fde080e7          	jalr	-34(ra) # 80000574 <panic>

000000008000359e <iinit>:
{
    8000359e:	7179                	addi	sp,sp,-48
    800035a0:	f406                	sd	ra,40(sp)
    800035a2:	f022                	sd	s0,32(sp)
    800035a4:	ec26                	sd	s1,24(sp)
    800035a6:	e84a                	sd	s2,16(sp)
    800035a8:	e44e                	sd	s3,8(sp)
    800035aa:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035ac:	00005597          	auipc	a1,0x5
    800035b0:	f6c58593          	addi	a1,a1,-148 # 80008518 <syscalls+0x180>
    800035b4:	0001d517          	auipc	a0,0x1d
    800035b8:	8ac50513          	addi	a0,a0,-1876 # 8001fe60 <icache>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	616080e7          	jalr	1558(ra) # 80000bd2 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035c4:	0001d497          	auipc	s1,0x1d
    800035c8:	8c448493          	addi	s1,s1,-1852 # 8001fe88 <icache+0x28>
    800035cc:	0001e997          	auipc	s3,0x1e
    800035d0:	34c98993          	addi	s3,s3,844 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035d4:	00005917          	auipc	s2,0x5
    800035d8:	f4c90913          	addi	s2,s2,-180 # 80008520 <syscalls+0x188>
    800035dc:	85ca                	mv	a1,s2
    800035de:	8526                	mv	a0,s1
    800035e0:	00001097          	auipc	ra,0x1
    800035e4:	e66080e7          	jalr	-410(ra) # 80004446 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035e8:	08848493          	addi	s1,s1,136
    800035ec:	ff3498e3          	bne	s1,s3,800035dc <iinit+0x3e>
}
    800035f0:	70a2                	ld	ra,40(sp)
    800035f2:	7402                	ld	s0,32(sp)
    800035f4:	64e2                	ld	s1,24(sp)
    800035f6:	6942                	ld	s2,16(sp)
    800035f8:	69a2                	ld	s3,8(sp)
    800035fa:	6145                	addi	sp,sp,48
    800035fc:	8082                	ret

00000000800035fe <ialloc>:
{
    800035fe:	715d                	addi	sp,sp,-80
    80003600:	e486                	sd	ra,72(sp)
    80003602:	e0a2                	sd	s0,64(sp)
    80003604:	fc26                	sd	s1,56(sp)
    80003606:	f84a                	sd	s2,48(sp)
    80003608:	f44e                	sd	s3,40(sp)
    8000360a:	f052                	sd	s4,32(sp)
    8000360c:	ec56                	sd	s5,24(sp)
    8000360e:	e85a                	sd	s6,16(sp)
    80003610:	e45e                	sd	s7,8(sp)
    80003612:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003614:	0001d797          	auipc	a5,0x1d
    80003618:	82c78793          	addi	a5,a5,-2004 # 8001fe40 <sb>
    8000361c:	47d8                	lw	a4,12(a5)
    8000361e:	4785                	li	a5,1
    80003620:	04e7fa63          	bleu	a4,a5,80003674 <ialloc+0x76>
    80003624:	8a2a                	mv	s4,a0
    80003626:	8b2e                	mv	s6,a1
    80003628:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000362a:	0001d997          	auipc	s3,0x1d
    8000362e:	81698993          	addi	s3,s3,-2026 # 8001fe40 <sb>
    80003632:	00048a9b          	sext.w	s5,s1
    80003636:	0044d593          	srli	a1,s1,0x4
    8000363a:	0189a783          	lw	a5,24(s3)
    8000363e:	9dbd                	addw	a1,a1,a5
    80003640:	8552                	mv	a0,s4
    80003642:	00000097          	auipc	ra,0x0
    80003646:	910080e7          	jalr	-1776(ra) # 80002f52 <bread>
    8000364a:	8baa                	mv	s7,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000364c:	05850913          	addi	s2,a0,88
    80003650:	00f4f793          	andi	a5,s1,15
    80003654:	079a                	slli	a5,a5,0x6
    80003656:	993e                	add	s2,s2,a5
    if(dip->type == 0){  // a free inode
    80003658:	00091783          	lh	a5,0(s2)
    8000365c:	c785                	beqz	a5,80003684 <ialloc+0x86>
    brelse(bp);
    8000365e:	00000097          	auipc	ra,0x0
    80003662:	a36080e7          	jalr	-1482(ra) # 80003094 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003666:	0485                	addi	s1,s1,1
    80003668:	00c9a703          	lw	a4,12(s3)
    8000366c:	0004879b          	sext.w	a5,s1
    80003670:	fce7e1e3          	bltu	a5,a4,80003632 <ialloc+0x34>
  panic("ialloc: no inodes");
    80003674:	00005517          	auipc	a0,0x5
    80003678:	eb450513          	addi	a0,a0,-332 # 80008528 <syscalls+0x190>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	ef8080e7          	jalr	-264(ra) # 80000574 <panic>
      memset(dip, 0, sizeof(*dip));
    80003684:	04000613          	li	a2,64
    80003688:	4581                	li	a1,0
    8000368a:	854a                	mv	a0,s2
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	6d2080e7          	jalr	1746(ra) # 80000d5e <memset>
      dip->type = type;
    80003694:	01691023          	sh	s6,0(s2)
      log_write(bp);   // mark it allocated on the disk
    80003698:	855e                	mv	a0,s7
    8000369a:	00001097          	auipc	ra,0x1
    8000369e:	ca8080e7          	jalr	-856(ra) # 80004342 <log_write>
      brelse(bp);
    800036a2:	855e                	mv	a0,s7
    800036a4:	00000097          	auipc	ra,0x0
    800036a8:	9f0080e7          	jalr	-1552(ra) # 80003094 <brelse>
      return iget(dev, inum);
    800036ac:	85d6                	mv	a1,s5
    800036ae:	8552                	mv	a0,s4
    800036b0:	00000097          	auipc	ra,0x0
    800036b4:	db4080e7          	jalr	-588(ra) # 80003464 <iget>
}
    800036b8:	60a6                	ld	ra,72(sp)
    800036ba:	6406                	ld	s0,64(sp)
    800036bc:	74e2                	ld	s1,56(sp)
    800036be:	7942                	ld	s2,48(sp)
    800036c0:	79a2                	ld	s3,40(sp)
    800036c2:	7a02                	ld	s4,32(sp)
    800036c4:	6ae2                	ld	s5,24(sp)
    800036c6:	6b42                	ld	s6,16(sp)
    800036c8:	6ba2                	ld	s7,8(sp)
    800036ca:	6161                	addi	sp,sp,80
    800036cc:	8082                	ret

00000000800036ce <iupdate>:
{
    800036ce:	1101                	addi	sp,sp,-32
    800036d0:	ec06                	sd	ra,24(sp)
    800036d2:	e822                	sd	s0,16(sp)
    800036d4:	e426                	sd	s1,8(sp)
    800036d6:	e04a                	sd	s2,0(sp)
    800036d8:	1000                	addi	s0,sp,32
    800036da:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036dc:	415c                	lw	a5,4(a0)
    800036de:	0047d79b          	srliw	a5,a5,0x4
    800036e2:	0001c717          	auipc	a4,0x1c
    800036e6:	75e70713          	addi	a4,a4,1886 # 8001fe40 <sb>
    800036ea:	4f0c                	lw	a1,24(a4)
    800036ec:	9dbd                	addw	a1,a1,a5
    800036ee:	4108                	lw	a0,0(a0)
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	862080e7          	jalr	-1950(ra) # 80002f52 <bread>
    800036f8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036fa:	05850513          	addi	a0,a0,88
    800036fe:	40dc                	lw	a5,4(s1)
    80003700:	8bbd                	andi	a5,a5,15
    80003702:	079a                	slli	a5,a5,0x6
    80003704:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003706:	04449783          	lh	a5,68(s1)
    8000370a:	00f51023          	sh	a5,0(a0)
  dip->major = ip->major;
    8000370e:	04649783          	lh	a5,70(s1)
    80003712:	00f51123          	sh	a5,2(a0)
  dip->minor = ip->minor;
    80003716:	04849783          	lh	a5,72(s1)
    8000371a:	00f51223          	sh	a5,4(a0)
  dip->nlink = ip->nlink;
    8000371e:	04a49783          	lh	a5,74(s1)
    80003722:	00f51323          	sh	a5,6(a0)
  dip->size = ip->size;
    80003726:	44fc                	lw	a5,76(s1)
    80003728:	c51c                	sw	a5,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000372a:	03400613          	li	a2,52
    8000372e:	05048593          	addi	a1,s1,80
    80003732:	0531                	addi	a0,a0,12
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	696080e7          	jalr	1686(ra) # 80000dca <memmove>
  log_write(bp);
    8000373c:	854a                	mv	a0,s2
    8000373e:	00001097          	auipc	ra,0x1
    80003742:	c04080e7          	jalr	-1020(ra) # 80004342 <log_write>
  brelse(bp);
    80003746:	854a                	mv	a0,s2
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	94c080e7          	jalr	-1716(ra) # 80003094 <brelse>
}
    80003750:	60e2                	ld	ra,24(sp)
    80003752:	6442                	ld	s0,16(sp)
    80003754:	64a2                	ld	s1,8(sp)
    80003756:	6902                	ld	s2,0(sp)
    80003758:	6105                	addi	sp,sp,32
    8000375a:	8082                	ret

000000008000375c <idup>:
{
    8000375c:	1101                	addi	sp,sp,-32
    8000375e:	ec06                	sd	ra,24(sp)
    80003760:	e822                	sd	s0,16(sp)
    80003762:	e426                	sd	s1,8(sp)
    80003764:	1000                	addi	s0,sp,32
    80003766:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003768:	0001c517          	auipc	a0,0x1c
    8000376c:	6f850513          	addi	a0,a0,1784 # 8001fe60 <icache>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	4f2080e7          	jalr	1266(ra) # 80000c62 <acquire>
  ip->ref++;
    80003778:	449c                	lw	a5,8(s1)
    8000377a:	2785                	addiw	a5,a5,1
    8000377c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000377e:	0001c517          	auipc	a0,0x1c
    80003782:	6e250513          	addi	a0,a0,1762 # 8001fe60 <icache>
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	590080e7          	jalr	1424(ra) # 80000d16 <release>
}
    8000378e:	8526                	mv	a0,s1
    80003790:	60e2                	ld	ra,24(sp)
    80003792:	6442                	ld	s0,16(sp)
    80003794:	64a2                	ld	s1,8(sp)
    80003796:	6105                	addi	sp,sp,32
    80003798:	8082                	ret

000000008000379a <ilock>:
{
    8000379a:	1101                	addi	sp,sp,-32
    8000379c:	ec06                	sd	ra,24(sp)
    8000379e:	e822                	sd	s0,16(sp)
    800037a0:	e426                	sd	s1,8(sp)
    800037a2:	e04a                	sd	s2,0(sp)
    800037a4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037a6:	c115                	beqz	a0,800037ca <ilock+0x30>
    800037a8:	84aa                	mv	s1,a0
    800037aa:	451c                	lw	a5,8(a0)
    800037ac:	00f05f63          	blez	a5,800037ca <ilock+0x30>
  acquiresleep(&ip->lock);
    800037b0:	0541                	addi	a0,a0,16
    800037b2:	00001097          	auipc	ra,0x1
    800037b6:	cce080e7          	jalr	-818(ra) # 80004480 <acquiresleep>
  if(ip->valid == 0){
    800037ba:	40bc                	lw	a5,64(s1)
    800037bc:	cf99                	beqz	a5,800037da <ilock+0x40>
}
    800037be:	60e2                	ld	ra,24(sp)
    800037c0:	6442                	ld	s0,16(sp)
    800037c2:	64a2                	ld	s1,8(sp)
    800037c4:	6902                	ld	s2,0(sp)
    800037c6:	6105                	addi	sp,sp,32
    800037c8:	8082                	ret
    panic("ilock");
    800037ca:	00005517          	auipc	a0,0x5
    800037ce:	d7650513          	addi	a0,a0,-650 # 80008540 <syscalls+0x1a8>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	da2080e7          	jalr	-606(ra) # 80000574 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037da:	40dc                	lw	a5,4(s1)
    800037dc:	0047d79b          	srliw	a5,a5,0x4
    800037e0:	0001c717          	auipc	a4,0x1c
    800037e4:	66070713          	addi	a4,a4,1632 # 8001fe40 <sb>
    800037e8:	4f0c                	lw	a1,24(a4)
    800037ea:	9dbd                	addw	a1,a1,a5
    800037ec:	4088                	lw	a0,0(s1)
    800037ee:	fffff097          	auipc	ra,0xfffff
    800037f2:	764080e7          	jalr	1892(ra) # 80002f52 <bread>
    800037f6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037f8:	05850593          	addi	a1,a0,88
    800037fc:	40dc                	lw	a5,4(s1)
    800037fe:	8bbd                	andi	a5,a5,15
    80003800:	079a                	slli	a5,a5,0x6
    80003802:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003804:	00059783          	lh	a5,0(a1)
    80003808:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000380c:	00259783          	lh	a5,2(a1)
    80003810:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003814:	00459783          	lh	a5,4(a1)
    80003818:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000381c:	00659783          	lh	a5,6(a1)
    80003820:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003824:	459c                	lw	a5,8(a1)
    80003826:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003828:	03400613          	li	a2,52
    8000382c:	05b1                	addi	a1,a1,12
    8000382e:	05048513          	addi	a0,s1,80
    80003832:	ffffd097          	auipc	ra,0xffffd
    80003836:	598080e7          	jalr	1432(ra) # 80000dca <memmove>
    brelse(bp);
    8000383a:	854a                	mv	a0,s2
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	858080e7          	jalr	-1960(ra) # 80003094 <brelse>
    ip->valid = 1;
    80003844:	4785                	li	a5,1
    80003846:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003848:	04449783          	lh	a5,68(s1)
    8000384c:	fbad                	bnez	a5,800037be <ilock+0x24>
      panic("ilock: no type");
    8000384e:	00005517          	auipc	a0,0x5
    80003852:	cfa50513          	addi	a0,a0,-774 # 80008548 <syscalls+0x1b0>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	d1e080e7          	jalr	-738(ra) # 80000574 <panic>

000000008000385e <iunlock>:
{
    8000385e:	1101                	addi	sp,sp,-32
    80003860:	ec06                	sd	ra,24(sp)
    80003862:	e822                	sd	s0,16(sp)
    80003864:	e426                	sd	s1,8(sp)
    80003866:	e04a                	sd	s2,0(sp)
    80003868:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000386a:	c905                	beqz	a0,8000389a <iunlock+0x3c>
    8000386c:	84aa                	mv	s1,a0
    8000386e:	01050913          	addi	s2,a0,16
    80003872:	854a                	mv	a0,s2
    80003874:	00001097          	auipc	ra,0x1
    80003878:	ca6080e7          	jalr	-858(ra) # 8000451a <holdingsleep>
    8000387c:	cd19                	beqz	a0,8000389a <iunlock+0x3c>
    8000387e:	449c                	lw	a5,8(s1)
    80003880:	00f05d63          	blez	a5,8000389a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003884:	854a                	mv	a0,s2
    80003886:	00001097          	auipc	ra,0x1
    8000388a:	c50080e7          	jalr	-944(ra) # 800044d6 <releasesleep>
}
    8000388e:	60e2                	ld	ra,24(sp)
    80003890:	6442                	ld	s0,16(sp)
    80003892:	64a2                	ld	s1,8(sp)
    80003894:	6902                	ld	s2,0(sp)
    80003896:	6105                	addi	sp,sp,32
    80003898:	8082                	ret
    panic("iunlock");
    8000389a:	00005517          	auipc	a0,0x5
    8000389e:	cbe50513          	addi	a0,a0,-834 # 80008558 <syscalls+0x1c0>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	cd2080e7          	jalr	-814(ra) # 80000574 <panic>

00000000800038aa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038aa:	7179                	addi	sp,sp,-48
    800038ac:	f406                	sd	ra,40(sp)
    800038ae:	f022                	sd	s0,32(sp)
    800038b0:	ec26                	sd	s1,24(sp)
    800038b2:	e84a                	sd	s2,16(sp)
    800038b4:	e44e                	sd	s3,8(sp)
    800038b6:	e052                	sd	s4,0(sp)
    800038b8:	1800                	addi	s0,sp,48
    800038ba:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038bc:	05050493          	addi	s1,a0,80
    800038c0:	08050913          	addi	s2,a0,128
    800038c4:	a821                	j	800038dc <itrunc+0x32>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    800038c6:	0009a503          	lw	a0,0(s3)
    800038ca:	00000097          	auipc	ra,0x0
    800038ce:	8e0080e7          	jalr	-1824(ra) # 800031aa <bfree>
      ip->addrs[i] = 0;
    800038d2:	0004a023          	sw	zero,0(s1)
  for(i = 0; i < NDIRECT; i++){
    800038d6:	0491                	addi	s1,s1,4
    800038d8:	01248563          	beq	s1,s2,800038e2 <itrunc+0x38>
    if(ip->addrs[i]){
    800038dc:	408c                	lw	a1,0(s1)
    800038de:	dde5                	beqz	a1,800038d6 <itrunc+0x2c>
    800038e0:	b7dd                	j	800038c6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038e2:	0809a583          	lw	a1,128(s3)
    800038e6:	e185                	bnez	a1,80003906 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038e8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038ec:	854e                	mv	a0,s3
    800038ee:	00000097          	auipc	ra,0x0
    800038f2:	de0080e7          	jalr	-544(ra) # 800036ce <iupdate>
}
    800038f6:	70a2                	ld	ra,40(sp)
    800038f8:	7402                	ld	s0,32(sp)
    800038fa:	64e2                	ld	s1,24(sp)
    800038fc:	6942                	ld	s2,16(sp)
    800038fe:	69a2                	ld	s3,8(sp)
    80003900:	6a02                	ld	s4,0(sp)
    80003902:	6145                	addi	sp,sp,48
    80003904:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003906:	0009a503          	lw	a0,0(s3)
    8000390a:	fffff097          	auipc	ra,0xfffff
    8000390e:	648080e7          	jalr	1608(ra) # 80002f52 <bread>
    80003912:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003914:	05850493          	addi	s1,a0,88
    80003918:	45850913          	addi	s2,a0,1112
    8000391c:	a811                	j	80003930 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000391e:	0009a503          	lw	a0,0(s3)
    80003922:	00000097          	auipc	ra,0x0
    80003926:	888080e7          	jalr	-1912(ra) # 800031aa <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000392a:	0491                	addi	s1,s1,4
    8000392c:	01248563          	beq	s1,s2,80003936 <itrunc+0x8c>
      if(a[j])
    80003930:	408c                	lw	a1,0(s1)
    80003932:	dde5                	beqz	a1,8000392a <itrunc+0x80>
    80003934:	b7ed                	j	8000391e <itrunc+0x74>
    brelse(bp);
    80003936:	8552                	mv	a0,s4
    80003938:	fffff097          	auipc	ra,0xfffff
    8000393c:	75c080e7          	jalr	1884(ra) # 80003094 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003940:	0809a583          	lw	a1,128(s3)
    80003944:	0009a503          	lw	a0,0(s3)
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	862080e7          	jalr	-1950(ra) # 800031aa <bfree>
    ip->addrs[NDIRECT] = 0;
    80003950:	0809a023          	sw	zero,128(s3)
    80003954:	bf51                	j	800038e8 <itrunc+0x3e>

0000000080003956 <iput>:
{
    80003956:	1101                	addi	sp,sp,-32
    80003958:	ec06                	sd	ra,24(sp)
    8000395a:	e822                	sd	s0,16(sp)
    8000395c:	e426                	sd	s1,8(sp)
    8000395e:	e04a                	sd	s2,0(sp)
    80003960:	1000                	addi	s0,sp,32
    80003962:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003964:	0001c517          	auipc	a0,0x1c
    80003968:	4fc50513          	addi	a0,a0,1276 # 8001fe60 <icache>
    8000396c:	ffffd097          	auipc	ra,0xffffd
    80003970:	2f6080e7          	jalr	758(ra) # 80000c62 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003974:	4498                	lw	a4,8(s1)
    80003976:	4785                	li	a5,1
    80003978:	02f70363          	beq	a4,a5,8000399e <iput+0x48>
  ip->ref--;
    8000397c:	449c                	lw	a5,8(s1)
    8000397e:	37fd                	addiw	a5,a5,-1
    80003980:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003982:	0001c517          	auipc	a0,0x1c
    80003986:	4de50513          	addi	a0,a0,1246 # 8001fe60 <icache>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	38c080e7          	jalr	908(ra) # 80000d16 <release>
}
    80003992:	60e2                	ld	ra,24(sp)
    80003994:	6442                	ld	s0,16(sp)
    80003996:	64a2                	ld	s1,8(sp)
    80003998:	6902                	ld	s2,0(sp)
    8000399a:	6105                	addi	sp,sp,32
    8000399c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000399e:	40bc                	lw	a5,64(s1)
    800039a0:	dff1                	beqz	a5,8000397c <iput+0x26>
    800039a2:	04a49783          	lh	a5,74(s1)
    800039a6:	fbf9                	bnez	a5,8000397c <iput+0x26>
    acquiresleep(&ip->lock);
    800039a8:	01048913          	addi	s2,s1,16
    800039ac:	854a                	mv	a0,s2
    800039ae:	00001097          	auipc	ra,0x1
    800039b2:	ad2080e7          	jalr	-1326(ra) # 80004480 <acquiresleep>
    release(&icache.lock);
    800039b6:	0001c517          	auipc	a0,0x1c
    800039ba:	4aa50513          	addi	a0,a0,1194 # 8001fe60 <icache>
    800039be:	ffffd097          	auipc	ra,0xffffd
    800039c2:	358080e7          	jalr	856(ra) # 80000d16 <release>
    itrunc(ip);
    800039c6:	8526                	mv	a0,s1
    800039c8:	00000097          	auipc	ra,0x0
    800039cc:	ee2080e7          	jalr	-286(ra) # 800038aa <itrunc>
    ip->type = 0;
    800039d0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039d4:	8526                	mv	a0,s1
    800039d6:	00000097          	auipc	ra,0x0
    800039da:	cf8080e7          	jalr	-776(ra) # 800036ce <iupdate>
    ip->valid = 0;
    800039de:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039e2:	854a                	mv	a0,s2
    800039e4:	00001097          	auipc	ra,0x1
    800039e8:	af2080e7          	jalr	-1294(ra) # 800044d6 <releasesleep>
    acquire(&icache.lock);
    800039ec:	0001c517          	auipc	a0,0x1c
    800039f0:	47450513          	addi	a0,a0,1140 # 8001fe60 <icache>
    800039f4:	ffffd097          	auipc	ra,0xffffd
    800039f8:	26e080e7          	jalr	622(ra) # 80000c62 <acquire>
    800039fc:	b741                	j	8000397c <iput+0x26>

00000000800039fe <iunlockput>:
{
    800039fe:	1101                	addi	sp,sp,-32
    80003a00:	ec06                	sd	ra,24(sp)
    80003a02:	e822                	sd	s0,16(sp)
    80003a04:	e426                	sd	s1,8(sp)
    80003a06:	1000                	addi	s0,sp,32
    80003a08:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a0a:	00000097          	auipc	ra,0x0
    80003a0e:	e54080e7          	jalr	-428(ra) # 8000385e <iunlock>
  iput(ip);
    80003a12:	8526                	mv	a0,s1
    80003a14:	00000097          	auipc	ra,0x0
    80003a18:	f42080e7          	jalr	-190(ra) # 80003956 <iput>
}
    80003a1c:	60e2                	ld	ra,24(sp)
    80003a1e:	6442                	ld	s0,16(sp)
    80003a20:	64a2                	ld	s1,8(sp)
    80003a22:	6105                	addi	sp,sp,32
    80003a24:	8082                	ret

0000000080003a26 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a26:	1141                	addi	sp,sp,-16
    80003a28:	e422                	sd	s0,8(sp)
    80003a2a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a2c:	411c                	lw	a5,0(a0)
    80003a2e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a30:	415c                	lw	a5,4(a0)
    80003a32:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a34:	04451783          	lh	a5,68(a0)
    80003a38:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a3c:	04a51783          	lh	a5,74(a0)
    80003a40:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a44:	04c56783          	lwu	a5,76(a0)
    80003a48:	e99c                	sd	a5,16(a1)
}
    80003a4a:	6422                	ld	s0,8(sp)
    80003a4c:	0141                	addi	sp,sp,16
    80003a4e:	8082                	ret

0000000080003a50 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a50:	457c                	lw	a5,76(a0)
    80003a52:	0ed7e963          	bltu	a5,a3,80003b44 <readi+0xf4>
{
    80003a56:	7159                	addi	sp,sp,-112
    80003a58:	f486                	sd	ra,104(sp)
    80003a5a:	f0a2                	sd	s0,96(sp)
    80003a5c:	eca6                	sd	s1,88(sp)
    80003a5e:	e8ca                	sd	s2,80(sp)
    80003a60:	e4ce                	sd	s3,72(sp)
    80003a62:	e0d2                	sd	s4,64(sp)
    80003a64:	fc56                	sd	s5,56(sp)
    80003a66:	f85a                	sd	s6,48(sp)
    80003a68:	f45e                	sd	s7,40(sp)
    80003a6a:	f062                	sd	s8,32(sp)
    80003a6c:	ec66                	sd	s9,24(sp)
    80003a6e:	e86a                	sd	s10,16(sp)
    80003a70:	e46e                	sd	s11,8(sp)
    80003a72:	1880                	addi	s0,sp,112
    80003a74:	8baa                	mv	s7,a0
    80003a76:	8c2e                	mv	s8,a1
    80003a78:	8a32                	mv	s4,a2
    80003a7a:	84b6                	mv	s1,a3
    80003a7c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a7e:	9f35                	addw	a4,a4,a3
    return 0;
    80003a80:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a82:	0ad76063          	bltu	a4,a3,80003b22 <readi+0xd2>
  if(off + n > ip->size)
    80003a86:	00e7f463          	bleu	a4,a5,80003a8e <readi+0x3e>
    n = ip->size - off;
    80003a8a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a8e:	0a0b0963          	beqz	s6,80003b40 <readi+0xf0>
    80003a92:	4901                	li	s2,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a94:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a98:	5cfd                	li	s9,-1
    80003a9a:	a82d                	j	80003ad4 <readi+0x84>
    80003a9c:	02099d93          	slli	s11,s3,0x20
    80003aa0:	020ddd93          	srli	s11,s11,0x20
    80003aa4:	058a8613          	addi	a2,s5,88
    80003aa8:	86ee                	mv	a3,s11
    80003aaa:	963a                	add	a2,a2,a4
    80003aac:	85d2                	mv	a1,s4
    80003aae:	8562                	mv	a0,s8
    80003ab0:	fffff097          	auipc	ra,0xfffff
    80003ab4:	a5c080e7          	jalr	-1444(ra) # 8000250c <either_copyout>
    80003ab8:	05950d63          	beq	a0,s9,80003b12 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003abc:	8556                	mv	a0,s5
    80003abe:	fffff097          	auipc	ra,0xfffff
    80003ac2:	5d6080e7          	jalr	1494(ra) # 80003094 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac6:	0129893b          	addw	s2,s3,s2
    80003aca:	009984bb          	addw	s1,s3,s1
    80003ace:	9a6e                	add	s4,s4,s11
    80003ad0:	05697763          	bleu	s6,s2,80003b1e <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ad4:	000ba983          	lw	s3,0(s7)
    80003ad8:	00a4d59b          	srliw	a1,s1,0xa
    80003adc:	855e                	mv	a0,s7
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	8ac080e7          	jalr	-1876(ra) # 8000338a <bmap>
    80003ae6:	0005059b          	sext.w	a1,a0
    80003aea:	854e                	mv	a0,s3
    80003aec:	fffff097          	auipc	ra,0xfffff
    80003af0:	466080e7          	jalr	1126(ra) # 80002f52 <bread>
    80003af4:	8aaa                	mv	s5,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af6:	3ff4f713          	andi	a4,s1,1023
    80003afa:	40ed07bb          	subw	a5,s10,a4
    80003afe:	412b06bb          	subw	a3,s6,s2
    80003b02:	89be                	mv	s3,a5
    80003b04:	2781                	sext.w	a5,a5
    80003b06:	0006861b          	sext.w	a2,a3
    80003b0a:	f8f679e3          	bleu	a5,a2,80003a9c <readi+0x4c>
    80003b0e:	89b6                	mv	s3,a3
    80003b10:	b771                	j	80003a9c <readi+0x4c>
      brelse(bp);
    80003b12:	8556                	mv	a0,s5
    80003b14:	fffff097          	auipc	ra,0xfffff
    80003b18:	580080e7          	jalr	1408(ra) # 80003094 <brelse>
      tot = -1;
    80003b1c:	597d                	li	s2,-1
  }
  return tot;
    80003b1e:	0009051b          	sext.w	a0,s2
}
    80003b22:	70a6                	ld	ra,104(sp)
    80003b24:	7406                	ld	s0,96(sp)
    80003b26:	64e6                	ld	s1,88(sp)
    80003b28:	6946                	ld	s2,80(sp)
    80003b2a:	69a6                	ld	s3,72(sp)
    80003b2c:	6a06                	ld	s4,64(sp)
    80003b2e:	7ae2                	ld	s5,56(sp)
    80003b30:	7b42                	ld	s6,48(sp)
    80003b32:	7ba2                	ld	s7,40(sp)
    80003b34:	7c02                	ld	s8,32(sp)
    80003b36:	6ce2                	ld	s9,24(sp)
    80003b38:	6d42                	ld	s10,16(sp)
    80003b3a:	6da2                	ld	s11,8(sp)
    80003b3c:	6165                	addi	sp,sp,112
    80003b3e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b40:	895a                	mv	s2,s6
    80003b42:	bff1                	j	80003b1e <readi+0xce>
    return 0;
    80003b44:	4501                	li	a0,0
}
    80003b46:	8082                	ret

0000000080003b48 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b48:	457c                	lw	a5,76(a0)
    80003b4a:	10d7e763          	bltu	a5,a3,80003c58 <writei+0x110>
{
    80003b4e:	7159                	addi	sp,sp,-112
    80003b50:	f486                	sd	ra,104(sp)
    80003b52:	f0a2                	sd	s0,96(sp)
    80003b54:	eca6                	sd	s1,88(sp)
    80003b56:	e8ca                	sd	s2,80(sp)
    80003b58:	e4ce                	sd	s3,72(sp)
    80003b5a:	e0d2                	sd	s4,64(sp)
    80003b5c:	fc56                	sd	s5,56(sp)
    80003b5e:	f85a                	sd	s6,48(sp)
    80003b60:	f45e                	sd	s7,40(sp)
    80003b62:	f062                	sd	s8,32(sp)
    80003b64:	ec66                	sd	s9,24(sp)
    80003b66:	e86a                	sd	s10,16(sp)
    80003b68:	e46e                	sd	s11,8(sp)
    80003b6a:	1880                	addi	s0,sp,112
    80003b6c:	8baa                	mv	s7,a0
    80003b6e:	8c2e                	mv	s8,a1
    80003b70:	8ab2                	mv	s5,a2
    80003b72:	84b6                	mv	s1,a3
    80003b74:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b76:	00e687bb          	addw	a5,a3,a4
    80003b7a:	0ed7e163          	bltu	a5,a3,80003c5c <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b7e:	00043737          	lui	a4,0x43
    80003b82:	0cf76f63          	bltu	a4,a5,80003c60 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b86:	0a0b0863          	beqz	s6,80003c36 <writei+0xee>
    80003b8a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b8c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b90:	5cfd                	li	s9,-1
    80003b92:	a091                	j	80003bd6 <writei+0x8e>
    80003b94:	02091d93          	slli	s11,s2,0x20
    80003b98:	020ddd93          	srli	s11,s11,0x20
    80003b9c:	05898513          	addi	a0,s3,88
    80003ba0:	86ee                	mv	a3,s11
    80003ba2:	8656                	mv	a2,s5
    80003ba4:	85e2                	mv	a1,s8
    80003ba6:	953a                	add	a0,a0,a4
    80003ba8:	fffff097          	auipc	ra,0xfffff
    80003bac:	9ba080e7          	jalr	-1606(ra) # 80002562 <either_copyin>
    80003bb0:	07950263          	beq	a0,s9,80003c14 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003bb4:	854e                	mv	a0,s3
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	78c080e7          	jalr	1932(ra) # 80004342 <log_write>
    brelse(bp);
    80003bbe:	854e                	mv	a0,s3
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	4d4080e7          	jalr	1236(ra) # 80003094 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc8:	01490a3b          	addw	s4,s2,s4
    80003bcc:	009904bb          	addw	s1,s2,s1
    80003bd0:	9aee                	add	s5,s5,s11
    80003bd2:	056a7763          	bleu	s6,s4,80003c20 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bd6:	000ba903          	lw	s2,0(s7)
    80003bda:	00a4d59b          	srliw	a1,s1,0xa
    80003bde:	855e                	mv	a0,s7
    80003be0:	fffff097          	auipc	ra,0xfffff
    80003be4:	7aa080e7          	jalr	1962(ra) # 8000338a <bmap>
    80003be8:	0005059b          	sext.w	a1,a0
    80003bec:	854a                	mv	a0,s2
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	364080e7          	jalr	868(ra) # 80002f52 <bread>
    80003bf6:	89aa                	mv	s3,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf8:	3ff4f713          	andi	a4,s1,1023
    80003bfc:	40ed07bb          	subw	a5,s10,a4
    80003c00:	414b06bb          	subw	a3,s6,s4
    80003c04:	893e                	mv	s2,a5
    80003c06:	2781                	sext.w	a5,a5
    80003c08:	0006861b          	sext.w	a2,a3
    80003c0c:	f8f674e3          	bleu	a5,a2,80003b94 <writei+0x4c>
    80003c10:	8936                	mv	s2,a3
    80003c12:	b749                	j	80003b94 <writei+0x4c>
      brelse(bp);
    80003c14:	854e                	mv	a0,s3
    80003c16:	fffff097          	auipc	ra,0xfffff
    80003c1a:	47e080e7          	jalr	1150(ra) # 80003094 <brelse>
      n = -1;
    80003c1e:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003c20:	04cba783          	lw	a5,76(s7)
    80003c24:	0097f463          	bleu	s1,a5,80003c2c <writei+0xe4>
      ip->size = off;
    80003c28:	049ba623          	sw	s1,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c2c:	855e                	mv	a0,s7
    80003c2e:	00000097          	auipc	ra,0x0
    80003c32:	aa0080e7          	jalr	-1376(ra) # 800036ce <iupdate>
  }

  return n;
    80003c36:	000b051b          	sext.w	a0,s6
}
    80003c3a:	70a6                	ld	ra,104(sp)
    80003c3c:	7406                	ld	s0,96(sp)
    80003c3e:	64e6                	ld	s1,88(sp)
    80003c40:	6946                	ld	s2,80(sp)
    80003c42:	69a6                	ld	s3,72(sp)
    80003c44:	6a06                	ld	s4,64(sp)
    80003c46:	7ae2                	ld	s5,56(sp)
    80003c48:	7b42                	ld	s6,48(sp)
    80003c4a:	7ba2                	ld	s7,40(sp)
    80003c4c:	7c02                	ld	s8,32(sp)
    80003c4e:	6ce2                	ld	s9,24(sp)
    80003c50:	6d42                	ld	s10,16(sp)
    80003c52:	6da2                	ld	s11,8(sp)
    80003c54:	6165                	addi	sp,sp,112
    80003c56:	8082                	ret
    return -1;
    80003c58:	557d                	li	a0,-1
}
    80003c5a:	8082                	ret
    return -1;
    80003c5c:	557d                	li	a0,-1
    80003c5e:	bff1                	j	80003c3a <writei+0xf2>
    return -1;
    80003c60:	557d                	li	a0,-1
    80003c62:	bfe1                	j	80003c3a <writei+0xf2>

0000000080003c64 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c64:	1141                	addi	sp,sp,-16
    80003c66:	e406                	sd	ra,8(sp)
    80003c68:	e022                	sd	s0,0(sp)
    80003c6a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c6c:	4639                	li	a2,14
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	1d8080e7          	jalr	472(ra) # 80000e46 <strncmp>
}
    80003c76:	60a2                	ld	ra,8(sp)
    80003c78:	6402                	ld	s0,0(sp)
    80003c7a:	0141                	addi	sp,sp,16
    80003c7c:	8082                	ret

0000000080003c7e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c7e:	7139                	addi	sp,sp,-64
    80003c80:	fc06                	sd	ra,56(sp)
    80003c82:	f822                	sd	s0,48(sp)
    80003c84:	f426                	sd	s1,40(sp)
    80003c86:	f04a                	sd	s2,32(sp)
    80003c88:	ec4e                	sd	s3,24(sp)
    80003c8a:	e852                	sd	s4,16(sp)
    80003c8c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c8e:	04451703          	lh	a4,68(a0)
    80003c92:	4785                	li	a5,1
    80003c94:	00f71a63          	bne	a4,a5,80003ca8 <dirlookup+0x2a>
    80003c98:	892a                	mv	s2,a0
    80003c9a:	89ae                	mv	s3,a1
    80003c9c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9e:	457c                	lw	a5,76(a0)
    80003ca0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ca2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca4:	e79d                	bnez	a5,80003cd2 <dirlookup+0x54>
    80003ca6:	a8a5                	j	80003d1e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ca8:	00005517          	auipc	a0,0x5
    80003cac:	8b850513          	addi	a0,a0,-1864 # 80008560 <syscalls+0x1c8>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	8c4080e7          	jalr	-1852(ra) # 80000574 <panic>
      panic("dirlookup read");
    80003cb8:	00005517          	auipc	a0,0x5
    80003cbc:	8c050513          	addi	a0,a0,-1856 # 80008578 <syscalls+0x1e0>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	8b4080e7          	jalr	-1868(ra) # 80000574 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc8:	24c1                	addiw	s1,s1,16
    80003cca:	04c92783          	lw	a5,76(s2)
    80003cce:	04f4f763          	bleu	a5,s1,80003d1c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cd2:	4741                	li	a4,16
    80003cd4:	86a6                	mv	a3,s1
    80003cd6:	fc040613          	addi	a2,s0,-64
    80003cda:	4581                	li	a1,0
    80003cdc:	854a                	mv	a0,s2
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	d72080e7          	jalr	-654(ra) # 80003a50 <readi>
    80003ce6:	47c1                	li	a5,16
    80003ce8:	fcf518e3          	bne	a0,a5,80003cb8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cec:	fc045783          	lhu	a5,-64(s0)
    80003cf0:	dfe1                	beqz	a5,80003cc8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cf2:	fc240593          	addi	a1,s0,-62
    80003cf6:	854e                	mv	a0,s3
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	f6c080e7          	jalr	-148(ra) # 80003c64 <namecmp>
    80003d00:	f561                	bnez	a0,80003cc8 <dirlookup+0x4a>
      if(poff)
    80003d02:	000a0463          	beqz	s4,80003d0a <dirlookup+0x8c>
        *poff = off;
    80003d06:	009a2023          	sw	s1,0(s4) # 2000 <_entry-0x7fffe000>
      return iget(dp->dev, inum);
    80003d0a:	fc045583          	lhu	a1,-64(s0)
    80003d0e:	00092503          	lw	a0,0(s2)
    80003d12:	fffff097          	auipc	ra,0xfffff
    80003d16:	752080e7          	jalr	1874(ra) # 80003464 <iget>
    80003d1a:	a011                	j	80003d1e <dirlookup+0xa0>
  return 0;
    80003d1c:	4501                	li	a0,0
}
    80003d1e:	70e2                	ld	ra,56(sp)
    80003d20:	7442                	ld	s0,48(sp)
    80003d22:	74a2                	ld	s1,40(sp)
    80003d24:	7902                	ld	s2,32(sp)
    80003d26:	69e2                	ld	s3,24(sp)
    80003d28:	6a42                	ld	s4,16(sp)
    80003d2a:	6121                	addi	sp,sp,64
    80003d2c:	8082                	ret

0000000080003d2e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d2e:	711d                	addi	sp,sp,-96
    80003d30:	ec86                	sd	ra,88(sp)
    80003d32:	e8a2                	sd	s0,80(sp)
    80003d34:	e4a6                	sd	s1,72(sp)
    80003d36:	e0ca                	sd	s2,64(sp)
    80003d38:	fc4e                	sd	s3,56(sp)
    80003d3a:	f852                	sd	s4,48(sp)
    80003d3c:	f456                	sd	s5,40(sp)
    80003d3e:	f05a                	sd	s6,32(sp)
    80003d40:	ec5e                	sd	s7,24(sp)
    80003d42:	e862                	sd	s8,16(sp)
    80003d44:	e466                	sd	s9,8(sp)
    80003d46:	1080                	addi	s0,sp,96
    80003d48:	84aa                	mv	s1,a0
    80003d4a:	8bae                	mv	s7,a1
    80003d4c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d4e:	00054703          	lbu	a4,0(a0)
    80003d52:	02f00793          	li	a5,47
    80003d56:	02f70363          	beq	a4,a5,80003d7c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d5a:	ffffe097          	auipc	ra,0xffffe
    80003d5e:	d36080e7          	jalr	-714(ra) # 80001a90 <myproc>
    80003d62:	15053503          	ld	a0,336(a0)
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	9f6080e7          	jalr	-1546(ra) # 8000375c <idup>
    80003d6e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d70:	02f00913          	li	s2,47
  len = path - s;
    80003d74:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d76:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d78:	4c05                	li	s8,1
    80003d7a:	a865                	j	80003e32 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d7c:	4585                	li	a1,1
    80003d7e:	4505                	li	a0,1
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	6e4080e7          	jalr	1764(ra) # 80003464 <iget>
    80003d88:	89aa                	mv	s3,a0
    80003d8a:	b7dd                	j	80003d70 <namex+0x42>
      iunlockput(ip);
    80003d8c:	854e                	mv	a0,s3
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	c70080e7          	jalr	-912(ra) # 800039fe <iunlockput>
      return 0;
    80003d96:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d98:	854e                	mv	a0,s3
    80003d9a:	60e6                	ld	ra,88(sp)
    80003d9c:	6446                	ld	s0,80(sp)
    80003d9e:	64a6                	ld	s1,72(sp)
    80003da0:	6906                	ld	s2,64(sp)
    80003da2:	79e2                	ld	s3,56(sp)
    80003da4:	7a42                	ld	s4,48(sp)
    80003da6:	7aa2                	ld	s5,40(sp)
    80003da8:	7b02                	ld	s6,32(sp)
    80003daa:	6be2                	ld	s7,24(sp)
    80003dac:	6c42                	ld	s8,16(sp)
    80003dae:	6ca2                	ld	s9,8(sp)
    80003db0:	6125                	addi	sp,sp,96
    80003db2:	8082                	ret
      iunlock(ip);
    80003db4:	854e                	mv	a0,s3
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	aa8080e7          	jalr	-1368(ra) # 8000385e <iunlock>
      return ip;
    80003dbe:	bfe9                	j	80003d98 <namex+0x6a>
      iunlockput(ip);
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	c3c080e7          	jalr	-964(ra) # 800039fe <iunlockput>
      return 0;
    80003dca:	89d2                	mv	s3,s4
    80003dcc:	b7f1                	j	80003d98 <namex+0x6a>
  len = path - s;
    80003dce:	40b48633          	sub	a2,s1,a1
    80003dd2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dd6:	094cd663          	ble	s4,s9,80003e62 <namex+0x134>
    memmove(name, s, DIRSIZ);
    80003dda:	4639                	li	a2,14
    80003ddc:	8556                	mv	a0,s5
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	fec080e7          	jalr	-20(ra) # 80000dca <memmove>
  while(*path == '/')
    80003de6:	0004c783          	lbu	a5,0(s1)
    80003dea:	01279763          	bne	a5,s2,80003df8 <namex+0xca>
    path++;
    80003dee:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	ff278de3          	beq	a5,s2,80003dee <namex+0xc0>
    ilock(ip);
    80003df8:	854e                	mv	a0,s3
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	9a0080e7          	jalr	-1632(ra) # 8000379a <ilock>
    if(ip->type != T_DIR){
    80003e02:	04499783          	lh	a5,68(s3)
    80003e06:	f98793e3          	bne	a5,s8,80003d8c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e0a:	000b8563          	beqz	s7,80003e14 <namex+0xe6>
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	d3cd                	beqz	a5,80003db4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e14:	865a                	mv	a2,s6
    80003e16:	85d6                	mv	a1,s5
    80003e18:	854e                	mv	a0,s3
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	e64080e7          	jalr	-412(ra) # 80003c7e <dirlookup>
    80003e22:	8a2a                	mv	s4,a0
    80003e24:	dd51                	beqz	a0,80003dc0 <namex+0x92>
    iunlockput(ip);
    80003e26:	854e                	mv	a0,s3
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	bd6080e7          	jalr	-1066(ra) # 800039fe <iunlockput>
    ip = next;
    80003e30:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e32:	0004c783          	lbu	a5,0(s1)
    80003e36:	05279d63          	bne	a5,s2,80003e90 <namex+0x162>
    path++;
    80003e3a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e3c:	0004c783          	lbu	a5,0(s1)
    80003e40:	ff278de3          	beq	a5,s2,80003e3a <namex+0x10c>
  if(*path == 0)
    80003e44:	cf8d                	beqz	a5,80003e7e <namex+0x150>
  while(*path != '/' && *path != 0)
    80003e46:	01278b63          	beq	a5,s2,80003e5c <namex+0x12e>
    80003e4a:	c795                	beqz	a5,80003e76 <namex+0x148>
    path++;
    80003e4c:	85a6                	mv	a1,s1
    path++;
    80003e4e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e50:	0004c783          	lbu	a5,0(s1)
    80003e54:	f7278de3          	beq	a5,s2,80003dce <namex+0xa0>
    80003e58:	fbfd                	bnez	a5,80003e4e <namex+0x120>
    80003e5a:	bf95                	j	80003dce <namex+0xa0>
    80003e5c:	85a6                	mv	a1,s1
  len = path - s;
    80003e5e:	8a5a                	mv	s4,s6
    80003e60:	865a                	mv	a2,s6
    memmove(name, s, len);
    80003e62:	2601                	sext.w	a2,a2
    80003e64:	8556                	mv	a0,s5
    80003e66:	ffffd097          	auipc	ra,0xffffd
    80003e6a:	f64080e7          	jalr	-156(ra) # 80000dca <memmove>
    name[len] = 0;
    80003e6e:	9a56                	add	s4,s4,s5
    80003e70:	000a0023          	sb	zero,0(s4)
    80003e74:	bf8d                	j	80003de6 <namex+0xb8>
  while(*path != '/' && *path != 0)
    80003e76:	85a6                	mv	a1,s1
  len = path - s;
    80003e78:	8a5a                	mv	s4,s6
    80003e7a:	865a                	mv	a2,s6
    80003e7c:	b7dd                	j	80003e62 <namex+0x134>
  if(nameiparent){
    80003e7e:	f00b8de3          	beqz	s7,80003d98 <namex+0x6a>
    iput(ip);
    80003e82:	854e                	mv	a0,s3
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	ad2080e7          	jalr	-1326(ra) # 80003956 <iput>
    return 0;
    80003e8c:	4981                	li	s3,0
    80003e8e:	b729                	j	80003d98 <namex+0x6a>
  if(*path == 0)
    80003e90:	d7fd                	beqz	a5,80003e7e <namex+0x150>
    80003e92:	85a6                	mv	a1,s1
    80003e94:	bf6d                	j	80003e4e <namex+0x120>

0000000080003e96 <dirlink>:
{
    80003e96:	7139                	addi	sp,sp,-64
    80003e98:	fc06                	sd	ra,56(sp)
    80003e9a:	f822                	sd	s0,48(sp)
    80003e9c:	f426                	sd	s1,40(sp)
    80003e9e:	f04a                	sd	s2,32(sp)
    80003ea0:	ec4e                	sd	s3,24(sp)
    80003ea2:	e852                	sd	s4,16(sp)
    80003ea4:	0080                	addi	s0,sp,64
    80003ea6:	892a                	mv	s2,a0
    80003ea8:	8a2e                	mv	s4,a1
    80003eaa:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003eac:	4601                	li	a2,0
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	dd0080e7          	jalr	-560(ra) # 80003c7e <dirlookup>
    80003eb6:	e93d                	bnez	a0,80003f2c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb8:	04c92483          	lw	s1,76(s2)
    80003ebc:	c49d                	beqz	s1,80003eea <dirlink+0x54>
    80003ebe:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ec0:	4741                	li	a4,16
    80003ec2:	86a6                	mv	a3,s1
    80003ec4:	fc040613          	addi	a2,s0,-64
    80003ec8:	4581                	li	a1,0
    80003eca:	854a                	mv	a0,s2
    80003ecc:	00000097          	auipc	ra,0x0
    80003ed0:	b84080e7          	jalr	-1148(ra) # 80003a50 <readi>
    80003ed4:	47c1                	li	a5,16
    80003ed6:	06f51163          	bne	a0,a5,80003f38 <dirlink+0xa2>
    if(de.inum == 0)
    80003eda:	fc045783          	lhu	a5,-64(s0)
    80003ede:	c791                	beqz	a5,80003eea <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee0:	24c1                	addiw	s1,s1,16
    80003ee2:	04c92783          	lw	a5,76(s2)
    80003ee6:	fcf4ede3          	bltu	s1,a5,80003ec0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eea:	4639                	li	a2,14
    80003eec:	85d2                	mv	a1,s4
    80003eee:	fc240513          	addi	a0,s0,-62
    80003ef2:	ffffd097          	auipc	ra,0xffffd
    80003ef6:	fa4080e7          	jalr	-92(ra) # 80000e96 <strncpy>
  de.inum = inum;
    80003efa:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003efe:	4741                	li	a4,16
    80003f00:	86a6                	mv	a3,s1
    80003f02:	fc040613          	addi	a2,s0,-64
    80003f06:	4581                	li	a1,0
    80003f08:	854a                	mv	a0,s2
    80003f0a:	00000097          	auipc	ra,0x0
    80003f0e:	c3e080e7          	jalr	-962(ra) # 80003b48 <writei>
    80003f12:	4741                	li	a4,16
  return 0;
    80003f14:	4781                	li	a5,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f16:	02e51963          	bne	a0,a4,80003f48 <dirlink+0xb2>
}
    80003f1a:	853e                	mv	a0,a5
    80003f1c:	70e2                	ld	ra,56(sp)
    80003f1e:	7442                	ld	s0,48(sp)
    80003f20:	74a2                	ld	s1,40(sp)
    80003f22:	7902                	ld	s2,32(sp)
    80003f24:	69e2                	ld	s3,24(sp)
    80003f26:	6a42                	ld	s4,16(sp)
    80003f28:	6121                	addi	sp,sp,64
    80003f2a:	8082                	ret
    iput(ip);
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	a2a080e7          	jalr	-1494(ra) # 80003956 <iput>
    return -1;
    80003f34:	57fd                	li	a5,-1
    80003f36:	b7d5                	j	80003f1a <dirlink+0x84>
      panic("dirlink read");
    80003f38:	00004517          	auipc	a0,0x4
    80003f3c:	65050513          	addi	a0,a0,1616 # 80008588 <syscalls+0x1f0>
    80003f40:	ffffc097          	auipc	ra,0xffffc
    80003f44:	634080e7          	jalr	1588(ra) # 80000574 <panic>
    panic("dirlink");
    80003f48:	00004517          	auipc	a0,0x4
    80003f4c:	76050513          	addi	a0,a0,1888 # 800086a8 <syscalls+0x310>
    80003f50:	ffffc097          	auipc	ra,0xffffc
    80003f54:	624080e7          	jalr	1572(ra) # 80000574 <panic>

0000000080003f58 <namei>:

struct inode*
namei(char *path)
{
    80003f58:	1101                	addi	sp,sp,-32
    80003f5a:	ec06                	sd	ra,24(sp)
    80003f5c:	e822                	sd	s0,16(sp)
    80003f5e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f60:	fe040613          	addi	a2,s0,-32
    80003f64:	4581                	li	a1,0
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	dc8080e7          	jalr	-568(ra) # 80003d2e <namex>
}
    80003f6e:	60e2                	ld	ra,24(sp)
    80003f70:	6442                	ld	s0,16(sp)
    80003f72:	6105                	addi	sp,sp,32
    80003f74:	8082                	ret

0000000080003f76 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f76:	1141                	addi	sp,sp,-16
    80003f78:	e406                	sd	ra,8(sp)
    80003f7a:	e022                	sd	s0,0(sp)
    80003f7c:	0800                	addi	s0,sp,16
  return namex(path, 1, name);
    80003f7e:	862e                	mv	a2,a1
    80003f80:	4585                	li	a1,1
    80003f82:	00000097          	auipc	ra,0x0
    80003f86:	dac080e7          	jalr	-596(ra) # 80003d2e <namex>
}
    80003f8a:	60a2                	ld	ra,8(sp)
    80003f8c:	6402                	ld	s0,0(sp)
    80003f8e:	0141                	addi	sp,sp,16
    80003f90:	8082                	ret

0000000080003f92 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f92:	1101                	addi	sp,sp,-32
    80003f94:	ec06                	sd	ra,24(sp)
    80003f96:	e822                	sd	s0,16(sp)
    80003f98:	e426                	sd	s1,8(sp)
    80003f9a:	e04a                	sd	s2,0(sp)
    80003f9c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f9e:	0001e917          	auipc	s2,0x1e
    80003fa2:	96a90913          	addi	s2,s2,-1686 # 80021908 <log>
    80003fa6:	01892583          	lw	a1,24(s2)
    80003faa:	02892503          	lw	a0,40(s2)
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	fa4080e7          	jalr	-92(ra) # 80002f52 <bread>
    80003fb6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fb8:	02c92683          	lw	a3,44(s2)
    80003fbc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fbe:	02d05763          	blez	a3,80003fec <write_head+0x5a>
    80003fc2:	0001e797          	auipc	a5,0x1e
    80003fc6:	97678793          	addi	a5,a5,-1674 # 80021938 <log+0x30>
    80003fca:	05c50713          	addi	a4,a0,92
    80003fce:	36fd                	addiw	a3,a3,-1
    80003fd0:	1682                	slli	a3,a3,0x20
    80003fd2:	9281                	srli	a3,a3,0x20
    80003fd4:	068a                	slli	a3,a3,0x2
    80003fd6:	0001e617          	auipc	a2,0x1e
    80003fda:	96660613          	addi	a2,a2,-1690 # 8002193c <log+0x34>
    80003fde:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fe0:	4390                	lw	a2,0(a5)
    80003fe2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe4:	0791                	addi	a5,a5,4
    80003fe6:	0711                	addi	a4,a4,4
    80003fe8:	fed79ce3          	bne	a5,a3,80003fe0 <write_head+0x4e>
  }
  bwrite(buf);
    80003fec:	8526                	mv	a0,s1
    80003fee:	fffff097          	auipc	ra,0xfffff
    80003ff2:	068080e7          	jalr	104(ra) # 80003056 <bwrite>
  brelse(buf);
    80003ff6:	8526                	mv	a0,s1
    80003ff8:	fffff097          	auipc	ra,0xfffff
    80003ffc:	09c080e7          	jalr	156(ra) # 80003094 <brelse>
}
    80004000:	60e2                	ld	ra,24(sp)
    80004002:	6442                	ld	s0,16(sp)
    80004004:	64a2                	ld	s1,8(sp)
    80004006:	6902                	ld	s2,0(sp)
    80004008:	6105                	addi	sp,sp,32
    8000400a:	8082                	ret

000000008000400c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000400c:	0001e797          	auipc	a5,0x1e
    80004010:	8fc78793          	addi	a5,a5,-1796 # 80021908 <log>
    80004014:	57dc                	lw	a5,44(a5)
    80004016:	0af05663          	blez	a5,800040c2 <install_trans+0xb6>
{
    8000401a:	7139                	addi	sp,sp,-64
    8000401c:	fc06                	sd	ra,56(sp)
    8000401e:	f822                	sd	s0,48(sp)
    80004020:	f426                	sd	s1,40(sp)
    80004022:	f04a                	sd	s2,32(sp)
    80004024:	ec4e                	sd	s3,24(sp)
    80004026:	e852                	sd	s4,16(sp)
    80004028:	e456                	sd	s5,8(sp)
    8000402a:	0080                	addi	s0,sp,64
    8000402c:	0001ea17          	auipc	s4,0x1e
    80004030:	90ca0a13          	addi	s4,s4,-1780 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004034:	4981                	li	s3,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004036:	0001e917          	auipc	s2,0x1e
    8000403a:	8d290913          	addi	s2,s2,-1838 # 80021908 <log>
    8000403e:	01892583          	lw	a1,24(s2)
    80004042:	013585bb          	addw	a1,a1,s3
    80004046:	2585                	addiw	a1,a1,1
    80004048:	02892503          	lw	a0,40(s2)
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	f06080e7          	jalr	-250(ra) # 80002f52 <bread>
    80004054:	8aaa                	mv	s5,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004056:	000a2583          	lw	a1,0(s4)
    8000405a:	02892503          	lw	a0,40(s2)
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	ef4080e7          	jalr	-268(ra) # 80002f52 <bread>
    80004066:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004068:	40000613          	li	a2,1024
    8000406c:	058a8593          	addi	a1,s5,88
    80004070:	05850513          	addi	a0,a0,88
    80004074:	ffffd097          	auipc	ra,0xffffd
    80004078:	d56080e7          	jalr	-682(ra) # 80000dca <memmove>
    bwrite(dbuf);  // write dst to disk
    8000407c:	8526                	mv	a0,s1
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	fd8080e7          	jalr	-40(ra) # 80003056 <bwrite>
    bunpin(dbuf);
    80004086:	8526                	mv	a0,s1
    80004088:	fffff097          	auipc	ra,0xfffff
    8000408c:	0e6080e7          	jalr	230(ra) # 8000316e <bunpin>
    brelse(lbuf);
    80004090:	8556                	mv	a0,s5
    80004092:	fffff097          	auipc	ra,0xfffff
    80004096:	002080e7          	jalr	2(ra) # 80003094 <brelse>
    brelse(dbuf);
    8000409a:	8526                	mv	a0,s1
    8000409c:	fffff097          	auipc	ra,0xfffff
    800040a0:	ff8080e7          	jalr	-8(ra) # 80003094 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040a4:	2985                	addiw	s3,s3,1
    800040a6:	0a11                	addi	s4,s4,4
    800040a8:	02c92783          	lw	a5,44(s2)
    800040ac:	f8f9c9e3          	blt	s3,a5,8000403e <install_trans+0x32>
}
    800040b0:	70e2                	ld	ra,56(sp)
    800040b2:	7442                	ld	s0,48(sp)
    800040b4:	74a2                	ld	s1,40(sp)
    800040b6:	7902                	ld	s2,32(sp)
    800040b8:	69e2                	ld	s3,24(sp)
    800040ba:	6a42                	ld	s4,16(sp)
    800040bc:	6aa2                	ld	s5,8(sp)
    800040be:	6121                	addi	sp,sp,64
    800040c0:	8082                	ret
    800040c2:	8082                	ret

00000000800040c4 <initlog>:
{
    800040c4:	7179                	addi	sp,sp,-48
    800040c6:	f406                	sd	ra,40(sp)
    800040c8:	f022                	sd	s0,32(sp)
    800040ca:	ec26                	sd	s1,24(sp)
    800040cc:	e84a                	sd	s2,16(sp)
    800040ce:	e44e                	sd	s3,8(sp)
    800040d0:	1800                	addi	s0,sp,48
    800040d2:	892a                	mv	s2,a0
    800040d4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040d6:	0001e497          	auipc	s1,0x1e
    800040da:	83248493          	addi	s1,s1,-1998 # 80021908 <log>
    800040de:	00004597          	auipc	a1,0x4
    800040e2:	4ba58593          	addi	a1,a1,1210 # 80008598 <syscalls+0x200>
    800040e6:	8526                	mv	a0,s1
    800040e8:	ffffd097          	auipc	ra,0xffffd
    800040ec:	aea080e7          	jalr	-1302(ra) # 80000bd2 <initlock>
  log.start = sb->logstart;
    800040f0:	0149a583          	lw	a1,20(s3)
    800040f4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040f6:	0109a783          	lw	a5,16(s3)
    800040fa:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040fc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004100:	854a                	mv	a0,s2
    80004102:	fffff097          	auipc	ra,0xfffff
    80004106:	e50080e7          	jalr	-432(ra) # 80002f52 <bread>
  log.lh.n = lh->n;
    8000410a:	4d3c                	lw	a5,88(a0)
    8000410c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000410e:	02f05563          	blez	a5,80004138 <initlog+0x74>
    80004112:	05c50713          	addi	a4,a0,92
    80004116:	0001e697          	auipc	a3,0x1e
    8000411a:	82268693          	addi	a3,a3,-2014 # 80021938 <log+0x30>
    8000411e:	37fd                	addiw	a5,a5,-1
    80004120:	1782                	slli	a5,a5,0x20
    80004122:	9381                	srli	a5,a5,0x20
    80004124:	078a                	slli	a5,a5,0x2
    80004126:	06050613          	addi	a2,a0,96
    8000412a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000412c:	4310                	lw	a2,0(a4)
    8000412e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004130:	0711                	addi	a4,a4,4
    80004132:	0691                	addi	a3,a3,4
    80004134:	fef71ce3          	bne	a4,a5,8000412c <initlog+0x68>
  brelse(buf);
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	f5c080e7          	jalr	-164(ra) # 80003094 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004140:	00000097          	auipc	ra,0x0
    80004144:	ecc080e7          	jalr	-308(ra) # 8000400c <install_trans>
  log.lh.n = 0;
    80004148:	0001d797          	auipc	a5,0x1d
    8000414c:	7e07a623          	sw	zero,2028(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    80004150:	00000097          	auipc	ra,0x0
    80004154:	e42080e7          	jalr	-446(ra) # 80003f92 <write_head>
}
    80004158:	70a2                	ld	ra,40(sp)
    8000415a:	7402                	ld	s0,32(sp)
    8000415c:	64e2                	ld	s1,24(sp)
    8000415e:	6942                	ld	s2,16(sp)
    80004160:	69a2                	ld	s3,8(sp)
    80004162:	6145                	addi	sp,sp,48
    80004164:	8082                	ret

0000000080004166 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004166:	1101                	addi	sp,sp,-32
    80004168:	ec06                	sd	ra,24(sp)
    8000416a:	e822                	sd	s0,16(sp)
    8000416c:	e426                	sd	s1,8(sp)
    8000416e:	e04a                	sd	s2,0(sp)
    80004170:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004172:	0001d517          	auipc	a0,0x1d
    80004176:	79650513          	addi	a0,a0,1942 # 80021908 <log>
    8000417a:	ffffd097          	auipc	ra,0xffffd
    8000417e:	ae8080e7          	jalr	-1304(ra) # 80000c62 <acquire>
  while(1){
    if(log.committing){
    80004182:	0001d497          	auipc	s1,0x1d
    80004186:	78648493          	addi	s1,s1,1926 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000418a:	4979                	li	s2,30
    8000418c:	a039                	j	8000419a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000418e:	85a6                	mv	a1,s1
    80004190:	8526                	mv	a0,s1
    80004192:	ffffe097          	auipc	ra,0xffffe
    80004196:	118080e7          	jalr	280(ra) # 800022aa <sleep>
    if(log.committing){
    8000419a:	50dc                	lw	a5,36(s1)
    8000419c:	fbed                	bnez	a5,8000418e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000419e:	509c                	lw	a5,32(s1)
    800041a0:	0017871b          	addiw	a4,a5,1
    800041a4:	0007069b          	sext.w	a3,a4
    800041a8:	0027179b          	slliw	a5,a4,0x2
    800041ac:	9fb9                	addw	a5,a5,a4
    800041ae:	0017979b          	slliw	a5,a5,0x1
    800041b2:	54d8                	lw	a4,44(s1)
    800041b4:	9fb9                	addw	a5,a5,a4
    800041b6:	00f95963          	ble	a5,s2,800041c8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041ba:	85a6                	mv	a1,s1
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffe097          	auipc	ra,0xffffe
    800041c2:	0ec080e7          	jalr	236(ra) # 800022aa <sleep>
    800041c6:	bfd1                	j	8000419a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041c8:	0001d517          	auipc	a0,0x1d
    800041cc:	74050513          	addi	a0,a0,1856 # 80021908 <log>
    800041d0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	b44080e7          	jalr	-1212(ra) # 80000d16 <release>
      break;
    }
  }
}
    800041da:	60e2                	ld	ra,24(sp)
    800041dc:	6442                	ld	s0,16(sp)
    800041de:	64a2                	ld	s1,8(sp)
    800041e0:	6902                	ld	s2,0(sp)
    800041e2:	6105                	addi	sp,sp,32
    800041e4:	8082                	ret

00000000800041e6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041e6:	7139                	addi	sp,sp,-64
    800041e8:	fc06                	sd	ra,56(sp)
    800041ea:	f822                	sd	s0,48(sp)
    800041ec:	f426                	sd	s1,40(sp)
    800041ee:	f04a                	sd	s2,32(sp)
    800041f0:	ec4e                	sd	s3,24(sp)
    800041f2:	e852                	sd	s4,16(sp)
    800041f4:	e456                	sd	s5,8(sp)
    800041f6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041f8:	0001d917          	auipc	s2,0x1d
    800041fc:	71090913          	addi	s2,s2,1808 # 80021908 <log>
    80004200:	854a                	mv	a0,s2
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	a60080e7          	jalr	-1440(ra) # 80000c62 <acquire>
  log.outstanding -= 1;
    8000420a:	02092783          	lw	a5,32(s2)
    8000420e:	37fd                	addiw	a5,a5,-1
    80004210:	0007849b          	sext.w	s1,a5
    80004214:	02f92023          	sw	a5,32(s2)
  if(log.committing)
    80004218:	02492783          	lw	a5,36(s2)
    8000421c:	eba1                	bnez	a5,8000426c <end_op+0x86>
    panic("log.committing");
  if(log.outstanding == 0){
    8000421e:	ecb9                	bnez	s1,8000427c <end_op+0x96>
    do_commit = 1;
    log.committing = 1;
    80004220:	0001d917          	auipc	s2,0x1d
    80004224:	6e890913          	addi	s2,s2,1768 # 80021908 <log>
    80004228:	4785                	li	a5,1
    8000422a:	02f92223          	sw	a5,36(s2)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000422e:	854a                	mv	a0,s2
    80004230:	ffffd097          	auipc	ra,0xffffd
    80004234:	ae6080e7          	jalr	-1306(ra) # 80000d16 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004238:	02c92783          	lw	a5,44(s2)
    8000423c:	06f04763          	bgtz	a5,800042aa <end_op+0xc4>
    acquire(&log.lock);
    80004240:	0001d497          	auipc	s1,0x1d
    80004244:	6c848493          	addi	s1,s1,1736 # 80021908 <log>
    80004248:	8526                	mv	a0,s1
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	a18080e7          	jalr	-1512(ra) # 80000c62 <acquire>
    log.committing = 0;
    80004252:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004256:	8526                	mv	a0,s1
    80004258:	ffffe097          	auipc	ra,0xffffe
    8000425c:	1d8080e7          	jalr	472(ra) # 80002430 <wakeup>
    release(&log.lock);
    80004260:	8526                	mv	a0,s1
    80004262:	ffffd097          	auipc	ra,0xffffd
    80004266:	ab4080e7          	jalr	-1356(ra) # 80000d16 <release>
}
    8000426a:	a03d                	j	80004298 <end_op+0xb2>
    panic("log.committing");
    8000426c:	00004517          	auipc	a0,0x4
    80004270:	33450513          	addi	a0,a0,820 # 800085a0 <syscalls+0x208>
    80004274:	ffffc097          	auipc	ra,0xffffc
    80004278:	300080e7          	jalr	768(ra) # 80000574 <panic>
    wakeup(&log);
    8000427c:	0001d497          	auipc	s1,0x1d
    80004280:	68c48493          	addi	s1,s1,1676 # 80021908 <log>
    80004284:	8526                	mv	a0,s1
    80004286:	ffffe097          	auipc	ra,0xffffe
    8000428a:	1aa080e7          	jalr	426(ra) # 80002430 <wakeup>
  release(&log.lock);
    8000428e:	8526                	mv	a0,s1
    80004290:	ffffd097          	auipc	ra,0xffffd
    80004294:	a86080e7          	jalr	-1402(ra) # 80000d16 <release>
}
    80004298:	70e2                	ld	ra,56(sp)
    8000429a:	7442                	ld	s0,48(sp)
    8000429c:	74a2                	ld	s1,40(sp)
    8000429e:	7902                	ld	s2,32(sp)
    800042a0:	69e2                	ld	s3,24(sp)
    800042a2:	6a42                	ld	s4,16(sp)
    800042a4:	6aa2                	ld	s5,8(sp)
    800042a6:	6121                	addi	sp,sp,64
    800042a8:	8082                	ret
    800042aa:	0001da17          	auipc	s4,0x1d
    800042ae:	68ea0a13          	addi	s4,s4,1678 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042b2:	0001d917          	auipc	s2,0x1d
    800042b6:	65690913          	addi	s2,s2,1622 # 80021908 <log>
    800042ba:	01892583          	lw	a1,24(s2)
    800042be:	9da5                	addw	a1,a1,s1
    800042c0:	2585                	addiw	a1,a1,1
    800042c2:	02892503          	lw	a0,40(s2)
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	c8c080e7          	jalr	-884(ra) # 80002f52 <bread>
    800042ce:	89aa                	mv	s3,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042d0:	000a2583          	lw	a1,0(s4)
    800042d4:	02892503          	lw	a0,40(s2)
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	c7a080e7          	jalr	-902(ra) # 80002f52 <bread>
    800042e0:	8aaa                	mv	s5,a0
    memmove(to->data, from->data, BSIZE);
    800042e2:	40000613          	li	a2,1024
    800042e6:	05850593          	addi	a1,a0,88
    800042ea:	05898513          	addi	a0,s3,88
    800042ee:	ffffd097          	auipc	ra,0xffffd
    800042f2:	adc080e7          	jalr	-1316(ra) # 80000dca <memmove>
    bwrite(to);  // write the log
    800042f6:	854e                	mv	a0,s3
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	d5e080e7          	jalr	-674(ra) # 80003056 <bwrite>
    brelse(from);
    80004300:	8556                	mv	a0,s5
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	d92080e7          	jalr	-622(ra) # 80003094 <brelse>
    brelse(to);
    8000430a:	854e                	mv	a0,s3
    8000430c:	fffff097          	auipc	ra,0xfffff
    80004310:	d88080e7          	jalr	-632(ra) # 80003094 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004314:	2485                	addiw	s1,s1,1
    80004316:	0a11                	addi	s4,s4,4
    80004318:	02c92783          	lw	a5,44(s2)
    8000431c:	f8f4cfe3          	blt	s1,a5,800042ba <end_op+0xd4>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004320:	00000097          	auipc	ra,0x0
    80004324:	c72080e7          	jalr	-910(ra) # 80003f92 <write_head>
    install_trans(); // Now install writes to home locations
    80004328:	00000097          	auipc	ra,0x0
    8000432c:	ce4080e7          	jalr	-796(ra) # 8000400c <install_trans>
    log.lh.n = 0;
    80004330:	0001d797          	auipc	a5,0x1d
    80004334:	6007a223          	sw	zero,1540(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004338:	00000097          	auipc	ra,0x0
    8000433c:	c5a080e7          	jalr	-934(ra) # 80003f92 <write_head>
    80004340:	b701                	j	80004240 <end_op+0x5a>

0000000080004342 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004342:	1101                	addi	sp,sp,-32
    80004344:	ec06                	sd	ra,24(sp)
    80004346:	e822                	sd	s0,16(sp)
    80004348:	e426                	sd	s1,8(sp)
    8000434a:	e04a                	sd	s2,0(sp)
    8000434c:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000434e:	0001d797          	auipc	a5,0x1d
    80004352:	5ba78793          	addi	a5,a5,1466 # 80021908 <log>
    80004356:	57d8                	lw	a4,44(a5)
    80004358:	47f5                	li	a5,29
    8000435a:	08e7c563          	blt	a5,a4,800043e4 <log_write+0xa2>
    8000435e:	892a                	mv	s2,a0
    80004360:	0001d797          	auipc	a5,0x1d
    80004364:	5a878793          	addi	a5,a5,1448 # 80021908 <log>
    80004368:	4fdc                	lw	a5,28(a5)
    8000436a:	37fd                	addiw	a5,a5,-1
    8000436c:	06f75c63          	ble	a5,a4,800043e4 <log_write+0xa2>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004370:	0001d797          	auipc	a5,0x1d
    80004374:	59878793          	addi	a5,a5,1432 # 80021908 <log>
    80004378:	539c                	lw	a5,32(a5)
    8000437a:	06f05d63          	blez	a5,800043f4 <log_write+0xb2>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000437e:	0001d497          	auipc	s1,0x1d
    80004382:	58a48493          	addi	s1,s1,1418 # 80021908 <log>
    80004386:	8526                	mv	a0,s1
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	8da080e7          	jalr	-1830(ra) # 80000c62 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004390:	54d0                	lw	a2,44(s1)
    80004392:	0ac05063          	blez	a2,80004432 <log_write+0xf0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004396:	00c92583          	lw	a1,12(s2)
    8000439a:	589c                	lw	a5,48(s1)
    8000439c:	0ab78363          	beq	a5,a1,80004442 <log_write+0x100>
    800043a0:	0001d717          	auipc	a4,0x1d
    800043a4:	59c70713          	addi	a4,a4,1436 # 8002193c <log+0x34>
  for (i = 0; i < log.lh.n; i++) {
    800043a8:	4781                	li	a5,0
    800043aa:	2785                	addiw	a5,a5,1
    800043ac:	04c78c63          	beq	a5,a2,80004404 <log_write+0xc2>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043b0:	4314                	lw	a3,0(a4)
    800043b2:	0711                	addi	a4,a4,4
    800043b4:	feb69be3          	bne	a3,a1,800043aa <log_write+0x68>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043b8:	07a1                	addi	a5,a5,8
    800043ba:	078a                	slli	a5,a5,0x2
    800043bc:	0001d717          	auipc	a4,0x1d
    800043c0:	54c70713          	addi	a4,a4,1356 # 80021908 <log>
    800043c4:	97ba                	add	a5,a5,a4
    800043c6:	cb8c                	sw	a1,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    log.lh.n++;
  }
  release(&log.lock);
    800043c8:	0001d517          	auipc	a0,0x1d
    800043cc:	54050513          	addi	a0,a0,1344 # 80021908 <log>
    800043d0:	ffffd097          	auipc	ra,0xffffd
    800043d4:	946080e7          	jalr	-1722(ra) # 80000d16 <release>
}
    800043d8:	60e2                	ld	ra,24(sp)
    800043da:	6442                	ld	s0,16(sp)
    800043dc:	64a2                	ld	s1,8(sp)
    800043de:	6902                	ld	s2,0(sp)
    800043e0:	6105                	addi	sp,sp,32
    800043e2:	8082                	ret
    panic("too big a transaction");
    800043e4:	00004517          	auipc	a0,0x4
    800043e8:	1cc50513          	addi	a0,a0,460 # 800085b0 <syscalls+0x218>
    800043ec:	ffffc097          	auipc	ra,0xffffc
    800043f0:	188080e7          	jalr	392(ra) # 80000574 <panic>
    panic("log_write outside of trans");
    800043f4:	00004517          	auipc	a0,0x4
    800043f8:	1d450513          	addi	a0,a0,468 # 800085c8 <syscalls+0x230>
    800043fc:	ffffc097          	auipc	ra,0xffffc
    80004400:	178080e7          	jalr	376(ra) # 80000574 <panic>
  log.lh.block[i] = b->blockno;
    80004404:	0621                	addi	a2,a2,8
    80004406:	060a                	slli	a2,a2,0x2
    80004408:	0001d797          	auipc	a5,0x1d
    8000440c:	50078793          	addi	a5,a5,1280 # 80021908 <log>
    80004410:	963e                	add	a2,a2,a5
    80004412:	00c92783          	lw	a5,12(s2)
    80004416:	ca1c                	sw	a5,16(a2)
    bpin(b);
    80004418:	854a                	mv	a0,s2
    8000441a:	fffff097          	auipc	ra,0xfffff
    8000441e:	d18080e7          	jalr	-744(ra) # 80003132 <bpin>
    log.lh.n++;
    80004422:	0001d717          	auipc	a4,0x1d
    80004426:	4e670713          	addi	a4,a4,1254 # 80021908 <log>
    8000442a:	575c                	lw	a5,44(a4)
    8000442c:	2785                	addiw	a5,a5,1
    8000442e:	d75c                	sw	a5,44(a4)
    80004430:	bf61                	j	800043c8 <log_write+0x86>
  log.lh.block[i] = b->blockno;
    80004432:	00c92783          	lw	a5,12(s2)
    80004436:	0001d717          	auipc	a4,0x1d
    8000443a:	50f72123          	sw	a5,1282(a4) # 80021938 <log+0x30>
  if (i == log.lh.n) {  // Add new block to log?
    8000443e:	f649                	bnez	a2,800043c8 <log_write+0x86>
    80004440:	bfe1                	j	80004418 <log_write+0xd6>
  for (i = 0; i < log.lh.n; i++) {
    80004442:	4781                	li	a5,0
    80004444:	bf95                	j	800043b8 <log_write+0x76>

0000000080004446 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
    80004452:	84aa                	mv	s1,a0
    80004454:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004456:	00004597          	auipc	a1,0x4
    8000445a:	19258593          	addi	a1,a1,402 # 800085e8 <syscalls+0x250>
    8000445e:	0521                	addi	a0,a0,8
    80004460:	ffffc097          	auipc	ra,0xffffc
    80004464:	772080e7          	jalr	1906(ra) # 80000bd2 <initlock>
  lk->name = name;
    80004468:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000446c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004470:	0204a423          	sw	zero,40(s1)
}
    80004474:	60e2                	ld	ra,24(sp)
    80004476:	6442                	ld	s0,16(sp)
    80004478:	64a2                	ld	s1,8(sp)
    8000447a:	6902                	ld	s2,0(sp)
    8000447c:	6105                	addi	sp,sp,32
    8000447e:	8082                	ret

0000000080004480 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004480:	1101                	addi	sp,sp,-32
    80004482:	ec06                	sd	ra,24(sp)
    80004484:	e822                	sd	s0,16(sp)
    80004486:	e426                	sd	s1,8(sp)
    80004488:	e04a                	sd	s2,0(sp)
    8000448a:	1000                	addi	s0,sp,32
    8000448c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000448e:	00850913          	addi	s2,a0,8
    80004492:	854a                	mv	a0,s2
    80004494:	ffffc097          	auipc	ra,0xffffc
    80004498:	7ce080e7          	jalr	1998(ra) # 80000c62 <acquire>
  while (lk->locked) {
    8000449c:	409c                	lw	a5,0(s1)
    8000449e:	cb89                	beqz	a5,800044b0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044a0:	85ca                	mv	a1,s2
    800044a2:	8526                	mv	a0,s1
    800044a4:	ffffe097          	auipc	ra,0xffffe
    800044a8:	e06080e7          	jalr	-506(ra) # 800022aa <sleep>
  while (lk->locked) {
    800044ac:	409c                	lw	a5,0(s1)
    800044ae:	fbed                	bnez	a5,800044a0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044b0:	4785                	li	a5,1
    800044b2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044b4:	ffffd097          	auipc	ra,0xffffd
    800044b8:	5dc080e7          	jalr	1500(ra) # 80001a90 <myproc>
    800044bc:	5d1c                	lw	a5,56(a0)
    800044be:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044c0:	854a                	mv	a0,s2
    800044c2:	ffffd097          	auipc	ra,0xffffd
    800044c6:	854080e7          	jalr	-1964(ra) # 80000d16 <release>
}
    800044ca:	60e2                	ld	ra,24(sp)
    800044cc:	6442                	ld	s0,16(sp)
    800044ce:	64a2                	ld	s1,8(sp)
    800044d0:	6902                	ld	s2,0(sp)
    800044d2:	6105                	addi	sp,sp,32
    800044d4:	8082                	ret

00000000800044d6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044d6:	1101                	addi	sp,sp,-32
    800044d8:	ec06                	sd	ra,24(sp)
    800044da:	e822                	sd	s0,16(sp)
    800044dc:	e426                	sd	s1,8(sp)
    800044de:	e04a                	sd	s2,0(sp)
    800044e0:	1000                	addi	s0,sp,32
    800044e2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e4:	00850913          	addi	s2,a0,8
    800044e8:	854a                	mv	a0,s2
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	778080e7          	jalr	1912(ra) # 80000c62 <acquire>
  lk->locked = 0;
    800044f2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044f6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044fa:	8526                	mv	a0,s1
    800044fc:	ffffe097          	auipc	ra,0xffffe
    80004500:	f34080e7          	jalr	-204(ra) # 80002430 <wakeup>
  release(&lk->lk);
    80004504:	854a                	mv	a0,s2
    80004506:	ffffd097          	auipc	ra,0xffffd
    8000450a:	810080e7          	jalr	-2032(ra) # 80000d16 <release>
}
    8000450e:	60e2                	ld	ra,24(sp)
    80004510:	6442                	ld	s0,16(sp)
    80004512:	64a2                	ld	s1,8(sp)
    80004514:	6902                	ld	s2,0(sp)
    80004516:	6105                	addi	sp,sp,32
    80004518:	8082                	ret

000000008000451a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000451a:	7179                	addi	sp,sp,-48
    8000451c:	f406                	sd	ra,40(sp)
    8000451e:	f022                	sd	s0,32(sp)
    80004520:	ec26                	sd	s1,24(sp)
    80004522:	e84a                	sd	s2,16(sp)
    80004524:	e44e                	sd	s3,8(sp)
    80004526:	1800                	addi	s0,sp,48
    80004528:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000452a:	00850913          	addi	s2,a0,8
    8000452e:	854a                	mv	a0,s2
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	732080e7          	jalr	1842(ra) # 80000c62 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004538:	409c                	lw	a5,0(s1)
    8000453a:	ef99                	bnez	a5,80004558 <holdingsleep+0x3e>
    8000453c:	4481                	li	s1,0
  release(&lk->lk);
    8000453e:	854a                	mv	a0,s2
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	7d6080e7          	jalr	2006(ra) # 80000d16 <release>
  return r;
}
    80004548:	8526                	mv	a0,s1
    8000454a:	70a2                	ld	ra,40(sp)
    8000454c:	7402                	ld	s0,32(sp)
    8000454e:	64e2                	ld	s1,24(sp)
    80004550:	6942                	ld	s2,16(sp)
    80004552:	69a2                	ld	s3,8(sp)
    80004554:	6145                	addi	sp,sp,48
    80004556:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004558:	0284a983          	lw	s3,40(s1)
    8000455c:	ffffd097          	auipc	ra,0xffffd
    80004560:	534080e7          	jalr	1332(ra) # 80001a90 <myproc>
    80004564:	5d04                	lw	s1,56(a0)
    80004566:	413484b3          	sub	s1,s1,s3
    8000456a:	0014b493          	seqz	s1,s1
    8000456e:	bfc1                	j	8000453e <holdingsleep+0x24>

0000000080004570 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004570:	1141                	addi	sp,sp,-16
    80004572:	e406                	sd	ra,8(sp)
    80004574:	e022                	sd	s0,0(sp)
    80004576:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004578:	00004597          	auipc	a1,0x4
    8000457c:	08058593          	addi	a1,a1,128 # 800085f8 <syscalls+0x260>
    80004580:	0001d517          	auipc	a0,0x1d
    80004584:	4d050513          	addi	a0,a0,1232 # 80021a50 <ftable>
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	64a080e7          	jalr	1610(ra) # 80000bd2 <initlock>
}
    80004590:	60a2                	ld	ra,8(sp)
    80004592:	6402                	ld	s0,0(sp)
    80004594:	0141                	addi	sp,sp,16
    80004596:	8082                	ret

0000000080004598 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004598:	1101                	addi	sp,sp,-32
    8000459a:	ec06                	sd	ra,24(sp)
    8000459c:	e822                	sd	s0,16(sp)
    8000459e:	e426                	sd	s1,8(sp)
    800045a0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045a2:	0001d517          	auipc	a0,0x1d
    800045a6:	4ae50513          	addi	a0,a0,1198 # 80021a50 <ftable>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	6b8080e7          	jalr	1720(ra) # 80000c62 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
    800045b2:	0001d797          	auipc	a5,0x1d
    800045b6:	49e78793          	addi	a5,a5,1182 # 80021a50 <ftable>
    800045ba:	4fdc                	lw	a5,28(a5)
    800045bc:	cb8d                	beqz	a5,800045ee <filealloc+0x56>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045be:	0001d497          	auipc	s1,0x1d
    800045c2:	4d248493          	addi	s1,s1,1234 # 80021a90 <ftable+0x40>
    800045c6:	0001e717          	auipc	a4,0x1e
    800045ca:	44270713          	addi	a4,a4,1090 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    800045ce:	40dc                	lw	a5,4(s1)
    800045d0:	c39d                	beqz	a5,800045f6 <filealloc+0x5e>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045d2:	02848493          	addi	s1,s1,40
    800045d6:	fee49ce3          	bne	s1,a4,800045ce <filealloc+0x36>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045da:	0001d517          	auipc	a0,0x1d
    800045de:	47650513          	addi	a0,a0,1142 # 80021a50 <ftable>
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	734080e7          	jalr	1844(ra) # 80000d16 <release>
  return 0;
    800045ea:	4481                	li	s1,0
    800045ec:	a839                	j	8000460a <filealloc+0x72>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ee:	0001d497          	auipc	s1,0x1d
    800045f2:	47a48493          	addi	s1,s1,1146 # 80021a68 <ftable+0x18>
      f->ref = 1;
    800045f6:	4785                	li	a5,1
    800045f8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045fa:	0001d517          	auipc	a0,0x1d
    800045fe:	45650513          	addi	a0,a0,1110 # 80021a50 <ftable>
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	714080e7          	jalr	1812(ra) # 80000d16 <release>
}
    8000460a:	8526                	mv	a0,s1
    8000460c:	60e2                	ld	ra,24(sp)
    8000460e:	6442                	ld	s0,16(sp)
    80004610:	64a2                	ld	s1,8(sp)
    80004612:	6105                	addi	sp,sp,32
    80004614:	8082                	ret

0000000080004616 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004616:	1101                	addi	sp,sp,-32
    80004618:	ec06                	sd	ra,24(sp)
    8000461a:	e822                	sd	s0,16(sp)
    8000461c:	e426                	sd	s1,8(sp)
    8000461e:	1000                	addi	s0,sp,32
    80004620:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004622:	0001d517          	auipc	a0,0x1d
    80004626:	42e50513          	addi	a0,a0,1070 # 80021a50 <ftable>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	638080e7          	jalr	1592(ra) # 80000c62 <acquire>
  if(f->ref < 1)
    80004632:	40dc                	lw	a5,4(s1)
    80004634:	02f05263          	blez	a5,80004658 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004638:	2785                	addiw	a5,a5,1
    8000463a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000463c:	0001d517          	auipc	a0,0x1d
    80004640:	41450513          	addi	a0,a0,1044 # 80021a50 <ftable>
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	6d2080e7          	jalr	1746(ra) # 80000d16 <release>
  return f;
}
    8000464c:	8526                	mv	a0,s1
    8000464e:	60e2                	ld	ra,24(sp)
    80004650:	6442                	ld	s0,16(sp)
    80004652:	64a2                	ld	s1,8(sp)
    80004654:	6105                	addi	sp,sp,32
    80004656:	8082                	ret
    panic("filedup");
    80004658:	00004517          	auipc	a0,0x4
    8000465c:	fa850513          	addi	a0,a0,-88 # 80008600 <syscalls+0x268>
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	f14080e7          	jalr	-236(ra) # 80000574 <panic>

0000000080004668 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004668:	7139                	addi	sp,sp,-64
    8000466a:	fc06                	sd	ra,56(sp)
    8000466c:	f822                	sd	s0,48(sp)
    8000466e:	f426                	sd	s1,40(sp)
    80004670:	f04a                	sd	s2,32(sp)
    80004672:	ec4e                	sd	s3,24(sp)
    80004674:	e852                	sd	s4,16(sp)
    80004676:	e456                	sd	s5,8(sp)
    80004678:	0080                	addi	s0,sp,64
    8000467a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000467c:	0001d517          	auipc	a0,0x1d
    80004680:	3d450513          	addi	a0,a0,980 # 80021a50 <ftable>
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	5de080e7          	jalr	1502(ra) # 80000c62 <acquire>
  if(f->ref < 1)
    8000468c:	40dc                	lw	a5,4(s1)
    8000468e:	06f05163          	blez	a5,800046f0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004692:	37fd                	addiw	a5,a5,-1
    80004694:	0007871b          	sext.w	a4,a5
    80004698:	c0dc                	sw	a5,4(s1)
    8000469a:	06e04363          	bgtz	a4,80004700 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000469e:	0004a903          	lw	s2,0(s1)
    800046a2:	0094ca83          	lbu	s5,9(s1)
    800046a6:	0104ba03          	ld	s4,16(s1)
    800046aa:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046ae:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046b2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046b6:	0001d517          	auipc	a0,0x1d
    800046ba:	39a50513          	addi	a0,a0,922 # 80021a50 <ftable>
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	658080e7          	jalr	1624(ra) # 80000d16 <release>

  if(ff.type == FD_PIPE){
    800046c6:	4785                	li	a5,1
    800046c8:	04f90d63          	beq	s2,a5,80004722 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046cc:	3979                	addiw	s2,s2,-2
    800046ce:	4785                	li	a5,1
    800046d0:	0527e063          	bltu	a5,s2,80004710 <fileclose+0xa8>
    begin_op();
    800046d4:	00000097          	auipc	ra,0x0
    800046d8:	a92080e7          	jalr	-1390(ra) # 80004166 <begin_op>
    iput(ff.ip);
    800046dc:	854e                	mv	a0,s3
    800046de:	fffff097          	auipc	ra,0xfffff
    800046e2:	278080e7          	jalr	632(ra) # 80003956 <iput>
    end_op();
    800046e6:	00000097          	auipc	ra,0x0
    800046ea:	b00080e7          	jalr	-1280(ra) # 800041e6 <end_op>
    800046ee:	a00d                	j	80004710 <fileclose+0xa8>
    panic("fileclose");
    800046f0:	00004517          	auipc	a0,0x4
    800046f4:	f1850513          	addi	a0,a0,-232 # 80008608 <syscalls+0x270>
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	e7c080e7          	jalr	-388(ra) # 80000574 <panic>
    release(&ftable.lock);
    80004700:	0001d517          	auipc	a0,0x1d
    80004704:	35050513          	addi	a0,a0,848 # 80021a50 <ftable>
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	60e080e7          	jalr	1550(ra) # 80000d16 <release>
  }
}
    80004710:	70e2                	ld	ra,56(sp)
    80004712:	7442                	ld	s0,48(sp)
    80004714:	74a2                	ld	s1,40(sp)
    80004716:	7902                	ld	s2,32(sp)
    80004718:	69e2                	ld	s3,24(sp)
    8000471a:	6a42                	ld	s4,16(sp)
    8000471c:	6aa2                	ld	s5,8(sp)
    8000471e:	6121                	addi	sp,sp,64
    80004720:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004722:	85d6                	mv	a1,s5
    80004724:	8552                	mv	a0,s4
    80004726:	00000097          	auipc	ra,0x0
    8000472a:	364080e7          	jalr	868(ra) # 80004a8a <pipeclose>
    8000472e:	b7cd                	j	80004710 <fileclose+0xa8>

0000000080004730 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004730:	715d                	addi	sp,sp,-80
    80004732:	e486                	sd	ra,72(sp)
    80004734:	e0a2                	sd	s0,64(sp)
    80004736:	fc26                	sd	s1,56(sp)
    80004738:	f84a                	sd	s2,48(sp)
    8000473a:	f44e                	sd	s3,40(sp)
    8000473c:	0880                	addi	s0,sp,80
    8000473e:	84aa                	mv	s1,a0
    80004740:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004742:	ffffd097          	auipc	ra,0xffffd
    80004746:	34e080e7          	jalr	846(ra) # 80001a90 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000474a:	409c                	lw	a5,0(s1)
    8000474c:	37f9                	addiw	a5,a5,-2
    8000474e:	4705                	li	a4,1
    80004750:	04f76763          	bltu	a4,a5,8000479e <filestat+0x6e>
    80004754:	892a                	mv	s2,a0
    ilock(f->ip);
    80004756:	6c88                	ld	a0,24(s1)
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	042080e7          	jalr	66(ra) # 8000379a <ilock>
    stati(f->ip, &st);
    80004760:	fb840593          	addi	a1,s0,-72
    80004764:	6c88                	ld	a0,24(s1)
    80004766:	fffff097          	auipc	ra,0xfffff
    8000476a:	2c0080e7          	jalr	704(ra) # 80003a26 <stati>
    iunlock(f->ip);
    8000476e:	6c88                	ld	a0,24(s1)
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	0ee080e7          	jalr	238(ra) # 8000385e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004778:	46e1                	li	a3,24
    8000477a:	fb840613          	addi	a2,s0,-72
    8000477e:	85ce                	mv	a1,s3
    80004780:	05093503          	ld	a0,80(s2)
    80004784:	ffffd097          	auipc	ra,0xffffd
    80004788:	fe8080e7          	jalr	-24(ra) # 8000176c <copyout>
    8000478c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004790:	60a6                	ld	ra,72(sp)
    80004792:	6406                	ld	s0,64(sp)
    80004794:	74e2                	ld	s1,56(sp)
    80004796:	7942                	ld	s2,48(sp)
    80004798:	79a2                	ld	s3,40(sp)
    8000479a:	6161                	addi	sp,sp,80
    8000479c:	8082                	ret
  return -1;
    8000479e:	557d                	li	a0,-1
    800047a0:	bfc5                	j	80004790 <filestat+0x60>

00000000800047a2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047a2:	7179                	addi	sp,sp,-48
    800047a4:	f406                	sd	ra,40(sp)
    800047a6:	f022                	sd	s0,32(sp)
    800047a8:	ec26                	sd	s1,24(sp)
    800047aa:	e84a                	sd	s2,16(sp)
    800047ac:	e44e                	sd	s3,8(sp)
    800047ae:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047b0:	00854783          	lbu	a5,8(a0)
    800047b4:	c3d5                	beqz	a5,80004858 <fileread+0xb6>
    800047b6:	89b2                	mv	s3,a2
    800047b8:	892e                	mv	s2,a1
    800047ba:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    800047bc:	411c                	lw	a5,0(a0)
    800047be:	4705                	li	a4,1
    800047c0:	04e78963          	beq	a5,a4,80004812 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047c4:	470d                	li	a4,3
    800047c6:	04e78d63          	beq	a5,a4,80004820 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ca:	4709                	li	a4,2
    800047cc:	06e79e63          	bne	a5,a4,80004848 <fileread+0xa6>
    ilock(f->ip);
    800047d0:	6d08                	ld	a0,24(a0)
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	fc8080e7          	jalr	-56(ra) # 8000379a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047da:	874e                	mv	a4,s3
    800047dc:	5094                	lw	a3,32(s1)
    800047de:	864a                	mv	a2,s2
    800047e0:	4585                	li	a1,1
    800047e2:	6c88                	ld	a0,24(s1)
    800047e4:	fffff097          	auipc	ra,0xfffff
    800047e8:	26c080e7          	jalr	620(ra) # 80003a50 <readi>
    800047ec:	892a                	mv	s2,a0
    800047ee:	00a05563          	blez	a0,800047f8 <fileread+0x56>
      f->off += r;
    800047f2:	509c                	lw	a5,32(s1)
    800047f4:	9fa9                	addw	a5,a5,a0
    800047f6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047f8:	6c88                	ld	a0,24(s1)
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	064080e7          	jalr	100(ra) # 8000385e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004802:	854a                	mv	a0,s2
    80004804:	70a2                	ld	ra,40(sp)
    80004806:	7402                	ld	s0,32(sp)
    80004808:	64e2                	ld	s1,24(sp)
    8000480a:	6942                	ld	s2,16(sp)
    8000480c:	69a2                	ld	s3,8(sp)
    8000480e:	6145                	addi	sp,sp,48
    80004810:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004812:	6908                	ld	a0,16(a0)
    80004814:	00000097          	auipc	ra,0x0
    80004818:	416080e7          	jalr	1046(ra) # 80004c2a <piperead>
    8000481c:	892a                	mv	s2,a0
    8000481e:	b7d5                	j	80004802 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004820:	02451783          	lh	a5,36(a0)
    80004824:	03079693          	slli	a3,a5,0x30
    80004828:	92c1                	srli	a3,a3,0x30
    8000482a:	4725                	li	a4,9
    8000482c:	02d76863          	bltu	a4,a3,8000485c <fileread+0xba>
    80004830:	0792                	slli	a5,a5,0x4
    80004832:	0001d717          	auipc	a4,0x1d
    80004836:	17e70713          	addi	a4,a4,382 # 800219b0 <devsw>
    8000483a:	97ba                	add	a5,a5,a4
    8000483c:	639c                	ld	a5,0(a5)
    8000483e:	c38d                	beqz	a5,80004860 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004840:	4505                	li	a0,1
    80004842:	9782                	jalr	a5
    80004844:	892a                	mv	s2,a0
    80004846:	bf75                	j	80004802 <fileread+0x60>
    panic("fileread");
    80004848:	00004517          	auipc	a0,0x4
    8000484c:	dd050513          	addi	a0,a0,-560 # 80008618 <syscalls+0x280>
    80004850:	ffffc097          	auipc	ra,0xffffc
    80004854:	d24080e7          	jalr	-732(ra) # 80000574 <panic>
    return -1;
    80004858:	597d                	li	s2,-1
    8000485a:	b765                	j	80004802 <fileread+0x60>
      return -1;
    8000485c:	597d                	li	s2,-1
    8000485e:	b755                	j	80004802 <fileread+0x60>
    80004860:	597d                	li	s2,-1
    80004862:	b745                	j	80004802 <fileread+0x60>

0000000080004864 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004864:	00954783          	lbu	a5,9(a0)
    80004868:	12078e63          	beqz	a5,800049a4 <filewrite+0x140>
{
    8000486c:	715d                	addi	sp,sp,-80
    8000486e:	e486                	sd	ra,72(sp)
    80004870:	e0a2                	sd	s0,64(sp)
    80004872:	fc26                	sd	s1,56(sp)
    80004874:	f84a                	sd	s2,48(sp)
    80004876:	f44e                	sd	s3,40(sp)
    80004878:	f052                	sd	s4,32(sp)
    8000487a:	ec56                	sd	s5,24(sp)
    8000487c:	e85a                	sd	s6,16(sp)
    8000487e:	e45e                	sd	s7,8(sp)
    80004880:	e062                	sd	s8,0(sp)
    80004882:	0880                	addi	s0,sp,80
    80004884:	8ab2                	mv	s5,a2
    80004886:	8b2e                	mv	s6,a1
    80004888:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    8000488a:	411c                	lw	a5,0(a0)
    8000488c:	4705                	li	a4,1
    8000488e:	02e78263          	beq	a5,a4,800048b2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004892:	470d                	li	a4,3
    80004894:	02e78563          	beq	a5,a4,800048be <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004898:	4709                	li	a4,2
    8000489a:	0ee79d63          	bne	a5,a4,80004994 <filewrite+0x130>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000489e:	0ec05763          	blez	a2,8000498c <filewrite+0x128>
    int i = 0;
    800048a2:	4901                	li	s2,0
    800048a4:	6b85                	lui	s7,0x1
    800048a6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800048aa:	6c05                	lui	s8,0x1
    800048ac:	c00c0c1b          	addiw	s8,s8,-1024
    800048b0:	a061                	j	80004938 <filewrite+0xd4>
    ret = pipewrite(f->pipe, addr, n);
    800048b2:	6908                	ld	a0,16(a0)
    800048b4:	00000097          	auipc	ra,0x0
    800048b8:	246080e7          	jalr	582(ra) # 80004afa <pipewrite>
    800048bc:	a065                	j	80004964 <filewrite+0x100>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048be:	02451783          	lh	a5,36(a0)
    800048c2:	03079693          	slli	a3,a5,0x30
    800048c6:	92c1                	srli	a3,a3,0x30
    800048c8:	4725                	li	a4,9
    800048ca:	0cd76f63          	bltu	a4,a3,800049a8 <filewrite+0x144>
    800048ce:	0792                	slli	a5,a5,0x4
    800048d0:	0001d717          	auipc	a4,0x1d
    800048d4:	0e070713          	addi	a4,a4,224 # 800219b0 <devsw>
    800048d8:	97ba                	add	a5,a5,a4
    800048da:	679c                	ld	a5,8(a5)
    800048dc:	cbe1                	beqz	a5,800049ac <filewrite+0x148>
    ret = devsw[f->major].write(1, addr, n);
    800048de:	4505                	li	a0,1
    800048e0:	9782                	jalr	a5
    800048e2:	a049                	j	80004964 <filewrite+0x100>
    800048e4:	00098a1b          	sext.w	s4,s3
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048e8:	00000097          	auipc	ra,0x0
    800048ec:	87e080e7          	jalr	-1922(ra) # 80004166 <begin_op>
      ilock(f->ip);
    800048f0:	6c88                	ld	a0,24(s1)
    800048f2:	fffff097          	auipc	ra,0xfffff
    800048f6:	ea8080e7          	jalr	-344(ra) # 8000379a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048fa:	8752                	mv	a4,s4
    800048fc:	5094                	lw	a3,32(s1)
    800048fe:	01690633          	add	a2,s2,s6
    80004902:	4585                	li	a1,1
    80004904:	6c88                	ld	a0,24(s1)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	242080e7          	jalr	578(ra) # 80003b48 <writei>
    8000490e:	89aa                	mv	s3,a0
    80004910:	02a05c63          	blez	a0,80004948 <filewrite+0xe4>
        f->off += r;
    80004914:	509c                	lw	a5,32(s1)
    80004916:	9fa9                	addw	a5,a5,a0
    80004918:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    8000491a:	6c88                	ld	a0,24(s1)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	f42080e7          	jalr	-190(ra) # 8000385e <iunlock>
      end_op();
    80004924:	00000097          	auipc	ra,0x0
    80004928:	8c2080e7          	jalr	-1854(ra) # 800041e6 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000492c:	05499863          	bne	s3,s4,8000497c <filewrite+0x118>
        panic("short filewrite");
      i += r;
    80004930:	012a093b          	addw	s2,s4,s2
    while(i < n){
    80004934:	03595563          	ble	s5,s2,8000495e <filewrite+0xfa>
      int n1 = n - i;
    80004938:	412a87bb          	subw	a5,s5,s2
      if(n1 > max)
    8000493c:	89be                	mv	s3,a5
    8000493e:	2781                	sext.w	a5,a5
    80004940:	fafbd2e3          	ble	a5,s7,800048e4 <filewrite+0x80>
    80004944:	89e2                	mv	s3,s8
    80004946:	bf79                	j	800048e4 <filewrite+0x80>
      iunlock(f->ip);
    80004948:	6c88                	ld	a0,24(s1)
    8000494a:	fffff097          	auipc	ra,0xfffff
    8000494e:	f14080e7          	jalr	-236(ra) # 8000385e <iunlock>
      end_op();
    80004952:	00000097          	auipc	ra,0x0
    80004956:	894080e7          	jalr	-1900(ra) # 800041e6 <end_op>
      if(r < 0)
    8000495a:	fc09d9e3          	bgez	s3,8000492c <filewrite+0xc8>
    }
    ret = (i == n ? n : -1);
    8000495e:	8556                	mv	a0,s5
    80004960:	032a9863          	bne	s5,s2,80004990 <filewrite+0x12c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004964:	60a6                	ld	ra,72(sp)
    80004966:	6406                	ld	s0,64(sp)
    80004968:	74e2                	ld	s1,56(sp)
    8000496a:	7942                	ld	s2,48(sp)
    8000496c:	79a2                	ld	s3,40(sp)
    8000496e:	7a02                	ld	s4,32(sp)
    80004970:	6ae2                	ld	s5,24(sp)
    80004972:	6b42                	ld	s6,16(sp)
    80004974:	6ba2                	ld	s7,8(sp)
    80004976:	6c02                	ld	s8,0(sp)
    80004978:	6161                	addi	sp,sp,80
    8000497a:	8082                	ret
        panic("short filewrite");
    8000497c:	00004517          	auipc	a0,0x4
    80004980:	cac50513          	addi	a0,a0,-852 # 80008628 <syscalls+0x290>
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	bf0080e7          	jalr	-1040(ra) # 80000574 <panic>
    int i = 0;
    8000498c:	4901                	li	s2,0
    8000498e:	bfc1                	j	8000495e <filewrite+0xfa>
    ret = (i == n ? n : -1);
    80004990:	557d                	li	a0,-1
    80004992:	bfc9                	j	80004964 <filewrite+0x100>
    panic("filewrite");
    80004994:	00004517          	auipc	a0,0x4
    80004998:	ca450513          	addi	a0,a0,-860 # 80008638 <syscalls+0x2a0>
    8000499c:	ffffc097          	auipc	ra,0xffffc
    800049a0:	bd8080e7          	jalr	-1064(ra) # 80000574 <panic>
    return -1;
    800049a4:	557d                	li	a0,-1
}
    800049a6:	8082                	ret
      return -1;
    800049a8:	557d                	li	a0,-1
    800049aa:	bf6d                	j	80004964 <filewrite+0x100>
    800049ac:	557d                	li	a0,-1
    800049ae:	bf5d                	j	80004964 <filewrite+0x100>

00000000800049b0 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049b0:	7179                	addi	sp,sp,-48
    800049b2:	f406                	sd	ra,40(sp)
    800049b4:	f022                	sd	s0,32(sp)
    800049b6:	ec26                	sd	s1,24(sp)
    800049b8:	e84a                	sd	s2,16(sp)
    800049ba:	e44e                	sd	s3,8(sp)
    800049bc:	e052                	sd	s4,0(sp)
    800049be:	1800                	addi	s0,sp,48
    800049c0:	84aa                	mv	s1,a0
    800049c2:	892e                	mv	s2,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049c4:	0005b023          	sd	zero,0(a1)
    800049c8:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	bcc080e7          	jalr	-1076(ra) # 80004598 <filealloc>
    800049d4:	e088                	sd	a0,0(s1)
    800049d6:	c551                	beqz	a0,80004a62 <pipealloc+0xb2>
    800049d8:	00000097          	auipc	ra,0x0
    800049dc:	bc0080e7          	jalr	-1088(ra) # 80004598 <filealloc>
    800049e0:	00a93023          	sd	a0,0(s2)
    800049e4:	c92d                	beqz	a0,80004a56 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	18c080e7          	jalr	396(ra) # 80000b72 <kalloc>
    800049ee:	89aa                	mv	s3,a0
    800049f0:	c125                	beqz	a0,80004a50 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049f2:	4a05                	li	s4,1
    800049f4:	23452023          	sw	s4,544(a0)
  pi->writeopen = 1;
    800049f8:	23452223          	sw	s4,548(a0)
  pi->nwrite = 0;
    800049fc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a00:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a04:	00004597          	auipc	a1,0x4
    80004a08:	c4458593          	addi	a1,a1,-956 # 80008648 <syscalls+0x2b0>
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	1c6080e7          	jalr	454(ra) # 80000bd2 <initlock>
  (*f0)->type = FD_PIPE;
    80004a14:	609c                	ld	a5,0(s1)
    80004a16:	0147a023          	sw	s4,0(a5)
  (*f0)->readable = 1;
    80004a1a:	609c                	ld	a5,0(s1)
    80004a1c:	01478423          	sb	s4,8(a5)
  (*f0)->writable = 0;
    80004a20:	609c                	ld	a5,0(s1)
    80004a22:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a26:	609c                	ld	a5,0(s1)
    80004a28:	0137b823          	sd	s3,16(a5)
  (*f1)->type = FD_PIPE;
    80004a2c:	00093783          	ld	a5,0(s2)
    80004a30:	0147a023          	sw	s4,0(a5)
  (*f1)->readable = 0;
    80004a34:	00093783          	ld	a5,0(s2)
    80004a38:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a3c:	00093783          	ld	a5,0(s2)
    80004a40:	014784a3          	sb	s4,9(a5)
  (*f1)->pipe = pi;
    80004a44:	00093783          	ld	a5,0(s2)
    80004a48:	0137b823          	sd	s3,16(a5)
  return 0;
    80004a4c:	4501                	li	a0,0
    80004a4e:	a025                	j	80004a76 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a50:	6088                	ld	a0,0(s1)
    80004a52:	e501                	bnez	a0,80004a5a <pipealloc+0xaa>
    80004a54:	a039                	j	80004a62 <pipealloc+0xb2>
    80004a56:	6088                	ld	a0,0(s1)
    80004a58:	c51d                	beqz	a0,80004a86 <pipealloc+0xd6>
    fileclose(*f0);
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	c0e080e7          	jalr	-1010(ra) # 80004668 <fileclose>
  if(*f1)
    80004a62:	00093783          	ld	a5,0(s2)
    fileclose(*f1);
  return -1;
    80004a66:	557d                	li	a0,-1
  if(*f1)
    80004a68:	c799                	beqz	a5,80004a76 <pipealloc+0xc6>
    fileclose(*f1);
    80004a6a:	853e                	mv	a0,a5
    80004a6c:	00000097          	auipc	ra,0x0
    80004a70:	bfc080e7          	jalr	-1028(ra) # 80004668 <fileclose>
  return -1;
    80004a74:	557d                	li	a0,-1
}
    80004a76:	70a2                	ld	ra,40(sp)
    80004a78:	7402                	ld	s0,32(sp)
    80004a7a:	64e2                	ld	s1,24(sp)
    80004a7c:	6942                	ld	s2,16(sp)
    80004a7e:	69a2                	ld	s3,8(sp)
    80004a80:	6a02                	ld	s4,0(sp)
    80004a82:	6145                	addi	sp,sp,48
    80004a84:	8082                	ret
  return -1;
    80004a86:	557d                	li	a0,-1
    80004a88:	b7fd                	j	80004a76 <pipealloc+0xc6>

0000000080004a8a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a8a:	1101                	addi	sp,sp,-32
    80004a8c:	ec06                	sd	ra,24(sp)
    80004a8e:	e822                	sd	s0,16(sp)
    80004a90:	e426                	sd	s1,8(sp)
    80004a92:	e04a                	sd	s2,0(sp)
    80004a94:	1000                	addi	s0,sp,32
    80004a96:	84aa                	mv	s1,a0
    80004a98:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a9a:	ffffc097          	auipc	ra,0xffffc
    80004a9e:	1c8080e7          	jalr	456(ra) # 80000c62 <acquire>
  if(writable){
    80004aa2:	02090d63          	beqz	s2,80004adc <pipeclose+0x52>
    pi->writeopen = 0;
    80004aa6:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004aaa:	21848513          	addi	a0,s1,536
    80004aae:	ffffe097          	auipc	ra,0xffffe
    80004ab2:	982080e7          	jalr	-1662(ra) # 80002430 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ab6:	2204b783          	ld	a5,544(s1)
    80004aba:	eb95                	bnez	a5,80004aee <pipeclose+0x64>
    release(&pi->lock);
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	258080e7          	jalr	600(ra) # 80000d16 <release>
    kfree((char*)pi);
    80004ac6:	8526                	mv	a0,s1
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	faa080e7          	jalr	-86(ra) # 80000a72 <kfree>
  } else
    release(&pi->lock);
}
    80004ad0:	60e2                	ld	ra,24(sp)
    80004ad2:	6442                	ld	s0,16(sp)
    80004ad4:	64a2                	ld	s1,8(sp)
    80004ad6:	6902                	ld	s2,0(sp)
    80004ad8:	6105                	addi	sp,sp,32
    80004ada:	8082                	ret
    pi->readopen = 0;
    80004adc:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ae0:	21c48513          	addi	a0,s1,540
    80004ae4:	ffffe097          	auipc	ra,0xffffe
    80004ae8:	94c080e7          	jalr	-1716(ra) # 80002430 <wakeup>
    80004aec:	b7e9                	j	80004ab6 <pipeclose+0x2c>
    release(&pi->lock);
    80004aee:	8526                	mv	a0,s1
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	226080e7          	jalr	550(ra) # 80000d16 <release>
}
    80004af8:	bfe1                	j	80004ad0 <pipeclose+0x46>

0000000080004afa <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004afa:	7119                	addi	sp,sp,-128
    80004afc:	fc86                	sd	ra,120(sp)
    80004afe:	f8a2                	sd	s0,112(sp)
    80004b00:	f4a6                	sd	s1,104(sp)
    80004b02:	f0ca                	sd	s2,96(sp)
    80004b04:	ecce                	sd	s3,88(sp)
    80004b06:	e8d2                	sd	s4,80(sp)
    80004b08:	e4d6                	sd	s5,72(sp)
    80004b0a:	e0da                	sd	s6,64(sp)
    80004b0c:	fc5e                	sd	s7,56(sp)
    80004b0e:	f862                	sd	s8,48(sp)
    80004b10:	f466                	sd	s9,40(sp)
    80004b12:	f06a                	sd	s10,32(sp)
    80004b14:	ec6e                	sd	s11,24(sp)
    80004b16:	0100                	addi	s0,sp,128
    80004b18:	84aa                	mv	s1,a0
    80004b1a:	8d2e                	mv	s10,a1
    80004b1c:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b1e:	ffffd097          	auipc	ra,0xffffd
    80004b22:	f72080e7          	jalr	-142(ra) # 80001a90 <myproc>
    80004b26:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b28:	8526                	mv	a0,s1
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	138080e7          	jalr	312(ra) # 80000c62 <acquire>
  for(i = 0; i < n; i++){
    80004b32:	0d605f63          	blez	s6,80004c10 <pipewrite+0x116>
    80004b36:	89a6                	mv	s3,s1
    80004b38:	3b7d                	addiw	s6,s6,-1
    80004b3a:	1b02                	slli	s6,s6,0x20
    80004b3c:	020b5b13          	srli	s6,s6,0x20
    80004b40:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b42:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b46:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b4a:	5dfd                	li	s11,-1
    80004b4c:	000b8c9b          	sext.w	s9,s7
    80004b50:	8c66                	mv	s8,s9
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b52:	2184a783          	lw	a5,536(s1)
    80004b56:	21c4a703          	lw	a4,540(s1)
    80004b5a:	2007879b          	addiw	a5,a5,512
    80004b5e:	06f71763          	bne	a4,a5,80004bcc <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80004b62:	2204a783          	lw	a5,544(s1)
    80004b66:	cf8d                	beqz	a5,80004ba0 <pipewrite+0xa6>
    80004b68:	03092783          	lw	a5,48(s2)
    80004b6c:	eb95                	bnez	a5,80004ba0 <pipewrite+0xa6>
      wakeup(&pi->nread);
    80004b6e:	8556                	mv	a0,s5
    80004b70:	ffffe097          	auipc	ra,0xffffe
    80004b74:	8c0080e7          	jalr	-1856(ra) # 80002430 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b78:	85ce                	mv	a1,s3
    80004b7a:	8552                	mv	a0,s4
    80004b7c:	ffffd097          	auipc	ra,0xffffd
    80004b80:	72e080e7          	jalr	1838(ra) # 800022aa <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b84:	2184a783          	lw	a5,536(s1)
    80004b88:	21c4a703          	lw	a4,540(s1)
    80004b8c:	2007879b          	addiw	a5,a5,512
    80004b90:	02f71e63          	bne	a4,a5,80004bcc <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80004b94:	2204a783          	lw	a5,544(s1)
    80004b98:	c781                	beqz	a5,80004ba0 <pipewrite+0xa6>
    80004b9a:	03092783          	lw	a5,48(s2)
    80004b9e:	dbe1                	beqz	a5,80004b6e <pipewrite+0x74>
        release(&pi->lock);
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	174080e7          	jalr	372(ra) # 80000d16 <release>
        return -1;
    80004baa:	5c7d                	li	s8,-1
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004bac:	8562                	mv	a0,s8
    80004bae:	70e6                	ld	ra,120(sp)
    80004bb0:	7446                	ld	s0,112(sp)
    80004bb2:	74a6                	ld	s1,104(sp)
    80004bb4:	7906                	ld	s2,96(sp)
    80004bb6:	69e6                	ld	s3,88(sp)
    80004bb8:	6a46                	ld	s4,80(sp)
    80004bba:	6aa6                	ld	s5,72(sp)
    80004bbc:	6b06                	ld	s6,64(sp)
    80004bbe:	7be2                	ld	s7,56(sp)
    80004bc0:	7c42                	ld	s8,48(sp)
    80004bc2:	7ca2                	ld	s9,40(sp)
    80004bc4:	7d02                	ld	s10,32(sp)
    80004bc6:	6de2                	ld	s11,24(sp)
    80004bc8:	6109                	addi	sp,sp,128
    80004bca:	8082                	ret
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bcc:	4685                	li	a3,1
    80004bce:	01ab8633          	add	a2,s7,s10
    80004bd2:	f8f40593          	addi	a1,s0,-113
    80004bd6:	05093503          	ld	a0,80(s2)
    80004bda:	ffffd097          	auipc	ra,0xffffd
    80004bde:	c1e080e7          	jalr	-994(ra) # 800017f8 <copyin>
    80004be2:	03b50863          	beq	a0,s11,80004c12 <pipewrite+0x118>
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004be6:	21c4a783          	lw	a5,540(s1)
    80004bea:	0017871b          	addiw	a4,a5,1
    80004bee:	20e4ae23          	sw	a4,540(s1)
    80004bf2:	1ff7f793          	andi	a5,a5,511
    80004bf6:	97a6                	add	a5,a5,s1
    80004bf8:	f8f44703          	lbu	a4,-113(s0)
    80004bfc:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c00:	001c8c1b          	addiw	s8,s9,1
    80004c04:	001b8793          	addi	a5,s7,1
    80004c08:	016b8563          	beq	s7,s6,80004c12 <pipewrite+0x118>
    80004c0c:	8bbe                	mv	s7,a5
    80004c0e:	bf3d                	j	80004b4c <pipewrite+0x52>
    80004c10:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004c12:	21848513          	addi	a0,s1,536
    80004c16:	ffffe097          	auipc	ra,0xffffe
    80004c1a:	81a080e7          	jalr	-2022(ra) # 80002430 <wakeup>
  release(&pi->lock);
    80004c1e:	8526                	mv	a0,s1
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	0f6080e7          	jalr	246(ra) # 80000d16 <release>
  return i;
    80004c28:	b751                	j	80004bac <pipewrite+0xb2>

0000000080004c2a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c2a:	715d                	addi	sp,sp,-80
    80004c2c:	e486                	sd	ra,72(sp)
    80004c2e:	e0a2                	sd	s0,64(sp)
    80004c30:	fc26                	sd	s1,56(sp)
    80004c32:	f84a                	sd	s2,48(sp)
    80004c34:	f44e                	sd	s3,40(sp)
    80004c36:	f052                	sd	s4,32(sp)
    80004c38:	ec56                	sd	s5,24(sp)
    80004c3a:	e85a                	sd	s6,16(sp)
    80004c3c:	0880                	addi	s0,sp,80
    80004c3e:	84aa                	mv	s1,a0
    80004c40:	89ae                	mv	s3,a1
    80004c42:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c44:	ffffd097          	auipc	ra,0xffffd
    80004c48:	e4c080e7          	jalr	-436(ra) # 80001a90 <myproc>
    80004c4c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c4e:	8526                	mv	a0,s1
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	012080e7          	jalr	18(ra) # 80000c62 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c58:	2184a703          	lw	a4,536(s1)
    80004c5c:	21c4a783          	lw	a5,540(s1)
    80004c60:	06f71b63          	bne	a4,a5,80004cd6 <piperead+0xac>
    80004c64:	8926                	mv	s2,s1
    80004c66:	2244a783          	lw	a5,548(s1)
    80004c6a:	cf9d                	beqz	a5,80004ca8 <piperead+0x7e>
    if(pr->killed){
    80004c6c:	030a2783          	lw	a5,48(s4)
    80004c70:	e78d                	bnez	a5,80004c9a <piperead+0x70>
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c72:	21848b13          	addi	s6,s1,536
    80004c76:	85ca                	mv	a1,s2
    80004c78:	855a                	mv	a0,s6
    80004c7a:	ffffd097          	auipc	ra,0xffffd
    80004c7e:	630080e7          	jalr	1584(ra) # 800022aa <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c82:	2184a703          	lw	a4,536(s1)
    80004c86:	21c4a783          	lw	a5,540(s1)
    80004c8a:	04f71663          	bne	a4,a5,80004cd6 <piperead+0xac>
    80004c8e:	2244a783          	lw	a5,548(s1)
    80004c92:	cb99                	beqz	a5,80004ca8 <piperead+0x7e>
    if(pr->killed){
    80004c94:	030a2783          	lw	a5,48(s4)
    80004c98:	dff9                	beqz	a5,80004c76 <piperead+0x4c>
      release(&pi->lock);
    80004c9a:	8526                	mv	a0,s1
    80004c9c:	ffffc097          	auipc	ra,0xffffc
    80004ca0:	07a080e7          	jalr	122(ra) # 80000d16 <release>
      return -1;
    80004ca4:	597d                	li	s2,-1
    80004ca6:	a829                	j	80004cc0 <piperead+0x96>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    if(pi->nread == pi->nwrite)
    80004ca8:	4901                	li	s2,0
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004caa:	21c48513          	addi	a0,s1,540
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	782080e7          	jalr	1922(ra) # 80002430 <wakeup>
  release(&pi->lock);
    80004cb6:	8526                	mv	a0,s1
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	05e080e7          	jalr	94(ra) # 80000d16 <release>
  return i;
}
    80004cc0:	854a                	mv	a0,s2
    80004cc2:	60a6                	ld	ra,72(sp)
    80004cc4:	6406                	ld	s0,64(sp)
    80004cc6:	74e2                	ld	s1,56(sp)
    80004cc8:	7942                	ld	s2,48(sp)
    80004cca:	79a2                	ld	s3,40(sp)
    80004ccc:	7a02                	ld	s4,32(sp)
    80004cce:	6ae2                	ld	s5,24(sp)
    80004cd0:	6b42                	ld	s6,16(sp)
    80004cd2:	6161                	addi	sp,sp,80
    80004cd4:	8082                	ret
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cd6:	4901                	li	s2,0
    80004cd8:	fd5059e3          	blez	s5,80004caa <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004cdc:	2184a783          	lw	a5,536(s1)
    80004ce0:	4901                	li	s2,0
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ce2:	5b7d                	li	s6,-1
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004ce4:	0017871b          	addiw	a4,a5,1
    80004ce8:	20e4ac23          	sw	a4,536(s1)
    80004cec:	1ff7f793          	andi	a5,a5,511
    80004cf0:	97a6                	add	a5,a5,s1
    80004cf2:	0187c783          	lbu	a5,24(a5)
    80004cf6:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cfa:	4685                	li	a3,1
    80004cfc:	fbf40613          	addi	a2,s0,-65
    80004d00:	85ce                	mv	a1,s3
    80004d02:	050a3503          	ld	a0,80(s4)
    80004d06:	ffffd097          	auipc	ra,0xffffd
    80004d0a:	a66080e7          	jalr	-1434(ra) # 8000176c <copyout>
    80004d0e:	f9650ee3          	beq	a0,s6,80004caa <piperead+0x80>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d12:	2905                	addiw	s2,s2,1
    80004d14:	f92a8be3          	beq	s5,s2,80004caa <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004d18:	2184a783          	lw	a5,536(s1)
    80004d1c:	0985                	addi	s3,s3,1
    80004d1e:	21c4a703          	lw	a4,540(s1)
    80004d22:	fcf711e3          	bne	a4,a5,80004ce4 <piperead+0xba>
    80004d26:	b751                	j	80004caa <piperead+0x80>

0000000080004d28 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d28:	de010113          	addi	sp,sp,-544
    80004d2c:	20113c23          	sd	ra,536(sp)
    80004d30:	20813823          	sd	s0,528(sp)
    80004d34:	20913423          	sd	s1,520(sp)
    80004d38:	21213023          	sd	s2,512(sp)
    80004d3c:	ffce                	sd	s3,504(sp)
    80004d3e:	fbd2                	sd	s4,496(sp)
    80004d40:	f7d6                	sd	s5,488(sp)
    80004d42:	f3da                	sd	s6,480(sp)
    80004d44:	efde                	sd	s7,472(sp)
    80004d46:	ebe2                	sd	s8,464(sp)
    80004d48:	e7e6                	sd	s9,456(sp)
    80004d4a:	e3ea                	sd	s10,448(sp)
    80004d4c:	ff6e                	sd	s11,440(sp)
    80004d4e:	1400                	addi	s0,sp,544
    80004d50:	892a                	mv	s2,a0
    80004d52:	dea43823          	sd	a0,-528(s0)
    80004d56:	deb43c23          	sd	a1,-520(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	d36080e7          	jalr	-714(ra) # 80001a90 <myproc>
    80004d62:	84aa                	mv	s1,a0

  begin_op();
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	402080e7          	jalr	1026(ra) # 80004166 <begin_op>

  if((ip = namei(path)) == 0){
    80004d6c:	854a                	mv	a0,s2
    80004d6e:	fffff097          	auipc	ra,0xfffff
    80004d72:	1ea080e7          	jalr	490(ra) # 80003f58 <namei>
    80004d76:	c93d                	beqz	a0,80004dec <exec+0xc4>
    80004d78:	892a                	mv	s2,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d7a:	fffff097          	auipc	ra,0xfffff
    80004d7e:	a20080e7          	jalr	-1504(ra) # 8000379a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d82:	04000713          	li	a4,64
    80004d86:	4681                	li	a3,0
    80004d88:	e4840613          	addi	a2,s0,-440
    80004d8c:	4581                	li	a1,0
    80004d8e:	854a                	mv	a0,s2
    80004d90:	fffff097          	auipc	ra,0xfffff
    80004d94:	cc0080e7          	jalr	-832(ra) # 80003a50 <readi>
    80004d98:	04000793          	li	a5,64
    80004d9c:	00f51a63          	bne	a0,a5,80004db0 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004da0:	e4842703          	lw	a4,-440(s0)
    80004da4:	464c47b7          	lui	a5,0x464c4
    80004da8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004dac:	04f70663          	beq	a4,a5,80004df8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004db0:	854a                	mv	a0,s2
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	c4c080e7          	jalr	-948(ra) # 800039fe <iunlockput>
    end_op();
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	42c080e7          	jalr	1068(ra) # 800041e6 <end_op>
  }
  return -1;
    80004dc2:	557d                	li	a0,-1
}
    80004dc4:	21813083          	ld	ra,536(sp)
    80004dc8:	21013403          	ld	s0,528(sp)
    80004dcc:	20813483          	ld	s1,520(sp)
    80004dd0:	20013903          	ld	s2,512(sp)
    80004dd4:	79fe                	ld	s3,504(sp)
    80004dd6:	7a5e                	ld	s4,496(sp)
    80004dd8:	7abe                	ld	s5,488(sp)
    80004dda:	7b1e                	ld	s6,480(sp)
    80004ddc:	6bfe                	ld	s7,472(sp)
    80004dde:	6c5e                	ld	s8,464(sp)
    80004de0:	6cbe                	ld	s9,456(sp)
    80004de2:	6d1e                	ld	s10,448(sp)
    80004de4:	7dfa                	ld	s11,440(sp)
    80004de6:	22010113          	addi	sp,sp,544
    80004dea:	8082                	ret
    end_op();
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	3fa080e7          	jalr	1018(ra) # 800041e6 <end_op>
    return -1;
    80004df4:	557d                	li	a0,-1
    80004df6:	b7f9                	j	80004dc4 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004df8:	8526                	mv	a0,s1
    80004dfa:	ffffd097          	auipc	ra,0xffffd
    80004dfe:	d5c080e7          	jalr	-676(ra) # 80001b56 <proc_pagetable>
    80004e02:	e0a43423          	sd	a0,-504(s0)
    80004e06:	d54d                	beqz	a0,80004db0 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e08:	e6842983          	lw	s3,-408(s0)
    80004e0c:	e8045783          	lhu	a5,-384(s0)
    80004e10:	c7ad                	beqz	a5,80004e7a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e12:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e14:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e16:	6c05                	lui	s8,0x1
    80004e18:	fffc0793          	addi	a5,s8,-1 # fff <_entry-0x7ffff001>
    80004e1c:	def43423          	sd	a5,-536(s0)
    80004e20:	7cfd                	lui	s9,0xfffff
    80004e22:	ac1d                	j	80005058 <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e24:	00004517          	auipc	a0,0x4
    80004e28:	82c50513          	addi	a0,a0,-2004 # 80008650 <syscalls+0x2b8>
    80004e2c:	ffffb097          	auipc	ra,0xffffb
    80004e30:	748080e7          	jalr	1864(ra) # 80000574 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e34:	8756                	mv	a4,s5
    80004e36:	009d86bb          	addw	a3,s11,s1
    80004e3a:	4581                	li	a1,0
    80004e3c:	854a                	mv	a0,s2
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	c12080e7          	jalr	-1006(ra) # 80003a50 <readi>
    80004e46:	2501                	sext.w	a0,a0
    80004e48:	1aaa9e63          	bne	s5,a0,80005004 <exec+0x2dc>
  for(i = 0; i < sz; i += PGSIZE){
    80004e4c:	6785                	lui	a5,0x1
    80004e4e:	9cbd                	addw	s1,s1,a5
    80004e50:	014c8a3b          	addw	s4,s9,s4
    80004e54:	1f74f963          	bleu	s7,s1,80005046 <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    80004e58:	02049593          	slli	a1,s1,0x20
    80004e5c:	9181                	srli	a1,a1,0x20
    80004e5e:	95ea                	add	a1,a1,s10
    80004e60:	e0843503          	ld	a0,-504(s0)
    80004e64:	ffffc097          	auipc	ra,0xffffc
    80004e68:	6e0080e7          	jalr	1760(ra) # 80001544 <walkaddr>
    80004e6c:	862a                	mv	a2,a0
    if(pa == 0)
    80004e6e:	d95d                	beqz	a0,80004e24 <exec+0xfc>
      n = PGSIZE;
    80004e70:	8ae2                	mv	s5,s8
    if(sz - i < PGSIZE)
    80004e72:	fd8a71e3          	bleu	s8,s4,80004e34 <exec+0x10c>
      n = sz - i;
    80004e76:	8ad2                	mv	s5,s4
    80004e78:	bf75                	j	80004e34 <exec+0x10c>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e7a:	4481                	li	s1,0
  iunlockput(ip);
    80004e7c:	854a                	mv	a0,s2
    80004e7e:	fffff097          	auipc	ra,0xfffff
    80004e82:	b80080e7          	jalr	-1152(ra) # 800039fe <iunlockput>
  end_op();
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	360080e7          	jalr	864(ra) # 800041e6 <end_op>
  p = myproc();
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	c02080e7          	jalr	-1022(ra) # 80001a90 <myproc>
    80004e96:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e98:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e9c:	6785                	lui	a5,0x1
    80004e9e:	17fd                	addi	a5,a5,-1
    80004ea0:	94be                	add	s1,s1,a5
    80004ea2:	77fd                	lui	a5,0xfffff
    80004ea4:	8fe5                	and	a5,a5,s1
    80004ea6:	e0f43023          	sd	a5,-512(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004eaa:	6609                	lui	a2,0x2
    80004eac:	963e                	add	a2,a2,a5
    80004eae:	85be                	mv	a1,a5
    80004eb0:	e0843483          	ld	s1,-504(s0)
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	5e4080e7          	jalr	1508(ra) # 8000149a <uvmalloc>
    80004ebe:	8b2a                	mv	s6,a0
  ip = 0;
    80004ec0:	4901                	li	s2,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ec2:	14050163          	beqz	a0,80005004 <exec+0x2dc>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ec6:	75f9                	lui	a1,0xffffe
    80004ec8:	95aa                	add	a1,a1,a0
    80004eca:	8526                	mv	a0,s1
    80004ecc:	ffffd097          	auipc	ra,0xffffd
    80004ed0:	86e080e7          	jalr	-1938(ra) # 8000173a <uvmclear>
  stackbase = sp - PGSIZE;
    80004ed4:	7bfd                	lui	s7,0xfffff
    80004ed6:	9bda                	add	s7,s7,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ed8:	df843783          	ld	a5,-520(s0)
    80004edc:	6388                	ld	a0,0(a5)
    80004ede:	c925                	beqz	a0,80004f4e <exec+0x226>
    80004ee0:	e8840993          	addi	s3,s0,-376
    80004ee4:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80004ee8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eea:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	01c080e7          	jalr	28(ra) # 80000f08 <strlen>
    80004ef4:	2505                	addiw	a0,a0,1
    80004ef6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004efa:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004efe:	13796863          	bltu	s2,s7,8000502e <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f02:	df843c83          	ld	s9,-520(s0)
    80004f06:	000cba03          	ld	s4,0(s9) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80004f0a:	8552                	mv	a0,s4
    80004f0c:	ffffc097          	auipc	ra,0xffffc
    80004f10:	ffc080e7          	jalr	-4(ra) # 80000f08 <strlen>
    80004f14:	0015069b          	addiw	a3,a0,1
    80004f18:	8652                	mv	a2,s4
    80004f1a:	85ca                	mv	a1,s2
    80004f1c:	e0843503          	ld	a0,-504(s0)
    80004f20:	ffffd097          	auipc	ra,0xffffd
    80004f24:	84c080e7          	jalr	-1972(ra) # 8000176c <copyout>
    80004f28:	10054763          	bltz	a0,80005036 <exec+0x30e>
    ustack[argc] = sp;
    80004f2c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f30:	0485                	addi	s1,s1,1
    80004f32:	008c8793          	addi	a5,s9,8
    80004f36:	def43c23          	sd	a5,-520(s0)
    80004f3a:	008cb503          	ld	a0,8(s9)
    80004f3e:	c911                	beqz	a0,80004f52 <exec+0x22a>
    if(argc >= MAXARG)
    80004f40:	09a1                	addi	s3,s3,8
    80004f42:	fb8995e3          	bne	s3,s8,80004eec <exec+0x1c4>
  sz = sz1;
    80004f46:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004f4a:	4901                	li	s2,0
    80004f4c:	a865                	j	80005004 <exec+0x2dc>
  sp = sz;
    80004f4e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f50:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f52:	00349793          	slli	a5,s1,0x3
    80004f56:	f9040713          	addi	a4,s0,-112
    80004f5a:	97ba                	add	a5,a5,a4
    80004f5c:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f60:	00148693          	addi	a3,s1,1
    80004f64:	068e                	slli	a3,a3,0x3
    80004f66:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f6a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f6e:	01797663          	bleu	s7,s2,80004f7a <exec+0x252>
  sz = sz1;
    80004f72:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004f76:	4901                	li	s2,0
    80004f78:	a071                	j	80005004 <exec+0x2dc>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f7a:	e8840613          	addi	a2,s0,-376
    80004f7e:	85ca                	mv	a1,s2
    80004f80:	e0843503          	ld	a0,-504(s0)
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	7e8080e7          	jalr	2024(ra) # 8000176c <copyout>
    80004f8c:	0a054963          	bltz	a0,8000503e <exec+0x316>
  p->trapframe->a1 = sp;
    80004f90:	058ab783          	ld	a5,88(s5)
    80004f94:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f98:	df043783          	ld	a5,-528(s0)
    80004f9c:	0007c703          	lbu	a4,0(a5)
    80004fa0:	cf11                	beqz	a4,80004fbc <exec+0x294>
    80004fa2:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fa4:	02f00693          	li	a3,47
    80004fa8:	a029                	j	80004fb2 <exec+0x28a>
  for(last=s=path; *s; s++)
    80004faa:	0785                	addi	a5,a5,1
    80004fac:	fff7c703          	lbu	a4,-1(a5)
    80004fb0:	c711                	beqz	a4,80004fbc <exec+0x294>
    if(*s == '/')
    80004fb2:	fed71ce3          	bne	a4,a3,80004faa <exec+0x282>
      last = s+1;
    80004fb6:	def43823          	sd	a5,-528(s0)
    80004fba:	bfc5                	j	80004faa <exec+0x282>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fbc:	4641                	li	a2,16
    80004fbe:	df043583          	ld	a1,-528(s0)
    80004fc2:	158a8513          	addi	a0,s5,344
    80004fc6:	ffffc097          	auipc	ra,0xffffc
    80004fca:	f10080e7          	jalr	-240(ra) # 80000ed6 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fce:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fd2:	e0843783          	ld	a5,-504(s0)
    80004fd6:	04fab823          	sd	a5,80(s5)
  p->sz = sz;
    80004fda:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fde:	058ab783          	ld	a5,88(s5)
    80004fe2:	e6043703          	ld	a4,-416(s0)
    80004fe6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fe8:	058ab783          	ld	a5,88(s5)
    80004fec:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004ff0:	85ea                	mv	a1,s10
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	c00080e7          	jalr	-1024(ra) # 80001bf2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004ffa:	0004851b          	sext.w	a0,s1
    80004ffe:	b3d9                	j	80004dc4 <exec+0x9c>
    80005000:	e0943023          	sd	s1,-512(s0)
    proc_freepagetable(pagetable, sz);
    80005004:	e0043583          	ld	a1,-512(s0)
    80005008:	e0843503          	ld	a0,-504(s0)
    8000500c:	ffffd097          	auipc	ra,0xffffd
    80005010:	be6080e7          	jalr	-1050(ra) # 80001bf2 <proc_freepagetable>
  if(ip){
    80005014:	d8091ee3          	bnez	s2,80004db0 <exec+0x88>
  return -1;
    80005018:	557d                	li	a0,-1
    8000501a:	b36d                	j	80004dc4 <exec+0x9c>
    8000501c:	e0943023          	sd	s1,-512(s0)
    80005020:	b7d5                	j	80005004 <exec+0x2dc>
    80005022:	e0943023          	sd	s1,-512(s0)
    80005026:	bff9                	j	80005004 <exec+0x2dc>
    80005028:	e0943023          	sd	s1,-512(s0)
    8000502c:	bfe1                	j	80005004 <exec+0x2dc>
  sz = sz1;
    8000502e:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005032:	4901                	li	s2,0
    80005034:	bfc1                	j	80005004 <exec+0x2dc>
  sz = sz1;
    80005036:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    8000503a:	4901                	li	s2,0
    8000503c:	b7e1                	j	80005004 <exec+0x2dc>
  sz = sz1;
    8000503e:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005042:	4901                	li	s2,0
    80005044:	b7c1                	j	80005004 <exec+0x2dc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005046:	e0043483          	ld	s1,-512(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000504a:	2b05                	addiw	s6,s6,1
    8000504c:	0389899b          	addiw	s3,s3,56
    80005050:	e8045783          	lhu	a5,-384(s0)
    80005054:	e2fb54e3          	ble	a5,s6,80004e7c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005058:	2981                	sext.w	s3,s3
    8000505a:	03800713          	li	a4,56
    8000505e:	86ce                	mv	a3,s3
    80005060:	e1040613          	addi	a2,s0,-496
    80005064:	4581                	li	a1,0
    80005066:	854a                	mv	a0,s2
    80005068:	fffff097          	auipc	ra,0xfffff
    8000506c:	9e8080e7          	jalr	-1560(ra) # 80003a50 <readi>
    80005070:	03800793          	li	a5,56
    80005074:	f8f516e3          	bne	a0,a5,80005000 <exec+0x2d8>
    if(ph.type != ELF_PROG_LOAD)
    80005078:	e1042783          	lw	a5,-496(s0)
    8000507c:	4705                	li	a4,1
    8000507e:	fce796e3          	bne	a5,a4,8000504a <exec+0x322>
    if(ph.memsz < ph.filesz)
    80005082:	e3843603          	ld	a2,-456(s0)
    80005086:	e3043783          	ld	a5,-464(s0)
    8000508a:	f8f669e3          	bltu	a2,a5,8000501c <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000508e:	e2043783          	ld	a5,-480(s0)
    80005092:	963e                	add	a2,a2,a5
    80005094:	f8f667e3          	bltu	a2,a5,80005022 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005098:	85a6                	mv	a1,s1
    8000509a:	e0843503          	ld	a0,-504(s0)
    8000509e:	ffffc097          	auipc	ra,0xffffc
    800050a2:	3fc080e7          	jalr	1020(ra) # 8000149a <uvmalloc>
    800050a6:	e0a43023          	sd	a0,-512(s0)
    800050aa:	dd3d                	beqz	a0,80005028 <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    800050ac:	e2043d03          	ld	s10,-480(s0)
    800050b0:	de843783          	ld	a5,-536(s0)
    800050b4:	00fd77b3          	and	a5,s10,a5
    800050b8:	f7b1                	bnez	a5,80005004 <exec+0x2dc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050ba:	e1842d83          	lw	s11,-488(s0)
    800050be:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050c2:	f80b82e3          	beqz	s7,80005046 <exec+0x31e>
    800050c6:	8a5e                	mv	s4,s7
    800050c8:	4481                	li	s1,0
    800050ca:	b379                	j	80004e58 <exec+0x130>

00000000800050cc <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050cc:	7179                	addi	sp,sp,-48
    800050ce:	f406                	sd	ra,40(sp)
    800050d0:	f022                	sd	s0,32(sp)
    800050d2:	ec26                	sd	s1,24(sp)
    800050d4:	e84a                	sd	s2,16(sp)
    800050d6:	1800                	addi	s0,sp,48
    800050d8:	892e                	mv	s2,a1
    800050da:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050dc:	fdc40593          	addi	a1,s0,-36
    800050e0:	ffffe097          	auipc	ra,0xffffe
    800050e4:	ad8080e7          	jalr	-1320(ra) # 80002bb8 <argint>
    800050e8:	04054063          	bltz	a0,80005128 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050ec:	fdc42703          	lw	a4,-36(s0)
    800050f0:	47bd                	li	a5,15
    800050f2:	02e7ed63          	bltu	a5,a4,8000512c <argfd+0x60>
    800050f6:	ffffd097          	auipc	ra,0xffffd
    800050fa:	99a080e7          	jalr	-1638(ra) # 80001a90 <myproc>
    800050fe:	fdc42703          	lw	a4,-36(s0)
    80005102:	01a70793          	addi	a5,a4,26
    80005106:	078e                	slli	a5,a5,0x3
    80005108:	953e                	add	a0,a0,a5
    8000510a:	611c                	ld	a5,0(a0)
    8000510c:	c395                	beqz	a5,80005130 <argfd+0x64>
    return -1;
  if(pfd)
    8000510e:	00090463          	beqz	s2,80005116 <argfd+0x4a>
    *pfd = fd;
    80005112:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005116:	4501                	li	a0,0
  if(pf)
    80005118:	c091                	beqz	s1,8000511c <argfd+0x50>
    *pf = f;
    8000511a:	e09c                	sd	a5,0(s1)
}
    8000511c:	70a2                	ld	ra,40(sp)
    8000511e:	7402                	ld	s0,32(sp)
    80005120:	64e2                	ld	s1,24(sp)
    80005122:	6942                	ld	s2,16(sp)
    80005124:	6145                	addi	sp,sp,48
    80005126:	8082                	ret
    return -1;
    80005128:	557d                	li	a0,-1
    8000512a:	bfcd                	j	8000511c <argfd+0x50>
    return -1;
    8000512c:	557d                	li	a0,-1
    8000512e:	b7fd                	j	8000511c <argfd+0x50>
    80005130:	557d                	li	a0,-1
    80005132:	b7ed                	j	8000511c <argfd+0x50>

0000000080005134 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005134:	1101                	addi	sp,sp,-32
    80005136:	ec06                	sd	ra,24(sp)
    80005138:	e822                	sd	s0,16(sp)
    8000513a:	e426                	sd	s1,8(sp)
    8000513c:	1000                	addi	s0,sp,32
    8000513e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005140:	ffffd097          	auipc	ra,0xffffd
    80005144:	950080e7          	jalr	-1712(ra) # 80001a90 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){
    80005148:	697c                	ld	a5,208(a0)
    8000514a:	c395                	beqz	a5,8000516e <fdalloc+0x3a>
    8000514c:	0d850713          	addi	a4,a0,216
  for(fd = 0; fd < NOFILE; fd++){
    80005150:	4785                	li	a5,1
    80005152:	4641                	li	a2,16
    if(p->ofile[fd] == 0){
    80005154:	6314                	ld	a3,0(a4)
    80005156:	ce89                	beqz	a3,80005170 <fdalloc+0x3c>
  for(fd = 0; fd < NOFILE; fd++){
    80005158:	2785                	addiw	a5,a5,1
    8000515a:	0721                	addi	a4,a4,8
    8000515c:	fec79ce3          	bne	a5,a2,80005154 <fdalloc+0x20>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005160:	57fd                	li	a5,-1
}
    80005162:	853e                	mv	a0,a5
    80005164:	60e2                	ld	ra,24(sp)
    80005166:	6442                	ld	s0,16(sp)
    80005168:	64a2                	ld	s1,8(sp)
    8000516a:	6105                	addi	sp,sp,32
    8000516c:	8082                	ret
  for(fd = 0; fd < NOFILE; fd++){
    8000516e:	4781                	li	a5,0
      p->ofile[fd] = f;
    80005170:	01a78713          	addi	a4,a5,26
    80005174:	070e                	slli	a4,a4,0x3
    80005176:	953a                	add	a0,a0,a4
    80005178:	e104                	sd	s1,0(a0)
      return fd;
    8000517a:	b7e5                	j	80005162 <fdalloc+0x2e>

000000008000517c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000517c:	715d                	addi	sp,sp,-80
    8000517e:	e486                	sd	ra,72(sp)
    80005180:	e0a2                	sd	s0,64(sp)
    80005182:	fc26                	sd	s1,56(sp)
    80005184:	f84a                	sd	s2,48(sp)
    80005186:	f44e                	sd	s3,40(sp)
    80005188:	f052                	sd	s4,32(sp)
    8000518a:	ec56                	sd	s5,24(sp)
    8000518c:	0880                	addi	s0,sp,80
    8000518e:	89ae                	mv	s3,a1
    80005190:	8ab2                	mv	s5,a2
    80005192:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005194:	fb040593          	addi	a1,s0,-80
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	dde080e7          	jalr	-546(ra) # 80003f76 <nameiparent>
    800051a0:	892a                	mv	s2,a0
    800051a2:	12050f63          	beqz	a0,800052e0 <create+0x164>
    return 0;

  ilock(dp);
    800051a6:	ffffe097          	auipc	ra,0xffffe
    800051aa:	5f4080e7          	jalr	1524(ra) # 8000379a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051ae:	4601                	li	a2,0
    800051b0:	fb040593          	addi	a1,s0,-80
    800051b4:	854a                	mv	a0,s2
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	ac8080e7          	jalr	-1336(ra) # 80003c7e <dirlookup>
    800051be:	84aa                	mv	s1,a0
    800051c0:	c921                	beqz	a0,80005210 <create+0x94>
    iunlockput(dp);
    800051c2:	854a                	mv	a0,s2
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	83a080e7          	jalr	-1990(ra) # 800039fe <iunlockput>
    ilock(ip);
    800051cc:	8526                	mv	a0,s1
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	5cc080e7          	jalr	1484(ra) # 8000379a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051d6:	2981                	sext.w	s3,s3
    800051d8:	4789                	li	a5,2
    800051da:	02f99463          	bne	s3,a5,80005202 <create+0x86>
    800051de:	0444d783          	lhu	a5,68(s1)
    800051e2:	37f9                	addiw	a5,a5,-2
    800051e4:	17c2                	slli	a5,a5,0x30
    800051e6:	93c1                	srli	a5,a5,0x30
    800051e8:	4705                	li	a4,1
    800051ea:	00f76c63          	bltu	a4,a5,80005202 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051ee:	8526                	mv	a0,s1
    800051f0:	60a6                	ld	ra,72(sp)
    800051f2:	6406                	ld	s0,64(sp)
    800051f4:	74e2                	ld	s1,56(sp)
    800051f6:	7942                	ld	s2,48(sp)
    800051f8:	79a2                	ld	s3,40(sp)
    800051fa:	7a02                	ld	s4,32(sp)
    800051fc:	6ae2                	ld	s5,24(sp)
    800051fe:	6161                	addi	sp,sp,80
    80005200:	8082                	ret
    iunlockput(ip);
    80005202:	8526                	mv	a0,s1
    80005204:	ffffe097          	auipc	ra,0xffffe
    80005208:	7fa080e7          	jalr	2042(ra) # 800039fe <iunlockput>
    return 0;
    8000520c:	4481                	li	s1,0
    8000520e:	b7c5                	j	800051ee <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005210:	85ce                	mv	a1,s3
    80005212:	00092503          	lw	a0,0(s2)
    80005216:	ffffe097          	auipc	ra,0xffffe
    8000521a:	3e8080e7          	jalr	1000(ra) # 800035fe <ialloc>
    8000521e:	84aa                	mv	s1,a0
    80005220:	c529                	beqz	a0,8000526a <create+0xee>
  ilock(ip);
    80005222:	ffffe097          	auipc	ra,0xffffe
    80005226:	578080e7          	jalr	1400(ra) # 8000379a <ilock>
  ip->major = major;
    8000522a:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000522e:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005232:	4785                	li	a5,1
    80005234:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005238:	8526                	mv	a0,s1
    8000523a:	ffffe097          	auipc	ra,0xffffe
    8000523e:	494080e7          	jalr	1172(ra) # 800036ce <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005242:	2981                	sext.w	s3,s3
    80005244:	4785                	li	a5,1
    80005246:	02f98a63          	beq	s3,a5,8000527a <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000524a:	40d0                	lw	a2,4(s1)
    8000524c:	fb040593          	addi	a1,s0,-80
    80005250:	854a                	mv	a0,s2
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	c44080e7          	jalr	-956(ra) # 80003e96 <dirlink>
    8000525a:	06054b63          	bltz	a0,800052d0 <create+0x154>
  iunlockput(dp);
    8000525e:	854a                	mv	a0,s2
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	79e080e7          	jalr	1950(ra) # 800039fe <iunlockput>
  return ip;
    80005268:	b759                	j	800051ee <create+0x72>
    panic("create: ialloc");
    8000526a:	00003517          	auipc	a0,0x3
    8000526e:	40650513          	addi	a0,a0,1030 # 80008670 <syscalls+0x2d8>
    80005272:	ffffb097          	auipc	ra,0xffffb
    80005276:	302080e7          	jalr	770(ra) # 80000574 <panic>
    dp->nlink++;  // for ".."
    8000527a:	04a95783          	lhu	a5,74(s2)
    8000527e:	2785                	addiw	a5,a5,1
    80005280:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005284:	854a                	mv	a0,s2
    80005286:	ffffe097          	auipc	ra,0xffffe
    8000528a:	448080e7          	jalr	1096(ra) # 800036ce <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000528e:	40d0                	lw	a2,4(s1)
    80005290:	00003597          	auipc	a1,0x3
    80005294:	3f058593          	addi	a1,a1,1008 # 80008680 <syscalls+0x2e8>
    80005298:	8526                	mv	a0,s1
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	bfc080e7          	jalr	-1028(ra) # 80003e96 <dirlink>
    800052a2:	00054f63          	bltz	a0,800052c0 <create+0x144>
    800052a6:	00492603          	lw	a2,4(s2)
    800052aa:	00003597          	auipc	a1,0x3
    800052ae:	3de58593          	addi	a1,a1,990 # 80008688 <syscalls+0x2f0>
    800052b2:	8526                	mv	a0,s1
    800052b4:	fffff097          	auipc	ra,0xfffff
    800052b8:	be2080e7          	jalr	-1054(ra) # 80003e96 <dirlink>
    800052bc:	f80557e3          	bgez	a0,8000524a <create+0xce>
      panic("create dots");
    800052c0:	00003517          	auipc	a0,0x3
    800052c4:	3d050513          	addi	a0,a0,976 # 80008690 <syscalls+0x2f8>
    800052c8:	ffffb097          	auipc	ra,0xffffb
    800052cc:	2ac080e7          	jalr	684(ra) # 80000574 <panic>
    panic("create: dirlink");
    800052d0:	00003517          	auipc	a0,0x3
    800052d4:	3d050513          	addi	a0,a0,976 # 800086a0 <syscalls+0x308>
    800052d8:	ffffb097          	auipc	ra,0xffffb
    800052dc:	29c080e7          	jalr	668(ra) # 80000574 <panic>
    return 0;
    800052e0:	84aa                	mv	s1,a0
    800052e2:	b731                	j	800051ee <create+0x72>

00000000800052e4 <sys_dup>:
{
    800052e4:	7179                	addi	sp,sp,-48
    800052e6:	f406                	sd	ra,40(sp)
    800052e8:	f022                	sd	s0,32(sp)
    800052ea:	ec26                	sd	s1,24(sp)
    800052ec:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052ee:	fd840613          	addi	a2,s0,-40
    800052f2:	4581                	li	a1,0
    800052f4:	4501                	li	a0,0
    800052f6:	00000097          	auipc	ra,0x0
    800052fa:	dd6080e7          	jalr	-554(ra) # 800050cc <argfd>
    return -1;
    800052fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005300:	02054363          	bltz	a0,80005326 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005304:	fd843503          	ld	a0,-40(s0)
    80005308:	00000097          	auipc	ra,0x0
    8000530c:	e2c080e7          	jalr	-468(ra) # 80005134 <fdalloc>
    80005310:	84aa                	mv	s1,a0
    return -1;
    80005312:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005314:	00054963          	bltz	a0,80005326 <sys_dup+0x42>
  filedup(f);
    80005318:	fd843503          	ld	a0,-40(s0)
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	2fa080e7          	jalr	762(ra) # 80004616 <filedup>
  return fd;
    80005324:	87a6                	mv	a5,s1
}
    80005326:	853e                	mv	a0,a5
    80005328:	70a2                	ld	ra,40(sp)
    8000532a:	7402                	ld	s0,32(sp)
    8000532c:	64e2                	ld	s1,24(sp)
    8000532e:	6145                	addi	sp,sp,48
    80005330:	8082                	ret

0000000080005332 <sys_read>:
{
    80005332:	7179                	addi	sp,sp,-48
    80005334:	f406                	sd	ra,40(sp)
    80005336:	f022                	sd	s0,32(sp)
    80005338:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000533a:	fe840613          	addi	a2,s0,-24
    8000533e:	4581                	li	a1,0
    80005340:	4501                	li	a0,0
    80005342:	00000097          	auipc	ra,0x0
    80005346:	d8a080e7          	jalr	-630(ra) # 800050cc <argfd>
    return -1;
    8000534a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534c:	04054163          	bltz	a0,8000538e <sys_read+0x5c>
    80005350:	fe440593          	addi	a1,s0,-28
    80005354:	4509                	li	a0,2
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	862080e7          	jalr	-1950(ra) # 80002bb8 <argint>
    return -1;
    8000535e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005360:	02054763          	bltz	a0,8000538e <sys_read+0x5c>
    80005364:	fd840593          	addi	a1,s0,-40
    80005368:	4505                	li	a0,1
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	870080e7          	jalr	-1936(ra) # 80002bda <argaddr>
    return -1;
    80005372:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005374:	00054d63          	bltz	a0,8000538e <sys_read+0x5c>
  return fileread(f, p, n);
    80005378:	fe442603          	lw	a2,-28(s0)
    8000537c:	fd843583          	ld	a1,-40(s0)
    80005380:	fe843503          	ld	a0,-24(s0)
    80005384:	fffff097          	auipc	ra,0xfffff
    80005388:	41e080e7          	jalr	1054(ra) # 800047a2 <fileread>
    8000538c:	87aa                	mv	a5,a0
}
    8000538e:	853e                	mv	a0,a5
    80005390:	70a2                	ld	ra,40(sp)
    80005392:	7402                	ld	s0,32(sp)
    80005394:	6145                	addi	sp,sp,48
    80005396:	8082                	ret

0000000080005398 <sys_write>:
{
    80005398:	7179                	addi	sp,sp,-48
    8000539a:	f406                	sd	ra,40(sp)
    8000539c:	f022                	sd	s0,32(sp)
    8000539e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a0:	fe840613          	addi	a2,s0,-24
    800053a4:	4581                	li	a1,0
    800053a6:	4501                	li	a0,0
    800053a8:	00000097          	auipc	ra,0x0
    800053ac:	d24080e7          	jalr	-732(ra) # 800050cc <argfd>
    return -1;
    800053b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053b2:	04054163          	bltz	a0,800053f4 <sys_write+0x5c>
    800053b6:	fe440593          	addi	a1,s0,-28
    800053ba:	4509                	li	a0,2
    800053bc:	ffffd097          	auipc	ra,0xffffd
    800053c0:	7fc080e7          	jalr	2044(ra) # 80002bb8 <argint>
    return -1;
    800053c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053c6:	02054763          	bltz	a0,800053f4 <sys_write+0x5c>
    800053ca:	fd840593          	addi	a1,s0,-40
    800053ce:	4505                	li	a0,1
    800053d0:	ffffe097          	auipc	ra,0xffffe
    800053d4:	80a080e7          	jalr	-2038(ra) # 80002bda <argaddr>
    return -1;
    800053d8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053da:	00054d63          	bltz	a0,800053f4 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053de:	fe442603          	lw	a2,-28(s0)
    800053e2:	fd843583          	ld	a1,-40(s0)
    800053e6:	fe843503          	ld	a0,-24(s0)
    800053ea:	fffff097          	auipc	ra,0xfffff
    800053ee:	47a080e7          	jalr	1146(ra) # 80004864 <filewrite>
    800053f2:	87aa                	mv	a5,a0
}
    800053f4:	853e                	mv	a0,a5
    800053f6:	70a2                	ld	ra,40(sp)
    800053f8:	7402                	ld	s0,32(sp)
    800053fa:	6145                	addi	sp,sp,48
    800053fc:	8082                	ret

00000000800053fe <sys_close>:
{
    800053fe:	1101                	addi	sp,sp,-32
    80005400:	ec06                	sd	ra,24(sp)
    80005402:	e822                	sd	s0,16(sp)
    80005404:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005406:	fe040613          	addi	a2,s0,-32
    8000540a:	fec40593          	addi	a1,s0,-20
    8000540e:	4501                	li	a0,0
    80005410:	00000097          	auipc	ra,0x0
    80005414:	cbc080e7          	jalr	-836(ra) # 800050cc <argfd>
    return -1;
    80005418:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000541a:	02054463          	bltz	a0,80005442 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000541e:	ffffc097          	auipc	ra,0xffffc
    80005422:	672080e7          	jalr	1650(ra) # 80001a90 <myproc>
    80005426:	fec42783          	lw	a5,-20(s0)
    8000542a:	07e9                	addi	a5,a5,26
    8000542c:	078e                	slli	a5,a5,0x3
    8000542e:	953e                	add	a0,a0,a5
    80005430:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005434:	fe043503          	ld	a0,-32(s0)
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	230080e7          	jalr	560(ra) # 80004668 <fileclose>
  return 0;
    80005440:	4781                	li	a5,0
}
    80005442:	853e                	mv	a0,a5
    80005444:	60e2                	ld	ra,24(sp)
    80005446:	6442                	ld	s0,16(sp)
    80005448:	6105                	addi	sp,sp,32
    8000544a:	8082                	ret

000000008000544c <sys_fstat>:
{
    8000544c:	1101                	addi	sp,sp,-32
    8000544e:	ec06                	sd	ra,24(sp)
    80005450:	e822                	sd	s0,16(sp)
    80005452:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005454:	fe840613          	addi	a2,s0,-24
    80005458:	4581                	li	a1,0
    8000545a:	4501                	li	a0,0
    8000545c:	00000097          	auipc	ra,0x0
    80005460:	c70080e7          	jalr	-912(ra) # 800050cc <argfd>
    return -1;
    80005464:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005466:	02054563          	bltz	a0,80005490 <sys_fstat+0x44>
    8000546a:	fe040593          	addi	a1,s0,-32
    8000546e:	4505                	li	a0,1
    80005470:	ffffd097          	auipc	ra,0xffffd
    80005474:	76a080e7          	jalr	1898(ra) # 80002bda <argaddr>
    return -1;
    80005478:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000547a:	00054b63          	bltz	a0,80005490 <sys_fstat+0x44>
  return filestat(f, st);
    8000547e:	fe043583          	ld	a1,-32(s0)
    80005482:	fe843503          	ld	a0,-24(s0)
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	2aa080e7          	jalr	682(ra) # 80004730 <filestat>
    8000548e:	87aa                	mv	a5,a0
}
    80005490:	853e                	mv	a0,a5
    80005492:	60e2                	ld	ra,24(sp)
    80005494:	6442                	ld	s0,16(sp)
    80005496:	6105                	addi	sp,sp,32
    80005498:	8082                	ret

000000008000549a <sys_link>:
{
    8000549a:	7169                	addi	sp,sp,-304
    8000549c:	f606                	sd	ra,296(sp)
    8000549e:	f222                	sd	s0,288(sp)
    800054a0:	ee26                	sd	s1,280(sp)
    800054a2:	ea4a                	sd	s2,272(sp)
    800054a4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054a6:	08000613          	li	a2,128
    800054aa:	ed040593          	addi	a1,s0,-304
    800054ae:	4501                	li	a0,0
    800054b0:	ffffd097          	auipc	ra,0xffffd
    800054b4:	74c080e7          	jalr	1868(ra) # 80002bfc <argstr>
    return -1;
    800054b8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ba:	10054e63          	bltz	a0,800055d6 <sys_link+0x13c>
    800054be:	08000613          	li	a2,128
    800054c2:	f5040593          	addi	a1,s0,-176
    800054c6:	4505                	li	a0,1
    800054c8:	ffffd097          	auipc	ra,0xffffd
    800054cc:	734080e7          	jalr	1844(ra) # 80002bfc <argstr>
    return -1;
    800054d0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d2:	10054263          	bltz	a0,800055d6 <sys_link+0x13c>
  begin_op();
    800054d6:	fffff097          	auipc	ra,0xfffff
    800054da:	c90080e7          	jalr	-880(ra) # 80004166 <begin_op>
  if((ip = namei(old)) == 0){
    800054de:	ed040513          	addi	a0,s0,-304
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	a76080e7          	jalr	-1418(ra) # 80003f58 <namei>
    800054ea:	84aa                	mv	s1,a0
    800054ec:	c551                	beqz	a0,80005578 <sys_link+0xde>
  ilock(ip);
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	2ac080e7          	jalr	684(ra) # 8000379a <ilock>
  if(ip->type == T_DIR){
    800054f6:	04449703          	lh	a4,68(s1)
    800054fa:	4785                	li	a5,1
    800054fc:	08f70463          	beq	a4,a5,80005584 <sys_link+0xea>
  ip->nlink++;
    80005500:	04a4d783          	lhu	a5,74(s1)
    80005504:	2785                	addiw	a5,a5,1
    80005506:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000550a:	8526                	mv	a0,s1
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	1c2080e7          	jalr	450(ra) # 800036ce <iupdate>
  iunlock(ip);
    80005514:	8526                	mv	a0,s1
    80005516:	ffffe097          	auipc	ra,0xffffe
    8000551a:	348080e7          	jalr	840(ra) # 8000385e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000551e:	fd040593          	addi	a1,s0,-48
    80005522:	f5040513          	addi	a0,s0,-176
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	a50080e7          	jalr	-1456(ra) # 80003f76 <nameiparent>
    8000552e:	892a                	mv	s2,a0
    80005530:	c935                	beqz	a0,800055a4 <sys_link+0x10a>
  ilock(dp);
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	268080e7          	jalr	616(ra) # 8000379a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000553a:	00092703          	lw	a4,0(s2)
    8000553e:	409c                	lw	a5,0(s1)
    80005540:	04f71d63          	bne	a4,a5,8000559a <sys_link+0x100>
    80005544:	40d0                	lw	a2,4(s1)
    80005546:	fd040593          	addi	a1,s0,-48
    8000554a:	854a                	mv	a0,s2
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	94a080e7          	jalr	-1718(ra) # 80003e96 <dirlink>
    80005554:	04054363          	bltz	a0,8000559a <sys_link+0x100>
  iunlockput(dp);
    80005558:	854a                	mv	a0,s2
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	4a4080e7          	jalr	1188(ra) # 800039fe <iunlockput>
  iput(ip);
    80005562:	8526                	mv	a0,s1
    80005564:	ffffe097          	auipc	ra,0xffffe
    80005568:	3f2080e7          	jalr	1010(ra) # 80003956 <iput>
  end_op();
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	c7a080e7          	jalr	-902(ra) # 800041e6 <end_op>
  return 0;
    80005574:	4781                	li	a5,0
    80005576:	a085                	j	800055d6 <sys_link+0x13c>
    end_op();
    80005578:	fffff097          	auipc	ra,0xfffff
    8000557c:	c6e080e7          	jalr	-914(ra) # 800041e6 <end_op>
    return -1;
    80005580:	57fd                	li	a5,-1
    80005582:	a891                	j	800055d6 <sys_link+0x13c>
    iunlockput(ip);
    80005584:	8526                	mv	a0,s1
    80005586:	ffffe097          	auipc	ra,0xffffe
    8000558a:	478080e7          	jalr	1144(ra) # 800039fe <iunlockput>
    end_op();
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	c58080e7          	jalr	-936(ra) # 800041e6 <end_op>
    return -1;
    80005596:	57fd                	li	a5,-1
    80005598:	a83d                	j	800055d6 <sys_link+0x13c>
    iunlockput(dp);
    8000559a:	854a                	mv	a0,s2
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	462080e7          	jalr	1122(ra) # 800039fe <iunlockput>
  ilock(ip);
    800055a4:	8526                	mv	a0,s1
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	1f4080e7          	jalr	500(ra) # 8000379a <ilock>
  ip->nlink--;
    800055ae:	04a4d783          	lhu	a5,74(s1)
    800055b2:	37fd                	addiw	a5,a5,-1
    800055b4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	114080e7          	jalr	276(ra) # 800036ce <iupdate>
  iunlockput(ip);
    800055c2:	8526                	mv	a0,s1
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	43a080e7          	jalr	1082(ra) # 800039fe <iunlockput>
  end_op();
    800055cc:	fffff097          	auipc	ra,0xfffff
    800055d0:	c1a080e7          	jalr	-998(ra) # 800041e6 <end_op>
  return -1;
    800055d4:	57fd                	li	a5,-1
}
    800055d6:	853e                	mv	a0,a5
    800055d8:	70b2                	ld	ra,296(sp)
    800055da:	7412                	ld	s0,288(sp)
    800055dc:	64f2                	ld	s1,280(sp)
    800055de:	6952                	ld	s2,272(sp)
    800055e0:	6155                	addi	sp,sp,304
    800055e2:	8082                	ret

00000000800055e4 <sys_unlink>:
{
    800055e4:	7151                	addi	sp,sp,-240
    800055e6:	f586                	sd	ra,232(sp)
    800055e8:	f1a2                	sd	s0,224(sp)
    800055ea:	eda6                	sd	s1,216(sp)
    800055ec:	e9ca                	sd	s2,208(sp)
    800055ee:	e5ce                	sd	s3,200(sp)
    800055f0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055f2:	08000613          	li	a2,128
    800055f6:	f3040593          	addi	a1,s0,-208
    800055fa:	4501                	li	a0,0
    800055fc:	ffffd097          	auipc	ra,0xffffd
    80005600:	600080e7          	jalr	1536(ra) # 80002bfc <argstr>
    80005604:	16054f63          	bltz	a0,80005782 <sys_unlink+0x19e>
  begin_op();
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	b5e080e7          	jalr	-1186(ra) # 80004166 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005610:	fb040593          	addi	a1,s0,-80
    80005614:	f3040513          	addi	a0,s0,-208
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	95e080e7          	jalr	-1698(ra) # 80003f76 <nameiparent>
    80005620:	89aa                	mv	s3,a0
    80005622:	c979                	beqz	a0,800056f8 <sys_unlink+0x114>
  ilock(dp);
    80005624:	ffffe097          	auipc	ra,0xffffe
    80005628:	176080e7          	jalr	374(ra) # 8000379a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000562c:	00003597          	auipc	a1,0x3
    80005630:	05458593          	addi	a1,a1,84 # 80008680 <syscalls+0x2e8>
    80005634:	fb040513          	addi	a0,s0,-80
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	62c080e7          	jalr	1580(ra) # 80003c64 <namecmp>
    80005640:	14050863          	beqz	a0,80005790 <sys_unlink+0x1ac>
    80005644:	00003597          	auipc	a1,0x3
    80005648:	04458593          	addi	a1,a1,68 # 80008688 <syscalls+0x2f0>
    8000564c:	fb040513          	addi	a0,s0,-80
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	614080e7          	jalr	1556(ra) # 80003c64 <namecmp>
    80005658:	12050c63          	beqz	a0,80005790 <sys_unlink+0x1ac>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000565c:	f2c40613          	addi	a2,s0,-212
    80005660:	fb040593          	addi	a1,s0,-80
    80005664:	854e                	mv	a0,s3
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	618080e7          	jalr	1560(ra) # 80003c7e <dirlookup>
    8000566e:	84aa                	mv	s1,a0
    80005670:	12050063          	beqz	a0,80005790 <sys_unlink+0x1ac>
  ilock(ip);
    80005674:	ffffe097          	auipc	ra,0xffffe
    80005678:	126080e7          	jalr	294(ra) # 8000379a <ilock>
  if(ip->nlink < 1)
    8000567c:	04a49783          	lh	a5,74(s1)
    80005680:	08f05263          	blez	a5,80005704 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005684:	04449703          	lh	a4,68(s1)
    80005688:	4785                	li	a5,1
    8000568a:	08f70563          	beq	a4,a5,80005714 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000568e:	4641                	li	a2,16
    80005690:	4581                	li	a1,0
    80005692:	fc040513          	addi	a0,s0,-64
    80005696:	ffffb097          	auipc	ra,0xffffb
    8000569a:	6c8080e7          	jalr	1736(ra) # 80000d5e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000569e:	4741                	li	a4,16
    800056a0:	f2c42683          	lw	a3,-212(s0)
    800056a4:	fc040613          	addi	a2,s0,-64
    800056a8:	4581                	li	a1,0
    800056aa:	854e                	mv	a0,s3
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	49c080e7          	jalr	1180(ra) # 80003b48 <writei>
    800056b4:	47c1                	li	a5,16
    800056b6:	0af51363          	bne	a0,a5,8000575c <sys_unlink+0x178>
  if(ip->type == T_DIR){
    800056ba:	04449703          	lh	a4,68(s1)
    800056be:	4785                	li	a5,1
    800056c0:	0af70663          	beq	a4,a5,8000576c <sys_unlink+0x188>
  iunlockput(dp);
    800056c4:	854e                	mv	a0,s3
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	338080e7          	jalr	824(ra) # 800039fe <iunlockput>
  ip->nlink--;
    800056ce:	04a4d783          	lhu	a5,74(s1)
    800056d2:	37fd                	addiw	a5,a5,-1
    800056d4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	ff4080e7          	jalr	-12(ra) # 800036ce <iupdate>
  iunlockput(ip);
    800056e2:	8526                	mv	a0,s1
    800056e4:	ffffe097          	auipc	ra,0xffffe
    800056e8:	31a080e7          	jalr	794(ra) # 800039fe <iunlockput>
  end_op();
    800056ec:	fffff097          	auipc	ra,0xfffff
    800056f0:	afa080e7          	jalr	-1286(ra) # 800041e6 <end_op>
  return 0;
    800056f4:	4501                	li	a0,0
    800056f6:	a07d                	j	800057a4 <sys_unlink+0x1c0>
    end_op();
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	aee080e7          	jalr	-1298(ra) # 800041e6 <end_op>
    return -1;
    80005700:	557d                	li	a0,-1
    80005702:	a04d                	j	800057a4 <sys_unlink+0x1c0>
    panic("unlink: nlink < 1");
    80005704:	00003517          	auipc	a0,0x3
    80005708:	fac50513          	addi	a0,a0,-84 # 800086b0 <syscalls+0x318>
    8000570c:	ffffb097          	auipc	ra,0xffffb
    80005710:	e68080e7          	jalr	-408(ra) # 80000574 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005714:	44f8                	lw	a4,76(s1)
    80005716:	02000793          	li	a5,32
    8000571a:	f6e7fae3          	bleu	a4,a5,8000568e <sys_unlink+0xaa>
    8000571e:	02000913          	li	s2,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005722:	4741                	li	a4,16
    80005724:	86ca                	mv	a3,s2
    80005726:	f1840613          	addi	a2,s0,-232
    8000572a:	4581                	li	a1,0
    8000572c:	8526                	mv	a0,s1
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	322080e7          	jalr	802(ra) # 80003a50 <readi>
    80005736:	47c1                	li	a5,16
    80005738:	00f51a63          	bne	a0,a5,8000574c <sys_unlink+0x168>
    if(de.inum != 0)
    8000573c:	f1845783          	lhu	a5,-232(s0)
    80005740:	e3b9                	bnez	a5,80005786 <sys_unlink+0x1a2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005742:	2941                	addiw	s2,s2,16
    80005744:	44fc                	lw	a5,76(s1)
    80005746:	fcf96ee3          	bltu	s2,a5,80005722 <sys_unlink+0x13e>
    8000574a:	b791                	j	8000568e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000574c:	00003517          	auipc	a0,0x3
    80005750:	f7c50513          	addi	a0,a0,-132 # 800086c8 <syscalls+0x330>
    80005754:	ffffb097          	auipc	ra,0xffffb
    80005758:	e20080e7          	jalr	-480(ra) # 80000574 <panic>
    panic("unlink: writei");
    8000575c:	00003517          	auipc	a0,0x3
    80005760:	f8450513          	addi	a0,a0,-124 # 800086e0 <syscalls+0x348>
    80005764:	ffffb097          	auipc	ra,0xffffb
    80005768:	e10080e7          	jalr	-496(ra) # 80000574 <panic>
    dp->nlink--;
    8000576c:	04a9d783          	lhu	a5,74(s3)
    80005770:	37fd                	addiw	a5,a5,-1
    80005772:	04f99523          	sh	a5,74(s3)
    iupdate(dp);
    80005776:	854e                	mv	a0,s3
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	f56080e7          	jalr	-170(ra) # 800036ce <iupdate>
    80005780:	b791                	j	800056c4 <sys_unlink+0xe0>
    return -1;
    80005782:	557d                	li	a0,-1
    80005784:	a005                	j	800057a4 <sys_unlink+0x1c0>
    iunlockput(ip);
    80005786:	8526                	mv	a0,s1
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	276080e7          	jalr	630(ra) # 800039fe <iunlockput>
  iunlockput(dp);
    80005790:	854e                	mv	a0,s3
    80005792:	ffffe097          	auipc	ra,0xffffe
    80005796:	26c080e7          	jalr	620(ra) # 800039fe <iunlockput>
  end_op();
    8000579a:	fffff097          	auipc	ra,0xfffff
    8000579e:	a4c080e7          	jalr	-1460(ra) # 800041e6 <end_op>
  return -1;
    800057a2:	557d                	li	a0,-1
}
    800057a4:	70ae                	ld	ra,232(sp)
    800057a6:	740e                	ld	s0,224(sp)
    800057a8:	64ee                	ld	s1,216(sp)
    800057aa:	694e                	ld	s2,208(sp)
    800057ac:	69ae                	ld	s3,200(sp)
    800057ae:	616d                	addi	sp,sp,240
    800057b0:	8082                	ret

00000000800057b2 <sys_open>:

uint64
sys_open(void)
{
    800057b2:	7131                	addi	sp,sp,-192
    800057b4:	fd06                	sd	ra,184(sp)
    800057b6:	f922                	sd	s0,176(sp)
    800057b8:	f526                	sd	s1,168(sp)
    800057ba:	f14a                	sd	s2,160(sp)
    800057bc:	ed4e                	sd	s3,152(sp)
    800057be:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057c0:	08000613          	li	a2,128
    800057c4:	f5040593          	addi	a1,s0,-176
    800057c8:	4501                	li	a0,0
    800057ca:	ffffd097          	auipc	ra,0xffffd
    800057ce:	432080e7          	jalr	1074(ra) # 80002bfc <argstr>
    return -1;
    800057d2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057d4:	0c054163          	bltz	a0,80005896 <sys_open+0xe4>
    800057d8:	f4c40593          	addi	a1,s0,-180
    800057dc:	4505                	li	a0,1
    800057de:	ffffd097          	auipc	ra,0xffffd
    800057e2:	3da080e7          	jalr	986(ra) # 80002bb8 <argint>
    800057e6:	0a054863          	bltz	a0,80005896 <sys_open+0xe4>

  begin_op();
    800057ea:	fffff097          	auipc	ra,0xfffff
    800057ee:	97c080e7          	jalr	-1668(ra) # 80004166 <begin_op>

  if(omode & O_CREATE){
    800057f2:	f4c42783          	lw	a5,-180(s0)
    800057f6:	2007f793          	andi	a5,a5,512
    800057fa:	cbdd                	beqz	a5,800058b0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057fc:	4681                	li	a3,0
    800057fe:	4601                	li	a2,0
    80005800:	4589                	li	a1,2
    80005802:	f5040513          	addi	a0,s0,-176
    80005806:	00000097          	auipc	ra,0x0
    8000580a:	976080e7          	jalr	-1674(ra) # 8000517c <create>
    8000580e:	892a                	mv	s2,a0
    if(ip == 0){
    80005810:	c959                	beqz	a0,800058a6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005812:	04491703          	lh	a4,68(s2)
    80005816:	478d                	li	a5,3
    80005818:	00f71763          	bne	a4,a5,80005826 <sys_open+0x74>
    8000581c:	04695703          	lhu	a4,70(s2)
    80005820:	47a5                	li	a5,9
    80005822:	0ce7ec63          	bltu	a5,a4,800058fa <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	d72080e7          	jalr	-654(ra) # 80004598 <filealloc>
    8000582e:	89aa                	mv	s3,a0
    80005830:	10050263          	beqz	a0,80005934 <sys_open+0x182>
    80005834:	00000097          	auipc	ra,0x0
    80005838:	900080e7          	jalr	-1792(ra) # 80005134 <fdalloc>
    8000583c:	84aa                	mv	s1,a0
    8000583e:	0e054663          	bltz	a0,8000592a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005842:	04491703          	lh	a4,68(s2)
    80005846:	478d                	li	a5,3
    80005848:	0cf70463          	beq	a4,a5,80005910 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000584c:	4789                	li	a5,2
    8000584e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005852:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005856:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000585a:	f4c42783          	lw	a5,-180(s0)
    8000585e:	0017c713          	xori	a4,a5,1
    80005862:	8b05                	andi	a4,a4,1
    80005864:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005868:	0037f713          	andi	a4,a5,3
    8000586c:	00e03733          	snez	a4,a4
    80005870:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005874:	4007f793          	andi	a5,a5,1024
    80005878:	c791                	beqz	a5,80005884 <sys_open+0xd2>
    8000587a:	04491703          	lh	a4,68(s2)
    8000587e:	4789                	li	a5,2
    80005880:	08f70f63          	beq	a4,a5,8000591e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005884:	854a                	mv	a0,s2
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	fd8080e7          	jalr	-40(ra) # 8000385e <iunlock>
  end_op();
    8000588e:	fffff097          	auipc	ra,0xfffff
    80005892:	958080e7          	jalr	-1704(ra) # 800041e6 <end_op>

  return fd;
}
    80005896:	8526                	mv	a0,s1
    80005898:	70ea                	ld	ra,184(sp)
    8000589a:	744a                	ld	s0,176(sp)
    8000589c:	74aa                	ld	s1,168(sp)
    8000589e:	790a                	ld	s2,160(sp)
    800058a0:	69ea                	ld	s3,152(sp)
    800058a2:	6129                	addi	sp,sp,192
    800058a4:	8082                	ret
      end_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	940080e7          	jalr	-1728(ra) # 800041e6 <end_op>
      return -1;
    800058ae:	b7e5                	j	80005896 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058b0:	f5040513          	addi	a0,s0,-176
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	6a4080e7          	jalr	1700(ra) # 80003f58 <namei>
    800058bc:	892a                	mv	s2,a0
    800058be:	c905                	beqz	a0,800058ee <sys_open+0x13c>
    ilock(ip);
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	eda080e7          	jalr	-294(ra) # 8000379a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058c8:	04491703          	lh	a4,68(s2)
    800058cc:	4785                	li	a5,1
    800058ce:	f4f712e3          	bne	a4,a5,80005812 <sys_open+0x60>
    800058d2:	f4c42783          	lw	a5,-180(s0)
    800058d6:	dba1                	beqz	a5,80005826 <sys_open+0x74>
      iunlockput(ip);
    800058d8:	854a                	mv	a0,s2
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	124080e7          	jalr	292(ra) # 800039fe <iunlockput>
      end_op();
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	904080e7          	jalr	-1788(ra) # 800041e6 <end_op>
      return -1;
    800058ea:	54fd                	li	s1,-1
    800058ec:	b76d                	j	80005896 <sys_open+0xe4>
      end_op();
    800058ee:	fffff097          	auipc	ra,0xfffff
    800058f2:	8f8080e7          	jalr	-1800(ra) # 800041e6 <end_op>
      return -1;
    800058f6:	54fd                	li	s1,-1
    800058f8:	bf79                	j	80005896 <sys_open+0xe4>
    iunlockput(ip);
    800058fa:	854a                	mv	a0,s2
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	102080e7          	jalr	258(ra) # 800039fe <iunlockput>
    end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	8e2080e7          	jalr	-1822(ra) # 800041e6 <end_op>
    return -1;
    8000590c:	54fd                	li	s1,-1
    8000590e:	b761                	j	80005896 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005910:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005914:	04691783          	lh	a5,70(s2)
    80005918:	02f99223          	sh	a5,36(s3)
    8000591c:	bf2d                	j	80005856 <sys_open+0xa4>
    itrunc(ip);
    8000591e:	854a                	mv	a0,s2
    80005920:	ffffe097          	auipc	ra,0xffffe
    80005924:	f8a080e7          	jalr	-118(ra) # 800038aa <itrunc>
    80005928:	bfb1                	j	80005884 <sys_open+0xd2>
      fileclose(f);
    8000592a:	854e                	mv	a0,s3
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	d3c080e7          	jalr	-708(ra) # 80004668 <fileclose>
    iunlockput(ip);
    80005934:	854a                	mv	a0,s2
    80005936:	ffffe097          	auipc	ra,0xffffe
    8000593a:	0c8080e7          	jalr	200(ra) # 800039fe <iunlockput>
    end_op();
    8000593e:	fffff097          	auipc	ra,0xfffff
    80005942:	8a8080e7          	jalr	-1880(ra) # 800041e6 <end_op>
    return -1;
    80005946:	54fd                	li	s1,-1
    80005948:	b7b9                	j	80005896 <sys_open+0xe4>

000000008000594a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000594a:	7175                	addi	sp,sp,-144
    8000594c:	e506                	sd	ra,136(sp)
    8000594e:	e122                	sd	s0,128(sp)
    80005950:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	814080e7          	jalr	-2028(ra) # 80004166 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000595a:	08000613          	li	a2,128
    8000595e:	f7040593          	addi	a1,s0,-144
    80005962:	4501                	li	a0,0
    80005964:	ffffd097          	auipc	ra,0xffffd
    80005968:	298080e7          	jalr	664(ra) # 80002bfc <argstr>
    8000596c:	02054963          	bltz	a0,8000599e <sys_mkdir+0x54>
    80005970:	4681                	li	a3,0
    80005972:	4601                	li	a2,0
    80005974:	4585                	li	a1,1
    80005976:	f7040513          	addi	a0,s0,-144
    8000597a:	00000097          	auipc	ra,0x0
    8000597e:	802080e7          	jalr	-2046(ra) # 8000517c <create>
    80005982:	cd11                	beqz	a0,8000599e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	07a080e7          	jalr	122(ra) # 800039fe <iunlockput>
  end_op();
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	85a080e7          	jalr	-1958(ra) # 800041e6 <end_op>
  return 0;
    80005994:	4501                	li	a0,0
}
    80005996:	60aa                	ld	ra,136(sp)
    80005998:	640a                	ld	s0,128(sp)
    8000599a:	6149                	addi	sp,sp,144
    8000599c:	8082                	ret
    end_op();
    8000599e:	fffff097          	auipc	ra,0xfffff
    800059a2:	848080e7          	jalr	-1976(ra) # 800041e6 <end_op>
    return -1;
    800059a6:	557d                	li	a0,-1
    800059a8:	b7fd                	j	80005996 <sys_mkdir+0x4c>

00000000800059aa <sys_mknod>:

uint64
sys_mknod(void)
{
    800059aa:	7135                	addi	sp,sp,-160
    800059ac:	ed06                	sd	ra,152(sp)
    800059ae:	e922                	sd	s0,144(sp)
    800059b0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059b2:	ffffe097          	auipc	ra,0xffffe
    800059b6:	7b4080e7          	jalr	1972(ra) # 80004166 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059ba:	08000613          	li	a2,128
    800059be:	f7040593          	addi	a1,s0,-144
    800059c2:	4501                	li	a0,0
    800059c4:	ffffd097          	auipc	ra,0xffffd
    800059c8:	238080e7          	jalr	568(ra) # 80002bfc <argstr>
    800059cc:	04054a63          	bltz	a0,80005a20 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059d0:	f6c40593          	addi	a1,s0,-148
    800059d4:	4505                	li	a0,1
    800059d6:	ffffd097          	auipc	ra,0xffffd
    800059da:	1e2080e7          	jalr	482(ra) # 80002bb8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059de:	04054163          	bltz	a0,80005a20 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059e2:	f6840593          	addi	a1,s0,-152
    800059e6:	4509                	li	a0,2
    800059e8:	ffffd097          	auipc	ra,0xffffd
    800059ec:	1d0080e7          	jalr	464(ra) # 80002bb8 <argint>
     argint(1, &major) < 0 ||
    800059f0:	02054863          	bltz	a0,80005a20 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059f4:	f6841683          	lh	a3,-152(s0)
    800059f8:	f6c41603          	lh	a2,-148(s0)
    800059fc:	458d                	li	a1,3
    800059fe:	f7040513          	addi	a0,s0,-144
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	77a080e7          	jalr	1914(ra) # 8000517c <create>
     argint(2, &minor) < 0 ||
    80005a0a:	c919                	beqz	a0,80005a20 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	ff2080e7          	jalr	-14(ra) # 800039fe <iunlockput>
  end_op();
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	7d2080e7          	jalr	2002(ra) # 800041e6 <end_op>
  return 0;
    80005a1c:	4501                	li	a0,0
    80005a1e:	a031                	j	80005a2a <sys_mknod+0x80>
    end_op();
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	7c6080e7          	jalr	1990(ra) # 800041e6 <end_op>
    return -1;
    80005a28:	557d                	li	a0,-1
}
    80005a2a:	60ea                	ld	ra,152(sp)
    80005a2c:	644a                	ld	s0,144(sp)
    80005a2e:	610d                	addi	sp,sp,160
    80005a30:	8082                	ret

0000000080005a32 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a32:	7135                	addi	sp,sp,-160
    80005a34:	ed06                	sd	ra,152(sp)
    80005a36:	e922                	sd	s0,144(sp)
    80005a38:	e526                	sd	s1,136(sp)
    80005a3a:	e14a                	sd	s2,128(sp)
    80005a3c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a3e:	ffffc097          	auipc	ra,0xffffc
    80005a42:	052080e7          	jalr	82(ra) # 80001a90 <myproc>
    80005a46:	892a                	mv	s2,a0
  
  begin_op();
    80005a48:	ffffe097          	auipc	ra,0xffffe
    80005a4c:	71e080e7          	jalr	1822(ra) # 80004166 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a50:	08000613          	li	a2,128
    80005a54:	f6040593          	addi	a1,s0,-160
    80005a58:	4501                	li	a0,0
    80005a5a:	ffffd097          	auipc	ra,0xffffd
    80005a5e:	1a2080e7          	jalr	418(ra) # 80002bfc <argstr>
    80005a62:	04054b63          	bltz	a0,80005ab8 <sys_chdir+0x86>
    80005a66:	f6040513          	addi	a0,s0,-160
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	4ee080e7          	jalr	1262(ra) # 80003f58 <namei>
    80005a72:	84aa                	mv	s1,a0
    80005a74:	c131                	beqz	a0,80005ab8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a76:	ffffe097          	auipc	ra,0xffffe
    80005a7a:	d24080e7          	jalr	-732(ra) # 8000379a <ilock>
  if(ip->type != T_DIR){
    80005a7e:	04449703          	lh	a4,68(s1)
    80005a82:	4785                	li	a5,1
    80005a84:	04f71063          	bne	a4,a5,80005ac4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a88:	8526                	mv	a0,s1
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	dd4080e7          	jalr	-556(ra) # 8000385e <iunlock>
  iput(p->cwd);
    80005a92:	15093503          	ld	a0,336(s2)
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	ec0080e7          	jalr	-320(ra) # 80003956 <iput>
  end_op();
    80005a9e:	ffffe097          	auipc	ra,0xffffe
    80005aa2:	748080e7          	jalr	1864(ra) # 800041e6 <end_op>
  p->cwd = ip;
    80005aa6:	14993823          	sd	s1,336(s2)
  return 0;
    80005aaa:	4501                	li	a0,0
}
    80005aac:	60ea                	ld	ra,152(sp)
    80005aae:	644a                	ld	s0,144(sp)
    80005ab0:	64aa                	ld	s1,136(sp)
    80005ab2:	690a                	ld	s2,128(sp)
    80005ab4:	610d                	addi	sp,sp,160
    80005ab6:	8082                	ret
    end_op();
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	72e080e7          	jalr	1838(ra) # 800041e6 <end_op>
    return -1;
    80005ac0:	557d                	li	a0,-1
    80005ac2:	b7ed                	j	80005aac <sys_chdir+0x7a>
    iunlockput(ip);
    80005ac4:	8526                	mv	a0,s1
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	f38080e7          	jalr	-200(ra) # 800039fe <iunlockput>
    end_op();
    80005ace:	ffffe097          	auipc	ra,0xffffe
    80005ad2:	718080e7          	jalr	1816(ra) # 800041e6 <end_op>
    return -1;
    80005ad6:	557d                	li	a0,-1
    80005ad8:	bfd1                	j	80005aac <sys_chdir+0x7a>

0000000080005ada <sys_exec>:

uint64
sys_exec(void)
{
    80005ada:	7145                	addi	sp,sp,-464
    80005adc:	e786                	sd	ra,456(sp)
    80005ade:	e3a2                	sd	s0,448(sp)
    80005ae0:	ff26                	sd	s1,440(sp)
    80005ae2:	fb4a                	sd	s2,432(sp)
    80005ae4:	f74e                	sd	s3,424(sp)
    80005ae6:	f352                	sd	s4,416(sp)
    80005ae8:	ef56                	sd	s5,408(sp)
    80005aea:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005aec:	08000613          	li	a2,128
    80005af0:	f4040593          	addi	a1,s0,-192
    80005af4:	4501                	li	a0,0
    80005af6:	ffffd097          	auipc	ra,0xffffd
    80005afa:	106080e7          	jalr	262(ra) # 80002bfc <argstr>
    return -1;
    80005afe:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b00:	0e054c63          	bltz	a0,80005bf8 <sys_exec+0x11e>
    80005b04:	e3840593          	addi	a1,s0,-456
    80005b08:	4505                	li	a0,1
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	0d0080e7          	jalr	208(ra) # 80002bda <argaddr>
    80005b12:	0e054363          	bltz	a0,80005bf8 <sys_exec+0x11e>
  }
  memset(argv, 0, sizeof(argv));
    80005b16:	e4040913          	addi	s2,s0,-448
    80005b1a:	10000613          	li	a2,256
    80005b1e:	4581                	li	a1,0
    80005b20:	854a                	mv	a0,s2
    80005b22:	ffffb097          	auipc	ra,0xffffb
    80005b26:	23c080e7          	jalr	572(ra) # 80000d5e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b2a:	89ca                	mv	s3,s2
  memset(argv, 0, sizeof(argv));
    80005b2c:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    80005b2e:	02000a93          	li	s5,32
    80005b32:	00048a1b          	sext.w	s4,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b36:	00349513          	slli	a0,s1,0x3
    80005b3a:	e3040593          	addi	a1,s0,-464
    80005b3e:	e3843783          	ld	a5,-456(s0)
    80005b42:	953e                	add	a0,a0,a5
    80005b44:	ffffd097          	auipc	ra,0xffffd
    80005b48:	fd8080e7          	jalr	-40(ra) # 80002b1c <fetchaddr>
    80005b4c:	02054a63          	bltz	a0,80005b80 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b50:	e3043783          	ld	a5,-464(s0)
    80005b54:	cfa9                	beqz	a5,80005bae <sys_exec+0xd4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b56:	ffffb097          	auipc	ra,0xffffb
    80005b5a:	01c080e7          	jalr	28(ra) # 80000b72 <kalloc>
    80005b5e:	00a93023          	sd	a0,0(s2)
    if(argv[i] == 0)
    80005b62:	cd19                	beqz	a0,80005b80 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b64:	6605                	lui	a2,0x1
    80005b66:	85aa                	mv	a1,a0
    80005b68:	e3043503          	ld	a0,-464(s0)
    80005b6c:	ffffd097          	auipc	ra,0xffffd
    80005b70:	004080e7          	jalr	4(ra) # 80002b70 <fetchstr>
    80005b74:	00054663          	bltz	a0,80005b80 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b78:	0485                	addi	s1,s1,1
    80005b7a:	0921                	addi	s2,s2,8
    80005b7c:	fb549be3          	bne	s1,s5,80005b32 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b80:	e4043503          	ld	a0,-448(s0)
    kfree(argv[i]);
  return -1;
    80005b84:	597d                	li	s2,-1
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b86:	c92d                	beqz	a0,80005bf8 <sys_exec+0x11e>
    kfree(argv[i]);
    80005b88:	ffffb097          	auipc	ra,0xffffb
    80005b8c:	eea080e7          	jalr	-278(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b90:	e4840493          	addi	s1,s0,-440
    80005b94:	10098993          	addi	s3,s3,256
    80005b98:	6088                	ld	a0,0(s1)
    80005b9a:	cd31                	beqz	a0,80005bf6 <sys_exec+0x11c>
    kfree(argv[i]);
    80005b9c:	ffffb097          	auipc	ra,0xffffb
    80005ba0:	ed6080e7          	jalr	-298(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba4:	04a1                	addi	s1,s1,8
    80005ba6:	ff3499e3          	bne	s1,s3,80005b98 <sys_exec+0xbe>
  return -1;
    80005baa:	597d                	li	s2,-1
    80005bac:	a0b1                	j	80005bf8 <sys_exec+0x11e>
      argv[i] = 0;
    80005bae:	0a0e                	slli	s4,s4,0x3
    80005bb0:	fc040793          	addi	a5,s0,-64
    80005bb4:	9a3e                	add	s4,s4,a5
    80005bb6:	e80a3023          	sd	zero,-384(s4)
  int ret = exec(path, argv);
    80005bba:	e4040593          	addi	a1,s0,-448
    80005bbe:	f4040513          	addi	a0,s0,-192
    80005bc2:	fffff097          	auipc	ra,0xfffff
    80005bc6:	166080e7          	jalr	358(ra) # 80004d28 <exec>
    80005bca:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bcc:	e4043503          	ld	a0,-448(s0)
    80005bd0:	c505                	beqz	a0,80005bf8 <sys_exec+0x11e>
    kfree(argv[i]);
    80005bd2:	ffffb097          	auipc	ra,0xffffb
    80005bd6:	ea0080e7          	jalr	-352(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bda:	e4840493          	addi	s1,s0,-440
    80005bde:	10098993          	addi	s3,s3,256
    80005be2:	6088                	ld	a0,0(s1)
    80005be4:	c911                	beqz	a0,80005bf8 <sys_exec+0x11e>
    kfree(argv[i]);
    80005be6:	ffffb097          	auipc	ra,0xffffb
    80005bea:	e8c080e7          	jalr	-372(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bee:	04a1                	addi	s1,s1,8
    80005bf0:	ff3499e3          	bne	s1,s3,80005be2 <sys_exec+0x108>
    80005bf4:	a011                	j	80005bf8 <sys_exec+0x11e>
  return -1;
    80005bf6:	597d                	li	s2,-1
}
    80005bf8:	854a                	mv	a0,s2
    80005bfa:	60be                	ld	ra,456(sp)
    80005bfc:	641e                	ld	s0,448(sp)
    80005bfe:	74fa                	ld	s1,440(sp)
    80005c00:	795a                	ld	s2,432(sp)
    80005c02:	79ba                	ld	s3,424(sp)
    80005c04:	7a1a                	ld	s4,416(sp)
    80005c06:	6afa                	ld	s5,408(sp)
    80005c08:	6179                	addi	sp,sp,464
    80005c0a:	8082                	ret

0000000080005c0c <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c0c:	7139                	addi	sp,sp,-64
    80005c0e:	fc06                	sd	ra,56(sp)
    80005c10:	f822                	sd	s0,48(sp)
    80005c12:	f426                	sd	s1,40(sp)
    80005c14:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c16:	ffffc097          	auipc	ra,0xffffc
    80005c1a:	e7a080e7          	jalr	-390(ra) # 80001a90 <myproc>
    80005c1e:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c20:	fd840593          	addi	a1,s0,-40
    80005c24:	4501                	li	a0,0
    80005c26:	ffffd097          	auipc	ra,0xffffd
    80005c2a:	fb4080e7          	jalr	-76(ra) # 80002bda <argaddr>
    return -1;
    80005c2e:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c30:	0c054f63          	bltz	a0,80005d0e <sys_pipe+0x102>
  if(pipealloc(&rf, &wf) < 0)
    80005c34:	fc840593          	addi	a1,s0,-56
    80005c38:	fd040513          	addi	a0,s0,-48
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	d74080e7          	jalr	-652(ra) # 800049b0 <pipealloc>
    return -1;
    80005c44:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c46:	0c054463          	bltz	a0,80005d0e <sys_pipe+0x102>
  fd0 = -1;
    80005c4a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c4e:	fd043503          	ld	a0,-48(s0)
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	4e2080e7          	jalr	1250(ra) # 80005134 <fdalloc>
    80005c5a:	fca42223          	sw	a0,-60(s0)
    80005c5e:	08054b63          	bltz	a0,80005cf4 <sys_pipe+0xe8>
    80005c62:	fc843503          	ld	a0,-56(s0)
    80005c66:	fffff097          	auipc	ra,0xfffff
    80005c6a:	4ce080e7          	jalr	1230(ra) # 80005134 <fdalloc>
    80005c6e:	fca42023          	sw	a0,-64(s0)
    80005c72:	06054863          	bltz	a0,80005ce2 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c76:	4691                	li	a3,4
    80005c78:	fc440613          	addi	a2,s0,-60
    80005c7c:	fd843583          	ld	a1,-40(s0)
    80005c80:	68a8                	ld	a0,80(s1)
    80005c82:	ffffc097          	auipc	ra,0xffffc
    80005c86:	aea080e7          	jalr	-1302(ra) # 8000176c <copyout>
    80005c8a:	02054063          	bltz	a0,80005caa <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c8e:	4691                	li	a3,4
    80005c90:	fc040613          	addi	a2,s0,-64
    80005c94:	fd843583          	ld	a1,-40(s0)
    80005c98:	0591                	addi	a1,a1,4
    80005c9a:	68a8                	ld	a0,80(s1)
    80005c9c:	ffffc097          	auipc	ra,0xffffc
    80005ca0:	ad0080e7          	jalr	-1328(ra) # 8000176c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ca4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca6:	06055463          	bgez	a0,80005d0e <sys_pipe+0x102>
    p->ofile[fd0] = 0;
    80005caa:	fc442783          	lw	a5,-60(s0)
    80005cae:	07e9                	addi	a5,a5,26
    80005cb0:	078e                	slli	a5,a5,0x3
    80005cb2:	97a6                	add	a5,a5,s1
    80005cb4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cb8:	fc042783          	lw	a5,-64(s0)
    80005cbc:	07e9                	addi	a5,a5,26
    80005cbe:	078e                	slli	a5,a5,0x3
    80005cc0:	94be                	add	s1,s1,a5
    80005cc2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cc6:	fd043503          	ld	a0,-48(s0)
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	99e080e7          	jalr	-1634(ra) # 80004668 <fileclose>
    fileclose(wf);
    80005cd2:	fc843503          	ld	a0,-56(s0)
    80005cd6:	fffff097          	auipc	ra,0xfffff
    80005cda:	992080e7          	jalr	-1646(ra) # 80004668 <fileclose>
    return -1;
    80005cde:	57fd                	li	a5,-1
    80005ce0:	a03d                	j	80005d0e <sys_pipe+0x102>
    if(fd0 >= 0)
    80005ce2:	fc442783          	lw	a5,-60(s0)
    80005ce6:	0007c763          	bltz	a5,80005cf4 <sys_pipe+0xe8>
      p->ofile[fd0] = 0;
    80005cea:	07e9                	addi	a5,a5,26
    80005cec:	078e                	slli	a5,a5,0x3
    80005cee:	94be                	add	s1,s1,a5
    80005cf0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cf4:	fd043503          	ld	a0,-48(s0)
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	970080e7          	jalr	-1680(ra) # 80004668 <fileclose>
    fileclose(wf);
    80005d00:	fc843503          	ld	a0,-56(s0)
    80005d04:	fffff097          	auipc	ra,0xfffff
    80005d08:	964080e7          	jalr	-1692(ra) # 80004668 <fileclose>
    return -1;
    80005d0c:	57fd                	li	a5,-1
}
    80005d0e:	853e                	mv	a0,a5
    80005d10:	70e2                	ld	ra,56(sp)
    80005d12:	7442                	ld	s0,48(sp)
    80005d14:	74a2                	ld	s1,40(sp)
    80005d16:	6121                	addi	sp,sp,64
    80005d18:	8082                	ret
    80005d1a:	0000                	unimp
    80005d1c:	0000                	unimp
	...

0000000080005d20 <kernelvec>:
    80005d20:	7111                	addi	sp,sp,-256
    80005d22:	e006                	sd	ra,0(sp)
    80005d24:	e40a                	sd	sp,8(sp)
    80005d26:	e80e                	sd	gp,16(sp)
    80005d28:	ec12                	sd	tp,24(sp)
    80005d2a:	f016                	sd	t0,32(sp)
    80005d2c:	f41a                	sd	t1,40(sp)
    80005d2e:	f81e                	sd	t2,48(sp)
    80005d30:	fc22                	sd	s0,56(sp)
    80005d32:	e0a6                	sd	s1,64(sp)
    80005d34:	e4aa                	sd	a0,72(sp)
    80005d36:	e8ae                	sd	a1,80(sp)
    80005d38:	ecb2                	sd	a2,88(sp)
    80005d3a:	f0b6                	sd	a3,96(sp)
    80005d3c:	f4ba                	sd	a4,104(sp)
    80005d3e:	f8be                	sd	a5,112(sp)
    80005d40:	fcc2                	sd	a6,120(sp)
    80005d42:	e146                	sd	a7,128(sp)
    80005d44:	e54a                	sd	s2,136(sp)
    80005d46:	e94e                	sd	s3,144(sp)
    80005d48:	ed52                	sd	s4,152(sp)
    80005d4a:	f156                	sd	s5,160(sp)
    80005d4c:	f55a                	sd	s6,168(sp)
    80005d4e:	f95e                	sd	s7,176(sp)
    80005d50:	fd62                	sd	s8,184(sp)
    80005d52:	e1e6                	sd	s9,192(sp)
    80005d54:	e5ea                	sd	s10,200(sp)
    80005d56:	e9ee                	sd	s11,208(sp)
    80005d58:	edf2                	sd	t3,216(sp)
    80005d5a:	f1f6                	sd	t4,224(sp)
    80005d5c:	f5fa                	sd	t5,232(sp)
    80005d5e:	f9fe                	sd	t6,240(sp)
    80005d60:	c85fc0ef          	jal	ra,800029e4 <kerneltrap>
    80005d64:	6082                	ld	ra,0(sp)
    80005d66:	6122                	ld	sp,8(sp)
    80005d68:	61c2                	ld	gp,16(sp)
    80005d6a:	7282                	ld	t0,32(sp)
    80005d6c:	7322                	ld	t1,40(sp)
    80005d6e:	73c2                	ld	t2,48(sp)
    80005d70:	7462                	ld	s0,56(sp)
    80005d72:	6486                	ld	s1,64(sp)
    80005d74:	6526                	ld	a0,72(sp)
    80005d76:	65c6                	ld	a1,80(sp)
    80005d78:	6666                	ld	a2,88(sp)
    80005d7a:	7686                	ld	a3,96(sp)
    80005d7c:	7726                	ld	a4,104(sp)
    80005d7e:	77c6                	ld	a5,112(sp)
    80005d80:	7866                	ld	a6,120(sp)
    80005d82:	688a                	ld	a7,128(sp)
    80005d84:	692a                	ld	s2,136(sp)
    80005d86:	69ca                	ld	s3,144(sp)
    80005d88:	6a6a                	ld	s4,152(sp)
    80005d8a:	7a8a                	ld	s5,160(sp)
    80005d8c:	7b2a                	ld	s6,168(sp)
    80005d8e:	7bca                	ld	s7,176(sp)
    80005d90:	7c6a                	ld	s8,184(sp)
    80005d92:	6c8e                	ld	s9,192(sp)
    80005d94:	6d2e                	ld	s10,200(sp)
    80005d96:	6dce                	ld	s11,208(sp)
    80005d98:	6e6e                	ld	t3,216(sp)
    80005d9a:	7e8e                	ld	t4,224(sp)
    80005d9c:	7f2e                	ld	t5,232(sp)
    80005d9e:	7fce                	ld	t6,240(sp)
    80005da0:	6111                	addi	sp,sp,256
    80005da2:	10200073          	sret
    80005da6:	00000013          	nop
    80005daa:	00000013          	nop
    80005dae:	0001                	nop

0000000080005db0 <timervec>:
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	e10c                	sd	a1,0(a0)
    80005db6:	e510                	sd	a2,8(a0)
    80005db8:	e914                	sd	a3,16(a0)
    80005dba:	710c                	ld	a1,32(a0)
    80005dbc:	7510                	ld	a2,40(a0)
    80005dbe:	6194                	ld	a3,0(a1)
    80005dc0:	96b2                	add	a3,a3,a2
    80005dc2:	e194                	sd	a3,0(a1)
    80005dc4:	4589                	li	a1,2
    80005dc6:	14459073          	csrw	sip,a1
    80005dca:	6914                	ld	a3,16(a0)
    80005dcc:	6510                	ld	a2,8(a0)
    80005dce:	610c                	ld	a1,0(a0)
    80005dd0:	34051573          	csrrw	a0,mscratch,a0
    80005dd4:	30200073          	mret
	...

0000000080005dda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dda:	1141                	addi	sp,sp,-16
    80005ddc:	e422                	sd	s0,8(sp)
    80005dde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005de0:	0c0007b7          	lui	a5,0xc000
    80005de4:	4705                	li	a4,1
    80005de6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005de8:	c3d8                	sw	a4,4(a5)
}
    80005dea:	6422                	ld	s0,8(sp)
    80005dec:	0141                	addi	sp,sp,16
    80005dee:	8082                	ret

0000000080005df0 <plicinithart>:

void
plicinithart(void)
{
    80005df0:	1141                	addi	sp,sp,-16
    80005df2:	e406                	sd	ra,8(sp)
    80005df4:	e022                	sd	s0,0(sp)
    80005df6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	c6c080e7          	jalr	-916(ra) # 80001a64 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e00:	0085171b          	slliw	a4,a0,0x8
    80005e04:	0c0027b7          	lui	a5,0xc002
    80005e08:	97ba                	add	a5,a5,a4
    80005e0a:	40200713          	li	a4,1026
    80005e0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e12:	00d5151b          	slliw	a0,a0,0xd
    80005e16:	0c2017b7          	lui	a5,0xc201
    80005e1a:	953e                	add	a0,a0,a5
    80005e1c:	00052023          	sw	zero,0(a0)
}
    80005e20:	60a2                	ld	ra,8(sp)
    80005e22:	6402                	ld	s0,0(sp)
    80005e24:	0141                	addi	sp,sp,16
    80005e26:	8082                	ret

0000000080005e28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e28:	1141                	addi	sp,sp,-16
    80005e2a:	e406                	sd	ra,8(sp)
    80005e2c:	e022                	sd	s0,0(sp)
    80005e2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e30:	ffffc097          	auipc	ra,0xffffc
    80005e34:	c34080e7          	jalr	-972(ra) # 80001a64 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e38:	00d5151b          	slliw	a0,a0,0xd
    80005e3c:	0c2017b7          	lui	a5,0xc201
    80005e40:	97aa                	add	a5,a5,a0
  return irq;
}
    80005e42:	43c8                	lw	a0,4(a5)
    80005e44:	60a2                	ld	ra,8(sp)
    80005e46:	6402                	ld	s0,0(sp)
    80005e48:	0141                	addi	sp,sp,16
    80005e4a:	8082                	ret

0000000080005e4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e4c:	1101                	addi	sp,sp,-32
    80005e4e:	ec06                	sd	ra,24(sp)
    80005e50:	e822                	sd	s0,16(sp)
    80005e52:	e426                	sd	s1,8(sp)
    80005e54:	1000                	addi	s0,sp,32
    80005e56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	c0c080e7          	jalr	-1012(ra) # 80001a64 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e60:	00d5151b          	slliw	a0,a0,0xd
    80005e64:	0c2017b7          	lui	a5,0xc201
    80005e68:	97aa                	add	a5,a5,a0
    80005e6a:	c3c4                	sw	s1,4(a5)
}
    80005e6c:	60e2                	ld	ra,24(sp)
    80005e6e:	6442                	ld	s0,16(sp)
    80005e70:	64a2                	ld	s1,8(sp)
    80005e72:	6105                	addi	sp,sp,32
    80005e74:	8082                	ret

0000000080005e76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e76:	1141                	addi	sp,sp,-16
    80005e78:	e406                	sd	ra,8(sp)
    80005e7a:	e022                	sd	s0,0(sp)
    80005e7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e7e:	479d                	li	a5,7
    80005e80:	04a7cd63          	blt	a5,a0,80005eda <free_desc+0x64>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e84:	0001d797          	auipc	a5,0x1d
    80005e88:	17c78793          	addi	a5,a5,380 # 80023000 <disk>
    80005e8c:	00a78733          	add	a4,a5,a0
    80005e90:	6789                	lui	a5,0x2
    80005e92:	97ba                	add	a5,a5,a4
    80005e94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e98:	eba9                	bnez	a5,80005eea <free_desc+0x74>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e9a:	0001f797          	auipc	a5,0x1f
    80005e9e:	16678793          	addi	a5,a5,358 # 80025000 <disk+0x2000>
    80005ea2:	639c                	ld	a5,0(a5)
    80005ea4:	00451713          	slli	a4,a0,0x4
    80005ea8:	97ba                	add	a5,a5,a4
    80005eaa:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005eae:	0001d797          	auipc	a5,0x1d
    80005eb2:	15278793          	addi	a5,a5,338 # 80023000 <disk>
    80005eb6:	97aa                	add	a5,a5,a0
    80005eb8:	6509                	lui	a0,0x2
    80005eba:	953e                	add	a0,a0,a5
    80005ebc:	4785                	li	a5,1
    80005ebe:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005ec2:	0001f517          	auipc	a0,0x1f
    80005ec6:	15650513          	addi	a0,a0,342 # 80025018 <disk+0x2018>
    80005eca:	ffffc097          	auipc	ra,0xffffc
    80005ece:	566080e7          	jalr	1382(ra) # 80002430 <wakeup>
}
    80005ed2:	60a2                	ld	ra,8(sp)
    80005ed4:	6402                	ld	s0,0(sp)
    80005ed6:	0141                	addi	sp,sp,16
    80005ed8:	8082                	ret
    panic("virtio_disk_intr 1");
    80005eda:	00003517          	auipc	a0,0x3
    80005ede:	81650513          	addi	a0,a0,-2026 # 800086f0 <syscalls+0x358>
    80005ee2:	ffffa097          	auipc	ra,0xffffa
    80005ee6:	692080e7          	jalr	1682(ra) # 80000574 <panic>
    panic("virtio_disk_intr 2");
    80005eea:	00003517          	auipc	a0,0x3
    80005eee:	81e50513          	addi	a0,a0,-2018 # 80008708 <syscalls+0x370>
    80005ef2:	ffffa097          	auipc	ra,0xffffa
    80005ef6:	682080e7          	jalr	1666(ra) # 80000574 <panic>

0000000080005efa <virtio_disk_init>:
{
    80005efa:	1101                	addi	sp,sp,-32
    80005efc:	ec06                	sd	ra,24(sp)
    80005efe:	e822                	sd	s0,16(sp)
    80005f00:	e426                	sd	s1,8(sp)
    80005f02:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f04:	00003597          	auipc	a1,0x3
    80005f08:	81c58593          	addi	a1,a1,-2020 # 80008720 <syscalls+0x388>
    80005f0c:	0001f517          	auipc	a0,0x1f
    80005f10:	19c50513          	addi	a0,a0,412 # 800250a8 <disk+0x20a8>
    80005f14:	ffffb097          	auipc	ra,0xffffb
    80005f18:	cbe080e7          	jalr	-834(ra) # 80000bd2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f1c:	100017b7          	lui	a5,0x10001
    80005f20:	4398                	lw	a4,0(a5)
    80005f22:	2701                	sext.w	a4,a4
    80005f24:	747277b7          	lui	a5,0x74727
    80005f28:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f2c:	0ef71163          	bne	a4,a5,8000600e <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f30:	100017b7          	lui	a5,0x10001
    80005f34:	43dc                	lw	a5,4(a5)
    80005f36:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f38:	4705                	li	a4,1
    80005f3a:	0ce79a63          	bne	a5,a4,8000600e <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f3e:	100017b7          	lui	a5,0x10001
    80005f42:	479c                	lw	a5,8(a5)
    80005f44:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f46:	4709                	li	a4,2
    80005f48:	0ce79363          	bne	a5,a4,8000600e <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f4c:	100017b7          	lui	a5,0x10001
    80005f50:	47d8                	lw	a4,12(a5)
    80005f52:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f54:	554d47b7          	lui	a5,0x554d4
    80005f58:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f5c:	0af71963          	bne	a4,a5,8000600e <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f60:	100017b7          	lui	a5,0x10001
    80005f64:	4705                	li	a4,1
    80005f66:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f68:	470d                	li	a4,3
    80005f6a:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f6c:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f6e:	c7ffe737          	lui	a4,0xc7ffe
    80005f72:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f76:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f78:	2701                	sext.w	a4,a4
    80005f7a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f7c:	472d                	li	a4,11
    80005f7e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f80:	473d                	li	a4,15
    80005f82:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f84:	6705                	lui	a4,0x1
    80005f86:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f88:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f8c:	5bdc                	lw	a5,52(a5)
    80005f8e:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f90:	c7d9                	beqz	a5,8000601e <virtio_disk_init+0x124>
  if(max < NUM)
    80005f92:	471d                	li	a4,7
    80005f94:	08f77d63          	bleu	a5,a4,8000602e <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f98:	100014b7          	lui	s1,0x10001
    80005f9c:	47a1                	li	a5,8
    80005f9e:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005fa0:	6609                	lui	a2,0x2
    80005fa2:	4581                	li	a1,0
    80005fa4:	0001d517          	auipc	a0,0x1d
    80005fa8:	05c50513          	addi	a0,a0,92 # 80023000 <disk>
    80005fac:	ffffb097          	auipc	ra,0xffffb
    80005fb0:	db2080e7          	jalr	-590(ra) # 80000d5e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fb4:	0001d717          	auipc	a4,0x1d
    80005fb8:	04c70713          	addi	a4,a4,76 # 80023000 <disk>
    80005fbc:	00c75793          	srli	a5,a4,0xc
    80005fc0:	2781                	sext.w	a5,a5
    80005fc2:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005fc4:	0001f797          	auipc	a5,0x1f
    80005fc8:	03c78793          	addi	a5,a5,60 # 80025000 <disk+0x2000>
    80005fcc:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005fce:	0001d717          	auipc	a4,0x1d
    80005fd2:	0b270713          	addi	a4,a4,178 # 80023080 <disk+0x80>
    80005fd6:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005fd8:	0001e717          	auipc	a4,0x1e
    80005fdc:	02870713          	addi	a4,a4,40 # 80024000 <disk+0x1000>
    80005fe0:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fe2:	4705                	li	a4,1
    80005fe4:	00e78c23          	sb	a4,24(a5)
    80005fe8:	00e78ca3          	sb	a4,25(a5)
    80005fec:	00e78d23          	sb	a4,26(a5)
    80005ff0:	00e78da3          	sb	a4,27(a5)
    80005ff4:	00e78e23          	sb	a4,28(a5)
    80005ff8:	00e78ea3          	sb	a4,29(a5)
    80005ffc:	00e78f23          	sb	a4,30(a5)
    80006000:	00e78fa3          	sb	a4,31(a5)
}
    80006004:	60e2                	ld	ra,24(sp)
    80006006:	6442                	ld	s0,16(sp)
    80006008:	64a2                	ld	s1,8(sp)
    8000600a:	6105                	addi	sp,sp,32
    8000600c:	8082                	ret
    panic("could not find virtio disk");
    8000600e:	00002517          	auipc	a0,0x2
    80006012:	72250513          	addi	a0,a0,1826 # 80008730 <syscalls+0x398>
    80006016:	ffffa097          	auipc	ra,0xffffa
    8000601a:	55e080e7          	jalr	1374(ra) # 80000574 <panic>
    panic("virtio disk has no queue 0");
    8000601e:	00002517          	auipc	a0,0x2
    80006022:	73250513          	addi	a0,a0,1842 # 80008750 <syscalls+0x3b8>
    80006026:	ffffa097          	auipc	ra,0xffffa
    8000602a:	54e080e7          	jalr	1358(ra) # 80000574 <panic>
    panic("virtio disk max queue too short");
    8000602e:	00002517          	auipc	a0,0x2
    80006032:	74250513          	addi	a0,a0,1858 # 80008770 <syscalls+0x3d8>
    80006036:	ffffa097          	auipc	ra,0xffffa
    8000603a:	53e080e7          	jalr	1342(ra) # 80000574 <panic>

000000008000603e <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000603e:	7159                	addi	sp,sp,-112
    80006040:	f486                	sd	ra,104(sp)
    80006042:	f0a2                	sd	s0,96(sp)
    80006044:	eca6                	sd	s1,88(sp)
    80006046:	e8ca                	sd	s2,80(sp)
    80006048:	e4ce                	sd	s3,72(sp)
    8000604a:	e0d2                	sd	s4,64(sp)
    8000604c:	fc56                	sd	s5,56(sp)
    8000604e:	f85a                	sd	s6,48(sp)
    80006050:	f45e                	sd	s7,40(sp)
    80006052:	f062                	sd	s8,32(sp)
    80006054:	1880                	addi	s0,sp,112
    80006056:	892a                	mv	s2,a0
    80006058:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000605a:	00c52b83          	lw	s7,12(a0)
    8000605e:	001b9b9b          	slliw	s7,s7,0x1
    80006062:	1b82                	slli	s7,s7,0x20
    80006064:	020bdb93          	srli	s7,s7,0x20

  acquire(&disk.vdisk_lock);
    80006068:	0001f517          	auipc	a0,0x1f
    8000606c:	04050513          	addi	a0,a0,64 # 800250a8 <disk+0x20a8>
    80006070:	ffffb097          	auipc	ra,0xffffb
    80006074:	bf2080e7          	jalr	-1038(ra) # 80000c62 <acquire>
    if(disk.free[i]){
    80006078:	0001f997          	auipc	s3,0x1f
    8000607c:	f8898993          	addi	s3,s3,-120 # 80025000 <disk+0x2000>
  for(int i = 0; i < NUM; i++){
    80006080:	4b21                	li	s6,8
      disk.free[i] = 0;
    80006082:	0001da97          	auipc	s5,0x1d
    80006086:	f7ea8a93          	addi	s5,s5,-130 # 80023000 <disk>
  for(int i = 0; i < 3; i++){
    8000608a:	4a0d                	li	s4,3
    8000608c:	a079                	j	8000611a <virtio_disk_rw+0xdc>
      disk.free[i] = 0;
    8000608e:	00fa86b3          	add	a3,s5,a5
    80006092:	96ae                	add	a3,a3,a1
    80006094:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006098:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000609a:	0207ca63          	bltz	a5,800060ce <virtio_disk_rw+0x90>
  for(int i = 0; i < 3; i++){
    8000609e:	2485                	addiw	s1,s1,1
    800060a0:	0711                	addi	a4,a4,4
    800060a2:	25448163          	beq	s1,s4,800062e4 <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800060a6:	863a                	mv	a2,a4
    if(disk.free[i]){
    800060a8:	0189c783          	lbu	a5,24(s3)
    800060ac:	24079163          	bnez	a5,800062ee <virtio_disk_rw+0x2b0>
    800060b0:	0001f697          	auipc	a3,0x1f
    800060b4:	f6968693          	addi	a3,a3,-151 # 80025019 <disk+0x2019>
  for(int i = 0; i < NUM; i++){
    800060b8:	87aa                	mv	a5,a0
    if(disk.free[i]){
    800060ba:	0006c803          	lbu	a6,0(a3)
    800060be:	fc0818e3          	bnez	a6,8000608e <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    800060c2:	2785                	addiw	a5,a5,1
    800060c4:	0685                	addi	a3,a3,1
    800060c6:	ff679ae3          	bne	a5,s6,800060ba <virtio_disk_rw+0x7c>
    idx[i] = alloc_desc();
    800060ca:	57fd                	li	a5,-1
    800060cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060ce:	02905a63          	blez	s1,80006102 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800060d2:	fa042503          	lw	a0,-96(s0)
    800060d6:	00000097          	auipc	ra,0x0
    800060da:	da0080e7          	jalr	-608(ra) # 80005e76 <free_desc>
      for(int j = 0; j < i; j++)
    800060de:	4785                	li	a5,1
    800060e0:	0297d163          	ble	s1,a5,80006102 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800060e4:	fa442503          	lw	a0,-92(s0)
    800060e8:	00000097          	auipc	ra,0x0
    800060ec:	d8e080e7          	jalr	-626(ra) # 80005e76 <free_desc>
      for(int j = 0; j < i; j++)
    800060f0:	4789                	li	a5,2
    800060f2:	0097d863          	ble	s1,a5,80006102 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800060f6:	fa842503          	lw	a0,-88(s0)
    800060fa:	00000097          	auipc	ra,0x0
    800060fe:	d7c080e7          	jalr	-644(ra) # 80005e76 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006102:	0001f597          	auipc	a1,0x1f
    80006106:	fa658593          	addi	a1,a1,-90 # 800250a8 <disk+0x20a8>
    8000610a:	0001f517          	auipc	a0,0x1f
    8000610e:	f0e50513          	addi	a0,a0,-242 # 80025018 <disk+0x2018>
    80006112:	ffffc097          	auipc	ra,0xffffc
    80006116:	198080e7          	jalr	408(ra) # 800022aa <sleep>
  for(int i = 0; i < 3; i++){
    8000611a:	fa040713          	addi	a4,s0,-96
    8000611e:	4481                	li	s1,0
  for(int i = 0; i < NUM; i++){
    80006120:	4505                	li	a0,1
      disk.free[i] = 0;
    80006122:	6589                	lui	a1,0x2
    80006124:	b749                	j	800060a6 <virtio_disk_rw+0x68>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006126:	4785                	li	a5,1
    80006128:	f8f42823          	sw	a5,-112(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000612c:	f8042a23          	sw	zero,-108(s0)
  buf0.sector = sector;
    80006130:	f9743c23          	sd	s7,-104(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006134:	fa042983          	lw	s3,-96(s0)
    80006138:	00499493          	slli	s1,s3,0x4
    8000613c:	0001fa17          	auipc	s4,0x1f
    80006140:	ec4a0a13          	addi	s4,s4,-316 # 80025000 <disk+0x2000>
    80006144:	000a3a83          	ld	s5,0(s4)
    80006148:	9aa6                	add	s5,s5,s1
    8000614a:	f9040513          	addi	a0,s0,-112
    8000614e:	ffffb097          	auipc	ra,0xffffb
    80006152:	fc6080e7          	jalr	-58(ra) # 80001114 <kvmpa>
    80006156:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000615a:	000a3783          	ld	a5,0(s4)
    8000615e:	97a6                	add	a5,a5,s1
    80006160:	4741                	li	a4,16
    80006162:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006164:	000a3783          	ld	a5,0(s4)
    80006168:	97a6                	add	a5,a5,s1
    8000616a:	4705                	li	a4,1
    8000616c:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006170:	fa442703          	lw	a4,-92(s0)
    80006174:	000a3783          	ld	a5,0(s4)
    80006178:	97a6                	add	a5,a5,s1
    8000617a:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000617e:	0712                	slli	a4,a4,0x4
    80006180:	000a3783          	ld	a5,0(s4)
    80006184:	97ba                	add	a5,a5,a4
    80006186:	05890693          	addi	a3,s2,88
    8000618a:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000618c:	000a3783          	ld	a5,0(s4)
    80006190:	97ba                	add	a5,a5,a4
    80006192:	40000693          	li	a3,1024
    80006196:	c794                	sw	a3,8(a5)
  if(write)
    80006198:	100c0863          	beqz	s8,800062a8 <virtio_disk_rw+0x26a>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000619c:	000a3783          	ld	a5,0(s4)
    800061a0:	97ba                	add	a5,a5,a4
    800061a2:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061a6:	0001d517          	auipc	a0,0x1d
    800061aa:	e5a50513          	addi	a0,a0,-422 # 80023000 <disk>
    800061ae:	0001f797          	auipc	a5,0x1f
    800061b2:	e5278793          	addi	a5,a5,-430 # 80025000 <disk+0x2000>
    800061b6:	6394                	ld	a3,0(a5)
    800061b8:	96ba                	add	a3,a3,a4
    800061ba:	00c6d603          	lhu	a2,12(a3)
    800061be:	00166613          	ori	a2,a2,1
    800061c2:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061c6:	fa842683          	lw	a3,-88(s0)
    800061ca:	6390                	ld	a2,0(a5)
    800061cc:	9732                	add	a4,a4,a2
    800061ce:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800061d2:	20098613          	addi	a2,s3,512
    800061d6:	0612                	slli	a2,a2,0x4
    800061d8:	962a                	add	a2,a2,a0
    800061da:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061de:	00469713          	slli	a4,a3,0x4
    800061e2:	6394                	ld	a3,0(a5)
    800061e4:	96ba                	add	a3,a3,a4
    800061e6:	6589                	lui	a1,0x2
    800061e8:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800061ec:	94ae                	add	s1,s1,a1
    800061ee:	94aa                	add	s1,s1,a0
    800061f0:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800061f2:	6394                	ld	a3,0(a5)
    800061f4:	96ba                	add	a3,a3,a4
    800061f6:	4585                	li	a1,1
    800061f8:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061fa:	6394                	ld	a3,0(a5)
    800061fc:	96ba                	add	a3,a3,a4
    800061fe:	4509                	li	a0,2
    80006200:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006204:	6394                	ld	a3,0(a5)
    80006206:	9736                	add	a4,a4,a3
    80006208:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000620c:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006210:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006214:	6794                	ld	a3,8(a5)
    80006216:	0026d703          	lhu	a4,2(a3)
    8000621a:	8b1d                	andi	a4,a4,7
    8000621c:	2709                	addiw	a4,a4,2
    8000621e:	0706                	slli	a4,a4,0x1
    80006220:	9736                	add	a4,a4,a3
    80006222:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    80006226:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000622a:	6798                	ld	a4,8(a5)
    8000622c:	00275783          	lhu	a5,2(a4)
    80006230:	2785                	addiw	a5,a5,1
    80006232:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006236:	100017b7          	lui	a5,0x10001
    8000623a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000623e:	00492703          	lw	a4,4(s2)
    80006242:	4785                	li	a5,1
    80006244:	02f71163          	bne	a4,a5,80006266 <virtio_disk_rw+0x228>
    sleep(b, &disk.vdisk_lock);
    80006248:	0001f997          	auipc	s3,0x1f
    8000624c:	e6098993          	addi	s3,s3,-416 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006250:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006252:	85ce                	mv	a1,s3
    80006254:	854a                	mv	a0,s2
    80006256:	ffffc097          	auipc	ra,0xffffc
    8000625a:	054080e7          	jalr	84(ra) # 800022aa <sleep>
  while(b->disk == 1) {
    8000625e:	00492783          	lw	a5,4(s2)
    80006262:	fe9788e3          	beq	a5,s1,80006252 <virtio_disk_rw+0x214>
  }

  disk.info[idx[0]].b = 0;
    80006266:	fa042483          	lw	s1,-96(s0)
    8000626a:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    8000626e:	00479713          	slli	a4,a5,0x4
    80006272:	0001d797          	auipc	a5,0x1d
    80006276:	d8e78793          	addi	a5,a5,-626 # 80023000 <disk>
    8000627a:	97ba                	add	a5,a5,a4
    8000627c:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006280:	0001f917          	auipc	s2,0x1f
    80006284:	d8090913          	addi	s2,s2,-640 # 80025000 <disk+0x2000>
    free_desc(i);
    80006288:	8526                	mv	a0,s1
    8000628a:	00000097          	auipc	ra,0x0
    8000628e:	bec080e7          	jalr	-1044(ra) # 80005e76 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006292:	0492                	slli	s1,s1,0x4
    80006294:	00093783          	ld	a5,0(s2)
    80006298:	94be                	add	s1,s1,a5
    8000629a:	00c4d783          	lhu	a5,12(s1)
    8000629e:	8b85                	andi	a5,a5,1
    800062a0:	cf91                	beqz	a5,800062bc <virtio_disk_rw+0x27e>
      i = disk.desc[i].next;
    800062a2:	00e4d483          	lhu	s1,14(s1)
  while(1){
    800062a6:	b7cd                	j	80006288 <virtio_disk_rw+0x24a>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800062a8:	0001f797          	auipc	a5,0x1f
    800062ac:	d5878793          	addi	a5,a5,-680 # 80025000 <disk+0x2000>
    800062b0:	639c                	ld	a5,0(a5)
    800062b2:	97ba                	add	a5,a5,a4
    800062b4:	4689                	li	a3,2
    800062b6:	00d79623          	sh	a3,12(a5)
    800062ba:	b5f5                	j	800061a6 <virtio_disk_rw+0x168>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062bc:	0001f517          	auipc	a0,0x1f
    800062c0:	dec50513          	addi	a0,a0,-532 # 800250a8 <disk+0x20a8>
    800062c4:	ffffb097          	auipc	ra,0xffffb
    800062c8:	a52080e7          	jalr	-1454(ra) # 80000d16 <release>
}
    800062cc:	70a6                	ld	ra,104(sp)
    800062ce:	7406                	ld	s0,96(sp)
    800062d0:	64e6                	ld	s1,88(sp)
    800062d2:	6946                	ld	s2,80(sp)
    800062d4:	69a6                	ld	s3,72(sp)
    800062d6:	6a06                	ld	s4,64(sp)
    800062d8:	7ae2                	ld	s5,56(sp)
    800062da:	7b42                	ld	s6,48(sp)
    800062dc:	7ba2                	ld	s7,40(sp)
    800062de:	7c02                	ld	s8,32(sp)
    800062e0:	6165                	addi	sp,sp,112
    800062e2:	8082                	ret
  if(write)
    800062e4:	e40c11e3          	bnez	s8,80006126 <virtio_disk_rw+0xe8>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800062e8:	f8042823          	sw	zero,-112(s0)
    800062ec:	b581                	j	8000612c <virtio_disk_rw+0xee>
      disk.free[i] = 0;
    800062ee:	00098c23          	sb	zero,24(s3)
    idx[i] = alloc_desc();
    800062f2:	00072023          	sw	zero,0(a4)
    if(idx[i] < 0){
    800062f6:	b365                	j	8000609e <virtio_disk_rw+0x60>

00000000800062f8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062f8:	1101                	addi	sp,sp,-32
    800062fa:	ec06                	sd	ra,24(sp)
    800062fc:	e822                	sd	s0,16(sp)
    800062fe:	e426                	sd	s1,8(sp)
    80006300:	e04a                	sd	s2,0(sp)
    80006302:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006304:	0001f517          	auipc	a0,0x1f
    80006308:	da450513          	addi	a0,a0,-604 # 800250a8 <disk+0x20a8>
    8000630c:	ffffb097          	auipc	ra,0xffffb
    80006310:	956080e7          	jalr	-1706(ra) # 80000c62 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006314:	0001f797          	auipc	a5,0x1f
    80006318:	cec78793          	addi	a5,a5,-788 # 80025000 <disk+0x2000>
    8000631c:	0207d683          	lhu	a3,32(a5)
    80006320:	6b98                	ld	a4,16(a5)
    80006322:	00275783          	lhu	a5,2(a4)
    80006326:	8fb5                	xor	a5,a5,a3
    80006328:	8b9d                	andi	a5,a5,7
    8000632a:	c7c9                	beqz	a5,800063b4 <virtio_disk_intr+0xbc>
    int id = disk.used->elems[disk.used_idx].id;
    8000632c:	068e                	slli	a3,a3,0x3
    8000632e:	9736                	add	a4,a4,a3
    80006330:	435c                	lw	a5,4(a4)

    if(disk.info[id].status != 0)
    80006332:	20078713          	addi	a4,a5,512
    80006336:	00471693          	slli	a3,a4,0x4
    8000633a:	0001d717          	auipc	a4,0x1d
    8000633e:	cc670713          	addi	a4,a4,-826 # 80023000 <disk>
    80006342:	9736                	add	a4,a4,a3
    80006344:	03074703          	lbu	a4,48(a4)
    80006348:	ef31                	bnez	a4,800063a4 <virtio_disk_intr+0xac>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000634a:	0001d917          	auipc	s2,0x1d
    8000634e:	cb690913          	addi	s2,s2,-842 # 80023000 <disk>
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006352:	0001f497          	auipc	s1,0x1f
    80006356:	cae48493          	addi	s1,s1,-850 # 80025000 <disk+0x2000>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000635a:	20078793          	addi	a5,a5,512
    8000635e:	0792                	slli	a5,a5,0x4
    80006360:	97ca                	add	a5,a5,s2
    80006362:	7798                	ld	a4,40(a5)
    80006364:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006368:	7788                	ld	a0,40(a5)
    8000636a:	ffffc097          	auipc	ra,0xffffc
    8000636e:	0c6080e7          	jalr	198(ra) # 80002430 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006372:	0204d783          	lhu	a5,32(s1)
    80006376:	2785                	addiw	a5,a5,1
    80006378:	8b9d                	andi	a5,a5,7
    8000637a:	03079613          	slli	a2,a5,0x30
    8000637e:	9241                	srli	a2,a2,0x30
    80006380:	02c49023          	sh	a2,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006384:	6898                	ld	a4,16(s1)
    80006386:	00275683          	lhu	a3,2(a4)
    8000638a:	8a9d                	andi	a3,a3,7
    8000638c:	02c68463          	beq	a3,a2,800063b4 <virtio_disk_intr+0xbc>
    int id = disk.used->elems[disk.used_idx].id;
    80006390:	078e                	slli	a5,a5,0x3
    80006392:	97ba                	add	a5,a5,a4
    80006394:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006396:	20078713          	addi	a4,a5,512
    8000639a:	0712                	slli	a4,a4,0x4
    8000639c:	974a                	add	a4,a4,s2
    8000639e:	03074703          	lbu	a4,48(a4)
    800063a2:	df45                	beqz	a4,8000635a <virtio_disk_intr+0x62>
      panic("virtio_disk_intr status");
    800063a4:	00002517          	auipc	a0,0x2
    800063a8:	3ec50513          	addi	a0,a0,1004 # 80008790 <syscalls+0x3f8>
    800063ac:	ffffa097          	auipc	ra,0xffffa
    800063b0:	1c8080e7          	jalr	456(ra) # 80000574 <panic>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063b4:	10001737          	lui	a4,0x10001
    800063b8:	533c                	lw	a5,96(a4)
    800063ba:	8b8d                	andi	a5,a5,3
    800063bc:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800063be:	0001f517          	auipc	a0,0x1f
    800063c2:	cea50513          	addi	a0,a0,-790 # 800250a8 <disk+0x20a8>
    800063c6:	ffffb097          	auipc	ra,0xffffb
    800063ca:	950080e7          	jalr	-1712(ra) # 80000d16 <release>
}
    800063ce:	60e2                	ld	ra,24(sp)
    800063d0:	6442                	ld	s0,16(sp)
    800063d2:	64a2                	ld	s1,8(sp)
    800063d4:	6902                	ld	s2,0(sp)
    800063d6:	6105                	addi	sp,sp,32
    800063d8:	8082                	ret
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
