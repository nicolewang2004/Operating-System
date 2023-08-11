
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8c013103          	ld	sp,-1856(sp) # 800088c0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000062:	d3278793          	addi	a5,a5,-718 # 80005d90 <timervec>
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
    8000012c:	422080e7          	jalr	1058(ra) # 8000254a <either_copyin>
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
    800001d4:	8a0080e7          	jalr	-1888(ra) # 80001a70 <myproc>
    800001d8:	591c                	lw	a5,48(a0)
    800001da:	eba5                	bnez	a5,8000024a <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001dc:	85ce                	mv	a1,s3
    800001de:	854a                	mv	a0,s2
    800001e0:	00002097          	auipc	ra,0x2
    800001e4:	0b2080e7          	jalr	178(ra) # 80002292 <sleep>
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
    80000220:	2d8080e7          	jalr	728(ra) # 800024f4 <either_copyout>
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
    8000041a:	18a080e7          	jalr	394(ra) # 800025a0 <procdump>
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
    8000047c:	fa0080e7          	jalr	-96(ra) # 80002418 <wakeup>
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
    800004ae:	70678793          	addi	a5,a5,1798 # 80021bb0 <devsw>
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
    800008f2:	b2a080e7          	jalr	-1238(ra) # 80002418 <wakeup>
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
    800009a2:	8f4080e7          	jalr	-1804(ra) # 80002292 <sleep>
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
    80000c00:	e58080e7          	jalr	-424(ra) # 80001a54 <mycpu>
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
    80000c32:	e26080e7          	jalr	-474(ra) # 80001a54 <mycpu>
    80000c36:	5d3c                	lw	a5,120(a0)
    80000c38:	cf89                	beqz	a5,80000c52 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c3a:	00001097          	auipc	ra,0x1
    80000c3e:	e1a080e7          	jalr	-486(ra) # 80001a54 <mycpu>
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
    80000c56:	e02080e7          	jalr	-510(ra) # 80001a54 <mycpu>
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
    80000c96:	dc2080e7          	jalr	-574(ra) # 80001a54 <mycpu>
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
    80000cc2:	d96080e7          	jalr	-618(ra) # 80001a54 <mycpu>
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
    80000f3e:	b0a080e7          	jalr	-1270(ra) # 80001a44 <cpuid>
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
    80000f5a:	aee080e7          	jalr	-1298(ra) # 80001a44 <cpuid>
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
    80000f7c:	76a080e7          	jalr	1898(ra) # 800026e2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	e50080e7          	jalr	-432(ra) # 80005dd0 <plicinithart>
  }

  scheduler();        
    80000f88:	00001097          	auipc	ra,0x1
    80000f8c:	02a080e7          	jalr	42(ra) # 80001fb2 <scheduler>
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
    80000fdc:	2a6080e7          	jalr	678(ra) # 8000127e <kvminit>
    kvminithart();   // turn on paging
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	068080e7          	jalr	104(ra) # 80001048 <kvminithart>
    procinit();      // process table
    80000fe8:	00001097          	auipc	ra,0x1
    80000fec:	98c080e7          	jalr	-1652(ra) # 80001974 <procinit>
    trapinit();      // trap vectors
    80000ff0:	00001097          	auipc	ra,0x1
    80000ff4:	6ca080e7          	jalr	1738(ra) # 800026ba <trapinit>
    trapinithart();  // install kernel trap vector
    80000ff8:	00001097          	auipc	ra,0x1
    80000ffc:	6ea080e7          	jalr	1770(ra) # 800026e2 <trapinithart>
    plicinit();      // set up interrupt controller
    80001000:	00005097          	auipc	ra,0x5
    80001004:	dba080e7          	jalr	-582(ra) # 80005dba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001008:	00005097          	auipc	ra,0x5
    8000100c:	dc8080e7          	jalr	-568(ra) # 80005dd0 <plicinithart>
    binit();         // buffer cache
    80001010:	00002097          	auipc	ra,0x2
    80001014:	e9a080e7          	jalr	-358(ra) # 80002eaa <binit>
    iinit();         // inode cache
    80001018:	00002097          	auipc	ra,0x2
    8000101c:	56c080e7          	jalr	1388(ra) # 80003584 <iinit>
    fileinit();      // file table
    80001020:	00003097          	auipc	ra,0x3
    80001024:	532080e7          	jalr	1330(ra) # 80004552 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001028:	00005097          	auipc	ra,0x5
    8000102c:	eb2080e7          	jalr	-334(ra) # 80005eda <virtio_disk_init>
    userinit();      // first user process
    80001030:	00001097          	auipc	ra,0x1
    80001034:	d10080e7          	jalr	-752(ra) # 80001d40 <userinit>
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

0000000080001114 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001114:	57fd                	li	a5,-1
    80001116:	83e9                	srli	a5,a5,0x1a
    80001118:	00b7f463          	bleu	a1,a5,80001120 <walkaddr+0xc>
    return 0;
    8000111c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000111e:	8082                	ret
{
    80001120:	1141                	addi	sp,sp,-16
    80001122:	e406                	sd	ra,8(sp)
    80001124:	e022                	sd	s0,0(sp)
    80001126:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001128:	4601                	li	a2,0
    8000112a:	00000097          	auipc	ra,0x0
    8000112e:	f44080e7          	jalr	-188(ra) # 8000106e <walk>
  if(pte == 0)
    80001132:	c105                	beqz	a0,80001152 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001134:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001136:	0117f693          	andi	a3,a5,17
    8000113a:	4745                	li	a4,17
    return 0;
    8000113c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000113e:	00e68663          	beq	a3,a4,8000114a <walkaddr+0x36>
}
    80001142:	60a2                	ld	ra,8(sp)
    80001144:	6402                	ld	s0,0(sp)
    80001146:	0141                	addi	sp,sp,16
    80001148:	8082                	ret
  pa = PTE2PA(*pte);
    8000114a:	00a7d513          	srli	a0,a5,0xa
    8000114e:	0532                	slli	a0,a0,0xc
  return pa;
    80001150:	bfcd                	j	80001142 <walkaddr+0x2e>
    return 0;
    80001152:	4501                	li	a0,0
    80001154:	b7fd                	j	80001142 <walkaddr+0x2e>

0000000080001156 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001156:	1101                	addi	sp,sp,-32
    80001158:	ec06                	sd	ra,24(sp)
    8000115a:	e822                	sd	s0,16(sp)
    8000115c:	e426                	sd	s1,8(sp)
    8000115e:	1000                	addi	s0,sp,32
    80001160:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001162:	6785                	lui	a5,0x1
    80001164:	17fd                	addi	a5,a5,-1
    80001166:	00f574b3          	and	s1,a0,a5
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    8000116a:	4601                	li	a2,0
    8000116c:	00008797          	auipc	a5,0x8
    80001170:	ea478793          	addi	a5,a5,-348 # 80009010 <kernel_pagetable>
    80001174:	6388                	ld	a0,0(a5)
    80001176:	00000097          	auipc	ra,0x0
    8000117a:	ef8080e7          	jalr	-264(ra) # 8000106e <walk>
  if(pte == 0)
    8000117e:	cd09                	beqz	a0,80001198 <kvmpa+0x42>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001180:	6108                	ld	a0,0(a0)
    80001182:	00157793          	andi	a5,a0,1
    80001186:	c38d                	beqz	a5,800011a8 <kvmpa+0x52>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001188:	8129                	srli	a0,a0,0xa
    8000118a:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000118c:	9526                	add	a0,a0,s1
    8000118e:	60e2                	ld	ra,24(sp)
    80001190:	6442                	ld	s0,16(sp)
    80001192:	64a2                	ld	s1,8(sp)
    80001194:	6105                	addi	sp,sp,32
    80001196:	8082                	ret
    panic("kvmpa");
    80001198:	00007517          	auipc	a0,0x7
    8000119c:	f4050513          	addi	a0,a0,-192 # 800080d8 <digits+0xc0>
    800011a0:	fffff097          	auipc	ra,0xfffff
    800011a4:	3d4080e7          	jalr	980(ra) # 80000574 <panic>
    panic("kvmpa");
    800011a8:	00007517          	auipc	a0,0x7
    800011ac:	f3050513          	addi	a0,a0,-208 # 800080d8 <digits+0xc0>
    800011b0:	fffff097          	auipc	ra,0xfffff
    800011b4:	3c4080e7          	jalr	964(ra) # 80000574 <panic>

00000000800011b8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011b8:	715d                	addi	sp,sp,-80
    800011ba:	e486                	sd	ra,72(sp)
    800011bc:	e0a2                	sd	s0,64(sp)
    800011be:	fc26                	sd	s1,56(sp)
    800011c0:	f84a                	sd	s2,48(sp)
    800011c2:	f44e                	sd	s3,40(sp)
    800011c4:	f052                	sd	s4,32(sp)
    800011c6:	ec56                	sd	s5,24(sp)
    800011c8:	e85a                	sd	s6,16(sp)
    800011ca:	e45e                	sd	s7,8(sp)
    800011cc:	0880                	addi	s0,sp,80
    800011ce:	8aaa                	mv	s5,a0
    800011d0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011d2:	79fd                	lui	s3,0xfffff
    800011d4:	0135fa33          	and	s4,a1,s3
  last = PGROUNDDOWN(va + size - 1);
    800011d8:	167d                	addi	a2,a2,-1
    800011da:	962e                	add	a2,a2,a1
    800011dc:	013679b3          	and	s3,a2,s3
  a = PGROUNDDOWN(va);
    800011e0:	8952                	mv	s2,s4
    800011e2:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011e6:	6b85                	lui	s7,0x1
    800011e8:	a811                	j	800011fc <mappages+0x44>
      panic("remap");
    800011ea:	00007517          	auipc	a0,0x7
    800011ee:	ef650513          	addi	a0,a0,-266 # 800080e0 <digits+0xc8>
    800011f2:	fffff097          	auipc	ra,0xfffff
    800011f6:	382080e7          	jalr	898(ra) # 80000574 <panic>
    a += PGSIZE;
    800011fa:	995e                	add	s2,s2,s7
  for(;;){
    800011fc:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001200:	4605                	li	a2,1
    80001202:	85ca                	mv	a1,s2
    80001204:	8556                	mv	a0,s5
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	e68080e7          	jalr	-408(ra) # 8000106e <walk>
    8000120e:	cd19                	beqz	a0,8000122c <mappages+0x74>
    if(*pte & PTE_V)
    80001210:	611c                	ld	a5,0(a0)
    80001212:	8b85                	andi	a5,a5,1
    80001214:	fbf9                	bnez	a5,800011ea <mappages+0x32>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001216:	80b1                	srli	s1,s1,0xc
    80001218:	04aa                	slli	s1,s1,0xa
    8000121a:	0164e4b3          	or	s1,s1,s6
    8000121e:	0014e493          	ori	s1,s1,1
    80001222:	e104                	sd	s1,0(a0)
    if(a == last)
    80001224:	fd391be3          	bne	s2,s3,800011fa <mappages+0x42>
    pa += PGSIZE;
  }
  return 0;
    80001228:	4501                	li	a0,0
    8000122a:	a011                	j	8000122e <mappages+0x76>
      return -1;
    8000122c:	557d                	li	a0,-1
}
    8000122e:	60a6                	ld	ra,72(sp)
    80001230:	6406                	ld	s0,64(sp)
    80001232:	74e2                	ld	s1,56(sp)
    80001234:	7942                	ld	s2,48(sp)
    80001236:	79a2                	ld	s3,40(sp)
    80001238:	7a02                	ld	s4,32(sp)
    8000123a:	6ae2                	ld	s5,24(sp)
    8000123c:	6b42                	ld	s6,16(sp)
    8000123e:	6ba2                	ld	s7,8(sp)
    80001240:	6161                	addi	sp,sp,80
    80001242:	8082                	ret

0000000080001244 <kvmmap>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000124c:	8736                	mv	a4,a3
    8000124e:	86ae                	mv	a3,a1
    80001250:	85aa                	mv	a1,a0
    80001252:	00008797          	auipc	a5,0x8
    80001256:	dbe78793          	addi	a5,a5,-578 # 80009010 <kernel_pagetable>
    8000125a:	6388                	ld	a0,0(a5)
    8000125c:	00000097          	auipc	ra,0x0
    80001260:	f5c080e7          	jalr	-164(ra) # 800011b8 <mappages>
    80001264:	e509                	bnez	a0,8000126e <kvmmap+0x2a>
}
    80001266:	60a2                	ld	ra,8(sp)
    80001268:	6402                	ld	s0,0(sp)
    8000126a:	0141                	addi	sp,sp,16
    8000126c:	8082                	ret
    panic("kvmmap");
    8000126e:	00007517          	auipc	a0,0x7
    80001272:	e7a50513          	addi	a0,a0,-390 # 800080e8 <digits+0xd0>
    80001276:	fffff097          	auipc	ra,0xfffff
    8000127a:	2fe080e7          	jalr	766(ra) # 80000574 <panic>

000000008000127e <kvminit>:
{
    8000127e:	1101                	addi	sp,sp,-32
    80001280:	ec06                	sd	ra,24(sp)
    80001282:	e822                	sd	s0,16(sp)
    80001284:	e426                	sd	s1,8(sp)
    80001286:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001288:	00000097          	auipc	ra,0x0
    8000128c:	8ea080e7          	jalr	-1814(ra) # 80000b72 <kalloc>
    80001290:	00008797          	auipc	a5,0x8
    80001294:	d8a7b023          	sd	a0,-640(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001298:	6605                	lui	a2,0x1
    8000129a:	4581                	li	a1,0
    8000129c:	00000097          	auipc	ra,0x0
    800012a0:	ac2080e7          	jalr	-1342(ra) # 80000d5e <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012a4:	4699                	li	a3,6
    800012a6:	6605                	lui	a2,0x1
    800012a8:	100005b7          	lui	a1,0x10000
    800012ac:	10000537          	lui	a0,0x10000
    800012b0:	00000097          	auipc	ra,0x0
    800012b4:	f94080e7          	jalr	-108(ra) # 80001244 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012b8:	4699                	li	a3,6
    800012ba:	6605                	lui	a2,0x1
    800012bc:	100015b7          	lui	a1,0x10001
    800012c0:	10001537          	lui	a0,0x10001
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f80080e7          	jalr	-128(ra) # 80001244 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012cc:	4699                	li	a3,6
    800012ce:	6641                	lui	a2,0x10
    800012d0:	020005b7          	lui	a1,0x2000
    800012d4:	02000537          	lui	a0,0x2000
    800012d8:	00000097          	auipc	ra,0x0
    800012dc:	f6c080e7          	jalr	-148(ra) # 80001244 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012e0:	4699                	li	a3,6
    800012e2:	00400637          	lui	a2,0x400
    800012e6:	0c0005b7          	lui	a1,0xc000
    800012ea:	0c000537          	lui	a0,0xc000
    800012ee:	00000097          	auipc	ra,0x0
    800012f2:	f56080e7          	jalr	-170(ra) # 80001244 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012f6:	00007497          	auipc	s1,0x7
    800012fa:	d0a48493          	addi	s1,s1,-758 # 80008000 <etext>
    800012fe:	46a9                	li	a3,10
    80001300:	80007617          	auipc	a2,0x80007
    80001304:	d0060613          	addi	a2,a2,-768 # 8000 <_entry-0x7fff8000>
    80001308:	4585                	li	a1,1
    8000130a:	05fe                	slli	a1,a1,0x1f
    8000130c:	852e                	mv	a0,a1
    8000130e:	00000097          	auipc	ra,0x0
    80001312:	f36080e7          	jalr	-202(ra) # 80001244 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001316:	4699                	li	a3,6
    80001318:	4645                	li	a2,17
    8000131a:	066e                	slli	a2,a2,0x1b
    8000131c:	8e05                	sub	a2,a2,s1
    8000131e:	85a6                	mv	a1,s1
    80001320:	8526                	mv	a0,s1
    80001322:	00000097          	auipc	ra,0x0
    80001326:	f22080e7          	jalr	-222(ra) # 80001244 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000132a:	46a9                	li	a3,10
    8000132c:	6605                	lui	a2,0x1
    8000132e:	00006597          	auipc	a1,0x6
    80001332:	cd258593          	addi	a1,a1,-814 # 80007000 <_trampoline>
    80001336:	04000537          	lui	a0,0x4000
    8000133a:	157d                	addi	a0,a0,-1
    8000133c:	0532                	slli	a0,a0,0xc
    8000133e:	00000097          	auipc	ra,0x0
    80001342:	f06080e7          	jalr	-250(ra) # 80001244 <kvmmap>
}
    80001346:	60e2                	ld	ra,24(sp)
    80001348:	6442                	ld	s0,16(sp)
    8000134a:	64a2                	ld	s1,8(sp)
    8000134c:	6105                	addi	sp,sp,32
    8000134e:	8082                	ret

0000000080001350 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001350:	715d                	addi	sp,sp,-80
    80001352:	e486                	sd	ra,72(sp)
    80001354:	e0a2                	sd	s0,64(sp)
    80001356:	fc26                	sd	s1,56(sp)
    80001358:	f84a                	sd	s2,48(sp)
    8000135a:	f44e                	sd	s3,40(sp)
    8000135c:	f052                	sd	s4,32(sp)
    8000135e:	ec56                	sd	s5,24(sp)
    80001360:	e85a                	sd	s6,16(sp)
    80001362:	e45e                	sd	s7,8(sp)
    80001364:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001366:	6785                	lui	a5,0x1
    80001368:	17fd                	addi	a5,a5,-1
    8000136a:	8fed                	and	a5,a5,a1
    8000136c:	e795                	bnez	a5,80001398 <uvmunmap+0x48>
    8000136e:	8a2a                	mv	s4,a0
    80001370:	84ae                	mv	s1,a1
    80001372:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001374:	0632                	slli	a2,a2,0xc
    80001376:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000137a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000137c:	6b05                	lui	s6,0x1
    8000137e:	0735e863          	bltu	a1,s3,800013ee <uvmunmap+0x9e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001382:	60a6                	ld	ra,72(sp)
    80001384:	6406                	ld	s0,64(sp)
    80001386:	74e2                	ld	s1,56(sp)
    80001388:	7942                	ld	s2,48(sp)
    8000138a:	79a2                	ld	s3,40(sp)
    8000138c:	7a02                	ld	s4,32(sp)
    8000138e:	6ae2                	ld	s5,24(sp)
    80001390:	6b42                	ld	s6,16(sp)
    80001392:	6ba2                	ld	s7,8(sp)
    80001394:	6161                	addi	sp,sp,80
    80001396:	8082                	ret
    panic("uvmunmap: not aligned");
    80001398:	00007517          	auipc	a0,0x7
    8000139c:	d5850513          	addi	a0,a0,-680 # 800080f0 <digits+0xd8>
    800013a0:	fffff097          	auipc	ra,0xfffff
    800013a4:	1d4080e7          	jalr	468(ra) # 80000574 <panic>
      panic("uvmunmap: walk");
    800013a8:	00007517          	auipc	a0,0x7
    800013ac:	d6050513          	addi	a0,a0,-672 # 80008108 <digits+0xf0>
    800013b0:	fffff097          	auipc	ra,0xfffff
    800013b4:	1c4080e7          	jalr	452(ra) # 80000574 <panic>
      panic("uvmunmap: not mapped");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	d6050513          	addi	a0,a0,-672 # 80008118 <digits+0x100>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	1b4080e7          	jalr	436(ra) # 80000574 <panic>
      panic("uvmunmap: not a leaf");
    800013c8:	00007517          	auipc	a0,0x7
    800013cc:	d6850513          	addi	a0,a0,-664 # 80008130 <digits+0x118>
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	1a4080e7          	jalr	420(ra) # 80000574 <panic>
      uint64 pa = PTE2PA(*pte);
    800013d8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013da:	0532                	slli	a0,a0,0xc
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	696080e7          	jalr	1686(ra) # 80000a72 <kfree>
    *pte = 0;
    800013e4:	00093023          	sd	zero,0(s2)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013e8:	94da                	add	s1,s1,s6
    800013ea:	f934fce3          	bleu	s3,s1,80001382 <uvmunmap+0x32>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013ee:	4601                	li	a2,0
    800013f0:	85a6                	mv	a1,s1
    800013f2:	8552                	mv	a0,s4
    800013f4:	00000097          	auipc	ra,0x0
    800013f8:	c7a080e7          	jalr	-902(ra) # 8000106e <walk>
    800013fc:	892a                	mv	s2,a0
    800013fe:	d54d                	beqz	a0,800013a8 <uvmunmap+0x58>
    if((*pte & PTE_V) == 0)
    80001400:	6108                	ld	a0,0(a0)
    80001402:	00157793          	andi	a5,a0,1
    80001406:	dbcd                	beqz	a5,800013b8 <uvmunmap+0x68>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001408:	3ff57793          	andi	a5,a0,1023
    8000140c:	fb778ee3          	beq	a5,s7,800013c8 <uvmunmap+0x78>
    if(do_free){
    80001410:	fc0a8ae3          	beqz	s5,800013e4 <uvmunmap+0x94>
    80001414:	b7d1                	j	800013d8 <uvmunmap+0x88>

0000000080001416 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001416:	1101                	addi	sp,sp,-32
    80001418:	ec06                	sd	ra,24(sp)
    8000141a:	e822                	sd	s0,16(sp)
    8000141c:	e426                	sd	s1,8(sp)
    8000141e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001420:	fffff097          	auipc	ra,0xfffff
    80001424:	752080e7          	jalr	1874(ra) # 80000b72 <kalloc>
    80001428:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000142a:	c519                	beqz	a0,80001438 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000142c:	6605                	lui	a2,0x1
    8000142e:	4581                	li	a1,0
    80001430:	00000097          	auipc	ra,0x0
    80001434:	92e080e7          	jalr	-1746(ra) # 80000d5e <memset>
  return pagetable;
}
    80001438:	8526                	mv	a0,s1
    8000143a:	60e2                	ld	ra,24(sp)
    8000143c:	6442                	ld	s0,16(sp)
    8000143e:	64a2                	ld	s1,8(sp)
    80001440:	6105                	addi	sp,sp,32
    80001442:	8082                	ret

0000000080001444 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001444:	7179                	addi	sp,sp,-48
    80001446:	f406                	sd	ra,40(sp)
    80001448:	f022                	sd	s0,32(sp)
    8000144a:	ec26                	sd	s1,24(sp)
    8000144c:	e84a                	sd	s2,16(sp)
    8000144e:	e44e                	sd	s3,8(sp)
    80001450:	e052                	sd	s4,0(sp)
    80001452:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001454:	6785                	lui	a5,0x1
    80001456:	04f67863          	bleu	a5,a2,800014a6 <uvminit+0x62>
    8000145a:	8a2a                	mv	s4,a0
    8000145c:	89ae                	mv	s3,a1
    8000145e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001460:	fffff097          	auipc	ra,0xfffff
    80001464:	712080e7          	jalr	1810(ra) # 80000b72 <kalloc>
    80001468:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	8f0080e7          	jalr	-1808(ra) # 80000d5e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001476:	4779                	li	a4,30
    80001478:	86ca                	mv	a3,s2
    8000147a:	6605                	lui	a2,0x1
    8000147c:	4581                	li	a1,0
    8000147e:	8552                	mv	a0,s4
    80001480:	00000097          	auipc	ra,0x0
    80001484:	d38080e7          	jalr	-712(ra) # 800011b8 <mappages>
  memmove(mem, src, sz);
    80001488:	8626                	mv	a2,s1
    8000148a:	85ce                	mv	a1,s3
    8000148c:	854a                	mv	a0,s2
    8000148e:	00000097          	auipc	ra,0x0
    80001492:	93c080e7          	jalr	-1732(ra) # 80000dca <memmove>
}
    80001496:	70a2                	ld	ra,40(sp)
    80001498:	7402                	ld	s0,32(sp)
    8000149a:	64e2                	ld	s1,24(sp)
    8000149c:	6942                	ld	s2,16(sp)
    8000149e:	69a2                	ld	s3,8(sp)
    800014a0:	6a02                	ld	s4,0(sp)
    800014a2:	6145                	addi	sp,sp,48
    800014a4:	8082                	ret
    panic("inituvm: more than a page");
    800014a6:	00007517          	auipc	a0,0x7
    800014aa:	ca250513          	addi	a0,a0,-862 # 80008148 <digits+0x130>
    800014ae:	fffff097          	auipc	ra,0xfffff
    800014b2:	0c6080e7          	jalr	198(ra) # 80000574 <panic>

00000000800014b6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014b6:	1101                	addi	sp,sp,-32
    800014b8:	ec06                	sd	ra,24(sp)
    800014ba:	e822                	sd	s0,16(sp)
    800014bc:	e426                	sd	s1,8(sp)
    800014be:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014c0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014c2:	00b67d63          	bleu	a1,a2,800014dc <uvmdealloc+0x26>
    800014c6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014c8:	6605                	lui	a2,0x1
    800014ca:	167d                	addi	a2,a2,-1
    800014cc:	00c487b3          	add	a5,s1,a2
    800014d0:	777d                	lui	a4,0xfffff
    800014d2:	8ff9                	and	a5,a5,a4
    800014d4:	962e                	add	a2,a2,a1
    800014d6:	8e79                	and	a2,a2,a4
    800014d8:	00c7e863          	bltu	a5,a2,800014e8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014dc:	8526                	mv	a0,s1
    800014de:	60e2                	ld	ra,24(sp)
    800014e0:	6442                	ld	s0,16(sp)
    800014e2:	64a2                	ld	s1,8(sp)
    800014e4:	6105                	addi	sp,sp,32
    800014e6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014e8:	8e1d                	sub	a2,a2,a5
    800014ea:	8231                	srli	a2,a2,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014ec:	4685                	li	a3,1
    800014ee:	2601                	sext.w	a2,a2
    800014f0:	85be                	mv	a1,a5
    800014f2:	00000097          	auipc	ra,0x0
    800014f6:	e5e080e7          	jalr	-418(ra) # 80001350 <uvmunmap>
    800014fa:	b7cd                	j	800014dc <uvmdealloc+0x26>

00000000800014fc <uvmalloc>:
  if(newsz < oldsz)
    800014fc:	0ab66163          	bltu	a2,a1,8000159e <uvmalloc+0xa2>
{
    80001500:	7139                	addi	sp,sp,-64
    80001502:	fc06                	sd	ra,56(sp)
    80001504:	f822                	sd	s0,48(sp)
    80001506:	f426                	sd	s1,40(sp)
    80001508:	f04a                	sd	s2,32(sp)
    8000150a:	ec4e                	sd	s3,24(sp)
    8000150c:	e852                	sd	s4,16(sp)
    8000150e:	e456                	sd	s5,8(sp)
    80001510:	0080                	addi	s0,sp,64
  oldsz = PGROUNDUP(oldsz);
    80001512:	6a05                	lui	s4,0x1
    80001514:	1a7d                	addi	s4,s4,-1
    80001516:	95d2                	add	a1,a1,s4
    80001518:	7a7d                	lui	s4,0xfffff
    8000151a:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000151e:	08ca7263          	bleu	a2,s4,800015a2 <uvmalloc+0xa6>
    80001522:	89b2                	mv	s3,a2
    80001524:	8aaa                	mv	s5,a0
    80001526:	8952                	mv	s2,s4
    mem = kalloc();
    80001528:	fffff097          	auipc	ra,0xfffff
    8000152c:	64a080e7          	jalr	1610(ra) # 80000b72 <kalloc>
    80001530:	84aa                	mv	s1,a0
    if(mem == 0){
    80001532:	c51d                	beqz	a0,80001560 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001534:	6605                	lui	a2,0x1
    80001536:	4581                	li	a1,0
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	826080e7          	jalr	-2010(ra) # 80000d5e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001540:	4779                	li	a4,30
    80001542:	86a6                	mv	a3,s1
    80001544:	6605                	lui	a2,0x1
    80001546:	85ca                	mv	a1,s2
    80001548:	8556                	mv	a0,s5
    8000154a:	00000097          	auipc	ra,0x0
    8000154e:	c6e080e7          	jalr	-914(ra) # 800011b8 <mappages>
    80001552:	e905                	bnez	a0,80001582 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001554:	6785                	lui	a5,0x1
    80001556:	993e                	add	s2,s2,a5
    80001558:	fd3968e3          	bltu	s2,s3,80001528 <uvmalloc+0x2c>
  return newsz;
    8000155c:	854e                	mv	a0,s3
    8000155e:	a809                	j	80001570 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001560:	8652                	mv	a2,s4
    80001562:	85ca                	mv	a1,s2
    80001564:	8556                	mv	a0,s5
    80001566:	00000097          	auipc	ra,0x0
    8000156a:	f50080e7          	jalr	-176(ra) # 800014b6 <uvmdealloc>
      return 0;
    8000156e:	4501                	li	a0,0
}
    80001570:	70e2                	ld	ra,56(sp)
    80001572:	7442                	ld	s0,48(sp)
    80001574:	74a2                	ld	s1,40(sp)
    80001576:	7902                	ld	s2,32(sp)
    80001578:	69e2                	ld	s3,24(sp)
    8000157a:	6a42                	ld	s4,16(sp)
    8000157c:	6aa2                	ld	s5,8(sp)
    8000157e:	6121                	addi	sp,sp,64
    80001580:	8082                	ret
      kfree(mem);
    80001582:	8526                	mv	a0,s1
    80001584:	fffff097          	auipc	ra,0xfffff
    80001588:	4ee080e7          	jalr	1262(ra) # 80000a72 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000158c:	8652                	mv	a2,s4
    8000158e:	85ca                	mv	a1,s2
    80001590:	8556                	mv	a0,s5
    80001592:	00000097          	auipc	ra,0x0
    80001596:	f24080e7          	jalr	-220(ra) # 800014b6 <uvmdealloc>
      return 0;
    8000159a:	4501                	li	a0,0
    8000159c:	bfd1                	j	80001570 <uvmalloc+0x74>
    return oldsz;
    8000159e:	852e                	mv	a0,a1
}
    800015a0:	8082                	ret
  return newsz;
    800015a2:	8532                	mv	a0,a2
    800015a4:	b7f1                	j	80001570 <uvmalloc+0x74>

00000000800015a6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015a6:	7179                	addi	sp,sp,-48
    800015a8:	f406                	sd	ra,40(sp)
    800015aa:	f022                	sd	s0,32(sp)
    800015ac:	ec26                	sd	s1,24(sp)
    800015ae:	e84a                	sd	s2,16(sp)
    800015b0:	e44e                	sd	s3,8(sp)
    800015b2:	e052                	sd	s4,0(sp)
    800015b4:	1800                	addi	s0,sp,48
    800015b6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015b8:	84aa                	mv	s1,a0
    800015ba:	6905                	lui	s2,0x1
    800015bc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015be:	4985                	li	s3,1
    800015c0:	a821                	j	800015d8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015c2:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015c4:	0532                	slli	a0,a0,0xc
    800015c6:	00000097          	auipc	ra,0x0
    800015ca:	fe0080e7          	jalr	-32(ra) # 800015a6 <freewalk>
      pagetable[i] = 0;
    800015ce:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015d2:	04a1                	addi	s1,s1,8
    800015d4:	03248163          	beq	s1,s2,800015f6 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015d8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015da:	00f57793          	andi	a5,a0,15
    800015de:	ff3782e3          	beq	a5,s3,800015c2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015e2:	8905                	andi	a0,a0,1
    800015e4:	d57d                	beqz	a0,800015d2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015e6:	00007517          	auipc	a0,0x7
    800015ea:	b8250513          	addi	a0,a0,-1150 # 80008168 <digits+0x150>
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	f86080e7          	jalr	-122(ra) # 80000574 <panic>
    }
  }
  kfree((void*)pagetable);
    800015f6:	8552                	mv	a0,s4
    800015f8:	fffff097          	auipc	ra,0xfffff
    800015fc:	47a080e7          	jalr	1146(ra) # 80000a72 <kfree>
}
    80001600:	70a2                	ld	ra,40(sp)
    80001602:	7402                	ld	s0,32(sp)
    80001604:	64e2                	ld	s1,24(sp)
    80001606:	6942                	ld	s2,16(sp)
    80001608:	69a2                	ld	s3,8(sp)
    8000160a:	6a02                	ld	s4,0(sp)
    8000160c:	6145                	addi	sp,sp,48
    8000160e:	8082                	ret

0000000080001610 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001610:	1101                	addi	sp,sp,-32
    80001612:	ec06                	sd	ra,24(sp)
    80001614:	e822                	sd	s0,16(sp)
    80001616:	e426                	sd	s1,8(sp)
    80001618:	1000                	addi	s0,sp,32
    8000161a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000161c:	e999                	bnez	a1,80001632 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000161e:	8526                	mv	a0,s1
    80001620:	00000097          	auipc	ra,0x0
    80001624:	f86080e7          	jalr	-122(ra) # 800015a6 <freewalk>
}
    80001628:	60e2                	ld	ra,24(sp)
    8000162a:	6442                	ld	s0,16(sp)
    8000162c:	64a2                	ld	s1,8(sp)
    8000162e:	6105                	addi	sp,sp,32
    80001630:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001632:	6605                	lui	a2,0x1
    80001634:	167d                	addi	a2,a2,-1
    80001636:	962e                	add	a2,a2,a1
    80001638:	4685                	li	a3,1
    8000163a:	8231                	srli	a2,a2,0xc
    8000163c:	4581                	li	a1,0
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	d12080e7          	jalr	-750(ra) # 80001350 <uvmunmap>
    80001646:	bfe1                	j	8000161e <uvmfree+0xe>

0000000080001648 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001648:	c679                	beqz	a2,80001716 <uvmcopy+0xce>
{
    8000164a:	715d                	addi	sp,sp,-80
    8000164c:	e486                	sd	ra,72(sp)
    8000164e:	e0a2                	sd	s0,64(sp)
    80001650:	fc26                	sd	s1,56(sp)
    80001652:	f84a                	sd	s2,48(sp)
    80001654:	f44e                	sd	s3,40(sp)
    80001656:	f052                	sd	s4,32(sp)
    80001658:	ec56                	sd	s5,24(sp)
    8000165a:	e85a                	sd	s6,16(sp)
    8000165c:	e45e                	sd	s7,8(sp)
    8000165e:	0880                	addi	s0,sp,80
    80001660:	8ab2                	mv	s5,a2
    80001662:	8b2e                	mv	s6,a1
    80001664:	8baa                	mv	s7,a0
  for(i = 0; i < sz; i += PGSIZE){
    80001666:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    80001668:	4601                	li	a2,0
    8000166a:	85ca                	mv	a1,s2
    8000166c:	855e                	mv	a0,s7
    8000166e:	00000097          	auipc	ra,0x0
    80001672:	a00080e7          	jalr	-1536(ra) # 8000106e <walk>
    80001676:	c531                	beqz	a0,800016c2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001678:	6118                	ld	a4,0(a0)
    8000167a:	00177793          	andi	a5,a4,1
    8000167e:	cbb1                	beqz	a5,800016d2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001680:	00a75593          	srli	a1,a4,0xa
    80001684:	00c59993          	slli	s3,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001688:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000168c:	fffff097          	auipc	ra,0xfffff
    80001690:	4e6080e7          	jalr	1254(ra) # 80000b72 <kalloc>
    80001694:	8a2a                	mv	s4,a0
    80001696:	c939                	beqz	a0,800016ec <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001698:	6605                	lui	a2,0x1
    8000169a:	85ce                	mv	a1,s3
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	72e080e7          	jalr	1838(ra) # 80000dca <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016a4:	8726                	mv	a4,s1
    800016a6:	86d2                	mv	a3,s4
    800016a8:	6605                	lui	a2,0x1
    800016aa:	85ca                	mv	a1,s2
    800016ac:	855a                	mv	a0,s6
    800016ae:	00000097          	auipc	ra,0x0
    800016b2:	b0a080e7          	jalr	-1270(ra) # 800011b8 <mappages>
    800016b6:	e515                	bnez	a0,800016e2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016b8:	6785                	lui	a5,0x1
    800016ba:	993e                	add	s2,s2,a5
    800016bc:	fb5966e3          	bltu	s2,s5,80001668 <uvmcopy+0x20>
    800016c0:	a081                	j	80001700 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016c2:	00007517          	auipc	a0,0x7
    800016c6:	ab650513          	addi	a0,a0,-1354 # 80008178 <digits+0x160>
    800016ca:	fffff097          	auipc	ra,0xfffff
    800016ce:	eaa080e7          	jalr	-342(ra) # 80000574 <panic>
      panic("uvmcopy: page not present");
    800016d2:	00007517          	auipc	a0,0x7
    800016d6:	ac650513          	addi	a0,a0,-1338 # 80008198 <digits+0x180>
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	e9a080e7          	jalr	-358(ra) # 80000574 <panic>
      kfree(mem);
    800016e2:	8552                	mv	a0,s4
    800016e4:	fffff097          	auipc	ra,0xfffff
    800016e8:	38e080e7          	jalr	910(ra) # 80000a72 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016ec:	4685                	li	a3,1
    800016ee:	00c95613          	srli	a2,s2,0xc
    800016f2:	4581                	li	a1,0
    800016f4:	855a                	mv	a0,s6
    800016f6:	00000097          	auipc	ra,0x0
    800016fa:	c5a080e7          	jalr	-934(ra) # 80001350 <uvmunmap>
  return -1;
    800016fe:	557d                	li	a0,-1
}
    80001700:	60a6                	ld	ra,72(sp)
    80001702:	6406                	ld	s0,64(sp)
    80001704:	74e2                	ld	s1,56(sp)
    80001706:	7942                	ld	s2,48(sp)
    80001708:	79a2                	ld	s3,40(sp)
    8000170a:	7a02                	ld	s4,32(sp)
    8000170c:	6ae2                	ld	s5,24(sp)
    8000170e:	6b42                	ld	s6,16(sp)
    80001710:	6ba2                	ld	s7,8(sp)
    80001712:	6161                	addi	sp,sp,80
    80001714:	8082                	ret
  return 0;
    80001716:	4501                	li	a0,0
}
    80001718:	8082                	ret

000000008000171a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000171a:	1141                	addi	sp,sp,-16
    8000171c:	e406                	sd	ra,8(sp)
    8000171e:	e022                	sd	s0,0(sp)
    80001720:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001722:	4601                	li	a2,0
    80001724:	00000097          	auipc	ra,0x0
    80001728:	94a080e7          	jalr	-1718(ra) # 8000106e <walk>
  if(pte == 0)
    8000172c:	c901                	beqz	a0,8000173c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000172e:	611c                	ld	a5,0(a0)
    80001730:	9bbd                	andi	a5,a5,-17
    80001732:	e11c                	sd	a5,0(a0)
}
    80001734:	60a2                	ld	ra,8(sp)
    80001736:	6402                	ld	s0,0(sp)
    80001738:	0141                	addi	sp,sp,16
    8000173a:	8082                	ret
    panic("uvmclear");
    8000173c:	00007517          	auipc	a0,0x7
    80001740:	a7c50513          	addi	a0,a0,-1412 # 800081b8 <digits+0x1a0>
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	e30080e7          	jalr	-464(ra) # 80000574 <panic>

000000008000174c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000174c:	c6bd                	beqz	a3,800017ba <copyout+0x6e>
{
    8000174e:	715d                	addi	sp,sp,-80
    80001750:	e486                	sd	ra,72(sp)
    80001752:	e0a2                	sd	s0,64(sp)
    80001754:	fc26                	sd	s1,56(sp)
    80001756:	f84a                	sd	s2,48(sp)
    80001758:	f44e                	sd	s3,40(sp)
    8000175a:	f052                	sd	s4,32(sp)
    8000175c:	ec56                	sd	s5,24(sp)
    8000175e:	e85a                	sd	s6,16(sp)
    80001760:	e45e                	sd	s7,8(sp)
    80001762:	e062                	sd	s8,0(sp)
    80001764:	0880                	addi	s0,sp,80
    80001766:	8baa                	mv	s7,a0
    80001768:	8a2e                	mv	s4,a1
    8000176a:	8ab2                	mv	s5,a2
    8000176c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000176e:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001770:	6b05                	lui	s6,0x1
    80001772:	a015                	j	80001796 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001774:	9552                	add	a0,a0,s4
    80001776:	0004861b          	sext.w	a2,s1
    8000177a:	85d6                	mv	a1,s5
    8000177c:	41250533          	sub	a0,a0,s2
    80001780:	fffff097          	auipc	ra,0xfffff
    80001784:	64a080e7          	jalr	1610(ra) # 80000dca <memmove>

    len -= n;
    80001788:	409989b3          	sub	s3,s3,s1
    src += n;
    8000178c:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    8000178e:	01690a33          	add	s4,s2,s6
  while(len > 0){
    80001792:	02098263          	beqz	s3,800017b6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001796:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    8000179a:	85ca                	mv	a1,s2
    8000179c:	855e                	mv	a0,s7
    8000179e:	00000097          	auipc	ra,0x0
    800017a2:	976080e7          	jalr	-1674(ra) # 80001114 <walkaddr>
    if(pa0 == 0)
    800017a6:	cd01                	beqz	a0,800017be <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017a8:	414904b3          	sub	s1,s2,s4
    800017ac:	94da                	add	s1,s1,s6
    if(n > len)
    800017ae:	fc99f3e3          	bleu	s1,s3,80001774 <copyout+0x28>
    800017b2:	84ce                	mv	s1,s3
    800017b4:	b7c1                	j	80001774 <copyout+0x28>
  }
  return 0;
    800017b6:	4501                	li	a0,0
    800017b8:	a021                	j	800017c0 <copyout+0x74>
    800017ba:	4501                	li	a0,0
}
    800017bc:	8082                	ret
      return -1;
    800017be:	557d                	li	a0,-1
}
    800017c0:	60a6                	ld	ra,72(sp)
    800017c2:	6406                	ld	s0,64(sp)
    800017c4:	74e2                	ld	s1,56(sp)
    800017c6:	7942                	ld	s2,48(sp)
    800017c8:	79a2                	ld	s3,40(sp)
    800017ca:	7a02                	ld	s4,32(sp)
    800017cc:	6ae2                	ld	s5,24(sp)
    800017ce:	6b42                	ld	s6,16(sp)
    800017d0:	6ba2                	ld	s7,8(sp)
    800017d2:	6c02                	ld	s8,0(sp)
    800017d4:	6161                	addi	sp,sp,80
    800017d6:	8082                	ret

00000000800017d8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017d8:	caa5                	beqz	a3,80001848 <copyin+0x70>
{
    800017da:	715d                	addi	sp,sp,-80
    800017dc:	e486                	sd	ra,72(sp)
    800017de:	e0a2                	sd	s0,64(sp)
    800017e0:	fc26                	sd	s1,56(sp)
    800017e2:	f84a                	sd	s2,48(sp)
    800017e4:	f44e                	sd	s3,40(sp)
    800017e6:	f052                	sd	s4,32(sp)
    800017e8:	ec56                	sd	s5,24(sp)
    800017ea:	e85a                	sd	s6,16(sp)
    800017ec:	e45e                	sd	s7,8(sp)
    800017ee:	e062                	sd	s8,0(sp)
    800017f0:	0880                	addi	s0,sp,80
    800017f2:	8baa                	mv	s7,a0
    800017f4:	8aae                	mv	s5,a1
    800017f6:	8a32                	mv	s4,a2
    800017f8:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017fa:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017fc:	6b05                	lui	s6,0x1
    800017fe:	a01d                	j	80001824 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001800:	014505b3          	add	a1,a0,s4
    80001804:	0004861b          	sext.w	a2,s1
    80001808:	412585b3          	sub	a1,a1,s2
    8000180c:	8556                	mv	a0,s5
    8000180e:	fffff097          	auipc	ra,0xfffff
    80001812:	5bc080e7          	jalr	1468(ra) # 80000dca <memmove>

    len -= n;
    80001816:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000181a:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    8000181c:	01690a33          	add	s4,s2,s6
  while(len > 0){
    80001820:	02098263          	beqz	s3,80001844 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001824:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    80001828:	85ca                	mv	a1,s2
    8000182a:	855e                	mv	a0,s7
    8000182c:	00000097          	auipc	ra,0x0
    80001830:	8e8080e7          	jalr	-1816(ra) # 80001114 <walkaddr>
    if(pa0 == 0)
    80001834:	cd01                	beqz	a0,8000184c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001836:	414904b3          	sub	s1,s2,s4
    8000183a:	94da                	add	s1,s1,s6
    if(n > len)
    8000183c:	fc99f2e3          	bleu	s1,s3,80001800 <copyin+0x28>
    80001840:	84ce                	mv	s1,s3
    80001842:	bf7d                	j	80001800 <copyin+0x28>
  }
  return 0;
    80001844:	4501                	li	a0,0
    80001846:	a021                	j	8000184e <copyin+0x76>
    80001848:	4501                	li	a0,0
}
    8000184a:	8082                	ret
      return -1;
    8000184c:	557d                	li	a0,-1
}
    8000184e:	60a6                	ld	ra,72(sp)
    80001850:	6406                	ld	s0,64(sp)
    80001852:	74e2                	ld	s1,56(sp)
    80001854:	7942                	ld	s2,48(sp)
    80001856:	79a2                	ld	s3,40(sp)
    80001858:	7a02                	ld	s4,32(sp)
    8000185a:	6ae2                	ld	s5,24(sp)
    8000185c:	6b42                	ld	s6,16(sp)
    8000185e:	6ba2                	ld	s7,8(sp)
    80001860:	6c02                	ld	s8,0(sp)
    80001862:	6161                	addi	sp,sp,80
    80001864:	8082                	ret

0000000080001866 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001866:	ced5                	beqz	a3,80001922 <copyinstr+0xbc>
{
    80001868:	715d                	addi	sp,sp,-80
    8000186a:	e486                	sd	ra,72(sp)
    8000186c:	e0a2                	sd	s0,64(sp)
    8000186e:	fc26                	sd	s1,56(sp)
    80001870:	f84a                	sd	s2,48(sp)
    80001872:	f44e                	sd	s3,40(sp)
    80001874:	f052                	sd	s4,32(sp)
    80001876:	ec56                	sd	s5,24(sp)
    80001878:	e85a                	sd	s6,16(sp)
    8000187a:	e45e                	sd	s7,8(sp)
    8000187c:	e062                	sd	s8,0(sp)
    8000187e:	0880                	addi	s0,sp,80
    80001880:	8aaa                	mv	s5,a0
    80001882:	84ae                	mv	s1,a1
    80001884:	8c32                	mv	s8,a2
    80001886:	8bb6                	mv	s7,a3
    va0 = PGROUNDDOWN(srcva);
    80001888:	7a7d                	lui	s4,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000188a:	6985                	lui	s3,0x1
    8000188c:	4b05                	li	s6,1
    8000188e:	a801                	j	8000189e <copyinstr+0x38>
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
    80001890:	87a6                	mv	a5,s1
    80001892:	a085                	j	800018f2 <copyinstr+0x8c>
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    80001894:	84b2                	mv	s1,a2
    }

    srcva = va0 + PGSIZE;
    80001896:	01390c33          	add	s8,s2,s3
  while(got_null == 0 && max > 0){
    8000189a:	080b8063          	beqz	s7,8000191a <copyinstr+0xb4>
    va0 = PGROUNDDOWN(srcva);
    8000189e:	014c7933          	and	s2,s8,s4
    pa0 = walkaddr(pagetable, va0);
    800018a2:	85ca                	mv	a1,s2
    800018a4:	8556                	mv	a0,s5
    800018a6:	00000097          	auipc	ra,0x0
    800018aa:	86e080e7          	jalr	-1938(ra) # 80001114 <walkaddr>
    if(pa0 == 0)
    800018ae:	c925                	beqz	a0,8000191e <copyinstr+0xb8>
    n = PGSIZE - (srcva - va0);
    800018b0:	41890633          	sub	a2,s2,s8
    800018b4:	964e                	add	a2,a2,s3
    if(n > max)
    800018b6:	00cbf363          	bleu	a2,s7,800018bc <copyinstr+0x56>
    800018ba:	865e                	mv	a2,s7
    char *p = (char *) (pa0 + (srcva - va0));
    800018bc:	9562                	add	a0,a0,s8
    800018be:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018c2:	da71                	beqz	a2,80001896 <copyinstr+0x30>
      if(*p == '\0'){
    800018c4:	00054703          	lbu	a4,0(a0)
    800018c8:	d761                	beqz	a4,80001890 <copyinstr+0x2a>
    800018ca:	9626                	add	a2,a2,s1
    800018cc:	87a6                	mv	a5,s1
    800018ce:	1bfd                	addi	s7,s7,-1
    800018d0:	009b86b3          	add	a3,s7,s1
    800018d4:	409b04b3          	sub	s1,s6,s1
    800018d8:	94aa                	add	s1,s1,a0
        *dst = *p;
    800018da:	00e78023          	sb	a4,0(a5) # 1000 <_entry-0x7ffff000>
      --max;
    800018de:	40f68bb3          	sub	s7,a3,a5
      p++;
    800018e2:	00f48733          	add	a4,s1,a5
      dst++;
    800018e6:	0785                	addi	a5,a5,1
    while(n > 0){
    800018e8:	faf606e3          	beq	a2,a5,80001894 <copyinstr+0x2e>
      if(*p == '\0'){
    800018ec:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018f0:	f76d                	bnez	a4,800018da <copyinstr+0x74>
        *dst = '\0';
    800018f2:	00078023          	sb	zero,0(a5)
    800018f6:	4785                	li	a5,1
  }
  if(got_null){
    800018f8:	0017b513          	seqz	a0,a5
    800018fc:	40a0053b          	negw	a0,a0
    80001900:	2501                	sext.w	a0,a0
    return 0;
  } else {
    return -1;
  }
}
    80001902:	60a6                	ld	ra,72(sp)
    80001904:	6406                	ld	s0,64(sp)
    80001906:	74e2                	ld	s1,56(sp)
    80001908:	7942                	ld	s2,48(sp)
    8000190a:	79a2                	ld	s3,40(sp)
    8000190c:	7a02                	ld	s4,32(sp)
    8000190e:	6ae2                	ld	s5,24(sp)
    80001910:	6b42                	ld	s6,16(sp)
    80001912:	6ba2                	ld	s7,8(sp)
    80001914:	6c02                	ld	s8,0(sp)
    80001916:	6161                	addi	sp,sp,80
    80001918:	8082                	ret
    8000191a:	4781                	li	a5,0
    8000191c:	bff1                	j	800018f8 <copyinstr+0x92>
      return -1;
    8000191e:	557d                	li	a0,-1
    80001920:	b7cd                	j	80001902 <copyinstr+0x9c>
  int got_null = 0;
    80001922:	4781                	li	a5,0
  if(got_null){
    80001924:	0017b513          	seqz	a0,a5
    80001928:	40a0053b          	negw	a0,a0
    8000192c:	2501                	sext.w	a0,a0
}
    8000192e:	8082                	ret

0000000080001930 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001930:	1101                	addi	sp,sp,-32
    80001932:	ec06                	sd	ra,24(sp)
    80001934:	e822                	sd	s0,16(sp)
    80001936:	e426                	sd	s1,8(sp)
    80001938:	1000                	addi	s0,sp,32
    8000193a:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000193c:	fffff097          	auipc	ra,0xfffff
    80001940:	2ac080e7          	jalr	684(ra) # 80000be8 <holding>
    80001944:	c909                	beqz	a0,80001956 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001946:	749c                	ld	a5,40(s1)
    80001948:	00978f63          	beq	a5,s1,80001966 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000194c:	60e2                	ld	ra,24(sp)
    8000194e:	6442                	ld	s0,16(sp)
    80001950:	64a2                	ld	s1,8(sp)
    80001952:	6105                	addi	sp,sp,32
    80001954:	8082                	ret
    panic("wakeup1");
    80001956:	00007517          	auipc	a0,0x7
    8000195a:	89a50513          	addi	a0,a0,-1894 # 800081f0 <states.1723+0x28>
    8000195e:	fffff097          	auipc	ra,0xfffff
    80001962:	c16080e7          	jalr	-1002(ra) # 80000574 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001966:	4c98                	lw	a4,24(s1)
    80001968:	4785                	li	a5,1
    8000196a:	fef711e3          	bne	a4,a5,8000194c <wakeup1+0x1c>
    p->state = RUNNABLE;
    8000196e:	4789                	li	a5,2
    80001970:	cc9c                	sw	a5,24(s1)
}
    80001972:	bfe9                	j	8000194c <wakeup1+0x1c>

0000000080001974 <procinit>:
{
    80001974:	715d                	addi	sp,sp,-80
    80001976:	e486                	sd	ra,72(sp)
    80001978:	e0a2                	sd	s0,64(sp)
    8000197a:	fc26                	sd	s1,56(sp)
    8000197c:	f84a                	sd	s2,48(sp)
    8000197e:	f44e                	sd	s3,40(sp)
    80001980:	f052                	sd	s4,32(sp)
    80001982:	ec56                	sd	s5,24(sp)
    80001984:	e85a                	sd	s6,16(sp)
    80001986:	e45e                	sd	s7,8(sp)
    80001988:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000198a:	00007597          	auipc	a1,0x7
    8000198e:	86e58593          	addi	a1,a1,-1938 # 800081f8 <states.1723+0x30>
    80001992:	00010517          	auipc	a0,0x10
    80001996:	fbe50513          	addi	a0,a0,-66 # 80011950 <pid_lock>
    8000199a:	fffff097          	auipc	ra,0xfffff
    8000199e:	238080e7          	jalr	568(ra) # 80000bd2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a2:	00010917          	auipc	s2,0x10
    800019a6:	3c690913          	addi	s2,s2,966 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    800019aa:	00007b97          	auipc	s7,0x7
    800019ae:	856b8b93          	addi	s7,s7,-1962 # 80008200 <states.1723+0x38>
      uint64 va = KSTACK((int) (p - proc));
    800019b2:	8b4a                	mv	s6,s2
    800019b4:	00006a97          	auipc	s5,0x6
    800019b8:	64ca8a93          	addi	s5,s5,1612 # 80008000 <etext>
    800019bc:	040009b7          	lui	s3,0x4000
    800019c0:	19fd                	addi	s3,s3,-1
    800019c2:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019c4:	00016a17          	auipc	s4,0x16
    800019c8:	fa4a0a13          	addi	s4,s4,-92 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    800019cc:	85de                	mv	a1,s7
    800019ce:	854a                	mv	a0,s2
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	202080e7          	jalr	514(ra) # 80000bd2 <initlock>
      char *pa = kalloc();
    800019d8:	fffff097          	auipc	ra,0xfffff
    800019dc:	19a080e7          	jalr	410(ra) # 80000b72 <kalloc>
    800019e0:	85aa                	mv	a1,a0
      if(pa == 0)
    800019e2:	c929                	beqz	a0,80001a34 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019e4:	416904b3          	sub	s1,s2,s6
    800019e8:	8491                	srai	s1,s1,0x4
    800019ea:	000ab783          	ld	a5,0(s5)
    800019ee:	02f484b3          	mul	s1,s1,a5
    800019f2:	2485                	addiw	s1,s1,1
    800019f4:	00d4949b          	slliw	s1,s1,0xd
    800019f8:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019fc:	4699                	li	a3,6
    800019fe:	6605                	lui	a2,0x1
    80001a00:	8526                	mv	a0,s1
    80001a02:	00000097          	auipc	ra,0x0
    80001a06:	842080e7          	jalr	-1982(ra) # 80001244 <kvmmap>
      p->kstack = va;
    80001a0a:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a0e:	17090913          	addi	s2,s2,368
    80001a12:	fb491de3          	bne	s2,s4,800019cc <procinit+0x58>
  kvminithart();
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	632080e7          	jalr	1586(ra) # 80001048 <kvminithart>
}
    80001a1e:	60a6                	ld	ra,72(sp)
    80001a20:	6406                	ld	s0,64(sp)
    80001a22:	74e2                	ld	s1,56(sp)
    80001a24:	7942                	ld	s2,48(sp)
    80001a26:	79a2                	ld	s3,40(sp)
    80001a28:	7a02                	ld	s4,32(sp)
    80001a2a:	6ae2                	ld	s5,24(sp)
    80001a2c:	6b42                	ld	s6,16(sp)
    80001a2e:	6ba2                	ld	s7,8(sp)
    80001a30:	6161                	addi	sp,sp,80
    80001a32:	8082                	ret
        panic("kalloc");
    80001a34:	00006517          	auipc	a0,0x6
    80001a38:	7d450513          	addi	a0,a0,2004 # 80008208 <states.1723+0x40>
    80001a3c:	fffff097          	auipc	ra,0xfffff
    80001a40:	b38080e7          	jalr	-1224(ra) # 80000574 <panic>

0000000080001a44 <cpuid>:
{
    80001a44:	1141                	addi	sp,sp,-16
    80001a46:	e422                	sd	s0,8(sp)
    80001a48:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a4a:	8512                	mv	a0,tp
}
    80001a4c:	2501                	sext.w	a0,a0
    80001a4e:	6422                	ld	s0,8(sp)
    80001a50:	0141                	addi	sp,sp,16
    80001a52:	8082                	ret

0000000080001a54 <mycpu>:
mycpu(void) {
    80001a54:	1141                	addi	sp,sp,-16
    80001a56:	e422                	sd	s0,8(sp)
    80001a58:	0800                	addi	s0,sp,16
    80001a5a:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a5c:	2781                	sext.w	a5,a5
    80001a5e:	079e                	slli	a5,a5,0x7
}
    80001a60:	00010517          	auipc	a0,0x10
    80001a64:	f0850513          	addi	a0,a0,-248 # 80011968 <cpus>
    80001a68:	953e                	add	a0,a0,a5
    80001a6a:	6422                	ld	s0,8(sp)
    80001a6c:	0141                	addi	sp,sp,16
    80001a6e:	8082                	ret

0000000080001a70 <myproc>:
myproc(void) {
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	1000                	addi	s0,sp,32
  push_off();
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	19c080e7          	jalr	412(ra) # 80000c16 <push_off>
    80001a82:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a84:	2781                	sext.w	a5,a5
    80001a86:	079e                	slli	a5,a5,0x7
    80001a88:	00010717          	auipc	a4,0x10
    80001a8c:	ec870713          	addi	a4,a4,-312 # 80011950 <pid_lock>
    80001a90:	97ba                	add	a5,a5,a4
    80001a92:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	222080e7          	jalr	546(ra) # 80000cb6 <pop_off>
}
    80001a9c:	8526                	mv	a0,s1
    80001a9e:	60e2                	ld	ra,24(sp)
    80001aa0:	6442                	ld	s0,16(sp)
    80001aa2:	64a2                	ld	s1,8(sp)
    80001aa4:	6105                	addi	sp,sp,32
    80001aa6:	8082                	ret

0000000080001aa8 <forkret>:
{
    80001aa8:	1141                	addi	sp,sp,-16
    80001aaa:	e406                	sd	ra,8(sp)
    80001aac:	e022                	sd	s0,0(sp)
    80001aae:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001ab0:	00000097          	auipc	ra,0x0
    80001ab4:	fc0080e7          	jalr	-64(ra) # 80001a70 <myproc>
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	25e080e7          	jalr	606(ra) # 80000d16 <release>
  if (first) {
    80001ac0:	00007797          	auipc	a5,0x7
    80001ac4:	db078793          	addi	a5,a5,-592 # 80008870 <first.1683>
    80001ac8:	439c                	lw	a5,0(a5)
    80001aca:	eb89                	bnez	a5,80001adc <forkret+0x34>
  usertrapret();
    80001acc:	00001097          	auipc	ra,0x1
    80001ad0:	c2e080e7          	jalr	-978(ra) # 800026fa <usertrapret>
}
    80001ad4:	60a2                	ld	ra,8(sp)
    80001ad6:	6402                	ld	s0,0(sp)
    80001ad8:	0141                	addi	sp,sp,16
    80001ada:	8082                	ret
    first = 0;
    80001adc:	00007797          	auipc	a5,0x7
    80001ae0:	d807aa23          	sw	zero,-620(a5) # 80008870 <first.1683>
    fsinit(ROOTDEV);
    80001ae4:	4505                	li	a0,1
    80001ae6:	00002097          	auipc	ra,0x2
    80001aea:	a20080e7          	jalr	-1504(ra) # 80003506 <fsinit>
    80001aee:	bff9                	j	80001acc <forkret+0x24>

0000000080001af0 <allocpid>:
allocpid() {
    80001af0:	1101                	addi	sp,sp,-32
    80001af2:	ec06                	sd	ra,24(sp)
    80001af4:	e822                	sd	s0,16(sp)
    80001af6:	e426                	sd	s1,8(sp)
    80001af8:	e04a                	sd	s2,0(sp)
    80001afa:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001afc:	00010917          	auipc	s2,0x10
    80001b00:	e5490913          	addi	s2,s2,-428 # 80011950 <pid_lock>
    80001b04:	854a                	mv	a0,s2
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	15c080e7          	jalr	348(ra) # 80000c62 <acquire>
  pid = nextpid;
    80001b0e:	00007797          	auipc	a5,0x7
    80001b12:	d6678793          	addi	a5,a5,-666 # 80008874 <nextpid>
    80001b16:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b18:	0014871b          	addiw	a4,s1,1
    80001b1c:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b1e:	854a                	mv	a0,s2
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	1f6080e7          	jalr	502(ra) # 80000d16 <release>
}
    80001b28:	8526                	mv	a0,s1
    80001b2a:	60e2                	ld	ra,24(sp)
    80001b2c:	6442                	ld	s0,16(sp)
    80001b2e:	64a2                	ld	s1,8(sp)
    80001b30:	6902                	ld	s2,0(sp)
    80001b32:	6105                	addi	sp,sp,32
    80001b34:	8082                	ret

0000000080001b36 <proc_pagetable>:
{
    80001b36:	1101                	addi	sp,sp,-32
    80001b38:	ec06                	sd	ra,24(sp)
    80001b3a:	e822                	sd	s0,16(sp)
    80001b3c:	e426                	sd	s1,8(sp)
    80001b3e:	e04a                	sd	s2,0(sp)
    80001b40:	1000                	addi	s0,sp,32
    80001b42:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b44:	00000097          	auipc	ra,0x0
    80001b48:	8d2080e7          	jalr	-1838(ra) # 80001416 <uvmcreate>
    80001b4c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b4e:	c121                	beqz	a0,80001b8e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b50:	4729                	li	a4,10
    80001b52:	00005697          	auipc	a3,0x5
    80001b56:	4ae68693          	addi	a3,a3,1198 # 80007000 <_trampoline>
    80001b5a:	6605                	lui	a2,0x1
    80001b5c:	040005b7          	lui	a1,0x4000
    80001b60:	15fd                	addi	a1,a1,-1
    80001b62:	05b2                	slli	a1,a1,0xc
    80001b64:	fffff097          	auipc	ra,0xfffff
    80001b68:	654080e7          	jalr	1620(ra) # 800011b8 <mappages>
    80001b6c:	02054863          	bltz	a0,80001b9c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b70:	4719                	li	a4,6
    80001b72:	05893683          	ld	a3,88(s2)
    80001b76:	6605                	lui	a2,0x1
    80001b78:	020005b7          	lui	a1,0x2000
    80001b7c:	15fd                	addi	a1,a1,-1
    80001b7e:	05b6                	slli	a1,a1,0xd
    80001b80:	8526                	mv	a0,s1
    80001b82:	fffff097          	auipc	ra,0xfffff
    80001b86:	636080e7          	jalr	1590(ra) # 800011b8 <mappages>
    80001b8a:	02054163          	bltz	a0,80001bac <proc_pagetable+0x76>
}
    80001b8e:	8526                	mv	a0,s1
    80001b90:	60e2                	ld	ra,24(sp)
    80001b92:	6442                	ld	s0,16(sp)
    80001b94:	64a2                	ld	s1,8(sp)
    80001b96:	6902                	ld	s2,0(sp)
    80001b98:	6105                	addi	sp,sp,32
    80001b9a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b9c:	4581                	li	a1,0
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	a70080e7          	jalr	-1424(ra) # 80001610 <uvmfree>
    return 0;
    80001ba8:	4481                	li	s1,0
    80001baa:	b7d5                	j	80001b8e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bac:	4681                	li	a3,0
    80001bae:	4605                	li	a2,1
    80001bb0:	040005b7          	lui	a1,0x4000
    80001bb4:	15fd                	addi	a1,a1,-1
    80001bb6:	05b2                	slli	a1,a1,0xc
    80001bb8:	8526                	mv	a0,s1
    80001bba:	fffff097          	auipc	ra,0xfffff
    80001bbe:	796080e7          	jalr	1942(ra) # 80001350 <uvmunmap>
    uvmfree(pagetable, 0);
    80001bc2:	4581                	li	a1,0
    80001bc4:	8526                	mv	a0,s1
    80001bc6:	00000097          	auipc	ra,0x0
    80001bca:	a4a080e7          	jalr	-1462(ra) # 80001610 <uvmfree>
    return 0;
    80001bce:	4481                	li	s1,0
    80001bd0:	bf7d                	j	80001b8e <proc_pagetable+0x58>

0000000080001bd2 <proc_freepagetable>:
{
    80001bd2:	1101                	addi	sp,sp,-32
    80001bd4:	ec06                	sd	ra,24(sp)
    80001bd6:	e822                	sd	s0,16(sp)
    80001bd8:	e426                	sd	s1,8(sp)
    80001bda:	e04a                	sd	s2,0(sp)
    80001bdc:	1000                	addi	s0,sp,32
    80001bde:	84aa                	mv	s1,a0
    80001be0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001be2:	4681                	li	a3,0
    80001be4:	4605                	li	a2,1
    80001be6:	040005b7          	lui	a1,0x4000
    80001bea:	15fd                	addi	a1,a1,-1
    80001bec:	05b2                	slli	a1,a1,0xc
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	762080e7          	jalr	1890(ra) # 80001350 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bf6:	4681                	li	a3,0
    80001bf8:	4605                	li	a2,1
    80001bfa:	020005b7          	lui	a1,0x2000
    80001bfe:	15fd                	addi	a1,a1,-1
    80001c00:	05b6                	slli	a1,a1,0xd
    80001c02:	8526                	mv	a0,s1
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	74c080e7          	jalr	1868(ra) # 80001350 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c0c:	85ca                	mv	a1,s2
    80001c0e:	8526                	mv	a0,s1
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	a00080e7          	jalr	-1536(ra) # 80001610 <uvmfree>
}
    80001c18:	60e2                	ld	ra,24(sp)
    80001c1a:	6442                	ld	s0,16(sp)
    80001c1c:	64a2                	ld	s1,8(sp)
    80001c1e:	6902                	ld	s2,0(sp)
    80001c20:	6105                	addi	sp,sp,32
    80001c22:	8082                	ret

0000000080001c24 <freeproc>:
{
    80001c24:	1101                	addi	sp,sp,-32
    80001c26:	ec06                	sd	ra,24(sp)
    80001c28:	e822                	sd	s0,16(sp)
    80001c2a:	e426                	sd	s1,8(sp)
    80001c2c:	1000                	addi	s0,sp,32
    80001c2e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c30:	6d28                	ld	a0,88(a0)
    80001c32:	c509                	beqz	a0,80001c3c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	e3e080e7          	jalr	-450(ra) # 80000a72 <kfree>
  p->trapframe = 0;
    80001c3c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c40:	68a8                	ld	a0,80(s1)
    80001c42:	c511                	beqz	a0,80001c4e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c44:	64ac                	ld	a1,72(s1)
    80001c46:	00000097          	auipc	ra,0x0
    80001c4a:	f8c080e7          	jalr	-116(ra) # 80001bd2 <proc_freepagetable>
  p->pagetable = 0;
    80001c4e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c52:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c56:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c5a:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c5e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c62:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c66:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c6a:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c6e:	0004ac23          	sw	zero,24(s1)
}
    80001c72:	60e2                	ld	ra,24(sp)
    80001c74:	6442                	ld	s0,16(sp)
    80001c76:	64a2                	ld	s1,8(sp)
    80001c78:	6105                	addi	sp,sp,32
    80001c7a:	8082                	ret

0000000080001c7c <allocproc>:
{
    80001c7c:	1101                	addi	sp,sp,-32
    80001c7e:	ec06                	sd	ra,24(sp)
    80001c80:	e822                	sd	s0,16(sp)
    80001c82:	e426                	sd	s1,8(sp)
    80001c84:	e04a                	sd	s2,0(sp)
    80001c86:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c88:	00010497          	auipc	s1,0x10
    80001c8c:	0e048493          	addi	s1,s1,224 # 80011d68 <proc>
    80001c90:	00016917          	auipc	s2,0x16
    80001c94:	cd890913          	addi	s2,s2,-808 # 80017968 <tickslock>
    acquire(&p->lock);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	fc8080e7          	jalr	-56(ra) # 80000c62 <acquire>
    if(p->state == UNUSED) {
    80001ca2:	4c9c                	lw	a5,24(s1)
    80001ca4:	cf81                	beqz	a5,80001cbc <allocproc+0x40>
      release(&p->lock);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	fffff097          	auipc	ra,0xfffff
    80001cac:	06e080e7          	jalr	110(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cb0:	17048493          	addi	s1,s1,368
    80001cb4:	ff2492e3          	bne	s1,s2,80001c98 <allocproc+0x1c>
  return 0;
    80001cb8:	4481                	li	s1,0
    80001cba:	a889                	j	80001d0c <allocproc+0x90>
  p->pid = allocpid();
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	e34080e7          	jalr	-460(ra) # 80001af0 <allocpid>
    80001cc4:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	eac080e7          	jalr	-340(ra) # 80000b72 <kalloc>
    80001cce:	892a                	mv	s2,a0
    80001cd0:	eca8                	sd	a0,88(s1)
    80001cd2:	c521                	beqz	a0,80001d1a <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cd4:	8526                	mv	a0,s1
    80001cd6:	00000097          	auipc	ra,0x0
    80001cda:	e60080e7          	jalr	-416(ra) # 80001b36 <proc_pagetable>
    80001cde:	892a                	mv	s2,a0
    80001ce0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ce2:	c139                	beqz	a0,80001d28 <allocproc+0xac>
  memset(&p->context, 0, sizeof(p->context));
    80001ce4:	07000613          	li	a2,112
    80001ce8:	4581                	li	a1,0
    80001cea:	06048513          	addi	a0,s1,96
    80001cee:	fffff097          	auipc	ra,0xfffff
    80001cf2:	070080e7          	jalr	112(ra) # 80000d5e <memset>
  p->context.ra = (uint64)forkret;
    80001cf6:	00000797          	auipc	a5,0x0
    80001cfa:	db278793          	addi	a5,a5,-590 # 80001aa8 <forkret>
    80001cfe:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d00:	60bc                	ld	a5,64(s1)
    80001d02:	6705                	lui	a4,0x1
    80001d04:	97ba                	add	a5,a5,a4
    80001d06:	f4bc                	sd	a5,104(s1)
  p->tracemask = 0;
    80001d08:	1604b423          	sd	zero,360(s1)
}
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	60e2                	ld	ra,24(sp)
    80001d10:	6442                	ld	s0,16(sp)
    80001d12:	64a2                	ld	s1,8(sp)
    80001d14:	6902                	ld	s2,0(sp)
    80001d16:	6105                	addi	sp,sp,32
    80001d18:	8082                	ret
    release(&p->lock);
    80001d1a:	8526                	mv	a0,s1
    80001d1c:	fffff097          	auipc	ra,0xfffff
    80001d20:	ffa080e7          	jalr	-6(ra) # 80000d16 <release>
    return 0;
    80001d24:	84ca                	mv	s1,s2
    80001d26:	b7dd                	j	80001d0c <allocproc+0x90>
    freeproc(p);
    80001d28:	8526                	mv	a0,s1
    80001d2a:	00000097          	auipc	ra,0x0
    80001d2e:	efa080e7          	jalr	-262(ra) # 80001c24 <freeproc>
    release(&p->lock);
    80001d32:	8526                	mv	a0,s1
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	fe2080e7          	jalr	-30(ra) # 80000d16 <release>
    return 0;
    80001d3c:	84ca                	mv	s1,s2
    80001d3e:	b7f9                	j	80001d0c <allocproc+0x90>

0000000080001d40 <userinit>:
{
    80001d40:	1101                	addi	sp,sp,-32
    80001d42:	ec06                	sd	ra,24(sp)
    80001d44:	e822                	sd	s0,16(sp)
    80001d46:	e426                	sd	s1,8(sp)
    80001d48:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d4a:	00000097          	auipc	ra,0x0
    80001d4e:	f32080e7          	jalr	-206(ra) # 80001c7c <allocproc>
    80001d52:	84aa                	mv	s1,a0
  initproc = p;
    80001d54:	00007797          	auipc	a5,0x7
    80001d58:	2ca7b223          	sd	a0,708(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d5c:	03400613          	li	a2,52
    80001d60:	00007597          	auipc	a1,0x7
    80001d64:	b2058593          	addi	a1,a1,-1248 # 80008880 <initcode>
    80001d68:	6928                	ld	a0,80(a0)
    80001d6a:	fffff097          	auipc	ra,0xfffff
    80001d6e:	6da080e7          	jalr	1754(ra) # 80001444 <uvminit>
  p->sz = PGSIZE;
    80001d72:	6785                	lui	a5,0x1
    80001d74:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d76:	6cb8                	ld	a4,88(s1)
    80001d78:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d7c:	6cb8                	ld	a4,88(s1)
    80001d7e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d80:	4641                	li	a2,16
    80001d82:	00006597          	auipc	a1,0x6
    80001d86:	48e58593          	addi	a1,a1,1166 # 80008210 <states.1723+0x48>
    80001d8a:	15848513          	addi	a0,s1,344
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	148080e7          	jalr	328(ra) # 80000ed6 <safestrcpy>
  p->cwd = namei("/");
    80001d96:	00006517          	auipc	a0,0x6
    80001d9a:	48a50513          	addi	a0,a0,1162 # 80008220 <states.1723+0x58>
    80001d9e:	00002097          	auipc	ra,0x2
    80001da2:	19c080e7          	jalr	412(ra) # 80003f3a <namei>
    80001da6:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001daa:	4789                	li	a5,2
    80001dac:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001dae:	8526                	mv	a0,s1
    80001db0:	fffff097          	auipc	ra,0xfffff
    80001db4:	f66080e7          	jalr	-154(ra) # 80000d16 <release>
}
    80001db8:	60e2                	ld	ra,24(sp)
    80001dba:	6442                	ld	s0,16(sp)
    80001dbc:	64a2                	ld	s1,8(sp)
    80001dbe:	6105                	addi	sp,sp,32
    80001dc0:	8082                	ret

0000000080001dc2 <growproc>:
{
    80001dc2:	1101                	addi	sp,sp,-32
    80001dc4:	ec06                	sd	ra,24(sp)
    80001dc6:	e822                	sd	s0,16(sp)
    80001dc8:	e426                	sd	s1,8(sp)
    80001dca:	e04a                	sd	s2,0(sp)
    80001dcc:	1000                	addi	s0,sp,32
    80001dce:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dd0:	00000097          	auipc	ra,0x0
    80001dd4:	ca0080e7          	jalr	-864(ra) # 80001a70 <myproc>
    80001dd8:	892a                	mv	s2,a0
  sz = p->sz;
    80001dda:	652c                	ld	a1,72(a0)
    80001ddc:	0005851b          	sext.w	a0,a1
  if(n > 0){
    80001de0:	00904f63          	bgtz	s1,80001dfe <growproc+0x3c>
  } else if(n < 0){
    80001de4:	0204cd63          	bltz	s1,80001e1e <growproc+0x5c>
  p->sz = sz;
    80001de8:	1502                	slli	a0,a0,0x20
    80001dea:	9101                	srli	a0,a0,0x20
    80001dec:	04a93423          	sd	a0,72(s2)
  return 0;
    80001df0:	4501                	li	a0,0
}
    80001df2:	60e2                	ld	ra,24(sp)
    80001df4:	6442                	ld	s0,16(sp)
    80001df6:	64a2                	ld	s1,8(sp)
    80001df8:	6902                	ld	s2,0(sp)
    80001dfa:	6105                	addi	sp,sp,32
    80001dfc:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dfe:	00a4863b          	addw	a2,s1,a0
    80001e02:	1602                	slli	a2,a2,0x20
    80001e04:	9201                	srli	a2,a2,0x20
    80001e06:	1582                	slli	a1,a1,0x20
    80001e08:	9181                	srli	a1,a1,0x20
    80001e0a:	05093503          	ld	a0,80(s2)
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	6ee080e7          	jalr	1774(ra) # 800014fc <uvmalloc>
    80001e16:	2501                	sext.w	a0,a0
    80001e18:	f961                	bnez	a0,80001de8 <growproc+0x26>
      return -1;
    80001e1a:	557d                	li	a0,-1
    80001e1c:	bfd9                	j	80001df2 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e1e:	00a4863b          	addw	a2,s1,a0
    80001e22:	1602                	slli	a2,a2,0x20
    80001e24:	9201                	srli	a2,a2,0x20
    80001e26:	1582                	slli	a1,a1,0x20
    80001e28:	9181                	srli	a1,a1,0x20
    80001e2a:	05093503          	ld	a0,80(s2)
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	688080e7          	jalr	1672(ra) # 800014b6 <uvmdealloc>
    80001e36:	2501                	sext.w	a0,a0
    80001e38:	bf45                	j	80001de8 <growproc+0x26>

0000000080001e3a <fork>:
{
    80001e3a:	7179                	addi	sp,sp,-48
    80001e3c:	f406                	sd	ra,40(sp)
    80001e3e:	f022                	sd	s0,32(sp)
    80001e40:	ec26                	sd	s1,24(sp)
    80001e42:	e84a                	sd	s2,16(sp)
    80001e44:	e44e                	sd	s3,8(sp)
    80001e46:	e052                	sd	s4,0(sp)
    80001e48:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e4a:	00000097          	auipc	ra,0x0
    80001e4e:	c26080e7          	jalr	-986(ra) # 80001a70 <myproc>
    80001e52:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	e28080e7          	jalr	-472(ra) # 80001c7c <allocproc>
    80001e5c:	c575                	beqz	a0,80001f48 <fork+0x10e>
    80001e5e:	89aa                	mv	s3,a0
  np->tracemask = p->tracemask;
    80001e60:	16893783          	ld	a5,360(s2)
    80001e64:	16f53423          	sd	a5,360(a0)
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e68:	04893603          	ld	a2,72(s2)
    80001e6c:	692c                	ld	a1,80(a0)
    80001e6e:	05093503          	ld	a0,80(s2)
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	7d6080e7          	jalr	2006(ra) # 80001648 <uvmcopy>
    80001e7a:	04054863          	bltz	a0,80001eca <fork+0x90>
  np->sz = p->sz;
    80001e7e:	04893783          	ld	a5,72(s2)
    80001e82:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e86:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e8a:	05893683          	ld	a3,88(s2)
    80001e8e:	87b6                	mv	a5,a3
    80001e90:	0589b703          	ld	a4,88(s3)
    80001e94:	12068693          	addi	a3,a3,288
    80001e98:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e9c:	6788                	ld	a0,8(a5)
    80001e9e:	6b8c                	ld	a1,16(a5)
    80001ea0:	6f90                	ld	a2,24(a5)
    80001ea2:	01073023          	sd	a6,0(a4)
    80001ea6:	e708                	sd	a0,8(a4)
    80001ea8:	eb0c                	sd	a1,16(a4)
    80001eaa:	ef10                	sd	a2,24(a4)
    80001eac:	02078793          	addi	a5,a5,32
    80001eb0:	02070713          	addi	a4,a4,32
    80001eb4:	fed792e3          	bne	a5,a3,80001e98 <fork+0x5e>
  np->trapframe->a0 = 0;
    80001eb8:	0589b783          	ld	a5,88(s3)
    80001ebc:	0607b823          	sd	zero,112(a5)
    80001ec0:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ec4:	15000a13          	li	s4,336
    80001ec8:	a03d                	j	80001ef6 <fork+0xbc>
    freeproc(np);
    80001eca:	854e                	mv	a0,s3
    80001ecc:	00000097          	auipc	ra,0x0
    80001ed0:	d58080e7          	jalr	-680(ra) # 80001c24 <freeproc>
    release(&np->lock);
    80001ed4:	854e                	mv	a0,s3
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	e40080e7          	jalr	-448(ra) # 80000d16 <release>
    return -1;
    80001ede:	54fd                	li	s1,-1
    80001ee0:	a899                	j	80001f36 <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ee2:	00002097          	auipc	ra,0x2
    80001ee6:	716080e7          	jalr	1814(ra) # 800045f8 <filedup>
    80001eea:	009987b3          	add	a5,s3,s1
    80001eee:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ef0:	04a1                	addi	s1,s1,8
    80001ef2:	01448763          	beq	s1,s4,80001f00 <fork+0xc6>
    if(p->ofile[i])
    80001ef6:	009907b3          	add	a5,s2,s1
    80001efa:	6388                	ld	a0,0(a5)
    80001efc:	f17d                	bnez	a0,80001ee2 <fork+0xa8>
    80001efe:	bfcd                	j	80001ef0 <fork+0xb6>
  np->cwd = idup(p->cwd);
    80001f00:	15093503          	ld	a0,336(s2)
    80001f04:	00002097          	auipc	ra,0x2
    80001f08:	83e080e7          	jalr	-1986(ra) # 80003742 <idup>
    80001f0c:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f10:	4641                	li	a2,16
    80001f12:	15890593          	addi	a1,s2,344
    80001f16:	15898513          	addi	a0,s3,344
    80001f1a:	fffff097          	auipc	ra,0xfffff
    80001f1e:	fbc080e7          	jalr	-68(ra) # 80000ed6 <safestrcpy>
  pid = np->pid;
    80001f22:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f26:	4789                	li	a5,2
    80001f28:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f2c:	854e                	mv	a0,s3
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	de8080e7          	jalr	-536(ra) # 80000d16 <release>
}
    80001f36:	8526                	mv	a0,s1
    80001f38:	70a2                	ld	ra,40(sp)
    80001f3a:	7402                	ld	s0,32(sp)
    80001f3c:	64e2                	ld	s1,24(sp)
    80001f3e:	6942                	ld	s2,16(sp)
    80001f40:	69a2                	ld	s3,8(sp)
    80001f42:	6a02                	ld	s4,0(sp)
    80001f44:	6145                	addi	sp,sp,48
    80001f46:	8082                	ret
    return -1;
    80001f48:	54fd                	li	s1,-1
    80001f4a:	b7f5                	j	80001f36 <fork+0xfc>

0000000080001f4c <reparent>:
{
    80001f4c:	7179                	addi	sp,sp,-48
    80001f4e:	f406                	sd	ra,40(sp)
    80001f50:	f022                	sd	s0,32(sp)
    80001f52:	ec26                	sd	s1,24(sp)
    80001f54:	e84a                	sd	s2,16(sp)
    80001f56:	e44e                	sd	s3,8(sp)
    80001f58:	e052                	sd	s4,0(sp)
    80001f5a:	1800                	addi	s0,sp,48
    80001f5c:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f5e:	00010497          	auipc	s1,0x10
    80001f62:	e0a48493          	addi	s1,s1,-502 # 80011d68 <proc>
      pp->parent = initproc;
    80001f66:	00007a17          	auipc	s4,0x7
    80001f6a:	0b2a0a13          	addi	s4,s4,178 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f6e:	00016917          	auipc	s2,0x16
    80001f72:	9fa90913          	addi	s2,s2,-1542 # 80017968 <tickslock>
    80001f76:	a029                	j	80001f80 <reparent+0x34>
    80001f78:	17048493          	addi	s1,s1,368
    80001f7c:	03248363          	beq	s1,s2,80001fa2 <reparent+0x56>
    if(pp->parent == p){
    80001f80:	709c                	ld	a5,32(s1)
    80001f82:	ff379be3          	bne	a5,s3,80001f78 <reparent+0x2c>
      acquire(&pp->lock);
    80001f86:	8526                	mv	a0,s1
    80001f88:	fffff097          	auipc	ra,0xfffff
    80001f8c:	cda080e7          	jalr	-806(ra) # 80000c62 <acquire>
      pp->parent = initproc;
    80001f90:	000a3783          	ld	a5,0(s4)
    80001f94:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	d7e080e7          	jalr	-642(ra) # 80000d16 <release>
    80001fa0:	bfe1                	j	80001f78 <reparent+0x2c>
}
    80001fa2:	70a2                	ld	ra,40(sp)
    80001fa4:	7402                	ld	s0,32(sp)
    80001fa6:	64e2                	ld	s1,24(sp)
    80001fa8:	6942                	ld	s2,16(sp)
    80001faa:	69a2                	ld	s3,8(sp)
    80001fac:	6a02                	ld	s4,0(sp)
    80001fae:	6145                	addi	sp,sp,48
    80001fb0:	8082                	ret

0000000080001fb2 <scheduler>:
{
    80001fb2:	715d                	addi	sp,sp,-80
    80001fb4:	e486                	sd	ra,72(sp)
    80001fb6:	e0a2                	sd	s0,64(sp)
    80001fb8:	fc26                	sd	s1,56(sp)
    80001fba:	f84a                	sd	s2,48(sp)
    80001fbc:	f44e                	sd	s3,40(sp)
    80001fbe:	f052                	sd	s4,32(sp)
    80001fc0:	ec56                	sd	s5,24(sp)
    80001fc2:	e85a                	sd	s6,16(sp)
    80001fc4:	e45e                	sd	s7,8(sp)
    80001fc6:	e062                	sd	s8,0(sp)
    80001fc8:	0880                	addi	s0,sp,80
    80001fca:	8792                	mv	a5,tp
  int id = r_tp();
    80001fcc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fce:	00779b13          	slli	s6,a5,0x7
    80001fd2:	00010717          	auipc	a4,0x10
    80001fd6:	97e70713          	addi	a4,a4,-1666 # 80011950 <pid_lock>
    80001fda:	975a                	add	a4,a4,s6
    80001fdc:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001fe0:	00010717          	auipc	a4,0x10
    80001fe4:	99070713          	addi	a4,a4,-1648 # 80011970 <cpus+0x8>
    80001fe8:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fea:	4c0d                	li	s8,3
        c->proc = p;
    80001fec:	079e                	slli	a5,a5,0x7
    80001fee:	00010a17          	auipc	s4,0x10
    80001ff2:	962a0a13          	addi	s4,s4,-1694 # 80011950 <pid_lock>
    80001ff6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ff8:	00016997          	auipc	s3,0x16
    80001ffc:	97098993          	addi	s3,s3,-1680 # 80017968 <tickslock>
        found = 1;
    80002000:	4b85                	li	s7,1
    80002002:	a899                	j	80002058 <scheduler+0xa6>
        p->state = RUNNING;
    80002004:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80002008:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    8000200c:	06048593          	addi	a1,s1,96
    80002010:	855a                	mv	a0,s6
    80002012:	00000097          	auipc	ra,0x0
    80002016:	63e080e7          	jalr	1598(ra) # 80002650 <swtch>
        c->proc = 0;
    8000201a:	000a3c23          	sd	zero,24(s4)
        found = 1;
    8000201e:	8ade                	mv	s5,s7
      release(&p->lock);
    80002020:	8526                	mv	a0,s1
    80002022:	fffff097          	auipc	ra,0xfffff
    80002026:	cf4080e7          	jalr	-780(ra) # 80000d16 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000202a:	17048493          	addi	s1,s1,368
    8000202e:	01348b63          	beq	s1,s3,80002044 <scheduler+0x92>
      acquire(&p->lock);
    80002032:	8526                	mv	a0,s1
    80002034:	fffff097          	auipc	ra,0xfffff
    80002038:	c2e080e7          	jalr	-978(ra) # 80000c62 <acquire>
      if(p->state == RUNNABLE) {
    8000203c:	4c9c                	lw	a5,24(s1)
    8000203e:	ff2791e3          	bne	a5,s2,80002020 <scheduler+0x6e>
    80002042:	b7c9                	j	80002004 <scheduler+0x52>
    if(found == 0) {
    80002044:	000a9a63          	bnez	s5,80002058 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002048:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000204c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002050:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002054:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002058:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000205c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002060:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002064:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002066:	00010497          	auipc	s1,0x10
    8000206a:	d0248493          	addi	s1,s1,-766 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000206e:	4909                	li	s2,2
    80002070:	b7c9                	j	80002032 <scheduler+0x80>

0000000080002072 <sched>:
{
    80002072:	7179                	addi	sp,sp,-48
    80002074:	f406                	sd	ra,40(sp)
    80002076:	f022                	sd	s0,32(sp)
    80002078:	ec26                	sd	s1,24(sp)
    8000207a:	e84a                	sd	s2,16(sp)
    8000207c:	e44e                	sd	s3,8(sp)
    8000207e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002080:	00000097          	auipc	ra,0x0
    80002084:	9f0080e7          	jalr	-1552(ra) # 80001a70 <myproc>
    80002088:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	b5e080e7          	jalr	-1186(ra) # 80000be8 <holding>
    80002092:	cd25                	beqz	a0,8000210a <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002094:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002096:	2781                	sext.w	a5,a5
    80002098:	079e                	slli	a5,a5,0x7
    8000209a:	00010717          	auipc	a4,0x10
    8000209e:	8b670713          	addi	a4,a4,-1866 # 80011950 <pid_lock>
    800020a2:	97ba                	add	a5,a5,a4
    800020a4:	0907a703          	lw	a4,144(a5)
    800020a8:	4785                	li	a5,1
    800020aa:	06f71863          	bne	a4,a5,8000211a <sched+0xa8>
  if(p->state == RUNNING)
    800020ae:	01892703          	lw	a4,24(s2)
    800020b2:	478d                	li	a5,3
    800020b4:	06f70b63          	beq	a4,a5,8000212a <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020bc:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020be:	efb5                	bnez	a5,8000213a <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020c0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020c2:	00010497          	auipc	s1,0x10
    800020c6:	88e48493          	addi	s1,s1,-1906 # 80011950 <pid_lock>
    800020ca:	2781                	sext.w	a5,a5
    800020cc:	079e                	slli	a5,a5,0x7
    800020ce:	97a6                	add	a5,a5,s1
    800020d0:	0947a983          	lw	s3,148(a5)
    800020d4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020d6:	2781                	sext.w	a5,a5
    800020d8:	079e                	slli	a5,a5,0x7
    800020da:	00010597          	auipc	a1,0x10
    800020de:	89658593          	addi	a1,a1,-1898 # 80011970 <cpus+0x8>
    800020e2:	95be                	add	a1,a1,a5
    800020e4:	06090513          	addi	a0,s2,96
    800020e8:	00000097          	auipc	ra,0x0
    800020ec:	568080e7          	jalr	1384(ra) # 80002650 <swtch>
    800020f0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020f2:	2781                	sext.w	a5,a5
    800020f4:	079e                	slli	a5,a5,0x7
    800020f6:	97a6                	add	a5,a5,s1
    800020f8:	0937aa23          	sw	s3,148(a5)
}
    800020fc:	70a2                	ld	ra,40(sp)
    800020fe:	7402                	ld	s0,32(sp)
    80002100:	64e2                	ld	s1,24(sp)
    80002102:	6942                	ld	s2,16(sp)
    80002104:	69a2                	ld	s3,8(sp)
    80002106:	6145                	addi	sp,sp,48
    80002108:	8082                	ret
    panic("sched p->lock");
    8000210a:	00006517          	auipc	a0,0x6
    8000210e:	11e50513          	addi	a0,a0,286 # 80008228 <states.1723+0x60>
    80002112:	ffffe097          	auipc	ra,0xffffe
    80002116:	462080e7          	jalr	1122(ra) # 80000574 <panic>
    panic("sched locks");
    8000211a:	00006517          	auipc	a0,0x6
    8000211e:	11e50513          	addi	a0,a0,286 # 80008238 <states.1723+0x70>
    80002122:	ffffe097          	auipc	ra,0xffffe
    80002126:	452080e7          	jalr	1106(ra) # 80000574 <panic>
    panic("sched running");
    8000212a:	00006517          	auipc	a0,0x6
    8000212e:	11e50513          	addi	a0,a0,286 # 80008248 <states.1723+0x80>
    80002132:	ffffe097          	auipc	ra,0xffffe
    80002136:	442080e7          	jalr	1090(ra) # 80000574 <panic>
    panic("sched interruptible");
    8000213a:	00006517          	auipc	a0,0x6
    8000213e:	11e50513          	addi	a0,a0,286 # 80008258 <states.1723+0x90>
    80002142:	ffffe097          	auipc	ra,0xffffe
    80002146:	432080e7          	jalr	1074(ra) # 80000574 <panic>

000000008000214a <exit>:
{
    8000214a:	7179                	addi	sp,sp,-48
    8000214c:	f406                	sd	ra,40(sp)
    8000214e:	f022                	sd	s0,32(sp)
    80002150:	ec26                	sd	s1,24(sp)
    80002152:	e84a                	sd	s2,16(sp)
    80002154:	e44e                	sd	s3,8(sp)
    80002156:	e052                	sd	s4,0(sp)
    80002158:	1800                	addi	s0,sp,48
    8000215a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000215c:	00000097          	auipc	ra,0x0
    80002160:	914080e7          	jalr	-1772(ra) # 80001a70 <myproc>
    80002164:	89aa                	mv	s3,a0
  if(p == initproc)
    80002166:	00007797          	auipc	a5,0x7
    8000216a:	eb278793          	addi	a5,a5,-334 # 80009018 <initproc>
    8000216e:	639c                	ld	a5,0(a5)
    80002170:	0d050493          	addi	s1,a0,208
    80002174:	15050913          	addi	s2,a0,336
    80002178:	02a79363          	bne	a5,a0,8000219e <exit+0x54>
    panic("init exiting");
    8000217c:	00006517          	auipc	a0,0x6
    80002180:	0f450513          	addi	a0,a0,244 # 80008270 <states.1723+0xa8>
    80002184:	ffffe097          	auipc	ra,0xffffe
    80002188:	3f0080e7          	jalr	1008(ra) # 80000574 <panic>
      fileclose(f);
    8000218c:	00002097          	auipc	ra,0x2
    80002190:	4be080e7          	jalr	1214(ra) # 8000464a <fileclose>
      p->ofile[fd] = 0;
    80002194:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002198:	04a1                	addi	s1,s1,8
    8000219a:	01248563          	beq	s1,s2,800021a4 <exit+0x5a>
    if(p->ofile[fd]){
    8000219e:	6088                	ld	a0,0(s1)
    800021a0:	f575                	bnez	a0,8000218c <exit+0x42>
    800021a2:	bfdd                	j	80002198 <exit+0x4e>
  begin_op();
    800021a4:	00002097          	auipc	ra,0x2
    800021a8:	fa4080e7          	jalr	-92(ra) # 80004148 <begin_op>
  iput(p->cwd);
    800021ac:	1509b503          	ld	a0,336(s3)
    800021b0:	00001097          	auipc	ra,0x1
    800021b4:	78c080e7          	jalr	1932(ra) # 8000393c <iput>
  end_op();
    800021b8:	00002097          	auipc	ra,0x2
    800021bc:	010080e7          	jalr	16(ra) # 800041c8 <end_op>
  p->cwd = 0;
    800021c0:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800021c4:	00007497          	auipc	s1,0x7
    800021c8:	e5448493          	addi	s1,s1,-428 # 80009018 <initproc>
    800021cc:	6088                	ld	a0,0(s1)
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a94080e7          	jalr	-1388(ra) # 80000c62 <acquire>
  wakeup1(initproc);
    800021d6:	6088                	ld	a0,0(s1)
    800021d8:	fffff097          	auipc	ra,0xfffff
    800021dc:	758080e7          	jalr	1880(ra) # 80001930 <wakeup1>
  release(&initproc->lock);
    800021e0:	6088                	ld	a0,0(s1)
    800021e2:	fffff097          	auipc	ra,0xfffff
    800021e6:	b34080e7          	jalr	-1228(ra) # 80000d16 <release>
  acquire(&p->lock);
    800021ea:	854e                	mv	a0,s3
    800021ec:	fffff097          	auipc	ra,0xfffff
    800021f0:	a76080e7          	jalr	-1418(ra) # 80000c62 <acquire>
  struct proc *original_parent = p->parent;
    800021f4:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021f8:	854e                	mv	a0,s3
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	b1c080e7          	jalr	-1252(ra) # 80000d16 <release>
  acquire(&original_parent->lock);
    80002202:	8526                	mv	a0,s1
    80002204:	fffff097          	auipc	ra,0xfffff
    80002208:	a5e080e7          	jalr	-1442(ra) # 80000c62 <acquire>
  acquire(&p->lock);
    8000220c:	854e                	mv	a0,s3
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	a54080e7          	jalr	-1452(ra) # 80000c62 <acquire>
  reparent(p);
    80002216:	854e                	mv	a0,s3
    80002218:	00000097          	auipc	ra,0x0
    8000221c:	d34080e7          	jalr	-716(ra) # 80001f4c <reparent>
  wakeup1(original_parent);
    80002220:	8526                	mv	a0,s1
    80002222:	fffff097          	auipc	ra,0xfffff
    80002226:	70e080e7          	jalr	1806(ra) # 80001930 <wakeup1>
  p->xstate = status;
    8000222a:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000222e:	4791                	li	a5,4
    80002230:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002234:	8526                	mv	a0,s1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	ae0080e7          	jalr	-1312(ra) # 80000d16 <release>
  sched();
    8000223e:	00000097          	auipc	ra,0x0
    80002242:	e34080e7          	jalr	-460(ra) # 80002072 <sched>
  panic("zombie exit");
    80002246:	00006517          	auipc	a0,0x6
    8000224a:	03a50513          	addi	a0,a0,58 # 80008280 <states.1723+0xb8>
    8000224e:	ffffe097          	auipc	ra,0xffffe
    80002252:	326080e7          	jalr	806(ra) # 80000574 <panic>

0000000080002256 <yield>:
{
    80002256:	1101                	addi	sp,sp,-32
    80002258:	ec06                	sd	ra,24(sp)
    8000225a:	e822                	sd	s0,16(sp)
    8000225c:	e426                	sd	s1,8(sp)
    8000225e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002260:	00000097          	auipc	ra,0x0
    80002264:	810080e7          	jalr	-2032(ra) # 80001a70 <myproc>
    80002268:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	9f8080e7          	jalr	-1544(ra) # 80000c62 <acquire>
  p->state = RUNNABLE;
    80002272:	4789                	li	a5,2
    80002274:	cc9c                	sw	a5,24(s1)
  sched();
    80002276:	00000097          	auipc	ra,0x0
    8000227a:	dfc080e7          	jalr	-516(ra) # 80002072 <sched>
  release(&p->lock);
    8000227e:	8526                	mv	a0,s1
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	a96080e7          	jalr	-1386(ra) # 80000d16 <release>
}
    80002288:	60e2                	ld	ra,24(sp)
    8000228a:	6442                	ld	s0,16(sp)
    8000228c:	64a2                	ld	s1,8(sp)
    8000228e:	6105                	addi	sp,sp,32
    80002290:	8082                	ret

0000000080002292 <sleep>:
{
    80002292:	7179                	addi	sp,sp,-48
    80002294:	f406                	sd	ra,40(sp)
    80002296:	f022                	sd	s0,32(sp)
    80002298:	ec26                	sd	s1,24(sp)
    8000229a:	e84a                	sd	s2,16(sp)
    8000229c:	e44e                	sd	s3,8(sp)
    8000229e:	1800                	addi	s0,sp,48
    800022a0:	89aa                	mv	s3,a0
    800022a2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022a4:	fffff097          	auipc	ra,0xfffff
    800022a8:	7cc080e7          	jalr	1996(ra) # 80001a70 <myproc>
    800022ac:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022ae:	05250663          	beq	a0,s2,800022fa <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022b2:	fffff097          	auipc	ra,0xfffff
    800022b6:	9b0080e7          	jalr	-1616(ra) # 80000c62 <acquire>
    release(lk);
    800022ba:	854a                	mv	a0,s2
    800022bc:	fffff097          	auipc	ra,0xfffff
    800022c0:	a5a080e7          	jalr	-1446(ra) # 80000d16 <release>
  p->chan = chan;
    800022c4:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022c8:	4785                	li	a5,1
    800022ca:	cc9c                	sw	a5,24(s1)
  sched();
    800022cc:	00000097          	auipc	ra,0x0
    800022d0:	da6080e7          	jalr	-602(ra) # 80002072 <sched>
  p->chan = 0;
    800022d4:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022d8:	8526                	mv	a0,s1
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	a3c080e7          	jalr	-1476(ra) # 80000d16 <release>
    acquire(lk);
    800022e2:	854a                	mv	a0,s2
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	97e080e7          	jalr	-1666(ra) # 80000c62 <acquire>
}
    800022ec:	70a2                	ld	ra,40(sp)
    800022ee:	7402                	ld	s0,32(sp)
    800022f0:	64e2                	ld	s1,24(sp)
    800022f2:	6942                	ld	s2,16(sp)
    800022f4:	69a2                	ld	s3,8(sp)
    800022f6:	6145                	addi	sp,sp,48
    800022f8:	8082                	ret
  p->chan = chan;
    800022fa:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022fe:	4785                	li	a5,1
    80002300:	cd1c                	sw	a5,24(a0)
  sched();
    80002302:	00000097          	auipc	ra,0x0
    80002306:	d70080e7          	jalr	-656(ra) # 80002072 <sched>
  p->chan = 0;
    8000230a:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000230e:	bff9                	j	800022ec <sleep+0x5a>

0000000080002310 <wait>:
{
    80002310:	715d                	addi	sp,sp,-80
    80002312:	e486                	sd	ra,72(sp)
    80002314:	e0a2                	sd	s0,64(sp)
    80002316:	fc26                	sd	s1,56(sp)
    80002318:	f84a                	sd	s2,48(sp)
    8000231a:	f44e                	sd	s3,40(sp)
    8000231c:	f052                	sd	s4,32(sp)
    8000231e:	ec56                	sd	s5,24(sp)
    80002320:	e85a                	sd	s6,16(sp)
    80002322:	e45e                	sd	s7,8(sp)
    80002324:	e062                	sd	s8,0(sp)
    80002326:	0880                	addi	s0,sp,80
    80002328:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	746080e7          	jalr	1862(ra) # 80001a70 <myproc>
    80002332:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002334:	8c2a                	mv	s8,a0
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	92c080e7          	jalr	-1748(ra) # 80000c62 <acquire>
    havekids = 0;
    8000233e:	4b01                	li	s6,0
        if(np->state == ZOMBIE){
    80002340:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002342:	00015997          	auipc	s3,0x15
    80002346:	62698993          	addi	s3,s3,1574 # 80017968 <tickslock>
        havekids = 1;
    8000234a:	4a85                	li	s5,1
    havekids = 0;
    8000234c:	875a                	mv	a4,s6
    for(np = proc; np < &proc[NPROC]; np++){
    8000234e:	00010497          	auipc	s1,0x10
    80002352:	a1a48493          	addi	s1,s1,-1510 # 80011d68 <proc>
    80002356:	a08d                	j	800023b8 <wait+0xa8>
          pid = np->pid;
    80002358:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000235c:	000b8e63          	beqz	s7,80002378 <wait+0x68>
    80002360:	4691                	li	a3,4
    80002362:	03448613          	addi	a2,s1,52
    80002366:	85de                	mv	a1,s7
    80002368:	05093503          	ld	a0,80(s2)
    8000236c:	fffff097          	auipc	ra,0xfffff
    80002370:	3e0080e7          	jalr	992(ra) # 8000174c <copyout>
    80002374:	02054263          	bltz	a0,80002398 <wait+0x88>
          freeproc(np);
    80002378:	8526                	mv	a0,s1
    8000237a:	00000097          	auipc	ra,0x0
    8000237e:	8aa080e7          	jalr	-1878(ra) # 80001c24 <freeproc>
          release(&np->lock);
    80002382:	8526                	mv	a0,s1
    80002384:	fffff097          	auipc	ra,0xfffff
    80002388:	992080e7          	jalr	-1646(ra) # 80000d16 <release>
          release(&p->lock);
    8000238c:	854a                	mv	a0,s2
    8000238e:	fffff097          	auipc	ra,0xfffff
    80002392:	988080e7          	jalr	-1656(ra) # 80000d16 <release>
          return pid;
    80002396:	a8a9                	j	800023f0 <wait+0xe0>
            release(&np->lock);
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	97c080e7          	jalr	-1668(ra) # 80000d16 <release>
            release(&p->lock);
    800023a2:	854a                	mv	a0,s2
    800023a4:	fffff097          	auipc	ra,0xfffff
    800023a8:	972080e7          	jalr	-1678(ra) # 80000d16 <release>
            return -1;
    800023ac:	59fd                	li	s3,-1
    800023ae:	a089                	j	800023f0 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023b0:	17048493          	addi	s1,s1,368
    800023b4:	03348463          	beq	s1,s3,800023dc <wait+0xcc>
      if(np->parent == p){
    800023b8:	709c                	ld	a5,32(s1)
    800023ba:	ff279be3          	bne	a5,s2,800023b0 <wait+0xa0>
        acquire(&np->lock);
    800023be:	8526                	mv	a0,s1
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	8a2080e7          	jalr	-1886(ra) # 80000c62 <acquire>
        if(np->state == ZOMBIE){
    800023c8:	4c9c                	lw	a5,24(s1)
    800023ca:	f94787e3          	beq	a5,s4,80002358 <wait+0x48>
        release(&np->lock);
    800023ce:	8526                	mv	a0,s1
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	946080e7          	jalr	-1722(ra) # 80000d16 <release>
        havekids = 1;
    800023d8:	8756                	mv	a4,s5
    800023da:	bfd9                	j	800023b0 <wait+0xa0>
    if(!havekids || p->killed){
    800023dc:	c701                	beqz	a4,800023e4 <wait+0xd4>
    800023de:	03092783          	lw	a5,48(s2)
    800023e2:	c785                	beqz	a5,8000240a <wait+0xfa>
      release(&p->lock);
    800023e4:	854a                	mv	a0,s2
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	930080e7          	jalr	-1744(ra) # 80000d16 <release>
      return -1;
    800023ee:	59fd                	li	s3,-1
}
    800023f0:	854e                	mv	a0,s3
    800023f2:	60a6                	ld	ra,72(sp)
    800023f4:	6406                	ld	s0,64(sp)
    800023f6:	74e2                	ld	s1,56(sp)
    800023f8:	7942                	ld	s2,48(sp)
    800023fa:	79a2                	ld	s3,40(sp)
    800023fc:	7a02                	ld	s4,32(sp)
    800023fe:	6ae2                	ld	s5,24(sp)
    80002400:	6b42                	ld	s6,16(sp)
    80002402:	6ba2                	ld	s7,8(sp)
    80002404:	6c02                	ld	s8,0(sp)
    80002406:	6161                	addi	sp,sp,80
    80002408:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    8000240a:	85e2                	mv	a1,s8
    8000240c:	854a                	mv	a0,s2
    8000240e:	00000097          	auipc	ra,0x0
    80002412:	e84080e7          	jalr	-380(ra) # 80002292 <sleep>
    havekids = 0;
    80002416:	bf1d                	j	8000234c <wait+0x3c>

0000000080002418 <wakeup>:
{
    80002418:	7139                	addi	sp,sp,-64
    8000241a:	fc06                	sd	ra,56(sp)
    8000241c:	f822                	sd	s0,48(sp)
    8000241e:	f426                	sd	s1,40(sp)
    80002420:	f04a                	sd	s2,32(sp)
    80002422:	ec4e                	sd	s3,24(sp)
    80002424:	e852                	sd	s4,16(sp)
    80002426:	e456                	sd	s5,8(sp)
    80002428:	0080                	addi	s0,sp,64
    8000242a:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000242c:	00010497          	auipc	s1,0x10
    80002430:	93c48493          	addi	s1,s1,-1732 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002434:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002436:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002438:	00015917          	auipc	s2,0x15
    8000243c:	53090913          	addi	s2,s2,1328 # 80017968 <tickslock>
    80002440:	a821                	j	80002458 <wakeup+0x40>
      p->state = RUNNABLE;
    80002442:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	8ce080e7          	jalr	-1842(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002450:	17048493          	addi	s1,s1,368
    80002454:	01248e63          	beq	s1,s2,80002470 <wakeup+0x58>
    acquire(&p->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	808080e7          	jalr	-2040(ra) # 80000c62 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002462:	4c9c                	lw	a5,24(s1)
    80002464:	ff3791e3          	bne	a5,s3,80002446 <wakeup+0x2e>
    80002468:	749c                	ld	a5,40(s1)
    8000246a:	fd479ee3          	bne	a5,s4,80002446 <wakeup+0x2e>
    8000246e:	bfd1                	j	80002442 <wakeup+0x2a>
}
    80002470:	70e2                	ld	ra,56(sp)
    80002472:	7442                	ld	s0,48(sp)
    80002474:	74a2                	ld	s1,40(sp)
    80002476:	7902                	ld	s2,32(sp)
    80002478:	69e2                	ld	s3,24(sp)
    8000247a:	6a42                	ld	s4,16(sp)
    8000247c:	6aa2                	ld	s5,8(sp)
    8000247e:	6121                	addi	sp,sp,64
    80002480:	8082                	ret

0000000080002482 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002482:	7179                	addi	sp,sp,-48
    80002484:	f406                	sd	ra,40(sp)
    80002486:	f022                	sd	s0,32(sp)
    80002488:	ec26                	sd	s1,24(sp)
    8000248a:	e84a                	sd	s2,16(sp)
    8000248c:	e44e                	sd	s3,8(sp)
    8000248e:	1800                	addi	s0,sp,48
    80002490:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002492:	00010497          	auipc	s1,0x10
    80002496:	8d648493          	addi	s1,s1,-1834 # 80011d68 <proc>
    8000249a:	00015997          	auipc	s3,0x15
    8000249e:	4ce98993          	addi	s3,s3,1230 # 80017968 <tickslock>
    acquire(&p->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	7be080e7          	jalr	1982(ra) # 80000c62 <acquire>
    if(p->pid == pid){
    800024ac:	5c9c                	lw	a5,56(s1)
    800024ae:	01278d63          	beq	a5,s2,800024c8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	862080e7          	jalr	-1950(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024bc:	17048493          	addi	s1,s1,368
    800024c0:	ff3491e3          	bne	s1,s3,800024a2 <kill+0x20>
  }
  return -1;
    800024c4:	557d                	li	a0,-1
    800024c6:	a829                	j	800024e0 <kill+0x5e>
      p->killed = 1;
    800024c8:	4785                	li	a5,1
    800024ca:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024cc:	4c98                	lw	a4,24(s1)
    800024ce:	4785                	li	a5,1
    800024d0:	00f70f63          	beq	a4,a5,800024ee <kill+0x6c>
      release(&p->lock);
    800024d4:	8526                	mv	a0,s1
    800024d6:	fffff097          	auipc	ra,0xfffff
    800024da:	840080e7          	jalr	-1984(ra) # 80000d16 <release>
      return 0;
    800024de:	4501                	li	a0,0
}
    800024e0:	70a2                	ld	ra,40(sp)
    800024e2:	7402                	ld	s0,32(sp)
    800024e4:	64e2                	ld	s1,24(sp)
    800024e6:	6942                	ld	s2,16(sp)
    800024e8:	69a2                	ld	s3,8(sp)
    800024ea:	6145                	addi	sp,sp,48
    800024ec:	8082                	ret
        p->state = RUNNABLE;
    800024ee:	4789                	li	a5,2
    800024f0:	cc9c                	sw	a5,24(s1)
    800024f2:	b7cd                	j	800024d4 <kill+0x52>

00000000800024f4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024f4:	7179                	addi	sp,sp,-48
    800024f6:	f406                	sd	ra,40(sp)
    800024f8:	f022                	sd	s0,32(sp)
    800024fa:	ec26                	sd	s1,24(sp)
    800024fc:	e84a                	sd	s2,16(sp)
    800024fe:	e44e                	sd	s3,8(sp)
    80002500:	e052                	sd	s4,0(sp)
    80002502:	1800                	addi	s0,sp,48
    80002504:	84aa                	mv	s1,a0
    80002506:	892e                	mv	s2,a1
    80002508:	89b2                	mv	s3,a2
    8000250a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	564080e7          	jalr	1380(ra) # 80001a70 <myproc>
  if(user_dst){
    80002514:	c08d                	beqz	s1,80002536 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002516:	86d2                	mv	a3,s4
    80002518:	864e                	mv	a2,s3
    8000251a:	85ca                	mv	a1,s2
    8000251c:	6928                	ld	a0,80(a0)
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	22e080e7          	jalr	558(ra) # 8000174c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002526:	70a2                	ld	ra,40(sp)
    80002528:	7402                	ld	s0,32(sp)
    8000252a:	64e2                	ld	s1,24(sp)
    8000252c:	6942                	ld	s2,16(sp)
    8000252e:	69a2                	ld	s3,8(sp)
    80002530:	6a02                	ld	s4,0(sp)
    80002532:	6145                	addi	sp,sp,48
    80002534:	8082                	ret
    memmove((char *)dst, src, len);
    80002536:	000a061b          	sext.w	a2,s4
    8000253a:	85ce                	mv	a1,s3
    8000253c:	854a                	mv	a0,s2
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	88c080e7          	jalr	-1908(ra) # 80000dca <memmove>
    return 0;
    80002546:	8526                	mv	a0,s1
    80002548:	bff9                	j	80002526 <either_copyout+0x32>

000000008000254a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	e052                	sd	s4,0(sp)
    80002558:	1800                	addi	s0,sp,48
    8000255a:	892a                	mv	s2,a0
    8000255c:	84ae                	mv	s1,a1
    8000255e:	89b2                	mv	s3,a2
    80002560:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	50e080e7          	jalr	1294(ra) # 80001a70 <myproc>
  if(user_src){
    8000256a:	c08d                	beqz	s1,8000258c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000256c:	86d2                	mv	a3,s4
    8000256e:	864e                	mv	a2,s3
    80002570:	85ca                	mv	a1,s2
    80002572:	6928                	ld	a0,80(a0)
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	264080e7          	jalr	612(ra) # 800017d8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000257c:	70a2                	ld	ra,40(sp)
    8000257e:	7402                	ld	s0,32(sp)
    80002580:	64e2                	ld	s1,24(sp)
    80002582:	6942                	ld	s2,16(sp)
    80002584:	69a2                	ld	s3,8(sp)
    80002586:	6a02                	ld	s4,0(sp)
    80002588:	6145                	addi	sp,sp,48
    8000258a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000258c:	000a061b          	sext.w	a2,s4
    80002590:	85ce                	mv	a1,s3
    80002592:	854a                	mv	a0,s2
    80002594:	fffff097          	auipc	ra,0xfffff
    80002598:	836080e7          	jalr	-1994(ra) # 80000dca <memmove>
    return 0;
    8000259c:	8526                	mv	a0,s1
    8000259e:	bff9                	j	8000257c <either_copyin+0x32>

00000000800025a0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025a0:	715d                	addi	sp,sp,-80
    800025a2:	e486                	sd	ra,72(sp)
    800025a4:	e0a2                	sd	s0,64(sp)
    800025a6:	fc26                	sd	s1,56(sp)
    800025a8:	f84a                	sd	s2,48(sp)
    800025aa:	f44e                	sd	s3,40(sp)
    800025ac:	f052                	sd	s4,32(sp)
    800025ae:	ec56                	sd	s5,24(sp)
    800025b0:	e85a                	sd	s6,16(sp)
    800025b2:	e45e                	sd	s7,8(sp)
    800025b4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025b6:	00006517          	auipc	a0,0x6
    800025ba:	b1250513          	addi	a0,a0,-1262 # 800080c8 <digits+0xb0>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	000080e7          	jalr	ra # 800005be <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c6:	00010497          	auipc	s1,0x10
    800025ca:	8fa48493          	addi	s1,s1,-1798 # 80011ec0 <proc+0x158>
    800025ce:	00015917          	auipc	s2,0x15
    800025d2:	4f290913          	addi	s2,s2,1266 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d6:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025d8:	00006997          	auipc	s3,0x6
    800025dc:	cb898993          	addi	s3,s3,-840 # 80008290 <states.1723+0xc8>
    printf("%d %s %s", p->pid, state, p->name);
    800025e0:	00006a97          	auipc	s5,0x6
    800025e4:	cb8a8a93          	addi	s5,s5,-840 # 80008298 <states.1723+0xd0>
    printf("\n");
    800025e8:	00006a17          	auipc	s4,0x6
    800025ec:	ae0a0a13          	addi	s4,s4,-1312 # 800080c8 <digits+0xb0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f0:	00006b97          	auipc	s7,0x6
    800025f4:	bd8b8b93          	addi	s7,s7,-1064 # 800081c8 <states.1723>
    800025f8:	a015                	j	8000261c <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    800025fa:	86ba                	mv	a3,a4
    800025fc:	ee072583          	lw	a1,-288(a4)
    80002600:	8556                	mv	a0,s5
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	fbc080e7          	jalr	-68(ra) # 800005be <printf>
    printf("\n");
    8000260a:	8552                	mv	a0,s4
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	fb2080e7          	jalr	-78(ra) # 800005be <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002614:	17048493          	addi	s1,s1,368
    80002618:	03248163          	beq	s1,s2,8000263a <procdump+0x9a>
    if(p->state == UNUSED)
    8000261c:	8726                	mv	a4,s1
    8000261e:	ec04a783          	lw	a5,-320(s1)
    80002622:	dbed                	beqz	a5,80002614 <procdump+0x74>
      state = "???";
    80002624:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002626:	fcfb6ae3          	bltu	s6,a5,800025fa <procdump+0x5a>
    8000262a:	1782                	slli	a5,a5,0x20
    8000262c:	9381                	srli	a5,a5,0x20
    8000262e:	078e                	slli	a5,a5,0x3
    80002630:	97de                	add	a5,a5,s7
    80002632:	6390                	ld	a2,0(a5)
    80002634:	f279                	bnez	a2,800025fa <procdump+0x5a>
      state = "???";
    80002636:	864e                	mv	a2,s3
    80002638:	b7c9                	j	800025fa <procdump+0x5a>
  }
}
    8000263a:	60a6                	ld	ra,72(sp)
    8000263c:	6406                	ld	s0,64(sp)
    8000263e:	74e2                	ld	s1,56(sp)
    80002640:	7942                	ld	s2,48(sp)
    80002642:	79a2                	ld	s3,40(sp)
    80002644:	7a02                	ld	s4,32(sp)
    80002646:	6ae2                	ld	s5,24(sp)
    80002648:	6b42                	ld	s6,16(sp)
    8000264a:	6ba2                	ld	s7,8(sp)
    8000264c:	6161                	addi	sp,sp,80
    8000264e:	8082                	ret

0000000080002650 <swtch>:
    80002650:	00153023          	sd	ra,0(a0)
    80002654:	00253423          	sd	sp,8(a0)
    80002658:	e900                	sd	s0,16(a0)
    8000265a:	ed04                	sd	s1,24(a0)
    8000265c:	03253023          	sd	s2,32(a0)
    80002660:	03353423          	sd	s3,40(a0)
    80002664:	03453823          	sd	s4,48(a0)
    80002668:	03553c23          	sd	s5,56(a0)
    8000266c:	05653023          	sd	s6,64(a0)
    80002670:	05753423          	sd	s7,72(a0)
    80002674:	05853823          	sd	s8,80(a0)
    80002678:	05953c23          	sd	s9,88(a0)
    8000267c:	07a53023          	sd	s10,96(a0)
    80002680:	07b53423          	sd	s11,104(a0)
    80002684:	0005b083          	ld	ra,0(a1)
    80002688:	0085b103          	ld	sp,8(a1)
    8000268c:	6980                	ld	s0,16(a1)
    8000268e:	6d84                	ld	s1,24(a1)
    80002690:	0205b903          	ld	s2,32(a1)
    80002694:	0285b983          	ld	s3,40(a1)
    80002698:	0305ba03          	ld	s4,48(a1)
    8000269c:	0385ba83          	ld	s5,56(a1)
    800026a0:	0405bb03          	ld	s6,64(a1)
    800026a4:	0485bb83          	ld	s7,72(a1)
    800026a8:	0505bc03          	ld	s8,80(a1)
    800026ac:	0585bc83          	ld	s9,88(a1)
    800026b0:	0605bd03          	ld	s10,96(a1)
    800026b4:	0685bd83          	ld	s11,104(a1)
    800026b8:	8082                	ret

00000000800026ba <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026ba:	1141                	addi	sp,sp,-16
    800026bc:	e406                	sd	ra,8(sp)
    800026be:	e022                	sd	s0,0(sp)
    800026c0:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026c2:	00006597          	auipc	a1,0x6
    800026c6:	c0e58593          	addi	a1,a1,-1010 # 800082d0 <states.1723+0x108>
    800026ca:	00015517          	auipc	a0,0x15
    800026ce:	29e50513          	addi	a0,a0,670 # 80017968 <tickslock>
    800026d2:	ffffe097          	auipc	ra,0xffffe
    800026d6:	500080e7          	jalr	1280(ra) # 80000bd2 <initlock>
}
    800026da:	60a2                	ld	ra,8(sp)
    800026dc:	6402                	ld	s0,0(sp)
    800026de:	0141                	addi	sp,sp,16
    800026e0:	8082                	ret

00000000800026e2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026e2:	1141                	addi	sp,sp,-16
    800026e4:	e422                	sd	s0,8(sp)
    800026e6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e8:	00003797          	auipc	a5,0x3
    800026ec:	61878793          	addi	a5,a5,1560 # 80005d00 <kernelvec>
    800026f0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026f4:	6422                	ld	s0,8(sp)
    800026f6:	0141                	addi	sp,sp,16
    800026f8:	8082                	ret

00000000800026fa <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026fa:	1141                	addi	sp,sp,-16
    800026fc:	e406                	sd	ra,8(sp)
    800026fe:	e022                	sd	s0,0(sp)
    80002700:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002702:	fffff097          	auipc	ra,0xfffff
    80002706:	36e080e7          	jalr	878(ra) # 80001a70 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000270a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000270e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002710:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002714:	00005617          	auipc	a2,0x5
    80002718:	8ec60613          	addi	a2,a2,-1812 # 80007000 <_trampoline>
    8000271c:	00005697          	auipc	a3,0x5
    80002720:	8e468693          	addi	a3,a3,-1820 # 80007000 <_trampoline>
    80002724:	8e91                	sub	a3,a3,a2
    80002726:	040007b7          	lui	a5,0x4000
    8000272a:	17fd                	addi	a5,a5,-1
    8000272c:	07b2                	slli	a5,a5,0xc
    8000272e:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002730:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002734:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002736:	180026f3          	csrr	a3,satp
    8000273a:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000273c:	6d38                	ld	a4,88(a0)
    8000273e:	6134                	ld	a3,64(a0)
    80002740:	6585                	lui	a1,0x1
    80002742:	96ae                	add	a3,a3,a1
    80002744:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002746:	6d38                	ld	a4,88(a0)
    80002748:	00000697          	auipc	a3,0x0
    8000274c:	13868693          	addi	a3,a3,312 # 80002880 <usertrap>
    80002750:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002752:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002754:	8692                	mv	a3,tp
    80002756:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002758:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000275c:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002760:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002764:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002768:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000276a:	6f18                	ld	a4,24(a4)
    8000276c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002770:	692c                	ld	a1,80(a0)
    80002772:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002774:	00005717          	auipc	a4,0x5
    80002778:	91c70713          	addi	a4,a4,-1764 # 80007090 <userret>
    8000277c:	8f11                	sub	a4,a4,a2
    8000277e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002780:	577d                	li	a4,-1
    80002782:	177e                	slli	a4,a4,0x3f
    80002784:	8dd9                	or	a1,a1,a4
    80002786:	02000537          	lui	a0,0x2000
    8000278a:	157d                	addi	a0,a0,-1
    8000278c:	0536                	slli	a0,a0,0xd
    8000278e:	9782                	jalr	a5
}
    80002790:	60a2                	ld	ra,8(sp)
    80002792:	6402                	ld	s0,0(sp)
    80002794:	0141                	addi	sp,sp,16
    80002796:	8082                	ret

0000000080002798 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002798:	1101                	addi	sp,sp,-32
    8000279a:	ec06                	sd	ra,24(sp)
    8000279c:	e822                	sd	s0,16(sp)
    8000279e:	e426                	sd	s1,8(sp)
    800027a0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a2:	00015497          	auipc	s1,0x15
    800027a6:	1c648493          	addi	s1,s1,454 # 80017968 <tickslock>
    800027aa:	8526                	mv	a0,s1
    800027ac:	ffffe097          	auipc	ra,0xffffe
    800027b0:	4b6080e7          	jalr	1206(ra) # 80000c62 <acquire>
  ticks++;
    800027b4:	00007517          	auipc	a0,0x7
    800027b8:	86c50513          	addi	a0,a0,-1940 # 80009020 <ticks>
    800027bc:	411c                	lw	a5,0(a0)
    800027be:	2785                	addiw	a5,a5,1
    800027c0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c2:	00000097          	auipc	ra,0x0
    800027c6:	c56080e7          	jalr	-938(ra) # 80002418 <wakeup>
  release(&tickslock);
    800027ca:	8526                	mv	a0,s1
    800027cc:	ffffe097          	auipc	ra,0xffffe
    800027d0:	54a080e7          	jalr	1354(ra) # 80000d16 <release>
}
    800027d4:	60e2                	ld	ra,24(sp)
    800027d6:	6442                	ld	s0,16(sp)
    800027d8:	64a2                	ld	s1,8(sp)
    800027da:	6105                	addi	sp,sp,32
    800027dc:	8082                	ret

00000000800027de <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027de:	1101                	addi	sp,sp,-32
    800027e0:	ec06                	sd	ra,24(sp)
    800027e2:	e822                	sd	s0,16(sp)
    800027e4:	e426                	sd	s1,8(sp)
    800027e6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027ec:	00074d63          	bltz	a4,80002806 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027f0:	57fd                	li	a5,-1
    800027f2:	17fe                	slli	a5,a5,0x3f
    800027f4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027f6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027f8:	06f70363          	beq	a4,a5,8000285e <devintr+0x80>
  }
}
    800027fc:	60e2                	ld	ra,24(sp)
    800027fe:	6442                	ld	s0,16(sp)
    80002800:	64a2                	ld	s1,8(sp)
    80002802:	6105                	addi	sp,sp,32
    80002804:	8082                	ret
     (scause & 0xff) == 9){
    80002806:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000280a:	46a5                	li	a3,9
    8000280c:	fed792e3          	bne	a5,a3,800027f0 <devintr+0x12>
    int irq = plic_claim();
    80002810:	00003097          	auipc	ra,0x3
    80002814:	5f8080e7          	jalr	1528(ra) # 80005e08 <plic_claim>
    80002818:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000281a:	47a9                	li	a5,10
    8000281c:	02f50763          	beq	a0,a5,8000284a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002820:	4785                	li	a5,1
    80002822:	02f50963          	beq	a0,a5,80002854 <devintr+0x76>
    return 1;
    80002826:	4505                	li	a0,1
    } else if(irq){
    80002828:	d8f1                	beqz	s1,800027fc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000282a:	85a6                	mv	a1,s1
    8000282c:	00006517          	auipc	a0,0x6
    80002830:	aac50513          	addi	a0,a0,-1364 # 800082d8 <states.1723+0x110>
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	d8a080e7          	jalr	-630(ra) # 800005be <printf>
      plic_complete(irq);
    8000283c:	8526                	mv	a0,s1
    8000283e:	00003097          	auipc	ra,0x3
    80002842:	5ee080e7          	jalr	1518(ra) # 80005e2c <plic_complete>
    return 1;
    80002846:	4505                	li	a0,1
    80002848:	bf55                	j	800027fc <devintr+0x1e>
      uartintr();
    8000284a:	ffffe097          	auipc	ra,0xffffe
    8000284e:	1d8080e7          	jalr	472(ra) # 80000a22 <uartintr>
    80002852:	b7ed                	j	8000283c <devintr+0x5e>
      virtio_disk_intr();
    80002854:	00004097          	auipc	ra,0x4
    80002858:	a84080e7          	jalr	-1404(ra) # 800062d8 <virtio_disk_intr>
    8000285c:	b7c5                	j	8000283c <devintr+0x5e>
    if(cpuid() == 0){
    8000285e:	fffff097          	auipc	ra,0xfffff
    80002862:	1e6080e7          	jalr	486(ra) # 80001a44 <cpuid>
    80002866:	c901                	beqz	a0,80002876 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002868:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000286c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000286e:	14479073          	csrw	sip,a5
    return 2;
    80002872:	4509                	li	a0,2
    80002874:	b761                	j	800027fc <devintr+0x1e>
      clockintr();
    80002876:	00000097          	auipc	ra,0x0
    8000287a:	f22080e7          	jalr	-222(ra) # 80002798 <clockintr>
    8000287e:	b7ed                	j	80002868 <devintr+0x8a>

0000000080002880 <usertrap>:
{
    80002880:	1101                	addi	sp,sp,-32
    80002882:	ec06                	sd	ra,24(sp)
    80002884:	e822                	sd	s0,16(sp)
    80002886:	e426                	sd	s1,8(sp)
    80002888:	e04a                	sd	s2,0(sp)
    8000288a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002890:	1007f793          	andi	a5,a5,256
    80002894:	e3ad                	bnez	a5,800028f6 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002896:	00003797          	auipc	a5,0x3
    8000289a:	46a78793          	addi	a5,a5,1130 # 80005d00 <kernelvec>
    8000289e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028a2:	fffff097          	auipc	ra,0xfffff
    800028a6:	1ce080e7          	jalr	462(ra) # 80001a70 <myproc>
    800028aa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028ac:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ae:	14102773          	csrr	a4,sepc
    800028b2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028b8:	47a1                	li	a5,8
    800028ba:	04f71c63          	bne	a4,a5,80002912 <usertrap+0x92>
    if(p->killed)
    800028be:	591c                	lw	a5,48(a0)
    800028c0:	e3b9                	bnez	a5,80002906 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028c2:	6cb8                	ld	a4,88(s1)
    800028c4:	6f1c                	ld	a5,24(a4)
    800028c6:	0791                	addi	a5,a5,4
    800028c8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028ce:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d2:	10079073          	csrw	sstatus,a5
    syscall();
    800028d6:	00000097          	auipc	ra,0x0
    800028da:	2e6080e7          	jalr	742(ra) # 80002bbc <syscall>
  if(p->killed)
    800028de:	589c                	lw	a5,48(s1)
    800028e0:	ebc1                	bnez	a5,80002970 <usertrap+0xf0>
  usertrapret();
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	e18080e7          	jalr	-488(ra) # 800026fa <usertrapret>
}
    800028ea:	60e2                	ld	ra,24(sp)
    800028ec:	6442                	ld	s0,16(sp)
    800028ee:	64a2                	ld	s1,8(sp)
    800028f0:	6902                	ld	s2,0(sp)
    800028f2:	6105                	addi	sp,sp,32
    800028f4:	8082                	ret
    panic("usertrap: not from user mode");
    800028f6:	00006517          	auipc	a0,0x6
    800028fa:	a0250513          	addi	a0,a0,-1534 # 800082f8 <states.1723+0x130>
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	c76080e7          	jalr	-906(ra) # 80000574 <panic>
      exit(-1);
    80002906:	557d                	li	a0,-1
    80002908:	00000097          	auipc	ra,0x0
    8000290c:	842080e7          	jalr	-1982(ra) # 8000214a <exit>
    80002910:	bf4d                	j	800028c2 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002912:	00000097          	auipc	ra,0x0
    80002916:	ecc080e7          	jalr	-308(ra) # 800027de <devintr>
    8000291a:	892a                	mv	s2,a0
    8000291c:	c501                	beqz	a0,80002924 <usertrap+0xa4>
  if(p->killed)
    8000291e:	589c                	lw	a5,48(s1)
    80002920:	c3a1                	beqz	a5,80002960 <usertrap+0xe0>
    80002922:	a815                	j	80002956 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002924:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002928:	5c90                	lw	a2,56(s1)
    8000292a:	00006517          	auipc	a0,0x6
    8000292e:	9ee50513          	addi	a0,a0,-1554 # 80008318 <states.1723+0x150>
    80002932:	ffffe097          	auipc	ra,0xffffe
    80002936:	c8c080e7          	jalr	-884(ra) # 800005be <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000293e:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002942:	00006517          	auipc	a0,0x6
    80002946:	a0650513          	addi	a0,a0,-1530 # 80008348 <states.1723+0x180>
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	c74080e7          	jalr	-908(ra) # 800005be <printf>
    p->killed = 1;
    80002952:	4785                	li	a5,1
    80002954:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002956:	557d                	li	a0,-1
    80002958:	fffff097          	auipc	ra,0xfffff
    8000295c:	7f2080e7          	jalr	2034(ra) # 8000214a <exit>
  if(which_dev == 2)
    80002960:	4789                	li	a5,2
    80002962:	f8f910e3          	bne	s2,a5,800028e2 <usertrap+0x62>
    yield();
    80002966:	00000097          	auipc	ra,0x0
    8000296a:	8f0080e7          	jalr	-1808(ra) # 80002256 <yield>
    8000296e:	bf95                	j	800028e2 <usertrap+0x62>
  int which_dev = 0;
    80002970:	4901                	li	s2,0
    80002972:	b7d5                	j	80002956 <usertrap+0xd6>

0000000080002974 <kerneltrap>:
{
    80002974:	7179                	addi	sp,sp,-48
    80002976:	f406                	sd	ra,40(sp)
    80002978:	f022                	sd	s0,32(sp)
    8000297a:	ec26                	sd	s1,24(sp)
    8000297c:	e84a                	sd	s2,16(sp)
    8000297e:	e44e                	sd	s3,8(sp)
    80002980:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002982:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002986:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000298a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000298e:	1004f793          	andi	a5,s1,256
    80002992:	cb85                	beqz	a5,800029c2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002994:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002998:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000299a:	ef85                	bnez	a5,800029d2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000299c:	00000097          	auipc	ra,0x0
    800029a0:	e42080e7          	jalr	-446(ra) # 800027de <devintr>
    800029a4:	cd1d                	beqz	a0,800029e2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029a6:	4789                	li	a5,2
    800029a8:	06f50a63          	beq	a0,a5,80002a1c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ac:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029b0:	10049073          	csrw	sstatus,s1
}
    800029b4:	70a2                	ld	ra,40(sp)
    800029b6:	7402                	ld	s0,32(sp)
    800029b8:	64e2                	ld	s1,24(sp)
    800029ba:	6942                	ld	s2,16(sp)
    800029bc:	69a2                	ld	s3,8(sp)
    800029be:	6145                	addi	sp,sp,48
    800029c0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	9a650513          	addi	a0,a0,-1626 # 80008368 <states.1723+0x1a0>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	baa080e7          	jalr	-1110(ra) # 80000574 <panic>
    panic("kerneltrap: interrupts enabled");
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	9be50513          	addi	a0,a0,-1602 # 80008390 <states.1723+0x1c8>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	b9a080e7          	jalr	-1126(ra) # 80000574 <panic>
    printf("scause %p\n", scause);
    800029e2:	85ce                	mv	a1,s3
    800029e4:	00006517          	auipc	a0,0x6
    800029e8:	9cc50513          	addi	a0,a0,-1588 # 800083b0 <states.1723+0x1e8>
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	bd2080e7          	jalr	-1070(ra) # 800005be <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029f8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	9c450513          	addi	a0,a0,-1596 # 800083c0 <states.1723+0x1f8>
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	bba080e7          	jalr	-1094(ra) # 800005be <printf>
    panic("kerneltrap");
    80002a0c:	00006517          	auipc	a0,0x6
    80002a10:	9cc50513          	addi	a0,a0,-1588 # 800083d8 <states.1723+0x210>
    80002a14:	ffffe097          	auipc	ra,0xffffe
    80002a18:	b60080e7          	jalr	-1184(ra) # 80000574 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1c:	fffff097          	auipc	ra,0xfffff
    80002a20:	054080e7          	jalr	84(ra) # 80001a70 <myproc>
    80002a24:	d541                	beqz	a0,800029ac <kerneltrap+0x38>
    80002a26:	fffff097          	auipc	ra,0xfffff
    80002a2a:	04a080e7          	jalr	74(ra) # 80001a70 <myproc>
    80002a2e:	4d18                	lw	a4,24(a0)
    80002a30:	478d                	li	a5,3
    80002a32:	f6f71de3          	bne	a4,a5,800029ac <kerneltrap+0x38>
    yield();
    80002a36:	00000097          	auipc	ra,0x0
    80002a3a:	820080e7          	jalr	-2016(ra) # 80002256 <yield>
    80002a3e:	b7bd                	j	800029ac <kerneltrap+0x38>

0000000080002a40 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a40:	1101                	addi	sp,sp,-32
    80002a42:	ec06                	sd	ra,24(sp)
    80002a44:	e822                	sd	s0,16(sp)
    80002a46:	e426                	sd	s1,8(sp)
    80002a48:	1000                	addi	s0,sp,32
    80002a4a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	024080e7          	jalr	36(ra) # 80001a70 <myproc>
  switch (n) {
    80002a54:	4795                	li	a5,5
    80002a56:	0497e363          	bltu	a5,s1,80002a9c <argraw+0x5c>
    80002a5a:	1482                	slli	s1,s1,0x20
    80002a5c:	9081                	srli	s1,s1,0x20
    80002a5e:	048a                	slli	s1,s1,0x2
    80002a60:	00006717          	auipc	a4,0x6
    80002a64:	98870713          	addi	a4,a4,-1656 # 800083e8 <states.1723+0x220>
    80002a68:	94ba                	add	s1,s1,a4
    80002a6a:	409c                	lw	a5,0(s1)
    80002a6c:	97ba                	add	a5,a5,a4
    80002a6e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a70:	6d3c                	ld	a5,88(a0)
    80002a72:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a74:	60e2                	ld	ra,24(sp)
    80002a76:	6442                	ld	s0,16(sp)
    80002a78:	64a2                	ld	s1,8(sp)
    80002a7a:	6105                	addi	sp,sp,32
    80002a7c:	8082                	ret
    return p->trapframe->a1;
    80002a7e:	6d3c                	ld	a5,88(a0)
    80002a80:	7fa8                	ld	a0,120(a5)
    80002a82:	bfcd                	j	80002a74 <argraw+0x34>
    return p->trapframe->a2;
    80002a84:	6d3c                	ld	a5,88(a0)
    80002a86:	63c8                	ld	a0,128(a5)
    80002a88:	b7f5                	j	80002a74 <argraw+0x34>
    return p->trapframe->a3;
    80002a8a:	6d3c                	ld	a5,88(a0)
    80002a8c:	67c8                	ld	a0,136(a5)
    80002a8e:	b7dd                	j	80002a74 <argraw+0x34>
    return p->trapframe->a4;
    80002a90:	6d3c                	ld	a5,88(a0)
    80002a92:	6bc8                	ld	a0,144(a5)
    80002a94:	b7c5                	j	80002a74 <argraw+0x34>
    return p->trapframe->a5;
    80002a96:	6d3c                	ld	a5,88(a0)
    80002a98:	6fc8                	ld	a0,152(a5)
    80002a9a:	bfe9                	j	80002a74 <argraw+0x34>
  panic("argraw");
    80002a9c:	00006517          	auipc	a0,0x6
    80002aa0:	a3c50513          	addi	a0,a0,-1476 # 800084d8 <sysnames+0x20>
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	ad0080e7          	jalr	-1328(ra) # 80000574 <panic>

0000000080002aac <fetchaddr>:
{
    80002aac:	1101                	addi	sp,sp,-32
    80002aae:	ec06                	sd	ra,24(sp)
    80002ab0:	e822                	sd	s0,16(sp)
    80002ab2:	e426                	sd	s1,8(sp)
    80002ab4:	e04a                	sd	s2,0(sp)
    80002ab6:	1000                	addi	s0,sp,32
    80002ab8:	84aa                	mv	s1,a0
    80002aba:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002abc:	fffff097          	auipc	ra,0xfffff
    80002ac0:	fb4080e7          	jalr	-76(ra) # 80001a70 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ac4:	653c                	ld	a5,72(a0)
    80002ac6:	02f4f963          	bleu	a5,s1,80002af8 <fetchaddr+0x4c>
    80002aca:	00848713          	addi	a4,s1,8
    80002ace:	02e7e763          	bltu	a5,a4,80002afc <fetchaddr+0x50>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ad2:	46a1                	li	a3,8
    80002ad4:	8626                	mv	a2,s1
    80002ad6:	85ca                	mv	a1,s2
    80002ad8:	6928                	ld	a0,80(a0)
    80002ada:	fffff097          	auipc	ra,0xfffff
    80002ade:	cfe080e7          	jalr	-770(ra) # 800017d8 <copyin>
    80002ae2:	00a03533          	snez	a0,a0
    80002ae6:	40a0053b          	negw	a0,a0
    80002aea:	2501                	sext.w	a0,a0
}
    80002aec:	60e2                	ld	ra,24(sp)
    80002aee:	6442                	ld	s0,16(sp)
    80002af0:	64a2                	ld	s1,8(sp)
    80002af2:	6902                	ld	s2,0(sp)
    80002af4:	6105                	addi	sp,sp,32
    80002af6:	8082                	ret
    return -1;
    80002af8:	557d                	li	a0,-1
    80002afa:	bfcd                	j	80002aec <fetchaddr+0x40>
    80002afc:	557d                	li	a0,-1
    80002afe:	b7fd                	j	80002aec <fetchaddr+0x40>

0000000080002b00 <fetchstr>:
{
    80002b00:	7179                	addi	sp,sp,-48
    80002b02:	f406                	sd	ra,40(sp)
    80002b04:	f022                	sd	s0,32(sp)
    80002b06:	ec26                	sd	s1,24(sp)
    80002b08:	e84a                	sd	s2,16(sp)
    80002b0a:	e44e                	sd	s3,8(sp)
    80002b0c:	1800                	addi	s0,sp,48
    80002b0e:	892a                	mv	s2,a0
    80002b10:	84ae                	mv	s1,a1
    80002b12:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b14:	fffff097          	auipc	ra,0xfffff
    80002b18:	f5c080e7          	jalr	-164(ra) # 80001a70 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b1c:	86ce                	mv	a3,s3
    80002b1e:	864a                	mv	a2,s2
    80002b20:	85a6                	mv	a1,s1
    80002b22:	6928                	ld	a0,80(a0)
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	d42080e7          	jalr	-702(ra) # 80001866 <copyinstr>
  if(err < 0)
    80002b2c:	00054763          	bltz	a0,80002b3a <fetchstr+0x3a>
  return strlen(buf);
    80002b30:	8526                	mv	a0,s1
    80002b32:	ffffe097          	auipc	ra,0xffffe
    80002b36:	3d6080e7          	jalr	982(ra) # 80000f08 <strlen>
}
    80002b3a:	70a2                	ld	ra,40(sp)
    80002b3c:	7402                	ld	s0,32(sp)
    80002b3e:	64e2                	ld	s1,24(sp)
    80002b40:	6942                	ld	s2,16(sp)
    80002b42:	69a2                	ld	s3,8(sp)
    80002b44:	6145                	addi	sp,sp,48
    80002b46:	8082                	ret

0000000080002b48 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b48:	1101                	addi	sp,sp,-32
    80002b4a:	ec06                	sd	ra,24(sp)
    80002b4c:	e822                	sd	s0,16(sp)
    80002b4e:	e426                	sd	s1,8(sp)
    80002b50:	1000                	addi	s0,sp,32
    80002b52:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b54:	00000097          	auipc	ra,0x0
    80002b58:	eec080e7          	jalr	-276(ra) # 80002a40 <argraw>
    80002b5c:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b5e:	4501                	li	a0,0
    80002b60:	60e2                	ld	ra,24(sp)
    80002b62:	6442                	ld	s0,16(sp)
    80002b64:	64a2                	ld	s1,8(sp)
    80002b66:	6105                	addi	sp,sp,32
    80002b68:	8082                	ret

0000000080002b6a <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b6a:	1101                	addi	sp,sp,-32
    80002b6c:	ec06                	sd	ra,24(sp)
    80002b6e:	e822                	sd	s0,16(sp)
    80002b70:	e426                	sd	s1,8(sp)
    80002b72:	1000                	addi	s0,sp,32
    80002b74:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b76:	00000097          	auipc	ra,0x0
    80002b7a:	eca080e7          	jalr	-310(ra) # 80002a40 <argraw>
    80002b7e:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b80:	4501                	li	a0,0
    80002b82:	60e2                	ld	ra,24(sp)
    80002b84:	6442                	ld	s0,16(sp)
    80002b86:	64a2                	ld	s1,8(sp)
    80002b88:	6105                	addi	sp,sp,32
    80002b8a:	8082                	ret

0000000080002b8c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b8c:	1101                	addi	sp,sp,-32
    80002b8e:	ec06                	sd	ra,24(sp)
    80002b90:	e822                	sd	s0,16(sp)
    80002b92:	e426                	sd	s1,8(sp)
    80002b94:	e04a                	sd	s2,0(sp)
    80002b96:	1000                	addi	s0,sp,32
    80002b98:	84ae                	mv	s1,a1
    80002b9a:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b9c:	00000097          	auipc	ra,0x0
    80002ba0:	ea4080e7          	jalr	-348(ra) # 80002a40 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ba4:	864a                	mv	a2,s2
    80002ba6:	85a6                	mv	a1,s1
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	f58080e7          	jalr	-168(ra) # 80002b00 <fetchstr>
}
    80002bb0:	60e2                	ld	ra,24(sp)
    80002bb2:	6442                	ld	s0,16(sp)
    80002bb4:	64a2                	ld	s1,8(sp)
    80002bb6:	6902                	ld	s2,0(sp)
    80002bb8:	6105                	addi	sp,sp,32
    80002bba:	8082                	ret

0000000080002bbc <syscall>:
    "trace",
};

void
syscall(void)
{
    80002bbc:	7179                	addi	sp,sp,-48
    80002bbe:	f406                	sd	ra,40(sp)
    80002bc0:	f022                	sd	s0,32(sp)
    80002bc2:	ec26                	sd	s1,24(sp)
    80002bc4:	e84a                	sd	s2,16(sp)
    80002bc6:	e44e                	sd	s3,8(sp)
    80002bc8:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002bca:	fffff097          	auipc	ra,0xfffff
    80002bce:	ea6080e7          	jalr	-346(ra) # 80001a70 <myproc>
    80002bd2:	84aa                	mv	s1,a0

  num = p->trapframe->a7; // 系统调用代号存在a7寄存器内
    80002bd4:	05853983          	ld	s3,88(a0)
    80002bd8:	0a89b783          	ld	a5,168(s3)
    80002bdc:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002be0:	37fd                	addiw	a5,a5,-1
    80002be2:	4755                	li	a4,21
    80002be4:	04f76963          	bltu	a4,a5,80002c36 <syscall+0x7a>
    80002be8:	00391713          	slli	a4,s2,0x3
    80002bec:	00006797          	auipc	a5,0x6
    80002bf0:	81478793          	addi	a5,a5,-2028 # 80008400 <syscalls>
    80002bf4:	97ba                	add	a5,a5,a4
    80002bf6:	639c                	ld	a5,0(a5)
    80002bf8:	cf9d                	beqz	a5,80002c36 <syscall+0x7a>
    p->trapframe->a0 = syscalls[num](); // 返回值存在a0寄存器内
    80002bfa:	9782                	jalr	a5
    80002bfc:	06a9b823          	sd	a0,112(s3)
    if (p->tracemask & (1 << num)) { // << 判断是否需要trace这个系统调用
    80002c00:	4785                	li	a5,1
    80002c02:	012797bb          	sllw	a5,a5,s2
    80002c06:	1684b703          	ld	a4,360(s1)
    80002c0a:	8ff9                	and	a5,a5,a4
    80002c0c:	c7a1                	beqz	a5,80002c54 <syscall+0x98>
      // this process traces this sys call num
      printf("%d: syscall %s -> %d\n", p->pid, sysnames[num], p->trapframe->a0);
    80002c0e:	6cb8                	ld	a4,88(s1)
    80002c10:	090e                	slli	s2,s2,0x3
    80002c12:	00005797          	auipc	a5,0x5
    80002c16:	7ee78793          	addi	a5,a5,2030 # 80008400 <syscalls>
    80002c1a:	993e                	add	s2,s2,a5
    80002c1c:	7b34                	ld	a3,112(a4)
    80002c1e:	0b893603          	ld	a2,184(s2)
    80002c22:	5c8c                	lw	a1,56(s1)
    80002c24:	00006517          	auipc	a0,0x6
    80002c28:	8bc50513          	addi	a0,a0,-1860 # 800084e0 <sysnames+0x28>
    80002c2c:	ffffe097          	auipc	ra,0xffffe
    80002c30:	992080e7          	jalr	-1646(ra) # 800005be <printf>
    80002c34:	a005                	j	80002c54 <syscall+0x98>
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c36:	86ca                	mv	a3,s2
    80002c38:	15848613          	addi	a2,s1,344
    80002c3c:	5c8c                	lw	a1,56(s1)
    80002c3e:	00006517          	auipc	a0,0x6
    80002c42:	8ba50513          	addi	a0,a0,-1862 # 800084f8 <sysnames+0x40>
    80002c46:	ffffe097          	auipc	ra,0xffffe
    80002c4a:	978080e7          	jalr	-1672(ra) # 800005be <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c4e:	6cbc                	ld	a5,88(s1)
    80002c50:	577d                	li	a4,-1
    80002c52:	fbb8                	sd	a4,112(a5)
  }
}
    80002c54:	70a2                	ld	ra,40(sp)
    80002c56:	7402                	ld	s0,32(sp)
    80002c58:	64e2                	ld	s1,24(sp)
    80002c5a:	6942                	ld	s2,16(sp)
    80002c5c:	69a2                	ld	s3,8(sp)
    80002c5e:	6145                	addi	sp,sp,48
    80002c60:	8082                	ret

0000000080002c62 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c62:	1101                	addi	sp,sp,-32
    80002c64:	ec06                	sd	ra,24(sp)
    80002c66:	e822                	sd	s0,16(sp)
    80002c68:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c6a:	fec40593          	addi	a1,s0,-20
    80002c6e:	4501                	li	a0,0
    80002c70:	00000097          	auipc	ra,0x0
    80002c74:	ed8080e7          	jalr	-296(ra) # 80002b48 <argint>
    return -1;
    80002c78:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c7a:	00054963          	bltz	a0,80002c8c <sys_exit+0x2a>
  exit(n);
    80002c7e:	fec42503          	lw	a0,-20(s0)
    80002c82:	fffff097          	auipc	ra,0xfffff
    80002c86:	4c8080e7          	jalr	1224(ra) # 8000214a <exit>
  return 0;  // not reached
    80002c8a:	4781                	li	a5,0
}
    80002c8c:	853e                	mv	a0,a5
    80002c8e:	60e2                	ld	ra,24(sp)
    80002c90:	6442                	ld	s0,16(sp)
    80002c92:	6105                	addi	sp,sp,32
    80002c94:	8082                	ret

0000000080002c96 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c96:	1141                	addi	sp,sp,-16
    80002c98:	e406                	sd	ra,8(sp)
    80002c9a:	e022                	sd	s0,0(sp)
    80002c9c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c9e:	fffff097          	auipc	ra,0xfffff
    80002ca2:	dd2080e7          	jalr	-558(ra) # 80001a70 <myproc>
}
    80002ca6:	5d08                	lw	a0,56(a0)
    80002ca8:	60a2                	ld	ra,8(sp)
    80002caa:	6402                	ld	s0,0(sp)
    80002cac:	0141                	addi	sp,sp,16
    80002cae:	8082                	ret

0000000080002cb0 <sys_fork>:

uint64
sys_fork(void)
{
    80002cb0:	1141                	addi	sp,sp,-16
    80002cb2:	e406                	sd	ra,8(sp)
    80002cb4:	e022                	sd	s0,0(sp)
    80002cb6:	0800                	addi	s0,sp,16
  return fork();
    80002cb8:	fffff097          	auipc	ra,0xfffff
    80002cbc:	182080e7          	jalr	386(ra) # 80001e3a <fork>
}
    80002cc0:	60a2                	ld	ra,8(sp)
    80002cc2:	6402                	ld	s0,0(sp)
    80002cc4:	0141                	addi	sp,sp,16
    80002cc6:	8082                	ret

0000000080002cc8 <sys_wait>:

uint64
sys_wait(void)
{
    80002cc8:	1101                	addi	sp,sp,-32
    80002cca:	ec06                	sd	ra,24(sp)
    80002ccc:	e822                	sd	s0,16(sp)
    80002cce:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cd0:	fe840593          	addi	a1,s0,-24
    80002cd4:	4501                	li	a0,0
    80002cd6:	00000097          	auipc	ra,0x0
    80002cda:	e94080e7          	jalr	-364(ra) # 80002b6a <argaddr>
    return -1;
    80002cde:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80002ce0:	00054963          	bltz	a0,80002cf2 <sys_wait+0x2a>
  return wait(p);
    80002ce4:	fe843503          	ld	a0,-24(s0)
    80002ce8:	fffff097          	auipc	ra,0xfffff
    80002cec:	628080e7          	jalr	1576(ra) # 80002310 <wait>
    80002cf0:	87aa                	mv	a5,a0
}
    80002cf2:	853e                	mv	a0,a5
    80002cf4:	60e2                	ld	ra,24(sp)
    80002cf6:	6442                	ld	s0,16(sp)
    80002cf8:	6105                	addi	sp,sp,32
    80002cfa:	8082                	ret

0000000080002cfc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cfc:	7179                	addi	sp,sp,-48
    80002cfe:	f406                	sd	ra,40(sp)
    80002d00:	f022                	sd	s0,32(sp)
    80002d02:	ec26                	sd	s1,24(sp)
    80002d04:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d06:	fdc40593          	addi	a1,s0,-36
    80002d0a:	4501                	li	a0,0
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	e3c080e7          	jalr	-452(ra) # 80002b48 <argint>
    return -1;
    80002d14:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002d16:	00054f63          	bltz	a0,80002d34 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002d1a:	fffff097          	auipc	ra,0xfffff
    80002d1e:	d56080e7          	jalr	-682(ra) # 80001a70 <myproc>
    80002d22:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d24:	fdc42503          	lw	a0,-36(s0)
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	09a080e7          	jalr	154(ra) # 80001dc2 <growproc>
    80002d30:	00054863          	bltz	a0,80002d40 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002d34:	8526                	mv	a0,s1
    80002d36:	70a2                	ld	ra,40(sp)
    80002d38:	7402                	ld	s0,32(sp)
    80002d3a:	64e2                	ld	s1,24(sp)
    80002d3c:	6145                	addi	sp,sp,48
    80002d3e:	8082                	ret
    return -1;
    80002d40:	54fd                	li	s1,-1
    80002d42:	bfcd                	j	80002d34 <sys_sbrk+0x38>

0000000080002d44 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d44:	7139                	addi	sp,sp,-64
    80002d46:	fc06                	sd	ra,56(sp)
    80002d48:	f822                	sd	s0,48(sp)
    80002d4a:	f426                	sd	s1,40(sp)
    80002d4c:	f04a                	sd	s2,32(sp)
    80002d4e:	ec4e                	sd	s3,24(sp)
    80002d50:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d52:	fcc40593          	addi	a1,s0,-52
    80002d56:	4501                	li	a0,0
    80002d58:	00000097          	auipc	ra,0x0
    80002d5c:	df0080e7          	jalr	-528(ra) # 80002b48 <argint>
    return -1;
    80002d60:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d62:	06054763          	bltz	a0,80002dd0 <sys_sleep+0x8c>
  acquire(&tickslock);
    80002d66:	00015517          	auipc	a0,0x15
    80002d6a:	c0250513          	addi	a0,a0,-1022 # 80017968 <tickslock>
    80002d6e:	ffffe097          	auipc	ra,0xffffe
    80002d72:	ef4080e7          	jalr	-268(ra) # 80000c62 <acquire>
  ticks0 = ticks;
    80002d76:	00006797          	auipc	a5,0x6
    80002d7a:	2aa78793          	addi	a5,a5,682 # 80009020 <ticks>
    80002d7e:	0007a903          	lw	s2,0(a5)
  while(ticks - ticks0 < n){
    80002d82:	fcc42783          	lw	a5,-52(s0)
    80002d86:	cf85                	beqz	a5,80002dbe <sys_sleep+0x7a>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d88:	00015997          	auipc	s3,0x15
    80002d8c:	be098993          	addi	s3,s3,-1056 # 80017968 <tickslock>
    80002d90:	00006497          	auipc	s1,0x6
    80002d94:	29048493          	addi	s1,s1,656 # 80009020 <ticks>
    if(myproc()->killed){
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	cd8080e7          	jalr	-808(ra) # 80001a70 <myproc>
    80002da0:	591c                	lw	a5,48(a0)
    80002da2:	ef9d                	bnez	a5,80002de0 <sys_sleep+0x9c>
    sleep(&ticks, &tickslock);
    80002da4:	85ce                	mv	a1,s3
    80002da6:	8526                	mv	a0,s1
    80002da8:	fffff097          	auipc	ra,0xfffff
    80002dac:	4ea080e7          	jalr	1258(ra) # 80002292 <sleep>
  while(ticks - ticks0 < n){
    80002db0:	409c                	lw	a5,0(s1)
    80002db2:	412787bb          	subw	a5,a5,s2
    80002db6:	fcc42703          	lw	a4,-52(s0)
    80002dba:	fce7efe3          	bltu	a5,a4,80002d98 <sys_sleep+0x54>
  }
  release(&tickslock);
    80002dbe:	00015517          	auipc	a0,0x15
    80002dc2:	baa50513          	addi	a0,a0,-1110 # 80017968 <tickslock>
    80002dc6:	ffffe097          	auipc	ra,0xffffe
    80002dca:	f50080e7          	jalr	-176(ra) # 80000d16 <release>
  return 0;
    80002dce:	4781                	li	a5,0
}
    80002dd0:	853e                	mv	a0,a5
    80002dd2:	70e2                	ld	ra,56(sp)
    80002dd4:	7442                	ld	s0,48(sp)
    80002dd6:	74a2                	ld	s1,40(sp)
    80002dd8:	7902                	ld	s2,32(sp)
    80002dda:	69e2                	ld	s3,24(sp)
    80002ddc:	6121                	addi	sp,sp,64
    80002dde:	8082                	ret
      release(&tickslock);
    80002de0:	00015517          	auipc	a0,0x15
    80002de4:	b8850513          	addi	a0,a0,-1144 # 80017968 <tickslock>
    80002de8:	ffffe097          	auipc	ra,0xffffe
    80002dec:	f2e080e7          	jalr	-210(ra) # 80000d16 <release>
      return -1;
    80002df0:	57fd                	li	a5,-1
    80002df2:	bff9                	j	80002dd0 <sys_sleep+0x8c>

0000000080002df4 <sys_kill>:

uint64
sys_kill(void)
{
    80002df4:	1101                	addi	sp,sp,-32
    80002df6:	ec06                	sd	ra,24(sp)
    80002df8:	e822                	sd	s0,16(sp)
    80002dfa:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dfc:	fec40593          	addi	a1,s0,-20
    80002e00:	4501                	li	a0,0
    80002e02:	00000097          	auipc	ra,0x0
    80002e06:	d46080e7          	jalr	-698(ra) # 80002b48 <argint>
    return -1;
    80002e0a:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80002e0c:	00054963          	bltz	a0,80002e1e <sys_kill+0x2a>
  return kill(pid);
    80002e10:	fec42503          	lw	a0,-20(s0)
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	66e080e7          	jalr	1646(ra) # 80002482 <kill>
    80002e1c:	87aa                	mv	a5,a0
}
    80002e1e:	853e                	mv	a0,a5
    80002e20:	60e2                	ld	ra,24(sp)
    80002e22:	6442                	ld	s0,16(sp)
    80002e24:	6105                	addi	sp,sp,32
    80002e26:	8082                	ret

0000000080002e28 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e28:	1101                	addi	sp,sp,-32
    80002e2a:	ec06                	sd	ra,24(sp)
    80002e2c:	e822                	sd	s0,16(sp)
    80002e2e:	e426                	sd	s1,8(sp)
    80002e30:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e32:	00015517          	auipc	a0,0x15
    80002e36:	b3650513          	addi	a0,a0,-1226 # 80017968 <tickslock>
    80002e3a:	ffffe097          	auipc	ra,0xffffe
    80002e3e:	e28080e7          	jalr	-472(ra) # 80000c62 <acquire>
  xticks = ticks;
    80002e42:	00006797          	auipc	a5,0x6
    80002e46:	1de78793          	addi	a5,a5,478 # 80009020 <ticks>
    80002e4a:	4384                	lw	s1,0(a5)
  release(&tickslock);
    80002e4c:	00015517          	auipc	a0,0x15
    80002e50:	b1c50513          	addi	a0,a0,-1252 # 80017968 <tickslock>
    80002e54:	ffffe097          	auipc	ra,0xffffe
    80002e58:	ec2080e7          	jalr	-318(ra) # 80000d16 <release>
  return xticks;
}
    80002e5c:	02049513          	slli	a0,s1,0x20
    80002e60:	9101                	srli	a0,a0,0x20
    80002e62:	60e2                	ld	ra,24(sp)
    80002e64:	6442                	ld	s0,16(sp)
    80002e66:	64a2                	ld	s1,8(sp)
    80002e68:	6105                	addi	sp,sp,32
    80002e6a:	8082                	ret

0000000080002e6c <sys_trace>:

// click the sys call number in p->tracemask
// so as to tracing its calling afterwards
uint64 
sys_trace(void) {
    80002e6c:	1101                	addi	sp,sp,-32
    80002e6e:	ec06                	sd	ra,24(sp)
    80002e70:	e822                	sd	s0,16(sp)
    80002e72:	1000                	addi	s0,sp,32
  int trace_sys_mask;
  if (argint(0, &trace_sys_mask) < 0)
    80002e74:	fec40593          	addi	a1,s0,-20
    80002e78:	4501                	li	a0,0
    80002e7a:	00000097          	auipc	ra,0x0
    80002e7e:	cce080e7          	jalr	-818(ra) # 80002b48 <argint>
    return -1;
    80002e82:	57fd                	li	a5,-1
  if (argint(0, &trace_sys_mask) < 0)
    80002e84:	00054e63          	bltz	a0,80002ea0 <sys_trace+0x34>
  myproc()->tracemask |= trace_sys_mask;
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	be8080e7          	jalr	-1048(ra) # 80001a70 <myproc>
    80002e90:	fec42703          	lw	a4,-20(s0)
    80002e94:	16853783          	ld	a5,360(a0)
    80002e98:	8fd9                	or	a5,a5,a4
    80002e9a:	16f53423          	sd	a5,360(a0)
  return 0;
    80002e9e:	4781                	li	a5,0
}
    80002ea0:	853e                	mv	a0,a5
    80002ea2:	60e2                	ld	ra,24(sp)
    80002ea4:	6442                	ld	s0,16(sp)
    80002ea6:	6105                	addi	sp,sp,32
    80002ea8:	8082                	ret

0000000080002eaa <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eaa:	7179                	addi	sp,sp,-48
    80002eac:	f406                	sd	ra,40(sp)
    80002eae:	f022                	sd	s0,32(sp)
    80002eb0:	ec26                	sd	s1,24(sp)
    80002eb2:	e84a                	sd	s2,16(sp)
    80002eb4:	e44e                	sd	s3,8(sp)
    80002eb6:	e052                	sd	s4,0(sp)
    80002eb8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eba:	00005597          	auipc	a1,0x5
    80002ebe:	67658593          	addi	a1,a1,1654 # 80008530 <sysnames+0x78>
    80002ec2:	00015517          	auipc	a0,0x15
    80002ec6:	abe50513          	addi	a0,a0,-1346 # 80017980 <bcache>
    80002eca:	ffffe097          	auipc	ra,0xffffe
    80002ece:	d08080e7          	jalr	-760(ra) # 80000bd2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ed2:	0001d797          	auipc	a5,0x1d
    80002ed6:	aae78793          	addi	a5,a5,-1362 # 8001f980 <bcache+0x8000>
    80002eda:	0001d717          	auipc	a4,0x1d
    80002ede:	d0e70713          	addi	a4,a4,-754 # 8001fbe8 <bcache+0x8268>
    80002ee2:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ee6:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eea:	00015497          	auipc	s1,0x15
    80002eee:	aae48493          	addi	s1,s1,-1362 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002ef2:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ef4:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ef6:	00005a17          	auipc	s4,0x5
    80002efa:	642a0a13          	addi	s4,s4,1602 # 80008538 <sysnames+0x80>
    b->next = bcache.head.next;
    80002efe:	2b893783          	ld	a5,696(s2)
    80002f02:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f04:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f08:	85d2                	mv	a1,s4
    80002f0a:	01048513          	addi	a0,s1,16
    80002f0e:	00001097          	auipc	ra,0x1
    80002f12:	51a080e7          	jalr	1306(ra) # 80004428 <initsleeplock>
    bcache.head.next->prev = b;
    80002f16:	2b893783          	ld	a5,696(s2)
    80002f1a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f1c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f20:	45848493          	addi	s1,s1,1112
    80002f24:	fd349de3          	bne	s1,s3,80002efe <binit+0x54>
  }
}
    80002f28:	70a2                	ld	ra,40(sp)
    80002f2a:	7402                	ld	s0,32(sp)
    80002f2c:	64e2                	ld	s1,24(sp)
    80002f2e:	6942                	ld	s2,16(sp)
    80002f30:	69a2                	ld	s3,8(sp)
    80002f32:	6a02                	ld	s4,0(sp)
    80002f34:	6145                	addi	sp,sp,48
    80002f36:	8082                	ret

0000000080002f38 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f38:	7179                	addi	sp,sp,-48
    80002f3a:	f406                	sd	ra,40(sp)
    80002f3c:	f022                	sd	s0,32(sp)
    80002f3e:	ec26                	sd	s1,24(sp)
    80002f40:	e84a                	sd	s2,16(sp)
    80002f42:	e44e                	sd	s3,8(sp)
    80002f44:	1800                	addi	s0,sp,48
    80002f46:	89aa                	mv	s3,a0
    80002f48:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f4a:	00015517          	auipc	a0,0x15
    80002f4e:	a3650513          	addi	a0,a0,-1482 # 80017980 <bcache>
    80002f52:	ffffe097          	auipc	ra,0xffffe
    80002f56:	d10080e7          	jalr	-752(ra) # 80000c62 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f5a:	0001d797          	auipc	a5,0x1d
    80002f5e:	a2678793          	addi	a5,a5,-1498 # 8001f980 <bcache+0x8000>
    80002f62:	2b87b483          	ld	s1,696(a5)
    80002f66:	0001d797          	auipc	a5,0x1d
    80002f6a:	c8278793          	addi	a5,a5,-894 # 8001fbe8 <bcache+0x8268>
    80002f6e:	02f48f63          	beq	s1,a5,80002fac <bread+0x74>
    80002f72:	873e                	mv	a4,a5
    80002f74:	a021                	j	80002f7c <bread+0x44>
    80002f76:	68a4                	ld	s1,80(s1)
    80002f78:	02e48a63          	beq	s1,a4,80002fac <bread+0x74>
    if(b->dev == dev && b->blockno == blockno){
    80002f7c:	449c                	lw	a5,8(s1)
    80002f7e:	ff379ce3          	bne	a5,s3,80002f76 <bread+0x3e>
    80002f82:	44dc                	lw	a5,12(s1)
    80002f84:	ff2799e3          	bne	a5,s2,80002f76 <bread+0x3e>
      b->refcnt++;
    80002f88:	40bc                	lw	a5,64(s1)
    80002f8a:	2785                	addiw	a5,a5,1
    80002f8c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f8e:	00015517          	auipc	a0,0x15
    80002f92:	9f250513          	addi	a0,a0,-1550 # 80017980 <bcache>
    80002f96:	ffffe097          	auipc	ra,0xffffe
    80002f9a:	d80080e7          	jalr	-640(ra) # 80000d16 <release>
      acquiresleep(&b->lock);
    80002f9e:	01048513          	addi	a0,s1,16
    80002fa2:	00001097          	auipc	ra,0x1
    80002fa6:	4c0080e7          	jalr	1216(ra) # 80004462 <acquiresleep>
      return b;
    80002faa:	a8b1                	j	80003006 <bread+0xce>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fac:	0001d797          	auipc	a5,0x1d
    80002fb0:	9d478793          	addi	a5,a5,-1580 # 8001f980 <bcache+0x8000>
    80002fb4:	2b07b483          	ld	s1,688(a5)
    80002fb8:	0001d797          	auipc	a5,0x1d
    80002fbc:	c3078793          	addi	a5,a5,-976 # 8001fbe8 <bcache+0x8268>
    80002fc0:	04f48d63          	beq	s1,a5,8000301a <bread+0xe2>
    if(b->refcnt == 0) {
    80002fc4:	40bc                	lw	a5,64(s1)
    80002fc6:	cb91                	beqz	a5,80002fda <bread+0xa2>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc8:	0001d717          	auipc	a4,0x1d
    80002fcc:	c2070713          	addi	a4,a4,-992 # 8001fbe8 <bcache+0x8268>
    80002fd0:	64a4                	ld	s1,72(s1)
    80002fd2:	04e48463          	beq	s1,a4,8000301a <bread+0xe2>
    if(b->refcnt == 0) {
    80002fd6:	40bc                	lw	a5,64(s1)
    80002fd8:	ffe5                	bnez	a5,80002fd0 <bread+0x98>
      b->dev = dev;
    80002fda:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fde:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fe2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fe6:	4785                	li	a5,1
    80002fe8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fea:	00015517          	auipc	a0,0x15
    80002fee:	99650513          	addi	a0,a0,-1642 # 80017980 <bcache>
    80002ff2:	ffffe097          	auipc	ra,0xffffe
    80002ff6:	d24080e7          	jalr	-732(ra) # 80000d16 <release>
      acquiresleep(&b->lock);
    80002ffa:	01048513          	addi	a0,s1,16
    80002ffe:	00001097          	auipc	ra,0x1
    80003002:	464080e7          	jalr	1124(ra) # 80004462 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003006:	409c                	lw	a5,0(s1)
    80003008:	c38d                	beqz	a5,8000302a <bread+0xf2>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000300a:	8526                	mv	a0,s1
    8000300c:	70a2                	ld	ra,40(sp)
    8000300e:	7402                	ld	s0,32(sp)
    80003010:	64e2                	ld	s1,24(sp)
    80003012:	6942                	ld	s2,16(sp)
    80003014:	69a2                	ld	s3,8(sp)
    80003016:	6145                	addi	sp,sp,48
    80003018:	8082                	ret
  panic("bget: no buffers");
    8000301a:	00005517          	auipc	a0,0x5
    8000301e:	52650513          	addi	a0,a0,1318 # 80008540 <sysnames+0x88>
    80003022:	ffffd097          	auipc	ra,0xffffd
    80003026:	552080e7          	jalr	1362(ra) # 80000574 <panic>
    virtio_disk_rw(b, 0);
    8000302a:	4581                	li	a1,0
    8000302c:	8526                	mv	a0,s1
    8000302e:	00003097          	auipc	ra,0x3
    80003032:	ff0080e7          	jalr	-16(ra) # 8000601e <virtio_disk_rw>
    b->valid = 1;
    80003036:	4785                	li	a5,1
    80003038:	c09c                	sw	a5,0(s1)
  return b;
    8000303a:	bfc1                	j	8000300a <bread+0xd2>

000000008000303c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000303c:	1101                	addi	sp,sp,-32
    8000303e:	ec06                	sd	ra,24(sp)
    80003040:	e822                	sd	s0,16(sp)
    80003042:	e426                	sd	s1,8(sp)
    80003044:	1000                	addi	s0,sp,32
    80003046:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003048:	0541                	addi	a0,a0,16
    8000304a:	00001097          	auipc	ra,0x1
    8000304e:	4b2080e7          	jalr	1202(ra) # 800044fc <holdingsleep>
    80003052:	cd01                	beqz	a0,8000306a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003054:	4585                	li	a1,1
    80003056:	8526                	mv	a0,s1
    80003058:	00003097          	auipc	ra,0x3
    8000305c:	fc6080e7          	jalr	-58(ra) # 8000601e <virtio_disk_rw>
}
    80003060:	60e2                	ld	ra,24(sp)
    80003062:	6442                	ld	s0,16(sp)
    80003064:	64a2                	ld	s1,8(sp)
    80003066:	6105                	addi	sp,sp,32
    80003068:	8082                	ret
    panic("bwrite");
    8000306a:	00005517          	auipc	a0,0x5
    8000306e:	4ee50513          	addi	a0,a0,1262 # 80008558 <sysnames+0xa0>
    80003072:	ffffd097          	auipc	ra,0xffffd
    80003076:	502080e7          	jalr	1282(ra) # 80000574 <panic>

000000008000307a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000307a:	1101                	addi	sp,sp,-32
    8000307c:	ec06                	sd	ra,24(sp)
    8000307e:	e822                	sd	s0,16(sp)
    80003080:	e426                	sd	s1,8(sp)
    80003082:	e04a                	sd	s2,0(sp)
    80003084:	1000                	addi	s0,sp,32
    80003086:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003088:	01050913          	addi	s2,a0,16
    8000308c:	854a                	mv	a0,s2
    8000308e:	00001097          	auipc	ra,0x1
    80003092:	46e080e7          	jalr	1134(ra) # 800044fc <holdingsleep>
    80003096:	c92d                	beqz	a0,80003108 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003098:	854a                	mv	a0,s2
    8000309a:	00001097          	auipc	ra,0x1
    8000309e:	41e080e7          	jalr	1054(ra) # 800044b8 <releasesleep>

  acquire(&bcache.lock);
    800030a2:	00015517          	auipc	a0,0x15
    800030a6:	8de50513          	addi	a0,a0,-1826 # 80017980 <bcache>
    800030aa:	ffffe097          	auipc	ra,0xffffe
    800030ae:	bb8080e7          	jalr	-1096(ra) # 80000c62 <acquire>
  b->refcnt--;
    800030b2:	40bc                	lw	a5,64(s1)
    800030b4:	37fd                	addiw	a5,a5,-1
    800030b6:	0007871b          	sext.w	a4,a5
    800030ba:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030bc:	eb05                	bnez	a4,800030ec <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030be:	68bc                	ld	a5,80(s1)
    800030c0:	64b8                	ld	a4,72(s1)
    800030c2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030c4:	64bc                	ld	a5,72(s1)
    800030c6:	68b8                	ld	a4,80(s1)
    800030c8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030ca:	0001d797          	auipc	a5,0x1d
    800030ce:	8b678793          	addi	a5,a5,-1866 # 8001f980 <bcache+0x8000>
    800030d2:	2b87b703          	ld	a4,696(a5)
    800030d6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030d8:	0001d717          	auipc	a4,0x1d
    800030dc:	b1070713          	addi	a4,a4,-1264 # 8001fbe8 <bcache+0x8268>
    800030e0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030e2:	2b87b703          	ld	a4,696(a5)
    800030e6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030e8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030ec:	00015517          	auipc	a0,0x15
    800030f0:	89450513          	addi	a0,a0,-1900 # 80017980 <bcache>
    800030f4:	ffffe097          	auipc	ra,0xffffe
    800030f8:	c22080e7          	jalr	-990(ra) # 80000d16 <release>
}
    800030fc:	60e2                	ld	ra,24(sp)
    800030fe:	6442                	ld	s0,16(sp)
    80003100:	64a2                	ld	s1,8(sp)
    80003102:	6902                	ld	s2,0(sp)
    80003104:	6105                	addi	sp,sp,32
    80003106:	8082                	ret
    panic("brelse");
    80003108:	00005517          	auipc	a0,0x5
    8000310c:	45850513          	addi	a0,a0,1112 # 80008560 <sysnames+0xa8>
    80003110:	ffffd097          	auipc	ra,0xffffd
    80003114:	464080e7          	jalr	1124(ra) # 80000574 <panic>

0000000080003118 <bpin>:

void
bpin(struct buf *b) {
    80003118:	1101                	addi	sp,sp,-32
    8000311a:	ec06                	sd	ra,24(sp)
    8000311c:	e822                	sd	s0,16(sp)
    8000311e:	e426                	sd	s1,8(sp)
    80003120:	1000                	addi	s0,sp,32
    80003122:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003124:	00015517          	auipc	a0,0x15
    80003128:	85c50513          	addi	a0,a0,-1956 # 80017980 <bcache>
    8000312c:	ffffe097          	auipc	ra,0xffffe
    80003130:	b36080e7          	jalr	-1226(ra) # 80000c62 <acquire>
  b->refcnt++;
    80003134:	40bc                	lw	a5,64(s1)
    80003136:	2785                	addiw	a5,a5,1
    80003138:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000313a:	00015517          	auipc	a0,0x15
    8000313e:	84650513          	addi	a0,a0,-1978 # 80017980 <bcache>
    80003142:	ffffe097          	auipc	ra,0xffffe
    80003146:	bd4080e7          	jalr	-1068(ra) # 80000d16 <release>
}
    8000314a:	60e2                	ld	ra,24(sp)
    8000314c:	6442                	ld	s0,16(sp)
    8000314e:	64a2                	ld	s1,8(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret

0000000080003154 <bunpin>:

void
bunpin(struct buf *b) {
    80003154:	1101                	addi	sp,sp,-32
    80003156:	ec06                	sd	ra,24(sp)
    80003158:	e822                	sd	s0,16(sp)
    8000315a:	e426                	sd	s1,8(sp)
    8000315c:	1000                	addi	s0,sp,32
    8000315e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003160:	00015517          	auipc	a0,0x15
    80003164:	82050513          	addi	a0,a0,-2016 # 80017980 <bcache>
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	afa080e7          	jalr	-1286(ra) # 80000c62 <acquire>
  b->refcnt--;
    80003170:	40bc                	lw	a5,64(s1)
    80003172:	37fd                	addiw	a5,a5,-1
    80003174:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003176:	00015517          	auipc	a0,0x15
    8000317a:	80a50513          	addi	a0,a0,-2038 # 80017980 <bcache>
    8000317e:	ffffe097          	auipc	ra,0xffffe
    80003182:	b98080e7          	jalr	-1128(ra) # 80000d16 <release>
}
    80003186:	60e2                	ld	ra,24(sp)
    80003188:	6442                	ld	s0,16(sp)
    8000318a:	64a2                	ld	s1,8(sp)
    8000318c:	6105                	addi	sp,sp,32
    8000318e:	8082                	ret

0000000080003190 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003190:	1101                	addi	sp,sp,-32
    80003192:	ec06                	sd	ra,24(sp)
    80003194:	e822                	sd	s0,16(sp)
    80003196:	e426                	sd	s1,8(sp)
    80003198:	e04a                	sd	s2,0(sp)
    8000319a:	1000                	addi	s0,sp,32
    8000319c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000319e:	00d5d59b          	srliw	a1,a1,0xd
    800031a2:	0001d797          	auipc	a5,0x1d
    800031a6:	e9e78793          	addi	a5,a5,-354 # 80020040 <sb>
    800031aa:	4fdc                	lw	a5,28(a5)
    800031ac:	9dbd                	addw	a1,a1,a5
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	d8a080e7          	jalr	-630(ra) # 80002f38 <bread>
  bi = b % BPB;
    800031b6:	2481                	sext.w	s1,s1
  m = 1 << (bi % 8);
    800031b8:	0074f793          	andi	a5,s1,7
    800031bc:	4705                	li	a4,1
    800031be:	00f7173b          	sllw	a4,a4,a5
  bi = b % BPB;
    800031c2:	6789                	lui	a5,0x2
    800031c4:	17fd                	addi	a5,a5,-1
    800031c6:	8cfd                	and	s1,s1,a5
  if((bp->data[bi/8] & m) == 0)
    800031c8:	41f4d79b          	sraiw	a5,s1,0x1f
    800031cc:	01d7d79b          	srliw	a5,a5,0x1d
    800031d0:	9fa5                	addw	a5,a5,s1
    800031d2:	4037d79b          	sraiw	a5,a5,0x3
    800031d6:	00f506b3          	add	a3,a0,a5
    800031da:	0586c683          	lbu	a3,88(a3)
    800031de:	00d77633          	and	a2,a4,a3
    800031e2:	c61d                	beqz	a2,80003210 <bfree+0x80>
    800031e4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031e6:	97aa                	add	a5,a5,a0
    800031e8:	fff74713          	not	a4,a4
    800031ec:	8f75                	and	a4,a4,a3
    800031ee:	04e78c23          	sb	a4,88(a5) # 2058 <_entry-0x7fffdfa8>
  log_write(bp);
    800031f2:	00001097          	auipc	ra,0x1
    800031f6:	132080e7          	jalr	306(ra) # 80004324 <log_write>
  brelse(bp);
    800031fa:	854a                	mv	a0,s2
    800031fc:	00000097          	auipc	ra,0x0
    80003200:	e7e080e7          	jalr	-386(ra) # 8000307a <brelse>
}
    80003204:	60e2                	ld	ra,24(sp)
    80003206:	6442                	ld	s0,16(sp)
    80003208:	64a2                	ld	s1,8(sp)
    8000320a:	6902                	ld	s2,0(sp)
    8000320c:	6105                	addi	sp,sp,32
    8000320e:	8082                	ret
    panic("freeing free block");
    80003210:	00005517          	auipc	a0,0x5
    80003214:	35850513          	addi	a0,a0,856 # 80008568 <sysnames+0xb0>
    80003218:	ffffd097          	auipc	ra,0xffffd
    8000321c:	35c080e7          	jalr	860(ra) # 80000574 <panic>

0000000080003220 <balloc>:
{
    80003220:	711d                	addi	sp,sp,-96
    80003222:	ec86                	sd	ra,88(sp)
    80003224:	e8a2                	sd	s0,80(sp)
    80003226:	e4a6                	sd	s1,72(sp)
    80003228:	e0ca                	sd	s2,64(sp)
    8000322a:	fc4e                	sd	s3,56(sp)
    8000322c:	f852                	sd	s4,48(sp)
    8000322e:	f456                	sd	s5,40(sp)
    80003230:	f05a                	sd	s6,32(sp)
    80003232:	ec5e                	sd	s7,24(sp)
    80003234:	e862                	sd	s8,16(sp)
    80003236:	e466                	sd	s9,8(sp)
    80003238:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000323a:	0001d797          	auipc	a5,0x1d
    8000323e:	e0678793          	addi	a5,a5,-506 # 80020040 <sb>
    80003242:	43dc                	lw	a5,4(a5)
    80003244:	10078e63          	beqz	a5,80003360 <balloc+0x140>
    80003248:	8baa                	mv	s7,a0
    8000324a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000324c:	0001db17          	auipc	s6,0x1d
    80003250:	df4b0b13          	addi	s6,s6,-524 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003254:	4c05                	li	s8,1
      m = 1 << (bi % 8);
    80003256:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003258:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000325a:	6c89                	lui	s9,0x2
    8000325c:	a079                	j	800032ea <balloc+0xca>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000325e:	8942                	mv	s2,a6
      m = 1 << (bi % 8);
    80003260:	4705                	li	a4,1
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003262:	4681                	li	a3,0
        bp->data[bi/8] |= m;  // Mark block in use.
    80003264:	96a6                	add	a3,a3,s1
    80003266:	8f51                	or	a4,a4,a2
    80003268:	04e68c23          	sb	a4,88(a3)
        log_write(bp);
    8000326c:	8526                	mv	a0,s1
    8000326e:	00001097          	auipc	ra,0x1
    80003272:	0b6080e7          	jalr	182(ra) # 80004324 <log_write>
        brelse(bp);
    80003276:	8526                	mv	a0,s1
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	e02080e7          	jalr	-510(ra) # 8000307a <brelse>
  bp = bread(dev, bno);
    80003280:	85ca                	mv	a1,s2
    80003282:	855e                	mv	a0,s7
    80003284:	00000097          	auipc	ra,0x0
    80003288:	cb4080e7          	jalr	-844(ra) # 80002f38 <bread>
    8000328c:	84aa                	mv	s1,a0
  memset(bp->data, 0, BSIZE);
    8000328e:	40000613          	li	a2,1024
    80003292:	4581                	li	a1,0
    80003294:	05850513          	addi	a0,a0,88
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	ac6080e7          	jalr	-1338(ra) # 80000d5e <memset>
  log_write(bp);
    800032a0:	8526                	mv	a0,s1
    800032a2:	00001097          	auipc	ra,0x1
    800032a6:	082080e7          	jalr	130(ra) # 80004324 <log_write>
  brelse(bp);
    800032aa:	8526                	mv	a0,s1
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	dce080e7          	jalr	-562(ra) # 8000307a <brelse>
}
    800032b4:	854a                	mv	a0,s2
    800032b6:	60e6                	ld	ra,88(sp)
    800032b8:	6446                	ld	s0,80(sp)
    800032ba:	64a6                	ld	s1,72(sp)
    800032bc:	6906                	ld	s2,64(sp)
    800032be:	79e2                	ld	s3,56(sp)
    800032c0:	7a42                	ld	s4,48(sp)
    800032c2:	7aa2                	ld	s5,40(sp)
    800032c4:	7b02                	ld	s6,32(sp)
    800032c6:	6be2                	ld	s7,24(sp)
    800032c8:	6c42                	ld	s8,16(sp)
    800032ca:	6ca2                	ld	s9,8(sp)
    800032cc:	6125                	addi	sp,sp,96
    800032ce:	8082                	ret
    brelse(bp);
    800032d0:	8526                	mv	a0,s1
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	da8080e7          	jalr	-600(ra) # 8000307a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032da:	015c87bb          	addw	a5,s9,s5
    800032de:	00078a9b          	sext.w	s5,a5
    800032e2:	004b2703          	lw	a4,4(s6)
    800032e6:	06eafd63          	bleu	a4,s5,80003360 <balloc+0x140>
    bp = bread(dev, BBLOCK(b, sb));
    800032ea:	41fad79b          	sraiw	a5,s5,0x1f
    800032ee:	0137d79b          	srliw	a5,a5,0x13
    800032f2:	015787bb          	addw	a5,a5,s5
    800032f6:	40d7d79b          	sraiw	a5,a5,0xd
    800032fa:	01cb2583          	lw	a1,28(s6)
    800032fe:	9dbd                	addw	a1,a1,a5
    80003300:	855e                	mv	a0,s7
    80003302:	00000097          	auipc	ra,0x0
    80003306:	c36080e7          	jalr	-970(ra) # 80002f38 <bread>
    8000330a:	84aa                	mv	s1,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330c:	000a881b          	sext.w	a6,s5
    80003310:	004b2503          	lw	a0,4(s6)
    80003314:	faa87ee3          	bleu	a0,a6,800032d0 <balloc+0xb0>
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003318:	0584c603          	lbu	a2,88(s1)
    8000331c:	00167793          	andi	a5,a2,1
    80003320:	df9d                	beqz	a5,8000325e <balloc+0x3e>
    80003322:	4105053b          	subw	a0,a0,a6
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003326:	87e2                	mv	a5,s8
    80003328:	0107893b          	addw	s2,a5,a6
    8000332c:	faa782e3          	beq	a5,a0,800032d0 <balloc+0xb0>
      m = 1 << (bi % 8);
    80003330:	41f7d71b          	sraiw	a4,a5,0x1f
    80003334:	01d7561b          	srliw	a2,a4,0x1d
    80003338:	00f606bb          	addw	a3,a2,a5
    8000333c:	0076f713          	andi	a4,a3,7
    80003340:	9f11                	subw	a4,a4,a2
    80003342:	00e9973b          	sllw	a4,s3,a4
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003346:	4036d69b          	sraiw	a3,a3,0x3
    8000334a:	00d48633          	add	a2,s1,a3
    8000334e:	05864603          	lbu	a2,88(a2)
    80003352:	00c775b3          	and	a1,a4,a2
    80003356:	d599                	beqz	a1,80003264 <balloc+0x44>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003358:	2785                	addiw	a5,a5,1
    8000335a:	fd4797e3          	bne	a5,s4,80003328 <balloc+0x108>
    8000335e:	bf8d                	j	800032d0 <balloc+0xb0>
  panic("balloc: out of blocks");
    80003360:	00005517          	auipc	a0,0x5
    80003364:	22050513          	addi	a0,a0,544 # 80008580 <sysnames+0xc8>
    80003368:	ffffd097          	auipc	ra,0xffffd
    8000336c:	20c080e7          	jalr	524(ra) # 80000574 <panic>

0000000080003370 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003370:	7179                	addi	sp,sp,-48
    80003372:	f406                	sd	ra,40(sp)
    80003374:	f022                	sd	s0,32(sp)
    80003376:	ec26                	sd	s1,24(sp)
    80003378:	e84a                	sd	s2,16(sp)
    8000337a:	e44e                	sd	s3,8(sp)
    8000337c:	e052                	sd	s4,0(sp)
    8000337e:	1800                	addi	s0,sp,48
    80003380:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003382:	47ad                	li	a5,11
    80003384:	04b7fe63          	bleu	a1,a5,800033e0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003388:	ff45849b          	addiw	s1,a1,-12
    8000338c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003390:	0ff00793          	li	a5,255
    80003394:	0ae7e363          	bltu	a5,a4,8000343a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003398:	08052583          	lw	a1,128(a0)
    8000339c:	c5ad                	beqz	a1,80003406 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000339e:	0009a503          	lw	a0,0(s3)
    800033a2:	00000097          	auipc	ra,0x0
    800033a6:	b96080e7          	jalr	-1130(ra) # 80002f38 <bread>
    800033aa:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033ac:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033b0:	02049593          	slli	a1,s1,0x20
    800033b4:	9181                	srli	a1,a1,0x20
    800033b6:	058a                	slli	a1,a1,0x2
    800033b8:	00b784b3          	add	s1,a5,a1
    800033bc:	0004a903          	lw	s2,0(s1)
    800033c0:	04090d63          	beqz	s2,8000341a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033c4:	8552                	mv	a0,s4
    800033c6:	00000097          	auipc	ra,0x0
    800033ca:	cb4080e7          	jalr	-844(ra) # 8000307a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033ce:	854a                	mv	a0,s2
    800033d0:	70a2                	ld	ra,40(sp)
    800033d2:	7402                	ld	s0,32(sp)
    800033d4:	64e2                	ld	s1,24(sp)
    800033d6:	6942                	ld	s2,16(sp)
    800033d8:	69a2                	ld	s3,8(sp)
    800033da:	6a02                	ld	s4,0(sp)
    800033dc:	6145                	addi	sp,sp,48
    800033de:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033e0:	02059493          	slli	s1,a1,0x20
    800033e4:	9081                	srli	s1,s1,0x20
    800033e6:	048a                	slli	s1,s1,0x2
    800033e8:	94aa                	add	s1,s1,a0
    800033ea:	0504a903          	lw	s2,80(s1)
    800033ee:	fe0910e3          	bnez	s2,800033ce <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033f2:	4108                	lw	a0,0(a0)
    800033f4:	00000097          	auipc	ra,0x0
    800033f8:	e2c080e7          	jalr	-468(ra) # 80003220 <balloc>
    800033fc:	0005091b          	sext.w	s2,a0
    80003400:	0524a823          	sw	s2,80(s1)
    80003404:	b7e9                	j	800033ce <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003406:	4108                	lw	a0,0(a0)
    80003408:	00000097          	auipc	ra,0x0
    8000340c:	e18080e7          	jalr	-488(ra) # 80003220 <balloc>
    80003410:	0005059b          	sext.w	a1,a0
    80003414:	08b9a023          	sw	a1,128(s3)
    80003418:	b759                	j	8000339e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000341a:	0009a503          	lw	a0,0(s3)
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	e02080e7          	jalr	-510(ra) # 80003220 <balloc>
    80003426:	0005091b          	sext.w	s2,a0
    8000342a:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    8000342e:	8552                	mv	a0,s4
    80003430:	00001097          	auipc	ra,0x1
    80003434:	ef4080e7          	jalr	-268(ra) # 80004324 <log_write>
    80003438:	b771                	j	800033c4 <bmap+0x54>
  panic("bmap: out of range");
    8000343a:	00005517          	auipc	a0,0x5
    8000343e:	15e50513          	addi	a0,a0,350 # 80008598 <sysnames+0xe0>
    80003442:	ffffd097          	auipc	ra,0xffffd
    80003446:	132080e7          	jalr	306(ra) # 80000574 <panic>

000000008000344a <iget>:
{
    8000344a:	7179                	addi	sp,sp,-48
    8000344c:	f406                	sd	ra,40(sp)
    8000344e:	f022                	sd	s0,32(sp)
    80003450:	ec26                	sd	s1,24(sp)
    80003452:	e84a                	sd	s2,16(sp)
    80003454:	e44e                	sd	s3,8(sp)
    80003456:	e052                	sd	s4,0(sp)
    80003458:	1800                	addi	s0,sp,48
    8000345a:	89aa                	mv	s3,a0
    8000345c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000345e:	0001d517          	auipc	a0,0x1d
    80003462:	c0250513          	addi	a0,a0,-1022 # 80020060 <icache>
    80003466:	ffffd097          	auipc	ra,0xffffd
    8000346a:	7fc080e7          	jalr	2044(ra) # 80000c62 <acquire>
  empty = 0;
    8000346e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003470:	0001d497          	auipc	s1,0x1d
    80003474:	c0848493          	addi	s1,s1,-1016 # 80020078 <icache+0x18>
    80003478:	0001e697          	auipc	a3,0x1e
    8000347c:	69068693          	addi	a3,a3,1680 # 80021b08 <log>
    80003480:	a039                	j	8000348e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003482:	02090b63          	beqz	s2,800034b8 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003486:	08848493          	addi	s1,s1,136
    8000348a:	02d48a63          	beq	s1,a3,800034be <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000348e:	449c                	lw	a5,8(s1)
    80003490:	fef059e3          	blez	a5,80003482 <iget+0x38>
    80003494:	4098                	lw	a4,0(s1)
    80003496:	ff3716e3          	bne	a4,s3,80003482 <iget+0x38>
    8000349a:	40d8                	lw	a4,4(s1)
    8000349c:	ff4713e3          	bne	a4,s4,80003482 <iget+0x38>
      ip->ref++;
    800034a0:	2785                	addiw	a5,a5,1
    800034a2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034a4:	0001d517          	auipc	a0,0x1d
    800034a8:	bbc50513          	addi	a0,a0,-1092 # 80020060 <icache>
    800034ac:	ffffe097          	auipc	ra,0xffffe
    800034b0:	86a080e7          	jalr	-1942(ra) # 80000d16 <release>
      return ip;
    800034b4:	8926                	mv	s2,s1
    800034b6:	a03d                	j	800034e4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b8:	f7f9                	bnez	a5,80003486 <iget+0x3c>
    800034ba:	8926                	mv	s2,s1
    800034bc:	b7e9                	j	80003486 <iget+0x3c>
  if(empty == 0)
    800034be:	02090c63          	beqz	s2,800034f6 <iget+0xac>
  ip->dev = dev;
    800034c2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034c6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034ca:	4785                	li	a5,1
    800034cc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034d0:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034d4:	0001d517          	auipc	a0,0x1d
    800034d8:	b8c50513          	addi	a0,a0,-1140 # 80020060 <icache>
    800034dc:	ffffe097          	auipc	ra,0xffffe
    800034e0:	83a080e7          	jalr	-1990(ra) # 80000d16 <release>
}
    800034e4:	854a                	mv	a0,s2
    800034e6:	70a2                	ld	ra,40(sp)
    800034e8:	7402                	ld	s0,32(sp)
    800034ea:	64e2                	ld	s1,24(sp)
    800034ec:	6942                	ld	s2,16(sp)
    800034ee:	69a2                	ld	s3,8(sp)
    800034f0:	6a02                	ld	s4,0(sp)
    800034f2:	6145                	addi	sp,sp,48
    800034f4:	8082                	ret
    panic("iget: no inodes");
    800034f6:	00005517          	auipc	a0,0x5
    800034fa:	0ba50513          	addi	a0,a0,186 # 800085b0 <sysnames+0xf8>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	076080e7          	jalr	118(ra) # 80000574 <panic>

0000000080003506 <fsinit>:
fsinit(int dev) {
    80003506:	7179                	addi	sp,sp,-48
    80003508:	f406                	sd	ra,40(sp)
    8000350a:	f022                	sd	s0,32(sp)
    8000350c:	ec26                	sd	s1,24(sp)
    8000350e:	e84a                	sd	s2,16(sp)
    80003510:	e44e                	sd	s3,8(sp)
    80003512:	1800                	addi	s0,sp,48
    80003514:	89aa                	mv	s3,a0
  bp = bread(dev, 1);
    80003516:	4585                	li	a1,1
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	a20080e7          	jalr	-1504(ra) # 80002f38 <bread>
    80003520:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003522:	0001d497          	auipc	s1,0x1d
    80003526:	b1e48493          	addi	s1,s1,-1250 # 80020040 <sb>
    8000352a:	02000613          	li	a2,32
    8000352e:	05850593          	addi	a1,a0,88
    80003532:	8526                	mv	a0,s1
    80003534:	ffffe097          	auipc	ra,0xffffe
    80003538:	896080e7          	jalr	-1898(ra) # 80000dca <memmove>
  brelse(bp);
    8000353c:	854a                	mv	a0,s2
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	b3c080e7          	jalr	-1220(ra) # 8000307a <brelse>
  if(sb.magic != FSMAGIC)
    80003546:	4098                	lw	a4,0(s1)
    80003548:	102037b7          	lui	a5,0x10203
    8000354c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003550:	02f71263          	bne	a4,a5,80003574 <fsinit+0x6e>
  initlog(dev, &sb);
    80003554:	0001d597          	auipc	a1,0x1d
    80003558:	aec58593          	addi	a1,a1,-1300 # 80020040 <sb>
    8000355c:	854e                	mv	a0,s3
    8000355e:	00001097          	auipc	ra,0x1
    80003562:	b48080e7          	jalr	-1208(ra) # 800040a6 <initlog>
}
    80003566:	70a2                	ld	ra,40(sp)
    80003568:	7402                	ld	s0,32(sp)
    8000356a:	64e2                	ld	s1,24(sp)
    8000356c:	6942                	ld	s2,16(sp)
    8000356e:	69a2                	ld	s3,8(sp)
    80003570:	6145                	addi	sp,sp,48
    80003572:	8082                	ret
    panic("invalid file system");
    80003574:	00005517          	auipc	a0,0x5
    80003578:	04c50513          	addi	a0,a0,76 # 800085c0 <sysnames+0x108>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	ff8080e7          	jalr	-8(ra) # 80000574 <panic>

0000000080003584 <iinit>:
{
    80003584:	7179                	addi	sp,sp,-48
    80003586:	f406                	sd	ra,40(sp)
    80003588:	f022                	sd	s0,32(sp)
    8000358a:	ec26                	sd	s1,24(sp)
    8000358c:	e84a                	sd	s2,16(sp)
    8000358e:	e44e                	sd	s3,8(sp)
    80003590:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003592:	00005597          	auipc	a1,0x5
    80003596:	04658593          	addi	a1,a1,70 # 800085d8 <sysnames+0x120>
    8000359a:	0001d517          	auipc	a0,0x1d
    8000359e:	ac650513          	addi	a0,a0,-1338 # 80020060 <icache>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	630080e7          	jalr	1584(ra) # 80000bd2 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035aa:	0001d497          	auipc	s1,0x1d
    800035ae:	ade48493          	addi	s1,s1,-1314 # 80020088 <icache+0x28>
    800035b2:	0001e997          	auipc	s3,0x1e
    800035b6:	56698993          	addi	s3,s3,1382 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035ba:	00005917          	auipc	s2,0x5
    800035be:	02690913          	addi	s2,s2,38 # 800085e0 <sysnames+0x128>
    800035c2:	85ca                	mv	a1,s2
    800035c4:	8526                	mv	a0,s1
    800035c6:	00001097          	auipc	ra,0x1
    800035ca:	e62080e7          	jalr	-414(ra) # 80004428 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035ce:	08848493          	addi	s1,s1,136
    800035d2:	ff3498e3          	bne	s1,s3,800035c2 <iinit+0x3e>
}
    800035d6:	70a2                	ld	ra,40(sp)
    800035d8:	7402                	ld	s0,32(sp)
    800035da:	64e2                	ld	s1,24(sp)
    800035dc:	6942                	ld	s2,16(sp)
    800035de:	69a2                	ld	s3,8(sp)
    800035e0:	6145                	addi	sp,sp,48
    800035e2:	8082                	ret

00000000800035e4 <ialloc>:
{
    800035e4:	715d                	addi	sp,sp,-80
    800035e6:	e486                	sd	ra,72(sp)
    800035e8:	e0a2                	sd	s0,64(sp)
    800035ea:	fc26                	sd	s1,56(sp)
    800035ec:	f84a                	sd	s2,48(sp)
    800035ee:	f44e                	sd	s3,40(sp)
    800035f0:	f052                	sd	s4,32(sp)
    800035f2:	ec56                	sd	s5,24(sp)
    800035f4:	e85a                	sd	s6,16(sp)
    800035f6:	e45e                	sd	s7,8(sp)
    800035f8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035fa:	0001d797          	auipc	a5,0x1d
    800035fe:	a4678793          	addi	a5,a5,-1466 # 80020040 <sb>
    80003602:	47d8                	lw	a4,12(a5)
    80003604:	4785                	li	a5,1
    80003606:	04e7fa63          	bleu	a4,a5,8000365a <ialloc+0x76>
    8000360a:	8a2a                	mv	s4,a0
    8000360c:	8b2e                	mv	s6,a1
    8000360e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003610:	0001d997          	auipc	s3,0x1d
    80003614:	a3098993          	addi	s3,s3,-1488 # 80020040 <sb>
    80003618:	00048a9b          	sext.w	s5,s1
    8000361c:	0044d593          	srli	a1,s1,0x4
    80003620:	0189a783          	lw	a5,24(s3)
    80003624:	9dbd                	addw	a1,a1,a5
    80003626:	8552                	mv	a0,s4
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	910080e7          	jalr	-1776(ra) # 80002f38 <bread>
    80003630:	8baa                	mv	s7,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003632:	05850913          	addi	s2,a0,88
    80003636:	00f4f793          	andi	a5,s1,15
    8000363a:	079a                	slli	a5,a5,0x6
    8000363c:	993e                	add	s2,s2,a5
    if(dip->type == 0){  // a free inode
    8000363e:	00091783          	lh	a5,0(s2)
    80003642:	c785                	beqz	a5,8000366a <ialloc+0x86>
    brelse(bp);
    80003644:	00000097          	auipc	ra,0x0
    80003648:	a36080e7          	jalr	-1482(ra) # 8000307a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000364c:	0485                	addi	s1,s1,1
    8000364e:	00c9a703          	lw	a4,12(s3)
    80003652:	0004879b          	sext.w	a5,s1
    80003656:	fce7e1e3          	bltu	a5,a4,80003618 <ialloc+0x34>
  panic("ialloc: no inodes");
    8000365a:	00005517          	auipc	a0,0x5
    8000365e:	f8e50513          	addi	a0,a0,-114 # 800085e8 <sysnames+0x130>
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	f12080e7          	jalr	-238(ra) # 80000574 <panic>
      memset(dip, 0, sizeof(*dip));
    8000366a:	04000613          	li	a2,64
    8000366e:	4581                	li	a1,0
    80003670:	854a                	mv	a0,s2
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	6ec080e7          	jalr	1772(ra) # 80000d5e <memset>
      dip->type = type;
    8000367a:	01691023          	sh	s6,0(s2)
      log_write(bp);   // mark it allocated on the disk
    8000367e:	855e                	mv	a0,s7
    80003680:	00001097          	auipc	ra,0x1
    80003684:	ca4080e7          	jalr	-860(ra) # 80004324 <log_write>
      brelse(bp);
    80003688:	855e                	mv	a0,s7
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	9f0080e7          	jalr	-1552(ra) # 8000307a <brelse>
      return iget(dev, inum);
    80003692:	85d6                	mv	a1,s5
    80003694:	8552                	mv	a0,s4
    80003696:	00000097          	auipc	ra,0x0
    8000369a:	db4080e7          	jalr	-588(ra) # 8000344a <iget>
}
    8000369e:	60a6                	ld	ra,72(sp)
    800036a0:	6406                	ld	s0,64(sp)
    800036a2:	74e2                	ld	s1,56(sp)
    800036a4:	7942                	ld	s2,48(sp)
    800036a6:	79a2                	ld	s3,40(sp)
    800036a8:	7a02                	ld	s4,32(sp)
    800036aa:	6ae2                	ld	s5,24(sp)
    800036ac:	6b42                	ld	s6,16(sp)
    800036ae:	6ba2                	ld	s7,8(sp)
    800036b0:	6161                	addi	sp,sp,80
    800036b2:	8082                	ret

00000000800036b4 <iupdate>:
{
    800036b4:	1101                	addi	sp,sp,-32
    800036b6:	ec06                	sd	ra,24(sp)
    800036b8:	e822                	sd	s0,16(sp)
    800036ba:	e426                	sd	s1,8(sp)
    800036bc:	e04a                	sd	s2,0(sp)
    800036be:	1000                	addi	s0,sp,32
    800036c0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036c2:	415c                	lw	a5,4(a0)
    800036c4:	0047d79b          	srliw	a5,a5,0x4
    800036c8:	0001d717          	auipc	a4,0x1d
    800036cc:	97870713          	addi	a4,a4,-1672 # 80020040 <sb>
    800036d0:	4f0c                	lw	a1,24(a4)
    800036d2:	9dbd                	addw	a1,a1,a5
    800036d4:	4108                	lw	a0,0(a0)
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	862080e7          	jalr	-1950(ra) # 80002f38 <bread>
    800036de:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036e0:	05850513          	addi	a0,a0,88
    800036e4:	40dc                	lw	a5,4(s1)
    800036e6:	8bbd                	andi	a5,a5,15
    800036e8:	079a                	slli	a5,a5,0x6
    800036ea:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036ec:	04449783          	lh	a5,68(s1)
    800036f0:	00f51023          	sh	a5,0(a0)
  dip->major = ip->major;
    800036f4:	04649783          	lh	a5,70(s1)
    800036f8:	00f51123          	sh	a5,2(a0)
  dip->minor = ip->minor;
    800036fc:	04849783          	lh	a5,72(s1)
    80003700:	00f51223          	sh	a5,4(a0)
  dip->nlink = ip->nlink;
    80003704:	04a49783          	lh	a5,74(s1)
    80003708:	00f51323          	sh	a5,6(a0)
  dip->size = ip->size;
    8000370c:	44fc                	lw	a5,76(s1)
    8000370e:	c51c                	sw	a5,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003710:	03400613          	li	a2,52
    80003714:	05048593          	addi	a1,s1,80
    80003718:	0531                	addi	a0,a0,12
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	6b0080e7          	jalr	1712(ra) # 80000dca <memmove>
  log_write(bp);
    80003722:	854a                	mv	a0,s2
    80003724:	00001097          	auipc	ra,0x1
    80003728:	c00080e7          	jalr	-1024(ra) # 80004324 <log_write>
  brelse(bp);
    8000372c:	854a                	mv	a0,s2
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	94c080e7          	jalr	-1716(ra) # 8000307a <brelse>
}
    80003736:	60e2                	ld	ra,24(sp)
    80003738:	6442                	ld	s0,16(sp)
    8000373a:	64a2                	ld	s1,8(sp)
    8000373c:	6902                	ld	s2,0(sp)
    8000373e:	6105                	addi	sp,sp,32
    80003740:	8082                	ret

0000000080003742 <idup>:
{
    80003742:	1101                	addi	sp,sp,-32
    80003744:	ec06                	sd	ra,24(sp)
    80003746:	e822                	sd	s0,16(sp)
    80003748:	e426                	sd	s1,8(sp)
    8000374a:	1000                	addi	s0,sp,32
    8000374c:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000374e:	0001d517          	auipc	a0,0x1d
    80003752:	91250513          	addi	a0,a0,-1774 # 80020060 <icache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	50c080e7          	jalr	1292(ra) # 80000c62 <acquire>
  ip->ref++;
    8000375e:	449c                	lw	a5,8(s1)
    80003760:	2785                	addiw	a5,a5,1
    80003762:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003764:	0001d517          	auipc	a0,0x1d
    80003768:	8fc50513          	addi	a0,a0,-1796 # 80020060 <icache>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	5aa080e7          	jalr	1450(ra) # 80000d16 <release>
}
    80003774:	8526                	mv	a0,s1
    80003776:	60e2                	ld	ra,24(sp)
    80003778:	6442                	ld	s0,16(sp)
    8000377a:	64a2                	ld	s1,8(sp)
    8000377c:	6105                	addi	sp,sp,32
    8000377e:	8082                	ret

0000000080003780 <ilock>:
{
    80003780:	1101                	addi	sp,sp,-32
    80003782:	ec06                	sd	ra,24(sp)
    80003784:	e822                	sd	s0,16(sp)
    80003786:	e426                	sd	s1,8(sp)
    80003788:	e04a                	sd	s2,0(sp)
    8000378a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000378c:	c115                	beqz	a0,800037b0 <ilock+0x30>
    8000378e:	84aa                	mv	s1,a0
    80003790:	451c                	lw	a5,8(a0)
    80003792:	00f05f63          	blez	a5,800037b0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003796:	0541                	addi	a0,a0,16
    80003798:	00001097          	auipc	ra,0x1
    8000379c:	cca080e7          	jalr	-822(ra) # 80004462 <acquiresleep>
  if(ip->valid == 0){
    800037a0:	40bc                	lw	a5,64(s1)
    800037a2:	cf99                	beqz	a5,800037c0 <ilock+0x40>
}
    800037a4:	60e2                	ld	ra,24(sp)
    800037a6:	6442                	ld	s0,16(sp)
    800037a8:	64a2                	ld	s1,8(sp)
    800037aa:	6902                	ld	s2,0(sp)
    800037ac:	6105                	addi	sp,sp,32
    800037ae:	8082                	ret
    panic("ilock");
    800037b0:	00005517          	auipc	a0,0x5
    800037b4:	e5050513          	addi	a0,a0,-432 # 80008600 <sysnames+0x148>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	dbc080e7          	jalr	-580(ra) # 80000574 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037c0:	40dc                	lw	a5,4(s1)
    800037c2:	0047d79b          	srliw	a5,a5,0x4
    800037c6:	0001d717          	auipc	a4,0x1d
    800037ca:	87a70713          	addi	a4,a4,-1926 # 80020040 <sb>
    800037ce:	4f0c                	lw	a1,24(a4)
    800037d0:	9dbd                	addw	a1,a1,a5
    800037d2:	4088                	lw	a0,0(s1)
    800037d4:	fffff097          	auipc	ra,0xfffff
    800037d8:	764080e7          	jalr	1892(ra) # 80002f38 <bread>
    800037dc:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037de:	05850593          	addi	a1,a0,88
    800037e2:	40dc                	lw	a5,4(s1)
    800037e4:	8bbd                	andi	a5,a5,15
    800037e6:	079a                	slli	a5,a5,0x6
    800037e8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037ea:	00059783          	lh	a5,0(a1)
    800037ee:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037f2:	00259783          	lh	a5,2(a1)
    800037f6:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037fa:	00459783          	lh	a5,4(a1)
    800037fe:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003802:	00659783          	lh	a5,6(a1)
    80003806:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000380a:	459c                	lw	a5,8(a1)
    8000380c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000380e:	03400613          	li	a2,52
    80003812:	05b1                	addi	a1,a1,12
    80003814:	05048513          	addi	a0,s1,80
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	5b2080e7          	jalr	1458(ra) # 80000dca <memmove>
    brelse(bp);
    80003820:	854a                	mv	a0,s2
    80003822:	00000097          	auipc	ra,0x0
    80003826:	858080e7          	jalr	-1960(ra) # 8000307a <brelse>
    ip->valid = 1;
    8000382a:	4785                	li	a5,1
    8000382c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000382e:	04449783          	lh	a5,68(s1)
    80003832:	fbad                	bnez	a5,800037a4 <ilock+0x24>
      panic("ilock: no type");
    80003834:	00005517          	auipc	a0,0x5
    80003838:	dd450513          	addi	a0,a0,-556 # 80008608 <sysnames+0x150>
    8000383c:	ffffd097          	auipc	ra,0xffffd
    80003840:	d38080e7          	jalr	-712(ra) # 80000574 <panic>

0000000080003844 <iunlock>:
{
    80003844:	1101                	addi	sp,sp,-32
    80003846:	ec06                	sd	ra,24(sp)
    80003848:	e822                	sd	s0,16(sp)
    8000384a:	e426                	sd	s1,8(sp)
    8000384c:	e04a                	sd	s2,0(sp)
    8000384e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003850:	c905                	beqz	a0,80003880 <iunlock+0x3c>
    80003852:	84aa                	mv	s1,a0
    80003854:	01050913          	addi	s2,a0,16
    80003858:	854a                	mv	a0,s2
    8000385a:	00001097          	auipc	ra,0x1
    8000385e:	ca2080e7          	jalr	-862(ra) # 800044fc <holdingsleep>
    80003862:	cd19                	beqz	a0,80003880 <iunlock+0x3c>
    80003864:	449c                	lw	a5,8(s1)
    80003866:	00f05d63          	blez	a5,80003880 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000386a:	854a                	mv	a0,s2
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	c4c080e7          	jalr	-948(ra) # 800044b8 <releasesleep>
}
    80003874:	60e2                	ld	ra,24(sp)
    80003876:	6442                	ld	s0,16(sp)
    80003878:	64a2                	ld	s1,8(sp)
    8000387a:	6902                	ld	s2,0(sp)
    8000387c:	6105                	addi	sp,sp,32
    8000387e:	8082                	ret
    panic("iunlock");
    80003880:	00005517          	auipc	a0,0x5
    80003884:	d9850513          	addi	a0,a0,-616 # 80008618 <sysnames+0x160>
    80003888:	ffffd097          	auipc	ra,0xffffd
    8000388c:	cec080e7          	jalr	-788(ra) # 80000574 <panic>

0000000080003890 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003890:	7179                	addi	sp,sp,-48
    80003892:	f406                	sd	ra,40(sp)
    80003894:	f022                	sd	s0,32(sp)
    80003896:	ec26                	sd	s1,24(sp)
    80003898:	e84a                	sd	s2,16(sp)
    8000389a:	e44e                	sd	s3,8(sp)
    8000389c:	e052                	sd	s4,0(sp)
    8000389e:	1800                	addi	s0,sp,48
    800038a0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038a2:	05050493          	addi	s1,a0,80
    800038a6:	08050913          	addi	s2,a0,128
    800038aa:	a821                	j	800038c2 <itrunc+0x32>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    800038ac:	0009a503          	lw	a0,0(s3)
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	8e0080e7          	jalr	-1824(ra) # 80003190 <bfree>
      ip->addrs[i] = 0;
    800038b8:	0004a023          	sw	zero,0(s1)
  for(i = 0; i < NDIRECT; i++){
    800038bc:	0491                	addi	s1,s1,4
    800038be:	01248563          	beq	s1,s2,800038c8 <itrunc+0x38>
    if(ip->addrs[i]){
    800038c2:	408c                	lw	a1,0(s1)
    800038c4:	dde5                	beqz	a1,800038bc <itrunc+0x2c>
    800038c6:	b7dd                	j	800038ac <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038c8:	0809a583          	lw	a1,128(s3)
    800038cc:	e185                	bnez	a1,800038ec <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038ce:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038d2:	854e                	mv	a0,s3
    800038d4:	00000097          	auipc	ra,0x0
    800038d8:	de0080e7          	jalr	-544(ra) # 800036b4 <iupdate>
}
    800038dc:	70a2                	ld	ra,40(sp)
    800038de:	7402                	ld	s0,32(sp)
    800038e0:	64e2                	ld	s1,24(sp)
    800038e2:	6942                	ld	s2,16(sp)
    800038e4:	69a2                	ld	s3,8(sp)
    800038e6:	6a02                	ld	s4,0(sp)
    800038e8:	6145                	addi	sp,sp,48
    800038ea:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038ec:	0009a503          	lw	a0,0(s3)
    800038f0:	fffff097          	auipc	ra,0xfffff
    800038f4:	648080e7          	jalr	1608(ra) # 80002f38 <bread>
    800038f8:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038fa:	05850493          	addi	s1,a0,88
    800038fe:	45850913          	addi	s2,a0,1112
    80003902:	a811                	j	80003916 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003904:	0009a503          	lw	a0,0(s3)
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	888080e7          	jalr	-1912(ra) # 80003190 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003910:	0491                	addi	s1,s1,4
    80003912:	01248563          	beq	s1,s2,8000391c <itrunc+0x8c>
      if(a[j])
    80003916:	408c                	lw	a1,0(s1)
    80003918:	dde5                	beqz	a1,80003910 <itrunc+0x80>
    8000391a:	b7ed                	j	80003904 <itrunc+0x74>
    brelse(bp);
    8000391c:	8552                	mv	a0,s4
    8000391e:	fffff097          	auipc	ra,0xfffff
    80003922:	75c080e7          	jalr	1884(ra) # 8000307a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003926:	0809a583          	lw	a1,128(s3)
    8000392a:	0009a503          	lw	a0,0(s3)
    8000392e:	00000097          	auipc	ra,0x0
    80003932:	862080e7          	jalr	-1950(ra) # 80003190 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003936:	0809a023          	sw	zero,128(s3)
    8000393a:	bf51                	j	800038ce <itrunc+0x3e>

000000008000393c <iput>:
{
    8000393c:	1101                	addi	sp,sp,-32
    8000393e:	ec06                	sd	ra,24(sp)
    80003940:	e822                	sd	s0,16(sp)
    80003942:	e426                	sd	s1,8(sp)
    80003944:	e04a                	sd	s2,0(sp)
    80003946:	1000                	addi	s0,sp,32
    80003948:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000394a:	0001c517          	auipc	a0,0x1c
    8000394e:	71650513          	addi	a0,a0,1814 # 80020060 <icache>
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	310080e7          	jalr	784(ra) # 80000c62 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000395a:	4498                	lw	a4,8(s1)
    8000395c:	4785                	li	a5,1
    8000395e:	02f70363          	beq	a4,a5,80003984 <iput+0x48>
  ip->ref--;
    80003962:	449c                	lw	a5,8(s1)
    80003964:	37fd                	addiw	a5,a5,-1
    80003966:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003968:	0001c517          	auipc	a0,0x1c
    8000396c:	6f850513          	addi	a0,a0,1784 # 80020060 <icache>
    80003970:	ffffd097          	auipc	ra,0xffffd
    80003974:	3a6080e7          	jalr	934(ra) # 80000d16 <release>
}
    80003978:	60e2                	ld	ra,24(sp)
    8000397a:	6442                	ld	s0,16(sp)
    8000397c:	64a2                	ld	s1,8(sp)
    8000397e:	6902                	ld	s2,0(sp)
    80003980:	6105                	addi	sp,sp,32
    80003982:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003984:	40bc                	lw	a5,64(s1)
    80003986:	dff1                	beqz	a5,80003962 <iput+0x26>
    80003988:	04a49783          	lh	a5,74(s1)
    8000398c:	fbf9                	bnez	a5,80003962 <iput+0x26>
    acquiresleep(&ip->lock);
    8000398e:	01048913          	addi	s2,s1,16
    80003992:	854a                	mv	a0,s2
    80003994:	00001097          	auipc	ra,0x1
    80003998:	ace080e7          	jalr	-1330(ra) # 80004462 <acquiresleep>
    release(&icache.lock);
    8000399c:	0001c517          	auipc	a0,0x1c
    800039a0:	6c450513          	addi	a0,a0,1732 # 80020060 <icache>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	372080e7          	jalr	882(ra) # 80000d16 <release>
    itrunc(ip);
    800039ac:	8526                	mv	a0,s1
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	ee2080e7          	jalr	-286(ra) # 80003890 <itrunc>
    ip->type = 0;
    800039b6:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039ba:	8526                	mv	a0,s1
    800039bc:	00000097          	auipc	ra,0x0
    800039c0:	cf8080e7          	jalr	-776(ra) # 800036b4 <iupdate>
    ip->valid = 0;
    800039c4:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039c8:	854a                	mv	a0,s2
    800039ca:	00001097          	auipc	ra,0x1
    800039ce:	aee080e7          	jalr	-1298(ra) # 800044b8 <releasesleep>
    acquire(&icache.lock);
    800039d2:	0001c517          	auipc	a0,0x1c
    800039d6:	68e50513          	addi	a0,a0,1678 # 80020060 <icache>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	288080e7          	jalr	648(ra) # 80000c62 <acquire>
    800039e2:	b741                	j	80003962 <iput+0x26>

00000000800039e4 <iunlockput>:
{
    800039e4:	1101                	addi	sp,sp,-32
    800039e6:	ec06                	sd	ra,24(sp)
    800039e8:	e822                	sd	s0,16(sp)
    800039ea:	e426                	sd	s1,8(sp)
    800039ec:	1000                	addi	s0,sp,32
    800039ee:	84aa                	mv	s1,a0
  iunlock(ip);
    800039f0:	00000097          	auipc	ra,0x0
    800039f4:	e54080e7          	jalr	-428(ra) # 80003844 <iunlock>
  iput(ip);
    800039f8:	8526                	mv	a0,s1
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	f42080e7          	jalr	-190(ra) # 8000393c <iput>
}
    80003a02:	60e2                	ld	ra,24(sp)
    80003a04:	6442                	ld	s0,16(sp)
    80003a06:	64a2                	ld	s1,8(sp)
    80003a08:	6105                	addi	sp,sp,32
    80003a0a:	8082                	ret

0000000080003a0c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a0c:	1141                	addi	sp,sp,-16
    80003a0e:	e422                	sd	s0,8(sp)
    80003a10:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a12:	411c                	lw	a5,0(a0)
    80003a14:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a16:	415c                	lw	a5,4(a0)
    80003a18:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a1a:	04451783          	lh	a5,68(a0)
    80003a1e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a22:	04a51783          	lh	a5,74(a0)
    80003a26:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a2a:	04c56783          	lwu	a5,76(a0)
    80003a2e:	e99c                	sd	a5,16(a1)
}
    80003a30:	6422                	ld	s0,8(sp)
    80003a32:	0141                	addi	sp,sp,16
    80003a34:	8082                	ret

0000000080003a36 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a36:	457c                	lw	a5,76(a0)
    80003a38:	0ed7e863          	bltu	a5,a3,80003b28 <readi+0xf2>
{
    80003a3c:	7159                	addi	sp,sp,-112
    80003a3e:	f486                	sd	ra,104(sp)
    80003a40:	f0a2                	sd	s0,96(sp)
    80003a42:	eca6                	sd	s1,88(sp)
    80003a44:	e8ca                	sd	s2,80(sp)
    80003a46:	e4ce                	sd	s3,72(sp)
    80003a48:	e0d2                	sd	s4,64(sp)
    80003a4a:	fc56                	sd	s5,56(sp)
    80003a4c:	f85a                	sd	s6,48(sp)
    80003a4e:	f45e                	sd	s7,40(sp)
    80003a50:	f062                	sd	s8,32(sp)
    80003a52:	ec66                	sd	s9,24(sp)
    80003a54:	e86a                	sd	s10,16(sp)
    80003a56:	e46e                	sd	s11,8(sp)
    80003a58:	1880                	addi	s0,sp,112
    80003a5a:	8baa                	mv	s7,a0
    80003a5c:	8c2e                	mv	s8,a1
    80003a5e:	8a32                	mv	s4,a2
    80003a60:	84b6                	mv	s1,a3
    80003a62:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a64:	9f35                	addw	a4,a4,a3
    return 0;
    80003a66:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a68:	08d76f63          	bltu	a4,a3,80003b06 <readi+0xd0>
  if(off + n > ip->size)
    80003a6c:	00e7f463          	bleu	a4,a5,80003a74 <readi+0x3e>
    n = ip->size - off;
    80003a70:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a74:	0a0b0863          	beqz	s6,80003b24 <readi+0xee>
    80003a78:	4901                	li	s2,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a7a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a7e:	5cfd                	li	s9,-1
    80003a80:	a82d                	j	80003aba <readi+0x84>
    80003a82:	02099d93          	slli	s11,s3,0x20
    80003a86:	020ddd93          	srli	s11,s11,0x20
    80003a8a:	058a8613          	addi	a2,s5,88
    80003a8e:	86ee                	mv	a3,s11
    80003a90:	963a                	add	a2,a2,a4
    80003a92:	85d2                	mv	a1,s4
    80003a94:	8562                	mv	a0,s8
    80003a96:	fffff097          	auipc	ra,0xfffff
    80003a9a:	a5e080e7          	jalr	-1442(ra) # 800024f4 <either_copyout>
    80003a9e:	05950d63          	beq	a0,s9,80003af8 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003aa2:	8556                	mv	a0,s5
    80003aa4:	fffff097          	auipc	ra,0xfffff
    80003aa8:	5d6080e7          	jalr	1494(ra) # 8000307a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aac:	0129893b          	addw	s2,s3,s2
    80003ab0:	009984bb          	addw	s1,s3,s1
    80003ab4:	9a6e                	add	s4,s4,s11
    80003ab6:	05697663          	bleu	s6,s2,80003b02 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aba:	000ba983          	lw	s3,0(s7)
    80003abe:	00a4d59b          	srliw	a1,s1,0xa
    80003ac2:	855e                	mv	a0,s7
    80003ac4:	00000097          	auipc	ra,0x0
    80003ac8:	8ac080e7          	jalr	-1876(ra) # 80003370 <bmap>
    80003acc:	0005059b          	sext.w	a1,a0
    80003ad0:	854e                	mv	a0,s3
    80003ad2:	fffff097          	auipc	ra,0xfffff
    80003ad6:	466080e7          	jalr	1126(ra) # 80002f38 <bread>
    80003ada:	8aaa                	mv	s5,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003adc:	3ff4f713          	andi	a4,s1,1023
    80003ae0:	40ed07bb          	subw	a5,s10,a4
    80003ae4:	412b06bb          	subw	a3,s6,s2
    80003ae8:	89be                	mv	s3,a5
    80003aea:	2781                	sext.w	a5,a5
    80003aec:	0006861b          	sext.w	a2,a3
    80003af0:	f8f679e3          	bleu	a5,a2,80003a82 <readi+0x4c>
    80003af4:	89b6                	mv	s3,a3
    80003af6:	b771                	j	80003a82 <readi+0x4c>
      brelse(bp);
    80003af8:	8556                	mv	a0,s5
    80003afa:	fffff097          	auipc	ra,0xfffff
    80003afe:	580080e7          	jalr	1408(ra) # 8000307a <brelse>
  }
  return tot;
    80003b02:	0009051b          	sext.w	a0,s2
}
    80003b06:	70a6                	ld	ra,104(sp)
    80003b08:	7406                	ld	s0,96(sp)
    80003b0a:	64e6                	ld	s1,88(sp)
    80003b0c:	6946                	ld	s2,80(sp)
    80003b0e:	69a6                	ld	s3,72(sp)
    80003b10:	6a06                	ld	s4,64(sp)
    80003b12:	7ae2                	ld	s5,56(sp)
    80003b14:	7b42                	ld	s6,48(sp)
    80003b16:	7ba2                	ld	s7,40(sp)
    80003b18:	7c02                	ld	s8,32(sp)
    80003b1a:	6ce2                	ld	s9,24(sp)
    80003b1c:	6d42                	ld	s10,16(sp)
    80003b1e:	6da2                	ld	s11,8(sp)
    80003b20:	6165                	addi	sp,sp,112
    80003b22:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b24:	895a                	mv	s2,s6
    80003b26:	bff1                	j	80003b02 <readi+0xcc>
    return 0;
    80003b28:	4501                	li	a0,0
}
    80003b2a:	8082                	ret

0000000080003b2c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b2c:	457c                	lw	a5,76(a0)
    80003b2e:	10d7e663          	bltu	a5,a3,80003c3a <writei+0x10e>
{
    80003b32:	7159                	addi	sp,sp,-112
    80003b34:	f486                	sd	ra,104(sp)
    80003b36:	f0a2                	sd	s0,96(sp)
    80003b38:	eca6                	sd	s1,88(sp)
    80003b3a:	e8ca                	sd	s2,80(sp)
    80003b3c:	e4ce                	sd	s3,72(sp)
    80003b3e:	e0d2                	sd	s4,64(sp)
    80003b40:	fc56                	sd	s5,56(sp)
    80003b42:	f85a                	sd	s6,48(sp)
    80003b44:	f45e                	sd	s7,40(sp)
    80003b46:	f062                	sd	s8,32(sp)
    80003b48:	ec66                	sd	s9,24(sp)
    80003b4a:	e86a                	sd	s10,16(sp)
    80003b4c:	e46e                	sd	s11,8(sp)
    80003b4e:	1880                	addi	s0,sp,112
    80003b50:	8baa                	mv	s7,a0
    80003b52:	8c2e                	mv	s8,a1
    80003b54:	8ab2                	mv	s5,a2
    80003b56:	84b6                	mv	s1,a3
    80003b58:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b5a:	00e687bb          	addw	a5,a3,a4
    80003b5e:	0ed7e063          	bltu	a5,a3,80003c3e <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b62:	00043737          	lui	a4,0x43
    80003b66:	0cf76e63          	bltu	a4,a5,80003c42 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b6a:	0a0b0763          	beqz	s6,80003c18 <writei+0xec>
    80003b6e:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b70:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b74:	5cfd                	li	s9,-1
    80003b76:	a091                	j	80003bba <writei+0x8e>
    80003b78:	02091d93          	slli	s11,s2,0x20
    80003b7c:	020ddd93          	srli	s11,s11,0x20
    80003b80:	05898513          	addi	a0,s3,88
    80003b84:	86ee                	mv	a3,s11
    80003b86:	8656                	mv	a2,s5
    80003b88:	85e2                	mv	a1,s8
    80003b8a:	953a                	add	a0,a0,a4
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	9be080e7          	jalr	-1602(ra) # 8000254a <either_copyin>
    80003b94:	07950263          	beq	a0,s9,80003bf8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b98:	854e                	mv	a0,s3
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	78a080e7          	jalr	1930(ra) # 80004324 <log_write>
    brelse(bp);
    80003ba2:	854e                	mv	a0,s3
    80003ba4:	fffff097          	auipc	ra,0xfffff
    80003ba8:	4d6080e7          	jalr	1238(ra) # 8000307a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bac:	01490a3b          	addw	s4,s2,s4
    80003bb0:	009904bb          	addw	s1,s2,s1
    80003bb4:	9aee                	add	s5,s5,s11
    80003bb6:	056a7663          	bleu	s6,s4,80003c02 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bba:	000ba903          	lw	s2,0(s7)
    80003bbe:	00a4d59b          	srliw	a1,s1,0xa
    80003bc2:	855e                	mv	a0,s7
    80003bc4:	fffff097          	auipc	ra,0xfffff
    80003bc8:	7ac080e7          	jalr	1964(ra) # 80003370 <bmap>
    80003bcc:	0005059b          	sext.w	a1,a0
    80003bd0:	854a                	mv	a0,s2
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	366080e7          	jalr	870(ra) # 80002f38 <bread>
    80003bda:	89aa                	mv	s3,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bdc:	3ff4f713          	andi	a4,s1,1023
    80003be0:	40ed07bb          	subw	a5,s10,a4
    80003be4:	414b06bb          	subw	a3,s6,s4
    80003be8:	893e                	mv	s2,a5
    80003bea:	2781                	sext.w	a5,a5
    80003bec:	0006861b          	sext.w	a2,a3
    80003bf0:	f8f674e3          	bleu	a5,a2,80003b78 <writei+0x4c>
    80003bf4:	8936                	mv	s2,a3
    80003bf6:	b749                	j	80003b78 <writei+0x4c>
      brelse(bp);
    80003bf8:	854e                	mv	a0,s3
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	480080e7          	jalr	1152(ra) # 8000307a <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003c02:	04cba783          	lw	a5,76(s7)
    80003c06:	0097f463          	bleu	s1,a5,80003c0e <writei+0xe2>
      ip->size = off;
    80003c0a:	049ba623          	sw	s1,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c0e:	855e                	mv	a0,s7
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	aa4080e7          	jalr	-1372(ra) # 800036b4 <iupdate>
  }

  return n;
    80003c18:	000b051b          	sext.w	a0,s6
}
    80003c1c:	70a6                	ld	ra,104(sp)
    80003c1e:	7406                	ld	s0,96(sp)
    80003c20:	64e6                	ld	s1,88(sp)
    80003c22:	6946                	ld	s2,80(sp)
    80003c24:	69a6                	ld	s3,72(sp)
    80003c26:	6a06                	ld	s4,64(sp)
    80003c28:	7ae2                	ld	s5,56(sp)
    80003c2a:	7b42                	ld	s6,48(sp)
    80003c2c:	7ba2                	ld	s7,40(sp)
    80003c2e:	7c02                	ld	s8,32(sp)
    80003c30:	6ce2                	ld	s9,24(sp)
    80003c32:	6d42                	ld	s10,16(sp)
    80003c34:	6da2                	ld	s11,8(sp)
    80003c36:	6165                	addi	sp,sp,112
    80003c38:	8082                	ret
    return -1;
    80003c3a:	557d                	li	a0,-1
}
    80003c3c:	8082                	ret
    return -1;
    80003c3e:	557d                	li	a0,-1
    80003c40:	bff1                	j	80003c1c <writei+0xf0>
    return -1;
    80003c42:	557d                	li	a0,-1
    80003c44:	bfe1                	j	80003c1c <writei+0xf0>

0000000080003c46 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c46:	1141                	addi	sp,sp,-16
    80003c48:	e406                	sd	ra,8(sp)
    80003c4a:	e022                	sd	s0,0(sp)
    80003c4c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c4e:	4639                	li	a2,14
    80003c50:	ffffd097          	auipc	ra,0xffffd
    80003c54:	1f6080e7          	jalr	502(ra) # 80000e46 <strncmp>
}
    80003c58:	60a2                	ld	ra,8(sp)
    80003c5a:	6402                	ld	s0,0(sp)
    80003c5c:	0141                	addi	sp,sp,16
    80003c5e:	8082                	ret

0000000080003c60 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c60:	7139                	addi	sp,sp,-64
    80003c62:	fc06                	sd	ra,56(sp)
    80003c64:	f822                	sd	s0,48(sp)
    80003c66:	f426                	sd	s1,40(sp)
    80003c68:	f04a                	sd	s2,32(sp)
    80003c6a:	ec4e                	sd	s3,24(sp)
    80003c6c:	e852                	sd	s4,16(sp)
    80003c6e:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c70:	04451703          	lh	a4,68(a0)
    80003c74:	4785                	li	a5,1
    80003c76:	00f71a63          	bne	a4,a5,80003c8a <dirlookup+0x2a>
    80003c7a:	892a                	mv	s2,a0
    80003c7c:	89ae                	mv	s3,a1
    80003c7e:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c80:	457c                	lw	a5,76(a0)
    80003c82:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c84:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c86:	e79d                	bnez	a5,80003cb4 <dirlookup+0x54>
    80003c88:	a8a5                	j	80003d00 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c8a:	00005517          	auipc	a0,0x5
    80003c8e:	99650513          	addi	a0,a0,-1642 # 80008620 <sysnames+0x168>
    80003c92:	ffffd097          	auipc	ra,0xffffd
    80003c96:	8e2080e7          	jalr	-1822(ra) # 80000574 <panic>
      panic("dirlookup read");
    80003c9a:	00005517          	auipc	a0,0x5
    80003c9e:	99e50513          	addi	a0,a0,-1634 # 80008638 <sysnames+0x180>
    80003ca2:	ffffd097          	auipc	ra,0xffffd
    80003ca6:	8d2080e7          	jalr	-1838(ra) # 80000574 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003caa:	24c1                	addiw	s1,s1,16
    80003cac:	04c92783          	lw	a5,76(s2)
    80003cb0:	04f4f763          	bleu	a5,s1,80003cfe <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cb4:	4741                	li	a4,16
    80003cb6:	86a6                	mv	a3,s1
    80003cb8:	fc040613          	addi	a2,s0,-64
    80003cbc:	4581                	li	a1,0
    80003cbe:	854a                	mv	a0,s2
    80003cc0:	00000097          	auipc	ra,0x0
    80003cc4:	d76080e7          	jalr	-650(ra) # 80003a36 <readi>
    80003cc8:	47c1                	li	a5,16
    80003cca:	fcf518e3          	bne	a0,a5,80003c9a <dirlookup+0x3a>
    if(de.inum == 0)
    80003cce:	fc045783          	lhu	a5,-64(s0)
    80003cd2:	dfe1                	beqz	a5,80003caa <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cd4:	fc240593          	addi	a1,s0,-62
    80003cd8:	854e                	mv	a0,s3
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	f6c080e7          	jalr	-148(ra) # 80003c46 <namecmp>
    80003ce2:	f561                	bnez	a0,80003caa <dirlookup+0x4a>
      if(poff)
    80003ce4:	000a0463          	beqz	s4,80003cec <dirlookup+0x8c>
        *poff = off;
    80003ce8:	009a2023          	sw	s1,0(s4) # 2000 <_entry-0x7fffe000>
      return iget(dp->dev, inum);
    80003cec:	fc045583          	lhu	a1,-64(s0)
    80003cf0:	00092503          	lw	a0,0(s2)
    80003cf4:	fffff097          	auipc	ra,0xfffff
    80003cf8:	756080e7          	jalr	1878(ra) # 8000344a <iget>
    80003cfc:	a011                	j	80003d00 <dirlookup+0xa0>
  return 0;
    80003cfe:	4501                	li	a0,0
}
    80003d00:	70e2                	ld	ra,56(sp)
    80003d02:	7442                	ld	s0,48(sp)
    80003d04:	74a2                	ld	s1,40(sp)
    80003d06:	7902                	ld	s2,32(sp)
    80003d08:	69e2                	ld	s3,24(sp)
    80003d0a:	6a42                	ld	s4,16(sp)
    80003d0c:	6121                	addi	sp,sp,64
    80003d0e:	8082                	ret

0000000080003d10 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d10:	711d                	addi	sp,sp,-96
    80003d12:	ec86                	sd	ra,88(sp)
    80003d14:	e8a2                	sd	s0,80(sp)
    80003d16:	e4a6                	sd	s1,72(sp)
    80003d18:	e0ca                	sd	s2,64(sp)
    80003d1a:	fc4e                	sd	s3,56(sp)
    80003d1c:	f852                	sd	s4,48(sp)
    80003d1e:	f456                	sd	s5,40(sp)
    80003d20:	f05a                	sd	s6,32(sp)
    80003d22:	ec5e                	sd	s7,24(sp)
    80003d24:	e862                	sd	s8,16(sp)
    80003d26:	e466                	sd	s9,8(sp)
    80003d28:	1080                	addi	s0,sp,96
    80003d2a:	84aa                	mv	s1,a0
    80003d2c:	8bae                	mv	s7,a1
    80003d2e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d30:	00054703          	lbu	a4,0(a0)
    80003d34:	02f00793          	li	a5,47
    80003d38:	02f70363          	beq	a4,a5,80003d5e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d3c:	ffffe097          	auipc	ra,0xffffe
    80003d40:	d34080e7          	jalr	-716(ra) # 80001a70 <myproc>
    80003d44:	15053503          	ld	a0,336(a0)
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	9fa080e7          	jalr	-1542(ra) # 80003742 <idup>
    80003d50:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d52:	02f00913          	li	s2,47
  len = path - s;
    80003d56:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d58:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d5a:	4c05                	li	s8,1
    80003d5c:	a865                	j	80003e14 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d5e:	4585                	li	a1,1
    80003d60:	4505                	li	a0,1
    80003d62:	fffff097          	auipc	ra,0xfffff
    80003d66:	6e8080e7          	jalr	1768(ra) # 8000344a <iget>
    80003d6a:	89aa                	mv	s3,a0
    80003d6c:	b7dd                	j	80003d52 <namex+0x42>
      iunlockput(ip);
    80003d6e:	854e                	mv	a0,s3
    80003d70:	00000097          	auipc	ra,0x0
    80003d74:	c74080e7          	jalr	-908(ra) # 800039e4 <iunlockput>
      return 0;
    80003d78:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d7a:	854e                	mv	a0,s3
    80003d7c:	60e6                	ld	ra,88(sp)
    80003d7e:	6446                	ld	s0,80(sp)
    80003d80:	64a6                	ld	s1,72(sp)
    80003d82:	6906                	ld	s2,64(sp)
    80003d84:	79e2                	ld	s3,56(sp)
    80003d86:	7a42                	ld	s4,48(sp)
    80003d88:	7aa2                	ld	s5,40(sp)
    80003d8a:	7b02                	ld	s6,32(sp)
    80003d8c:	6be2                	ld	s7,24(sp)
    80003d8e:	6c42                	ld	s8,16(sp)
    80003d90:	6ca2                	ld	s9,8(sp)
    80003d92:	6125                	addi	sp,sp,96
    80003d94:	8082                	ret
      iunlock(ip);
    80003d96:	854e                	mv	a0,s3
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	aac080e7          	jalr	-1364(ra) # 80003844 <iunlock>
      return ip;
    80003da0:	bfe9                	j	80003d7a <namex+0x6a>
      iunlockput(ip);
    80003da2:	854e                	mv	a0,s3
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	c40080e7          	jalr	-960(ra) # 800039e4 <iunlockput>
      return 0;
    80003dac:	89d2                	mv	s3,s4
    80003dae:	b7f1                	j	80003d7a <namex+0x6a>
  len = path - s;
    80003db0:	40b48633          	sub	a2,s1,a1
    80003db4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003db8:	094cd663          	ble	s4,s9,80003e44 <namex+0x134>
    memmove(name, s, DIRSIZ);
    80003dbc:	4639                	li	a2,14
    80003dbe:	8556                	mv	a0,s5
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	00a080e7          	jalr	10(ra) # 80000dca <memmove>
  while(*path == '/')
    80003dc8:	0004c783          	lbu	a5,0(s1)
    80003dcc:	01279763          	bne	a5,s2,80003dda <namex+0xca>
    path++;
    80003dd0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dd2:	0004c783          	lbu	a5,0(s1)
    80003dd6:	ff278de3          	beq	a5,s2,80003dd0 <namex+0xc0>
    ilock(ip);
    80003dda:	854e                	mv	a0,s3
    80003ddc:	00000097          	auipc	ra,0x0
    80003de0:	9a4080e7          	jalr	-1628(ra) # 80003780 <ilock>
    if(ip->type != T_DIR){
    80003de4:	04499783          	lh	a5,68(s3)
    80003de8:	f98793e3          	bne	a5,s8,80003d6e <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dec:	000b8563          	beqz	s7,80003df6 <namex+0xe6>
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	d3cd                	beqz	a5,80003d96 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003df6:	865a                	mv	a2,s6
    80003df8:	85d6                	mv	a1,s5
    80003dfa:	854e                	mv	a0,s3
    80003dfc:	00000097          	auipc	ra,0x0
    80003e00:	e64080e7          	jalr	-412(ra) # 80003c60 <dirlookup>
    80003e04:	8a2a                	mv	s4,a0
    80003e06:	dd51                	beqz	a0,80003da2 <namex+0x92>
    iunlockput(ip);
    80003e08:	854e                	mv	a0,s3
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	bda080e7          	jalr	-1062(ra) # 800039e4 <iunlockput>
    ip = next;
    80003e12:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e14:	0004c783          	lbu	a5,0(s1)
    80003e18:	05279d63          	bne	a5,s2,80003e72 <namex+0x162>
    path++;
    80003e1c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e1e:	0004c783          	lbu	a5,0(s1)
    80003e22:	ff278de3          	beq	a5,s2,80003e1c <namex+0x10c>
  if(*path == 0)
    80003e26:	cf8d                	beqz	a5,80003e60 <namex+0x150>
  while(*path != '/' && *path != 0)
    80003e28:	01278b63          	beq	a5,s2,80003e3e <namex+0x12e>
    80003e2c:	c795                	beqz	a5,80003e58 <namex+0x148>
    path++;
    80003e2e:	85a6                	mv	a1,s1
    path++;
    80003e30:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e32:	0004c783          	lbu	a5,0(s1)
    80003e36:	f7278de3          	beq	a5,s2,80003db0 <namex+0xa0>
    80003e3a:	fbfd                	bnez	a5,80003e30 <namex+0x120>
    80003e3c:	bf95                	j	80003db0 <namex+0xa0>
    80003e3e:	85a6                	mv	a1,s1
  len = path - s;
    80003e40:	8a5a                	mv	s4,s6
    80003e42:	865a                	mv	a2,s6
    memmove(name, s, len);
    80003e44:	2601                	sext.w	a2,a2
    80003e46:	8556                	mv	a0,s5
    80003e48:	ffffd097          	auipc	ra,0xffffd
    80003e4c:	f82080e7          	jalr	-126(ra) # 80000dca <memmove>
    name[len] = 0;
    80003e50:	9a56                	add	s4,s4,s5
    80003e52:	000a0023          	sb	zero,0(s4)
    80003e56:	bf8d                	j	80003dc8 <namex+0xb8>
  while(*path != '/' && *path != 0)
    80003e58:	85a6                	mv	a1,s1
  len = path - s;
    80003e5a:	8a5a                	mv	s4,s6
    80003e5c:	865a                	mv	a2,s6
    80003e5e:	b7dd                	j	80003e44 <namex+0x134>
  if(nameiparent){
    80003e60:	f00b8de3          	beqz	s7,80003d7a <namex+0x6a>
    iput(ip);
    80003e64:	854e                	mv	a0,s3
    80003e66:	00000097          	auipc	ra,0x0
    80003e6a:	ad6080e7          	jalr	-1322(ra) # 8000393c <iput>
    return 0;
    80003e6e:	4981                	li	s3,0
    80003e70:	b729                	j	80003d7a <namex+0x6a>
  if(*path == 0)
    80003e72:	d7fd                	beqz	a5,80003e60 <namex+0x150>
    80003e74:	85a6                	mv	a1,s1
    80003e76:	bf6d                	j	80003e30 <namex+0x120>

0000000080003e78 <dirlink>:
{
    80003e78:	7139                	addi	sp,sp,-64
    80003e7a:	fc06                	sd	ra,56(sp)
    80003e7c:	f822                	sd	s0,48(sp)
    80003e7e:	f426                	sd	s1,40(sp)
    80003e80:	f04a                	sd	s2,32(sp)
    80003e82:	ec4e                	sd	s3,24(sp)
    80003e84:	e852                	sd	s4,16(sp)
    80003e86:	0080                	addi	s0,sp,64
    80003e88:	892a                	mv	s2,a0
    80003e8a:	8a2e                	mv	s4,a1
    80003e8c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e8e:	4601                	li	a2,0
    80003e90:	00000097          	auipc	ra,0x0
    80003e94:	dd0080e7          	jalr	-560(ra) # 80003c60 <dirlookup>
    80003e98:	e93d                	bnez	a0,80003f0e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e9a:	04c92483          	lw	s1,76(s2)
    80003e9e:	c49d                	beqz	s1,80003ecc <dirlink+0x54>
    80003ea0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea2:	4741                	li	a4,16
    80003ea4:	86a6                	mv	a3,s1
    80003ea6:	fc040613          	addi	a2,s0,-64
    80003eaa:	4581                	li	a1,0
    80003eac:	854a                	mv	a0,s2
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	b88080e7          	jalr	-1144(ra) # 80003a36 <readi>
    80003eb6:	47c1                	li	a5,16
    80003eb8:	06f51163          	bne	a0,a5,80003f1a <dirlink+0xa2>
    if(de.inum == 0)
    80003ebc:	fc045783          	lhu	a5,-64(s0)
    80003ec0:	c791                	beqz	a5,80003ecc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec2:	24c1                	addiw	s1,s1,16
    80003ec4:	04c92783          	lw	a5,76(s2)
    80003ec8:	fcf4ede3          	bltu	s1,a5,80003ea2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ecc:	4639                	li	a2,14
    80003ece:	85d2                	mv	a1,s4
    80003ed0:	fc240513          	addi	a0,s0,-62
    80003ed4:	ffffd097          	auipc	ra,0xffffd
    80003ed8:	fc2080e7          	jalr	-62(ra) # 80000e96 <strncpy>
  de.inum = inum;
    80003edc:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee0:	4741                	li	a4,16
    80003ee2:	86a6                	mv	a3,s1
    80003ee4:	fc040613          	addi	a2,s0,-64
    80003ee8:	4581                	li	a1,0
    80003eea:	854a                	mv	a0,s2
    80003eec:	00000097          	auipc	ra,0x0
    80003ef0:	c40080e7          	jalr	-960(ra) # 80003b2c <writei>
    80003ef4:	4741                	li	a4,16
  return 0;
    80003ef6:	4781                	li	a5,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef8:	02e51963          	bne	a0,a4,80003f2a <dirlink+0xb2>
}
    80003efc:	853e                	mv	a0,a5
    80003efe:	70e2                	ld	ra,56(sp)
    80003f00:	7442                	ld	s0,48(sp)
    80003f02:	74a2                	ld	s1,40(sp)
    80003f04:	7902                	ld	s2,32(sp)
    80003f06:	69e2                	ld	s3,24(sp)
    80003f08:	6a42                	ld	s4,16(sp)
    80003f0a:	6121                	addi	sp,sp,64
    80003f0c:	8082                	ret
    iput(ip);
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	a2e080e7          	jalr	-1490(ra) # 8000393c <iput>
    return -1;
    80003f16:	57fd                	li	a5,-1
    80003f18:	b7d5                	j	80003efc <dirlink+0x84>
      panic("dirlink read");
    80003f1a:	00004517          	auipc	a0,0x4
    80003f1e:	72e50513          	addi	a0,a0,1838 # 80008648 <sysnames+0x190>
    80003f22:	ffffc097          	auipc	ra,0xffffc
    80003f26:	652080e7          	jalr	1618(ra) # 80000574 <panic>
    panic("dirlink");
    80003f2a:	00005517          	auipc	a0,0x5
    80003f2e:	83e50513          	addi	a0,a0,-1986 # 80008768 <sysnames+0x2b0>
    80003f32:	ffffc097          	auipc	ra,0xffffc
    80003f36:	642080e7          	jalr	1602(ra) # 80000574 <panic>

0000000080003f3a <namei>:

struct inode*
namei(char *path)
{
    80003f3a:	1101                	addi	sp,sp,-32
    80003f3c:	ec06                	sd	ra,24(sp)
    80003f3e:	e822                	sd	s0,16(sp)
    80003f40:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f42:	fe040613          	addi	a2,s0,-32
    80003f46:	4581                	li	a1,0
    80003f48:	00000097          	auipc	ra,0x0
    80003f4c:	dc8080e7          	jalr	-568(ra) # 80003d10 <namex>
}
    80003f50:	60e2                	ld	ra,24(sp)
    80003f52:	6442                	ld	s0,16(sp)
    80003f54:	6105                	addi	sp,sp,32
    80003f56:	8082                	ret

0000000080003f58 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f58:	1141                	addi	sp,sp,-16
    80003f5a:	e406                	sd	ra,8(sp)
    80003f5c:	e022                	sd	s0,0(sp)
    80003f5e:	0800                	addi	s0,sp,16
  return namex(path, 1, name);
    80003f60:	862e                	mv	a2,a1
    80003f62:	4585                	li	a1,1
    80003f64:	00000097          	auipc	ra,0x0
    80003f68:	dac080e7          	jalr	-596(ra) # 80003d10 <namex>
}
    80003f6c:	60a2                	ld	ra,8(sp)
    80003f6e:	6402                	ld	s0,0(sp)
    80003f70:	0141                	addi	sp,sp,16
    80003f72:	8082                	ret

0000000080003f74 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f74:	1101                	addi	sp,sp,-32
    80003f76:	ec06                	sd	ra,24(sp)
    80003f78:	e822                	sd	s0,16(sp)
    80003f7a:	e426                	sd	s1,8(sp)
    80003f7c:	e04a                	sd	s2,0(sp)
    80003f7e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f80:	0001e917          	auipc	s2,0x1e
    80003f84:	b8890913          	addi	s2,s2,-1144 # 80021b08 <log>
    80003f88:	01892583          	lw	a1,24(s2)
    80003f8c:	02892503          	lw	a0,40(s2)
    80003f90:	fffff097          	auipc	ra,0xfffff
    80003f94:	fa8080e7          	jalr	-88(ra) # 80002f38 <bread>
    80003f98:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f9a:	02c92683          	lw	a3,44(s2)
    80003f9e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fa0:	02d05763          	blez	a3,80003fce <write_head+0x5a>
    80003fa4:	0001e797          	auipc	a5,0x1e
    80003fa8:	b9478793          	addi	a5,a5,-1132 # 80021b38 <log+0x30>
    80003fac:	05c50713          	addi	a4,a0,92
    80003fb0:	36fd                	addiw	a3,a3,-1
    80003fb2:	1682                	slli	a3,a3,0x20
    80003fb4:	9281                	srli	a3,a3,0x20
    80003fb6:	068a                	slli	a3,a3,0x2
    80003fb8:	0001e617          	auipc	a2,0x1e
    80003fbc:	b8460613          	addi	a2,a2,-1148 # 80021b3c <log+0x34>
    80003fc0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fc2:	4390                	lw	a2,0(a5)
    80003fc4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fc6:	0791                	addi	a5,a5,4
    80003fc8:	0711                	addi	a4,a4,4
    80003fca:	fed79ce3          	bne	a5,a3,80003fc2 <write_head+0x4e>
  }
  bwrite(buf);
    80003fce:	8526                	mv	a0,s1
    80003fd0:	fffff097          	auipc	ra,0xfffff
    80003fd4:	06c080e7          	jalr	108(ra) # 8000303c <bwrite>
  brelse(buf);
    80003fd8:	8526                	mv	a0,s1
    80003fda:	fffff097          	auipc	ra,0xfffff
    80003fde:	0a0080e7          	jalr	160(ra) # 8000307a <brelse>
}
    80003fe2:	60e2                	ld	ra,24(sp)
    80003fe4:	6442                	ld	s0,16(sp)
    80003fe6:	64a2                	ld	s1,8(sp)
    80003fe8:	6902                	ld	s2,0(sp)
    80003fea:	6105                	addi	sp,sp,32
    80003fec:	8082                	ret

0000000080003fee <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fee:	0001e797          	auipc	a5,0x1e
    80003ff2:	b1a78793          	addi	a5,a5,-1254 # 80021b08 <log>
    80003ff6:	57dc                	lw	a5,44(a5)
    80003ff8:	0af05663          	blez	a5,800040a4 <install_trans+0xb6>
{
    80003ffc:	7139                	addi	sp,sp,-64
    80003ffe:	fc06                	sd	ra,56(sp)
    80004000:	f822                	sd	s0,48(sp)
    80004002:	f426                	sd	s1,40(sp)
    80004004:	f04a                	sd	s2,32(sp)
    80004006:	ec4e                	sd	s3,24(sp)
    80004008:	e852                	sd	s4,16(sp)
    8000400a:	e456                	sd	s5,8(sp)
    8000400c:	0080                	addi	s0,sp,64
    8000400e:	0001ea17          	auipc	s4,0x1e
    80004012:	b2aa0a13          	addi	s4,s4,-1238 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004016:	4981                	li	s3,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004018:	0001e917          	auipc	s2,0x1e
    8000401c:	af090913          	addi	s2,s2,-1296 # 80021b08 <log>
    80004020:	01892583          	lw	a1,24(s2)
    80004024:	013585bb          	addw	a1,a1,s3
    80004028:	2585                	addiw	a1,a1,1
    8000402a:	02892503          	lw	a0,40(s2)
    8000402e:	fffff097          	auipc	ra,0xfffff
    80004032:	f0a080e7          	jalr	-246(ra) # 80002f38 <bread>
    80004036:	8aaa                	mv	s5,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004038:	000a2583          	lw	a1,0(s4)
    8000403c:	02892503          	lw	a0,40(s2)
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	ef8080e7          	jalr	-264(ra) # 80002f38 <bread>
    80004048:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000404a:	40000613          	li	a2,1024
    8000404e:	058a8593          	addi	a1,s5,88
    80004052:	05850513          	addi	a0,a0,88
    80004056:	ffffd097          	auipc	ra,0xffffd
    8000405a:	d74080e7          	jalr	-652(ra) # 80000dca <memmove>
    bwrite(dbuf);  // write dst to disk
    8000405e:	8526                	mv	a0,s1
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	fdc080e7          	jalr	-36(ra) # 8000303c <bwrite>
    bunpin(dbuf);
    80004068:	8526                	mv	a0,s1
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	0ea080e7          	jalr	234(ra) # 80003154 <bunpin>
    brelse(lbuf);
    80004072:	8556                	mv	a0,s5
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	006080e7          	jalr	6(ra) # 8000307a <brelse>
    brelse(dbuf);
    8000407c:	8526                	mv	a0,s1
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	ffc080e7          	jalr	-4(ra) # 8000307a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004086:	2985                	addiw	s3,s3,1
    80004088:	0a11                	addi	s4,s4,4
    8000408a:	02c92783          	lw	a5,44(s2)
    8000408e:	f8f9c9e3          	blt	s3,a5,80004020 <install_trans+0x32>
}
    80004092:	70e2                	ld	ra,56(sp)
    80004094:	7442                	ld	s0,48(sp)
    80004096:	74a2                	ld	s1,40(sp)
    80004098:	7902                	ld	s2,32(sp)
    8000409a:	69e2                	ld	s3,24(sp)
    8000409c:	6a42                	ld	s4,16(sp)
    8000409e:	6aa2                	ld	s5,8(sp)
    800040a0:	6121                	addi	sp,sp,64
    800040a2:	8082                	ret
    800040a4:	8082                	ret

00000000800040a6 <initlog>:
{
    800040a6:	7179                	addi	sp,sp,-48
    800040a8:	f406                	sd	ra,40(sp)
    800040aa:	f022                	sd	s0,32(sp)
    800040ac:	ec26                	sd	s1,24(sp)
    800040ae:	e84a                	sd	s2,16(sp)
    800040b0:	e44e                	sd	s3,8(sp)
    800040b2:	1800                	addi	s0,sp,48
    800040b4:	892a                	mv	s2,a0
    800040b6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040b8:	0001e497          	auipc	s1,0x1e
    800040bc:	a5048493          	addi	s1,s1,-1456 # 80021b08 <log>
    800040c0:	00004597          	auipc	a1,0x4
    800040c4:	59858593          	addi	a1,a1,1432 # 80008658 <sysnames+0x1a0>
    800040c8:	8526                	mv	a0,s1
    800040ca:	ffffd097          	auipc	ra,0xffffd
    800040ce:	b08080e7          	jalr	-1272(ra) # 80000bd2 <initlock>
  log.start = sb->logstart;
    800040d2:	0149a583          	lw	a1,20(s3)
    800040d6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040d8:	0109a783          	lw	a5,16(s3)
    800040dc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040de:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040e2:	854a                	mv	a0,s2
    800040e4:	fffff097          	auipc	ra,0xfffff
    800040e8:	e54080e7          	jalr	-428(ra) # 80002f38 <bread>
  log.lh.n = lh->n;
    800040ec:	4d3c                	lw	a5,88(a0)
    800040ee:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040f0:	02f05563          	blez	a5,8000411a <initlog+0x74>
    800040f4:	05c50713          	addi	a4,a0,92
    800040f8:	0001e697          	auipc	a3,0x1e
    800040fc:	a4068693          	addi	a3,a3,-1472 # 80021b38 <log+0x30>
    80004100:	37fd                	addiw	a5,a5,-1
    80004102:	1782                	slli	a5,a5,0x20
    80004104:	9381                	srli	a5,a5,0x20
    80004106:	078a                	slli	a5,a5,0x2
    80004108:	06050613          	addi	a2,a0,96
    8000410c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000410e:	4310                	lw	a2,0(a4)
    80004110:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004112:	0711                	addi	a4,a4,4
    80004114:	0691                	addi	a3,a3,4
    80004116:	fef71ce3          	bne	a4,a5,8000410e <initlog+0x68>
  brelse(buf);
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	f60080e7          	jalr	-160(ra) # 8000307a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004122:	00000097          	auipc	ra,0x0
    80004126:	ecc080e7          	jalr	-308(ra) # 80003fee <install_trans>
  log.lh.n = 0;
    8000412a:	0001e797          	auipc	a5,0x1e
    8000412e:	a007a523          	sw	zero,-1526(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004132:	00000097          	auipc	ra,0x0
    80004136:	e42080e7          	jalr	-446(ra) # 80003f74 <write_head>
}
    8000413a:	70a2                	ld	ra,40(sp)
    8000413c:	7402                	ld	s0,32(sp)
    8000413e:	64e2                	ld	s1,24(sp)
    80004140:	6942                	ld	s2,16(sp)
    80004142:	69a2                	ld	s3,8(sp)
    80004144:	6145                	addi	sp,sp,48
    80004146:	8082                	ret

0000000080004148 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004148:	1101                	addi	sp,sp,-32
    8000414a:	ec06                	sd	ra,24(sp)
    8000414c:	e822                	sd	s0,16(sp)
    8000414e:	e426                	sd	s1,8(sp)
    80004150:	e04a                	sd	s2,0(sp)
    80004152:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004154:	0001e517          	auipc	a0,0x1e
    80004158:	9b450513          	addi	a0,a0,-1612 # 80021b08 <log>
    8000415c:	ffffd097          	auipc	ra,0xffffd
    80004160:	b06080e7          	jalr	-1274(ra) # 80000c62 <acquire>
  while(1){
    if(log.committing){
    80004164:	0001e497          	auipc	s1,0x1e
    80004168:	9a448493          	addi	s1,s1,-1628 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000416c:	4979                	li	s2,30
    8000416e:	a039                	j	8000417c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004170:	85a6                	mv	a1,s1
    80004172:	8526                	mv	a0,s1
    80004174:	ffffe097          	auipc	ra,0xffffe
    80004178:	11e080e7          	jalr	286(ra) # 80002292 <sleep>
    if(log.committing){
    8000417c:	50dc                	lw	a5,36(s1)
    8000417e:	fbed                	bnez	a5,80004170 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004180:	509c                	lw	a5,32(s1)
    80004182:	0017871b          	addiw	a4,a5,1
    80004186:	0007069b          	sext.w	a3,a4
    8000418a:	0027179b          	slliw	a5,a4,0x2
    8000418e:	9fb9                	addw	a5,a5,a4
    80004190:	0017979b          	slliw	a5,a5,0x1
    80004194:	54d8                	lw	a4,44(s1)
    80004196:	9fb9                	addw	a5,a5,a4
    80004198:	00f95963          	ble	a5,s2,800041aa <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000419c:	85a6                	mv	a1,s1
    8000419e:	8526                	mv	a0,s1
    800041a0:	ffffe097          	auipc	ra,0xffffe
    800041a4:	0f2080e7          	jalr	242(ra) # 80002292 <sleep>
    800041a8:	bfd1                	j	8000417c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041aa:	0001e517          	auipc	a0,0x1e
    800041ae:	95e50513          	addi	a0,a0,-1698 # 80021b08 <log>
    800041b2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041b4:	ffffd097          	auipc	ra,0xffffd
    800041b8:	b62080e7          	jalr	-1182(ra) # 80000d16 <release>
      break;
    }
  }
}
    800041bc:	60e2                	ld	ra,24(sp)
    800041be:	6442                	ld	s0,16(sp)
    800041c0:	64a2                	ld	s1,8(sp)
    800041c2:	6902                	ld	s2,0(sp)
    800041c4:	6105                	addi	sp,sp,32
    800041c6:	8082                	ret

00000000800041c8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041c8:	7139                	addi	sp,sp,-64
    800041ca:	fc06                	sd	ra,56(sp)
    800041cc:	f822                	sd	s0,48(sp)
    800041ce:	f426                	sd	s1,40(sp)
    800041d0:	f04a                	sd	s2,32(sp)
    800041d2:	ec4e                	sd	s3,24(sp)
    800041d4:	e852                	sd	s4,16(sp)
    800041d6:	e456                	sd	s5,8(sp)
    800041d8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041da:	0001e917          	auipc	s2,0x1e
    800041de:	92e90913          	addi	s2,s2,-1746 # 80021b08 <log>
    800041e2:	854a                	mv	a0,s2
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	a7e080e7          	jalr	-1410(ra) # 80000c62 <acquire>
  log.outstanding -= 1;
    800041ec:	02092783          	lw	a5,32(s2)
    800041f0:	37fd                	addiw	a5,a5,-1
    800041f2:	0007849b          	sext.w	s1,a5
    800041f6:	02f92023          	sw	a5,32(s2)
  if(log.committing)
    800041fa:	02492783          	lw	a5,36(s2)
    800041fe:	eba1                	bnez	a5,8000424e <end_op+0x86>
    panic("log.committing");
  if(log.outstanding == 0){
    80004200:	ecb9                	bnez	s1,8000425e <end_op+0x96>
    do_commit = 1;
    log.committing = 1;
    80004202:	0001e917          	auipc	s2,0x1e
    80004206:	90690913          	addi	s2,s2,-1786 # 80021b08 <log>
    8000420a:	4785                	li	a5,1
    8000420c:	02f92223          	sw	a5,36(s2)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004210:	854a                	mv	a0,s2
    80004212:	ffffd097          	auipc	ra,0xffffd
    80004216:	b04080e7          	jalr	-1276(ra) # 80000d16 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000421a:	02c92783          	lw	a5,44(s2)
    8000421e:	06f04763          	bgtz	a5,8000428c <end_op+0xc4>
    acquire(&log.lock);
    80004222:	0001e497          	auipc	s1,0x1e
    80004226:	8e648493          	addi	s1,s1,-1818 # 80021b08 <log>
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	a36080e7          	jalr	-1482(ra) # 80000c62 <acquire>
    log.committing = 0;
    80004234:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004238:	8526                	mv	a0,s1
    8000423a:	ffffe097          	auipc	ra,0xffffe
    8000423e:	1de080e7          	jalr	478(ra) # 80002418 <wakeup>
    release(&log.lock);
    80004242:	8526                	mv	a0,s1
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	ad2080e7          	jalr	-1326(ra) # 80000d16 <release>
}
    8000424c:	a03d                	j	8000427a <end_op+0xb2>
    panic("log.committing");
    8000424e:	00004517          	auipc	a0,0x4
    80004252:	41250513          	addi	a0,a0,1042 # 80008660 <sysnames+0x1a8>
    80004256:	ffffc097          	auipc	ra,0xffffc
    8000425a:	31e080e7          	jalr	798(ra) # 80000574 <panic>
    wakeup(&log);
    8000425e:	0001e497          	auipc	s1,0x1e
    80004262:	8aa48493          	addi	s1,s1,-1878 # 80021b08 <log>
    80004266:	8526                	mv	a0,s1
    80004268:	ffffe097          	auipc	ra,0xffffe
    8000426c:	1b0080e7          	jalr	432(ra) # 80002418 <wakeup>
  release(&log.lock);
    80004270:	8526                	mv	a0,s1
    80004272:	ffffd097          	auipc	ra,0xffffd
    80004276:	aa4080e7          	jalr	-1372(ra) # 80000d16 <release>
}
    8000427a:	70e2                	ld	ra,56(sp)
    8000427c:	7442                	ld	s0,48(sp)
    8000427e:	74a2                	ld	s1,40(sp)
    80004280:	7902                	ld	s2,32(sp)
    80004282:	69e2                	ld	s3,24(sp)
    80004284:	6a42                	ld	s4,16(sp)
    80004286:	6aa2                	ld	s5,8(sp)
    80004288:	6121                	addi	sp,sp,64
    8000428a:	8082                	ret
    8000428c:	0001ea17          	auipc	s4,0x1e
    80004290:	8aca0a13          	addi	s4,s4,-1876 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004294:	0001e917          	auipc	s2,0x1e
    80004298:	87490913          	addi	s2,s2,-1932 # 80021b08 <log>
    8000429c:	01892583          	lw	a1,24(s2)
    800042a0:	9da5                	addw	a1,a1,s1
    800042a2:	2585                	addiw	a1,a1,1
    800042a4:	02892503          	lw	a0,40(s2)
    800042a8:	fffff097          	auipc	ra,0xfffff
    800042ac:	c90080e7          	jalr	-880(ra) # 80002f38 <bread>
    800042b0:	89aa                	mv	s3,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042b2:	000a2583          	lw	a1,0(s4)
    800042b6:	02892503          	lw	a0,40(s2)
    800042ba:	fffff097          	auipc	ra,0xfffff
    800042be:	c7e080e7          	jalr	-898(ra) # 80002f38 <bread>
    800042c2:	8aaa                	mv	s5,a0
    memmove(to->data, from->data, BSIZE);
    800042c4:	40000613          	li	a2,1024
    800042c8:	05850593          	addi	a1,a0,88
    800042cc:	05898513          	addi	a0,s3,88
    800042d0:	ffffd097          	auipc	ra,0xffffd
    800042d4:	afa080e7          	jalr	-1286(ra) # 80000dca <memmove>
    bwrite(to);  // write the log
    800042d8:	854e                	mv	a0,s3
    800042da:	fffff097          	auipc	ra,0xfffff
    800042de:	d62080e7          	jalr	-670(ra) # 8000303c <bwrite>
    brelse(from);
    800042e2:	8556                	mv	a0,s5
    800042e4:	fffff097          	auipc	ra,0xfffff
    800042e8:	d96080e7          	jalr	-618(ra) # 8000307a <brelse>
    brelse(to);
    800042ec:	854e                	mv	a0,s3
    800042ee:	fffff097          	auipc	ra,0xfffff
    800042f2:	d8c080e7          	jalr	-628(ra) # 8000307a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f6:	2485                	addiw	s1,s1,1
    800042f8:	0a11                	addi	s4,s4,4
    800042fa:	02c92783          	lw	a5,44(s2)
    800042fe:	f8f4cfe3          	blt	s1,a5,8000429c <end_op+0xd4>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004302:	00000097          	auipc	ra,0x0
    80004306:	c72080e7          	jalr	-910(ra) # 80003f74 <write_head>
    install_trans(); // Now install writes to home locations
    8000430a:	00000097          	auipc	ra,0x0
    8000430e:	ce4080e7          	jalr	-796(ra) # 80003fee <install_trans>
    log.lh.n = 0;
    80004312:	0001e797          	auipc	a5,0x1e
    80004316:	8207a123          	sw	zero,-2014(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	c5a080e7          	jalr	-934(ra) # 80003f74 <write_head>
    80004322:	b701                	j	80004222 <end_op+0x5a>

0000000080004324 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004324:	1101                	addi	sp,sp,-32
    80004326:	ec06                	sd	ra,24(sp)
    80004328:	e822                	sd	s0,16(sp)
    8000432a:	e426                	sd	s1,8(sp)
    8000432c:	e04a                	sd	s2,0(sp)
    8000432e:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004330:	0001d797          	auipc	a5,0x1d
    80004334:	7d878793          	addi	a5,a5,2008 # 80021b08 <log>
    80004338:	57d8                	lw	a4,44(a5)
    8000433a:	47f5                	li	a5,29
    8000433c:	08e7c563          	blt	a5,a4,800043c6 <log_write+0xa2>
    80004340:	892a                	mv	s2,a0
    80004342:	0001d797          	auipc	a5,0x1d
    80004346:	7c678793          	addi	a5,a5,1990 # 80021b08 <log>
    8000434a:	4fdc                	lw	a5,28(a5)
    8000434c:	37fd                	addiw	a5,a5,-1
    8000434e:	06f75c63          	ble	a5,a4,800043c6 <log_write+0xa2>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004352:	0001d797          	auipc	a5,0x1d
    80004356:	7b678793          	addi	a5,a5,1974 # 80021b08 <log>
    8000435a:	539c                	lw	a5,32(a5)
    8000435c:	06f05d63          	blez	a5,800043d6 <log_write+0xb2>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004360:	0001d497          	auipc	s1,0x1d
    80004364:	7a848493          	addi	s1,s1,1960 # 80021b08 <log>
    80004368:	8526                	mv	a0,s1
    8000436a:	ffffd097          	auipc	ra,0xffffd
    8000436e:	8f8080e7          	jalr	-1800(ra) # 80000c62 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004372:	54d0                	lw	a2,44(s1)
    80004374:	0ac05063          	blez	a2,80004414 <log_write+0xf0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004378:	00c92583          	lw	a1,12(s2)
    8000437c:	589c                	lw	a5,48(s1)
    8000437e:	0ab78363          	beq	a5,a1,80004424 <log_write+0x100>
    80004382:	0001d717          	auipc	a4,0x1d
    80004386:	7ba70713          	addi	a4,a4,1978 # 80021b3c <log+0x34>
  for (i = 0; i < log.lh.n; i++) {
    8000438a:	4781                	li	a5,0
    8000438c:	2785                	addiw	a5,a5,1
    8000438e:	04c78c63          	beq	a5,a2,800043e6 <log_write+0xc2>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004392:	4314                	lw	a3,0(a4)
    80004394:	0711                	addi	a4,a4,4
    80004396:	feb69be3          	bne	a3,a1,8000438c <log_write+0x68>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000439a:	07a1                	addi	a5,a5,8
    8000439c:	078a                	slli	a5,a5,0x2
    8000439e:	0001d717          	auipc	a4,0x1d
    800043a2:	76a70713          	addi	a4,a4,1898 # 80021b08 <log>
    800043a6:	97ba                	add	a5,a5,a4
    800043a8:	cb8c                	sw	a1,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    log.lh.n++;
  }
  release(&log.lock);
    800043aa:	0001d517          	auipc	a0,0x1d
    800043ae:	75e50513          	addi	a0,a0,1886 # 80021b08 <log>
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	964080e7          	jalr	-1692(ra) # 80000d16 <release>
}
    800043ba:	60e2                	ld	ra,24(sp)
    800043bc:	6442                	ld	s0,16(sp)
    800043be:	64a2                	ld	s1,8(sp)
    800043c0:	6902                	ld	s2,0(sp)
    800043c2:	6105                	addi	sp,sp,32
    800043c4:	8082                	ret
    panic("too big a transaction");
    800043c6:	00004517          	auipc	a0,0x4
    800043ca:	2aa50513          	addi	a0,a0,682 # 80008670 <sysnames+0x1b8>
    800043ce:	ffffc097          	auipc	ra,0xffffc
    800043d2:	1a6080e7          	jalr	422(ra) # 80000574 <panic>
    panic("log_write outside of trans");
    800043d6:	00004517          	auipc	a0,0x4
    800043da:	2b250513          	addi	a0,a0,690 # 80008688 <sysnames+0x1d0>
    800043de:	ffffc097          	auipc	ra,0xffffc
    800043e2:	196080e7          	jalr	406(ra) # 80000574 <panic>
  log.lh.block[i] = b->blockno;
    800043e6:	0621                	addi	a2,a2,8
    800043e8:	060a                	slli	a2,a2,0x2
    800043ea:	0001d797          	auipc	a5,0x1d
    800043ee:	71e78793          	addi	a5,a5,1822 # 80021b08 <log>
    800043f2:	963e                	add	a2,a2,a5
    800043f4:	00c92783          	lw	a5,12(s2)
    800043f8:	ca1c                	sw	a5,16(a2)
    bpin(b);
    800043fa:	854a                	mv	a0,s2
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	d1c080e7          	jalr	-740(ra) # 80003118 <bpin>
    log.lh.n++;
    80004404:	0001d717          	auipc	a4,0x1d
    80004408:	70470713          	addi	a4,a4,1796 # 80021b08 <log>
    8000440c:	575c                	lw	a5,44(a4)
    8000440e:	2785                	addiw	a5,a5,1
    80004410:	d75c                	sw	a5,44(a4)
    80004412:	bf61                	j	800043aa <log_write+0x86>
  log.lh.block[i] = b->blockno;
    80004414:	00c92783          	lw	a5,12(s2)
    80004418:	0001d717          	auipc	a4,0x1d
    8000441c:	72f72023          	sw	a5,1824(a4) # 80021b38 <log+0x30>
  if (i == log.lh.n) {  // Add new block to log?
    80004420:	f649                	bnez	a2,800043aa <log_write+0x86>
    80004422:	bfe1                	j	800043fa <log_write+0xd6>
  for (i = 0; i < log.lh.n; i++) {
    80004424:	4781                	li	a5,0
    80004426:	bf95                	j	8000439a <log_write+0x76>

0000000080004428 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004428:	1101                	addi	sp,sp,-32
    8000442a:	ec06                	sd	ra,24(sp)
    8000442c:	e822                	sd	s0,16(sp)
    8000442e:	e426                	sd	s1,8(sp)
    80004430:	e04a                	sd	s2,0(sp)
    80004432:	1000                	addi	s0,sp,32
    80004434:	84aa                	mv	s1,a0
    80004436:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004438:	00004597          	auipc	a1,0x4
    8000443c:	27058593          	addi	a1,a1,624 # 800086a8 <sysnames+0x1f0>
    80004440:	0521                	addi	a0,a0,8
    80004442:	ffffc097          	auipc	ra,0xffffc
    80004446:	790080e7          	jalr	1936(ra) # 80000bd2 <initlock>
  lk->name = name;
    8000444a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000444e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004452:	0204a423          	sw	zero,40(s1)
}
    80004456:	60e2                	ld	ra,24(sp)
    80004458:	6442                	ld	s0,16(sp)
    8000445a:	64a2                	ld	s1,8(sp)
    8000445c:	6902                	ld	s2,0(sp)
    8000445e:	6105                	addi	sp,sp,32
    80004460:	8082                	ret

0000000080004462 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004462:	1101                	addi	sp,sp,-32
    80004464:	ec06                	sd	ra,24(sp)
    80004466:	e822                	sd	s0,16(sp)
    80004468:	e426                	sd	s1,8(sp)
    8000446a:	e04a                	sd	s2,0(sp)
    8000446c:	1000                	addi	s0,sp,32
    8000446e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004470:	00850913          	addi	s2,a0,8
    80004474:	854a                	mv	a0,s2
    80004476:	ffffc097          	auipc	ra,0xffffc
    8000447a:	7ec080e7          	jalr	2028(ra) # 80000c62 <acquire>
  while (lk->locked) {
    8000447e:	409c                	lw	a5,0(s1)
    80004480:	cb89                	beqz	a5,80004492 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004482:	85ca                	mv	a1,s2
    80004484:	8526                	mv	a0,s1
    80004486:	ffffe097          	auipc	ra,0xffffe
    8000448a:	e0c080e7          	jalr	-500(ra) # 80002292 <sleep>
  while (lk->locked) {
    8000448e:	409c                	lw	a5,0(s1)
    80004490:	fbed                	bnez	a5,80004482 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004492:	4785                	li	a5,1
    80004494:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004496:	ffffd097          	auipc	ra,0xffffd
    8000449a:	5da080e7          	jalr	1498(ra) # 80001a70 <myproc>
    8000449e:	5d1c                	lw	a5,56(a0)
    800044a0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044a2:	854a                	mv	a0,s2
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	872080e7          	jalr	-1934(ra) # 80000d16 <release>
}
    800044ac:	60e2                	ld	ra,24(sp)
    800044ae:	6442                	ld	s0,16(sp)
    800044b0:	64a2                	ld	s1,8(sp)
    800044b2:	6902                	ld	s2,0(sp)
    800044b4:	6105                	addi	sp,sp,32
    800044b6:	8082                	ret

00000000800044b8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044b8:	1101                	addi	sp,sp,-32
    800044ba:	ec06                	sd	ra,24(sp)
    800044bc:	e822                	sd	s0,16(sp)
    800044be:	e426                	sd	s1,8(sp)
    800044c0:	e04a                	sd	s2,0(sp)
    800044c2:	1000                	addi	s0,sp,32
    800044c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044c6:	00850913          	addi	s2,a0,8
    800044ca:	854a                	mv	a0,s2
    800044cc:	ffffc097          	auipc	ra,0xffffc
    800044d0:	796080e7          	jalr	1942(ra) # 80000c62 <acquire>
  lk->locked = 0;
    800044d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044d8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044dc:	8526                	mv	a0,s1
    800044de:	ffffe097          	auipc	ra,0xffffe
    800044e2:	f3a080e7          	jalr	-198(ra) # 80002418 <wakeup>
  release(&lk->lk);
    800044e6:	854a                	mv	a0,s2
    800044e8:	ffffd097          	auipc	ra,0xffffd
    800044ec:	82e080e7          	jalr	-2002(ra) # 80000d16 <release>
}
    800044f0:	60e2                	ld	ra,24(sp)
    800044f2:	6442                	ld	s0,16(sp)
    800044f4:	64a2                	ld	s1,8(sp)
    800044f6:	6902                	ld	s2,0(sp)
    800044f8:	6105                	addi	sp,sp,32
    800044fa:	8082                	ret

00000000800044fc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044fc:	7179                	addi	sp,sp,-48
    800044fe:	f406                	sd	ra,40(sp)
    80004500:	f022                	sd	s0,32(sp)
    80004502:	ec26                	sd	s1,24(sp)
    80004504:	e84a                	sd	s2,16(sp)
    80004506:	e44e                	sd	s3,8(sp)
    80004508:	1800                	addi	s0,sp,48
    8000450a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000450c:	00850913          	addi	s2,a0,8
    80004510:	854a                	mv	a0,s2
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	750080e7          	jalr	1872(ra) # 80000c62 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000451a:	409c                	lw	a5,0(s1)
    8000451c:	ef99                	bnez	a5,8000453a <holdingsleep+0x3e>
    8000451e:	4481                	li	s1,0
  release(&lk->lk);
    80004520:	854a                	mv	a0,s2
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	7f4080e7          	jalr	2036(ra) # 80000d16 <release>
  return r;
}
    8000452a:	8526                	mv	a0,s1
    8000452c:	70a2                	ld	ra,40(sp)
    8000452e:	7402                	ld	s0,32(sp)
    80004530:	64e2                	ld	s1,24(sp)
    80004532:	6942                	ld	s2,16(sp)
    80004534:	69a2                	ld	s3,8(sp)
    80004536:	6145                	addi	sp,sp,48
    80004538:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000453a:	0284a983          	lw	s3,40(s1)
    8000453e:	ffffd097          	auipc	ra,0xffffd
    80004542:	532080e7          	jalr	1330(ra) # 80001a70 <myproc>
    80004546:	5d04                	lw	s1,56(a0)
    80004548:	413484b3          	sub	s1,s1,s3
    8000454c:	0014b493          	seqz	s1,s1
    80004550:	bfc1                	j	80004520 <holdingsleep+0x24>

0000000080004552 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004552:	1141                	addi	sp,sp,-16
    80004554:	e406                	sd	ra,8(sp)
    80004556:	e022                	sd	s0,0(sp)
    80004558:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000455a:	00004597          	auipc	a1,0x4
    8000455e:	15e58593          	addi	a1,a1,350 # 800086b8 <sysnames+0x200>
    80004562:	0001d517          	auipc	a0,0x1d
    80004566:	6ee50513          	addi	a0,a0,1774 # 80021c50 <ftable>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	668080e7          	jalr	1640(ra) # 80000bd2 <initlock>
}
    80004572:	60a2                	ld	ra,8(sp)
    80004574:	6402                	ld	s0,0(sp)
    80004576:	0141                	addi	sp,sp,16
    80004578:	8082                	ret

000000008000457a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000457a:	1101                	addi	sp,sp,-32
    8000457c:	ec06                	sd	ra,24(sp)
    8000457e:	e822                	sd	s0,16(sp)
    80004580:	e426                	sd	s1,8(sp)
    80004582:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004584:	0001d517          	auipc	a0,0x1d
    80004588:	6cc50513          	addi	a0,a0,1740 # 80021c50 <ftable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	6d6080e7          	jalr	1750(ra) # 80000c62 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
    80004594:	0001d797          	auipc	a5,0x1d
    80004598:	6bc78793          	addi	a5,a5,1724 # 80021c50 <ftable>
    8000459c:	4fdc                	lw	a5,28(a5)
    8000459e:	cb8d                	beqz	a5,800045d0 <filealloc+0x56>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a0:	0001d497          	auipc	s1,0x1d
    800045a4:	6f048493          	addi	s1,s1,1776 # 80021c90 <ftable+0x40>
    800045a8:	0001e717          	auipc	a4,0x1e
    800045ac:	66070713          	addi	a4,a4,1632 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    800045b0:	40dc                	lw	a5,4(s1)
    800045b2:	c39d                	beqz	a5,800045d8 <filealloc+0x5e>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b4:	02848493          	addi	s1,s1,40
    800045b8:	fee49ce3          	bne	s1,a4,800045b0 <filealloc+0x36>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045bc:	0001d517          	auipc	a0,0x1d
    800045c0:	69450513          	addi	a0,a0,1684 # 80021c50 <ftable>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	752080e7          	jalr	1874(ra) # 80000d16 <release>
  return 0;
    800045cc:	4481                	li	s1,0
    800045ce:	a839                	j	800045ec <filealloc+0x72>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045d0:	0001d497          	auipc	s1,0x1d
    800045d4:	69848493          	addi	s1,s1,1688 # 80021c68 <ftable+0x18>
      f->ref = 1;
    800045d8:	4785                	li	a5,1
    800045da:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045dc:	0001d517          	auipc	a0,0x1d
    800045e0:	67450513          	addi	a0,a0,1652 # 80021c50 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	732080e7          	jalr	1842(ra) # 80000d16 <release>
}
    800045ec:	8526                	mv	a0,s1
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6105                	addi	sp,sp,32
    800045f6:	8082                	ret

00000000800045f8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045f8:	1101                	addi	sp,sp,-32
    800045fa:	ec06                	sd	ra,24(sp)
    800045fc:	e822                	sd	s0,16(sp)
    800045fe:	e426                	sd	s1,8(sp)
    80004600:	1000                	addi	s0,sp,32
    80004602:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004604:	0001d517          	auipc	a0,0x1d
    80004608:	64c50513          	addi	a0,a0,1612 # 80021c50 <ftable>
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	656080e7          	jalr	1622(ra) # 80000c62 <acquire>
  if(f->ref < 1)
    80004614:	40dc                	lw	a5,4(s1)
    80004616:	02f05263          	blez	a5,8000463a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000461a:	2785                	addiw	a5,a5,1
    8000461c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000461e:	0001d517          	auipc	a0,0x1d
    80004622:	63250513          	addi	a0,a0,1586 # 80021c50 <ftable>
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	6f0080e7          	jalr	1776(ra) # 80000d16 <release>
  return f;
}
    8000462e:	8526                	mv	a0,s1
    80004630:	60e2                	ld	ra,24(sp)
    80004632:	6442                	ld	s0,16(sp)
    80004634:	64a2                	ld	s1,8(sp)
    80004636:	6105                	addi	sp,sp,32
    80004638:	8082                	ret
    panic("filedup");
    8000463a:	00004517          	auipc	a0,0x4
    8000463e:	08650513          	addi	a0,a0,134 # 800086c0 <sysnames+0x208>
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	f32080e7          	jalr	-206(ra) # 80000574 <panic>

000000008000464a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000464a:	7139                	addi	sp,sp,-64
    8000464c:	fc06                	sd	ra,56(sp)
    8000464e:	f822                	sd	s0,48(sp)
    80004650:	f426                	sd	s1,40(sp)
    80004652:	f04a                	sd	s2,32(sp)
    80004654:	ec4e                	sd	s3,24(sp)
    80004656:	e852                	sd	s4,16(sp)
    80004658:	e456                	sd	s5,8(sp)
    8000465a:	0080                	addi	s0,sp,64
    8000465c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000465e:	0001d517          	auipc	a0,0x1d
    80004662:	5f250513          	addi	a0,a0,1522 # 80021c50 <ftable>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	5fc080e7          	jalr	1532(ra) # 80000c62 <acquire>
  if(f->ref < 1)
    8000466e:	40dc                	lw	a5,4(s1)
    80004670:	06f05163          	blez	a5,800046d2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004674:	37fd                	addiw	a5,a5,-1
    80004676:	0007871b          	sext.w	a4,a5
    8000467a:	c0dc                	sw	a5,4(s1)
    8000467c:	06e04363          	bgtz	a4,800046e2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004680:	0004a903          	lw	s2,0(s1)
    80004684:	0094ca83          	lbu	s5,9(s1)
    80004688:	0104ba03          	ld	s4,16(s1)
    8000468c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004690:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004694:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004698:	0001d517          	auipc	a0,0x1d
    8000469c:	5b850513          	addi	a0,a0,1464 # 80021c50 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	676080e7          	jalr	1654(ra) # 80000d16 <release>

  if(ff.type == FD_PIPE){
    800046a8:	4785                	li	a5,1
    800046aa:	04f90d63          	beq	s2,a5,80004704 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046ae:	3979                	addiw	s2,s2,-2
    800046b0:	4785                	li	a5,1
    800046b2:	0527e063          	bltu	a5,s2,800046f2 <fileclose+0xa8>
    begin_op();
    800046b6:	00000097          	auipc	ra,0x0
    800046ba:	a92080e7          	jalr	-1390(ra) # 80004148 <begin_op>
    iput(ff.ip);
    800046be:	854e                	mv	a0,s3
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	27c080e7          	jalr	636(ra) # 8000393c <iput>
    end_op();
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	b00080e7          	jalr	-1280(ra) # 800041c8 <end_op>
    800046d0:	a00d                	j	800046f2 <fileclose+0xa8>
    panic("fileclose");
    800046d2:	00004517          	auipc	a0,0x4
    800046d6:	ff650513          	addi	a0,a0,-10 # 800086c8 <sysnames+0x210>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	e9a080e7          	jalr	-358(ra) # 80000574 <panic>
    release(&ftable.lock);
    800046e2:	0001d517          	auipc	a0,0x1d
    800046e6:	56e50513          	addi	a0,a0,1390 # 80021c50 <ftable>
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	62c080e7          	jalr	1580(ra) # 80000d16 <release>
  }
}
    800046f2:	70e2                	ld	ra,56(sp)
    800046f4:	7442                	ld	s0,48(sp)
    800046f6:	74a2                	ld	s1,40(sp)
    800046f8:	7902                	ld	s2,32(sp)
    800046fa:	69e2                	ld	s3,24(sp)
    800046fc:	6a42                	ld	s4,16(sp)
    800046fe:	6aa2                	ld	s5,8(sp)
    80004700:	6121                	addi	sp,sp,64
    80004702:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004704:	85d6                	mv	a1,s5
    80004706:	8552                	mv	a0,s4
    80004708:	00000097          	auipc	ra,0x0
    8000470c:	364080e7          	jalr	868(ra) # 80004a6c <pipeclose>
    80004710:	b7cd                	j	800046f2 <fileclose+0xa8>

0000000080004712 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004712:	715d                	addi	sp,sp,-80
    80004714:	e486                	sd	ra,72(sp)
    80004716:	e0a2                	sd	s0,64(sp)
    80004718:	fc26                	sd	s1,56(sp)
    8000471a:	f84a                	sd	s2,48(sp)
    8000471c:	f44e                	sd	s3,40(sp)
    8000471e:	0880                	addi	s0,sp,80
    80004720:	84aa                	mv	s1,a0
    80004722:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004724:	ffffd097          	auipc	ra,0xffffd
    80004728:	34c080e7          	jalr	844(ra) # 80001a70 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000472c:	409c                	lw	a5,0(s1)
    8000472e:	37f9                	addiw	a5,a5,-2
    80004730:	4705                	li	a4,1
    80004732:	04f76763          	bltu	a4,a5,80004780 <filestat+0x6e>
    80004736:	892a                	mv	s2,a0
    ilock(f->ip);
    80004738:	6c88                	ld	a0,24(s1)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	046080e7          	jalr	70(ra) # 80003780 <ilock>
    stati(f->ip, &st);
    80004742:	fb840593          	addi	a1,s0,-72
    80004746:	6c88                	ld	a0,24(s1)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	2c4080e7          	jalr	708(ra) # 80003a0c <stati>
    iunlock(f->ip);
    80004750:	6c88                	ld	a0,24(s1)
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	0f2080e7          	jalr	242(ra) # 80003844 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000475a:	46e1                	li	a3,24
    8000475c:	fb840613          	addi	a2,s0,-72
    80004760:	85ce                	mv	a1,s3
    80004762:	05093503          	ld	a0,80(s2)
    80004766:	ffffd097          	auipc	ra,0xffffd
    8000476a:	fe6080e7          	jalr	-26(ra) # 8000174c <copyout>
    8000476e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004772:	60a6                	ld	ra,72(sp)
    80004774:	6406                	ld	s0,64(sp)
    80004776:	74e2                	ld	s1,56(sp)
    80004778:	7942                	ld	s2,48(sp)
    8000477a:	79a2                	ld	s3,40(sp)
    8000477c:	6161                	addi	sp,sp,80
    8000477e:	8082                	ret
  return -1;
    80004780:	557d                	li	a0,-1
    80004782:	bfc5                	j	80004772 <filestat+0x60>

0000000080004784 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004784:	7179                	addi	sp,sp,-48
    80004786:	f406                	sd	ra,40(sp)
    80004788:	f022                	sd	s0,32(sp)
    8000478a:	ec26                	sd	s1,24(sp)
    8000478c:	e84a                	sd	s2,16(sp)
    8000478e:	e44e                	sd	s3,8(sp)
    80004790:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004792:	00854783          	lbu	a5,8(a0)
    80004796:	c3d5                	beqz	a5,8000483a <fileread+0xb6>
    80004798:	89b2                	mv	s3,a2
    8000479a:	892e                	mv	s2,a1
    8000479c:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    8000479e:	411c                	lw	a5,0(a0)
    800047a0:	4705                	li	a4,1
    800047a2:	04e78963          	beq	a5,a4,800047f4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047a6:	470d                	li	a4,3
    800047a8:	04e78d63          	beq	a5,a4,80004802 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047ac:	4709                	li	a4,2
    800047ae:	06e79e63          	bne	a5,a4,8000482a <fileread+0xa6>
    ilock(f->ip);
    800047b2:	6d08                	ld	a0,24(a0)
    800047b4:	fffff097          	auipc	ra,0xfffff
    800047b8:	fcc080e7          	jalr	-52(ra) # 80003780 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047bc:	874e                	mv	a4,s3
    800047be:	5094                	lw	a3,32(s1)
    800047c0:	864a                	mv	a2,s2
    800047c2:	4585                	li	a1,1
    800047c4:	6c88                	ld	a0,24(s1)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	270080e7          	jalr	624(ra) # 80003a36 <readi>
    800047ce:	892a                	mv	s2,a0
    800047d0:	00a05563          	blez	a0,800047da <fileread+0x56>
      f->off += r;
    800047d4:	509c                	lw	a5,32(s1)
    800047d6:	9fa9                	addw	a5,a5,a0
    800047d8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047da:	6c88                	ld	a0,24(s1)
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	068080e7          	jalr	104(ra) # 80003844 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047e4:	854a                	mv	a0,s2
    800047e6:	70a2                	ld	ra,40(sp)
    800047e8:	7402                	ld	s0,32(sp)
    800047ea:	64e2                	ld	s1,24(sp)
    800047ec:	6942                	ld	s2,16(sp)
    800047ee:	69a2                	ld	s3,8(sp)
    800047f0:	6145                	addi	sp,sp,48
    800047f2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047f4:	6908                	ld	a0,16(a0)
    800047f6:	00000097          	auipc	ra,0x0
    800047fa:	416080e7          	jalr	1046(ra) # 80004c0c <piperead>
    800047fe:	892a                	mv	s2,a0
    80004800:	b7d5                	j	800047e4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004802:	02451783          	lh	a5,36(a0)
    80004806:	03079693          	slli	a3,a5,0x30
    8000480a:	92c1                	srli	a3,a3,0x30
    8000480c:	4725                	li	a4,9
    8000480e:	02d76863          	bltu	a4,a3,8000483e <fileread+0xba>
    80004812:	0792                	slli	a5,a5,0x4
    80004814:	0001d717          	auipc	a4,0x1d
    80004818:	39c70713          	addi	a4,a4,924 # 80021bb0 <devsw>
    8000481c:	97ba                	add	a5,a5,a4
    8000481e:	639c                	ld	a5,0(a5)
    80004820:	c38d                	beqz	a5,80004842 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004822:	4505                	li	a0,1
    80004824:	9782                	jalr	a5
    80004826:	892a                	mv	s2,a0
    80004828:	bf75                	j	800047e4 <fileread+0x60>
    panic("fileread");
    8000482a:	00004517          	auipc	a0,0x4
    8000482e:	eae50513          	addi	a0,a0,-338 # 800086d8 <sysnames+0x220>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	d42080e7          	jalr	-702(ra) # 80000574 <panic>
    return -1;
    8000483a:	597d                	li	s2,-1
    8000483c:	b765                	j	800047e4 <fileread+0x60>
      return -1;
    8000483e:	597d                	li	s2,-1
    80004840:	b755                	j	800047e4 <fileread+0x60>
    80004842:	597d                	li	s2,-1
    80004844:	b745                	j	800047e4 <fileread+0x60>

0000000080004846 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004846:	00954783          	lbu	a5,9(a0)
    8000484a:	12078e63          	beqz	a5,80004986 <filewrite+0x140>
{
    8000484e:	715d                	addi	sp,sp,-80
    80004850:	e486                	sd	ra,72(sp)
    80004852:	e0a2                	sd	s0,64(sp)
    80004854:	fc26                	sd	s1,56(sp)
    80004856:	f84a                	sd	s2,48(sp)
    80004858:	f44e                	sd	s3,40(sp)
    8000485a:	f052                	sd	s4,32(sp)
    8000485c:	ec56                	sd	s5,24(sp)
    8000485e:	e85a                	sd	s6,16(sp)
    80004860:	e45e                	sd	s7,8(sp)
    80004862:	e062                	sd	s8,0(sp)
    80004864:	0880                	addi	s0,sp,80
    80004866:	8ab2                	mv	s5,a2
    80004868:	8b2e                	mv	s6,a1
    8000486a:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    8000486c:	411c                	lw	a5,0(a0)
    8000486e:	4705                	li	a4,1
    80004870:	02e78263          	beq	a5,a4,80004894 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004874:	470d                	li	a4,3
    80004876:	02e78563          	beq	a5,a4,800048a0 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000487a:	4709                	li	a4,2
    8000487c:	0ee79d63          	bne	a5,a4,80004976 <filewrite+0x130>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004880:	0ec05763          	blez	a2,8000496e <filewrite+0x128>
    int i = 0;
    80004884:	4901                	li	s2,0
    80004886:	6b85                	lui	s7,0x1
    80004888:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000488c:	6c05                	lui	s8,0x1
    8000488e:	c00c0c1b          	addiw	s8,s8,-1024
    80004892:	a061                	j	8000491a <filewrite+0xd4>
    ret = pipewrite(f->pipe, addr, n);
    80004894:	6908                	ld	a0,16(a0)
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	246080e7          	jalr	582(ra) # 80004adc <pipewrite>
    8000489e:	a065                	j	80004946 <filewrite+0x100>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048a0:	02451783          	lh	a5,36(a0)
    800048a4:	03079693          	slli	a3,a5,0x30
    800048a8:	92c1                	srli	a3,a3,0x30
    800048aa:	4725                	li	a4,9
    800048ac:	0cd76f63          	bltu	a4,a3,8000498a <filewrite+0x144>
    800048b0:	0792                	slli	a5,a5,0x4
    800048b2:	0001d717          	auipc	a4,0x1d
    800048b6:	2fe70713          	addi	a4,a4,766 # 80021bb0 <devsw>
    800048ba:	97ba                	add	a5,a5,a4
    800048bc:	679c                	ld	a5,8(a5)
    800048be:	cbe1                	beqz	a5,8000498e <filewrite+0x148>
    ret = devsw[f->major].write(1, addr, n);
    800048c0:	4505                	li	a0,1
    800048c2:	9782                	jalr	a5
    800048c4:	a049                	j	80004946 <filewrite+0x100>
    800048c6:	00098a1b          	sext.w	s4,s3
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ca:	00000097          	auipc	ra,0x0
    800048ce:	87e080e7          	jalr	-1922(ra) # 80004148 <begin_op>
      ilock(f->ip);
    800048d2:	6c88                	ld	a0,24(s1)
    800048d4:	fffff097          	auipc	ra,0xfffff
    800048d8:	eac080e7          	jalr	-340(ra) # 80003780 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048dc:	8752                	mv	a4,s4
    800048de:	5094                	lw	a3,32(s1)
    800048e0:	01690633          	add	a2,s2,s6
    800048e4:	4585                	li	a1,1
    800048e6:	6c88                	ld	a0,24(s1)
    800048e8:	fffff097          	auipc	ra,0xfffff
    800048ec:	244080e7          	jalr	580(ra) # 80003b2c <writei>
    800048f0:	89aa                	mv	s3,a0
    800048f2:	02a05c63          	blez	a0,8000492a <filewrite+0xe4>
        f->off += r;
    800048f6:	509c                	lw	a5,32(s1)
    800048f8:	9fa9                	addw	a5,a5,a0
    800048fa:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    800048fc:	6c88                	ld	a0,24(s1)
    800048fe:	fffff097          	auipc	ra,0xfffff
    80004902:	f46080e7          	jalr	-186(ra) # 80003844 <iunlock>
      end_op();
    80004906:	00000097          	auipc	ra,0x0
    8000490a:	8c2080e7          	jalr	-1854(ra) # 800041c8 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000490e:	05499863          	bne	s3,s4,8000495e <filewrite+0x118>
        panic("short filewrite");
      i += r;
    80004912:	012a093b          	addw	s2,s4,s2
    while(i < n){
    80004916:	03595563          	ble	s5,s2,80004940 <filewrite+0xfa>
      int n1 = n - i;
    8000491a:	412a87bb          	subw	a5,s5,s2
      if(n1 > max)
    8000491e:	89be                	mv	s3,a5
    80004920:	2781                	sext.w	a5,a5
    80004922:	fafbd2e3          	ble	a5,s7,800048c6 <filewrite+0x80>
    80004926:	89e2                	mv	s3,s8
    80004928:	bf79                	j	800048c6 <filewrite+0x80>
      iunlock(f->ip);
    8000492a:	6c88                	ld	a0,24(s1)
    8000492c:	fffff097          	auipc	ra,0xfffff
    80004930:	f18080e7          	jalr	-232(ra) # 80003844 <iunlock>
      end_op();
    80004934:	00000097          	auipc	ra,0x0
    80004938:	894080e7          	jalr	-1900(ra) # 800041c8 <end_op>
      if(r < 0)
    8000493c:	fc09d9e3          	bgez	s3,8000490e <filewrite+0xc8>
    }
    ret = (i == n ? n : -1);
    80004940:	8556                	mv	a0,s5
    80004942:	032a9863          	bne	s5,s2,80004972 <filewrite+0x12c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004946:	60a6                	ld	ra,72(sp)
    80004948:	6406                	ld	s0,64(sp)
    8000494a:	74e2                	ld	s1,56(sp)
    8000494c:	7942                	ld	s2,48(sp)
    8000494e:	79a2                	ld	s3,40(sp)
    80004950:	7a02                	ld	s4,32(sp)
    80004952:	6ae2                	ld	s5,24(sp)
    80004954:	6b42                	ld	s6,16(sp)
    80004956:	6ba2                	ld	s7,8(sp)
    80004958:	6c02                	ld	s8,0(sp)
    8000495a:	6161                	addi	sp,sp,80
    8000495c:	8082                	ret
        panic("short filewrite");
    8000495e:	00004517          	auipc	a0,0x4
    80004962:	d8a50513          	addi	a0,a0,-630 # 800086e8 <sysnames+0x230>
    80004966:	ffffc097          	auipc	ra,0xffffc
    8000496a:	c0e080e7          	jalr	-1010(ra) # 80000574 <panic>
    int i = 0;
    8000496e:	4901                	li	s2,0
    80004970:	bfc1                	j	80004940 <filewrite+0xfa>
    ret = (i == n ? n : -1);
    80004972:	557d                	li	a0,-1
    80004974:	bfc9                	j	80004946 <filewrite+0x100>
    panic("filewrite");
    80004976:	00004517          	auipc	a0,0x4
    8000497a:	d8250513          	addi	a0,a0,-638 # 800086f8 <sysnames+0x240>
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	bf6080e7          	jalr	-1034(ra) # 80000574 <panic>
    return -1;
    80004986:	557d                	li	a0,-1
}
    80004988:	8082                	ret
      return -1;
    8000498a:	557d                	li	a0,-1
    8000498c:	bf6d                	j	80004946 <filewrite+0x100>
    8000498e:	557d                	li	a0,-1
    80004990:	bf5d                	j	80004946 <filewrite+0x100>

0000000080004992 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004992:	7179                	addi	sp,sp,-48
    80004994:	f406                	sd	ra,40(sp)
    80004996:	f022                	sd	s0,32(sp)
    80004998:	ec26                	sd	s1,24(sp)
    8000499a:	e84a                	sd	s2,16(sp)
    8000499c:	e44e                	sd	s3,8(sp)
    8000499e:	e052                	sd	s4,0(sp)
    800049a0:	1800                	addi	s0,sp,48
    800049a2:	84aa                	mv	s1,a0
    800049a4:	892e                	mv	s2,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049a6:	0005b023          	sd	zero,0(a1)
    800049aa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049ae:	00000097          	auipc	ra,0x0
    800049b2:	bcc080e7          	jalr	-1076(ra) # 8000457a <filealloc>
    800049b6:	e088                	sd	a0,0(s1)
    800049b8:	c551                	beqz	a0,80004a44 <pipealloc+0xb2>
    800049ba:	00000097          	auipc	ra,0x0
    800049be:	bc0080e7          	jalr	-1088(ra) # 8000457a <filealloc>
    800049c2:	00a93023          	sd	a0,0(s2)
    800049c6:	c92d                	beqz	a0,80004a38 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049c8:	ffffc097          	auipc	ra,0xffffc
    800049cc:	1aa080e7          	jalr	426(ra) # 80000b72 <kalloc>
    800049d0:	89aa                	mv	s3,a0
    800049d2:	c125                	beqz	a0,80004a32 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049d4:	4a05                	li	s4,1
    800049d6:	23452023          	sw	s4,544(a0)
  pi->writeopen = 1;
    800049da:	23452223          	sw	s4,548(a0)
  pi->nwrite = 0;
    800049de:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049e2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049e6:	00004597          	auipc	a1,0x4
    800049ea:	d2258593          	addi	a1,a1,-734 # 80008708 <sysnames+0x250>
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	1e4080e7          	jalr	484(ra) # 80000bd2 <initlock>
  (*f0)->type = FD_PIPE;
    800049f6:	609c                	ld	a5,0(s1)
    800049f8:	0147a023          	sw	s4,0(a5)
  (*f0)->readable = 1;
    800049fc:	609c                	ld	a5,0(s1)
    800049fe:	01478423          	sb	s4,8(a5)
  (*f0)->writable = 0;
    80004a02:	609c                	ld	a5,0(s1)
    80004a04:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a08:	609c                	ld	a5,0(s1)
    80004a0a:	0137b823          	sd	s3,16(a5)
  (*f1)->type = FD_PIPE;
    80004a0e:	00093783          	ld	a5,0(s2)
    80004a12:	0147a023          	sw	s4,0(a5)
  (*f1)->readable = 0;
    80004a16:	00093783          	ld	a5,0(s2)
    80004a1a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a1e:	00093783          	ld	a5,0(s2)
    80004a22:	014784a3          	sb	s4,9(a5)
  (*f1)->pipe = pi;
    80004a26:	00093783          	ld	a5,0(s2)
    80004a2a:	0137b823          	sd	s3,16(a5)
  return 0;
    80004a2e:	4501                	li	a0,0
    80004a30:	a025                	j	80004a58 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a32:	6088                	ld	a0,0(s1)
    80004a34:	e501                	bnez	a0,80004a3c <pipealloc+0xaa>
    80004a36:	a039                	j	80004a44 <pipealloc+0xb2>
    80004a38:	6088                	ld	a0,0(s1)
    80004a3a:	c51d                	beqz	a0,80004a68 <pipealloc+0xd6>
    fileclose(*f0);
    80004a3c:	00000097          	auipc	ra,0x0
    80004a40:	c0e080e7          	jalr	-1010(ra) # 8000464a <fileclose>
  if(*f1)
    80004a44:	00093783          	ld	a5,0(s2)
    fileclose(*f1);
  return -1;
    80004a48:	557d                	li	a0,-1
  if(*f1)
    80004a4a:	c799                	beqz	a5,80004a58 <pipealloc+0xc6>
    fileclose(*f1);
    80004a4c:	853e                	mv	a0,a5
    80004a4e:	00000097          	auipc	ra,0x0
    80004a52:	bfc080e7          	jalr	-1028(ra) # 8000464a <fileclose>
  return -1;
    80004a56:	557d                	li	a0,-1
}
    80004a58:	70a2                	ld	ra,40(sp)
    80004a5a:	7402                	ld	s0,32(sp)
    80004a5c:	64e2                	ld	s1,24(sp)
    80004a5e:	6942                	ld	s2,16(sp)
    80004a60:	69a2                	ld	s3,8(sp)
    80004a62:	6a02                	ld	s4,0(sp)
    80004a64:	6145                	addi	sp,sp,48
    80004a66:	8082                	ret
  return -1;
    80004a68:	557d                	li	a0,-1
    80004a6a:	b7fd                	j	80004a58 <pipealloc+0xc6>

0000000080004a6c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a6c:	1101                	addi	sp,sp,-32
    80004a6e:	ec06                	sd	ra,24(sp)
    80004a70:	e822                	sd	s0,16(sp)
    80004a72:	e426                	sd	s1,8(sp)
    80004a74:	e04a                	sd	s2,0(sp)
    80004a76:	1000                	addi	s0,sp,32
    80004a78:	84aa                	mv	s1,a0
    80004a7a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	1e6080e7          	jalr	486(ra) # 80000c62 <acquire>
  if(writable){
    80004a84:	02090d63          	beqz	s2,80004abe <pipeclose+0x52>
    pi->writeopen = 0;
    80004a88:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a8c:	21848513          	addi	a0,s1,536
    80004a90:	ffffe097          	auipc	ra,0xffffe
    80004a94:	988080e7          	jalr	-1656(ra) # 80002418 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a98:	2204b783          	ld	a5,544(s1)
    80004a9c:	eb95                	bnez	a5,80004ad0 <pipeclose+0x64>
    release(&pi->lock);
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	276080e7          	jalr	630(ra) # 80000d16 <release>
    kfree((char*)pi);
    80004aa8:	8526                	mv	a0,s1
    80004aaa:	ffffc097          	auipc	ra,0xffffc
    80004aae:	fc8080e7          	jalr	-56(ra) # 80000a72 <kfree>
  } else
    release(&pi->lock);
}
    80004ab2:	60e2                	ld	ra,24(sp)
    80004ab4:	6442                	ld	s0,16(sp)
    80004ab6:	64a2                	ld	s1,8(sp)
    80004ab8:	6902                	ld	s2,0(sp)
    80004aba:	6105                	addi	sp,sp,32
    80004abc:	8082                	ret
    pi->readopen = 0;
    80004abe:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ac2:	21c48513          	addi	a0,s1,540
    80004ac6:	ffffe097          	auipc	ra,0xffffe
    80004aca:	952080e7          	jalr	-1710(ra) # 80002418 <wakeup>
    80004ace:	b7e9                	j	80004a98 <pipeclose+0x2c>
    release(&pi->lock);
    80004ad0:	8526                	mv	a0,s1
    80004ad2:	ffffc097          	auipc	ra,0xffffc
    80004ad6:	244080e7          	jalr	580(ra) # 80000d16 <release>
}
    80004ada:	bfe1                	j	80004ab2 <pipeclose+0x46>

0000000080004adc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004adc:	7119                	addi	sp,sp,-128
    80004ade:	fc86                	sd	ra,120(sp)
    80004ae0:	f8a2                	sd	s0,112(sp)
    80004ae2:	f4a6                	sd	s1,104(sp)
    80004ae4:	f0ca                	sd	s2,96(sp)
    80004ae6:	ecce                	sd	s3,88(sp)
    80004ae8:	e8d2                	sd	s4,80(sp)
    80004aea:	e4d6                	sd	s5,72(sp)
    80004aec:	e0da                	sd	s6,64(sp)
    80004aee:	fc5e                	sd	s7,56(sp)
    80004af0:	f862                	sd	s8,48(sp)
    80004af2:	f466                	sd	s9,40(sp)
    80004af4:	f06a                	sd	s10,32(sp)
    80004af6:	ec6e                	sd	s11,24(sp)
    80004af8:	0100                	addi	s0,sp,128
    80004afa:	84aa                	mv	s1,a0
    80004afc:	8d2e                	mv	s10,a1
    80004afe:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b00:	ffffd097          	auipc	ra,0xffffd
    80004b04:	f70080e7          	jalr	-144(ra) # 80001a70 <myproc>
    80004b08:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b0a:	8526                	mv	a0,s1
    80004b0c:	ffffc097          	auipc	ra,0xffffc
    80004b10:	156080e7          	jalr	342(ra) # 80000c62 <acquire>
  for(i = 0; i < n; i++){
    80004b14:	0d605f63          	blez	s6,80004bf2 <pipewrite+0x116>
    80004b18:	89a6                	mv	s3,s1
    80004b1a:	3b7d                	addiw	s6,s6,-1
    80004b1c:	1b02                	slli	s6,s6,0x20
    80004b1e:	020b5b13          	srli	s6,s6,0x20
    80004b22:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b24:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b28:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b2c:	5dfd                	li	s11,-1
    80004b2e:	000b8c9b          	sext.w	s9,s7
    80004b32:	8c66                	mv	s8,s9
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b34:	2184a783          	lw	a5,536(s1)
    80004b38:	21c4a703          	lw	a4,540(s1)
    80004b3c:	2007879b          	addiw	a5,a5,512
    80004b40:	06f71763          	bne	a4,a5,80004bae <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80004b44:	2204a783          	lw	a5,544(s1)
    80004b48:	cf8d                	beqz	a5,80004b82 <pipewrite+0xa6>
    80004b4a:	03092783          	lw	a5,48(s2)
    80004b4e:	eb95                	bnez	a5,80004b82 <pipewrite+0xa6>
      wakeup(&pi->nread);
    80004b50:	8556                	mv	a0,s5
    80004b52:	ffffe097          	auipc	ra,0xffffe
    80004b56:	8c6080e7          	jalr	-1850(ra) # 80002418 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b5a:	85ce                	mv	a1,s3
    80004b5c:	8552                	mv	a0,s4
    80004b5e:	ffffd097          	auipc	ra,0xffffd
    80004b62:	734080e7          	jalr	1844(ra) # 80002292 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b66:	2184a783          	lw	a5,536(s1)
    80004b6a:	21c4a703          	lw	a4,540(s1)
    80004b6e:	2007879b          	addiw	a5,a5,512
    80004b72:	02f71e63          	bne	a4,a5,80004bae <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80004b76:	2204a783          	lw	a5,544(s1)
    80004b7a:	c781                	beqz	a5,80004b82 <pipewrite+0xa6>
    80004b7c:	03092783          	lw	a5,48(s2)
    80004b80:	dbe1                	beqz	a5,80004b50 <pipewrite+0x74>
        release(&pi->lock);
    80004b82:	8526                	mv	a0,s1
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	192080e7          	jalr	402(ra) # 80000d16 <release>
        return -1;
    80004b8c:	5c7d                	li	s8,-1
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b8e:	8562                	mv	a0,s8
    80004b90:	70e6                	ld	ra,120(sp)
    80004b92:	7446                	ld	s0,112(sp)
    80004b94:	74a6                	ld	s1,104(sp)
    80004b96:	7906                	ld	s2,96(sp)
    80004b98:	69e6                	ld	s3,88(sp)
    80004b9a:	6a46                	ld	s4,80(sp)
    80004b9c:	6aa6                	ld	s5,72(sp)
    80004b9e:	6b06                	ld	s6,64(sp)
    80004ba0:	7be2                	ld	s7,56(sp)
    80004ba2:	7c42                	ld	s8,48(sp)
    80004ba4:	7ca2                	ld	s9,40(sp)
    80004ba6:	7d02                	ld	s10,32(sp)
    80004ba8:	6de2                	ld	s11,24(sp)
    80004baa:	6109                	addi	sp,sp,128
    80004bac:	8082                	ret
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bae:	4685                	li	a3,1
    80004bb0:	01ab8633          	add	a2,s7,s10
    80004bb4:	f8f40593          	addi	a1,s0,-113
    80004bb8:	05093503          	ld	a0,80(s2)
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	c1c080e7          	jalr	-996(ra) # 800017d8 <copyin>
    80004bc4:	03b50863          	beq	a0,s11,80004bf4 <pipewrite+0x118>
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004bc8:	21c4a783          	lw	a5,540(s1)
    80004bcc:	0017871b          	addiw	a4,a5,1
    80004bd0:	20e4ae23          	sw	a4,540(s1)
    80004bd4:	1ff7f793          	andi	a5,a5,511
    80004bd8:	97a6                	add	a5,a5,s1
    80004bda:	f8f44703          	lbu	a4,-113(s0)
    80004bde:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004be2:	001c8c1b          	addiw	s8,s9,1
    80004be6:	001b8793          	addi	a5,s7,1
    80004bea:	016b8563          	beq	s7,s6,80004bf4 <pipewrite+0x118>
    80004bee:	8bbe                	mv	s7,a5
    80004bf0:	bf3d                	j	80004b2e <pipewrite+0x52>
    80004bf2:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004bf4:	21848513          	addi	a0,s1,536
    80004bf8:	ffffe097          	auipc	ra,0xffffe
    80004bfc:	820080e7          	jalr	-2016(ra) # 80002418 <wakeup>
  release(&pi->lock);
    80004c00:	8526                	mv	a0,s1
    80004c02:	ffffc097          	auipc	ra,0xffffc
    80004c06:	114080e7          	jalr	276(ra) # 80000d16 <release>
  return i;
    80004c0a:	b751                	j	80004b8e <pipewrite+0xb2>

0000000080004c0c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c0c:	715d                	addi	sp,sp,-80
    80004c0e:	e486                	sd	ra,72(sp)
    80004c10:	e0a2                	sd	s0,64(sp)
    80004c12:	fc26                	sd	s1,56(sp)
    80004c14:	f84a                	sd	s2,48(sp)
    80004c16:	f44e                	sd	s3,40(sp)
    80004c18:	f052                	sd	s4,32(sp)
    80004c1a:	ec56                	sd	s5,24(sp)
    80004c1c:	e85a                	sd	s6,16(sp)
    80004c1e:	0880                	addi	s0,sp,80
    80004c20:	84aa                	mv	s1,a0
    80004c22:	89ae                	mv	s3,a1
    80004c24:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c26:	ffffd097          	auipc	ra,0xffffd
    80004c2a:	e4a080e7          	jalr	-438(ra) # 80001a70 <myproc>
    80004c2e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c30:	8526                	mv	a0,s1
    80004c32:	ffffc097          	auipc	ra,0xffffc
    80004c36:	030080e7          	jalr	48(ra) # 80000c62 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c3a:	2184a703          	lw	a4,536(s1)
    80004c3e:	21c4a783          	lw	a5,540(s1)
    80004c42:	06f71b63          	bne	a4,a5,80004cb8 <piperead+0xac>
    80004c46:	8926                	mv	s2,s1
    80004c48:	2244a783          	lw	a5,548(s1)
    80004c4c:	cf9d                	beqz	a5,80004c8a <piperead+0x7e>
    if(pr->killed){
    80004c4e:	030a2783          	lw	a5,48(s4)
    80004c52:	e78d                	bnez	a5,80004c7c <piperead+0x70>
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c54:	21848b13          	addi	s6,s1,536
    80004c58:	85ca                	mv	a1,s2
    80004c5a:	855a                	mv	a0,s6
    80004c5c:	ffffd097          	auipc	ra,0xffffd
    80004c60:	636080e7          	jalr	1590(ra) # 80002292 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c64:	2184a703          	lw	a4,536(s1)
    80004c68:	21c4a783          	lw	a5,540(s1)
    80004c6c:	04f71663          	bne	a4,a5,80004cb8 <piperead+0xac>
    80004c70:	2244a783          	lw	a5,548(s1)
    80004c74:	cb99                	beqz	a5,80004c8a <piperead+0x7e>
    if(pr->killed){
    80004c76:	030a2783          	lw	a5,48(s4)
    80004c7a:	dff9                	beqz	a5,80004c58 <piperead+0x4c>
      release(&pi->lock);
    80004c7c:	8526                	mv	a0,s1
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	098080e7          	jalr	152(ra) # 80000d16 <release>
      return -1;
    80004c86:	597d                	li	s2,-1
    80004c88:	a829                	j	80004ca2 <piperead+0x96>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    if(pi->nread == pi->nwrite)
    80004c8a:	4901                	li	s2,0
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c8c:	21c48513          	addi	a0,s1,540
    80004c90:	ffffd097          	auipc	ra,0xffffd
    80004c94:	788080e7          	jalr	1928(ra) # 80002418 <wakeup>
  release(&pi->lock);
    80004c98:	8526                	mv	a0,s1
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	07c080e7          	jalr	124(ra) # 80000d16 <release>
  return i;
}
    80004ca2:	854a                	mv	a0,s2
    80004ca4:	60a6                	ld	ra,72(sp)
    80004ca6:	6406                	ld	s0,64(sp)
    80004ca8:	74e2                	ld	s1,56(sp)
    80004caa:	7942                	ld	s2,48(sp)
    80004cac:	79a2                	ld	s3,40(sp)
    80004cae:	7a02                	ld	s4,32(sp)
    80004cb0:	6ae2                	ld	s5,24(sp)
    80004cb2:	6b42                	ld	s6,16(sp)
    80004cb4:	6161                	addi	sp,sp,80
    80004cb6:	8082                	ret
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb8:	4901                	li	s2,0
    80004cba:	fd5059e3          	blez	s5,80004c8c <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004cbe:	2184a783          	lw	a5,536(s1)
    80004cc2:	4901                	li	s2,0
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cc4:	5b7d                	li	s6,-1
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cc6:	0017871b          	addiw	a4,a5,1
    80004cca:	20e4ac23          	sw	a4,536(s1)
    80004cce:	1ff7f793          	andi	a5,a5,511
    80004cd2:	97a6                	add	a5,a5,s1
    80004cd4:	0187c783          	lbu	a5,24(a5)
    80004cd8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cdc:	4685                	li	a3,1
    80004cde:	fbf40613          	addi	a2,s0,-65
    80004ce2:	85ce                	mv	a1,s3
    80004ce4:	050a3503          	ld	a0,80(s4)
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	a64080e7          	jalr	-1436(ra) # 8000174c <copyout>
    80004cf0:	f9650ee3          	beq	a0,s6,80004c8c <piperead+0x80>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cf4:	2905                	addiw	s2,s2,1
    80004cf6:	f92a8be3          	beq	s5,s2,80004c8c <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004cfa:	2184a783          	lw	a5,536(s1)
    80004cfe:	0985                	addi	s3,s3,1
    80004d00:	21c4a703          	lw	a4,540(s1)
    80004d04:	fcf711e3          	bne	a4,a5,80004cc6 <piperead+0xba>
    80004d08:	b751                	j	80004c8c <piperead+0x80>

0000000080004d0a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d0a:	de010113          	addi	sp,sp,-544
    80004d0e:	20113c23          	sd	ra,536(sp)
    80004d12:	20813823          	sd	s0,528(sp)
    80004d16:	20913423          	sd	s1,520(sp)
    80004d1a:	21213023          	sd	s2,512(sp)
    80004d1e:	ffce                	sd	s3,504(sp)
    80004d20:	fbd2                	sd	s4,496(sp)
    80004d22:	f7d6                	sd	s5,488(sp)
    80004d24:	f3da                	sd	s6,480(sp)
    80004d26:	efde                	sd	s7,472(sp)
    80004d28:	ebe2                	sd	s8,464(sp)
    80004d2a:	e7e6                	sd	s9,456(sp)
    80004d2c:	e3ea                	sd	s10,448(sp)
    80004d2e:	ff6e                	sd	s11,440(sp)
    80004d30:	1400                	addi	s0,sp,544
    80004d32:	892a                	mv	s2,a0
    80004d34:	dea43823          	sd	a0,-528(s0)
    80004d38:	deb43c23          	sd	a1,-520(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d3c:	ffffd097          	auipc	ra,0xffffd
    80004d40:	d34080e7          	jalr	-716(ra) # 80001a70 <myproc>
    80004d44:	84aa                	mv	s1,a0

  begin_op();
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	402080e7          	jalr	1026(ra) # 80004148 <begin_op>

  if((ip = namei(path)) == 0){
    80004d4e:	854a                	mv	a0,s2
    80004d50:	fffff097          	auipc	ra,0xfffff
    80004d54:	1ea080e7          	jalr	490(ra) # 80003f3a <namei>
    80004d58:	c93d                	beqz	a0,80004dce <exec+0xc4>
    80004d5a:	892a                	mv	s2,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	a24080e7          	jalr	-1500(ra) # 80003780 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d64:	04000713          	li	a4,64
    80004d68:	4681                	li	a3,0
    80004d6a:	e4840613          	addi	a2,s0,-440
    80004d6e:	4581                	li	a1,0
    80004d70:	854a                	mv	a0,s2
    80004d72:	fffff097          	auipc	ra,0xfffff
    80004d76:	cc4080e7          	jalr	-828(ra) # 80003a36 <readi>
    80004d7a:	04000793          	li	a5,64
    80004d7e:	00f51a63          	bne	a0,a5,80004d92 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d82:	e4842703          	lw	a4,-440(s0)
    80004d86:	464c47b7          	lui	a5,0x464c4
    80004d8a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d8e:	04f70663          	beq	a4,a5,80004dda <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d92:	854a                	mv	a0,s2
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	c50080e7          	jalr	-944(ra) # 800039e4 <iunlockput>
    end_op();
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	42c080e7          	jalr	1068(ra) # 800041c8 <end_op>
  }
  return -1;
    80004da4:	557d                	li	a0,-1
}
    80004da6:	21813083          	ld	ra,536(sp)
    80004daa:	21013403          	ld	s0,528(sp)
    80004dae:	20813483          	ld	s1,520(sp)
    80004db2:	20013903          	ld	s2,512(sp)
    80004db6:	79fe                	ld	s3,504(sp)
    80004db8:	7a5e                	ld	s4,496(sp)
    80004dba:	7abe                	ld	s5,488(sp)
    80004dbc:	7b1e                	ld	s6,480(sp)
    80004dbe:	6bfe                	ld	s7,472(sp)
    80004dc0:	6c5e                	ld	s8,464(sp)
    80004dc2:	6cbe                	ld	s9,456(sp)
    80004dc4:	6d1e                	ld	s10,448(sp)
    80004dc6:	7dfa                	ld	s11,440(sp)
    80004dc8:	22010113          	addi	sp,sp,544
    80004dcc:	8082                	ret
    end_op();
    80004dce:	fffff097          	auipc	ra,0xfffff
    80004dd2:	3fa080e7          	jalr	1018(ra) # 800041c8 <end_op>
    return -1;
    80004dd6:	557d                	li	a0,-1
    80004dd8:	b7f9                	j	80004da6 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dda:	8526                	mv	a0,s1
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	d5a080e7          	jalr	-678(ra) # 80001b36 <proc_pagetable>
    80004de4:	e0a43423          	sd	a0,-504(s0)
    80004de8:	d54d                	beqz	a0,80004d92 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dea:	e6842983          	lw	s3,-408(s0)
    80004dee:	e8045783          	lhu	a5,-384(s0)
    80004df2:	c7ad                	beqz	a5,80004e5c <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004df4:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004df6:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004df8:	6c05                	lui	s8,0x1
    80004dfa:	fffc0793          	addi	a5,s8,-1 # fff <_entry-0x7ffff001>
    80004dfe:	def43423          	sd	a5,-536(s0)
    80004e02:	7cfd                	lui	s9,0xfffff
    80004e04:	ac1d                	j	8000503a <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e06:	00004517          	auipc	a0,0x4
    80004e0a:	90a50513          	addi	a0,a0,-1782 # 80008710 <sysnames+0x258>
    80004e0e:	ffffb097          	auipc	ra,0xffffb
    80004e12:	766080e7          	jalr	1894(ra) # 80000574 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e16:	8756                	mv	a4,s5
    80004e18:	009d86bb          	addw	a3,s11,s1
    80004e1c:	4581                	li	a1,0
    80004e1e:	854a                	mv	a0,s2
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	c16080e7          	jalr	-1002(ra) # 80003a36 <readi>
    80004e28:	2501                	sext.w	a0,a0
    80004e2a:	1aaa9e63          	bne	s5,a0,80004fe6 <exec+0x2dc>
  for(i = 0; i < sz; i += PGSIZE){
    80004e2e:	6785                	lui	a5,0x1
    80004e30:	9cbd                	addw	s1,s1,a5
    80004e32:	014c8a3b          	addw	s4,s9,s4
    80004e36:	1f74f963          	bleu	s7,s1,80005028 <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    80004e3a:	02049593          	slli	a1,s1,0x20
    80004e3e:	9181                	srli	a1,a1,0x20
    80004e40:	95ea                	add	a1,a1,s10
    80004e42:	e0843503          	ld	a0,-504(s0)
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	2ce080e7          	jalr	718(ra) # 80001114 <walkaddr>
    80004e4e:	862a                	mv	a2,a0
    if(pa == 0)
    80004e50:	d95d                	beqz	a0,80004e06 <exec+0xfc>
      n = PGSIZE;
    80004e52:	8ae2                	mv	s5,s8
    if(sz - i < PGSIZE)
    80004e54:	fd8a71e3          	bleu	s8,s4,80004e16 <exec+0x10c>
      n = sz - i;
    80004e58:	8ad2                	mv	s5,s4
    80004e5a:	bf75                	j	80004e16 <exec+0x10c>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e5c:	4481                	li	s1,0
  iunlockput(ip);
    80004e5e:	854a                	mv	a0,s2
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	b84080e7          	jalr	-1148(ra) # 800039e4 <iunlockput>
  end_op();
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	360080e7          	jalr	864(ra) # 800041c8 <end_op>
  p = myproc();
    80004e70:	ffffd097          	auipc	ra,0xffffd
    80004e74:	c00080e7          	jalr	-1024(ra) # 80001a70 <myproc>
    80004e78:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e7a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e7e:	6785                	lui	a5,0x1
    80004e80:	17fd                	addi	a5,a5,-1
    80004e82:	94be                	add	s1,s1,a5
    80004e84:	77fd                	lui	a5,0xfffff
    80004e86:	8fe5                	and	a5,a5,s1
    80004e88:	e0f43023          	sd	a5,-512(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e8c:	6609                	lui	a2,0x2
    80004e8e:	963e                	add	a2,a2,a5
    80004e90:	85be                	mv	a1,a5
    80004e92:	e0843483          	ld	s1,-504(s0)
    80004e96:	8526                	mv	a0,s1
    80004e98:	ffffc097          	auipc	ra,0xffffc
    80004e9c:	664080e7          	jalr	1636(ra) # 800014fc <uvmalloc>
    80004ea0:	8b2a                	mv	s6,a0
  ip = 0;
    80004ea2:	4901                	li	s2,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ea4:	14050163          	beqz	a0,80004fe6 <exec+0x2dc>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ea8:	75f9                	lui	a1,0xffffe
    80004eaa:	95aa                	add	a1,a1,a0
    80004eac:	8526                	mv	a0,s1
    80004eae:	ffffd097          	auipc	ra,0xffffd
    80004eb2:	86c080e7          	jalr	-1940(ra) # 8000171a <uvmclear>
  stackbase = sp - PGSIZE;
    80004eb6:	7bfd                	lui	s7,0xfffff
    80004eb8:	9bda                	add	s7,s7,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eba:	df843783          	ld	a5,-520(s0)
    80004ebe:	6388                	ld	a0,0(a5)
    80004ec0:	c925                	beqz	a0,80004f30 <exec+0x226>
    80004ec2:	e8840993          	addi	s3,s0,-376
    80004ec6:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80004eca:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ecc:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004ece:	ffffc097          	auipc	ra,0xffffc
    80004ed2:	03a080e7          	jalr	58(ra) # 80000f08 <strlen>
    80004ed6:	2505                	addiw	a0,a0,1
    80004ed8:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004edc:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ee0:	13796863          	bltu	s2,s7,80005010 <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ee4:	df843c83          	ld	s9,-520(s0)
    80004ee8:	000cba03          	ld	s4,0(s9) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80004eec:	8552                	mv	a0,s4
    80004eee:	ffffc097          	auipc	ra,0xffffc
    80004ef2:	01a080e7          	jalr	26(ra) # 80000f08 <strlen>
    80004ef6:	0015069b          	addiw	a3,a0,1
    80004efa:	8652                	mv	a2,s4
    80004efc:	85ca                	mv	a1,s2
    80004efe:	e0843503          	ld	a0,-504(s0)
    80004f02:	ffffd097          	auipc	ra,0xffffd
    80004f06:	84a080e7          	jalr	-1974(ra) # 8000174c <copyout>
    80004f0a:	10054763          	bltz	a0,80005018 <exec+0x30e>
    ustack[argc] = sp;
    80004f0e:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f12:	0485                	addi	s1,s1,1
    80004f14:	008c8793          	addi	a5,s9,8
    80004f18:	def43c23          	sd	a5,-520(s0)
    80004f1c:	008cb503          	ld	a0,8(s9)
    80004f20:	c911                	beqz	a0,80004f34 <exec+0x22a>
    if(argc >= MAXARG)
    80004f22:	09a1                	addi	s3,s3,8
    80004f24:	fb8995e3          	bne	s3,s8,80004ece <exec+0x1c4>
  sz = sz1;
    80004f28:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004f2c:	4901                	li	s2,0
    80004f2e:	a865                	j	80004fe6 <exec+0x2dc>
  sp = sz;
    80004f30:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f32:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f34:	00349793          	slli	a5,s1,0x3
    80004f38:	f9040713          	addi	a4,s0,-112
    80004f3c:	97ba                	add	a5,a5,a4
    80004f3e:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd8ef8>
  sp -= (argc+1) * sizeof(uint64);
    80004f42:	00148693          	addi	a3,s1,1
    80004f46:	068e                	slli	a3,a3,0x3
    80004f48:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f4c:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f50:	01797663          	bleu	s7,s2,80004f5c <exec+0x252>
  sz = sz1;
    80004f54:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004f58:	4901                	li	s2,0
    80004f5a:	a071                	j	80004fe6 <exec+0x2dc>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f5c:	e8840613          	addi	a2,s0,-376
    80004f60:	85ca                	mv	a1,s2
    80004f62:	e0843503          	ld	a0,-504(s0)
    80004f66:	ffffc097          	auipc	ra,0xffffc
    80004f6a:	7e6080e7          	jalr	2022(ra) # 8000174c <copyout>
    80004f6e:	0a054963          	bltz	a0,80005020 <exec+0x316>
  p->trapframe->a1 = sp;
    80004f72:	058ab783          	ld	a5,88(s5)
    80004f76:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f7a:	df043783          	ld	a5,-528(s0)
    80004f7e:	0007c703          	lbu	a4,0(a5)
    80004f82:	cf11                	beqz	a4,80004f9e <exec+0x294>
    80004f84:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f86:	02f00693          	li	a3,47
    80004f8a:	a029                	j	80004f94 <exec+0x28a>
  for(last=s=path; *s; s++)
    80004f8c:	0785                	addi	a5,a5,1
    80004f8e:	fff7c703          	lbu	a4,-1(a5)
    80004f92:	c711                	beqz	a4,80004f9e <exec+0x294>
    if(*s == '/')
    80004f94:	fed71ce3          	bne	a4,a3,80004f8c <exec+0x282>
      last = s+1;
    80004f98:	def43823          	sd	a5,-528(s0)
    80004f9c:	bfc5                	j	80004f8c <exec+0x282>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f9e:	4641                	li	a2,16
    80004fa0:	df043583          	ld	a1,-528(s0)
    80004fa4:	158a8513          	addi	a0,s5,344
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	f2e080e7          	jalr	-210(ra) # 80000ed6 <safestrcpy>
  oldpagetable = p->pagetable;
    80004fb0:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004fb4:	e0843783          	ld	a5,-504(s0)
    80004fb8:	04fab823          	sd	a5,80(s5)
  p->sz = sz;
    80004fbc:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fc0:	058ab783          	ld	a5,88(s5)
    80004fc4:	e6043703          	ld	a4,-416(s0)
    80004fc8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004fca:	058ab783          	ld	a5,88(s5)
    80004fce:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fd2:	85ea                	mv	a1,s10
    80004fd4:	ffffd097          	auipc	ra,0xffffd
    80004fd8:	bfe080e7          	jalr	-1026(ra) # 80001bd2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fdc:	0004851b          	sext.w	a0,s1
    80004fe0:	b3d9                	j	80004da6 <exec+0x9c>
    80004fe2:	e0943023          	sd	s1,-512(s0)
    proc_freepagetable(pagetable, sz);
    80004fe6:	e0043583          	ld	a1,-512(s0)
    80004fea:	e0843503          	ld	a0,-504(s0)
    80004fee:	ffffd097          	auipc	ra,0xffffd
    80004ff2:	be4080e7          	jalr	-1052(ra) # 80001bd2 <proc_freepagetable>
  if(ip){
    80004ff6:	d8091ee3          	bnez	s2,80004d92 <exec+0x88>
  return -1;
    80004ffa:	557d                	li	a0,-1
    80004ffc:	b36d                	j	80004da6 <exec+0x9c>
    80004ffe:	e0943023          	sd	s1,-512(s0)
    80005002:	b7d5                	j	80004fe6 <exec+0x2dc>
    80005004:	e0943023          	sd	s1,-512(s0)
    80005008:	bff9                	j	80004fe6 <exec+0x2dc>
    8000500a:	e0943023          	sd	s1,-512(s0)
    8000500e:	bfe1                	j	80004fe6 <exec+0x2dc>
  sz = sz1;
    80005010:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005014:	4901                	li	s2,0
    80005016:	bfc1                	j	80004fe6 <exec+0x2dc>
  sz = sz1;
    80005018:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    8000501c:	4901                	li	s2,0
    8000501e:	b7e1                	j	80004fe6 <exec+0x2dc>
  sz = sz1;
    80005020:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80005024:	4901                	li	s2,0
    80005026:	b7c1                	j	80004fe6 <exec+0x2dc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005028:	e0043483          	ld	s1,-512(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000502c:	2b05                	addiw	s6,s6,1
    8000502e:	0389899b          	addiw	s3,s3,56
    80005032:	e8045783          	lhu	a5,-384(s0)
    80005036:	e2fb54e3          	ble	a5,s6,80004e5e <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000503a:	2981                	sext.w	s3,s3
    8000503c:	03800713          	li	a4,56
    80005040:	86ce                	mv	a3,s3
    80005042:	e1040613          	addi	a2,s0,-496
    80005046:	4581                	li	a1,0
    80005048:	854a                	mv	a0,s2
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	9ec080e7          	jalr	-1556(ra) # 80003a36 <readi>
    80005052:	03800793          	li	a5,56
    80005056:	f8f516e3          	bne	a0,a5,80004fe2 <exec+0x2d8>
    if(ph.type != ELF_PROG_LOAD)
    8000505a:	e1042783          	lw	a5,-496(s0)
    8000505e:	4705                	li	a4,1
    80005060:	fce796e3          	bne	a5,a4,8000502c <exec+0x322>
    if(ph.memsz < ph.filesz)
    80005064:	e3843603          	ld	a2,-456(s0)
    80005068:	e3043783          	ld	a5,-464(s0)
    8000506c:	f8f669e3          	bltu	a2,a5,80004ffe <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005070:	e2043783          	ld	a5,-480(s0)
    80005074:	963e                	add	a2,a2,a5
    80005076:	f8f667e3          	bltu	a2,a5,80005004 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000507a:	85a6                	mv	a1,s1
    8000507c:	e0843503          	ld	a0,-504(s0)
    80005080:	ffffc097          	auipc	ra,0xffffc
    80005084:	47c080e7          	jalr	1148(ra) # 800014fc <uvmalloc>
    80005088:	e0a43023          	sd	a0,-512(s0)
    8000508c:	dd3d                	beqz	a0,8000500a <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    8000508e:	e2043d03          	ld	s10,-480(s0)
    80005092:	de843783          	ld	a5,-536(s0)
    80005096:	00fd77b3          	and	a5,s10,a5
    8000509a:	f7b1                	bnez	a5,80004fe6 <exec+0x2dc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000509c:	e1842d83          	lw	s11,-488(s0)
    800050a0:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050a4:	f80b82e3          	beqz	s7,80005028 <exec+0x31e>
    800050a8:	8a5e                	mv	s4,s7
    800050aa:	4481                	li	s1,0
    800050ac:	b379                	j	80004e3a <exec+0x130>

00000000800050ae <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050ae:	7179                	addi	sp,sp,-48
    800050b0:	f406                	sd	ra,40(sp)
    800050b2:	f022                	sd	s0,32(sp)
    800050b4:	ec26                	sd	s1,24(sp)
    800050b6:	e84a                	sd	s2,16(sp)
    800050b8:	1800                	addi	s0,sp,48
    800050ba:	892e                	mv	s2,a1
    800050bc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050be:	fdc40593          	addi	a1,s0,-36
    800050c2:	ffffe097          	auipc	ra,0xffffe
    800050c6:	a86080e7          	jalr	-1402(ra) # 80002b48 <argint>
    800050ca:	04054063          	bltz	a0,8000510a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050ce:	fdc42703          	lw	a4,-36(s0)
    800050d2:	47bd                	li	a5,15
    800050d4:	02e7ed63          	bltu	a5,a4,8000510e <argfd+0x60>
    800050d8:	ffffd097          	auipc	ra,0xffffd
    800050dc:	998080e7          	jalr	-1640(ra) # 80001a70 <myproc>
    800050e0:	fdc42703          	lw	a4,-36(s0)
    800050e4:	01a70793          	addi	a5,a4,26
    800050e8:	078e                	slli	a5,a5,0x3
    800050ea:	953e                	add	a0,a0,a5
    800050ec:	611c                	ld	a5,0(a0)
    800050ee:	c395                	beqz	a5,80005112 <argfd+0x64>
    return -1;
  if(pfd)
    800050f0:	00090463          	beqz	s2,800050f8 <argfd+0x4a>
    *pfd = fd;
    800050f4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050f8:	4501                	li	a0,0
  if(pf)
    800050fa:	c091                	beqz	s1,800050fe <argfd+0x50>
    *pf = f;
    800050fc:	e09c                	sd	a5,0(s1)
}
    800050fe:	70a2                	ld	ra,40(sp)
    80005100:	7402                	ld	s0,32(sp)
    80005102:	64e2                	ld	s1,24(sp)
    80005104:	6942                	ld	s2,16(sp)
    80005106:	6145                	addi	sp,sp,48
    80005108:	8082                	ret
    return -1;
    8000510a:	557d                	li	a0,-1
    8000510c:	bfcd                	j	800050fe <argfd+0x50>
    return -1;
    8000510e:	557d                	li	a0,-1
    80005110:	b7fd                	j	800050fe <argfd+0x50>
    80005112:	557d                	li	a0,-1
    80005114:	b7ed                	j	800050fe <argfd+0x50>

0000000080005116 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005116:	1101                	addi	sp,sp,-32
    80005118:	ec06                	sd	ra,24(sp)
    8000511a:	e822                	sd	s0,16(sp)
    8000511c:	e426                	sd	s1,8(sp)
    8000511e:	1000                	addi	s0,sp,32
    80005120:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005122:	ffffd097          	auipc	ra,0xffffd
    80005126:	94e080e7          	jalr	-1714(ra) # 80001a70 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){
    8000512a:	697c                	ld	a5,208(a0)
    8000512c:	c395                	beqz	a5,80005150 <fdalloc+0x3a>
    8000512e:	0d850713          	addi	a4,a0,216
  for(fd = 0; fd < NOFILE; fd++){
    80005132:	4785                	li	a5,1
    80005134:	4641                	li	a2,16
    if(p->ofile[fd] == 0){
    80005136:	6314                	ld	a3,0(a4)
    80005138:	ce89                	beqz	a3,80005152 <fdalloc+0x3c>
  for(fd = 0; fd < NOFILE; fd++){
    8000513a:	2785                	addiw	a5,a5,1
    8000513c:	0721                	addi	a4,a4,8
    8000513e:	fec79ce3          	bne	a5,a2,80005136 <fdalloc+0x20>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005142:	57fd                	li	a5,-1
}
    80005144:	853e                	mv	a0,a5
    80005146:	60e2                	ld	ra,24(sp)
    80005148:	6442                	ld	s0,16(sp)
    8000514a:	64a2                	ld	s1,8(sp)
    8000514c:	6105                	addi	sp,sp,32
    8000514e:	8082                	ret
  for(fd = 0; fd < NOFILE; fd++){
    80005150:	4781                	li	a5,0
      p->ofile[fd] = f;
    80005152:	01a78713          	addi	a4,a5,26
    80005156:	070e                	slli	a4,a4,0x3
    80005158:	953a                	add	a0,a0,a4
    8000515a:	e104                	sd	s1,0(a0)
      return fd;
    8000515c:	b7e5                	j	80005144 <fdalloc+0x2e>

000000008000515e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000515e:	715d                	addi	sp,sp,-80
    80005160:	e486                	sd	ra,72(sp)
    80005162:	e0a2                	sd	s0,64(sp)
    80005164:	fc26                	sd	s1,56(sp)
    80005166:	f84a                	sd	s2,48(sp)
    80005168:	f44e                	sd	s3,40(sp)
    8000516a:	f052                	sd	s4,32(sp)
    8000516c:	ec56                	sd	s5,24(sp)
    8000516e:	0880                	addi	s0,sp,80
    80005170:	89ae                	mv	s3,a1
    80005172:	8ab2                	mv	s5,a2
    80005174:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005176:	fb040593          	addi	a1,s0,-80
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	dde080e7          	jalr	-546(ra) # 80003f58 <nameiparent>
    80005182:	892a                	mv	s2,a0
    80005184:	12050f63          	beqz	a0,800052c2 <create+0x164>
    return 0;

  ilock(dp);
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	5f8080e7          	jalr	1528(ra) # 80003780 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005190:	4601                	li	a2,0
    80005192:	fb040593          	addi	a1,s0,-80
    80005196:	854a                	mv	a0,s2
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	ac8080e7          	jalr	-1336(ra) # 80003c60 <dirlookup>
    800051a0:	84aa                	mv	s1,a0
    800051a2:	c921                	beqz	a0,800051f2 <create+0x94>
    iunlockput(dp);
    800051a4:	854a                	mv	a0,s2
    800051a6:	fffff097          	auipc	ra,0xfffff
    800051aa:	83e080e7          	jalr	-1986(ra) # 800039e4 <iunlockput>
    ilock(ip);
    800051ae:	8526                	mv	a0,s1
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	5d0080e7          	jalr	1488(ra) # 80003780 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051b8:	2981                	sext.w	s3,s3
    800051ba:	4789                	li	a5,2
    800051bc:	02f99463          	bne	s3,a5,800051e4 <create+0x86>
    800051c0:	0444d783          	lhu	a5,68(s1)
    800051c4:	37f9                	addiw	a5,a5,-2
    800051c6:	17c2                	slli	a5,a5,0x30
    800051c8:	93c1                	srli	a5,a5,0x30
    800051ca:	4705                	li	a4,1
    800051cc:	00f76c63          	bltu	a4,a5,800051e4 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051d0:	8526                	mv	a0,s1
    800051d2:	60a6                	ld	ra,72(sp)
    800051d4:	6406                	ld	s0,64(sp)
    800051d6:	74e2                	ld	s1,56(sp)
    800051d8:	7942                	ld	s2,48(sp)
    800051da:	79a2                	ld	s3,40(sp)
    800051dc:	7a02                	ld	s4,32(sp)
    800051de:	6ae2                	ld	s5,24(sp)
    800051e0:	6161                	addi	sp,sp,80
    800051e2:	8082                	ret
    iunlockput(ip);
    800051e4:	8526                	mv	a0,s1
    800051e6:	ffffe097          	auipc	ra,0xffffe
    800051ea:	7fe080e7          	jalr	2046(ra) # 800039e4 <iunlockput>
    return 0;
    800051ee:	4481                	li	s1,0
    800051f0:	b7c5                	j	800051d0 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051f2:	85ce                	mv	a1,s3
    800051f4:	00092503          	lw	a0,0(s2)
    800051f8:	ffffe097          	auipc	ra,0xffffe
    800051fc:	3ec080e7          	jalr	1004(ra) # 800035e4 <ialloc>
    80005200:	84aa                	mv	s1,a0
    80005202:	c529                	beqz	a0,8000524c <create+0xee>
  ilock(ip);
    80005204:	ffffe097          	auipc	ra,0xffffe
    80005208:	57c080e7          	jalr	1404(ra) # 80003780 <ilock>
  ip->major = major;
    8000520c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005210:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005214:	4785                	li	a5,1
    80005216:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000521a:	8526                	mv	a0,s1
    8000521c:	ffffe097          	auipc	ra,0xffffe
    80005220:	498080e7          	jalr	1176(ra) # 800036b4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005224:	2981                	sext.w	s3,s3
    80005226:	4785                	li	a5,1
    80005228:	02f98a63          	beq	s3,a5,8000525c <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000522c:	40d0                	lw	a2,4(s1)
    8000522e:	fb040593          	addi	a1,s0,-80
    80005232:	854a                	mv	a0,s2
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	c44080e7          	jalr	-956(ra) # 80003e78 <dirlink>
    8000523c:	06054b63          	bltz	a0,800052b2 <create+0x154>
  iunlockput(dp);
    80005240:	854a                	mv	a0,s2
    80005242:	ffffe097          	auipc	ra,0xffffe
    80005246:	7a2080e7          	jalr	1954(ra) # 800039e4 <iunlockput>
  return ip;
    8000524a:	b759                	j	800051d0 <create+0x72>
    panic("create: ialloc");
    8000524c:	00003517          	auipc	a0,0x3
    80005250:	4e450513          	addi	a0,a0,1252 # 80008730 <sysnames+0x278>
    80005254:	ffffb097          	auipc	ra,0xffffb
    80005258:	320080e7          	jalr	800(ra) # 80000574 <panic>
    dp->nlink++;  // for ".."
    8000525c:	04a95783          	lhu	a5,74(s2)
    80005260:	2785                	addiw	a5,a5,1
    80005262:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005266:	854a                	mv	a0,s2
    80005268:	ffffe097          	auipc	ra,0xffffe
    8000526c:	44c080e7          	jalr	1100(ra) # 800036b4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005270:	40d0                	lw	a2,4(s1)
    80005272:	00003597          	auipc	a1,0x3
    80005276:	4ce58593          	addi	a1,a1,1230 # 80008740 <sysnames+0x288>
    8000527a:	8526                	mv	a0,s1
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	bfc080e7          	jalr	-1028(ra) # 80003e78 <dirlink>
    80005284:	00054f63          	bltz	a0,800052a2 <create+0x144>
    80005288:	00492603          	lw	a2,4(s2)
    8000528c:	00003597          	auipc	a1,0x3
    80005290:	4bc58593          	addi	a1,a1,1212 # 80008748 <sysnames+0x290>
    80005294:	8526                	mv	a0,s1
    80005296:	fffff097          	auipc	ra,0xfffff
    8000529a:	be2080e7          	jalr	-1054(ra) # 80003e78 <dirlink>
    8000529e:	f80557e3          	bgez	a0,8000522c <create+0xce>
      panic("create dots");
    800052a2:	00003517          	auipc	a0,0x3
    800052a6:	4ae50513          	addi	a0,a0,1198 # 80008750 <sysnames+0x298>
    800052aa:	ffffb097          	auipc	ra,0xffffb
    800052ae:	2ca080e7          	jalr	714(ra) # 80000574 <panic>
    panic("create: dirlink");
    800052b2:	00003517          	auipc	a0,0x3
    800052b6:	4ae50513          	addi	a0,a0,1198 # 80008760 <sysnames+0x2a8>
    800052ba:	ffffb097          	auipc	ra,0xffffb
    800052be:	2ba080e7          	jalr	698(ra) # 80000574 <panic>
    return 0;
    800052c2:	84aa                	mv	s1,a0
    800052c4:	b731                	j	800051d0 <create+0x72>

00000000800052c6 <sys_dup>:
{
    800052c6:	7179                	addi	sp,sp,-48
    800052c8:	f406                	sd	ra,40(sp)
    800052ca:	f022                	sd	s0,32(sp)
    800052cc:	ec26                	sd	s1,24(sp)
    800052ce:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052d0:	fd840613          	addi	a2,s0,-40
    800052d4:	4581                	li	a1,0
    800052d6:	4501                	li	a0,0
    800052d8:	00000097          	auipc	ra,0x0
    800052dc:	dd6080e7          	jalr	-554(ra) # 800050ae <argfd>
    return -1;
    800052e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052e2:	02054363          	bltz	a0,80005308 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052e6:	fd843503          	ld	a0,-40(s0)
    800052ea:	00000097          	auipc	ra,0x0
    800052ee:	e2c080e7          	jalr	-468(ra) # 80005116 <fdalloc>
    800052f2:	84aa                	mv	s1,a0
    return -1;
    800052f4:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052f6:	00054963          	bltz	a0,80005308 <sys_dup+0x42>
  filedup(f);
    800052fa:	fd843503          	ld	a0,-40(s0)
    800052fe:	fffff097          	auipc	ra,0xfffff
    80005302:	2fa080e7          	jalr	762(ra) # 800045f8 <filedup>
  return fd;
    80005306:	87a6                	mv	a5,s1
}
    80005308:	853e                	mv	a0,a5
    8000530a:	70a2                	ld	ra,40(sp)
    8000530c:	7402                	ld	s0,32(sp)
    8000530e:	64e2                	ld	s1,24(sp)
    80005310:	6145                	addi	sp,sp,48
    80005312:	8082                	ret

0000000080005314 <sys_read>:
{
    80005314:	7179                	addi	sp,sp,-48
    80005316:	f406                	sd	ra,40(sp)
    80005318:	f022                	sd	s0,32(sp)
    8000531a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531c:	fe840613          	addi	a2,s0,-24
    80005320:	4581                	li	a1,0
    80005322:	4501                	li	a0,0
    80005324:	00000097          	auipc	ra,0x0
    80005328:	d8a080e7          	jalr	-630(ra) # 800050ae <argfd>
    return -1;
    8000532c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000532e:	04054163          	bltz	a0,80005370 <sys_read+0x5c>
    80005332:	fe440593          	addi	a1,s0,-28
    80005336:	4509                	li	a0,2
    80005338:	ffffe097          	auipc	ra,0xffffe
    8000533c:	810080e7          	jalr	-2032(ra) # 80002b48 <argint>
    return -1;
    80005340:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005342:	02054763          	bltz	a0,80005370 <sys_read+0x5c>
    80005346:	fd840593          	addi	a1,s0,-40
    8000534a:	4505                	li	a0,1
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	81e080e7          	jalr	-2018(ra) # 80002b6a <argaddr>
    return -1;
    80005354:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005356:	00054d63          	bltz	a0,80005370 <sys_read+0x5c>
  return fileread(f, p, n);
    8000535a:	fe442603          	lw	a2,-28(s0)
    8000535e:	fd843583          	ld	a1,-40(s0)
    80005362:	fe843503          	ld	a0,-24(s0)
    80005366:	fffff097          	auipc	ra,0xfffff
    8000536a:	41e080e7          	jalr	1054(ra) # 80004784 <fileread>
    8000536e:	87aa                	mv	a5,a0
}
    80005370:	853e                	mv	a0,a5
    80005372:	70a2                	ld	ra,40(sp)
    80005374:	7402                	ld	s0,32(sp)
    80005376:	6145                	addi	sp,sp,48
    80005378:	8082                	ret

000000008000537a <sys_write>:
{
    8000537a:	7179                	addi	sp,sp,-48
    8000537c:	f406                	sd	ra,40(sp)
    8000537e:	f022                	sd	s0,32(sp)
    80005380:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005382:	fe840613          	addi	a2,s0,-24
    80005386:	4581                	li	a1,0
    80005388:	4501                	li	a0,0
    8000538a:	00000097          	auipc	ra,0x0
    8000538e:	d24080e7          	jalr	-732(ra) # 800050ae <argfd>
    return -1;
    80005392:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005394:	04054163          	bltz	a0,800053d6 <sys_write+0x5c>
    80005398:	fe440593          	addi	a1,s0,-28
    8000539c:	4509                	li	a0,2
    8000539e:	ffffd097          	auipc	ra,0xffffd
    800053a2:	7aa080e7          	jalr	1962(ra) # 80002b48 <argint>
    return -1;
    800053a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053a8:	02054763          	bltz	a0,800053d6 <sys_write+0x5c>
    800053ac:	fd840593          	addi	a1,s0,-40
    800053b0:	4505                	li	a0,1
    800053b2:	ffffd097          	auipc	ra,0xffffd
    800053b6:	7b8080e7          	jalr	1976(ra) # 80002b6a <argaddr>
    return -1;
    800053ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053bc:	00054d63          	bltz	a0,800053d6 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053c0:	fe442603          	lw	a2,-28(s0)
    800053c4:	fd843583          	ld	a1,-40(s0)
    800053c8:	fe843503          	ld	a0,-24(s0)
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	47a080e7          	jalr	1146(ra) # 80004846 <filewrite>
    800053d4:	87aa                	mv	a5,a0
}
    800053d6:	853e                	mv	a0,a5
    800053d8:	70a2                	ld	ra,40(sp)
    800053da:	7402                	ld	s0,32(sp)
    800053dc:	6145                	addi	sp,sp,48
    800053de:	8082                	ret

00000000800053e0 <sys_close>:
{
    800053e0:	1101                	addi	sp,sp,-32
    800053e2:	ec06                	sd	ra,24(sp)
    800053e4:	e822                	sd	s0,16(sp)
    800053e6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053e8:	fe040613          	addi	a2,s0,-32
    800053ec:	fec40593          	addi	a1,s0,-20
    800053f0:	4501                	li	a0,0
    800053f2:	00000097          	auipc	ra,0x0
    800053f6:	cbc080e7          	jalr	-836(ra) # 800050ae <argfd>
    return -1;
    800053fa:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053fc:	02054463          	bltz	a0,80005424 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	670080e7          	jalr	1648(ra) # 80001a70 <myproc>
    80005408:	fec42783          	lw	a5,-20(s0)
    8000540c:	07e9                	addi	a5,a5,26
    8000540e:	078e                	slli	a5,a5,0x3
    80005410:	953e                	add	a0,a0,a5
    80005412:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005416:	fe043503          	ld	a0,-32(s0)
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	230080e7          	jalr	560(ra) # 8000464a <fileclose>
  return 0;
    80005422:	4781                	li	a5,0
}
    80005424:	853e                	mv	a0,a5
    80005426:	60e2                	ld	ra,24(sp)
    80005428:	6442                	ld	s0,16(sp)
    8000542a:	6105                	addi	sp,sp,32
    8000542c:	8082                	ret

000000008000542e <sys_fstat>:
{
    8000542e:	1101                	addi	sp,sp,-32
    80005430:	ec06                	sd	ra,24(sp)
    80005432:	e822                	sd	s0,16(sp)
    80005434:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005436:	fe840613          	addi	a2,s0,-24
    8000543a:	4581                	li	a1,0
    8000543c:	4501                	li	a0,0
    8000543e:	00000097          	auipc	ra,0x0
    80005442:	c70080e7          	jalr	-912(ra) # 800050ae <argfd>
    return -1;
    80005446:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005448:	02054563          	bltz	a0,80005472 <sys_fstat+0x44>
    8000544c:	fe040593          	addi	a1,s0,-32
    80005450:	4505                	li	a0,1
    80005452:	ffffd097          	auipc	ra,0xffffd
    80005456:	718080e7          	jalr	1816(ra) # 80002b6a <argaddr>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000545c:	00054b63          	bltz	a0,80005472 <sys_fstat+0x44>
  return filestat(f, st);
    80005460:	fe043583          	ld	a1,-32(s0)
    80005464:	fe843503          	ld	a0,-24(s0)
    80005468:	fffff097          	auipc	ra,0xfffff
    8000546c:	2aa080e7          	jalr	682(ra) # 80004712 <filestat>
    80005470:	87aa                	mv	a5,a0
}
    80005472:	853e                	mv	a0,a5
    80005474:	60e2                	ld	ra,24(sp)
    80005476:	6442                	ld	s0,16(sp)
    80005478:	6105                	addi	sp,sp,32
    8000547a:	8082                	ret

000000008000547c <sys_link>:
{
    8000547c:	7169                	addi	sp,sp,-304
    8000547e:	f606                	sd	ra,296(sp)
    80005480:	f222                	sd	s0,288(sp)
    80005482:	ee26                	sd	s1,280(sp)
    80005484:	ea4a                	sd	s2,272(sp)
    80005486:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005488:	08000613          	li	a2,128
    8000548c:	ed040593          	addi	a1,s0,-304
    80005490:	4501                	li	a0,0
    80005492:	ffffd097          	auipc	ra,0xffffd
    80005496:	6fa080e7          	jalr	1786(ra) # 80002b8c <argstr>
    return -1;
    8000549a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000549c:	10054e63          	bltz	a0,800055b8 <sys_link+0x13c>
    800054a0:	08000613          	li	a2,128
    800054a4:	f5040593          	addi	a1,s0,-176
    800054a8:	4505                	li	a0,1
    800054aa:	ffffd097          	auipc	ra,0xffffd
    800054ae:	6e2080e7          	jalr	1762(ra) # 80002b8c <argstr>
    return -1;
    800054b2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054b4:	10054263          	bltz	a0,800055b8 <sys_link+0x13c>
  begin_op();
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	c90080e7          	jalr	-880(ra) # 80004148 <begin_op>
  if((ip = namei(old)) == 0){
    800054c0:	ed040513          	addi	a0,s0,-304
    800054c4:	fffff097          	auipc	ra,0xfffff
    800054c8:	a76080e7          	jalr	-1418(ra) # 80003f3a <namei>
    800054cc:	84aa                	mv	s1,a0
    800054ce:	c551                	beqz	a0,8000555a <sys_link+0xde>
  ilock(ip);
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	2b0080e7          	jalr	688(ra) # 80003780 <ilock>
  if(ip->type == T_DIR){
    800054d8:	04449703          	lh	a4,68(s1)
    800054dc:	4785                	li	a5,1
    800054de:	08f70463          	beq	a4,a5,80005566 <sys_link+0xea>
  ip->nlink++;
    800054e2:	04a4d783          	lhu	a5,74(s1)
    800054e6:	2785                	addiw	a5,a5,1
    800054e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	1c6080e7          	jalr	454(ra) # 800036b4 <iupdate>
  iunlock(ip);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	34c080e7          	jalr	844(ra) # 80003844 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005500:	fd040593          	addi	a1,s0,-48
    80005504:	f5040513          	addi	a0,s0,-176
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	a50080e7          	jalr	-1456(ra) # 80003f58 <nameiparent>
    80005510:	892a                	mv	s2,a0
    80005512:	c935                	beqz	a0,80005586 <sys_link+0x10a>
  ilock(dp);
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	26c080e7          	jalr	620(ra) # 80003780 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000551c:	00092703          	lw	a4,0(s2)
    80005520:	409c                	lw	a5,0(s1)
    80005522:	04f71d63          	bne	a4,a5,8000557c <sys_link+0x100>
    80005526:	40d0                	lw	a2,4(s1)
    80005528:	fd040593          	addi	a1,s0,-48
    8000552c:	854a                	mv	a0,s2
    8000552e:	fffff097          	auipc	ra,0xfffff
    80005532:	94a080e7          	jalr	-1718(ra) # 80003e78 <dirlink>
    80005536:	04054363          	bltz	a0,8000557c <sys_link+0x100>
  iunlockput(dp);
    8000553a:	854a                	mv	a0,s2
    8000553c:	ffffe097          	auipc	ra,0xffffe
    80005540:	4a8080e7          	jalr	1192(ra) # 800039e4 <iunlockput>
  iput(ip);
    80005544:	8526                	mv	a0,s1
    80005546:	ffffe097          	auipc	ra,0xffffe
    8000554a:	3f6080e7          	jalr	1014(ra) # 8000393c <iput>
  end_op();
    8000554e:	fffff097          	auipc	ra,0xfffff
    80005552:	c7a080e7          	jalr	-902(ra) # 800041c8 <end_op>
  return 0;
    80005556:	4781                	li	a5,0
    80005558:	a085                	j	800055b8 <sys_link+0x13c>
    end_op();
    8000555a:	fffff097          	auipc	ra,0xfffff
    8000555e:	c6e080e7          	jalr	-914(ra) # 800041c8 <end_op>
    return -1;
    80005562:	57fd                	li	a5,-1
    80005564:	a891                	j	800055b8 <sys_link+0x13c>
    iunlockput(ip);
    80005566:	8526                	mv	a0,s1
    80005568:	ffffe097          	auipc	ra,0xffffe
    8000556c:	47c080e7          	jalr	1148(ra) # 800039e4 <iunlockput>
    end_op();
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	c58080e7          	jalr	-936(ra) # 800041c8 <end_op>
    return -1;
    80005578:	57fd                	li	a5,-1
    8000557a:	a83d                	j	800055b8 <sys_link+0x13c>
    iunlockput(dp);
    8000557c:	854a                	mv	a0,s2
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	466080e7          	jalr	1126(ra) # 800039e4 <iunlockput>
  ilock(ip);
    80005586:	8526                	mv	a0,s1
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	1f8080e7          	jalr	504(ra) # 80003780 <ilock>
  ip->nlink--;
    80005590:	04a4d783          	lhu	a5,74(s1)
    80005594:	37fd                	addiw	a5,a5,-1
    80005596:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	118080e7          	jalr	280(ra) # 800036b4 <iupdate>
  iunlockput(ip);
    800055a4:	8526                	mv	a0,s1
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	43e080e7          	jalr	1086(ra) # 800039e4 <iunlockput>
  end_op();
    800055ae:	fffff097          	auipc	ra,0xfffff
    800055b2:	c1a080e7          	jalr	-998(ra) # 800041c8 <end_op>
  return -1;
    800055b6:	57fd                	li	a5,-1
}
    800055b8:	853e                	mv	a0,a5
    800055ba:	70b2                	ld	ra,296(sp)
    800055bc:	7412                	ld	s0,288(sp)
    800055be:	64f2                	ld	s1,280(sp)
    800055c0:	6952                	ld	s2,272(sp)
    800055c2:	6155                	addi	sp,sp,304
    800055c4:	8082                	ret

00000000800055c6 <sys_unlink>:
{
    800055c6:	7151                	addi	sp,sp,-240
    800055c8:	f586                	sd	ra,232(sp)
    800055ca:	f1a2                	sd	s0,224(sp)
    800055cc:	eda6                	sd	s1,216(sp)
    800055ce:	e9ca                	sd	s2,208(sp)
    800055d0:	e5ce                	sd	s3,200(sp)
    800055d2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055d4:	08000613          	li	a2,128
    800055d8:	f3040593          	addi	a1,s0,-208
    800055dc:	4501                	li	a0,0
    800055de:	ffffd097          	auipc	ra,0xffffd
    800055e2:	5ae080e7          	jalr	1454(ra) # 80002b8c <argstr>
    800055e6:	16054f63          	bltz	a0,80005764 <sys_unlink+0x19e>
  begin_op();
    800055ea:	fffff097          	auipc	ra,0xfffff
    800055ee:	b5e080e7          	jalr	-1186(ra) # 80004148 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055f2:	fb040593          	addi	a1,s0,-80
    800055f6:	f3040513          	addi	a0,s0,-208
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	95e080e7          	jalr	-1698(ra) # 80003f58 <nameiparent>
    80005602:	89aa                	mv	s3,a0
    80005604:	c979                	beqz	a0,800056da <sys_unlink+0x114>
  ilock(dp);
    80005606:	ffffe097          	auipc	ra,0xffffe
    8000560a:	17a080e7          	jalr	378(ra) # 80003780 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000560e:	00003597          	auipc	a1,0x3
    80005612:	13258593          	addi	a1,a1,306 # 80008740 <sysnames+0x288>
    80005616:	fb040513          	addi	a0,s0,-80
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	62c080e7          	jalr	1580(ra) # 80003c46 <namecmp>
    80005622:	14050863          	beqz	a0,80005772 <sys_unlink+0x1ac>
    80005626:	00003597          	auipc	a1,0x3
    8000562a:	12258593          	addi	a1,a1,290 # 80008748 <sysnames+0x290>
    8000562e:	fb040513          	addi	a0,s0,-80
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	614080e7          	jalr	1556(ra) # 80003c46 <namecmp>
    8000563a:	12050c63          	beqz	a0,80005772 <sys_unlink+0x1ac>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000563e:	f2c40613          	addi	a2,s0,-212
    80005642:	fb040593          	addi	a1,s0,-80
    80005646:	854e                	mv	a0,s3
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	618080e7          	jalr	1560(ra) # 80003c60 <dirlookup>
    80005650:	84aa                	mv	s1,a0
    80005652:	12050063          	beqz	a0,80005772 <sys_unlink+0x1ac>
  ilock(ip);
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	12a080e7          	jalr	298(ra) # 80003780 <ilock>
  if(ip->nlink < 1)
    8000565e:	04a49783          	lh	a5,74(s1)
    80005662:	08f05263          	blez	a5,800056e6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005666:	04449703          	lh	a4,68(s1)
    8000566a:	4785                	li	a5,1
    8000566c:	08f70563          	beq	a4,a5,800056f6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005670:	4641                	li	a2,16
    80005672:	4581                	li	a1,0
    80005674:	fc040513          	addi	a0,s0,-64
    80005678:	ffffb097          	auipc	ra,0xffffb
    8000567c:	6e6080e7          	jalr	1766(ra) # 80000d5e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005680:	4741                	li	a4,16
    80005682:	f2c42683          	lw	a3,-212(s0)
    80005686:	fc040613          	addi	a2,s0,-64
    8000568a:	4581                	li	a1,0
    8000568c:	854e                	mv	a0,s3
    8000568e:	ffffe097          	auipc	ra,0xffffe
    80005692:	49e080e7          	jalr	1182(ra) # 80003b2c <writei>
    80005696:	47c1                	li	a5,16
    80005698:	0af51363          	bne	a0,a5,8000573e <sys_unlink+0x178>
  if(ip->type == T_DIR){
    8000569c:	04449703          	lh	a4,68(s1)
    800056a0:	4785                	li	a5,1
    800056a2:	0af70663          	beq	a4,a5,8000574e <sys_unlink+0x188>
  iunlockput(dp);
    800056a6:	854e                	mv	a0,s3
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	33c080e7          	jalr	828(ra) # 800039e4 <iunlockput>
  ip->nlink--;
    800056b0:	04a4d783          	lhu	a5,74(s1)
    800056b4:	37fd                	addiw	a5,a5,-1
    800056b6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056ba:	8526                	mv	a0,s1
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	ff8080e7          	jalr	-8(ra) # 800036b4 <iupdate>
  iunlockput(ip);
    800056c4:	8526                	mv	a0,s1
    800056c6:	ffffe097          	auipc	ra,0xffffe
    800056ca:	31e080e7          	jalr	798(ra) # 800039e4 <iunlockput>
  end_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	afa080e7          	jalr	-1286(ra) # 800041c8 <end_op>
  return 0;
    800056d6:	4501                	li	a0,0
    800056d8:	a07d                	j	80005786 <sys_unlink+0x1c0>
    end_op();
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	aee080e7          	jalr	-1298(ra) # 800041c8 <end_op>
    return -1;
    800056e2:	557d                	li	a0,-1
    800056e4:	a04d                	j	80005786 <sys_unlink+0x1c0>
    panic("unlink: nlink < 1");
    800056e6:	00003517          	auipc	a0,0x3
    800056ea:	08a50513          	addi	a0,a0,138 # 80008770 <sysnames+0x2b8>
    800056ee:	ffffb097          	auipc	ra,0xffffb
    800056f2:	e86080e7          	jalr	-378(ra) # 80000574 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056f6:	44f8                	lw	a4,76(s1)
    800056f8:	02000793          	li	a5,32
    800056fc:	f6e7fae3          	bleu	a4,a5,80005670 <sys_unlink+0xaa>
    80005700:	02000913          	li	s2,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005704:	4741                	li	a4,16
    80005706:	86ca                	mv	a3,s2
    80005708:	f1840613          	addi	a2,s0,-232
    8000570c:	4581                	li	a1,0
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	326080e7          	jalr	806(ra) # 80003a36 <readi>
    80005718:	47c1                	li	a5,16
    8000571a:	00f51a63          	bne	a0,a5,8000572e <sys_unlink+0x168>
    if(de.inum != 0)
    8000571e:	f1845783          	lhu	a5,-232(s0)
    80005722:	e3b9                	bnez	a5,80005768 <sys_unlink+0x1a2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005724:	2941                	addiw	s2,s2,16
    80005726:	44fc                	lw	a5,76(s1)
    80005728:	fcf96ee3          	bltu	s2,a5,80005704 <sys_unlink+0x13e>
    8000572c:	b791                	j	80005670 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000572e:	00003517          	auipc	a0,0x3
    80005732:	05a50513          	addi	a0,a0,90 # 80008788 <sysnames+0x2d0>
    80005736:	ffffb097          	auipc	ra,0xffffb
    8000573a:	e3e080e7          	jalr	-450(ra) # 80000574 <panic>
    panic("unlink: writei");
    8000573e:	00003517          	auipc	a0,0x3
    80005742:	06250513          	addi	a0,a0,98 # 800087a0 <sysnames+0x2e8>
    80005746:	ffffb097          	auipc	ra,0xffffb
    8000574a:	e2e080e7          	jalr	-466(ra) # 80000574 <panic>
    dp->nlink--;
    8000574e:	04a9d783          	lhu	a5,74(s3)
    80005752:	37fd                	addiw	a5,a5,-1
    80005754:	04f99523          	sh	a5,74(s3)
    iupdate(dp);
    80005758:	854e                	mv	a0,s3
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	f5a080e7          	jalr	-166(ra) # 800036b4 <iupdate>
    80005762:	b791                	j	800056a6 <sys_unlink+0xe0>
    return -1;
    80005764:	557d                	li	a0,-1
    80005766:	a005                	j	80005786 <sys_unlink+0x1c0>
    iunlockput(ip);
    80005768:	8526                	mv	a0,s1
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	27a080e7          	jalr	634(ra) # 800039e4 <iunlockput>
  iunlockput(dp);
    80005772:	854e                	mv	a0,s3
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	270080e7          	jalr	624(ra) # 800039e4 <iunlockput>
  end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	a4c080e7          	jalr	-1460(ra) # 800041c8 <end_op>
  return -1;
    80005784:	557d                	li	a0,-1
}
    80005786:	70ae                	ld	ra,232(sp)
    80005788:	740e                	ld	s0,224(sp)
    8000578a:	64ee                	ld	s1,216(sp)
    8000578c:	694e                	ld	s2,208(sp)
    8000578e:	69ae                	ld	s3,200(sp)
    80005790:	616d                	addi	sp,sp,240
    80005792:	8082                	ret

0000000080005794 <sys_open>:

uint64
sys_open(void)
{
    80005794:	7131                	addi	sp,sp,-192
    80005796:	fd06                	sd	ra,184(sp)
    80005798:	f922                	sd	s0,176(sp)
    8000579a:	f526                	sd	s1,168(sp)
    8000579c:	f14a                	sd	s2,160(sp)
    8000579e:	ed4e                	sd	s3,152(sp)
    800057a0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057a2:	08000613          	li	a2,128
    800057a6:	f5040593          	addi	a1,s0,-176
    800057aa:	4501                	li	a0,0
    800057ac:	ffffd097          	auipc	ra,0xffffd
    800057b0:	3e0080e7          	jalr	992(ra) # 80002b8c <argstr>
    return -1;
    800057b4:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057b6:	0c054163          	bltz	a0,80005878 <sys_open+0xe4>
    800057ba:	f4c40593          	addi	a1,s0,-180
    800057be:	4505                	li	a0,1
    800057c0:	ffffd097          	auipc	ra,0xffffd
    800057c4:	388080e7          	jalr	904(ra) # 80002b48 <argint>
    800057c8:	0a054863          	bltz	a0,80005878 <sys_open+0xe4>

  begin_op();
    800057cc:	fffff097          	auipc	ra,0xfffff
    800057d0:	97c080e7          	jalr	-1668(ra) # 80004148 <begin_op>

  if(omode & O_CREATE){
    800057d4:	f4c42783          	lw	a5,-180(s0)
    800057d8:	2007f793          	andi	a5,a5,512
    800057dc:	cbdd                	beqz	a5,80005892 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057de:	4681                	li	a3,0
    800057e0:	4601                	li	a2,0
    800057e2:	4589                	li	a1,2
    800057e4:	f5040513          	addi	a0,s0,-176
    800057e8:	00000097          	auipc	ra,0x0
    800057ec:	976080e7          	jalr	-1674(ra) # 8000515e <create>
    800057f0:	892a                	mv	s2,a0
    if(ip == 0){
    800057f2:	c959                	beqz	a0,80005888 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057f4:	04491703          	lh	a4,68(s2)
    800057f8:	478d                	li	a5,3
    800057fa:	00f71763          	bne	a4,a5,80005808 <sys_open+0x74>
    800057fe:	04695703          	lhu	a4,70(s2)
    80005802:	47a5                	li	a5,9
    80005804:	0ce7ec63          	bltu	a5,a4,800058dc <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	d72080e7          	jalr	-654(ra) # 8000457a <filealloc>
    80005810:	89aa                	mv	s3,a0
    80005812:	10050263          	beqz	a0,80005916 <sys_open+0x182>
    80005816:	00000097          	auipc	ra,0x0
    8000581a:	900080e7          	jalr	-1792(ra) # 80005116 <fdalloc>
    8000581e:	84aa                	mv	s1,a0
    80005820:	0e054663          	bltz	a0,8000590c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005824:	04491703          	lh	a4,68(s2)
    80005828:	478d                	li	a5,3
    8000582a:	0cf70463          	beq	a4,a5,800058f2 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000582e:	4789                	li	a5,2
    80005830:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005834:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005838:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000583c:	f4c42783          	lw	a5,-180(s0)
    80005840:	0017c713          	xori	a4,a5,1
    80005844:	8b05                	andi	a4,a4,1
    80005846:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000584a:	0037f713          	andi	a4,a5,3
    8000584e:	00e03733          	snez	a4,a4
    80005852:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005856:	4007f793          	andi	a5,a5,1024
    8000585a:	c791                	beqz	a5,80005866 <sys_open+0xd2>
    8000585c:	04491703          	lh	a4,68(s2)
    80005860:	4789                	li	a5,2
    80005862:	08f70f63          	beq	a4,a5,80005900 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005866:	854a                	mv	a0,s2
    80005868:	ffffe097          	auipc	ra,0xffffe
    8000586c:	fdc080e7          	jalr	-36(ra) # 80003844 <iunlock>
  end_op();
    80005870:	fffff097          	auipc	ra,0xfffff
    80005874:	958080e7          	jalr	-1704(ra) # 800041c8 <end_op>

  return fd;
}
    80005878:	8526                	mv	a0,s1
    8000587a:	70ea                	ld	ra,184(sp)
    8000587c:	744a                	ld	s0,176(sp)
    8000587e:	74aa                	ld	s1,168(sp)
    80005880:	790a                	ld	s2,160(sp)
    80005882:	69ea                	ld	s3,152(sp)
    80005884:	6129                	addi	sp,sp,192
    80005886:	8082                	ret
      end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	940080e7          	jalr	-1728(ra) # 800041c8 <end_op>
      return -1;
    80005890:	b7e5                	j	80005878 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005892:	f5040513          	addi	a0,s0,-176
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	6a4080e7          	jalr	1700(ra) # 80003f3a <namei>
    8000589e:	892a                	mv	s2,a0
    800058a0:	c905                	beqz	a0,800058d0 <sys_open+0x13c>
    ilock(ip);
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	ede080e7          	jalr	-290(ra) # 80003780 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058aa:	04491703          	lh	a4,68(s2)
    800058ae:	4785                	li	a5,1
    800058b0:	f4f712e3          	bne	a4,a5,800057f4 <sys_open+0x60>
    800058b4:	f4c42783          	lw	a5,-180(s0)
    800058b8:	dba1                	beqz	a5,80005808 <sys_open+0x74>
      iunlockput(ip);
    800058ba:	854a                	mv	a0,s2
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	128080e7          	jalr	296(ra) # 800039e4 <iunlockput>
      end_op();
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	904080e7          	jalr	-1788(ra) # 800041c8 <end_op>
      return -1;
    800058cc:	54fd                	li	s1,-1
    800058ce:	b76d                	j	80005878 <sys_open+0xe4>
      end_op();
    800058d0:	fffff097          	auipc	ra,0xfffff
    800058d4:	8f8080e7          	jalr	-1800(ra) # 800041c8 <end_op>
      return -1;
    800058d8:	54fd                	li	s1,-1
    800058da:	bf79                	j	80005878 <sys_open+0xe4>
    iunlockput(ip);
    800058dc:	854a                	mv	a0,s2
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	106080e7          	jalr	262(ra) # 800039e4 <iunlockput>
    end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	8e2080e7          	jalr	-1822(ra) # 800041c8 <end_op>
    return -1;
    800058ee:	54fd                	li	s1,-1
    800058f0:	b761                	j	80005878 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058f2:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058f6:	04691783          	lh	a5,70(s2)
    800058fa:	02f99223          	sh	a5,36(s3)
    800058fe:	bf2d                	j	80005838 <sys_open+0xa4>
    itrunc(ip);
    80005900:	854a                	mv	a0,s2
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	f8e080e7          	jalr	-114(ra) # 80003890 <itrunc>
    8000590a:	bfb1                	j	80005866 <sys_open+0xd2>
      fileclose(f);
    8000590c:	854e                	mv	a0,s3
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	d3c080e7          	jalr	-708(ra) # 8000464a <fileclose>
    iunlockput(ip);
    80005916:	854a                	mv	a0,s2
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	0cc080e7          	jalr	204(ra) # 800039e4 <iunlockput>
    end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	8a8080e7          	jalr	-1880(ra) # 800041c8 <end_op>
    return -1;
    80005928:	54fd                	li	s1,-1
    8000592a:	b7b9                	j	80005878 <sys_open+0xe4>

000000008000592c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000592c:	7175                	addi	sp,sp,-144
    8000592e:	e506                	sd	ra,136(sp)
    80005930:	e122                	sd	s0,128(sp)
    80005932:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	814080e7          	jalr	-2028(ra) # 80004148 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000593c:	08000613          	li	a2,128
    80005940:	f7040593          	addi	a1,s0,-144
    80005944:	4501                	li	a0,0
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	246080e7          	jalr	582(ra) # 80002b8c <argstr>
    8000594e:	02054963          	bltz	a0,80005980 <sys_mkdir+0x54>
    80005952:	4681                	li	a3,0
    80005954:	4601                	li	a2,0
    80005956:	4585                	li	a1,1
    80005958:	f7040513          	addi	a0,s0,-144
    8000595c:	00000097          	auipc	ra,0x0
    80005960:	802080e7          	jalr	-2046(ra) # 8000515e <create>
    80005964:	cd11                	beqz	a0,80005980 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	07e080e7          	jalr	126(ra) # 800039e4 <iunlockput>
  end_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	85a080e7          	jalr	-1958(ra) # 800041c8 <end_op>
  return 0;
    80005976:	4501                	li	a0,0
}
    80005978:	60aa                	ld	ra,136(sp)
    8000597a:	640a                	ld	s0,128(sp)
    8000597c:	6149                	addi	sp,sp,144
    8000597e:	8082                	ret
    end_op();
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	848080e7          	jalr	-1976(ra) # 800041c8 <end_op>
    return -1;
    80005988:	557d                	li	a0,-1
    8000598a:	b7fd                	j	80005978 <sys_mkdir+0x4c>

000000008000598c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000598c:	7135                	addi	sp,sp,-160
    8000598e:	ed06                	sd	ra,152(sp)
    80005990:	e922                	sd	s0,144(sp)
    80005992:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	7b4080e7          	jalr	1972(ra) # 80004148 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000599c:	08000613          	li	a2,128
    800059a0:	f7040593          	addi	a1,s0,-144
    800059a4:	4501                	li	a0,0
    800059a6:	ffffd097          	auipc	ra,0xffffd
    800059aa:	1e6080e7          	jalr	486(ra) # 80002b8c <argstr>
    800059ae:	04054a63          	bltz	a0,80005a02 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059b2:	f6c40593          	addi	a1,s0,-148
    800059b6:	4505                	li	a0,1
    800059b8:	ffffd097          	auipc	ra,0xffffd
    800059bc:	190080e7          	jalr	400(ra) # 80002b48 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059c0:	04054163          	bltz	a0,80005a02 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    800059c4:	f6840593          	addi	a1,s0,-152
    800059c8:	4509                	li	a0,2
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	17e080e7          	jalr	382(ra) # 80002b48 <argint>
     argint(1, &major) < 0 ||
    800059d2:	02054863          	bltz	a0,80005a02 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059d6:	f6841683          	lh	a3,-152(s0)
    800059da:	f6c41603          	lh	a2,-148(s0)
    800059de:	458d                	li	a1,3
    800059e0:	f7040513          	addi	a0,s0,-144
    800059e4:	fffff097          	auipc	ra,0xfffff
    800059e8:	77a080e7          	jalr	1914(ra) # 8000515e <create>
     argint(2, &minor) < 0 ||
    800059ec:	c919                	beqz	a0,80005a02 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	ff6080e7          	jalr	-10(ra) # 800039e4 <iunlockput>
  end_op();
    800059f6:	ffffe097          	auipc	ra,0xffffe
    800059fa:	7d2080e7          	jalr	2002(ra) # 800041c8 <end_op>
  return 0;
    800059fe:	4501                	li	a0,0
    80005a00:	a031                	j	80005a0c <sys_mknod+0x80>
    end_op();
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	7c6080e7          	jalr	1990(ra) # 800041c8 <end_op>
    return -1;
    80005a0a:	557d                	li	a0,-1
}
    80005a0c:	60ea                	ld	ra,152(sp)
    80005a0e:	644a                	ld	s0,144(sp)
    80005a10:	610d                	addi	sp,sp,160
    80005a12:	8082                	ret

0000000080005a14 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a14:	7135                	addi	sp,sp,-160
    80005a16:	ed06                	sd	ra,152(sp)
    80005a18:	e922                	sd	s0,144(sp)
    80005a1a:	e526                	sd	s1,136(sp)
    80005a1c:	e14a                	sd	s2,128(sp)
    80005a1e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a20:	ffffc097          	auipc	ra,0xffffc
    80005a24:	050080e7          	jalr	80(ra) # 80001a70 <myproc>
    80005a28:	892a                	mv	s2,a0
  
  begin_op();
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	71e080e7          	jalr	1822(ra) # 80004148 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a32:	08000613          	li	a2,128
    80005a36:	f6040593          	addi	a1,s0,-160
    80005a3a:	4501                	li	a0,0
    80005a3c:	ffffd097          	auipc	ra,0xffffd
    80005a40:	150080e7          	jalr	336(ra) # 80002b8c <argstr>
    80005a44:	04054b63          	bltz	a0,80005a9a <sys_chdir+0x86>
    80005a48:	f6040513          	addi	a0,s0,-160
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	4ee080e7          	jalr	1262(ra) # 80003f3a <namei>
    80005a54:	84aa                	mv	s1,a0
    80005a56:	c131                	beqz	a0,80005a9a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	d28080e7          	jalr	-728(ra) # 80003780 <ilock>
  if(ip->type != T_DIR){
    80005a60:	04449703          	lh	a4,68(s1)
    80005a64:	4785                	li	a5,1
    80005a66:	04f71063          	bne	a4,a5,80005aa6 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a6a:	8526                	mv	a0,s1
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	dd8080e7          	jalr	-552(ra) # 80003844 <iunlock>
  iput(p->cwd);
    80005a74:	15093503          	ld	a0,336(s2)
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	ec4080e7          	jalr	-316(ra) # 8000393c <iput>
  end_op();
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	748080e7          	jalr	1864(ra) # 800041c8 <end_op>
  p->cwd = ip;
    80005a88:	14993823          	sd	s1,336(s2)
  return 0;
    80005a8c:	4501                	li	a0,0
}
    80005a8e:	60ea                	ld	ra,152(sp)
    80005a90:	644a                	ld	s0,144(sp)
    80005a92:	64aa                	ld	s1,136(sp)
    80005a94:	690a                	ld	s2,128(sp)
    80005a96:	610d                	addi	sp,sp,160
    80005a98:	8082                	ret
    end_op();
    80005a9a:	ffffe097          	auipc	ra,0xffffe
    80005a9e:	72e080e7          	jalr	1838(ra) # 800041c8 <end_op>
    return -1;
    80005aa2:	557d                	li	a0,-1
    80005aa4:	b7ed                	j	80005a8e <sys_chdir+0x7a>
    iunlockput(ip);
    80005aa6:	8526                	mv	a0,s1
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	f3c080e7          	jalr	-196(ra) # 800039e4 <iunlockput>
    end_op();
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	718080e7          	jalr	1816(ra) # 800041c8 <end_op>
    return -1;
    80005ab8:	557d                	li	a0,-1
    80005aba:	bfd1                	j	80005a8e <sys_chdir+0x7a>

0000000080005abc <sys_exec>:

uint64
sys_exec(void)
{
    80005abc:	7145                	addi	sp,sp,-464
    80005abe:	e786                	sd	ra,456(sp)
    80005ac0:	e3a2                	sd	s0,448(sp)
    80005ac2:	ff26                	sd	s1,440(sp)
    80005ac4:	fb4a                	sd	s2,432(sp)
    80005ac6:	f74e                	sd	s3,424(sp)
    80005ac8:	f352                	sd	s4,416(sp)
    80005aca:	ef56                	sd	s5,408(sp)
    80005acc:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ace:	08000613          	li	a2,128
    80005ad2:	f4040593          	addi	a1,s0,-192
    80005ad6:	4501                	li	a0,0
    80005ad8:	ffffd097          	auipc	ra,0xffffd
    80005adc:	0b4080e7          	jalr	180(ra) # 80002b8c <argstr>
    return -1;
    80005ae0:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ae2:	0e054c63          	bltz	a0,80005bda <sys_exec+0x11e>
    80005ae6:	e3840593          	addi	a1,s0,-456
    80005aea:	4505                	li	a0,1
    80005aec:	ffffd097          	auipc	ra,0xffffd
    80005af0:	07e080e7          	jalr	126(ra) # 80002b6a <argaddr>
    80005af4:	0e054363          	bltz	a0,80005bda <sys_exec+0x11e>
  }
  memset(argv, 0, sizeof(argv));
    80005af8:	e4040913          	addi	s2,s0,-448
    80005afc:	10000613          	li	a2,256
    80005b00:	4581                	li	a1,0
    80005b02:	854a                	mv	a0,s2
    80005b04:	ffffb097          	auipc	ra,0xffffb
    80005b08:	25a080e7          	jalr	602(ra) # 80000d5e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b0c:	89ca                	mv	s3,s2
  memset(argv, 0, sizeof(argv));
    80005b0e:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    80005b10:	02000a93          	li	s5,32
    80005b14:	00048a1b          	sext.w	s4,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b18:	00349513          	slli	a0,s1,0x3
    80005b1c:	e3040593          	addi	a1,s0,-464
    80005b20:	e3843783          	ld	a5,-456(s0)
    80005b24:	953e                	add	a0,a0,a5
    80005b26:	ffffd097          	auipc	ra,0xffffd
    80005b2a:	f86080e7          	jalr	-122(ra) # 80002aac <fetchaddr>
    80005b2e:	02054a63          	bltz	a0,80005b62 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b32:	e3043783          	ld	a5,-464(s0)
    80005b36:	cfa9                	beqz	a5,80005b90 <sys_exec+0xd4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b38:	ffffb097          	auipc	ra,0xffffb
    80005b3c:	03a080e7          	jalr	58(ra) # 80000b72 <kalloc>
    80005b40:	00a93023          	sd	a0,0(s2)
    if(argv[i] == 0)
    80005b44:	cd19                	beqz	a0,80005b62 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b46:	6605                	lui	a2,0x1
    80005b48:	85aa                	mv	a1,a0
    80005b4a:	e3043503          	ld	a0,-464(s0)
    80005b4e:	ffffd097          	auipc	ra,0xffffd
    80005b52:	fb2080e7          	jalr	-78(ra) # 80002b00 <fetchstr>
    80005b56:	00054663          	bltz	a0,80005b62 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b5a:	0485                	addi	s1,s1,1
    80005b5c:	0921                	addi	s2,s2,8
    80005b5e:	fb549be3          	bne	s1,s5,80005b14 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b62:	e4043503          	ld	a0,-448(s0)
    kfree(argv[i]);
  return -1;
    80005b66:	597d                	li	s2,-1
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b68:	c92d                	beqz	a0,80005bda <sys_exec+0x11e>
    kfree(argv[i]);
    80005b6a:	ffffb097          	auipc	ra,0xffffb
    80005b6e:	f08080e7          	jalr	-248(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b72:	e4840493          	addi	s1,s0,-440
    80005b76:	10098993          	addi	s3,s3,256
    80005b7a:	6088                	ld	a0,0(s1)
    80005b7c:	cd31                	beqz	a0,80005bd8 <sys_exec+0x11c>
    kfree(argv[i]);
    80005b7e:	ffffb097          	auipc	ra,0xffffb
    80005b82:	ef4080e7          	jalr	-268(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b86:	04a1                	addi	s1,s1,8
    80005b88:	ff3499e3          	bne	s1,s3,80005b7a <sys_exec+0xbe>
  return -1;
    80005b8c:	597d                	li	s2,-1
    80005b8e:	a0b1                	j	80005bda <sys_exec+0x11e>
      argv[i] = 0;
    80005b90:	0a0e                	slli	s4,s4,0x3
    80005b92:	fc040793          	addi	a5,s0,-64
    80005b96:	9a3e                	add	s4,s4,a5
    80005b98:	e80a3023          	sd	zero,-384(s4)
  int ret = exec(path, argv);
    80005b9c:	e4040593          	addi	a1,s0,-448
    80005ba0:	f4040513          	addi	a0,s0,-192
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	166080e7          	jalr	358(ra) # 80004d0a <exec>
    80005bac:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bae:	e4043503          	ld	a0,-448(s0)
    80005bb2:	c505                	beqz	a0,80005bda <sys_exec+0x11e>
    kfree(argv[i]);
    80005bb4:	ffffb097          	auipc	ra,0xffffb
    80005bb8:	ebe080e7          	jalr	-322(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bbc:	e4840493          	addi	s1,s0,-440
    80005bc0:	10098993          	addi	s3,s3,256
    80005bc4:	6088                	ld	a0,0(s1)
    80005bc6:	c911                	beqz	a0,80005bda <sys_exec+0x11e>
    kfree(argv[i]);
    80005bc8:	ffffb097          	auipc	ra,0xffffb
    80005bcc:	eaa080e7          	jalr	-342(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bd0:	04a1                	addi	s1,s1,8
    80005bd2:	ff3499e3          	bne	s1,s3,80005bc4 <sys_exec+0x108>
    80005bd6:	a011                	j	80005bda <sys_exec+0x11e>
  return -1;
    80005bd8:	597d                	li	s2,-1
}
    80005bda:	854a                	mv	a0,s2
    80005bdc:	60be                	ld	ra,456(sp)
    80005bde:	641e                	ld	s0,448(sp)
    80005be0:	74fa                	ld	s1,440(sp)
    80005be2:	795a                	ld	s2,432(sp)
    80005be4:	79ba                	ld	s3,424(sp)
    80005be6:	7a1a                	ld	s4,416(sp)
    80005be8:	6afa                	ld	s5,408(sp)
    80005bea:	6179                	addi	sp,sp,464
    80005bec:	8082                	ret

0000000080005bee <sys_pipe>:

uint64
sys_pipe(void)
{
    80005bee:	7139                	addi	sp,sp,-64
    80005bf0:	fc06                	sd	ra,56(sp)
    80005bf2:	f822                	sd	s0,48(sp)
    80005bf4:	f426                	sd	s1,40(sp)
    80005bf6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bf8:	ffffc097          	auipc	ra,0xffffc
    80005bfc:	e78080e7          	jalr	-392(ra) # 80001a70 <myproc>
    80005c00:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c02:	fd840593          	addi	a1,s0,-40
    80005c06:	4501                	li	a0,0
    80005c08:	ffffd097          	auipc	ra,0xffffd
    80005c0c:	f62080e7          	jalr	-158(ra) # 80002b6a <argaddr>
    return -1;
    80005c10:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c12:	0c054f63          	bltz	a0,80005cf0 <sys_pipe+0x102>
  if(pipealloc(&rf, &wf) < 0)
    80005c16:	fc840593          	addi	a1,s0,-56
    80005c1a:	fd040513          	addi	a0,s0,-48
    80005c1e:	fffff097          	auipc	ra,0xfffff
    80005c22:	d74080e7          	jalr	-652(ra) # 80004992 <pipealloc>
    return -1;
    80005c26:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c28:	0c054463          	bltz	a0,80005cf0 <sys_pipe+0x102>
  fd0 = -1;
    80005c2c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c30:	fd043503          	ld	a0,-48(s0)
    80005c34:	fffff097          	auipc	ra,0xfffff
    80005c38:	4e2080e7          	jalr	1250(ra) # 80005116 <fdalloc>
    80005c3c:	fca42223          	sw	a0,-60(s0)
    80005c40:	08054b63          	bltz	a0,80005cd6 <sys_pipe+0xe8>
    80005c44:	fc843503          	ld	a0,-56(s0)
    80005c48:	fffff097          	auipc	ra,0xfffff
    80005c4c:	4ce080e7          	jalr	1230(ra) # 80005116 <fdalloc>
    80005c50:	fca42023          	sw	a0,-64(s0)
    80005c54:	06054863          	bltz	a0,80005cc4 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c58:	4691                	li	a3,4
    80005c5a:	fc440613          	addi	a2,s0,-60
    80005c5e:	fd843583          	ld	a1,-40(s0)
    80005c62:	68a8                	ld	a0,80(s1)
    80005c64:	ffffc097          	auipc	ra,0xffffc
    80005c68:	ae8080e7          	jalr	-1304(ra) # 8000174c <copyout>
    80005c6c:	02054063          	bltz	a0,80005c8c <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c70:	4691                	li	a3,4
    80005c72:	fc040613          	addi	a2,s0,-64
    80005c76:	fd843583          	ld	a1,-40(s0)
    80005c7a:	0591                	addi	a1,a1,4
    80005c7c:	68a8                	ld	a0,80(s1)
    80005c7e:	ffffc097          	auipc	ra,0xffffc
    80005c82:	ace080e7          	jalr	-1330(ra) # 8000174c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c86:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c88:	06055463          	bgez	a0,80005cf0 <sys_pipe+0x102>
    p->ofile[fd0] = 0;
    80005c8c:	fc442783          	lw	a5,-60(s0)
    80005c90:	07e9                	addi	a5,a5,26
    80005c92:	078e                	slli	a5,a5,0x3
    80005c94:	97a6                	add	a5,a5,s1
    80005c96:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c9a:	fc042783          	lw	a5,-64(s0)
    80005c9e:	07e9                	addi	a5,a5,26
    80005ca0:	078e                	slli	a5,a5,0x3
    80005ca2:	94be                	add	s1,s1,a5
    80005ca4:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005ca8:	fd043503          	ld	a0,-48(s0)
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	99e080e7          	jalr	-1634(ra) # 8000464a <fileclose>
    fileclose(wf);
    80005cb4:	fc843503          	ld	a0,-56(s0)
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	992080e7          	jalr	-1646(ra) # 8000464a <fileclose>
    return -1;
    80005cc0:	57fd                	li	a5,-1
    80005cc2:	a03d                	j	80005cf0 <sys_pipe+0x102>
    if(fd0 >= 0)
    80005cc4:	fc442783          	lw	a5,-60(s0)
    80005cc8:	0007c763          	bltz	a5,80005cd6 <sys_pipe+0xe8>
      p->ofile[fd0] = 0;
    80005ccc:	07e9                	addi	a5,a5,26
    80005cce:	078e                	slli	a5,a5,0x3
    80005cd0:	94be                	add	s1,s1,a5
    80005cd2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cd6:	fd043503          	ld	a0,-48(s0)
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	970080e7          	jalr	-1680(ra) # 8000464a <fileclose>
    fileclose(wf);
    80005ce2:	fc843503          	ld	a0,-56(s0)
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	964080e7          	jalr	-1692(ra) # 8000464a <fileclose>
    return -1;
    80005cee:	57fd                	li	a5,-1
}
    80005cf0:	853e                	mv	a0,a5
    80005cf2:	70e2                	ld	ra,56(sp)
    80005cf4:	7442                	ld	s0,48(sp)
    80005cf6:	74a2                	ld	s1,40(sp)
    80005cf8:	6121                	addi	sp,sp,64
    80005cfa:	8082                	ret
    80005cfc:	0000                	unimp
	...

0000000080005d00 <kernelvec>:
    80005d00:	7111                	addi	sp,sp,-256
    80005d02:	e006                	sd	ra,0(sp)
    80005d04:	e40a                	sd	sp,8(sp)
    80005d06:	e80e                	sd	gp,16(sp)
    80005d08:	ec12                	sd	tp,24(sp)
    80005d0a:	f016                	sd	t0,32(sp)
    80005d0c:	f41a                	sd	t1,40(sp)
    80005d0e:	f81e                	sd	t2,48(sp)
    80005d10:	fc22                	sd	s0,56(sp)
    80005d12:	e0a6                	sd	s1,64(sp)
    80005d14:	e4aa                	sd	a0,72(sp)
    80005d16:	e8ae                	sd	a1,80(sp)
    80005d18:	ecb2                	sd	a2,88(sp)
    80005d1a:	f0b6                	sd	a3,96(sp)
    80005d1c:	f4ba                	sd	a4,104(sp)
    80005d1e:	f8be                	sd	a5,112(sp)
    80005d20:	fcc2                	sd	a6,120(sp)
    80005d22:	e146                	sd	a7,128(sp)
    80005d24:	e54a                	sd	s2,136(sp)
    80005d26:	e94e                	sd	s3,144(sp)
    80005d28:	ed52                	sd	s4,152(sp)
    80005d2a:	f156                	sd	s5,160(sp)
    80005d2c:	f55a                	sd	s6,168(sp)
    80005d2e:	f95e                	sd	s7,176(sp)
    80005d30:	fd62                	sd	s8,184(sp)
    80005d32:	e1e6                	sd	s9,192(sp)
    80005d34:	e5ea                	sd	s10,200(sp)
    80005d36:	e9ee                	sd	s11,208(sp)
    80005d38:	edf2                	sd	t3,216(sp)
    80005d3a:	f1f6                	sd	t4,224(sp)
    80005d3c:	f5fa                	sd	t5,232(sp)
    80005d3e:	f9fe                	sd	t6,240(sp)
    80005d40:	c35fc0ef          	jal	ra,80002974 <kerneltrap>
    80005d44:	6082                	ld	ra,0(sp)
    80005d46:	6122                	ld	sp,8(sp)
    80005d48:	61c2                	ld	gp,16(sp)
    80005d4a:	7282                	ld	t0,32(sp)
    80005d4c:	7322                	ld	t1,40(sp)
    80005d4e:	73c2                	ld	t2,48(sp)
    80005d50:	7462                	ld	s0,56(sp)
    80005d52:	6486                	ld	s1,64(sp)
    80005d54:	6526                	ld	a0,72(sp)
    80005d56:	65c6                	ld	a1,80(sp)
    80005d58:	6666                	ld	a2,88(sp)
    80005d5a:	7686                	ld	a3,96(sp)
    80005d5c:	7726                	ld	a4,104(sp)
    80005d5e:	77c6                	ld	a5,112(sp)
    80005d60:	7866                	ld	a6,120(sp)
    80005d62:	688a                	ld	a7,128(sp)
    80005d64:	692a                	ld	s2,136(sp)
    80005d66:	69ca                	ld	s3,144(sp)
    80005d68:	6a6a                	ld	s4,152(sp)
    80005d6a:	7a8a                	ld	s5,160(sp)
    80005d6c:	7b2a                	ld	s6,168(sp)
    80005d6e:	7bca                	ld	s7,176(sp)
    80005d70:	7c6a                	ld	s8,184(sp)
    80005d72:	6c8e                	ld	s9,192(sp)
    80005d74:	6d2e                	ld	s10,200(sp)
    80005d76:	6dce                	ld	s11,208(sp)
    80005d78:	6e6e                	ld	t3,216(sp)
    80005d7a:	7e8e                	ld	t4,224(sp)
    80005d7c:	7f2e                	ld	t5,232(sp)
    80005d7e:	7fce                	ld	t6,240(sp)
    80005d80:	6111                	addi	sp,sp,256
    80005d82:	10200073          	sret
    80005d86:	00000013          	nop
    80005d8a:	00000013          	nop
    80005d8e:	0001                	nop

0000000080005d90 <timervec>:
    80005d90:	34051573          	csrrw	a0,mscratch,a0
    80005d94:	e10c                	sd	a1,0(a0)
    80005d96:	e510                	sd	a2,8(a0)
    80005d98:	e914                	sd	a3,16(a0)
    80005d9a:	710c                	ld	a1,32(a0)
    80005d9c:	7510                	ld	a2,40(a0)
    80005d9e:	6194                	ld	a3,0(a1)
    80005da0:	96b2                	add	a3,a3,a2
    80005da2:	e194                	sd	a3,0(a1)
    80005da4:	4589                	li	a1,2
    80005da6:	14459073          	csrw	sip,a1
    80005daa:	6914                	ld	a3,16(a0)
    80005dac:	6510                	ld	a2,8(a0)
    80005dae:	610c                	ld	a1,0(a0)
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	30200073          	mret
	...

0000000080005dba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dba:	1141                	addi	sp,sp,-16
    80005dbc:	e422                	sd	s0,8(sp)
    80005dbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005dc0:	0c0007b7          	lui	a5,0xc000
    80005dc4:	4705                	li	a4,1
    80005dc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005dc8:	c3d8                	sw	a4,4(a5)
}
    80005dca:	6422                	ld	s0,8(sp)
    80005dcc:	0141                	addi	sp,sp,16
    80005dce:	8082                	ret

0000000080005dd0 <plicinithart>:

void
plicinithart(void)
{
    80005dd0:	1141                	addi	sp,sp,-16
    80005dd2:	e406                	sd	ra,8(sp)
    80005dd4:	e022                	sd	s0,0(sp)
    80005dd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	c6c080e7          	jalr	-916(ra) # 80001a44 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005de0:	0085171b          	slliw	a4,a0,0x8
    80005de4:	0c0027b7          	lui	a5,0xc002
    80005de8:	97ba                	add	a5,a5,a4
    80005dea:	40200713          	li	a4,1026
    80005dee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005df2:	00d5151b          	slliw	a0,a0,0xd
    80005df6:	0c2017b7          	lui	a5,0xc201
    80005dfa:	953e                	add	a0,a0,a5
    80005dfc:	00052023          	sw	zero,0(a0)
}
    80005e00:	60a2                	ld	ra,8(sp)
    80005e02:	6402                	ld	s0,0(sp)
    80005e04:	0141                	addi	sp,sp,16
    80005e06:	8082                	ret

0000000080005e08 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e08:	1141                	addi	sp,sp,-16
    80005e0a:	e406                	sd	ra,8(sp)
    80005e0c:	e022                	sd	s0,0(sp)
    80005e0e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e10:	ffffc097          	auipc	ra,0xffffc
    80005e14:	c34080e7          	jalr	-972(ra) # 80001a44 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e18:	00d5151b          	slliw	a0,a0,0xd
    80005e1c:	0c2017b7          	lui	a5,0xc201
    80005e20:	97aa                	add	a5,a5,a0
  return irq;
}
    80005e22:	43c8                	lw	a0,4(a5)
    80005e24:	60a2                	ld	ra,8(sp)
    80005e26:	6402                	ld	s0,0(sp)
    80005e28:	0141                	addi	sp,sp,16
    80005e2a:	8082                	ret

0000000080005e2c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e2c:	1101                	addi	sp,sp,-32
    80005e2e:	ec06                	sd	ra,24(sp)
    80005e30:	e822                	sd	s0,16(sp)
    80005e32:	e426                	sd	s1,8(sp)
    80005e34:	1000                	addi	s0,sp,32
    80005e36:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	c0c080e7          	jalr	-1012(ra) # 80001a44 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e40:	00d5151b          	slliw	a0,a0,0xd
    80005e44:	0c2017b7          	lui	a5,0xc201
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	c3c4                	sw	s1,4(a5)
}
    80005e4c:	60e2                	ld	ra,24(sp)
    80005e4e:	6442                	ld	s0,16(sp)
    80005e50:	64a2                	ld	s1,8(sp)
    80005e52:	6105                	addi	sp,sp,32
    80005e54:	8082                	ret

0000000080005e56 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e56:	1141                	addi	sp,sp,-16
    80005e58:	e406                	sd	ra,8(sp)
    80005e5a:	e022                	sd	s0,0(sp)
    80005e5c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e5e:	479d                	li	a5,7
    80005e60:	04a7cd63          	blt	a5,a0,80005eba <free_desc+0x64>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e64:	0001d797          	auipc	a5,0x1d
    80005e68:	19c78793          	addi	a5,a5,412 # 80023000 <disk>
    80005e6c:	00a78733          	add	a4,a5,a0
    80005e70:	6789                	lui	a5,0x2
    80005e72:	97ba                	add	a5,a5,a4
    80005e74:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e78:	eba9                	bnez	a5,80005eca <free_desc+0x74>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e7a:	0001f797          	auipc	a5,0x1f
    80005e7e:	18678793          	addi	a5,a5,390 # 80025000 <disk+0x2000>
    80005e82:	639c                	ld	a5,0(a5)
    80005e84:	00451713          	slli	a4,a0,0x4
    80005e88:	97ba                	add	a5,a5,a4
    80005e8a:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e8e:	0001d797          	auipc	a5,0x1d
    80005e92:	17278793          	addi	a5,a5,370 # 80023000 <disk>
    80005e96:	97aa                	add	a5,a5,a0
    80005e98:	6509                	lui	a0,0x2
    80005e9a:	953e                	add	a0,a0,a5
    80005e9c:	4785                	li	a5,1
    80005e9e:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005ea2:	0001f517          	auipc	a0,0x1f
    80005ea6:	17650513          	addi	a0,a0,374 # 80025018 <disk+0x2018>
    80005eaa:	ffffc097          	auipc	ra,0xffffc
    80005eae:	56e080e7          	jalr	1390(ra) # 80002418 <wakeup>
}
    80005eb2:	60a2                	ld	ra,8(sp)
    80005eb4:	6402                	ld	s0,0(sp)
    80005eb6:	0141                	addi	sp,sp,16
    80005eb8:	8082                	ret
    panic("virtio_disk_intr 1");
    80005eba:	00003517          	auipc	a0,0x3
    80005ebe:	8f650513          	addi	a0,a0,-1802 # 800087b0 <sysnames+0x2f8>
    80005ec2:	ffffa097          	auipc	ra,0xffffa
    80005ec6:	6b2080e7          	jalr	1714(ra) # 80000574 <panic>
    panic("virtio_disk_intr 2");
    80005eca:	00003517          	auipc	a0,0x3
    80005ece:	8fe50513          	addi	a0,a0,-1794 # 800087c8 <sysnames+0x310>
    80005ed2:	ffffa097          	auipc	ra,0xffffa
    80005ed6:	6a2080e7          	jalr	1698(ra) # 80000574 <panic>

0000000080005eda <virtio_disk_init>:
{
    80005eda:	1101                	addi	sp,sp,-32
    80005edc:	ec06                	sd	ra,24(sp)
    80005ede:	e822                	sd	s0,16(sp)
    80005ee0:	e426                	sd	s1,8(sp)
    80005ee2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ee4:	00003597          	auipc	a1,0x3
    80005ee8:	8fc58593          	addi	a1,a1,-1796 # 800087e0 <sysnames+0x328>
    80005eec:	0001f517          	auipc	a0,0x1f
    80005ef0:	1bc50513          	addi	a0,a0,444 # 800250a8 <disk+0x20a8>
    80005ef4:	ffffb097          	auipc	ra,0xffffb
    80005ef8:	cde080e7          	jalr	-802(ra) # 80000bd2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005efc:	100017b7          	lui	a5,0x10001
    80005f00:	4398                	lw	a4,0(a5)
    80005f02:	2701                	sext.w	a4,a4
    80005f04:	747277b7          	lui	a5,0x74727
    80005f08:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f0c:	0ef71163          	bne	a4,a5,80005fee <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f10:	100017b7          	lui	a5,0x10001
    80005f14:	43dc                	lw	a5,4(a5)
    80005f16:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f18:	4705                	li	a4,1
    80005f1a:	0ce79a63          	bne	a5,a4,80005fee <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f1e:	100017b7          	lui	a5,0x10001
    80005f22:	479c                	lw	a5,8(a5)
    80005f24:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f26:	4709                	li	a4,2
    80005f28:	0ce79363          	bne	a5,a4,80005fee <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f2c:	100017b7          	lui	a5,0x10001
    80005f30:	47d8                	lw	a4,12(a5)
    80005f32:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f34:	554d47b7          	lui	a5,0x554d4
    80005f38:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f3c:	0af71963          	bne	a4,a5,80005fee <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f40:	100017b7          	lui	a5,0x10001
    80005f44:	4705                	li	a4,1
    80005f46:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f48:	470d                	li	a4,3
    80005f4a:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f4c:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f4e:	c7ffe737          	lui	a4,0xc7ffe
    80005f52:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f56:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f58:	2701                	sext.w	a4,a4
    80005f5a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f5c:	472d                	li	a4,11
    80005f5e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f60:	473d                	li	a4,15
    80005f62:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f64:	6705                	lui	a4,0x1
    80005f66:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f68:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f6c:	5bdc                	lw	a5,52(a5)
    80005f6e:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f70:	c7d9                	beqz	a5,80005ffe <virtio_disk_init+0x124>
  if(max < NUM)
    80005f72:	471d                	li	a4,7
    80005f74:	08f77d63          	bleu	a5,a4,8000600e <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f78:	100014b7          	lui	s1,0x10001
    80005f7c:	47a1                	li	a5,8
    80005f7e:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f80:	6609                	lui	a2,0x2
    80005f82:	4581                	li	a1,0
    80005f84:	0001d517          	auipc	a0,0x1d
    80005f88:	07c50513          	addi	a0,a0,124 # 80023000 <disk>
    80005f8c:	ffffb097          	auipc	ra,0xffffb
    80005f90:	dd2080e7          	jalr	-558(ra) # 80000d5e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f94:	0001d717          	auipc	a4,0x1d
    80005f98:	06c70713          	addi	a4,a4,108 # 80023000 <disk>
    80005f9c:	00c75793          	srli	a5,a4,0xc
    80005fa0:	2781                	sext.w	a5,a5
    80005fa2:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005fa4:	0001f797          	auipc	a5,0x1f
    80005fa8:	05c78793          	addi	a5,a5,92 # 80025000 <disk+0x2000>
    80005fac:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005fae:	0001d717          	auipc	a4,0x1d
    80005fb2:	0d270713          	addi	a4,a4,210 # 80023080 <disk+0x80>
    80005fb6:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005fb8:	0001e717          	auipc	a4,0x1e
    80005fbc:	04870713          	addi	a4,a4,72 # 80024000 <disk+0x1000>
    80005fc0:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fc2:	4705                	li	a4,1
    80005fc4:	00e78c23          	sb	a4,24(a5)
    80005fc8:	00e78ca3          	sb	a4,25(a5)
    80005fcc:	00e78d23          	sb	a4,26(a5)
    80005fd0:	00e78da3          	sb	a4,27(a5)
    80005fd4:	00e78e23          	sb	a4,28(a5)
    80005fd8:	00e78ea3          	sb	a4,29(a5)
    80005fdc:	00e78f23          	sb	a4,30(a5)
    80005fe0:	00e78fa3          	sb	a4,31(a5)
}
    80005fe4:	60e2                	ld	ra,24(sp)
    80005fe6:	6442                	ld	s0,16(sp)
    80005fe8:	64a2                	ld	s1,8(sp)
    80005fea:	6105                	addi	sp,sp,32
    80005fec:	8082                	ret
    panic("could not find virtio disk");
    80005fee:	00003517          	auipc	a0,0x3
    80005ff2:	80250513          	addi	a0,a0,-2046 # 800087f0 <sysnames+0x338>
    80005ff6:	ffffa097          	auipc	ra,0xffffa
    80005ffa:	57e080e7          	jalr	1406(ra) # 80000574 <panic>
    panic("virtio disk has no queue 0");
    80005ffe:	00003517          	auipc	a0,0x3
    80006002:	81250513          	addi	a0,a0,-2030 # 80008810 <sysnames+0x358>
    80006006:	ffffa097          	auipc	ra,0xffffa
    8000600a:	56e080e7          	jalr	1390(ra) # 80000574 <panic>
    panic("virtio disk max queue too short");
    8000600e:	00003517          	auipc	a0,0x3
    80006012:	82250513          	addi	a0,a0,-2014 # 80008830 <sysnames+0x378>
    80006016:	ffffa097          	auipc	ra,0xffffa
    8000601a:	55e080e7          	jalr	1374(ra) # 80000574 <panic>

000000008000601e <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000601e:	7159                	addi	sp,sp,-112
    80006020:	f486                	sd	ra,104(sp)
    80006022:	f0a2                	sd	s0,96(sp)
    80006024:	eca6                	sd	s1,88(sp)
    80006026:	e8ca                	sd	s2,80(sp)
    80006028:	e4ce                	sd	s3,72(sp)
    8000602a:	e0d2                	sd	s4,64(sp)
    8000602c:	fc56                	sd	s5,56(sp)
    8000602e:	f85a                	sd	s6,48(sp)
    80006030:	f45e                	sd	s7,40(sp)
    80006032:	f062                	sd	s8,32(sp)
    80006034:	1880                	addi	s0,sp,112
    80006036:	892a                	mv	s2,a0
    80006038:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000603a:	00c52b83          	lw	s7,12(a0)
    8000603e:	001b9b9b          	slliw	s7,s7,0x1
    80006042:	1b82                	slli	s7,s7,0x20
    80006044:	020bdb93          	srli	s7,s7,0x20

  acquire(&disk.vdisk_lock);
    80006048:	0001f517          	auipc	a0,0x1f
    8000604c:	06050513          	addi	a0,a0,96 # 800250a8 <disk+0x20a8>
    80006050:	ffffb097          	auipc	ra,0xffffb
    80006054:	c12080e7          	jalr	-1006(ra) # 80000c62 <acquire>
    if(disk.free[i]){
    80006058:	0001f997          	auipc	s3,0x1f
    8000605c:	fa898993          	addi	s3,s3,-88 # 80025000 <disk+0x2000>
  for(int i = 0; i < NUM; i++){
    80006060:	4b21                	li	s6,8
      disk.free[i] = 0;
    80006062:	0001da97          	auipc	s5,0x1d
    80006066:	f9ea8a93          	addi	s5,s5,-98 # 80023000 <disk>
  for(int i = 0; i < 3; i++){
    8000606a:	4a0d                	li	s4,3
    8000606c:	a079                	j	800060fa <virtio_disk_rw+0xdc>
      disk.free[i] = 0;
    8000606e:	00fa86b3          	add	a3,s5,a5
    80006072:	96ae                	add	a3,a3,a1
    80006074:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006078:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000607a:	0207ca63          	bltz	a5,800060ae <virtio_disk_rw+0x90>
  for(int i = 0; i < 3; i++){
    8000607e:	2485                	addiw	s1,s1,1
    80006080:	0711                	addi	a4,a4,4
    80006082:	25448163          	beq	s1,s4,800062c4 <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006086:	863a                	mv	a2,a4
    if(disk.free[i]){
    80006088:	0189c783          	lbu	a5,24(s3)
    8000608c:	24079163          	bnez	a5,800062ce <virtio_disk_rw+0x2b0>
    80006090:	0001f697          	auipc	a3,0x1f
    80006094:	f8968693          	addi	a3,a3,-119 # 80025019 <disk+0x2019>
  for(int i = 0; i < NUM; i++){
    80006098:	87aa                	mv	a5,a0
    if(disk.free[i]){
    8000609a:	0006c803          	lbu	a6,0(a3)
    8000609e:	fc0818e3          	bnez	a6,8000606e <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    800060a2:	2785                	addiw	a5,a5,1
    800060a4:	0685                	addi	a3,a3,1
    800060a6:	ff679ae3          	bne	a5,s6,8000609a <virtio_disk_rw+0x7c>
    idx[i] = alloc_desc();
    800060aa:	57fd                	li	a5,-1
    800060ac:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060ae:	02905a63          	blez	s1,800060e2 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800060b2:	fa042503          	lw	a0,-96(s0)
    800060b6:	00000097          	auipc	ra,0x0
    800060ba:	da0080e7          	jalr	-608(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060be:	4785                	li	a5,1
    800060c0:	0297d163          	ble	s1,a5,800060e2 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800060c4:	fa442503          	lw	a0,-92(s0)
    800060c8:	00000097          	auipc	ra,0x0
    800060cc:	d8e080e7          	jalr	-626(ra) # 80005e56 <free_desc>
      for(int j = 0; j < i; j++)
    800060d0:	4789                	li	a5,2
    800060d2:	0097d863          	ble	s1,a5,800060e2 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800060d6:	fa842503          	lw	a0,-88(s0)
    800060da:	00000097          	auipc	ra,0x0
    800060de:	d7c080e7          	jalr	-644(ra) # 80005e56 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060e2:	0001f597          	auipc	a1,0x1f
    800060e6:	fc658593          	addi	a1,a1,-58 # 800250a8 <disk+0x20a8>
    800060ea:	0001f517          	auipc	a0,0x1f
    800060ee:	f2e50513          	addi	a0,a0,-210 # 80025018 <disk+0x2018>
    800060f2:	ffffc097          	auipc	ra,0xffffc
    800060f6:	1a0080e7          	jalr	416(ra) # 80002292 <sleep>
  for(int i = 0; i < 3; i++){
    800060fa:	fa040713          	addi	a4,s0,-96
    800060fe:	4481                	li	s1,0
  for(int i = 0; i < NUM; i++){
    80006100:	4505                	li	a0,1
      disk.free[i] = 0;
    80006102:	6589                	lui	a1,0x2
    80006104:	b749                	j	80006086 <virtio_disk_rw+0x68>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006106:	4785                	li	a5,1
    80006108:	f8f42823          	sw	a5,-112(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000610c:	f8042a23          	sw	zero,-108(s0)
  buf0.sector = sector;
    80006110:	f9743c23          	sd	s7,-104(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006114:	fa042983          	lw	s3,-96(s0)
    80006118:	00499493          	slli	s1,s3,0x4
    8000611c:	0001fa17          	auipc	s4,0x1f
    80006120:	ee4a0a13          	addi	s4,s4,-284 # 80025000 <disk+0x2000>
    80006124:	000a3a83          	ld	s5,0(s4)
    80006128:	9aa6                	add	s5,s5,s1
    8000612a:	f9040513          	addi	a0,s0,-112
    8000612e:	ffffb097          	auipc	ra,0xffffb
    80006132:	028080e7          	jalr	40(ra) # 80001156 <kvmpa>
    80006136:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000613a:	000a3783          	ld	a5,0(s4)
    8000613e:	97a6                	add	a5,a5,s1
    80006140:	4741                	li	a4,16
    80006142:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006144:	000a3783          	ld	a5,0(s4)
    80006148:	97a6                	add	a5,a5,s1
    8000614a:	4705                	li	a4,1
    8000614c:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006150:	fa442703          	lw	a4,-92(s0)
    80006154:	000a3783          	ld	a5,0(s4)
    80006158:	97a6                	add	a5,a5,s1
    8000615a:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000615e:	0712                	slli	a4,a4,0x4
    80006160:	000a3783          	ld	a5,0(s4)
    80006164:	97ba                	add	a5,a5,a4
    80006166:	05890693          	addi	a3,s2,88
    8000616a:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000616c:	000a3783          	ld	a5,0(s4)
    80006170:	97ba                	add	a5,a5,a4
    80006172:	40000693          	li	a3,1024
    80006176:	c794                	sw	a3,8(a5)
  if(write)
    80006178:	100c0863          	beqz	s8,80006288 <virtio_disk_rw+0x26a>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000617c:	000a3783          	ld	a5,0(s4)
    80006180:	97ba                	add	a5,a5,a4
    80006182:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006186:	0001d517          	auipc	a0,0x1d
    8000618a:	e7a50513          	addi	a0,a0,-390 # 80023000 <disk>
    8000618e:	0001f797          	auipc	a5,0x1f
    80006192:	e7278793          	addi	a5,a5,-398 # 80025000 <disk+0x2000>
    80006196:	6394                	ld	a3,0(a5)
    80006198:	96ba                	add	a3,a3,a4
    8000619a:	00c6d603          	lhu	a2,12(a3)
    8000619e:	00166613          	ori	a2,a2,1
    800061a2:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061a6:	fa842683          	lw	a3,-88(s0)
    800061aa:	6390                	ld	a2,0(a5)
    800061ac:	9732                	add	a4,a4,a2
    800061ae:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800061b2:	20098613          	addi	a2,s3,512
    800061b6:	0612                	slli	a2,a2,0x4
    800061b8:	962a                	add	a2,a2,a0
    800061ba:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061be:	00469713          	slli	a4,a3,0x4
    800061c2:	6394                	ld	a3,0(a5)
    800061c4:	96ba                	add	a3,a3,a4
    800061c6:	6589                	lui	a1,0x2
    800061c8:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800061cc:	94ae                	add	s1,s1,a1
    800061ce:	94aa                	add	s1,s1,a0
    800061d0:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800061d2:	6394                	ld	a3,0(a5)
    800061d4:	96ba                	add	a3,a3,a4
    800061d6:	4585                	li	a1,1
    800061d8:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061da:	6394                	ld	a3,0(a5)
    800061dc:	96ba                	add	a3,a3,a4
    800061de:	4509                	li	a0,2
    800061e0:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800061e4:	6394                	ld	a3,0(a5)
    800061e6:	9736                	add	a4,a4,a3
    800061e8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061ec:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061f0:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800061f4:	6794                	ld	a3,8(a5)
    800061f6:	0026d703          	lhu	a4,2(a3)
    800061fa:	8b1d                	andi	a4,a4,7
    800061fc:	2709                	addiw	a4,a4,2
    800061fe:	0706                	slli	a4,a4,0x1
    80006200:	9736                	add	a4,a4,a3
    80006202:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    80006206:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000620a:	6798                	ld	a4,8(a5)
    8000620c:	00275783          	lhu	a5,2(a4)
    80006210:	2785                	addiw	a5,a5,1
    80006212:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006216:	100017b7          	lui	a5,0x10001
    8000621a:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000621e:	00492703          	lw	a4,4(s2)
    80006222:	4785                	li	a5,1
    80006224:	02f71163          	bne	a4,a5,80006246 <virtio_disk_rw+0x228>
    sleep(b, &disk.vdisk_lock);
    80006228:	0001f997          	auipc	s3,0x1f
    8000622c:	e8098993          	addi	s3,s3,-384 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006230:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006232:	85ce                	mv	a1,s3
    80006234:	854a                	mv	a0,s2
    80006236:	ffffc097          	auipc	ra,0xffffc
    8000623a:	05c080e7          	jalr	92(ra) # 80002292 <sleep>
  while(b->disk == 1) {
    8000623e:	00492783          	lw	a5,4(s2)
    80006242:	fe9788e3          	beq	a5,s1,80006232 <virtio_disk_rw+0x214>
  }

  disk.info[idx[0]].b = 0;
    80006246:	fa042483          	lw	s1,-96(s0)
    8000624a:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    8000624e:	00479713          	slli	a4,a5,0x4
    80006252:	0001d797          	auipc	a5,0x1d
    80006256:	dae78793          	addi	a5,a5,-594 # 80023000 <disk>
    8000625a:	97ba                	add	a5,a5,a4
    8000625c:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006260:	0001f917          	auipc	s2,0x1f
    80006264:	da090913          	addi	s2,s2,-608 # 80025000 <disk+0x2000>
    free_desc(i);
    80006268:	8526                	mv	a0,s1
    8000626a:	00000097          	auipc	ra,0x0
    8000626e:	bec080e7          	jalr	-1044(ra) # 80005e56 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006272:	0492                	slli	s1,s1,0x4
    80006274:	00093783          	ld	a5,0(s2)
    80006278:	94be                	add	s1,s1,a5
    8000627a:	00c4d783          	lhu	a5,12(s1)
    8000627e:	8b85                	andi	a5,a5,1
    80006280:	cf91                	beqz	a5,8000629c <virtio_disk_rw+0x27e>
      i = disk.desc[i].next;
    80006282:	00e4d483          	lhu	s1,14(s1)
  while(1){
    80006286:	b7cd                	j	80006268 <virtio_disk_rw+0x24a>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006288:	0001f797          	auipc	a5,0x1f
    8000628c:	d7878793          	addi	a5,a5,-648 # 80025000 <disk+0x2000>
    80006290:	639c                	ld	a5,0(a5)
    80006292:	97ba                	add	a5,a5,a4
    80006294:	4689                	li	a3,2
    80006296:	00d79623          	sh	a3,12(a5)
    8000629a:	b5f5                	j	80006186 <virtio_disk_rw+0x168>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000629c:	0001f517          	auipc	a0,0x1f
    800062a0:	e0c50513          	addi	a0,a0,-500 # 800250a8 <disk+0x20a8>
    800062a4:	ffffb097          	auipc	ra,0xffffb
    800062a8:	a72080e7          	jalr	-1422(ra) # 80000d16 <release>
}
    800062ac:	70a6                	ld	ra,104(sp)
    800062ae:	7406                	ld	s0,96(sp)
    800062b0:	64e6                	ld	s1,88(sp)
    800062b2:	6946                	ld	s2,80(sp)
    800062b4:	69a6                	ld	s3,72(sp)
    800062b6:	6a06                	ld	s4,64(sp)
    800062b8:	7ae2                	ld	s5,56(sp)
    800062ba:	7b42                	ld	s6,48(sp)
    800062bc:	7ba2                	ld	s7,40(sp)
    800062be:	7c02                	ld	s8,32(sp)
    800062c0:	6165                	addi	sp,sp,112
    800062c2:	8082                	ret
  if(write)
    800062c4:	e40c11e3          	bnez	s8,80006106 <virtio_disk_rw+0xe8>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800062c8:	f8042823          	sw	zero,-112(s0)
    800062cc:	b581                	j	8000610c <virtio_disk_rw+0xee>
      disk.free[i] = 0;
    800062ce:	00098c23          	sb	zero,24(s3)
    idx[i] = alloc_desc();
    800062d2:	00072023          	sw	zero,0(a4)
    if(idx[i] < 0){
    800062d6:	b365                	j	8000607e <virtio_disk_rw+0x60>

00000000800062d8 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062d8:	1101                	addi	sp,sp,-32
    800062da:	ec06                	sd	ra,24(sp)
    800062dc:	e822                	sd	s0,16(sp)
    800062de:	e426                	sd	s1,8(sp)
    800062e0:	e04a                	sd	s2,0(sp)
    800062e2:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062e4:	0001f517          	auipc	a0,0x1f
    800062e8:	dc450513          	addi	a0,a0,-572 # 800250a8 <disk+0x20a8>
    800062ec:	ffffb097          	auipc	ra,0xffffb
    800062f0:	976080e7          	jalr	-1674(ra) # 80000c62 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062f4:	0001f797          	auipc	a5,0x1f
    800062f8:	d0c78793          	addi	a5,a5,-756 # 80025000 <disk+0x2000>
    800062fc:	0207d683          	lhu	a3,32(a5)
    80006300:	6b98                	ld	a4,16(a5)
    80006302:	00275783          	lhu	a5,2(a4)
    80006306:	8fb5                	xor	a5,a5,a3
    80006308:	8b9d                	andi	a5,a5,7
    8000630a:	c7c9                	beqz	a5,80006394 <virtio_disk_intr+0xbc>
    int id = disk.used->elems[disk.used_idx].id;
    8000630c:	068e                	slli	a3,a3,0x3
    8000630e:	9736                	add	a4,a4,a3
    80006310:	435c                	lw	a5,4(a4)

    if(disk.info[id].status != 0)
    80006312:	20078713          	addi	a4,a5,512
    80006316:	00471693          	slli	a3,a4,0x4
    8000631a:	0001d717          	auipc	a4,0x1d
    8000631e:	ce670713          	addi	a4,a4,-794 # 80023000 <disk>
    80006322:	9736                	add	a4,a4,a3
    80006324:	03074703          	lbu	a4,48(a4)
    80006328:	ef31                	bnez	a4,80006384 <virtio_disk_intr+0xac>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000632a:	0001d917          	auipc	s2,0x1d
    8000632e:	cd690913          	addi	s2,s2,-810 # 80023000 <disk>
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006332:	0001f497          	auipc	s1,0x1f
    80006336:	cce48493          	addi	s1,s1,-818 # 80025000 <disk+0x2000>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000633a:	20078793          	addi	a5,a5,512
    8000633e:	0792                	slli	a5,a5,0x4
    80006340:	97ca                	add	a5,a5,s2
    80006342:	7798                	ld	a4,40(a5)
    80006344:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    80006348:	7788                	ld	a0,40(a5)
    8000634a:	ffffc097          	auipc	ra,0xffffc
    8000634e:	0ce080e7          	jalr	206(ra) # 80002418 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006352:	0204d783          	lhu	a5,32(s1)
    80006356:	2785                	addiw	a5,a5,1
    80006358:	8b9d                	andi	a5,a5,7
    8000635a:	03079613          	slli	a2,a5,0x30
    8000635e:	9241                	srli	a2,a2,0x30
    80006360:	02c49023          	sh	a2,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006364:	6898                	ld	a4,16(s1)
    80006366:	00275683          	lhu	a3,2(a4)
    8000636a:	8a9d                	andi	a3,a3,7
    8000636c:	02c68463          	beq	a3,a2,80006394 <virtio_disk_intr+0xbc>
    int id = disk.used->elems[disk.used_idx].id;
    80006370:	078e                	slli	a5,a5,0x3
    80006372:	97ba                	add	a5,a5,a4
    80006374:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006376:	20078713          	addi	a4,a5,512
    8000637a:	0712                	slli	a4,a4,0x4
    8000637c:	974a                	add	a4,a4,s2
    8000637e:	03074703          	lbu	a4,48(a4)
    80006382:	df45                	beqz	a4,8000633a <virtio_disk_intr+0x62>
      panic("virtio_disk_intr status");
    80006384:	00002517          	auipc	a0,0x2
    80006388:	4cc50513          	addi	a0,a0,1228 # 80008850 <sysnames+0x398>
    8000638c:	ffffa097          	auipc	ra,0xffffa
    80006390:	1e8080e7          	jalr	488(ra) # 80000574 <panic>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006394:	10001737          	lui	a4,0x10001
    80006398:	533c                	lw	a5,96(a4)
    8000639a:	8b8d                	andi	a5,a5,3
    8000639c:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    8000639e:	0001f517          	auipc	a0,0x1f
    800063a2:	d0a50513          	addi	a0,a0,-758 # 800250a8 <disk+0x20a8>
    800063a6:	ffffb097          	auipc	ra,0xffffb
    800063aa:	970080e7          	jalr	-1680(ra) # 80000d16 <release>
}
    800063ae:	60e2                	ld	ra,24(sp)
    800063b0:	6442                	ld	s0,16(sp)
    800063b2:	64a2                	ld	s1,8(sp)
    800063b4:	6902                	ld	s2,0(sp)
    800063b6:	6105                	addi	sp,sp,32
    800063b8:	8082                	ret
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
