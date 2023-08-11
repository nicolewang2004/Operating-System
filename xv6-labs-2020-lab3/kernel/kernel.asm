
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9a013103          	ld	sp,-1632(sp) # 800089a0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000062:	fc278793          	addi	a5,a5,-62 # 80006020 <timervec>
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
    80000096:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
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
    8000012c:	6fa080e7          	jalr	1786(ra) # 80002822 <either_copyin>
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
    800001d4:	988080e7          	jalr	-1656(ra) # 80001b58 <myproc>
    800001d8:	591c                	lw	a5,48(a0)
    800001da:	eba5                	bnez	a5,8000024a <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001dc:	85ce                	mv	a1,s3
    800001de:	854a                	mv	a0,s2
    800001e0:	00002097          	auipc	ra,0x2
    800001e4:	38a080e7          	jalr	906(ra) # 8000256a <sleep>
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
    80000220:	5b0080e7          	jalr	1456(ra) # 800027cc <either_copyout>
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
    8000041a:	462080e7          	jalr	1122(ra) # 80002878 <procdump>
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
    8000047c:	278080e7          	jalr	632(ra) # 800026f0 <wakeup>
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
    800008f2:	e02080e7          	jalr	-510(ra) # 800026f0 <wakeup>
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
    800009a2:	bcc080e7          	jalr	-1076(ra) # 8000256a <sleep>
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
    80000a88:	00026797          	auipc	a5,0x26
    80000a8c:	59878793          	addi	a5,a5,1432 # 80027020 <end>
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
    80000b5a:	00026517          	auipc	a0,0x26
    80000b5e:	4c650513          	addi	a0,a0,1222 # 80027020 <end>
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
    80000c00:	f40080e7          	jalr	-192(ra) # 80001b3c <mycpu>
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
    80000c32:	f0e080e7          	jalr	-242(ra) # 80001b3c <mycpu>
    80000c36:	5d3c                	lw	a5,120(a0)
    80000c38:	cf89                	beqz	a5,80000c52 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c3a:	00001097          	auipc	ra,0x1
    80000c3e:	f02080e7          	jalr	-254(ra) # 80001b3c <mycpu>
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
    80000c56:	eea080e7          	jalr	-278(ra) # 80001b3c <mycpu>
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
    80000c96:	eaa080e7          	jalr	-342(ra) # 80001b3c <mycpu>
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
    80000cc2:	e7e080e7          	jalr	-386(ra) # 80001b3c <mycpu>
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
    80000d74:	00b78023          	sb	a1,0(a5) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
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
    80000f3e:	bf2080e7          	jalr	-1038(ra) # 80001b2c <cpuid>
#endif    
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
    80000f5a:	bd6080e7          	jalr	-1066(ra) # 80001b2c <cpuid>
    80000f5e:	85aa                	mv	a1,a0
    80000f60:	00007517          	auipc	a0,0x7
    80000f64:	15850513          	addi	a0,a0,344 # 800080b8 <digits+0xa0>
    80000f68:	fffff097          	auipc	ra,0xfffff
    80000f6c:	656080e7          	jalr	1622(ra) # 800005be <printf>
    kvminithart();    // turn on paging
    80000f70:	00000097          	auipc	ra,0x0
    80000f74:	0e0080e7          	jalr	224(ra) # 80001050 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f78:	00002097          	auipc	ra,0x2
    80000f7c:	a42080e7          	jalr	-1470(ra) # 800029ba <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	0e0080e7          	jalr	224(ra) # 80006060 <plicinithart>
  }

  scheduler();        
    80000f88:	00001097          	auipc	ra,0x1
    80000f8c:	2e6080e7          	jalr	742(ra) # 8000226e <scheduler>
    consoleinit();
    80000f90:	fffff097          	auipc	ra,0xfffff
    80000f94:	4f2080e7          	jalr	1266(ra) # 80000482 <consoleinit>
    statsinit();
    80000f98:	00006097          	auipc	ra,0x6
    80000f9c:	8dc080e7          	jalr	-1828(ra) # 80006874 <statsinit>
    printfinit();
    80000fa0:	00000097          	auipc	ra,0x0
    80000fa4:	804080e7          	jalr	-2044(ra) # 800007a4 <printfinit>
    printf("\n");
    80000fa8:	00007517          	auipc	a0,0x7
    80000fac:	12050513          	addi	a0,a0,288 # 800080c8 <digits+0xb0>
    80000fb0:	fffff097          	auipc	ra,0xfffff
    80000fb4:	60e080e7          	jalr	1550(ra) # 800005be <printf>
    printf("xv6 kernel is booting\n");
    80000fb8:	00007517          	auipc	a0,0x7
    80000fbc:	0e850513          	addi	a0,a0,232 # 800080a0 <digits+0x88>
    80000fc0:	fffff097          	auipc	ra,0xfffff
    80000fc4:	5fe080e7          	jalr	1534(ra) # 800005be <printf>
    printf("\n");
    80000fc8:	00007517          	auipc	a0,0x7
    80000fcc:	10050513          	addi	a0,a0,256 # 800080c8 <digits+0xb0>
    80000fd0:	fffff097          	auipc	ra,0xfffff
    80000fd4:	5ee080e7          	jalr	1518(ra) # 800005be <printf>
    kinit();         // physical page allocator
    80000fd8:	00000097          	auipc	ra,0x0
    80000fdc:	b5e080e7          	jalr	-1186(ra) # 80000b36 <kinit>
    kvminit();       // create kernel page table
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	2ae080e7          	jalr	686(ra) # 8000128e <kvminit>
    kvminithart();   // turn on paging
    80000fe8:	00000097          	auipc	ra,0x0
    80000fec:	068080e7          	jalr	104(ra) # 80001050 <kvminithart>
    procinit();      // process table
    80000ff0:	00001097          	auipc	ra,0x1
    80000ff4:	adc080e7          	jalr	-1316(ra) # 80001acc <procinit>
    trapinit();      // trap vectors
    80000ff8:	00002097          	auipc	ra,0x2
    80000ffc:	99a080e7          	jalr	-1638(ra) # 80002992 <trapinit>
    trapinithart();  // install kernel trap vector
    80001000:	00002097          	auipc	ra,0x2
    80001004:	9ba080e7          	jalr	-1606(ra) # 800029ba <trapinithart>
    plicinit();      // set up interrupt controller
    80001008:	00005097          	auipc	ra,0x5
    8000100c:	042080e7          	jalr	66(ra) # 8000604a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001010:	00005097          	auipc	ra,0x5
    80001014:	050080e7          	jalr	80(ra) # 80006060 <plicinithart>
    binit();         // buffer cache
    80001018:	00002097          	auipc	ra,0x2
    8000101c:	0f2080e7          	jalr	242(ra) # 8000310a <binit>
    iinit();         // inode cache
    80001020:	00002097          	auipc	ra,0x2
    80001024:	7c4080e7          	jalr	1988(ra) # 800037e4 <iinit>
    fileinit();      // file table
    80001028:	00003097          	auipc	ra,0x3
    8000102c:	78a080e7          	jalr	1930(ra) # 800047b2 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001030:	00005097          	auipc	ra,0x5
    80001034:	13a080e7          	jalr	314(ra) # 8000616a <virtio_disk_init>
    userinit();      // first user process
    80001038:	00001097          	auipc	ra,0x1
    8000103c:	f4c080e7          	jalr	-180(ra) # 80001f84 <userinit>
    __sync_synchronize();
    80001040:	0ff0000f          	fence
    started = 1;
    80001044:	4785                	li	a5,1
    80001046:	00008717          	auipc	a4,0x8
    8000104a:	fcf72323          	sw	a5,-58(a4) # 8000900c <started>
    8000104e:	bf2d                	j	80000f88 <main+0x56>

0000000080001050 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001050:	1141                	addi	sp,sp,-16
    80001052:	e422                	sd	s0,8(sp)
    80001054:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001056:	00008797          	auipc	a5,0x8
    8000105a:	fba78793          	addi	a5,a5,-70 # 80009010 <kernel_pagetable>
    8000105e:	639c                	ld	a5,0(a5)
    80001060:	83b1                	srli	a5,a5,0xc
    80001062:	577d                	li	a4,-1
    80001064:	177e                	slli	a4,a4,0x3f
    80001066:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001068:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000106c:	12000073          	sfence.vma
  sfence_vma();
}
    80001070:	6422                	ld	s0,8(sp)
    80001072:	0141                	addi	sp,sp,16
    80001074:	8082                	ret

0000000080001076 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001076:	7139                	addi	sp,sp,-64
    80001078:	fc06                	sd	ra,56(sp)
    8000107a:	f822                	sd	s0,48(sp)
    8000107c:	f426                	sd	s1,40(sp)
    8000107e:	f04a                	sd	s2,32(sp)
    80001080:	ec4e                	sd	s3,24(sp)
    80001082:	e852                	sd	s4,16(sp)
    80001084:	e456                	sd	s5,8(sp)
    80001086:	e05a                	sd	s6,0(sp)
    80001088:	0080                	addi	s0,sp,64
    8000108a:	84aa                	mv	s1,a0
    8000108c:	89ae                	mv	s3,a1
    8000108e:	8b32                	mv	s6,a2
  if(va >= MAXVA)
    80001090:	57fd                	li	a5,-1
    80001092:	83e9                	srli	a5,a5,0x1a
    80001094:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001096:	4ab1                	li	s5,12
  if(va >= MAXVA)
    80001098:	04b7f263          	bleu	a1,a5,800010dc <walk+0x66>
    panic("walk");
    8000109c:	00007517          	auipc	a0,0x7
    800010a0:	05450513          	addi	a0,a0,84 # 800080f0 <indent.1777+0x20>
    800010a4:	fffff097          	auipc	ra,0xfffff
    800010a8:	4d0080e7          	jalr	1232(ra) # 80000574 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010ac:	060b0663          	beqz	s6,80001118 <walk+0xa2>
    800010b0:	00000097          	auipc	ra,0x0
    800010b4:	ac2080e7          	jalr	-1342(ra) # 80000b72 <kalloc>
    800010b8:	84aa                	mv	s1,a0
    800010ba:	c529                	beqz	a0,80001104 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010bc:	6605                	lui	a2,0x1
    800010be:	4581                	li	a1,0
    800010c0:	00000097          	auipc	ra,0x0
    800010c4:	c9e080e7          	jalr	-866(ra) # 80000d5e <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010c8:	00c4d793          	srli	a5,s1,0xc
    800010cc:	07aa                	slli	a5,a5,0xa
    800010ce:	0017e793          	ori	a5,a5,1
    800010d2:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010d6:	3a5d                	addiw	s4,s4,-9
    800010d8:	035a0063          	beq	s4,s5,800010f8 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010dc:	0149d933          	srl	s2,s3,s4
    800010e0:	1ff97913          	andi	s2,s2,511
    800010e4:	090e                	slli	s2,s2,0x3
    800010e6:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010e8:	00093483          	ld	s1,0(s2)
    800010ec:	0014f793          	andi	a5,s1,1
    800010f0:	dfd5                	beqz	a5,800010ac <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010f2:	80a9                	srli	s1,s1,0xa
    800010f4:	04b2                	slli	s1,s1,0xc
    800010f6:	b7c5                	j	800010d6 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010f8:	00c9d513          	srli	a0,s3,0xc
    800010fc:	1ff57513          	andi	a0,a0,511
    80001100:	050e                	slli	a0,a0,0x3
    80001102:	9526                	add	a0,a0,s1
}
    80001104:	70e2                	ld	ra,56(sp)
    80001106:	7442                	ld	s0,48(sp)
    80001108:	74a2                	ld	s1,40(sp)
    8000110a:	7902                	ld	s2,32(sp)
    8000110c:	69e2                	ld	s3,24(sp)
    8000110e:	6a42                	ld	s4,16(sp)
    80001110:	6aa2                	ld	s5,8(sp)
    80001112:	6b02                	ld	s6,0(sp)
    80001114:	6121                	addi	sp,sp,64
    80001116:	8082                	ret
        return 0;
    80001118:	4501                	li	a0,0
    8000111a:	b7ed                	j	80001104 <walk+0x8e>

000000008000111c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000111c:	57fd                	li	a5,-1
    8000111e:	83e9                	srli	a5,a5,0x1a
    80001120:	00b7f463          	bleu	a1,a5,80001128 <walkaddr+0xc>
    return 0;
    80001124:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001126:	8082                	ret
{
    80001128:	1141                	addi	sp,sp,-16
    8000112a:	e406                	sd	ra,8(sp)
    8000112c:	e022                	sd	s0,0(sp)
    8000112e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001130:	4601                	li	a2,0
    80001132:	00000097          	auipc	ra,0x0
    80001136:	f44080e7          	jalr	-188(ra) # 80001076 <walk>
  if(pte == 0)
    8000113a:	c105                	beqz	a0,8000115a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000113c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000113e:	0117f693          	andi	a3,a5,17
    80001142:	4745                	li	a4,17
    return 0;
    80001144:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001146:	00e68663          	beq	a3,a4,80001152 <walkaddr+0x36>
}
    8000114a:	60a2                	ld	ra,8(sp)
    8000114c:	6402                	ld	s0,0(sp)
    8000114e:	0141                	addi	sp,sp,16
    80001150:	8082                	ret
  pa = PTE2PA(*pte);
    80001152:	00a7d513          	srli	a0,a5,0xa
    80001156:	0532                	slli	a0,a0,0xc
  return pa;
    80001158:	bfcd                	j	8000114a <walkaddr+0x2e>
    return 0;
    8000115a:	4501                	li	a0,0
    8000115c:	b7fd                	j	8000114a <walkaddr+0x2e>

000000008000115e <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    8000115e:	1101                	addi	sp,sp,-32
    80001160:	ec06                	sd	ra,24(sp)
    80001162:	e822                	sd	s0,16(sp)
    80001164:	e426                	sd	s1,8(sp)
    80001166:	e04a                	sd	s2,0(sp)
    80001168:	1000                	addi	s0,sp,32
    8000116a:	892a                	mv	s2,a0
  uint64 off = va % PGSIZE;
    8000116c:	6505                	lui	a0,0x1
    8000116e:	157d                	addi	a0,a0,-1
    80001170:	00a974b3          	and	s1,s2,a0
  pte_t *pte;
  uint64 pa;

  // 将walk函数的第一个参数改为进程私有的内核页表  
  struct proc* p = myproc();
    80001174:	00001097          	auipc	ra,0x1
    80001178:	9e4080e7          	jalr	-1564(ra) # 80001b58 <myproc>

  pte = walk(p->kernel_pagetable, va, 0);
    8000117c:	4601                	li	a2,0
    8000117e:	85ca                	mv	a1,s2
    80001180:	16853503          	ld	a0,360(a0) # 1168 <_entry-0x7fffee98>
    80001184:	00000097          	auipc	ra,0x0
    80001188:	ef2080e7          	jalr	-270(ra) # 80001076 <walk>
  if(pte == 0)
    8000118c:	cd11                	beqz	a0,800011a8 <kvmpa+0x4a>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000118e:	6108                	ld	a0,0(a0)
    80001190:	00157793          	andi	a5,a0,1
    80001194:	c395                	beqz	a5,800011b8 <kvmpa+0x5a>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001196:	8129                	srli	a0,a0,0xa
    80001198:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    8000119a:	9526                	add	a0,a0,s1
    8000119c:	60e2                	ld	ra,24(sp)
    8000119e:	6442                	ld	s0,16(sp)
    800011a0:	64a2                	ld	s1,8(sp)
    800011a2:	6902                	ld	s2,0(sp)
    800011a4:	6105                	addi	sp,sp,32
    800011a6:	8082                	ret
    panic("kvmpa");
    800011a8:	00007517          	auipc	a0,0x7
    800011ac:	f5050513          	addi	a0,a0,-176 # 800080f8 <indent.1777+0x28>
    800011b0:	fffff097          	auipc	ra,0xfffff
    800011b4:	3c4080e7          	jalr	964(ra) # 80000574 <panic>
    panic("kvmpa");
    800011b8:	00007517          	auipc	a0,0x7
    800011bc:	f4050513          	addi	a0,a0,-192 # 800080f8 <indent.1777+0x28>
    800011c0:	fffff097          	auipc	ra,0xfffff
    800011c4:	3b4080e7          	jalr	948(ra) # 80000574 <panic>

00000000800011c8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011c8:	715d                	addi	sp,sp,-80
    800011ca:	e486                	sd	ra,72(sp)
    800011cc:	e0a2                	sd	s0,64(sp)
    800011ce:	fc26                	sd	s1,56(sp)
    800011d0:	f84a                	sd	s2,48(sp)
    800011d2:	f44e                	sd	s3,40(sp)
    800011d4:	f052                	sd	s4,32(sp)
    800011d6:	ec56                	sd	s5,24(sp)
    800011d8:	e85a                	sd	s6,16(sp)
    800011da:	e45e                	sd	s7,8(sp)
    800011dc:	0880                	addi	s0,sp,80
    800011de:	8aaa                	mv	s5,a0
    800011e0:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011e2:	79fd                	lui	s3,0xfffff
    800011e4:	0135fa33          	and	s4,a1,s3
  last = PGROUNDDOWN(va + size - 1);
    800011e8:	167d                	addi	a2,a2,-1
    800011ea:	962e                	add	a2,a2,a1
    800011ec:	013679b3          	and	s3,a2,s3
  a = PGROUNDDOWN(va);
    800011f0:	8952                	mv	s2,s4
    800011f2:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011f6:	6b85                	lui	s7,0x1
    800011f8:	a811                	j	8000120c <mappages+0x44>
      panic("remap");
    800011fa:	00007517          	auipc	a0,0x7
    800011fe:	f0650513          	addi	a0,a0,-250 # 80008100 <indent.1777+0x30>
    80001202:	fffff097          	auipc	ra,0xfffff
    80001206:	372080e7          	jalr	882(ra) # 80000574 <panic>
    a += PGSIZE;
    8000120a:	995e                	add	s2,s2,s7
  for(;;){
    8000120c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001210:	4605                	li	a2,1
    80001212:	85ca                	mv	a1,s2
    80001214:	8556                	mv	a0,s5
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	e60080e7          	jalr	-416(ra) # 80001076 <walk>
    8000121e:	cd19                	beqz	a0,8000123c <mappages+0x74>
    if(*pte & PTE_V)
    80001220:	611c                	ld	a5,0(a0)
    80001222:	8b85                	andi	a5,a5,1
    80001224:	fbf9                	bnez	a5,800011fa <mappages+0x32>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001226:	80b1                	srli	s1,s1,0xc
    80001228:	04aa                	slli	s1,s1,0xa
    8000122a:	0164e4b3          	or	s1,s1,s6
    8000122e:	0014e493          	ori	s1,s1,1
    80001232:	e104                	sd	s1,0(a0)
    if(a == last)
    80001234:	fd391be3          	bne	s2,s3,8000120a <mappages+0x42>
    pa += PGSIZE;
  }
  return 0;
    80001238:	4501                	li	a0,0
    8000123a:	a011                	j	8000123e <mappages+0x76>
      return -1;
    8000123c:	557d                	li	a0,-1
}
    8000123e:	60a6                	ld	ra,72(sp)
    80001240:	6406                	ld	s0,64(sp)
    80001242:	74e2                	ld	s1,56(sp)
    80001244:	7942                	ld	s2,48(sp)
    80001246:	79a2                	ld	s3,40(sp)
    80001248:	7a02                	ld	s4,32(sp)
    8000124a:	6ae2                	ld	s5,24(sp)
    8000124c:	6b42                	ld	s6,16(sp)
    8000124e:	6ba2                	ld	s7,8(sp)
    80001250:	6161                	addi	sp,sp,80
    80001252:	8082                	ret

0000000080001254 <kvmmap>:
{
    80001254:	1141                	addi	sp,sp,-16
    80001256:	e406                	sd	ra,8(sp)
    80001258:	e022                	sd	s0,0(sp)
    8000125a:	0800                	addi	s0,sp,16
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000125c:	8736                	mv	a4,a3
    8000125e:	86ae                	mv	a3,a1
    80001260:	85aa                	mv	a1,a0
    80001262:	00008797          	auipc	a5,0x8
    80001266:	dae78793          	addi	a5,a5,-594 # 80009010 <kernel_pagetable>
    8000126a:	6388                	ld	a0,0(a5)
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f5c080e7          	jalr	-164(ra) # 800011c8 <mappages>
    80001274:	e509                	bnez	a0,8000127e <kvmmap+0x2a>
}
    80001276:	60a2                	ld	ra,8(sp)
    80001278:	6402                	ld	s0,0(sp)
    8000127a:	0141                	addi	sp,sp,16
    8000127c:	8082                	ret
    panic("kvmmap");
    8000127e:	00007517          	auipc	a0,0x7
    80001282:	e8a50513          	addi	a0,a0,-374 # 80008108 <indent.1777+0x38>
    80001286:	fffff097          	auipc	ra,0xfffff
    8000128a:	2ee080e7          	jalr	750(ra) # 80000574 <panic>

000000008000128e <kvminit>:
{
    8000128e:	1101                	addi	sp,sp,-32
    80001290:	ec06                	sd	ra,24(sp)
    80001292:	e822                	sd	s0,16(sp)
    80001294:	e426                	sd	s1,8(sp)
    80001296:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	8da080e7          	jalr	-1830(ra) # 80000b72 <kalloc>
    800012a0:	00008797          	auipc	a5,0x8
    800012a4:	d6a7b823          	sd	a0,-656(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800012a8:	6605                	lui	a2,0x1
    800012aa:	4581                	li	a1,0
    800012ac:	00000097          	auipc	ra,0x0
    800012b0:	ab2080e7          	jalr	-1358(ra) # 80000d5e <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012b4:	4699                	li	a3,6
    800012b6:	6605                	lui	a2,0x1
    800012b8:	100005b7          	lui	a1,0x10000
    800012bc:	10000537          	lui	a0,0x10000
    800012c0:	00000097          	auipc	ra,0x0
    800012c4:	f94080e7          	jalr	-108(ra) # 80001254 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012c8:	4699                	li	a3,6
    800012ca:	6605                	lui	a2,0x1
    800012cc:	100015b7          	lui	a1,0x10001
    800012d0:	10001537          	lui	a0,0x10001
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	f80080e7          	jalr	-128(ra) # 80001254 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012dc:	4699                	li	a3,6
    800012de:	6641                	lui	a2,0x10
    800012e0:	020005b7          	lui	a1,0x2000
    800012e4:	02000537          	lui	a0,0x2000
    800012e8:	00000097          	auipc	ra,0x0
    800012ec:	f6c080e7          	jalr	-148(ra) # 80001254 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012f0:	4699                	li	a3,6
    800012f2:	00400637          	lui	a2,0x400
    800012f6:	0c0005b7          	lui	a1,0xc000
    800012fa:	0c000537          	lui	a0,0xc000
    800012fe:	00000097          	auipc	ra,0x0
    80001302:	f56080e7          	jalr	-170(ra) # 80001254 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001306:	00007497          	auipc	s1,0x7
    8000130a:	cfa48493          	addi	s1,s1,-774 # 80008000 <etext>
    8000130e:	46a9                	li	a3,10
    80001310:	80007617          	auipc	a2,0x80007
    80001314:	cf060613          	addi	a2,a2,-784 # 8000 <_entry-0x7fff8000>
    80001318:	4585                	li	a1,1
    8000131a:	05fe                	slli	a1,a1,0x1f
    8000131c:	852e                	mv	a0,a1
    8000131e:	00000097          	auipc	ra,0x0
    80001322:	f36080e7          	jalr	-202(ra) # 80001254 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001326:	4699                	li	a3,6
    80001328:	4645                	li	a2,17
    8000132a:	066e                	slli	a2,a2,0x1b
    8000132c:	8e05                	sub	a2,a2,s1
    8000132e:	85a6                	mv	a1,s1
    80001330:	8526                	mv	a0,s1
    80001332:	00000097          	auipc	ra,0x0
    80001336:	f22080e7          	jalr	-222(ra) # 80001254 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000133a:	46a9                	li	a3,10
    8000133c:	6605                	lui	a2,0x1
    8000133e:	00006597          	auipc	a1,0x6
    80001342:	cc258593          	addi	a1,a1,-830 # 80007000 <_trampoline>
    80001346:	04000537          	lui	a0,0x4000
    8000134a:	157d                	addi	a0,a0,-1
    8000134c:	0532                	slli	a0,a0,0xc
    8000134e:	00000097          	auipc	ra,0x0
    80001352:	f06080e7          	jalr	-250(ra) # 80001254 <kvmmap>
}
    80001356:	60e2                	ld	ra,24(sp)
    80001358:	6442                	ld	s0,16(sp)
    8000135a:	64a2                	ld	s1,8(sp)
    8000135c:	6105                	addi	sp,sp,32
    8000135e:	8082                	ret

0000000080001360 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001360:	715d                	addi	sp,sp,-80
    80001362:	e486                	sd	ra,72(sp)
    80001364:	e0a2                	sd	s0,64(sp)
    80001366:	fc26                	sd	s1,56(sp)
    80001368:	f84a                	sd	s2,48(sp)
    8000136a:	f44e                	sd	s3,40(sp)
    8000136c:	f052                	sd	s4,32(sp)
    8000136e:	ec56                	sd	s5,24(sp)
    80001370:	e85a                	sd	s6,16(sp)
    80001372:	e45e                	sd	s7,8(sp)
    80001374:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001376:	6785                	lui	a5,0x1
    80001378:	17fd                	addi	a5,a5,-1
    8000137a:	8fed                	and	a5,a5,a1
    8000137c:	e795                	bnez	a5,800013a8 <uvmunmap+0x48>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	84ae                	mv	s1,a1
    80001382:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001384:	0632                	slli	a2,a2,0xc
    80001386:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000138a:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000138c:	6b05                	lui	s6,0x1
    8000138e:	0735e863          	bltu	a1,s3,800013fe <uvmunmap+0x9e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001392:	60a6                	ld	ra,72(sp)
    80001394:	6406                	ld	s0,64(sp)
    80001396:	74e2                	ld	s1,56(sp)
    80001398:	7942                	ld	s2,48(sp)
    8000139a:	79a2                	ld	s3,40(sp)
    8000139c:	7a02                	ld	s4,32(sp)
    8000139e:	6ae2                	ld	s5,24(sp)
    800013a0:	6b42                	ld	s6,16(sp)
    800013a2:	6ba2                	ld	s7,8(sp)
    800013a4:	6161                	addi	sp,sp,80
    800013a6:	8082                	ret
    panic("uvmunmap: not aligned");
    800013a8:	00007517          	auipc	a0,0x7
    800013ac:	d6850513          	addi	a0,a0,-664 # 80008110 <indent.1777+0x40>
    800013b0:	fffff097          	auipc	ra,0xfffff
    800013b4:	1c4080e7          	jalr	452(ra) # 80000574 <panic>
      panic("uvmunmap: walk");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	d7050513          	addi	a0,a0,-656 # 80008128 <indent.1777+0x58>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	1b4080e7          	jalr	436(ra) # 80000574 <panic>
      panic("uvmunmap: not mapped");
    800013c8:	00007517          	auipc	a0,0x7
    800013cc:	d7050513          	addi	a0,a0,-656 # 80008138 <indent.1777+0x68>
    800013d0:	fffff097          	auipc	ra,0xfffff
    800013d4:	1a4080e7          	jalr	420(ra) # 80000574 <panic>
      panic("uvmunmap: not a leaf");
    800013d8:	00007517          	auipc	a0,0x7
    800013dc:	d7850513          	addi	a0,a0,-648 # 80008150 <indent.1777+0x80>
    800013e0:	fffff097          	auipc	ra,0xfffff
    800013e4:	194080e7          	jalr	404(ra) # 80000574 <panic>
      uint64 pa = PTE2PA(*pte);
    800013e8:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013ea:	0532                	slli	a0,a0,0xc
    800013ec:	fffff097          	auipc	ra,0xfffff
    800013f0:	686080e7          	jalr	1670(ra) # 80000a72 <kfree>
    *pte = 0;
    800013f4:	00093023          	sd	zero,0(s2)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013f8:	94da                	add	s1,s1,s6
    800013fa:	f934fce3          	bleu	s3,s1,80001392 <uvmunmap+0x32>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013fe:	4601                	li	a2,0
    80001400:	85a6                	mv	a1,s1
    80001402:	8552                	mv	a0,s4
    80001404:	00000097          	auipc	ra,0x0
    80001408:	c72080e7          	jalr	-910(ra) # 80001076 <walk>
    8000140c:	892a                	mv	s2,a0
    8000140e:	d54d                	beqz	a0,800013b8 <uvmunmap+0x58>
    if((*pte & PTE_V) == 0)
    80001410:	6108                	ld	a0,0(a0)
    80001412:	00157793          	andi	a5,a0,1
    80001416:	dbcd                	beqz	a5,800013c8 <uvmunmap+0x68>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001418:	3ff57793          	andi	a5,a0,1023
    8000141c:	fb778ee3          	beq	a5,s7,800013d8 <uvmunmap+0x78>
    if(do_free){
    80001420:	fc0a8ae3          	beqz	s5,800013f4 <uvmunmap+0x94>
    80001424:	b7d1                	j	800013e8 <uvmunmap+0x88>

0000000080001426 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001426:	1101                	addi	sp,sp,-32
    80001428:	ec06                	sd	ra,24(sp)
    8000142a:	e822                	sd	s0,16(sp)
    8000142c:	e426                	sd	s1,8(sp)
    8000142e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001430:	fffff097          	auipc	ra,0xfffff
    80001434:	742080e7          	jalr	1858(ra) # 80000b72 <kalloc>
    80001438:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000143a:	c519                	beqz	a0,80001448 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000143c:	6605                	lui	a2,0x1
    8000143e:	4581                	li	a1,0
    80001440:	00000097          	auipc	ra,0x0
    80001444:	91e080e7          	jalr	-1762(ra) # 80000d5e <memset>
  return pagetable;
}
    80001448:	8526                	mv	a0,s1
    8000144a:	60e2                	ld	ra,24(sp)
    8000144c:	6442                	ld	s0,16(sp)
    8000144e:	64a2                	ld	s1,8(sp)
    80001450:	6105                	addi	sp,sp,32
    80001452:	8082                	ret

0000000080001454 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001454:	7179                	addi	sp,sp,-48
    80001456:	f406                	sd	ra,40(sp)
    80001458:	f022                	sd	s0,32(sp)
    8000145a:	ec26                	sd	s1,24(sp)
    8000145c:	e84a                	sd	s2,16(sp)
    8000145e:	e44e                	sd	s3,8(sp)
    80001460:	e052                	sd	s4,0(sp)
    80001462:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001464:	6785                	lui	a5,0x1
    80001466:	04f67863          	bleu	a5,a2,800014b6 <uvminit+0x62>
    8000146a:	8a2a                	mv	s4,a0
    8000146c:	89ae                	mv	s3,a1
    8000146e:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001470:	fffff097          	auipc	ra,0xfffff
    80001474:	702080e7          	jalr	1794(ra) # 80000b72 <kalloc>
    80001478:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000147a:	6605                	lui	a2,0x1
    8000147c:	4581                	li	a1,0
    8000147e:	00000097          	auipc	ra,0x0
    80001482:	8e0080e7          	jalr	-1824(ra) # 80000d5e <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001486:	4779                	li	a4,30
    80001488:	86ca                	mv	a3,s2
    8000148a:	6605                	lui	a2,0x1
    8000148c:	4581                	li	a1,0
    8000148e:	8552                	mv	a0,s4
    80001490:	00000097          	auipc	ra,0x0
    80001494:	d38080e7          	jalr	-712(ra) # 800011c8 <mappages>
  memmove(mem, src, sz);
    80001498:	8626                	mv	a2,s1
    8000149a:	85ce                	mv	a1,s3
    8000149c:	854a                	mv	a0,s2
    8000149e:	00000097          	auipc	ra,0x0
    800014a2:	92c080e7          	jalr	-1748(ra) # 80000dca <memmove>
}
    800014a6:	70a2                	ld	ra,40(sp)
    800014a8:	7402                	ld	s0,32(sp)
    800014aa:	64e2                	ld	s1,24(sp)
    800014ac:	6942                	ld	s2,16(sp)
    800014ae:	69a2                	ld	s3,8(sp)
    800014b0:	6a02                	ld	s4,0(sp)
    800014b2:	6145                	addi	sp,sp,48
    800014b4:	8082                	ret
    panic("inituvm: more than a page");
    800014b6:	00007517          	auipc	a0,0x7
    800014ba:	cb250513          	addi	a0,a0,-846 # 80008168 <indent.1777+0x98>
    800014be:	fffff097          	auipc	ra,0xfffff
    800014c2:	0b6080e7          	jalr	182(ra) # 80000574 <panic>

00000000800014c6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014c6:	1101                	addi	sp,sp,-32
    800014c8:	ec06                	sd	ra,24(sp)
    800014ca:	e822                	sd	s0,16(sp)
    800014cc:	e426                	sd	s1,8(sp)
    800014ce:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014d0:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014d2:	00b67d63          	bleu	a1,a2,800014ec <uvmdealloc+0x26>
    800014d6:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014d8:	6605                	lui	a2,0x1
    800014da:	167d                	addi	a2,a2,-1
    800014dc:	00c487b3          	add	a5,s1,a2
    800014e0:	777d                	lui	a4,0xfffff
    800014e2:	8ff9                	and	a5,a5,a4
    800014e4:	962e                	add	a2,a2,a1
    800014e6:	8e79                	and	a2,a2,a4
    800014e8:	00c7e863          	bltu	a5,a2,800014f8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014ec:	8526                	mv	a0,s1
    800014ee:	60e2                	ld	ra,24(sp)
    800014f0:	6442                	ld	s0,16(sp)
    800014f2:	64a2                	ld	s1,8(sp)
    800014f4:	6105                	addi	sp,sp,32
    800014f6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014f8:	8e1d                	sub	a2,a2,a5
    800014fa:	8231                	srli	a2,a2,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014fc:	4685                	li	a3,1
    800014fe:	2601                	sext.w	a2,a2
    80001500:	85be                	mv	a1,a5
    80001502:	00000097          	auipc	ra,0x0
    80001506:	e5e080e7          	jalr	-418(ra) # 80001360 <uvmunmap>
    8000150a:	b7cd                	j	800014ec <uvmdealloc+0x26>

000000008000150c <uvmalloc>:
  if(newsz < oldsz)
    8000150c:	0ab66163          	bltu	a2,a1,800015ae <uvmalloc+0xa2>
{
    80001510:	7139                	addi	sp,sp,-64
    80001512:	fc06                	sd	ra,56(sp)
    80001514:	f822                	sd	s0,48(sp)
    80001516:	f426                	sd	s1,40(sp)
    80001518:	f04a                	sd	s2,32(sp)
    8000151a:	ec4e                	sd	s3,24(sp)
    8000151c:	e852                	sd	s4,16(sp)
    8000151e:	e456                	sd	s5,8(sp)
    80001520:	0080                	addi	s0,sp,64
  oldsz = PGROUNDUP(oldsz);
    80001522:	6a05                	lui	s4,0x1
    80001524:	1a7d                	addi	s4,s4,-1
    80001526:	95d2                	add	a1,a1,s4
    80001528:	7a7d                	lui	s4,0xfffff
    8000152a:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000152e:	08ca7263          	bleu	a2,s4,800015b2 <uvmalloc+0xa6>
    80001532:	89b2                	mv	s3,a2
    80001534:	8aaa                	mv	s5,a0
    80001536:	8952                	mv	s2,s4
    mem = kalloc();
    80001538:	fffff097          	auipc	ra,0xfffff
    8000153c:	63a080e7          	jalr	1594(ra) # 80000b72 <kalloc>
    80001540:	84aa                	mv	s1,a0
    if(mem == 0){
    80001542:	c51d                	beqz	a0,80001570 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001544:	6605                	lui	a2,0x1
    80001546:	4581                	li	a1,0
    80001548:	00000097          	auipc	ra,0x0
    8000154c:	816080e7          	jalr	-2026(ra) # 80000d5e <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001550:	4779                	li	a4,30
    80001552:	86a6                	mv	a3,s1
    80001554:	6605                	lui	a2,0x1
    80001556:	85ca                	mv	a1,s2
    80001558:	8556                	mv	a0,s5
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	c6e080e7          	jalr	-914(ra) # 800011c8 <mappages>
    80001562:	e905                	bnez	a0,80001592 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001564:	6785                	lui	a5,0x1
    80001566:	993e                	add	s2,s2,a5
    80001568:	fd3968e3          	bltu	s2,s3,80001538 <uvmalloc+0x2c>
  return newsz;
    8000156c:	854e                	mv	a0,s3
    8000156e:	a809                	j	80001580 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001570:	8652                	mv	a2,s4
    80001572:	85ca                	mv	a1,s2
    80001574:	8556                	mv	a0,s5
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	f50080e7          	jalr	-176(ra) # 800014c6 <uvmdealloc>
      return 0;
    8000157e:	4501                	li	a0,0
}
    80001580:	70e2                	ld	ra,56(sp)
    80001582:	7442                	ld	s0,48(sp)
    80001584:	74a2                	ld	s1,40(sp)
    80001586:	7902                	ld	s2,32(sp)
    80001588:	69e2                	ld	s3,24(sp)
    8000158a:	6a42                	ld	s4,16(sp)
    8000158c:	6aa2                	ld	s5,8(sp)
    8000158e:	6121                	addi	sp,sp,64
    80001590:	8082                	ret
      kfree(mem);
    80001592:	8526                	mv	a0,s1
    80001594:	fffff097          	auipc	ra,0xfffff
    80001598:	4de080e7          	jalr	1246(ra) # 80000a72 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000159c:	8652                	mv	a2,s4
    8000159e:	85ca                	mv	a1,s2
    800015a0:	8556                	mv	a0,s5
    800015a2:	00000097          	auipc	ra,0x0
    800015a6:	f24080e7          	jalr	-220(ra) # 800014c6 <uvmdealloc>
      return 0;
    800015aa:	4501                	li	a0,0
    800015ac:	bfd1                	j	80001580 <uvmalloc+0x74>
    return oldsz;
    800015ae:	852e                	mv	a0,a1
}
    800015b0:	8082                	ret
  return newsz;
    800015b2:	8532                	mv	a0,a2
    800015b4:	b7f1                	j	80001580 <uvmalloc+0x74>

00000000800015b6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015b6:	7179                	addi	sp,sp,-48
    800015b8:	f406                	sd	ra,40(sp)
    800015ba:	f022                	sd	s0,32(sp)
    800015bc:	ec26                	sd	s1,24(sp)
    800015be:	e84a                	sd	s2,16(sp)
    800015c0:	e44e                	sd	s3,8(sp)
    800015c2:	e052                	sd	s4,0(sp)
    800015c4:	1800                	addi	s0,sp,48
    800015c6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015c8:	84aa                	mv	s1,a0
    800015ca:	6905                	lui	s2,0x1
    800015cc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ce:	4985                	li	s3,1
    800015d0:	a821                	j	800015e8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015d2:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015d4:	0532                	slli	a0,a0,0xc
    800015d6:	00000097          	auipc	ra,0x0
    800015da:	fe0080e7          	jalr	-32(ra) # 800015b6 <freewalk>
      pagetable[i] = 0;
    800015de:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015e2:	04a1                	addi	s1,s1,8
    800015e4:	03248163          	beq	s1,s2,80001606 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015e8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015ea:	00f57793          	andi	a5,a0,15
    800015ee:	ff3782e3          	beq	a5,s3,800015d2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015f2:	8905                	andi	a0,a0,1
    800015f4:	d57d                	beqz	a0,800015e2 <freewalk+0x2c>
      panic("freewalk: leaf");
    800015f6:	00007517          	auipc	a0,0x7
    800015fa:	b9250513          	addi	a0,a0,-1134 # 80008188 <indent.1777+0xb8>
    800015fe:	fffff097          	auipc	ra,0xfffff
    80001602:	f76080e7          	jalr	-138(ra) # 80000574 <panic>
    }
  }
  kfree((void*)pagetable);
    80001606:	8552                	mv	a0,s4
    80001608:	fffff097          	auipc	ra,0xfffff
    8000160c:	46a080e7          	jalr	1130(ra) # 80000a72 <kfree>
}
    80001610:	70a2                	ld	ra,40(sp)
    80001612:	7402                	ld	s0,32(sp)
    80001614:	64e2                	ld	s1,24(sp)
    80001616:	6942                	ld	s2,16(sp)
    80001618:	69a2                	ld	s3,8(sp)
    8000161a:	6a02                	ld	s4,0(sp)
    8000161c:	6145                	addi	sp,sp,48
    8000161e:	8082                	ret

0000000080001620 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001620:	1101                	addi	sp,sp,-32
    80001622:	ec06                	sd	ra,24(sp)
    80001624:	e822                	sd	s0,16(sp)
    80001626:	e426                	sd	s1,8(sp)
    80001628:	1000                	addi	s0,sp,32
    8000162a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000162c:	e999                	bnez	a1,80001642 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000162e:	8526                	mv	a0,s1
    80001630:	00000097          	auipc	ra,0x0
    80001634:	f86080e7          	jalr	-122(ra) # 800015b6 <freewalk>
}
    80001638:	60e2                	ld	ra,24(sp)
    8000163a:	6442                	ld	s0,16(sp)
    8000163c:	64a2                	ld	s1,8(sp)
    8000163e:	6105                	addi	sp,sp,32
    80001640:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001642:	6605                	lui	a2,0x1
    80001644:	167d                	addi	a2,a2,-1
    80001646:	962e                	add	a2,a2,a1
    80001648:	4685                	li	a3,1
    8000164a:	8231                	srli	a2,a2,0xc
    8000164c:	4581                	li	a1,0
    8000164e:	00000097          	auipc	ra,0x0
    80001652:	d12080e7          	jalr	-750(ra) # 80001360 <uvmunmap>
    80001656:	bfe1                	j	8000162e <uvmfree+0xe>

0000000080001658 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001658:	c679                	beqz	a2,80001726 <uvmcopy+0xce>
{
    8000165a:	715d                	addi	sp,sp,-80
    8000165c:	e486                	sd	ra,72(sp)
    8000165e:	e0a2                	sd	s0,64(sp)
    80001660:	fc26                	sd	s1,56(sp)
    80001662:	f84a                	sd	s2,48(sp)
    80001664:	f44e                	sd	s3,40(sp)
    80001666:	f052                	sd	s4,32(sp)
    80001668:	ec56                	sd	s5,24(sp)
    8000166a:	e85a                	sd	s6,16(sp)
    8000166c:	e45e                	sd	s7,8(sp)
    8000166e:	0880                	addi	s0,sp,80
    80001670:	8ab2                	mv	s5,a2
    80001672:	8b2e                	mv	s6,a1
    80001674:	8baa                	mv	s7,a0
  for(i = 0; i < sz; i += PGSIZE){
    80001676:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    80001678:	4601                	li	a2,0
    8000167a:	85ca                	mv	a1,s2
    8000167c:	855e                	mv	a0,s7
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	9f8080e7          	jalr	-1544(ra) # 80001076 <walk>
    80001686:	c531                	beqz	a0,800016d2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001688:	6118                	ld	a4,0(a0)
    8000168a:	00177793          	andi	a5,a4,1
    8000168e:	cbb1                	beqz	a5,800016e2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001690:	00a75593          	srli	a1,a4,0xa
    80001694:	00c59993          	slli	s3,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001698:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	4d6080e7          	jalr	1238(ra) # 80000b72 <kalloc>
    800016a4:	8a2a                	mv	s4,a0
    800016a6:	c939                	beqz	a0,800016fc <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800016a8:	6605                	lui	a2,0x1
    800016aa:	85ce                	mv	a1,s3
    800016ac:	fffff097          	auipc	ra,0xfffff
    800016b0:	71e080e7          	jalr	1822(ra) # 80000dca <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016b4:	8726                	mv	a4,s1
    800016b6:	86d2                	mv	a3,s4
    800016b8:	6605                	lui	a2,0x1
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	b0a080e7          	jalr	-1270(ra) # 800011c8 <mappages>
    800016c6:	e515                	bnez	a0,800016f2 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016c8:	6785                	lui	a5,0x1
    800016ca:	993e                	add	s2,s2,a5
    800016cc:	fb5966e3          	bltu	s2,s5,80001678 <uvmcopy+0x20>
    800016d0:	a081                	j	80001710 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016d2:	00007517          	auipc	a0,0x7
    800016d6:	ac650513          	addi	a0,a0,-1338 # 80008198 <indent.1777+0xc8>
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	e9a080e7          	jalr	-358(ra) # 80000574 <panic>
      panic("uvmcopy: page not present");
    800016e2:	00007517          	auipc	a0,0x7
    800016e6:	ad650513          	addi	a0,a0,-1322 # 800081b8 <indent.1777+0xe8>
    800016ea:	fffff097          	auipc	ra,0xfffff
    800016ee:	e8a080e7          	jalr	-374(ra) # 80000574 <panic>
      kfree(mem);
    800016f2:	8552                	mv	a0,s4
    800016f4:	fffff097          	auipc	ra,0xfffff
    800016f8:	37e080e7          	jalr	894(ra) # 80000a72 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016fc:	4685                	li	a3,1
    800016fe:	00c95613          	srli	a2,s2,0xc
    80001702:	4581                	li	a1,0
    80001704:	855a                	mv	a0,s6
    80001706:	00000097          	auipc	ra,0x0
    8000170a:	c5a080e7          	jalr	-934(ra) # 80001360 <uvmunmap>
  return -1;
    8000170e:	557d                	li	a0,-1
}
    80001710:	60a6                	ld	ra,72(sp)
    80001712:	6406                	ld	s0,64(sp)
    80001714:	74e2                	ld	s1,56(sp)
    80001716:	7942                	ld	s2,48(sp)
    80001718:	79a2                	ld	s3,40(sp)
    8000171a:	7a02                	ld	s4,32(sp)
    8000171c:	6ae2                	ld	s5,24(sp)
    8000171e:	6b42                	ld	s6,16(sp)
    80001720:	6ba2                	ld	s7,8(sp)
    80001722:	6161                	addi	sp,sp,80
    80001724:	8082                	ret
  return 0;
    80001726:	4501                	li	a0,0
}
    80001728:	8082                	ret

000000008000172a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000172a:	1141                	addi	sp,sp,-16
    8000172c:	e406                	sd	ra,8(sp)
    8000172e:	e022                	sd	s0,0(sp)
    80001730:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001732:	4601                	li	a2,0
    80001734:	00000097          	auipc	ra,0x0
    80001738:	942080e7          	jalr	-1726(ra) # 80001076 <walk>
  if(pte == 0)
    8000173c:	c901                	beqz	a0,8000174c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000173e:	611c                	ld	a5,0(a0)
    80001740:	9bbd                	andi	a5,a5,-17
    80001742:	e11c                	sd	a5,0(a0)
}
    80001744:	60a2                	ld	ra,8(sp)
    80001746:	6402                	ld	s0,0(sp)
    80001748:	0141                	addi	sp,sp,16
    8000174a:	8082                	ret
    panic("uvmclear");
    8000174c:	00007517          	auipc	a0,0x7
    80001750:	a8c50513          	addi	a0,a0,-1396 # 800081d8 <indent.1777+0x108>
    80001754:	fffff097          	auipc	ra,0xfffff
    80001758:	e20080e7          	jalr	-480(ra) # 80000574 <panic>

000000008000175c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000175c:	c6bd                	beqz	a3,800017ca <copyout+0x6e>
{
    8000175e:	715d                	addi	sp,sp,-80
    80001760:	e486                	sd	ra,72(sp)
    80001762:	e0a2                	sd	s0,64(sp)
    80001764:	fc26                	sd	s1,56(sp)
    80001766:	f84a                	sd	s2,48(sp)
    80001768:	f44e                	sd	s3,40(sp)
    8000176a:	f052                	sd	s4,32(sp)
    8000176c:	ec56                	sd	s5,24(sp)
    8000176e:	e85a                	sd	s6,16(sp)
    80001770:	e45e                	sd	s7,8(sp)
    80001772:	e062                	sd	s8,0(sp)
    80001774:	0880                	addi	s0,sp,80
    80001776:	8baa                	mv	s7,a0
    80001778:	8a2e                	mv	s4,a1
    8000177a:	8ab2                	mv	s5,a2
    8000177c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000177e:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001780:	6b05                	lui	s6,0x1
    80001782:	a015                	j	800017a6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001784:	9552                	add	a0,a0,s4
    80001786:	0004861b          	sext.w	a2,s1
    8000178a:	85d6                	mv	a1,s5
    8000178c:	41250533          	sub	a0,a0,s2
    80001790:	fffff097          	auipc	ra,0xfffff
    80001794:	63a080e7          	jalr	1594(ra) # 80000dca <memmove>

    len -= n;
    80001798:	409989b3          	sub	s3,s3,s1
    src += n;
    8000179c:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    8000179e:	01690a33          	add	s4,s2,s6
  while(len > 0){
    800017a2:	02098263          	beqz	s3,800017c6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800017a6:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    800017aa:	85ca                	mv	a1,s2
    800017ac:	855e                	mv	a0,s7
    800017ae:	00000097          	auipc	ra,0x0
    800017b2:	96e080e7          	jalr	-1682(ra) # 8000111c <walkaddr>
    if(pa0 == 0)
    800017b6:	cd01                	beqz	a0,800017ce <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017b8:	414904b3          	sub	s1,s2,s4
    800017bc:	94da                	add	s1,s1,s6
    if(n > len)
    800017be:	fc99f3e3          	bleu	s1,s3,80001784 <copyout+0x28>
    800017c2:	84ce                	mv	s1,s3
    800017c4:	b7c1                	j	80001784 <copyout+0x28>
  }
  return 0;
    800017c6:	4501                	li	a0,0
    800017c8:	a021                	j	800017d0 <copyout+0x74>
    800017ca:	4501                	li	a0,0
}
    800017cc:	8082                	ret
      return -1;
    800017ce:	557d                	li	a0,-1
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6c02                	ld	s8,0(sp)
    800017e4:	6161                	addi	sp,sp,80
    800017e6:	8082                	ret

00000000800017e8 <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800017e8:	1141                	addi	sp,sp,-16
    800017ea:	e406                	sd	ra,8(sp)
    800017ec:	e022                	sd	s0,0(sp)
    800017ee:	0800                	addi	s0,sp,16
    return copyin_new(pagetable, dst, srcva, len);
    800017f0:	00005097          	auipc	ra,0x5
    800017f4:	eb6080e7          	jalr	-330(ra) # 800066a6 <copyin_new>
}
    800017f8:	60a2                	ld	ra,8(sp)
    800017fa:	6402                	ld	s0,0(sp)
    800017fc:	0141                	addi	sp,sp,16
    800017fe:	8082                	ret

0000000080001800 <copyinstr>:
// until a '\0', or max.
// Return 0 on success, -1 on error.

int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80001800:	1141                	addi	sp,sp,-16
    80001802:	e406                	sd	ra,8(sp)
    80001804:	e022                	sd	s0,0(sp)
    80001806:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable, dst, srcva, max);
    80001808:	00005097          	auipc	ra,0x5
    8000180c:	f06080e7          	jalr	-250(ra) # 8000670e <copyinstr_new>
}
    80001810:	60a2                	ld	ra,8(sp)
    80001812:	6402                	ld	s0,0(sp)
    80001814:	0141                	addi	sp,sp,16
    80001816:	8082                	ret

0000000080001818 <vmprint_helper>:


// Recursive helper
void vmprint_helper(pagetable_t pagetable, int depth) {
    80001818:	715d                	addi	sp,sp,-80
    8000181a:	e486                	sd	ra,72(sp)
    8000181c:	e0a2                	sd	s0,64(sp)
    8000181e:	fc26                	sd	s1,56(sp)
    80001820:	f84a                	sd	s2,48(sp)
    80001822:	f44e                	sd	s3,40(sp)
    80001824:	f052                	sd	s4,32(sp)
    80001826:	ec56                	sd	s5,24(sp)
    80001828:	e85a                	sd	s6,16(sp)
    8000182a:	e45e                	sd	s7,8(sp)
    8000182c:	e062                	sd	s8,0(sp)
    8000182e:	0880                	addi	s0,sp,80
      "",
      "..",
      ".. ..",
      ".. .. .."
  };
  if (depth <= 0 || depth >= 4) {
    80001830:	fff5871b          	addiw	a4,a1,-1
    80001834:	4789                	li	a5,2
    80001836:	02e7e463          	bltu	a5,a4,8000185e <vmprint_helper+0x46>
    8000183a:	89aa                	mv	s3,a0
    8000183c:	4901                	li	s2,0
  }
  // there are 2^9 = 512 PTES in a page table.
  for (int i = 0; i < 512; i++) {
    pte_t pte = pagetable[i];
    if (pte & PTE_V) { //是一个有效的PTE
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    8000183e:	00359793          	slli	a5,a1,0x3
    80001842:	00007b17          	auipc	s6,0x7
    80001846:	88eb0b13          	addi	s6,s6,-1906 # 800080d0 <indent.1777>
    8000184a:	9b3e                	add	s6,s6,a5
    8000184c:	00007b97          	auipc	s7,0x7
    80001850:	9c4b8b93          	addi	s7,s7,-1596 # 80008210 <indent.1777+0x140>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
        // points to a lower-level page table 并且是间接层PTE
        uint64 child = PTE2PA(pte);
        vmprint_helper((pagetable_t)child, depth+1); // 递归, 深度+1
    80001854:	00158c1b          	addiw	s8,a1,1
  for (int i = 0; i < 512; i++) {
    80001858:	20000a93          	li	s5,512
    8000185c:	a01d                	j	80001882 <vmprint_helper+0x6a>
    panic("vmprint_helper: depth not in {1, 2, 3}");
    8000185e:	00007517          	auipc	a0,0x7
    80001862:	98a50513          	addi	a0,a0,-1654 # 800081e8 <indent.1777+0x118>
    80001866:	fffff097          	auipc	ra,0xfffff
    8000186a:	d0e080e7          	jalr	-754(ra) # 80000574 <panic>
        vmprint_helper((pagetable_t)child, depth+1); // 递归, 深度+1
    8000186e:	85e2                	mv	a1,s8
    80001870:	8552                	mv	a0,s4
    80001872:	00000097          	auipc	ra,0x0
    80001876:	fa6080e7          	jalr	-90(ra) # 80001818 <vmprint_helper>
  for (int i = 0; i < 512; i++) {
    8000187a:	2905                	addiw	s2,s2,1
    8000187c:	09a1                	addi	s3,s3,8
    8000187e:	03590763          	beq	s2,s5,800018ac <vmprint_helper+0x94>
    pte_t pte = pagetable[i];
    80001882:	0009b483          	ld	s1,0(s3) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    if (pte & PTE_V) { //是一个有效的PTE
    80001886:	0014f793          	andi	a5,s1,1
    8000188a:	dbe5                	beqz	a5,8000187a <vmprint_helper+0x62>
      printf("%s%d: pte %p pa %p\n", indent[depth], i, pte, PTE2PA(pte));
    8000188c:	00a4da13          	srli	s4,s1,0xa
    80001890:	0a32                	slli	s4,s4,0xc
    80001892:	8752                	mv	a4,s4
    80001894:	86a6                	mv	a3,s1
    80001896:	864a                	mv	a2,s2
    80001898:	000b3583          	ld	a1,0(s6)
    8000189c:	855e                	mv	a0,s7
    8000189e:	fffff097          	auipc	ra,0xfffff
    800018a2:	d20080e7          	jalr	-736(ra) # 800005be <printf>
      if ((pte & (PTE_R|PTE_W|PTE_X)) == 0) {
    800018a6:	88b9                	andi	s1,s1,14
    800018a8:	f8e9                	bnez	s1,8000187a <vmprint_helper+0x62>
    800018aa:	b7d1                	j	8000186e <vmprint_helper+0x56>
      }
    }
  }
}
    800018ac:	60a6                	ld	ra,72(sp)
    800018ae:	6406                	ld	s0,64(sp)
    800018b0:	74e2                	ld	s1,56(sp)
    800018b2:	7942                	ld	s2,48(sp)
    800018b4:	79a2                	ld	s3,40(sp)
    800018b6:	7a02                	ld	s4,32(sp)
    800018b8:	6ae2                	ld	s5,24(sp)
    800018ba:	6b42                	ld	s6,16(sp)
    800018bc:	6ba2                	ld	s7,8(sp)
    800018be:	6c02                	ld	s8,0(sp)
    800018c0:	6161                	addi	sp,sp,80
    800018c2:	8082                	ret

00000000800018c4 <vmprint>:

// Utility func to print the valid
// PTEs within a page table recursively
void vmprint(pagetable_t pagetable) {
    800018c4:	1101                	addi	sp,sp,-32
    800018c6:	ec06                	sd	ra,24(sp)
    800018c8:	e822                	sd	s0,16(sp)
    800018ca:	e426                	sd	s1,8(sp)
    800018cc:	1000                	addi	s0,sp,32
    800018ce:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    800018d0:	85aa                	mv	a1,a0
    800018d2:	00007517          	auipc	a0,0x7
    800018d6:	95650513          	addi	a0,a0,-1706 # 80008228 <indent.1777+0x158>
    800018da:	fffff097          	auipc	ra,0xfffff
    800018de:	ce4080e7          	jalr	-796(ra) # 800005be <printf>
  vmprint_helper(pagetable, 1);
    800018e2:	4585                	li	a1,1
    800018e4:	8526                	mv	a0,s1
    800018e6:	00000097          	auipc	ra,0x0
    800018ea:	f32080e7          	jalr	-206(ra) # 80001818 <vmprint_helper>
}
    800018ee:	60e2                	ld	ra,24(sp)
    800018f0:	6442                	ld	s0,16(sp)
    800018f2:	64a2                	ld	s1,8(sp)
    800018f4:	6105                	addi	sp,sp,32
    800018f6:	8082                	ret

00000000800018f8 <kvmbuild>:

pagetable_t
kvmbuild(void)
{
    800018f8:	1101                	addi	sp,sp,-32
    800018fa:	ec06                	sd	ra,24(sp)
    800018fc:	e822                	sd	s0,16(sp)
    800018fe:	e426                	sd	s1,8(sp)
    80001900:	e04a                	sd	s2,0(sp)
    80001902:	1000                	addi	s0,sp,32
    pagetable_t  pagetable = (pagetable_t) kalloc();
    80001904:	fffff097          	auipc	ra,0xfffff
    80001908:	26e080e7          	jalr	622(ra) # 80000b72 <kalloc>
    8000190c:	84aa                	mv	s1,a0
    memset(pagetable, 0, PGSIZE);
    8000190e:	6605                	lui	a2,0x1
    80001910:	4581                	li	a1,0
    80001912:	fffff097          	auipc	ra,0xfffff
    80001916:	44c080e7          	jalr	1100(ra) # 80000d5e <memset>

    // uart registers
    mappages(pagetable, UART0, PGSIZE, UART0, PTE_R | PTE_W);
    8000191a:	4719                	li	a4,6
    8000191c:	100006b7          	lui	a3,0x10000
    80001920:	6605                	lui	a2,0x1
    80001922:	100005b7          	lui	a1,0x10000
    80001926:	8526                	mv	a0,s1
    80001928:	00000097          	auipc	ra,0x0
    8000192c:	8a0080e7          	jalr	-1888(ra) # 800011c8 <mappages>

    // virtio mmio disk interface
    mappages(pagetable, VIRTIO0, PGSIZE, VIRTIO0, PTE_R | PTE_W);
    80001930:	4719                	li	a4,6
    80001932:	100016b7          	lui	a3,0x10001
    80001936:	6605                	lui	a2,0x1
    80001938:	100015b7          	lui	a1,0x10001
    8000193c:	8526                	mv	a0,s1
    8000193e:	00000097          	auipc	ra,0x0
    80001942:	88a080e7          	jalr	-1910(ra) # 800011c8 <mappages>

    // CLINT
   // mappages(pagetable, CLINT, 0x10000, CLINT, PTE_R | PTE_W);

    // PLIC
    mappages(pagetable, PLIC, 0x400000, PLIC, PTE_R | PTE_W);
    80001946:	4719                	li	a4,6
    80001948:	0c0006b7          	lui	a3,0xc000
    8000194c:	00400637          	lui	a2,0x400
    80001950:	0c0005b7          	lui	a1,0xc000
    80001954:	8526                	mv	a0,s1
    80001956:	00000097          	auipc	ra,0x0
    8000195a:	872080e7          	jalr	-1934(ra) # 800011c8 <mappages>

    // map kernel text executable and read-only.
    mappages(pagetable, KERNBASE, (uint64)etext-KERNBASE, KERNBASE, PTE_R | PTE_X);
    8000195e:	00006917          	auipc	s2,0x6
    80001962:	6a290913          	addi	s2,s2,1698 # 80008000 <etext>
    80001966:	4729                	li	a4,10
    80001968:	4685                	li	a3,1
    8000196a:	06fe                	slli	a3,a3,0x1f
    8000196c:	80006617          	auipc	a2,0x80006
    80001970:	69460613          	addi	a2,a2,1684 # 8000 <_entry-0x7fff8000>
    80001974:	85b6                	mv	a1,a3
    80001976:	8526                	mv	a0,s1
    80001978:	00000097          	auipc	ra,0x0
    8000197c:	850080e7          	jalr	-1968(ra) # 800011c8 <mappages>

    // map kernel data and the physical RAM we'll make use of.
    mappages(pagetable, (uint64)etext, PHYSTOP-(uint64)etext, (uint64)etext, PTE_R | PTE_W);
    80001980:	4719                	li	a4,6
    80001982:	86ca                	mv	a3,s2
    80001984:	4645                	li	a2,17
    80001986:	066e                	slli	a2,a2,0x1b
    80001988:	41260633          	sub	a2,a2,s2
    8000198c:	85ca                	mv	a1,s2
    8000198e:	8526                	mv	a0,s1
    80001990:	00000097          	auipc	ra,0x0
    80001994:	838080e7          	jalr	-1992(ra) # 800011c8 <mappages>

    // map the trampoline for trap entry/exit to
    // the highest virtual address in the kernel.
    mappages(pagetable, TRAMPOLINE, PGSIZE, (uint64)trampoline, PTE_R | PTE_X);
    80001998:	4729                	li	a4,10
    8000199a:	00005697          	auipc	a3,0x5
    8000199e:	66668693          	addi	a3,a3,1638 # 80007000 <_trampoline>
    800019a2:	6605                	lui	a2,0x1
    800019a4:	040005b7          	lui	a1,0x4000
    800019a8:	15fd                	addi	a1,a1,-1
    800019aa:	05b2                	slli	a1,a1,0xc
    800019ac:	8526                	mv	a0,s1
    800019ae:	00000097          	auipc	ra,0x0
    800019b2:	81a080e7          	jalr	-2022(ra) # 800011c8 <mappages>

    return pagetable;
}
    800019b6:	8526                	mv	a0,s1
    800019b8:	60e2                	ld	ra,24(sp)
    800019ba:	6442                	ld	s0,16(sp)
    800019bc:	64a2                	ld	s1,8(sp)
    800019be:	6902                	ld	s2,0(sp)
    800019c0:	6105                	addi	sp,sp,32
    800019c2:	8082                	ret

00000000800019c4 <uvm2kvm>:

void
uvm2kvm(pagetable_t pagetable, pagetable_t kpagetable, uint64 old_size, uint64 new_size)
{
    800019c4:	7139                	addi	sp,sp,-64
    800019c6:	fc06                	sd	ra,56(sp)
    800019c8:	f822                	sd	s0,48(sp)
    800019ca:	f426                	sd	s1,40(sp)
    800019cc:	f04a                	sd	s2,32(sp)
    800019ce:	ec4e                	sd	s3,24(sp)
    800019d0:	e852                	sd	s4,16(sp)
    800019d2:	e456                	sd	s5,8(sp)
    800019d4:	e05a                	sd	s6,0(sp)
    800019d6:	0080                	addi	s0,sp,64
    if (new_size < old_size)
    800019d8:	06c6e863          	bltu	a3,a2,80001a48 <uvm2kvm+0x84>
    800019dc:	8a2a                	mv	s4,a0
    800019de:	8aae                	mv	s5,a1
        panic("new size lower than old size");

    if (PGROUNDUP(new_size) >= PLIC)
    800019e0:	6985                	lui	s3,0x1
    800019e2:	19fd                	addi	s3,s3,-1
    800019e4:	96ce                	add	a3,a3,s3
    800019e6:	79fd                	lui	s3,0xfffff
    800019e8:	0136f9b3          	and	s3,a3,s3
    800019ec:	0c0007b7          	lui	a5,0xc000
    800019f0:	06f9f463          	bleu	a5,s3,80001a58 <uvm2kvm+0x94>
        panic("new size too big");

    uint64 begin = PGROUNDUP(old_size);
    800019f4:	6485                	lui	s1,0x1
    800019f6:	14fd                	addi	s1,s1,-1
    800019f8:	9626                	add	a2,a2,s1
    800019fa:	74fd                	lui	s1,0xfffff
    800019fc:	8cf1                	and	s1,s1,a2
    uint64 end = PGROUNDUP(new_size);
    // printf("begin: %x, end: %x\n", begin, end);
    for (uint64 va = begin; va < end; va += PGSIZE) {
    800019fe:	0334fb63          	bleu	s3,s1,80001a34 <uvm2kvm+0x70>
    80001a02:	6b05                	lui	s6,0x1
        pte_t* pte = walk(pagetable, va, 0);
    80001a04:	4601                	li	a2,0
    80001a06:	85a6                	mv	a1,s1
    80001a08:	8552                	mv	a0,s4
    80001a0a:	fffff097          	auipc	ra,0xfffff
    80001a0e:	66c080e7          	jalr	1644(ra) # 80001076 <walk>
    80001a12:	892a                	mv	s2,a0
        if (pte == 0)
    80001a14:	c931                	beqz	a0,80001a68 <uvm2kvm+0xa4>
            panic("user page table not found");
        pte_t* kpte = walk(kpagetable, va, 1);
    80001a16:	4605                	li	a2,1
    80001a18:	85a6                	mv	a1,s1
    80001a1a:	8556                	mv	a0,s5
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	65a080e7          	jalr	1626(ra) # 80001076 <walk>
        if (kpte == 0)
    80001a24:	c931                	beqz	a0,80001a78 <uvm2kvm+0xb4>
            panic("kernel page table not found");
        *kpte = (*pte) & (~PTE_U);
    80001a26:	00093783          	ld	a5,0(s2)
    80001a2a:	9bbd                	andi	a5,a5,-17
    80001a2c:	e11c                	sd	a5,0(a0)
    for (uint64 va = begin; va < end; va += PGSIZE) {
    80001a2e:	94da                	add	s1,s1,s6
    80001a30:	fd34eae3          	bltu	s1,s3,80001a04 <uvm2kvm+0x40>
    }
}
    80001a34:	70e2                	ld	ra,56(sp)
    80001a36:	7442                	ld	s0,48(sp)
    80001a38:	74a2                	ld	s1,40(sp)
    80001a3a:	7902                	ld	s2,32(sp)
    80001a3c:	69e2                	ld	s3,24(sp)
    80001a3e:	6a42                	ld	s4,16(sp)
    80001a40:	6aa2                	ld	s5,8(sp)
    80001a42:	6b02                	ld	s6,0(sp)
    80001a44:	6121                	addi	sp,sp,64
    80001a46:	8082                	ret
        panic("new size lower than old size");
    80001a48:	00006517          	auipc	a0,0x6
    80001a4c:	7f050513          	addi	a0,a0,2032 # 80008238 <indent.1777+0x168>
    80001a50:	fffff097          	auipc	ra,0xfffff
    80001a54:	b24080e7          	jalr	-1244(ra) # 80000574 <panic>
        panic("new size too big");
    80001a58:	00007517          	auipc	a0,0x7
    80001a5c:	80050513          	addi	a0,a0,-2048 # 80008258 <indent.1777+0x188>
    80001a60:	fffff097          	auipc	ra,0xfffff
    80001a64:	b14080e7          	jalr	-1260(ra) # 80000574 <panic>
            panic("user page table not found");
    80001a68:	00007517          	auipc	a0,0x7
    80001a6c:	80850513          	addi	a0,a0,-2040 # 80008270 <indent.1777+0x1a0>
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	b04080e7          	jalr	-1276(ra) # 80000574 <panic>
            panic("kernel page table not found");
    80001a78:	00007517          	auipc	a0,0x7
    80001a7c:	81850513          	addi	a0,a0,-2024 # 80008290 <indent.1777+0x1c0>
    80001a80:	fffff097          	auipc	ra,0xfffff
    80001a84:	af4080e7          	jalr	-1292(ra) # 80000574 <panic>

0000000080001a88 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a88:	1101                	addi	sp,sp,-32
    80001a8a:	ec06                	sd	ra,24(sp)
    80001a8c:	e822                	sd	s0,16(sp)
    80001a8e:	e426                	sd	s1,8(sp)
    80001a90:	1000                	addi	s0,sp,32
    80001a92:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	154080e7          	jalr	340(ra) # 80000be8 <holding>
    80001a9c:	c909                	beqz	a0,80001aae <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a9e:	749c                	ld	a5,40(s1)
    80001aa0:	00978f63          	beq	a5,s1,80001abe <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001aa4:	60e2                	ld	ra,24(sp)
    80001aa6:	6442                	ld	s0,16(sp)
    80001aa8:	64a2                	ld	s1,8(sp)
    80001aaa:	6105                	addi	sp,sp,32
    80001aac:	8082                	ret
    panic("wakeup1");
    80001aae:	00007517          	auipc	a0,0x7
    80001ab2:	84a50513          	addi	a0,a0,-1974 # 800082f8 <states.1760+0x28>
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	abe080e7          	jalr	-1346(ra) # 80000574 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001abe:	4c98                	lw	a4,24(s1)
    80001ac0:	4785                	li	a5,1
    80001ac2:	fef711e3          	bne	a4,a5,80001aa4 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001ac6:	4789                	li	a5,2
    80001ac8:	cc9c                	sw	a5,24(s1)
}
    80001aca:	bfe9                	j	80001aa4 <wakeup1+0x1c>

0000000080001acc <procinit>:
{
    80001acc:	7179                	addi	sp,sp,-48
    80001ace:	f406                	sd	ra,40(sp)
    80001ad0:	f022                	sd	s0,32(sp)
    80001ad2:	ec26                	sd	s1,24(sp)
    80001ad4:	e84a                	sd	s2,16(sp)
    80001ad6:	e44e                	sd	s3,8(sp)
    80001ad8:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001ada:	00007597          	auipc	a1,0x7
    80001ade:	82658593          	addi	a1,a1,-2010 # 80008300 <states.1760+0x30>
    80001ae2:	00010517          	auipc	a0,0x10
    80001ae6:	e6e50513          	addi	a0,a0,-402 # 80011950 <pid_lock>
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	0e8080e7          	jalr	232(ra) # 80000bd2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001af2:	00010497          	auipc	s1,0x10
    80001af6:	27648493          	addi	s1,s1,630 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001afa:	00007997          	auipc	s3,0x7
    80001afe:	80e98993          	addi	s3,s3,-2034 # 80008308 <states.1760+0x38>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b02:	00016917          	auipc	s2,0x16
    80001b06:	e6690913          	addi	s2,s2,-410 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001b0a:	85ce                	mv	a1,s3
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	0c4080e7          	jalr	196(ra) # 80000bd2 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b16:	17048493          	addi	s1,s1,368
    80001b1a:	ff2498e3          	bne	s1,s2,80001b0a <procinit+0x3e>
}
    80001b1e:	70a2                	ld	ra,40(sp)
    80001b20:	7402                	ld	s0,32(sp)
    80001b22:	64e2                	ld	s1,24(sp)
    80001b24:	6942                	ld	s2,16(sp)
    80001b26:	69a2                	ld	s3,8(sp)
    80001b28:	6145                	addi	sp,sp,48
    80001b2a:	8082                	ret

0000000080001b2c <cpuid>:
{
    80001b2c:	1141                	addi	sp,sp,-16
    80001b2e:	e422                	sd	s0,8(sp)
    80001b30:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b32:	8512                	mv	a0,tp
}
    80001b34:	2501                	sext.w	a0,a0
    80001b36:	6422                	ld	s0,8(sp)
    80001b38:	0141                	addi	sp,sp,16
    80001b3a:	8082                	ret

0000000080001b3c <mycpu>:
mycpu(void) {
    80001b3c:	1141                	addi	sp,sp,-16
    80001b3e:	e422                	sd	s0,8(sp)
    80001b40:	0800                	addi	s0,sp,16
    80001b42:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b44:	2781                	sext.w	a5,a5
    80001b46:	079e                	slli	a5,a5,0x7
}
    80001b48:	00010517          	auipc	a0,0x10
    80001b4c:	e2050513          	addi	a0,a0,-480 # 80011968 <cpus>
    80001b50:	953e                	add	a0,a0,a5
    80001b52:	6422                	ld	s0,8(sp)
    80001b54:	0141                	addi	sp,sp,16
    80001b56:	8082                	ret

0000000080001b58 <myproc>:
myproc(void) {
    80001b58:	1101                	addi	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	1000                	addi	s0,sp,32
  push_off();
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	0b4080e7          	jalr	180(ra) # 80000c16 <push_off>
    80001b6a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b6c:	2781                	sext.w	a5,a5
    80001b6e:	079e                	slli	a5,a5,0x7
    80001b70:	00010717          	auipc	a4,0x10
    80001b74:	de070713          	addi	a4,a4,-544 # 80011950 <pid_lock>
    80001b78:	97ba                	add	a5,a5,a4
    80001b7a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	13a080e7          	jalr	314(ra) # 80000cb6 <pop_off>
}
    80001b84:	8526                	mv	a0,s1
    80001b86:	60e2                	ld	ra,24(sp)
    80001b88:	6442                	ld	s0,16(sp)
    80001b8a:	64a2                	ld	s1,8(sp)
    80001b8c:	6105                	addi	sp,sp,32
    80001b8e:	8082                	ret

0000000080001b90 <forkret>:
{
    80001b90:	1141                	addi	sp,sp,-16
    80001b92:	e406                	sd	ra,8(sp)
    80001b94:	e022                	sd	s0,0(sp)
    80001b96:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b98:	00000097          	auipc	ra,0x0
    80001b9c:	fc0080e7          	jalr	-64(ra) # 80001b58 <myproc>
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	176080e7          	jalr	374(ra) # 80000d16 <release>
  if (first) {
    80001ba8:	00007797          	auipc	a5,0x7
    80001bac:	da878793          	addi	a5,a5,-600 # 80008950 <first.1720>
    80001bb0:	439c                	lw	a5,0(a5)
    80001bb2:	eb89                	bnez	a5,80001bc4 <forkret+0x34>
  usertrapret();
    80001bb4:	00001097          	auipc	ra,0x1
    80001bb8:	e1e080e7          	jalr	-482(ra) # 800029d2 <usertrapret>
}
    80001bbc:	60a2                	ld	ra,8(sp)
    80001bbe:	6402                	ld	s0,0(sp)
    80001bc0:	0141                	addi	sp,sp,16
    80001bc2:	8082                	ret
    first = 0;
    80001bc4:	00007797          	auipc	a5,0x7
    80001bc8:	d807a623          	sw	zero,-628(a5) # 80008950 <first.1720>
    fsinit(ROOTDEV);
    80001bcc:	4505                	li	a0,1
    80001bce:	00002097          	auipc	ra,0x2
    80001bd2:	b98080e7          	jalr	-1128(ra) # 80003766 <fsinit>
    80001bd6:	bff9                	j	80001bb4 <forkret+0x24>

0000000080001bd8 <allocpid>:
allocpid() {
    80001bd8:	1101                	addi	sp,sp,-32
    80001bda:	ec06                	sd	ra,24(sp)
    80001bdc:	e822                	sd	s0,16(sp)
    80001bde:	e426                	sd	s1,8(sp)
    80001be0:	e04a                	sd	s2,0(sp)
    80001be2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001be4:	00010917          	auipc	s2,0x10
    80001be8:	d6c90913          	addi	s2,s2,-660 # 80011950 <pid_lock>
    80001bec:	854a                	mv	a0,s2
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	074080e7          	jalr	116(ra) # 80000c62 <acquire>
  pid = nextpid;
    80001bf6:	00007797          	auipc	a5,0x7
    80001bfa:	d5e78793          	addi	a5,a5,-674 # 80008954 <nextpid>
    80001bfe:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c00:	0014871b          	addiw	a4,s1,1
    80001c04:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c06:	854a                	mv	a0,s2
    80001c08:	fffff097          	auipc	ra,0xfffff
    80001c0c:	10e080e7          	jalr	270(ra) # 80000d16 <release>
}
    80001c10:	8526                	mv	a0,s1
    80001c12:	60e2                	ld	ra,24(sp)
    80001c14:	6442                	ld	s0,16(sp)
    80001c16:	64a2                	ld	s1,8(sp)
    80001c18:	6902                	ld	s2,0(sp)
    80001c1a:	6105                	addi	sp,sp,32
    80001c1c:	8082                	ret

0000000080001c1e <proc_free_kernel_pagetable>:
{
    80001c1e:	7179                	addi	sp,sp,-48
    80001c20:	f406                	sd	ra,40(sp)
    80001c22:	f022                	sd	s0,32(sp)
    80001c24:	ec26                	sd	s1,24(sp)
    80001c26:	e84a                	sd	s2,16(sp)
    80001c28:	e44e                	sd	s3,8(sp)
    80001c2a:	1800                	addi	s0,sp,48
    80001c2c:	84aa                	mv	s1,a0
    80001c2e:	892e                	mv	s2,a1
    uvmunmap(pagetable, UART0, 1, 0);
    80001c30:	4681                	li	a3,0
    80001c32:	4605                	li	a2,1
    80001c34:	100005b7          	lui	a1,0x10000
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	728080e7          	jalr	1832(ra) # 80001360 <uvmunmap>
    uvmunmap(pagetable, VIRTIO0, 1, 0);
    80001c40:	4681                	li	a3,0
    80001c42:	4605                	li	a2,1
    80001c44:	100015b7          	lui	a1,0x10001
    80001c48:	8526                	mv	a0,s1
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	716080e7          	jalr	1814(ra) # 80001360 <uvmunmap>
    uvmunmap(pagetable, PLIC, 0x400000/PGSIZE, 0);
    80001c52:	4681                	li	a3,0
    80001c54:	40000613          	li	a2,1024
    80001c58:	0c0005b7          	lui	a1,0xc000
    80001c5c:	8526                	mv	a0,s1
    80001c5e:	fffff097          	auipc	ra,0xfffff
    80001c62:	702080e7          	jalr	1794(ra) # 80001360 <uvmunmap>
    uvmunmap(pagetable, KERNBASE, ((uint64)etext-KERNBASE)/PGSIZE, 0);
    80001c66:	00006997          	auipc	s3,0x6
    80001c6a:	39a98993          	addi	s3,s3,922 # 80008000 <etext>
    80001c6e:	4681                	li	a3,0
    80001c70:	80006617          	auipc	a2,0x80006
    80001c74:	39060613          	addi	a2,a2,912 # 8000 <_entry-0x7fff8000>
    80001c78:	8231                	srli	a2,a2,0xc
    80001c7a:	4585                	li	a1,1
    80001c7c:	05fe                	slli	a1,a1,0x1f
    80001c7e:	8526                	mv	a0,s1
    80001c80:	fffff097          	auipc	ra,0xfffff
    80001c84:	6e0080e7          	jalr	1760(ra) # 80001360 <uvmunmap>
    uvmunmap(pagetable, (uint64)etext, (PHYSTOP-(uint64)etext)/PGSIZE, 0);
    80001c88:	4645                	li	a2,17
    80001c8a:	066e                	slli	a2,a2,0x1b
    80001c8c:	41360633          	sub	a2,a2,s3
    80001c90:	4681                	li	a3,0
    80001c92:	8231                	srli	a2,a2,0xc
    80001c94:	85ce                	mv	a1,s3
    80001c96:	8526                	mv	a0,s1
    80001c98:	fffff097          	auipc	ra,0xfffff
    80001c9c:	6c8080e7          	jalr	1736(ra) # 80001360 <uvmunmap>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ca0:	4681                	li	a3,0
    80001ca2:	4605                	li	a2,1
    80001ca4:	040005b7          	lui	a1,0x4000
    80001ca8:	15fd                	addi	a1,a1,-1
    80001caa:	05b2                	slli	a1,a1,0xc
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6b2080e7          	jalr	1714(ra) # 80001360 <uvmunmap>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 0);
    80001cb6:	6605                	lui	a2,0x1
    80001cb8:	167d                	addi	a2,a2,-1
    80001cba:	964a                	add	a2,a2,s2
    80001cbc:	4681                	li	a3,0
    80001cbe:	8231                	srli	a2,a2,0xc
    80001cc0:	4581                	li	a1,0
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	69c080e7          	jalr	1692(ra) # 80001360 <uvmunmap>
    freewalk(pagetable);
    80001ccc:	8526                	mv	a0,s1
    80001cce:	00000097          	auipc	ra,0x0
    80001cd2:	8e8080e7          	jalr	-1816(ra) # 800015b6 <freewalk>
}
    80001cd6:	70a2                	ld	ra,40(sp)
    80001cd8:	7402                	ld	s0,32(sp)
    80001cda:	64e2                	ld	s1,24(sp)
    80001cdc:	6942                	ld	s2,16(sp)
    80001cde:	69a2                	ld	s3,8(sp)
    80001ce0:	6145                	addi	sp,sp,48
    80001ce2:	8082                	ret

0000000080001ce4 <proc_pagetable>:
{
    80001ce4:	1101                	addi	sp,sp,-32
    80001ce6:	ec06                	sd	ra,24(sp)
    80001ce8:	e822                	sd	s0,16(sp)
    80001cea:	e426                	sd	s1,8(sp)
    80001cec:	e04a                	sd	s2,0(sp)
    80001cee:	1000                	addi	s0,sp,32
    80001cf0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cf2:	fffff097          	auipc	ra,0xfffff
    80001cf6:	734080e7          	jalr	1844(ra) # 80001426 <uvmcreate>
    80001cfa:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001cfc:	c121                	beqz	a0,80001d3c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cfe:	4729                	li	a4,10
    80001d00:	00005697          	auipc	a3,0x5
    80001d04:	30068693          	addi	a3,a3,768 # 80007000 <_trampoline>
    80001d08:	6605                	lui	a2,0x1
    80001d0a:	040005b7          	lui	a1,0x4000
    80001d0e:	15fd                	addi	a1,a1,-1
    80001d10:	05b2                	slli	a1,a1,0xc
    80001d12:	fffff097          	auipc	ra,0xfffff
    80001d16:	4b6080e7          	jalr	1206(ra) # 800011c8 <mappages>
    80001d1a:	02054863          	bltz	a0,80001d4a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d1e:	4719                	li	a4,6
    80001d20:	05893683          	ld	a3,88(s2)
    80001d24:	6605                	lui	a2,0x1
    80001d26:	020005b7          	lui	a1,0x2000
    80001d2a:	15fd                	addi	a1,a1,-1
    80001d2c:	05b6                	slli	a1,a1,0xd
    80001d2e:	8526                	mv	a0,s1
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	498080e7          	jalr	1176(ra) # 800011c8 <mappages>
    80001d38:	02054163          	bltz	a0,80001d5a <proc_pagetable+0x76>
}
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	60e2                	ld	ra,24(sp)
    80001d40:	6442                	ld	s0,16(sp)
    80001d42:	64a2                	ld	s1,8(sp)
    80001d44:	6902                	ld	s2,0(sp)
    80001d46:	6105                	addi	sp,sp,32
    80001d48:	8082                	ret
    uvmfree(pagetable, 0);
    80001d4a:	4581                	li	a1,0
    80001d4c:	8526                	mv	a0,s1
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	8d2080e7          	jalr	-1838(ra) # 80001620 <uvmfree>
    return 0;
    80001d56:	4481                	li	s1,0
    80001d58:	b7d5                	j	80001d3c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d5a:	4681                	li	a3,0
    80001d5c:	4605                	li	a2,1
    80001d5e:	040005b7          	lui	a1,0x4000
    80001d62:	15fd                	addi	a1,a1,-1
    80001d64:	05b2                	slli	a1,a1,0xc
    80001d66:	8526                	mv	a0,s1
    80001d68:	fffff097          	auipc	ra,0xfffff
    80001d6c:	5f8080e7          	jalr	1528(ra) # 80001360 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d70:	4581                	li	a1,0
    80001d72:	8526                	mv	a0,s1
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	8ac080e7          	jalr	-1876(ra) # 80001620 <uvmfree>
    return 0;
    80001d7c:	4481                	li	s1,0
    80001d7e:	bf7d                	j	80001d3c <proc_pagetable+0x58>

0000000080001d80 <proc_freepagetable>:
{
    80001d80:	1101                	addi	sp,sp,-32
    80001d82:	ec06                	sd	ra,24(sp)
    80001d84:	e822                	sd	s0,16(sp)
    80001d86:	e426                	sd	s1,8(sp)
    80001d88:	e04a                	sd	s2,0(sp)
    80001d8a:	1000                	addi	s0,sp,32
    80001d8c:	84aa                	mv	s1,a0
    80001d8e:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d90:	4681                	li	a3,0
    80001d92:	4605                	li	a2,1
    80001d94:	040005b7          	lui	a1,0x4000
    80001d98:	15fd                	addi	a1,a1,-1
    80001d9a:	05b2                	slli	a1,a1,0xc
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	5c4080e7          	jalr	1476(ra) # 80001360 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001da4:	4681                	li	a3,0
    80001da6:	4605                	li	a2,1
    80001da8:	020005b7          	lui	a1,0x2000
    80001dac:	15fd                	addi	a1,a1,-1
    80001dae:	05b6                	slli	a1,a1,0xd
    80001db0:	8526                	mv	a0,s1
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	5ae080e7          	jalr	1454(ra) # 80001360 <uvmunmap>
  uvmfree(pagetable, sz);
    80001dba:	85ca                	mv	a1,s2
    80001dbc:	8526                	mv	a0,s1
    80001dbe:	00000097          	auipc	ra,0x0
    80001dc2:	862080e7          	jalr	-1950(ra) # 80001620 <uvmfree>
}
    80001dc6:	60e2                	ld	ra,24(sp)
    80001dc8:	6442                	ld	s0,16(sp)
    80001dca:	64a2                	ld	s1,8(sp)
    80001dcc:	6902                	ld	s2,0(sp)
    80001dce:	6105                	addi	sp,sp,32
    80001dd0:	8082                	ret

0000000080001dd2 <freeproc>:
{
    80001dd2:	1101                	addi	sp,sp,-32
    80001dd4:	ec06                	sd	ra,24(sp)
    80001dd6:	e822                	sd	s0,16(sp)
    80001dd8:	e426                	sd	s1,8(sp)
    80001dda:	1000                	addi	s0,sp,32
    80001ddc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001dde:	6d28                	ld	a0,88(a0)
    80001de0:	c509                	beqz	a0,80001dea <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	c90080e7          	jalr	-880(ra) # 80000a72 <kfree>
  p->trapframe = 0;
    80001dea:	0404bc23          	sd	zero,88(s1)
  if (p->kstack)
    80001dee:	60ac                	ld	a1,64(s1)
    80001df0:	e9b9                	bnez	a1,80001e46 <freeproc+0x74>
  p->kstack = 0;
    80001df2:	0404b023          	sd	zero,64(s1)
  if(p->kernel_pagetable)
    80001df6:	1684b503          	ld	a0,360(s1)
    80001dfa:	c511                	beqz	a0,80001e06 <freeproc+0x34>
      proc_free_kernel_pagetable(p->kernel_pagetable,p->sz);
    80001dfc:	64ac                	ld	a1,72(s1)
    80001dfe:	00000097          	auipc	ra,0x0
    80001e02:	e20080e7          	jalr	-480(ra) # 80001c1e <proc_free_kernel_pagetable>
  p->kernel_pagetable = 0;
    80001e06:	1604b423          	sd	zero,360(s1)
  if(p->pagetable)
    80001e0a:	68a8                	ld	a0,80(s1)
    80001e0c:	c511                	beqz	a0,80001e18 <freeproc+0x46>
    proc_freepagetable(p->pagetable, p->sz);
    80001e0e:	64ac                	ld	a1,72(s1)
    80001e10:	00000097          	auipc	ra,0x0
    80001e14:	f70080e7          	jalr	-144(ra) # 80001d80 <proc_freepagetable>
  p->pagetable = 0;
    80001e18:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001e1c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001e20:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001e24:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001e28:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e2c:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001e30:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001e34:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001e38:	0004ac23          	sw	zero,24(s1)
}
    80001e3c:	60e2                	ld	ra,24(sp)
    80001e3e:	6442                	ld	s0,16(sp)
    80001e40:	64a2                	ld	s1,8(sp)
    80001e42:	6105                	addi	sp,sp,32
    80001e44:	8082                	ret
      uvmunmap(p->kernel_pagetable, p->kstack, 1, 1);
    80001e46:	4685                	li	a3,1
    80001e48:	4605                	li	a2,1
    80001e4a:	1684b503          	ld	a0,360(s1)
    80001e4e:	fffff097          	auipc	ra,0xfffff
    80001e52:	512080e7          	jalr	1298(ra) # 80001360 <uvmunmap>
    80001e56:	bf71                	j	80001df2 <freeproc+0x20>

0000000080001e58 <allocproc>:
{
    80001e58:	1101                	addi	sp,sp,-32
    80001e5a:	ec06                	sd	ra,24(sp)
    80001e5c:	e822                	sd	s0,16(sp)
    80001e5e:	e426                	sd	s1,8(sp)
    80001e60:	e04a                	sd	s2,0(sp)
    80001e62:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e64:	00010497          	auipc	s1,0x10
    80001e68:	f0448493          	addi	s1,s1,-252 # 80011d68 <proc>
    80001e6c:	00016917          	auipc	s2,0x16
    80001e70:	afc90913          	addi	s2,s2,-1284 # 80017968 <tickslock>
    acquire(&p->lock);
    80001e74:	8526                	mv	a0,s1
    80001e76:	fffff097          	auipc	ra,0xfffff
    80001e7a:	dec080e7          	jalr	-532(ra) # 80000c62 <acquire>
    if(p->state == UNUSED) {
    80001e7e:	4c9c                	lw	a5,24(s1)
    80001e80:	cf81                	beqz	a5,80001e98 <allocproc+0x40>
      release(&p->lock);
    80001e82:	8526                	mv	a0,s1
    80001e84:	fffff097          	auipc	ra,0xfffff
    80001e88:	e92080e7          	jalr	-366(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e8c:	17048493          	addi	s1,s1,368
    80001e90:	ff2492e3          	bne	s1,s2,80001e74 <allocproc+0x1c>
  return 0;
    80001e94:	4481                	li	s1,0
    80001e96:	a06d                	j	80001f40 <allocproc+0xe8>
  p->pid = allocpid();
    80001e98:	00000097          	auipc	ra,0x0
    80001e9c:	d40080e7          	jalr	-704(ra) # 80001bd8 <allocpid>
    80001ea0:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	cd0080e7          	jalr	-816(ra) # 80000b72 <kalloc>
    80001eaa:	892a                	mv	s2,a0
    80001eac:	eca8                	sd	a0,88(s1)
    80001eae:	c145                	beqz	a0,80001f4e <allocproc+0xf6>
  p->pagetable = proc_pagetable(p);
    80001eb0:	8526                	mv	a0,s1
    80001eb2:	00000097          	auipc	ra,0x0
    80001eb6:	e32080e7          	jalr	-462(ra) # 80001ce4 <proc_pagetable>
    80001eba:	892a                	mv	s2,a0
    80001ebc:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001ebe:	cd59                	beqz	a0,80001f5c <allocproc+0x104>
  p->kernel_pagetable = kvmbuild();
    80001ec0:	00000097          	auipc	ra,0x0
    80001ec4:	a38080e7          	jalr	-1480(ra) # 800018f8 <kvmbuild>
    80001ec8:	16a4b423          	sd	a0,360(s1)
  char *pa = kalloc();
    80001ecc:	fffff097          	auipc	ra,0xfffff
    80001ed0:	ca6080e7          	jalr	-858(ra) # 80000b72 <kalloc>
    80001ed4:	86aa                	mv	a3,a0
  if(pa == 0)
    80001ed6:	cd59                	beqz	a0,80001f74 <allocproc+0x11c>
  uint64 va = KSTACK((int) (p - proc));
    80001ed8:	00010797          	auipc	a5,0x10
    80001edc:	e9078793          	addi	a5,a5,-368 # 80011d68 <proc>
    80001ee0:	40f487b3          	sub	a5,s1,a5
    80001ee4:	8791                	srai	a5,a5,0x4
    80001ee6:	00006717          	auipc	a4,0x6
    80001eea:	11a70713          	addi	a4,a4,282 # 80008000 <etext>
    80001eee:	6318                	ld	a4,0(a4)
    80001ef0:	02e787b3          	mul	a5,a5,a4
    80001ef4:	2785                	addiw	a5,a5,1
    80001ef6:	00d7979b          	slliw	a5,a5,0xd
    80001efa:	04000937          	lui	s2,0x4000
    80001efe:	197d                	addi	s2,s2,-1
    80001f00:	0932                	slli	s2,s2,0xc
    80001f02:	40f90933          	sub	s2,s2,a5
  mappages(p->kernel_pagetable, va, PGSIZE, (uint64)pa, PTE_R | PTE_W);
    80001f06:	4719                	li	a4,6
    80001f08:	6605                	lui	a2,0x1
    80001f0a:	85ca                	mv	a1,s2
    80001f0c:	1684b503          	ld	a0,360(s1)
    80001f10:	fffff097          	auipc	ra,0xfffff
    80001f14:	2b8080e7          	jalr	696(ra) # 800011c8 <mappages>
  p->kstack = va;
    80001f18:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001f1c:	07000613          	li	a2,112
    80001f20:	4581                	li	a1,0
    80001f22:	06048513          	addi	a0,s1,96
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	e38080e7          	jalr	-456(ra) # 80000d5e <memset>
  p->context.ra = (uint64)forkret;
    80001f2e:	00000797          	auipc	a5,0x0
    80001f32:	c6278793          	addi	a5,a5,-926 # 80001b90 <forkret>
    80001f36:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001f38:	60bc                	ld	a5,64(s1)
    80001f3a:	6705                	lui	a4,0x1
    80001f3c:	97ba                	add	a5,a5,a4
    80001f3e:	f4bc                	sd	a5,104(s1)
}
    80001f40:	8526                	mv	a0,s1
    80001f42:	60e2                	ld	ra,24(sp)
    80001f44:	6442                	ld	s0,16(sp)
    80001f46:	64a2                	ld	s1,8(sp)
    80001f48:	6902                	ld	s2,0(sp)
    80001f4a:	6105                	addi	sp,sp,32
    80001f4c:	8082                	ret
    release(&p->lock);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	dc6080e7          	jalr	-570(ra) # 80000d16 <release>
    return 0;
    80001f58:	84ca                	mv	s1,s2
    80001f5a:	b7dd                	j	80001f40 <allocproc+0xe8>
    freeproc(p);
    80001f5c:	8526                	mv	a0,s1
    80001f5e:	00000097          	auipc	ra,0x0
    80001f62:	e74080e7          	jalr	-396(ra) # 80001dd2 <freeproc>
    release(&p->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	dae080e7          	jalr	-594(ra) # 80000d16 <release>
    return 0;
    80001f70:	84ca                	mv	s1,s2
    80001f72:	b7f9                	j	80001f40 <allocproc+0xe8>
      panic("kalloc");
    80001f74:	00006517          	auipc	a0,0x6
    80001f78:	39c50513          	addi	a0,a0,924 # 80008310 <states.1760+0x40>
    80001f7c:	ffffe097          	auipc	ra,0xffffe
    80001f80:	5f8080e7          	jalr	1528(ra) # 80000574 <panic>

0000000080001f84 <userinit>:
{
    80001f84:	1101                	addi	sp,sp,-32
    80001f86:	ec06                	sd	ra,24(sp)
    80001f88:	e822                	sd	s0,16(sp)
    80001f8a:	e426                	sd	s1,8(sp)
    80001f8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f8e:	00000097          	auipc	ra,0x0
    80001f92:	eca080e7          	jalr	-310(ra) # 80001e58 <allocproc>
    80001f96:	84aa                	mv	s1,a0
  initproc = p;
    80001f98:	00007797          	auipc	a5,0x7
    80001f9c:	08a7b023          	sd	a0,128(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001fa0:	03400613          	li	a2,52
    80001fa4:	00007597          	auipc	a1,0x7
    80001fa8:	9bc58593          	addi	a1,a1,-1604 # 80008960 <initcode>
    80001fac:	6928                	ld	a0,80(a0)
    80001fae:	fffff097          	auipc	ra,0xfffff
    80001fb2:	4a6080e7          	jalr	1190(ra) # 80001454 <uvminit>
  p->sz = PGSIZE;
    80001fb6:	6785                	lui	a5,0x1
    80001fb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001fba:	6cb8                	ld	a4,88(s1)
    80001fbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001fc0:	6cb8                	ld	a4,88(s1)
    80001fc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fc4:	4641                	li	a2,16
    80001fc6:	00006597          	auipc	a1,0x6
    80001fca:	35258593          	addi	a1,a1,850 # 80008318 <states.1760+0x48>
    80001fce:	15848513          	addi	a0,s1,344
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	f04080e7          	jalr	-252(ra) # 80000ed6 <safestrcpy>
  p->cwd = namei("/");
    80001fda:	00006517          	auipc	a0,0x6
    80001fde:	34e50513          	addi	a0,a0,846 # 80008328 <states.1760+0x58>
    80001fe2:	00002097          	auipc	ra,0x2
    80001fe6:	1b8080e7          	jalr	440(ra) # 8000419a <namei>
    80001fea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001fee:	4789                	li	a5,2
    80001ff0:	cc9c                	sw	a5,24(s1)
  uvm2kvm(p->pagetable, p->kernel_pagetable, 0, p->sz);
    80001ff2:	64b4                	ld	a3,72(s1)
    80001ff4:	4601                	li	a2,0
    80001ff6:	1684b583          	ld	a1,360(s1)
    80001ffa:	68a8                	ld	a0,80(s1)
    80001ffc:	00000097          	auipc	ra,0x0
    80002000:	9c8080e7          	jalr	-1592(ra) # 800019c4 <uvm2kvm>
  release(&p->lock);
    80002004:	8526                	mv	a0,s1
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	d10080e7          	jalr	-752(ra) # 80000d16 <release>
}
    8000200e:	60e2                	ld	ra,24(sp)
    80002010:	6442                	ld	s0,16(sp)
    80002012:	64a2                	ld	s1,8(sp)
    80002014:	6105                	addi	sp,sp,32
    80002016:	8082                	ret

0000000080002018 <growproc>:
{
    80002018:	7179                	addi	sp,sp,-48
    8000201a:	f406                	sd	ra,40(sp)
    8000201c:	f022                	sd	s0,32(sp)
    8000201e:	ec26                	sd	s1,24(sp)
    80002020:	e84a                	sd	s2,16(sp)
    80002022:	e44e                	sd	s3,8(sp)
    80002024:	1800                	addi	s0,sp,48
    80002026:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002028:	00000097          	auipc	ra,0x0
    8000202c:	b30080e7          	jalr	-1232(ra) # 80001b58 <myproc>
    80002030:	89aa                	mv	s3,a0
  sz = p->sz;
    80002032:	652c                	ld	a1,72(a0)
    80002034:	0005849b          	sext.w	s1,a1
  if(n > 0){
    80002038:	03204063          	bgtz	s2,80002058 <growproc+0x40>
  } else if(n < 0){
    8000203c:	04094e63          	bltz	s2,80002098 <growproc+0x80>
  p->sz = sz;
    80002040:	1482                	slli	s1,s1,0x20
    80002042:	9081                	srli	s1,s1,0x20
    80002044:	0499b423          	sd	s1,72(s3)
  return 0;
    80002048:	4501                	li	a0,0
}
    8000204a:	70a2                	ld	ra,40(sp)
    8000204c:	7402                	ld	s0,32(sp)
    8000204e:	64e2                	ld	s1,24(sp)
    80002050:	6942                	ld	s2,16(sp)
    80002052:	69a2                	ld	s3,8(sp)
    80002054:	6145                	addi	sp,sp,48
    80002056:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002058:	2901                	sext.w	s2,s2
    8000205a:	0099063b          	addw	a2,s2,s1
    8000205e:	1602                	slli	a2,a2,0x20
    80002060:	9201                	srli	a2,a2,0x20
    80002062:	1582                	slli	a1,a1,0x20
    80002064:	9181                	srli	a1,a1,0x20
    80002066:	6928                	ld	a0,80(a0)
    80002068:	fffff097          	auipc	ra,0xfffff
    8000206c:	4a4080e7          	jalr	1188(ra) # 8000150c <uvmalloc>
    80002070:	0005049b          	sext.w	s1,a0
    80002074:	c8a5                	beqz	s1,800020e4 <growproc+0xcc>
    uvm2kvm(p->pagetable, p->kernel_pagetable, sz - n, sz);
    80002076:	4124893b          	subw	s2,s1,s2
    8000207a:	02051693          	slli	a3,a0,0x20
    8000207e:	9281                	srli	a3,a3,0x20
    80002080:	02091613          	slli	a2,s2,0x20
    80002084:	9201                	srli	a2,a2,0x20
    80002086:	1689b583          	ld	a1,360(s3)
    8000208a:	0509b503          	ld	a0,80(s3)
    8000208e:	00000097          	auipc	ra,0x0
    80002092:	936080e7          	jalr	-1738(ra) # 800019c4 <uvm2kvm>
    80002096:	b76d                	j	80002040 <growproc+0x28>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002098:	0099063b          	addw	a2,s2,s1
    8000209c:	1602                	slli	a2,a2,0x20
    8000209e:	9201                	srli	a2,a2,0x20
    800020a0:	1582                	slli	a1,a1,0x20
    800020a2:	9181                	srli	a1,a1,0x20
    800020a4:	6928                	ld	a0,80(a0)
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	420080e7          	jalr	1056(ra) # 800014c6 <uvmdealloc>
    800020ae:	0005049b          	sext.w	s1,a0
    uvmunmap(p->kernel_pagetable, PGROUNDUP(sz), (-n)/PGSIZE, 0);
    800020b2:	41f9561b          	sraiw	a2,s2,0x1f
    800020b6:	0146561b          	srliw	a2,a2,0x14
    800020ba:	0126063b          	addw	a2,a2,s2
    800020be:	40c6561b          	sraiw	a2,a2,0xc
    800020c2:	6585                	lui	a1,0x1
    800020c4:	35fd                	addiw	a1,a1,-1
    800020c6:	9da5                	addw	a1,a1,s1
    800020c8:	77fd                	lui	a5,0xfffff
    800020ca:	8dfd                	and	a1,a1,a5
    800020cc:	1582                	slli	a1,a1,0x20
    800020ce:	9181                	srli	a1,a1,0x20
    800020d0:	4681                	li	a3,0
    800020d2:	40c0063b          	negw	a2,a2
    800020d6:	1689b503          	ld	a0,360(s3)
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	286080e7          	jalr	646(ra) # 80001360 <uvmunmap>
    800020e2:	bfb9                	j	80002040 <growproc+0x28>
      return -1;
    800020e4:	557d                	li	a0,-1
    800020e6:	b795                	j	8000204a <growproc+0x32>

00000000800020e8 <fork>:
{
    800020e8:	7179                	addi	sp,sp,-48
    800020ea:	f406                	sd	ra,40(sp)
    800020ec:	f022                	sd	s0,32(sp)
    800020ee:	ec26                	sd	s1,24(sp)
    800020f0:	e84a                	sd	s2,16(sp)
    800020f2:	e44e                	sd	s3,8(sp)
    800020f4:	e052                	sd	s4,0(sp)
    800020f6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020f8:	00000097          	auipc	ra,0x0
    800020fc:	a60080e7          	jalr	-1440(ra) # 80001b58 <myproc>
    80002100:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002102:	00000097          	auipc	ra,0x0
    80002106:	d56080e7          	jalr	-682(ra) # 80001e58 <allocproc>
    8000210a:	cd6d                	beqz	a0,80002204 <fork+0x11c>
    8000210c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000210e:	04893603          	ld	a2,72(s2) # 4000048 <_entry-0x7bffffb8>
    80002112:	692c                	ld	a1,80(a0)
    80002114:	05093503          	ld	a0,80(s2)
    80002118:	fffff097          	auipc	ra,0xfffff
    8000211c:	540080e7          	jalr	1344(ra) # 80001658 <uvmcopy>
    80002120:	04054863          	bltz	a0,80002170 <fork+0x88>
  np->sz = p->sz;
    80002124:	04893783          	ld	a5,72(s2)
    80002128:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    8000212c:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80002130:	05893683          	ld	a3,88(s2)
    80002134:	87b6                	mv	a5,a3
    80002136:	0589b703          	ld	a4,88(s3)
    8000213a:	12068693          	addi	a3,a3,288
    8000213e:	0007b803          	ld	a6,0(a5) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    80002142:	6788                	ld	a0,8(a5)
    80002144:	6b8c                	ld	a1,16(a5)
    80002146:	6f90                	ld	a2,24(a5)
    80002148:	01073023          	sd	a6,0(a4)
    8000214c:	e708                	sd	a0,8(a4)
    8000214e:	eb0c                	sd	a1,16(a4)
    80002150:	ef10                	sd	a2,24(a4)
    80002152:	02078793          	addi	a5,a5,32
    80002156:	02070713          	addi	a4,a4,32
    8000215a:	fed792e3          	bne	a5,a3,8000213e <fork+0x56>
  np->trapframe->a0 = 0;
    8000215e:	0589b783          	ld	a5,88(s3)
    80002162:	0607b823          	sd	zero,112(a5)
    80002166:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    8000216a:	15000a13          	li	s4,336
    8000216e:	a03d                	j	8000219c <fork+0xb4>
    freeproc(np);
    80002170:	854e                	mv	a0,s3
    80002172:	00000097          	auipc	ra,0x0
    80002176:	c60080e7          	jalr	-928(ra) # 80001dd2 <freeproc>
    release(&np->lock);
    8000217a:	854e                	mv	a0,s3
    8000217c:	fffff097          	auipc	ra,0xfffff
    80002180:	b9a080e7          	jalr	-1126(ra) # 80000d16 <release>
    return -1;
    80002184:	54fd                	li	s1,-1
    80002186:	a0b5                	j	800021f2 <fork+0x10a>
      np->ofile[i] = filedup(p->ofile[i]);
    80002188:	00002097          	auipc	ra,0x2
    8000218c:	6d0080e7          	jalr	1744(ra) # 80004858 <filedup>
    80002190:	009987b3          	add	a5,s3,s1
    80002194:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002196:	04a1                	addi	s1,s1,8
    80002198:	01448763          	beq	s1,s4,800021a6 <fork+0xbe>
    if(p->ofile[i])
    8000219c:	009907b3          	add	a5,s2,s1
    800021a0:	6388                	ld	a0,0(a5)
    800021a2:	f17d                	bnez	a0,80002188 <fork+0xa0>
    800021a4:	bfcd                	j	80002196 <fork+0xae>
  np->cwd = idup(p->cwd);
    800021a6:	15093503          	ld	a0,336(s2)
    800021aa:	00001097          	auipc	ra,0x1
    800021ae:	7f8080e7          	jalr	2040(ra) # 800039a2 <idup>
    800021b2:	14a9b823          	sd	a0,336(s3)
  uvm2kvm(np->pagetable, np->kernel_pagetable, 0, np->sz);
    800021b6:	0489b683          	ld	a3,72(s3)
    800021ba:	4601                	li	a2,0
    800021bc:	1689b583          	ld	a1,360(s3)
    800021c0:	0509b503          	ld	a0,80(s3)
    800021c4:	00000097          	auipc	ra,0x0
    800021c8:	800080e7          	jalr	-2048(ra) # 800019c4 <uvm2kvm>
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021cc:	4641                	li	a2,16
    800021ce:	15890593          	addi	a1,s2,344
    800021d2:	15898513          	addi	a0,s3,344
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	d00080e7          	jalr	-768(ra) # 80000ed6 <safestrcpy>
  pid = np->pid;
    800021de:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    800021e2:	4789                	li	a5,2
    800021e4:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800021e8:	854e                	mv	a0,s3
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	b2c080e7          	jalr	-1236(ra) # 80000d16 <release>
}
    800021f2:	8526                	mv	a0,s1
    800021f4:	70a2                	ld	ra,40(sp)
    800021f6:	7402                	ld	s0,32(sp)
    800021f8:	64e2                	ld	s1,24(sp)
    800021fa:	6942                	ld	s2,16(sp)
    800021fc:	69a2                	ld	s3,8(sp)
    800021fe:	6a02                	ld	s4,0(sp)
    80002200:	6145                	addi	sp,sp,48
    80002202:	8082                	ret
    return -1;
    80002204:	54fd                	li	s1,-1
    80002206:	b7f5                	j	800021f2 <fork+0x10a>

0000000080002208 <reparent>:
{
    80002208:	7179                	addi	sp,sp,-48
    8000220a:	f406                	sd	ra,40(sp)
    8000220c:	f022                	sd	s0,32(sp)
    8000220e:	ec26                	sd	s1,24(sp)
    80002210:	e84a                	sd	s2,16(sp)
    80002212:	e44e                	sd	s3,8(sp)
    80002214:	e052                	sd	s4,0(sp)
    80002216:	1800                	addi	s0,sp,48
    80002218:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000221a:	00010497          	auipc	s1,0x10
    8000221e:	b4e48493          	addi	s1,s1,-1202 # 80011d68 <proc>
      pp->parent = initproc;
    80002222:	00007a17          	auipc	s4,0x7
    80002226:	df6a0a13          	addi	s4,s4,-522 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000222a:	00015917          	auipc	s2,0x15
    8000222e:	73e90913          	addi	s2,s2,1854 # 80017968 <tickslock>
    80002232:	a029                	j	8000223c <reparent+0x34>
    80002234:	17048493          	addi	s1,s1,368
    80002238:	03248363          	beq	s1,s2,8000225e <reparent+0x56>
    if(pp->parent == p){
    8000223c:	709c                	ld	a5,32(s1)
    8000223e:	ff379be3          	bne	a5,s3,80002234 <reparent+0x2c>
      acquire(&pp->lock);
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	a1e080e7          	jalr	-1506(ra) # 80000c62 <acquire>
      pp->parent = initproc;
    8000224c:	000a3783          	ld	a5,0(s4)
    80002250:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	ac2080e7          	jalr	-1342(ra) # 80000d16 <release>
    8000225c:	bfe1                	j	80002234 <reparent+0x2c>
}
    8000225e:	70a2                	ld	ra,40(sp)
    80002260:	7402                	ld	s0,32(sp)
    80002262:	64e2                	ld	s1,24(sp)
    80002264:	6942                	ld	s2,16(sp)
    80002266:	69a2                	ld	s3,8(sp)
    80002268:	6a02                	ld	s4,0(sp)
    8000226a:	6145                	addi	sp,sp,48
    8000226c:	8082                	ret

000000008000226e <scheduler>:
{
    8000226e:	715d                	addi	sp,sp,-80
    80002270:	e486                	sd	ra,72(sp)
    80002272:	e0a2                	sd	s0,64(sp)
    80002274:	fc26                	sd	s1,56(sp)
    80002276:	f84a                	sd	s2,48(sp)
    80002278:	f44e                	sd	s3,40(sp)
    8000227a:	f052                	sd	s4,32(sp)
    8000227c:	ec56                	sd	s5,24(sp)
    8000227e:	e85a                	sd	s6,16(sp)
    80002280:	e45e                	sd	s7,8(sp)
    80002282:	e062                	sd	s8,0(sp)
    80002284:	0880                	addi	s0,sp,80
    80002286:	8792                	mv	a5,tp
  int id = r_tp();
    80002288:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000228a:	00779b13          	slli	s6,a5,0x7
    8000228e:	0000f717          	auipc	a4,0xf
    80002292:	6c270713          	addi	a4,a4,1730 # 80011950 <pid_lock>
    80002296:	975a                	add	a4,a4,s6
    80002298:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000229c:	0000f717          	auipc	a4,0xf
    800022a0:	6d470713          	addi	a4,a4,1748 # 80011970 <cpus+0x8>
    800022a4:	9b3a                	add	s6,s6,a4
        c->proc = p;
    800022a6:	079e                	slli	a5,a5,0x7
    800022a8:	0000fa17          	auipc	s4,0xf
    800022ac:	6a8a0a13          	addi	s4,s4,1704 # 80011950 <pid_lock>
    800022b0:	9a3e                	add	s4,s4,a5
        w_satp(MAKE_SATP(p->kernel_pagetable));
    800022b2:	5bfd                	li	s7,-1
    800022b4:	1bfe                	slli	s7,s7,0x3f
    for(p = proc; p < &proc[NPROC]; p++) {
    800022b6:	00015997          	auipc	s3,0x15
    800022ba:	6b298993          	addi	s3,s3,1714 # 80017968 <tickslock>
    800022be:	a885                	j	8000232e <scheduler+0xc0>
        p->state = RUNNING;
    800022c0:	0154ac23          	sw	s5,24(s1)
        c->proc = p;
    800022c4:	009a3c23          	sd	s1,24(s4)
        w_satp(MAKE_SATP(p->kernel_pagetable));
    800022c8:	1684b783          	ld	a5,360(s1)
    800022cc:	83b1                	srli	a5,a5,0xc
    800022ce:	0177e7b3          	or	a5,a5,s7
  asm volatile("csrw satp, %0" : : "r" (x));
    800022d2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800022d6:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    800022da:	06048593          	addi	a1,s1,96
    800022de:	855a                	mv	a0,s6
    800022e0:	00000097          	auipc	ra,0x0
    800022e4:	648080e7          	jalr	1608(ra) # 80002928 <swtch>
        kvminithart(); // use kernel page table
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	d68080e7          	jalr	-664(ra) # 80001050 <kvminithart>
        c->proc = 0;
    800022f0:	000a3c23          	sd	zero,24(s4)
        found = 1;
    800022f4:	4c05                	li	s8,1
      release(&p->lock);
    800022f6:	8526                	mv	a0,s1
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	a1e080e7          	jalr	-1506(ra) # 80000d16 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002300:	17048493          	addi	s1,s1,368
    80002304:	01348b63          	beq	s1,s3,8000231a <scheduler+0xac>
      acquire(&p->lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	958080e7          	jalr	-1704(ra) # 80000c62 <acquire>
      if(p->state == RUNNABLE) {
    80002312:	4c9c                	lw	a5,24(s1)
    80002314:	ff2791e3          	bne	a5,s2,800022f6 <scheduler+0x88>
    80002318:	b765                	j	800022c0 <scheduler+0x52>
    if(found == 0) {
    8000231a:	000c1a63          	bnez	s8,8000232e <scheduler+0xc0>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000231e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002322:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002326:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000232a:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000232e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002332:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002336:	10079073          	csrw	sstatus,a5
    int found = 0;
    8000233a:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    8000233c:	00010497          	auipc	s1,0x10
    80002340:	a2c48493          	addi	s1,s1,-1492 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002344:	4909                	li	s2,2
        p->state = RUNNING;
    80002346:	4a8d                	li	s5,3
    80002348:	b7c1                	j	80002308 <scheduler+0x9a>

000000008000234a <sched>:
{
    8000234a:	7179                	addi	sp,sp,-48
    8000234c:	f406                	sd	ra,40(sp)
    8000234e:	f022                	sd	s0,32(sp)
    80002350:	ec26                	sd	s1,24(sp)
    80002352:	e84a                	sd	s2,16(sp)
    80002354:	e44e                	sd	s3,8(sp)
    80002356:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002358:	00000097          	auipc	ra,0x0
    8000235c:	800080e7          	jalr	-2048(ra) # 80001b58 <myproc>
    80002360:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	886080e7          	jalr	-1914(ra) # 80000be8 <holding>
    8000236a:	cd25                	beqz	a0,800023e2 <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000236c:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000236e:	2781                	sext.w	a5,a5
    80002370:	079e                	slli	a5,a5,0x7
    80002372:	0000f717          	auipc	a4,0xf
    80002376:	5de70713          	addi	a4,a4,1502 # 80011950 <pid_lock>
    8000237a:	97ba                	add	a5,a5,a4
    8000237c:	0907a703          	lw	a4,144(a5)
    80002380:	4785                	li	a5,1
    80002382:	06f71863          	bne	a4,a5,800023f2 <sched+0xa8>
  if(p->state == RUNNING)
    80002386:	01892703          	lw	a4,24(s2)
    8000238a:	478d                	li	a5,3
    8000238c:	06f70b63          	beq	a4,a5,80002402 <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002390:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002394:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002396:	efb5                	bnez	a5,80002412 <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002398:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000239a:	0000f497          	auipc	s1,0xf
    8000239e:	5b648493          	addi	s1,s1,1462 # 80011950 <pid_lock>
    800023a2:	2781                	sext.w	a5,a5
    800023a4:	079e                	slli	a5,a5,0x7
    800023a6:	97a6                	add	a5,a5,s1
    800023a8:	0947a983          	lw	s3,148(a5)
    800023ac:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800023ae:	2781                	sext.w	a5,a5
    800023b0:	079e                	slli	a5,a5,0x7
    800023b2:	0000f597          	auipc	a1,0xf
    800023b6:	5be58593          	addi	a1,a1,1470 # 80011970 <cpus+0x8>
    800023ba:	95be                	add	a1,a1,a5
    800023bc:	06090513          	addi	a0,s2,96
    800023c0:	00000097          	auipc	ra,0x0
    800023c4:	568080e7          	jalr	1384(ra) # 80002928 <swtch>
    800023c8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023ca:	2781                	sext.w	a5,a5
    800023cc:	079e                	slli	a5,a5,0x7
    800023ce:	97a6                	add	a5,a5,s1
    800023d0:	0937aa23          	sw	s3,148(a5)
}
    800023d4:	70a2                	ld	ra,40(sp)
    800023d6:	7402                	ld	s0,32(sp)
    800023d8:	64e2                	ld	s1,24(sp)
    800023da:	6942                	ld	s2,16(sp)
    800023dc:	69a2                	ld	s3,8(sp)
    800023de:	6145                	addi	sp,sp,48
    800023e0:	8082                	ret
    panic("sched p->lock");
    800023e2:	00006517          	auipc	a0,0x6
    800023e6:	f4e50513          	addi	a0,a0,-178 # 80008330 <states.1760+0x60>
    800023ea:	ffffe097          	auipc	ra,0xffffe
    800023ee:	18a080e7          	jalr	394(ra) # 80000574 <panic>
    panic("sched locks");
    800023f2:	00006517          	auipc	a0,0x6
    800023f6:	f4e50513          	addi	a0,a0,-178 # 80008340 <states.1760+0x70>
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	17a080e7          	jalr	378(ra) # 80000574 <panic>
    panic("sched running");
    80002402:	00006517          	auipc	a0,0x6
    80002406:	f4e50513          	addi	a0,a0,-178 # 80008350 <states.1760+0x80>
    8000240a:	ffffe097          	auipc	ra,0xffffe
    8000240e:	16a080e7          	jalr	362(ra) # 80000574 <panic>
    panic("sched interruptible");
    80002412:	00006517          	auipc	a0,0x6
    80002416:	f4e50513          	addi	a0,a0,-178 # 80008360 <states.1760+0x90>
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	15a080e7          	jalr	346(ra) # 80000574 <panic>

0000000080002422 <exit>:
{
    80002422:	7179                	addi	sp,sp,-48
    80002424:	f406                	sd	ra,40(sp)
    80002426:	f022                	sd	s0,32(sp)
    80002428:	ec26                	sd	s1,24(sp)
    8000242a:	e84a                	sd	s2,16(sp)
    8000242c:	e44e                	sd	s3,8(sp)
    8000242e:	e052                	sd	s4,0(sp)
    80002430:	1800                	addi	s0,sp,48
    80002432:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	724080e7          	jalr	1828(ra) # 80001b58 <myproc>
    8000243c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000243e:	00007797          	auipc	a5,0x7
    80002442:	bda78793          	addi	a5,a5,-1062 # 80009018 <initproc>
    80002446:	639c                	ld	a5,0(a5)
    80002448:	0d050493          	addi	s1,a0,208
    8000244c:	15050913          	addi	s2,a0,336
    80002450:	02a79363          	bne	a5,a0,80002476 <exit+0x54>
    panic("init exiting");
    80002454:	00006517          	auipc	a0,0x6
    80002458:	f2450513          	addi	a0,a0,-220 # 80008378 <states.1760+0xa8>
    8000245c:	ffffe097          	auipc	ra,0xffffe
    80002460:	118080e7          	jalr	280(ra) # 80000574 <panic>
      fileclose(f);
    80002464:	00002097          	auipc	ra,0x2
    80002468:	446080e7          	jalr	1094(ra) # 800048aa <fileclose>
      p->ofile[fd] = 0;
    8000246c:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002470:	04a1                	addi	s1,s1,8
    80002472:	01248563          	beq	s1,s2,8000247c <exit+0x5a>
    if(p->ofile[fd]){
    80002476:	6088                	ld	a0,0(s1)
    80002478:	f575                	bnez	a0,80002464 <exit+0x42>
    8000247a:	bfdd                	j	80002470 <exit+0x4e>
  begin_op();
    8000247c:	00002097          	auipc	ra,0x2
    80002480:	f2c080e7          	jalr	-212(ra) # 800043a8 <begin_op>
  iput(p->cwd);
    80002484:	1509b503          	ld	a0,336(s3)
    80002488:	00001097          	auipc	ra,0x1
    8000248c:	714080e7          	jalr	1812(ra) # 80003b9c <iput>
  end_op();
    80002490:	00002097          	auipc	ra,0x2
    80002494:	f98080e7          	jalr	-104(ra) # 80004428 <end_op>
  p->cwd = 0;
    80002498:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000249c:	00007497          	auipc	s1,0x7
    800024a0:	b7c48493          	addi	s1,s1,-1156 # 80009018 <initproc>
    800024a4:	6088                	ld	a0,0(s1)
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	7bc080e7          	jalr	1980(ra) # 80000c62 <acquire>
  wakeup1(initproc);
    800024ae:	6088                	ld	a0,0(s1)
    800024b0:	fffff097          	auipc	ra,0xfffff
    800024b4:	5d8080e7          	jalr	1496(ra) # 80001a88 <wakeup1>
  release(&initproc->lock);
    800024b8:	6088                	ld	a0,0(s1)
    800024ba:	fffff097          	auipc	ra,0xfffff
    800024be:	85c080e7          	jalr	-1956(ra) # 80000d16 <release>
  acquire(&p->lock);
    800024c2:	854e                	mv	a0,s3
    800024c4:	ffffe097          	auipc	ra,0xffffe
    800024c8:	79e080e7          	jalr	1950(ra) # 80000c62 <acquire>
  struct proc *original_parent = p->parent;
    800024cc:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800024d0:	854e                	mv	a0,s3
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	844080e7          	jalr	-1980(ra) # 80000d16 <release>
  acquire(&original_parent->lock);
    800024da:	8526                	mv	a0,s1
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	786080e7          	jalr	1926(ra) # 80000c62 <acquire>
  acquire(&p->lock);
    800024e4:	854e                	mv	a0,s3
    800024e6:	ffffe097          	auipc	ra,0xffffe
    800024ea:	77c080e7          	jalr	1916(ra) # 80000c62 <acquire>
  reparent(p);
    800024ee:	854e                	mv	a0,s3
    800024f0:	00000097          	auipc	ra,0x0
    800024f4:	d18080e7          	jalr	-744(ra) # 80002208 <reparent>
  wakeup1(original_parent);
    800024f8:	8526                	mv	a0,s1
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	58e080e7          	jalr	1422(ra) # 80001a88 <wakeup1>
  p->xstate = status;
    80002502:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002506:	4791                	li	a5,4
    80002508:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000250c:	8526                	mv	a0,s1
    8000250e:	fffff097          	auipc	ra,0xfffff
    80002512:	808080e7          	jalr	-2040(ra) # 80000d16 <release>
  sched();
    80002516:	00000097          	auipc	ra,0x0
    8000251a:	e34080e7          	jalr	-460(ra) # 8000234a <sched>
  panic("zombie exit");
    8000251e:	00006517          	auipc	a0,0x6
    80002522:	e6a50513          	addi	a0,a0,-406 # 80008388 <states.1760+0xb8>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	04e080e7          	jalr	78(ra) # 80000574 <panic>

000000008000252e <yield>:
{
    8000252e:	1101                	addi	sp,sp,-32
    80002530:	ec06                	sd	ra,24(sp)
    80002532:	e822                	sd	s0,16(sp)
    80002534:	e426                	sd	s1,8(sp)
    80002536:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002538:	fffff097          	auipc	ra,0xfffff
    8000253c:	620080e7          	jalr	1568(ra) # 80001b58 <myproc>
    80002540:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	720080e7          	jalr	1824(ra) # 80000c62 <acquire>
  p->state = RUNNABLE;
    8000254a:	4789                	li	a5,2
    8000254c:	cc9c                	sw	a5,24(s1)
  sched();
    8000254e:	00000097          	auipc	ra,0x0
    80002552:	dfc080e7          	jalr	-516(ra) # 8000234a <sched>
  release(&p->lock);
    80002556:	8526                	mv	a0,s1
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	7be080e7          	jalr	1982(ra) # 80000d16 <release>
}
    80002560:	60e2                	ld	ra,24(sp)
    80002562:	6442                	ld	s0,16(sp)
    80002564:	64a2                	ld	s1,8(sp)
    80002566:	6105                	addi	sp,sp,32
    80002568:	8082                	ret

000000008000256a <sleep>:
{
    8000256a:	7179                	addi	sp,sp,-48
    8000256c:	f406                	sd	ra,40(sp)
    8000256e:	f022                	sd	s0,32(sp)
    80002570:	ec26                	sd	s1,24(sp)
    80002572:	e84a                	sd	s2,16(sp)
    80002574:	e44e                	sd	s3,8(sp)
    80002576:	1800                	addi	s0,sp,48
    80002578:	89aa                	mv	s3,a0
    8000257a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000257c:	fffff097          	auipc	ra,0xfffff
    80002580:	5dc080e7          	jalr	1500(ra) # 80001b58 <myproc>
    80002584:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002586:	05250663          	beq	a0,s2,800025d2 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	6d8080e7          	jalr	1752(ra) # 80000c62 <acquire>
    release(lk);
    80002592:	854a                	mv	a0,s2
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	782080e7          	jalr	1922(ra) # 80000d16 <release>
  p->chan = chan;
    8000259c:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800025a0:	4785                	li	a5,1
    800025a2:	cc9c                	sw	a5,24(s1)
  sched();
    800025a4:	00000097          	auipc	ra,0x0
    800025a8:	da6080e7          	jalr	-602(ra) # 8000234a <sched>
  p->chan = 0;
    800025ac:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800025b0:	8526                	mv	a0,s1
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	764080e7          	jalr	1892(ra) # 80000d16 <release>
    acquire(lk);
    800025ba:	854a                	mv	a0,s2
    800025bc:	ffffe097          	auipc	ra,0xffffe
    800025c0:	6a6080e7          	jalr	1702(ra) # 80000c62 <acquire>
}
    800025c4:	70a2                	ld	ra,40(sp)
    800025c6:	7402                	ld	s0,32(sp)
    800025c8:	64e2                	ld	s1,24(sp)
    800025ca:	6942                	ld	s2,16(sp)
    800025cc:	69a2                	ld	s3,8(sp)
    800025ce:	6145                	addi	sp,sp,48
    800025d0:	8082                	ret
  p->chan = chan;
    800025d2:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800025d6:	4785                	li	a5,1
    800025d8:	cd1c                	sw	a5,24(a0)
  sched();
    800025da:	00000097          	auipc	ra,0x0
    800025de:	d70080e7          	jalr	-656(ra) # 8000234a <sched>
  p->chan = 0;
    800025e2:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800025e6:	bff9                	j	800025c4 <sleep+0x5a>

00000000800025e8 <wait>:
{
    800025e8:	715d                	addi	sp,sp,-80
    800025ea:	e486                	sd	ra,72(sp)
    800025ec:	e0a2                	sd	s0,64(sp)
    800025ee:	fc26                	sd	s1,56(sp)
    800025f0:	f84a                	sd	s2,48(sp)
    800025f2:	f44e                	sd	s3,40(sp)
    800025f4:	f052                	sd	s4,32(sp)
    800025f6:	ec56                	sd	s5,24(sp)
    800025f8:	e85a                	sd	s6,16(sp)
    800025fa:	e45e                	sd	s7,8(sp)
    800025fc:	e062                	sd	s8,0(sp)
    800025fe:	0880                	addi	s0,sp,80
    80002600:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002602:	fffff097          	auipc	ra,0xfffff
    80002606:	556080e7          	jalr	1366(ra) # 80001b58 <myproc>
    8000260a:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000260c:	8c2a                	mv	s8,a0
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	654080e7          	jalr	1620(ra) # 80000c62 <acquire>
    havekids = 0;
    80002616:	4b01                	li	s6,0
        if(np->state == ZOMBIE){
    80002618:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000261a:	00015997          	auipc	s3,0x15
    8000261e:	34e98993          	addi	s3,s3,846 # 80017968 <tickslock>
        havekids = 1;
    80002622:	4a85                	li	s5,1
    havekids = 0;
    80002624:	875a                	mv	a4,s6
    for(np = proc; np < &proc[NPROC]; np++){
    80002626:	0000f497          	auipc	s1,0xf
    8000262a:	74248493          	addi	s1,s1,1858 # 80011d68 <proc>
    8000262e:	a08d                	j	80002690 <wait+0xa8>
          pid = np->pid;
    80002630:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002634:	000b8e63          	beqz	s7,80002650 <wait+0x68>
    80002638:	4691                	li	a3,4
    8000263a:	03448613          	addi	a2,s1,52
    8000263e:	85de                	mv	a1,s7
    80002640:	05093503          	ld	a0,80(s2)
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	118080e7          	jalr	280(ra) # 8000175c <copyout>
    8000264c:	02054263          	bltz	a0,80002670 <wait+0x88>
          freeproc(np);
    80002650:	8526                	mv	a0,s1
    80002652:	fffff097          	auipc	ra,0xfffff
    80002656:	780080e7          	jalr	1920(ra) # 80001dd2 <freeproc>
          release(&np->lock);
    8000265a:	8526                	mv	a0,s1
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	6ba080e7          	jalr	1722(ra) # 80000d16 <release>
          release(&p->lock);
    80002664:	854a                	mv	a0,s2
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	6b0080e7          	jalr	1712(ra) # 80000d16 <release>
          return pid;
    8000266e:	a8a9                	j	800026c8 <wait+0xe0>
            release(&np->lock);
    80002670:	8526                	mv	a0,s1
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	6a4080e7          	jalr	1700(ra) # 80000d16 <release>
            release(&p->lock);
    8000267a:	854a                	mv	a0,s2
    8000267c:	ffffe097          	auipc	ra,0xffffe
    80002680:	69a080e7          	jalr	1690(ra) # 80000d16 <release>
            return -1;
    80002684:	59fd                	li	s3,-1
    80002686:	a089                	j	800026c8 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002688:	17048493          	addi	s1,s1,368
    8000268c:	03348463          	beq	s1,s3,800026b4 <wait+0xcc>
      if(np->parent == p){
    80002690:	709c                	ld	a5,32(s1)
    80002692:	ff279be3          	bne	a5,s2,80002688 <wait+0xa0>
        acquire(&np->lock);
    80002696:	8526                	mv	a0,s1
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	5ca080e7          	jalr	1482(ra) # 80000c62 <acquire>
        if(np->state == ZOMBIE){
    800026a0:	4c9c                	lw	a5,24(s1)
    800026a2:	f94787e3          	beq	a5,s4,80002630 <wait+0x48>
        release(&np->lock);
    800026a6:	8526                	mv	a0,s1
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	66e080e7          	jalr	1646(ra) # 80000d16 <release>
        havekids = 1;
    800026b0:	8756                	mv	a4,s5
    800026b2:	bfd9                	j	80002688 <wait+0xa0>
    if(!havekids || p->killed){
    800026b4:	c701                	beqz	a4,800026bc <wait+0xd4>
    800026b6:	03092783          	lw	a5,48(s2)
    800026ba:	c785                	beqz	a5,800026e2 <wait+0xfa>
      release(&p->lock);
    800026bc:	854a                	mv	a0,s2
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	658080e7          	jalr	1624(ra) # 80000d16 <release>
      return -1;
    800026c6:	59fd                	li	s3,-1
}
    800026c8:	854e                	mv	a0,s3
    800026ca:	60a6                	ld	ra,72(sp)
    800026cc:	6406                	ld	s0,64(sp)
    800026ce:	74e2                	ld	s1,56(sp)
    800026d0:	7942                	ld	s2,48(sp)
    800026d2:	79a2                	ld	s3,40(sp)
    800026d4:	7a02                	ld	s4,32(sp)
    800026d6:	6ae2                	ld	s5,24(sp)
    800026d8:	6b42                	ld	s6,16(sp)
    800026da:	6ba2                	ld	s7,8(sp)
    800026dc:	6c02                	ld	s8,0(sp)
    800026de:	6161                	addi	sp,sp,80
    800026e0:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800026e2:	85e2                	mv	a1,s8
    800026e4:	854a                	mv	a0,s2
    800026e6:	00000097          	auipc	ra,0x0
    800026ea:	e84080e7          	jalr	-380(ra) # 8000256a <sleep>
    havekids = 0;
    800026ee:	bf1d                	j	80002624 <wait+0x3c>

00000000800026f0 <wakeup>:
{
    800026f0:	7139                	addi	sp,sp,-64
    800026f2:	fc06                	sd	ra,56(sp)
    800026f4:	f822                	sd	s0,48(sp)
    800026f6:	f426                	sd	s1,40(sp)
    800026f8:	f04a                	sd	s2,32(sp)
    800026fa:	ec4e                	sd	s3,24(sp)
    800026fc:	e852                	sd	s4,16(sp)
    800026fe:	e456                	sd	s5,8(sp)
    80002700:	0080                	addi	s0,sp,64
    80002702:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002704:	0000f497          	auipc	s1,0xf
    80002708:	66448493          	addi	s1,s1,1636 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000270c:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000270e:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002710:	00015917          	auipc	s2,0x15
    80002714:	25890913          	addi	s2,s2,600 # 80017968 <tickslock>
    80002718:	a821                	j	80002730 <wakeup+0x40>
      p->state = RUNNABLE;
    8000271a:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000271e:	8526                	mv	a0,s1
    80002720:	ffffe097          	auipc	ra,0xffffe
    80002724:	5f6080e7          	jalr	1526(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002728:	17048493          	addi	s1,s1,368
    8000272c:	01248e63          	beq	s1,s2,80002748 <wakeup+0x58>
    acquire(&p->lock);
    80002730:	8526                	mv	a0,s1
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	530080e7          	jalr	1328(ra) # 80000c62 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000273a:	4c9c                	lw	a5,24(s1)
    8000273c:	ff3791e3          	bne	a5,s3,8000271e <wakeup+0x2e>
    80002740:	749c                	ld	a5,40(s1)
    80002742:	fd479ee3          	bne	a5,s4,8000271e <wakeup+0x2e>
    80002746:	bfd1                	j	8000271a <wakeup+0x2a>
}
    80002748:	70e2                	ld	ra,56(sp)
    8000274a:	7442                	ld	s0,48(sp)
    8000274c:	74a2                	ld	s1,40(sp)
    8000274e:	7902                	ld	s2,32(sp)
    80002750:	69e2                	ld	s3,24(sp)
    80002752:	6a42                	ld	s4,16(sp)
    80002754:	6aa2                	ld	s5,8(sp)
    80002756:	6121                	addi	sp,sp,64
    80002758:	8082                	ret

000000008000275a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000275a:	7179                	addi	sp,sp,-48
    8000275c:	f406                	sd	ra,40(sp)
    8000275e:	f022                	sd	s0,32(sp)
    80002760:	ec26                	sd	s1,24(sp)
    80002762:	e84a                	sd	s2,16(sp)
    80002764:	e44e                	sd	s3,8(sp)
    80002766:	1800                	addi	s0,sp,48
    80002768:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000276a:	0000f497          	auipc	s1,0xf
    8000276e:	5fe48493          	addi	s1,s1,1534 # 80011d68 <proc>
    80002772:	00015997          	auipc	s3,0x15
    80002776:	1f698993          	addi	s3,s3,502 # 80017968 <tickslock>
    acquire(&p->lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	4e6080e7          	jalr	1254(ra) # 80000c62 <acquire>
    if(p->pid == pid){
    80002784:	5c9c                	lw	a5,56(s1)
    80002786:	01278d63          	beq	a5,s2,800027a0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000278a:	8526                	mv	a0,s1
    8000278c:	ffffe097          	auipc	ra,0xffffe
    80002790:	58a080e7          	jalr	1418(ra) # 80000d16 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002794:	17048493          	addi	s1,s1,368
    80002798:	ff3491e3          	bne	s1,s3,8000277a <kill+0x20>
  }
  return -1;
    8000279c:	557d                	li	a0,-1
    8000279e:	a829                	j	800027b8 <kill+0x5e>
      p->killed = 1;
    800027a0:	4785                	li	a5,1
    800027a2:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800027a4:	4c98                	lw	a4,24(s1)
    800027a6:	4785                	li	a5,1
    800027a8:	00f70f63          	beq	a4,a5,800027c6 <kill+0x6c>
      release(&p->lock);
    800027ac:	8526                	mv	a0,s1
    800027ae:	ffffe097          	auipc	ra,0xffffe
    800027b2:	568080e7          	jalr	1384(ra) # 80000d16 <release>
      return 0;
    800027b6:	4501                	li	a0,0
}
    800027b8:	70a2                	ld	ra,40(sp)
    800027ba:	7402                	ld	s0,32(sp)
    800027bc:	64e2                	ld	s1,24(sp)
    800027be:	6942                	ld	s2,16(sp)
    800027c0:	69a2                	ld	s3,8(sp)
    800027c2:	6145                	addi	sp,sp,48
    800027c4:	8082                	ret
        p->state = RUNNABLE;
    800027c6:	4789                	li	a5,2
    800027c8:	cc9c                	sw	a5,24(s1)
    800027ca:	b7cd                	j	800027ac <kill+0x52>

00000000800027cc <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027cc:	7179                	addi	sp,sp,-48
    800027ce:	f406                	sd	ra,40(sp)
    800027d0:	f022                	sd	s0,32(sp)
    800027d2:	ec26                	sd	s1,24(sp)
    800027d4:	e84a                	sd	s2,16(sp)
    800027d6:	e44e                	sd	s3,8(sp)
    800027d8:	e052                	sd	s4,0(sp)
    800027da:	1800                	addi	s0,sp,48
    800027dc:	84aa                	mv	s1,a0
    800027de:	892e                	mv	s2,a1
    800027e0:	89b2                	mv	s3,a2
    800027e2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027e4:	fffff097          	auipc	ra,0xfffff
    800027e8:	374080e7          	jalr	884(ra) # 80001b58 <myproc>
  if(user_dst){
    800027ec:	c08d                	beqz	s1,8000280e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800027ee:	86d2                	mv	a3,s4
    800027f0:	864e                	mv	a2,s3
    800027f2:	85ca                	mv	a1,s2
    800027f4:	6928                	ld	a0,80(a0)
    800027f6:	fffff097          	auipc	ra,0xfffff
    800027fa:	f66080e7          	jalr	-154(ra) # 8000175c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800027fe:	70a2                	ld	ra,40(sp)
    80002800:	7402                	ld	s0,32(sp)
    80002802:	64e2                	ld	s1,24(sp)
    80002804:	6942                	ld	s2,16(sp)
    80002806:	69a2                	ld	s3,8(sp)
    80002808:	6a02                	ld	s4,0(sp)
    8000280a:	6145                	addi	sp,sp,48
    8000280c:	8082                	ret
    memmove((char *)dst, src, len);
    8000280e:	000a061b          	sext.w	a2,s4
    80002812:	85ce                	mv	a1,s3
    80002814:	854a                	mv	a0,s2
    80002816:	ffffe097          	auipc	ra,0xffffe
    8000281a:	5b4080e7          	jalr	1460(ra) # 80000dca <memmove>
    return 0;
    8000281e:	8526                	mv	a0,s1
    80002820:	bff9                	j	800027fe <either_copyout+0x32>

0000000080002822 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002822:	7179                	addi	sp,sp,-48
    80002824:	f406                	sd	ra,40(sp)
    80002826:	f022                	sd	s0,32(sp)
    80002828:	ec26                	sd	s1,24(sp)
    8000282a:	e84a                	sd	s2,16(sp)
    8000282c:	e44e                	sd	s3,8(sp)
    8000282e:	e052                	sd	s4,0(sp)
    80002830:	1800                	addi	s0,sp,48
    80002832:	892a                	mv	s2,a0
    80002834:	84ae                	mv	s1,a1
    80002836:	89b2                	mv	s3,a2
    80002838:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000283a:	fffff097          	auipc	ra,0xfffff
    8000283e:	31e080e7          	jalr	798(ra) # 80001b58 <myproc>
  if(user_src){
    80002842:	c08d                	beqz	s1,80002864 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002844:	86d2                	mv	a3,s4
    80002846:	864e                	mv	a2,s3
    80002848:	85ca                	mv	a1,s2
    8000284a:	6928                	ld	a0,80(a0)
    8000284c:	fffff097          	auipc	ra,0xfffff
    80002850:	f9c080e7          	jalr	-100(ra) # 800017e8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002854:	70a2                	ld	ra,40(sp)
    80002856:	7402                	ld	s0,32(sp)
    80002858:	64e2                	ld	s1,24(sp)
    8000285a:	6942                	ld	s2,16(sp)
    8000285c:	69a2                	ld	s3,8(sp)
    8000285e:	6a02                	ld	s4,0(sp)
    80002860:	6145                	addi	sp,sp,48
    80002862:	8082                	ret
    memmove(dst, (char*)src, len);
    80002864:	000a061b          	sext.w	a2,s4
    80002868:	85ce                	mv	a1,s3
    8000286a:	854a                	mv	a0,s2
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	55e080e7          	jalr	1374(ra) # 80000dca <memmove>
    return 0;
    80002874:	8526                	mv	a0,s1
    80002876:	bff9                	j	80002854 <either_copyin+0x32>

0000000080002878 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002878:	715d                	addi	sp,sp,-80
    8000287a:	e486                	sd	ra,72(sp)
    8000287c:	e0a2                	sd	s0,64(sp)
    8000287e:	fc26                	sd	s1,56(sp)
    80002880:	f84a                	sd	s2,48(sp)
    80002882:	f44e                	sd	s3,40(sp)
    80002884:	f052                	sd	s4,32(sp)
    80002886:	ec56                	sd	s5,24(sp)
    80002888:	e85a                	sd	s6,16(sp)
    8000288a:	e45e                	sd	s7,8(sp)
    8000288c:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000288e:	00006517          	auipc	a0,0x6
    80002892:	83a50513          	addi	a0,a0,-1990 # 800080c8 <digits+0xb0>
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	d28080e7          	jalr	-728(ra) # 800005be <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000289e:	0000f497          	auipc	s1,0xf
    800028a2:	62248493          	addi	s1,s1,1570 # 80011ec0 <proc+0x158>
    800028a6:	00015917          	auipc	s2,0x15
    800028aa:	21a90913          	addi	s2,s2,538 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ae:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800028b0:	00006997          	auipc	s3,0x6
    800028b4:	ae898993          	addi	s3,s3,-1304 # 80008398 <states.1760+0xc8>
    printf("%d %s %s", p->pid, state, p->name);
    800028b8:	00006a97          	auipc	s5,0x6
    800028bc:	ae8a8a93          	addi	s5,s5,-1304 # 800083a0 <states.1760+0xd0>
    printf("\n");
    800028c0:	00006a17          	auipc	s4,0x6
    800028c4:	808a0a13          	addi	s4,s4,-2040 # 800080c8 <digits+0xb0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028c8:	00006b97          	auipc	s7,0x6
    800028cc:	a08b8b93          	addi	s7,s7,-1528 # 800082d0 <states.1760>
    800028d0:	a015                	j	800028f4 <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    800028d2:	86ba                	mv	a3,a4
    800028d4:	ee072583          	lw	a1,-288(a4)
    800028d8:	8556                	mv	a0,s5
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	ce4080e7          	jalr	-796(ra) # 800005be <printf>
    printf("\n");
    800028e2:	8552                	mv	a0,s4
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	cda080e7          	jalr	-806(ra) # 800005be <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028ec:	17048493          	addi	s1,s1,368
    800028f0:	03248163          	beq	s1,s2,80002912 <procdump+0x9a>
    if(p->state == UNUSED)
    800028f4:	8726                	mv	a4,s1
    800028f6:	ec04a783          	lw	a5,-320(s1)
    800028fa:	dbed                	beqz	a5,800028ec <procdump+0x74>
      state = "???";
    800028fc:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028fe:	fcfb6ae3          	bltu	s6,a5,800028d2 <procdump+0x5a>
    80002902:	1782                	slli	a5,a5,0x20
    80002904:	9381                	srli	a5,a5,0x20
    80002906:	078e                	slli	a5,a5,0x3
    80002908:	97de                	add	a5,a5,s7
    8000290a:	6390                	ld	a2,0(a5)
    8000290c:	f279                	bnez	a2,800028d2 <procdump+0x5a>
      state = "???";
    8000290e:	864e                	mv	a2,s3
    80002910:	b7c9                	j	800028d2 <procdump+0x5a>
  }
}
    80002912:	60a6                	ld	ra,72(sp)
    80002914:	6406                	ld	s0,64(sp)
    80002916:	74e2                	ld	s1,56(sp)
    80002918:	7942                	ld	s2,48(sp)
    8000291a:	79a2                	ld	s3,40(sp)
    8000291c:	7a02                	ld	s4,32(sp)
    8000291e:	6ae2                	ld	s5,24(sp)
    80002920:	6b42                	ld	s6,16(sp)
    80002922:	6ba2                	ld	s7,8(sp)
    80002924:	6161                	addi	sp,sp,80
    80002926:	8082                	ret

0000000080002928 <swtch>:
    80002928:	00153023          	sd	ra,0(a0)
    8000292c:	00253423          	sd	sp,8(a0)
    80002930:	e900                	sd	s0,16(a0)
    80002932:	ed04                	sd	s1,24(a0)
    80002934:	03253023          	sd	s2,32(a0)
    80002938:	03353423          	sd	s3,40(a0)
    8000293c:	03453823          	sd	s4,48(a0)
    80002940:	03553c23          	sd	s5,56(a0)
    80002944:	05653023          	sd	s6,64(a0)
    80002948:	05753423          	sd	s7,72(a0)
    8000294c:	05853823          	sd	s8,80(a0)
    80002950:	05953c23          	sd	s9,88(a0)
    80002954:	07a53023          	sd	s10,96(a0)
    80002958:	07b53423          	sd	s11,104(a0)
    8000295c:	0005b083          	ld	ra,0(a1)
    80002960:	0085b103          	ld	sp,8(a1)
    80002964:	6980                	ld	s0,16(a1)
    80002966:	6d84                	ld	s1,24(a1)
    80002968:	0205b903          	ld	s2,32(a1)
    8000296c:	0285b983          	ld	s3,40(a1)
    80002970:	0305ba03          	ld	s4,48(a1)
    80002974:	0385ba83          	ld	s5,56(a1)
    80002978:	0405bb03          	ld	s6,64(a1)
    8000297c:	0485bb83          	ld	s7,72(a1)
    80002980:	0505bc03          	ld	s8,80(a1)
    80002984:	0585bc83          	ld	s9,88(a1)
    80002988:	0605bd03          	ld	s10,96(a1)
    8000298c:	0685bd83          	ld	s11,104(a1)
    80002990:	8082                	ret

0000000080002992 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002992:	1141                	addi	sp,sp,-16
    80002994:	e406                	sd	ra,8(sp)
    80002996:	e022                	sd	s0,0(sp)
    80002998:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000299a:	00006597          	auipc	a1,0x6
    8000299e:	a3e58593          	addi	a1,a1,-1474 # 800083d8 <states.1760+0x108>
    800029a2:	00015517          	auipc	a0,0x15
    800029a6:	fc650513          	addi	a0,a0,-58 # 80017968 <tickslock>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	228080e7          	jalr	552(ra) # 80000bd2 <initlock>
}
    800029b2:	60a2                	ld	ra,8(sp)
    800029b4:	6402                	ld	s0,0(sp)
    800029b6:	0141                	addi	sp,sp,16
    800029b8:	8082                	ret

00000000800029ba <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029ba:	1141                	addi	sp,sp,-16
    800029bc:	e422                	sd	s0,8(sp)
    800029be:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029c0:	00003797          	auipc	a5,0x3
    800029c4:	5d078793          	addi	a5,a5,1488 # 80005f90 <kernelvec>
    800029c8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029cc:	6422                	ld	s0,8(sp)
    800029ce:	0141                	addi	sp,sp,16
    800029d0:	8082                	ret

00000000800029d2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029d2:	1141                	addi	sp,sp,-16
    800029d4:	e406                	sd	ra,8(sp)
    800029d6:	e022                	sd	s0,0(sp)
    800029d8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029da:	fffff097          	auipc	ra,0xfffff
    800029de:	17e080e7          	jalr	382(ra) # 80001b58 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029e6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800029ec:	00004617          	auipc	a2,0x4
    800029f0:	61460613          	addi	a2,a2,1556 # 80007000 <_trampoline>
    800029f4:	00004697          	auipc	a3,0x4
    800029f8:	60c68693          	addi	a3,a3,1548 # 80007000 <_trampoline>
    800029fc:	8e91                	sub	a3,a3,a2
    800029fe:	040007b7          	lui	a5,0x4000
    80002a02:	17fd                	addi	a5,a5,-1
    80002a04:	07b2                	slli	a5,a5,0xc
    80002a06:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a08:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a0c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a0e:	180026f3          	csrr	a3,satp
    80002a12:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a14:	6d38                	ld	a4,88(a0)
    80002a16:	6134                	ld	a3,64(a0)
    80002a18:	6585                	lui	a1,0x1
    80002a1a:	96ae                	add	a3,a3,a1
    80002a1c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a1e:	6d38                	ld	a4,88(a0)
    80002a20:	00000697          	auipc	a3,0x0
    80002a24:	13868693          	addi	a3,a3,312 # 80002b58 <usertrap>
    80002a28:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a2a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a2c:	8692                	mv	a3,tp
    80002a2e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a30:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a34:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a38:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a3c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a40:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a42:	6f18                	ld	a4,24(a4)
    80002a44:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a48:	692c                	ld	a1,80(a0)
    80002a4a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a4c:	00004717          	auipc	a4,0x4
    80002a50:	64470713          	addi	a4,a4,1604 # 80007090 <userret>
    80002a54:	8f11                	sub	a4,a4,a2
    80002a56:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a58:	577d                	li	a4,-1
    80002a5a:	177e                	slli	a4,a4,0x3f
    80002a5c:	8dd9                	or	a1,a1,a4
    80002a5e:	02000537          	lui	a0,0x2000
    80002a62:	157d                	addi	a0,a0,-1
    80002a64:	0536                	slli	a0,a0,0xd
    80002a66:	9782                	jalr	a5
}
    80002a68:	60a2                	ld	ra,8(sp)
    80002a6a:	6402                	ld	s0,0(sp)
    80002a6c:	0141                	addi	sp,sp,16
    80002a6e:	8082                	ret

0000000080002a70 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a70:	1101                	addi	sp,sp,-32
    80002a72:	ec06                	sd	ra,24(sp)
    80002a74:	e822                	sd	s0,16(sp)
    80002a76:	e426                	sd	s1,8(sp)
    80002a78:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a7a:	00015497          	auipc	s1,0x15
    80002a7e:	eee48493          	addi	s1,s1,-274 # 80017968 <tickslock>
    80002a82:	8526                	mv	a0,s1
    80002a84:	ffffe097          	auipc	ra,0xffffe
    80002a88:	1de080e7          	jalr	478(ra) # 80000c62 <acquire>
  ticks++;
    80002a8c:	00006517          	auipc	a0,0x6
    80002a90:	59450513          	addi	a0,a0,1428 # 80009020 <ticks>
    80002a94:	411c                	lw	a5,0(a0)
    80002a96:	2785                	addiw	a5,a5,1
    80002a98:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002a9a:	00000097          	auipc	ra,0x0
    80002a9e:	c56080e7          	jalr	-938(ra) # 800026f0 <wakeup>
  release(&tickslock);
    80002aa2:	8526                	mv	a0,s1
    80002aa4:	ffffe097          	auipc	ra,0xffffe
    80002aa8:	272080e7          	jalr	626(ra) # 80000d16 <release>
}
    80002aac:	60e2                	ld	ra,24(sp)
    80002aae:	6442                	ld	s0,16(sp)
    80002ab0:	64a2                	ld	s1,8(sp)
    80002ab2:	6105                	addi	sp,sp,32
    80002ab4:	8082                	ret

0000000080002ab6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ab6:	1101                	addi	sp,sp,-32
    80002ab8:	ec06                	sd	ra,24(sp)
    80002aba:	e822                	sd	s0,16(sp)
    80002abc:	e426                	sd	s1,8(sp)
    80002abe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002ac4:	00074d63          	bltz	a4,80002ade <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002ac8:	57fd                	li	a5,-1
    80002aca:	17fe                	slli	a5,a5,0x3f
    80002acc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ace:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002ad0:	06f70363          	beq	a4,a5,80002b36 <devintr+0x80>
  }
}
    80002ad4:	60e2                	ld	ra,24(sp)
    80002ad6:	6442                	ld	s0,16(sp)
    80002ad8:	64a2                	ld	s1,8(sp)
    80002ada:	6105                	addi	sp,sp,32
    80002adc:	8082                	ret
     (scause & 0xff) == 9){
    80002ade:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002ae2:	46a5                	li	a3,9
    80002ae4:	fed792e3          	bne	a5,a3,80002ac8 <devintr+0x12>
    int irq = plic_claim();
    80002ae8:	00003097          	auipc	ra,0x3
    80002aec:	5b0080e7          	jalr	1456(ra) # 80006098 <plic_claim>
    80002af0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002af2:	47a9                	li	a5,10
    80002af4:	02f50763          	beq	a0,a5,80002b22 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002af8:	4785                	li	a5,1
    80002afa:	02f50963          	beq	a0,a5,80002b2c <devintr+0x76>
    return 1;
    80002afe:	4505                	li	a0,1
    } else if(irq){
    80002b00:	d8f1                	beqz	s1,80002ad4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b02:	85a6                	mv	a1,s1
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	8dc50513          	addi	a0,a0,-1828 # 800083e0 <states.1760+0x110>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	ab2080e7          	jalr	-1358(ra) # 800005be <printf>
      plic_complete(irq);
    80002b14:	8526                	mv	a0,s1
    80002b16:	00003097          	auipc	ra,0x3
    80002b1a:	5a6080e7          	jalr	1446(ra) # 800060bc <plic_complete>
    return 1;
    80002b1e:	4505                	li	a0,1
    80002b20:	bf55                	j	80002ad4 <devintr+0x1e>
      uartintr();
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	f00080e7          	jalr	-256(ra) # 80000a22 <uartintr>
    80002b2a:	b7ed                	j	80002b14 <devintr+0x5e>
      virtio_disk_intr();
    80002b2c:	00004097          	auipc	ra,0x4
    80002b30:	a3c080e7          	jalr	-1476(ra) # 80006568 <virtio_disk_intr>
    80002b34:	b7c5                	j	80002b14 <devintr+0x5e>
    if(cpuid() == 0){
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	ff6080e7          	jalr	-10(ra) # 80001b2c <cpuid>
    80002b3e:	c901                	beqz	a0,80002b4e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b40:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b44:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b46:	14479073          	csrw	sip,a5
    return 2;
    80002b4a:	4509                	li	a0,2
    80002b4c:	b761                	j	80002ad4 <devintr+0x1e>
      clockintr();
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	f22080e7          	jalr	-222(ra) # 80002a70 <clockintr>
    80002b56:	b7ed                	j	80002b40 <devintr+0x8a>

0000000080002b58 <usertrap>:
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	e04a                	sd	s2,0(sp)
    80002b62:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b64:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b68:	1007f793          	andi	a5,a5,256
    80002b6c:	e3ad                	bnez	a5,80002bce <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b6e:	00003797          	auipc	a5,0x3
    80002b72:	42278793          	addi	a5,a5,1058 # 80005f90 <kernelvec>
    80002b76:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b7a:	fffff097          	auipc	ra,0xfffff
    80002b7e:	fde080e7          	jalr	-34(ra) # 80001b58 <myproc>
    80002b82:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b84:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b86:	14102773          	csrr	a4,sepc
    80002b8a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b8c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002b90:	47a1                	li	a5,8
    80002b92:	04f71c63          	bne	a4,a5,80002bea <usertrap+0x92>
    if(p->killed)
    80002b96:	591c                	lw	a5,48(a0)
    80002b98:	e3b9                	bnez	a5,80002bde <usertrap+0x86>
    p->trapframe->epc += 4;
    80002b9a:	6cb8                	ld	a4,88(s1)
    80002b9c:	6f1c                	ld	a5,24(a4)
    80002b9e:	0791                	addi	a5,a5,4
    80002ba0:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ba6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002baa:	10079073          	csrw	sstatus,a5
    syscall();
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	2e6080e7          	jalr	742(ra) # 80002e94 <syscall>
  if(p->killed)
    80002bb6:	589c                	lw	a5,48(s1)
    80002bb8:	ebc1                	bnez	a5,80002c48 <usertrap+0xf0>
  usertrapret();
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	e18080e7          	jalr	-488(ra) # 800029d2 <usertrapret>
}
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	64a2                	ld	s1,8(sp)
    80002bc8:	6902                	ld	s2,0(sp)
    80002bca:	6105                	addi	sp,sp,32
    80002bcc:	8082                	ret
    panic("usertrap: not from user mode");
    80002bce:	00006517          	auipc	a0,0x6
    80002bd2:	83250513          	addi	a0,a0,-1998 # 80008400 <states.1760+0x130>
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	99e080e7          	jalr	-1634(ra) # 80000574 <panic>
      exit(-1);
    80002bde:	557d                	li	a0,-1
    80002be0:	00000097          	auipc	ra,0x0
    80002be4:	842080e7          	jalr	-1982(ra) # 80002422 <exit>
    80002be8:	bf4d                	j	80002b9a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	ecc080e7          	jalr	-308(ra) # 80002ab6 <devintr>
    80002bf2:	892a                	mv	s2,a0
    80002bf4:	c501                	beqz	a0,80002bfc <usertrap+0xa4>
  if(p->killed)
    80002bf6:	589c                	lw	a5,48(s1)
    80002bf8:	c3a1                	beqz	a5,80002c38 <usertrap+0xe0>
    80002bfa:	a815                	j	80002c2e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bfc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c00:	5c90                	lw	a2,56(s1)
    80002c02:	00006517          	auipc	a0,0x6
    80002c06:	81e50513          	addi	a0,a0,-2018 # 80008420 <states.1760+0x150>
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	9b4080e7          	jalr	-1612(ra) # 800005be <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c12:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c16:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c1a:	00006517          	auipc	a0,0x6
    80002c1e:	83650513          	addi	a0,a0,-1994 # 80008450 <states.1760+0x180>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	99c080e7          	jalr	-1636(ra) # 800005be <printf>
    p->killed = 1;
    80002c2a:	4785                	li	a5,1
    80002c2c:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002c2e:	557d                	li	a0,-1
    80002c30:	fffff097          	auipc	ra,0xfffff
    80002c34:	7f2080e7          	jalr	2034(ra) # 80002422 <exit>
  if(which_dev == 2)
    80002c38:	4789                	li	a5,2
    80002c3a:	f8f910e3          	bne	s2,a5,80002bba <usertrap+0x62>
    yield();
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	8f0080e7          	jalr	-1808(ra) # 8000252e <yield>
    80002c46:	bf95                	j	80002bba <usertrap+0x62>
  int which_dev = 0;
    80002c48:	4901                	li	s2,0
    80002c4a:	b7d5                	j	80002c2e <usertrap+0xd6>

0000000080002c4c <kerneltrap>:
{
    80002c4c:	7179                	addi	sp,sp,-48
    80002c4e:	f406                	sd	ra,40(sp)
    80002c50:	f022                	sd	s0,32(sp)
    80002c52:	ec26                	sd	s1,24(sp)
    80002c54:	e84a                	sd	s2,16(sp)
    80002c56:	e44e                	sd	s3,8(sp)
    80002c58:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c5a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c5e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c62:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c66:	1004f793          	andi	a5,s1,256
    80002c6a:	cb85                	beqz	a5,80002c9a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c6c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c70:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c72:	ef85                	bnez	a5,80002caa <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c74:	00000097          	auipc	ra,0x0
    80002c78:	e42080e7          	jalr	-446(ra) # 80002ab6 <devintr>
    80002c7c:	cd1d                	beqz	a0,80002cba <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c7e:	4789                	li	a5,2
    80002c80:	06f50a63          	beq	a0,a5,80002cf4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c84:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c88:	10049073          	csrw	sstatus,s1
}
    80002c8c:	70a2                	ld	ra,40(sp)
    80002c8e:	7402                	ld	s0,32(sp)
    80002c90:	64e2                	ld	s1,24(sp)
    80002c92:	6942                	ld	s2,16(sp)
    80002c94:	69a2                	ld	s3,8(sp)
    80002c96:	6145                	addi	sp,sp,48
    80002c98:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c9a:	00005517          	auipc	a0,0x5
    80002c9e:	7d650513          	addi	a0,a0,2006 # 80008470 <states.1760+0x1a0>
    80002ca2:	ffffe097          	auipc	ra,0xffffe
    80002ca6:	8d2080e7          	jalr	-1838(ra) # 80000574 <panic>
    panic("kerneltrap: interrupts enabled");
    80002caa:	00005517          	auipc	a0,0x5
    80002cae:	7ee50513          	addi	a0,a0,2030 # 80008498 <states.1760+0x1c8>
    80002cb2:	ffffe097          	auipc	ra,0xffffe
    80002cb6:	8c2080e7          	jalr	-1854(ra) # 80000574 <panic>
    printf("scause %p\n", scause);
    80002cba:	85ce                	mv	a1,s3
    80002cbc:	00005517          	auipc	a0,0x5
    80002cc0:	7fc50513          	addi	a0,a0,2044 # 800084b8 <states.1760+0x1e8>
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	8fa080e7          	jalr	-1798(ra) # 800005be <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ccc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cd0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cd4:	00005517          	auipc	a0,0x5
    80002cd8:	7f450513          	addi	a0,a0,2036 # 800084c8 <states.1760+0x1f8>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	8e2080e7          	jalr	-1822(ra) # 800005be <printf>
    panic("kerneltrap");
    80002ce4:	00005517          	auipc	a0,0x5
    80002ce8:	7fc50513          	addi	a0,a0,2044 # 800084e0 <states.1760+0x210>
    80002cec:	ffffe097          	auipc	ra,0xffffe
    80002cf0:	888080e7          	jalr	-1912(ra) # 80000574 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	e64080e7          	jalr	-412(ra) # 80001b58 <myproc>
    80002cfc:	d541                	beqz	a0,80002c84 <kerneltrap+0x38>
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	e5a080e7          	jalr	-422(ra) # 80001b58 <myproc>
    80002d06:	4d18                	lw	a4,24(a0)
    80002d08:	478d                	li	a5,3
    80002d0a:	f6f71de3          	bne	a4,a5,80002c84 <kerneltrap+0x38>
    yield();
    80002d0e:	00000097          	auipc	ra,0x0
    80002d12:	820080e7          	jalr	-2016(ra) # 8000252e <yield>
    80002d16:	b7bd                	j	80002c84 <kerneltrap+0x38>

0000000080002d18 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	e426                	sd	s1,8(sp)
    80002d20:	1000                	addi	s0,sp,32
    80002d22:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d24:	fffff097          	auipc	ra,0xfffff
    80002d28:	e34080e7          	jalr	-460(ra) # 80001b58 <myproc>
  switch (n) {
    80002d2c:	4795                	li	a5,5
    80002d2e:	0497e363          	bltu	a5,s1,80002d74 <argraw+0x5c>
    80002d32:	1482                	slli	s1,s1,0x20
    80002d34:	9081                	srli	s1,s1,0x20
    80002d36:	048a                	slli	s1,s1,0x2
    80002d38:	00005717          	auipc	a4,0x5
    80002d3c:	7b870713          	addi	a4,a4,1976 # 800084f0 <states.1760+0x220>
    80002d40:	94ba                	add	s1,s1,a4
    80002d42:	409c                	lw	a5,0(s1)
    80002d44:	97ba                	add	a5,a5,a4
    80002d46:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d48:	6d3c                	ld	a5,88(a0)
    80002d4a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d4c:	60e2                	ld	ra,24(sp)
    80002d4e:	6442                	ld	s0,16(sp)
    80002d50:	64a2                	ld	s1,8(sp)
    80002d52:	6105                	addi	sp,sp,32
    80002d54:	8082                	ret
    return p->trapframe->a1;
    80002d56:	6d3c                	ld	a5,88(a0)
    80002d58:	7fa8                	ld	a0,120(a5)
    80002d5a:	bfcd                	j	80002d4c <argraw+0x34>
    return p->trapframe->a2;
    80002d5c:	6d3c                	ld	a5,88(a0)
    80002d5e:	63c8                	ld	a0,128(a5)
    80002d60:	b7f5                	j	80002d4c <argraw+0x34>
    return p->trapframe->a3;
    80002d62:	6d3c                	ld	a5,88(a0)
    80002d64:	67c8                	ld	a0,136(a5)
    80002d66:	b7dd                	j	80002d4c <argraw+0x34>
    return p->trapframe->a4;
    80002d68:	6d3c                	ld	a5,88(a0)
    80002d6a:	6bc8                	ld	a0,144(a5)
    80002d6c:	b7c5                	j	80002d4c <argraw+0x34>
    return p->trapframe->a5;
    80002d6e:	6d3c                	ld	a5,88(a0)
    80002d70:	6fc8                	ld	a0,152(a5)
    80002d72:	bfe9                	j	80002d4c <argraw+0x34>
  panic("argraw");
    80002d74:	00006517          	auipc	a0,0x6
    80002d78:	84450513          	addi	a0,a0,-1980 # 800085b8 <syscalls+0xb0>
    80002d7c:	ffffd097          	auipc	ra,0xffffd
    80002d80:	7f8080e7          	jalr	2040(ra) # 80000574 <panic>

0000000080002d84 <fetchaddr>:
{
    80002d84:	1101                	addi	sp,sp,-32
    80002d86:	ec06                	sd	ra,24(sp)
    80002d88:	e822                	sd	s0,16(sp)
    80002d8a:	e426                	sd	s1,8(sp)
    80002d8c:	e04a                	sd	s2,0(sp)
    80002d8e:	1000                	addi	s0,sp,32
    80002d90:	84aa                	mv	s1,a0
    80002d92:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d94:	fffff097          	auipc	ra,0xfffff
    80002d98:	dc4080e7          	jalr	-572(ra) # 80001b58 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002d9c:	653c                	ld	a5,72(a0)
    80002d9e:	02f4f963          	bleu	a5,s1,80002dd0 <fetchaddr+0x4c>
    80002da2:	00848713          	addi	a4,s1,8
    80002da6:	02e7e763          	bltu	a5,a4,80002dd4 <fetchaddr+0x50>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002daa:	46a1                	li	a3,8
    80002dac:	8626                	mv	a2,s1
    80002dae:	85ca                	mv	a1,s2
    80002db0:	6928                	ld	a0,80(a0)
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	a36080e7          	jalr	-1482(ra) # 800017e8 <copyin>
    80002dba:	00a03533          	snez	a0,a0
    80002dbe:	40a0053b          	negw	a0,a0
    80002dc2:	2501                	sext.w	a0,a0
}
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	64a2                	ld	s1,8(sp)
    80002dca:	6902                	ld	s2,0(sp)
    80002dcc:	6105                	addi	sp,sp,32
    80002dce:	8082                	ret
    return -1;
    80002dd0:	557d                	li	a0,-1
    80002dd2:	bfcd                	j	80002dc4 <fetchaddr+0x40>
    80002dd4:	557d                	li	a0,-1
    80002dd6:	b7fd                	j	80002dc4 <fetchaddr+0x40>

0000000080002dd8 <fetchstr>:
{
    80002dd8:	7179                	addi	sp,sp,-48
    80002dda:	f406                	sd	ra,40(sp)
    80002ddc:	f022                	sd	s0,32(sp)
    80002dde:	ec26                	sd	s1,24(sp)
    80002de0:	e84a                	sd	s2,16(sp)
    80002de2:	e44e                	sd	s3,8(sp)
    80002de4:	1800                	addi	s0,sp,48
    80002de6:	892a                	mv	s2,a0
    80002de8:	84ae                	mv	s1,a1
    80002dea:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002dec:	fffff097          	auipc	ra,0xfffff
    80002df0:	d6c080e7          	jalr	-660(ra) # 80001b58 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002df4:	86ce                	mv	a3,s3
    80002df6:	864a                	mv	a2,s2
    80002df8:	85a6                	mv	a1,s1
    80002dfa:	6928                	ld	a0,80(a0)
    80002dfc:	fffff097          	auipc	ra,0xfffff
    80002e00:	a04080e7          	jalr	-1532(ra) # 80001800 <copyinstr>
  if(err < 0)
    80002e04:	00054763          	bltz	a0,80002e12 <fetchstr+0x3a>
  return strlen(buf);
    80002e08:	8526                	mv	a0,s1
    80002e0a:	ffffe097          	auipc	ra,0xffffe
    80002e0e:	0fe080e7          	jalr	254(ra) # 80000f08 <strlen>
}
    80002e12:	70a2                	ld	ra,40(sp)
    80002e14:	7402                	ld	s0,32(sp)
    80002e16:	64e2                	ld	s1,24(sp)
    80002e18:	6942                	ld	s2,16(sp)
    80002e1a:	69a2                	ld	s3,8(sp)
    80002e1c:	6145                	addi	sp,sp,48
    80002e1e:	8082                	ret

0000000080002e20 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e20:	1101                	addi	sp,sp,-32
    80002e22:	ec06                	sd	ra,24(sp)
    80002e24:	e822                	sd	s0,16(sp)
    80002e26:	e426                	sd	s1,8(sp)
    80002e28:	1000                	addi	s0,sp,32
    80002e2a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e2c:	00000097          	auipc	ra,0x0
    80002e30:	eec080e7          	jalr	-276(ra) # 80002d18 <argraw>
    80002e34:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e36:	4501                	li	a0,0
    80002e38:	60e2                	ld	ra,24(sp)
    80002e3a:	6442                	ld	s0,16(sp)
    80002e3c:	64a2                	ld	s1,8(sp)
    80002e3e:	6105                	addi	sp,sp,32
    80002e40:	8082                	ret

0000000080002e42 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e42:	1101                	addi	sp,sp,-32
    80002e44:	ec06                	sd	ra,24(sp)
    80002e46:	e822                	sd	s0,16(sp)
    80002e48:	e426                	sd	s1,8(sp)
    80002e4a:	1000                	addi	s0,sp,32
    80002e4c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e4e:	00000097          	auipc	ra,0x0
    80002e52:	eca080e7          	jalr	-310(ra) # 80002d18 <argraw>
    80002e56:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e58:	4501                	li	a0,0
    80002e5a:	60e2                	ld	ra,24(sp)
    80002e5c:	6442                	ld	s0,16(sp)
    80002e5e:	64a2                	ld	s1,8(sp)
    80002e60:	6105                	addi	sp,sp,32
    80002e62:	8082                	ret

0000000080002e64 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e64:	1101                	addi	sp,sp,-32
    80002e66:	ec06                	sd	ra,24(sp)
    80002e68:	e822                	sd	s0,16(sp)
    80002e6a:	e426                	sd	s1,8(sp)
    80002e6c:	e04a                	sd	s2,0(sp)
    80002e6e:	1000                	addi	s0,sp,32
    80002e70:	84ae                	mv	s1,a1
    80002e72:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	ea4080e7          	jalr	-348(ra) # 80002d18 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e7c:	864a                	mv	a2,s2
    80002e7e:	85a6                	mv	a1,s1
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	f58080e7          	jalr	-168(ra) # 80002dd8 <fetchstr>
}
    80002e88:	60e2                	ld	ra,24(sp)
    80002e8a:	6442                	ld	s0,16(sp)
    80002e8c:	64a2                	ld	s1,8(sp)
    80002e8e:	6902                	ld	s2,0(sp)
    80002e90:	6105                	addi	sp,sp,32
    80002e92:	8082                	ret

0000000080002e94 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e94:	1101                	addi	sp,sp,-32
    80002e96:	ec06                	sd	ra,24(sp)
    80002e98:	e822                	sd	s0,16(sp)
    80002e9a:	e426                	sd	s1,8(sp)
    80002e9c:	e04a                	sd	s2,0(sp)
    80002e9e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ea0:	fffff097          	auipc	ra,0xfffff
    80002ea4:	cb8080e7          	jalr	-840(ra) # 80001b58 <myproc>
    80002ea8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002eaa:	05853903          	ld	s2,88(a0)
    80002eae:	0a893783          	ld	a5,168(s2)
    80002eb2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002eb6:	37fd                	addiw	a5,a5,-1
    80002eb8:	4751                	li	a4,20
    80002eba:	00f76f63          	bltu	a4,a5,80002ed8 <syscall+0x44>
    80002ebe:	00369713          	slli	a4,a3,0x3
    80002ec2:	00005797          	auipc	a5,0x5
    80002ec6:	64678793          	addi	a5,a5,1606 # 80008508 <syscalls>
    80002eca:	97ba                	add	a5,a5,a4
    80002ecc:	639c                	ld	a5,0(a5)
    80002ece:	c789                	beqz	a5,80002ed8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ed0:	9782                	jalr	a5
    80002ed2:	06a93823          	sd	a0,112(s2)
    80002ed6:	a839                	j	80002ef4 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ed8:	15848613          	addi	a2,s1,344
    80002edc:	5c8c                	lw	a1,56(s1)
    80002ede:	00005517          	auipc	a0,0x5
    80002ee2:	6e250513          	addi	a0,a0,1762 # 800085c0 <syscalls+0xb8>
    80002ee6:	ffffd097          	auipc	ra,0xffffd
    80002eea:	6d8080e7          	jalr	1752(ra) # 800005be <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002eee:	6cbc                	ld	a5,88(s1)
    80002ef0:	577d                	li	a4,-1
    80002ef2:	fbb8                	sd	a4,112(a5)
  }
}
    80002ef4:	60e2                	ld	ra,24(sp)
    80002ef6:	6442                	ld	s0,16(sp)
    80002ef8:	64a2                	ld	s1,8(sp)
    80002efa:	6902                	ld	s2,0(sp)
    80002efc:	6105                	addi	sp,sp,32
    80002efe:	8082                	ret

0000000080002f00 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f00:	1101                	addi	sp,sp,-32
    80002f02:	ec06                	sd	ra,24(sp)
    80002f04:	e822                	sd	s0,16(sp)
    80002f06:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f08:	fec40593          	addi	a1,s0,-20
    80002f0c:	4501                	li	a0,0
    80002f0e:	00000097          	auipc	ra,0x0
    80002f12:	f12080e7          	jalr	-238(ra) # 80002e20 <argint>
    return -1;
    80002f16:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f18:	00054963          	bltz	a0,80002f2a <sys_exit+0x2a>
  exit(n);
    80002f1c:	fec42503          	lw	a0,-20(s0)
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	502080e7          	jalr	1282(ra) # 80002422 <exit>
  return 0;  // not reached
    80002f28:	4781                	li	a5,0
}
    80002f2a:	853e                	mv	a0,a5
    80002f2c:	60e2                	ld	ra,24(sp)
    80002f2e:	6442                	ld	s0,16(sp)
    80002f30:	6105                	addi	sp,sp,32
    80002f32:	8082                	ret

0000000080002f34 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f34:	1141                	addi	sp,sp,-16
    80002f36:	e406                	sd	ra,8(sp)
    80002f38:	e022                	sd	s0,0(sp)
    80002f3a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f3c:	fffff097          	auipc	ra,0xfffff
    80002f40:	c1c080e7          	jalr	-996(ra) # 80001b58 <myproc>
}
    80002f44:	5d08                	lw	a0,56(a0)
    80002f46:	60a2                	ld	ra,8(sp)
    80002f48:	6402                	ld	s0,0(sp)
    80002f4a:	0141                	addi	sp,sp,16
    80002f4c:	8082                	ret

0000000080002f4e <sys_fork>:

uint64
sys_fork(void)
{
    80002f4e:	1141                	addi	sp,sp,-16
    80002f50:	e406                	sd	ra,8(sp)
    80002f52:	e022                	sd	s0,0(sp)
    80002f54:	0800                	addi	s0,sp,16
  return fork();
    80002f56:	fffff097          	auipc	ra,0xfffff
    80002f5a:	192080e7          	jalr	402(ra) # 800020e8 <fork>
}
    80002f5e:	60a2                	ld	ra,8(sp)
    80002f60:	6402                	ld	s0,0(sp)
    80002f62:	0141                	addi	sp,sp,16
    80002f64:	8082                	ret

0000000080002f66 <sys_wait>:

uint64
sys_wait(void)
{
    80002f66:	1101                	addi	sp,sp,-32
    80002f68:	ec06                	sd	ra,24(sp)
    80002f6a:	e822                	sd	s0,16(sp)
    80002f6c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f6e:	fe840593          	addi	a1,s0,-24
    80002f72:	4501                	li	a0,0
    80002f74:	00000097          	auipc	ra,0x0
    80002f78:	ece080e7          	jalr	-306(ra) # 80002e42 <argaddr>
    return -1;
    80002f7c:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80002f7e:	00054963          	bltz	a0,80002f90 <sys_wait+0x2a>
  return wait(p);
    80002f82:	fe843503          	ld	a0,-24(s0)
    80002f86:	fffff097          	auipc	ra,0xfffff
    80002f8a:	662080e7          	jalr	1634(ra) # 800025e8 <wait>
    80002f8e:	87aa                	mv	a5,a0
}
    80002f90:	853e                	mv	a0,a5
    80002f92:	60e2                	ld	ra,24(sp)
    80002f94:	6442                	ld	s0,16(sp)
    80002f96:	6105                	addi	sp,sp,32
    80002f98:	8082                	ret

0000000080002f9a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f9a:	7179                	addi	sp,sp,-48
    80002f9c:	f406                	sd	ra,40(sp)
    80002f9e:	f022                	sd	s0,32(sp)
    80002fa0:	ec26                	sd	s1,24(sp)
    80002fa2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fa4:	fdc40593          	addi	a1,s0,-36
    80002fa8:	4501                	li	a0,0
    80002faa:	00000097          	auipc	ra,0x0
    80002fae:	e76080e7          	jalr	-394(ra) # 80002e20 <argint>
    return -1;
    80002fb2:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002fb4:	00054f63          	bltz	a0,80002fd2 <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002fb8:	fffff097          	auipc	ra,0xfffff
    80002fbc:	ba0080e7          	jalr	-1120(ra) # 80001b58 <myproc>
    80002fc0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fc2:	fdc42503          	lw	a0,-36(s0)
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	052080e7          	jalr	82(ra) # 80002018 <growproc>
    80002fce:	00054863          	bltz	a0,80002fde <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002fd2:	8526                	mv	a0,s1
    80002fd4:	70a2                	ld	ra,40(sp)
    80002fd6:	7402                	ld	s0,32(sp)
    80002fd8:	64e2                	ld	s1,24(sp)
    80002fda:	6145                	addi	sp,sp,48
    80002fdc:	8082                	ret
    return -1;
    80002fde:	54fd                	li	s1,-1
    80002fe0:	bfcd                	j	80002fd2 <sys_sbrk+0x38>

0000000080002fe2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fe2:	7139                	addi	sp,sp,-64
    80002fe4:	fc06                	sd	ra,56(sp)
    80002fe6:	f822                	sd	s0,48(sp)
    80002fe8:	f426                	sd	s1,40(sp)
    80002fea:	f04a                	sd	s2,32(sp)
    80002fec:	ec4e                	sd	s3,24(sp)
    80002fee:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002ff0:	fcc40593          	addi	a1,s0,-52
    80002ff4:	4501                	li	a0,0
    80002ff6:	00000097          	auipc	ra,0x0
    80002ffa:	e2a080e7          	jalr	-470(ra) # 80002e20 <argint>
    return -1;
    80002ffe:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003000:	06054763          	bltz	a0,8000306e <sys_sleep+0x8c>
  acquire(&tickslock);
    80003004:	00015517          	auipc	a0,0x15
    80003008:	96450513          	addi	a0,a0,-1692 # 80017968 <tickslock>
    8000300c:	ffffe097          	auipc	ra,0xffffe
    80003010:	c56080e7          	jalr	-938(ra) # 80000c62 <acquire>
  ticks0 = ticks;
    80003014:	00006797          	auipc	a5,0x6
    80003018:	00c78793          	addi	a5,a5,12 # 80009020 <ticks>
    8000301c:	0007a903          	lw	s2,0(a5)
  while(ticks - ticks0 < n){
    80003020:	fcc42783          	lw	a5,-52(s0)
    80003024:	cf85                	beqz	a5,8000305c <sys_sleep+0x7a>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003026:	00015997          	auipc	s3,0x15
    8000302a:	94298993          	addi	s3,s3,-1726 # 80017968 <tickslock>
    8000302e:	00006497          	auipc	s1,0x6
    80003032:	ff248493          	addi	s1,s1,-14 # 80009020 <ticks>
    if(myproc()->killed){
    80003036:	fffff097          	auipc	ra,0xfffff
    8000303a:	b22080e7          	jalr	-1246(ra) # 80001b58 <myproc>
    8000303e:	591c                	lw	a5,48(a0)
    80003040:	ef9d                	bnez	a5,8000307e <sys_sleep+0x9c>
    sleep(&ticks, &tickslock);
    80003042:	85ce                	mv	a1,s3
    80003044:	8526                	mv	a0,s1
    80003046:	fffff097          	auipc	ra,0xfffff
    8000304a:	524080e7          	jalr	1316(ra) # 8000256a <sleep>
  while(ticks - ticks0 < n){
    8000304e:	409c                	lw	a5,0(s1)
    80003050:	412787bb          	subw	a5,a5,s2
    80003054:	fcc42703          	lw	a4,-52(s0)
    80003058:	fce7efe3          	bltu	a5,a4,80003036 <sys_sleep+0x54>
  }
  release(&tickslock);
    8000305c:	00015517          	auipc	a0,0x15
    80003060:	90c50513          	addi	a0,a0,-1780 # 80017968 <tickslock>
    80003064:	ffffe097          	auipc	ra,0xffffe
    80003068:	cb2080e7          	jalr	-846(ra) # 80000d16 <release>
  return 0;
    8000306c:	4781                	li	a5,0
}
    8000306e:	853e                	mv	a0,a5
    80003070:	70e2                	ld	ra,56(sp)
    80003072:	7442                	ld	s0,48(sp)
    80003074:	74a2                	ld	s1,40(sp)
    80003076:	7902                	ld	s2,32(sp)
    80003078:	69e2                	ld	s3,24(sp)
    8000307a:	6121                	addi	sp,sp,64
    8000307c:	8082                	ret
      release(&tickslock);
    8000307e:	00015517          	auipc	a0,0x15
    80003082:	8ea50513          	addi	a0,a0,-1814 # 80017968 <tickslock>
    80003086:	ffffe097          	auipc	ra,0xffffe
    8000308a:	c90080e7          	jalr	-880(ra) # 80000d16 <release>
      return -1;
    8000308e:	57fd                	li	a5,-1
    80003090:	bff9                	j	8000306e <sys_sleep+0x8c>

0000000080003092 <sys_kill>:

uint64
sys_kill(void)
{
    80003092:	1101                	addi	sp,sp,-32
    80003094:	ec06                	sd	ra,24(sp)
    80003096:	e822                	sd	s0,16(sp)
    80003098:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    8000309a:	fec40593          	addi	a1,s0,-20
    8000309e:	4501                	li	a0,0
    800030a0:	00000097          	auipc	ra,0x0
    800030a4:	d80080e7          	jalr	-640(ra) # 80002e20 <argint>
    return -1;
    800030a8:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    800030aa:	00054963          	bltz	a0,800030bc <sys_kill+0x2a>
  return kill(pid);
    800030ae:	fec42503          	lw	a0,-20(s0)
    800030b2:	fffff097          	auipc	ra,0xfffff
    800030b6:	6a8080e7          	jalr	1704(ra) # 8000275a <kill>
    800030ba:	87aa                	mv	a5,a0
}
    800030bc:	853e                	mv	a0,a5
    800030be:	60e2                	ld	ra,24(sp)
    800030c0:	6442                	ld	s0,16(sp)
    800030c2:	6105                	addi	sp,sp,32
    800030c4:	8082                	ret

00000000800030c6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030d0:	00015517          	auipc	a0,0x15
    800030d4:	89850513          	addi	a0,a0,-1896 # 80017968 <tickslock>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	b8a080e7          	jalr	-1142(ra) # 80000c62 <acquire>
  xticks = ticks;
    800030e0:	00006797          	auipc	a5,0x6
    800030e4:	f4078793          	addi	a5,a5,-192 # 80009020 <ticks>
    800030e8:	4384                	lw	s1,0(a5)
  release(&tickslock);
    800030ea:	00015517          	auipc	a0,0x15
    800030ee:	87e50513          	addi	a0,a0,-1922 # 80017968 <tickslock>
    800030f2:	ffffe097          	auipc	ra,0xffffe
    800030f6:	c24080e7          	jalr	-988(ra) # 80000d16 <release>
  return xticks;
}
    800030fa:	02049513          	slli	a0,s1,0x20
    800030fe:	9101                	srli	a0,a0,0x20
    80003100:	60e2                	ld	ra,24(sp)
    80003102:	6442                	ld	s0,16(sp)
    80003104:	64a2                	ld	s1,8(sp)
    80003106:	6105                	addi	sp,sp,32
    80003108:	8082                	ret

000000008000310a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000310a:	7179                	addi	sp,sp,-48
    8000310c:	f406                	sd	ra,40(sp)
    8000310e:	f022                	sd	s0,32(sp)
    80003110:	ec26                	sd	s1,24(sp)
    80003112:	e84a                	sd	s2,16(sp)
    80003114:	e44e                	sd	s3,8(sp)
    80003116:	e052                	sd	s4,0(sp)
    80003118:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000311a:	00005597          	auipc	a1,0x5
    8000311e:	4c658593          	addi	a1,a1,1222 # 800085e0 <syscalls+0xd8>
    80003122:	00015517          	auipc	a0,0x15
    80003126:	85e50513          	addi	a0,a0,-1954 # 80017980 <bcache>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	aa8080e7          	jalr	-1368(ra) # 80000bd2 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003132:	0001d797          	auipc	a5,0x1d
    80003136:	84e78793          	addi	a5,a5,-1970 # 8001f980 <bcache+0x8000>
    8000313a:	0001d717          	auipc	a4,0x1d
    8000313e:	aae70713          	addi	a4,a4,-1362 # 8001fbe8 <bcache+0x8268>
    80003142:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003146:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000314a:	00015497          	auipc	s1,0x15
    8000314e:	84e48493          	addi	s1,s1,-1970 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80003152:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003154:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003156:	00005a17          	auipc	s4,0x5
    8000315a:	492a0a13          	addi	s4,s4,1170 # 800085e8 <syscalls+0xe0>
    b->next = bcache.head.next;
    8000315e:	2b893783          	ld	a5,696(s2)
    80003162:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003164:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003168:	85d2                	mv	a1,s4
    8000316a:	01048513          	addi	a0,s1,16
    8000316e:	00001097          	auipc	ra,0x1
    80003172:	51a080e7          	jalr	1306(ra) # 80004688 <initsleeplock>
    bcache.head.next->prev = b;
    80003176:	2b893783          	ld	a5,696(s2)
    8000317a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000317c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003180:	45848493          	addi	s1,s1,1112
    80003184:	fd349de3          	bne	s1,s3,8000315e <binit+0x54>
  }
}
    80003188:	70a2                	ld	ra,40(sp)
    8000318a:	7402                	ld	s0,32(sp)
    8000318c:	64e2                	ld	s1,24(sp)
    8000318e:	6942                	ld	s2,16(sp)
    80003190:	69a2                	ld	s3,8(sp)
    80003192:	6a02                	ld	s4,0(sp)
    80003194:	6145                	addi	sp,sp,48
    80003196:	8082                	ret

0000000080003198 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003198:	7179                	addi	sp,sp,-48
    8000319a:	f406                	sd	ra,40(sp)
    8000319c:	f022                	sd	s0,32(sp)
    8000319e:	ec26                	sd	s1,24(sp)
    800031a0:	e84a                	sd	s2,16(sp)
    800031a2:	e44e                	sd	s3,8(sp)
    800031a4:	1800                	addi	s0,sp,48
    800031a6:	89aa                	mv	s3,a0
    800031a8:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800031aa:	00014517          	auipc	a0,0x14
    800031ae:	7d650513          	addi	a0,a0,2006 # 80017980 <bcache>
    800031b2:	ffffe097          	auipc	ra,0xffffe
    800031b6:	ab0080e7          	jalr	-1360(ra) # 80000c62 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031ba:	0001c797          	auipc	a5,0x1c
    800031be:	7c678793          	addi	a5,a5,1990 # 8001f980 <bcache+0x8000>
    800031c2:	2b87b483          	ld	s1,696(a5)
    800031c6:	0001d797          	auipc	a5,0x1d
    800031ca:	a2278793          	addi	a5,a5,-1502 # 8001fbe8 <bcache+0x8268>
    800031ce:	02f48f63          	beq	s1,a5,8000320c <bread+0x74>
    800031d2:	873e                	mv	a4,a5
    800031d4:	a021                	j	800031dc <bread+0x44>
    800031d6:	68a4                	ld	s1,80(s1)
    800031d8:	02e48a63          	beq	s1,a4,8000320c <bread+0x74>
    if(b->dev == dev && b->blockno == blockno){
    800031dc:	449c                	lw	a5,8(s1)
    800031de:	ff379ce3          	bne	a5,s3,800031d6 <bread+0x3e>
    800031e2:	44dc                	lw	a5,12(s1)
    800031e4:	ff2799e3          	bne	a5,s2,800031d6 <bread+0x3e>
      b->refcnt++;
    800031e8:	40bc                	lw	a5,64(s1)
    800031ea:	2785                	addiw	a5,a5,1
    800031ec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ee:	00014517          	auipc	a0,0x14
    800031f2:	79250513          	addi	a0,a0,1938 # 80017980 <bcache>
    800031f6:	ffffe097          	auipc	ra,0xffffe
    800031fa:	b20080e7          	jalr	-1248(ra) # 80000d16 <release>
      acquiresleep(&b->lock);
    800031fe:	01048513          	addi	a0,s1,16
    80003202:	00001097          	auipc	ra,0x1
    80003206:	4c0080e7          	jalr	1216(ra) # 800046c2 <acquiresleep>
      return b;
    8000320a:	a8b1                	j	80003266 <bread+0xce>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000320c:	0001c797          	auipc	a5,0x1c
    80003210:	77478793          	addi	a5,a5,1908 # 8001f980 <bcache+0x8000>
    80003214:	2b07b483          	ld	s1,688(a5)
    80003218:	0001d797          	auipc	a5,0x1d
    8000321c:	9d078793          	addi	a5,a5,-1584 # 8001fbe8 <bcache+0x8268>
    80003220:	04f48d63          	beq	s1,a5,8000327a <bread+0xe2>
    if(b->refcnt == 0) {
    80003224:	40bc                	lw	a5,64(s1)
    80003226:	cb91                	beqz	a5,8000323a <bread+0xa2>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003228:	0001d717          	auipc	a4,0x1d
    8000322c:	9c070713          	addi	a4,a4,-1600 # 8001fbe8 <bcache+0x8268>
    80003230:	64a4                	ld	s1,72(s1)
    80003232:	04e48463          	beq	s1,a4,8000327a <bread+0xe2>
    if(b->refcnt == 0) {
    80003236:	40bc                	lw	a5,64(s1)
    80003238:	ffe5                	bnez	a5,80003230 <bread+0x98>
      b->dev = dev;
    8000323a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000323e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003242:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003246:	4785                	li	a5,1
    80003248:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000324a:	00014517          	auipc	a0,0x14
    8000324e:	73650513          	addi	a0,a0,1846 # 80017980 <bcache>
    80003252:	ffffe097          	auipc	ra,0xffffe
    80003256:	ac4080e7          	jalr	-1340(ra) # 80000d16 <release>
      acquiresleep(&b->lock);
    8000325a:	01048513          	addi	a0,s1,16
    8000325e:	00001097          	auipc	ra,0x1
    80003262:	464080e7          	jalr	1124(ra) # 800046c2 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003266:	409c                	lw	a5,0(s1)
    80003268:	c38d                	beqz	a5,8000328a <bread+0xf2>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000326a:	8526                	mv	a0,s1
    8000326c:	70a2                	ld	ra,40(sp)
    8000326e:	7402                	ld	s0,32(sp)
    80003270:	64e2                	ld	s1,24(sp)
    80003272:	6942                	ld	s2,16(sp)
    80003274:	69a2                	ld	s3,8(sp)
    80003276:	6145                	addi	sp,sp,48
    80003278:	8082                	ret
  panic("bget: no buffers");
    8000327a:	00005517          	auipc	a0,0x5
    8000327e:	37650513          	addi	a0,a0,886 # 800085f0 <syscalls+0xe8>
    80003282:	ffffd097          	auipc	ra,0xffffd
    80003286:	2f2080e7          	jalr	754(ra) # 80000574 <panic>
    virtio_disk_rw(b, 0);
    8000328a:	4581                	li	a1,0
    8000328c:	8526                	mv	a0,s1
    8000328e:	00003097          	auipc	ra,0x3
    80003292:	020080e7          	jalr	32(ra) # 800062ae <virtio_disk_rw>
    b->valid = 1;
    80003296:	4785                	li	a5,1
    80003298:	c09c                	sw	a5,0(s1)
  return b;
    8000329a:	bfc1                	j	8000326a <bread+0xd2>

000000008000329c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000329c:	1101                	addi	sp,sp,-32
    8000329e:	ec06                	sd	ra,24(sp)
    800032a0:	e822                	sd	s0,16(sp)
    800032a2:	e426                	sd	s1,8(sp)
    800032a4:	1000                	addi	s0,sp,32
    800032a6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032a8:	0541                	addi	a0,a0,16
    800032aa:	00001097          	auipc	ra,0x1
    800032ae:	4b2080e7          	jalr	1202(ra) # 8000475c <holdingsleep>
    800032b2:	cd01                	beqz	a0,800032ca <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032b4:	4585                	li	a1,1
    800032b6:	8526                	mv	a0,s1
    800032b8:	00003097          	auipc	ra,0x3
    800032bc:	ff6080e7          	jalr	-10(ra) # 800062ae <virtio_disk_rw>
}
    800032c0:	60e2                	ld	ra,24(sp)
    800032c2:	6442                	ld	s0,16(sp)
    800032c4:	64a2                	ld	s1,8(sp)
    800032c6:	6105                	addi	sp,sp,32
    800032c8:	8082                	ret
    panic("bwrite");
    800032ca:	00005517          	auipc	a0,0x5
    800032ce:	33e50513          	addi	a0,a0,830 # 80008608 <syscalls+0x100>
    800032d2:	ffffd097          	auipc	ra,0xffffd
    800032d6:	2a2080e7          	jalr	674(ra) # 80000574 <panic>

00000000800032da <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032da:	1101                	addi	sp,sp,-32
    800032dc:	ec06                	sd	ra,24(sp)
    800032de:	e822                	sd	s0,16(sp)
    800032e0:	e426                	sd	s1,8(sp)
    800032e2:	e04a                	sd	s2,0(sp)
    800032e4:	1000                	addi	s0,sp,32
    800032e6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032e8:	01050913          	addi	s2,a0,16
    800032ec:	854a                	mv	a0,s2
    800032ee:	00001097          	auipc	ra,0x1
    800032f2:	46e080e7          	jalr	1134(ra) # 8000475c <holdingsleep>
    800032f6:	c92d                	beqz	a0,80003368 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032f8:	854a                	mv	a0,s2
    800032fa:	00001097          	auipc	ra,0x1
    800032fe:	41e080e7          	jalr	1054(ra) # 80004718 <releasesleep>

  acquire(&bcache.lock);
    80003302:	00014517          	auipc	a0,0x14
    80003306:	67e50513          	addi	a0,a0,1662 # 80017980 <bcache>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	958080e7          	jalr	-1704(ra) # 80000c62 <acquire>
  b->refcnt--;
    80003312:	40bc                	lw	a5,64(s1)
    80003314:	37fd                	addiw	a5,a5,-1
    80003316:	0007871b          	sext.w	a4,a5
    8000331a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000331c:	eb05                	bnez	a4,8000334c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000331e:	68bc                	ld	a5,80(s1)
    80003320:	64b8                	ld	a4,72(s1)
    80003322:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003324:	64bc                	ld	a5,72(s1)
    80003326:	68b8                	ld	a4,80(s1)
    80003328:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000332a:	0001c797          	auipc	a5,0x1c
    8000332e:	65678793          	addi	a5,a5,1622 # 8001f980 <bcache+0x8000>
    80003332:	2b87b703          	ld	a4,696(a5)
    80003336:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003338:	0001d717          	auipc	a4,0x1d
    8000333c:	8b070713          	addi	a4,a4,-1872 # 8001fbe8 <bcache+0x8268>
    80003340:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003342:	2b87b703          	ld	a4,696(a5)
    80003346:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003348:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000334c:	00014517          	auipc	a0,0x14
    80003350:	63450513          	addi	a0,a0,1588 # 80017980 <bcache>
    80003354:	ffffe097          	auipc	ra,0xffffe
    80003358:	9c2080e7          	jalr	-1598(ra) # 80000d16 <release>
}
    8000335c:	60e2                	ld	ra,24(sp)
    8000335e:	6442                	ld	s0,16(sp)
    80003360:	64a2                	ld	s1,8(sp)
    80003362:	6902                	ld	s2,0(sp)
    80003364:	6105                	addi	sp,sp,32
    80003366:	8082                	ret
    panic("brelse");
    80003368:	00005517          	auipc	a0,0x5
    8000336c:	2a850513          	addi	a0,a0,680 # 80008610 <syscalls+0x108>
    80003370:	ffffd097          	auipc	ra,0xffffd
    80003374:	204080e7          	jalr	516(ra) # 80000574 <panic>

0000000080003378 <bpin>:

void
bpin(struct buf *b) {
    80003378:	1101                	addi	sp,sp,-32
    8000337a:	ec06                	sd	ra,24(sp)
    8000337c:	e822                	sd	s0,16(sp)
    8000337e:	e426                	sd	s1,8(sp)
    80003380:	1000                	addi	s0,sp,32
    80003382:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003384:	00014517          	auipc	a0,0x14
    80003388:	5fc50513          	addi	a0,a0,1532 # 80017980 <bcache>
    8000338c:	ffffe097          	auipc	ra,0xffffe
    80003390:	8d6080e7          	jalr	-1834(ra) # 80000c62 <acquire>
  b->refcnt++;
    80003394:	40bc                	lw	a5,64(s1)
    80003396:	2785                	addiw	a5,a5,1
    80003398:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000339a:	00014517          	auipc	a0,0x14
    8000339e:	5e650513          	addi	a0,a0,1510 # 80017980 <bcache>
    800033a2:	ffffe097          	auipc	ra,0xffffe
    800033a6:	974080e7          	jalr	-1676(ra) # 80000d16 <release>
}
    800033aa:	60e2                	ld	ra,24(sp)
    800033ac:	6442                	ld	s0,16(sp)
    800033ae:	64a2                	ld	s1,8(sp)
    800033b0:	6105                	addi	sp,sp,32
    800033b2:	8082                	ret

00000000800033b4 <bunpin>:

void
bunpin(struct buf *b) {
    800033b4:	1101                	addi	sp,sp,-32
    800033b6:	ec06                	sd	ra,24(sp)
    800033b8:	e822                	sd	s0,16(sp)
    800033ba:	e426                	sd	s1,8(sp)
    800033bc:	1000                	addi	s0,sp,32
    800033be:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033c0:	00014517          	auipc	a0,0x14
    800033c4:	5c050513          	addi	a0,a0,1472 # 80017980 <bcache>
    800033c8:	ffffe097          	auipc	ra,0xffffe
    800033cc:	89a080e7          	jalr	-1894(ra) # 80000c62 <acquire>
  b->refcnt--;
    800033d0:	40bc                	lw	a5,64(s1)
    800033d2:	37fd                	addiw	a5,a5,-1
    800033d4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033d6:	00014517          	auipc	a0,0x14
    800033da:	5aa50513          	addi	a0,a0,1450 # 80017980 <bcache>
    800033de:	ffffe097          	auipc	ra,0xffffe
    800033e2:	938080e7          	jalr	-1736(ra) # 80000d16 <release>
}
    800033e6:	60e2                	ld	ra,24(sp)
    800033e8:	6442                	ld	s0,16(sp)
    800033ea:	64a2                	ld	s1,8(sp)
    800033ec:	6105                	addi	sp,sp,32
    800033ee:	8082                	ret

00000000800033f0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033f0:	1101                	addi	sp,sp,-32
    800033f2:	ec06                	sd	ra,24(sp)
    800033f4:	e822                	sd	s0,16(sp)
    800033f6:	e426                	sd	s1,8(sp)
    800033f8:	e04a                	sd	s2,0(sp)
    800033fa:	1000                	addi	s0,sp,32
    800033fc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033fe:	00d5d59b          	srliw	a1,a1,0xd
    80003402:	0001d797          	auipc	a5,0x1d
    80003406:	c3e78793          	addi	a5,a5,-962 # 80020040 <sb>
    8000340a:	4fdc                	lw	a5,28(a5)
    8000340c:	9dbd                	addw	a1,a1,a5
    8000340e:	00000097          	auipc	ra,0x0
    80003412:	d8a080e7          	jalr	-630(ra) # 80003198 <bread>
  bi = b % BPB;
    80003416:	2481                	sext.w	s1,s1
  m = 1 << (bi % 8);
    80003418:	0074f793          	andi	a5,s1,7
    8000341c:	4705                	li	a4,1
    8000341e:	00f7173b          	sllw	a4,a4,a5
  bi = b % BPB;
    80003422:	6789                	lui	a5,0x2
    80003424:	17fd                	addi	a5,a5,-1
    80003426:	8cfd                	and	s1,s1,a5
  if((bp->data[bi/8] & m) == 0)
    80003428:	41f4d79b          	sraiw	a5,s1,0x1f
    8000342c:	01d7d79b          	srliw	a5,a5,0x1d
    80003430:	9fa5                	addw	a5,a5,s1
    80003432:	4037d79b          	sraiw	a5,a5,0x3
    80003436:	00f506b3          	add	a3,a0,a5
    8000343a:	0586c683          	lbu	a3,88(a3)
    8000343e:	00d77633          	and	a2,a4,a3
    80003442:	c61d                	beqz	a2,80003470 <bfree+0x80>
    80003444:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003446:	97aa                	add	a5,a5,a0
    80003448:	fff74713          	not	a4,a4
    8000344c:	8f75                	and	a4,a4,a3
    8000344e:	04e78c23          	sb	a4,88(a5) # 2058 <_entry-0x7fffdfa8>
  log_write(bp);
    80003452:	00001097          	auipc	ra,0x1
    80003456:	132080e7          	jalr	306(ra) # 80004584 <log_write>
  brelse(bp);
    8000345a:	854a                	mv	a0,s2
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	e7e080e7          	jalr	-386(ra) # 800032da <brelse>
}
    80003464:	60e2                	ld	ra,24(sp)
    80003466:	6442                	ld	s0,16(sp)
    80003468:	64a2                	ld	s1,8(sp)
    8000346a:	6902                	ld	s2,0(sp)
    8000346c:	6105                	addi	sp,sp,32
    8000346e:	8082                	ret
    panic("freeing free block");
    80003470:	00005517          	auipc	a0,0x5
    80003474:	1a850513          	addi	a0,a0,424 # 80008618 <syscalls+0x110>
    80003478:	ffffd097          	auipc	ra,0xffffd
    8000347c:	0fc080e7          	jalr	252(ra) # 80000574 <panic>

0000000080003480 <balloc>:
{
    80003480:	711d                	addi	sp,sp,-96
    80003482:	ec86                	sd	ra,88(sp)
    80003484:	e8a2                	sd	s0,80(sp)
    80003486:	e4a6                	sd	s1,72(sp)
    80003488:	e0ca                	sd	s2,64(sp)
    8000348a:	fc4e                	sd	s3,56(sp)
    8000348c:	f852                	sd	s4,48(sp)
    8000348e:	f456                	sd	s5,40(sp)
    80003490:	f05a                	sd	s6,32(sp)
    80003492:	ec5e                	sd	s7,24(sp)
    80003494:	e862                	sd	s8,16(sp)
    80003496:	e466                	sd	s9,8(sp)
    80003498:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000349a:	0001d797          	auipc	a5,0x1d
    8000349e:	ba678793          	addi	a5,a5,-1114 # 80020040 <sb>
    800034a2:	43dc                	lw	a5,4(a5)
    800034a4:	10078e63          	beqz	a5,800035c0 <balloc+0x140>
    800034a8:	8baa                	mv	s7,a0
    800034aa:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034ac:	0001db17          	auipc	s6,0x1d
    800034b0:	b94b0b13          	addi	s6,s6,-1132 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b4:	4c05                	li	s8,1
      m = 1 << (bi % 8);
    800034b6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034ba:	6c89                	lui	s9,0x2
    800034bc:	a079                	j	8000354a <balloc+0xca>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034be:	8942                	mv	s2,a6
      m = 1 << (bi % 8);
    800034c0:	4705                	li	a4,1
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034c2:	4681                	li	a3,0
        bp->data[bi/8] |= m;  // Mark block in use.
    800034c4:	96a6                	add	a3,a3,s1
    800034c6:	8f51                	or	a4,a4,a2
    800034c8:	04e68c23          	sb	a4,88(a3)
        log_write(bp);
    800034cc:	8526                	mv	a0,s1
    800034ce:	00001097          	auipc	ra,0x1
    800034d2:	0b6080e7          	jalr	182(ra) # 80004584 <log_write>
        brelse(bp);
    800034d6:	8526                	mv	a0,s1
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	e02080e7          	jalr	-510(ra) # 800032da <brelse>
  bp = bread(dev, bno);
    800034e0:	85ca                	mv	a1,s2
    800034e2:	855e                	mv	a0,s7
    800034e4:	00000097          	auipc	ra,0x0
    800034e8:	cb4080e7          	jalr	-844(ra) # 80003198 <bread>
    800034ec:	84aa                	mv	s1,a0
  memset(bp->data, 0, BSIZE);
    800034ee:	40000613          	li	a2,1024
    800034f2:	4581                	li	a1,0
    800034f4:	05850513          	addi	a0,a0,88
    800034f8:	ffffe097          	auipc	ra,0xffffe
    800034fc:	866080e7          	jalr	-1946(ra) # 80000d5e <memset>
  log_write(bp);
    80003500:	8526                	mv	a0,s1
    80003502:	00001097          	auipc	ra,0x1
    80003506:	082080e7          	jalr	130(ra) # 80004584 <log_write>
  brelse(bp);
    8000350a:	8526                	mv	a0,s1
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	dce080e7          	jalr	-562(ra) # 800032da <brelse>
}
    80003514:	854a                	mv	a0,s2
    80003516:	60e6                	ld	ra,88(sp)
    80003518:	6446                	ld	s0,80(sp)
    8000351a:	64a6                	ld	s1,72(sp)
    8000351c:	6906                	ld	s2,64(sp)
    8000351e:	79e2                	ld	s3,56(sp)
    80003520:	7a42                	ld	s4,48(sp)
    80003522:	7aa2                	ld	s5,40(sp)
    80003524:	7b02                	ld	s6,32(sp)
    80003526:	6be2                	ld	s7,24(sp)
    80003528:	6c42                	ld	s8,16(sp)
    8000352a:	6ca2                	ld	s9,8(sp)
    8000352c:	6125                	addi	sp,sp,96
    8000352e:	8082                	ret
    brelse(bp);
    80003530:	8526                	mv	a0,s1
    80003532:	00000097          	auipc	ra,0x0
    80003536:	da8080e7          	jalr	-600(ra) # 800032da <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000353a:	015c87bb          	addw	a5,s9,s5
    8000353e:	00078a9b          	sext.w	s5,a5
    80003542:	004b2703          	lw	a4,4(s6)
    80003546:	06eafd63          	bleu	a4,s5,800035c0 <balloc+0x140>
    bp = bread(dev, BBLOCK(b, sb));
    8000354a:	41fad79b          	sraiw	a5,s5,0x1f
    8000354e:	0137d79b          	srliw	a5,a5,0x13
    80003552:	015787bb          	addw	a5,a5,s5
    80003556:	40d7d79b          	sraiw	a5,a5,0xd
    8000355a:	01cb2583          	lw	a1,28(s6)
    8000355e:	9dbd                	addw	a1,a1,a5
    80003560:	855e                	mv	a0,s7
    80003562:	00000097          	auipc	ra,0x0
    80003566:	c36080e7          	jalr	-970(ra) # 80003198 <bread>
    8000356a:	84aa                	mv	s1,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000356c:	000a881b          	sext.w	a6,s5
    80003570:	004b2503          	lw	a0,4(s6)
    80003574:	faa87ee3          	bleu	a0,a6,80003530 <balloc+0xb0>
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003578:	0584c603          	lbu	a2,88(s1)
    8000357c:	00167793          	andi	a5,a2,1
    80003580:	df9d                	beqz	a5,800034be <balloc+0x3e>
    80003582:	4105053b          	subw	a0,a0,a6
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003586:	87e2                	mv	a5,s8
    80003588:	0107893b          	addw	s2,a5,a6
    8000358c:	faa782e3          	beq	a5,a0,80003530 <balloc+0xb0>
      m = 1 << (bi % 8);
    80003590:	41f7d71b          	sraiw	a4,a5,0x1f
    80003594:	01d7561b          	srliw	a2,a4,0x1d
    80003598:	00f606bb          	addw	a3,a2,a5
    8000359c:	0076f713          	andi	a4,a3,7
    800035a0:	9f11                	subw	a4,a4,a2
    800035a2:	00e9973b          	sllw	a4,s3,a4
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800035a6:	4036d69b          	sraiw	a3,a3,0x3
    800035aa:	00d48633          	add	a2,s1,a3
    800035ae:	05864603          	lbu	a2,88(a2)
    800035b2:	00c775b3          	and	a1,a4,a2
    800035b6:	d599                	beqz	a1,800034c4 <balloc+0x44>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035b8:	2785                	addiw	a5,a5,1
    800035ba:	fd4797e3          	bne	a5,s4,80003588 <balloc+0x108>
    800035be:	bf8d                	j	80003530 <balloc+0xb0>
  panic("balloc: out of blocks");
    800035c0:	00005517          	auipc	a0,0x5
    800035c4:	07050513          	addi	a0,a0,112 # 80008630 <syscalls+0x128>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	fac080e7          	jalr	-84(ra) # 80000574 <panic>

00000000800035d0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035d0:	7179                	addi	sp,sp,-48
    800035d2:	f406                	sd	ra,40(sp)
    800035d4:	f022                	sd	s0,32(sp)
    800035d6:	ec26                	sd	s1,24(sp)
    800035d8:	e84a                	sd	s2,16(sp)
    800035da:	e44e                	sd	s3,8(sp)
    800035dc:	e052                	sd	s4,0(sp)
    800035de:	1800                	addi	s0,sp,48
    800035e0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035e2:	47ad                	li	a5,11
    800035e4:	04b7fe63          	bleu	a1,a5,80003640 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035e8:	ff45849b          	addiw	s1,a1,-12
    800035ec:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035f0:	0ff00793          	li	a5,255
    800035f4:	0ae7e363          	bltu	a5,a4,8000369a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035f8:	08052583          	lw	a1,128(a0)
    800035fc:	c5ad                	beqz	a1,80003666 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035fe:	0009a503          	lw	a0,0(s3)
    80003602:	00000097          	auipc	ra,0x0
    80003606:	b96080e7          	jalr	-1130(ra) # 80003198 <bread>
    8000360a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000360c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003610:	02049593          	slli	a1,s1,0x20
    80003614:	9181                	srli	a1,a1,0x20
    80003616:	058a                	slli	a1,a1,0x2
    80003618:	00b784b3          	add	s1,a5,a1
    8000361c:	0004a903          	lw	s2,0(s1)
    80003620:	04090d63          	beqz	s2,8000367a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003624:	8552                	mv	a0,s4
    80003626:	00000097          	auipc	ra,0x0
    8000362a:	cb4080e7          	jalr	-844(ra) # 800032da <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000362e:	854a                	mv	a0,s2
    80003630:	70a2                	ld	ra,40(sp)
    80003632:	7402                	ld	s0,32(sp)
    80003634:	64e2                	ld	s1,24(sp)
    80003636:	6942                	ld	s2,16(sp)
    80003638:	69a2                	ld	s3,8(sp)
    8000363a:	6a02                	ld	s4,0(sp)
    8000363c:	6145                	addi	sp,sp,48
    8000363e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003640:	02059493          	slli	s1,a1,0x20
    80003644:	9081                	srli	s1,s1,0x20
    80003646:	048a                	slli	s1,s1,0x2
    80003648:	94aa                	add	s1,s1,a0
    8000364a:	0504a903          	lw	s2,80(s1)
    8000364e:	fe0910e3          	bnez	s2,8000362e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003652:	4108                	lw	a0,0(a0)
    80003654:	00000097          	auipc	ra,0x0
    80003658:	e2c080e7          	jalr	-468(ra) # 80003480 <balloc>
    8000365c:	0005091b          	sext.w	s2,a0
    80003660:	0524a823          	sw	s2,80(s1)
    80003664:	b7e9                	j	8000362e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003666:	4108                	lw	a0,0(a0)
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	e18080e7          	jalr	-488(ra) # 80003480 <balloc>
    80003670:	0005059b          	sext.w	a1,a0
    80003674:	08b9a023          	sw	a1,128(s3)
    80003678:	b759                	j	800035fe <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000367a:	0009a503          	lw	a0,0(s3)
    8000367e:	00000097          	auipc	ra,0x0
    80003682:	e02080e7          	jalr	-510(ra) # 80003480 <balloc>
    80003686:	0005091b          	sext.w	s2,a0
    8000368a:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    8000368e:	8552                	mv	a0,s4
    80003690:	00001097          	auipc	ra,0x1
    80003694:	ef4080e7          	jalr	-268(ra) # 80004584 <log_write>
    80003698:	b771                	j	80003624 <bmap+0x54>
  panic("bmap: out of range");
    8000369a:	00005517          	auipc	a0,0x5
    8000369e:	fae50513          	addi	a0,a0,-82 # 80008648 <syscalls+0x140>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	ed2080e7          	jalr	-302(ra) # 80000574 <panic>

00000000800036aa <iget>:
{
    800036aa:	7179                	addi	sp,sp,-48
    800036ac:	f406                	sd	ra,40(sp)
    800036ae:	f022                	sd	s0,32(sp)
    800036b0:	ec26                	sd	s1,24(sp)
    800036b2:	e84a                	sd	s2,16(sp)
    800036b4:	e44e                	sd	s3,8(sp)
    800036b6:	e052                	sd	s4,0(sp)
    800036b8:	1800                	addi	s0,sp,48
    800036ba:	89aa                	mv	s3,a0
    800036bc:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    800036be:	0001d517          	auipc	a0,0x1d
    800036c2:	9a250513          	addi	a0,a0,-1630 # 80020060 <icache>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	59c080e7          	jalr	1436(ra) # 80000c62 <acquire>
  empty = 0;
    800036ce:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800036d0:	0001d497          	auipc	s1,0x1d
    800036d4:	9a848493          	addi	s1,s1,-1624 # 80020078 <icache+0x18>
    800036d8:	0001e697          	auipc	a3,0x1e
    800036dc:	43068693          	addi	a3,a3,1072 # 80021b08 <log>
    800036e0:	a039                	j	800036ee <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036e2:	02090b63          	beqz	s2,80003718 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800036e6:	08848493          	addi	s1,s1,136
    800036ea:	02d48a63          	beq	s1,a3,8000371e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036ee:	449c                	lw	a5,8(s1)
    800036f0:	fef059e3          	blez	a5,800036e2 <iget+0x38>
    800036f4:	4098                	lw	a4,0(s1)
    800036f6:	ff3716e3          	bne	a4,s3,800036e2 <iget+0x38>
    800036fa:	40d8                	lw	a4,4(s1)
    800036fc:	ff4713e3          	bne	a4,s4,800036e2 <iget+0x38>
      ip->ref++;
    80003700:	2785                	addiw	a5,a5,1
    80003702:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003704:	0001d517          	auipc	a0,0x1d
    80003708:	95c50513          	addi	a0,a0,-1700 # 80020060 <icache>
    8000370c:	ffffd097          	auipc	ra,0xffffd
    80003710:	60a080e7          	jalr	1546(ra) # 80000d16 <release>
      return ip;
    80003714:	8926                	mv	s2,s1
    80003716:	a03d                	j	80003744 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003718:	f7f9                	bnez	a5,800036e6 <iget+0x3c>
    8000371a:	8926                	mv	s2,s1
    8000371c:	b7e9                	j	800036e6 <iget+0x3c>
  if(empty == 0)
    8000371e:	02090c63          	beqz	s2,80003756 <iget+0xac>
  ip->dev = dev;
    80003722:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003726:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000372a:	4785                	li	a5,1
    8000372c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003730:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003734:	0001d517          	auipc	a0,0x1d
    80003738:	92c50513          	addi	a0,a0,-1748 # 80020060 <icache>
    8000373c:	ffffd097          	auipc	ra,0xffffd
    80003740:	5da080e7          	jalr	1498(ra) # 80000d16 <release>
}
    80003744:	854a                	mv	a0,s2
    80003746:	70a2                	ld	ra,40(sp)
    80003748:	7402                	ld	s0,32(sp)
    8000374a:	64e2                	ld	s1,24(sp)
    8000374c:	6942                	ld	s2,16(sp)
    8000374e:	69a2                	ld	s3,8(sp)
    80003750:	6a02                	ld	s4,0(sp)
    80003752:	6145                	addi	sp,sp,48
    80003754:	8082                	ret
    panic("iget: no inodes");
    80003756:	00005517          	auipc	a0,0x5
    8000375a:	f0a50513          	addi	a0,a0,-246 # 80008660 <syscalls+0x158>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	e16080e7          	jalr	-490(ra) # 80000574 <panic>

0000000080003766 <fsinit>:
fsinit(int dev) {
    80003766:	7179                	addi	sp,sp,-48
    80003768:	f406                	sd	ra,40(sp)
    8000376a:	f022                	sd	s0,32(sp)
    8000376c:	ec26                	sd	s1,24(sp)
    8000376e:	e84a                	sd	s2,16(sp)
    80003770:	e44e                	sd	s3,8(sp)
    80003772:	1800                	addi	s0,sp,48
    80003774:	89aa                	mv	s3,a0
  bp = bread(dev, 1);
    80003776:	4585                	li	a1,1
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	a20080e7          	jalr	-1504(ra) # 80003198 <bread>
    80003780:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003782:	0001d497          	auipc	s1,0x1d
    80003786:	8be48493          	addi	s1,s1,-1858 # 80020040 <sb>
    8000378a:	02000613          	li	a2,32
    8000378e:	05850593          	addi	a1,a0,88
    80003792:	8526                	mv	a0,s1
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	636080e7          	jalr	1590(ra) # 80000dca <memmove>
  brelse(bp);
    8000379c:	854a                	mv	a0,s2
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	b3c080e7          	jalr	-1220(ra) # 800032da <brelse>
  if(sb.magic != FSMAGIC)
    800037a6:	4098                	lw	a4,0(s1)
    800037a8:	102037b7          	lui	a5,0x10203
    800037ac:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037b0:	02f71263          	bne	a4,a5,800037d4 <fsinit+0x6e>
  initlog(dev, &sb);
    800037b4:	0001d597          	auipc	a1,0x1d
    800037b8:	88c58593          	addi	a1,a1,-1908 # 80020040 <sb>
    800037bc:	854e                	mv	a0,s3
    800037be:	00001097          	auipc	ra,0x1
    800037c2:	b48080e7          	jalr	-1208(ra) # 80004306 <initlog>
}
    800037c6:	70a2                	ld	ra,40(sp)
    800037c8:	7402                	ld	s0,32(sp)
    800037ca:	64e2                	ld	s1,24(sp)
    800037cc:	6942                	ld	s2,16(sp)
    800037ce:	69a2                	ld	s3,8(sp)
    800037d0:	6145                	addi	sp,sp,48
    800037d2:	8082                	ret
    panic("invalid file system");
    800037d4:	00005517          	auipc	a0,0x5
    800037d8:	e9c50513          	addi	a0,a0,-356 # 80008670 <syscalls+0x168>
    800037dc:	ffffd097          	auipc	ra,0xffffd
    800037e0:	d98080e7          	jalr	-616(ra) # 80000574 <panic>

00000000800037e4 <iinit>:
{
    800037e4:	7179                	addi	sp,sp,-48
    800037e6:	f406                	sd	ra,40(sp)
    800037e8:	f022                	sd	s0,32(sp)
    800037ea:	ec26                	sd	s1,24(sp)
    800037ec:	e84a                	sd	s2,16(sp)
    800037ee:	e44e                	sd	s3,8(sp)
    800037f0:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800037f2:	00005597          	auipc	a1,0x5
    800037f6:	e9658593          	addi	a1,a1,-362 # 80008688 <syscalls+0x180>
    800037fa:	0001d517          	auipc	a0,0x1d
    800037fe:	86650513          	addi	a0,a0,-1946 # 80020060 <icache>
    80003802:	ffffd097          	auipc	ra,0xffffd
    80003806:	3d0080e7          	jalr	976(ra) # 80000bd2 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000380a:	0001d497          	auipc	s1,0x1d
    8000380e:	87e48493          	addi	s1,s1,-1922 # 80020088 <icache+0x28>
    80003812:	0001e997          	auipc	s3,0x1e
    80003816:	30698993          	addi	s3,s3,774 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000381a:	00005917          	auipc	s2,0x5
    8000381e:	e7690913          	addi	s2,s2,-394 # 80008690 <syscalls+0x188>
    80003822:	85ca                	mv	a1,s2
    80003824:	8526                	mv	a0,s1
    80003826:	00001097          	auipc	ra,0x1
    8000382a:	e62080e7          	jalr	-414(ra) # 80004688 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000382e:	08848493          	addi	s1,s1,136
    80003832:	ff3498e3          	bne	s1,s3,80003822 <iinit+0x3e>
}
    80003836:	70a2                	ld	ra,40(sp)
    80003838:	7402                	ld	s0,32(sp)
    8000383a:	64e2                	ld	s1,24(sp)
    8000383c:	6942                	ld	s2,16(sp)
    8000383e:	69a2                	ld	s3,8(sp)
    80003840:	6145                	addi	sp,sp,48
    80003842:	8082                	ret

0000000080003844 <ialloc>:
{
    80003844:	715d                	addi	sp,sp,-80
    80003846:	e486                	sd	ra,72(sp)
    80003848:	e0a2                	sd	s0,64(sp)
    8000384a:	fc26                	sd	s1,56(sp)
    8000384c:	f84a                	sd	s2,48(sp)
    8000384e:	f44e                	sd	s3,40(sp)
    80003850:	f052                	sd	s4,32(sp)
    80003852:	ec56                	sd	s5,24(sp)
    80003854:	e85a                	sd	s6,16(sp)
    80003856:	e45e                	sd	s7,8(sp)
    80003858:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000385a:	0001c797          	auipc	a5,0x1c
    8000385e:	7e678793          	addi	a5,a5,2022 # 80020040 <sb>
    80003862:	47d8                	lw	a4,12(a5)
    80003864:	4785                	li	a5,1
    80003866:	04e7fa63          	bleu	a4,a5,800038ba <ialloc+0x76>
    8000386a:	8a2a                	mv	s4,a0
    8000386c:	8b2e                	mv	s6,a1
    8000386e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003870:	0001c997          	auipc	s3,0x1c
    80003874:	7d098993          	addi	s3,s3,2000 # 80020040 <sb>
    80003878:	00048a9b          	sext.w	s5,s1
    8000387c:	0044d593          	srli	a1,s1,0x4
    80003880:	0189a783          	lw	a5,24(s3)
    80003884:	9dbd                	addw	a1,a1,a5
    80003886:	8552                	mv	a0,s4
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	910080e7          	jalr	-1776(ra) # 80003198 <bread>
    80003890:	8baa                	mv	s7,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003892:	05850913          	addi	s2,a0,88
    80003896:	00f4f793          	andi	a5,s1,15
    8000389a:	079a                	slli	a5,a5,0x6
    8000389c:	993e                	add	s2,s2,a5
    if(dip->type == 0){  // a free inode
    8000389e:	00091783          	lh	a5,0(s2)
    800038a2:	c785                	beqz	a5,800038ca <ialloc+0x86>
    brelse(bp);
    800038a4:	00000097          	auipc	ra,0x0
    800038a8:	a36080e7          	jalr	-1482(ra) # 800032da <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038ac:	0485                	addi	s1,s1,1
    800038ae:	00c9a703          	lw	a4,12(s3)
    800038b2:	0004879b          	sext.w	a5,s1
    800038b6:	fce7e1e3          	bltu	a5,a4,80003878 <ialloc+0x34>
  panic("ialloc: no inodes");
    800038ba:	00005517          	auipc	a0,0x5
    800038be:	dde50513          	addi	a0,a0,-546 # 80008698 <syscalls+0x190>
    800038c2:	ffffd097          	auipc	ra,0xffffd
    800038c6:	cb2080e7          	jalr	-846(ra) # 80000574 <panic>
      memset(dip, 0, sizeof(*dip));
    800038ca:	04000613          	li	a2,64
    800038ce:	4581                	li	a1,0
    800038d0:	854a                	mv	a0,s2
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	48c080e7          	jalr	1164(ra) # 80000d5e <memset>
      dip->type = type;
    800038da:	01691023          	sh	s6,0(s2)
      log_write(bp);   // mark it allocated on the disk
    800038de:	855e                	mv	a0,s7
    800038e0:	00001097          	auipc	ra,0x1
    800038e4:	ca4080e7          	jalr	-860(ra) # 80004584 <log_write>
      brelse(bp);
    800038e8:	855e                	mv	a0,s7
    800038ea:	00000097          	auipc	ra,0x0
    800038ee:	9f0080e7          	jalr	-1552(ra) # 800032da <brelse>
      return iget(dev, inum);
    800038f2:	85d6                	mv	a1,s5
    800038f4:	8552                	mv	a0,s4
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	db4080e7          	jalr	-588(ra) # 800036aa <iget>
}
    800038fe:	60a6                	ld	ra,72(sp)
    80003900:	6406                	ld	s0,64(sp)
    80003902:	74e2                	ld	s1,56(sp)
    80003904:	7942                	ld	s2,48(sp)
    80003906:	79a2                	ld	s3,40(sp)
    80003908:	7a02                	ld	s4,32(sp)
    8000390a:	6ae2                	ld	s5,24(sp)
    8000390c:	6b42                	ld	s6,16(sp)
    8000390e:	6ba2                	ld	s7,8(sp)
    80003910:	6161                	addi	sp,sp,80
    80003912:	8082                	ret

0000000080003914 <iupdate>:
{
    80003914:	1101                	addi	sp,sp,-32
    80003916:	ec06                	sd	ra,24(sp)
    80003918:	e822                	sd	s0,16(sp)
    8000391a:	e426                	sd	s1,8(sp)
    8000391c:	e04a                	sd	s2,0(sp)
    8000391e:	1000                	addi	s0,sp,32
    80003920:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003922:	415c                	lw	a5,4(a0)
    80003924:	0047d79b          	srliw	a5,a5,0x4
    80003928:	0001c717          	auipc	a4,0x1c
    8000392c:	71870713          	addi	a4,a4,1816 # 80020040 <sb>
    80003930:	4f0c                	lw	a1,24(a4)
    80003932:	9dbd                	addw	a1,a1,a5
    80003934:	4108                	lw	a0,0(a0)
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	862080e7          	jalr	-1950(ra) # 80003198 <bread>
    8000393e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003940:	05850513          	addi	a0,a0,88
    80003944:	40dc                	lw	a5,4(s1)
    80003946:	8bbd                	andi	a5,a5,15
    80003948:	079a                	slli	a5,a5,0x6
    8000394a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000394c:	04449783          	lh	a5,68(s1)
    80003950:	00f51023          	sh	a5,0(a0)
  dip->major = ip->major;
    80003954:	04649783          	lh	a5,70(s1)
    80003958:	00f51123          	sh	a5,2(a0)
  dip->minor = ip->minor;
    8000395c:	04849783          	lh	a5,72(s1)
    80003960:	00f51223          	sh	a5,4(a0)
  dip->nlink = ip->nlink;
    80003964:	04a49783          	lh	a5,74(s1)
    80003968:	00f51323          	sh	a5,6(a0)
  dip->size = ip->size;
    8000396c:	44fc                	lw	a5,76(s1)
    8000396e:	c51c                	sw	a5,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003970:	03400613          	li	a2,52
    80003974:	05048593          	addi	a1,s1,80
    80003978:	0531                	addi	a0,a0,12
    8000397a:	ffffd097          	auipc	ra,0xffffd
    8000397e:	450080e7          	jalr	1104(ra) # 80000dca <memmove>
  log_write(bp);
    80003982:	854a                	mv	a0,s2
    80003984:	00001097          	auipc	ra,0x1
    80003988:	c00080e7          	jalr	-1024(ra) # 80004584 <log_write>
  brelse(bp);
    8000398c:	854a                	mv	a0,s2
    8000398e:	00000097          	auipc	ra,0x0
    80003992:	94c080e7          	jalr	-1716(ra) # 800032da <brelse>
}
    80003996:	60e2                	ld	ra,24(sp)
    80003998:	6442                	ld	s0,16(sp)
    8000399a:	64a2                	ld	s1,8(sp)
    8000399c:	6902                	ld	s2,0(sp)
    8000399e:	6105                	addi	sp,sp,32
    800039a0:	8082                	ret

00000000800039a2 <idup>:
{
    800039a2:	1101                	addi	sp,sp,-32
    800039a4:	ec06                	sd	ra,24(sp)
    800039a6:	e822                	sd	s0,16(sp)
    800039a8:	e426                	sd	s1,8(sp)
    800039aa:	1000                	addi	s0,sp,32
    800039ac:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039ae:	0001c517          	auipc	a0,0x1c
    800039b2:	6b250513          	addi	a0,a0,1714 # 80020060 <icache>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	2ac080e7          	jalr	684(ra) # 80000c62 <acquire>
  ip->ref++;
    800039be:	449c                	lw	a5,8(s1)
    800039c0:	2785                	addiw	a5,a5,1
    800039c2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039c4:	0001c517          	auipc	a0,0x1c
    800039c8:	69c50513          	addi	a0,a0,1692 # 80020060 <icache>
    800039cc:	ffffd097          	auipc	ra,0xffffd
    800039d0:	34a080e7          	jalr	842(ra) # 80000d16 <release>
}
    800039d4:	8526                	mv	a0,s1
    800039d6:	60e2                	ld	ra,24(sp)
    800039d8:	6442                	ld	s0,16(sp)
    800039da:	64a2                	ld	s1,8(sp)
    800039dc:	6105                	addi	sp,sp,32
    800039de:	8082                	ret

00000000800039e0 <ilock>:
{
    800039e0:	1101                	addi	sp,sp,-32
    800039e2:	ec06                	sd	ra,24(sp)
    800039e4:	e822                	sd	s0,16(sp)
    800039e6:	e426                	sd	s1,8(sp)
    800039e8:	e04a                	sd	s2,0(sp)
    800039ea:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039ec:	c115                	beqz	a0,80003a10 <ilock+0x30>
    800039ee:	84aa                	mv	s1,a0
    800039f0:	451c                	lw	a5,8(a0)
    800039f2:	00f05f63          	blez	a5,80003a10 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039f6:	0541                	addi	a0,a0,16
    800039f8:	00001097          	auipc	ra,0x1
    800039fc:	cca080e7          	jalr	-822(ra) # 800046c2 <acquiresleep>
  if(ip->valid == 0){
    80003a00:	40bc                	lw	a5,64(s1)
    80003a02:	cf99                	beqz	a5,80003a20 <ilock+0x40>
}
    80003a04:	60e2                	ld	ra,24(sp)
    80003a06:	6442                	ld	s0,16(sp)
    80003a08:	64a2                	ld	s1,8(sp)
    80003a0a:	6902                	ld	s2,0(sp)
    80003a0c:	6105                	addi	sp,sp,32
    80003a0e:	8082                	ret
    panic("ilock");
    80003a10:	00005517          	auipc	a0,0x5
    80003a14:	ca050513          	addi	a0,a0,-864 # 800086b0 <syscalls+0x1a8>
    80003a18:	ffffd097          	auipc	ra,0xffffd
    80003a1c:	b5c080e7          	jalr	-1188(ra) # 80000574 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a20:	40dc                	lw	a5,4(s1)
    80003a22:	0047d79b          	srliw	a5,a5,0x4
    80003a26:	0001c717          	auipc	a4,0x1c
    80003a2a:	61a70713          	addi	a4,a4,1562 # 80020040 <sb>
    80003a2e:	4f0c                	lw	a1,24(a4)
    80003a30:	9dbd                	addw	a1,a1,a5
    80003a32:	4088                	lw	a0,0(s1)
    80003a34:	fffff097          	auipc	ra,0xfffff
    80003a38:	764080e7          	jalr	1892(ra) # 80003198 <bread>
    80003a3c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a3e:	05850593          	addi	a1,a0,88
    80003a42:	40dc                	lw	a5,4(s1)
    80003a44:	8bbd                	andi	a5,a5,15
    80003a46:	079a                	slli	a5,a5,0x6
    80003a48:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a4a:	00059783          	lh	a5,0(a1)
    80003a4e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a52:	00259783          	lh	a5,2(a1)
    80003a56:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a5a:	00459783          	lh	a5,4(a1)
    80003a5e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a62:	00659783          	lh	a5,6(a1)
    80003a66:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a6a:	459c                	lw	a5,8(a1)
    80003a6c:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a6e:	03400613          	li	a2,52
    80003a72:	05b1                	addi	a1,a1,12
    80003a74:	05048513          	addi	a0,s1,80
    80003a78:	ffffd097          	auipc	ra,0xffffd
    80003a7c:	352080e7          	jalr	850(ra) # 80000dca <memmove>
    brelse(bp);
    80003a80:	854a                	mv	a0,s2
    80003a82:	00000097          	auipc	ra,0x0
    80003a86:	858080e7          	jalr	-1960(ra) # 800032da <brelse>
    ip->valid = 1;
    80003a8a:	4785                	li	a5,1
    80003a8c:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a8e:	04449783          	lh	a5,68(s1)
    80003a92:	fbad                	bnez	a5,80003a04 <ilock+0x24>
      panic("ilock: no type");
    80003a94:	00005517          	auipc	a0,0x5
    80003a98:	c2450513          	addi	a0,a0,-988 # 800086b8 <syscalls+0x1b0>
    80003a9c:	ffffd097          	auipc	ra,0xffffd
    80003aa0:	ad8080e7          	jalr	-1320(ra) # 80000574 <panic>

0000000080003aa4 <iunlock>:
{
    80003aa4:	1101                	addi	sp,sp,-32
    80003aa6:	ec06                	sd	ra,24(sp)
    80003aa8:	e822                	sd	s0,16(sp)
    80003aaa:	e426                	sd	s1,8(sp)
    80003aac:	e04a                	sd	s2,0(sp)
    80003aae:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ab0:	c905                	beqz	a0,80003ae0 <iunlock+0x3c>
    80003ab2:	84aa                	mv	s1,a0
    80003ab4:	01050913          	addi	s2,a0,16
    80003ab8:	854a                	mv	a0,s2
    80003aba:	00001097          	auipc	ra,0x1
    80003abe:	ca2080e7          	jalr	-862(ra) # 8000475c <holdingsleep>
    80003ac2:	cd19                	beqz	a0,80003ae0 <iunlock+0x3c>
    80003ac4:	449c                	lw	a5,8(s1)
    80003ac6:	00f05d63          	blez	a5,80003ae0 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003aca:	854a                	mv	a0,s2
    80003acc:	00001097          	auipc	ra,0x1
    80003ad0:	c4c080e7          	jalr	-948(ra) # 80004718 <releasesleep>
}
    80003ad4:	60e2                	ld	ra,24(sp)
    80003ad6:	6442                	ld	s0,16(sp)
    80003ad8:	64a2                	ld	s1,8(sp)
    80003ada:	6902                	ld	s2,0(sp)
    80003adc:	6105                	addi	sp,sp,32
    80003ade:	8082                	ret
    panic("iunlock");
    80003ae0:	00005517          	auipc	a0,0x5
    80003ae4:	be850513          	addi	a0,a0,-1048 # 800086c8 <syscalls+0x1c0>
    80003ae8:	ffffd097          	auipc	ra,0xffffd
    80003aec:	a8c080e7          	jalr	-1396(ra) # 80000574 <panic>

0000000080003af0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003af0:	7179                	addi	sp,sp,-48
    80003af2:	f406                	sd	ra,40(sp)
    80003af4:	f022                	sd	s0,32(sp)
    80003af6:	ec26                	sd	s1,24(sp)
    80003af8:	e84a                	sd	s2,16(sp)
    80003afa:	e44e                	sd	s3,8(sp)
    80003afc:	e052                	sd	s4,0(sp)
    80003afe:	1800                	addi	s0,sp,48
    80003b00:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b02:	05050493          	addi	s1,a0,80
    80003b06:	08050913          	addi	s2,a0,128
    80003b0a:	a821                	j	80003b22 <itrunc+0x32>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    80003b0c:	0009a503          	lw	a0,0(s3)
    80003b10:	00000097          	auipc	ra,0x0
    80003b14:	8e0080e7          	jalr	-1824(ra) # 800033f0 <bfree>
      ip->addrs[i] = 0;
    80003b18:	0004a023          	sw	zero,0(s1)
  for(i = 0; i < NDIRECT; i++){
    80003b1c:	0491                	addi	s1,s1,4
    80003b1e:	01248563          	beq	s1,s2,80003b28 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b22:	408c                	lw	a1,0(s1)
    80003b24:	dde5                	beqz	a1,80003b1c <itrunc+0x2c>
    80003b26:	b7dd                	j	80003b0c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b28:	0809a583          	lw	a1,128(s3)
    80003b2c:	e185                	bnez	a1,80003b4c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b2e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b32:	854e                	mv	a0,s3
    80003b34:	00000097          	auipc	ra,0x0
    80003b38:	de0080e7          	jalr	-544(ra) # 80003914 <iupdate>
}
    80003b3c:	70a2                	ld	ra,40(sp)
    80003b3e:	7402                	ld	s0,32(sp)
    80003b40:	64e2                	ld	s1,24(sp)
    80003b42:	6942                	ld	s2,16(sp)
    80003b44:	69a2                	ld	s3,8(sp)
    80003b46:	6a02                	ld	s4,0(sp)
    80003b48:	6145                	addi	sp,sp,48
    80003b4a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b4c:	0009a503          	lw	a0,0(s3)
    80003b50:	fffff097          	auipc	ra,0xfffff
    80003b54:	648080e7          	jalr	1608(ra) # 80003198 <bread>
    80003b58:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b5a:	05850493          	addi	s1,a0,88
    80003b5e:	45850913          	addi	s2,a0,1112
    80003b62:	a811                	j	80003b76 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b64:	0009a503          	lw	a0,0(s3)
    80003b68:	00000097          	auipc	ra,0x0
    80003b6c:	888080e7          	jalr	-1912(ra) # 800033f0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b70:	0491                	addi	s1,s1,4
    80003b72:	01248563          	beq	s1,s2,80003b7c <itrunc+0x8c>
      if(a[j])
    80003b76:	408c                	lw	a1,0(s1)
    80003b78:	dde5                	beqz	a1,80003b70 <itrunc+0x80>
    80003b7a:	b7ed                	j	80003b64 <itrunc+0x74>
    brelse(bp);
    80003b7c:	8552                	mv	a0,s4
    80003b7e:	fffff097          	auipc	ra,0xfffff
    80003b82:	75c080e7          	jalr	1884(ra) # 800032da <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b86:	0809a583          	lw	a1,128(s3)
    80003b8a:	0009a503          	lw	a0,0(s3)
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	862080e7          	jalr	-1950(ra) # 800033f0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b96:	0809a023          	sw	zero,128(s3)
    80003b9a:	bf51                	j	80003b2e <itrunc+0x3e>

0000000080003b9c <iput>:
{
    80003b9c:	1101                	addi	sp,sp,-32
    80003b9e:	ec06                	sd	ra,24(sp)
    80003ba0:	e822                	sd	s0,16(sp)
    80003ba2:	e426                	sd	s1,8(sp)
    80003ba4:	e04a                	sd	s2,0(sp)
    80003ba6:	1000                	addi	s0,sp,32
    80003ba8:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003baa:	0001c517          	auipc	a0,0x1c
    80003bae:	4b650513          	addi	a0,a0,1206 # 80020060 <icache>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	0b0080e7          	jalr	176(ra) # 80000c62 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bba:	4498                	lw	a4,8(s1)
    80003bbc:	4785                	li	a5,1
    80003bbe:	02f70363          	beq	a4,a5,80003be4 <iput+0x48>
  ip->ref--;
    80003bc2:	449c                	lw	a5,8(s1)
    80003bc4:	37fd                	addiw	a5,a5,-1
    80003bc6:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003bc8:	0001c517          	auipc	a0,0x1c
    80003bcc:	49850513          	addi	a0,a0,1176 # 80020060 <icache>
    80003bd0:	ffffd097          	auipc	ra,0xffffd
    80003bd4:	146080e7          	jalr	326(ra) # 80000d16 <release>
}
    80003bd8:	60e2                	ld	ra,24(sp)
    80003bda:	6442                	ld	s0,16(sp)
    80003bdc:	64a2                	ld	s1,8(sp)
    80003bde:	6902                	ld	s2,0(sp)
    80003be0:	6105                	addi	sp,sp,32
    80003be2:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003be4:	40bc                	lw	a5,64(s1)
    80003be6:	dff1                	beqz	a5,80003bc2 <iput+0x26>
    80003be8:	04a49783          	lh	a5,74(s1)
    80003bec:	fbf9                	bnez	a5,80003bc2 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bee:	01048913          	addi	s2,s1,16
    80003bf2:	854a                	mv	a0,s2
    80003bf4:	00001097          	auipc	ra,0x1
    80003bf8:	ace080e7          	jalr	-1330(ra) # 800046c2 <acquiresleep>
    release(&icache.lock);
    80003bfc:	0001c517          	auipc	a0,0x1c
    80003c00:	46450513          	addi	a0,a0,1124 # 80020060 <icache>
    80003c04:	ffffd097          	auipc	ra,0xffffd
    80003c08:	112080e7          	jalr	274(ra) # 80000d16 <release>
    itrunc(ip);
    80003c0c:	8526                	mv	a0,s1
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	ee2080e7          	jalr	-286(ra) # 80003af0 <itrunc>
    ip->type = 0;
    80003c16:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c1a:	8526                	mv	a0,s1
    80003c1c:	00000097          	auipc	ra,0x0
    80003c20:	cf8080e7          	jalr	-776(ra) # 80003914 <iupdate>
    ip->valid = 0;
    80003c24:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c28:	854a                	mv	a0,s2
    80003c2a:	00001097          	auipc	ra,0x1
    80003c2e:	aee080e7          	jalr	-1298(ra) # 80004718 <releasesleep>
    acquire(&icache.lock);
    80003c32:	0001c517          	auipc	a0,0x1c
    80003c36:	42e50513          	addi	a0,a0,1070 # 80020060 <icache>
    80003c3a:	ffffd097          	auipc	ra,0xffffd
    80003c3e:	028080e7          	jalr	40(ra) # 80000c62 <acquire>
    80003c42:	b741                	j	80003bc2 <iput+0x26>

0000000080003c44 <iunlockput>:
{
    80003c44:	1101                	addi	sp,sp,-32
    80003c46:	ec06                	sd	ra,24(sp)
    80003c48:	e822                	sd	s0,16(sp)
    80003c4a:	e426                	sd	s1,8(sp)
    80003c4c:	1000                	addi	s0,sp,32
    80003c4e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	e54080e7          	jalr	-428(ra) # 80003aa4 <iunlock>
  iput(ip);
    80003c58:	8526                	mv	a0,s1
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	f42080e7          	jalr	-190(ra) # 80003b9c <iput>
}
    80003c62:	60e2                	ld	ra,24(sp)
    80003c64:	6442                	ld	s0,16(sp)
    80003c66:	64a2                	ld	s1,8(sp)
    80003c68:	6105                	addi	sp,sp,32
    80003c6a:	8082                	ret

0000000080003c6c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c6c:	1141                	addi	sp,sp,-16
    80003c6e:	e422                	sd	s0,8(sp)
    80003c70:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c72:	411c                	lw	a5,0(a0)
    80003c74:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c76:	415c                	lw	a5,4(a0)
    80003c78:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c7a:	04451783          	lh	a5,68(a0)
    80003c7e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c82:	04a51783          	lh	a5,74(a0)
    80003c86:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c8a:	04c56783          	lwu	a5,76(a0)
    80003c8e:	e99c                	sd	a5,16(a1)
}
    80003c90:	6422                	ld	s0,8(sp)
    80003c92:	0141                	addi	sp,sp,16
    80003c94:	8082                	ret

0000000080003c96 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c96:	457c                	lw	a5,76(a0)
    80003c98:	0ed7e863          	bltu	a5,a3,80003d88 <readi+0xf2>
{
    80003c9c:	7159                	addi	sp,sp,-112
    80003c9e:	f486                	sd	ra,104(sp)
    80003ca0:	f0a2                	sd	s0,96(sp)
    80003ca2:	eca6                	sd	s1,88(sp)
    80003ca4:	e8ca                	sd	s2,80(sp)
    80003ca6:	e4ce                	sd	s3,72(sp)
    80003ca8:	e0d2                	sd	s4,64(sp)
    80003caa:	fc56                	sd	s5,56(sp)
    80003cac:	f85a                	sd	s6,48(sp)
    80003cae:	f45e                	sd	s7,40(sp)
    80003cb0:	f062                	sd	s8,32(sp)
    80003cb2:	ec66                	sd	s9,24(sp)
    80003cb4:	e86a                	sd	s10,16(sp)
    80003cb6:	e46e                	sd	s11,8(sp)
    80003cb8:	1880                	addi	s0,sp,112
    80003cba:	8baa                	mv	s7,a0
    80003cbc:	8c2e                	mv	s8,a1
    80003cbe:	8a32                	mv	s4,a2
    80003cc0:	84b6                	mv	s1,a3
    80003cc2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cc4:	9f35                	addw	a4,a4,a3
    return 0;
    80003cc6:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cc8:	08d76f63          	bltu	a4,a3,80003d66 <readi+0xd0>
  if(off + n > ip->size)
    80003ccc:	00e7f463          	bleu	a4,a5,80003cd4 <readi+0x3e>
    n = ip->size - off;
    80003cd0:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cd4:	0a0b0863          	beqz	s6,80003d84 <readi+0xee>
    80003cd8:	4901                	li	s2,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cda:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cde:	5cfd                	li	s9,-1
    80003ce0:	a82d                	j	80003d1a <readi+0x84>
    80003ce2:	02099d93          	slli	s11,s3,0x20
    80003ce6:	020ddd93          	srli	s11,s11,0x20
    80003cea:	058a8613          	addi	a2,s5,88
    80003cee:	86ee                	mv	a3,s11
    80003cf0:	963a                	add	a2,a2,a4
    80003cf2:	85d2                	mv	a1,s4
    80003cf4:	8562                	mv	a0,s8
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	ad6080e7          	jalr	-1322(ra) # 800027cc <either_copyout>
    80003cfe:	05950d63          	beq	a0,s9,80003d58 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003d02:	8556                	mv	a0,s5
    80003d04:	fffff097          	auipc	ra,0xfffff
    80003d08:	5d6080e7          	jalr	1494(ra) # 800032da <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d0c:	0129893b          	addw	s2,s3,s2
    80003d10:	009984bb          	addw	s1,s3,s1
    80003d14:	9a6e                	add	s4,s4,s11
    80003d16:	05697663          	bleu	s6,s2,80003d62 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003d1a:	000ba983          	lw	s3,0(s7)
    80003d1e:	00a4d59b          	srliw	a1,s1,0xa
    80003d22:	855e                	mv	a0,s7
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	8ac080e7          	jalr	-1876(ra) # 800035d0 <bmap>
    80003d2c:	0005059b          	sext.w	a1,a0
    80003d30:	854e                	mv	a0,s3
    80003d32:	fffff097          	auipc	ra,0xfffff
    80003d36:	466080e7          	jalr	1126(ra) # 80003198 <bread>
    80003d3a:	8aaa                	mv	s5,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d3c:	3ff4f713          	andi	a4,s1,1023
    80003d40:	40ed07bb          	subw	a5,s10,a4
    80003d44:	412b06bb          	subw	a3,s6,s2
    80003d48:	89be                	mv	s3,a5
    80003d4a:	2781                	sext.w	a5,a5
    80003d4c:	0006861b          	sext.w	a2,a3
    80003d50:	f8f679e3          	bleu	a5,a2,80003ce2 <readi+0x4c>
    80003d54:	89b6                	mv	s3,a3
    80003d56:	b771                	j	80003ce2 <readi+0x4c>
      brelse(bp);
    80003d58:	8556                	mv	a0,s5
    80003d5a:	fffff097          	auipc	ra,0xfffff
    80003d5e:	580080e7          	jalr	1408(ra) # 800032da <brelse>
  }
  return tot;
    80003d62:	0009051b          	sext.w	a0,s2
}
    80003d66:	70a6                	ld	ra,104(sp)
    80003d68:	7406                	ld	s0,96(sp)
    80003d6a:	64e6                	ld	s1,88(sp)
    80003d6c:	6946                	ld	s2,80(sp)
    80003d6e:	69a6                	ld	s3,72(sp)
    80003d70:	6a06                	ld	s4,64(sp)
    80003d72:	7ae2                	ld	s5,56(sp)
    80003d74:	7b42                	ld	s6,48(sp)
    80003d76:	7ba2                	ld	s7,40(sp)
    80003d78:	7c02                	ld	s8,32(sp)
    80003d7a:	6ce2                	ld	s9,24(sp)
    80003d7c:	6d42                	ld	s10,16(sp)
    80003d7e:	6da2                	ld	s11,8(sp)
    80003d80:	6165                	addi	sp,sp,112
    80003d82:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d84:	895a                	mv	s2,s6
    80003d86:	bff1                	j	80003d62 <readi+0xcc>
    return 0;
    80003d88:	4501                	li	a0,0
}
    80003d8a:	8082                	ret

0000000080003d8c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d8c:	457c                	lw	a5,76(a0)
    80003d8e:	10d7e663          	bltu	a5,a3,80003e9a <writei+0x10e>
{
    80003d92:	7159                	addi	sp,sp,-112
    80003d94:	f486                	sd	ra,104(sp)
    80003d96:	f0a2                	sd	s0,96(sp)
    80003d98:	eca6                	sd	s1,88(sp)
    80003d9a:	e8ca                	sd	s2,80(sp)
    80003d9c:	e4ce                	sd	s3,72(sp)
    80003d9e:	e0d2                	sd	s4,64(sp)
    80003da0:	fc56                	sd	s5,56(sp)
    80003da2:	f85a                	sd	s6,48(sp)
    80003da4:	f45e                	sd	s7,40(sp)
    80003da6:	f062                	sd	s8,32(sp)
    80003da8:	ec66                	sd	s9,24(sp)
    80003daa:	e86a                	sd	s10,16(sp)
    80003dac:	e46e                	sd	s11,8(sp)
    80003dae:	1880                	addi	s0,sp,112
    80003db0:	8baa                	mv	s7,a0
    80003db2:	8c2e                	mv	s8,a1
    80003db4:	8ab2                	mv	s5,a2
    80003db6:	84b6                	mv	s1,a3
    80003db8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dba:	00e687bb          	addw	a5,a3,a4
    80003dbe:	0ed7e063          	bltu	a5,a3,80003e9e <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003dc2:	00043737          	lui	a4,0x43
    80003dc6:	0cf76e63          	bltu	a4,a5,80003ea2 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dca:	0a0b0763          	beqz	s6,80003e78 <writei+0xec>
    80003dce:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dd0:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003dd4:	5cfd                	li	s9,-1
    80003dd6:	a091                	j	80003e1a <writei+0x8e>
    80003dd8:	02091d93          	slli	s11,s2,0x20
    80003ddc:	020ddd93          	srli	s11,s11,0x20
    80003de0:	05898513          	addi	a0,s3,88
    80003de4:	86ee                	mv	a3,s11
    80003de6:	8656                	mv	a2,s5
    80003de8:	85e2                	mv	a1,s8
    80003dea:	953a                	add	a0,a0,a4
    80003dec:	fffff097          	auipc	ra,0xfffff
    80003df0:	a36080e7          	jalr	-1482(ra) # 80002822 <either_copyin>
    80003df4:	07950263          	beq	a0,s9,80003e58 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003df8:	854e                	mv	a0,s3
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	78a080e7          	jalr	1930(ra) # 80004584 <log_write>
    brelse(bp);
    80003e02:	854e                	mv	a0,s3
    80003e04:	fffff097          	auipc	ra,0xfffff
    80003e08:	4d6080e7          	jalr	1238(ra) # 800032da <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e0c:	01490a3b          	addw	s4,s2,s4
    80003e10:	009904bb          	addw	s1,s2,s1
    80003e14:	9aee                	add	s5,s5,s11
    80003e16:	056a7663          	bleu	s6,s4,80003e62 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003e1a:	000ba903          	lw	s2,0(s7)
    80003e1e:	00a4d59b          	srliw	a1,s1,0xa
    80003e22:	855e                	mv	a0,s7
    80003e24:	fffff097          	auipc	ra,0xfffff
    80003e28:	7ac080e7          	jalr	1964(ra) # 800035d0 <bmap>
    80003e2c:	0005059b          	sext.w	a1,a0
    80003e30:	854a                	mv	a0,s2
    80003e32:	fffff097          	auipc	ra,0xfffff
    80003e36:	366080e7          	jalr	870(ra) # 80003198 <bread>
    80003e3a:	89aa                	mv	s3,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e3c:	3ff4f713          	andi	a4,s1,1023
    80003e40:	40ed07bb          	subw	a5,s10,a4
    80003e44:	414b06bb          	subw	a3,s6,s4
    80003e48:	893e                	mv	s2,a5
    80003e4a:	2781                	sext.w	a5,a5
    80003e4c:	0006861b          	sext.w	a2,a3
    80003e50:	f8f674e3          	bleu	a5,a2,80003dd8 <writei+0x4c>
    80003e54:	8936                	mv	s2,a3
    80003e56:	b749                	j	80003dd8 <writei+0x4c>
      brelse(bp);
    80003e58:	854e                	mv	a0,s3
    80003e5a:	fffff097          	auipc	ra,0xfffff
    80003e5e:	480080e7          	jalr	1152(ra) # 800032da <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003e62:	04cba783          	lw	a5,76(s7)
    80003e66:	0097f463          	bleu	s1,a5,80003e6e <writei+0xe2>
      ip->size = off;
    80003e6a:	049ba623          	sw	s1,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e6e:	855e                	mv	a0,s7
    80003e70:	00000097          	auipc	ra,0x0
    80003e74:	aa4080e7          	jalr	-1372(ra) # 80003914 <iupdate>
  }

  return n;
    80003e78:	000b051b          	sext.w	a0,s6
}
    80003e7c:	70a6                	ld	ra,104(sp)
    80003e7e:	7406                	ld	s0,96(sp)
    80003e80:	64e6                	ld	s1,88(sp)
    80003e82:	6946                	ld	s2,80(sp)
    80003e84:	69a6                	ld	s3,72(sp)
    80003e86:	6a06                	ld	s4,64(sp)
    80003e88:	7ae2                	ld	s5,56(sp)
    80003e8a:	7b42                	ld	s6,48(sp)
    80003e8c:	7ba2                	ld	s7,40(sp)
    80003e8e:	7c02                	ld	s8,32(sp)
    80003e90:	6ce2                	ld	s9,24(sp)
    80003e92:	6d42                	ld	s10,16(sp)
    80003e94:	6da2                	ld	s11,8(sp)
    80003e96:	6165                	addi	sp,sp,112
    80003e98:	8082                	ret
    return -1;
    80003e9a:	557d                	li	a0,-1
}
    80003e9c:	8082                	ret
    return -1;
    80003e9e:	557d                	li	a0,-1
    80003ea0:	bff1                	j	80003e7c <writei+0xf0>
    return -1;
    80003ea2:	557d                	li	a0,-1
    80003ea4:	bfe1                	j	80003e7c <writei+0xf0>

0000000080003ea6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003ea6:	1141                	addi	sp,sp,-16
    80003ea8:	e406                	sd	ra,8(sp)
    80003eaa:	e022                	sd	s0,0(sp)
    80003eac:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003eae:	4639                	li	a2,14
    80003eb0:	ffffd097          	auipc	ra,0xffffd
    80003eb4:	f96080e7          	jalr	-106(ra) # 80000e46 <strncmp>
}
    80003eb8:	60a2                	ld	ra,8(sp)
    80003eba:	6402                	ld	s0,0(sp)
    80003ebc:	0141                	addi	sp,sp,16
    80003ebe:	8082                	ret

0000000080003ec0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ec0:	7139                	addi	sp,sp,-64
    80003ec2:	fc06                	sd	ra,56(sp)
    80003ec4:	f822                	sd	s0,48(sp)
    80003ec6:	f426                	sd	s1,40(sp)
    80003ec8:	f04a                	sd	s2,32(sp)
    80003eca:	ec4e                	sd	s3,24(sp)
    80003ecc:	e852                	sd	s4,16(sp)
    80003ece:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ed0:	04451703          	lh	a4,68(a0)
    80003ed4:	4785                	li	a5,1
    80003ed6:	00f71a63          	bne	a4,a5,80003eea <dirlookup+0x2a>
    80003eda:	892a                	mv	s2,a0
    80003edc:	89ae                	mv	s3,a1
    80003ede:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee0:	457c                	lw	a5,76(a0)
    80003ee2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ee4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee6:	e79d                	bnez	a5,80003f14 <dirlookup+0x54>
    80003ee8:	a8a5                	j	80003f60 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003eea:	00004517          	auipc	a0,0x4
    80003eee:	7e650513          	addi	a0,a0,2022 # 800086d0 <syscalls+0x1c8>
    80003ef2:	ffffc097          	auipc	ra,0xffffc
    80003ef6:	682080e7          	jalr	1666(ra) # 80000574 <panic>
      panic("dirlookup read");
    80003efa:	00004517          	auipc	a0,0x4
    80003efe:	7ee50513          	addi	a0,a0,2030 # 800086e8 <syscalls+0x1e0>
    80003f02:	ffffc097          	auipc	ra,0xffffc
    80003f06:	672080e7          	jalr	1650(ra) # 80000574 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f0a:	24c1                	addiw	s1,s1,16
    80003f0c:	04c92783          	lw	a5,76(s2)
    80003f10:	04f4f763          	bleu	a5,s1,80003f5e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f14:	4741                	li	a4,16
    80003f16:	86a6                	mv	a3,s1
    80003f18:	fc040613          	addi	a2,s0,-64
    80003f1c:	4581                	li	a1,0
    80003f1e:	854a                	mv	a0,s2
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	d76080e7          	jalr	-650(ra) # 80003c96 <readi>
    80003f28:	47c1                	li	a5,16
    80003f2a:	fcf518e3          	bne	a0,a5,80003efa <dirlookup+0x3a>
    if(de.inum == 0)
    80003f2e:	fc045783          	lhu	a5,-64(s0)
    80003f32:	dfe1                	beqz	a5,80003f0a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f34:	fc240593          	addi	a1,s0,-62
    80003f38:	854e                	mv	a0,s3
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	f6c080e7          	jalr	-148(ra) # 80003ea6 <namecmp>
    80003f42:	f561                	bnez	a0,80003f0a <dirlookup+0x4a>
      if(poff)
    80003f44:	000a0463          	beqz	s4,80003f4c <dirlookup+0x8c>
        *poff = off;
    80003f48:	009a2023          	sw	s1,0(s4) # 2000 <_entry-0x7fffe000>
      return iget(dp->dev, inum);
    80003f4c:	fc045583          	lhu	a1,-64(s0)
    80003f50:	00092503          	lw	a0,0(s2)
    80003f54:	fffff097          	auipc	ra,0xfffff
    80003f58:	756080e7          	jalr	1878(ra) # 800036aa <iget>
    80003f5c:	a011                	j	80003f60 <dirlookup+0xa0>
  return 0;
    80003f5e:	4501                	li	a0,0
}
    80003f60:	70e2                	ld	ra,56(sp)
    80003f62:	7442                	ld	s0,48(sp)
    80003f64:	74a2                	ld	s1,40(sp)
    80003f66:	7902                	ld	s2,32(sp)
    80003f68:	69e2                	ld	s3,24(sp)
    80003f6a:	6a42                	ld	s4,16(sp)
    80003f6c:	6121                	addi	sp,sp,64
    80003f6e:	8082                	ret

0000000080003f70 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f70:	711d                	addi	sp,sp,-96
    80003f72:	ec86                	sd	ra,88(sp)
    80003f74:	e8a2                	sd	s0,80(sp)
    80003f76:	e4a6                	sd	s1,72(sp)
    80003f78:	e0ca                	sd	s2,64(sp)
    80003f7a:	fc4e                	sd	s3,56(sp)
    80003f7c:	f852                	sd	s4,48(sp)
    80003f7e:	f456                	sd	s5,40(sp)
    80003f80:	f05a                	sd	s6,32(sp)
    80003f82:	ec5e                	sd	s7,24(sp)
    80003f84:	e862                	sd	s8,16(sp)
    80003f86:	e466                	sd	s9,8(sp)
    80003f88:	1080                	addi	s0,sp,96
    80003f8a:	84aa                	mv	s1,a0
    80003f8c:	8bae                	mv	s7,a1
    80003f8e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f90:	00054703          	lbu	a4,0(a0)
    80003f94:	02f00793          	li	a5,47
    80003f98:	02f70363          	beq	a4,a5,80003fbe <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f9c:	ffffe097          	auipc	ra,0xffffe
    80003fa0:	bbc080e7          	jalr	-1092(ra) # 80001b58 <myproc>
    80003fa4:	15053503          	ld	a0,336(a0)
    80003fa8:	00000097          	auipc	ra,0x0
    80003fac:	9fa080e7          	jalr	-1542(ra) # 800039a2 <idup>
    80003fb0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003fb2:	02f00913          	li	s2,47
  len = path - s;
    80003fb6:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003fb8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fba:	4c05                	li	s8,1
    80003fbc:	a865                	j	80004074 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fbe:	4585                	li	a1,1
    80003fc0:	4505                	li	a0,1
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	6e8080e7          	jalr	1768(ra) # 800036aa <iget>
    80003fca:	89aa                	mv	s3,a0
    80003fcc:	b7dd                	j	80003fb2 <namex+0x42>
      iunlockput(ip);
    80003fce:	854e                	mv	a0,s3
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	c74080e7          	jalr	-908(ra) # 80003c44 <iunlockput>
      return 0;
    80003fd8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fda:	854e                	mv	a0,s3
    80003fdc:	60e6                	ld	ra,88(sp)
    80003fde:	6446                	ld	s0,80(sp)
    80003fe0:	64a6                	ld	s1,72(sp)
    80003fe2:	6906                	ld	s2,64(sp)
    80003fe4:	79e2                	ld	s3,56(sp)
    80003fe6:	7a42                	ld	s4,48(sp)
    80003fe8:	7aa2                	ld	s5,40(sp)
    80003fea:	7b02                	ld	s6,32(sp)
    80003fec:	6be2                	ld	s7,24(sp)
    80003fee:	6c42                	ld	s8,16(sp)
    80003ff0:	6ca2                	ld	s9,8(sp)
    80003ff2:	6125                	addi	sp,sp,96
    80003ff4:	8082                	ret
      iunlock(ip);
    80003ff6:	854e                	mv	a0,s3
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	aac080e7          	jalr	-1364(ra) # 80003aa4 <iunlock>
      return ip;
    80004000:	bfe9                	j	80003fda <namex+0x6a>
      iunlockput(ip);
    80004002:	854e                	mv	a0,s3
    80004004:	00000097          	auipc	ra,0x0
    80004008:	c40080e7          	jalr	-960(ra) # 80003c44 <iunlockput>
      return 0;
    8000400c:	89d2                	mv	s3,s4
    8000400e:	b7f1                	j	80003fda <namex+0x6a>
  len = path - s;
    80004010:	40b48633          	sub	a2,s1,a1
    80004014:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004018:	094cd663          	ble	s4,s9,800040a4 <namex+0x134>
    memmove(name, s, DIRSIZ);
    8000401c:	4639                	li	a2,14
    8000401e:	8556                	mv	a0,s5
    80004020:	ffffd097          	auipc	ra,0xffffd
    80004024:	daa080e7          	jalr	-598(ra) # 80000dca <memmove>
  while(*path == '/')
    80004028:	0004c783          	lbu	a5,0(s1)
    8000402c:	01279763          	bne	a5,s2,8000403a <namex+0xca>
    path++;
    80004030:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004032:	0004c783          	lbu	a5,0(s1)
    80004036:	ff278de3          	beq	a5,s2,80004030 <namex+0xc0>
    ilock(ip);
    8000403a:	854e                	mv	a0,s3
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	9a4080e7          	jalr	-1628(ra) # 800039e0 <ilock>
    if(ip->type != T_DIR){
    80004044:	04499783          	lh	a5,68(s3)
    80004048:	f98793e3          	bne	a5,s8,80003fce <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000404c:	000b8563          	beqz	s7,80004056 <namex+0xe6>
    80004050:	0004c783          	lbu	a5,0(s1)
    80004054:	d3cd                	beqz	a5,80003ff6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004056:	865a                	mv	a2,s6
    80004058:	85d6                	mv	a1,s5
    8000405a:	854e                	mv	a0,s3
    8000405c:	00000097          	auipc	ra,0x0
    80004060:	e64080e7          	jalr	-412(ra) # 80003ec0 <dirlookup>
    80004064:	8a2a                	mv	s4,a0
    80004066:	dd51                	beqz	a0,80004002 <namex+0x92>
    iunlockput(ip);
    80004068:	854e                	mv	a0,s3
    8000406a:	00000097          	auipc	ra,0x0
    8000406e:	bda080e7          	jalr	-1062(ra) # 80003c44 <iunlockput>
    ip = next;
    80004072:	89d2                	mv	s3,s4
  while(*path == '/')
    80004074:	0004c783          	lbu	a5,0(s1)
    80004078:	05279d63          	bne	a5,s2,800040d2 <namex+0x162>
    path++;
    8000407c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000407e:	0004c783          	lbu	a5,0(s1)
    80004082:	ff278de3          	beq	a5,s2,8000407c <namex+0x10c>
  if(*path == 0)
    80004086:	cf8d                	beqz	a5,800040c0 <namex+0x150>
  while(*path != '/' && *path != 0)
    80004088:	01278b63          	beq	a5,s2,8000409e <namex+0x12e>
    8000408c:	c795                	beqz	a5,800040b8 <namex+0x148>
    path++;
    8000408e:	85a6                	mv	a1,s1
    path++;
    80004090:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004092:	0004c783          	lbu	a5,0(s1)
    80004096:	f7278de3          	beq	a5,s2,80004010 <namex+0xa0>
    8000409a:	fbfd                	bnez	a5,80004090 <namex+0x120>
    8000409c:	bf95                	j	80004010 <namex+0xa0>
    8000409e:	85a6                	mv	a1,s1
  len = path - s;
    800040a0:	8a5a                	mv	s4,s6
    800040a2:	865a                	mv	a2,s6
    memmove(name, s, len);
    800040a4:	2601                	sext.w	a2,a2
    800040a6:	8556                	mv	a0,s5
    800040a8:	ffffd097          	auipc	ra,0xffffd
    800040ac:	d22080e7          	jalr	-734(ra) # 80000dca <memmove>
    name[len] = 0;
    800040b0:	9a56                	add	s4,s4,s5
    800040b2:	000a0023          	sb	zero,0(s4)
    800040b6:	bf8d                	j	80004028 <namex+0xb8>
  while(*path != '/' && *path != 0)
    800040b8:	85a6                	mv	a1,s1
  len = path - s;
    800040ba:	8a5a                	mv	s4,s6
    800040bc:	865a                	mv	a2,s6
    800040be:	b7dd                	j	800040a4 <namex+0x134>
  if(nameiparent){
    800040c0:	f00b8de3          	beqz	s7,80003fda <namex+0x6a>
    iput(ip);
    800040c4:	854e                	mv	a0,s3
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	ad6080e7          	jalr	-1322(ra) # 80003b9c <iput>
    return 0;
    800040ce:	4981                	li	s3,0
    800040d0:	b729                	j	80003fda <namex+0x6a>
  if(*path == 0)
    800040d2:	d7fd                	beqz	a5,800040c0 <namex+0x150>
    800040d4:	85a6                	mv	a1,s1
    800040d6:	bf6d                	j	80004090 <namex+0x120>

00000000800040d8 <dirlink>:
{
    800040d8:	7139                	addi	sp,sp,-64
    800040da:	fc06                	sd	ra,56(sp)
    800040dc:	f822                	sd	s0,48(sp)
    800040de:	f426                	sd	s1,40(sp)
    800040e0:	f04a                	sd	s2,32(sp)
    800040e2:	ec4e                	sd	s3,24(sp)
    800040e4:	e852                	sd	s4,16(sp)
    800040e6:	0080                	addi	s0,sp,64
    800040e8:	892a                	mv	s2,a0
    800040ea:	8a2e                	mv	s4,a1
    800040ec:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040ee:	4601                	li	a2,0
    800040f0:	00000097          	auipc	ra,0x0
    800040f4:	dd0080e7          	jalr	-560(ra) # 80003ec0 <dirlookup>
    800040f8:	e93d                	bnez	a0,8000416e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040fa:	04c92483          	lw	s1,76(s2)
    800040fe:	c49d                	beqz	s1,8000412c <dirlink+0x54>
    80004100:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004102:	4741                	li	a4,16
    80004104:	86a6                	mv	a3,s1
    80004106:	fc040613          	addi	a2,s0,-64
    8000410a:	4581                	li	a1,0
    8000410c:	854a                	mv	a0,s2
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	b88080e7          	jalr	-1144(ra) # 80003c96 <readi>
    80004116:	47c1                	li	a5,16
    80004118:	06f51163          	bne	a0,a5,8000417a <dirlink+0xa2>
    if(de.inum == 0)
    8000411c:	fc045783          	lhu	a5,-64(s0)
    80004120:	c791                	beqz	a5,8000412c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004122:	24c1                	addiw	s1,s1,16
    80004124:	04c92783          	lw	a5,76(s2)
    80004128:	fcf4ede3          	bltu	s1,a5,80004102 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000412c:	4639                	li	a2,14
    8000412e:	85d2                	mv	a1,s4
    80004130:	fc240513          	addi	a0,s0,-62
    80004134:	ffffd097          	auipc	ra,0xffffd
    80004138:	d62080e7          	jalr	-670(ra) # 80000e96 <strncpy>
  de.inum = inum;
    8000413c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004140:	4741                	li	a4,16
    80004142:	86a6                	mv	a3,s1
    80004144:	fc040613          	addi	a2,s0,-64
    80004148:	4581                	li	a1,0
    8000414a:	854a                	mv	a0,s2
    8000414c:	00000097          	auipc	ra,0x0
    80004150:	c40080e7          	jalr	-960(ra) # 80003d8c <writei>
    80004154:	4741                	li	a4,16
  return 0;
    80004156:	4781                	li	a5,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004158:	02e51963          	bne	a0,a4,8000418a <dirlink+0xb2>
}
    8000415c:	853e                	mv	a0,a5
    8000415e:	70e2                	ld	ra,56(sp)
    80004160:	7442                	ld	s0,48(sp)
    80004162:	74a2                	ld	s1,40(sp)
    80004164:	7902                	ld	s2,32(sp)
    80004166:	69e2                	ld	s3,24(sp)
    80004168:	6a42                	ld	s4,16(sp)
    8000416a:	6121                	addi	sp,sp,64
    8000416c:	8082                	ret
    iput(ip);
    8000416e:	00000097          	auipc	ra,0x0
    80004172:	a2e080e7          	jalr	-1490(ra) # 80003b9c <iput>
    return -1;
    80004176:	57fd                	li	a5,-1
    80004178:	b7d5                	j	8000415c <dirlink+0x84>
      panic("dirlink read");
    8000417a:	00004517          	auipc	a0,0x4
    8000417e:	57e50513          	addi	a0,a0,1406 # 800086f8 <syscalls+0x1f0>
    80004182:	ffffc097          	auipc	ra,0xffffc
    80004186:	3f2080e7          	jalr	1010(ra) # 80000574 <panic>
    panic("dirlink");
    8000418a:	00004517          	auipc	a0,0x4
    8000418e:	68650513          	addi	a0,a0,1670 # 80008810 <syscalls+0x308>
    80004192:	ffffc097          	auipc	ra,0xffffc
    80004196:	3e2080e7          	jalr	994(ra) # 80000574 <panic>

000000008000419a <namei>:

struct inode*
namei(char *path)
{
    8000419a:	1101                	addi	sp,sp,-32
    8000419c:	ec06                	sd	ra,24(sp)
    8000419e:	e822                	sd	s0,16(sp)
    800041a0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800041a2:	fe040613          	addi	a2,s0,-32
    800041a6:	4581                	li	a1,0
    800041a8:	00000097          	auipc	ra,0x0
    800041ac:	dc8080e7          	jalr	-568(ra) # 80003f70 <namex>
}
    800041b0:	60e2                	ld	ra,24(sp)
    800041b2:	6442                	ld	s0,16(sp)
    800041b4:	6105                	addi	sp,sp,32
    800041b6:	8082                	ret

00000000800041b8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041b8:	1141                	addi	sp,sp,-16
    800041ba:	e406                	sd	ra,8(sp)
    800041bc:	e022                	sd	s0,0(sp)
    800041be:	0800                	addi	s0,sp,16
  return namex(path, 1, name);
    800041c0:	862e                	mv	a2,a1
    800041c2:	4585                	li	a1,1
    800041c4:	00000097          	auipc	ra,0x0
    800041c8:	dac080e7          	jalr	-596(ra) # 80003f70 <namex>
}
    800041cc:	60a2                	ld	ra,8(sp)
    800041ce:	6402                	ld	s0,0(sp)
    800041d0:	0141                	addi	sp,sp,16
    800041d2:	8082                	ret

00000000800041d4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041d4:	1101                	addi	sp,sp,-32
    800041d6:	ec06                	sd	ra,24(sp)
    800041d8:	e822                	sd	s0,16(sp)
    800041da:	e426                	sd	s1,8(sp)
    800041dc:	e04a                	sd	s2,0(sp)
    800041de:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041e0:	0001e917          	auipc	s2,0x1e
    800041e4:	92890913          	addi	s2,s2,-1752 # 80021b08 <log>
    800041e8:	01892583          	lw	a1,24(s2)
    800041ec:	02892503          	lw	a0,40(s2)
    800041f0:	fffff097          	auipc	ra,0xfffff
    800041f4:	fa8080e7          	jalr	-88(ra) # 80003198 <bread>
    800041f8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041fa:	02c92683          	lw	a3,44(s2)
    800041fe:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004200:	02d05763          	blez	a3,8000422e <write_head+0x5a>
    80004204:	0001e797          	auipc	a5,0x1e
    80004208:	93478793          	addi	a5,a5,-1740 # 80021b38 <log+0x30>
    8000420c:	05c50713          	addi	a4,a0,92
    80004210:	36fd                	addiw	a3,a3,-1
    80004212:	1682                	slli	a3,a3,0x20
    80004214:	9281                	srli	a3,a3,0x20
    80004216:	068a                	slli	a3,a3,0x2
    80004218:	0001e617          	auipc	a2,0x1e
    8000421c:	92460613          	addi	a2,a2,-1756 # 80021b3c <log+0x34>
    80004220:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004222:	4390                	lw	a2,0(a5)
    80004224:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004226:	0791                	addi	a5,a5,4
    80004228:	0711                	addi	a4,a4,4
    8000422a:	fed79ce3          	bne	a5,a3,80004222 <write_head+0x4e>
  }
  bwrite(buf);
    8000422e:	8526                	mv	a0,s1
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	06c080e7          	jalr	108(ra) # 8000329c <bwrite>
  brelse(buf);
    80004238:	8526                	mv	a0,s1
    8000423a:	fffff097          	auipc	ra,0xfffff
    8000423e:	0a0080e7          	jalr	160(ra) # 800032da <brelse>
}
    80004242:	60e2                	ld	ra,24(sp)
    80004244:	6442                	ld	s0,16(sp)
    80004246:	64a2                	ld	s1,8(sp)
    80004248:	6902                	ld	s2,0(sp)
    8000424a:	6105                	addi	sp,sp,32
    8000424c:	8082                	ret

000000008000424e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000424e:	0001e797          	auipc	a5,0x1e
    80004252:	8ba78793          	addi	a5,a5,-1862 # 80021b08 <log>
    80004256:	57dc                	lw	a5,44(a5)
    80004258:	0af05663          	blez	a5,80004304 <install_trans+0xb6>
{
    8000425c:	7139                	addi	sp,sp,-64
    8000425e:	fc06                	sd	ra,56(sp)
    80004260:	f822                	sd	s0,48(sp)
    80004262:	f426                	sd	s1,40(sp)
    80004264:	f04a                	sd	s2,32(sp)
    80004266:	ec4e                	sd	s3,24(sp)
    80004268:	e852                	sd	s4,16(sp)
    8000426a:	e456                	sd	s5,8(sp)
    8000426c:	0080                	addi	s0,sp,64
    8000426e:	0001ea17          	auipc	s4,0x1e
    80004272:	8caa0a13          	addi	s4,s4,-1846 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004276:	4981                	li	s3,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004278:	0001e917          	auipc	s2,0x1e
    8000427c:	89090913          	addi	s2,s2,-1904 # 80021b08 <log>
    80004280:	01892583          	lw	a1,24(s2)
    80004284:	013585bb          	addw	a1,a1,s3
    80004288:	2585                	addiw	a1,a1,1
    8000428a:	02892503          	lw	a0,40(s2)
    8000428e:	fffff097          	auipc	ra,0xfffff
    80004292:	f0a080e7          	jalr	-246(ra) # 80003198 <bread>
    80004296:	8aaa                	mv	s5,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004298:	000a2583          	lw	a1,0(s4)
    8000429c:	02892503          	lw	a0,40(s2)
    800042a0:	fffff097          	auipc	ra,0xfffff
    800042a4:	ef8080e7          	jalr	-264(ra) # 80003198 <bread>
    800042a8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042aa:	40000613          	li	a2,1024
    800042ae:	058a8593          	addi	a1,s5,88
    800042b2:	05850513          	addi	a0,a0,88
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	b14080e7          	jalr	-1260(ra) # 80000dca <memmove>
    bwrite(dbuf);  // write dst to disk
    800042be:	8526                	mv	a0,s1
    800042c0:	fffff097          	auipc	ra,0xfffff
    800042c4:	fdc080e7          	jalr	-36(ra) # 8000329c <bwrite>
    bunpin(dbuf);
    800042c8:	8526                	mv	a0,s1
    800042ca:	fffff097          	auipc	ra,0xfffff
    800042ce:	0ea080e7          	jalr	234(ra) # 800033b4 <bunpin>
    brelse(lbuf);
    800042d2:	8556                	mv	a0,s5
    800042d4:	fffff097          	auipc	ra,0xfffff
    800042d8:	006080e7          	jalr	6(ra) # 800032da <brelse>
    brelse(dbuf);
    800042dc:	8526                	mv	a0,s1
    800042de:	fffff097          	auipc	ra,0xfffff
    800042e2:	ffc080e7          	jalr	-4(ra) # 800032da <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e6:	2985                	addiw	s3,s3,1
    800042e8:	0a11                	addi	s4,s4,4
    800042ea:	02c92783          	lw	a5,44(s2)
    800042ee:	f8f9c9e3          	blt	s3,a5,80004280 <install_trans+0x32>
}
    800042f2:	70e2                	ld	ra,56(sp)
    800042f4:	7442                	ld	s0,48(sp)
    800042f6:	74a2                	ld	s1,40(sp)
    800042f8:	7902                	ld	s2,32(sp)
    800042fa:	69e2                	ld	s3,24(sp)
    800042fc:	6a42                	ld	s4,16(sp)
    800042fe:	6aa2                	ld	s5,8(sp)
    80004300:	6121                	addi	sp,sp,64
    80004302:	8082                	ret
    80004304:	8082                	ret

0000000080004306 <initlog>:
{
    80004306:	7179                	addi	sp,sp,-48
    80004308:	f406                	sd	ra,40(sp)
    8000430a:	f022                	sd	s0,32(sp)
    8000430c:	ec26                	sd	s1,24(sp)
    8000430e:	e84a                	sd	s2,16(sp)
    80004310:	e44e                	sd	s3,8(sp)
    80004312:	1800                	addi	s0,sp,48
    80004314:	892a                	mv	s2,a0
    80004316:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004318:	0001d497          	auipc	s1,0x1d
    8000431c:	7f048493          	addi	s1,s1,2032 # 80021b08 <log>
    80004320:	00004597          	auipc	a1,0x4
    80004324:	3e858593          	addi	a1,a1,1000 # 80008708 <syscalls+0x200>
    80004328:	8526                	mv	a0,s1
    8000432a:	ffffd097          	auipc	ra,0xffffd
    8000432e:	8a8080e7          	jalr	-1880(ra) # 80000bd2 <initlock>
  log.start = sb->logstart;
    80004332:	0149a583          	lw	a1,20(s3)
    80004336:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004338:	0109a783          	lw	a5,16(s3)
    8000433c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000433e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004342:	854a                	mv	a0,s2
    80004344:	fffff097          	auipc	ra,0xfffff
    80004348:	e54080e7          	jalr	-428(ra) # 80003198 <bread>
  log.lh.n = lh->n;
    8000434c:	4d3c                	lw	a5,88(a0)
    8000434e:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004350:	02f05563          	blez	a5,8000437a <initlog+0x74>
    80004354:	05c50713          	addi	a4,a0,92
    80004358:	0001d697          	auipc	a3,0x1d
    8000435c:	7e068693          	addi	a3,a3,2016 # 80021b38 <log+0x30>
    80004360:	37fd                	addiw	a5,a5,-1
    80004362:	1782                	slli	a5,a5,0x20
    80004364:	9381                	srli	a5,a5,0x20
    80004366:	078a                	slli	a5,a5,0x2
    80004368:	06050613          	addi	a2,a0,96
    8000436c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000436e:	4310                	lw	a2,0(a4)
    80004370:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004372:	0711                	addi	a4,a4,4
    80004374:	0691                	addi	a3,a3,4
    80004376:	fef71ce3          	bne	a4,a5,8000436e <initlog+0x68>
  brelse(buf);
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	f60080e7          	jalr	-160(ra) # 800032da <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004382:	00000097          	auipc	ra,0x0
    80004386:	ecc080e7          	jalr	-308(ra) # 8000424e <install_trans>
  log.lh.n = 0;
    8000438a:	0001d797          	auipc	a5,0x1d
    8000438e:	7a07a523          	sw	zero,1962(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    80004392:	00000097          	auipc	ra,0x0
    80004396:	e42080e7          	jalr	-446(ra) # 800041d4 <write_head>
}
    8000439a:	70a2                	ld	ra,40(sp)
    8000439c:	7402                	ld	s0,32(sp)
    8000439e:	64e2                	ld	s1,24(sp)
    800043a0:	6942                	ld	s2,16(sp)
    800043a2:	69a2                	ld	s3,8(sp)
    800043a4:	6145                	addi	sp,sp,48
    800043a6:	8082                	ret

00000000800043a8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043a8:	1101                	addi	sp,sp,-32
    800043aa:	ec06                	sd	ra,24(sp)
    800043ac:	e822                	sd	s0,16(sp)
    800043ae:	e426                	sd	s1,8(sp)
    800043b0:	e04a                	sd	s2,0(sp)
    800043b2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043b4:	0001d517          	auipc	a0,0x1d
    800043b8:	75450513          	addi	a0,a0,1876 # 80021b08 <log>
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	8a6080e7          	jalr	-1882(ra) # 80000c62 <acquire>
  while(1){
    if(log.committing){
    800043c4:	0001d497          	auipc	s1,0x1d
    800043c8:	74448493          	addi	s1,s1,1860 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043cc:	4979                	li	s2,30
    800043ce:	a039                	j	800043dc <begin_op+0x34>
      sleep(&log, &log.lock);
    800043d0:	85a6                	mv	a1,s1
    800043d2:	8526                	mv	a0,s1
    800043d4:	ffffe097          	auipc	ra,0xffffe
    800043d8:	196080e7          	jalr	406(ra) # 8000256a <sleep>
    if(log.committing){
    800043dc:	50dc                	lw	a5,36(s1)
    800043de:	fbed                	bnez	a5,800043d0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043e0:	509c                	lw	a5,32(s1)
    800043e2:	0017871b          	addiw	a4,a5,1
    800043e6:	0007069b          	sext.w	a3,a4
    800043ea:	0027179b          	slliw	a5,a4,0x2
    800043ee:	9fb9                	addw	a5,a5,a4
    800043f0:	0017979b          	slliw	a5,a5,0x1
    800043f4:	54d8                	lw	a4,44(s1)
    800043f6:	9fb9                	addw	a5,a5,a4
    800043f8:	00f95963          	ble	a5,s2,8000440a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043fc:	85a6                	mv	a1,s1
    800043fe:	8526                	mv	a0,s1
    80004400:	ffffe097          	auipc	ra,0xffffe
    80004404:	16a080e7          	jalr	362(ra) # 8000256a <sleep>
    80004408:	bfd1                	j	800043dc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000440a:	0001d517          	auipc	a0,0x1d
    8000440e:	6fe50513          	addi	a0,a0,1790 # 80021b08 <log>
    80004412:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	902080e7          	jalr	-1790(ra) # 80000d16 <release>
      break;
    }
  }
}
    8000441c:	60e2                	ld	ra,24(sp)
    8000441e:	6442                	ld	s0,16(sp)
    80004420:	64a2                	ld	s1,8(sp)
    80004422:	6902                	ld	s2,0(sp)
    80004424:	6105                	addi	sp,sp,32
    80004426:	8082                	ret

0000000080004428 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004428:	7139                	addi	sp,sp,-64
    8000442a:	fc06                	sd	ra,56(sp)
    8000442c:	f822                	sd	s0,48(sp)
    8000442e:	f426                	sd	s1,40(sp)
    80004430:	f04a                	sd	s2,32(sp)
    80004432:	ec4e                	sd	s3,24(sp)
    80004434:	e852                	sd	s4,16(sp)
    80004436:	e456                	sd	s5,8(sp)
    80004438:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000443a:	0001d917          	auipc	s2,0x1d
    8000443e:	6ce90913          	addi	s2,s2,1742 # 80021b08 <log>
    80004442:	854a                	mv	a0,s2
    80004444:	ffffd097          	auipc	ra,0xffffd
    80004448:	81e080e7          	jalr	-2018(ra) # 80000c62 <acquire>
  log.outstanding -= 1;
    8000444c:	02092783          	lw	a5,32(s2)
    80004450:	37fd                	addiw	a5,a5,-1
    80004452:	0007849b          	sext.w	s1,a5
    80004456:	02f92023          	sw	a5,32(s2)
  if(log.committing)
    8000445a:	02492783          	lw	a5,36(s2)
    8000445e:	eba1                	bnez	a5,800044ae <end_op+0x86>
    panic("log.committing");
  if(log.outstanding == 0){
    80004460:	ecb9                	bnez	s1,800044be <end_op+0x96>
    do_commit = 1;
    log.committing = 1;
    80004462:	0001d917          	auipc	s2,0x1d
    80004466:	6a690913          	addi	s2,s2,1702 # 80021b08 <log>
    8000446a:	4785                	li	a5,1
    8000446c:	02f92223          	sw	a5,36(s2)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004470:	854a                	mv	a0,s2
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	8a4080e7          	jalr	-1884(ra) # 80000d16 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000447a:	02c92783          	lw	a5,44(s2)
    8000447e:	06f04763          	bgtz	a5,800044ec <end_op+0xc4>
    acquire(&log.lock);
    80004482:	0001d497          	auipc	s1,0x1d
    80004486:	68648493          	addi	s1,s1,1670 # 80021b08 <log>
    8000448a:	8526                	mv	a0,s1
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	7d6080e7          	jalr	2006(ra) # 80000c62 <acquire>
    log.committing = 0;
    80004494:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004498:	8526                	mv	a0,s1
    8000449a:	ffffe097          	auipc	ra,0xffffe
    8000449e:	256080e7          	jalr	598(ra) # 800026f0 <wakeup>
    release(&log.lock);
    800044a2:	8526                	mv	a0,s1
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	872080e7          	jalr	-1934(ra) # 80000d16 <release>
}
    800044ac:	a03d                	j	800044da <end_op+0xb2>
    panic("log.committing");
    800044ae:	00004517          	auipc	a0,0x4
    800044b2:	26250513          	addi	a0,a0,610 # 80008710 <syscalls+0x208>
    800044b6:	ffffc097          	auipc	ra,0xffffc
    800044ba:	0be080e7          	jalr	190(ra) # 80000574 <panic>
    wakeup(&log);
    800044be:	0001d497          	auipc	s1,0x1d
    800044c2:	64a48493          	addi	s1,s1,1610 # 80021b08 <log>
    800044c6:	8526                	mv	a0,s1
    800044c8:	ffffe097          	auipc	ra,0xffffe
    800044cc:	228080e7          	jalr	552(ra) # 800026f0 <wakeup>
  release(&log.lock);
    800044d0:	8526                	mv	a0,s1
    800044d2:	ffffd097          	auipc	ra,0xffffd
    800044d6:	844080e7          	jalr	-1980(ra) # 80000d16 <release>
}
    800044da:	70e2                	ld	ra,56(sp)
    800044dc:	7442                	ld	s0,48(sp)
    800044de:	74a2                	ld	s1,40(sp)
    800044e0:	7902                	ld	s2,32(sp)
    800044e2:	69e2                	ld	s3,24(sp)
    800044e4:	6a42                	ld	s4,16(sp)
    800044e6:	6aa2                	ld	s5,8(sp)
    800044e8:	6121                	addi	sp,sp,64
    800044ea:	8082                	ret
    800044ec:	0001da17          	auipc	s4,0x1d
    800044f0:	64ca0a13          	addi	s4,s4,1612 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044f4:	0001d917          	auipc	s2,0x1d
    800044f8:	61490913          	addi	s2,s2,1556 # 80021b08 <log>
    800044fc:	01892583          	lw	a1,24(s2)
    80004500:	9da5                	addw	a1,a1,s1
    80004502:	2585                	addiw	a1,a1,1
    80004504:	02892503          	lw	a0,40(s2)
    80004508:	fffff097          	auipc	ra,0xfffff
    8000450c:	c90080e7          	jalr	-880(ra) # 80003198 <bread>
    80004510:	89aa                	mv	s3,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004512:	000a2583          	lw	a1,0(s4)
    80004516:	02892503          	lw	a0,40(s2)
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	c7e080e7          	jalr	-898(ra) # 80003198 <bread>
    80004522:	8aaa                	mv	s5,a0
    memmove(to->data, from->data, BSIZE);
    80004524:	40000613          	li	a2,1024
    80004528:	05850593          	addi	a1,a0,88
    8000452c:	05898513          	addi	a0,s3,88
    80004530:	ffffd097          	auipc	ra,0xffffd
    80004534:	89a080e7          	jalr	-1894(ra) # 80000dca <memmove>
    bwrite(to);  // write the log
    80004538:	854e                	mv	a0,s3
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	d62080e7          	jalr	-670(ra) # 8000329c <bwrite>
    brelse(from);
    80004542:	8556                	mv	a0,s5
    80004544:	fffff097          	auipc	ra,0xfffff
    80004548:	d96080e7          	jalr	-618(ra) # 800032da <brelse>
    brelse(to);
    8000454c:	854e                	mv	a0,s3
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	d8c080e7          	jalr	-628(ra) # 800032da <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004556:	2485                	addiw	s1,s1,1
    80004558:	0a11                	addi	s4,s4,4
    8000455a:	02c92783          	lw	a5,44(s2)
    8000455e:	f8f4cfe3          	blt	s1,a5,800044fc <end_op+0xd4>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004562:	00000097          	auipc	ra,0x0
    80004566:	c72080e7          	jalr	-910(ra) # 800041d4 <write_head>
    install_trans(); // Now install writes to home locations
    8000456a:	00000097          	auipc	ra,0x0
    8000456e:	ce4080e7          	jalr	-796(ra) # 8000424e <install_trans>
    log.lh.n = 0;
    80004572:	0001d797          	auipc	a5,0x1d
    80004576:	5c07a123          	sw	zero,1474(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000457a:	00000097          	auipc	ra,0x0
    8000457e:	c5a080e7          	jalr	-934(ra) # 800041d4 <write_head>
    80004582:	b701                	j	80004482 <end_op+0x5a>

0000000080004584 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004584:	1101                	addi	sp,sp,-32
    80004586:	ec06                	sd	ra,24(sp)
    80004588:	e822                	sd	s0,16(sp)
    8000458a:	e426                	sd	s1,8(sp)
    8000458c:	e04a                	sd	s2,0(sp)
    8000458e:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004590:	0001d797          	auipc	a5,0x1d
    80004594:	57878793          	addi	a5,a5,1400 # 80021b08 <log>
    80004598:	57d8                	lw	a4,44(a5)
    8000459a:	47f5                	li	a5,29
    8000459c:	08e7c563          	blt	a5,a4,80004626 <log_write+0xa2>
    800045a0:	892a                	mv	s2,a0
    800045a2:	0001d797          	auipc	a5,0x1d
    800045a6:	56678793          	addi	a5,a5,1382 # 80021b08 <log>
    800045aa:	4fdc                	lw	a5,28(a5)
    800045ac:	37fd                	addiw	a5,a5,-1
    800045ae:	06f75c63          	ble	a5,a4,80004626 <log_write+0xa2>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045b2:	0001d797          	auipc	a5,0x1d
    800045b6:	55678793          	addi	a5,a5,1366 # 80021b08 <log>
    800045ba:	539c                	lw	a5,32(a5)
    800045bc:	06f05d63          	blez	a5,80004636 <log_write+0xb2>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800045c0:	0001d497          	auipc	s1,0x1d
    800045c4:	54848493          	addi	s1,s1,1352 # 80021b08 <log>
    800045c8:	8526                	mv	a0,s1
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	698080e7          	jalr	1688(ra) # 80000c62 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    800045d2:	54d0                	lw	a2,44(s1)
    800045d4:	0ac05063          	blez	a2,80004674 <log_write+0xf0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045d8:	00c92583          	lw	a1,12(s2)
    800045dc:	589c                	lw	a5,48(s1)
    800045de:	0ab78363          	beq	a5,a1,80004684 <log_write+0x100>
    800045e2:	0001d717          	auipc	a4,0x1d
    800045e6:	55a70713          	addi	a4,a4,1370 # 80021b3c <log+0x34>
  for (i = 0; i < log.lh.n; i++) {
    800045ea:	4781                	li	a5,0
    800045ec:	2785                	addiw	a5,a5,1
    800045ee:	04c78c63          	beq	a5,a2,80004646 <log_write+0xc2>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045f2:	4314                	lw	a3,0(a4)
    800045f4:	0711                	addi	a4,a4,4
    800045f6:	feb69be3          	bne	a3,a1,800045ec <log_write+0x68>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045fa:	07a1                	addi	a5,a5,8
    800045fc:	078a                	slli	a5,a5,0x2
    800045fe:	0001d717          	auipc	a4,0x1d
    80004602:	50a70713          	addi	a4,a4,1290 # 80021b08 <log>
    80004606:	97ba                	add	a5,a5,a4
    80004608:	cb8c                	sw	a1,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    log.lh.n++;
  }
  release(&log.lock);
    8000460a:	0001d517          	auipc	a0,0x1d
    8000460e:	4fe50513          	addi	a0,a0,1278 # 80021b08 <log>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	704080e7          	jalr	1796(ra) # 80000d16 <release>
}
    8000461a:	60e2                	ld	ra,24(sp)
    8000461c:	6442                	ld	s0,16(sp)
    8000461e:	64a2                	ld	s1,8(sp)
    80004620:	6902                	ld	s2,0(sp)
    80004622:	6105                	addi	sp,sp,32
    80004624:	8082                	ret
    panic("too big a transaction");
    80004626:	00004517          	auipc	a0,0x4
    8000462a:	0fa50513          	addi	a0,a0,250 # 80008720 <syscalls+0x218>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	f46080e7          	jalr	-186(ra) # 80000574 <panic>
    panic("log_write outside of trans");
    80004636:	00004517          	auipc	a0,0x4
    8000463a:	10250513          	addi	a0,a0,258 # 80008738 <syscalls+0x230>
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	f36080e7          	jalr	-202(ra) # 80000574 <panic>
  log.lh.block[i] = b->blockno;
    80004646:	0621                	addi	a2,a2,8
    80004648:	060a                	slli	a2,a2,0x2
    8000464a:	0001d797          	auipc	a5,0x1d
    8000464e:	4be78793          	addi	a5,a5,1214 # 80021b08 <log>
    80004652:	963e                	add	a2,a2,a5
    80004654:	00c92783          	lw	a5,12(s2)
    80004658:	ca1c                	sw	a5,16(a2)
    bpin(b);
    8000465a:	854a                	mv	a0,s2
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	d1c080e7          	jalr	-740(ra) # 80003378 <bpin>
    log.lh.n++;
    80004664:	0001d717          	auipc	a4,0x1d
    80004668:	4a470713          	addi	a4,a4,1188 # 80021b08 <log>
    8000466c:	575c                	lw	a5,44(a4)
    8000466e:	2785                	addiw	a5,a5,1
    80004670:	d75c                	sw	a5,44(a4)
    80004672:	bf61                	j	8000460a <log_write+0x86>
  log.lh.block[i] = b->blockno;
    80004674:	00c92783          	lw	a5,12(s2)
    80004678:	0001d717          	auipc	a4,0x1d
    8000467c:	4cf72023          	sw	a5,1216(a4) # 80021b38 <log+0x30>
  if (i == log.lh.n) {  // Add new block to log?
    80004680:	f649                	bnez	a2,8000460a <log_write+0x86>
    80004682:	bfe1                	j	8000465a <log_write+0xd6>
  for (i = 0; i < log.lh.n; i++) {
    80004684:	4781                	li	a5,0
    80004686:	bf95                	j	800045fa <log_write+0x76>

0000000080004688 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004688:	1101                	addi	sp,sp,-32
    8000468a:	ec06                	sd	ra,24(sp)
    8000468c:	e822                	sd	s0,16(sp)
    8000468e:	e426                	sd	s1,8(sp)
    80004690:	e04a                	sd	s2,0(sp)
    80004692:	1000                	addi	s0,sp,32
    80004694:	84aa                	mv	s1,a0
    80004696:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004698:	00004597          	auipc	a1,0x4
    8000469c:	0c058593          	addi	a1,a1,192 # 80008758 <syscalls+0x250>
    800046a0:	0521                	addi	a0,a0,8
    800046a2:	ffffc097          	auipc	ra,0xffffc
    800046a6:	530080e7          	jalr	1328(ra) # 80000bd2 <initlock>
  lk->name = name;
    800046aa:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800046ae:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046b2:	0204a423          	sw	zero,40(s1)
}
    800046b6:	60e2                	ld	ra,24(sp)
    800046b8:	6442                	ld	s0,16(sp)
    800046ba:	64a2                	ld	s1,8(sp)
    800046bc:	6902                	ld	s2,0(sp)
    800046be:	6105                	addi	sp,sp,32
    800046c0:	8082                	ret

00000000800046c2 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046c2:	1101                	addi	sp,sp,-32
    800046c4:	ec06                	sd	ra,24(sp)
    800046c6:	e822                	sd	s0,16(sp)
    800046c8:	e426                	sd	s1,8(sp)
    800046ca:	e04a                	sd	s2,0(sp)
    800046cc:	1000                	addi	s0,sp,32
    800046ce:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046d0:	00850913          	addi	s2,a0,8
    800046d4:	854a                	mv	a0,s2
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	58c080e7          	jalr	1420(ra) # 80000c62 <acquire>
  while (lk->locked) {
    800046de:	409c                	lw	a5,0(s1)
    800046e0:	cb89                	beqz	a5,800046f2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046e2:	85ca                	mv	a1,s2
    800046e4:	8526                	mv	a0,s1
    800046e6:	ffffe097          	auipc	ra,0xffffe
    800046ea:	e84080e7          	jalr	-380(ra) # 8000256a <sleep>
  while (lk->locked) {
    800046ee:	409c                	lw	a5,0(s1)
    800046f0:	fbed                	bnez	a5,800046e2 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046f2:	4785                	li	a5,1
    800046f4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046f6:	ffffd097          	auipc	ra,0xffffd
    800046fa:	462080e7          	jalr	1122(ra) # 80001b58 <myproc>
    800046fe:	5d1c                	lw	a5,56(a0)
    80004700:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004702:	854a                	mv	a0,s2
    80004704:	ffffc097          	auipc	ra,0xffffc
    80004708:	612080e7          	jalr	1554(ra) # 80000d16 <release>
}
    8000470c:	60e2                	ld	ra,24(sp)
    8000470e:	6442                	ld	s0,16(sp)
    80004710:	64a2                	ld	s1,8(sp)
    80004712:	6902                	ld	s2,0(sp)
    80004714:	6105                	addi	sp,sp,32
    80004716:	8082                	ret

0000000080004718 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004718:	1101                	addi	sp,sp,-32
    8000471a:	ec06                	sd	ra,24(sp)
    8000471c:	e822                	sd	s0,16(sp)
    8000471e:	e426                	sd	s1,8(sp)
    80004720:	e04a                	sd	s2,0(sp)
    80004722:	1000                	addi	s0,sp,32
    80004724:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004726:	00850913          	addi	s2,a0,8
    8000472a:	854a                	mv	a0,s2
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	536080e7          	jalr	1334(ra) # 80000c62 <acquire>
  lk->locked = 0;
    80004734:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004738:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000473c:	8526                	mv	a0,s1
    8000473e:	ffffe097          	auipc	ra,0xffffe
    80004742:	fb2080e7          	jalr	-78(ra) # 800026f0 <wakeup>
  release(&lk->lk);
    80004746:	854a                	mv	a0,s2
    80004748:	ffffc097          	auipc	ra,0xffffc
    8000474c:	5ce080e7          	jalr	1486(ra) # 80000d16 <release>
}
    80004750:	60e2                	ld	ra,24(sp)
    80004752:	6442                	ld	s0,16(sp)
    80004754:	64a2                	ld	s1,8(sp)
    80004756:	6902                	ld	s2,0(sp)
    80004758:	6105                	addi	sp,sp,32
    8000475a:	8082                	ret

000000008000475c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000475c:	7179                	addi	sp,sp,-48
    8000475e:	f406                	sd	ra,40(sp)
    80004760:	f022                	sd	s0,32(sp)
    80004762:	ec26                	sd	s1,24(sp)
    80004764:	e84a                	sd	s2,16(sp)
    80004766:	e44e                	sd	s3,8(sp)
    80004768:	1800                	addi	s0,sp,48
    8000476a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000476c:	00850913          	addi	s2,a0,8
    80004770:	854a                	mv	a0,s2
    80004772:	ffffc097          	auipc	ra,0xffffc
    80004776:	4f0080e7          	jalr	1264(ra) # 80000c62 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000477a:	409c                	lw	a5,0(s1)
    8000477c:	ef99                	bnez	a5,8000479a <holdingsleep+0x3e>
    8000477e:	4481                	li	s1,0
  release(&lk->lk);
    80004780:	854a                	mv	a0,s2
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	594080e7          	jalr	1428(ra) # 80000d16 <release>
  return r;
}
    8000478a:	8526                	mv	a0,s1
    8000478c:	70a2                	ld	ra,40(sp)
    8000478e:	7402                	ld	s0,32(sp)
    80004790:	64e2                	ld	s1,24(sp)
    80004792:	6942                	ld	s2,16(sp)
    80004794:	69a2                	ld	s3,8(sp)
    80004796:	6145                	addi	sp,sp,48
    80004798:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000479a:	0284a983          	lw	s3,40(s1)
    8000479e:	ffffd097          	auipc	ra,0xffffd
    800047a2:	3ba080e7          	jalr	954(ra) # 80001b58 <myproc>
    800047a6:	5d04                	lw	s1,56(a0)
    800047a8:	413484b3          	sub	s1,s1,s3
    800047ac:	0014b493          	seqz	s1,s1
    800047b0:	bfc1                	j	80004780 <holdingsleep+0x24>

00000000800047b2 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800047b2:	1141                	addi	sp,sp,-16
    800047b4:	e406                	sd	ra,8(sp)
    800047b6:	e022                	sd	s0,0(sp)
    800047b8:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800047ba:	00004597          	auipc	a1,0x4
    800047be:	fae58593          	addi	a1,a1,-82 # 80008768 <syscalls+0x260>
    800047c2:	0001d517          	auipc	a0,0x1d
    800047c6:	48e50513          	addi	a0,a0,1166 # 80021c50 <ftable>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	408080e7          	jalr	1032(ra) # 80000bd2 <initlock>
}
    800047d2:	60a2                	ld	ra,8(sp)
    800047d4:	6402                	ld	s0,0(sp)
    800047d6:	0141                	addi	sp,sp,16
    800047d8:	8082                	ret

00000000800047da <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047da:	1101                	addi	sp,sp,-32
    800047dc:	ec06                	sd	ra,24(sp)
    800047de:	e822                	sd	s0,16(sp)
    800047e0:	e426                	sd	s1,8(sp)
    800047e2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047e4:	0001d517          	auipc	a0,0x1d
    800047e8:	46c50513          	addi	a0,a0,1132 # 80021c50 <ftable>
    800047ec:	ffffc097          	auipc	ra,0xffffc
    800047f0:	476080e7          	jalr	1142(ra) # 80000c62 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
    800047f4:	0001d797          	auipc	a5,0x1d
    800047f8:	45c78793          	addi	a5,a5,1116 # 80021c50 <ftable>
    800047fc:	4fdc                	lw	a5,28(a5)
    800047fe:	cb8d                	beqz	a5,80004830 <filealloc+0x56>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004800:	0001d497          	auipc	s1,0x1d
    80004804:	49048493          	addi	s1,s1,1168 # 80021c90 <ftable+0x40>
    80004808:	0001e717          	auipc	a4,0x1e
    8000480c:	40070713          	addi	a4,a4,1024 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    80004810:	40dc                	lw	a5,4(s1)
    80004812:	c39d                	beqz	a5,80004838 <filealloc+0x5e>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004814:	02848493          	addi	s1,s1,40
    80004818:	fee49ce3          	bne	s1,a4,80004810 <filealloc+0x36>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000481c:	0001d517          	auipc	a0,0x1d
    80004820:	43450513          	addi	a0,a0,1076 # 80021c50 <ftable>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	4f2080e7          	jalr	1266(ra) # 80000d16 <release>
  return 0;
    8000482c:	4481                	li	s1,0
    8000482e:	a839                	j	8000484c <filealloc+0x72>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004830:	0001d497          	auipc	s1,0x1d
    80004834:	43848493          	addi	s1,s1,1080 # 80021c68 <ftable+0x18>
      f->ref = 1;
    80004838:	4785                	li	a5,1
    8000483a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000483c:	0001d517          	auipc	a0,0x1d
    80004840:	41450513          	addi	a0,a0,1044 # 80021c50 <ftable>
    80004844:	ffffc097          	auipc	ra,0xffffc
    80004848:	4d2080e7          	jalr	1234(ra) # 80000d16 <release>
}
    8000484c:	8526                	mv	a0,s1
    8000484e:	60e2                	ld	ra,24(sp)
    80004850:	6442                	ld	s0,16(sp)
    80004852:	64a2                	ld	s1,8(sp)
    80004854:	6105                	addi	sp,sp,32
    80004856:	8082                	ret

0000000080004858 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004858:	1101                	addi	sp,sp,-32
    8000485a:	ec06                	sd	ra,24(sp)
    8000485c:	e822                	sd	s0,16(sp)
    8000485e:	e426                	sd	s1,8(sp)
    80004860:	1000                	addi	s0,sp,32
    80004862:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004864:	0001d517          	auipc	a0,0x1d
    80004868:	3ec50513          	addi	a0,a0,1004 # 80021c50 <ftable>
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	3f6080e7          	jalr	1014(ra) # 80000c62 <acquire>
  if(f->ref < 1)
    80004874:	40dc                	lw	a5,4(s1)
    80004876:	02f05263          	blez	a5,8000489a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000487a:	2785                	addiw	a5,a5,1
    8000487c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000487e:	0001d517          	auipc	a0,0x1d
    80004882:	3d250513          	addi	a0,a0,978 # 80021c50 <ftable>
    80004886:	ffffc097          	auipc	ra,0xffffc
    8000488a:	490080e7          	jalr	1168(ra) # 80000d16 <release>
  return f;
}
    8000488e:	8526                	mv	a0,s1
    80004890:	60e2                	ld	ra,24(sp)
    80004892:	6442                	ld	s0,16(sp)
    80004894:	64a2                	ld	s1,8(sp)
    80004896:	6105                	addi	sp,sp,32
    80004898:	8082                	ret
    panic("filedup");
    8000489a:	00004517          	auipc	a0,0x4
    8000489e:	ed650513          	addi	a0,a0,-298 # 80008770 <syscalls+0x268>
    800048a2:	ffffc097          	auipc	ra,0xffffc
    800048a6:	cd2080e7          	jalr	-814(ra) # 80000574 <panic>

00000000800048aa <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800048aa:	7139                	addi	sp,sp,-64
    800048ac:	fc06                	sd	ra,56(sp)
    800048ae:	f822                	sd	s0,48(sp)
    800048b0:	f426                	sd	s1,40(sp)
    800048b2:	f04a                	sd	s2,32(sp)
    800048b4:	ec4e                	sd	s3,24(sp)
    800048b6:	e852                	sd	s4,16(sp)
    800048b8:	e456                	sd	s5,8(sp)
    800048ba:	0080                	addi	s0,sp,64
    800048bc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800048be:	0001d517          	auipc	a0,0x1d
    800048c2:	39250513          	addi	a0,a0,914 # 80021c50 <ftable>
    800048c6:	ffffc097          	auipc	ra,0xffffc
    800048ca:	39c080e7          	jalr	924(ra) # 80000c62 <acquire>
  if(f->ref < 1)
    800048ce:	40dc                	lw	a5,4(s1)
    800048d0:	06f05163          	blez	a5,80004932 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048d4:	37fd                	addiw	a5,a5,-1
    800048d6:	0007871b          	sext.w	a4,a5
    800048da:	c0dc                	sw	a5,4(s1)
    800048dc:	06e04363          	bgtz	a4,80004942 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048e0:	0004a903          	lw	s2,0(s1)
    800048e4:	0094ca83          	lbu	s5,9(s1)
    800048e8:	0104ba03          	ld	s4,16(s1)
    800048ec:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048f0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048f4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048f8:	0001d517          	auipc	a0,0x1d
    800048fc:	35850513          	addi	a0,a0,856 # 80021c50 <ftable>
    80004900:	ffffc097          	auipc	ra,0xffffc
    80004904:	416080e7          	jalr	1046(ra) # 80000d16 <release>

  if(ff.type == FD_PIPE){
    80004908:	4785                	li	a5,1
    8000490a:	04f90d63          	beq	s2,a5,80004964 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000490e:	3979                	addiw	s2,s2,-2
    80004910:	4785                	li	a5,1
    80004912:	0527e063          	bltu	a5,s2,80004952 <fileclose+0xa8>
    begin_op();
    80004916:	00000097          	auipc	ra,0x0
    8000491a:	a92080e7          	jalr	-1390(ra) # 800043a8 <begin_op>
    iput(ff.ip);
    8000491e:	854e                	mv	a0,s3
    80004920:	fffff097          	auipc	ra,0xfffff
    80004924:	27c080e7          	jalr	636(ra) # 80003b9c <iput>
    end_op();
    80004928:	00000097          	auipc	ra,0x0
    8000492c:	b00080e7          	jalr	-1280(ra) # 80004428 <end_op>
    80004930:	a00d                	j	80004952 <fileclose+0xa8>
    panic("fileclose");
    80004932:	00004517          	auipc	a0,0x4
    80004936:	e4650513          	addi	a0,a0,-442 # 80008778 <syscalls+0x270>
    8000493a:	ffffc097          	auipc	ra,0xffffc
    8000493e:	c3a080e7          	jalr	-966(ra) # 80000574 <panic>
    release(&ftable.lock);
    80004942:	0001d517          	auipc	a0,0x1d
    80004946:	30e50513          	addi	a0,a0,782 # 80021c50 <ftable>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	3cc080e7          	jalr	972(ra) # 80000d16 <release>
  }
}
    80004952:	70e2                	ld	ra,56(sp)
    80004954:	7442                	ld	s0,48(sp)
    80004956:	74a2                	ld	s1,40(sp)
    80004958:	7902                	ld	s2,32(sp)
    8000495a:	69e2                	ld	s3,24(sp)
    8000495c:	6a42                	ld	s4,16(sp)
    8000495e:	6aa2                	ld	s5,8(sp)
    80004960:	6121                	addi	sp,sp,64
    80004962:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004964:	85d6                	mv	a1,s5
    80004966:	8552                	mv	a0,s4
    80004968:	00000097          	auipc	ra,0x0
    8000496c:	364080e7          	jalr	868(ra) # 80004ccc <pipeclose>
    80004970:	b7cd                	j	80004952 <fileclose+0xa8>

0000000080004972 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004972:	715d                	addi	sp,sp,-80
    80004974:	e486                	sd	ra,72(sp)
    80004976:	e0a2                	sd	s0,64(sp)
    80004978:	fc26                	sd	s1,56(sp)
    8000497a:	f84a                	sd	s2,48(sp)
    8000497c:	f44e                	sd	s3,40(sp)
    8000497e:	0880                	addi	s0,sp,80
    80004980:	84aa                	mv	s1,a0
    80004982:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004984:	ffffd097          	auipc	ra,0xffffd
    80004988:	1d4080e7          	jalr	468(ra) # 80001b58 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000498c:	409c                	lw	a5,0(s1)
    8000498e:	37f9                	addiw	a5,a5,-2
    80004990:	4705                	li	a4,1
    80004992:	04f76763          	bltu	a4,a5,800049e0 <filestat+0x6e>
    80004996:	892a                	mv	s2,a0
    ilock(f->ip);
    80004998:	6c88                	ld	a0,24(s1)
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	046080e7          	jalr	70(ra) # 800039e0 <ilock>
    stati(f->ip, &st);
    800049a2:	fb840593          	addi	a1,s0,-72
    800049a6:	6c88                	ld	a0,24(s1)
    800049a8:	fffff097          	auipc	ra,0xfffff
    800049ac:	2c4080e7          	jalr	708(ra) # 80003c6c <stati>
    iunlock(f->ip);
    800049b0:	6c88                	ld	a0,24(s1)
    800049b2:	fffff097          	auipc	ra,0xfffff
    800049b6:	0f2080e7          	jalr	242(ra) # 80003aa4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800049ba:	46e1                	li	a3,24
    800049bc:	fb840613          	addi	a2,s0,-72
    800049c0:	85ce                	mv	a1,s3
    800049c2:	05093503          	ld	a0,80(s2)
    800049c6:	ffffd097          	auipc	ra,0xffffd
    800049ca:	d96080e7          	jalr	-618(ra) # 8000175c <copyout>
    800049ce:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049d2:	60a6                	ld	ra,72(sp)
    800049d4:	6406                	ld	s0,64(sp)
    800049d6:	74e2                	ld	s1,56(sp)
    800049d8:	7942                	ld	s2,48(sp)
    800049da:	79a2                	ld	s3,40(sp)
    800049dc:	6161                	addi	sp,sp,80
    800049de:	8082                	ret
  return -1;
    800049e0:	557d                	li	a0,-1
    800049e2:	bfc5                	j	800049d2 <filestat+0x60>

00000000800049e4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049e4:	7179                	addi	sp,sp,-48
    800049e6:	f406                	sd	ra,40(sp)
    800049e8:	f022                	sd	s0,32(sp)
    800049ea:	ec26                	sd	s1,24(sp)
    800049ec:	e84a                	sd	s2,16(sp)
    800049ee:	e44e                	sd	s3,8(sp)
    800049f0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049f2:	00854783          	lbu	a5,8(a0)
    800049f6:	c3d5                	beqz	a5,80004a9a <fileread+0xb6>
    800049f8:	89b2                	mv	s3,a2
    800049fa:	892e                	mv	s2,a1
    800049fc:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    800049fe:	411c                	lw	a5,0(a0)
    80004a00:	4705                	li	a4,1
    80004a02:	04e78963          	beq	a5,a4,80004a54 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a06:	470d                	li	a4,3
    80004a08:	04e78d63          	beq	a5,a4,80004a62 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a0c:	4709                	li	a4,2
    80004a0e:	06e79e63          	bne	a5,a4,80004a8a <fileread+0xa6>
    ilock(f->ip);
    80004a12:	6d08                	ld	a0,24(a0)
    80004a14:	fffff097          	auipc	ra,0xfffff
    80004a18:	fcc080e7          	jalr	-52(ra) # 800039e0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004a1c:	874e                	mv	a4,s3
    80004a1e:	5094                	lw	a3,32(s1)
    80004a20:	864a                	mv	a2,s2
    80004a22:	4585                	li	a1,1
    80004a24:	6c88                	ld	a0,24(s1)
    80004a26:	fffff097          	auipc	ra,0xfffff
    80004a2a:	270080e7          	jalr	624(ra) # 80003c96 <readi>
    80004a2e:	892a                	mv	s2,a0
    80004a30:	00a05563          	blez	a0,80004a3a <fileread+0x56>
      f->off += r;
    80004a34:	509c                	lw	a5,32(s1)
    80004a36:	9fa9                	addw	a5,a5,a0
    80004a38:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a3a:	6c88                	ld	a0,24(s1)
    80004a3c:	fffff097          	auipc	ra,0xfffff
    80004a40:	068080e7          	jalr	104(ra) # 80003aa4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a44:	854a                	mv	a0,s2
    80004a46:	70a2                	ld	ra,40(sp)
    80004a48:	7402                	ld	s0,32(sp)
    80004a4a:	64e2                	ld	s1,24(sp)
    80004a4c:	6942                	ld	s2,16(sp)
    80004a4e:	69a2                	ld	s3,8(sp)
    80004a50:	6145                	addi	sp,sp,48
    80004a52:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a54:	6908                	ld	a0,16(a0)
    80004a56:	00000097          	auipc	ra,0x0
    80004a5a:	416080e7          	jalr	1046(ra) # 80004e6c <piperead>
    80004a5e:	892a                	mv	s2,a0
    80004a60:	b7d5                	j	80004a44 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a62:	02451783          	lh	a5,36(a0)
    80004a66:	03079693          	slli	a3,a5,0x30
    80004a6a:	92c1                	srli	a3,a3,0x30
    80004a6c:	4725                	li	a4,9
    80004a6e:	02d76863          	bltu	a4,a3,80004a9e <fileread+0xba>
    80004a72:	0792                	slli	a5,a5,0x4
    80004a74:	0001d717          	auipc	a4,0x1d
    80004a78:	13c70713          	addi	a4,a4,316 # 80021bb0 <devsw>
    80004a7c:	97ba                	add	a5,a5,a4
    80004a7e:	639c                	ld	a5,0(a5)
    80004a80:	c38d                	beqz	a5,80004aa2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a82:	4505                	li	a0,1
    80004a84:	9782                	jalr	a5
    80004a86:	892a                	mv	s2,a0
    80004a88:	bf75                	j	80004a44 <fileread+0x60>
    panic("fileread");
    80004a8a:	00004517          	auipc	a0,0x4
    80004a8e:	cfe50513          	addi	a0,a0,-770 # 80008788 <syscalls+0x280>
    80004a92:	ffffc097          	auipc	ra,0xffffc
    80004a96:	ae2080e7          	jalr	-1310(ra) # 80000574 <panic>
    return -1;
    80004a9a:	597d                	li	s2,-1
    80004a9c:	b765                	j	80004a44 <fileread+0x60>
      return -1;
    80004a9e:	597d                	li	s2,-1
    80004aa0:	b755                	j	80004a44 <fileread+0x60>
    80004aa2:	597d                	li	s2,-1
    80004aa4:	b745                	j	80004a44 <fileread+0x60>

0000000080004aa6 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004aa6:	00954783          	lbu	a5,9(a0)
    80004aaa:	12078e63          	beqz	a5,80004be6 <filewrite+0x140>
{
    80004aae:	715d                	addi	sp,sp,-80
    80004ab0:	e486                	sd	ra,72(sp)
    80004ab2:	e0a2                	sd	s0,64(sp)
    80004ab4:	fc26                	sd	s1,56(sp)
    80004ab6:	f84a                	sd	s2,48(sp)
    80004ab8:	f44e                	sd	s3,40(sp)
    80004aba:	f052                	sd	s4,32(sp)
    80004abc:	ec56                	sd	s5,24(sp)
    80004abe:	e85a                	sd	s6,16(sp)
    80004ac0:	e45e                	sd	s7,8(sp)
    80004ac2:	e062                	sd	s8,0(sp)
    80004ac4:	0880                	addi	s0,sp,80
    80004ac6:	8ab2                	mv	s5,a2
    80004ac8:	8b2e                	mv	s6,a1
    80004aca:	84aa                	mv	s1,a0
    return -1;

  if(f->type == FD_PIPE){
    80004acc:	411c                	lw	a5,0(a0)
    80004ace:	4705                	li	a4,1
    80004ad0:	02e78263          	beq	a5,a4,80004af4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ad4:	470d                	li	a4,3
    80004ad6:	02e78563          	beq	a5,a4,80004b00 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004ada:	4709                	li	a4,2
    80004adc:	0ee79d63          	bne	a5,a4,80004bd6 <filewrite+0x130>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ae0:	0ec05763          	blez	a2,80004bce <filewrite+0x128>
    int i = 0;
    80004ae4:	4901                	li	s2,0
    80004ae6:	6b85                	lui	s7,0x1
    80004ae8:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004aec:	6c05                	lui	s8,0x1
    80004aee:	c00c0c1b          	addiw	s8,s8,-1024
    80004af2:	a061                	j	80004b7a <filewrite+0xd4>
    ret = pipewrite(f->pipe, addr, n);
    80004af4:	6908                	ld	a0,16(a0)
    80004af6:	00000097          	auipc	ra,0x0
    80004afa:	246080e7          	jalr	582(ra) # 80004d3c <pipewrite>
    80004afe:	a065                	j	80004ba6 <filewrite+0x100>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004b00:	02451783          	lh	a5,36(a0)
    80004b04:	03079693          	slli	a3,a5,0x30
    80004b08:	92c1                	srli	a3,a3,0x30
    80004b0a:	4725                	li	a4,9
    80004b0c:	0cd76f63          	bltu	a4,a3,80004bea <filewrite+0x144>
    80004b10:	0792                	slli	a5,a5,0x4
    80004b12:	0001d717          	auipc	a4,0x1d
    80004b16:	09e70713          	addi	a4,a4,158 # 80021bb0 <devsw>
    80004b1a:	97ba                	add	a5,a5,a4
    80004b1c:	679c                	ld	a5,8(a5)
    80004b1e:	cbe1                	beqz	a5,80004bee <filewrite+0x148>
    ret = devsw[f->major].write(1, addr, n);
    80004b20:	4505                	li	a0,1
    80004b22:	9782                	jalr	a5
    80004b24:	a049                	j	80004ba6 <filewrite+0x100>
    80004b26:	00098a1b          	sext.w	s4,s3
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004b2a:	00000097          	auipc	ra,0x0
    80004b2e:	87e080e7          	jalr	-1922(ra) # 800043a8 <begin_op>
      ilock(f->ip);
    80004b32:	6c88                	ld	a0,24(s1)
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	eac080e7          	jalr	-340(ra) # 800039e0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b3c:	8752                	mv	a4,s4
    80004b3e:	5094                	lw	a3,32(s1)
    80004b40:	01690633          	add	a2,s2,s6
    80004b44:	4585                	li	a1,1
    80004b46:	6c88                	ld	a0,24(s1)
    80004b48:	fffff097          	auipc	ra,0xfffff
    80004b4c:	244080e7          	jalr	580(ra) # 80003d8c <writei>
    80004b50:	89aa                	mv	s3,a0
    80004b52:	02a05c63          	blez	a0,80004b8a <filewrite+0xe4>
        f->off += r;
    80004b56:	509c                	lw	a5,32(s1)
    80004b58:	9fa9                	addw	a5,a5,a0
    80004b5a:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    80004b5c:	6c88                	ld	a0,24(s1)
    80004b5e:	fffff097          	auipc	ra,0xfffff
    80004b62:	f46080e7          	jalr	-186(ra) # 80003aa4 <iunlock>
      end_op();
    80004b66:	00000097          	auipc	ra,0x0
    80004b6a:	8c2080e7          	jalr	-1854(ra) # 80004428 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004b6e:	05499863          	bne	s3,s4,80004bbe <filewrite+0x118>
        panic("short filewrite");
      i += r;
    80004b72:	012a093b          	addw	s2,s4,s2
    while(i < n){
    80004b76:	03595563          	ble	s5,s2,80004ba0 <filewrite+0xfa>
      int n1 = n - i;
    80004b7a:	412a87bb          	subw	a5,s5,s2
      if(n1 > max)
    80004b7e:	89be                	mv	s3,a5
    80004b80:	2781                	sext.w	a5,a5
    80004b82:	fafbd2e3          	ble	a5,s7,80004b26 <filewrite+0x80>
    80004b86:	89e2                	mv	s3,s8
    80004b88:	bf79                	j	80004b26 <filewrite+0x80>
      iunlock(f->ip);
    80004b8a:	6c88                	ld	a0,24(s1)
    80004b8c:	fffff097          	auipc	ra,0xfffff
    80004b90:	f18080e7          	jalr	-232(ra) # 80003aa4 <iunlock>
      end_op();
    80004b94:	00000097          	auipc	ra,0x0
    80004b98:	894080e7          	jalr	-1900(ra) # 80004428 <end_op>
      if(r < 0)
    80004b9c:	fc09d9e3          	bgez	s3,80004b6e <filewrite+0xc8>
    }
    ret = (i == n ? n : -1);
    80004ba0:	8556                	mv	a0,s5
    80004ba2:	032a9863          	bne	s5,s2,80004bd2 <filewrite+0x12c>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ba6:	60a6                	ld	ra,72(sp)
    80004ba8:	6406                	ld	s0,64(sp)
    80004baa:	74e2                	ld	s1,56(sp)
    80004bac:	7942                	ld	s2,48(sp)
    80004bae:	79a2                	ld	s3,40(sp)
    80004bb0:	7a02                	ld	s4,32(sp)
    80004bb2:	6ae2                	ld	s5,24(sp)
    80004bb4:	6b42                	ld	s6,16(sp)
    80004bb6:	6ba2                	ld	s7,8(sp)
    80004bb8:	6c02                	ld	s8,0(sp)
    80004bba:	6161                	addi	sp,sp,80
    80004bbc:	8082                	ret
        panic("short filewrite");
    80004bbe:	00004517          	auipc	a0,0x4
    80004bc2:	bda50513          	addi	a0,a0,-1062 # 80008798 <syscalls+0x290>
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	9ae080e7          	jalr	-1618(ra) # 80000574 <panic>
    int i = 0;
    80004bce:	4901                	li	s2,0
    80004bd0:	bfc1                	j	80004ba0 <filewrite+0xfa>
    ret = (i == n ? n : -1);
    80004bd2:	557d                	li	a0,-1
    80004bd4:	bfc9                	j	80004ba6 <filewrite+0x100>
    panic("filewrite");
    80004bd6:	00004517          	auipc	a0,0x4
    80004bda:	bd250513          	addi	a0,a0,-1070 # 800087a8 <syscalls+0x2a0>
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	996080e7          	jalr	-1642(ra) # 80000574 <panic>
    return -1;
    80004be6:	557d                	li	a0,-1
}
    80004be8:	8082                	ret
      return -1;
    80004bea:	557d                	li	a0,-1
    80004bec:	bf6d                	j	80004ba6 <filewrite+0x100>
    80004bee:	557d                	li	a0,-1
    80004bf0:	bf5d                	j	80004ba6 <filewrite+0x100>

0000000080004bf2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004bf2:	7179                	addi	sp,sp,-48
    80004bf4:	f406                	sd	ra,40(sp)
    80004bf6:	f022                	sd	s0,32(sp)
    80004bf8:	ec26                	sd	s1,24(sp)
    80004bfa:	e84a                	sd	s2,16(sp)
    80004bfc:	e44e                	sd	s3,8(sp)
    80004bfe:	e052                	sd	s4,0(sp)
    80004c00:	1800                	addi	s0,sp,48
    80004c02:	84aa                	mv	s1,a0
    80004c04:	892e                	mv	s2,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c06:	0005b023          	sd	zero,0(a1)
    80004c0a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c0e:	00000097          	auipc	ra,0x0
    80004c12:	bcc080e7          	jalr	-1076(ra) # 800047da <filealloc>
    80004c16:	e088                	sd	a0,0(s1)
    80004c18:	c551                	beqz	a0,80004ca4 <pipealloc+0xb2>
    80004c1a:	00000097          	auipc	ra,0x0
    80004c1e:	bc0080e7          	jalr	-1088(ra) # 800047da <filealloc>
    80004c22:	00a93023          	sd	a0,0(s2)
    80004c26:	c92d                	beqz	a0,80004c98 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004c28:	ffffc097          	auipc	ra,0xffffc
    80004c2c:	f4a080e7          	jalr	-182(ra) # 80000b72 <kalloc>
    80004c30:	89aa                	mv	s3,a0
    80004c32:	c125                	beqz	a0,80004c92 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004c34:	4a05                	li	s4,1
    80004c36:	23452023          	sw	s4,544(a0)
  pi->writeopen = 1;
    80004c3a:	23452223          	sw	s4,548(a0)
  pi->nwrite = 0;
    80004c3e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004c42:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004c46:	00004597          	auipc	a1,0x4
    80004c4a:	b7258593          	addi	a1,a1,-1166 # 800087b8 <syscalls+0x2b0>
    80004c4e:	ffffc097          	auipc	ra,0xffffc
    80004c52:	f84080e7          	jalr	-124(ra) # 80000bd2 <initlock>
  (*f0)->type = FD_PIPE;
    80004c56:	609c                	ld	a5,0(s1)
    80004c58:	0147a023          	sw	s4,0(a5)
  (*f0)->readable = 1;
    80004c5c:	609c                	ld	a5,0(s1)
    80004c5e:	01478423          	sb	s4,8(a5)
  (*f0)->writable = 0;
    80004c62:	609c                	ld	a5,0(s1)
    80004c64:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c68:	609c                	ld	a5,0(s1)
    80004c6a:	0137b823          	sd	s3,16(a5)
  (*f1)->type = FD_PIPE;
    80004c6e:	00093783          	ld	a5,0(s2)
    80004c72:	0147a023          	sw	s4,0(a5)
  (*f1)->readable = 0;
    80004c76:	00093783          	ld	a5,0(s2)
    80004c7a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c7e:	00093783          	ld	a5,0(s2)
    80004c82:	014784a3          	sb	s4,9(a5)
  (*f1)->pipe = pi;
    80004c86:	00093783          	ld	a5,0(s2)
    80004c8a:	0137b823          	sd	s3,16(a5)
  return 0;
    80004c8e:	4501                	li	a0,0
    80004c90:	a025                	j	80004cb8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c92:	6088                	ld	a0,0(s1)
    80004c94:	e501                	bnez	a0,80004c9c <pipealloc+0xaa>
    80004c96:	a039                	j	80004ca4 <pipealloc+0xb2>
    80004c98:	6088                	ld	a0,0(s1)
    80004c9a:	c51d                	beqz	a0,80004cc8 <pipealloc+0xd6>
    fileclose(*f0);
    80004c9c:	00000097          	auipc	ra,0x0
    80004ca0:	c0e080e7          	jalr	-1010(ra) # 800048aa <fileclose>
  if(*f1)
    80004ca4:	00093783          	ld	a5,0(s2)
    fileclose(*f1);
  return -1;
    80004ca8:	557d                	li	a0,-1
  if(*f1)
    80004caa:	c799                	beqz	a5,80004cb8 <pipealloc+0xc6>
    fileclose(*f1);
    80004cac:	853e                	mv	a0,a5
    80004cae:	00000097          	auipc	ra,0x0
    80004cb2:	bfc080e7          	jalr	-1028(ra) # 800048aa <fileclose>
  return -1;
    80004cb6:	557d                	li	a0,-1
}
    80004cb8:	70a2                	ld	ra,40(sp)
    80004cba:	7402                	ld	s0,32(sp)
    80004cbc:	64e2                	ld	s1,24(sp)
    80004cbe:	6942                	ld	s2,16(sp)
    80004cc0:	69a2                	ld	s3,8(sp)
    80004cc2:	6a02                	ld	s4,0(sp)
    80004cc4:	6145                	addi	sp,sp,48
    80004cc6:	8082                	ret
  return -1;
    80004cc8:	557d                	li	a0,-1
    80004cca:	b7fd                	j	80004cb8 <pipealloc+0xc6>

0000000080004ccc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ccc:	1101                	addi	sp,sp,-32
    80004cce:	ec06                	sd	ra,24(sp)
    80004cd0:	e822                	sd	s0,16(sp)
    80004cd2:	e426                	sd	s1,8(sp)
    80004cd4:	e04a                	sd	s2,0(sp)
    80004cd6:	1000                	addi	s0,sp,32
    80004cd8:	84aa                	mv	s1,a0
    80004cda:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	f86080e7          	jalr	-122(ra) # 80000c62 <acquire>
  if(writable){
    80004ce4:	02090d63          	beqz	s2,80004d1e <pipeclose+0x52>
    pi->writeopen = 0;
    80004ce8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004cec:	21848513          	addi	a0,s1,536
    80004cf0:	ffffe097          	auipc	ra,0xffffe
    80004cf4:	a00080e7          	jalr	-1536(ra) # 800026f0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cf8:	2204b783          	ld	a5,544(s1)
    80004cfc:	eb95                	bnez	a5,80004d30 <pipeclose+0x64>
    release(&pi->lock);
    80004cfe:	8526                	mv	a0,s1
    80004d00:	ffffc097          	auipc	ra,0xffffc
    80004d04:	016080e7          	jalr	22(ra) # 80000d16 <release>
    kfree((char*)pi);
    80004d08:	8526                	mv	a0,s1
    80004d0a:	ffffc097          	auipc	ra,0xffffc
    80004d0e:	d68080e7          	jalr	-664(ra) # 80000a72 <kfree>
  } else
    release(&pi->lock);
}
    80004d12:	60e2                	ld	ra,24(sp)
    80004d14:	6442                	ld	s0,16(sp)
    80004d16:	64a2                	ld	s1,8(sp)
    80004d18:	6902                	ld	s2,0(sp)
    80004d1a:	6105                	addi	sp,sp,32
    80004d1c:	8082                	ret
    pi->readopen = 0;
    80004d1e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004d22:	21c48513          	addi	a0,s1,540
    80004d26:	ffffe097          	auipc	ra,0xffffe
    80004d2a:	9ca080e7          	jalr	-1590(ra) # 800026f0 <wakeup>
    80004d2e:	b7e9                	j	80004cf8 <pipeclose+0x2c>
    release(&pi->lock);
    80004d30:	8526                	mv	a0,s1
    80004d32:	ffffc097          	auipc	ra,0xffffc
    80004d36:	fe4080e7          	jalr	-28(ra) # 80000d16 <release>
}
    80004d3a:	bfe1                	j	80004d12 <pipeclose+0x46>

0000000080004d3c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004d3c:	7119                	addi	sp,sp,-128
    80004d3e:	fc86                	sd	ra,120(sp)
    80004d40:	f8a2                	sd	s0,112(sp)
    80004d42:	f4a6                	sd	s1,104(sp)
    80004d44:	f0ca                	sd	s2,96(sp)
    80004d46:	ecce                	sd	s3,88(sp)
    80004d48:	e8d2                	sd	s4,80(sp)
    80004d4a:	e4d6                	sd	s5,72(sp)
    80004d4c:	e0da                	sd	s6,64(sp)
    80004d4e:	fc5e                	sd	s7,56(sp)
    80004d50:	f862                	sd	s8,48(sp)
    80004d52:	f466                	sd	s9,40(sp)
    80004d54:	f06a                	sd	s10,32(sp)
    80004d56:	ec6e                	sd	s11,24(sp)
    80004d58:	0100                	addi	s0,sp,128
    80004d5a:	84aa                	mv	s1,a0
    80004d5c:	8d2e                	mv	s10,a1
    80004d5e:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004d60:	ffffd097          	auipc	ra,0xffffd
    80004d64:	df8080e7          	jalr	-520(ra) # 80001b58 <myproc>
    80004d68:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004d6a:	8526                	mv	a0,s1
    80004d6c:	ffffc097          	auipc	ra,0xffffc
    80004d70:	ef6080e7          	jalr	-266(ra) # 80000c62 <acquire>
  for(i = 0; i < n; i++){
    80004d74:	0d605f63          	blez	s6,80004e52 <pipewrite+0x116>
    80004d78:	89a6                	mv	s3,s1
    80004d7a:	3b7d                	addiw	s6,s6,-1
    80004d7c:	1b02                	slli	s6,s6,0x20
    80004d7e:	020b5b13          	srli	s6,s6,0x20
    80004d82:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004d84:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d88:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d8c:	5dfd                	li	s11,-1
    80004d8e:	000b8c9b          	sext.w	s9,s7
    80004d92:	8c66                	mv	s8,s9
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d94:	2184a783          	lw	a5,536(s1)
    80004d98:	21c4a703          	lw	a4,540(s1)
    80004d9c:	2007879b          	addiw	a5,a5,512
    80004da0:	06f71763          	bne	a4,a5,80004e0e <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80004da4:	2204a783          	lw	a5,544(s1)
    80004da8:	cf8d                	beqz	a5,80004de2 <pipewrite+0xa6>
    80004daa:	03092783          	lw	a5,48(s2)
    80004dae:	eb95                	bnez	a5,80004de2 <pipewrite+0xa6>
      wakeup(&pi->nread);
    80004db0:	8556                	mv	a0,s5
    80004db2:	ffffe097          	auipc	ra,0xffffe
    80004db6:	93e080e7          	jalr	-1730(ra) # 800026f0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004dba:	85ce                	mv	a1,s3
    80004dbc:	8552                	mv	a0,s4
    80004dbe:	ffffd097          	auipc	ra,0xffffd
    80004dc2:	7ac080e7          	jalr	1964(ra) # 8000256a <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004dc6:	2184a783          	lw	a5,536(s1)
    80004dca:	21c4a703          	lw	a4,540(s1)
    80004dce:	2007879b          	addiw	a5,a5,512
    80004dd2:	02f71e63          	bne	a4,a5,80004e0e <pipewrite+0xd2>
      if(pi->readopen == 0 || pr->killed){
    80004dd6:	2204a783          	lw	a5,544(s1)
    80004dda:	c781                	beqz	a5,80004de2 <pipewrite+0xa6>
    80004ddc:	03092783          	lw	a5,48(s2)
    80004de0:	dbe1                	beqz	a5,80004db0 <pipewrite+0x74>
        release(&pi->lock);
    80004de2:	8526                	mv	a0,s1
    80004de4:	ffffc097          	auipc	ra,0xffffc
    80004de8:	f32080e7          	jalr	-206(ra) # 80000d16 <release>
        return -1;
    80004dec:	5c7d                	li	s8,-1
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004dee:	8562                	mv	a0,s8
    80004df0:	70e6                	ld	ra,120(sp)
    80004df2:	7446                	ld	s0,112(sp)
    80004df4:	74a6                	ld	s1,104(sp)
    80004df6:	7906                	ld	s2,96(sp)
    80004df8:	69e6                	ld	s3,88(sp)
    80004dfa:	6a46                	ld	s4,80(sp)
    80004dfc:	6aa6                	ld	s5,72(sp)
    80004dfe:	6b06                	ld	s6,64(sp)
    80004e00:	7be2                	ld	s7,56(sp)
    80004e02:	7c42                	ld	s8,48(sp)
    80004e04:	7ca2                	ld	s9,40(sp)
    80004e06:	7d02                	ld	s10,32(sp)
    80004e08:	6de2                	ld	s11,24(sp)
    80004e0a:	6109                	addi	sp,sp,128
    80004e0c:	8082                	ret
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e0e:	4685                	li	a3,1
    80004e10:	01ab8633          	add	a2,s7,s10
    80004e14:	f8f40593          	addi	a1,s0,-113
    80004e18:	05093503          	ld	a0,80(s2)
    80004e1c:	ffffd097          	auipc	ra,0xffffd
    80004e20:	9cc080e7          	jalr	-1588(ra) # 800017e8 <copyin>
    80004e24:	03b50863          	beq	a0,s11,80004e54 <pipewrite+0x118>
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e28:	21c4a783          	lw	a5,540(s1)
    80004e2c:	0017871b          	addiw	a4,a5,1
    80004e30:	20e4ae23          	sw	a4,540(s1)
    80004e34:	1ff7f793          	andi	a5,a5,511
    80004e38:	97a6                	add	a5,a5,s1
    80004e3a:	f8f44703          	lbu	a4,-113(s0)
    80004e3e:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004e42:	001c8c1b          	addiw	s8,s9,1
    80004e46:	001b8793          	addi	a5,s7,1
    80004e4a:	016b8563          	beq	s7,s6,80004e54 <pipewrite+0x118>
    80004e4e:	8bbe                	mv	s7,a5
    80004e50:	bf3d                	j	80004d8e <pipewrite+0x52>
    80004e52:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004e54:	21848513          	addi	a0,s1,536
    80004e58:	ffffe097          	auipc	ra,0xffffe
    80004e5c:	898080e7          	jalr	-1896(ra) # 800026f0 <wakeup>
  release(&pi->lock);
    80004e60:	8526                	mv	a0,s1
    80004e62:	ffffc097          	auipc	ra,0xffffc
    80004e66:	eb4080e7          	jalr	-332(ra) # 80000d16 <release>
  return i;
    80004e6a:	b751                	j	80004dee <pipewrite+0xb2>

0000000080004e6c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e6c:	715d                	addi	sp,sp,-80
    80004e6e:	e486                	sd	ra,72(sp)
    80004e70:	e0a2                	sd	s0,64(sp)
    80004e72:	fc26                	sd	s1,56(sp)
    80004e74:	f84a                	sd	s2,48(sp)
    80004e76:	f44e                	sd	s3,40(sp)
    80004e78:	f052                	sd	s4,32(sp)
    80004e7a:	ec56                	sd	s5,24(sp)
    80004e7c:	e85a                	sd	s6,16(sp)
    80004e7e:	0880                	addi	s0,sp,80
    80004e80:	84aa                	mv	s1,a0
    80004e82:	89ae                	mv	s3,a1
    80004e84:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e86:	ffffd097          	auipc	ra,0xffffd
    80004e8a:	cd2080e7          	jalr	-814(ra) # 80001b58 <myproc>
    80004e8e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e90:	8526                	mv	a0,s1
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	dd0080e7          	jalr	-560(ra) # 80000c62 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e9a:	2184a703          	lw	a4,536(s1)
    80004e9e:	21c4a783          	lw	a5,540(s1)
    80004ea2:	06f71b63          	bne	a4,a5,80004f18 <piperead+0xac>
    80004ea6:	8926                	mv	s2,s1
    80004ea8:	2244a783          	lw	a5,548(s1)
    80004eac:	cf9d                	beqz	a5,80004eea <piperead+0x7e>
    if(pr->killed){
    80004eae:	030a2783          	lw	a5,48(s4)
    80004eb2:	e78d                	bnez	a5,80004edc <piperead+0x70>
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004eb4:	21848b13          	addi	s6,s1,536
    80004eb8:	85ca                	mv	a1,s2
    80004eba:	855a                	mv	a0,s6
    80004ebc:	ffffd097          	auipc	ra,0xffffd
    80004ec0:	6ae080e7          	jalr	1710(ra) # 8000256a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ec4:	2184a703          	lw	a4,536(s1)
    80004ec8:	21c4a783          	lw	a5,540(s1)
    80004ecc:	04f71663          	bne	a4,a5,80004f18 <piperead+0xac>
    80004ed0:	2244a783          	lw	a5,548(s1)
    80004ed4:	cb99                	beqz	a5,80004eea <piperead+0x7e>
    if(pr->killed){
    80004ed6:	030a2783          	lw	a5,48(s4)
    80004eda:	dff9                	beqz	a5,80004eb8 <piperead+0x4c>
      release(&pi->lock);
    80004edc:	8526                	mv	a0,s1
    80004ede:	ffffc097          	auipc	ra,0xffffc
    80004ee2:	e38080e7          	jalr	-456(ra) # 80000d16 <release>
      return -1;
    80004ee6:	597d                	li	s2,-1
    80004ee8:	a829                	j	80004f02 <piperead+0x96>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    if(pi->nread == pi->nwrite)
    80004eea:	4901                	li	s2,0
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004eec:	21c48513          	addi	a0,s1,540
    80004ef0:	ffffe097          	auipc	ra,0xffffe
    80004ef4:	800080e7          	jalr	-2048(ra) # 800026f0 <wakeup>
  release(&pi->lock);
    80004ef8:	8526                	mv	a0,s1
    80004efa:	ffffc097          	auipc	ra,0xffffc
    80004efe:	e1c080e7          	jalr	-484(ra) # 80000d16 <release>
  return i;
}
    80004f02:	854a                	mv	a0,s2
    80004f04:	60a6                	ld	ra,72(sp)
    80004f06:	6406                	ld	s0,64(sp)
    80004f08:	74e2                	ld	s1,56(sp)
    80004f0a:	7942                	ld	s2,48(sp)
    80004f0c:	79a2                	ld	s3,40(sp)
    80004f0e:	7a02                	ld	s4,32(sp)
    80004f10:	6ae2                	ld	s5,24(sp)
    80004f12:	6b42                	ld	s6,16(sp)
    80004f14:	6161                	addi	sp,sp,80
    80004f16:	8082                	ret
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f18:	4901                	li	s2,0
    80004f1a:	fd5059e3          	blez	s5,80004eec <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004f1e:	2184a783          	lw	a5,536(s1)
    80004f22:	4901                	li	s2,0
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f24:	5b7d                	li	s6,-1
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f26:	0017871b          	addiw	a4,a5,1
    80004f2a:	20e4ac23          	sw	a4,536(s1)
    80004f2e:	1ff7f793          	andi	a5,a5,511
    80004f32:	97a6                	add	a5,a5,s1
    80004f34:	0187c783          	lbu	a5,24(a5)
    80004f38:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f3c:	4685                	li	a3,1
    80004f3e:	fbf40613          	addi	a2,s0,-65
    80004f42:	85ce                	mv	a1,s3
    80004f44:	050a3503          	ld	a0,80(s4)
    80004f48:	ffffd097          	auipc	ra,0xffffd
    80004f4c:	814080e7          	jalr	-2028(ra) # 8000175c <copyout>
    80004f50:	f9650ee3          	beq	a0,s6,80004eec <piperead+0x80>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f54:	2905                	addiw	s2,s2,1
    80004f56:	f92a8be3          	beq	s5,s2,80004eec <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004f5a:	2184a783          	lw	a5,536(s1)
    80004f5e:	0985                	addi	s3,s3,1
    80004f60:	21c4a703          	lw	a4,540(s1)
    80004f64:	fcf711e3          	bne	a4,a5,80004f26 <piperead+0xba>
    80004f68:	b751                	j	80004eec <piperead+0x80>

0000000080004f6a <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004f6a:	df010113          	addi	sp,sp,-528
    80004f6e:	20113423          	sd	ra,520(sp)
    80004f72:	20813023          	sd	s0,512(sp)
    80004f76:	ffa6                	sd	s1,504(sp)
    80004f78:	fbca                	sd	s2,496(sp)
    80004f7a:	f7ce                	sd	s3,488(sp)
    80004f7c:	f3d2                	sd	s4,480(sp)
    80004f7e:	efd6                	sd	s5,472(sp)
    80004f80:	ebda                	sd	s6,464(sp)
    80004f82:	e7de                	sd	s7,456(sp)
    80004f84:	e3e2                	sd	s8,448(sp)
    80004f86:	ff66                	sd	s9,440(sp)
    80004f88:	fb6a                	sd	s10,432(sp)
    80004f8a:	f76e                	sd	s11,424(sp)
    80004f8c:	0c00                	addi	s0,sp,528
    80004f8e:	84aa                	mv	s1,a0
    80004f90:	dea43c23          	sd	a0,-520(s0)
    80004f94:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	bc0080e7          	jalr	-1088(ra) # 80001b58 <myproc>
    80004fa0:	892a                	mv	s2,a0

  begin_op();
    80004fa2:	fffff097          	auipc	ra,0xfffff
    80004fa6:	406080e7          	jalr	1030(ra) # 800043a8 <begin_op>

  if((ip = namei(path)) == 0){
    80004faa:	8526                	mv	a0,s1
    80004fac:	fffff097          	auipc	ra,0xfffff
    80004fb0:	1ee080e7          	jalr	494(ra) # 8000419a <namei>
    80004fb4:	c92d                	beqz	a0,80005026 <exec+0xbc>
    80004fb6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004fb8:	fffff097          	auipc	ra,0xfffff
    80004fbc:	a28080e7          	jalr	-1496(ra) # 800039e0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004fc0:	04000713          	li	a4,64
    80004fc4:	4681                	li	a3,0
    80004fc6:	e4840613          	addi	a2,s0,-440
    80004fca:	4581                	li	a1,0
    80004fcc:	8526                	mv	a0,s1
    80004fce:	fffff097          	auipc	ra,0xfffff
    80004fd2:	cc8080e7          	jalr	-824(ra) # 80003c96 <readi>
    80004fd6:	04000793          	li	a5,64
    80004fda:	00f51a63          	bne	a0,a5,80004fee <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004fde:	e4842703          	lw	a4,-440(s0)
    80004fe2:	464c47b7          	lui	a5,0x464c4
    80004fe6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004fea:	04f70463          	beq	a4,a5,80005032 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004fee:	8526                	mv	a0,s1
    80004ff0:	fffff097          	auipc	ra,0xfffff
    80004ff4:	c54080e7          	jalr	-940(ra) # 80003c44 <iunlockput>
    end_op();
    80004ff8:	fffff097          	auipc	ra,0xfffff
    80004ffc:	430080e7          	jalr	1072(ra) # 80004428 <end_op>
  }
  return -1;
    80005000:	557d                	li	a0,-1
}
    80005002:	20813083          	ld	ra,520(sp)
    80005006:	20013403          	ld	s0,512(sp)
    8000500a:	74fe                	ld	s1,504(sp)
    8000500c:	795e                	ld	s2,496(sp)
    8000500e:	79be                	ld	s3,488(sp)
    80005010:	7a1e                	ld	s4,480(sp)
    80005012:	6afe                	ld	s5,472(sp)
    80005014:	6b5e                	ld	s6,464(sp)
    80005016:	6bbe                	ld	s7,456(sp)
    80005018:	6c1e                	ld	s8,448(sp)
    8000501a:	7cfa                	ld	s9,440(sp)
    8000501c:	7d5a                	ld	s10,432(sp)
    8000501e:	7dba                	ld	s11,424(sp)
    80005020:	21010113          	addi	sp,sp,528
    80005024:	8082                	ret
    end_op();
    80005026:	fffff097          	auipc	ra,0xfffff
    8000502a:	402080e7          	jalr	1026(ra) # 80004428 <end_op>
    return -1;
    8000502e:	557d                	li	a0,-1
    80005030:	bfc9                	j	80005002 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005032:	854a                	mv	a0,s2
    80005034:	ffffd097          	auipc	ra,0xffffd
    80005038:	cb0080e7          	jalr	-848(ra) # 80001ce4 <proc_pagetable>
    8000503c:	e0a43423          	sd	a0,-504(s0)
    80005040:	d55d                	beqz	a0,80004fee <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005042:	e6842983          	lw	s3,-408(s0)
    80005046:	e8045783          	lhu	a5,-384(s0)
    8000504a:	c7b5                	beqz	a5,800050b6 <exec+0x14c>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000504c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000504e:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80005050:	6c85                	lui	s9,0x1
    80005052:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005056:	def43823          	sd	a5,-528(s0)
    8000505a:	a4b5                	j	800052c6 <exec+0x35c>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    8000505c:	00003517          	auipc	a0,0x3
    80005060:	76450513          	addi	a0,a0,1892 # 800087c0 <syscalls+0x2b8>
    80005064:	ffffb097          	auipc	ra,0xffffb
    80005068:	510080e7          	jalr	1296(ra) # 80000574 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    8000506c:	8756                	mv	a4,s5
    8000506e:	012d86bb          	addw	a3,s11,s2
    80005072:	4581                	li	a1,0
    80005074:	8526                	mv	a0,s1
    80005076:	fffff097          	auipc	ra,0xfffff
    8000507a:	c20080e7          	jalr	-992(ra) # 80003c96 <readi>
    8000507e:	2501                	sext.w	a0,a0
    80005080:	1eaa9d63          	bne	s5,a0,8000527a <exec+0x310>
  for(i = 0; i < sz; i += PGSIZE){
    80005084:	6785                	lui	a5,0x1
    80005086:	0127893b          	addw	s2,a5,s2
    8000508a:	77fd                	lui	a5,0xfffff
    8000508c:	01478a3b          	addw	s4,a5,s4
    80005090:	21897f63          	bleu	s8,s2,800052ae <exec+0x344>
    pa = walkaddr(pagetable, va + i);
    80005094:	02091593          	slli	a1,s2,0x20
    80005098:	9181                	srli	a1,a1,0x20
    8000509a:	95ea                	add	a1,a1,s10
    8000509c:	e0843503          	ld	a0,-504(s0)
    800050a0:	ffffc097          	auipc	ra,0xffffc
    800050a4:	07c080e7          	jalr	124(ra) # 8000111c <walkaddr>
    800050a8:	862a                	mv	a2,a0
    if(pa == 0)
    800050aa:	d94d                	beqz	a0,8000505c <exec+0xf2>
      n = PGSIZE;
    800050ac:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800050ae:	fb9a7fe3          	bleu	s9,s4,8000506c <exec+0x102>
      n = sz - i;
    800050b2:	8ad2                	mv	s5,s4
    800050b4:	bf65                	j	8000506c <exec+0x102>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800050b6:	4901                	li	s2,0
  iunlockput(ip);
    800050b8:	8526                	mv	a0,s1
    800050ba:	fffff097          	auipc	ra,0xfffff
    800050be:	b8a080e7          	jalr	-1142(ra) # 80003c44 <iunlockput>
  end_op();
    800050c2:	fffff097          	auipc	ra,0xfffff
    800050c6:	366080e7          	jalr	870(ra) # 80004428 <end_op>
  p = myproc();
    800050ca:	ffffd097          	auipc	ra,0xffffd
    800050ce:	a8e080e7          	jalr	-1394(ra) # 80001b58 <myproc>
    800050d2:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800050d4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800050d8:	6b85                	lui	s7,0x1
    800050da:	1bfd                	addi	s7,s7,-1
    800050dc:	995e                	add	s2,s2,s7
    800050de:	7bfd                	lui	s7,0xfffff
    800050e0:	01797bb3          	and	s7,s2,s7
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050e4:	6609                	lui	a2,0x2
    800050e6:	965e                	add	a2,a2,s7
    800050e8:	85de                	mv	a1,s7
    800050ea:	e0843903          	ld	s2,-504(s0)
    800050ee:	854a                	mv	a0,s2
    800050f0:	ffffc097          	auipc	ra,0xffffc
    800050f4:	41c080e7          	jalr	1052(ra) # 8000150c <uvmalloc>
    800050f8:	8b2a                	mv	s6,a0
  ip = 0;
    800050fa:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800050fc:	16050f63          	beqz	a0,8000527a <exec+0x310>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005100:	75f9                	lui	a1,0xffffe
    80005102:	95aa                	add	a1,a1,a0
    80005104:	854a                	mv	a0,s2
    80005106:	ffffc097          	auipc	ra,0xffffc
    8000510a:	624080e7          	jalr	1572(ra) # 8000172a <uvmclear>
  stackbase = sp - PGSIZE;
    8000510e:	7bfd                	lui	s7,0xfffff
    80005110:	9bda                	add	s7,s7,s6
  for(argc = 0; argv[argc]; argc++) {
    80005112:	e0043783          	ld	a5,-512(s0)
    80005116:	6388                	ld	a0,0(a5)
    80005118:	c535                	beqz	a0,80005184 <exec+0x21a>
    8000511a:	e8840993          	addi	s3,s0,-376
    8000511e:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80005122:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005124:	ffffc097          	auipc	ra,0xffffc
    80005128:	de4080e7          	jalr	-540(ra) # 80000f08 <strlen>
    8000512c:	2505                	addiw	a0,a0,1
    8000512e:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005132:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005136:	17796363          	bltu	s2,s7,8000529c <exec+0x332>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000513a:	e0043c83          	ld	s9,-512(s0)
    8000513e:	000cba03          	ld	s4,0(s9)
    80005142:	8552                	mv	a0,s4
    80005144:	ffffc097          	auipc	ra,0xffffc
    80005148:	dc4080e7          	jalr	-572(ra) # 80000f08 <strlen>
    8000514c:	0015069b          	addiw	a3,a0,1
    80005150:	8652                	mv	a2,s4
    80005152:	85ca                	mv	a1,s2
    80005154:	e0843503          	ld	a0,-504(s0)
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	604080e7          	jalr	1540(ra) # 8000175c <copyout>
    80005160:	14054163          	bltz	a0,800052a2 <exec+0x338>
    ustack[argc] = sp;
    80005164:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005168:	0485                	addi	s1,s1,1
    8000516a:	008c8793          	addi	a5,s9,8
    8000516e:	e0f43023          	sd	a5,-512(s0)
    80005172:	008cb503          	ld	a0,8(s9)
    80005176:	c909                	beqz	a0,80005188 <exec+0x21e>
    if(argc >= MAXARG)
    80005178:	09a1                	addi	s3,s3,8
    8000517a:	fb3c15e3          	bne	s8,s3,80005124 <exec+0x1ba>
  sz = sz1;
    8000517e:	8bda                	mv	s7,s6
  ip = 0;
    80005180:	4481                	li	s1,0
    80005182:	a8e5                	j	8000527a <exec+0x310>
  sp = sz;
    80005184:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005186:	4481                	li	s1,0
  ustack[argc] = 0;
    80005188:	00349793          	slli	a5,s1,0x3
    8000518c:	f9040713          	addi	a4,s0,-112
    80005190:	97ba                	add	a5,a5,a4
    80005192:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffd7ed8>
  sp -= (argc+1) * sizeof(uint64);
    80005196:	00148693          	addi	a3,s1,1
    8000519a:	068e                	slli	a3,a3,0x3
    8000519c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800051a0:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800051a4:	01797563          	bleu	s7,s2,800051ae <exec+0x244>
  sz = sz1;
    800051a8:	8bda                	mv	s7,s6
  ip = 0;
    800051aa:	4481                	li	s1,0
    800051ac:	a0f9                	j	8000527a <exec+0x310>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800051ae:	e8840613          	addi	a2,s0,-376
    800051b2:	85ca                	mv	a1,s2
    800051b4:	e0843983          	ld	s3,-504(s0)
    800051b8:	854e                	mv	a0,s3
    800051ba:	ffffc097          	auipc	ra,0xffffc
    800051be:	5a2080e7          	jalr	1442(ra) # 8000175c <copyout>
    800051c2:	0e054363          	bltz	a0,800052a8 <exec+0x33e>
  uvmunmap(p->kernel_pagetable, 0, PGROUNDUP(oldsz)/PGSIZE, 0);
    800051c6:	6605                	lui	a2,0x1
    800051c8:	167d                	addi	a2,a2,-1
    800051ca:	966a                	add	a2,a2,s10
    800051cc:	4681                	li	a3,0
    800051ce:	8231                	srli	a2,a2,0xc
    800051d0:	4581                	li	a1,0
    800051d2:	168ab503          	ld	a0,360(s5)
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	18a080e7          	jalr	394(ra) # 80001360 <uvmunmap>
  uvm2kvm(pagetable, p->kernel_pagetable, 0, sz);
    800051de:	86da                	mv	a3,s6
    800051e0:	4601                	li	a2,0
    800051e2:	168ab583          	ld	a1,360(s5)
    800051e6:	854e                	mv	a0,s3
    800051e8:	ffffc097          	auipc	ra,0xffffc
    800051ec:	7dc080e7          	jalr	2012(ra) # 800019c4 <uvm2kvm>
  p->trapframe->a1 = sp;
    800051f0:	058ab783          	ld	a5,88(s5)
    800051f4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800051f8:	df843783          	ld	a5,-520(s0)
    800051fc:	0007c703          	lbu	a4,0(a5)
    80005200:	cf11                	beqz	a4,8000521c <exec+0x2b2>
    80005202:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005204:	02f00693          	li	a3,47
    80005208:	a039                	j	80005216 <exec+0x2ac>
      last = s+1;
    8000520a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000520e:	0785                	addi	a5,a5,1
    80005210:	fff7c703          	lbu	a4,-1(a5)
    80005214:	c701                	beqz	a4,8000521c <exec+0x2b2>
    if(*s == '/')
    80005216:	fed71ce3          	bne	a4,a3,8000520e <exec+0x2a4>
    8000521a:	bfc5                	j	8000520a <exec+0x2a0>
  safestrcpy(p->name, last, sizeof(p->name));
    8000521c:	4641                	li	a2,16
    8000521e:	df843583          	ld	a1,-520(s0)
    80005222:	158a8513          	addi	a0,s5,344
    80005226:	ffffc097          	auipc	ra,0xffffc
    8000522a:	cb0080e7          	jalr	-848(ra) # 80000ed6 <safestrcpy>
  oldpagetable = p->pagetable;
    8000522e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005232:	e0843783          	ld	a5,-504(s0)
    80005236:	04fab823          	sd	a5,80(s5)
  p->sz = sz;
    8000523a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000523e:	058ab783          	ld	a5,88(s5)
    80005242:	e6043703          	ld	a4,-416(s0)
    80005246:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005248:	058ab783          	ld	a5,88(s5)
    8000524c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005250:	85ea                	mv	a1,s10
    80005252:	ffffd097          	auipc	ra,0xffffd
    80005256:	b2e080e7          	jalr	-1234(ra) # 80001d80 <proc_freepagetable>
if (p->pid == 1) {
    8000525a:	038aa703          	lw	a4,56(s5)
    8000525e:	4785                	li	a5,1
    80005260:	00f70563          	beq	a4,a5,8000526a <exec+0x300>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005264:	0004851b          	sext.w	a0,s1
    80005268:	bb69                	j	80005002 <exec+0x98>
      vmprint(p->pagetable);
    8000526a:	050ab503          	ld	a0,80(s5)
    8000526e:	ffffc097          	auipc	ra,0xffffc
    80005272:	656080e7          	jalr	1622(ra) # 800018c4 <vmprint>
    80005276:	b7fd                	j	80005264 <exec+0x2fa>
    80005278:	8bca                	mv	s7,s2
    proc_freepagetable(pagetable, sz);
    8000527a:	85de                	mv	a1,s7
    8000527c:	e0843503          	ld	a0,-504(s0)
    80005280:	ffffd097          	auipc	ra,0xffffd
    80005284:	b00080e7          	jalr	-1280(ra) # 80001d80 <proc_freepagetable>
  if(ip){
    80005288:	d60493e3          	bnez	s1,80004fee <exec+0x84>
  return -1;
    8000528c:	557d                	li	a0,-1
    8000528e:	bb95                	j	80005002 <exec+0x98>
    80005290:	8bca                	mv	s7,s2
    80005292:	b7e5                	j	8000527a <exec+0x310>
    80005294:	8bca                	mv	s7,s2
    80005296:	b7d5                	j	8000527a <exec+0x310>
    80005298:	8bca                	mv	s7,s2
    8000529a:	b7c5                	j	8000527a <exec+0x310>
  sz = sz1;
    8000529c:	8bda                	mv	s7,s6
  ip = 0;
    8000529e:	4481                	li	s1,0
    800052a0:	bfe9                	j	8000527a <exec+0x310>
  sz = sz1;
    800052a2:	8bda                	mv	s7,s6
  ip = 0;
    800052a4:	4481                	li	s1,0
    800052a6:	bfd1                	j	8000527a <exec+0x310>
  sz = sz1;
    800052a8:	8bda                	mv	s7,s6
  ip = 0;
    800052aa:	4481                	li	s1,0
    800052ac:	b7f9                	j	8000527a <exec+0x310>
    if (sz1 >= PLIC)
    800052ae:	0c0007b7          	lui	a5,0xc000
    800052b2:	fcfbf4e3          	bleu	a5,s7,8000527a <exec+0x310>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800052b6:	895e                	mv	s2,s7
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052b8:	2b05                	addiw	s6,s6,1
    800052ba:	0389899b          	addiw	s3,s3,56
    800052be:	e8045783          	lhu	a5,-384(s0)
    800052c2:	defb5be3          	ble	a5,s6,800050b8 <exec+0x14e>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052c6:	2981                	sext.w	s3,s3
    800052c8:	03800713          	li	a4,56
    800052cc:	86ce                	mv	a3,s3
    800052ce:	e1040613          	addi	a2,s0,-496
    800052d2:	4581                	li	a1,0
    800052d4:	8526                	mv	a0,s1
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	9c0080e7          	jalr	-1600(ra) # 80003c96 <readi>
    800052de:	03800793          	li	a5,56
    800052e2:	f8f51be3          	bne	a0,a5,80005278 <exec+0x30e>
    if(ph.type != ELF_PROG_LOAD)
    800052e6:	e1042783          	lw	a5,-496(s0)
    800052ea:	4705                	li	a4,1
    800052ec:	fce796e3          	bne	a5,a4,800052b8 <exec+0x34e>
    if(ph.memsz < ph.filesz)
    800052f0:	e3843603          	ld	a2,-456(s0)
    800052f4:	e3043783          	ld	a5,-464(s0)
    800052f8:	f8f66ce3          	bltu	a2,a5,80005290 <exec+0x326>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800052fc:	e2043783          	ld	a5,-480(s0)
    80005300:	963e                	add	a2,a2,a5
    80005302:	f8f669e3          	bltu	a2,a5,80005294 <exec+0x32a>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005306:	85ca                	mv	a1,s2
    80005308:	e0843503          	ld	a0,-504(s0)
    8000530c:	ffffc097          	auipc	ra,0xffffc
    80005310:	200080e7          	jalr	512(ra) # 8000150c <uvmalloc>
    80005314:	8baa                	mv	s7,a0
    80005316:	d149                	beqz	a0,80005298 <exec+0x32e>
    if(ph.vaddr % PGSIZE != 0)
    80005318:	e2043d03          	ld	s10,-480(s0)
    8000531c:	df043783          	ld	a5,-528(s0)
    80005320:	00fd77b3          	and	a5,s10,a5
    80005324:	fbb9                	bnez	a5,8000527a <exec+0x310>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005326:	e1842d83          	lw	s11,-488(s0)
    8000532a:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000532e:	f80c00e3          	beqz	s8,800052ae <exec+0x344>
    80005332:	8a62                	mv	s4,s8
    80005334:	4901                	li	s2,0
    80005336:	bbb9                	j	80005094 <exec+0x12a>

0000000080005338 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005338:	7179                	addi	sp,sp,-48
    8000533a:	f406                	sd	ra,40(sp)
    8000533c:	f022                	sd	s0,32(sp)
    8000533e:	ec26                	sd	s1,24(sp)
    80005340:	e84a                	sd	s2,16(sp)
    80005342:	1800                	addi	s0,sp,48
    80005344:	892e                	mv	s2,a1
    80005346:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005348:	fdc40593          	addi	a1,s0,-36
    8000534c:	ffffe097          	auipc	ra,0xffffe
    80005350:	ad4080e7          	jalr	-1324(ra) # 80002e20 <argint>
    80005354:	04054063          	bltz	a0,80005394 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005358:	fdc42703          	lw	a4,-36(s0)
    8000535c:	47bd                	li	a5,15
    8000535e:	02e7ed63          	bltu	a5,a4,80005398 <argfd+0x60>
    80005362:	ffffc097          	auipc	ra,0xffffc
    80005366:	7f6080e7          	jalr	2038(ra) # 80001b58 <myproc>
    8000536a:	fdc42703          	lw	a4,-36(s0)
    8000536e:	01a70793          	addi	a5,a4,26
    80005372:	078e                	slli	a5,a5,0x3
    80005374:	953e                	add	a0,a0,a5
    80005376:	611c                	ld	a5,0(a0)
    80005378:	c395                	beqz	a5,8000539c <argfd+0x64>
    return -1;
  if(pfd)
    8000537a:	00090463          	beqz	s2,80005382 <argfd+0x4a>
    *pfd = fd;
    8000537e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005382:	4501                	li	a0,0
  if(pf)
    80005384:	c091                	beqz	s1,80005388 <argfd+0x50>
    *pf = f;
    80005386:	e09c                	sd	a5,0(s1)
}
    80005388:	70a2                	ld	ra,40(sp)
    8000538a:	7402                	ld	s0,32(sp)
    8000538c:	64e2                	ld	s1,24(sp)
    8000538e:	6942                	ld	s2,16(sp)
    80005390:	6145                	addi	sp,sp,48
    80005392:	8082                	ret
    return -1;
    80005394:	557d                	li	a0,-1
    80005396:	bfcd                	j	80005388 <argfd+0x50>
    return -1;
    80005398:	557d                	li	a0,-1
    8000539a:	b7fd                	j	80005388 <argfd+0x50>
    8000539c:	557d                	li	a0,-1
    8000539e:	b7ed                	j	80005388 <argfd+0x50>

00000000800053a0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053a0:	1101                	addi	sp,sp,-32
    800053a2:	ec06                	sd	ra,24(sp)
    800053a4:	e822                	sd	s0,16(sp)
    800053a6:	e426                	sd	s1,8(sp)
    800053a8:	1000                	addi	s0,sp,32
    800053aa:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053ac:	ffffc097          	auipc	ra,0xffffc
    800053b0:	7ac080e7          	jalr	1964(ra) # 80001b58 <myproc>

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){
    800053b4:	697c                	ld	a5,208(a0)
    800053b6:	c395                	beqz	a5,800053da <fdalloc+0x3a>
    800053b8:	0d850713          	addi	a4,a0,216
  for(fd = 0; fd < NOFILE; fd++){
    800053bc:	4785                	li	a5,1
    800053be:	4641                	li	a2,16
    if(p->ofile[fd] == 0){
    800053c0:	6314                	ld	a3,0(a4)
    800053c2:	ce89                	beqz	a3,800053dc <fdalloc+0x3c>
  for(fd = 0; fd < NOFILE; fd++){
    800053c4:	2785                	addiw	a5,a5,1
    800053c6:	0721                	addi	a4,a4,8
    800053c8:	fec79ce3          	bne	a5,a2,800053c0 <fdalloc+0x20>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800053cc:	57fd                	li	a5,-1
}
    800053ce:	853e                	mv	a0,a5
    800053d0:	60e2                	ld	ra,24(sp)
    800053d2:	6442                	ld	s0,16(sp)
    800053d4:	64a2                	ld	s1,8(sp)
    800053d6:	6105                	addi	sp,sp,32
    800053d8:	8082                	ret
  for(fd = 0; fd < NOFILE; fd++){
    800053da:	4781                	li	a5,0
      p->ofile[fd] = f;
    800053dc:	01a78713          	addi	a4,a5,26 # c00001a <_entry-0x73ffffe6>
    800053e0:	070e                	slli	a4,a4,0x3
    800053e2:	953a                	add	a0,a0,a4
    800053e4:	e104                	sd	s1,0(a0)
      return fd;
    800053e6:	b7e5                	j	800053ce <fdalloc+0x2e>

00000000800053e8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800053e8:	715d                	addi	sp,sp,-80
    800053ea:	e486                	sd	ra,72(sp)
    800053ec:	e0a2                	sd	s0,64(sp)
    800053ee:	fc26                	sd	s1,56(sp)
    800053f0:	f84a                	sd	s2,48(sp)
    800053f2:	f44e                	sd	s3,40(sp)
    800053f4:	f052                	sd	s4,32(sp)
    800053f6:	ec56                	sd	s5,24(sp)
    800053f8:	0880                	addi	s0,sp,80
    800053fa:	89ae                	mv	s3,a1
    800053fc:	8ab2                	mv	s5,a2
    800053fe:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005400:	fb040593          	addi	a1,s0,-80
    80005404:	fffff097          	auipc	ra,0xfffff
    80005408:	db4080e7          	jalr	-588(ra) # 800041b8 <nameiparent>
    8000540c:	892a                	mv	s2,a0
    8000540e:	12050f63          	beqz	a0,8000554c <create+0x164>
    return 0;

  ilock(dp);
    80005412:	ffffe097          	auipc	ra,0xffffe
    80005416:	5ce080e7          	jalr	1486(ra) # 800039e0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000541a:	4601                	li	a2,0
    8000541c:	fb040593          	addi	a1,s0,-80
    80005420:	854a                	mv	a0,s2
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	a9e080e7          	jalr	-1378(ra) # 80003ec0 <dirlookup>
    8000542a:	84aa                	mv	s1,a0
    8000542c:	c921                	beqz	a0,8000547c <create+0x94>
    iunlockput(dp);
    8000542e:	854a                	mv	a0,s2
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	814080e7          	jalr	-2028(ra) # 80003c44 <iunlockput>
    ilock(ip);
    80005438:	8526                	mv	a0,s1
    8000543a:	ffffe097          	auipc	ra,0xffffe
    8000543e:	5a6080e7          	jalr	1446(ra) # 800039e0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005442:	2981                	sext.w	s3,s3
    80005444:	4789                	li	a5,2
    80005446:	02f99463          	bne	s3,a5,8000546e <create+0x86>
    8000544a:	0444d783          	lhu	a5,68(s1)
    8000544e:	37f9                	addiw	a5,a5,-2
    80005450:	17c2                	slli	a5,a5,0x30
    80005452:	93c1                	srli	a5,a5,0x30
    80005454:	4705                	li	a4,1
    80005456:	00f76c63          	bltu	a4,a5,8000546e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000545a:	8526                	mv	a0,s1
    8000545c:	60a6                	ld	ra,72(sp)
    8000545e:	6406                	ld	s0,64(sp)
    80005460:	74e2                	ld	s1,56(sp)
    80005462:	7942                	ld	s2,48(sp)
    80005464:	79a2                	ld	s3,40(sp)
    80005466:	7a02                	ld	s4,32(sp)
    80005468:	6ae2                	ld	s5,24(sp)
    8000546a:	6161                	addi	sp,sp,80
    8000546c:	8082                	ret
    iunlockput(ip);
    8000546e:	8526                	mv	a0,s1
    80005470:	ffffe097          	auipc	ra,0xffffe
    80005474:	7d4080e7          	jalr	2004(ra) # 80003c44 <iunlockput>
    return 0;
    80005478:	4481                	li	s1,0
    8000547a:	b7c5                	j	8000545a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000547c:	85ce                	mv	a1,s3
    8000547e:	00092503          	lw	a0,0(s2)
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	3c2080e7          	jalr	962(ra) # 80003844 <ialloc>
    8000548a:	84aa                	mv	s1,a0
    8000548c:	c529                	beqz	a0,800054d6 <create+0xee>
  ilock(ip);
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	552080e7          	jalr	1362(ra) # 800039e0 <ilock>
  ip->major = major;
    80005496:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000549a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000549e:	4785                	li	a5,1
    800054a0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054a4:	8526                	mv	a0,s1
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	46e080e7          	jalr	1134(ra) # 80003914 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054ae:	2981                	sext.w	s3,s3
    800054b0:	4785                	li	a5,1
    800054b2:	02f98a63          	beq	s3,a5,800054e6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800054b6:	40d0                	lw	a2,4(s1)
    800054b8:	fb040593          	addi	a1,s0,-80
    800054bc:	854a                	mv	a0,s2
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	c1a080e7          	jalr	-998(ra) # 800040d8 <dirlink>
    800054c6:	06054b63          	bltz	a0,8000553c <create+0x154>
  iunlockput(dp);
    800054ca:	854a                	mv	a0,s2
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	778080e7          	jalr	1912(ra) # 80003c44 <iunlockput>
  return ip;
    800054d4:	b759                	j	8000545a <create+0x72>
    panic("create: ialloc");
    800054d6:	00003517          	auipc	a0,0x3
    800054da:	30a50513          	addi	a0,a0,778 # 800087e0 <syscalls+0x2d8>
    800054de:	ffffb097          	auipc	ra,0xffffb
    800054e2:	096080e7          	jalr	150(ra) # 80000574 <panic>
    dp->nlink++;  // for ".."
    800054e6:	04a95783          	lhu	a5,74(s2)
    800054ea:	2785                	addiw	a5,a5,1
    800054ec:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800054f0:	854a                	mv	a0,s2
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	422080e7          	jalr	1058(ra) # 80003914 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800054fa:	40d0                	lw	a2,4(s1)
    800054fc:	00003597          	auipc	a1,0x3
    80005500:	2f458593          	addi	a1,a1,756 # 800087f0 <syscalls+0x2e8>
    80005504:	8526                	mv	a0,s1
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	bd2080e7          	jalr	-1070(ra) # 800040d8 <dirlink>
    8000550e:	00054f63          	bltz	a0,8000552c <create+0x144>
    80005512:	00492603          	lw	a2,4(s2)
    80005516:	00003597          	auipc	a1,0x3
    8000551a:	d9a58593          	addi	a1,a1,-614 # 800082b0 <indent.1777+0x1e0>
    8000551e:	8526                	mv	a0,s1
    80005520:	fffff097          	auipc	ra,0xfffff
    80005524:	bb8080e7          	jalr	-1096(ra) # 800040d8 <dirlink>
    80005528:	f80557e3          	bgez	a0,800054b6 <create+0xce>
      panic("create dots");
    8000552c:	00003517          	auipc	a0,0x3
    80005530:	2cc50513          	addi	a0,a0,716 # 800087f8 <syscalls+0x2f0>
    80005534:	ffffb097          	auipc	ra,0xffffb
    80005538:	040080e7          	jalr	64(ra) # 80000574 <panic>
    panic("create: dirlink");
    8000553c:	00003517          	auipc	a0,0x3
    80005540:	2cc50513          	addi	a0,a0,716 # 80008808 <syscalls+0x300>
    80005544:	ffffb097          	auipc	ra,0xffffb
    80005548:	030080e7          	jalr	48(ra) # 80000574 <panic>
    return 0;
    8000554c:	84aa                	mv	s1,a0
    8000554e:	b731                	j	8000545a <create+0x72>

0000000080005550 <sys_dup>:
{
    80005550:	7179                	addi	sp,sp,-48
    80005552:	f406                	sd	ra,40(sp)
    80005554:	f022                	sd	s0,32(sp)
    80005556:	ec26                	sd	s1,24(sp)
    80005558:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000555a:	fd840613          	addi	a2,s0,-40
    8000555e:	4581                	li	a1,0
    80005560:	4501                	li	a0,0
    80005562:	00000097          	auipc	ra,0x0
    80005566:	dd6080e7          	jalr	-554(ra) # 80005338 <argfd>
    return -1;
    8000556a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000556c:	02054363          	bltz	a0,80005592 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005570:	fd843503          	ld	a0,-40(s0)
    80005574:	00000097          	auipc	ra,0x0
    80005578:	e2c080e7          	jalr	-468(ra) # 800053a0 <fdalloc>
    8000557c:	84aa                	mv	s1,a0
    return -1;
    8000557e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005580:	00054963          	bltz	a0,80005592 <sys_dup+0x42>
  filedup(f);
    80005584:	fd843503          	ld	a0,-40(s0)
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	2d0080e7          	jalr	720(ra) # 80004858 <filedup>
  return fd;
    80005590:	87a6                	mv	a5,s1
}
    80005592:	853e                	mv	a0,a5
    80005594:	70a2                	ld	ra,40(sp)
    80005596:	7402                	ld	s0,32(sp)
    80005598:	64e2                	ld	s1,24(sp)
    8000559a:	6145                	addi	sp,sp,48
    8000559c:	8082                	ret

000000008000559e <sys_read>:
{
    8000559e:	7179                	addi	sp,sp,-48
    800055a0:	f406                	sd	ra,40(sp)
    800055a2:	f022                	sd	s0,32(sp)
    800055a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055a6:	fe840613          	addi	a2,s0,-24
    800055aa:	4581                	li	a1,0
    800055ac:	4501                	li	a0,0
    800055ae:	00000097          	auipc	ra,0x0
    800055b2:	d8a080e7          	jalr	-630(ra) # 80005338 <argfd>
    return -1;
    800055b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055b8:	04054163          	bltz	a0,800055fa <sys_read+0x5c>
    800055bc:	fe440593          	addi	a1,s0,-28
    800055c0:	4509                	li	a0,2
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	85e080e7          	jalr	-1954(ra) # 80002e20 <argint>
    return -1;
    800055ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055cc:	02054763          	bltz	a0,800055fa <sys_read+0x5c>
    800055d0:	fd840593          	addi	a1,s0,-40
    800055d4:	4505                	li	a0,1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	86c080e7          	jalr	-1940(ra) # 80002e42 <argaddr>
    return -1;
    800055de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055e0:	00054d63          	bltz	a0,800055fa <sys_read+0x5c>
  return fileread(f, p, n);
    800055e4:	fe442603          	lw	a2,-28(s0)
    800055e8:	fd843583          	ld	a1,-40(s0)
    800055ec:	fe843503          	ld	a0,-24(s0)
    800055f0:	fffff097          	auipc	ra,0xfffff
    800055f4:	3f4080e7          	jalr	1012(ra) # 800049e4 <fileread>
    800055f8:	87aa                	mv	a5,a0
}
    800055fa:	853e                	mv	a0,a5
    800055fc:	70a2                	ld	ra,40(sp)
    800055fe:	7402                	ld	s0,32(sp)
    80005600:	6145                	addi	sp,sp,48
    80005602:	8082                	ret

0000000080005604 <sys_write>:
{
    80005604:	7179                	addi	sp,sp,-48
    80005606:	f406                	sd	ra,40(sp)
    80005608:	f022                	sd	s0,32(sp)
    8000560a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000560c:	fe840613          	addi	a2,s0,-24
    80005610:	4581                	li	a1,0
    80005612:	4501                	li	a0,0
    80005614:	00000097          	auipc	ra,0x0
    80005618:	d24080e7          	jalr	-732(ra) # 80005338 <argfd>
    return -1;
    8000561c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000561e:	04054163          	bltz	a0,80005660 <sys_write+0x5c>
    80005622:	fe440593          	addi	a1,s0,-28
    80005626:	4509                	li	a0,2
    80005628:	ffffd097          	auipc	ra,0xffffd
    8000562c:	7f8080e7          	jalr	2040(ra) # 80002e20 <argint>
    return -1;
    80005630:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005632:	02054763          	bltz	a0,80005660 <sys_write+0x5c>
    80005636:	fd840593          	addi	a1,s0,-40
    8000563a:	4505                	li	a0,1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	806080e7          	jalr	-2042(ra) # 80002e42 <argaddr>
    return -1;
    80005644:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005646:	00054d63          	bltz	a0,80005660 <sys_write+0x5c>
  return filewrite(f, p, n);
    8000564a:	fe442603          	lw	a2,-28(s0)
    8000564e:	fd843583          	ld	a1,-40(s0)
    80005652:	fe843503          	ld	a0,-24(s0)
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	450080e7          	jalr	1104(ra) # 80004aa6 <filewrite>
    8000565e:	87aa                	mv	a5,a0
}
    80005660:	853e                	mv	a0,a5
    80005662:	70a2                	ld	ra,40(sp)
    80005664:	7402                	ld	s0,32(sp)
    80005666:	6145                	addi	sp,sp,48
    80005668:	8082                	ret

000000008000566a <sys_close>:
{
    8000566a:	1101                	addi	sp,sp,-32
    8000566c:	ec06                	sd	ra,24(sp)
    8000566e:	e822                	sd	s0,16(sp)
    80005670:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005672:	fe040613          	addi	a2,s0,-32
    80005676:	fec40593          	addi	a1,s0,-20
    8000567a:	4501                	li	a0,0
    8000567c:	00000097          	auipc	ra,0x0
    80005680:	cbc080e7          	jalr	-836(ra) # 80005338 <argfd>
    return -1;
    80005684:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005686:	02054463          	bltz	a0,800056ae <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000568a:	ffffc097          	auipc	ra,0xffffc
    8000568e:	4ce080e7          	jalr	1230(ra) # 80001b58 <myproc>
    80005692:	fec42783          	lw	a5,-20(s0)
    80005696:	07e9                	addi	a5,a5,26
    80005698:	078e                	slli	a5,a5,0x3
    8000569a:	953e                	add	a0,a0,a5
    8000569c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800056a0:	fe043503          	ld	a0,-32(s0)
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	206080e7          	jalr	518(ra) # 800048aa <fileclose>
  return 0;
    800056ac:	4781                	li	a5,0
}
    800056ae:	853e                	mv	a0,a5
    800056b0:	60e2                	ld	ra,24(sp)
    800056b2:	6442                	ld	s0,16(sp)
    800056b4:	6105                	addi	sp,sp,32
    800056b6:	8082                	ret

00000000800056b8 <sys_fstat>:
{
    800056b8:	1101                	addi	sp,sp,-32
    800056ba:	ec06                	sd	ra,24(sp)
    800056bc:	e822                	sd	s0,16(sp)
    800056be:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056c0:	fe840613          	addi	a2,s0,-24
    800056c4:	4581                	li	a1,0
    800056c6:	4501                	li	a0,0
    800056c8:	00000097          	auipc	ra,0x0
    800056cc:	c70080e7          	jalr	-912(ra) # 80005338 <argfd>
    return -1;
    800056d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056d2:	02054563          	bltz	a0,800056fc <sys_fstat+0x44>
    800056d6:	fe040593          	addi	a1,s0,-32
    800056da:	4505                	li	a0,1
    800056dc:	ffffd097          	auipc	ra,0xffffd
    800056e0:	766080e7          	jalr	1894(ra) # 80002e42 <argaddr>
    return -1;
    800056e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800056e6:	00054b63          	bltz	a0,800056fc <sys_fstat+0x44>
  return filestat(f, st);
    800056ea:	fe043583          	ld	a1,-32(s0)
    800056ee:	fe843503          	ld	a0,-24(s0)
    800056f2:	fffff097          	auipc	ra,0xfffff
    800056f6:	280080e7          	jalr	640(ra) # 80004972 <filestat>
    800056fa:	87aa                	mv	a5,a0
}
    800056fc:	853e                	mv	a0,a5
    800056fe:	60e2                	ld	ra,24(sp)
    80005700:	6442                	ld	s0,16(sp)
    80005702:	6105                	addi	sp,sp,32
    80005704:	8082                	ret

0000000080005706 <sys_link>:
{
    80005706:	7169                	addi	sp,sp,-304
    80005708:	f606                	sd	ra,296(sp)
    8000570a:	f222                	sd	s0,288(sp)
    8000570c:	ee26                	sd	s1,280(sp)
    8000570e:	ea4a                	sd	s2,272(sp)
    80005710:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005712:	08000613          	li	a2,128
    80005716:	ed040593          	addi	a1,s0,-304
    8000571a:	4501                	li	a0,0
    8000571c:	ffffd097          	auipc	ra,0xffffd
    80005720:	748080e7          	jalr	1864(ra) # 80002e64 <argstr>
    return -1;
    80005724:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005726:	10054e63          	bltz	a0,80005842 <sys_link+0x13c>
    8000572a:	08000613          	li	a2,128
    8000572e:	f5040593          	addi	a1,s0,-176
    80005732:	4505                	li	a0,1
    80005734:	ffffd097          	auipc	ra,0xffffd
    80005738:	730080e7          	jalr	1840(ra) # 80002e64 <argstr>
    return -1;
    8000573c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000573e:	10054263          	bltz	a0,80005842 <sys_link+0x13c>
  begin_op();
    80005742:	fffff097          	auipc	ra,0xfffff
    80005746:	c66080e7          	jalr	-922(ra) # 800043a8 <begin_op>
  if((ip = namei(old)) == 0){
    8000574a:	ed040513          	addi	a0,s0,-304
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	a4c080e7          	jalr	-1460(ra) # 8000419a <namei>
    80005756:	84aa                	mv	s1,a0
    80005758:	c551                	beqz	a0,800057e4 <sys_link+0xde>
  ilock(ip);
    8000575a:	ffffe097          	auipc	ra,0xffffe
    8000575e:	286080e7          	jalr	646(ra) # 800039e0 <ilock>
  if(ip->type == T_DIR){
    80005762:	04449703          	lh	a4,68(s1)
    80005766:	4785                	li	a5,1
    80005768:	08f70463          	beq	a4,a5,800057f0 <sys_link+0xea>
  ip->nlink++;
    8000576c:	04a4d783          	lhu	a5,74(s1)
    80005770:	2785                	addiw	a5,a5,1
    80005772:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005776:	8526                	mv	a0,s1
    80005778:	ffffe097          	auipc	ra,0xffffe
    8000577c:	19c080e7          	jalr	412(ra) # 80003914 <iupdate>
  iunlock(ip);
    80005780:	8526                	mv	a0,s1
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	322080e7          	jalr	802(ra) # 80003aa4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000578a:	fd040593          	addi	a1,s0,-48
    8000578e:	f5040513          	addi	a0,s0,-176
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	a26080e7          	jalr	-1498(ra) # 800041b8 <nameiparent>
    8000579a:	892a                	mv	s2,a0
    8000579c:	c935                	beqz	a0,80005810 <sys_link+0x10a>
  ilock(dp);
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	242080e7          	jalr	578(ra) # 800039e0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057a6:	00092703          	lw	a4,0(s2)
    800057aa:	409c                	lw	a5,0(s1)
    800057ac:	04f71d63          	bne	a4,a5,80005806 <sys_link+0x100>
    800057b0:	40d0                	lw	a2,4(s1)
    800057b2:	fd040593          	addi	a1,s0,-48
    800057b6:	854a                	mv	a0,s2
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	920080e7          	jalr	-1760(ra) # 800040d8 <dirlink>
    800057c0:	04054363          	bltz	a0,80005806 <sys_link+0x100>
  iunlockput(dp);
    800057c4:	854a                	mv	a0,s2
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	47e080e7          	jalr	1150(ra) # 80003c44 <iunlockput>
  iput(ip);
    800057ce:	8526                	mv	a0,s1
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	3cc080e7          	jalr	972(ra) # 80003b9c <iput>
  end_op();
    800057d8:	fffff097          	auipc	ra,0xfffff
    800057dc:	c50080e7          	jalr	-944(ra) # 80004428 <end_op>
  return 0;
    800057e0:	4781                	li	a5,0
    800057e2:	a085                	j	80005842 <sys_link+0x13c>
    end_op();
    800057e4:	fffff097          	auipc	ra,0xfffff
    800057e8:	c44080e7          	jalr	-956(ra) # 80004428 <end_op>
    return -1;
    800057ec:	57fd                	li	a5,-1
    800057ee:	a891                	j	80005842 <sys_link+0x13c>
    iunlockput(ip);
    800057f0:	8526                	mv	a0,s1
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	452080e7          	jalr	1106(ra) # 80003c44 <iunlockput>
    end_op();
    800057fa:	fffff097          	auipc	ra,0xfffff
    800057fe:	c2e080e7          	jalr	-978(ra) # 80004428 <end_op>
    return -1;
    80005802:	57fd                	li	a5,-1
    80005804:	a83d                	j	80005842 <sys_link+0x13c>
    iunlockput(dp);
    80005806:	854a                	mv	a0,s2
    80005808:	ffffe097          	auipc	ra,0xffffe
    8000580c:	43c080e7          	jalr	1084(ra) # 80003c44 <iunlockput>
  ilock(ip);
    80005810:	8526                	mv	a0,s1
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	1ce080e7          	jalr	462(ra) # 800039e0 <ilock>
  ip->nlink--;
    8000581a:	04a4d783          	lhu	a5,74(s1)
    8000581e:	37fd                	addiw	a5,a5,-1
    80005820:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	0ee080e7          	jalr	238(ra) # 80003914 <iupdate>
  iunlockput(ip);
    8000582e:	8526                	mv	a0,s1
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	414080e7          	jalr	1044(ra) # 80003c44 <iunlockput>
  end_op();
    80005838:	fffff097          	auipc	ra,0xfffff
    8000583c:	bf0080e7          	jalr	-1040(ra) # 80004428 <end_op>
  return -1;
    80005840:	57fd                	li	a5,-1
}
    80005842:	853e                	mv	a0,a5
    80005844:	70b2                	ld	ra,296(sp)
    80005846:	7412                	ld	s0,288(sp)
    80005848:	64f2                	ld	s1,280(sp)
    8000584a:	6952                	ld	s2,272(sp)
    8000584c:	6155                	addi	sp,sp,304
    8000584e:	8082                	ret

0000000080005850 <sys_unlink>:
{
    80005850:	7151                	addi	sp,sp,-240
    80005852:	f586                	sd	ra,232(sp)
    80005854:	f1a2                	sd	s0,224(sp)
    80005856:	eda6                	sd	s1,216(sp)
    80005858:	e9ca                	sd	s2,208(sp)
    8000585a:	e5ce                	sd	s3,200(sp)
    8000585c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000585e:	08000613          	li	a2,128
    80005862:	f3040593          	addi	a1,s0,-208
    80005866:	4501                	li	a0,0
    80005868:	ffffd097          	auipc	ra,0xffffd
    8000586c:	5fc080e7          	jalr	1532(ra) # 80002e64 <argstr>
    80005870:	16054f63          	bltz	a0,800059ee <sys_unlink+0x19e>
  begin_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	b34080e7          	jalr	-1228(ra) # 800043a8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000587c:	fb040593          	addi	a1,s0,-80
    80005880:	f3040513          	addi	a0,s0,-208
    80005884:	fffff097          	auipc	ra,0xfffff
    80005888:	934080e7          	jalr	-1740(ra) # 800041b8 <nameiparent>
    8000588c:	89aa                	mv	s3,a0
    8000588e:	c979                	beqz	a0,80005964 <sys_unlink+0x114>
  ilock(dp);
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	150080e7          	jalr	336(ra) # 800039e0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005898:	00003597          	auipc	a1,0x3
    8000589c:	f5858593          	addi	a1,a1,-168 # 800087f0 <syscalls+0x2e8>
    800058a0:	fb040513          	addi	a0,s0,-80
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	602080e7          	jalr	1538(ra) # 80003ea6 <namecmp>
    800058ac:	14050863          	beqz	a0,800059fc <sys_unlink+0x1ac>
    800058b0:	00003597          	auipc	a1,0x3
    800058b4:	a0058593          	addi	a1,a1,-1536 # 800082b0 <indent.1777+0x1e0>
    800058b8:	fb040513          	addi	a0,s0,-80
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	5ea080e7          	jalr	1514(ra) # 80003ea6 <namecmp>
    800058c4:	12050c63          	beqz	a0,800059fc <sys_unlink+0x1ac>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800058c8:	f2c40613          	addi	a2,s0,-212
    800058cc:	fb040593          	addi	a1,s0,-80
    800058d0:	854e                	mv	a0,s3
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	5ee080e7          	jalr	1518(ra) # 80003ec0 <dirlookup>
    800058da:	84aa                	mv	s1,a0
    800058dc:	12050063          	beqz	a0,800059fc <sys_unlink+0x1ac>
  ilock(ip);
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	100080e7          	jalr	256(ra) # 800039e0 <ilock>
  if(ip->nlink < 1)
    800058e8:	04a49783          	lh	a5,74(s1)
    800058ec:	08f05263          	blez	a5,80005970 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800058f0:	04449703          	lh	a4,68(s1)
    800058f4:	4785                	li	a5,1
    800058f6:	08f70563          	beq	a4,a5,80005980 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800058fa:	4641                	li	a2,16
    800058fc:	4581                	li	a1,0
    800058fe:	fc040513          	addi	a0,s0,-64
    80005902:	ffffb097          	auipc	ra,0xffffb
    80005906:	45c080e7          	jalr	1116(ra) # 80000d5e <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000590a:	4741                	li	a4,16
    8000590c:	f2c42683          	lw	a3,-212(s0)
    80005910:	fc040613          	addi	a2,s0,-64
    80005914:	4581                	li	a1,0
    80005916:	854e                	mv	a0,s3
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	474080e7          	jalr	1140(ra) # 80003d8c <writei>
    80005920:	47c1                	li	a5,16
    80005922:	0af51363          	bne	a0,a5,800059c8 <sys_unlink+0x178>
  if(ip->type == T_DIR){
    80005926:	04449703          	lh	a4,68(s1)
    8000592a:	4785                	li	a5,1
    8000592c:	0af70663          	beq	a4,a5,800059d8 <sys_unlink+0x188>
  iunlockput(dp);
    80005930:	854e                	mv	a0,s3
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	312080e7          	jalr	786(ra) # 80003c44 <iunlockput>
  ip->nlink--;
    8000593a:	04a4d783          	lhu	a5,74(s1)
    8000593e:	37fd                	addiw	a5,a5,-1
    80005940:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005944:	8526                	mv	a0,s1
    80005946:	ffffe097          	auipc	ra,0xffffe
    8000594a:	fce080e7          	jalr	-50(ra) # 80003914 <iupdate>
  iunlockput(ip);
    8000594e:	8526                	mv	a0,s1
    80005950:	ffffe097          	auipc	ra,0xffffe
    80005954:	2f4080e7          	jalr	756(ra) # 80003c44 <iunlockput>
  end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	ad0080e7          	jalr	-1328(ra) # 80004428 <end_op>
  return 0;
    80005960:	4501                	li	a0,0
    80005962:	a07d                	j	80005a10 <sys_unlink+0x1c0>
    end_op();
    80005964:	fffff097          	auipc	ra,0xfffff
    80005968:	ac4080e7          	jalr	-1340(ra) # 80004428 <end_op>
    return -1;
    8000596c:	557d                	li	a0,-1
    8000596e:	a04d                	j	80005a10 <sys_unlink+0x1c0>
    panic("unlink: nlink < 1");
    80005970:	00003517          	auipc	a0,0x3
    80005974:	ea850513          	addi	a0,a0,-344 # 80008818 <syscalls+0x310>
    80005978:	ffffb097          	auipc	ra,0xffffb
    8000597c:	bfc080e7          	jalr	-1028(ra) # 80000574 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005980:	44f8                	lw	a4,76(s1)
    80005982:	02000793          	li	a5,32
    80005986:	f6e7fae3          	bleu	a4,a5,800058fa <sys_unlink+0xaa>
    8000598a:	02000913          	li	s2,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000598e:	4741                	li	a4,16
    80005990:	86ca                	mv	a3,s2
    80005992:	f1840613          	addi	a2,s0,-232
    80005996:	4581                	li	a1,0
    80005998:	8526                	mv	a0,s1
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	2fc080e7          	jalr	764(ra) # 80003c96 <readi>
    800059a2:	47c1                	li	a5,16
    800059a4:	00f51a63          	bne	a0,a5,800059b8 <sys_unlink+0x168>
    if(de.inum != 0)
    800059a8:	f1845783          	lhu	a5,-232(s0)
    800059ac:	e3b9                	bnez	a5,800059f2 <sys_unlink+0x1a2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059ae:	2941                	addiw	s2,s2,16
    800059b0:	44fc                	lw	a5,76(s1)
    800059b2:	fcf96ee3          	bltu	s2,a5,8000598e <sys_unlink+0x13e>
    800059b6:	b791                	j	800058fa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059b8:	00003517          	auipc	a0,0x3
    800059bc:	e7850513          	addi	a0,a0,-392 # 80008830 <syscalls+0x328>
    800059c0:	ffffb097          	auipc	ra,0xffffb
    800059c4:	bb4080e7          	jalr	-1100(ra) # 80000574 <panic>
    panic("unlink: writei");
    800059c8:	00003517          	auipc	a0,0x3
    800059cc:	e8050513          	addi	a0,a0,-384 # 80008848 <syscalls+0x340>
    800059d0:	ffffb097          	auipc	ra,0xffffb
    800059d4:	ba4080e7          	jalr	-1116(ra) # 80000574 <panic>
    dp->nlink--;
    800059d8:	04a9d783          	lhu	a5,74(s3)
    800059dc:	37fd                	addiw	a5,a5,-1
    800059de:	04f99523          	sh	a5,74(s3)
    iupdate(dp);
    800059e2:	854e                	mv	a0,s3
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	f30080e7          	jalr	-208(ra) # 80003914 <iupdate>
    800059ec:	b791                	j	80005930 <sys_unlink+0xe0>
    return -1;
    800059ee:	557d                	li	a0,-1
    800059f0:	a005                	j	80005a10 <sys_unlink+0x1c0>
    iunlockput(ip);
    800059f2:	8526                	mv	a0,s1
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	250080e7          	jalr	592(ra) # 80003c44 <iunlockput>
  iunlockput(dp);
    800059fc:	854e                	mv	a0,s3
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	246080e7          	jalr	582(ra) # 80003c44 <iunlockput>
  end_op();
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	a22080e7          	jalr	-1502(ra) # 80004428 <end_op>
  return -1;
    80005a0e:	557d                	li	a0,-1
}
    80005a10:	70ae                	ld	ra,232(sp)
    80005a12:	740e                	ld	s0,224(sp)
    80005a14:	64ee                	ld	s1,216(sp)
    80005a16:	694e                	ld	s2,208(sp)
    80005a18:	69ae                	ld	s3,200(sp)
    80005a1a:	616d                	addi	sp,sp,240
    80005a1c:	8082                	ret

0000000080005a1e <sys_open>:

uint64
sys_open(void)
{
    80005a1e:	7131                	addi	sp,sp,-192
    80005a20:	fd06                	sd	ra,184(sp)
    80005a22:	f922                	sd	s0,176(sp)
    80005a24:	f526                	sd	s1,168(sp)
    80005a26:	f14a                	sd	s2,160(sp)
    80005a28:	ed4e                	sd	s3,152(sp)
    80005a2a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a2c:	08000613          	li	a2,128
    80005a30:	f5040593          	addi	a1,s0,-176
    80005a34:	4501                	li	a0,0
    80005a36:	ffffd097          	auipc	ra,0xffffd
    80005a3a:	42e080e7          	jalr	1070(ra) # 80002e64 <argstr>
    return -1;
    80005a3e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005a40:	0c054163          	bltz	a0,80005b02 <sys_open+0xe4>
    80005a44:	f4c40593          	addi	a1,s0,-180
    80005a48:	4505                	li	a0,1
    80005a4a:	ffffd097          	auipc	ra,0xffffd
    80005a4e:	3d6080e7          	jalr	982(ra) # 80002e20 <argint>
    80005a52:	0a054863          	bltz	a0,80005b02 <sys_open+0xe4>

  begin_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	952080e7          	jalr	-1710(ra) # 800043a8 <begin_op>

  if(omode & O_CREATE){
    80005a5e:	f4c42783          	lw	a5,-180(s0)
    80005a62:	2007f793          	andi	a5,a5,512
    80005a66:	cbdd                	beqz	a5,80005b1c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005a68:	4681                	li	a3,0
    80005a6a:	4601                	li	a2,0
    80005a6c:	4589                	li	a1,2
    80005a6e:	f5040513          	addi	a0,s0,-176
    80005a72:	00000097          	auipc	ra,0x0
    80005a76:	976080e7          	jalr	-1674(ra) # 800053e8 <create>
    80005a7a:	892a                	mv	s2,a0
    if(ip == 0){
    80005a7c:	c959                	beqz	a0,80005b12 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a7e:	04491703          	lh	a4,68(s2)
    80005a82:	478d                	li	a5,3
    80005a84:	00f71763          	bne	a4,a5,80005a92 <sys_open+0x74>
    80005a88:	04695703          	lhu	a4,70(s2)
    80005a8c:	47a5                	li	a5,9
    80005a8e:	0ce7ec63          	bltu	a5,a4,80005b66 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a92:	fffff097          	auipc	ra,0xfffff
    80005a96:	d48080e7          	jalr	-696(ra) # 800047da <filealloc>
    80005a9a:	89aa                	mv	s3,a0
    80005a9c:	10050263          	beqz	a0,80005ba0 <sys_open+0x182>
    80005aa0:	00000097          	auipc	ra,0x0
    80005aa4:	900080e7          	jalr	-1792(ra) # 800053a0 <fdalloc>
    80005aa8:	84aa                	mv	s1,a0
    80005aaa:	0e054663          	bltz	a0,80005b96 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005aae:	04491703          	lh	a4,68(s2)
    80005ab2:	478d                	li	a5,3
    80005ab4:	0cf70463          	beq	a4,a5,80005b7c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ab8:	4789                	li	a5,2
    80005aba:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005abe:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005ac2:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005ac6:	f4c42783          	lw	a5,-180(s0)
    80005aca:	0017c713          	xori	a4,a5,1
    80005ace:	8b05                	andi	a4,a4,1
    80005ad0:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ad4:	0037f713          	andi	a4,a5,3
    80005ad8:	00e03733          	snez	a4,a4
    80005adc:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ae0:	4007f793          	andi	a5,a5,1024
    80005ae4:	c791                	beqz	a5,80005af0 <sys_open+0xd2>
    80005ae6:	04491703          	lh	a4,68(s2)
    80005aea:	4789                	li	a5,2
    80005aec:	08f70f63          	beq	a4,a5,80005b8a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005af0:	854a                	mv	a0,s2
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	fb2080e7          	jalr	-78(ra) # 80003aa4 <iunlock>
  end_op();
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	92e080e7          	jalr	-1746(ra) # 80004428 <end_op>

  return fd;
}
    80005b02:	8526                	mv	a0,s1
    80005b04:	70ea                	ld	ra,184(sp)
    80005b06:	744a                	ld	s0,176(sp)
    80005b08:	74aa                	ld	s1,168(sp)
    80005b0a:	790a                	ld	s2,160(sp)
    80005b0c:	69ea                	ld	s3,152(sp)
    80005b0e:	6129                	addi	sp,sp,192
    80005b10:	8082                	ret
      end_op();
    80005b12:	fffff097          	auipc	ra,0xfffff
    80005b16:	916080e7          	jalr	-1770(ra) # 80004428 <end_op>
      return -1;
    80005b1a:	b7e5                	j	80005b02 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b1c:	f5040513          	addi	a0,s0,-176
    80005b20:	ffffe097          	auipc	ra,0xffffe
    80005b24:	67a080e7          	jalr	1658(ra) # 8000419a <namei>
    80005b28:	892a                	mv	s2,a0
    80005b2a:	c905                	beqz	a0,80005b5a <sys_open+0x13c>
    ilock(ip);
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	eb4080e7          	jalr	-332(ra) # 800039e0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b34:	04491703          	lh	a4,68(s2)
    80005b38:	4785                	li	a5,1
    80005b3a:	f4f712e3          	bne	a4,a5,80005a7e <sys_open+0x60>
    80005b3e:	f4c42783          	lw	a5,-180(s0)
    80005b42:	dba1                	beqz	a5,80005a92 <sys_open+0x74>
      iunlockput(ip);
    80005b44:	854a                	mv	a0,s2
    80005b46:	ffffe097          	auipc	ra,0xffffe
    80005b4a:	0fe080e7          	jalr	254(ra) # 80003c44 <iunlockput>
      end_op();
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	8da080e7          	jalr	-1830(ra) # 80004428 <end_op>
      return -1;
    80005b56:	54fd                	li	s1,-1
    80005b58:	b76d                	j	80005b02 <sys_open+0xe4>
      end_op();
    80005b5a:	fffff097          	auipc	ra,0xfffff
    80005b5e:	8ce080e7          	jalr	-1842(ra) # 80004428 <end_op>
      return -1;
    80005b62:	54fd                	li	s1,-1
    80005b64:	bf79                	j	80005b02 <sys_open+0xe4>
    iunlockput(ip);
    80005b66:	854a                	mv	a0,s2
    80005b68:	ffffe097          	auipc	ra,0xffffe
    80005b6c:	0dc080e7          	jalr	220(ra) # 80003c44 <iunlockput>
    end_op();
    80005b70:	fffff097          	auipc	ra,0xfffff
    80005b74:	8b8080e7          	jalr	-1864(ra) # 80004428 <end_op>
    return -1;
    80005b78:	54fd                	li	s1,-1
    80005b7a:	b761                	j	80005b02 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b7c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b80:	04691783          	lh	a5,70(s2)
    80005b84:	02f99223          	sh	a5,36(s3)
    80005b88:	bf2d                	j	80005ac2 <sys_open+0xa4>
    itrunc(ip);
    80005b8a:	854a                	mv	a0,s2
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	f64080e7          	jalr	-156(ra) # 80003af0 <itrunc>
    80005b94:	bfb1                	j	80005af0 <sys_open+0xd2>
      fileclose(f);
    80005b96:	854e                	mv	a0,s3
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	d12080e7          	jalr	-750(ra) # 800048aa <fileclose>
    iunlockput(ip);
    80005ba0:	854a                	mv	a0,s2
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	0a2080e7          	jalr	162(ra) # 80003c44 <iunlockput>
    end_op();
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	87e080e7          	jalr	-1922(ra) # 80004428 <end_op>
    return -1;
    80005bb2:	54fd                	li	s1,-1
    80005bb4:	b7b9                	j	80005b02 <sys_open+0xe4>

0000000080005bb6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bb6:	7175                	addi	sp,sp,-144
    80005bb8:	e506                	sd	ra,136(sp)
    80005bba:	e122                	sd	s0,128(sp)
    80005bbc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	7ea080e7          	jalr	2026(ra) # 800043a8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005bc6:	08000613          	li	a2,128
    80005bca:	f7040593          	addi	a1,s0,-144
    80005bce:	4501                	li	a0,0
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	294080e7          	jalr	660(ra) # 80002e64 <argstr>
    80005bd8:	02054963          	bltz	a0,80005c0a <sys_mkdir+0x54>
    80005bdc:	4681                	li	a3,0
    80005bde:	4601                	li	a2,0
    80005be0:	4585                	li	a1,1
    80005be2:	f7040513          	addi	a0,s0,-144
    80005be6:	00000097          	auipc	ra,0x0
    80005bea:	802080e7          	jalr	-2046(ra) # 800053e8 <create>
    80005bee:	cd11                	beqz	a0,80005c0a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	054080e7          	jalr	84(ra) # 80003c44 <iunlockput>
  end_op();
    80005bf8:	fffff097          	auipc	ra,0xfffff
    80005bfc:	830080e7          	jalr	-2000(ra) # 80004428 <end_op>
  return 0;
    80005c00:	4501                	li	a0,0
}
    80005c02:	60aa                	ld	ra,136(sp)
    80005c04:	640a                	ld	s0,128(sp)
    80005c06:	6149                	addi	sp,sp,144
    80005c08:	8082                	ret
    end_op();
    80005c0a:	fffff097          	auipc	ra,0xfffff
    80005c0e:	81e080e7          	jalr	-2018(ra) # 80004428 <end_op>
    return -1;
    80005c12:	557d                	li	a0,-1
    80005c14:	b7fd                	j	80005c02 <sys_mkdir+0x4c>

0000000080005c16 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c16:	7135                	addi	sp,sp,-160
    80005c18:	ed06                	sd	ra,152(sp)
    80005c1a:	e922                	sd	s0,144(sp)
    80005c1c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c1e:	ffffe097          	auipc	ra,0xffffe
    80005c22:	78a080e7          	jalr	1930(ra) # 800043a8 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c26:	08000613          	li	a2,128
    80005c2a:	f7040593          	addi	a1,s0,-144
    80005c2e:	4501                	li	a0,0
    80005c30:	ffffd097          	auipc	ra,0xffffd
    80005c34:	234080e7          	jalr	564(ra) # 80002e64 <argstr>
    80005c38:	04054a63          	bltz	a0,80005c8c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005c3c:	f6c40593          	addi	a1,s0,-148
    80005c40:	4505                	li	a0,1
    80005c42:	ffffd097          	auipc	ra,0xffffd
    80005c46:	1de080e7          	jalr	478(ra) # 80002e20 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c4a:	04054163          	bltz	a0,80005c8c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005c4e:	f6840593          	addi	a1,s0,-152
    80005c52:	4509                	li	a0,2
    80005c54:	ffffd097          	auipc	ra,0xffffd
    80005c58:	1cc080e7          	jalr	460(ra) # 80002e20 <argint>
     argint(1, &major) < 0 ||
    80005c5c:	02054863          	bltz	a0,80005c8c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c60:	f6841683          	lh	a3,-152(s0)
    80005c64:	f6c41603          	lh	a2,-148(s0)
    80005c68:	458d                	li	a1,3
    80005c6a:	f7040513          	addi	a0,s0,-144
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	77a080e7          	jalr	1914(ra) # 800053e8 <create>
     argint(2, &minor) < 0 ||
    80005c76:	c919                	beqz	a0,80005c8c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c78:	ffffe097          	auipc	ra,0xffffe
    80005c7c:	fcc080e7          	jalr	-52(ra) # 80003c44 <iunlockput>
  end_op();
    80005c80:	ffffe097          	auipc	ra,0xffffe
    80005c84:	7a8080e7          	jalr	1960(ra) # 80004428 <end_op>
  return 0;
    80005c88:	4501                	li	a0,0
    80005c8a:	a031                	j	80005c96 <sys_mknod+0x80>
    end_op();
    80005c8c:	ffffe097          	auipc	ra,0xffffe
    80005c90:	79c080e7          	jalr	1948(ra) # 80004428 <end_op>
    return -1;
    80005c94:	557d                	li	a0,-1
}
    80005c96:	60ea                	ld	ra,152(sp)
    80005c98:	644a                	ld	s0,144(sp)
    80005c9a:	610d                	addi	sp,sp,160
    80005c9c:	8082                	ret

0000000080005c9e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c9e:	7135                	addi	sp,sp,-160
    80005ca0:	ed06                	sd	ra,152(sp)
    80005ca2:	e922                	sd	s0,144(sp)
    80005ca4:	e526                	sd	s1,136(sp)
    80005ca6:	e14a                	sd	s2,128(sp)
    80005ca8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005caa:	ffffc097          	auipc	ra,0xffffc
    80005cae:	eae080e7          	jalr	-338(ra) # 80001b58 <myproc>
    80005cb2:	892a                	mv	s2,a0
  
  begin_op();
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	6f4080e7          	jalr	1780(ra) # 800043a8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005cbc:	08000613          	li	a2,128
    80005cc0:	f6040593          	addi	a1,s0,-160
    80005cc4:	4501                	li	a0,0
    80005cc6:	ffffd097          	auipc	ra,0xffffd
    80005cca:	19e080e7          	jalr	414(ra) # 80002e64 <argstr>
    80005cce:	04054b63          	bltz	a0,80005d24 <sys_chdir+0x86>
    80005cd2:	f6040513          	addi	a0,s0,-160
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	4c4080e7          	jalr	1220(ra) # 8000419a <namei>
    80005cde:	84aa                	mv	s1,a0
    80005ce0:	c131                	beqz	a0,80005d24 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	cfe080e7          	jalr	-770(ra) # 800039e0 <ilock>
  if(ip->type != T_DIR){
    80005cea:	04449703          	lh	a4,68(s1)
    80005cee:	4785                	li	a5,1
    80005cf0:	04f71063          	bne	a4,a5,80005d30 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005cf4:	8526                	mv	a0,s1
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	dae080e7          	jalr	-594(ra) # 80003aa4 <iunlock>
  iput(p->cwd);
    80005cfe:	15093503          	ld	a0,336(s2)
    80005d02:	ffffe097          	auipc	ra,0xffffe
    80005d06:	e9a080e7          	jalr	-358(ra) # 80003b9c <iput>
  end_op();
    80005d0a:	ffffe097          	auipc	ra,0xffffe
    80005d0e:	71e080e7          	jalr	1822(ra) # 80004428 <end_op>
  p->cwd = ip;
    80005d12:	14993823          	sd	s1,336(s2)
  return 0;
    80005d16:	4501                	li	a0,0
}
    80005d18:	60ea                	ld	ra,152(sp)
    80005d1a:	644a                	ld	s0,144(sp)
    80005d1c:	64aa                	ld	s1,136(sp)
    80005d1e:	690a                	ld	s2,128(sp)
    80005d20:	610d                	addi	sp,sp,160
    80005d22:	8082                	ret
    end_op();
    80005d24:	ffffe097          	auipc	ra,0xffffe
    80005d28:	704080e7          	jalr	1796(ra) # 80004428 <end_op>
    return -1;
    80005d2c:	557d                	li	a0,-1
    80005d2e:	b7ed                	j	80005d18 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d30:	8526                	mv	a0,s1
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	f12080e7          	jalr	-238(ra) # 80003c44 <iunlockput>
    end_op();
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	6ee080e7          	jalr	1774(ra) # 80004428 <end_op>
    return -1;
    80005d42:	557d                	li	a0,-1
    80005d44:	bfd1                	j	80005d18 <sys_chdir+0x7a>

0000000080005d46 <sys_exec>:

uint64
sys_exec(void)
{
    80005d46:	7145                	addi	sp,sp,-464
    80005d48:	e786                	sd	ra,456(sp)
    80005d4a:	e3a2                	sd	s0,448(sp)
    80005d4c:	ff26                	sd	s1,440(sp)
    80005d4e:	fb4a                	sd	s2,432(sp)
    80005d50:	f74e                	sd	s3,424(sp)
    80005d52:	f352                	sd	s4,416(sp)
    80005d54:	ef56                	sd	s5,408(sp)
    80005d56:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d58:	08000613          	li	a2,128
    80005d5c:	f4040593          	addi	a1,s0,-192
    80005d60:	4501                	li	a0,0
    80005d62:	ffffd097          	auipc	ra,0xffffd
    80005d66:	102080e7          	jalr	258(ra) # 80002e64 <argstr>
    return -1;
    80005d6a:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005d6c:	0e054c63          	bltz	a0,80005e64 <sys_exec+0x11e>
    80005d70:	e3840593          	addi	a1,s0,-456
    80005d74:	4505                	li	a0,1
    80005d76:	ffffd097          	auipc	ra,0xffffd
    80005d7a:	0cc080e7          	jalr	204(ra) # 80002e42 <argaddr>
    80005d7e:	0e054363          	bltz	a0,80005e64 <sys_exec+0x11e>
  }
  memset(argv, 0, sizeof(argv));
    80005d82:	e4040913          	addi	s2,s0,-448
    80005d86:	10000613          	li	a2,256
    80005d8a:	4581                	li	a1,0
    80005d8c:	854a                	mv	a0,s2
    80005d8e:	ffffb097          	auipc	ra,0xffffb
    80005d92:	fd0080e7          	jalr	-48(ra) # 80000d5e <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d96:	89ca                	mv	s3,s2
  memset(argv, 0, sizeof(argv));
    80005d98:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    80005d9a:	02000a93          	li	s5,32
    80005d9e:	00048a1b          	sext.w	s4,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005da2:	00349513          	slli	a0,s1,0x3
    80005da6:	e3040593          	addi	a1,s0,-464
    80005daa:	e3843783          	ld	a5,-456(s0)
    80005dae:	953e                	add	a0,a0,a5
    80005db0:	ffffd097          	auipc	ra,0xffffd
    80005db4:	fd4080e7          	jalr	-44(ra) # 80002d84 <fetchaddr>
    80005db8:	02054a63          	bltz	a0,80005dec <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005dbc:	e3043783          	ld	a5,-464(s0)
    80005dc0:	cfa9                	beqz	a5,80005e1a <sys_exec+0xd4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005dc2:	ffffb097          	auipc	ra,0xffffb
    80005dc6:	db0080e7          	jalr	-592(ra) # 80000b72 <kalloc>
    80005dca:	00a93023          	sd	a0,0(s2)
    if(argv[i] == 0)
    80005dce:	cd19                	beqz	a0,80005dec <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005dd0:	6605                	lui	a2,0x1
    80005dd2:	85aa                	mv	a1,a0
    80005dd4:	e3043503          	ld	a0,-464(s0)
    80005dd8:	ffffd097          	auipc	ra,0xffffd
    80005ddc:	000080e7          	jalr	ra # 80002dd8 <fetchstr>
    80005de0:	00054663          	bltz	a0,80005dec <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005de4:	0485                	addi	s1,s1,1
    80005de6:	0921                	addi	s2,s2,8
    80005de8:	fb549be3          	bne	s1,s5,80005d9e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dec:	e4043503          	ld	a0,-448(s0)
    kfree(argv[i]);
  return -1;
    80005df0:	597d                	li	s2,-1
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005df2:	c92d                	beqz	a0,80005e64 <sys_exec+0x11e>
    kfree(argv[i]);
    80005df4:	ffffb097          	auipc	ra,0xffffb
    80005df8:	c7e080e7          	jalr	-898(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dfc:	e4840493          	addi	s1,s0,-440
    80005e00:	10098993          	addi	s3,s3,256
    80005e04:	6088                	ld	a0,0(s1)
    80005e06:	cd31                	beqz	a0,80005e62 <sys_exec+0x11c>
    kfree(argv[i]);
    80005e08:	ffffb097          	auipc	ra,0xffffb
    80005e0c:	c6a080e7          	jalr	-918(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e10:	04a1                	addi	s1,s1,8
    80005e12:	ff3499e3          	bne	s1,s3,80005e04 <sys_exec+0xbe>
  return -1;
    80005e16:	597d                	li	s2,-1
    80005e18:	a0b1                	j	80005e64 <sys_exec+0x11e>
      argv[i] = 0;
    80005e1a:	0a0e                	slli	s4,s4,0x3
    80005e1c:	fc040793          	addi	a5,s0,-64
    80005e20:	9a3e                	add	s4,s4,a5
    80005e22:	e80a3023          	sd	zero,-384(s4)
  int ret = exec(path, argv);
    80005e26:	e4040593          	addi	a1,s0,-448
    80005e2a:	f4040513          	addi	a0,s0,-192
    80005e2e:	fffff097          	auipc	ra,0xfffff
    80005e32:	13c080e7          	jalr	316(ra) # 80004f6a <exec>
    80005e36:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e38:	e4043503          	ld	a0,-448(s0)
    80005e3c:	c505                	beqz	a0,80005e64 <sys_exec+0x11e>
    kfree(argv[i]);
    80005e3e:	ffffb097          	auipc	ra,0xffffb
    80005e42:	c34080e7          	jalr	-972(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e46:	e4840493          	addi	s1,s0,-440
    80005e4a:	10098993          	addi	s3,s3,256
    80005e4e:	6088                	ld	a0,0(s1)
    80005e50:	c911                	beqz	a0,80005e64 <sys_exec+0x11e>
    kfree(argv[i]);
    80005e52:	ffffb097          	auipc	ra,0xffffb
    80005e56:	c20080e7          	jalr	-992(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e5a:	04a1                	addi	s1,s1,8
    80005e5c:	ff3499e3          	bne	s1,s3,80005e4e <sys_exec+0x108>
    80005e60:	a011                	j	80005e64 <sys_exec+0x11e>
  return -1;
    80005e62:	597d                	li	s2,-1
}
    80005e64:	854a                	mv	a0,s2
    80005e66:	60be                	ld	ra,456(sp)
    80005e68:	641e                	ld	s0,448(sp)
    80005e6a:	74fa                	ld	s1,440(sp)
    80005e6c:	795a                	ld	s2,432(sp)
    80005e6e:	79ba                	ld	s3,424(sp)
    80005e70:	7a1a                	ld	s4,416(sp)
    80005e72:	6afa                	ld	s5,408(sp)
    80005e74:	6179                	addi	sp,sp,464
    80005e76:	8082                	ret

0000000080005e78 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e78:	7139                	addi	sp,sp,-64
    80005e7a:	fc06                	sd	ra,56(sp)
    80005e7c:	f822                	sd	s0,48(sp)
    80005e7e:	f426                	sd	s1,40(sp)
    80005e80:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e82:	ffffc097          	auipc	ra,0xffffc
    80005e86:	cd6080e7          	jalr	-810(ra) # 80001b58 <myproc>
    80005e8a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005e8c:	fd840593          	addi	a1,s0,-40
    80005e90:	4501                	li	a0,0
    80005e92:	ffffd097          	auipc	ra,0xffffd
    80005e96:	fb0080e7          	jalr	-80(ra) # 80002e42 <argaddr>
    return -1;
    80005e9a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e9c:	0c054f63          	bltz	a0,80005f7a <sys_pipe+0x102>
  if(pipealloc(&rf, &wf) < 0)
    80005ea0:	fc840593          	addi	a1,s0,-56
    80005ea4:	fd040513          	addi	a0,s0,-48
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	d4a080e7          	jalr	-694(ra) # 80004bf2 <pipealloc>
    return -1;
    80005eb0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005eb2:	0c054463          	bltz	a0,80005f7a <sys_pipe+0x102>
  fd0 = -1;
    80005eb6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005eba:	fd043503          	ld	a0,-48(s0)
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	4e2080e7          	jalr	1250(ra) # 800053a0 <fdalloc>
    80005ec6:	fca42223          	sw	a0,-60(s0)
    80005eca:	08054b63          	bltz	a0,80005f60 <sys_pipe+0xe8>
    80005ece:	fc843503          	ld	a0,-56(s0)
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	4ce080e7          	jalr	1230(ra) # 800053a0 <fdalloc>
    80005eda:	fca42023          	sw	a0,-64(s0)
    80005ede:	06054863          	bltz	a0,80005f4e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ee2:	4691                	li	a3,4
    80005ee4:	fc440613          	addi	a2,s0,-60
    80005ee8:	fd843583          	ld	a1,-40(s0)
    80005eec:	68a8                	ld	a0,80(s1)
    80005eee:	ffffc097          	auipc	ra,0xffffc
    80005ef2:	86e080e7          	jalr	-1938(ra) # 8000175c <copyout>
    80005ef6:	02054063          	bltz	a0,80005f16 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005efa:	4691                	li	a3,4
    80005efc:	fc040613          	addi	a2,s0,-64
    80005f00:	fd843583          	ld	a1,-40(s0)
    80005f04:	0591                	addi	a1,a1,4
    80005f06:	68a8                	ld	a0,80(s1)
    80005f08:	ffffc097          	auipc	ra,0xffffc
    80005f0c:	854080e7          	jalr	-1964(ra) # 8000175c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f10:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f12:	06055463          	bgez	a0,80005f7a <sys_pipe+0x102>
    p->ofile[fd0] = 0;
    80005f16:	fc442783          	lw	a5,-60(s0)
    80005f1a:	07e9                	addi	a5,a5,26
    80005f1c:	078e                	slli	a5,a5,0x3
    80005f1e:	97a6                	add	a5,a5,s1
    80005f20:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f24:	fc042783          	lw	a5,-64(s0)
    80005f28:	07e9                	addi	a5,a5,26
    80005f2a:	078e                	slli	a5,a5,0x3
    80005f2c:	94be                	add	s1,s1,a5
    80005f2e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f32:	fd043503          	ld	a0,-48(s0)
    80005f36:	fffff097          	auipc	ra,0xfffff
    80005f3a:	974080e7          	jalr	-1676(ra) # 800048aa <fileclose>
    fileclose(wf);
    80005f3e:	fc843503          	ld	a0,-56(s0)
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	968080e7          	jalr	-1688(ra) # 800048aa <fileclose>
    return -1;
    80005f4a:	57fd                	li	a5,-1
    80005f4c:	a03d                	j	80005f7a <sys_pipe+0x102>
    if(fd0 >= 0)
    80005f4e:	fc442783          	lw	a5,-60(s0)
    80005f52:	0007c763          	bltz	a5,80005f60 <sys_pipe+0xe8>
      p->ofile[fd0] = 0;
    80005f56:	07e9                	addi	a5,a5,26
    80005f58:	078e                	slli	a5,a5,0x3
    80005f5a:	94be                	add	s1,s1,a5
    80005f5c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f60:	fd043503          	ld	a0,-48(s0)
    80005f64:	fffff097          	auipc	ra,0xfffff
    80005f68:	946080e7          	jalr	-1722(ra) # 800048aa <fileclose>
    fileclose(wf);
    80005f6c:	fc843503          	ld	a0,-56(s0)
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	93a080e7          	jalr	-1734(ra) # 800048aa <fileclose>
    return -1;
    80005f78:	57fd                	li	a5,-1
}
    80005f7a:	853e                	mv	a0,a5
    80005f7c:	70e2                	ld	ra,56(sp)
    80005f7e:	7442                	ld	s0,48(sp)
    80005f80:	74a2                	ld	s1,40(sp)
    80005f82:	6121                	addi	sp,sp,64
    80005f84:	8082                	ret
	...

0000000080005f90 <kernelvec>:
    80005f90:	7111                	addi	sp,sp,-256
    80005f92:	e006                	sd	ra,0(sp)
    80005f94:	e40a                	sd	sp,8(sp)
    80005f96:	e80e                	sd	gp,16(sp)
    80005f98:	ec12                	sd	tp,24(sp)
    80005f9a:	f016                	sd	t0,32(sp)
    80005f9c:	f41a                	sd	t1,40(sp)
    80005f9e:	f81e                	sd	t2,48(sp)
    80005fa0:	fc22                	sd	s0,56(sp)
    80005fa2:	e0a6                	sd	s1,64(sp)
    80005fa4:	e4aa                	sd	a0,72(sp)
    80005fa6:	e8ae                	sd	a1,80(sp)
    80005fa8:	ecb2                	sd	a2,88(sp)
    80005faa:	f0b6                	sd	a3,96(sp)
    80005fac:	f4ba                	sd	a4,104(sp)
    80005fae:	f8be                	sd	a5,112(sp)
    80005fb0:	fcc2                	sd	a6,120(sp)
    80005fb2:	e146                	sd	a7,128(sp)
    80005fb4:	e54a                	sd	s2,136(sp)
    80005fb6:	e94e                	sd	s3,144(sp)
    80005fb8:	ed52                	sd	s4,152(sp)
    80005fba:	f156                	sd	s5,160(sp)
    80005fbc:	f55a                	sd	s6,168(sp)
    80005fbe:	f95e                	sd	s7,176(sp)
    80005fc0:	fd62                	sd	s8,184(sp)
    80005fc2:	e1e6                	sd	s9,192(sp)
    80005fc4:	e5ea                	sd	s10,200(sp)
    80005fc6:	e9ee                	sd	s11,208(sp)
    80005fc8:	edf2                	sd	t3,216(sp)
    80005fca:	f1f6                	sd	t4,224(sp)
    80005fcc:	f5fa                	sd	t5,232(sp)
    80005fce:	f9fe                	sd	t6,240(sp)
    80005fd0:	c7dfc0ef          	jal	ra,80002c4c <kerneltrap>
    80005fd4:	6082                	ld	ra,0(sp)
    80005fd6:	6122                	ld	sp,8(sp)
    80005fd8:	61c2                	ld	gp,16(sp)
    80005fda:	7282                	ld	t0,32(sp)
    80005fdc:	7322                	ld	t1,40(sp)
    80005fde:	73c2                	ld	t2,48(sp)
    80005fe0:	7462                	ld	s0,56(sp)
    80005fe2:	6486                	ld	s1,64(sp)
    80005fe4:	6526                	ld	a0,72(sp)
    80005fe6:	65c6                	ld	a1,80(sp)
    80005fe8:	6666                	ld	a2,88(sp)
    80005fea:	7686                	ld	a3,96(sp)
    80005fec:	7726                	ld	a4,104(sp)
    80005fee:	77c6                	ld	a5,112(sp)
    80005ff0:	7866                	ld	a6,120(sp)
    80005ff2:	688a                	ld	a7,128(sp)
    80005ff4:	692a                	ld	s2,136(sp)
    80005ff6:	69ca                	ld	s3,144(sp)
    80005ff8:	6a6a                	ld	s4,152(sp)
    80005ffa:	7a8a                	ld	s5,160(sp)
    80005ffc:	7b2a                	ld	s6,168(sp)
    80005ffe:	7bca                	ld	s7,176(sp)
    80006000:	7c6a                	ld	s8,184(sp)
    80006002:	6c8e                	ld	s9,192(sp)
    80006004:	6d2e                	ld	s10,200(sp)
    80006006:	6dce                	ld	s11,208(sp)
    80006008:	6e6e                	ld	t3,216(sp)
    8000600a:	7e8e                	ld	t4,224(sp)
    8000600c:	7f2e                	ld	t5,232(sp)
    8000600e:	7fce                	ld	t6,240(sp)
    80006010:	6111                	addi	sp,sp,256
    80006012:	10200073          	sret
    80006016:	00000013          	nop
    8000601a:	00000013          	nop
    8000601e:	0001                	nop

0000000080006020 <timervec>:
    80006020:	34051573          	csrrw	a0,mscratch,a0
    80006024:	e10c                	sd	a1,0(a0)
    80006026:	e510                	sd	a2,8(a0)
    80006028:	e914                	sd	a3,16(a0)
    8000602a:	710c                	ld	a1,32(a0)
    8000602c:	7510                	ld	a2,40(a0)
    8000602e:	6194                	ld	a3,0(a1)
    80006030:	96b2                	add	a3,a3,a2
    80006032:	e194                	sd	a3,0(a1)
    80006034:	4589                	li	a1,2
    80006036:	14459073          	csrw	sip,a1
    8000603a:	6914                	ld	a3,16(a0)
    8000603c:	6510                	ld	a2,8(a0)
    8000603e:	610c                	ld	a1,0(a0)
    80006040:	34051573          	csrrw	a0,mscratch,a0
    80006044:	30200073          	mret
	...

000000008000604a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000604a:	1141                	addi	sp,sp,-16
    8000604c:	e422                	sd	s0,8(sp)
    8000604e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006050:	0c0007b7          	lui	a5,0xc000
    80006054:	4705                	li	a4,1
    80006056:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006058:	c3d8                	sw	a4,4(a5)
}
    8000605a:	6422                	ld	s0,8(sp)
    8000605c:	0141                	addi	sp,sp,16
    8000605e:	8082                	ret

0000000080006060 <plicinithart>:

void
plicinithart(void)
{
    80006060:	1141                	addi	sp,sp,-16
    80006062:	e406                	sd	ra,8(sp)
    80006064:	e022                	sd	s0,0(sp)
    80006066:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006068:	ffffc097          	auipc	ra,0xffffc
    8000606c:	ac4080e7          	jalr	-1340(ra) # 80001b2c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006070:	0085171b          	slliw	a4,a0,0x8
    80006074:	0c0027b7          	lui	a5,0xc002
    80006078:	97ba                	add	a5,a5,a4
    8000607a:	40200713          	li	a4,1026
    8000607e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006082:	00d5151b          	slliw	a0,a0,0xd
    80006086:	0c2017b7          	lui	a5,0xc201
    8000608a:	953e                	add	a0,a0,a5
    8000608c:	00052023          	sw	zero,0(a0)
}
    80006090:	60a2                	ld	ra,8(sp)
    80006092:	6402                	ld	s0,0(sp)
    80006094:	0141                	addi	sp,sp,16
    80006096:	8082                	ret

0000000080006098 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006098:	1141                	addi	sp,sp,-16
    8000609a:	e406                	sd	ra,8(sp)
    8000609c:	e022                	sd	s0,0(sp)
    8000609e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060a0:	ffffc097          	auipc	ra,0xffffc
    800060a4:	a8c080e7          	jalr	-1396(ra) # 80001b2c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060a8:	00d5151b          	slliw	a0,a0,0xd
    800060ac:	0c2017b7          	lui	a5,0xc201
    800060b0:	97aa                	add	a5,a5,a0
  return irq;
}
    800060b2:	43c8                	lw	a0,4(a5)
    800060b4:	60a2                	ld	ra,8(sp)
    800060b6:	6402                	ld	s0,0(sp)
    800060b8:	0141                	addi	sp,sp,16
    800060ba:	8082                	ret

00000000800060bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060bc:	1101                	addi	sp,sp,-32
    800060be:	ec06                	sd	ra,24(sp)
    800060c0:	e822                	sd	s0,16(sp)
    800060c2:	e426                	sd	s1,8(sp)
    800060c4:	1000                	addi	s0,sp,32
    800060c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060c8:	ffffc097          	auipc	ra,0xffffc
    800060cc:	a64080e7          	jalr	-1436(ra) # 80001b2c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060d0:	00d5151b          	slliw	a0,a0,0xd
    800060d4:	0c2017b7          	lui	a5,0xc201
    800060d8:	97aa                	add	a5,a5,a0
    800060da:	c3c4                	sw	s1,4(a5)
}
    800060dc:	60e2                	ld	ra,24(sp)
    800060de:	6442                	ld	s0,16(sp)
    800060e0:	64a2                	ld	s1,8(sp)
    800060e2:	6105                	addi	sp,sp,32
    800060e4:	8082                	ret

00000000800060e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060e6:	1141                	addi	sp,sp,-16
    800060e8:	e406                	sd	ra,8(sp)
    800060ea:	e022                	sd	s0,0(sp)
    800060ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060ee:	479d                	li	a5,7
    800060f0:	04a7cd63          	blt	a5,a0,8000614a <free_desc+0x64>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    800060f4:	0001d797          	auipc	a5,0x1d
    800060f8:	f0c78793          	addi	a5,a5,-244 # 80023000 <disk>
    800060fc:	00a78733          	add	a4,a5,a0
    80006100:	6789                	lui	a5,0x2
    80006102:	97ba                	add	a5,a5,a4
    80006104:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006108:	eba9                	bnez	a5,8000615a <free_desc+0x74>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000610a:	0001f797          	auipc	a5,0x1f
    8000610e:	ef678793          	addi	a5,a5,-266 # 80025000 <disk+0x2000>
    80006112:	639c                	ld	a5,0(a5)
    80006114:	00451713          	slli	a4,a0,0x4
    80006118:	97ba                	add	a5,a5,a4
    8000611a:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000611e:	0001d797          	auipc	a5,0x1d
    80006122:	ee278793          	addi	a5,a5,-286 # 80023000 <disk>
    80006126:	97aa                	add	a5,a5,a0
    80006128:	6509                	lui	a0,0x2
    8000612a:	953e                	add	a0,a0,a5
    8000612c:	4785                	li	a5,1
    8000612e:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80006132:	0001f517          	auipc	a0,0x1f
    80006136:	ee650513          	addi	a0,a0,-282 # 80025018 <disk+0x2018>
    8000613a:	ffffc097          	auipc	ra,0xffffc
    8000613e:	5b6080e7          	jalr	1462(ra) # 800026f0 <wakeup>
}
    80006142:	60a2                	ld	ra,8(sp)
    80006144:	6402                	ld	s0,0(sp)
    80006146:	0141                	addi	sp,sp,16
    80006148:	8082                	ret
    panic("virtio_disk_intr 1");
    8000614a:	00002517          	auipc	a0,0x2
    8000614e:	70e50513          	addi	a0,a0,1806 # 80008858 <syscalls+0x350>
    80006152:	ffffa097          	auipc	ra,0xffffa
    80006156:	422080e7          	jalr	1058(ra) # 80000574 <panic>
    panic("virtio_disk_intr 2");
    8000615a:	00002517          	auipc	a0,0x2
    8000615e:	71650513          	addi	a0,a0,1814 # 80008870 <syscalls+0x368>
    80006162:	ffffa097          	auipc	ra,0xffffa
    80006166:	412080e7          	jalr	1042(ra) # 80000574 <panic>

000000008000616a <virtio_disk_init>:
{
    8000616a:	1101                	addi	sp,sp,-32
    8000616c:	ec06                	sd	ra,24(sp)
    8000616e:	e822                	sd	s0,16(sp)
    80006170:	e426                	sd	s1,8(sp)
    80006172:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006174:	00002597          	auipc	a1,0x2
    80006178:	71458593          	addi	a1,a1,1812 # 80008888 <syscalls+0x380>
    8000617c:	0001f517          	auipc	a0,0x1f
    80006180:	f2c50513          	addi	a0,a0,-212 # 800250a8 <disk+0x20a8>
    80006184:	ffffb097          	auipc	ra,0xffffb
    80006188:	a4e080e7          	jalr	-1458(ra) # 80000bd2 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000618c:	100017b7          	lui	a5,0x10001
    80006190:	4398                	lw	a4,0(a5)
    80006192:	2701                	sext.w	a4,a4
    80006194:	747277b7          	lui	a5,0x74727
    80006198:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000619c:	0ef71163          	bne	a4,a5,8000627e <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061a0:	100017b7          	lui	a5,0x10001
    800061a4:	43dc                	lw	a5,4(a5)
    800061a6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061a8:	4705                	li	a4,1
    800061aa:	0ce79a63          	bne	a5,a4,8000627e <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061ae:	100017b7          	lui	a5,0x10001
    800061b2:	479c                	lw	a5,8(a5)
    800061b4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800061b6:	4709                	li	a4,2
    800061b8:	0ce79363          	bne	a5,a4,8000627e <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061bc:	100017b7          	lui	a5,0x10001
    800061c0:	47d8                	lw	a4,12(a5)
    800061c2:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061c4:	554d47b7          	lui	a5,0x554d4
    800061c8:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061cc:	0af71963          	bne	a4,a5,8000627e <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061d0:	100017b7          	lui	a5,0x10001
    800061d4:	4705                	li	a4,1
    800061d6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061d8:	470d                	li	a4,3
    800061da:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061dc:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061de:	c7ffe737          	lui	a4,0xc7ffe
    800061e2:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    800061e6:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061e8:	2701                	sext.w	a4,a4
    800061ea:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061ec:	472d                	li	a4,11
    800061ee:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061f0:	473d                	li	a4,15
    800061f2:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800061f4:	6705                	lui	a4,0x1
    800061f6:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800061f8:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800061fc:	5bdc                	lw	a5,52(a5)
    800061fe:	2781                	sext.w	a5,a5
  if(max == 0)
    80006200:	c7d9                	beqz	a5,8000628e <virtio_disk_init+0x124>
  if(max < NUM)
    80006202:	471d                	li	a4,7
    80006204:	08f77d63          	bleu	a5,a4,8000629e <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006208:	100014b7          	lui	s1,0x10001
    8000620c:	47a1                	li	a5,8
    8000620e:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006210:	6609                	lui	a2,0x2
    80006212:	4581                	li	a1,0
    80006214:	0001d517          	auipc	a0,0x1d
    80006218:	dec50513          	addi	a0,a0,-532 # 80023000 <disk>
    8000621c:	ffffb097          	auipc	ra,0xffffb
    80006220:	b42080e7          	jalr	-1214(ra) # 80000d5e <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006224:	0001d717          	auipc	a4,0x1d
    80006228:	ddc70713          	addi	a4,a4,-548 # 80023000 <disk>
    8000622c:	00c75793          	srli	a5,a4,0xc
    80006230:	2781                	sext.w	a5,a5
    80006232:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80006234:	0001f797          	auipc	a5,0x1f
    80006238:	dcc78793          	addi	a5,a5,-564 # 80025000 <disk+0x2000>
    8000623c:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    8000623e:	0001d717          	auipc	a4,0x1d
    80006242:	e4270713          	addi	a4,a4,-446 # 80023080 <disk+0x80>
    80006246:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80006248:	0001e717          	auipc	a4,0x1e
    8000624c:	db870713          	addi	a4,a4,-584 # 80024000 <disk+0x1000>
    80006250:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80006252:	4705                	li	a4,1
    80006254:	00e78c23          	sb	a4,24(a5)
    80006258:	00e78ca3          	sb	a4,25(a5)
    8000625c:	00e78d23          	sb	a4,26(a5)
    80006260:	00e78da3          	sb	a4,27(a5)
    80006264:	00e78e23          	sb	a4,28(a5)
    80006268:	00e78ea3          	sb	a4,29(a5)
    8000626c:	00e78f23          	sb	a4,30(a5)
    80006270:	00e78fa3          	sb	a4,31(a5)
}
    80006274:	60e2                	ld	ra,24(sp)
    80006276:	6442                	ld	s0,16(sp)
    80006278:	64a2                	ld	s1,8(sp)
    8000627a:	6105                	addi	sp,sp,32
    8000627c:	8082                	ret
    panic("could not find virtio disk");
    8000627e:	00002517          	auipc	a0,0x2
    80006282:	61a50513          	addi	a0,a0,1562 # 80008898 <syscalls+0x390>
    80006286:	ffffa097          	auipc	ra,0xffffa
    8000628a:	2ee080e7          	jalr	750(ra) # 80000574 <panic>
    panic("virtio disk has no queue 0");
    8000628e:	00002517          	auipc	a0,0x2
    80006292:	62a50513          	addi	a0,a0,1578 # 800088b8 <syscalls+0x3b0>
    80006296:	ffffa097          	auipc	ra,0xffffa
    8000629a:	2de080e7          	jalr	734(ra) # 80000574 <panic>
    panic("virtio disk max queue too short");
    8000629e:	00002517          	auipc	a0,0x2
    800062a2:	63a50513          	addi	a0,a0,1594 # 800088d8 <syscalls+0x3d0>
    800062a6:	ffffa097          	auipc	ra,0xffffa
    800062aa:	2ce080e7          	jalr	718(ra) # 80000574 <panic>

00000000800062ae <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800062ae:	7159                	addi	sp,sp,-112
    800062b0:	f486                	sd	ra,104(sp)
    800062b2:	f0a2                	sd	s0,96(sp)
    800062b4:	eca6                	sd	s1,88(sp)
    800062b6:	e8ca                	sd	s2,80(sp)
    800062b8:	e4ce                	sd	s3,72(sp)
    800062ba:	e0d2                	sd	s4,64(sp)
    800062bc:	fc56                	sd	s5,56(sp)
    800062be:	f85a                	sd	s6,48(sp)
    800062c0:	f45e                	sd	s7,40(sp)
    800062c2:	f062                	sd	s8,32(sp)
    800062c4:	1880                	addi	s0,sp,112
    800062c6:	892a                	mv	s2,a0
    800062c8:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062ca:	00c52b83          	lw	s7,12(a0)
    800062ce:	001b9b9b          	slliw	s7,s7,0x1
    800062d2:	1b82                	slli	s7,s7,0x20
    800062d4:	020bdb93          	srli	s7,s7,0x20

  acquire(&disk.vdisk_lock);
    800062d8:	0001f517          	auipc	a0,0x1f
    800062dc:	dd050513          	addi	a0,a0,-560 # 800250a8 <disk+0x20a8>
    800062e0:	ffffb097          	auipc	ra,0xffffb
    800062e4:	982080e7          	jalr	-1662(ra) # 80000c62 <acquire>
    if(disk.free[i]){
    800062e8:	0001f997          	auipc	s3,0x1f
    800062ec:	d1898993          	addi	s3,s3,-744 # 80025000 <disk+0x2000>
  for(int i = 0; i < NUM; i++){
    800062f0:	4b21                	li	s6,8
      disk.free[i] = 0;
    800062f2:	0001da97          	auipc	s5,0x1d
    800062f6:	d0ea8a93          	addi	s5,s5,-754 # 80023000 <disk>
  for(int i = 0; i < 3; i++){
    800062fa:	4a0d                	li	s4,3
    800062fc:	a079                	j	8000638a <virtio_disk_rw+0xdc>
      disk.free[i] = 0;
    800062fe:	00fa86b3          	add	a3,s5,a5
    80006302:	96ae                	add	a3,a3,a1
    80006304:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006308:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000630a:	0207ca63          	bltz	a5,8000633e <virtio_disk_rw+0x90>
  for(int i = 0; i < 3; i++){
    8000630e:	2485                	addiw	s1,s1,1
    80006310:	0711                	addi	a4,a4,4
    80006312:	25448163          	beq	s1,s4,80006554 <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006316:	863a                	mv	a2,a4
    if(disk.free[i]){
    80006318:	0189c783          	lbu	a5,24(s3)
    8000631c:	24079163          	bnez	a5,8000655e <virtio_disk_rw+0x2b0>
    80006320:	0001f697          	auipc	a3,0x1f
    80006324:	cf968693          	addi	a3,a3,-775 # 80025019 <disk+0x2019>
  for(int i = 0; i < NUM; i++){
    80006328:	87aa                	mv	a5,a0
    if(disk.free[i]){
    8000632a:	0006c803          	lbu	a6,0(a3)
    8000632e:	fc0818e3          	bnez	a6,800062fe <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80006332:	2785                	addiw	a5,a5,1
    80006334:	0685                	addi	a3,a3,1
    80006336:	ff679ae3          	bne	a5,s6,8000632a <virtio_disk_rw+0x7c>
    idx[i] = alloc_desc();
    8000633a:	57fd                	li	a5,-1
    8000633c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000633e:	02905a63          	blez	s1,80006372 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    80006342:	fa042503          	lw	a0,-96(s0)
    80006346:	00000097          	auipc	ra,0x0
    8000634a:	da0080e7          	jalr	-608(ra) # 800060e6 <free_desc>
      for(int j = 0; j < i; j++)
    8000634e:	4785                	li	a5,1
    80006350:	0297d163          	ble	s1,a5,80006372 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    80006354:	fa442503          	lw	a0,-92(s0)
    80006358:	00000097          	auipc	ra,0x0
    8000635c:	d8e080e7          	jalr	-626(ra) # 800060e6 <free_desc>
      for(int j = 0; j < i; j++)
    80006360:	4789                	li	a5,2
    80006362:	0097d863          	ble	s1,a5,80006372 <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    80006366:	fa842503          	lw	a0,-88(s0)
    8000636a:	00000097          	auipc	ra,0x0
    8000636e:	d7c080e7          	jalr	-644(ra) # 800060e6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006372:	0001f597          	auipc	a1,0x1f
    80006376:	d3658593          	addi	a1,a1,-714 # 800250a8 <disk+0x20a8>
    8000637a:	0001f517          	auipc	a0,0x1f
    8000637e:	c9e50513          	addi	a0,a0,-866 # 80025018 <disk+0x2018>
    80006382:	ffffc097          	auipc	ra,0xffffc
    80006386:	1e8080e7          	jalr	488(ra) # 8000256a <sleep>
  for(int i = 0; i < 3; i++){
    8000638a:	fa040713          	addi	a4,s0,-96
    8000638e:	4481                	li	s1,0
  for(int i = 0; i < NUM; i++){
    80006390:	4505                	li	a0,1
      disk.free[i] = 0;
    80006392:	6589                	lui	a1,0x2
    80006394:	b749                	j	80006316 <virtio_disk_rw+0x68>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006396:	4785                	li	a5,1
    80006398:	f8f42823          	sw	a5,-112(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000639c:	f8042a23          	sw	zero,-108(s0)
  buf0.sector = sector;
    800063a0:	f9743c23          	sd	s7,-104(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800063a4:	fa042983          	lw	s3,-96(s0)
    800063a8:	00499493          	slli	s1,s3,0x4
    800063ac:	0001fa17          	auipc	s4,0x1f
    800063b0:	c54a0a13          	addi	s4,s4,-940 # 80025000 <disk+0x2000>
    800063b4:	000a3a83          	ld	s5,0(s4)
    800063b8:	9aa6                	add	s5,s5,s1
    800063ba:	f9040513          	addi	a0,s0,-112
    800063be:	ffffb097          	auipc	ra,0xffffb
    800063c2:	da0080e7          	jalr	-608(ra) # 8000115e <kvmpa>
    800063c6:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800063ca:	000a3783          	ld	a5,0(s4)
    800063ce:	97a6                	add	a5,a5,s1
    800063d0:	4741                	li	a4,16
    800063d2:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063d4:	000a3783          	ld	a5,0(s4)
    800063d8:	97a6                	add	a5,a5,s1
    800063da:	4705                	li	a4,1
    800063dc:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800063e0:	fa442703          	lw	a4,-92(s0)
    800063e4:	000a3783          	ld	a5,0(s4)
    800063e8:	97a6                	add	a5,a5,s1
    800063ea:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063ee:	0712                	slli	a4,a4,0x4
    800063f0:	000a3783          	ld	a5,0(s4)
    800063f4:	97ba                	add	a5,a5,a4
    800063f6:	05890693          	addi	a3,s2,88
    800063fa:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800063fc:	000a3783          	ld	a5,0(s4)
    80006400:	97ba                	add	a5,a5,a4
    80006402:	40000693          	li	a3,1024
    80006406:	c794                	sw	a3,8(a5)
  if(write)
    80006408:	100c0863          	beqz	s8,80006518 <virtio_disk_rw+0x26a>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000640c:	000a3783          	ld	a5,0(s4)
    80006410:	97ba                	add	a5,a5,a4
    80006412:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006416:	0001d517          	auipc	a0,0x1d
    8000641a:	bea50513          	addi	a0,a0,-1046 # 80023000 <disk>
    8000641e:	0001f797          	auipc	a5,0x1f
    80006422:	be278793          	addi	a5,a5,-1054 # 80025000 <disk+0x2000>
    80006426:	6394                	ld	a3,0(a5)
    80006428:	96ba                	add	a3,a3,a4
    8000642a:	00c6d603          	lhu	a2,12(a3)
    8000642e:	00166613          	ori	a2,a2,1
    80006432:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006436:	fa842683          	lw	a3,-88(s0)
    8000643a:	6390                	ld	a2,0(a5)
    8000643c:	9732                	add	a4,a4,a2
    8000643e:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006442:	20098613          	addi	a2,s3,512
    80006446:	0612                	slli	a2,a2,0x4
    80006448:	962a                	add	a2,a2,a0
    8000644a:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000644e:	00469713          	slli	a4,a3,0x4
    80006452:	6394                	ld	a3,0(a5)
    80006454:	96ba                	add	a3,a3,a4
    80006456:	6589                	lui	a1,0x2
    80006458:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    8000645c:	94ae                	add	s1,s1,a1
    8000645e:	94aa                	add	s1,s1,a0
    80006460:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006462:	6394                	ld	a3,0(a5)
    80006464:	96ba                	add	a3,a3,a4
    80006466:	4585                	li	a1,1
    80006468:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000646a:	6394                	ld	a3,0(a5)
    8000646c:	96ba                	add	a3,a3,a4
    8000646e:	4509                	li	a0,2
    80006470:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    80006474:	6394                	ld	a3,0(a5)
    80006476:	9736                	add	a4,a4,a3
    80006478:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000647c:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006480:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    80006484:	6794                	ld	a3,8(a5)
    80006486:	0026d703          	lhu	a4,2(a3)
    8000648a:	8b1d                	andi	a4,a4,7
    8000648c:	2709                	addiw	a4,a4,2
    8000648e:	0706                	slli	a4,a4,0x1
    80006490:	9736                	add	a4,a4,a3
    80006492:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    80006496:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    8000649a:	6798                	ld	a4,8(a5)
    8000649c:	00275783          	lhu	a5,2(a4)
    800064a0:	2785                	addiw	a5,a5,1
    800064a2:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064a6:	100017b7          	lui	a5,0x10001
    800064aa:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800064ae:	00492703          	lw	a4,4(s2)
    800064b2:	4785                	li	a5,1
    800064b4:	02f71163          	bne	a4,a5,800064d6 <virtio_disk_rw+0x228>
    sleep(b, &disk.vdisk_lock);
    800064b8:	0001f997          	auipc	s3,0x1f
    800064bc:	bf098993          	addi	s3,s3,-1040 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800064c0:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800064c2:	85ce                	mv	a1,s3
    800064c4:	854a                	mv	a0,s2
    800064c6:	ffffc097          	auipc	ra,0xffffc
    800064ca:	0a4080e7          	jalr	164(ra) # 8000256a <sleep>
  while(b->disk == 1) {
    800064ce:	00492783          	lw	a5,4(s2)
    800064d2:	fe9788e3          	beq	a5,s1,800064c2 <virtio_disk_rw+0x214>
  }

  disk.info[idx[0]].b = 0;
    800064d6:	fa042483          	lw	s1,-96(s0)
    800064da:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800064de:	00479713          	slli	a4,a5,0x4
    800064e2:	0001d797          	auipc	a5,0x1d
    800064e6:	b1e78793          	addi	a5,a5,-1250 # 80023000 <disk>
    800064ea:	97ba                	add	a5,a5,a4
    800064ec:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800064f0:	0001f917          	auipc	s2,0x1f
    800064f4:	b1090913          	addi	s2,s2,-1264 # 80025000 <disk+0x2000>
    free_desc(i);
    800064f8:	8526                	mv	a0,s1
    800064fa:	00000097          	auipc	ra,0x0
    800064fe:	bec080e7          	jalr	-1044(ra) # 800060e6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006502:	0492                	slli	s1,s1,0x4
    80006504:	00093783          	ld	a5,0(s2)
    80006508:	94be                	add	s1,s1,a5
    8000650a:	00c4d783          	lhu	a5,12(s1)
    8000650e:	8b85                	andi	a5,a5,1
    80006510:	cf91                	beqz	a5,8000652c <virtio_disk_rw+0x27e>
      i = disk.desc[i].next;
    80006512:	00e4d483          	lhu	s1,14(s1)
  while(1){
    80006516:	b7cd                	j	800064f8 <virtio_disk_rw+0x24a>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006518:	0001f797          	auipc	a5,0x1f
    8000651c:	ae878793          	addi	a5,a5,-1304 # 80025000 <disk+0x2000>
    80006520:	639c                	ld	a5,0(a5)
    80006522:	97ba                	add	a5,a5,a4
    80006524:	4689                	li	a3,2
    80006526:	00d79623          	sh	a3,12(a5)
    8000652a:	b5f5                	j	80006416 <virtio_disk_rw+0x168>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000652c:	0001f517          	auipc	a0,0x1f
    80006530:	b7c50513          	addi	a0,a0,-1156 # 800250a8 <disk+0x20a8>
    80006534:	ffffa097          	auipc	ra,0xffffa
    80006538:	7e2080e7          	jalr	2018(ra) # 80000d16 <release>
}
    8000653c:	70a6                	ld	ra,104(sp)
    8000653e:	7406                	ld	s0,96(sp)
    80006540:	64e6                	ld	s1,88(sp)
    80006542:	6946                	ld	s2,80(sp)
    80006544:	69a6                	ld	s3,72(sp)
    80006546:	6a06                	ld	s4,64(sp)
    80006548:	7ae2                	ld	s5,56(sp)
    8000654a:	7b42                	ld	s6,48(sp)
    8000654c:	7ba2                	ld	s7,40(sp)
    8000654e:	7c02                	ld	s8,32(sp)
    80006550:	6165                	addi	sp,sp,112
    80006552:	8082                	ret
  if(write)
    80006554:	e40c11e3          	bnez	s8,80006396 <virtio_disk_rw+0xe8>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006558:	f8042823          	sw	zero,-112(s0)
    8000655c:	b581                	j	8000639c <virtio_disk_rw+0xee>
      disk.free[i] = 0;
    8000655e:	00098c23          	sb	zero,24(s3)
    idx[i] = alloc_desc();
    80006562:	00072023          	sw	zero,0(a4)
    if(idx[i] < 0){
    80006566:	b365                	j	8000630e <virtio_disk_rw+0x60>

0000000080006568 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006568:	1101                	addi	sp,sp,-32
    8000656a:	ec06                	sd	ra,24(sp)
    8000656c:	e822                	sd	s0,16(sp)
    8000656e:	e426                	sd	s1,8(sp)
    80006570:	e04a                	sd	s2,0(sp)
    80006572:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006574:	0001f517          	auipc	a0,0x1f
    80006578:	b3450513          	addi	a0,a0,-1228 # 800250a8 <disk+0x20a8>
    8000657c:	ffffa097          	auipc	ra,0xffffa
    80006580:	6e6080e7          	jalr	1766(ra) # 80000c62 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006584:	0001f797          	auipc	a5,0x1f
    80006588:	a7c78793          	addi	a5,a5,-1412 # 80025000 <disk+0x2000>
    8000658c:	0207d683          	lhu	a3,32(a5)
    80006590:	6b98                	ld	a4,16(a5)
    80006592:	00275783          	lhu	a5,2(a4)
    80006596:	8fb5                	xor	a5,a5,a3
    80006598:	8b9d                	andi	a5,a5,7
    8000659a:	c7c9                	beqz	a5,80006624 <virtio_disk_intr+0xbc>
    int id = disk.used->elems[disk.used_idx].id;
    8000659c:	068e                	slli	a3,a3,0x3
    8000659e:	9736                	add	a4,a4,a3
    800065a0:	435c                	lw	a5,4(a4)

    if(disk.info[id].status != 0)
    800065a2:	20078713          	addi	a4,a5,512
    800065a6:	00471693          	slli	a3,a4,0x4
    800065aa:	0001d717          	auipc	a4,0x1d
    800065ae:	a5670713          	addi	a4,a4,-1450 # 80023000 <disk>
    800065b2:	9736                	add	a4,a4,a3
    800065b4:	03074703          	lbu	a4,48(a4)
    800065b8:	ef31                	bnez	a4,80006614 <virtio_disk_intr+0xac>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    800065ba:	0001d917          	auipc	s2,0x1d
    800065be:	a4690913          	addi	s2,s2,-1466 # 80023000 <disk>
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800065c2:	0001f497          	auipc	s1,0x1f
    800065c6:	a3e48493          	addi	s1,s1,-1474 # 80025000 <disk+0x2000>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800065ca:	20078793          	addi	a5,a5,512
    800065ce:	0792                	slli	a5,a5,0x4
    800065d0:	97ca                	add	a5,a5,s2
    800065d2:	7798                	ld	a4,40(a5)
    800065d4:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800065d8:	7788                	ld	a0,40(a5)
    800065da:	ffffc097          	auipc	ra,0xffffc
    800065de:	116080e7          	jalr	278(ra) # 800026f0 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800065e2:	0204d783          	lhu	a5,32(s1)
    800065e6:	2785                	addiw	a5,a5,1
    800065e8:	8b9d                	andi	a5,a5,7
    800065ea:	03079613          	slli	a2,a5,0x30
    800065ee:	9241                	srli	a2,a2,0x30
    800065f0:	02c49023          	sh	a2,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800065f4:	6898                	ld	a4,16(s1)
    800065f6:	00275683          	lhu	a3,2(a4)
    800065fa:	8a9d                	andi	a3,a3,7
    800065fc:	02c68463          	beq	a3,a2,80006624 <virtio_disk_intr+0xbc>
    int id = disk.used->elems[disk.used_idx].id;
    80006600:	078e                	slli	a5,a5,0x3
    80006602:	97ba                	add	a5,a5,a4
    80006604:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006606:	20078713          	addi	a4,a5,512
    8000660a:	0712                	slli	a4,a4,0x4
    8000660c:	974a                	add	a4,a4,s2
    8000660e:	03074703          	lbu	a4,48(a4)
    80006612:	df45                	beqz	a4,800065ca <virtio_disk_intr+0x62>
      panic("virtio_disk_intr status");
    80006614:	00002517          	auipc	a0,0x2
    80006618:	2e450513          	addi	a0,a0,740 # 800088f8 <syscalls+0x3f0>
    8000661c:	ffffa097          	auipc	ra,0xffffa
    80006620:	f58080e7          	jalr	-168(ra) # 80000574 <panic>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006624:	10001737          	lui	a4,0x10001
    80006628:	533c                	lw	a5,96(a4)
    8000662a:	8b8d                	andi	a5,a5,3
    8000662c:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    8000662e:	0001f517          	auipc	a0,0x1f
    80006632:	a7a50513          	addi	a0,a0,-1414 # 800250a8 <disk+0x20a8>
    80006636:	ffffa097          	auipc	ra,0xffffa
    8000663a:	6e0080e7          	jalr	1760(ra) # 80000d16 <release>
}
    8000663e:	60e2                	ld	ra,24(sp)
    80006640:	6442                	ld	s0,16(sp)
    80006642:	64a2                	ld	s1,8(sp)
    80006644:	6902                	ld	s2,0(sp)
    80006646:	6105                	addi	sp,sp,32
    80006648:	8082                	ret

000000008000664a <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    8000664a:	7179                	addi	sp,sp,-48
    8000664c:	f406                	sd	ra,40(sp)
    8000664e:	f022                	sd	s0,32(sp)
    80006650:	ec26                	sd	s1,24(sp)
    80006652:	e84a                	sd	s2,16(sp)
    80006654:	e44e                	sd	s3,8(sp)
    80006656:	e052                	sd	s4,0(sp)
    80006658:	1800                	addi	s0,sp,48
    8000665a:	89aa                	mv	s3,a0
    8000665c:	8a2e                	mv	s4,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    8000665e:	00003917          	auipc	s2,0x3
    80006662:	9ca90913          	addi	s2,s2,-1590 # 80009028 <stats>
    80006666:	00092683          	lw	a3,0(s2)
    8000666a:	00002617          	auipc	a2,0x2
    8000666e:	2a660613          	addi	a2,a2,678 # 80008910 <syscalls+0x408>
    80006672:	00000097          	auipc	ra,0x0
    80006676:	2e2080e7          	jalr	738(ra) # 80006954 <snprintf>
    8000667a:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    8000667c:	00492683          	lw	a3,4(s2)
    80006680:	00002617          	auipc	a2,0x2
    80006684:	2a060613          	addi	a2,a2,672 # 80008920 <syscalls+0x418>
    80006688:	85d2                	mv	a1,s4
    8000668a:	954e                	add	a0,a0,s3
    8000668c:	00000097          	auipc	ra,0x0
    80006690:	2c8080e7          	jalr	712(ra) # 80006954 <snprintf>
  return n;
}
    80006694:	9d25                	addw	a0,a0,s1
    80006696:	70a2                	ld	ra,40(sp)
    80006698:	7402                	ld	s0,32(sp)
    8000669a:	64e2                	ld	s1,24(sp)
    8000669c:	6942                	ld	s2,16(sp)
    8000669e:	69a2                	ld	s3,8(sp)
    800066a0:	6a02                	ld	s4,0(sp)
    800066a2:	6145                	addi	sp,sp,48
    800066a4:	8082                	ret

00000000800066a6 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800066a6:	7179                	addi	sp,sp,-48
    800066a8:	f406                	sd	ra,40(sp)
    800066aa:	f022                	sd	s0,32(sp)
    800066ac:	ec26                	sd	s1,24(sp)
    800066ae:	e84a                	sd	s2,16(sp)
    800066b0:	e44e                	sd	s3,8(sp)
    800066b2:	1800                	addi	s0,sp,48
    800066b4:	89ae                	mv	s3,a1
    800066b6:	84b2                	mv	s1,a2
    800066b8:	8936                	mv	s2,a3
  struct proc *p = myproc();
    800066ba:	ffffb097          	auipc	ra,0xffffb
    800066be:	49e080e7          	jalr	1182(ra) # 80001b58 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    800066c2:	653c                	ld	a5,72(a0)
    800066c4:	02f4ff63          	bleu	a5,s1,80006702 <copyin_new+0x5c>
    800066c8:	01248733          	add	a4,s1,s2
    800066cc:	02f77d63          	bleu	a5,a4,80006706 <copyin_new+0x60>
    800066d0:	02976d63          	bltu	a4,s1,8000670a <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    800066d4:	0009061b          	sext.w	a2,s2
    800066d8:	85a6                	mv	a1,s1
    800066da:	854e                	mv	a0,s3
    800066dc:	ffffa097          	auipc	ra,0xffffa
    800066e0:	6ee080e7          	jalr	1774(ra) # 80000dca <memmove>
  stats.ncopyin++;   // XXX lock
    800066e4:	00003717          	auipc	a4,0x3
    800066e8:	94470713          	addi	a4,a4,-1724 # 80009028 <stats>
    800066ec:	431c                	lw	a5,0(a4)
    800066ee:	2785                	addiw	a5,a5,1
    800066f0:	c31c                	sw	a5,0(a4)
  return 0;
    800066f2:	4501                	li	a0,0
}
    800066f4:	70a2                	ld	ra,40(sp)
    800066f6:	7402                	ld	s0,32(sp)
    800066f8:	64e2                	ld	s1,24(sp)
    800066fa:	6942                	ld	s2,16(sp)
    800066fc:	69a2                	ld	s3,8(sp)
    800066fe:	6145                	addi	sp,sp,48
    80006700:	8082                	ret
    return -1;
    80006702:	557d                	li	a0,-1
    80006704:	bfc5                	j	800066f4 <copyin_new+0x4e>
    80006706:	557d                	li	a0,-1
    80006708:	b7f5                	j	800066f4 <copyin_new+0x4e>
    8000670a:	557d                	li	a0,-1
    8000670c:	b7e5                	j	800066f4 <copyin_new+0x4e>

000000008000670e <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    8000670e:	7179                	addi	sp,sp,-48
    80006710:	f406                	sd	ra,40(sp)
    80006712:	f022                	sd	s0,32(sp)
    80006714:	ec26                	sd	s1,24(sp)
    80006716:	e84a                	sd	s2,16(sp)
    80006718:	e44e                	sd	s3,8(sp)
    8000671a:	1800                	addi	s0,sp,48
    8000671c:	89ae                	mv	s3,a1
    8000671e:	84b2                	mv	s1,a2
    80006720:	8936                	mv	s2,a3
  struct proc *p = myproc();
    80006722:	ffffb097          	auipc	ra,0xffffb
    80006726:	436080e7          	jalr	1078(ra) # 80001b58 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    8000672a:	00003717          	auipc	a4,0x3
    8000672e:	8fe70713          	addi	a4,a4,-1794 # 80009028 <stats>
    80006732:	435c                	lw	a5,4(a4)
    80006734:	2785                	addiw	a5,a5,1
    80006736:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006738:	04090063          	beqz	s2,80006778 <copyinstr_new+0x6a>
    8000673c:	653c                	ld	a5,72(a0)
    8000673e:	02f4ff63          	bleu	a5,s1,8000677c <copyinstr_new+0x6e>
    dst[i] = s[i];
    80006742:	0004c783          	lbu	a5,0(s1)
    80006746:	00f98023          	sb	a5,0(s3)
    if(s[i] == '\0')
    8000674a:	cb9d                	beqz	a5,80006780 <copyinstr_new+0x72>
    8000674c:	00148793          	addi	a5,s1,1
    80006750:	012486b3          	add	a3,s1,s2
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006754:	02d78863          	beq	a5,a3,80006784 <copyinstr_new+0x76>
    80006758:	6538                	ld	a4,72(a0)
    8000675a:	00e7fd63          	bleu	a4,a5,80006774 <copyinstr_new+0x66>
    dst[i] = s[i];
    8000675e:	0007c603          	lbu	a2,0(a5)
    80006762:	40978733          	sub	a4,a5,s1
    80006766:	974e                	add	a4,a4,s3
    80006768:	00c70023          	sb	a2,0(a4)
    if(s[i] == '\0')
    8000676c:	0785                	addi	a5,a5,1
    8000676e:	f27d                	bnez	a2,80006754 <copyinstr_new+0x46>
      return 0;
    80006770:	4501                	li	a0,0
    80006772:	a811                	j	80006786 <copyinstr_new+0x78>
  }
  return -1;
    80006774:	557d                	li	a0,-1
    80006776:	a801                	j	80006786 <copyinstr_new+0x78>
    80006778:	557d                	li	a0,-1
    8000677a:	a031                	j	80006786 <copyinstr_new+0x78>
    8000677c:	557d                	li	a0,-1
    8000677e:	a021                	j	80006786 <copyinstr_new+0x78>
      return 0;
    80006780:	4501                	li	a0,0
    80006782:	a011                	j	80006786 <copyinstr_new+0x78>
  return -1;
    80006784:	557d                	li	a0,-1
}
    80006786:	70a2                	ld	ra,40(sp)
    80006788:	7402                	ld	s0,32(sp)
    8000678a:	64e2                	ld	s1,24(sp)
    8000678c:	6942                	ld	s2,16(sp)
    8000678e:	69a2                	ld	s3,8(sp)
    80006790:	6145                	addi	sp,sp,48
    80006792:	8082                	ret

0000000080006794 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006794:	1141                	addi	sp,sp,-16
    80006796:	e422                	sd	s0,8(sp)
    80006798:	0800                	addi	s0,sp,16
  return -1;
}
    8000679a:	557d                	li	a0,-1
    8000679c:	6422                	ld	s0,8(sp)
    8000679e:	0141                	addi	sp,sp,16
    800067a0:	8082                	ret

00000000800067a2 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800067a2:	7179                	addi	sp,sp,-48
    800067a4:	f406                	sd	ra,40(sp)
    800067a6:	f022                	sd	s0,32(sp)
    800067a8:	ec26                	sd	s1,24(sp)
    800067aa:	e84a                	sd	s2,16(sp)
    800067ac:	e44e                	sd	s3,8(sp)
    800067ae:	e052                	sd	s4,0(sp)
    800067b0:	1800                	addi	s0,sp,48
    800067b2:	89aa                	mv	s3,a0
    800067b4:	8a2e                	mv	s4,a1
    800067b6:	8932                	mv	s2,a2
  int m;

  acquire(&stats.lock);
    800067b8:	00020517          	auipc	a0,0x20
    800067bc:	84850513          	addi	a0,a0,-1976 # 80026000 <stats>
    800067c0:	ffffa097          	auipc	ra,0xffffa
    800067c4:	4a2080e7          	jalr	1186(ra) # 80000c62 <acquire>

  if(stats.sz == 0) {
    800067c8:	00021797          	auipc	a5,0x21
    800067cc:	83878793          	addi	a5,a5,-1992 # 80027000 <stats+0x1000>
    800067d0:	4f9c                	lw	a5,24(a5)
    800067d2:	cbad                	beqz	a5,80006844 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800067d4:	00021797          	auipc	a5,0x21
    800067d8:	82c78793          	addi	a5,a5,-2004 # 80027000 <stats+0x1000>
    800067dc:	4fd8                	lw	a4,28(a5)
    800067de:	4f9c                	lw	a5,24(a5)
    800067e0:	9f99                	subw	a5,a5,a4
    800067e2:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800067e6:	06d05d63          	blez	a3,80006860 <statsread+0xbe>
    if(m > n)
    800067ea:	84be                	mv	s1,a5
    800067ec:	00d95363          	ble	a3,s2,800067f2 <statsread+0x50>
    800067f0:	84ca                	mv	s1,s2
    800067f2:	0004891b          	sext.w	s2,s1
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800067f6:	86ca                	mv	a3,s2
    800067f8:	00020617          	auipc	a2,0x20
    800067fc:	82060613          	addi	a2,a2,-2016 # 80026018 <stats+0x18>
    80006800:	963a                	add	a2,a2,a4
    80006802:	85d2                	mv	a1,s4
    80006804:	854e                	mv	a0,s3
    80006806:	ffffc097          	auipc	ra,0xffffc
    8000680a:	fc6080e7          	jalr	-58(ra) # 800027cc <either_copyout>
    8000680e:	57fd                	li	a5,-1
    80006810:	00f50963          	beq	a0,a5,80006822 <statsread+0x80>
      stats.off += m;
    80006814:	00020717          	auipc	a4,0x20
    80006818:	7ec70713          	addi	a4,a4,2028 # 80027000 <stats+0x1000>
    8000681c:	4f5c                	lw	a5,28(a4)
    8000681e:	9cbd                	addw	s1,s1,a5
    80006820:	cf44                	sw	s1,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006822:	0001f517          	auipc	a0,0x1f
    80006826:	7de50513          	addi	a0,a0,2014 # 80026000 <stats>
    8000682a:	ffffa097          	auipc	ra,0xffffa
    8000682e:	4ec080e7          	jalr	1260(ra) # 80000d16 <release>
  return m;
}
    80006832:	854a                	mv	a0,s2
    80006834:	70a2                	ld	ra,40(sp)
    80006836:	7402                	ld	s0,32(sp)
    80006838:	64e2                	ld	s1,24(sp)
    8000683a:	6942                	ld	s2,16(sp)
    8000683c:	69a2                	ld	s3,8(sp)
    8000683e:	6a02                	ld	s4,0(sp)
    80006840:	6145                	addi	sp,sp,48
    80006842:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006844:	6585                	lui	a1,0x1
    80006846:	0001f517          	auipc	a0,0x1f
    8000684a:	7d250513          	addi	a0,a0,2002 # 80026018 <stats+0x18>
    8000684e:	00000097          	auipc	ra,0x0
    80006852:	dfc080e7          	jalr	-516(ra) # 8000664a <statscopyin>
    80006856:	00020797          	auipc	a5,0x20
    8000685a:	7ca7a123          	sw	a0,1986(a5) # 80027018 <stats+0x1018>
    8000685e:	bf9d                	j	800067d4 <statsread+0x32>
    stats.sz = 0;
    80006860:	00020797          	auipc	a5,0x20
    80006864:	7a078793          	addi	a5,a5,1952 # 80027000 <stats+0x1000>
    80006868:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    8000686c:	0007ae23          	sw	zero,28(a5)
    m = -1;
    80006870:	597d                	li	s2,-1
    80006872:	bf45                	j	80006822 <statsread+0x80>

0000000080006874 <statsinit>:

void
statsinit(void)
{
    80006874:	1141                	addi	sp,sp,-16
    80006876:	e406                	sd	ra,8(sp)
    80006878:	e022                	sd	s0,0(sp)
    8000687a:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000687c:	00002597          	auipc	a1,0x2
    80006880:	0b458593          	addi	a1,a1,180 # 80008930 <syscalls+0x428>
    80006884:	0001f517          	auipc	a0,0x1f
    80006888:	77c50513          	addi	a0,a0,1916 # 80026000 <stats>
    8000688c:	ffffa097          	auipc	ra,0xffffa
    80006890:	346080e7          	jalr	838(ra) # 80000bd2 <initlock>

  devsw[STATS].read = statsread;
    80006894:	0001b797          	auipc	a5,0x1b
    80006898:	31c78793          	addi	a5,a5,796 # 80021bb0 <devsw>
    8000689c:	00000717          	auipc	a4,0x0
    800068a0:	f0670713          	addi	a4,a4,-250 # 800067a2 <statsread>
    800068a4:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800068a6:	00000717          	auipc	a4,0x0
    800068aa:	eee70713          	addi	a4,a4,-274 # 80006794 <statswrite>
    800068ae:	f798                	sd	a4,40(a5)
}
    800068b0:	60a2                	ld	ra,8(sp)
    800068b2:	6402                	ld	s0,0(sp)
    800068b4:	0141                	addi	sp,sp,16
    800068b6:	8082                	ret

00000000800068b8 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800068b8:	1101                	addi	sp,sp,-32
    800068ba:	ec22                	sd	s0,24(sp)
    800068bc:	1000                	addi	s0,sp,32
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800068be:	c299                	beqz	a3,800068c4 <sprintint+0xc>
    800068c0:	0005cd63          	bltz	a1,800068da <sprintint+0x22>
    x = -xx;
  else
    x = xx;
    800068c4:	2581                	sext.w	a1,a1
    800068c6:	4301                	li	t1,0

  i = 0;
    800068c8:	fe040713          	addi	a4,s0,-32
    800068cc:	4801                	li	a6,0
  do {
    buf[i++] = digits[x % base];
    800068ce:	2601                	sext.w	a2,a2
    800068d0:	00002897          	auipc	a7,0x2
    800068d4:	06888893          	addi	a7,a7,104 # 80008938 <digits>
    800068d8:	a801                	j	800068e8 <sprintint+0x30>
    x = -xx;
    800068da:	40b005bb          	negw	a1,a1
    800068de:	2581                	sext.w	a1,a1
  if(sign && (sign = xx < 0))
    800068e0:	4305                	li	t1,1
    x = -xx;
    800068e2:	b7dd                	j	800068c8 <sprintint+0x10>
  } while((x /= base) != 0);
    800068e4:	85be                	mv	a1,a5
    buf[i++] = digits[x % base];
    800068e6:	8836                	mv	a6,a3
    800068e8:	0018069b          	addiw	a3,a6,1
    800068ec:	02c5f7bb          	remuw	a5,a1,a2
    800068f0:	1782                	slli	a5,a5,0x20
    800068f2:	9381                	srli	a5,a5,0x20
    800068f4:	97c6                	add	a5,a5,a7
    800068f6:	0007c783          	lbu	a5,0(a5)
    800068fa:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800068fe:	0705                	addi	a4,a4,1
    80006900:	02c5d7bb          	divuw	a5,a1,a2
    80006904:	fec5f0e3          	bleu	a2,a1,800068e4 <sprintint+0x2c>

  if(sign)
    80006908:	00030b63          	beqz	t1,8000691e <sprintint+0x66>
    buf[i++] = '-';
    8000690c:	ff040793          	addi	a5,s0,-16
    80006910:	96be                	add	a3,a3,a5
    80006912:	02d00793          	li	a5,45
    80006916:	fef68823          	sb	a5,-16(a3)
    8000691a:	0028069b          	addiw	a3,a6,2

  n = 0;
  while(--i >= 0)
    8000691e:	02d05963          	blez	a3,80006950 <sprintint+0x98>
    80006922:	fe040793          	addi	a5,s0,-32
    80006926:	00d78733          	add	a4,a5,a3
    8000692a:	87aa                	mv	a5,a0
    8000692c:	0505                	addi	a0,a0,1
    8000692e:	fff6861b          	addiw	a2,a3,-1
    80006932:	1602                	slli	a2,a2,0x20
    80006934:	9201                	srli	a2,a2,0x20
    80006936:	9532                	add	a0,a0,a2
  *s = c;
    80006938:	fff74603          	lbu	a2,-1(a4)
    8000693c:	00c78023          	sb	a2,0(a5)
  while(--i >= 0)
    80006940:	177d                	addi	a4,a4,-1
    80006942:	0785                	addi	a5,a5,1
    80006944:	fea79ae3          	bne	a5,a0,80006938 <sprintint+0x80>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006948:	8536                	mv	a0,a3
    8000694a:	6462                	ld	s0,24(sp)
    8000694c:	6105                	addi	sp,sp,32
    8000694e:	8082                	ret
  while(--i >= 0)
    80006950:	4681                	li	a3,0
    80006952:	bfdd                	j	80006948 <sprintint+0x90>

0000000080006954 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006954:	7171                	addi	sp,sp,-176
    80006956:	fc86                	sd	ra,120(sp)
    80006958:	f8a2                	sd	s0,112(sp)
    8000695a:	f4a6                	sd	s1,104(sp)
    8000695c:	f0ca                	sd	s2,96(sp)
    8000695e:	ecce                	sd	s3,88(sp)
    80006960:	e8d2                	sd	s4,80(sp)
    80006962:	e4d6                	sd	s5,72(sp)
    80006964:	e0da                	sd	s6,64(sp)
    80006966:	fc5e                	sd	s7,56(sp)
    80006968:	f862                	sd	s8,48(sp)
    8000696a:	f466                	sd	s9,40(sp)
    8000696c:	f06a                	sd	s10,32(sp)
    8000696e:	ec6e                	sd	s11,24(sp)
    80006970:	0100                	addi	s0,sp,128
    80006972:	e414                	sd	a3,8(s0)
    80006974:	e818                	sd	a4,16(s0)
    80006976:	ec1c                	sd	a5,24(s0)
    80006978:	03043023          	sd	a6,32(s0)
    8000697c:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    80006980:	ce1d                	beqz	a2,800069be <snprintf+0x6a>
    80006982:	8baa                	mv	s7,a0
    80006984:	89ae                	mv	s3,a1
    80006986:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006988:	00840793          	addi	a5,s0,8
    8000698c:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006990:	14b05263          	blez	a1,80006ad4 <snprintf+0x180>
    80006994:	00064703          	lbu	a4,0(a2)
    80006998:	0007079b          	sext.w	a5,a4
    8000699c:	12078e63          	beqz	a5,80006ad8 <snprintf+0x184>
  int off = 0;
    800069a0:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800069a2:	4901                	li	s2,0
    if(c != '%'){
    800069a4:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800069a8:	06400b13          	li	s6,100
  *s = c;
    800069ac:	02500d13          	li	s10,37
    switch(c){
    800069b0:	07300c93          	li	s9,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800069b4:	02800d93          	li	s11,40
    switch(c){
    800069b8:	07800c13          	li	s8,120
    800069bc:	a805                	j	800069ec <snprintf+0x98>
    panic("null fmt");
    800069be:	00001517          	auipc	a0,0x1
    800069c2:	68250513          	addi	a0,a0,1666 # 80008040 <digits+0x28>
    800069c6:	ffffa097          	auipc	ra,0xffffa
    800069ca:	bae080e7          	jalr	-1106(ra) # 80000574 <panic>
  *s = c;
    800069ce:	009b87b3          	add	a5,s7,s1
    800069d2:	00e78023          	sb	a4,0(a5)
      off += sputc(buf+off, c);
    800069d6:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800069d8:	2905                	addiw	s2,s2,1
    800069da:	0b34dc63          	ble	s3,s1,80006a92 <snprintf+0x13e>
    800069de:	012a07b3          	add	a5,s4,s2
    800069e2:	0007c703          	lbu	a4,0(a5)
    800069e6:	0007079b          	sext.w	a5,a4
    800069ea:	c7c5                	beqz	a5,80006a92 <snprintf+0x13e>
    if(c != '%'){
    800069ec:	ff5791e3          	bne	a5,s5,800069ce <snprintf+0x7a>
    c = fmt[++i] & 0xff;
    800069f0:	2905                	addiw	s2,s2,1
    800069f2:	012a07b3          	add	a5,s4,s2
    800069f6:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800069fa:	cfc1                	beqz	a5,80006a92 <snprintf+0x13e>
    switch(c){
    800069fc:	05678163          	beq	a5,s6,80006a3e <snprintf+0xea>
    80006a00:	02fb7763          	bleu	a5,s6,80006a2e <snprintf+0xda>
    80006a04:	05978e63          	beq	a5,s9,80006a60 <snprintf+0x10c>
    80006a08:	0b879b63          	bne	a5,s8,80006abe <snprintf+0x16a>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006a0c:	f8843783          	ld	a5,-120(s0)
    80006a10:	00878713          	addi	a4,a5,8
    80006a14:	f8e43423          	sd	a4,-120(s0)
    80006a18:	4685                	li	a3,1
    80006a1a:	4641                	li	a2,16
    80006a1c:	438c                	lw	a1,0(a5)
    80006a1e:	009b8533          	add	a0,s7,s1
    80006a22:	00000097          	auipc	ra,0x0
    80006a26:	e96080e7          	jalr	-362(ra) # 800068b8 <sprintint>
    80006a2a:	9ca9                	addw	s1,s1,a0
      break;
    80006a2c:	b775                	j	800069d8 <snprintf+0x84>
    switch(c){
    80006a2e:	09579863          	bne	a5,s5,80006abe <snprintf+0x16a>
  *s = c;
    80006a32:	009b87b3          	add	a5,s7,s1
    80006a36:	01a78023          	sb	s10,0(a5)
        off += sputc(buf+off, *s);
      break;
    case '%':
      off += sputc(buf+off, '%');
    80006a3a:	2485                	addiw	s1,s1,1
      break;
    80006a3c:	bf71                	j	800069d8 <snprintf+0x84>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    80006a3e:	f8843783          	ld	a5,-120(s0)
    80006a42:	00878713          	addi	a4,a5,8
    80006a46:	f8e43423          	sd	a4,-120(s0)
    80006a4a:	4685                	li	a3,1
    80006a4c:	4629                	li	a2,10
    80006a4e:	438c                	lw	a1,0(a5)
    80006a50:	009b8533          	add	a0,s7,s1
    80006a54:	00000097          	auipc	ra,0x0
    80006a58:	e64080e7          	jalr	-412(ra) # 800068b8 <sprintint>
    80006a5c:	9ca9                	addw	s1,s1,a0
      break;
    80006a5e:	bfad                	j	800069d8 <snprintf+0x84>
      if((s = va_arg(ap, char*)) == 0)
    80006a60:	f8843783          	ld	a5,-120(s0)
    80006a64:	00878713          	addi	a4,a5,8
    80006a68:	f8e43423          	sd	a4,-120(s0)
    80006a6c:	639c                	ld	a5,0(a5)
    80006a6e:	c3b1                	beqz	a5,80006ab2 <snprintf+0x15e>
      for(; *s && off < sz; s++)
    80006a70:	0007c703          	lbu	a4,0(a5)
    80006a74:	d335                	beqz	a4,800069d8 <snprintf+0x84>
    80006a76:	0134de63          	ble	s3,s1,80006a92 <snprintf+0x13e>
    80006a7a:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006a7e:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006a82:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006a84:	0785                	addi	a5,a5,1
    80006a86:	0007c703          	lbu	a4,0(a5)
    80006a8a:	d739                	beqz	a4,800069d8 <snprintf+0x84>
    80006a8c:	0685                	addi	a3,a3,1
    80006a8e:	fe9998e3          	bne	s3,s1,80006a7e <snprintf+0x12a>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006a92:	8526                	mv	a0,s1
    80006a94:	70e6                	ld	ra,120(sp)
    80006a96:	7446                	ld	s0,112(sp)
    80006a98:	74a6                	ld	s1,104(sp)
    80006a9a:	7906                	ld	s2,96(sp)
    80006a9c:	69e6                	ld	s3,88(sp)
    80006a9e:	6a46                	ld	s4,80(sp)
    80006aa0:	6aa6                	ld	s5,72(sp)
    80006aa2:	6b06                	ld	s6,64(sp)
    80006aa4:	7be2                	ld	s7,56(sp)
    80006aa6:	7c42                	ld	s8,48(sp)
    80006aa8:	7ca2                	ld	s9,40(sp)
    80006aaa:	7d02                	ld	s10,32(sp)
    80006aac:	6de2                	ld	s11,24(sp)
    80006aae:	614d                	addi	sp,sp,176
    80006ab0:	8082                	ret
      for(; *s && off < sz; s++)
    80006ab2:	876e                	mv	a4,s11
        s = "(null)";
    80006ab4:	00001797          	auipc	a5,0x1
    80006ab8:	58478793          	addi	a5,a5,1412 # 80008038 <digits+0x20>
    80006abc:	bf6d                	j	80006a76 <snprintf+0x122>
  *s = c;
    80006abe:	009b8733          	add	a4,s7,s1
    80006ac2:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006ac6:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006aca:	975e                	add	a4,a4,s7
    80006acc:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006ad0:	2489                	addiw	s1,s1,2
      break;
    80006ad2:	b719                	j	800069d8 <snprintf+0x84>
  int off = 0;
    80006ad4:	4481                	li	s1,0
    80006ad6:	bf75                	j	80006a92 <snprintf+0x13e>
    80006ad8:	84be                	mv	s1,a5
    80006ada:	bf65                	j	80006a92 <snprintf+0x13e>
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
