
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	81013103          	ld	sp,-2032(sp) # 80008810 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

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
    80000022:	f1402773          	csrr	a4,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	2701                	sext.w	a4,a4

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000028:	0037161b          	slliw	a2,a4,0x3
    8000002c:	020047b7          	lui	a5,0x2004
    80000030:	963e                	add	a2,a2,a5
    80000032:	0200c7b7          	lui	a5,0x200c
    80000036:	ff87b783          	ld	a5,-8(a5) # 200bff8 <_entry-0x7dff4008>
    8000003a:	000f46b7          	lui	a3,0xf4
    8000003e:	24068693          	addi	a3,a3,576 # f4240 <_entry-0x7ff0bdc0>
    80000042:	97b6                	add	a5,a5,a3
    80000044:	e21c                	sd	a5,0(a2)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000046:	00271793          	slli	a5,a4,0x2
    8000004a:	97ba                	add	a5,a5,a4
    8000004c:	00379713          	slli	a4,a5,0x3
    80000050:	00009797          	auipc	a5,0x9
    80000054:	ff078793          	addi	a5,a5,-16 # 80009040 <timer_scratch>
    80000058:	97ba                	add	a5,a5,a4
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef90                	sd	a2,24(a5)
  scratch[4] = interval;
    8000005c:	f394                	sd	a3,32(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	21e78793          	addi	a5,a5,542 # 80006280 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcc7ff>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e4878793          	addi	a5,a5,-440 # 80000ef4 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  timerinit();
    800000d6:	00000097          	auipc	ra,0x0
    800000da:	f46080e7          	jalr	-186(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000de:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e6:	30200073          	mret
}
    800000ea:	60a2                	ld	ra,8(sp)
    800000ec:	6402                	ld	s0,0(sp)
    800000ee:	0141                	addi	sp,sp,16
    800000f0:	8082                	ret

00000000800000f2 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f2:	715d                	addi	sp,sp,-80
    800000f4:	e486                	sd	ra,72(sp)
    800000f6:	e0a2                	sd	s0,64(sp)
    800000f8:	fc26                	sd	s1,56(sp)
    800000fa:	f84a                	sd	s2,48(sp)
    800000fc:	f44e                	sd	s3,40(sp)
    800000fe:	f052                	sd	s4,32(sp)
    80000100:	ec56                	sd	s5,24(sp)
    80000102:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000104:	04c05663          	blez	a2,80000150 <consolewrite+0x5e>
    80000108:	8a2a                	mv	s4,a0
    8000010a:	892e                	mv	s2,a1
    8000010c:	89b2                	mv	s3,a2
    8000010e:	4481                	li	s1,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000110:	5afd                	li	s5,-1
    80000112:	4685                	li	a3,1
    80000114:	864a                	mv	a2,s2
    80000116:	85d2                	mv	a1,s4
    80000118:	fbf40513          	addi	a0,s0,-65
    8000011c:	00002097          	auipc	ra,0x2
    80000120:	45c080e7          	jalr	1116(ra) # 80002578 <either_copyin>
    80000124:	01550c63          	beq	a0,s5,8000013c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000128:	fbf44503          	lbu	a0,-65(s0)
    8000012c:	00000097          	auipc	ra,0x0
    80000130:	7d2080e7          	jalr	2002(ra) # 800008fe <uartputc>
  for(i = 0; i < n; i++){
    80000134:	2485                	addiw	s1,s1,1
    80000136:	0905                	addi	s2,s2,1
    80000138:	fc999de3          	bne	s3,s1,80000112 <consolewrite+0x20>
  }

  return i;
}
    8000013c:	8526                	mv	a0,s1
    8000013e:	60a6                	ld	ra,72(sp)
    80000140:	6406                	ld	s0,64(sp)
    80000142:	74e2                	ld	s1,56(sp)
    80000144:	7942                	ld	s2,48(sp)
    80000146:	79a2                	ld	s3,40(sp)
    80000148:	7a02                	ld	s4,32(sp)
    8000014a:	6ae2                	ld	s5,24(sp)
    8000014c:	6161                	addi	sp,sp,80
    8000014e:	8082                	ret
  for(i = 0; i < n; i++){
    80000150:	4481                	li	s1,0
    80000152:	b7ed                	j	8000013c <consolewrite+0x4a>

0000000080000154 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000154:	7119                	addi	sp,sp,-128
    80000156:	fc86                	sd	ra,120(sp)
    80000158:	f8a2                	sd	s0,112(sp)
    8000015a:	f4a6                	sd	s1,104(sp)
    8000015c:	f0ca                	sd	s2,96(sp)
    8000015e:	ecce                	sd	s3,88(sp)
    80000160:	e8d2                	sd	s4,80(sp)
    80000162:	e4d6                	sd	s5,72(sp)
    80000164:	e0da                	sd	s6,64(sp)
    80000166:	fc5e                	sd	s7,56(sp)
    80000168:	f862                	sd	s8,48(sp)
    8000016a:	f466                	sd	s9,40(sp)
    8000016c:	f06a                	sd	s10,32(sp)
    8000016e:	ec6e                	sd	s11,24(sp)
    80000170:	0100                	addi	s0,sp,128
    80000172:	8caa                	mv	s9,a0
    80000174:	8aae                	mv	s5,a1
    80000176:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000178:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000017c:	00011517          	auipc	a0,0x11
    80000180:	00450513          	addi	a0,a0,4 # 80011180 <cons>
    80000184:	00001097          	auipc	ra,0x1
    80000188:	aa0080e7          	jalr	-1376(ra) # 80000c24 <acquire>
  while(n > 0){
    8000018c:	09405663          	blez	s4,80000218 <consoleread+0xc4>
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000190:	00011497          	auipc	s1,0x11
    80000194:	ff048493          	addi	s1,s1,-16 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000198:	89a6                	mv	s3,s1
    8000019a:	00011917          	auipc	s2,0x11
    8000019e:	07e90913          	addi	s2,s2,126 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a2:	4c11                	li	s8,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a4:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a6:	4da9                	li	s11,10
    while(cons.r == cons.w){
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71463          	bne	a4,a5,800001d8 <consoleread+0x84>
      if(myproc()->killed){
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	88a080e7          	jalr	-1910(ra) # 80001a3e <myproc>
    800001bc:	591c                	lw	a5,48(a0)
    800001be:	eba5                	bnez	a5,8000022e <consoleread+0xda>
      sleep(&cons.r, &cons.lock);
    800001c0:	85ce                	mv	a1,s3
    800001c2:	854a                	mv	a0,s2
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	0fc080e7          	jalr	252(ra) # 800022c0 <sleep>
    while(cons.r == cons.w){
    800001cc:	0984a783          	lw	a5,152(s1)
    800001d0:	09c4a703          	lw	a4,156(s1)
    800001d4:	fef700e3          	beq	a4,a5,800001b4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001d8:	0017871b          	addiw	a4,a5,1
    800001dc:	08e4ac23          	sw	a4,152(s1)
    800001e0:	07f7f713          	andi	a4,a5,127
    800001e4:	9726                	add	a4,a4,s1
    800001e6:	01874703          	lbu	a4,24(a4)
    800001ea:	00070b9b          	sext.w	s7,a4
    if(c == C('D')){  // end-of-file
    800001ee:	078b8863          	beq	s7,s8,8000025e <consoleread+0x10a>
    cbuf = c;
    800001f2:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f6:	4685                	li	a3,1
    800001f8:	f8f40613          	addi	a2,s0,-113
    800001fc:	85d6                	mv	a1,s5
    800001fe:	8566                	mv	a0,s9
    80000200:	00002097          	auipc	ra,0x2
    80000204:	322080e7          	jalr	802(ra) # 80002522 <either_copyout>
    80000208:	01a50863          	beq	a0,s10,80000218 <consoleread+0xc4>
    dst++;
    8000020c:	0a85                	addi	s5,s5,1
    --n;
    8000020e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000210:	01bb8463          	beq	s7,s11,80000218 <consoleread+0xc4>
  while(n > 0){
    80000214:	f80a1ae3          	bnez	s4,800001a8 <consoleread+0x54>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000218:	00011517          	auipc	a0,0x11
    8000021c:	f6850513          	addi	a0,a0,-152 # 80011180 <cons>
    80000220:	00001097          	auipc	ra,0x1
    80000224:	ab8080e7          	jalr	-1352(ra) # 80000cd8 <release>

  return target - n;
    80000228:	414b053b          	subw	a0,s6,s4
    8000022c:	a811                	j	80000240 <consoleread+0xec>
        release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	f5250513          	addi	a0,a0,-174 # 80011180 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	aa2080e7          	jalr	-1374(ra) # 80000cd8 <release>
        return -1;
    8000023e:	557d                	li	a0,-1
}
    80000240:	70e6                	ld	ra,120(sp)
    80000242:	7446                	ld	s0,112(sp)
    80000244:	74a6                	ld	s1,104(sp)
    80000246:	7906                	ld	s2,96(sp)
    80000248:	69e6                	ld	s3,88(sp)
    8000024a:	6a46                	ld	s4,80(sp)
    8000024c:	6aa6                	ld	s5,72(sp)
    8000024e:	6b06                	ld	s6,64(sp)
    80000250:	7be2                	ld	s7,56(sp)
    80000252:	7c42                	ld	s8,48(sp)
    80000254:	7ca2                	ld	s9,40(sp)
    80000256:	7d02                	ld	s10,32(sp)
    80000258:	6de2                	ld	s11,24(sp)
    8000025a:	6109                	addi	sp,sp,128
    8000025c:	8082                	ret
      if(n < target){
    8000025e:	000a071b          	sext.w	a4,s4
    80000262:	fb677be3          	bleu	s6,a4,80000218 <consoleread+0xc4>
        cons.r--;
    80000266:	00011717          	auipc	a4,0x11
    8000026a:	faf72923          	sw	a5,-78(a4) # 80011218 <cons+0x98>
    8000026e:	b76d                	j	80000218 <consoleread+0xc4>

0000000080000270 <consputc>:
{
    80000270:	1141                	addi	sp,sp,-16
    80000272:	e406                	sd	ra,8(sp)
    80000274:	e022                	sd	s0,0(sp)
    80000276:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000278:	10000793          	li	a5,256
    8000027c:	00f50a63          	beq	a0,a5,80000290 <consputc+0x20>
    uartputc_sync(c);
    80000280:	00000097          	auipc	ra,0x0
    80000284:	58a080e7          	jalr	1418(ra) # 8000080a <uartputc_sync>
}
    80000288:	60a2                	ld	ra,8(sp)
    8000028a:	6402                	ld	s0,0(sp)
    8000028c:	0141                	addi	sp,sp,16
    8000028e:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000290:	4521                	li	a0,8
    80000292:	00000097          	auipc	ra,0x0
    80000296:	578080e7          	jalr	1400(ra) # 8000080a <uartputc_sync>
    8000029a:	02000513          	li	a0,32
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	56c080e7          	jalr	1388(ra) # 8000080a <uartputc_sync>
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	562080e7          	jalr	1378(ra) # 8000080a <uartputc_sync>
    800002b0:	bfe1                	j	80000288 <consputc+0x18>

00000000800002b2 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b2:	1101                	addi	sp,sp,-32
    800002b4:	ec06                	sd	ra,24(sp)
    800002b6:	e822                	sd	s0,16(sp)
    800002b8:	e426                	sd	s1,8(sp)
    800002ba:	e04a                	sd	s2,0(sp)
    800002bc:	1000                	addi	s0,sp,32
    800002be:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002c0:	00011517          	auipc	a0,0x11
    800002c4:	ec050513          	addi	a0,a0,-320 # 80011180 <cons>
    800002c8:	00001097          	auipc	ra,0x1
    800002cc:	95c080e7          	jalr	-1700(ra) # 80000c24 <acquire>

  switch(c){
    800002d0:	47c1                	li	a5,16
    800002d2:	12f48463          	beq	s1,a5,800003fa <consoleintr+0x148>
    800002d6:	0297df63          	ble	s1,a5,80000314 <consoleintr+0x62>
    800002da:	47d5                	li	a5,21
    800002dc:	0af48863          	beq	s1,a5,8000038c <consoleintr+0xda>
    800002e0:	07f00793          	li	a5,127
    800002e4:	02f49b63          	bne	s1,a5,8000031a <consoleintr+0x68>
      consputc(BACKSPACE);
    }
    break;
  case C('H'): // Backspace
  case '\x7f':
    if(cons.e != cons.w){
    800002e8:	00011717          	auipc	a4,0x11
    800002ec:	e9870713          	addi	a4,a4,-360 # 80011180 <cons>
    800002f0:	0a072783          	lw	a5,160(a4)
    800002f4:	09c72703          	lw	a4,156(a4)
    800002f8:	10f70563          	beq	a4,a5,80000402 <consoleintr+0x150>
      cons.e--;
    800002fc:	37fd                	addiw	a5,a5,-1
    800002fe:	00011717          	auipc	a4,0x11
    80000302:	f2f72123          	sw	a5,-222(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    80000306:	10000513          	li	a0,256
    8000030a:	00000097          	auipc	ra,0x0
    8000030e:	f66080e7          	jalr	-154(ra) # 80000270 <consputc>
    80000312:	a8c5                	j	80000402 <consoleintr+0x150>
  switch(c){
    80000314:	47a1                	li	a5,8
    80000316:	fcf489e3          	beq	s1,a5,800002e8 <consoleintr+0x36>
    }
    break;
  default:
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031a:	c4e5                	beqz	s1,80000402 <consoleintr+0x150>
    8000031c:	00011717          	auipc	a4,0x11
    80000320:	e6470713          	addi	a4,a4,-412 # 80011180 <cons>
    80000324:	0a072783          	lw	a5,160(a4)
    80000328:	09872703          	lw	a4,152(a4)
    8000032c:	9f99                	subw	a5,a5,a4
    8000032e:	07f00713          	li	a4,127
    80000332:	0cf76863          	bltu	a4,a5,80000402 <consoleintr+0x150>
      c = (c == '\r') ? '\n' : c;
    80000336:	47b5                	li	a5,13
    80000338:	0ef48363          	beq	s1,a5,8000041e <consoleintr+0x16c>

      // echo back to the user.
      consputc(c);
    8000033c:	8526                	mv	a0,s1
    8000033e:	00000097          	auipc	ra,0x0
    80000342:	f32080e7          	jalr	-206(ra) # 80000270 <consputc>

      // store for consumption by consoleread().
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000346:	00011797          	auipc	a5,0x11
    8000034a:	e3a78793          	addi	a5,a5,-454 # 80011180 <cons>
    8000034e:	0a07a703          	lw	a4,160(a5)
    80000352:	0017069b          	addiw	a3,a4,1
    80000356:	0006861b          	sext.w	a2,a3
    8000035a:	0ad7a023          	sw	a3,160(a5)
    8000035e:	07f77713          	andi	a4,a4,127
    80000362:	97ba                	add	a5,a5,a4
    80000364:	00978c23          	sb	s1,24(a5)

      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000368:	47a9                	li	a5,10
    8000036a:	0ef48163          	beq	s1,a5,8000044c <consoleintr+0x19a>
    8000036e:	4791                	li	a5,4
    80000370:	0cf48e63          	beq	s1,a5,8000044c <consoleintr+0x19a>
    80000374:	00011797          	auipc	a5,0x11
    80000378:	e0c78793          	addi	a5,a5,-500 # 80011180 <cons>
    8000037c:	0987a783          	lw	a5,152(a5)
    80000380:	0807879b          	addiw	a5,a5,128
    80000384:	06f61f63          	bne	a2,a5,80000402 <consoleintr+0x150>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000388:	863e                	mv	a2,a5
    8000038a:	a0c9                	j	8000044c <consoleintr+0x19a>
    while(cons.e != cons.w &&
    8000038c:	00011717          	auipc	a4,0x11
    80000390:	df470713          	addi	a4,a4,-524 # 80011180 <cons>
    80000394:	0a072783          	lw	a5,160(a4)
    80000398:	09c72703          	lw	a4,156(a4)
    8000039c:	06f70363          	beq	a4,a5,80000402 <consoleintr+0x150>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a0:	37fd                	addiw	a5,a5,-1
    800003a2:	0007871b          	sext.w	a4,a5
    800003a6:	07f7f793          	andi	a5,a5,127
    800003aa:	00011697          	auipc	a3,0x11
    800003ae:	dd668693          	addi	a3,a3,-554 # 80011180 <cons>
    800003b2:	97b6                	add	a5,a5,a3
    while(cons.e != cons.w &&
    800003b4:	0187c683          	lbu	a3,24(a5)
    800003b8:	47a9                	li	a5,10
      cons.e--;
    800003ba:	00011497          	auipc	s1,0x11
    800003be:	dc648493          	addi	s1,s1,-570 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003c2:	4929                	li	s2,10
    800003c4:	02f68f63          	beq	a3,a5,80000402 <consoleintr+0x150>
      cons.e--;
    800003c8:	0ae4a023          	sw	a4,160(s1)
      consputc(BACKSPACE);
    800003cc:	10000513          	li	a0,256
    800003d0:	00000097          	auipc	ra,0x0
    800003d4:	ea0080e7          	jalr	-352(ra) # 80000270 <consputc>
    while(cons.e != cons.w &&
    800003d8:	0a04a783          	lw	a5,160(s1)
    800003dc:	09c4a703          	lw	a4,156(s1)
    800003e0:	02f70163          	beq	a4,a5,80000402 <consoleintr+0x150>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003e4:	37fd                	addiw	a5,a5,-1
    800003e6:	0007871b          	sext.w	a4,a5
    800003ea:	07f7f793          	andi	a5,a5,127
    800003ee:	97a6                	add	a5,a5,s1
    while(cons.e != cons.w &&
    800003f0:	0187c783          	lbu	a5,24(a5)
    800003f4:	fd279ae3          	bne	a5,s2,800003c8 <consoleintr+0x116>
    800003f8:	a029                	j	80000402 <consoleintr+0x150>
    procdump();
    800003fa:	00002097          	auipc	ra,0x2
    800003fe:	1d4080e7          	jalr	468(ra) # 800025ce <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000402:	00011517          	auipc	a0,0x11
    80000406:	d7e50513          	addi	a0,a0,-642 # 80011180 <cons>
    8000040a:	00001097          	auipc	ra,0x1
    8000040e:	8ce080e7          	jalr	-1842(ra) # 80000cd8 <release>
}
    80000412:	60e2                	ld	ra,24(sp)
    80000414:	6442                	ld	s0,16(sp)
    80000416:	64a2                	ld	s1,8(sp)
    80000418:	6902                	ld	s2,0(sp)
    8000041a:	6105                	addi	sp,sp,32
    8000041c:	8082                	ret
      consputc(c);
    8000041e:	4529                	li	a0,10
    80000420:	00000097          	auipc	ra,0x0
    80000424:	e50080e7          	jalr	-432(ra) # 80000270 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	d5878793          	addi	a5,a5,-680 # 80011180 <cons>
    80000430:	0a07a703          	lw	a4,160(a5)
    80000434:	0017069b          	addiw	a3,a4,1
    80000438:	0006861b          	sext.w	a2,a3
    8000043c:	0ad7a023          	sw	a3,160(a5)
    80000440:	07f77713          	andi	a4,a4,127
    80000444:	97ba                	add	a5,a5,a4
    80000446:	4729                	li	a4,10
    80000448:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000044c:	00011797          	auipc	a5,0x11
    80000450:	dcc7a823          	sw	a2,-560(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000454:	00011517          	auipc	a0,0x11
    80000458:	dc450513          	addi	a0,a0,-572 # 80011218 <cons+0x98>
    8000045c:	00002097          	auipc	ra,0x2
    80000460:	fea080e7          	jalr	-22(ra) # 80002446 <wakeup>
    80000464:	bf79                	j	80000402 <consoleintr+0x150>

0000000080000466 <consoleinit>:

void
consoleinit(void)
{
    80000466:	1141                	addi	sp,sp,-16
    80000468:	e406                	sd	ra,8(sp)
    8000046a:	e022                	sd	s0,0(sp)
    8000046c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000046e:	00008597          	auipc	a1,0x8
    80000472:	ba258593          	addi	a1,a1,-1118 # 80008010 <etext+0x10>
    80000476:	00011517          	auipc	a0,0x11
    8000047a:	d0a50513          	addi	a0,a0,-758 # 80011180 <cons>
    8000047e:	00000097          	auipc	ra,0x0
    80000482:	716080e7          	jalr	1814(ra) # 80000b94 <initlock>

  uartinit();
    80000486:	00000097          	auipc	ra,0x0
    8000048a:	334080e7          	jalr	820(ra) # 800007ba <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000048e:	0002d797          	auipc	a5,0x2d
    80000492:	e7278793          	addi	a5,a5,-398 # 8002d300 <devsw>
    80000496:	00000717          	auipc	a4,0x0
    8000049a:	cbe70713          	addi	a4,a4,-834 # 80000154 <consoleread>
    8000049e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004a0:	00000717          	auipc	a4,0x0
    800004a4:	c5270713          	addi	a4,a4,-942 # 800000f2 <consolewrite>
    800004a8:	ef98                	sd	a4,24(a5)
}
    800004aa:	60a2                	ld	ra,8(sp)
    800004ac:	6402                	ld	s0,0(sp)
    800004ae:	0141                	addi	sp,sp,16
    800004b0:	8082                	ret

00000000800004b2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004b2:	7179                	addi	sp,sp,-48
    800004b4:	f406                	sd	ra,40(sp)
    800004b6:	f022                	sd	s0,32(sp)
    800004b8:	ec26                	sd	s1,24(sp)
    800004ba:	e84a                	sd	s2,16(sp)
    800004bc:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004be:	c219                	beqz	a2,800004c4 <printint+0x12>
    800004c0:	00054d63          	bltz	a0,800004da <printint+0x28>
    x = -xx;
  else
    x = xx;
    800004c4:	2501                	sext.w	a0,a0
    800004c6:	4881                	li	a7,0
    800004c8:	fd040713          	addi	a4,s0,-48

  i = 0;
    800004cc:	4601                	li	a2,0
  do {
    buf[i++] = digits[x % base];
    800004ce:	2581                	sext.w	a1,a1
    800004d0:	00008817          	auipc	a6,0x8
    800004d4:	b4880813          	addi	a6,a6,-1208 # 80008018 <digits>
    800004d8:	a801                	j	800004e8 <printint+0x36>
    x = -xx;
    800004da:	40a0053b          	negw	a0,a0
    800004de:	2501                	sext.w	a0,a0
  if(sign && (sign = xx < 0))
    800004e0:	4885                	li	a7,1
    x = -xx;
    800004e2:	b7dd                	j	800004c8 <printint+0x16>
  } while((x /= base) != 0);
    800004e4:	853e                	mv	a0,a5
    buf[i++] = digits[x % base];
    800004e6:	8636                	mv	a2,a3
    800004e8:	0016069b          	addiw	a3,a2,1
    800004ec:	02b577bb          	remuw	a5,a0,a1
    800004f0:	1782                	slli	a5,a5,0x20
    800004f2:	9381                	srli	a5,a5,0x20
    800004f4:	97c2                	add	a5,a5,a6
    800004f6:	0007c783          	lbu	a5,0(a5)
    800004fa:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800004fe:	0705                	addi	a4,a4,1
    80000500:	02b557bb          	divuw	a5,a0,a1
    80000504:	feb570e3          	bleu	a1,a0,800004e4 <printint+0x32>

  if(sign)
    80000508:	00088b63          	beqz	a7,8000051e <printint+0x6c>
    buf[i++] = '-';
    8000050c:	fe040793          	addi	a5,s0,-32
    80000510:	96be                	add	a3,a3,a5
    80000512:	02d00793          	li	a5,45
    80000516:	fef68823          	sb	a5,-16(a3)
    8000051a:	0026069b          	addiw	a3,a2,2

  while(--i >= 0)
    8000051e:	02d05763          	blez	a3,8000054c <printint+0x9a>
    80000522:	fd040793          	addi	a5,s0,-48
    80000526:	00d784b3          	add	s1,a5,a3
    8000052a:	fff78913          	addi	s2,a5,-1
    8000052e:	9936                	add	s2,s2,a3
    80000530:	36fd                	addiw	a3,a3,-1
    80000532:	1682                	slli	a3,a3,0x20
    80000534:	9281                	srli	a3,a3,0x20
    80000536:	40d90933          	sub	s2,s2,a3
    consputc(buf[i]);
    8000053a:	fff4c503          	lbu	a0,-1(s1)
    8000053e:	00000097          	auipc	ra,0x0
    80000542:	d32080e7          	jalr	-718(ra) # 80000270 <consputc>
  while(--i >= 0)
    80000546:	14fd                	addi	s1,s1,-1
    80000548:	ff2499e3          	bne	s1,s2,8000053a <printint+0x88>
}
    8000054c:	70a2                	ld	ra,40(sp)
    8000054e:	7402                	ld	s0,32(sp)
    80000550:	64e2                	ld	s1,24(sp)
    80000552:	6942                	ld	s2,16(sp)
    80000554:	6145                	addi	sp,sp,48
    80000556:	8082                	ret

0000000080000558 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000558:	1101                	addi	sp,sp,-32
    8000055a:	ec06                	sd	ra,24(sp)
    8000055c:	e822                	sd	s0,16(sp)
    8000055e:	e426                	sd	s1,8(sp)
    80000560:	1000                	addi	s0,sp,32
    80000562:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000564:	00011797          	auipc	a5,0x11
    80000568:	cc07ae23          	sw	zero,-804(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	ac450513          	addi	a0,a0,-1340 # 80008030 <digits+0x18>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	02e080e7          	jalr	46(ra) # 800005a2 <printf>
  printf(s);
    8000057c:	8526                	mv	a0,s1
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	024080e7          	jalr	36(ra) # 800005a2 <printf>
  printf("\n");
    80000586:	00008517          	auipc	a0,0x8
    8000058a:	b4250513          	addi	a0,a0,-1214 # 800080c8 <digits+0xb0>
    8000058e:	00000097          	auipc	ra,0x0
    80000592:	014080e7          	jalr	20(ra) # 800005a2 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000596:	4785                	li	a5,1
    80000598:	00009717          	auipc	a4,0x9
    8000059c:	a6f72423          	sw	a5,-1432(a4) # 80009000 <panicked>
  for(;;)
    800005a0:	a001                	j	800005a0 <panic+0x48>

00000000800005a2 <printf>:
{
    800005a2:	7131                	addi	sp,sp,-192
    800005a4:	fc86                	sd	ra,120(sp)
    800005a6:	f8a2                	sd	s0,112(sp)
    800005a8:	f4a6                	sd	s1,104(sp)
    800005aa:	f0ca                	sd	s2,96(sp)
    800005ac:	ecce                	sd	s3,88(sp)
    800005ae:	e8d2                	sd	s4,80(sp)
    800005b0:	e4d6                	sd	s5,72(sp)
    800005b2:	e0da                	sd	s6,64(sp)
    800005b4:	fc5e                	sd	s7,56(sp)
    800005b6:	f862                	sd	s8,48(sp)
    800005b8:	f466                	sd	s9,40(sp)
    800005ba:	f06a                	sd	s10,32(sp)
    800005bc:	ec6e                	sd	s11,24(sp)
    800005be:	0100                	addi	s0,sp,128
    800005c0:	8aaa                	mv	s5,a0
    800005c2:	e40c                	sd	a1,8(s0)
    800005c4:	e810                	sd	a2,16(s0)
    800005c6:	ec14                	sd	a3,24(s0)
    800005c8:	f018                	sd	a4,32(s0)
    800005ca:	f41c                	sd	a5,40(s0)
    800005cc:	03043823          	sd	a6,48(s0)
    800005d0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005d4:	00011797          	auipc	a5,0x11
    800005d8:	c5478793          	addi	a5,a5,-940 # 80011228 <pr>
    800005dc:	0187ad83          	lw	s11,24(a5)
  if(locking)
    800005e0:	020d9b63          	bnez	s11,80000616 <printf+0x74>
  if (fmt == 0)
    800005e4:	020a8f63          	beqz	s5,80000622 <printf+0x80>
  va_start(ap, fmt);
    800005e8:	00840793          	addi	a5,s0,8
    800005ec:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005f0:	000ac503          	lbu	a0,0(s5)
    800005f4:	16050063          	beqz	a0,80000754 <printf+0x1b2>
    800005f8:	4481                	li	s1,0
    if(c != '%'){
    800005fa:	02500a13          	li	s4,37
    switch(c){
    800005fe:	07000b13          	li	s6,112
  consputc('x');
    80000602:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000604:	00008b97          	auipc	s7,0x8
    80000608:	a14b8b93          	addi	s7,s7,-1516 # 80008018 <digits>
    switch(c){
    8000060c:	07300c93          	li	s9,115
    80000610:	06400c13          	li	s8,100
    80000614:	a815                	j	80000648 <printf+0xa6>
    acquire(&pr.lock);
    80000616:	853e                	mv	a0,a5
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	60c080e7          	jalr	1548(ra) # 80000c24 <acquire>
    80000620:	b7d1                	j	800005e4 <printf+0x42>
    panic("null fmt");
    80000622:	00008517          	auipc	a0,0x8
    80000626:	a1e50513          	addi	a0,a0,-1506 # 80008040 <digits+0x28>
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	f2e080e7          	jalr	-210(ra) # 80000558 <panic>
      consputc(c);
    80000632:	00000097          	auipc	ra,0x0
    80000636:	c3e080e7          	jalr	-962(ra) # 80000270 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a87b3          	add	a5,s5,s1
    80000640:	0007c503          	lbu	a0,0(a5)
    80000644:	10050863          	beqz	a0,80000754 <printf+0x1b2>
    if(c != '%'){
    80000648:	ff4515e3          	bne	a0,s4,80000632 <printf+0x90>
    c = fmt[++i] & 0xff;
    8000064c:	2485                	addiw	s1,s1,1
    8000064e:	009a87b3          	add	a5,s5,s1
    80000652:	0007c783          	lbu	a5,0(a5)
    80000656:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000065a:	0e090d63          	beqz	s2,80000754 <printf+0x1b2>
    switch(c){
    8000065e:	05678a63          	beq	a5,s6,800006b2 <printf+0x110>
    80000662:	02fb7663          	bleu	a5,s6,8000068e <printf+0xec>
    80000666:	09978963          	beq	a5,s9,800006f8 <printf+0x156>
    8000066a:	07800713          	li	a4,120
    8000066e:	0ce79863          	bne	a5,a4,8000073e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000672:	f8843783          	ld	a5,-120(s0)
    80000676:	00878713          	addi	a4,a5,8
    8000067a:	f8e43423          	sd	a4,-120(s0)
    8000067e:	4605                	li	a2,1
    80000680:	85ea                	mv	a1,s10
    80000682:	4388                	lw	a0,0(a5)
    80000684:	00000097          	auipc	ra,0x0
    80000688:	e2e080e7          	jalr	-466(ra) # 800004b2 <printint>
      break;
    8000068c:	b77d                	j	8000063a <printf+0x98>
    switch(c){
    8000068e:	0b478263          	beq	a5,s4,80000732 <printf+0x190>
    80000692:	0b879663          	bne	a5,s8,8000073e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	4605                	li	a2,1
    800006a4:	45a9                	li	a1,10
    800006a6:	4388                	lw	a0,0(a5)
    800006a8:	00000097          	auipc	ra,0x0
    800006ac:	e0a080e7          	jalr	-502(ra) # 800004b2 <printint>
      break;
    800006b0:	b769                	j	8000063a <printf+0x98>
      printptr(va_arg(ap, uint64));
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006c2:	03000513          	li	a0,48
    800006c6:	00000097          	auipc	ra,0x0
    800006ca:	baa080e7          	jalr	-1110(ra) # 80000270 <consputc>
  consputc('x');
    800006ce:	07800513          	li	a0,120
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	b9e080e7          	jalr	-1122(ra) # 80000270 <consputc>
    800006da:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006dc:	03c9d793          	srli	a5,s3,0x3c
    800006e0:	97de                	add	a5,a5,s7
    800006e2:	0007c503          	lbu	a0,0(a5)
    800006e6:	00000097          	auipc	ra,0x0
    800006ea:	b8a080e7          	jalr	-1142(ra) # 80000270 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006ee:	0992                	slli	s3,s3,0x4
    800006f0:	397d                	addiw	s2,s2,-1
    800006f2:	fe0915e3          	bnez	s2,800006dc <printf+0x13a>
    800006f6:	b791                	j	8000063a <printf+0x98>
      if((s = va_arg(ap, char*)) == 0)
    800006f8:	f8843783          	ld	a5,-120(s0)
    800006fc:	00878713          	addi	a4,a5,8
    80000700:	f8e43423          	sd	a4,-120(s0)
    80000704:	0007b903          	ld	s2,0(a5)
    80000708:	00090e63          	beqz	s2,80000724 <printf+0x182>
      for(; *s; s++)
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	d50d                	beqz	a0,8000063a <printf+0x98>
        consputc(*s);
    80000712:	00000097          	auipc	ra,0x0
    80000716:	b5e080e7          	jalr	-1186(ra) # 80000270 <consputc>
      for(; *s; s++)
    8000071a:	0905                	addi	s2,s2,1
    8000071c:	00094503          	lbu	a0,0(s2)
    80000720:	f96d                	bnez	a0,80000712 <printf+0x170>
    80000722:	bf21                	j	8000063a <printf+0x98>
        s = "(null)";
    80000724:	00008917          	auipc	s2,0x8
    80000728:	91490913          	addi	s2,s2,-1772 # 80008038 <digits+0x20>
      for(; *s; s++)
    8000072c:	02800513          	li	a0,40
    80000730:	b7cd                	j	80000712 <printf+0x170>
      consputc('%');
    80000732:	8552                	mv	a0,s4
    80000734:	00000097          	auipc	ra,0x0
    80000738:	b3c080e7          	jalr	-1220(ra) # 80000270 <consputc>
      break;
    8000073c:	bdfd                	j	8000063a <printf+0x98>
      consputc('%');
    8000073e:	8552                	mv	a0,s4
    80000740:	00000097          	auipc	ra,0x0
    80000744:	b30080e7          	jalr	-1232(ra) # 80000270 <consputc>
      consputc(c);
    80000748:	854a                	mv	a0,s2
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	b26080e7          	jalr	-1242(ra) # 80000270 <consputc>
      break;
    80000752:	b5e5                	j	8000063a <printf+0x98>
  if(locking)
    80000754:	020d9163          	bnez	s11,80000776 <printf+0x1d4>
}
    80000758:	70e6                	ld	ra,120(sp)
    8000075a:	7446                	ld	s0,112(sp)
    8000075c:	74a6                	ld	s1,104(sp)
    8000075e:	7906                	ld	s2,96(sp)
    80000760:	69e6                	ld	s3,88(sp)
    80000762:	6a46                	ld	s4,80(sp)
    80000764:	6aa6                	ld	s5,72(sp)
    80000766:	6b06                	ld	s6,64(sp)
    80000768:	7be2                	ld	s7,56(sp)
    8000076a:	7c42                	ld	s8,48(sp)
    8000076c:	7ca2                	ld	s9,40(sp)
    8000076e:	7d02                	ld	s10,32(sp)
    80000770:	6de2                	ld	s11,24(sp)
    80000772:	6129                	addi	sp,sp,192
    80000774:	8082                	ret
    release(&pr.lock);
    80000776:	00011517          	auipc	a0,0x11
    8000077a:	ab250513          	addi	a0,a0,-1358 # 80011228 <pr>
    8000077e:	00000097          	auipc	ra,0x0
    80000782:	55a080e7          	jalr	1370(ra) # 80000cd8 <release>
}
    80000786:	bfc9                	j	80000758 <printf+0x1b6>

0000000080000788 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000788:	1101                	addi	sp,sp,-32
    8000078a:	ec06                	sd	ra,24(sp)
    8000078c:	e822                	sd	s0,16(sp)
    8000078e:	e426                	sd	s1,8(sp)
    80000790:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000792:	00011497          	auipc	s1,0x11
    80000796:	a9648493          	addi	s1,s1,-1386 # 80011228 <pr>
    8000079a:	00008597          	auipc	a1,0x8
    8000079e:	8b658593          	addi	a1,a1,-1866 # 80008050 <digits+0x38>
    800007a2:	8526                	mv	a0,s1
    800007a4:	00000097          	auipc	ra,0x0
    800007a8:	3f0080e7          	jalr	1008(ra) # 80000b94 <initlock>
  pr.locking = 1;
    800007ac:	4785                	li	a5,1
    800007ae:	cc9c                	sw	a5,24(s1)
}
    800007b0:	60e2                	ld	ra,24(sp)
    800007b2:	6442                	ld	s0,16(sp)
    800007b4:	64a2                	ld	s1,8(sp)
    800007b6:	6105                	addi	sp,sp,32
    800007b8:	8082                	ret

00000000800007ba <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007ba:	1141                	addi	sp,sp,-16
    800007bc:	e406                	sd	ra,8(sp)
    800007be:	e022                	sd	s0,0(sp)
    800007c0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007c2:	100007b7          	lui	a5,0x10000
    800007c6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ca:	f8000713          	li	a4,-128
    800007ce:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007d2:	470d                	li	a4,3
    800007d4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007dc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007e0:	469d                	li	a3,7
    800007e2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007e6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ea:	00008597          	auipc	a1,0x8
    800007ee:	86e58593          	addi	a1,a1,-1938 # 80008058 <digits+0x40>
    800007f2:	00011517          	auipc	a0,0x11
    800007f6:	a5650513          	addi	a0,a0,-1450 # 80011248 <uart_tx_lock>
    800007fa:	00000097          	auipc	ra,0x0
    800007fe:	39a080e7          	jalr	922(ra) # 80000b94 <initlock>
}
    80000802:	60a2                	ld	ra,8(sp)
    80000804:	6402                	ld	s0,0(sp)
    80000806:	0141                	addi	sp,sp,16
    80000808:	8082                	ret

000000008000080a <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000080a:	1101                	addi	sp,sp,-32
    8000080c:	ec06                	sd	ra,24(sp)
    8000080e:	e822                	sd	s0,16(sp)
    80000810:	e426                	sd	s1,8(sp)
    80000812:	1000                	addi	s0,sp,32
    80000814:	84aa                	mv	s1,a0
  push_off();
    80000816:	00000097          	auipc	ra,0x0
    8000081a:	3c2080e7          	jalr	962(ra) # 80000bd8 <push_off>

  if(panicked){
    8000081e:	00008797          	auipc	a5,0x8
    80000822:	7e278793          	addi	a5,a5,2018 # 80009000 <panicked>
    80000826:	439c                	lw	a5,0(a5)
    80000828:	2781                	sext.w	a5,a5
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000082a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000082e:	c391                	beqz	a5,80000832 <uartputc_sync+0x28>
    for(;;)
    80000830:	a001                	j	80000830 <uartputc_sync+0x26>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000832:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000836:	0ff7f793          	andi	a5,a5,255
    8000083a:	0207f793          	andi	a5,a5,32
    8000083e:	dbf5                	beqz	a5,80000832 <uartputc_sync+0x28>
    ;
  WriteReg(THR, c);
    80000840:	0ff4f793          	andi	a5,s1,255
    80000844:	10000737          	lui	a4,0x10000
    80000848:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	42c080e7          	jalr	1068(ra) # 80000c78 <pop_off>
}
    80000854:	60e2                	ld	ra,24(sp)
    80000856:	6442                	ld	s0,16(sp)
    80000858:	64a2                	ld	s1,8(sp)
    8000085a:	6105                	addi	sp,sp,32
    8000085c:	8082                	ret

000000008000085e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000085e:	00008797          	auipc	a5,0x8
    80000862:	7aa78793          	addi	a5,a5,1962 # 80009008 <uart_tx_r>
    80000866:	639c                	ld	a5,0(a5)
    80000868:	00008717          	auipc	a4,0x8
    8000086c:	7a870713          	addi	a4,a4,1960 # 80009010 <uart_tx_w>
    80000870:	6318                	ld	a4,0(a4)
    80000872:	08f70563          	beq	a4,a5,800008fc <uartstart+0x9e>
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000876:	10000737          	lui	a4,0x10000
    8000087a:	00574703          	lbu	a4,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000087e:	0ff77713          	andi	a4,a4,255
    80000882:	02077713          	andi	a4,a4,32
    80000886:	cb3d                	beqz	a4,800008fc <uartstart+0x9e>
{
    80000888:	7139                	addi	sp,sp,-64
    8000088a:	fc06                	sd	ra,56(sp)
    8000088c:	f822                	sd	s0,48(sp)
    8000088e:	f426                	sd	s1,40(sp)
    80000890:	f04a                	sd	s2,32(sp)
    80000892:	ec4e                	sd	s3,24(sp)
    80000894:	e852                	sd	s4,16(sp)
    80000896:	e456                	sd	s5,8(sp)
    80000898:	0080                	addi	s0,sp,64
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000089a:	00011a17          	auipc	s4,0x11
    8000089e:	9aea0a13          	addi	s4,s4,-1618 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    800008a2:	00008497          	auipc	s1,0x8
    800008a6:	76648493          	addi	s1,s1,1894 # 80009008 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008aa:	10000937          	lui	s2,0x10000
    if(uart_tx_w == uart_tx_r){
    800008ae:	00008997          	auipc	s3,0x8
    800008b2:	76298993          	addi	s3,s3,1890 # 80009010 <uart_tx_w>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008b6:	01f7f713          	andi	a4,a5,31
    800008ba:	9752                	add	a4,a4,s4
    800008bc:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    800008c0:	0785                	addi	a5,a5,1
    800008c2:	e09c                	sd	a5,0(s1)
    wakeup(&uart_tx_r);
    800008c4:	8526                	mv	a0,s1
    800008c6:	00002097          	auipc	ra,0x2
    800008ca:	b80080e7          	jalr	-1152(ra) # 80002446 <wakeup>
    WriteReg(THR, c);
    800008ce:	01590023          	sb	s5,0(s2) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    800008d2:	609c                	ld	a5,0(s1)
    800008d4:	0009b703          	ld	a4,0(s3)
    800008d8:	00f70963          	beq	a4,a5,800008ea <uartstart+0x8c>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008dc:	00594703          	lbu	a4,5(s2)
    800008e0:	0ff77713          	andi	a4,a4,255
    800008e4:	02077713          	andi	a4,a4,32
    800008e8:	f779                	bnez	a4,800008b6 <uartstart+0x58>
  }
}
    800008ea:	70e2                	ld	ra,56(sp)
    800008ec:	7442                	ld	s0,48(sp)
    800008ee:	74a2                	ld	s1,40(sp)
    800008f0:	7902                	ld	s2,32(sp)
    800008f2:	69e2                	ld	s3,24(sp)
    800008f4:	6a42                	ld	s4,16(sp)
    800008f6:	6aa2                	ld	s5,8(sp)
    800008f8:	6121                	addi	sp,sp,64
    800008fa:	8082                	ret
    800008fc:	8082                	ret

00000000800008fe <uartputc>:
{
    800008fe:	7179                	addi	sp,sp,-48
    80000900:	f406                	sd	ra,40(sp)
    80000902:	f022                	sd	s0,32(sp)
    80000904:	ec26                	sd	s1,24(sp)
    80000906:	e84a                	sd	s2,16(sp)
    80000908:	e44e                	sd	s3,8(sp)
    8000090a:	e052                	sd	s4,0(sp)
    8000090c:	1800                	addi	s0,sp,48
    8000090e:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000910:	00011517          	auipc	a0,0x11
    80000914:	93850513          	addi	a0,a0,-1736 # 80011248 <uart_tx_lock>
    80000918:	00000097          	auipc	ra,0x0
    8000091c:	30c080e7          	jalr	780(ra) # 80000c24 <acquire>
  if(panicked){
    80000920:	00008797          	auipc	a5,0x8
    80000924:	6e078793          	addi	a5,a5,1760 # 80009000 <panicked>
    80000928:	439c                	lw	a5,0(a5)
    8000092a:	2781                	sext.w	a5,a5
    8000092c:	c391                	beqz	a5,80000930 <uartputc+0x32>
    for(;;)
    8000092e:	a001                	j	8000092e <uartputc+0x30>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000930:	00008797          	auipc	a5,0x8
    80000934:	6e078793          	addi	a5,a5,1760 # 80009010 <uart_tx_w>
    80000938:	639c                	ld	a5,0(a5)
    8000093a:	00008717          	auipc	a4,0x8
    8000093e:	6ce70713          	addi	a4,a4,1742 # 80009008 <uart_tx_r>
    80000942:	6318                	ld	a4,0(a4)
    80000944:	02070713          	addi	a4,a4,32
    80000948:	02f71b63          	bne	a4,a5,8000097e <uartputc+0x80>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	00011a17          	auipc	s4,0x11
    80000950:	8fca0a13          	addi	s4,s4,-1796 # 80011248 <uart_tx_lock>
    80000954:	00008497          	auipc	s1,0x8
    80000958:	6b448493          	addi	s1,s1,1716 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000095c:	00008917          	auipc	s2,0x8
    80000960:	6b490913          	addi	s2,s2,1716 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000964:	85d2                	mv	a1,s4
    80000966:	8526                	mv	a0,s1
    80000968:	00002097          	auipc	ra,0x2
    8000096c:	958080e7          	jalr	-1704(ra) # 800022c0 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000970:	00093783          	ld	a5,0(s2)
    80000974:	6098                	ld	a4,0(s1)
    80000976:	02070713          	addi	a4,a4,32
    8000097a:	fef705e3          	beq	a4,a5,80000964 <uartputc+0x66>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    8000097e:	00011497          	auipc	s1,0x11
    80000982:	8ca48493          	addi	s1,s1,-1846 # 80011248 <uart_tx_lock>
    80000986:	01f7f713          	andi	a4,a5,31
    8000098a:	9726                	add	a4,a4,s1
    8000098c:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000990:	0785                	addi	a5,a5,1
    80000992:	00008717          	auipc	a4,0x8
    80000996:	66f73f23          	sd	a5,1662(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000099a:	00000097          	auipc	ra,0x0
    8000099e:	ec4080e7          	jalr	-316(ra) # 8000085e <uartstart>
      release(&uart_tx_lock);
    800009a2:	8526                	mv	a0,s1
    800009a4:	00000097          	auipc	ra,0x0
    800009a8:	334080e7          	jalr	820(ra) # 80000cd8 <release>
}
    800009ac:	70a2                	ld	ra,40(sp)
    800009ae:	7402                	ld	s0,32(sp)
    800009b0:	64e2                	ld	s1,24(sp)
    800009b2:	6942                	ld	s2,16(sp)
    800009b4:	69a2                	ld	s3,8(sp)
    800009b6:	6a02                	ld	s4,0(sp)
    800009b8:	6145                	addi	sp,sp,48
    800009ba:	8082                	ret

00000000800009bc <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009bc:	1141                	addi	sp,sp,-16
    800009be:	e422                	sd	s0,8(sp)
    800009c0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009c2:	100007b7          	lui	a5,0x10000
    800009c6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ca:	8b85                	andi	a5,a5,1
    800009cc:	cb91                	beqz	a5,800009e0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009ce:	100007b7          	lui	a5,0x10000
    800009d2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009d6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009da:	6422                	ld	s0,8(sp)
    800009dc:	0141                	addi	sp,sp,16
    800009de:	8082                	ret
    return -1;
    800009e0:	557d                	li	a0,-1
    800009e2:	bfe5                	j	800009da <uartgetc+0x1e>

00000000800009e4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009e4:	1101                	addi	sp,sp,-32
    800009e6:	ec06                	sd	ra,24(sp)
    800009e8:	e822                	sd	s0,16(sp)
    800009ea:	e426                	sd	s1,8(sp)
    800009ec:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ee:	54fd                	li	s1,-1
    int c = uartgetc();
    800009f0:	00000097          	auipc	ra,0x0
    800009f4:	fcc080e7          	jalr	-52(ra) # 800009bc <uartgetc>
    if(c == -1)
    800009f8:	00950763          	beq	a0,s1,80000a06 <uartintr+0x22>
      break;
    consoleintr(c);
    800009fc:	00000097          	auipc	ra,0x0
    80000a00:	8b6080e7          	jalr	-1866(ra) # 800002b2 <consoleintr>
  while(1){
    80000a04:	b7f5                	j	800009f0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a06:	00011497          	auipc	s1,0x11
    80000a0a:	84248493          	addi	s1,s1,-1982 # 80011248 <uart_tx_lock>
    80000a0e:	8526                	mv	a0,s1
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	214080e7          	jalr	532(ra) # 80000c24 <acquire>
  uartstart();
    80000a18:	00000097          	auipc	ra,0x0
    80000a1c:	e46080e7          	jalr	-442(ra) # 8000085e <uartstart>
  release(&uart_tx_lock);
    80000a20:	8526                	mv	a0,s1
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	2b6080e7          	jalr	694(ra) # 80000cd8 <release>
}
    80000a2a:	60e2                	ld	ra,24(sp)
    80000a2c:	6442                	ld	s0,16(sp)
    80000a2e:	64a2                	ld	s1,8(sp)
    80000a30:	6105                	addi	sp,sp,32
    80000a32:	8082                	ret

0000000080000a34 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a34:	1101                	addi	sp,sp,-32
    80000a36:	ec06                	sd	ra,24(sp)
    80000a38:	e822                	sd	s0,16(sp)
    80000a3a:	e426                	sd	s1,8(sp)
    80000a3c:	e04a                	sd	s2,0(sp)
    80000a3e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a40:	6785                	lui	a5,0x1
    80000a42:	17fd                	addi	a5,a5,-1
    80000a44:	8fe9                	and	a5,a5,a0
    80000a46:	ebb9                	bnez	a5,80000a9c <kfree+0x68>
    80000a48:	84aa                	mv	s1,a0
    80000a4a:	00031797          	auipc	a5,0x31
    80000a4e:	5b678793          	addi	a5,a5,1462 # 80032000 <end>
    80000a52:	04f56563          	bltu	a0,a5,80000a9c <kfree+0x68>
    80000a56:	47c5                	li	a5,17
    80000a58:	07ee                	slli	a5,a5,0x1b
    80000a5a:	04f57163          	bleu	a5,a0,80000a9c <kfree+0x68>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a5e:	6605                	lui	a2,0x1
    80000a60:	4585                	li	a1,1
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	2be080e7          	jalr	702(ra) # 80000d20 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a6a:	00011917          	auipc	s2,0x11
    80000a6e:	81690913          	addi	s2,s2,-2026 # 80011280 <kmem>
    80000a72:	854a                	mv	a0,s2
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	1b0080e7          	jalr	432(ra) # 80000c24 <acquire>
  r->next = kmem.freelist;
    80000a7c:	01893783          	ld	a5,24(s2)
    80000a80:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a82:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a86:	854a                	mv	a0,s2
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	250080e7          	jalr	592(ra) # 80000cd8 <release>
}
    80000a90:	60e2                	ld	ra,24(sp)
    80000a92:	6442                	ld	s0,16(sp)
    80000a94:	64a2                	ld	s1,8(sp)
    80000a96:	6902                	ld	s2,0(sp)
    80000a98:	6105                	addi	sp,sp,32
    80000a9a:	8082                	ret
    panic("kfree");
    80000a9c:	00007517          	auipc	a0,0x7
    80000aa0:	5c450513          	addi	a0,a0,1476 # 80008060 <digits+0x48>
    80000aa4:	00000097          	auipc	ra,0x0
    80000aa8:	ab4080e7          	jalr	-1356(ra) # 80000558 <panic>

0000000080000aac <freerange>:
{
    80000aac:	7179                	addi	sp,sp,-48
    80000aae:	f406                	sd	ra,40(sp)
    80000ab0:	f022                	sd	s0,32(sp)
    80000ab2:	ec26                	sd	s1,24(sp)
    80000ab4:	e84a                	sd	s2,16(sp)
    80000ab6:	e44e                	sd	s3,8(sp)
    80000ab8:	e052                	sd	s4,0(sp)
    80000aba:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000abc:	6705                	lui	a4,0x1
    80000abe:	fff70793          	addi	a5,a4,-1 # fff <_entry-0x7ffff001>
    80000ac2:	00f504b3          	add	s1,a0,a5
    80000ac6:	77fd                	lui	a5,0xfffff
    80000ac8:	8cfd                	and	s1,s1,a5
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aca:	94ba                	add	s1,s1,a4
    80000acc:	0095ee63          	bltu	a1,s1,80000ae8 <freerange+0x3c>
    80000ad0:	892e                	mv	s2,a1
    kfree(p);
    80000ad2:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad4:	6985                	lui	s3,0x1
    kfree(p);
    80000ad6:	01448533          	add	a0,s1,s4
    80000ada:	00000097          	auipc	ra,0x0
    80000ade:	f5a080e7          	jalr	-166(ra) # 80000a34 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae2:	94ce                	add	s1,s1,s3
    80000ae4:	fe9979e3          	bleu	s1,s2,80000ad6 <freerange+0x2a>
}
    80000ae8:	70a2                	ld	ra,40(sp)
    80000aea:	7402                	ld	s0,32(sp)
    80000aec:	64e2                	ld	s1,24(sp)
    80000aee:	6942                	ld	s2,16(sp)
    80000af0:	69a2                	ld	s3,8(sp)
    80000af2:	6a02                	ld	s4,0(sp)
    80000af4:	6145                	addi	sp,sp,48
    80000af6:	8082                	ret

0000000080000af8 <kinit>:
{
    80000af8:	1141                	addi	sp,sp,-16
    80000afa:	e406                	sd	ra,8(sp)
    80000afc:	e022                	sd	s0,0(sp)
    80000afe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b00:	00007597          	auipc	a1,0x7
    80000b04:	56858593          	addi	a1,a1,1384 # 80008068 <digits+0x50>
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	77850513          	addi	a0,a0,1912 # 80011280 <kmem>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	084080e7          	jalr	132(ra) # 80000b94 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b18:	45c5                	li	a1,17
    80000b1a:	05ee                	slli	a1,a1,0x1b
    80000b1c:	00031517          	auipc	a0,0x31
    80000b20:	4e450513          	addi	a0,a0,1252 # 80032000 <end>
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	f88080e7          	jalr	-120(ra) # 80000aac <freerange>
}
    80000b2c:	60a2                	ld	ra,8(sp)
    80000b2e:	6402                	ld	s0,0(sp)
    80000b30:	0141                	addi	sp,sp,16
    80000b32:	8082                	ret

0000000080000b34 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b34:	1101                	addi	sp,sp,-32
    80000b36:	ec06                	sd	ra,24(sp)
    80000b38:	e822                	sd	s0,16(sp)
    80000b3a:	e426                	sd	s1,8(sp)
    80000b3c:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b3e:	00010497          	auipc	s1,0x10
    80000b42:	74248493          	addi	s1,s1,1858 # 80011280 <kmem>
    80000b46:	8526                	mv	a0,s1
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	0dc080e7          	jalr	220(ra) # 80000c24 <acquire>
  r = kmem.freelist;
    80000b50:	6c84                	ld	s1,24(s1)
  if(r)
    80000b52:	c885                	beqz	s1,80000b82 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b54:	609c                	ld	a5,0(s1)
    80000b56:	00010517          	auipc	a0,0x10
    80000b5a:	72a50513          	addi	a0,a0,1834 # 80011280 <kmem>
    80000b5e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b60:	00000097          	auipc	ra,0x0
    80000b64:	178080e7          	jalr	376(ra) # 80000cd8 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b68:	6605                	lui	a2,0x1
    80000b6a:	4595                	li	a1,5
    80000b6c:	8526                	mv	a0,s1
    80000b6e:	00000097          	auipc	ra,0x0
    80000b72:	1b2080e7          	jalr	434(ra) # 80000d20 <memset>
  return (void*)r;
}
    80000b76:	8526                	mv	a0,s1
    80000b78:	60e2                	ld	ra,24(sp)
    80000b7a:	6442                	ld	s0,16(sp)
    80000b7c:	64a2                	ld	s1,8(sp)
    80000b7e:	6105                	addi	sp,sp,32
    80000b80:	8082                	ret
  release(&kmem.lock);
    80000b82:	00010517          	auipc	a0,0x10
    80000b86:	6fe50513          	addi	a0,a0,1790 # 80011280 <kmem>
    80000b8a:	00000097          	auipc	ra,0x0
    80000b8e:	14e080e7          	jalr	334(ra) # 80000cd8 <release>
  if(r)
    80000b92:	b7d5                	j	80000b76 <kalloc+0x42>

0000000080000b94 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b94:	1141                	addi	sp,sp,-16
    80000b96:	e422                	sd	s0,8(sp)
    80000b98:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b9a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b9c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000ba0:	00053823          	sd	zero,16(a0)
}
    80000ba4:	6422                	ld	s0,8(sp)
    80000ba6:	0141                	addi	sp,sp,16
    80000ba8:	8082                	ret

0000000080000baa <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000baa:	411c                	lw	a5,0(a0)
    80000bac:	e399                	bnez	a5,80000bb2 <holding+0x8>
    80000bae:	4501                	li	a0,0
  return r;
}
    80000bb0:	8082                	ret
{
    80000bb2:	1101                	addi	sp,sp,-32
    80000bb4:	ec06                	sd	ra,24(sp)
    80000bb6:	e822                	sd	s0,16(sp)
    80000bb8:	e426                	sd	s1,8(sp)
    80000bba:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bbc:	6904                	ld	s1,16(a0)
    80000bbe:	00001097          	auipc	ra,0x1
    80000bc2:	e64080e7          	jalr	-412(ra) # 80001a22 <mycpu>
    80000bc6:	40a48533          	sub	a0,s1,a0
    80000bca:	00153513          	seqz	a0,a0
}
    80000bce:	60e2                	ld	ra,24(sp)
    80000bd0:	6442                	ld	s0,16(sp)
    80000bd2:	64a2                	ld	s1,8(sp)
    80000bd4:	6105                	addi	sp,sp,32
    80000bd6:	8082                	ret

0000000080000bd8 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd8:	1101                	addi	sp,sp,-32
    80000bda:	ec06                	sd	ra,24(sp)
    80000bdc:	e822                	sd	s0,16(sp)
    80000bde:	e426                	sd	s1,8(sp)
    80000be0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000be2:	100024f3          	csrr	s1,sstatus
    80000be6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bea:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bec:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bf0:	00001097          	auipc	ra,0x1
    80000bf4:	e32080e7          	jalr	-462(ra) # 80001a22 <mycpu>
    80000bf8:	5d3c                	lw	a5,120(a0)
    80000bfa:	cf89                	beqz	a5,80000c14 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bfc:	00001097          	auipc	ra,0x1
    80000c00:	e26080e7          	jalr	-474(ra) # 80001a22 <mycpu>
    80000c04:	5d3c                	lw	a5,120(a0)
    80000c06:	2785                	addiw	a5,a5,1
    80000c08:	dd3c                	sw	a5,120(a0)
}
    80000c0a:	60e2                	ld	ra,24(sp)
    80000c0c:	6442                	ld	s0,16(sp)
    80000c0e:	64a2                	ld	s1,8(sp)
    80000c10:	6105                	addi	sp,sp,32
    80000c12:	8082                	ret
    mycpu()->intena = old;
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	e0e080e7          	jalr	-498(ra) # 80001a22 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c1c:	8085                	srli	s1,s1,0x1
    80000c1e:	8885                	andi	s1,s1,1
    80000c20:	dd64                	sw	s1,124(a0)
    80000c22:	bfe9                	j	80000bfc <push_off+0x24>

0000000080000c24 <acquire>:
{
    80000c24:	1101                	addi	sp,sp,-32
    80000c26:	ec06                	sd	ra,24(sp)
    80000c28:	e822                	sd	s0,16(sp)
    80000c2a:	e426                	sd	s1,8(sp)
    80000c2c:	1000                	addi	s0,sp,32
    80000c2e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	fa8080e7          	jalr	-88(ra) # 80000bd8 <push_off>
  if(holding(lk))
    80000c38:	8526                	mv	a0,s1
    80000c3a:	00000097          	auipc	ra,0x0
    80000c3e:	f70080e7          	jalr	-144(ra) # 80000baa <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c42:	4705                	li	a4,1
  if(holding(lk))
    80000c44:	e115                	bnez	a0,80000c68 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c46:	87ba                	mv	a5,a4
    80000c48:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c4c:	2781                	sext.w	a5,a5
    80000c4e:	ffe5                	bnez	a5,80000c46 <acquire+0x22>
  __sync_synchronize();
    80000c50:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c54:	00001097          	auipc	ra,0x1
    80000c58:	dce080e7          	jalr	-562(ra) # 80001a22 <mycpu>
    80000c5c:	e888                	sd	a0,16(s1)
}
    80000c5e:	60e2                	ld	ra,24(sp)
    80000c60:	6442                	ld	s0,16(sp)
    80000c62:	64a2                	ld	s1,8(sp)
    80000c64:	6105                	addi	sp,sp,32
    80000c66:	8082                	ret
    panic("acquire");
    80000c68:	00007517          	auipc	a0,0x7
    80000c6c:	40850513          	addi	a0,a0,1032 # 80008070 <digits+0x58>
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	8e8080e7          	jalr	-1816(ra) # 80000558 <panic>

0000000080000c78 <pop_off>:

void
pop_off(void)
{
    80000c78:	1141                	addi	sp,sp,-16
    80000c7a:	e406                	sd	ra,8(sp)
    80000c7c:	e022                	sd	s0,0(sp)
    80000c7e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c80:	00001097          	auipc	ra,0x1
    80000c84:	da2080e7          	jalr	-606(ra) # 80001a22 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c88:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c8c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c8e:	e78d                	bnez	a5,80000cb8 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c90:	5d3c                	lw	a5,120(a0)
    80000c92:	02f05b63          	blez	a5,80000cc8 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c96:	37fd                	addiw	a5,a5,-1
    80000c98:	0007871b          	sext.w	a4,a5
    80000c9c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c9e:	eb09                	bnez	a4,80000cb0 <pop_off+0x38>
    80000ca0:	5d7c                	lw	a5,124(a0)
    80000ca2:	c799                	beqz	a5,80000cb0 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ca8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cac:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cb0:	60a2                	ld	ra,8(sp)
    80000cb2:	6402                	ld	s0,0(sp)
    80000cb4:	0141                	addi	sp,sp,16
    80000cb6:	8082                	ret
    panic("pop_off - interruptible");
    80000cb8:	00007517          	auipc	a0,0x7
    80000cbc:	3c050513          	addi	a0,a0,960 # 80008078 <digits+0x60>
    80000cc0:	00000097          	auipc	ra,0x0
    80000cc4:	898080e7          	jalr	-1896(ra) # 80000558 <panic>
    panic("pop_off");
    80000cc8:	00007517          	auipc	a0,0x7
    80000ccc:	3c850513          	addi	a0,a0,968 # 80008090 <digits+0x78>
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	888080e7          	jalr	-1912(ra) # 80000558 <panic>

0000000080000cd8 <release>:
{
    80000cd8:	1101                	addi	sp,sp,-32
    80000cda:	ec06                	sd	ra,24(sp)
    80000cdc:	e822                	sd	s0,16(sp)
    80000cde:	e426                	sd	s1,8(sp)
    80000ce0:	1000                	addi	s0,sp,32
    80000ce2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	ec6080e7          	jalr	-314(ra) # 80000baa <holding>
    80000cec:	c115                	beqz	a0,80000d10 <release+0x38>
  lk->cpu = 0;
    80000cee:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cf2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cf6:	0f50000f          	fence	iorw,ow
    80000cfa:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cfe:	00000097          	auipc	ra,0x0
    80000d02:	f7a080e7          	jalr	-134(ra) # 80000c78 <pop_off>
}
    80000d06:	60e2                	ld	ra,24(sp)
    80000d08:	6442                	ld	s0,16(sp)
    80000d0a:	64a2                	ld	s1,8(sp)
    80000d0c:	6105                	addi	sp,sp,32
    80000d0e:	8082                	ret
    panic("release");
    80000d10:	00007517          	auipc	a0,0x7
    80000d14:	38850513          	addi	a0,a0,904 # 80008098 <digits+0x80>
    80000d18:	00000097          	auipc	ra,0x0
    80000d1c:	840080e7          	jalr	-1984(ra) # 80000558 <panic>

0000000080000d20 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d20:	1141                	addi	sp,sp,-16
    80000d22:	e422                	sd	s0,8(sp)
    80000d24:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d26:	ce09                	beqz	a2,80000d40 <memset+0x20>
    80000d28:	87aa                	mv	a5,a0
    80000d2a:	fff6071b          	addiw	a4,a2,-1
    80000d2e:	1702                	slli	a4,a4,0x20
    80000d30:	9301                	srli	a4,a4,0x20
    80000d32:	0705                	addi	a4,a4,1
    80000d34:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d36:	00b78023          	sb	a1,0(a5) # fffffffffffff000 <end+0xffffffff7ffcd000>
  for(i = 0; i < n; i++){
    80000d3a:	0785                	addi	a5,a5,1
    80000d3c:	fee79de3          	bne	a5,a4,80000d36 <memset+0x16>
  }
  return dst;
}
    80000d40:	6422                	ld	s0,8(sp)
    80000d42:	0141                	addi	sp,sp,16
    80000d44:	8082                	ret

0000000080000d46 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d4c:	ce15                	beqz	a2,80000d88 <memcmp+0x42>
    80000d4e:	fff6069b          	addiw	a3,a2,-1
    if(*s1 != *s2)
    80000d52:	00054783          	lbu	a5,0(a0)
    80000d56:	0005c703          	lbu	a4,0(a1)
    80000d5a:	02e79063          	bne	a5,a4,80000d7a <memcmp+0x34>
    80000d5e:	1682                	slli	a3,a3,0x20
    80000d60:	9281                	srli	a3,a3,0x20
    80000d62:	0685                	addi	a3,a3,1
    80000d64:	96aa                	add	a3,a3,a0
      return *s1 - *s2;
    s1++, s2++;
    80000d66:	0505                	addi	a0,a0,1
    80000d68:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d6a:	00d50d63          	beq	a0,a3,80000d84 <memcmp+0x3e>
    if(*s1 != *s2)
    80000d6e:	00054783          	lbu	a5,0(a0)
    80000d72:	0005c703          	lbu	a4,0(a1)
    80000d76:	fee788e3          	beq	a5,a4,80000d66 <memcmp+0x20>
      return *s1 - *s2;
    80000d7a:	40e7853b          	subw	a0,a5,a4
  }

  return 0;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
  return 0;
    80000d84:	4501                	li	a0,0
    80000d86:	bfe5                	j	80000d7e <memcmp+0x38>
    80000d88:	4501                	li	a0,0
    80000d8a:	bfd5                	j	80000d7e <memcmp+0x38>

0000000080000d8c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d8c:	1141                	addi	sp,sp,-16
    80000d8e:	e422                	sd	s0,8(sp)
    80000d90:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d92:	00a5f963          	bleu	a0,a1,80000da4 <memmove+0x18>
    80000d96:	02061713          	slli	a4,a2,0x20
    80000d9a:	9301                	srli	a4,a4,0x20
    80000d9c:	00e587b3          	add	a5,a1,a4
    80000da0:	02f56563          	bltu	a0,a5,80000dca <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000da4:	fff6069b          	addiw	a3,a2,-1
    80000da8:	ce11                	beqz	a2,80000dc4 <memmove+0x38>
    80000daa:	1682                	slli	a3,a3,0x20
    80000dac:	9281                	srli	a3,a3,0x20
    80000dae:	0685                	addi	a3,a3,1
    80000db0:	96ae                	add	a3,a3,a1
    80000db2:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000db4:	0585                	addi	a1,a1,1
    80000db6:	0785                	addi	a5,a5,1
    80000db8:	fff5c703          	lbu	a4,-1(a1)
    80000dbc:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dc0:	fed59ae3          	bne	a1,a3,80000db4 <memmove+0x28>

  return dst;
}
    80000dc4:	6422                	ld	s0,8(sp)
    80000dc6:	0141                	addi	sp,sp,16
    80000dc8:	8082                	ret
    d += n;
    80000dca:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dcc:	fff6069b          	addiw	a3,a2,-1
    80000dd0:	da75                	beqz	a2,80000dc4 <memmove+0x38>
    80000dd2:	02069613          	slli	a2,a3,0x20
    80000dd6:	9201                	srli	a2,a2,0x20
    80000dd8:	fff64613          	not	a2,a2
    80000ddc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dde:	17fd                	addi	a5,a5,-1
    80000de0:	177d                	addi	a4,a4,-1
    80000de2:	0007c683          	lbu	a3,0(a5)
    80000de6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dea:	fef61ae3          	bne	a2,a5,80000dde <memmove+0x52>
    80000dee:	bfd9                	j	80000dc4 <memmove+0x38>

0000000080000df0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000df0:	1141                	addi	sp,sp,-16
    80000df2:	e406                	sd	ra,8(sp)
    80000df4:	e022                	sd	s0,0(sp)
    80000df6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000df8:	00000097          	auipc	ra,0x0
    80000dfc:	f94080e7          	jalr	-108(ra) # 80000d8c <memmove>
}
    80000e00:	60a2                	ld	ra,8(sp)
    80000e02:	6402                	ld	s0,0(sp)
    80000e04:	0141                	addi	sp,sp,16
    80000e06:	8082                	ret

0000000080000e08 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e08:	1141                	addi	sp,sp,-16
    80000e0a:	e422                	sd	s0,8(sp)
    80000e0c:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e0e:	c229                	beqz	a2,80000e50 <strncmp+0x48>
    80000e10:	00054783          	lbu	a5,0(a0)
    80000e14:	c795                	beqz	a5,80000e40 <strncmp+0x38>
    80000e16:	0005c703          	lbu	a4,0(a1)
    80000e1a:	02f71363          	bne	a4,a5,80000e40 <strncmp+0x38>
    80000e1e:	fff6071b          	addiw	a4,a2,-1
    80000e22:	1702                	slli	a4,a4,0x20
    80000e24:	9301                	srli	a4,a4,0x20
    80000e26:	0705                	addi	a4,a4,1
    80000e28:	972a                	add	a4,a4,a0
    n--, p++, q++;
    80000e2a:	0505                	addi	a0,a0,1
    80000e2c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e2e:	02e50363          	beq	a0,a4,80000e54 <strncmp+0x4c>
    80000e32:	00054783          	lbu	a5,0(a0)
    80000e36:	c789                	beqz	a5,80000e40 <strncmp+0x38>
    80000e38:	0005c683          	lbu	a3,0(a1)
    80000e3c:	fef687e3          	beq	a3,a5,80000e2a <strncmp+0x22>
  if(n == 0)
    return 0;
  return (uchar)*p - (uchar)*q;
    80000e40:	00054503          	lbu	a0,0(a0)
    80000e44:	0005c783          	lbu	a5,0(a1)
    80000e48:	9d1d                	subw	a0,a0,a5
}
    80000e4a:	6422                	ld	s0,8(sp)
    80000e4c:	0141                	addi	sp,sp,16
    80000e4e:	8082                	ret
    return 0;
    80000e50:	4501                	li	a0,0
    80000e52:	bfe5                	j	80000e4a <strncmp+0x42>
    80000e54:	4501                	li	a0,0
    80000e56:	bfd5                	j	80000e4a <strncmp+0x42>

0000000080000e58 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e58:	1141                	addi	sp,sp,-16
    80000e5a:	e422                	sd	s0,8(sp)
    80000e5c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e5e:	872a                	mv	a4,a0
    80000e60:	a011                	j	80000e64 <strncpy+0xc>
    80000e62:	8636                	mv	a2,a3
    80000e64:	fff6069b          	addiw	a3,a2,-1
    80000e68:	00c05963          	blez	a2,80000e7a <strncpy+0x22>
    80000e6c:	0705                	addi	a4,a4,1
    80000e6e:	0005c783          	lbu	a5,0(a1)
    80000e72:	fef70fa3          	sb	a5,-1(a4)
    80000e76:	0585                	addi	a1,a1,1
    80000e78:	f7ed                	bnez	a5,80000e62 <strncpy+0xa>
    ;
  while(n-- > 0)
    80000e7a:	00d05c63          	blez	a3,80000e92 <strncpy+0x3a>
    80000e7e:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e80:	0685                	addi	a3,a3,1
    80000e82:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e86:	fff6c793          	not	a5,a3
    80000e8a:	9fb9                	addw	a5,a5,a4
    80000e8c:	9fb1                	addw	a5,a5,a2
    80000e8e:	fef049e3          	bgtz	a5,80000e80 <strncpy+0x28>
  return os;
}
    80000e92:	6422                	ld	s0,8(sp)
    80000e94:	0141                	addi	sp,sp,16
    80000e96:	8082                	ret

0000000080000e98 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e98:	1141                	addi	sp,sp,-16
    80000e9a:	e422                	sd	s0,8(sp)
    80000e9c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e9e:	02c05363          	blez	a2,80000ec4 <safestrcpy+0x2c>
    80000ea2:	fff6069b          	addiw	a3,a2,-1
    80000ea6:	1682                	slli	a3,a3,0x20
    80000ea8:	9281                	srli	a3,a3,0x20
    80000eaa:	96ae                	add	a3,a3,a1
    80000eac:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000eae:	00d58963          	beq	a1,a3,80000ec0 <safestrcpy+0x28>
    80000eb2:	0585                	addi	a1,a1,1
    80000eb4:	0785                	addi	a5,a5,1
    80000eb6:	fff5c703          	lbu	a4,-1(a1)
    80000eba:	fee78fa3          	sb	a4,-1(a5)
    80000ebe:	fb65                	bnez	a4,80000eae <safestrcpy+0x16>
    ;
  *s = 0;
    80000ec0:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ec4:	6422                	ld	s0,8(sp)
    80000ec6:	0141                	addi	sp,sp,16
    80000ec8:	8082                	ret

0000000080000eca <strlen>:

int
strlen(const char *s)
{
    80000eca:	1141                	addi	sp,sp,-16
    80000ecc:	e422                	sd	s0,8(sp)
    80000ece:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ed0:	00054783          	lbu	a5,0(a0)
    80000ed4:	cf91                	beqz	a5,80000ef0 <strlen+0x26>
    80000ed6:	0505                	addi	a0,a0,1
    80000ed8:	87aa                	mv	a5,a0
    80000eda:	4685                	li	a3,1
    80000edc:	9e89                	subw	a3,a3,a0
    80000ede:	00f6853b          	addw	a0,a3,a5
    80000ee2:	0785                	addi	a5,a5,1
    80000ee4:	fff7c703          	lbu	a4,-1(a5)
    80000ee8:	fb7d                	bnez	a4,80000ede <strlen+0x14>
    ;
  return n;
}
    80000eea:	6422                	ld	s0,8(sp)
    80000eec:	0141                	addi	sp,sp,16
    80000eee:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ef0:	4501                	li	a0,0
    80000ef2:	bfe5                	j	80000eea <strlen+0x20>

0000000080000ef4 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ef4:	1141                	addi	sp,sp,-16
    80000ef6:	e406                	sd	ra,8(sp)
    80000ef8:	e022                	sd	s0,0(sp)
    80000efa:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000efc:	00001097          	auipc	ra,0x1
    80000f00:	b16080e7          	jalr	-1258(ra) # 80001a12 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f04:	00008717          	auipc	a4,0x8
    80000f08:	11470713          	addi	a4,a4,276 # 80009018 <started>
  if(cpuid() == 0){
    80000f0c:	c139                	beqz	a0,80000f52 <main+0x5e>
    while(started == 0)
    80000f0e:	431c                	lw	a5,0(a4)
    80000f10:	2781                	sext.w	a5,a5
    80000f12:	dff5                	beqz	a5,80000f0e <main+0x1a>
      ;
    __sync_synchronize();
    80000f14:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f18:	00001097          	auipc	ra,0x1
    80000f1c:	afa080e7          	jalr	-1286(ra) # 80001a12 <cpuid>
    80000f20:	85aa                	mv	a1,a0
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	19650513          	addi	a0,a0,406 # 800080b8 <digits+0xa0>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	678080e7          	jalr	1656(ra) # 800005a2 <printf>
    kvminithart();    // turn on paging
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	0d8080e7          	jalr	216(ra) # 8000100a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	7d6080e7          	jalr	2006(ra) # 80002710 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f42:	00005097          	auipc	ra,0x5
    80000f46:	37e080e7          	jalr	894(ra) # 800062c0 <plicinithart>
  }

  scheduler();        
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	076080e7          	jalr	118(ra) # 80001fc0 <scheduler>
    consoleinit();
    80000f52:	fffff097          	auipc	ra,0xfffff
    80000f56:	514080e7          	jalr	1300(ra) # 80000466 <consoleinit>
    printfinit();
    80000f5a:	00000097          	auipc	ra,0x0
    80000f5e:	82e080e7          	jalr	-2002(ra) # 80000788 <printfinit>
    printf("\n");
    80000f62:	00007517          	auipc	a0,0x7
    80000f66:	16650513          	addi	a0,a0,358 # 800080c8 <digits+0xb0>
    80000f6a:	fffff097          	auipc	ra,0xfffff
    80000f6e:	638080e7          	jalr	1592(ra) # 800005a2 <printf>
    printf("xv6 kernel is booting\n");
    80000f72:	00007517          	auipc	a0,0x7
    80000f76:	12e50513          	addi	a0,a0,302 # 800080a0 <digits+0x88>
    80000f7a:	fffff097          	auipc	ra,0xfffff
    80000f7e:	628080e7          	jalr	1576(ra) # 800005a2 <printf>
    printf("\n");
    80000f82:	00007517          	auipc	a0,0x7
    80000f86:	14650513          	addi	a0,a0,326 # 800080c8 <digits+0xb0>
    80000f8a:	fffff097          	auipc	ra,0xfffff
    80000f8e:	618080e7          	jalr	1560(ra) # 800005a2 <printf>
    kinit();         // physical page allocator
    80000f92:	00000097          	auipc	ra,0x0
    80000f96:	b66080e7          	jalr	-1178(ra) # 80000af8 <kinit>
    kvminit();       // create kernel page table
    80000f9a:	00000097          	auipc	ra,0x0
    80000f9e:	310080e7          	jalr	784(ra) # 800012aa <kvminit>
    kvminithart();   // turn on paging
    80000fa2:	00000097          	auipc	ra,0x0
    80000fa6:	068080e7          	jalr	104(ra) # 8000100a <kvminithart>
    procinit();      // process table
    80000faa:	00001097          	auipc	ra,0x1
    80000fae:	9be080e7          	jalr	-1602(ra) # 80001968 <procinit>
    trapinit();      // trap vectors
    80000fb2:	00001097          	auipc	ra,0x1
    80000fb6:	736080e7          	jalr	1846(ra) # 800026e8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fba:	00001097          	auipc	ra,0x1
    80000fbe:	756080e7          	jalr	1878(ra) # 80002710 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fc2:	00005097          	auipc	ra,0x5
    80000fc6:	2e8080e7          	jalr	744(ra) # 800062aa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fca:	00005097          	auipc	ra,0x5
    80000fce:	2f6080e7          	jalr	758(ra) # 800062c0 <plicinithart>
    binit();         // buffer cache
    80000fd2:	00002097          	auipc	ra,0x2
    80000fd6:	ec0080e7          	jalr	-320(ra) # 80002e92 <binit>
    iinit();         // inode cache
    80000fda:	00002097          	auipc	ra,0x2
    80000fde:	592080e7          	jalr	1426(ra) # 8000356c <iinit>
    fileinit();      // file table
    80000fe2:	00003097          	auipc	ra,0x3
    80000fe6:	570080e7          	jalr	1392(ra) # 80004552 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fea:	00005097          	auipc	ra,0x5
    80000fee:	3f8080e7          	jalr	1016(ra) # 800063e2 <virtio_disk_init>
    userinit();      // first user process
    80000ff2:	00001097          	auipc	ra,0x1
    80000ff6:	d18080e7          	jalr	-744(ra) # 80001d0a <userinit>
    __sync_synchronize();
    80000ffa:	0ff0000f          	fence
    started = 1;
    80000ffe:	4785                	li	a5,1
    80001000:	00008717          	auipc	a4,0x8
    80001004:	00f72c23          	sw	a5,24(a4) # 80009018 <started>
    80001008:	b789                	j	80000f4a <main+0x56>

000000008000100a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000100a:	1141                	addi	sp,sp,-16
    8000100c:	e422                	sd	s0,8(sp)
    8000100e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001010:	00008797          	auipc	a5,0x8
    80001014:	01078793          	addi	a5,a5,16 # 80009020 <kernel_pagetable>
    80001018:	639c                	ld	a5,0(a5)
    8000101a:	83b1                	srli	a5,a5,0xc
    8000101c:	577d                	li	a4,-1
    8000101e:	177e                	slli	a4,a4,0x3f
    80001020:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001022:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001026:	12000073          	sfence.vma
  sfence_vma();
}
    8000102a:	6422                	ld	s0,8(sp)
    8000102c:	0141                	addi	sp,sp,16
    8000102e:	8082                	ret

0000000080001030 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001030:	7139                	addi	sp,sp,-64
    80001032:	fc06                	sd	ra,56(sp)
    80001034:	f822                	sd	s0,48(sp)
    80001036:	f426                	sd	s1,40(sp)
    80001038:	f04a                	sd	s2,32(sp)
    8000103a:	ec4e                	sd	s3,24(sp)
    8000103c:	e852                	sd	s4,16(sp)
    8000103e:	e456                	sd	s5,8(sp)
    80001040:	e05a                	sd	s6,0(sp)
    80001042:	0080                	addi	s0,sp,64
    80001044:	84aa                	mv	s1,a0
    80001046:	89ae                	mv	s3,a1
    80001048:	8b32                	mv	s6,a2
  if(va >= MAXVA)
    8000104a:	57fd                	li	a5,-1
    8000104c:	83e9                	srli	a5,a5,0x1a
    8000104e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001050:	4ab1                	li	s5,12
  if(va >= MAXVA)
    80001052:	04b7f263          	bleu	a1,a5,80001096 <walk+0x66>
    panic("walk");
    80001056:	00007517          	auipc	a0,0x7
    8000105a:	07a50513          	addi	a0,a0,122 # 800080d0 <digits+0xb8>
    8000105e:	fffff097          	auipc	ra,0xfffff
    80001062:	4fa080e7          	jalr	1274(ra) # 80000558 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001066:	060b0663          	beqz	s6,800010d2 <walk+0xa2>
    8000106a:	00000097          	auipc	ra,0x0
    8000106e:	aca080e7          	jalr	-1334(ra) # 80000b34 <kalloc>
    80001072:	84aa                	mv	s1,a0
    80001074:	c529                	beqz	a0,800010be <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001076:	6605                	lui	a2,0x1
    80001078:	4581                	li	a1,0
    8000107a:	00000097          	auipc	ra,0x0
    8000107e:	ca6080e7          	jalr	-858(ra) # 80000d20 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001082:	00c4d793          	srli	a5,s1,0xc
    80001086:	07aa                	slli	a5,a5,0xa
    80001088:	0017e793          	ori	a5,a5,1
    8000108c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001090:	3a5d                	addiw	s4,s4,-9
    80001092:	035a0063          	beq	s4,s5,800010b2 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001096:	0149d933          	srl	s2,s3,s4
    8000109a:	1ff97913          	andi	s2,s2,511
    8000109e:	090e                	slli	s2,s2,0x3
    800010a0:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010a2:	00093483          	ld	s1,0(s2)
    800010a6:	0014f793          	andi	a5,s1,1
    800010aa:	dfd5                	beqz	a5,80001066 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010ac:	80a9                	srli	s1,s1,0xa
    800010ae:	04b2                	slli	s1,s1,0xc
    800010b0:	b7c5                	j	80001090 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010b2:	00c9d513          	srli	a0,s3,0xc
    800010b6:	1ff57513          	andi	a0,a0,511
    800010ba:	050e                	slli	a0,a0,0x3
    800010bc:	9526                	add	a0,a0,s1
}
    800010be:	70e2                	ld	ra,56(sp)
    800010c0:	7442                	ld	s0,48(sp)
    800010c2:	74a2                	ld	s1,40(sp)
    800010c4:	7902                	ld	s2,32(sp)
    800010c6:	69e2                	ld	s3,24(sp)
    800010c8:	6a42                	ld	s4,16(sp)
    800010ca:	6aa2                	ld	s5,8(sp)
    800010cc:	6b02                	ld	s6,0(sp)
    800010ce:	6121                	addi	sp,sp,64
    800010d0:	8082                	ret
        return 0;
    800010d2:	4501                	li	a0,0
    800010d4:	b7ed                	j	800010be <walk+0x8e>

00000000800010d6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010d6:	57fd                	li	a5,-1
    800010d8:	83e9                	srli	a5,a5,0x1a
    800010da:	00b7f463          	bleu	a1,a5,800010e2 <walkaddr+0xc>
    return 0;
    800010de:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010e0:	8082                	ret
{
    800010e2:	1141                	addi	sp,sp,-16
    800010e4:	e406                	sd	ra,8(sp)
    800010e6:	e022                	sd	s0,0(sp)
    800010e8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ea:	4601                	li	a2,0
    800010ec:	00000097          	auipc	ra,0x0
    800010f0:	f44080e7          	jalr	-188(ra) # 80001030 <walk>
  if(pte == 0)
    800010f4:	c105                	beqz	a0,80001114 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010f6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010f8:	0117f693          	andi	a3,a5,17
    800010fc:	4745                	li	a4,17
    return 0;
    800010fe:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001100:	00e68663          	beq	a3,a4,8000110c <walkaddr+0x36>
}
    80001104:	60a2                	ld	ra,8(sp)
    80001106:	6402                	ld	s0,0(sp)
    80001108:	0141                	addi	sp,sp,16
    8000110a:	8082                	ret
  pa = PTE2PA(*pte);
    8000110c:	00a7d513          	srli	a0,a5,0xa
    80001110:	0532                	slli	a0,a0,0xc
  return pa;
    80001112:	bfcd                	j	80001104 <walkaddr+0x2e>
    return 0;
    80001114:	4501                	li	a0,0
    80001116:	b7fd                	j	80001104 <walkaddr+0x2e>

0000000080001118 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001118:	715d                	addi	sp,sp,-80
    8000111a:	e486                	sd	ra,72(sp)
    8000111c:	e0a2                	sd	s0,64(sp)
    8000111e:	fc26                	sd	s1,56(sp)
    80001120:	f84a                	sd	s2,48(sp)
    80001122:	f44e                	sd	s3,40(sp)
    80001124:	f052                	sd	s4,32(sp)
    80001126:	ec56                	sd	s5,24(sp)
    80001128:	e85a                	sd	s6,16(sp)
    8000112a:	e45e                	sd	s7,8(sp)
    8000112c:	0880                	addi	s0,sp,80
    8000112e:	8aaa                	mv	s5,a0
    80001130:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001132:	79fd                	lui	s3,0xfffff
    80001134:	0135fa33          	and	s4,a1,s3
  last = PGROUNDDOWN(va + size - 1);
    80001138:	167d                	addi	a2,a2,-1
    8000113a:	962e                	add	a2,a2,a1
    8000113c:	013679b3          	and	s3,a2,s3
  a = PGROUNDDOWN(va);
    80001140:	8952                	mv	s2,s4
    80001142:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001146:	6b85                	lui	s7,0x1
    80001148:	a811                	j	8000115c <mappages+0x44>
      panic("remap");
    8000114a:	00007517          	auipc	a0,0x7
    8000114e:	f8e50513          	addi	a0,a0,-114 # 800080d8 <digits+0xc0>
    80001152:	fffff097          	auipc	ra,0xfffff
    80001156:	406080e7          	jalr	1030(ra) # 80000558 <panic>
    a += PGSIZE;
    8000115a:	995e                	add	s2,s2,s7
  for(;;){
    8000115c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001160:	4605                	li	a2,1
    80001162:	85ca                	mv	a1,s2
    80001164:	8556                	mv	a0,s5
    80001166:	00000097          	auipc	ra,0x0
    8000116a:	eca080e7          	jalr	-310(ra) # 80001030 <walk>
    8000116e:	cd19                	beqz	a0,8000118c <mappages+0x74>
    if(*pte & PTE_V)
    80001170:	611c                	ld	a5,0(a0)
    80001172:	8b85                	andi	a5,a5,1
    80001174:	fbf9                	bnez	a5,8000114a <mappages+0x32>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001176:	80b1                	srli	s1,s1,0xc
    80001178:	04aa                	slli	s1,s1,0xa
    8000117a:	0164e4b3          	or	s1,s1,s6
    8000117e:	0014e493          	ori	s1,s1,1
    80001182:	e104                	sd	s1,0(a0)
    if(a == last)
    80001184:	fd391be3          	bne	s2,s3,8000115a <mappages+0x42>
    pa += PGSIZE;
  }
  return 0;
    80001188:	4501                	li	a0,0
    8000118a:	a011                	j	8000118e <mappages+0x76>
      return -1;
    8000118c:	557d                	li	a0,-1
}
    8000118e:	60a6                	ld	ra,72(sp)
    80001190:	6406                	ld	s0,64(sp)
    80001192:	74e2                	ld	s1,56(sp)
    80001194:	7942                	ld	s2,48(sp)
    80001196:	79a2                	ld	s3,40(sp)
    80001198:	7a02                	ld	s4,32(sp)
    8000119a:	6ae2                	ld	s5,24(sp)
    8000119c:	6b42                	ld	s6,16(sp)
    8000119e:	6ba2                	ld	s7,8(sp)
    800011a0:	6161                	addi	sp,sp,80
    800011a2:	8082                	ret

00000000800011a4 <kvmmap>:
{
    800011a4:	1141                	addi	sp,sp,-16
    800011a6:	e406                	sd	ra,8(sp)
    800011a8:	e022                	sd	s0,0(sp)
    800011aa:	0800                	addi	s0,sp,16
    800011ac:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011ae:	86b2                	mv	a3,a2
    800011b0:	863e                	mv	a2,a5
    800011b2:	00000097          	auipc	ra,0x0
    800011b6:	f66080e7          	jalr	-154(ra) # 80001118 <mappages>
    800011ba:	e509                	bnez	a0,800011c4 <kvmmap+0x20>
}
    800011bc:	60a2                	ld	ra,8(sp)
    800011be:	6402                	ld	s0,0(sp)
    800011c0:	0141                	addi	sp,sp,16
    800011c2:	8082                	ret
    panic("kvmmap");
    800011c4:	00007517          	auipc	a0,0x7
    800011c8:	f1c50513          	addi	a0,a0,-228 # 800080e0 <digits+0xc8>
    800011cc:	fffff097          	auipc	ra,0xfffff
    800011d0:	38c080e7          	jalr	908(ra) # 80000558 <panic>

00000000800011d4 <kvmmake>:
{
    800011d4:	1101                	addi	sp,sp,-32
    800011d6:	ec06                	sd	ra,24(sp)
    800011d8:	e822                	sd	s0,16(sp)
    800011da:	e426                	sd	s1,8(sp)
    800011dc:	e04a                	sd	s2,0(sp)
    800011de:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011e0:	00000097          	auipc	ra,0x0
    800011e4:	954080e7          	jalr	-1708(ra) # 80000b34 <kalloc>
    800011e8:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011ea:	6605                	lui	a2,0x1
    800011ec:	4581                	li	a1,0
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	b32080e7          	jalr	-1230(ra) # 80000d20 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	6685                	lui	a3,0x1
    800011fa:	10000637          	lui	a2,0x10000
    800011fe:	100005b7          	lui	a1,0x10000
    80001202:	8526                	mv	a0,s1
    80001204:	00000097          	auipc	ra,0x0
    80001208:	fa0080e7          	jalr	-96(ra) # 800011a4 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000120c:	4719                	li	a4,6
    8000120e:	6685                	lui	a3,0x1
    80001210:	10001637          	lui	a2,0x10001
    80001214:	100015b7          	lui	a1,0x10001
    80001218:	8526                	mv	a0,s1
    8000121a:	00000097          	auipc	ra,0x0
    8000121e:	f8a080e7          	jalr	-118(ra) # 800011a4 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001222:	4719                	li	a4,6
    80001224:	004006b7          	lui	a3,0x400
    80001228:	0c000637          	lui	a2,0xc000
    8000122c:	0c0005b7          	lui	a1,0xc000
    80001230:	8526                	mv	a0,s1
    80001232:	00000097          	auipc	ra,0x0
    80001236:	f72080e7          	jalr	-142(ra) # 800011a4 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000123a:	00007917          	auipc	s2,0x7
    8000123e:	dc690913          	addi	s2,s2,-570 # 80008000 <etext>
    80001242:	4729                	li	a4,10
    80001244:	80007697          	auipc	a3,0x80007
    80001248:	dbc68693          	addi	a3,a3,-580 # 8000 <_entry-0x7fff8000>
    8000124c:	4605                	li	a2,1
    8000124e:	067e                	slli	a2,a2,0x1f
    80001250:	85b2                	mv	a1,a2
    80001252:	8526                	mv	a0,s1
    80001254:	00000097          	auipc	ra,0x0
    80001258:	f50080e7          	jalr	-176(ra) # 800011a4 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000125c:	4719                	li	a4,6
    8000125e:	46c5                	li	a3,17
    80001260:	06ee                	slli	a3,a3,0x1b
    80001262:	412686b3          	sub	a3,a3,s2
    80001266:	864a                	mv	a2,s2
    80001268:	85ca                	mv	a1,s2
    8000126a:	8526                	mv	a0,s1
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	f38080e7          	jalr	-200(ra) # 800011a4 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001274:	4729                	li	a4,10
    80001276:	6685                	lui	a3,0x1
    80001278:	00006617          	auipc	a2,0x6
    8000127c:	d8860613          	addi	a2,a2,-632 # 80007000 <_trampoline>
    80001280:	040005b7          	lui	a1,0x4000
    80001284:	15fd                	addi	a1,a1,-1
    80001286:	05b2                	slli	a1,a1,0xc
    80001288:	8526                	mv	a0,s1
    8000128a:	00000097          	auipc	ra,0x0
    8000128e:	f1a080e7          	jalr	-230(ra) # 800011a4 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001292:	8526                	mv	a0,s1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	63e080e7          	jalr	1598(ra) # 800018d2 <proc_mapstacks>
}
    8000129c:	8526                	mv	a0,s1
    8000129e:	60e2                	ld	ra,24(sp)
    800012a0:	6442                	ld	s0,16(sp)
    800012a2:	64a2                	ld	s1,8(sp)
    800012a4:	6902                	ld	s2,0(sp)
    800012a6:	6105                	addi	sp,sp,32
    800012a8:	8082                	ret

00000000800012aa <kvminit>:
{
    800012aa:	1141                	addi	sp,sp,-16
    800012ac:	e406                	sd	ra,8(sp)
    800012ae:	e022                	sd	s0,0(sp)
    800012b0:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012b2:	00000097          	auipc	ra,0x0
    800012b6:	f22080e7          	jalr	-222(ra) # 800011d4 <kvmmake>
    800012ba:	00008797          	auipc	a5,0x8
    800012be:	d6a7b323          	sd	a0,-666(a5) # 80009020 <kernel_pagetable>
}
    800012c2:	60a2                	ld	ra,8(sp)
    800012c4:	6402                	ld	s0,0(sp)
    800012c6:	0141                	addi	sp,sp,16
    800012c8:	8082                	ret

00000000800012ca <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ca:	715d                	addi	sp,sp,-80
    800012cc:	e486                	sd	ra,72(sp)
    800012ce:	e0a2                	sd	s0,64(sp)
    800012d0:	fc26                	sd	s1,56(sp)
    800012d2:	f84a                	sd	s2,48(sp)
    800012d4:	f44e                	sd	s3,40(sp)
    800012d6:	f052                	sd	s4,32(sp)
    800012d8:	ec56                	sd	s5,24(sp)
    800012da:	e85a                	sd	s6,16(sp)
    800012dc:	e45e                	sd	s7,8(sp)
    800012de:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012e0:	6785                	lui	a5,0x1
    800012e2:	17fd                	addi	a5,a5,-1
    800012e4:	8fed                	and	a5,a5,a1
    800012e6:	e795                	bnez	a5,80001312 <uvmunmap+0x48>
    800012e8:	8a2a                	mv	s4,a0
    800012ea:	84ae                	mv	s1,a1
    800012ec:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	0632                	slli	a2,a2,0xc
    800012f0:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      continue; //panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012f4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f6:	6b05                	lui	s6,0x1
    800012f8:	0735e063          	bltu	a1,s3,80001358 <uvmunmap+0x8e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012fc:	60a6                	ld	ra,72(sp)
    800012fe:	6406                	ld	s0,64(sp)
    80001300:	74e2                	ld	s1,56(sp)
    80001302:	7942                	ld	s2,48(sp)
    80001304:	79a2                	ld	s3,40(sp)
    80001306:	7a02                	ld	s4,32(sp)
    80001308:	6ae2                	ld	s5,24(sp)
    8000130a:	6b42                	ld	s6,16(sp)
    8000130c:	6ba2                	ld	s7,8(sp)
    8000130e:	6161                	addi	sp,sp,80
    80001310:	8082                	ret
    panic("uvmunmap: not aligned");
    80001312:	00007517          	auipc	a0,0x7
    80001316:	dd650513          	addi	a0,a0,-554 # 800080e8 <digits+0xd0>
    8000131a:	fffff097          	auipc	ra,0xfffff
    8000131e:	23e080e7          	jalr	574(ra) # 80000558 <panic>
      panic("uvmunmap: walk");
    80001322:	00007517          	auipc	a0,0x7
    80001326:	dde50513          	addi	a0,a0,-546 # 80008100 <digits+0xe8>
    8000132a:	fffff097          	auipc	ra,0xfffff
    8000132e:	22e080e7          	jalr	558(ra) # 80000558 <panic>
      panic("uvmunmap: not a leaf");
    80001332:	00007517          	auipc	a0,0x7
    80001336:	dde50513          	addi	a0,a0,-546 # 80008110 <digits+0xf8>
    8000133a:	fffff097          	auipc	ra,0xfffff
    8000133e:	21e080e7          	jalr	542(ra) # 80000558 <panic>
      uint64 pa = PTE2PA(*pte);
    80001342:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001344:	0532                	slli	a0,a0,0xc
    80001346:	fffff097          	auipc	ra,0xfffff
    8000134a:	6ee080e7          	jalr	1774(ra) # 80000a34 <kfree>
    *pte = 0;
    8000134e:	00093023          	sd	zero,0(s2)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001352:	94da                	add	s1,s1,s6
    80001354:	fb34f4e3          	bleu	s3,s1,800012fc <uvmunmap+0x32>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001358:	4601                	li	a2,0
    8000135a:	85a6                	mv	a1,s1
    8000135c:	8552                	mv	a0,s4
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	cd2080e7          	jalr	-814(ra) # 80001030 <walk>
    80001366:	892a                	mv	s2,a0
    80001368:	dd4d                	beqz	a0,80001322 <uvmunmap+0x58>
    if((*pte & PTE_V) == 0)
    8000136a:	6108                	ld	a0,0(a0)
    8000136c:	00157793          	andi	a5,a0,1
    80001370:	d3ed                	beqz	a5,80001352 <uvmunmap+0x88>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001372:	3ff57793          	andi	a5,a0,1023
    80001376:	fb778ee3          	beq	a5,s7,80001332 <uvmunmap+0x68>
    if(do_free){
    8000137a:	fc0a8ae3          	beqz	s5,8000134e <uvmunmap+0x84>
    8000137e:	b7d1                	j	80001342 <uvmunmap+0x78>

0000000080001380 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001380:	1101                	addi	sp,sp,-32
    80001382:	ec06                	sd	ra,24(sp)
    80001384:	e822                	sd	s0,16(sp)
    80001386:	e426                	sd	s1,8(sp)
    80001388:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000138a:	fffff097          	auipc	ra,0xfffff
    8000138e:	7aa080e7          	jalr	1962(ra) # 80000b34 <kalloc>
    80001392:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001394:	c519                	beqz	a0,800013a2 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001396:	6605                	lui	a2,0x1
    80001398:	4581                	li	a1,0
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	986080e7          	jalr	-1658(ra) # 80000d20 <memset>
  return pagetable;
}
    800013a2:	8526                	mv	a0,s1
    800013a4:	60e2                	ld	ra,24(sp)
    800013a6:	6442                	ld	s0,16(sp)
    800013a8:	64a2                	ld	s1,8(sp)
    800013aa:	6105                	addi	sp,sp,32
    800013ac:	8082                	ret

00000000800013ae <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ae:	7179                	addi	sp,sp,-48
    800013b0:	f406                	sd	ra,40(sp)
    800013b2:	f022                	sd	s0,32(sp)
    800013b4:	ec26                	sd	s1,24(sp)
    800013b6:	e84a                	sd	s2,16(sp)
    800013b8:	e44e                	sd	s3,8(sp)
    800013ba:	e052                	sd	s4,0(sp)
    800013bc:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013be:	6785                	lui	a5,0x1
    800013c0:	04f67863          	bleu	a5,a2,80001410 <uvminit+0x62>
    800013c4:	8a2a                	mv	s4,a0
    800013c6:	89ae                	mv	s3,a1
    800013c8:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013ca:	fffff097          	auipc	ra,0xfffff
    800013ce:	76a080e7          	jalr	1898(ra) # 80000b34 <kalloc>
    800013d2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013d4:	6605                	lui	a2,0x1
    800013d6:	4581                	li	a1,0
    800013d8:	00000097          	auipc	ra,0x0
    800013dc:	948080e7          	jalr	-1720(ra) # 80000d20 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013e0:	4779                	li	a4,30
    800013e2:	86ca                	mv	a3,s2
    800013e4:	6605                	lui	a2,0x1
    800013e6:	4581                	li	a1,0
    800013e8:	8552                	mv	a0,s4
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	d2e080e7          	jalr	-722(ra) # 80001118 <mappages>
  memmove(mem, src, sz);
    800013f2:	8626                	mv	a2,s1
    800013f4:	85ce                	mv	a1,s3
    800013f6:	854a                	mv	a0,s2
    800013f8:	00000097          	auipc	ra,0x0
    800013fc:	994080e7          	jalr	-1644(ra) # 80000d8c <memmove>
}
    80001400:	70a2                	ld	ra,40(sp)
    80001402:	7402                	ld	s0,32(sp)
    80001404:	64e2                	ld	s1,24(sp)
    80001406:	6942                	ld	s2,16(sp)
    80001408:	69a2                	ld	s3,8(sp)
    8000140a:	6a02                	ld	s4,0(sp)
    8000140c:	6145                	addi	sp,sp,48
    8000140e:	8082                	ret
    panic("inituvm: more than a page");
    80001410:	00007517          	auipc	a0,0x7
    80001414:	d1850513          	addi	a0,a0,-744 # 80008128 <digits+0x110>
    80001418:	fffff097          	auipc	ra,0xfffff
    8000141c:	140080e7          	jalr	320(ra) # 80000558 <panic>

0000000080001420 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001420:	1101                	addi	sp,sp,-32
    80001422:	ec06                	sd	ra,24(sp)
    80001424:	e822                	sd	s0,16(sp)
    80001426:	e426                	sd	s1,8(sp)
    80001428:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000142a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000142c:	00b67d63          	bleu	a1,a2,80001446 <uvmdealloc+0x26>
    80001430:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001432:	6605                	lui	a2,0x1
    80001434:	167d                	addi	a2,a2,-1
    80001436:	00c487b3          	add	a5,s1,a2
    8000143a:	777d                	lui	a4,0xfffff
    8000143c:	8ff9                	and	a5,a5,a4
    8000143e:	962e                	add	a2,a2,a1
    80001440:	8e79                	and	a2,a2,a4
    80001442:	00c7e863          	bltu	a5,a2,80001452 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001446:	8526                	mv	a0,s1
    80001448:	60e2                	ld	ra,24(sp)
    8000144a:	6442                	ld	s0,16(sp)
    8000144c:	64a2                	ld	s1,8(sp)
    8000144e:	6105                	addi	sp,sp,32
    80001450:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001452:	8e1d                	sub	a2,a2,a5
    80001454:	8231                	srli	a2,a2,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001456:	4685                	li	a3,1
    80001458:	2601                	sext.w	a2,a2
    8000145a:	85be                	mv	a1,a5
    8000145c:	00000097          	auipc	ra,0x0
    80001460:	e6e080e7          	jalr	-402(ra) # 800012ca <uvmunmap>
    80001464:	b7cd                	j	80001446 <uvmdealloc+0x26>

0000000080001466 <uvmalloc>:
  if(newsz < oldsz)
    80001466:	0ab66163          	bltu	a2,a1,80001508 <uvmalloc+0xa2>
{
    8000146a:	7139                	addi	sp,sp,-64
    8000146c:	fc06                	sd	ra,56(sp)
    8000146e:	f822                	sd	s0,48(sp)
    80001470:	f426                	sd	s1,40(sp)
    80001472:	f04a                	sd	s2,32(sp)
    80001474:	ec4e                	sd	s3,24(sp)
    80001476:	e852                	sd	s4,16(sp)
    80001478:	e456                	sd	s5,8(sp)
    8000147a:	0080                	addi	s0,sp,64
  oldsz = PGROUNDUP(oldsz);
    8000147c:	6a05                	lui	s4,0x1
    8000147e:	1a7d                	addi	s4,s4,-1
    80001480:	95d2                	add	a1,a1,s4
    80001482:	7a7d                	lui	s4,0xfffff
    80001484:	0145fa33          	and	s4,a1,s4
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001488:	08ca7263          	bleu	a2,s4,8000150c <uvmalloc+0xa6>
    8000148c:	89b2                	mv	s3,a2
    8000148e:	8aaa                	mv	s5,a0
    80001490:	8952                	mv	s2,s4
    mem = kalloc();
    80001492:	fffff097          	auipc	ra,0xfffff
    80001496:	6a2080e7          	jalr	1698(ra) # 80000b34 <kalloc>
    8000149a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000149c:	c51d                	beqz	a0,800014ca <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000149e:	6605                	lui	a2,0x1
    800014a0:	4581                	li	a1,0
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	87e080e7          	jalr	-1922(ra) # 80000d20 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014aa:	4779                	li	a4,30
    800014ac:	86a6                	mv	a3,s1
    800014ae:	6605                	lui	a2,0x1
    800014b0:	85ca                	mv	a1,s2
    800014b2:	8556                	mv	a0,s5
    800014b4:	00000097          	auipc	ra,0x0
    800014b8:	c64080e7          	jalr	-924(ra) # 80001118 <mappages>
    800014bc:	e905                	bnez	a0,800014ec <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014be:	6785                	lui	a5,0x1
    800014c0:	993e                	add	s2,s2,a5
    800014c2:	fd3968e3          	bltu	s2,s3,80001492 <uvmalloc+0x2c>
  return newsz;
    800014c6:	854e                	mv	a0,s3
    800014c8:	a809                	j	800014da <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014ca:	8652                	mv	a2,s4
    800014cc:	85ca                	mv	a1,s2
    800014ce:	8556                	mv	a0,s5
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	f50080e7          	jalr	-176(ra) # 80001420 <uvmdealloc>
      return 0;
    800014d8:	4501                	li	a0,0
}
    800014da:	70e2                	ld	ra,56(sp)
    800014dc:	7442                	ld	s0,48(sp)
    800014de:	74a2                	ld	s1,40(sp)
    800014e0:	7902                	ld	s2,32(sp)
    800014e2:	69e2                	ld	s3,24(sp)
    800014e4:	6a42                	ld	s4,16(sp)
    800014e6:	6aa2                	ld	s5,8(sp)
    800014e8:	6121                	addi	sp,sp,64
    800014ea:	8082                	ret
      kfree(mem);
    800014ec:	8526                	mv	a0,s1
    800014ee:	fffff097          	auipc	ra,0xfffff
    800014f2:	546080e7          	jalr	1350(ra) # 80000a34 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014f6:	8652                	mv	a2,s4
    800014f8:	85ca                	mv	a1,s2
    800014fa:	8556                	mv	a0,s5
    800014fc:	00000097          	auipc	ra,0x0
    80001500:	f24080e7          	jalr	-220(ra) # 80001420 <uvmdealloc>
      return 0;
    80001504:	4501                	li	a0,0
    80001506:	bfd1                	j	800014da <uvmalloc+0x74>
    return oldsz;
    80001508:	852e                	mv	a0,a1
}
    8000150a:	8082                	ret
  return newsz;
    8000150c:	8532                	mv	a0,a2
    8000150e:	b7f1                	j	800014da <uvmalloc+0x74>

0000000080001510 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001510:	7179                	addi	sp,sp,-48
    80001512:	f406                	sd	ra,40(sp)
    80001514:	f022                	sd	s0,32(sp)
    80001516:	ec26                	sd	s1,24(sp)
    80001518:	e84a                	sd	s2,16(sp)
    8000151a:	e44e                	sd	s3,8(sp)
    8000151c:	e052                	sd	s4,0(sp)
    8000151e:	1800                	addi	s0,sp,48
    80001520:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001522:	84aa                	mv	s1,a0
    80001524:	6905                	lui	s2,0x1
    80001526:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001528:	4985                	li	s3,1
    8000152a:	a821                	j	80001542 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000152c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000152e:	0532                	slli	a0,a0,0xc
    80001530:	00000097          	auipc	ra,0x0
    80001534:	fe0080e7          	jalr	-32(ra) # 80001510 <freewalk>
      pagetable[i] = 0;
    80001538:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000153c:	04a1                	addi	s1,s1,8
    8000153e:	03248163          	beq	s1,s2,80001560 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001542:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001544:	00f57793          	andi	a5,a0,15
    80001548:	ff3782e3          	beq	a5,s3,8000152c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000154c:	8905                	andi	a0,a0,1
    8000154e:	d57d                	beqz	a0,8000153c <freewalk+0x2c>
      panic("freewalk: leaf");
    80001550:	00007517          	auipc	a0,0x7
    80001554:	bf850513          	addi	a0,a0,-1032 # 80008148 <digits+0x130>
    80001558:	fffff097          	auipc	ra,0xfffff
    8000155c:	000080e7          	jalr	ra # 80000558 <panic>
    }
  }
  kfree((void*)pagetable);
    80001560:	8552                	mv	a0,s4
    80001562:	fffff097          	auipc	ra,0xfffff
    80001566:	4d2080e7          	jalr	1234(ra) # 80000a34 <kfree>
}
    8000156a:	70a2                	ld	ra,40(sp)
    8000156c:	7402                	ld	s0,32(sp)
    8000156e:	64e2                	ld	s1,24(sp)
    80001570:	6942                	ld	s2,16(sp)
    80001572:	69a2                	ld	s3,8(sp)
    80001574:	6a02                	ld	s4,0(sp)
    80001576:	6145                	addi	sp,sp,48
    80001578:	8082                	ret

000000008000157a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000157a:	1101                	addi	sp,sp,-32
    8000157c:	ec06                	sd	ra,24(sp)
    8000157e:	e822                	sd	s0,16(sp)
    80001580:	e426                	sd	s1,8(sp)
    80001582:	1000                	addi	s0,sp,32
    80001584:	84aa                	mv	s1,a0
  if(sz > 0)
    80001586:	e999                	bnez	a1,8000159c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001588:	8526                	mv	a0,s1
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	f86080e7          	jalr	-122(ra) # 80001510 <freewalk>
}
    80001592:	60e2                	ld	ra,24(sp)
    80001594:	6442                	ld	s0,16(sp)
    80001596:	64a2                	ld	s1,8(sp)
    80001598:	6105                	addi	sp,sp,32
    8000159a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000159c:	6605                	lui	a2,0x1
    8000159e:	167d                	addi	a2,a2,-1
    800015a0:	962e                	add	a2,a2,a1
    800015a2:	4685                	li	a3,1
    800015a4:	8231                	srli	a2,a2,0xc
    800015a6:	4581                	li	a1,0
    800015a8:	00000097          	auipc	ra,0x0
    800015ac:	d22080e7          	jalr	-734(ra) # 800012ca <uvmunmap>
    800015b0:	bfe1                	j	80001588 <uvmfree+0xe>

00000000800015b2 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015b2:	c269                	beqz	a2,80001674 <uvmcopy+0xc2>
{
    800015b4:	715d                	addi	sp,sp,-80
    800015b6:	e486                	sd	ra,72(sp)
    800015b8:	e0a2                	sd	s0,64(sp)
    800015ba:	fc26                	sd	s1,56(sp)
    800015bc:	f84a                	sd	s2,48(sp)
    800015be:	f44e                	sd	s3,40(sp)
    800015c0:	f052                	sd	s4,32(sp)
    800015c2:	ec56                	sd	s5,24(sp)
    800015c4:	e85a                	sd	s6,16(sp)
    800015c6:	e45e                	sd	s7,8(sp)
    800015c8:	0880                	addi	s0,sp,80
    800015ca:	8ab2                	mv	s5,a2
    800015cc:	8bae                	mv	s7,a1
    800015ce:	8b2a                	mv	s6,a0
  for(i = 0; i < sz; i += PGSIZE){
    800015d0:	4481                	li	s1,0
    800015d2:	a829                	j	800015ec <uvmcopy+0x3a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800015d4:	00007517          	auipc	a0,0x7
    800015d8:	b8450513          	addi	a0,a0,-1148 # 80008158 <digits+0x140>
    800015dc:	fffff097          	auipc	ra,0xfffff
    800015e0:	f7c080e7          	jalr	-132(ra) # 80000558 <panic>
  for(i = 0; i < sz; i += PGSIZE){
    800015e4:	6785                	lui	a5,0x1
    800015e6:	94be                	add	s1,s1,a5
    800015e8:	0954f463          	bleu	s5,s1,80001670 <uvmcopy+0xbe>
    if((pte = walk(old, i, 0)) == 0)
    800015ec:	4601                	li	a2,0
    800015ee:	85a6                	mv	a1,s1
    800015f0:	855a                	mv	a0,s6
    800015f2:	00000097          	auipc	ra,0x0
    800015f6:	a3e080e7          	jalr	-1474(ra) # 80001030 <walk>
    800015fa:	dd69                	beqz	a0,800015d4 <uvmcopy+0x22>
    if((*pte & PTE_V) == 0)
    800015fc:	6118                	ld	a4,0(a0)
    800015fe:	00177793          	andi	a5,a4,1
    80001602:	d3ed                	beqz	a5,800015e4 <uvmcopy+0x32>
      continue; //panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001604:	00a75593          	srli	a1,a4,0xa
    80001608:	00c59993          	slli	s3,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000160c:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	524080e7          	jalr	1316(ra) # 80000b34 <kalloc>
    80001618:	8a2a                	mv	s4,a0
    8000161a:	c515                	beqz	a0,80001646 <uvmcopy+0x94>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000161c:	6605                	lui	a2,0x1
    8000161e:	85ce                	mv	a1,s3
    80001620:	fffff097          	auipc	ra,0xfffff
    80001624:	76c080e7          	jalr	1900(ra) # 80000d8c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001628:	874a                	mv	a4,s2
    8000162a:	86d2                	mv	a3,s4
    8000162c:	6605                	lui	a2,0x1
    8000162e:	85a6                	mv	a1,s1
    80001630:	855e                	mv	a0,s7
    80001632:	00000097          	auipc	ra,0x0
    80001636:	ae6080e7          	jalr	-1306(ra) # 80001118 <mappages>
    8000163a:	d54d                	beqz	a0,800015e4 <uvmcopy+0x32>
      kfree(mem);
    8000163c:	8552                	mv	a0,s4
    8000163e:	fffff097          	auipc	ra,0xfffff
    80001642:	3f6080e7          	jalr	1014(ra) # 80000a34 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001646:	4685                	li	a3,1
    80001648:	00c4d613          	srli	a2,s1,0xc
    8000164c:	4581                	li	a1,0
    8000164e:	855e                	mv	a0,s7
    80001650:	00000097          	auipc	ra,0x0
    80001654:	c7a080e7          	jalr	-902(ra) # 800012ca <uvmunmap>
  return -1;
    80001658:	557d                	li	a0,-1
}
    8000165a:	60a6                	ld	ra,72(sp)
    8000165c:	6406                	ld	s0,64(sp)
    8000165e:	74e2                	ld	s1,56(sp)
    80001660:	7942                	ld	s2,48(sp)
    80001662:	79a2                	ld	s3,40(sp)
    80001664:	7a02                	ld	s4,32(sp)
    80001666:	6ae2                	ld	s5,24(sp)
    80001668:	6b42                	ld	s6,16(sp)
    8000166a:	6ba2                	ld	s7,8(sp)
    8000166c:	6161                	addi	sp,sp,80
    8000166e:	8082                	ret
  return 0;
    80001670:	4501                	li	a0,0
    80001672:	b7e5                	j	8000165a <uvmcopy+0xa8>
    80001674:	4501                	li	a0,0
}
    80001676:	8082                	ret

0000000080001678 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001678:	1141                	addi	sp,sp,-16
    8000167a:	e406                	sd	ra,8(sp)
    8000167c:	e022                	sd	s0,0(sp)
    8000167e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001680:	4601                	li	a2,0
    80001682:	00000097          	auipc	ra,0x0
    80001686:	9ae080e7          	jalr	-1618(ra) # 80001030 <walk>
  if(pte == 0)
    8000168a:	c901                	beqz	a0,8000169a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000168c:	611c                	ld	a5,0(a0)
    8000168e:	9bbd                	andi	a5,a5,-17
    80001690:	e11c                	sd	a5,0(a0)
}
    80001692:	60a2                	ld	ra,8(sp)
    80001694:	6402                	ld	s0,0(sp)
    80001696:	0141                	addi	sp,sp,16
    80001698:	8082                	ret
    panic("uvmclear");
    8000169a:	00007517          	auipc	a0,0x7
    8000169e:	ade50513          	addi	a0,a0,-1314 # 80008178 <digits+0x160>
    800016a2:	fffff097          	auipc	ra,0xfffff
    800016a6:	eb6080e7          	jalr	-330(ra) # 80000558 <panic>

00000000800016aa <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016aa:	c6bd                	beqz	a3,80001718 <copyout+0x6e>
{
    800016ac:	715d                	addi	sp,sp,-80
    800016ae:	e486                	sd	ra,72(sp)
    800016b0:	e0a2                	sd	s0,64(sp)
    800016b2:	fc26                	sd	s1,56(sp)
    800016b4:	f84a                	sd	s2,48(sp)
    800016b6:	f44e                	sd	s3,40(sp)
    800016b8:	f052                	sd	s4,32(sp)
    800016ba:	ec56                	sd	s5,24(sp)
    800016bc:	e85a                	sd	s6,16(sp)
    800016be:	e45e                	sd	s7,8(sp)
    800016c0:	e062                	sd	s8,0(sp)
    800016c2:	0880                	addi	s0,sp,80
    800016c4:	8baa                	mv	s7,a0
    800016c6:	8a2e                	mv	s4,a1
    800016c8:	8ab2                	mv	s5,a2
    800016ca:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016cc:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016ce:	6b05                	lui	s6,0x1
    800016d0:	a015                	j	800016f4 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016d2:	9552                	add	a0,a0,s4
    800016d4:	0004861b          	sext.w	a2,s1
    800016d8:	85d6                	mv	a1,s5
    800016da:	41250533          	sub	a0,a0,s2
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	6ae080e7          	jalr	1710(ra) # 80000d8c <memmove>

    len -= n;
    800016e6:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ea:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    800016ec:	01690a33          	add	s4,s2,s6
  while(len > 0){
    800016f0:	02098263          	beqz	s3,80001714 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016f4:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    800016f8:	85ca                	mv	a1,s2
    800016fa:	855e                	mv	a0,s7
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	9da080e7          	jalr	-1574(ra) # 800010d6 <walkaddr>
    if(pa0 == 0)
    80001704:	cd01                	beqz	a0,8000171c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001706:	414904b3          	sub	s1,s2,s4
    8000170a:	94da                	add	s1,s1,s6
    if(n > len)
    8000170c:	fc99f3e3          	bleu	s1,s3,800016d2 <copyout+0x28>
    80001710:	84ce                	mv	s1,s3
    80001712:	b7c1                	j	800016d2 <copyout+0x28>
  }
  return 0;
    80001714:	4501                	li	a0,0
    80001716:	a021                	j	8000171e <copyout+0x74>
    80001718:	4501                	li	a0,0
}
    8000171a:	8082                	ret
      return -1;
    8000171c:	557d                	li	a0,-1
}
    8000171e:	60a6                	ld	ra,72(sp)
    80001720:	6406                	ld	s0,64(sp)
    80001722:	74e2                	ld	s1,56(sp)
    80001724:	7942                	ld	s2,48(sp)
    80001726:	79a2                	ld	s3,40(sp)
    80001728:	7a02                	ld	s4,32(sp)
    8000172a:	6ae2                	ld	s5,24(sp)
    8000172c:	6b42                	ld	s6,16(sp)
    8000172e:	6ba2                	ld	s7,8(sp)
    80001730:	6c02                	ld	s8,0(sp)
    80001732:	6161                	addi	sp,sp,80
    80001734:	8082                	ret

0000000080001736 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001736:	caa5                	beqz	a3,800017a6 <copyin+0x70>
{
    80001738:	715d                	addi	sp,sp,-80
    8000173a:	e486                	sd	ra,72(sp)
    8000173c:	e0a2                	sd	s0,64(sp)
    8000173e:	fc26                	sd	s1,56(sp)
    80001740:	f84a                	sd	s2,48(sp)
    80001742:	f44e                	sd	s3,40(sp)
    80001744:	f052                	sd	s4,32(sp)
    80001746:	ec56                	sd	s5,24(sp)
    80001748:	e85a                	sd	s6,16(sp)
    8000174a:	e45e                	sd	s7,8(sp)
    8000174c:	e062                	sd	s8,0(sp)
    8000174e:	0880                	addi	s0,sp,80
    80001750:	8baa                	mv	s7,a0
    80001752:	8aae                	mv	s5,a1
    80001754:	8a32                	mv	s4,a2
    80001756:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001758:	7c7d                	lui	s8,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000175a:	6b05                	lui	s6,0x1
    8000175c:	a01d                	j	80001782 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000175e:	014505b3          	add	a1,a0,s4
    80001762:	0004861b          	sext.w	a2,s1
    80001766:	412585b3          	sub	a1,a1,s2
    8000176a:	8556                	mv	a0,s5
    8000176c:	fffff097          	auipc	ra,0xfffff
    80001770:	620080e7          	jalr	1568(ra) # 80000d8c <memmove>

    len -= n;
    80001774:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001778:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    8000177a:	01690a33          	add	s4,s2,s6
  while(len > 0){
    8000177e:	02098263          	beqz	s3,800017a2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001782:	018a7933          	and	s2,s4,s8
    pa0 = walkaddr(pagetable, va0);
    80001786:	85ca                	mv	a1,s2
    80001788:	855e                	mv	a0,s7
    8000178a:	00000097          	auipc	ra,0x0
    8000178e:	94c080e7          	jalr	-1716(ra) # 800010d6 <walkaddr>
    if(pa0 == 0)
    80001792:	cd01                	beqz	a0,800017aa <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001794:	414904b3          	sub	s1,s2,s4
    80001798:	94da                	add	s1,s1,s6
    if(n > len)
    8000179a:	fc99f2e3          	bleu	s1,s3,8000175e <copyin+0x28>
    8000179e:	84ce                	mv	s1,s3
    800017a0:	bf7d                	j	8000175e <copyin+0x28>
  }
  return 0;
    800017a2:	4501                	li	a0,0
    800017a4:	a021                	j	800017ac <copyin+0x76>
    800017a6:	4501                	li	a0,0
}
    800017a8:	8082                	ret
      return -1;
    800017aa:	557d                	li	a0,-1
}
    800017ac:	60a6                	ld	ra,72(sp)
    800017ae:	6406                	ld	s0,64(sp)
    800017b0:	74e2                	ld	s1,56(sp)
    800017b2:	7942                	ld	s2,48(sp)
    800017b4:	79a2                	ld	s3,40(sp)
    800017b6:	7a02                	ld	s4,32(sp)
    800017b8:	6ae2                	ld	s5,24(sp)
    800017ba:	6b42                	ld	s6,16(sp)
    800017bc:	6ba2                	ld	s7,8(sp)
    800017be:	6c02                	ld	s8,0(sp)
    800017c0:	6161                	addi	sp,sp,80
    800017c2:	8082                	ret

00000000800017c4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017c4:	ced5                	beqz	a3,80001880 <copyinstr+0xbc>
{
    800017c6:	715d                	addi	sp,sp,-80
    800017c8:	e486                	sd	ra,72(sp)
    800017ca:	e0a2                	sd	s0,64(sp)
    800017cc:	fc26                	sd	s1,56(sp)
    800017ce:	f84a                	sd	s2,48(sp)
    800017d0:	f44e                	sd	s3,40(sp)
    800017d2:	f052                	sd	s4,32(sp)
    800017d4:	ec56                	sd	s5,24(sp)
    800017d6:	e85a                	sd	s6,16(sp)
    800017d8:	e45e                	sd	s7,8(sp)
    800017da:	e062                	sd	s8,0(sp)
    800017dc:	0880                	addi	s0,sp,80
    800017de:	8aaa                	mv	s5,a0
    800017e0:	84ae                	mv	s1,a1
    800017e2:	8c32                	mv	s8,a2
    800017e4:	8bb6                	mv	s7,a3
    va0 = PGROUNDDOWN(srcva);
    800017e6:	7a7d                	lui	s4,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017e8:	6985                	lui	s3,0x1
    800017ea:	4b05                	li	s6,1
    800017ec:	a801                	j	800017fc <copyinstr+0x38>
    if(n > max)
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
    800017ee:	87a6                	mv	a5,s1
    800017f0:	a085                	j	80001850 <copyinstr+0x8c>
        *dst = *p;
      }
      --n;
      --max;
      p++;
      dst++;
    800017f2:	84b2                	mv	s1,a2
    }

    srcva = va0 + PGSIZE;
    800017f4:	01390c33          	add	s8,s2,s3
  while(got_null == 0 && max > 0){
    800017f8:	080b8063          	beqz	s7,80001878 <copyinstr+0xb4>
    va0 = PGROUNDDOWN(srcva);
    800017fc:	014c7933          	and	s2,s8,s4
    pa0 = walkaddr(pagetable, va0);
    80001800:	85ca                	mv	a1,s2
    80001802:	8556                	mv	a0,s5
    80001804:	00000097          	auipc	ra,0x0
    80001808:	8d2080e7          	jalr	-1838(ra) # 800010d6 <walkaddr>
    if(pa0 == 0)
    8000180c:	c925                	beqz	a0,8000187c <copyinstr+0xb8>
    n = PGSIZE - (srcva - va0);
    8000180e:	41890633          	sub	a2,s2,s8
    80001812:	964e                	add	a2,a2,s3
    if(n > max)
    80001814:	00cbf363          	bleu	a2,s7,8000181a <copyinstr+0x56>
    80001818:	865e                	mv	a2,s7
    char *p = (char *) (pa0 + (srcva - va0));
    8000181a:	9562                	add	a0,a0,s8
    8000181c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001820:	da71                	beqz	a2,800017f4 <copyinstr+0x30>
      if(*p == '\0'){
    80001822:	00054703          	lbu	a4,0(a0)
    80001826:	d761                	beqz	a4,800017ee <copyinstr+0x2a>
    80001828:	9626                	add	a2,a2,s1
    8000182a:	87a6                	mv	a5,s1
    8000182c:	1bfd                	addi	s7,s7,-1
    8000182e:	009b86b3          	add	a3,s7,s1
    80001832:	409b04b3          	sub	s1,s6,s1
    80001836:	94aa                	add	s1,s1,a0
        *dst = *p;
    80001838:	00e78023          	sb	a4,0(a5) # 1000 <_entry-0x7ffff000>
      --max;
    8000183c:	40f68bb3          	sub	s7,a3,a5
      p++;
    80001840:	00f48733          	add	a4,s1,a5
      dst++;
    80001844:	0785                	addi	a5,a5,1
    while(n > 0){
    80001846:	faf606e3          	beq	a2,a5,800017f2 <copyinstr+0x2e>
      if(*p == '\0'){
    8000184a:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffcd000>
    8000184e:	f76d                	bnez	a4,80001838 <copyinstr+0x74>
        *dst = '\0';
    80001850:	00078023          	sb	zero,0(a5)
    80001854:	4785                	li	a5,1
  }
  if(got_null){
    80001856:	0017b513          	seqz	a0,a5
    8000185a:	40a0053b          	negw	a0,a0
    8000185e:	2501                	sext.w	a0,a0
    return 0;
  } else {
    return -1;
  }
}
    80001860:	60a6                	ld	ra,72(sp)
    80001862:	6406                	ld	s0,64(sp)
    80001864:	74e2                	ld	s1,56(sp)
    80001866:	7942                	ld	s2,48(sp)
    80001868:	79a2                	ld	s3,40(sp)
    8000186a:	7a02                	ld	s4,32(sp)
    8000186c:	6ae2                	ld	s5,24(sp)
    8000186e:	6b42                	ld	s6,16(sp)
    80001870:	6ba2                	ld	s7,8(sp)
    80001872:	6c02                	ld	s8,0(sp)
    80001874:	6161                	addi	sp,sp,80
    80001876:	8082                	ret
    80001878:	4781                	li	a5,0
    8000187a:	bff1                	j	80001856 <copyinstr+0x92>
      return -1;
    8000187c:	557d                	li	a0,-1
    8000187e:	b7cd                	j	80001860 <copyinstr+0x9c>
  int got_null = 0;
    80001880:	4781                	li	a5,0
  if(got_null){
    80001882:	0017b513          	seqz	a0,a5
    80001886:	40a0053b          	negw	a0,a0
    8000188a:	2501                	sext.w	a0,a0
}
    8000188c:	8082                	ret

000000008000188e <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    8000188e:	1101                	addi	sp,sp,-32
    80001890:	ec06                	sd	ra,24(sp)
    80001892:	e822                	sd	s0,16(sp)
    80001894:	e426                	sd	s1,8(sp)
    80001896:	1000                	addi	s0,sp,32
    80001898:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000189a:	fffff097          	auipc	ra,0xfffff
    8000189e:	310080e7          	jalr	784(ra) # 80000baa <holding>
    800018a2:	c909                	beqz	a0,800018b4 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018a4:	749c                	ld	a5,40(s1)
    800018a6:	00978f63          	beq	a5,s1,800018c4 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018aa:	60e2                	ld	ra,24(sp)
    800018ac:	6442                	ld	s0,16(sp)
    800018ae:	64a2                	ld	s1,8(sp)
    800018b0:	6105                	addi	sp,sp,32
    800018b2:	8082                	ret
    panic("wakeup1");
    800018b4:	00007517          	auipc	a0,0x7
    800018b8:	8fc50513          	addi	a0,a0,-1796 # 800081b0 <states.1754+0x28>
    800018bc:	fffff097          	auipc	ra,0xfffff
    800018c0:	c9c080e7          	jalr	-868(ra) # 80000558 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018c4:	4c98                	lw	a4,24(s1)
    800018c6:	4785                	li	a5,1
    800018c8:	fef711e3          	bne	a4,a5,800018aa <wakeup1+0x1c>
    p->state = RUNNABLE;
    800018cc:	4789                	li	a5,2
    800018ce:	cc9c                	sw	a5,24(s1)
}
    800018d0:	bfe9                	j	800018aa <wakeup1+0x1c>

00000000800018d2 <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    800018d2:	7139                	addi	sp,sp,-64
    800018d4:	fc06                	sd	ra,56(sp)
    800018d6:	f822                	sd	s0,48(sp)
    800018d8:	f426                	sd	s1,40(sp)
    800018da:	f04a                	sd	s2,32(sp)
    800018dc:	ec4e                	sd	s3,24(sp)
    800018de:	e852                	sd	s4,16(sp)
    800018e0:	e456                	sd	s5,8(sp)
    800018e2:	e05a                	sd	s6,0(sp)
    800018e4:	0080                	addi	s0,sp,64
    800018e6:	8b2a                	mv	s6,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800018e8:	00010497          	auipc	s1,0x10
    800018ec:	dd048493          	addi	s1,s1,-560 # 800116b8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    800018f0:	8aa6                	mv	s5,s1
    800018f2:	00006a17          	auipc	s4,0x6
    800018f6:	70ea0a13          	addi	s4,s4,1806 # 80008000 <etext>
    800018fa:	04000937          	lui	s2,0x4000
    800018fe:	197d                	addi	s2,s2,-1
    80001900:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001902:	00021997          	auipc	s3,0x21
    80001906:	7b698993          	addi	s3,s3,1974 # 800230b8 <tickslock>
    char *pa = kalloc();
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	22a080e7          	jalr	554(ra) # 80000b34 <kalloc>
    80001912:	862a                	mv	a2,a0
    if(pa == 0)
    80001914:	c131                	beqz	a0,80001958 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001916:	415485b3          	sub	a1,s1,s5
    8000191a:	858d                	srai	a1,a1,0x3
    8000191c:	000a3783          	ld	a5,0(s4)
    80001920:	02f585b3          	mul	a1,a1,a5
    80001924:	2585                	addiw	a1,a1,1
    80001926:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000192a:	4719                	li	a4,6
    8000192c:	6685                	lui	a3,0x1
    8000192e:	40b905b3          	sub	a1,s2,a1
    80001932:	855a                	mv	a0,s6
    80001934:	00000097          	auipc	ra,0x0
    80001938:	870080e7          	jalr	-1936(ra) # 800011a4 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000193c:	46848493          	addi	s1,s1,1128
    80001940:	fd3495e3          	bne	s1,s3,8000190a <proc_mapstacks+0x38>
}
    80001944:	70e2                	ld	ra,56(sp)
    80001946:	7442                	ld	s0,48(sp)
    80001948:	74a2                	ld	s1,40(sp)
    8000194a:	7902                	ld	s2,32(sp)
    8000194c:	69e2                	ld	s3,24(sp)
    8000194e:	6a42                	ld	s4,16(sp)
    80001950:	6aa2                	ld	s5,8(sp)
    80001952:	6b02                	ld	s6,0(sp)
    80001954:	6121                	addi	sp,sp,64
    80001956:	8082                	ret
      panic("kalloc");
    80001958:	00007517          	auipc	a0,0x7
    8000195c:	86050513          	addi	a0,a0,-1952 # 800081b8 <states.1754+0x30>
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	bf8080e7          	jalr	-1032(ra) # 80000558 <panic>

0000000080001968 <procinit>:
{
    80001968:	7139                	addi	sp,sp,-64
    8000196a:	fc06                	sd	ra,56(sp)
    8000196c:	f822                	sd	s0,48(sp)
    8000196e:	f426                	sd	s1,40(sp)
    80001970:	f04a                	sd	s2,32(sp)
    80001972:	ec4e                	sd	s3,24(sp)
    80001974:	e852                	sd	s4,16(sp)
    80001976:	e456                	sd	s5,8(sp)
    80001978:	e05a                	sd	s6,0(sp)
    8000197a:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    8000197c:	00007597          	auipc	a1,0x7
    80001980:	84458593          	addi	a1,a1,-1980 # 800081c0 <states.1754+0x38>
    80001984:	00010517          	auipc	a0,0x10
    80001988:	91c50513          	addi	a0,a0,-1764 # 800112a0 <pid_lock>
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	208080e7          	jalr	520(ra) # 80000b94 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001994:	00010497          	auipc	s1,0x10
    80001998:	d2448493          	addi	s1,s1,-732 # 800116b8 <proc>
      initlock(&p->lock, "proc");
    8000199c:	00007b17          	auipc	s6,0x7
    800019a0:	82cb0b13          	addi	s6,s6,-2004 # 800081c8 <states.1754+0x40>
      p->kstack = KSTACK((int) (p - proc));
    800019a4:	8aa6                	mv	s5,s1
    800019a6:	00006a17          	auipc	s4,0x6
    800019aa:	65aa0a13          	addi	s4,s4,1626 # 80008000 <etext>
    800019ae:	04000937          	lui	s2,0x4000
    800019b2:	197d                	addi	s2,s2,-1
    800019b4:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019b6:	00021997          	auipc	s3,0x21
    800019ba:	70298993          	addi	s3,s3,1794 # 800230b8 <tickslock>
      initlock(&p->lock, "proc");
    800019be:	85da                	mv	a1,s6
    800019c0:	8526                	mv	a0,s1
    800019c2:	fffff097          	auipc	ra,0xfffff
    800019c6:	1d2080e7          	jalr	466(ra) # 80000b94 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    800019ca:	415487b3          	sub	a5,s1,s5
    800019ce:	878d                	srai	a5,a5,0x3
    800019d0:	000a3703          	ld	a4,0(s4)
    800019d4:	02e787b3          	mul	a5,a5,a4
    800019d8:	2785                	addiw	a5,a5,1
    800019da:	00d7979b          	slliw	a5,a5,0xd
    800019de:	40f907b3          	sub	a5,s2,a5
    800019e2:	e0bc                	sd	a5,64(s1)
 memset(p->vma, 0, sizeof(p->vma)); //++++++
    800019e4:	30000613          	li	a2,768
    800019e8:	4581                	li	a1,0
    800019ea:	16848513          	addi	a0,s1,360
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	332080e7          	jalr	818(ra) # 80000d20 <memset>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f6:	46848493          	addi	s1,s1,1128
    800019fa:	fd3492e3          	bne	s1,s3,800019be <procinit+0x56>
}
    800019fe:	70e2                	ld	ra,56(sp)
    80001a00:	7442                	ld	s0,48(sp)
    80001a02:	74a2                	ld	s1,40(sp)
    80001a04:	7902                	ld	s2,32(sp)
    80001a06:	69e2                	ld	s3,24(sp)
    80001a08:	6a42                	ld	s4,16(sp)
    80001a0a:	6aa2                	ld	s5,8(sp)
    80001a0c:	6b02                	ld	s6,0(sp)
    80001a0e:	6121                	addi	sp,sp,64
    80001a10:	8082                	ret

0000000080001a12 <cpuid>:
{
    80001a12:	1141                	addi	sp,sp,-16
    80001a14:	e422                	sd	s0,8(sp)
    80001a16:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a18:	8512                	mv	a0,tp
}
    80001a1a:	2501                	sext.w	a0,a0
    80001a1c:	6422                	ld	s0,8(sp)
    80001a1e:	0141                	addi	sp,sp,16
    80001a20:	8082                	ret

0000000080001a22 <mycpu>:
mycpu(void) {
    80001a22:	1141                	addi	sp,sp,-16
    80001a24:	e422                	sd	s0,8(sp)
    80001a26:	0800                	addi	s0,sp,16
    80001a28:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a2a:	2781                	sext.w	a5,a5
    80001a2c:	079e                	slli	a5,a5,0x7
}
    80001a2e:	00010517          	auipc	a0,0x10
    80001a32:	88a50513          	addi	a0,a0,-1910 # 800112b8 <cpus>
    80001a36:	953e                	add	a0,a0,a5
    80001a38:	6422                	ld	s0,8(sp)
    80001a3a:	0141                	addi	sp,sp,16
    80001a3c:	8082                	ret

0000000080001a3e <myproc>:
myproc(void) {
    80001a3e:	1101                	addi	sp,sp,-32
    80001a40:	ec06                	sd	ra,24(sp)
    80001a42:	e822                	sd	s0,16(sp)
    80001a44:	e426                	sd	s1,8(sp)
    80001a46:	1000                	addi	s0,sp,32
  push_off();
    80001a48:	fffff097          	auipc	ra,0xfffff
    80001a4c:	190080e7          	jalr	400(ra) # 80000bd8 <push_off>
    80001a50:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a52:	2781                	sext.w	a5,a5
    80001a54:	079e                	slli	a5,a5,0x7
    80001a56:	00010717          	auipc	a4,0x10
    80001a5a:	84a70713          	addi	a4,a4,-1974 # 800112a0 <pid_lock>
    80001a5e:	97ba                	add	a5,a5,a4
    80001a60:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a62:	fffff097          	auipc	ra,0xfffff
    80001a66:	216080e7          	jalr	534(ra) # 80000c78 <pop_off>
}
    80001a6a:	8526                	mv	a0,s1
    80001a6c:	60e2                	ld	ra,24(sp)
    80001a6e:	6442                	ld	s0,16(sp)
    80001a70:	64a2                	ld	s1,8(sp)
    80001a72:	6105                	addi	sp,sp,32
    80001a74:	8082                	ret

0000000080001a76 <forkret>:
{
    80001a76:	1141                	addi	sp,sp,-16
    80001a78:	e406                	sd	ra,8(sp)
    80001a7a:	e022                	sd	s0,0(sp)
    80001a7c:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	fc0080e7          	jalr	-64(ra) # 80001a3e <myproc>
    80001a86:	fffff097          	auipc	ra,0xfffff
    80001a8a:	252080e7          	jalr	594(ra) # 80000cd8 <release>
  if (first) {
    80001a8e:	00007797          	auipc	a5,0x7
    80001a92:	d3278793          	addi	a5,a5,-718 # 800087c0 <first.1714>
    80001a96:	439c                	lw	a5,0(a5)
    80001a98:	eb89                	bnez	a5,80001aaa <forkret+0x34>
  usertrapret();
    80001a9a:	00001097          	auipc	ra,0x1
    80001a9e:	c8e080e7          	jalr	-882(ra) # 80002728 <usertrapret>
}
    80001aa2:	60a2                	ld	ra,8(sp)
    80001aa4:	6402                	ld	s0,0(sp)
    80001aa6:	0141                	addi	sp,sp,16
    80001aa8:	8082                	ret
    first = 0;
    80001aaa:	00007797          	auipc	a5,0x7
    80001aae:	d007ab23          	sw	zero,-746(a5) # 800087c0 <first.1714>
    fsinit(ROOTDEV);
    80001ab2:	4505                	li	a0,1
    80001ab4:	00002097          	auipc	ra,0x2
    80001ab8:	a3a080e7          	jalr	-1478(ra) # 800034ee <fsinit>
    80001abc:	bff9                	j	80001a9a <forkret+0x24>

0000000080001abe <allocpid>:
allocpid() {
    80001abe:	1101                	addi	sp,sp,-32
    80001ac0:	ec06                	sd	ra,24(sp)
    80001ac2:	e822                	sd	s0,16(sp)
    80001ac4:	e426                	sd	s1,8(sp)
    80001ac6:	e04a                	sd	s2,0(sp)
    80001ac8:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001aca:	0000f917          	auipc	s2,0xf
    80001ace:	7d690913          	addi	s2,s2,2006 # 800112a0 <pid_lock>
    80001ad2:	854a                	mv	a0,s2
    80001ad4:	fffff097          	auipc	ra,0xfffff
    80001ad8:	150080e7          	jalr	336(ra) # 80000c24 <acquire>
  pid = nextpid;
    80001adc:	00007797          	auipc	a5,0x7
    80001ae0:	ce878793          	addi	a5,a5,-792 # 800087c4 <nextpid>
    80001ae4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001ae6:	0014871b          	addiw	a4,s1,1
    80001aea:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aec:	854a                	mv	a0,s2
    80001aee:	fffff097          	auipc	ra,0xfffff
    80001af2:	1ea080e7          	jalr	490(ra) # 80000cd8 <release>
}
    80001af6:	8526                	mv	a0,s1
    80001af8:	60e2                	ld	ra,24(sp)
    80001afa:	6442                	ld	s0,16(sp)
    80001afc:	64a2                	ld	s1,8(sp)
    80001afe:	6902                	ld	s2,0(sp)
    80001b00:	6105                	addi	sp,sp,32
    80001b02:	8082                	ret

0000000080001b04 <proc_pagetable>:
{
    80001b04:	1101                	addi	sp,sp,-32
    80001b06:	ec06                	sd	ra,24(sp)
    80001b08:	e822                	sd	s0,16(sp)
    80001b0a:	e426                	sd	s1,8(sp)
    80001b0c:	e04a                	sd	s2,0(sp)
    80001b0e:	1000                	addi	s0,sp,32
    80001b10:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b12:	00000097          	auipc	ra,0x0
    80001b16:	86e080e7          	jalr	-1938(ra) # 80001380 <uvmcreate>
    80001b1a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b1c:	c121                	beqz	a0,80001b5c <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b1e:	4729                	li	a4,10
    80001b20:	00005697          	auipc	a3,0x5
    80001b24:	4e068693          	addi	a3,a3,1248 # 80007000 <_trampoline>
    80001b28:	6605                	lui	a2,0x1
    80001b2a:	040005b7          	lui	a1,0x4000
    80001b2e:	15fd                	addi	a1,a1,-1
    80001b30:	05b2                	slli	a1,a1,0xc
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	5e6080e7          	jalr	1510(ra) # 80001118 <mappages>
    80001b3a:	02054863          	bltz	a0,80001b6a <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b3e:	4719                	li	a4,6
    80001b40:	05893683          	ld	a3,88(s2)
    80001b44:	6605                	lui	a2,0x1
    80001b46:	020005b7          	lui	a1,0x2000
    80001b4a:	15fd                	addi	a1,a1,-1
    80001b4c:	05b6                	slli	a1,a1,0xd
    80001b4e:	8526                	mv	a0,s1
    80001b50:	fffff097          	auipc	ra,0xfffff
    80001b54:	5c8080e7          	jalr	1480(ra) # 80001118 <mappages>
    80001b58:	02054163          	bltz	a0,80001b7a <proc_pagetable+0x76>
}
    80001b5c:	8526                	mv	a0,s1
    80001b5e:	60e2                	ld	ra,24(sp)
    80001b60:	6442                	ld	s0,16(sp)
    80001b62:	64a2                	ld	s1,8(sp)
    80001b64:	6902                	ld	s2,0(sp)
    80001b66:	6105                	addi	sp,sp,32
    80001b68:	8082                	ret
    uvmfree(pagetable, 0);
    80001b6a:	4581                	li	a1,0
    80001b6c:	8526                	mv	a0,s1
    80001b6e:	00000097          	auipc	ra,0x0
    80001b72:	a0c080e7          	jalr	-1524(ra) # 8000157a <uvmfree>
    return 0;
    80001b76:	4481                	li	s1,0
    80001b78:	b7d5                	j	80001b5c <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b7a:	4681                	li	a3,0
    80001b7c:	4605                	li	a2,1
    80001b7e:	040005b7          	lui	a1,0x4000
    80001b82:	15fd                	addi	a1,a1,-1
    80001b84:	05b2                	slli	a1,a1,0xc
    80001b86:	8526                	mv	a0,s1
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	742080e7          	jalr	1858(ra) # 800012ca <uvmunmap>
    uvmfree(pagetable, 0);
    80001b90:	4581                	li	a1,0
    80001b92:	8526                	mv	a0,s1
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	9e6080e7          	jalr	-1562(ra) # 8000157a <uvmfree>
    return 0;
    80001b9c:	4481                	li	s1,0
    80001b9e:	bf7d                	j	80001b5c <proc_pagetable+0x58>

0000000080001ba0 <proc_freepagetable>:
{
    80001ba0:	1101                	addi	sp,sp,-32
    80001ba2:	ec06                	sd	ra,24(sp)
    80001ba4:	e822                	sd	s0,16(sp)
    80001ba6:	e426                	sd	s1,8(sp)
    80001ba8:	e04a                	sd	s2,0(sp)
    80001baa:	1000                	addi	s0,sp,32
    80001bac:	84aa                	mv	s1,a0
    80001bae:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bb0:	4681                	li	a3,0
    80001bb2:	4605                	li	a2,1
    80001bb4:	040005b7          	lui	a1,0x4000
    80001bb8:	15fd                	addi	a1,a1,-1
    80001bba:	05b2                	slli	a1,a1,0xc
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	70e080e7          	jalr	1806(ra) # 800012ca <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bc4:	4681                	li	a3,0
    80001bc6:	4605                	li	a2,1
    80001bc8:	020005b7          	lui	a1,0x2000
    80001bcc:	15fd                	addi	a1,a1,-1
    80001bce:	05b6                	slli	a1,a1,0xd
    80001bd0:	8526                	mv	a0,s1
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	6f8080e7          	jalr	1784(ra) # 800012ca <uvmunmap>
  uvmfree(pagetable, sz);
    80001bda:	85ca                	mv	a1,s2
    80001bdc:	8526                	mv	a0,s1
    80001bde:	00000097          	auipc	ra,0x0
    80001be2:	99c080e7          	jalr	-1636(ra) # 8000157a <uvmfree>
}
    80001be6:	60e2                	ld	ra,24(sp)
    80001be8:	6442                	ld	s0,16(sp)
    80001bea:	64a2                	ld	s1,8(sp)
    80001bec:	6902                	ld	s2,0(sp)
    80001bee:	6105                	addi	sp,sp,32
    80001bf0:	8082                	ret

0000000080001bf2 <freeproc>:
{
    80001bf2:	1101                	addi	sp,sp,-32
    80001bf4:	ec06                	sd	ra,24(sp)
    80001bf6:	e822                	sd	s0,16(sp)
    80001bf8:	e426                	sd	s1,8(sp)
    80001bfa:	1000                	addi	s0,sp,32
    80001bfc:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bfe:	6d28                	ld	a0,88(a0)
    80001c00:	c509                	beqz	a0,80001c0a <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	e32080e7          	jalr	-462(ra) # 80000a34 <kfree>
  p->trapframe = 0;
    80001c0a:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c0e:	68a8                	ld	a0,80(s1)
    80001c10:	c511                	beqz	a0,80001c1c <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c12:	64ac                	ld	a1,72(s1)
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	f8c080e7          	jalr	-116(ra) # 80001ba0 <proc_freepagetable>
  p->pagetable = 0;
    80001c1c:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c20:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c24:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c28:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c2c:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c30:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c34:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c38:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c3c:	0004ac23          	sw	zero,24(s1)
}
    80001c40:	60e2                	ld	ra,24(sp)
    80001c42:	6442                	ld	s0,16(sp)
    80001c44:	64a2                	ld	s1,8(sp)
    80001c46:	6105                	addi	sp,sp,32
    80001c48:	8082                	ret

0000000080001c4a <allocproc>:
{
    80001c4a:	1101                	addi	sp,sp,-32
    80001c4c:	ec06                	sd	ra,24(sp)
    80001c4e:	e822                	sd	s0,16(sp)
    80001c50:	e426                	sd	s1,8(sp)
    80001c52:	e04a                	sd	s2,0(sp)
    80001c54:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c56:	00010497          	auipc	s1,0x10
    80001c5a:	a6248493          	addi	s1,s1,-1438 # 800116b8 <proc>
    80001c5e:	00021917          	auipc	s2,0x21
    80001c62:	45a90913          	addi	s2,s2,1114 # 800230b8 <tickslock>
    acquire(&p->lock);
    80001c66:	8526                	mv	a0,s1
    80001c68:	fffff097          	auipc	ra,0xfffff
    80001c6c:	fbc080e7          	jalr	-68(ra) # 80000c24 <acquire>
    if(p->state == UNUSED) {
    80001c70:	4c9c                	lw	a5,24(s1)
    80001c72:	cf81                	beqz	a5,80001c8a <allocproc+0x40>
      release(&p->lock);
    80001c74:	8526                	mv	a0,s1
    80001c76:	fffff097          	auipc	ra,0xfffff
    80001c7a:	062080e7          	jalr	98(ra) # 80000cd8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c7e:	46848493          	addi	s1,s1,1128
    80001c82:	ff2492e3          	bne	s1,s2,80001c66 <allocproc+0x1c>
  return 0;
    80001c86:	4481                	li	s1,0
    80001c88:	a0b9                	j	80001cd6 <allocproc+0x8c>
  p->pid = allocpid();
    80001c8a:	00000097          	auipc	ra,0x0
    80001c8e:	e34080e7          	jalr	-460(ra) # 80001abe <allocpid>
    80001c92:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c94:	fffff097          	auipc	ra,0xfffff
    80001c98:	ea0080e7          	jalr	-352(ra) # 80000b34 <kalloc>
    80001c9c:	892a                	mv	s2,a0
    80001c9e:	eca8                	sd	a0,88(s1)
    80001ca0:	c131                	beqz	a0,80001ce4 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	e60080e7          	jalr	-416(ra) # 80001b04 <proc_pagetable>
    80001cac:	892a                	mv	s2,a0
    80001cae:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cb0:	c129                	beqz	a0,80001cf2 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001cb2:	07000613          	li	a2,112
    80001cb6:	4581                	li	a1,0
    80001cb8:	06048513          	addi	a0,s1,96
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	064080e7          	jalr	100(ra) # 80000d20 <memset>
  p->context.ra = (uint64)forkret;
    80001cc4:	00000797          	auipc	a5,0x0
    80001cc8:	db278793          	addi	a5,a5,-590 # 80001a76 <forkret>
    80001ccc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001cce:	60bc                	ld	a5,64(s1)
    80001cd0:	6705                	lui	a4,0x1
    80001cd2:	97ba                	add	a5,a5,a4
    80001cd4:	f4bc                	sd	a5,104(s1)
}
    80001cd6:	8526                	mv	a0,s1
    80001cd8:	60e2                	ld	ra,24(sp)
    80001cda:	6442                	ld	s0,16(sp)
    80001cdc:	64a2                	ld	s1,8(sp)
    80001cde:	6902                	ld	s2,0(sp)
    80001ce0:	6105                	addi	sp,sp,32
    80001ce2:	8082                	ret
    release(&p->lock);
    80001ce4:	8526                	mv	a0,s1
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	ff2080e7          	jalr	-14(ra) # 80000cd8 <release>
    return 0;
    80001cee:	84ca                	mv	s1,s2
    80001cf0:	b7dd                	j	80001cd6 <allocproc+0x8c>
    freeproc(p);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	00000097          	auipc	ra,0x0
    80001cf8:	efe080e7          	jalr	-258(ra) # 80001bf2 <freeproc>
    release(&p->lock);
    80001cfc:	8526                	mv	a0,s1
    80001cfe:	fffff097          	auipc	ra,0xfffff
    80001d02:	fda080e7          	jalr	-38(ra) # 80000cd8 <release>
    return 0;
    80001d06:	84ca                	mv	s1,s2
    80001d08:	b7f9                	j	80001cd6 <allocproc+0x8c>

0000000080001d0a <userinit>:
{
    80001d0a:	1101                	addi	sp,sp,-32
    80001d0c:	ec06                	sd	ra,24(sp)
    80001d0e:	e822                	sd	s0,16(sp)
    80001d10:	e426                	sd	s1,8(sp)
    80001d12:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	f36080e7          	jalr	-202(ra) # 80001c4a <allocproc>
    80001d1c:	84aa                	mv	s1,a0
  initproc = p;
    80001d1e:	00007797          	auipc	a5,0x7
    80001d22:	30a7b523          	sd	a0,778(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d26:	03400613          	li	a2,52
    80001d2a:	00007597          	auipc	a1,0x7
    80001d2e:	aa658593          	addi	a1,a1,-1370 # 800087d0 <initcode>
    80001d32:	6928                	ld	a0,80(a0)
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	67a080e7          	jalr	1658(ra) # 800013ae <uvminit>
  p->sz = PGSIZE;
    80001d3c:	6785                	lui	a5,0x1
    80001d3e:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d40:	6cb8                	ld	a4,88(s1)
    80001d42:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d46:	6cb8                	ld	a4,88(s1)
    80001d48:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d4a:	4641                	li	a2,16
    80001d4c:	00006597          	auipc	a1,0x6
    80001d50:	48458593          	addi	a1,a1,1156 # 800081d0 <states.1754+0x48>
    80001d54:	15848513          	addi	a0,s1,344
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	140080e7          	jalr	320(ra) # 80000e98 <safestrcpy>
  p->cwd = namei("/");
    80001d60:	00006517          	auipc	a0,0x6
    80001d64:	48050513          	addi	a0,a0,1152 # 800081e0 <states.1754+0x58>
    80001d68:	00002097          	auipc	ra,0x2
    80001d6c:	1c0080e7          	jalr	448(ra) # 80003f28 <namei>
    80001d70:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d74:	4789                	li	a5,2
    80001d76:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d78:	8526                	mv	a0,s1
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	f5e080e7          	jalr	-162(ra) # 80000cd8 <release>
}
    80001d82:	60e2                	ld	ra,24(sp)
    80001d84:	6442                	ld	s0,16(sp)
    80001d86:	64a2                	ld	s1,8(sp)
    80001d88:	6105                	addi	sp,sp,32
    80001d8a:	8082                	ret

0000000080001d8c <growproc>:
{
    80001d8c:	1101                	addi	sp,sp,-32
    80001d8e:	ec06                	sd	ra,24(sp)
    80001d90:	e822                	sd	s0,16(sp)
    80001d92:	e426                	sd	s1,8(sp)
    80001d94:	e04a                	sd	s2,0(sp)
    80001d96:	1000                	addi	s0,sp,32
    80001d98:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d9a:	00000097          	auipc	ra,0x0
    80001d9e:	ca4080e7          	jalr	-860(ra) # 80001a3e <myproc>
    80001da2:	892a                	mv	s2,a0
  sz = p->sz;
    80001da4:	652c                	ld	a1,72(a0)
    80001da6:	0005851b          	sext.w	a0,a1
  if(n > 0){
    80001daa:	00904f63          	bgtz	s1,80001dc8 <growproc+0x3c>
  } else if(n < 0){
    80001dae:	0204cd63          	bltz	s1,80001de8 <growproc+0x5c>
  p->sz = sz;
    80001db2:	1502                	slli	a0,a0,0x20
    80001db4:	9101                	srli	a0,a0,0x20
    80001db6:	04a93423          	sd	a0,72(s2)
  return 0;
    80001dba:	4501                	li	a0,0
}
    80001dbc:	60e2                	ld	ra,24(sp)
    80001dbe:	6442                	ld	s0,16(sp)
    80001dc0:	64a2                	ld	s1,8(sp)
    80001dc2:	6902                	ld	s2,0(sp)
    80001dc4:	6105                	addi	sp,sp,32
    80001dc6:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dc8:	00a4863b          	addw	a2,s1,a0
    80001dcc:	1602                	slli	a2,a2,0x20
    80001dce:	9201                	srli	a2,a2,0x20
    80001dd0:	1582                	slli	a1,a1,0x20
    80001dd2:	9181                	srli	a1,a1,0x20
    80001dd4:	05093503          	ld	a0,80(s2)
    80001dd8:	fffff097          	auipc	ra,0xfffff
    80001ddc:	68e080e7          	jalr	1678(ra) # 80001466 <uvmalloc>
    80001de0:	2501                	sext.w	a0,a0
    80001de2:	f961                	bnez	a0,80001db2 <growproc+0x26>
      return -1;
    80001de4:	557d                	li	a0,-1
    80001de6:	bfd9                	j	80001dbc <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001de8:	00a4863b          	addw	a2,s1,a0
    80001dec:	1602                	slli	a2,a2,0x20
    80001dee:	9201                	srli	a2,a2,0x20
    80001df0:	1582                	slli	a1,a1,0x20
    80001df2:	9181                	srli	a1,a1,0x20
    80001df4:	05093503          	ld	a0,80(s2)
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	628080e7          	jalr	1576(ra) # 80001420 <uvmdealloc>
    80001e00:	2501                	sext.w	a0,a0
    80001e02:	bf45                	j	80001db2 <growproc+0x26>

0000000080001e04 <fork>:
{
    80001e04:	715d                	addi	sp,sp,-80
    80001e06:	e486                	sd	ra,72(sp)
    80001e08:	e0a2                	sd	s0,64(sp)
    80001e0a:	fc26                	sd	s1,56(sp)
    80001e0c:	f84a                	sd	s2,48(sp)
    80001e0e:	f44e                	sd	s3,40(sp)
    80001e10:	f052                	sd	s4,32(sp)
    80001e12:	ec56                	sd	s5,24(sp)
    80001e14:	e85a                	sd	s6,16(sp)
    80001e16:	e45e                	sd	s7,8(sp)
    80001e18:	0880                	addi	s0,sp,80
  struct proc *p = myproc();
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	c24080e7          	jalr	-988(ra) # 80001a3e <myproc>
    80001e22:	84aa                	mv	s1,a0
  if((np = allocproc()) == 0){
    80001e24:	00000097          	auipc	ra,0x0
    80001e28:	e26080e7          	jalr	-474(ra) # 80001c4a <allocproc>
    80001e2c:	12050563          	beqz	a0,80001f56 <fork+0x152>
    80001e30:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e32:	64b0                	ld	a2,72(s1)
    80001e34:	692c                	ld	a1,80(a0)
    80001e36:	68a8                	ld	a0,80(s1)
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	77a080e7          	jalr	1914(ra) # 800015b2 <uvmcopy>
    80001e40:	04054663          	bltz	a0,80001e8c <fork+0x88>
  np->sz = p->sz;
    80001e44:	64bc                	ld	a5,72(s1)
    80001e46:	04f9b423          	sd	a5,72(s3)
  np->parent = p;
    80001e4a:	0299b023          	sd	s1,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e4e:	6cb4                	ld	a3,88(s1)
    80001e50:	87b6                	mv	a5,a3
    80001e52:	0589b703          	ld	a4,88(s3)
    80001e56:	12068693          	addi	a3,a3,288
    80001e5a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e5e:	6788                	ld	a0,8(a5)
    80001e60:	6b8c                	ld	a1,16(a5)
    80001e62:	6f90                	ld	a2,24(a5)
    80001e64:	01073023          	sd	a6,0(a4)
    80001e68:	e708                	sd	a0,8(a4)
    80001e6a:	eb0c                	sd	a1,16(a4)
    80001e6c:	ef10                	sd	a2,24(a4)
    80001e6e:	02078793          	addi	a5,a5,32
    80001e72:	02070713          	addi	a4,a4,32
    80001e76:	fed792e3          	bne	a5,a3,80001e5a <fork+0x56>
  np->trapframe->a0 = 0;
    80001e7a:	0589b783          	ld	a5,88(s3)
    80001e7e:	0607b823          	sd	zero,112(a5)
    80001e82:	0d000913          	li	s2,208
  for(i = 0; i < NOFILE; i++)
    80001e86:	15000a13          	li	s4,336
    80001e8a:	a03d                	j	80001eb8 <fork+0xb4>
    freeproc(np);
    80001e8c:	854e                	mv	a0,s3
    80001e8e:	00000097          	auipc	ra,0x0
    80001e92:	d64080e7          	jalr	-668(ra) # 80001bf2 <freeproc>
    release(&np->lock);
    80001e96:	854e                	mv	a0,s3
    80001e98:	fffff097          	auipc	ra,0xfffff
    80001e9c:	e40080e7          	jalr	-448(ra) # 80000cd8 <release>
    return -1;
    80001ea0:	5bfd                	li	s7,-1
    80001ea2:	a871                	j	80001f3e <fork+0x13a>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ea4:	00002097          	auipc	ra,0x2
    80001ea8:	754080e7          	jalr	1876(ra) # 800045f8 <filedup>
    80001eac:	012987b3          	add	a5,s3,s2
    80001eb0:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001eb2:	0921                	addi	s2,s2,8
    80001eb4:	01490763          	beq	s2,s4,80001ec2 <fork+0xbe>
    if(p->ofile[i])
    80001eb8:	012487b3          	add	a5,s1,s2
    80001ebc:	6388                	ld	a0,0(a5)
    80001ebe:	f17d                	bnez	a0,80001ea4 <fork+0xa0>
    80001ec0:	bfcd                	j	80001eb2 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001ec2:	1504b503          	ld	a0,336(s1)
    80001ec6:	00002097          	auipc	ra,0x2
    80001eca:	864080e7          	jalr	-1948(ra) # 8000372a <idup>
    80001ece:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ed2:	4641                	li	a2,16
    80001ed4:	15848593          	addi	a1,s1,344
    80001ed8:	15898513          	addi	a0,s3,344
    80001edc:	fffff097          	auipc	ra,0xfffff
    80001ee0:	fbc080e7          	jalr	-68(ra) # 80000e98 <safestrcpy>
  pid = np->pid;
    80001ee4:	0389ab83          	lw	s7,56(s3)
    for (int i = 0; i < 16; i++) {
    80001ee8:	18448493          	addi	s1,s1,388
  pid = np->pid;
    80001eec:	4901                	li	s2,0
    if (p->vma[i].valid == 1) {
    80001eee:	4a85                	li	s5,1
      memmove(&(np->vma[i]), &(p->vma[i]), sizeof(struct VMA));
    80001ef0:	16898b13          	addi	s6,s3,360
    for (int i = 0; i < 16; i++) {
    80001ef4:	30000a13          	li	s4,768
    80001ef8:	a03d                	j	80001f26 <fork+0x122>
      memmove(&(np->vma[i]), &(p->vma[i]), sizeof(struct VMA));
    80001efa:	03000613          	li	a2,48
    80001efe:	fe448593          	addi	a1,s1,-28
    80001f02:	012b0533          	add	a0,s6,s2
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	e86080e7          	jalr	-378(ra) # 80000d8c <memmove>
      filedup(p->vma[i].f);
    80001f0e:	00c4b503          	ld	a0,12(s1)
    80001f12:	00002097          	auipc	ra,0x2
    80001f16:	6e6080e7          	jalr	1766(ra) # 800045f8 <filedup>
    for (int i = 0; i < 16; i++) {
    80001f1a:	03048493          	addi	s1,s1,48
    80001f1e:	03090913          	addi	s2,s2,48
    80001f22:	01490663          	beq	s2,s4,80001f2e <fork+0x12a>
    if (p->vma[i].valid == 1) {
    80001f26:	409c                	lw	a5,0(s1)
    80001f28:	ff5799e3          	bne	a5,s5,80001f1a <fork+0x116>
    80001f2c:	b7f9                	j	80001efa <fork+0xf6>
  np->state = RUNNABLE;
    80001f2e:	4789                	li	a5,2
    80001f30:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f34:	854e                	mv	a0,s3
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	da2080e7          	jalr	-606(ra) # 80000cd8 <release>
}
    80001f3e:	855e                	mv	a0,s7
    80001f40:	60a6                	ld	ra,72(sp)
    80001f42:	6406                	ld	s0,64(sp)
    80001f44:	74e2                	ld	s1,56(sp)
    80001f46:	7942                	ld	s2,48(sp)
    80001f48:	79a2                	ld	s3,40(sp)
    80001f4a:	7a02                	ld	s4,32(sp)
    80001f4c:	6ae2                	ld	s5,24(sp)
    80001f4e:	6b42                	ld	s6,16(sp)
    80001f50:	6ba2                	ld	s7,8(sp)
    80001f52:	6161                	addi	sp,sp,80
    80001f54:	8082                	ret
    return -1;
    80001f56:	5bfd                	li	s7,-1
    80001f58:	b7dd                	j	80001f3e <fork+0x13a>

0000000080001f5a <reparent>:
{
    80001f5a:	7179                	addi	sp,sp,-48
    80001f5c:	f406                	sd	ra,40(sp)
    80001f5e:	f022                	sd	s0,32(sp)
    80001f60:	ec26                	sd	s1,24(sp)
    80001f62:	e84a                	sd	s2,16(sp)
    80001f64:	e44e                	sd	s3,8(sp)
    80001f66:	e052                	sd	s4,0(sp)
    80001f68:	1800                	addi	s0,sp,48
    80001f6a:	89aa                	mv	s3,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f6c:	0000f497          	auipc	s1,0xf
    80001f70:	74c48493          	addi	s1,s1,1868 # 800116b8 <proc>
      pp->parent = initproc;
    80001f74:	00007a17          	auipc	s4,0x7
    80001f78:	0b4a0a13          	addi	s4,s4,180 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f7c:	00021917          	auipc	s2,0x21
    80001f80:	13c90913          	addi	s2,s2,316 # 800230b8 <tickslock>
    80001f84:	a029                	j	80001f8e <reparent+0x34>
    80001f86:	46848493          	addi	s1,s1,1128
    80001f8a:	03248363          	beq	s1,s2,80001fb0 <reparent+0x56>
    if(pp->parent == p){
    80001f8e:	709c                	ld	a5,32(s1)
    80001f90:	ff379be3          	bne	a5,s3,80001f86 <reparent+0x2c>
      acquire(&pp->lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	c8e080e7          	jalr	-882(ra) # 80000c24 <acquire>
      pp->parent = initproc;
    80001f9e:	000a3783          	ld	a5,0(s4)
    80001fa2:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001fa4:	8526                	mv	a0,s1
    80001fa6:	fffff097          	auipc	ra,0xfffff
    80001faa:	d32080e7          	jalr	-718(ra) # 80000cd8 <release>
    80001fae:	bfe1                	j	80001f86 <reparent+0x2c>
}
    80001fb0:	70a2                	ld	ra,40(sp)
    80001fb2:	7402                	ld	s0,32(sp)
    80001fb4:	64e2                	ld	s1,24(sp)
    80001fb6:	6942                	ld	s2,16(sp)
    80001fb8:	69a2                	ld	s3,8(sp)
    80001fba:	6a02                	ld	s4,0(sp)
    80001fbc:	6145                	addi	sp,sp,48
    80001fbe:	8082                	ret

0000000080001fc0 <scheduler>:
{
    80001fc0:	711d                	addi	sp,sp,-96
    80001fc2:	ec86                	sd	ra,88(sp)
    80001fc4:	e8a2                	sd	s0,80(sp)
    80001fc6:	e4a6                	sd	s1,72(sp)
    80001fc8:	e0ca                	sd	s2,64(sp)
    80001fca:	fc4e                	sd	s3,56(sp)
    80001fcc:	f852                	sd	s4,48(sp)
    80001fce:	f456                	sd	s5,40(sp)
    80001fd0:	f05a                	sd	s6,32(sp)
    80001fd2:	ec5e                	sd	s7,24(sp)
    80001fd4:	e862                	sd	s8,16(sp)
    80001fd6:	e466                	sd	s9,8(sp)
    80001fd8:	1080                	addi	s0,sp,96
    80001fda:	8792                	mv	a5,tp
  int id = r_tp();
    80001fdc:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fde:	00779c13          	slli	s8,a5,0x7
    80001fe2:	0000f717          	auipc	a4,0xf
    80001fe6:	2be70713          	addi	a4,a4,702 # 800112a0 <pid_lock>
    80001fea:	9762                	add	a4,a4,s8
    80001fec:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001ff0:	0000f717          	auipc	a4,0xf
    80001ff4:	2d070713          	addi	a4,a4,720 # 800112c0 <cpus+0x8>
    80001ff8:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80001ffa:	4a89                	li	s5,2
        c->proc = p;
    80001ffc:	079e                	slli	a5,a5,0x7
    80001ffe:	0000fb17          	auipc	s6,0xf
    80002002:	2a2b0b13          	addi	s6,s6,674 # 800112a0 <pid_lock>
    80002006:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002008:	00021a17          	auipc	s4,0x21
    8000200c:	0b0a0a13          	addi	s4,s4,176 # 800230b8 <tickslock>
    int nproc = 0;
    80002010:	4c81                	li	s9,0
    80002012:	a8a1                	j	8000206a <scheduler+0xaa>
        p->state = RUNNING;
    80002014:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002018:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    8000201c:	06048593          	addi	a1,s1,96
    80002020:	8562                	mv	a0,s8
    80002022:	00000097          	auipc	ra,0x0
    80002026:	65c080e7          	jalr	1628(ra) # 8000267e <swtch>
        c->proc = 0;
    8000202a:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    8000202e:	8526                	mv	a0,s1
    80002030:	fffff097          	auipc	ra,0xfffff
    80002034:	ca8080e7          	jalr	-856(ra) # 80000cd8 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002038:	46848493          	addi	s1,s1,1128
    8000203c:	01448d63          	beq	s1,s4,80002056 <scheduler+0x96>
      acquire(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	be2080e7          	jalr	-1054(ra) # 80000c24 <acquire>
      if(p->state != UNUSED) {
    8000204a:	4c9c                	lw	a5,24(s1)
    8000204c:	d3ed                	beqz	a5,8000202e <scheduler+0x6e>
        nproc++;
    8000204e:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002050:	fd579fe3          	bne	a5,s5,8000202e <scheduler+0x6e>
    80002054:	b7c1                	j	80002014 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002056:	013aca63          	blt	s5,s3,8000206a <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000205a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000205e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002062:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002066:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000206a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000206e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002072:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002076:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002078:	0000f497          	auipc	s1,0xf
    8000207c:	64048493          	addi	s1,s1,1600 # 800116b8 <proc>
        p->state = RUNNING;
    80002080:	4b8d                	li	s7,3
    80002082:	bf7d                	j	80002040 <scheduler+0x80>

0000000080002084 <sched>:
{
    80002084:	7179                	addi	sp,sp,-48
    80002086:	f406                	sd	ra,40(sp)
    80002088:	f022                	sd	s0,32(sp)
    8000208a:	ec26                	sd	s1,24(sp)
    8000208c:	e84a                	sd	s2,16(sp)
    8000208e:	e44e                	sd	s3,8(sp)
    80002090:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002092:	00000097          	auipc	ra,0x0
    80002096:	9ac080e7          	jalr	-1620(ra) # 80001a3e <myproc>
    8000209a:	892a                	mv	s2,a0
  if(!holding(&p->lock))
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	b0e080e7          	jalr	-1266(ra) # 80000baa <holding>
    800020a4:	cd25                	beqz	a0,8000211c <sched+0x98>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020a6:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800020a8:	2781                	sext.w	a5,a5
    800020aa:	079e                	slli	a5,a5,0x7
    800020ac:	0000f717          	auipc	a4,0xf
    800020b0:	1f470713          	addi	a4,a4,500 # 800112a0 <pid_lock>
    800020b4:	97ba                	add	a5,a5,a4
    800020b6:	0907a703          	lw	a4,144(a5)
    800020ba:	4785                	li	a5,1
    800020bc:	06f71863          	bne	a4,a5,8000212c <sched+0xa8>
  if(p->state == RUNNING)
    800020c0:	01892703          	lw	a4,24(s2)
    800020c4:	478d                	li	a5,3
    800020c6:	06f70b63          	beq	a4,a5,8000213c <sched+0xb8>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020ca:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020ce:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020d0:	efb5                	bnez	a5,8000214c <sched+0xc8>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020d4:	0000f497          	auipc	s1,0xf
    800020d8:	1cc48493          	addi	s1,s1,460 # 800112a0 <pid_lock>
    800020dc:	2781                	sext.w	a5,a5
    800020de:	079e                	slli	a5,a5,0x7
    800020e0:	97a6                	add	a5,a5,s1
    800020e2:	0947a983          	lw	s3,148(a5)
    800020e6:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020e8:	2781                	sext.w	a5,a5
    800020ea:	079e                	slli	a5,a5,0x7
    800020ec:	0000f597          	auipc	a1,0xf
    800020f0:	1d458593          	addi	a1,a1,468 # 800112c0 <cpus+0x8>
    800020f4:	95be                	add	a1,a1,a5
    800020f6:	06090513          	addi	a0,s2,96
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	584080e7          	jalr	1412(ra) # 8000267e <swtch>
    80002102:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002104:	2781                	sext.w	a5,a5
    80002106:	079e                	slli	a5,a5,0x7
    80002108:	97a6                	add	a5,a5,s1
    8000210a:	0937aa23          	sw	s3,148(a5)
}
    8000210e:	70a2                	ld	ra,40(sp)
    80002110:	7402                	ld	s0,32(sp)
    80002112:	64e2                	ld	s1,24(sp)
    80002114:	6942                	ld	s2,16(sp)
    80002116:	69a2                	ld	s3,8(sp)
    80002118:	6145                	addi	sp,sp,48
    8000211a:	8082                	ret
    panic("sched p->lock");
    8000211c:	00006517          	auipc	a0,0x6
    80002120:	0cc50513          	addi	a0,a0,204 # 800081e8 <states.1754+0x60>
    80002124:	ffffe097          	auipc	ra,0xffffe
    80002128:	434080e7          	jalr	1076(ra) # 80000558 <panic>
    panic("sched locks");
    8000212c:	00006517          	auipc	a0,0x6
    80002130:	0cc50513          	addi	a0,a0,204 # 800081f8 <states.1754+0x70>
    80002134:	ffffe097          	auipc	ra,0xffffe
    80002138:	424080e7          	jalr	1060(ra) # 80000558 <panic>
    panic("sched running");
    8000213c:	00006517          	auipc	a0,0x6
    80002140:	0cc50513          	addi	a0,a0,204 # 80008208 <states.1754+0x80>
    80002144:	ffffe097          	auipc	ra,0xffffe
    80002148:	414080e7          	jalr	1044(ra) # 80000558 <panic>
    panic("sched interruptible");
    8000214c:	00006517          	auipc	a0,0x6
    80002150:	0cc50513          	addi	a0,a0,204 # 80008218 <states.1754+0x90>
    80002154:	ffffe097          	auipc	ra,0xffffe
    80002158:	404080e7          	jalr	1028(ra) # 80000558 <panic>

000000008000215c <exit>:
{
    8000215c:	7179                	addi	sp,sp,-48
    8000215e:	f406                	sd	ra,40(sp)
    80002160:	f022                	sd	s0,32(sp)
    80002162:	ec26                	sd	s1,24(sp)
    80002164:	e84a                	sd	s2,16(sp)
    80002166:	e44e                	sd	s3,8(sp)
    80002168:	e052                	sd	s4,0(sp)
    8000216a:	1800                	addi	s0,sp,48
    8000216c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000216e:	00000097          	auipc	ra,0x0
    80002172:	8d0080e7          	jalr	-1840(ra) # 80001a3e <myproc>
    80002176:	89aa                	mv	s3,a0
    for (int i = 0; i < 16; i++) {
    80002178:	16850493          	addi	s1,a0,360
    8000217c:	46850913          	addi	s2,a0,1128
      unmap_vma(p->vma[i].addr, p->vma[i].length);
    80002180:	648c                	ld	a1,8(s1)
    80002182:	6088                	ld	a0,0(s1)
    80002184:	00004097          	auipc	ra,0x4
    80002188:	daa080e7          	jalr	-598(ra) # 80005f2e <unmap_vma>
    for (int i = 0; i < 16; i++) {
    8000218c:	03048493          	addi	s1,s1,48
    80002190:	ff2498e3          	bne	s1,s2,80002180 <exit+0x24>
  if(p == initproc)
    80002194:	00007797          	auipc	a5,0x7
    80002198:	e9478793          	addi	a5,a5,-364 # 80009028 <initproc>
    8000219c:	639c                	ld	a5,0(a5)
    8000219e:	0d098493          	addi	s1,s3,208
    800021a2:	15098913          	addi	s2,s3,336
    800021a6:	01379d63          	bne	a5,s3,800021c0 <exit+0x64>
    panic("init exiting");
    800021aa:	00006517          	auipc	a0,0x6
    800021ae:	08650513          	addi	a0,a0,134 # 80008230 <states.1754+0xa8>
    800021b2:	ffffe097          	auipc	ra,0xffffe
    800021b6:	3a6080e7          	jalr	934(ra) # 80000558 <panic>
  for(int fd = 0; fd < NOFILE; fd++){
    800021ba:	04a1                	addi	s1,s1,8
    800021bc:	01248b63          	beq	s1,s2,800021d2 <exit+0x76>
    if(p->ofile[fd]){
    800021c0:	6088                	ld	a0,0(s1)
    800021c2:	dd65                	beqz	a0,800021ba <exit+0x5e>
      fileclose(f);
    800021c4:	00002097          	auipc	ra,0x2
    800021c8:	486080e7          	jalr	1158(ra) # 8000464a <fileclose>
      p->ofile[fd] = 0;
    800021cc:	0004b023          	sd	zero,0(s1)
    800021d0:	b7ed                	j	800021ba <exit+0x5e>
  begin_op();
    800021d2:	00002097          	auipc	ra,0x2
    800021d6:	f74080e7          	jalr	-140(ra) # 80004146 <begin_op>
  iput(p->cwd);
    800021da:	1509b503          	ld	a0,336(s3)
    800021de:	00001097          	auipc	ra,0x1
    800021e2:	746080e7          	jalr	1862(ra) # 80003924 <iput>
  end_op();
    800021e6:	00002097          	auipc	ra,0x2
    800021ea:	fe0080e7          	jalr	-32(ra) # 800041c6 <end_op>
  p->cwd = 0;
    800021ee:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800021f2:	00007497          	auipc	s1,0x7
    800021f6:	e3648493          	addi	s1,s1,-458 # 80009028 <initproc>
    800021fa:	6088                	ld	a0,0(s1)
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	a28080e7          	jalr	-1496(ra) # 80000c24 <acquire>
  wakeup1(initproc);
    80002204:	6088                	ld	a0,0(s1)
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	688080e7          	jalr	1672(ra) # 8000188e <wakeup1>
  release(&initproc->lock);
    8000220e:	6088                	ld	a0,0(s1)
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	ac8080e7          	jalr	-1336(ra) # 80000cd8 <release>
  acquire(&p->lock);
    80002218:	854e                	mv	a0,s3
    8000221a:	fffff097          	auipc	ra,0xfffff
    8000221e:	a0a080e7          	jalr	-1526(ra) # 80000c24 <acquire>
  struct proc *original_parent = p->parent;
    80002222:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002226:	854e                	mv	a0,s3
    80002228:	fffff097          	auipc	ra,0xfffff
    8000222c:	ab0080e7          	jalr	-1360(ra) # 80000cd8 <release>
  acquire(&original_parent->lock);
    80002230:	8526                	mv	a0,s1
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	9f2080e7          	jalr	-1550(ra) # 80000c24 <acquire>
  acquire(&p->lock);
    8000223a:	854e                	mv	a0,s3
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	9e8080e7          	jalr	-1560(ra) # 80000c24 <acquire>
  reparent(p);
    80002244:	854e                	mv	a0,s3
    80002246:	00000097          	auipc	ra,0x0
    8000224a:	d14080e7          	jalr	-748(ra) # 80001f5a <reparent>
  wakeup1(original_parent);
    8000224e:	8526                	mv	a0,s1
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	63e080e7          	jalr	1598(ra) # 8000188e <wakeup1>
  p->xstate = status;
    80002258:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000225c:	4791                	li	a5,4
    8000225e:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002262:	8526                	mv	a0,s1
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	a74080e7          	jalr	-1420(ra) # 80000cd8 <release>
  sched();
    8000226c:	00000097          	auipc	ra,0x0
    80002270:	e18080e7          	jalr	-488(ra) # 80002084 <sched>
  panic("zombie exit");
    80002274:	00006517          	auipc	a0,0x6
    80002278:	fcc50513          	addi	a0,a0,-52 # 80008240 <states.1754+0xb8>
    8000227c:	ffffe097          	auipc	ra,0xffffe
    80002280:	2dc080e7          	jalr	732(ra) # 80000558 <panic>

0000000080002284 <yield>:
{
    80002284:	1101                	addi	sp,sp,-32
    80002286:	ec06                	sd	ra,24(sp)
    80002288:	e822                	sd	s0,16(sp)
    8000228a:	e426                	sd	s1,8(sp)
    8000228c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	7b0080e7          	jalr	1968(ra) # 80001a3e <myproc>
    80002296:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	98c080e7          	jalr	-1652(ra) # 80000c24 <acquire>
  p->state = RUNNABLE;
    800022a0:	4789                	li	a5,2
    800022a2:	cc9c                	sw	a5,24(s1)
  sched();
    800022a4:	00000097          	auipc	ra,0x0
    800022a8:	de0080e7          	jalr	-544(ra) # 80002084 <sched>
  release(&p->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	a2a080e7          	jalr	-1494(ra) # 80000cd8 <release>
}
    800022b6:	60e2                	ld	ra,24(sp)
    800022b8:	6442                	ld	s0,16(sp)
    800022ba:	64a2                	ld	s1,8(sp)
    800022bc:	6105                	addi	sp,sp,32
    800022be:	8082                	ret

00000000800022c0 <sleep>:
{
    800022c0:	7179                	addi	sp,sp,-48
    800022c2:	f406                	sd	ra,40(sp)
    800022c4:	f022                	sd	s0,32(sp)
    800022c6:	ec26                	sd	s1,24(sp)
    800022c8:	e84a                	sd	s2,16(sp)
    800022ca:	e44e                	sd	s3,8(sp)
    800022cc:	1800                	addi	s0,sp,48
    800022ce:	89aa                	mv	s3,a0
    800022d0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022d2:	fffff097          	auipc	ra,0xfffff
    800022d6:	76c080e7          	jalr	1900(ra) # 80001a3e <myproc>
    800022da:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800022dc:	05250663          	beq	a0,s2,80002328 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	944080e7          	jalr	-1724(ra) # 80000c24 <acquire>
    release(lk);
    800022e8:	854a                	mv	a0,s2
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	9ee080e7          	jalr	-1554(ra) # 80000cd8 <release>
  p->chan = chan;
    800022f2:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022f6:	4785                	li	a5,1
    800022f8:	cc9c                	sw	a5,24(s1)
  sched();
    800022fa:	00000097          	auipc	ra,0x0
    800022fe:	d8a080e7          	jalr	-630(ra) # 80002084 <sched>
  p->chan = 0;
    80002302:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002306:	8526                	mv	a0,s1
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	9d0080e7          	jalr	-1584(ra) # 80000cd8 <release>
    acquire(lk);
    80002310:	854a                	mv	a0,s2
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	912080e7          	jalr	-1774(ra) # 80000c24 <acquire>
}
    8000231a:	70a2                	ld	ra,40(sp)
    8000231c:	7402                	ld	s0,32(sp)
    8000231e:	64e2                	ld	s1,24(sp)
    80002320:	6942                	ld	s2,16(sp)
    80002322:	69a2                	ld	s3,8(sp)
    80002324:	6145                	addi	sp,sp,48
    80002326:	8082                	ret
  p->chan = chan;
    80002328:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000232c:	4785                	li	a5,1
    8000232e:	cd1c                	sw	a5,24(a0)
  sched();
    80002330:	00000097          	auipc	ra,0x0
    80002334:	d54080e7          	jalr	-684(ra) # 80002084 <sched>
  p->chan = 0;
    80002338:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000233c:	bff9                	j	8000231a <sleep+0x5a>

000000008000233e <wait>:
{
    8000233e:	715d                	addi	sp,sp,-80
    80002340:	e486                	sd	ra,72(sp)
    80002342:	e0a2                	sd	s0,64(sp)
    80002344:	fc26                	sd	s1,56(sp)
    80002346:	f84a                	sd	s2,48(sp)
    80002348:	f44e                	sd	s3,40(sp)
    8000234a:	f052                	sd	s4,32(sp)
    8000234c:	ec56                	sd	s5,24(sp)
    8000234e:	e85a                	sd	s6,16(sp)
    80002350:	e45e                	sd	s7,8(sp)
    80002352:	e062                	sd	s8,0(sp)
    80002354:	0880                	addi	s0,sp,80
    80002356:	8baa                	mv	s7,a0
  struct proc *p = myproc();
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	6e6080e7          	jalr	1766(ra) # 80001a3e <myproc>
    80002360:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002362:	8c2a                	mv	s8,a0
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	8c0080e7          	jalr	-1856(ra) # 80000c24 <acquire>
    havekids = 0;
    8000236c:	4b01                	li	s6,0
        if(np->state == ZOMBIE){
    8000236e:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002370:	00021997          	auipc	s3,0x21
    80002374:	d4898993          	addi	s3,s3,-696 # 800230b8 <tickslock>
        havekids = 1;
    80002378:	4a85                	li	s5,1
    havekids = 0;
    8000237a:	875a                	mv	a4,s6
    for(np = proc; np < &proc[NPROC]; np++){
    8000237c:	0000f497          	auipc	s1,0xf
    80002380:	33c48493          	addi	s1,s1,828 # 800116b8 <proc>
    80002384:	a08d                	j	800023e6 <wait+0xa8>
          pid = np->pid;
    80002386:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000238a:	000b8e63          	beqz	s7,800023a6 <wait+0x68>
    8000238e:	4691                	li	a3,4
    80002390:	03448613          	addi	a2,s1,52
    80002394:	85de                	mv	a1,s7
    80002396:	05093503          	ld	a0,80(s2)
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	310080e7          	jalr	784(ra) # 800016aa <copyout>
    800023a2:	02054263          	bltz	a0,800023c6 <wait+0x88>
          freeproc(np);
    800023a6:	8526                	mv	a0,s1
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	84a080e7          	jalr	-1974(ra) # 80001bf2 <freeproc>
          release(&np->lock);
    800023b0:	8526                	mv	a0,s1
    800023b2:	fffff097          	auipc	ra,0xfffff
    800023b6:	926080e7          	jalr	-1754(ra) # 80000cd8 <release>
          release(&p->lock);
    800023ba:	854a                	mv	a0,s2
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	91c080e7          	jalr	-1764(ra) # 80000cd8 <release>
          return pid;
    800023c4:	a8a9                	j	8000241e <wait+0xe0>
            release(&np->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	910080e7          	jalr	-1776(ra) # 80000cd8 <release>
            release(&p->lock);
    800023d0:	854a                	mv	a0,s2
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	906080e7          	jalr	-1786(ra) # 80000cd8 <release>
            return -1;
    800023da:	59fd                	li	s3,-1
    800023dc:	a089                	j	8000241e <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800023de:	46848493          	addi	s1,s1,1128
    800023e2:	03348463          	beq	s1,s3,8000240a <wait+0xcc>
      if(np->parent == p){
    800023e6:	709c                	ld	a5,32(s1)
    800023e8:	ff279be3          	bne	a5,s2,800023de <wait+0xa0>
        acquire(&np->lock);
    800023ec:	8526                	mv	a0,s1
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	836080e7          	jalr	-1994(ra) # 80000c24 <acquire>
        if(np->state == ZOMBIE){
    800023f6:	4c9c                	lw	a5,24(s1)
    800023f8:	f94787e3          	beq	a5,s4,80002386 <wait+0x48>
        release(&np->lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	8da080e7          	jalr	-1830(ra) # 80000cd8 <release>
        havekids = 1;
    80002406:	8756                	mv	a4,s5
    80002408:	bfd9                	j	800023de <wait+0xa0>
    if(!havekids || p->killed){
    8000240a:	c701                	beqz	a4,80002412 <wait+0xd4>
    8000240c:	03092783          	lw	a5,48(s2)
    80002410:	c785                	beqz	a5,80002438 <wait+0xfa>
      release(&p->lock);
    80002412:	854a                	mv	a0,s2
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	8c4080e7          	jalr	-1852(ra) # 80000cd8 <release>
      return -1;
    8000241c:	59fd                	li	s3,-1
}
    8000241e:	854e                	mv	a0,s3
    80002420:	60a6                	ld	ra,72(sp)
    80002422:	6406                	ld	s0,64(sp)
    80002424:	74e2                	ld	s1,56(sp)
    80002426:	7942                	ld	s2,48(sp)
    80002428:	79a2                	ld	s3,40(sp)
    8000242a:	7a02                	ld	s4,32(sp)
    8000242c:	6ae2                	ld	s5,24(sp)
    8000242e:	6b42                	ld	s6,16(sp)
    80002430:	6ba2                	ld	s7,8(sp)
    80002432:	6c02                	ld	s8,0(sp)
    80002434:	6161                	addi	sp,sp,80
    80002436:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002438:	85e2                	mv	a1,s8
    8000243a:	854a                	mv	a0,s2
    8000243c:	00000097          	auipc	ra,0x0
    80002440:	e84080e7          	jalr	-380(ra) # 800022c0 <sleep>
    havekids = 0;
    80002444:	bf1d                	j	8000237a <wait+0x3c>

0000000080002446 <wakeup>:
{
    80002446:	7139                	addi	sp,sp,-64
    80002448:	fc06                	sd	ra,56(sp)
    8000244a:	f822                	sd	s0,48(sp)
    8000244c:	f426                	sd	s1,40(sp)
    8000244e:	f04a                	sd	s2,32(sp)
    80002450:	ec4e                	sd	s3,24(sp)
    80002452:	e852                	sd	s4,16(sp)
    80002454:	e456                	sd	s5,8(sp)
    80002456:	0080                	addi	s0,sp,64
    80002458:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    8000245a:	0000f497          	auipc	s1,0xf
    8000245e:	25e48493          	addi	s1,s1,606 # 800116b8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002462:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002464:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002466:	00021917          	auipc	s2,0x21
    8000246a:	c5290913          	addi	s2,s2,-942 # 800230b8 <tickslock>
    8000246e:	a821                	j	80002486 <wakeup+0x40>
      p->state = RUNNABLE;
    80002470:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	862080e7          	jalr	-1950(ra) # 80000cd8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000247e:	46848493          	addi	s1,s1,1128
    80002482:	01248e63          	beq	s1,s2,8000249e <wakeup+0x58>
    acquire(&p->lock);
    80002486:	8526                	mv	a0,s1
    80002488:	ffffe097          	auipc	ra,0xffffe
    8000248c:	79c080e7          	jalr	1948(ra) # 80000c24 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002490:	4c9c                	lw	a5,24(s1)
    80002492:	ff3791e3          	bne	a5,s3,80002474 <wakeup+0x2e>
    80002496:	749c                	ld	a5,40(s1)
    80002498:	fd479ee3          	bne	a5,s4,80002474 <wakeup+0x2e>
    8000249c:	bfd1                	j	80002470 <wakeup+0x2a>
}
    8000249e:	70e2                	ld	ra,56(sp)
    800024a0:	7442                	ld	s0,48(sp)
    800024a2:	74a2                	ld	s1,40(sp)
    800024a4:	7902                	ld	s2,32(sp)
    800024a6:	69e2                	ld	s3,24(sp)
    800024a8:	6a42                	ld	s4,16(sp)
    800024aa:	6aa2                	ld	s5,8(sp)
    800024ac:	6121                	addi	sp,sp,64
    800024ae:	8082                	ret

00000000800024b0 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800024b0:	7179                	addi	sp,sp,-48
    800024b2:	f406                	sd	ra,40(sp)
    800024b4:	f022                	sd	s0,32(sp)
    800024b6:	ec26                	sd	s1,24(sp)
    800024b8:	e84a                	sd	s2,16(sp)
    800024ba:	e44e                	sd	s3,8(sp)
    800024bc:	1800                	addi	s0,sp,48
    800024be:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800024c0:	0000f497          	auipc	s1,0xf
    800024c4:	1f848493          	addi	s1,s1,504 # 800116b8 <proc>
    800024c8:	00021997          	auipc	s3,0x21
    800024cc:	bf098993          	addi	s3,s3,-1040 # 800230b8 <tickslock>
    acquire(&p->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	752080e7          	jalr	1874(ra) # 80000c24 <acquire>
    if(p->pid == pid){
    800024da:	5c9c                	lw	a5,56(s1)
    800024dc:	01278d63          	beq	a5,s2,800024f6 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024e0:	8526                	mv	a0,s1
    800024e2:	ffffe097          	auipc	ra,0xffffe
    800024e6:	7f6080e7          	jalr	2038(ra) # 80000cd8 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024ea:	46848493          	addi	s1,s1,1128
    800024ee:	ff3491e3          	bne	s1,s3,800024d0 <kill+0x20>
  }
  return -1;
    800024f2:	557d                	li	a0,-1
    800024f4:	a829                	j	8000250e <kill+0x5e>
      p->killed = 1;
    800024f6:	4785                	li	a5,1
    800024f8:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024fa:	4c98                	lw	a4,24(s1)
    800024fc:	4785                	li	a5,1
    800024fe:	00f70f63          	beq	a4,a5,8000251c <kill+0x6c>
      release(&p->lock);
    80002502:	8526                	mv	a0,s1
    80002504:	ffffe097          	auipc	ra,0xffffe
    80002508:	7d4080e7          	jalr	2004(ra) # 80000cd8 <release>
      return 0;
    8000250c:	4501                	li	a0,0
}
    8000250e:	70a2                	ld	ra,40(sp)
    80002510:	7402                	ld	s0,32(sp)
    80002512:	64e2                	ld	s1,24(sp)
    80002514:	6942                	ld	s2,16(sp)
    80002516:	69a2                	ld	s3,8(sp)
    80002518:	6145                	addi	sp,sp,48
    8000251a:	8082                	ret
        p->state = RUNNABLE;
    8000251c:	4789                	li	a5,2
    8000251e:	cc9c                	sw	a5,24(s1)
    80002520:	b7cd                	j	80002502 <kill+0x52>

0000000080002522 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002522:	7179                	addi	sp,sp,-48
    80002524:	f406                	sd	ra,40(sp)
    80002526:	f022                	sd	s0,32(sp)
    80002528:	ec26                	sd	s1,24(sp)
    8000252a:	e84a                	sd	s2,16(sp)
    8000252c:	e44e                	sd	s3,8(sp)
    8000252e:	e052                	sd	s4,0(sp)
    80002530:	1800                	addi	s0,sp,48
    80002532:	84aa                	mv	s1,a0
    80002534:	892e                	mv	s2,a1
    80002536:	89b2                	mv	s3,a2
    80002538:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000253a:	fffff097          	auipc	ra,0xfffff
    8000253e:	504080e7          	jalr	1284(ra) # 80001a3e <myproc>
  if(user_dst){
    80002542:	c08d                	beqz	s1,80002564 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002544:	86d2                	mv	a3,s4
    80002546:	864e                	mv	a2,s3
    80002548:	85ca                	mv	a1,s2
    8000254a:	6928                	ld	a0,80(a0)
    8000254c:	fffff097          	auipc	ra,0xfffff
    80002550:	15e080e7          	jalr	350(ra) # 800016aa <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002554:	70a2                	ld	ra,40(sp)
    80002556:	7402                	ld	s0,32(sp)
    80002558:	64e2                	ld	s1,24(sp)
    8000255a:	6942                	ld	s2,16(sp)
    8000255c:	69a2                	ld	s3,8(sp)
    8000255e:	6a02                	ld	s4,0(sp)
    80002560:	6145                	addi	sp,sp,48
    80002562:	8082                	ret
    memmove((char *)dst, src, len);
    80002564:	000a061b          	sext.w	a2,s4
    80002568:	85ce                	mv	a1,s3
    8000256a:	854a                	mv	a0,s2
    8000256c:	fffff097          	auipc	ra,0xfffff
    80002570:	820080e7          	jalr	-2016(ra) # 80000d8c <memmove>
    return 0;
    80002574:	8526                	mv	a0,s1
    80002576:	bff9                	j	80002554 <either_copyout+0x32>

0000000080002578 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002578:	7179                	addi	sp,sp,-48
    8000257a:	f406                	sd	ra,40(sp)
    8000257c:	f022                	sd	s0,32(sp)
    8000257e:	ec26                	sd	s1,24(sp)
    80002580:	e84a                	sd	s2,16(sp)
    80002582:	e44e                	sd	s3,8(sp)
    80002584:	e052                	sd	s4,0(sp)
    80002586:	1800                	addi	s0,sp,48
    80002588:	892a                	mv	s2,a0
    8000258a:	84ae                	mv	s1,a1
    8000258c:	89b2                	mv	s3,a2
    8000258e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	4ae080e7          	jalr	1198(ra) # 80001a3e <myproc>
  if(user_src){
    80002598:	c08d                	beqz	s1,800025ba <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000259a:	86d2                	mv	a3,s4
    8000259c:	864e                	mv	a2,s3
    8000259e:	85ca                	mv	a1,s2
    800025a0:	6928                	ld	a0,80(a0)
    800025a2:	fffff097          	auipc	ra,0xfffff
    800025a6:	194080e7          	jalr	404(ra) # 80001736 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800025aa:	70a2                	ld	ra,40(sp)
    800025ac:	7402                	ld	s0,32(sp)
    800025ae:	64e2                	ld	s1,24(sp)
    800025b0:	6942                	ld	s2,16(sp)
    800025b2:	69a2                	ld	s3,8(sp)
    800025b4:	6a02                	ld	s4,0(sp)
    800025b6:	6145                	addi	sp,sp,48
    800025b8:	8082                	ret
    memmove(dst, (char*)src, len);
    800025ba:	000a061b          	sext.w	a2,s4
    800025be:	85ce                	mv	a1,s3
    800025c0:	854a                	mv	a0,s2
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	7ca080e7          	jalr	1994(ra) # 80000d8c <memmove>
    return 0;
    800025ca:	8526                	mv	a0,s1
    800025cc:	bff9                	j	800025aa <either_copyin+0x32>

00000000800025ce <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025ce:	715d                	addi	sp,sp,-80
    800025d0:	e486                	sd	ra,72(sp)
    800025d2:	e0a2                	sd	s0,64(sp)
    800025d4:	fc26                	sd	s1,56(sp)
    800025d6:	f84a                	sd	s2,48(sp)
    800025d8:	f44e                	sd	s3,40(sp)
    800025da:	f052                	sd	s4,32(sp)
    800025dc:	ec56                	sd	s5,24(sp)
    800025de:	e85a                	sd	s6,16(sp)
    800025e0:	e45e                	sd	s7,8(sp)
    800025e2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025e4:	00006517          	auipc	a0,0x6
    800025e8:	ae450513          	addi	a0,a0,-1308 # 800080c8 <digits+0xb0>
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	fb6080e7          	jalr	-74(ra) # 800005a2 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025f4:	0000f497          	auipc	s1,0xf
    800025f8:	21c48493          	addi	s1,s1,540 # 80011810 <proc+0x158>
    800025fc:	00021917          	auipc	s2,0x21
    80002600:	c1490913          	addi	s2,s2,-1004 # 80023210 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002604:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002606:	00006997          	auipc	s3,0x6
    8000260a:	c4a98993          	addi	s3,s3,-950 # 80008250 <states.1754+0xc8>
    printf("%d %s %s", p->pid, state, p->name);
    8000260e:	00006a97          	auipc	s5,0x6
    80002612:	c4aa8a93          	addi	s5,s5,-950 # 80008258 <states.1754+0xd0>
    printf("\n");
    80002616:	00006a17          	auipc	s4,0x6
    8000261a:	ab2a0a13          	addi	s4,s4,-1358 # 800080c8 <digits+0xb0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000261e:	00006b97          	auipc	s7,0x6
    80002622:	b6ab8b93          	addi	s7,s7,-1174 # 80008188 <states.1754>
    80002626:	a015                	j	8000264a <procdump+0x7c>
    printf("%d %s %s", p->pid, state, p->name);
    80002628:	86ba                	mv	a3,a4
    8000262a:	ee072583          	lw	a1,-288(a4)
    8000262e:	8556                	mv	a0,s5
    80002630:	ffffe097          	auipc	ra,0xffffe
    80002634:	f72080e7          	jalr	-142(ra) # 800005a2 <printf>
    printf("\n");
    80002638:	8552                	mv	a0,s4
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	f68080e7          	jalr	-152(ra) # 800005a2 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002642:	46848493          	addi	s1,s1,1128
    80002646:	03248163          	beq	s1,s2,80002668 <procdump+0x9a>
    if(p->state == UNUSED)
    8000264a:	8726                	mv	a4,s1
    8000264c:	ec04a783          	lw	a5,-320(s1)
    80002650:	dbed                	beqz	a5,80002642 <procdump+0x74>
      state = "???";
    80002652:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002654:	fcfb6ae3          	bltu	s6,a5,80002628 <procdump+0x5a>
    80002658:	1782                	slli	a5,a5,0x20
    8000265a:	9381                	srli	a5,a5,0x20
    8000265c:	078e                	slli	a5,a5,0x3
    8000265e:	97de                	add	a5,a5,s7
    80002660:	6390                	ld	a2,0(a5)
    80002662:	f279                	bnez	a2,80002628 <procdump+0x5a>
      state = "???";
    80002664:	864e                	mv	a2,s3
    80002666:	b7c9                	j	80002628 <procdump+0x5a>
  }
}
    80002668:	60a6                	ld	ra,72(sp)
    8000266a:	6406                	ld	s0,64(sp)
    8000266c:	74e2                	ld	s1,56(sp)
    8000266e:	7942                	ld	s2,48(sp)
    80002670:	79a2                	ld	s3,40(sp)
    80002672:	7a02                	ld	s4,32(sp)
    80002674:	6ae2                	ld	s5,24(sp)
    80002676:	6b42                	ld	s6,16(sp)
    80002678:	6ba2                	ld	s7,8(sp)
    8000267a:	6161                	addi	sp,sp,80
    8000267c:	8082                	ret

000000008000267e <swtch>:
    8000267e:	00153023          	sd	ra,0(a0)
    80002682:	00253423          	sd	sp,8(a0)
    80002686:	e900                	sd	s0,16(a0)
    80002688:	ed04                	sd	s1,24(a0)
    8000268a:	03253023          	sd	s2,32(a0)
    8000268e:	03353423          	sd	s3,40(a0)
    80002692:	03453823          	sd	s4,48(a0)
    80002696:	03553c23          	sd	s5,56(a0)
    8000269a:	05653023          	sd	s6,64(a0)
    8000269e:	05753423          	sd	s7,72(a0)
    800026a2:	05853823          	sd	s8,80(a0)
    800026a6:	05953c23          	sd	s9,88(a0)
    800026aa:	07a53023          	sd	s10,96(a0)
    800026ae:	07b53423          	sd	s11,104(a0)
    800026b2:	0005b083          	ld	ra,0(a1)
    800026b6:	0085b103          	ld	sp,8(a1)
    800026ba:	6980                	ld	s0,16(a1)
    800026bc:	6d84                	ld	s1,24(a1)
    800026be:	0205b903          	ld	s2,32(a1)
    800026c2:	0285b983          	ld	s3,40(a1)
    800026c6:	0305ba03          	ld	s4,48(a1)
    800026ca:	0385ba83          	ld	s5,56(a1)
    800026ce:	0405bb03          	ld	s6,64(a1)
    800026d2:	0485bb83          	ld	s7,72(a1)
    800026d6:	0505bc03          	ld	s8,80(a1)
    800026da:	0585bc83          	ld	s9,88(a1)
    800026de:	0605bd03          	ld	s10,96(a1)
    800026e2:	0685bd83          	ld	s11,104(a1)
    800026e6:	8082                	ret

00000000800026e8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026e8:	1141                	addi	sp,sp,-16
    800026ea:	e406                	sd	ra,8(sp)
    800026ec:	e022                	sd	s0,0(sp)
    800026ee:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026f0:	00006597          	auipc	a1,0x6
    800026f4:	ba058593          	addi	a1,a1,-1120 # 80008290 <states.1754+0x108>
    800026f8:	00021517          	auipc	a0,0x21
    800026fc:	9c050513          	addi	a0,a0,-1600 # 800230b8 <tickslock>
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	494080e7          	jalr	1172(ra) # 80000b94 <initlock>
}
    80002708:	60a2                	ld	ra,8(sp)
    8000270a:	6402                	ld	s0,0(sp)
    8000270c:	0141                	addi	sp,sp,16
    8000270e:	8082                	ret

0000000080002710 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002710:	1141                	addi	sp,sp,-16
    80002712:	e422                	sd	s0,8(sp)
    80002714:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002716:	00004797          	auipc	a5,0x4
    8000271a:	ada78793          	addi	a5,a5,-1318 # 800061f0 <kernelvec>
    8000271e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002722:	6422                	ld	s0,8(sp)
    80002724:	0141                	addi	sp,sp,16
    80002726:	8082                	ret

0000000080002728 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002728:	1141                	addi	sp,sp,-16
    8000272a:	e406                	sd	ra,8(sp)
    8000272c:	e022                	sd	s0,0(sp)
    8000272e:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002730:	fffff097          	auipc	ra,0xfffff
    80002734:	30e080e7          	jalr	782(ra) # 80001a3e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002738:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000273c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000273e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002742:	00005617          	auipc	a2,0x5
    80002746:	8be60613          	addi	a2,a2,-1858 # 80007000 <_trampoline>
    8000274a:	00005697          	auipc	a3,0x5
    8000274e:	8b668693          	addi	a3,a3,-1866 # 80007000 <_trampoline>
    80002752:	8e91                	sub	a3,a3,a2
    80002754:	040007b7          	lui	a5,0x4000
    80002758:	17fd                	addi	a5,a5,-1
    8000275a:	07b2                	slli	a5,a5,0xc
    8000275c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000275e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002762:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002764:	180026f3          	csrr	a3,satp
    80002768:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000276a:	6d38                	ld	a4,88(a0)
    8000276c:	6134                	ld	a3,64(a0)
    8000276e:	6585                	lui	a1,0x1
    80002770:	96ae                	add	a3,a3,a1
    80002772:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002774:	6d38                	ld	a4,88(a0)
    80002776:	00000697          	auipc	a3,0x0
    8000277a:	13868693          	addi	a3,a3,312 # 800028ae <usertrap>
    8000277e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002780:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002782:	8692                	mv	a3,tp
    80002784:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002786:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000278a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000278e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002792:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002796:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002798:	6f18                	ld	a4,24(a4)
    8000279a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000279e:	692c                	ld	a1,80(a0)
    800027a0:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    800027a2:	00005717          	auipc	a4,0x5
    800027a6:	8ee70713          	addi	a4,a4,-1810 # 80007090 <userret>
    800027aa:	8f11                	sub	a4,a4,a2
    800027ac:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    800027ae:	577d                	li	a4,-1
    800027b0:	177e                	slli	a4,a4,0x3f
    800027b2:	8dd9                	or	a1,a1,a4
    800027b4:	02000537          	lui	a0,0x2000
    800027b8:	157d                	addi	a0,a0,-1
    800027ba:	0536                	slli	a0,a0,0xd
    800027bc:	9782                	jalr	a5
}
    800027be:	60a2                	ld	ra,8(sp)
    800027c0:	6402                	ld	s0,0(sp)
    800027c2:	0141                	addi	sp,sp,16
    800027c4:	8082                	ret

00000000800027c6 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027c6:	1101                	addi	sp,sp,-32
    800027c8:	ec06                	sd	ra,24(sp)
    800027ca:	e822                	sd	s0,16(sp)
    800027cc:	e426                	sd	s1,8(sp)
    800027ce:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027d0:	00021497          	auipc	s1,0x21
    800027d4:	8e848493          	addi	s1,s1,-1816 # 800230b8 <tickslock>
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	44a080e7          	jalr	1098(ra) # 80000c24 <acquire>
  ticks++;
    800027e2:	00007517          	auipc	a0,0x7
    800027e6:	84e50513          	addi	a0,a0,-1970 # 80009030 <ticks>
    800027ea:	411c                	lw	a5,0(a0)
    800027ec:	2785                	addiw	a5,a5,1
    800027ee:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027f0:	00000097          	auipc	ra,0x0
    800027f4:	c56080e7          	jalr	-938(ra) # 80002446 <wakeup>
  release(&tickslock);
    800027f8:	8526                	mv	a0,s1
    800027fa:	ffffe097          	auipc	ra,0xffffe
    800027fe:	4de080e7          	jalr	1246(ra) # 80000cd8 <release>
}
    80002802:	60e2                	ld	ra,24(sp)
    80002804:	6442                	ld	s0,16(sp)
    80002806:	64a2                	ld	s1,8(sp)
    80002808:	6105                	addi	sp,sp,32
    8000280a:	8082                	ret

000000008000280c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000280c:	1101                	addi	sp,sp,-32
    8000280e:	ec06                	sd	ra,24(sp)
    80002810:	e822                	sd	s0,16(sp)
    80002812:	e426                	sd	s1,8(sp)
    80002814:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002816:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000281a:	00074d63          	bltz	a4,80002834 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000281e:	57fd                	li	a5,-1
    80002820:	17fe                	slli	a5,a5,0x3f
    80002822:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002824:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002826:	06f70363          	beq	a4,a5,8000288c <devintr+0x80>
  }
}
    8000282a:	60e2                	ld	ra,24(sp)
    8000282c:	6442                	ld	s0,16(sp)
    8000282e:	64a2                	ld	s1,8(sp)
    80002830:	6105                	addi	sp,sp,32
    80002832:	8082                	ret
     (scause & 0xff) == 9){
    80002834:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002838:	46a5                	li	a3,9
    8000283a:	fed792e3          	bne	a5,a3,8000281e <devintr+0x12>
    int irq = plic_claim();
    8000283e:	00004097          	auipc	ra,0x4
    80002842:	aba080e7          	jalr	-1350(ra) # 800062f8 <plic_claim>
    80002846:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002848:	47a9                	li	a5,10
    8000284a:	02f50763          	beq	a0,a5,80002878 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000284e:	4785                	li	a5,1
    80002850:	02f50963          	beq	a0,a5,80002882 <devintr+0x76>
    return 1;
    80002854:	4505                	li	a0,1
    } else if(irq){
    80002856:	d8f1                	beqz	s1,8000282a <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002858:	85a6                	mv	a1,s1
    8000285a:	00006517          	auipc	a0,0x6
    8000285e:	a3e50513          	addi	a0,a0,-1474 # 80008298 <states.1754+0x110>
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	d40080e7          	jalr	-704(ra) # 800005a2 <printf>
      plic_complete(irq);
    8000286a:	8526                	mv	a0,s1
    8000286c:	00004097          	auipc	ra,0x4
    80002870:	ab0080e7          	jalr	-1360(ra) # 8000631c <plic_complete>
    return 1;
    80002874:	4505                	li	a0,1
    80002876:	bf55                	j	8000282a <devintr+0x1e>
      uartintr();
    80002878:	ffffe097          	auipc	ra,0xffffe
    8000287c:	16c080e7          	jalr	364(ra) # 800009e4 <uartintr>
    80002880:	b7ed                	j	8000286a <devintr+0x5e>
      virtio_disk_intr();
    80002882:	00004097          	auipc	ra,0x4
    80002886:	f98080e7          	jalr	-104(ra) # 8000681a <virtio_disk_intr>
    8000288a:	b7c5                	j	8000286a <devintr+0x5e>
    if(cpuid() == 0){
    8000288c:	fffff097          	auipc	ra,0xfffff
    80002890:	186080e7          	jalr	390(ra) # 80001a12 <cpuid>
    80002894:	c901                	beqz	a0,800028a4 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002896:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000289a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000289c:	14479073          	csrw	sip,a5
    return 2;
    800028a0:	4509                	li	a0,2
    800028a2:	b761                	j	8000282a <devintr+0x1e>
      clockintr();
    800028a4:	00000097          	auipc	ra,0x0
    800028a8:	f22080e7          	jalr	-222(ra) # 800027c6 <clockintr>
    800028ac:	b7ed                	j	80002896 <devintr+0x8a>

00000000800028ae <usertrap>:
{
    800028ae:	1101                	addi	sp,sp,-32
    800028b0:	ec06                	sd	ra,24(sp)
    800028b2:	e822                	sd	s0,16(sp)
    800028b4:	e426                	sd	s1,8(sp)
    800028b6:	e04a                	sd	s2,0(sp)
    800028b8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028ba:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028be:	1007f793          	andi	a5,a5,256
    800028c2:	e3ad                	bnez	a5,80002924 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028c4:	00004797          	auipc	a5,0x4
    800028c8:	92c78793          	addi	a5,a5,-1748 # 800061f0 <kernelvec>
    800028cc:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028d0:	fffff097          	auipc	ra,0xfffff
    800028d4:	16e080e7          	jalr	366(ra) # 80001a3e <myproc>
    800028d8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028da:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028dc:	14102773          	csrr	a4,sepc
    800028e0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028e6:	47a1                	li	a5,8
    800028e8:	04f71c63          	bne	a4,a5,80002940 <usertrap+0x92>
    if(p->killed)
    800028ec:	591c                	lw	a5,48(a0)
    800028ee:	e3b9                	bnez	a5,80002934 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028f0:	6cb8                	ld	a4,88(s1)
    800028f2:	6f1c                	ld	a5,24(a4)
    800028f4:	0791                	addi	a5,a5,4
    800028f6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028fc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002900:	10079073          	csrw	sstatus,a5
    syscall();
    80002904:	00000097          	auipc	ra,0x0
    80002908:	318080e7          	jalr	792(ra) # 80002c1c <syscall>
  if(p->killed)
    8000290c:	589c                	lw	a5,48(s1)
    8000290e:	e7cd                	bnez	a5,800029b8 <usertrap+0x10a>
  usertrapret();
    80002910:	00000097          	auipc	ra,0x0
    80002914:	e18080e7          	jalr	-488(ra) # 80002728 <usertrapret>
}
    80002918:	60e2                	ld	ra,24(sp)
    8000291a:	6442                	ld	s0,16(sp)
    8000291c:	64a2                	ld	s1,8(sp)
    8000291e:	6902                	ld	s2,0(sp)
    80002920:	6105                	addi	sp,sp,32
    80002922:	8082                	ret
    panic("usertrap: not from user mode");
    80002924:	00006517          	auipc	a0,0x6
    80002928:	99450513          	addi	a0,a0,-1644 # 800082b8 <states.1754+0x130>
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	c2c080e7          	jalr	-980(ra) # 80000558 <panic>
      exit(-1);
    80002934:	557d                	li	a0,-1
    80002936:	00000097          	auipc	ra,0x0
    8000293a:	826080e7          	jalr	-2010(ra) # 8000215c <exit>
    8000293e:	bf4d                	j	800028f0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002940:	00000097          	auipc	ra,0x0
    80002944:	ecc080e7          	jalr	-308(ra) # 8000280c <devintr>
    80002948:	892a                	mv	s2,a0
    8000294a:	e525                	bnez	a0,800029b2 <usertrap+0x104>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000294c:	14202773          	csrr	a4,scause
else if (r_scause() == 15 || r_scause() == 13) {
    80002950:	47bd                	li	a5,15
    80002952:	00f70763          	beq	a4,a5,80002960 <usertrap+0xb2>
    80002956:	14202773          	csrr	a4,scause
    8000295a:	47b5                	li	a5,13
    8000295c:	02f71163          	bne	a4,a5,8000297e <usertrap+0xd0>
    80002960:	14202573          	csrr	a0,scause
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002964:	143025f3          	csrr	a1,stval
    int ret = handle_mmap_page_fault(r_scause(), r_stval());
    80002968:	00003097          	auipc	ra,0x3
    8000296c:	790080e7          	jalr	1936(ra) # 800060f8 <handle_mmap_page_fault>
    if (ret < 0) {
    80002970:	02051793          	slli	a5,a0,0x20
    80002974:	f807dce3          	bgez	a5,8000290c <usertrap+0x5e>
      p->killed = 1;
    80002978:	4785                	li	a5,1
    8000297a:	d89c                	sw	a5,48(s1)
    8000297c:	a83d                	j	800029ba <usertrap+0x10c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000297e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002982:	5c90                	lw	a2,56(s1)
    80002984:	00006517          	auipc	a0,0x6
    80002988:	95450513          	addi	a0,a0,-1708 # 800082d8 <states.1754+0x150>
    8000298c:	ffffe097          	auipc	ra,0xffffe
    80002990:	c16080e7          	jalr	-1002(ra) # 800005a2 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002994:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002998:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	96c50513          	addi	a0,a0,-1684 # 80008308 <states.1754+0x180>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	bfe080e7          	jalr	-1026(ra) # 800005a2 <printf>
    p->killed = 1;
    800029ac:	4785                	li	a5,1
    800029ae:	d89c                	sw	a5,48(s1)
    800029b0:	a029                	j	800029ba <usertrap+0x10c>
  if(p->killed)
    800029b2:	589c                	lw	a5,48(s1)
    800029b4:	cb81                	beqz	a5,800029c4 <usertrap+0x116>
    800029b6:	a011                	j	800029ba <usertrap+0x10c>
    800029b8:	4901                	li	s2,0
    exit(-1);
    800029ba:	557d                	li	a0,-1
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	7a0080e7          	jalr	1952(ra) # 8000215c <exit>
  if(which_dev == 2)
    800029c4:	4789                	li	a5,2
    800029c6:	f4f915e3          	bne	s2,a5,80002910 <usertrap+0x62>
    yield();
    800029ca:	00000097          	auipc	ra,0x0
    800029ce:	8ba080e7          	jalr	-1862(ra) # 80002284 <yield>
    800029d2:	bf3d                	j	80002910 <usertrap+0x62>

00000000800029d4 <kerneltrap>:
{
    800029d4:	7179                	addi	sp,sp,-48
    800029d6:	f406                	sd	ra,40(sp)
    800029d8:	f022                	sd	s0,32(sp)
    800029da:	ec26                	sd	s1,24(sp)
    800029dc:	e84a                	sd	s2,16(sp)
    800029de:	e44e                	sd	s3,8(sp)
    800029e0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029e6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ea:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029ee:	1004f793          	andi	a5,s1,256
    800029f2:	cb85                	beqz	a5,80002a22 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029f4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029f8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029fa:	ef85                	bnez	a5,80002a32 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	e10080e7          	jalr	-496(ra) # 8000280c <devintr>
    80002a04:	cd1d                	beqz	a0,80002a42 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a06:	4789                	li	a5,2
    80002a08:	06f50a63          	beq	a0,a5,80002a7c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a0c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a10:	10049073          	csrw	sstatus,s1
}
    80002a14:	70a2                	ld	ra,40(sp)
    80002a16:	7402                	ld	s0,32(sp)
    80002a18:	64e2                	ld	s1,24(sp)
    80002a1a:	6942                	ld	s2,16(sp)
    80002a1c:	69a2                	ld	s3,8(sp)
    80002a1e:	6145                	addi	sp,sp,48
    80002a20:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a22:	00006517          	auipc	a0,0x6
    80002a26:	90650513          	addi	a0,a0,-1786 # 80008328 <states.1754+0x1a0>
    80002a2a:	ffffe097          	auipc	ra,0xffffe
    80002a2e:	b2e080e7          	jalr	-1234(ra) # 80000558 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a32:	00006517          	auipc	a0,0x6
    80002a36:	91e50513          	addi	a0,a0,-1762 # 80008350 <states.1754+0x1c8>
    80002a3a:	ffffe097          	auipc	ra,0xffffe
    80002a3e:	b1e080e7          	jalr	-1250(ra) # 80000558 <panic>
    printf("scause %p\n", scause);
    80002a42:	85ce                	mv	a1,s3
    80002a44:	00006517          	auipc	a0,0x6
    80002a48:	92c50513          	addi	a0,a0,-1748 # 80008370 <states.1754+0x1e8>
    80002a4c:	ffffe097          	auipc	ra,0xffffe
    80002a50:	b56080e7          	jalr	-1194(ra) # 800005a2 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a54:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a58:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	92450513          	addi	a0,a0,-1756 # 80008380 <states.1754+0x1f8>
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	b3e080e7          	jalr	-1218(ra) # 800005a2 <printf>
    panic("kerneltrap");
    80002a6c:	00006517          	auipc	a0,0x6
    80002a70:	92c50513          	addi	a0,a0,-1748 # 80008398 <states.1754+0x210>
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	ae4080e7          	jalr	-1308(ra) # 80000558 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	fc2080e7          	jalr	-62(ra) # 80001a3e <myproc>
    80002a84:	d541                	beqz	a0,80002a0c <kerneltrap+0x38>
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	fb8080e7          	jalr	-72(ra) # 80001a3e <myproc>
    80002a8e:	4d18                	lw	a4,24(a0)
    80002a90:	478d                	li	a5,3
    80002a92:	f6f71de3          	bne	a4,a5,80002a0c <kerneltrap+0x38>
    yield();
    80002a96:	fffff097          	auipc	ra,0xfffff
    80002a9a:	7ee080e7          	jalr	2030(ra) # 80002284 <yield>
    80002a9e:	b7bd                	j	80002a0c <kerneltrap+0x38>

0000000080002aa0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002aa0:	1101                	addi	sp,sp,-32
    80002aa2:	ec06                	sd	ra,24(sp)
    80002aa4:	e822                	sd	s0,16(sp)
    80002aa6:	e426                	sd	s1,8(sp)
    80002aa8:	1000                	addi	s0,sp,32
    80002aaa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002aac:	fffff097          	auipc	ra,0xfffff
    80002ab0:	f92080e7          	jalr	-110(ra) # 80001a3e <myproc>
  switch (n) {
    80002ab4:	4795                	li	a5,5
    80002ab6:	0497e363          	bltu	a5,s1,80002afc <argraw+0x5c>
    80002aba:	1482                	slli	s1,s1,0x20
    80002abc:	9081                	srli	s1,s1,0x20
    80002abe:	048a                	slli	s1,s1,0x2
    80002ac0:	00006717          	auipc	a4,0x6
    80002ac4:	8e870713          	addi	a4,a4,-1816 # 800083a8 <states.1754+0x220>
    80002ac8:	94ba                	add	s1,s1,a4
    80002aca:	409c                	lw	a5,0(s1)
    80002acc:	97ba                	add	a5,a5,a4
    80002ace:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ad0:	6d3c                	ld	a5,88(a0)
    80002ad2:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ad4:	60e2                	ld	ra,24(sp)
    80002ad6:	6442                	ld	s0,16(sp)
    80002ad8:	64a2                	ld	s1,8(sp)
    80002ada:	6105                	addi	sp,sp,32
    80002adc:	8082                	ret
    return p->trapframe->a1;
    80002ade:	6d3c                	ld	a5,88(a0)
    80002ae0:	7fa8                	ld	a0,120(a5)
    80002ae2:	bfcd                	j	80002ad4 <argraw+0x34>
    return p->trapframe->a2;
    80002ae4:	6d3c                	ld	a5,88(a0)
    80002ae6:	63c8                	ld	a0,128(a5)
    80002ae8:	b7f5                	j	80002ad4 <argraw+0x34>
    return p->trapframe->a3;
    80002aea:	6d3c                	ld	a5,88(a0)
    80002aec:	67c8                	ld	a0,136(a5)
    80002aee:	b7dd                	j	80002ad4 <argraw+0x34>
    return p->trapframe->a4;
    80002af0:	6d3c                	ld	a5,88(a0)
    80002af2:	6bc8                	ld	a0,144(a5)
    80002af4:	b7c5                	j	80002ad4 <argraw+0x34>
    return p->trapframe->a5;
    80002af6:	6d3c                	ld	a5,88(a0)
    80002af8:	6fc8                	ld	a0,152(a5)
    80002afa:	bfe9                	j	80002ad4 <argraw+0x34>
  panic("argraw");
    80002afc:	00006517          	auipc	a0,0x6
    80002b00:	98450513          	addi	a0,a0,-1660 # 80008480 <syscalls+0xc0>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	a54080e7          	jalr	-1452(ra) # 80000558 <panic>

0000000080002b0c <fetchaddr>:
{
    80002b0c:	1101                	addi	sp,sp,-32
    80002b0e:	ec06                	sd	ra,24(sp)
    80002b10:	e822                	sd	s0,16(sp)
    80002b12:	e426                	sd	s1,8(sp)
    80002b14:	e04a                	sd	s2,0(sp)
    80002b16:	1000                	addi	s0,sp,32
    80002b18:	84aa                	mv	s1,a0
    80002b1a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	f22080e7          	jalr	-222(ra) # 80001a3e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002b24:	653c                	ld	a5,72(a0)
    80002b26:	02f4f963          	bleu	a5,s1,80002b58 <fetchaddr+0x4c>
    80002b2a:	00848713          	addi	a4,s1,8
    80002b2e:	02e7e763          	bltu	a5,a4,80002b5c <fetchaddr+0x50>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b32:	46a1                	li	a3,8
    80002b34:	8626                	mv	a2,s1
    80002b36:	85ca                	mv	a1,s2
    80002b38:	6928                	ld	a0,80(a0)
    80002b3a:	fffff097          	auipc	ra,0xfffff
    80002b3e:	bfc080e7          	jalr	-1028(ra) # 80001736 <copyin>
    80002b42:	00a03533          	snez	a0,a0
    80002b46:	40a0053b          	negw	a0,a0
    80002b4a:	2501                	sext.w	a0,a0
}
    80002b4c:	60e2                	ld	ra,24(sp)
    80002b4e:	6442                	ld	s0,16(sp)
    80002b50:	64a2                	ld	s1,8(sp)
    80002b52:	6902                	ld	s2,0(sp)
    80002b54:	6105                	addi	sp,sp,32
    80002b56:	8082                	ret
    return -1;
    80002b58:	557d                	li	a0,-1
    80002b5a:	bfcd                	j	80002b4c <fetchaddr+0x40>
    80002b5c:	557d                	li	a0,-1
    80002b5e:	b7fd                	j	80002b4c <fetchaddr+0x40>

0000000080002b60 <fetchstr>:
{
    80002b60:	7179                	addi	sp,sp,-48
    80002b62:	f406                	sd	ra,40(sp)
    80002b64:	f022                	sd	s0,32(sp)
    80002b66:	ec26                	sd	s1,24(sp)
    80002b68:	e84a                	sd	s2,16(sp)
    80002b6a:	e44e                	sd	s3,8(sp)
    80002b6c:	1800                	addi	s0,sp,48
    80002b6e:	892a                	mv	s2,a0
    80002b70:	84ae                	mv	s1,a1
    80002b72:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b74:	fffff097          	auipc	ra,0xfffff
    80002b78:	eca080e7          	jalr	-310(ra) # 80001a3e <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b7c:	86ce                	mv	a3,s3
    80002b7e:	864a                	mv	a2,s2
    80002b80:	85a6                	mv	a1,s1
    80002b82:	6928                	ld	a0,80(a0)
    80002b84:	fffff097          	auipc	ra,0xfffff
    80002b88:	c40080e7          	jalr	-960(ra) # 800017c4 <copyinstr>
  if(err < 0)
    80002b8c:	00054763          	bltz	a0,80002b9a <fetchstr+0x3a>
  return strlen(buf);
    80002b90:	8526                	mv	a0,s1
    80002b92:	ffffe097          	auipc	ra,0xffffe
    80002b96:	338080e7          	jalr	824(ra) # 80000eca <strlen>
}
    80002b9a:	70a2                	ld	ra,40(sp)
    80002b9c:	7402                	ld	s0,32(sp)
    80002b9e:	64e2                	ld	s1,24(sp)
    80002ba0:	6942                	ld	s2,16(sp)
    80002ba2:	69a2                	ld	s3,8(sp)
    80002ba4:	6145                	addi	sp,sp,48
    80002ba6:	8082                	ret

0000000080002ba8 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002ba8:	1101                	addi	sp,sp,-32
    80002baa:	ec06                	sd	ra,24(sp)
    80002bac:	e822                	sd	s0,16(sp)
    80002bae:	e426                	sd	s1,8(sp)
    80002bb0:	1000                	addi	s0,sp,32
    80002bb2:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	eec080e7          	jalr	-276(ra) # 80002aa0 <argraw>
    80002bbc:	c088                	sw	a0,0(s1)
  return 0;
}
    80002bbe:	4501                	li	a0,0
    80002bc0:	60e2                	ld	ra,24(sp)
    80002bc2:	6442                	ld	s0,16(sp)
    80002bc4:	64a2                	ld	s1,8(sp)
    80002bc6:	6105                	addi	sp,sp,32
    80002bc8:	8082                	ret

0000000080002bca <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002bca:	1101                	addi	sp,sp,-32
    80002bcc:	ec06                	sd	ra,24(sp)
    80002bce:	e822                	sd	s0,16(sp)
    80002bd0:	e426                	sd	s1,8(sp)
    80002bd2:	1000                	addi	s0,sp,32
    80002bd4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	eca080e7          	jalr	-310(ra) # 80002aa0 <argraw>
    80002bde:	e088                	sd	a0,0(s1)
  return 0;
}
    80002be0:	4501                	li	a0,0
    80002be2:	60e2                	ld	ra,24(sp)
    80002be4:	6442                	ld	s0,16(sp)
    80002be6:	64a2                	ld	s1,8(sp)
    80002be8:	6105                	addi	sp,sp,32
    80002bea:	8082                	ret

0000000080002bec <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	e426                	sd	s1,8(sp)
    80002bf4:	e04a                	sd	s2,0(sp)
    80002bf6:	1000                	addi	s0,sp,32
    80002bf8:	84ae                	mv	s1,a1
    80002bfa:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bfc:	00000097          	auipc	ra,0x0
    80002c00:	ea4080e7          	jalr	-348(ra) # 80002aa0 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002c04:	864a                	mv	a2,s2
    80002c06:	85a6                	mv	a1,s1
    80002c08:	00000097          	auipc	ra,0x0
    80002c0c:	f58080e7          	jalr	-168(ra) # 80002b60 <fetchstr>
}
    80002c10:	60e2                	ld	ra,24(sp)
    80002c12:	6442                	ld	s0,16(sp)
    80002c14:	64a2                	ld	s1,8(sp)
    80002c16:	6902                	ld	s2,0(sp)
    80002c18:	6105                	addi	sp,sp,32
    80002c1a:	8082                	ret

0000000080002c1c <syscall>:
[SYS_munmap]   sys_munmap,//+++++++++++++
};

void
syscall(void)
{
    80002c1c:	1101                	addi	sp,sp,-32
    80002c1e:	ec06                	sd	ra,24(sp)
    80002c20:	e822                	sd	s0,16(sp)
    80002c22:	e426                	sd	s1,8(sp)
    80002c24:	e04a                	sd	s2,0(sp)
    80002c26:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	e16080e7          	jalr	-490(ra) # 80001a3e <myproc>
    80002c30:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c32:	05853903          	ld	s2,88(a0)
    80002c36:	0a893783          	ld	a5,168(s2)
    80002c3a:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c3e:	37fd                	addiw	a5,a5,-1
    80002c40:	4759                	li	a4,22
    80002c42:	00f76f63          	bltu	a4,a5,80002c60 <syscall+0x44>
    80002c46:	00369713          	slli	a4,a3,0x3
    80002c4a:	00005797          	auipc	a5,0x5
    80002c4e:	77678793          	addi	a5,a5,1910 # 800083c0 <syscalls>
    80002c52:	97ba                	add	a5,a5,a4
    80002c54:	639c                	ld	a5,0(a5)
    80002c56:	c789                	beqz	a5,80002c60 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c58:	9782                	jalr	a5
    80002c5a:	06a93823          	sd	a0,112(s2)
    80002c5e:	a839                	j	80002c7c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c60:	15848613          	addi	a2,s1,344
    80002c64:	5c8c                	lw	a1,56(s1)
    80002c66:	00006517          	auipc	a0,0x6
    80002c6a:	82250513          	addi	a0,a0,-2014 # 80008488 <syscalls+0xc8>
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	934080e7          	jalr	-1740(ra) # 800005a2 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c76:	6cbc                	ld	a5,88(s1)
    80002c78:	577d                	li	a4,-1
    80002c7a:	fbb8                	sd	a4,112(a5)
  }
}
    80002c7c:	60e2                	ld	ra,24(sp)
    80002c7e:	6442                	ld	s0,16(sp)
    80002c80:	64a2                	ld	s1,8(sp)
    80002c82:	6902                	ld	s2,0(sp)
    80002c84:	6105                	addi	sp,sp,32
    80002c86:	8082                	ret

0000000080002c88 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c88:	1101                	addi	sp,sp,-32
    80002c8a:	ec06                	sd	ra,24(sp)
    80002c8c:	e822                	sd	s0,16(sp)
    80002c8e:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c90:	fec40593          	addi	a1,s0,-20
    80002c94:	4501                	li	a0,0
    80002c96:	00000097          	auipc	ra,0x0
    80002c9a:	f12080e7          	jalr	-238(ra) # 80002ba8 <argint>
    return -1;
    80002c9e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002ca0:	00054963          	bltz	a0,80002cb2 <sys_exit+0x2a>
  exit(n);
    80002ca4:	fec42503          	lw	a0,-20(s0)
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	4b4080e7          	jalr	1204(ra) # 8000215c <exit>
  return 0;  // not reached
    80002cb0:	4781                	li	a5,0
}
    80002cb2:	853e                	mv	a0,a5
    80002cb4:	60e2                	ld	ra,24(sp)
    80002cb6:	6442                	ld	s0,16(sp)
    80002cb8:	6105                	addi	sp,sp,32
    80002cba:	8082                	ret

0000000080002cbc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cbc:	1141                	addi	sp,sp,-16
    80002cbe:	e406                	sd	ra,8(sp)
    80002cc0:	e022                	sd	s0,0(sp)
    80002cc2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	d7a080e7          	jalr	-646(ra) # 80001a3e <myproc>
}
    80002ccc:	5d08                	lw	a0,56(a0)
    80002cce:	60a2                	ld	ra,8(sp)
    80002cd0:	6402                	ld	s0,0(sp)
    80002cd2:	0141                	addi	sp,sp,16
    80002cd4:	8082                	ret

0000000080002cd6 <sys_fork>:

uint64
sys_fork(void)
{
    80002cd6:	1141                	addi	sp,sp,-16
    80002cd8:	e406                	sd	ra,8(sp)
    80002cda:	e022                	sd	s0,0(sp)
    80002cdc:	0800                	addi	s0,sp,16
  return fork();
    80002cde:	fffff097          	auipc	ra,0xfffff
    80002ce2:	126080e7          	jalr	294(ra) # 80001e04 <fork>
}
    80002ce6:	60a2                	ld	ra,8(sp)
    80002ce8:	6402                	ld	s0,0(sp)
    80002cea:	0141                	addi	sp,sp,16
    80002cec:	8082                	ret

0000000080002cee <sys_wait>:

uint64
sys_wait(void)
{
    80002cee:	1101                	addi	sp,sp,-32
    80002cf0:	ec06                	sd	ra,24(sp)
    80002cf2:	e822                	sd	s0,16(sp)
    80002cf4:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cf6:	fe840593          	addi	a1,s0,-24
    80002cfa:	4501                	li	a0,0
    80002cfc:	00000097          	auipc	ra,0x0
    80002d00:	ece080e7          	jalr	-306(ra) # 80002bca <argaddr>
    return -1;
    80002d04:	57fd                	li	a5,-1
  if(argaddr(0, &p) < 0)
    80002d06:	00054963          	bltz	a0,80002d18 <sys_wait+0x2a>
  return wait(p);
    80002d0a:	fe843503          	ld	a0,-24(s0)
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	630080e7          	jalr	1584(ra) # 8000233e <wait>
    80002d16:	87aa                	mv	a5,a0
}
    80002d18:	853e                	mv	a0,a5
    80002d1a:	60e2                	ld	ra,24(sp)
    80002d1c:	6442                	ld	s0,16(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret

0000000080002d22 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d22:	7179                	addi	sp,sp,-48
    80002d24:	f406                	sd	ra,40(sp)
    80002d26:	f022                	sd	s0,32(sp)
    80002d28:	ec26                	sd	s1,24(sp)
    80002d2a:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002d2c:	fdc40593          	addi	a1,s0,-36
    80002d30:	4501                	li	a0,0
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	e76080e7          	jalr	-394(ra) # 80002ba8 <argint>
    return -1;
    80002d3a:	54fd                	li	s1,-1
  if(argint(0, &n) < 0)
    80002d3c:	00054f63          	bltz	a0,80002d5a <sys_sbrk+0x38>
  addr = myproc()->sz;
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	cfe080e7          	jalr	-770(ra) # 80001a3e <myproc>
    80002d48:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d4a:	fdc42503          	lw	a0,-36(s0)
    80002d4e:	fffff097          	auipc	ra,0xfffff
    80002d52:	03e080e7          	jalr	62(ra) # 80001d8c <growproc>
    80002d56:	00054863          	bltz	a0,80002d66 <sys_sbrk+0x44>
    return -1;
  return addr;
}
    80002d5a:	8526                	mv	a0,s1
    80002d5c:	70a2                	ld	ra,40(sp)
    80002d5e:	7402                	ld	s0,32(sp)
    80002d60:	64e2                	ld	s1,24(sp)
    80002d62:	6145                	addi	sp,sp,48
    80002d64:	8082                	ret
    return -1;
    80002d66:	54fd                	li	s1,-1
    80002d68:	bfcd                	j	80002d5a <sys_sbrk+0x38>

0000000080002d6a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d6a:	7139                	addi	sp,sp,-64
    80002d6c:	fc06                	sd	ra,56(sp)
    80002d6e:	f822                	sd	s0,48(sp)
    80002d70:	f426                	sd	s1,40(sp)
    80002d72:	f04a                	sd	s2,32(sp)
    80002d74:	ec4e                	sd	s3,24(sp)
    80002d76:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d78:	fcc40593          	addi	a1,s0,-52
    80002d7c:	4501                	li	a0,0
    80002d7e:	00000097          	auipc	ra,0x0
    80002d82:	e2a080e7          	jalr	-470(ra) # 80002ba8 <argint>
    return -1;
    80002d86:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d88:	06054763          	bltz	a0,80002df6 <sys_sleep+0x8c>
  acquire(&tickslock);
    80002d8c:	00020517          	auipc	a0,0x20
    80002d90:	32c50513          	addi	a0,a0,812 # 800230b8 <tickslock>
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	e90080e7          	jalr	-368(ra) # 80000c24 <acquire>
  ticks0 = ticks;
    80002d9c:	00006797          	auipc	a5,0x6
    80002da0:	29478793          	addi	a5,a5,660 # 80009030 <ticks>
    80002da4:	0007a903          	lw	s2,0(a5)
  while(ticks - ticks0 < n){
    80002da8:	fcc42783          	lw	a5,-52(s0)
    80002dac:	cf85                	beqz	a5,80002de4 <sys_sleep+0x7a>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dae:	00020997          	auipc	s3,0x20
    80002db2:	30a98993          	addi	s3,s3,778 # 800230b8 <tickslock>
    80002db6:	00006497          	auipc	s1,0x6
    80002dba:	27a48493          	addi	s1,s1,634 # 80009030 <ticks>
    if(myproc()->killed){
    80002dbe:	fffff097          	auipc	ra,0xfffff
    80002dc2:	c80080e7          	jalr	-896(ra) # 80001a3e <myproc>
    80002dc6:	591c                	lw	a5,48(a0)
    80002dc8:	ef9d                	bnez	a5,80002e06 <sys_sleep+0x9c>
    sleep(&ticks, &tickslock);
    80002dca:	85ce                	mv	a1,s3
    80002dcc:	8526                	mv	a0,s1
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	4f2080e7          	jalr	1266(ra) # 800022c0 <sleep>
  while(ticks - ticks0 < n){
    80002dd6:	409c                	lw	a5,0(s1)
    80002dd8:	412787bb          	subw	a5,a5,s2
    80002ddc:	fcc42703          	lw	a4,-52(s0)
    80002de0:	fce7efe3          	bltu	a5,a4,80002dbe <sys_sleep+0x54>
  }
  release(&tickslock);
    80002de4:	00020517          	auipc	a0,0x20
    80002de8:	2d450513          	addi	a0,a0,724 # 800230b8 <tickslock>
    80002dec:	ffffe097          	auipc	ra,0xffffe
    80002df0:	eec080e7          	jalr	-276(ra) # 80000cd8 <release>
  return 0;
    80002df4:	4781                	li	a5,0
}
    80002df6:	853e                	mv	a0,a5
    80002df8:	70e2                	ld	ra,56(sp)
    80002dfa:	7442                	ld	s0,48(sp)
    80002dfc:	74a2                	ld	s1,40(sp)
    80002dfe:	7902                	ld	s2,32(sp)
    80002e00:	69e2                	ld	s3,24(sp)
    80002e02:	6121                	addi	sp,sp,64
    80002e04:	8082                	ret
      release(&tickslock);
    80002e06:	00020517          	auipc	a0,0x20
    80002e0a:	2b250513          	addi	a0,a0,690 # 800230b8 <tickslock>
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	eca080e7          	jalr	-310(ra) # 80000cd8 <release>
      return -1;
    80002e16:	57fd                	li	a5,-1
    80002e18:	bff9                	j	80002df6 <sys_sleep+0x8c>

0000000080002e1a <sys_kill>:

uint64
sys_kill(void)
{
    80002e1a:	1101                	addi	sp,sp,-32
    80002e1c:	ec06                	sd	ra,24(sp)
    80002e1e:	e822                	sd	s0,16(sp)
    80002e20:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002e22:	fec40593          	addi	a1,s0,-20
    80002e26:	4501                	li	a0,0
    80002e28:	00000097          	auipc	ra,0x0
    80002e2c:	d80080e7          	jalr	-640(ra) # 80002ba8 <argint>
    return -1;
    80002e30:	57fd                	li	a5,-1
  if(argint(0, &pid) < 0)
    80002e32:	00054963          	bltz	a0,80002e44 <sys_kill+0x2a>
  return kill(pid);
    80002e36:	fec42503          	lw	a0,-20(s0)
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	676080e7          	jalr	1654(ra) # 800024b0 <kill>
    80002e42:	87aa                	mv	a5,a0
}
    80002e44:	853e                	mv	a0,a5
    80002e46:	60e2                	ld	ra,24(sp)
    80002e48:	6442                	ld	s0,16(sp)
    80002e4a:	6105                	addi	sp,sp,32
    80002e4c:	8082                	ret

0000000080002e4e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e4e:	1101                	addi	sp,sp,-32
    80002e50:	ec06                	sd	ra,24(sp)
    80002e52:	e822                	sd	s0,16(sp)
    80002e54:	e426                	sd	s1,8(sp)
    80002e56:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e58:	00020517          	auipc	a0,0x20
    80002e5c:	26050513          	addi	a0,a0,608 # 800230b8 <tickslock>
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	dc4080e7          	jalr	-572(ra) # 80000c24 <acquire>
  xticks = ticks;
    80002e68:	00006797          	auipc	a5,0x6
    80002e6c:	1c878793          	addi	a5,a5,456 # 80009030 <ticks>
    80002e70:	4384                	lw	s1,0(a5)
  release(&tickslock);
    80002e72:	00020517          	auipc	a0,0x20
    80002e76:	24650513          	addi	a0,a0,582 # 800230b8 <tickslock>
    80002e7a:	ffffe097          	auipc	ra,0xffffe
    80002e7e:	e5e080e7          	jalr	-418(ra) # 80000cd8 <release>
  return xticks;
}
    80002e82:	02049513          	slli	a0,s1,0x20
    80002e86:	9101                	srli	a0,a0,0x20
    80002e88:	60e2                	ld	ra,24(sp)
    80002e8a:	6442                	ld	s0,16(sp)
    80002e8c:	64a2                	ld	s1,8(sp)
    80002e8e:	6105                	addi	sp,sp,32
    80002e90:	8082                	ret

0000000080002e92 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e92:	7179                	addi	sp,sp,-48
    80002e94:	f406                	sd	ra,40(sp)
    80002e96:	f022                	sd	s0,32(sp)
    80002e98:	ec26                	sd	s1,24(sp)
    80002e9a:	e84a                	sd	s2,16(sp)
    80002e9c:	e44e                	sd	s3,8(sp)
    80002e9e:	e052                	sd	s4,0(sp)
    80002ea0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ea2:	00005597          	auipc	a1,0x5
    80002ea6:	60658593          	addi	a1,a1,1542 # 800084a8 <syscalls+0xe8>
    80002eaa:	00020517          	auipc	a0,0x20
    80002eae:	22650513          	addi	a0,a0,550 # 800230d0 <bcache>
    80002eb2:	ffffe097          	auipc	ra,0xffffe
    80002eb6:	ce2080e7          	jalr	-798(ra) # 80000b94 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002eba:	00028797          	auipc	a5,0x28
    80002ebe:	21678793          	addi	a5,a5,534 # 8002b0d0 <bcache+0x8000>
    80002ec2:	00028717          	auipc	a4,0x28
    80002ec6:	47670713          	addi	a4,a4,1142 # 8002b338 <bcache+0x8268>
    80002eca:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002ece:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002ed2:	00020497          	auipc	s1,0x20
    80002ed6:	21648493          	addi	s1,s1,534 # 800230e8 <bcache+0x18>
    b->next = bcache.head.next;
    80002eda:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002edc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002ede:	00005a17          	auipc	s4,0x5
    80002ee2:	5d2a0a13          	addi	s4,s4,1490 # 800084b0 <syscalls+0xf0>
    b->next = bcache.head.next;
    80002ee6:	2b893783          	ld	a5,696(s2)
    80002eea:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002eec:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ef0:	85d2                	mv	a1,s4
    80002ef2:	01048513          	addi	a0,s1,16
    80002ef6:	00001097          	auipc	ra,0x1
    80002efa:	532080e7          	jalr	1330(ra) # 80004428 <initsleeplock>
    bcache.head.next->prev = b;
    80002efe:	2b893783          	ld	a5,696(s2)
    80002f02:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f04:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f08:	45848493          	addi	s1,s1,1112
    80002f0c:	fd349de3          	bne	s1,s3,80002ee6 <binit+0x54>
  }
}
    80002f10:	70a2                	ld	ra,40(sp)
    80002f12:	7402                	ld	s0,32(sp)
    80002f14:	64e2                	ld	s1,24(sp)
    80002f16:	6942                	ld	s2,16(sp)
    80002f18:	69a2                	ld	s3,8(sp)
    80002f1a:	6a02                	ld	s4,0(sp)
    80002f1c:	6145                	addi	sp,sp,48
    80002f1e:	8082                	ret

0000000080002f20 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f20:	7179                	addi	sp,sp,-48
    80002f22:	f406                	sd	ra,40(sp)
    80002f24:	f022                	sd	s0,32(sp)
    80002f26:	ec26                	sd	s1,24(sp)
    80002f28:	e84a                	sd	s2,16(sp)
    80002f2a:	e44e                	sd	s3,8(sp)
    80002f2c:	1800                	addi	s0,sp,48
    80002f2e:	89aa                	mv	s3,a0
    80002f30:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f32:	00020517          	auipc	a0,0x20
    80002f36:	19e50513          	addi	a0,a0,414 # 800230d0 <bcache>
    80002f3a:	ffffe097          	auipc	ra,0xffffe
    80002f3e:	cea080e7          	jalr	-790(ra) # 80000c24 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f42:	00028797          	auipc	a5,0x28
    80002f46:	18e78793          	addi	a5,a5,398 # 8002b0d0 <bcache+0x8000>
    80002f4a:	2b87b483          	ld	s1,696(a5)
    80002f4e:	00028797          	auipc	a5,0x28
    80002f52:	3ea78793          	addi	a5,a5,1002 # 8002b338 <bcache+0x8268>
    80002f56:	02f48f63          	beq	s1,a5,80002f94 <bread+0x74>
    80002f5a:	873e                	mv	a4,a5
    80002f5c:	a021                	j	80002f64 <bread+0x44>
    80002f5e:	68a4                	ld	s1,80(s1)
    80002f60:	02e48a63          	beq	s1,a4,80002f94 <bread+0x74>
    if(b->dev == dev && b->blockno == blockno){
    80002f64:	449c                	lw	a5,8(s1)
    80002f66:	ff379ce3          	bne	a5,s3,80002f5e <bread+0x3e>
    80002f6a:	44dc                	lw	a5,12(s1)
    80002f6c:	ff2799e3          	bne	a5,s2,80002f5e <bread+0x3e>
      b->refcnt++;
    80002f70:	40bc                	lw	a5,64(s1)
    80002f72:	2785                	addiw	a5,a5,1
    80002f74:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f76:	00020517          	auipc	a0,0x20
    80002f7a:	15a50513          	addi	a0,a0,346 # 800230d0 <bcache>
    80002f7e:	ffffe097          	auipc	ra,0xffffe
    80002f82:	d5a080e7          	jalr	-678(ra) # 80000cd8 <release>
      acquiresleep(&b->lock);
    80002f86:	01048513          	addi	a0,s1,16
    80002f8a:	00001097          	auipc	ra,0x1
    80002f8e:	4d8080e7          	jalr	1240(ra) # 80004462 <acquiresleep>
      return b;
    80002f92:	a8b1                	j	80002fee <bread+0xce>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f94:	00028797          	auipc	a5,0x28
    80002f98:	13c78793          	addi	a5,a5,316 # 8002b0d0 <bcache+0x8000>
    80002f9c:	2b07b483          	ld	s1,688(a5)
    80002fa0:	00028797          	auipc	a5,0x28
    80002fa4:	39878793          	addi	a5,a5,920 # 8002b338 <bcache+0x8268>
    80002fa8:	04f48d63          	beq	s1,a5,80003002 <bread+0xe2>
    if(b->refcnt == 0) {
    80002fac:	40bc                	lw	a5,64(s1)
    80002fae:	cb91                	beqz	a5,80002fc2 <bread+0xa2>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fb0:	00028717          	auipc	a4,0x28
    80002fb4:	38870713          	addi	a4,a4,904 # 8002b338 <bcache+0x8268>
    80002fb8:	64a4                	ld	s1,72(s1)
    80002fba:	04e48463          	beq	s1,a4,80003002 <bread+0xe2>
    if(b->refcnt == 0) {
    80002fbe:	40bc                	lw	a5,64(s1)
    80002fc0:	ffe5                	bnez	a5,80002fb8 <bread+0x98>
      b->dev = dev;
    80002fc2:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fc6:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fca:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fce:	4785                	li	a5,1
    80002fd0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fd2:	00020517          	auipc	a0,0x20
    80002fd6:	0fe50513          	addi	a0,a0,254 # 800230d0 <bcache>
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	cfe080e7          	jalr	-770(ra) # 80000cd8 <release>
      acquiresleep(&b->lock);
    80002fe2:	01048513          	addi	a0,s1,16
    80002fe6:	00001097          	auipc	ra,0x1
    80002fea:	47c080e7          	jalr	1148(ra) # 80004462 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002fee:	409c                	lw	a5,0(s1)
    80002ff0:	c38d                	beqz	a5,80003012 <bread+0xf2>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002ff2:	8526                	mv	a0,s1
    80002ff4:	70a2                	ld	ra,40(sp)
    80002ff6:	7402                	ld	s0,32(sp)
    80002ff8:	64e2                	ld	s1,24(sp)
    80002ffa:	6942                	ld	s2,16(sp)
    80002ffc:	69a2                	ld	s3,8(sp)
    80002ffe:	6145                	addi	sp,sp,48
    80003000:	8082                	ret
  panic("bget: no buffers");
    80003002:	00005517          	auipc	a0,0x5
    80003006:	4b650513          	addi	a0,a0,1206 # 800084b8 <syscalls+0xf8>
    8000300a:	ffffd097          	auipc	ra,0xffffd
    8000300e:	54e080e7          	jalr	1358(ra) # 80000558 <panic>
    virtio_disk_rw(b, 0);
    80003012:	4581                	li	a1,0
    80003014:	8526                	mv	a0,s1
    80003016:	00003097          	auipc	ra,0x3
    8000301a:	510080e7          	jalr	1296(ra) # 80006526 <virtio_disk_rw>
    b->valid = 1;
    8000301e:	4785                	li	a5,1
    80003020:	c09c                	sw	a5,0(s1)
  return b;
    80003022:	bfc1                	j	80002ff2 <bread+0xd2>

0000000080003024 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003024:	1101                	addi	sp,sp,-32
    80003026:	ec06                	sd	ra,24(sp)
    80003028:	e822                	sd	s0,16(sp)
    8000302a:	e426                	sd	s1,8(sp)
    8000302c:	1000                	addi	s0,sp,32
    8000302e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003030:	0541                	addi	a0,a0,16
    80003032:	00001097          	auipc	ra,0x1
    80003036:	4ca080e7          	jalr	1226(ra) # 800044fc <holdingsleep>
    8000303a:	cd01                	beqz	a0,80003052 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000303c:	4585                	li	a1,1
    8000303e:	8526                	mv	a0,s1
    80003040:	00003097          	auipc	ra,0x3
    80003044:	4e6080e7          	jalr	1254(ra) # 80006526 <virtio_disk_rw>
}
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	64a2                	ld	s1,8(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret
    panic("bwrite");
    80003052:	00005517          	auipc	a0,0x5
    80003056:	47e50513          	addi	a0,a0,1150 # 800084d0 <syscalls+0x110>
    8000305a:	ffffd097          	auipc	ra,0xffffd
    8000305e:	4fe080e7          	jalr	1278(ra) # 80000558 <panic>

0000000080003062 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003062:	1101                	addi	sp,sp,-32
    80003064:	ec06                	sd	ra,24(sp)
    80003066:	e822                	sd	s0,16(sp)
    80003068:	e426                	sd	s1,8(sp)
    8000306a:	e04a                	sd	s2,0(sp)
    8000306c:	1000                	addi	s0,sp,32
    8000306e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003070:	01050913          	addi	s2,a0,16
    80003074:	854a                	mv	a0,s2
    80003076:	00001097          	auipc	ra,0x1
    8000307a:	486080e7          	jalr	1158(ra) # 800044fc <holdingsleep>
    8000307e:	c92d                	beqz	a0,800030f0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003080:	854a                	mv	a0,s2
    80003082:	00001097          	auipc	ra,0x1
    80003086:	436080e7          	jalr	1078(ra) # 800044b8 <releasesleep>

  acquire(&bcache.lock);
    8000308a:	00020517          	auipc	a0,0x20
    8000308e:	04650513          	addi	a0,a0,70 # 800230d0 <bcache>
    80003092:	ffffe097          	auipc	ra,0xffffe
    80003096:	b92080e7          	jalr	-1134(ra) # 80000c24 <acquire>
  b->refcnt--;
    8000309a:	40bc                	lw	a5,64(s1)
    8000309c:	37fd                	addiw	a5,a5,-1
    8000309e:	0007871b          	sext.w	a4,a5
    800030a2:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030a4:	eb05                	bnez	a4,800030d4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030a6:	68bc                	ld	a5,80(s1)
    800030a8:	64b8                	ld	a4,72(s1)
    800030aa:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030ac:	64bc                	ld	a5,72(s1)
    800030ae:	68b8                	ld	a4,80(s1)
    800030b0:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030b2:	00028797          	auipc	a5,0x28
    800030b6:	01e78793          	addi	a5,a5,30 # 8002b0d0 <bcache+0x8000>
    800030ba:	2b87b703          	ld	a4,696(a5)
    800030be:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030c0:	00028717          	auipc	a4,0x28
    800030c4:	27870713          	addi	a4,a4,632 # 8002b338 <bcache+0x8268>
    800030c8:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030ca:	2b87b703          	ld	a4,696(a5)
    800030ce:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030d0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030d4:	00020517          	auipc	a0,0x20
    800030d8:	ffc50513          	addi	a0,a0,-4 # 800230d0 <bcache>
    800030dc:	ffffe097          	auipc	ra,0xffffe
    800030e0:	bfc080e7          	jalr	-1028(ra) # 80000cd8 <release>
}
    800030e4:	60e2                	ld	ra,24(sp)
    800030e6:	6442                	ld	s0,16(sp)
    800030e8:	64a2                	ld	s1,8(sp)
    800030ea:	6902                	ld	s2,0(sp)
    800030ec:	6105                	addi	sp,sp,32
    800030ee:	8082                	ret
    panic("brelse");
    800030f0:	00005517          	auipc	a0,0x5
    800030f4:	3e850513          	addi	a0,a0,1000 # 800084d8 <syscalls+0x118>
    800030f8:	ffffd097          	auipc	ra,0xffffd
    800030fc:	460080e7          	jalr	1120(ra) # 80000558 <panic>

0000000080003100 <bpin>:

void
bpin(struct buf *b) {
    80003100:	1101                	addi	sp,sp,-32
    80003102:	ec06                	sd	ra,24(sp)
    80003104:	e822                	sd	s0,16(sp)
    80003106:	e426                	sd	s1,8(sp)
    80003108:	1000                	addi	s0,sp,32
    8000310a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000310c:	00020517          	auipc	a0,0x20
    80003110:	fc450513          	addi	a0,a0,-60 # 800230d0 <bcache>
    80003114:	ffffe097          	auipc	ra,0xffffe
    80003118:	b10080e7          	jalr	-1264(ra) # 80000c24 <acquire>
  b->refcnt++;
    8000311c:	40bc                	lw	a5,64(s1)
    8000311e:	2785                	addiw	a5,a5,1
    80003120:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003122:	00020517          	auipc	a0,0x20
    80003126:	fae50513          	addi	a0,a0,-82 # 800230d0 <bcache>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	bae080e7          	jalr	-1106(ra) # 80000cd8 <release>
}
    80003132:	60e2                	ld	ra,24(sp)
    80003134:	6442                	ld	s0,16(sp)
    80003136:	64a2                	ld	s1,8(sp)
    80003138:	6105                	addi	sp,sp,32
    8000313a:	8082                	ret

000000008000313c <bunpin>:

void
bunpin(struct buf *b) {
    8000313c:	1101                	addi	sp,sp,-32
    8000313e:	ec06                	sd	ra,24(sp)
    80003140:	e822                	sd	s0,16(sp)
    80003142:	e426                	sd	s1,8(sp)
    80003144:	1000                	addi	s0,sp,32
    80003146:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003148:	00020517          	auipc	a0,0x20
    8000314c:	f8850513          	addi	a0,a0,-120 # 800230d0 <bcache>
    80003150:	ffffe097          	auipc	ra,0xffffe
    80003154:	ad4080e7          	jalr	-1324(ra) # 80000c24 <acquire>
  b->refcnt--;
    80003158:	40bc                	lw	a5,64(s1)
    8000315a:	37fd                	addiw	a5,a5,-1
    8000315c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000315e:	00020517          	auipc	a0,0x20
    80003162:	f7250513          	addi	a0,a0,-142 # 800230d0 <bcache>
    80003166:	ffffe097          	auipc	ra,0xffffe
    8000316a:	b72080e7          	jalr	-1166(ra) # 80000cd8 <release>
}
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	64a2                	ld	s1,8(sp)
    80003174:	6105                	addi	sp,sp,32
    80003176:	8082                	ret

0000000080003178 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003178:	1101                	addi	sp,sp,-32
    8000317a:	ec06                	sd	ra,24(sp)
    8000317c:	e822                	sd	s0,16(sp)
    8000317e:	e426                	sd	s1,8(sp)
    80003180:	e04a                	sd	s2,0(sp)
    80003182:	1000                	addi	s0,sp,32
    80003184:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003186:	00d5d59b          	srliw	a1,a1,0xd
    8000318a:	00028797          	auipc	a5,0x28
    8000318e:	60678793          	addi	a5,a5,1542 # 8002b790 <sb>
    80003192:	4fdc                	lw	a5,28(a5)
    80003194:	9dbd                	addw	a1,a1,a5
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	d8a080e7          	jalr	-630(ra) # 80002f20 <bread>
  bi = b % BPB;
    8000319e:	2481                	sext.w	s1,s1
  m = 1 << (bi % 8);
    800031a0:	0074f793          	andi	a5,s1,7
    800031a4:	4705                	li	a4,1
    800031a6:	00f7173b          	sllw	a4,a4,a5
  bi = b % BPB;
    800031aa:	6789                	lui	a5,0x2
    800031ac:	17fd                	addi	a5,a5,-1
    800031ae:	8cfd                	and	s1,s1,a5
  if((bp->data[bi/8] & m) == 0)
    800031b0:	41f4d79b          	sraiw	a5,s1,0x1f
    800031b4:	01d7d79b          	srliw	a5,a5,0x1d
    800031b8:	9fa5                	addw	a5,a5,s1
    800031ba:	4037d79b          	sraiw	a5,a5,0x3
    800031be:	00f506b3          	add	a3,a0,a5
    800031c2:	0586c683          	lbu	a3,88(a3)
    800031c6:	00d77633          	and	a2,a4,a3
    800031ca:	c61d                	beqz	a2,800031f8 <bfree+0x80>
    800031cc:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031ce:	97aa                	add	a5,a5,a0
    800031d0:	fff74713          	not	a4,a4
    800031d4:	8f75                	and	a4,a4,a3
    800031d6:	04e78c23          	sb	a4,88(a5) # 2058 <_entry-0x7fffdfa8>
  log_write(bp);
    800031da:	00001097          	auipc	ra,0x1
    800031de:	14a080e7          	jalr	330(ra) # 80004324 <log_write>
  brelse(bp);
    800031e2:	854a                	mv	a0,s2
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	e7e080e7          	jalr	-386(ra) # 80003062 <brelse>
}
    800031ec:	60e2                	ld	ra,24(sp)
    800031ee:	6442                	ld	s0,16(sp)
    800031f0:	64a2                	ld	s1,8(sp)
    800031f2:	6902                	ld	s2,0(sp)
    800031f4:	6105                	addi	sp,sp,32
    800031f6:	8082                	ret
    panic("freeing free block");
    800031f8:	00005517          	auipc	a0,0x5
    800031fc:	2e850513          	addi	a0,a0,744 # 800084e0 <syscalls+0x120>
    80003200:	ffffd097          	auipc	ra,0xffffd
    80003204:	358080e7          	jalr	856(ra) # 80000558 <panic>

0000000080003208 <balloc>:
{
    80003208:	711d                	addi	sp,sp,-96
    8000320a:	ec86                	sd	ra,88(sp)
    8000320c:	e8a2                	sd	s0,80(sp)
    8000320e:	e4a6                	sd	s1,72(sp)
    80003210:	e0ca                	sd	s2,64(sp)
    80003212:	fc4e                	sd	s3,56(sp)
    80003214:	f852                	sd	s4,48(sp)
    80003216:	f456                	sd	s5,40(sp)
    80003218:	f05a                	sd	s6,32(sp)
    8000321a:	ec5e                	sd	s7,24(sp)
    8000321c:	e862                	sd	s8,16(sp)
    8000321e:	e466                	sd	s9,8(sp)
    80003220:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003222:	00028797          	auipc	a5,0x28
    80003226:	56e78793          	addi	a5,a5,1390 # 8002b790 <sb>
    8000322a:	43dc                	lw	a5,4(a5)
    8000322c:	10078e63          	beqz	a5,80003348 <balloc+0x140>
    80003230:	8baa                	mv	s7,a0
    80003232:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003234:	00028b17          	auipc	s6,0x28
    80003238:	55cb0b13          	addi	s6,s6,1372 # 8002b790 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000323c:	4c05                	li	s8,1
      m = 1 << (bi % 8);
    8000323e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003240:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003242:	6c89                	lui	s9,0x2
    80003244:	a079                	j	800032d2 <balloc+0xca>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003246:	8942                	mv	s2,a6
      m = 1 << (bi % 8);
    80003248:	4705                	li	a4,1
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000324a:	4681                	li	a3,0
        bp->data[bi/8] |= m;  // Mark block in use.
    8000324c:	96a6                	add	a3,a3,s1
    8000324e:	8f51                	or	a4,a4,a2
    80003250:	04e68c23          	sb	a4,88(a3)
        log_write(bp);
    80003254:	8526                	mv	a0,s1
    80003256:	00001097          	auipc	ra,0x1
    8000325a:	0ce080e7          	jalr	206(ra) # 80004324 <log_write>
        brelse(bp);
    8000325e:	8526                	mv	a0,s1
    80003260:	00000097          	auipc	ra,0x0
    80003264:	e02080e7          	jalr	-510(ra) # 80003062 <brelse>
  bp = bread(dev, bno);
    80003268:	85ca                	mv	a1,s2
    8000326a:	855e                	mv	a0,s7
    8000326c:	00000097          	auipc	ra,0x0
    80003270:	cb4080e7          	jalr	-844(ra) # 80002f20 <bread>
    80003274:	84aa                	mv	s1,a0
  memset(bp->data, 0, BSIZE);
    80003276:	40000613          	li	a2,1024
    8000327a:	4581                	li	a1,0
    8000327c:	05850513          	addi	a0,a0,88
    80003280:	ffffe097          	auipc	ra,0xffffe
    80003284:	aa0080e7          	jalr	-1376(ra) # 80000d20 <memset>
  log_write(bp);
    80003288:	8526                	mv	a0,s1
    8000328a:	00001097          	auipc	ra,0x1
    8000328e:	09a080e7          	jalr	154(ra) # 80004324 <log_write>
  brelse(bp);
    80003292:	8526                	mv	a0,s1
    80003294:	00000097          	auipc	ra,0x0
    80003298:	dce080e7          	jalr	-562(ra) # 80003062 <brelse>
}
    8000329c:	854a                	mv	a0,s2
    8000329e:	60e6                	ld	ra,88(sp)
    800032a0:	6446                	ld	s0,80(sp)
    800032a2:	64a6                	ld	s1,72(sp)
    800032a4:	6906                	ld	s2,64(sp)
    800032a6:	79e2                	ld	s3,56(sp)
    800032a8:	7a42                	ld	s4,48(sp)
    800032aa:	7aa2                	ld	s5,40(sp)
    800032ac:	7b02                	ld	s6,32(sp)
    800032ae:	6be2                	ld	s7,24(sp)
    800032b0:	6c42                	ld	s8,16(sp)
    800032b2:	6ca2                	ld	s9,8(sp)
    800032b4:	6125                	addi	sp,sp,96
    800032b6:	8082                	ret
    brelse(bp);
    800032b8:	8526                	mv	a0,s1
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	da8080e7          	jalr	-600(ra) # 80003062 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032c2:	015c87bb          	addw	a5,s9,s5
    800032c6:	00078a9b          	sext.w	s5,a5
    800032ca:	004b2703          	lw	a4,4(s6)
    800032ce:	06eafd63          	bleu	a4,s5,80003348 <balloc+0x140>
    bp = bread(dev, BBLOCK(b, sb));
    800032d2:	41fad79b          	sraiw	a5,s5,0x1f
    800032d6:	0137d79b          	srliw	a5,a5,0x13
    800032da:	015787bb          	addw	a5,a5,s5
    800032de:	40d7d79b          	sraiw	a5,a5,0xd
    800032e2:	01cb2583          	lw	a1,28(s6)
    800032e6:	9dbd                	addw	a1,a1,a5
    800032e8:	855e                	mv	a0,s7
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	c36080e7          	jalr	-970(ra) # 80002f20 <bread>
    800032f2:	84aa                	mv	s1,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f4:	000a881b          	sext.w	a6,s5
    800032f8:	004b2503          	lw	a0,4(s6)
    800032fc:	faa87ee3          	bleu	a0,a6,800032b8 <balloc+0xb0>
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003300:	0584c603          	lbu	a2,88(s1)
    80003304:	00167793          	andi	a5,a2,1
    80003308:	df9d                	beqz	a5,80003246 <balloc+0x3e>
    8000330a:	4105053b          	subw	a0,a0,a6
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330e:	87e2                	mv	a5,s8
    80003310:	0107893b          	addw	s2,a5,a6
    80003314:	faa782e3          	beq	a5,a0,800032b8 <balloc+0xb0>
      m = 1 << (bi % 8);
    80003318:	41f7d71b          	sraiw	a4,a5,0x1f
    8000331c:	01d7561b          	srliw	a2,a4,0x1d
    80003320:	00f606bb          	addw	a3,a2,a5
    80003324:	0076f713          	andi	a4,a3,7
    80003328:	9f11                	subw	a4,a4,a2
    8000332a:	00e9973b          	sllw	a4,s3,a4
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000332e:	4036d69b          	sraiw	a3,a3,0x3
    80003332:	00d48633          	add	a2,s1,a3
    80003336:	05864603          	lbu	a2,88(a2)
    8000333a:	00c775b3          	and	a1,a4,a2
    8000333e:	d599                	beqz	a1,8000324c <balloc+0x44>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003340:	2785                	addiw	a5,a5,1
    80003342:	fd4797e3          	bne	a5,s4,80003310 <balloc+0x108>
    80003346:	bf8d                	j	800032b8 <balloc+0xb0>
  panic("balloc: out of blocks");
    80003348:	00005517          	auipc	a0,0x5
    8000334c:	1b050513          	addi	a0,a0,432 # 800084f8 <syscalls+0x138>
    80003350:	ffffd097          	auipc	ra,0xffffd
    80003354:	208080e7          	jalr	520(ra) # 80000558 <panic>

0000000080003358 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003358:	7179                	addi	sp,sp,-48
    8000335a:	f406                	sd	ra,40(sp)
    8000335c:	f022                	sd	s0,32(sp)
    8000335e:	ec26                	sd	s1,24(sp)
    80003360:	e84a                	sd	s2,16(sp)
    80003362:	e44e                	sd	s3,8(sp)
    80003364:	e052                	sd	s4,0(sp)
    80003366:	1800                	addi	s0,sp,48
    80003368:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000336a:	47ad                	li	a5,11
    8000336c:	04b7fe63          	bleu	a1,a5,800033c8 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003370:	ff45849b          	addiw	s1,a1,-12
    80003374:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003378:	0ff00793          	li	a5,255
    8000337c:	0ae7e363          	bltu	a5,a4,80003422 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003380:	08052583          	lw	a1,128(a0)
    80003384:	c5ad                	beqz	a1,800033ee <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003386:	0009a503          	lw	a0,0(s3)
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	b96080e7          	jalr	-1130(ra) # 80002f20 <bread>
    80003392:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003394:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003398:	02049593          	slli	a1,s1,0x20
    8000339c:	9181                	srli	a1,a1,0x20
    8000339e:	058a                	slli	a1,a1,0x2
    800033a0:	00b784b3          	add	s1,a5,a1
    800033a4:	0004a903          	lw	s2,0(s1)
    800033a8:	04090d63          	beqz	s2,80003402 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033ac:	8552                	mv	a0,s4
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	cb4080e7          	jalr	-844(ra) # 80003062 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033b6:	854a                	mv	a0,s2
    800033b8:	70a2                	ld	ra,40(sp)
    800033ba:	7402                	ld	s0,32(sp)
    800033bc:	64e2                	ld	s1,24(sp)
    800033be:	6942                	ld	s2,16(sp)
    800033c0:	69a2                	ld	s3,8(sp)
    800033c2:	6a02                	ld	s4,0(sp)
    800033c4:	6145                	addi	sp,sp,48
    800033c6:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033c8:	02059493          	slli	s1,a1,0x20
    800033cc:	9081                	srli	s1,s1,0x20
    800033ce:	048a                	slli	s1,s1,0x2
    800033d0:	94aa                	add	s1,s1,a0
    800033d2:	0504a903          	lw	s2,80(s1)
    800033d6:	fe0910e3          	bnez	s2,800033b6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033da:	4108                	lw	a0,0(a0)
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	e2c080e7          	jalr	-468(ra) # 80003208 <balloc>
    800033e4:	0005091b          	sext.w	s2,a0
    800033e8:	0524a823          	sw	s2,80(s1)
    800033ec:	b7e9                	j	800033b6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033ee:	4108                	lw	a0,0(a0)
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	e18080e7          	jalr	-488(ra) # 80003208 <balloc>
    800033f8:	0005059b          	sext.w	a1,a0
    800033fc:	08b9a023          	sw	a1,128(s3)
    80003400:	b759                	j	80003386 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003402:	0009a503          	lw	a0,0(s3)
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	e02080e7          	jalr	-510(ra) # 80003208 <balloc>
    8000340e:	0005091b          	sext.w	s2,a0
    80003412:	0124a023          	sw	s2,0(s1)
      log_write(bp);
    80003416:	8552                	mv	a0,s4
    80003418:	00001097          	auipc	ra,0x1
    8000341c:	f0c080e7          	jalr	-244(ra) # 80004324 <log_write>
    80003420:	b771                	j	800033ac <bmap+0x54>
  panic("bmap: out of range");
    80003422:	00005517          	auipc	a0,0x5
    80003426:	0ee50513          	addi	a0,a0,238 # 80008510 <syscalls+0x150>
    8000342a:	ffffd097          	auipc	ra,0xffffd
    8000342e:	12e080e7          	jalr	302(ra) # 80000558 <panic>

0000000080003432 <iget>:
{
    80003432:	7179                	addi	sp,sp,-48
    80003434:	f406                	sd	ra,40(sp)
    80003436:	f022                	sd	s0,32(sp)
    80003438:	ec26                	sd	s1,24(sp)
    8000343a:	e84a                	sd	s2,16(sp)
    8000343c:	e44e                	sd	s3,8(sp)
    8000343e:	e052                	sd	s4,0(sp)
    80003440:	1800                	addi	s0,sp,48
    80003442:	89aa                	mv	s3,a0
    80003444:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003446:	00028517          	auipc	a0,0x28
    8000344a:	36a50513          	addi	a0,a0,874 # 8002b7b0 <icache>
    8000344e:	ffffd097          	auipc	ra,0xffffd
    80003452:	7d6080e7          	jalr	2006(ra) # 80000c24 <acquire>
  empty = 0;
    80003456:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003458:	00028497          	auipc	s1,0x28
    8000345c:	37048493          	addi	s1,s1,880 # 8002b7c8 <icache+0x18>
    80003460:	0002a697          	auipc	a3,0x2a
    80003464:	df868693          	addi	a3,a3,-520 # 8002d258 <log>
    80003468:	a039                	j	80003476 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000346a:	02090b63          	beqz	s2,800034a0 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000346e:	08848493          	addi	s1,s1,136
    80003472:	02d48a63          	beq	s1,a3,800034a6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003476:	449c                	lw	a5,8(s1)
    80003478:	fef059e3          	blez	a5,8000346a <iget+0x38>
    8000347c:	4098                	lw	a4,0(s1)
    8000347e:	ff3716e3          	bne	a4,s3,8000346a <iget+0x38>
    80003482:	40d8                	lw	a4,4(s1)
    80003484:	ff4713e3          	bne	a4,s4,8000346a <iget+0x38>
      ip->ref++;
    80003488:	2785                	addiw	a5,a5,1
    8000348a:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    8000348c:	00028517          	auipc	a0,0x28
    80003490:	32450513          	addi	a0,a0,804 # 8002b7b0 <icache>
    80003494:	ffffe097          	auipc	ra,0xffffe
    80003498:	844080e7          	jalr	-1980(ra) # 80000cd8 <release>
      return ip;
    8000349c:	8926                	mv	s2,s1
    8000349e:	a03d                	j	800034cc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034a0:	f7f9                	bnez	a5,8000346e <iget+0x3c>
    800034a2:	8926                	mv	s2,s1
    800034a4:	b7e9                	j	8000346e <iget+0x3c>
  if(empty == 0)
    800034a6:	02090c63          	beqz	s2,800034de <iget+0xac>
  ip->dev = dev;
    800034aa:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034ae:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034b2:	4785                	li	a5,1
    800034b4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034b8:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034bc:	00028517          	auipc	a0,0x28
    800034c0:	2f450513          	addi	a0,a0,756 # 8002b7b0 <icache>
    800034c4:	ffffe097          	auipc	ra,0xffffe
    800034c8:	814080e7          	jalr	-2028(ra) # 80000cd8 <release>
}
    800034cc:	854a                	mv	a0,s2
    800034ce:	70a2                	ld	ra,40(sp)
    800034d0:	7402                	ld	s0,32(sp)
    800034d2:	64e2                	ld	s1,24(sp)
    800034d4:	6942                	ld	s2,16(sp)
    800034d6:	69a2                	ld	s3,8(sp)
    800034d8:	6a02                	ld	s4,0(sp)
    800034da:	6145                	addi	sp,sp,48
    800034dc:	8082                	ret
    panic("iget: no inodes");
    800034de:	00005517          	auipc	a0,0x5
    800034e2:	04a50513          	addi	a0,a0,74 # 80008528 <syscalls+0x168>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	072080e7          	jalr	114(ra) # 80000558 <panic>

00000000800034ee <fsinit>:
fsinit(int dev) {
    800034ee:	7179                	addi	sp,sp,-48
    800034f0:	f406                	sd	ra,40(sp)
    800034f2:	f022                	sd	s0,32(sp)
    800034f4:	ec26                	sd	s1,24(sp)
    800034f6:	e84a                	sd	s2,16(sp)
    800034f8:	e44e                	sd	s3,8(sp)
    800034fa:	1800                	addi	s0,sp,48
    800034fc:	89aa                	mv	s3,a0
  bp = bread(dev, 1);
    800034fe:	4585                	li	a1,1
    80003500:	00000097          	auipc	ra,0x0
    80003504:	a20080e7          	jalr	-1504(ra) # 80002f20 <bread>
    80003508:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000350a:	00028497          	auipc	s1,0x28
    8000350e:	28648493          	addi	s1,s1,646 # 8002b790 <sb>
    80003512:	02000613          	li	a2,32
    80003516:	05850593          	addi	a1,a0,88
    8000351a:	8526                	mv	a0,s1
    8000351c:	ffffe097          	auipc	ra,0xffffe
    80003520:	870080e7          	jalr	-1936(ra) # 80000d8c <memmove>
  brelse(bp);
    80003524:	854a                	mv	a0,s2
    80003526:	00000097          	auipc	ra,0x0
    8000352a:	b3c080e7          	jalr	-1220(ra) # 80003062 <brelse>
  if(sb.magic != FSMAGIC)
    8000352e:	4098                	lw	a4,0(s1)
    80003530:	102037b7          	lui	a5,0x10203
    80003534:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003538:	02f71263          	bne	a4,a5,8000355c <fsinit+0x6e>
  initlog(dev, &sb);
    8000353c:	00028597          	auipc	a1,0x28
    80003540:	25458593          	addi	a1,a1,596 # 8002b790 <sb>
    80003544:	854e                	mv	a0,s3
    80003546:	00001097          	auipc	ra,0x1
    8000354a:	b5c080e7          	jalr	-1188(ra) # 800040a2 <initlog>
}
    8000354e:	70a2                	ld	ra,40(sp)
    80003550:	7402                	ld	s0,32(sp)
    80003552:	64e2                	ld	s1,24(sp)
    80003554:	6942                	ld	s2,16(sp)
    80003556:	69a2                	ld	s3,8(sp)
    80003558:	6145                	addi	sp,sp,48
    8000355a:	8082                	ret
    panic("invalid file system");
    8000355c:	00005517          	auipc	a0,0x5
    80003560:	fdc50513          	addi	a0,a0,-36 # 80008538 <syscalls+0x178>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	ff4080e7          	jalr	-12(ra) # 80000558 <panic>

000000008000356c <iinit>:
{
    8000356c:	7179                	addi	sp,sp,-48
    8000356e:	f406                	sd	ra,40(sp)
    80003570:	f022                	sd	s0,32(sp)
    80003572:	ec26                	sd	s1,24(sp)
    80003574:	e84a                	sd	s2,16(sp)
    80003576:	e44e                	sd	s3,8(sp)
    80003578:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    8000357a:	00005597          	auipc	a1,0x5
    8000357e:	fd658593          	addi	a1,a1,-42 # 80008550 <syscalls+0x190>
    80003582:	00028517          	auipc	a0,0x28
    80003586:	22e50513          	addi	a0,a0,558 # 8002b7b0 <icache>
    8000358a:	ffffd097          	auipc	ra,0xffffd
    8000358e:	60a080e7          	jalr	1546(ra) # 80000b94 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003592:	00028497          	auipc	s1,0x28
    80003596:	24648493          	addi	s1,s1,582 # 8002b7d8 <icache+0x28>
    8000359a:	0002a997          	auipc	s3,0x2a
    8000359e:	cce98993          	addi	s3,s3,-818 # 8002d268 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035a2:	00005917          	auipc	s2,0x5
    800035a6:	fb690913          	addi	s2,s2,-74 # 80008558 <syscalls+0x198>
    800035aa:	85ca                	mv	a1,s2
    800035ac:	8526                	mv	a0,s1
    800035ae:	00001097          	auipc	ra,0x1
    800035b2:	e7a080e7          	jalr	-390(ra) # 80004428 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035b6:	08848493          	addi	s1,s1,136
    800035ba:	ff3498e3          	bne	s1,s3,800035aa <iinit+0x3e>
}
    800035be:	70a2                	ld	ra,40(sp)
    800035c0:	7402                	ld	s0,32(sp)
    800035c2:	64e2                	ld	s1,24(sp)
    800035c4:	6942                	ld	s2,16(sp)
    800035c6:	69a2                	ld	s3,8(sp)
    800035c8:	6145                	addi	sp,sp,48
    800035ca:	8082                	ret

00000000800035cc <ialloc>:
{
    800035cc:	715d                	addi	sp,sp,-80
    800035ce:	e486                	sd	ra,72(sp)
    800035d0:	e0a2                	sd	s0,64(sp)
    800035d2:	fc26                	sd	s1,56(sp)
    800035d4:	f84a                	sd	s2,48(sp)
    800035d6:	f44e                	sd	s3,40(sp)
    800035d8:	f052                	sd	s4,32(sp)
    800035da:	ec56                	sd	s5,24(sp)
    800035dc:	e85a                	sd	s6,16(sp)
    800035de:	e45e                	sd	s7,8(sp)
    800035e0:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035e2:	00028797          	auipc	a5,0x28
    800035e6:	1ae78793          	addi	a5,a5,430 # 8002b790 <sb>
    800035ea:	47d8                	lw	a4,12(a5)
    800035ec:	4785                	li	a5,1
    800035ee:	04e7fa63          	bleu	a4,a5,80003642 <ialloc+0x76>
    800035f2:	8a2a                	mv	s4,a0
    800035f4:	8b2e                	mv	s6,a1
    800035f6:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035f8:	00028997          	auipc	s3,0x28
    800035fc:	19898993          	addi	s3,s3,408 # 8002b790 <sb>
    80003600:	00048a9b          	sext.w	s5,s1
    80003604:	0044d593          	srli	a1,s1,0x4
    80003608:	0189a783          	lw	a5,24(s3)
    8000360c:	9dbd                	addw	a1,a1,a5
    8000360e:	8552                	mv	a0,s4
    80003610:	00000097          	auipc	ra,0x0
    80003614:	910080e7          	jalr	-1776(ra) # 80002f20 <bread>
    80003618:	8baa                	mv	s7,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000361a:	05850913          	addi	s2,a0,88
    8000361e:	00f4f793          	andi	a5,s1,15
    80003622:	079a                	slli	a5,a5,0x6
    80003624:	993e                	add	s2,s2,a5
    if(dip->type == 0){  // a free inode
    80003626:	00091783          	lh	a5,0(s2)
    8000362a:	c785                	beqz	a5,80003652 <ialloc+0x86>
    brelse(bp);
    8000362c:	00000097          	auipc	ra,0x0
    80003630:	a36080e7          	jalr	-1482(ra) # 80003062 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003634:	0485                	addi	s1,s1,1
    80003636:	00c9a703          	lw	a4,12(s3)
    8000363a:	0004879b          	sext.w	a5,s1
    8000363e:	fce7e1e3          	bltu	a5,a4,80003600 <ialloc+0x34>
  panic("ialloc: no inodes");
    80003642:	00005517          	auipc	a0,0x5
    80003646:	f1e50513          	addi	a0,a0,-226 # 80008560 <syscalls+0x1a0>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	f0e080e7          	jalr	-242(ra) # 80000558 <panic>
      memset(dip, 0, sizeof(*dip));
    80003652:	04000613          	li	a2,64
    80003656:	4581                	li	a1,0
    80003658:	854a                	mv	a0,s2
    8000365a:	ffffd097          	auipc	ra,0xffffd
    8000365e:	6c6080e7          	jalr	1734(ra) # 80000d20 <memset>
      dip->type = type;
    80003662:	01691023          	sh	s6,0(s2)
      log_write(bp);   // mark it allocated on the disk
    80003666:	855e                	mv	a0,s7
    80003668:	00001097          	auipc	ra,0x1
    8000366c:	cbc080e7          	jalr	-836(ra) # 80004324 <log_write>
      brelse(bp);
    80003670:	855e                	mv	a0,s7
    80003672:	00000097          	auipc	ra,0x0
    80003676:	9f0080e7          	jalr	-1552(ra) # 80003062 <brelse>
      return iget(dev, inum);
    8000367a:	85d6                	mv	a1,s5
    8000367c:	8552                	mv	a0,s4
    8000367e:	00000097          	auipc	ra,0x0
    80003682:	db4080e7          	jalr	-588(ra) # 80003432 <iget>
}
    80003686:	60a6                	ld	ra,72(sp)
    80003688:	6406                	ld	s0,64(sp)
    8000368a:	74e2                	ld	s1,56(sp)
    8000368c:	7942                	ld	s2,48(sp)
    8000368e:	79a2                	ld	s3,40(sp)
    80003690:	7a02                	ld	s4,32(sp)
    80003692:	6ae2                	ld	s5,24(sp)
    80003694:	6b42                	ld	s6,16(sp)
    80003696:	6ba2                	ld	s7,8(sp)
    80003698:	6161                	addi	sp,sp,80
    8000369a:	8082                	ret

000000008000369c <iupdate>:
{
    8000369c:	1101                	addi	sp,sp,-32
    8000369e:	ec06                	sd	ra,24(sp)
    800036a0:	e822                	sd	s0,16(sp)
    800036a2:	e426                	sd	s1,8(sp)
    800036a4:	e04a                	sd	s2,0(sp)
    800036a6:	1000                	addi	s0,sp,32
    800036a8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036aa:	415c                	lw	a5,4(a0)
    800036ac:	0047d79b          	srliw	a5,a5,0x4
    800036b0:	00028717          	auipc	a4,0x28
    800036b4:	0e070713          	addi	a4,a4,224 # 8002b790 <sb>
    800036b8:	4f0c                	lw	a1,24(a4)
    800036ba:	9dbd                	addw	a1,a1,a5
    800036bc:	4108                	lw	a0,0(a0)
    800036be:	00000097          	auipc	ra,0x0
    800036c2:	862080e7          	jalr	-1950(ra) # 80002f20 <bread>
    800036c6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036c8:	05850513          	addi	a0,a0,88
    800036cc:	40dc                	lw	a5,4(s1)
    800036ce:	8bbd                	andi	a5,a5,15
    800036d0:	079a                	slli	a5,a5,0x6
    800036d2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036d4:	04449783          	lh	a5,68(s1)
    800036d8:	00f51023          	sh	a5,0(a0)
  dip->major = ip->major;
    800036dc:	04649783          	lh	a5,70(s1)
    800036e0:	00f51123          	sh	a5,2(a0)
  dip->minor = ip->minor;
    800036e4:	04849783          	lh	a5,72(s1)
    800036e8:	00f51223          	sh	a5,4(a0)
  dip->nlink = ip->nlink;
    800036ec:	04a49783          	lh	a5,74(s1)
    800036f0:	00f51323          	sh	a5,6(a0)
  dip->size = ip->size;
    800036f4:	44fc                	lw	a5,76(s1)
    800036f6:	c51c                	sw	a5,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036f8:	03400613          	li	a2,52
    800036fc:	05048593          	addi	a1,s1,80
    80003700:	0531                	addi	a0,a0,12
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	68a080e7          	jalr	1674(ra) # 80000d8c <memmove>
  log_write(bp);
    8000370a:	854a                	mv	a0,s2
    8000370c:	00001097          	auipc	ra,0x1
    80003710:	c18080e7          	jalr	-1000(ra) # 80004324 <log_write>
  brelse(bp);
    80003714:	854a                	mv	a0,s2
    80003716:	00000097          	auipc	ra,0x0
    8000371a:	94c080e7          	jalr	-1716(ra) # 80003062 <brelse>
}
    8000371e:	60e2                	ld	ra,24(sp)
    80003720:	6442                	ld	s0,16(sp)
    80003722:	64a2                	ld	s1,8(sp)
    80003724:	6902                	ld	s2,0(sp)
    80003726:	6105                	addi	sp,sp,32
    80003728:	8082                	ret

000000008000372a <idup>:
{
    8000372a:	1101                	addi	sp,sp,-32
    8000372c:	ec06                	sd	ra,24(sp)
    8000372e:	e822                	sd	s0,16(sp)
    80003730:	e426                	sd	s1,8(sp)
    80003732:	1000                	addi	s0,sp,32
    80003734:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003736:	00028517          	auipc	a0,0x28
    8000373a:	07a50513          	addi	a0,a0,122 # 8002b7b0 <icache>
    8000373e:	ffffd097          	auipc	ra,0xffffd
    80003742:	4e6080e7          	jalr	1254(ra) # 80000c24 <acquire>
  ip->ref++;
    80003746:	449c                	lw	a5,8(s1)
    80003748:	2785                	addiw	a5,a5,1
    8000374a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000374c:	00028517          	auipc	a0,0x28
    80003750:	06450513          	addi	a0,a0,100 # 8002b7b0 <icache>
    80003754:	ffffd097          	auipc	ra,0xffffd
    80003758:	584080e7          	jalr	1412(ra) # 80000cd8 <release>
}
    8000375c:	8526                	mv	a0,s1
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6105                	addi	sp,sp,32
    80003766:	8082                	ret

0000000080003768 <ilock>:
{
    80003768:	1101                	addi	sp,sp,-32
    8000376a:	ec06                	sd	ra,24(sp)
    8000376c:	e822                	sd	s0,16(sp)
    8000376e:	e426                	sd	s1,8(sp)
    80003770:	e04a                	sd	s2,0(sp)
    80003772:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003774:	c115                	beqz	a0,80003798 <ilock+0x30>
    80003776:	84aa                	mv	s1,a0
    80003778:	451c                	lw	a5,8(a0)
    8000377a:	00f05f63          	blez	a5,80003798 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000377e:	0541                	addi	a0,a0,16
    80003780:	00001097          	auipc	ra,0x1
    80003784:	ce2080e7          	jalr	-798(ra) # 80004462 <acquiresleep>
  if(ip->valid == 0){
    80003788:	40bc                	lw	a5,64(s1)
    8000378a:	cf99                	beqz	a5,800037a8 <ilock+0x40>
}
    8000378c:	60e2                	ld	ra,24(sp)
    8000378e:	6442                	ld	s0,16(sp)
    80003790:	64a2                	ld	s1,8(sp)
    80003792:	6902                	ld	s2,0(sp)
    80003794:	6105                	addi	sp,sp,32
    80003796:	8082                	ret
    panic("ilock");
    80003798:	00005517          	auipc	a0,0x5
    8000379c:	de050513          	addi	a0,a0,-544 # 80008578 <syscalls+0x1b8>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	db8080e7          	jalr	-584(ra) # 80000558 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037a8:	40dc                	lw	a5,4(s1)
    800037aa:	0047d79b          	srliw	a5,a5,0x4
    800037ae:	00028717          	auipc	a4,0x28
    800037b2:	fe270713          	addi	a4,a4,-30 # 8002b790 <sb>
    800037b6:	4f0c                	lw	a1,24(a4)
    800037b8:	9dbd                	addw	a1,a1,a5
    800037ba:	4088                	lw	a0,0(s1)
    800037bc:	fffff097          	auipc	ra,0xfffff
    800037c0:	764080e7          	jalr	1892(ra) # 80002f20 <bread>
    800037c4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037c6:	05850593          	addi	a1,a0,88
    800037ca:	40dc                	lw	a5,4(s1)
    800037cc:	8bbd                	andi	a5,a5,15
    800037ce:	079a                	slli	a5,a5,0x6
    800037d0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037d2:	00059783          	lh	a5,0(a1)
    800037d6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037da:	00259783          	lh	a5,2(a1)
    800037de:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037e2:	00459783          	lh	a5,4(a1)
    800037e6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037ea:	00659783          	lh	a5,6(a1)
    800037ee:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037f2:	459c                	lw	a5,8(a1)
    800037f4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037f6:	03400613          	li	a2,52
    800037fa:	05b1                	addi	a1,a1,12
    800037fc:	05048513          	addi	a0,s1,80
    80003800:	ffffd097          	auipc	ra,0xffffd
    80003804:	58c080e7          	jalr	1420(ra) # 80000d8c <memmove>
    brelse(bp);
    80003808:	854a                	mv	a0,s2
    8000380a:	00000097          	auipc	ra,0x0
    8000380e:	858080e7          	jalr	-1960(ra) # 80003062 <brelse>
    ip->valid = 1;
    80003812:	4785                	li	a5,1
    80003814:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003816:	04449783          	lh	a5,68(s1)
    8000381a:	fbad                	bnez	a5,8000378c <ilock+0x24>
      panic("ilock: no type");
    8000381c:	00005517          	auipc	a0,0x5
    80003820:	d6450513          	addi	a0,a0,-668 # 80008580 <syscalls+0x1c0>
    80003824:	ffffd097          	auipc	ra,0xffffd
    80003828:	d34080e7          	jalr	-716(ra) # 80000558 <panic>

000000008000382c <iunlock>:
{
    8000382c:	1101                	addi	sp,sp,-32
    8000382e:	ec06                	sd	ra,24(sp)
    80003830:	e822                	sd	s0,16(sp)
    80003832:	e426                	sd	s1,8(sp)
    80003834:	e04a                	sd	s2,0(sp)
    80003836:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003838:	c905                	beqz	a0,80003868 <iunlock+0x3c>
    8000383a:	84aa                	mv	s1,a0
    8000383c:	01050913          	addi	s2,a0,16
    80003840:	854a                	mv	a0,s2
    80003842:	00001097          	auipc	ra,0x1
    80003846:	cba080e7          	jalr	-838(ra) # 800044fc <holdingsleep>
    8000384a:	cd19                	beqz	a0,80003868 <iunlock+0x3c>
    8000384c:	449c                	lw	a5,8(s1)
    8000384e:	00f05d63          	blez	a5,80003868 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003852:	854a                	mv	a0,s2
    80003854:	00001097          	auipc	ra,0x1
    80003858:	c64080e7          	jalr	-924(ra) # 800044b8 <releasesleep>
}
    8000385c:	60e2                	ld	ra,24(sp)
    8000385e:	6442                	ld	s0,16(sp)
    80003860:	64a2                	ld	s1,8(sp)
    80003862:	6902                	ld	s2,0(sp)
    80003864:	6105                	addi	sp,sp,32
    80003866:	8082                	ret
    panic("iunlock");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	d2850513          	addi	a0,a0,-728 # 80008590 <syscalls+0x1d0>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	ce8080e7          	jalr	-792(ra) # 80000558 <panic>

0000000080003878 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003878:	7179                	addi	sp,sp,-48
    8000387a:	f406                	sd	ra,40(sp)
    8000387c:	f022                	sd	s0,32(sp)
    8000387e:	ec26                	sd	s1,24(sp)
    80003880:	e84a                	sd	s2,16(sp)
    80003882:	e44e                	sd	s3,8(sp)
    80003884:	e052                	sd	s4,0(sp)
    80003886:	1800                	addi	s0,sp,48
    80003888:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000388a:	05050493          	addi	s1,a0,80
    8000388e:	08050913          	addi	s2,a0,128
    80003892:	a821                	j	800038aa <itrunc+0x32>
    if(ip->addrs[i]){
      bfree(ip->dev, ip->addrs[i]);
    80003894:	0009a503          	lw	a0,0(s3)
    80003898:	00000097          	auipc	ra,0x0
    8000389c:	8e0080e7          	jalr	-1824(ra) # 80003178 <bfree>
      ip->addrs[i] = 0;
    800038a0:	0004a023          	sw	zero,0(s1)
  for(i = 0; i < NDIRECT; i++){
    800038a4:	0491                	addi	s1,s1,4
    800038a6:	01248563          	beq	s1,s2,800038b0 <itrunc+0x38>
    if(ip->addrs[i]){
    800038aa:	408c                	lw	a1,0(s1)
    800038ac:	dde5                	beqz	a1,800038a4 <itrunc+0x2c>
    800038ae:	b7dd                	j	80003894 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038b0:	0809a583          	lw	a1,128(s3)
    800038b4:	e185                	bnez	a1,800038d4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038b6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038ba:	854e                	mv	a0,s3
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	de0080e7          	jalr	-544(ra) # 8000369c <iupdate>
}
    800038c4:	70a2                	ld	ra,40(sp)
    800038c6:	7402                	ld	s0,32(sp)
    800038c8:	64e2                	ld	s1,24(sp)
    800038ca:	6942                	ld	s2,16(sp)
    800038cc:	69a2                	ld	s3,8(sp)
    800038ce:	6a02                	ld	s4,0(sp)
    800038d0:	6145                	addi	sp,sp,48
    800038d2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038d4:	0009a503          	lw	a0,0(s3)
    800038d8:	fffff097          	auipc	ra,0xfffff
    800038dc:	648080e7          	jalr	1608(ra) # 80002f20 <bread>
    800038e0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038e2:	05850493          	addi	s1,a0,88
    800038e6:	45850913          	addi	s2,a0,1112
    800038ea:	a811                	j	800038fe <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038ec:	0009a503          	lw	a0,0(s3)
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	888080e7          	jalr	-1912(ra) # 80003178 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038f8:	0491                	addi	s1,s1,4
    800038fa:	01248563          	beq	s1,s2,80003904 <itrunc+0x8c>
      if(a[j])
    800038fe:	408c                	lw	a1,0(s1)
    80003900:	dde5                	beqz	a1,800038f8 <itrunc+0x80>
    80003902:	b7ed                	j	800038ec <itrunc+0x74>
    brelse(bp);
    80003904:	8552                	mv	a0,s4
    80003906:	fffff097          	auipc	ra,0xfffff
    8000390a:	75c080e7          	jalr	1884(ra) # 80003062 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000390e:	0809a583          	lw	a1,128(s3)
    80003912:	0009a503          	lw	a0,0(s3)
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	862080e7          	jalr	-1950(ra) # 80003178 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000391e:	0809a023          	sw	zero,128(s3)
    80003922:	bf51                	j	800038b6 <itrunc+0x3e>

0000000080003924 <iput>:
{
    80003924:	1101                	addi	sp,sp,-32
    80003926:	ec06                	sd	ra,24(sp)
    80003928:	e822                	sd	s0,16(sp)
    8000392a:	e426                	sd	s1,8(sp)
    8000392c:	e04a                	sd	s2,0(sp)
    8000392e:	1000                	addi	s0,sp,32
    80003930:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003932:	00028517          	auipc	a0,0x28
    80003936:	e7e50513          	addi	a0,a0,-386 # 8002b7b0 <icache>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	2ea080e7          	jalr	746(ra) # 80000c24 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003942:	4498                	lw	a4,8(s1)
    80003944:	4785                	li	a5,1
    80003946:	02f70363          	beq	a4,a5,8000396c <iput+0x48>
  ip->ref--;
    8000394a:	449c                	lw	a5,8(s1)
    8000394c:	37fd                	addiw	a5,a5,-1
    8000394e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003950:	00028517          	auipc	a0,0x28
    80003954:	e6050513          	addi	a0,a0,-416 # 8002b7b0 <icache>
    80003958:	ffffd097          	auipc	ra,0xffffd
    8000395c:	380080e7          	jalr	896(ra) # 80000cd8 <release>
}
    80003960:	60e2                	ld	ra,24(sp)
    80003962:	6442                	ld	s0,16(sp)
    80003964:	64a2                	ld	s1,8(sp)
    80003966:	6902                	ld	s2,0(sp)
    80003968:	6105                	addi	sp,sp,32
    8000396a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000396c:	40bc                	lw	a5,64(s1)
    8000396e:	dff1                	beqz	a5,8000394a <iput+0x26>
    80003970:	04a49783          	lh	a5,74(s1)
    80003974:	fbf9                	bnez	a5,8000394a <iput+0x26>
    acquiresleep(&ip->lock);
    80003976:	01048913          	addi	s2,s1,16
    8000397a:	854a                	mv	a0,s2
    8000397c:	00001097          	auipc	ra,0x1
    80003980:	ae6080e7          	jalr	-1306(ra) # 80004462 <acquiresleep>
    release(&icache.lock);
    80003984:	00028517          	auipc	a0,0x28
    80003988:	e2c50513          	addi	a0,a0,-468 # 8002b7b0 <icache>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	34c080e7          	jalr	844(ra) # 80000cd8 <release>
    itrunc(ip);
    80003994:	8526                	mv	a0,s1
    80003996:	00000097          	auipc	ra,0x0
    8000399a:	ee2080e7          	jalr	-286(ra) # 80003878 <itrunc>
    ip->type = 0;
    8000399e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039a2:	8526                	mv	a0,s1
    800039a4:	00000097          	auipc	ra,0x0
    800039a8:	cf8080e7          	jalr	-776(ra) # 8000369c <iupdate>
    ip->valid = 0;
    800039ac:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039b0:	854a                	mv	a0,s2
    800039b2:	00001097          	auipc	ra,0x1
    800039b6:	b06080e7          	jalr	-1274(ra) # 800044b8 <releasesleep>
    acquire(&icache.lock);
    800039ba:	00028517          	auipc	a0,0x28
    800039be:	df650513          	addi	a0,a0,-522 # 8002b7b0 <icache>
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	262080e7          	jalr	610(ra) # 80000c24 <acquire>
    800039ca:	b741                	j	8000394a <iput+0x26>

00000000800039cc <iunlockput>:
{
    800039cc:	1101                	addi	sp,sp,-32
    800039ce:	ec06                	sd	ra,24(sp)
    800039d0:	e822                	sd	s0,16(sp)
    800039d2:	e426                	sd	s1,8(sp)
    800039d4:	1000                	addi	s0,sp,32
    800039d6:	84aa                	mv	s1,a0
  iunlock(ip);
    800039d8:	00000097          	auipc	ra,0x0
    800039dc:	e54080e7          	jalr	-428(ra) # 8000382c <iunlock>
  iput(ip);
    800039e0:	8526                	mv	a0,s1
    800039e2:	00000097          	auipc	ra,0x0
    800039e6:	f42080e7          	jalr	-190(ra) # 80003924 <iput>
}
    800039ea:	60e2                	ld	ra,24(sp)
    800039ec:	6442                	ld	s0,16(sp)
    800039ee:	64a2                	ld	s1,8(sp)
    800039f0:	6105                	addi	sp,sp,32
    800039f2:	8082                	ret

00000000800039f4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039f4:	1141                	addi	sp,sp,-16
    800039f6:	e422                	sd	s0,8(sp)
    800039f8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039fa:	411c                	lw	a5,0(a0)
    800039fc:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039fe:	415c                	lw	a5,4(a0)
    80003a00:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a02:	04451783          	lh	a5,68(a0)
    80003a06:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a0a:	04a51783          	lh	a5,74(a0)
    80003a0e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a12:	04c56783          	lwu	a5,76(a0)
    80003a16:	e99c                	sd	a5,16(a1)
}
    80003a18:	6422                	ld	s0,8(sp)
    80003a1a:	0141                	addi	sp,sp,16
    80003a1c:	8082                	ret

0000000080003a1e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a1e:	457c                	lw	a5,76(a0)
    80003a20:	0ed7e963          	bltu	a5,a3,80003b12 <readi+0xf4>
{
    80003a24:	7159                	addi	sp,sp,-112
    80003a26:	f486                	sd	ra,104(sp)
    80003a28:	f0a2                	sd	s0,96(sp)
    80003a2a:	eca6                	sd	s1,88(sp)
    80003a2c:	e8ca                	sd	s2,80(sp)
    80003a2e:	e4ce                	sd	s3,72(sp)
    80003a30:	e0d2                	sd	s4,64(sp)
    80003a32:	fc56                	sd	s5,56(sp)
    80003a34:	f85a                	sd	s6,48(sp)
    80003a36:	f45e                	sd	s7,40(sp)
    80003a38:	f062                	sd	s8,32(sp)
    80003a3a:	ec66                	sd	s9,24(sp)
    80003a3c:	e86a                	sd	s10,16(sp)
    80003a3e:	e46e                	sd	s11,8(sp)
    80003a40:	1880                	addi	s0,sp,112
    80003a42:	8baa                	mv	s7,a0
    80003a44:	8c2e                	mv	s8,a1
    80003a46:	8a32                	mv	s4,a2
    80003a48:	84b6                	mv	s1,a3
    80003a4a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a4c:	9f35                	addw	a4,a4,a3
    return 0;
    80003a4e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a50:	0ad76063          	bltu	a4,a3,80003af0 <readi+0xd2>
  if(off + n > ip->size)
    80003a54:	00e7f463          	bleu	a4,a5,80003a5c <readi+0x3e>
    n = ip->size - off;
    80003a58:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a5c:	0a0b0963          	beqz	s6,80003b0e <readi+0xf0>
    80003a60:	4901                	li	s2,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a62:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a66:	5cfd                	li	s9,-1
    80003a68:	a82d                	j	80003aa2 <readi+0x84>
    80003a6a:	02099d93          	slli	s11,s3,0x20
    80003a6e:	020ddd93          	srli	s11,s11,0x20
    80003a72:	058a8613          	addi	a2,s5,88
    80003a76:	86ee                	mv	a3,s11
    80003a78:	963a                	add	a2,a2,a4
    80003a7a:	85d2                	mv	a1,s4
    80003a7c:	8562                	mv	a0,s8
    80003a7e:	fffff097          	auipc	ra,0xfffff
    80003a82:	aa4080e7          	jalr	-1372(ra) # 80002522 <either_copyout>
    80003a86:	05950d63          	beq	a0,s9,80003ae0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003a8a:	8556                	mv	a0,s5
    80003a8c:	fffff097          	auipc	ra,0xfffff
    80003a90:	5d6080e7          	jalr	1494(ra) # 80003062 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a94:	0129893b          	addw	s2,s3,s2
    80003a98:	009984bb          	addw	s1,s3,s1
    80003a9c:	9a6e                	add	s4,s4,s11
    80003a9e:	05697763          	bleu	s6,s2,80003aec <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003aa2:	000ba983          	lw	s3,0(s7)
    80003aa6:	00a4d59b          	srliw	a1,s1,0xa
    80003aaa:	855e                	mv	a0,s7
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	8ac080e7          	jalr	-1876(ra) # 80003358 <bmap>
    80003ab4:	0005059b          	sext.w	a1,a0
    80003ab8:	854e                	mv	a0,s3
    80003aba:	fffff097          	auipc	ra,0xfffff
    80003abe:	466080e7          	jalr	1126(ra) # 80002f20 <bread>
    80003ac2:	8aaa                	mv	s5,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ac4:	3ff4f713          	andi	a4,s1,1023
    80003ac8:	40ed07bb          	subw	a5,s10,a4
    80003acc:	412b06bb          	subw	a3,s6,s2
    80003ad0:	89be                	mv	s3,a5
    80003ad2:	2781                	sext.w	a5,a5
    80003ad4:	0006861b          	sext.w	a2,a3
    80003ad8:	f8f679e3          	bleu	a5,a2,80003a6a <readi+0x4c>
    80003adc:	89b6                	mv	s3,a3
    80003ade:	b771                	j	80003a6a <readi+0x4c>
      brelse(bp);
    80003ae0:	8556                	mv	a0,s5
    80003ae2:	fffff097          	auipc	ra,0xfffff
    80003ae6:	580080e7          	jalr	1408(ra) # 80003062 <brelse>
      tot = -1;
    80003aea:	597d                	li	s2,-1
  }
  return tot;
    80003aec:	0009051b          	sext.w	a0,s2
}
    80003af0:	70a6                	ld	ra,104(sp)
    80003af2:	7406                	ld	s0,96(sp)
    80003af4:	64e6                	ld	s1,88(sp)
    80003af6:	6946                	ld	s2,80(sp)
    80003af8:	69a6                	ld	s3,72(sp)
    80003afa:	6a06                	ld	s4,64(sp)
    80003afc:	7ae2                	ld	s5,56(sp)
    80003afe:	7b42                	ld	s6,48(sp)
    80003b00:	7ba2                	ld	s7,40(sp)
    80003b02:	7c02                	ld	s8,32(sp)
    80003b04:	6ce2                	ld	s9,24(sp)
    80003b06:	6d42                	ld	s10,16(sp)
    80003b08:	6da2                	ld	s11,8(sp)
    80003b0a:	6165                	addi	sp,sp,112
    80003b0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b0e:	895a                	mv	s2,s6
    80003b10:	bff1                	j	80003aec <readi+0xce>
    return 0;
    80003b12:	4501                	li	a0,0
}
    80003b14:	8082                	ret

0000000080003b16 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b16:	457c                	lw	a5,76(a0)
    80003b18:	10d7e863          	bltu	a5,a3,80003c28 <writei+0x112>
{
    80003b1c:	7159                	addi	sp,sp,-112
    80003b1e:	f486                	sd	ra,104(sp)
    80003b20:	f0a2                	sd	s0,96(sp)
    80003b22:	eca6                	sd	s1,88(sp)
    80003b24:	e8ca                	sd	s2,80(sp)
    80003b26:	e4ce                	sd	s3,72(sp)
    80003b28:	e0d2                	sd	s4,64(sp)
    80003b2a:	fc56                	sd	s5,56(sp)
    80003b2c:	f85a                	sd	s6,48(sp)
    80003b2e:	f45e                	sd	s7,40(sp)
    80003b30:	f062                	sd	s8,32(sp)
    80003b32:	ec66                	sd	s9,24(sp)
    80003b34:	e86a                	sd	s10,16(sp)
    80003b36:	e46e                	sd	s11,8(sp)
    80003b38:	1880                	addi	s0,sp,112
    80003b3a:	8b2a                	mv	s6,a0
    80003b3c:	8c2e                	mv	s8,a1
    80003b3e:	8ab2                	mv	s5,a2
    80003b40:	84b6                	mv	s1,a3
    80003b42:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b44:	00e687bb          	addw	a5,a3,a4
    80003b48:	0ed7e263          	bltu	a5,a3,80003c2c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b4c:	00043737          	lui	a4,0x43
    80003b50:	0ef76063          	bltu	a4,a5,80003c30 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b54:	0c0b8863          	beqz	s7,80003c24 <writei+0x10e>
    80003b58:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b5a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b5e:	5cfd                	li	s9,-1
    80003b60:	a091                	j	80003ba4 <writei+0x8e>
    80003b62:	02091d93          	slli	s11,s2,0x20
    80003b66:	020ddd93          	srli	s11,s11,0x20
    80003b6a:	058a0513          	addi	a0,s4,88 # 2058 <_entry-0x7fffdfa8>
    80003b6e:	86ee                	mv	a3,s11
    80003b70:	8656                	mv	a2,s5
    80003b72:	85e2                	mv	a1,s8
    80003b74:	953a                	add	a0,a0,a4
    80003b76:	fffff097          	auipc	ra,0xfffff
    80003b7a:	a02080e7          	jalr	-1534(ra) # 80002578 <either_copyin>
    80003b7e:	07950263          	beq	a0,s9,80003be2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b82:	8552                	mv	a0,s4
    80003b84:	00000097          	auipc	ra,0x0
    80003b88:	7a0080e7          	jalr	1952(ra) # 80004324 <log_write>
    brelse(bp);
    80003b8c:	8552                	mv	a0,s4
    80003b8e:	fffff097          	auipc	ra,0xfffff
    80003b92:	4d4080e7          	jalr	1236(ra) # 80003062 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b96:	013909bb          	addw	s3,s2,s3
    80003b9a:	009904bb          	addw	s1,s2,s1
    80003b9e:	9aee                	add	s5,s5,s11
    80003ba0:	0579f663          	bleu	s7,s3,80003bec <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ba4:	000b2903          	lw	s2,0(s6)
    80003ba8:	00a4d59b          	srliw	a1,s1,0xa
    80003bac:	855a                	mv	a0,s6
    80003bae:	fffff097          	auipc	ra,0xfffff
    80003bb2:	7aa080e7          	jalr	1962(ra) # 80003358 <bmap>
    80003bb6:	0005059b          	sext.w	a1,a0
    80003bba:	854a                	mv	a0,s2
    80003bbc:	fffff097          	auipc	ra,0xfffff
    80003bc0:	364080e7          	jalr	868(ra) # 80002f20 <bread>
    80003bc4:	8a2a                	mv	s4,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc6:	3ff4f713          	andi	a4,s1,1023
    80003bca:	40ed07bb          	subw	a5,s10,a4
    80003bce:	413b86bb          	subw	a3,s7,s3
    80003bd2:	893e                	mv	s2,a5
    80003bd4:	2781                	sext.w	a5,a5
    80003bd6:	0006861b          	sext.w	a2,a3
    80003bda:	f8f674e3          	bleu	a5,a2,80003b62 <writei+0x4c>
    80003bde:	8936                	mv	s2,a3
    80003be0:	b749                	j	80003b62 <writei+0x4c>
      brelse(bp);
    80003be2:	8552                	mv	a0,s4
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	47e080e7          	jalr	1150(ra) # 80003062 <brelse>
  }

  if(off > ip->size)
    80003bec:	04cb2783          	lw	a5,76(s6)
    80003bf0:	0097f463          	bleu	s1,a5,80003bf8 <writei+0xe2>
    ip->size = off;
    80003bf4:	049b2623          	sw	s1,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003bf8:	855a                	mv	a0,s6
    80003bfa:	00000097          	auipc	ra,0x0
    80003bfe:	aa2080e7          	jalr	-1374(ra) # 8000369c <iupdate>

  return tot;
    80003c02:	0009851b          	sext.w	a0,s3
}
    80003c06:	70a6                	ld	ra,104(sp)
    80003c08:	7406                	ld	s0,96(sp)
    80003c0a:	64e6                	ld	s1,88(sp)
    80003c0c:	6946                	ld	s2,80(sp)
    80003c0e:	69a6                	ld	s3,72(sp)
    80003c10:	6a06                	ld	s4,64(sp)
    80003c12:	7ae2                	ld	s5,56(sp)
    80003c14:	7b42                	ld	s6,48(sp)
    80003c16:	7ba2                	ld	s7,40(sp)
    80003c18:	7c02                	ld	s8,32(sp)
    80003c1a:	6ce2                	ld	s9,24(sp)
    80003c1c:	6d42                	ld	s10,16(sp)
    80003c1e:	6da2                	ld	s11,8(sp)
    80003c20:	6165                	addi	sp,sp,112
    80003c22:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c24:	89de                	mv	s3,s7
    80003c26:	bfc9                	j	80003bf8 <writei+0xe2>
    return -1;
    80003c28:	557d                	li	a0,-1
}
    80003c2a:	8082                	ret
    return -1;
    80003c2c:	557d                	li	a0,-1
    80003c2e:	bfe1                	j	80003c06 <writei+0xf0>
    return -1;
    80003c30:	557d                	li	a0,-1
    80003c32:	bfd1                	j	80003c06 <writei+0xf0>

0000000080003c34 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c34:	1141                	addi	sp,sp,-16
    80003c36:	e406                	sd	ra,8(sp)
    80003c38:	e022                	sd	s0,0(sp)
    80003c3a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c3c:	4639                	li	a2,14
    80003c3e:	ffffd097          	auipc	ra,0xffffd
    80003c42:	1ca080e7          	jalr	458(ra) # 80000e08 <strncmp>
}
    80003c46:	60a2                	ld	ra,8(sp)
    80003c48:	6402                	ld	s0,0(sp)
    80003c4a:	0141                	addi	sp,sp,16
    80003c4c:	8082                	ret

0000000080003c4e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c4e:	7139                	addi	sp,sp,-64
    80003c50:	fc06                	sd	ra,56(sp)
    80003c52:	f822                	sd	s0,48(sp)
    80003c54:	f426                	sd	s1,40(sp)
    80003c56:	f04a                	sd	s2,32(sp)
    80003c58:	ec4e                	sd	s3,24(sp)
    80003c5a:	e852                	sd	s4,16(sp)
    80003c5c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c5e:	04451703          	lh	a4,68(a0)
    80003c62:	4785                	li	a5,1
    80003c64:	00f71a63          	bne	a4,a5,80003c78 <dirlookup+0x2a>
    80003c68:	892a                	mv	s2,a0
    80003c6a:	89ae                	mv	s3,a1
    80003c6c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c6e:	457c                	lw	a5,76(a0)
    80003c70:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c72:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c74:	e79d                	bnez	a5,80003ca2 <dirlookup+0x54>
    80003c76:	a8a5                	j	80003cee <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c78:	00005517          	auipc	a0,0x5
    80003c7c:	92050513          	addi	a0,a0,-1760 # 80008598 <syscalls+0x1d8>
    80003c80:	ffffd097          	auipc	ra,0xffffd
    80003c84:	8d8080e7          	jalr	-1832(ra) # 80000558 <panic>
      panic("dirlookup read");
    80003c88:	00005517          	auipc	a0,0x5
    80003c8c:	92850513          	addi	a0,a0,-1752 # 800085b0 <syscalls+0x1f0>
    80003c90:	ffffd097          	auipc	ra,0xffffd
    80003c94:	8c8080e7          	jalr	-1848(ra) # 80000558 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c98:	24c1                	addiw	s1,s1,16
    80003c9a:	04c92783          	lw	a5,76(s2)
    80003c9e:	04f4f763          	bleu	a5,s1,80003cec <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ca2:	4741                	li	a4,16
    80003ca4:	86a6                	mv	a3,s1
    80003ca6:	fc040613          	addi	a2,s0,-64
    80003caa:	4581                	li	a1,0
    80003cac:	854a                	mv	a0,s2
    80003cae:	00000097          	auipc	ra,0x0
    80003cb2:	d70080e7          	jalr	-656(ra) # 80003a1e <readi>
    80003cb6:	47c1                	li	a5,16
    80003cb8:	fcf518e3          	bne	a0,a5,80003c88 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cbc:	fc045783          	lhu	a5,-64(s0)
    80003cc0:	dfe1                	beqz	a5,80003c98 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cc2:	fc240593          	addi	a1,s0,-62
    80003cc6:	854e                	mv	a0,s3
    80003cc8:	00000097          	auipc	ra,0x0
    80003ccc:	f6c080e7          	jalr	-148(ra) # 80003c34 <namecmp>
    80003cd0:	f561                	bnez	a0,80003c98 <dirlookup+0x4a>
      if(poff)
    80003cd2:	000a0463          	beqz	s4,80003cda <dirlookup+0x8c>
        *poff = off;
    80003cd6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cda:	fc045583          	lhu	a1,-64(s0)
    80003cde:	00092503          	lw	a0,0(s2)
    80003ce2:	fffff097          	auipc	ra,0xfffff
    80003ce6:	750080e7          	jalr	1872(ra) # 80003432 <iget>
    80003cea:	a011                	j	80003cee <dirlookup+0xa0>
  return 0;
    80003cec:	4501                	li	a0,0
}
    80003cee:	70e2                	ld	ra,56(sp)
    80003cf0:	7442                	ld	s0,48(sp)
    80003cf2:	74a2                	ld	s1,40(sp)
    80003cf4:	7902                	ld	s2,32(sp)
    80003cf6:	69e2                	ld	s3,24(sp)
    80003cf8:	6a42                	ld	s4,16(sp)
    80003cfa:	6121                	addi	sp,sp,64
    80003cfc:	8082                	ret

0000000080003cfe <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003cfe:	711d                	addi	sp,sp,-96
    80003d00:	ec86                	sd	ra,88(sp)
    80003d02:	e8a2                	sd	s0,80(sp)
    80003d04:	e4a6                	sd	s1,72(sp)
    80003d06:	e0ca                	sd	s2,64(sp)
    80003d08:	fc4e                	sd	s3,56(sp)
    80003d0a:	f852                	sd	s4,48(sp)
    80003d0c:	f456                	sd	s5,40(sp)
    80003d0e:	f05a                	sd	s6,32(sp)
    80003d10:	ec5e                	sd	s7,24(sp)
    80003d12:	e862                	sd	s8,16(sp)
    80003d14:	e466                	sd	s9,8(sp)
    80003d16:	1080                	addi	s0,sp,96
    80003d18:	84aa                	mv	s1,a0
    80003d1a:	8bae                	mv	s7,a1
    80003d1c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d1e:	00054703          	lbu	a4,0(a0)
    80003d22:	02f00793          	li	a5,47
    80003d26:	02f70363          	beq	a4,a5,80003d4c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d2a:	ffffe097          	auipc	ra,0xffffe
    80003d2e:	d14080e7          	jalr	-748(ra) # 80001a3e <myproc>
    80003d32:	15053503          	ld	a0,336(a0)
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	9f4080e7          	jalr	-1548(ra) # 8000372a <idup>
    80003d3e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d40:	02f00913          	li	s2,47
  len = path - s;
    80003d44:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80003d46:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d48:	4c05                	li	s8,1
    80003d4a:	a865                	j	80003e02 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d4c:	4585                	li	a1,1
    80003d4e:	4505                	li	a0,1
    80003d50:	fffff097          	auipc	ra,0xfffff
    80003d54:	6e2080e7          	jalr	1762(ra) # 80003432 <iget>
    80003d58:	89aa                	mv	s3,a0
    80003d5a:	b7dd                	j	80003d40 <namex+0x42>
      iunlockput(ip);
    80003d5c:	854e                	mv	a0,s3
    80003d5e:	00000097          	auipc	ra,0x0
    80003d62:	c6e080e7          	jalr	-914(ra) # 800039cc <iunlockput>
      return 0;
    80003d66:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d68:	854e                	mv	a0,s3
    80003d6a:	60e6                	ld	ra,88(sp)
    80003d6c:	6446                	ld	s0,80(sp)
    80003d6e:	64a6                	ld	s1,72(sp)
    80003d70:	6906                	ld	s2,64(sp)
    80003d72:	79e2                	ld	s3,56(sp)
    80003d74:	7a42                	ld	s4,48(sp)
    80003d76:	7aa2                	ld	s5,40(sp)
    80003d78:	7b02                	ld	s6,32(sp)
    80003d7a:	6be2                	ld	s7,24(sp)
    80003d7c:	6c42                	ld	s8,16(sp)
    80003d7e:	6ca2                	ld	s9,8(sp)
    80003d80:	6125                	addi	sp,sp,96
    80003d82:	8082                	ret
      iunlock(ip);
    80003d84:	854e                	mv	a0,s3
    80003d86:	00000097          	auipc	ra,0x0
    80003d8a:	aa6080e7          	jalr	-1370(ra) # 8000382c <iunlock>
      return ip;
    80003d8e:	bfe9                	j	80003d68 <namex+0x6a>
      iunlockput(ip);
    80003d90:	854e                	mv	a0,s3
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	c3a080e7          	jalr	-966(ra) # 800039cc <iunlockput>
      return 0;
    80003d9a:	89d2                	mv	s3,s4
    80003d9c:	b7f1                	j	80003d68 <namex+0x6a>
  len = path - s;
    80003d9e:	40b48633          	sub	a2,s1,a1
    80003da2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003da6:	094cd663          	ble	s4,s9,80003e32 <namex+0x134>
    memmove(name, s, DIRSIZ);
    80003daa:	4639                	li	a2,14
    80003dac:	8556                	mv	a0,s5
    80003dae:	ffffd097          	auipc	ra,0xffffd
    80003db2:	fde080e7          	jalr	-34(ra) # 80000d8c <memmove>
  while(*path == '/')
    80003db6:	0004c783          	lbu	a5,0(s1)
    80003dba:	01279763          	bne	a5,s2,80003dc8 <namex+0xca>
    path++;
    80003dbe:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dc0:	0004c783          	lbu	a5,0(s1)
    80003dc4:	ff278de3          	beq	a5,s2,80003dbe <namex+0xc0>
    ilock(ip);
    80003dc8:	854e                	mv	a0,s3
    80003dca:	00000097          	auipc	ra,0x0
    80003dce:	99e080e7          	jalr	-1634(ra) # 80003768 <ilock>
    if(ip->type != T_DIR){
    80003dd2:	04499783          	lh	a5,68(s3)
    80003dd6:	f98793e3          	bne	a5,s8,80003d5c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003dda:	000b8563          	beqz	s7,80003de4 <namex+0xe6>
    80003dde:	0004c783          	lbu	a5,0(s1)
    80003de2:	d3cd                	beqz	a5,80003d84 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003de4:	865a                	mv	a2,s6
    80003de6:	85d6                	mv	a1,s5
    80003de8:	854e                	mv	a0,s3
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	e64080e7          	jalr	-412(ra) # 80003c4e <dirlookup>
    80003df2:	8a2a                	mv	s4,a0
    80003df4:	dd51                	beqz	a0,80003d90 <namex+0x92>
    iunlockput(ip);
    80003df6:	854e                	mv	a0,s3
    80003df8:	00000097          	auipc	ra,0x0
    80003dfc:	bd4080e7          	jalr	-1068(ra) # 800039cc <iunlockput>
    ip = next;
    80003e00:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e02:	0004c783          	lbu	a5,0(s1)
    80003e06:	05279d63          	bne	a5,s2,80003e60 <namex+0x162>
    path++;
    80003e0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e0c:	0004c783          	lbu	a5,0(s1)
    80003e10:	ff278de3          	beq	a5,s2,80003e0a <namex+0x10c>
  if(*path == 0)
    80003e14:	cf8d                	beqz	a5,80003e4e <namex+0x150>
  while(*path != '/' && *path != 0)
    80003e16:	01278b63          	beq	a5,s2,80003e2c <namex+0x12e>
    80003e1a:	c795                	beqz	a5,80003e46 <namex+0x148>
    path++;
    80003e1c:	85a6                	mv	a1,s1
    path++;
    80003e1e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e20:	0004c783          	lbu	a5,0(s1)
    80003e24:	f7278de3          	beq	a5,s2,80003d9e <namex+0xa0>
    80003e28:	fbfd                	bnez	a5,80003e1e <namex+0x120>
    80003e2a:	bf95                	j	80003d9e <namex+0xa0>
    80003e2c:	85a6                	mv	a1,s1
  len = path - s;
    80003e2e:	8a5a                	mv	s4,s6
    80003e30:	865a                	mv	a2,s6
    memmove(name, s, len);
    80003e32:	2601                	sext.w	a2,a2
    80003e34:	8556                	mv	a0,s5
    80003e36:	ffffd097          	auipc	ra,0xffffd
    80003e3a:	f56080e7          	jalr	-170(ra) # 80000d8c <memmove>
    name[len] = 0;
    80003e3e:	9a56                	add	s4,s4,s5
    80003e40:	000a0023          	sb	zero,0(s4)
    80003e44:	bf8d                	j	80003db6 <namex+0xb8>
  while(*path != '/' && *path != 0)
    80003e46:	85a6                	mv	a1,s1
  len = path - s;
    80003e48:	8a5a                	mv	s4,s6
    80003e4a:	865a                	mv	a2,s6
    80003e4c:	b7dd                	j	80003e32 <namex+0x134>
  if(nameiparent){
    80003e4e:	f00b8de3          	beqz	s7,80003d68 <namex+0x6a>
    iput(ip);
    80003e52:	854e                	mv	a0,s3
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	ad0080e7          	jalr	-1328(ra) # 80003924 <iput>
    return 0;
    80003e5c:	4981                	li	s3,0
    80003e5e:	b729                	j	80003d68 <namex+0x6a>
  if(*path == 0)
    80003e60:	d7fd                	beqz	a5,80003e4e <namex+0x150>
    80003e62:	85a6                	mv	a1,s1
    80003e64:	bf6d                	j	80003e1e <namex+0x120>

0000000080003e66 <dirlink>:
{
    80003e66:	7139                	addi	sp,sp,-64
    80003e68:	fc06                	sd	ra,56(sp)
    80003e6a:	f822                	sd	s0,48(sp)
    80003e6c:	f426                	sd	s1,40(sp)
    80003e6e:	f04a                	sd	s2,32(sp)
    80003e70:	ec4e                	sd	s3,24(sp)
    80003e72:	e852                	sd	s4,16(sp)
    80003e74:	0080                	addi	s0,sp,64
    80003e76:	892a                	mv	s2,a0
    80003e78:	8a2e                	mv	s4,a1
    80003e7a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e7c:	4601                	li	a2,0
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	dd0080e7          	jalr	-560(ra) # 80003c4e <dirlookup>
    80003e86:	e93d                	bnez	a0,80003efc <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e88:	04c92483          	lw	s1,76(s2)
    80003e8c:	c49d                	beqz	s1,80003eba <dirlink+0x54>
    80003e8e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e90:	4741                	li	a4,16
    80003e92:	86a6                	mv	a3,s1
    80003e94:	fc040613          	addi	a2,s0,-64
    80003e98:	4581                	li	a1,0
    80003e9a:	854a                	mv	a0,s2
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	b82080e7          	jalr	-1150(ra) # 80003a1e <readi>
    80003ea4:	47c1                	li	a5,16
    80003ea6:	06f51163          	bne	a0,a5,80003f08 <dirlink+0xa2>
    if(de.inum == 0)
    80003eaa:	fc045783          	lhu	a5,-64(s0)
    80003eae:	c791                	beqz	a5,80003eba <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb0:	24c1                	addiw	s1,s1,16
    80003eb2:	04c92783          	lw	a5,76(s2)
    80003eb6:	fcf4ede3          	bltu	s1,a5,80003e90 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003eba:	4639                	li	a2,14
    80003ebc:	85d2                	mv	a1,s4
    80003ebe:	fc240513          	addi	a0,s0,-62
    80003ec2:	ffffd097          	auipc	ra,0xffffd
    80003ec6:	f96080e7          	jalr	-106(ra) # 80000e58 <strncpy>
  de.inum = inum;
    80003eca:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ece:	4741                	li	a4,16
    80003ed0:	86a6                	mv	a3,s1
    80003ed2:	fc040613          	addi	a2,s0,-64
    80003ed6:	4581                	li	a1,0
    80003ed8:	854a                	mv	a0,s2
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	c3c080e7          	jalr	-964(ra) # 80003b16 <writei>
    80003ee2:	4741                	li	a4,16
  return 0;
    80003ee4:	4781                	li	a5,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee6:	02e51963          	bne	a0,a4,80003f18 <dirlink+0xb2>
}
    80003eea:	853e                	mv	a0,a5
    80003eec:	70e2                	ld	ra,56(sp)
    80003eee:	7442                	ld	s0,48(sp)
    80003ef0:	74a2                	ld	s1,40(sp)
    80003ef2:	7902                	ld	s2,32(sp)
    80003ef4:	69e2                	ld	s3,24(sp)
    80003ef6:	6a42                	ld	s4,16(sp)
    80003ef8:	6121                	addi	sp,sp,64
    80003efa:	8082                	ret
    iput(ip);
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	a28080e7          	jalr	-1496(ra) # 80003924 <iput>
    return -1;
    80003f04:	57fd                	li	a5,-1
    80003f06:	b7d5                	j	80003eea <dirlink+0x84>
      panic("dirlink read");
    80003f08:	00004517          	auipc	a0,0x4
    80003f0c:	6b850513          	addi	a0,a0,1720 # 800085c0 <syscalls+0x200>
    80003f10:	ffffc097          	auipc	ra,0xffffc
    80003f14:	648080e7          	jalr	1608(ra) # 80000558 <panic>
    panic("dirlink");
    80003f18:	00004517          	auipc	a0,0x4
    80003f1c:	7b850513          	addi	a0,a0,1976 # 800086d0 <syscalls+0x310>
    80003f20:	ffffc097          	auipc	ra,0xffffc
    80003f24:	638080e7          	jalr	1592(ra) # 80000558 <panic>

0000000080003f28 <namei>:

struct inode*
namei(char *path)
{
    80003f28:	1101                	addi	sp,sp,-32
    80003f2a:	ec06                	sd	ra,24(sp)
    80003f2c:	e822                	sd	s0,16(sp)
    80003f2e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f30:	fe040613          	addi	a2,s0,-32
    80003f34:	4581                	li	a1,0
    80003f36:	00000097          	auipc	ra,0x0
    80003f3a:	dc8080e7          	jalr	-568(ra) # 80003cfe <namex>
}
    80003f3e:	60e2                	ld	ra,24(sp)
    80003f40:	6442                	ld	s0,16(sp)
    80003f42:	6105                	addi	sp,sp,32
    80003f44:	8082                	ret

0000000080003f46 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f46:	1141                	addi	sp,sp,-16
    80003f48:	e406                	sd	ra,8(sp)
    80003f4a:	e022                	sd	s0,0(sp)
    80003f4c:	0800                	addi	s0,sp,16
  return namex(path, 1, name);
    80003f4e:	862e                	mv	a2,a1
    80003f50:	4585                	li	a1,1
    80003f52:	00000097          	auipc	ra,0x0
    80003f56:	dac080e7          	jalr	-596(ra) # 80003cfe <namex>
}
    80003f5a:	60a2                	ld	ra,8(sp)
    80003f5c:	6402                	ld	s0,0(sp)
    80003f5e:	0141                	addi	sp,sp,16
    80003f60:	8082                	ret

0000000080003f62 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f62:	1101                	addi	sp,sp,-32
    80003f64:	ec06                	sd	ra,24(sp)
    80003f66:	e822                	sd	s0,16(sp)
    80003f68:	e426                	sd	s1,8(sp)
    80003f6a:	e04a                	sd	s2,0(sp)
    80003f6c:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f6e:	00029917          	auipc	s2,0x29
    80003f72:	2ea90913          	addi	s2,s2,746 # 8002d258 <log>
    80003f76:	01892583          	lw	a1,24(s2)
    80003f7a:	02892503          	lw	a0,40(s2)
    80003f7e:	fffff097          	auipc	ra,0xfffff
    80003f82:	fa2080e7          	jalr	-94(ra) # 80002f20 <bread>
    80003f86:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f88:	02c92683          	lw	a3,44(s2)
    80003f8c:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f8e:	02d05763          	blez	a3,80003fbc <write_head+0x5a>
    80003f92:	00029797          	auipc	a5,0x29
    80003f96:	2f678793          	addi	a5,a5,758 # 8002d288 <log+0x30>
    80003f9a:	05c50713          	addi	a4,a0,92
    80003f9e:	36fd                	addiw	a3,a3,-1
    80003fa0:	1682                	slli	a3,a3,0x20
    80003fa2:	9281                	srli	a3,a3,0x20
    80003fa4:	068a                	slli	a3,a3,0x2
    80003fa6:	00029617          	auipc	a2,0x29
    80003faa:	2e660613          	addi	a2,a2,742 # 8002d28c <log+0x34>
    80003fae:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fb0:	4390                	lw	a2,0(a5)
    80003fb2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fb4:	0791                	addi	a5,a5,4
    80003fb6:	0711                	addi	a4,a4,4
    80003fb8:	fed79ce3          	bne	a5,a3,80003fb0 <write_head+0x4e>
  }
  bwrite(buf);
    80003fbc:	8526                	mv	a0,s1
    80003fbe:	fffff097          	auipc	ra,0xfffff
    80003fc2:	066080e7          	jalr	102(ra) # 80003024 <bwrite>
  brelse(buf);
    80003fc6:	8526                	mv	a0,s1
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	09a080e7          	jalr	154(ra) # 80003062 <brelse>
}
    80003fd0:	60e2                	ld	ra,24(sp)
    80003fd2:	6442                	ld	s0,16(sp)
    80003fd4:	64a2                	ld	s1,8(sp)
    80003fd6:	6902                	ld	s2,0(sp)
    80003fd8:	6105                	addi	sp,sp,32
    80003fda:	8082                	ret

0000000080003fdc <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fdc:	00029797          	auipc	a5,0x29
    80003fe0:	27c78793          	addi	a5,a5,636 # 8002d258 <log>
    80003fe4:	57dc                	lw	a5,44(a5)
    80003fe6:	0af05d63          	blez	a5,800040a0 <install_trans+0xc4>
{
    80003fea:	7139                	addi	sp,sp,-64
    80003fec:	fc06                	sd	ra,56(sp)
    80003fee:	f822                	sd	s0,48(sp)
    80003ff0:	f426                	sd	s1,40(sp)
    80003ff2:	f04a                	sd	s2,32(sp)
    80003ff4:	ec4e                	sd	s3,24(sp)
    80003ff6:	e852                	sd	s4,16(sp)
    80003ff8:	e456                	sd	s5,8(sp)
    80003ffa:	e05a                	sd	s6,0(sp)
    80003ffc:	0080                	addi	s0,sp,64
    80003ffe:	8b2a                	mv	s6,a0
    80004000:	00029a17          	auipc	s4,0x29
    80004004:	288a0a13          	addi	s4,s4,648 # 8002d288 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004008:	4981                	li	s3,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000400a:	00029917          	auipc	s2,0x29
    8000400e:	24e90913          	addi	s2,s2,590 # 8002d258 <log>
    80004012:	a035                	j	8000403e <install_trans+0x62>
      bunpin(dbuf);
    80004014:	8526                	mv	a0,s1
    80004016:	fffff097          	auipc	ra,0xfffff
    8000401a:	126080e7          	jalr	294(ra) # 8000313c <bunpin>
    brelse(lbuf);
    8000401e:	8556                	mv	a0,s5
    80004020:	fffff097          	auipc	ra,0xfffff
    80004024:	042080e7          	jalr	66(ra) # 80003062 <brelse>
    brelse(dbuf);
    80004028:	8526                	mv	a0,s1
    8000402a:	fffff097          	auipc	ra,0xfffff
    8000402e:	038080e7          	jalr	56(ra) # 80003062 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004032:	2985                	addiw	s3,s3,1
    80004034:	0a11                	addi	s4,s4,4
    80004036:	02c92783          	lw	a5,44(s2)
    8000403a:	04f9d963          	ble	a5,s3,8000408c <install_trans+0xb0>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000403e:	01892583          	lw	a1,24(s2)
    80004042:	013585bb          	addw	a1,a1,s3
    80004046:	2585                	addiw	a1,a1,1
    80004048:	02892503          	lw	a0,40(s2)
    8000404c:	fffff097          	auipc	ra,0xfffff
    80004050:	ed4080e7          	jalr	-300(ra) # 80002f20 <bread>
    80004054:	8aaa                	mv	s5,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004056:	000a2583          	lw	a1,0(s4)
    8000405a:	02892503          	lw	a0,40(s2)
    8000405e:	fffff097          	auipc	ra,0xfffff
    80004062:	ec2080e7          	jalr	-318(ra) # 80002f20 <bread>
    80004066:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004068:	40000613          	li	a2,1024
    8000406c:	058a8593          	addi	a1,s5,88
    80004070:	05850513          	addi	a0,a0,88
    80004074:	ffffd097          	auipc	ra,0xffffd
    80004078:	d18080e7          	jalr	-744(ra) # 80000d8c <memmove>
    bwrite(dbuf);  // write dst to disk
    8000407c:	8526                	mv	a0,s1
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	fa6080e7          	jalr	-90(ra) # 80003024 <bwrite>
    if(recovering == 0)
    80004086:	f80b1ce3          	bnez	s6,8000401e <install_trans+0x42>
    8000408a:	b769                	j	80004014 <install_trans+0x38>
}
    8000408c:	70e2                	ld	ra,56(sp)
    8000408e:	7442                	ld	s0,48(sp)
    80004090:	74a2                	ld	s1,40(sp)
    80004092:	7902                	ld	s2,32(sp)
    80004094:	69e2                	ld	s3,24(sp)
    80004096:	6a42                	ld	s4,16(sp)
    80004098:	6aa2                	ld	s5,8(sp)
    8000409a:	6b02                	ld	s6,0(sp)
    8000409c:	6121                	addi	sp,sp,64
    8000409e:	8082                	ret
    800040a0:	8082                	ret

00000000800040a2 <initlog>:
{
    800040a2:	7179                	addi	sp,sp,-48
    800040a4:	f406                	sd	ra,40(sp)
    800040a6:	f022                	sd	s0,32(sp)
    800040a8:	ec26                	sd	s1,24(sp)
    800040aa:	e84a                	sd	s2,16(sp)
    800040ac:	e44e                	sd	s3,8(sp)
    800040ae:	1800                	addi	s0,sp,48
    800040b0:	892a                	mv	s2,a0
    800040b2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040b4:	00029497          	auipc	s1,0x29
    800040b8:	1a448493          	addi	s1,s1,420 # 8002d258 <log>
    800040bc:	00004597          	auipc	a1,0x4
    800040c0:	51458593          	addi	a1,a1,1300 # 800085d0 <syscalls+0x210>
    800040c4:	8526                	mv	a0,s1
    800040c6:	ffffd097          	auipc	ra,0xffffd
    800040ca:	ace080e7          	jalr	-1330(ra) # 80000b94 <initlock>
  log.start = sb->logstart;
    800040ce:	0149a583          	lw	a1,20(s3)
    800040d2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040d4:	0109a783          	lw	a5,16(s3)
    800040d8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040da:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040de:	854a                	mv	a0,s2
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	e40080e7          	jalr	-448(ra) # 80002f20 <bread>
  log.lh.n = lh->n;
    800040e8:	4d3c                	lw	a5,88(a0)
    800040ea:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040ec:	02f05563          	blez	a5,80004116 <initlog+0x74>
    800040f0:	05c50713          	addi	a4,a0,92
    800040f4:	00029697          	auipc	a3,0x29
    800040f8:	19468693          	addi	a3,a3,404 # 8002d288 <log+0x30>
    800040fc:	37fd                	addiw	a5,a5,-1
    800040fe:	1782                	slli	a5,a5,0x20
    80004100:	9381                	srli	a5,a5,0x20
    80004102:	078a                	slli	a5,a5,0x2
    80004104:	06050613          	addi	a2,a0,96
    80004108:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000410a:	4310                	lw	a2,0(a4)
    8000410c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000410e:	0711                	addi	a4,a4,4
    80004110:	0691                	addi	a3,a3,4
    80004112:	fef71ce3          	bne	a4,a5,8000410a <initlog+0x68>
  brelse(buf);
    80004116:	fffff097          	auipc	ra,0xfffff
    8000411a:	f4c080e7          	jalr	-180(ra) # 80003062 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000411e:	4505                	li	a0,1
    80004120:	00000097          	auipc	ra,0x0
    80004124:	ebc080e7          	jalr	-324(ra) # 80003fdc <install_trans>
  log.lh.n = 0;
    80004128:	00029797          	auipc	a5,0x29
    8000412c:	1407ae23          	sw	zero,348(a5) # 8002d284 <log+0x2c>
  write_head(); // clear the log
    80004130:	00000097          	auipc	ra,0x0
    80004134:	e32080e7          	jalr	-462(ra) # 80003f62 <write_head>
}
    80004138:	70a2                	ld	ra,40(sp)
    8000413a:	7402                	ld	s0,32(sp)
    8000413c:	64e2                	ld	s1,24(sp)
    8000413e:	6942                	ld	s2,16(sp)
    80004140:	69a2                	ld	s3,8(sp)
    80004142:	6145                	addi	sp,sp,48
    80004144:	8082                	ret

0000000080004146 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004146:	1101                	addi	sp,sp,-32
    80004148:	ec06                	sd	ra,24(sp)
    8000414a:	e822                	sd	s0,16(sp)
    8000414c:	e426                	sd	s1,8(sp)
    8000414e:	e04a                	sd	s2,0(sp)
    80004150:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004152:	00029517          	auipc	a0,0x29
    80004156:	10650513          	addi	a0,a0,262 # 8002d258 <log>
    8000415a:	ffffd097          	auipc	ra,0xffffd
    8000415e:	aca080e7          	jalr	-1334(ra) # 80000c24 <acquire>
  while(1){
    if(log.committing){
    80004162:	00029497          	auipc	s1,0x29
    80004166:	0f648493          	addi	s1,s1,246 # 8002d258 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000416a:	4979                	li	s2,30
    8000416c:	a039                	j	8000417a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000416e:	85a6                	mv	a1,s1
    80004170:	8526                	mv	a0,s1
    80004172:	ffffe097          	auipc	ra,0xffffe
    80004176:	14e080e7          	jalr	334(ra) # 800022c0 <sleep>
    if(log.committing){
    8000417a:	50dc                	lw	a5,36(s1)
    8000417c:	fbed                	bnez	a5,8000416e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000417e:	509c                	lw	a5,32(s1)
    80004180:	0017871b          	addiw	a4,a5,1
    80004184:	0007069b          	sext.w	a3,a4
    80004188:	0027179b          	slliw	a5,a4,0x2
    8000418c:	9fb9                	addw	a5,a5,a4
    8000418e:	0017979b          	slliw	a5,a5,0x1
    80004192:	54d8                	lw	a4,44(s1)
    80004194:	9fb9                	addw	a5,a5,a4
    80004196:	00f95963          	ble	a5,s2,800041a8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000419a:	85a6                	mv	a1,s1
    8000419c:	8526                	mv	a0,s1
    8000419e:	ffffe097          	auipc	ra,0xffffe
    800041a2:	122080e7          	jalr	290(ra) # 800022c0 <sleep>
    800041a6:	bfd1                	j	8000417a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041a8:	00029517          	auipc	a0,0x29
    800041ac:	0b050513          	addi	a0,a0,176 # 8002d258 <log>
    800041b0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041b2:	ffffd097          	auipc	ra,0xffffd
    800041b6:	b26080e7          	jalr	-1242(ra) # 80000cd8 <release>
      break;
    }
  }
}
    800041ba:	60e2                	ld	ra,24(sp)
    800041bc:	6442                	ld	s0,16(sp)
    800041be:	64a2                	ld	s1,8(sp)
    800041c0:	6902                	ld	s2,0(sp)
    800041c2:	6105                	addi	sp,sp,32
    800041c4:	8082                	ret

00000000800041c6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041c6:	7139                	addi	sp,sp,-64
    800041c8:	fc06                	sd	ra,56(sp)
    800041ca:	f822                	sd	s0,48(sp)
    800041cc:	f426                	sd	s1,40(sp)
    800041ce:	f04a                	sd	s2,32(sp)
    800041d0:	ec4e                	sd	s3,24(sp)
    800041d2:	e852                	sd	s4,16(sp)
    800041d4:	e456                	sd	s5,8(sp)
    800041d6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041d8:	00029917          	auipc	s2,0x29
    800041dc:	08090913          	addi	s2,s2,128 # 8002d258 <log>
    800041e0:	854a                	mv	a0,s2
    800041e2:	ffffd097          	auipc	ra,0xffffd
    800041e6:	a42080e7          	jalr	-1470(ra) # 80000c24 <acquire>
  log.outstanding -= 1;
    800041ea:	02092783          	lw	a5,32(s2)
    800041ee:	37fd                	addiw	a5,a5,-1
    800041f0:	0007849b          	sext.w	s1,a5
    800041f4:	02f92023          	sw	a5,32(s2)
  if(log.committing)
    800041f8:	02492783          	lw	a5,36(s2)
    800041fc:	eba1                	bnez	a5,8000424c <end_op+0x86>
    panic("log.committing");
  if(log.outstanding == 0){
    800041fe:	ecb9                	bnez	s1,8000425c <end_op+0x96>
    do_commit = 1;
    log.committing = 1;
    80004200:	00029917          	auipc	s2,0x29
    80004204:	05890913          	addi	s2,s2,88 # 8002d258 <log>
    80004208:	4785                	li	a5,1
    8000420a:	02f92223          	sw	a5,36(s2)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000420e:	854a                	mv	a0,s2
    80004210:	ffffd097          	auipc	ra,0xffffd
    80004214:	ac8080e7          	jalr	-1336(ra) # 80000cd8 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004218:	02c92783          	lw	a5,44(s2)
    8000421c:	06f04763          	bgtz	a5,8000428a <end_op+0xc4>
    acquire(&log.lock);
    80004220:	00029497          	auipc	s1,0x29
    80004224:	03848493          	addi	s1,s1,56 # 8002d258 <log>
    80004228:	8526                	mv	a0,s1
    8000422a:	ffffd097          	auipc	ra,0xffffd
    8000422e:	9fa080e7          	jalr	-1542(ra) # 80000c24 <acquire>
    log.committing = 0;
    80004232:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004236:	8526                	mv	a0,s1
    80004238:	ffffe097          	auipc	ra,0xffffe
    8000423c:	20e080e7          	jalr	526(ra) # 80002446 <wakeup>
    release(&log.lock);
    80004240:	8526                	mv	a0,s1
    80004242:	ffffd097          	auipc	ra,0xffffd
    80004246:	a96080e7          	jalr	-1386(ra) # 80000cd8 <release>
}
    8000424a:	a03d                	j	80004278 <end_op+0xb2>
    panic("log.committing");
    8000424c:	00004517          	auipc	a0,0x4
    80004250:	38c50513          	addi	a0,a0,908 # 800085d8 <syscalls+0x218>
    80004254:	ffffc097          	auipc	ra,0xffffc
    80004258:	304080e7          	jalr	772(ra) # 80000558 <panic>
    wakeup(&log);
    8000425c:	00029497          	auipc	s1,0x29
    80004260:	ffc48493          	addi	s1,s1,-4 # 8002d258 <log>
    80004264:	8526                	mv	a0,s1
    80004266:	ffffe097          	auipc	ra,0xffffe
    8000426a:	1e0080e7          	jalr	480(ra) # 80002446 <wakeup>
  release(&log.lock);
    8000426e:	8526                	mv	a0,s1
    80004270:	ffffd097          	auipc	ra,0xffffd
    80004274:	a68080e7          	jalr	-1432(ra) # 80000cd8 <release>
}
    80004278:	70e2                	ld	ra,56(sp)
    8000427a:	7442                	ld	s0,48(sp)
    8000427c:	74a2                	ld	s1,40(sp)
    8000427e:	7902                	ld	s2,32(sp)
    80004280:	69e2                	ld	s3,24(sp)
    80004282:	6a42                	ld	s4,16(sp)
    80004284:	6aa2                	ld	s5,8(sp)
    80004286:	6121                	addi	sp,sp,64
    80004288:	8082                	ret
    8000428a:	00029a17          	auipc	s4,0x29
    8000428e:	ffea0a13          	addi	s4,s4,-2 # 8002d288 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004292:	00029917          	auipc	s2,0x29
    80004296:	fc690913          	addi	s2,s2,-58 # 8002d258 <log>
    8000429a:	01892583          	lw	a1,24(s2)
    8000429e:	9da5                	addw	a1,a1,s1
    800042a0:	2585                	addiw	a1,a1,1
    800042a2:	02892503          	lw	a0,40(s2)
    800042a6:	fffff097          	auipc	ra,0xfffff
    800042aa:	c7a080e7          	jalr	-902(ra) # 80002f20 <bread>
    800042ae:	89aa                	mv	s3,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042b0:	000a2583          	lw	a1,0(s4)
    800042b4:	02892503          	lw	a0,40(s2)
    800042b8:	fffff097          	auipc	ra,0xfffff
    800042bc:	c68080e7          	jalr	-920(ra) # 80002f20 <bread>
    800042c0:	8aaa                	mv	s5,a0
    memmove(to->data, from->data, BSIZE);
    800042c2:	40000613          	li	a2,1024
    800042c6:	05850593          	addi	a1,a0,88
    800042ca:	05898513          	addi	a0,s3,88
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	abe080e7          	jalr	-1346(ra) # 80000d8c <memmove>
    bwrite(to);  // write the log
    800042d6:	854e                	mv	a0,s3
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	d4c080e7          	jalr	-692(ra) # 80003024 <bwrite>
    brelse(from);
    800042e0:	8556                	mv	a0,s5
    800042e2:	fffff097          	auipc	ra,0xfffff
    800042e6:	d80080e7          	jalr	-640(ra) # 80003062 <brelse>
    brelse(to);
    800042ea:	854e                	mv	a0,s3
    800042ec:	fffff097          	auipc	ra,0xfffff
    800042f0:	d76080e7          	jalr	-650(ra) # 80003062 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f4:	2485                	addiw	s1,s1,1
    800042f6:	0a11                	addi	s4,s4,4
    800042f8:	02c92783          	lw	a5,44(s2)
    800042fc:	f8f4cfe3          	blt	s1,a5,8000429a <end_op+0xd4>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004300:	00000097          	auipc	ra,0x0
    80004304:	c62080e7          	jalr	-926(ra) # 80003f62 <write_head>
    install_trans(0); // Now install writes to home locations
    80004308:	4501                	li	a0,0
    8000430a:	00000097          	auipc	ra,0x0
    8000430e:	cd2080e7          	jalr	-814(ra) # 80003fdc <install_trans>
    log.lh.n = 0;
    80004312:	00029797          	auipc	a5,0x29
    80004316:	f607a923          	sw	zero,-142(a5) # 8002d284 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	c48080e7          	jalr	-952(ra) # 80003f62 <write_head>
    80004322:	bdfd                	j	80004220 <end_op+0x5a>

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
    80004330:	00029797          	auipc	a5,0x29
    80004334:	f2878793          	addi	a5,a5,-216 # 8002d258 <log>
    80004338:	57d8                	lw	a4,44(a5)
    8000433a:	47f5                	li	a5,29
    8000433c:	08e7c563          	blt	a5,a4,800043c6 <log_write+0xa2>
    80004340:	892a                	mv	s2,a0
    80004342:	00029797          	auipc	a5,0x29
    80004346:	f1678793          	addi	a5,a5,-234 # 8002d258 <log>
    8000434a:	4fdc                	lw	a5,28(a5)
    8000434c:	37fd                	addiw	a5,a5,-1
    8000434e:	06f75c63          	ble	a5,a4,800043c6 <log_write+0xa2>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004352:	00029797          	auipc	a5,0x29
    80004356:	f0678793          	addi	a5,a5,-250 # 8002d258 <log>
    8000435a:	539c                	lw	a5,32(a5)
    8000435c:	06f05d63          	blez	a5,800043d6 <log_write+0xb2>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004360:	00029497          	auipc	s1,0x29
    80004364:	ef848493          	addi	s1,s1,-264 # 8002d258 <log>
    80004368:	8526                	mv	a0,s1
    8000436a:	ffffd097          	auipc	ra,0xffffd
    8000436e:	8ba080e7          	jalr	-1862(ra) # 80000c24 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004372:	54d0                	lw	a2,44(s1)
    80004374:	0ac05063          	blez	a2,80004414 <log_write+0xf0>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004378:	00c92583          	lw	a1,12(s2)
    8000437c:	589c                	lw	a5,48(s1)
    8000437e:	0ab78363          	beq	a5,a1,80004424 <log_write+0x100>
    80004382:	00029717          	auipc	a4,0x29
    80004386:	f0a70713          	addi	a4,a4,-246 # 8002d28c <log+0x34>
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
    8000439e:	00029717          	auipc	a4,0x29
    800043a2:	eba70713          	addi	a4,a4,-326 # 8002d258 <log>
    800043a6:	97ba                	add	a5,a5,a4
    800043a8:	cb8c                	sw	a1,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    log.lh.n++;
  }
  release(&log.lock);
    800043aa:	00029517          	auipc	a0,0x29
    800043ae:	eae50513          	addi	a0,a0,-338 # 8002d258 <log>
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	926080e7          	jalr	-1754(ra) # 80000cd8 <release>
}
    800043ba:	60e2                	ld	ra,24(sp)
    800043bc:	6442                	ld	s0,16(sp)
    800043be:	64a2                	ld	s1,8(sp)
    800043c0:	6902                	ld	s2,0(sp)
    800043c2:	6105                	addi	sp,sp,32
    800043c4:	8082                	ret
    panic("too big a transaction");
    800043c6:	00004517          	auipc	a0,0x4
    800043ca:	22250513          	addi	a0,a0,546 # 800085e8 <syscalls+0x228>
    800043ce:	ffffc097          	auipc	ra,0xffffc
    800043d2:	18a080e7          	jalr	394(ra) # 80000558 <panic>
    panic("log_write outside of trans");
    800043d6:	00004517          	auipc	a0,0x4
    800043da:	22a50513          	addi	a0,a0,554 # 80008600 <syscalls+0x240>
    800043de:	ffffc097          	auipc	ra,0xffffc
    800043e2:	17a080e7          	jalr	378(ra) # 80000558 <panic>
  log.lh.block[i] = b->blockno;
    800043e6:	0621                	addi	a2,a2,8
    800043e8:	060a                	slli	a2,a2,0x2
    800043ea:	00029797          	auipc	a5,0x29
    800043ee:	e6e78793          	addi	a5,a5,-402 # 8002d258 <log>
    800043f2:	963e                	add	a2,a2,a5
    800043f4:	00c92783          	lw	a5,12(s2)
    800043f8:	ca1c                	sw	a5,16(a2)
    bpin(b);
    800043fa:	854a                	mv	a0,s2
    800043fc:	fffff097          	auipc	ra,0xfffff
    80004400:	d04080e7          	jalr	-764(ra) # 80003100 <bpin>
    log.lh.n++;
    80004404:	00029717          	auipc	a4,0x29
    80004408:	e5470713          	addi	a4,a4,-428 # 8002d258 <log>
    8000440c:	575c                	lw	a5,44(a4)
    8000440e:	2785                	addiw	a5,a5,1
    80004410:	d75c                	sw	a5,44(a4)
    80004412:	bf61                	j	800043aa <log_write+0x86>
  log.lh.block[i] = b->blockno;
    80004414:	00c92783          	lw	a5,12(s2)
    80004418:	00029717          	auipc	a4,0x29
    8000441c:	e6f72823          	sw	a5,-400(a4) # 8002d288 <log+0x30>
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
    8000443c:	1e858593          	addi	a1,a1,488 # 80008620 <syscalls+0x260>
    80004440:	0521                	addi	a0,a0,8
    80004442:	ffffc097          	auipc	ra,0xffffc
    80004446:	752080e7          	jalr	1874(ra) # 80000b94 <initlock>
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
    8000447a:	7ae080e7          	jalr	1966(ra) # 80000c24 <acquire>
  while (lk->locked) {
    8000447e:	409c                	lw	a5,0(s1)
    80004480:	cb89                	beqz	a5,80004492 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004482:	85ca                	mv	a1,s2
    80004484:	8526                	mv	a0,s1
    80004486:	ffffe097          	auipc	ra,0xffffe
    8000448a:	e3a080e7          	jalr	-454(ra) # 800022c0 <sleep>
  while (lk->locked) {
    8000448e:	409c                	lw	a5,0(s1)
    80004490:	fbed                	bnez	a5,80004482 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004492:	4785                	li	a5,1
    80004494:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004496:	ffffd097          	auipc	ra,0xffffd
    8000449a:	5a8080e7          	jalr	1448(ra) # 80001a3e <myproc>
    8000449e:	5d1c                	lw	a5,56(a0)
    800044a0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044a2:	854a                	mv	a0,s2
    800044a4:	ffffd097          	auipc	ra,0xffffd
    800044a8:	834080e7          	jalr	-1996(ra) # 80000cd8 <release>
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
    800044d0:	758080e7          	jalr	1880(ra) # 80000c24 <acquire>
  lk->locked = 0;
    800044d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044d8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044dc:	8526                	mv	a0,s1
    800044de:	ffffe097          	auipc	ra,0xffffe
    800044e2:	f68080e7          	jalr	-152(ra) # 80002446 <wakeup>
  release(&lk->lk);
    800044e6:	854a                	mv	a0,s2
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	7f0080e7          	jalr	2032(ra) # 80000cd8 <release>
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
    80004516:	712080e7          	jalr	1810(ra) # 80000c24 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000451a:	409c                	lw	a5,0(s1)
    8000451c:	ef99                	bnez	a5,8000453a <holdingsleep+0x3e>
    8000451e:	4481                	li	s1,0
  release(&lk->lk);
    80004520:	854a                	mv	a0,s2
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	7b6080e7          	jalr	1974(ra) # 80000cd8 <release>
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
    80004542:	500080e7          	jalr	1280(ra) # 80001a3e <myproc>
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
    8000455e:	0d658593          	addi	a1,a1,214 # 80008630 <syscalls+0x270>
    80004562:	00029517          	auipc	a0,0x29
    80004566:	e3e50513          	addi	a0,a0,-450 # 8002d3a0 <ftable>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	62a080e7          	jalr	1578(ra) # 80000b94 <initlock>
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
    80004584:	00029517          	auipc	a0,0x29
    80004588:	e1c50513          	addi	a0,a0,-484 # 8002d3a0 <ftable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	698080e7          	jalr	1688(ra) # 80000c24 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    if(f->ref == 0){
    80004594:	00029797          	auipc	a5,0x29
    80004598:	e0c78793          	addi	a5,a5,-500 # 8002d3a0 <ftable>
    8000459c:	4fdc                	lw	a5,28(a5)
    8000459e:	cb8d                	beqz	a5,800045d0 <filealloc+0x56>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a0:	00029497          	auipc	s1,0x29
    800045a4:	e4048493          	addi	s1,s1,-448 # 8002d3e0 <ftable+0x40>
    800045a8:	0002a717          	auipc	a4,0x2a
    800045ac:	db070713          	addi	a4,a4,-592 # 8002e358 <ftable+0xfb8>
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
    800045bc:	00029517          	auipc	a0,0x29
    800045c0:	de450513          	addi	a0,a0,-540 # 8002d3a0 <ftable>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	714080e7          	jalr	1812(ra) # 80000cd8 <release>
  return 0;
    800045cc:	4481                	li	s1,0
    800045ce:	a839                	j	800045ec <filealloc+0x72>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045d0:	00029497          	auipc	s1,0x29
    800045d4:	de848493          	addi	s1,s1,-536 # 8002d3b8 <ftable+0x18>
      f->ref = 1;
    800045d8:	4785                	li	a5,1
    800045da:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045dc:	00029517          	auipc	a0,0x29
    800045e0:	dc450513          	addi	a0,a0,-572 # 8002d3a0 <ftable>
    800045e4:	ffffc097          	auipc	ra,0xffffc
    800045e8:	6f4080e7          	jalr	1780(ra) # 80000cd8 <release>
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
    80004604:	00029517          	auipc	a0,0x29
    80004608:	d9c50513          	addi	a0,a0,-612 # 8002d3a0 <ftable>
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	618080e7          	jalr	1560(ra) # 80000c24 <acquire>
  if(f->ref < 1)
    80004614:	40dc                	lw	a5,4(s1)
    80004616:	02f05263          	blez	a5,8000463a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000461a:	2785                	addiw	a5,a5,1
    8000461c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000461e:	00029517          	auipc	a0,0x29
    80004622:	d8250513          	addi	a0,a0,-638 # 8002d3a0 <ftable>
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	6b2080e7          	jalr	1714(ra) # 80000cd8 <release>
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
    8000463e:	ffe50513          	addi	a0,a0,-2 # 80008638 <syscalls+0x278>
    80004642:	ffffc097          	auipc	ra,0xffffc
    80004646:	f16080e7          	jalr	-234(ra) # 80000558 <panic>

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
    8000465e:	00029517          	auipc	a0,0x29
    80004662:	d4250513          	addi	a0,a0,-702 # 8002d3a0 <ftable>
    80004666:	ffffc097          	auipc	ra,0xffffc
    8000466a:	5be080e7          	jalr	1470(ra) # 80000c24 <acquire>
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
    80004698:	00029517          	auipc	a0,0x29
    8000469c:	d0850513          	addi	a0,a0,-760 # 8002d3a0 <ftable>
    800046a0:	ffffc097          	auipc	ra,0xffffc
    800046a4:	638080e7          	jalr	1592(ra) # 80000cd8 <release>

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
    800046ba:	a90080e7          	jalr	-1392(ra) # 80004146 <begin_op>
    iput(ff.ip);
    800046be:	854e                	mv	a0,s3
    800046c0:	fffff097          	auipc	ra,0xfffff
    800046c4:	264080e7          	jalr	612(ra) # 80003924 <iput>
    end_op();
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	afe080e7          	jalr	-1282(ra) # 800041c6 <end_op>
    800046d0:	a00d                	j	800046f2 <fileclose+0xa8>
    panic("fileclose");
    800046d2:	00004517          	auipc	a0,0x4
    800046d6:	f6e50513          	addi	a0,a0,-146 # 80008640 <syscalls+0x280>
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	e7e080e7          	jalr	-386(ra) # 80000558 <panic>
    release(&ftable.lock);
    800046e2:	00029517          	auipc	a0,0x29
    800046e6:	cbe50513          	addi	a0,a0,-834 # 8002d3a0 <ftable>
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	5ee080e7          	jalr	1518(ra) # 80000cd8 <release>
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
    8000470c:	340080e7          	jalr	832(ra) # 80004a48 <pipeclose>
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
    80004728:	31a080e7          	jalr	794(ra) # 80001a3e <myproc>
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
    8000473e:	02e080e7          	jalr	46(ra) # 80003768 <ilock>
    stati(f->ip, &st);
    80004742:	fb840593          	addi	a1,s0,-72
    80004746:	6c88                	ld	a0,24(s1)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	2ac080e7          	jalr	684(ra) # 800039f4 <stati>
    iunlock(f->ip);
    80004750:	6c88                	ld	a0,24(s1)
    80004752:	fffff097          	auipc	ra,0xfffff
    80004756:	0da080e7          	jalr	218(ra) # 8000382c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000475a:	46e1                	li	a3,24
    8000475c:	fb840613          	addi	a2,s0,-72
    80004760:	85ce                	mv	a1,s3
    80004762:	05093503          	ld	a0,80(s2)
    80004766:	ffffd097          	auipc	ra,0xffffd
    8000476a:	f44080e7          	jalr	-188(ra) # 800016aa <copyout>
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
    800047b8:	fb4080e7          	jalr	-76(ra) # 80003768 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047bc:	874e                	mv	a4,s3
    800047be:	5094                	lw	a3,32(s1)
    800047c0:	864a                	mv	a2,s2
    800047c2:	4585                	li	a1,1
    800047c4:	6c88                	ld	a0,24(s1)
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	258080e7          	jalr	600(ra) # 80003a1e <readi>
    800047ce:	892a                	mv	s2,a0
    800047d0:	00a05563          	blez	a0,800047da <fileread+0x56>
      f->off += r;
    800047d4:	509c                	lw	a5,32(s1)
    800047d6:	9fa9                	addw	a5,a5,a0
    800047d8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047da:	6c88                	ld	a0,24(s1)
    800047dc:	fffff097          	auipc	ra,0xfffff
    800047e0:	050080e7          	jalr	80(ra) # 8000382c <iunlock>
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
    800047fa:	3c8080e7          	jalr	968(ra) # 80004bbe <piperead>
    800047fe:	892a                	mv	s2,a0
    80004800:	b7d5                	j	800047e4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004802:	02451783          	lh	a5,36(a0)
    80004806:	03079693          	slli	a3,a5,0x30
    8000480a:	92c1                	srli	a3,a3,0x30
    8000480c:	4725                	li	a4,9
    8000480e:	02d76863          	bltu	a4,a3,8000483e <fileread+0xba>
    80004812:	0792                	slli	a5,a5,0x4
    80004814:	00029717          	auipc	a4,0x29
    80004818:	aec70713          	addi	a4,a4,-1300 # 8002d300 <devsw>
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
    8000482e:	e2650513          	addi	a0,a0,-474 # 80008650 <syscalls+0x290>
    80004832:	ffffc097          	auipc	ra,0xffffc
    80004836:	d26080e7          	jalr	-730(ra) # 80000558 <panic>
    return -1;
    8000483a:	597d                	li	s2,-1
    8000483c:	b765                	j	800047e4 <fileread+0x60>
      return -1;
    8000483e:	597d                	li	s2,-1
    80004840:	b755                	j	800047e4 <fileread+0x60>
    80004842:	597d                	li	s2,-1
    80004844:	b745                	j	800047e4 <fileread+0x60>

0000000080004846 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004846:	715d                	addi	sp,sp,-80
    80004848:	e486                	sd	ra,72(sp)
    8000484a:	e0a2                	sd	s0,64(sp)
    8000484c:	fc26                	sd	s1,56(sp)
    8000484e:	f84a                	sd	s2,48(sp)
    80004850:	f44e                	sd	s3,40(sp)
    80004852:	f052                	sd	s4,32(sp)
    80004854:	ec56                	sd	s5,24(sp)
    80004856:	e85a                	sd	s6,16(sp)
    80004858:	e45e                	sd	s7,8(sp)
    8000485a:	e062                	sd	s8,0(sp)
    8000485c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000485e:	00954783          	lbu	a5,9(a0)
    80004862:	10078063          	beqz	a5,80004962 <filewrite+0x11c>
    80004866:	84aa                	mv	s1,a0
    80004868:	8bae                	mv	s7,a1
    8000486a:	8ab2                	mv	s5,a2
    return -1;

  if(f->type == FD_PIPE){
    8000486c:	411c                	lw	a5,0(a0)
    8000486e:	4705                	li	a4,1
    80004870:	02e78263          	beq	a5,a4,80004894 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004874:	470d                	li	a4,3
    80004876:	02e78663          	beq	a5,a4,800048a2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000487a:	4709                	li	a4,2
    8000487c:	0ce79b63          	bne	a5,a4,80004952 <filewrite+0x10c>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004880:	0ac05763          	blez	a2,8000492e <filewrite+0xe8>
    int i = 0;
    80004884:	4901                	li	s2,0
    80004886:	6b05                	lui	s6,0x1
    80004888:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000488c:	6c05                	lui	s8,0x1
    8000488e:	c00c0c1b          	addiw	s8,s8,-1024
    80004892:	a071                	j	8000491e <filewrite+0xd8>
    ret = pipewrite(f->pipe, addr, n);
    80004894:	6908                	ld	a0,16(a0)
    80004896:	00000097          	auipc	ra,0x0
    8000489a:	222080e7          	jalr	546(ra) # 80004ab8 <pipewrite>
    8000489e:	8aaa                	mv	s5,a0
    800048a0:	a851                	j	80004934 <filewrite+0xee>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048a2:	02451783          	lh	a5,36(a0)
    800048a6:	03079693          	slli	a3,a5,0x30
    800048aa:	92c1                	srli	a3,a3,0x30
    800048ac:	4725                	li	a4,9
    800048ae:	0ad76c63          	bltu	a4,a3,80004966 <filewrite+0x120>
    800048b2:	0792                	slli	a5,a5,0x4
    800048b4:	00029717          	auipc	a4,0x29
    800048b8:	a4c70713          	addi	a4,a4,-1460 # 8002d300 <devsw>
    800048bc:	97ba                	add	a5,a5,a4
    800048be:	679c                	ld	a5,8(a5)
    800048c0:	c7cd                	beqz	a5,8000496a <filewrite+0x124>
    ret = devsw[f->major].write(1, addr, n);
    800048c2:	4505                	li	a0,1
    800048c4:	9782                	jalr	a5
    800048c6:	8aaa                	mv	s5,a0
    800048c8:	a0b5                	j	80004934 <filewrite+0xee>
    800048ca:	00098a1b          	sext.w	s4,s3
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ce:	00000097          	auipc	ra,0x0
    800048d2:	878080e7          	jalr	-1928(ra) # 80004146 <begin_op>
      ilock(f->ip);
    800048d6:	6c88                	ld	a0,24(s1)
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	e90080e7          	jalr	-368(ra) # 80003768 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048e0:	8752                	mv	a4,s4
    800048e2:	5094                	lw	a3,32(s1)
    800048e4:	01790633          	add	a2,s2,s7
    800048e8:	4585                	li	a1,1
    800048ea:	6c88                	ld	a0,24(s1)
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	22a080e7          	jalr	554(ra) # 80003b16 <writei>
    800048f4:	89aa                	mv	s3,a0
    800048f6:	00a05563          	blez	a0,80004900 <filewrite+0xba>
        f->off += r;
    800048fa:	509c                	lw	a5,32(s1)
    800048fc:	9fa9                	addw	a5,a5,a0
    800048fe:	d09c                	sw	a5,32(s1)
      iunlock(f->ip);
    80004900:	6c88                	ld	a0,24(s1)
    80004902:	fffff097          	auipc	ra,0xfffff
    80004906:	f2a080e7          	jalr	-214(ra) # 8000382c <iunlock>
      end_op();
    8000490a:	00000097          	auipc	ra,0x0
    8000490e:	8bc080e7          	jalr	-1860(ra) # 800041c6 <end_op>

      if(r != n1){
    80004912:	01499f63          	bne	s3,s4,80004930 <filewrite+0xea>
        // error from writei
        break;
      }
      i += r;
    80004916:	012a093b          	addw	s2,s4,s2
    while(i < n){
    8000491a:	01595b63          	ble	s5,s2,80004930 <filewrite+0xea>
      int n1 = n - i;
    8000491e:	412a87bb          	subw	a5,s5,s2
      if(n1 > max)
    80004922:	89be                	mv	s3,a5
    80004924:	2781                	sext.w	a5,a5
    80004926:	fafb52e3          	ble	a5,s6,800048ca <filewrite+0x84>
    8000492a:	89e2                	mv	s3,s8
    8000492c:	bf79                	j	800048ca <filewrite+0x84>
    int i = 0;
    8000492e:	4901                	li	s2,0
    }
    ret = (i == n ? n : -1);
    80004930:	012a9f63          	bne	s5,s2,8000494e <filewrite+0x108>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004934:	8556                	mv	a0,s5
    80004936:	60a6                	ld	ra,72(sp)
    80004938:	6406                	ld	s0,64(sp)
    8000493a:	74e2                	ld	s1,56(sp)
    8000493c:	7942                	ld	s2,48(sp)
    8000493e:	79a2                	ld	s3,40(sp)
    80004940:	7a02                	ld	s4,32(sp)
    80004942:	6ae2                	ld	s5,24(sp)
    80004944:	6b42                	ld	s6,16(sp)
    80004946:	6ba2                	ld	s7,8(sp)
    80004948:	6c02                	ld	s8,0(sp)
    8000494a:	6161                	addi	sp,sp,80
    8000494c:	8082                	ret
    ret = (i == n ? n : -1);
    8000494e:	5afd                	li	s5,-1
    80004950:	b7d5                	j	80004934 <filewrite+0xee>
    panic("filewrite");
    80004952:	00004517          	auipc	a0,0x4
    80004956:	d0e50513          	addi	a0,a0,-754 # 80008660 <syscalls+0x2a0>
    8000495a:	ffffc097          	auipc	ra,0xffffc
    8000495e:	bfe080e7          	jalr	-1026(ra) # 80000558 <panic>
    return -1;
    80004962:	5afd                	li	s5,-1
    80004964:	bfc1                	j	80004934 <filewrite+0xee>
      return -1;
    80004966:	5afd                	li	s5,-1
    80004968:	b7f1                	j	80004934 <filewrite+0xee>
    8000496a:	5afd                	li	s5,-1
    8000496c:	b7e1                	j	80004934 <filewrite+0xee>

000000008000496e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000496e:	7179                	addi	sp,sp,-48
    80004970:	f406                	sd	ra,40(sp)
    80004972:	f022                	sd	s0,32(sp)
    80004974:	ec26                	sd	s1,24(sp)
    80004976:	e84a                	sd	s2,16(sp)
    80004978:	e44e                	sd	s3,8(sp)
    8000497a:	e052                	sd	s4,0(sp)
    8000497c:	1800                	addi	s0,sp,48
    8000497e:	84aa                	mv	s1,a0
    80004980:	892e                	mv	s2,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004982:	0005b023          	sd	zero,0(a1)
    80004986:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000498a:	00000097          	auipc	ra,0x0
    8000498e:	bf0080e7          	jalr	-1040(ra) # 8000457a <filealloc>
    80004992:	e088                	sd	a0,0(s1)
    80004994:	c551                	beqz	a0,80004a20 <pipealloc+0xb2>
    80004996:	00000097          	auipc	ra,0x0
    8000499a:	be4080e7          	jalr	-1052(ra) # 8000457a <filealloc>
    8000499e:	00a93023          	sd	a0,0(s2)
    800049a2:	c92d                	beqz	a0,80004a14 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	190080e7          	jalr	400(ra) # 80000b34 <kalloc>
    800049ac:	89aa                	mv	s3,a0
    800049ae:	c125                	beqz	a0,80004a0e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049b0:	4a05                	li	s4,1
    800049b2:	23452023          	sw	s4,544(a0)
  pi->writeopen = 1;
    800049b6:	23452223          	sw	s4,548(a0)
  pi->nwrite = 0;
    800049ba:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049be:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c2:	00004597          	auipc	a1,0x4
    800049c6:	cae58593          	addi	a1,a1,-850 # 80008670 <syscalls+0x2b0>
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	1ca080e7          	jalr	458(ra) # 80000b94 <initlock>
  (*f0)->type = FD_PIPE;
    800049d2:	609c                	ld	a5,0(s1)
    800049d4:	0147a023          	sw	s4,0(a5)
  (*f0)->readable = 1;
    800049d8:	609c                	ld	a5,0(s1)
    800049da:	01478423          	sb	s4,8(a5)
  (*f0)->writable = 0;
    800049de:	609c                	ld	a5,0(s1)
    800049e0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049e4:	609c                	ld	a5,0(s1)
    800049e6:	0137b823          	sd	s3,16(a5)
  (*f1)->type = FD_PIPE;
    800049ea:	00093783          	ld	a5,0(s2)
    800049ee:	0147a023          	sw	s4,0(a5)
  (*f1)->readable = 0;
    800049f2:	00093783          	ld	a5,0(s2)
    800049f6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049fa:	00093783          	ld	a5,0(s2)
    800049fe:	014784a3          	sb	s4,9(a5)
  (*f1)->pipe = pi;
    80004a02:	00093783          	ld	a5,0(s2)
    80004a06:	0137b823          	sd	s3,16(a5)
  return 0;
    80004a0a:	4501                	li	a0,0
    80004a0c:	a025                	j	80004a34 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a0e:	6088                	ld	a0,0(s1)
    80004a10:	e501                	bnez	a0,80004a18 <pipealloc+0xaa>
    80004a12:	a039                	j	80004a20 <pipealloc+0xb2>
    80004a14:	6088                	ld	a0,0(s1)
    80004a16:	c51d                	beqz	a0,80004a44 <pipealloc+0xd6>
    fileclose(*f0);
    80004a18:	00000097          	auipc	ra,0x0
    80004a1c:	c32080e7          	jalr	-974(ra) # 8000464a <fileclose>
  if(*f1)
    80004a20:	00093783          	ld	a5,0(s2)
    fileclose(*f1);
  return -1;
    80004a24:	557d                	li	a0,-1
  if(*f1)
    80004a26:	c799                	beqz	a5,80004a34 <pipealloc+0xc6>
    fileclose(*f1);
    80004a28:	853e                	mv	a0,a5
    80004a2a:	00000097          	auipc	ra,0x0
    80004a2e:	c20080e7          	jalr	-992(ra) # 8000464a <fileclose>
  return -1;
    80004a32:	557d                	li	a0,-1
}
    80004a34:	70a2                	ld	ra,40(sp)
    80004a36:	7402                	ld	s0,32(sp)
    80004a38:	64e2                	ld	s1,24(sp)
    80004a3a:	6942                	ld	s2,16(sp)
    80004a3c:	69a2                	ld	s3,8(sp)
    80004a3e:	6a02                	ld	s4,0(sp)
    80004a40:	6145                	addi	sp,sp,48
    80004a42:	8082                	ret
  return -1;
    80004a44:	557d                	li	a0,-1
    80004a46:	b7fd                	j	80004a34 <pipealloc+0xc6>

0000000080004a48 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a48:	1101                	addi	sp,sp,-32
    80004a4a:	ec06                	sd	ra,24(sp)
    80004a4c:	e822                	sd	s0,16(sp)
    80004a4e:	e426                	sd	s1,8(sp)
    80004a50:	e04a                	sd	s2,0(sp)
    80004a52:	1000                	addi	s0,sp,32
    80004a54:	84aa                	mv	s1,a0
    80004a56:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	1cc080e7          	jalr	460(ra) # 80000c24 <acquire>
  if(writable){
    80004a60:	02090d63          	beqz	s2,80004a9a <pipeclose+0x52>
    pi->writeopen = 0;
    80004a64:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a68:	21848513          	addi	a0,s1,536
    80004a6c:	ffffe097          	auipc	ra,0xffffe
    80004a70:	9da080e7          	jalr	-1574(ra) # 80002446 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a74:	2204b783          	ld	a5,544(s1)
    80004a78:	eb95                	bnez	a5,80004aac <pipeclose+0x64>
    release(&pi->lock);
    80004a7a:	8526                	mv	a0,s1
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	25c080e7          	jalr	604(ra) # 80000cd8 <release>
    kfree((char*)pi);
    80004a84:	8526                	mv	a0,s1
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	fae080e7          	jalr	-82(ra) # 80000a34 <kfree>
  } else
    release(&pi->lock);
}
    80004a8e:	60e2                	ld	ra,24(sp)
    80004a90:	6442                	ld	s0,16(sp)
    80004a92:	64a2                	ld	s1,8(sp)
    80004a94:	6902                	ld	s2,0(sp)
    80004a96:	6105                	addi	sp,sp,32
    80004a98:	8082                	ret
    pi->readopen = 0;
    80004a9a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a9e:	21c48513          	addi	a0,s1,540
    80004aa2:	ffffe097          	auipc	ra,0xffffe
    80004aa6:	9a4080e7          	jalr	-1628(ra) # 80002446 <wakeup>
    80004aaa:	b7e9                	j	80004a74 <pipeclose+0x2c>
    release(&pi->lock);
    80004aac:	8526                	mv	a0,s1
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	22a080e7          	jalr	554(ra) # 80000cd8 <release>
}
    80004ab6:	bfe1                	j	80004a8e <pipeclose+0x46>

0000000080004ab8 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ab8:	7159                	addi	sp,sp,-112
    80004aba:	f486                	sd	ra,104(sp)
    80004abc:	f0a2                	sd	s0,96(sp)
    80004abe:	eca6                	sd	s1,88(sp)
    80004ac0:	e8ca                	sd	s2,80(sp)
    80004ac2:	e4ce                	sd	s3,72(sp)
    80004ac4:	e0d2                	sd	s4,64(sp)
    80004ac6:	fc56                	sd	s5,56(sp)
    80004ac8:	f85a                	sd	s6,48(sp)
    80004aca:	f45e                	sd	s7,40(sp)
    80004acc:	f062                	sd	s8,32(sp)
    80004ace:	ec66                	sd	s9,24(sp)
    80004ad0:	1880                	addi	s0,sp,112
    80004ad2:	84aa                	mv	s1,a0
    80004ad4:	8aae                	mv	s5,a1
    80004ad6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ad8:	ffffd097          	auipc	ra,0xffffd
    80004adc:	f66080e7          	jalr	-154(ra) # 80001a3e <myproc>
    80004ae0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ae2:	8526                	mv	a0,s1
    80004ae4:	ffffc097          	auipc	ra,0xffffc
    80004ae8:	140080e7          	jalr	320(ra) # 80000c24 <acquire>
  while(i < n){
    80004aec:	0d405763          	blez	s4,80004bba <pipewrite+0x102>
    80004af0:	8ba6                	mv	s7,s1
    if(pi->readopen == 0 || pr->killed){
    80004af2:	2204a783          	lw	a5,544(s1)
    80004af6:	cb99                	beqz	a5,80004b0c <pipewrite+0x54>
    80004af8:	0309a903          	lw	s2,48(s3)
    80004afc:	00091863          	bnez	s2,80004b0c <pipewrite+0x54>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b00:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b02:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b06:	21c48c13          	addi	s8,s1,540
    80004b0a:	a0bd                	j	80004b78 <pipewrite+0xc0>
      release(&pi->lock);
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	ffffc097          	auipc	ra,0xffffc
    80004b12:	1ca080e7          	jalr	458(ra) # 80000cd8 <release>
      return -1;
    80004b16:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b18:	854a                	mv	a0,s2
    80004b1a:	70a6                	ld	ra,104(sp)
    80004b1c:	7406                	ld	s0,96(sp)
    80004b1e:	64e6                	ld	s1,88(sp)
    80004b20:	6946                	ld	s2,80(sp)
    80004b22:	69a6                	ld	s3,72(sp)
    80004b24:	6a06                	ld	s4,64(sp)
    80004b26:	7ae2                	ld	s5,56(sp)
    80004b28:	7b42                	ld	s6,48(sp)
    80004b2a:	7ba2                	ld	s7,40(sp)
    80004b2c:	7c02                	ld	s8,32(sp)
    80004b2e:	6ce2                	ld	s9,24(sp)
    80004b30:	6165                	addi	sp,sp,112
    80004b32:	8082                	ret
      wakeup(&pi->nread);
    80004b34:	8566                	mv	a0,s9
    80004b36:	ffffe097          	auipc	ra,0xffffe
    80004b3a:	910080e7          	jalr	-1776(ra) # 80002446 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b3e:	85de                	mv	a1,s7
    80004b40:	8562                	mv	a0,s8
    80004b42:	ffffd097          	auipc	ra,0xffffd
    80004b46:	77e080e7          	jalr	1918(ra) # 800022c0 <sleep>
    80004b4a:	a839                	j	80004b68 <pipewrite+0xb0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b4c:	21c4a783          	lw	a5,540(s1)
    80004b50:	0017871b          	addiw	a4,a5,1
    80004b54:	20e4ae23          	sw	a4,540(s1)
    80004b58:	1ff7f793          	andi	a5,a5,511
    80004b5c:	97a6                	add	a5,a5,s1
    80004b5e:	f9f44703          	lbu	a4,-97(s0)
    80004b62:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b66:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b68:	03495d63          	ble	s4,s2,80004ba2 <pipewrite+0xea>
    if(pi->readopen == 0 || pr->killed){
    80004b6c:	2204a783          	lw	a5,544(s1)
    80004b70:	dfd1                	beqz	a5,80004b0c <pipewrite+0x54>
    80004b72:	0309a783          	lw	a5,48(s3)
    80004b76:	fbd9                	bnez	a5,80004b0c <pipewrite+0x54>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b78:	2184a783          	lw	a5,536(s1)
    80004b7c:	21c4a703          	lw	a4,540(s1)
    80004b80:	2007879b          	addiw	a5,a5,512
    80004b84:	faf708e3          	beq	a4,a5,80004b34 <pipewrite+0x7c>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b88:	4685                	li	a3,1
    80004b8a:	01590633          	add	a2,s2,s5
    80004b8e:	f9f40593          	addi	a1,s0,-97
    80004b92:	0509b503          	ld	a0,80(s3)
    80004b96:	ffffd097          	auipc	ra,0xffffd
    80004b9a:	ba0080e7          	jalr	-1120(ra) # 80001736 <copyin>
    80004b9e:	fb6517e3          	bne	a0,s6,80004b4c <pipewrite+0x94>
  wakeup(&pi->nread);
    80004ba2:	21848513          	addi	a0,s1,536
    80004ba6:	ffffe097          	auipc	ra,0xffffe
    80004baa:	8a0080e7          	jalr	-1888(ra) # 80002446 <wakeup>
  release(&pi->lock);
    80004bae:	8526                	mv	a0,s1
    80004bb0:	ffffc097          	auipc	ra,0xffffc
    80004bb4:	128080e7          	jalr	296(ra) # 80000cd8 <release>
  return i;
    80004bb8:	b785                	j	80004b18 <pipewrite+0x60>
  int i = 0;
    80004bba:	4901                	li	s2,0
    80004bbc:	b7dd                	j	80004ba2 <pipewrite+0xea>

0000000080004bbe <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bbe:	715d                	addi	sp,sp,-80
    80004bc0:	e486                	sd	ra,72(sp)
    80004bc2:	e0a2                	sd	s0,64(sp)
    80004bc4:	fc26                	sd	s1,56(sp)
    80004bc6:	f84a                	sd	s2,48(sp)
    80004bc8:	f44e                	sd	s3,40(sp)
    80004bca:	f052                	sd	s4,32(sp)
    80004bcc:	ec56                	sd	s5,24(sp)
    80004bce:	e85a                	sd	s6,16(sp)
    80004bd0:	0880                	addi	s0,sp,80
    80004bd2:	84aa                	mv	s1,a0
    80004bd4:	89ae                	mv	s3,a1
    80004bd6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bd8:	ffffd097          	auipc	ra,0xffffd
    80004bdc:	e66080e7          	jalr	-410(ra) # 80001a3e <myproc>
    80004be0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004be2:	8526                	mv	a0,s1
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	040080e7          	jalr	64(ra) # 80000c24 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bec:	2184a703          	lw	a4,536(s1)
    80004bf0:	21c4a783          	lw	a5,540(s1)
    80004bf4:	06f71b63          	bne	a4,a5,80004c6a <piperead+0xac>
    80004bf8:	8926                	mv	s2,s1
    80004bfa:	2244a783          	lw	a5,548(s1)
    80004bfe:	cf9d                	beqz	a5,80004c3c <piperead+0x7e>
    if(pr->killed){
    80004c00:	030a2783          	lw	a5,48(s4)
    80004c04:	e78d                	bnez	a5,80004c2e <piperead+0x70>
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c06:	21848b13          	addi	s6,s1,536
    80004c0a:	85ca                	mv	a1,s2
    80004c0c:	855a                	mv	a0,s6
    80004c0e:	ffffd097          	auipc	ra,0xffffd
    80004c12:	6b2080e7          	jalr	1714(ra) # 800022c0 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c16:	2184a703          	lw	a4,536(s1)
    80004c1a:	21c4a783          	lw	a5,540(s1)
    80004c1e:	04f71663          	bne	a4,a5,80004c6a <piperead+0xac>
    80004c22:	2244a783          	lw	a5,548(s1)
    80004c26:	cb99                	beqz	a5,80004c3c <piperead+0x7e>
    if(pr->killed){
    80004c28:	030a2783          	lw	a5,48(s4)
    80004c2c:	dff9                	beqz	a5,80004c0a <piperead+0x4c>
      release(&pi->lock);
    80004c2e:	8526                	mv	a0,s1
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	0a8080e7          	jalr	168(ra) # 80000cd8 <release>
      return -1;
    80004c38:	597d                	li	s2,-1
    80004c3a:	a829                	j	80004c54 <piperead+0x96>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    if(pi->nread == pi->nwrite)
    80004c3c:	4901                	li	s2,0
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c3e:	21c48513          	addi	a0,s1,540
    80004c42:	ffffe097          	auipc	ra,0xffffe
    80004c46:	804080e7          	jalr	-2044(ra) # 80002446 <wakeup>
  release(&pi->lock);
    80004c4a:	8526                	mv	a0,s1
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	08c080e7          	jalr	140(ra) # 80000cd8 <release>
  return i;
}
    80004c54:	854a                	mv	a0,s2
    80004c56:	60a6                	ld	ra,72(sp)
    80004c58:	6406                	ld	s0,64(sp)
    80004c5a:	74e2                	ld	s1,56(sp)
    80004c5c:	7942                	ld	s2,48(sp)
    80004c5e:	79a2                	ld	s3,40(sp)
    80004c60:	7a02                	ld	s4,32(sp)
    80004c62:	6ae2                	ld	s5,24(sp)
    80004c64:	6b42                	ld	s6,16(sp)
    80004c66:	6161                	addi	sp,sp,80
    80004c68:	8082                	ret
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c6a:	4901                	li	s2,0
    80004c6c:	fd5059e3          	blez	s5,80004c3e <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004c70:	2184a783          	lw	a5,536(s1)
    80004c74:	4901                	li	s2,0
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c76:	5b7d                	li	s6,-1
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c78:	0017871b          	addiw	a4,a5,1
    80004c7c:	20e4ac23          	sw	a4,536(s1)
    80004c80:	1ff7f793          	andi	a5,a5,511
    80004c84:	97a6                	add	a5,a5,s1
    80004c86:	0187c783          	lbu	a5,24(a5)
    80004c8a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c8e:	4685                	li	a3,1
    80004c90:	fbf40613          	addi	a2,s0,-65
    80004c94:	85ce                	mv	a1,s3
    80004c96:	050a3503          	ld	a0,80(s4)
    80004c9a:	ffffd097          	auipc	ra,0xffffd
    80004c9e:	a10080e7          	jalr	-1520(ra) # 800016aa <copyout>
    80004ca2:	f9650ee3          	beq	a0,s6,80004c3e <piperead+0x80>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ca6:	2905                	addiw	s2,s2,1
    80004ca8:	f92a8be3          	beq	s5,s2,80004c3e <piperead+0x80>
    if(pi->nread == pi->nwrite)
    80004cac:	2184a783          	lw	a5,536(s1)
    80004cb0:	0985                	addi	s3,s3,1
    80004cb2:	21c4a703          	lw	a4,540(s1)
    80004cb6:	fcf711e3          	bne	a4,a5,80004c78 <piperead+0xba>
    80004cba:	b751                	j	80004c3e <piperead+0x80>

0000000080004cbc <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cbc:	de010113          	addi	sp,sp,-544
    80004cc0:	20113c23          	sd	ra,536(sp)
    80004cc4:	20813823          	sd	s0,528(sp)
    80004cc8:	20913423          	sd	s1,520(sp)
    80004ccc:	21213023          	sd	s2,512(sp)
    80004cd0:	ffce                	sd	s3,504(sp)
    80004cd2:	fbd2                	sd	s4,496(sp)
    80004cd4:	f7d6                	sd	s5,488(sp)
    80004cd6:	f3da                	sd	s6,480(sp)
    80004cd8:	efde                	sd	s7,472(sp)
    80004cda:	ebe2                	sd	s8,464(sp)
    80004cdc:	e7e6                	sd	s9,456(sp)
    80004cde:	e3ea                	sd	s10,448(sp)
    80004ce0:	ff6e                	sd	s11,440(sp)
    80004ce2:	1400                	addi	s0,sp,544
    80004ce4:	892a                	mv	s2,a0
    80004ce6:	dea43823          	sd	a0,-528(s0)
    80004cea:	deb43c23          	sd	a1,-520(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	d50080e7          	jalr	-688(ra) # 80001a3e <myproc>
    80004cf6:	84aa                	mv	s1,a0

  begin_op();
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	44e080e7          	jalr	1102(ra) # 80004146 <begin_op>

  if((ip = namei(path)) == 0){
    80004d00:	854a                	mv	a0,s2
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	226080e7          	jalr	550(ra) # 80003f28 <namei>
    80004d0a:	c93d                	beqz	a0,80004d80 <exec+0xc4>
    80004d0c:	892a                	mv	s2,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d0e:	fffff097          	auipc	ra,0xfffff
    80004d12:	a5a080e7          	jalr	-1446(ra) # 80003768 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d16:	04000713          	li	a4,64
    80004d1a:	4681                	li	a3,0
    80004d1c:	e4840613          	addi	a2,s0,-440
    80004d20:	4581                	li	a1,0
    80004d22:	854a                	mv	a0,s2
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	cfa080e7          	jalr	-774(ra) # 80003a1e <readi>
    80004d2c:	04000793          	li	a5,64
    80004d30:	00f51a63          	bne	a0,a5,80004d44 <exec+0x88>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d34:	e4842703          	lw	a4,-440(s0)
    80004d38:	464c47b7          	lui	a5,0x464c4
    80004d3c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d40:	04f70663          	beq	a4,a5,80004d8c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d44:	854a                	mv	a0,s2
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	c86080e7          	jalr	-890(ra) # 800039cc <iunlockput>
    end_op();
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	478080e7          	jalr	1144(ra) # 800041c6 <end_op>
  }
  return -1;
    80004d56:	557d                	li	a0,-1
}
    80004d58:	21813083          	ld	ra,536(sp)
    80004d5c:	21013403          	ld	s0,528(sp)
    80004d60:	20813483          	ld	s1,520(sp)
    80004d64:	20013903          	ld	s2,512(sp)
    80004d68:	79fe                	ld	s3,504(sp)
    80004d6a:	7a5e                	ld	s4,496(sp)
    80004d6c:	7abe                	ld	s5,488(sp)
    80004d6e:	7b1e                	ld	s6,480(sp)
    80004d70:	6bfe                	ld	s7,472(sp)
    80004d72:	6c5e                	ld	s8,464(sp)
    80004d74:	6cbe                	ld	s9,456(sp)
    80004d76:	6d1e                	ld	s10,448(sp)
    80004d78:	7dfa                	ld	s11,440(sp)
    80004d7a:	22010113          	addi	sp,sp,544
    80004d7e:	8082                	ret
    end_op();
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	446080e7          	jalr	1094(ra) # 800041c6 <end_op>
    return -1;
    80004d88:	557d                	li	a0,-1
    80004d8a:	b7f9                	j	80004d58 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	d76080e7          	jalr	-650(ra) # 80001b04 <proc_pagetable>
    80004d96:	e0a43423          	sd	a0,-504(s0)
    80004d9a:	d54d                	beqz	a0,80004d44 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d9c:	e6842983          	lw	s3,-408(s0)
    80004da0:	e8045783          	lhu	a5,-384(s0)
    80004da4:	c7ad                	beqz	a5,80004e0e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004da6:	4481                	li	s1,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da8:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004daa:	6c05                	lui	s8,0x1
    80004dac:	fffc0793          	addi	a5,s8,-1 # fff <_entry-0x7ffff001>
    80004db0:	def43423          	sd	a5,-536(s0)
    80004db4:	7cfd                	lui	s9,0xfffff
    80004db6:	ac1d                	j	80004fec <exec+0x330>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004db8:	00004517          	auipc	a0,0x4
    80004dbc:	8c050513          	addi	a0,a0,-1856 # 80008678 <syscalls+0x2b8>
    80004dc0:	ffffb097          	auipc	ra,0xffffb
    80004dc4:	798080e7          	jalr	1944(ra) # 80000558 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dc8:	8756                	mv	a4,s5
    80004dca:	009d86bb          	addw	a3,s11,s1
    80004dce:	4581                	li	a1,0
    80004dd0:	854a                	mv	a0,s2
    80004dd2:	fffff097          	auipc	ra,0xfffff
    80004dd6:	c4c080e7          	jalr	-948(ra) # 80003a1e <readi>
    80004dda:	2501                	sext.w	a0,a0
    80004ddc:	1aaa9e63          	bne	s5,a0,80004f98 <exec+0x2dc>
  for(i = 0; i < sz; i += PGSIZE){
    80004de0:	6785                	lui	a5,0x1
    80004de2:	9cbd                	addw	s1,s1,a5
    80004de4:	014c8a3b          	addw	s4,s9,s4
    80004de8:	1f74f963          	bleu	s7,s1,80004fda <exec+0x31e>
    pa = walkaddr(pagetable, va + i);
    80004dec:	02049593          	slli	a1,s1,0x20
    80004df0:	9181                	srli	a1,a1,0x20
    80004df2:	95ea                	add	a1,a1,s10
    80004df4:	e0843503          	ld	a0,-504(s0)
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	2de080e7          	jalr	734(ra) # 800010d6 <walkaddr>
    80004e00:	862a                	mv	a2,a0
    if(pa == 0)
    80004e02:	d95d                	beqz	a0,80004db8 <exec+0xfc>
      n = PGSIZE;
    80004e04:	8ae2                	mv	s5,s8
    if(sz - i < PGSIZE)
    80004e06:	fd8a71e3          	bleu	s8,s4,80004dc8 <exec+0x10c>
      n = sz - i;
    80004e0a:	8ad2                	mv	s5,s4
    80004e0c:	bf75                	j	80004dc8 <exec+0x10c>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e0e:	4481                	li	s1,0
  iunlockput(ip);
    80004e10:	854a                	mv	a0,s2
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	bba080e7          	jalr	-1094(ra) # 800039cc <iunlockput>
  end_op();
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	3ac080e7          	jalr	940(ra) # 800041c6 <end_op>
  p = myproc();
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	c1c080e7          	jalr	-996(ra) # 80001a3e <myproc>
    80004e2a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e2c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e30:	6785                	lui	a5,0x1
    80004e32:	17fd                	addi	a5,a5,-1
    80004e34:	94be                	add	s1,s1,a5
    80004e36:	77fd                	lui	a5,0xfffff
    80004e38:	8fe5                	and	a5,a5,s1
    80004e3a:	e0f43023          	sd	a5,-512(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e3e:	6609                	lui	a2,0x2
    80004e40:	963e                	add	a2,a2,a5
    80004e42:	85be                	mv	a1,a5
    80004e44:	e0843483          	ld	s1,-504(s0)
    80004e48:	8526                	mv	a0,s1
    80004e4a:	ffffc097          	auipc	ra,0xffffc
    80004e4e:	61c080e7          	jalr	1564(ra) # 80001466 <uvmalloc>
    80004e52:	8b2a                	mv	s6,a0
  ip = 0;
    80004e54:	4901                	li	s2,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e56:	14050163          	beqz	a0,80004f98 <exec+0x2dc>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e5a:	75f9                	lui	a1,0xffffe
    80004e5c:	95aa                	add	a1,a1,a0
    80004e5e:	8526                	mv	a0,s1
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	818080e7          	jalr	-2024(ra) # 80001678 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e68:	7bfd                	lui	s7,0xfffff
    80004e6a:	9bda                	add	s7,s7,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e6c:	df843783          	ld	a5,-520(s0)
    80004e70:	6388                	ld	a0,0(a5)
    80004e72:	c925                	beqz	a0,80004ee2 <exec+0x226>
    80004e74:	e8840993          	addi	s3,s0,-376
    80004e78:	f8840c13          	addi	s8,s0,-120
  sp = sz;
    80004e7c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e7e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	04a080e7          	jalr	74(ra) # 80000eca <strlen>
    80004e88:	2505                	addiw	a0,a0,1
    80004e8a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e8e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e92:	13796863          	bltu	s2,s7,80004fc2 <exec+0x306>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e96:	df843c83          	ld	s9,-520(s0)
    80004e9a:	000cba03          	ld	s4,0(s9) # fffffffffffff000 <end+0xffffffff7ffcd000>
    80004e9e:	8552                	mv	a0,s4
    80004ea0:	ffffc097          	auipc	ra,0xffffc
    80004ea4:	02a080e7          	jalr	42(ra) # 80000eca <strlen>
    80004ea8:	0015069b          	addiw	a3,a0,1
    80004eac:	8652                	mv	a2,s4
    80004eae:	85ca                	mv	a1,s2
    80004eb0:	e0843503          	ld	a0,-504(s0)
    80004eb4:	ffffc097          	auipc	ra,0xffffc
    80004eb8:	7f6080e7          	jalr	2038(ra) # 800016aa <copyout>
    80004ebc:	10054763          	bltz	a0,80004fca <exec+0x30e>
    ustack[argc] = sp;
    80004ec0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ec4:	0485                	addi	s1,s1,1
    80004ec6:	008c8793          	addi	a5,s9,8
    80004eca:	def43c23          	sd	a5,-520(s0)
    80004ece:	008cb503          	ld	a0,8(s9)
    80004ed2:	c911                	beqz	a0,80004ee6 <exec+0x22a>
    if(argc >= MAXARG)
    80004ed4:	09a1                	addi	s3,s3,8
    80004ed6:	fb8995e3          	bne	s3,s8,80004e80 <exec+0x1c4>
  sz = sz1;
    80004eda:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004ede:	4901                	li	s2,0
    80004ee0:	a865                	j	80004f98 <exec+0x2dc>
  sp = sz;
    80004ee2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ee4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee6:	00349793          	slli	a5,s1,0x3
    80004eea:	f9040713          	addi	a4,s0,-112
    80004eee:	97ba                	add	a5,a5,a4
    80004ef0:	ee07bc23          	sd	zero,-264(a5) # ffffffffffffeef8 <end+0xffffffff7ffccef8>
  sp -= (argc+1) * sizeof(uint64);
    80004ef4:	00148693          	addi	a3,s1,1
    80004ef8:	068e                	slli	a3,a3,0x3
    80004efa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004efe:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f02:	01797663          	bleu	s7,s2,80004f0e <exec+0x252>
  sz = sz1;
    80004f06:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004f0a:	4901                	li	s2,0
    80004f0c:	a071                	j	80004f98 <exec+0x2dc>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f0e:	e8840613          	addi	a2,s0,-376
    80004f12:	85ca                	mv	a1,s2
    80004f14:	e0843503          	ld	a0,-504(s0)
    80004f18:	ffffc097          	auipc	ra,0xffffc
    80004f1c:	792080e7          	jalr	1938(ra) # 800016aa <copyout>
    80004f20:	0a054963          	bltz	a0,80004fd2 <exec+0x316>
  p->trapframe->a1 = sp;
    80004f24:	058ab783          	ld	a5,88(s5)
    80004f28:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f2c:	df043783          	ld	a5,-528(s0)
    80004f30:	0007c703          	lbu	a4,0(a5)
    80004f34:	cf11                	beqz	a4,80004f50 <exec+0x294>
    80004f36:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f38:	02f00693          	li	a3,47
    80004f3c:	a029                	j	80004f46 <exec+0x28a>
  for(last=s=path; *s; s++)
    80004f3e:	0785                	addi	a5,a5,1
    80004f40:	fff7c703          	lbu	a4,-1(a5)
    80004f44:	c711                	beqz	a4,80004f50 <exec+0x294>
    if(*s == '/')
    80004f46:	fed71ce3          	bne	a4,a3,80004f3e <exec+0x282>
      last = s+1;
    80004f4a:	def43823          	sd	a5,-528(s0)
    80004f4e:	bfc5                	j	80004f3e <exec+0x282>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f50:	4641                	li	a2,16
    80004f52:	df043583          	ld	a1,-528(s0)
    80004f56:	158a8513          	addi	a0,s5,344
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	f3e080e7          	jalr	-194(ra) # 80000e98 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f62:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f66:	e0843783          	ld	a5,-504(s0)
    80004f6a:	04fab823          	sd	a5,80(s5)
  p->sz = sz;
    80004f6e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f72:	058ab783          	ld	a5,88(s5)
    80004f76:	e6043703          	ld	a4,-416(s0)
    80004f7a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f7c:	058ab783          	ld	a5,88(s5)
    80004f80:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f84:	85ea                	mv	a1,s10
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	c1a080e7          	jalr	-998(ra) # 80001ba0 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f8e:	0004851b          	sext.w	a0,s1
    80004f92:	b3d9                	j	80004d58 <exec+0x9c>
    80004f94:	e0943023          	sd	s1,-512(s0)
    proc_freepagetable(pagetable, sz);
    80004f98:	e0043583          	ld	a1,-512(s0)
    80004f9c:	e0843503          	ld	a0,-504(s0)
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	c00080e7          	jalr	-1024(ra) # 80001ba0 <proc_freepagetable>
  if(ip){
    80004fa8:	d8091ee3          	bnez	s2,80004d44 <exec+0x88>
  return -1;
    80004fac:	557d                	li	a0,-1
    80004fae:	b36d                	j	80004d58 <exec+0x9c>
    80004fb0:	e0943023          	sd	s1,-512(s0)
    80004fb4:	b7d5                	j	80004f98 <exec+0x2dc>
    80004fb6:	e0943023          	sd	s1,-512(s0)
    80004fba:	bff9                	j	80004f98 <exec+0x2dc>
    80004fbc:	e0943023          	sd	s1,-512(s0)
    80004fc0:	bfe1                	j	80004f98 <exec+0x2dc>
  sz = sz1;
    80004fc2:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004fc6:	4901                	li	s2,0
    80004fc8:	bfc1                	j	80004f98 <exec+0x2dc>
  sz = sz1;
    80004fca:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004fce:	4901                	li	s2,0
    80004fd0:	b7e1                	j	80004f98 <exec+0x2dc>
  sz = sz1;
    80004fd2:	e1643023          	sd	s6,-512(s0)
  ip = 0;
    80004fd6:	4901                	li	s2,0
    80004fd8:	b7c1                	j	80004f98 <exec+0x2dc>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fda:	e0043483          	ld	s1,-512(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fde:	2b05                	addiw	s6,s6,1
    80004fe0:	0389899b          	addiw	s3,s3,56
    80004fe4:	e8045783          	lhu	a5,-384(s0)
    80004fe8:	e2fb54e3          	ble	a5,s6,80004e10 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fec:	2981                	sext.w	s3,s3
    80004fee:	03800713          	li	a4,56
    80004ff2:	86ce                	mv	a3,s3
    80004ff4:	e1040613          	addi	a2,s0,-496
    80004ff8:	4581                	li	a1,0
    80004ffa:	854a                	mv	a0,s2
    80004ffc:	fffff097          	auipc	ra,0xfffff
    80005000:	a22080e7          	jalr	-1502(ra) # 80003a1e <readi>
    80005004:	03800793          	li	a5,56
    80005008:	f8f516e3          	bne	a0,a5,80004f94 <exec+0x2d8>
    if(ph.type != ELF_PROG_LOAD)
    8000500c:	e1042783          	lw	a5,-496(s0)
    80005010:	4705                	li	a4,1
    80005012:	fce796e3          	bne	a5,a4,80004fde <exec+0x322>
    if(ph.memsz < ph.filesz)
    80005016:	e3843603          	ld	a2,-456(s0)
    8000501a:	e3043783          	ld	a5,-464(s0)
    8000501e:	f8f669e3          	bltu	a2,a5,80004fb0 <exec+0x2f4>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005022:	e2043783          	ld	a5,-480(s0)
    80005026:	963e                	add	a2,a2,a5
    80005028:	f8f667e3          	bltu	a2,a5,80004fb6 <exec+0x2fa>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000502c:	85a6                	mv	a1,s1
    8000502e:	e0843503          	ld	a0,-504(s0)
    80005032:	ffffc097          	auipc	ra,0xffffc
    80005036:	434080e7          	jalr	1076(ra) # 80001466 <uvmalloc>
    8000503a:	e0a43023          	sd	a0,-512(s0)
    8000503e:	dd3d                	beqz	a0,80004fbc <exec+0x300>
    if(ph.vaddr % PGSIZE != 0)
    80005040:	e2043d03          	ld	s10,-480(s0)
    80005044:	de843783          	ld	a5,-536(s0)
    80005048:	00fd77b3          	and	a5,s10,a5
    8000504c:	f7b1                	bnez	a5,80004f98 <exec+0x2dc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000504e:	e1842d83          	lw	s11,-488(s0)
    80005052:	e3042b83          	lw	s7,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005056:	f80b82e3          	beqz	s7,80004fda <exec+0x31e>
    8000505a:	8a5e                	mv	s4,s7
    8000505c:	4481                	li	s1,0
    8000505e:	b379                	j	80004dec <exec+0x130>

0000000080005060 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005060:	7179                	addi	sp,sp,-48
    80005062:	f406                	sd	ra,40(sp)
    80005064:	f022                	sd	s0,32(sp)
    80005066:	ec26                	sd	s1,24(sp)
    80005068:	e84a                	sd	s2,16(sp)
    8000506a:	1800                	addi	s0,sp,48
    8000506c:	892e                	mv	s2,a1
    8000506e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005070:	fdc40593          	addi	a1,s0,-36
    80005074:	ffffe097          	auipc	ra,0xffffe
    80005078:	b34080e7          	jalr	-1228(ra) # 80002ba8 <argint>
    8000507c:	04054063          	bltz	a0,800050bc <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005080:	fdc42703          	lw	a4,-36(s0)
    80005084:	47bd                	li	a5,15
    80005086:	02e7ed63          	bltu	a5,a4,800050c0 <argfd+0x60>
    8000508a:	ffffd097          	auipc	ra,0xffffd
    8000508e:	9b4080e7          	jalr	-1612(ra) # 80001a3e <myproc>
    80005092:	fdc42703          	lw	a4,-36(s0)
    80005096:	01a70793          	addi	a5,a4,26
    8000509a:	078e                	slli	a5,a5,0x3
    8000509c:	953e                	add	a0,a0,a5
    8000509e:	611c                	ld	a5,0(a0)
    800050a0:	c395                	beqz	a5,800050c4 <argfd+0x64>
    return -1;
  if(pfd)
    800050a2:	00090463          	beqz	s2,800050aa <argfd+0x4a>
    *pfd = fd;
    800050a6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050aa:	4501                	li	a0,0
  if(pf)
    800050ac:	c091                	beqz	s1,800050b0 <argfd+0x50>
    *pf = f;
    800050ae:	e09c                	sd	a5,0(s1)
}
    800050b0:	70a2                	ld	ra,40(sp)
    800050b2:	7402                	ld	s0,32(sp)
    800050b4:	64e2                	ld	s1,24(sp)
    800050b6:	6942                	ld	s2,16(sp)
    800050b8:	6145                	addi	sp,sp,48
    800050ba:	8082                	ret
    return -1;
    800050bc:	557d                	li	a0,-1
    800050be:	bfcd                	j	800050b0 <argfd+0x50>
    return -1;
    800050c0:	557d                	li	a0,-1
    800050c2:	b7fd                	j	800050b0 <argfd+0x50>
    800050c4:	557d                	li	a0,-1
    800050c6:	b7ed                	j	800050b0 <argfd+0x50>

00000000800050c8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050c8:	1101                	addi	sp,sp,-32
    800050ca:	ec06                	sd	ra,24(sp)
    800050cc:	e822                	sd	s0,16(sp)
    800050ce:	e426                	sd	s1,8(sp)
    800050d0:	1000                	addi	s0,sp,32
    800050d2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050d4:	ffffd097          	auipc	ra,0xffffd
    800050d8:	96a080e7          	jalr	-1686(ra) # 80001a3e <myproc>

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){
    800050dc:	697c                	ld	a5,208(a0)
    800050de:	c395                	beqz	a5,80005102 <fdalloc+0x3a>
    800050e0:	0d850713          	addi	a4,a0,216
  for(fd = 0; fd < NOFILE; fd++){
    800050e4:	4785                	li	a5,1
    800050e6:	4641                	li	a2,16
    if(p->ofile[fd] == 0){
    800050e8:	6314                	ld	a3,0(a4)
    800050ea:	ce89                	beqz	a3,80005104 <fdalloc+0x3c>
  for(fd = 0; fd < NOFILE; fd++){
    800050ec:	2785                	addiw	a5,a5,1
    800050ee:	0721                	addi	a4,a4,8
    800050f0:	fec79ce3          	bne	a5,a2,800050e8 <fdalloc+0x20>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050f4:	57fd                	li	a5,-1
}
    800050f6:	853e                	mv	a0,a5
    800050f8:	60e2                	ld	ra,24(sp)
    800050fa:	6442                	ld	s0,16(sp)
    800050fc:	64a2                	ld	s1,8(sp)
    800050fe:	6105                	addi	sp,sp,32
    80005100:	8082                	ret
  for(fd = 0; fd < NOFILE; fd++){
    80005102:	4781                	li	a5,0
      p->ofile[fd] = f;
    80005104:	01a78713          	addi	a4,a5,26
    80005108:	070e                	slli	a4,a4,0x3
    8000510a:	953a                	add	a0,a0,a4
    8000510c:	e104                	sd	s1,0(a0)
      return fd;
    8000510e:	b7e5                	j	800050f6 <fdalloc+0x2e>

0000000080005110 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005110:	715d                	addi	sp,sp,-80
    80005112:	e486                	sd	ra,72(sp)
    80005114:	e0a2                	sd	s0,64(sp)
    80005116:	fc26                	sd	s1,56(sp)
    80005118:	f84a                	sd	s2,48(sp)
    8000511a:	f44e                	sd	s3,40(sp)
    8000511c:	f052                	sd	s4,32(sp)
    8000511e:	ec56                	sd	s5,24(sp)
    80005120:	0880                	addi	s0,sp,80
    80005122:	89ae                	mv	s3,a1
    80005124:	8ab2                	mv	s5,a2
    80005126:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005128:	fb040593          	addi	a1,s0,-80
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	e1a080e7          	jalr	-486(ra) # 80003f46 <nameiparent>
    80005134:	892a                	mv	s2,a0
    80005136:	12050f63          	beqz	a0,80005274 <create+0x164>
    return 0;

  ilock(dp);
    8000513a:	ffffe097          	auipc	ra,0xffffe
    8000513e:	62e080e7          	jalr	1582(ra) # 80003768 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005142:	4601                	li	a2,0
    80005144:	fb040593          	addi	a1,s0,-80
    80005148:	854a                	mv	a0,s2
    8000514a:	fffff097          	auipc	ra,0xfffff
    8000514e:	b04080e7          	jalr	-1276(ra) # 80003c4e <dirlookup>
    80005152:	84aa                	mv	s1,a0
    80005154:	c921                	beqz	a0,800051a4 <create+0x94>
    iunlockput(dp);
    80005156:	854a                	mv	a0,s2
    80005158:	fffff097          	auipc	ra,0xfffff
    8000515c:	874080e7          	jalr	-1932(ra) # 800039cc <iunlockput>
    ilock(ip);
    80005160:	8526                	mv	a0,s1
    80005162:	ffffe097          	auipc	ra,0xffffe
    80005166:	606080e7          	jalr	1542(ra) # 80003768 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000516a:	2981                	sext.w	s3,s3
    8000516c:	4789                	li	a5,2
    8000516e:	02f99463          	bne	s3,a5,80005196 <create+0x86>
    80005172:	0444d783          	lhu	a5,68(s1)
    80005176:	37f9                	addiw	a5,a5,-2
    80005178:	17c2                	slli	a5,a5,0x30
    8000517a:	93c1                	srli	a5,a5,0x30
    8000517c:	4705                	li	a4,1
    8000517e:	00f76c63          	bltu	a4,a5,80005196 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005182:	8526                	mv	a0,s1
    80005184:	60a6                	ld	ra,72(sp)
    80005186:	6406                	ld	s0,64(sp)
    80005188:	74e2                	ld	s1,56(sp)
    8000518a:	7942                	ld	s2,48(sp)
    8000518c:	79a2                	ld	s3,40(sp)
    8000518e:	7a02                	ld	s4,32(sp)
    80005190:	6ae2                	ld	s5,24(sp)
    80005192:	6161                	addi	sp,sp,80
    80005194:	8082                	ret
    iunlockput(ip);
    80005196:	8526                	mv	a0,s1
    80005198:	fffff097          	auipc	ra,0xfffff
    8000519c:	834080e7          	jalr	-1996(ra) # 800039cc <iunlockput>
    return 0;
    800051a0:	4481                	li	s1,0
    800051a2:	b7c5                	j	80005182 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051a4:	85ce                	mv	a1,s3
    800051a6:	00092503          	lw	a0,0(s2)
    800051aa:	ffffe097          	auipc	ra,0xffffe
    800051ae:	422080e7          	jalr	1058(ra) # 800035cc <ialloc>
    800051b2:	84aa                	mv	s1,a0
    800051b4:	c529                	beqz	a0,800051fe <create+0xee>
  ilock(ip);
    800051b6:	ffffe097          	auipc	ra,0xffffe
    800051ba:	5b2080e7          	jalr	1458(ra) # 80003768 <ilock>
  ip->major = major;
    800051be:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051c2:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051c6:	4785                	li	a5,1
    800051c8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051cc:	8526                	mv	a0,s1
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	4ce080e7          	jalr	1230(ra) # 8000369c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051d6:	2981                	sext.w	s3,s3
    800051d8:	4785                	li	a5,1
    800051da:	02f98a63          	beq	s3,a5,8000520e <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051de:	40d0                	lw	a2,4(s1)
    800051e0:	fb040593          	addi	a1,s0,-80
    800051e4:	854a                	mv	a0,s2
    800051e6:	fffff097          	auipc	ra,0xfffff
    800051ea:	c80080e7          	jalr	-896(ra) # 80003e66 <dirlink>
    800051ee:	06054b63          	bltz	a0,80005264 <create+0x154>
  iunlockput(dp);
    800051f2:	854a                	mv	a0,s2
    800051f4:	ffffe097          	auipc	ra,0xffffe
    800051f8:	7d8080e7          	jalr	2008(ra) # 800039cc <iunlockput>
  return ip;
    800051fc:	b759                	j	80005182 <create+0x72>
    panic("create: ialloc");
    800051fe:	00003517          	auipc	a0,0x3
    80005202:	49a50513          	addi	a0,a0,1178 # 80008698 <syscalls+0x2d8>
    80005206:	ffffb097          	auipc	ra,0xffffb
    8000520a:	352080e7          	jalr	850(ra) # 80000558 <panic>
    dp->nlink++;  // for ".."
    8000520e:	04a95783          	lhu	a5,74(s2)
    80005212:	2785                	addiw	a5,a5,1
    80005214:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005218:	854a                	mv	a0,s2
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	482080e7          	jalr	1154(ra) # 8000369c <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005222:	40d0                	lw	a2,4(s1)
    80005224:	00003597          	auipc	a1,0x3
    80005228:	48458593          	addi	a1,a1,1156 # 800086a8 <syscalls+0x2e8>
    8000522c:	8526                	mv	a0,s1
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	c38080e7          	jalr	-968(ra) # 80003e66 <dirlink>
    80005236:	00054f63          	bltz	a0,80005254 <create+0x144>
    8000523a:	00492603          	lw	a2,4(s2)
    8000523e:	00003597          	auipc	a1,0x3
    80005242:	47258593          	addi	a1,a1,1138 # 800086b0 <syscalls+0x2f0>
    80005246:	8526                	mv	a0,s1
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	c1e080e7          	jalr	-994(ra) # 80003e66 <dirlink>
    80005250:	f80557e3          	bgez	a0,800051de <create+0xce>
      panic("create dots");
    80005254:	00003517          	auipc	a0,0x3
    80005258:	46450513          	addi	a0,a0,1124 # 800086b8 <syscalls+0x2f8>
    8000525c:	ffffb097          	auipc	ra,0xffffb
    80005260:	2fc080e7          	jalr	764(ra) # 80000558 <panic>
    panic("create: dirlink");
    80005264:	00003517          	auipc	a0,0x3
    80005268:	46450513          	addi	a0,a0,1124 # 800086c8 <syscalls+0x308>
    8000526c:	ffffb097          	auipc	ra,0xffffb
    80005270:	2ec080e7          	jalr	748(ra) # 80000558 <panic>
    return 0;
    80005274:	84aa                	mv	s1,a0
    80005276:	b731                	j	80005182 <create+0x72>

0000000080005278 <sys_dup>:
{
    80005278:	7179                	addi	sp,sp,-48
    8000527a:	f406                	sd	ra,40(sp)
    8000527c:	f022                	sd	s0,32(sp)
    8000527e:	ec26                	sd	s1,24(sp)
    80005280:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005282:	fd840613          	addi	a2,s0,-40
    80005286:	4581                	li	a1,0
    80005288:	4501                	li	a0,0
    8000528a:	00000097          	auipc	ra,0x0
    8000528e:	dd6080e7          	jalr	-554(ra) # 80005060 <argfd>
    return -1;
    80005292:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005294:	02054363          	bltz	a0,800052ba <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005298:	fd843503          	ld	a0,-40(s0)
    8000529c:	00000097          	auipc	ra,0x0
    800052a0:	e2c080e7          	jalr	-468(ra) # 800050c8 <fdalloc>
    800052a4:	84aa                	mv	s1,a0
    return -1;
    800052a6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052a8:	00054963          	bltz	a0,800052ba <sys_dup+0x42>
  filedup(f);
    800052ac:	fd843503          	ld	a0,-40(s0)
    800052b0:	fffff097          	auipc	ra,0xfffff
    800052b4:	348080e7          	jalr	840(ra) # 800045f8 <filedup>
  return fd;
    800052b8:	87a6                	mv	a5,s1
}
    800052ba:	853e                	mv	a0,a5
    800052bc:	70a2                	ld	ra,40(sp)
    800052be:	7402                	ld	s0,32(sp)
    800052c0:	64e2                	ld	s1,24(sp)
    800052c2:	6145                	addi	sp,sp,48
    800052c4:	8082                	ret

00000000800052c6 <sys_read>:
{
    800052c6:	7179                	addi	sp,sp,-48
    800052c8:	f406                	sd	ra,40(sp)
    800052ca:	f022                	sd	s0,32(sp)
    800052cc:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ce:	fe840613          	addi	a2,s0,-24
    800052d2:	4581                	li	a1,0
    800052d4:	4501                	li	a0,0
    800052d6:	00000097          	auipc	ra,0x0
    800052da:	d8a080e7          	jalr	-630(ra) # 80005060 <argfd>
    return -1;
    800052de:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e0:	04054163          	bltz	a0,80005322 <sys_read+0x5c>
    800052e4:	fe440593          	addi	a1,s0,-28
    800052e8:	4509                	li	a0,2
    800052ea:	ffffe097          	auipc	ra,0xffffe
    800052ee:	8be080e7          	jalr	-1858(ra) # 80002ba8 <argint>
    return -1;
    800052f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f4:	02054763          	bltz	a0,80005322 <sys_read+0x5c>
    800052f8:	fd840593          	addi	a1,s0,-40
    800052fc:	4505                	li	a0,1
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	8cc080e7          	jalr	-1844(ra) # 80002bca <argaddr>
    return -1;
    80005306:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005308:	00054d63          	bltz	a0,80005322 <sys_read+0x5c>
  return fileread(f, p, n);
    8000530c:	fe442603          	lw	a2,-28(s0)
    80005310:	fd843583          	ld	a1,-40(s0)
    80005314:	fe843503          	ld	a0,-24(s0)
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	46c080e7          	jalr	1132(ra) # 80004784 <fileread>
    80005320:	87aa                	mv	a5,a0
}
    80005322:	853e                	mv	a0,a5
    80005324:	70a2                	ld	ra,40(sp)
    80005326:	7402                	ld	s0,32(sp)
    80005328:	6145                	addi	sp,sp,48
    8000532a:	8082                	ret

000000008000532c <sys_write>:
{
    8000532c:	7179                	addi	sp,sp,-48
    8000532e:	f406                	sd	ra,40(sp)
    80005330:	f022                	sd	s0,32(sp)
    80005332:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005334:	fe840613          	addi	a2,s0,-24
    80005338:	4581                	li	a1,0
    8000533a:	4501                	li	a0,0
    8000533c:	00000097          	auipc	ra,0x0
    80005340:	d24080e7          	jalr	-732(ra) # 80005060 <argfd>
    return -1;
    80005344:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005346:	04054163          	bltz	a0,80005388 <sys_write+0x5c>
    8000534a:	fe440593          	addi	a1,s0,-28
    8000534e:	4509                	li	a0,2
    80005350:	ffffe097          	auipc	ra,0xffffe
    80005354:	858080e7          	jalr	-1960(ra) # 80002ba8 <argint>
    return -1;
    80005358:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000535a:	02054763          	bltz	a0,80005388 <sys_write+0x5c>
    8000535e:	fd840593          	addi	a1,s0,-40
    80005362:	4505                	li	a0,1
    80005364:	ffffe097          	auipc	ra,0xffffe
    80005368:	866080e7          	jalr	-1946(ra) # 80002bca <argaddr>
    return -1;
    8000536c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536e:	00054d63          	bltz	a0,80005388 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005372:	fe442603          	lw	a2,-28(s0)
    80005376:	fd843583          	ld	a1,-40(s0)
    8000537a:	fe843503          	ld	a0,-24(s0)
    8000537e:	fffff097          	auipc	ra,0xfffff
    80005382:	4c8080e7          	jalr	1224(ra) # 80004846 <filewrite>
    80005386:	87aa                	mv	a5,a0
}
    80005388:	853e                	mv	a0,a5
    8000538a:	70a2                	ld	ra,40(sp)
    8000538c:	7402                	ld	s0,32(sp)
    8000538e:	6145                	addi	sp,sp,48
    80005390:	8082                	ret

0000000080005392 <sys_close>:
{
    80005392:	1101                	addi	sp,sp,-32
    80005394:	ec06                	sd	ra,24(sp)
    80005396:	e822                	sd	s0,16(sp)
    80005398:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000539a:	fe040613          	addi	a2,s0,-32
    8000539e:	fec40593          	addi	a1,s0,-20
    800053a2:	4501                	li	a0,0
    800053a4:	00000097          	auipc	ra,0x0
    800053a8:	cbc080e7          	jalr	-836(ra) # 80005060 <argfd>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053ae:	02054463          	bltz	a0,800053d6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053b2:	ffffc097          	auipc	ra,0xffffc
    800053b6:	68c080e7          	jalr	1676(ra) # 80001a3e <myproc>
    800053ba:	fec42783          	lw	a5,-20(s0)
    800053be:	07e9                	addi	a5,a5,26
    800053c0:	078e                	slli	a5,a5,0x3
    800053c2:	953e                	add	a0,a0,a5
    800053c4:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053c8:	fe043503          	ld	a0,-32(s0)
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	27e080e7          	jalr	638(ra) # 8000464a <fileclose>
  return 0;
    800053d4:	4781                	li	a5,0
}
    800053d6:	853e                	mv	a0,a5
    800053d8:	60e2                	ld	ra,24(sp)
    800053da:	6442                	ld	s0,16(sp)
    800053dc:	6105                	addi	sp,sp,32
    800053de:	8082                	ret

00000000800053e0 <sys_fstat>:
{
    800053e0:	1101                	addi	sp,sp,-32
    800053e2:	ec06                	sd	ra,24(sp)
    800053e4:	e822                	sd	s0,16(sp)
    800053e6:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053e8:	fe840613          	addi	a2,s0,-24
    800053ec:	4581                	li	a1,0
    800053ee:	4501                	li	a0,0
    800053f0:	00000097          	auipc	ra,0x0
    800053f4:	c70080e7          	jalr	-912(ra) # 80005060 <argfd>
    return -1;
    800053f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053fa:	02054563          	bltz	a0,80005424 <sys_fstat+0x44>
    800053fe:	fe040593          	addi	a1,s0,-32
    80005402:	4505                	li	a0,1
    80005404:	ffffd097          	auipc	ra,0xffffd
    80005408:	7c6080e7          	jalr	1990(ra) # 80002bca <argaddr>
    return -1;
    8000540c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000540e:	00054b63          	bltz	a0,80005424 <sys_fstat+0x44>
  return filestat(f, st);
    80005412:	fe043583          	ld	a1,-32(s0)
    80005416:	fe843503          	ld	a0,-24(s0)
    8000541a:	fffff097          	auipc	ra,0xfffff
    8000541e:	2f8080e7          	jalr	760(ra) # 80004712 <filestat>
    80005422:	87aa                	mv	a5,a0
}
    80005424:	853e                	mv	a0,a5
    80005426:	60e2                	ld	ra,24(sp)
    80005428:	6442                	ld	s0,16(sp)
    8000542a:	6105                	addi	sp,sp,32
    8000542c:	8082                	ret

000000008000542e <sys_link>:
{
    8000542e:	7169                	addi	sp,sp,-304
    80005430:	f606                	sd	ra,296(sp)
    80005432:	f222                	sd	s0,288(sp)
    80005434:	ee26                	sd	s1,280(sp)
    80005436:	ea4a                	sd	s2,272(sp)
    80005438:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000543a:	08000613          	li	a2,128
    8000543e:	ed040593          	addi	a1,s0,-304
    80005442:	4501                	li	a0,0
    80005444:	ffffd097          	auipc	ra,0xffffd
    80005448:	7a8080e7          	jalr	1960(ra) # 80002bec <argstr>
    return -1;
    8000544c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000544e:	10054e63          	bltz	a0,8000556a <sys_link+0x13c>
    80005452:	08000613          	li	a2,128
    80005456:	f5040593          	addi	a1,s0,-176
    8000545a:	4505                	li	a0,1
    8000545c:	ffffd097          	auipc	ra,0xffffd
    80005460:	790080e7          	jalr	1936(ra) # 80002bec <argstr>
    return -1;
    80005464:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005466:	10054263          	bltz	a0,8000556a <sys_link+0x13c>
  begin_op();
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	cdc080e7          	jalr	-804(ra) # 80004146 <begin_op>
  if((ip = namei(old)) == 0){
    80005472:	ed040513          	addi	a0,s0,-304
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	ab2080e7          	jalr	-1358(ra) # 80003f28 <namei>
    8000547e:	84aa                	mv	s1,a0
    80005480:	c551                	beqz	a0,8000550c <sys_link+0xde>
  ilock(ip);
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	2e6080e7          	jalr	742(ra) # 80003768 <ilock>
  if(ip->type == T_DIR){
    8000548a:	04449703          	lh	a4,68(s1)
    8000548e:	4785                	li	a5,1
    80005490:	08f70463          	beq	a4,a5,80005518 <sys_link+0xea>
  ip->nlink++;
    80005494:	04a4d783          	lhu	a5,74(s1)
    80005498:	2785                	addiw	a5,a5,1
    8000549a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000549e:	8526                	mv	a0,s1
    800054a0:	ffffe097          	auipc	ra,0xffffe
    800054a4:	1fc080e7          	jalr	508(ra) # 8000369c <iupdate>
  iunlock(ip);
    800054a8:	8526                	mv	a0,s1
    800054aa:	ffffe097          	auipc	ra,0xffffe
    800054ae:	382080e7          	jalr	898(ra) # 8000382c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054b2:	fd040593          	addi	a1,s0,-48
    800054b6:	f5040513          	addi	a0,s0,-176
    800054ba:	fffff097          	auipc	ra,0xfffff
    800054be:	a8c080e7          	jalr	-1396(ra) # 80003f46 <nameiparent>
    800054c2:	892a                	mv	s2,a0
    800054c4:	c935                	beqz	a0,80005538 <sys_link+0x10a>
  ilock(dp);
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	2a2080e7          	jalr	674(ra) # 80003768 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054ce:	00092703          	lw	a4,0(s2)
    800054d2:	409c                	lw	a5,0(s1)
    800054d4:	04f71d63          	bne	a4,a5,8000552e <sys_link+0x100>
    800054d8:	40d0                	lw	a2,4(s1)
    800054da:	fd040593          	addi	a1,s0,-48
    800054de:	854a                	mv	a0,s2
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	986080e7          	jalr	-1658(ra) # 80003e66 <dirlink>
    800054e8:	04054363          	bltz	a0,8000552e <sys_link+0x100>
  iunlockput(dp);
    800054ec:	854a                	mv	a0,s2
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	4de080e7          	jalr	1246(ra) # 800039cc <iunlockput>
  iput(ip);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	42c080e7          	jalr	1068(ra) # 80003924 <iput>
  end_op();
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	cc6080e7          	jalr	-826(ra) # 800041c6 <end_op>
  return 0;
    80005508:	4781                	li	a5,0
    8000550a:	a085                	j	8000556a <sys_link+0x13c>
    end_op();
    8000550c:	fffff097          	auipc	ra,0xfffff
    80005510:	cba080e7          	jalr	-838(ra) # 800041c6 <end_op>
    return -1;
    80005514:	57fd                	li	a5,-1
    80005516:	a891                	j	8000556a <sys_link+0x13c>
    iunlockput(ip);
    80005518:	8526                	mv	a0,s1
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	4b2080e7          	jalr	1202(ra) # 800039cc <iunlockput>
    end_op();
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	ca4080e7          	jalr	-860(ra) # 800041c6 <end_op>
    return -1;
    8000552a:	57fd                	li	a5,-1
    8000552c:	a83d                	j	8000556a <sys_link+0x13c>
    iunlockput(dp);
    8000552e:	854a                	mv	a0,s2
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	49c080e7          	jalr	1180(ra) # 800039cc <iunlockput>
  ilock(ip);
    80005538:	8526                	mv	a0,s1
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	22e080e7          	jalr	558(ra) # 80003768 <ilock>
  ip->nlink--;
    80005542:	04a4d783          	lhu	a5,74(s1)
    80005546:	37fd                	addiw	a5,a5,-1
    80005548:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000554c:	8526                	mv	a0,s1
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	14e080e7          	jalr	334(ra) # 8000369c <iupdate>
  iunlockput(ip);
    80005556:	8526                	mv	a0,s1
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	474080e7          	jalr	1140(ra) # 800039cc <iunlockput>
  end_op();
    80005560:	fffff097          	auipc	ra,0xfffff
    80005564:	c66080e7          	jalr	-922(ra) # 800041c6 <end_op>
  return -1;
    80005568:	57fd                	li	a5,-1
}
    8000556a:	853e                	mv	a0,a5
    8000556c:	70b2                	ld	ra,296(sp)
    8000556e:	7412                	ld	s0,288(sp)
    80005570:	64f2                	ld	s1,280(sp)
    80005572:	6952                	ld	s2,272(sp)
    80005574:	6155                	addi	sp,sp,304
    80005576:	8082                	ret

0000000080005578 <sys_unlink>:
{
    80005578:	7151                	addi	sp,sp,-240
    8000557a:	f586                	sd	ra,232(sp)
    8000557c:	f1a2                	sd	s0,224(sp)
    8000557e:	eda6                	sd	s1,216(sp)
    80005580:	e9ca                	sd	s2,208(sp)
    80005582:	e5ce                	sd	s3,200(sp)
    80005584:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005586:	08000613          	li	a2,128
    8000558a:	f3040593          	addi	a1,s0,-208
    8000558e:	4501                	li	a0,0
    80005590:	ffffd097          	auipc	ra,0xffffd
    80005594:	65c080e7          	jalr	1628(ra) # 80002bec <argstr>
    80005598:	16054f63          	bltz	a0,80005716 <sys_unlink+0x19e>
  begin_op();
    8000559c:	fffff097          	auipc	ra,0xfffff
    800055a0:	baa080e7          	jalr	-1110(ra) # 80004146 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055a4:	fb040593          	addi	a1,s0,-80
    800055a8:	f3040513          	addi	a0,s0,-208
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	99a080e7          	jalr	-1638(ra) # 80003f46 <nameiparent>
    800055b4:	89aa                	mv	s3,a0
    800055b6:	c979                	beqz	a0,8000568c <sys_unlink+0x114>
  ilock(dp);
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	1b0080e7          	jalr	432(ra) # 80003768 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055c0:	00003597          	auipc	a1,0x3
    800055c4:	0e858593          	addi	a1,a1,232 # 800086a8 <syscalls+0x2e8>
    800055c8:	fb040513          	addi	a0,s0,-80
    800055cc:	ffffe097          	auipc	ra,0xffffe
    800055d0:	668080e7          	jalr	1640(ra) # 80003c34 <namecmp>
    800055d4:	14050863          	beqz	a0,80005724 <sys_unlink+0x1ac>
    800055d8:	00003597          	auipc	a1,0x3
    800055dc:	0d858593          	addi	a1,a1,216 # 800086b0 <syscalls+0x2f0>
    800055e0:	fb040513          	addi	a0,s0,-80
    800055e4:	ffffe097          	auipc	ra,0xffffe
    800055e8:	650080e7          	jalr	1616(ra) # 80003c34 <namecmp>
    800055ec:	12050c63          	beqz	a0,80005724 <sys_unlink+0x1ac>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055f0:	f2c40613          	addi	a2,s0,-212
    800055f4:	fb040593          	addi	a1,s0,-80
    800055f8:	854e                	mv	a0,s3
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	654080e7          	jalr	1620(ra) # 80003c4e <dirlookup>
    80005602:	84aa                	mv	s1,a0
    80005604:	12050063          	beqz	a0,80005724 <sys_unlink+0x1ac>
  ilock(ip);
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	160080e7          	jalr	352(ra) # 80003768 <ilock>
  if(ip->nlink < 1)
    80005610:	04a49783          	lh	a5,74(s1)
    80005614:	08f05263          	blez	a5,80005698 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005618:	04449703          	lh	a4,68(s1)
    8000561c:	4785                	li	a5,1
    8000561e:	08f70563          	beq	a4,a5,800056a8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005622:	4641                	li	a2,16
    80005624:	4581                	li	a1,0
    80005626:	fc040513          	addi	a0,s0,-64
    8000562a:	ffffb097          	auipc	ra,0xffffb
    8000562e:	6f6080e7          	jalr	1782(ra) # 80000d20 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005632:	4741                	li	a4,16
    80005634:	f2c42683          	lw	a3,-212(s0)
    80005638:	fc040613          	addi	a2,s0,-64
    8000563c:	4581                	li	a1,0
    8000563e:	854e                	mv	a0,s3
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	4d6080e7          	jalr	1238(ra) # 80003b16 <writei>
    80005648:	47c1                	li	a5,16
    8000564a:	0af51363          	bne	a0,a5,800056f0 <sys_unlink+0x178>
  if(ip->type == T_DIR){
    8000564e:	04449703          	lh	a4,68(s1)
    80005652:	4785                	li	a5,1
    80005654:	0af70663          	beq	a4,a5,80005700 <sys_unlink+0x188>
  iunlockput(dp);
    80005658:	854e                	mv	a0,s3
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	372080e7          	jalr	882(ra) # 800039cc <iunlockput>
  ip->nlink--;
    80005662:	04a4d783          	lhu	a5,74(s1)
    80005666:	37fd                	addiw	a5,a5,-1
    80005668:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000566c:	8526                	mv	a0,s1
    8000566e:	ffffe097          	auipc	ra,0xffffe
    80005672:	02e080e7          	jalr	46(ra) # 8000369c <iupdate>
  iunlockput(ip);
    80005676:	8526                	mv	a0,s1
    80005678:	ffffe097          	auipc	ra,0xffffe
    8000567c:	354080e7          	jalr	852(ra) # 800039cc <iunlockput>
  end_op();
    80005680:	fffff097          	auipc	ra,0xfffff
    80005684:	b46080e7          	jalr	-1210(ra) # 800041c6 <end_op>
  return 0;
    80005688:	4501                	li	a0,0
    8000568a:	a07d                	j	80005738 <sys_unlink+0x1c0>
    end_op();
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	b3a080e7          	jalr	-1222(ra) # 800041c6 <end_op>
    return -1;
    80005694:	557d                	li	a0,-1
    80005696:	a04d                	j	80005738 <sys_unlink+0x1c0>
    panic("unlink: nlink < 1");
    80005698:	00003517          	auipc	a0,0x3
    8000569c:	04050513          	addi	a0,a0,64 # 800086d8 <syscalls+0x318>
    800056a0:	ffffb097          	auipc	ra,0xffffb
    800056a4:	eb8080e7          	jalr	-328(ra) # 80000558 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056a8:	44f8                	lw	a4,76(s1)
    800056aa:	02000793          	li	a5,32
    800056ae:	f6e7fae3          	bleu	a4,a5,80005622 <sys_unlink+0xaa>
    800056b2:	02000913          	li	s2,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056b6:	4741                	li	a4,16
    800056b8:	86ca                	mv	a3,s2
    800056ba:	f1840613          	addi	a2,s0,-232
    800056be:	4581                	li	a1,0
    800056c0:	8526                	mv	a0,s1
    800056c2:	ffffe097          	auipc	ra,0xffffe
    800056c6:	35c080e7          	jalr	860(ra) # 80003a1e <readi>
    800056ca:	47c1                	li	a5,16
    800056cc:	00f51a63          	bne	a0,a5,800056e0 <sys_unlink+0x168>
    if(de.inum != 0)
    800056d0:	f1845783          	lhu	a5,-232(s0)
    800056d4:	e3b9                	bnez	a5,8000571a <sys_unlink+0x1a2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056d6:	2941                	addiw	s2,s2,16
    800056d8:	44fc                	lw	a5,76(s1)
    800056da:	fcf96ee3          	bltu	s2,a5,800056b6 <sys_unlink+0x13e>
    800056de:	b791                	j	80005622 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056e0:	00003517          	auipc	a0,0x3
    800056e4:	01050513          	addi	a0,a0,16 # 800086f0 <syscalls+0x330>
    800056e8:	ffffb097          	auipc	ra,0xffffb
    800056ec:	e70080e7          	jalr	-400(ra) # 80000558 <panic>
    panic("unlink: writei");
    800056f0:	00003517          	auipc	a0,0x3
    800056f4:	01850513          	addi	a0,a0,24 # 80008708 <syscalls+0x348>
    800056f8:	ffffb097          	auipc	ra,0xffffb
    800056fc:	e60080e7          	jalr	-416(ra) # 80000558 <panic>
    dp->nlink--;
    80005700:	04a9d783          	lhu	a5,74(s3)
    80005704:	37fd                	addiw	a5,a5,-1
    80005706:	04f99523          	sh	a5,74(s3)
    iupdate(dp);
    8000570a:	854e                	mv	a0,s3
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	f90080e7          	jalr	-112(ra) # 8000369c <iupdate>
    80005714:	b791                	j	80005658 <sys_unlink+0xe0>
    return -1;
    80005716:	557d                	li	a0,-1
    80005718:	a005                	j	80005738 <sys_unlink+0x1c0>
    iunlockput(ip);
    8000571a:	8526                	mv	a0,s1
    8000571c:	ffffe097          	auipc	ra,0xffffe
    80005720:	2b0080e7          	jalr	688(ra) # 800039cc <iunlockput>
  iunlockput(dp);
    80005724:	854e                	mv	a0,s3
    80005726:	ffffe097          	auipc	ra,0xffffe
    8000572a:	2a6080e7          	jalr	678(ra) # 800039cc <iunlockput>
  end_op();
    8000572e:	fffff097          	auipc	ra,0xfffff
    80005732:	a98080e7          	jalr	-1384(ra) # 800041c6 <end_op>
  return -1;
    80005736:	557d                	li	a0,-1
}
    80005738:	70ae                	ld	ra,232(sp)
    8000573a:	740e                	ld	s0,224(sp)
    8000573c:	64ee                	ld	s1,216(sp)
    8000573e:	694e                	ld	s2,208(sp)
    80005740:	69ae                	ld	s3,200(sp)
    80005742:	616d                	addi	sp,sp,240
    80005744:	8082                	ret

0000000080005746 <sys_open>:

uint64
sys_open(void)
{
    80005746:	7131                	addi	sp,sp,-192
    80005748:	fd06                	sd	ra,184(sp)
    8000574a:	f922                	sd	s0,176(sp)
    8000574c:	f526                	sd	s1,168(sp)
    8000574e:	f14a                	sd	s2,160(sp)
    80005750:	ed4e                	sd	s3,152(sp)
    80005752:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005754:	08000613          	li	a2,128
    80005758:	f5040593          	addi	a1,s0,-176
    8000575c:	4501                	li	a0,0
    8000575e:	ffffd097          	auipc	ra,0xffffd
    80005762:	48e080e7          	jalr	1166(ra) # 80002bec <argstr>
    return -1;
    80005766:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005768:	0c054163          	bltz	a0,8000582a <sys_open+0xe4>
    8000576c:	f4c40593          	addi	a1,s0,-180
    80005770:	4505                	li	a0,1
    80005772:	ffffd097          	auipc	ra,0xffffd
    80005776:	436080e7          	jalr	1078(ra) # 80002ba8 <argint>
    8000577a:	0a054863          	bltz	a0,8000582a <sys_open+0xe4>

  begin_op();
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	9c8080e7          	jalr	-1592(ra) # 80004146 <begin_op>

  if(omode & O_CREATE){
    80005786:	f4c42783          	lw	a5,-180(s0)
    8000578a:	2007f793          	andi	a5,a5,512
    8000578e:	cbdd                	beqz	a5,80005844 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005790:	4681                	li	a3,0
    80005792:	4601                	li	a2,0
    80005794:	4589                	li	a1,2
    80005796:	f5040513          	addi	a0,s0,-176
    8000579a:	00000097          	auipc	ra,0x0
    8000579e:	976080e7          	jalr	-1674(ra) # 80005110 <create>
    800057a2:	892a                	mv	s2,a0
    if(ip == 0){
    800057a4:	c959                	beqz	a0,8000583a <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057a6:	04491703          	lh	a4,68(s2)
    800057aa:	478d                	li	a5,3
    800057ac:	00f71763          	bne	a4,a5,800057ba <sys_open+0x74>
    800057b0:	04695703          	lhu	a4,70(s2)
    800057b4:	47a5                	li	a5,9
    800057b6:	0ce7ec63          	bltu	a5,a4,8000588e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	dc0080e7          	jalr	-576(ra) # 8000457a <filealloc>
    800057c2:	89aa                	mv	s3,a0
    800057c4:	10050263          	beqz	a0,800058c8 <sys_open+0x182>
    800057c8:	00000097          	auipc	ra,0x0
    800057cc:	900080e7          	jalr	-1792(ra) # 800050c8 <fdalloc>
    800057d0:	84aa                	mv	s1,a0
    800057d2:	0e054663          	bltz	a0,800058be <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057d6:	04491703          	lh	a4,68(s2)
    800057da:	478d                	li	a5,3
    800057dc:	0cf70463          	beq	a4,a5,800058a4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057e0:	4789                	li	a5,2
    800057e2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057e6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057ea:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057ee:	f4c42783          	lw	a5,-180(s0)
    800057f2:	0017c713          	xori	a4,a5,1
    800057f6:	8b05                	andi	a4,a4,1
    800057f8:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057fc:	0037f713          	andi	a4,a5,3
    80005800:	00e03733          	snez	a4,a4
    80005804:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005808:	4007f793          	andi	a5,a5,1024
    8000580c:	c791                	beqz	a5,80005818 <sys_open+0xd2>
    8000580e:	04491703          	lh	a4,68(s2)
    80005812:	4789                	li	a5,2
    80005814:	08f70f63          	beq	a4,a5,800058b2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005818:	854a                	mv	a0,s2
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	012080e7          	jalr	18(ra) # 8000382c <iunlock>
  end_op();
    80005822:	fffff097          	auipc	ra,0xfffff
    80005826:	9a4080e7          	jalr	-1628(ra) # 800041c6 <end_op>

  return fd;
}
    8000582a:	8526                	mv	a0,s1
    8000582c:	70ea                	ld	ra,184(sp)
    8000582e:	744a                	ld	s0,176(sp)
    80005830:	74aa                	ld	s1,168(sp)
    80005832:	790a                	ld	s2,160(sp)
    80005834:	69ea                	ld	s3,152(sp)
    80005836:	6129                	addi	sp,sp,192
    80005838:	8082                	ret
      end_op();
    8000583a:	fffff097          	auipc	ra,0xfffff
    8000583e:	98c080e7          	jalr	-1652(ra) # 800041c6 <end_op>
      return -1;
    80005842:	b7e5                	j	8000582a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005844:	f5040513          	addi	a0,s0,-176
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	6e0080e7          	jalr	1760(ra) # 80003f28 <namei>
    80005850:	892a                	mv	s2,a0
    80005852:	c905                	beqz	a0,80005882 <sys_open+0x13c>
    ilock(ip);
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	f14080e7          	jalr	-236(ra) # 80003768 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000585c:	04491703          	lh	a4,68(s2)
    80005860:	4785                	li	a5,1
    80005862:	f4f712e3          	bne	a4,a5,800057a6 <sys_open+0x60>
    80005866:	f4c42783          	lw	a5,-180(s0)
    8000586a:	dba1                	beqz	a5,800057ba <sys_open+0x74>
      iunlockput(ip);
    8000586c:	854a                	mv	a0,s2
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	15e080e7          	jalr	350(ra) # 800039cc <iunlockput>
      end_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	950080e7          	jalr	-1712(ra) # 800041c6 <end_op>
      return -1;
    8000587e:	54fd                	li	s1,-1
    80005880:	b76d                	j	8000582a <sys_open+0xe4>
      end_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	944080e7          	jalr	-1724(ra) # 800041c6 <end_op>
      return -1;
    8000588a:	54fd                	li	s1,-1
    8000588c:	bf79                	j	8000582a <sys_open+0xe4>
    iunlockput(ip);
    8000588e:	854a                	mv	a0,s2
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	13c080e7          	jalr	316(ra) # 800039cc <iunlockput>
    end_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	92e080e7          	jalr	-1746(ra) # 800041c6 <end_op>
    return -1;
    800058a0:	54fd                	li	s1,-1
    800058a2:	b761                	j	8000582a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058a4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058a8:	04691783          	lh	a5,70(s2)
    800058ac:	02f99223          	sh	a5,36(s3)
    800058b0:	bf2d                	j	800057ea <sys_open+0xa4>
    itrunc(ip);
    800058b2:	854a                	mv	a0,s2
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	fc4080e7          	jalr	-60(ra) # 80003878 <itrunc>
    800058bc:	bfb1                	j	80005818 <sys_open+0xd2>
      fileclose(f);
    800058be:	854e                	mv	a0,s3
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	d8a080e7          	jalr	-630(ra) # 8000464a <fileclose>
    iunlockput(ip);
    800058c8:	854a                	mv	a0,s2
    800058ca:	ffffe097          	auipc	ra,0xffffe
    800058ce:	102080e7          	jalr	258(ra) # 800039cc <iunlockput>
    end_op();
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	8f4080e7          	jalr	-1804(ra) # 800041c6 <end_op>
    return -1;
    800058da:	54fd                	li	s1,-1
    800058dc:	b7b9                	j	8000582a <sys_open+0xe4>

00000000800058de <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058de:	7175                	addi	sp,sp,-144
    800058e0:	e506                	sd	ra,136(sp)
    800058e2:	e122                	sd	s0,128(sp)
    800058e4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	860080e7          	jalr	-1952(ra) # 80004146 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058ee:	08000613          	li	a2,128
    800058f2:	f7040593          	addi	a1,s0,-144
    800058f6:	4501                	li	a0,0
    800058f8:	ffffd097          	auipc	ra,0xffffd
    800058fc:	2f4080e7          	jalr	756(ra) # 80002bec <argstr>
    80005900:	02054963          	bltz	a0,80005932 <sys_mkdir+0x54>
    80005904:	4681                	li	a3,0
    80005906:	4601                	li	a2,0
    80005908:	4585                	li	a1,1
    8000590a:	f7040513          	addi	a0,s0,-144
    8000590e:	00000097          	auipc	ra,0x0
    80005912:	802080e7          	jalr	-2046(ra) # 80005110 <create>
    80005916:	cd11                	beqz	a0,80005932 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	0b4080e7          	jalr	180(ra) # 800039cc <iunlockput>
  end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	8a6080e7          	jalr	-1882(ra) # 800041c6 <end_op>
  return 0;
    80005928:	4501                	li	a0,0
}
    8000592a:	60aa                	ld	ra,136(sp)
    8000592c:	640a                	ld	s0,128(sp)
    8000592e:	6149                	addi	sp,sp,144
    80005930:	8082                	ret
    end_op();
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	894080e7          	jalr	-1900(ra) # 800041c6 <end_op>
    return -1;
    8000593a:	557d                	li	a0,-1
    8000593c:	b7fd                	j	8000592a <sys_mkdir+0x4c>

000000008000593e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000593e:	7135                	addi	sp,sp,-160
    80005940:	ed06                	sd	ra,152(sp)
    80005942:	e922                	sd	s0,144(sp)
    80005944:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005946:	fffff097          	auipc	ra,0xfffff
    8000594a:	800080e7          	jalr	-2048(ra) # 80004146 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594e:	08000613          	li	a2,128
    80005952:	f7040593          	addi	a1,s0,-144
    80005956:	4501                	li	a0,0
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	294080e7          	jalr	660(ra) # 80002bec <argstr>
    80005960:	04054a63          	bltz	a0,800059b4 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005964:	f6c40593          	addi	a1,s0,-148
    80005968:	4505                	li	a0,1
    8000596a:	ffffd097          	auipc	ra,0xffffd
    8000596e:	23e080e7          	jalr	574(ra) # 80002ba8 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005972:	04054163          	bltz	a0,800059b4 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005976:	f6840593          	addi	a1,s0,-152
    8000597a:	4509                	li	a0,2
    8000597c:	ffffd097          	auipc	ra,0xffffd
    80005980:	22c080e7          	jalr	556(ra) # 80002ba8 <argint>
     argint(1, &major) < 0 ||
    80005984:	02054863          	bltz	a0,800059b4 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005988:	f6841683          	lh	a3,-152(s0)
    8000598c:	f6c41603          	lh	a2,-148(s0)
    80005990:	458d                	li	a1,3
    80005992:	f7040513          	addi	a0,s0,-144
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	77a080e7          	jalr	1914(ra) # 80005110 <create>
     argint(2, &minor) < 0 ||
    8000599e:	c919                	beqz	a0,800059b4 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	02c080e7          	jalr	44(ra) # 800039cc <iunlockput>
  end_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	81e080e7          	jalr	-2018(ra) # 800041c6 <end_op>
  return 0;
    800059b0:	4501                	li	a0,0
    800059b2:	a031                	j	800059be <sys_mknod+0x80>
    end_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	812080e7          	jalr	-2030(ra) # 800041c6 <end_op>
    return -1;
    800059bc:	557d                	li	a0,-1
}
    800059be:	60ea                	ld	ra,152(sp)
    800059c0:	644a                	ld	s0,144(sp)
    800059c2:	610d                	addi	sp,sp,160
    800059c4:	8082                	ret

00000000800059c6 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059c6:	7135                	addi	sp,sp,-160
    800059c8:	ed06                	sd	ra,152(sp)
    800059ca:	e922                	sd	s0,144(sp)
    800059cc:	e526                	sd	s1,136(sp)
    800059ce:	e14a                	sd	s2,128(sp)
    800059d0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059d2:	ffffc097          	auipc	ra,0xffffc
    800059d6:	06c080e7          	jalr	108(ra) # 80001a3e <myproc>
    800059da:	892a                	mv	s2,a0
  
  begin_op();
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	76a080e7          	jalr	1898(ra) # 80004146 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059e4:	08000613          	li	a2,128
    800059e8:	f6040593          	addi	a1,s0,-160
    800059ec:	4501                	li	a0,0
    800059ee:	ffffd097          	auipc	ra,0xffffd
    800059f2:	1fe080e7          	jalr	510(ra) # 80002bec <argstr>
    800059f6:	04054b63          	bltz	a0,80005a4c <sys_chdir+0x86>
    800059fa:	f6040513          	addi	a0,s0,-160
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	52a080e7          	jalr	1322(ra) # 80003f28 <namei>
    80005a06:	84aa                	mv	s1,a0
    80005a08:	c131                	beqz	a0,80005a4c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a0a:	ffffe097          	auipc	ra,0xffffe
    80005a0e:	d5e080e7          	jalr	-674(ra) # 80003768 <ilock>
  if(ip->type != T_DIR){
    80005a12:	04449703          	lh	a4,68(s1)
    80005a16:	4785                	li	a5,1
    80005a18:	04f71063          	bne	a4,a5,80005a58 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a1c:	8526                	mv	a0,s1
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	e0e080e7          	jalr	-498(ra) # 8000382c <iunlock>
  iput(p->cwd);
    80005a26:	15093503          	ld	a0,336(s2)
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	efa080e7          	jalr	-262(ra) # 80003924 <iput>
  end_op();
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	794080e7          	jalr	1940(ra) # 800041c6 <end_op>
  p->cwd = ip;
    80005a3a:	14993823          	sd	s1,336(s2)
  return 0;
    80005a3e:	4501                	li	a0,0
}
    80005a40:	60ea                	ld	ra,152(sp)
    80005a42:	644a                	ld	s0,144(sp)
    80005a44:	64aa                	ld	s1,136(sp)
    80005a46:	690a                	ld	s2,128(sp)
    80005a48:	610d                	addi	sp,sp,160
    80005a4a:	8082                	ret
    end_op();
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	77a080e7          	jalr	1914(ra) # 800041c6 <end_op>
    return -1;
    80005a54:	557d                	li	a0,-1
    80005a56:	b7ed                	j	80005a40 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a58:	8526                	mv	a0,s1
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	f72080e7          	jalr	-142(ra) # 800039cc <iunlockput>
    end_op();
    80005a62:	ffffe097          	auipc	ra,0xffffe
    80005a66:	764080e7          	jalr	1892(ra) # 800041c6 <end_op>
    return -1;
    80005a6a:	557d                	li	a0,-1
    80005a6c:	bfd1                	j	80005a40 <sys_chdir+0x7a>

0000000080005a6e <sys_exec>:

uint64
sys_exec(void)
{
    80005a6e:	7145                	addi	sp,sp,-464
    80005a70:	e786                	sd	ra,456(sp)
    80005a72:	e3a2                	sd	s0,448(sp)
    80005a74:	ff26                	sd	s1,440(sp)
    80005a76:	fb4a                	sd	s2,432(sp)
    80005a78:	f74e                	sd	s3,424(sp)
    80005a7a:	f352                	sd	s4,416(sp)
    80005a7c:	ef56                	sd	s5,408(sp)
    80005a7e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a80:	08000613          	li	a2,128
    80005a84:	f4040593          	addi	a1,s0,-192
    80005a88:	4501                	li	a0,0
    80005a8a:	ffffd097          	auipc	ra,0xffffd
    80005a8e:	162080e7          	jalr	354(ra) # 80002bec <argstr>
    return -1;
    80005a92:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a94:	0e054c63          	bltz	a0,80005b8c <sys_exec+0x11e>
    80005a98:	e3840593          	addi	a1,s0,-456
    80005a9c:	4505                	li	a0,1
    80005a9e:	ffffd097          	auipc	ra,0xffffd
    80005aa2:	12c080e7          	jalr	300(ra) # 80002bca <argaddr>
    80005aa6:	0e054363          	bltz	a0,80005b8c <sys_exec+0x11e>
  }
  memset(argv, 0, sizeof(argv));
    80005aaa:	e4040913          	addi	s2,s0,-448
    80005aae:	10000613          	li	a2,256
    80005ab2:	4581                	li	a1,0
    80005ab4:	854a                	mv	a0,s2
    80005ab6:	ffffb097          	auipc	ra,0xffffb
    80005aba:	26a080e7          	jalr	618(ra) # 80000d20 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005abe:	89ca                	mv	s3,s2
  memset(argv, 0, sizeof(argv));
    80005ac0:	4481                	li	s1,0
    if(i >= NELEM(argv)){
    80005ac2:	02000a93          	li	s5,32
    80005ac6:	00048a1b          	sext.w	s4,s1
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aca:	00349513          	slli	a0,s1,0x3
    80005ace:	e3040593          	addi	a1,s0,-464
    80005ad2:	e3843783          	ld	a5,-456(s0)
    80005ad6:	953e                	add	a0,a0,a5
    80005ad8:	ffffd097          	auipc	ra,0xffffd
    80005adc:	034080e7          	jalr	52(ra) # 80002b0c <fetchaddr>
    80005ae0:	02054a63          	bltz	a0,80005b14 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ae4:	e3043783          	ld	a5,-464(s0)
    80005ae8:	cfa9                	beqz	a5,80005b42 <sys_exec+0xd4>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005aea:	ffffb097          	auipc	ra,0xffffb
    80005aee:	04a080e7          	jalr	74(ra) # 80000b34 <kalloc>
    80005af2:	00a93023          	sd	a0,0(s2)
    if(argv[i] == 0)
    80005af6:	cd19                	beqz	a0,80005b14 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005af8:	6605                	lui	a2,0x1
    80005afa:	85aa                	mv	a1,a0
    80005afc:	e3043503          	ld	a0,-464(s0)
    80005b00:	ffffd097          	auipc	ra,0xffffd
    80005b04:	060080e7          	jalr	96(ra) # 80002b60 <fetchstr>
    80005b08:	00054663          	bltz	a0,80005b14 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b0c:	0485                	addi	s1,s1,1
    80005b0e:	0921                	addi	s2,s2,8
    80005b10:	fb549be3          	bne	s1,s5,80005ac6 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b14:	e4043503          	ld	a0,-448(s0)
    kfree(argv[i]);
  return -1;
    80005b18:	597d                	li	s2,-1
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1a:	c92d                	beqz	a0,80005b8c <sys_exec+0x11e>
    kfree(argv[i]);
    80005b1c:	ffffb097          	auipc	ra,0xffffb
    80005b20:	f18080e7          	jalr	-232(ra) # 80000a34 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b24:	e4840493          	addi	s1,s0,-440
    80005b28:	10098993          	addi	s3,s3,256
    80005b2c:	6088                	ld	a0,0(s1)
    80005b2e:	cd31                	beqz	a0,80005b8a <sys_exec+0x11c>
    kfree(argv[i]);
    80005b30:	ffffb097          	auipc	ra,0xffffb
    80005b34:	f04080e7          	jalr	-252(ra) # 80000a34 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b38:	04a1                	addi	s1,s1,8
    80005b3a:	ff3499e3          	bne	s1,s3,80005b2c <sys_exec+0xbe>
  return -1;
    80005b3e:	597d                	li	s2,-1
    80005b40:	a0b1                	j	80005b8c <sys_exec+0x11e>
      argv[i] = 0;
    80005b42:	0a0e                	slli	s4,s4,0x3
    80005b44:	fc040793          	addi	a5,s0,-64
    80005b48:	9a3e                	add	s4,s4,a5
    80005b4a:	e80a3023          	sd	zero,-384(s4)
  int ret = exec(path, argv);
    80005b4e:	e4040593          	addi	a1,s0,-448
    80005b52:	f4040513          	addi	a0,s0,-192
    80005b56:	fffff097          	auipc	ra,0xfffff
    80005b5a:	166080e7          	jalr	358(ra) # 80004cbc <exec>
    80005b5e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b60:	e4043503          	ld	a0,-448(s0)
    80005b64:	c505                	beqz	a0,80005b8c <sys_exec+0x11e>
    kfree(argv[i]);
    80005b66:	ffffb097          	auipc	ra,0xffffb
    80005b6a:	ece080e7          	jalr	-306(ra) # 80000a34 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b6e:	e4840493          	addi	s1,s0,-440
    80005b72:	10098993          	addi	s3,s3,256
    80005b76:	6088                	ld	a0,0(s1)
    80005b78:	c911                	beqz	a0,80005b8c <sys_exec+0x11e>
    kfree(argv[i]);
    80005b7a:	ffffb097          	auipc	ra,0xffffb
    80005b7e:	eba080e7          	jalr	-326(ra) # 80000a34 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b82:	04a1                	addi	s1,s1,8
    80005b84:	ff3499e3          	bne	s1,s3,80005b76 <sys_exec+0x108>
    80005b88:	a011                	j	80005b8c <sys_exec+0x11e>
  return -1;
    80005b8a:	597d                	li	s2,-1
}
    80005b8c:	854a                	mv	a0,s2
    80005b8e:	60be                	ld	ra,456(sp)
    80005b90:	641e                	ld	s0,448(sp)
    80005b92:	74fa                	ld	s1,440(sp)
    80005b94:	795a                	ld	s2,432(sp)
    80005b96:	79ba                	ld	s3,424(sp)
    80005b98:	7a1a                	ld	s4,416(sp)
    80005b9a:	6afa                	ld	s5,408(sp)
    80005b9c:	6179                	addi	sp,sp,464
    80005b9e:	8082                	ret

0000000080005ba0 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ba0:	7139                	addi	sp,sp,-64
    80005ba2:	fc06                	sd	ra,56(sp)
    80005ba4:	f822                	sd	s0,48(sp)
    80005ba6:	f426                	sd	s1,40(sp)
    80005ba8:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005baa:	ffffc097          	auipc	ra,0xffffc
    80005bae:	e94080e7          	jalr	-364(ra) # 80001a3e <myproc>
    80005bb2:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bb4:	fd840593          	addi	a1,s0,-40
    80005bb8:	4501                	li	a0,0
    80005bba:	ffffd097          	auipc	ra,0xffffd
    80005bbe:	010080e7          	jalr	16(ra) # 80002bca <argaddr>
    return -1;
    80005bc2:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bc4:	0c054f63          	bltz	a0,80005ca2 <sys_pipe+0x102>
  if(pipealloc(&rf, &wf) < 0)
    80005bc8:	fc840593          	addi	a1,s0,-56
    80005bcc:	fd040513          	addi	a0,s0,-48
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	d9e080e7          	jalr	-610(ra) # 8000496e <pipealloc>
    return -1;
    80005bd8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bda:	0c054463          	bltz	a0,80005ca2 <sys_pipe+0x102>
  fd0 = -1;
    80005bde:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005be2:	fd043503          	ld	a0,-48(s0)
    80005be6:	fffff097          	auipc	ra,0xfffff
    80005bea:	4e2080e7          	jalr	1250(ra) # 800050c8 <fdalloc>
    80005bee:	fca42223          	sw	a0,-60(s0)
    80005bf2:	08054b63          	bltz	a0,80005c88 <sys_pipe+0xe8>
    80005bf6:	fc843503          	ld	a0,-56(s0)
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	4ce080e7          	jalr	1230(ra) # 800050c8 <fdalloc>
    80005c02:	fca42023          	sw	a0,-64(s0)
    80005c06:	06054863          	bltz	a0,80005c76 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c0a:	4691                	li	a3,4
    80005c0c:	fc440613          	addi	a2,s0,-60
    80005c10:	fd843583          	ld	a1,-40(s0)
    80005c14:	68a8                	ld	a0,80(s1)
    80005c16:	ffffc097          	auipc	ra,0xffffc
    80005c1a:	a94080e7          	jalr	-1388(ra) # 800016aa <copyout>
    80005c1e:	02054063          	bltz	a0,80005c3e <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c22:	4691                	li	a3,4
    80005c24:	fc040613          	addi	a2,s0,-64
    80005c28:	fd843583          	ld	a1,-40(s0)
    80005c2c:	0591                	addi	a1,a1,4
    80005c2e:	68a8                	ld	a0,80(s1)
    80005c30:	ffffc097          	auipc	ra,0xffffc
    80005c34:	a7a080e7          	jalr	-1414(ra) # 800016aa <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c38:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c3a:	06055463          	bgez	a0,80005ca2 <sys_pipe+0x102>
    p->ofile[fd0] = 0;
    80005c3e:	fc442783          	lw	a5,-60(s0)
    80005c42:	07e9                	addi	a5,a5,26
    80005c44:	078e                	slli	a5,a5,0x3
    80005c46:	97a6                	add	a5,a5,s1
    80005c48:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c4c:	fc042783          	lw	a5,-64(s0)
    80005c50:	07e9                	addi	a5,a5,26
    80005c52:	078e                	slli	a5,a5,0x3
    80005c54:	94be                	add	s1,s1,a5
    80005c56:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c5a:	fd043503          	ld	a0,-48(s0)
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	9ec080e7          	jalr	-1556(ra) # 8000464a <fileclose>
    fileclose(wf);
    80005c66:	fc843503          	ld	a0,-56(s0)
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	9e0080e7          	jalr	-1568(ra) # 8000464a <fileclose>
    return -1;
    80005c72:	57fd                	li	a5,-1
    80005c74:	a03d                	j	80005ca2 <sys_pipe+0x102>
    if(fd0 >= 0)
    80005c76:	fc442783          	lw	a5,-60(s0)
    80005c7a:	0007c763          	bltz	a5,80005c88 <sys_pipe+0xe8>
      p->ofile[fd0] = 0;
    80005c7e:	07e9                	addi	a5,a5,26
    80005c80:	078e                	slli	a5,a5,0x3
    80005c82:	94be                	add	s1,s1,a5
    80005c84:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c88:	fd043503          	ld	a0,-48(s0)
    80005c8c:	fffff097          	auipc	ra,0xfffff
    80005c90:	9be080e7          	jalr	-1602(ra) # 8000464a <fileclose>
    fileclose(wf);
    80005c94:	fc843503          	ld	a0,-56(s0)
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	9b2080e7          	jalr	-1614(ra) # 8000464a <fileclose>
    return -1;
    80005ca0:	57fd                	li	a5,-1
}
    80005ca2:	853e                	mv	a0,a5
    80005ca4:	70e2                	ld	ra,56(sp)
    80005ca6:	7442                	ld	s0,48(sp)
    80005ca8:	74a2                	ld	s1,40(sp)
    80005caa:	6121                	addi	sp,sp,64
    80005cac:	8082                	ret

0000000080005cae <get_unused_vma>:

//
struct VMA*
get_unused_vma()
{
    80005cae:	1141                	addi	sp,sp,-16
    80005cb0:	e406                	sd	ra,8(sp)
    80005cb2:	e022                	sd	s0,0(sp)
    80005cb4:	0800                	addi	s0,sp,16
  struct proc* p = myproc();
    80005cb6:	ffffc097          	auipc	ra,0xffffc
    80005cba:	d88080e7          	jalr	-632(ra) # 80001a3e <myproc>
  for (int i = 0; i < 16; i++) {
    if (p->vma[i].valid == 0) {
    80005cbe:	18452783          	lw	a5,388(a0)
    80005cc2:	c38d                	beqz	a5,80005ce4 <get_unused_vma+0x36>
    80005cc4:	1b450713          	addi	a4,a0,436
  for (int i = 0; i < 16; i++) {
    80005cc8:	4785                	li	a5,1
    80005cca:	4641                	li	a2,16
    if (p->vma[i].valid == 0) {
    80005ccc:	4314                	lw	a3,0(a4)
    80005cce:	ca99                	beqz	a3,80005ce4 <get_unused_vma+0x36>
  for (int i = 0; i < 16; i++) {
    80005cd0:	2785                	addiw	a5,a5,1
    80005cd2:	03070713          	addi	a4,a4,48
    80005cd6:	fec79be3          	bne	a5,a2,80005ccc <get_unused_vma+0x1e>
      return &(p->vma[i]);
    }
  }
  return 0;
    80005cda:	4501                	li	a0,0
}
    80005cdc:	60a2                	ld	ra,8(sp)
    80005cde:	6402                	ld	s0,0(sp)
    80005ce0:	0141                	addi	sp,sp,16
    80005ce2:	8082                	ret
      return &(p->vma[i]);
    80005ce4:	00179713          	slli	a4,a5,0x1
    80005ce8:	97ba                	add	a5,a5,a4
    80005cea:	0792                	slli	a5,a5,0x4
    80005cec:	16878793          	addi	a5,a5,360
    80005cf0:	953e                	add	a0,a0,a5
    80005cf2:	b7ed                	j	80005cdc <get_unused_vma+0x2e>

0000000080005cf4 <get_vma_by_address>:

struct VMA*
get_vma_by_address(uint64 va)
{
    80005cf4:	1101                	addi	sp,sp,-32
    80005cf6:	ec06                	sd	ra,24(sp)
    80005cf8:	e822                	sd	s0,16(sp)
    80005cfa:	e426                	sd	s1,8(sp)
    80005cfc:	1000                	addi	s0,sp,32
    80005cfe:	84aa                	mv	s1,a0
  struct proc* p = myproc();
    80005d00:	ffffc097          	auipc	ra,0xffffc
    80005d04:	d3e080e7          	jalr	-706(ra) # 80001a3e <myproc>
  for (int i = 0; i < 16; i++) {
    80005d08:	16850793          	addi	a5,a0,360
    80005d0c:	4701                	li	a4,0
    80005d0e:	45c1                	li	a1,16
    80005d10:	a031                	j	80005d1c <get_vma_by_address+0x28>
    80005d12:	2705                	addiw	a4,a4,1
    80005d14:	03078793          	addi	a5,a5,48
    80005d18:	02b70363          	beq	a4,a1,80005d3e <get_vma_by_address+0x4a>
    struct VMA* curr = &(p->vma[i]);
    if (curr->valid == 0)
    80005d1c:	4fd4                	lw	a3,28(a5)
    80005d1e:	daf5                	beqz	a3,80005d12 <get_vma_by_address+0x1e>
      continue;
    // the address is covered by the vma
    if (curr->addr <= va && curr->addr + curr->length > va) {
    80005d20:	6394                	ld	a3,0(a5)
    80005d22:	fed4e8e3          	bltu	s1,a3,80005d12 <get_vma_by_address+0x1e>
    80005d26:	6790                	ld	a2,8(a5)
    80005d28:	96b2                	add	a3,a3,a2
    80005d2a:	fed4f4e3          	bleu	a3,s1,80005d12 <get_vma_by_address+0x1e>
    struct VMA* curr = &(p->vma[i]);
    80005d2e:	00171793          	slli	a5,a4,0x1
    80005d32:	97ba                	add	a5,a5,a4
    80005d34:	0792                	slli	a5,a5,0x4
    80005d36:	16878793          	addi	a5,a5,360
    80005d3a:	953e                	add	a0,a0,a5
    80005d3c:	a011                	j	80005d40 <get_vma_by_address+0x4c>
      return curr;
    }
  }
  return 0;
    80005d3e:	4501                	li	a0,0
}
    80005d40:	60e2                	ld	ra,24(sp)
    80005d42:	6442                	ld	s0,16(sp)
    80005d44:	64a2                	ld	s1,8(sp)
    80005d46:	6105                	addi	sp,sp,32
    80005d48:	8082                	ret

0000000080005d4a <get_vma_start_addr>:
// find available virtual address at the top of process
// and then increase the process size
// it is something like sbrk
uint64
get_vma_start_addr(uint64 length)
{
    80005d4a:	1101                	addi	sp,sp,-32
    80005d4c:	ec06                	sd	ra,24(sp)
    80005d4e:	e822                	sd	s0,16(sp)
    80005d50:	e426                	sd	s1,8(sp)
    80005d52:	1000                	addi	s0,sp,32
    80005d54:	84aa                	mv	s1,a0
  struct proc* p = myproc();
    80005d56:	ffffc097          	auipc	ra,0xffffc
    80005d5a:	ce8080e7          	jalr	-792(ra) # 80001a3e <myproc>
  uint64 addr = PGROUNDUP(p->sz);
    80005d5e:	653c                	ld	a5,72(a0)
    80005d60:	6705                	lui	a4,0x1
    80005d62:	177d                	addi	a4,a4,-1
    80005d64:	97ba                	add	a5,a5,a4
    80005d66:	777d                	lui	a4,0xfffff
    80005d68:	8ff9                	and	a5,a5,a4
  p->sz = addr + length;
    80005d6a:	94be                	add	s1,s1,a5
    80005d6c:	e524                	sd	s1,72(a0)
  return addr;
}
    80005d6e:	853e                	mv	a0,a5
    80005d70:	60e2                	ld	ra,24(sp)
    80005d72:	6442                	ld	s0,16(sp)
    80005d74:	64a2                	ld	s1,8(sp)
    80005d76:	6105                	addi	sp,sp,32
    80005d78:	8082                	ret

0000000080005d7a <sys_mmap>:
// flags: map_shared/map_private, flags will be either MAP_SHARED,
// meaning that modifications to the mapped memory should be written back to
// the file, or MAP_PRIVATE, meaning that they should not.
uint64
sys_mmap()
{
    80005d7a:	715d                	addi	sp,sp,-80
    80005d7c:	e486                	sd	ra,72(sp)
    80005d7e:	e0a2                	sd	s0,64(sp)
    80005d80:	fc26                	sd	s1,56(sp)
    80005d82:	0880                	addi	s0,sp,80
  uint64 addr = 0, length = 0, offset = 0;
    80005d84:	fc043c23          	sd	zero,-40(s0)
    80005d88:	fc043823          	sd	zero,-48(s0)
    80005d8c:	fc043423          	sd	zero,-56(s0)
  int prot = 0, flags = 0;
    80005d90:	fc042223          	sw	zero,-60(s0)
    80005d94:	fc042023          	sw	zero,-64(s0)
  struct file *f;
  if (argaddr(0, &addr) < 0) // addr is 0 by default, which means the user does not use specific address
    80005d98:	fd840593          	addi	a1,s0,-40
    80005d9c:	4501                	li	a0,0
    80005d9e:	ffffd097          	auipc	ra,0xffffd
    80005da2:	e2c080e7          	jalr	-468(ra) # 80002bca <argaddr>
    return -1;
    80005da6:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0) // addr is 0 by default, which means the user does not use specific address
    80005da8:	10054363          	bltz	a0,80005eae <sys_mmap+0x134>
  if (argaddr(1, &length) < 0)
    80005dac:	fd040593          	addi	a1,s0,-48
    80005db0:	4505                	li	a0,1
    80005db2:	ffffd097          	auipc	ra,0xffffd
    80005db6:	e18080e7          	jalr	-488(ra) # 80002bca <argaddr>
    return -1;
    80005dba:	57fd                	li	a5,-1
  if (argaddr(1, &length) < 0)
    80005dbc:	0e054963          	bltz	a0,80005eae <sys_mmap+0x134>
  if (argint(2, &prot) < 0)
    80005dc0:	fc440593          	addi	a1,s0,-60
    80005dc4:	4509                	li	a0,2
    80005dc6:	ffffd097          	auipc	ra,0xffffd
    80005dca:	de2080e7          	jalr	-542(ra) # 80002ba8 <argint>
    return -1;
    80005dce:	57fd                	li	a5,-1
  if (argint(2, &prot) < 0)
    80005dd0:	0c054f63          	bltz	a0,80005eae <sys_mmap+0x134>
  if (argint(3, &flags) < 0)
    80005dd4:	fc040593          	addi	a1,s0,-64
    80005dd8:	450d                	li	a0,3
    80005dda:	ffffd097          	auipc	ra,0xffffd
    80005dde:	dce080e7          	jalr	-562(ra) # 80002ba8 <argint>
    return -1;
    80005de2:	57fd                	li	a5,-1
  if (argint(3, &flags) < 0)
    80005de4:	0c054563          	bltz	a0,80005eae <sys_mmap+0x134>
  if (argfd(4, 0, &f) < 0)
    80005de8:	fb840613          	addi	a2,s0,-72
    80005dec:	4581                	li	a1,0
    80005dee:	4511                	li	a0,4
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	270080e7          	jalr	624(ra) # 80005060 <argfd>
    return -1;
    80005df8:	57fd                	li	a5,-1
  if (argfd(4, 0, &f) < 0)
    80005dfa:	0a054a63          	bltz	a0,80005eae <sys_mmap+0x134>
  if (argaddr(5, &offset) < 0)
    80005dfe:	fc840593          	addi	a1,s0,-56
    80005e02:	4515                	li	a0,5
    80005e04:	ffffd097          	auipc	ra,0xffffd
    80005e08:	dc6080e7          	jalr	-570(ra) # 80002bca <argaddr>
    80005e0c:	0a054763          	bltz	a0,80005eba <sys_mmap+0x140>
    return -1;

  // check operation conflict
  if ((prot & PROT_WRITE) && !(f->writable) && !(flags & MAP_PRIVATE))
    80005e10:	fc442703          	lw	a4,-60(s0)
    80005e14:	00277793          	andi	a5,a4,2
    80005e18:	cb99                	beqz	a5,80005e2e <sys_mmap+0xb4>
    80005e1a:	fb843783          	ld	a5,-72(s0)
    80005e1e:	0097c783          	lbu	a5,9(a5)
    80005e22:	e791                	bnez	a5,80005e2e <sys_mmap+0xb4>
    80005e24:	fc042683          	lw	a3,-64(s0)
    80005e28:	8a89                	andi	a3,a3,2
    return -1;
    80005e2a:	57fd                	li	a5,-1
  if ((prot & PROT_WRITE) && !(f->writable) && !(flags & MAP_PRIVATE))
    80005e2c:	c2c9                	beqz	a3,80005eae <sys_mmap+0x134>
  if ((prot & PROT_READ) && !(f->readable))
    80005e2e:	8b05                	andi	a4,a4,1
    80005e30:	c719                	beqz	a4,80005e3e <sys_mmap+0xc4>
    80005e32:	fb843783          	ld	a5,-72(s0)
    80005e36:	0087c703          	lbu	a4,8(a5)
    return -1;
    80005e3a:	57fd                	li	a5,-1
  if ((prot & PROT_READ) && !(f->readable))
    80005e3c:	cb2d                	beqz	a4,80005eae <sys_mmap+0x134>

  struct VMA* vma = get_unused_vma();
    80005e3e:	00000097          	auipc	ra,0x0
    80005e42:	e70080e7          	jalr	-400(ra) # 80005cae <get_unused_vma>
    80005e46:	84aa                	mv	s1,a0
  if (0 == vma) // not enough vma
    80005e48:	c93d                	beqz	a0,80005ebe <sys_mmap+0x144>
    return -1;

  // add file reference
  filedup(f);
    80005e4a:	fb843503          	ld	a0,-72(s0)
    80005e4e:	ffffe097          	auipc	ra,0xffffe
    80005e52:	7aa080e7          	jalr	1962(ra) # 800045f8 <filedup>

  // init the vma
  vma->addr = get_vma_start_addr(length);
    80005e56:	fd043503          	ld	a0,-48(s0)
    80005e5a:	00000097          	auipc	ra,0x0
    80005e5e:	ef0080e7          	jalr	-272(ra) # 80005d4a <get_vma_start_addr>
    80005e62:	87aa                	mv	a5,a0
    80005e64:	e088                	sd	a0,0(s1)
  vma->length = length;
    80005e66:	fd043703          	ld	a4,-48(s0)
    80005e6a:	e498                	sd	a4,8(s1)
  vma->f = f;
    80005e6c:	fb843683          	ld	a3,-72(s0)
    80005e70:	f494                	sd	a3,40(s1)
  vma->flags = flags;
    80005e72:	fc042683          	lw	a3,-64(s0)
    80005e76:	c8d4                	sw	a3,20(s1)
  vma->prot = prot;
    80005e78:	fc442683          	lw	a3,-60(s0)
    80005e7c:	c894                	sw	a3,16(s1)
  vma->offset = offset;
    80005e7e:	fc843683          	ld	a3,-56(s0)
    80005e82:	cc94                	sw	a3,24(s1)
  vma->valid = 1;
    80005e84:	4685                	li	a3,1
    80005e86:	ccd4                	sw	a3,28(s1)

  int page_num = length / PGSIZE + ((length % PGSIZE == 0) ? 0 : 1);
    80005e88:	6605                	lui	a2,0x1
    80005e8a:	167d                	addi	a2,a2,-1
    80005e8c:	8e79                	and	a2,a2,a4
    80005e8e:	00c03633          	snez	a2,a2
    80005e92:	8331                	srli	a4,a4,0xc
    80005e94:	9e39                	addw	a2,a2,a4
  int mask = 1;
  for (int i = 0; i < page_num; i++) {
    80005e96:	00c05c63          	blez	a2,80005eae <sys_mmap+0x134>
    80005e9a:	708c                	ld	a1,32(s1)
    80005e9c:	4681                	li	a3,0
  int mask = 1;
    80005e9e:	4705                	li	a4,1
    vma->bitmap |= mask;
    80005ea0:	8dd9                	or	a1,a1,a4
    mask = mask << 1;
    80005ea2:	0017171b          	slliw	a4,a4,0x1
  for (int i = 0; i < page_num; i++) {
    80005ea6:	2685                	addiw	a3,a3,1
    80005ea8:	fed61ce3          	bne	a2,a3,80005ea0 <sys_mmap+0x126>
    80005eac:	f08c                	sd	a1,32(s1)
  }
  return vma->addr;
}
    80005eae:	853e                	mv	a0,a5
    80005eb0:	60a6                	ld	ra,72(sp)
    80005eb2:	6406                	ld	s0,64(sp)
    80005eb4:	74e2                	ld	s1,56(sp)
    80005eb6:	6161                	addi	sp,sp,80
    80005eb8:	8082                	ret
    return -1;
    80005eba:	57fd                	li	a5,-1
    80005ebc:	bfcd                	j	80005eae <sys_mmap+0x134>
    return -1;
    80005ebe:	57fd                	li	a5,-1
    80005ec0:	b7fd                	j	80005eae <sys_mmap+0x134>

0000000080005ec2 <clean_vma>:

uint64
clean_vma(struct VMA* vma, uint64 addr, uint64 length)
{
  int page_number = length / PGSIZE + ((length % PGSIZE == 0) ? 0 : 1);
    80005ec2:	6785                	lui	a5,0x1
    80005ec4:	17fd                	addi	a5,a5,-1
    80005ec6:	8ff1                	and	a5,a5,a2
    80005ec8:	00f037b3          	snez	a5,a5
    80005ecc:	8231                	srli	a2,a2,0xc
    80005ece:	9e3d                	addw	a2,a2,a5
  int start = (addr - vma->addr) / PGSIZE;
    80005ed0:	611c                	ld	a5,0(a0)
    80005ed2:	8d9d                	sub	a1,a1,a5
    80005ed4:	81b1                	srli	a1,a1,0xc
    80005ed6:	2581                	sext.w	a1,a1
  for (int i = start; i < page_number; i++) {
    80005ed8:	00c5de63          	ble	a2,a1,80005ef4 <clean_vma+0x32>
    80005edc:	7118                	ld	a4,32(a0)
    vma->bitmap = vma->bitmap & (~(1 << i));
    80005ede:	4685                	li	a3,1
    80005ee0:	00b697bb          	sllw	a5,a3,a1
    80005ee4:	fff7c793          	not	a5,a5
    80005ee8:	2781                	sext.w	a5,a5
    80005eea:	8f7d                	and	a4,a4,a5
  for (int i = start; i < page_number; i++) {
    80005eec:	2585                	addiw	a1,a1,1
    80005eee:	feb619e3          	bne	a2,a1,80005ee0 <clean_vma+0x1e>
    80005ef2:	f118                	sd	a4,32(a0)
  }
  if (0 == vma->bitmap) {
    80005ef4:	711c                	ld	a5,32(a0)
    80005ef6:	c399                	beqz	a5,80005efc <clean_vma+0x3a>
    fileclose(vma->f);
    memset((void*)vma, 0, sizeof (struct VMA));
  }
  return 0;
}
    80005ef8:	4501                	li	a0,0
    80005efa:	8082                	ret
{
    80005efc:	1101                	addi	sp,sp,-32
    80005efe:	ec06                	sd	ra,24(sp)
    80005f00:	e822                	sd	s0,16(sp)
    80005f02:	e426                	sd	s1,8(sp)
    80005f04:	1000                	addi	s0,sp,32
    80005f06:	84aa                	mv	s1,a0
    fileclose(vma->f);
    80005f08:	7508                	ld	a0,40(a0)
    80005f0a:	ffffe097          	auipc	ra,0xffffe
    80005f0e:	740080e7          	jalr	1856(ra) # 8000464a <fileclose>
    memset((void*)vma, 0, sizeof (struct VMA));
    80005f12:	03000613          	li	a2,48
    80005f16:	4581                	li	a1,0
    80005f18:	8526                	mv	a0,s1
    80005f1a:	ffffb097          	auipc	ra,0xffffb
    80005f1e:	e06080e7          	jalr	-506(ra) # 80000d20 <memset>
}
    80005f22:	4501                	li	a0,0
    80005f24:	60e2                	ld	ra,24(sp)
    80005f26:	6442                	ld	s0,16(sp)
    80005f28:	64a2                	ld	s1,8(sp)
    80005f2a:	6105                	addi	sp,sp,32
    80005f2c:	8082                	ret

0000000080005f2e <unmap_vma>:

uint64
unmap_vma(uint64 addr, uint64 length)
{
    80005f2e:	7139                	addi	sp,sp,-64
    80005f30:	fc06                	sd	ra,56(sp)
    80005f32:	f822                	sd	s0,48(sp)
    80005f34:	f426                	sd	s1,40(sp)
    80005f36:	f04a                	sd	s2,32(sp)
    80005f38:	ec4e                	sd	s3,24(sp)
    80005f3a:	e852                	sd	s4,16(sp)
    80005f3c:	e456                	sd	s5,8(sp)
    80005f3e:	e05a                	sd	s6,0(sp)
    80005f40:	0080                	addi	s0,sp,64
  struct VMA* vma = get_vma_by_address(addr);
    80005f42:	00000097          	auipc	ra,0x0
    80005f46:	db2080e7          	jalr	-590(ra) # 80005cf4 <get_vma_by_address>
  if (0 == vma)
    80005f4a:	cd21                	beqz	a0,80005fa2 <unmap_vma+0x74>
    80005f4c:	8aaa                	mv	s5,a0
    return -1;

  int total = sizeof (uint64);
  struct proc* proc = myproc();
    80005f4e:	ffffc097          	auipc	ra,0xffffc
    80005f52:	af0080e7          	jalr	-1296(ra) # 80001a3e <myproc>
    80005f56:	8b2a                	mv	s6,a0

  uint64 bitmap = vma->bitmap;
    80005f58:	020ab903          	ld	s2,32(s5)
    80005f5c:	4481                	li	s1,0
    80005f5e:	6a05                	lui	s4,0x1
  for (int i = 0; i < total; i++) {
    80005f60:	69a1                	lui	s3,0x8
    80005f62:	a00d                	j	80005f84 <unmap_vma+0x56>
    if ((bitmap & 1) != 0) {
      uint64 addr = vma->addr + PGSIZE * i;
    80005f64:	000ab583          	ld	a1,0(s5)
      uvmunmap(proc->pagetable, addr, 1, 0);
    80005f68:	4681                	li	a3,0
    80005f6a:	4605                	li	a2,1
    80005f6c:	95a6                	add	a1,a1,s1
    80005f6e:	050b3503          	ld	a0,80(s6)
    80005f72:	ffffb097          	auipc	ra,0xffffb
    80005f76:	358080e7          	jalr	856(ra) # 800012ca <uvmunmap>
      bitmap = (bitmap >> 1);
    80005f7a:	00195913          	srli	s2,s2,0x1
  for (int i = 0; i < total; i++) {
    80005f7e:	94d2                	add	s1,s1,s4
    80005f80:	01348663          	beq	s1,s3,80005f8c <unmap_vma+0x5e>
    if ((bitmap & 1) != 0) {
    80005f84:	00197793          	andi	a5,s2,1
    80005f88:	dbfd                	beqz	a5,80005f7e <unmap_vma+0x50>
    80005f8a:	bfe9                	j	80005f64 <unmap_vma+0x36>
    }
  }
  return 0;
    80005f8c:	4501                	li	a0,0
}
    80005f8e:	70e2                	ld	ra,56(sp)
    80005f90:	7442                	ld	s0,48(sp)
    80005f92:	74a2                	ld	s1,40(sp)
    80005f94:	7902                	ld	s2,32(sp)
    80005f96:	69e2                	ld	s3,24(sp)
    80005f98:	6a42                	ld	s4,16(sp)
    80005f9a:	6aa2                	ld	s5,8(sp)
    80005f9c:	6b02                	ld	s6,0(sp)
    80005f9e:	6121                	addi	sp,sp,64
    80005fa0:	8082                	ret
    return -1;
    80005fa2:	557d                	li	a0,-1
    80005fa4:	b7ed                	j	80005f8e <unmap_vma+0x60>

0000000080005fa6 <flush_content>:

uint64
flush_content(struct VMA* vma, uint64 addr, uint64 length)
{
    80005fa6:	715d                	addi	sp,sp,-80
    80005fa8:	e486                	sd	ra,72(sp)
    80005faa:	e0a2                	sd	s0,64(sp)
    80005fac:	fc26                	sd	s1,56(sp)
    80005fae:	f84a                	sd	s2,48(sp)
    80005fb0:	f44e                	sd	s3,40(sp)
    80005fb2:	f052                	sd	s4,32(sp)
    80005fb4:	ec56                	sd	s5,24(sp)
    80005fb6:	e85a                	sd	s6,16(sp)
    80005fb8:	e45e                	sd	s7,8(sp)
    80005fba:	0880                	addi	s0,sp,80
    80005fbc:	892a                	mv	s2,a0
    80005fbe:	8a2e                	mv	s4,a1
    80005fc0:	84b2                	mv	s1,a2
  struct proc* proc = myproc();
    80005fc2:	ffffc097          	auipc	ra,0xffffc
    80005fc6:	a7c080e7          	jalr	-1412(ra) # 80001a3e <myproc>
    80005fca:	8aaa                	mv	s5,a0
  int page_number = length / PGSIZE + ((length % PGSIZE == 0) ? 0 : 1);
    80005fcc:	6985                	lui	s3,0x1
    80005fce:	19fd                	addi	s3,s3,-1
    80005fd0:	0134f9b3          	and	s3,s1,s3
    80005fd4:	013039b3          	snez	s3,s3
    80005fd8:	80b1                	srli	s1,s1,0xc
    80005fda:	009989bb          	addw	s3,s3,s1
    80005fde:	00098b1b          	sext.w	s6,s3
  int start = (addr - vma->addr) / PGSIZE;
    80005fe2:	00093483          	ld	s1,0(s2)
    80005fe6:	409a04b3          	sub	s1,s4,s1
    80005fea:	80b1                	srli	s1,s1,0xc
    80005fec:	2481                	sext.w	s1,s1
  for (int i = start; i < page_number; i++) {
    80005fee:	0364d763          	ble	s6,s1,8000601c <flush_content+0x76>
    80005ff2:	00c4949b          	slliw	s1,s1,0xc
    80005ff6:	00c9999b          	slliw	s3,s3,0xc
    80005ffa:	6b85                	lui	s7,0x1
//    if (((vma->bitmap >> i) & 1) == 1) {
      vma->f->off = PGSIZE * i;
    80005ffc:	02893783          	ld	a5,40(s2)
    80006000:	d384                	sw	s1,32(a5)
      // write in memory content to file
      filewrite(vma->f, vma->addr, PGSIZE);
    80006002:	6605                	lui	a2,0x1
    80006004:	00093583          	ld	a1,0(s2)
    80006008:	02893503          	ld	a0,40(s2)
    8000600c:	fffff097          	auipc	ra,0xfffff
    80006010:	83a080e7          	jalr	-1990(ra) # 80004846 <filewrite>
  for (int i = start; i < page_number; i++) {
    80006014:	009b84bb          	addw	s1,s7,s1
    80006018:	ff3492e3          	bne	s1,s3,80005ffc <flush_content+0x56>
//      uvmunmap(proc->pagetable, addr + i * PGSIZE, 1, 1);
//    }
  }
  uvmunmap(proc->pagetable, addr, page_number, 1);
    8000601c:	4685                	li	a3,1
    8000601e:	865a                	mv	a2,s6
    80006020:	85d2                	mv	a1,s4
    80006022:	050ab503          	ld	a0,80(s5)
    80006026:	ffffb097          	auipc	ra,0xffffb
    8000602a:	2a4080e7          	jalr	676(ra) # 800012ca <uvmunmap>
  return 0;
}
    8000602e:	4501                	li	a0,0
    80006030:	60a6                	ld	ra,72(sp)
    80006032:	6406                	ld	s0,64(sp)
    80006034:	74e2                	ld	s1,56(sp)
    80006036:	7942                	ld	s2,48(sp)
    80006038:	79a2                	ld	s3,40(sp)
    8000603a:	7a02                	ld	s4,32(sp)
    8000603c:	6ae2                	ld	s5,24(sp)
    8000603e:	6b42                	ld	s6,16(sp)
    80006040:	6ba2                	ld	s7,8(sp)
    80006042:	6161                	addi	sp,sp,80
    80006044:	8082                	ret

0000000080006046 <sys_munmap_helper>:

uint64
sys_munmap_helper(uint64 addr, uint64 length)
{
    80006046:	7179                	addi	sp,sp,-48
    80006048:	f406                	sd	ra,40(sp)
    8000604a:	f022                	sd	s0,32(sp)
    8000604c:	ec26                	sd	s1,24(sp)
    8000604e:	e84a                	sd	s2,16(sp)
    80006050:	e44e                	sd	s3,8(sp)
    80006052:	1800                	addi	s0,sp,48
    80006054:	892a                	mv	s2,a0
    80006056:	89ae                	mv	s3,a1
  // get the address's vma
  struct VMA* vma = get_vma_by_address(addr);
    80006058:	00000097          	auipc	ra,0x0
    8000605c:	c9c080e7          	jalr	-868(ra) # 80005cf4 <get_vma_by_address>
  if (0 == vma)
    80006060:	c121                	beqz	a0,800060a0 <sys_munmap_helper+0x5a>
    80006062:	84aa                	mv	s1,a0
    return -1;

  // no need to write back
  if (vma->flags & MAP_PRIVATE) {
    80006064:	495c                	lw	a5,20(a0)
    80006066:	8b89                	andi	a5,a5,2
    80006068:	e78d                	bnez	a5,80006092 <sys_munmap_helper+0x4c>
    return clean_vma(vma, addr, length);
  }
  // we need to write in-memory content to file
  uint64 ret = flush_content(vma, addr, length);
    8000606a:	864e                	mv	a2,s3
    8000606c:	85ca                	mv	a1,s2
    8000606e:	00000097          	auipc	ra,0x0
    80006072:	f38080e7          	jalr	-200(ra) # 80005fa6 <flush_content>
  if (ret < 0)
    return ret;

  return clean_vma(vma, addr, length);
    80006076:	864e                	mv	a2,s3
    80006078:	85ca                	mv	a1,s2
    8000607a:	8526                	mv	a0,s1
    8000607c:	00000097          	auipc	ra,0x0
    80006080:	e46080e7          	jalr	-442(ra) # 80005ec2 <clean_vma>
}
    80006084:	70a2                	ld	ra,40(sp)
    80006086:	7402                	ld	s0,32(sp)
    80006088:	64e2                	ld	s1,24(sp)
    8000608a:	6942                	ld	s2,16(sp)
    8000608c:	69a2                	ld	s3,8(sp)
    8000608e:	6145                	addi	sp,sp,48
    80006090:	8082                	ret
    return clean_vma(vma, addr, length);
    80006092:	864e                	mv	a2,s3
    80006094:	85ca                	mv	a1,s2
    80006096:	00000097          	auipc	ra,0x0
    8000609a:	e2c080e7          	jalr	-468(ra) # 80005ec2 <clean_vma>
    8000609e:	b7dd                	j	80006084 <sys_munmap_helper+0x3e>
    return -1;
    800060a0:	557d                	li	a0,-1
    800060a2:	b7cd                	j	80006084 <sys_munmap_helper+0x3e>

00000000800060a4 <sys_munmap>:


uint64
sys_munmap()
{
    800060a4:	1101                	addi	sp,sp,-32
    800060a6:	ec06                	sd	ra,24(sp)
    800060a8:	e822                	sd	s0,16(sp)
    800060aa:	1000                	addi	s0,sp,32
  uint64 addr = 0, length = 0;
    800060ac:	fe043423          	sd	zero,-24(s0)
    800060b0:	fe043023          	sd	zero,-32(s0)
  if (argaddr(0, &addr) < 0)
    800060b4:	fe840593          	addi	a1,s0,-24
    800060b8:	4501                	li	a0,0
    800060ba:	ffffd097          	auipc	ra,0xffffd
    800060be:	b10080e7          	jalr	-1264(ra) # 80002bca <argaddr>
    return -1;
    800060c2:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0)
    800060c4:	02054563          	bltz	a0,800060ee <sys_munmap+0x4a>
  if (argaddr(1, &length) < 0)
    800060c8:	fe040593          	addi	a1,s0,-32
    800060cc:	4505                	li	a0,1
    800060ce:	ffffd097          	auipc	ra,0xffffd
    800060d2:	afc080e7          	jalr	-1284(ra) # 80002bca <argaddr>
    return -1;
    800060d6:	57fd                	li	a5,-1
  if (argaddr(1, &length) < 0)
    800060d8:	00054b63          	bltz	a0,800060ee <sys_munmap+0x4a>

  return sys_munmap_helper(addr, length);
    800060dc:	fe043583          	ld	a1,-32(s0)
    800060e0:	fe843503          	ld	a0,-24(s0)
    800060e4:	00000097          	auipc	ra,0x0
    800060e8:	f62080e7          	jalr	-158(ra) # 80006046 <sys_munmap_helper>
    800060ec:	87aa                	mv	a5,a0
}
    800060ee:	853e                	mv	a0,a5
    800060f0:	60e2                	ld	ra,24(sp)
    800060f2:	6442                	ld	s0,16(sp)
    800060f4:	6105                	addi	sp,sp,32
    800060f6:	8082                	ret

00000000800060f8 <handle_mmap_page_fault>:


uint64
handle_mmap_page_fault(uint64 scause, uint64 va)
{
    800060f8:	7179                	addi	sp,sp,-48
    800060fa:	f406                	sd	ra,40(sp)
    800060fc:	f022                	sd	s0,32(sp)
    800060fe:	ec26                	sd	s1,24(sp)
    80006100:	e84a                	sd	s2,16(sp)
    80006102:	e44e                	sd	s3,8(sp)
    80006104:	1800                	addi	s0,sp,48
    80006106:	89aa                	mv	s3,a0
    80006108:	892e                	mv	s2,a1
  struct VMA* vma = get_vma_by_address(va);
    8000610a:	852e                	mv	a0,a1
    8000610c:	00000097          	auipc	ra,0x0
    80006110:	be8080e7          	jalr	-1048(ra) # 80005cf4 <get_vma_by_address>
  if (0 == vma)
    80006114:	c969                	beqz	a0,800061e6 <handle_mmap_page_fault+0xee>
    80006116:	84aa                	mv	s1,a0
    return -1;

  // write
  if (scause == 15 && (!(vma->prot & PROT_WRITE)))
    80006118:	47bd                	li	a5,15
    8000611a:	0af98a63          	beq	s3,a5,800061ce <handle_mmap_page_fault+0xd6>
    return -1;
  if (scause == 13 && (!(vma->prot & PROT_READ)))
    8000611e:	47b5                	li	a5,13
    80006120:	00f99663          	bne	s3,a5,8000612c <handle_mmap_page_fault+0x34>
    80006124:	491c                	lw	a5,16(a0)
    80006126:	8b85                	andi	a5,a5,1
    return -1;
    80006128:	557d                	li	a0,-1
  if (scause == 13 && (!(vma->prot & PROT_READ)))
    8000612a:	cbd9                	beqz	a5,800061c0 <handle_mmap_page_fault+0xc8>

  // allocate new physical address
  void* pa = kalloc();
    8000612c:	ffffb097          	auipc	ra,0xffffb
    80006130:	a08080e7          	jalr	-1528(ra) # 80000b34 <kalloc>
    80006134:	89aa                	mv	s3,a0
  if (0 == kalloc())
    80006136:	ffffb097          	auipc	ra,0xffffb
    8000613a:	9fe080e7          	jalr	-1538(ra) # 80000b34 <kalloc>
    8000613e:	c555                	beqz	a0,800061ea <handle_mmap_page_fault+0xf2>
    return -1;
  memset(pa, 0, PGSIZE);
    80006140:	6605                	lui	a2,0x1
    80006142:	4581                	li	a1,0
    80006144:	854e                	mv	a0,s3
    80006146:	ffffb097          	auipc	ra,0xffffb
    8000614a:	bda080e7          	jalr	-1062(ra) # 80000d20 <memset>

  struct proc* p = myproc();
    8000614e:	ffffc097          	auipc	ra,0xffffc
    80006152:	8f0080e7          	jalr	-1808(ra) # 80001a3e <myproc>
  // set pages permission
  int flag = 0;
  if (vma->prot & PROT_WRITE)
    80006156:	489c                	lw	a5,16(s1)
    80006158:	0027f713          	andi	a4,a5,2
    8000615c:	2701                	sext.w	a4,a4
    8000615e:	c311                	beqz	a4,80006162 <handle_mmap_page_fault+0x6a>
    flag |= PTE_W;
    80006160:	4711                	li	a4,4
  if (vma->prot & PROT_READ)
    80006162:	8b85                	andi	a5,a5,1
    80006164:	c399                	beqz	a5,8000616a <handle_mmap_page_fault+0x72>
    flag |= PTE_R;
    80006166:	00276713          	ori	a4,a4,2
  flag |= PTE_U;
  flag |= PTE_X;

  // page align
  va = PGROUNDDOWN(va);
    8000616a:	76fd                	lui	a3,0xfffff
    8000616c:	00d97933          	and	s2,s2,a3
  // map the virtual address and physical address
  if (mappages(p->pagetable, va, PGSIZE, (uint64)pa, flag) < 0) {
    80006170:	01876713          	ori	a4,a4,24
    80006174:	86ce                	mv	a3,s3
    80006176:	6605                	lui	a2,0x1
    80006178:	85ca                	mv	a1,s2
    8000617a:	6928                	ld	a0,80(a0)
    8000617c:	ffffb097          	auipc	ra,0xffffb
    80006180:	f9c080e7          	jalr	-100(ra) # 80001118 <mappages>
    80006184:	04054a63          	bltz	a0,800061d8 <handle_mmap_page_fault+0xe0>
    kfree(pa);
    return -1;
  }

  // read file content to memory
  ilock(vma->f->ip);
    80006188:	749c                	ld	a5,40(s1)
    8000618a:	6f88                	ld	a0,24(a5)
    8000618c:	ffffd097          	auipc	ra,0xffffd
    80006190:	5dc080e7          	jalr	1500(ra) # 80003768 <ilock>
  readi(vma->f->ip, 0, (uint64)pa, vma->offset + va - vma->addr, PGSIZE);
    80006194:	4c94                	lw	a3,24(s1)
    80006196:	0126893b          	addw	s2,a3,s2
    8000619a:	6094                	ld	a3,0(s1)
    8000619c:	749c                	ld	a5,40(s1)
    8000619e:	6705                	lui	a4,0x1
    800061a0:	40d906bb          	subw	a3,s2,a3
    800061a4:	864e                	mv	a2,s3
    800061a6:	4581                	li	a1,0
    800061a8:	6f88                	ld	a0,24(a5)
    800061aa:	ffffe097          	auipc	ra,0xffffe
    800061ae:	874080e7          	jalr	-1932(ra) # 80003a1e <readi>
  iunlock(vma->f->ip);
    800061b2:	749c                	ld	a5,40(s1)
    800061b4:	6f88                	ld	a0,24(a5)
    800061b6:	ffffd097          	auipc	ra,0xffffd
    800061ba:	676080e7          	jalr	1654(ra) # 8000382c <iunlock>
  return 0;
    800061be:	4501                	li	a0,0
}
    800061c0:	70a2                	ld	ra,40(sp)
    800061c2:	7402                	ld	s0,32(sp)
    800061c4:	64e2                	ld	s1,24(sp)
    800061c6:	6942                	ld	s2,16(sp)
    800061c8:	69a2                	ld	s3,8(sp)
    800061ca:	6145                	addi	sp,sp,48
    800061cc:	8082                	ret
  if (scause == 15 && (!(vma->prot & PROT_WRITE)))
    800061ce:	491c                	lw	a5,16(a0)
    800061d0:	8b89                	andi	a5,a5,2
    return -1;
    800061d2:	557d                	li	a0,-1
  if (scause == 15 && (!(vma->prot & PROT_WRITE)))
    800061d4:	ffa1                	bnez	a5,8000612c <handle_mmap_page_fault+0x34>
    800061d6:	b7ed                	j	800061c0 <handle_mmap_page_fault+0xc8>
    kfree(pa);
    800061d8:	854e                	mv	a0,s3
    800061da:	ffffb097          	auipc	ra,0xffffb
    800061de:	85a080e7          	jalr	-1958(ra) # 80000a34 <kfree>
    return -1;
    800061e2:	557d                	li	a0,-1
    800061e4:	bff1                	j	800061c0 <handle_mmap_page_fault+0xc8>
    return -1;
    800061e6:	557d                	li	a0,-1
    800061e8:	bfe1                	j	800061c0 <handle_mmap_page_fault+0xc8>
    return -1;
    800061ea:	557d                	li	a0,-1
    800061ec:	bfd1                	j	800061c0 <handle_mmap_page_fault+0xc8>
	...

00000000800061f0 <kernelvec>:
    800061f0:	7111                	addi	sp,sp,-256
    800061f2:	e006                	sd	ra,0(sp)
    800061f4:	e40a                	sd	sp,8(sp)
    800061f6:	e80e                	sd	gp,16(sp)
    800061f8:	ec12                	sd	tp,24(sp)
    800061fa:	f016                	sd	t0,32(sp)
    800061fc:	f41a                	sd	t1,40(sp)
    800061fe:	f81e                	sd	t2,48(sp)
    80006200:	fc22                	sd	s0,56(sp)
    80006202:	e0a6                	sd	s1,64(sp)
    80006204:	e4aa                	sd	a0,72(sp)
    80006206:	e8ae                	sd	a1,80(sp)
    80006208:	ecb2                	sd	a2,88(sp)
    8000620a:	f0b6                	sd	a3,96(sp)
    8000620c:	f4ba                	sd	a4,104(sp)
    8000620e:	f8be                	sd	a5,112(sp)
    80006210:	fcc2                	sd	a6,120(sp)
    80006212:	e146                	sd	a7,128(sp)
    80006214:	e54a                	sd	s2,136(sp)
    80006216:	e94e                	sd	s3,144(sp)
    80006218:	ed52                	sd	s4,152(sp)
    8000621a:	f156                	sd	s5,160(sp)
    8000621c:	f55a                	sd	s6,168(sp)
    8000621e:	f95e                	sd	s7,176(sp)
    80006220:	fd62                	sd	s8,184(sp)
    80006222:	e1e6                	sd	s9,192(sp)
    80006224:	e5ea                	sd	s10,200(sp)
    80006226:	e9ee                	sd	s11,208(sp)
    80006228:	edf2                	sd	t3,216(sp)
    8000622a:	f1f6                	sd	t4,224(sp)
    8000622c:	f5fa                	sd	t5,232(sp)
    8000622e:	f9fe                	sd	t6,240(sp)
    80006230:	fa4fc0ef          	jal	ra,800029d4 <kerneltrap>
    80006234:	6082                	ld	ra,0(sp)
    80006236:	6122                	ld	sp,8(sp)
    80006238:	61c2                	ld	gp,16(sp)
    8000623a:	7282                	ld	t0,32(sp)
    8000623c:	7322                	ld	t1,40(sp)
    8000623e:	73c2                	ld	t2,48(sp)
    80006240:	7462                	ld	s0,56(sp)
    80006242:	6486                	ld	s1,64(sp)
    80006244:	6526                	ld	a0,72(sp)
    80006246:	65c6                	ld	a1,80(sp)
    80006248:	6666                	ld	a2,88(sp)
    8000624a:	7686                	ld	a3,96(sp)
    8000624c:	7726                	ld	a4,104(sp)
    8000624e:	77c6                	ld	a5,112(sp)
    80006250:	7866                	ld	a6,120(sp)
    80006252:	688a                	ld	a7,128(sp)
    80006254:	692a                	ld	s2,136(sp)
    80006256:	69ca                	ld	s3,144(sp)
    80006258:	6a6a                	ld	s4,152(sp)
    8000625a:	7a8a                	ld	s5,160(sp)
    8000625c:	7b2a                	ld	s6,168(sp)
    8000625e:	7bca                	ld	s7,176(sp)
    80006260:	7c6a                	ld	s8,184(sp)
    80006262:	6c8e                	ld	s9,192(sp)
    80006264:	6d2e                	ld	s10,200(sp)
    80006266:	6dce                	ld	s11,208(sp)
    80006268:	6e6e                	ld	t3,216(sp)
    8000626a:	7e8e                	ld	t4,224(sp)
    8000626c:	7f2e                	ld	t5,232(sp)
    8000626e:	7fce                	ld	t6,240(sp)
    80006270:	6111                	addi	sp,sp,256
    80006272:	10200073          	sret
    80006276:	00000013          	nop
    8000627a:	00000013          	nop
    8000627e:	0001                	nop

0000000080006280 <timervec>:
    80006280:	34051573          	csrrw	a0,mscratch,a0
    80006284:	e10c                	sd	a1,0(a0)
    80006286:	e510                	sd	a2,8(a0)
    80006288:	e914                	sd	a3,16(a0)
    8000628a:	6d0c                	ld	a1,24(a0)
    8000628c:	7110                	ld	a2,32(a0)
    8000628e:	6194                	ld	a3,0(a1)
    80006290:	96b2                	add	a3,a3,a2
    80006292:	e194                	sd	a3,0(a1)
    80006294:	4589                	li	a1,2
    80006296:	14459073          	csrw	sip,a1
    8000629a:	6914                	ld	a3,16(a0)
    8000629c:	6510                	ld	a2,8(a0)
    8000629e:	610c                	ld	a1,0(a0)
    800062a0:	34051573          	csrrw	a0,mscratch,a0
    800062a4:	30200073          	mret
	...

00000000800062aa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062aa:	1141                	addi	sp,sp,-16
    800062ac:	e422                	sd	s0,8(sp)
    800062ae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800062b0:	0c0007b7          	lui	a5,0xc000
    800062b4:	4705                	li	a4,1
    800062b6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800062b8:	c3d8                	sw	a4,4(a5)
}
    800062ba:	6422                	ld	s0,8(sp)
    800062bc:	0141                	addi	sp,sp,16
    800062be:	8082                	ret

00000000800062c0 <plicinithart>:

void
plicinithart(void)
{
    800062c0:	1141                	addi	sp,sp,-16
    800062c2:	e406                	sd	ra,8(sp)
    800062c4:	e022                	sd	s0,0(sp)
    800062c6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800062c8:	ffffb097          	auipc	ra,0xffffb
    800062cc:	74a080e7          	jalr	1866(ra) # 80001a12 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800062d0:	0085171b          	slliw	a4,a0,0x8
    800062d4:	0c0027b7          	lui	a5,0xc002
    800062d8:	97ba                	add	a5,a5,a4
    800062da:	40200713          	li	a4,1026
    800062de:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800062e2:	00d5151b          	slliw	a0,a0,0xd
    800062e6:	0c2017b7          	lui	a5,0xc201
    800062ea:	953e                	add	a0,a0,a5
    800062ec:	00052023          	sw	zero,0(a0)
}
    800062f0:	60a2                	ld	ra,8(sp)
    800062f2:	6402                	ld	s0,0(sp)
    800062f4:	0141                	addi	sp,sp,16
    800062f6:	8082                	ret

00000000800062f8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800062f8:	1141                	addi	sp,sp,-16
    800062fa:	e406                	sd	ra,8(sp)
    800062fc:	e022                	sd	s0,0(sp)
    800062fe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006300:	ffffb097          	auipc	ra,0xffffb
    80006304:	712080e7          	jalr	1810(ra) # 80001a12 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006308:	00d5151b          	slliw	a0,a0,0xd
    8000630c:	0c2017b7          	lui	a5,0xc201
    80006310:	97aa                	add	a5,a5,a0
  return irq;
}
    80006312:	43c8                	lw	a0,4(a5)
    80006314:	60a2                	ld	ra,8(sp)
    80006316:	6402                	ld	s0,0(sp)
    80006318:	0141                	addi	sp,sp,16
    8000631a:	8082                	ret

000000008000631c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000631c:	1101                	addi	sp,sp,-32
    8000631e:	ec06                	sd	ra,24(sp)
    80006320:	e822                	sd	s0,16(sp)
    80006322:	e426                	sd	s1,8(sp)
    80006324:	1000                	addi	s0,sp,32
    80006326:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006328:	ffffb097          	auipc	ra,0xffffb
    8000632c:	6ea080e7          	jalr	1770(ra) # 80001a12 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006330:	00d5151b          	slliw	a0,a0,0xd
    80006334:	0c2017b7          	lui	a5,0xc201
    80006338:	97aa                	add	a5,a5,a0
    8000633a:	c3c4                	sw	s1,4(a5)
}
    8000633c:	60e2                	ld	ra,24(sp)
    8000633e:	6442                	ld	s0,16(sp)
    80006340:	64a2                	ld	s1,8(sp)
    80006342:	6105                	addi	sp,sp,32
    80006344:	8082                	ret

0000000080006346 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006346:	1141                	addi	sp,sp,-16
    80006348:	e406                	sd	ra,8(sp)
    8000634a:	e022                	sd	s0,0(sp)
    8000634c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000634e:	479d                	li	a5,7
    80006350:	06a7c963          	blt	a5,a0,800063c2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006354:	00029797          	auipc	a5,0x29
    80006358:	cac78793          	addi	a5,a5,-852 # 8002f000 <disk>
    8000635c:	00a78733          	add	a4,a5,a0
    80006360:	6789                	lui	a5,0x2
    80006362:	97ba                	add	a5,a5,a4
    80006364:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006368:	e7ad                	bnez	a5,800063d2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000636a:	00451793          	slli	a5,a0,0x4
    8000636e:	0002b717          	auipc	a4,0x2b
    80006372:	c9270713          	addi	a4,a4,-878 # 80031000 <disk+0x2000>
    80006376:	6314                	ld	a3,0(a4)
    80006378:	96be                	add	a3,a3,a5
    8000637a:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffcd000>
  disk.desc[i].len = 0;
    8000637e:	6314                	ld	a3,0(a4)
    80006380:	96be                	add	a3,a3,a5
    80006382:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006386:	6314                	ld	a3,0(a4)
    80006388:	96be                	add	a3,a3,a5
    8000638a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000638e:	6318                	ld	a4,0(a4)
    80006390:	97ba                	add	a5,a5,a4
    80006392:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006396:	00029797          	auipc	a5,0x29
    8000639a:	c6a78793          	addi	a5,a5,-918 # 8002f000 <disk>
    8000639e:	97aa                	add	a5,a5,a0
    800063a0:	6509                	lui	a0,0x2
    800063a2:	953e                	add	a0,a0,a5
    800063a4:	4785                	li	a5,1
    800063a6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800063aa:	0002b517          	auipc	a0,0x2b
    800063ae:	c6e50513          	addi	a0,a0,-914 # 80031018 <disk+0x2018>
    800063b2:	ffffc097          	auipc	ra,0xffffc
    800063b6:	094080e7          	jalr	148(ra) # 80002446 <wakeup>
}
    800063ba:	60a2                	ld	ra,8(sp)
    800063bc:	6402                	ld	s0,0(sp)
    800063be:	0141                	addi	sp,sp,16
    800063c0:	8082                	ret
    panic("free_desc 1");
    800063c2:	00002517          	auipc	a0,0x2
    800063c6:	35650513          	addi	a0,a0,854 # 80008718 <syscalls+0x358>
    800063ca:	ffffa097          	auipc	ra,0xffffa
    800063ce:	18e080e7          	jalr	398(ra) # 80000558 <panic>
    panic("free_desc 2");
    800063d2:	00002517          	auipc	a0,0x2
    800063d6:	35650513          	addi	a0,a0,854 # 80008728 <syscalls+0x368>
    800063da:	ffffa097          	auipc	ra,0xffffa
    800063de:	17e080e7          	jalr	382(ra) # 80000558 <panic>

00000000800063e2 <virtio_disk_init>:
{
    800063e2:	1101                	addi	sp,sp,-32
    800063e4:	ec06                	sd	ra,24(sp)
    800063e6:	e822                	sd	s0,16(sp)
    800063e8:	e426                	sd	s1,8(sp)
    800063ea:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800063ec:	00002597          	auipc	a1,0x2
    800063f0:	34c58593          	addi	a1,a1,844 # 80008738 <syscalls+0x378>
    800063f4:	0002b517          	auipc	a0,0x2b
    800063f8:	d3450513          	addi	a0,a0,-716 # 80031128 <disk+0x2128>
    800063fc:	ffffa097          	auipc	ra,0xffffa
    80006400:	798080e7          	jalr	1944(ra) # 80000b94 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006404:	100017b7          	lui	a5,0x10001
    80006408:	4398                	lw	a4,0(a5)
    8000640a:	2701                	sext.w	a4,a4
    8000640c:	747277b7          	lui	a5,0x74727
    80006410:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006414:	0ef71163          	bne	a4,a5,800064f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006418:	100017b7          	lui	a5,0x10001
    8000641c:	43dc                	lw	a5,4(a5)
    8000641e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006420:	4705                	li	a4,1
    80006422:	0ce79a63          	bne	a5,a4,800064f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006426:	100017b7          	lui	a5,0x10001
    8000642a:	479c                	lw	a5,8(a5)
    8000642c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000642e:	4709                	li	a4,2
    80006430:	0ce79363          	bne	a5,a4,800064f6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006434:	100017b7          	lui	a5,0x10001
    80006438:	47d8                	lw	a4,12(a5)
    8000643a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000643c:	554d47b7          	lui	a5,0x554d4
    80006440:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006444:	0af71963          	bne	a4,a5,800064f6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006448:	100017b7          	lui	a5,0x10001
    8000644c:	4705                	li	a4,1
    8000644e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006450:	470d                	li	a4,3
    80006452:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006454:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006456:	c7ffe737          	lui	a4,0xc7ffe
    8000645a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcc75f>
    8000645e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006460:	2701                	sext.w	a4,a4
    80006462:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006464:	472d                	li	a4,11
    80006466:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006468:	473d                	li	a4,15
    8000646a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000646c:	6705                	lui	a4,0x1
    8000646e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006470:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006474:	5bdc                	lw	a5,52(a5)
    80006476:	2781                	sext.w	a5,a5
  if(max == 0)
    80006478:	c7d9                	beqz	a5,80006506 <virtio_disk_init+0x124>
  if(max < NUM)
    8000647a:	471d                	li	a4,7
    8000647c:	08f77d63          	bleu	a5,a4,80006516 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006480:	100014b7          	lui	s1,0x10001
    80006484:	47a1                	li	a5,8
    80006486:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006488:	6609                	lui	a2,0x2
    8000648a:	4581                	li	a1,0
    8000648c:	00029517          	auipc	a0,0x29
    80006490:	b7450513          	addi	a0,a0,-1164 # 8002f000 <disk>
    80006494:	ffffb097          	auipc	ra,0xffffb
    80006498:	88c080e7          	jalr	-1908(ra) # 80000d20 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000649c:	00029717          	auipc	a4,0x29
    800064a0:	b6470713          	addi	a4,a4,-1180 # 8002f000 <disk>
    800064a4:	00c75793          	srli	a5,a4,0xc
    800064a8:	2781                	sext.w	a5,a5
    800064aa:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800064ac:	0002b797          	auipc	a5,0x2b
    800064b0:	b5478793          	addi	a5,a5,-1196 # 80031000 <disk+0x2000>
    800064b4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800064b6:	00029717          	auipc	a4,0x29
    800064ba:	bca70713          	addi	a4,a4,-1078 # 8002f080 <disk+0x80>
    800064be:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800064c0:	0002a717          	auipc	a4,0x2a
    800064c4:	b4070713          	addi	a4,a4,-1216 # 80030000 <disk+0x1000>
    800064c8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800064ca:	4705                	li	a4,1
    800064cc:	00e78c23          	sb	a4,24(a5)
    800064d0:	00e78ca3          	sb	a4,25(a5)
    800064d4:	00e78d23          	sb	a4,26(a5)
    800064d8:	00e78da3          	sb	a4,27(a5)
    800064dc:	00e78e23          	sb	a4,28(a5)
    800064e0:	00e78ea3          	sb	a4,29(a5)
    800064e4:	00e78f23          	sb	a4,30(a5)
    800064e8:	00e78fa3          	sb	a4,31(a5)
}
    800064ec:	60e2                	ld	ra,24(sp)
    800064ee:	6442                	ld	s0,16(sp)
    800064f0:	64a2                	ld	s1,8(sp)
    800064f2:	6105                	addi	sp,sp,32
    800064f4:	8082                	ret
    panic("could not find virtio disk");
    800064f6:	00002517          	auipc	a0,0x2
    800064fa:	25250513          	addi	a0,a0,594 # 80008748 <syscalls+0x388>
    800064fe:	ffffa097          	auipc	ra,0xffffa
    80006502:	05a080e7          	jalr	90(ra) # 80000558 <panic>
    panic("virtio disk has no queue 0");
    80006506:	00002517          	auipc	a0,0x2
    8000650a:	26250513          	addi	a0,a0,610 # 80008768 <syscalls+0x3a8>
    8000650e:	ffffa097          	auipc	ra,0xffffa
    80006512:	04a080e7          	jalr	74(ra) # 80000558 <panic>
    panic("virtio disk max queue too short");
    80006516:	00002517          	auipc	a0,0x2
    8000651a:	27250513          	addi	a0,a0,626 # 80008788 <syscalls+0x3c8>
    8000651e:	ffffa097          	auipc	ra,0xffffa
    80006522:	03a080e7          	jalr	58(ra) # 80000558 <panic>

0000000080006526 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006526:	711d                	addi	sp,sp,-96
    80006528:	ec86                	sd	ra,88(sp)
    8000652a:	e8a2                	sd	s0,80(sp)
    8000652c:	e4a6                	sd	s1,72(sp)
    8000652e:	e0ca                	sd	s2,64(sp)
    80006530:	fc4e                	sd	s3,56(sp)
    80006532:	f852                	sd	s4,48(sp)
    80006534:	f456                	sd	s5,40(sp)
    80006536:	f05a                	sd	s6,32(sp)
    80006538:	ec5e                	sd	s7,24(sp)
    8000653a:	e862                	sd	s8,16(sp)
    8000653c:	1080                	addi	s0,sp,96
    8000653e:	892a                	mv	s2,a0
    80006540:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006542:	00c52b83          	lw	s7,12(a0)
    80006546:	001b9b9b          	slliw	s7,s7,0x1
    8000654a:	1b82                	slli	s7,s7,0x20
    8000654c:	020bdb93          	srli	s7,s7,0x20

  acquire(&disk.vdisk_lock);
    80006550:	0002b517          	auipc	a0,0x2b
    80006554:	bd850513          	addi	a0,a0,-1064 # 80031128 <disk+0x2128>
    80006558:	ffffa097          	auipc	ra,0xffffa
    8000655c:	6cc080e7          	jalr	1740(ra) # 80000c24 <acquire>
    if(disk.free[i]){
    80006560:	0002b997          	auipc	s3,0x2b
    80006564:	aa098993          	addi	s3,s3,-1376 # 80031000 <disk+0x2000>
  for(int i = 0; i < NUM; i++){
    80006568:	4b21                	li	s6,8
      disk.free[i] = 0;
    8000656a:	00029a97          	auipc	s5,0x29
    8000656e:	a96a8a93          	addi	s5,s5,-1386 # 8002f000 <disk>
  for(int i = 0; i < 3; i++){
    80006572:	4a0d                	li	s4,3
    80006574:	a079                	j	80006602 <virtio_disk_rw+0xdc>
      disk.free[i] = 0;
    80006576:	00fa86b3          	add	a3,s5,a5
    8000657a:	96ae                	add	a3,a3,a1
    8000657c:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006580:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006582:	0207ca63          	bltz	a5,800065b6 <virtio_disk_rw+0x90>
  for(int i = 0; i < 3; i++){
    80006586:	2485                	addiw	s1,s1,1
    80006588:	0711                	addi	a4,a4,4
    8000658a:	25448b63          	beq	s1,s4,800067e0 <virtio_disk_rw+0x2ba>
    idx[i] = alloc_desc();
    8000658e:	863a                	mv	a2,a4
    if(disk.free[i]){
    80006590:	0189c783          	lbu	a5,24(s3)
    80006594:	26079e63          	bnez	a5,80006810 <virtio_disk_rw+0x2ea>
    80006598:	0002b697          	auipc	a3,0x2b
    8000659c:	a8168693          	addi	a3,a3,-1407 # 80031019 <disk+0x2019>
  for(int i = 0; i < NUM; i++){
    800065a0:	87aa                	mv	a5,a0
    if(disk.free[i]){
    800065a2:	0006c803          	lbu	a6,0(a3)
    800065a6:	fc0818e3          	bnez	a6,80006576 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    800065aa:	2785                	addiw	a5,a5,1
    800065ac:	0685                	addi	a3,a3,1
    800065ae:	ff679ae3          	bne	a5,s6,800065a2 <virtio_disk_rw+0x7c>
    idx[i] = alloc_desc();
    800065b2:	57fd                	li	a5,-1
    800065b4:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800065b6:	02905a63          	blez	s1,800065ea <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800065ba:	fa042503          	lw	a0,-96(s0)
    800065be:	00000097          	auipc	ra,0x0
    800065c2:	d88080e7          	jalr	-632(ra) # 80006346 <free_desc>
      for(int j = 0; j < i; j++)
    800065c6:	4785                	li	a5,1
    800065c8:	0297d163          	ble	s1,a5,800065ea <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800065cc:	fa442503          	lw	a0,-92(s0)
    800065d0:	00000097          	auipc	ra,0x0
    800065d4:	d76080e7          	jalr	-650(ra) # 80006346 <free_desc>
      for(int j = 0; j < i; j++)
    800065d8:	4789                	li	a5,2
    800065da:	0097d863          	ble	s1,a5,800065ea <virtio_disk_rw+0xc4>
        free_desc(idx[j]);
    800065de:	fa842503          	lw	a0,-88(s0)
    800065e2:	00000097          	auipc	ra,0x0
    800065e6:	d64080e7          	jalr	-668(ra) # 80006346 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065ea:	0002b597          	auipc	a1,0x2b
    800065ee:	b3e58593          	addi	a1,a1,-1218 # 80031128 <disk+0x2128>
    800065f2:	0002b517          	auipc	a0,0x2b
    800065f6:	a2650513          	addi	a0,a0,-1498 # 80031018 <disk+0x2018>
    800065fa:	ffffc097          	auipc	ra,0xffffc
    800065fe:	cc6080e7          	jalr	-826(ra) # 800022c0 <sleep>
  for(int i = 0; i < 3; i++){
    80006602:	fa040713          	addi	a4,s0,-96
    80006606:	4481                	li	s1,0
  for(int i = 0; i < NUM; i++){
    80006608:	4505                	li	a0,1
      disk.free[i] = 0;
    8000660a:	6589                	lui	a1,0x2
    8000660c:	b749                	j	8000658e <virtio_disk_rw+0x68>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    8000660e:	20058793          	addi	a5,a1,512 # 2200 <_entry-0x7fffde00>
    80006612:	00479613          	slli	a2,a5,0x4
    80006616:	00029797          	auipc	a5,0x29
    8000661a:	9ea78793          	addi	a5,a5,-1558 # 8002f000 <disk>
    8000661e:	97b2                	add	a5,a5,a2
    80006620:	4605                	li	a2,1
    80006622:	0ac7a423          	sw	a2,168(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006626:	20058793          	addi	a5,a1,512
    8000662a:	00479613          	slli	a2,a5,0x4
    8000662e:	00029797          	auipc	a5,0x29
    80006632:	9d278793          	addi	a5,a5,-1582 # 8002f000 <disk>
    80006636:	97b2                	add	a5,a5,a2
    80006638:	0a07a623          	sw	zero,172(a5)
  buf0->sector = sector;
    8000663c:	0b77b823          	sd	s7,176(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006640:	0002b797          	auipc	a5,0x2b
    80006644:	9c078793          	addi	a5,a5,-1600 # 80031000 <disk+0x2000>
    80006648:	6390                	ld	a2,0(a5)
    8000664a:	963a                	add	a2,a2,a4
    8000664c:	7779                	lui	a4,0xffffe
    8000664e:	9732                	add	a4,a4,a2
    80006650:	e314                	sd	a3,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006652:	00459713          	slli	a4,a1,0x4
    80006656:	6394                	ld	a3,0(a5)
    80006658:	96ba                	add	a3,a3,a4
    8000665a:	4641                	li	a2,16
    8000665c:	c690                	sw	a2,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000665e:	6394                	ld	a3,0(a5)
    80006660:	96ba                	add	a3,a3,a4
    80006662:	4605                	li	a2,1
    80006664:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006668:	fa442683          	lw	a3,-92(s0)
    8000666c:	6390                	ld	a2,0(a5)
    8000666e:	963a                	add	a2,a2,a4
    80006670:	00d61723          	sh	a3,14(a2) # 200e <_entry-0x7fffdff2>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006674:	0692                	slli	a3,a3,0x4
    80006676:	6390                	ld	a2,0(a5)
    80006678:	9636                	add	a2,a2,a3
    8000667a:	05890513          	addi	a0,s2,88
    8000667e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006680:	639c                	ld	a5,0(a5)
    80006682:	97b6                	add	a5,a5,a3
    80006684:	40000613          	li	a2,1024
    80006688:	c790                	sw	a2,8(a5)
  if(write)
    8000668a:	140c0163          	beqz	s8,800067cc <virtio_disk_rw+0x2a6>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000668e:	0002b797          	auipc	a5,0x2b
    80006692:	97278793          	addi	a5,a5,-1678 # 80031000 <disk+0x2000>
    80006696:	639c                	ld	a5,0(a5)
    80006698:	97b6                	add	a5,a5,a3
    8000669a:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000669e:	00029897          	auipc	a7,0x29
    800066a2:	96288893          	addi	a7,a7,-1694 # 8002f000 <disk>
    800066a6:	0002b797          	auipc	a5,0x2b
    800066aa:	95a78793          	addi	a5,a5,-1702 # 80031000 <disk+0x2000>
    800066ae:	6390                	ld	a2,0(a5)
    800066b0:	9636                	add	a2,a2,a3
    800066b2:	00c65503          	lhu	a0,12(a2)
    800066b6:	00156513          	ori	a0,a0,1
    800066ba:	00a61623          	sh	a0,12(a2)
  disk.desc[idx[1]].next = idx[2];
    800066be:	fa842603          	lw	a2,-88(s0)
    800066c2:	6388                	ld	a0,0(a5)
    800066c4:	96aa                	add	a3,a3,a0
    800066c6:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800066ca:	20058513          	addi	a0,a1,512
    800066ce:	0512                	slli	a0,a0,0x4
    800066d0:	9546                	add	a0,a0,a7
    800066d2:	56fd                	li	a3,-1
    800066d4:	02d50823          	sb	a3,48(a0)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800066d8:	00461693          	slli	a3,a2,0x4
    800066dc:	6390                	ld	a2,0(a5)
    800066de:	9636                	add	a2,a2,a3
    800066e0:	6809                	lui	a6,0x2
    800066e2:	03080813          	addi	a6,a6,48 # 2030 <_entry-0x7fffdfd0>
    800066e6:	9742                	add	a4,a4,a6
    800066e8:	9746                	add	a4,a4,a7
    800066ea:	e218                	sd	a4,0(a2)
  disk.desc[idx[2]].len = 1;
    800066ec:	6398                	ld	a4,0(a5)
    800066ee:	9736                	add	a4,a4,a3
    800066f0:	4605                	li	a2,1
    800066f2:	c710                	sw	a2,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066f4:	6398                	ld	a4,0(a5)
    800066f6:	9736                	add	a4,a4,a3
    800066f8:	4809                	li	a6,2
    800066fa:	01071623          	sh	a6,12(a4) # ffffffffffffe00c <end+0xffffffff7ffcc00c>
  disk.desc[idx[2]].next = 0;
    800066fe:	6398                	ld	a4,0(a5)
    80006700:	96ba                	add	a3,a3,a4
    80006702:	00069723          	sh	zero,14(a3)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006706:	00c92223          	sw	a2,4(s2)
  disk.info[idx[0]].b = b;
    8000670a:	03253423          	sd	s2,40(a0)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000670e:	6794                	ld	a3,8(a5)
    80006710:	0026d703          	lhu	a4,2(a3)
    80006714:	8b1d                	andi	a4,a4,7
    80006716:	0706                	slli	a4,a4,0x1
    80006718:	9736                	add	a4,a4,a3
    8000671a:	00b71223          	sh	a1,4(a4)

  __sync_synchronize();
    8000671e:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006722:	6798                	ld	a4,8(a5)
    80006724:	00275783          	lhu	a5,2(a4)
    80006728:	2785                	addiw	a5,a5,1
    8000672a:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000672e:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006732:	100017b7          	lui	a5,0x10001
    80006736:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    8000673a:	00492703          	lw	a4,4(s2)
    8000673e:	4785                	li	a5,1
    80006740:	02f71163          	bne	a4,a5,80006762 <virtio_disk_rw+0x23c>
    sleep(b, &disk.vdisk_lock);
    80006744:	0002b997          	auipc	s3,0x2b
    80006748:	9e498993          	addi	s3,s3,-1564 # 80031128 <disk+0x2128>
  while(b->disk == 1) {
    8000674c:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000674e:	85ce                	mv	a1,s3
    80006750:	854a                	mv	a0,s2
    80006752:	ffffc097          	auipc	ra,0xffffc
    80006756:	b6e080e7          	jalr	-1170(ra) # 800022c0 <sleep>
  while(b->disk == 1) {
    8000675a:	00492783          	lw	a5,4(s2)
    8000675e:	fe9788e3          	beq	a5,s1,8000674e <virtio_disk_rw+0x228>
  }

  disk.info[idx[0]].b = 0;
    80006762:	fa042503          	lw	a0,-96(s0)
    80006766:	20050793          	addi	a5,a0,512
    8000676a:	00479713          	slli	a4,a5,0x4
    8000676e:	00029797          	auipc	a5,0x29
    80006772:	89278793          	addi	a5,a5,-1902 # 8002f000 <disk>
    80006776:	97ba                	add	a5,a5,a4
    80006778:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    8000677c:	0002b997          	auipc	s3,0x2b
    80006780:	88498993          	addi	s3,s3,-1916 # 80031000 <disk+0x2000>
    80006784:	00451713          	slli	a4,a0,0x4
    80006788:	0009b783          	ld	a5,0(s3)
    8000678c:	97ba                	add	a5,a5,a4
    8000678e:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006792:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006796:	00000097          	auipc	ra,0x0
    8000679a:	bb0080e7          	jalr	-1104(ra) # 80006346 <free_desc>
      i = nxt;
    8000679e:	854a                	mv	a0,s2
    if(flag & VRING_DESC_F_NEXT)
    800067a0:	8885                	andi	s1,s1,1
    800067a2:	f0ed                	bnez	s1,80006784 <virtio_disk_rw+0x25e>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800067a4:	0002b517          	auipc	a0,0x2b
    800067a8:	98450513          	addi	a0,a0,-1660 # 80031128 <disk+0x2128>
    800067ac:	ffffa097          	auipc	ra,0xffffa
    800067b0:	52c080e7          	jalr	1324(ra) # 80000cd8 <release>
}
    800067b4:	60e6                	ld	ra,88(sp)
    800067b6:	6446                	ld	s0,80(sp)
    800067b8:	64a6                	ld	s1,72(sp)
    800067ba:	6906                	ld	s2,64(sp)
    800067bc:	79e2                	ld	s3,56(sp)
    800067be:	7a42                	ld	s4,48(sp)
    800067c0:	7aa2                	ld	s5,40(sp)
    800067c2:	7b02                	ld	s6,32(sp)
    800067c4:	6be2                	ld	s7,24(sp)
    800067c6:	6c42                	ld	s8,16(sp)
    800067c8:	6125                	addi	sp,sp,96
    800067ca:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800067cc:	0002b797          	auipc	a5,0x2b
    800067d0:	83478793          	addi	a5,a5,-1996 # 80031000 <disk+0x2000>
    800067d4:	639c                	ld	a5,0(a5)
    800067d6:	97b6                	add	a5,a5,a3
    800067d8:	4609                	li	a2,2
    800067da:	00c79623          	sh	a2,12(a5)
    800067de:	b5c1                	j	8000669e <virtio_disk_rw+0x178>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800067e0:	fa042583          	lw	a1,-96(s0)
    800067e4:	20058713          	addi	a4,a1,512
    800067e8:	0712                	slli	a4,a4,0x4
    800067ea:	00029697          	auipc	a3,0x29
    800067ee:	8be68693          	addi	a3,a3,-1858 # 8002f0a8 <disk+0xa8>
    800067f2:	96ba                	add	a3,a3,a4
  if(write)
    800067f4:	e00c1de3          	bnez	s8,8000660e <virtio_disk_rw+0xe8>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800067f8:	20058793          	addi	a5,a1,512
    800067fc:	00479613          	slli	a2,a5,0x4
    80006800:	00029797          	auipc	a5,0x29
    80006804:	80078793          	addi	a5,a5,-2048 # 8002f000 <disk>
    80006808:	97b2                	add	a5,a5,a2
    8000680a:	0a07a423          	sw	zero,168(a5)
    8000680e:	bd21                	j	80006626 <virtio_disk_rw+0x100>
      disk.free[i] = 0;
    80006810:	00098c23          	sb	zero,24(s3)
    idx[i] = alloc_desc();
    80006814:	00072023          	sw	zero,0(a4)
    if(idx[i] < 0){
    80006818:	b3bd                	j	80006586 <virtio_disk_rw+0x60>

000000008000681a <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000681a:	1101                	addi	sp,sp,-32
    8000681c:	ec06                	sd	ra,24(sp)
    8000681e:	e822                	sd	s0,16(sp)
    80006820:	e426                	sd	s1,8(sp)
    80006822:	e04a                	sd	s2,0(sp)
    80006824:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006826:	0002b517          	auipc	a0,0x2b
    8000682a:	90250513          	addi	a0,a0,-1790 # 80031128 <disk+0x2128>
    8000682e:	ffffa097          	auipc	ra,0xffffa
    80006832:	3f6080e7          	jalr	1014(ra) # 80000c24 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006836:	10001737          	lui	a4,0x10001
    8000683a:	533c                	lw	a5,96(a4)
    8000683c:	8b8d                	andi	a5,a5,3
    8000683e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006840:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006844:	0002a797          	auipc	a5,0x2a
    80006848:	7bc78793          	addi	a5,a5,1980 # 80031000 <disk+0x2000>
    8000684c:	6b94                	ld	a3,16(a5)
    8000684e:	0207d703          	lhu	a4,32(a5)
    80006852:	0026d783          	lhu	a5,2(a3)
    80006856:	06f70163          	beq	a4,a5,800068b8 <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000685a:	00028917          	auipc	s2,0x28
    8000685e:	7a690913          	addi	s2,s2,1958 # 8002f000 <disk>
    80006862:	0002a497          	auipc	s1,0x2a
    80006866:	79e48493          	addi	s1,s1,1950 # 80031000 <disk+0x2000>
    __sync_synchronize();
    8000686a:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000686e:	6898                	ld	a4,16(s1)
    80006870:	0204d783          	lhu	a5,32(s1)
    80006874:	8b9d                	andi	a5,a5,7
    80006876:	078e                	slli	a5,a5,0x3
    80006878:	97ba                	add	a5,a5,a4
    8000687a:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000687c:	20078713          	addi	a4,a5,512
    80006880:	0712                	slli	a4,a4,0x4
    80006882:	974a                	add	a4,a4,s2
    80006884:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006888:	e731                	bnez	a4,800068d4 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000688a:	20078793          	addi	a5,a5,512
    8000688e:	0792                	slli	a5,a5,0x4
    80006890:	97ca                	add	a5,a5,s2
    80006892:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006894:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006898:	ffffc097          	auipc	ra,0xffffc
    8000689c:	bae080e7          	jalr	-1106(ra) # 80002446 <wakeup>

    disk.used_idx += 1;
    800068a0:	0204d783          	lhu	a5,32(s1)
    800068a4:	2785                	addiw	a5,a5,1
    800068a6:	17c2                	slli	a5,a5,0x30
    800068a8:	93c1                	srli	a5,a5,0x30
    800068aa:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068ae:	6898                	ld	a4,16(s1)
    800068b0:	00275703          	lhu	a4,2(a4)
    800068b4:	faf71be3          	bne	a4,a5,8000686a <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800068b8:	0002b517          	auipc	a0,0x2b
    800068bc:	87050513          	addi	a0,a0,-1936 # 80031128 <disk+0x2128>
    800068c0:	ffffa097          	auipc	ra,0xffffa
    800068c4:	418080e7          	jalr	1048(ra) # 80000cd8 <release>
}
    800068c8:	60e2                	ld	ra,24(sp)
    800068ca:	6442                	ld	s0,16(sp)
    800068cc:	64a2                	ld	s1,8(sp)
    800068ce:	6902                	ld	s2,0(sp)
    800068d0:	6105                	addi	sp,sp,32
    800068d2:	8082                	ret
      panic("virtio_disk_intr status");
    800068d4:	00002517          	auipc	a0,0x2
    800068d8:	ed450513          	addi	a0,a0,-300 # 800087a8 <syscalls+0x3e8>
    800068dc:	ffffa097          	auipc	ra,0xffffa
    800068e0:	c7c080e7          	jalr	-900(ra) # 80000558 <panic>
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
