
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
    80000062:	e9278793          	addi	a5,a5,-366 # 80005ef0 <timervec>
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
    80000096:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77ff>
    8000009a:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009c:	6705                	lui	a4,0x1
    8000009e:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a4:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a8:	00001797          	auipc	a5,0x1
    800000ac:	ede78793          	addi	a5,a5,-290 # 80000f86 <main>
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
    80000112:	ba8080e7          	jalr	-1112(ra) # 80000cb6 <acquire>
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
    8000012c:	4ee080e7          	jalr	1262(ra) # 80002616 <either_copyin>
    80000130:	01550c63          	beq	a0,s5,80000148 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000134:	fbf44503          	lbu	a0,-65(s0)
    80000138:	00001097          	auipc	ra,0x1
    8000013c:	842080e7          	jalr	-1982(ra) # 8000097a <uartputc>
  for(i = 0; i < n; i++){
    80000140:	2485                	addiw	s1,s1,1
    80000142:	0905                	addi	s2,s2,1
    80000144:	fc999de3          	bne	s3,s1,8000011e <consolewrite+0x30>
  }
  release(&cons.lock);
    80000148:	00011517          	auipc	a0,0x11
    8000014c:	6e850513          	addi	a0,a0,1768 # 80011830 <cons>
    80000150:	00001097          	auipc	ra,0x1
    80000154:	c1a080e7          	jalr	-998(ra) # 80000d6a <release>

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
    800001a4:	b16080e7          	jalr	-1258(ra) # 80000cb6 <acquire>
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
    800001d4:	8f4080e7          	jalr	-1804(ra) # 80001ac4 <myproc>
    800001d8:	591c                	lw	a5,48(a0)
    800001da:	eba5                	bnez	a5,8000024a <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001dc:	85ce                	mv	a1,s3
    800001de:	854a                	mv	a0,s2
    800001e0:	00002097          	auipc	ra,0x2
    800001e4:	17e080e7          	jalr	382(ra) # 8000235e <sleep>
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
    80000220:	3a4080e7          	jalr	932(ra) # 800025c0 <either_copyout>
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
    80000240:	b2e080e7          	jalr	-1234(ra) # 80000d6a <release>

  return target - n;
    80000244:	414b053b          	subw	a0,s6,s4
    80000248:	a811                	j	8000025c <consoleread+0xec>
        release(&cons.lock);
    8000024a:	00011517          	auipc	a0,0x11
    8000024e:	5e650513          	addi	a0,a0,1510 # 80011830 <cons>
    80000252:	00001097          	auipc	ra,0x1
    80000256:	b18080e7          	jalr	-1256(ra) # 80000d6a <release>
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
    800002a0:	5de080e7          	jalr	1502(ra) # 8000087a <uartputc_sync>
}
    800002a4:	60a2                	ld	ra,8(sp)
    800002a6:	6402                	ld	s0,0(sp)
    800002a8:	0141                	addi	sp,sp,16
    800002aa:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002ac:	4521                	li	a0,8
    800002ae:	00000097          	auipc	ra,0x0
    800002b2:	5cc080e7          	jalr	1484(ra) # 8000087a <uartputc_sync>
    800002b6:	02000513          	li	a0,32
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	5c0080e7          	jalr	1472(ra) # 8000087a <uartputc_sync>
    800002c2:	4521                	li	a0,8
    800002c4:	00000097          	auipc	ra,0x0
    800002c8:	5b6080e7          	jalr	1462(ra) # 8000087a <uartputc_sync>
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
    800002e8:	9d2080e7          	jalr	-1582(ra) # 80000cb6 <acquire>

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
    8000041a:	256080e7          	jalr	598(ra) # 8000266c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000041e:	00011517          	auipc	a0,0x11
    80000422:	41250513          	addi	a0,a0,1042 # 80011830 <cons>
    80000426:	00001097          	auipc	ra,0x1
    8000042a:	944080e7          	jalr	-1724(ra) # 80000d6a <release>
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
    8000047c:	06c080e7          	jalr	108(ra) # 800024e4 <wakeup>
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
    8000049e:	78c080e7          	jalr	1932(ra) # 80000c26 <initlock>

  uartinit();
    800004a2:	00000097          	auipc	ra,0x0
    800004a6:	388080e7          	jalr	904(ra) # 8000082a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    800004aa:	00022797          	auipc	a5,0x22
    800004ae:	d0678793          	addi	a5,a5,-762 # 800221b0 <devsw>
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

0000000080000574 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000574:	1101                	addi	sp,sp,-32
    80000576:	ec06                	sd	ra,24(sp)
    80000578:	e822                	sd	s0,16(sp)
    8000057a:	e426                	sd	s1,8(sp)
    8000057c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000057e:	00011497          	auipc	s1,0x11
    80000582:	35a48493          	addi	s1,s1,858 # 800118d8 <pr>
    80000586:	00008597          	auipc	a1,0x8
    8000058a:	aaa58593          	addi	a1,a1,-1366 # 80008030 <digits+0x18>
    8000058e:	8526                	mv	a0,s1
    80000590:	00000097          	auipc	ra,0x0
    80000594:	696080e7          	jalr	1686(ra) # 80000c26 <initlock>
  pr.locking = 1;
    80000598:	4785                	li	a5,1
    8000059a:	cc9c                	sw	a5,24(s1)
}
    8000059c:	60e2                	ld	ra,24(sp)
    8000059e:	6442                	ld	s0,16(sp)
    800005a0:	64a2                	ld	s1,8(sp)
    800005a2:	6105                	addi	sp,sp,32
    800005a4:	8082                	ret

00000000800005a6 <backtrace>:

void
backtrace(void)
{
    800005a6:	7179                	addi	sp,sp,-48
    800005a8:	f406                	sd	ra,40(sp)
    800005aa:	f022                	sd	s0,32(sp)
    800005ac:	ec26                	sd	s1,24(sp)
    800005ae:	e84a                	sd	s2,16(sp)
    800005b0:	e44e                	sd	s3,8(sp)
    800005b2:	1800                	addi	s0,sp,48
  asm volatile("mv %0, s0" : "=r" (x) );
    800005b4:	84a2                	mv	s1,s0
    // 获取栈帧首地址
    uint64 fpaddr = r_fp();
    // 获取当前进程在kernel中stack的最大地址
    uint64 max = PGROUNDUP(fpaddr);
    800005b6:	6905                	lui	s2,0x1
    800005b8:	197d                	addi	s2,s2,-1
    800005ba:	9926                	add	s2,s2,s1
    800005bc:	77fd                	lui	a5,0xfffff
    800005be:	00f97933          	and	s2,s2,a5
    // 因为栈是从高地址至低地址增长的，所以这里用小于号判断
    while (fpaddr < max) { 
    800005c2:	0324f163          	bleu	s2,s1,800005e4 <backtrace+0x3e>
        // return address是当前fp-8
        printf("%p\n", *((uint64*)(fpaddr - 8)));
    800005c6:	00008997          	auipc	s3,0x8
    800005ca:	a7298993          	addi	s3,s3,-1422 # 80008038 <digits+0x20>
    800005ce:	ff84b583          	ld	a1,-8(s1)
    800005d2:	854e                	mv	a0,s3
    800005d4:	00000097          	auipc	ra,0x0
    800005d8:	070080e7          	jalr	112(ra) # 80000644 <printf>
        // 调用该函数的栈帧便宜是fp - 16
        fpaddr = *((uint64*)(fpaddr - 16));
    800005dc:	ff04b483          	ld	s1,-16(s1)
    while (fpaddr < max) { 
    800005e0:	ff24e7e3          	bltu	s1,s2,800005ce <backtrace+0x28>
    }
}
    800005e4:	70a2                	ld	ra,40(sp)
    800005e6:	7402                	ld	s0,32(sp)
    800005e8:	64e2                	ld	s1,24(sp)
    800005ea:	6942                	ld	s2,16(sp)
    800005ec:	69a2                	ld	s3,8(sp)
    800005ee:	6145                	addi	sp,sp,48
    800005f0:	8082                	ret

00000000800005f2 <panic>:
{
    800005f2:	1101                	addi	sp,sp,-32
    800005f4:	ec06                	sd	ra,24(sp)
    800005f6:	e822                	sd	s0,16(sp)
    800005f8:	e426                	sd	s1,8(sp)
    800005fa:	1000                	addi	s0,sp,32
    800005fc:	84aa                	mv	s1,a0
  backtrace();
    800005fe:	00000097          	auipc	ra,0x0
    80000602:	fa8080e7          	jalr	-88(ra) # 800005a6 <backtrace>
  pr.locking = 0;
    80000606:	00011797          	auipc	a5,0x11
    8000060a:	2e07a523          	sw	zero,746(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000060e:	00008517          	auipc	a0,0x8
    80000612:	a3250513          	addi	a0,a0,-1486 # 80008040 <digits+0x28>
    80000616:	00000097          	auipc	ra,0x0
    8000061a:	02e080e7          	jalr	46(ra) # 80000644 <printf>
  printf(s);
    8000061e:	8526                	mv	a0,s1
    80000620:	00000097          	auipc	ra,0x0
    80000624:	024080e7          	jalr	36(ra) # 80000644 <printf>
  printf("\n");
    80000628:	00008517          	auipc	a0,0x8
    8000062c:	aa850513          	addi	a0,a0,-1368 # 800080d0 <digits+0xb8>
    80000630:	00000097          	auipc	ra,0x0
    80000634:	014080e7          	jalr	20(ra) # 80000644 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000638:	4785                	li	a5,1
    8000063a:	00009717          	auipc	a4,0x9
    8000063e:	9cf72323          	sw	a5,-1594(a4) # 80009000 <panicked>
  for(;;)
    80000642:	a001                	j	80000642 <panic+0x50>

0000000080000644 <printf>:
{
    80000644:	7131                	addi	sp,sp,-192
    80000646:	fc86                	sd	ra,120(sp)
    80000648:	f8a2                	sd	s0,112(sp)
    8000064a:	f4a6                	sd	s1,104(sp)
    8000064c:	f0ca                	sd	s2,96(sp)
    8000064e:	ecce                	sd	s3,88(sp)
    80000650:	e8d2                	sd	s4,80(sp)
    80000652:	e4d6                	sd	s5,72(sp)
    80000654:	e0da                	sd	s6,64(sp)
    80000656:	fc5e                	sd	s7,56(sp)
    80000658:	f862                	sd	s8,48(sp)
    8000065a:	f466                	sd	s9,40(sp)
    8000065c:	f06a                	sd	s10,32(sp)
    8000065e:	ec6e                	sd	s11,24(sp)
    80000660:	0100                	addi	s0,sp,128
    80000662:	8aaa                	mv	s5,a0
    80000664:	e40c                	sd	a1,8(s0)
    80000666:	e810                	sd	a2,16(s0)
    80000668:	ec14                	sd	a3,24(s0)
    8000066a:	f018                	sd	a4,32(s0)
    8000066c:	f41c                	sd	a5,40(s0)
    8000066e:	03043823          	sd	a6,48(s0)
    80000672:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    80000676:	00011797          	auipc	a5,0x11
    8000067a:	26278793          	addi	a5,a5,610 # 800118d8 <pr>
    8000067e:	0187ad83          	lw	s11,24(a5)
  if(locking)
    80000682:	020d9b63          	bnez	s11,800006b8 <printf+0x74>
  if (fmt == 0)
    80000686:	020a8f63          	beqz	s5,800006c4 <printf+0x80>
  va_start(ap, fmt);
    8000068a:	00840793          	addi	a5,s0,8
    8000068e:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000692:	000ac503          	lbu	a0,0(s5)
    80000696:	16050063          	beqz	a0,800007f6 <printf+0x1b2>
    8000069a:	4481                	li	s1,0
    if(c != '%'){
    8000069c:	02500a13          	li	s4,37
    switch(c){
    800006a0:	07000b13          	li	s6,112
  consputc('x');
    800006a4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006a6:	00008b97          	auipc	s7,0x8
    800006aa:	972b8b93          	addi	s7,s7,-1678 # 80008018 <digits>
    switch(c){
    800006ae:	07300c93          	li	s9,115
    800006b2:	06400c13          	li	s8,100
    800006b6:	a815                	j	800006ea <printf+0xa6>
    acquire(&pr.lock);
    800006b8:	853e                	mv	a0,a5
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	5fc080e7          	jalr	1532(ra) # 80000cb6 <acquire>
    800006c2:	b7d1                	j	80000686 <printf+0x42>
    panic("null fmt");
    800006c4:	00008517          	auipc	a0,0x8
    800006c8:	98c50513          	addi	a0,a0,-1652 # 80008050 <digits+0x38>
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	f26080e7          	jalr	-218(ra) # 800005f2 <panic>
      consputc(c);
    800006d4:	00000097          	auipc	ra,0x0
    800006d8:	bb8080e7          	jalr	-1096(ra) # 8000028c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800006dc:	2485                	addiw	s1,s1,1
    800006de:	009a87b3          	add	a5,s5,s1
    800006e2:	0007c503          	lbu	a0,0(a5)
    800006e6:	10050863          	beqz	a0,800007f6 <printf+0x1b2>
    if(c != '%'){
    800006ea:	ff4515e3          	bne	a0,s4,800006d4 <printf+0x90>
    c = fmt[++i] & 0xff;
    800006ee:	2485                	addiw	s1,s1,1
    800006f0:	009a87b3          	add	a5,s5,s1
    800006f4:	0007c783          	lbu	a5,0(a5)
    800006f8:	0007891b          	sext.w	s2,a5
    if(c == 0)
    800006fc:	0e090d63          	beqz	s2,800007f6 <printf+0x1b2>
    switch(c){
    80000700:	05678a63          	beq	a5,s6,80000754 <printf+0x110>
    80000704:	02fb7663          	bleu	a5,s6,80000730 <printf+0xec>
    80000708:	09978963          	beq	a5,s9,8000079a <printf+0x156>
    8000070c:	07800713          	li	a4,120
    80000710:	0ce79863          	bne	a5,a4,800007e0 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000714:	f8843783          	ld	a5,-120(s0)
    80000718:	00878713          	addi	a4,a5,8
    8000071c:	f8e43423          	sd	a4,-120(s0)
    80000720:	4605                	li	a2,1
    80000722:	85ea                	mv	a1,s10
    80000724:	4388                	lw	a0,0(a5)
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	da8080e7          	jalr	-600(ra) # 800004ce <printint>
      break;
    8000072e:	b77d                	j	800006dc <printf+0x98>
    switch(c){
    80000730:	0b478263          	beq	a5,s4,800007d4 <printf+0x190>
    80000734:	0b879663          	bne	a5,s8,800007e0 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000738:	f8843783          	ld	a5,-120(s0)
    8000073c:	00878713          	addi	a4,a5,8
    80000740:	f8e43423          	sd	a4,-120(s0)
    80000744:	4605                	li	a2,1
    80000746:	45a9                	li	a1,10
    80000748:	4388                	lw	a0,0(a5)
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	d84080e7          	jalr	-636(ra) # 800004ce <printint>
      break;
    80000752:	b769                	j	800006dc <printf+0x98>
      printptr(va_arg(ap, uint64));
    80000754:	f8843783          	ld	a5,-120(s0)
    80000758:	00878713          	addi	a4,a5,8
    8000075c:	f8e43423          	sd	a4,-120(s0)
    80000760:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000764:	03000513          	li	a0,48
    80000768:	00000097          	auipc	ra,0x0
    8000076c:	b24080e7          	jalr	-1244(ra) # 8000028c <consputc>
  consputc('x');
    80000770:	07800513          	li	a0,120
    80000774:	00000097          	auipc	ra,0x0
    80000778:	b18080e7          	jalr	-1256(ra) # 8000028c <consputc>
    8000077c:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    8000077e:	03c9d793          	srli	a5,s3,0x3c
    80000782:	97de                	add	a5,a5,s7
    80000784:	0007c503          	lbu	a0,0(a5)
    80000788:	00000097          	auipc	ra,0x0
    8000078c:	b04080e7          	jalr	-1276(ra) # 8000028c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    80000790:	0992                	slli	s3,s3,0x4
    80000792:	397d                	addiw	s2,s2,-1
    80000794:	fe0915e3          	bnez	s2,8000077e <printf+0x13a>
    80000798:	b791                	j	800006dc <printf+0x98>
      if((s = va_arg(ap, char*)) == 0)
    8000079a:	f8843783          	ld	a5,-120(s0)
    8000079e:	00878713          	addi	a4,a5,8
    800007a2:	f8e43423          	sd	a4,-120(s0)
    800007a6:	0007b903          	ld	s2,0(a5)
    800007aa:	00090e63          	beqz	s2,800007c6 <printf+0x182>
      for(; *s; s++)
    800007ae:	00094503          	lbu	a0,0(s2) # 1000 <_entry-0x7ffff000>
    800007b2:	d50d                	beqz	a0,800006dc <printf+0x98>
        consputc(*s);
    800007b4:	00000097          	auipc	ra,0x0
    800007b8:	ad8080e7          	jalr	-1320(ra) # 8000028c <consputc>
      for(; *s; s++)
    800007bc:	0905                	addi	s2,s2,1
    800007be:	00094503          	lbu	a0,0(s2)
    800007c2:	f96d                	bnez	a0,800007b4 <printf+0x170>
    800007c4:	bf21                	j	800006dc <printf+0x98>
        s = "(null)";
    800007c6:	00008917          	auipc	s2,0x8
    800007ca:	88290913          	addi	s2,s2,-1918 # 80008048 <digits+0x30>
      for(; *s; s++)
    800007ce:	02800513          	li	a0,40
    800007d2:	b7cd                	j	800007b4 <printf+0x170>
      consputc('%');
    800007d4:	8552                	mv	a0,s4
    800007d6:	00000097          	auipc	ra,0x0
    800007da:	ab6080e7          	jalr	-1354(ra) # 8000028c <consputc>
      break;
    800007de:	bdfd                	j	800006dc <printf+0x98>
      consputc('%');
    800007e0:	8552                	mv	a0,s4
    800007e2:	00000097          	auipc	ra,0x0
    800007e6:	aaa080e7          	jalr	-1366(ra) # 8000028c <consputc>
      consputc(c);
    800007ea:	854a                	mv	a0,s2
    800007ec:	00000097          	auipc	ra,0x0
    800007f0:	aa0080e7          	jalr	-1376(ra) # 8000028c <consputc>
      break;
    800007f4:	b5e5                	j	800006dc <printf+0x98>
  if(locking)
    800007f6:	020d9163          	bnez	s11,80000818 <printf+0x1d4>
}
    800007fa:	70e6                	ld	ra,120(sp)
    800007fc:	7446                	ld	s0,112(sp)
    800007fe:	74a6                	ld	s1,104(sp)
    80000800:	7906                	ld	s2,96(sp)
    80000802:	69e6                	ld	s3,88(sp)
    80000804:	6a46                	ld	s4,80(sp)
    80000806:	6aa6                	ld	s5,72(sp)
    80000808:	6b06                	ld	s6,64(sp)
    8000080a:	7be2                	ld	s7,56(sp)
    8000080c:	7c42                	ld	s8,48(sp)
    8000080e:	7ca2                	ld	s9,40(sp)
    80000810:	7d02                	ld	s10,32(sp)
    80000812:	6de2                	ld	s11,24(sp)
    80000814:	6129                	addi	sp,sp,192
    80000816:	8082                	ret
    release(&pr.lock);
    80000818:	00011517          	auipc	a0,0x11
    8000081c:	0c050513          	addi	a0,a0,192 # 800118d8 <pr>
    80000820:	00000097          	auipc	ra,0x0
    80000824:	54a080e7          	jalr	1354(ra) # 80000d6a <release>
}
    80000828:	bfc9                	j	800007fa <printf+0x1b6>

000000008000082a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000082a:	1141                	addi	sp,sp,-16
    8000082c:	e406                	sd	ra,8(sp)
    8000082e:	e022                	sd	s0,0(sp)
    80000830:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000832:	100007b7          	lui	a5,0x10000
    80000836:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000083a:	f8000713          	li	a4,-128
    8000083e:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000842:	470d                	li	a4,3
    80000844:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000848:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000084c:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000850:	469d                	li	a3,7
    80000852:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000856:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000085a:	00008597          	auipc	a1,0x8
    8000085e:	80658593          	addi	a1,a1,-2042 # 80008060 <digits+0x48>
    80000862:	00011517          	auipc	a0,0x11
    80000866:	09650513          	addi	a0,a0,150 # 800118f8 <uart_tx_lock>
    8000086a:	00000097          	auipc	ra,0x0
    8000086e:	3bc080e7          	jalr	956(ra) # 80000c26 <initlock>
}
    80000872:	60a2                	ld	ra,8(sp)
    80000874:	6402                	ld	s0,0(sp)
    80000876:	0141                	addi	sp,sp,16
    80000878:	8082                	ret

000000008000087a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000087a:	1101                	addi	sp,sp,-32
    8000087c:	ec06                	sd	ra,24(sp)
    8000087e:	e822                	sd	s0,16(sp)
    80000880:	e426                	sd	s1,8(sp)
    80000882:	1000                	addi	s0,sp,32
    80000884:	84aa                	mv	s1,a0
  push_off();
    80000886:	00000097          	auipc	ra,0x0
    8000088a:	3e4080e7          	jalr	996(ra) # 80000c6a <push_off>

  if(panicked){
    8000088e:	00008797          	auipc	a5,0x8
    80000892:	77278793          	addi	a5,a5,1906 # 80009000 <panicked>
    80000896:	439c                	lw	a5,0(a5)
    80000898:	2781                	sext.w	a5,a5
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000089a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000089e:	c391                	beqz	a5,800008a2 <uartputc_sync+0x28>
    for(;;)
    800008a0:	a001                	j	800008a0 <uartputc_sync+0x26>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800008a2:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    800008a6:	0ff7f793          	andi	a5,a5,255
    800008aa:	0207f793          	andi	a5,a5,32
    800008ae:	dbf5                	beqz	a5,800008a2 <uartputc_sync+0x28>
    ;
  WriteReg(THR, c);
    800008b0:	0ff4f793          	andi	a5,s1,255
    800008b4:	10000737          	lui	a4,0x10000
    800008b8:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    800008bc:	00000097          	auipc	ra,0x0
    800008c0:	44e080e7          	jalr	1102(ra) # 80000d0a <pop_off>
}
    800008c4:	60e2                	ld	ra,24(sp)
    800008c6:	6442                	ld	s0,16(sp)
    800008c8:	64a2                	ld	s1,8(sp)
    800008ca:	6105                	addi	sp,sp,32
    800008cc:	8082                	ret

00000000800008ce <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008ce:	00008797          	auipc	a5,0x8
    800008d2:	73678793          	addi	a5,a5,1846 # 80009004 <uart_tx_r>
    800008d6:	439c                	lw	a5,0(a5)
    800008d8:	00008717          	auipc	a4,0x8
    800008dc:	73070713          	addi	a4,a4,1840 # 80009008 <uart_tx_w>
    800008e0:	4318                	lw	a4,0(a4)
    800008e2:	08f70b63          	beq	a4,a5,80000978 <uartstart+0xaa>
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008e6:	10000737          	lui	a4,0x10000
    800008ea:	00574703          	lbu	a4,5(a4) # 10000005 <_entry-0x6ffffffb>
    800008ee:	0ff77713          	andi	a4,a4,255
    800008f2:	02077713          	andi	a4,a4,32
    800008f6:	c349                	beqz	a4,80000978 <uartstart+0xaa>
{
    800008f8:	7139                	addi	sp,sp,-64
    800008fa:	fc06                	sd	ra,56(sp)
    800008fc:	f822                	sd	s0,48(sp)
    800008fe:	f426                	sd	s1,40(sp)
    80000900:	f04a                	sd	s2,32(sp)
    80000902:	ec4e                	sd	s3,24(sp)
    80000904:	e852                	sd	s4,16(sp)
    80000906:	e456                	sd	s5,8(sp)
    80000908:	0080                	addi	s0,sp,64
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000090a:	00011a17          	auipc	s4,0x11
    8000090e:	feea0a13          	addi	s4,s4,-18 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000912:	00008497          	auipc	s1,0x8
    80000916:	6f248493          	addi	s1,s1,1778 # 80009004 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    8000091a:	10000937          	lui	s2,0x10000
    if(uart_tx_w == uart_tx_r){
    8000091e:	00008997          	auipc	s3,0x8
    80000922:	6ea98993          	addi	s3,s3,1770 # 80009008 <uart_tx_w>
    int c = uart_tx_buf[uart_tx_r];
    80000926:	00fa0733          	add	a4,s4,a5
    8000092a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000092e:	2785                	addiw	a5,a5,1
    80000930:	41f7d71b          	sraiw	a4,a5,0x1f
    80000934:	01b7571b          	srliw	a4,a4,0x1b
    80000938:	9fb9                	addw	a5,a5,a4
    8000093a:	8bfd                	andi	a5,a5,31
    8000093c:	9f99                	subw	a5,a5,a4
    8000093e:	c09c                	sw	a5,0(s1)
    wakeup(&uart_tx_r);
    80000940:	8526                	mv	a0,s1
    80000942:	00002097          	auipc	ra,0x2
    80000946:	ba2080e7          	jalr	-1118(ra) # 800024e4 <wakeup>
    WriteReg(THR, c);
    8000094a:	01590023          	sb	s5,0(s2) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    8000094e:	409c                	lw	a5,0(s1)
    80000950:	0009a703          	lw	a4,0(s3)
    80000954:	00f70963          	beq	a4,a5,80000966 <uartstart+0x98>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000958:	00594703          	lbu	a4,5(s2)
    8000095c:	0ff77713          	andi	a4,a4,255
    80000960:	02077713          	andi	a4,a4,32
    80000964:	f369                	bnez	a4,80000926 <uartstart+0x58>
  }
}
    80000966:	70e2                	ld	ra,56(sp)
    80000968:	7442                	ld	s0,48(sp)
    8000096a:	74a2                	ld	s1,40(sp)
    8000096c:	7902                	ld	s2,32(sp)
    8000096e:	69e2                	ld	s3,24(sp)
    80000970:	6a42                	ld	s4,16(sp)
    80000972:	6aa2                	ld	s5,8(sp)
    80000974:	6121                	addi	sp,sp,64
    80000976:	8082                	ret
    80000978:	8082                	ret

000000008000097a <uartputc>:
{
    8000097a:	7179                	addi	sp,sp,-48
    8000097c:	f406                	sd	ra,40(sp)
    8000097e:	f022                	sd	s0,32(sp)
    80000980:	ec26                	sd	s1,24(sp)
    80000982:	e84a                	sd	s2,16(sp)
    80000984:	e44e                	sd	s3,8(sp)
    80000986:	e052                	sd	s4,0(sp)
    80000988:	1800                	addi	s0,sp,48
    8000098a:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    8000098c:	00011517          	auipc	a0,0x11
    80000990:	f6c50513          	addi	a0,a0,-148 # 800118f8 <uart_tx_lock>
    80000994:	00000097          	auipc	ra,0x0
    80000998:	322080e7          	jalr	802(ra) # 80000cb6 <acquire>
  if(panicked){
    8000099c:	00008797          	auipc	a5,0x8
    800009a0:	66478793          	addi	a5,a5,1636 # 80009000 <panicked>
    800009a4:	439c                	lw	a5,0(a5)
    800009a6:	2781                	sext.w	a5,a5
    800009a8:	c391                	beqz	a5,800009ac <uartputc+0x32>
    for(;;)
    800009aa:	a001                	j	800009aa <uartputc+0x30>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009ac:	00008797          	auipc	a5,0x8
    800009b0:	65c78793          	addi	a5,a5,1628 # 80009008 <uart_tx_w>
    800009b4:	4398                	lw	a4,0(a5)
    800009b6:	0017079b          	addiw	a5,a4,1
    800009ba:	41f7d69b          	sraiw	a3,a5,0x1f
    800009be:	01b6d69b          	srliw	a3,a3,0x1b
    800009c2:	9fb5                	addw	a5,a5,a3
    800009c4:	8bfd                	andi	a5,a5,31
    800009c6:	9f95                	subw	a5,a5,a3
    800009c8:	00008697          	auipc	a3,0x8
    800009cc:	63c68693          	addi	a3,a3,1596 # 80009004 <uart_tx_r>
    800009d0:	4294                	lw	a3,0(a3)
    800009d2:	04f69263          	bne	a3,a5,80000a16 <uartputc+0x9c>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009d6:	00011a17          	auipc	s4,0x11
    800009da:	f22a0a13          	addi	s4,s4,-222 # 800118f8 <uart_tx_lock>
    800009de:	00008497          	auipc	s1,0x8
    800009e2:	62648493          	addi	s1,s1,1574 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009e6:	00008917          	auipc	s2,0x8
    800009ea:	62290913          	addi	s2,s2,1570 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009ee:	85d2                	mv	a1,s4
    800009f0:	8526                	mv	a0,s1
    800009f2:	00002097          	auipc	ra,0x2
    800009f6:	96c080e7          	jalr	-1684(ra) # 8000235e <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009fa:	00092703          	lw	a4,0(s2)
    800009fe:	0017079b          	addiw	a5,a4,1
    80000a02:	41f7d69b          	sraiw	a3,a5,0x1f
    80000a06:	01b6d69b          	srliw	a3,a3,0x1b
    80000a0a:	9fb5                	addw	a5,a5,a3
    80000a0c:	8bfd                	andi	a5,a5,31
    80000a0e:	9f95                	subw	a5,a5,a3
    80000a10:	4094                	lw	a3,0(s1)
    80000a12:	fcf68ee3          	beq	a3,a5,800009ee <uartputc+0x74>
      uart_tx_buf[uart_tx_w] = c;
    80000a16:	00011497          	auipc	s1,0x11
    80000a1a:	ee248493          	addi	s1,s1,-286 # 800118f8 <uart_tx_lock>
    80000a1e:	9726                	add	a4,a4,s1
    80000a20:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000a24:	00008717          	auipc	a4,0x8
    80000a28:	5ef72223          	sw	a5,1508(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000a2c:	00000097          	auipc	ra,0x0
    80000a30:	ea2080e7          	jalr	-350(ra) # 800008ce <uartstart>
      release(&uart_tx_lock);
    80000a34:	8526                	mv	a0,s1
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	334080e7          	jalr	820(ra) # 80000d6a <release>
}
    80000a3e:	70a2                	ld	ra,40(sp)
    80000a40:	7402                	ld	s0,32(sp)
    80000a42:	64e2                	ld	s1,24(sp)
    80000a44:	6942                	ld	s2,16(sp)
    80000a46:	69a2                	ld	s3,8(sp)
    80000a48:	6a02                	ld	s4,0(sp)
    80000a4a:	6145                	addi	sp,sp,48
    80000a4c:	8082                	ret

0000000080000a4e <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a4e:	1141                	addi	sp,sp,-16
    80000a50:	e422                	sd	s0,8(sp)
    80000a52:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a54:	100007b7          	lui	a5,0x10000
    80000a58:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a5c:	8b85                	andi	a5,a5,1
    80000a5e:	cb91                	beqz	a5,80000a72 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a60:	100007b7          	lui	a5,0x10000
    80000a64:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a68:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a6c:	6422                	ld	s0,8(sp)
    80000a6e:	0141                	addi	sp,sp,16
    80000a70:	8082                	ret
    return -1;
    80000a72:	557d                	li	a0,-1
    80000a74:	bfe5                	j	80000a6c <uartgetc+0x1e>

0000000080000a76 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a76:	1101                	addi	sp,sp,-32
    80000a78:	ec06                	sd	ra,24(sp)
    80000a7a:	e822                	sd	s0,16(sp)
    80000a7c:	e426                	sd	s1,8(sp)
    80000a7e:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a80:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a82:	00000097          	auipc	ra,0x0
    80000a86:	fcc080e7          	jalr	-52(ra) # 80000a4e <uartgetc>
    if(c == -1)
    80000a8a:	00950763          	beq	a0,s1,80000a98 <uartintr+0x22>
      break;
    consoleintr(c);
    80000a8e:	00000097          	auipc	ra,0x0
    80000a92:	840080e7          	jalr	-1984(ra) # 800002ce <consoleintr>
  while(1){
    80000a96:	b7f5                	j	80000a82 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a98:	00011497          	auipc	s1,0x11
    80000a9c:	e6048493          	addi	s1,s1,-416 # 800118f8 <uart_tx_lock>
    80000aa0:	8526                	mv	a0,s1
    80000aa2:	00000097          	auipc	ra,0x0
    80000aa6:	214080e7          	jalr	532(ra) # 80000cb6 <acquire>
  uartstart();
    80000aaa:	00000097          	auipc	ra,0x0
    80000aae:	e24080e7          	jalr	-476(ra) # 800008ce <uartstart>
  release(&uart_tx_lock);
    80000ab2:	8526                	mv	a0,s1
    80000ab4:	00000097          	auipc	ra,0x0
    80000ab8:	2b6080e7          	jalr	694(ra) # 80000d6a <release>
}
    80000abc:	60e2                	ld	ra,24(sp)
    80000abe:	6442                	ld	s0,16(sp)
    80000ac0:	64a2                	ld	s1,8(sp)
    80000ac2:	6105                	addi	sp,sp,32
    80000ac4:	8082                	ret

0000000080000ac6 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000ac6:	1101                	addi	sp,sp,-32
    80000ac8:	ec06                	sd	ra,24(sp)
    80000aca:	e822                	sd	s0,16(sp)
    80000acc:	e426                	sd	s1,8(sp)
    80000ace:	e04a                	sd	s2,0(sp)
    80000ad0:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000ad2:	6785                	lui	a5,0x1
    80000ad4:	17fd                	addi	a5,a5,-1
    80000ad6:	8fe9                	and	a5,a5,a0
    80000ad8:	ebb9                	bnez	a5,80000b2e <kfree+0x68>
    80000ada:	84aa                	mv	s1,a0
    80000adc:	00026797          	auipc	a5,0x26
    80000ae0:	52478793          	addi	a5,a5,1316 # 80027000 <end>
    80000ae4:	04f56563          	bltu	a0,a5,80000b2e <kfree+0x68>
    80000ae8:	47c5                	li	a5,17
    80000aea:	07ee                	slli	a5,a5,0x1b
    80000aec:	04f57163          	bleu	a5,a0,80000b2e <kfree+0x68>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000af0:	6605                	lui	a2,0x1
    80000af2:	4585                	li	a1,1
    80000af4:	00000097          	auipc	ra,0x0
    80000af8:	2be080e7          	jalr	702(ra) # 80000db2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000afc:	00011917          	auipc	s2,0x11
    80000b00:	e3490913          	addi	s2,s2,-460 # 80011930 <kmem>
    80000b04:	854a                	mv	a0,s2
    80000b06:	00000097          	auipc	ra,0x0
    80000b0a:	1b0080e7          	jalr	432(ra) # 80000cb6 <acquire>
  r->next = kmem.freelist;
    80000b0e:	01893783          	ld	a5,24(s2)
    80000b12:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000b14:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000b18:	854a                	mv	a0,s2
    80000b1a:	00000097          	auipc	ra,0x0
    80000b1e:	250080e7          	jalr	592(ra) # 80000d6a <release>
}
    80000b22:	60e2                	ld	ra,24(sp)
    80000b24:	6442                	ld	s0,16(sp)
    80000b26:	64a2                	ld	s1,8(sp)
    80000b28:	6902                	ld	s2,0(sp)
    80000b2a:	6105                	addi	sp,sp,32
    80000b2c:	8082                	ret
    panic("kfree");
    80000b2e:	00007517          	auipc	a0,0x7
    80000b32:	53a50513          	addi	a0,a0,1338 # 80008068 <digits+0x50>
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	abc080e7          	jalr	-1348(ra) # 800005f2 <panic>

0000000080000b3e <freerange>:
{
    80000b3e:	7179                	addi	sp,sp,-48
    80000b40:	f406                	sd	ra,40(sp)
    80000b42:	f022                	sd	s0,32(sp)
    80000b44:	ec26                	sd	s1,24(sp)
    80000b46:	e84a                	sd	s2,16(sp)
    80000b48:	e44e                	sd	s3,8(sp)
    80000b4a:	e052                	sd	s4,0(sp)
    80000b4c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b4e:	6705                	lui	a4,0x1
    80000b50:	fff70793          	addi	a5,a4,-1 # fff <_entry-0x7ffff001>
    80000b54:	00f504b3          	add	s1,a0,a5
    80000b58:	77fd                	lui	a5,0xfffff
    80000b5a:	8cfd                	and	s1,s1,a5
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b5c:	94ba                	add	s1,s1,a4
    80000b5e:	0095ee63          	bltu	a1,s1,80000b7a <freerange+0x3c>
    80000b62:	892e                	mv	s2,a1
    kfree(p);
    80000b64:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b66:	6985                	lui	s3,0x1
    kfree(p);
    80000b68:	01448533          	add	a0,s1,s4
    80000b6c:	00000097          	auipc	ra,0x0
    80000b70:	f5a080e7          	jalr	-166(ra) # 80000ac6 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b74:	94ce                	add	s1,s1,s3
    80000b76:	fe9979e3          	bleu	s1,s2,80000b68 <freerange+0x2a>
}
    80000b7a:	70a2                	ld	ra,40(sp)
    80000b7c:	7402                	ld	s0,32(sp)
    80000b7e:	64e2                	ld	s1,24(sp)
    80000b80:	6942                	ld	s2,16(sp)
    80000b82:	69a2                	ld	s3,8(sp)
    80000b84:	6a02                	ld	s4,0(sp)
    80000b86:	6145                	addi	sp,sp,48
    80000b88:	8082                	ret

0000000080000b8a <kinit>:
{
    80000b8a:	1141                	addi	sp,sp,-16
    80000b8c:	e406                	sd	ra,8(sp)
    80000b8e:	e022                	sd	s0,0(sp)
    80000b90:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b92:	00007597          	auipc	a1,0x7
    80000b96:	4de58593          	addi	a1,a1,1246 # 80008070 <digits+0x58>
    80000b9a:	00011517          	auipc	a0,0x11
    80000b9e:	d9650513          	addi	a0,a0,-618 # 80011930 <kmem>
    80000ba2:	00000097          	auipc	ra,0x0
    80000ba6:	084080e7          	jalr	132(ra) # 80000c26 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000baa:	45c5                	li	a1,17
    80000bac:	05ee                	slli	a1,a1,0x1b
    80000bae:	00026517          	auipc	a0,0x26
    80000bb2:	45250513          	addi	a0,a0,1106 # 80027000 <end>
    80000bb6:	00000097          	auipc	ra,0x0
    80000bba:	f88080e7          	jalr	-120(ra) # 80000b3e <freerange>
}
    80000bbe:	60a2                	ld	ra,8(sp)
    80000bc0:	6402                	ld	s0,0(sp)
    80000bc2:	0141                	addi	sp,sp,16
    80000bc4:	8082                	ret

0000000080000bc6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000bc6:	1101                	addi	sp,sp,-32
    80000bc8:	ec06                	sd	ra,24(sp)
    80000bca:	e822                	sd	s0,16(sp)
    80000bcc:	e426                	sd	s1,8(sp)
    80000bce:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000bd0:	00011497          	auipc	s1,0x11
    80000bd4:	d6048493          	addi	s1,s1,-672 # 80011930 <kmem>
    80000bd8:	8526                	mv	a0,s1
    80000bda:	00000097          	auipc	ra,0x0
    80000bde:	0dc080e7          	jalr	220(ra) # 80000cb6 <acquire>
  r = kmem.freelist;
    80000be2:	6c84                	ld	s1,24(s1)
  if(r)
    80000be4:	c885                	beqz	s1,80000c14 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000be6:	609c                	ld	a5,0(s1)
    80000be8:	00011517          	auipc	a0,0x11
    80000bec:	d4850513          	addi	a0,a0,-696 # 80011930 <kmem>
    80000bf0:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000bf2:	00000097          	auipc	ra,0x0
    80000bf6:	178080e7          	jalr	376(ra) # 80000d6a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bfa:	6605                	lui	a2,0x1
    80000bfc:	4595                	li	a1,5
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	1b2080e7          	jalr	434(ra) # 80000db2 <memset>
  return (void*)r;
}
    80000c08:	8526                	mv	a0,s1
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
  release(&kmem.lock);
    80000c14:	00011517          	auipc	a0,0x11
    80000c18:	d1c50513          	addi	a0,a0,-740 # 80011930 <kmem>
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	14e080e7          	jalr	334(ra) # 80000d6a <release>
  if(r)
    80000c24:	b7d5                	j	80000c08 <kalloc+0x42>

0000000080000c26 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c26:	1141                	addi	sp,sp,-16
    80000c28:	e422                	sd	s0,8(sp)
    80000c2a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c2c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c2e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c32:	00053823          	sd	zero,16(a0)
}
    80000c36:	6422                	ld	s0,8(sp)
    80000c38:	0141                	addi	sp,sp,16
    80000c3a:	8082                	ret

0000000080000c3c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c3c:	411c                	lw	a5,0(a0)
    80000c3e:	e399                	bnez	a5,80000c44 <holding+0x8>
    80000c40:	4501                	li	a0,0
  return r;
}
    80000c42:	8082                	ret
{
    80000c44:	1101                	addi	sp,sp,-32
    80000c46:	ec06                	sd	ra,24(sp)
    80000c48:	e822                	sd	s0,16(sp)
    80000c4a:	e426                	sd	s1,8(sp)
    80000c4c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c4e:	6904                	ld	s1,16(a0)
    80000c50:	00001097          	auipc	ra,0x1
    80000c54:	e58080e7          	jalr	-424(ra) # 80001aa8 <mycpu>
    80000c58:	40a48533          	sub	a0,s1,a0
    80000c5c:	00153513          	seqz	a0,a0
}
    80000c60:	60e2                	ld	ra,24(sp)
    80000c62:	6442                	ld	s0,16(sp)
    80000c64:	64a2                	ld	s1,8(sp)
    80000c66:	6105                	addi	sp,sp,32
    80000c68:	8082                	ret

0000000080000c6a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c6a:	1101                	addi	sp,sp,-32
    80000c6c:	ec06                	sd	ra,24(sp)
    80000c6e:	e822                	sd	s0,16(sp)
    80000c70:	e426                	sd	s1,8(sp)
    80000c72:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100024f3          	csrr	s1,sstatus
    80000c78:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c7c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c7e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c82:	00001097          	auipc	ra,0x1
    80000c86:	e26080e7          	jalr	-474(ra) # 80001aa8 <mycpu>
    80000c8a:	5d3c                	lw	a5,120(a0)
    80000c8c:	cf89                	beqz	a5,80000ca6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c8e:	00001097          	auipc	ra,0x1
    80000c92:	e1a080e7          	jalr	-486(ra) # 80001aa8 <mycpu>
    80000c96:	5d3c                	lw	a5,120(a0)
    80000c98:	2785                	addiw	a5,a5,1
    80000c9a:	dd3c                	sw	a5,120(a0)
}
    80000c9c:	60e2                	ld	ra,24(sp)
    80000c9e:	6442                	ld	s0,16(sp)
    80000ca0:	64a2                	ld	s1,8(sp)
    80000ca2:	6105                	addi	sp,sp,32
    80000ca4:	8082                	ret
    mycpu()->intena = old;
    80000ca6:	00001097          	auipc	ra,0x1
    80000caa:	e02080e7          	jalr	-510(ra) # 80001aa8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cae:	8085                	srli	s1,s1,0x1
    80000cb0:	8885                	andi	s1,s1,1
    80000cb2:	dd64                	sw	s1,124(a0)
    80000cb4:	bfe9                	j	80000c8e <push_off+0x24>

0000000080000cb6 <acquire>:
{
    80000cb6:	1101                	addi	sp,sp,-32
    80000cb8:	ec06                	sd	ra,24(sp)
    80000cba:	e822                	sd	s0,16(sp)
    80000cbc:	e426                	sd	s1,8(sp)
    80000cbe:	1000                	addi	s0,sp,32
    80000cc0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000cc2:	00000097          	auipc	ra,0x0
    80000cc6:	fa8080e7          	jalr	-88(ra) # 80000c6a <push_off>
  if(holding(lk))
    80000cca:	8526                	mv	a0,s1
    80000ccc:	00000097          	auipc	ra,0x0
    80000cd0:	f70080e7          	jalr	-144(ra) # 80000c3c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cd4:	4705                	li	a4,1
  if(holding(lk))
    80000cd6:	e115                	bnez	a0,80000cfa <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cd8:	87ba                	mv	a5,a4
    80000cda:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cde:	2781                	sext.w	a5,a5
    80000ce0:	ffe5                	bnez	a5,80000cd8 <acquire+0x22>
  __sync_synchronize();
    80000ce2:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000ce6:	00001097          	auipc	ra,0x1
    80000cea:	dc2080e7          	jalr	-574(ra) # 80001aa8 <mycpu>
    80000cee:	e888                	sd	a0,16(s1)
}
    80000cf0:	60e2                	ld	ra,24(sp)
    80000cf2:	6442                	ld	s0,16(sp)
    80000cf4:	64a2                	ld	s1,8(sp)
    80000cf6:	6105                	addi	sp,sp,32
    80000cf8:	8082                	ret
    panic("acquire");
    80000cfa:	00007517          	auipc	a0,0x7
    80000cfe:	37e50513          	addi	a0,a0,894 # 80008078 <digits+0x60>
    80000d02:	00000097          	auipc	ra,0x0
    80000d06:	8f0080e7          	jalr	-1808(ra) # 800005f2 <panic>

0000000080000d0a <pop_off>:

void
pop_off(void)
{
    80000d0a:	1141                	addi	sp,sp,-16
    80000d0c:	e406                	sd	ra,8(sp)
    80000d0e:	e022                	sd	s0,0(sp)
    80000d10:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d12:	00001097          	auipc	ra,0x1
    80000d16:	d96080e7          	jalr	-618(ra) # 80001aa8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d1a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d1e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d20:	e78d                	bnez	a5,80000d4a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d22:	5d3c                	lw	a5,120(a0)
    80000d24:	02f05b63          	blez	a5,80000d5a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d28:	37fd                	addiw	a5,a5,-1
    80000d2a:	0007871b          	sext.w	a4,a5
    80000d2e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d30:	eb09                	bnez	a4,80000d42 <pop_off+0x38>
    80000d32:	5d7c                	lw	a5,124(a0)
    80000d34:	c799                	beqz	a5,80000d42 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d36:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d3a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d3e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d42:	60a2                	ld	ra,8(sp)
    80000d44:	6402                	ld	s0,0(sp)
    80000d46:	0141                	addi	sp,sp,16
    80000d48:	8082                	ret
    panic("pop_off - interruptible");
    80000d4a:	00007517          	auipc	a0,0x7
    80000d4e:	33650513          	addi	a0,a0,822 # 80008080 <digits+0x68>
    80000d52:	00000097          	auipc	ra,0x0
    80000d56:	8a0080e7          	jalr	-1888(ra) # 800005f2 <panic>
    panic("pop_off");
    80000d5a:	00007517          	auipc	a0,0x7
    80000d5e:	33e50513          	addi	a0,a0,830 # 80008098 <digits+0x80>
    80000d62:	00000097          	auipc	ra,0x0
    80000d66:	890080e7          	jalr	-1904(ra) # 800005f2 <panic>

0000000080000d6a <release>:
{
    80000d6a:	1101                	addi	sp,sp,-32
    80000d6c:	ec06                	sd	ra,24(sp)
    80000d6e:	e822                	sd	s0,16(sp)
    80000d70:	e426                	sd	s1,8(sp)
    80000d72:	1000                	addi	s0,sp,32
    80000d74:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d76:	00000097          	auipc	ra,0x0
    80000d7a:	ec6080e7          	jalr	-314(ra) # 80000c3c <holding>
    80000d7e:	c115                	beqz	a0,80000da2 <release+0x38>
  lk->cpu = 0;
    80000d80:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d84:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d88:	0f50000f          	fence	iorw,ow
    80000d8c:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d90:	00000097          	auipc	ra,0x0
    80000d94:	f7a080e7          	jalr	-134(ra) # 80000d0a <pop_off>
}
    80000d98:	60e2                	ld	ra,24(sp)
    80000d9a:	6442                	ld	s0,16(sp)
    80000d9c:	64a2                	ld	s1,8(sp)
    80000d9e:	6105                	addi	sp,sp,32
    80000da0:	8082                	ret
    panic("release");
    80000da2:	00007517          	auipc	a0,0x7
    80000da6:	2fe50513          	addi	a0,a0,766 # 800080a0 <digits+0x88>
    80000daa:	00000097          	auipc	ra,0x0
    80000dae:	848080e7          	jalr	-1976(ra) # 800005f2 <panic>

0000000080000db2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000db2:	1141                	addi	sp,sp,-16
    80000db4:	e422                	sd	s0,8(sp)
    80000db6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000db8:	ce09                	beqz	a2,80000dd2 <memset+0x20>
    80000dba:	87aa                	mv	a5,a0
    80000dbc:	fff6071b          	addiw	a4,a2,-1
    80000dc0:	1702                	slli	a4,a4,0x20
    80000dc2:	9301                	srli	a4,a4,0x20
    80000dc4:	0705                	addi	a4,a4,1
    80000dc6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000dc8:	00b78023          	sb	a1,0(a5) # fffffffffffff000 <end+0xffffffff7ffd8000>
  for(i = 0; i < n; i++){
    80000dcc:	0785                	addi	a5,a5,1
    80000dce:	fee79de3          	bne	a5,a4,80000dc8 <memset+0x16>
  }
  return dst;
}
    80000dd2:	6422                	ld	s0,8(sp)
    80000dd4:	0141                	addi	sp,sp,16
    80000dd6:	8082                	ret

0000000080000dd8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000dd8:	1141                	addi	sp,sp,-16
    80000dda:	e422                	sd	s0,8(sp)
    80000ddc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dde:	ce15                	beqz	a2,80000e1a <memcmp+0x42>
    80000de0:	fff6069b          	addiw	a3,a2,-1
    if(*s1 != *s2)
    80000de4:	00054783          	lbu	a5,0(a0)
    80000de8:	0005c703          	lbu	a4,0(a1)
    80000dec:	02e79063          	bne	a5,a4,80000e0c <memcmp+0x34>
    80000df0:	1682                	slli	a3,a3,0x20
    80000df2:	9281                	srli	a3,a3,0x20
    80000df4:	0685                	addi	a3,a3,1
    80000df6:	96aa                	add	a3,a3,a0
      return *s1 - *s2;
    s1++, s2++;
    80000df8:	0505                	addi	a0,a0,1
    80000dfa:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dfc:	00d50d63          	beq	a0,a3,80000e16 <memcmp+0x3e>
    if(*s1 != *s2)
    80000e00:	00054783          	lbu	a5,0(a0)
    80000e04:	0005c703          	lbu	a4,0(a1)
    80000e08:	fee788e3          	beq	a5,a4,80000df8 <memcmp+0x20>
      return *s1 - *s2;
    80000e0c:	40e7853b          	subw	a0,a5,a4
  }

  return 0;
}
    80000e10:	6422                	ld	s0,8(sp)
    80000e12:	0141                	addi	sp,sp,16
    80000e14:	8082                	ret
  return 0;
    80000e16:	4501                	li	a0,0
    80000e18:	bfe5                	j	80000e10 <memcmp+0x38>
    80000e1a:	4501                	li	a0,0
    80000e1c:	bfd5                	j	80000e10 <memcmp+0x38>

0000000080000e1e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e1e:	1141                	addi	sp,sp,-16
    80000e20:	e422                	sd	s0,8(sp)
    80000e22:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e24:	00a5f963          	bleu	a0,a1,80000e36 <memmove+0x18>
    80000e28:	02061713          	slli	a4,a2,0x20
    80000e2c:	9301                	srli	a4,a4,0x20
    80000e2e:	00e587b3          	add	a5,a1,a4
    80000e32:	02f56563          	bltu	a0,a5,80000e5c <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e36:	fff6069b          	addiw	a3,a2,-1
    80000e3a:	ce11                	beqz	a2,80000e56 <memmove+0x38>
    80000e3c:	1682                	slli	a3,a3,0x20
    80000e3e:	9281                	srli	a3,a3,0x20
    80000e40:	0685                	addi	a3,a3,1
    80000e42:	96ae                	add	a3,a3,a1
    80000e44:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e46:	0585                	addi	a1,a1,1
    80000e48:	0785                	addi	a5,a5,1
    80000e4a:	fff5c703          	lbu	a4,-1(a1)
    80000e4e:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e52:	fed59ae3          	bne	a1,a3,80000e46 <memmove+0x28>

  return dst;
}
    80000e56:	6422                	ld	s0,8(sp)
    80000e58:	0141                	addi	sp,sp,16
    80000e5a:	8082                	ret
    d += n;
    80000e5c:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e5e:	fff6069b          	addiw	a3,a2,-1
    80000e62:	da75                	beqz	a2,80000e56 <memmove+0x38>
    80000e64:	02069613          	slli	a2,a3,0x20
    80000e68:	9201                	srli	a2,a2,0x20
    80000e6a:	fff64613          	not	a2,a2
    80000e6e:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e70:	17fd                	addi	a5,a5,-1
    80000e72:	177d                	addi	a4,a4,-1
    80000e74:	0007c683          	lbu	a3,0(a5)
    80000e78:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e7c:	fef61ae3          	bne	a2,a5,80000e70 <memmove+0x52>
    80000e80:	bfd9                	j	80000e56 <memmove+0x38>

0000000080000e82 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e82:	1141                	addi	sp,sp,-16
    80000e84:	e406                	sd	ra,8(sp)
    80000e86:	e022                	sd	s0,0(sp)
    80000e88:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e8a:	00000097          	auipc	ra,0x0
    80000e8e:	f94080e7          	jalr	-108(ra) # 80000e1e <memmove>
}
    80000e92:	60a2                	ld	ra,8(sp)
    80000e94:	6402                	ld	s0,0(sp)
    80000e96:	0141                	addi	sp,sp,16
    80000e98:	8082                	ret

0000000080000e9a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e9a:	1141                	addi	sp,sp,-16
    80000e9c:	e422                	sd	s0,8(sp)
    80000e9e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000ea0:	c229                	beqz	a2,80000ee2 <strncmp+0x48>
    80000ea2:	00054783          	lbu	a5,0(a0)
    80000ea6:	c795                	beqz	a5,80000ed2 <strncmp+0x38>
    80000ea8:	0005c703          	lbu	a4,0(a1)
    80000eac:	02f71363          	bne	a4,a5,80000ed2 <strncmp+0x38>
    80000eb0:	fff6071b          	addiw	a4,a2,-1
    80000eb4:	1702                	slli	a4,a4,0x20
    80000eb6:	9301                	srli	a4,a4,0x20
    80000eb8:	0705                	addi	a4,a4,1
    80000eba:	972a                	add	a4,a4,a0
    n--, p++, q++;
    80000ebc:	0505                	addi	a0,a0,1
    80000ebe:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000ec0:	02e50363          	beq	a0,a4,80000ee6 <strncmp+0x4c>
    80000ec4:	00054783          	lbu	a5,0(a0)
    80000ec8:	c789                	beqz	a5,80000ed2 <strncmp+0x38>
    80000eca:	0005c683          	lbu	a3,0(a1)
    80000ece:	fef687e3          	beq	a3,a5,80000ebc <strncmp+0x22>
  if(n == 0)
    return 0;
  return (uchar)*p - (uchar)*q;
    80000ed2:	00054503          	lbu	a0,0(a0)
    80000ed6:	0005c783          	lbu	a5,0(a1)
    80000eda:	9d1d                	subw	a0,a0,a5
}
    80000edc:	6422                	ld	s0,8(sp)
    80000ede:	0141                	addi	sp,sp,16
    80000ee0:	8082                	ret
    return 0;
    80000ee2:	4501                	li	a0,0
    80000ee4:	bfe5                	j	80000edc <strncmp+0x42>
    80000ee6:	4501                	li	a0,0
    80000ee8:	bfd5                	j	80000edc <strncmp+0x42>

0000000080000eea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000eea:	1141                	addi	sp,sp,-16
    80000eec:	e422                	sd	s0,8(sp)
    80000eee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ef0:	872a                	mv	a4,a0
    80000ef2:	a011                	j	80000ef6 <strncpy+0xc>
    80000ef4:	8636                	mv	a2,a3
    80000ef6:	fff6069b          	addiw	a3,a2,-1
    80000efa:	00c05963          	blez	a2,80000f0c <strncpy+0x22>
    80000efe:	0705                	addi	a4,a4,1
    80000f00:	0005c783          	lbu	a5,0(a1)
    80000f04:	fef70fa3          	sb	a5,-1(a4)
    80000f08:	0585                	addi	a1,a1,1
    80000f0a:	f7ed                	bnez	a5,80000ef4 <strncpy+0xa>
    ;
  while(n-- > 0)
    80000f0c:	00d05c63          	blez	a3,80000f24 <strncpy+0x3a>
    80000f10:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f12:	0685                	addi	a3,a3,1
    80000f14:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f18:	fff6c793          	not	a5,a3
    80000f1c:	9fb9                	addw	a5,a5,a4
    80000f1e:	9fb1                	addw	a5,a5,a2
    80000f20:	fef049e3          	bgtz	a5,80000f12 <strncpy+0x28>
  return os;
}
    80000f24:	6422                	ld	s0,8(sp)
    80000f26:	0141                	addi	sp,sp,16
    80000f28:	8082                	ret

0000000080000f2a <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f2a:	1141                	addi	sp,sp,-16
    80000f2c:	e422                	sd	s0,8(sp)
    80000f2e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f30:	02c05363          	blez	a2,80000f56 <safestrcpy+0x2c>
    80000f34:	fff6069b          	addiw	a3,a2,-1
    80000f38:	1682                	slli	a3,a3,0x20
    80000f3a:	9281                	srli	a3,a3,0x20
    80000f3c:	96ae                	add	a3,a3,a1
    80000f3e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f40:	00d58963          	beq	a1,a3,80000f52 <safestrcpy+0x28>
    80000f44:	0585                	addi	a1,a1,1
    80000f46:	0785                	addi	a5,a5,1
    80000f48:	fff5c703          	lbu	a4,-1(a1)
    80000f4c:	fee78fa3          	sb	a4,-1(a5)
    80000f50:	fb65                	bnez	a4,80000f40 <safestrcpy+0x16>
    ;
  *s = 0;
    80000f52:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f56:	6422                	ld	s0,8(sp)
    80000f58:	0141                	addi	sp,sp,16
    80000f5a:	8082                	ret

0000000080000f5c <strlen>:

int
strlen(const char *s)
{
    80000f5c:	1141                	addi	sp,sp,-16
    80000f5e:	e422                	sd	s0,8(sp)
    80000f60:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f62:	00054783          	lbu	a5,0(a0)
    80000f66:	cf91                	beqz	a5,80000f82 <strlen+0x26>
    80000f68:	0505                	addi	a0,a0,1
    80000f6a:	87aa                	mv	a5,a0
    80000f6c:	4685                	li	a3,1
    80000f6e:	9e89                	subw	a3,a3,a0
    80000f70:	00f6853b          	addw	a0,a3,a5
    80000f74:	0785                	addi	a5,a5,1
    80000f76:	fff7c703          	lbu	a4,-1(a5)
    80000f7a:	fb7d                	bnez	a4,80000f70 <strlen+0x14>
    ;
  return n;
}
    80000f7c:	6422                	ld	s0,8(sp)
    80000f7e:	0141                	addi	sp,sp,16
    80000f80:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f82:	4501                	li	a0,0
    80000f84:	bfe5                	j	80000f7c <strlen+0x20>

0000000080000f86 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f86:	1141                	addi	sp,sp,-16
    80000f88:	e406                	sd	ra,8(sp)
    80000f8a:	e022                	sd	s0,0(sp)
    80000f8c:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f8e:	00001097          	auipc	ra,0x1
    80000f92:	b0a080e7          	jalr	-1270(ra) # 80001a98 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f96:	00008717          	auipc	a4,0x8
    80000f9a:	07670713          	addi	a4,a4,118 # 8000900c <started>
  if(cpuid() == 0){
    80000f9e:	c139                	beqz	a0,80000fe4 <main+0x5e>
    while(started == 0)
    80000fa0:	431c                	lw	a5,0(a4)
    80000fa2:	2781                	sext.w	a5,a5
    80000fa4:	dff5                	beqz	a5,80000fa0 <main+0x1a>
      ;
    __sync_synchronize();
    80000fa6:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000faa:	00001097          	auipc	ra,0x1
    80000fae:	aee080e7          	jalr	-1298(ra) # 80001a98 <cpuid>
    80000fb2:	85aa                	mv	a1,a0
    80000fb4:	00007517          	auipc	a0,0x7
    80000fb8:	10c50513          	addi	a0,a0,268 # 800080c0 <digits+0xa8>
    80000fbc:	fffff097          	auipc	ra,0xfffff
    80000fc0:	688080e7          	jalr	1672(ra) # 80000644 <printf>
    kvminithart();    // turn on paging
    80000fc4:	00000097          	auipc	ra,0x0
    80000fc8:	0d8080e7          	jalr	216(ra) # 8000109c <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fcc:	00001097          	auipc	ra,0x1
    80000fd0:	7e2080e7          	jalr	2018(ra) # 800027ae <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fd4:	00005097          	auipc	ra,0x5
    80000fd8:	f5c080e7          	jalr	-164(ra) # 80005f30 <plicinithart>
  }

  scheduler();        
    80000fdc:	00001097          	auipc	ra,0x1
    80000fe0:	0a2080e7          	jalr	162(ra) # 8000207e <scheduler>
    consoleinit();
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	49e080e7          	jalr	1182(ra) # 80000482 <consoleinit>
    printfinit();
    80000fec:	fffff097          	auipc	ra,0xfffff
    80000ff0:	588080e7          	jalr	1416(ra) # 80000574 <printfinit>
    printf("\n");
    80000ff4:	00007517          	auipc	a0,0x7
    80000ff8:	0dc50513          	addi	a0,a0,220 # 800080d0 <digits+0xb8>
    80000ffc:	fffff097          	auipc	ra,0xfffff
    80001000:	648080e7          	jalr	1608(ra) # 80000644 <printf>
    printf("xv6 kernel is booting\n");
    80001004:	00007517          	auipc	a0,0x7
    80001008:	0a450513          	addi	a0,a0,164 # 800080a8 <digits+0x90>
    8000100c:	fffff097          	auipc	ra,0xfffff
    80001010:	638080e7          	jalr	1592(ra) # 80000644 <printf>
    printf("\n");
    80001014:	00007517          	auipc	a0,0x7
    80001018:	0bc50513          	addi	a0,a0,188 # 800080d0 <digits+0xb8>
    8000101c:	fffff097          	auipc	ra,0xfffff
    80001020:	628080e7          	jalr	1576(ra) # 80000644 <printf>
    kinit();         // physical page allocator
    80001024:	00000097          	auipc	ra,0x0
    80001028:	b66080e7          	jalr	-1178(ra) # 80000b8a <kinit>
    kvminit();       // create kernel page table
    8000102c:	00000097          	auipc	ra,0x0
    80001030:	2a6080e7          	jalr	678(ra) # 800012d2 <kvminit>
    kvminithart();   // turn on paging
    80001034:	00000097          	auipc	ra,0x0
    80001038:	068080e7          	jalr	104(ra) # 8000109c <kvminithart>
    procinit();      // process table
    8000103c:	00001097          	auipc	ra,0x1
    80001040:	98c080e7          	jalr	-1652(ra) # 800019c8 <procinit>
    trapinit();      // trap vectors
    80001044:	00001097          	auipc	ra,0x1
    80001048:	742080e7          	jalr	1858(ra) # 80002786 <trapinit>
    trapinithart();  // install kernel trap vector
    8000104c:	00001097          	auipc	ra,0x1
    80001050:	762080e7          	jalr	1890(ra) # 800027ae <trapinithart>
    plicinit();      // set up interrupt controller
    80001054:	00005097          	auipc	ra,0x5
    80001058:	ec6080e7          	jalr	-314(ra) # 80005f1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000105c:	00005097          	auipc	ra,0x5
    80001060:	ed4080e7          	jalr	-300(ra) # 80005f30 <plicinithart>
    binit();         // buffer cache
    80001064:	00002097          	auipc	ra,0x2
    80001068:	fa8080e7          	jalr	-88(ra) # 8000300c <binit>
    iinit();         // inode cache
    8000106c:	00002097          	auipc	ra,0x2
    80001070:	67a080e7          	jalr	1658(ra) # 800036e6 <iinit>
    fileinit();      // file table
    80001074:	00003097          	auipc	ra,0x3
    80001078:	640080e7          	jalr	1600(ra) # 800046b4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000107c:	00005097          	auipc	ra,0x5
    80001080:	fbe080e7          	jalr	-66(ra) # 8000603a <virtio_disk_init>
    userinit();      // first user process
    80001084:	00001097          	auipc	ra,0x1
    80001088:	d90080e7          	jalr	-624(ra) # 80001e14 <userinit>
    __sync_synchronize();
    8000108c:	0ff0000f          	fence
    started = 1;
    80001090:	4785                	li	a5,1
    80001092:	00008717          	auipc	a4,0x8
    80001096:	f6f72d23          	sw	a5,-134(a4) # 8000900c <started>
    8000109a:	b789                	j	80000fdc <main+0x56>

000000008000109c <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000109c:	1141                	addi	sp,sp,-16
    8000109e:	e422                	sd	s0,8(sp)
    800010a0:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010a2:	00008797          	auipc	a5,0x8
    800010a6:	f6e78793          	addi	a5,a5,-146 # 80009010 <kernel_pagetable>
    800010aa:	639c                	ld	a5,0(a5)
    800010ac:	83b1                	srli	a5,a5,0xc
    800010ae:	577d                	li	a4,-1
    800010b0:	177e                	slli	a4,a4,0x3f
    800010b2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010b4:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010b8:	12000073          	sfence.vma
  sfence_vma();
}
    800010bc:	6422                	ld	s0,8(sp)
    800010be:	0141                	addi	sp,sp,16
    800010c0:	8082                	ret

00000000800010c2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010c2:	7139                	addi	sp,sp,-64
    800010c4:	fc06                	sd	ra,56(sp)
    800010c6:	f822                	sd	s0,48(sp)
    800010c8:	f426                	sd	s1,40(sp)
    800010ca:	f04a                	sd	s2,32(sp)
    800010cc:	ec4e                	sd	s3,24(sp)
    800010ce:	e852                	sd	s4,16(sp)
    800010d0:	e456                	sd	s5,8(sp)
    800010d2:	e05a                	sd	s6,0(sp)
    800010d4:	0080                	addi	s0,sp,64
    800010d6:	84aa                	mv	s1,a0
    800010d8:	89ae                	mv	s3,a1
    800010da:	8b32                	mv	s6,a2
  if(va >= MAXVA)
    800010dc:	57fd                	li	a5,-1
    800010de:	83e9                	srli	a5,a5,0x1a
    800010e0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010e2:	4ab1                	li	s5,12
  if(va >= MAXVA)
    800010e4:	04b7f263          	bleu	a1,a5,80001128 <walk+0x66>
    panic("walk");
    800010e8:	00007517          	auipc	a0,0x7
    800010ec:	ff050513          	addi	a0,a0,-16 # 800080d8 <digits+0xc0>
    800010f0:	fffff097          	auipc	ra,0xfffff
    800010f4:	502080e7          	jalr	1282(ra) # 800005f2 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010f8:	060b0663          	beqz	s6,80001164 <walk+0xa2>
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	aca080e7          	jalr	-1334(ra) # 80000bc6 <kalloc>
    80001104:	84aa                	mv	s1,a0
    80001106:	c529                	beqz	a0,80001150 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001108:	6605                	lui	a2,0x1
    8000110a:	4581                	li	a1,0
    8000110c:	00000097          	auipc	ra,0x0
    80001110:	ca6080e7          	jalr	-858(ra) # 80000db2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001114:	00c4d793          	srli	a5,s1,0xc
    80001118:	07aa                	slli	a5,a5,0xa
    8000111a:	0017e793          	ori	a5,a5,1
    8000111e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001122:	3a5d                	addiw	s4,s4,-9
    80001124:	035a0063          	beq	s4,s5,80001144 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001128:	0149d933          	srl	s2,s3,s4
    8000112c:	1ff97913          	andi	s2,s2,511
    80001130:	090e                	slli	s2,s2,0x3
    80001132:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001134:	00093483          	ld	s1,0(s2)
    80001138:	0014f793          	andi	a5,s1,1
    8000113c:	dfd5                	beqz	a5,800010f8 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000113e:	80a9                	srli	s1,s1,0xa
    80001140:	04b2                	slli	s1,s1,0xc
    80001142:	b7c5                	j	80001122 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001144:	00c9d513          	srli	a0,s3,0xc
    80001148:	1ff57513          	andi	a0,a0,511
    8000114c:	050e                	slli	a0,a0,0x3
    8000114e:	9526                	add	a0,a0,s1
}
    80001150:	70e2                	ld	ra,56(sp)
    80001152:	7442                	ld	s0,48(sp)
    80001154:	74a2                	ld	s1,40(sp)
    80001156:	7902                	ld	s2,32(sp)
    80001158:	69e2                	ld	s3,24(sp)
    8000115a:	6a42                	ld	s4,16(sp)
    8000115c:	6aa2                	ld	s5,8(sp)
    8000115e:	6b02                	ld	s6,0(sp)
    80001160:	6121                	addi	sp,sp,64
    80001162:	8082                	ret
        return 0;
    80001164:	4501                	li	a0,0
    80001166:	b7ed                	j	80001150 <walk+0x8e>

0000000080001168 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001168:	57fd                	li	a5,-1
    8000116a:	83e9                	srli	a5,a5,0x1a
    8000116c:	00b7f463          	bleu	a1,a5,80001174 <walkaddr+0xc>
    return 0;
    80001170:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001172:	8082                	ret
{
    80001174:	1141                	addi	sp,sp,-16
    80001176:	e406                	sd	ra,8(sp)
    80001178:	e022                	sd	s0,0(sp)
    8000117a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000117c:	4601                	li	a2,0
    8000117e:	00000097          	auipc	ra,0x0
    80001182:	f44080e7          	jalr	-188(ra) # 800010c2 <walk>
  if(pte == 0)
    80001186:	c105                	beqz	a0,800011a6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001188:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000118a:	0117f693          	andi	a3,a5,17
    8000118e:	4745                	li	a4,17
    return 0;
    80001190:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001192:	00e68663          	beq	a3,a4,8000119e <walkaddr+0x36>
}
    80001196:	60a2                	ld	ra,8(sp)
    80001198:	6402                	ld	s0,0(sp)
    8000119a:	0141                	addi	sp,sp,16
    8000119c:	8082                	ret
  pa = PTE2PA(*pte);
    8000119e:	00a7d513          	srli	a0,a5,0xa
    800011a2:	0532                	slli	a0,a0,0xc
  return pa;
    800011a4:	bfcd                	j	80001196 <walkaddr+0x2e>
    return 0;
    800011a6:	4501                	li	a0,0
    800011a8:	b7fd                	j	80001196 <walkaddr+0x2e>

00000000800011aa <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800011aa:	1101                	addi	sp,sp,-32
    800011ac:	ec06                	sd	ra,24(sp)
    800011ae:	e822                	sd	s0,16(sp)
    800011b0:	e426                	sd	s1,8(sp)
    800011b2:	1000                	addi	s0,sp,32
    800011b4:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800011b6:	6785                	lui	a5,0x1
    800011b8:	17fd                	addi	a5,a5,-1
    800011ba:	00f574b3          	and	s1,a0,a5
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800011be:	4601                	li	a2,0
    800011c0:	00008797          	auipc	a5,0x8
    800011c4:	e5078793          	addi	a5,a5,-432 # 80009010 <kernel_pagetable>
    800011c8:	6388                	ld	a0,0(a5)
    800011ca:	00000097          	auipc	ra,0x0
    800011ce:	ef8080e7          	jalr	-264(ra) # 800010c2 <walk>
  if(pte == 0)
    800011d2:	cd09                	beqz	a0,800011ec <kvmpa+0x42>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800011d4:	6108                	ld	a0,0(a0)
    800011d6:	00157793          	andi	a5,a0,1
    800011da:	c38d                	beqz	a5,800011fc <kvmpa+0x52>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800011dc:	8129                	srli	a0,a0,0xa
    800011de:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800011e0:	9526                	add	a0,a0,s1
    800011e2:	60e2                	ld	ra,24(sp)
    800011e4:	6442                	ld	s0,16(sp)
    800011e6:	64a2                	ld	s1,8(sp)
    800011e8:	6105                	addi	sp,sp,32
    800011ea:	8082                	ret
    panic("kvmpa");
    800011ec:	00007517          	auipc	a0,0x7
    800011f0:	ef450513          	addi	a0,a0,-268 # 800080e0 <digits+0xc8>
    800011f4:	fffff097          	auipc	ra,0xfffff
    800011f8:	3fe080e7          	jalr	1022(ra) # 800005f2 <panic>
    panic("kvmpa");
    800011fc:	00007517          	auipc	a0,0x7
    80001200:	ee450513          	addi	a0,a0,-284 # 800080e0 <digits+0xc8>
    80001204:	fffff097          	auipc	ra,0xfffff
    80001208:	3ee080e7          	jalr	1006(ra) # 800005f2 <panic>

000000008000120c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000120c:	715d                	addi	sp,sp,-80
    8000120e:	e486                	sd	ra,72(sp)
    80001210:	e0a2                	sd	s0,64(sp)
    80001212:	fc26                	sd	s1,56(sp)
    80001214:	f84a                	sd	s2,48(sp)
    80001216:	f44e                	sd	s3,40(sp)
    80001218:	f052                	sd	s4,32(sp)
    8000121a:	ec56                	sd	s5,24(sp)
    8000121c:	e85a                	sd	s6,16(sp)
    8000121e:	e45e                	sd	s7,8(sp)
    80001220:	0880                	addi	s0,sp,80
    80001222:	8aaa                	mv	s5,a0
    80001224:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001226:	79fd                	lui	s3,0xfffff
    80001228:	0135fa33          	and	s4,a1,s3
  last = PGROUNDDOWN(va + size - 1);
    8000122c:	167d                	addi	a2,a2,-1
    8000122e:	962e                	add	a2,a2,a1
    80001230:	013679b3          	and	s3,a2,s3
  a = PGROUNDDOWN(va);
    80001234:	8952                	mv	s2,s4
    80001236:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000123a:	6b85                	lui	s7,0x1
    8000123c:	a811                	j	80001250 <mappages+0x44>
      panic("remap");
    8000123e:	00007517          	auipc	a0,0x7
    80001242:	eaa50513          	addi	a0,a0,-342 # 800080e8 <digits+0xd0>
    80001246:	fffff097          	auipc	ra,0xfffff
    8000124a:	3ac080e7          	jalr	940(ra) # 800005f2 <panic>
    a += PGSIZE;
    8000124e:	995e                	add	s2,s2,s7
  for(;;){
    80001250:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001254:	4605                	li	a2,1
    80001256:	85ca                	mv	a1,s2
    80001258:	8556                	mv	a0,s5
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	e68080e7          	jalr	-408(ra) # 800010c2 <walk>
    80001262:	cd19                	beqz	a0,80001280 <mappages+0x74>
    if(*pte & PTE_V)
    80001264:	611c                	ld	a5,0(a0)
    80001266:	8b85                	andi	a5,a5,1
    80001268:	fbf9                	bnez	a5,8000123e <mappages+0x32>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000126a:	80b1                	srli	s1,s1,0xc
    8000126c:	04aa                	slli	s1,s1,0xa
    8000126e:	0164e4b3          	or	s1,s1,s6
    80001272:	0014e493          	ori	s1,s1,1
    80001276:	e104                	sd	s1,0(a0)
    if(a == last)
    80001278:	fd391be3          	bne	s2,s3,8000124e <mappages+0x42>
    pa += PGSIZE;
  }
  return 0;
    8000127c:	4501                	li	a0,0
    8000127e:	a011                	j	80001282 <mappages+0x76>
      return -1;
    80001280:	557d                	li	a0,-1
}
    80001282:	60a6                	ld	ra,72(sp)
    80001284:	6406                	ld	s0,64(sp)
    80001286:	74e2                	ld	s1,56(sp)
    80001288:	7942                	ld	s2,48(sp)
    8000128a:	79a2                	ld	s3,40(sp)
    8000128c:	7a02                	ld	s4,32(sp)
    8000128e:	6ae2                	ld	s5,24(sp)
    80001290:	6b42                	ld	s6,16(sp)
    80001292:	6ba2                	ld	s7,8(sp)
    80001294:	6161                	addi	sp,sp,80
    80001296:	8082                	ret

0000000080001298 <kvmmap>:
{
    80001298:	1141                	addi	sp,sp,-16
    8000129a:	e406                	sd	ra,8(sp)
    8000129c:	e022                	sd	s0,0(sp)
    8000129e:	0800                	addi	s0,sp,16
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800012a0:	8736                	mv	a4,a3
    800012a2:	86ae                	mv	a3,a1
    800012a4:	85aa                	mv	a1,a0
    800012a6:	00008797          	auipc	a5,0x8
    800012aa:	d6a78793          	addi	a5,a5,-662 # 80009010 <kernel_pagetable>
    800012ae:	6388                	ld	a0,0(a5)
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f5c080e7          	jalr	-164(ra) # 8000120c <mappages>
    800012b8:	e509                	bnez	a0,800012c2 <kvmmap+0x2a>
}
    800012ba:	60a2                	ld	ra,8(sp)
    800012bc:	6402                	ld	s0,0(sp)
    800012be:	0141                	addi	sp,sp,16
    800012c0:	8082                	ret
    panic("kvmmap");
    800012c2:	00007517          	auipc	a0,0x7
    800012c6:	e2e50513          	addi	a0,a0,-466 # 800080f0 <digits+0xd8>
    800012ca:	fffff097          	auipc	ra,0xfffff
    800012ce:	328080e7          	jalr	808(ra) # 800005f2 <panic>

00000000800012d2 <kvminit>:
{
    800012d2:	1101                	addi	sp,sp,-32
    800012d4:	ec06                	sd	ra,24(sp)
    800012d6:	e822                	sd	s0,16(sp)
    800012d8:	e426                	sd	s1,8(sp)
    800012da:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800012dc:	00000097          	auipc	ra,0x0
    800012e0:	8ea080e7          	jalr	-1814(ra) # 80000bc6 <kalloc>
    800012e4:	00008797          	auipc	a5,0x8
    800012e8:	d2a7b623          	sd	a0,-724(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800012ec:	6605                	lui	a2,0x1
    800012ee:	4581                	li	a1,0
    800012f0:	00000097          	auipc	ra,0x0
    800012f4:	ac2080e7          	jalr	-1342(ra) # 80000db2 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012f8:	4699                	li	a3,6
    800012fa:	6605                	lui	a2,0x1
    800012fc:	100005b7          	lui	a1,0x10000
    80001300:	10000537          	lui	a0,0x10000
    80001304:	00000097          	auipc	ra,0x0
    80001308:	f94080e7          	jalr	-108(ra) # 80001298 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000130c:	4699                	li	a3,6
    8000130e:	6605                	lui	a2,0x1
    80001310:	100015b7          	lui	a1,0x10001
    80001314:	10001537          	lui	a0,0x10001
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	f80080e7          	jalr	-128(ra) # 80001298 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001320:	4699                	li	a3,6
    80001322:	6641                	lui	a2,0x10
    80001324:	020005b7          	lui	a1,0x2000
    80001328:	02000537          	lui	a0,0x2000
    8000132c:	00000097          	auipc	ra,0x0
    80001330:	f6c080e7          	jalr	-148(ra) # 80001298 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001334:	4699                	li	a3,6
    80001336:	00400637          	lui	a2,0x400
    8000133a:	0c0005b7          	lui	a1,0xc000
    8000133e:	0c000537          	lui	a0,0xc000
    80001342:	00000097          	auipc	ra,0x0
    80001346:	f56080e7          	jalr	-170(ra) # 80001298 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000134a:	00007497          	auipc	s1,0x7
    8000134e:	cb648493          	addi	s1,s1,-842 # 80008000 <etext>
    80001352:	46a9                	li	a3,10
    80001354:	80007617          	auipc	a2,0x80007
    80001358:	cac60613          	addi	a2,a2,-852 # 8000 <_entry-0x7fff8000>
    8000135c:	4585                	li	a1,1
    8000135e:	05fe                	slli	a1,a1,0x1f
    80001360:	852e                	mv	a0,a1
    80001362:	00000097          	auipc	ra,0x0
    80001366:	f36080e7          	jalr	-202(ra) # 80001298 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000136a:	4699                	li	a3,6
    8000136c:	4645                	li	a2,17
    8000136e:	066e                	slli	a2,a2,0x1b
    80001370:	8e05                	sub	a2,a2,s1
    80001372:	85a6                	mv	a1,s1
    80001374:	8526                	mv	a0,s1
    80001376:	00000097          	auipc	ra,0x0
    8000137a:	f22080e7          	jalr	-222(ra) # 80001298 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000137e:	46a9                	li	a3,10
    80001380:	6605                	lui	a2,0x1
    80001382:	00006597          	auipc	a1,0x6
    80001386:	c7e58593          	addi	a1,a1,-898 # 80007000 <_trampoline>
    8000138a:	04000537          	lui	a0,0x4000
    8000138e:	157d                	addi	a0,a0,-1
    80001390:	0532                	slli	a0,a0,0xc
    80001392:	00000097          	auipc	ra,0x0
    80001396:	f06080e7          	jalr	-250(ra) # 80001298 <kvmmap>
}
    8000139a:	60e2                	ld	ra,24(sp)
    8000139c:	6442                	ld	s0,16(sp)
    8000139e:	64a2                	ld	s1,8(sp)
    800013a0:	6105                	addi	sp,sp,32
    800013a2:	8082                	ret

00000000800013a4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013a4:	715d                	addi	sp,sp,-80
    800013a6:	e486                	sd	ra,72(sp)
    800013a8:	e0a2                	sd	s0,64(sp)
    800013aa:	fc26                	sd	s1,56(sp)
    800013ac:	f84a                	sd	s2,48(sp)
    800013ae:	f44e                	sd	s3,40(sp)
    800013b0:	f052                	sd	s4,32(sp)
    800013b2:	ec56                	sd	s5,24(sp)
    800013b4:	e85a                	sd	s6,16(sp)
    800013b6:	e45e                	sd	s7,8(sp)
    800013b8:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013ba:	6785                	lui	a5,0x1
    800013bc:	17fd                	addi	a5,a5,-1
    800013be:	8fed                	and	a5,a5,a1
    800013c0:	e795                	bnez	a5,800013ec <uvmunmap+0x48>
    800013c2:	8a2a                	mv	s4,a0
    800013c4:	84ae                	mv	s1,a1
    800013c6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c8:	0632                	slli	a2,a2,0xc
    800013ca:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013ce:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013d0:	6b05                	lui	s6,0x1
    800013d2:	0735e863          	bltu	a1,s3,80001442 <uvmunmap+0x9e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013d6:	60a6                	ld	ra,72(sp)
    800013d8:	6406                	ld	s0,64(sp)
    800013da:	74e2                	ld	s1,56(sp)
    800013dc:	7942                	ld	s2,48(sp)
    800013de:	79a2                	ld	s3,40(sp)
    800013e0:	7a02                	ld	s4,32(sp)
    800013e2:	6ae2                	ld	s5,24(sp)
    800013e4:	6b42                	ld	s6,16(sp)
    800013e6:	6ba2                	ld	s7,8(sp)
    800013e8:	6161                	addi	sp,sp,80
    800013ea:	8082                	ret
    panic("uvmunmap: not aligned");
    800013ec:	00007517          	auipc	a0,0x7
    800013f0:	d0c50513          	addi	a0,a0,-756 # 800080f8 <digits+0xe0>
    800013f4:	fffff097          	auipc	ra,0xfffff
    800013f8:	1fe080e7          	jalr	510(ra) # 800005f2 <panic>
      panic("uvmunmap: walk");
    800013fc:	00007517          	auipc	a0,0x7
    80001400:	d1450513          	addi	a0,a0,-748 # 80008110 <digits+0xf8>
    80001404:	fffff097          	auipc	ra,0xfffff
    80001408:	1ee080e7          	jalr	494(ra) # 800005f2 <panic>
      panic("uvmunmap: not mapped");
    8000140c:	00007517          	auipc	a0,0x7
    80001410:	d1450513          	addi	a0,a0,-748 # 80008120 <digits+0x108>
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	1de080e7          	jalr	478(ra) # 800005f2 <panic>
      panic("uvmunmap: not a leaf");
    8000141c:	00007517          	auipc	a0,0x7
    80001420:	d1c50513          	addi	a0,a0,-740 # 80008138 <digits+0x120>
    80001424:	fffff097          	auipc	ra,0xfffff
    80001428:	1ce080e7          	jalr	462(ra) # 800005f2 <panic>
      uint64 pa = PTE2PA(*pte);
    8000142c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000142e:	0532                	slli	a0,a0,0xc
    80001430:	fffff097          	auipc	ra,0xfffff
    80001434:	696080e7          	jalr	1686(ra) # 80000ac6 <kfree>
    *pte = 0;
    80001438:	00093023          	sd	zero,0(s2)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000143c:	94da                	add	s1,s1,s6
    8000143e:	f934fce3          	bleu	s3,s1,800013d6 <uvmunmap+0x32>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001442:	4601                	li	a2,0
    80001444:	85a6                	mv	a1,s1
    80001446:	8552                	mv	a0,s4
    80001448:	00000097          	auipc	ra,0x0
    8000144c:	c7a080e7          	jalr	-902(ra) # 800010c2 <walk>
    80001450:	892a                	mv	s2,a0
    80001452:	d54d                	beqz	a0,800013fc <uvmunmap+0x58>
    if((*pte & PTE_V) == 0)
    80001454:	6108                	ld	a0,0(a0)
    80001456:	00157793          	andi	a5,a0,1
    8000145a:	dbcd                	beqz	a5,8000140c <uvmunmap+0x68>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000145c:	3ff57793          	andi	a5,a0,1023
    80001460:	fb778ee3          	beq	a5,s7,8000141c <uvmunmap+0x78>
    if(do_free){
    80001464:	fc0a8ae3          	beqz	s5,80001438 <uvmunmap+0x94>
    80001468:	b7d1                	j	8000142c <uvmunmap+0x88>

000000008000146a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000146a:	1101                	addi	sp,sp,-32
    8000146c:	ec06                	sd	ra,24(sp)
    8000146e:	e822                	sd	s0,16(sp)
    80001470:	e426                	sd	s1,8(sp)
    80001472:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001474:	fffff097          	auipc	ra,0xfffff
    80001478:	752080e7          	jalr	1874(ra) # 80000bc6 <kalloc>
    8000147c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000147e:	c519                	beqz	a0,8000148c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001480:	6605                	lui	a2,0x1
    80001482:	4581                	li	a1,0
    80001484:	00000097          	auipc	ra,0x0
    80001488:	92e080e7          	jalr	-1746(ra) # 80000db2 <memset>
  return pagetable;
}
    8000148c:	8526                	mv	a0,s1
    8000148e:	60e2                	ld	ra,24(sp)
    80001490:	6442                	ld	s0,16(sp)
    80001492:	64a2                	ld	s1,8(sp)
    80001494:	6105                	addi	sp,sp,32
    80001496:	8082                	ret

0000000080001498 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001498:	7179                	addi	sp,sp,-48
    8000149a:	f406                	sd	ra,40(sp)
    8000149c:	f022                	sd	s0,32(sp)
    8000149e:	ec26                	sd	s1,24(sp)
    800014a0:	e84a                	sd	s2,16(sp)
    800014a2:	e44e                	sd	s3,8(sp)
    800014a4:	e052                	sd	s4,0(sp)
    800014a6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014a8:	6785                	lui	a5,0x1
    800014aa:	04f67863          	bleu	a5,a2,800014fa <uvminit+0x62>
    800014ae:	8a2a                	mv	s4,a0
    800014b0:	89ae                	mv	s3,a1
    800014b2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014b4:	fffff097          	auipc	ra,0xfffff
    800014b8:	712080e7          	jalr	1810(ra) # 80000bc6 <kalloc>
    800014bc:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014be:	6605                	lui	a2,0x1
    800014c0:	4581                	li	a1,0
    800014c2:	00000097          	auipc	ra,0x0
    800014c6:	8f0080e7          	jalr	-1808(ra) # 80000db2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014ca:	4779                	li	a4,30
    800014cc:	86ca                	mv	a3,s2
    800014ce:	6605                	lui	a2,0x1
    800014d0:	4581                	li	a1,0
    800014d2:	8552                	mv	a0,s4
    800014d4:	00000097          	auipc	ra,0x0
    800014d8:	d38080e7          	jalr	-712(ra) # 8000120c <mappages>
  memmove(mem, src, sz);
    800014dc:	8626                	mv	a2,s1
    800014de:	85ce                	mv	a1,s3
    800014e0:	854a                	mv	a0,s2
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	93c080e7          	jalr	-1732(ra) # 80000e1e <memmove>
}
    800014ea:	70a2                	ld	ra,40(sp)
    800014ec:	7402                	ld	s0,32(sp)
    800014ee:	64e2                	ld	s1,24(sp)
    800014f0:	6942                	ld	s2,16(sp)
    800014f2:	69a2                	ld	s3,8(sp)
    800014f4:	6a02                	ld	s4,0(sp)
    800014f6:	6145                	addi	sp,sp,48
    800014f8:	8082                	ret
    panic("inituvm: more than a page");
    800014fa:	00007517          	auipc	a0,0x7
    800014fe:	c5650513          	addi	a0,a0,-938 # 80008150 <digits+0x138>
    80001502:	fffff097          	auipc	ra,0xfffff
    80001506:	0f0080e7          	jalr	240(ra) # 800005f2 <panic>

000000008000150a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000150a:	1101                	addi	sp,sp,-32
    8000150c:	ec06                	sd	ra,24(sp)
    8000150e:	e822                	sd	s0,16(sp)
    80001510:	e426                	sd	s1,8(sp)
    80001512:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001514:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001516:	00b67d63          	bleu	a1,a2,80001530 <uvmdealloc+0x26>
    8000151a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000151c:	6605                	lui	a2,0x1
    8000151e:	167d                	addi	a2,a2,-1
    80001520:	00c487b3          	add	a5,s1,a2
    80001524:	777d                	lui	a4,0xfffff
    80001526:	8ff9                	and	a5,a5,a4
    80001528:	962e                	add	a2,a2,a1
    8000152a:	8e79                	and	a2,a2,a4
    8000152c:	00c7e863          	bltu	a5,a2,8000153c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001530:	8526                	mv	a0,s1
    80001532:	60e2                	ld	ra,24(sp)
    80001534:	6442                	ld	s0,16(sp)
    80001536:	64a2                	ld	s1,8(sp)
    80001538:	6105                	addi	sp,sp,32
    8000153a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000153c:	8e1d                	sub	a2,a2,a5
    8000153e:	8231                	srli	a2,a2,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001540:	4685                	li	a3,1
    80001542:	2601                	sext.w	a2,a2
    80001544:	85be                	mv	a1,a5
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	e5e080e7          	jalr	-418(ra) # 800013a4 <uvmunmap>
    8000154e:	b7cd                	j	80001530 <uvmdealloc+0x26>

0000000080001550 <uvmalloc>:
  if(newsz < oldsz)
    80001550:	0ab66163          	bltu	a2,a1,800015f2 <uvmalloc+0xa2>
{
    80001554:	7139                	addi	sp,sp,-64
    80001556:	fc06                	sd	ra,56(sp)
    80001558:	f822                	sd	s0,48(sp)
    8000155a:	f426                	sd	s1,40(sp)
    8000155c:	f04a                	sd	s2,32(sp)
    8000155e:	ec4e                	sd	s3,24(sp)
    80001560:	e852                	sd	s4,16(sp)
    80001562:	e456                	sd	s5,8(sp)
    80001564:	0080                	addi	s0,sp,64
  oldsz = PGROUNDUP(oldsz);
    80001566:	6a05                	lui	s4,0x1
    80001568:	1a7d                	addi	s4,s4,-1
    8000156a:	95d2                	add	a1,a1,s4
    8000156c:	7a7d                	lui	s4,0xfffff
    8000156e:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001572:	08ca7263          	bleu	a2,s4,800015f6 <uvmalloc+0xa6>
    80001576:	89b2                	mv	s3,a2
    80001578:	8aaa                	mv	s5,a0
    8000157a:	8952                	mv	s2,s4
    mem = kalloc();
    8000157c:	fffff097          	auipc	ra,0xfffff
    80001580:	64a080e7          	jalr	1610(ra) # 80000bc6 <kalloc>
    80001584:	84aa                	mv	s1,a0
    if(mem == 0){
    80001586:	c51d                	beqz	a0,800015b4 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001588:	6605                	lui	a2,0x1
    8000158a:	4581                	li	a1,0
    8000158c:	00000097          	auipc	ra,0x0
    80001590:	826080e7          	jalr	-2010(ra) # 80000db2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001594:	4779                	li	a4,30
    80001596:	86a6                	mv	a3,s1
    80001598:	6605                	lui	a2,0x1
    8000159a:	85ca                	mv	a1,s2
    8000159c:	8556                	mv	a0,s5
    8000159e:	00000097          	auipc	ra,0x0
    800015a2:	c6e080e7          	jalr	-914(ra) # 8000120c <mappages>
    800015a6:	e905                	bnez	a0,800015d6 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a8:	6785                	lui	a5,0x1
    800015aa:	993e                	add	s2,s2,a5
    800015ac:	fd3968e3          	bltu	s2,s3,8000157c <uvmalloc+0x2c>
  return newsz;
    800015b0:	854e                	mv	a0,s3
    800015b2:	a809                	j	800015c4 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015b4:	8652                	mv	a2,s4
    800015b6:	85ca                	mv	a1,s2
    800015b8:	8556                	mv	a0,s5
    800015ba:	00000097          	auipc	ra,0x0
    800015be:	f50080e7          	jalr	-176(ra) # 8000150a <uvmdealloc>
      return 0;
    800015c2:	4501                	li	a0,0
}
    800015c4:	70e2                	ld	ra,56(sp)
    800015c6:	7442                	ld	s0,48(sp)
    800015c8:	74a2                	ld	s1,40(sp)
    800015ca:	7902                	ld	s2,32(sp)
    800015cc:	69e2                	ld	s3,24(sp)
    800015ce:	6a42                	ld	s4,16(sp)
    800015d0:	6aa2                	ld	s5,8(sp)
    800015d2:	6121                	addi	sp,sp,64
    800015d4:	8082                	ret
      kfree(mem);
    800015d6:	8526                	mv	a0,s1
    800015d8:	fffff097          	auipc	ra,0xfffff
    800015dc:	4ee080e7          	jalr	1262(ra) # 80000ac6 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015e0:	8652                	mv	a2,s4
    800015e2:	85ca                	mv	a1,s2
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	f24080e7          	jalr	-220(ra) # 8000150a <uvmdealloc>
      return 0;
    800015ee:	4501                	li	a0,0
    800015f0:	bfd1                	j	800015c4 <uvmalloc+0x74>
    return oldsz;
    800015f2:	852e                	mv	a0,a1
}
    800015f4:	8082                	ret
  return newsz;
    800015f6:	8532                	mv	a0,a2
    800015f8:	b7f1                	j	800015c4 <uvmalloc+0x74>

00000000800015fa <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015fa:	7179                	addi	sp,sp,-48
    800015fc:	f406                	sd	ra,40(sp)
    800015fe:	f022                	sd	s0,32(sp)
    80001600:	ec26                	sd	s1,24(sp)
    80001602:	e84a                	sd	s2,16(sp)
    80001604:	e44e                	sd	s3,8(sp)
    80001606:	e052                	sd	s4,0(sp)
    80001608:	1800                	addi	s0,sp,48
    8000160a:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000160c:	84aa                	mv	s1,a0
    8000160e:	6905                	lui	s2,0x1
    80001610:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001612:	4985                	li	s3,1
    80001614:	a821                	j	8000162c <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001616:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001618:	0532                	slli	a0,a0,0xc
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	fe0080e7          	jalr	-32(ra) # 800015fa <freewalk>
      pagetable[i] = 0;
    80001622:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001626:	04a1                	addi	s1,s1,8
    80001628:	03248163          	beq	s1,s2,8000164a <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000162c:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000162e:	00f57793          	andi	a5,a0,15
    80001632:	ff3782e3          	beq	a5,s3,80001616 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001636:	8905                	andi	a0,a0,1
    80001638:	d57d                	beqz	a0,80001626 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000163a:	00007517          	auipc	a0,0x7
    8000163e:	b3650513          	addi	a0,a0,-1226 # 80008170 <digits+0x158>
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	fb0080e7          	jalr	-80(ra) # 800005f2 <panic>
    }
  }
  kfree((void*)pagetable);
    8000164a:	8552                	mv	a0,s4
    8000164c:	fffff097          	auipc	ra,0xfffff
    80001650:	47a080e7          	jalr	1146(ra) # 80000ac6 <kfree>
}
    80001654:	70a2                	ld	ra,40(sp)
    80001656:	7402                	ld	s0,32(sp)
    80001658:	64e2                	ld	s1,24(sp)
    8000165a:	6942                	ld	s2,16(sp)
    8000165c:	69a2                	ld	s3,8(sp)
    8000165e:	6a02                	ld	s4,0(sp)
    80001660:	6145                	addi	sp,sp,48
    80001662:	8082                	ret

0000000080001664 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001664:	1101                	addi	sp,sp,-32
    80001666:	ec06                	sd	ra,24(sp)
    80001668:	e822                	sd	s0,16(sp)
    8000166a:	e426                	sd	s1,8(sp)
    8000166c:	1000                	addi	s0,sp,32
    8000166e:	84aa                	mv	s1,a0
  if(sz > 0)
    80001670:	e999                	bnez	a1,80001686 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001672:	8526                	mv	a0,s1
    80001674:	00000097          	auipc	ra,0x0
    80001678:	f86080e7          	jalr	-122(ra) # 800015fa <freewalk>
}
    8000167c:	60e2                	ld	ra,24(sp)
    8000167e:	6442                	ld	s0,16(sp)
    80001680:	64a2                	ld	s1,8(sp)
    80001682:	6105                	addi	sp,sp,32
    80001684:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001686:	6605                	lui	a2,0x1
    80001688:	167d                	addi	a2,a2,-1
    8000168a:	962e                	add	a2,a2,a1
    8000168c:	4685                	li	a3,1
    8000168e:	8231                	srli	a2,a2,0xc
    80001690:	4581                	li	a1,0
    80001692:	00000097          	auipc	ra,0x0
    80001696:	d12080e7          	jalr	-750(ra) # 800013a4 <uvmunmap>
    8000169a:	bfe1                	j	80001672 <uvmfree+0xe>

000000008000169c <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000169c:	c679                	beqz	a2,8000176a <uvmcopy+0xce>
{
    8000169e:	715d                	addi	sp,sp,-80
    800016a0:	e486                	sd	ra,72(sp)
    800016a2:	e0a2                	sd	s0,64(sp)
    800016a4:	fc26                	sd	s1,56(sp)
    800016a6:	f84a                	sd	s2,48(sp)
    800016a8:	f44e                	sd	s3,40(sp)
    800016aa:	f052                	sd	s4,32(sp)
    800016ac:	ec56                	sd	s5,24(sp)
    800016ae:	e85a                	sd	s6,16(sp)
    800016b0:	e45e                	sd	s7,8(sp)
    800016b2:	0880                	addi	s0,sp,80
    800016b4:	8ab2                	mv	s5,a2
    800016b6:	8b2e                	mv	s6,a1
    800016b8:	8baa                	mv	s7,a0
  for(i = 0; i < sz; i += PGSIZE){
    800016ba:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    800016bc:	4601                	li	a2,0
    800016be:	85ca                	mv	a1,s2
    800016c0:	855e                	mv	a0,s7
    800016c2:	00000097          	auipc	ra,0x0
    800016c6:	a00080e7          	jalr	-1536(ra) # 800010c2 <walk>
    800016ca:	c531                	beqz	a0,80001716 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800016cc:	6118                	ld	a4,0(a0)
    800016ce:	00177793          	andi	a5,a4,1
    800016d2:	cbb1                	beqz	a5,80001726 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800016d4:	00a75593          	srli	a1,a4,0xa
    800016d8:	00c59993          	slli	s3,a1,0xc
    flags = PTE_FLAGS(*pte);
    800016dc:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800016e0:	fffff097          	auipc	ra,0xfffff
    800016e4:	4e6080e7          	jalr	1254(ra) # 80000bc6 <kalloc>
    800016e8:	8a2a                	mv	s4,a0
    800016ea:	c939                	beqz	a0,80001740 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016ec:	6605                	lui	a2,0x1
    800016ee:	85ce                	mv	a1,s3
    800016f0:	fffff097          	auipc	ra,0xfffff
    800016f4:	72e080e7          	jalr	1838(ra) # 80000e1e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016f8:	8726                	mv	a4,s1
    800016fa:	86d2                	mv	a3,s4
    800016fc:	6605                	lui	a2,0x1
    800016fe:	85ca                	mv	a1,s2
    80001700:	855a                	mv	a0,s6
    80001702:	00000097          	auipc	ra,0x0
    80001706:	b0a080e7          	jalr	-1270(ra) # 8000120c <mappages>
    8000170a:	e515                	bnez	a0,80001736 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000170c:	6785                	lui	a5,0x1
    8000170e:	993e                	add	s2,s2,a5
    80001710:	fb5966e3          	bltu	s2,s5,800016bc <uvmcopy+0x20>
    80001714:	a081                	j	80001754 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001716:	00007517          	auipc	a0,0x7
    8000171a:	a6a50513          	addi	a0,a0,-1430 # 80008180 <digits+0x168>
    8000171e:	fffff097          	auipc	ra,0xfffff
    80001722:	ed4080e7          	jalr	-300(ra) # 800005f2 <panic>
      panic("uvmcopy: page not present");
    80001726:	00007517          	auipc	a0,0x7
    8000172a:	a7a50513          	addi	a0,a0,-1414 # 800081a0 <digits+0x188>
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	ec4080e7          	jalr	-316(ra) # 800005f2 <panic>
      kfree(mem);
    80001736:	8552                	mv	a0,s4
    80001738:	fffff097          	auipc	ra,0xfffff
    8000173c:	38e080e7          	jalr	910(ra) # 80000ac6 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001740:	4685                	li	a3,1
    80001742:	00c95613          	srli	a2,s2,0xc
    80001746:	4581                	li	a1,0
    80001748:	855a                	mv	a0,s6
    8000174a:	00000097          	auipc	ra,0x0
    8000174e:	c5a080e7          	jalr	-934(ra) # 800013a4 <uvmunmap>
  return -1;
    80001752:	557d                	li	a0,-1
}
    80001754:	60a6                	ld	ra,72(sp)
    80001756:	6406                	ld	s0,64(sp)
    80001758:	74e2                	ld	s1,56(sp)
    8000175a:	7942                	ld	s2,48(sp)
    8000175c:	79a2                	ld	s3,40(sp)
    8000175e:	7a02                	ld	s4,32(sp)
    80001760:	6ae2                	ld	s5,24(sp)
    80001762:	6b42                	ld	s6,16(sp)
    80001764:	6ba2                	ld	s7,8(sp)
    80001766:	6161                	addi	sp,sp,80
    80001768:	8082                	ret
  return 0;
    8000176a:	4501                	li	a0,0
}
    8000176c:	8082                	ret

000000008000176e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000176e:	1141                	addi	sp,sp,-16
    80001770:	e406                	sd	ra,8(sp)
    80001772:	e022                	sd	s0,0(sp)
    80001774:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001776:	4601                	li	a2,0
    80001778:	00000097          	auipc	ra,0x0
    8000177c:	94a080e7          	jalr	-1718(ra) # 800010c2 <walk>
  if(pte == 0)
    80001780:	c901                	beqz	a0,80001790 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001782:	611c                	ld	a5,0(a0)
    80001784:	9bbd                	andi	a5,a5,-17
    80001786:	e11c                	sd	a5,0(a0)
}
    80001788:	60a2                	ld	ra,8(sp)
    8000178a:	6402                	ld	s0,0(sp)
    8000178c:	0141                	addi	sp,sp,16
    8000178e:	8082                	ret
    panic("uvmclear");
    80001790:	00007517          	auipc	a0,0x7
    80001794:	a3050513          	addi	a0,a0,-1488 # 800081c0 <digits+0x1a8>
    80001798:	fffff097          	auipc	ra,0xfffff
    8000179c:	e5a080e7          	jalr	-422(ra) # 800005f2 <panic>

00000000800017a0 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017a0:	c6bd                	beqz	a3,8000180e <copyout+0x6e>
{
    800017a2:	715d                	addi	sp,sp,-80
    800017a4:	e486                	sd	ra,72(sp)
    800017a6:	e0a2                	sd	s0,64(sp)
    800017a8:	fc26                	sd	s1,56(sp)
    800017aa:	f84a                	sd	s2,48(sp)
    800017ac:	f44e                	sd	s3,40(sp)
    800017ae:	f052                	sd	s4,32(sp)
    800017b0:	ec56                	sd	s5,24(sp)
    800017b2:	e85a                	sd	s6,16(sp)
    800017b4:	e45e                	sd	s7,8(sp)
    800017b6:	e062                	sd	s8,0(sp)
    800017b8:	0880                	addi	s0,sp,80
    800017ba:	8baa                	mv	s7,a0
    800017bc:	8a2e                	mv	s4,a1
    800017be:	8ab2                	mv	s5,a2
    800017c0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800017c2:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800017c4:	6b05                	lui	s6,0x1
    800017c6:	a015                	j	800017ea <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800017c8:	9552                	add	a0,a0,s4
    800017ca:	0004861b          	sext.w	a2,s1
    800017ce:	85d6                	mv	a1,s5
    800017d0:	41250533          	sub	a0,a0,s2
    800017d4:	fffff097          	auipc	ra,0xfffff
    800017d8:	64a080e7          	jalr	1610(ra) # 80000e1e <memmove>

    len -= n;
    800017dc:	409989b3          	sub	s3,s3,s1
    src += n;
    800017e0:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    800017e2:	01690a33          	add	s4,s2,s6
  while(len > 0){
    800017e6:	02098263          	beqz	s3,8000180a <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017ea:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    800017ee:	85ca                	mv	a1,s2
    800017f0:	855e                	mv	a0,s7
    800017f2:	00000097          	auipc	ra,0x0
    800017f6:	976080e7          	jalr	-1674(ra) # 80001168 <walkaddr>
    if(pa0 == 0)
    800017fa:	cd01                	beqz	a0,80001812 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017fc:	414904b3          	sub	s1,s2,s4
    80001800:	94da                	add	s1,s1,s6
    if(n > len)
    80001802:	fc99f3e3          	bleu	s1,s3,800017c8 <copyout+0x28>
    80001806:	84ce                	mv	s1,s3
    80001808:	b7c1                	j	800017c8 <copyout+0x28>
  }
  return 0;
    8000180a:	4501                	li	a0,0
    8000180c:	a021                	j	80001814 <copyout+0x74>
    8000180e:	4501                	li	a0,0
}
    80001810:	8082                	ret
      return -1;
    80001812:	557d                	li	a0,-1
}
    80001814:	60a6                	ld	ra,72(sp)
    80001816:	6406                	ld	s0,64(sp)
    80001818:	74e2                	ld	s1,56(sp)
    8000181a:	7942                	ld	s2,48(sp)
    8000181c:	79a2                	ld	s3,40(sp)
    8000181e:	7a02                	ld	s4,32(sp)
    80001820:	6ae2                	ld	s5,24(sp)
    80001822:	6b42                	ld	s6,16(sp)
    80001824:	6ba2                	ld	s7,8(sp)
    80001826:	6c02                	ld	s8,0(sp)
    80001828:	6161                	addi	sp,sp,80
    8000182a:	8082                	ret

000000008000182c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000182c:	caa5                	beqz	a3,8000189c <copyin+0x70>
{
    8000182e:	715d                	addi	sp,sp,-80
    80001830:	e486                	sd	ra,72(sp)
    80001832:	e0a2                	sd	s0,64(sp)
    80001834:	fc26                	sd	s1,56(sp)
    80001836:	f84a                	sd	s2,48(sp)
    80001838:	f44e                	sd	s3,40(sp)
    8000183a:	f052                	sd	s4,32(sp)
    8000183c:	ec56                	sd	s5,24(sp)
    8000183e:	e85a                	sd	s6,16(sp)
    80001840:	e45e                	sd	s7,8(sp)
    80001842:	e062                	sd	s8,0(sp)
    80001844:	0880                	addi	s0,sp,80
    80001846:	8baa                	mv	s7,a0
    80001848:	8aae                	mv	s5,a1
    8000184a:	8a32                	mv	s4,a2
    8000184c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000184e:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001850:	6b05                	lui	s6,0x1
    80001852:	a01d                	j	80001878 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001854:	014505b3          	add	a1,a0,s4
    80001858:	0004861b          	sext.w	a2,s1
    8000185c:	412585b3          	sub	a1,a1,s2
    80001860:	8556                	mv	a0,s5
    80001862:	fffff097          	auipc	ra,0xfffff
    80001866:	5bc080e7          	jalr	1468(ra) # 80000e1e <memmove>

    len -= n;
    8000186a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000186e:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001870:	01690a33          	add	s4,s2,s6
  while(len > 0){
    80001874:	02098263          	beqz	s3,80001898 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001878:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    8000187c:	85ca                	mv	a1,s2
    8000187e:	855e                	mv	a0,s7
    80001880:	00000097          	auipc	ra,0x0
    80001884:	8e8080e7          	jalr	-1816(ra) # 80001168 <walkaddr>
    if(pa0 == 0)
    80001888:	cd01                	beqz	a0,800018a0 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000188a:	414904b3          	sub	s1,s2,s4
    8000188e:	94da                	add	s1,s1,s6
    if(n > len)
    80001890:	fc99f2e3          	bleu	s1,s3,80001854 <copyin+0x28>
    80001894:	84ce                	mv	s1,s3
    80001896:	bf7d                	j	80001854 <copyin+0x28>
  }
  return 0;
    80001898:	4501                	li	a0,0
    8000189a:	a021                	j	800018a2 <copyin+0x76>
    8000189c:	4501                	li	a0,0
}
    8000189e:	8082                	ret
      return -1;
    800018a0:	557d                	li	a0,-1
}
    800018a2:	60a6                	ld	ra,72(sp)
    800018a4:	6406                	ld	s0,64(sp)
    800018a6:	74e2                	ld	s1,56(sp)
    800018a8:	7942                	ld	s2,48(sp)
    800018aa:	79a2                	ld	s3,40(sp)
    800018ac:	7a02                	ld	s4,32(sp)
    800018ae:	6ae2                	ld	s5,24(sp)
    800018b0:	6b42                	ld	s6,16(sp)
    800018b2:	6ba2                	ld	s7,8(sp)
    800018b4:	6c02                	ld	s8,0(sp)
    800018b6:	6161                	addi	sp,sp,80
    800018b8:	8082                	ret

00000000800018ba <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800018ba:	ced5                	beqz	a3,80001976 <copyinstr+0xbc>
{
    800018bc:	715d                	addi	sp,sp,-80
    800018be:	e486                	sd	ra,72(sp)
    800018c0:	e0a2                	sd	s0,64(sp)
    800018c2:	fc26                	sd	s1,56(sp)
    800018c4:	f84a                	sd	s2,48(sp)
    800018c6:	f44e                	sd	s3,40(sp)
    800018c8:	f052                	sd	s4,32(sp)
    800018ca:	ec56                	sd	s5,24(sp)
    800018cc:	e85a                	sd	s6,16(sp)
    800018ce:	e45e                	sd	s7,8(sp)
    800018d0:	e062                	sd	s8,0(sp)
    800018d2:	0880                	addi	s0,sp,80
    800018d4:	8aaa                	mv	s5,a0
    800018d6:	84ae                	mv	s1,a1
    800018d8:	8c32                	mv	s8,a2
    800018da:	8bb6                	mv	s7,a3
    va0 = PGROUNDDOWN(srcva);
    800018dc:	7a7d                	lui	s4,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800018de:	6985                	lui	s3,0x1
    800018e0:	4b05                	li	s6,1
    800018e2:	a801                	j	800018f2 <copyinstr+0x38>
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
    800018e4:	87a6                	mv	a5,s1
    800018e6:	a085                	j	80001946 <copyinstr+0x8c>
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    800018e8:	84b2                	mv	s1,a2
    }

    srcva = va0 + PGSIZE;
    800018ea:	01390c33          	add	s8,s2,s3
  while(got_null == 0 && max > 0){
    800018ee:	080b8063          	beqz	s7,8000196e <copyinstr+0xb4>
    va0 = PGROUNDDOWN(srcva);
    800018f2:	014c7933          	and	s2,s8,s4
    pa0 = walkaddr(pagetable, va0);
    800018f6:	85ca                	mv	a1,s2
    800018f8:	8556                	mv	a0,s5
    800018fa:	00000097          	auipc	ra,0x0
    800018fe:	86e080e7          	jalr	-1938(ra) # 80001168 <walkaddr>
    if(pa0 == 0)
    80001902:	c925                	beqz	a0,80001972 <copyinstr+0xb8>
    n = PGSIZE - (srcva - va0);
    80001904:	41890633          	sub	a2,s2,s8
    80001908:	964e                	add	a2,a2,s3
    if(n > max)
    8000190a:	00cbf363          	bleu	a2,s7,80001910 <copyinstr+0x56>
    8000190e:	865e                	mv	a2,s7
    char *p = (char *) (pa0 + (srcva - va0));
    80001910:	9562                	add	a0,a0,s8
    80001912:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001916:	da71                	beqz	a2,800018ea <copyinstr+0x30>
      if(*p == '\0'){
    80001918:	00054703          	lbu	a4,0(a0)
    8000191c:	d761                	beqz	a4,800018e4 <copyinstr+0x2a>
    8000191e:	9626                	add	a2,a2,s1
    80001920:	87a6                	mv	a5,s1
    80001922:	1bfd                	addi	s7,s7,-1
    80001924:	009b86b3          	add	a3,s7,s1
    80001928:	409b04b3          	sub	s1,s6,s1
    8000192c:	94aa                	add	s1,s1,a0
        *dst = *p;
    8000192e:	00e78023          	sb	a4,0(a5) # 1000 <_entry-0x7ffff000>
      --max;
    80001932:	40f68bb3          	sub	s7,a3,a5
      p++;
    80001936:	00f48733          	add	a4,s1,a5
      dst++;
    8000193a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000193c:	faf606e3          	beq	a2,a5,800018e8 <copyinstr+0x2e>
      if(*p == '\0'){
    80001940:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd8000>
    80001944:	f76d                	bnez	a4,8000192e <copyinstr+0x74>
        *dst = '\0';
    80001946:	00078023          	sb	zero,0(a5)
    8000194a:	4785                	li	a5,1
  }
  if(got_null){
    8000194c:	0017b513          	seqz	a0,a5
    80001950:	40a0053b          	negw	a0,a0
    80001954:	2501                	sext.w	a0,a0
    return 0;
  } else {
    return -1;
  }
}
    80001956:	60a6                	ld	ra,72(sp)
    80001958:	6406                	ld	s0,64(sp)
    8000195a:	74e2                	ld	s1,56(sp)
    8000195c:	7942                	ld	s2,48(sp)
    8000195e:	79a2                	ld	s3,40(sp)
    80001960:	7a02                	ld	s4,32(sp)
    80001962:	6ae2                	ld	s5,24(sp)
    80001964:	6b42                	ld	s6,16(sp)
    80001966:	6ba2                	ld	s7,8(sp)
    80001968:	6c02                	ld	s8,0(sp)
    8000196a:	6161                	addi	sp,sp,80
    8000196c:	8082                	ret
    8000196e:	4781                	li	a5,0
    80001970:	bff1                	j	8000194c <copyinstr+0x92>
      return -1;
    80001972:	557d                	li	a0,-1
    80001974:	b7cd                	j	80001956 <copyinstr+0x9c>
  int got_null = 0;
    80001976:	4781                	li	a5,0
  if(got_null){
    80001978:	0017b513          	seqz	a0,a5
    8000197c:	40a0053b          	negw	a0,a0
    80001980:	2501                	sext.w	a0,a0
}
    80001982:	8082                	ret

0000000080001984 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001984:	1101                	addi	sp,sp,-32
    80001986:	ec06                	sd	ra,24(sp)
    80001988:	e822                	sd	s0,16(sp)
    8000198a:	e426                	sd	s1,8(sp)
    8000198c:	1000                	addi	s0,sp,32
    8000198e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001990:	fffff097          	auipc	ra,0xfffff
    80001994:	2ac080e7          	jalr	684(ra) # 80000c3c <holding>
    80001998:	c909                	beqz	a0,800019aa <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000199a:	749c                	ld	a5,40(s1)
    8000199c:	00978f63          	beq	a5,s1,800019ba <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800019a0:	60e2                	ld	ra,24(sp)
    800019a2:	6442                	ld	s0,16(sp)
    800019a4:	64a2                	ld	s1,8(sp)
    800019a6:	6105                	addi	sp,sp,32
    800019a8:	8082                	ret
    panic("wakeup1");
    800019aa:	00007517          	auipc	a0,0x7
    800019ae:	84e50513          	addi	a0,a0,-1970 # 800081f8 <states.1732+0x28>
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	c40080e7          	jalr	-960(ra) # 800005f2 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800019ba:	4c98                	lw	a4,24(s1)
    800019bc:	4785                	li	a5,1
    800019be:	fef711e3          	bne	a4,a5,800019a0 <wakeup1+0x1c>
    p->state = RUNNABLE;
    800019c2:	4789                	li	a5,2
    800019c4:	cc9c                	sw	a5,24(s1)
}
    800019c6:	bfe9                	j	800019a0 <wakeup1+0x1c>

00000000800019c8 <procinit>:
{
    800019c8:	715d                	addi	sp,sp,-80
    800019ca:	e486                	sd	ra,72(sp)
    800019cc:	e0a2                	sd	s0,64(sp)
    800019ce:	fc26                	sd	s1,56(sp)
    800019d0:	f84a                	sd	s2,48(sp)
    800019d2:	f44e                	sd	s3,40(sp)
    800019d4:	f052                	sd	s4,32(sp)
    800019d6:	ec56                	sd	s5,24(sp)
    800019d8:	e85a                	sd	s6,16(sp)
    800019da:	e45e                	sd	s7,8(sp)
    800019dc:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    800019de:	00007597          	auipc	a1,0x7
    800019e2:	82258593          	addi	a1,a1,-2014 # 80008200 <states.1732+0x30>
    800019e6:	00010517          	auipc	a0,0x10
    800019ea:	f6a50513          	addi	a0,a0,-150 # 80011950 <pid_lock>
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	238080e7          	jalr	568(ra) # 80000c26 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f6:	00010917          	auipc	s2,0x10
    800019fa:	37290913          	addi	s2,s2,882 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    800019fe:	00007b97          	auipc	s7,0x7
    80001a02:	80ab8b93          	addi	s7,s7,-2038 # 80008208 <states.1732+0x38>
      uint64 va = KSTACK((int) (p - proc));
    80001a06:	8b4a                	mv	s6,s2
    80001a08:	00006a97          	auipc	s5,0x6
    80001a0c:	5f8a8a93          	addi	s5,s5,1528 # 80008000 <etext>
    80001a10:	040009b7          	lui	s3,0x4000
    80001a14:	19fd                	addi	s3,s3,-1
    80001a16:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a18:	00016a17          	auipc	s4,0x16
    80001a1c:	550a0a13          	addi	s4,s4,1360 # 80017f68 <tickslock>
      initlock(&p->lock, "proc");
    80001a20:	85de                	mv	a1,s7
    80001a22:	854a                	mv	a0,s2
    80001a24:	fffff097          	auipc	ra,0xfffff
    80001a28:	202080e7          	jalr	514(ra) # 80000c26 <initlock>
      char *pa = kalloc();
    80001a2c:	fffff097          	auipc	ra,0xfffff
    80001a30:	19a080e7          	jalr	410(ra) # 80000bc6 <kalloc>
    80001a34:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a36:	c929                	beqz	a0,80001a88 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a38:	416904b3          	sub	s1,s2,s6
    80001a3c:	848d                	srai	s1,s1,0x3
    80001a3e:	000ab783          	ld	a5,0(s5)
    80001a42:	02f484b3          	mul	s1,s1,a5
    80001a46:	2485                	addiw	s1,s1,1
    80001a48:	00d4949b          	slliw	s1,s1,0xd
    80001a4c:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001a50:	4699                	li	a3,6
    80001a52:	6605                	lui	a2,0x1
    80001a54:	8526                	mv	a0,s1
    80001a56:	00000097          	auipc	ra,0x0
    80001a5a:	842080e7          	jalr	-1982(ra) # 80001298 <kvmmap>
      p->kstack = va;
    80001a5e:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a62:	18890913          	addi	s2,s2,392
    80001a66:	fb491de3          	bne	s2,s4,80001a20 <procinit+0x58>
  kvminithart();
    80001a6a:	fffff097          	auipc	ra,0xfffff
    80001a6e:	632080e7          	jalr	1586(ra) # 8000109c <kvminithart>
}
    80001a72:	60a6                	ld	ra,72(sp)
    80001a74:	6406                	ld	s0,64(sp)
    80001a76:	74e2                	ld	s1,56(sp)
    80001a78:	7942                	ld	s2,48(sp)
    80001a7a:	79a2                	ld	s3,40(sp)
    80001a7c:	7a02                	ld	s4,32(sp)
    80001a7e:	6ae2                	ld	s5,24(sp)
    80001a80:	6b42                	ld	s6,16(sp)
    80001a82:	6ba2                	ld	s7,8(sp)
    80001a84:	6161                	addi	sp,sp,80
    80001a86:	8082                	ret
        panic("kalloc");
    80001a88:	00006517          	auipc	a0,0x6
    80001a8c:	78850513          	addi	a0,a0,1928 # 80008210 <states.1732+0x40>
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	b62080e7          	jalr	-1182(ra) # 800005f2 <panic>

0000000080001a98 <cpuid>:
{
    80001a98:	1141                	addi	sp,sp,-16
    80001a9a:	e422                	sd	s0,8(sp)
    80001a9c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a9e:	8512                	mv	a0,tp
}
    80001aa0:	2501                	sext.w	a0,a0
    80001aa2:	6422                	ld	s0,8(sp)
    80001aa4:	0141                	addi	sp,sp,16
    80001aa6:	8082                	ret

0000000080001aa8 <mycpu>:
mycpu(void) {
    80001aa8:	1141                	addi	sp,sp,-16
    80001aaa:	e422                	sd	s0,8(sp)
    80001aac:	0800                	addi	s0,sp,16
    80001aae:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ab0:	2781                	sext.w	a5,a5
    80001ab2:	079e                	slli	a5,a5,0x7
}
    80001ab4:	00010517          	auipc	a0,0x10
    80001ab8:	eb450513          	addi	a0,a0,-332 # 80011968 <cpus>
    80001abc:	953e                	add	a0,a0,a5
    80001abe:	6422                	ld	s0,8(sp)
    80001ac0:	0141                	addi	sp,sp,16
    80001ac2:	8082                	ret

0000000080001ac4 <myproc>:
myproc(void) {
    80001ac4:	1101                	addi	sp,sp,-32
    80001ac6:	ec06                	sd	ra,24(sp)
    80001ac8:	e822                	sd	s0,16(sp)
    80001aca:	e426                	sd	s1,8(sp)
    80001acc:	1000                	addi	s0,sp,32
  push_off();
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	19c080e7          	jalr	412(ra) # 80000c6a <push_off>
    80001ad6:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001ad8:	2781                	sext.w	a5,a5
    80001ada:	079e                	slli	a5,a5,0x7
    80001adc:	00010717          	auipc	a4,0x10
    80001ae0:	e7470713          	addi	a4,a4,-396 # 80011950 <pid_lock>
    80001ae4:	97ba                	add	a5,a5,a4
    80001ae6:	6f84                	ld	s1,24(a5)
  pop_off();
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	222080e7          	jalr	546(ra) # 80000d0a <pop_off>
}
    80001af0:	8526                	mv	a0,s1
    80001af2:	60e2                	ld	ra,24(sp)
    80001af4:	6442                	ld	s0,16(sp)
    80001af6:	64a2                	ld	s1,8(sp)
    80001af8:	6105                	addi	sp,sp,32
    80001afa:	8082                	ret

0000000080001afc <forkret>:
{
    80001afc:	1141                	addi	sp,sp,-16
    80001afe:	e406                	sd	ra,8(sp)
    80001b00:	e022                	sd	s0,0(sp)
    80001b02:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b04:	00000097          	auipc	ra,0x0
    80001b08:	fc0080e7          	jalr	-64(ra) # 80001ac4 <myproc>
    80001b0c:	fffff097          	auipc	ra,0xfffff
    80001b10:	25e080e7          	jalr	606(ra) # 80000d6a <release>
  if (first) {
    80001b14:	00007797          	auipc	a5,0x7
    80001b18:	d1c78793          	addi	a5,a5,-740 # 80008830 <first.1692>
    80001b1c:	439c                	lw	a5,0(a5)
    80001b1e:	eb89                	bnez	a5,80001b30 <forkret+0x34>
  usertrapret();
    80001b20:	00001097          	auipc	ra,0x1
    80001b24:	ca6080e7          	jalr	-858(ra) # 800027c6 <usertrapret>
}
    80001b28:	60a2                	ld	ra,8(sp)
    80001b2a:	6402                	ld	s0,0(sp)
    80001b2c:	0141                	addi	sp,sp,16
    80001b2e:	8082                	ret
    first = 0;
    80001b30:	00007797          	auipc	a5,0x7
    80001b34:	d007a023          	sw	zero,-768(a5) # 80008830 <first.1692>
    fsinit(ROOTDEV);
    80001b38:	4505                	li	a0,1
    80001b3a:	00002097          	auipc	ra,0x2
    80001b3e:	b2e080e7          	jalr	-1234(ra) # 80003668 <fsinit>
    80001b42:	bff9                	j	80001b20 <forkret+0x24>

0000000080001b44 <allocpid>:
allocpid() {
    80001b44:	1101                	addi	sp,sp,-32
    80001b46:	ec06                	sd	ra,24(sp)
    80001b48:	e822                	sd	s0,16(sp)
    80001b4a:	e426                	sd	s1,8(sp)
    80001b4c:	e04a                	sd	s2,0(sp)
    80001b4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b50:	00010917          	auipc	s2,0x10
    80001b54:	e0090913          	addi	s2,s2,-512 # 80011950 <pid_lock>
    80001b58:	854a                	mv	a0,s2
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	15c080e7          	jalr	348(ra) # 80000cb6 <acquire>
  pid = nextpid;
    80001b62:	00007797          	auipc	a5,0x7
    80001b66:	cd278793          	addi	a5,a5,-814 # 80008834 <nextpid>
    80001b6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b6c:	0014871b          	addiw	a4,s1,1
    80001b70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b72:	854a                	mv	a0,s2
    80001b74:	fffff097          	auipc	ra,0xfffff
    80001b78:	1f6080e7          	jalr	502(ra) # 80000d6a <release>
}
    80001b7c:	8526                	mv	a0,s1
    80001b7e:	60e2                	ld	ra,24(sp)
    80001b80:	6442                	ld	s0,16(sp)
    80001b82:	64a2                	ld	s1,8(sp)
    80001b84:	6902                	ld	s2,0(sp)
    80001b86:	6105                	addi	sp,sp,32
    80001b88:	8082                	ret

0000000080001b8a <proc_pagetable>:
{
    80001b8a:	1101                	addi	sp,sp,-32
    80001b8c:	ec06                	sd	ra,24(sp)
    80001b8e:	e822                	sd	s0,16(sp)
    80001b90:	e426                	sd	s1,8(sp)
    80001b92:	e04a                	sd	s2,0(sp)
    80001b94:	1000                	addi	s0,sp,32
    80001b96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b98:	00000097          	auipc	ra,0x0
    80001b9c:	8d2080e7          	jalr	-1838(ra) # 8000146a <uvmcreate>
    80001ba0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ba2:	c121                	beqz	a0,80001be2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ba4:	4729                	li	a4,10
    80001ba6:	00005697          	auipc	a3,0x5
    80001baa:	45a68693          	addi	a3,a3,1114 # 80007000 <_trampoline>
    80001bae:	6605                	lui	a2,0x1
    80001bb0:	040005b7          	lui	a1,0x4000
    80001bb4:	15fd                	addi	a1,a1,-1
    80001bb6:	05b2                	slli	a1,a1,0xc
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	654080e7          	jalr	1620(ra) # 8000120c <mappages>
    80001bc0:	02054863          	bltz	a0,80001bf0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001bc4:	4719                	li	a4,6
    80001bc6:	05893683          	ld	a3,88(s2)
    80001bca:	6605                	lui	a2,0x1
    80001bcc:	020005b7          	lui	a1,0x2000
    80001bd0:	15fd                	addi	a1,a1,-1
    80001bd2:	05b6                	slli	a1,a1,0xd
    80001bd4:	8526                	mv	a0,s1
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	636080e7          	jalr	1590(ra) # 8000120c <mappages>
    80001bde:	02054163          	bltz	a0,80001c00 <proc_pagetable+0x76>
}
    80001be2:	8526                	mv	a0,s1
    80001be4:	60e2                	ld	ra,24(sp)
    80001be6:	6442                	ld	s0,16(sp)
    80001be8:	64a2                	ld	s1,8(sp)
    80001bea:	6902                	ld	s2,0(sp)
    80001bec:	6105                	addi	sp,sp,32
    80001bee:	8082                	ret
    uvmfree(pagetable, 0);
    80001bf0:	4581                	li	a1,0
    80001bf2:	8526                	mv	a0,s1
    80001bf4:	00000097          	auipc	ra,0x0
    80001bf8:	a70080e7          	jalr	-1424(ra) # 80001664 <uvmfree>
    return 0;
    80001bfc:	4481                	li	s1,0
    80001bfe:	b7d5                	j	80001be2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c00:	4681                	li	a3,0
    80001c02:	4605                	li	a2,1
    80001c04:	040005b7          	lui	a1,0x4000
    80001c08:	15fd                	addi	a1,a1,-1
    80001c0a:	05b2                	slli	a1,a1,0xc
    80001c0c:	8526                	mv	a0,s1
    80001c0e:	fffff097          	auipc	ra,0xfffff
    80001c12:	796080e7          	jalr	1942(ra) # 800013a4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c16:	4581                	li	a1,0
    80001c18:	8526                	mv	a0,s1
    80001c1a:	00000097          	auipc	ra,0x0
    80001c1e:	a4a080e7          	jalr	-1462(ra) # 80001664 <uvmfree>
    return 0;
    80001c22:	4481                	li	s1,0
    80001c24:	bf7d                	j	80001be2 <proc_pagetable+0x58>

0000000080001c26 <proc_freepagetable>:
{
    80001c26:	1101                	addi	sp,sp,-32
    80001c28:	ec06                	sd	ra,24(sp)
    80001c2a:	e822                	sd	s0,16(sp)
    80001c2c:	e426                	sd	s1,8(sp)
    80001c2e:	e04a                	sd	s2,0(sp)
    80001c30:	1000                	addi	s0,sp,32
    80001c32:	84aa                	mv	s1,a0
    80001c34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c36:	4681                	li	a3,0
    80001c38:	4605                	li	a2,1
    80001c3a:	040005b7          	lui	a1,0x4000
    80001c3e:	15fd                	addi	a1,a1,-1
    80001c40:	05b2                	slli	a1,a1,0xc
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	762080e7          	jalr	1890(ra) # 800013a4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c4a:	4681                	li	a3,0
    80001c4c:	4605                	li	a2,1
    80001c4e:	020005b7          	lui	a1,0x2000
    80001c52:	15fd                	addi	a1,a1,-1
    80001c54:	05b6                	slli	a1,a1,0xd
    80001c56:	8526                	mv	a0,s1
    80001c58:	fffff097          	auipc	ra,0xfffff
    80001c5c:	74c080e7          	jalr	1868(ra) # 800013a4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c60:	85ca                	mv	a1,s2
    80001c62:	8526                	mv	a0,s1
    80001c64:	00000097          	auipc	ra,0x0
    80001c68:	a00080e7          	jalr	-1536(ra) # 80001664 <uvmfree>
}
    80001c6c:	60e2                	ld	ra,24(sp)
    80001c6e:	6442                	ld	s0,16(sp)
    80001c70:	64a2                	ld	s1,8(sp)
    80001c72:	6902                	ld	s2,0(sp)
    80001c74:	6105                	addi	sp,sp,32
    80001c76:	8082                	ret

0000000080001c78 <freeproc>:
{
    80001c78:	1101                	addi	sp,sp,-32
    80001c7a:	ec06                	sd	ra,24(sp)
    80001c7c:	e822                	sd	s0,16(sp)
    80001c7e:	e426                	sd	s1,8(sp)
    80001c80:	1000                	addi	s0,sp,32
    80001c82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c84:	6d28                	ld	a0,88(a0)
    80001c86:	c509                	beqz	a0,80001c90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	e3e080e7          	jalr	-450(ra) # 80000ac6 <kfree>
  p->trapframe = 0;
    80001c90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c94:	68a8                	ld	a0,80(s1)
    80001c96:	c511                	beqz	a0,80001ca2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c98:	64ac                	ld	a1,72(s1)
    80001c9a:	00000097          	auipc	ra,0x0
    80001c9e:	f8c080e7          	jalr	-116(ra) # 80001c26 <proc_freepagetable>
  if(p->alarm_trapframe)
    80001ca2:	1804b503          	ld	a0,384(s1)
    80001ca6:	c509                	beqz	a0,80001cb0 <freeproc+0x38>
    kfree((void*)p->alarm_trapframe);
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	e1e080e7          	jalr	-482(ra) # 80000ac6 <kfree>
  p->alarm_trapframe = 0;
    80001cb0:	1804b023          	sd	zero,384(s1)
  p->pagetable = 0;
    80001cb4:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cb8:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cbc:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001cc0:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001cc4:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001cc8:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001ccc:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001cd0:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001cd4:	0004ac23          	sw	zero,24(s1)
}
    80001cd8:	60e2                	ld	ra,24(sp)
    80001cda:	6442                	ld	s0,16(sp)
    80001cdc:	64a2                	ld	s1,8(sp)
    80001cde:	6105                	addi	sp,sp,32
    80001ce0:	8082                	ret

0000000080001ce2 <allocproc>:
{
    80001ce2:	1101                	addi	sp,sp,-32
    80001ce4:	ec06                	sd	ra,24(sp)
    80001ce6:	e822                	sd	s0,16(sp)
    80001ce8:	e426                	sd	s1,8(sp)
    80001cea:	e04a                	sd	s2,0(sp)
    80001cec:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cee:	00010497          	auipc	s1,0x10
    80001cf2:	07a48493          	addi	s1,s1,122 # 80011d68 <proc>
    80001cf6:	00016917          	auipc	s2,0x16
    80001cfa:	27290913          	addi	s2,s2,626 # 80017f68 <tickslock>
    acquire(&p->lock);
    80001cfe:	8526                	mv	a0,s1
    80001d00:	fffff097          	auipc	ra,0xfffff
    80001d04:	fb6080e7          	jalr	-74(ra) # 80000cb6 <acquire>
    if(p->state == UNUSED) {
    80001d08:	4c9c                	lw	a5,24(s1)
    80001d0a:	cf81                	beqz	a5,80001d22 <allocproc+0x40>
      release(&p->lock);
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	05c080e7          	jalr	92(ra) # 80000d6a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d16:	18848493          	addi	s1,s1,392
    80001d1a:	ff2492e3          	bne	s1,s2,80001cfe <allocproc+0x1c>
  return 0;
    80001d1e:	4481                	li	s1,0
    80001d20:	a071                	j	80001dac <allocproc+0xca>
  p->pid = allocpid();
    80001d22:	00000097          	auipc	ra,0x0
    80001d26:	e22080e7          	jalr	-478(ra) # 80001b44 <allocpid>
    80001d2a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d2c:	fffff097          	auipc	ra,0xfffff
    80001d30:	e9a080e7          	jalr	-358(ra) # 80000bc6 <kalloc>
    80001d34:	892a                	mv	s2,a0
    80001d36:	eca8                	sd	a0,88(s1)
    80001d38:	c149                	beqz	a0,80001dba <allocproc+0xd8>
  if((p->alarm_trapframe = (struct trapframe *)kalloc()) == 0){
    80001d3a:	fffff097          	auipc	ra,0xfffff
    80001d3e:	e8c080e7          	jalr	-372(ra) # 80000bc6 <kalloc>
    80001d42:	892a                	mv	s2,a0
    80001d44:	18a4b023          	sd	a0,384(s1)
    80001d48:	c141                	beqz	a0,80001dc8 <allocproc+0xe6>
  p->intervals = 0;
    80001d4a:	1604a623          	sw	zero,364(s1)
  p->tickers = 0;
    80001d4e:	1604a823          	sw	zero,368(s1)
  p->handler = 0;
    80001d52:	1604bc23          	sd	zero,376(s1)
  p->pending = 0;
    80001d56:	1604a423          	sw	zero,360(s1)
  p->pagetable = proc_pagetable(p);
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	00000097          	auipc	ra,0x0
    80001d60:	e2e080e7          	jalr	-466(ra) # 80001b8a <proc_pagetable>
    80001d64:	892a                	mv	s2,a0
    80001d66:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d68:	c53d                	beqz	a0,80001dd6 <allocproc+0xf4>
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	e5c080e7          	jalr	-420(ra) # 80000bc6 <kalloc>
    80001d72:	892a                	mv	s2,a0
    80001d74:	eca8                	sd	a0,88(s1)
    80001d76:	cd25                	beqz	a0,80001dee <allocproc+0x10c>
  p->pagetable = proc_pagetable(p);
    80001d78:	8526                	mv	a0,s1
    80001d7a:	00000097          	auipc	ra,0x0
    80001d7e:	e10080e7          	jalr	-496(ra) # 80001b8a <proc_pagetable>
    80001d82:	892a                	mv	s2,a0
    80001d84:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d86:	c93d                	beqz	a0,80001dfc <allocproc+0x11a>
  memset(&p->context, 0, sizeof(p->context));
    80001d88:	07000613          	li	a2,112
    80001d8c:	4581                	li	a1,0
    80001d8e:	06048513          	addi	a0,s1,96
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	020080e7          	jalr	32(ra) # 80000db2 <memset>
  p->context.ra = (uint64)forkret;
    80001d9a:	00000797          	auipc	a5,0x0
    80001d9e:	d6278793          	addi	a5,a5,-670 # 80001afc <forkret>
    80001da2:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001da4:	60bc                	ld	a5,64(s1)
    80001da6:	6705                	lui	a4,0x1
    80001da8:	97ba                	add	a5,a5,a4
    80001daa:	f4bc                	sd	a5,104(s1)
}
    80001dac:	8526                	mv	a0,s1
    80001dae:	60e2                	ld	ra,24(sp)
    80001db0:	6442                	ld	s0,16(sp)
    80001db2:	64a2                	ld	s1,8(sp)
    80001db4:	6902                	ld	s2,0(sp)
    80001db6:	6105                	addi	sp,sp,32
    80001db8:	8082                	ret
    release(&p->lock);
    80001dba:	8526                	mv	a0,s1
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	fae080e7          	jalr	-82(ra) # 80000d6a <release>
    return 0;
    80001dc4:	84ca                	mv	s1,s2
    80001dc6:	b7dd                	j	80001dac <allocproc+0xca>
    release(&p->lock);
    80001dc8:	8526                	mv	a0,s1
    80001dca:	fffff097          	auipc	ra,0xfffff
    80001dce:	fa0080e7          	jalr	-96(ra) # 80000d6a <release>
    return 0;
    80001dd2:	84ca                	mv	s1,s2
    80001dd4:	bfe1                	j	80001dac <allocproc+0xca>
    freeproc(p);
    80001dd6:	8526                	mv	a0,s1
    80001dd8:	00000097          	auipc	ra,0x0
    80001ddc:	ea0080e7          	jalr	-352(ra) # 80001c78 <freeproc>
    release(&p->lock);
    80001de0:	8526                	mv	a0,s1
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	f88080e7          	jalr	-120(ra) # 80000d6a <release>
    return 0;
    80001dea:	84ca                	mv	s1,s2
    80001dec:	b7c1                	j	80001dac <allocproc+0xca>
    release(&p->lock);
    80001dee:	8526                	mv	a0,s1
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	f7a080e7          	jalr	-134(ra) # 80000d6a <release>
    return 0;
    80001df8:	84ca                	mv	s1,s2
    80001dfa:	bf4d                	j	80001dac <allocproc+0xca>
    freeproc(p);
    80001dfc:	8526                	mv	a0,s1
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	e7a080e7          	jalr	-390(ra) # 80001c78 <freeproc>
    release(&p->lock);
    80001e06:	8526                	mv	a0,s1
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	f62080e7          	jalr	-158(ra) # 80000d6a <release>
    return 0;
    80001e10:	84ca                	mv	s1,s2
    80001e12:	bf69                	j	80001dac <allocproc+0xca>

0000000080001e14 <userinit>:
{
    80001e14:	1101                	addi	sp,sp,-32
    80001e16:	ec06                	sd	ra,24(sp)
    80001e18:	e822                	sd	s0,16(sp)
    80001e1a:	e426                	sd	s1,8(sp)
    80001e1c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e1e:	00000097          	auipc	ra,0x0
    80001e22:	ec4080e7          	jalr	-316(ra) # 80001ce2 <allocproc>
    80001e26:	84aa                	mv	s1,a0
  initproc = p;
    80001e28:	00007797          	auipc	a5,0x7
    80001e2c:	1ea7b823          	sd	a0,496(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e30:	03400613          	li	a2,52
    80001e34:	00007597          	auipc	a1,0x7
    80001e38:	a0c58593          	addi	a1,a1,-1524 # 80008840 <initcode>
    80001e3c:	6928                	ld	a0,80(a0)
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	65a080e7          	jalr	1626(ra) # 80001498 <uvminit>
  p->sz = PGSIZE;
    80001e46:	6785                	lui	a5,0x1
    80001e48:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e4a:	6cb8                	ld	a4,88(s1)
    80001e4c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e50:	6cb8                	ld	a4,88(s1)
    80001e52:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e54:	4641                	li	a2,16
    80001e56:	00006597          	auipc	a1,0x6
    80001e5a:	3c258593          	addi	a1,a1,962 # 80008218 <states.1732+0x48>
    80001e5e:	15848513          	addi	a0,s1,344
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	0c8080e7          	jalr	200(ra) # 80000f2a <safestrcpy>
  p->cwd = namei("/");
    80001e6a:	00006517          	auipc	a0,0x6
    80001e6e:	3be50513          	addi	a0,a0,958 # 80008228 <states.1732+0x58>
    80001e72:	00002097          	auipc	ra,0x2
    80001e76:	22a080e7          	jalr	554(ra) # 8000409c <namei>
    80001e7a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e7e:	4789                	li	a5,2
    80001e80:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e82:	8526                	mv	a0,s1
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	ee6080e7          	jalr	-282(ra) # 80000d6a <release>
}
    80001e8c:	60e2                	ld	ra,24(sp)
    80001e8e:	6442                	ld	s0,16(sp)
    80001e90:	64a2                	ld	s1,8(sp)
    80001e92:	6105                	addi	sp,sp,32
    80001e94:	8082                	ret

0000000080001e96 <growproc>:
{
    80001e96:	1101                	addi	sp,sp,-32
    80001e98:	ec06                	sd	ra,24(sp)
    80001e9a:	e822                	sd	s0,16(sp)
    80001e9c:	e426                	sd	s1,8(sp)
    80001e9e:	e04a                	sd	s2,0(sp)
    80001ea0:	1000                	addi	s0,sp,32
    80001ea2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ea4:	00000097          	auipc	ra,0x0
    80001ea8:	c20080e7          	jalr	-992(ra) # 80001ac4 <myproc>
    80001eac:	892a                	mv	s2,a0
  sz = p->sz;
    80001eae:	652c                	ld	a1,72(a0)
    80001eb0:	0005851b          	sext.w	a0,a1
  if(n > 0){
    80001eb4:	00904f63          	bgtz	s1,80001ed2 <growproc+0x3c>
  } else if(n < 0){
    80001eb8:	0204cd63          	bltz	s1,80001ef2 <growproc+0x5c>
  p->sz = sz;
    80001ebc:	1502                	slli	a0,a0,0x20
    80001ebe:	9101                	srli	a0,a0,0x20
    80001ec0:	04a93423          	sd	a0,72(s2)
  return 0;
    80001ec4:	4501                	li	a0,0
}
    80001ec6:	60e2                	ld	ra,24(sp)
    80001ec8:	6442                	ld	s0,16(sp)
    80001eca:	64a2                	ld	s1,8(sp)
    80001ecc:	6902                	ld	s2,0(sp)
    80001ece:	6105                	addi	sp,sp,32
    80001ed0:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001ed2:	00a4863b          	addw	a2,s1,a0
    80001ed6:	1602                	slli	a2,a2,0x20
    80001ed8:	9201                	srli	a2,a2,0x20
    80001eda:	1582                	slli	a1,a1,0x20
    80001edc:	9181                	srli	a1,a1,0x20
    80001ede:	05093503          	ld	a0,80(s2)
    80001ee2:	fffff097          	auipc	ra,0xfffff
    80001ee6:	66e080e7          	jalr	1646(ra) # 80001550 <uvmalloc>
    80001eea:	2501                	sext.w	a0,a0
    80001eec:	f961                	bnez	a0,80001ebc <growproc+0x26>
      return -1;
    80001eee:	557d                	li	a0,-1
    80001ef0:	bfd9                	j	80001ec6 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ef2:	00a4863b          	addw	a2,s1,a0
    80001ef6:	1602                	slli	a2,a2,0x20
    80001ef8:	9201                	srli	a2,a2,0x20
    80001efa:	1582                	slli	a1,a1,0x20
    80001efc:	9181                	srli	a1,a1,0x20
    80001efe:	05093503          	ld	a0,80(s2)
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	608080e7          	jalr	1544(ra) # 8000150a <uvmdealloc>
    80001f0a:	2501                	sext.w	a0,a0
    80001f0c:	bf45                	j	80001ebc <growproc+0x26>

0000000080001f0e <fork>:
{
    80001f0e:	7179                	addi	sp,sp,-48
    80001f10:	f406                	sd	ra,40(sp)
    80001f12:	f022                	sd	s0,32(sp)
    80001f14:	ec26                	sd	s1,24(sp)
    80001f16:	e84a                	sd	s2,16(sp)
    80001f18:	e44e                	sd	s3,8(sp)
    80001f1a:	e052                	sd	s4,0(sp)
    80001f1c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f1e:	00000097          	auipc	ra,0x0
    80001f22:	ba6080e7          	jalr	-1114(ra) # 80001ac4 <myproc>
    80001f26:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f28:	00000097          	auipc	ra,0x0
    80001f2c:	dba080e7          	jalr	-582(ra) # 80001ce2 <allocproc>
    80001f30:	c175                	beqz	a0,80002014 <fork+0x106>
    80001f32:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f34:	04893603          	ld	a2,72(s2)
    80001f38:	692c                	ld	a1,80(a0)
    80001f3a:	05093503          	ld	a0,80(s2)
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	75e080e7          	jalr	1886(ra) # 8000169c <uvmcopy>
    80001f46:	04054863          	bltz	a0,80001f96 <fork+0x88>
  np->sz = p->sz;
    80001f4a:	04893783          	ld	a5,72(s2)
    80001f4e:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f52:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f56:	05893683          	ld	a3,88(s2)
    80001f5a:	87b6                	mv	a5,a3
    80001f5c:	0589b703          	ld	a4,88(s3)
    80001f60:	12068693          	addi	a3,a3,288
    80001f64:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f68:	6788                	ld	a0,8(a5)
    80001f6a:	6b8c                	ld	a1,16(a5)
    80001f6c:	6f90                	ld	a2,24(a5)
    80001f6e:	01073023          	sd	a6,0(a4)
    80001f72:	e708                	sd	a0,8(a4)
    80001f74:	eb0c                	sd	a1,16(a4)
    80001f76:	ef10                	sd	a2,24(a4)
    80001f78:	02078793          	addi	a5,a5,32
    80001f7c:	02070713          	addi	a4,a4,32
    80001f80:	fed792e3          	bne	a5,a3,80001f64 <fork+0x56>
  np->trapframe->a0 = 0;
    80001f84:	0589b783          	ld	a5,88(s3)
    80001f88:	0607b823          	sd	zero,112(a5)
    80001f8c:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f90:	15000a13          	li	s4,336
    80001f94:	a03d                	j	80001fc2 <fork+0xb4>
    freeproc(np);
    80001f96:	854e                	mv	a0,s3
    80001f98:	00000097          	auipc	ra,0x0
    80001f9c:	ce0080e7          	jalr	-800(ra) # 80001c78 <freeproc>
    release(&np->lock);
    80001fa0:	854e                	mv	a0,s3
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	dc8080e7          	jalr	-568(ra) # 80000d6a <release>
    return -1;
    80001faa:	54fd                	li	s1,-1
    80001fac:	a899                	j	80002002 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fae:	00002097          	auipc	ra,0x2
    80001fb2:	7ac080e7          	jalr	1964(ra) # 8000475a <filedup>
    80001fb6:	009987b3          	add	a5,s3,s1
    80001fba:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001fbc:	04a1                	addi	s1,s1,8
    80001fbe:	01448763          	beq	s1,s4,80001fcc <fork+0xbe>
    if(p->ofile[i])
    80001fc2:	009907b3          	add	a5,s2,s1
    80001fc6:	6388                	ld	a0,0(a5)
    80001fc8:	f17d                	bnez	a0,80001fae <fork+0xa0>
    80001fca:	bfcd                	j	80001fbc <fork+0xae>
  np->cwd = idup(p->cwd);
    80001fcc:	15093503          	ld	a0,336(s2)
    80001fd0:	00002097          	auipc	ra,0x2
    80001fd4:	8d4080e7          	jalr	-1836(ra) # 800038a4 <idup>
    80001fd8:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fdc:	4641                	li	a2,16
    80001fde:	15890593          	addi	a1,s2,344
    80001fe2:	15898513          	addi	a0,s3,344
    80001fe6:	fffff097          	auipc	ra,0xfffff
    80001fea:	f44080e7          	jalr	-188(ra) # 80000f2a <safestrcpy>
  pid = np->pid;
    80001fee:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001ff2:	4789                	li	a5,2
    80001ff4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001ff8:	854e                	mv	a0,s3
    80001ffa:	fffff097          	auipc	ra,0xfffff
    80001ffe:	d70080e7          	jalr	-656(ra) # 80000d6a <release>
}
    80002002:	8526                	mv	a0,s1
    80002004:	70a2                	ld	ra,40(sp)
    80002006:	7402                	ld	s0,32(sp)
    80002008:	64e2                	ld	s1,24(sp)
    8000200a:	6942                	ld	s2,16(sp)
    8000200c:	69a2                	ld	s3,8(sp)
    8000200e:	6a02                	ld	s4,0(sp)
    80002010:	6145                	addi	sp,sp,48
    80002012:	8082                	ret
    return -1;
    80002014:	54fd                	li	s1,-1
    80002016:	b7f5                	j	80002002 <fork+0xf4>

0000000080002018 <reparent>:
{
    80002018:	7179                	addi	sp,sp,-48
    8000201a:	f406                	sd	ra,40(sp)
    8000201c:	f022                	sd	s0,32(sp)
    8000201e:	ec26                	sd	s1,24(sp)
    80002020:	e84a                	sd	s2,16(sp)
    80002022:	e44e                	sd	s3,8(sp)
    80002024:	e052                	sd	s4,0(sp)
    80002026:	1800                	addi	s0,sp,48
    80002028:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000202a:	00010497          	auipc	s1,0x10
    8000202e:	d3e48493          	addi	s1,s1,-706 # 80011d68 <proc>
      pp->parent = initproc;
    80002032:	00007a17          	auipc	s4,0x7
    80002036:	fe6a0a13          	addi	s4,s4,-26 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000203a:	00016917          	auipc	s2,0x16
    8000203e:	f2e90913          	addi	s2,s2,-210 # 80017f68 <tickslock>
    80002042:	a029                	j	8000204c <reparent+0x34>
    80002044:	18848493          	addi	s1,s1,392
    80002048:	03248363          	beq	s1,s2,8000206e <reparent+0x56>
    if(pp->parent == p){
    8000204c:	709c                	ld	a5,32(s1)
    8000204e:	ff379be3          	bne	a5,s3,80002044 <reparent+0x2c>
      acquire(&pp->lock);
    80002052:	8526                	mv	a0,s1
    80002054:	fffff097          	auipc	ra,0xfffff
    80002058:	c62080e7          	jalr	-926(ra) # 80000cb6 <acquire>
      pp->parent = initproc;
    8000205c:	000a3783          	ld	a5,0(s4)
    80002060:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002062:	8526                	mv	a0,s1
    80002064:	fffff097          	auipc	ra,0xfffff
    80002068:	d06080e7          	jalr	-762(ra) # 80000d6a <release>
    8000206c:	bfe1                	j	80002044 <reparent+0x2c>
}
    8000206e:	70a2                	ld	ra,40(sp)
    80002070:	7402                	ld	s0,32(sp)
    80002072:	64e2                	ld	s1,24(sp)
    80002074:	6942                	ld	s2,16(sp)
    80002076:	69a2                	ld	s3,8(sp)
    80002078:	6a02                	ld	s4,0(sp)
    8000207a:	6145                	addi	sp,sp,48
    8000207c:	8082                	ret

000000008000207e <scheduler>:
{
    8000207e:	715d                	addi	sp,sp,-80
    80002080:	e486                	sd	ra,72(sp)
    80002082:	e0a2                	sd	s0,64(sp)
    80002084:	fc26                	sd	s1,56(sp)
    80002086:	f84a                	sd	s2,48(sp)
    80002088:	f44e                	sd	s3,40(sp)
    8000208a:	f052                	sd	s4,32(sp)
    8000208c:	ec56                	sd	s5,24(sp)
    8000208e:	e85a                	sd	s6,16(sp)
    80002090:	e45e                	sd	s7,8(sp)
    80002092:	e062                	sd	s8,0(sp)
    80002094:	0880                	addi	s0,sp,80
    80002096:	8792                	mv	a5,tp
  int id = r_tp();
    80002098:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000209a:	00779b13          	slli	s6,a5,0x7
    8000209e:	00010717          	auipc	a4,0x10
    800020a2:	8b270713          	addi	a4,a4,-1870 # 80011950 <pid_lock>
    800020a6:	975a                	add	a4,a4,s6
    800020a8:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800020ac:	00010717          	auipc	a4,0x10
    800020b0:	8c470713          	addi	a4,a4,-1852 # 80011970 <cpus+0x8>
    800020b4:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    800020b6:	4c0d                	li	s8,3
        c->proc = p;
    800020b8:	079e                	slli	a5,a5,0x7
    800020ba:	00010a17          	auipc	s4,0x10
    800020be:	896a0a13          	addi	s4,s4,-1898 # 80011950 <pid_lock>
    800020c2:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800020c4:	00016997          	auipc	s3,0x16
    800020c8:	ea498993          	addi	s3,s3,-348 # 80017f68 <tickslock>
        found = 1;
    800020cc:	4b85                	li	s7,1
    800020ce:	a899                	j	80002124 <scheduler+0xa6>
        p->state = RUNNING;
    800020d0:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    800020d4:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    800020d8:	06048593          	addi	a1,s1,96
    800020dc:	855a                	mv	a0,s6
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	63e080e7          	jalr	1598(ra) # 8000271c <swtch>
        c->proc = 0;
    800020e6:	000a3c23          	sd	zero,24(s4)
        found = 1;
    800020ea:	8ade                	mv	s5,s7
      release(&p->lock);
    800020ec:	8526                	mv	a0,s1
    800020ee:	fffff097          	auipc	ra,0xfffff
    800020f2:	c7c080e7          	jalr	-900(ra) # 80000d6a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020f6:	18848493          	addi	s1,s1,392
    800020fa:	01348b63          	beq	s1,s3,80002110 <scheduler+0x92>
      acquire(&p->lock);
    800020fe:	8526                	mv	a0,s1
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	bb6080e7          	jalr	-1098(ra) # 80000cb6 <acquire>
      if(p->state == RUNNABLE) {
    80002108:	4c9c                	lw	a5,24(s1)
    8000210a:	ff2791e3          	bne	a5,s2,800020ec <scheduler+0x6e>
    8000210e:	b7c9                	j	800020d0 <scheduler+0x52>
    if(found == 0) {
    80002110:	000a9a63          	bnez	s5,80002124 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002114:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002118:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000211c:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002120:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002124:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002128:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000212c:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002130:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002132:	00010497          	auipc	s1,0x10
    80002136:	c3648493          	addi	s1,s1,-970 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000213a:	4909                	li	s2,2
    8000213c:	b7c9                	j	800020fe <scheduler+0x80>

000000008000213e <sched>:
{
    8000213e:	7179                	addi	sp,sp,-48
    80002140:	f406                	sd	ra,40(sp)
    80002142:	f022                	sd	s0,32(sp)
    80002144:	ec26                	sd	s1,24(sp)
    80002146:	e84a                	sd	s2,16(sp)
    80002148:	e44e                	sd	s3,8(sp)
    8000214a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000214c:	00000097          	auipc	ra,0x0
    80002150:	978080e7          	jalr	-1672(ra) # 80001ac4 <myproc>
    80002154:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	ae6080e7          	jalr	-1306(ra) # 80000c3c <holding>
    8000215e:	cd25                	beqz	a0,800021d6 <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002160:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002162:	2781                	sext.w	a5,a5
    80002164:	079e                	slli	a5,a5,0x7
    80002166:	0000f717          	auipc	a4,0xf
    8000216a:	7ea70713          	addi	a4,a4,2026 # 80011950 <pid_lock>
    8000216e:	97ba                	add	a5,a5,a4
    80002170:	0907a703          	lw	a4,144(a5)
    80002174:	4785                	li	a5,1
    80002176:	06f71863          	bne	a4,a5,800021e6 <sched+0xa8>
  if(p->state == RUNNING)
    8000217a:	01892703          	lw	a4,24(s2)
    8000217e:	478d                	li	a5,3
    80002180:	06f70b63          	beq	a4,a5,800021f6 <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002184:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002188:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000218a:	efb5                	bnez	a5,80002206 <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000218c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000218e:	0000f497          	auipc	s1,0xf
    80002192:	7c248493          	addi	s1,s1,1986 # 80011950 <pid_lock>
    80002196:	2781                	sext.w	a5,a5
    80002198:	079e                	slli	a5,a5,0x7
    8000219a:	97a6                	add	a5,a5,s1
    8000219c:	0947a983          	lw	s3,148(a5)
    800021a0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021a2:	2781                	sext.w	a5,a5
    800021a4:	079e                	slli	a5,a5,0x7
    800021a6:	0000f597          	auipc	a1,0xf
    800021aa:	7ca58593          	addi	a1,a1,1994 # 80011970 <cpus+0x8>
    800021ae:	95be                	add	a1,a1,a5
    800021b0:	06090513          	addi	a0,s2,96
    800021b4:	00000097          	auipc	ra,0x0
    800021b8:	568080e7          	jalr	1384(ra) # 8000271c <swtch>
    800021bc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021be:	2781                	sext.w	a5,a5
    800021c0:	079e                	slli	a5,a5,0x7
    800021c2:	97a6                	add	a5,a5,s1
    800021c4:	0937aa23          	sw	s3,148(a5)
}
    800021c8:	70a2                	ld	ra,40(sp)
    800021ca:	7402                	ld	s0,32(sp)
    800021cc:	64e2                	ld	s1,24(sp)
    800021ce:	6942                	ld	s2,16(sp)
    800021d0:	69a2                	ld	s3,8(sp)
    800021d2:	6145                	addi	sp,sp,48
    800021d4:	8082                	ret
    panic("sched p->lock");
    800021d6:	00006517          	auipc	a0,0x6
    800021da:	05a50513          	addi	a0,a0,90 # 80008230 <states.1732+0x60>
    800021de:	ffffe097          	auipc	ra,0xffffe
    800021e2:	414080e7          	jalr	1044(ra) # 800005f2 <panic>
    panic("sched locks");
    800021e6:	00006517          	auipc	a0,0x6
    800021ea:	05a50513          	addi	a0,a0,90 # 80008240 <states.1732+0x70>
    800021ee:	ffffe097          	auipc	ra,0xffffe
    800021f2:	404080e7          	jalr	1028(ra) # 800005f2 <panic>
    panic("sched running");
    800021f6:	00006517          	auipc	a0,0x6
    800021fa:	05a50513          	addi	a0,a0,90 # 80008250 <states.1732+0x80>
    800021fe:	ffffe097          	auipc	ra,0xffffe
    80002202:	3f4080e7          	jalr	1012(ra) # 800005f2 <panic>
    panic("sched interruptible");
    80002206:	00006517          	auipc	a0,0x6
    8000220a:	05a50513          	addi	a0,a0,90 # 80008260 <states.1732+0x90>
    8000220e:	ffffe097          	auipc	ra,0xffffe
    80002212:	3e4080e7          	jalr	996(ra) # 800005f2 <panic>

0000000080002216 <exit>:
{
    80002216:	7179                	addi	sp,sp,-48
    80002218:	f406                	sd	ra,40(sp)
    8000221a:	f022                	sd	s0,32(sp)
    8000221c:	ec26                	sd	s1,24(sp)
    8000221e:	e84a                	sd	s2,16(sp)
    80002220:	e44e                	sd	s3,8(sp)
    80002222:	e052                	sd	s4,0(sp)
    80002224:	1800                	addi	s0,sp,48
    80002226:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002228:	00000097          	auipc	ra,0x0
    8000222c:	89c080e7          	jalr	-1892(ra) # 80001ac4 <myproc>
    80002230:	89aa                	mv	s3,a0
  if(p == initproc)
    80002232:	00007797          	auipc	a5,0x7
    80002236:	de678793          	addi	a5,a5,-538 # 80009018 <initproc>
    8000223a:	639c                	ld	a5,0(a5)
    8000223c:	0d050493          	addi	s1,a0,208
    80002240:	15050913          	addi	s2,a0,336
    80002244:	02a79363          	bne	a5,a0,8000226a <exit+0x54>
    panic("init exiting");
    80002248:	00006517          	auipc	a0,0x6
    8000224c:	03050513          	addi	a0,a0,48 # 80008278 <states.1732+0xa8>
    80002250:	ffffe097          	auipc	ra,0xffffe
    80002254:	3a2080e7          	jalr	930(ra) # 800005f2 <panic>
      fileclose(f);
    80002258:	00002097          	auipc	ra,0x2
    8000225c:	554080e7          	jalr	1364(ra) # 800047ac <fileclose>
      p->ofile[fd] = 0;
    80002260:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002264:	04a1                	addi	s1,s1,8
    80002266:	01248563          	beq	s1,s2,80002270 <exit+0x5a>
    if(p->ofile[fd]){
    8000226a:	6088                	ld	a0,0(s1)
    8000226c:	f575                	bnez	a0,80002258 <exit+0x42>
    8000226e:	bfdd                	j	80002264 <exit+0x4e>
  begin_op();
    80002270:	00002097          	auipc	ra,0x2
    80002274:	03a080e7          	jalr	58(ra) # 800042aa <begin_op>
  iput(p->cwd);
    80002278:	1509b503          	ld	a0,336(s3)
    8000227c:	00002097          	auipc	ra,0x2
    80002280:	822080e7          	jalr	-2014(ra) # 80003a9e <iput>
  end_op();
    80002284:	00002097          	auipc	ra,0x2
    80002288:	0a6080e7          	jalr	166(ra) # 8000432a <end_op>
  p->cwd = 0;
    8000228c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002290:	00007497          	auipc	s1,0x7
    80002294:	d8848493          	addi	s1,s1,-632 # 80009018 <initproc>
    80002298:	6088                	ld	a0,0(s1)
    8000229a:	fffff097          	auipc	ra,0xfffff
    8000229e:	a1c080e7          	jalr	-1508(ra) # 80000cb6 <acquire>
  wakeup1(initproc);
    800022a2:	6088                	ld	a0,0(s1)
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	6e0080e7          	jalr	1760(ra) # 80001984 <wakeup1>
  release(&initproc->lock);
    800022ac:	6088                	ld	a0,0(s1)
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	abc080e7          	jalr	-1348(ra) # 80000d6a <release>
  acquire(&p->lock);
    800022b6:	854e                	mv	a0,s3
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	9fe080e7          	jalr	-1538(ra) # 80000cb6 <acquire>
  struct proc *original_parent = p->parent;
    800022c0:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800022c4:	854e                	mv	a0,s3
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	aa4080e7          	jalr	-1372(ra) # 80000d6a <release>
  acquire(&original_parent->lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	9e6080e7          	jalr	-1562(ra) # 80000cb6 <acquire>
  acquire(&p->lock);
    800022d8:	854e                	mv	a0,s3
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	9dc080e7          	jalr	-1572(ra) # 80000cb6 <acquire>
  reparent(p);
    800022e2:	854e                	mv	a0,s3
    800022e4:	00000097          	auipc	ra,0x0
    800022e8:	d34080e7          	jalr	-716(ra) # 80002018 <reparent>
  wakeup1(original_parent);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	696080e7          	jalr	1686(ra) # 80001984 <wakeup1>
  p->xstate = status;
    800022f6:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800022fa:	4791                	li	a5,4
    800022fc:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002300:	8526                	mv	a0,s1
    80002302:	fffff097          	auipc	ra,0xfffff
    80002306:	a68080e7          	jalr	-1432(ra) # 80000d6a <release>
  sched();
    8000230a:	00000097          	auipc	ra,0x0
    8000230e:	e34080e7          	jalr	-460(ra) # 8000213e <sched>
  panic("zombie exit");
    80002312:	00006517          	auipc	a0,0x6
    80002316:	f7650513          	addi	a0,a0,-138 # 80008288 <states.1732+0xb8>
    8000231a:	ffffe097          	auipc	ra,0xffffe
    8000231e:	2d8080e7          	jalr	728(ra) # 800005f2 <panic>

0000000080002322 <yield>:
{
    80002322:	1101                	addi	sp,sp,-32
    80002324:	ec06                	sd	ra,24(sp)
    80002326:	e822                	sd	s0,16(sp)
    80002328:	e426                	sd	s1,8(sp)
    8000232a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	798080e7          	jalr	1944(ra) # 80001ac4 <myproc>
    80002334:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	980080e7          	jalr	-1664(ra) # 80000cb6 <acquire>
  p->state = RUNNABLE;
    8000233e:	4789                	li	a5,2
    80002340:	cc9c                	sw	a5,24(s1)
  sched();
    80002342:	00000097          	auipc	ra,0x0
    80002346:	dfc080e7          	jalr	-516(ra) # 8000213e <sched>
  release(&p->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	a1e080e7          	jalr	-1506(ra) # 80000d6a <release>
}
    80002354:	60e2                	ld	ra,24(sp)
    80002356:	6442                	ld	s0,16(sp)
    80002358:	64a2                	ld	s1,8(sp)
    8000235a:	6105                	addi	sp,sp,32
    8000235c:	8082                	ret

000000008000235e <sleep>:
{
    8000235e:	7179                	addi	sp,sp,-48
    80002360:	f406                	sd	ra,40(sp)
    80002362:	f022                	sd	s0,32(sp)
    80002364:	ec26                	sd	s1,24(sp)
    80002366:	e84a                	sd	s2,16(sp)
    80002368:	e44e                	sd	s3,8(sp)
    8000236a:	1800                	addi	s0,sp,48
    8000236c:	89aa                	mv	s3,a0
    8000236e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	754080e7          	jalr	1876(ra) # 80001ac4 <myproc>
    80002378:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000237a:	05250663          	beq	a0,s2,800023c6 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000237e:	fffff097          	auipc	ra,0xfffff
    80002382:	938080e7          	jalr	-1736(ra) # 80000cb6 <acquire>
    release(lk);
    80002386:	854a                	mv	a0,s2
    80002388:	fffff097          	auipc	ra,0xfffff
    8000238c:	9e2080e7          	jalr	-1566(ra) # 80000d6a <release>
  p->chan = chan;
    80002390:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002394:	4785                	li	a5,1
    80002396:	cc9c                	sw	a5,24(s1)
  sched();
    80002398:	00000097          	auipc	ra,0x0
    8000239c:	da6080e7          	jalr	-602(ra) # 8000213e <sched>
  p->chan = 0;
    800023a0:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800023a4:	8526                	mv	a0,s1
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	9c4080e7          	jalr	-1596(ra) # 80000d6a <release>
    acquire(lk);
    800023ae:	854a                	mv	a0,s2
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	906080e7          	jalr	-1786(ra) # 80000cb6 <acquire>
}
    800023b8:	70a2                	ld	ra,40(sp)
    800023ba:	7402                	ld	s0,32(sp)
    800023bc:	64e2                	ld	s1,24(sp)
    800023be:	6942                	ld	s2,16(sp)
    800023c0:	69a2                	ld	s3,8(sp)
    800023c2:	6145                	addi	sp,sp,48
    800023c4:	8082                	ret
  p->chan = chan;
    800023c6:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800023ca:	4785                	li	a5,1
    800023cc:	cd1c                	sw	a5,24(a0)
  sched();
    800023ce:	00000097          	auipc	ra,0x0
    800023d2:	d70080e7          	jalr	-656(ra) # 8000213e <sched>
  p->chan = 0;
    800023d6:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800023da:	bff9                	j	800023b8 <sleep+0x5a>

00000000800023dc <wait>:
{
    800023dc:	715d                	addi	sp,sp,-80
    800023de:	e486                	sd	ra,72(sp)
    800023e0:	e0a2                	sd	s0,64(sp)
    800023e2:	fc26                	sd	s1,56(sp)
    800023e4:	f84a                	sd	s2,48(sp)
    800023e6:	f44e                	sd	s3,40(sp)
    800023e8:	f052                	sd	s4,32(sp)
    800023ea:	ec56                	sd	s5,24(sp)
    800023ec:	e85a                	sd	s6,16(sp)
    800023ee:	e45e                	sd	s7,8(sp)
    800023f0:	e062                	sd	s8,0(sp)
    800023f2:	0880                	addi	s0,sp,80
    800023f4:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    800023f6:	fffff097          	auipc	ra,0xfffff
    800023fa:	6ce080e7          	jalr	1742(ra) # 80001ac4 <myproc>
    800023fe:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002400:	8c2a                	mv	s8,a0
    80002402:	fffff097          	auipc	ra,0xfffff
    80002406:	8b4080e7          	jalr	-1868(ra) # 80000cb6 <acquire>
    havekids = 0;
    8000240a:	4b01                	li	s6,0
        if(np->state == ZOMBIE){
    8000240c:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000240e:	00016997          	auipc	s3,0x16
    80002412:	b5a98993          	addi	s3,s3,-1190 # 80017f68 <tickslock>
        havekids = 1;
    80002416:	4a85                	li	s5,1
    havekids = 0;
    80002418:	875a                	mv	a4,s6
    for(np = proc; np < &proc[NPROC]; np++){
    8000241a:	00010497          	auipc	s1,0x10
    8000241e:	94e48493          	addi	s1,s1,-1714 # 80011d68 <proc>
    80002422:	a08d                	j	80002484 <wait+0xa8>
          pid = np->pid;
    80002424:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002428:	000b8e63          	beqz	s7,80002444 <wait+0x68>
    8000242c:	4691                	li	a3,4
    8000242e:	03448613          	addi	a2,s1,52
    80002432:	85de                	mv	a1,s7
    80002434:	05093503          	ld	a0,80(s2)
    80002438:	fffff097          	auipc	ra,0xfffff
    8000243c:	368080e7          	jalr	872(ra) # 800017a0 <copyout>
    80002440:	02054263          	bltz	a0,80002464 <wait+0x88>
          freeproc(np);
    80002444:	8526                	mv	a0,s1
    80002446:	00000097          	auipc	ra,0x0
    8000244a:	832080e7          	jalr	-1998(ra) # 80001c78 <freeproc>
          release(&np->lock);
    8000244e:	8526                	mv	a0,s1
    80002450:	fffff097          	auipc	ra,0xfffff
    80002454:	91a080e7          	jalr	-1766(ra) # 80000d6a <release>
          release(&p->lock);
    80002458:	854a                	mv	a0,s2
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	910080e7          	jalr	-1776(ra) # 80000d6a <release>
          return pid;
    80002462:	a8a9                	j	800024bc <wait+0xe0>
            release(&np->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	904080e7          	jalr	-1788(ra) # 80000d6a <release>
            release(&p->lock);
    8000246e:	854a                	mv	a0,s2
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	8fa080e7          	jalr	-1798(ra) # 80000d6a <release>
            return -1;
    80002478:	59fd                	li	s3,-1
    8000247a:	a089                	j	800024bc <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000247c:	18848493          	addi	s1,s1,392
    80002480:	03348463          	beq	s1,s3,800024a8 <wait+0xcc>
      if(np->parent == p){
    80002484:	709c                	ld	a5,32(s1)
    80002486:	ff279be3          	bne	a5,s2,8000247c <wait+0xa0>
        acquire(&np->lock);
    8000248a:	8526                	mv	a0,s1
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	82a080e7          	jalr	-2006(ra) # 80000cb6 <acquire>
        if(np->state == ZOMBIE){
    80002494:	4c9c                	lw	a5,24(s1)
    80002496:	f94787e3          	beq	a5,s4,80002424 <wait+0x48>
        release(&np->lock);
    8000249a:	8526                	mv	a0,s1
    8000249c:	fffff097          	auipc	ra,0xfffff
    800024a0:	8ce080e7          	jalr	-1842(ra) # 80000d6a <release>
        havekids = 1;
    800024a4:	8756                	mv	a4,s5
    800024a6:	bfd9                	j	8000247c <wait+0xa0>
    if(!havekids || p->killed){
    800024a8:	c701                	beqz	a4,800024b0 <wait+0xd4>
    800024aa:	03092783          	lw	a5,48(s2)
    800024ae:	c785                	beqz	a5,800024d6 <wait+0xfa>
      release(&p->lock);
    800024b0:	854a                	mv	a0,s2
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	8b8080e7          	jalr	-1864(ra) # 80000d6a <release>
      return -1;
    800024ba:	59fd                	li	s3,-1
}
    800024bc:	854e                	mv	a0,s3
    800024be:	60a6                	ld	ra,72(sp)
    800024c0:	6406                	ld	s0,64(sp)
    800024c2:	74e2                	ld	s1,56(sp)
    800024c4:	7942                	ld	s2,48(sp)
    800024c6:	79a2                	ld	s3,40(sp)
    800024c8:	7a02                	ld	s4,32(sp)
    800024ca:	6ae2                	ld	s5,24(sp)
    800024cc:	6b42                	ld	s6,16(sp)
    800024ce:	6ba2                	ld	s7,8(sp)
    800024d0:	6c02                	ld	s8,0(sp)
    800024d2:	6161                	addi	sp,sp,80
    800024d4:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800024d6:	85e2                	mv	a1,s8
    800024d8:	854a                	mv	a0,s2
    800024da:	00000097          	auipc	ra,0x0
    800024de:	e84080e7          	jalr	-380(ra) # 8000235e <sleep>
    havekids = 0;
    800024e2:	bf1d                	j	80002418 <wait+0x3c>

00000000800024e4 <wakeup>:
{
    800024e4:	7139                	addi	sp,sp,-64
    800024e6:	fc06                	sd	ra,56(sp)
    800024e8:	f822                	sd	s0,48(sp)
    800024ea:	f426                	sd	s1,40(sp)
    800024ec:	f04a                	sd	s2,32(sp)
    800024ee:	ec4e                	sd	s3,24(sp)
    800024f0:	e852                	sd	s4,16(sp)
    800024f2:	e456                	sd	s5,8(sp)
    800024f4:	0080                	addi	s0,sp,64
    800024f6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800024f8:	00010497          	auipc	s1,0x10
    800024fc:	87048493          	addi	s1,s1,-1936 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002500:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002502:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002504:	00016917          	auipc	s2,0x16
    80002508:	a6490913          	addi	s2,s2,-1436 # 80017f68 <tickslock>
    8000250c:	a821                	j	80002524 <wakeup+0x40>
      p->state = RUNNABLE;
    8000250e:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	856080e7          	jalr	-1962(ra) # 80000d6a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000251c:	18848493          	addi	s1,s1,392
    80002520:	01248e63          	beq	s1,s2,8000253c <wakeup+0x58>
    acquire(&p->lock);
    80002524:	8526                	mv	a0,s1
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	790080e7          	jalr	1936(ra) # 80000cb6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000252e:	4c9c                	lw	a5,24(s1)
    80002530:	ff3791e3          	bne	a5,s3,80002512 <wakeup+0x2e>
    80002534:	749c                	ld	a5,40(s1)
    80002536:	fd479ee3          	bne	a5,s4,80002512 <wakeup+0x2e>
    8000253a:	bfd1                	j	8000250e <wakeup+0x2a>
}
    8000253c:	70e2                	ld	ra,56(sp)
    8000253e:	7442                	ld	s0,48(sp)
    80002540:	74a2                	ld	s1,40(sp)
    80002542:	7902                	ld	s2,32(sp)
    80002544:	69e2                	ld	s3,24(sp)
    80002546:	6a42                	ld	s4,16(sp)
    80002548:	6aa2                	ld	s5,8(sp)
    8000254a:	6121                	addi	sp,sp,64
    8000254c:	8082                	ret

000000008000254e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000254e:	7179                	addi	sp,sp,-48
    80002550:	f406                	sd	ra,40(sp)
    80002552:	f022                	sd	s0,32(sp)
    80002554:	ec26                	sd	s1,24(sp)
    80002556:	e84a                	sd	s2,16(sp)
    80002558:	e44e                	sd	s3,8(sp)
    8000255a:	1800                	addi	s0,sp,48
    8000255c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000255e:	00010497          	auipc	s1,0x10
    80002562:	80a48493          	addi	s1,s1,-2038 # 80011d68 <proc>
    80002566:	00016997          	auipc	s3,0x16
    8000256a:	a0298993          	addi	s3,s3,-1534 # 80017f68 <tickslock>
    acquire(&p->lock);
    8000256e:	8526                	mv	a0,s1
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	746080e7          	jalr	1862(ra) # 80000cb6 <acquire>
    if(p->pid == pid){
    80002578:	5c9c                	lw	a5,56(s1)
    8000257a:	01278d63          	beq	a5,s2,80002594 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000257e:	8526                	mv	a0,s1
    80002580:	ffffe097          	auipc	ra,0xffffe
    80002584:	7ea080e7          	jalr	2026(ra) # 80000d6a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002588:	18848493          	addi	s1,s1,392
    8000258c:	ff3491e3          	bne	s1,s3,8000256e <kill+0x20>
  }
  return -1;
    80002590:	557d                	li	a0,-1
    80002592:	a829                	j	800025ac <kill+0x5e>
      p->killed = 1;
    80002594:	4785                	li	a5,1
    80002596:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002598:	4c98                	lw	a4,24(s1)
    8000259a:	4785                	li	a5,1
    8000259c:	00f70f63          	beq	a4,a5,800025ba <kill+0x6c>
      release(&p->lock);
    800025a0:	8526                	mv	a0,s1
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	7c8080e7          	jalr	1992(ra) # 80000d6a <release>
      return 0;
    800025aa:	4501                	li	a0,0
}
    800025ac:	70a2                	ld	ra,40(sp)
    800025ae:	7402                	ld	s0,32(sp)
    800025b0:	64e2                	ld	s1,24(sp)
    800025b2:	6942                	ld	s2,16(sp)
    800025b4:	69a2                	ld	s3,8(sp)
    800025b6:	6145                	addi	sp,sp,48
    800025b8:	8082                	ret
        p->state = RUNNABLE;
    800025ba:	4789                	li	a5,2
    800025bc:	cc9c                	sw	a5,24(s1)
    800025be:	b7cd                	j	800025a0 <kill+0x52>

00000000800025c0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025c0:	7179                	addi	sp,sp,-48
    800025c2:	f406                	sd	ra,40(sp)
    800025c4:	f022                	sd	s0,32(sp)
    800025c6:	ec26                	sd	s1,24(sp)
    800025c8:	e84a                	sd	s2,16(sp)
    800025ca:	e44e                	sd	s3,8(sp)
    800025cc:	e052                	sd	s4,0(sp)
    800025ce:	1800                	addi	s0,sp,48
    800025d0:	84aa                	mv	s1,a0
    800025d2:	892e                	mv	s2,a1
    800025d4:	89b2                	mv	s3,a2
    800025d6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025d8:	fffff097          	auipc	ra,0xfffff
    800025dc:	4ec080e7          	jalr	1260(ra) # 80001ac4 <myproc>
  if(user_dst){
    800025e0:	c08d                	beqz	s1,80002602 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025e2:	86d2                	mv	a3,s4
    800025e4:	864e                	mv	a2,s3
    800025e6:	85ca                	mv	a1,s2
    800025e8:	6928                	ld	a0,80(a0)
    800025ea:	fffff097          	auipc	ra,0xfffff
    800025ee:	1b6080e7          	jalr	438(ra) # 800017a0 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025f2:	70a2                	ld	ra,40(sp)
    800025f4:	7402                	ld	s0,32(sp)
    800025f6:	64e2                	ld	s1,24(sp)
    800025f8:	6942                	ld	s2,16(sp)
    800025fa:	69a2                	ld	s3,8(sp)
    800025fc:	6a02                	ld	s4,0(sp)
    800025fe:	6145                	addi	sp,sp,48
    80002600:	8082                	ret
    memmove((char *)dst, src, len);
    80002602:	000a061b          	sext.w	a2,s4
    80002606:	85ce                	mv	a1,s3
    80002608:	854a                	mv	a0,s2
    8000260a:	fffff097          	auipc	ra,0xfffff
    8000260e:	814080e7          	jalr	-2028(ra) # 80000e1e <memmove>
    return 0;
    80002612:	8526                	mv	a0,s1
    80002614:	bff9                	j	800025f2 <either_copyout+0x32>

0000000080002616 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002616:	7179                	addi	sp,sp,-48
    80002618:	f406                	sd	ra,40(sp)
    8000261a:	f022                	sd	s0,32(sp)
    8000261c:	ec26                	sd	s1,24(sp)
    8000261e:	e84a                	sd	s2,16(sp)
    80002620:	e44e                	sd	s3,8(sp)
    80002622:	e052                	sd	s4,0(sp)
    80002624:	1800                	addi	s0,sp,48
    80002626:	892a                	mv	s2,a0
    80002628:	84ae                	mv	s1,a1
    8000262a:	89b2                	mv	s3,a2
    8000262c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000262e:	fffff097          	auipc	ra,0xfffff
    80002632:	496080e7          	jalr	1174(ra) # 80001ac4 <myproc>
  if(user_src){
    80002636:	c08d                	beqz	s1,80002658 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002638:	86d2                	mv	a3,s4
    8000263a:	864e                	mv	a2,s3
    8000263c:	85ca                	mv	a1,s2
    8000263e:	6928                	ld	a0,80(a0)
    80002640:	fffff097          	auipc	ra,0xfffff
    80002644:	1ec080e7          	jalr	492(ra) # 8000182c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002648:	70a2                	ld	ra,40(sp)
    8000264a:	7402                	ld	s0,32(sp)
    8000264c:	64e2                	ld	s1,24(sp)
    8000264e:	6942                	ld	s2,16(sp)
    80002650:	69a2                	ld	s3,8(sp)
    80002652:	6a02                	ld	s4,0(sp)
    80002654:	6145                	addi	sp,sp,48
    80002656:	8082                	ret
    memmove(dst, (char*)src, len);
    80002658:	000a061b          	sext.w	a2,s4
    8000265c:	85ce                	mv	a1,s3
    8000265e:	854a                	mv	a0,s2
    80002660:	ffffe097          	auipc	ra,0xffffe
    80002664:	7be080e7          	jalr	1982(ra) # 80000e1e <memmove>
    return 0;
    80002668:	8526                	mv	a0,s1
    8000266a:	bff9                	j	80002648 <either_copyin+0x32>

000000008000266c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000266c:	715d                	addi	sp,sp,-80
    8000266e:	e486                	sd	ra,72(sp)
    80002670:	e0a2                	sd	s0,64(sp)
    80002672:	fc26                	sd	s1,56(sp)
    80002674:	f84a                	sd	s2,48(sp)
    80002676:	f44e                	sd	s3,40(sp)
    80002678:	f052                	sd	s4,32(sp)
    8000267a:	ec56                	sd	s5,24(sp)
    8000267c:	e85a                	sd	s6,16(sp)
    8000267e:	e45e                	sd	s7,8(sp)
    80002680:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002682:	00006517          	auipc	a0,0x6
    80002686:	a4e50513          	addi	a0,a0,-1458 # 800080d0 <digits+0xb8>
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	fba080e7          	jalr	-70(ra) # 80000644 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002692:	00010497          	auipc	s1,0x10
    80002696:	82e48493          	addi	s1,s1,-2002 # 80011ec0 <proc+0x158>
    8000269a:	00016917          	auipc	s2,0x16
    8000269e:	a2690913          	addi	s2,s2,-1498 # 800180c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026a2:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800026a4:	00006997          	auipc	s3,0x6
    800026a8:	bf498993          	addi	s3,s3,-1036 # 80008298 <states.1732+0xc8>
    printf("%d %s %s", p->pid, state, p->name);
    800026ac:	00006a97          	auipc	s5,0x6
    800026b0:	bf4a8a93          	addi	s5,s5,-1036 # 800082a0 <states.1732+0xd0>
    printf("\n");
    800026b4:	00006a17          	auipc	s4,0x6
    800026b8:	a1ca0a13          	addi	s4,s4,-1508 # 800080d0 <digits+0xb8>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026bc:	00006b97          	auipc	s7,0x6
    800026c0:	b14b8b93          	addi	s7,s7,-1260 # 800081d0 <states.1732>
    800026c4:	a015                	j	800026e8 <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    800026c6:	86ba                	mv	a3,a4
    800026c8:	ee072583          	lw	a1,-288(a4)
    800026cc:	8556                	mv	a0,s5
    800026ce:	ffffe097          	auipc	ra,0xffffe
    800026d2:	f76080e7          	jalr	-138(ra) # 80000644 <printf>
    printf("\n");
    800026d6:	8552                	mv	a0,s4
    800026d8:	ffffe097          	auipc	ra,0xffffe
    800026dc:	f6c080e7          	jalr	-148(ra) # 80000644 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026e0:	18848493          	addi	s1,s1,392
    800026e4:	03248163          	beq	s1,s2,80002706 <procdump+0x9a>
    if(p->state == UNUSED)
    800026e8:	8726                	mv	a4,s1
    800026ea:	ec04a783          	lw	a5,-320(s1)
    800026ee:	dbed                	beqz	a5,800026e0 <procdump+0x74>
      state = "???";
    800026f0:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026f2:	fcfb6ae3          	bltu	s6,a5,800026c6 <procdump+0x5a>
    800026f6:	1782                	slli	a5,a5,0x20
    800026f8:	9381                	srli	a5,a5,0x20
    800026fa:	078e                	slli	a5,a5,0x3
    800026fc:	97de                	add	a5,a5,s7
    800026fe:	6390                	ld	a2,0(a5)
    80002700:	f279                	bnez	a2,800026c6 <procdump+0x5a>
      state = "???";
    80002702:	864e                	mv	a2,s3
    80002704:	b7c9                	j	800026c6 <procdump+0x5a>
  }
}
    80002706:	60a6                	ld	ra,72(sp)
    80002708:	6406                	ld	s0,64(sp)
    8000270a:	74e2                	ld	s1,56(sp)
    8000270c:	7942                	ld	s2,48(sp)
    8000270e:	79a2                	ld	s3,40(sp)
    80002710:	7a02                	ld	s4,32(sp)
    80002712:	6ae2                	ld	s5,24(sp)
    80002714:	6b42                	ld	s6,16(sp)
    80002716:	6ba2                	ld	s7,8(sp)
    80002718:	6161                	addi	sp,sp,80
    8000271a:	8082                	ret

000000008000271c <swtch>:
    8000271c:	00153023          	sd	ra,0(a0)
    80002720:	00253423          	sd	sp,8(a0)
    80002724:	e900                	sd	s0,16(a0)
    80002726:	ed04                	sd	s1,24(a0)
    80002728:	03253023          	sd	s2,32(a0)
    8000272c:	03353423          	sd	s3,40(a0)
    80002730:	03453823          	sd	s4,48(a0)
    80002734:	03553c23          	sd	s5,56(a0)
    80002738:	05653023          	sd	s6,64(a0)
    8000273c:	05753423          	sd	s7,72(a0)
    80002740:	05853823          	sd	s8,80(a0)
    80002744:	05953c23          	sd	s9,88(a0)
    80002748:	07a53023          	sd	s10,96(a0)
    8000274c:	07b53423          	sd	s11,104(a0)
    80002750:	0005b083          	ld	ra,0(a1)
    80002754:	0085b103          	ld	sp,8(a1)
    80002758:	6980                	ld	s0,16(a1)
    8000275a:	6d84                	ld	s1,24(a1)
    8000275c:	0205b903          	ld	s2,32(a1)
    80002760:	0285b983          	ld	s3,40(a1)
    80002764:	0305ba03          	ld	s4,48(a1)
    80002768:	0385ba83          	ld	s5,56(a1)
    8000276c:	0405bb03          	ld	s6,64(a1)
    80002770:	0485bb83          	ld	s7,72(a1)
    80002774:	0505bc03          	ld	s8,80(a1)
    80002778:	0585bc83          	ld	s9,88(a1)
    8000277c:	0605bd03          	ld	s10,96(a1)
    80002780:	0685bd83          	ld	s11,104(a1)
    80002784:	8082                	ret

0000000080002786 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002786:	1141                	addi	sp,sp,-16
    80002788:	e406                	sd	ra,8(sp)
    8000278a:	e022                	sd	s0,0(sp)
    8000278c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000278e:	00006597          	auipc	a1,0x6
    80002792:	b4a58593          	addi	a1,a1,-1206 # 800082d8 <states.1732+0x108>
    80002796:	00015517          	auipc	a0,0x15
    8000279a:	7d250513          	addi	a0,a0,2002 # 80017f68 <tickslock>
    8000279e:	ffffe097          	auipc	ra,0xffffe
    800027a2:	488080e7          	jalr	1160(ra) # 80000c26 <initlock>
}
    800027a6:	60a2                	ld	ra,8(sp)
    800027a8:	6402                	ld	s0,0(sp)
    800027aa:	0141                	addi	sp,sp,16
    800027ac:	8082                	ret

00000000800027ae <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027ae:	1141                	addi	sp,sp,-16
    800027b0:	e422                	sd	s0,8(sp)
    800027b2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027b4:	00003797          	auipc	a5,0x3
    800027b8:	6ac78793          	addi	a5,a5,1708 # 80005e60 <kernelvec>
    800027bc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027c0:	6422                	ld	s0,8(sp)
    800027c2:	0141                	addi	sp,sp,16
    800027c4:	8082                	ret

00000000800027c6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800027c6:	1141                	addi	sp,sp,-16
    800027c8:	e406                	sd	ra,8(sp)
    800027ca:	e022                	sd	s0,0(sp)
    800027cc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027ce:	fffff097          	auipc	ra,0xfffff
    800027d2:	2f6080e7          	jalr	758(ra) # 80001ac4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027da:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027dc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027e0:	00005617          	auipc	a2,0x5
    800027e4:	82060613          	addi	a2,a2,-2016 # 80007000 <_trampoline>
    800027e8:	00005697          	auipc	a3,0x5
    800027ec:	81868693          	addi	a3,a3,-2024 # 80007000 <_trampoline>
    800027f0:	8e91                	sub	a3,a3,a2
    800027f2:	040007b7          	lui	a5,0x4000
    800027f6:	17fd                	addi	a5,a5,-1
    800027f8:	07b2                	slli	a5,a5,0xc
    800027fa:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027fc:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002800:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002802:	180026f3          	csrr	a3,satp
    80002806:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002808:	6d38                	ld	a4,88(a0)
    8000280a:	6134                	ld	a3,64(a0)
    8000280c:	6585                	lui	a1,0x1
    8000280e:	96ae                	add	a3,a3,a1
    80002810:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002812:	6d38                	ld	a4,88(a0)
    80002814:	00000697          	auipc	a3,0x0
    80002818:	13868693          	addi	a3,a3,312 # 8000294c <usertrap>
    8000281c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000281e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002820:	8692                	mv	a3,tp
    80002822:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002824:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002828:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000282c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002830:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002834:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002836:	6f18                	ld	a4,24(a4)
    80002838:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000283c:	692c                	ld	a1,80(a0)
    8000283e:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002840:	00005717          	auipc	a4,0x5
    80002844:	85070713          	addi	a4,a4,-1968 # 80007090 <userret>
    80002848:	8f11                	sub	a4,a4,a2
    8000284a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000284c:	577d                	li	a4,-1
    8000284e:	177e                	slli	a4,a4,0x3f
    80002850:	8dd9                	or	a1,a1,a4
    80002852:	02000537          	lui	a0,0x2000
    80002856:	157d                	addi	a0,a0,-1
    80002858:	0536                	slli	a0,a0,0xd
    8000285a:	9782                	jalr	a5
}
    8000285c:	60a2                	ld	ra,8(sp)
    8000285e:	6402                	ld	s0,0(sp)
    80002860:	0141                	addi	sp,sp,16
    80002862:	8082                	ret

0000000080002864 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002864:	1101                	addi	sp,sp,-32
    80002866:	ec06                	sd	ra,24(sp)
    80002868:	e822                	sd	s0,16(sp)
    8000286a:	e426                	sd	s1,8(sp)
    8000286c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000286e:	00015497          	auipc	s1,0x15
    80002872:	6fa48493          	addi	s1,s1,1786 # 80017f68 <tickslock>
    80002876:	8526                	mv	a0,s1
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	43e080e7          	jalr	1086(ra) # 80000cb6 <acquire>
  ticks++;
    80002880:	00006517          	auipc	a0,0x6
    80002884:	7a050513          	addi	a0,a0,1952 # 80009020 <ticks>
    80002888:	411c                	lw	a5,0(a0)
    8000288a:	2785                	addiw	a5,a5,1
    8000288c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000288e:	00000097          	auipc	ra,0x0
    80002892:	c56080e7          	jalr	-938(ra) # 800024e4 <wakeup>
  release(&tickslock);
    80002896:	8526                	mv	a0,s1
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	4d2080e7          	jalr	1234(ra) # 80000d6a <release>
}
    800028a0:	60e2                	ld	ra,24(sp)
    800028a2:	6442                	ld	s0,16(sp)
    800028a4:	64a2                	ld	s1,8(sp)
    800028a6:	6105                	addi	sp,sp,32
    800028a8:	8082                	ret

00000000800028aa <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028aa:	1101                	addi	sp,sp,-32
    800028ac:	ec06                	sd	ra,24(sp)
    800028ae:	e822                	sd	s0,16(sp)
    800028b0:	e426                	sd	s1,8(sp)
    800028b2:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b4:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028b8:	00074d63          	bltz	a4,800028d2 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028bc:	57fd                	li	a5,-1
    800028be:	17fe                	slli	a5,a5,0x3f
    800028c0:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028c2:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800028c4:	06f70363          	beq	a4,a5,8000292a <devintr+0x80>
  }
}
    800028c8:	60e2                	ld	ra,24(sp)
    800028ca:	6442                	ld	s0,16(sp)
    800028cc:	64a2                	ld	s1,8(sp)
    800028ce:	6105                	addi	sp,sp,32
    800028d0:	8082                	ret
     (scause & 0xff) == 9){
    800028d2:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028d6:	46a5                	li	a3,9
    800028d8:	fed792e3          	bne	a5,a3,800028bc <devintr+0x12>
    int irq = plic_claim();
    800028dc:	00003097          	auipc	ra,0x3
    800028e0:	68c080e7          	jalr	1676(ra) # 80005f68 <plic_claim>
    800028e4:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028e6:	47a9                	li	a5,10
    800028e8:	02f50763          	beq	a0,a5,80002916 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028ec:	4785                	li	a5,1
    800028ee:	02f50963          	beq	a0,a5,80002920 <devintr+0x76>
    return 1;
    800028f2:	4505                	li	a0,1
    } else if(irq){
    800028f4:	d8f1                	beqz	s1,800028c8 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028f6:	85a6                	mv	a1,s1
    800028f8:	00006517          	auipc	a0,0x6
    800028fc:	9e850513          	addi	a0,a0,-1560 # 800082e0 <states.1732+0x110>
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	d44080e7          	jalr	-700(ra) # 80000644 <printf>
      plic_complete(irq);
    80002908:	8526                	mv	a0,s1
    8000290a:	00003097          	auipc	ra,0x3
    8000290e:	682080e7          	jalr	1666(ra) # 80005f8c <plic_complete>
    return 1;
    80002912:	4505                	li	a0,1
    80002914:	bf55                	j	800028c8 <devintr+0x1e>
      uartintr();
    80002916:	ffffe097          	auipc	ra,0xffffe
    8000291a:	160080e7          	jalr	352(ra) # 80000a76 <uartintr>
    8000291e:	b7ed                	j	80002908 <devintr+0x5e>
      virtio_disk_intr();
    80002920:	00004097          	auipc	ra,0x4
    80002924:	b18080e7          	jalr	-1256(ra) # 80006438 <virtio_disk_intr>
    80002928:	b7c5                	j	80002908 <devintr+0x5e>
    if(cpuid() == 0){
    8000292a:	fffff097          	auipc	ra,0xfffff
    8000292e:	16e080e7          	jalr	366(ra) # 80001a98 <cpuid>
    80002932:	c901                	beqz	a0,80002942 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002934:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002938:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000293a:	14479073          	csrw	sip,a5
    return 2;
    8000293e:	4509                	li	a0,2
    80002940:	b761                	j	800028c8 <devintr+0x1e>
      clockintr();
    80002942:	00000097          	auipc	ra,0x0
    80002946:	f22080e7          	jalr	-222(ra) # 80002864 <clockintr>
    8000294a:	b7ed                	j	80002934 <devintr+0x8a>

000000008000294c <usertrap>:
{
    8000294c:	1101                	addi	sp,sp,-32
    8000294e:	ec06                	sd	ra,24(sp)
    80002950:	e822                	sd	s0,16(sp)
    80002952:	e426                	sd	s1,8(sp)
    80002954:	e04a                	sd	s2,0(sp)
    80002956:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002958:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000295c:	1007f793          	andi	a5,a5,256
    80002960:	e3ad                	bnez	a5,800029c2 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002962:	00003797          	auipc	a5,0x3
    80002966:	4fe78793          	addi	a5,a5,1278 # 80005e60 <kernelvec>
    8000296a:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000296e:	fffff097          	auipc	ra,0xfffff
    80002972:	156080e7          	jalr	342(ra) # 80001ac4 <myproc>
    80002976:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002978:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000297a:	14102773          	csrr	a4,sepc
    8000297e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002980:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002984:	47a1                	li	a5,8
    80002986:	04f71c63          	bne	a4,a5,800029de <usertrap+0x92>
    if(p->killed)
    8000298a:	591c                	lw	a5,48(a0)
    8000298c:	e3b9                	bnez	a5,800029d2 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000298e:	6cb8                	ld	a4,88(s1)
    80002990:	6f1c                	ld	a5,24(a4)
    80002992:	0791                	addi	a5,a5,4
    80002994:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002996:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000299a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000299e:	10079073          	csrw	sstatus,a5
    syscall();
    800029a2:	00000097          	auipc	ra,0x0
    800029a6:	346080e7          	jalr	838(ra) # 80002ce8 <syscall>
  if(p->killed)
    800029aa:	589c                	lw	a5,48(s1)
    800029ac:	ebc5                	bnez	a5,80002a5c <usertrap+0x110>
  usertrapret();
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	e18080e7          	jalr	-488(ra) # 800027c6 <usertrapret>
}
    800029b6:	60e2                	ld	ra,24(sp)
    800029b8:	6442                	ld	s0,16(sp)
    800029ba:	64a2                	ld	s1,8(sp)
    800029bc:	6902                	ld	s2,0(sp)
    800029be:	6105                	addi	sp,sp,32
    800029c0:	8082                	ret
    panic("usertrap: not from user mode");
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	93e50513          	addi	a0,a0,-1730 # 80008300 <states.1732+0x130>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	c28080e7          	jalr	-984(ra) # 800005f2 <panic>
      exit(-1);
    800029d2:	557d                	li	a0,-1
    800029d4:	00000097          	auipc	ra,0x0
    800029d8:	842080e7          	jalr	-1982(ra) # 80002216 <exit>
    800029dc:	bf4d                	j	8000298e <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800029de:	00000097          	auipc	ra,0x0
    800029e2:	ecc080e7          	jalr	-308(ra) # 800028aa <devintr>
    800029e6:	892a                	mv	s2,a0
    800029e8:	c501                	beqz	a0,800029f0 <usertrap+0xa4>
  if(p->killed)
    800029ea:	589c                	lw	a5,48(s1)
    800029ec:	c3a1                	beqz	a5,80002a2c <usertrap+0xe0>
    800029ee:	a815                	j	80002a22 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f0:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029f4:	5c90                	lw	a2,56(s1)
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	92a50513          	addi	a0,a0,-1750 # 80008320 <states.1732+0x150>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	c46080e7          	jalr	-954(ra) # 80000644 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a06:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a0a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	94250513          	addi	a0,a0,-1726 # 80008350 <states.1732+0x180>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	c2e080e7          	jalr	-978(ra) # 80000644 <printf>
    p->killed = 1;
    80002a1e:	4785                	li	a5,1
    80002a20:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002a22:	557d                	li	a0,-1
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	7f2080e7          	jalr	2034(ra) # 80002216 <exit>
  if (which_dev == 2) {
    80002a2c:	4789                	li	a5,2
    80002a2e:	f8f910e3          	bne	s2,a5,800029ae <usertrap+0x62>
    if (p->intervals > 0 && p->pending == 0)
    80002a32:	16c4a783          	lw	a5,364(s1)
    80002a36:	00f05e63          	blez	a5,80002a52 <usertrap+0x106>
    80002a3a:	1684a703          	lw	a4,360(s1)
    80002a3e:	eb11                	bnez	a4,80002a52 <usertrap+0x106>
        p->tickers -= 1;
    80002a40:	1704a703          	lw	a4,368(s1)
    80002a44:	377d                	addiw	a4,a4,-1
    80002a46:	0007069b          	sext.w	a3,a4
        if (p->tickers <= 0)
    80002a4a:	00d05b63          	blez	a3,80002a60 <usertrap+0x114>
        p->tickers -= 1;
    80002a4e:	16e4a823          	sw	a4,368(s1)
    yield();
    80002a52:	00000097          	auipc	ra,0x0
    80002a56:	8d0080e7          	jalr	-1840(ra) # 80002322 <yield>
    80002a5a:	bf91                	j	800029ae <usertrap+0x62>
  int which_dev = 0;
    80002a5c:	4901                	li	s2,0
    80002a5e:	b7d1                	j	80002a22 <usertrap+0xd6>
          p->tickers = p->intervals;
    80002a60:	16f4a823          	sw	a5,368(s1)
          *p->alarm_trapframe = *p->trapframe;  // 这里必须是值拷贝
    80002a64:	6cb4                	ld	a3,88(s1)
    80002a66:	87b6                	mv	a5,a3
    80002a68:	1804b703          	ld	a4,384(s1)
    80002a6c:	12068693          	addi	a3,a3,288
    80002a70:	0007b803          	ld	a6,0(a5)
    80002a74:	6788                	ld	a0,8(a5)
    80002a76:	6b8c                	ld	a1,16(a5)
    80002a78:	6f90                	ld	a2,24(a5)
    80002a7a:	01073023          	sd	a6,0(a4)
    80002a7e:	e708                	sd	a0,8(a4)
    80002a80:	eb0c                	sd	a1,16(a4)
    80002a82:	ef10                	sd	a2,24(a4)
    80002a84:	02078793          	addi	a5,a5,32
    80002a88:	02070713          	addi	a4,a4,32
    80002a8c:	fed792e3          	bne	a5,a3,80002a70 <usertrap+0x124>
          p->trapframe->epc = (uint64)p->handler; // 返回用户态时执行中断处理函数
    80002a90:	6cbc                	ld	a5,88(s1)
    80002a92:	1784b703          	ld	a4,376(s1)
    80002a96:	ef98                	sd	a4,24(a5)
          p->pending = 1;
    80002a98:	4785                	li	a5,1
    80002a9a:	16f4a423          	sw	a5,360(s1)
    80002a9e:	bf55                	j	80002a52 <usertrap+0x106>

0000000080002aa0 <kerneltrap>:
{
    80002aa0:	7179                	addi	sp,sp,-48
    80002aa2:	f406                	sd	ra,40(sp)
    80002aa4:	f022                	sd	s0,32(sp)
    80002aa6:	ec26                	sd	s1,24(sp)
    80002aa8:	e84a                	sd	s2,16(sp)
    80002aaa:	e44e                	sd	s3,8(sp)
    80002aac:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aae:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ab2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ab6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002aba:	1004f793          	andi	a5,s1,256
    80002abe:	cb85                	beqz	a5,80002aee <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002ac4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002ac6:	ef85                	bnez	a5,80002afe <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ac8:	00000097          	auipc	ra,0x0
    80002acc:	de2080e7          	jalr	-542(ra) # 800028aa <devintr>
    80002ad0:	cd1d                	beqz	a0,80002b0e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ad2:	4789                	li	a5,2
    80002ad4:	06f50a63          	beq	a0,a5,80002b48 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ad8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002adc:	10049073          	csrw	sstatus,s1
}
    80002ae0:	70a2                	ld	ra,40(sp)
    80002ae2:	7402                	ld	s0,32(sp)
    80002ae4:	64e2                	ld	s1,24(sp)
    80002ae6:	6942                	ld	s2,16(sp)
    80002ae8:	69a2                	ld	s3,8(sp)
    80002aea:	6145                	addi	sp,sp,48
    80002aec:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	88250513          	addi	a0,a0,-1918 # 80008370 <states.1732+0x1a0>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	afc080e7          	jalr	-1284(ra) # 800005f2 <panic>
    panic("kerneltrap: interrupts enabled");
    80002afe:	00006517          	auipc	a0,0x6
    80002b02:	89a50513          	addi	a0,a0,-1894 # 80008398 <states.1732+0x1c8>
    80002b06:	ffffe097          	auipc	ra,0xffffe
    80002b0a:	aec080e7          	jalr	-1300(ra) # 800005f2 <panic>
    printf("scause %p\n", scause);
    80002b0e:	85ce                	mv	a1,s3
    80002b10:	00006517          	auipc	a0,0x6
    80002b14:	8a850513          	addi	a0,a0,-1880 # 800083b8 <states.1732+0x1e8>
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	b2c080e7          	jalr	-1236(ra) # 80000644 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b20:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b24:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b28:	00006517          	auipc	a0,0x6
    80002b2c:	8a050513          	addi	a0,a0,-1888 # 800083c8 <states.1732+0x1f8>
    80002b30:	ffffe097          	auipc	ra,0xffffe
    80002b34:	b14080e7          	jalr	-1260(ra) # 80000644 <printf>
    panic("kerneltrap");
    80002b38:	00006517          	auipc	a0,0x6
    80002b3c:	8a850513          	addi	a0,a0,-1880 # 800083e0 <states.1732+0x210>
    80002b40:	ffffe097          	auipc	ra,0xffffe
    80002b44:	ab2080e7          	jalr	-1358(ra) # 800005f2 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b48:	fffff097          	auipc	ra,0xfffff
    80002b4c:	f7c080e7          	jalr	-132(ra) # 80001ac4 <myproc>
    80002b50:	d541                	beqz	a0,80002ad8 <kerneltrap+0x38>
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	f72080e7          	jalr	-142(ra) # 80001ac4 <myproc>
    80002b5a:	4d18                	lw	a4,24(a0)
    80002b5c:	478d                	li	a5,3
    80002b5e:	f6f71de3          	bne	a4,a5,80002ad8 <kerneltrap+0x38>
    yield();
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	7c0080e7          	jalr	1984(ra) # 80002322 <yield>
    80002b6a:	b7bd                	j	80002ad8 <kerneltrap+0x38>

0000000080002b6c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b6c:	1101                	addi	sp,sp,-32
    80002b6e:	ec06                	sd	ra,24(sp)
    80002b70:	e822                	sd	s0,16(sp)
    80002b72:	e426                	sd	s1,8(sp)
    80002b74:	1000                	addi	s0,sp,32
    80002b76:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b78:	fffff097          	auipc	ra,0xfffff
    80002b7c:	f4c080e7          	jalr	-180(ra) # 80001ac4 <myproc>
  switch (n) {
    80002b80:	4795                	li	a5,5
    80002b82:	0497e363          	bltu	a5,s1,80002bc8 <argraw+0x5c>
    80002b86:	1482                	slli	s1,s1,0x20
    80002b88:	9081                	srli	s1,s1,0x20
    80002b8a:	048a                	slli	s1,s1,0x2
    80002b8c:	00006717          	auipc	a4,0x6
    80002b90:	86470713          	addi	a4,a4,-1948 # 800083f0 <states.1732+0x220>
    80002b94:	94ba                	add	s1,s1,a4
    80002b96:	409c                	lw	a5,0(s1)
    80002b98:	97ba                	add	a5,a5,a4
    80002b9a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b9c:	6d3c                	ld	a5,88(a0)
    80002b9e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ba0:	60e2                	ld	ra,24(sp)
    80002ba2:	6442                	ld	s0,16(sp)
    80002ba4:	64a2                	ld	s1,8(sp)
    80002ba6:	6105                	addi	sp,sp,32
    80002ba8:	8082                	ret
    return p->trapframe->a1;
    80002baa:	6d3c                	ld	a5,88(a0)
    80002bac:	7fa8                	ld	a0,120(a5)
    80002bae:	bfcd                	j	80002ba0 <argraw+0x34>
    return p->trapframe->a2;
    80002bb0:	6d3c                	ld	a5,88(a0)
    80002bb2:	63c8                	ld	a0,128(a5)
    80002bb4:	b7f5                	j	80002ba0 <argraw+0x34>
    return p->trapframe->a3;
    80002bb6:	6d3c                	ld	a5,88(a0)
    80002bb8:	67c8                	ld	a0,136(a5)
    80002bba:	b7dd                	j	80002ba0 <argraw+0x34>
    return p->trapframe->a4;
    80002bbc:	6d3c                	ld	a5,88(a0)
    80002bbe:	6bc8                	ld	a0,144(a5)
    80002bc0:	b7c5                	j	80002ba0 <argraw+0x34>
    return p->trapframe->a5;
    80002bc2:	6d3c                	ld	a5,88(a0)
    80002bc4:	6fc8                	ld	a0,152(a5)
    80002bc6:	bfe9                	j	80002ba0 <argraw+0x34>
  panic("argraw");
    80002bc8:	00006517          	auipc	a0,0x6
    80002bcc:	90050513          	addi	a0,a0,-1792 # 800084c8 <syscalls+0xc0>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	a22080e7          	jalr	-1502(ra) # 800005f2 <panic>

0000000080002bd8 <fetchaddr>:
{
    80002bd8:	1101                	addi	sp,sp,-32
    80002bda:	ec06                	sd	ra,24(sp)
    80002bdc:	e822                	sd	s0,16(sp)
    80002bde:	e426                	sd	s1,8(sp)
    80002be0:	e04a                	sd	s2,0(sp)
    80002be2:	1000                	addi	s0,sp,32
    80002be4:	84aa                	mv	s1,a0
    80002be6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	edc080e7          	jalr	-292(ra) # 80001ac4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bf0:	653c                	ld	a5,72(a0)
    80002bf2:	02f4f963          	bleu	a5,s1,80002c24 <fetchaddr+0x4c>
    80002bf6:	00848713          	addi	a4,s1,8
    80002bfa:	02e7e763          	bltu	a5,a4,80002c28 <fetchaddr+0x50>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bfe:	46a1                	li	a3,8
    80002c00:	8626                	mv	a2,s1
    80002c02:	85ca                	mv	a1,s2
    80002c04:	6928                	ld	a0,80(a0)
    80002c06:	fffff097          	auipc	ra,0xfffff
    80002c0a:	c26080e7          	jalr	-986(ra) # 8000182c <copyin>
    80002c0e:	00a03533          	snez	a0,a0
    80002c12:	40a0053b          	negw	a0,a0
    80002c16:	2501                	sext.w	a0,a0
}
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6902                	ld	s2,0(sp)
    80002c20:	6105                	addi	sp,sp,32
    80002c22:	8082                	ret
    return -1;
    80002c24:	557d                	li	a0,-1
    80002c26:	bfcd                	j	80002c18 <fetchaddr+0x40>
    80002c28:	557d                	li	a0,-1
    80002c2a:	b7fd                	j	80002c18 <fetchaddr+0x40>

0000000080002c2c <fetchstr>:
{
    80002c2c:	7179                	addi	sp,sp,-48
    80002c2e:	f406                	sd	ra,40(sp)
    80002c30:	f022                	sd	s0,32(sp)
    80002c32:	ec26                	sd	s1,24(sp)
    80002c34:	e84a                	sd	s2,16(sp)
    80002c36:	e44e                	sd	s3,8(sp)
    80002c38:	1800                	addi	s0,sp,48
    80002c3a:	892a                	mv	s2,a0
    80002c3c:	84ae                	mv	s1,a1
    80002c3e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	e84080e7          	jalr	-380(ra) # 80001ac4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c48:	86ce                	mv	a3,s3
    80002c4a:	864a                	mv	a2,s2
    80002c4c:	85a6                	mv	a1,s1
    80002c4e:	6928                	ld	a0,80(a0)
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	c6a080e7          	jalr	-918(ra) # 800018ba <copyinstr>
  if(err < 0)
    80002c58:	00054763          	bltz	a0,80002c66 <fetchstr+0x3a>
  return strlen(buf);
    80002c5c:	8526                	mv	a0,s1
    80002c5e:	ffffe097          	auipc	ra,0xffffe
    80002c62:	2fe080e7          	jalr	766(ra) # 80000f5c <strlen>
}
    80002c66:	70a2                	ld	ra,40(sp)
    80002c68:	7402                	ld	s0,32(sp)
    80002c6a:	64e2                	ld	s1,24(sp)
    80002c6c:	6942                	ld	s2,16(sp)
    80002c6e:	69a2                	ld	s3,8(sp)
    80002c70:	6145                	addi	sp,sp,48
    80002c72:	8082                	ret

0000000080002c74 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c74:	1101                	addi	sp,sp,-32
    80002c76:	ec06                	sd	ra,24(sp)
    80002c78:	e822                	sd	s0,16(sp)
    80002c7a:	e426                	sd	s1,8(sp)
    80002c7c:	1000                	addi	s0,sp,32
    80002c7e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	eec080e7          	jalr	-276(ra) # 80002b6c <argraw>
    80002c88:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c8a:	4501                	li	a0,0
    80002c8c:	60e2                	ld	ra,24(sp)
    80002c8e:	6442                	ld	s0,16(sp)
    80002c90:	64a2                	ld	s1,8(sp)
    80002c92:	6105                	addi	sp,sp,32
    80002c94:	8082                	ret

0000000080002c96 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c96:	1101                	addi	sp,sp,-32
    80002c98:	ec06                	sd	ra,24(sp)
    80002c9a:	e822                	sd	s0,16(sp)
    80002c9c:	e426                	sd	s1,8(sp)
    80002c9e:	1000                	addi	s0,sp,32
    80002ca0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ca2:	00000097          	auipc	ra,0x0
    80002ca6:	eca080e7          	jalr	-310(ra) # 80002b6c <argraw>
    80002caa:	e088                	sd	a0,0(s1)
  return 0;
}
    80002cac:	4501                	li	a0,0
    80002cae:	60e2                	ld	ra,24(sp)
    80002cb0:	6442                	ld	s0,16(sp)
    80002cb2:	64a2                	ld	s1,8(sp)
    80002cb4:	6105                	addi	sp,sp,32
    80002cb6:	8082                	ret

0000000080002cb8 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cb8:	1101                	addi	sp,sp,-32
    80002cba:	ec06                	sd	ra,24(sp)
    80002cbc:	e822                	sd	s0,16(sp)
    80002cbe:	e426                	sd	s1,8(sp)
    80002cc0:	e04a                	sd	s2,0(sp)
    80002cc2:	1000                	addi	s0,sp,32
    80002cc4:	84ae                	mv	s1,a1
    80002cc6:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	ea4080e7          	jalr	-348(ra) # 80002b6c <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002cd0:	864a                	mv	a2,s2
    80002cd2:	85a6                	mv	a1,s1
    80002cd4:	00000097          	auipc	ra,0x0
    80002cd8:	f58080e7          	jalr	-168(ra) # 80002c2c <fetchstr>
}
    80002cdc:	60e2                	ld	ra,24(sp)
    80002cde:	6442                	ld	s0,16(sp)
    80002ce0:	64a2                	ld	s1,8(sp)
    80002ce2:	6902                	ld	s2,0(sp)
    80002ce4:	6105                	addi	sp,sp,32
    80002ce6:	8082                	ret

0000000080002ce8 <syscall>:
[SYS_sigreturn]   sys_sigreturn,
};

void
syscall(void)
{
    80002ce8:	1101                	addi	sp,sp,-32
    80002cea:	ec06                	sd	ra,24(sp)
    80002cec:	e822                	sd	s0,16(sp)
    80002cee:	e426                	sd	s1,8(sp)
    80002cf0:	e04a                	sd	s2,0(sp)
    80002cf2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	dd0080e7          	jalr	-560(ra) # 80001ac4 <myproc>
    80002cfc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cfe:	05853903          	ld	s2,88(a0)
    80002d02:	0a893783          	ld	a5,168(s2)
    80002d06:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d0a:	37fd                	addiw	a5,a5,-1
    80002d0c:	4759                	li	a4,22
    80002d0e:	00f76f63          	bltu	a4,a5,80002d2c <syscall+0x44>
    80002d12:	00369713          	slli	a4,a3,0x3
    80002d16:	00005797          	auipc	a5,0x5
    80002d1a:	6f278793          	addi	a5,a5,1778 # 80008408 <syscalls>
    80002d1e:	97ba                	add	a5,a5,a4
    80002d20:	639c                	ld	a5,0(a5)
    80002d22:	c789                	beqz	a5,80002d2c <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d24:	9782                	jalr	a5
    80002d26:	06a93823          	sd	a0,112(s2)
    80002d2a:	a839                	j	80002d48 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d2c:	15848613          	addi	a2,s1,344
    80002d30:	5c8c                	lw	a1,56(s1)
    80002d32:	00005517          	auipc	a0,0x5
    80002d36:	79e50513          	addi	a0,a0,1950 # 800084d0 <syscalls+0xc8>
    80002d3a:	ffffe097          	auipc	ra,0xffffe
    80002d3e:	90a080e7          	jalr	-1782(ra) # 80000644 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d42:	6cbc                	ld	a5,88(s1)
    80002d44:	577d                	li	a4,-1
    80002d46:	fbb8                	sd	a4,112(a5)
  }
}
    80002d48:	60e2                	ld	ra,24(sp)
    80002d4a:	6442                	ld	s0,16(sp)
    80002d4c:	64a2                	ld	s1,8(sp)
    80002d4e:	6902                	ld	s2,0(sp)
    80002d50:	6105                	addi	sp,sp,32
    80002d52:	8082                	ret

0000000080002d54 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d54:	1101                	addi	sp,sp,-32
    80002d56:	ec06                	sd	ra,24(sp)
    80002d58:	e822                	sd	s0,16(sp)
    80002d5a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d5c:	fec40593          	addi	a1,s0,-20
    80002d60:	4501                	li	a0,0
    80002d62:	00000097          	auipc	ra,0x0
    80002d66:	f12080e7          	jalr	-238(ra) # 80002c74 <argint>
    return -1;
    80002d6a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d6c:	00054963          	bltz	a0,80002d7e <sys_exit+0x2a>
  exit(n);
    80002d70:	fec42503          	lw	a0,-20(s0)
    80002d74:	fffff097          	auipc	ra,0xfffff
    80002d78:	4a2080e7          	jalr	1186(ra) # 80002216 <exit>
  return 0;  // not reached
    80002d7c:	4781                	li	a5,0
}
    80002d7e:	853e                	mv	a0,a5
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	6105                	addi	sp,sp,32
    80002d86:	8082                	ret

0000000080002d88 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d88:	1141                	addi	sp,sp,-16
    80002d8a:	e406                	sd	ra,8(sp)
    80002d8c:	e022                	sd	s0,0(sp)
    80002d8e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	d34080e7          	jalr	-716(ra) # 80001ac4 <myproc>
}
    80002d98:	5d08                	lw	a0,56(a0)
    80002d9a:	60a2                	ld	ra,8(sp)
    80002d9c:	6402                	ld	s0,0(sp)
    80002d9e:	0141                	addi	sp,sp,16
    80002da0:	8082                	ret

0000000080002da2 <sys_fork>:

uint64
sys_fork(void)
{
    80002da2:	1141                	addi	sp,sp,-16
    80002da4:	e406                	sd	ra,8(sp)
    80002da6:	e022                	sd	s0,0(sp)
    80002da8:	0800                	addi	s0,sp,16
  return fork();
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	164080e7          	jalr	356(ra) # 80001f0e <fork>
}
    80002db2:	60a2                	ld	ra,8(sp)
    80002db4:	6402                	ld	s0,0(sp)
    80002db6:	0141                	addi	sp,sp,16
    80002db8:	8082                	ret

0000000080002dba <sys_wait>:

uint64
sys_wait(void)
{
    80002dba:	1101                	addi	sp,sp,-32
    80002dbc:	ec06                	sd	ra,24(sp)
    80002dbe:	e822                	sd	s0,16(sp)
    80002dc0:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dc2:	fe840593          	addi	a1,s0,-24
    80002dc6:	4501                	li	a0,0
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	ece080e7          	jalr	-306(ra) # 80002c96 <argaddr>
    return -1;
    80002dd0:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80002dd2:	00054963          	bltz	a0,80002de4 <sys_wait+0x2a>
  return wait(p);
    80002dd6:	fe843503          	ld	a0,-24(s0)
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	602080e7          	jalr	1538(ra) # 800023dc <wait>
    80002de2:	87aa                	mv	a5,a0
}
    80002de4:	853e                	mv	a0,a5
    80002de6:	60e2                	ld	ra,24(sp)
    80002de8:	6442                	ld	s0,16(sp)
    80002dea:	6105                	addi	sp,sp,32
    80002dec:	8082                	ret

0000000080002dee <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dee:	7179                	addi	sp,sp,-48
    80002df0:	f406                	sd	ra,40(sp)
    80002df2:	f022                	sd	s0,32(sp)
    80002df4:	ec26                	sd	s1,24(sp)
    80002df6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002df8:	fdc40593          	addi	a1,s0,-36
    80002dfc:	4501                	li	a0,0
    80002dfe:	00000097          	auipc	ra,0x0
    80002e02:	e76080e7          	jalr	-394(ra) # 80002c74 <argint>
    return -1;
    80002e06:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002e08:	00054f63          	bltz	a0,80002e26 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002e0c:	fffff097          	auipc	ra,0xfffff
    80002e10:	cb8080e7          	jalr	-840(ra) # 80001ac4 <myproc>
    80002e14:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e16:	fdc42503          	lw	a0,-36(s0)
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	07c080e7          	jalr	124(ra) # 80001e96 <growproc>
    80002e22:	00054863          	bltz	a0,80002e32 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002e26:	8526                	mv	a0,s1
    80002e28:	70a2                	ld	ra,40(sp)
    80002e2a:	7402                	ld	s0,32(sp)
    80002e2c:	64e2                	ld	s1,24(sp)
    80002e2e:	6145                	addi	sp,sp,48
    80002e30:	8082                	ret
    return -1;
    80002e32:	54fd                	li	s1,-1
    80002e34:	bfcd                	j	80002e26 <sys_sbrk+0x38>

0000000080002e36 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e36:	7139                	addi	sp,sp,-64
    80002e38:	fc06                	sd	ra,56(sp)
    80002e3a:	f822                	sd	s0,48(sp)
    80002e3c:	f426                	sd	s1,40(sp)
    80002e3e:	f04a                	sd	s2,32(sp)
    80002e40:	ec4e                	sd	s3,24(sp)
    80002e42:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

// begin+++++
   backtrace();
    80002e44:	ffffd097          	auipc	ra,0xffffd
    80002e48:	762080e7          	jalr	1890(ra) # 800005a6 <backtrace>
   // end-------


  if(argint(0, &n) < 0)
    80002e4c:	fcc40593          	addi	a1,s0,-52
    80002e50:	4501                	li	a0,0
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	e22080e7          	jalr	-478(ra) # 80002c74 <argint>
    return -1;
    80002e5a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e5c:	06054763          	bltz	a0,80002eca <sys_sleep+0x94>
  acquire(&tickslock);
    80002e60:	00015517          	auipc	a0,0x15
    80002e64:	10850513          	addi	a0,a0,264 # 80017f68 <tickslock>
    80002e68:	ffffe097          	auipc	ra,0xffffe
    80002e6c:	e4e080e7          	jalr	-434(ra) # 80000cb6 <acquire>
  ticks0 = ticks;
    80002e70:	00006797          	auipc	a5,0x6
    80002e74:	1b078793          	addi	a5,a5,432 # 80009020 <ticks>
    80002e78:	0007a903          	lw	s2,0(a5)
  while(ticks - ticks0 < n){
    80002e7c:	fcc42783          	lw	a5,-52(s0)
    80002e80:	cf85                	beqz	a5,80002eb8 <sys_sleep+0x82>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e82:	00015997          	auipc	s3,0x15
    80002e86:	0e698993          	addi	s3,s3,230 # 80017f68 <tickslock>
    80002e8a:	00006497          	auipc	s1,0x6
    80002e8e:	19648493          	addi	s1,s1,406 # 80009020 <ticks>
    if(myproc()->killed){
    80002e92:	fffff097          	auipc	ra,0xfffff
    80002e96:	c32080e7          	jalr	-974(ra) # 80001ac4 <myproc>
    80002e9a:	591c                	lw	a5,48(a0)
    80002e9c:	ef9d                	bnez	a5,80002eda <sys_sleep+0xa4>
    sleep(&ticks, &tickslock);
    80002e9e:	85ce                	mv	a1,s3
    80002ea0:	8526                	mv	a0,s1
    80002ea2:	fffff097          	auipc	ra,0xfffff
    80002ea6:	4bc080e7          	jalr	1212(ra) # 8000235e <sleep>
  while(ticks - ticks0 < n){
    80002eaa:	409c                	lw	a5,0(s1)
    80002eac:	412787bb          	subw	a5,a5,s2
    80002eb0:	fcc42703          	lw	a4,-52(s0)
    80002eb4:	fce7efe3          	bltu	a5,a4,80002e92 <sys_sleep+0x5c>
  }
  release(&tickslock);
    80002eb8:	00015517          	auipc	a0,0x15
    80002ebc:	0b050513          	addi	a0,a0,176 # 80017f68 <tickslock>
    80002ec0:	ffffe097          	auipc	ra,0xffffe
    80002ec4:	eaa080e7          	jalr	-342(ra) # 80000d6a <release>
  return 0;
    80002ec8:	4781                	li	a5,0
}
    80002eca:	853e                	mv	a0,a5
    80002ecc:	70e2                	ld	ra,56(sp)
    80002ece:	7442                	ld	s0,48(sp)
    80002ed0:	74a2                	ld	s1,40(sp)
    80002ed2:	7902                	ld	s2,32(sp)
    80002ed4:	69e2                	ld	s3,24(sp)
    80002ed6:	6121                	addi	sp,sp,64
    80002ed8:	8082                	ret
      release(&tickslock);
    80002eda:	00015517          	auipc	a0,0x15
    80002ede:	08e50513          	addi	a0,a0,142 # 80017f68 <tickslock>
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	e88080e7          	jalr	-376(ra) # 80000d6a <release>
      return -1;
    80002eea:	57fd                	li	a5,-1
    80002eec:	bff9                	j	80002eca <sys_sleep+0x94>

0000000080002eee <sys_kill>:

uint64
sys_kill(void)
{
    80002eee:	1101                	addi	sp,sp,-32
    80002ef0:	ec06                	sd	ra,24(sp)
    80002ef2:	e822                	sd	s0,16(sp)
    80002ef4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ef6:	fec40593          	addi	a1,s0,-20
    80002efa:	4501                	li	a0,0
    80002efc:	00000097          	auipc	ra,0x0
    80002f00:	d78080e7          	jalr	-648(ra) # 80002c74 <argint>
    return -1;
    80002f04:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80002f06:	00054963          	bltz	a0,80002f18 <sys_kill+0x2a>
  return kill(pid);
    80002f0a:	fec42503          	lw	a0,-20(s0)
    80002f0e:	fffff097          	auipc	ra,0xfffff
    80002f12:	640080e7          	jalr	1600(ra) # 8000254e <kill>
    80002f16:	87aa                	mv	a5,a0
}
    80002f18:	853e                	mv	a0,a5
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	6105                	addi	sp,sp,32
    80002f20:	8082                	ret

0000000080002f22 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f22:	1101                	addi	sp,sp,-32
    80002f24:	ec06                	sd	ra,24(sp)
    80002f26:	e822                	sd	s0,16(sp)
    80002f28:	e426                	sd	s1,8(sp)
    80002f2a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f2c:	00015517          	auipc	a0,0x15
    80002f30:	03c50513          	addi	a0,a0,60 # 80017f68 <tickslock>
    80002f34:	ffffe097          	auipc	ra,0xffffe
    80002f38:	d82080e7          	jalr	-638(ra) # 80000cb6 <acquire>
  xticks = ticks;
    80002f3c:	00006797          	auipc	a5,0x6
    80002f40:	0e478793          	addi	a5,a5,228 # 80009020 <ticks>
    80002f44:	4384                	lw	s1,0(a5)
  release(&tickslock);
    80002f46:	00015517          	auipc	a0,0x15
    80002f4a:	02250513          	addi	a0,a0,34 # 80017f68 <tickslock>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	e1c080e7          	jalr	-484(ra) # 80000d6a <release>
  return xticks;
}
    80002f56:	02049513          	slli	a0,s1,0x20
    80002f5a:	9101                	srli	a0,a0,0x20
    80002f5c:	60e2                	ld	ra,24(sp)
    80002f5e:	6442                	ld	s0,16(sp)
    80002f60:	64a2                	ld	s1,8(sp)
    80002f62:	6105                	addi	sp,sp,32
    80002f64:	8082                	ret

0000000080002f66 <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    80002f66:	1101                	addi	sp,sp,-32
    80002f68:	ec06                	sd	ra,24(sp)
    80002f6a:	e822                	sd	s0,16(sp)
    80002f6c:	1000                	addi	s0,sp,32
  int n;
  uint64 fn;
  if (argint(0, &n) < 0)
    80002f6e:	fec40593          	addi	a1,s0,-20
    80002f72:	4501                	li	a0,0
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	d00080e7          	jalr	-768(ra) # 80002c74 <argint>
    return -1;
    80002f7c:	57fd                	li	a5,-1
  if (argint(0, &n) < 0)
    80002f7e:	02054b63          	bltz	a0,80002fb4 <sys_sigalarm+0x4e>
  if (argaddr(1, &fn) < 0)
    80002f82:	fe040593          	addi	a1,s0,-32
    80002f86:	4505                	li	a0,1
    80002f88:	00000097          	auipc	ra,0x0
    80002f8c:	d0e080e7          	jalr	-754(ra) # 80002c96 <argaddr>
    return -1;
    80002f90:	57fd                	li	a5,-1
  if (argaddr(1, &fn) < 0)
    80002f92:	02054163          	bltz	a0,80002fb4 <sys_sigalarm+0x4e>

  struct proc* p = myproc();
    80002f96:	fffff097          	auipc	ra,0xfffff
    80002f9a:	b2e080e7          	jalr	-1234(ra) # 80001ac4 <myproc>
  p->intervals = n;
    80002f9e:	fec42783          	lw	a5,-20(s0)
    80002fa2:	16f52623          	sw	a5,364(a0)
  p->tickers = n;
    80002fa6:	16f52823          	sw	a5,368(a0)
  p->handler = (void(*)())(fn);
    80002faa:	fe043783          	ld	a5,-32(s0)
    80002fae:	16f53c23          	sd	a5,376(a0)
  return 0;
    80002fb2:	4781                	li	a5,0
}
    80002fb4:	853e                	mv	a0,a5
    80002fb6:	60e2                	ld	ra,24(sp)
    80002fb8:	6442                	ld	s0,16(sp)
    80002fba:	6105                	addi	sp,sp,32
    80002fbc:	8082                	ret

0000000080002fbe <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    80002fbe:	1141                	addi	sp,sp,-16
    80002fc0:	e406                	sd	ra,8(sp)
    80002fc2:	e022                	sd	s0,0(sp)
    80002fc4:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	afe080e7          	jalr	-1282(ra) # 80001ac4 <myproc>
  *p->trapframe = *p->alarm_trapframe;// 这里必须是值拷贝
    80002fce:	18053683          	ld	a3,384(a0)
    80002fd2:	87b6                	mv	a5,a3
    80002fd4:	6d38                	ld	a4,88(a0)
    80002fd6:	12068693          	addi	a3,a3,288
    80002fda:	0007b883          	ld	a7,0(a5)
    80002fde:	0087b803          	ld	a6,8(a5)
    80002fe2:	6b8c                	ld	a1,16(a5)
    80002fe4:	6f90                	ld	a2,24(a5)
    80002fe6:	01173023          	sd	a7,0(a4)
    80002fea:	01073423          	sd	a6,8(a4)
    80002fee:	eb0c                	sd	a1,16(a4)
    80002ff0:	ef10                	sd	a2,24(a4)
    80002ff2:	02078793          	addi	a5,a5,32
    80002ff6:	02070713          	addi	a4,a4,32
    80002ffa:	fed790e3          	bne	a5,a3,80002fda <sys_sigreturn+0x1c>
  p->pending = 0;
    80002ffe:	16052423          	sw	zero,360(a0)
  return 0;
}
    80003002:	4501                	li	a0,0
    80003004:	60a2                	ld	ra,8(sp)
    80003006:	6402                	ld	s0,0(sp)
    80003008:	0141                	addi	sp,sp,16
    8000300a:	8082                	ret

000000008000300c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000300c:	7179                	addi	sp,sp,-48
    8000300e:	f406                	sd	ra,40(sp)
    80003010:	f022                	sd	s0,32(sp)
    80003012:	ec26                	sd	s1,24(sp)
    80003014:	e84a                	sd	s2,16(sp)
    80003016:	e44e                	sd	s3,8(sp)
    80003018:	e052                	sd	s4,0(sp)
    8000301a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000301c:	00005597          	auipc	a1,0x5
    80003020:	4d458593          	addi	a1,a1,1236 # 800084f0 <syscalls+0xe8>
    80003024:	00015517          	auipc	a0,0x15
    80003028:	f5c50513          	addi	a0,a0,-164 # 80017f80 <bcache>
    8000302c:	ffffe097          	auipc	ra,0xffffe
    80003030:	bfa080e7          	jalr	-1030(ra) # 80000c26 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003034:	0001d797          	auipc	a5,0x1d
    80003038:	f4c78793          	addi	a5,a5,-180 # 8001ff80 <bcache+0x8000>
    8000303c:	0001d717          	auipc	a4,0x1d
    80003040:	1ac70713          	addi	a4,a4,428 # 800201e8 <bcache+0x8268>
    80003044:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003048:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000304c:	00015497          	auipc	s1,0x15
    80003050:	f4c48493          	addi	s1,s1,-180 # 80017f98 <bcache+0x18>
    b->next = bcache.head.next;
    80003054:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003056:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003058:	00005a17          	auipc	s4,0x5
    8000305c:	4a0a0a13          	addi	s4,s4,1184 # 800084f8 <syscalls+0xf0>
    b->next = bcache.head.next;
    80003060:	2b893783          	ld	a5,696(s2)
    80003064:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003066:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000306a:	85d2                	mv	a1,s4
    8000306c:	01048513          	addi	a0,s1,16
    80003070:	00001097          	auipc	ra,0x1
    80003074:	51a080e7          	jalr	1306(ra) # 8000458a <initsleeplock>
    bcache.head.next->prev = b;
    80003078:	2b893783          	ld	a5,696(s2)
    8000307c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000307e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003082:	45848493          	addi	s1,s1,1112
    80003086:	fd349de3          	bne	s1,s3,80003060 <binit+0x54>
  }
}
    8000308a:	70a2                	ld	ra,40(sp)
    8000308c:	7402                	ld	s0,32(sp)
    8000308e:	64e2                	ld	s1,24(sp)
    80003090:	6942                	ld	s2,16(sp)
    80003092:	69a2                	ld	s3,8(sp)
    80003094:	6a02                	ld	s4,0(sp)
    80003096:	6145                	addi	sp,sp,48
    80003098:	8082                	ret

000000008000309a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000309a:	7179                	addi	sp,sp,-48
    8000309c:	f406                	sd	ra,40(sp)
    8000309e:	f022                	sd	s0,32(sp)
    800030a0:	ec26                	sd	s1,24(sp)
    800030a2:	e84a                	sd	s2,16(sp)
    800030a4:	e44e                	sd	s3,8(sp)
    800030a6:	1800                	addi	s0,sp,48
    800030a8:	89aa                	mv	s3,a0
    800030aa:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030ac:	00015517          	auipc	a0,0x15
    800030b0:	ed450513          	addi	a0,a0,-300 # 80017f80 <bcache>
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	c02080e7          	jalr	-1022(ra) # 80000cb6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030bc:	0001d797          	auipc	a5,0x1d
    800030c0:	ec478793          	addi	a5,a5,-316 # 8001ff80 <bcache+0x8000>
    800030c4:	2b87b483          	ld	s1,696(a5)
    800030c8:	0001d797          	auipc	a5,0x1d
    800030cc:	12078793          	addi	a5,a5,288 # 800201e8 <bcache+0x8268>
    800030d0:	02f48f63          	beq	s1,a5,8000310e <bread+0x74>
    800030d4:	873e                	mv	a4,a5
    800030d6:	a021                	j	800030de <bread+0x44>
    800030d8:	68a4                	ld	s1,80(s1)
    800030da:	02e48a63          	beq	s1,a4,8000310e <bread+0x74>
    if(b->dev == dev && b->blockno == blockno){
    800030de:	449c                	lw	a5,8(s1)
    800030e0:	ff379ce3          	bne	a5,s3,800030d8 <bread+0x3e>
    800030e4:	44dc                	lw	a5,12(s1)
    800030e6:	ff2799e3          	bne	a5,s2,800030d8 <bread+0x3e>
      b->refcnt++;
    800030ea:	40bc                	lw	a5,64(s1)
    800030ec:	2785                	addiw	a5,a5,1
    800030ee:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030f0:	00015517          	auipc	a0,0x15
    800030f4:	e9050513          	addi	a0,a0,-368 # 80017f80 <bcache>
    800030f8:	ffffe097          	auipc	ra,0xffffe
    800030fc:	c72080e7          	jalr	-910(ra) # 80000d6a <release>
      acquiresleep(&b->lock);
    80003100:	01048513          	addi	a0,s1,16
    80003104:	00001097          	auipc	ra,0x1
    80003108:	4c0080e7          	jalr	1216(ra) # 800045c4 <acquiresleep>
      return b;
    8000310c:	a8b1                	j	80003168 <bread+0xce>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000310e:	0001d797          	auipc	a5,0x1d
    80003112:	e7278793          	addi	a5,a5,-398 # 8001ff80 <bcache+0x8000>
    80003116:	2b07b483          	ld	s1,688(a5)
    8000311a:	0001d797          	auipc	a5,0x1d
    8000311e:	0ce78793          	addi	a5,a5,206 # 800201e8 <bcache+0x8268>
    80003122:	04f48d63          	beq	s1,a5,8000317c <bread+0xe2>
    if(b->refcnt == 0) {
    80003126:	40bc                	lw	a5,64(s1)
    80003128:	cb91                	beqz	a5,8000313c <bread+0xa2>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000312a:	0001d717          	auipc	a4,0x1d
    8000312e:	0be70713          	addi	a4,a4,190 # 800201e8 <bcache+0x8268>
    80003132:	64a4                	ld	s1,72(s1)
    80003134:	04e48463          	beq	s1,a4,8000317c <bread+0xe2>
    if(b->refcnt == 0) {
    80003138:	40bc                	lw	a5,64(s1)
    8000313a:	ffe5                	bnez	a5,80003132 <bread+0x98>
      b->dev = dev;
    8000313c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003140:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003144:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003148:	4785                	li	a5,1
    8000314a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000314c:	00015517          	auipc	a0,0x15
    80003150:	e3450513          	addi	a0,a0,-460 # 80017f80 <bcache>
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	c16080e7          	jalr	-1002(ra) # 80000d6a <release>
      acquiresleep(&b->lock);
    8000315c:	01048513          	addi	a0,s1,16
    80003160:	00001097          	auipc	ra,0x1
    80003164:	464080e7          	jalr	1124(ra) # 800045c4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003168:	409c                	lw	a5,0(s1)
    8000316a:	c38d                	beqz	a5,8000318c <bread+0xf2>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000316c:	8526                	mv	a0,s1
    8000316e:	70a2                	ld	ra,40(sp)
    80003170:	7402                	ld	s0,32(sp)
    80003172:	64e2                	ld	s1,24(sp)
    80003174:	6942                	ld	s2,16(sp)
    80003176:	69a2                	ld	s3,8(sp)
    80003178:	6145                	addi	sp,sp,48
    8000317a:	8082                	ret
  panic("bget: no buffers");
    8000317c:	00005517          	auipc	a0,0x5
    80003180:	38450513          	addi	a0,a0,900 # 80008500 <syscalls+0xf8>
    80003184:	ffffd097          	auipc	ra,0xffffd
    80003188:	46e080e7          	jalr	1134(ra) # 800005f2 <panic>
    virtio_disk_rw(b, 0);
    8000318c:	4581                	li	a1,0
    8000318e:	8526                	mv	a0,s1
    80003190:	00003097          	auipc	ra,0x3
    80003194:	fee080e7          	jalr	-18(ra) # 8000617e <virtio_disk_rw>
    b->valid = 1;
    80003198:	4785                	li	a5,1
    8000319a:	c09c                	sw	a5,0(s1)
  return b;
    8000319c:	bfc1                	j	8000316c <bread+0xd2>

000000008000319e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000319e:	1101                	addi	sp,sp,-32
    800031a0:	ec06                	sd	ra,24(sp)
    800031a2:	e822                	sd	s0,16(sp)
    800031a4:	e426                	sd	s1,8(sp)
    800031a6:	1000                	addi	s0,sp,32
    800031a8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031aa:	0541                	addi	a0,a0,16
    800031ac:	00001097          	auipc	ra,0x1
    800031b0:	4b2080e7          	jalr	1202(ra) # 8000465e <holdingsleep>
    800031b4:	cd01                	beqz	a0,800031cc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031b6:	4585                	li	a1,1
    800031b8:	8526                	mv	a0,s1
    800031ba:	00003097          	auipc	ra,0x3
    800031be:	fc4080e7          	jalr	-60(ra) # 8000617e <virtio_disk_rw>
}
    800031c2:	60e2                	ld	ra,24(sp)
    800031c4:	6442                	ld	s0,16(sp)
    800031c6:	64a2                	ld	s1,8(sp)
    800031c8:	6105                	addi	sp,sp,32
    800031ca:	8082                	ret
    panic("bwrite");
    800031cc:	00005517          	auipc	a0,0x5
    800031d0:	34c50513          	addi	a0,a0,844 # 80008518 <syscalls+0x110>
    800031d4:	ffffd097          	auipc	ra,0xffffd
    800031d8:	41e080e7          	jalr	1054(ra) # 800005f2 <panic>

00000000800031dc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	e04a                	sd	s2,0(sp)
    800031e6:	1000                	addi	s0,sp,32
    800031e8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ea:	01050913          	addi	s2,a0,16
    800031ee:	854a                	mv	a0,s2
    800031f0:	00001097          	auipc	ra,0x1
    800031f4:	46e080e7          	jalr	1134(ra) # 8000465e <holdingsleep>
    800031f8:	c92d                	beqz	a0,8000326a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031fa:	854a                	mv	a0,s2
    800031fc:	00001097          	auipc	ra,0x1
    80003200:	41e080e7          	jalr	1054(ra) # 8000461a <releasesleep>

  acquire(&bcache.lock);
    80003204:	00015517          	auipc	a0,0x15
    80003208:	d7c50513          	addi	a0,a0,-644 # 80017f80 <bcache>
    8000320c:	ffffe097          	auipc	ra,0xffffe
    80003210:	aaa080e7          	jalr	-1366(ra) # 80000cb6 <acquire>
  b->refcnt--;
    80003214:	40bc                	lw	a5,64(s1)
    80003216:	37fd                	addiw	a5,a5,-1
    80003218:	0007871b          	sext.w	a4,a5
    8000321c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000321e:	eb05                	bnez	a4,8000324e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003220:	68bc                	ld	a5,80(s1)
    80003222:	64b8                	ld	a4,72(s1)
    80003224:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003226:	64bc                	ld	a5,72(s1)
    80003228:	68b8                	ld	a4,80(s1)
    8000322a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000322c:	0001d797          	auipc	a5,0x1d
    80003230:	d5478793          	addi	a5,a5,-684 # 8001ff80 <bcache+0x8000>
    80003234:	2b87b703          	ld	a4,696(a5)
    80003238:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000323a:	0001d717          	auipc	a4,0x1d
    8000323e:	fae70713          	addi	a4,a4,-82 # 800201e8 <bcache+0x8268>
    80003242:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003244:	2b87b703          	ld	a4,696(a5)
    80003248:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000324a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000324e:	00015517          	auipc	a0,0x15
    80003252:	d3250513          	addi	a0,a0,-718 # 80017f80 <bcache>
    80003256:	ffffe097          	auipc	ra,0xffffe
    8000325a:	b14080e7          	jalr	-1260(ra) # 80000d6a <release>
}
    8000325e:	60e2                	ld	ra,24(sp)
    80003260:	6442                	ld	s0,16(sp)
    80003262:	64a2                	ld	s1,8(sp)
    80003264:	6902                	ld	s2,0(sp)
    80003266:	6105                	addi	sp,sp,32
    80003268:	8082                	ret
    panic("brelse");
    8000326a:	00005517          	auipc	a0,0x5
    8000326e:	2b650513          	addi	a0,a0,694 # 80008520 <syscalls+0x118>
    80003272:	ffffd097          	auipc	ra,0xffffd
    80003276:	380080e7          	jalr	896(ra) # 800005f2 <panic>

000000008000327a <bpin>:

void
bpin(struct buf *b) {
    8000327a:	1101                	addi	sp,sp,-32
    8000327c:	ec06                	sd	ra,24(sp)
    8000327e:	e822                	sd	s0,16(sp)
    80003280:	e426                	sd	s1,8(sp)
    80003282:	1000                	addi	s0,sp,32
    80003284:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003286:	00015517          	auipc	a0,0x15
    8000328a:	cfa50513          	addi	a0,a0,-774 # 80017f80 <bcache>
    8000328e:	ffffe097          	auipc	ra,0xffffe
    80003292:	a28080e7          	jalr	-1496(ra) # 80000cb6 <acquire>
  b->refcnt++;
    80003296:	40bc                	lw	a5,64(s1)
    80003298:	2785                	addiw	a5,a5,1
    8000329a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000329c:	00015517          	auipc	a0,0x15
    800032a0:	ce450513          	addi	a0,a0,-796 # 80017f80 <bcache>
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	ac6080e7          	jalr	-1338(ra) # 80000d6a <release>
}
    800032ac:	60e2                	ld	ra,24(sp)
    800032ae:	6442                	ld	s0,16(sp)
    800032b0:	64a2                	ld	s1,8(sp)
    800032b2:	6105                	addi	sp,sp,32
    800032b4:	8082                	ret

00000000800032b6 <bunpin>:

void
bunpin(struct buf *b) {
    800032b6:	1101                	addi	sp,sp,-32
    800032b8:	ec06                	sd	ra,24(sp)
    800032ba:	e822                	sd	s0,16(sp)
    800032bc:	e426                	sd	s1,8(sp)
    800032be:	1000                	addi	s0,sp,32
    800032c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032c2:	00015517          	auipc	a0,0x15
    800032c6:	cbe50513          	addi	a0,a0,-834 # 80017f80 <bcache>
    800032ca:	ffffe097          	auipc	ra,0xffffe
    800032ce:	9ec080e7          	jalr	-1556(ra) # 80000cb6 <acquire>
  b->refcnt--;
    800032d2:	40bc                	lw	a5,64(s1)
    800032d4:	37fd                	addiw	a5,a5,-1
    800032d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032d8:	00015517          	auipc	a0,0x15
    800032dc:	ca850513          	addi	a0,a0,-856 # 80017f80 <bcache>
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	a8a080e7          	jalr	-1398(ra) # 80000d6a <release>
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret

00000000800032f2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032f2:	1101                	addi	sp,sp,-32
    800032f4:	ec06                	sd	ra,24(sp)
    800032f6:	e822                	sd	s0,16(sp)
    800032f8:	e426                	sd	s1,8(sp)
    800032fa:	e04a                	sd	s2,0(sp)
    800032fc:	1000                	addi	s0,sp,32
    800032fe:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003300:	00d5d59b          	srliw	a1,a1,0xd
    80003304:	0001d797          	auipc	a5,0x1d
    80003308:	33c78793          	addi	a5,a5,828 # 80020640 <sb>
    8000330c:	4fdc                	lw	a5,28(a5)
    8000330e:	9dbd                	addw	a1,a1,a5
    80003310:	00000097          	auipc	ra,0x0
    80003314:	d8a080e7          	jalr	-630(ra) # 8000309a <bread>
  bi = b % BPB;
    80003318:	2481                	sext.w	s1,s1
  m = 1 << (bi % 8);
    8000331a:	0074f793          	andi	a5,s1,7
    8000331e:	4705                	li	a4,1
    80003320:	00f7173b          	sllw	a4,a4,a5
  bi = b % BPB;
    80003324:	6789                	lui	a5,0x2
    80003326:	17fd                	addi	a5,a5,-1
    80003328:	8cfd                	and	s1,s1,a5
  if((bp->data[bi/8] & m) == 0)
    8000332a:	41f4d79b          	sraiw	a5,s1,0x1f
    8000332e:	01d7d79b          	srliw	a5,a5,0x1d
    80003332:	9fa5                	addw	a5,a5,s1
    80003334:	4037d79b          	sraiw	a5,a5,0x3
    80003338:	00f506b3          	add	a3,a0,a5
    8000333c:	0586c683          	lbu	a3,88(a3)
    80003340:	00d77633          	and	a2,a4,a3
    80003344:	c61d                	beqz	a2,80003372 <bfree+0x80>
    80003346:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003348:	97aa                	add	a5,a5,a0
    8000334a:	fff74713          	not	a4,a4
    8000334e:	8f75                	and	a4,a4,a3
    80003350:	04e78c23          	sb	a4,88(a5) # 2058 <_entry-0x7fffdfa8>
  log_write(bp);
    80003354:	00001097          	auipc	ra,0x1
    80003358:	132080e7          	jalr	306(ra) # 80004486 <log_write>
  brelse(bp);
    8000335c:	854a                	mv	a0,s2
    8000335e:	00000097          	auipc	ra,0x0
    80003362:	e7e080e7          	jalr	-386(ra) # 800031dc <brelse>
}
    80003366:	60e2                	ld	ra,24(sp)
    80003368:	6442                	ld	s0,16(sp)
    8000336a:	64a2                	ld	s1,8(sp)
    8000336c:	6902                	ld	s2,0(sp)
    8000336e:	6105                	addi	sp,sp,32
    80003370:	8082                	ret
    panic("freeing free block");
    80003372:	00005517          	auipc	a0,0x5
    80003376:	1b650513          	addi	a0,a0,438 # 80008528 <syscalls+0x120>
    8000337a:	ffffd097          	auipc	ra,0xffffd
    8000337e:	278080e7          	jalr	632(ra) # 800005f2 <panic>

0000000080003382 <balloc>:
{
    80003382:	711d                	addi	sp,sp,-96
    80003384:	ec86                	sd	ra,88(sp)
    80003386:	e8a2                	sd	s0,80(sp)
    80003388:	e4a6                	sd	s1,72(sp)
    8000338a:	e0ca                	sd	s2,64(sp)
    8000338c:	fc4e                	sd	s3,56(sp)
    8000338e:	f852                	sd	s4,48(sp)
    80003390:	f456                	sd	s5,40(sp)
    80003392:	f05a                	sd	s6,32(sp)
    80003394:	ec5e                	sd	s7,24(sp)
    80003396:	e862                	sd	s8,16(sp)
    80003398:	e466                	sd	s9,8(sp)
    8000339a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000339c:	0001d797          	auipc	a5,0x1d
    800033a0:	2a478793          	addi	a5,a5,676 # 80020640 <sb>
    800033a4:	43dc                	lw	a5,4(a5)
    800033a6:	10078e63          	beqz	a5,800034c2 <balloc+0x140>
    800033aa:	8baa                	mv	s7,a0
    800033ac:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033ae:	0001db17          	auipc	s6,0x1d
    800033b2:	292b0b13          	addi	s6,s6,658 # 80020640 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033b6:	4c05                	li	s8,1
      m = 1 << (bi % 8);
    800033b8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ba:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033bc:	6c89                	lui	s9,0x2
    800033be:	a079                	j	8000344c <balloc+0xca>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c0:	8942                	mv	s2,a6
      m = 1 << (bi % 8);
    800033c2:	4705                	li	a4,1
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800033c4:	4681                	li	a3,0
        bp->data[bi/8] |= m;  // Mark block in use.
    800033c6:	96a6                	add	a3,a3,s1
    800033c8:	8f51                	or	a4,a4,a2
    800033ca:	04e68c23          	sb	a4,88(a3)
        log_write(bp);
    800033ce:	8526                	mv	a0,s1
    800033d0:	00001097          	auipc	ra,0x1
    800033d4:	0b6080e7          	jalr	182(ra) # 80004486 <log_write>
        brelse(bp);
    800033d8:	8526                	mv	a0,s1
    800033da:	00000097          	auipc	ra,0x0
    800033de:	e02080e7          	jalr	-510(ra) # 800031dc <brelse>
  bp = bread(dev, bno);
    800033e2:	85ca                	mv	a1,s2
    800033e4:	855e                	mv	a0,s7
    800033e6:	00000097          	auipc	ra,0x0
    800033ea:	cb4080e7          	jalr	-844(ra) # 8000309a <bread>
    800033ee:	84aa                	mv	s1,a0
  memset(bp->data, 0, BSIZE);
    800033f0:	40000613          	li	a2,1024
    800033f4:	4581                	li	a1,0
    800033f6:	05850513          	addi	a0,a0,88
    800033fa:	ffffe097          	auipc	ra,0xffffe
    800033fe:	9b8080e7          	jalr	-1608(ra) # 80000db2 <memset>
  log_write(bp);
    80003402:	8526                	mv	a0,s1
    80003404:	00001097          	auipc	ra,0x1
    80003408:	082080e7          	jalr	130(ra) # 80004486 <log_write>
  brelse(bp);
    8000340c:	8526                	mv	a0,s1
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	dce080e7          	jalr	-562(ra) # 800031dc <brelse>
}
    80003416:	854a                	mv	a0,s2
    80003418:	60e6                	ld	ra,88(sp)
    8000341a:	6446                	ld	s0,80(sp)
    8000341c:	64a6                	ld	s1,72(sp)
    8000341e:	6906                	ld	s2,64(sp)
    80003420:	79e2                	ld	s3,56(sp)
    80003422:	7a42                	ld	s4,48(sp)
    80003424:	7aa2                	ld	s5,40(sp)
    80003426:	7b02                	ld	s6,32(sp)
    80003428:	6be2                	ld	s7,24(sp)
    8000342a:	6c42                	ld	s8,16(sp)
    8000342c:	6ca2                	ld	s9,8(sp)
    8000342e:	6125                	addi	sp,sp,96
    80003430:	8082                	ret
    brelse(bp);
    80003432:	8526                	mv	a0,s1
    80003434:	00000097          	auipc	ra,0x0
    80003438:	da8080e7          	jalr	-600(ra) # 800031dc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000343c:	015c87bb          	addw	a5,s9,s5
    80003440:	00078a9b          	sext.w	s5,a5
    80003444:	004b2703          	lw	a4,4(s6)
    80003448:	06eafd63          	bleu	a4,s5,800034c2 <balloc+0x140>
    bp = bread(dev, BBLOCK(b, sb));
    8000344c:	41fad79b          	sraiw	a5,s5,0x1f
    80003450:	0137d79b          	srliw	a5,a5,0x13
    80003454:	015787bb          	addw	a5,a5,s5
    80003458:	40d7d79b          	sraiw	a5,a5,0xd
    8000345c:	01cb2583          	lw	a1,28(s6)
    80003460:	9dbd                	addw	a1,a1,a5
    80003462:	855e                	mv	a0,s7
    80003464:	00000097          	auipc	ra,0x0
    80003468:	c36080e7          	jalr	-970(ra) # 8000309a <bread>
    8000346c:	84aa                	mv	s1,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000346e:	000a881b          	sext.w	a6,s5
    80003472:	004b2503          	lw	a0,4(s6)
    80003476:	faa87ee3          	bleu	a0,a6,80003432 <balloc+0xb0>
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000347a:	0584c603          	lbu	a2,88(s1)
    8000347e:	00167793          	andi	a5,a2,1
    80003482:	df9d                	beqz	a5,800033c0 <balloc+0x3e>
    80003484:	4105053b          	subw	a0,a0,a6
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003488:	87e2                	mv	a5,s8
    8000348a:	0107893b          	addw	s2,a5,a6
    8000348e:	faa782e3          	beq	a5,a0,80003432 <balloc+0xb0>
      m = 1 << (bi % 8);
    80003492:	41f7d71b          	sraiw	a4,a5,0x1f
    80003496:	01d7561b          	srliw	a2,a4,0x1d
    8000349a:	00f606bb          	addw	a3,a2,a5
    8000349e:	0076f713          	andi	a4,a3,7
    800034a2:	9f11                	subw	a4,a4,a2
    800034a4:	00e9973b          	sllw	a4,s3,a4
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034a8:	4036d69b          	sraiw	a3,a3,0x3
    800034ac:	00d48633          	add	a2,s1,a3
    800034b0:	05864603          	lbu	a2,88(a2)
    800034b4:	00c775b3          	and	a1,a4,a2
    800034b8:	d599                	beqz	a1,800033c6 <balloc+0x44>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ba:	2785                	addiw	a5,a5,1
    800034bc:	fd4797e3          	bne	a5,s4,8000348a <balloc+0x108>
    800034c0:	bf8d                	j	80003432 <balloc+0xb0>
  panic("balloc: out of blocks");
    800034c2:	00005517          	auipc	a0,0x5
    800034c6:	07e50513          	addi	a0,a0,126 # 80008540 <syscalls+0x138>
    800034ca:	ffffd097          	auipc	ra,0xffffd
    800034ce:	128080e7          	jalr	296(ra) # 800005f2 <panic>

00000000800034d2 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800034d2:	7179                	addi	sp,sp,-48
    800034d4:	f406                	sd	ra,40(sp)
    800034d6:	f022                	sd	s0,32(sp)
    800034d8:	ec26                	sd	s1,24(sp)
    800034da:	e84a                	sd	s2,16(sp)
    800034dc:	e44e                	sd	s3,8(sp)
    800034de:	e052                	sd	s4,0(sp)
    800034e0:	1800                	addi	s0,sp,48
    800034e2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034e4:	47ad                	li	a5,11
    800034e6:	04b7fe63          	bleu	a1,a5,80003542 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800034ea:	ff45849b          	addiw	s1,a1,-12
    800034ee:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034f2:	0ff00793          	li	a5,255
    800034f6:	0ae7e363          	bltu	a5,a4,8000359c <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800034fa:	08052583          	lw	a1,128(a0)
    800034fe:	c5ad                	beqz	a1,80003568 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003500:	0009a503          	lw	a0,0(s3)
    80003504:	00000097          	auipc	ra,0x0
    80003508:	b96080e7          	jalr	-1130(ra) # 8000309a <bread>
    8000350c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000350e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003512:	02049593          	slli	a1,s1,0x20
    80003516:	9181                	srli	a1,a1,0x20
    80003518:	058a                	slli	a1,a1,0x2
    8000351a:	00b784b3          	add	s1,a5,a1
    8000351e:	0004a903          	lw	s2,0(s1)
    80003522:	04090d63          	beqz	s2,8000357c <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003526:	8552                	mv	a0,s4
    80003528:	00000097          	auipc	ra,0x0
    8000352c:	cb4080e7          	jalr	-844(ra) # 800031dc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003530:	854a                	mv	a0,s2
    80003532:	70a2                	ld	ra,40(sp)
    80003534:	7402                	ld	s0,32(sp)
    80003536:	64e2                	ld	s1,24(sp)
    80003538:	6942                	ld	s2,16(sp)
    8000353a:	69a2                	ld	s3,8(sp)
    8000353c:	6a02                	ld	s4,0(sp)
    8000353e:	6145                	addi	sp,sp,48
    80003540:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003542:	02059493          	slli	s1,a1,0x20
    80003546:	9081                	srli	s1,s1,0x20
    80003548:	048a                	slli	s1,s1,0x2
    8000354a:	94aa                	add	s1,s1,a0
    8000354c:	0504a903          	lw	s2,80(s1)
    80003550:	fe0910e3          	bnez	s2,80003530 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003554:	4108                	lw	a0,0(a0)
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	e2c080e7          	jalr	-468(ra) # 80003382 <balloc>
    8000355e:	0005091b          	sext.w	s2,a0
    80003562:	0524a823          	sw	s2,80(s1)
    80003566:	b7e9                	j	80003530 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003568:	4108                	lw	a0,0(a0)
    8000356a:	00000097          	auipc	ra,0x0
    8000356e:	e18080e7          	jalr	-488(ra) # 80003382 <balloc>
    80003572:	0005059b          	sext.w	a1,a0
    80003576:	08b9a023          	sw	a1,128(s3)
    8000357a:	b759                	j	80003500 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000357c:	0009a503          	lw	a0,0(s3)
    80003580:	00000097          	auipc	ra,0x0
    80003584:	e02080e7          	jalr	-510(ra) # 80003382 <balloc>
    80003588:	0005091b          	sext.w	s2,a0
    8000358c:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    80003590:	8552                	mv	a0,s4
    80003592:	00001097          	auipc	ra,0x1
    80003596:	ef4080e7          	jalr	-268(ra) # 80004486 <log_write>
    8000359a:	b771                	j	80003526 <bmap+0x54>
  panic("bmap: out of range");
    8000359c:	00005517          	auipc	a0,0x5
    800035a0:	fbc50513          	addi	a0,a0,-68 # 80008558 <syscalls+0x150>
    800035a4:	ffffd097          	auipc	ra,0xffffd
    800035a8:	04e080e7          	jalr	78(ra) # 800005f2 <panic>

00000000800035ac <iget>:
{
    800035ac:	7179                	addi	sp,sp,-48
    800035ae:	f406                	sd	ra,40(sp)
    800035b0:	f022                	sd	s0,32(sp)
    800035b2:	ec26                	sd	s1,24(sp)
    800035b4:	e84a                	sd	s2,16(sp)
    800035b6:	e44e                	sd	s3,8(sp)
    800035b8:	e052                	sd	s4,0(sp)
    800035ba:	1800                	addi	s0,sp,48
    800035bc:	89aa                	mv	s3,a0
    800035be:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800035c0:	0001d517          	auipc	a0,0x1d
    800035c4:	0a050513          	addi	a0,a0,160 # 80020660 <icache>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	6ee080e7          	jalr	1774(ra) # 80000cb6 <acquire>
  empty = 0;
    800035d0:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035d2:	0001d497          	auipc	s1,0x1d
    800035d6:	0a648493          	addi	s1,s1,166 # 80020678 <icache+0x18>
    800035da:	0001f697          	auipc	a3,0x1f
    800035de:	b2e68693          	addi	a3,a3,-1234 # 80022108 <log>
    800035e2:	a039                	j	800035f0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035e4:	02090b63          	beqz	s2,8000361a <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800035e8:	08848493          	addi	s1,s1,136
    800035ec:	02d48a63          	beq	s1,a3,80003620 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035f0:	449c                	lw	a5,8(s1)
    800035f2:	fef059e3          	blez	a5,800035e4 <iget+0x38>
    800035f6:	4098                	lw	a4,0(s1)
    800035f8:	ff3716e3          	bne	a4,s3,800035e4 <iget+0x38>
    800035fc:	40d8                	lw	a4,4(s1)
    800035fe:	ff4713e3          	bne	a4,s4,800035e4 <iget+0x38>
      ip->ref++;
    80003602:	2785                	addiw	a5,a5,1
    80003604:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003606:	0001d517          	auipc	a0,0x1d
    8000360a:	05a50513          	addi	a0,a0,90 # 80020660 <icache>
    8000360e:	ffffd097          	auipc	ra,0xffffd
    80003612:	75c080e7          	jalr	1884(ra) # 80000d6a <release>
      return ip;
    80003616:	8926                	mv	s2,s1
    80003618:	a03d                	j	80003646 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000361a:	f7f9                	bnez	a5,800035e8 <iget+0x3c>
    8000361c:	8926                	mv	s2,s1
    8000361e:	b7e9                	j	800035e8 <iget+0x3c>
  if(empty == 0)
    80003620:	02090c63          	beqz	s2,80003658 <iget+0xac>
  ip->dev = dev;
    80003624:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003628:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000362c:	4785                	li	a5,1
    8000362e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003632:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003636:	0001d517          	auipc	a0,0x1d
    8000363a:	02a50513          	addi	a0,a0,42 # 80020660 <icache>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	72c080e7          	jalr	1836(ra) # 80000d6a <release>
}
    80003646:	854a                	mv	a0,s2
    80003648:	70a2                	ld	ra,40(sp)
    8000364a:	7402                	ld	s0,32(sp)
    8000364c:	64e2                	ld	s1,24(sp)
    8000364e:	6942                	ld	s2,16(sp)
    80003650:	69a2                	ld	s3,8(sp)
    80003652:	6a02                	ld	s4,0(sp)
    80003654:	6145                	addi	sp,sp,48
    80003656:	8082                	ret
    panic("iget: no inodes");
    80003658:	00005517          	auipc	a0,0x5
    8000365c:	f1850513          	addi	a0,a0,-232 # 80008570 <syscalls+0x168>
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	f92080e7          	jalr	-110(ra) # 800005f2 <panic>

0000000080003668 <fsinit>:
fsinit(int dev) {
    80003668:	7179                	addi	sp,sp,-48
    8000366a:	f406                	sd	ra,40(sp)
    8000366c:	f022                	sd	s0,32(sp)
    8000366e:	ec26                	sd	s1,24(sp)
    80003670:	e84a                	sd	s2,16(sp)
    80003672:	e44e                	sd	s3,8(sp)
    80003674:	1800                	addi	s0,sp,48
    80003676:	89aa                	mv	s3,a0
  bp = bread(dev, 1);
    80003678:	4585                	li	a1,1
    8000367a:	00000097          	auipc	ra,0x0
    8000367e:	a20080e7          	jalr	-1504(ra) # 8000309a <bread>
    80003682:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003684:	0001d497          	auipc	s1,0x1d
    80003688:	fbc48493          	addi	s1,s1,-68 # 80020640 <sb>
    8000368c:	02000613          	li	a2,32
    80003690:	05850593          	addi	a1,a0,88
    80003694:	8526                	mv	a0,s1
    80003696:	ffffd097          	auipc	ra,0xffffd
    8000369a:	788080e7          	jalr	1928(ra) # 80000e1e <memmove>
  brelse(bp);
    8000369e:	854a                	mv	a0,s2
    800036a0:	00000097          	auipc	ra,0x0
    800036a4:	b3c080e7          	jalr	-1220(ra) # 800031dc <brelse>
  if(sb.magic != FSMAGIC)
    800036a8:	4098                	lw	a4,0(s1)
    800036aa:	102037b7          	lui	a5,0x10203
    800036ae:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036b2:	02f71263          	bne	a4,a5,800036d6 <fsinit+0x6e>
  initlog(dev, &sb);
    800036b6:	0001d597          	auipc	a1,0x1d
    800036ba:	f8a58593          	addi	a1,a1,-118 # 80020640 <sb>
    800036be:	854e                	mv	a0,s3
    800036c0:	00001097          	auipc	ra,0x1
    800036c4:	b48080e7          	jalr	-1208(ra) # 80004208 <initlog>
}
    800036c8:	70a2                	ld	ra,40(sp)
    800036ca:	7402                	ld	s0,32(sp)
    800036cc:	64e2                	ld	s1,24(sp)
    800036ce:	6942                	ld	s2,16(sp)
    800036d0:	69a2                	ld	s3,8(sp)
    800036d2:	6145                	addi	sp,sp,48
    800036d4:	8082                	ret
    panic("invalid file system");
    800036d6:	00005517          	auipc	a0,0x5
    800036da:	eaa50513          	addi	a0,a0,-342 # 80008580 <syscalls+0x178>
    800036de:	ffffd097          	auipc	ra,0xffffd
    800036e2:	f14080e7          	jalr	-236(ra) # 800005f2 <panic>

00000000800036e6 <iinit>:
{
    800036e6:	7179                	addi	sp,sp,-48
    800036e8:	f406                	sd	ra,40(sp)
    800036ea:	f022                	sd	s0,32(sp)
    800036ec:	ec26                	sd	s1,24(sp)
    800036ee:	e84a                	sd	s2,16(sp)
    800036f0:	e44e                	sd	s3,8(sp)
    800036f2:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800036f4:	00005597          	auipc	a1,0x5
    800036f8:	ea458593          	addi	a1,a1,-348 # 80008598 <syscalls+0x190>
    800036fc:	0001d517          	auipc	a0,0x1d
    80003700:	f6450513          	addi	a0,a0,-156 # 80020660 <icache>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	522080e7          	jalr	1314(ra) # 80000c26 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000370c:	0001d497          	auipc	s1,0x1d
    80003710:	f7c48493          	addi	s1,s1,-132 # 80020688 <icache+0x28>
    80003714:	0001f997          	auipc	s3,0x1f
    80003718:	a0498993          	addi	s3,s3,-1532 # 80022118 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000371c:	00005917          	auipc	s2,0x5
    80003720:	e8490913          	addi	s2,s2,-380 # 800085a0 <syscalls+0x198>
    80003724:	85ca                	mv	a1,s2
    80003726:	8526                	mv	a0,s1
    80003728:	00001097          	auipc	ra,0x1
    8000372c:	e62080e7          	jalr	-414(ra) # 8000458a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003730:	08848493          	addi	s1,s1,136
    80003734:	ff3498e3          	bne	s1,s3,80003724 <iinit+0x3e>
}
    80003738:	70a2                	ld	ra,40(sp)
    8000373a:	7402                	ld	s0,32(sp)
    8000373c:	64e2                	ld	s1,24(sp)
    8000373e:	6942                	ld	s2,16(sp)
    80003740:	69a2                	ld	s3,8(sp)
    80003742:	6145                	addi	sp,sp,48
    80003744:	8082                	ret

0000000080003746 <ialloc>:
{
    80003746:	715d                	addi	sp,sp,-80
    80003748:	e486                	sd	ra,72(sp)
    8000374a:	e0a2                	sd	s0,64(sp)
    8000374c:	fc26                	sd	s1,56(sp)
    8000374e:	f84a                	sd	s2,48(sp)
    80003750:	f44e                	sd	s3,40(sp)
    80003752:	f052                	sd	s4,32(sp)
    80003754:	ec56                	sd	s5,24(sp)
    80003756:	e85a                	sd	s6,16(sp)
    80003758:	e45e                	sd	s7,8(sp)
    8000375a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000375c:	0001d797          	auipc	a5,0x1d
    80003760:	ee478793          	addi	a5,a5,-284 # 80020640 <sb>
    80003764:	47d8                	lw	a4,12(a5)
    80003766:	4785                	li	a5,1
    80003768:	04e7fa63          	bleu	a4,a5,800037bc <ialloc+0x76>
    8000376c:	8a2a                	mv	s4,a0
    8000376e:	8b2e                	mv	s6,a1
    80003770:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003772:	0001d997          	auipc	s3,0x1d
    80003776:	ece98993          	addi	s3,s3,-306 # 80020640 <sb>
    8000377a:	00048a9b          	sext.w	s5,s1
    8000377e:	0044d593          	srli	a1,s1,0x4
    80003782:	0189a783          	lw	a5,24(s3)
    80003786:	9dbd                	addw	a1,a1,a5
    80003788:	8552                	mv	a0,s4
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	910080e7          	jalr	-1776(ra) # 8000309a <bread>
    80003792:	8baa                	mv	s7,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003794:	05850913          	addi	s2,a0,88
    80003798:	00f4f793          	andi	a5,s1,15
    8000379c:	079a                	slli	a5,a5,0x6
    8000379e:	993e                	add	s2,s2,a5
    if(dip->type == 0){  // a free inode
    800037a0:	00091783          	lh	a5,0(s2)
    800037a4:	c785                	beqz	a5,800037cc <ialloc+0x86>
    brelse(bp);
    800037a6:	00000097          	auipc	ra,0x0
    800037aa:	a36080e7          	jalr	-1482(ra) # 800031dc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ae:	0485                	addi	s1,s1,1
    800037b0:	00c9a703          	lw	a4,12(s3)
    800037b4:	0004879b          	sext.w	a5,s1
    800037b8:	fce7e1e3          	bltu	a5,a4,8000377a <ialloc+0x34>
  panic("ialloc: no inodes");
    800037bc:	00005517          	auipc	a0,0x5
    800037c0:	dec50513          	addi	a0,a0,-532 # 800085a8 <syscalls+0x1a0>
    800037c4:	ffffd097          	auipc	ra,0xffffd
    800037c8:	e2e080e7          	jalr	-466(ra) # 800005f2 <panic>
      memset(dip, 0, sizeof(*dip));
    800037cc:	04000613          	li	a2,64
    800037d0:	4581                	li	a1,0
    800037d2:	854a                	mv	a0,s2
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	5de080e7          	jalr	1502(ra) # 80000db2 <memset>
      dip->type = type;
    800037dc:	01691023          	sh	s6,0(s2)
      log_write(bp);   // mark it allocated on the disk
    800037e0:	855e                	mv	a0,s7
    800037e2:	00001097          	auipc	ra,0x1
    800037e6:	ca4080e7          	jalr	-860(ra) # 80004486 <log_write>
      brelse(bp);
    800037ea:	855e                	mv	a0,s7
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	9f0080e7          	jalr	-1552(ra) # 800031dc <brelse>
      return iget(dev, inum);
    800037f4:	85d6                	mv	a1,s5
    800037f6:	8552                	mv	a0,s4
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	db4080e7          	jalr	-588(ra) # 800035ac <iget>
}
    80003800:	60a6                	ld	ra,72(sp)
    80003802:	6406                	ld	s0,64(sp)
    80003804:	74e2                	ld	s1,56(sp)
    80003806:	7942                	ld	s2,48(sp)
    80003808:	79a2                	ld	s3,40(sp)
    8000380a:	7a02                	ld	s4,32(sp)
    8000380c:	6ae2                	ld	s5,24(sp)
    8000380e:	6b42                	ld	s6,16(sp)
    80003810:	6ba2                	ld	s7,8(sp)
    80003812:	6161                	addi	sp,sp,80
    80003814:	8082                	ret

0000000080003816 <iupdate>:
{
    80003816:	1101                	addi	sp,sp,-32
    80003818:	ec06                	sd	ra,24(sp)
    8000381a:	e822                	sd	s0,16(sp)
    8000381c:	e426                	sd	s1,8(sp)
    8000381e:	e04a                	sd	s2,0(sp)
    80003820:	1000                	addi	s0,sp,32
    80003822:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003824:	415c                	lw	a5,4(a0)
    80003826:	0047d79b          	srliw	a5,a5,0x4
    8000382a:	0001d717          	auipc	a4,0x1d
    8000382e:	e1670713          	addi	a4,a4,-490 # 80020640 <sb>
    80003832:	4f0c                	lw	a1,24(a4)
    80003834:	9dbd                	addw	a1,a1,a5
    80003836:	4108                	lw	a0,0(a0)
    80003838:	00000097          	auipc	ra,0x0
    8000383c:	862080e7          	jalr	-1950(ra) # 8000309a <bread>
    80003840:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003842:	05850513          	addi	a0,a0,88
    80003846:	40dc                	lw	a5,4(s1)
    80003848:	8bbd                	andi	a5,a5,15
    8000384a:	079a                	slli	a5,a5,0x6
    8000384c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000384e:	04449783          	lh	a5,68(s1)
    80003852:	00f51023          	sh	a5,0(a0)
  dip->major = ip->major;
    80003856:	04649783          	lh	a5,70(s1)
    8000385a:	00f51123          	sh	a5,2(a0)
  dip->minor = ip->minor;
    8000385e:	04849783          	lh	a5,72(s1)
    80003862:	00f51223          	sh	a5,4(a0)
  dip->nlink = ip->nlink;
    80003866:	04a49783          	lh	a5,74(s1)
    8000386a:	00f51323          	sh	a5,6(a0)
  dip->size = ip->size;
    8000386e:	44fc                	lw	a5,76(s1)
    80003870:	c51c                	sw	a5,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003872:	03400613          	li	a2,52
    80003876:	05048593          	addi	a1,s1,80
    8000387a:	0531                	addi	a0,a0,12
    8000387c:	ffffd097          	auipc	ra,0xffffd
    80003880:	5a2080e7          	jalr	1442(ra) # 80000e1e <memmove>
  log_write(bp);
    80003884:	854a                	mv	a0,s2
    80003886:	00001097          	auipc	ra,0x1
    8000388a:	c00080e7          	jalr	-1024(ra) # 80004486 <log_write>
  brelse(bp);
    8000388e:	854a                	mv	a0,s2
    80003890:	00000097          	auipc	ra,0x0
    80003894:	94c080e7          	jalr	-1716(ra) # 800031dc <brelse>
}
    80003898:	60e2                	ld	ra,24(sp)
    8000389a:	6442                	ld	s0,16(sp)
    8000389c:	64a2                	ld	s1,8(sp)
    8000389e:	6902                	ld	s2,0(sp)
    800038a0:	6105                	addi	sp,sp,32
    800038a2:	8082                	ret

00000000800038a4 <idup>:
{
    800038a4:	1101                	addi	sp,sp,-32
    800038a6:	ec06                	sd	ra,24(sp)
    800038a8:	e822                	sd	s0,16(sp)
    800038aa:	e426                	sd	s1,8(sp)
    800038ac:	1000                	addi	s0,sp,32
    800038ae:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800038b0:	0001d517          	auipc	a0,0x1d
    800038b4:	db050513          	addi	a0,a0,-592 # 80020660 <icache>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	3fe080e7          	jalr	1022(ra) # 80000cb6 <acquire>
  ip->ref++;
    800038c0:	449c                	lw	a5,8(s1)
    800038c2:	2785                	addiw	a5,a5,1
    800038c4:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800038c6:	0001d517          	auipc	a0,0x1d
    800038ca:	d9a50513          	addi	a0,a0,-614 # 80020660 <icache>
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	49c080e7          	jalr	1180(ra) # 80000d6a <release>
}
    800038d6:	8526                	mv	a0,s1
    800038d8:	60e2                	ld	ra,24(sp)
    800038da:	6442                	ld	s0,16(sp)
    800038dc:	64a2                	ld	s1,8(sp)
    800038de:	6105                	addi	sp,sp,32
    800038e0:	8082                	ret

00000000800038e2 <ilock>:
{
    800038e2:	1101                	addi	sp,sp,-32
    800038e4:	ec06                	sd	ra,24(sp)
    800038e6:	e822                	sd	s0,16(sp)
    800038e8:	e426                	sd	s1,8(sp)
    800038ea:	e04a                	sd	s2,0(sp)
    800038ec:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038ee:	c115                	beqz	a0,80003912 <ilock+0x30>
    800038f0:	84aa                	mv	s1,a0
    800038f2:	451c                	lw	a5,8(a0)
    800038f4:	00f05f63          	blez	a5,80003912 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038f8:	0541                	addi	a0,a0,16
    800038fa:	00001097          	auipc	ra,0x1
    800038fe:	cca080e7          	jalr	-822(ra) # 800045c4 <acquiresleep>
  if(ip->valid == 0){
    80003902:	40bc                	lw	a5,64(s1)
    80003904:	cf99                	beqz	a5,80003922 <ilock+0x40>
}
    80003906:	60e2                	ld	ra,24(sp)
    80003908:	6442                	ld	s0,16(sp)
    8000390a:	64a2                	ld	s1,8(sp)
    8000390c:	6902                	ld	s2,0(sp)
    8000390e:	6105                	addi	sp,sp,32
    80003910:	8082                	ret
    panic("ilock");
    80003912:	00005517          	auipc	a0,0x5
    80003916:	cae50513          	addi	a0,a0,-850 # 800085c0 <syscalls+0x1b8>
    8000391a:	ffffd097          	auipc	ra,0xffffd
    8000391e:	cd8080e7          	jalr	-808(ra) # 800005f2 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003922:	40dc                	lw	a5,4(s1)
    80003924:	0047d79b          	srliw	a5,a5,0x4
    80003928:	0001d717          	auipc	a4,0x1d
    8000392c:	d1870713          	addi	a4,a4,-744 # 80020640 <sb>
    80003930:	4f0c                	lw	a1,24(a4)
    80003932:	9dbd                	addw	a1,a1,a5
    80003934:	4088                	lw	a0,0(s1)
    80003936:	fffff097          	auipc	ra,0xfffff
    8000393a:	764080e7          	jalr	1892(ra) # 8000309a <bread>
    8000393e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003940:	05850593          	addi	a1,a0,88
    80003944:	40dc                	lw	a5,4(s1)
    80003946:	8bbd                	andi	a5,a5,15
    80003948:	079a                	slli	a5,a5,0x6
    8000394a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000394c:	00059783          	lh	a5,0(a1)
    80003950:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003954:	00259783          	lh	a5,2(a1)
    80003958:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000395c:	00459783          	lh	a5,4(a1)
    80003960:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003964:	00659783          	lh	a5,6(a1)
    80003968:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000396c:	459c                	lw	a5,8(a1)
    8000396e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003970:	03400613          	li	a2,52
    80003974:	05b1                	addi	a1,a1,12
    80003976:	05048513          	addi	a0,s1,80
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	4a4080e7          	jalr	1188(ra) # 80000e1e <memmove>
    brelse(bp);
    80003982:	854a                	mv	a0,s2
    80003984:	00000097          	auipc	ra,0x0
    80003988:	858080e7          	jalr	-1960(ra) # 800031dc <brelse>
    ip->valid = 1;
    8000398c:	4785                	li	a5,1
    8000398e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003990:	04449783          	lh	a5,68(s1)
    80003994:	fbad                	bnez	a5,80003906 <ilock+0x24>
      panic("ilock: no type");
    80003996:	00005517          	auipc	a0,0x5
    8000399a:	c3250513          	addi	a0,a0,-974 # 800085c8 <syscalls+0x1c0>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	c54080e7          	jalr	-940(ra) # 800005f2 <panic>

00000000800039a6 <iunlock>:
{
    800039a6:	1101                	addi	sp,sp,-32
    800039a8:	ec06                	sd	ra,24(sp)
    800039aa:	e822                	sd	s0,16(sp)
    800039ac:	e426                	sd	s1,8(sp)
    800039ae:	e04a                	sd	s2,0(sp)
    800039b0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039b2:	c905                	beqz	a0,800039e2 <iunlock+0x3c>
    800039b4:	84aa                	mv	s1,a0
    800039b6:	01050913          	addi	s2,a0,16
    800039ba:	854a                	mv	a0,s2
    800039bc:	00001097          	auipc	ra,0x1
    800039c0:	ca2080e7          	jalr	-862(ra) # 8000465e <holdingsleep>
    800039c4:	cd19                	beqz	a0,800039e2 <iunlock+0x3c>
    800039c6:	449c                	lw	a5,8(s1)
    800039c8:	00f05d63          	blez	a5,800039e2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039cc:	854a                	mv	a0,s2
    800039ce:	00001097          	auipc	ra,0x1
    800039d2:	c4c080e7          	jalr	-948(ra) # 8000461a <releasesleep>
}
    800039d6:	60e2                	ld	ra,24(sp)
    800039d8:	6442                	ld	s0,16(sp)
    800039da:	64a2                	ld	s1,8(sp)
    800039dc:	6902                	ld	s2,0(sp)
    800039de:	6105                	addi	sp,sp,32
    800039e0:	8082                	ret
    panic("iunlock");
    800039e2:	00005517          	auipc	a0,0x5
    800039e6:	bf650513          	addi	a0,a0,-1034 # 800085d8 <syscalls+0x1d0>
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	c08080e7          	jalr	-1016(ra) # 800005f2 <panic>

00000000800039f2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039f2:	7179                	addi	sp,sp,-48
    800039f4:	f406                	sd	ra,40(sp)
    800039f6:	f022                	sd	s0,32(sp)
    800039f8:	ec26                	sd	s1,24(sp)
    800039fa:	e84a                	sd	s2,16(sp)
    800039fc:	e44e                	sd	s3,8(sp)
    800039fe:	e052                	sd	s4,0(sp)
    80003a00:	1800                	addi	s0,sp,48
    80003a02:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a04:	05050493          	addi	s1,a0,80
    80003a08:	08050913          	addi	s2,a0,128
    80003a0c:	a821                	j	80003a24 <itrunc+0x32>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    80003a0e:	0009a503          	lw	a0,0(s3)
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	8e0080e7          	jalr	-1824(ra) # 800032f2 <bfree>
      ip->addrs[i] = 0;
    80003a1a:	0004a023          	sw	zero,0(s1)
  for(i = 0; i < NDIRECT; i++){
    80003a1e:	0491                	addi	s1,s1,4
    80003a20:	01248563          	beq	s1,s2,80003a2a <itrunc+0x38>
    if(ip->addrs[i]){
    80003a24:	408c                	lw	a1,0(s1)
    80003a26:	dde5                	beqz	a1,80003a1e <itrunc+0x2c>
    80003a28:	b7dd                	j	80003a0e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a2a:	0809a583          	lw	a1,128(s3)
    80003a2e:	e185                	bnez	a1,80003a4e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a30:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a34:	854e                	mv	a0,s3
    80003a36:	00000097          	auipc	ra,0x0
    80003a3a:	de0080e7          	jalr	-544(ra) # 80003816 <iupdate>
}
    80003a3e:	70a2                	ld	ra,40(sp)
    80003a40:	7402                	ld	s0,32(sp)
    80003a42:	64e2                	ld	s1,24(sp)
    80003a44:	6942                	ld	s2,16(sp)
    80003a46:	69a2                	ld	s3,8(sp)
    80003a48:	6a02                	ld	s4,0(sp)
    80003a4a:	6145                	addi	sp,sp,48
    80003a4c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a4e:	0009a503          	lw	a0,0(s3)
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	648080e7          	jalr	1608(ra) # 8000309a <bread>
    80003a5a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a5c:	05850493          	addi	s1,a0,88
    80003a60:	45850913          	addi	s2,a0,1112
    80003a64:	a811                	j	80003a78 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a66:	0009a503          	lw	a0,0(s3)
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	888080e7          	jalr	-1912(ra) # 800032f2 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a72:	0491                	addi	s1,s1,4
    80003a74:	01248563          	beq	s1,s2,80003a7e <itrunc+0x8c>
      if(a[j])
    80003a78:	408c                	lw	a1,0(s1)
    80003a7a:	dde5                	beqz	a1,80003a72 <itrunc+0x80>
    80003a7c:	b7ed                	j	80003a66 <itrunc+0x74>
    brelse(bp);
    80003a7e:	8552                	mv	a0,s4
    80003a80:	fffff097          	auipc	ra,0xfffff
    80003a84:	75c080e7          	jalr	1884(ra) # 800031dc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a88:	0809a583          	lw	a1,128(s3)
    80003a8c:	0009a503          	lw	a0,0(s3)
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	862080e7          	jalr	-1950(ra) # 800032f2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a98:	0809a023          	sw	zero,128(s3)
    80003a9c:	bf51                	j	80003a30 <itrunc+0x3e>

0000000080003a9e <iput>:
{
    80003a9e:	1101                	addi	sp,sp,-32
    80003aa0:	ec06                	sd	ra,24(sp)
    80003aa2:	e822                	sd	s0,16(sp)
    80003aa4:	e426                	sd	s1,8(sp)
    80003aa6:	e04a                	sd	s2,0(sp)
    80003aa8:	1000                	addi	s0,sp,32
    80003aaa:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003aac:	0001d517          	auipc	a0,0x1d
    80003ab0:	bb450513          	addi	a0,a0,-1100 # 80020660 <icache>
    80003ab4:	ffffd097          	auipc	ra,0xffffd
    80003ab8:	202080e7          	jalr	514(ra) # 80000cb6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003abc:	4498                	lw	a4,8(s1)
    80003abe:	4785                	li	a5,1
    80003ac0:	02f70363          	beq	a4,a5,80003ae6 <iput+0x48>
  ip->ref--;
    80003ac4:	449c                	lw	a5,8(s1)
    80003ac6:	37fd                	addiw	a5,a5,-1
    80003ac8:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003aca:	0001d517          	auipc	a0,0x1d
    80003ace:	b9650513          	addi	a0,a0,-1130 # 80020660 <icache>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	298080e7          	jalr	664(ra) # 80000d6a <release>
}
    80003ada:	60e2                	ld	ra,24(sp)
    80003adc:	6442                	ld	s0,16(sp)
    80003ade:	64a2                	ld	s1,8(sp)
    80003ae0:	6902                	ld	s2,0(sp)
    80003ae2:	6105                	addi	sp,sp,32
    80003ae4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ae6:	40bc                	lw	a5,64(s1)
    80003ae8:	dff1                	beqz	a5,80003ac4 <iput+0x26>
    80003aea:	04a49783          	lh	a5,74(s1)
    80003aee:	fbf9                	bnez	a5,80003ac4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003af0:	01048913          	addi	s2,s1,16
    80003af4:	854a                	mv	a0,s2
    80003af6:	00001097          	auipc	ra,0x1
    80003afa:	ace080e7          	jalr	-1330(ra) # 800045c4 <acquiresleep>
    release(&icache.lock);
    80003afe:	0001d517          	auipc	a0,0x1d
    80003b02:	b6250513          	addi	a0,a0,-1182 # 80020660 <icache>
    80003b06:	ffffd097          	auipc	ra,0xffffd
    80003b0a:	264080e7          	jalr	612(ra) # 80000d6a <release>
    itrunc(ip);
    80003b0e:	8526                	mv	a0,s1
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	ee2080e7          	jalr	-286(ra) # 800039f2 <itrunc>
    ip->type = 0;
    80003b18:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b1c:	8526                	mv	a0,s1
    80003b1e:	00000097          	auipc	ra,0x0
    80003b22:	cf8080e7          	jalr	-776(ra) # 80003816 <iupdate>
    ip->valid = 0;
    80003b26:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b2a:	854a                	mv	a0,s2
    80003b2c:	00001097          	auipc	ra,0x1
    80003b30:	aee080e7          	jalr	-1298(ra) # 8000461a <releasesleep>
    acquire(&icache.lock);
    80003b34:	0001d517          	auipc	a0,0x1d
    80003b38:	b2c50513          	addi	a0,a0,-1236 # 80020660 <icache>
    80003b3c:	ffffd097          	auipc	ra,0xffffd
    80003b40:	17a080e7          	jalr	378(ra) # 80000cb6 <acquire>
    80003b44:	b741                	j	80003ac4 <iput+0x26>

0000000080003b46 <iunlockput>:
{
    80003b46:	1101                	addi	sp,sp,-32
    80003b48:	ec06                	sd	ra,24(sp)
    80003b4a:	e822                	sd	s0,16(sp)
    80003b4c:	e426                	sd	s1,8(sp)
    80003b4e:	1000                	addi	s0,sp,32
    80003b50:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	e54080e7          	jalr	-428(ra) # 800039a6 <iunlock>
  iput(ip);
    80003b5a:	8526                	mv	a0,s1
    80003b5c:	00000097          	auipc	ra,0x0
    80003b60:	f42080e7          	jalr	-190(ra) # 80003a9e <iput>
}
    80003b64:	60e2                	ld	ra,24(sp)
    80003b66:	6442                	ld	s0,16(sp)
    80003b68:	64a2                	ld	s1,8(sp)
    80003b6a:	6105                	addi	sp,sp,32
    80003b6c:	8082                	ret

0000000080003b6e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b6e:	1141                	addi	sp,sp,-16
    80003b70:	e422                	sd	s0,8(sp)
    80003b72:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b74:	411c                	lw	a5,0(a0)
    80003b76:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b78:	415c                	lw	a5,4(a0)
    80003b7a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b7c:	04451783          	lh	a5,68(a0)
    80003b80:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b84:	04a51783          	lh	a5,74(a0)
    80003b88:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b8c:	04c56783          	lwu	a5,76(a0)
    80003b90:	e99c                	sd	a5,16(a1)
}
    80003b92:	6422                	ld	s0,8(sp)
    80003b94:	0141                	addi	sp,sp,16
    80003b96:	8082                	ret

0000000080003b98 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b98:	457c                	lw	a5,76(a0)
    80003b9a:	0ed7e863          	bltu	a5,a3,80003c8a <readi+0xf2>
{
    80003b9e:	7159                	addi	sp,sp,-112
    80003ba0:	f486                	sd	ra,104(sp)
    80003ba2:	f0a2                	sd	s0,96(sp)
    80003ba4:	eca6                	sd	s1,88(sp)
    80003ba6:	e8ca                	sd	s2,80(sp)
    80003ba8:	e4ce                	sd	s3,72(sp)
    80003baa:	e0d2                	sd	s4,64(sp)
    80003bac:	fc56                	sd	s5,56(sp)
    80003bae:	f85a                	sd	s6,48(sp)
    80003bb0:	f45e                	sd	s7,40(sp)
    80003bb2:	f062                	sd	s8,32(sp)
    80003bb4:	ec66                	sd	s9,24(sp)
    80003bb6:	e86a                	sd	s10,16(sp)
    80003bb8:	e46e                	sd	s11,8(sp)
    80003bba:	1880                	addi	s0,sp,112
    80003bbc:	8baa                	mv	s7,a0
    80003bbe:	8c2e                	mv	s8,a1
    80003bc0:	8a32                	mv	s4,a2
    80003bc2:	84b6                	mv	s1,a3
    80003bc4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bc6:	9f35                	addw	a4,a4,a3
    return 0;
    80003bc8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bca:	08d76f63          	bltu	a4,a3,80003c68 <readi+0xd0>
  if(off + n > ip->size)
    80003bce:	00e7f463          	bleu	a4,a5,80003bd6 <readi+0x3e>
    n = ip->size - off;
    80003bd2:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bd6:	0a0b0863          	beqz	s6,80003c86 <readi+0xee>
    80003bda:	4901                	li	s2,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bdc:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003be0:	5cfd                	li	s9,-1
    80003be2:	a82d                	j	80003c1c <readi+0x84>
    80003be4:	02099d93          	slli	s11,s3,0x20
    80003be8:	020ddd93          	srli	s11,s11,0x20
    80003bec:	058a8613          	addi	a2,s5,88
    80003bf0:	86ee                	mv	a3,s11
    80003bf2:	963a                	add	a2,a2,a4
    80003bf4:	85d2                	mv	a1,s4
    80003bf6:	8562                	mv	a0,s8
    80003bf8:	fffff097          	auipc	ra,0xfffff
    80003bfc:	9c8080e7          	jalr	-1592(ra) # 800025c0 <either_copyout>
    80003c00:	05950d63          	beq	a0,s9,80003c5a <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003c04:	8556                	mv	a0,s5
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	5d6080e7          	jalr	1494(ra) # 800031dc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c0e:	0129893b          	addw	s2,s3,s2
    80003c12:	009984bb          	addw	s1,s3,s1
    80003c16:	9a6e                	add	s4,s4,s11
    80003c18:	05697663          	bleu	s6,s2,80003c64 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c1c:	000ba983          	lw	s3,0(s7)
    80003c20:	00a4d59b          	srliw	a1,s1,0xa
    80003c24:	855e                	mv	a0,s7
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	8ac080e7          	jalr	-1876(ra) # 800034d2 <bmap>
    80003c2e:	0005059b          	sext.w	a1,a0
    80003c32:	854e                	mv	a0,s3
    80003c34:	fffff097          	auipc	ra,0xfffff
    80003c38:	466080e7          	jalr	1126(ra) # 8000309a <bread>
    80003c3c:	8aaa                	mv	s5,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c3e:	3ff4f713          	andi	a4,s1,1023
    80003c42:	40ed07bb          	subw	a5,s10,a4
    80003c46:	412b06bb          	subw	a3,s6,s2
    80003c4a:	89be                	mv	s3,a5
    80003c4c:	2781                	sext.w	a5,a5
    80003c4e:	0006861b          	sext.w	a2,a3
    80003c52:	f8f679e3          	bleu	a5,a2,80003be4 <readi+0x4c>
    80003c56:	89b6                	mv	s3,a3
    80003c58:	b771                	j	80003be4 <readi+0x4c>
      brelse(bp);
    80003c5a:	8556                	mv	a0,s5
    80003c5c:	fffff097          	auipc	ra,0xfffff
    80003c60:	580080e7          	jalr	1408(ra) # 800031dc <brelse>
  }
  return tot;
    80003c64:	0009051b          	sext.w	a0,s2
}
    80003c68:	70a6                	ld	ra,104(sp)
    80003c6a:	7406                	ld	s0,96(sp)
    80003c6c:	64e6                	ld	s1,88(sp)
    80003c6e:	6946                	ld	s2,80(sp)
    80003c70:	69a6                	ld	s3,72(sp)
    80003c72:	6a06                	ld	s4,64(sp)
    80003c74:	7ae2                	ld	s5,56(sp)
    80003c76:	7b42                	ld	s6,48(sp)
    80003c78:	7ba2                	ld	s7,40(sp)
    80003c7a:	7c02                	ld	s8,32(sp)
    80003c7c:	6ce2                	ld	s9,24(sp)
    80003c7e:	6d42                	ld	s10,16(sp)
    80003c80:	6da2                	ld	s11,8(sp)
    80003c82:	6165                	addi	sp,sp,112
    80003c84:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c86:	895a                	mv	s2,s6
    80003c88:	bff1                	j	80003c64 <readi+0xcc>
    return 0;
    80003c8a:	4501                	li	a0,0
}
    80003c8c:	8082                	ret

0000000080003c8e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c8e:	457c                	lw	a5,76(a0)
    80003c90:	10d7e663          	bltu	a5,a3,80003d9c <writei+0x10e>
{
    80003c94:	7159                	addi	sp,sp,-112
    80003c96:	f486                	sd	ra,104(sp)
    80003c98:	f0a2                	sd	s0,96(sp)
    80003c9a:	eca6                	sd	s1,88(sp)
    80003c9c:	e8ca                	sd	s2,80(sp)
    80003c9e:	e4ce                	sd	s3,72(sp)
    80003ca0:	e0d2                	sd	s4,64(sp)
    80003ca2:	fc56                	sd	s5,56(sp)
    80003ca4:	f85a                	sd	s6,48(sp)
    80003ca6:	f45e                	sd	s7,40(sp)
    80003ca8:	f062                	sd	s8,32(sp)
    80003caa:	ec66                	sd	s9,24(sp)
    80003cac:	e86a                	sd	s10,16(sp)
    80003cae:	e46e                	sd	s11,8(sp)
    80003cb0:	1880                	addi	s0,sp,112
    80003cb2:	8baa                	mv	s7,a0
    80003cb4:	8c2e                	mv	s8,a1
    80003cb6:	8ab2                	mv	s5,a2
    80003cb8:	84b6                	mv	s1,a3
    80003cba:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cbc:	00e687bb          	addw	a5,a3,a4
    80003cc0:	0ed7e063          	bltu	a5,a3,80003da0 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cc4:	00043737          	lui	a4,0x43
    80003cc8:	0cf76e63          	bltu	a4,a5,80003da4 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ccc:	0a0b0763          	beqz	s6,80003d7a <writei+0xec>
    80003cd0:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd2:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cd6:	5cfd                	li	s9,-1
    80003cd8:	a091                	j	80003d1c <writei+0x8e>
    80003cda:	02091d93          	slli	s11,s2,0x20
    80003cde:	020ddd93          	srli	s11,s11,0x20
    80003ce2:	05898513          	addi	a0,s3,88
    80003ce6:	86ee                	mv	a3,s11
    80003ce8:	8656                	mv	a2,s5
    80003cea:	85e2                	mv	a1,s8
    80003cec:	953a                	add	a0,a0,a4
    80003cee:	fffff097          	auipc	ra,0xfffff
    80003cf2:	928080e7          	jalr	-1752(ra) # 80002616 <either_copyin>
    80003cf6:	07950263          	beq	a0,s9,80003d5a <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cfa:	854e                	mv	a0,s3
    80003cfc:	00000097          	auipc	ra,0x0
    80003d00:	78a080e7          	jalr	1930(ra) # 80004486 <log_write>
    brelse(bp);
    80003d04:	854e                	mv	a0,s3
    80003d06:	fffff097          	auipc	ra,0xfffff
    80003d0a:	4d6080e7          	jalr	1238(ra) # 800031dc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d0e:	01490a3b          	addw	s4,s2,s4
    80003d12:	009904bb          	addw	s1,s2,s1
    80003d16:	9aee                	add	s5,s5,s11
    80003d18:	056a7663          	bleu	s6,s4,80003d64 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d1c:	000ba903          	lw	s2,0(s7)
    80003d20:	00a4d59b          	srliw	a1,s1,0xa
    80003d24:	855e                	mv	a0,s7
    80003d26:	fffff097          	auipc	ra,0xfffff
    80003d2a:	7ac080e7          	jalr	1964(ra) # 800034d2 <bmap>
    80003d2e:	0005059b          	sext.w	a1,a0
    80003d32:	854a                	mv	a0,s2
    80003d34:	fffff097          	auipc	ra,0xfffff
    80003d38:	366080e7          	jalr	870(ra) # 8000309a <bread>
    80003d3c:	89aa                	mv	s3,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3e:	3ff4f713          	andi	a4,s1,1023
    80003d42:	40ed07bb          	subw	a5,s10,a4
    80003d46:	414b06bb          	subw	a3,s6,s4
    80003d4a:	893e                	mv	s2,a5
    80003d4c:	2781                	sext.w	a5,a5
    80003d4e:	0006861b          	sext.w	a2,a3
    80003d52:	f8f674e3          	bleu	a5,a2,80003cda <writei+0x4c>
    80003d56:	8936                	mv	s2,a3
    80003d58:	b749                	j	80003cda <writei+0x4c>
      brelse(bp);
    80003d5a:	854e                	mv	a0,s3
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	480080e7          	jalr	1152(ra) # 800031dc <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003d64:	04cba783          	lw	a5,76(s7)
    80003d68:	0097f463          	bleu	s1,a5,80003d70 <writei+0xe2>
      ip->size = off;
    80003d6c:	049ba623          	sw	s1,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003d70:	855e                	mv	a0,s7
    80003d72:	00000097          	auipc	ra,0x0
    80003d76:	aa4080e7          	jalr	-1372(ra) # 80003816 <iupdate>
  }

  return n;
    80003d7a:	000b051b          	sext.w	a0,s6
}
    80003d7e:	70a6                	ld	ra,104(sp)
    80003d80:	7406                	ld	s0,96(sp)
    80003d82:	64e6                	ld	s1,88(sp)
    80003d84:	6946                	ld	s2,80(sp)
    80003d86:	69a6                	ld	s3,72(sp)
    80003d88:	6a06                	ld	s4,64(sp)
    80003d8a:	7ae2                	ld	s5,56(sp)
    80003d8c:	7b42                	ld	s6,48(sp)
    80003d8e:	7ba2                	ld	s7,40(sp)
    80003d90:	7c02                	ld	s8,32(sp)
    80003d92:	6ce2                	ld	s9,24(sp)
    80003d94:	6d42                	ld	s10,16(sp)
    80003d96:	6da2                	ld	s11,8(sp)
    80003d98:	6165                	addi	sp,sp,112
    80003d9a:	8082                	ret
    return -1;
    80003d9c:	557d                	li	a0,-1
}
    80003d9e:	8082                	ret
    return -1;
    80003da0:	557d                	li	a0,-1
    80003da2:	bff1                	j	80003d7e <writei+0xf0>
    return -1;
    80003da4:	557d                	li	a0,-1
    80003da6:	bfe1                	j	80003d7e <writei+0xf0>

0000000080003da8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003da8:	1141                	addi	sp,sp,-16
    80003daa:	e406                	sd	ra,8(sp)
    80003dac:	e022                	sd	s0,0(sp)
    80003dae:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003db0:	4639                	li	a2,14
    80003db2:	ffffd097          	auipc	ra,0xffffd
    80003db6:	0e8080e7          	jalr	232(ra) # 80000e9a <strncmp>
}
    80003dba:	60a2                	ld	ra,8(sp)
    80003dbc:	6402                	ld	s0,0(sp)
    80003dbe:	0141                	addi	sp,sp,16
    80003dc0:	8082                	ret

0000000080003dc2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dc2:	7139                	addi	sp,sp,-64
    80003dc4:	fc06                	sd	ra,56(sp)
    80003dc6:	f822                	sd	s0,48(sp)
    80003dc8:	f426                	sd	s1,40(sp)
    80003dca:	f04a                	sd	s2,32(sp)
    80003dcc:	ec4e                	sd	s3,24(sp)
    80003dce:	e852                	sd	s4,16(sp)
    80003dd0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dd2:	04451703          	lh	a4,68(a0)
    80003dd6:	4785                	li	a5,1
    80003dd8:	00f71a63          	bne	a4,a5,80003dec <dirlookup+0x2a>
    80003ddc:	892a                	mv	s2,a0
    80003dde:	89ae                	mv	s3,a1
    80003de0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de2:	457c                	lw	a5,76(a0)
    80003de4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003de6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003de8:	e79d                	bnez	a5,80003e16 <dirlookup+0x54>
    80003dea:	a8a5                	j	80003e62 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dec:	00004517          	auipc	a0,0x4
    80003df0:	7f450513          	addi	a0,a0,2036 # 800085e0 <syscalls+0x1d8>
    80003df4:	ffffc097          	auipc	ra,0xffffc
    80003df8:	7fe080e7          	jalr	2046(ra) # 800005f2 <panic>
      panic("dirlookup read");
    80003dfc:	00004517          	auipc	a0,0x4
    80003e00:	7fc50513          	addi	a0,a0,2044 # 800085f8 <syscalls+0x1f0>
    80003e04:	ffffc097          	auipc	ra,0xffffc
    80003e08:	7ee080e7          	jalr	2030(ra) # 800005f2 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e0c:	24c1                	addiw	s1,s1,16
    80003e0e:	04c92783          	lw	a5,76(s2)
    80003e12:	04f4f763          	bleu	a5,s1,80003e60 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e16:	4741                	li	a4,16
    80003e18:	86a6                	mv	a3,s1
    80003e1a:	fc040613          	addi	a2,s0,-64
    80003e1e:	4581                	li	a1,0
    80003e20:	854a                	mv	a0,s2
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	d76080e7          	jalr	-650(ra) # 80003b98 <readi>
    80003e2a:	47c1                	li	a5,16
    80003e2c:	fcf518e3          	bne	a0,a5,80003dfc <dirlookup+0x3a>
    if(de.inum == 0)
    80003e30:	fc045783          	lhu	a5,-64(s0)
    80003e34:	dfe1                	beqz	a5,80003e0c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e36:	fc240593          	addi	a1,s0,-62
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	f6c080e7          	jalr	-148(ra) # 80003da8 <namecmp>
    80003e44:	f561                	bnez	a0,80003e0c <dirlookup+0x4a>
      if(poff)
    80003e46:	000a0463          	beqz	s4,80003e4e <dirlookup+0x8c>
        *poff = off;
    80003e4a:	009a2023          	sw	s1,0(s4) # 2000 <_entry-0x7fffe000>
      return iget(dp->dev, inum);
    80003e4e:	fc045583          	lhu	a1,-64(s0)
    80003e52:	00092503          	lw	a0,0(s2)
    80003e56:	fffff097          	auipc	ra,0xfffff
    80003e5a:	756080e7          	jalr	1878(ra) # 800035ac <iget>
    80003e5e:	a011                	j	80003e62 <dirlookup+0xa0>
  return 0;
    80003e60:	4501                	li	a0,0
}
    80003e62:	70e2                	ld	ra,56(sp)
    80003e64:	7442                	ld	s0,48(sp)
    80003e66:	74a2                	ld	s1,40(sp)
    80003e68:	7902                	ld	s2,32(sp)
    80003e6a:	69e2                	ld	s3,24(sp)
    80003e6c:	6a42                	ld	s4,16(sp)
    80003e6e:	6121                	addi	sp,sp,64
    80003e70:	8082                	ret

0000000080003e72 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e72:	711d                	addi	sp,sp,-96
    80003e74:	ec86                	sd	ra,88(sp)
    80003e76:	e8a2                	sd	s0,80(sp)
    80003e78:	e4a6                	sd	s1,72(sp)
    80003e7a:	e0ca                	sd	s2,64(sp)
    80003e7c:	fc4e                	sd	s3,56(sp)
    80003e7e:	f852                	sd	s4,48(sp)
    80003e80:	f456                	sd	s5,40(sp)
    80003e82:	f05a                	sd	s6,32(sp)
    80003e84:	ec5e                	sd	s7,24(sp)
    80003e86:	e862                	sd	s8,16(sp)
    80003e88:	e466                	sd	s9,8(sp)
    80003e8a:	1080                	addi	s0,sp,96
    80003e8c:	84aa                	mv	s1,a0
    80003e8e:	8bae                	mv	s7,a1
    80003e90:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e92:	00054703          	lbu	a4,0(a0)
    80003e96:	02f00793          	li	a5,47
    80003e9a:	02f70363          	beq	a4,a5,80003ec0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e9e:	ffffe097          	auipc	ra,0xffffe
    80003ea2:	c26080e7          	jalr	-986(ra) # 80001ac4 <myproc>
    80003ea6:	15053503          	ld	a0,336(a0)
    80003eaa:	00000097          	auipc	ra,0x0
    80003eae:	9fa080e7          	jalr	-1542(ra) # 800038a4 <idup>
    80003eb2:	89aa                	mv	s3,a0
  while(*path == '/')
    80003eb4:	02f00913          	li	s2,47
  len = path - s;
    80003eb8:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003eba:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ebc:	4c05                	li	s8,1
    80003ebe:	a865                	j	80003f76 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ec0:	4585                	li	a1,1
    80003ec2:	4505                	li	a0,1
    80003ec4:	fffff097          	auipc	ra,0xfffff
    80003ec8:	6e8080e7          	jalr	1768(ra) # 800035ac <iget>
    80003ecc:	89aa                	mv	s3,a0
    80003ece:	b7dd                	j	80003eb4 <namex+0x42>
      iunlockput(ip);
    80003ed0:	854e                	mv	a0,s3
    80003ed2:	00000097          	auipc	ra,0x0
    80003ed6:	c74080e7          	jalr	-908(ra) # 80003b46 <iunlockput>
      return 0;
    80003eda:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003edc:	854e                	mv	a0,s3
    80003ede:	60e6                	ld	ra,88(sp)
    80003ee0:	6446                	ld	s0,80(sp)
    80003ee2:	64a6                	ld	s1,72(sp)
    80003ee4:	6906                	ld	s2,64(sp)
    80003ee6:	79e2                	ld	s3,56(sp)
    80003ee8:	7a42                	ld	s4,48(sp)
    80003eea:	7aa2                	ld	s5,40(sp)
    80003eec:	7b02                	ld	s6,32(sp)
    80003eee:	6be2                	ld	s7,24(sp)
    80003ef0:	6c42                	ld	s8,16(sp)
    80003ef2:	6ca2                	ld	s9,8(sp)
    80003ef4:	6125                	addi	sp,sp,96
    80003ef6:	8082                	ret
      iunlock(ip);
    80003ef8:	854e                	mv	a0,s3
    80003efa:	00000097          	auipc	ra,0x0
    80003efe:	aac080e7          	jalr	-1364(ra) # 800039a6 <iunlock>
      return ip;
    80003f02:	bfe9                	j	80003edc <namex+0x6a>
      iunlockput(ip);
    80003f04:	854e                	mv	a0,s3
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	c40080e7          	jalr	-960(ra) # 80003b46 <iunlockput>
      return 0;
    80003f0e:	89d2                	mv	s3,s4
    80003f10:	b7f1                	j	80003edc <namex+0x6a>
  len = path - s;
    80003f12:	40b48633          	sub	a2,s1,a1
    80003f16:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f1a:	094cd663          	ble	s4,s9,80003fa6 <namex+0x134>
    memmove(name, s, DIRSIZ);
    80003f1e:	4639                	li	a2,14
    80003f20:	8556                	mv	a0,s5
    80003f22:	ffffd097          	auipc	ra,0xffffd
    80003f26:	efc080e7          	jalr	-260(ra) # 80000e1e <memmove>
  while(*path == '/')
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	01279763          	bne	a5,s2,80003f3c <namex+0xca>
    path++;
    80003f32:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f34:	0004c783          	lbu	a5,0(s1)
    80003f38:	ff278de3          	beq	a5,s2,80003f32 <namex+0xc0>
    ilock(ip);
    80003f3c:	854e                	mv	a0,s3
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	9a4080e7          	jalr	-1628(ra) # 800038e2 <ilock>
    if(ip->type != T_DIR){
    80003f46:	04499783          	lh	a5,68(s3)
    80003f4a:	f98793e3          	bne	a5,s8,80003ed0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f4e:	000b8563          	beqz	s7,80003f58 <namex+0xe6>
    80003f52:	0004c783          	lbu	a5,0(s1)
    80003f56:	d3cd                	beqz	a5,80003ef8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f58:	865a                	mv	a2,s6
    80003f5a:	85d6                	mv	a1,s5
    80003f5c:	854e                	mv	a0,s3
    80003f5e:	00000097          	auipc	ra,0x0
    80003f62:	e64080e7          	jalr	-412(ra) # 80003dc2 <dirlookup>
    80003f66:	8a2a                	mv	s4,a0
    80003f68:	dd51                	beqz	a0,80003f04 <namex+0x92>
    iunlockput(ip);
    80003f6a:	854e                	mv	a0,s3
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	bda080e7          	jalr	-1062(ra) # 80003b46 <iunlockput>
    ip = next;
    80003f74:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f76:	0004c783          	lbu	a5,0(s1)
    80003f7a:	05279d63          	bne	a5,s2,80003fd4 <namex+0x162>
    path++;
    80003f7e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f80:	0004c783          	lbu	a5,0(s1)
    80003f84:	ff278de3          	beq	a5,s2,80003f7e <namex+0x10c>
  if(*path == 0)
    80003f88:	cf8d                	beqz	a5,80003fc2 <namex+0x150>
  while(*path != '/' && *path != 0)
    80003f8a:	01278b63          	beq	a5,s2,80003fa0 <namex+0x12e>
    80003f8e:	c795                	beqz	a5,80003fba <namex+0x148>
    path++;
    80003f90:	85a6                	mv	a1,s1
    path++;
    80003f92:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f94:	0004c783          	lbu	a5,0(s1)
    80003f98:	f7278de3          	beq	a5,s2,80003f12 <namex+0xa0>
    80003f9c:	fbfd                	bnez	a5,80003f92 <namex+0x120>
    80003f9e:	bf95                	j	80003f12 <namex+0xa0>
    80003fa0:	85a6                	mv	a1,s1
  len = path - s;
    80003fa2:	8a5a                	mv	s4,s6
    80003fa4:	865a                	mv	a2,s6
    memmove(name, s, len);
    80003fa6:	2601                	sext.w	a2,a2
    80003fa8:	8556                	mv	a0,s5
    80003faa:	ffffd097          	auipc	ra,0xffffd
    80003fae:	e74080e7          	jalr	-396(ra) # 80000e1e <memmove>
    name[len] = 0;
    80003fb2:	9a56                	add	s4,s4,s5
    80003fb4:	000a0023          	sb	zero,0(s4)
    80003fb8:	bf8d                	j	80003f2a <namex+0xb8>
  while(*path != '/' && *path != 0)
    80003fba:	85a6                	mv	a1,s1
  len = path - s;
    80003fbc:	8a5a                	mv	s4,s6
    80003fbe:	865a                	mv	a2,s6
    80003fc0:	b7dd                	j	80003fa6 <namex+0x134>
  if(nameiparent){
    80003fc2:	f00b8de3          	beqz	s7,80003edc <namex+0x6a>
    iput(ip);
    80003fc6:	854e                	mv	a0,s3
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	ad6080e7          	jalr	-1322(ra) # 80003a9e <iput>
    return 0;
    80003fd0:	4981                	li	s3,0
    80003fd2:	b729                	j	80003edc <namex+0x6a>
  if(*path == 0)
    80003fd4:	d7fd                	beqz	a5,80003fc2 <namex+0x150>
    80003fd6:	85a6                	mv	a1,s1
    80003fd8:	bf6d                	j	80003f92 <namex+0x120>

0000000080003fda <dirlink>:
{
    80003fda:	7139                	addi	sp,sp,-64
    80003fdc:	fc06                	sd	ra,56(sp)
    80003fde:	f822                	sd	s0,48(sp)
    80003fe0:	f426                	sd	s1,40(sp)
    80003fe2:	f04a                	sd	s2,32(sp)
    80003fe4:	ec4e                	sd	s3,24(sp)
    80003fe6:	e852                	sd	s4,16(sp)
    80003fe8:	0080                	addi	s0,sp,64
    80003fea:	892a                	mv	s2,a0
    80003fec:	8a2e                	mv	s4,a1
    80003fee:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ff0:	4601                	li	a2,0
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	dd0080e7          	jalr	-560(ra) # 80003dc2 <dirlookup>
    80003ffa:	e93d                	bnez	a0,80004070 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ffc:	04c92483          	lw	s1,76(s2)
    80004000:	c49d                	beqz	s1,8000402e <dirlink+0x54>
    80004002:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004004:	4741                	li	a4,16
    80004006:	86a6                	mv	a3,s1
    80004008:	fc040613          	addi	a2,s0,-64
    8000400c:	4581                	li	a1,0
    8000400e:	854a                	mv	a0,s2
    80004010:	00000097          	auipc	ra,0x0
    80004014:	b88080e7          	jalr	-1144(ra) # 80003b98 <readi>
    80004018:	47c1                	li	a5,16
    8000401a:	06f51163          	bne	a0,a5,8000407c <dirlink+0xa2>
    if(de.inum == 0)
    8000401e:	fc045783          	lhu	a5,-64(s0)
    80004022:	c791                	beqz	a5,8000402e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004024:	24c1                	addiw	s1,s1,16
    80004026:	04c92783          	lw	a5,76(s2)
    8000402a:	fcf4ede3          	bltu	s1,a5,80004004 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000402e:	4639                	li	a2,14
    80004030:	85d2                	mv	a1,s4
    80004032:	fc240513          	addi	a0,s0,-62
    80004036:	ffffd097          	auipc	ra,0xffffd
    8000403a:	eb4080e7          	jalr	-332(ra) # 80000eea <strncpy>
  de.inum = inum;
    8000403e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004042:	4741                	li	a4,16
    80004044:	86a6                	mv	a3,s1
    80004046:	fc040613          	addi	a2,s0,-64
    8000404a:	4581                	li	a1,0
    8000404c:	854a                	mv	a0,s2
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	c40080e7          	jalr	-960(ra) # 80003c8e <writei>
    80004056:	4741                	li	a4,16
  return 0;
    80004058:	4781                	li	a5,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000405a:	02e51963          	bne	a0,a4,8000408c <dirlink+0xb2>
}
    8000405e:	853e                	mv	a0,a5
    80004060:	70e2                	ld	ra,56(sp)
    80004062:	7442                	ld	s0,48(sp)
    80004064:	74a2                	ld	s1,40(sp)
    80004066:	7902                	ld	s2,32(sp)
    80004068:	69e2                	ld	s3,24(sp)
    8000406a:	6a42                	ld	s4,16(sp)
    8000406c:	6121                	addi	sp,sp,64
    8000406e:	8082                	ret
    iput(ip);
    80004070:	00000097          	auipc	ra,0x0
    80004074:	a2e080e7          	jalr	-1490(ra) # 80003a9e <iput>
    return -1;
    80004078:	57fd                	li	a5,-1
    8000407a:	b7d5                	j	8000405e <dirlink+0x84>
      panic("dirlink read");
    8000407c:	00004517          	auipc	a0,0x4
    80004080:	58c50513          	addi	a0,a0,1420 # 80008608 <syscalls+0x200>
    80004084:	ffffc097          	auipc	ra,0xffffc
    80004088:	56e080e7          	jalr	1390(ra) # 800005f2 <panic>
    panic("dirlink");
    8000408c:	00004517          	auipc	a0,0x4
    80004090:	69c50513          	addi	a0,a0,1692 # 80008728 <syscalls+0x320>
    80004094:	ffffc097          	auipc	ra,0xffffc
    80004098:	55e080e7          	jalr	1374(ra) # 800005f2 <panic>

000000008000409c <namei>:

struct inode*
namei(char *path)
{
    8000409c:	1101                	addi	sp,sp,-32
    8000409e:	ec06                	sd	ra,24(sp)
    800040a0:	e822                	sd	s0,16(sp)
    800040a2:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040a4:	fe040613          	addi	a2,s0,-32
    800040a8:	4581                	li	a1,0
    800040aa:	00000097          	auipc	ra,0x0
    800040ae:	dc8080e7          	jalr	-568(ra) # 80003e72 <namex>
}
    800040b2:	60e2                	ld	ra,24(sp)
    800040b4:	6442                	ld	s0,16(sp)
    800040b6:	6105                	addi	sp,sp,32
    800040b8:	8082                	ret

00000000800040ba <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040ba:	1141                	addi	sp,sp,-16
    800040bc:	e406                	sd	ra,8(sp)
    800040be:	e022                	sd	s0,0(sp)
    800040c0:	0800                	addi	s0,sp,16
  return namex(path, 1, name);
    800040c2:	862e                	mv	a2,a1
    800040c4:	4585                	li	a1,1
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	dac080e7          	jalr	-596(ra) # 80003e72 <namex>
}
    800040ce:	60a2                	ld	ra,8(sp)
    800040d0:	6402                	ld	s0,0(sp)
    800040d2:	0141                	addi	sp,sp,16
    800040d4:	8082                	ret

00000000800040d6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040d6:	1101                	addi	sp,sp,-32
    800040d8:	ec06                	sd	ra,24(sp)
    800040da:	e822                	sd	s0,16(sp)
    800040dc:	e426                	sd	s1,8(sp)
    800040de:	e04a                	sd	s2,0(sp)
    800040e0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040e2:	0001e917          	auipc	s2,0x1e
    800040e6:	02690913          	addi	s2,s2,38 # 80022108 <log>
    800040ea:	01892583          	lw	a1,24(s2)
    800040ee:	02892503          	lw	a0,40(s2)
    800040f2:	fffff097          	auipc	ra,0xfffff
    800040f6:	fa8080e7          	jalr	-88(ra) # 8000309a <bread>
    800040fa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040fc:	02c92683          	lw	a3,44(s2)
    80004100:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004102:	02d05763          	blez	a3,80004130 <write_head+0x5a>
    80004106:	0001e797          	auipc	a5,0x1e
    8000410a:	03278793          	addi	a5,a5,50 # 80022138 <log+0x30>
    8000410e:	05c50713          	addi	a4,a0,92
    80004112:	36fd                	addiw	a3,a3,-1
    80004114:	1682                	slli	a3,a3,0x20
    80004116:	9281                	srli	a3,a3,0x20
    80004118:	068a                	slli	a3,a3,0x2
    8000411a:	0001e617          	auipc	a2,0x1e
    8000411e:	02260613          	addi	a2,a2,34 # 8002213c <log+0x34>
    80004122:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004124:	4390                	lw	a2,0(a5)
    80004126:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004128:	0791                	addi	a5,a5,4
    8000412a:	0711                	addi	a4,a4,4
    8000412c:	fed79ce3          	bne	a5,a3,80004124 <write_head+0x4e>
  }
  bwrite(buf);
    80004130:	8526                	mv	a0,s1
    80004132:	fffff097          	auipc	ra,0xfffff
    80004136:	06c080e7          	jalr	108(ra) # 8000319e <bwrite>
  brelse(buf);
    8000413a:	8526                	mv	a0,s1
    8000413c:	fffff097          	auipc	ra,0xfffff
    80004140:	0a0080e7          	jalr	160(ra) # 800031dc <brelse>
}
    80004144:	60e2                	ld	ra,24(sp)
    80004146:	6442                	ld	s0,16(sp)
    80004148:	64a2                	ld	s1,8(sp)
    8000414a:	6902                	ld	s2,0(sp)
    8000414c:	6105                	addi	sp,sp,32
    8000414e:	8082                	ret

0000000080004150 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004150:	0001e797          	auipc	a5,0x1e
    80004154:	fb878793          	addi	a5,a5,-72 # 80022108 <log>
    80004158:	57dc                	lw	a5,44(a5)
    8000415a:	0af05663          	blez	a5,80004206 <install_trans+0xb6>
{
    8000415e:	7139                	addi	sp,sp,-64
    80004160:	fc06                	sd	ra,56(sp)
    80004162:	f822                	sd	s0,48(sp)
    80004164:	f426                	sd	s1,40(sp)
    80004166:	f04a                	sd	s2,32(sp)
    80004168:	ec4e                	sd	s3,24(sp)
    8000416a:	e852                	sd	s4,16(sp)
    8000416c:	e456                	sd	s5,8(sp)
    8000416e:	0080                	addi	s0,sp,64
    80004170:	0001ea17          	auipc	s4,0x1e
    80004174:	fc8a0a13          	addi	s4,s4,-56 # 80022138 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004178:	4981                	li	s3,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000417a:	0001e917          	auipc	s2,0x1e
    8000417e:	f8e90913          	addi	s2,s2,-114 # 80022108 <log>
    80004182:	01892583          	lw	a1,24(s2)
    80004186:	013585bb          	addw	a1,a1,s3
    8000418a:	2585                	addiw	a1,a1,1
    8000418c:	02892503          	lw	a0,40(s2)
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	f0a080e7          	jalr	-246(ra) # 8000309a <bread>
    80004198:	8aaa                	mv	s5,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000419a:	000a2583          	lw	a1,0(s4)
    8000419e:	02892503          	lw	a0,40(s2)
    800041a2:	fffff097          	auipc	ra,0xfffff
    800041a6:	ef8080e7          	jalr	-264(ra) # 8000309a <bread>
    800041aa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041ac:	40000613          	li	a2,1024
    800041b0:	058a8593          	addi	a1,s5,88
    800041b4:	05850513          	addi	a0,a0,88
    800041b8:	ffffd097          	auipc	ra,0xffffd
    800041bc:	c66080e7          	jalr	-922(ra) # 80000e1e <memmove>
    bwrite(dbuf);  // write dst to disk
    800041c0:	8526                	mv	a0,s1
    800041c2:	fffff097          	auipc	ra,0xfffff
    800041c6:	fdc080e7          	jalr	-36(ra) # 8000319e <bwrite>
    bunpin(dbuf);
    800041ca:	8526                	mv	a0,s1
    800041cc:	fffff097          	auipc	ra,0xfffff
    800041d0:	0ea080e7          	jalr	234(ra) # 800032b6 <bunpin>
    brelse(lbuf);
    800041d4:	8556                	mv	a0,s5
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	006080e7          	jalr	6(ra) # 800031dc <brelse>
    brelse(dbuf);
    800041de:	8526                	mv	a0,s1
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	ffc080e7          	jalr	-4(ra) # 800031dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041e8:	2985                	addiw	s3,s3,1
    800041ea:	0a11                	addi	s4,s4,4
    800041ec:	02c92783          	lw	a5,44(s2)
    800041f0:	f8f9c9e3          	blt	s3,a5,80004182 <install_trans+0x32>
}
    800041f4:	70e2                	ld	ra,56(sp)
    800041f6:	7442                	ld	s0,48(sp)
    800041f8:	74a2                	ld	s1,40(sp)
    800041fa:	7902                	ld	s2,32(sp)
    800041fc:	69e2                	ld	s3,24(sp)
    800041fe:	6a42                	ld	s4,16(sp)
    80004200:	6aa2                	ld	s5,8(sp)
    80004202:	6121                	addi	sp,sp,64
    80004204:	8082                	ret
    80004206:	8082                	ret

0000000080004208 <initlog>:
{
    80004208:	7179                	addi	sp,sp,-48
    8000420a:	f406                	sd	ra,40(sp)
    8000420c:	f022                	sd	s0,32(sp)
    8000420e:	ec26                	sd	s1,24(sp)
    80004210:	e84a                	sd	s2,16(sp)
    80004212:	e44e                	sd	s3,8(sp)
    80004214:	1800                	addi	s0,sp,48
    80004216:	892a                	mv	s2,a0
    80004218:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000421a:	0001e497          	auipc	s1,0x1e
    8000421e:	eee48493          	addi	s1,s1,-274 # 80022108 <log>
    80004222:	00004597          	auipc	a1,0x4
    80004226:	3f658593          	addi	a1,a1,1014 # 80008618 <syscalls+0x210>
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	9fa080e7          	jalr	-1542(ra) # 80000c26 <initlock>
  log.start = sb->logstart;
    80004234:	0149a583          	lw	a1,20(s3)
    80004238:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000423a:	0109a783          	lw	a5,16(s3)
    8000423e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004240:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004244:	854a                	mv	a0,s2
    80004246:	fffff097          	auipc	ra,0xfffff
    8000424a:	e54080e7          	jalr	-428(ra) # 8000309a <bread>
  log.lh.n = lh->n;
    8000424e:	4d3c                	lw	a5,88(a0)
    80004250:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004252:	02f05563          	blez	a5,8000427c <initlog+0x74>
    80004256:	05c50713          	addi	a4,a0,92
    8000425a:	0001e697          	auipc	a3,0x1e
    8000425e:	ede68693          	addi	a3,a3,-290 # 80022138 <log+0x30>
    80004262:	37fd                	addiw	a5,a5,-1
    80004264:	1782                	slli	a5,a5,0x20
    80004266:	9381                	srli	a5,a5,0x20
    80004268:	078a                	slli	a5,a5,0x2
    8000426a:	06050613          	addi	a2,a0,96
    8000426e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004270:	4310                	lw	a2,0(a4)
    80004272:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004274:	0711                	addi	a4,a4,4
    80004276:	0691                	addi	a3,a3,4
    80004278:	fef71ce3          	bne	a4,a5,80004270 <initlog+0x68>
  brelse(buf);
    8000427c:	fffff097          	auipc	ra,0xfffff
    80004280:	f60080e7          	jalr	-160(ra) # 800031dc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004284:	00000097          	auipc	ra,0x0
    80004288:	ecc080e7          	jalr	-308(ra) # 80004150 <install_trans>
  log.lh.n = 0;
    8000428c:	0001e797          	auipc	a5,0x1e
    80004290:	ea07a423          	sw	zero,-344(a5) # 80022134 <log+0x2c>
  write_head(); // clear the log
    80004294:	00000097          	auipc	ra,0x0
    80004298:	e42080e7          	jalr	-446(ra) # 800040d6 <write_head>
}
    8000429c:	70a2                	ld	ra,40(sp)
    8000429e:	7402                	ld	s0,32(sp)
    800042a0:	64e2                	ld	s1,24(sp)
    800042a2:	6942                	ld	s2,16(sp)
    800042a4:	69a2                	ld	s3,8(sp)
    800042a6:	6145                	addi	sp,sp,48
    800042a8:	8082                	ret

00000000800042aa <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042aa:	1101                	addi	sp,sp,-32
    800042ac:	ec06                	sd	ra,24(sp)
    800042ae:	e822                	sd	s0,16(sp)
    800042b0:	e426                	sd	s1,8(sp)
    800042b2:	e04a                	sd	s2,0(sp)
    800042b4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042b6:	0001e517          	auipc	a0,0x1e
    800042ba:	e5250513          	addi	a0,a0,-430 # 80022108 <log>
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	9f8080e7          	jalr	-1544(ra) # 80000cb6 <acquire>
  while(1){
    if(log.committing){
    800042c6:	0001e497          	auipc	s1,0x1e
    800042ca:	e4248493          	addi	s1,s1,-446 # 80022108 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042ce:	4979                	li	s2,30
    800042d0:	a039                	j	800042de <begin_op+0x34>
      sleep(&log, &log.lock);
    800042d2:	85a6                	mv	a1,s1
    800042d4:	8526                	mv	a0,s1
    800042d6:	ffffe097          	auipc	ra,0xffffe
    800042da:	088080e7          	jalr	136(ra) # 8000235e <sleep>
    if(log.committing){
    800042de:	50dc                	lw	a5,36(s1)
    800042e0:	fbed                	bnez	a5,800042d2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042e2:	509c                	lw	a5,32(s1)
    800042e4:	0017871b          	addiw	a4,a5,1
    800042e8:	0007069b          	sext.w	a3,a4
    800042ec:	0027179b          	slliw	a5,a4,0x2
    800042f0:	9fb9                	addw	a5,a5,a4
    800042f2:	0017979b          	slliw	a5,a5,0x1
    800042f6:	54d8                	lw	a4,44(s1)
    800042f8:	9fb9                	addw	a5,a5,a4
    800042fa:	00f95963          	ble	a5,s2,8000430c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042fe:	85a6                	mv	a1,s1
    80004300:	8526                	mv	a0,s1
    80004302:	ffffe097          	auipc	ra,0xffffe
    80004306:	05c080e7          	jalr	92(ra) # 8000235e <sleep>
    8000430a:	bfd1                	j	800042de <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000430c:	0001e517          	auipc	a0,0x1e
    80004310:	dfc50513          	addi	a0,a0,-516 # 80022108 <log>
    80004314:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004316:	ffffd097          	auipc	ra,0xffffd
    8000431a:	a54080e7          	jalr	-1452(ra) # 80000d6a <release>
      break;
    }
  }
}
    8000431e:	60e2                	ld	ra,24(sp)
    80004320:	6442                	ld	s0,16(sp)
    80004322:	64a2                	ld	s1,8(sp)
    80004324:	6902                	ld	s2,0(sp)
    80004326:	6105                	addi	sp,sp,32
    80004328:	8082                	ret

000000008000432a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000432a:	7139                	addi	sp,sp,-64
    8000432c:	fc06                	sd	ra,56(sp)
    8000432e:	f822                	sd	s0,48(sp)
    80004330:	f426                	sd	s1,40(sp)
    80004332:	f04a                	sd	s2,32(sp)
    80004334:	ec4e                	sd	s3,24(sp)
    80004336:	e852                	sd	s4,16(sp)
    80004338:	e456                	sd	s5,8(sp)
    8000433a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000433c:	0001e917          	auipc	s2,0x1e
    80004340:	dcc90913          	addi	s2,s2,-564 # 80022108 <log>
    80004344:	854a                	mv	a0,s2
    80004346:	ffffd097          	auipc	ra,0xffffd
    8000434a:	970080e7          	jalr	-1680(ra) # 80000cb6 <acquire>
  log.outstanding -= 1;
    8000434e:	02092783          	lw	a5,32(s2)
    80004352:	37fd                	addiw	a5,a5,-1
    80004354:	0007849b          	sext.w	s1,a5
    80004358:	02f92023          	sw	a5,32(s2)
  if(log.committing)
    8000435c:	02492783          	lw	a5,36(s2)
    80004360:	eba1                	bnez	a5,800043b0 <end_op+0x86>
    panic("log.committing");
  if(log.outstanding == 0){
    80004362:	ecb9                	bnez	s1,800043c0 <end_op+0x96>
    do_commit = 1;
    log.committing = 1;
    80004364:	0001e917          	auipc	s2,0x1e
    80004368:	da490913          	addi	s2,s2,-604 # 80022108 <log>
    8000436c:	4785                	li	a5,1
    8000436e:	02f92223          	sw	a5,36(s2)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004372:	854a                	mv	a0,s2
    80004374:	ffffd097          	auipc	ra,0xffffd
    80004378:	9f6080e7          	jalr	-1546(ra) # 80000d6a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000437c:	02c92783          	lw	a5,44(s2)
    80004380:	06f04763          	bgtz	a5,800043ee <end_op+0xc4>
    acquire(&log.lock);
    80004384:	0001e497          	auipc	s1,0x1e
    80004388:	d8448493          	addi	s1,s1,-636 # 80022108 <log>
    8000438c:	8526                	mv	a0,s1
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	928080e7          	jalr	-1752(ra) # 80000cb6 <acquire>
    log.committing = 0;
    80004396:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000439a:	8526                	mv	a0,s1
    8000439c:	ffffe097          	auipc	ra,0xffffe
    800043a0:	148080e7          	jalr	328(ra) # 800024e4 <wakeup>
    release(&log.lock);
    800043a4:	8526                	mv	a0,s1
    800043a6:	ffffd097          	auipc	ra,0xffffd
    800043aa:	9c4080e7          	jalr	-1596(ra) # 80000d6a <release>
}
    800043ae:	a03d                	j	800043dc <end_op+0xb2>
    panic("log.committing");
    800043b0:	00004517          	auipc	a0,0x4
    800043b4:	27050513          	addi	a0,a0,624 # 80008620 <syscalls+0x218>
    800043b8:	ffffc097          	auipc	ra,0xffffc
    800043bc:	23a080e7          	jalr	570(ra) # 800005f2 <panic>
    wakeup(&log);
    800043c0:	0001e497          	auipc	s1,0x1e
    800043c4:	d4848493          	addi	s1,s1,-696 # 80022108 <log>
    800043c8:	8526                	mv	a0,s1
    800043ca:	ffffe097          	auipc	ra,0xffffe
    800043ce:	11a080e7          	jalr	282(ra) # 800024e4 <wakeup>
  release(&log.lock);
    800043d2:	8526                	mv	a0,s1
    800043d4:	ffffd097          	auipc	ra,0xffffd
    800043d8:	996080e7          	jalr	-1642(ra) # 80000d6a <release>
}
    800043dc:	70e2                	ld	ra,56(sp)
    800043de:	7442                	ld	s0,48(sp)
    800043e0:	74a2                	ld	s1,40(sp)
    800043e2:	7902                	ld	s2,32(sp)
    800043e4:	69e2                	ld	s3,24(sp)
    800043e6:	6a42                	ld	s4,16(sp)
    800043e8:	6aa2                	ld	s5,8(sp)
    800043ea:	6121                	addi	sp,sp,64
    800043ec:	8082                	ret
    800043ee:	0001ea17          	auipc	s4,0x1e
    800043f2:	d4aa0a13          	addi	s4,s4,-694 # 80022138 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043f6:	0001e917          	auipc	s2,0x1e
    800043fa:	d1290913          	addi	s2,s2,-750 # 80022108 <log>
    800043fe:	01892583          	lw	a1,24(s2)
    80004402:	9da5                	addw	a1,a1,s1
    80004404:	2585                	addiw	a1,a1,1
    80004406:	02892503          	lw	a0,40(s2)
    8000440a:	fffff097          	auipc	ra,0xfffff
    8000440e:	c90080e7          	jalr	-880(ra) # 8000309a <bread>
    80004412:	89aa                	mv	s3,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004414:	000a2583          	lw	a1,0(s4)
    80004418:	02892503          	lw	a0,40(s2)
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	c7e080e7          	jalr	-898(ra) # 8000309a <bread>
    80004424:	8aaa                	mv	s5,a0
    memmove(to->data, from->data, BSIZE);
    80004426:	40000613          	li	a2,1024
    8000442a:	05850593          	addi	a1,a0,88
    8000442e:	05898513          	addi	a0,s3,88
    80004432:	ffffd097          	auipc	ra,0xffffd
    80004436:	9ec080e7          	jalr	-1556(ra) # 80000e1e <memmove>
    bwrite(to);  // write the log
    8000443a:	854e                	mv	a0,s3
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	d62080e7          	jalr	-670(ra) # 8000319e <bwrite>
    brelse(from);
    80004444:	8556                	mv	a0,s5
    80004446:	fffff097          	auipc	ra,0xfffff
    8000444a:	d96080e7          	jalr	-618(ra) # 800031dc <brelse>
    brelse(to);
    8000444e:	854e                	mv	a0,s3
    80004450:	fffff097          	auipc	ra,0xfffff
    80004454:	d8c080e7          	jalr	-628(ra) # 800031dc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004458:	2485                	addiw	s1,s1,1
    8000445a:	0a11                	addi	s4,s4,4
    8000445c:	02c92783          	lw	a5,44(s2)
    80004460:	f8f4cfe3          	blt	s1,a5,800043fe <end_op+0xd4>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004464:	00000097          	auipc	ra,0x0
    80004468:	c72080e7          	jalr	-910(ra) # 800040d6 <write_head>
    install_trans(); // Now install writes to home locations
    8000446c:	00000097          	auipc	ra,0x0
    80004470:	ce4080e7          	jalr	-796(ra) # 80004150 <install_trans>
    log.lh.n = 0;
    80004474:	0001e797          	auipc	a5,0x1e
    80004478:	cc07a023          	sw	zero,-832(a5) # 80022134 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000447c:	00000097          	auipc	ra,0x0
    80004480:	c5a080e7          	jalr	-934(ra) # 800040d6 <write_head>
    80004484:	b701                	j	80004384 <end_op+0x5a>

0000000080004486 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004486:	1101                	addi	sp,sp,-32
    80004488:	ec06                	sd	ra,24(sp)
    8000448a:	e822                	sd	s0,16(sp)
    8000448c:	e426                	sd	s1,8(sp)
    8000448e:	e04a                	sd	s2,0(sp)
    80004490:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004492:	0001e797          	auipc	a5,0x1e
    80004496:	c7678793          	addi	a5,a5,-906 # 80022108 <log>
    8000449a:	57d8                	lw	a4,44(a5)
    8000449c:	47f5                	li	a5,29
    8000449e:	08e7c563          	blt	a5,a4,80004528 <log_write+0xa2>
    800044a2:	892a                	mv	s2,a0
    800044a4:	0001e797          	auipc	a5,0x1e
    800044a8:	c6478793          	addi	a5,a5,-924 # 80022108 <log>
    800044ac:	4fdc                	lw	a5,28(a5)
    800044ae:	37fd                	addiw	a5,a5,-1
    800044b0:	06f75c63          	ble	a5,a4,80004528 <log_write+0xa2>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044b4:	0001e797          	auipc	a5,0x1e
    800044b8:	c5478793          	addi	a5,a5,-940 # 80022108 <log>
    800044bc:	539c                	lw	a5,32(a5)
    800044be:	06f05d63          	blez	a5,80004538 <log_write+0xb2>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800044c2:	0001e497          	auipc	s1,0x1e
    800044c6:	c4648493          	addi	s1,s1,-954 # 80022108 <log>
    800044ca:	8526                	mv	a0,s1
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	7ea080e7          	jalr	2026(ra) # 80000cb6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800044d4:	54d0                	lw	a2,44(s1)
    800044d6:	0ac05063          	blez	a2,80004576 <log_write+0xf0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044da:	00c92583          	lw	a1,12(s2)
    800044de:	589c                	lw	a5,48(s1)
    800044e0:	0ab78363          	beq	a5,a1,80004586 <log_write+0x100>
    800044e4:	0001e717          	auipc	a4,0x1e
    800044e8:	c5870713          	addi	a4,a4,-936 # 8002213c <log+0x34>
  for (i = 0; i < log.lh.n; i++) {
    800044ec:	4781                	li	a5,0
    800044ee:	2785                	addiw	a5,a5,1
    800044f0:	04c78c63          	beq	a5,a2,80004548 <log_write+0xc2>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800044f4:	4314                	lw	a3,0(a4)
    800044f6:	0711                	addi	a4,a4,4
    800044f8:	feb69be3          	bne	a3,a1,800044ee <log_write+0x68>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044fc:	07a1                	addi	a5,a5,8
    800044fe:	078a                	slli	a5,a5,0x2
    80004500:	0001e717          	auipc	a4,0x1e
    80004504:	c0870713          	addi	a4,a4,-1016 # 80022108 <log>
    80004508:	97ba                	add	a5,a5,a4
    8000450a:	cb8c                	sw	a1,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    log.lh.n++;
  }
  release(&log.lock);
    8000450c:	0001e517          	auipc	a0,0x1e
    80004510:	bfc50513          	addi	a0,a0,-1028 # 80022108 <log>
    80004514:	ffffd097          	auipc	ra,0xffffd
    80004518:	856080e7          	jalr	-1962(ra) # 80000d6a <release>
}
    8000451c:	60e2                	ld	ra,24(sp)
    8000451e:	6442                	ld	s0,16(sp)
    80004520:	64a2                	ld	s1,8(sp)
    80004522:	6902                	ld	s2,0(sp)
    80004524:	6105                	addi	sp,sp,32
    80004526:	8082                	ret
    panic("too big a transaction");
    80004528:	00004517          	auipc	a0,0x4
    8000452c:	10850513          	addi	a0,a0,264 # 80008630 <syscalls+0x228>
    80004530:	ffffc097          	auipc	ra,0xffffc
    80004534:	0c2080e7          	jalr	194(ra) # 800005f2 <panic>
    panic("log_write outside of trans");
    80004538:	00004517          	auipc	a0,0x4
    8000453c:	11050513          	addi	a0,a0,272 # 80008648 <syscalls+0x240>
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	0b2080e7          	jalr	178(ra) # 800005f2 <panic>
  log.lh.block[i] = b->blockno;
    80004548:	0621                	addi	a2,a2,8
    8000454a:	060a                	slli	a2,a2,0x2
    8000454c:	0001e797          	auipc	a5,0x1e
    80004550:	bbc78793          	addi	a5,a5,-1092 # 80022108 <log>
    80004554:	963e                	add	a2,a2,a5
    80004556:	00c92783          	lw	a5,12(s2)
    8000455a:	ca1c                	sw	a5,16(a2)
    bpin(b);
    8000455c:	854a                	mv	a0,s2
    8000455e:	fffff097          	auipc	ra,0xfffff
    80004562:	d1c080e7          	jalr	-740(ra) # 8000327a <bpin>
    log.lh.n++;
    80004566:	0001e717          	auipc	a4,0x1e
    8000456a:	ba270713          	addi	a4,a4,-1118 # 80022108 <log>
    8000456e:	575c                	lw	a5,44(a4)
    80004570:	2785                	addiw	a5,a5,1
    80004572:	d75c                	sw	a5,44(a4)
    80004574:	bf61                	j	8000450c <log_write+0x86>
  log.lh.block[i] = b->blockno;
    80004576:	00c92783          	lw	a5,12(s2)
    8000457a:	0001e717          	auipc	a4,0x1e
    8000457e:	baf72f23          	sw	a5,-1090(a4) # 80022138 <log+0x30>
  if (i == log.lh.n) {  // Add new block to log?
    80004582:	f649                	bnez	a2,8000450c <log_write+0x86>
    80004584:	bfe1                	j	8000455c <log_write+0xd6>
  for (i = 0; i < log.lh.n; i++) {
    80004586:	4781                	li	a5,0
    80004588:	bf95                	j	800044fc <log_write+0x76>

000000008000458a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000458a:	1101                	addi	sp,sp,-32
    8000458c:	ec06                	sd	ra,24(sp)
    8000458e:	e822                	sd	s0,16(sp)
    80004590:	e426                	sd	s1,8(sp)
    80004592:	e04a                	sd	s2,0(sp)
    80004594:	1000                	addi	s0,sp,32
    80004596:	84aa                	mv	s1,a0
    80004598:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000459a:	00004597          	auipc	a1,0x4
    8000459e:	0ce58593          	addi	a1,a1,206 # 80008668 <syscalls+0x260>
    800045a2:	0521                	addi	a0,a0,8
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	682080e7          	jalr	1666(ra) # 80000c26 <initlock>
  lk->name = name;
    800045ac:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045b0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045b4:	0204a423          	sw	zero,40(s1)
}
    800045b8:	60e2                	ld	ra,24(sp)
    800045ba:	6442                	ld	s0,16(sp)
    800045bc:	64a2                	ld	s1,8(sp)
    800045be:	6902                	ld	s2,0(sp)
    800045c0:	6105                	addi	sp,sp,32
    800045c2:	8082                	ret

00000000800045c4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045c4:	1101                	addi	sp,sp,-32
    800045c6:	ec06                	sd	ra,24(sp)
    800045c8:	e822                	sd	s0,16(sp)
    800045ca:	e426                	sd	s1,8(sp)
    800045cc:	e04a                	sd	s2,0(sp)
    800045ce:	1000                	addi	s0,sp,32
    800045d0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045d2:	00850913          	addi	s2,a0,8
    800045d6:	854a                	mv	a0,s2
    800045d8:	ffffc097          	auipc	ra,0xffffc
    800045dc:	6de080e7          	jalr	1758(ra) # 80000cb6 <acquire>
  while (lk->locked) {
    800045e0:	409c                	lw	a5,0(s1)
    800045e2:	cb89                	beqz	a5,800045f4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045e4:	85ca                	mv	a1,s2
    800045e6:	8526                	mv	a0,s1
    800045e8:	ffffe097          	auipc	ra,0xffffe
    800045ec:	d76080e7          	jalr	-650(ra) # 8000235e <sleep>
  while (lk->locked) {
    800045f0:	409c                	lw	a5,0(s1)
    800045f2:	fbed                	bnez	a5,800045e4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045f4:	4785                	li	a5,1
    800045f6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045f8:	ffffd097          	auipc	ra,0xffffd
    800045fc:	4cc080e7          	jalr	1228(ra) # 80001ac4 <myproc>
    80004600:	5d1c                	lw	a5,56(a0)
    80004602:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004604:	854a                	mv	a0,s2
    80004606:	ffffc097          	auipc	ra,0xffffc
    8000460a:	764080e7          	jalr	1892(ra) # 80000d6a <release>
}
    8000460e:	60e2                	ld	ra,24(sp)
    80004610:	6442                	ld	s0,16(sp)
    80004612:	64a2                	ld	s1,8(sp)
    80004614:	6902                	ld	s2,0(sp)
    80004616:	6105                	addi	sp,sp,32
    80004618:	8082                	ret

000000008000461a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000461a:	1101                	addi	sp,sp,-32
    8000461c:	ec06                	sd	ra,24(sp)
    8000461e:	e822                	sd	s0,16(sp)
    80004620:	e426                	sd	s1,8(sp)
    80004622:	e04a                	sd	s2,0(sp)
    80004624:	1000                	addi	s0,sp,32
    80004626:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004628:	00850913          	addi	s2,a0,8
    8000462c:	854a                	mv	a0,s2
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	688080e7          	jalr	1672(ra) # 80000cb6 <acquire>
  lk->locked = 0;
    80004636:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000463a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000463e:	8526                	mv	a0,s1
    80004640:	ffffe097          	auipc	ra,0xffffe
    80004644:	ea4080e7          	jalr	-348(ra) # 800024e4 <wakeup>
  release(&lk->lk);
    80004648:	854a                	mv	a0,s2
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	720080e7          	jalr	1824(ra) # 80000d6a <release>
}
    80004652:	60e2                	ld	ra,24(sp)
    80004654:	6442                	ld	s0,16(sp)
    80004656:	64a2                	ld	s1,8(sp)
    80004658:	6902                	ld	s2,0(sp)
    8000465a:	6105                	addi	sp,sp,32
    8000465c:	8082                	ret

000000008000465e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000465e:	7179                	addi	sp,sp,-48
    80004660:	f406                	sd	ra,40(sp)
    80004662:	f022                	sd	s0,32(sp)
    80004664:	ec26                	sd	s1,24(sp)
    80004666:	e84a                	sd	s2,16(sp)
    80004668:	e44e                	sd	s3,8(sp)
    8000466a:	1800                	addi	s0,sp,48
    8000466c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000466e:	00850913          	addi	s2,a0,8
    80004672:	854a                	mv	a0,s2
    80004674:	ffffc097          	auipc	ra,0xffffc
    80004678:	642080e7          	jalr	1602(ra) # 80000cb6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000467c:	409c                	lw	a5,0(s1)
    8000467e:	ef99                	bnez	a5,8000469c <holdingsleep+0x3e>
    80004680:	4481                	li	s1,0
  release(&lk->lk);
    80004682:	854a                	mv	a0,s2
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	6e6080e7          	jalr	1766(ra) # 80000d6a <release>
  return r;
}
    8000468c:	8526                	mv	a0,s1
    8000468e:	70a2                	ld	ra,40(sp)
    80004690:	7402                	ld	s0,32(sp)
    80004692:	64e2                	ld	s1,24(sp)
    80004694:	6942                	ld	s2,16(sp)
    80004696:	69a2                	ld	s3,8(sp)
    80004698:	6145                	addi	sp,sp,48
    8000469a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000469c:	0284a983          	lw	s3,40(s1)
    800046a0:	ffffd097          	auipc	ra,0xffffd
    800046a4:	424080e7          	jalr	1060(ra) # 80001ac4 <myproc>
    800046a8:	5d04                	lw	s1,56(a0)
    800046aa:	413484b3          	sub	s1,s1,s3
    800046ae:	0014b493          	seqz	s1,s1
    800046b2:	bfc1                	j	80004682 <holdingsleep+0x24>

00000000800046b4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046b4:	1141                	addi	sp,sp,-16
    800046b6:	e406                	sd	ra,8(sp)
    800046b8:	e022                	sd	s0,0(sp)
    800046ba:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046bc:	00004597          	auipc	a1,0x4
    800046c0:	fbc58593          	addi	a1,a1,-68 # 80008678 <syscalls+0x270>
    800046c4:	0001e517          	auipc	a0,0x1e
    800046c8:	b8c50513          	addi	a0,a0,-1140 # 80022250 <ftable>
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	55a080e7          	jalr	1370(ra) # 80000c26 <initlock>
}
    800046d4:	60a2                	ld	ra,8(sp)
    800046d6:	6402                	ld	s0,0(sp)
    800046d8:	0141                	addi	sp,sp,16
    800046da:	8082                	ret

00000000800046dc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046dc:	1101                	addi	sp,sp,-32
    800046de:	ec06                	sd	ra,24(sp)
    800046e0:	e822                	sd	s0,16(sp)
    800046e2:	e426                	sd	s1,8(sp)
    800046e4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046e6:	0001e517          	auipc	a0,0x1e
    800046ea:	b6a50513          	addi	a0,a0,-1174 # 80022250 <ftable>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	5c8080e7          	jalr	1480(ra) # 80000cb6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
    800046f6:	0001e797          	auipc	a5,0x1e
    800046fa:	b5a78793          	addi	a5,a5,-1190 # 80022250 <ftable>
    800046fe:	4fdc                	lw	a5,28(a5)
    80004700:	cb8d                	beqz	a5,80004732 <filealloc+0x56>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004702:	0001e497          	auipc	s1,0x1e
    80004706:	b8e48493          	addi	s1,s1,-1138 # 80022290 <ftable+0x40>
    8000470a:	0001f717          	auipc	a4,0x1f
    8000470e:	afe70713          	addi	a4,a4,-1282 # 80023208 <ftable+0xfb8>
    if(f->ref == 0){
    80004712:	40dc                	lw	a5,4(s1)
    80004714:	c39d                	beqz	a5,8000473a <filealloc+0x5e>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004716:	02848493          	addi	s1,s1,40
    8000471a:	fee49ce3          	bne	s1,a4,80004712 <filealloc+0x36>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000471e:	0001e517          	auipc	a0,0x1e
    80004722:	b3250513          	addi	a0,a0,-1230 # 80022250 <ftable>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	644080e7          	jalr	1604(ra) # 80000d6a <release>
  return 0;
    8000472e:	4481                	li	s1,0
    80004730:	a839                	j	8000474e <filealloc+0x72>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004732:	0001e497          	auipc	s1,0x1e
    80004736:	b3648493          	addi	s1,s1,-1226 # 80022268 <ftable+0x18>
      f->ref = 1;
    8000473a:	4785                	li	a5,1
    8000473c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000473e:	0001e517          	auipc	a0,0x1e
    80004742:	b1250513          	addi	a0,a0,-1262 # 80022250 <ftable>
    80004746:	ffffc097          	auipc	ra,0xffffc
    8000474a:	624080e7          	jalr	1572(ra) # 80000d6a <release>
}
    8000474e:	8526                	mv	a0,s1
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6105                	addi	sp,sp,32
    80004758:	8082                	ret

000000008000475a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000475a:	1101                	addi	sp,sp,-32
    8000475c:	ec06                	sd	ra,24(sp)
    8000475e:	e822                	sd	s0,16(sp)
    80004760:	e426                	sd	s1,8(sp)
    80004762:	1000                	addi	s0,sp,32
    80004764:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004766:	0001e517          	auipc	a0,0x1e
    8000476a:	aea50513          	addi	a0,a0,-1302 # 80022250 <ftable>
    8000476e:	ffffc097          	auipc	ra,0xffffc
    80004772:	548080e7          	jalr	1352(ra) # 80000cb6 <acquire>
  if(f->ref < 1)
    80004776:	40dc                	lw	a5,4(s1)
    80004778:	02f05263          	blez	a5,8000479c <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000477c:	2785                	addiw	a5,a5,1
    8000477e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004780:	0001e517          	auipc	a0,0x1e
    80004784:	ad050513          	addi	a0,a0,-1328 # 80022250 <ftable>
    80004788:	ffffc097          	auipc	ra,0xffffc
    8000478c:	5e2080e7          	jalr	1506(ra) # 80000d6a <release>
  return f;
}
    80004790:	8526                	mv	a0,s1
    80004792:	60e2                	ld	ra,24(sp)
    80004794:	6442                	ld	s0,16(sp)
    80004796:	64a2                	ld	s1,8(sp)
    80004798:	6105                	addi	sp,sp,32
    8000479a:	8082                	ret
    panic("filedup");
    8000479c:	00004517          	auipc	a0,0x4
    800047a0:	ee450513          	addi	a0,a0,-284 # 80008680 <syscalls+0x278>
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	e4e080e7          	jalr	-434(ra) # 800005f2 <panic>

00000000800047ac <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047ac:	7139                	addi	sp,sp,-64
    800047ae:	fc06                	sd	ra,56(sp)
    800047b0:	f822                	sd	s0,48(sp)
    800047b2:	f426                	sd	s1,40(sp)
    800047b4:	f04a                	sd	s2,32(sp)
    800047b6:	ec4e                	sd	s3,24(sp)
    800047b8:	e852                	sd	s4,16(sp)
    800047ba:	e456                	sd	s5,8(sp)
    800047bc:	0080                	addi	s0,sp,64
    800047be:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047c0:	0001e517          	auipc	a0,0x1e
    800047c4:	a9050513          	addi	a0,a0,-1392 # 80022250 <ftable>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	4ee080e7          	jalr	1262(ra) # 80000cb6 <acquire>
  if(f->ref < 1)
    800047d0:	40dc                	lw	a5,4(s1)
    800047d2:	06f05163          	blez	a5,80004834 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047d6:	37fd                	addiw	a5,a5,-1
    800047d8:	0007871b          	sext.w	a4,a5
    800047dc:	c0dc                	sw	a5,4(s1)
    800047de:	06e04363          	bgtz	a4,80004844 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047e2:	0004a903          	lw	s2,0(s1)
    800047e6:	0094ca83          	lbu	s5,9(s1)
    800047ea:	0104ba03          	ld	s4,16(s1)
    800047ee:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047f2:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047f6:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047fa:	0001e517          	auipc	a0,0x1e
    800047fe:	a5650513          	addi	a0,a0,-1450 # 80022250 <ftable>
    80004802:	ffffc097          	auipc	ra,0xffffc
    80004806:	568080e7          	jalr	1384(ra) # 80000d6a <release>

  if(ff.type == FD_PIPE){
    8000480a:	4785                	li	a5,1
    8000480c:	04f90d63          	beq	s2,a5,80004866 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004810:	3979                	addiw	s2,s2,-2
    80004812:	4785                	li	a5,1
    80004814:	0527e063          	bltu	a5,s2,80004854 <fileclose+0xa8>
    begin_op();
    80004818:	00000097          	auipc	ra,0x0
    8000481c:	a92080e7          	jalr	-1390(ra) # 800042aa <begin_op>
    iput(ff.ip);
    80004820:	854e                	mv	a0,s3
    80004822:	fffff097          	auipc	ra,0xfffff
    80004826:	27c080e7          	jalr	636(ra) # 80003a9e <iput>
    end_op();
    8000482a:	00000097          	auipc	ra,0x0
    8000482e:	b00080e7          	jalr	-1280(ra) # 8000432a <end_op>
    80004832:	a00d                	j	80004854 <fileclose+0xa8>
    panic("fileclose");
    80004834:	00004517          	auipc	a0,0x4
    80004838:	e5450513          	addi	a0,a0,-428 # 80008688 <syscalls+0x280>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	db6080e7          	jalr	-586(ra) # 800005f2 <panic>
    release(&ftable.lock);
    80004844:	0001e517          	auipc	a0,0x1e
    80004848:	a0c50513          	addi	a0,a0,-1524 # 80022250 <ftable>
    8000484c:	ffffc097          	auipc	ra,0xffffc
    80004850:	51e080e7          	jalr	1310(ra) # 80000d6a <release>
  }
}
    80004854:	70e2                	ld	ra,56(sp)
    80004856:	7442                	ld	s0,48(sp)
    80004858:	74a2                	ld	s1,40(sp)
    8000485a:	7902                	ld	s2,32(sp)
    8000485c:	69e2                	ld	s3,24(sp)
    8000485e:	6a42                	ld	s4,16(sp)
    80004860:	6aa2                	ld	s5,8(sp)
    80004862:	6121                	addi	sp,sp,64
    80004864:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004866:	85d6                	mv	a1,s5
    80004868:	8552                	mv	a0,s4
    8000486a:	00000097          	auipc	ra,0x0
    8000486e:	364080e7          	jalr	868(ra) # 80004bce <pipeclose>
    80004872:	b7cd                	j	80004854 <fileclose+0xa8>

0000000080004874 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004874:	715d                	addi	sp,sp,-80
    80004876:	e486                	sd	ra,72(sp)
    80004878:	e0a2                	sd	s0,64(sp)
    8000487a:	fc26                	sd	s1,56(sp)
    8000487c:	f84a                	sd	s2,48(sp)
    8000487e:	f44e                	sd	s3,40(sp)
    80004880:	0880                	addi	s0,sp,80
    80004882:	84aa                	mv	s1,a0
    80004884:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004886:	ffffd097          	auipc	ra,0xffffd
    8000488a:	23e080e7          	jalr	574(ra) # 80001ac4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000488e:	409c                	lw	a5,0(s1)
    80004890:	37f9                	addiw	a5,a5,-2
    80004892:	4705                	li	a4,1
    80004894:	04f76763          	bltu	a4,a5,800048e2 <filestat+0x6e>
    80004898:	892a                	mv	s2,a0
    ilock(f->ip);
    8000489a:	6c88                	ld	a0,24(s1)
    8000489c:	fffff097          	auipc	ra,0xfffff
    800048a0:	046080e7          	jalr	70(ra) # 800038e2 <ilock>
    stati(f->ip, &st);
    800048a4:	fb840593          	addi	a1,s0,-72
    800048a8:	6c88                	ld	a0,24(s1)
    800048aa:	fffff097          	auipc	ra,0xfffff
    800048ae:	2c4080e7          	jalr	708(ra) # 80003b6e <stati>
    iunlock(f->ip);
    800048b2:	6c88                	ld	a0,24(s1)
    800048b4:	fffff097          	auipc	ra,0xfffff
    800048b8:	0f2080e7          	jalr	242(ra) # 800039a6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048bc:	46e1                	li	a3,24
    800048be:	fb840613          	addi	a2,s0,-72
    800048c2:	85ce                	mv	a1,s3
    800048c4:	05093503          	ld	a0,80(s2)
    800048c8:	ffffd097          	auipc	ra,0xffffd
    800048cc:	ed8080e7          	jalr	-296(ra) # 800017a0 <copyout>
    800048d0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048d4:	60a6                	ld	ra,72(sp)
    800048d6:	6406                	ld	s0,64(sp)
    800048d8:	74e2                	ld	s1,56(sp)
    800048da:	7942                	ld	s2,48(sp)
    800048dc:	79a2                	ld	s3,40(sp)
    800048de:	6161                	addi	sp,sp,80
    800048e0:	8082                	ret
  return -1;
    800048e2:	557d                	li	a0,-1
    800048e4:	bfc5                	j	800048d4 <filestat+0x60>

00000000800048e6 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048e6:	7179                	addi	sp,sp,-48
    800048e8:	f406                	sd	ra,40(sp)
    800048ea:	f022                	sd	s0,32(sp)
    800048ec:	ec26                	sd	s1,24(sp)
    800048ee:	e84a                	sd	s2,16(sp)
    800048f0:	e44e                	sd	s3,8(sp)
    800048f2:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048f4:	00854783          	lbu	a5,8(a0)
    800048f8:	c3d5                	beqz	a5,8000499c <fileread+0xb6>
    800048fa:	89b2                	mv	s3,a2
    800048fc:	892e                	mv	s2,a1
    800048fe:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    80004900:	411c                	lw	a5,0(a0)
    80004902:	4705                	li	a4,1
    80004904:	04e78963          	beq	a5,a4,80004956 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004908:	470d                	li	a4,3
    8000490a:	04e78d63          	beq	a5,a4,80004964 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000490e:	4709                	li	a4,2
    80004910:	06e79e63          	bne	a5,a4,8000498c <fileread+0xa6>
    ilock(f->ip);
    80004914:	6d08                	ld	a0,24(a0)
    80004916:	fffff097          	auipc	ra,0xfffff
    8000491a:	fcc080e7          	jalr	-52(ra) # 800038e2 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000491e:	874e                	mv	a4,s3
    80004920:	5094                	lw	a3,32(s1)
    80004922:	864a                	mv	a2,s2
    80004924:	4585                	li	a1,1
    80004926:	6c88                	ld	a0,24(s1)
    80004928:	fffff097          	auipc	ra,0xfffff
    8000492c:	270080e7          	jalr	624(ra) # 80003b98 <readi>
    80004930:	892a                	mv	s2,a0
    80004932:	00a05563          	blez	a0,8000493c <fileread+0x56>
      f->off += r;
    80004936:	509c                	lw	a5,32(s1)
    80004938:	9fa9                	addw	a5,a5,a0
    8000493a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000493c:	6c88                	ld	a0,24(s1)
    8000493e:	fffff097          	auipc	ra,0xfffff
    80004942:	068080e7          	jalr	104(ra) # 800039a6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004946:	854a                	mv	a0,s2
    80004948:	70a2                	ld	ra,40(sp)
    8000494a:	7402                	ld	s0,32(sp)
    8000494c:	64e2                	ld	s1,24(sp)
    8000494e:	6942                	ld	s2,16(sp)
    80004950:	69a2                	ld	s3,8(sp)
    80004952:	6145                	addi	sp,sp,48
    80004954:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004956:	6908                	ld	a0,16(a0)
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	416080e7          	jalr	1046(ra) # 80004d6e <piperead>
    80004960:	892a                	mv	s2,a0
    80004962:	b7d5                	j	80004946 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004964:	02451783          	lh	a5,36(a0)
    80004968:	03079693          	slli	a3,a5,0x30
    8000496c:	92c1                	srli	a3,a3,0x30
    8000496e:	4725                	li	a4,9
    80004970:	02d76863          	bltu	a4,a3,800049a0 <fileread+0xba>
    80004974:	0792                	slli	a5,a5,0x4
    80004976:	0001e717          	auipc	a4,0x1e
    8000497a:	83a70713          	addi	a4,a4,-1990 # 800221b0 <devsw>
    8000497e:	97ba                	add	a5,a5,a4
    80004980:	639c                	ld	a5,0(a5)
    80004982:	c38d                	beqz	a5,800049a4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004984:	4505                	li	a0,1
    80004986:	9782                	jalr	a5
    80004988:	892a                	mv	s2,a0
    8000498a:	bf75                	j	80004946 <fileread+0x60>
    panic("fileread");
    8000498c:	00004517          	auipc	a0,0x4
    80004990:	d0c50513          	addi	a0,a0,-756 # 80008698 <syscalls+0x290>
    80004994:	ffffc097          	auipc	ra,0xffffc
    80004998:	c5e080e7          	jalr	-930(ra) # 800005f2 <panic>
    return -1;
    8000499c:	597d                	li	s2,-1
    8000499e:	b765                	j	80004946 <fileread+0x60>
      return -1;
    800049a0:	597d                	li	s2,-1
    800049a2:	b755                	j	80004946 <fileread+0x60>
    800049a4:	597d                	li	s2,-1
    800049a6:	b745                	j	80004946 <fileread+0x60>

00000000800049a8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800049a8:	00954783          	lbu	a5,9(a0)
    800049ac:	12078e63          	beqz	a5,80004ae8 <filewrite+0x140>
{
    800049b0:	715d                	addi	sp,sp,-80
    800049b2:	e486                	sd	ra,72(sp)
    800049b4:	e0a2                	sd	s0,64(sp)
    800049b6:	fc26                	sd	s1,56(sp)
    800049b8:	f84a                	sd	s2,48(sp)
    800049ba:	f44e                	sd	s3,40(sp)
    800049bc:	f052                	sd	s4,32(sp)
    800049be:	ec56                	sd	s5,24(sp)
    800049c0:	e85a                	sd	s6,16(sp)
    800049c2:	e45e                	sd	s7,8(sp)
    800049c4:	e062                	sd	s8,0(sp)
    800049c6:	0880                	addi	s0,sp,80
    800049c8:	8ab2                	mv	s5,a2
    800049ca:	8b2e                	mv	s6,a1
    800049cc:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    800049ce:	411c                	lw	a5,0(a0)
    800049d0:	4705                	li	a4,1
    800049d2:	02e78263          	beq	a5,a4,800049f6 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049d6:	470d                	li	a4,3
    800049d8:	02e78563          	beq	a5,a4,80004a02 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049dc:	4709                	li	a4,2
    800049de:	0ee79d63          	bne	a5,a4,80004ad8 <filewrite+0x130>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049e2:	0ec05763          	blez	a2,80004ad0 <filewrite+0x128>
    int i = 0;
    800049e6:	4901                	li	s2,0
    800049e8:	6b85                	lui	s7,0x1
    800049ea:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800049ee:	6c05                	lui	s8,0x1
    800049f0:	c00c0c1b          	addiw	s8,s8,-1024
    800049f4:	a061                	j	80004a7c <filewrite+0xd4>
    ret = pipewrite(f->pipe, addr, n);
    800049f6:	6908                	ld	a0,16(a0)
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	246080e7          	jalr	582(ra) # 80004c3e <pipewrite>
    80004a00:	a065                	j	80004aa8 <filewrite+0x100>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a02:	02451783          	lh	a5,36(a0)
    80004a06:	03079693          	slli	a3,a5,0x30
    80004a0a:	92c1                	srli	a3,a3,0x30
    80004a0c:	4725                	li	a4,9
    80004a0e:	0cd76f63          	bltu	a4,a3,80004aec <filewrite+0x144>
    80004a12:	0792                	slli	a5,a5,0x4
    80004a14:	0001d717          	auipc	a4,0x1d
    80004a18:	79c70713          	addi	a4,a4,1948 # 800221b0 <devsw>
    80004a1c:	97ba                	add	a5,a5,a4
    80004a1e:	679c                	ld	a5,8(a5)
    80004a20:	cbe1                	beqz	a5,80004af0 <filewrite+0x148>
    ret = devsw[f->major].write(1, addr, n);
    80004a22:	4505                	li	a0,1
    80004a24:	9782                	jalr	a5
    80004a26:	a049                	j	80004aa8 <filewrite+0x100>
    80004a28:	00098a1b          	sext.w	s4,s3
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a2c:	00000097          	auipc	ra,0x0
    80004a30:	87e080e7          	jalr	-1922(ra) # 800042aa <begin_op>
      ilock(f->ip);
    80004a34:	6c88                	ld	a0,24(s1)
    80004a36:	fffff097          	auipc	ra,0xfffff
    80004a3a:	eac080e7          	jalr	-340(ra) # 800038e2 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a3e:	8752                	mv	a4,s4
    80004a40:	5094                	lw	a3,32(s1)
    80004a42:	01690633          	add	a2,s2,s6
    80004a46:	4585                	li	a1,1
    80004a48:	6c88                	ld	a0,24(s1)
    80004a4a:	fffff097          	auipc	ra,0xfffff
    80004a4e:	244080e7          	jalr	580(ra) # 80003c8e <writei>
    80004a52:	89aa                	mv	s3,a0
    80004a54:	02a05c63          	blez	a0,80004a8c <filewrite+0xe4>
        f->off += r;
    80004a58:	509c                	lw	a5,32(s1)
    80004a5a:	9fa9                	addw	a5,a5,a0
    80004a5c:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    80004a5e:	6c88                	ld	a0,24(s1)
    80004a60:	fffff097          	auipc	ra,0xfffff
    80004a64:	f46080e7          	jalr	-186(ra) # 800039a6 <iunlock>
      end_op();
    80004a68:	00000097          	auipc	ra,0x0
    80004a6c:	8c2080e7          	jalr	-1854(ra) # 8000432a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004a70:	05499863          	bne	s3,s4,80004ac0 <filewrite+0x118>
        panic("short filewrite");
      i += r;
    80004a74:	012a093b          	addw	s2,s4,s2
    while(i < n){
    80004a78:	03595563          	ble	s5,s2,80004aa2 <filewrite+0xfa>
      int n1 = n - i;
    80004a7c:	412a87bb          	subw	a5,s5,s2
      if(n1 > max)
    80004a80:	89be                	mv	s3,a5
    80004a82:	2781                	sext.w	a5,a5
    80004a84:	fafbd2e3          	ble	a5,s7,80004a28 <filewrite+0x80>
    80004a88:	89e2                	mv	s3,s8
    80004a8a:	bf79                	j	80004a28 <filewrite+0x80>
      iunlock(f->ip);
    80004a8c:	6c88                	ld	a0,24(s1)
    80004a8e:	fffff097          	auipc	ra,0xfffff
    80004a92:	f18080e7          	jalr	-232(ra) # 800039a6 <iunlock>
      end_op();
    80004a96:	00000097          	auipc	ra,0x0
    80004a9a:	894080e7          	jalr	-1900(ra) # 8000432a <end_op>
      if(r < 0)
    80004a9e:	fc09d9e3          	bgez	s3,80004a70 <filewrite+0xc8>
    }
    ret = (i == n ? n : -1);
    80004aa2:	8556                	mv	a0,s5
    80004aa4:	032a9863          	bne	s5,s2,80004ad4 <filewrite+0x12c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004aa8:	60a6                	ld	ra,72(sp)
    80004aaa:	6406                	ld	s0,64(sp)
    80004aac:	74e2                	ld	s1,56(sp)
    80004aae:	7942                	ld	s2,48(sp)
    80004ab0:	79a2                	ld	s3,40(sp)
    80004ab2:	7a02                	ld	s4,32(sp)
    80004ab4:	6ae2                	ld	s5,24(sp)
    80004ab6:	6b42                	ld	s6,16(sp)
    80004ab8:	6ba2                	ld	s7,8(sp)
    80004aba:	6c02                	ld	s8,0(sp)
    80004abc:	6161                	addi	sp,sp,80
    80004abe:	8082                	ret
        panic("short filewrite");
    80004ac0:	00004517          	auipc	a0,0x4
    80004ac4:	be850513          	addi	a0,a0,-1048 # 800086a8 <syscalls+0x2a0>
    80004ac8:	ffffc097          	auipc	ra,0xffffc
    80004acc:	b2a080e7          	jalr	-1238(ra) # 800005f2 <panic>
    int i = 0;
    80004ad0:	4901                	li	s2,0
    80004ad2:	bfc1                	j	80004aa2 <filewrite+0xfa>
    ret = (i == n ? n : -1);
    80004ad4:	557d                	li	a0,-1
    80004ad6:	bfc9                	j	80004aa8 <filewrite+0x100>
    panic("filewrite");
    80004ad8:	00004517          	auipc	a0,0x4
    80004adc:	be050513          	addi	a0,a0,-1056 # 800086b8 <syscalls+0x2b0>
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	b12080e7          	jalr	-1262(ra) # 800005f2 <panic>
    return -1;
    80004ae8:	557d                	li	a0,-1
}
    80004aea:	8082                	ret
      return -1;
    80004aec:	557d                	li	a0,-1
    80004aee:	bf6d                	j	80004aa8 <filewrite+0x100>
    80004af0:	557d                	li	a0,-1
    80004af2:	bf5d                	j	80004aa8 <filewrite+0x100>

0000000080004af4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004af4:	7179                	addi	sp,sp,-48
    80004af6:	f406                	sd	ra,40(sp)
    80004af8:	f022                	sd	s0,32(sp)
    80004afa:	ec26                	sd	s1,24(sp)
    80004afc:	e84a                	sd	s2,16(sp)
    80004afe:	e44e                	sd	s3,8(sp)
    80004b00:	e052                	sd	s4,0(sp)
    80004b02:	1800                	addi	s0,sp,48
    80004b04:	84aa                	mv	s1,a0
    80004b06:	892e                	mv	s2,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b08:	0005b023          	sd	zero,0(a1)
    80004b0c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b10:	00000097          	auipc	ra,0x0
    80004b14:	bcc080e7          	jalr	-1076(ra) # 800046dc <filealloc>
    80004b18:	e088                	sd	a0,0(s1)
    80004b1a:	c551                	beqz	a0,80004ba6 <pipealloc+0xb2>
    80004b1c:	00000097          	auipc	ra,0x0
    80004b20:	bc0080e7          	jalr	-1088(ra) # 800046dc <filealloc>
    80004b24:	00a93023          	sd	a0,0(s2)
    80004b28:	c92d                	beqz	a0,80004b9a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b2a:	ffffc097          	auipc	ra,0xffffc
    80004b2e:	09c080e7          	jalr	156(ra) # 80000bc6 <kalloc>
    80004b32:	89aa                	mv	s3,a0
    80004b34:	c125                	beqz	a0,80004b94 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b36:	4a05                	li	s4,1
    80004b38:	23452023          	sw	s4,544(a0)
  pi->writeopen = 1;
    80004b3c:	23452223          	sw	s4,548(a0)
  pi->nwrite = 0;
    80004b40:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b44:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b48:	00004597          	auipc	a1,0x4
    80004b4c:	b8058593          	addi	a1,a1,-1152 # 800086c8 <syscalls+0x2c0>
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	0d6080e7          	jalr	214(ra) # 80000c26 <initlock>
  (*f0)->type = FD_PIPE;
    80004b58:	609c                	ld	a5,0(s1)
    80004b5a:	0147a023          	sw	s4,0(a5)
  (*f0)->readable = 1;
    80004b5e:	609c                	ld	a5,0(s1)
    80004b60:	01478423          	sb	s4,8(a5)
  (*f0)->writable = 0;
    80004b64:	609c                	ld	a5,0(s1)
    80004b66:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b6a:	609c                	ld	a5,0(s1)
    80004b6c:	0137b823          	sd	s3,16(a5)
  (*f1)->type = FD_PIPE;
    80004b70:	00093783          	ld	a5,0(s2)
    80004b74:	0147a023          	sw	s4,0(a5)
  (*f1)->readable = 0;
    80004b78:	00093783          	ld	a5,0(s2)
    80004b7c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b80:	00093783          	ld	a5,0(s2)
    80004b84:	014784a3          	sb	s4,9(a5)
  (*f1)->pipe = pi;
    80004b88:	00093783          	ld	a5,0(s2)
    80004b8c:	0137b823          	sd	s3,16(a5)
  return 0;
    80004b90:	4501                	li	a0,0
    80004b92:	a025                	j	80004bba <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b94:	6088                	ld	a0,0(s1)
    80004b96:	e501                	bnez	a0,80004b9e <pipealloc+0xaa>
    80004b98:	a039                	j	80004ba6 <pipealloc+0xb2>
    80004b9a:	6088                	ld	a0,0(s1)
    80004b9c:	c51d                	beqz	a0,80004bca <pipealloc+0xd6>
    fileclose(*f0);
    80004b9e:	00000097          	auipc	ra,0x0
    80004ba2:	c0e080e7          	jalr	-1010(ra) # 800047ac <fileclose>
  if(*f1)
    80004ba6:	00093783          	ld	a5,0(s2)
    fileclose(*f1);
  return -1;
    80004baa:	557d                	li	a0,-1
  if(*f1)
    80004bac:	c799                	beqz	a5,80004bba <pipealloc+0xc6>
    fileclose(*f1);
    80004bae:	853e                	mv	a0,a5
    80004bb0:	00000097          	auipc	ra,0x0
    80004bb4:	bfc080e7          	jalr	-1028(ra) # 800047ac <fileclose>
  return -1;
    80004bb8:	557d                	li	a0,-1
}
    80004bba:	70a2                	ld	ra,40(sp)
    80004bbc:	7402                	ld	s0,32(sp)
    80004bbe:	64e2                	ld	s1,24(sp)
    80004bc0:	6942                	ld	s2,16(sp)
    80004bc2:	69a2                	ld	s3,8(sp)
    80004bc4:	6a02                	ld	s4,0(sp)
    80004bc6:	6145                	addi	sp,sp,48
    80004bc8:	8082                	ret
  return -1;
    80004bca:	557d                	li	a0,-1
    80004bcc:	b7fd                	j	80004bba <pipealloc+0xc6>

0000000080004bce <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bce:	1101                	addi	sp,sp,-32
    80004bd0:	ec06                	sd	ra,24(sp)
    80004bd2:	e822                	sd	s0,16(sp)
    80004bd4:	e426                	sd	s1,8(sp)
    80004bd6:	e04a                	sd	s2,0(sp)
    80004bd8:	1000                	addi	s0,sp,32
    80004bda:	84aa                	mv	s1,a0
    80004bdc:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	0d8080e7          	jalr	216(ra) # 80000cb6 <acquire>
  if(writable){
    80004be6:	02090d63          	beqz	s2,80004c20 <pipeclose+0x52>
    pi->writeopen = 0;
    80004bea:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bee:	21848513          	addi	a0,s1,536
    80004bf2:	ffffe097          	auipc	ra,0xffffe
    80004bf6:	8f2080e7          	jalr	-1806(ra) # 800024e4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004bfa:	2204b783          	ld	a5,544(s1)
    80004bfe:	eb95                	bnez	a5,80004c32 <pipeclose+0x64>
    release(&pi->lock);
    80004c00:	8526                	mv	a0,s1
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	168080e7          	jalr	360(ra) # 80000d6a <release>
    kfree((char*)pi);
    80004c0a:	8526                	mv	a0,s1
    80004c0c:	ffffc097          	auipc	ra,0xffffc
    80004c10:	eba080e7          	jalr	-326(ra) # 80000ac6 <kfree>
  } else
    release(&pi->lock);
}
    80004c14:	60e2                	ld	ra,24(sp)
    80004c16:	6442                	ld	s0,16(sp)
    80004c18:	64a2                	ld	s1,8(sp)
    80004c1a:	6902                	ld	s2,0(sp)
    80004c1c:	6105                	addi	sp,sp,32
    80004c1e:	8082                	ret
    pi->readopen = 0;
    80004c20:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c24:	21c48513          	addi	a0,s1,540
    80004c28:	ffffe097          	auipc	ra,0xffffe
    80004c2c:	8bc080e7          	jalr	-1860(ra) # 800024e4 <wakeup>
    80004c30:	b7e9                	j	80004bfa <pipeclose+0x2c>
    release(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	136080e7          	jalr	310(ra) # 80000d6a <release>
}
    80004c3c:	bfe1                	j	80004c14 <pipeclose+0x46>

0000000080004c3e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c3e:	7119                	addi	sp,sp,-128
    80004c40:	fc86                	sd	ra,120(sp)
    80004c42:	f8a2                	sd	s0,112(sp)
    80004c44:	f4a6                	sd	s1,104(sp)
    80004c46:	f0ca                	sd	s2,96(sp)
    80004c48:	ecce                	sd	s3,88(sp)
    80004c4a:	e8d2                	sd	s4,80(sp)
    80004c4c:	e4d6                	sd	s5,72(sp)
    80004c4e:	e0da                	sd	s6,64(sp)
    80004c50:	fc5e                	sd	s7,56(sp)
    80004c52:	f862                	sd	s8,48(sp)
    80004c54:	f466                	sd	s9,40(sp)
    80004c56:	f06a                	sd	s10,32(sp)
    80004c58:	ec6e                	sd	s11,24(sp)
    80004c5a:	0100                	addi	s0,sp,128
    80004c5c:	84aa                	mv	s1,a0
    80004c5e:	8d2e                	mv	s10,a1
    80004c60:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004c62:	ffffd097          	auipc	ra,0xffffd
    80004c66:	e62080e7          	jalr	-414(ra) # 80001ac4 <myproc>
    80004c6a:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	048080e7          	jalr	72(ra) # 80000cb6 <acquire>
  for(i = 0; i < n; i++){
    80004c76:	0d605f63          	blez	s6,80004d54 <pipewrite+0x116>
    80004c7a:	89a6                	mv	s3,s1
    80004c7c:	3b7d                	addiw	s6,s6,-1
    80004c7e:	1b02                	slli	s6,s6,0x20
    80004c80:	020b5b13          	srli	s6,s6,0x20
    80004c84:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004c86:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c8a:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c8e:	5dfd                	li	s11,-1
    80004c90:	000b8c9b          	sext.w	s9,s7
    80004c94:	8c66                	mv	s8,s9
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004c96:	2184a783          	lw	a5,536(s1)
    80004c9a:	21c4a703          	lw	a4,540(s1)
    80004c9e:	2007879b          	addiw	a5,a5,512
    80004ca2:	06f71763          	bne	a4,a5,80004d10 <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80004ca6:	2204a783          	lw	a5,544(s1)
    80004caa:	cf8d                	beqz	a5,80004ce4 <pipewrite+0xa6>
    80004cac:	03092783          	lw	a5,48(s2)
    80004cb0:	eb95                	bnez	a5,80004ce4 <pipewrite+0xa6>
      wakeup(&pi->nread);
    80004cb2:	8556                	mv	a0,s5
    80004cb4:	ffffe097          	auipc	ra,0xffffe
    80004cb8:	830080e7          	jalr	-2000(ra) # 800024e4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cbc:	85ce                	mv	a1,s3
    80004cbe:	8552                	mv	a0,s4
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	69e080e7          	jalr	1694(ra) # 8000235e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004cc8:	2184a783          	lw	a5,536(s1)
    80004ccc:	21c4a703          	lw	a4,540(s1)
    80004cd0:	2007879b          	addiw	a5,a5,512
    80004cd4:	02f71e63          	bne	a4,a5,80004d10 <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80004cd8:	2204a783          	lw	a5,544(s1)
    80004cdc:	c781                	beqz	a5,80004ce4 <pipewrite+0xa6>
    80004cde:	03092783          	lw	a5,48(s2)
    80004ce2:	dbe1                	beqz	a5,80004cb2 <pipewrite+0x74>
        release(&pi->lock);
    80004ce4:	8526                	mv	a0,s1
    80004ce6:	ffffc097          	auipc	ra,0xffffc
    80004cea:	084080e7          	jalr	132(ra) # 80000d6a <release>
        return -1;
    80004cee:	5c7d                	li	s8,-1
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004cf0:	8562                	mv	a0,s8
    80004cf2:	70e6                	ld	ra,120(sp)
    80004cf4:	7446                	ld	s0,112(sp)
    80004cf6:	74a6                	ld	s1,104(sp)
    80004cf8:	7906                	ld	s2,96(sp)
    80004cfa:	69e6                	ld	s3,88(sp)
    80004cfc:	6a46                	ld	s4,80(sp)
    80004cfe:	6aa6                	ld	s5,72(sp)
    80004d00:	6b06                	ld	s6,64(sp)
    80004d02:	7be2                	ld	s7,56(sp)
    80004d04:	7c42                	ld	s8,48(sp)
    80004d06:	7ca2                	ld	s9,40(sp)
    80004d08:	7d02                	ld	s10,32(sp)
    80004d0a:	6de2                	ld	s11,24(sp)
    80004d0c:	6109                	addi	sp,sp,128
    80004d0e:	8082                	ret
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d10:	4685                	li	a3,1
    80004d12:	01ab8633          	add	a2,s7,s10
    80004d16:	f8f40593          	addi	a1,s0,-113
    80004d1a:	05093503          	ld	a0,80(s2)
    80004d1e:	ffffd097          	auipc	ra,0xffffd
    80004d22:	b0e080e7          	jalr	-1266(ra) # 8000182c <copyin>
    80004d26:	03b50863          	beq	a0,s11,80004d56 <pipewrite+0x118>
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d2a:	21c4a783          	lw	a5,540(s1)
    80004d2e:	0017871b          	addiw	a4,a5,1
    80004d32:	20e4ae23          	sw	a4,540(s1)
    80004d36:	1ff7f793          	andi	a5,a5,511
    80004d3a:	97a6                	add	a5,a5,s1
    80004d3c:	f8f44703          	lbu	a4,-113(s0)
    80004d40:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004d44:	001c8c1b          	addiw	s8,s9,1
    80004d48:	001b8793          	addi	a5,s7,1
    80004d4c:	016b8563          	beq	s7,s6,80004d56 <pipewrite+0x118>
    80004d50:	8bbe                	mv	s7,a5
    80004d52:	bf3d                	j	80004c90 <pipewrite+0x52>
    80004d54:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004d56:	21848513          	addi	a0,s1,536
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	78a080e7          	jalr	1930(ra) # 800024e4 <wakeup>
  release(&pi->lock);
    80004d62:	8526                	mv	a0,s1
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	006080e7          	jalr	6(ra) # 80000d6a <release>
  return i;
    80004d6c:	b751                	j	80004cf0 <pipewrite+0xb2>

0000000080004d6e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d6e:	715d                	addi	sp,sp,-80
    80004d70:	e486                	sd	ra,72(sp)
    80004d72:	e0a2                	sd	s0,64(sp)
    80004d74:	fc26                	sd	s1,56(sp)
    80004d76:	f84a                	sd	s2,48(sp)
    80004d78:	f44e                	sd	s3,40(sp)
    80004d7a:	f052                	sd	s4,32(sp)
    80004d7c:	ec56                	sd	s5,24(sp)
    80004d7e:	e85a                	sd	s6,16(sp)
    80004d80:	0880                	addi	s0,sp,80
    80004d82:	84aa                	mv	s1,a0
    80004d84:	89ae                	mv	s3,a1
    80004d86:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d88:	ffffd097          	auipc	ra,0xffffd
    80004d8c:	d3c080e7          	jalr	-708(ra) # 80001ac4 <myproc>
    80004d90:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d92:	8526                	mv	a0,s1
    80004d94:	ffffc097          	auipc	ra,0xffffc
    80004d98:	f22080e7          	jalr	-222(ra) # 80000cb6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d9c:	2184a703          	lw	a4,536(s1)
    80004da0:	21c4a783          	lw	a5,540(s1)
    80004da4:	06f71b63          	bne	a4,a5,80004e1a <piperead+0xac>
    80004da8:	8926                	mv	s2,s1
    80004daa:	2244a783          	lw	a5,548(s1)
    80004dae:	cf9d                	beqz	a5,80004dec <piperead+0x7e>
    if(pr->killed){
    80004db0:	030a2783          	lw	a5,48(s4)
    80004db4:	e78d                	bnez	a5,80004dde <piperead+0x70>
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004db6:	21848b13          	addi	s6,s1,536
    80004dba:	85ca                	mv	a1,s2
    80004dbc:	855a                	mv	a0,s6
    80004dbe:	ffffd097          	auipc	ra,0xffffd
    80004dc2:	5a0080e7          	jalr	1440(ra) # 8000235e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dc6:	2184a703          	lw	a4,536(s1)
    80004dca:	21c4a783          	lw	a5,540(s1)
    80004dce:	04f71663          	bne	a4,a5,80004e1a <piperead+0xac>
    80004dd2:	2244a783          	lw	a5,548(s1)
    80004dd6:	cb99                	beqz	a5,80004dec <piperead+0x7e>
    if(pr->killed){
    80004dd8:	030a2783          	lw	a5,48(s4)
    80004ddc:	dff9                	beqz	a5,80004dba <piperead+0x4c>
      release(&pi->lock);
    80004dde:	8526                	mv	a0,s1
    80004de0:	ffffc097          	auipc	ra,0xffffc
    80004de4:	f8a080e7          	jalr	-118(ra) # 80000d6a <release>
      return -1;
    80004de8:	597d                	li	s2,-1
    80004dea:	a829                	j	80004e04 <piperead+0x96>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    if(pi->nread == pi->nwrite)
    80004dec:	4901                	li	s2,0
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004dee:	21c48513          	addi	a0,s1,540
    80004df2:	ffffd097          	auipc	ra,0xffffd
    80004df6:	6f2080e7          	jalr	1778(ra) # 800024e4 <wakeup>
  release(&pi->lock);
    80004dfa:	8526                	mv	a0,s1
    80004dfc:	ffffc097          	auipc	ra,0xffffc
    80004e00:	f6e080e7          	jalr	-146(ra) # 80000d6a <release>
  return i;
}
    80004e04:	854a                	mv	a0,s2
    80004e06:	60a6                	ld	ra,72(sp)
    80004e08:	6406                	ld	s0,64(sp)
    80004e0a:	74e2                	ld	s1,56(sp)
    80004e0c:	7942                	ld	s2,48(sp)
    80004e0e:	79a2                	ld	s3,40(sp)
    80004e10:	7a02                	ld	s4,32(sp)
    80004e12:	6ae2                	ld	s5,24(sp)
    80004e14:	6b42                	ld	s6,16(sp)
    80004e16:	6161                	addi	sp,sp,80
    80004e18:	8082                	ret
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e1a:	4901                	li	s2,0
    80004e1c:	fd5059e3          	blez	s5,80004dee <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004e20:	2184a783          	lw	a5,536(s1)
    80004e24:	4901                	li	s2,0
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e26:	5b7d                	li	s6,-1
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e28:	0017871b          	addiw	a4,a5,1
    80004e2c:	20e4ac23          	sw	a4,536(s1)
    80004e30:	1ff7f793          	andi	a5,a5,511
    80004e34:	97a6                	add	a5,a5,s1
    80004e36:	0187c783          	lbu	a5,24(a5)
    80004e3a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e3e:	4685                	li	a3,1
    80004e40:	fbf40613          	addi	a2,s0,-65
    80004e44:	85ce                	mv	a1,s3
    80004e46:	050a3503          	ld	a0,80(s4)
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	956080e7          	jalr	-1706(ra) # 800017a0 <copyout>
    80004e52:	f9650ee3          	beq	a0,s6,80004dee <piperead+0x80>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e56:	2905                	addiw	s2,s2,1
    80004e58:	f92a8be3          	beq	s5,s2,80004dee <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004e5c:	2184a783          	lw	a5,536(s1)
    80004e60:	0985                	addi	s3,s3,1
    80004e62:	21c4a703          	lw	a4,540(s1)
    80004e66:	fcf711e3          	bne	a4,a5,80004e28 <piperead+0xba>
    80004e6a:	b751                	j	80004dee <piperead+0x80>

0000000080004e6c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004e6c:	de010113          	addi	sp,sp,-544
    80004e70:	20113c23          	sd	ra,536(sp)
    80004e74:	20813823          	sd	s0,528(sp)
    80004e78:	20913423          	sd	s1,520(sp)
    80004e7c:	21213023          	sd	s2,512(sp)
    80004e80:	ffce                	sd	s3,504(sp)
    80004e82:	fbd2                	sd	s4,496(sp)
    80004e84:	f7d6                	sd	s5,488(sp)
    80004e86:	f3da                	sd	s6,480(sp)
    80004e88:	efde                	sd	s7,472(sp)
    80004e8a:	ebe2                	sd	s8,464(sp)
    80004e8c:	e7e6                	sd	s9,456(sp)
    80004e8e:	e3ea                	sd	s10,448(sp)
    80004e90:	ff6e                	sd	s11,440(sp)
    80004e92:	1400                	addi	s0,sp,544
    80004e94:	892a                	mv	s2,a0
    80004e96:	dea43823          	sd	a0,-528(s0)
    80004e9a:	deb43c23          	sd	a1,-520(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e9e:	ffffd097          	auipc	ra,0xffffd
    80004ea2:	c26080e7          	jalr	-986(ra) # 80001ac4 <myproc>
    80004ea6:	84aa                	mv	s1,a0

  begin_op();
    80004ea8:	fffff097          	auipc	ra,0xfffff
    80004eac:	402080e7          	jalr	1026(ra) # 800042aa <begin_op>

  if((ip = namei(path)) == 0){
    80004eb0:	854a                	mv	a0,s2
    80004eb2:	fffff097          	auipc	ra,0xfffff
    80004eb6:	1ea080e7          	jalr	490(ra) # 8000409c <namei>
    80004eba:	c93d                	beqz	a0,80004f30 <exec+0xc4>
    80004ebc:	892a                	mv	s2,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ebe:	fffff097          	auipc	ra,0xfffff
    80004ec2:	a24080e7          	jalr	-1500(ra) # 800038e2 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ec6:	04000713          	li	a4,64
    80004eca:	4681                	li	a3,0
    80004ecc:	e4840613          	addi	a2,s0,-440
    80004ed0:	4581                	li	a1,0
    80004ed2:	854a                	mv	a0,s2
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	cc4080e7          	jalr	-828(ra) # 80003b98 <readi>
    80004edc:	04000793          	li	a5,64
    80004ee0:	00f51a63          	bne	a0,a5,80004ef4 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004ee4:	e4842703          	lw	a4,-440(s0)
    80004ee8:	464c47b7          	lui	a5,0x464c4
    80004eec:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004ef0:	04f70663          	beq	a4,a5,80004f3c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ef4:	854a                	mv	a0,s2
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	c50080e7          	jalr	-944(ra) # 80003b46 <iunlockput>
    end_op();
    80004efe:	fffff097          	auipc	ra,0xfffff
    80004f02:	42c080e7          	jalr	1068(ra) # 8000432a <end_op>
  }
  return -1;
    80004f06:	557d                	li	a0,-1
}
    80004f08:	21813083          	ld	ra,536(sp)
    80004f0c:	21013403          	ld	s0,528(sp)
    80004f10:	20813483          	ld	s1,520(sp)
    80004f14:	20013903          	ld	s2,512(sp)
    80004f18:	79fe                	ld	s3,504(sp)
    80004f1a:	7a5e                	ld	s4,496(sp)
    80004f1c:	7abe                	ld	s5,488(sp)
    80004f1e:	7b1e                	ld	s6,480(sp)
    80004f20:	6bfe                	ld	s7,472(sp)
    80004f22:	6c5e                	ld	s8,464(sp)
    80004f24:	6cbe                	ld	s9,456(sp)
    80004f26:	6d1e                	ld	s10,448(sp)
    80004f28:	7dfa                	ld	s11,440(sp)
    80004f2a:	22010113          	addi	sp,sp,544
    80004f2e:	8082                	ret
    end_op();
    80004f30:	fffff097          	auipc	ra,0xfffff
    80004f34:	3fa080e7          	jalr	1018(ra) # 8000432a <end_op>
    return -1;
    80004f38:	557d                	li	a0,-1
    80004f3a:	b7f9                	j	80004f08 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f3c:	8526                	mv	a0,s1
    80004f3e:	ffffd097          	auipc	ra,0xffffd
    80004f42:	c4c080e7          	jalr	-948(ra) # 80001b8a <proc_pagetable>
    80004f46:	e0a43423          	sd	a0,-504(s0)
    80004f4a:	d54d                	beqz	a0,80004ef4 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f4c:	e6842983          	lw	s3,-408(s0)
    80004f50:	e8045783          	lhu	a5,-384(s0)
    80004f54:	c7ad                	beqz	a5,80004fbe <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004f56:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f58:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f5a:	6c05                	lui	s8,0x1
    80004f5c:	fffc0793          	addi	a5,s8,-1 # fff <_entry-0x7ffff001>
    80004f60:	def43423          	sd	a5,-536(s0)
    80004f64:	7cfd                	lui	s9,0xfffff
    80004f66:	ac1d                	j	8000519c <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f68:	00003517          	auipc	a0,0x3
    80004f6c:	76850513          	addi	a0,a0,1896 # 800086d0 <syscalls+0x2c8>
    80004f70:	ffffb097          	auipc	ra,0xffffb
    80004f74:	682080e7          	jalr	1666(ra) # 800005f2 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f78:	8756                	mv	a4,s5
    80004f7a:	009d86bb          	addw	a3,s11,s1
    80004f7e:	4581                	li	a1,0
    80004f80:	854a                	mv	a0,s2
    80004f82:	fffff097          	auipc	ra,0xfffff
    80004f86:	c16080e7          	jalr	-1002(ra) # 80003b98 <readi>
    80004f8a:	2501                	sext.w	a0,a0
    80004f8c:	1aaa9e63          	bne	s5,a0,80005148 <exec+0x2dc>
  for(i = 0; i < sz; i += PGSIZE){
    80004f90:	6785                	lui	a5,0x1
    80004f92:	9cbd                	addw	s1,s1,a5
    80004f94:	014c8a3b          	addw	s4,s9,s4
    80004f98:	1f74f963          	bleu	s7,s1,8000518a <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    80004f9c:	02049593          	slli	a1,s1,0x20
    80004fa0:	9181                	srli	a1,a1,0x20
    80004fa2:	95ea                	add	a1,a1,s10
    80004fa4:	e0843503          	ld	a0,-504(s0)
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	1c0080e7          	jalr	448(ra) # 80001168 <walkaddr>
    80004fb0:	862a                	mv	a2,a0
    if(pa == 0)
    80004fb2:	d95d                	beqz	a0,80004f68 <exec+0xfc>
      n = PGSIZE;
    80004fb4:	8ae2                	mv	s5,s8
    if(sz - i < PGSIZE)
    80004fb6:	fd8a71e3          	bleu	s8,s4,80004f78 <exec+0x10c>
      n = sz - i;
    80004fba:	8ad2                	mv	s5,s4
    80004fbc:	bf75                	j	80004f78 <exec+0x10c>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fbe:	4481                	li	s1,0
  iunlockput(ip);
    80004fc0:	854a                	mv	a0,s2
    80004fc2:	fffff097          	auipc	ra,0xfffff
    80004fc6:	b84080e7          	jalr	-1148(ra) # 80003b46 <iunlockput>
  end_op();
    80004fca:	fffff097          	auipc	ra,0xfffff
    80004fce:	360080e7          	jalr	864(ra) # 8000432a <end_op>
  p = myproc();
    80004fd2:	ffffd097          	auipc	ra,0xffffd
    80004fd6:	af2080e7          	jalr	-1294(ra) # 80001ac4 <myproc>
    80004fda:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fdc:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fe0:	6785                	lui	a5,0x1
    80004fe2:	17fd                	addi	a5,a5,-1
    80004fe4:	94be                	add	s1,s1,a5
    80004fe6:	77fd                	lui	a5,0xfffff
    80004fe8:	8fe5                	and	a5,a5,s1
    80004fea:	e0f43023          	sd	a5,-512(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004fee:	6609                	lui	a2,0x2
    80004ff0:	963e                	add	a2,a2,a5
    80004ff2:	85be                	mv	a1,a5
    80004ff4:	e0843483          	ld	s1,-504(s0)
    80004ff8:	8526                	mv	a0,s1
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	556080e7          	jalr	1366(ra) # 80001550 <uvmalloc>
    80005002:	8b2a                	mv	s6,a0
  ip = 0;
    80005004:	4901                	li	s2,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005006:	14050163          	beqz	a0,80005148 <exec+0x2dc>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000500a:	75f9                	lui	a1,0xffffe
    8000500c:	95aa                	add	a1,a1,a0
    8000500e:	8526                	mv	a0,s1
    80005010:	ffffc097          	auipc	ra,0xffffc
    80005014:	75e080e7          	jalr	1886(ra) # 8000176e <uvmclear>
  stackbase = sp - PGSIZE;
    80005018:	7bfd                	lui	s7,0xfffff
    8000501a:	9bda                	add	s7,s7,s6
  for(argc = 0; argv[argc]; argc++) {
    8000501c:	df843783          	ld	a5,-520(s0)
    80005020:	6388                	ld	a0,0(a5)
    80005022:	c925                	beqz	a0,80005092 <exec+0x226>
    80005024:	e8840993          	addi	s3,s0,-376
    80005028:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    8000502c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000502e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005030:	ffffc097          	auipc	ra,0xffffc
    80005034:	f2c080e7          	jalr	-212(ra) # 80000f5c <strlen>
    80005038:	2505                	addiw	a0,a0,1
    8000503a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    8000503e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005042:	13796863          	bltu	s2,s7,80005172 <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005046:	df843c83          	ld	s9,-520(s0)
    8000504a:	000cba03          	ld	s4,0(s9) # fffffffffffff000 <end+0xffffffff7ffd8000>
    8000504e:	8552                	mv	a0,s4
    80005050:	ffffc097          	auipc	ra,0xffffc
    80005054:	f0c080e7          	jalr	-244(ra) # 80000f5c <strlen>
    80005058:	0015069b          	addiw	a3,a0,1
    8000505c:	8652                	mv	a2,s4
    8000505e:	85ca                	mv	a1,s2
    80005060:	e0843503          	ld	a0,-504(s0)
    80005064:	ffffc097          	auipc	ra,0xffffc
    80005068:	73c080e7          	jalr	1852(ra) # 800017a0 <copyout>
    8000506c:	10054763          	bltz	a0,8000517a <exec+0x30e>
    ustack[argc] = sp;
    80005070:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005074:	0485                	addi	s1,s1,1
    80005076:	008c8793          	addi	a5,s9,8
    8000507a:	def43c23          	sd	a5,-520(s0)
    8000507e:	008cb503          	ld	a0,8(s9)
    80005082:	c911                	beqz	a0,80005096 <exec+0x22a>
    if(argc >= MAXARG)
    80005084:	09a1                	addi	s3,s3,8
    80005086:	fb8995e3          	bne	s3,s8,80005030 <exec+0x1c4>
  sz = sz1;
    8000508a:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    8000508e:	4901                	li	s2,0
    80005090:	a865                	j	80005148 <exec+0x2dc>
  sp = sz;
    80005092:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005094:	4481                	li	s1,0
  ustack[argc] = 0;
    80005096:	00349793          	slli	a5,s1,0x3
    8000509a:	f9040713          	addi	a4,s0,-112
    8000509e:	97ba                	add	a5,a5,a4
    800050a0:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ef8>
  sp -= (argc+1) * sizeof(uint64);
    800050a4:	00148693          	addi	a3,s1,1
    800050a8:	068e                	slli	a3,a3,0x3
    800050aa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050ae:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050b2:	01797663          	bleu	s7,s2,800050be <exec+0x252>
  sz = sz1;
    800050b6:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    800050ba:	4901                	li	s2,0
    800050bc:	a071                	j	80005148 <exec+0x2dc>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050be:	e8840613          	addi	a2,s0,-376
    800050c2:	85ca                	mv	a1,s2
    800050c4:	e0843503          	ld	a0,-504(s0)
    800050c8:	ffffc097          	auipc	ra,0xffffc
    800050cc:	6d8080e7          	jalr	1752(ra) # 800017a0 <copyout>
    800050d0:	0a054963          	bltz	a0,80005182 <exec+0x316>
  p->trapframe->a1 = sp;
    800050d4:	058ab783          	ld	a5,88(s5)
    800050d8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050dc:	df043783          	ld	a5,-528(s0)
    800050e0:	0007c703          	lbu	a4,0(a5)
    800050e4:	cf11                	beqz	a4,80005100 <exec+0x294>
    800050e6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050e8:	02f00693          	li	a3,47
    800050ec:	a029                	j	800050f6 <exec+0x28a>
  for(last=s=path; *s; s++)
    800050ee:	0785                	addi	a5,a5,1
    800050f0:	fff7c703          	lbu	a4,-1(a5)
    800050f4:	c711                	beqz	a4,80005100 <exec+0x294>
    if(*s == '/')
    800050f6:	fed71ce3          	bne	a4,a3,800050ee <exec+0x282>
      last = s+1;
    800050fa:	def43823          	sd	a5,-528(s0)
    800050fe:	bfc5                	j	800050ee <exec+0x282>
  safestrcpy(p->name, last, sizeof(p->name));
    80005100:	4641                	li	a2,16
    80005102:	df043583          	ld	a1,-528(s0)
    80005106:	158a8513          	addi	a0,s5,344
    8000510a:	ffffc097          	auipc	ra,0xffffc
    8000510e:	e20080e7          	jalr	-480(ra) # 80000f2a <safestrcpy>
  oldpagetable = p->pagetable;
    80005112:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005116:	e0843783          	ld	a5,-504(s0)
    8000511a:	04fab823          	sd	a5,80(s5)
  p->sz = sz;
    8000511e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005122:	058ab783          	ld	a5,88(s5)
    80005126:	e6043703          	ld	a4,-416(s0)
    8000512a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000512c:	058ab783          	ld	a5,88(s5)
    80005130:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005134:	85ea                	mv	a1,s10
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	af0080e7          	jalr	-1296(ra) # 80001c26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000513e:	0004851b          	sext.w	a0,s1
    80005142:	b3d9                	j	80004f08 <exec+0x9c>
    80005144:	e0943023          	sd	s1,-512(s0)
    proc_freepagetable(pagetable, sz);
    80005148:	e0043583          	ld	a1,-512(s0)
    8000514c:	e0843503          	ld	a0,-504(s0)
    80005150:	ffffd097          	auipc	ra,0xffffd
    80005154:	ad6080e7          	jalr	-1322(ra) # 80001c26 <proc_freepagetable>
  if(ip){
    80005158:	d8091ee3          	bnez	s2,80004ef4 <exec+0x88>
  return -1;
    8000515c:	557d                	li	a0,-1
    8000515e:	b36d                	j	80004f08 <exec+0x9c>
    80005160:	e0943023          	sd	s1,-512(s0)
    80005164:	b7d5                	j	80005148 <exec+0x2dc>
    80005166:	e0943023          	sd	s1,-512(s0)
    8000516a:	bff9                	j	80005148 <exec+0x2dc>
    8000516c:	e0943023          	sd	s1,-512(s0)
    80005170:	bfe1                	j	80005148 <exec+0x2dc>
  sz = sz1;
    80005172:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005176:	4901                	li	s2,0
    80005178:	bfc1                	j	80005148 <exec+0x2dc>
  sz = sz1;
    8000517a:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    8000517e:	4901                	li	s2,0
    80005180:	b7e1                	j	80005148 <exec+0x2dc>
  sz = sz1;
    80005182:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005186:	4901                	li	s2,0
    80005188:	b7c1                	j	80005148 <exec+0x2dc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000518a:	e0043483          	ld	s1,-512(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000518e:	2b05                	addiw	s6,s6,1
    80005190:	0389899b          	addiw	s3,s3,56
    80005194:	e8045783          	lhu	a5,-384(s0)
    80005198:	e2fb54e3          	ble	a5,s6,80004fc0 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000519c:	2981                	sext.w	s3,s3
    8000519e:	03800713          	li	a4,56
    800051a2:	86ce                	mv	a3,s3
    800051a4:	e1040613          	addi	a2,s0,-496
    800051a8:	4581                	li	a1,0
    800051aa:	854a                	mv	a0,s2
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	9ec080e7          	jalr	-1556(ra) # 80003b98 <readi>
    800051b4:	03800793          	li	a5,56
    800051b8:	f8f516e3          	bne	a0,a5,80005144 <exec+0x2d8>
    if(ph.type != ELF_PROG_LOAD)
    800051bc:	e1042783          	lw	a5,-496(s0)
    800051c0:	4705                	li	a4,1
    800051c2:	fce796e3          	bne	a5,a4,8000518e <exec+0x322>
    if(ph.memsz < ph.filesz)
    800051c6:	e3843603          	ld	a2,-456(s0)
    800051ca:	e3043783          	ld	a5,-464(s0)
    800051ce:	f8f669e3          	bltu	a2,a5,80005160 <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051d2:	e2043783          	ld	a5,-480(s0)
    800051d6:	963e                	add	a2,a2,a5
    800051d8:	f8f667e3          	bltu	a2,a5,80005166 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800051dc:	85a6                	mv	a1,s1
    800051de:	e0843503          	ld	a0,-504(s0)
    800051e2:	ffffc097          	auipc	ra,0xffffc
    800051e6:	36e080e7          	jalr	878(ra) # 80001550 <uvmalloc>
    800051ea:	e0a43023          	sd	a0,-512(s0)
    800051ee:	dd3d                	beqz	a0,8000516c <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    800051f0:	e2043d03          	ld	s10,-480(s0)
    800051f4:	de843783          	ld	a5,-536(s0)
    800051f8:	00fd77b3          	and	a5,s10,a5
    800051fc:	f7b1                	bnez	a5,80005148 <exec+0x2dc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051fe:	e1842d83          	lw	s11,-488(s0)
    80005202:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005206:	f80b82e3          	beqz	s7,8000518a <exec+0x31e>
    8000520a:	8a5e                	mv	s4,s7
    8000520c:	4481                	li	s1,0
    8000520e:	b379                	j	80004f9c <exec+0x130>

0000000080005210 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005210:	7179                	addi	sp,sp,-48
    80005212:	f406                	sd	ra,40(sp)
    80005214:	f022                	sd	s0,32(sp)
    80005216:	ec26                	sd	s1,24(sp)
    80005218:	e84a                	sd	s2,16(sp)
    8000521a:	1800                	addi	s0,sp,48
    8000521c:	892e                	mv	s2,a1
    8000521e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005220:	fdc40593          	addi	a1,s0,-36
    80005224:	ffffe097          	auipc	ra,0xffffe
    80005228:	a50080e7          	jalr	-1456(ra) # 80002c74 <argint>
    8000522c:	04054063          	bltz	a0,8000526c <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005230:	fdc42703          	lw	a4,-36(s0)
    80005234:	47bd                	li	a5,15
    80005236:	02e7ed63          	bltu	a5,a4,80005270 <argfd+0x60>
    8000523a:	ffffd097          	auipc	ra,0xffffd
    8000523e:	88a080e7          	jalr	-1910(ra) # 80001ac4 <myproc>
    80005242:	fdc42703          	lw	a4,-36(s0)
    80005246:	01a70793          	addi	a5,a4,26
    8000524a:	078e                	slli	a5,a5,0x3
    8000524c:	953e                	add	a0,a0,a5
    8000524e:	611c                	ld	a5,0(a0)
    80005250:	c395                	beqz	a5,80005274 <argfd+0x64>
    return -1;
  if(pfd)
    80005252:	00090463          	beqz	s2,8000525a <argfd+0x4a>
    *pfd = fd;
    80005256:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000525a:	4501                	li	a0,0
  if(pf)
    8000525c:	c091                	beqz	s1,80005260 <argfd+0x50>
    *pf = f;
    8000525e:	e09c                	sd	a5,0(s1)
}
    80005260:	70a2                	ld	ra,40(sp)
    80005262:	7402                	ld	s0,32(sp)
    80005264:	64e2                	ld	s1,24(sp)
    80005266:	6942                	ld	s2,16(sp)
    80005268:	6145                	addi	sp,sp,48
    8000526a:	8082                	ret
    return -1;
    8000526c:	557d                	li	a0,-1
    8000526e:	bfcd                	j	80005260 <argfd+0x50>
    return -1;
    80005270:	557d                	li	a0,-1
    80005272:	b7fd                	j	80005260 <argfd+0x50>
    80005274:	557d                	li	a0,-1
    80005276:	b7ed                	j	80005260 <argfd+0x50>

0000000080005278 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005278:	1101                	addi	sp,sp,-32
    8000527a:	ec06                	sd	ra,24(sp)
    8000527c:	e822                	sd	s0,16(sp)
    8000527e:	e426                	sd	s1,8(sp)
    80005280:	1000                	addi	s0,sp,32
    80005282:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005284:	ffffd097          	auipc	ra,0xffffd
    80005288:	840080e7          	jalr	-1984(ra) # 80001ac4 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){
    8000528c:	697c                	ld	a5,208(a0)
    8000528e:	c395                	beqz	a5,800052b2 <fdalloc+0x3a>
    80005290:	0d850713          	addi	a4,a0,216
  for(fd = 0; fd < NOFILE; fd++){
    80005294:	4785                	li	a5,1
    80005296:	4641                	li	a2,16
    if(p->ofile[fd] == 0){
    80005298:	6314                	ld	a3,0(a4)
    8000529a:	ce89                	beqz	a3,800052b4 <fdalloc+0x3c>
  for(fd = 0; fd < NOFILE; fd++){
    8000529c:	2785                	addiw	a5,a5,1
    8000529e:	0721                	addi	a4,a4,8
    800052a0:	fec79ce3          	bne	a5,a2,80005298 <fdalloc+0x20>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052a4:	57fd                	li	a5,-1
}
    800052a6:	853e                	mv	a0,a5
    800052a8:	60e2                	ld	ra,24(sp)
    800052aa:	6442                	ld	s0,16(sp)
    800052ac:	64a2                	ld	s1,8(sp)
    800052ae:	6105                	addi	sp,sp,32
    800052b0:	8082                	ret
  for(fd = 0; fd < NOFILE; fd++){
    800052b2:	4781                	li	a5,0
      p->ofile[fd] = f;
    800052b4:	01a78713          	addi	a4,a5,26
    800052b8:	070e                	slli	a4,a4,0x3
    800052ba:	953a                	add	a0,a0,a4
    800052bc:	e104                	sd	s1,0(a0)
      return fd;
    800052be:	b7e5                	j	800052a6 <fdalloc+0x2e>

00000000800052c0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052c0:	715d                	addi	sp,sp,-80
    800052c2:	e486                	sd	ra,72(sp)
    800052c4:	e0a2                	sd	s0,64(sp)
    800052c6:	fc26                	sd	s1,56(sp)
    800052c8:	f84a                	sd	s2,48(sp)
    800052ca:	f44e                	sd	s3,40(sp)
    800052cc:	f052                	sd	s4,32(sp)
    800052ce:	ec56                	sd	s5,24(sp)
    800052d0:	0880                	addi	s0,sp,80
    800052d2:	89ae                	mv	s3,a1
    800052d4:	8ab2                	mv	s5,a2
    800052d6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052d8:	fb040593          	addi	a1,s0,-80
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	dde080e7          	jalr	-546(ra) # 800040ba <nameiparent>
    800052e4:	892a                	mv	s2,a0
    800052e6:	12050f63          	beqz	a0,80005424 <create+0x164>
    return 0;

  ilock(dp);
    800052ea:	ffffe097          	auipc	ra,0xffffe
    800052ee:	5f8080e7          	jalr	1528(ra) # 800038e2 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052f2:	4601                	li	a2,0
    800052f4:	fb040593          	addi	a1,s0,-80
    800052f8:	854a                	mv	a0,s2
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	ac8080e7          	jalr	-1336(ra) # 80003dc2 <dirlookup>
    80005302:	84aa                	mv	s1,a0
    80005304:	c921                	beqz	a0,80005354 <create+0x94>
    iunlockput(dp);
    80005306:	854a                	mv	a0,s2
    80005308:	fffff097          	auipc	ra,0xfffff
    8000530c:	83e080e7          	jalr	-1986(ra) # 80003b46 <iunlockput>
    ilock(ip);
    80005310:	8526                	mv	a0,s1
    80005312:	ffffe097          	auipc	ra,0xffffe
    80005316:	5d0080e7          	jalr	1488(ra) # 800038e2 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000531a:	2981                	sext.w	s3,s3
    8000531c:	4789                	li	a5,2
    8000531e:	02f99463          	bne	s3,a5,80005346 <create+0x86>
    80005322:	0444d783          	lhu	a5,68(s1)
    80005326:	37f9                	addiw	a5,a5,-2
    80005328:	17c2                	slli	a5,a5,0x30
    8000532a:	93c1                	srli	a5,a5,0x30
    8000532c:	4705                	li	a4,1
    8000532e:	00f76c63          	bltu	a4,a5,80005346 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005332:	8526                	mv	a0,s1
    80005334:	60a6                	ld	ra,72(sp)
    80005336:	6406                	ld	s0,64(sp)
    80005338:	74e2                	ld	s1,56(sp)
    8000533a:	7942                	ld	s2,48(sp)
    8000533c:	79a2                	ld	s3,40(sp)
    8000533e:	7a02                	ld	s4,32(sp)
    80005340:	6ae2                	ld	s5,24(sp)
    80005342:	6161                	addi	sp,sp,80
    80005344:	8082                	ret
    iunlockput(ip);
    80005346:	8526                	mv	a0,s1
    80005348:	ffffe097          	auipc	ra,0xffffe
    8000534c:	7fe080e7          	jalr	2046(ra) # 80003b46 <iunlockput>
    return 0;
    80005350:	4481                	li	s1,0
    80005352:	b7c5                	j	80005332 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005354:	85ce                	mv	a1,s3
    80005356:	00092503          	lw	a0,0(s2)
    8000535a:	ffffe097          	auipc	ra,0xffffe
    8000535e:	3ec080e7          	jalr	1004(ra) # 80003746 <ialloc>
    80005362:	84aa                	mv	s1,a0
    80005364:	c529                	beqz	a0,800053ae <create+0xee>
  ilock(ip);
    80005366:	ffffe097          	auipc	ra,0xffffe
    8000536a:	57c080e7          	jalr	1404(ra) # 800038e2 <ilock>
  ip->major = major;
    8000536e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005372:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005376:	4785                	li	a5,1
    80005378:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000537c:	8526                	mv	a0,s1
    8000537e:	ffffe097          	auipc	ra,0xffffe
    80005382:	498080e7          	jalr	1176(ra) # 80003816 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005386:	2981                	sext.w	s3,s3
    80005388:	4785                	li	a5,1
    8000538a:	02f98a63          	beq	s3,a5,800053be <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000538e:	40d0                	lw	a2,4(s1)
    80005390:	fb040593          	addi	a1,s0,-80
    80005394:	854a                	mv	a0,s2
    80005396:	fffff097          	auipc	ra,0xfffff
    8000539a:	c44080e7          	jalr	-956(ra) # 80003fda <dirlink>
    8000539e:	06054b63          	bltz	a0,80005414 <create+0x154>
  iunlockput(dp);
    800053a2:	854a                	mv	a0,s2
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	7a2080e7          	jalr	1954(ra) # 80003b46 <iunlockput>
  return ip;
    800053ac:	b759                	j	80005332 <create+0x72>
    panic("create: ialloc");
    800053ae:	00003517          	auipc	a0,0x3
    800053b2:	34250513          	addi	a0,a0,834 # 800086f0 <syscalls+0x2e8>
    800053b6:	ffffb097          	auipc	ra,0xffffb
    800053ba:	23c080e7          	jalr	572(ra) # 800005f2 <panic>
    dp->nlink++;  // for ".."
    800053be:	04a95783          	lhu	a5,74(s2)
    800053c2:	2785                	addiw	a5,a5,1
    800053c4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800053c8:	854a                	mv	a0,s2
    800053ca:	ffffe097          	auipc	ra,0xffffe
    800053ce:	44c080e7          	jalr	1100(ra) # 80003816 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053d2:	40d0                	lw	a2,4(s1)
    800053d4:	00003597          	auipc	a1,0x3
    800053d8:	32c58593          	addi	a1,a1,812 # 80008700 <syscalls+0x2f8>
    800053dc:	8526                	mv	a0,s1
    800053de:	fffff097          	auipc	ra,0xfffff
    800053e2:	bfc080e7          	jalr	-1028(ra) # 80003fda <dirlink>
    800053e6:	00054f63          	bltz	a0,80005404 <create+0x144>
    800053ea:	00492603          	lw	a2,4(s2)
    800053ee:	00003597          	auipc	a1,0x3
    800053f2:	31a58593          	addi	a1,a1,794 # 80008708 <syscalls+0x300>
    800053f6:	8526                	mv	a0,s1
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	be2080e7          	jalr	-1054(ra) # 80003fda <dirlink>
    80005400:	f80557e3          	bgez	a0,8000538e <create+0xce>
      panic("create dots");
    80005404:	00003517          	auipc	a0,0x3
    80005408:	30c50513          	addi	a0,a0,780 # 80008710 <syscalls+0x308>
    8000540c:	ffffb097          	auipc	ra,0xffffb
    80005410:	1e6080e7          	jalr	486(ra) # 800005f2 <panic>
    panic("create: dirlink");
    80005414:	00003517          	auipc	a0,0x3
    80005418:	30c50513          	addi	a0,a0,780 # 80008720 <syscalls+0x318>
    8000541c:	ffffb097          	auipc	ra,0xffffb
    80005420:	1d6080e7          	jalr	470(ra) # 800005f2 <panic>
    return 0;
    80005424:	84aa                	mv	s1,a0
    80005426:	b731                	j	80005332 <create+0x72>

0000000080005428 <sys_dup>:
{
    80005428:	7179                	addi	sp,sp,-48
    8000542a:	f406                	sd	ra,40(sp)
    8000542c:	f022                	sd	s0,32(sp)
    8000542e:	ec26                	sd	s1,24(sp)
    80005430:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005432:	fd840613          	addi	a2,s0,-40
    80005436:	4581                	li	a1,0
    80005438:	4501                	li	a0,0
    8000543a:	00000097          	auipc	ra,0x0
    8000543e:	dd6080e7          	jalr	-554(ra) # 80005210 <argfd>
    return -1;
    80005442:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005444:	02054363          	bltz	a0,8000546a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005448:	fd843503          	ld	a0,-40(s0)
    8000544c:	00000097          	auipc	ra,0x0
    80005450:	e2c080e7          	jalr	-468(ra) # 80005278 <fdalloc>
    80005454:	84aa                	mv	s1,a0
    return -1;
    80005456:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005458:	00054963          	bltz	a0,8000546a <sys_dup+0x42>
  filedup(f);
    8000545c:	fd843503          	ld	a0,-40(s0)
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	2fa080e7          	jalr	762(ra) # 8000475a <filedup>
  return fd;
    80005468:	87a6                	mv	a5,s1
}
    8000546a:	853e                	mv	a0,a5
    8000546c:	70a2                	ld	ra,40(sp)
    8000546e:	7402                	ld	s0,32(sp)
    80005470:	64e2                	ld	s1,24(sp)
    80005472:	6145                	addi	sp,sp,48
    80005474:	8082                	ret

0000000080005476 <sys_read>:
{
    80005476:	7179                	addi	sp,sp,-48
    80005478:	f406                	sd	ra,40(sp)
    8000547a:	f022                	sd	s0,32(sp)
    8000547c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000547e:	fe840613          	addi	a2,s0,-24
    80005482:	4581                	li	a1,0
    80005484:	4501                	li	a0,0
    80005486:	00000097          	auipc	ra,0x0
    8000548a:	d8a080e7          	jalr	-630(ra) # 80005210 <argfd>
    return -1;
    8000548e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005490:	04054163          	bltz	a0,800054d2 <sys_read+0x5c>
    80005494:	fe440593          	addi	a1,s0,-28
    80005498:	4509                	li	a0,2
    8000549a:	ffffd097          	auipc	ra,0xffffd
    8000549e:	7da080e7          	jalr	2010(ra) # 80002c74 <argint>
    return -1;
    800054a2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054a4:	02054763          	bltz	a0,800054d2 <sys_read+0x5c>
    800054a8:	fd840593          	addi	a1,s0,-40
    800054ac:	4505                	li	a0,1
    800054ae:	ffffd097          	auipc	ra,0xffffd
    800054b2:	7e8080e7          	jalr	2024(ra) # 80002c96 <argaddr>
    return -1;
    800054b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054b8:	00054d63          	bltz	a0,800054d2 <sys_read+0x5c>
  return fileread(f, p, n);
    800054bc:	fe442603          	lw	a2,-28(s0)
    800054c0:	fd843583          	ld	a1,-40(s0)
    800054c4:	fe843503          	ld	a0,-24(s0)
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	41e080e7          	jalr	1054(ra) # 800048e6 <fileread>
    800054d0:	87aa                	mv	a5,a0
}
    800054d2:	853e                	mv	a0,a5
    800054d4:	70a2                	ld	ra,40(sp)
    800054d6:	7402                	ld	s0,32(sp)
    800054d8:	6145                	addi	sp,sp,48
    800054da:	8082                	ret

00000000800054dc <sys_write>:
{
    800054dc:	7179                	addi	sp,sp,-48
    800054de:	f406                	sd	ra,40(sp)
    800054e0:	f022                	sd	s0,32(sp)
    800054e2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054e4:	fe840613          	addi	a2,s0,-24
    800054e8:	4581                	li	a1,0
    800054ea:	4501                	li	a0,0
    800054ec:	00000097          	auipc	ra,0x0
    800054f0:	d24080e7          	jalr	-732(ra) # 80005210 <argfd>
    return -1;
    800054f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800054f6:	04054163          	bltz	a0,80005538 <sys_write+0x5c>
    800054fa:	fe440593          	addi	a1,s0,-28
    800054fe:	4509                	li	a0,2
    80005500:	ffffd097          	auipc	ra,0xffffd
    80005504:	774080e7          	jalr	1908(ra) # 80002c74 <argint>
    return -1;
    80005508:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000550a:	02054763          	bltz	a0,80005538 <sys_write+0x5c>
    8000550e:	fd840593          	addi	a1,s0,-40
    80005512:	4505                	li	a0,1
    80005514:	ffffd097          	auipc	ra,0xffffd
    80005518:	782080e7          	jalr	1922(ra) # 80002c96 <argaddr>
    return -1;
    8000551c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000551e:	00054d63          	bltz	a0,80005538 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005522:	fe442603          	lw	a2,-28(s0)
    80005526:	fd843583          	ld	a1,-40(s0)
    8000552a:	fe843503          	ld	a0,-24(s0)
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	47a080e7          	jalr	1146(ra) # 800049a8 <filewrite>
    80005536:	87aa                	mv	a5,a0
}
    80005538:	853e                	mv	a0,a5
    8000553a:	70a2                	ld	ra,40(sp)
    8000553c:	7402                	ld	s0,32(sp)
    8000553e:	6145                	addi	sp,sp,48
    80005540:	8082                	ret

0000000080005542 <sys_close>:
{
    80005542:	1101                	addi	sp,sp,-32
    80005544:	ec06                	sd	ra,24(sp)
    80005546:	e822                	sd	s0,16(sp)
    80005548:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000554a:	fe040613          	addi	a2,s0,-32
    8000554e:	fec40593          	addi	a1,s0,-20
    80005552:	4501                	li	a0,0
    80005554:	00000097          	auipc	ra,0x0
    80005558:	cbc080e7          	jalr	-836(ra) # 80005210 <argfd>
    return -1;
    8000555c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000555e:	02054463          	bltz	a0,80005586 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005562:	ffffc097          	auipc	ra,0xffffc
    80005566:	562080e7          	jalr	1378(ra) # 80001ac4 <myproc>
    8000556a:	fec42783          	lw	a5,-20(s0)
    8000556e:	07e9                	addi	a5,a5,26
    80005570:	078e                	slli	a5,a5,0x3
    80005572:	953e                	add	a0,a0,a5
    80005574:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005578:	fe043503          	ld	a0,-32(s0)
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	230080e7          	jalr	560(ra) # 800047ac <fileclose>
  return 0;
    80005584:	4781                	li	a5,0
}
    80005586:	853e                	mv	a0,a5
    80005588:	60e2                	ld	ra,24(sp)
    8000558a:	6442                	ld	s0,16(sp)
    8000558c:	6105                	addi	sp,sp,32
    8000558e:	8082                	ret

0000000080005590 <sys_fstat>:
{
    80005590:	1101                	addi	sp,sp,-32
    80005592:	ec06                	sd	ra,24(sp)
    80005594:	e822                	sd	s0,16(sp)
    80005596:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005598:	fe840613          	addi	a2,s0,-24
    8000559c:	4581                	li	a1,0
    8000559e:	4501                	li	a0,0
    800055a0:	00000097          	auipc	ra,0x0
    800055a4:	c70080e7          	jalr	-912(ra) # 80005210 <argfd>
    return -1;
    800055a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055aa:	02054563          	bltz	a0,800055d4 <sys_fstat+0x44>
    800055ae:	fe040593          	addi	a1,s0,-32
    800055b2:	4505                	li	a0,1
    800055b4:	ffffd097          	auipc	ra,0xffffd
    800055b8:	6e2080e7          	jalr	1762(ra) # 80002c96 <argaddr>
    return -1;
    800055bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800055be:	00054b63          	bltz	a0,800055d4 <sys_fstat+0x44>
  return filestat(f, st);
    800055c2:	fe043583          	ld	a1,-32(s0)
    800055c6:	fe843503          	ld	a0,-24(s0)
    800055ca:	fffff097          	auipc	ra,0xfffff
    800055ce:	2aa080e7          	jalr	682(ra) # 80004874 <filestat>
    800055d2:	87aa                	mv	a5,a0
}
    800055d4:	853e                	mv	a0,a5
    800055d6:	60e2                	ld	ra,24(sp)
    800055d8:	6442                	ld	s0,16(sp)
    800055da:	6105                	addi	sp,sp,32
    800055dc:	8082                	ret

00000000800055de <sys_link>:
{
    800055de:	7169                	addi	sp,sp,-304
    800055e0:	f606                	sd	ra,296(sp)
    800055e2:	f222                	sd	s0,288(sp)
    800055e4:	ee26                	sd	s1,280(sp)
    800055e6:	ea4a                	sd	s2,272(sp)
    800055e8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ea:	08000613          	li	a2,128
    800055ee:	ed040593          	addi	a1,s0,-304
    800055f2:	4501                	li	a0,0
    800055f4:	ffffd097          	auipc	ra,0xffffd
    800055f8:	6c4080e7          	jalr	1732(ra) # 80002cb8 <argstr>
    return -1;
    800055fc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055fe:	10054e63          	bltz	a0,8000571a <sys_link+0x13c>
    80005602:	08000613          	li	a2,128
    80005606:	f5040593          	addi	a1,s0,-176
    8000560a:	4505                	li	a0,1
    8000560c:	ffffd097          	auipc	ra,0xffffd
    80005610:	6ac080e7          	jalr	1708(ra) # 80002cb8 <argstr>
    return -1;
    80005614:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005616:	10054263          	bltz	a0,8000571a <sys_link+0x13c>
  begin_op();
    8000561a:	fffff097          	auipc	ra,0xfffff
    8000561e:	c90080e7          	jalr	-880(ra) # 800042aa <begin_op>
  if((ip = namei(old)) == 0){
    80005622:	ed040513          	addi	a0,s0,-304
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	a76080e7          	jalr	-1418(ra) # 8000409c <namei>
    8000562e:	84aa                	mv	s1,a0
    80005630:	c551                	beqz	a0,800056bc <sys_link+0xde>
  ilock(ip);
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	2b0080e7          	jalr	688(ra) # 800038e2 <ilock>
  if(ip->type == T_DIR){
    8000563a:	04449703          	lh	a4,68(s1)
    8000563e:	4785                	li	a5,1
    80005640:	08f70463          	beq	a4,a5,800056c8 <sys_link+0xea>
  ip->nlink++;
    80005644:	04a4d783          	lhu	a5,74(s1)
    80005648:	2785                	addiw	a5,a5,1
    8000564a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000564e:	8526                	mv	a0,s1
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	1c6080e7          	jalr	454(ra) # 80003816 <iupdate>
  iunlock(ip);
    80005658:	8526                	mv	a0,s1
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	34c080e7          	jalr	844(ra) # 800039a6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005662:	fd040593          	addi	a1,s0,-48
    80005666:	f5040513          	addi	a0,s0,-176
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	a50080e7          	jalr	-1456(ra) # 800040ba <nameiparent>
    80005672:	892a                	mv	s2,a0
    80005674:	c935                	beqz	a0,800056e8 <sys_link+0x10a>
  ilock(dp);
    80005676:	ffffe097          	auipc	ra,0xffffe
    8000567a:	26c080e7          	jalr	620(ra) # 800038e2 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000567e:	00092703          	lw	a4,0(s2)
    80005682:	409c                	lw	a5,0(s1)
    80005684:	04f71d63          	bne	a4,a5,800056de <sys_link+0x100>
    80005688:	40d0                	lw	a2,4(s1)
    8000568a:	fd040593          	addi	a1,s0,-48
    8000568e:	854a                	mv	a0,s2
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	94a080e7          	jalr	-1718(ra) # 80003fda <dirlink>
    80005698:	04054363          	bltz	a0,800056de <sys_link+0x100>
  iunlockput(dp);
    8000569c:	854a                	mv	a0,s2
    8000569e:	ffffe097          	auipc	ra,0xffffe
    800056a2:	4a8080e7          	jalr	1192(ra) # 80003b46 <iunlockput>
  iput(ip);
    800056a6:	8526                	mv	a0,s1
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	3f6080e7          	jalr	1014(ra) # 80003a9e <iput>
  end_op();
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	c7a080e7          	jalr	-902(ra) # 8000432a <end_op>
  return 0;
    800056b8:	4781                	li	a5,0
    800056ba:	a085                	j	8000571a <sys_link+0x13c>
    end_op();
    800056bc:	fffff097          	auipc	ra,0xfffff
    800056c0:	c6e080e7          	jalr	-914(ra) # 8000432a <end_op>
    return -1;
    800056c4:	57fd                	li	a5,-1
    800056c6:	a891                	j	8000571a <sys_link+0x13c>
    iunlockput(ip);
    800056c8:	8526                	mv	a0,s1
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	47c080e7          	jalr	1148(ra) # 80003b46 <iunlockput>
    end_op();
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	c58080e7          	jalr	-936(ra) # 8000432a <end_op>
    return -1;
    800056da:	57fd                	li	a5,-1
    800056dc:	a83d                	j	8000571a <sys_link+0x13c>
    iunlockput(dp);
    800056de:	854a                	mv	a0,s2
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	466080e7          	jalr	1126(ra) # 80003b46 <iunlockput>
  ilock(ip);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	1f8080e7          	jalr	504(ra) # 800038e2 <ilock>
  ip->nlink--;
    800056f2:	04a4d783          	lhu	a5,74(s1)
    800056f6:	37fd                	addiw	a5,a5,-1
    800056f8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056fc:	8526                	mv	a0,s1
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	118080e7          	jalr	280(ra) # 80003816 <iupdate>
  iunlockput(ip);
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	43e080e7          	jalr	1086(ra) # 80003b46 <iunlockput>
  end_op();
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	c1a080e7          	jalr	-998(ra) # 8000432a <end_op>
  return -1;
    80005718:	57fd                	li	a5,-1
}
    8000571a:	853e                	mv	a0,a5
    8000571c:	70b2                	ld	ra,296(sp)
    8000571e:	7412                	ld	s0,288(sp)
    80005720:	64f2                	ld	s1,280(sp)
    80005722:	6952                	ld	s2,272(sp)
    80005724:	6155                	addi	sp,sp,304
    80005726:	8082                	ret

0000000080005728 <sys_unlink>:
{
    80005728:	7151                	addi	sp,sp,-240
    8000572a:	f586                	sd	ra,232(sp)
    8000572c:	f1a2                	sd	s0,224(sp)
    8000572e:	eda6                	sd	s1,216(sp)
    80005730:	e9ca                	sd	s2,208(sp)
    80005732:	e5ce                	sd	s3,200(sp)
    80005734:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005736:	08000613          	li	a2,128
    8000573a:	f3040593          	addi	a1,s0,-208
    8000573e:	4501                	li	a0,0
    80005740:	ffffd097          	auipc	ra,0xffffd
    80005744:	578080e7          	jalr	1400(ra) # 80002cb8 <argstr>
    80005748:	16054f63          	bltz	a0,800058c6 <sys_unlink+0x19e>
  begin_op();
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	b5e080e7          	jalr	-1186(ra) # 800042aa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005754:	fb040593          	addi	a1,s0,-80
    80005758:	f3040513          	addi	a0,s0,-208
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	95e080e7          	jalr	-1698(ra) # 800040ba <nameiparent>
    80005764:	89aa                	mv	s3,a0
    80005766:	c979                	beqz	a0,8000583c <sys_unlink+0x114>
  ilock(dp);
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	17a080e7          	jalr	378(ra) # 800038e2 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005770:	00003597          	auipc	a1,0x3
    80005774:	f9058593          	addi	a1,a1,-112 # 80008700 <syscalls+0x2f8>
    80005778:	fb040513          	addi	a0,s0,-80
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	62c080e7          	jalr	1580(ra) # 80003da8 <namecmp>
    80005784:	14050863          	beqz	a0,800058d4 <sys_unlink+0x1ac>
    80005788:	00003597          	auipc	a1,0x3
    8000578c:	f8058593          	addi	a1,a1,-128 # 80008708 <syscalls+0x300>
    80005790:	fb040513          	addi	a0,s0,-80
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	614080e7          	jalr	1556(ra) # 80003da8 <namecmp>
    8000579c:	12050c63          	beqz	a0,800058d4 <sys_unlink+0x1ac>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057a0:	f2c40613          	addi	a2,s0,-212
    800057a4:	fb040593          	addi	a1,s0,-80
    800057a8:	854e                	mv	a0,s3
    800057aa:	ffffe097          	auipc	ra,0xffffe
    800057ae:	618080e7          	jalr	1560(ra) # 80003dc2 <dirlookup>
    800057b2:	84aa                	mv	s1,a0
    800057b4:	12050063          	beqz	a0,800058d4 <sys_unlink+0x1ac>
  ilock(ip);
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	12a080e7          	jalr	298(ra) # 800038e2 <ilock>
  if(ip->nlink < 1)
    800057c0:	04a49783          	lh	a5,74(s1)
    800057c4:	08f05263          	blez	a5,80005848 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057c8:	04449703          	lh	a4,68(s1)
    800057cc:	4785                	li	a5,1
    800057ce:	08f70563          	beq	a4,a5,80005858 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057d2:	4641                	li	a2,16
    800057d4:	4581                	li	a1,0
    800057d6:	fc040513          	addi	a0,s0,-64
    800057da:	ffffb097          	auipc	ra,0xffffb
    800057de:	5d8080e7          	jalr	1496(ra) # 80000db2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057e2:	4741                	li	a4,16
    800057e4:	f2c42683          	lw	a3,-212(s0)
    800057e8:	fc040613          	addi	a2,s0,-64
    800057ec:	4581                	li	a1,0
    800057ee:	854e                	mv	a0,s3
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	49e080e7          	jalr	1182(ra) # 80003c8e <writei>
    800057f8:	47c1                	li	a5,16
    800057fa:	0af51363          	bne	a0,a5,800058a0 <sys_unlink+0x178>
  if(ip->type == T_DIR){
    800057fe:	04449703          	lh	a4,68(s1)
    80005802:	4785                	li	a5,1
    80005804:	0af70663          	beq	a4,a5,800058b0 <sys_unlink+0x188>
  iunlockput(dp);
    80005808:	854e                	mv	a0,s3
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	33c080e7          	jalr	828(ra) # 80003b46 <iunlockput>
  ip->nlink--;
    80005812:	04a4d783          	lhu	a5,74(s1)
    80005816:	37fd                	addiw	a5,a5,-1
    80005818:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000581c:	8526                	mv	a0,s1
    8000581e:	ffffe097          	auipc	ra,0xffffe
    80005822:	ff8080e7          	jalr	-8(ra) # 80003816 <iupdate>
  iunlockput(ip);
    80005826:	8526                	mv	a0,s1
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	31e080e7          	jalr	798(ra) # 80003b46 <iunlockput>
  end_op();
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	afa080e7          	jalr	-1286(ra) # 8000432a <end_op>
  return 0;
    80005838:	4501                	li	a0,0
    8000583a:	a07d                	j	800058e8 <sys_unlink+0x1c0>
    end_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	aee080e7          	jalr	-1298(ra) # 8000432a <end_op>
    return -1;
    80005844:	557d                	li	a0,-1
    80005846:	a04d                	j	800058e8 <sys_unlink+0x1c0>
    panic("unlink: nlink < 1");
    80005848:	00003517          	auipc	a0,0x3
    8000584c:	ee850513          	addi	a0,a0,-280 # 80008730 <syscalls+0x328>
    80005850:	ffffb097          	auipc	ra,0xffffb
    80005854:	da2080e7          	jalr	-606(ra) # 800005f2 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005858:	44f8                	lw	a4,76(s1)
    8000585a:	02000793          	li	a5,32
    8000585e:	f6e7fae3          	bleu	a4,a5,800057d2 <sys_unlink+0xaa>
    80005862:	02000913          	li	s2,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005866:	4741                	li	a4,16
    80005868:	86ca                	mv	a3,s2
    8000586a:	f1840613          	addi	a2,s0,-232
    8000586e:	4581                	li	a1,0
    80005870:	8526                	mv	a0,s1
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	326080e7          	jalr	806(ra) # 80003b98 <readi>
    8000587a:	47c1                	li	a5,16
    8000587c:	00f51a63          	bne	a0,a5,80005890 <sys_unlink+0x168>
    if(de.inum != 0)
    80005880:	f1845783          	lhu	a5,-232(s0)
    80005884:	e3b9                	bnez	a5,800058ca <sys_unlink+0x1a2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005886:	2941                	addiw	s2,s2,16
    80005888:	44fc                	lw	a5,76(s1)
    8000588a:	fcf96ee3          	bltu	s2,a5,80005866 <sys_unlink+0x13e>
    8000588e:	b791                	j	800057d2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005890:	00003517          	auipc	a0,0x3
    80005894:	eb850513          	addi	a0,a0,-328 # 80008748 <syscalls+0x340>
    80005898:	ffffb097          	auipc	ra,0xffffb
    8000589c:	d5a080e7          	jalr	-678(ra) # 800005f2 <panic>
    panic("unlink: writei");
    800058a0:	00003517          	auipc	a0,0x3
    800058a4:	ec050513          	addi	a0,a0,-320 # 80008760 <syscalls+0x358>
    800058a8:	ffffb097          	auipc	ra,0xffffb
    800058ac:	d4a080e7          	jalr	-694(ra) # 800005f2 <panic>
    dp->nlink--;
    800058b0:	04a9d783          	lhu	a5,74(s3)
    800058b4:	37fd                	addiw	a5,a5,-1
    800058b6:	04f99523          	sh	a5,74(s3)
    iupdate(dp);
    800058ba:	854e                	mv	a0,s3
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	f5a080e7          	jalr	-166(ra) # 80003816 <iupdate>
    800058c4:	b791                	j	80005808 <sys_unlink+0xe0>
    return -1;
    800058c6:	557d                	li	a0,-1
    800058c8:	a005                	j	800058e8 <sys_unlink+0x1c0>
    iunlockput(ip);
    800058ca:	8526                	mv	a0,s1
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	27a080e7          	jalr	634(ra) # 80003b46 <iunlockput>
  iunlockput(dp);
    800058d4:	854e                	mv	a0,s3
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	270080e7          	jalr	624(ra) # 80003b46 <iunlockput>
  end_op();
    800058de:	fffff097          	auipc	ra,0xfffff
    800058e2:	a4c080e7          	jalr	-1460(ra) # 8000432a <end_op>
  return -1;
    800058e6:	557d                	li	a0,-1
}
    800058e8:	70ae                	ld	ra,232(sp)
    800058ea:	740e                	ld	s0,224(sp)
    800058ec:	64ee                	ld	s1,216(sp)
    800058ee:	694e                	ld	s2,208(sp)
    800058f0:	69ae                	ld	s3,200(sp)
    800058f2:	616d                	addi	sp,sp,240
    800058f4:	8082                	ret

00000000800058f6 <sys_open>:

uint64
sys_open(void)
{
    800058f6:	7131                	addi	sp,sp,-192
    800058f8:	fd06                	sd	ra,184(sp)
    800058fa:	f922                	sd	s0,176(sp)
    800058fc:	f526                	sd	s1,168(sp)
    800058fe:	f14a                	sd	s2,160(sp)
    80005900:	ed4e                	sd	s3,152(sp)
    80005902:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005904:	08000613          	li	a2,128
    80005908:	f5040593          	addi	a1,s0,-176
    8000590c:	4501                	li	a0,0
    8000590e:	ffffd097          	auipc	ra,0xffffd
    80005912:	3aa080e7          	jalr	938(ra) # 80002cb8 <argstr>
    return -1;
    80005916:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005918:	0c054163          	bltz	a0,800059da <sys_open+0xe4>
    8000591c:	f4c40593          	addi	a1,s0,-180
    80005920:	4505                	li	a0,1
    80005922:	ffffd097          	auipc	ra,0xffffd
    80005926:	352080e7          	jalr	850(ra) # 80002c74 <argint>
    8000592a:	0a054863          	bltz	a0,800059da <sys_open+0xe4>

  begin_op();
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	97c080e7          	jalr	-1668(ra) # 800042aa <begin_op>

  if(omode & O_CREATE){
    80005936:	f4c42783          	lw	a5,-180(s0)
    8000593a:	2007f793          	andi	a5,a5,512
    8000593e:	cbdd                	beqz	a5,800059f4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005940:	4681                	li	a3,0
    80005942:	4601                	li	a2,0
    80005944:	4589                	li	a1,2
    80005946:	f5040513          	addi	a0,s0,-176
    8000594a:	00000097          	auipc	ra,0x0
    8000594e:	976080e7          	jalr	-1674(ra) # 800052c0 <create>
    80005952:	892a                	mv	s2,a0
    if(ip == 0){
    80005954:	c959                	beqz	a0,800059ea <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005956:	04491703          	lh	a4,68(s2)
    8000595a:	478d                	li	a5,3
    8000595c:	00f71763          	bne	a4,a5,8000596a <sys_open+0x74>
    80005960:	04695703          	lhu	a4,70(s2)
    80005964:	47a5                	li	a5,9
    80005966:	0ce7ec63          	bltu	a5,a4,80005a3e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	d72080e7          	jalr	-654(ra) # 800046dc <filealloc>
    80005972:	89aa                	mv	s3,a0
    80005974:	10050263          	beqz	a0,80005a78 <sys_open+0x182>
    80005978:	00000097          	auipc	ra,0x0
    8000597c:	900080e7          	jalr	-1792(ra) # 80005278 <fdalloc>
    80005980:	84aa                	mv	s1,a0
    80005982:	0e054663          	bltz	a0,80005a6e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005986:	04491703          	lh	a4,68(s2)
    8000598a:	478d                	li	a5,3
    8000598c:	0cf70463          	beq	a4,a5,80005a54 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005990:	4789                	li	a5,2
    80005992:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005996:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000599a:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000599e:	f4c42783          	lw	a5,-180(s0)
    800059a2:	0017c713          	xori	a4,a5,1
    800059a6:	8b05                	andi	a4,a4,1
    800059a8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059ac:	0037f713          	andi	a4,a5,3
    800059b0:	00e03733          	snez	a4,a4
    800059b4:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059b8:	4007f793          	andi	a5,a5,1024
    800059bc:	c791                	beqz	a5,800059c8 <sys_open+0xd2>
    800059be:	04491703          	lh	a4,68(s2)
    800059c2:	4789                	li	a5,2
    800059c4:	08f70f63          	beq	a4,a5,80005a62 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059c8:	854a                	mv	a0,s2
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	fdc080e7          	jalr	-36(ra) # 800039a6 <iunlock>
  end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	958080e7          	jalr	-1704(ra) # 8000432a <end_op>

  return fd;
}
    800059da:	8526                	mv	a0,s1
    800059dc:	70ea                	ld	ra,184(sp)
    800059de:	744a                	ld	s0,176(sp)
    800059e0:	74aa                	ld	s1,168(sp)
    800059e2:	790a                	ld	s2,160(sp)
    800059e4:	69ea                	ld	s3,152(sp)
    800059e6:	6129                	addi	sp,sp,192
    800059e8:	8082                	ret
      end_op();
    800059ea:	fffff097          	auipc	ra,0xfffff
    800059ee:	940080e7          	jalr	-1728(ra) # 8000432a <end_op>
      return -1;
    800059f2:	b7e5                	j	800059da <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059f4:	f5040513          	addi	a0,s0,-176
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	6a4080e7          	jalr	1700(ra) # 8000409c <namei>
    80005a00:	892a                	mv	s2,a0
    80005a02:	c905                	beqz	a0,80005a32 <sys_open+0x13c>
    ilock(ip);
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	ede080e7          	jalr	-290(ra) # 800038e2 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a0c:	04491703          	lh	a4,68(s2)
    80005a10:	4785                	li	a5,1
    80005a12:	f4f712e3          	bne	a4,a5,80005956 <sys_open+0x60>
    80005a16:	f4c42783          	lw	a5,-180(s0)
    80005a1a:	dba1                	beqz	a5,8000596a <sys_open+0x74>
      iunlockput(ip);
    80005a1c:	854a                	mv	a0,s2
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	128080e7          	jalr	296(ra) # 80003b46 <iunlockput>
      end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	904080e7          	jalr	-1788(ra) # 8000432a <end_op>
      return -1;
    80005a2e:	54fd                	li	s1,-1
    80005a30:	b76d                	j	800059da <sys_open+0xe4>
      end_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	8f8080e7          	jalr	-1800(ra) # 8000432a <end_op>
      return -1;
    80005a3a:	54fd                	li	s1,-1
    80005a3c:	bf79                	j	800059da <sys_open+0xe4>
    iunlockput(ip);
    80005a3e:	854a                	mv	a0,s2
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	106080e7          	jalr	262(ra) # 80003b46 <iunlockput>
    end_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	8e2080e7          	jalr	-1822(ra) # 8000432a <end_op>
    return -1;
    80005a50:	54fd                	li	s1,-1
    80005a52:	b761                	j	800059da <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a54:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a58:	04691783          	lh	a5,70(s2)
    80005a5c:	02f99223          	sh	a5,36(s3)
    80005a60:	bf2d                	j	8000599a <sys_open+0xa4>
    itrunc(ip);
    80005a62:	854a                	mv	a0,s2
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	f8e080e7          	jalr	-114(ra) # 800039f2 <itrunc>
    80005a6c:	bfb1                	j	800059c8 <sys_open+0xd2>
      fileclose(f);
    80005a6e:	854e                	mv	a0,s3
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	d3c080e7          	jalr	-708(ra) # 800047ac <fileclose>
    iunlockput(ip);
    80005a78:	854a                	mv	a0,s2
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	0cc080e7          	jalr	204(ra) # 80003b46 <iunlockput>
    end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	8a8080e7          	jalr	-1880(ra) # 8000432a <end_op>
    return -1;
    80005a8a:	54fd                	li	s1,-1
    80005a8c:	b7b9                	j	800059da <sys_open+0xe4>

0000000080005a8e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a8e:	7175                	addi	sp,sp,-144
    80005a90:	e506                	sd	ra,136(sp)
    80005a92:	e122                	sd	s0,128(sp)
    80005a94:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	814080e7          	jalr	-2028(ra) # 800042aa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a9e:	08000613          	li	a2,128
    80005aa2:	f7040593          	addi	a1,s0,-144
    80005aa6:	4501                	li	a0,0
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	210080e7          	jalr	528(ra) # 80002cb8 <argstr>
    80005ab0:	02054963          	bltz	a0,80005ae2 <sys_mkdir+0x54>
    80005ab4:	4681                	li	a3,0
    80005ab6:	4601                	li	a2,0
    80005ab8:	4585                	li	a1,1
    80005aba:	f7040513          	addi	a0,s0,-144
    80005abe:	00000097          	auipc	ra,0x0
    80005ac2:	802080e7          	jalr	-2046(ra) # 800052c0 <create>
    80005ac6:	cd11                	beqz	a0,80005ae2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	07e080e7          	jalr	126(ra) # 80003b46 <iunlockput>
  end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	85a080e7          	jalr	-1958(ra) # 8000432a <end_op>
  return 0;
    80005ad8:	4501                	li	a0,0
}
    80005ada:	60aa                	ld	ra,136(sp)
    80005adc:	640a                	ld	s0,128(sp)
    80005ade:	6149                	addi	sp,sp,144
    80005ae0:	8082                	ret
    end_op();
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	848080e7          	jalr	-1976(ra) # 8000432a <end_op>
    return -1;
    80005aea:	557d                	li	a0,-1
    80005aec:	b7fd                	j	80005ada <sys_mkdir+0x4c>

0000000080005aee <sys_mknod>:

uint64
sys_mknod(void)
{
    80005aee:	7135                	addi	sp,sp,-160
    80005af0:	ed06                	sd	ra,152(sp)
    80005af2:	e922                	sd	s0,144(sp)
    80005af4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	7b4080e7          	jalr	1972(ra) # 800042aa <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005afe:	08000613          	li	a2,128
    80005b02:	f7040593          	addi	a1,s0,-144
    80005b06:	4501                	li	a0,0
    80005b08:	ffffd097          	auipc	ra,0xffffd
    80005b0c:	1b0080e7          	jalr	432(ra) # 80002cb8 <argstr>
    80005b10:	04054a63          	bltz	a0,80005b64 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005b14:	f6c40593          	addi	a1,s0,-148
    80005b18:	4505                	li	a0,1
    80005b1a:	ffffd097          	auipc	ra,0xffffd
    80005b1e:	15a080e7          	jalr	346(ra) # 80002c74 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b22:	04054163          	bltz	a0,80005b64 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005b26:	f6840593          	addi	a1,s0,-152
    80005b2a:	4509                	li	a0,2
    80005b2c:	ffffd097          	auipc	ra,0xffffd
    80005b30:	148080e7          	jalr	328(ra) # 80002c74 <argint>
     argint(1, &major) < 0 ||
    80005b34:	02054863          	bltz	a0,80005b64 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b38:	f6841683          	lh	a3,-152(s0)
    80005b3c:	f6c41603          	lh	a2,-148(s0)
    80005b40:	458d                	li	a1,3
    80005b42:	f7040513          	addi	a0,s0,-144
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	77a080e7          	jalr	1914(ra) # 800052c0 <create>
     argint(2, &minor) < 0 ||
    80005b4e:	c919                	beqz	a0,80005b64 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	ff6080e7          	jalr	-10(ra) # 80003b46 <iunlockput>
  end_op();
    80005b58:	ffffe097          	auipc	ra,0xffffe
    80005b5c:	7d2080e7          	jalr	2002(ra) # 8000432a <end_op>
  return 0;
    80005b60:	4501                	li	a0,0
    80005b62:	a031                	j	80005b6e <sys_mknod+0x80>
    end_op();
    80005b64:	ffffe097          	auipc	ra,0xffffe
    80005b68:	7c6080e7          	jalr	1990(ra) # 8000432a <end_op>
    return -1;
    80005b6c:	557d                	li	a0,-1
}
    80005b6e:	60ea                	ld	ra,152(sp)
    80005b70:	644a                	ld	s0,144(sp)
    80005b72:	610d                	addi	sp,sp,160
    80005b74:	8082                	ret

0000000080005b76 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b76:	7135                	addi	sp,sp,-160
    80005b78:	ed06                	sd	ra,152(sp)
    80005b7a:	e922                	sd	s0,144(sp)
    80005b7c:	e526                	sd	s1,136(sp)
    80005b7e:	e14a                	sd	s2,128(sp)
    80005b80:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b82:	ffffc097          	auipc	ra,0xffffc
    80005b86:	f42080e7          	jalr	-190(ra) # 80001ac4 <myproc>
    80005b8a:	892a                	mv	s2,a0
  
  begin_op();
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	71e080e7          	jalr	1822(ra) # 800042aa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b94:	08000613          	li	a2,128
    80005b98:	f6040593          	addi	a1,s0,-160
    80005b9c:	4501                	li	a0,0
    80005b9e:	ffffd097          	auipc	ra,0xffffd
    80005ba2:	11a080e7          	jalr	282(ra) # 80002cb8 <argstr>
    80005ba6:	04054b63          	bltz	a0,80005bfc <sys_chdir+0x86>
    80005baa:	f6040513          	addi	a0,s0,-160
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	4ee080e7          	jalr	1262(ra) # 8000409c <namei>
    80005bb6:	84aa                	mv	s1,a0
    80005bb8:	c131                	beqz	a0,80005bfc <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	d28080e7          	jalr	-728(ra) # 800038e2 <ilock>
  if(ip->type != T_DIR){
    80005bc2:	04449703          	lh	a4,68(s1)
    80005bc6:	4785                	li	a5,1
    80005bc8:	04f71063          	bne	a4,a5,80005c08 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bcc:	8526                	mv	a0,s1
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	dd8080e7          	jalr	-552(ra) # 800039a6 <iunlock>
  iput(p->cwd);
    80005bd6:	15093503          	ld	a0,336(s2)
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	ec4080e7          	jalr	-316(ra) # 80003a9e <iput>
  end_op();
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	748080e7          	jalr	1864(ra) # 8000432a <end_op>
  p->cwd = ip;
    80005bea:	14993823          	sd	s1,336(s2)
  return 0;
    80005bee:	4501                	li	a0,0
}
    80005bf0:	60ea                	ld	ra,152(sp)
    80005bf2:	644a                	ld	s0,144(sp)
    80005bf4:	64aa                	ld	s1,136(sp)
    80005bf6:	690a                	ld	s2,128(sp)
    80005bf8:	610d                	addi	sp,sp,160
    80005bfa:	8082                	ret
    end_op();
    80005bfc:	ffffe097          	auipc	ra,0xffffe
    80005c00:	72e080e7          	jalr	1838(ra) # 8000432a <end_op>
    return -1;
    80005c04:	557d                	li	a0,-1
    80005c06:	b7ed                	j	80005bf0 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c08:	8526                	mv	a0,s1
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	f3c080e7          	jalr	-196(ra) # 80003b46 <iunlockput>
    end_op();
    80005c12:	ffffe097          	auipc	ra,0xffffe
    80005c16:	718080e7          	jalr	1816(ra) # 8000432a <end_op>
    return -1;
    80005c1a:	557d                	li	a0,-1
    80005c1c:	bfd1                	j	80005bf0 <sys_chdir+0x7a>

0000000080005c1e <sys_exec>:

uint64
sys_exec(void)
{
    80005c1e:	7145                	addi	sp,sp,-464
    80005c20:	e786                	sd	ra,456(sp)
    80005c22:	e3a2                	sd	s0,448(sp)
    80005c24:	ff26                	sd	s1,440(sp)
    80005c26:	fb4a                	sd	s2,432(sp)
    80005c28:	f74e                	sd	s3,424(sp)
    80005c2a:	f352                	sd	s4,416(sp)
    80005c2c:	ef56                	sd	s5,408(sp)
    80005c2e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c30:	08000613          	li	a2,128
    80005c34:	f4040593          	addi	a1,s0,-192
    80005c38:	4501                	li	a0,0
    80005c3a:	ffffd097          	auipc	ra,0xffffd
    80005c3e:	07e080e7          	jalr	126(ra) # 80002cb8 <argstr>
    return -1;
    80005c42:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005c44:	0e054c63          	bltz	a0,80005d3c <sys_exec+0x11e>
    80005c48:	e3840593          	addi	a1,s0,-456
    80005c4c:	4505                	li	a0,1
    80005c4e:	ffffd097          	auipc	ra,0xffffd
    80005c52:	048080e7          	jalr	72(ra) # 80002c96 <argaddr>
    80005c56:	0e054363          	bltz	a0,80005d3c <sys_exec+0x11e>
  }
  memset(argv, 0, sizeof(argv));
    80005c5a:	e4040913          	addi	s2,s0,-448
    80005c5e:	10000613          	li	a2,256
    80005c62:	4581                	li	a1,0
    80005c64:	854a                	mv	a0,s2
    80005c66:	ffffb097          	auipc	ra,0xffffb
    80005c6a:	14c080e7          	jalr	332(ra) # 80000db2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c6e:	89ca                	mv	s3,s2
  memset(argv, 0, sizeof(argv));
    80005c70:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    80005c72:	02000a93          	li	s5,32
    80005c76:	00048a1b          	sext.w	s4,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c7a:	00349513          	slli	a0,s1,0x3
    80005c7e:	e3040593          	addi	a1,s0,-464
    80005c82:	e3843783          	ld	a5,-456(s0)
    80005c86:	953e                	add	a0,a0,a5
    80005c88:	ffffd097          	auipc	ra,0xffffd
    80005c8c:	f50080e7          	jalr	-176(ra) # 80002bd8 <fetchaddr>
    80005c90:	02054a63          	bltz	a0,80005cc4 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c94:	e3043783          	ld	a5,-464(s0)
    80005c98:	cfa9                	beqz	a5,80005cf2 <sys_exec+0xd4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c9a:	ffffb097          	auipc	ra,0xffffb
    80005c9e:	f2c080e7          	jalr	-212(ra) # 80000bc6 <kalloc>
    80005ca2:	00a93023          	sd	a0,0(s2)
    if(argv[i] == 0)
    80005ca6:	cd19                	beqz	a0,80005cc4 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ca8:	6605                	lui	a2,0x1
    80005caa:	85aa                	mv	a1,a0
    80005cac:	e3043503          	ld	a0,-464(s0)
    80005cb0:	ffffd097          	auipc	ra,0xffffd
    80005cb4:	f7c080e7          	jalr	-132(ra) # 80002c2c <fetchstr>
    80005cb8:	00054663          	bltz	a0,80005cc4 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005cbc:	0485                	addi	s1,s1,1
    80005cbe:	0921                	addi	s2,s2,8
    80005cc0:	fb549be3          	bne	s1,s5,80005c76 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc4:	e4043503          	ld	a0,-448(s0)
    kfree(argv[i]);
  return -1;
    80005cc8:	597d                	li	s2,-1
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cca:	c92d                	beqz	a0,80005d3c <sys_exec+0x11e>
    kfree(argv[i]);
    80005ccc:	ffffb097          	auipc	ra,0xffffb
    80005cd0:	dfa080e7          	jalr	-518(ra) # 80000ac6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd4:	e4840493          	addi	s1,s0,-440
    80005cd8:	10098993          	addi	s3,s3,256
    80005cdc:	6088                	ld	a0,0(s1)
    80005cde:	cd31                	beqz	a0,80005d3a <sys_exec+0x11c>
    kfree(argv[i]);
    80005ce0:	ffffb097          	auipc	ra,0xffffb
    80005ce4:	de6080e7          	jalr	-538(ra) # 80000ac6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce8:	04a1                	addi	s1,s1,8
    80005cea:	ff3499e3          	bne	s1,s3,80005cdc <sys_exec+0xbe>
  return -1;
    80005cee:	597d                	li	s2,-1
    80005cf0:	a0b1                	j	80005d3c <sys_exec+0x11e>
      argv[i] = 0;
    80005cf2:	0a0e                	slli	s4,s4,0x3
    80005cf4:	fc040793          	addi	a5,s0,-64
    80005cf8:	9a3e                	add	s4,s4,a5
    80005cfa:	e80a3023          	sd	zero,-384(s4)
  int ret = exec(path, argv);
    80005cfe:	e4040593          	addi	a1,s0,-448
    80005d02:	f4040513          	addi	a0,s0,-192
    80005d06:	fffff097          	auipc	ra,0xfffff
    80005d0a:	166080e7          	jalr	358(ra) # 80004e6c <exec>
    80005d0e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d10:	e4043503          	ld	a0,-448(s0)
    80005d14:	c505                	beqz	a0,80005d3c <sys_exec+0x11e>
    kfree(argv[i]);
    80005d16:	ffffb097          	auipc	ra,0xffffb
    80005d1a:	db0080e7          	jalr	-592(ra) # 80000ac6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d1e:	e4840493          	addi	s1,s0,-440
    80005d22:	10098993          	addi	s3,s3,256
    80005d26:	6088                	ld	a0,0(s1)
    80005d28:	c911                	beqz	a0,80005d3c <sys_exec+0x11e>
    kfree(argv[i]);
    80005d2a:	ffffb097          	auipc	ra,0xffffb
    80005d2e:	d9c080e7          	jalr	-612(ra) # 80000ac6 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d32:	04a1                	addi	s1,s1,8
    80005d34:	ff3499e3          	bne	s1,s3,80005d26 <sys_exec+0x108>
    80005d38:	a011                	j	80005d3c <sys_exec+0x11e>
  return -1;
    80005d3a:	597d                	li	s2,-1
}
    80005d3c:	854a                	mv	a0,s2
    80005d3e:	60be                	ld	ra,456(sp)
    80005d40:	641e                	ld	s0,448(sp)
    80005d42:	74fa                	ld	s1,440(sp)
    80005d44:	795a                	ld	s2,432(sp)
    80005d46:	79ba                	ld	s3,424(sp)
    80005d48:	7a1a                	ld	s4,416(sp)
    80005d4a:	6afa                	ld	s5,408(sp)
    80005d4c:	6179                	addi	sp,sp,464
    80005d4e:	8082                	ret

0000000080005d50 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d50:	7139                	addi	sp,sp,-64
    80005d52:	fc06                	sd	ra,56(sp)
    80005d54:	f822                	sd	s0,48(sp)
    80005d56:	f426                	sd	s1,40(sp)
    80005d58:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d5a:	ffffc097          	auipc	ra,0xffffc
    80005d5e:	d6a080e7          	jalr	-662(ra) # 80001ac4 <myproc>
    80005d62:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005d64:	fd840593          	addi	a1,s0,-40
    80005d68:	4501                	li	a0,0
    80005d6a:	ffffd097          	auipc	ra,0xffffd
    80005d6e:	f2c080e7          	jalr	-212(ra) # 80002c96 <argaddr>
    return -1;
    80005d72:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005d74:	0c054f63          	bltz	a0,80005e52 <sys_pipe+0x102>
  if(pipealloc(&rf, &wf) < 0)
    80005d78:	fc840593          	addi	a1,s0,-56
    80005d7c:	fd040513          	addi	a0,s0,-48
    80005d80:	fffff097          	auipc	ra,0xfffff
    80005d84:	d74080e7          	jalr	-652(ra) # 80004af4 <pipealloc>
    return -1;
    80005d88:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d8a:	0c054463          	bltz	a0,80005e52 <sys_pipe+0x102>
  fd0 = -1;
    80005d8e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d92:	fd043503          	ld	a0,-48(s0)
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	4e2080e7          	jalr	1250(ra) # 80005278 <fdalloc>
    80005d9e:	fca42223          	sw	a0,-60(s0)
    80005da2:	08054b63          	bltz	a0,80005e38 <sys_pipe+0xe8>
    80005da6:	fc843503          	ld	a0,-56(s0)
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	4ce080e7          	jalr	1230(ra) # 80005278 <fdalloc>
    80005db2:	fca42023          	sw	a0,-64(s0)
    80005db6:	06054863          	bltz	a0,80005e26 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dba:	4691                	li	a3,4
    80005dbc:	fc440613          	addi	a2,s0,-60
    80005dc0:	fd843583          	ld	a1,-40(s0)
    80005dc4:	68a8                	ld	a0,80(s1)
    80005dc6:	ffffc097          	auipc	ra,0xffffc
    80005dca:	9da080e7          	jalr	-1574(ra) # 800017a0 <copyout>
    80005dce:	02054063          	bltz	a0,80005dee <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dd2:	4691                	li	a3,4
    80005dd4:	fc040613          	addi	a2,s0,-64
    80005dd8:	fd843583          	ld	a1,-40(s0)
    80005ddc:	0591                	addi	a1,a1,4
    80005dde:	68a8                	ld	a0,80(s1)
    80005de0:	ffffc097          	auipc	ra,0xffffc
    80005de4:	9c0080e7          	jalr	-1600(ra) # 800017a0 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005de8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dea:	06055463          	bgez	a0,80005e52 <sys_pipe+0x102>
    p->ofile[fd0] = 0;
    80005dee:	fc442783          	lw	a5,-60(s0)
    80005df2:	07e9                	addi	a5,a5,26
    80005df4:	078e                	slli	a5,a5,0x3
    80005df6:	97a6                	add	a5,a5,s1
    80005df8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dfc:	fc042783          	lw	a5,-64(s0)
    80005e00:	07e9                	addi	a5,a5,26
    80005e02:	078e                	slli	a5,a5,0x3
    80005e04:	94be                	add	s1,s1,a5
    80005e06:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e0a:	fd043503          	ld	a0,-48(s0)
    80005e0e:	fffff097          	auipc	ra,0xfffff
    80005e12:	99e080e7          	jalr	-1634(ra) # 800047ac <fileclose>
    fileclose(wf);
    80005e16:	fc843503          	ld	a0,-56(s0)
    80005e1a:	fffff097          	auipc	ra,0xfffff
    80005e1e:	992080e7          	jalr	-1646(ra) # 800047ac <fileclose>
    return -1;
    80005e22:	57fd                	li	a5,-1
    80005e24:	a03d                	j	80005e52 <sys_pipe+0x102>
    if(fd0 >= 0)
    80005e26:	fc442783          	lw	a5,-60(s0)
    80005e2a:	0007c763          	bltz	a5,80005e38 <sys_pipe+0xe8>
      p->ofile[fd0] = 0;
    80005e2e:	07e9                	addi	a5,a5,26
    80005e30:	078e                	slli	a5,a5,0x3
    80005e32:	94be                	add	s1,s1,a5
    80005e34:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e38:	fd043503          	ld	a0,-48(s0)
    80005e3c:	fffff097          	auipc	ra,0xfffff
    80005e40:	970080e7          	jalr	-1680(ra) # 800047ac <fileclose>
    fileclose(wf);
    80005e44:	fc843503          	ld	a0,-56(s0)
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	964080e7          	jalr	-1692(ra) # 800047ac <fileclose>
    return -1;
    80005e50:	57fd                	li	a5,-1
}
    80005e52:	853e                	mv	a0,a5
    80005e54:	70e2                	ld	ra,56(sp)
    80005e56:	7442                	ld	s0,48(sp)
    80005e58:	74a2                	ld	s1,40(sp)
    80005e5a:	6121                	addi	sp,sp,64
    80005e5c:	8082                	ret
	...

0000000080005e60 <kernelvec>:
    80005e60:	7111                	addi	sp,sp,-256
    80005e62:	e006                	sd	ra,0(sp)
    80005e64:	e40a                	sd	sp,8(sp)
    80005e66:	e80e                	sd	gp,16(sp)
    80005e68:	ec12                	sd	tp,24(sp)
    80005e6a:	f016                	sd	t0,32(sp)
    80005e6c:	f41a                	sd	t1,40(sp)
    80005e6e:	f81e                	sd	t2,48(sp)
    80005e70:	fc22                	sd	s0,56(sp)
    80005e72:	e0a6                	sd	s1,64(sp)
    80005e74:	e4aa                	sd	a0,72(sp)
    80005e76:	e8ae                	sd	a1,80(sp)
    80005e78:	ecb2                	sd	a2,88(sp)
    80005e7a:	f0b6                	sd	a3,96(sp)
    80005e7c:	f4ba                	sd	a4,104(sp)
    80005e7e:	f8be                	sd	a5,112(sp)
    80005e80:	fcc2                	sd	a6,120(sp)
    80005e82:	e146                	sd	a7,128(sp)
    80005e84:	e54a                	sd	s2,136(sp)
    80005e86:	e94e                	sd	s3,144(sp)
    80005e88:	ed52                	sd	s4,152(sp)
    80005e8a:	f156                	sd	s5,160(sp)
    80005e8c:	f55a                	sd	s6,168(sp)
    80005e8e:	f95e                	sd	s7,176(sp)
    80005e90:	fd62                	sd	s8,184(sp)
    80005e92:	e1e6                	sd	s9,192(sp)
    80005e94:	e5ea                	sd	s10,200(sp)
    80005e96:	e9ee                	sd	s11,208(sp)
    80005e98:	edf2                	sd	t3,216(sp)
    80005e9a:	f1f6                	sd	t4,224(sp)
    80005e9c:	f5fa                	sd	t5,232(sp)
    80005e9e:	f9fe                	sd	t6,240(sp)
    80005ea0:	c01fc0ef          	jal	ra,80002aa0 <kerneltrap>
    80005ea4:	6082                	ld	ra,0(sp)
    80005ea6:	6122                	ld	sp,8(sp)
    80005ea8:	61c2                	ld	gp,16(sp)
    80005eaa:	7282                	ld	t0,32(sp)
    80005eac:	7322                	ld	t1,40(sp)
    80005eae:	73c2                	ld	t2,48(sp)
    80005eb0:	7462                	ld	s0,56(sp)
    80005eb2:	6486                	ld	s1,64(sp)
    80005eb4:	6526                	ld	a0,72(sp)
    80005eb6:	65c6                	ld	a1,80(sp)
    80005eb8:	6666                	ld	a2,88(sp)
    80005eba:	7686                	ld	a3,96(sp)
    80005ebc:	7726                	ld	a4,104(sp)
    80005ebe:	77c6                	ld	a5,112(sp)
    80005ec0:	7866                	ld	a6,120(sp)
    80005ec2:	688a                	ld	a7,128(sp)
    80005ec4:	692a                	ld	s2,136(sp)
    80005ec6:	69ca                	ld	s3,144(sp)
    80005ec8:	6a6a                	ld	s4,152(sp)
    80005eca:	7a8a                	ld	s5,160(sp)
    80005ecc:	7b2a                	ld	s6,168(sp)
    80005ece:	7bca                	ld	s7,176(sp)
    80005ed0:	7c6a                	ld	s8,184(sp)
    80005ed2:	6c8e                	ld	s9,192(sp)
    80005ed4:	6d2e                	ld	s10,200(sp)
    80005ed6:	6dce                	ld	s11,208(sp)
    80005ed8:	6e6e                	ld	t3,216(sp)
    80005eda:	7e8e                	ld	t4,224(sp)
    80005edc:	7f2e                	ld	t5,232(sp)
    80005ede:	7fce                	ld	t6,240(sp)
    80005ee0:	6111                	addi	sp,sp,256
    80005ee2:	10200073          	sret
    80005ee6:	00000013          	nop
    80005eea:	00000013          	nop
    80005eee:	0001                	nop

0000000080005ef0 <timervec>:
    80005ef0:	34051573          	csrrw	a0,mscratch,a0
    80005ef4:	e10c                	sd	a1,0(a0)
    80005ef6:	e510                	sd	a2,8(a0)
    80005ef8:	e914                	sd	a3,16(a0)
    80005efa:	710c                	ld	a1,32(a0)
    80005efc:	7510                	ld	a2,40(a0)
    80005efe:	6194                	ld	a3,0(a1)
    80005f00:	96b2                	add	a3,a3,a2
    80005f02:	e194                	sd	a3,0(a1)
    80005f04:	4589                	li	a1,2
    80005f06:	14459073          	csrw	sip,a1
    80005f0a:	6914                	ld	a3,16(a0)
    80005f0c:	6510                	ld	a2,8(a0)
    80005f0e:	610c                	ld	a1,0(a0)
    80005f10:	34051573          	csrrw	a0,mscratch,a0
    80005f14:	30200073          	mret
	...

0000000080005f1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f1a:	1141                	addi	sp,sp,-16
    80005f1c:	e422                	sd	s0,8(sp)
    80005f1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f20:	0c0007b7          	lui	a5,0xc000
    80005f24:	4705                	li	a4,1
    80005f26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f28:	c3d8                	sw	a4,4(a5)
}
    80005f2a:	6422                	ld	s0,8(sp)
    80005f2c:	0141                	addi	sp,sp,16
    80005f2e:	8082                	ret

0000000080005f30 <plicinithart>:

void
plicinithart(void)
{
    80005f30:	1141                	addi	sp,sp,-16
    80005f32:	e406                	sd	ra,8(sp)
    80005f34:	e022                	sd	s0,0(sp)
    80005f36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f38:	ffffc097          	auipc	ra,0xffffc
    80005f3c:	b60080e7          	jalr	-1184(ra) # 80001a98 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f40:	0085171b          	slliw	a4,a0,0x8
    80005f44:	0c0027b7          	lui	a5,0xc002
    80005f48:	97ba                	add	a5,a5,a4
    80005f4a:	40200713          	li	a4,1026
    80005f4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f52:	00d5151b          	slliw	a0,a0,0xd
    80005f56:	0c2017b7          	lui	a5,0xc201
    80005f5a:	953e                	add	a0,a0,a5
    80005f5c:	00052023          	sw	zero,0(a0)
}
    80005f60:	60a2                	ld	ra,8(sp)
    80005f62:	6402                	ld	s0,0(sp)
    80005f64:	0141                	addi	sp,sp,16
    80005f66:	8082                	ret

0000000080005f68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f68:	1141                	addi	sp,sp,-16
    80005f6a:	e406                	sd	ra,8(sp)
    80005f6c:	e022                	sd	s0,0(sp)
    80005f6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f70:	ffffc097          	auipc	ra,0xffffc
    80005f74:	b28080e7          	jalr	-1240(ra) # 80001a98 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f78:	00d5151b          	slliw	a0,a0,0xd
    80005f7c:	0c2017b7          	lui	a5,0xc201
    80005f80:	97aa                	add	a5,a5,a0
  return irq;
}
    80005f82:	43c8                	lw	a0,4(a5)
    80005f84:	60a2                	ld	ra,8(sp)
    80005f86:	6402                	ld	s0,0(sp)
    80005f88:	0141                	addi	sp,sp,16
    80005f8a:	8082                	ret

0000000080005f8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f8c:	1101                	addi	sp,sp,-32
    80005f8e:	ec06                	sd	ra,24(sp)
    80005f90:	e822                	sd	s0,16(sp)
    80005f92:	e426                	sd	s1,8(sp)
    80005f94:	1000                	addi	s0,sp,32
    80005f96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	b00080e7          	jalr	-1280(ra) # 80001a98 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fa0:	00d5151b          	slliw	a0,a0,0xd
    80005fa4:	0c2017b7          	lui	a5,0xc201
    80005fa8:	97aa                	add	a5,a5,a0
    80005faa:	c3c4                	sw	s1,4(a5)
}
    80005fac:	60e2                	ld	ra,24(sp)
    80005fae:	6442                	ld	s0,16(sp)
    80005fb0:	64a2                	ld	s1,8(sp)
    80005fb2:	6105                	addi	sp,sp,32
    80005fb4:	8082                	ret

0000000080005fb6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fb6:	1141                	addi	sp,sp,-16
    80005fb8:	e406                	sd	ra,8(sp)
    80005fba:	e022                	sd	s0,0(sp)
    80005fbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fbe:	479d                	li	a5,7
    80005fc0:	04a7cd63          	blt	a5,a0,8000601a <free_desc+0x64>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005fc4:	0001e797          	auipc	a5,0x1e
    80005fc8:	03c78793          	addi	a5,a5,60 # 80024000 <disk>
    80005fcc:	00a78733          	add	a4,a5,a0
    80005fd0:	6789                	lui	a5,0x2
    80005fd2:	97ba                	add	a5,a5,a4
    80005fd4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005fd8:	eba9                	bnez	a5,8000602a <free_desc+0x74>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005fda:	00020797          	auipc	a5,0x20
    80005fde:	02678793          	addi	a5,a5,38 # 80026000 <disk+0x2000>
    80005fe2:	639c                	ld	a5,0(a5)
    80005fe4:	00451713          	slli	a4,a0,0x4
    80005fe8:	97ba                	add	a5,a5,a4
    80005fea:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005fee:	0001e797          	auipc	a5,0x1e
    80005ff2:	01278793          	addi	a5,a5,18 # 80024000 <disk>
    80005ff6:	97aa                	add	a5,a5,a0
    80005ff8:	6509                	lui	a0,0x2
    80005ffa:	953e                	add	a0,a0,a5
    80005ffc:	4785                	li	a5,1
    80005ffe:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006002:	00020517          	auipc	a0,0x20
    80006006:	01650513          	addi	a0,a0,22 # 80026018 <disk+0x2018>
    8000600a:	ffffc097          	auipc	ra,0xffffc
    8000600e:	4da080e7          	jalr	1242(ra) # 800024e4 <wakeup>
}
    80006012:	60a2                	ld	ra,8(sp)
    80006014:	6402                	ld	s0,0(sp)
    80006016:	0141                	addi	sp,sp,16
    80006018:	8082                	ret
    panic("virtio_disk_intr 1");
    8000601a:	00002517          	auipc	a0,0x2
    8000601e:	75650513          	addi	a0,a0,1878 # 80008770 <syscalls+0x368>
    80006022:	ffffa097          	auipc	ra,0xffffa
    80006026:	5d0080e7          	jalr	1488(ra) # 800005f2 <panic>
    panic("virtio_disk_intr 2");
    8000602a:	00002517          	auipc	a0,0x2
    8000602e:	75e50513          	addi	a0,a0,1886 # 80008788 <syscalls+0x380>
    80006032:	ffffa097          	auipc	ra,0xffffa
    80006036:	5c0080e7          	jalr	1472(ra) # 800005f2 <panic>

000000008000603a <virtio_disk_init>:
{
    8000603a:	1101                	addi	sp,sp,-32
    8000603c:	ec06                	sd	ra,24(sp)
    8000603e:	e822                	sd	s0,16(sp)
    80006040:	e426                	sd	s1,8(sp)
    80006042:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006044:	00002597          	auipc	a1,0x2
    80006048:	75c58593          	addi	a1,a1,1884 # 800087a0 <syscalls+0x398>
    8000604c:	00020517          	auipc	a0,0x20
    80006050:	05c50513          	addi	a0,a0,92 # 800260a8 <disk+0x20a8>
    80006054:	ffffb097          	auipc	ra,0xffffb
    80006058:	bd2080e7          	jalr	-1070(ra) # 80000c26 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000605c:	100017b7          	lui	a5,0x10001
    80006060:	4398                	lw	a4,0(a5)
    80006062:	2701                	sext.w	a4,a4
    80006064:	747277b7          	lui	a5,0x74727
    80006068:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000606c:	0ef71163          	bne	a4,a5,8000614e <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006070:	100017b7          	lui	a5,0x10001
    80006074:	43dc                	lw	a5,4(a5)
    80006076:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006078:	4705                	li	a4,1
    8000607a:	0ce79a63          	bne	a5,a4,8000614e <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000607e:	100017b7          	lui	a5,0x10001
    80006082:	479c                	lw	a5,8(a5)
    80006084:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006086:	4709                	li	a4,2
    80006088:	0ce79363          	bne	a5,a4,8000614e <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000608c:	100017b7          	lui	a5,0x10001
    80006090:	47d8                	lw	a4,12(a5)
    80006092:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006094:	554d47b7          	lui	a5,0x554d4
    80006098:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000609c:	0af71963          	bne	a4,a5,8000614e <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a0:	100017b7          	lui	a5,0x10001
    800060a4:	4705                	li	a4,1
    800060a6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a8:	470d                	li	a4,3
    800060aa:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060ac:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800060ae:	c7ffe737          	lui	a4,0xc7ffe
    800060b2:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd775f>
    800060b6:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060b8:	2701                	sext.w	a4,a4
    800060ba:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060bc:	472d                	li	a4,11
    800060be:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060c0:	473d                	li	a4,15
    800060c2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800060c4:	6705                	lui	a4,0x1
    800060c6:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060c8:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060cc:	5bdc                	lw	a5,52(a5)
    800060ce:	2781                	sext.w	a5,a5
  if(max == 0)
    800060d0:	c7d9                	beqz	a5,8000615e <virtio_disk_init+0x124>
  if(max < NUM)
    800060d2:	471d                	li	a4,7
    800060d4:	08f77d63          	bleu	a5,a4,8000616e <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060d8:	100014b7          	lui	s1,0x10001
    800060dc:	47a1                	li	a5,8
    800060de:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800060e0:	6609                	lui	a2,0x2
    800060e2:	4581                	li	a1,0
    800060e4:	0001e517          	auipc	a0,0x1e
    800060e8:	f1c50513          	addi	a0,a0,-228 # 80024000 <disk>
    800060ec:	ffffb097          	auipc	ra,0xffffb
    800060f0:	cc6080e7          	jalr	-826(ra) # 80000db2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800060f4:	0001e717          	auipc	a4,0x1e
    800060f8:	f0c70713          	addi	a4,a4,-244 # 80024000 <disk>
    800060fc:	00c75793          	srli	a5,a4,0xc
    80006100:	2781                	sext.w	a5,a5
    80006102:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006104:	00020797          	auipc	a5,0x20
    80006108:	efc78793          	addi	a5,a5,-260 # 80026000 <disk+0x2000>
    8000610c:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000610e:	0001e717          	auipc	a4,0x1e
    80006112:	f7270713          	addi	a4,a4,-142 # 80024080 <disk+0x80>
    80006116:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006118:	0001f717          	auipc	a4,0x1f
    8000611c:	ee870713          	addi	a4,a4,-280 # 80025000 <disk+0x1000>
    80006120:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006122:	4705                	li	a4,1
    80006124:	00e78c23          	sb	a4,24(a5)
    80006128:	00e78ca3          	sb	a4,25(a5)
    8000612c:	00e78d23          	sb	a4,26(a5)
    80006130:	00e78da3          	sb	a4,27(a5)
    80006134:	00e78e23          	sb	a4,28(a5)
    80006138:	00e78ea3          	sb	a4,29(a5)
    8000613c:	00e78f23          	sb	a4,30(a5)
    80006140:	00e78fa3          	sb	a4,31(a5)
}
    80006144:	60e2                	ld	ra,24(sp)
    80006146:	6442                	ld	s0,16(sp)
    80006148:	64a2                	ld	s1,8(sp)
    8000614a:	6105                	addi	sp,sp,32
    8000614c:	8082                	ret
    panic("could not find virtio disk");
    8000614e:	00002517          	auipc	a0,0x2
    80006152:	66250513          	addi	a0,a0,1634 # 800087b0 <syscalls+0x3a8>
    80006156:	ffffa097          	auipc	ra,0xffffa
    8000615a:	49c080e7          	jalr	1180(ra) # 800005f2 <panic>
    panic("virtio disk has no queue 0");
    8000615e:	00002517          	auipc	a0,0x2
    80006162:	67250513          	addi	a0,a0,1650 # 800087d0 <syscalls+0x3c8>
    80006166:	ffffa097          	auipc	ra,0xffffa
    8000616a:	48c080e7          	jalr	1164(ra) # 800005f2 <panic>
    panic("virtio disk max queue too short");
    8000616e:	00002517          	auipc	a0,0x2
    80006172:	68250513          	addi	a0,a0,1666 # 800087f0 <syscalls+0x3e8>
    80006176:	ffffa097          	auipc	ra,0xffffa
    8000617a:	47c080e7          	jalr	1148(ra) # 800005f2 <panic>

000000008000617e <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000617e:	7159                	addi	sp,sp,-112
    80006180:	f486                	sd	ra,104(sp)
    80006182:	f0a2                	sd	s0,96(sp)
    80006184:	eca6                	sd	s1,88(sp)
    80006186:	e8ca                	sd	s2,80(sp)
    80006188:	e4ce                	sd	s3,72(sp)
    8000618a:	e0d2                	sd	s4,64(sp)
    8000618c:	fc56                	sd	s5,56(sp)
    8000618e:	f85a                	sd	s6,48(sp)
    80006190:	f45e                	sd	s7,40(sp)
    80006192:	f062                	sd	s8,32(sp)
    80006194:	1880                	addi	s0,sp,112
    80006196:	892a                	mv	s2,a0
    80006198:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000619a:	00c52b83          	lw	s7,12(a0)
    8000619e:	001b9b9b          	slliw	s7,s7,0x1
    800061a2:	1b82                	slli	s7,s7,0x20
    800061a4:	020bdb93          	srli	s7,s7,0x20

  acquire(&disk.vdisk_lock);
    800061a8:	00020517          	auipc	a0,0x20
    800061ac:	f0050513          	addi	a0,a0,-256 # 800260a8 <disk+0x20a8>
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	b06080e7          	jalr	-1274(ra) # 80000cb6 <acquire>
    if(disk.free[i]){
    800061b8:	00020997          	auipc	s3,0x20
    800061bc:	e4898993          	addi	s3,s3,-440 # 80026000 <disk+0x2000>
  for(int i = 0; i < NUM; i++){
    800061c0:	4b21                	li	s6,8
      disk.free[i] = 0;
    800061c2:	0001ea97          	auipc	s5,0x1e
    800061c6:	e3ea8a93          	addi	s5,s5,-450 # 80024000 <disk>
  for(int i = 0; i < 3; i++){
    800061ca:	4a0d                	li	s4,3
    800061cc:	a079                	j	8000625a <virtio_disk_rw+0xdc>
      disk.free[i] = 0;
    800061ce:	00fa86b3          	add	a3,s5,a5
    800061d2:	96ae                	add	a3,a3,a1
    800061d4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061d8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061da:	0207ca63          	bltz	a5,8000620e <virtio_disk_rw+0x90>
  for(int i = 0; i < 3; i++){
    800061de:	2485                	addiw	s1,s1,1
    800061e0:	0711                	addi	a4,a4,4
    800061e2:	25448163          	beq	s1,s4,80006424 <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800061e6:	863a                	mv	a2,a4
    if(disk.free[i]){
    800061e8:	0189c783          	lbu	a5,24(s3)
    800061ec:	24079163          	bnez	a5,8000642e <virtio_disk_rw+0x2b0>
    800061f0:	00020697          	auipc	a3,0x20
    800061f4:	e2968693          	addi	a3,a3,-471 # 80026019 <disk+0x2019>
  for(int i = 0; i < NUM; i++){
    800061f8:	87aa                	mv	a5,a0
    if(disk.free[i]){
    800061fa:	0006c803          	lbu	a6,0(a3)
    800061fe:	fc0818e3          	bnez	a6,800061ce <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80006202:	2785                	addiw	a5,a5,1
    80006204:	0685                	addi	a3,a3,1
    80006206:	ff679ae3          	bne	a5,s6,800061fa <virtio_disk_rw+0x7c>
    idx[i] = alloc_desc();
    8000620a:	57fd                	li	a5,-1
    8000620c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000620e:	02905a63          	blez	s1,80006242 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    80006212:	fa042503          	lw	a0,-96(s0)
    80006216:	00000097          	auipc	ra,0x0
    8000621a:	da0080e7          	jalr	-608(ra) # 80005fb6 <free_desc>
      for(int j = 0; j < i; j++)
    8000621e:	4785                	li	a5,1
    80006220:	0297d163          	ble	s1,a5,80006242 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    80006224:	fa442503          	lw	a0,-92(s0)
    80006228:	00000097          	auipc	ra,0x0
    8000622c:	d8e080e7          	jalr	-626(ra) # 80005fb6 <free_desc>
      for(int j = 0; j < i; j++)
    80006230:	4789                	li	a5,2
    80006232:	0097d863          	ble	s1,a5,80006242 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    80006236:	fa842503          	lw	a0,-88(s0)
    8000623a:	00000097          	auipc	ra,0x0
    8000623e:	d7c080e7          	jalr	-644(ra) # 80005fb6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006242:	00020597          	auipc	a1,0x20
    80006246:	e6658593          	addi	a1,a1,-410 # 800260a8 <disk+0x20a8>
    8000624a:	00020517          	auipc	a0,0x20
    8000624e:	dce50513          	addi	a0,a0,-562 # 80026018 <disk+0x2018>
    80006252:	ffffc097          	auipc	ra,0xffffc
    80006256:	10c080e7          	jalr	268(ra) # 8000235e <sleep>
  for(int i = 0; i < 3; i++){
    8000625a:	fa040713          	addi	a4,s0,-96
    8000625e:	4481                	li	s1,0
  for(int i = 0; i < NUM; i++){
    80006260:	4505                	li	a0,1
      disk.free[i] = 0;
    80006262:	6589                	lui	a1,0x2
    80006264:	b749                	j	800061e6 <virtio_disk_rw+0x68>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006266:	4785                	li	a5,1
    80006268:	f8f42823          	sw	a5,-112(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000626c:	f8042a23          	sw	zero,-108(s0)
  buf0.sector = sector;
    80006270:	f9743c23          	sd	s7,-104(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006274:	fa042983          	lw	s3,-96(s0)
    80006278:	00499493          	slli	s1,s3,0x4
    8000627c:	00020a17          	auipc	s4,0x20
    80006280:	d84a0a13          	addi	s4,s4,-636 # 80026000 <disk+0x2000>
    80006284:	000a3a83          	ld	s5,0(s4)
    80006288:	9aa6                	add	s5,s5,s1
    8000628a:	f9040513          	addi	a0,s0,-112
    8000628e:	ffffb097          	auipc	ra,0xffffb
    80006292:	f1c080e7          	jalr	-228(ra) # 800011aa <kvmpa>
    80006296:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000629a:	000a3783          	ld	a5,0(s4)
    8000629e:	97a6                	add	a5,a5,s1
    800062a0:	4741                	li	a4,16
    800062a2:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062a4:	000a3783          	ld	a5,0(s4)
    800062a8:	97a6                	add	a5,a5,s1
    800062aa:	4705                	li	a4,1
    800062ac:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800062b0:	fa442703          	lw	a4,-92(s0)
    800062b4:	000a3783          	ld	a5,0(s4)
    800062b8:	97a6                	add	a5,a5,s1
    800062ba:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062be:	0712                	slli	a4,a4,0x4
    800062c0:	000a3783          	ld	a5,0(s4)
    800062c4:	97ba                	add	a5,a5,a4
    800062c6:	05890693          	addi	a3,s2,88
    800062ca:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800062cc:	000a3783          	ld	a5,0(s4)
    800062d0:	97ba                	add	a5,a5,a4
    800062d2:	40000693          	li	a3,1024
    800062d6:	c794                	sw	a3,8(a5)
  if(write)
    800062d8:	100c0863          	beqz	s8,800063e8 <virtio_disk_rw+0x26a>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062dc:	000a3783          	ld	a5,0(s4)
    800062e0:	97ba                	add	a5,a5,a4
    800062e2:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062e6:	0001e517          	auipc	a0,0x1e
    800062ea:	d1a50513          	addi	a0,a0,-742 # 80024000 <disk>
    800062ee:	00020797          	auipc	a5,0x20
    800062f2:	d1278793          	addi	a5,a5,-750 # 80026000 <disk+0x2000>
    800062f6:	6394                	ld	a3,0(a5)
    800062f8:	96ba                	add	a3,a3,a4
    800062fa:	00c6d603          	lhu	a2,12(a3)
    800062fe:	00166613          	ori	a2,a2,1
    80006302:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006306:	fa842683          	lw	a3,-88(s0)
    8000630a:	6390                	ld	a2,0(a5)
    8000630c:	9732                	add	a4,a4,a2
    8000630e:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006312:	20098613          	addi	a2,s3,512
    80006316:	0612                	slli	a2,a2,0x4
    80006318:	962a                	add	a2,a2,a0
    8000631a:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000631e:	00469713          	slli	a4,a3,0x4
    80006322:	6394                	ld	a3,0(a5)
    80006324:	96ba                	add	a3,a3,a4
    80006326:	6589                	lui	a1,0x2
    80006328:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    8000632c:	94ae                	add	s1,s1,a1
    8000632e:	94aa                	add	s1,s1,a0
    80006330:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006332:	6394                	ld	a3,0(a5)
    80006334:	96ba                	add	a3,a3,a4
    80006336:	4585                	li	a1,1
    80006338:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000633a:	6394                	ld	a3,0(a5)
    8000633c:	96ba                	add	a3,a3,a4
    8000633e:	4509                	li	a0,2
    80006340:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006344:	6394                	ld	a3,0(a5)
    80006346:	9736                	add	a4,a4,a3
    80006348:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000634c:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006350:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006354:	6794                	ld	a3,8(a5)
    80006356:	0026d703          	lhu	a4,2(a3)
    8000635a:	8b1d                	andi	a4,a4,7
    8000635c:	2709                	addiw	a4,a4,2
    8000635e:	0706                	slli	a4,a4,0x1
    80006360:	9736                	add	a4,a4,a3
    80006362:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    80006366:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000636a:	6798                	ld	a4,8(a5)
    8000636c:	00275783          	lhu	a5,2(a4)
    80006370:	2785                	addiw	a5,a5,1
    80006372:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006376:	100017b7          	lui	a5,0x10001
    8000637a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000637e:	00492703          	lw	a4,4(s2)
    80006382:	4785                	li	a5,1
    80006384:	02f71163          	bne	a4,a5,800063a6 <virtio_disk_rw+0x228>
    sleep(b, &disk.vdisk_lock);
    80006388:	00020997          	auipc	s3,0x20
    8000638c:	d2098993          	addi	s3,s3,-736 # 800260a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006390:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006392:	85ce                	mv	a1,s3
    80006394:	854a                	mv	a0,s2
    80006396:	ffffc097          	auipc	ra,0xffffc
    8000639a:	fc8080e7          	jalr	-56(ra) # 8000235e <sleep>
  while(b->disk == 1) {
    8000639e:	00492783          	lw	a5,4(s2)
    800063a2:	fe9788e3          	beq	a5,s1,80006392 <virtio_disk_rw+0x214>
  }

  disk.info[idx[0]].b = 0;
    800063a6:	fa042483          	lw	s1,-96(s0)
    800063aa:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800063ae:	00479713          	slli	a4,a5,0x4
    800063b2:	0001e797          	auipc	a5,0x1e
    800063b6:	c4e78793          	addi	a5,a5,-946 # 80024000 <disk>
    800063ba:	97ba                	add	a5,a5,a4
    800063bc:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063c0:	00020917          	auipc	s2,0x20
    800063c4:	c4090913          	addi	s2,s2,-960 # 80026000 <disk+0x2000>
    free_desc(i);
    800063c8:	8526                	mv	a0,s1
    800063ca:	00000097          	auipc	ra,0x0
    800063ce:	bec080e7          	jalr	-1044(ra) # 80005fb6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800063d2:	0492                	slli	s1,s1,0x4
    800063d4:	00093783          	ld	a5,0(s2)
    800063d8:	94be                	add	s1,s1,a5
    800063da:	00c4d783          	lhu	a5,12(s1)
    800063de:	8b85                	andi	a5,a5,1
    800063e0:	cf91                	beqz	a5,800063fc <virtio_disk_rw+0x27e>
      i = disk.desc[i].next;
    800063e2:	00e4d483          	lhu	s1,14(s1)
  while(1){
    800063e6:	b7cd                	j	800063c8 <virtio_disk_rw+0x24a>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063e8:	00020797          	auipc	a5,0x20
    800063ec:	c1878793          	addi	a5,a5,-1000 # 80026000 <disk+0x2000>
    800063f0:	639c                	ld	a5,0(a5)
    800063f2:	97ba                	add	a5,a5,a4
    800063f4:	4689                	li	a3,2
    800063f6:	00d79623          	sh	a3,12(a5)
    800063fa:	b5f5                	j	800062e6 <virtio_disk_rw+0x168>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063fc:	00020517          	auipc	a0,0x20
    80006400:	cac50513          	addi	a0,a0,-852 # 800260a8 <disk+0x20a8>
    80006404:	ffffb097          	auipc	ra,0xffffb
    80006408:	966080e7          	jalr	-1690(ra) # 80000d6a <release>
}
    8000640c:	70a6                	ld	ra,104(sp)
    8000640e:	7406                	ld	s0,96(sp)
    80006410:	64e6                	ld	s1,88(sp)
    80006412:	6946                	ld	s2,80(sp)
    80006414:	69a6                	ld	s3,72(sp)
    80006416:	6a06                	ld	s4,64(sp)
    80006418:	7ae2                	ld	s5,56(sp)
    8000641a:	7b42                	ld	s6,48(sp)
    8000641c:	7ba2                	ld	s7,40(sp)
    8000641e:	7c02                	ld	s8,32(sp)
    80006420:	6165                	addi	sp,sp,112
    80006422:	8082                	ret
  if(write)
    80006424:	e40c11e3          	bnez	s8,80006266 <virtio_disk_rw+0xe8>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006428:	f8042823          	sw	zero,-112(s0)
    8000642c:	b581                	j	8000626c <virtio_disk_rw+0xee>
      disk.free[i] = 0;
    8000642e:	00098c23          	sb	zero,24(s3)
    idx[i] = alloc_desc();
    80006432:	00072023          	sw	zero,0(a4)
    if(idx[i] < 0){
    80006436:	b365                	j	800061de <virtio_disk_rw+0x60>

0000000080006438 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006438:	1101                	addi	sp,sp,-32
    8000643a:	ec06                	sd	ra,24(sp)
    8000643c:	e822                	sd	s0,16(sp)
    8000643e:	e426                	sd	s1,8(sp)
    80006440:	e04a                	sd	s2,0(sp)
    80006442:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006444:	00020517          	auipc	a0,0x20
    80006448:	c6450513          	addi	a0,a0,-924 # 800260a8 <disk+0x20a8>
    8000644c:	ffffb097          	auipc	ra,0xffffb
    80006450:	86a080e7          	jalr	-1942(ra) # 80000cb6 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006454:	00020797          	auipc	a5,0x20
    80006458:	bac78793          	addi	a5,a5,-1108 # 80026000 <disk+0x2000>
    8000645c:	0207d683          	lhu	a3,32(a5)
    80006460:	6b98                	ld	a4,16(a5)
    80006462:	00275783          	lhu	a5,2(a4)
    80006466:	8fb5                	xor	a5,a5,a3
    80006468:	8b9d                	andi	a5,a5,7
    8000646a:	c7c9                	beqz	a5,800064f4 <virtio_disk_intr+0xbc>
    int id = disk.used->elems[disk.used_idx].id;
    8000646c:	068e                	slli	a3,a3,0x3
    8000646e:	9736                	add	a4,a4,a3
    80006470:	435c                	lw	a5,4(a4)

    if(disk.info[id].status != 0)
    80006472:	20078713          	addi	a4,a5,512
    80006476:	00471693          	slli	a3,a4,0x4
    8000647a:	0001e717          	auipc	a4,0x1e
    8000647e:	b8670713          	addi	a4,a4,-1146 # 80024000 <disk>
    80006482:	9736                	add	a4,a4,a3
    80006484:	03074703          	lbu	a4,48(a4)
    80006488:	ef31                	bnez	a4,800064e4 <virtio_disk_intr+0xac>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000648a:	0001e917          	auipc	s2,0x1e
    8000648e:	b7690913          	addi	s2,s2,-1162 # 80024000 <disk>
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006492:	00020497          	auipc	s1,0x20
    80006496:	b6e48493          	addi	s1,s1,-1170 # 80026000 <disk+0x2000>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000649a:	20078793          	addi	a5,a5,512
    8000649e:	0792                	slli	a5,a5,0x4
    800064a0:	97ca                	add	a5,a5,s2
    800064a2:	7798                	ld	a4,40(a5)
    800064a4:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800064a8:	7788                	ld	a0,40(a5)
    800064aa:	ffffc097          	auipc	ra,0xffffc
    800064ae:	03a080e7          	jalr	58(ra) # 800024e4 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800064b2:	0204d783          	lhu	a5,32(s1)
    800064b6:	2785                	addiw	a5,a5,1
    800064b8:	8b9d                	andi	a5,a5,7
    800064ba:	03079613          	slli	a2,a5,0x30
    800064be:	9241                	srli	a2,a2,0x30
    800064c0:	02c49023          	sh	a2,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800064c4:	6898                	ld	a4,16(s1)
    800064c6:	00275683          	lhu	a3,2(a4)
    800064ca:	8a9d                	andi	a3,a3,7
    800064cc:	02c68463          	beq	a3,a2,800064f4 <virtio_disk_intr+0xbc>
    int id = disk.used->elems[disk.used_idx].id;
    800064d0:	078e                	slli	a5,a5,0x3
    800064d2:	97ba                	add	a5,a5,a4
    800064d4:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800064d6:	20078713          	addi	a4,a5,512
    800064da:	0712                	slli	a4,a4,0x4
    800064dc:	974a                	add	a4,a4,s2
    800064de:	03074703          	lbu	a4,48(a4)
    800064e2:	df45                	beqz	a4,8000649a <virtio_disk_intr+0x62>
      panic("virtio_disk_intr status");
    800064e4:	00002517          	auipc	a0,0x2
    800064e8:	32c50513          	addi	a0,a0,812 # 80008810 <syscalls+0x408>
    800064ec:	ffffa097          	auipc	ra,0xffffa
    800064f0:	106080e7          	jalr	262(ra) # 800005f2 <panic>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064f4:	10001737          	lui	a4,0x10001
    800064f8:	533c                	lw	a5,96(a4)
    800064fa:	8b8d                	andi	a5,a5,3
    800064fc:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800064fe:	00020517          	auipc	a0,0x20
    80006502:	baa50513          	addi	a0,a0,-1110 # 800260a8 <disk+0x20a8>
    80006506:	ffffb097          	auipc	ra,0xffffb
    8000650a:	864080e7          	jalr	-1948(ra) # 80000d6a <release>
}
    8000650e:	60e2                	ld	ra,24(sp)
    80006510:	6442                	ld	s0,16(sp)
    80006512:	64a2                	ld	s1,8(sp)
    80006514:	6902                	ld	s2,0(sp)
    80006516:	6105                	addi	sp,sp,32
    80006518:	8082                	ret
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
